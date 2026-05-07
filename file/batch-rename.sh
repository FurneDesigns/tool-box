#!/usr/bin/env bash
# usage: batch-rename [--dry] <pattern> <replacement> [files...]
#        batch-rename --dry "IMG_" "photo_" *.jpg
#
# Rename multiple files using a regex pattern. By default operates on every
# file in the current directory. Use --dry to preview without renaming.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

dry=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry) dry=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) break ;;
  esac
done

[[ $# -lt 2 ]] && show_help_and_exit
pattern="$1"; shift
replace="$1"; shift

if [[ $# -eq 0 ]]; then
  mapfile -t files < <(find . -maxdepth 1 -type f -printf '%f\n')
else
  files=("$@")
fi

renamed=0
for f in "${files[@]}"; do
  [[ -e "$f" ]] || continue
  dir="$(dirname "$f")"
  name="$(basename "$f")"
  new="$(printf '%s' "$name" | sed -E "s/$pattern/$replace/g")"
  if [[ "$name" != "$new" ]]; then
    target="$dir/$new"
    if [[ -e "$target" && "$f" != "$target" ]]; then
      warn "Skipping (target exists): $name → $new"
      continue
    fi
    printf '%s%s%s → %s%s%s\n' "$C_DIM" "$name" "$C_RESET" "$C_GREEN" "$new" "$C_RESET"
    if [[ $dry -eq 0 ]]; then
      mv -- "$f" "$target"
    fi
    renamed=$((renamed + 1))
  fi
done

if [[ $dry -eq 1 ]]; then
  info "Dry run: would rename $renamed file(s)."
else
  ok "Renamed $renamed file(s)."
fi
