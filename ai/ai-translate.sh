#!/usr/bin/env bash
# usage: ai-translate <target-lang> [text...]
#        echo "hello" | ai-translate spanish
#        ai-translate japanese "Where is the train station?"
#
# Translate text into a target language using Claude. Reads from stdin if
# no text is provided as args.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

target="$1"; shift

if [[ $# -gt 0 ]]; then
  text="$*"
elif [[ ! -t 0 ]]; then
  text="$(cat)"
else
  show_help_and_exit
fi

prompt="Translate the text below into $target.

Rules:
- Output ONLY the translation. No quotes, no notes, no transliteration.
- Preserve formatting (line breaks, lists, code blocks) exactly.
- Keep proper nouns and code identifiers untranslated.

Text:
$text"

printf '%s' "$prompt" | ai_call
