#!/bin/sh
# run-tests.sh — POSIX sh test runner for tflow-skill-creator scripts
# Usage: sh run-tests.sh
# Runs validate.sh fixtures and script contract tests.
# Exits 0 if all tests pass; exits 1 if any test fails.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"
INIT="$SCRIPT_DIR/init.sh"
IMPROVE="$SCRIPT_DIR/improve.sh"
PACKAGE="$SCRIPT_DIR/package.sh"
FIXTURES="$SCRIPT_DIR/fixtures"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tflow-tests.XXXXXX")
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT HUP INT TERM

pass() {
    NAME="$1"
    printf 'PASS: %s\n' "$NAME"
    PASS=$((PASS + 1))
}

fail() {
    NAME="$1"
    MSG="$2"
    printf 'FAIL: %s (%s)\n' "$NAME" "$MSG" >&2
    FAIL=$((FAIL + 1))
}

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

assert_file() {
    NAME="$1"
    PATH_TO_CHECK="$2"

    if [ -f "$PATH_TO_CHECK" ]; then
        pass "$NAME"
    else
        fail "$NAME" "missing file $PATH_TO_CHECK"
    fi
}

assert_dir() {
    NAME="$1"
    PATH_TO_CHECK="$2"

    if [ -d "$PATH_TO_CHECK" ]; then
        pass "$NAME"
    else
        fail "$NAME" "missing directory $PATH_TO_CHECK"
    fi
}

assert_missing() {
    NAME="$1"
    PATH_TO_CHECK="$2"

    if [ ! -e "$PATH_TO_CHECK" ]; then
        pass "$NAME"
    else
        fail "$NAME" "unexpected path exists: $PATH_TO_CHECK"
    fi
}

assert_grep() {
    NAME="$1"
    PATTERN="$2"
    PATH_TO_CHECK="$3"

    if grep -q "$PATTERN" "$PATH_TO_CHECK"; then
        pass "$NAME"
    else
        fail "$NAME" "pattern not found: $PATTERN"
    fi
}

assert_not_grep() {
    NAME="$1"
    PATTERN="$2"
    PATH_TO_CHECK="$3"

    if grep -q "$PATTERN" "$PATH_TO_CHECK"; then
        fail "$NAME" "unexpected pattern found: $PATTERN"
    else
        pass "$NAME"
    fi
}

run_static_script_tests() {
    for script in "$VALIDATE" "$INIT" "$IMPROVE" "$PACKAGE"; do
        script_name="$(basename "$script")"
        run_cmd_test "syntax $script_name" 0 sh -n "$script"
        assert_grep "$script_name uses set -eu" '^set -eu$' "$script"
        if grep -Eq '^[[:space:]]*(\[\[|local[[:space:]]|declare[[:space:]]+-a)' "$script"; then
            fail "$script_name has no bash-only syntax" "found bash-only construct"
        else
            pass "$script_name has no bash-only syntax"
        fi
    done
}

