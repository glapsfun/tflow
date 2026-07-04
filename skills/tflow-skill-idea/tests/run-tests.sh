#!/bin/sh
set -eu

# CDPATH= is a one-shot empty assignment scoped to this cd so a user's exported
# CDPATH can't redirect it or print output; the space is intentional, not a typo.
# shellcheck disable=SC1007
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/SKILL.md"
SCHEMA="$ROOT/references/idea-brief-schema.md"
EVALS="$ROOT/evals/evals.json"

PASS=0
FAIL=0

assert_match() {
    LABEL="$1"
    FILE="$2"
    PATTERN="$3"
    if [ -f "$FILE" ] && grep -Eiq "$PATTERN" "$FILE"; then
        printf 'PASS: %s\n' "$LABEL"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s\n' "$LABEL" >&2
        FAIL=$((FAIL + 1))
    fi
}

assert_flat_match() {
    LABEL="$1"
    FILE="$2"
    PATTERN="$3"
    if [ -f "$FILE" ] && tr '\n' ' ' < "$FILE" | grep -Eiq "$PATTERN"; then
        printf 'PASS: %s\n' "$LABEL"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s\n' "$LABEL" >&2
        FAIL=$((FAIL + 1))
    fi
}

assert_match "trigger starts with Use when" "$SKILL" \
    '^description: Use when'
assert_match "dialogue asks one question at a time" "$SKILL" \
    'one question at a time'
assert_match "five whys stops early when purpose is clear" "$SKILL" \
    'stop early'
assert_match "five whys has a hard cap" "$SKILL" \
    'at most five'
assert_match "each answer feeds the next question" "$SKILL" \
    'answer feeds the next'
assert_match "directions come with a recommendation" "$SKILL" \
    'recommendation'
assert_match "abandoned dialogue emits no brief" "$SKILL" \
    'Do not emit an idea brief'
assert_match "no field is filled on the human's behalf" "$SKILL" \
    "never fill .*on the human's behalf"
assert_match "raw prompt is captured verbatim" "$SCHEMA" \
    'verbatim'
assert_flat_match "schema names all eight fields in order" "$SCHEMA" \
    'raw_prompt.*core_purpose.*chosen_direction.*rejected_directions.*target_users.*success_criteria.*research_questions.*research_mode'
assert_match "research mode is base or deep" "$SCHEMA" \
    '`base` or `deep`'
assert_match "success criteria feed the check phase" "$SCHEMA" \
    'check phase'
assert_match "research questions feed the validate phase" "$SCHEMA" \
    'validate phase'

if python3 - "$EVALS" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

expected = {
    "happy-path-brief",
    "vague-idea-five-whys",
    "human-abandons",
    "all-directions-rejected",
    "research-mode-choice",
}
actual = {case["id"] for case in payload["evals"]}
if payload.get("skill") != "tflow-skill-idea":
    raise SystemExit("wrong skill name")
if actual != expected:
    raise SystemExit(f"eval ids differ: expected {sorted(expected)}, got {sorted(actual)}")
for case in payload["evals"]:
    if not case.get("prompt") or not case.get("expected"):
        raise SystemExit(f"incomplete eval: {case.get('id')}")
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
