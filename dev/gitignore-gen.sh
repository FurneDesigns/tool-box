#!/usr/bin/env bash
# usage: gitignore-gen [LANG...] [--list] [--write]
#        gitignore-gen node python macos
#
# Fetches gitignore templates from gitignore.io (toptal.com) and prints them
# to stdout. With --write, appends to ./.gitignore (or creates it).

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

list=0
write=0
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)  list=1; shift ;;
    --write) write=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) args+=("$1"); shift ;;
  esac
done

need curl

if [[ $list -eq 1 ]]; then
  curl -sS "https://www.toptal.com/developers/gitignore/api/list" | tr ',' '\n'
  exit 0
fi

[[ ${#args[@]} -eq 0 ]] && show_help_and_exit
joined="$(IFS=,; echo "${args[*]}")"

content="$(curl -sS "https://www.toptal.com/developers/gitignore/api/$joined")"
[[ -z "$content" || "$content" == *"ERROR"* ]] && die "Could not fetch templates for: $joined"

if [[ $write -eq 1 ]]; then
  if [[ -f .gitignore ]]; then
    printf '\n%s\n' "$content" >> .gitignore
    ok "Appended to ./.gitignore"
  else
    printf '%s\n' "$content" > .gitignore
    ok "Created ./.gitignore"
  fi
else
  printf '%s\n' "$content"
fi
