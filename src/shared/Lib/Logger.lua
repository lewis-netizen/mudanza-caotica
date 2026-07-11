-- Logger
-- Módulo de logging estructurado. Reemplaza print/warn en todo el proyecto.
-- Selene está configurado para denegar print/warn fuera de este archivo.
--
-- USO:
--   local Logger = require(game.ReplicatedStorage.Shared.Lib.Logger)
--   local log = Logger.new("MiModulo")
--   log:debug("Valor: %s", tostring(valor))
--   log:info("Jugador %s se unió", player.Name)
--   log:warn("DataStore tardó %d segundos", elapsed)
--   log:error("Estado inválido: %s", state)
--
-- El nivel mínimo se lee de GlobalConfig.LOG_LEVEL.
-- En Studio: DEBUG (todo visible).
-- En producción: WARN (solo problemas reales).

local GlobalConfig = require(game.ReplicatedStorage.Shared.Config.GlobalConfig)

-- ─── Niveles ──────────────────────────────────────────────────────────────────

local LEVELS = {
	DEBUG = 1,
	INFO  = 2,
	WARN  = 3,
	ERROR = 4,
}

local MIN_LEVEL: number = LEVELS[GlobalConfig.LOG_LEVEL] or LEVELS.WARN

-- ─── Implementación ───────────────────────────────────────────────────────────

local Logger = {}
Logger.__index = Logger

export type LoggerInstance = {
	debug: (self: LoggerInstance, msg: string, ...any) -> (),
	info:  (self: LoggerInstance, msg: string, ...any) -> (),
	warn:  (self: LoggerInstance, msg: string, ...any) -> (),
	error: (self: LoggerInstance, msg: string, ...any) -> (),
}

--- Crea una nueva instancia de Logger para un módulo.
--- @param moduleName string — nombre del módulo, aparece como prefijo en cada línea
function Logger.new(moduleName: string): LoggerInstance
	local self = setmetatable({}, Logger)
	self._prefix = string.format("[%s]", moduleName)
	return self
end

local function emit(prefix: string, level: string, levelValue: number, msg: string, ...: any)
	if levelValue < MIN_LEVEL then return end

	local formatted = string.format(msg, ...)
	local line = string.format("%s[%s] %s", prefix, level, formatted)

	if levelValue >= LEVELS.ERROR then
		error(line, 2)
	elseif levelValue >= LEVELS.WARN then
		warn(line)
	else
		print(line)
	end
end

function Logger:debug(msg: string, ...: any)
	emit(self._prefix, "DEBUG", LEVELS.DEBUG, msg, ...)
end

function Logger:info(msg: string, ...: any)
	emit(self._prefix, "INFO", LEVELS.INFO, msg, ...)
end

function Logger:warn(msg: string, ...: any)
	emit(self._prefix, "WARN", LEVELS.WARN, msg, ...)
end

function Logger:error(msg: string, ...: any)
	emit(self._prefix, "ERROR", LEVELS.ERROR, msg, ...)
end

return Logger
