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
    supportId: number?, -- soporte actual si el objeto es large (GAM-006)
    lostSince: number?, -- inicio de la pérdida de soporte (os.clock), nil = con soporte (GAM-007)
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

local ObjectState: any = nil
local function states()
    if not ObjectState then
        ObjectState = require(game:GetService("ReplicatedStorage").Shared.Constants.ObjectState)
    end
    return ObjectState
end

local function getShared(moduleName: string)
    return require(game:GetService("ReplicatedStorage").Shared.Config[moduleName])
end

local function getCarryRules()
    return require(game:GetService("ReplicatedStorage").Shared.Rules.CarryRules)
end

-- ─── Helpers ───────────────────────────────────────────────────────────────────

local function getCharacterParts(player: any): (any?, any?)
    local character = player.Character
    if not character then
        return nil, nil
    end
    return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function getCarrySupport()
    return require(game:GetService("ServerScriptService").Systems.CarrySupport)
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

local function pickup(player: any, instanceId: string, supportId: number?)
    local ObjectManager = getObjectManager()
    local part = ObjectManager.getObjectPart(instanceId)
    local hrp, humanoid = getCharacterParts(player)
    if not part or not hrp or not humanoid then
        return
    end

    local obj = ObjectManager.getObject(instanceId)
    local Catalog = require(game:GetService("ReplicatedStorage").Shared.Definitions.Objects)
    local def = if obj then Catalog.get(obj.ObjectId) else nil

    -- La validación (incluido el soporte de large, GAM-006) ya la decidió
    -- CarryRules — pickup solo se llama con una decisión "pickup" válida.

    -- Posicionar frente al jugador y soldar — autoridad física del servidor (§4.2)
    part.Anchored = false
    part.CanCollide = false
    part.Massless = true
    part.CFrame = hrp.CFrame * CFrame.new(0, 0, -(part.Size.Z / 2 + 2))

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = part
    weld.Parent = part

    -- DL-027: guardar la velocidad vigente ANTES de modificarla; el cálculo
    -- del multiplicador es puro (CarryRules.carrySpeed).
    local previousWalkSpeed = humanoid.WalkSpeed
    local multiplier = if def then def.Properties.carrySpeedMultiplier else nil
    humanoid.WalkSpeed = getCarryRules().carrySpeed(previousWalkSpeed, multiplier)

    carriersByUserId[player.UserId] = {
        instanceId = instanceId,
        previousWalkSpeed = previousWalkSpeed,
        weld = weld,
        player = player,
        supportId = supportId,
    }
    userIdByInstance[instanceId] = player.UserId

    ObjectManager.setState(instanceId, states().BEING_CARRIED, player.UserId, supportId)
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

    ObjectManager.setState(entry.instanceId, states().FREE, nil, nil)
    if recordStoryEvent then
        recordStoryEvent("ObjectDropped", { instanceId = entry.instanceId, playerId = player.UserId })
    end
end

-- ─── Contexto para CarrySupport (GAM-006/007) ──────────────────────────────────
-- La vigilancia del soporte vive en CarrySupport (responsabilidad propia);
-- los entries siguen siendo propiedad de este módulo (§4.8) — se delegan por
-- inyección (mismo patrón que RoundManager → CarryManager).

local function buildSupportCtx(): any
    return {
        isActive = function()
            return active
        end,
        entries = function()
            return carriersByUserId
        end,
        isBusy = function(userId: number)
            return carriersByUserId[userId] ~= nil
        end,
        getCharacterRoot = function(player: any)
            local hrp = getCharacterParts(player)
            return hrp
        end,
        applySupport = function(userId: number, entry: any, supportId: number?)
            entry.supportId = supportId
            getObjectManager().setState(entry.instanceId, states().BEING_CARRIED, userId, supportId)
        end,
        drop = drop,
        recordStoryEvent = recordStoryEvent,
        log = getLog(),
    }
end

-- ─── Validación de InteractObject (GAM-003) ────────────────────────────────────

local function onInteractObject(player: any, payload: any)
    if not active then
        return
    end
    -- El payload de InteractObject es `{ instanceId }` (§4.3), no el string
    -- suelto. El CarryManager original (slice #31) lo trataba como string, pero
    -- nadie lo disparaba (hueco de QA-001) hasta InteractionController (GAM-010),
    -- que sí sigue el contrato — de ahí el desajuste. Se extrae aquí.
    local instanceId = if type(payload) == "table" then payload.instanceId else payload
    if type(instanceId) ~= "string" then
        return
    end

    -- Cáscara effectful: reúne los hechos del mundo (§4.2) y delega la DECISIÓN
    -- en el núcleo puro CarryRules (testeado en Lune). Luego ejecuta el efecto.
    local ObjectManager = getObjectManager()
    local obj = ObjectManager.getObject(instanceId)
    local part = ObjectManager.getObjectPart(instanceId)
    local hrp = getCharacterParts(player)

    local Catalog = require(game:GetService("ReplicatedStorage").Shared.Definitions.Objects)
    local def = if obj then Catalog.get(obj.ObjectId) else nil

    local inRange = false
    if part and hrp then
        local maxRange = getShared("GlobalConfig").MAX_INTERACT_RANGE
        inRange = (part.Position - hrp.Position).Magnitude <= maxRange
    end

    -- large: buscar soporte ANTES de decidir — el carry no comienza sin él
    -- (GAM-006). supportId viaja en ObjectStateChanged (§4.3).
    local isLarge = def ~= nil and def.Size == "large"
    local supportId: number? = nil
    if isLarge and part then
        local supportRange = def.Properties.supportRange
        if type(supportRange) == "number" then
            supportId = getCarrySupport().findSupportUserId(buildSupportCtx(), player, part.Position, supportRange)
        end
    end

    local decision = getCarryRules().decideInteraction({
        exists = obj ~= nil,
        state = if obj then obj.State else "",
        leaderId = if obj then obj.LeaderId else nil,
        isLarge = isLarge,
        supportAvailable = supportId ~= nil,
        alreadyCarrying = carriersByUserId[player.UserId] ~= nil,
        inRange = inRange,
        playerId = player.UserId,
    }, states())

    if decision == "drop" then
        drop(player)
    elseif decision == "pickup" then
        pickup(player, instanceId, supportId)
    end
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

    -- Vigilancia de soporte (GAM-007) — CarrySupport corre el loop; la
    -- cancelación es por el flag `active` via ctx.isActive
    getCarrySupport().start(buildSupportCtx())

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

--- InstanceId que el jugador (userId) carga actualmente, o nil. Usado por
--- TruckManager: el objeto cargado se sostiene a la altura del torso y no toca
--- una TruckZone a ras de suelo, pero el personaje sí — la entrega se resuelve
--- por el jugador que entra a la zona, no por el objeto tocándola.
function CarryManager.getCarriedInstanceId(userId: number): string?
    local entry = carriersByUserId[userId]
    return if entry then entry.instanceId else nil
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
