#!/bin/sh
# run-layer2.sh — execute deterministic layer-2 test cases for an Agent Skill
# Usage: sh run-layer2.sh <tests-dir>
#   Runs every *.test.sh file in <tests-dir> with sh. A case passes iff it
#   exits 0.
# Exit:  0 = all cases pass (or none found: SKIP); 1 = any case fails;
#        2 = usage error
set -eu

usage() {
    printf 'Usage: sh run-layer2.sh <tests-dir>\n' >&2
}

if [ "$#" -ne 1 ]; then
    usage
    exit 2
fi

TESTS_DIR="$1"
if [ ! -d "$TESTS_DIR" ]; then
    printf 'ERROR: not a directory: %s\n' "$TESTS_DIR" >&2
    usage
    exit 2
fi

PASS=0
FAIL=0
FOUND=0

for case_file in "$TESTS_DIR"/*.test.sh; do
    [ -f "$case_file" ] || continue
    FOUND=1
    if sh "$case_file"; then
        printf 'PASS: %s\n' "$(basename "$case_file")"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s\n' "$(basename "$case_file")" >&2
        FAIL=$((FAIL + 1))
    fi
done

if [ "$FOUND" -eq 0 ]; then
    printf 'SKIP: no *.test.sh files in %s\n' "$TESTS_DIR"
    exit 0
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
