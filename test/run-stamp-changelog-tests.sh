#!/bin/sh
# run-stamp-changelog-tests.sh — POSIX sh behavior/idempotency/integration test
# for scripts/stamp-changelog.sh.
# Usage: sh test/run-stamp-changelog-tests.sh
# Each case runs the real helper inside an isolated `mktemp -d` work dir against a
# throwaway package.json + CHANGELOG.md, so the repo's real files are NEVER touched.
# Mirrors the harness idiom of test/run-installer-tests.sh (self-locate, mktemp temp
# root, cleanup trap, pass/fail counters, `N passed, M failed` footer).
# Exits 0 if all assertions pass; exits 1 if any fail.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HELPER="$REPO_ROOT/scripts/stamp-changelog.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tflow-stamp-tests.XXXXXX")
PASS=0
FAIL=0

# shellcheck disable=SC2329  # invoked indirectly via the EXIT/signal trap below.
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

# Assert a file matches an extended-regex (grep -E) pattern.
assert_grep() {
    if grep -Eq "$2" "$3"; then
        pass "$1"
    else
        fail "$1" "pattern not found: $2"
    fi
}

# Assert a file does NOT match a pattern.
assert_not_grep() {
    if grep -Eq "$2" "$3"; then
        fail "$1" "unexpected pattern found: $2"
    else
        pass "$1"
    fi
}

# Write a throwaway package.json with the given version into $1.
write_pkg() {
    printf '{ "name": "fixture", "version": "%s" }\n' "$2" >"$1/package.json"
}

# Extract a CHANGELOG section body by literal heading prefix (metachar-safe via
# awk index), using the SAME boundary logic release.yml uses. Prints the body.
section_body() {
    awk -v hdr="$2" '
        index($0, hdr) == 1 {f=1; next}
        f && /^## \[/ {exit}
        f {print}
    ' "$1"
}

# Run the helper inside a work dir (cwd-relative), capturing exit code without
# aborting the suite under set -e. Sets RC.
run_helper() {
    if (cd "$1" && sh "$HELPER") >"$1/out.log" 2>&1; then
        RC=0
    else
        RC=$?
    fi
}

ISO='[0-9]{4}-[0-9]{2}-[0-9]{2}'

# ── Case 1: rename + re-seed + section boundaries + older-section preservation ──
D1="$TMP_ROOT/case1"
mkdir -p "$D1"
write_pkg "$D1" "9.9.9"
cat >"$D1/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

### Added
- MARKER_UNREL new thing

## [0.0.1] - 2026-01-01

### Added
- MARKER_OLD legacy thing
EOF
run_helper "$D1"
if [ "$RC" -eq 0 ]; then
    pass "case1 helper exits 0"
else
    fail "case1 helper exits 0" "got exit $RC"
fi
assert_grep "case1 dated 9.9.9 heading" "^## \[9\.9\.9\] - $ISO\$" "$D1/CHANGELOG.md"
assert_grep "case1 fresh Unreleased re-seeded" "^## \[Unreleased\]\$" "$D1/CHANGELOG.md"
# Re-seeded Unreleased body must be EMPTY (no non-whitespace).
B1="$(section_body "$D1/CHANGELOG.md" "## [Unreleased]")"
if printf '%s' "$B1" | grep -q '[^[:space:]]'; then
    fail "case1 re-seeded Unreleased empty" "Unreleased body is non-empty"
else
    pass "case1 re-seeded Unreleased empty"
fi
# Original Unreleased body line now sits inside the 9.9.9 section.
S99="$(section_body "$D1/CHANGELOG.md" "## [9.9.9]")"
if printf '%s' "$S99" | grep -q 'MARKER_UNREL'; then
    pass "case1 original body moved into 9.9.9 section"
else
    fail "case1 original body moved into 9.9.9 section" "MARKER_UNREL not in 9.9.9 section"
fi
assert_grep "case1 older 0.0.1 heading preserved" "^## \[0\.0\.1\] - 2026-01-01\$" "$D1/CHANGELOG.md"
assert_grep "case1 older 0.0.1 body preserved" "MARKER_OLD" "$D1/CHANGELOG.md"

# ── Case 2: idempotency — a second run is a no-op, exactly one 9.9.9 heading ────
run_helper "$D1"
if [ "$RC" -eq 0 ]; then
    pass "case2 second run exits 0"
else
    fail "case2 second run exits 0" "got exit $RC"
fi
COUNT=$(grep -c '^## \[9\.9\.9\]' "$D1/CHANGELOG.md" || true)
if [ "$COUNT" -eq 1 ]; then
    pass "case2 exactly one 9.9.9 heading after re-run"
else
    fail "case2 exactly one 9.9.9 heading after re-run" "found $COUNT headings"
fi

# ── Case 3: missing [Unreleased] fails loud ────────────────────────────────────
D3="$TMP_ROOT/case3"
mkdir -p "$D3"
write_pkg "$D3" "7.7.7"
cat >"$D3/CHANGELOG.md" <<'EOF'
# Changelog

## [0.0.1] - 2026-01-01

