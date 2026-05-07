#!/usr/bin/env bash
# usage: serve [--port PORT] [--dir DIR]
#
# Start a quick HTTP server on the given directory (default: cwd, port 8000).
# Uses python3's built-in http.server. Prints the LAN URL so you can open it
# from another device.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

port=8000
dir="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) port="$2"; shift 2 ;;
    --dir)  dir="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

need python3
[[ -d "$dir" ]] || die "Not a directory: $dir"

# Try to find a LAN IP for nicer printout.
lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
[[ -z "$lan_ip" ]] && lan_ip="$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}')"
[[ -z "$lan_ip" ]] && lan_ip="localhost"

ok "Serving $dir"
printf '  Local: %shttp://localhost:%s%s\n'  "$C_CYAN" "$port" "$C_RESET"
printf '  LAN:   %shttp://%s:%s%s\n\n'        "$C_CYAN" "$lan_ip" "$port" "$C_RESET"

cd "$dir"
exec python3 -m http.server "$port"
