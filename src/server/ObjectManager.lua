-- ObjectManager
-- Spawn, estados y tracking de ObjectInstances (§4.4, GAM-002).
-- Único propietario de ObjectInstance.State (§4.8) — todos los módulos
-- solicitan cambios aquí, nunca mutan estado directamente.
-- No mueve objetos: CarryManager posee el transporte.
--
-- Lune-compatible (§4.6): todo acceso a game/servicios ocurre dentro de
-- funciones. La lógica de estados es pura y se testea en ObjectManager.spec.

local ObjectManager = {}

export type ObjectInstance = {
    InstanceId: string,
    ObjectId: string,
    State: string, -- "free" | "being_carried" | "delivered"
    LeaderId: number?,
    SupportId: number?,
}

local VALID_STATES = {
    free = true,
    being_carried = true,
    delivered = true,
}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local instances: { [string]: ObjectInstance } = {}
local parts: { [string]: any } = {}
local containerFolder: any = nil
local deliveredCount = 0
local spawnSerial = 0

-- ─── Logger lazy (silencioso fuera de Roblox) ──────────────────────────────────

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
    local ok, instance = pcall(function()
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("ObjectManager")
    end)
    log = if ok then instance else NOOP_LOG
    return log
end

-- ─── Replicación de estado ─────────────────────────────────────────────────────

local function fireStateChanged(instance: ObjectInstance)
    -- pcall: en entorno Lune (specs) no hay DataModel — el cambio de estado
    -- puro sigue siendo válido aunque no haya replicación.
    pcall(function()
        local Networking = require(game:GetService("ReplicatedStorage").Shared.Lib.Networking)
        Networking.ObjectStateChanged:FireAllClients({
            instanceId = instance.InstanceId,
            objectId = instance.ObjectId,
            state = instance.State,
            leaderId = instance.LeaderId,
            supportId = instance.SupportId,
        })
    end)
end

-- ─── Spawn ─────────────────────────────────────────────────────────────────────

local function spawnInstance(def: any, point: any, container: any, config: any)
    spawnSerial += 1
    local instanceId = string.format("obj_%04d", spawnSerial)

    local dims = config.PLACEHOLDER_OBJECT_SIZES[def.Size] or { 2, 2, 2 }
    local rgb = config.PLACEHOLDER_OBJECT_COLORS[def.Size] or { 200, 200, 200 }
    local jitterRange = config.MIN_SPAWN_DISTANCE

    local part = Instance.new("Part")
    part.Size = Vector3.new(dims[1], dims[2], dims[3])
    part.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Position = point.Position
        + Vector3.new((math.random() - 0.5) * jitterRange, dims[2] / 2 + 0.5, (math.random() - 0.5) * jitterRange)
    part:SetAttribute("InstanceId", instanceId)
    part:SetAttribute("ObjectId", def.ObjectId)
    part.Parent = container

    local CollectionService = game:GetService("CollectionService")
    CollectionService:AddTag(part, "CarryObject")

    local instance: ObjectInstance = {
        InstanceId = instanceId,
        ObjectId = def.ObjectId,
        State = "free",
        LeaderId = nil,
        SupportId = nil,
    }
    instances[instanceId] = instance
    parts[instanceId] = part
    fireStateChanged(instance)
end

--- Spawnea los objetos de la ronda en los Parts con Tag "ObjectSpawn" (§4.4).
--- Cantidades por Size desde GameplayConfig.OBJECT_COUNTS.
function ObjectManager.initialize()
    ObjectManager.reset()

    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Catalog = require(ReplicatedStorage.Shared.Definitions.Objects)
    local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

    local spawnPoints = CollectionService:GetTagged("ObjectSpawn")
    if #spawnPoints == 0 then
        getLog():warn("Sin Parts con Tag ObjectSpawn — no se spawnean objetos (ver §4.4)")
        return
    end

    -- Barajar los puntos de spawn (Fisher–Yates) para Entropía Espacial (§3.4)
    local shuffled = table.clone(spawnPoints)
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    local container = Instance.new("Folder")
    container.Name = "RoundObjects"
    container.Parent = game:GetService("Workspace")
    containerFolder = container

    local pointIndex = 0
    local total = 0
    for size, count in pairs(GameplayConfig.OBJECT_COUNTS) do
        local defs = Catalog.getBySize(size)
        if #defs == 0 then
            getLog():warn("Sin ObjectDefinitions para Size %s — se omite", size)
            continue
        end
        for _ = 1, count do
            local def = defs[math.random(#defs)]
            pointIndex += 1
            local point = shuffled[((pointIndex - 1) % #shuffled) + 1]
            spawnInstance(def, point, container, GameplayConfig)
            total += 1
        end
    end

    getLog():info("Spawn completo — %d objetos en %d puntos", total, #shuffled)
end

-- ─── API de estados ────────────────────────────────────────────────────────────

--- Solicita un cambio de estado. Retorna true si se aplicó.
--- state "delivered" destruye el Part (GAM-004: el objeto desaparece).
function ObjectManager.setState(instanceId: string, state: string, leaderId: number?, supportId: number?): boolean
    local instance = instances[instanceId]
    if not instance then
        getLog():debug("setState ignorado — InstanceId inexistente: %s", tostring(instanceId))
        return false
    end
    if not VALID_STATES[state] then
        getLog():warn("setState rechazado — estado inválido: %s", tostring(state))
        return false
    end

    instance.State = state
    instance.LeaderId = leaderId
    instance.SupportId = supportId

    if state == "delivered" then
        deliveredCount += 1
        local part = parts[instanceId]
        if part then
            parts[instanceId] = nil
            pcall(function()
                part:Destroy()
            end)
        end
    end

    fireStateChanged(instance)
    return true
end

-- ─── API de lectura ────────────────────────────────────────────────────────────
-- Todo lo que sale es copia — solo ObjectManager muta sus tablas (§4.8).

--- Retorna una copia del ObjectInstance, o nil si no existe.
function ObjectManager.getObject(instanceId: string): ObjectInstance?
    local instance = instances[instanceId]
    return if instance then table.clone(instance) else nil
end

--- Retorna el Part en Workspace del objeto, o nil.
function ObjectManager.getObjectPart(instanceId: string): any?
    return parts[instanceId]
end

--- Retorna un array con los InstanceIds de los objetos en estado free.
function ObjectManager.getFreeObjects(): { string }
    local free = {}
    for instanceId, instance in pairs(instances) do
        if instance.State == "free" then
            table.insert(free, instanceId)
        end
    end
    return free
end

--- Retorna un array de copias de todos los ObjectInstances.
function ObjectManager.getAllObjects(): { ObjectInstance }
    local all = {}
    for _, instance in pairs(instances) do
        table.insert(all, table.clone(instance))
    end
    return all
end

--- Retorna el número de objetos entregados desde el último reset.
function ObjectManager.getDeliveredCount(): number
    return deliveredCount
end

-- ─── Reset ─────────────────────────────────────────────────────────────────────

--- Limpia todo el estado interno y destruye los Parts spawneados.
--- Idempotente — puede llamarse múltiples veces sin error.
function ObjectManager.reset()
    for _, part in pairs(parts) do
        pcall(function()
            part:Destroy()
        end)
    end
    if containerFolder then
        pcall(function()
            containerFolder:Destroy()
        end)
        containerFolder = nil
    end
    parts = {}
    instances = {}
    deliveredCount = 0
    spawnSerial = 0
end

return ObjectManager
