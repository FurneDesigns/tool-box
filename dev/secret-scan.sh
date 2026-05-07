#!/usr/bin/env bash
# usage: secret-scan [PATH]
#
# Quick scan for accidentally committed secrets in PATH (default: cwd).
# Looks for common token formats: AWS keys, GitHub tokens, generic API keys,
# private key headers, JWTs in source. Not a replacement for gitleaks/trufflehog,
# but catches the obvious mistakes.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help) show_help_and_exit ;;
esac

target="${1:-.}"

# Patterns: name + regex (Python-flavor)
python3 - "$target" <<'PY'
import os, re, sys, pathlib

ROOT = pathlib.Path(sys.argv[1]).resolve()
SKIP_DIRS = {".git", "node_modules", "venv", ".venv", "dist", "build", "__pycache__", ".next", ".turbo"}
TEXT_EXTS = {".js",".ts",".jsx",".tsx",".py",".rb",".go",".rs",".java",".kt",".php",".sh",".env",".yml",".yaml",".json",".toml",".cfg",".ini",".md",".txt",".html",".vue",".svelte",".c",".cpp",".cs",".swift"}

PATTERNS = [
    ("AWS access key",          re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("AWS secret",              re.compile(r"(?i)aws.{0,20}(secret|key).{0,5}['\"][A-Za-z0-9/+=]{40}['\"]")),
    ("GitHub token",            re.compile(r"\bghp_[A-Za-z0-9]{36}\b|\bgho_[A-Za-z0-9]{36}\b|\bghs_[A-Za-z0-9]{36}\b")),
    ("Slack token",             re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}\b")),
    ("Google API key",          re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("OpenAI key",              re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b")),
    ("Anthropic key",           re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}\b")),
    ("Stripe key",              re.compile(r"\b(sk|pk|rk)_(test|live)_[A-Za-z0-9]{20,}\b")),
    ("Private key header",      re.compile(r"-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----")),
    ("Generic password assign", re.compile(r"(?i)(password|passwd|pwd)\s*[:=]\s*['\"][^'\"\s]{6,}['\"]")),
    ("JWT in source",           re.compile(r"\beyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b")),
]

hits = []
scanned = 0
for path in ROOT.rglob("*"):
    if not path.is_file(): continue
    if any(part in SKIP_DIRS for part in path.parts): continue
    if path.suffix and path.suffix not in TEXT_EXTS: continue
    if path.stat().st_size > 1_000_000: continue
    try:
        with path.open(encoding="utf-8", errors="ignore") as f:
            for i, line in enumerate(f, 1):
                if len(line) > 4000: continue
                for name, pat in PATTERNS:
                    if pat.search(line):
                        hits.append((str(path.relative_to(ROOT)), i, name, line.strip()[:140]))
        scanned += 1
    except Exception:
        pass

if not hits:
    print(f"No secrets found in {scanned} files.")
    sys.exit(0)

RED, RESET, DIM = "\033[1;31m", "\033[0m", "\033[2m"
print(f"{RED}Found {len(hits)} potential secret(s):{RESET}\n")
for path, line, name, snippet in hits:
    print(f"  {RED}{name}{RESET}")
    print(f"    {path}:{line}")
    print(f"    {DIM}{snippet}{RESET}")
print(f"\nScanned {scanned} files. Review carefully — false positives happen.")
sys.exit(2 if hits else 0)
PY
