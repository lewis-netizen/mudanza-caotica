-- ClientStateManager
-- Fuente única de verdad del estado del juego en el cliente.
-- Es el único módulo que escucha RemoteEvents.
-- Los módulos de UI leen de aquí — nunca conectan RemoteEvents directamente.
--
-- Invariante: ningún módulo fuera de este archivo llama a Networking.*:Connect()
-- Invariante: el estado es de solo lectura para los consumidores — todo lo que
--             sale de este módulo (getState, getObject, listeners) es snapshot,
--             nunca la tabla interna.
-- Invariante: todo el estado se limpia en RoundEnded y RoundStarted
--
-- Lune-compatible: las dependencias (Networking, Logger) se resuelven en
-- init(), no en el scope de módulo — sin acceso a `game` al cargar (§4.6).

-- ─── Dependencias — resueltas en init() ────────────────────────────────────────

local Networking = nil
local log = nil
local Phase = nil -- Constants.RoundPhase
local State_ = nil -- Constants.ObjectState

-- ─── Tipos ────────────────────────────────────────────────────────────────────

export type RoundPhase = "Lobby" | "Active" | "Summary"

export type ObjectState = "free" | "being_carried" | "delivered"

export type ObjectSnapshot = {
    instanceId: string,
    objectId: string,
    state: ObjectState,
    leaderId: number?,
    supportId: number?,
}

export type RoundSummary = {
    SavedObjects: number,
    LostObjects: number,
    ClientComment: string,
    StoryEvents: { any },
}

export type State = {
    phase: RoundPhase,
    timeRemaining: number,
    deliveredCount: number,
    activeEventType: string?,
    objects: { [string]: ObjectSnapshot },
    summary: RoundSummary?,
}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local state: State = {
    phase = "Lobby",
    timeRemaining = 0,
    deliveredCount = 0,
    activeEventType = nil,
    objects = {},
    summary = nil,
}

--- Construye una copia snapshot del estado actual.
--- Cada ObjectSnapshot se clona individualmente — los consumidores no pueden
--- mutar el estado interno. (StoryEvents dentro de summary se comparte por
--- referencia: el summary llega del servidor y no se muta en el cliente.)
local function buildSnapshot(): State
    local objectsCopy: { [string]: ObjectSnapshot } = {}
    for instanceId, obj in pairs(state.objects) do
        objectsCopy[instanceId] = table.clone(obj)
    end
    return {
        phase = state.phase,
        timeRemaining = state.timeRemaining,
        deliveredCount = state.deliveredCount,
        activeEventType = state.activeEventType,
        objects = objectsCopy,
        summary = if state.summary then table.clone(state.summary) else nil,
    }
end

-- ─── Listeners registrados por módulos de UI ──────────────────────────────────
-- Cada listener recibe el estado completo cuando cambia.
-- Los módulos se registran en su init() y se desregistran en cleanup().
--
-- Suscripción selectiva (§4.10): los ticks de TimerSync solo notifican a los
-- listeners registrados con { timerUpdates = true }. Evita re-renders por
-- segundo en módulos que no muestran el timer.

type Listener = (state: State) -> ()

type ListenerEntry = {
    fn: Listener,
    timerUpdates: boolean,
}

export type SubscribeOptions = {
    timerUpdates: boolean?,
}

local listeners: { [string]: ListenerEntry } = {}

--- Notifica un cambio de estado. timerOnly = true → solo listeners de timer.
local function notify(timerOnly: boolean?)
    -- Un solo snapshot compartido por notificación — los listeners nunca
    -- reciben la tabla interna.
    local snapshot = buildSnapshot()
    for _, entry in pairs(listeners) do
        if timerOnly and not entry.timerUpdates then
            continue
        end
        entry.fn(snapshot)
    end
end

-- ─── API pública — lectura ─────────────────────────────────────────────────────

local ClientStateManager = {}

--- Retorna una copia snapshot del estado actual.
--- No retorna la tabla interna — los consumidores no pueden mutar el estado.
function ClientStateManager.getState(): State
    return buildSnapshot()
end

--- Retorna un snapshot del objeto específico, o nil si no existe.
function ClientStateManager.getObject(instanceId: string): ObjectSnapshot?
    local obj = state.objects[instanceId]
    return if obj then table.clone(obj) else nil
