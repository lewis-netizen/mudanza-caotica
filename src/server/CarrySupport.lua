-- CarrySupport
-- Vigilancia del contrato de soporte de objetos large (GAM-006/GAM-007).
-- Brazo de CarryManager: los entries siguen siendo PROPIEDAD de CarryManager
-- (§4.8) — este módulo los recibe por inyección (ctx, mismo patrón que
-- RoundManager → CarryManager) y ejecuta la vigilancia:
--   · búsqueda de soporte (shell sobre CarryRules.chooseSupport, puro)
--   · loop por tick con task.wait — NUNCA por frame (§4.12)
--   · la DECISIÓN por tick es pura (CarryRules.evaluateSupport, Lune)
--
-- Lune-compatible (§4.6): servicios y módulos se resuelven dentro de funciones.

local CarrySupport = {}

local SUPPORT_CHECK_INTERVAL = 0.25 -- s entre checks; el timeout se mide con os.clock

export type Ctx = {
    isActive: () -> boolean, -- el sistema de carry sigue activo
    entries: () -> { [number]: any }, -- userId → CarryEntry (propiedad de CarryManager)
    isBusy: (userId: number) -> boolean, -- ya carga como líder (no puede ser soporte)
    getCharacterRoot: (player: any) -> any?, -- HumanoidRootPart o nil
    applySupport: (userId: number, entry: any, supportId: number?) -> (), -- muta entry + setState
    drop: (player: any) -> (), -- suelta el objeto (efectos de CarryManager)
    recordStoryEvent: ((eventType: string, data: any?) -> ())?,
    log: any,
}

-- ─── Dependencias lazy ─────────────────────────────────────────────────────────

local function getCarryRules()
    return require(game:GetService("ReplicatedStorage").Shared.Rules.CarryRules)
end

local function getObjectManager()
    return require(game:GetService("ServerScriptService").Systems.ObjectManager)
end

local function getCatalog()
    return require(game:GetService("ReplicatedStorage").Shared.Definitions.Objects)
end

-- ─── Búsqueda de soporte ───────────────────────────────────────────────────────

--- El OTRO jugador más cercano dentro de supportRange de la posición del
--- objeto (GAM-006). Excluye al líder y a quienes ya cargan como líderes
--- (sus manos están ocupadas — Dependencia Social §2.1). Elección pura.
function CarrySupport.findSupportUserId(ctx: Ctx, leader: any, position: any, supportRange: number): number?
    local Players = game:GetService("Players")
    local candidates = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= leader and not ctx.isBusy(other.UserId) then
            local hrp = ctx.getCharacterRoot(other)
            if hrp then
                local delta = hrp.Position - position
                table.insert(candidates, { id = other.UserId, distSq = delta:Dot(delta) })
            end
        end
    end
    return getCarryRules().chooseSupport(candidates, supportRange * supportRange)
end

-- ─── Tick de vigilancia (GAM-007) ──────────────────────────────────────────────

local function checkTick(ctx: Ctx, now: number)
    local Players = game:GetService("Players")
    local ObjectManager = getObjectManager()
    local Catalog = getCatalog()
    local toDrop: { any } = {}

    for userId, entry in pairs(ctx.entries()) do
        local obj = ObjectManager.getObject(entry.instanceId)
        local def = if obj then Catalog.get(obj.ObjectId) else nil
        local part = ObjectManager.getObjectPart(entry.instanceId)
        if not def or def.Size ~= "large" or not part then
            continue
        end
        local supportRange = def.Properties.supportRange
        local timeout = def.Properties.supportTimeout
        if type(supportRange) ~= "number" or type(timeout) ~= "number" then
            continue
        end

        local currentInRange = false
        if entry.supportId then
            local supportPlayer = Players:GetPlayerByUserId(entry.supportId)
            local hrp = if supportPlayer then ctx.getCharacterRoot(supportPlayer) else nil
            if hrp then
                currentInRange = (hrp.Position - part.Position).Magnitude <= supportRange
            end
        end
        local replacementId: number? = nil
        if not currentInRange then
            replacementId = CarrySupport.findSupportUserId(ctx, entry.player, part.Position, supportRange)
        end

        local action, lostSince = getCarryRules().evaluateSupport({
            currentSupportInRange = currentInRange,
            replacementId = replacementId,
            lostSince = entry.lostSince,
            now = now,
            timeout = timeout,
        })

        local wasLost = entry.lostSince ~= nil
        entry.lostSince = lostSince

        if action == "reassign" then
            ctx.applySupport(userId, entry, replacementId)
        end

        if (action == "keep" or action == "reassign") and wasLost then
            -- El refuerzo llegó antes del timeout — el carry continúa (GAM-007)
            if ctx.recordStoryEvent then
                ctx.recordStoryEvent("SupportRestored", { instanceId = entry.instanceId })
            end
        elseif action == "grace" and not wasLost then
            if ctx.recordStoryEvent then
                ctx.recordStoryEvent("SupportLost", { instanceId = entry.instanceId })
            end
        elseif action == "drop" then
            -- No mutar entries durante la iteración — se aplica después
            table.insert(toDrop, entry.player)
        end
    end

    for _, player in ipairs(toDrop) do
        ctx.log:info("Soporte perdido más de la tolerancia — el objeto cae (GAM-007)")
        ctx.drop(player)
    end
end

-- ─── Loop ──────────────────────────────────────────────────────────────────────

--- Arranca el loop de vigilancia. La cancelación es por ctx.isActive() — el
--- caller (CarryManager.stop) apaga el flag y el thread muere solo.
function CarrySupport.start(ctx: Ctx)
    task.spawn(function()
        while ctx.isActive() do
            task.wait(SUPPORT_CHECK_INTERVAL)
            if not ctx.isActive() then
                return
            end
            checkTick(ctx, os.clock())
        end
    end)
end

return CarrySupport
