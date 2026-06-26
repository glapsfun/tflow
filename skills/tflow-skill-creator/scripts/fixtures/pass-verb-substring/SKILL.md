---
name: pass-verb-substring
description: Use when you need information about typically uninstalled prior art
---

This fixture locks in the CR-02 word-boundary fix for R-DESC-VERBS.

The description contains substrings that look like workflow verbs but are not
whole words: "in**format**ion" (format), "typi**call**y" (call), and
"un**install**ed" (install). With unanchored matching these wrongly FAILed
desc-workflow-verb; with word-boundary anchoring they correctly PASS.

No whole-word workflow verb is present, so this skill must validate (exit 0).
