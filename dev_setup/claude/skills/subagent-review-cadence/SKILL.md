---
name: subagent-review-cadence
description: When and how to spawn review sub-agents during implementation. Use after completing a meaningful implementation unit.
type: process
---

**When this applies:** after completing a class, significant algorithm, schema change, or any meaningful implementation unit.

## Cadence

Spawn **1-2 review sub-agents** after each meaningful unit:
- Agent 1: accuracy and spec compliance (does it do what was specified?).
- Agent 2: adjacent impact (does it silently break anything nearby?).

Do not proceed to the next unit until both are clean.

## Monorepo note

Module changes can silently break consumers in adjacent modules. Agent 2 should specifically check imports, interface changes, and cross-module dependencies.

## When to skip

Mechanical changes only: imports, renames, formatting, trivial one-liners, repetitive same-pattern additions. Batch these and review the batch.

If subagent-driven development is active (two-stage internal review), that satisfies this cadence.

## Sub-agent briefing

Include in every sub-agent prompt:
- Full context (what changed, why, expected behavior).
- Specific files modified.
- What to check (spec compliance, adjacent breakage, or both).
- Expected depth and directness (sharp peer standard).
