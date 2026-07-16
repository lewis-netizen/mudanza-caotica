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

-- ─── Input del cliente ─────────────────────────────────────────────────────────

-- Tecla de interacción (recoger/soltar). String — el cliente la mapea con
-- Enum.KeyCode[INTERACT_KEY]. No usar Enum aquí: rompería la carga en Lune
-- (§4.6). Usado por InteractionController (GAM-010).
local INTERACT_KEY = "E"

-- ─── Mapa activo (DL-036) ──────────────────────────────────────────────────────
-- Fuente ÚNICA de qué layout usa el servidor. Un solo valor — imposible que
-- "placeholder" y "real" se contradigan (por eso NO son dos flags).
--   "placeholder" → MapBootstrap genera el edificio en código y descarta el
--                   mapa real de Workspace/RealMap si existe (default: seguro,
--                   siempre jugable mientras WLD-001 está incompleto).
--   "real"        → se usa Workspace/RealMap tal cual; MapBootstrap no genera
--                   nada. Cambiar a "real" cuando WLD-001 esté completo.
local MAP_MODE: "placeholder" | "real" = "placeholder"

-- ─── Feature Flags ────────────────────────────────────────────────────────────
-- Flags estáticos — booleanos con nombre descriptivo.
-- Deploy para cambiar. Sin DataStore, sin RemoteConfig.
-- Logger registra flags activos al inicio del servidor.

local FEATURE_FLAGS = {
    ENABLE_NPC = true, -- NPCManager patrullando (WLD-004)
    ENABLE_EVENTS = false, -- EventManager — desactivado hasta Semana 3
    ENABLE_SUMMARY_SCREEN = true, -- Summary Screen al finalizar ronda
    DEBUG_OBJECT_STATES = IS_STUDIO, -- Logging verbose de ObjectInstance.State
}

-- ─── Exports ───────────────────────────────────────────────────────────────────

return {
    IS_STUDIO = IS_STUDIO,
    LOG_LEVEL = LOG_LEVEL,
    TIMER_SYNC_INTERVAL = TIMER_SYNC_INTERVAL,
    MAX_INTERACT_RANGE = MAX_INTERACT_RANGE,
    INTERACT_KEY = INTERACT_KEY,
    MAP_MODE = MAP_MODE,
    FEATURE_FLAGS = FEATURE_FLAGS,
}
