-- CarryManager
-- Lógica de transporte de objetos (§4.4, GAM-003, GAM-005).
-- ÚNICO punto server-side que conecta OnServerEvent (INV-001, DL-029) —
-- InteractObject es el único RemoteEvent cliente→servidor (§4.3).
-- Los cambios de estado se solicitan a ObjectManager — nunca se mutan aquí (§4.8).
--
-- Contrato de velocidad (DL-027): al iniciar un carry se guarda el WalkSpeed
-- vigente del jugador y se restaura ESE valor al soltar/entregar. Nunca se
-- sobrescribe con una constante. BASE_WALK_SPEED es solo fallback.
--
-- Lune-compatible (§4.6): servicios y módulos se resuelven dentro de funciones.

local CarryManager = {}

type CarryEntry = {
    instanceId: string,
    previousWalkSpeed: number,
    weld: any,
    player: any,
}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local active = false
local carriersByUserId: { [number]: CarryEntry } = {}
local userIdByInstance: { [string]: number } = {}
local connections: { any } = {}
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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("CarryManager")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getObjectManager()
    return require(game:GetService("ServerScriptService").Systems.ObjectManager)
end

local function getShared(moduleName: string)
    return require(game:GetService("ReplicatedStorage").Shared.Config[moduleName])
end

-- ─── Helpers ───────────────────────────────────────────────────────────────────

local function getCharacterParts(player: any): (any?, any?)
    local character = player.Character
    if not character then
        return nil, nil
    end
    return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function restoreWalkSpeed(entry: CarryEntry)
    local _, humanoid = getCharacterParts(entry.player)
    if not humanoid then
        return
    end
    local GameplayConfig = getShared("GameplayConfig")
    local speed = entry.previousWalkSpeed
    if type(speed) ~= "number" or speed <= 0 then
        speed = GameplayConfig.BASE_WALK_SPEED
    end
    humanoid.WalkSpeed = speed
end

--- Libera el carry sin cambiar estado del objeto — el caller decide el
--- estado final (TruckManager → delivered; drop → free).
local function releaseEntry(userId: number)
    local entry = carriersByUserId[userId]
    if not entry then
        return nil
    end
    carriersByUserId[userId] = nil
    userIdByInstance[entry.instanceId] = nil
    if entry.weld then
        pcall(function()
            entry.weld:Destroy()
        end)
    end
    restoreWalkSpeed(entry)
    return entry
end

-- ─── Pickup / Drop ─────────────────────────────────────────────────────────────

local function pickup(player: any, instanceId: string)
    local ObjectManager = getObjectManager()
    local part = ObjectManager.getObjectPart(instanceId)
    local hrp, humanoid = getCharacterParts(player)
    if not part or not hrp or not humanoid then
        return
    end

    local obj = ObjectManager.getObject(instanceId)
    local Catalog = require(game:GetService("ReplicatedStorage").Shared.Definitions.Objects)
    local def = if obj then Catalog.get(obj.ObjectId) else nil

    -- Objetos large requieren líder + soporte (GAM-006, Semana 2) — todavía
    -- no soportados por el slice. Se rechaza con log, sin cambiar estado.
    if def and def.Size == "large" then
        getLog():debug("Pickup de large rechazado — GAM-006 pendiente (%s)", instanceId)
        return
    end

    -- Posicionar frente al jugador y soldar — autoridad física del servidor (§4.2)
    part.Anchored = false
    part.CanCollide = false
    part.Massless = true
    part.CFrame = hrp.CFrame * CFrame.new(0, 0, -(part.Size.Z / 2 + 2))

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = part
    weld.Parent = part

    -- DL-027: guardar la velocidad vigente ANTES de modificarla
    local previousWalkSpeed = humanoid.WalkSpeed
    local multiplier = if def then def.Properties.carrySpeedMultiplier else nil
    if type(multiplier) == "number" and multiplier > 0 and multiplier < 1 then
        humanoid.WalkSpeed = previousWalkSpeed * multiplier
    end

    carriersByUserId[player.UserId] = {
        instanceId = instanceId,
        previousWalkSpeed = previousWalkSpeed,
        weld = weld,
        player = player,
    }
    userIdByInstance[instanceId] = player.UserId

    ObjectManager.setState(instanceId, "being_carried", player.UserId, nil)
    if recordStoryEvent then
        recordStoryEvent("CarryStarted", { instanceId = instanceId, playerId = player.UserId })
    end
