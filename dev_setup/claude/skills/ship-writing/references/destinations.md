# Destination notes

`~/.claude/WRITING.md` applies to every destination. These notes list only the differences. Read the note for the destination before drafting.

## PR descriptions

Lead with the outcome in one sentence. Then give the motivation: what the change unblocks or fixes. The diff already shows how. Add technical detail only where a reviewer can't infer it from the diff, like cross-repo coordination or a hidden invariant. Follow the repo's PR template when one exists.

## Review comments

Each comment holds one finding: the location, the problem, and a concrete fix. Use plain English, and expand acronyms on first use. Skip the preamble and the praise.

## Replying to a reviewer

- Reply inline, in the thread the comment lives in. Don't answer review comments with a top-level PR comment.
- Answer first, in 1 to 3 sentences. If the answer needs more, change the doc instead of the thread.
- Skip the praise opener, the restated comment, and repeated apologies.
- Admit a mistake plainly and state what you checked. Keep a correction specific.

## Revising after review

- Change only what the reviewer asked for. A broad rewrite in answer to a narrow ask forces a full re-review and costs the reviewer's trust.
- Show the before and after of each changed passage.
- Reread the whole section that contains each change, as a first-time reader, before pushing.
- Push the fix as a new commit whose message names the change. Then reply once in each thread, inline, in one line: the fixing commit SHA or the reason for declining. Answer a question in 1 to 3 sentences. Don't post a top-level summary comment.

## Slack and email

Match the register to the audience. Cross-team and external messages are more formal, with links up front. Peers get shorter messages. Don't explain what a technical reader already knows.

## Jira and Confluence

A Jira description leads with the decision or the ask. It doesn't restate the title. A Confluence page that is really a design doc follows `~/.claude/DESIGN_DOCS.md`. A status update or record stays as short as its content.
