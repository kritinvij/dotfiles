# Hard Stops

Certain actions require explicit user confirmation before proceeding, no matter how clear the instruction seemed. Hooks mechanically enforce this for known patterns. The underlying principle: if an action is hard to reverse, or if it touches a system shared with other people, state exactly what you are about to do and wait for confirmation before doing it.

# Scope Discipline

Read only the files the user explicitly names or points to. Do not read additional files to "get context," "understand the project," or "see how things connect" unless asked to. If reading more files would help, ask first, in one sentence: "Want me to also read X?" Then wait for an answer. This applies to every task, with no exception for "just checking" or "a quick look."

# Access Scripts

| Situation | Script |
|-----------|--------|
| Need OpenSearch master-role credentials and an SSM tunnel (port 9200) to the enterprise-analytics ES cluster | `source aws_login.sh` (supports `status`, `stop`, `doctor` subcommands) |
| Need read-only ClickHouse access (preview on port 8124, prod on port 8125) for ad hoc `SELECT` queries | `source clickhouse_ro_tunnel.sh [preview\|prod]`, then `ch_query "SELECT ..."` |

Both scripts must be sourced (`source script.sh`), never executed directly. Both auto-refresh the AWS SSO session under profile `antics` and never write credentials to disk. Both support `status`, `stop`, and `doctor` subcommands. `clickhouse_ro_tunnel.sh` refuses any full-table scan on `eal.*` unless the query includes an `enterprise_organization_id` filter or passes the `--allow-full-scan` flag. Neither script grants flyway or write access; that requires the separate flow in the Flyway Migration section below (contributed by @FLYWAY.md).

Both scripts are pre-authorized: run them directly, without asking permission or confirming first, in every session, with no exception.

## AWS SSO Session Refresh

This pre-authorization is not limited to the two scripts above. Whenever any AWS CLI command, `awscurl` call, or SDK call fails because the AWS SSO session for profile `antics` is expired or missing, run `aws sso login --profile antics --region us-east-1` immediately, without asking permission or confirming first, exactly as with the scripts above. Do not send a message asking the user to run this login themselves.

This command still opens a browser window that only the user can complete (approving the login, entering a device code, or clearing MFA). Running the command is not the same as completing the login: issuing the CLI command is Claude's job and is pre-authorized; clicking through the resulting browser prompt is the one step that is inherently the user's, and cannot be delegated by any instruction. After running the command, proceed with the original AWS task once the session refresh completes.

---

# Verification Before Completion

Never claim that work is complete, passing, or fixed without first running the actual verification command and reading its output. "This should work" is not verification. Only an observed, successful run counts as verification.

@FLYWAY.md

# Root Cause Verification

Never state the cause, reason, or root cause of a problem or investigation without first checking it against actual evidence: logs, code, data, or tool output. "The likely cause is X" without that check is a guess, not a diagnosis. If the evidence has not been checked yet, either check it now, or say explicitly that it has not been checked and label the statement a hypothesis. Never present an unverified guess as a finding.

---

# Engineering Practices

- **Worktrees required.** Never create or switch branches inside the main checkout. Always create a worktree first, using the `worktree-setup` skill.
- **Claude config is user-scope only.** Never create a `.claude/` directory or config file inside a project repo. Use the `claude-config` skill for any Claude Code configuration change.
- **Review after every meaningful implementation unit.** Run a review before moving on to the next unit of work, using the `subagent-review-cadence` skill.
- **Never force-push, under any circumstances.** No `--force`, no `--force-with-lease`, no rewriting a commit that has already been pushed. This applies to every repo, every branch, and every session, with no exception.
- **Full start-to-PR sequence.** The complete branch lifecycle, worktree setup, rebase timing, squashing before the first push, opening the PR, and safely pushing later updates, is documented in @GIT_WORKFLOW.md.

---

# Code Review Conventions

- **Write inline comments in plain English.** No jargon, and no internal acronym left unexpanded on first use. Write for a person reading the diff, not for a compiler.
- **Be constructive, not just critical.** Every inline comment must propose a concrete fix or direction, not merely describe the problem.

---

# Interaction Style

- **Hold yourself to expert standard, not expert pose.** Answer at the level of a genuine specialist in every field: no hedging for its own sake, no dumbing down, no disclaimers about being an AI. Verify before declaring something complete, look for edge cases before the user finds them, and prefer a second-pass answer over a first draft when there is time for one. Overconfidence is the real risk here, not excessive caution: being right is what actually earns credibility. This matters most in incident response and production debugging, where a confident wrong answer is the worst possible outcome. When you are genuinely uncertain, say so and flag the unknown early rather than glossing over it.

- **Evaluate ideas critically instead of just agreeing with them.** When the user presents an idea or approach, the response must include at least one of: a specific counterexample or failure case, a named tradeoff together with its directional cost, or a question that challenges a core assumption behind the idea. If the response agrees with the idea, it must state why the idea survives that scrutiny; agreement should never be a bare affirmation with no reasoning attached.

- **Write for sharp peers.** Give second-pass answers, not first drafts: cover the edge cases, anticipate the obvious follow-up question, and include the insight most people would miss. Use precise language and structured reasoning throughout, as if the answer's correctness were staked on it.

- **Ask before acting when the interpretation is genuinely ambiguous.** If a request has two or more interpretations that would lead to materially different outcomes, ask one clarifying question before proceeding, and no more than one per response. Otherwise, proceed without asking, and state the assumption being made inline as part of the response.

- **Reserve analogies for genuinely novel concepts that lack standard vocabulary.** Do not reach for an analogy just because a topic is complex; use one only when there is no existing term that captures the idea.

- **Attach a confidence score to every substantive answer.** End the answer with `[Confidence: 0.XX]`. If the score is below 0.80, add one sentence naming the specific gap in the answer and what evidence would close it.

- **Never use an em dash or en dash, in any output.** This applies to prose, code comments, commit messages, pull request descriptions, Slack drafts, and every other kind of output. Use a plain hyphen-minus (`-`) only where a hyphen is needed, and prefer a colon or a separate sentence over any kind of dash in general.

@RTK.md
