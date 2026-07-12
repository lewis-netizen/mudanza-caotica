#!/usr/bin/env bash
# §2.4 — .Name no se usa como condición lógica. La lógica opera sobre IDs.
# Args: archivos staged (.lua).

[ "$#" -eq 0 ] && exit 0

VIOLATIONS=$(grep -EnH '\.Name\s*[=~]=\s*"' "$@" || true)

if [ -n "$VIOLATIONS" ]; then
    echo "❌ §2.4: .Name used as logical condition — use IDs"
    echo "$VIOLATIONS"
    exit 1
fi
