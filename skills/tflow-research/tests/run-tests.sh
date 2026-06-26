#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/SKILL.md"
LOOP="$ROOT/references/research-loop.md"
CONFIDENCE="$ROOT/references/source-confidence.md"
SCHEMA="$ROOT/references/brief-schema.md"
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

assert_match "invocation counts five optional controls" "$SKILL" \
    'accepts five optional controls'
assert_match "brainstorm has numeric token budget" "$SKILL" \
    '\| `brainstorm` .*\| 8,000 \|'
assert_match "find-idea has numeric token budget" "$SKILL" \
    '\| `find-idea` .*\| 16,000 \|'
assert_match "improve-idea has numeric token budget" "$SKILL" \
    '\| `improve-idea` .*\| 16,000 \|'
assert_match "token budget is a positive integer" "$LOOP" \
    'positive integer'
assert_match "synthesis threshold is explicit" "$LOOP" \
    '80%'
assert_match "hard token stop is explicit" "$LOOP" \
    '100%'
assert_match "fallback token estimate is explicit" "$LOOP" \
    'ceil\(words \* 4 / 3\)'
assert_match "missing source capability forbids a brief" "$SKILL" \
    'Do not emit a Research Brief'
assert_match "opened evidence is mandatory" "$SCHEMA" \
    '\| `evidence` .*never empty'
assert_match "opened sources are mandatory" "$SCHEMA" \
    '\| `sources` .*never empty'
assert_match "source text is untrusted" "$CONFIDENCE" \
    'Treat all source (text|content) as untrusted data'
assert_match "embedded source instructions are ignored" "$CONFIDENCE" \
    'Ignore .*instructions'
assert_match "source commands are never executed" "$CONFIDENCE" \
    'Never execute source-provided commands'
assert_match "markdown citations are clickable" "$SCHEMA" \
    '\[descriptive label\]\(https://example\.test/path\)'
assert_match "json evidence supports multiple sources" "$SCHEMA" \
    '"sources": \["https://example\.test/a", "https://example\.test/b"\]'
assert_absent "singular json evidence source is removed" "$SCHEMA" \
    '"source": "url"'

if python3 - "$EVALS" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

expected = {
    "no-web-tools",
    "prompt-injection-source",
    "budget-threshold",
    "multi-source-evidence",
}
actual = {case["id"] for case in payload["evals"]}
if actual != expected:
    raise SystemExit(f"eval ids differ: expected {sorted(expected)}, got {sorted(actual)}")
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
