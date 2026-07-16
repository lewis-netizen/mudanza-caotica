-- PlayerDataService
-- Wrapper delgado sobre ProfileStore (§4.7, PER-003). Responsabilidad
-- exclusivamente de dominio: aplicar MigrationService.migrate() al cargar
-- y exponer el schema canónico de PlayerData (§2.5).
--
-- NO reimplementa retry, session locking, rate limiting ni auto-save —
-- todo eso es responsabilidad de ProfileStore (paquete externo).
--
-- Ciclo de sesión (DL-020) — atado al jugador, nunca a la ronda:
--   loadPlayer(player)     StartSessionAsync + migrate. En PlayerAdded.
--   savePlayer(player)     Profile:Save() — flush. Nunca cierra la sesión.
--   getData(player)        Profile.Data en memoria. Sin operación de red.
--   releasePlayer(player)  Profile:EndSession(). Solo en PlayerRemoving.
--
-- Lune-compatible (§4.6): ProfileStore y servicios se resuelven dentro de
-- funciones. Los paths puros (getData con sesión inexistente) no tocan game.

local PlayerDataService = {}

type Session = {
    profile: any?, -- nil si la sesión corre con datos por defecto (sin persistir)
    data: any,
    sessionStart: number,
}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local sessions: { [any]: Session } = {}
local storeInstance: any = nil

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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("PlayerDataService")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getMigrationService()
    return require(game:GetService("ServerScriptService").Systems.Persistence.MigrationService)
end

local function getConfig()
    return require(game:GetService("ServerScriptService").Systems.Persistence.ProfileStoreConfig)
end

--- Crea (una sola vez) el ProfileStore. Retorna nil si el paquete no está
--- disponible (Lune, Studio sin acceso a DataStores) — el caller degrada
--- a datos por defecto sin bloquear el join (PER-003).
local function getStore(): any?
    if storeInstance then
        return storeInstance
    end
    local ok, store = pcall(function()
        local ServerScriptService = game:GetService("ServerScriptService")
        local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
        local config = require(ServerScriptService.Systems.Persistence.ProfileStoreConfig)
        local MigrationService = require(ServerScriptService.Systems.Persistence.MigrationService)
        return ProfileStore.New(config.STORE_NAME, MigrationService.getTemplate())
    end)
    if ok then
        storeInstance = store
    end
    return storeInstance
end

-- ─── Helpers ───────────────────────────────────────────────────────────────────

--- Escribe el resultado de la migración DENTRO de Profile.Data (misma tabla)
--- — ProfileStore guarda la referencia original, no una nueva.
--- GUARDA DE ALIASING: cuando el dato ya está en la versión canónica,
--- migrate() devuelve la MISMA tabla; limpiar target borraría también source
--- (self-wipe — el perfil quedaba {} sesión por medio). Si son la misma
--- referencia no hay nada que escribir.
local function writeInto(target: any, source: any)
    if target == source then
        return
    end
    for key in pairs(target) do
        target[key] = nil
    end
    for key, value in pairs(source) do
        target[key] = value
    end
end

-- Expuesto con prefijo _ para el spec (mismo patrón que PrefabRegistry._audit):
-- la guarda de aliasing es exactamente el bug que los specs de interfaz no veían.
PlayerDataService._writeInto = writeInto

local function stampJoinDates(data: any)
    local now = os.time()
    if data.Profile.FirstJoinDate == 0 then
        data.Profile.FirstJoinDate = now
    end
    data.Profile.LastJoinDate = now
end

-- ─── API pública (§4.7) ────────────────────────────────────────────────────────

--- Inicia la sesión de ProfileStore y aplica la migración. Si la sesión
--- falla (perfil bloqueado por otro servidor), el jugador recibe datos por
--- defecto y un warn — nunca se bloquea el join (PER-003).
function PlayerDataService.loadPlayer(player: any): any
    local existing = sessions[player]
    if existing then
        return existing.data
    end

    local MigrationService = getMigrationService()
    local store = getStore()
    local profile: any = nil

    if store then
        local config = getConfig()
        local ok, result = pcall(function()
            return store:StartSessionAsync(config.SESSION_KEY_PREFIX .. tostring(player.UserId), {
                Cancel = function()
                    return player.Parent == nil
                end,
            })
        end)
        profile = if ok then result else nil
    end

    local data: any
    if profile then
        profile:AddUserId(player.UserId)
        writeInto(profile.Data, MigrationService.migrate(profile.Data))
        data = profile.Data
        profile.OnSessionEnd:Connect(function()
            sessions[player] = nil
        end)
        getLog():info("Sesión iniciada — %s (Version %d)", tostring(player.UserId), data.Version)
    else
        -- Degradación explícita: la partida funciona, los datos no persisten
        data = MigrationService.migrate(nil)
        getLog():warn(
            "Sesión de ProfileStore no disponible para %s — datos por defecto, sin persistencia",
            tostring(player.UserId)
        )
    end

    stampJoinDates(data)
    sessions[player] = {
        profile = profile,
        data = data,
        sessionStart = os.time(),
    }
    return data
end

--- Flush explícito (Profile:Save()). NUNCA cierra la sesión (DL-020).
--- ProfileStore ya auto-guarda periódicamente — esto solo adelanta el guardado
--- en momentos significativos (fin de ronda).
function PlayerDataService.savePlayer(player: any)
    local session = sessions[player]
    if not session or not session.profile then
        return
    end
    if session.profile:IsActive() then
        session.profile:Save()
    end
end

--- Retorna el PlayerData en memoria, o nil si no hay sesión.
--- Nunca lanza excepción — seguro ante player nil (PER-003).
function PlayerDataService.getData(player: any): any?
    local session = sessions[player]
    return if session then session.data else nil
end

--- Cierra la sesión (Profile:EndSession()) — ÚNICO punto de cierre, solo en
--- PlayerRemoving (DL-020). ProfileStore guarda al cerrar. Acumula TimePlayed.
function PlayerDataService.releasePlayer(player: any)
    local session = sessions[player]
    if not session then
        return
    end
    sessions[player] = nil

    session.data.Stats.TimePlayed += os.time() - session.sessionStart

    if session.profile and session.profile:IsActive() then
        session.profile:EndSession()
    end
end

return PlayerDataService
