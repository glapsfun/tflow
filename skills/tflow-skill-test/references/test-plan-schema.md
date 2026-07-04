# Test Plan Schema

Authoritative contract for `test-plan.md`, produced by define mode. Fields
appear as markdown headings in this order.

| Field | Type | Required | Meaning | Empty value |
|-------|------|----------|---------|-------------|
| `skill_name` | text | yes | Kebab-case name of the skill under test. | never empty |
| `expected_behaviors` | list | yes | Observable claims the skill must satisfy; in factory use derived from the idea brief's success_criteria. | never empty |
| `eval_scenarios` | list | yes | Judged scenarios, each with a kind (`positive`, `negative`, or `edge`), a prompt, and `pass_criteria`. | never empty |
| `script_tests` | list | yes | Deterministic `*.test.sh` cases per expected script; each case names the script, the behavior, and the exit-0 condition. | empty list allowed (skill ships no scripts) |

Scenario coverage rules: at least one positive, one negative, and one edge
scenario. Every scenario's `pass_criteria` must be checkable against the
skill text alone — no criteria that require running the whole factory.

## Markdown plan

```text
# Test Plan

## skill_name
<kebab-case-name>

## expected_behaviors
- <observable claim>

## eval_scenarios
### <scenario-id> (positive | negative | edge)
- prompt: <what the user asks>
- pass_criteria:
  - <checkable criterion>

## script_tests
### <script-name>.sh
- <case-id>: <behavior> — exits 0 when <condition>
```

When `script_tests` has no entries, keep the heading and write `- none`.
