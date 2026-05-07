#!/usr/bin/env bash
# usage: license-gen [LICENSE] [--author NAME] [--year YEAR] [--list] [--write]
#        license-gen mit --author "Jane Doe"
#
# Generate a LICENSE file from common templates. Built-in: mit, apache-2.0,
# bsd-2-clause, bsd-3-clause, gpl-3.0, isc, unlicense. Use --list to see all.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

author="$(git config user.name 2>/dev/null || echo "Your Name")"
year="$(date +%Y)"
write=0
list=0
license=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --author) author="$2"; shift 2 ;;
    --year)   year="$2"; shift 2 ;;
    --write)  write=1; shift ;;
    --list)   list=1; shift ;;
    -h|--help) show_help_and_exit ;;
    *) license="$1"; shift ;;
  esac
done

if [[ $list -eq 1 ]]; then
  printf '%s\n' mit apache-2.0 bsd-2-clause bsd-3-clause gpl-3.0 isc unlicense
  exit 0
fi

[[ -z "$license" ]] && show_help_and_exit
license="${license,,}"

case "$license" in
  mit)
    text="MIT License

Copyright (c) $year $author

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE."
    ;;
  isc)
    text="ISC License

Copyright (c) $year $author

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE
USE OR PERFORMANCE OF THIS SOFTWARE."
    ;;
  unlicense)
    text="This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute
this software, either in source code form or as a compiled binary, for any
purpose, commercial or non-commercial, and by any means.

For more information, please refer to <https://unlicense.org/>"
    ;;
  apache-2.0|bsd-2-clause|bsd-3-clause|gpl-3.0)
    need curl
    info "Fetching $license template from choosealicense.com..."
    raw="$(curl -sS "https://raw.githubusercontent.com/github/choosealicense.com/gh-pages/_licenses/${license}.txt")" \
      || die "Could not fetch template."
    # strip the YAML front-matter
    text="$(printf '%s\n' "$raw" | awk 'BEGIN{f=0} /^---$/{f++; next} f>=2{print}')"
    text="${text//\[year\]/$year}"
    text="${text//\[fullname\]/$author}"
    text="${text//\[name of copyright owner\]/$author}"
    ;;
  *) die "Unknown license: $license. Try --list." ;;
esac

if [[ $write -eq 1 ]]; then
  if [[ -f LICENSE ]]; then
    confirm "LICENSE exists. Overwrite?" || die "Aborted."
  fi
  printf '%s\n' "$text" > LICENSE
  ok "Wrote LICENSE ($license)"
else
  printf '%s\n' "$text"
fi
