-- PrefabRegistry
-- Resuelve ObjectId → representación física (DL-031). Única capa que conoce
-- ServerStorage/ObjectPrefabs. Cierra el hueco del contrato entre
-- ObjectDefinition (identidad/datos) y el asset real (apariencia):
--
--   ObjectDefinition → PrefabRegistry → ServerStorage/ObjectPrefabs
--                                     ↘ placeholder generado (fallback)
--
-- CONTRATO Arte → PrefabRegistry (§4.4):
--   ServerStorage/ObjectPrefabs/        ← Folder creado por arte en Studio
--     <Model | BasePart>                ← un prefab por tipo de objeto
--       Attribute "ObjectId" (string)   ← igual a ObjectDefinition.ObjectId
--   · Identificación SIEMPRE por Attribute — nunca por .Name (§2.4).
--   · Un Model debe tener PrimaryPart (raíz física del carry) y sus demás
--     BaseParts soldadas a ella, sin anclar.
--   · Prefab ausente → instantiate() genera un placeholder: el arte puede
--     llegar después del código sin romper rondas.
--
-- validate() corre al bootstrap (Main.server.lua) y reporta faltantes,
-- duplicados, huérfanos e inválidos — los errores de contrato aparecen al
-- arrancar el servidor, nunca a mitad de una partida.
--
-- Lune-compatible (§4.6): servicios dentro de funciones. El núcleo de la
-- auditoría (_audit) es puro y se testea en PrefabRegistry.spec.lua.

local PrefabRegistry = {}

export type PrefabEntry = {
    objectId: any, -- valor del Attribute (puede venir mal tipado de Studio)
    physicsRootOk: boolean, -- BasePart, o Model con PrimaryPart
}

export type AuditIssues = {
    missing: { string },
    duplicated: { string },
    orphaned: { string },
    invalid: { string },
}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local cache: { [string]: any }? = nil -- ObjectId → template (no clonado)

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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("PrefabRegistry")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getCatalog()
    return require(game:GetService("ReplicatedStorage").Shared.Definitions.Objects)
end

local function getPrefabFolder(): any?
    return game:GetService("ServerStorage"):FindFirstChild("ObjectPrefabs")
end

local function hasPhysicsRoot(instance: any): boolean
    if instance:IsA("BasePart") then
        return true
    end
    return instance:IsA("Model") and instance.PrimaryPart ~= nil
end

-- ─── Núcleo puro de auditoría (testeable en Lune) ──────────────────────────────

--- Cruza los ObjectIds del catálogo contra las entradas de prefabs.
--- Retorna (ok, issues): ok = false solo ante violaciones de contrato
--- (duplicados/ inválidos) — los faltantes degradan a placeholder y los
--- huérfanos son inofensivos; ambos se reportan como warning.
function PrefabRegistry._audit(catalogIds: { string }, prefabs: { PrefabEntry }): (boolean, AuditIssues)
    local issues: AuditIssues = { missing = {}, duplicated = {}, orphaned = {}, invalid = {} }

    local catalogSet: { [string]: boolean } = {}
    for _, id in ipairs(catalogIds) do
        catalogSet[id] = true
    end

    local seen: { [string]: boolean } = {}
    for _, entry in ipairs(prefabs) do
        if type(entry.objectId) ~= "string" or entry.objectId == "" or not entry.physicsRootOk then
            table.insert(issues.invalid, tostring(entry.objectId))
        elseif seen[entry.objectId] then
            table.insert(issues.duplicated, entry.objectId)
        else
            seen[entry.objectId] = true
            if not catalogSet[entry.objectId] then
                table.insert(issues.orphaned, entry.objectId)
            end
        end
    end

    for _, id in ipairs(catalogIds) do
        if not seen[id] then
            table.insert(issues.missing, id)
        end
    end

    table.sort(issues.missing)
    table.sort(issues.duplicated)
    table.sort(issues.orphaned)
    table.sort(issues.invalid)

    local ok = #issues.duplicated == 0 and #issues.invalid == 0
    return ok, issues
end

