#!/usr/bin/env bash
# usage: qr <text>
#        echo "https://example.com" | qr
#
# Render a QR code in the terminal. Uses the local `qrencode` if available,
# otherwise falls back to the qrenco.de online service via curl.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

if [[ $# -gt 0 ]]; then
  text="$*"
elif [[ ! -t 0 ]]; then
  text="$(cat)"
else
  show_help_and_exit
fi

if have qrencode; then
  printf '%s' "$text" | qrencode -t ansiutf8
else
  need curl
  # qrenco.de service: returns a terminal-renderable QR code
  curl -sSf --data-urlencode "x=$text" "https://qrenco.de/" || die "QR generation failed."
fi