run_script_contract_tests() {
    INIT_ROOT="$TMP_ROOT/init-root"
    mkdir -p "$INIT_ROOT"

    run_cmd_test "init valid-skill" 0 sh "$INIT" valid-skill "$INIT_ROOT"
    assert_file "init creates SKILL.md" "$INIT_ROOT/skills/valid-skill/SKILL.md"
    assert_dir "init creates scripts dir" "$INIT_ROOT/skills/valid-skill/scripts"
    assert_dir "init creates references dir" "$INIT_ROOT/skills/valid-skill/references"
    assert_dir "init creates assets dir" "$INIT_ROOT/skills/valid-skill/assets"
    run_cmd_test "init scaffold validates" 0 sh "$VALIDATE" "$INIT_ROOT/skills/valid-skill"
    assert_grep "scaffold compatibility is scalar" \
        '^compatibility: Agent Skills specification v1 compatible\.$' \
        "$INIT_ROOT/skills/valid-skill/SKILL.md"
    assert_grep "scaffold metadata value is string" \
        '^  tflow_scaffold: "true"$' \
        "$INIT_ROOT/skills/valid-skill/SKILL.md"
    assert_not_grep "scaffold omits nonexistent local validator" \
        'sh scripts/validate\.sh \.' \
        "$INIT_ROOT/skills/valid-skill/SKILL.md"
    assert_grep "package has direct symlink defense" \
        'symbolic links are not portable package input' \
        "$PACKAGE"
    run_cmd_test "init rejects invalid name" 1 sh "$INIT" InvalidName "$TMP_ROOT"
    run_cmd_test "init refuses overwrite" 1 sh "$INIT" valid-skill "$INIT_ROOT"

    run_cmd_test "validate rejects multiple targets" 2 sh "$VALIDATE" \
        "$FIXTURES/fail-bad-name" "$FIXTURES/pass-well-formed"
    run_cmd_test "validate rejects duplicate quiet option" 2 sh "$VALIDATE" \
        --quiet --quiet "$FIXTURES/pass-well-formed"

    BODY_RULE_DIR="$TMP_ROOT/body-horizontal-rules"
    mkdir -p "$BODY_RULE_DIR"
    awk '
        BEGIN { delimiters = 0; replacements = 0 }
        /^---$/ && delimiters < 2 {
            delimiters++
            print
            next
        }
        delimiters == 2 && replacements < 2 && /^Line [0-9]+ of body content\.$/ {
            print "---"
            replacements++
            next
        }
        { print }
    ' "$FIXTURES/fail-body-too-long/SKILL.md" > "$BODY_RULE_DIR/SKILL.md"
    sed 's/name: fail-body-too-long/name: body-horizontal-rules/' \
        "$BODY_RULE_DIR/SKILL.md" > "$TMP_ROOT/body-horizontal-rules.md"
    mv "$TMP_ROOT/body-horizontal-rules.md" "$BODY_RULE_DIR/SKILL.md"
    run_cmd_test "body horizontal rules still count" 1 sh "$VALIDATE" "$BODY_RULE_DIR"

    SYMLINK_DIR="$TMP_ROOT/symlink-skill"
    cp -R "$FIXTURES/pass-well-formed" "$SYMLINK_DIR"
    sed 's/name: pass-well-formed/name: symlink-skill/' \
        "$SYMLINK_DIR/SKILL.md" > "$TMP_ROOT/symlink-skill.md"
    mv "$TMP_ROOT/symlink-skill.md" "$SYMLINK_DIR/SKILL.md"
    printf 'outside\n' > "$TMP_ROOT/outside.txt"
    ln -s "$TMP_ROOT/outside.txt" "$SYMLINK_DIR/external-link"
    run_cmd_test "validate rejects symlink" 1 sh "$VALIDATE" "$SYMLINK_DIR"

    # name-dir-match must resolve the target to a real directory name so a
    # `.` argument (or the bare default) run from inside a skill dir compares
    # against the actual basename, not "." (basename of ".").
    DOT_DIR="$TMP_ROOT/pass-well-formed"
    cp -R "$FIXTURES/pass-well-formed" "$DOT_DIR"
    if (cd "$DOT_DIR" && sh "$VALIDATE" . >/dev/null 2>&1); then
        pass "validate accepts dot invocation from skill dir"
    else
        fail "validate accepts dot invocation from skill dir" "exit non-zero"
    fi
    if (cd "$DOT_DIR" && sh "$VALIDATE" >/dev/null 2>&1); then
        pass "validate accepts bare invocation from skill dir"
    else
        fail "validate accepts bare invocation from skill dir" "exit non-zero"
    fi

    run_cmd_test "improve writes report" 0 sh "$IMPROVE" "$INIT_ROOT/skills/valid-skill"
    assert_file "improve report exists" "$INIT_ROOT/skills/valid-skill/.skill-improvement.md"
    assert_grep "improve report has validation status" "Validation" "$INIT_ROOT/skills/valid-skill/.skill-improvement.md"
    assert_grep "improve report has scaffold comparison" "Scaffold Comparison" "$INIT_ROOT/skills/valid-skill/.skill-improvement.md"
    assert_grep "improve report has placeholder checks" "Placeholder" "$INIT_ROOT/skills/valid-skill/.skill-improvement.md"
    assert_grep "improve report has testing checklist" "Testing Checklist" "$INIT_ROOT/skills/valid-skill/.skill-improvement.md"

    # improve.sh must strip a quoted `name:` the same way validate.sh does, so a
    # quoted-name skill still gets a real scaffold diff instead of the
    # non-portable-name skip.
    QUOTED_DIR="$TMP_ROOT/pass-quoted-scalars"
    cp -R "$FIXTURES/pass-quoted-scalars" "$QUOTED_DIR"
    sh "$IMPROVE" "$QUOTED_DIR" >/dev/null 2>&1 || true
    assert_not_grep "improve resolves quoted skill name" \
        'non-portable skill name' "$QUOTED_DIR/.skill-improvement.md"

    run_cmd_test "package refuses unchecked evidence" 1 sh "$PACKAGE" "$INIT_ROOT/skills/valid-skill"
    sed '/^- \[[ x]\]/d' \
        "$INIT_ROOT/skills/valid-skill/.skill-improvement.md" \
        > "$TMP_ROOT/improvement-empty.md"
    mv "$TMP_ROOT/improvement-empty.md" \
        "$INIT_ROOT/skills/valid-skill/.skill-improvement.md"
    run_cmd_test "package refuses deleted evidence" 1 sh "$PACKAGE" \
        "$INIT_ROOT/skills/valid-skill"

    sh "$IMPROVE" "$INIT_ROOT/skills/valid-skill" >/dev/null
    sed 's/- \[ \]/- [x]/g' "$INIT_ROOT/skills/valid-skill/.skill-improvement.md" > "$TMP_ROOT/improvement-complete.md"
    mv "$TMP_ROOT/improvement-complete.md" "$INIT_ROOT/skills/valid-skill/.skill-improvement.md"

    printf 'outside\n' > "$TMP_ROOT/package-outside.txt"
    ln -s "$TMP_ROOT/package-outside.txt" \
        "$INIT_ROOT/skills/valid-skill/assets/external-link"
    run_cmd_test "package refuses symlink" 1 sh "$PACKAGE" \
        "$INIT_ROOT/skills/valid-skill"
    rm "$INIT_ROOT/skills/valid-skill/assets/external-link"

    mkdir -p "$INIT_ROOT/skills/valid-skill/dist/old-package"
    printf 'stale artifact\n' > "$INIT_ROOT/skills/valid-skill/dist/old-package/stale.txt"
    run_cmd_test "package creates artifacts" 0 sh "$PACKAGE" "$INIT_ROOT/skills/valid-skill"
    assert_dir "package creates inspectable dist" "$INIT_ROOT/skills/valid-skill/dist/valid-skill"
    assert_file "package creates archive" "$INIT_ROOT/skills/valid-skill/dist/valid-skill.tar.gz"
    assert_missing "package excludes improvement evidence" "$INIT_ROOT/skills/valid-skill/dist/valid-skill/.skill-improvement.md"
    assert_missing "package excludes nested dist output" "$INIT_ROOT/skills/valid-skill/dist/valid-skill/dist"

    FAIL_ROOT="$TMP_ROOT/fail-root"
    mkdir -p "$FAIL_ROOT/skills"
    cp -R "$FIXTURES/fail-bad-name" "$FAIL_ROOT/skills/fail-bad-name"
    printf '%s\n' '- [x] Validation reviewed' > "$FAIL_ROOT/skills/fail-bad-name/.skill-improvement.md"
    run_cmd_test "package refuses invalid skill" 1 sh "$PACKAGE" "$FAIL_ROOT/skills/fail-bad-name"
    if [ ! -e "$FAIL_ROOT/skills/fail-bad-name/dist" ]; then
        pass "package leaves no artifacts after validation failure"
    else
        fail "package leaves no artifacts after validation failure" "dist exists"
    fi
}

