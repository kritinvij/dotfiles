---
name: doc-readability
description: Score Markdown docs (PRD, ADR, RFC, spec) for human readability — a 20–100 score, the top issue, and concrete improvement suggestions per doc. Use whenever someone wants a doc's readability judged, even without the word — "score this doc", "how readable is this PRD", "is this spec too verbose / hard to follow / clear enough to share", "does it read like AI slop" — to compare drafts, or from open-pr Step 1 for newly added docs. With no paths given, scores the docs the current branch adds or significantly modifies.
---

# doc-readability — score docs for reader friction

Scores documents the way an intended reader experiences them — clarity, conciseness, coherence, structure, prioritization, language, cognitive load — using [references/readability-rubric.md](references/readability-rubric.md). Reports scores and concrete fixes; what to do with them is the caller's business.

## Inputs

Explicit file paths when given. Otherwise default to the Markdown docs the current branch adds or modifies:

```bash
git diff --name-only --diff-filter=AM "$(git merge-base origin/main HEAD)"..HEAD -- '*.md' ':!docs/_templates/**'
```

Drop modified docs whose change is trivial (typo, link, or formatting fixes — check `git diff --stat`); a significantly modified doc is scored whole, not just its diff. Nothing to score → say so and stop.

## Procedure — evidence checklist, sonnet

The judge never assigns scores. It answers the rubric's binary-style checks (`pass` / `minor` / `recurring`, evidence quote required on every non-pass) and the caller computes the score mechanically — scalar judgments drift between runs; evidence counts don't.

1. **Spawn one sub-agent with `model: sonnet`** — never burn the session's own model on this, and don't substitute haiku. The prompt:
   - Read the rubric at its absolute path — spell out `<repo>/.agents/skills/doc-readability/references/readability-rubric.md` in the prompt so the sub-agent never has to search for it — and each target doc (absolute paths too).
   - Apply the checklist to every doc independently and return in the final message a raw JSON array with one per-document result object per the rubric, plus a `suggestions` key: up to 3 concrete edits targeting the failed checks.
2. **Validate**: every non-`pass` verdict must carry evidence; every rubric check present per doc. Malformed output → re-run once; if still malformed, report as low-confidence.
3. **Score** (per the rubric's Scoring section): per dimension, 5 if all checks pass, 4 on any `minor`, 3/2/1 as `recurring` checks stack; overall = **mean of the 7 dimensions × 20** (range 20–100).

## Output

One line or table row per doc: score, rating band (≥90 Excellent, 80–89 Good, 70–79 Acceptable, 60–69 Poor, <60 Very poor), top issue. A doc **needs attention** when its score is under 80 or any single dimension is ≤ 3 — one bad axis can hide inside a passing mean. For flagged docs, include the weak dimensions, the failed checks' evidence, and the suggestions.

## Calibration

The checklist + sonnet + cap-aggregation pairing is calibrated by [evals/](evals/README.md) (good fixtures ≥ 80, mediocre 55–79, bad ≤ 69). Change the rubric's checks, the aggregation, the thresholds, or the judge model only with a green `run-eval.sh`.
