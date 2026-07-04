# Idea Brief Schema

This reference is the authoritative output contract for `tflow-skill-idea`.
The dialogue in [SKILL.md](../SKILL.md) produces one markdown artifact,
`idea-brief.md`, in exactly this shape.

## Field contract

The brief has these eight fields, in this order. The field names are the
markdown headings.

| Field | Type | Required | Meaning | Empty value |
|-------|------|----------|---------|-------------|
| `raw_prompt` | text | yes | The human's original idea, captured verbatim. | never empty |
| `core_purpose` | text | yes | The root reason the skill should exist, from Five Whys. | never empty |
| `chosen_direction` | text | yes | The direction the human approved. | never empty |
| `rejected_directions` | list | yes | Alternatives considered, each with why not. | empty list allowed |
| `target_users` | text | yes | Who invokes the resulting skill and when. | never empty |
| `success_criteria` | list | yes | Observable outcomes the finished skill must satisfy; these feed the factory's check phase (the arbiter judges the built skill against them). | never empty |
| `research_questions` | list | yes | What research must answer; these feed the factory's validate phase (each must be answered with sourced evidence). | never empty |
| `research_mode` | text | yes | `base` or `deep`; the factory maps this to tflow-research depth/breadth/token-budget presets. | never empty |

A dialogue that cannot fill every required field must fail closed instead of
emitting a brief. `rejected_directions` may be an empty list when the human
accepted the first proposal, but the heading is never omitted.

## Markdown brief

Use these headings, in this order.

```text
# Idea Brief

## raw_prompt
<the human's idea, verbatim>

## core_purpose
<the root reason, one or two sentences>

## chosen_direction
<the approved direction, one or two sentences>

## rejected_directions
- <direction> — <why not>

## target_users
<who invokes the skill and when>

## success_criteria
- <observable outcome>

## research_questions
- <question research must answer>

## research_mode
<base | deep>
```

When `rejected_directions` has no entries, keep the heading and write
`- none`.
