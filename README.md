# notes-to-issue
Local app that helps sync local account notes to the right github issue

## Overview

Take plain-text meeting notes locally in Obsidian and automatically publish them as comments on the right GitHub issue in `github/sales`.

## Local Structure

One folder per account, one `.md` file per meeting:

```
~/obsidian/sales/
├── acme-corp/
│   ├── 2026-03-28-meeting.md
│   ├── 2026-03-31-meeting.md
│   └── 2026-04-02-meeting.md
├── globex/
│   └── 2026-04-01-meeting.md
└── .last_published/        # auto-managed by the script
```

## Linking Notes to Issues

Each meeting note has YAML frontmatter with the GitHub issue number:

```markdown
---
github_issue: 456
---

## Acme Corp – 2026-03-31

- Discussed renewal timeline
- Action item: send pricing deck by Friday
```

## How the Script Works

- Runs on a schedule via `cron`
- Scans the vault for `.md` files that don't have a corresponding marker in `.last_published/`
- Extracts the `github_issue` number from frontmatter
- Posts the note body (frontmatter stripped) as a new comment via the GitHub CLI (`gh`)
- Creates a marker file after a successful post so the note is **never posted twice**

## Prerequisites

- [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login`)
- Obsidian with the Templates core plugin (optional, but recommended for pre-filling frontmatter)