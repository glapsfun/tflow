---
name: tflow-prompt
description: Use when the user shares a raw, vague, or first-draft prompt and wants it clarified, tightened, strengthened, or made more reliable — or asks to improve, rewrite, or optimize a prompt, write a system prompt, or apply prompt-engineering techniques like few-shot examples, chain-of-thought, role framing, or XML structuring
license: MIT
compatibility: Portable Agent Skill source for Claude Code, OpenAI Codex, and runtimes that support SKILL.md; requires no scripts, tools, or network access.
---

# tflow Prompt

Use this skill to turn a user's base prompt into a stronger one. The default is a
single pass: read the prompt, apply the techniques that actually help it, and
hand back the rewritten prompt **plus** a short change log. Always rewrite *and*
explain — never return a silently transformed prompt the user cannot audit.

Enhance to earn it, not to decorate. Add a technique only when it makes the
prompt measurably clearer for its goal; if the original is already tight, say so
and change little. Match effort to the prompt's complexity — a one-liner usually
needs a clarity pass, not all seven techniques.

Prompt-engineering specifics drift between model releases: token limits,
provider flags, and model names change. Treat the technique *principles* here as
durable, but tell the user to verify any concrete model name, token limit, or
API field against the provider's current documentation rather than trusting a
fixed value.

## Locating the prompt

Take the prompt to enhance from the user's latest message or from earlier in the
conversation. If no candidate prompt is present, ask the user to paste the one
they want strengthened before going further.

## Process

1. **Infer the goal.** What outcome does the user want, for what audience, in
   what shape? If the prompt is too thin to infer a goal, ask up to three
   targeted questions (typically goal, audience, result shape), then proceed.
2. **Run the completeness check.** A well-formed prompt covers up to four
   components: an **instruction** (the task), **context** (background and
   motivation), **input data** (the material to act on), and an **output
   indicator** (the shape of the result). Note only the ones that are missing
   *and matter* for this task — not every prompt needs all four.
3. **Apply the techniques in order**, each only where it helps. The order in
   [Techniques](#techniques-in-order) is deliberate: clarity first, structure
   and examples next, role and reasoning last.
4. **Scale to complexity.** Reserve examples, structure, role framing, and
   step-by-step reasoning for prompts whose difficulty earns them. Name anything
   you *remove* as noise, not just what you add.
5. **Return the two-part result** below.

## Techniques, in order

1. **Clarity & directness** — state the task and its constraints explicitly;
   replace vague language with concrete instructions.
2. **Context & motivation** — explain *why*, so the model generalizes beyond the
   literal words.
3. **Examples** — show 2–5 diverse examples for format-sensitive or nuanced
   tasks; demonstrate the desired output rather than only describing it.
4. **Structure** — separate instruction, context, and input into labeled
   sections (headers or tags) so they are not confused for one another.
5. **Role** — give the model a role or expertise level when tone or domain rigor
   matters.
6. **Reasoning** — invite step-by-step thinking for analytical or multi-factor
   tasks, before the final answer.
7. **Decomposition** — split complex, multi-stage work into sequential prompts
   where each output feeds the next.

Worked before/after rewrites are in [examples](references/examples.md).

## Result format

Return exactly two parts, in this order:

1. **Enhanced prompt** — the rewritten prompt in a fenced code block, ready to
   copy and use verbatim.
2. **Change log** — a short bullet list, each line tagged by the technique that
   motivated it and a one-line reason, ending with a **completeness note**: one
   line naming which of the four components (instruction, context, input,
   output indicator) are now present, and any the user must still supply — for
   example real input data or domain facts. Use these tags:
   - `clarity` — sharpened or disambiguated the instruction.
   - `context` — added background or motivation.
   - `example` — added or restructured examples.
   - `structure` — introduced or tidied sectioning.
   - `role` — set or adjusted a role.
   - `reasoning` — invited step-by-step thinking.
   - `decomposition` — split into stages or sequenced prompts.
   - `cut` — removed noise, redundancy, or over-specification.

## Boundaries

- This skill improves prompts; it does not run, benchmark, or evaluate them.
  Suggest the user test against their own success criteria, but keep execution
  out of scope.
- It assumes no specific provider or model. The techniques are general; defer
  vendor-specific detail to the provider's live documentation.
- It never fabricates the user's domain facts or input data. Missing material is
  named in the completeness note, not guessed.

## References

- [examples](references/examples.md) — worked before/after enhancements showing
  the two-part result and proportional technique use.
