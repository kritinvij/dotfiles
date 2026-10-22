# Design Docs

Every rule in this file is mandatory, and each **Test** is a required check.

For design docs, ADRs, RFCs, and any doc with several readers over time. Read this before drafting or reviewing one. It builds on `~/.claude/WRITING.md`, which covers sentences, paragraphs, formatting, and evidence. The team's template and a repo's doc conventions win where they're more specific.

Same format as `WRITING.md`: principles and tests, independent of topic.

**Overall principle.** Write as if explaining the decision to a colleague, not filling in a template. State the problem before the decision. **Test:** if a section reads like a filled-in checklist, rewrite it as reasoning.

## Size the doc to the decision

**Principle.** The doc is as long as the decision needs. A one-way, cross-team change earns a full doc. A reversible change inside one team fits on one page. The body holds the reasoning. Raw data, long tables, and history go in an appendix or a link.

**Why.** Reviewers read the first page closely and skim the rest. A long body hides the one tradeoff they needed to judge.

**Test.** Could a reviewer read the body in 10 minutes? If not, move detail to the appendix until they can. Could any section lose half its sentences and still carry its point? If so, cut them.

## The summary carries the decision

**Principle.** The doc opens with a `TL;DR:` of at most 3 sentences: the problem, the decision, and its main cost.

**Why.** Many readers see only the summary. It has to be enough for them to agree, object, or route the doc to someone else.

**Test.** Show only the TL;DR to someone who hasn't seen the doc. Can they say what's being decided and what it costs?

---

# What the doc has to answer

A template's headings are optional. The questions behind them aren't. Each question below has an answer in the doc, or a line under "Sections skipped" saying why it doesn't apply. Answer each one in as few sentences as it takes. An item that needs one sentence gets one sentence, not a section.

- What happens if this isn't done?
- Why now? Keep the problem separate from the trigger that makes this the right time.
- How will success be measured? Name the metric and the query, dashboard, or event that produces it.
- What are the non-functional requirements (latency, availability, volume, reliability tier), and why that tier?
- What happens when an assumption breaks: a dependency fails, input is malformed, an event arrives twice?
- If the doc adds a new component, why can't an existing one do the job?
- What does it depend on, and what happens when each dependency fails?
- Does it change data or interfaces that other teams consume, and have those teams reviewed it?
- What are the security, privacy, accessibility, and cost implications?
- What gets instrumented? Prefer existing events and justify new ones.
- How does it roll out, and how does it roll back?
- Could a teammate build the main path from this doc alone?

**Test.** Walk the list against the draft. Every item has an answer or a skip line.

---

# Structure

## Headings do work

- Each sub-decision gets its own heading. Don't bury it inside a larger section.
- When a section answers one question, make the question the heading.
- Split consequences into positive, negative, and mitigations.

**Test.** Read only the headings. They should outline the decision.

## Tag the payload

A label in front of the key line lets a skimmer get the outcome without reading the reasoning. Standard forms:

- `TL;DR:` before the doc's opening summary, as set out in "The summary carries the decision".
- `Answer:` or `Proposal:` before the sentence that carries a section's result.
- A bracketed outcome on an option's label, like `(Works)`, `(Failed)`, `[Recommended]`.
- `Suggested choice: <option>` as its own line after a tradeoff discussion.

These labels are fragments by design. A readability grader flagging these labels isn't a defect.

## Set the frame before the design

- **Constraints.** Name everything that can't change (regulatory, contractual, platform, organizational) in its own section before any solution. Refer back to them by name when an option gets ruled out.
- **Scope.** State what the doc decides, as well as what's out of scope.
- **Glossary.** When 3 or more terms are project-specific or used narrowly, define each once before the design. Use them the same way throughout.
- **History.** If this isn't the first attempt, say what was tried before, why it stopped, and what's different now.
- **Phases.** When work ships in stages, give each stage its own goals.

**Test.** Can a reader decide in under a minute whether the doc answers their question?

---

---

# Links

**Principle.** A design doc records a decision at one point in time, so it links as little as possible. Each link it keeps points at a pinned version, not a path that changes. Living docs, like references, READMEs, and guides, do the opposite. They link each other by path, so a broken link forces an update. They link a design doc only by a pinned version, or they copy the fact in.

**Why.** A moving link in a record drifts until it points at something that contradicts the decision. A pinned link in a living doc goes stale without anyone noticing.

**Test.** For each link, ask whether the source records a moment or tracks the present. A record links only when the reader must see the exact thing, and pins it. A link to something not yet merged can't be pinned yet. Name it in prose now and pin it after it merges.

---

# Evidence in a design doc

`WRITING.md`'s Evidence rules apply in full. Three additions:

- **Show the delta.** For a change to an existing system, one table with a row per component: current behavior, target behavior, what changes. Follow it with a short list of what does not change.
- **Name the unmeasurable.** Split success criteria into measurable (with a baseline) and immeasurable (named anyway). Don't force a fake number, and don't drop the goal.
- **Appendix the raw data.** Measurement windows, formulas, samples, tool output. The body states results and points to the appendix.

---

# Alternatives and risks

- **Advantage before disadvantage, then the verdict.** Every rejected option gets its real strength stated before its weakness.
- **Explain easy calls.** When a choice was obvious, state the fact that made it obvious.
- **Sub-variants count.** Give each variant of the chosen approach that you considered and dropped its own line.
- **Many options, same criteria.** Use a table, then a sentence naming the verdict and the criterion that decided it. For a long pros-and-cons list, use `+` and `-` prefixes instead of prose.
- **Risks carry their remedy.** Each risk states its impact, its mitigation, and a rough effort. A risk with no mitigation says so, and appears under open questions too.
- **Decision log only when contested.** When reviewers could reasonably question several choices later, end with a table: decision, reason, rejected options. Skip it when the choices are obvious.

**Test.** For each rejected option, could its advocate agree that the doc states its strength fairly?

---

# Open edges and doc state

## Keep open edges owned

- **Non-goals carry a re-entry condition:** the event or state that would bring them back in scope.
- **Skipped template sections get a line** under "Sections skipped" with the reason. This differs from a non-goal: "not applicable" or "not yet", not permanent scope.
- **Open questions carry an owner and a pointer.** Format: `TODO(<owner>): <question>. Prior discussion: <link>.` Tag a team when no person is assigned. Address a specific person directly, in second person, where their input is needed. Mark the section resolved once every item is answered. A question the author can answer gets the literal answer, not hedged prose.
- **Recurring review questions go in an FAQ** at the end, one direct answer each.

## Keep the doc's state honest

- **Status drift goes at the top, dated,** before any content it invalidates.
- **Sign-off is marked inline,** next to each reviewer's name. When reviewers own different parts, use a table: team, reviewer, status, date approved, section to review. List the doc's tabs in the header if there are several.
- **Execution gets a ledger:** task, owner, effort, timeline, status, updated as rows complete.
- **Mark where the reviewed content ends.** Put an explicit end marker before scratch notes, minutes, or raw research. The lower the bar after it, the more visible the marker.

**Test.** Could someone opening the doc for the first time tell its current status, who approved what, and which parts are unreviewed?
