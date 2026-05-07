#!/usr/bin/env bash
# usage: ai-regex "what should it match"
#        ai-regex --flavor pcre "match an iso date"
#
# Generate a regex from a natural-language description. Output includes the
# pattern plus a few labelled examples (matches and non-matches).

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

flavor="ECMAScript / JavaScript"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --flavor) flavor="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) break ;;
  esac
done

[[ $# -eq 0 ]] && show_help_and_exit
description="$*"

prompt="Generate a regex pattern that matches: $description

Flavor: $flavor

Output format (exactly):
PATTERN: <the regex on one line, no leading/trailing whitespace>

EXPLANATION:
<2-4 short bullet points explaining the pattern>

MATCHES:
- <example 1>
- <example 2>
- <example 3>

DOES NOT MATCH:
- <example 1>
- <example 2>

Keep the pattern as simple as possible. Prefer readable over clever."

printf '%s' "$prompt" | ai_call
