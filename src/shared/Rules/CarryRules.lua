-- Rules/CarryRules.lua
-- Núcleo PURO de decisión de transporte (functional core / imperative shell).
-- CarryManager (la cáscara effectful) obtiene los hechos del mundo (estado del
-- objeto, distancia, si el jugador ya carga) y delega la DECISIÓN aquí; luego
-- ejecuta el efecto. Esta separación hace la validación testeable en Lune sin
-- DataModel — CarryManager es effect-heavy y no puede cargarse aislado.
--
-- Módulo puro: sin acceso a game/servicios. Lune-compatible por construcción.

local CarryRules = {}

export type InteractionFacts = {
    exists: boolean, -- el objeto existe en ObjectManager
    state: string, -- ObjectState del objeto (free/being_carried/delivered)
    leaderId: number?, -- líder actual si being_carried
    isLarge: boolean, -- def.Size == "large"
    alreadyCarrying: boolean, -- el jugador ya carga otro objeto
    inRange: boolean, -- dentro de MAX_INTERACT_RANGE
    playerId: number, -- UserId del jugador que interactúa
}

-- Acción resultante que la cáscara debe ejecutar.
export type Decision = "pickup" | "drop" | "ignore"

--- Decide qué hacer ante un InteractObject, dado el estado del mundo.
--- Regla (GAM-003, §4.2): validación server-side de tipo/existencia/rango/estado.
--- - objeto being_carried por este jugador (líder) → drop
--- - objeto being_carried por otro → ignore (solo el líder suelta)
--- - objeto free, en rango, jugador libre, no large → pickup
--- - large → ignore (líder/soporte es GAM-006, Semana 2)
--- - cualquier otro caso → ignore
function CarryRules.decideInteraction(
    facts: InteractionFacts,
    states: { FREE: string, BEING_CARRIED: string }
): Decision
    if not facts.exists then
        return "ignore"
    end

    if facts.state == states.BEING_CARRIED then
        if facts.leaderId == facts.playerId then
            return "drop"
        end
        return "ignore"
    end

    if facts.state ~= states.FREE then
        return "ignore"
    end

    -- free: requiere rango, jugador libre, y que no sea large (GAM-006 pendiente)
    if facts.alreadyCarrying or not facts.inRange or facts.isLarge then
        return "ignore"
    end

    return "pickup"
end

--- Velocidad efectiva al cargar: aplica el multiplicador solo si es válido
--- (número en (0,1)). Devuelve la velocidad previa intacta si no aplica.
--- El caller decide qué hacer con el resultado (DL-027: nunca pisa con constante).
function CarryRules.carrySpeed(previousWalkSpeed: number, multiplier: any): number
    if type(multiplier) == "number" and multiplier > 0 and multiplier < 1 then
        return previousWalkSpeed * multiplier
    end
    return previousWalkSpeed
end

return CarryRules
