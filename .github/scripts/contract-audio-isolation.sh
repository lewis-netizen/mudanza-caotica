#!/usr/bin/env bash
# INV-002 — sound:Play()/:Stop()/:Pause() no en módulos de gameplay. §4.9.
# Los tweens se excluyen: TweenService es el mecanismo mandatado para el
# NPC (§4.4) y tween:Play() no es audio/VFX.
# Args: archivos staged (.lua) de src/server y src/shared.

[ "$#" -eq 0 ] && exit 0

VIOLATIONS=$(grep -nH ":Play()\|:Stop()\|:Pause()" "$@" | grep -v "AudioManager\|VFXManager\|[Tt]ween" || true)

if [ -n "$VIOLATIONS" ]; then
    echo "❌ INV-002: Direct audio/VFX call in gameplay module"
    echo "$VIOLATIONS"
    echo "See AI_CONTEXT_MASTER §4.9"
    exit 1
fi
