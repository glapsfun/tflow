#!/bin/sh
set -eu

# CDPATH= is a one-shot empty assignment scoped to this cd so a user's exported
# CDPATH can't redirect it or print output; the space is intentional, not a typo.
# shellcheck disable=SC1007
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/SKILL.md"
PLAN_SCHEMA="$ROOT/references/test-plan-schema.md"
RESULTS_SCHEMA="$ROOT/references/test-results-schema.md"
RUNNER="$ROOT/scripts/run-layer2.sh"
FIXTURES="$ROOT/tests/fixtures"
EVALS="$ROOT/evals/evals.json"

PASS=0
FAIL=0

ok() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
ko() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

assert_match() {
    if [ -f "$2" ] && grep -Eiq "$3" "$2"; then ok "$1"; else ko "$1"; fi
}

assert_flat_match() {
    if [ -f "$2" ] && tr '\n' ' ' < "$2" | grep -Eiq "$3"; then ok "$1"; else ko "$1"; fi
}

# ── run-layer2.sh behavior ────────────────────────────────────────────────────

if [ -f "$RUNNER" ] && sh "$RUNNER" "$FIXTURES/layer2-pass" >/dev/null 2>&1; then
    ok "runner exits 0 on an all-pass directory"
else
    ko "runner exits 0 on an all-pass directory"
fi

if [ -f "$RUNNER" ] && ! sh "$RUNNER" "$FIXTURES/layer2-fail" >/dev/null 2>&1; then
    ok "runner exits non-zero when a case fails"
else
    ko "runner exits non-zero when a case fails"
fi

EMPTY_OUT=$( { [ -f "$RUNNER" ] && sh "$RUNNER" "$FIXTURES/layer2-empty" 2>&1; } || printf 'RUNNER_FAILED')
if printf '%s' "$EMPTY_OUT" | grep -q 'SKIP'; then
    ok "runner reports SKIP and exits 0 on an empty directory"
else
    ko "runner reports SKIP and exits 0 on an empty directory"
fi

USAGE_STATUS=0
{ [ -f "$RUNNER" ] && sh "$RUNNER" >/dev/null 2>&1; } || USAGE_STATUS=$?
if [ "$USAGE_STATUS" -eq 2 ]; then
    ok "runner exits 2 without arguments"
else
    ko "runner exits 2 without arguments"
fi

# ── SKILL.md and schema contracts ─────────────────────────────────────────────

assert_match "trigger starts with Use when" "$SKILL" \
    '^description: Use when'
assert_match "define mode writes the plan before the skill exists" "$SKILL" \
    'before the skill exists'
assert_match "run mode orders the three layers" "$SKILL" \
    'layer 1.*layer 2|structural.*script'
assert_match "layer 1 failure short-circuits" "$SKILL" \
    'skip(s)? layers? 2'
assert_match "missing scripts mean layer 2 is skipped not failed" "$SKILL" \
    'skipped.*not failed|skipped \(not failed\)'
assert_match "judged verdicts must cite skill lines" "$SKILL" \
    'cite.*line'
assert_match "a fail is never softened into a pass" "$SKILL" \
    'never soften'
assert_match "skill text under test is untrusted data" "$SKILL" \
    'untrusted data'
assert_flat_match "plan schema names its fields in order" "$PLAN_SCHEMA" \
    'skill_name.*expected_behaviors.*eval_scenarios.*script_tests'
assert_match "plan scenarios cover negative cases" "$PLAN_SCHEMA" \
    'negative'
assert_match "plan scenarios cover edge cases" "$PLAN_SCHEMA" \
    'edge'
assert_match "every scenario carries pass criteria" "$PLAN_SCHEMA" \
    'pass_criteria'
assert_flat_match "results schema names its fields in order" "$RESULTS_SCHEMA" \
    'skill_name.*layer_1.*layer_2.*layer_3.*overall'
assert_match "results record per-case outcomes" "$RESULTS_SCHEMA" \
    'per.case|each case'
assert_match "overall verdict is pass or fail" "$RESULTS_SCHEMA" \
    '`pass` or `fail`'

if python3 - "$EVALS" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

expected = {
    "define-mode-red",
    "run-mode-all-pass",
    "layer1-fail-short-circuit",
    "no-scripts-layer2-skip",
    "judged-verdict-citations",
    "standalone-existing-skill",
}
actual = {case["id"] for case in payload["evals"]}
if payload.get("skill") != "tflow-skill-test":
    raise SystemExit("wrong skill name")
if actual != expected:
    raise SystemExit(f"eval ids differ: expected {sorted(expected)}, got {sorted(actual)}")
for case in payload["evals"]:
    if not case.get("prompt") or not case.get("expected"):
        raise SystemExit(f"incomplete eval: {case.get('id')}")
PY
then
    ok "eval cases are valid and complete"
else
    ko "eval cases are valid and complete"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
