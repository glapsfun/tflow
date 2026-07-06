# Worked Examples

Two before/after enhancements. They show the two-part result format and, more
importantly, that enhancement is *proportional*: choose the few techniques that
move a prompt toward its goal rather than applying all seven every time.

## Example 1 — a thin prompt fixed by clarity alone

A simple ask that is underspecified. It needs a clarity pass and an output
indicator; reaching for examples, a role, or step-by-step reasoning would be
noise.

**Before:**

```
write a function to clean up the data
```

**After (enhanced prompt):**

```
Write a Python function `clean_records(records)` that takes a list of dicts and
returns a new list with: (1) rows dropped where `email` is missing or empty,
(2) `email` lowercased and stripped of surrounding whitespace, (3) duplicate
rows removed by `email`, keeping the first occurrence.

Return only the function plus a one-line docstring. Do not print or read files.
```

**Change log:**

- `clarity` — named the language, signature, and the three concrete cleaning
  rules instead of "clean up the data".
- `clarity` — stated the output indicator (function + one-line docstring, no
  I/O) so the result shape is unambiguous.

**Completeness note:** instruction and output indicator are now present; the
user should supply a sample `records` value if the dict schema differs from the
assumed `email` key.

## Example 2 — an over-engineered prompt improved mostly by cutting

A prompt stuffed with ceremony that buries the actual task. The dominant move is
removal; a light role line is the only addition that earns its place.

**Before:**

```
You are an extraordinarily talented, world-class, award-winning senior copywriter
with 20+ years of experience and a PhD. Think very very carefully step by step in
extreme detail. It is ABSOLUTELY CRITICAL and you MUST NOT FAIL. Please please
write me a tweet about our new coffee subscription. Make it good. Take a deep
breath. Do not hallucinate.
```

**After (enhanced prompt):**

```
You are a copywriter. Write one tweet (≤ 280 characters) announcing our new
coffee subscription: fresh beans shipped monthly, cancel anytime. Friendly,
concrete, no hashtags or emoji unless they earn their place.
```

**Change log:**

- `cut` — removed the inflated persona stacking, the all-caps pressure, the
  "take a deep breath / don't hallucinate" filler, and the duplicated "please".
- `role` — kept a single, sufficient role ("a copywriter").
- `clarity` — stated the real constraints: length, the two product facts, tone,
  and the hashtag/emoji rule.

**Completeness note:** instruction, context, and output indicator are present;
the user should supply the subscription price or launch date if the tweet must
include one.
