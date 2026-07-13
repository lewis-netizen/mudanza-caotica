-- RoundPhase.spec.lua
-- Fija los valores canónicos de las fases globales (§4.4).
--
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(RoundPhase)
    if not RoundPhase then
        describe("RoundPhase", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    describe("valores canónicos", function()
        it("LOBBY es 'Lobby'", function()
            expect(RoundPhase.LOBBY).to.equal("Lobby")
        end)

        it("ACTIVE es 'Active'", function()
            expect(RoundPhase.ACTIVE).to.equal("Active")
        end)

        it("SUMMARY es 'Summary'", function()
            expect(RoundPhase.SUMMARY).to.equal("Summary")
        end)
    end)

    describe("inmutabilidad", function()
        it("la tabla está congelada", function()
            expect(table.isfrozen(RoundPhase)).to.equal(true)
        end)
    end)
end
