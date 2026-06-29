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

# shellcheck disable=SC2329  # invoked indirectly via the trap below
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

# Strip surrounding quotes so a quoted `name: "foo"` (which validate.sh accepts)
# resolves to the same kebab name here and still gets a scaffold diff instead of
# being skipped as non-portable.
NAME=$(awk '/^---$/{f++; next} f==1 && /^name:/{
    sub(/^name:[[:space:]]*/, "")
    sub(/[[:space:]]+$/, "")
    q = substr($0, 1, 1)
    if ((q == "\"" || q == "\047") && substr($0, length($0), 1) == q) {
        $0 = substr($0, 2, length($0) - 2)
    }
    print; exit
}' "$SKILL_MD")
[ -n "$NAME" ] || NAME="$(basename "$SKILL_DIR")"

# Render the scaffold for comparison with awk so the (possibly untrusted)
# skill name is passed as data and never parsed as program text — this avoids
# the sed command-injection / crash on sed-special characters. A non-portable
# name skips the diff with a note instead of aborting, so the report is always
# written (improve.sh's contract: exit 1 = report written).
SCAFFOLD_DIFF="$TMP_DIR/scaffold.diff"
if [ ! -f "$SCAFFOLD" ]; then
    printf 'Scaffold template not found: %s\n' "$SCAFFOLD" > "$SCAFFOLD_DIFF"
elif ! printf '%s' "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    printf 'Skipped scaffold diff: non-portable skill name %s\n' "$NAME" > "$SCAFFOLD_DIFF"
else
    SCAFFOLD_RENDERED="$TMP_DIR/SKILL.md"
    awk -v n="$NAME" '{gsub(/__SKILL_NAME__/, n)}1' "$SCAFFOLD" > "$SCAFFOLD_RENDERED"
    if diff -u "$SCAFFOLD_RENDERED" "$SKILL_MD" > "$SCAFFOLD_DIFF" 2>&1; then
        printf 'No differences from the scaffold template.\n' > "$SCAFFOLD_DIFF"
    fi
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
    # shellcheck disable=SC2016  # literal backticks are intended markdown, not expansion
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