run_real_skill_validation_tests() {
    # Every shipped skill must pass the shipped validate.sh cleanly — including
    # the Rule-D lint gate when shellcheck is present. Regression guard for the
    # lint false positives that made the installer self-check report
    # FAIL tflow-skill-creator in v0.1.0. On failure, surface validate.sh's
    # output and the linter version so cross-environment differences are
    # diagnosable instead of an opaque "got 1".
    SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
    for skill in tflow-research tflow-skill-creator tflow-skill-factory \
        tflow-skill-idea tflow-skill-test tflow-prompt tflow-gateway; do
        [ -d "$SKILLS_DIR/$skill" ] || continue
        if sh "$VALIDATE" "$SKILLS_DIR/$skill" > "$TMP_ROOT/vsc.txt" 2>&1; then
            pass "shipped skill validates: $skill (exit 0 as expected)"
        else
            fail "shipped skill validates: $skill" "validate.sh exited non-zero"
            command -v shellcheck >/dev/null 2>&1 && \
                shellcheck --version 2>&1 | sed 's/^/    [diag] shellcheck /'
            grep -vE '^PASS ' "$TMP_ROOT/vsc.txt" | sed 's/^/    [diag] /'
        fi
    done
}

run_static_script_tests

for fixture_dir in "$FIXTURES"/*/; do
    name="$(basename "$fixture_dir")"
    case "$name" in
        pass-*) run_test "$fixture_dir" 0 ;;
        fail-*) run_test "$fixture_dir" 1 ;;
        *)      printf 'SKIP: %s (no pass-/fail- prefix)\n' "$name" >&2 ;;
    esac
done

run_script_contract_tests
run_real_skill_validation_tests

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
