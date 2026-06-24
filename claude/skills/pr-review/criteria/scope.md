# Criterion: `scope`

## What it says

Code can be in-spec and still over-built. Independent of any spec, flag a diff that solves the stated problem with more code, more abstraction, or more defensiveness than the problem requires. Two shapes: **over-building** (volume the task didn't need) and **gold-plating** ("while I was here" changes the task never named).

This is the spec-independent counterpart to `spec-compliance`. `spec-compliance` catches *behavior* the spec didn't ask for, and drops itself when no spec resolves. This criterion catches *complexity* inside in-scope behavior, and applies whether or not a spec exists.

## Why

Autonomous runners drift toward more: speculative abstraction, error handling for cases that can't occur, single-use indirection, and reflexive cleanup of code the task never touched. Each inflates the diff, widens the blast radius, and makes the next reviewer (human or agent) read more to find less. A smaller diff where every line traces to the task is cheaper to review and cheaper to be wrong about.

## How to spot

- An abstraction (interface, factory, config option, generic param) with exactly one caller and no second one in sight.
- Error handling, retries, or validation for inputs the call site can't produce.
- A helper/module that could be inlined at its single use without losing clarity.
- Diff hunks in files the task never named — reformatting, renames, "improved" comments, refactors of untouched code.
- Removal of pre-existing dead code the change didn't orphan (only orphans the change itself created are in scope).
- A function that ran 50 lines in an obvious form and 200 in the delivered one.

The test for each hunk: does this line trace directly to the task? If not, it's a finding.

## When NOT to apply

- The abstraction is requested by the spec, or a second caller lands in the same diff.
- The "extra" handling guards a genuinely reachable input (untrusted boundary, parsed external data, public API surface).
- The PR is an explicit refactor/cleanup task — then the "unrelated" changes ARE the task.
- A reformat is the byproduct of an autoformatter the repo already enforces.

## Severity guidance

- **Concern** when the over-build is the bulk of the diff, or the gold-plating touches code paths unrelated to the task (review/merge risk on lines nobody asked to change).
- **Nit** for a single speculative abstraction or a small "while I was here" tidy that's harmless but untraceable.
- Never **Blocker** on its own — over-built code that works isn't broken. Combine with a `bug-checklist` finding if the extra surface also introduces a defect.
