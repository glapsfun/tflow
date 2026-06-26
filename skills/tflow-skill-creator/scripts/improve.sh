#!/bin/sh
# improve.sh — write a lightweight skill improvement evidence report
# Usage: sh improve.sh <skill-dir-or-SKILL.md>
# Exit:  0 = report written and validation passed; 1 = report written with failed validation or operational failure; 2 = usage error
set -eu

usage() {
    printf 'Usage: sh improve.sh <skill-dir-or-SKILL.md>\n' >&2
}

if [ "$#" -ne 1 ]; then
    usage
    exit 2
fi

case "$1" in
    -*) usage; exit 2 ;;
esac

INPUT="$1"
if [ -d "$INPUT" ]; then
    SKILL_DIR="$INPUT"
    SKILL_MD="$SKILL_DIR/SKILL.md"
elif [ -f "$INPUT" ] && [ "$(basename "$INPUT")" = "SKILL.md" ]; then
    SKILL_MD="$INPUT"
    SKILL_DIR="$(cd "$(dirname "$INPUT")" && pwd)"
else
    printf 'ERROR: expected a skill directory or SKILL.md path: %s\n' "$INPUT" >&2
    exit 1
fi

if [ ! -f "$SKILL_MD" ]; then
    printf 'ERROR: no SKILL.md found in %s\n' "$SKILL_DIR" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"
SCAFFOLD="$SCRIPT_DIR/../assets/scaffold/SKILL.md"
REPORT="$SKILL_DIR/.skill-improvement.md"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/tflow-improve.XXXXXX")

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT HUP INT TERM

VALIDATION_OUT="$TMP_DIR/validation.txt"
if sh "$VALIDATE" "$SKILL_DIR" > "$VALIDATION_OUT" 2>&1; then
    VALIDATION_STATUS="PASS"
    VALIDATION_EXIT=0
else
    VALIDATION_STATUS="FAIL"
    VALIDATION_EXIT=1
fi

NAME=$(awk '/^---$/{f++; next} f==1 && /^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}' "$SKILL_MD")
[ -n "$NAME" ] || NAME="$(basename "$SKILL_DIR")"

SCAFFOLD_DIFF="$TMP_DIR/scaffold.diff"
if [ -f "$SCAFFOLD" ]; then
    SCAFFOLD_RENDERED="$TMP_DIR/SKILL.md"
    sed "s/__SKILL_NAME__/$NAME/g" "$SCAFFOLD" > "$SCAFFOLD_RENDERED"
    if diff -u "$SCAFFOLD_RENDERED" "$SKILL_MD" > "$SCAFFOLD_DIFF" 2>&1; then
        printf 'No differences from the scaffold template.\n' > "$SCAFFOLD_DIFF"
    fi
else
    printf 'Scaffold template not found: %s\n' "$SCAFFOLD" > "$SCAFFOLD_DIFF"
fi

PLACEHOLDERS="$TMP_DIR/placeholders.txt"
if grep -nEi 'TODO|FIXME|placeholder|coming soon|not available|__SKILL_NAME__' "$SKILL_MD" > "$PLACEHOLDERS" 2>/dev/null; then
    PLACEHOLDER_STATUS="REVIEW"
else
    PLACEHOLDER_STATUS="PASS"
    printf 'No obvious starter leftovers found.\n' > "$PLACEHOLDERS"
fi

{
    printf '# Skill Improvement Report\n\n'
    printf '## Validation\n\n'
    printf -- '- Command: `sh %s %s`\n' "$VALIDATE" "$SKILL_DIR"
    printf -- '- Result: %s\n\n' "$VALIDATION_STATUS"
    printf '```text\n'
    cat "$VALIDATION_OUT"
    printf '```\n\n'
    printf '## Scaffold Comparison\n\n'
    printf '```diff\n'
    cat "$SCAFFOLD_DIFF"
    printf '```\n\n'
    printf '## Placeholder Checks\n\n'
    printf -- '- Result: %s\n\n' "$PLACEHOLDER_STATUS"
    printf '```text\n'
    cat "$PLACEHOLDERS"
    printf '```\n\n'
    printf '## Testing Checklist\n\n'
    printf -- '- [ ] Ran validate.sh against the final source skill\n'
    printf -- '- [ ] Tested the skill against at least one realistic user prompt\n'
    printf -- '- [ ] Confirmed references and assets are read only when relevant\n'
    printf -- '- [ ] Confirmed no runtime-specific frontmatter or install path is required\n'
} > "$REPORT"

printf 'Wrote improvement report: %s\n' "$REPORT"
exit "$VALIDATION_EXIT"
