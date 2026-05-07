#!/usr/bin/env bash
# usage: timer <duration>
#        timer 90
#        timer 5m
#        timer 1h30m
#
# Simple countdown timer. Accepts plain seconds or a duration string with
# h/m/s suffixes. Beeps when done.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

input="$1"

# Parse duration string -> seconds
secs=$(python3 - "$input" <<'PY'
import sys, re
s = sys.argv[1].strip().lower()
if s.isdigit():
    print(int(s)); sys.exit()
total = 0
for n, u in re.findall(r"(\d+)\s*([hms])", s):
    n = int(n)
    if u == "h": total += n*3600
    if u == "m": total += n*60
    if u == "s": total += n
if total == 0:
    sys.stderr.write(f"Could not parse duration: {s!r}\n"); sys.exit(1)
print(total)
PY
)

end=$(( $(date +%s) + secs ))
while (( $(date +%s) < end )); do
  left=$(( end - $(date +%s) ))
  printf '\r%02d:%02d:%02d remaining  ' \
    $((left / 3600)) $(((left % 3600) / 60)) $((left % 60))
  sleep 1
done
printf '\rTime up.%-25s\n' " "
printf '\a\a\a'
