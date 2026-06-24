---
name: Fail-Bad-Name
description: Use when you need to test name pattern validation
---

This fixture has an uppercase name, which violates R-NAME-PATTERN.

The name "Fail-Bad-Name" contains uppercase letters, which do not match
the required pattern ^[a-z0-9]+(-[a-z0-9]+)*$.

Only one rule is broken: R-NAME-PATTERN (spec).
