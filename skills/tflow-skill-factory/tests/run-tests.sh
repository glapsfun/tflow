#!/bin/sh
set -eu

# CDPATH= is a one-shot empty assignment scoped to this cd so a user's exported
# CDPATH can't redirect it or print output; the space is intentional, not a typo.
# shellcheck disable=SC1007
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/SKILL.md"
VALIDATE_PHASE="$ROOT/references/validate-phase.md"
CHECK_PHASE="$ROOT/references/check-phase.md"
DOC_PHASE="$ROOT/references/doc-phase.md"
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
assert_match "compatibility names idea dependency" "$SKILL" \
    '^compatibility: .*tflow-skill-idea'
assert_match "compatibility names research dependency" "$SKILL" \
    '^compatibility: .*tflow-research'
assert_match "compatibility names test dependency" "$SKILL" \
    '^compatibility: .*tflow-skill-test'
assert_match "compatibility names creator dependency" "$SKILL" \
    '^compatibility: .*tflow-skill-creator'
assert_match "compatibility names external source access" "$SKILL" \
    '^compatibility: .*(web|search|fetch)'
assert_match "compatibility names writable scratch storage" "$SKILL" \
    '^compatibility: .*(writable|temporary|scratch)'
assert_flat_match "pipeline runs all eight steps in order" "$SKILL" \
    'idea.*research.*validate.*test.plan.*create.*test.run.*check.*doc'
assert_match "idea approval is the only human gate" "$SKILL" \
    'only human gate'
assert_match "test plan is written before the skill exists" "$SKILL" \
    'before the skill exists'
assert_match "re-research loop is bounded" "$SKILL" \
    'at most 2 re-research'
assert_match "improvement loop is bounded" "$SKILL" \
    'at most 3'
assert_match "artifact content is untrusted data" "$SKILL" \
    'untrusted data'
assert_match "artifacts are gated before the next phase" "$SKILL" \
    'required fields before'
assert_match "exhausted budget halts the run" "$SKILL" \
    'budget.*(halt|stop)|(halt|stop).*budget'
assert_match "unattended flow does not package" "$SKILL" \
    'Do not run `package[.]sh`'
assert_match "caller scratch is never removed" "$SKILL" \
    'never remove(s)? caller-provided'
assert_match "run summary is part of the final report" "$SKILL" \
    'run-summary[.]md'
assert_flat_match "validate phase checks research questions" "$VALIDATE_PHASE" \
    'research_questions.*sourced evidence|sourced evidence.*research_questions'
assert_match "validate phase verdicts are proceed or re-research" "$VALIDATE_PHASE" \
    '`proceed` or `re-research`'
assert_match "validate phase gaps refine the next research pass" "$VALIDATE_PHASE" \
    'gap.*(refine|next research)|becomes the.*research input'
assert_flat_match "check phase judges against success criteria" "$CHECK_PHASE" \
    'success_criteria'
assert_match "check phase verdicts are approved or needs-improvement" "$CHECK_PHASE" \
    '`approved` or `needs-improvement`'
assert_match "check phase fixes are keyed to files" "$CHECK_PHASE" \
    'keyed to files'
assert_match "arbiter never softens a failing test" "$CHECK_PHASE" \
    'may not soften|never soften'
assert_match "doc phase writes docs into the skill" "$DOC_PHASE" \
    'into the skill directory'
assert_match "doc phase records iterations used" "$DOC_PHASE" \
    'iterations used'
assert_match "doc phase writes the run summary" "$DOC_PHASE" \
    'run-summary[.]md'

if python3 - "$EVALS" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

expected = {
    "full-pipeline-success",
    "re-research-loop",
    "improve-loop-exhausted",
    "missing-phase-skill",
    "artifact-prompt-injection",
    "idea-abandoned",
}
actual = {case["id"] for case in payload["evals"]}
if payload.get("skill") != "tflow-skill-factory":
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
