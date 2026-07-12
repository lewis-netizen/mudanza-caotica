#!/usr/bin/env bash
# Nivel 1 — linting con Selene sobre archivos staged.
# Args: archivos staged (.lua).

[ "$#" -eq 0 ] && exit 0

selene generate-roblox-std >/dev/null 2>&1 || true
selene "$@"
