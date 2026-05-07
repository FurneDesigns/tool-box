#!/usr/bin/env bash
# usage: ai-readme [--write]
#
# Generate a README.md by inspecting the current repo (package files, source
# layout, scripts). Prints to stdout by default; pass --write to save it as
# README.md (refuses to overwrite without confirmation).

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

write=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --write) write=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

context=""
add() { [[ -f "$1" ]] && context+="### $1\n\`\`\`\n$(head -c 4000 "$1")\n\`\`\`\n\n"; }

add package.json
add pyproject.toml
add Cargo.toml
add go.mod
add Gemfile
add composer.json
add Makefile
add Dockerfile

if have git && git rev-parse --git-dir >/dev/null 2>&1; then
  context+="### Repo file tree (depth 2)\n\`\`\`\n"
  context+="$(git ls-files | awk -F/ '{print $1, $2}' | sort -u | head -60)"
  context+="\n\`\`\`\n\n"
fi

# Fallback: a tiny tree if no git.
if [[ -z "$context" ]]; then
  context+="### Files\n\`\`\`\n$(find . -maxdepth 2 -not -path '*/\.*' | head -40)\n\`\`\`\n"
fi

prompt="Write a clean, professional README.md for this project based on the files below.

Include these sections, in order:
- Project title (from package.json/Cargo.toml/etc., otherwise infer from repo name)
- One-line tagline
- Features (bullet list, 3-6 items)
- Installation (real commands based on the package manager you see)
- Usage (one or two realistic examples)
- Project structure (only if non-trivial)
- License (if a LICENSE file exists, mention it; otherwise skip)

Rules:
- Output GitHub-flavored markdown only. No surrounding commentary.
- Don't invent features, APIs, or commands you can't see evidence of.
- Keep it concise; this is a starting point users will edit.

Project files:
$(printf '%b' "$context")"

readme="$(printf '%s' "$prompt" | ai_call)"

if [[ $write -eq 1 ]]; then
  if [[ -f README.md ]]; then
    confirm "README.md exists. Overwrite?" || { warn "Aborted."; exit 1; }
  fi
  printf '%s\n' "$readme" > README.md
  ok "Wrote README.md ($(wc -c < README.md) bytes)"
else
  printf '%s\n' "$readme"
fi
