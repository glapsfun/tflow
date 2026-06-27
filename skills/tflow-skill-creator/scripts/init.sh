#!/bin/sh
# init.sh — create a portable Agent Skill scaffold
# Usage: sh init.sh <skill-name> [target-root]
# Exit:  0 = scaffold created and validates; 1 = operational failure; 2 = usage error
set -eu

usage() {
    printf 'Usage: sh init.sh <skill-name> [target-root]\n' >&2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
    exit 2
fi

case "$1" in
    -*) usage; exit 2 ;;
esac

SKILL_NAME="$1"
TARGET_ROOT="${2:-.}"

if ! printf '%s' "$SKILL_NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    printf 'ERROR: invalid skill name: %s\n' "$SKILL_NAME" >&2
    printf 'Names must match ^[a-z0-9]+(-[a-z0-9]+)*$ and contain no slash, dot, or uppercase characters.\n' >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCAFFOLD="$SCRIPT_DIR/../assets/scaffold/SKILL.md"
VALIDATE="$SCRIPT_DIR/validate.sh"
TARGET_DIR="$TARGET_ROOT/skills/$SKILL_NAME"

if [ ! -f "$SCAFFOLD" ]; then
    printf 'ERROR: scaffold template not found: %s\n' "$SCAFFOLD" >&2
    exit 1
fi

if [ -e "$TARGET_DIR" ]; then
    printf 'ERROR: target skill already exists: %s\n' "$TARGET_DIR" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR/scripts" "$TARGET_DIR/references" "$TARGET_DIR/assets"
sed "s/__SKILL_NAME__/$SKILL_NAME/g" "$SCAFFOLD" > "$TARGET_DIR/SKILL.md"

if ! sh "$VALIDATE" "$TARGET_DIR"; then
    # Remove the half-created scaffold so the command stays re-runnable
    # (otherwise the [ -e "$TARGET_DIR" ] guard above trips on retry).
    rm -rf "$TARGET_DIR"
    printf 'ERROR: generated scaffold failed validation: %s\n' "$TARGET_DIR" >&2
    exit 1
fi

printf 'Created skill scaffold: %s\n' "$TARGET_DIR"
printf 'Next: edit SKILL.md, add supporting files, then run improve.sh and package.sh.\n'
