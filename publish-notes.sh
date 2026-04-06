#!/usr/bin/env bash
# publish-notes.sh
#
# Scans an Obsidian vault for unposted meeting notes and publishes them
# as comments on the corresponding GitHub issue.
#
# Usage:
#   ./publish-notes.sh [--dry-run]
#
# Environment overrides (optional):
#   VAULT_DIR  – path to your Obsidian sales vault  (default: ~/obsidian/sales)
#   REPO       – GitHub repo in owner/name format    (default: github/sales)
#
# Cron example – run every day at 8am:
#   0 8 * * * /path/to/publish-notes.sh >> /tmp/publish-notes.log 2>&1

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

VAULT_DIR="${VAULT_DIR:-$HOME/obsidian/sales}"
REPO="${REPO:-github/sales}"
TRACKER_DIR="$VAULT_DIR/.last_published"
DRY_RUN=false

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

if [ ! -d "$VAULT_DIR" ]; then
  echo "Error: VAULT_DIR '$VAULT_DIR' does not exist." >&2
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: GitHub CLI (gh) is not installed. See https://cli.github.com/" >&2
  exit 1
fi

if [ "$DRY_RUN" = false ] && ! gh auth status &>/dev/null; then
  echo "Error: Not authenticated with GitHub CLI. Run 'gh auth login' first." >&2
  exit 1
fi

mkdir -p "$TRACKER_DIR"

if [ "$DRY_RUN" = true ]; then
  echo "🔍 Dry-run mode – no posts will be made."
fi

# ---------------------------------------------------------------------------
# Process each meeting note
# ---------------------------------------------------------------------------

# Find all meeting note .md files (skip _account.md files and the tracker dir)
while IFS= read -r -d '' file; do

  # Derive a flat marker filename from the file's path relative to the vault.
  # e.g. acme-corp/2026-03-31-meeting.md → .last_published/acme-corp_2026-03-31-meeting.md
  relative="${file#"$VAULT_DIR/"}"
  marker="$TRACKER_DIR/${relative//\//_}"

  # Skip notes that have already been published
  if [ -f "$marker" ]; then
    continue
  fi

  # Extract the github_issue number from YAML frontmatter
  issue_number=$(awk '/^---/{f=!f; next} f && /^github_issue:/{print $2; exit}' "$file")

  if [ -z "$issue_number" ]; then
    echo "Skipping $relative (no github_issue in frontmatter)"
    continue
  fi

  # Validate that issue_number is a positive integer to prevent command injection
  if ! [[ "$issue_number" =~ ^[0-9]+$ ]]; then
    echo "Skipping $relative (invalid github_issue value: '$issue_number')" >&2
    continue
  fi

  # Extract the note body (everything after the closing --- of the frontmatter),
  # then strip any leading blank lines with sed
  body=$(awk 'BEGIN{fm=0; body=0} /^---/{fm++; next} fm>=2{body=1} body{print}' "$file" \
         | sed '/./,$!d')

  if [ -z "$body" ]; then
    echo "Skipping $relative (empty body)"
    continue
  fi

  echo "Posting $relative → ${REPO}#${issue_number}..."

  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] would post to ${REPO}#${issue_number}"
    continue
  fi

  # Post the comment; touch the marker only on success (set -e handles failures)
  echo "$body" | gh issue comment "$issue_number" --repo "$REPO" --body-file -
  touch "$marker"
  echo "✅ Posted and marked."

done < <(find "$VAULT_DIR" \
           -name "*.md" \
           -not -name "_*.md" \
           -not -path "*/.last_published/*" \
           -print0)