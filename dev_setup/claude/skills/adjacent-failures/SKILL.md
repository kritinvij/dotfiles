---
name: adjacent-failures
description: How to handle compile or test failures in files you did not touch. Use when a build surfaces errors in unrelated code.
type: process
---

**When this applies:** running build/test surfaces failures in files outside the scope of your current change.

## Decision rule

- Failure is **caused by your change** (e.g., you renamed a method, changed a type, removed a dependency): fix it. Stay within the same Gradle module or package.
- Failure is **pre-existing** (existed before your change, unrelated code path): **flag explicitly, do not silently fix.**

## How to flag pre-existing failures

Tell the user:
- Which file(s) are failing.
- Why you believe it is pre-existing (e.g., "this class was not touched by this PR and the error is unrelated to the interface change").
- Recommended action (create a separate Jira ticket, fix in a separate PR).

## Why

Silent fixes conflate separate issues, inflate PR scope, and make rollback harder. Pre-existing bugs should be tracked independently.
