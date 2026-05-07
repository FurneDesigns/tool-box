#!/usr/bin/env bash
# usage: speed-test [--size MB]
#
# Quick internet download speed test. Pulls a test file from Cloudflare
# (default 25MB) and reports throughput. Use --size to choose 1, 10, 25, or 100.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

size_mb=25
while [[ $# -gt 0 ]]; do
  case "$1" in
    --size) size_mb="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

case "$size_mb" in
  1|10|25|100) ;;
  *) die "Size must be 1, 10, 25, or 100" ;;
esac

need curl

bytes=$((size_mb * 1024 * 1024))
url="https://speed.cloudflare.com/__down?bytes=$bytes"

info "Testing download speed (${size_mb} MB from Cloudflare)..."
result="$(curl -o /dev/null -sS -w '%{speed_download} %{time_total}\n' "$url")"
read -r speed time_total <<<"$result"

mbps="$(python3 -c "print(f'{float('$speed') * 8 / 1_000_000:.2f}')")"
mibs="$(python3 -c "print(f'{float('$speed') / 1_048_576:.2f}')")"

printf '%sDownload:%s %s Mbps  (%s MiB/s)\n' "$C_BOLD" "$C_RESET" "$mbps" "$mibs"
printf '%sElapsed: %s s%s\n' "$C_DIM" "$time_total" "$C_RESET"
