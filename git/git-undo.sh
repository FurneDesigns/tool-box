#!/usr/bin/env bash
# usage: git-undo [--hard]
#
# Undo the last commit on the current branch. By default keeps your changes
# in the working tree (soft reset). With --hard, also discards the changes.
# Refuses to run if HEAD is already pushed unless you pass --hard explicitly.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

mode="--soft"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hard) mode="--hard"; shift ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "Not in a git repository"

current="$(git rev-parse --abbrev-ref HEAD)"
last_msg="$(git log -1 --format='%h %s')"
echo "Last commit on '$current': $last_msg"

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
if [[ -n "$upstream" ]]; then
  if git merge-base --is-ancestor HEAD "$upstream"; then
    warn "HEAD has been pushed to $upstream."
    [[ "$mode" != "--hard" ]] || warn "Force-pushing later will rewrite history!"
    confirm "Proceed anyway?" || die "Aborted."
  fi
fi

if [[ "$mode" == "--hard" ]]; then
  warn "This will DISCARD all changes from the last commit."
  confirm "Are you sure?" || die "Aborted."
fi

git reset "$mode" HEAD~1
ok "Undone (mode: $mode). Working tree $( [[ $mode == --soft ]] && echo 'kept your changes' || echo 'cleared')."
