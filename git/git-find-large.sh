#!/usr/bin/env bash
# usage: git-find-large [--top N]
#
# Find the largest blobs ever committed to this repo, including ones no
# longer in HEAD. Useful for hunting down accidentally committed binaries
# or build artifacts before running git filter-repo.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

top=20
while [[ $# -gt 0 ]]; do
  case "$1" in
    --top) top="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "Not in a git repository"

info "Scanning git objects (this can take a moment on large repos)..."

# Build a name index from rev-list so we can map blob SHAs back to paths.
git rev-list --objects --all 2>/dev/null \
  | awk '{print $1, substr($0, length($1)+2)}' \
  | sort -k1,1 > /tmp/.git-find-large-names.$$

git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectname) %(objectsize)' \
  | awk '$1=="blob" {print $3, $2}' \
  | sort -rn -k1,1 \
  | head -"$top" \
  | while read -r size sha; do
      name="$(awk -v s="$sha" '$1==s {print $2; exit}' /tmp/.git-find-large-names.$$)"
      human="$(numfmt --to=iec-i --suffix=B --padding=8 "$size" 2>/dev/null || echo "${size}B")"
      printf '%s  %s  %s\n' "$human" "${sha:0:10}" "${name:-<unknown>}"
    done

rm -f /tmp/.git-find-large-names.$$
