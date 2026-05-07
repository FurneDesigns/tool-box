#!/usr/bin/env bash
# usage: httpcheck <url> [--method M] [--header "K: V"]... [--data BODY]
#
# Inspect an HTTP response: status, redirect chain, timing breakdown, and
# selected response headers. Like a friendlier `curl -v`.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

url="$1"; shift
method="GET"
data=""
headers=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --method) method="$2"; shift 2 ;;
    --header) headers+=(-H "$2"); shift 2 ;;
    --data)   data="$2"; shift 2 ;;
    *) die "Unknown option: $1" ;;
  esac
done

need curl

fmt='---
http_version:       %{http_version}
status_code:        %{http_code}
url_effective:      %{url_effective}
remote_ip:          %{remote_ip}
content_type:       %{content_type}
size_download:      %{size_download}
---
dns_lookup:         %{time_namelookup}s
tcp_connect:        %{time_connect}s
tls_handshake:      %{time_appconnect}s
time_to_first_byte: %{time_starttransfer}s
total:              %{time_total}s
redirect_count:     %{num_redirects}
'

args=(-sS -L --connect-timeout 10 --max-time 30 -o /dev/null -w "$fmt" -X "$method")
[[ -n "$data" ]] && args+=(--data "$data")
args+=("${headers[@]}")
args+=("$url")

curl "${args[@]}"
