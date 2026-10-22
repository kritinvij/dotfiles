# Human Readability Checklist for Technical Documents

Use this checklist to evaluate the human readability of PRDs, ADRs, RFCs, technical
specifications, and similar engineering documents.

The goal is to answer:

> **How easy is it for the intended human reader to understand, navigate, and act on this document?**

Do **not** evaluate whether the technical decisions are correct, whether the proposed
solution is optimal, or whether every expected section is present. Those should be
evaluated separately.

## How to evaluate

First determine the likely intended audience from the document itself. Evaluate
readability relative to that audience, reading as that reader — not as a checklist
validator hunting for violations.

Then answer every check below with a verdict:

- **`pass`** — you looked for this kind of friction and found nothing a reader would notice.
- **`minor`** — the friction occurs **once**, at a level the intended reader would
  actually notice (not a trivial stumble they'd read past without slowing down).
- **`recurring`** — the same kind of friction appears **in several places**, or one
  instance is severe enough that the reader must stop and work through it.

Any verdict other than `pass` **requires evidence**: a short quote (≤ 15 words) or a
precise pointer (section name) from the document — for `recurring`, evidence of at
least two places, or the one severe instance. If you cannot point to concrete
evidence, the check passes.

Judge each check independently; do not let one bad section fail every check, and do not
let overall polish pass a check whose specific friction is present. You are counting
observable instances, never rating severity on a scale.

You never compute or output scores. Verdicts and evidence only.

---

## 1. Clarity — can the reader understand each statement on the first read?

- **clarity.1 — Reread-to-understand:** A passage requires rereading or interpretation
  before its meaning is clear (convoluted, ambiguous, or overloaded sentences).
- **clarity.2 — Unresolved references:** A pronoun or reference ("this", "it", "that
  approach", "the above") has no obvious antecedent, or a reference points somewhere
  the reader must hunt for. This includes referring to requirements or sections by
  bare identifier — "FR-3", "per section 4.2", "as defined above" — without restating
  the substance: readers do not hold numeric IDs in working memory, so the document
  must say what the requirement is where it relies on it. Defining an ID next to its
  full text (a requirements table) is fine; referring by ID alone is the friction.
- **clarity.3 — Abstract where concrete is needed:** A claim, requirement, or metric is
  left abstract or unquantified where the reader needs a concrete value, example, or
  threshold to understand or act on it.
- **clarity.4 — Undefined or shifting terms:** A key term is used before it is
  explained, is never explained, or is used with inconsistent meaning across the
  document.

## 2. Conciseness — does every passage earn its length?

- **conciseness.1 — Repetition:** The same idea is stated more than once without the
  restatement adding information (including summary sections that only restate).
- **conciseness.2 — Filler:** Sentences of generic commentary that convey no
  document-specific information (throat-clearing intros, "this is an important
  consideration", restating the obvious).
- **conciseness.3 — Unneeded background:** Background or context beyond what the
  intended reader needs to follow the document.
- **conciseness.4 — Over-explanation:** Simple concepts explained at a length
  disproportionate to their difficulty or importance.

Do not fail a check merely because the document is long; necessary detail is not a
conciseness problem.

## 3. Coherence — does the document form one followable argument?

- **coherence.1 — Forward dependencies:** A section relies on a concept, decision, or
  term that is only introduced later in the document.
- **coherence.2 — Broken ordering:** Ideas appear in an order the reader must mentally
  rearrange, or a transition is abrupt enough to break the thread.
- **coherence.3 — Unsupported conclusions:** A stated conclusion, decision, or
  recommendation does not follow from information presented before it.
- **coherence.4 — No through-line:** The document reads as accumulated fragments rather
  than one line of reasoning (e.g. context → problem → constraints → proposal →
  implications).

## 4. Structure — does the layout help the reader navigate?

- **structure.1 — Over- or under-structuring:** Heading hierarchy fragments the content
  (many tiny sections, headings for single sentences — a common AI pattern) or is too
  flat to navigate (walls of prose with no landmarks).
- **structure.2 — Scattered grouping:** Information that belongs together is split
  across distant sections, forcing the reader to reassemble it.
- **structure.3 — Buried decisions:** Key decisions, requirements, or conclusions are
  not visually discoverable (via headings, tables, emphasis, or position) — a scanning
  reader would miss them.
- **structure.4 — Wrong form for the content:** Content is in the wrong medium for
  what it describes: prose where a table or list would carry it far better; bullets
  where connected prose is needed to preserve the reasoning; or paragraphs straining
  to narrate what a diagram shows at a glance — a multi-party interaction that reads
  as "A calls B, then B writes to C, then C notifies A" is a Mermaid sequence
  diagram, branching logic walked through in "if X then... otherwise..." prose is a
  flowchart, and a state lifecycle listed as transitions is a state diagram. Fail
  this only when the prose demonstrably strains (the reader must track the players
  or branches in their head); a diagram is not required for every sequence.

## 5. Prioritization — does the important feel important?

- **density.1 — Flat emphasis:** Trivial or peripheral details receive space or
  prominence comparable to key decisions and requirements.
- **density.2 — Undifferentiated statements:** The reader cannot tell decisions from
  assumptions, examples, or background without inferring it.
- **density.3 — Hidden caveats:** An important caveat, risk, or limitation is buried
  where a reader is unlikely to see it.
- **density.4 — Buried lede:** The document (or its major sections) does not surface
  the most important information first; the reader must dig for what matters most.

This is not conciseness: a document with no redundant sentence can still fail all four.

## 6. Language — does it read like professional writing for humans?

- **language.1 — Formulaic phrasing:** Template or AI-boilerplate constructions recur
  ("It is important to note", "In today's fast-paced...", mechanically identical
  section patterns).
- **language.2 — Hedging:** Qualifiers and hedges ("might", "could potentially",
  "should generally") blunt statements the reader needs to be definite.
- **language.3 — Awkward construction:** Sentences a professional editor would rewrite
  — tangled clauses, misused vocabulary, unnecessary jargon. Jargon includes insider
  metaphor shorthand that assumes the reader shares the author's mental model:
  "load-bearing", "seam", "belt and suspenders", "blast radius" — name the concrete
  thing instead.
- **language.4 — Repetitive patterns:** Repeated sentence shapes or rhetorical frames
  that make the prose feel generated rather than written: triads,
  one-sentence-per-bullet monotony, and especially the contrast formulas — "it's not
  X, it's Y", "not X but Y" ("not a cache but a queue"), "not just X but Y",
  "X is Y, never Z". A contrast formula spends words denying a claim nobody made;
  state what the thing is.
- **language.5 — Fragments and run-ons:** A sentence with no finite verb ("Refined
  continuously." "Terminal states, clocks, re-entry."), or two independent clauses
  joined by a colon, semicolon, or em-dash where a period belongs. A conjunction that
  names the relation ("so", "because", "but", "unless", "if") is not a run-on. Count instances. A
  doc that does this in several paragraphs is `recurring`.
- **language.6 — Copula avoidance and metaphor shorthand:** "serves as", "functions as",
  "acts as", "marks", "boasts" where "is" or "has" is meant; or a metaphor standing in
  for a property the doc could name ("load-bearing", "seam", "blast radius"). Quoted
  mentions do not count.

Do not fail a document merely for being formal, and do not infer that AI-generated text
reads worse simply because it appears AI-generated — every fail needs its quote.

## 7. Cognitive load — how much work does the reader do?

- **cogload.1 — Working-memory burden:** Understanding a passage requires holding
  several earlier concepts in mind simultaneously because the document does not restate
  or link them where used.
- **cogload.2 — Assembly required:** Answering a basic question the document should
  answer ("what was decided?", "what are the requirements?") requires jumping between
  sections and consolidating scattered statements.
- **cogload.3 — Unstated relationships:** The reader must infer relationships (causes,
  dependencies, sequence) that the document could have stated.
- **cogload.4 — Effortful extraction:** What was actually decided or required cannot be
  determined without searching through prose.

---

## Per-document result

For each document produce one object (the caller's prompt says where and in what
container to return it):

```json
{
  "path": "docs/initiatives/x/spec.md",
  "checks": {
    "clarity.1": { "verdict": "pass" },
    "clarity.2": { "verdict": "minor", "evidence": "\"this approach\" in Rollout has no antecedent" },
    "language.2": { "verdict": "recurring", "evidence": "\"should generally\", \"might improve\" across Goals and Metrics" },
    "...": "every check, in rubric order"
  },
  "topIssue": "<= 20 words: the highest-impact readability problem, or empty string"
}
```

Every `minor` or `recurring` verdict carries `evidence`; a `pass` carries no evidence
field. Do not output scores, counts, or per-dimension summaries — the caller derives
everything from the verdicts.

---

# Scoring — computed by the caller, never by the judge

Each dimension's score follows mechanically from its check verdicts (six for Language, four for the rest):

| Worst verdicts in the dimension | Dimension score |
| ------------------------------- | --------------- |
| All checks `pass`               | 5               |
| Any `minor`, no `recurring`     | 4               |
| One `recurring` check           | 3               |
| Two `recurring` checks          | 2               |
| Three or four `recurring`       | 1               |

**Readability Score = average of the seven dimension scores × 20**, a score from
**20–100**.

| Score  | Rating     | Interpretation                                     |
| ------ | ---------- | -------------------------------------------------- |
| 90–100 | Excellent  | Publication-ready; exceptionally easy to consume   |
| 80–89  | Good       | Clear and effective; only minor editing needed     |
| 70–79  | Acceptable | Readable but meaningful improvements are available |
| 60–69  | Poor       | Reader friction is significant                     |
| <60    | Very Poor  | Substantial rewriting recommended                  |

---

# Evaluation guardrails

Do not reward or penalize the document based on:

- whether you agree with its technical decisions;
- whether the proposal is technically correct;
- whether a specific PRD/RFC/ADR template was followed;
- document length by itself;
- sophisticated vocabulary by itself;
- the presence or absence of diagrams for their own sake — a missing diagram matters
  only where structure.4 applies: the prose demonstrably strains to carry what a
  diagram would show.
