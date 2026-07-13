-- StatRules.spec.lua — núcleo puro de atribución de estadísticas.
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(StatRules)
    if not StatRules then
        describe("StatRules", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    describe("computeStatDeltas", function()
        it("atribuye una entrega al líder por ObjectId", function()
            local events = {
                { EventType = "ObjectDelivered", Data = { playerId = 1, objectId = "box_small" } },
            }
            local deltas = StatRules.computeStatDeltas(events)
            expect(deltas[1].saved).to.equal(1)
            expect(deltas[1].byType["box_small"]).to.equal(1)
        end)

        it("agrega múltiples entregas del mismo jugador y tipo", function()
            local events = {
                { EventType = "ObjectDelivered", Data = { playerId = 1, objectId = "box_small" } },
                { EventType = "ObjectDelivered", Data = { playerId = 1, objectId = "box_small" } },
                { EventType = "ObjectDelivered", Data = { playerId = 1, objectId = "sofa_medium" } },
            }
            local deltas = StatRules.computeStatDeltas(events)
            expect(deltas[1].saved).to.equal(3)
            expect(deltas[1].byType["box_small"]).to.equal(2)
            expect(deltas[1].byType["sofa_medium"]).to.equal(1)
        end)

        it("separa entregas por jugador", function()
            local events = {
                { EventType = "ObjectDelivered", Data = { playerId = 1, objectId = "box_small" } },
                { EventType = "ObjectDelivered", Data = { playerId = 2, objectId = "box_small" } },
            }
            local deltas = StatRules.computeStatDeltas(events)
            expect(deltas[1].saved).to.equal(1)
            expect(deltas[2].saved).to.equal(1)
        end)

        it("ignora eventos que no son ObjectDelivered", function()
            local events = {
                { EventType = "ObjectDropped", Data = { playerId = 1 } },
                { EventType = "CarryStarted", Data = { playerId = 1 } },
            }
            local deltas = StatRules.computeStatDeltas(events)
            expect(next(deltas)).never.to.be.ok()
        end)

        it("ignora ObjectDelivered sin playerId (no atribuible)", function()
            local events = {
                { EventType = "ObjectDelivered", Data = { objectId = "box_small" } },
            }
            local deltas = StatRules.computeStatDeltas(events)
            expect(next(deltas)).never.to.be.ok()
        end)
    end)
end
