# Check Phase

Factory-internal step 7 — the arbiter. Inputs: `idea-brief.md`,
`test-results.md`, and the built skill directory. Output:
`review-verdict.md`. The arbiter reads everything and edits nothing.

## Checks

1. **Intent.** The built skill serves the idea brief's `core_purpose` and
   `chosen_direction` — not a nearby problem.
2. **Success criteria.** Every entry in the idea brief's `success_criteria`
   is observably satisfied by the skill, citing the file and lines that
   satisfy it.
3. **Tests.** `test-results.md` reports `overall: pass`. The arbiter
   may not soften a failing or missing test into a pass, may not re-run
   tests with weaker criteria, and may not reinterpret `not reached` as
   passed.
4. **Clarity.** The skill's workflow is followable by a fresh agent:
   inputs, outputs, and failure behavior are stated, and reference links
   resolve.

## Verdict

`review-verdict.md` has these fields, in order, as markdown headings:

```text
# Review Verdict

## verdict
approved | needs-improvement

## satisfied
- <criterion> — <file:lines that satisfy it>

## fixes
- <file or file:lines> — <what must change and why>
```

The verdict is `approved` or `needs-improvement` — nothing else. `fixes`
entries are keyed to files (or file:line ranges) so the next create
iteration can act on them directly; a fix that names no file is invalid.
On `approved`, `fixes` contains `- none`.
