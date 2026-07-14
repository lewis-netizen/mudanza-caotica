-- MapBootstrap
-- Arbitra qué layout usa el servidor según GlobalConfig.MAP_MODE (DL-036).
-- Produce todos los contratos de tags que los sistemas esperan: ObjectSpawn,
-- TruckZone, NPCNode, NPCDropZone.
--
-- Contrato del mapa real (WLD-001): se construye en Studio bajo un contenedor
-- Workspace/RealMap (Folder o Model). MAP_MODE decide, explícitamente:
--   "real"        → se usa Workspace/RealMap tal cual; no se genera nada.
--   "placeholder" → se DESTRUYE la copia runtime de Workspace/RealMap (si
--                   existe) y se genera el placeholder. Destruir es seguro:
--                   en Play/servidor el DataModel es una copia — el .rbxlx
--                   guardado que editas en Studio queda intacto. Necesario
--                   porque CollectionService:GetTagged es agnóstico al parent:
--                   parkear el mapa real no ocultaría sus tags.
--
-- Por qué MAP_MODE y no dos flags: un solo valor no puede contradecirse, así
-- que no hace falta que un flag "apague" a otro en runtime (eso rompería el
-- contrato de flags estáticos). Reemplaza la antigua detección por presencia
-- de TruckZone (frágil con el mapa real incompleto).
--
-- La geometría inline del placeholder es DATO DE MAPA temporal, no parámetro
-- de balance — INV-004 no aplica.
--
-- Lune-compatible (§4.6): servicios se resuelven dentro de funciones.

local MapBootstrap = {}

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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("MapBootstrap")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

-- ─── Helpers ───────────────────────────────────────────────────────────────────

local function makePart(props: { [string]: any }, parent: any): any
    local part = Instance.new("Part")
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    for key, value in pairs(props) do
        (part :: any)[key] = value
    end
    part.Parent = parent
    return part
end

local function makeMarker(position: any, parent: any, tag: string): any
    local CollectionService = game:GetService("CollectionService")
    local marker = makePart({
        Size = Vector3.new(1, 1, 1),
        Position = position,
        Transparency = 1,
        CanCollide = false,
    }, parent)
    CollectionService:AddTag(marker, tag)
    return marker
end

-- ─── Construcción ──────────────────────────────────────────────────────────────
-- Edificio: 40x40 studs, 2 niveles + rampa, puerta al sur hacia el camión.
-- Un pasillo central (x = 0) produce la fricción espacial básica (WLD-001).

local function buildWalls(container: any)
    local gray = Color3.fromRGB(160, 160, 165)
    local wallHeight = 12

    -- Perímetro (puerta de 10 studs centrada en el muro sur)
    makePart(
        { Size = Vector3.new(15, wallHeight, 1), Position = Vector3.new(-12.5, wallHeight / 2, 0), Color = gray },
        container
    )
    makePart(
        { Size = Vector3.new(15, wallHeight, 1), Position = Vector3.new(12.5, wallHeight / 2, 0), Color = gray },
        container
    )
    makePart(
        { Size = Vector3.new(40, wallHeight, 1), Position = Vector3.new(0, wallHeight / 2, 40), Color = gray },
        container
    )
    makePart(
        { Size = Vector3.new(1, wallHeight, 40), Position = Vector3.new(-20, wallHeight / 2, 20), Color = gray },
        container
    )
    makePart(
        { Size = Vector3.new(1, wallHeight, 40), Position = Vector3.new(20, wallHeight / 2, 20), Color = gray },
        container
    )

    -- Muro interior: crea el pasillo/chokepoint central (hueco en z 18–24)
    makePart(
        { Size = Vector3.new(1, wallHeight, 16), Position = Vector3.new(0, wallHeight / 2, 10), Color = gray },
        container
    )
    makePart(
        { Size = Vector3.new(1, wallHeight, 14), Position = Vector3.new(0, wallHeight / 2, 33), Color = gray },
        container
    )
end

local function buildFloors(container: any)
    local floorColor = Color3.fromRGB(120, 120, 128)

    -- Suelo exterior + interior
    makePart(
        { Size = Vector3.new(140, 1, 140), Position = Vector3.new(0, -0.5, 15), Color = Color3.fromRGB(96, 110, 96) },
        container
    )

    -- Segundo nivel: losa sobre la mitad norte + rampa de acceso (WLD-001:
    -- 2 niveles con rampa accesible)
    makePart({ Size = Vector3.new(40, 1, 20), Position = Vector3.new(0, 12, 30), Color = floorColor }, container)

    local rampLength = math.sqrt(20 * 20 + 12 * 12)
    local rampAngle = math.atan(12 / 20)
    local ramp = makePart({ Size = Vector3.new(8, 1, rampLength), Color = floorColor }, container)
    ramp.CFrame = CFrame.new(Vector3.new(-14, 6, 10)) * CFrame.Angles(rampAngle, 0, 0)

    -- Barandilla del borde del segundo nivel (WLD-001: sin huecos de caída
    -- accidental fuera de ruta)
    makePart({ Size = Vector3.new(30, 3, 1), Position = Vector3.new(5, 13.5, 20.5), Color = floorColor }, container)
