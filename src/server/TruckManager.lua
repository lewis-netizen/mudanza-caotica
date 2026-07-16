-- TruckManager
-- Zona de entrega y conteo de objetos salvados (§4.4, GAM-004).
-- La entrega se detecta server-side via Part.Touched — nunca por RemoteEvent
-- del cliente (§4.3). Solo objetos being_carried cuentan como entrega.
--
-- Lune-compatible (§4.6): servicios y módulos se resuelven dentro de funciones.

local TruckManager = {}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local active = false
local deliveredCount = 0
local touchedConnection: any = nil
local recordStoryEvent: ((eventType: string, data: any?) -> ())? = nil

-- ─── Dependencias lazy ─────────────────────────────────────────────────────────

local NOOP_LOG = {
    debug = function() end,
    info = function() end,
    warn = function() end,
    error = function() end,
}

local log: any = nil
local function getLog()
    if log then
        return log
    end
    local ok, result = pcall(function()
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("TruckManager")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getObjectManager()
    return require(game:GetService("ServerScriptService").Systems.ObjectManager)
end

local function getCarryManager()
    return require(game:GetService("ServerScriptService").Systems.CarryManager)
end

local ObjectState: any = nil
local function states()
    if not ObjectState then
        ObjectState = require(game:GetService("ReplicatedStorage").Shared.Constants.ObjectState)
    end
    return ObjectState
end

-- ─── Entrega ───────────────────────────────────────────────────────────────────

--- Resuelve el InstanceId subiendo desde la parte tocada. Un objeto puede
--- ser un Model multi-part (PrefabRegistry, DL-031): el Attribute vive en la
--- raíz, no necesariamente en la parte que toca la zona.
local function resolveInstanceId(hit: any): string?
    local node = hit
    local depth = 0
    while node and depth < 5 do
        local id = node:GetAttribute("InstanceId")
        if type(id) == "string" then
            return id
        end
        node = node.Parent
        depth += 1
    end
    return nil
end

local function onZoneTouched(hit: any)
    if not active then
        return
    end

    -- El objeto puede tocar la zona directamente (Model bajo), pero lo habitual
    -- es que se sostenga a la altura del torso y NO toque una zona a ras de
    -- suelo — el personaje del jugador sí la toca. En ese caso se entrega lo que
    -- ese jugador carga (§4.4, GAM-004: solo being_carried se entrega).
    local instanceId = resolveInstanceId(hit)
    if not instanceId then
        local Players = game:GetService("Players")
        local character = if hit then hit:FindFirstAncestorOfClass("Model") else nil
        local player = if character then Players:GetPlayerFromCharacter(character) else nil
        if player then
            instanceId = getCarryManager().getCarriedInstanceId(player.UserId)
        end
    end
    if not instanceId then
        return
    end

    local ObjectManager = getObjectManager()
    local obj = ObjectManager.getObject(instanceId)
    -- Solo objetos being_carried se entregan — un objeto free dentro de la
    -- zona no cuenta (GAM-004)
    if not obj or obj.State ~= states().BEING_CARRIED then
        return
    end

    local leaderId = obj.LeaderId

    -- Orden: liberar el weld (restaura WalkSpeed), luego el cambio de estado
    -- (delivered destruye el Part — GAM-004: desaparece del Workspace)
    getCarryManager().forceRelease(instanceId)
    ObjectManager.setState(instanceId, states().DELIVERED, nil, nil)
    deliveredCount += 1

    pcall(function()
        local Networking = require(game:GetService("ReplicatedStorage").Shared.Lib.Networking)
        Networking.DeliverObject:FireAllClients({ instanceId = instanceId })
    end)

    if recordStoryEvent then
        recordStoryEvent("ObjectDelivered", {
            instanceId = instanceId,
            objectId = obj.ObjectId,
            playerId = leaderId,
        })
    end

    getLog():info("Entrega #%d — %s (%s)", deliveredCount, instanceId, obj.ObjectId)
end

-- ─── API pública — llamada solo por RoundManager (§4.8) ────────────────────────

--- Conecta la zona de entrega (Part con Tag "TruckZone" — contrato §4.4).
function TruckManager.start(ctx: { recordStoryEvent: (string, any?) -> () })
    if active then
        return
    end
    active = true
    recordStoryEvent = ctx.recordStoryEvent

    local CollectionService = game:GetService("CollectionService")
    local zones = CollectionService:GetTagged("TruckZone")
    if #zones == 0 then
        getLog():warn("Sin Part con Tag TruckZone — no habrá entregas (ver §4.4)")
        return
    end

    touchedConnection = zones[1].Touched:Connect(onZoneTouched)
    getLog():info("Zona de entrega activa")
end

--- Retorna el conteo de entregas de la ronda actual.
function TruckManager.getDeliveredCount(): number
    return deliveredCount
end

--- Desconecta la zona de entrega.
function TruckManager.stop()
    active = false
    if touchedConnection then
        pcall(function()
            touchedConnection:Disconnect()
        end)
        touchedConnection = nil
    end
    recordStoryEvent = nil
end

--- Limpia el conteo sin residuos.
function TruckManager.reset()
    TruckManager.stop()
    deliveredCount = 0
end

return TruckManager
