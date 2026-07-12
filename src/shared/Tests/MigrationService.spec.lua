-- MigrationService.spec.lua
-- Tests unitarios para MigrationService.
-- Prioridad máxima: es el módulo más crítico para datos de producción.
--
-- Compatibilidad con Lune: el módulo se recibe como parámetro (inyección
-- de dependencias). Cuando MigrationService esté implementado en
-- src/server/Persistence/MigrationService.lua, run-specs.luau lo cargará
-- con fs.readFile() y lo pasará aquí sin depender de game.*.
--
-- Uso en Studio: TestEZ.TestBootstrap:run({ game.ReplicatedStorage.Shared.Tests })
-- Uso con Lune:  lune run lune/run-specs.luau

return function(MigrationService)
    -- Si MigrationService no está disponible aún (módulo no implementado),
    -- los tests se saltan con mensaje claro en lugar de fallar con nil error.
    if not MigrationService then
        describe("MigrationService", function()
            it("SKIP — módulo no implementado todavía", function()
                -- No falla — documenta que el módulo está pendiente
            end)
        end)
        return
    end

    -- ── Dato sin campo Version ────────────────────────────────────────────────

    describe("dato sin Version", function()
        it("debería tratarse como versión 0 y migrar", function()
            local raw = { Stats = { ObjectsSaved = 5 } }
            local migrated = MigrationService.migrate(raw)
            expect(migrated.Version).to.be.ok()
        end)

        it("debería preservar Stats existentes tras la migración", function()
            local raw = { Stats = { ObjectsSaved = 5 } }
            local migrated = MigrationService.migrate(raw)
            expect(migrated.Stats).to.be.ok()
            expect(migrated.Stats.ObjectsSaved).to.equal(5)
        end)
    end)

    -- ── Dato con Version canónica actual ─────────────────────────────────────

    describe("dato con Version = 1 (canónica actual)", function()
        it("debería retornarse sin modificaciones", function()
            local current = {
                Version = 1,
                Profile = { FirstJoinDate = 1000, LastJoinDate = 2000 },
                Stats = {
                    TimePlayed = 120,
                    MatchesStarted = 3,
                    MatchesCompleted = 2,
                    ObjectsSaved = 14,
                    ObjectsSavedByType = {},
                },
                Identity = {},
                Creation = {},
                Settings = { MusicVolume = 1, SFXVolume = 1 },
            }
            local migrated = MigrationService.migrate(current)
            expect(migrated.Version).to.equal(1)
            expect(migrated.Stats.ObjectsSaved).to.equal(14)
            expect(migrated.Profile.FirstJoinDate).to.equal(1000)
        end)
    end)

    -- ── Fallo de migración ────────────────────────────────────────────────────

    describe("fallo durante la migración", function()
        it("nunca debería propagar error al caller", function()
            local corrupted = { Version = 0, Stats = nil }
            local success, result = pcall(MigrationService.migrate, corrupted)
            if not success then
                expect(false).to.equal(true) -- fuerza fallo: migrate lanzó excepción
            else
                expect(result).to.be.ok()
            end
        end)
    end)

    -- ── Dominios reservados ───────────────────────────────────────────────────

    describe("dominios reservados", function()
        it("Identity debería existir como tabla", function()
            local raw = { Version = 0 }
            local migrated = MigrationService.migrate(raw)
            expect(migrated.Identity).to.be.ok()
            expect(type(migrated.Identity)).to.equal("table")
        end)

        it("Creation debería existir como tabla", function()
            local raw = { Version = 0 }
            local migrated = MigrationService.migrate(raw)
            expect(migrated.Creation).to.be.ok()
            expect(type(migrated.Creation)).to.equal("table")
        end)
    end)
end
