-- NPCRules.spec.lua — núcleo puro de la patrulla del NPC (WLD-004).
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(NPCRules)
    if not NPCRules then
        describe("NPCRules", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    describe("orderedPatrol", function()
        it("ordena por NodeIndex ascendente", function()
            local patrol = NPCRules.orderedPatrol({
                { index = 3, key = "c" },
                { index = 1, key = "a" },
                { index = 2, key = "b" },
            })
            expect(patrol[1]).to.equal("a")
            expect(patrol[2]).to.equal("b")
            expect(patrol[3]).to.equal("c")
        end)
        it("descarta índices duplicados (se queda con el primero)", function()
            local patrol = NPCRules.orderedPatrol({
                { index = 1, key = "a" },
                { index = 1, key = "dup" },
                { index = 2, key = "b" },
            })
            expect(#patrol).to.equal(2)
            expect(patrol[1]).to.equal("a")
        end)
        it("descarta índices no numéricos", function()
            local patrol = NPCRules.orderedPatrol({
                { index = "x" :: any, key = "malo" },
                { index = 1, key = "a" },
            })
            expect(#patrol).to.equal(1)
            expect(patrol[1]).to.equal("a")
        end)
        it("lista vacía → patrulla vacía", function()
            expect(#NPCRules.orderedPatrol({})).to.equal(0)
        end)
    end)

    describe("nextStep", function()
        it("avanza secuencialmente", function()
            expect(NPCRules.nextStep(1, 6)).to.equal(2)
            expect(NPCRules.nextStep(5, 6)).to.equal(6)
        end)
        it("del último nodo vuelve al primero (circular)", function()
            expect(NPCRules.nextStep(6, 6)).to.equal(1)
        end)
        it("sin nodos → 0 (patrulla imposible)", function()
            expect(NPCRules.nextStep(1, 0)).to.equal(0)
        end)
    end)
end
