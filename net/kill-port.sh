#!/usr/bin/env bash
# usage: kill-port <port> [--force]
#
# Kill the process listening on the given TCP port. Asks for confirmation
# unless --force is passed.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

port="$1"; shift
force=0
[[ "${1:-}" == "--force" ]] && force=1

[[ "$port" =~ ^[0-9]+$ ]] || die "Port must be a number."

pids=()
if have lsof; then
  while read -r pid; do
    [[ -n "$pid" ]] && pids+=("$pid")
  done < <(lsof -ti tcp:"$port" 2>/dev/null)
elif have ss; then
  while read -r pid; do
    [[ -n "$pid" ]] && pids+=("$pid")
  done < <(ss -ltnp 2>/dev/null | awk -v p="$port" '$4 ~ ":"p"$" {print}' \
            | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u)
elif have fuser; then
  pids_str="$(fuser "$port"/tcp 2>/dev/null || true)"
  for p in $pids_str; do pids+=("$p"); done
else
  die "Need lsof, ss, or fuser to find the process."
fi

if [[ ${#pids[@]} -eq 0 ]]; then
  warn "No process listening on port $port."
  exit 0
fi

echo "Process(es) on port $port:"
for pid in "${pids[@]}"; do
  cmd="$(ps -p "$pid" -o pid,user,comm,args= 2>/dev/null | tail -n +2 || echo "  pid $pid")"
  printf '  %s\n' "$cmd"
done

if [[ $force -eq 1 ]] || confirm "Kill ${#pids[@]} process(es)?"; then
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true; done
  ok "Killed."
fi
