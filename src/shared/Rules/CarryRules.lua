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
    supportAvailable: boolean?, -- large: hay otro jugador en supportRange (GAM-006)
    alreadyCarrying: boolean, -- el jugador ya carga otro objeto
    inRange: boolean, -- dentro de MAX_INTERACT_RANGE
    playerId: number, -- UserId del jugador que interactúa
}

-- Acción resultante que la cáscara debe ejecutar.
export type Decision = "pickup" | "drop" | "ignore"

--- Decide qué hacer ante un InteractObject, dado el estado del mundo.
--- Regla (GAM-003/GAM-006, §4.2): validación server-side de tipo/existencia/
--- rango/estado.
--- - objeto being_carried por este jugador (líder) → drop
--- - objeto being_carried por otro → ignore (solo el líder suelta)
--- - objeto free, en rango, jugador libre, no large → pickup
--- - large: además requiere soporte disponible (otro jugador en supportRange,
---   Dependencia Social §2.1) — sin soporte → ignore
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

    if facts.alreadyCarrying or not facts.inRange then
        return "ignore"
    end

    -- large: el carry no comienza sin soporte (GAM-006)
    if facts.isLarge and not facts.supportAvailable then
        return "ignore"
    end

    return "pickup"
end

--- Elige el jugador de soporte: el candidato más cercano dentro de rango.
--- `candidates` = { { id, distSq } } (otros jugadores, nunca el líder).
--- Retorna su id, o nil si ninguno está en rango. Puro (GAM-006/GAM-007).
function CarryRules.chooseSupport(candidates: { { id: number, distSq: number } }, rangeSq: number): number?
    local bestId: number? = nil
    local bestSq = rangeSq
    for _, candidate in ipairs(candidates) do
        if candidate.distSq <= bestSq then
            bestSq = candidate.distSq
            bestId = candidate.id
        end
    end
    return bestId
end

export type SupportFacts = {
    currentSupportInRange: boolean, -- el soporte actual sigue dentro de supportRange
    replacementId: number?, -- otro candidato en rango (chooseSupport), si lo hay
    lostSince: number?, -- timestamp del inicio de la pérdida (nil = con soporte)
    now: number,
    timeout: number, -- ObjectDefinition.Properties.supportTimeout
}

--- Evalúa el soporte de un carry large en un tick del loop (GAM-007).
--- Retorna (acción, lostSince'):
---   "keep"     el soporte actual sigue válido            → lostSince' = nil
---   "reassign" otro jugador en rango toma el relevo      → lostSince' = nil
---   "grace"    sin soporte, dentro de la tolerancia      → lostSince' arranca/persiste
---   "drop"     sin soporte por ≥ timeout → el objeto cae
--- Si el soporte vuelve (keep/reassign) antes del timeout, el carry continúa
--- sin interrupción — la tolerancia se resetea. Puro.
function CarryRules.evaluateSupport(facts: SupportFacts): (string, number?)
    if facts.currentSupportInRange then
        return "keep", nil
    end
    if facts.replacementId ~= nil then
        return "reassign", nil
    end
    local lostSince = facts.lostSince or facts.now
    if facts.now - lostSince >= facts.timeout then
        return "drop", lostSince
    end
    return "grace", lostSince
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
