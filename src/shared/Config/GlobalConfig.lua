-- GlobalConfig.lua
-- Configuración global del proyecto.
-- Todos los módulos que necesiten constantes transversales las leen aquí.
-- Nunca hardcodear valores que aparezcan en más de un archivo.
--
-- Lune-compatible: todo acceso a `game` ocurre dentro de una función anónima
-- envuelta completa en pcall. En entorno Lune (sin DataModel), `game` es nil
-- e indexarlo lanza error — el pcall lo captura e IS_STUDIO es false. (§4.6)

local function isStudio(): boolean
    -- Importante: no pasar `game.GetService` como argumento de pcall —
    -- indexar `game` se evaluaría ANTES de entrar al pcall y rompería
    -- la carga del módulo en Lune. El acceso completo va dentro del closure.
    local ok, result = pcall(function()
        return game:GetService("RunService"):IsStudio()
    end)
    return ok and result == true
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
    ENABLE_NPC = false, -- NPCManager — desactivado hasta que exista (Semana 3, WLD-004)
    ENABLE_EVENTS = false, -- EventManager — desactivado hasta Semana 3
    ENABLE_SUMMARY_SCREEN = true, -- Summary Screen al finalizar ronda
    ENABLE_PLACEHOLDER_MAP = true, -- MapBootstrap genera edificio placeholder si falta layout real (WLD-001)
    DEBUG_OBJECT_STATES = IS_STUDIO, -- Logging verbose de ObjectInstance.State
}

-- ─── Exports ───────────────────────────────────────────────────────────────────

return {
    IS_STUDIO = IS_STUDIO,
    LOG_LEVEL = LOG_LEVEL,
    TIMER_SYNC_INTERVAL = TIMER_SYNC_INTERVAL,
    MAX_INTERACT_RANGE = MAX_INTERACT_RANGE,
    FEATURE_FLAGS = FEATURE_FLAGS,
}
