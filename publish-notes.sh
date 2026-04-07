#!/usr/bin/env bash
# Scans Obsidian vault for unposted meeting notes and posts them as
# GitHub issue comments on github/sales.
#
# Cron example – run every day at 5pm:
#   0 17 * * * /path/to/publish-notes.sh >> /tmp/publish-notes.log 2>&1

set -euo pipefail

VAULT_DIR="$HOME/obsidian/sales"
REPO="github/sales"

# Find all meeting note .md files (skip _account.md and hidden files)
while IFS= read -r -d '' file; do
  relative="${file#$VAULT_DIR/}"

  # Skip if already posted
  if grep -q "^published: true" "$file"; then
    continue
  fi

  # Extract github_issue from this file's frontmatter
  issue_number=$(grep -m1 "^github_issue:" "$file" | cut -d' ' -f2)

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
  sed -i '' 's/^published: false/published: true/' "$file"
  echo "✅ Posted and marked."

done < <(find "$VAULT_DIR" -name "*.md" -not -name "_*.md" -print0)