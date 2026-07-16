-- PlayerDataService.spec.lua
-- Tests unitarios para PlayerDataService.
-- Foco: PlayerDataService es un wrapper delgado sobre ProfileStore (§4.7).
-- No testea retry/session-locking — eso es responsabilidad de ProfileStore
-- (paquete externo, no auditado por contratos del proyecto).
--
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(PlayerDataService)
    if not PlayerDataService then
        describe("PlayerDataService", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    -- ── Interfaz pública ─────────────────────────────────────────────────────

    describe("interfaz pública", function()
        it("expone loadPlayer(player)", function()
            expect(PlayerDataService.loadPlayer).to.be.ok()
            expect(type(PlayerDataService.loadPlayer)).to.equal("function")
        end)

        it("expone savePlayer(player)", function()
            expect(PlayerDataService.savePlayer).to.be.ok()
            expect(type(PlayerDataService.savePlayer)).to.equal("function")
        end)

        it("expone getData(player)", function()
            expect(PlayerDataService.getData).to.be.ok()
            expect(type(PlayerDataService.getData)).to.equal("function")
        end)
    end)

    -- ── No reimplementa lo que ya provee ProfileStore ────────────────────────
    -- Estos tests documentan la invariante arquitectónica: PlayerDataService
    -- es un wrapper de dominio, no una reimplementación de DataStore.

    describe("scope de responsabilidad", function()
        it("no expone funciones de retry manual (responsabilidad de ProfileStore)", function()
            expect(PlayerDataService.retryLoad).never.to.be.ok()
            expect(PlayerDataService.retrySave).never.to.be.ok()
        end)

        it("no expone acceso directo a DataStoreService de Roblox", function()
            expect(PlayerDataService.GetDataStore).never.to.be.ok()
            expect(PlayerDataService.getDataStore).never.to.be.ok()
        end)
    end)

    -- ── getData nunca propaga excepción ──────────────────────────────────────

    describe("getData", function()
        it("nunca propaga excepción al caller, incluso sin sesión activa", function()
            expect(function()
                PlayerDataService.getData(nil :: any)
            end).never.to.throw()
        end)
    end)

    -- ── _writeInto: guarda de aliasing ───────────────────────────────────────
    -- Regresión del self-wipe (runtime, QA): migrate() de un dato ya canónico
    -- devuelve la MISMA tabla; sin la guarda, limpiar target borraba source.

    describe("_writeInto", function()
        it("misma referencia → no borra nada (guarda de aliasing)", function()
            local data = { Version = 1, Profile = { FirstJoinDate = 123 } }
            PlayerDataService._writeInto(data, data)
            expect(data.Version).to.equal(1)
            expect(data.Profile.FirstJoinDate).to.equal(123)
        end)

        it("referencias distintas → reemplaza el contenido del target", function()
            local target = { old = true, Version = 0 }
            local source = { Version = 1, Profile = {} }
            PlayerDataService._writeInto(target, source)
            expect(target.old).never.to.be.ok()
            expect(target.Version).to.equal(1)
            expect(target.Profile).to.be.ok()
        end)
    end)
end
