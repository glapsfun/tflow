---
name: fail-workflow-verb-gerund
description: Use when formatting a report before sending it to a teammate
---

This fixture has a description starting with "Use when" (passing R-DESC-PREFIX)
but containing the workflow gerund "formatting", which matches
format(s|ting|ing)? in the denylist, violating R-DESC-VERBS (tflow rule D-04).
The double-consonant gerund ("formatting", not "formating") is the case the
earlier format(s|ing)? pattern missed.

Only one rule is broken: R-DESC-VERBS (tflow).
</content>
</invoke>
