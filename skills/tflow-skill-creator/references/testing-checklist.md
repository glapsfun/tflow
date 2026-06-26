# Testing Checklist

`scripts/improve.sh` writes `.skill-improvement.md`. That report is the evidence
gate consumed by `scripts/package.sh`.

## Required Evidence

Complete the report with concrete evidence before packaging:

- final validation command and exit result;
- realistic invocation test for the skill's trigger condition;
- reference and asset review showing supporting files are relevant and reachable;
- portability review confirming no runtime-only frontmatter or install path is
  required;
- package artifact review after `scripts/package.sh` succeeds.

Use checked checklist entries only after the evidence exists. An unchecked entry
means the skill is not ready to package.

## Realistic Invocation Test

Test the skill with a prompt that resembles real use. For a factory skill, include
pressure that tempts the agent to skip gates, such as time pressure or a
pre-existing draft. The expected behavior is that the agent still follows
`scripts/init.sh`, `scripts/validate.sh`, `scripts/improve.sh`, and
`scripts/package.sh`.

Record:

- the prompt used;
- whether the skill loaded at the right time;
- commands the agent ran;
- any gate the agent tried to skip;
- edits made after validation or evidence review.

## Validation Output

Capture the final validation command:

```sh
sh skills/tflow-skill-creator/scripts/validate.sh <skill-dir>
```

The report should include the exit result and relevant output. A warning about
missing `shellcheck` is acceptable when `shellcheck` is not installed; a failure
is not acceptable for packaging.

## Checklist Blocking Rule

`scripts/package.sh` refuses to package when `.skill-improvement.md` contains any
line that begins with:

```text
- [ ]
```

Do not remove checklist items to bypass the gate. Replace each unchecked item
with checked evidence after the test or review is complete.

## Package Artifact Review

After packaging, inspect both outputs:

- `dist/<skill-name>/` contains the expected skill source files;
- `dist/<skill-name>.tar.gz` exists and can be listed with `tar -tzf`;
- no prior `dist/`, caches, editor swap files, or generated evidence files are
  inside the package;
- install hints are printed as hints only, with no runtime directory writes.

The final user summary should include the skill path, validation command,
evidence file path, package directory, archive path, and any limitation found
during testing.
