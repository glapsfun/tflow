# tflow

A factory for authoring **Agent Skills** to the [agentskills.io](https://agentskills.io) open standard (spec v1).

## What this is

tflow produces portable Agent Skills — Markdown `SKILL.md` files paired with POSIX `sh`
scripts. There is no compiled application: the deliverables are the skills themselves and
the scripts that author and validate them. The keystone is `validate.sh`, the linter every
artifact is gated through (spec compliance, tflow conventions, and portability).

## The shipped skills

- **`tflow-research`** — bounded web research synthesized into a sourced decision brief
  across brainstorm, find-idea, and improve-idea modes.
- **`tflow-skill-creator`** — the disciplined factory loop that takes a skill from intent to
  distributable evidence: the `init` / `validate` / `improve` / `package` scripts plus the
  `run-tests.sh` self-test suite.
- **`tflow-skill-factory`** — a thin chaining orchestrator that runs `tflow-research` and then
  `tflow-skill-creator` end-to-end, turning a plain-text intent into a validated skill
  directory.

## Quick start

```sh
# Validate a single skill directory (exit 0 = pass, 1 = fail, 2 = usage error)
sh skills/tflow-skill-creator/scripts/validate.sh <skill-dir>
sh skills/tflow-skill-creator/scripts/validate.sh --quiet <skill-dir>   # suppress PASS lines

# Run the full self-test suite (runs validate.sh against every fixture)
sh skills/tflow-skill-creator/scripts/run-tests.sh

# Lint the scripts themselves — must be clean with --shell=sh
shellcheck --shell=sh skills/*/scripts/*.sh
```

## Repo layout

```
skills/<name>/
  SKILL.md      # frontmatter + body, must pass validate.sh
  scripts/      # POSIX sh scripts (validate, init, improve, package, run-tests)
  references/   # supporting reference material
  assets/       # templates and other static assets
```

Skills install portably under both `.claude/skills/` and `.codex/skills/` — the same
`SKILL.md` must validate in either location.

## Development

```sh
pip install pre-commit
pre-commit install
```

Contributions run through a three-check gate, enforced identically by the local
`pre-commit` hook and by GitHub Actions CI (`.github/workflows/ci.yml`) on every push to
`main` and every pull request:

1. **shellcheck** (`--shell=sh`) on the skill scripts.
2. The **skill self-test suite** (`run-tests.sh`).
3. **yamllint** on the project's YAML.

Skill scripts stay POSIX `sh` (`#!/bin/sh`, `set -eu`, no bashisms, no hardcoded runtime
paths). The `pre-commit` / CI tooling is a separate Python-based dev layer and does not relax
that rule. Any change to a `validate.sh` rule needs a matching `pass-*` / `fail-*` fixture so
the self-test suite keeps the gate honest.

## License

Released under the MIT License (© 2026 glapsfun). See [LICENSE](LICENSE).
