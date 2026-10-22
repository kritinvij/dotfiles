---
name: pr-description
description: PR description standards. Five required fields for every pull request. Use when creating or drafting a pull request.
type: process
---

**When this applies:** before running `gh pr create` or drafting a PR description.

Every PR must include all five fields. "N/A" is acceptable only for truly trivial changes.

1. **What changed** - one specific sentence about the code change.
2. **Why** - Jira ticket reference or motivation (e.g., `Fixes EAL-XXXX`).
3. **How to test** - exact steps a reviewer can follow.
4. **Migration impact** - schema changes, feature flag coordination, config changes needed. "None" if clean.
5. **Rollback plan** - for infra or migration changes. "Revert commit X" is acceptable minimum.

Always follow the PR template for the specific repo if one exists (`.github/pull_request_template.md`).

Pass body via heredoc:
```bash
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```
