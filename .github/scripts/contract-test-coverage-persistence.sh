#!/usr/bin/env bash
# Nivel 2 — todo módulo de src/server/Persistence/ tiene spec en
# src/shared/Tests/. §4.11.
# Args: archivos staged (.lua) de src/server/Persistence.

[ "$#" -eq 0 ] && exit 0

MISSING=""
for file in "$@"; do
    case "$file" in
        *.spec.lua) continue ;;
    esac
    module=$(basename "$file" .lua)
    spec="src/shared/Tests/${module}.spec.lua"
    if [ ! -f "$spec" ]; then
        MISSING="${MISSING}
  ${module}: spec missing at ${spec}"
    fi
done

if [ -n "$MISSING" ]; then
    echo "❌ Test coverage: Persistence module without spec:"
    echo "$MISSING"
    exit 1
fi
