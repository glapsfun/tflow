#!/bin/sh
# run-installer-tests.sh — POSIX sh end-to-end integration test for bin/tflow.
# Usage: sh test/run-installer-tests.sh
# Drives the real `node bin/tflow` CLI into throwaway temp projects and asserts the
# installer's full user-facing contract (INST-01/02/04/05/06/07/08/09). Mirrors the
# harness idiom of skills/tflow-skill-creator/scripts/run-tests.sh (self-locate,
# mktemp temp root, cleanup trap, pass/fail counters, `N passed, M failed` footer).
# Exits 0 if all assertions pass; exits 1 if any fail.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TFLOW="$REPO_ROOT/bin/tflow"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tflow-installer-tests.XXXXXX")
PASS=0
FAIL=0

# shellcheck disable=SC2329  # invoked indirectly via the EXIT/signal trap below.
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

assert_status() {
    NAME="$1"
    EXPECTED="$2"
    if [ "$CLI_STATUS" = "$EXPECTED" ]; then
        pass "$NAME (exit $EXPECTED as expected)"
    else
        fail "$NAME" "expected exit $EXPECTED, got $CLI_STATUS"
    fi
}

# Drive the real CLI inside a temp project (cwd = project, so the local-install
# default targets it). Combined stdout+stderr is captured to a log for plan/report
# assertions; CLI_STATUS holds the exit code without aborting under `set -e`.
cli() {
    CLI_DIR="$1"
    CLI_LOG="$2"
    shift 2
    if ( cd "$CLI_DIR" && node "$TFLOW" "$@" ) >"$CLI_LOG" 2>&1; then
        CLI_STATUS=0
    else
        CLI_STATUS=$?
    fi
}

# Portable in-place edit (POSIX sed -i is non-portable; use a temp + mv).
replace_in() {
    EDIT_FILE="$1"
    EDIT_EXPR="$2"
    sed "$EDIT_EXPR" "$EDIT_FILE" > "$TMP_ROOT/.edit.tmp"
    mv "$TMP_ROOT/.edit.tmp" "$EDIT_FILE"
}

MARK='TFLOW_TEST_MARKER_EDIT'

# ── Scenario A: install + manifest + fixture exclusion + idempotency +
#    no-clobber + --force + advisory self-check (INST-01/04/07/08) ──────────────
PROJ_A="$TMP_ROOT/proj-a"
mkdir -p "$PROJ_A/.claude"
A_SKILLS="$PROJ_A/.claude/skills"
A_MAN="$PROJ_A/.claude/.tflow/install-manifest.json"

cli "$PROJ_A" "$TMP_ROOT/a1.log" init --claude
assert_status "init --claude" 0
assert_file "installs tflow-research SKILL.md" "$A_SKILLS/tflow-research/SKILL.md"
assert_file "installs tflow-skill-creator SKILL.md" "$A_SKILLS/tflow-skill-creator/SKILL.md"
assert_file "installs tflow-skill-factory SKILL.md" "$A_SKILLS/tflow-skill-factory/SKILL.md"
assert_file "writes install manifest" "$A_MAN"
assert_grep "manifest records sha256 hashes" '"[0-9a-f]\{64\}"' "$A_MAN"
assert_grep "manifest declares the package name" '@glapsfun/tflow' "$A_MAN"
assert_grep "self-check reports PASS per real skill" 'PASS tflow-research' "$TMP_ROOT/a1.log"

# Fixture exclusion (INST-08): no scripts/fixtures and no fail-* anywhere.
assert_missing "fixtures dir excluded from install" \
    "$A_SKILLS/tflow-skill-creator/scripts/fixtures"
if find "$A_SKILLS" -name 'fail-*' 2>/dev/null | grep -q .; then
    fail "no fail-* paths under install" "found a fail-* path in the runtime copy"
else
    pass "no fail-* paths under install"
fi

# Idempotency (INST-04): a clean second run refreshes pristine files as overwrite.
cli "$PROJ_A" "$TMP_ROOT/a2.log" init --claude
assert_status "second init is idempotent" 0
assert_grep "second run overwrites pristine files" 'overwrite' "$TMP_ROOT/a2.log"

