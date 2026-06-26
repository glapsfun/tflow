---
name: __SKILL_NAME__
description: Use when a focused agent capability belongs in a reusable portable skill
license: MIT
compatibility:
  agentskills: ">=1.0"
metadata:
  tflow_scaffold: true
---

# __SKILL_NAME__

Use this starter as a small, portable skill source. Keep the main file focused on
when the skill applies, the process the agent should follow, and which support
files to read on demand.

## Trigger

Use this skill when the current task needs a repeatable capability that should
work in more than one agent runtime.

## Process

1. Confirm the user intent and the expected output.
2. Read only the supporting files that are relevant to the task.
3. Perform deterministic checks with scripts where they exist.
4. Report the result with the files changed, commands run, and remaining risks.

## Progressive Disclosure

Keep long examples, policies, and domain references in `references/`. Keep binary
or reusable source material in `assets/`. Keep deterministic helpers in
`scripts/`.

## Validation Notes

Before packaging or installing, validate this skill directory with:

```sh
sh scripts/validate.sh .
```
