#!/usr/bin/env bash
# INV-001 — OnClientEvent:Connect solo en ClientStateManager.lua (cliente);
# OnServerEvent:Connect solo en CarryManager.lua (servidor). §4.10, DL-029.
# Args: archivos staged (.lua).

[ "$#" -eq 0 ] && exit 0

V1=$(grep -nH "\.OnClientEvent:Connect" "$@" | grep -v "ClientStateManager.lua" | grep -v "Networking.lua" || true)
V2=$(grep -nH "\.OnServerEvent:Connect" "$@" | grep -v "CarryManager.lua" | grep -v "Networking.lua" || true)

if [ -n "$V1$V2" ]; then
    echo "❌ INV-001: Networking connection outside its single owner"
    if [ -n "$V1" ]; then echo "$V1"; fi
    if [ -n "$V2" ]; then echo "$V2"; fi
    echo "OnClientEvent → ClientStateManager.lua | OnServerEvent → CarryManager.lua"
    echo "See AI_CONTEXT_MASTER §4.10"
    exit 1
fi
