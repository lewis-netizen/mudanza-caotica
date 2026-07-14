-- Rules/StatRules.lua
-- Núcleo PURO de atribución de estadísticas. GameManager (la cáscara) le pasa
-- los StoryEvents del RoundSummary y recibe los deltas por jugador; luego los
-- aplica al PlayerData en memoria. Pura → testeable en Lune.
--
-- Módulo puro: sin acceso a game/servicios.

local StatRules = {}

export type PlayerDelta = {
    saved: number, -- ObjectsSaved a sumar
    byType: { [string]: number }, -- ObjectsSavedByType[objectId] a sumar (§2.4)
}

--- Calcula, a partir de los StoryEvents de la ronda, cuántos objetos entregó
--- cada jugador y de qué ObjectId. Solo los eventos ObjectDelivered con
--- playerId cuentan (atribución al líder que entregó — GAM-004, §2.5).
--- Indexado por ObjectId, nunca por nombre (§2.4).
--- Retorna { [playerId]: PlayerDelta }.
function StatRules.computeStatDeltas(storyEvents: { any }): { [number]: PlayerDelta }
    local deltas: { [number]: PlayerDelta } = {}

    for _, event in ipairs(storyEvents) do
        local data = event.Data
        if event.EventType == "ObjectDelivered" and data and type(data.playerId) == "number" then
            local playerId = data.playerId
            local delta = deltas[playerId]
            if not delta then
                delta = { saved = 0, byType = {} }
                deltas[playerId] = delta
            end
            delta.saved += 1
            if type(data.objectId) == "string" then
                delta.byType[data.objectId] = (delta.byType[data.objectId] or 0) + 1
            end
        end
    end

    return deltas
end

return StatRules
