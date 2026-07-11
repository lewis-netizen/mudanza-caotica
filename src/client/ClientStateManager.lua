-- ClientStateManager
-- Fuente única de verdad del estado del juego en el cliente.
-- Es el único módulo que escucha RemoteEvents.
-- Los módulos de UI leen de aquí — nunca conectan RemoteEvents directamente.
--
-- Invariante: ningún módulo fuera de este archivo llama a Networking.*:Connect()
-- Invariante: el estado es de solo lectura para los consumidores
-- Invariante: todo el estado se limpia en RoundEnded y RoundStarted

local Networking = require(game.ReplicatedStorage.Shared.Lib.Networking)
local Logger = require(game.ReplicatedStorage.Shared.Lib.Logger)

local log = Logger.new("ClientStateManager")

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

-- ─── Listeners registrados por módulos de UI ──────────────────────────────────
-- Cada listener recibe el estado completo cuando cambia.
-- Los módulos se registran en su init() y se desregistran en cleanup().

type Listener = (state: State) -> ()

local listeners: { [string]: Listener } = {}

local function notify()
	for _, listener in pairs(listeners) do
		listener(state)
	end
end

-- ─── API pública — lectura ─────────────────────────────────────────────────────

local ClientStateManager = {}

--- Retorna una copia snapshot del estado actual.
--- No retorna la tabla interna — los consumidores no pueden mutar el estado.
function ClientStateManager.getState(): State
	return {
		phase = state.phase,
		timeRemaining = state.timeRemaining,
		deliveredCount = state.deliveredCount,
		activeEventType = state.activeEventType,
		objects = table.clone(state.objects),
		summary = state.summary,
	}
end

--- Retorna el snapshot de un objeto específico, o nil si no existe.
function ClientStateManager.getObject(instanceId: string): ObjectSnapshot?
	return state.objects[instanceId]
end

--- Registra un listener que se llama cuando el estado cambia.
--- Retorna una función de cleanup que desregistra el listener.
--- Usar en el init() de cada módulo de UI.
function ClientStateManager.subscribe(id: string, listener: Listener): () -> ()
	listeners[id] = listener
	-- Llamar inmediatamente con el estado actual para sincronizar
	listener(state)
	return function()
		listeners[id] = nil
	end
end

-- ─── Handlers de RemoteEvents ──────────────────────────────────────────────────
-- Solo este módulo conecta RemoteEvents. Nadie más.

local function onRoundStarted(data: { duration: number, eventType: string })
	log:info("RoundStarted — duration: %d, event: %s", data.duration, data.eventType or "none")
	state.phase = "Active"
	state.timeRemaining = data.duration
	state.deliveredCount = 0
	state.activeEventType = data.eventType
	state.objects = {}
	state.summary = nil
	notify()
end

local function onRoundEnded(summary: RoundSummary)
	log:info("RoundEnded — saved: %d, lost: %d", summary.SavedObjects, summary.LostObjects)
	state.phase = "Summary"
	state.summary = summary
	notify()
end

local function onObjectStateChanged(data: {
	instanceId: string,
	state: ObjectState,
	leaderId: number?,
	supportId: number?,
})
	local existing = state.objects[data.instanceId]
	if existing then
		existing.state = data.state
		existing.leaderId = data.leaderId
		existing.supportId = data.supportId
	else
		-- Primera vez que vemos este objeto
		state.objects[data.instanceId] = {
			instanceId = data.instanceId,
			objectId = "", -- el servidor puede extender el payload si se necesita
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
		obj.state = "delivered"
	end
	state.deliveredCount += 1
	notify()
end

local function onTimerSync(data: { timeRemaining: number })
	-- Baja prioridad — solo actualizar el timer sin notificar todos los listeners
	-- para evitar re-renders innecesarios en módulos que no muestran el timer
	state.timeRemaining = data.timeRemaining
	-- Notificación selectiva: solo listeners que escuchan timer
	-- En MVP: notificar a todos (optimizar si hay perf issues)
	notify()
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
		log:warn("init() llamado más de una vez — ignorado")
		return
	end
	initialized = true

	Networking.RoundStarted.OnClientEvent:Connect(onRoundStarted)
	Networking.RoundEnded.OnClientEvent:Connect(onRoundEnded)
	Networking.ObjectStateChanged.OnClientEvent:Connect(onObjectStateChanged)
	Networking.DeliverObject.OnClientEvent:Connect(onDeliverObject)
	Networking.TimerSync.OnClientEvent:Connect(onTimerSync)
	Networking.EventTriggered.OnClientEvent:Connect(onEventTriggered)

	log:info("Inicializado — escuchando 6 RemoteEvents")
end

return ClientStateManager
