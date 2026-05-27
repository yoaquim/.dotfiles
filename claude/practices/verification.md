# Verification

Before claiming a task is done, show the evidence. Don't assert success — prove it.

## The rule

When you say "done," "fixed," "working," or equivalent, the next thing in your output must be the command + output that proves it:

- Test suite: command run + final line showing 0 failures
- Type check / lint: command + exit 0
- Bug fix: the original repro command + the new (passing/correct) output
- Build: command + exit 0

No proof → no claim. "I made the change and it should work" is not a completion claim.

## What doesn't count

- "Tests should pass now" — run them
- Showing the diff instead of the test output — diff proves you wrote something, not that it works
- A partial test run (one test instead of the suite) when the change has wider blast radius
- Cached / stale output from earlier in the session — re-run after the change

## Why

LLMs default to confident-sounding completion claims. The user can't tell a real success from a hallucinated one without rerunning everything themselves. Pasting the proof transfers that work to the agent, where it belongs.
