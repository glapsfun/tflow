#!/bin/sh
# run-tests.sh — POSIX sh test runner for tflow-gateway scripts
# Usage: sh run-tests.sh
# Fixture convention: fixtures/pass-discover-* and fail-discover-* are
# skills-roots driven through discover-skills.sh; pass-artifacts-* and
# fail-artifacts-* are run-dirs driven through validate-artifacts.sh with
# the artifact names listed in the fixture's .args file. pass-* must exit
# 0, fail-* must exit 1.
# Exits 0 if all tests pass; exits 1 if any test fails.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DISCOVER="$SCRIPT_DIR/discover-skills.sh"
ARTIFACTS="$SCRIPT_DIR/validate-artifacts.sh"
FIXTURES="$SCRIPT_DIR/fixtures"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tflow-gateway-tests.XXXXXX")
TAB=$(printf '\t')
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT HUP INT TERM

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

fail() {
    printf 'FAIL: %s (%s)\n' "$1" "$2" >&2
    FAIL=$((FAIL + 1))
}

run_cmd_test() {
    NAME="$1"
    EXPECTED="$2"
    shift 2

    if "$@" >/dev/null 2>&1; then
        ACTUAL=0
    else
        ACTUAL=$?
    fi

    if [ "$ACTUAL" = "$EXPECTED" ]; then
        pass "$NAME (exit $EXPECTED as expected)"
    else
        fail "$NAME" "expected exit $EXPECTED, got $ACTUAL"
    fi
}

run_static_script_tests() {
    for script in "$DISCOVER" "$ARTIFACTS"; do
        [ -f "$script" ] || continue
        script_name="$(basename "$script")"
        run_cmd_test "syntax $script_name" 0 sh -n "$script"
        if grep -q '^set -eu$' "$script"; then
            pass "$script_name uses set -eu"
        else
            fail "$script_name uses set -eu" "missing set -eu"
        fi
        if grep -Eq '^[[:space:]]*(\[\[|local[[:space:]]|declare[[:space:]]+-a)' "$script"; then
            fail "$script_name has no bash-only syntax" "found bash-only construct"
        else
            pass "$script_name has no bash-only syntax"
        fi
    done
}

run_fixture_tests() {
    for fixture_dir in "$FIXTURES"/*/; do
        name="$(basename "$fixture_dir")"
        case "$name" in
            pass-discover-*) run_cmd_test "$name" 0 sh "$DISCOVER" "$fixture_dir" ;;
            fail-discover-*) run_cmd_test "$name" 1 sh "$DISCOVER" "$fixture_dir" ;;
            pass-artifacts-*|fail-artifacts-*)
                case "$name" in
                    pass-*) expected=0 ;;
                    *)      expected=1 ;;
                esac
                if [ ! -f "$fixture_dir/.args" ]; then
                    fail "$name" "fixture is missing its .args file"
                    continue
                fi
                ARGS=$(cat "$fixture_dir/.args")
                # Word-splitting is intentional: .args holds space-separated
                # artifact names, none of which contain whitespace.
                # shellcheck disable=SC2086
                run_cmd_test "$name" "$expected" sh "$ARTIFACTS" "$fixture_dir" $ARGS
                ;;
            *) printf 'SKIP: %s (no recognized prefix)\n' "$name" >&2 ;;
        esac
    done
}

run_discover_contract_tests() {
    run_cmd_test "discover rejects zero arguments" 2 sh "$DISCOVER"
    run_cmd_test "discover rejects missing root" 2 \
        sh "$DISCOVER" "$TMP_ROOT/does-not-exist"

    OUT="$TMP_ROOT/discover-out.txt"
    ERR="$TMP_ROOT/discover-err.txt"

    sh "$DISCOVER" "$FIXTURES/pass-discover-two-skills" > "$OUT"
    if grep -q "^tflow-alpha${TAB}Use when alpha" "$OUT" \
        && grep -q "^tflow-beta${TAB}Use when beta" "$OUT"; then
        pass "discover lists both tflow skills tab-separated, quotes stripped"
    else
        fail "discover lists both tflow skills tab-separated, quotes stripped" \
            "missing expected lines"
    fi
    if grep -q "^other-skill" "$OUT"; then
        fail "discover ignores non-tflow skills" "other-skill listed"
    else
        pass "discover ignores non-tflow skills"
    fi

    sh "$DISCOVER" "$FIXTURES/pass-discover-self-excluded" > "$OUT"
    if grep -q "^tflow-gateway" "$OUT"; then
        fail "discover excludes tflow-gateway" "gateway listed"
    else
        pass "discover excludes tflow-gateway"
    fi

    sh "$DISCOVER" "$FIXTURES/pass-discover-two-skills" \
        "$FIXTURES/pass-discover-two-skills" > "$OUT"
    COUNT=$(grep -c "^tflow-alpha${TAB}" "$OUT" || true)
    if [ "$COUNT" -eq 1 ]; then
        pass "discover dedupes skills across roots"
    else
        fail "discover dedupes skills across roots" "tflow-alpha listed $COUNT times"
    fi

    TAB_ROOT="$TMP_ROOT/tab-desc-root"
    mkdir -p "$TAB_ROOT/tflow-tabbed"
    printf -- '---\nname: tflow-tabbed\ndescription: Use when a\ttab lurks\n---\n' \
        > "$TAB_ROOT/tflow-tabbed/SKILL.md"
    sh "$DISCOVER" "$TAB_ROOT" > "$OUT"
    if grep -q "^tflow-tabbed${TAB}Use when a tab lurks\$" "$OUT"; then
        pass "discover flattens tabs inside descriptions"
    else
        fail "discover flattens tabs inside descriptions" "TSV contract broken"
    fi

    sh "$DISCOVER" "$FIXTURES/pass-discover-skips-malformed" > "$OUT" 2> "$ERR"
    if grep -q "^tflow-alpha${TAB}" "$OUT" \
        && ! grep -q '^tflow-broken' "$OUT" \
        && grep -q 'WARN' "$ERR"; then
        pass "discover skips malformed SKILL.md with warning"
    else
        fail "discover skips malformed SKILL.md with warning" "unexpected output"
    fi
}

run_artifacts_contract_tests() {
    [ -f "$ARTIFACTS" ] || return 0
    run_cmd_test "artifacts rejects zero artifact names" 2 \
        sh "$ARTIFACTS" "$FIXTURES/pass-artifacts-complete"
    run_cmd_test "artifacts rejects missing run dir" 2 \
        sh "$ARTIFACTS" "$TMP_ROOT/does-not-exist" enhanced-prompt.md
    run_cmd_test "artifacts accepts unknown non-empty artifact" 0 \
        sh "$ARTIFACTS" "$FIXTURES/pass-artifacts-complete" research-brief.md
    run_cmd_test "artifacts rejects path-separator artifact name" 1 \
        sh "$ARTIFACTS" "$FIXTURES/pass-artifacts-complete" \
        ../pass-artifacts-complete/research-brief.md
    run_cmd_test "artifacts rejects dot-prefixed artifact name" 1 \
        sh "$ARTIFACTS" "$FIXTURES/pass-artifacts-complete" .args
}

run_static_script_tests
run_fixture_tests
run_discover_contract_tests
run_artifacts_contract_tests

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
