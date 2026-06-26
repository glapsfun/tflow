---
name: tflow-skill-creator
description: Use when a portable Agent Skill needs a disciplined factory pass from intent to distributable evidence
license: MIT
compatibility: Portable Agent Skill source for Claude Code, OpenAI Codex, and runtimes that support SKILL.md with POSIX sh scripts.
---

# tflow Skill Creator

Use this skill to turn an intent, research brief, or existing draft into a
portable Agent Skill. The canonical target is `tflow-skill-creator`; older
`skill-creator` names are historical context only.

Keep this entrypoint runtime-neutral. Detailed runtime path notes live in
[portability notes](references/portability-notes.md), not in this main file.

## Required Gates

The factory is script-owned. Do not reimplement these deterministic steps from
memory or prose.

1. Capture the skill intent, target name, inputs, outputs, runtime assumptions,
   and evidence the finished skill must provide.
2. Run `scripts/init.sh <skill-name> [target-root]` to scaffold the target skill.
3. Author or edit `SKILL.md`, `references/`, `scripts/`, and `assets/` as needed.
4. Run `scripts/validate.sh <skill-dir>` and fix every failure before continuing.
5. Run `scripts/improve.sh <skill-dir>` to write `.skill-improvement.md`.
6. Complete every checklist item in `.skill-improvement.md`.
7. Run `scripts/package.sh <skill-dir>` to create `dist/<skill-name>/` and
   `dist/<skill-name>.tar.gz`.

Use the full command sequence and failure handling in
[factory loop](references/factory-loop.md).

## Fail Closed

If a required script is missing, exits non-zero, or produces output that shows a
gate failed, stop the factory pass. Report the command, exit status, relevant
output, and the file or decision needed next. Do not package a skill after a
failed validation or unchecked `.skill-improvement.md` item.

## Authoring Rules

- Keep frontmatter to the portable Agent Skills fields: `name`, `description`,
  `license`, `compatibility`, and `metadata`.
- Use the documented single-line frontmatter subset in
  [portability notes](references/portability-notes.md); keep compatibility and
  metadata values as strings.
- Make `description` a trigger only. It must begin with `Use when` and must not
  summarize the workflow.
- Use plain relative Markdown links such as
  `[testing checklist](references/testing-checklist.md)`.
- Do not use path-prefix force-load syntax.
- Keep heavy guidance in directly linked reference files.
- Keep scripts POSIX `sh`, script-relative, and free of runtime install paths.
- Require every bundled `sh` script to pass `sh -n`; run `shellcheck` when it is
  available.
- Keep the source tree symlink-free.

## Evidence Requirements

A successful pass ends with:

- source under `skills/<skill-name>/` that passes `scripts/validate.sh`;
- completed `.skill-improvement.md` with no unchecked checklist entries;
- package artifacts under `dist/`;
- a concise summary of paths changed and commands run.

See [testing checklist](references/testing-checklist.md) for the evidence that
must be captured before packaging.