end

local function buildDeliveryZone(container: any)
    local CollectionService = game:GetService("CollectionService")

    -- Camión placeholder (visual) + zona de entrega tagueada (§4.4)
    makePart({
        Size = Vector3.new(10, 8, 16),
        Position = Vector3.new(0, 4, -18),
        Color = Color3.fromRGB(70, 90, 150),
        Transparency = 0.35,
        CanCollide = false,
    }, container)

    local zone = makePart({
        Size = Vector3.new(12, 1, 18),
        Position = Vector3.new(0, 0.5, -14),
        Color = Color3.fromRGB(80, 190, 100),
        Transparency = 0.6,
        CanCollide = false,
    }, container)
    CollectionService:AddTag(zone, "TruckZone")
end

local function buildSpawnMarkers(container: any)
    -- Nivel 1: seis puntos repartidos en ambos cuartos (x < 0 y x > 0)
    local level1 = { { -14, 6 }, { -10, 30 }, { -15, 36 }, { 12, 8 }, { 15, 26 }, { 8, 36 } }
    for _, xz in ipairs(level1) do
        makeMarker(Vector3.new(xz[1], 1, xz[2]), container, "ObjectSpawn")
    end
    -- Nivel 2: cuatro puntos sobre la losa
    local level2 = { { -12, 26 }, { -6, 36 }, { 8, 28 }, { 14, 36 } }
    for _, xz in ipairs(level2) do
        makeMarker(Vector3.new(xz[1], 13.5, xz[2]), container, "ObjectSpawn")
    end
end

local function buildNPCContract(container: any)
    -- WLD-002: nodos de patrulla + drop zones existen aunque el NPC no (§4.4)
    local nodes = { { -10, 6 }, { -14, 20 }, { -8, 34 }, { 6, 34 }, { 14, 20 }, { 10, 6 } }
    for index, xz in ipairs(nodes) do
        local node = makeMarker(Vector3.new(xz[1], 1, xz[2]), container, "NPCNode")
        node:SetAttribute("NodeIndex", index)
    end
    for _, xz in ipairs({ { -16, 12 }, { 16, 32 } }) do
        makeMarker(Vector3.new(xz[1], 1, xz[2]), container, "NPCDropZone")
    end
end

local function buildPlayerSpawn(container: any)
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Size = Vector3.new(8, 1, 8)
    spawnLocation.Position = Vector3.new(14, 0.5, -8)
    spawnLocation.Anchored = true
    spawnLocation.Neutral = true
    spawnLocation.Duration = 0
    spawnLocation.Parent = container
end

-- ─── API pública ───────────────────────────────────────────────────────────────

--- Genera el mapa placeholder si no existe layout real (detectado por el
--- Tag TruckZone). Idempotente. Llamado una vez desde Main.server.lua.
function MapBootstrap.ensure()
    local Workspace = game:GetService("Workspace")
    local GlobalConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GlobalConfig)
    local mode = GlobalConfig.MAP_MODE
    local realMap = Workspace:FindFirstChild("RealMap")

    if mode == "real" then
        if realMap then
            getLog():info("MAP_MODE=real — usando Workspace/RealMap")
        else
            getLog():warn("MAP_MODE=real pero no existe Workspace/RealMap — la ronda no tendrá spawns ni entregas")
        end
        return
    end

    if mode ~= "placeholder" then
        getLog():warn("MAP_MODE no reconocido (%s) — se asume placeholder", tostring(mode))
    end

    -- placeholder: excluir el mapa real destruyendo su copia runtime (seguro —
    -- no toca el .rbxlx guardado). Necesario para que sus tags no se mezclen
    -- con los del placeholder (GetTagged es agnóstico al parent).
    if realMap then
        pcall(function()
            realMap:Destroy()
        end)
        getLog():info("MAP_MODE=placeholder — Workspace/RealMap descartado en runtime")
    end

    local container = Instance.new("Folder")
    container.Name = "PlaceholderMap"
    container.Parent = Workspace

    buildFloors(container)
    buildWalls(container)
    buildDeliveryZone(container)
    buildSpawnMarkers(container)
    buildNPCContract(container)
    buildPlayerSpawn(container)

    getLog():info("Mapa placeholder generado (MAP_MODE=real lo desactiva cuando WLD-001 esté listo)")
end

return MapBootstrap
