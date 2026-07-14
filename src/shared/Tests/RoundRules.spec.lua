-- RoundRules.spec.lua — núcleo puro de la lógica de ronda.
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(RoundRules)
    if not RoundRules then
        describe("RoundRules", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    describe("buildClientComment — 3 umbrales (UI-003)", function()
        it("sin objetos → comentario neutro", function()
            expect(RoundRules.buildClientComment(0, 0)).to.equal("No había nada que mudar. El camión se fue igual.")
        end)
        it("ratio alto (≥0.8) → comentario alto", function()
            expect(RoundRules.buildClientComment(9, 1)).to.equal(
                "El camión se fue lleno. Mudanza de profesionales — casi."
            )
        end)
        it("ratio medio (0.4–0.8) → comentario medio", function()
            expect(RoundRules.buildClientComment(1, 1)).to.equal("Se salvó lo importante. Probablemente.")
        end)
        it("ratio bajo (<0.4) → comentario bajo", function()
            expect(RoundRules.buildClientComment(1, 9)).to.equal(
                "El camión se fue casi vacío. El vecino sigue riéndose."
            )
        end)
    end)

    describe("countLost", function()
        it("cuenta objetos no entregados", function()
            local objects = {
                { State = "delivered" },
                { State = "free" },
                { State = "being_carried" },
            }
            expect(RoundRules.countLost(objects, "delivered")).to.equal(2)
        end)
        it("lista vacía → 0", function()
            expect(RoundRules.countLost({}, "delivered")).to.equal(0)
        end)
        it("todos entregados → 0", function()
            expect(RoundRules.countLost({ { State = "delivered" }, { State = "delivered" } }, "delivered")).to.equal(0)
        end)
    end)
end
