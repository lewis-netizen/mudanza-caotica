-- GlobalConfig.lua
-- Configuración global del proyecto.
-- Todos los módulos que necesiten constantes transversales las leen aquí.
-- Nunca hardcodear valores que aparezcan en más de un archivo.
--
-- Lune-compatible: RunService se accede dentro de una función, no en scope
-- de módulo. En entorno Lune (sin DataModel), IS_STUDIO es false. (§4.6)

local function isStudio(): boolean
	local ok, RunService = pcall(game.GetService, game, "RunService")
	if not ok or not RunService then
		return false -- entorno Lune o sin DataModel
	end
	local okStudio, result = pcall(function()
		return RunService:IsStudio()
	end)
	return okStudio and result or false
end

local IS_STUDIO = isStudio()

-- ─── Logging ──────────────────────────────────────────────────────────────────

-- Nivel mínimo de logging.
-- En development: "DEBUG" — todo es visible.
-- En production: "WARN" — solo problemas reales.
-- Valores válidos: "DEBUG" | "INFO" | "WARN" | "ERROR"
local LOG_LEVEL = if IS_STUDIO then "DEBUG" else "WARN"

-- ─── Networking ───────────────────────────────────────────────────────────────

-- Intervalo de sincronización del timer cliente-servidor (segundos).
-- Baja prioridad — el servidor es la fuente de verdad.
local TIMER_SYNC_INTERVAL = 1

-- Rango máximo de interacción jugador-objeto (studs).
-- Usado por CarryManager para validar InteractObject server-side.
local MAX_INTERACT_RANGE = 10

-- ─── Feature Flags ────────────────────────────────────────────────────────────
-- Flags estáticos — booleanos con nombre descriptivo.
-- Deploy para cambiar. Sin DataStore, sin RemoteConfig.
-- Logger registra flags activos al inicio del servidor.

local FEATURE_FLAGS = {
	ENABLE_NPC           = true,   -- NPCManager activo en rondas
	ENABLE_EVENTS        = false,  -- EventManager — desactivado hasta Semana 3
	ENABLE_SUMMARY_SCREEN = true,  -- Summary Screen al finalizar ronda
	DEBUG_OBJECT_STATES  = IS_STUDIO, -- Logging verbose de ObjectInstance.State
}

-- ─── Exports ───────────────────────────────────────────────────────────────────

return {
	IS_STUDIO          = IS_STUDIO,
	LOG_LEVEL          = LOG_LEVEL,
	TIMER_SYNC_INTERVAL = TIMER_SYNC_INTERVAL,
	MAX_INTERACT_RANGE  = MAX_INTERACT_RANGE,
	FEATURE_FLAGS       = FEATURE_FLAGS,
}
