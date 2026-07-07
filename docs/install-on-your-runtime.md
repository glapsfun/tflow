# Install tflow on your runtime

tflow installs its skills into your agent runtime's skill directory with a single command.
This guide walks every shipped flag with a runnable command and a sample of the real CLI
output, then covers the install manifest, the post-install self-check, and troubleshooting.

The authoritative usage line (from `tflow` itself) is:

```
Usage: tflow init [--claude] [--codex] [--global] [--dry-run] [--force] [--uninstall]
```

`init` is the only subcommand. Every flag is optional and boolean. By default the install is
**local** (into the current project) and targets whichever runtime dirs already exist.

## Where files go

- Skills install into `<runtime>/skills/` — e.g. `.claude/skills/` or `.codex/skills/`.
- A sha256 install manifest is written to `<runtime>/.tflow/install-manifest.json` — e.g.
  `.claude/.tflow/install-manifest.json`. The manifest records the hash of every file tflow
  wrote, which is how a later run distinguishes a **pristine** file (safe to refresh or
  remove) from one **you modified** (skipped on install, preserved on uninstall). tflow never
  clobbers a file you changed.
- Local scope writes under the current directory; `--global` writes under your home directory.

## Installing

### Auto-detect (bare `init`)

With no runtime flag, tflow installs into whichever of `.claude` / `.codex` already exist
under the target directory. It never creates a runtime dir that isn't there.

```sh
npx @glapsfun/tflow init
```

```
[claude] install → /your/project/.claude
  create skills/tflow-gateway/SKILL.md
  create skills/tflow-gateway/scripts/discover-skills.sh
  create skills/tflow-prompt/SKILL.md
  create skills/tflow-research/SKILL.md
  create skills/tflow-skill-creator/SKILL.md
  create skills/tflow-skill-creator/scripts/validate.sh
  create skills/tflow-skill-factory/SKILL.md
  create skills/tflow-skill-idea/SKILL.md
  create skills/tflow-skill-test/SKILL.md
  … (one line per installed file)
  → 44 created, 0 overwritten, 0 skipped
[claude] validate.sh self-check:
  PASS tflow-gateway
  PASS tflow-prompt
  PASS tflow-research
  PASS tflow-skill-creator
  PASS tflow-skill-factory
  PASS tflow-skill-idea
  PASS tflow-skill-test
```

### Target a specific runtime — `--claude` / `--codex`

Passing `--claude` and/or `--codex` selects the runtime explicitly (this wins over
auto-detect, and works even when the dir doesn't exist yet — tflow creates the skills tree
under it):

```sh
npx @glapsfun/tflow init --claude
npx @glapsfun/tflow init --codex
npx @glapsfun/tflow init --claude --codex
```

A second run over an unchanged install refreshes the pristine files in place:

```
[codex] install → /your/project/.codex
  overwrite skills/tflow-research/SKILL.md
  overwrite skills/tflow-skill-creator/SKILL.md
  → 0 created, 2 overwritten, 0 skipped
```

### Global install — `--global`

`--global` targets the runtime dirs under your home directory instead of the current project:

```sh
npx @glapsfun/tflow init --global --claude
```

```
[claude] install → /Users/you/.claude
  create skills/tflow-research/SKILL.md
  → 1 created, 0 overwritten, 0 skipped
```

### Preview without writing — `--dry-run`

`--dry-run` prints the exact install plan but writes nothing (no files, no manifest). The
install header carries a literal `dry-run ` marker so you can tell a preview from a real run:

```sh
npx @glapsfun/tflow init --dry-run --claude
```

```
[claude] dry-run install → /your/project/.claude
  create skills/tflow-research/SKILL.md
  skip(modified) skills/tflow-skill-creator/SKILL.md
  → 1 created, 0 overwritten, 1 skipped
```

Here `skip(modified)` means tflow detected that you edited that file since it was installed,
so it would leave your version untouched.

### Force-overwrite your edits — `--force`

By default a file you modified is skipped. `--force` overwrites it with the shipped version:

```sh
npx @glapsfun/tflow init --force --claude
```

```
[claude] install → /your/project/.claude
  overwrite skills/tflow-skill-creator/SKILL.md
  → 0 created, 1 overwritten, 0 skipped
```

## The post-install self-check

After a real (non-preview) install, tflow runs the installed `validate.sh` against each
installed skill and reports a per-skill result:

```
[claude] validate.sh self-check:
  PASS tflow-gateway
  PASS tflow-prompt
  PASS tflow-research
  PASS tflow-skill-creator
  PASS tflow-skill-factory
  PASS tflow-skill-idea
  PASS tflow-skill-test
```

A `FAIL` here is **advisory** — it is reported but the install still exits `0`. If POSIX `sh`
isn't available the self-check is skipped (see troubleshooting), and the install still
succeeds.

## Removing tflow — `init --uninstall`

Removal is a flag on the `init` subcommand, **not** a separate subcommand. `init --uninstall`
removes only the files tflow installed and left pristine; files you modified are preserved,
and anything already gone is reported as missing:

```sh
npx @glapsfun/tflow init --uninstall --claude
```

```
[claude] uninstall → /your/project/.claude
  removed skills/tflow-research/SKILL.md
  preserved(modified) skills/tflow-skill-creator/SKILL.md
  missing skills/tflow-skill-factory/SKILL.md
  → 1 removed, 1 preserved, 1 missing
```

> **Caution:** `--dry-run does not apply to --uninstall`. The `--dry-run` flag previews
> *installs* only — it does not turn an uninstall into a dry run. tflow dispatches to the
> removal path whenever `--uninstall` is present, **regardless of `--dry-run`**, so
> `init --uninstall --dry-run` still deletes pristine files. If you only want to preview a
> removal, there is no preview mode — omit `--uninstall`.

## Troubleshooting

**No runtime detected.** If you run a bare `init` in a directory with no `.claude` or `.codex`
dir to auto-detect, tflow prints (and exits with code `1`):

```
tflow: no runtime detected — pass --claude and/or --codex (no .claude/.codex to auto-detect)
```

Fix it by passing the runtime explicitly, e.g. `npx @glapsfun/tflow init --claude`.

**POSIX sh unavailable.** If `sh` isn't on the system, the post-install self-check is skipped
with a warning — the install itself still completes and exits `0`:

```
WARN: POSIX sh unavailable — skipping validate.sh self-check.
```

### Exit codes

- `0` — Success (a self-check `FAIL` is advisory and still exits `0`).
- `1` — No runtime detected.
- `2` — Usage error (missing/unknown subcommand or unknown flag).

## Supported runtimes

tflow currently installs into the `.claude` and `.codex` runtime targets. Additional runtimes
are a future-milestone item and are not yet supported.

## Pinning a version

`npx` runs the latest published version by default. To pin an exact release, suffix the
package with its version:

```sh
npx @glapsfun/tflow@0.1.0 init --claude
```

## See also

- [Versioning policy](versioning.md) and [release runbook](releasing.md) — for maintainers.
- [CHANGELOG](../CHANGELOG.md) — what changed in each release.
