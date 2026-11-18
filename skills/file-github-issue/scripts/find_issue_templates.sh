#!/usr/bin/env bash
# Print the issue templates a GitHub repo asks people to use.
#
# Usage:  find_issue_templates.sh OWNER/REPO
#
# Looks in the repo first, then in the owner's shared ".github" repo, which
# GitHub uses as the fallback when a repo has no templates of its own.
# Output: one block per file, each starting with a header line:
#   ===== TEMPLATE: .github/ISSUE_TEMPLATE/bug_report.yml (from owner/repo) =====
#   ===== CONFIG: .github/ISSUE_TEMPLATE/config.yml (from owner/repo) =====
# or the single line NO_TEMPLATES.
set -euo pipefail

repo="${1:-}"
[[ "$repo" == */* ]] || { echo "Usage: $0 OWNER/REPO" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "ERROR: The GitHub CLI (gh) is not installed." >&2; exit 2; }

raw()      { gh api "repos/$1/contents/$2" -H "Accept: application/vnd.github.raw+json" 2>/dev/null; }
list_dir() { gh api "repos/$1/contents/$2" --jq '.[] | select(.type == "file") | .path' 2>/dev/null || true; }

found=0
show() {
  local kind="TEMPLATE"
  case "$(basename "$2" | tr '[:upper:]' '[:lower:]')" in config.yml|config.yaml) kind="CONFIG" ;; esac
  echo "===== $kind: $2 (from $1) ====="
  raw "$1" "$2" || echo "(could not read this file)"
  echo
  [ "$kind" = "TEMPLATE" ] && found=1
  return 0
}

check() {
  local r="$1" f
  while IFS= read -r f; do
    case "$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')" in
      *.md|*.yml|*.yaml) show "$r" "$f" ;;
    esac
  done < <(list_dir "$r" ".github/ISSUE_TEMPLATE")
  # Older single-file templates.
  for f in .github/ISSUE_TEMPLATE.md .github/issue_template.md ISSUE_TEMPLATE.md issue_template.md \
           docs/ISSUE_TEMPLATE.md docs/issue_template.md; do
    if raw "$r" "$f" >/dev/null; then show "$r" "$f"; fi
  done
}

check "$repo"
if [ "$found" -eq 0 ]; then
  owner="${repo%%/*}"
  check "$owner/.github"
fi
[ "$found" -eq 1 ] || echo "NO_TEMPLATES"
