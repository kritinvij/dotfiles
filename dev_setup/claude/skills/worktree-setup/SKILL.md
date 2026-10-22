---
name: worktree-setup
description: Create and initialize a git worktree for branch work. Required before any branch creation or switching. Never create branches in the main checkout.
type: process
---

**When this applies:** starting any work that requires a new branch or switching branches.

## Rules

- Main checkout always stays on `main`, read-only for git ops (log, diff, status).
- Never run `git checkout -b` or `git switch -c` in the main checkout.

## Setup

```bash
# From main checkout
git worktree add .worktrees/<branch-name> -b <branch-name>
cd .worktrees/<branch-name>

# Ensure .worktrees/ is in .gitignore (check first, use ~/.gitignore if project-level is off-limits)
grep -q '\.worktrees' .gitignore || echo ".worktrees/" >> ~/.gitignore
```

Branch name format: `<type>/<jira-ticket>-<short-description>` (see `commit-standards` skill).

## Before Starting Code Changes

From the worktree, sync with upstream:

```bash
git fetch origin && git rebase origin/main
```
