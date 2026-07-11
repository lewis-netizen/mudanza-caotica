-- Config/Events.lua
-- Contrato canónico de StoryEvents y pool de EventDefinitions.
--
-- REGLA: todo EventType que aparezca en recordStoryEvent() debe estar
-- registrado aquí. El Orchestrator audita esta coherencia.
--
-- REGLA: los EventTypes son strings identificadores únicos.
-- Nunca usar nombres de objetos, partes de Studio, o strings arbitrarios.

-- ─── StoryEvent schema ─────────────────────────────────────────────────────────
--
-- StoryEvent = {
--   EventType : string   — debe ser una clave de STORY_EVENT_TYPES
--   Data      : table?   — campos permitidos: instanceId, objectId,
--                          playerId, duration. Nunca strings de nombre.
--   Timestamp : number   — os.clock() al momento del evento
-- }

-- ─── EventTypes canónicos ──────────────────────────────────────────────────────
-- Estos son los únicos EventTypes válidos para recordStoryEvent().
-- Añadir nuevos aquí antes de usarlos en cualquier módulo.

local STORY_EVENT_TYPES = {
	-- Gameplay core
	ObjectDelivered    = "ObjectDelivered",    -- data: { instanceId, objectId }
	ObjectDropped      = "ObjectDropped",      -- data: { instanceId, playerId }
	SupportLost        = "SupportLost",        -- data: { instanceId }
	SupportRestored    = "SupportRestored",    -- data: { instanceId }
	CarryStarted       = "CarryStarted",       -- data: { instanceId, playerId }

	-- Round events
	RoundEventStarted  = "RoundEventStarted",  -- data: { eventType }
}

-- ─── EventDefinition schema ────────────────────────────────────────────────────
--
-- EventDefinition = {
--   EventType : string          — identificador único, debe ser una clave de STORY_EVENT_TYPES
--   start     : () -> () -> ()  — función de inicio, retorna función de cleanup
-- }
--
-- La función de cleanup es llamada por EventManager.reset().
-- El cleanup debe devolver el mundo exactamente al estado anterior.
-- Si el evento no modifica nada persistente, cleanup puede ser nil.

-- ─── Pool de eventos ───────────────────────────────────────────────────────────
-- EventManager selecciona aleatoriamente de este pool al inicio de cada ronda.
-- Cada evento pasa el Test Oficial de Diseño (§2.2) antes de entrar al pool.

local Pool = {
	-- ── Evento 1: El vecino bloquea el pasillo central ─────────────────────────
	-- Entropía Espacial — modifica la geometría efectiva del edificio.
	-- El NPC se posiciona estáticamente en una NPCDropZone del pasillo central.
	-- Los jugadores deben coordinar rutas alternativas.
	{
		EventType = STORY_EVENT_TYPES.RoundEventStarted,

		start = function()
			-- Servicios accedidos dentro de la función — no en scope de módulo
			-- (inyección de dependencias — compatibilidad con Lune §4.6)
			local CollectionService = game:GetService("CollectionService")
			local TweenService = game:GetService("TweenService")

			local dropZones = CollectionService:GetTagged("NPCDropZone")
			local corridorZone = nil
			for _, zone in ipairs(dropZones) do
				if zone:GetAttribute("EventTag") == "NeighborBlocksCorridor" then
					corridorZone = zone
					break
				end
			end

			-- El NPC se identifica por Tag, nunca por nombre literal
			local npcParts = CollectionService:GetTagged("NPCModel")
			local npcPrimaryPart = if #npcParts > 0 then npcParts[1] else nil
			local npcModel = if npcPrimaryPart then npcPrimaryPart.Parent else nil
			local originalCFrame: CFrame? = nil

			if npcModel and corridorZone then
				originalCFrame = (npcModel :: Model):GetPivot()
				local tween = TweenService:Create(
					(npcModel :: Model).PrimaryPart,
					TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = corridorZone.CFrame }
				)
				tween:Play()
			end

			return function()
				if npcModel and originalCFrame then
					(npcModel :: Model):PivotTo(originalCFrame)
				end
			end
		end,
	},

	-- ── Placeholder: añadir más eventos en Semana 3 ───────────────────────────
	-- Cada evento nuevo debe:
	--   1. Pasar los 5 criterios del Test Oficial de Diseño (§2.2)
	--   2. No violar la Lista Prohibida (§3.5)
	--   3. Registrar su EventType en STORY_EVENT_TYPES si genera StoryEvent
	--   4. Implementar cleanup completo en EventManager.reset()
}

-- ─── Exports ───────────────────────────────────────────────────────────────────

return {
	STORY_EVENT_TYPES = STORY_EVENT_TYPES,
	Pool = Pool,
}
