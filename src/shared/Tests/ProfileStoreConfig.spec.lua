-- ProfileStoreConfig.spec.lua
-- Tests para ProfileStoreConfig (PER-001) — configuración declarativa.
-- El template canónico se testea en MigrationService.spec (fuente única).
--
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(ProfileStoreConfig)
    if not ProfileStoreConfig then
        describe("ProfileStoreConfig", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    describe("configuración del store (PER-001)", function()
        it("STORE_NAME sigue el patrón versionado PlayerData_vN", function()
            expect(type(ProfileStoreConfig.STORE_NAME)).to.equal("string")
            expect(ProfileStoreConfig.STORE_NAME:match("^PlayerData_v%d+$")).to.be.ok()
        end)

        it("SESSION_KEY_PREFIX es un string no vacío", function()
            expect(type(ProfileStoreConfig.SESSION_KEY_PREFIX)).to.equal("string")
            expect(#ProfileStoreConfig.SESSION_KEY_PREFIX > 0).to.equal(true)
        end)

        it("es configuración declarativa — solo valores planos, sin funciones", function()
            for _, value in pairs(ProfileStoreConfig) do
                local kind = type(value)
                expect(kind == "string" or kind == "number" or kind == "boolean").to.equal(true)
            end
        end)
    end)
end
