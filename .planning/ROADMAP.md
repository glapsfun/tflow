# Roadmap: tflow (Milestone 1 — Foundation)

## Overview

Milestone 1 builds the two foundational primitives of the tflow agentic dev flow — `validate.sh` as the keystone gate, the `skill-creator` scripts and SKILL.md as the factory, the `deep-research` SKILL.md as the methodology — plus a thin chaining agent that chains them end-to-end. The build order is dependency-driven: the gate must exist before anything is validated through it, the scripts before the SKILL.md that references them, both skills before the orchestrator that chains them.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: The Keystone Gate** - Build and self-test `validate.sh` — the foundation of trust every other artifact depends on (completed 2026-06-24)
- [ ] **Phase 2: Skills Authored** - Build the remaining `skill-creator` scripts, `deep-research` SKILL.md, and finalize `skill-creator` SKILL.md
- [ ] **Phase 3: Integration Proof** - Build the thin chaining orchestrator and run it end-to-end to produce a skill that passes `validate.sh` clean

## Phase Details

### Phase 1: The Keystone Gate

**Goal**: `validate.sh` exists, enforces all frontmatter and structural rules, self-tests all failure cases with non-zero exit, and is shellcheck-clean
**Depends on**: Nothing (first phase)
**Requirements**: CREATE-01, CREATE-02, CREATE-03, CREATE-04, CREATE-09, CREATE-10, PORT-03
**Success Criteria** (what must be TRUE):

  1. Running `sh scripts/validate.sh` against a skill with an invalid `name` (too long, wrong chars, mismatched dir name) exits non-zero with a clear error message
  2. Running `sh scripts/validate.sh` against a skill whose `description` does not start with "Use when" or contains workflow verbs exits non-zero with a clear error message
  3. Running `sh scripts/validate.sh` against a skill with `@`-force-load syntax in the body exits non-zero
  4. Running `sh scripts/validate.sh` against a well-formed skill exits 0 with a PASS message
  5. `shellcheck --shell=sh scripts/validate.sh` exits 0 (no warnings); the script accepts a target-directory argument and contains no hardcoded runtime paths

**Plans**: 1/1 plans complete

Plans:

- [x] 01-01-PLAN.md — Write validate.sh (POSIX sh linter, all rule sets, --quiet flag) and self-test suite (run-tests.sh + 9 fixtures)

### Phase 2: Skills Authored

**Goal**: The remaining three `skill-creator` scripts (`init`, `package`, `improve`) are shellcheck-clean and agent-runnable; `deep-research` SKILL.md documents the full methodology; `skill-creator` SKILL.md documents the factory loop — all authored to the Agent Skills open standard with portable frontmatter only and no `@`-force-load syntax
**Depends on**: Phase 1
**Requirements**: CREATE-05, CREATE-06, CREATE-07, CREATE-08, RSCH-01, RSCH-02, RSCH-03, RSCH-04, RSCH-05, RSCH-06, PORT-01, PORT-02
**Success Criteria** (what must be TRUE):

  1. Running `sh scripts/init.sh <name>` produces a `skills/<name>/` directory that passes `validate.sh` clean out of the box
  2. Running `sh scripts/package.sh <skill-dir>` is gated on `validate.sh` passing and exits non-zero if validation fails
  3. Running `sh scripts/improve.sh <skill-md>` emits a diff-vs-baseline and a mandatory testing checklist; it does not allow `package` to proceed without the checklist being addressed
  4. An agent following `deep-research` SKILL.md can run a research task with a topic, optional seed links, and a depth/breadth budget, and receives a structured markdown brief (idea, options, evidence, recommendation, open questions, sources) plus optional JSON output
  5. The frontmatter of both `deep-research` and `skill-creator` SKILL.md files contains only spec-defined fields (`name`, `description`, `license`, `compatibility`, `metadata`) and passes `validate.sh` clean in both `.claude/skills/` and `.codex/skills/` install locations

**Plans**: 3 plans
Plans:

- [ ] 02-01-PLAN.md — Migrate the script spine to `tflow-skill-creator` and implement `init.sh`, `improve.sh`, and `package.sh`
- [ ] 02-02-PLAN.md — Author the `tflow-skill-creator` SKILL.md and factory-loop references
- [ ] 02-03-PLAN.md — Author the `tflow-research` SKILL.md, research references, and portability checks

**UI hint**: no

### Phase 3: Integration Proof

**Goal**: A thin chaining orchestrator agent runs unattended from a plain-text intent, chains `deep-research` → `skill-creator`, and produces a new skill directory that passes `validate.sh` clean — proving the factory can build itself
**Depends on**: Phase 2
**Requirements**: AGENT-01, AGENT-02, AGENT-03
**Success Criteria** (what must be TRUE):

  1. The orchestrator agent file contains only sequencing instructions — no research logic, no SKILL.md authoring rules embedded in it
  2. Given a plain-text intent, the orchestrator runs unattended: invokes `deep-research`, passes the markdown brief via `<research_brief>` tag to `skill-creator`, and `skill-creator` produces a skill directory
  3. The skill directory produced by the orchestrator run passes `sh scripts/validate.sh` clean (exit 0) without human intervention

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. The Keystone Gate | 1/1 | Complete    | 2026-06-24 |
| 2. Skills Authored | 0/TBD | Not started | - |
| 3. Integration Proof | 0/TBD | Not started | - |
