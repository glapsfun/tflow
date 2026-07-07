# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2026-07-07

### Added

- `tflow-skill-idea`: interactive idea shaping into an eight-field idea brief
  (Five Whys, direction choice, fail-closed on abandonment).
- `tflow-skill-test`: TDD for skills — `define` mode writes the test plan before
  authoring; `run` mode executes the three-layer pass via `run-layer2.sh`.
- `tflow-prompt`: prompt enhancement — rewrites a raw or first-draft prompt with
  earned prompt-engineering techniques and returns it with an auditable change
  log (script-free, portable across Claude Code and Codex).
- `tflow-gateway`: the family front door — sharpens a raw request with
  `tflow-prompt`, discovers installed tflow skills, routes to the best fit,
  and accepts the result against acceptance checks fixed before delegation,
  with a bounded re-delegation loop (max 2 rounds).

### Changed

- **Breaking:** `tflow-skill-factory` rewritten as an eight-step loop controller
  (idea → research → validate → test-plan → create → test-run → check → doc)
  with bounded re-research (2) and improvement (3) loops, artifact gates, and
  internal validate/check/doc phase references. It now requires all four
  sibling skills.

## [0.1.1] - 2026-06-29

### Fixed

- The post-install `validate.sh` self-check no longer reports
  `FAIL tflow-skill-creator` on machines with shellcheck installed. `validate.sh`
  Rule D runs whatever shellcheck is on PATH, and different shellcheck versions
  number the same false positives differently — a trap-invoked `cleanup()` is
  `SC2317` ("unreachable") in 0.9.0 but `SC2329` ("never invoked") in 0.10+. Rule
  D now excludes the full set spanning those versions: `SC2317`/`SC2329` (trap
  cleanup), `SC2016` (literal-backtick `printf`), `SC2115` (guarded `rm -rf`),
  and `SC2015` (the `emit` helper's benign `A && B || true`), so the shipped
  skills validate clean from 0.9.0 (CI runners) through 0.11.0 (dev). Added a
  regression test that validates every shipped skill and prints the shellcheck
  version and findings on failure.

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
