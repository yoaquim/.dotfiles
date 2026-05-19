# Bug Checklist

The primary review pass. Apply every section to every changed file. If uncertain whether something is a bug, surface it as `**Confidence:** Low` — don't drop it.

## Correctness
- Off-by-one / fence-post (`<` vs `<=`).
- Wrong operator (`&&` vs `||`, `=` vs `==`).
- Inverted condition.
- Caller's state mutated unexpectedly.

## Null / undefined
- Properties accessed on values that can be null/undefined.
- Optional chaining masking a real bug.
- Empty array/string assumptions.

## Async / race
- Stale closures over mutable refs.
- Promise chains without `catch`.
- State writes after unmount/teardown.
- Concurrent reads of state being mutated.
- Missing AbortController / cancellation paths.
- Out-of-order message or response delivery.

## Error handling
- Silent `catch` that swallows real errors.
- Missing error paths in network/IO code.
- Errors thrown across realm/process boundaries (`vm`, workers, subprocesses) — `instanceof Error` lies.

## Security
- Injection (SQL, command, prompt, XSS, template).
- Secrets logged or returned in error responses.
- Auth checks missing or bypassed.
- Path traversal.
- Deserialization of untrusted input.
- Prototype pollution.

## Resources / lifecycle
- Event listeners, timers, file handles, subscriptions not cleaned up.
- Cleanup missing on unmount/teardown.
- Unbounded growth (caches, logs, arrays).

## Tests
- Asserts the wrong thing (passes regardless of bug).
- Mocks that hide the bug being claimed fixed.
- Snapshots without semantic checks.
- Coverage gap on the failure path being patched.
