#!/usr/bin/env bash
# Upload screenshots / videos to a new *secret* gist in the user's own GitHub
# account, then print Markdown that can be pasted into a GitHub issue.
#
# Usage:  upload_evidence.sh [-t "Short issue title"] FILE [FILE...]
#
# Why git and not `gh gist create`? The gist API only accepts text files.
# A gist is a normal git repository though, so binary files (PNG, MP4, ...)
# can be pushed into it with git. Auth reuses the GitHub CLI login, set for
# these git commands only (the user's global git config is not touched).
#
# Output (stdout):
#   GIST_URL=https://gist.github.com/<id>
#   ---MARKDOWN---
#   ![login-error](https://gist.githubusercontent.com/<user>/<id>/raw/<sha>/01-login-error.png)
#   🎥 [Watch video: checkout-freeze](https://gist.githubusercontent.com/.../02-checkout-freeze.mp4)
set -euo pipefail

title="Issue evidence"
if [ "${1:-}" = "-t" ]; then
  title="${2:-Issue evidence}"
  shift 2
fi
if [ $# -eq 0 ]; then
  echo "Usage: $0 [-t \"title\"] FILE [FILE...]" >&2
  exit 1
fi

die() { echo "ERROR: $*" >&2; exit 2; }

command -v gh  >/dev/null 2>&1 || die "The GitHub CLI (gh) is not installed. Install it from https://cli.github.com and run: gh auth login"
command -v git >/dev/null 2>&1 || die "git is not installed."
gh auth status >/dev/null 2>&1   || die "Not logged in to GitHub. Run: gh auth login"

# ---- check every file before creating anything --------------------------------
files=()
for raw in "$@"; do
  f="$raw"
  # Windows paths (C:\Users\...) -> POSIX paths when running under Git Bash.
  if command -v cygpath >/dev/null 2>&1 && [[ "$f" == *\\* || "$f" =~ ^[A-Za-z]: ]]; then
    f="$(cygpath -u "$f")"
  fi
  [ -f "$f" ] || die "File not found: $raw"
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -ge 100000000 ]; then
    die "File is larger than 100 MB, which GitHub refuses: $raw. Trim or compress it first."
  fi
  files+=("$f")
done

user="$(gh api user --jq .login)" || die "Could not read your GitHub username."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# ---- 1. create a secret gist (needs one text file to start) ----------------------
printf '# %s\n\nScreenshots and videos for a GitHub issue.\n' "$title" > "$work/README.md"
if ! gist_url="$(gh gist create --desc "Evidence: $title" "$work/README.md" 2>"$work/err" | tail -n1)"; then
  cat "$work/err" >&2
  die "Could not create a gist. If the message mentions scopes, run: gh auth refresh -s gist"
fi
gist_id="${gist_url##*/}"
[ -n "$gist_id" ] || die "Could not read the gist id from: $gist_url"

# ---- 2. clone it, add the files, push ------------------------------------------
git_auth=(-c credential.helper= -c "credential.helper=!gh auth git-credential")
git "${git_auth[@]}" clone --quiet "https://gist.github.com/${gist_id}.git" "$work/gist"

names=()
labels=()
i=0
for f in "${files[@]}"; do
  i=$((i + 1))
  base="$(basename "$f")"
  # Gists have no folders and dislike odd characters: number + clean the name.
  clean="$(printf '%s' "$base" | tr ' ' '-' | sed 's/[^A-Za-z0-9._-]/-/g; s/--*/-/g')"
  name="$(printf '%02d-%s' "$i" "$clean")"
  cp "$f" "$work/gist/$name"
  names+=("$name")
  labels+=("$(printf '%s' "${base%.*}" | tr -d '[]')")
done

git -C "$work/gist" add -A
git -C "$work/gist" -c user.name="$user" -c user.email="${user}@users.noreply.github.com" \
  commit --quiet -m "Add issue evidence"
git "${git_auth[@]}" -C "$work/gist" push --quiet origin HEAD

sha="$(git -C "$work/gist" rev-parse HEAD)"
raw_base="https://gist.githubusercontent.com/${user}/${gist_id}/raw/${sha}"

# ---- 3. print Markdown -----------------------------------------------------------
echo "GIST_URL=$gist_url"
echo "---MARKDOWN---"
for idx in "${!names[@]}"; do
  name="${names[$idx]}"
  label="${labels[$idx]}"
  url="${raw_base}/${name}"
  ext="$(printf '%s' "${name##*.}" | tr '[:upper:]' '[:lower:]')"
  case "$ext" in
    png|jpg|jpeg|gif|webp|bmp)
      echo "![${label}](${url})" ;;
    mp4|mov|webm|mkv|avi|m4v)
      echo "🎥 [Watch video: ${label}](${url})" ;;
    *)
      echo "📎 [${label}](${url})" ;;
  esac
done

# ---- 4. soft check that the links answer (warn only) -----------------------------
if command -v curl >/dev/null 2>&1; then
  for name in "${names[@]}"; do
    code="$(curl -s -o /dev/null -w '%{http_code}' -I "${raw_base}/${name}" || true)"
    if [ "$code" != "200" ]; then
      echo "WARNING: ${name} returned HTTP ${code}. It may take a minute to appear." >&2
    fi
  done
fi
