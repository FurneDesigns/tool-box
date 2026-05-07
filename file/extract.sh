#!/usr/bin/env bash
# usage: extract <archive>
#
# Universal archive extractor — figures out the right tool from the file
# extension. Supports: .zip .tar .tar.gz .tgz .tar.bz2 .tbz2 .tar.xz .txz
# .tar.zst .gz .bz2 .xz .zst .7z .rar .Z

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

f="$1"
[[ -f "$f" ]] || die "File not found: $f"

case "${f,,}" in
  *.tar.gz|*.tgz)        need tar; tar -xzvf "$f" ;;
  *.tar.bz2|*.tbz2)      need tar; tar -xjvf "$f" ;;
  *.tar.xz|*.txz)        need tar; tar -xJvf "$f" ;;
  *.tar.zst|*.tzst)      need tar; need zstd; tar --zstd -xvf "$f" ;;
  *.tar)                 need tar; tar -xvf "$f" ;;
  *.gz)                  need gunzip; gunzip -k "$f" ;;
  *.bz2)                 need bunzip2; bunzip2 -k "$f" ;;
  *.xz)                  need unxz; unxz -k "$f" ;;
  *.zst)                 need zstd; zstd -d -k "$f" ;;
  *.zip)                 need unzip; unzip "$f" ;;
  *.7z)                  need 7z; 7z x "$f" ;;
  *.rar)                 need unrar; unrar x "$f" ;;
  *.z)                   need uncompress; uncompress "$f" ;;
  *) die "Unknown archive format: $f" ;;
esac

ok "Extracted."
