---
name: java-pr-gate
description: "Full Java PR gate: run claude-gradle-gate then fetch and apply auto-review prompts from reusable-gha-workflows. Required before creating any PR in a repo with build.gradle or settings.gradle."
type: process
---

**When this applies:** repo has `build.gradle` or `settings.gradle` AND you are about to create a PR.

Gate order: **verification → this gate → code review.**

## Step 1: Build gate

```bash
claude-gradle-gate
```

Must pass before proceeding.

## Step 2: Auto-review prompts

```bash
claude-pr-review-fetch
```

Read all three docs (Java PR auto-review, Java best practices, security review). Run an internal review pass against your diff. Any unreachable file: warn, skip, continue.

## Step 3: Fix-and-iterate

Cycle until clean (max 3 iterations):
- Fix or explicitly document each finding.
- Same finding recurs after addressing → treat as deliberate choice, document in PR description.
