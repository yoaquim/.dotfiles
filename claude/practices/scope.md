# Scope

Write the minimum code that satisfies the task, and touch only what the task requires. Two failure modes to kill: over-building and gold-plating.

## Minimum code

- No features beyond what was asked.
- No abstractions for single-use code. No "flexibility" or "configurability" nobody requested.
- No error handling for impossible scenarios.
- If you wrote 200 lines and it could be 50, rewrite it.

The test: would a senior engineer call this overcomplicated? If yes, simplify.

## Surgical changes

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style, even if you'd do it differently.
- Pre-existing dead code: note it in the status file — don't delete it.

When your change orphans something:

- Remove imports/variables/functions that YOUR change made unused.
- Leave pre-existing orphans alone unless removing them is the task.

The test: every changed line traces directly to the task.

## On ambiguity

You can't ask — you're autonomous. Make the smallest reasonable choice that satisfies the task and record it in the status file Notes. Don't hedge by building both interpretations.

## Why

Autonomous runners drift toward more: speculative abstraction, defensive handling for cases that can't occur, and "while I'm here" cleanup of code the task never named. Each one inflates the diff, widens the blast radius, and makes review harder. Smaller diff, traceable to the task, every time.
