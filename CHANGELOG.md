# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-06-29

### Fixed

- The post-install `validate.sh` self-check no longer reports
  `FAIL tflow-skill-creator` on machines with shellcheck installed. The shipped
  `validate.sh` ran shellcheck with no excludes — stricter than the project's
  own gate — so `improve.sh`/`package.sh` tripped three codes the project
  excludes everywhere else (SC2329 on a trap-invoked `cleanup()`, SC2016 on a
  literal-backtick `printf`, SC2115 on a guarded `rm -rf`). Rule D now applies
  the same `--exclude=SC2115,SC2016,SC2329` policy as `.pre-commit-config.yaml`,
  keeping the gate consistent with CI. Added a regression test asserting every
  shipped skill validates clean.

## [0.1.0] - 2026-06-28

### Added

- Three portable Agent Skills — `tflow-research`, `tflow-skill-creator`, and
  `tflow-skill-factory` — installable into both Claude and Codex runtimes.
- `validate.sh` factory gate enforcing the agentskills.io spec plus tflow's
  authoring conventions, with a fixture-driven self-test suite.
- `npx @glapsfun/tflow init` installer: `--claude` / `--codex` runtime targets,
  local vs `--global` scope, `--dry-run` preview, `--force` overwrite, and
  `--uninstall` removal, backed by a sha256 install-manifest that never clobbers
  files you have modified.
- Post-install `validate.sh` self-check reporting per-skill PASS / FAIL (advisory).
- Tag-triggered npm release pipeline (`v*` push → publish + GitHub Release).
