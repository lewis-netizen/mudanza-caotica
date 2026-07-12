-- SummaryManager
-- Summary Screen básica (UI-003, versión slice). Muestra salvados/perdidos,
-- el comentario narrativo del servidor y los StoryEvents en lenguaje
-- narrativo — sin rankings, puntuaciones ni recompensas (§3.5).
-- Lee estado EXCLUSIVAMENTE de ClientStateManager (§4.10). Janitor (§4.11).

local SummaryManager = {}

local MAX_STORY_LINES = 6

-- Narrativa por EventType — lenguaje de historia, no de estadística (UI-003)
local EVENT_PHRASES: { [string]: string } = {
    ObjectDelivered = "Un mueble llegó al camión sano y salvo.",
    ObjectDropped = "A alguien se le cayó algo por el camino.",
    SupportLost = "Un objeto grande se quedó sin manos suficientes.",
    SupportRestored = "El refuerzo llegó justo a tiempo.",
    RoundEventStarted = "El edificio decidió complicar el día.",
}

local janitor: any = nil
local rootFrame: any = nil
local statsLabel: any = nil
local commentLabel: any = nil
local storyContainer: any = nil

local function makeLabel(parent: any, height: number, text: string, bold: boolean): any
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -24, 0, height)
    label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
    label.TextSize = if bold then 22 else 16
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextWrapped = true
    label.Text = text
    label.Parent = parent
    return label
end

local function buildGui(playerGui: any): any
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MudanzaSummary"
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromOffset(420, 360)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 16)
    padding.PaddingBottom = UDim.new(0, 16)
    padding.Parent = frame

    makeLabel(frame, 30, "La mudanza terminó", true)
    statsLabel = makeLabel(frame, 24, "", false)
    commentLabel = makeLabel(frame, 40, "", false)

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -24, 1, -140)
    container.Parent = frame

    local storyLayout = Instance.new("UIListLayout")
    storyLayout.Padding = UDim.new(0, 4)
    storyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    storyLayout.Parent = container

    storyContainer = container
    screenGui.Parent = playerGui
    rootFrame = frame
    return screenGui
end

local function renderStoryEvents(storyEvents: { any })
    for _, child in ipairs(storyContainer:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local shown = 0
    for index = #storyEvents, 1, -1 do
        if shown >= MAX_STORY_LINES then
            break
        end
        local event = storyEvents[index]
        local phrase = EVENT_PHRASES[event.EventType]
        if phrase then
            local minutes = math.floor((event.Timestamp or 0) // 60)
            local seconds = math.floor((event.Timestamp or 0) % 60)
            local label =
                makeLabel(storyContainer, 20, string.format("Min %d:%02d — %s", minutes, seconds, phrase), false)
            label.TextSize = 14
            label.LayoutOrder = shown
            shown += 1
        end
    end
end

local function onState(state: any)
    if not rootFrame then
        return
    end
    local showing = state.phase == "Summary" and state.summary ~= nil
    rootFrame.Visible = showing
    if not showing then
        return
    end

    local summary = state.summary
    statsLabel.Text = string.format("Salvados: %d   ·   Perdidos: %d", summary.SavedObjects, summary.LostObjects)
    commentLabel.Text = summary.ClientComment or ""
    renderStoryEvents(summary.StoryEvents or {})
end

--- Construye la Summary Screen y se suscribe al estado. Idempotente.
function SummaryManager.init()
    if janitor then
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Janitor = require(ReplicatedStorage.Packages.Janitor)
    janitor = Janitor.new()

    local player = game:GetService("Players").LocalPlayer
    local screenGui = buildGui(player:WaitForChild("PlayerGui"))
    janitor:Add(screenGui, "Destroy")

    local ClientStateManager = require(script.Parent:WaitForChild("ClientStateManager"))
    janitor:Add(ClientStateManager.subscribe("SummaryManager", onState), true)
end

--- Libera GUI y suscripción.
function SummaryManager.cleanup()
    if janitor then
        janitor:Destroy()
        janitor = nil
        rootFrame = nil
        statsLabel = nil
        commentLabel = nil
        storyContainer = nil
    end
end

return SummaryManager
