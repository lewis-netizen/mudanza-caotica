-- ObjectState.spec.lua
-- Fija el formato de wire de los estados de ObjectInstance (§4.3).
-- Estos literales viajan en ObjectStateChanged y ObjectManager los replica en
-- su VALID_STATES local (dueño del estado, §4.8) — este spec pinnea los
-- valores canónicos; ObjectManager.spec verifica el comportamiento con ellos.
--
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(ObjectState)
    if not ObjectState then
        describe("ObjectState", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    describe("valores canónicos (contrato de wire §4.3)", function()
        it("FREE es 'free'", function()
            expect(ObjectState.FREE).to.equal("free")
        end)

        it("BEING_CARRIED es 'being_carried'", function()
            expect(ObjectState.BEING_CARRIED).to.equal("being_carried")
        end)

        it("DELIVERED es 'delivered'", function()
            expect(ObjectState.DELIVERED).to.equal("delivered")
        end)
    end)

    describe("inmutabilidad", function()
        it("la tabla está congelada — nadie puede mutar el contrato", function()
            expect(table.isfrozen(ObjectState)).to.equal(true)
        end)
    end)
end
