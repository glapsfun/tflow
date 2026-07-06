#!/bin/sh
set -eu

# CDPATH= is a one-shot empty assignment scoped to this cd so a user's exported
# CDPATH can't redirect it or print output; the space is intentional, not a typo.
# shellcheck disable=SC1007
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/SKILL.md"
EXAMPLES="$ROOT/references/examples.md"
EVALS="$ROOT/evals/evals.json"

PASS=0
FAIL=0

assert_match() {
    LABEL="$1"
    FILE="$2"
    PATTERN="$3"
    if grep -Eq "$PATTERN" "$FILE"; then
        printf 'PASS: %s\n' "$LABEL"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s\n' "$LABEL" >&2
        FAIL=$((FAIL + 1))
    fi
}

assert_absent() {
    LABEL="$1"
    FILE="$2"
    PATTERN="$3"
    if grep -Eq "$PATTERN" "$FILE"; then
        printf 'FAIL: %s\n' "$LABEL" >&2
        FAIL=$((FAIL + 1))
    else
        printf 'PASS: %s\n' "$LABEL"
        PASS=$((PASS + 1))
    fi
}

assert_match "description starts with Use when" "$SKILL" \
    '^description: Use when '
assert_absent "no @-force-load path syntax in SKILL.md" "$SKILL" \
    '@[A-Za-z0-9_./-]+'
assert_absent "no @-force-load path syntax in examples" "$EXAMPLES" \
    '@[A-Za-z0-9_./-]+'
assert_match "default is a single rewrite-and-explain pass" "$SKILL" \
    'rewrite \*and\*'
assert_match "process includes a completeness check" "$SKILL" \
    'Run the completeness check'
assert_match "completeness check names four components" "$SKILL" \
    'up to four'
assert_match "result is exactly two parts" "$SKILL" \
    'Return exactly two parts'
assert_match "enhanced prompt goes in a fenced block" "$SKILL" \
    'Enhanced prompt.*fenced code block'
assert_match "completeness note closes the result" "$SKILL" \
    'completeness note'

# All eight change-log tags must be documented.
assert_match "tag clarity is documented" "$SKILL" '`clarity`'
assert_match "tag context is documented" "$SKILL" '`context`'
assert_match "tag example is documented" "$SKILL" '`example`'
assert_match "tag structure is documented" "$SKILL" '`structure`'
assert_match "tag role is documented" "$SKILL" '`role`'
assert_match "tag reasoning is documented" "$SKILL" '`reasoning`'
assert_match "tag decomposition is documented" "$SKILL" '`decomposition`'
assert_match "tag cut is documented" "$SKILL" '`cut`'

assert_match "techniques are ordered with decomposition last" "$SKILL" \
    '7\. \*\*Decomposition\*\*'
assert_match "thin prompts trigger up to three questions" "$SKILL" \
    'up to three'
assert_match "version-honesty defers to provider docs" "$SKILL" \
    "provider's current documentation"
assert_match "boundaries refuse to run or benchmark prompts" "$SKILL" \
    'does not run, benchmark, or evaluate'

assert_match "examples show a before block" "$EXAMPLES" \
    '\*\*Before:\*\*'
assert_match "examples show an after block" "$EXAMPLES" \
    '\*\*After'
assert_match "examples include a cut-dominated rewrite" "$EXAMPLES" \
    'improved mostly by cutting'

if python3 - "$EVALS" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

if payload.get("skill") != "tflow-prompt":
    raise SystemExit("skill field must be 'tflow-prompt'")

expected = {
    "vague-one-liner",
    "format-sensitive-classification",
    "over-engineered-cut",
    "thin-prompt-ask-first",
}
actual = {case["id"] for case in payload["evals"]}
if actual != expected:
    raise SystemExit(f"eval ids differ: expected {sorted(expected)}, got {sorted(actual)}")

for case in payload["evals"]:
    if not case.get("prompt") or not case.get("expected"):
        raise SystemExit(f"eval {case.get('id')} is missing prompt or expected")
PY
then
    printf 'PASS: eval cases are valid and complete\n'
    PASS=$((PASS + 1))
else
    printf 'FAIL: eval cases are valid and complete\n' >&2
    FAIL=$((FAIL + 1))
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
