#!/bin/sh
# stamp-changelog.sh — rewrite the CHANGELOG [Unreleased] section into a dated
# release section at `npm version` time, then re-seed a fresh empty [Unreleased].
#
# Maintainer-only release tooling: this runs from the repo root via the
# package.json `version` lifecycle hook when a maintainer runs `npm version`.
# It is NOT shipped in the npm tarball (excluded by the package.json `files`
# allowlist, same as scripts/assert-pack.sh) and never runs on consumer install.
#
# Zero-dependency POSIX sh: node is guaranteed by package.json engines.node>=20;
# everything else (awk/date/mktemp/mv/grep) is a system tool. Safe to run twice —
# a second run on an already-stamped version is a no-op (exit 0).
set -eu

CHANGELOG="CHANGELOG.md"
VERSION="$(node -p "require('./package.json').version")" # D-06: single source
DATE="$(date +%Y-%m-%d)"                                 # Keep a Changelog ISO date

# Idempotency guard FIRST. FIXED-STRING (-F) match, NOT a regex: a SemVer like
# 0.1.0 contains regex metacharacters (.) that an interpolated regex would treat
# as wildcards and could false-match. `if grep` is a CONDITION so set -e does NOT
# abort on its non-zero result (the CLAUDE.md grep trap applies to grep -c in
# assignments/pipelines, not to grep inside an if).
if grep -Fq "## [$VERSION]" "$CHANGELOG"; then
    printf 'stamp-changelog: ## [%s] already present — nothing to do.\n' "$VERSION"
    exit 0
fi

# Contract guard: require an [Unreleased] heading to rewrite; fail loud if absent.
if ! grep -q '^## \[Unreleased\]' "$CHANGELOG"; then
    printf 'stamp-changelog: no ## [Unreleased] section in %s\n' "$CHANGELOG" >&2
    exit 1
fi

# Empty-body guard: extract the [Unreleased] section body with the SAME awk logic
# release.yml uses, and reject (exit 1) before any rewrite if it has no
# non-whitespace content — so a maintainer cannot tag a release that Phase 6's
# non-empty-section gate would reject. The BODY=$(...) assignment is an awk
# pipeline with no grep -c, so no `|| true` is needed; the grep -q lives inside an
# `if !` condition and is therefore safe under set -e.
BODY="$(awk '
    /^## \[Unreleased\]/ {f=1; next}
    f && /^## \[/ {exit}
    f {print}
' "$CHANGELOG")"
if ! printf '%s' "$BODY" | grep -q '[^[:space:]]'; then
    printf 'stamp-changelog: ## [Unreleased] section is empty — add entries before releasing\n' >&2
    exit 1
fi

# Atomic rewrite. The temp file sits BESIDE CHANGELOG.md (cwd, same filesystem) so
# the final `mv` is an atomic same-filesystem rename, never a cross-filesystem
# copy-and-delete that could leave a partial CHANGELOG.md.
TMP="$(mktemp "./.stamp-changelog.XXXXXX")"
cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT HUP INT TERM

# Replace the FIRST [Unreleased] heading with: a fresh empty [Unreleased], a blank
# line, then the dated version heading. The original section body now follows the
# version heading unchanged. The `done` guard ensures only the first match rewrites.
awk -v ver="$VERSION" -v date="$DATE" '
    !done && /^## \[Unreleased\]/ {
        print "## [Unreleased]"
        print ""
        print "## [" ver "] - " date
        done = 1
        next
    }
    { print }
' "$CHANGELOG" >"$TMP"

mv "$TMP" "$CHANGELOG"
trap - EXIT HUP INT TERM
printf 'stamp-changelog: stamped ## [%s] - %s\n' "$VERSION" "$DATE"
