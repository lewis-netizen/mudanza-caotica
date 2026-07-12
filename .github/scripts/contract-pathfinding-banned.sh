#!/usr/bin/env bash
# §4.6 — PathfindingService prohibido. Usar TweenService + NPCNodes.
# Args: archivos staged (.lua).

[ "$#" -eq 0 ] && exit 0

VIOLATIONS=$(grep -nH "PathfindingService" "$@" || true)

if [ -n "$VIOLATIONS" ]; then
    echo "❌ §4.6: PathfindingService found — use TweenService + NPCNodes"
    echo "$VIOLATIONS"
    exit 1
fi
