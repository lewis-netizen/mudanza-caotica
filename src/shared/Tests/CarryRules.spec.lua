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
        it("large SIN soporte → ignore (el carry no comienza sin soporte, GAM-006)", function()
            expect(CarryRules.decideInteraction(facts({ isLarge = true, supportAvailable = false }), STATES)).to.equal(
                "ignore"
            )
        end)
        it("delivered → ignore", function()
            expect(CarryRules.decideInteraction(facts({ state = "delivered" }), STATES)).to.equal("ignore")
        end)
    end)

    describe("decideInteraction — large con soporte (GAM-006)", function()
        it("large CON soporte en rango → pickup", function()
            expect(CarryRules.decideInteraction(facts({ isLarge = true, supportAvailable = true }), STATES)).to.equal(
                "pickup"
            )
        end)
        it("large con soporte pero fuera de rango del líder → ignore", function()
            local f = facts({ isLarge = true, supportAvailable = true, inRange = false })
            expect(CarryRules.decideInteraction(f, STATES)).to.equal("ignore")
        end)
    end)

    describe("chooseSupport (GAM-006)", function()
        it("elige el candidato más cercano dentro de rango", function()
            local candidates = { { id = 10, distSq = 50 }, { id = 20, distSq = 9 }, { id = 30, distSq = 30 } }
            expect(CarryRules.chooseSupport(candidates, 64)).to.equal(20)
        end)
        it("ninguno en rango → nil", function()
            local candidates = { { id = 10, distSq = 100 }, { id = 20, distSq = 81 } }
            expect(CarryRules.chooseSupport(candidates, 64)).to.equal(nil)
        end)
        it("sin candidatos → nil", function()
            expect(CarryRules.chooseSupport({}, 64)).to.equal(nil)
        end)
        it("en el borde exacto del rango → cuenta como dentro", function()
            expect(CarryRules.chooseSupport({ { id = 7, distSq = 64 } }, 64)).to.equal(7)
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

    describe("evaluateSupport (GAM-007)", function()
        local function supportFacts(overrides)
            local f = {
                currentSupportInRange = false,
                replacementId = nil,
                lostSince = nil,
                now = 100,
                timeout = 3,
            }
            for k, v in pairs(overrides) do
                f[k] = v
            end
            return f
        end

        it("soporte actual en rango → keep, tolerancia reseteada", function()
            local action, lostSince =
                CarryRules.evaluateSupport(supportFacts({ currentSupportInRange = true, lostSince = 99 }))
            expect(action).to.equal("keep")
            expect(lostSince).to.equal(nil)
        end)
        it("soporte fuera pero hay reemplazo en rango → reassign", function()
            local action, lostSince = CarryRules.evaluateSupport(supportFacts({ replacementId = 42 }))
            expect(action).to.equal("reassign")
            expect(lostSince).to.equal(nil)
        end)
        it("sin soporte por primera vez → grace, arranca la tolerancia", function()
            local action, lostSince = CarryRules.evaluateSupport(supportFacts({ now = 100 }))
            expect(action).to.equal("grace")
            expect(lostSince).to.equal(100)
        end)
        it("sin soporte dentro de la tolerancia → grace, lostSince persiste", function()
            local action, lostSince = CarryRules.evaluateSupport(supportFacts({ lostSince = 98, now = 100 }))
            expect(action).to.equal("grace")
            expect(lostSince).to.equal(98)
        end)
        it("sin soporte más allá del timeout → drop", function()
            local action = CarryRules.evaluateSupport(supportFacts({ lostSince = 96, now = 100, timeout = 3 }))
            expect(action).to.equal("drop")
        end)
        it("el soporte vuelve antes del timeout → keep (el carry continúa)", function()
            local action =
                CarryRules.evaluateSupport(supportFacts({ currentSupportInRange = true, lostSince = 98, now = 100 }))
            expect(action).to.equal("keep")
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
