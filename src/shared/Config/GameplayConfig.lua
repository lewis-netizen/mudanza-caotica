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
		small  = 8,
		medium = 5,
		large  = 2,
	},

	-- Distancia mínima entre dos objetos spawneados (studs).
	-- Previene que dos objetos aparezcan en la misma posición.
	MIN_SPAWN_DISTANCE = 4,

	-- ─── Carry ────────────────────────────────────────────────────────────────

	-- WalkSpeed base del jugador (valor por defecto de Roblox).
	-- Usado por CarryManager para restaurar velocidad al soltar objetos.
	BASE_WALK_SPEED = 16,
}
