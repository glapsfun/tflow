# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
