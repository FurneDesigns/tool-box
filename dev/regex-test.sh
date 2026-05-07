#!/usr/bin/env bash
# usage: regex-test <pattern> <test-string>
#        regex-test --file <pattern> <file>
#
# Test a regex pattern against a string or every line in a file. Highlights
# matches and prints captured groups. Uses Python regex (PCRE-like).

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

from_file=0
case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
  --file) from_file=1; shift ;;
esac

pattern="${1:-}"; shift || true
target="${1:-}"

[[ -z "$pattern" || -z "$target" ]] && show_help_and_exit

export TB_PATTERN="$pattern"

if [[ $from_file -eq 1 ]]; then
  [[ -f "$target" ]] || die "File not found: $target"
  python3 - "$target" <<'PY'
import os, re, sys
pat = re.compile(os.environ["TB_PATTERN"])
RED = "\033[1;31m"; RESET = "\033[0m"
total = 0
with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
    for i, line in enumerate(f, 1):
        line = line.rstrip("\n")
        matches = list(pat.finditer(line))
        if not matches:
            continue
        total += len(matches)
        out, last = "", 0
        for m in matches:
            out += line[last:m.start()] + RED + m.group(0) + RESET
            last = m.end()
        out += line[last:]
        print(f"{i}: {out}")
        for j, m in enumerate(matches, 1):
            if m.groups():
                print(f"   match {j}: groups = {list(m.groups())}")
print(f"\n{total} match(es)")
PY
else
  python3 - "$target" <<'PY'
import os, re, sys
pat = re.compile(os.environ["TB_PATTERN"])
text = sys.argv[1]
RED = "\033[1;31m"; RESET = "\033[0m"
matches = list(pat.finditer(text))
if not matches:
    print("No matches.")
    sys.exit(1)
out, last = "", 0
for m in matches:
    out += text[last:m.start()] + RED + m.group(0) + RESET
    last = m.end()
out += text[last:]
print(out)
print(f"\n{len(matches)} match(es)")
for i, m in enumerate(matches, 1):
    print(f"  [{i}] {m.group(0)!r}  span={m.span()}")
    if m.groups():
        for j, g in enumerate(m.groups(), 1):
            print(f"      group {j}: {g!r}")
    if m.groupdict():
        for k, v in m.groupdict().items():
            print(f"      named '{k}': {v!r}")
PY
fi
