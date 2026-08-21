# Git Workflow: Start to PR

This is the full lifecycle for any branch work: starting on main, creating a worktree, opening the PR, and pushing later updates to it. The "Worktrees required" and "Never force-push, under any circumstances" rules in CLAUDE.md's Engineering Practices are absolute and apply throughout this sequence. This file specifies how they apply at each step.

## 1. Starting work

1. Start from an updated main branch of the repo: switch to main, then run `git pull`.
2. Rebase main against `origin/main` before creating anything new, even if `git pull` in step 1 already fetched. This surfaces drift from other people's merged work before it can turn into a conflict later.
3. Only after that rebase, create a new worktree and branch from the freshly rebased main. Use the `worktree-setup` skill. See "Worktrees required" in Engineering Practices: never create or switch branches inside the main checkout itself.

## 2. Before opening a PR

4. Rebase main again inside the worktree, immediately before opening the PR, to pick up anything that landed on main since step 1.
5. If that rebase produces conflicts, read what changed on both sides and understand why the conflict exists before resolving it. Do not default to keeping "ours" or "theirs" without that review.
6. Squash every commit on the branch into a single commit, then push that single commit to open the PR. This squash happens locally, before the branch has ever been pushed, so it does not conflict with the no-force-push rule below, which only applies once a commit has been pushed. Use the `commit-standards` skill for the commit message format.
7. Open the PR using the repository's PR template if one exists, and link the relevant Jira ticket or tickets. Use the `pr-description` skill.

## 3. After the PR is open

8. Add any further work as new commits on top of the squashed commit already on the PR. Once a commit is pushed, never rewrite it: no `--force`, no `--force-with-lease`, no `git commit --amend`, no `git rebase -i` touching a pushed commit. If main has since moved and now conflicts with the PR, resolve that with `git merge origin/main`, which creates a merge commit, rather than rebasing the PR branch onto main. To correct something in a commit that is already pushed, add a new commit with the fix instead of amending the old one. This step is the detailed application of "Never force-push, under any circumstances" from Engineering Practices: it is not relaxed for this workflow.
9. Before pushing any update, run `git pull` (a fetch followed by a merge, not a rebase) against the remote branch, so the push never lands on top of stale local state.

## Resulting Commit Shape

- The squash in step 6 happens exactly once, before the branch is pushed for the first time.
- After that first push, the PR's commit history is: one squashed commit, followed by zero or more follow-up commits, none of which are ever rewritten.
