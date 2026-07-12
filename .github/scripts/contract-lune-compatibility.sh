#!/usr/bin/env bash
# Nivel 1 — §4.6: globals de Roblox no en scope de módulo (compatibilidad
# Lune). Corre el checker completo y filtra los archivos staged que fallen.
# Args: archivos staged (.lua) de src/shared y src/server.

[ "$#" -eq 0 ] && exit 0

OUTPUT=$(lune run lune/check-compatibility.luau 2>&1 || true)

FOUND=""
for file in "$@"; do
    case "$file" in
        *.spec.lua) continue ;;
    esac
    # Normalizar separadores de Windows para el match contra el reporte.
    # Solo cuentan las líneas de la sección de INCOMPATIBLES (❌) — el
    # reporte también lista los módulos compatibles (✅) y un match plano
    # daría falso positivo con cualquier archivo compatible staged.
    normalized=$(echo "$file" | tr '\\' '/')
    if echo "$OUTPUT" | grep -q "❌.*$normalized"; then
        FOUND="${FOUND}
  $normalized"
    fi
done

if [ -n "$FOUND" ]; then
    echo "❌ Lune compatibility: Roblox globals at module scope in staged files:"
    echo "$FOUND"
    echo ""
    echo "Move Roblox service access inside functions (inyección de dependencias)."
    echo "Full report: lune run lune/check-compatibility.luau"
    echo "See AI_CONTEXT_MASTER §4.6"
    exit 1
fi
