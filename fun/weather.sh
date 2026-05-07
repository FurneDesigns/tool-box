#!/usr/bin/env bash
# usage: weather [LOCATION]
#
# Show current weather + forecast in your terminal. Uses wttr.in.
# Examples:
#   weather                  # auto-detect location by IP
#   weather "Buenos Aires"
#   weather Tokyo

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

need curl
loc="${*:-}"
loc_enc="$(printf '%s' "$loc" | sed 's/ /+/g')"
curl -sS "https://wttr.in/${loc_enc}?2nF" || die "Could not reach wttr.in"
