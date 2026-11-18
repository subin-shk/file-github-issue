#!/usr/bin/env bash
# One-time setup for browser capture: a small Node project with Playwright
# (drives a real browser), gifenc + pngjs (turn screenshots into an animated GIF)
# and ffmpeg-static (a full ffmpeg, to save recordings as MP4, which every
# browser plays). Safe to run again; it only installs what's missing.
#
# Prints the folder to run capture scripts from as the last line:
#   CAPTURE_DIR=/home/me/.cache/file-github-issue/capture
set -euo pipefail

command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js is not installed. Get it from https://nodejs.org (LTS)." >&2; exit 2; }
command -v npm  >/dev/null 2>&1 || { echo "ERROR: npm is not installed (it comes with Node.js)." >&2; exit 2; }

dir="${FILE_GITHUB_ISSUE_HOME:-$HOME/.cache/file-github-issue}/capture"
mkdir -p "$dir"
cd "$dir"

if [ ! -f package.json ]; then
  cat > package.json <<'EOF'
{ "name": "file-github-issue-capture", "private": true, "type": "module" }
EOF
fi

if [ ! -d node_modules/playwright ] || [ ! -d node_modules/gifenc ] || [ ! -d node_modules/pngjs ] || [ ! -d node_modules/ffmpeg-static ]; then
  echo "Installing capture tools (first time only)..." >&2
  npm install --silent --no-audit --no-fund playwright gifenc pngjs ffmpeg-static >&2
fi

# Downloads Chromium only if this Playwright version doesn't have it yet.
npx --no-install playwright install chromium >&2

echo "CAPTURE_DIR=$dir"
