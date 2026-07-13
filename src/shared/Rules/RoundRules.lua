-- Rules/RoundRules.lua
-- Núcleo PURO de la lógica de ronda. RoundManager (la cáscara) obtiene el
-- estado de los módulos y delega el cálculo aquí. Pura → testeable en Lune.
--
-- Módulo puro: sin acceso a game/servicios.

local RoundRules = {}

--- Comentario narrativo del servidor por umbral de resultado (UI-003).
--- 3 umbrales; sin puntuaciones ni ranking (§3.5). Determinista.
function RoundRules.buildClientComment(saved: number, lost: number): string
    local total = saved + lost
    if total == 0 then
        return "No había nada que mudar. El camión se fue igual."
    end
    local ratio = saved / total
    if ratio >= 0.8 then
        return "El camión se fue lleno. Mudanza de profesionales — casi."
    elseif ratio >= 0.4 then
        return "Se salvó lo importante. Probablemente."
    end
    return "El camión se fue casi vacío. El vecino sigue riéndose."
end

--- Cuenta objetos NO entregados dado el snapshot de objetos de la ronda.
--- `objects` es una lista de { State: string }. Puro.
function RoundRules.countLost(objects: { { State: string } }, deliveredState: string): number
    local lost = 0
    for _, obj in ipairs(objects) do
        if obj.State ~= deliveredState then
            lost += 1
        end
    end
    return lost
end

return RoundRules
