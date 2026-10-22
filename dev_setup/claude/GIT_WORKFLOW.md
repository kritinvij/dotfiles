# Git Workflow: Start to PR

Every step in this file is mandatory.

This file is the home of the branch lifecycle and the no-force-push rule. Both apply in every repo, on every branch, in every session.

## No force-push

Once a commit is pushed, it stays as it is. Don't use `--force`, `--force-with-lease`, `git commit --amend` on a pushed commit, or any rebase that touches one. Fix a pushed commit with a new commit on top.

## 1. Starting work

1. Update main in the main checkout: `git switch main && git fetch origin && git rebase origin/main`. A rebase surfaces any local commit that drifted onto main, where a plain `git pull` would hide it. If the rebase reports conflicts, resolve them before going further.
2. Create a worktree and branch from the updated main with the `worktree-setup` skill. Branches are never created or switched inside the main checkout.

## 2. Before opening a PR

3. Rebase on main again inside the worktree, right before opening the PR.
4. If that rebase conflicts, read both sides and understand the conflict before resolving it. Don't default to "ours" or "theirs".
5. Run the tests and the build, and read the output. In a repo with `build.gradle` or `settings.gradle`, run the `java-pr-gate` skill. A PR opens only on a verified branch.
6. Squash the branch into one commit, then push it to open the PR. The squash happens before the first push, so it rewrites nothing that was pushed. Use the `commit-standards` skill for the message.
7. Open the PR with the repo's template if one exists, and link the Jira tickets. Use the `pr-description` skill. Pushing and opening the PR are Hard Stops (see CLAUDE.md).

## 3. After the PR is open

8. Add further work as new commits on top of the squashed commit.
9. Before each push, run `git pull`, which fetches and merges. The push then never lands on stale local state.
10. Don't rebase a pushed branch, even without conflicts. If main now conflicts with the PR, run `git merge origin/main`. If it doesn't conflict, do nothing. Step 3 is the only rebase allowed, because nothing was pushed yet.
11. Once a PR merges, start the next change fresh from step 1. Don't add commits to a merged PR.
12. Every new commit on an open PR starts and ends with its review threads. This covers bot threads (the PR-assistant bot, Devin, Copilot, CI-fix bots) and human ones.
    - **Before the commit:** list every unresolved thread, with its author, file, and line. Also list any commits a bot pushed since your last one, and show the user their diffs.
      ```bash
      gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{isResolved path line comments(first:10){nodes{author{login} body url}}}}}}}' -F o=<owner> -F r=<repo> -F n=<pr> --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved|not)'
      ```
      Top-level bot comments outside threads: `gh pr view <pr> --comments`.
    - **Handle every finding in this iteration.** Fix each valid one. Decline the rest with a stated reason.
    - **After pushing, draft one inline reply per thread.** It holds the fixing commit SHA or the reason for declining, in one line. Don't post a top-level summary comment.
    - **Posting the replies is a Hard Stop.** Draft them through the `ship-writing` skill. Show each draft next to its finding, and post only after the user confirms they read every line.

## Recovering from a rebase on a pushed branch

If a pushed branch was rebased locally by mistake, recover with a merge. Don't use `git reset --hard`, `git reset --keep`, or move the branch ref back to the remote tip. Those discard commits. Use this approach without asking which one to pick.

1. Run `git merge origin/<branch>`. Both sides hold the same content, so it usually merges cleanly.
2. Check the result. `git diff <rebased-sha> HEAD --stat` must be empty. `git diff origin/main...HEAD --stat` must list only the intended files.
3. Re-run the build and tests on the merge commit, then `git push` with no force flag.

The branch history gains a duplicated pair of commits and a merge commit. That cost is accepted, because the PR's net diff and final tree stay the same. Step 10 prevents the situation.

## Resulting commit shape

The PR holds one squashed commit, then zero or more follow-up commits. The squash in step 6 happens once, before the first push. No commit is rewritten after it is pushed.
