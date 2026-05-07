#!/usr/bin/env bash
# usage: json-pretty [FILE|-]
#        echo '{"a":1}' | json-pretty
#
# Pretty-print JSON. Reads from FILE or stdin. Validates the input and exits
# non-zero (with the parser error) if it isn't valid JSON.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

if [[ $# -gt 0 && "$1" != "-" ]]; then
  [[ -f "$1" ]] || die "File not found: $1"
  python3 -c '
import sys, json
raw = open(sys.argv[1], encoding="utf-8").read()
try:
    data = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"Invalid JSON: {e}", file=sys.stderr); sys.exit(1)
print(json.dumps(data, indent=2, ensure_ascii=False))
' "$1"
else
  [[ -t 0 ]] && show_help_and_exit
  python3 -c '
import sys, json
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"Invalid JSON: {e}", file=sys.stderr); sys.exit(1)
print(json.dumps(data, indent=2, ensure_ascii=False))
'
fi
