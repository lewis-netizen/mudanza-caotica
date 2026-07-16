-- PromptController
-- Prompt contextual de interacción (UI-002): "E — Recoger" al acercarse a un
-- objeto free; "E — Soltar" mientras se carga. Completamente client-side —
-- CERO llamadas al servidor para consultas (UI-002).
--
-- Fusion declarativo (§4.14, DL-042). El objetivo lo resuelve
-- InteractionController.getTarget() — la lógica de targeting vive UNA vez, en
-- el dueño del input. Este módulo solo la consume en un poll de baja
-- frecuencia (task.wait — no per-frame, §4.12) y renderiza.
--
-- No conecta RemoteEvents (INV-001): la fase la lee de ClientStateManager.
--
-- Lune-compatible (§4.6): dependencias y servicios se resuelven en init().

local PromptController = {}

local POLL_INTERVAL = 0.15 -- s — fluido al caminar, sin coste por frame

-- Fusion scope del módulo. nil = no inicializado (idempotencia).
local scope: any = nil

--- Construye el prompt y arranca el poll. Idempotente.
function PromptController.init()
    if scope then
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Fusion = require(ReplicatedStorage.Packages.Fusion)
    local Phase = require(ReplicatedStorage.Shared.Constants.RoundPhase)
    local GlobalConfig = require(ReplicatedStorage.Shared.Config.GlobalConfig)
    local ClientStateManager = require(script.Parent:WaitForChild("ClientStateManager"))
    local InteractionController = require(script.Parent:WaitForChild("InteractionController"))

    local Children = Fusion.Children
    scope = Fusion.scoped(Fusion)

    local phase = scope:Value(Phase.LOBBY)
    local mode = scope:Value(nil :: string?) -- "pickup" | "drop" | nil

    table.insert(
        scope,
        ClientStateManager.subscribe("PromptController", function(state)
            phase:set(state.phase)
        end)
    )

    -- Poll del objetivo — cancelación por flag registrada en el scope
    local running = true
    table.insert(scope, function()
        running = false
    end)
    task.spawn(function()
        while running do
            task.wait(POLL_INTERVAL)
            if not running then
                return
            end
            local _, targetMode = InteractionController.getTarget()
            mode:set(targetMode)
        end
    end)

    local key = GlobalConfig.INTERACT_KEY
    local player = game:GetService("Players").LocalPlayer

    scope:New("ScreenGui")({
        Name = "MudanzaPrompt",
        ResetOnSpawn = false,
        Parent = player:WaitForChild("PlayerGui"),

        [Children] = scope:New("TextLabel")({
            Name = "InteractPrompt",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -96), -- bajo el centro — no tapa el gameplay (§3.7)
            Size = UDim2.fromOffset(220, 34),
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 18,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            -- Visible solo en ronda activa y con objetivo (free en rango, o cargando)
            Visible = scope:Computed(function(use)
                return use(phase) == Phase.ACTIVE and use(mode) ~= nil
            end),
            Text = scope:Computed(function(use)
                local m = use(mode)
                if m == "drop" then
                    return key .. " — Soltar"
                end
                return key .. " — Recoger"
            end),
            [Children] = scope:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
        }),
    })
end

--- Libera GUI, poll y suscripción (el scope completo, en orden inverso).
function PromptController.cleanup()
    if scope then
        scope:doCleanup()
        scope = nil
    end
end

return PromptController
