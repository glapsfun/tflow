#!/bin/sh
# validate.sh — POSIX sh linter for Agent Skills (agentskills.io spec v1 + tflow conventions)
# Usage: sh validate.sh [--quiet|-q] [<skill-dir>]
# Exit:  0 = all rules pass; 1 = one or more rules fail; 2 = usage error
#
# Rule sources:
#   (spec)  = agentskills.io/specification v1
#   (tflow) = tflow project conventions (CONTEXT.md D-01..D-08)
#
# v1 constraints:
#   - Multi-line YAML block scalars (description: |) are not supported; extracted value
#     will be "|" which naturally fails the ^Use when check with an informative message.
#   - shellcheck is optional; if absent a WARN is emitted and overall result can still PASS (D-06).
set -eu

QUIET=0
TARGET_DIR="."

for arg in "$@"; do
    case "$arg" in
        --quiet|-q) QUIET=1 ;;
        -*) printf 'ERROR: unknown option: %s\n' "$arg" >&2; exit 2 ;;
        *)  TARGET_DIR="$arg" ;;
    esac
done

FAIL=0
SKILL_MD="$TARGET_DIR/SKILL.md"

emit() {
    LEVEL="$1"; shift; MSG="$*"
    case "$LEVEL" in
        PASS) [ "$QUIET" -eq 0 ] && printf 'PASS [%s]\n' "$MSG" || true ;;
        FAIL) printf 'FAIL [%s]\n' "$MSG" >&2; FAIL=1 ;;
        WARN) printf 'WARN: %s\n' "$MSG" >&2 ;;
    esac
}

# ── Preflight: R-SKILL-EXISTS ──────────────────────────────────────────────────
if [ ! -f "$SKILL_MD" ]; then
    emit FAIL "skill-md-exists (spec): no SKILL.md found in '$TARGET_DIR'"
    exit 1
fi

# ── Frontmatter extraction (Pattern 1) ────────────────────────────────────────
FRONTMATTER=$(awk '/^---$/{f++; next} f==1{print}' "$SKILL_MD")
NAME=$(printf '%s' "$FRONTMATTER" | grep '^name:' | sed 's/^name:[[:space:]]*//')
DESC=$(printf '%s' "$FRONTMATTER" | grep '^description:' | sed 's/^description:[[:space:]]*//')

# Guard empty NAME
if [ -z "$NAME" ]; then
    emit FAIL "name-missing (spec): no 'name:' field in frontmatter"
    FAIL=1
fi

# Guard empty DESC
if [ -z "$DESC" ]; then
    emit FAIL "desc-missing (spec): no 'description:' field in frontmatter"
    FAIL=1
fi

# ── Rule Set A: Name rules (spec) ─────────────────────────────────────────────

if [ -n "$NAME" ]; then
    # R-NAME-LEN — spec limit is a character count; wc -m counts characters
    # under a UTF-8 locale (and degrades to bytes under the C locale, so pure
    # ASCII is unaffected). Avoids over-counting multi-byte UTF-8 names.
    NAME_LEN=$(printf '%s' "$NAME" | wc -m | tr -d ' ')
    if [ "$NAME_LEN" -gt 64 ]; then
        emit FAIL "name-length (spec): $NAME_LEN chars (max 64)"
    else
        emit PASS "name-length"
    fi

    # R-NAME-PATTERN
    if printf '%s' "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        emit PASS "name-pattern"
    else
        emit FAIL "name-pattern (spec): '$NAME' (must match ^[a-z0-9]+(-[a-z0-9]+)*\$)"
    fi

    # R-NAME-DIR
    DIR_NAME=$(basename "$TARGET_DIR")
    if [ "$NAME" = "$DIR_NAME" ]; then
        emit PASS "name-dir-match"
    else
        emit FAIL "name-dir-match (spec): frontmatter name '$NAME' != directory '$DIR_NAME'"
    fi
fi

# ── Rule Set A: Description rules (spec) ──────────────────────────────────────

