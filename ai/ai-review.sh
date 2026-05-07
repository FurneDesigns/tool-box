#!/usr/bin/env bash
# usage: ai-review [--base BRANCH] [--staged]
#
# Sends your diff to Claude for a quick code review. By default reviews the
# diff between HEAD and origin/main (or the repo's default branch). Use
# --base to compare against a different branch, or --staged to review only
# what's currently staged.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

base=""; staged=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)   base="$2"; shift 2 ;;
    --staged) staged=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "Not in a git repository"

if [[ $staged -eq 1 ]]; then
  diff="$(git diff --cached --no-color)"
  [[ -z "$diff" ]] && die "No staged changes."
else
  if [[ -z "$base" ]]; then
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
      base="origin/main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
      base="origin/master"
    elif git rev-parse --verify main >/dev/null 2>&1; then
      base="main"
    else
      base="master"
    fi
  fi
  diff="$(git diff "${base}...HEAD" --no-color 2>/dev/null || git diff "$base" --no-color)"
  [[ -z "$diff" ]] && die "No diff against $base."
  info "Reviewing diff against $base..."
fi

# Trim to keep API cost bounded.
diff_trimmed="$(printf '%s' "$diff" | head -c 60000)"

prompt="You are a senior code reviewer. Review the diff below.

Output a short markdown report with these sections (omit a section if empty):
1. **Summary** — 1-2 sentences describing the change.
2. **Bugs / correctness issues** — concrete problems with file:line refs.
3. **Security concerns** — auth, injection, secrets, XSS, etc.
4. **Suggestions** — design/clarity/perf improvements.
5. **Nitpicks** — minor style things, only if they matter.

Be direct and specific. No filler. Skip generic advice. If the diff is fine,
say so in one sentence.

Diff:
\`\`\`diff
$diff_trimmed
\`\`\`"

printf '%s' "$prompt" | ai_call
