#!/usr/bin/env bash
# Convert a screen recording (.mov, .webm, .mkv, .avi, ...) to MP4 (H.264),
# which every browser plays when someone clicks the video link in an issue.
#
# Usage:  to_mp4.sh INPUT [OUTPUT.mp4]
# Prints the path of the MP4 as the last line:  MP4=/path/to/file.mp4
#
# Uses ffmpeg from PATH, or the copy installed by setup_capture.sh.
set -euo pipefail

in="${1:-}"
[ -n "$in" ] || { echo "Usage: $0 INPUT [OUTPUT.mp4]" >&2; exit 1; }
if command -v cygpath >/dev/null 2>&1 && [[ "$in" == *\\* || "$in" =~ ^[A-Za-z]: ]]; then
  in="$(cygpath -u "$in")"
fi
[ -f "$in" ] || { echo "ERROR: File not found: $1" >&2; exit 2; }
out="${2:-${in%.*}.mp4}"
if [ "$out" = "$in" ]; then out="${in%.*}-converted.mp4"; fi

ffmpeg=""
if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg="ffmpeg"
else
  cap="${FILE_GITHUB_ISSUE_HOME:-$HOME/.cache/file-github-issue}/capture"
  if [ -d "$cap/node_modules/ffmpeg-static" ]; then
    ffmpeg="$(cd "$cap" && node -p "require('ffmpeg-static')")"
  fi
fi
[ -n "$ffmpeg" ] || { echo "ERROR: No video converter found. Run setup_capture.sh once (needs Node.js), or attach the original file." >&2; exit 2; }

# Even width/height are required for yuv420p; keep audio if there is any.
"$ffmpeg" -y -loglevel error -i "$in" \
  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
  -c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart "$out"

echo "MP4=$out"
