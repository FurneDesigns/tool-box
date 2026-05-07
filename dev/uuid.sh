#!/usr/bin/env bash
# usage: uuid [-n COUNT] [--upper]
#
# Generate one or more random UUID v4 values.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

count=1
upper=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n) count="$2"; shift 2 ;;
    --upper) upper=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ "$count" =~ ^[0-9]+$ ]] || die "Count must be a number."

for ((i=0; i<count; i++)); do
  if [[ -r /proc/sys/kernel/random/uuid ]]; then
    u="$(cat /proc/sys/kernel/random/uuid)"
  elif have uuidgen; then
    u="$(uuidgen)"
  else
    u="$(python3 -c 'import uuid; print(uuid.uuid4())')"
  fi
  [[ $upper -eq 1 ]] && u="${u^^}"
  printf '%s\n' "$u"
done
