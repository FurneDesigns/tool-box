#!/usr/bin/env bash
# Shared helpers for tool-box scripts. Source it like:
#   source "$(dirname "$0")/../lib/common.sh"

# --- color output ----------------------------------------------------------

if [[ -t 1 ]] && [[ "${NO_COLOR:-}" == "" ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_MAGENTA=$'\033[35m'
  C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""
  C_RED=""; C_GREEN=""; C_YELLOW=""
  C_BLUE=""; C_MAGENTA=""; C_CYAN=""
fi

info()  { printf '%s%s%s\n' "$C_CYAN"   "$*" "$C_RESET"; }
ok()    { printf '%s%s%s\n' "$C_GREEN"  "$*" "$C_RESET"; }
warn()  { printf '%s%s%s\n' "$C_YELLOW" "$*" "$C_RESET" >&2; }
err()   { printf '%s%s%s\n' "$C_RED"    "$*" "$C_RESET" >&2; }
die()   { err "$@"; exit 1; }

# --- utility helpers -------------------------------------------------------

need() {
  # need <cmd> [install hint]
  command -v "$1" >/dev/null 2>&1 && return 0
  err "Required command not found: $1"
  [[ -n "${2:-}" ]] && err "  Install: $2"
  exit 127
}

have() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  # confirm "Question?" -> 0 if yes
  local prompt="${1:-Continue?}"
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# --- AI helper -------------------------------------------------------------
# Send a prompt to Claude and print the response on stdout.
# Tries `claude -p` (Claude Code CLI) first, then falls back to the API
# using ANTHROPIC_API_KEY. Pass the prompt on stdin.
#
# Env vars:
#   TOOLBOX_MODEL    override model (default: claude-haiku-4-5-20251001)
#   TOOLBOX_AI       force backend: "cli" | "api" | "auto" (default auto)

ai_call() {
  local model="${TOOLBOX_MODEL:-claude-haiku-4-5-20251001}"
  local backend="${TOOLBOX_AI:-auto}"
  local prompt
  prompt="$(cat)"

  if [[ "$backend" == "cli" || "$backend" == "auto" ]] && have claude; then
    if printf '%s' "$prompt" | claude -p --model "$model" 2>/dev/null; then
      return 0
    fi
    [[ "$backend" == "cli" ]] && die "claude CLI failed"
  fi

  [[ -z "${ANTHROPIC_API_KEY:-}" ]] && die "Set ANTHROPIC_API_KEY or install the 'claude' CLI"

  need curl
  need python3

  local payload
  payload=$(python3 -c '
import json, sys
prompt = sys.stdin.read()
print(json.dumps({
  "model": sys.argv[1],
  "max_tokens": 2048,
  "messages": [{"role": "user", "content": prompt}],
}))
' "$model" <<<"$prompt")

  local response
  response=$(curl -sS https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$payload") || die "API request failed"

  python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
if "content" in data:
    for block in data["content"]:
        if block.get("type") == "text":
            print(block["text"], end="")
    print()
else:
    sys.stderr.write(json.dumps(data, indent=2) + "\n")
    sys.exit(1)
' <<<"$response"
}

# --- argument parsing ------------------------------------------------------

show_help_and_exit() {
  # Look for a usage block at the top of the calling script: lines starting
  # with "# usage:" through the next blank comment line.
  local script="${BASH_SOURCE[1]}"
  awk '
    /^# usage:/ { in_block=1 }
    in_block {
      if (/^[^#]/ || /^#$/) exit
      sub(/^# ?/, "")
      print
    }
  ' "$script"
  exit 0
}
