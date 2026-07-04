# Doc Phase

Factory-internal step 8. Runs only after an `approved` verdict. Inputs:
every run artifact plus the built skill directory. Outputs: documentation
written into the skill directory, and `run-summary.md` in the run
directory.

## Skill documentation

Ensure the built skill carries its own user-facing documentation — added
into the skill directory so it ships with the skill:

- What the skill is for and when to reach for it (aligned with its
  frontmatter description).
- How to use it: inputs, outputs, and at least one worked example.
- Limitations and non-goals discovered during the run, including anything
  the check phase accepted with caveats.

Then re-run the creator's `validate.sh` against the skill directory; doc
edits must not break the structural gate.

## Run summary

`run-summary.md` records the whole run for the human:

```text
# Run Summary

## skill
<name and final path>

## goal
<core_purpose from the idea brief>

## iterations used
- re-research rounds: <n> of 2
- improvement iterations: <n> of 3

## test outcome
<overall verdict and per-layer counts from test-results.md>

## what changed each loop
- iteration <n>: <fixes applied>

## artifacts
- <path per artifact produced>
```

The summary reports; it never edits the skill or re-judges a verdict.
