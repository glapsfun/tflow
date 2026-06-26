---
name: tflow-research
description: Use when a decision needs bounded web research synthesized into a sourced brief across brainstorm, find-idea, and improve-idea modes
license: MIT
compatibility: Portable Agent Skill source for Claude Code, OpenAI Codex, and runtimes that support SKILL.md with the agent's own web/fetch tools.
---

# tflow Research

Use this skill to turn a topic into a bounded research pass that ends in a
sourced decision brief. The canonical target name for this research methodology
is `tflow-research`.

This skill is a methodology, not a search engine. It does not bundle a search
provider, API key, or crawler. It uses the agent's own web and fetch tools
(for example WebSearch and WebFetch, or the runtime's equivalents) to gather
evidence, and it tells the agent how to plan, follow links, read, and
synthesize within an explicit budget.

Keep this entrypoint focused. Detailed loop control, source confidence rules,
and the exact brief contract live in linked reference files:

- [research loop](references/research-loop.md) — phased, budgeted process.
- [source confidence](references/source-confidence.md) — hierarchy, freshness,
  confidence labels, and citation discipline.
- [brief schema](references/brief-schema.md) — exact markdown and JSON fields.

## Invocation

A research request requires one input and accepts five optional controls.

- **topic** (required): the question or prompt to research. Be specific about
  the decision the brief must support.
- **mode** (optional): one of `brainstorm`, `find-idea`, or `improve-idea`.
  Defaults to `brainstorm` when omitted.
- **seed links** (optional): starting URLs the agent should read first before
  searching more broadly.
- **depth** (optional): how many link hops to follow away from a source.
- **breadth** (optional): how many sources to consider per phase.
- **token_budget** (optional): a positive integer giving the approximate reading
  budget for the whole pass. The agent starts synthesis at 80% and stops reading
  at 100%.

`depth`, `breadth`, and `token_budget` are the cost controls. They satisfy the
budget requirement (RSCH-03, RSCH-04) and prevent the unbounded recursion
failure mode. See the [research loop](references/research-loop.md) for how the
agent applies the visited set, URL cap, and stopping rules.

## Preflight and Failure

Validate `mode`, `depth`, `breadth`, and `token_budget` before research begins.
Reject invalid or non-positive numeric controls.

Confirm that the runtime can open at least one external source through its web,
search, or fetch tools. If no source can be opened, report the missing
capability and stop. Do not emit a Research Brief, JSON brief, citations, or
confidence labels, and do not substitute model memory for opened evidence.

## Conservative Defaults

Defaults are deliberately small so a research pass never expands unboundedly by
accident. Callers must explicitly raise `depth`, `breadth`, or `token_budget`
for a larger run.

| Mode | Goal | Output emphasis | Default depth | Default breadth | Default token_budget |
|------|------|-----------------|---------------|-----------------|----------------------|
| `brainstorm` | Map the option space for an open topic | Many `options`, light `evidence`, sharp `open_questions` | 1 | 3 | 8,000 |
| `find-idea` | Pick a recommended approach from candidates | A clear `recommendation` backed by compared `options` | 2 | 4 | 16,000 |
| `improve-idea` | Strengthen one existing idea | Deep `evidence` and `risks` for the current direction | 2 | 3 | 16,000 |

Reject zero, negative, or non-numeric budgets before research begins. Larger
numbers are opt-in, never the default. See the
[research loop](references/research-loop.md) for accounting and escalation.

## Modes

- **brainstorm** — the topic is open and the goal is to widen the field. Favor
  surveying many candidate directions over deeply vetting one. The brief should
  surface several `options` and the questions that would decide between them.
- **find-idea** — the goal is a decision. Compare candidate approaches against
  the topic and converge on a single `recommendation`, with `evidence` and
  `risks` that justify the choice over the alternatives.
- **improve-idea** — one idea already exists and the goal is to make it
  stronger. Concentrate the budget on `evidence` for and against the current
  direction, the `risks` it carries, and the concrete refinements that address
  them.

## The Research Loop

Every pass follows the same phases. Full detail, including the visited set,
total URL cap, depth and breadth ceilings, and forced synthesis at the token
threshold, is in [research loop](references/research-loop.md).

1. **Plan** — break the topic into sub-questions and decide what evidence would
   settle each one.
2. **Search** — use the agent's own web/fetch tools to find sources for the
   sub-questions; read any seed links first.
3. **Follow** — recursively follow only promising links, within the depth and
   breadth ceilings, tracking every visited URL to avoid repeats.
4. **Read and extract** — pull the specific claims, data, and caveats that
   answer the sub-questions, recording the source for each.
5. **Synthesize** — turn the extracted evidence into the decision brief. Force
   this step when the token budget is nearly spent, even if some questions
   remain open; record those under `open_questions`.

This phased loop with recursive link following and forced synthesis satisfies
RSCH-01 and RSCH-04.

## Source Discipline

Prefer primary and authoritative sources, check freshness for facts that change
over time, and mark a confidence level for each claim. Keep source notes scoped
to the topic and never copy secrets or credentials into the brief. The full
hierarchy, freshness checks, confidence labels, and citation rules are in
[source confidence](references/source-confidence.md).

## Output: Decision Brief

A pass is not complete until the evidence becomes a decision. Stopping at a list
of links is a failure. The markdown brief must synthesize findings into these
fields, in this order:

- **topic** — the question that was researched.
- **mode** — the mode the pass ran in.
- **recommendation** — the decision or lead answer the brief supports.
- **options** — the candidate directions considered, with tradeoffs.
- **evidence** — the claims and data behind the recommendation, with sources.
- **risks** — what could make the recommendation wrong or costly.
- **open_questions** — what remains unresolved within the budget.
- **sources** — the cited URLs with short summaries and confidence.

Every emitted brief must contain at least one material `evidence` entry and one
corresponding opened source. If opened sources cannot support a recommendation,
report an inconclusive research failure instead of emitting a brief.

These mandatory fields satisfy RSCH-05 and the decision-brief decision (D-16).
The exact markdown headings and field meanings are in
[brief schema](references/brief-schema.md).

## Optional JSON Output

When a caller needs structured output for chaining into a later skill, also emit
a JSON object that mirrors the markdown brief exactly:

```json
{
  "topic": "decision question",
  "mode": "find-idea",
  "recommendation": "lead answer",
  "options": [],
  "evidence": [{
    "claim": "supporting claim",
    "sources": ["https://example.test/a"],
    "confidence": "high"
  }],
  "risks": [],
  "open_questions": [],
  "sources": [{
    "url": "https://example.test/a",
    "summary": "what the source supports",
    "confidence": "high"
  }]
}
```

Empty arrays are valid only for `options`, `risks`, and `open_questions`.
`evidence` and `sources` must contain at least one entry. The JSON keys must
match the markdown fields one for one, including `risks` and `open_questions`.
This optional JSON mirror satisfies RSCH-06 and the JSON decision (D-17). See
[brief schema](references/brief-schema.md) for the authoritative key list.

## Boundaries

- This skill owns the research process and budget, not a search backend.
- It reads external sources through the agent's tools; it installs nothing.
- It produces a brief; it does not store state or write files on its own.
- Keep the brief scoped to the topic and free of secrets from any source.