# No-clobber (INST-04): a user edit survives a re-run and is reported skip(modified).
A_EDITED="$A_SKILLS/tflow-research/SKILL.md"
printf '\n%s\n' "$MARK" >> "$A_EDITED"
cli "$PROJ_A" "$TMP_ROOT/a3.log" init --claude
assert_status "re-run over a user edit" 0
assert_grep "user-edited file reported skip(modified)" 'skip(modified)' "$TMP_ROOT/a3.log"
assert_grep "user edit survives re-run" "$MARK" "$A_EDITED"

# --force overwrites the user edit (INST-04 / D-04).
cli "$PROJ_A" "$TMP_ROOT/a4.log" init --claude --force
assert_status "init --force" 0
assert_grep "force overwrites files" 'overwrite' "$TMP_ROOT/a4.log"
assert_not_grep "force replaces the user edit" "$MARK" "$A_EDITED"

# Advisory self-check (INST-07 / D-08): a broken installed skill makes validate FAIL,
# but the install still exits 0. Breaking name!=dir is a modified file, so it is
# preserved through the re-run and validate sees the break.
replace_in "$A_EDITED" 's/^name: tflow-research$/name: broken-name-mismatch/'
cli "$PROJ_A" "$TMP_ROOT/a5.log" init --claude
assert_status "install exits 0 despite a failing self-check" 0
assert_grep "self-check reports FAIL for the broken skill" 'FAIL tflow-research' "$TMP_ROOT/a5.log"

# ── Scenario B: --dry-run writes nothing (INST-05 / D-05) ─────────────────────
PROJ_B="$TMP_ROOT/proj-b"
mkdir -p "$PROJ_B/.claude"
cli "$PROJ_B" "$TMP_ROOT/b1.log" init --claude --dry-run
assert_status "init --dry-run" 0
assert_grep "dry-run prints a create plan" 'create' "$TMP_ROOT/b1.log"
assert_missing "dry-run writes no skills dir" "$PROJ_B/.claude/skills"
assert_missing "dry-run writes no manifest" "$PROJ_B/.claude/.tflow/install-manifest.json"

# ── Scenario C: --uninstall removes pristine, preserves modified (INST-06/D-07) ─
PROJ_C="$TMP_ROOT/proj-c"
mkdir -p "$PROJ_C/.claude"
cli "$PROJ_C" "$TMP_ROOT/c1.log" init --claude
assert_status "install before uninstall" 0
C_PRISTINE="$PROJ_C/.claude/skills/tflow-research/SKILL.md"
C_MODIFIED="$PROJ_C/.claude/skills/tflow-skill-factory/SKILL.md"
printf '\n%s\n' "$MARK" >> "$C_MODIFIED"
cli "$PROJ_C" "$TMP_ROOT/c2.log" init --uninstall --claude
assert_status "init --uninstall" 0
assert_grep "uninstall preserves a modified file" 'preserved(modified)' "$TMP_ROOT/c2.log"
assert_missing "uninstall removes a pristine file" "$C_PRISTINE"
assert_missing "uninstall removes the manifest" "$PROJ_C/.claude/.tflow/install-manifest.json"
assert_file "uninstall keeps the modified file" "$C_MODIFIED"
assert_grep "modified file content is intact after uninstall" "$MARK" "$C_MODIFIED"

# ── Scenario D: --codex writes an independent manifest under .codex (INST-02) ──
PROJ_D="$TMP_ROOT/proj-d"
mkdir -p "$PROJ_D/.codex"
cli "$PROJ_D" "$TMP_ROOT/d1.log" init --codex
assert_status "init --codex" 0
assert_file "codex install places SKILL.md" "$PROJ_D/.codex/skills/tflow-research/SKILL.md"
assert_file "codex has its own manifest" "$PROJ_D/.codex/.tflow/install-manifest.json"
assert_grep "codex manifest records runtime codex" '"runtime": "codex"' \
    "$PROJ_D/.codex/.tflow/install-manifest.json"
assert_missing "codex install does not touch .claude" "$PROJ_D/.claude"

# ── Scenario E: auto-detect (D-01) — bare init non-zero with no runtime dir ────
PROJ_E="$TMP_ROOT/proj-e"
mkdir -p "$PROJ_E"
cli "$PROJ_E" "$TMP_ROOT/e1.log" init
assert_status "bare init with no runtime dir exits non-zero" 1
mkdir -p "$PROJ_E/.claude"
cli "$PROJ_E" "$TMP_ROOT/e2.log" init
assert_status "bare init auto-detects an existing .claude" 0
assert_file "auto-detected install places SKILL.md" \
    "$PROJ_E/.claude/skills/tflow-research/SKILL.md"

