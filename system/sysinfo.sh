#!/usr/bin/env bash
# usage: sysinfo
#
# A compact system snapshot: OS, CPU, memory, disks, top processes by RAM,
# uptime, and load. Linux-focused; falls back gracefully on macOS/WSL.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

section() { printf '\n%s%s%s\n%s%s%s\n' "$C_BOLD" "$1" "$C_RESET" "$C_DIM" "${1//?/─}" "$C_RESET"; }

section "System"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf '  OS:       %s\n' "${PRETTY_NAME:-$NAME}"
fi
printf '  Kernel:   %s\n' "$(uname -r)"
printf '  Host:     %s\n' "$(hostname)"
printf '  Uptime:   %s\n' "$(uptime -p 2>/dev/null || uptime)"
printf '  Shell:    %s\n' "${SHELL:-?}"
printf '  User:     %s\n' "${USER:-?}"

section "CPU"
if [[ -r /proc/cpuinfo ]]; then
  model="$(awk -F: '/^model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^ *//')"
  cores="$(grep -c ^processor /proc/cpuinfo)"
  printf '  Model:    %s\n' "${model:-?}"
  printf '  Threads:  %s\n' "$cores"
fi
load="$(awk '{print $1, $2, $3}' /proc/loadavg 2>/dev/null || true)"
[[ -n "$load" ]] && printf '  Load:     %s\n' "$load"

section "Memory"
if have free; then
  free -h | awk 'NR<=2 {print "  " $0}'
fi

section "Disk"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -vE '^(tmpfs|devtmpfs|udev|overlay|none)' \
  | head -10 \
  | awk '{print "  " $0}'

section "Top processes (by memory)"
ps aux --sort=-%mem 2>/dev/null \
  | awk 'NR==1 || NR<=6 {printf "  %-9s %6s %5s %s\n", $1, $4"%", $2, $11}' \
  | head -7
