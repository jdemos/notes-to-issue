#!/usr/bin/env bash
# Scans Obsidian vault for unposted meeting notes and posts them as
# GitHub issue comments on github/sales.
#
# Cron example – run every day at 8am:
#   0 8 * * * /path/to/publish-notes.sh >> /tmp/publish-notes.log 2>&1

set -euo pipefail

VAULT_DIR="$HOME/obsidian/sales"
REPO="github/sales"
TRACKER_DIR="$VAULT_DIR/.last_published"

mkdir -p "$TRACKER_DIR"

# Find all meeting note .md files (skip _account.md and hidden files)
while IFS= read -r -d '' file; do
  # Build a unique marker name from the file's relative path
  # e.g. acme-corp/2026-03-31-meeting.md → acme-corp_2026-03-31-meeting.md
  relative="${file#$VAULT_DIR/}"
  marker="$TRACKER_DIR/${relative//"/"_}"

  # Skip if already posted
  if [ -f "$marker" ]; then
    continue
  fi

  # Extract github_issue from this file's frontmatter
  issue_number=$(awk '/^---/{f=!f; next} f && /^github_issue:/{print $2; exit}' "$file")

  if [ -z "$issue_number" ]; then
    echo "Skipping $relative (no github_issue in frontmatter)"
    continue
  fi

  # Strip YAML frontmatter, post only the note body
  body=$(awk 'BEGIN{fm=0; body=0} /^---/{fm++; next} fm>=2{body=1} body{print}' "$file" | sed '/./,$!d')

  if [ -z "$body" ]; then
    echo "Skipping $relative (empty body)"
    continue
  fi

  echo "Posting $relative → ${REPO}#${issue_number}..."
  echo "$body" | gh issue comment "$issue_number" --repo "$REPO" --body-file -

  # Mark as posted only if the gh command succeeded
  touch "$marker"
  echo "✅ Posted and marked."

done < <(find "$VAULT_DIR" -name "*.md" -not -name "_*.md" -not -path "*/.last_published/*" -print0)