#!/usr/bin/env bash
# usage: git-clean [--remote] [--force]
#
# Delete local branches that have already been merged into the default branch
# (main or master). Use --remote to also prune remote-tracking refs that no
# longer exist on the remote. Without --force, you'll be asked to confirm.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

remote=0; force=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote) remote=1; shift ;;
    --force)  force=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "Not in a git repository"

if git show-ref --verify --quiet refs/heads/main; then
  base="main"
elif git show-ref --verify --quiet refs/heads/master; then
  base="master"
else
  die "No main or master branch found."
fi

current="$(git rev-parse --abbrev-ref HEAD)"

mapfile -t merged < <(
  git branch --merged "$base" \
    | sed 's/^[* ] //' \
    | grep -vE "^($base|$current)$" || true
)

if [[ ${#merged[@]} -eq 0 ]]; then
  ok "No merged branches to clean."
else
  echo "Local branches merged into $base:"
  printf '  %s\n' "${merged[@]}"
  if [[ $force -eq 1 ]] || confirm "Delete ${#merged[@]} branch(es)?"; then
    for b in "${merged[@]}"; do
      git branch -d "$b"
    done
    ok "Deleted ${#merged[@]} branch(es)."
  fi
fi

if [[ $remote -eq 1 ]]; then
  echo
  info "Pruning remote-tracking refs..."
  git fetch --all --prune
  ok "Done."
fi
