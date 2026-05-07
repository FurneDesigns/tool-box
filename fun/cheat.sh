#!/usr/bin/env bash
# usage: cheat <topic>
#        cheat tar
#        cheat "git/log"
#
# Look up a quick command-line cheatsheet via cheat.sh. Great for when you
# can almost remember the right flag.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

need curl
topic="$*"
topic_enc="$(printf '%s' "$topic" | sed 's/ /+/g')"
curl -sS "https://cheat.sh/${topic_enc}" || die "Could not reach cheat.sh"
