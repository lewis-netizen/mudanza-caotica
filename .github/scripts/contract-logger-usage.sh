#!/usr/bin/env bash
# Nivel 1 — print()/warn() directos prohibidos fuera de Lib/Logger.lua.
# Selene no puede prohibir globals específicos — este grep es el ban real.
# Args: archivos staged (.lua).

[ "$#" -eq 0 ] && exit 0

VIOLATIONS=$(grep -nHE '(^|[^A-Za-z_.:])(print|warn)\(' "$@" | grep -v "Logger.lua" || true)

if [ -n "$VIOLATIONS" ]; then
    echo "❌ Logger contract: print()/warn() directo — usa Lib/Logger.lua"
    echo "$VIOLATIONS"
    exit 1
fi
