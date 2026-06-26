---
name: fail-workflow-verb
description: Use when creating a new skill with the scaffold tool
---

This fixture has a description starting with "Use when" (passing R-DESC-PREFIX)
but containing the workflow verb "creating", which matches creat(es|ing|e)?
in the denylist, violating R-DESC-VERBS (tflow rule D-04).

Only one rule is broken: R-DESC-VERBS (tflow).
