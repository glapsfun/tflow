#!/bin/sh
# assert-pack.sh — npm pack content-assertion guard for @glapsfun/tflow.
# Runs `npm pack --dry-run --json`, lists the tarball paths, and asserts the
# publish include/exclude contract (PKG-02/PKG-03/PKG-04):
#   - MUST contain the dev kit (skills, bin/tflow, CHANGELOG.md, README.md,
#     LICENSE, package.json) and the shipped fixtures.
#   - MUST NOT leak any dev-kit internal, runtime artifact, or stray tarball.
# Zero-dependency: node is guaranteed by package.json engines.node>=20.
# Exit 0 if the contract holds; exit 1 on the first violation.
# Phase 6 (REL-04) reuses this as a pre-publish gate.
set -eu

# Resolve repo root (the dir holding package.json) so npm pack runs against it
# regardless of the caller's cwd.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

TMP_LIST=$(mktemp "${TMPDIR:-/tmp}/tflow-pack.XXXXXX")
cleanup() {
    rm -f "$TMP_LIST"
}
trap cleanup EXIT HUP INT TERM

PASS=0
FAIL=0

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

# 1. Build the tarball path list from npm pack --dry-run --json.
#    JSON shape: [ { ..., "files": [ { "path", "size", "mode" }, ... ] } ]
npm pack --dry-run --json 2>/dev/null \
    | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));for(const f of d[0].files)console.log(f.path)' \
    > "$TMP_LIST"

if [ ! -s "$TMP_LIST" ]; then
    printf 'FAIL: npm pack --dry-run produced an empty file list\n' >&2
    exit 1
fi

# 2. MUST-CONTAIN: exact dev-kit roots.
for p in bin/tflow CHANGELOG.md README.md LICENSE package.json; do
    if grep -qx "$p" "$TMP_LIST"; then
        pass "ships $p"
    else
        fail "missing required path: $p"
    fi
done

# MUST-CONTAIN: at least one shipped fixture path (PKG-03 keeps fixtures).
if grep -q '^skills/tflow-skill-creator/scripts/fixtures/' "$TMP_LIST"; then
    pass "ships skills/**/scripts/fixtures/"
else
    fail "fixtures missing from tarball"
fi

# MUST-CONTAIN: at least one shipped skill-creator shell script.
if grep -q '^skills/tflow-skill-creator/scripts/.*\.sh$' "$TMP_LIST"; then
    pass "ships skills/tflow-skill-creator/scripts/*.sh"
else
    fail "no skill-creator *.sh shipped"
fi

# 3a. MUST-NOT-CONTAIN — dev-kit internal dirs / the guard's own scripts/ dir.
#     These only leak if they appear at the TARBALL ROOT, so anchor with `^`.
#     A bare substring would false-positive on the legitimately-shipped nested
#     skills/**/scripts/ paths (those MUST ship). Guard each count against the
#     set -e zero-match abort with `|| true`.
for bad in '^\.planning/' '^\.claude/' '^\.codex/' '^\.help/' '^\.github/' '^scripts/'; do
    COUNT=$(grep -c "$bad" "$TMP_LIST" || true)
    if [ "$COUNT" -eq 0 ]; then
        pass "no leak (root): $bad"
    else
        fail "leaked $COUNT path(s) matching: $bad"
    fi
done

# 3b. MUST-NOT-CONTAIN — root marker files, runtime artifacts, stray tarballs.
#     These leak if present ANYWHERE in the tree, so match as substrings.
for bad in 'CLAUDE.md' 'AGENTS.md' '/dist/' '.skill-improvement.md' '.tgz'; do
    COUNT=$(grep -c "$bad" "$TMP_LIST" || true)
    if [ "$COUNT" -eq 0 ]; then
        pass "no leak: $bad"
    else
        fail "leaked $COUNT path(s) matching: $bad"
    fi
done

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
printf 'pack contract OK\n'
