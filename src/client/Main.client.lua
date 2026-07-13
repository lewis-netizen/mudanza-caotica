-- Main.client.lua
-- Entry point del cliente (GM-001). Solo bootstrapping — toda la lógica
-- vive en ModuleScripts (§4.1).
--
-- El acceso a servicios ocurre dentro de bootstrap() para cumplir el
-- contrato de scope de módulo (§4.6).

local function bootstrap()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local modules = script.Parent

    -- ClientStateManager primero — los módulos de UI leen de él (§4.10)
    require(modules:WaitForChild("ClientStateManager")).init()
    require(modules:WaitForChild("HUDManager")).init()

    local GlobalConfig = require(ReplicatedStorage.Shared.Config.GlobalConfig)
    if GlobalConfig.FEATURE_FLAGS.ENABLE_SUMMARY_SCREEN then
        require(modules:WaitForChild("SummaryManager")).init()
    end
end

bootstrap()
