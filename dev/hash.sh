#!/usr/bin/env bash
# usage: hash [--algo md5|sha1|sha256|sha512] [FILE|-]
#        echo "data" | hash --algo sha256
#
# Hash a file or stdin. Defaults to sha256.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

algo="sha256"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --algo) algo="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) break ;;
  esac
done

case "$algo" in
  md5)    cmd="md5sum" ;;
  sha1)   cmd="sha1sum" ;;
  sha256) cmd="sha256sum" ;;
  sha512) cmd="sha512sum" ;;
  *) die "Unsupported algo: $algo (use md5|sha1|sha256|sha512)" ;;
esac

need "$cmd"

if [[ $# -eq 0 || "$1" == "-" ]]; then
  $cmd | awk '{print $1}'
else
  for f in "$@"; do
    [[ -f "$f" ]] || { warn "Not a file: $f"; continue; }
    $cmd "$f"
  done
fi
