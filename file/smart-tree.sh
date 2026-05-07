#!/usr/bin/env bash
# usage: smart-tree [PATH] [--depth N]
#
# Print a project tree, automatically skipping the usual noise dirs
# (node_modules, .git, build artifacts). No external 'tree' dependency.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

target="."
depth=4
while [[ $# -gt 0 ]]; do
  case "$1" in
    --depth) depth="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) target="$1"; shift ;;
  esac
done

[[ -d "$target" ]] || die "Not a directory: $target"

python3 - "$target" "$depth" <<'PY'
import sys, os, pathlib

SKIP = {".git","node_modules","venv",".venv","dist","build","__pycache__",
        "target",".next",".turbo","coverage",".idea",".vscode",".pytest_cache",
        ".mypy_cache",".ruff_cache","vendor"}

root = pathlib.Path(sys.argv[1]).resolve()
max_depth = int(sys.argv[2])

print(root.name + "/")

def walk(path, prefix, depth):
    if depth > max_depth: return
    try:
        entries = sorted(path.iterdir(), key=lambda p: (p.is_file(), p.name.lower()))
    except PermissionError:
        return
    entries = [e for e in entries if e.name not in SKIP and not e.name.startswith(".")
               or e.name in {".github",".gitlab"}]
    for i, e in enumerate(entries):
        is_last = (i == len(entries) - 1)
        branch = "└── " if is_last else "├── "
        suffix = "/" if e.is_dir() else ""
        print(prefix + branch + e.name + suffix)
        if e.is_dir():
            walk(e, prefix + ("    " if is_last else "│   "), depth + 1)

walk(root, "", 1)
PY
