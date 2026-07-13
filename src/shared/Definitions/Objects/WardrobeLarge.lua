-- ObjectDefinition — ropero grande (GAM-001).
return {
    ObjectId = "wardrobe_large",
    Size = "large",
    Properties = {
        -- Rango (studs) en el que el soporte debe mantenerse del líder. GAM-006.
        supportRange = 8,
        -- Segundos de tolerancia sin soporte antes de que el objeto caiga. GAM-007.
        supportTimeout = 3,
    },
}