-- ─── Resolución ────────────────────────────────────────────────────────────────

local function buildCache(): { [string]: any }
    if cache then
        return cache
    end
    local built: { [string]: any } = {}
    local folder = getPrefabFolder()
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            local objectId = child:GetAttribute("ObjectId")
            -- Solo entradas válidas y no duplicadas — validate() reporta el resto
            if type(objectId) == "string" and objectId ~= "" and hasPhysicsRoot(child) and not built[objectId] then
                built[objectId] = child
            end
        end
    end
    cache = built
    return built
end

--- Retorna el template del prefab para un ObjectId, o nil si no existe.
--- El caller clona — el template nunca sale de ServerStorage.
function PrefabRegistry.resolve(objectId: string): any?
    return buildCache()[objectId]
end

--- Invalida el cache (hot-reload de prefabs en Studio).
function PrefabRegistry.refresh()
    cache = nil
end

-- ─── Instanciación ─────────────────────────────────────────────────────────────

--- Placeholder generado cuando no hay prefab: dimensiones y color por Size
--- desde GameplayConfig (apariencia temporal, se retira con el arte real).
local function buildPlaceholder(def: any): any
    local config = require(game:GetService("ReplicatedStorage").Shared.Config.GameplayConfig)
    local dims = config.PLACEHOLDER_OBJECT_SIZES[def.Size] or { 2, 2, 2 }
    local rgb = config.PLACEHOLDER_OBJECT_COLORS[def.Size] or { 200, 200, 200 }

    local part = Instance.new("Part")
    part.Size = Vector3.new(dims[1], dims[2], dims[3])
    part.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return part
end

--- Materializa la representación física de una ObjectDefinition.
--- Retorna (top, root, isPlaceholder): top = instancia a parentar/destruir;
--- root = BasePart raíz para física y welds (== top en placeholders).
function PrefabRegistry.instantiate(def: any): (any, any?, boolean)
    local template = PrefabRegistry.resolve(def.ObjectId)
    if template then
        local top = template:Clone()
        local root = if top:IsA("BasePart") then top else top.PrimaryPart
        return top, root, false
    end
    local part = buildPlaceholder(def)
    return part, part, true
end

-- ─── Auditoría de contrato (bootstrap) ─────────────────────────────────────────

--- Audita ObjectPrefabs contra el catálogo y loguea el resultado.
--- Retorna (ok, issues). Sin folder: todo degrada a placeholder (válido).
function PrefabRegistry.validate(): (boolean, AuditIssues)
    local catalogIds: { string } = {}
    for objectId in pairs(getCatalog().getAll()) do
        table.insert(catalogIds, objectId)
    end

    local prefabs: { PrefabEntry } = {}
    local folder = getPrefabFolder()
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            table.insert(prefabs, {
                objectId = child:GetAttribute("ObjectId"),
                physicsRootOk = hasPhysicsRoot(child),
            })
        end
    end

    local ok, issues = PrefabRegistry._audit(catalogIds, prefabs)

    if not folder then
        getLog():info("Sin ServerStorage/ObjectPrefabs — todos los objetos usarán placeholder")
    end
    if #issues.missing > 0 then
        getLog():warn("Prefabs faltantes (fallback a placeholder): %s", table.concat(issues.missing, ", "))
    end
    if #issues.orphaned > 0 then
        getLog():warn("Prefabs huérfanos sin ObjectDefinition: %s", table.concat(issues.orphaned, ", "))
    end
    if #issues.duplicated > 0 then
        getLog():warn("CONTRATO VIOLADO — ObjectId duplicado en prefabs: %s", table.concat(issues.duplicated, ", "))
    end
    if #issues.invalid > 0 then
        getLog():warn(
            "CONTRATO VIOLADO — prefabs sin Attribute ObjectId válido o sin PrimaryPart: %s",
            table.concat(issues.invalid, ", ")
        )
    end
    if ok and #issues.missing == 0 then
        getLog():info("Prefabs válidos — %d ObjectIds resueltos", #catalogIds)
    end

    return ok, issues
end

return PrefabRegistry
