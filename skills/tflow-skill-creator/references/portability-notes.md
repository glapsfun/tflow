# Portability Notes

The canonical source for authored skills is `skills/<name>/`. Runtime-specific
directories are install targets or validation shapes, not the source of truth.

## Supported Runtime Shapes

Use the same skill source content in these directory shapes when checking
portability:

| Runtime | Project shape | Personal shape | Note |
| --- | --- | --- | --- |
| Claude Code | `.claude/skills/<name>/` | `~/.claude/skills/<name>/` | Claude Code project and personal skill locations. |
| Codex GSD convention | `.codex/skills/<name>/` | `~/.codex/skills/<name>/` | This repo's GSD harness uses this convention. |
| Official Codex | `.agents/skills/<name>/` | `~/.agents/skills/<name>/` | Official Codex skill path convention. |

The Phase 2 portability check copies `skills/tflow-skill-creator` into temporary
`.claude/skills/tflow-skill-creator` and `.codex/skills/tflow-skill-creator`
directory shapes, validates both copies, then removes the temporary root.

## Frontmatter

Keep portable skill frontmatter to fields understood by the Agent Skills open
standard:

```yaml
---
name: example-skill
description: Use when an observable trigger condition applies
license: MIT
compatibility: Portable across Claude Code and OpenAI Codex skill directories.
metadata:
  key: value
---
```

Avoid runtime-only controls in portable source, including `when_to_use`, model
selection, path auto-activation, hook config, and runtime-specific trigger
fields. If a future distribution layer needs those controls, keep that adapter
outside the canonical source.

## Links And References

Use plain relative Markdown links from `SKILL.md` to files one level below the
skill directory, for example:

```markdown
[factory loop](references/factory-loop.md)
```

Do not use path-prefix force-load syntax. The validation gate rejects that
syntax to keep source portable and avoid unnecessary context loading.

## Script Paths

Scripts must accept target paths as arguments or resolve siblings from their own
location. They must not hardcode `.claude/`, `.codex/`, `.agents/`, or home
directory install paths.

Agents invoking a source-tree script should use commands like:

```sh
sh skills/tflow-skill-creator/scripts/validate.sh skills/tflow-skill-creator
```

An installed copy may use paths relative to that installed skill directory, but
the script behavior remains the same.

## Package Boundary

`scripts/package.sh` is package-only. It may print install hints after it writes
`dist/<skill-name>/` and `dist/<skill-name>.tar.gz`, but it must not perform
runtime installation or mutate agent configuration.

This boundary keeps package generation deterministic and lets each runtime or
adapter own its own install mechanics.

## Adapter Caveats

- Treat `.codex/skills/` as a GSD convention for this repository, while
  `.agents/skills/` is the official Codex convention.
- Do not assume a runtime has `shellcheck`; `scripts/validate.sh` warns and
  continues when it is absent.
- Do not depend on symlink support for portable packages. A copied directory
  must contain the files needed by the skill.
- Keep generated archives and `dist/` out of package input to avoid recursive
  packages.
