-- EventManager
-- Selecciona y ejecuta UN evento aleatorio por ronda desde el pool de
-- Config/Events (§4.4, WLD-005). El evento modifica el entorno, nunca las
-- mecánicas core (§3.4). reset() devuelve el mundo exactamente al estado
-- anterior via el cleanup que retorna cada evento.
--
-- RoundManager es el único caller (§4.8), bajo FEATURE_FLAGS.ENABLE_EVENTS.
-- EventTriggered viaja a los clientes con { eventType } (§4.3).
--
-- Lune-compatible (§4.6): servicios dentro de funciones.

local EventManager = {}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local activeCleanup: (() -> ())? = nil
local activeEventType: string? = nil

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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("EventManager")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getEventsConfig()
    return require(game:GetService("ReplicatedStorage").Shared.Config.Events)
end

-- ─── API pública — llamada solo por RoundManager (§4.8) ────────────────────────

--- Selecciona un evento aleatorio del pool y lo ejecuta. Retorna su EventType,
--- o nil si el pool está vacío o el evento falló al arrancar (la ronda sigue
--- sin evento — degradación explícita, nunca rompe la ronda).
function EventManager.triggerRandom(): string?
    if activeCleanup then
        EventManager.reset() -- nunca dos eventos activos a la vez
    end

    local pool = getEventsConfig().Pool
    if #pool == 0 then
        getLog():warn("Pool de eventos vacío — la ronda corre sin evento")
        return nil
    end

    local entry = pool[math.random(#pool)]
    local ok, cleanup = pcall(entry.start)
    if not ok then
        getLog():warn("Evento %s falló al arrancar — la ronda sigue sin evento", tostring(entry.EventType))
        return nil
    end

    activeCleanup = if type(cleanup) == "function" then cleanup else nil
    activeEventType = entry.EventType

    pcall(function()
        local Networking = require(game:GetService("ReplicatedStorage").Shared.Lib.Networking)
        Networking.EventTriggered:FireAllClients({ eventType = entry.EventType })
    end)

    getLog():info("Evento activo: %s", tostring(entry.EventType))
    return entry.EventType
end

--- EventType del evento activo, o nil.
function EventManager.getActiveEventType(): string?
    return activeEventType
end

--- Deshace el evento activo — el cleanup devuelve el entorno EXACTAMENTE al
--- estado anterior (§4.4). Idempotente.
function EventManager.reset()
    if activeCleanup then
        local ok, err = pcall(activeCleanup)
        if not ok then
            getLog():warn("Cleanup del evento %s falló: %s", tostring(activeEventType), tostring(err))
        end
    end
    activeCleanup = nil
    activeEventType = nil
end

return EventManager
