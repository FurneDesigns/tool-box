#!/usr/bin/env bash
# usage: cloc-quick [PATH]
#
# Count lines of code grouped by language. Handles common dirs/exts and
# skips node_modules, vendor, build artefacts. Lightweight alternative to
# the cloc gem.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

target="${1:-.}"

python3 - "$target" <<'PY'
import os, sys, pathlib, collections

EXT = {
    ".py":"Python", ".js":"JavaScript", ".jsx":"JSX", ".ts":"TypeScript",
    ".tsx":"TSX", ".vue":"Vue", ".svelte":"Svelte", ".rb":"Ruby",
    ".go":"Go", ".rs":"Rust", ".java":"Java", ".kt":"Kotlin", ".scala":"Scala",
    ".swift":"Swift", ".php":"PHP", ".cs":"C#", ".c":"C", ".h":"C/C++ header",
    ".cpp":"C++", ".cc":"C++", ".cxx":"C++", ".hpp":"C++ header",
    ".sh":"Shell", ".bash":"Shell", ".zsh":"Shell", ".fish":"Fish",
    ".sql":"SQL", ".html":"HTML", ".css":"CSS", ".scss":"SCSS",
    ".md":"Markdown", ".yml":"YAML", ".yaml":"YAML", ".json":"JSON",
    ".toml":"TOML", ".xml":"XML", ".dockerfile":"Dockerfile",
    ".lua":"Lua", ".dart":"Dart", ".elm":"Elm", ".ex":"Elixir", ".exs":"Elixir",
    ".erl":"Erlang", ".clj":"Clojure", ".hs":"Haskell", ".ml":"OCaml",
    ".r":"R", ".m":"Objective-C", ".mm":"Objective-C++", ".pl":"Perl",
}
SKIP_DIRS = {".git","node_modules","venv",".venv","dist","build","__pycache__",
             "target",".next",".turbo","coverage","vendor",".idea",".vscode"}

stats = collections.defaultdict(lambda: [0, 0, 0])  # files, lines, blank

root = pathlib.Path(sys.argv[1]).resolve()
for path in root.rglob("*"):
    if not path.is_file(): continue
    if any(p in SKIP_DIRS for p in path.parts): continue
    lang = EXT.get(path.suffix.lower())
    if lang is None and path.name.lower() == "dockerfile":
        lang = "Dockerfile"
    if lang is None: continue
    try:
        if path.stat().st_size > 5_000_000: continue
        with path.open(encoding="utf-8", errors="ignore") as f:
            blank = 0; total = 0
            for line in f:
                total += 1
                if not line.strip(): blank += 1
        s = stats[lang]
        s[0] += 1; s[1] += total; s[2] += blank
    except Exception:
        pass

if not stats:
    print("No source files found.")
    sys.exit(0)

rows = sorted(stats.items(), key=lambda kv: -kv[1][1])
total_files = sum(v[0] for v in stats.values())
total_lines = sum(v[1] for v in stats.values())
total_blank = sum(v[2] for v in stats.values())

w = max(len(k) for k in stats) + 2
print(f"{'Language'.ljust(w)}{'Files':>8}{'Lines':>10}{'Blank':>10}{'Code':>10}")
print("-" * (w + 38))
for lang, (f, lines, blank) in rows:
    print(f"{lang.ljust(w)}{f:>8}{lines:>10}{blank:>10}{lines-blank:>10}")
print("-" * (w + 38))
print(f"{'TOTAL'.ljust(w)}{total_files:>8}{total_lines:>10}{total_blank:>10}{total_lines-total_blank:>10}")
PY
