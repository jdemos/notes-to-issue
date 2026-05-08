# notes-to-issue

Take plain-text meeting notes locally in Obsidian and automatically publish them as comments on the right GitHub issue in `github/sales`.

## How It Works

`publish-notes.sh` runs on a cron schedule and:

1. Scans `~/obsidian/sales/` for `.md` files where `published` is not `true`
2. Extracts the `github_issue` number from each file's YAML frontmatter
3. Strips the frontmatter and posts the note body as a new comment via the GitHub CLI (`gh`)
4. Updates `published: true` in the frontmatter after a successful post so the note is **never posted twice**

Files inside folders or filenames starting with `_` are ignored (e.g. `_templates/`).

## Vault Structure

One folder per account named `Account Name - <issue_number>`, one `.md` file per meeting:

```
~/obsidian/sales/
├── Acme Corp - 456/
│   ├── 2026-03-28-Meeting.md
│   └── 2026-04-02-Meeting.md
├── Globex - 789/
│   └── 2026-04-01-Meeting.md
└── _templates/
    └── meeting.md
```

## Note Format

Each meeting note requires YAML frontmatter with `github_issue` and `published`:

```markdown
---
date: 2026-04-02
github_issue: 456
published: false
---

## Notes

- Discussed renewal timeline

## Action items

- [ ] Send pricing deck by Friday
```

## Obsidian Template

A [Templater](https://github.com/SilverStripeUnderscore/obsidian-templater) template is included at `templates/meeting.md`. It auto-fills the date and reads the issue number from the folder name. Copy it into your vault's `_templates/` folder.

> **Note:** Run the template only after the note file is inside its account folder — the issue number is derived from the folder name.

## Setup

1. Install [GitHub CLI](https://cli.github.com/) and authenticate: `gh auth login`
2. Create `~/obsidian/sales/` and point your Obsidian vault at it
3. Create account folders using the `Account Name - <issue_number>` convention
4. Copy `templates/meeting.md` into your vault's `_templates/` folder and configure Templater
5. Schedule the script with cron:

```
GH_TOKEN=<your_token>
TZ=America/Denver
0 16 * * * /path/to/publish-notes.sh >> /tmp/publish-notes.log 2>&1
```
