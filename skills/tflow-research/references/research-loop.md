# Research Loop

This reference defines the bounded, recursive research process for
`tflow-research`. It expands the phases summarized in `SKILL.md` and specifies
the exact budget controls that keep a pass from expanding without limit.

The loop uses the agent's own web and fetch tools. It does not bundle a search
provider. Every external read goes through the runtime's web/search/fetch
capability.

## Inputs the loop consumes

- **topic** (required) — the decision question to research.
- **mode** — `brainstorm`, `find-idea`, or `improve-idea`; sets emphasis and
  default budgets.
- **seed links** — URLs read first, before broader search.
- **depth** — maximum link hops away from a starting source.
- **breadth** — maximum sources considered per phase.
- **token_budget** — approximate total reading budget for the whole pass.

## Phases

### 1. Plan

Decompose the topic into a small set of sub-questions. For each sub-question,
name the kind of evidence that would settle it (benchmark, spec, primary doc,
maintainer statement, dated comparison). Order sub-questions by how much they
move the decision so the budget is spent on what matters.

### 2. Search

Read any seed links first. Then use the agent's web/fetch tools to find sources
for the highest-value sub-questions. Do not open more than `breadth` sources in
a single phase. Record every URL opened in the visited set immediately.

### 3. Follow (recursive)

From a promising source, follow only links that are likely to answer an open
sub-question. Each hop away from an original source counts against `depth`.
Never follow a link that is already in the visited set. Stop following when:

- the current hop count would exceed `depth`, or
- the sources opened in this phase would exceed `breadth`, or
- the total URLs opened would exceed the total URL cap (below).

### 4. Read and extract

For each opened source, extract only the specific claims, numbers, and caveats
that answer a sub-question. Attach the source URL and an access note to each
extracted claim so it can be cited and confidence-rated later. Note freshness
for any claim that can change over time (see
[source confidence](source-confidence.md)).

### 5. Synthesize

Turn the extracted evidence into the decision brief defined in
[brief schema](brief-schema.md). This phase is mandatory. A pass that stops at a
list of sources without a `recommendation` has failed. Anything unresolved when
the pass ends goes under `open_questions`, not into more searching.

## Budget controls

These controls are not optional. Omitting any of them reintroduces the
unbounded-recursion failure mode.

- **Visited set** — every opened URL is recorded before it is read. A URL in the
  visited set is never opened again, which prevents cycles and repeats.
- **Total URL cap** — a hard ceiling on the number of distinct URLs opened in
  the whole pass, independent of `depth` and `breadth`. Derive it from
  `breadth` and `depth` (roughly `breadth x (depth + 1)`) and treat it as an
  absolute stop. When the cap is reached, go straight to synthesis.
- **Depth ceiling** — `depth` caps how far the loop recurses away from any
  starting source. Hops beyond `depth` are not followed.
- **Breadth ceiling** — `breadth` caps how many sources are considered per
  phase, so a single phase cannot fan out without limit.
- **Forced synthesis near token_budget** — track approximate tokens read. When
  the running total approaches `token_budget`, stop searching and following and
  move immediately to synthesis. It is correct to produce a brief with open
  questions rather than exhaust the budget chasing more links.

## Stopping rules

Stop the loop and synthesize when any of these is true:

1. The `recommendation` is already well-supported and more sources would not
   change it (early stop — preferred).
2. The total URL cap has been reached.
3. The reading total has reached the forced-synthesis threshold near
   `token_budget`.
4. Every remaining open sub-question depends on information no available source
   provides; record these under `open_questions`.

Always reach phase 5. None of the stopping rules permit ending without a brief.

## Budget escalation

Defaults are conservative on purpose (see the defaults table in `SKILL.md`).
Escalate only deliberately:

- Raise `breadth` when the option space is wider than the default sample can
  fairly represent.
- Raise `depth` when the deciding evidence lives several hops from the entry
  sources (for example a spec referenced by a referenced doc).
- Raise `token_budget` when the topic genuinely needs more reading, and raise
  the total URL cap with it so the new budget is usable.

Escalation is always caller-driven or an explicit, recorded decision in the
pass — never an automatic reaction to running low. When in doubt, synthesize at
the current budget and list what a larger run would investigate under
`open_questions`.
