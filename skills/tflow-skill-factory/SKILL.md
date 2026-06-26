---
name: tflow-skill-factory
description: Use when a plain-text skill intent should travel the full factory chain from a research brief to a validated skill directory
license: MIT
compatibility: Portable Agent Skill source for Claude Code, OpenAI Codex, and runtimes that support SKILL.md with POSIX sh scripts.
---

# tflow Skill Factory

This skill is a thin orchestrator. It chains [tflow-research](../tflow-research/SKILL.md)
into [tflow-skill-creator](../tflow-skill-creator/SKILL.md) so a plain-text intent
becomes a validated skill directory. It owns sequencing only — it holds no research
or authoring logic of its own. The chained skills do all of the real work.

## Sequence

1. Apply the `tflow-research` skill to the provided plain-text intent as its
   `topic`, in `find-idea` mode using that mode's defaults (depth 2, breadth 4,
   medium token budget). Capture the markdown decision brief it produces.
2. Forward that brief UNCHANGED to the `tflow-skill-creator` skill, wrapped exactly
   inside a `<research_brief>` ... `</research_brief>` envelope — verbatim
   pass-through with no transform, summary, or re-decision. Hand the creator a
   throwaway scratch directory as its `target-root` so the proof skill is written
   outside `skills/` (the gitignored `/.proof/` root is the intended scratch path).
3. Let `tflow-skill-creator` run its own factory loop: it derives the kebab-case
   skill name from the brief and drives `init.sh` → author → `validate.sh`. Do not
   author or research here, and do not duplicate either skill's logic.
4. If `validate.sh` exits non-zero, return to the creator's authoring step and retry
   the author → validate cycle at most 2 times. If it still fails after the second
   retry, HALT and report the command, the exit status, the relevant output, and the
   decision needed next. This loop control is sequencing only — never re-author here.
5. Once `validate.sh` exits 0, have the creator run `improve.sh` to write
   `.skill-improvement.md`, then STOP. Do not run `package.sh` — its human-checklist
   gate blocks honest unattended packaging.

## Boundaries

The orchestrator owns only sequencing, mode selection, brief pass-through, and
retry/halt control — never research or authoring, which belong to the chained skills.

## Fail Closed

If a chained skill is missing, exits non-zero, or shows that a gate failed, stop the
chain. Report the command, exit status, relevant output, and the decision needed next.
Do not continue past a failed `validate.sh` once the bounded retry is exhausted.
