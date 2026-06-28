# Release runbook

This is the maintainer step-list for cutting a tflow release. The version is single-sourced
from `package.json`; `npm version` bumps it, an `npm version` lifecycle hook auto-stamps the
CHANGELOG, and `git push --follow-tags` fires the release pipeline. For *which* bump to choose,
see the [versioning policy](versioning.md).

## How the automation fits together

tflow's `package.json` wires a `version` lifecycle script:

```json
"scripts": {
  "version": "sh scripts/stamp-changelog.sh && git add CHANGELOG.md"
}
```

When you run `npm version <bump>`, npm:

1. Checks the working tree is **clean** (aborts otherwise — see below).
2. Bumps `version` in `package.json`.
3. Runs the `version` script — `scripts/stamp-changelog.sh` rewrites the `## [Unreleased]`
   section into `## [x.y.z] - <date>`, re-seeds a fresh empty `## [Unreleased]` above it, and
   the `git add CHANGELOG.md` stages the rewritten changelog **into the same commit npm is
   about to create**.
4. Commits (`package.json` + `CHANGELOG.md` together) and creates the `v<x.y.z>` tag.

The helper reads the bumped version from `package.json` via
`node -p "require('./package.json').version"` — it never invents a version, so the tag, the
`package.json` version, and the stamped `## [x.y.z]` heading always agree (this is the same
read the release workflow uses for its drift guard).

## The ordinary release flow

```sh
# 1. Author your changes. As you work, fill the CHANGELOG.md `## [Unreleased]`
#    section at feature level (Added / Changed / Fixed).

# 2. Commit everything so the working tree is CLEAN.
#    `npm version` aborts on a dirty tree (see "Clean tree required" below).
git add -A && git commit -m "feat: <summary>"

# 3. Bump. The `version` hook stamps CHANGELOG.md, git-adds it, then npm
#    commits (package.json + CHANGELOG.md) and tags v<x.y.z>.
npm version patch     # 0.1.0 -> 0.1.1  (feature or fix, pre-1.0)
# npm version minor   # 0.1.x -> 0.2.0  (breaking change, pre-1.0)
# npm version major   # reserved for 1.0.0 graduation

# 4. Push the commit AND the tag. --follow-tags pushes the v<x.y.z> tag,
#    which fires .github/workflows/release.yml.
git push --follow-tags
```

`.github/workflows/release.yml` triggers on `v*` tags. Its precondition gate fails closed
unless the tag equals the `package.json` version **and** there is a non-empty `## [x.y.z]`
section in `CHANGELOG.md` — both guaranteed by the steps above. It then runs the CI gate,
asserts the npm pack contract, publishes to npm, and creates the GitHub Release.

## First release (v0.1.0)

The repository **already ships at `0.1.0`** (that is the version in `package.json` today). A
normal `npm version patch` would produce `0.1.1` and skip the required `## [0.1.0]` section —
but the design forbids hand-stamping `## [0.1.0]` (the helper owns that heading). For the
first release only, use the same-version bootstrap:

```sh
# First release ONLY — package.json is already 0.1.0.
npm version 0.1.0 --allow-same-version
git push --follow-tags
```

`npm version 0.1.0 --allow-same-version` still runs the `version` lifecycle hook (so
`scripts/stamp-changelog.sh` stamps `## [0.1.0] - <date>`), commits, and tags `v0.1.0` exactly
like a normal bump — it just doesn't change the version number. This `--allow-same-version`
form is needed **only for the first release**, because the repo was initialized at `0.1.0`.
Every **subsequent** release uses the ordinary `npm version <patch|minor|major>` flow above.

### Why there is no hand-written `## [0.1.0]` before release

The roadmap's SC#3 — *"the CHANGELOG's top section matches the current package version"* — is
satisfied by **automation, not by a hand-written heading**. The first
`npm version 0.1.0 --allow-same-version` produces the matching `## [0.1.0]` section at release
time. That is why the repo intentionally carries a populated `## [Unreleased]` section and
**no** hand-stamped `## [0.1.0]` heading before the release is cut. Leave it that way; the
stamp helper creates the dated heading when you run `npm version`.

## Clean tree required

`npm version` refuses to run if the working directory has uncommitted changes. Always commit
your `[Unreleased]` content and any other work **first** (step 2 above), then run
`npm version`. The helper's own `git add CHANGELOG.md` happens *inside* the hook, after npm's
clean-tree check, so it does not trip the check.

Do **not** bypass git hooks anywhere in this flow (no hook-skipping commit flag) — that would
defeat the pre-commit gate the release pipeline relies on.

## Notes

- The release scripts (`scripts/stamp-changelog.sh`, `scripts/assert-pack.sh`) are
  repo-maintainer tooling, run from the repo at release time. They are intentionally **not**
  shipped in the npm tarball (excluded by the `package.json` `files` allowlist) — harmless,
  because `npm version` is always run from the repo checkout, never from an installed or
  unpacked package.
- **Future step (not the current flow):** OIDC trusted publishing and `npm publish
  --provenance` are a planned follow-up. Until that is wired and registered out-of-band, the
  pipeline uses the token-based publish path. Do not add `--provenance` to this runbook yet.

## See also

- [Versioning policy](versioning.md) — choosing the right bump.
- [CHANGELOG](../CHANGELOG.md) — the record the stamp helper rewrites.
