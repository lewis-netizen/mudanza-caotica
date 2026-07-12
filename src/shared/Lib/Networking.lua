-- Networking
-- Fuente única de referencias a RemoteEvents del proyecto.
-- Ningún otro módulo referencia ReplicatedStorage.Remotes.* directamente.
--
-- INVARIANTE: toda conexión a RemoteEvents pasa por este módulo.
-- INVARIANTE: la dirección de cada evento está comentada.
-- INVARIANTE: el número de RemoteEvents no supera 7 sin aprobación del PO (§4.3).
--
-- Lune-compatible: ReplicatedStorage se accede dentro de la función init(),
-- no en el scope del módulo. (inyección de dependencias — §4.6)

local Networking = {}
local _remotes = nil

local function getRemotes()
    if _remotes then
        return _remotes
    end
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local Gameplay = Remotes:WaitForChild("Gameplay")
    local Round = Remotes:WaitForChild("Round")
    _remotes = {
        -- Gameplay: cliente → servidor
        InteractObject = Gameplay:WaitForChild("InteractObject"),
        -- Gameplay: servidor → clientes
        DeliverObject = Gameplay:WaitForChild("DeliverObject"),
        ObjectStateChanged = Gameplay:WaitForChild("ObjectStateChanged"),
        -- Round: servidor → clientes
        EventTriggered = Round:WaitForChild("EventTriggered"),
        RoundStarted = Round:WaitForChild("RoundStarted"),
        RoundEnded = Round:WaitForChild("RoundEnded"),
        TimerSync = Round:WaitForChild("TimerSync"),
    }
    return _remotes
end

-- Proxy que resuelve los RemoteEvents al primer acceso
setmetatable(Networking, {
    __index = function(_, key)
        return getRemotes()[key]
    end,
})

return Networking
