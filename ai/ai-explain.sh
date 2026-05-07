#!/usr/bin/env bash
# usage: ai-explain [FILE...]
#        cat foo.py | ai-explain
#
# Explain code in plain English. Pass file paths or pipe code on stdin.
# Multiple files are concatenated and explained together.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

if [[ $# -gt 0 ]]; then
  src=""
  for f in "$@"; do
    [[ -f "$f" ]] || die "Not a file: $f"
    src+="### File: $f\n\`\`\`\n$(cat "$f")\n\`\`\`\n\n"
  done
elif [[ ! -t 0 ]]; then
  src="\`\`\`\n$(cat)\n\`\`\`"
else
  show_help_and_exit
fi

prompt="Explain the code below in clear, friendly prose.

Cover:
- What this code does (the goal, not the syntax).
- Key functions / classes / data flow.
- Anything subtle, surprising, or potentially buggy.
- If multiple files: how they fit together.

Skip line-by-line narration. Aim for under ~250 words unless complexity demands more.

$(printf '%b' "$src")"

printf '%s' "$prompt" | ai_call