if [ -n "$DESC" ]; then
    # R-DESC-LEN — spec limits (1-1024) are character counts; wc -m counts
    # characters under a UTF-8 locale (degrades to bytes under C, so ASCII is
    # unaffected). Avoids over-counting multi-byte UTF-8 descriptions.
    DESC_LEN=$(printf '%s' "$DESC" | wc -m | tr -d ' ')
    if [ "$DESC_LEN" -lt 1 ] || [ "$DESC_LEN" -gt 1024 ]; then
        emit FAIL "desc-length (spec): $DESC_LEN chars (must be 1-1024)"
    else
        emit PASS "desc-length"
    fi

    # R-DESC-XML
    if printf '%s' "$DESC" | grep -qE '<[a-zA-Z][^>]*>|</[a-zA-Z]'; then
        emit FAIL "desc-xml-tags (spec): description must not contain XML tags"
    else
        emit PASS "desc-xml-tags"
    fi

    # ── Rule Set B: Description rules (tflow) ─────────────────────────────────

    # R-DESC-PREFIX (D-03)
    if printf '%s' "$DESC" | grep -q '^Use when'; then
        emit PASS "desc-prefix"
    else
        emit FAIL "desc-prefix (tflow): must start with 'Use when' (got: '$(printf '%s' "$DESC" | cut -c1-40)...')"
    fi

    # R-DESC-VERBS (D-04)
    # NOTE: "trigger" is intentionally NOT a banned verb — portability-notes.md
    # teaches trigger-condition phrasing ("Use when an observable trigger
    # condition applies") as the recommended description style, so the validator
    # must not reject the wording it recommends.
    VERB_PATTERN='dispatch(es|ing)?|run(s|ning)?|execut(es|ing|e)?|creat(es|ing|e)?|generat(es|ing|e)?|build(s|ing)?|process(es|ing)?|scaffold(s|ing)?|lint(s|ing)?|loop(s|ing)?|packag(es|ing|e)?|install(s|ing)?|call(s|ing)?|invok(es|ing|e)?|produc(es|ing|e)?|output(s|ing)?|emit(s|ting)?|format(s|ing)?|validat(es|ing|e)?|deploy(s|ing)?'
    if printf '%s' "$DESC" | grep -qiE "(^|[^a-z])($VERB_PATTERN)([^a-z]|$)"; then
        emit FAIL "desc-workflow-verb (tflow): description contains workflow verb (triggers description-as-summary pitfall)"
    else
        emit PASS "desc-workflow-verb"
    fi
fi

# ── Rule Set A: Body rules (spec) ─────────────────────────────────────────────

# R-BODY-LINES (CREATE-03)
BODY_LINES=$(awk '/^---$/{f++; next} f>=2{print}' "$SKILL_MD" | wc -l | tr -d ' ')
if [ "$BODY_LINES" -ge 500 ]; then
    emit FAIL "body-lines (spec): $BODY_LINES lines (must be < 500)"
else
    emit PASS "body-lines"
fi

# ── Rule Set C: Portability (PORT-03) ─────────────────────────────────────────

# R-AT-LOAD — detect @-prefixed path references in body
# The || true guard is MANDATORY: grep -c exits 1 on zero matches; set -e would abort without it
AT_COUNT=$(awk '/^---$/{f++; next} f>=2{print}' "$SKILL_MD" \
    | grep -cE '(^|[^a-zA-Z0-9_])@([a-zA-Z$~][a-zA-Z0-9_-]*/|\.\.?/|/[a-zA-Z])' \
    || true)
if [ "$AT_COUNT" -gt 0 ]; then
    emit FAIL "at-force-load (tflow): $AT_COUNT line(s) with @-path syntax (use plain markdown links instead)"
else
    emit PASS "at-force-load"
fi

# ── Rule Set D: Dev-tool gate (D-06) ──────────────────────────────────────────

# R-SHELLCHECK — optional; WARN if absent (D-06), FAIL if present and non-zero
if command -v shellcheck >/dev/null 2>&1; then
    SC_FAIL=0
    for script in "$TARGET_DIR/scripts"/*.sh; do
        [ -f "$script" ] || continue
        if shellcheck --shell=sh "$script"; then
            emit PASS "shellcheck: $(basename "$script")"
        else
            emit FAIL "shellcheck: $(basename "$script") (see above for warnings)"
            SC_FAIL=1
        fi
    done
    [ "$SC_FAIL" -ne 0 ] && FAIL=1
else
    emit WARN "shellcheck not installed — skipping shellcheck rule (install: brew install shellcheck)"
fi

# ── Final result ───────────────────────────────────────────────────────────────

if [ "$FAIL" -ne 0 ]; then
    [ "$QUIET" -eq 0 ] && printf '\nValidation FAILED\n' >&2
    exit 1
fi
[ "$QUIET" -eq 0 ] && printf '\nValidation PASSED\n'
exit 0
