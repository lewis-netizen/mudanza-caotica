-- SummaryManager
-- Summary Screen básica (UI-003, versión slice). Muestra salvados/perdidos, el
-- comentario narrativo del servidor y los StoryEvents en lenguaje narrativo —
-- sin rankings, puntuaciones ni recompensas (§3.5).
--
-- Fusion declarativo (§4.14, DL-042): deriva de Value/Computed que un ÚNICO
-- subscribe a ClientStateManager (§4.10) actualiza; la lista de StoryEvents se
-- renderiza con ForValues. No conecta RemoteEvents (INV-001). Lifecycle vía el
-- scope de Fusion (doCleanup).
--
-- Lune-compatible (§4.6): dependencias y servicios se resuelven en init().

local SummaryManager = {}

local MAX_STORY_LINES = 6

-- Narrativa por EventType — lenguaje de historia, no de estadística (UI-003).
local EVENT_PHRASES: { [string]: string } = {
    ObjectDelivered = "Un mueble llegó al camión sano y salvo.",
    ObjectDropped = "A alguien se le cayó algo por el camino.",
    SupportLost = "Un objeto grande se quedó sin manos suficientes.",
    SupportRestored = "El refuerzo llegó justo a tiempo.",
    RoundEventStarted = "El edificio decidió complicar el día.",
}

-- Fusion scope del módulo. nil = no inicializado (idempotencia).
local scope: any = nil

type StoryLine = { order: number, text: string }

--- Núcleo puro: convierte los StoryEvents de la ronda en líneas narrativas
--- ordenadas (más recientes primero, máx MAX_STORY_LINES). El `order` se hornea
--- en cada línea porque ForValues no expone la key al processor.
local function buildStoryLines(storyEvents: { any }): { StoryLine }
    local lines: { StoryLine } = {}
    local shown = 0
    for index = #storyEvents, 1, -1 do
        if shown >= MAX_STORY_LINES then
            break
        end
        local event = storyEvents[index]
        local phrase = EVENT_PHRASES[event.EventType]
        if phrase then
            local timestamp = event.Timestamp or 0
            shown += 1
            table.insert(lines, {
                order = shown,
                text = string.format(
                    "Min %d:%02d — %s",
                    math.floor(timestamp // 60),
                    math.floor(timestamp % 60),
                    phrase
                ),
            })
        end
    end
    return lines
end

--- Construye la Summary Screen y se suscribe al estado. Idempotente.
function SummaryManager.init()
    if scope then
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Fusion = require(ReplicatedStorage.Packages.Fusion)
    local Phase = require(ReplicatedStorage.Shared.Constants.RoundPhase)
    local ClientStateManager = require(script.Parent:WaitForChild("ClientStateManager"))

    local Children = Fusion.Children
    scope = Fusion.scoped(Fusion)

    -- Espejos reactivos del summary.
    local visible = scope:Value(false)
    local statsText = scope:Value("")
    local commentText = scope:Value("")
    local storyLines = scope:Value({} :: { StoryLine })

    table.insert(
        scope,
        ClientStateManager.subscribe("SummaryManager", function(state)
            local showing = state.phase == Phase.SUMMARY and state.summary ~= nil
            visible:set(showing)
            if not showing then
                return
            end
            local summary = state.summary
            statsText:set(string.format("Salvados: %d   ·   Perdidos: %d", summary.SavedObjects, summary.LostObjects))
            commentText:set(summary.ClientComment or "")
            storyLines:set(buildStoryLines(summary.StoryEvents or {}))
        end)
    )

    local player = game:GetService("Players").LocalPlayer

    scope:New("ScreenGui")({
        Name = "MudanzaSummary",
        ResetOnSpawn = false,
        Parent = player:WaitForChild("PlayerGui"),

        [Children] = scope:New("Frame")({
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(420, 360),
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Visible = visible,

            [Children] = {
                scope:New("UICorner")({ CornerRadius = UDim.new(0, 12) }),
                scope:New("UIListLayout")({
                    Padding = UDim.new(0, 8),
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                scope:New("UIPadding")({
                    PaddingTop = UDim.new(0, 16),
                    PaddingBottom = UDim.new(0, 16),
                }),

                scope:New("TextLabel")({
                    LayoutOrder = 1,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -24, 0, 30),
                    Font = Enum.Font.GothamBold,
                    TextSize = 22,
                    TextColor3 = Color3.fromRGB(240, 240, 240),
                    TextWrapped = true,
                    Text = "La mudanza terminó",
                }),
                scope:New("TextLabel")({
                    LayoutOrder = 2,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -24, 0, 24),
                    Font = Enum.Font.Gotham,
                    TextSize = 16,
                    TextColor3 = Color3.fromRGB(240, 240, 240),
                    TextWrapped = true,
                    Text = statsText,
                }),
                scope:New("TextLabel")({
                    LayoutOrder = 3,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -24, 0, 40),
                    Font = Enum.Font.Gotham,
                    TextSize = 16,
                    TextColor3 = Color3.fromRGB(240, 240, 240),
                    TextWrapped = true,
                    Text = commentText,
                }),

                -- Contenedor de StoryEvents — lista dinámica vía ForValues.
                scope:New("Frame")({
                    LayoutOrder = 4,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -24, 1, -140),
                    [Children] = {
                        scope:New("UIListLayout")({
                            Padding = UDim.new(0, 4),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        }),
                        scope:ForValues(storyLines, function(_, innerScope: any, line: StoryLine)
                            return innerScope:New("TextLabel")({
                                LayoutOrder = line.order,
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, -24, 0, 20),
                                Font = Enum.Font.Gotham,
                                TextSize = 14,
                                TextColor3 = Color3.fromRGB(240, 240, 240),
                                TextWrapped = true,
                                Text = line.text,
                            })
                        end),
                    },
                }),
            },
        }),
    })
end

--- Libera GUI y suscripción (el scope completo, en orden inverso).
function SummaryManager.cleanup()
    if scope then
        scope:doCleanup()
        scope = nil
    end
end

return SummaryManager
