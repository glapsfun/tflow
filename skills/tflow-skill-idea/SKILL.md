---
name: tflow-skill-idea
description: Use when a raw Agent Skill idea needs interactive shaping into a research-ready idea brief — surfacing the core purpose with Five Whys and a human-chosen direction before any research or authoring begins
license: MIT
compatibility: Portable Agent Skill source for Claude Code, OpenAI Codex, and runtimes that support SKILL.md; needs a human in the loop for the dialogue and no scripts or network access.
---

# tflow Skill Idea

Use this skill to turn a raw skill idea into a research-ready idea brief
through a short interactive dialogue. It is Phase 1 of the tflow factory
pipeline and equally usable on its own. It is a methodology: no scripts,
no network access, only structured conversation ending in one artifact.

The output contract lives in
[idea brief schema](references/idea-brief-schema.md). Emit nothing else.

## Invocation

- **raw prompt** (required): the human's idea in their own words. Capture it
  verbatim before the dialogue starts; it becomes the `raw_prompt` field.
- **context** (optional): links, prior notes, or an existing skill the idea
  relates to.

## Dialogue

Ask one question at a time. Never batch questions, and never answer your own
question on the human's behalf.

1. Restate the raw prompt in one sentence and confirm the reading.
2. Apply Five Whys to find the core purpose: ask why the skill should
   exist, and each answer feeds the next why. Stop early the moment the
   root reason is clear — do not mechanically complete the count — and
   ask at most five whys in total.
3. Propose two or three candidate directions. Give each a one-line tradeoff
   and mark exactly one as the recommendation with the reason.
4. Let the human pick a direction, ask for one more round of options, or
   reject them all. Allow at most one extra round of directions.
5. Confirm the research mode with the human: `base` for a quick pass over the
   obvious sources, `deep` for a wide pass across competing approaches.
6. Draft `success_criteria` (observable outcomes) and `research_questions`
   (what research must answer) from the dialogue, read them back, and adjust
   until the human agrees.
7. Emit the idea brief exactly per the schema, then stop.

## Fail Closed

If the human abandons the dialogue, rejects every direction after the extra
round, or the core purpose is still unclear after five whys, stop and report
what is missing and what was learned so far. Do not emit an idea brief, and
never fill a field on the human's behalf. A partial brief is worse than no
brief: downstream phases treat every field as load-bearing.
