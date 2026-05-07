#!/usr/bin/env bash
# usage: git-cz
#
# Interactive Conventional Commit helper. Walks you through type, scope,
# subject, and optional body, then runs git commit. Mirrors the commitizen
# 'cz' UX without requiring node.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

git rev-parse --git-dir >/dev/null 2>&1 || die "Not in a git repository"

if [[ -z "$(git diff --cached --name-only)" ]]; then
  die "No staged changes. Stage with 'git add' first."
fi

declare -a types=(
  "feat:     A new feature"
  "fix:      A bug fix"
  "docs:     Documentation only"
  "style:    Formatting, whitespace (no code change)"
  "refactor: Code change that neither fixes nor adds"
  "perf:     Performance improvement"
  "test:     Adding or fixing tests"
  "build:    Build system or dependencies"
  "ci:       CI/CD configuration"
  "chore:    Other changes (tooling, etc)"
  "revert:   Revert a previous commit"
)

echo "Select a type:"
for i in "${!types[@]}"; do
  printf '  %s%2d%s) %s\n' "$C_CYAN" "$((i+1))" "$C_RESET" "${types[$i]}"
done
read -r -p "Number: " n
[[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#types[@]} )) || die "Invalid choice."
type="${types[$((n-1))]%%:*}"

read -r -p "Scope (optional, e.g., auth, api): " scope
read -r -p "Short subject (imperative, <=72 chars): " subject
[[ -z "$subject" ]] && die "Subject is required."

read -r -p "Long body? (y/N) " want_body
body=""
if [[ "$want_body" =~ ^[Yy]$ ]]; then
  echo "Enter body (end with a single '.' on a line):"
  while IFS= read -r line; do
    [[ "$line" == "." ]] && break
    body+="$line"$'\n'
  done
fi

read -r -p "Breaking change? (y/N) " breaking
breaking_note=""
if [[ "$breaking" =~ ^[Yy]$ ]]; then
  read -r -p "Describe the breaking change: " breaking_note
fi

header="$type"
[[ -n "$scope" ]] && header="$type($scope)"
[[ -n "$breaking_note" ]] && header+="!"
header+=": $subject"

msg="$header"
[[ -n "$body" ]] && msg+=$'\n\n'"$body"
[[ -n "$breaking_note" ]] && msg+=$'\n\n'"BREAKING CHANGE: $breaking_note"

echo
printf '%s%s%s\n' "$C_BOLD" "Final message:" "$C_RESET"
printf '%s%s%s\n' "$C_DIM" "─────────────────────────────" "$C_RESET"
printf '%s\n' "$msg"
printf '%s%s%s\n' "$C_DIM" "─────────────────────────────" "$C_RESET"

if confirm "Commit?"; then
  git commit -m "$msg"
  ok "Committed."
fi
