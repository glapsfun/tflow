#!/bin/sh
# package.sh — create an inspectable skill package and tar.gz archive
# Usage: sh package.sh <skill-dir>
# Exit:  0 = package artifacts written; 1 = gate or operational failure; 2 = usage error
set -eu

usage() {
    printf 'Usage: sh package.sh <skill-dir>\n' >&2
}

if [ "$#" -ne 1 ]; then
    usage
    exit 2
fi

case "$1" in
    -*) usage; exit 2 ;;
esac

SKILL_DIR="$1"
if [ ! -d "$SKILL_DIR" ]; then
    printf 'ERROR: skill directory not found: %s\n' "$SKILL_DIR" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"
IMPROVEMENT="$SKILL_DIR/.skill-improvement.md"
SKILL_NAME="$(basename "$SKILL_DIR")"

if ! sh "$VALIDATE" "$SKILL_DIR"; then
    printf 'ERROR: validation failed; package artifacts were not updated.\n' >&2
    exit 1
fi

if [ ! -f "$IMPROVEMENT" ]; then
    printf 'ERROR: missing improvement evidence: %s\n' "$IMPROVEMENT" >&2
    exit 1
fi

for required in \
    '- [x] Ran validate.sh against the final source skill' \
    '- [x] Tested the skill against at least one realistic user prompt' \
    '- [x] Confirmed references and assets are read only when relevant' \
    '- [x] Confirmed no runtime-specific frontmatter or install path is required'
do
    COUNT=$(grep -Fxc -- "$required" "$IMPROVEMENT" || true)
    if [ "$COUNT" -ne 1 ]; then
        printf 'ERROR: missing or duplicated completed evidence: %s\n' "$required" >&2
        exit 1
    fi
done

if grep -q '^- \[ \]' "$IMPROVEMENT"; then
    printf 'ERROR: .skill-improvement.md has unchecked checklist items.\n' >&2
    exit 1
fi

SYMLINK=$(find "$SKILL_DIR" -type l -print -quit 2>/dev/null || true)
if [ -n "$SYMLINK" ]; then
    printf 'ERROR: symbolic links are not portable package input: %s\n' "$SYMLINK" >&2
    exit 1
fi

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/tflow-package.XXXXXX")
# shellcheck disable=SC2329  # invoked indirectly via the trap below
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT HUP INT TERM

STAGE_DIR="$TMP_DIR/$SKILL_NAME"
ARCHIVE_TMP="$TMP_DIR/$SKILL_NAME.tar.gz"
mkdir -p "$STAGE_DIR"

for item in "$SKILL_DIR"/* "$SKILL_DIR"/.[!.]* "$SKILL_DIR"/..?*; do
    [ -e "$item" ] || continue
    base="$(basename "$item")"
    case "$base" in
        .skill-improvement.md|dist|.git|.DS_Store|.cache|__pycache__|*.tmp|*.temp|*.swp|*~)
            continue
            ;;
    esac
    cp -R "$item" "$STAGE_DIR/$base"
done

(cd "$TMP_DIR" && tar -czf "$ARCHIVE_TMP" "$SKILL_NAME")

DIST_DIR="$SKILL_DIR/dist"
mkdir -p "$DIST_DIR"
# shellcheck disable=SC2115  # $SKILL_NAME is a validated basename, never empty
rm -rf "$DIST_DIR/$SKILL_NAME" "$DIST_DIR/$SKILL_NAME.tar.gz"
cp -R "$STAGE_DIR" "$DIST_DIR/$SKILL_NAME"
cp "$ARCHIVE_TMP" "$DIST_DIR/$SKILL_NAME.tar.gz"

printf 'Package directory: %s\n' "$DIST_DIR/$SKILL_NAME"
printf 'Package archive: %s\n' "$DIST_DIR/$SKILL_NAME.tar.gz"
printf 'Install hint: copy the package directory into a supported agent skills directory when needed.\n'
