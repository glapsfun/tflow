---
name: pass-well-formed
description: Use when you need a canonical example of a well-formed skill that passes all quality checks
license: MIT
---

This skill serves as a reference fixture for the validate.sh self-test suite.

It demonstrates a well-formed SKILL.md that satisfies every rule in the
agentskills.io specification v1 and all tflow project conventions.

The name matches the parent directory name, the description starts with
"Use when", contains no workflow verbs, no XML tags, and is within the
character limit. The body is well under 500 lines and contains no
at-prefixed path references.

Use this fixture to confirm that validate.sh exits 0 on valid input.