### Added
- something
EOF
run_helper "$D3"
if [ "$RC" -ne 0 ]; then
    pass "case3 missing Unreleased exits non-zero"
else
    fail "case3 missing Unreleased exits non-zero" "expected non-zero, got 0"
fi
assert_not_grep "case3 did not stamp 7.7.7" "^## \[7\.7\.7\]" "$D3/CHANGELOG.md"

# ── Case 4: first-release 0.1.0 stamp produces the exact heading ───────────────
D4="$TMP_ROOT/case4"
mkdir -p "$D4"
write_pkg "$D4" "0.1.0"
cat >"$D4/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

### Added
- first release content
EOF
run_helper "$D4"
if [ "$RC" -eq 0 ]; then
    pass "case4 helper exits 0"
else
    fail "case4 helper exits 0" "got exit $RC"
fi
assert_grep "case4 exact 0.1.0 heading" "^## \[0\.1\.0\] - $ISO\$" "$D4/CHANGELOG.md"

# ── Case 5: empty [Unreleased] body fails loud, no rewrite ─────────────────────
D5="$TMP_ROOT/case5"
mkdir -p "$D5"
write_pkg "$D5" "8.8.8"
cat >"$D5/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

## [0.0.1] - 2026-01-01

### Added
- something
EOF
run_helper "$D5"
if [ "$RC" -ne 0 ]; then
    pass "case5 empty Unreleased body exits non-zero"
else
    fail "case5 empty Unreleased body exits non-zero" "expected non-zero, got 0"
fi
assert_not_grep "case5 did not stamp 8.8.8" "^## \[8\.8\.8\]" "$D5/CHANGELOG.md"

# ── Case 6: real `npm version 0.1.0 --allow-same-version` integration ──────────
if command -v npm >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
    R6="$TMP_ROOT/case6"
    mkdir -p "$R6/scripts"
    cp "$HELPER" "$R6/scripts/stamp-changelog.sh"
    # Fixture manifest is intentionally non-canonical (inline scripts object): a
    # same-version `npm version 0.1.0 --allow-same-version` re-serializes
    # package.json into npm's canonical multi-line form, which is a real diff, so
    # the tagged commit carries package.json alongside the stamped CHANGELOG.md
    # (mirrors npm normalizing a hand-authored manifest at release time).
    cat >"$R6/package.json" <<'EOF'
{ "name": "fixture-int", "version": "0.1.0", "scripts": { "version": "sh scripts/stamp-changelog.sh && git add CHANGELOG.md" } }
EOF
    cat >"$R6/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

### Added
- INTEGRATION_MARKER end-to-end content
EOF
    (
        cd "$R6" &&
            git init -q &&
            git config user.email "test@example.com" &&
            git config user.name "tflow test" &&
            git config commit.gpgsign false &&
            git add -A &&
            git commit -q -m "init" &&
            npm version 0.1.0 --allow-same-version >/dev/null 2>&1
    ) >"$R6.log" 2>&1
    INT_RC=$?
    if [ "$INT_RC" -eq 0 ]; then
        pass "case6 npm version lifecycle ran"
    else
        fail "case6 npm version lifecycle ran" "exit $INT_RC (see $R6.log)"
    fi
    # (a) tag v0.1.0 exists
    if [ -n "$(git -C "$R6" tag -l v0.1.0)" ]; then
        pass "case6 tag v0.1.0 created"
    else
        fail "case6 tag v0.1.0 created" "no v0.1.0 tag"
    fi
    # (b) tagged commit carries BOTH package.json and CHANGELOG.md. Use diff-tree
    # (not `git show`, whose annotated-tag header pollutes --name-only output).
    TAGGED_FILES="$(git -C "$R6" diff-tree --no-commit-id --name-only -r v0.1.0 2>/dev/null)"
    if printf '%s\n' "$TAGGED_FILES" | grep -q '^package.json$' &&
        printf '%s\n' "$TAGGED_FILES" | grep -q '^CHANGELOG.md$'; then
        pass "case6 tagged commit carries package.json + CHANGELOG.md"
    else
        fail "case6 tagged commit carries package.json + CHANGELOG.md" "files: $TAGGED_FILES"
    fi
    # (c) stamped [0.1.0] section is NON-EMPTY (release.yml awk extraction)
    S6="$(section_body "$R6/CHANGELOG.md" "## [0.1.0]")"
    if printf '%s' "$S6" | grep -q 'INTEGRATION_MARKER'; then
        pass "case6 stamped 0.1.0 section non-empty"
    else
        fail "case6 stamped 0.1.0 section non-empty" "marker missing from 0.1.0 section"
    fi
    # (d) re-seeded [Unreleased] section body is EMPTY
    U6="$(section_body "$R6/CHANGELOG.md" "## [Unreleased]")"
    if printf '%s' "$U6" | grep -q '[^[:space:]]'; then
        fail "case6 re-seeded Unreleased empty" "Unreleased body is non-empty"
    else
        pass "case6 re-seeded Unreleased empty"
    fi
else
    printf 'WARN: npm and/or git not found — SKIPPING case6 real npm version integration\n' >&2
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
