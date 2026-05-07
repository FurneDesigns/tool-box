#!/usr/bin/env bash
# usage: lorem [-w WORDS] [-p PARAGRAPHS] [-s SENTENCES]
#
# Generate Lorem Ipsum filler text. Defaults to 1 paragraph.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

words=0
paragraphs=1
sentences=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -w) words="$2"; paragraphs=0; sentences=0; shift 2 ;;
    -p) paragraphs="$2"; shift 2 ;;
    -s) sentences="$2"; paragraphs=0; words=0; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) die "Unknown option: $1" ;;
  esac
done

python3 - "$words" "$paragraphs" "$sentences" <<'PY'
import sys, random, textwrap

WORDS = ("lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod "
         "tempor incididunt ut labore et dolore magna aliqua enim ad minim veniam "
         "quis nostrud exercitation ullamco laboris nisi aliquip ex ea commodo "
         "consequat duis aute irure in reprehenderit voluptate velit esse cillum "
         "fugiat nulla pariatur excepteur sint occaecat cupidatat non proident "
         "sunt culpa qui officia deserunt mollit anim id est laborum").split()

w = int(sys.argv[1]); p = int(sys.argv[2]); s = int(sys.argv[3])

def sentence():
    n = random.randint(8, 18)
    parts = [random.choice(WORDS) for _ in range(n)]
    parts[0] = parts[0].capitalize()
    return " ".join(parts) + "."

def paragraph():
    return " ".join(sentence() for _ in range(random.randint(4, 7)))

if w > 0:
    out = [random.choice(WORDS) for _ in range(w)]
    out[0] = out[0].capitalize()
    print(textwrap.fill(" ".join(out), 80))
elif s > 0:
    print(textwrap.fill(" ".join(sentence() for _ in range(s)), 80))
else:
    print("\n\n".join(textwrap.fill(paragraph(), 80) for _ in range(p)))
PY
