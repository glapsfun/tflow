# Brief Schema

This reference is the authoritative output contract for `tflow-research`. The
synthesize phase in [research loop](research-loop.md) produces a decision brief
in exactly this shape. Markdown is always produced; JSON is optional and mirrors
the markdown one for one.

## Field contract

The brief has these eight fields, in this order. This list is the contract: the
same fields are the markdown headings and the JSON keys.

| Field | Type | Required | Meaning | Empty value |
|-------|------|----------|---------|-------------|
| `topic` | text | yes | The decision question that was researched. | never empty |
| `mode` | text | yes | The pass mode: `brainstorm`, `find-idea`, or `improve-idea`. | never empty |
| `recommendation` | text | yes | The decision or lead answer the brief supports; one or two sentences. | never empty |
| `options` | list | yes | Candidate directions considered, each with its tradeoff. | empty list allowed |
| `evidence` | list | yes | Claims and data behind the recommendation, each citing a source and a confidence label. | empty list allowed |
| `risks` | list | yes | What could make the recommendation wrong or costly. | empty list allowed |
| `open_questions` | list | yes | What remains unresolved within the budget. | empty list allowed |
| `sources` | list | yes | Cited URLs, each with a short summary and confidence label. | empty list allowed |

`topic`, `mode`, and `recommendation` are always populated — a brief without a
`recommendation` is not a valid decision brief. The five list fields may be
empty lists when a section genuinely has no entries, but they are never omitted.

## Markdown brief

Use these headings, in this order. The field names above are the headings.

```markdown
# Research Brief

## topic
<the question that was researched>

## mode
<brainstorm | find-idea | improve-idea>

## recommendation
<the decision or lead answer, one or two sentences>

## options
| Option | Tradeoff |
|--------|----------|
| ...    | ...      |

## evidence
| Claim | Source | Confidence |
|-------|--------|------------|
| ...   | [url]  | high/medium/low |

## risks
- <risk and why it matters>

## open_questions
- <what is still unresolved>

## sources
- [url] — <short summary> (confidence: high/medium/low)
```

When a list section has no entries, keep the heading and write a single line
such as `- none` so the section is explicit rather than missing.

## Optional JSON brief

When a caller needs structured output for chaining into a later skill, emit a
JSON object with exactly these keys. The keys mirror the markdown fields one for
one, including `risks` and `open_questions`.

```json
{
  "topic": "string",
  "mode": "brainstorm | find-idea | improve-idea",
  "recommendation": "string",
  "options": [
    { "option": "string", "tradeoff": "string" }
  ],
  "evidence": [
    { "claim": "string", "source": "url", "confidence": "high | medium | low" }
  ],
  "risks": [
    { "risk": "string" }
  ],
  "open_questions": [
    "string"
  ],
  "sources": [
    { "url": "url", "summary": "string", "confidence": "high | medium | low" }
  ]
}
```

Rules for the JSON mirror:

- The eight top-level keys match the markdown headings exactly; none is renamed,
  added, or dropped.
- A section with no entries is an empty array (`[]`), never a missing key and
  never `null`.
- `topic`, `mode`, and `recommendation` are non-empty strings.
- Every `evidence` and `sources` entry carries a `confidence` label, matching
  the labels defined in [source confidence](source-confidence.md).
