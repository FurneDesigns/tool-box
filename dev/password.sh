#!/usr/bin/env bash
# usage: password [-l LENGTH] [-n COUNT] [--no-symbols] [--alnum]
#
# Generate cryptographically random passwords.
#   -l   length of each password (default 20)
#   -n   number of passwords (default 1)
#   --no-symbols  exclude symbols
#   --alnum       letters + digits only

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

length=20
count=1
charset="A-Za-z0-9!@#\$%^&*()-_=+[]{}<>?,.:;"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -l) length="$2"; shift 2 ;;
    -n) count="$2"; shift 2 ;;
    --no-symbols|--alnum) charset="A-Za-z0-9"; shift ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ "$length" =~ ^[0-9]+$ ]] || die "Length must be a number."
[[ "$count"  =~ ^[0-9]+$ ]] || die "Count must be a number."
(( length >= 4 ))  || die "Length must be at least 4."

for ((i=0; i<count; i++)); do
  # Read a chunk of urandom into tr to avoid SIGPIPE under pipefail.
  pw="$(LC_ALL=C head -c $((length * 64)) /dev/urandom | LC_ALL=C tr -dc "$charset" | head -c "$length")"
  printf '%s\n' "$pw"
done
