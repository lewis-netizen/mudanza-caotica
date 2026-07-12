-- Logger
-- Módulo de logging estructurado. Reemplaza print/warn en todo el proyecto.
-- El contrato `contract-logger-usage` (lefthook/CI) deniega print/warn
-- directos fuera de este archivo.
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
--
-- Lune-compatible: GlobalConfig se resuelve en el primer log emitido — no en
-- el scope de módulo — para no acceder a `game` al cargar el módulo (§4.6).
-- En entorno Lune (sin DataModel) el nivel por defecto es WARN.

-- ─── Niveles ──────────────────────────────────────────────────────────────────

local LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
}

local minLevel: number? = nil

local function getMinLevel(): number
    if minLevel == nil then
        local ok, GlobalConfig = pcall(function()
            return require(game.ReplicatedStorage.Shared.Config.GlobalConfig)
        end)
        if ok and GlobalConfig then
            minLevel = LEVELS[GlobalConfig.LOG_LEVEL] or LEVELS.WARN
        else
            minLevel = LEVELS.WARN -- entorno sin DataModel (Lune)
        end
    end
    return minLevel :: number
end

-- ─── Implementación ───────────────────────────────────────────────────────────

local Logger = {}
Logger.__index = Logger

export type LoggerInstance = {
    debug: (self: LoggerInstance, msg: string, ...any) -> (),
    info: (self: LoggerInstance, msg: string, ...any) -> (),
    warn: (self: LoggerInstance, msg: string, ...any) -> (),
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
    if levelValue < getMinLevel() then
        return
    end

    local formatted = string.format(msg, ...)
    local line = string.format("%s[%s] %s", prefix, level, formatted)

    if levelValue >= LEVELS.ERROR then
        -- Nivel 3: emit (1) ← método del Logger (2) ← código del usuario (3).
        -- Así el error apunta al call site real, no al Logger.
        error(line, 3)
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
