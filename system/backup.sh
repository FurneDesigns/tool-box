#!/usr/bin/env bash
# usage: backup <source> [--dest DIR] [--encrypt]
#
# Create a timestamped tar.gz of <source>. Default destination is ~/backups.
# With --encrypt, prompts for a password and produces an openssl-encrypted
# .tar.gz.enc file. Restore with:
#   openssl enc -d -aes-256-cbc -pbkdf2 -in foo.tar.gz.enc | tar xzf -

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

src="$1"; shift
dest="$HOME/backups"
encrypt=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)    dest="$2"; shift 2 ;;
    --encrypt) encrypt=1; shift ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -e "$src" ]] || die "Source not found: $src"
mkdir -p "$dest"

stamp="$(date +%Y%m%d-%H%M%S)"
name="$(basename "$(realpath "$src")")"
out="$dest/$name-$stamp.tar.gz"

info "Archiving $src..."
tar -czf "$out" -C "$(dirname "$(realpath "$src")")" "$(basename "$(realpath "$src")")"

if [[ $encrypt -eq 1 ]]; then
  need openssl
  enc="$out.enc"
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$out" -out "$enc"
  rm "$out"
  out="$enc"
fi

size="$(numfmt --to=iec-i --suffix=B "$(stat -c%s "$out")" 2>/dev/null || stat -c%s "$out")"
ok "Backup → $out ($size)"