end

local function drop(player: any)
    local entry = releaseEntry(player.UserId)
    if not entry then
        return
    end

    local ObjectManager = getObjectManager()
    local part = ObjectManager.getObjectPart(entry.instanceId)
    if part then
        -- El objeto queda en la posición actual del jugador (GAM-003)
        part.Anchored = true
        part.CanCollide = true
        part.Massless = false
    end

    ObjectManager.setState(entry.instanceId, "free", nil, nil)
    if recordStoryEvent then
        recordStoryEvent("ObjectDropped", { instanceId = entry.instanceId, playerId = player.UserId })
    end
end

-- ─── Validación de InteractObject (GAM-003) ────────────────────────────────────

local function onInteractObject(player: any, instanceId: any)
    if not active then
        return
    end
    -- Validación server-side: tipo, existencia, rango, estado (§4.2)
    if type(instanceId) ~= "string" then
        return
    end

    local ObjectManager = getObjectManager()
    local obj = ObjectManager.getObject(instanceId)
    if not obj then
        return
    end

    if obj.State == "being_carried" then
        -- Solo el líder puede soltar su propio objeto
        if obj.LeaderId == player.UserId then
            drop(player)
        end
        return
    end

    if obj.State ~= "free" then
        return
    end

    -- Un jugador solo carga un objeto a la vez
    if carriersByUserId[player.UserId] then
        return
    end

    -- Rango de interacción (GlobalConfig.MAX_INTERACT_RANGE)
    local part = ObjectManager.getObjectPart(instanceId)
    local hrp = getCharacterParts(player)
    if not part or not hrp then
        return
    end
    local GlobalConfig = getShared("GlobalConfig")
    if (part.Position - hrp.Position).Magnitude > GlobalConfig.MAX_INTERACT_RANGE then
        return
    end

    pickup(player, instanceId)
end

-- ─── API pública — llamada solo por RoundManager (§4.8) ────────────────────────

--- Inicia el sistema de carry. ctx.recordStoryEvent lo inyecta RoundManager
--- (inyección de dependencias — evita require circular con RoundManager).
function CarryManager.start(ctx: { recordStoryEvent: (string, any?) -> () })
    if active then
        return
    end
    active = true
    recordStoryEvent = ctx.recordStoryEvent

    local Networking = require(game:GetService("ReplicatedStorage").Shared.Lib.Networking)
    table.insert(connections, Networking.InteractObject.OnServerEvent:Connect(onInteractObject))

    -- Si un jugador se desconecta cargando un objeto, el objeto vuelve a free
    local Players = game:GetService("Players")
    table.insert(
        connections,
        Players.PlayerRemoving:Connect(function(player)
            if carriersByUserId[player.UserId] then
                drop(player)
            end
        end)
    )

    getLog():info("Carry activo — escuchando InteractObject")
end

--- Libera un carry sin marcar drop (usado por TruckManager al entregar).
--- No cambia el estado del objeto — eso lo decide el caller via ObjectManager.
function CarryManager.forceRelease(instanceId: string)
    local userId = userIdByInstance[instanceId]
    if userId then
        releaseEntry(userId)
    end
end

--- Detiene el sistema: desconecta y suelta todos los objetos cargados.
function CarryManager.stop()
    if not active then
        return
    end
    active = false
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    connections = {}
    for userId in pairs(carriersByUserId) do
        local entry = carriersByUserId[userId]
        if entry then
            drop(entry.player)
        end
    end
    recordStoryEvent = nil
end

--- Limpia el estado interno. Los Parts los limpia ObjectManager.reset().
function CarryManager.reset()
    carriersByUserId = {}
    userIdByInstance = {}
end

return CarryManager
