#!/usr/bin/env bash
# Nivel 2 — src/server/ no requiere módulos de src/client/. §4.2.
# Args: archivos staged (.lua) de src/server.

[ "$#" -eq 0 ] && exit 0

VIOLATIONS=$(grep -nH "require.*[Cc]lient\|require.*StarterPlayer" "$@" || true)

if [ -n "$VIOLATIONS" ]; then
    echo "❌ Layer violation: src/server/ requires src/client/ module"
    echo "$VIOLATIONS"
    echo "See AI_CONTEXT_MASTER §4.2"
    exit 1
fi
