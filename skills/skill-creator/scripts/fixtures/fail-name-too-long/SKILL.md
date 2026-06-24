---
name: aaaaaaaaaa-aaaaaaaaaa-aaaaaaaaaa-aaaaaaaaaa-aaaaaaaaaa-aaaaaaaaaa
description: Use when you need to test name length validation
---

This fixture has a name that exceeds 64 characters, violating R-NAME-LEN.

The name above is 65 characters long (10+1+10+1+10+1+10+1+10+1+7 = 65).
It also does not match the directory name "fail-name-too-long", so both
R-NAME-LEN and R-NAME-DIR fire. The test only asserts exit 1, so firing
multiple rules is acceptable; R-NAME-LEN is the primary target.
