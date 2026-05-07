#!/usr/bin/env bash
# usage: case-convert <case> [text...]
#        echo "hello world" | case-convert snake
#
# Convert text between cases. Cases:
#   snake     hello_world
#   kebab     hello-world
#   camel     helloWorld
#   pascal    HelloWorld
#   constant  HELLO_WORLD
#   title     Hello World
#   upper     HELLO WORLD
#   lower     hello world

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

mode="$1"; shift

if [[ $# -gt 0 ]]; then
  text="$*"
elif [[ ! -t 0 ]]; then
  text="$(cat)"
else
  show_help_and_exit
fi

python3 - "$mode" "$text" <<'PY'
import sys, re

mode, text = sys.argv[1], sys.argv[2]

# split into words
parts = re.findall(r"[A-Z]+(?=[A-Z][a-z])|[A-Z]?[a-z0-9]+|[A-Z]+|[0-9]+", text)
parts = [p for p in parts if p]

m = mode.lower()
if   m == "snake":     out = "_".join(p.lower() for p in parts)
elif m == "kebab":     out = "-".join(p.lower() for p in parts)
elif m == "camel":     out = (parts[0].lower() if parts else "") + "".join(p.capitalize() for p in parts[1:])
elif m == "pascal":    out = "".join(p.capitalize() for p in parts)
elif m == "constant":  out = "_".join(p.upper() for p in parts)
elif m == "title":     out = " ".join(p.capitalize() for p in parts)
elif m == "upper":     out = " ".join(parts).upper()
elif m == "lower":     out = " ".join(parts).lower()
else:
    print(f"Unknown case: {mode}", file=sys.stderr); sys.exit(1)
print(out)
PY
