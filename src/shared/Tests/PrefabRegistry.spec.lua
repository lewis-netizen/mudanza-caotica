-- PrefabRegistry.spec.lua
-- Tests del núcleo puro de auditoría del contrato ObjectId → Prefab (DL-031).
-- _audit no toca DataModel — corre completo en Lune.
--
-- Compatibilidad con Lune: el módulo se recibe como parámetro.

return function(PrefabRegistry)
    if not PrefabRegistry then
        describe("PrefabRegistry", function()
            it("SKIP — módulo no implementado todavía", function() end)
        end)
        return
    end

    local CATALOG = { "box_small", "sofa_medium", "wardrobe_large" }

    describe("_audit — contrato completo", function()
        it("catálogo cubierto y sin extras → ok sin issues", function()
            local ok, issues = PrefabRegistry._audit(CATALOG, {
                { objectId = "box_small", physicsRootOk = true },
                { objectId = "sofa_medium", physicsRootOk = true },
                { objectId = "wardrobe_large", physicsRootOk = true },
            })
            expect(ok).to.equal(true)
            expect(#issues.missing).to.equal(0)
            expect(#issues.duplicated).to.equal(0)
            expect(#issues.orphaned).to.equal(0)
            expect(#issues.invalid).to.equal(0)
        end)

        it("sin prefabs → todos los ObjectIds en missing, pero ok (fallback)", function()
            local ok, issues = PrefabRegistry._audit(CATALOG, {})
            expect(ok).to.equal(true)
            expect(#issues.missing).to.equal(3)
        end)
    end)

    describe("_audit — violaciones de contrato", function()
        it("ObjectId duplicado → not ok", function()
            local ok, issues = PrefabRegistry._audit(CATALOG, {
                { objectId = "box_small", physicsRootOk = true },
                { objectId = "box_small", physicsRootOk = true },
            })
            expect(ok).to.equal(false)
            expect(#issues.duplicated).to.equal(1)
            expect(issues.duplicated[1]).to.equal("box_small")
        end)

        it("prefab sin Attribute ObjectId → invalid y not ok", function()
            local ok, issues = PrefabRegistry._audit(CATALOG, {
                { objectId = nil, physicsRootOk = true },
            })
            expect(ok).to.equal(false)
            expect(#issues.invalid).to.equal(1)
        end)

        it("Model sin PrimaryPart → invalid y not ok", function()
            local ok, issues = PrefabRegistry._audit(CATALOG, {
                { objectId = "box_small", physicsRootOk = false },
            })
            expect(ok).to.equal(false)
            expect(#issues.invalid).to.equal(1)
        end)
    end)

    describe("_audit — huérfanos", function()
        it("prefab sin ObjectDefinition → orphaned pero ok (inofensivo)", function()
            local ok, issues = PrefabRegistry._audit(CATALOG, {
                { objectId = "piano_gigante", physicsRootOk = true },
            })
            expect(ok).to.equal(true)
            expect(#issues.orphaned).to.equal(1)
            expect(issues.orphaned[1]).to.equal("piano_gigante")
        end)
    end)
end
