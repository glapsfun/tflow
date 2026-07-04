# Validate Phase

Factory-internal step 3. Inputs: `idea-brief.md` and `research-brief.md`
from the run directory. Output: `validation-report.md`. This phase judges
the research against the idea — it does not redo the research and it does
not touch the idea brief.

## Checks

1. **Coverage.** Every entry in the idea brief's `research_questions` is
   answered in the research brief with sourced evidence — at least one
   evidence row whose sources list is nonempty. An unanswered question is
   a gap.
2. **Grounding.** The research brief's `recommendation` is supported by its
   own `evidence` rows; a recommendation resting only on model memory is a
   gap.
3. **Assumptions.** Implicit assumptions are surfaced: anything the
   evidence takes for granted that the idea brief does not state is listed
   explicitly.
4. **Implementability.** The chosen direction can be built as a portable
   Agent Skill (SKILL.md plus optional POSIX sh scripts) within the scope
   the idea brief describes. Anything requiring capabilities the runtime
   cannot promise is a gap.

## Report

`validation-report.md` has these fields, in order, as markdown headings:

```text
# Validation Report

## verdict
proceed | re-research

## valid_points
- <what holds up and why>

## gaps
- <unanswered question or ungrounded claim>

## assumptions
- <assumption made explicit>

## refined_research_input
<only when verdict is re-research: the gap list rewritten as the topic and
seed questions for the next tflow-research pass>
```

The verdict is `proceed` or `re-research` — nothing else. On `re-research`
the `refined_research_input` becomes the next research pass's input
verbatim, and each gap refines the next research pass as a question it
must answer. On `proceed`, `refined_research_input` is omitted.
