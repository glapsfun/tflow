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
| `evidence` | list | yes | Claims and data behind the recommendation, each citing one or more opened sources and a confidence label. | never empty |
| `risks` | list | yes | What could make the recommendation wrong or costly. | empty list allowed |
| `open_questions` | list | yes | What remains unresolved within the budget. | empty list allowed |
| `sources` | list | yes | Opened absolute URLs, each with a short summary and confidence label. | never empty |

`topic`, `mode`, `recommendation`, `evidence`, and `sources` are always
populated. A pass that cannot support a recommendation with at least one
material evidence entry and one opened source must report an inconclusive
research failure instead of emitting a Research Brief. `options`, `risks`, and
`open_questions` may be empty lists, but they are never omitted.

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
| Claim | Sources | Confidence |
|-------|---------|------------|
| ...   | [descriptive label](https://example.test/path) | high/medium/low |

## risks
- <risk and why it matters>

## open_questions
- <what is still unresolved>

## sources
- [descriptive label](https://example.test/path) — <short summary> (confidence: high/medium/low)
```

When `options`, `risks`, or `open_questions` has no entries, keep the heading
and write `- none`. `evidence` and `sources` must never be empty in an emitted
brief.

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
    {
      "claim": "string",
      "sources": ["https://example.test/a", "https://example.test/b"],
      "confidence": "high | medium | low"
    }
  ],
  "risks": [
    { "risk": "string" }
  ],
  "open_questions": [
    "string"
  ],
  "sources": [
    {
      "url": "https://example.test/a",
      "summary": "string",
      "confidence": "high | medium | low"
    }
  ]
}
```

Rules for the JSON mirror:

- The eight top-level keys match the markdown headings exactly; none is renamed,
  added, or dropped.
- `evidence` and top-level `sources` contain at least one entry; the other list
  fields use `[]` when empty.
- `topic`, `mode`, and `recommendation` are non-empty strings.
- Every `evidence[].sources` value is a non-empty array of absolute URLs also
  represented in the top-level `sources` list.
- Every `evidence` and top-level `sources` entry carries a `confidence` label
  matching [source confidence](source-confidence.md).
