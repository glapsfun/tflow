#!/bin/sh
set -eu

# CDPATH= is a one-shot empty assignment scoped to this cd so a user's exported
# CDPATH can't redirect it or print output; the space is intentional, not a typo.
# shellcheck disable=SC1007
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/SKILL.md"
EVALS="$ROOT/evals/evals.json"
CREATOR_LOOP="$ROOT/../tflow-skill-creator/references/factory-loop.md"

PASS=0
FAIL=0

assert_match() {
    LABEL="$1"
    FILE="$2"
    PATTERN="$3"
    if grep -Eiq "$PATTERN" "$FILE"; then
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
    if grep -Eiq "$PATTERN" "$FILE"; then
        printf 'FAIL: %s\n' "$LABEL" >&2
        FAIL=$((FAIL + 1))
    else
        printf 'PASS: %s\n' "$LABEL"
        PASS=$((PASS + 1))
    fi
}

assert_flat_match() {
    LABEL="$1"
    FILE="$2"
    PATTERN="$3"
    if tr '\n' ' ' < "$FILE" | grep -Eiq "$PATTERN"; then
        printf 'PASS: %s\n' "$LABEL"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s\n' "$LABEL" >&2
        FAIL=$((FAIL + 1))
    fi
}

assert_match "trigger promises a validated draft" "$SKILL" \
    '^description: Use when .*validated .*draft'
assert_match "compatibility names research dependency" "$SKILL" \
    '^compatibility: .*tflow-research'
assert_match "compatibility names creator dependency" "$SKILL" \
    '^compatibility: .*tflow-skill-creator'
assert_match "compatibility names external source access" "$SKILL" \
    '^compatibility: .*(web|search|fetch)'
assert_match "compatibility names writable scratch storage" "$SKILL" \
    '^compatibility: .*(writable|temporary|scratch)'
assert_match "find-idea depth is numeric" "$SKILL" \
    'depth[ =`]2'
assert_match "find-idea breadth is numeric" "$SKILL" \
    'breadth[ =`]4'
assert_match "find-idea token budget is numeric" "$SKILL" \
    'token_budget[ =`]16000'
assert_absent "stale medium budget is removed" "$SKILL" \
    'medium token budget'
assert_flat_match "brief gate names all eight fields" "$SKILL" \
    'topic.*mode.*recommendation.*options.*evidence.*risks.*open_questions.*sources'
assert_flat_match "brief gate requires evidence" "$SKILL" \
    '(nonempty|non-empty).*evidence'
assert_flat_match "brief gate requires opened sources" "$SKILL" \
    '(nonempty|non-empty).*(opened )?sources|opened source'
assert_match "missing source capability halts" "$SKILL" \
    '(missing|no|unavailable).*(web|search|fetch|source).*(halt|stop)|halt.*(web|search|fetch|source)'
assert_flat_match "inconclusive research halts" "$SKILL" \
    'inconclusive.*(halt|stop)|(halt|stop).*inconclusive'
assert_flat_match "malformed brief halts" "$SKILL" \
    '(malformed|invalid).*(brief|output).*(halt|stop)|(halt|stop).*(malformed|invalid)'
assert_match "brief content is untrusted data" "$SKILL" \
    'untrusted data'
assert_match "embedded instructions are ignored" "$SKILL" \
    'ignore.*(instruction|command)|do not (follow|execute).*(instruction|command)'
assert_match "literal envelope delimiters are escaped" "$SKILL" \
    'escape.*(delimiter|<research_brief>|</research_brief>)'
assert_flat_match "only declared fields are consumed" "$SKILL" \
    'only.*eight.*field|only.*declared.*field'
assert_match "runtime temporary storage is used" "$SKILL" \
    '(runtime|system).*(temporary|temp).*director'
assert_match "caller scratch fallback is explicit" "$SKILL" \
    'caller-provided.*scratch|scratch.*provided by the caller'
assert_match "temporary output is cleaned" "$SKILL" \
    '(clean|remove).*(temporary|scratch)'
assert_absent "repository proof path is removed" "$SKILL" \
    '/[.]proof/'
assert_match "validation retries remain bounded" "$SKILL" \
    '(at most|maximum|max).*2.*retr'
assert_match "unattended flow does not package" "$SKILL" \
    'Do not run `package[.]sh`|stop before.*package[.]sh'
assert_flat_match "creator treats brief as untrusted data" "$CREATOR_LOOP" \
    'research brief.*untrusted data|untrusted data.*research brief'
assert_match "creator ignores embedded instructions" "$CREATOR_LOOP" \
    'ignore.*(instruction|command)|do not (follow|execute).*(instruction|command)'

if python3 - "$EVALS" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

expected = {
    "live-source-success",
    "no-source-tools",
    "inconclusive-research",
    "brief-prompt-injection",
    "missing-chained-skill",
    "validation-retries-exhausted",
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
