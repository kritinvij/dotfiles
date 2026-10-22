---
name: ship-writing
description: Use before drafted text leaves this chat for other readers. That covers a Slack message, a GitHub PR description, review comment, or reply to a reviewer, a revision to a doc under review, a Jira or Confluence page, an email, a Google Doc, a design doc, an ADR, or an RFC. Skip it for a chat reply to the user, a code comment, a commit message, or text the user dictates word for word. Runs the draft through the repo's writing-style linter, when one exists, and the doc-readability skill until both are clean. Then self-audits against ~/.claude/WRITING.md (plus ~/.claude/DESIGN_DOCS.md for a design doc) and hands the draft back for approval. Keeps one scratch file across revision rounds until approval. Sends nothing and opens no PR. CLAUDE.md's Hard Stops still gate every send.
---

# Ship writing

Every draft for other readers goes through this loop before it reaches its destination.

## 1. Draft in one scratch file

For a design doc, ADR, or RFC, read `~/.claude/DESIGN_DOCS.md` before the first line. For every destination, read its note in `references/destinations.md`.

Before revising a doc on an open PR, pull the branch. List every commit someone else pushed since your last change, bots included, and show the user each diff. That text goes out under the user's name, so it gets read like the rest.

When the draft answers a reviewer, edit only the sentences their comment is about. Follow "Revising after review" in `references/destinations.md`.

Write the draft to a `.md` file. If the linter checks only files inside its repo, put the scratch file in that repo's main checkout, such as `_scratch_<name>.md` at the repo root. Don't write the draft into its destination first.

Keep this one file for the whole task. When the user asks for changes in step 5, edit it in place and rerun steps 2 to 4.

## 2. Lint until it prints `✓ no issues`

Use the repo's own writing-style linter, found in its docs or tooling. If the repo has none, skip this step and say so in the results line.

Run it from the main checkout, freshly pulled. A worktree's copy of the linter can predate new rules and pass a draft that CI fails.

A linter that reports nothing to check, or warns that the file is outside the repository, checked nothing. Treat that as a failure and move the file into the repo.

Fix every finding. If you disagree with one, fix it anyway, or add `human-written: true` frontmatter with a stated reason. A repo's writing-style doc can hold rules the linter can't enforce, like a sentence-length cap. Check those by hand.

## 3. Score with doc-readability and fix real issues

Run the `doc-readability` skill on the same file. Fix every issue it flags, then rerun it and report the new score. The label forms in DESIGN_DOCS.md's "Tag the payload" stay as written, even when flagged as fragments. There is no target score. A doc is done when every real issue is fixed.

### When to stop rescoring

Each run is a fresh grader. It can raise a new minor nit, drop an old one, or re-flag a fixed passage in new words. On a long doc, chasing every flag never ends.

After 3 rounds on the same doc, stop once both of these hold:

- No finding in the last 2 rounds was a `recurring` correctness or clarity defect. Those are wrong claims, undefined terms the doc depends on, and broken cross-references. Recurring taste notes, like word variety or merging a definition, don't count.
- The score moves up and down within about 10 points instead of trending.

Then stop and say so. Name the score range and the kind of nit later rounds kept raising.

## 4. Self-audit what the linter can't check

The linter catches banned phrases, dash and semicolon density, and frontmatter shape. Run every **Test** in `~/.claude/WRITING.md` in order, plus the destination note. For a design doc, also run every test in DESIGN_DOCS.md and walk "What the doc has to answer" item by item.

Run these first, on every section, because they catch the worst failures:

- **The first sentence stands alone.** No opening sentence relies on a reference outside it.
- **No warm-up, no wind-down.** Delete the first and last sentence of each unit. If no fact was lost, keep them deleted.
- **Sentence length.** Split or cut any sentence over 25 words. Most should sit under 20.
- **Cut pass.** Delete every word whose removal leaves the meaning unchanged. Expect the draft to shrink by a fifth or more. If it didn't shrink, do the pass again.
- **Reread after every edit.** Read each touched section in full, top to bottom, as a first-time reader.

## 5. Show the draft and confirm it was read

The user owns every line sent under their name. A doc that reads as unread costs trust no later fix buys back. This step gets the text read.

- **Lead with the results line:** `Lint: <✓ 0 issues | N findings> · Readability: <score> (<band>) · Confidence: 0.XX`. Confidence rates how well the draft's claims are verified, on CLAUDE.md's scale. If a step didn't run, name it and the reason in place of its value. The line stays in chat and never enters the draft.
- **Show the full text.** For anything over about 30 lines, show one section at a time and wait for an "ok" before the next.
- **For a revision,** show the before and after of each changed passage, then the whole section around it.
- **For a review reply,** show it next to the comment it answers. Flag a reply over 3 sentences.
- **Ask: "Have you read every line of this?"** A go-ahead without a yes isn't approval. If part is unread, name that part and wait.

If the user asks for changes, edit the same scratch file, rerun steps 2 to 4, and return here. If they approve, go to step 6.

Approval means "this text is right." Sending it is a separate decision, even when the user gives both at once.

## 6. Copy to the destination, then delete the scratch file

Paste the approved text where it goes: the Slack composer, the PR or comment body, or the doc. After the copy succeeds, delete the scratch file. Don't delete it before approval. If the delete is blocked, give the user the path and the `rm` command.

## 7. This skill sends nothing

The loop ends with an approved draft sitting in its destination. Posting it is a Hard Stop in CLAUDE.md. That covers a Slack message, a Jira or Confluence comment, an email, a published artifact, and opening or pushing a PR, draft PRs included. Ask before it goes out, as a separate question from step 5.
