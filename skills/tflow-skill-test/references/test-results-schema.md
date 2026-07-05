# Test Results Schema

Authoritative contract for `test-results.md`, produced by run mode. Fields
appear as markdown headings in this order.

| Field | Type | Required | Meaning | Empty value |
|-------|------|----------|---------|-------------|
| `skill_name` | text | yes | Name of the skill that was tested. | never empty |
| `layer_1` | section | yes | Structural gate: the validate.sh command, exit status, and verdict. | never empty |
| `layer_2` | section | yes | Script checks: each case with pass/fail, or `skipped` when the skill ships no scripts, or `not reached` after a layer 1 failure. | never empty |
| `layer_3` | section | yes | Judged scenarios: each case with pass/fail, the line citations relied on, or `not reached`. | never empty |
| `overall` | text | yes | `pass` or `fail` — `pass` only when layer 1 passed, layer 2 passed or was skipped, and every layer 3 scenario passed. | never empty |

Record each case individually: one line per case with its id, verdict, and
(for layer 3) the cited lines. A short-circuited layer is `not reached`,
which is distinct from `skipped` and from `fail`.

## Markdown results

```text
# Test Results

## skill_name
<kebab-case-name>

## layer_1
- command: sh .../validate.sh <skill-dir>
- exit: <status>
- verdict: pass | fail

## layer_2
- <case-id>: pass | fail
(or: skipped — skill ships no scripts / not reached)

## layer_3
- <scenario-id>: pass | fail — cites SKILL.md:<lines>
(or: not reached)

## overall
pass | fail
```
