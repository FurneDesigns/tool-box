#!/usr/bin/env bash
# usage: jwt-decode <token>
#        echo "$TOKEN" | jwt-decode
#
# Decode a JWT and print its header + payload as pretty JSON. Does NOT verify
# the signature — purely a debugging convenience.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

if [[ $# -gt 0 ]]; then
  token="$1"
elif [[ ! -t 0 ]]; then
  token="$(cat)"
else
  show_help_and_exit
fi

token="$(printf '%s' "$token" | tr -d '[:space:]')"
[[ "$token" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\..*$ ]] || die "Not a JWT (expected three dot-separated segments)."

decode_segment() {
  local seg="$1"
  # base64url -> base64 (replace chars and pad)
  local pad=$(( (4 - ${#seg} % 4) % 4 ))
  local b64="${seg//-/+}"
  b64="${b64//_//}"
  printf '%s' "$b64$(printf '%*s' $pad '' | tr ' ' '=')" \
    | base64 -d 2>/dev/null \
    | python3 -m json.tool 2>/dev/null \
    || printf '<could not decode>\n'
}

IFS='.' read -r h p s <<<"$token"

printf '%sHeader:%s\n'  "$C_BOLD" "$C_RESET"
decode_segment "$h"
printf '\n%sPayload:%s\n' "$C_BOLD" "$C_RESET"
decode_segment "$p"
printf '\n%sSignature:%s %s\n' "$C_BOLD" "$C_RESET" "${s:-<none>}"
printf '%s(signature is NOT verified)%s\n' "$C_DIM" "$C_RESET"
