#!/usr/bin/env bash
# usage: pomodoro [--work MIN] [--break MIN] [--rounds N]
#
# Run a Pomodoro session in the terminal. Defaults: 25/5 minute cycles, 4
# rounds. Plays a terminal bell at each transition. Press Ctrl-C to stop.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

work=25
brk=5
rounds=4
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work)   work="$2"; shift 2 ;;
    --break)  brk="$2"; shift 2 ;;
    --rounds) rounds="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

countdown() {
  local secs="$1" label="$2"
  local end=$(( $(date +%s) + secs ))
  while (( $(date +%s) < end )); do
    local left=$(( end - $(date +%s) ))
    printf '\r%s%s%s  %02d:%02d remaining   ' "$C_BOLD" "$label" "$C_RESET" \
      $((left / 60)) $((left % 60))
    sleep 1
  done
  printf '\r%s%s — done!%s%-30s\n' "$C_GREEN" "$label" "$C_RESET" " "
  printf '\a'
}

for ((r=1; r<=rounds; r++)); do
  printf '\n%sRound %d/%d%s\n' "$C_CYAN" "$r" "$rounds" "$C_RESET"
  countdown $((work * 60)) "Work"
  if (( r < rounds )); then
    countdown $((brk * 60)) "Break"
  fi
done

printf '\n%sAll %d rounds complete. Nice work.%s\n' "$C_GREEN" "$rounds" "$C_RESET"
