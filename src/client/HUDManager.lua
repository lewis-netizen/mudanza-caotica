-- HUDManager
-- HUD de ronda: timer MM:SS + conteo de entregas (UI-001).
-- Fusion declarativo (§4.14, DL-042): la UI deriva de Value/Computed que un
-- ÚNICO subscribe a ClientStateManager (§4.10) actualiza. No conecta
-- RemoteEvents (INV-001). Lifecycle vía el scope de Fusion (doCleanup).
--
-- Suscripción selectiva timerUpdates=true: único módulo con los ticks por
-- segundo de TimerSync (DL-025).
--
-- Lune-compatible (§4.6): dependencias y servicios se resuelven en init().

local HUDManager = {}

-- Fusion scope del módulo. nil = no inicializado (idempotencia).
local scope: any = nil

local function formatTime(totalSeconds: number): string
    local seconds = math.max(0, math.floor(totalSeconds))
    return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

--- Construye el HUD y se suscribe al estado. Idempotente.
function HUDManager.init()
    if scope then
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Fusion = require(ReplicatedStorage.Packages.Fusion)
    local Phase = require(ReplicatedStorage.Shared.Constants.RoundPhase)
    local ClientStateManager = require(script.Parent:WaitForChild("ClientStateManager"))

    local Children = Fusion.Children
    scope = Fusion.scoped(Fusion)

    -- Espejos reactivos del estado del cliente.
    local phase = scope:Value(Phase.LOBBY)
    local timeRemaining = scope:Value(0)
    local delivered = scope:Value(0)

    -- UN subscribe = la frontera imperativa→reactiva. El cleanup (función) se
    -- añade al scope para que doCleanup lo invoque junto con la GUI.
    table.insert(
        scope,
        ClientStateManager.subscribe("HUDManager", function(state)
            phase:set(state.phase)
            timeRemaining:set(state.timeRemaining)
            delivered:set(state.deliveredCount)
        end, { timerUpdates = true })
    )

    local player = game:GetService("Players").LocalPlayer

    scope:New("ScreenGui")({
        Name = "MudanzaHUD",
        ResetOnSpawn = false, -- sobrevive respawns sin re-conexiones (UI-001)
        Parent = player:WaitForChild("PlayerGui"),

        [Children] = scope:New("Frame")({
            Name = "RoundBar",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 8),
            Size = UDim2.fromOffset(220, 64),
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            -- El HUD solo es visible durante la ronda activa (UI-001).
            Visible = scope:Computed(function(use)
                return use(phase) == Phase.ACTIVE
            end),

            [Children] = {
                scope:New("UICorner")({
                    CornerRadius = UDim.new(0, 10),
                }),

                scope:New("TextLabel")({
                    Name = "Timer",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0.6, 0),
                    Font = Enum.Font.GothamBold,
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Text = scope:Computed(function(use)
                        return formatTime(use(timeRemaining))
                    end),
                }),

                scope:New("TextLabel")({
                    Name = "Delivered",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0.6, 0),
                    Size = UDim2.new(1, 0, 0.4, 0),
                    Font = Enum.Font.Gotham,
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(200, 220, 200),
                    Text = scope:Computed(function(use)
                        return string.format("Entregados: %d", use(delivered))
                    end),
                }),
            },
        }),
    })
end

--- Libera GUI y suscripción (el scope completo, en orden inverso).
function HUDManager.cleanup()
    if scope then
        scope:doCleanup()
        scope = nil
    end
end

return HUDManager
