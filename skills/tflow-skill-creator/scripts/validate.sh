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

usage() {
    printf 'Usage: sh validate.sh [--quiet|-q] [<skill-dir>]\n' >&2
}

QUIET=0
QUIET_SET=0
TARGET_DIR="."
TARGET_SET=0

for arg in "$@"; do
    case "$arg" in
        --quiet|-q)
            if [ "$QUIET_SET" -eq 1 ]; then
                usage
                exit 2
            fi
            QUIET=1
            QUIET_SET=1
            ;;
        -*)
            printf 'ERROR: unknown option: %s\n' "$arg" >&2
            usage
            exit 2
            ;;
        *)
            if [ "$TARGET_SET" -eq 1 ]; then
                usage
                exit 2
            fi
            TARGET_DIR="$arg"
            TARGET_SET=1
            ;;
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

# ── Frontmatter extraction (strict tflow YAML subset) ─────────────────────────
if PARSED=$(awk '
function fail(message) {
    print message
    failed = 1
    exit 1
}
function trim(value) {
    sub(/^[[:space:]]+/, "", value)
    sub(/[[:space:]]+$/, "", value)
    return value
}
function scalar(value, field, first, last, inner, lower) {
    value = trim(value)
    if (value == "") {
        fail(field " must be a non-empty string")
    }

    first = substr(value, 1, 1)
    last = substr(value, length(value), 1)
    if (first == "\"" || first == "\047") {
        if (length(value) < 2 || last != first) {
            fail(field " has an unterminated quoted string")
        }
        inner = substr(value, 2, length(value) - 2)
        if (index(inner, first) || index(inner, "\\")) {
            fail(field " uses unsupported quoted-string escaping")
        }
        return inner
    }

    if (index(value, ": ") || value ~ /[[:space:]]#/) {
        fail(field " uses unsupported unquoted YAML syntax")
    }
    if (first == "[" || first == "{" || first == "&" || first == "*" ||
        first == "!" || first == "|" || first == ">" || first == "@" ||
        first == "`") {
        fail(field " uses an unsupported YAML construct")
    }
    lower = tolower(value)
    if (lower ~ /^(true|false|null|~)$/ ||
        value ~ /^[-+]?[0-9]+([.][0-9]+)?$/) {
        fail(field " must be a string")
    }
    return value
}
BEGIN {
    opened = 0
    closed = 0
    parent = ""
}
NR == 1 {
    if ($0 != "---") {
        fail("frontmatter must start with --- on line 1")
    }
    opened = 1
    next
}
opened && !closed {
    if ($0 == "---") {
        closed = 1
        next
    }
    if ($0 == "") {
        next
    }
    if ($0 ~ /^[[:space:]]/) {
        if (parent != "metadata" ||
            $0 !~ /^  [A-Za-z0-9_.-]+:[[:space:]]*/) {
            fail("invalid frontmatter indentation or mapping")
        }
        line = substr($0, 3)
        separator = index(line, ":")
        key = substr(line, 1, separator - 1)
        if (metadata_seen[key]++) {
            fail("duplicate metadata key: " key)
        }
        value = substr(line, separator + 1)
        scalar(value, "metadata." key)
        next
    }

    parent = ""
    if ($0 !~ /^[a-z][a-z0-9-]*:[[:space:]]*/) {
        fail("invalid top-level frontmatter syntax")
    }
    separator = index($0, ":")
    key = substr($0, 1, separator - 1)
    value = substr($0, separator + 1)
    if (key !~ /^(name|description|license|compatibility|metadata)$/) {
        fail("unknown top-level field: " key)
    }
    if (field_seen[key]++) {
        fail("duplicate top-level field: " key)
    }
    if (key == "metadata") {
        if (trim(value) != "") {
            fail("metadata must be an indented mapping")
        }
        parent = "metadata"
        next
    }
    values[key] = scalar(value, key)
    next
}
END {
    if (failed) {
        exit 1
    }
    if (!closed) {
        fail("frontmatter closing delimiter is missing")
    }
    if (!field_seen["name"]) {
        fail("required field name is missing")
    }
    if (!field_seen["description"]) {
        fail("required field description is missing")
    }
    print "name\t" values["name"]
    print "description\t" values["description"]
}
' "$SKILL_MD"); then
    NAME=$(printf '%s\n' "$PARSED" | awk -F '\t' \
        '$1 == "name" { print substr($0, 6) }')
    DESC=$(printf '%s\n' "$PARSED" | awk -F '\t' \
        '$1 == "description" { print substr($0, 13) }')
else
    emit FAIL "frontmatter-subset (tflow): $PARSED"
    exit 1
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
    # Resolve the target to a real directory name first. Without this a `.`
    # argument (or the bare default, which is ".") run from inside a skill dir
    # would compare against basename "." = "." and spuriously fail the match.
    # The preflight already guaranteed $TARGET_DIR holds a SKILL.md, so the cd
    # cannot fail here. (improve.sh resolves SKILL_DIR the same way.)
    DIR_NAME=$(basename "$(cd "$TARGET_DIR" && pwd)")
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
    VERB_PATTERN='dispatch(es|ing)?|run(s|ning)?|execut(es|ing|e)?|creat(es|ing|e)?|generat(es|ing|e)?|build(s|ing)?|process(es|ing)?|scaffold(s|ing)?|lint(s|ing)?|loop(s|ing)?|packag(es|ing|e)?|install(s|ing)?|call(s|ing)?|invok(es|ing|e)?|produc(es|ing|e)?|output(s|ting|ing)?|emit(s|ting)?|format(s|ting|ing)?|validat(es|ing|e)?|deploy(s|ing)?'
    if printf '%s' "$DESC" | grep -qiE "(^|[^a-z])($VERB_PATTERN)([^a-z]|$)"; then
        emit FAIL "desc-workflow-verb (tflow): description contains workflow verb (triggers description-as-summary pitfall)"
    else
        emit PASS "desc-workflow-verb"
    fi
fi

# ── Rule Set A: Body rules (spec) ─────────────────────────────────────────────

# R-BODY-LINES (CREATE-03)
BODY_LINES=$(awk 'f < 2 && /^---$/{f++; next} f >= 2{print}' "$SKILL_MD" \
    | wc -l | tr -d ' ')
if [ "$BODY_LINES" -ge 500 ]; then
    emit FAIL "body-lines (spec): $BODY_LINES lines (must be < 500)"
else
    emit PASS "body-lines"
fi

# ── Rule Set C: Portability (PORT-03) ─────────────────────────────────────────

# R-AT-LOAD — detect @-prefixed path references in body
# The || true guard is MANDATORY: grep -c exits 1 on zero matches; set -e would abort without it
AT_COUNT=$(awk 'f < 2 && /^---$/{f++; next} f >= 2{print}' "$SKILL_MD" \
    | grep -cE '(^|[^a-zA-Z0-9_])@([a-zA-Z$~][a-zA-Z0-9_-]*/|\.\.?/|/[a-zA-Z])' \
    || true)
if [ "$AT_COUNT" -gt 0 ]; then
    emit FAIL "at-force-load (tflow): $AT_COUNT line(s) with @-path syntax (use plain markdown links instead)"
else
    emit PASS "at-force-load"
fi

# ── Rule Set D: Source-tree and dev-tool gates ────────────────────────────────

SYMLINK=$(find "$TARGET_DIR" -type l -print -quit 2>/dev/null || true)
if [ -n "$SYMLINK" ]; then
    emit FAIL "symlink-free (tflow): symbolic link found: $SYMLINK"
else
    emit PASS "symlink-free"
fi

for script in "$TARGET_DIR/scripts"/*.sh; do
    [ -f "$script" ] || continue
    if sh -n "$script"; then
        emit PASS "sh-syntax: $(basename "$script")"
    else
        emit FAIL "sh-syntax: $(basename "$script")"
    fi
done

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
