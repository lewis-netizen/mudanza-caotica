#!/usr/bin/env bash
# Nivel 2 — ningún módulo supera 400 líneas (DL-033: coste-revisor, no
# coste-escritor). Los specs quedan exentos.
# Args: archivos staged (.lua).

[ "$#" -eq 0 ] && exit 0

VIOLATIONS=""
for file in "$@"; do
    case "$file" in
        *.spec.lua) continue ;;
    esac
    LINES=$(wc -l < "$file")
    if [ "$LINES" -gt 400 ]; then
        VIOLATIONS="${VIOLATIONS}
  $file — ${LINES} lines"
    fi
done

if [ -n "$VIOLATIONS" ]; then
    echo "❌ Module size violation: files exceeding 400 lines:"
    echo "$VIOLATIONS"
    echo "Split into smaller modules with single responsibilities."
    exit 1
fi
