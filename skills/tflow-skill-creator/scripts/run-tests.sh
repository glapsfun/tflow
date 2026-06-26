#!/bin/sh
# run-tests.sh — POSIX sh test runner for validate.sh
# Usage: sh run-tests.sh
# Runs validate.sh against each fixture and asserts expected exit code.
# Exits 0 if all tests pass; exits 1 if any test fails.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"
FIXTURES="$SCRIPT_DIR/fixtures"
PASS=0
FAIL=0

run_test() {
    FIXTURE_DIR="$1"
    EXPECTED="$2"
    NAME="$(basename "$FIXTURE_DIR")"

    if sh "$VALIDATE" "$FIXTURE_DIR" >/dev/null 2>&1; then
        ACTUAL=0
    else
        ACTUAL=1
    fi

    if [ "$ACTUAL" = "$EXPECTED" ]; then
        printf 'PASS: %s (exit %s as expected)\n' "$NAME" "$EXPECTED"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s (expected exit %s, got %s)\n' "$NAME" "$EXPECTED" "$ACTUAL" >&2
        FAIL=$((FAIL + 1))
    fi
}

for fixture_dir in "$FIXTURES"/*/; do
    name="$(basename "$fixture_dir")"
    case "$name" in
        pass-*) run_test "$fixture_dir" 0 ;;
        fail-*) run_test "$fixture_dir" 1 ;;
        *)      printf 'SKIP: %s (no pass-/fail- prefix)\n' "$name" >&2 ;;
    esac
done

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
