-- GameplayConfig.lua
-- Configuración de mecánicas de gameplay.
-- CarryManager, NPCManager y ObjectManager leen estos valores.
-- Nunca hardcodear en módulos — todo ajuste post-playtest ocurre aquí.
--
-- REGLA: todos los parámetros de balance van aquí o en ObjectDefinition.Properties.
-- Si el valor es específico de un tipo de objeto → ObjectDefinition.Properties.
-- Si el valor es global al sistema → aquí.

return {
    -- ─── NPC ──────────────────────────────────────────────────────────────────

    -- Velocidad de movimiento del NPC entre nodos (studs/segundo).
    NPC_SPEED = 8,

    -- ─── Spawn de objetos ──────────────────────────────────────────────────────

    -- Cantidad de objetos spawneados por Size al inicio de cada ronda.
    -- Ajustar post-playtest en GAM-008 / WLD-007.
    OBJECT_COUNTS = {
        small = 8,
        medium = 5,
        large = 2,
    },

    -- Distancia mínima entre dos objetos spawneados (studs).
    -- Previene que dos objetos aparezcan en la misma posición.
    MIN_SPAWN_DISTANCE = 4,

    -- Dimensiones {x, y, z} en studs del Part placeholder por Size.
    -- Apariencia temporal — se reemplaza cuando existan modelos reales.
    -- Tablas planas (no Vector3) para mantener el módulo Lune-compatible (§4.6).
    PLACEHOLDER_OBJECT_SIZES = {
        small = { 2, 2, 2 },
        medium = { 3, 2.5, 2.5 },
        large = { 6, 3, 2.5 },
    },

    -- Color {r, g, b} (0–255) del Part placeholder por Size — legibilidad
    -- en playtest. Tablas planas (no Color3) por la misma razón de arriba.
    PLACEHOLDER_OBJECT_COLORS = {
        small = { 235, 200, 120 },
        medium = { 230, 140, 60 },
        large = { 200, 70, 60 },
    },

    -- ─── Carry ────────────────────────────────────────────────────────────────

    -- CONTRATO (DL-027): CarryManager guarda el WalkSpeed vigente del jugador
    -- al iniciar el carry y restaura ESE valor al soltar/entregar — nunca
    -- sobrescribe con una constante, para no pisar otros modificadores de
    -- velocidad activos. BASE_WALK_SPEED es solo el fallback si el valor
    -- guardado no existe o no es válido (> 0).
    BASE_WALK_SPEED = 16,
}
