-- InteractionController
-- Captura el input del jugador y dispara InteractObject:FireServer (GAM-010).
-- Cierra el hueco de QA-001: el servidor escucha InteractObject (CarryManager,
-- INV-001) pero ningún cliente lo disparaba — el slice no era jugable.
--
-- INV-001: este módulo NO conecta ningún RemoteEvent (ni OnClientEvent ni
-- OnServerEvent). Solo FireServer (cliente→servidor, permitido en cualquier
-- módulo). El estado de los objetos se lee de ClientStateManager (§4.10);
-- la posición de los Parts, por Tag CarryObject + Attribute InstanceId (§2.4).
--
-- El servidor es la autoridad: revalida tipo/existencia/rango/estado y decide
-- pickup/drop/ignore (CarryRules.decideInteraction, GAM-003). Este módulo solo
-- propone un objetivo razonable.
--
-- Lune-compatible (§4.6): servicios y dependencias se resuelven en init().

local InteractionController = {}

local janitor: any = nil
local log: any = nil
local Networking: any = nil
local ClientStateManager: any = nil
local GlobalConfig: any = nil
local ObjectStates: any = nil -- Constants.ObjectState

-- Servicios — resueltos en init()
local Players: any = nil
local CollectionService: any = nil
local UserInputService: any = nil

--- Distancia al cuadrado entre dos Vector3 (evita sqrt — solo comparamos rango).
local function distSq(a: Vector3, b: Vector3): number
    local dx, dy, dz = a.X - b.X, a.Y - b.Y, a.Z - b.Z
    return dx * dx + dy * dy + dz * dz
end

--- HumanoidRootPart del personaje local, o nil si aún no está listo.
local function characterRoot(): any?
    local character = Players.LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

--- El objeto que el jugador local carga como líder, o nil. Se resuelve leyendo
--- el estado de ClientStateManager — sin round-trip al servidor.
local function carriedInstanceId(): string?
    local myUserId = Players.LocalPlayer.UserId
    local state = ClientStateManager.getState()
    for instanceId, object in pairs(state.objects) do
        if object.state == ObjectStates.BEING_CARRIED and object.leaderId == myUserId then
            return instanceId
        end
    end
    return nil
end

--- El objeto `free` más cercano dentro de rango, o nil. Localiza los Parts por
--- Tag CarryObject + Attribute InstanceId (§2.4) y cruza su estado con
--- ClientStateManager (solo `free` es recogible).
local function nearestFreeInRange(): string?
    local root = characterRoot()
    if not root then
        return nil
    end
    local origin = root.Position
    local bestSq = GlobalConfig.MAX_INTERACT_RANGE * GlobalConfig.MAX_INTERACT_RANGE
    local bestId: string? = nil
    local state = ClientStateManager.getState()

    for _, part in ipairs(CollectionService:GetTagged("CarryObject")) do
        local instanceId = part:GetAttribute("InstanceId")
        if type(instanceId) ~= "string" then
            continue
        end
        local snapshot = state.objects[instanceId]
        if not snapshot or snapshot.state ~= ObjectStates.FREE then
            continue
        end
        local d = distSq(origin, part.Position)
        if d <= bestSq then
            bestSq = d
            bestId = instanceId
        end
    end
    return bestId
end

--- Elige el objetivo y dispara InteractObject. Si cargo algo, esa interacción es
--- soltar (prioridad 1); si no, recoger el `free` más cercano en rango.
local function onInteract()
    local target = carriedInstanceId() or nearestFreeInRange()
    if not target then
        return
    end
    Networking.InteractObject:FireServer({ instanceId = target })
end

--- Conecta el input. Idempotente.
function InteractionController.init()
    if janitor then
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    Players = game:GetService("Players")
    CollectionService = game:GetService("CollectionService")
    UserInputService = game:GetService("UserInputService")

    local Janitor = require(ReplicatedStorage.Packages.Janitor)
    local Logger = require(ReplicatedStorage.Shared.Lib.Logger)
    Networking = require(ReplicatedStorage.Shared.Lib.Networking)
    GlobalConfig = require(ReplicatedStorage.Shared.Config.GlobalConfig)
    ObjectStates = require(ReplicatedStorage.Shared.Constants.ObjectState)
    ClientStateManager = require(script.Parent:WaitForChild("ClientStateManager"))

    log = Logger.new("InteractionController")
    janitor = Janitor.new()

    local interactKey = Enum.KeyCode[GlobalConfig.INTERACT_KEY]

    janitor:Add(
        UserInputService.InputBegan:Connect(function(input: any, gameProcessed: boolean)
            if gameProcessed then
                return
            end
            if input.KeyCode == interactKey then
                onInteract()
            end
        end),
        "Disconnect"
    )

    log:info("Inicializado — tecla de interacción: %s", GlobalConfig.INTERACT_KEY)
end

--- Desconecta el input. Idempotente.
function InteractionController.cleanup()
    if janitor then
        janitor:Destroy()
        janitor = nil
    end
end

return InteractionController
