#!/bin/sh
# discover-skills.sh — list installed tflow-* skills as name<TAB>description
# Usage: sh discover-skills.sh <skills-root>...
# Exit:  0 = at least one tflow skill found; 1 = none found; 2 = usage error
#
# Scans each <skills-root> for tflow-*/SKILL.md and extracts the name and
# description frontmatter fields (single-line scalars only — the same subset
# as validate.sh; block scalars are unsupported and skipped). tflow-gateway
# itself is excluded: the gateway never routes to itself. Duplicate skill
# directories across roots are listed once — the first root wins. A SKILL.md
# whose frontmatter cannot be read emits a WARN to stderr and is skipped.
set -eu

usage() {
    printf 'Usage: sh discover-skills.sh <skills-root>...\n' >&2
}

if [ "$#" -lt 1 ]; then
    usage
    exit 2
fi

for ROOT in "$@"; do
    if [ ! -d "$ROOT" ]; then
        printf 'ERROR: not a directory: %s\n' "$ROOT" >&2
        usage
        exit 2
    fi
done

FOUND=0
SEEN=" "

for ROOT in "$@"; do
    for SKILL_MD in "$ROOT"/tflow-*/SKILL.md; do
        [ -f "$SKILL_MD" ] || continue
        DIR_NAME=$(basename "$(dirname "$SKILL_MD")")
        if [ "$DIR_NAME" = "tflow-gateway" ]; then
            continue
        fi
        case "$SEEN" in
            *" $DIR_NAME "*) continue ;;
        esac
        # \047 is a single quote; strip one matching pair of surrounding
        # quotes from a scalar, mirroring validate.sh's quoted-string subset.
        if awk '
            function strip(v, first, last) {
                sub(/^[[:space:]]+/, "", v)
                sub(/[[:space:]]+$/, "", v)
                if (length(v) >= 2) {
                    first = substr(v, 1, 1)
                    last = substr(v, length(v), 1)
                    if ((first == "\"" || first == "\047") && last == first) {
                        v = substr(v, 2, length(v) - 2)
                    }
                }
                return v
            }
            NR == 1 {
                if ($0 != "---") { bad = 1; exit }
                next
            }
            $0 == "---" { closed = 1; exit }
            /^name:/ { name = strip(substr($0, 6)) }
            /^description:/ { desc = strip(substr($0, 13)) }
            END {
                if (bad || !closed || name == "" || desc == "") exit 1
                printf "%s\t%s\n", name, desc
            }
        ' "$SKILL_MD"; then
            SEEN="$SEEN$DIR_NAME "
            FOUND=$((FOUND + 1))
        else
            printf 'WARN: skipping %s (unreadable frontmatter)\n' "$SKILL_MD" >&2
        fi
    done
done

if [ "$FOUND" -eq 0 ]; then
    printf 'ERROR: no routable tflow skills found\n' >&2
    exit 1
fi
exit 0
