---
name: tflow-research
description: Use when a decision needs bounded web research before committing — comparing options, picking an approach, or pressure-testing an existing idea — and the answer must be traceable to opened sources rather than model memory
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

`depth`, `breadth`, and `token_budget` are the cost controls. They keep the
budget bounded and prevent the unbounded recursion failure mode. See the
[research loop](references/research-loop.md) for how the agent applies the
visited set, URL cap, and stopping rules.

## Preflight and Failure

Validate `mode`, `depth`, `breadth`, and `token_budget` before research begins.
Reject invalid or non-positive numeric controls.

Confirm that the runtime can open at least one external source through its web,
search, or fetch tools. If no source can be opened, report the missing
capability and stop. Do not emit a Research Brief, JSON brief, citations, or
confidence labels, and do not substitute model memory for opened evidence.

**Violating the letter of this rule is violating its spirit.** A brief built
from memory with a disclaimer is still a forbidden brief. When sources cannot be
opened, the only correct output is a short capability report naming what is
missing.

| Rationalization | Reality |
|-----------------|---------|
| "I'll answer from training knowledge and just flag it's unverified." | A disclaimed brief is still a brief built on memory. Report the missing capability and stop. |
| "I'll list URLs as starting points the user can check." | URLs recalled from memory are fabricated citations — the exact failure this rule forbids. Cite only sources opened this pass. |
| "A recommendation with caveats is more useful than nothing." | This rule is fail-closed. The useful answer is naming the missing capability so it can be fixed, not a sourced-looking guess. |

Red flags — STOP and emit only a capability report:

- About to write a `recommendation` with no opened source behind it.
- About to print a URL that was not opened this pass.
- Reaching for an "as of my knowledge" or "not fetched live" disclaimer.

## Modes and Defaults

Each mode sets what the pass optimizes for and a conservative default budget.
Defaults are deliberately small so a research pass never expands unboundedly by
accident. Callers must explicitly raise `depth`, `breadth`, or `token_budget`
for a larger run.

| Mode | Goal | Output emphasis | Default depth | Default breadth | Default token_budget |
|------|------|-----------------|---------------|-----------------|----------------------|
| `brainstorm` | Map the option space for an open topic | Many `options`, light `evidence`, sharp `open_questions` | 1 | 3 | 8,000 |
| `find-idea` | Pick a recommended approach from candidates | A clear `recommendation` backed by compared `options` | 2 | 4 | 16,000 |
| `improve-idea` | Strengthen one existing idea | Deep `evidence` and `risks` for the current direction | 2 | 3 | 16,000 |

Larger numbers are opt-in, never the default. The `Goal` and `Output emphasis`
columns above are the authoritative definition of each mode. See the
[research loop](references/research-loop.md) for accounting and escalation.

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
See [brief schema](references/brief-schema.md) for the authoritative key list.

## Boundaries

- This skill owns the research process and budget, not a search backend.
- It reads external sources through the agent's tools; it installs nothing.
- It produces a brief; it does not store state or write files on its own.
- Keep the brief scoped to the topic and free of secrets from any source.
