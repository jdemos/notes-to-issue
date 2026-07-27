#!/usr/bin/env bash
# Scans Obsidian vault for unposted meeting notes and posts them as
# GitHub issue comments on github/sales.
#
# Cron example – run Monday through Friday at 4:30pm:
#   30 16 * * 1-5 /path/to/publish-notes.sh >> /tmp/publish-notes.log 2>&1

set -euo pipefail

# Ensure Homebrew and common tool paths are available (needed when run via cron)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "──────────────────────────────────────────"
echo "▶ Run: $(date '+%A, %B %-d %Y at %-I:%M %p %Z')"
echo "──────────────────────────────────────────"

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
  sed -i '' 's/^published: "false"/published: true/;s/^published: false/published: true/' "$file"
  echo "✅ Posted and marked."

done < <(find "$VAULT_DIR" -name "*.md" -not -name "_*.md" -not -path "*/_*/*" -print0)