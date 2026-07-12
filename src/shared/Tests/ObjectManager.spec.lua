-- ObjectManager.spec.lua
-- Tests unitarios para ObjectManager.
-- Foco: invariantes de estado — ObjectManager es el único propietario
-- de ObjectInstance.State.
--
-- Compatibilidad con Lune: el módulo se recibe como parámetro.
-- Cuando ObjectManager esté implementado, run-specs.luau lo pasará aquí.

return function(ObjectManager)
    if not ObjectManager then
        describe("ObjectManager", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    beforeEach(function()
        ObjectManager.reset()
    end)

    -- ── reset limpia todo el estado interno ──────────────────────────────────

    describe("reset", function()
        it("getAllObjects() retorna tabla vacía tras reset", function()
            ObjectManager.reset()
            local all = ObjectManager.getAllObjects()
            expect(#all).to.equal(0)
        end)

        it("getDeliveredCount() retorna 0 tras reset", function()
            ObjectManager.reset()
            expect(ObjectManager.getDeliveredCount()).to.equal(0)
        end)

        it("puede llamarse múltiples veces sin error", function()
            expect(function()
                ObjectManager.reset()
                ObjectManager.reset()
                ObjectManager.reset()
            end).never.to.throw()
        end)
    end)

    -- ── getObject retorna nil para instanceIds inexistentes ──────────────────

    describe("getObject", function()
        it("retorna nil para instanceId inexistente", function()
            local obj = ObjectManager.getObject("id-inexistente-jamás")
            expect(obj).never.to.be.ok()
        end)
    end)

    -- ── getFreeObjects solo retorna objetos free ──────────────────────────────

    describe("getFreeObjects", function()
        it("retorna una tabla", function()
            local free = ObjectManager.getFreeObjects()
            expect(type(free)).to.equal("table")
        end)

        it("solo contiene objetos en estado free", function()
            local free = ObjectManager.getFreeObjects()
            for _, instanceId in ipairs(free) do
                local obj = ObjectManager.getObject(instanceId)
                expect(obj.State).to.equal("free")
            end
        end)
    end)

    -- ── setState no crea estado fantasma para IDs inexistentes ───────────────

    describe("setState", function()
        it("no crea ObjectInstance para instanceId inexistente", function()
            ObjectManager.setState("id-fantasma", "being_carried", 12345, nil)
            local obj = ObjectManager.getObject("id-fantasma")
            -- Si el ID no existía, no debe aparecer en getAllObjects
            expect(obj).never.to.be.ok()
        end)
    end)
end
