#!/usr/bin/env bash
# Install tool-box scripts by symlinking them into a directory on $PATH.
#
# Usage:
#   ./install.sh                  # symlink into ~/.local/bin (default)
#   ./install.sh --prefix DIR     # custom target directory
#   ./install.sh --copy           # copy instead of symlinking
#   ./install.sh --uninstall      # remove installed symlinks/copies
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${HOME}/.local/bin"
ACTION="link"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)    PREFIX="$2"; shift 2 ;;
    --copy)      ACTION="copy"; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$PREFIX"

mapfile -t scripts < <(
  find "$ROOT"/{ai,git,dev,file,net,system,fun} -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort
)

count=0
skipped=0

for src in "${scripts[@]}"; do
  name="$(basename "$src" .sh)"
  dest="$PREFIX/$name"

  case "$ACTION" in
    link)
      chmod +x "$src"
      ln -sf "$src" "$dest"
      count=$((count + 1))
      ;;
    copy)
      chmod +x "$src"
      cp "$src" "$dest"
      chmod +x "$dest"
      count=$((count + 1))
      ;;
    uninstall)
      if [[ -e "$dest" || -L "$dest" ]]; then
        rm -f "$dest"
        count=$((count + 1))
      else
        skipped=$((skipped + 1))
      fi
      ;;
  esac
done

case "$ACTION" in
  link)      echo "Linked $count scripts into $PREFIX" ;;
  copy)      echo "Copied $count scripts into $PREFIX" ;;
  uninstall) echo "Removed $count scripts from $PREFIX" ;;
esac

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *)
    echo
    echo "Note: $PREFIX is not on your \$PATH."
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"$PREFIX:\$PATH\""
    ;;
esac
