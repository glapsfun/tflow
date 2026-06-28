# Versioning policy

tflow follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html). This
document defines what the version number promises — what counts as a breaking change,
what is additive, and what is a fix — so that a maintainer can pick the right bump and a
user can read a version jump correctly.

## The public API

For tflow, the **public API is the skill + CLI contract**. That means three things:

1. **The shipped skills** — `tflow-research`, `tflow-skill-creator`, `tflow-skill-factory`
   (their names, and the scripts/SKILL.md surface a user invokes).
2. **The installer CLI** — the `tflow init` subcommand and its flags
   (`--claude`, `--codex`, `--global`, `--dry-run`, `--force`, `--uninstall`), the
   install-directory layout it writes into (`<runtime>/skills/`, the `.tflow/` manifest).
3. **The `validate.sh` rule-set behavior** — the gate is the kit's core value, so the
   *behavior* of the validator is part of the contract. A change to a rule that flips a
   previously-passing skill to fail is a breaking change (see MAJOR below).

### What is NOT the public API

These may change at any time without a MAJOR bump:

- **Planning internals** (`.planning/` and the GSD workflow files) — local tooling, never
  shipped.
- **Internal script structure** — how a script is organized internally, helper functions,
  variable names, refactors that preserve observable behavior.
- **Test fixtures** (`scripts/fixtures/`) — they ship for `run-tests.sh` but are not part of
  the user-facing surface; adding/removing/adjusting a fixture is not a contract change.

The boundary line is *observable behavior of the skill + CLI + validator*, not the code
behind it.

## MAJOR / MINOR / PATCH

| Bump | Meaning | Examples |
|------|---------|----------|
| **MAJOR** | A breaking change to the public API | Remove or **rename a skill**; remove or **rename a CLI flag** or subcommand; **change the install-dir layout**; **tighten a `validate.sh` frontmatter rule** so a previously-passing skill now fails. |
| **MINOR** | Additive — backward compatible | Add a new skill; add a new CLI flag; **relax** a `validate.sh` rule (a skill that passed still passes). |
| **PATCH** | A doc or script bug fix with no contract change | Fix a typo in a message; fix a script bug that produced wrong output; documentation corrections. |

The canonical illustrations are the three from the roadmap: a **skill rename** (MAJOR), a
**script-flag removal** (MAJOR), and a **`validate.sh` frontmatter-rule change** — tightening
is MAJOR, relaxing is MINOR.

## The 0.x convention (pre-1.0)

tflow is currently in the `0.x` series. Per semver.org §4, *"Major version zero (0.y.z) is
for initial development. Anything MAY change at any time. The public API SHOULD NOT be
considered stable."*

While pre-1.0, tflow uses the standard 0.x mapping:

- **Breaking change** → bump the **MINOR** digit: `0.1.x` → `0.2.0`.
- **Feature or fix** → bump the **PATCH** digit: `0.1.0` → `0.1.1`.

In other words, during `0.x` the MINOR slot plays the role MAJOR plays after 1.0, and the
PATCH slot absorbs both features and fixes. This is the honest "pre-1.0 maturity signal":
the contract is still settling.

## The 1.0.0 graduation criterion

tflow ships `1.0.0` when **the skill + CLI contract is declared stable** — that is, when the
maintainers commit that the shipped skills, the `tflow init` flag set and install layout, and
the `validate.sh` rule-set behavior will only change under the MAJOR/MINOR/PATCH rules above
(no more "anything MAY change"). Until that declaration, stay in `0.x` and treat every
breaking change as a MINOR bump.

## See also

- [Release runbook](releasing.md) — how to actually cut a release (which bump to choose,
  then `npm version` → `git push --follow-tags`).
- [CHANGELOG](../CHANGELOG.md) — the human-readable record of what changed in each version.
