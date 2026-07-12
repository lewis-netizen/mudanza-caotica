-- Main.server.lua
-- Entry point del servidor (GM-001). Solo bootstrapping — toda la lógica
-- de juego vive en ModuleScripts (§4.1).
--
-- El acceso a servicios ocurre dentro de bootstrap() para cumplir el
-- contrato de scope de módulo (§4.6) verificado por check-compatibility.

local function bootstrap()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Systems = game:GetService("ServerScriptService").Systems

    local GlobalConfig = require(ReplicatedStorage.Shared.Config.GlobalConfig)
    local Logger = require(ReplicatedStorage.Shared.Lib.Logger)
    local log = Logger.new("Main.server")

    -- Registrar flags activos al inicio del servidor (contrato de GlobalConfig)
    for flag, enabled in pairs(GlobalConfig.FEATURE_FLAGS) do
        log:info("FeatureFlag %s = %s", flag, tostring(enabled))
    end

    require(Systems.MapBootstrap).ensure()

    local GameManager = require(Systems.GameManager)
    GameManager.init()
    GameManager.start()

    log:info("Servidor arrancado")
end

bootstrap()
