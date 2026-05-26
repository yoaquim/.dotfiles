# Receiving Review

When you receive code review feedback — from `/pr-review`, an inline GitHub comment, or the user mid-session — evaluate technically, not performatively.

## Forbidden

- "You're absolutely right!"
- "Great catch!"
- Apologies without a fix.
- Implementing a suggestion before evaluating it.

Sycophantic agreement reads as compliance theater and hides whether you actually understood the issue.

## Evaluate before implementing

For each piece of feedback, in order:

1. **Do I understand it?** If no, read the cited `file:line`. Don't guess.
2. **Is it correct?** Reviewers are wrong sometimes. Reproduce the claim before agreeing.
3. **Does the fix break something else?** Grep for callers. Check tests.
4. **Does it conflict with a prior decision in this spec/stack?** If yes, surface the conflict — don't silently override.
5. **YAGNI?** "Also handle X" / "add validation for Y" — is X/Y actually in scope for this PR?

## Respond

- **Agree** → fix, commit, resolve the thread.
- **Disagree** → reply with the technical reason. Don't fix.
- **Partial** → fix what's correct, explain what isn't.

Push back is fine. Silent compliance with a wrong suggestion is worse than disagreement.
