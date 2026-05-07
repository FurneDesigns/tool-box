#!/usr/bin/env bash
# usage: b64 [-d] [--url] [TEXT|FILE]
#        echo "hello" | b64
#        b64 -d "aGVsbG8K"
#
# Base64 encode (default) or decode (-d). Use --url for URL-safe alphabet.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

decode=0
urlsafe=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--decode) decode=1; shift ;;
    --url) urlsafe=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) break ;;
  esac
done

if [[ $# -gt 0 ]]; then
  if [[ -f "$1" ]]; then
    input="$(cat "$1")"
  else
    input="$*"
  fi
else
  [[ -t 0 ]] && show_help_and_exit
  input="$(cat)"
fi

if [[ $decode -eq 1 ]]; then
  s="$input"
  if [[ $urlsafe -eq 1 ]]; then
    s="${s//-/+}"
    s="${s//_//}"
    pad=$(( (4 - ${#s} % 4) % 4 ))
    s="$s$(printf '%*s' $pad '' | tr ' ' '=')"
  fi
  printf '%s' "$s" | base64 -d
else
  if [[ $urlsafe -eq 1 ]]; then
    printf '%s' "$input" | base64 -w0 | tr '+/' '-_' | tr -d '='
    printf '\n'
  else
    printf '%s' "$input" | base64 -w0
    printf '\n'
  fi
fi