# ── Scenario F: tampered manifest — hostile keys are rejected, uninstall does
#    not crash, and nothing outside targetRoot is touched (WR-06; exercises the
#    V12 traversal-reject branch + the WR-01 directory/empty-key guard) ─────────
PROJ_F="$TMP_ROOT/proj-f"
mkdir -p "$PROJ_F/.claude"
cli "$PROJ_F" "$TMP_ROOT/f1.log" init --claude
assert_status "install before tampered uninstall" 0

# A sentinel OUTSIDE .claude that a "skills/../../escape" key resolves to.
F_ESCAPE="$PROJ_F/escape"
printf 'do-not-delete\n' > "$F_ESCAPE"

# Replace the real manifest with hostile keys: a `..` escape (resolves outside
# targetRoot), an empty key (resolves to targetRoot itself), and a bare
# directory key (`skills`, the EISDIR trap from WR-01).
F_MAN="$PROJ_F/.claude/.tflow/install-manifest.json"
F_SHA='0000000000000000000000000000000000000000000000000000000000000000'
{
    printf '{\n'
    printf '  "name": "@glapsfun/tflow",\n'
    printf '  "version": "0.0.0",\n'
    printf '  "runtime": "claude",\n'
    printf '  "scope": "local",\n'
    printf '  "installedAt": "1970-01-01T00:00:00.000Z",\n'
    printf '  "files": {\n'
    printf '    "skills/../../escape": "%s",\n' "$F_SHA"
    printf '    "": "%s",\n' "$F_SHA"
    printf '    "skills": "%s"\n' "$F_SHA"
    printf '  }\n'
    printf '}\n'
} > "$F_MAN"

cli "$PROJ_F" "$TMP_ROOT/f2.log" init --uninstall --claude
assert_status "uninstall with a tampered manifest does not crash" 0
assert_grep "tampered escape key is rejected" 'reject skills/../../escape' "$TMP_ROOT/f2.log"
assert_file "uninstall leaves a path outside targetRoot untouched" "$F_ESCAPE"
assert_grep "escape sentinel content is intact" 'do-not-delete' "$F_ESCAPE"

# ── Scenario G: --global installs under $HOME and records scope "global"
#    (WR-06 — global scope was previously unexercised) ──────────────────────────
G_HOME="$TMP_ROOT/proj-g-home"
mkdir -p "$G_HOME/.claude"
OLD_HOME="${HOME:-}"
export HOME="$G_HOME"
cli "$G_HOME" "$TMP_ROOT/g1.log" init --global --claude
export HOME="$OLD_HOME"
assert_status "init --global --claude" 0
assert_file "global install places SKILL.md under \$HOME/.claude" \
    "$G_HOME/.claude/skills/tflow-research/SKILL.md"
assert_grep "global manifest records scope global" '"scope": "global"' \
    "$G_HOME/.claude/.tflow/install-manifest.json"

# ── Scenario H: bare init auto-detects BOTH runtimes in one invocation
#    (IN-02 — the dual-runtime auto-detect loop was previously unexercised:
#    Scenario E covered single-.claude, G covered explicit --global --claude) ─────
PROJ_H="$TMP_ROOT/proj-h"
mkdir -p "$PROJ_H/.claude" "$PROJ_H/.codex"
cli "$PROJ_H" "$TMP_ROOT/h1.log" init
assert_status "bare init auto-detects both .claude and .codex" 0
assert_file "dual auto-detect installs under .claude" \
    "$PROJ_H/.claude/skills/tflow-research/SKILL.md"
assert_file "dual auto-detect installs under .codex" \
    "$PROJ_H/.codex/skills/tflow-research/SKILL.md"
assert_file "dual auto-detect writes a .claude manifest" \
    "$PROJ_H/.claude/.tflow/install-manifest.json"
assert_file "dual auto-detect writes a .codex manifest" \
    "$PROJ_H/.codex/.tflow/install-manifest.json"
assert_grep "dual auto-detect .claude manifest records runtime claude" \
    '"runtime": "claude"' "$PROJ_H/.claude/.tflow/install-manifest.json"
assert_grep "dual auto-detect .codex manifest records runtime codex" \
    '"runtime": "codex"' "$PROJ_H/.codex/.tflow/install-manifest.json"

# ── Footer ────────────────────────────────────────────────────────────────────
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
