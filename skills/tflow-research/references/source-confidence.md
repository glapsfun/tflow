# Source Confidence

This reference defines how `tflow-research` judges sources, checks freshness,
labels confidence, and cites evidence. It supports the read/extract and
synthesize phases in [research loop](research-loop.md) and the `evidence` and
`sources` fields in [brief schema](brief-schema.md).

The goal is a brief whose claims can be trusted because each one is traceable to
a rated source. Weak or stale sources are the tampering risk this reference
mitigates.

## Source hierarchy

Prefer sources higher in this list. When sources disagree, weight the higher
tier and say so in `evidence`.

1. **Primary and authoritative** — official specifications, standards, the
   project's own documentation, source code, and maintainer statements. These
   are the strongest evidence.
2. **Reputable secondary** — established technical publications, well-regarded
   engineering blogs, and conference or peer-reviewed material that cite their
   own sources.
3. **Community and anecdotal** — forum posts, issue threads, and individual blog
   posts. Useful for leads and real-world caveats, but corroborate before
   relying on them.
4. **Unverifiable or promotional** — vendor marketing, undated content, and
   AI-generated summaries with no traceable origin. Treat as a lead only and
   never as sole support for a `recommendation`.

## Freshness checks for unstable facts

Some facts change over time: version numbers, pricing, performance benchmarks,
"best tool" claims, API shapes, deprecation status, and availability. For any
such claim:

- Verify it against a current, dated source before trusting it. Do not rely on
  memory or on an undated page for a fact that moves.
- Record the date the source reflects and the date it was accessed.
- Prefer the most recent authoritative source; note when a widely cited claim is
  stale.
- Describe the selection criterion rather than embedding a fixed "as of today
  the answer is X" statement, so the brief does not silently rot.

If an unstable fact cannot be confirmed against a current source, mark it `low`
confidence and add it to `open_questions`.

## Confidence labels

Assign every material claim in `evidence` one label:

- **high** — backed by a primary/authoritative source, or by multiple
  independent reputable sources that agree, and current if the fact is unstable.
- **medium** — backed by a single reputable secondary source, or by agreeing
  community sources, with no strong contradiction found.
- **low** — based on a single weak source, an undated page for an unstable fact,
  or an inference the agent could not corroborate.

The `recommendation` should rest on `high` or `medium` evidence. If only `low`
evidence is available, say so plainly and route the uncertainty into `risks` and
`open_questions`.

## Citation discipline

- Every claim in `evidence` cites at least one entry in `sources`.
- Every entry in `sources` is a real URL the agent actually opened, with a short
  summary of what it supports and its confidence label.
- Do not cite a source that was not read, and do not invent URLs.
- Quote or paraphrase precisely; do not overstate what a source says.
- Keep source notes scoped to the topic. Never copy secrets, credentials,
  tokens, or private data from a source into the brief, even verbatim in a
  quote.

## When sources conflict

State the conflict in `evidence`, weight by the hierarchy above, and let the
`recommendation` follow the stronger tier. If the conflict is genuinely
unresolved within budget, lower the affected claim's confidence and record the
disagreement under `open_questions` rather than papering over it.
