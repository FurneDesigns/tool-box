#!/usr/bin/env bash
# usage: find-dupes [PATH] [--min SIZE]
#
# Find duplicate files by content (size pre-filter, then sha256). Default
# minimum size is 1 byte. Examples:
#   find-dupes ~/Pictures
#   find-dupes . --min 1M

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

target="."
min="1c"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --min) min="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) target="$1"; shift ;;
  esac
done

[[ -d "$target" ]] || die "Not a directory: $target"
need sha256sum

info "Hashing files in $target (min size $min)..."

# Build size→files map first to skip unique-size files entirely.
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

find "$target" -type f -size +"$min" -printf '%s\t%p\n' 2>/dev/null \
  | sort -n > "$tmpdir/by_size"

awk -F'\t' '{print $1}' "$tmpdir/by_size" | uniq -d > "$tmpdir/dup_sizes"

if [[ ! -s "$tmpdir/dup_sizes" ]]; then
  ok "No duplicates found."
  exit 0
fi

# For files matching duplicate sizes, hash them and group by hash.
awk -F'\t' 'NR==FNR{s[$1]=1; next} ($1 in s){print $2}' \
  "$tmpdir/dup_sizes" "$tmpdir/by_size" \
  | xargs -d '\n' -r -P 4 -I{} sha256sum "{}" 2>/dev/null \
  | sort > "$tmpdir/hashes"

awk '{
  hash=$1
  $1=""
  sub(/^ /, "")
  groups[hash] = groups[hash] $0 "\n"
  count[hash]++
}
END {
  for (h in count) if (count[h] > 1) {
    printf "── %s (%d copies) ──\n", h, count[h]
    printf "%s", groups[h]
    print ""
  }
}' "$tmpdir/hashes"
