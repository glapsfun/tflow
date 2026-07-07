#!/bin/sh
# validate-artifacts.sh — tflow-gateway artifact gate
# Usage: sh validate-artifacts.sh <run-dir> <artifact-name>...
# Exit:  0 = all named artifacts pass; 1 = any check fails; 2 = usage error
#
# Every named artifact must exist in <run-dir> and be non-empty. The four
# gateway-owned artifacts (enhanced-prompt.md, routing-decision.md,
# validation.md, final-report.md) must additionally contain their schema's
# required "## section" headings. Unknown artifact names get the existence
# and non-empty checks only, so delegated skills' artifacts can be gated
# without hardcoding their schemas here.
set -eu

usage() {
    printf 'Usage: sh validate-artifacts.sh <run-dir> <artifact-name>...\n' >&2
}

if [ "$#" -lt 2 ]; then
    usage
    exit 2
fi

RUN_DIR="$1"
shift

if [ ! -d "$RUN_DIR" ]; then
    printf 'ERROR: not a directory: %s\n' "$RUN_DIR" >&2
    usage
    exit 2
fi

FAIL=0

check_sections() {
    FILE="$1"
    ARTIFACT="$2"
    shift 2
    for SECTION in "$@"; do
        if grep -q "^## $SECTION\$" "$FILE"; then
            printf 'PASS [%s: section %s]\n' "$ARTIFACT" "$SECTION"
        else
            printf 'FAIL [%s: missing section ## %s]\n' "$ARTIFACT" "$SECTION" >&2
            FAIL=1
        fi
    done
}

for NAME in "$@"; do
    # Confine every check to <run-dir>: a name with a path separator (or a
    # dot-prefixed name like ../x) could report PASS for a file outside it.
    case "$NAME" in
        */*|.*)
            printf 'FAIL [%s: artifact name must be a plain filename]\n' "$NAME" >&2
            FAIL=1
            continue
            ;;
    esac
    FILE="$RUN_DIR/$NAME"
    if [ ! -f "$FILE" ]; then
        printf 'FAIL [%s: missing]\n' "$NAME" >&2
        FAIL=1
        continue
    fi
    if [ ! -s "$FILE" ]; then
        printf 'FAIL [%s: empty]\n' "$NAME" >&2
        FAIL=1
        continue
    fi
    printf 'PASS [%s: exists, non-empty]\n' "$NAME"
    case "$NAME" in
        enhanced-prompt.md)
            check_sections "$FILE" "$NAME" \
                goal expected_output acceptance_checks missing_context ;;
        routing-decision.md)
            check_sections "$FILE" "$NAME" \
                chosen_skills rationale execution_mode rejected_candidates ;;
        validation.md)
            check_sections "$FILE" "$NAME" checks verdict ;;
        final-report.md)
            check_sections "$FILE" "$NAME" \
                original_request routing artifacts validation_verdict \
                remaining_issues ;;
    esac
done

if [ "$FAIL" -ne 0 ]; then
    printf '\nArtifact gate FAILED\n' >&2
    exit 1
fi
printf '\nArtifact gate PASSED\n'
exit 0
