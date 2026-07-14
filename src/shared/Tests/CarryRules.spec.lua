-- CarryRules.spec.lua — núcleo puro de decisión de transporte (functional core).
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(CarryRules)
    if not CarryRules then
        describe("CarryRules", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    local STATES = { FREE = "free", BEING_CARRIED = "being_carried" }

    local function facts(overrides)
        local f = {
            exists = true,
            state = "free",
            leaderId = nil,
            isLarge = false,
            alreadyCarrying = false,
            inRange = true,
            playerId = 1,
        }
        for k, v in pairs(overrides) do
            f[k] = v
        end
        return f
    end

    describe("decideInteraction — pickup", function()
        it("objeto free, en rango, jugador libre, no large → pickup", function()
            expect(CarryRules.decideInteraction(facts({}), STATES)).to.equal("pickup")
        end)
    end)

    describe("decideInteraction — ignore", function()
        it("objeto inexistente → ignore", function()
            expect(CarryRules.decideInteraction(facts({ exists = false }), STATES)).to.equal("ignore")
        end)
        it("fuera de rango → ignore", function()
            expect(CarryRules.decideInteraction(facts({ inRange = false }), STATES)).to.equal("ignore")
        end)
        it("jugador ya carga otro → ignore", function()
            expect(CarryRules.decideInteraction(facts({ alreadyCarrying = true }), STATES)).to.equal("ignore")
        end)
        it("objeto large → ignore (GAM-006 pendiente)", function()
            expect(CarryRules.decideInteraction(facts({ isLarge = true }), STATES)).to.equal("ignore")
        end)
        it("delivered → ignore", function()
            expect(CarryRules.decideInteraction(facts({ state = "delivered" }), STATES)).to.equal("ignore")
        end)
    end)

    describe("decideInteraction — drop", function()
        it("being_carried por el mismo jugador (líder) → drop", function()
            local f = facts({ state = "being_carried", leaderId = 1, playerId = 1 })
            expect(CarryRules.decideInteraction(f, STATES)).to.equal("drop")
        end)
        it("being_carried por OTRO jugador → ignore (solo el líder suelta)", function()
            local f = facts({ state = "being_carried", leaderId = 2, playerId = 1 })
            expect(CarryRules.decideInteraction(f, STATES)).to.equal("ignore")
        end)
    end)

    describe("carrySpeed", function()
        it("aplica multiplicador válido en (0,1)", function()
            expect(CarryRules.carrySpeed(16, 0.5)).to.equal(8)
        end)
        it("multiplicador inválido (≥1) → velocidad intacta", function()
            expect(CarryRules.carrySpeed(16, 1)).to.equal(16)
        end)
        it("multiplicador nil → velocidad intacta", function()
            expect(CarryRules.carrySpeed(16, nil)).to.equal(16)
        end)
    end)
end
