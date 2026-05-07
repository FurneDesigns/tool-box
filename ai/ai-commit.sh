#!/usr/bin/env bash
# usage: ai-commit [--all] [--type TYPE] [--scope SCOPE] [--dry]
#
# Generate a Conventional Commit message from your staged diff using Claude,
# then prompt to use it. With --all, stages every modified file first.
#
# Examples:
#   ai-commit                  # uses currently staged changes
#   ai-commit --all            # stages all changes, then writes message
#   ai-commit --type fix --dry # preview without committing

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

stage_all=0; type_hint=""; scope_hint=""; dry=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)   stage_all=1; shift ;;
    --type)  type_hint="$2"; shift 2 ;;
    --scope) scope_hint="$2"; shift 2 ;;
    --dry)   dry=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "Not in a git repository"

if [[ $stage_all -eq 1 ]]; then
  git add -A
fi

diff="$(git diff --cached --no-color)"
[[ -z "$diff" ]] && die "No staged changes. Stage with 'git add' or pass --all."

# Truncate huge diffs to keep the prompt cheap.
diff_trimmed="$(printf '%s' "$diff" | head -c 12000)"

prompt="You are a senior engineer writing a Conventional Commit message.

Rules:
- First line: <type>(<scope>): <subject>  (subject in imperative, <= 72 chars, no trailing period)
- Allowed types: feat, fix, refactor, perf, docs, test, build, ci, chore, style, revert
- Add a body only when the change is non-obvious. Wrap at ~72 chars.
- Never reference 'this commit' or 'this PR'. No emojis. No markdown.
- Output ONLY the commit message — nothing else.

${type_hint:+Hint: prefer type '$type_hint'.}
${scope_hint:+Hint: prefer scope '$scope_hint'.}

Diff:
\`\`\`diff
$diff_trimmed
\`\`\`"

info "Asking Claude for a commit message..."
msg="$(printf '%s' "$prompt" | ai_call)"
msg="$(printf '%s\n' "$msg" | sed -e 's/^```.*$//' -e '/./,$!d' | awk 'NF{found=1} found{print}')"

echo
printf '%s%s%s\n' "$C_BOLD" "Generated message:" "$C_RESET"
printf '%s%s%s\n' "$C_DIM" "─────────────────────────────────────────" "$C_RESET"
printf '%s\n' "$msg"
printf '%s%s%s\n' "$C_DIM" "─────────────────────────────────────────" "$C_RESET"

if [[ $dry -eq 1 ]]; then
  exit 0
fi

if confirm "Commit with this message?"; then
  git commit -m "$msg"
  ok "Committed."
else
  warn "Aborted. Message above was not used."
fi
