-- NPCManager
-- El vecino: NPC que patrulla los NPCNodes en orden de NodeIndex usando
-- EXCLUSIVAMENTE TweenService (§4.4, WLD-004) — sin pathfinding del motor,
-- prohibido por §4.6. Colisión activa: bloquea el paso (Entropía Espacial §3.4).
--
-- El orden y el avance de la patrulla son puros (Rules/NPCRules, §4.13); aquí
-- vive el shell: construir el NPC placeholder, tween entre nodos y el ciclo.
-- RoundManager es el único caller de start/stop/reset (§4.8), bajo
-- FEATURE_FLAGS.ENABLE_NPC.
--
-- Lune-compatible (§4.6): servicios dentro de funciones.

local NPCManager = {}

-- ─── Estado interno ────────────────────────────────────────────────────────────

local active = false
local npcModel: any = nil
local homeCFrame: any = nil
local currentTween: any = nil

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
        return require(game:GetService("ReplicatedStorage").Shared.Lib.Logger).new("NPCManager")
    end)
    log = if ok then result else NOOP_LOG
    return log
end

local function getNPCRules()
    return require(game:GetService("ReplicatedStorage").Shared.Rules.NPCRules)
end

-- ─── Construcción del NPC placeholder ──────────────────────────────────────────
-- Figura simple de Parts (el arte final es humano, como los prefabs WLD-008).
-- La raíz (torso) es el volumen de colisión, anclada — el movimiento es por
-- Tween del CFrame de la raíz; los detalles van soldados sin colisión.

local function buildNPC(): any
    local model = Instance.new("Model")
    model.Name = "Vecino" -- cosmético; la identificación es por Tag (§2.4)

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 3, 1)
    torso.Color = Color3.fromRGB(86, 110, 140) -- bata azul del vecino
    torso.Anchored = true
    torso.CanCollide = true
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.Parent = model
    model.PrimaryPart = torso

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Color = Color3.fromRGB(224, 187, 148)
    head.Anchored = false
    head.CanCollide = false
    head.Massless = true
    head.CFrame = torso.CFrame * CFrame.new(0, 2.1, 0)
    head.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = torso
    weld.Part1 = head
    weld.Parent = head

    game:GetService("CollectionService"):AddTag(torso, "NPCModel")
    return model
end

--- Nodos de patrulla ordenados por NodeIndex (orden puro — NPCRules).
local function collectPatrol(): { any }
    local CollectionService = game:GetService("CollectionService")
    local refs = {}
    for _, node in ipairs(CollectionService:GetTagged("NPCNode")) do
        table.insert(refs, { index = node:GetAttribute("NodeIndex"), key = node })
    end
    return getNPCRules().orderedPatrol(refs)
end

-- ─── Ciclo de patrulla ─────────────────────────────────────────────────────────

local function patrolLoop(patrol: { any })
    local TweenService = game:GetService("TweenService")
    local GameplayConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameplayConfig)
    local speed = GameplayConfig.NPC_SPEED
    local step = 1

    while active do
        step = getNPCRules().nextStep(step, #patrol)
        if step == 0 or not npcModel or not npcModel.PrimaryPart then
            return
        end
        local torso = npcModel.PrimaryPart
        local target = patrol[step]
        local goal = CFrame.new(target.Position + Vector3.new(0, torso.Size.Y / 2 + 0.5, 0))
        local duration = math.max(0.1, (goal.Position - torso.Position).Magnitude / speed)

        currentTween = TweenService:Create(torso, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = goal })
        currentTween:Play()
        currentTween.Completed:Wait()
        currentTween = nil
        if not active then
            return
        end
        task.wait(0.4) -- pausa breve en cada nodo — lectura del vecino que "ronda"
    end
end

-- ─── API pública — llamada solo por RoundManager (§4.8) ────────────────────────

--- Construye el NPC (una vez) y arranca la patrulla. Sin nodos: warn y no-op.
function NPCManager.start()
    if active then
        return
    end
    local patrol = collectPatrol()
    if #patrol == 0 then
        getLog():warn("Sin Parts con Tag NPCNode — el NPC no patrulla (ver §4.4)")
        return
    end

    if not npcModel then
        npcModel = buildNPC()
        local first = patrol[1]
        local torso = npcModel.PrimaryPart
        homeCFrame = CFrame.new(first.Position + Vector3.new(0, torso.Size.Y / 2 + 0.5, 0))
        npcModel:PivotTo(homeCFrame)
        npcModel.Parent = game:GetService("Workspace")
    end

    active = true
    task.spawn(patrolLoop, patrol)
    getLog():info("NPC patrullando %d nodos (TweenService)", #patrol)
end

--- Detiene el movimiento sin errores — incluso a mitad de un Tween.
function NPCManager.stop()
    active = false
    if currentTween then
        pcall(function()
            currentTween:Cancel()
        end)
        currentTween = nil
    end
end

--- Devuelve el NPC a su posición inicial limpiamente.
function NPCManager.reset()
    NPCManager.stop()
    if npcModel and homeCFrame then
        pcall(function()
            npcModel:PivotTo(homeCFrame)
        end)
    end
end

return NPCManager
