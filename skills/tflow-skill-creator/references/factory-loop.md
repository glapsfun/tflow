# Factory Loop

This reference expands the `tflow-skill-creator` factory loop. The scripts are
mandatory gates; use their exit codes and output as the source of truth.

## 1. Capture Intent

Before touching files, capture:

- target skill name in kebab-case;
- purpose and trigger condition;
- expected inputs and outputs;
- supporting files needed under `references/`, `scripts/`, or `assets/`;
- evidence required before packaging;
- portability constraints for Claude Code, Codex GSD, and official Codex skill
  layouts.

If the user provided a research brief, preserve the brief as source context and
convert only the stable decisions into the skill.

## 2. Scaffold

Run the scaffold gate from the canonical source tree:

```sh
sh skills/tflow-skill-creator/scripts/init.sh <skill-name> [target-root]
```

`scripts/init.sh` creates `skills/<skill-name>/SKILL.md`, `scripts/`,
`references/`, and `assets/`, then runs `scripts/validate.sh` against the
generated skill. It refuses invalid names and existing target directories.

If this command exits non-zero, stop and report the command output. Do not create
the target structure by hand unless the script itself is missing and that missing
script has been reported as the blocker.

## 3. Author Or Edit

Edit the scaffold into the real skill:

- keep `SKILL.md` concise and trigger-focused;
- move deep guidance into directly linked files under `references/`;
- add deterministic helper scripts only when the skill needs repeatable local
  actions;
- add templates or examples under `assets/`;
- keep all cross references as plain relative Markdown links.

Do not write runtime install behavior into the skill source. Runtime placement is
covered in `portability-notes.md`.

## 4. Validate

Run validation after every material edit:

```sh
sh skills/tflow-skill-creator/scripts/validate.sh <skill-dir>
```

The validation gate checks the skill name, trigger description, body size,
path-prefix force-load syntax, and bundled shell scripts when `shellcheck` is
available.

If validation fails, fix the source and re-run the command. Do not continue to
the improvement or package gates until validation exits 0.

## 5. Improve

Run the evidence gate:

```sh
sh skills/tflow-skill-creator/scripts/improve.sh <skill-dir>
```

`scripts/improve.sh` writes `<skill-dir>/.skill-improvement.md` with validation
output, a scaffold comparison, starter-leftover checks, and a mandatory testing
checklist. It is a report writer, not an automatic source rewriter.

Complete the checklist by replacing every unchecked entry with checked evidence
after the corresponding test or review is actually done.

## 6. Package

Package only after validation passes and `.skill-improvement.md` has no
unchecked checklist items:

```sh
sh skills/tflow-skill-creator/scripts/package.sh <skill-dir>
```

`scripts/package.sh` validates first, checks the improvement evidence, stages the
source tree, then writes:

- `<skill-dir>/dist/<skill-name>/`
- `<skill-dir>/dist/<skill-name>.tar.gz`

The package command is distribution-only. It prints copy hints; it does not copy
into `.claude/`, `.codex/`, `.agents/`, home directories, or any other runtime
install location.

## Fail-Closed Rules

Stop immediately when:

- any required script is missing;
- any gate exits non-zero;
- validation output contains failures;
- `.skill-improvement.md` still has unchecked checklist entries;
- package artifacts are absent after `scripts/package.sh` claims success.

The final response should list the skill directory, validation command, evidence
file, package directory, package archive, and any unresolved blocker.
