-- GameManager
-- Punto de entrada del ciclo de vida (§4.4, GM-003). Único propietario del
-- estado global Lobby/Active/Summary. Llama start/stop/reset solo sobre
-- RoundManager y loadPlayer/savePlayer/releasePlayer sobre PlayerDataService
-- (§4.8) — nunca sobre módulos de gameplay directamente.
--
-- Ciclo de sesión de PlayerData (DL-020): atado al jugador, no a la ronda.
--   PlayerAdded    → loadPlayer   (StartSessionAsync + migración)
--   fin de ronda   → savePlayer   (flush — la sesión NO se cierra)
--   PlayerRemoving → releasePlayer (EndSession — único punto de cierre)
--
-- Lune-compatible (§4.6): servicios y módulos se resuelven dentro de funciones.

local GameManager = {}

type GamePhase = "Lobby" | "Active" | "Summary"

-- ─── Estado interno ────────────────────────────────────────────────────────────

local phase: GamePhase = "Lobby"
local running = false
local initialized = false
local roundOver = false

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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("GameManager")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getRoundManager()
    return require(game:GetService("ServerScriptService").Systems.RoundManager)
end

local function getPlayerDataService()
    return require(game:GetService("ServerScriptService").Systems.Persistence.PlayerDataService)
end

local function getRoundConfig()
    return require(game:GetService("ReplicatedStorage").Shared.Config.RoundConfig)
end

local RoundPhase: any = nil
local function phases()
    if not RoundPhase then
        RoundPhase = require(game:GetService("ReplicatedStorage").Shared.Constants.RoundPhase)
    end
    return RoundPhase
end

local function getStatRules()
    return require(game:GetService("ReplicatedStorage").Shared.Rules.StatRules)
end

-- ─── Stats de ronda (§2.5) ─────────────────────────────────────────────────────

local function applyMatchStarted()
    local PlayerDataService = getPlayerDataService()
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        local data = PlayerDataService.getData(player)
        if data then
            data.Stats.MatchesStarted += 1
        end
    end
end

--- Aplica al PlayerData los deltas de stats. El CÁLCULO (summary → deltas por
--- jugador, indexado por ObjectId §2.4) es puro y vive en Rules/StatRules;
--- aquí solo se aplican los efectos sobre el dato en memoria.
local function applyRoundStats(summary: any)
    local Players = game:GetService("Players")
    local PlayerDataService = getPlayerDataService()

    local deltas = getStatRules().computeStatDeltas(summary.StoryEvents)
    for playerId, delta in pairs(deltas) do
        local player = Players:GetPlayerByUserId(playerId)
        local data = if player then PlayerDataService.getData(player) else nil
        if data then
            data.Stats.ObjectsSaved += delta.saved
            for objectId, count in pairs(delta.byType) do
                data.Stats.ObjectsSavedByType[objectId] = (data.Stats.ObjectsSavedByType[objectId] or 0) + count
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local data = PlayerDataService.getData(player)
        if data then
            data.Stats.MatchesCompleted += 1
        end
        -- Flush explícito al final de ronda (DL-020) — nunca EndSession aquí
        PlayerDataService.savePlayer(player)
    end
end

-- ─── Ciclo de vida ─────────────────────────────────────────────────────────────

local function setPhase(newPhase: GamePhase)
    phase = newPhase
    getLog():info("Fase global → %s", newPhase)
end

local function waitForPlayers(minPlayers: number)
    local Players = game:GetService("Players")
    while running and #Players:GetPlayers() < minPlayers do
        task.wait(1)
    end
end

local function lifecycleLoop()
    local RoundConfig = getRoundConfig()
    local RoundManager = getRoundManager()

    while running do
        -- LOBBY: espera fija + mínimo de jugadores (RoundConfig)
        setPhase(phases().LOBBY)
        task.wait(RoundConfig.LOBBY_DURATION)
        waitForPlayers(RoundConfig.MIN_PLAYERS_TO_START)
        if not running then
            break
        end

        -- ACTIVE: RoundManager posee la ronda; GameManager solo espera el
        -- aviso de fin de timer (RoundManager nunca transiciona el estado)
        setPhase(phases().ACTIVE)
        applyMatchStarted()
        roundOver = false
        RoundManager.start({
            onTimeExpired = function()
                roundOver = true
            end,
        })
        while running and not roundOver do
            task.wait(0.25)
        end

        -- SUMMARY: compilar resultados, aplicar stats, flush de PlayerData
        local summary = RoundManager.stop()
        applyRoundStats(summary)
        setPhase(phases().SUMMARY)
        task.wait(RoundConfig.SUMMARY_DURATION)

        RoundManager.reset()
    end
end

-- ─── API pública — llamada solo por Main.server.lua ───────────────────────────

--- Conecta el ciclo de sesión de jugadores. Idempotente.
function GameManager.init()
    if initialized then
        getLog():warn("init() llamado más de una vez — ignorado")
        return
    end
    initialized = true

    local Players = game:GetService("Players")
    local PlayerDataService = getPlayerDataService()

    Players.PlayerAdded:Connect(function(player)
        PlayerDataService.loadPlayer(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        PlayerDataService.releasePlayer(player)
    end)

    -- Jugadores que entraron antes de conectar la señal (arranque en Studio)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            PlayerDataService.loadPlayer(player)
        end)
    end

    getLog():info("Inicializado — ciclo de sesión conectado")
end

--- Arranca el loop Lobby → Active → Summary → Lobby.
function GameManager.start()
    if running then
        return
    end
    running = true
    task.spawn(lifecycleLoop)
end

--- Detiene el loop al final del ciclo actual (para tests/shutdown).
function GameManager.stop()
    running = false
end

--- Fase global actual — solo lectura.
function GameManager.getPhase(): GamePhase
    return phase
end

return GameManager
