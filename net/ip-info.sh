#!/usr/bin/env bash
# usage: ip-info [IP]
#
# Show your public IP and geolocation info, or info for a specific IP.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

need curl

ip="${1:-}"
if [[ -z "$ip" ]]; then
  ip="$(curl -sS https://api.ipify.org 2>/dev/null || curl -sS https://ifconfig.me 2>/dev/null)"
  [[ -z "$ip" ]] && die "Could not determine public IP."
  printf '%sPublic IP:%s %s\n\n' "$C_BOLD" "$C_RESET" "$ip"
fi

curl -sS "https://ipinfo.io/$ip/json" 2>/dev/null | python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
keys = ["ip", "hostname", "city", "region", "country", "loc", "org", "postal", "timezone"]
W = max(len(k) for k in keys) + 2
for k in keys:
    if k in data:
        print(f"{k.ljust(W)}{data[k]}")
'
