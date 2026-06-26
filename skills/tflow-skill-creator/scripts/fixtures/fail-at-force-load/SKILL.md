---
name: fail-at-force-load
description: Use when you need to test detection of at-path references in the body
---

This fixture contains an at-prefixed path reference in the body, violating
R-AT-LOAD (tflow PORT-03 convention).

See @references/guide.md for more information about the topic.

The line above contains an at-path reference that would be flagged by
validate.sh as force-load syntax. Use plain markdown links instead:
[guide](references/guide.md)

Only one rule is broken: R-AT-LOAD (tflow).
