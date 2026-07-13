-- Definitions/Objects — Catálogo de ObjectDefinitions (GAM-001).
-- Las definiciones viven como ModuleScripts hijos de este módulo — una por
-- tipo de objeto. La lógica de sistemas opera sobre ObjectId y Properties,
-- nunca sobre nombres de instancias (§2.4).
--
-- Lune-compatible: `script` solo se accede dentro de funciones (§4.6).

export type ObjectDefinition = {
    ObjectId: string,
    Size: string, -- "small" | "medium" | "large"
    Properties: { [string]: any },
}

local Catalog = {}

local byId: { [string]: ObjectDefinition }? = nil
local bySize: { [string]: { ObjectDefinition } }? = nil

local function load()
    if byId then
        return
    end
    byId = {}
    bySize = { small = {}, medium = {}, large = {} }

    for _, child in ipairs(script:GetChildren()) do
        if not child:IsA("ModuleScript") then
            continue
        end
        local def = require(child)
        local valid = type(def) == "table"
            and type(def.ObjectId) == "string"
            and type(def.Properties) == "table"
            and bySize[def.Size] ~= nil
        if not valid then
            error(("Definición inválida en Definitions/Objects: %s"):format(child:GetFullName()))
        end
        if byId[def.ObjectId] then
            error(("ObjectId duplicado en el catálogo: %s"):format(def.ObjectId))
        end
        byId[def.ObjectId] = def
        table.insert(bySize[def.Size], def)
    end
end

--- Retorna la definición para un ObjectId, o nil si no existe.
function Catalog.get(objectId: string): ObjectDefinition?
    load()
    return (byId :: { [string]: ObjectDefinition })[objectId]
end

--- Retorna las definiciones de un Size dado (tabla vacía si no hay).
function Catalog.getBySize(size: string): { ObjectDefinition }
    load()
    return (bySize :: { [string]: { ObjectDefinition } })[size] or {}
end

--- Retorna el mapa completo ObjectId → ObjectDefinition.
function Catalog.getAll(): { [string]: ObjectDefinition }
    load()
    return byId :: { [string]: ObjectDefinition }
end

return Catalog
