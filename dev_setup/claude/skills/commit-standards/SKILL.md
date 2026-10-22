---
name: commit-standards
description: Commit message format, branch naming conventions, and Java build gate requirement before committing. Use when creating a commit or asking about commit/branch naming.
type: process
---

**When this applies:** any time you are about to run `git commit` or the user asks about commit or branch naming.

## Branch Naming

Format: `<type>/<jira-ticket>-<short-description>`

- Lowercase, hyphens only.
- Ticket number required when it exists.
- Description ≤40 chars.
- Worktree dir name matches branch name exactly.

## Commit Message

Format: `<type>(<scope>): <short description>`

- Imperative mood, ≤72 chars, no trailing period.
- Include `Fixes EAL-XXXX` or `Refs EAL-XXXX` in the commit **body** (not subject) when a Jira ticket exists.
- Pass via heredoc to avoid quoting issues.

## Before Committing Java Changes

Only when `.java` or build-affecting files (build.gradle, settings.gradle, etc.) changed:

```
claude-gradle-gate
```

Spotless fail → script auto-applies and retries. Never commit until all four checks pass (`build test checkstyle spotlessCheck`).
