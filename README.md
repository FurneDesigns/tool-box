# tool-box

> A collection of small, focused command-line tools for developers. Pure Bash + Python (zero installs), one-line install, sensible defaults.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell: bash](https://img.shields.io/badge/Shell-bash-1f425f.svg)](#)
[![Tools: 40+](https://img.shields.io/badge/Tools-40%2B-blue.svg)](#whats-inside)

```
$ ai-commit --all
Asking Claude for a commit message...

Generated message:
─────────────────────────────────────────
feat(auth): add refresh-token rotation

Rotates the refresh token on every successful refresh so a stolen
token becomes single-use. Includes regression tests and updates the
session table migration.
─────────────────────────────────────────
Commit with this message? [y/N]
```

## Why

You don't always need a slick GUI app to decode a JWT, generate a strong password, find duplicate files, or test a regex. You need a one-liner. `tool-box` gives you 40+ of those, all consistent, all with `--help`, all installable in 30 seconds.

The AI tools (`ai-*`) are deliberately tiny — they hand a focused prompt to Claude and print the result. No magic, no surprises.

## Install

```bash
git clone https://github.com/FurneDesigns/tool-box.git ~/.tool-box
cd ~/.tool-box
./install.sh                 # symlinks every tool into ~/.local/bin
```

Make sure `~/.local/bin` is on your `$PATH`. To install elsewhere:

```bash
./install.sh --prefix /usr/local/bin
./install.sh --copy          # copy instead of symlink
./install.sh --uninstall     # remove
```

### Optional: enable the AI tools

The `ai-*` scripts work with either:

- **Claude Code CLI** (`claude` on your `$PATH`) — preferred, no extra setup.
- **Claude API** — set `ANTHROPIC_API_KEY` in your shell profile.

The default model is `claude-haiku-4-5-20251001` (fast, cheap). Override with `TOOLBOX_MODEL=claude-sonnet-4-6 ai-review`.

## What's inside

### AI

| Tool | What it does |
|------|---------------|
| `ai-commit` | Generates a Conventional Commit message from your staged diff |
| `ai-review` | Reviews your branch diff and reports bugs, security issues, suggestions |
| `ai-explain` | Explains a code file (or piped code) in plain English |
| `ai-regex` | Turns a description into a regex with examples of matches/non-matches |
| `ai-readme` | Drafts a README.md by reading your repo's manifest + tree |
| `ai-translate` | Translates text into any language |
| `ai-sql` | Natural-language → SQL (with `--schema` for accurate column names) |

### Git

| Tool | What it does |
|------|---------------|
| `git-stats` | Repo stats: commits, top contributors, busiest weekday/hour |
| `git-clean` | Deletes branches that are merged into main/master |
| `git-undo` | Safely undoes the last commit (soft reset by default) |
| `git-cz` | Interactive Conventional Commit prompt — no Node.js needed |
| `git-find-large` | Finds the biggest blobs ever committed (even outside HEAD) |

### Dev utilities

| Tool | What it does |
|------|---------------|
| `jwt-decode` | Decodes a JWT header + payload as pretty JSON |
| `uuid` | Generates UUID v4 (one or many, optional uppercase) |
| `password` | Generates strong random passwords |
| `hash` | Hashes a file or stdin (md5/sha1/sha256/sha512) |
| `b64` | Base64 encode/decode (with `--url` for URL-safe variant) |
| `color` | Convert hex / rgb / hsl + an ANSI swatch in your terminal |
| `gitignore-gen` | Pulls .gitignore templates from gitignore.io |
| `license-gen` | Drops a LICENSE (MIT, Apache-2.0, BSD, GPL, ISC, Unlicense, …) |
| `lorem` | Lorem ipsum (words, sentences, or paragraphs) |
| `regex-test` | Tests a Python regex against a string or file, highlighting matches |
| `secret-scan` | Quick scan for AWS/GitHub/OpenAI/etc tokens accidentally committed |

### File & text

| Tool | What it does |
|------|---------------|
| `cloc` | Count lines of code by language (no external dep) |
| `find-dupes` | Find duplicate files by content hash (size pre-filter) |
| `extract` | Universal archive extractor (tar/zip/7z/rar/zst/…) |
| `smart-tree` | Project tree that auto-skips node_modules, .git, build, etc. |
| `batch-rename` | Regex rename multiple files (with `--dry` preview) |
| `mdtoc` | Generate a Markdown table of contents (`--write` to inject in place) |
| `json-pretty` | Validate + pretty-print JSON from file or stdin |
| `case-convert` | snake / kebab / camel / pascal / constant / title / upper / lower |

### Network

| Tool | What it does |
|------|---------------|
| `ip-info` | Your public IP + geolocation (or info on any IP) |
| `qr` | Render a QR code for any text/URL in the terminal |
| `speed-test` | Quick download speed test against Cloudflare |
| `httpcheck` | HTTP request inspector: status, redirects, full timing breakdown |
| `kill-port` | Kill the process listening on a TCP port |
| `serve` | Start a local HTTP server in any directory (with the LAN URL) |

### System & productivity

| Tool | What it does |
|------|---------------|
| `sysinfo` | Compact system snapshot: OS, CPU, memory, disks, top processes |
| `backup` | Timestamped tar.gz backup, optionally encrypted (AES-256) |
| `pomodoro` | Configurable Pomodoro timer with terminal bells |
| `timer` | Countdown timer that accepts `90`, `5m`, `1h30m`, etc. |
| `weather` | wttr.in weather forecast, defaults to your IP location |
| `cheat` | cheat.sh quick lookup for any command (`cheat tar`, `cheat git/log`) |

## Examples

```bash
# Every tool has --help
ai-review --help

# Pipe in stdin where it makes sense
echo "hello world" | case-convert constant            # HELLO_WORLD
echo '{"a":1}'      | json-pretty
cat token.txt       | jwt-decode
cat src/foo.py      | ai-explain

# Quick recipes
password -l 32                                        # 32-char password
hash --algo sha256 some-file.zip
color "rgb(59, 130, 246)"
serve --port 3000 --dir ./public
ai-sql --schema schema.sql "users with no orders in last 30 days"
ai-translate japanese "where is the train station?"
```

## Project structure

```
tool-box/
├── ai/         # Claude-powered tools
├── git/        # Git workflow utilities
├── dev/        # Encoding, generation, debugging
├── file/       # File & text manipulation
├── net/        # Network & HTTP
├── system/     # System info & backups
├── fun/        # Pomodoro, weather, cheat sheets
├── lib/
│   └── common.sh   # Shared helpers (colors, AI client, arg parsing)
└── install.sh
```

## Requirements

Most tools work with just **bash 5+**, **python3**, and **curl** — installed by default on essentially every Linux/macOS system.

A few tools optionally use:

| Tool | Optional dep | Falls back to |
|------|--------------|----------------|
| `qr` | `qrencode` | qrenco.de online service |
| `extract` | `7z`, `unrar`, `zstd` | error message naming the missing tool |
| `kill-port` | `lsof` (preferred) | `ss` or `fuser` |

## Contributing

PRs welcome. Each tool is a single self-contained script. To add one:

1. Drop it in the appropriate category folder (`ai/`, `git/`, `dev/`, `file/`, `net/`, `system/`, `fun/`).
2. Start with `#!/usr/bin/env bash`, `set -euo pipefail`, and `source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"`.
3. Include a `# usage:` block at the top — `--help` reads it automatically.
4. Use the `info / ok / warn / err / die` helpers from `lib/common.sh`.

Re-run `./install.sh` to pick up the new script.

## License

[MIT](LICENSE) © [FurneDesigns](https://furnedesigns.com)
