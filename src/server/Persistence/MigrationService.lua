-- MigrationService
-- Versionado y migración de PlayerData (§4.7, PER-002). Detecta la versión
-- del dato cargado por ProfileStore y aplica migraciones secuenciales hasta
-- la versión canónica actual. Dato sin campo Version = versión 0.
--
-- Este módulo es el DUEÑO del template canónico de PlayerData (§2.5) —
-- ProfileStoreConfig y PlayerDataService lo consumen via getTemplate().
--
-- Módulo puro: sin acceso a game/servicios — testeable en Lune (§4.6).
-- migrate() NUNCA propaga excepción: ante fallo retorna un dato fresco
-- con Version canónica (PER-002).

local MigrationService = {}

local CURRENT_VERSION = 1

-- ─── Template canónico (§2.5) ──────────────────────────────────────────────────
-- Los dominios reservados (Identity, Creation) existen desde el día uno como
-- tablas — nunca nil. Su contenido no puede usarse sin especificación del PO.

local function newTemplate(): any
    return {
        Version = CURRENT_VERSION,
        Profile = {
            FirstJoinDate = 0,
            LastJoinDate = 0,
        },
        Stats = {
            TimePlayed = 0,
            MatchesStarted = 0,
            MatchesCompleted = 0,
            ObjectsSaved = 0,
            ObjectsSavedByType = {}, -- indexado por ObjectId, nunca por nombre (§2.4)
        },
        Identity = {
            Titles = {},
            Cosmetics = {},
            Auras = {},
        },
        Creation = {},
        Settings = {
            MusicVolume = 1,
            SFXVolume = 1,
        },
    }
end

--- Retorna un template canónico FRESCO (tabla nueva en cada llamada).
function MigrationService.getTemplate(): any
    return newTemplate()
end

--- Versión canónica actual del schema.
function MigrationService.getCurrentVersion(): number
    return CURRENT_VERSION
end

-- ─── Pipeline de migraciones ───────────────────────────────────────────────────
-- MIGRATIONS[n] transforma un dato de versión n a versión n+1.
-- Añadir una migración nueva = registrar una función aquí + subir
-- CURRENT_VERSION. La lógica central no se modifica (PER-002).

local function mergeDomain(target: any, source: any)
    if type(source) ~= "table" then
        return
    end
    for key, value in pairs(source) do
        target[key] = value
    end
end

local MIGRATIONS: { [number]: (any) -> any } = {
    -- v0 → v1: dato pre-versionado. Se preservan los campos existentes por
    -- dominio sobre un template fresco — nunca se pierden Stats.
    [0] = function(data)
        local fresh = newTemplate()
        mergeDomain(fresh.Profile, data.Profile)
        mergeDomain(fresh.Stats, data.Stats)
        mergeDomain(fresh.Identity, data.Identity)
        mergeDomain(fresh.Creation, data.Creation)
        mergeDomain(fresh.Settings, data.Settings)
        fresh.Version = 1
        return fresh
    end,
}

-- ─── Migración ─────────────────────────────────────────────────────────────────

local function migrateInternal(raw: any): any
    if type(raw) ~= "table" then
        return newTemplate()
    end

    local version = if type(raw.Version) == "number" then raw.Version else 0

    -- Dato de una versión futura (código viejo, dato nuevo): no se toca —
    -- degradarlo destruiría información. ProfileStore lo guarda tal cual.
    if version > CURRENT_VERSION then
        return raw
    end

    local data = raw
    while version < CURRENT_VERSION do
        local step = MIGRATIONS[version]
        if not step then
            -- Hueco en el pipeline — dato irrecuperable de forma segura
            return newTemplate()
        end
        data = step(data)
        version += 1 -- secuencial, nunca saltos (PER-002)
    end

    return data
end

--- Migra un PlayerData crudo a la versión canónica. Nunca lanza excepción:
--- ante cualquier fallo retorna un template fresco con Version actual.
function MigrationService.migrate(raw: any): any
    local ok, result = pcall(migrateInternal, raw)
    if ok and type(result) == "table" then
        return result
    end
    return newTemplate()
end

return MigrationService
