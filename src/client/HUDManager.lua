-- HUDManager
-- HUD de ronda: timer MM:SS + conteo de entregas (UI-001).
-- Lee estado EXCLUSIVAMENTE de ClientStateManager (§4.10) — nunca conecta
-- RemoteEvents. Usa Janitor para el lifecycle de sus recursos (§4.11).
--
-- Se suscribe con timerUpdates = true: es el único módulo que necesita los
-- ticks por segundo de TimerSync (DL-025).

local HUDManager = {}

local janitor: any = nil
local rootFrame: any = nil
local timerLabel: any = nil
local deliveredLabel: any = nil
local Phase: any = nil -- Constants.RoundPhase, resuelto en init()

local function formatTime(totalSeconds: number): string
    local seconds = math.max(0, math.floor(totalSeconds))
    return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

local function buildGui(playerGui: any): any
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MudanzaHUD"
    screenGui.ResetOnSpawn = false -- sobrevive respawns — sin re-conexiones (UI-001)
    screenGui.IgnoreGuiInset = false

    -- Barra superior — nunca ocupa el centro de pantalla (UI-001)
    local frame = Instance.new("Frame")
    frame.Name = "RoundBar"
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0, 8)
    frame.Size = UDim2.fromOffset(220, 64)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local timer = Instance.new("TextLabel")
    timer.Name = "Timer"
    timer.BackgroundTransparency = 1
    timer.Size = UDim2.new(1, 0, 0.6, 0)
    timer.Font = Enum.Font.GothamBold
    timer.TextScaled = true
    timer.TextColor3 = Color3.fromRGB(255, 255, 255)
    timer.Text = "00:00"
    timer.Parent = frame

    local delivered = Instance.new("TextLabel")
    delivered.Name = "Delivered"
    delivered.BackgroundTransparency = 1
    delivered.Position = UDim2.new(0, 0, 0.6, 0)
    delivered.Size = UDim2.new(1, 0, 0.4, 0)
    delivered.Font = Enum.Font.Gotham
    delivered.TextScaled = true
    delivered.TextColor3 = Color3.fromRGB(200, 220, 200)
    delivered.Text = "Entregados: 0"
    delivered.Parent = frame

    screenGui.Parent = playerGui

    rootFrame = frame
    timerLabel = timer
    deliveredLabel = delivered
    return screenGui
end

local function onState(state: any)
    if not rootFrame then
        return
    end
    -- El HUD solo es visible durante la ronda activa (UI-001)
    rootFrame.Visible = state.phase == Phase.ACTIVE
    timerLabel.Text = formatTime(state.timeRemaining)
    deliveredLabel.Text = string.format("Entregados: %d", state.deliveredCount)
end

--- Construye el HUD y se suscribe al estado. Idempotente.
function HUDManager.init()
    if janitor then
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Janitor = require(ReplicatedStorage.Packages.Janitor)
    Phase = require(ReplicatedStorage.Shared.Constants.RoundPhase)
    janitor = Janitor.new()

    local player = game:GetService("Players").LocalPlayer
    local screenGui = buildGui(player:WaitForChild("PlayerGui"))
    janitor:Add(screenGui, "Destroy")

    local ClientStateManager = require(script.Parent:WaitForChild("ClientStateManager"))
    -- El cleanup de subscribe es una función — Janitor la invoca al destruir
    janitor:Add(ClientStateManager.subscribe("HUDManager", onState, { timerUpdates = true }), true)
end

--- Libera GUI y suscripción.
function HUDManager.cleanup()
    if janitor then
        janitor:Destroy()
        janitor = nil
        rootFrame = nil
        timerLabel = nil
        deliveredLabel = nil
    end
end

return HUDManager