end

--- Registra un listener que se llama cuando el estado cambia.
--- options.timerUpdates = true → recibe también los ticks de TimerSync
--- (1 notificación por segundo). Por defecto los ticks de timer NO notifican.
--- Retorna una función de cleanup que desregistra el listener.
--- Usar en el init() de cada módulo de UI.
function ClientStateManager.subscribe(id: string, listener: Listener, options: SubscribeOptions?): () -> ()
    listeners[id] = {
        fn = listener,
        timerUpdates = if options then options.timerUpdates == true else false,
    }
    -- Llamar inmediatamente con el estado actual para sincronizar
    listener(buildSnapshot())
    return function()
        listeners[id] = nil
    end
end

-- ─── Handlers de RemoteEvents ──────────────────────────────────────────────────
-- Solo este módulo conecta RemoteEvents. Nadie más.

local function onRoundStarted(data: { duration: number, eventType: string? })
    log:info("RoundStarted — duration: %d, event: %s", data.duration, data.eventType or "none")
    state.phase = Phase.ACTIVE
    state.timeRemaining = data.duration
    state.deliveredCount = 0
    state.activeEventType = data.eventType
    state.objects = {}
    state.summary = nil
    notify()
end

local function onRoundEnded(summary: RoundSummary)
    log:info("RoundEnded — saved: %d, lost: %d", summary.SavedObjects, summary.LostObjects)
    state.phase = Phase.SUMMARY
    state.summary = summary
    notify()
end

local function onObjectStateChanged(data: {
    instanceId: string,
    objectId: string?,
    state: ObjectState,
    leaderId: number?,
    supportId: number?,
})
    local existing = state.objects[data.instanceId]
    if existing then
        existing.state = data.state
        existing.leaderId = data.leaderId
        existing.supportId = data.supportId
        if data.objectId then
            existing.objectId = data.objectId
        end
    else
        -- Primera vez que vemos este objeto
        state.objects[data.instanceId] = {
            instanceId = data.instanceId,
            objectId = data.objectId or "",
            state = data.state,
            leaderId = data.leaderId,
            supportId = data.supportId,
        }
    end
    notify()
end

local function onDeliverObject(data: { instanceId: string })
    local obj = state.objects[data.instanceId]
    if obj then
        obj.state = State_.DELIVERED
    end
    state.deliveredCount += 1
    notify()
end

local function onTimerSync(data: { timeRemaining: number })
    -- Baja prioridad — notificación selectiva: solo listeners registrados
    -- con timerUpdates = true reciben este tick (§4.10).
    state.timeRemaining = data.timeRemaining
    notify(true)
end

local function onEventTriggered(data: { eventType: string })
    log:info("EventTriggered — %s", data.eventType)
    state.activeEventType = data.eventType
    notify()
end

-- ─── Inicialización ────────────────────────────────────────────────────────────

local initialized = false

function ClientStateManager.init()
    if initialized then
        if log then
            log:warn("init() llamado más de una vez — ignorado")
        end
        return
    end
    initialized = true

    -- Dependencias resueltas aquí — no en scope de módulo (§4.6).
    -- init() solo corre en runtime Roblox, donde `game` siempre existe.
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    Networking = require(ReplicatedStorage.Shared.Lib.Networking)
    local Logger = require(ReplicatedStorage.Shared.Lib.Logger)
    log = Logger.new("ClientStateManager")
    Phase = require(ReplicatedStorage.Shared.Constants.RoundPhase)
    State_ = require(ReplicatedStorage.Shared.Constants.ObjectState)

    Networking.RoundStarted.OnClientEvent:Connect(onRoundStarted)
    Networking.RoundEnded.OnClientEvent:Connect(onRoundEnded)
    Networking.ObjectStateChanged.OnClientEvent:Connect(onObjectStateChanged)
    Networking.DeliverObject.OnClientEvent:Connect(onDeliverObject)
    Networking.TimerSync.OnClientEvent:Connect(onTimerSync)
    Networking.EventTriggered.OnClientEvent:Connect(onEventTriggered)

    log:info("Inicializado — escuchando 6 RemoteEvents")
end

return ClientStateManager
