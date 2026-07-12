-- RoundManager
-- Gestiona la ronda activa (§4.4, GM-002). Propietario de RoundState y
-- RoundSummary. Único módulo que llama start/stop/reset sobre los módulos
-- de gameplay (§4.8). NUNCA cambia el estado global Lobby/Active/Summary —
-- eso es exclusivo de GameManager.
--
-- StoryEvent.Timestamp = segundos desde RoundStarted (DL-021) — RoundManager
-- es la fuente única del timer. Todo EventType debe estar registrado en
-- Config/Events.lua (INV-003).
--
-- Lune-compatible (§4.6): servicios y módulos se resuelven dentro de funciones.

local RoundManager = {}

export type StoryEvent = {
    EventType: string,
    Data: any?,
    Timestamp: number,
}

export type RoundSummary = {
    SavedObjects: number,
    LostObjects: number,
    ClientComment: string,
    StoryEvents: { StoryEvent },
}

-- ─── RoundState (§4.4) ─────────────────────────────────────────────────────────

local roundActive = false
local elapsedSeconds = 0
local roundDuration = 0
local activeEventType: string? = nil
local storyEvents: { StoryEvent } = {}

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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("RoundManager")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getSystems(moduleName: string)
    return require(game:GetService("ServerScriptService").Systems[moduleName])
end

local function getSharedConfig(moduleName: string)
    return require(game:GetService("ReplicatedStorage").Shared.Config[moduleName])
end

local function getNetworking()
    return require(game:GetService("ReplicatedStorage").Shared.Lib.Networking)
end

-- ─── StoryEvents ───────────────────────────────────────────────────────────────

--- Registra un StoryEvent en RoundState. El EventType debe estar registrado
--- en Config/Events.lua (INV-003) — los no registrados se descartan con warn.
function RoundManager.recordStoryEvent(eventType: string, data: any?)
    if not roundActive then
        return
    end
    local Events = getSharedConfig("Events")
    if not Events.STORY_EVENT_TYPES[eventType] then
        getLog():warn("StoryEvent descartado — EventType no registrado en Config/Events.lua: %s", tostring(eventType))
        return
    end
    table.insert(storyEvents, {
        EventType = eventType,
        Data = data,
        Timestamp = elapsedSeconds,
    })
end

-- ─── Summary ───────────────────────────────────────────────────────────────────

--- Comentario narrativo del servidor — 3 umbrales (UI-003). Sin puntuaciones.
local function buildClientComment(saved: number, lost: number): string
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

-- ─── Ciclo de ronda — llamado solo por GameManager (§4.8) ──────────────────────

--- Inicia la ronda: módulos de gameplay en orden de dependencias (§4.5),
--- timer y RoundStarted. opts.onTimeExpired se llama al agotarse el tiempo —
--- GameManager decide entonces la transición (RoundManager no la inicia).
function RoundManager.start(opts: { onTimeExpired: () -> () })
    if roundActive then
        getLog():warn("start() con ronda ya activa — ignorado")
        return
    end

    local RoundConfig = getSharedConfig("RoundConfig")
    local GlobalConfig = getSharedConfig("GlobalConfig")

    roundActive = true
    elapsedSeconds = 0
    roundDuration = RoundConfig.ROUND_DURATION
    storyEvents = {}
    activeEventType = nil

    local ctx = { recordStoryEvent = RoundManager.recordStoryEvent }

    -- Orden de arranque por dependencias (§4.5)
    getSystems("ObjectManager").initialize()
    getSystems("CarryManager").start(ctx)
    getSystems("TruckManager").start(ctx)

    if GlobalConfig.FEATURE_FLAGS.ENABLE_NPC then
        getLog():warn("ENABLE_NPC activo pero NPCManager no existe todavía (WLD-004)")
    end
    if GlobalConfig.FEATURE_FLAGS.ENABLE_EVENTS then
        getLog():warn("ENABLE_EVENTS activo pero EventManager no existe todavía (WLD-005)")
    end

    getNetworking().RoundStarted:FireAllClients({
        duration = roundDuration,
        eventType = activeEventType,
    })
    getLog():info("Ronda iniciada — %d segundos", roundDuration)

    -- Timer de ronda: fuente única del tiempo (§4.4). TimerSync es baja
    -- prioridad (§4.3) — 1 tick por TIMER_SYNC_INTERVAL.
    local syncInterval = GlobalConfig.TIMER_SYNC_INTERVAL
    local sinceSync = 0
    -- La cancelación es por flag (roundActive) — no se guarda el thread.
    task.spawn(function()
        while roundActive and elapsedSeconds < roundDuration do
            task.wait(1)
            if not roundActive then
                return
            end
            elapsedSeconds += 1
            sinceSync += 1
            if sinceSync >= syncInterval then
                sinceSync = 0
                getNetworking().TimerSync:FireAllClients({
                    timeRemaining = roundDuration - elapsedSeconds,
                })
            end
        end
        if roundActive then
            getLog():info("Timer agotado — notificando a GameManager")
            opts.onTimeExpired()
        end
    end)
end

--- Detiene la ronda y compila el RoundSummary desde RoundState (GM-002).
function RoundManager.stop(): RoundSummary
    local ObjectManager = getSystems("ObjectManager")
    local TruckManager = getSystems("TruckManager")

    -- Detener módulos activos ANTES de compilar: los drops forzados por
    -- stop() generan sus StoryEvents y deben entrar al summary.
    getSystems("CarryManager").stop()
    TruckManager.stop()
    roundActive = false

    local saved = TruckManager.getDeliveredCount()
    local lost = 0
    for _, obj in ipairs(ObjectManager.getAllObjects()) do
        if obj.State ~= "delivered" then
            lost += 1
        end
    end

    local summary: RoundSummary = {
        SavedObjects = saved,
        LostObjects = lost,
        ClientComment = buildClientComment(saved, lost),
        StoryEvents = storyEvents,
    }

    getNetworking().RoundEnded:FireAllClients(summary)
    getLog():info("Ronda terminada — salvados: %d, perdidos: %d", saved, lost)
    return summary
end

--- Resetea todos los módulos de gameplay y limpia RoundState (GM-002).
function RoundManager.reset()
    roundActive = false
    getSystems("ObjectManager").reset()
    getSystems("CarryManager").reset()
    getSystems("TruckManager").reset()
    elapsedSeconds = 0
    storyEvents = {}
    activeEventType = nil
end

--- Segundos restantes de la ronda activa (0 si no hay ronda).
function RoundManager.getTimeRemaining(): number
    if not roundActive then
        return 0
    end
    return math.max(0, roundDuration - elapsedSeconds)
end

return RoundManager
