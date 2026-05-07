#!/usr/bin/env bash
# usage: mdtoc [--write] FILE
#
# Generate a Markdown table of contents from the headings in FILE.
# Prints the TOC to stdout; with --write, replaces (or inserts) it between
# <!-- toc --> and <!-- /toc --> markers in the file.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

write=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --write) write=1; shift ;;
    -h|--help|"") show_help_and_exit ;;
    *) break ;;
  esac
done

[[ $# -eq 0 ]] && show_help_and_exit
file="$1"
[[ -f "$file" ]] || die "File not found: $file"

toc="$(python3 - "$file" <<'PY'
import sys, re

slugs = {}
def slug(text):
    s = re.sub(r"[^\w\s-]", "", text.lower()).strip()
    s = re.sub(r"\s+", "-", s)
    if s in slugs:
        slugs[s] += 1
        s = f"{s}-{slugs[s]}"
    else:
        slugs[s] = 0
    return s

in_code = False
lines = []
with open(sys.argv[1], encoding="utf-8") as f:
    for line in f:
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        m = re.match(r"^(#{1,6})\s+(.+?)\s*#*\s*$", line)
        if not m: continue
        level = len(m.group(1))
        title = m.group(2).strip()
        # Skip H1 (usually the doc title)
        if level == 1: continue
        indent = "  " * (level - 2)
        lines.append(f"{indent}- [{title}](#{slug(title)})")

print("\n".join(lines))
PY
)"

if [[ -z "$toc" ]]; then
  warn "No headings (level 2-6) found."
  exit 0
fi

if [[ $write -eq 1 ]]; then
  python3 - "$file" "$toc" <<'PY'
import sys, re
path, toc = sys.argv[1], sys.argv[2]
content = open(path, encoding="utf-8").read()
block = "<!-- toc -->\n" + toc + "\n<!-- /toc -->"
if "<!-- toc -->" in content:
    new = re.sub(r"<!-- toc -->.*?<!-- /toc -->", block, content, count=1, flags=re.DOTALL)
else:
    new = block + "\n\n" + content
open(path, "w", encoding="utf-8").write(new)
print(f"Wrote TOC into {path}")
PY
else
  printf '%s\n' "$toc"
fi
