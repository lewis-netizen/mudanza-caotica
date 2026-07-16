-- Rules/NPCRules.lua
-- Núcleo PURO de la patrulla del NPC (WLD-004, §4.13). NPCManager (shell)
-- reúne los nodos tagueados y ejecuta los Tweens; el ORDEN y el AVANCE de la
-- patrulla se deciden aquí — testeable en Lune sin DataModel.
--
-- Módulo puro: sin acceso a game/servicios. Lune-compatible por construcción.

local NPCRules = {}

export type NodeRef = { index: number, key: any }

--- Ordena los nodos de patrulla por NodeIndex ascendente y retorna sus keys.
--- Índices duplicados o no numéricos se descartan (el layout los reporta en
--- runtime como warning — aquí solo se decide el orden). Puro.
function NPCRules.orderedPatrol(nodes: { NodeRef }): { any }
    local seen: { [number]: boolean } = {}
    local valid: { NodeRef } = {}
    for _, node in ipairs(nodes) do
        if type(node.index) == "number" and not seen[node.index] then
            seen[node.index] = true
            table.insert(valid, node)
        end
    end
    table.sort(valid, function(a, b)
        return a.index < b.index
    end)
    local keys = {}
    for _, node in ipairs(valid) do
        table.insert(keys, node.key)
    end
    return keys
end

--- Siguiente paso de la patrulla: avanza circularmente (1→2→…→n→1). Puro.
function NPCRules.nextStep(current: number, count: number): number
    if count <= 0 then
        return 0
    end
    return (current % count) + 1
end

return NPCRules
