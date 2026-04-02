# Interaction Style

- **Ask first, act second.** Ask clarifying questions before proceeding. Never assume. If anything is ambiguous or lowers your confidence, ask until you have what you need.
- **Use analogies** when explaining new or abstract concepts.
- **Be concise and direct.** No filler, no preamble. Lead with the answer or the action.
- **Evaluate critically, not agreeably.** When I present an idea, design, or approach — challenge it. Actively look for gaps, contradictions, and weaknesses. Find data or precedent to validate *or* refute my thinking. Help me work out the kinks. Do not agree to be agreeable.

---

# Skills — Check Before Acting

**If there is even a 1% chance a skill applies, invoke it before responding or taking any action.**

Use the `Skill` tool. Never read skill files directly with Read.

Key skills by category:

| When | Skill |
|------|-------|
| Starting any complex/multi-step task | `superpowers:using-superpowers` |
| Planning before touching code | `superpowers:writing-plans` |
| Brainstorming a design or approach | `superpowers:brainstorming` |
| Executing a plan with subagents | `superpowers:subagent-driven-development` |
| 2+ independent failures/tasks in parallel | `superpowers:dispatching-parallel-agents` |
| Any bug, test failure, unexpected behavior | `superpowers:systematic-debugging` |
| About to say "done", commit, or create a PR | `superpowers:verification-before-completion` |
| Implementation complete, ready to merge | `superpowers:finishing-a-development-branch` |
| Working in an isolated branch/workspace | `superpowers:using-git-worktrees` |
| Receiving or addressing PR feedback | `superpowers:receiving-code-review` |
| End of session — write handoff note for next session | `remember:remember` |

---

# Memory

At the start of every conversation, check the project memory index (`MEMORY.md`) for relevant context. Memory files contain past decisions, preferences, and engineering practices.

- Memory is point-in-time. Verify time-sensitive entries (file paths, function names, flags) against current state before acting on them.
- If a memory conflicts with what you observe in code, trust the code and update the stale memory.

---

# Sub-Agents & Parallelism

Use sub-agents **proactively** — don't wait to be asked.

- **Searches & exploration**: For any multi-step codebase search, reference audit, or broad exploration, spawn an `Explore` sub-agent rather than running Grep/Glob/Bash inline.
- **Verification**: Spawn sub-agents to verify correctness, find consumers, audit coverage, and check adjacent systems.
- **Parallelism**: Use `superpowers:dispatching-parallel-agents` for 2+ independent tasks — run them concurrently.

## Review After Every Step

After each implementation step — before moving to the next — spawn **1–2 review sub-agents**:

1. One to review the produced work for **accuracy and completeness**.
2. One to check **adjacent areas**: other files, modules, systems, or repos that may also need updating. Checking work means not just what was written, but what might have been missed elsewhere.

**Do not proceed to the next step until review is clean.** In mono-repos, a change in one module can silently break others — exhaustive cross-module review is required.

---

# Verification Before Completion

**Never claim work is complete, passing, or fixed without running the verification command first.**

The rule: identify the verification command → run it fresh → read the full output → then make the claim.

"Should work", "looks correct", "probably passes" are not verification. See `superpowers:verification-before-completion` for the full gate function.

---

# Development Workflow

For multi-step implementation tasks:

1. **Plan first** → `superpowers:writing-plans` (before touching any code)
2. **Execute with subagents** → `superpowers:subagent-driven-development` (fresh agent per task, two-stage review: spec compliance then code quality)
3. **Finish the branch** → `superpowers:finishing-a-development-branch` (verify tests → present merge/PR options → clean up worktree)

---

# Engineering Practices

## Before Starting Any Code Changes
Always fetch and rebase from main before touching any files:
```bash
git fetch origin
git rebase origin/main
```
Skipping this pollutes PR diffs with unrelated commits.

## Before Committing Java Changes
Run all four checks before any commit:
```bash
./gradlew build test checkstyle spotlessCheck
```
If spotless fails, run `./gradlew spotlessApply` first, then re-run all four. Never commit until all pass.

## Adjacent Failures
When a command surfaces failures in related/adjacent tasks, fix those too — don't stop at the literal scope of the command. The goal is a clean state, not minimal compliance.

## Checking Tool & System Access
Before asking me whether I have access to an external system (Jira, GitHub, Slack, databases, etc.), check:
1. The `system-reminder` deferred tool list for matching MCP tools (`mcp__*`)
2. Available skills via the Skill tool
3. Any relevant tool already in scope

Only ask me if nothing is found after checking.

---

# Claude Configuration

All Claude configuration lives at **user scope only** — never project scope.

- **MCP servers** → `~/.claude.json` top-level `mcpServers` only
- **Permissions, skills, tool allowlists** → `~/.claude/settings.json` only
- **Never** create `.claude/` directories, `settings.local.json`, or `.mcp.json` files inside a project directory
- If a permission prompt fires during a session, add it to `~/.claude/settings.json` — not to a project-level file
