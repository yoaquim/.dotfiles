# Dependency Pinning (npm)

A committed lockfile with integrity hashes is the primary defense against supply-chain republish attacks. If a package is republished on the registry with different content (the TeamPCP / Miasma / Phantom Gyp playbook), the `integrity` (sha512) hash in the lockfile **fails the install before any code runs**. Mandatory for any project with a `package.json`.

## Rules

1. **Always commit the lockfile.** `package-lock.json`, `pnpm-lock.yaml`, or `yarn.lock` — never `.gitignore` it. No lockfile = no integrity hashes = no protection.
2. **Install with the locked, immutable command — never the mutable one:**
   - npm: `npm ci` (requires lockfile, installs it exactly, fails on any drift) — not `npm install`
   - pnpm: `pnpm install --frozen-lockfile`
   - yarn: `yarn install --immutable`
3. **`npm ci` already verifies integrity hashes and runs install scripts normally** — it breaks nothing and is the always-on protection. **Do NOT blanket-add `ignore-scripts=true`**: it disables the lifecycle/`node-gyp` builds that esbuild, prisma, sharp, swc, bcrypt, and most native deps depend on. Reserve `npm ci --ignore-scripts` for **auditing an untrusted install**, or as a default only in repos with zero native dependencies.
4. **New deps land exact:** `save-exact=true` in `.npmrc`, so `npm install <pkg>` writes `1.2.3`, not `^1.2.3`.
5. **lockfileVersion 2 or 3.** v1 lockfiles lack `integrity` on every node — the whole point. Confirm with `head package-lock.json` → `"lockfileVersion": 3`.
6. **Verify registry signatures:** `npm audit signatures` checks that installed packages were signed by the registry.
7. **Review the lockfile diff** when adding/updating a dep before committing — watch for changed `resolved` URLs or `integrity` hashes on packages you didn't touch. An unexplained integrity change on an untouched package is the attack signature.

## Adding or bumping a dependency

1. `npm install <pkg>@<exact-version>` (or bump in `package.json`, then `npm install`)
2. Inspect the lockfile diff — new entries, changed integrity hashes
3. `npm ci` from a clean checkout to confirm it resolves to the locked hashes
4. Commit `package.json` **and** the lockfile together

## Verify (show output before claiming done)

- `npm ci` succeeds and leaves the lockfile byte-identical (`git diff --exit-code package-lock.json`)
- Every package in the lockfile has `"integrity": "sha512-..."`
- if an `.npmrc` is present, it uses `save-exact=true` (and `ignore-scripts` only in repos with no native deps)

## On violation

- Ran `npm install` and the lockfile changed unexpectedly? Stop. Inspect the diff. Do not commit blindly.
- No lockfile in the repo? Generate one (`npm install`), review it fully, commit it — that's the first task, before any feature work.
