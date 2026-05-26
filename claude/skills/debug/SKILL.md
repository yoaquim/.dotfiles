---
name: debug
description: Systematic root-cause debugging. Use when a bug needs more than a one-line fix — anything failing repeatedly, anything where the cause isn't obvious from the error.
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---

# Debug

**Iron law: no fix without root cause.** A change that makes the symptom go away is not a fix unless you can name why it worked.

## Phase 1: Investigate

- Reproduce. Smallest input that triggers the failure.
- Read the failing path top-to-bottom. Don't jump to the suspected hot spot.
- Trace backward up the call chain from where the symptom appears to where the bad value originates. The bug is at the source, not the symptom.
- Capture actual values at each frame, not expected ones.

Done when you can state: **"the bug is at `<file:line>` because `<cause>`."** If you can't, stay in Phase 1.

## Phase 2: Pattern

Before fixing:

- **Same bug elsewhere?** Grep for the pattern (other call sites missing the same check).
- **Same class of bug?** (off-by-one, missing await, stale closure, unchecked null). Where else does the class apply in the diff or module?
- **When did it appear?** `git log -S` / `git blame` on the buggy line. Recent regression vs latent forever changes the fix.

Patterns mean the fix is bigger than one site — or the test surface is.

## Phase 3: Hypothesize + test

- **One variable at a time.** No "while I'm here" changes mixed into the fix commit.
- **Write a failing test that exercises the root cause, not the symptom.** If you can't write that test, the cause isn't identified — return to Phase 1.
- **After 3 failed fixes: stop fixing, question the architecture.** The bug is probably a category error (wrong abstraction, wrong invariant), not a typo.

## Phase 4: Fix

- Failing test → minimal fix → test green.
- **Defense in depth:** also validate at the layer that makes this class of bug structurally impossible (input boundary, type, invariant). Local fix is necessary; structural fix is sufficient.
- Verify the original repro is green. Run the full test suite — fixes that pass the new test but break others aren't fixes.

## Red flags — return to Phase 1

- "Let me try changing X and see if it works."
- Multi-change diff to fix one bug.
- Fix passes tests but you can't explain *why* the original bug happened.
- Symptom moves to a new location after the fix.
- You're tweaking timeouts, retries, or sleeps to make a flaky test pass.
