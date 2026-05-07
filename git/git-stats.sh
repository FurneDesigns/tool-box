#!/usr/bin/env bash
# usage: git-stats [--since DATE] [--top N]
#
# Show repository statistics: total commits, contributors with commit
# counts, most-changed files, and busiest day-of-week.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

since=""
top=10
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) since="--since=$2"; shift 2 ;;
    --top)   top="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "Not in a git repository"

repo="$(basename "$(git rev-parse --show-toplevel)")"
total="$(git log --oneline ${since:+"$since"} 2>/dev/null | wc -l | tr -d ' ')"
first="$(git log ${since:+"$since"} --reverse --format=%ai 2>/dev/null | head -1)"
last="$(git log ${since:+"$since"} -1 --format=%ai 2>/dev/null)"

printf '%s%s%s\n' "$C_BOLD" "Repo:    $repo" "$C_RESET"
echo "Commits: $total"
[[ -n "$first" ]] && echo "First:   $first"
[[ -n "$last"  ]] && echo "Latest:  $last"

echo
printf '%s%s%s\n' "$C_BOLD" "Top $top contributors:" "$C_RESET"
git shortlog -sne ${since:+"$since"} HEAD 2>/dev/null | head -"$top"

echo
printf '%s%s%s\n' "$C_BOLD" "Top $top changed files:" "$C_RESET"
git log ${since:+"$since"} --pretty=format: --name-only 2>/dev/null \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -"$top"

echo
printf '%s%s%s\n' "$C_BOLD" "Commits by day of week:" "$C_RESET"
git log ${since:+"$since"} --format=%ad --date=format:%a 2>/dev/null \
  | sort | uniq -c | sort -rn

echo
printf '%s%s%s\n' "$C_BOLD" "Commits by hour:" "$C_RESET"
git log ${since:+"$since"} --format=%ad --date=format:%H 2>/dev/null \
  | sort | uniq -c | awk '{printf "%s:00  %s\n", $2, $1}'
