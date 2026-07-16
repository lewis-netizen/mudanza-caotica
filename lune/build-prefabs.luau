-- build-prefabs.luau
-- Genera assets/ObjectPrefabs.rbxmx — los prefabs de objeto como CÓDIGO
-- (FND-003/WLD-008, DL-040). Coste-IA (§5.9): versionable, reproducible,
-- sin pasos manuales de Studio. Regenerar tras cambiar un modelo:
--
--   lune run lune/build-prefabs.luau
--
-- Contrato Arte → PrefabRegistry (§4.4):
--   · Un prefab por ObjectId del catálogo, Attribute "ObjectId" en el hijo.
--   · Model con PrimaryPart (raíz física); demás BaseParts soldadas a ella,
--     SIN anclar. La raíz es el volumen de colisión; los detalles decorativos
--     van CanCollide=false para que la física del carry sea idéntica a la de
--     un Part suelto (CarryManager solo muta la raíz).
--
-- El archivo generado lo mapea Rojo a ServerStorage/ObjectPrefabs
-- (default.project.json). El script hace un round-trip de verificación antes
-- de escribir: deserializa lo serializado y valida el contrato.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Instance = roblox.Instance

local OUTPUT = "assets/ObjectPrefabs.rbxmx"

-- ─── Helpers ───────────────────────────────────────────────────────────────────

type PartProps = {
	name: string,
	size: { number },
	offset: { number }?, -- offset relativo a la raíz (studs)
	color: { number },
	material: roblox.Enum?,
}

local function makePart(props: PartProps): roblox.Instance
	local part = Instance.new("Part")
	part.Name = props.name
	part.Size = roblox.Vector3.new(props.size[1], props.size[2], props.size[3])
	part.Color = roblox.Color3.fromRGB(props.color[1], props.color[2], props.color[3])
	if props.material then
		part.Material = props.material
	end
	part.TopSurface = roblox.Enum.SurfaceType.Smooth
	part.BottomSurface = roblox.Enum.SurfaceType.Smooth
	return part
end

--- Construye un Model: la raíz (colisión, anclada) + detalles decorativos
--- (CanCollide=false, Massless, soldados a la raíz, sin anclar — §4.4).
local function buildPrefab(objectId: string, root: PartProps, details: { PartProps }): roblox.Instance
	local model = Instance.new("Model")
	model.Name = objectId -- cosmético; la identificación es por Attribute (§2.4)
	model:SetAttribute("ObjectId", objectId)

	local rootPart = makePart(root)
	rootPart.Anchored = true
	rootPart.CanCollide = true
	rootPart.CFrame = roblox.CFrame.new(0, 0, 0)
	rootPart.Parent = model
	model.PrimaryPart = rootPart

	for _, props in details do
		local part = makePart(props)
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		local offset = props.offset or { 0, 0, 0 }
		part.CFrame = rootPart.CFrame * roblox.CFrame.new(offset[1], offset[2], offset[3])
		part.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rootPart
		weld.Part1 = part
		weld.Parent = part
	end

	return model
end

-- ─── Los tres prefabs del slice (catálogo GAM-001) ─────────────────────────────

local CARDBOARD = { 173, 130, 86 }
local TAPE = { 133, 97, 60 }
local FABRIC = { 122, 51, 62 }
local FABRIC_DARK = { 100, 40, 50 }
local WOOD = { 105, 74, 48 }
local WOOD_LIGHT = { 133, 97, 64 }
local METAL = { 60, 60, 64 }

local function buildAll(): roblox.Instance
	local folder = Instance.new("Folder")
	folder.Name = "ObjectPrefabs"

	-- Caja de cartón: cuerpo + cinta de embalaje cruzada.
	buildPrefab("box_small", { name = "Body", size = { 2, 2, 2 }, color = CARDBOARD }, {
		{ name = "TapeAlong", size = { 2.04, 0.08, 0.5 }, offset = { 0, 1.02, 0 }, color = TAPE },
		{ name = "TapeAcross", size = { 0.5, 0.08, 2.04 }, offset = { 0, 1.02, 0 }, color = TAPE },
	}).Parent =
		folder

	-- Sofá: asiento (raíz = volumen de colisión) + respaldo, brazos y cojines.
	buildPrefab("sofa_medium", { name = "Seat", size = { 4.5, 1.2, 2 }, color = FABRIC }, {
		{ name = "Backrest", size = { 4.5, 1.6, 0.6 }, offset = { 0, 1.4, -0.7 }, color = FABRIC },
		{ name = "ArmLeft", size = { 0.6, 0.9, 2 }, offset = { -1.95, 1.05, 0 }, color = FABRIC },
		{ name = "ArmRight", size = { 0.6, 0.9, 2 }, offset = { 1.95, 1.05, 0 }, color = FABRIC },
		{ name = "CushionLeft", size = { 1.55, 0.35, 1.7 }, offset = { -0.83, 0.78, 0.1 }, color = FABRIC_DARK },
		{ name = "CushionRight", size = { 1.55, 0.35, 1.7 }, offset = { 0.83, 0.78, 0.1 }, color = FABRIC_DARK },
	}).Parent =
		folder

	-- Ropero: cuerpo (raíz) + puertas, tiradores y cornisa.
	buildPrefab("wardrobe_large", { name = "Body", size = { 2.6, 5.4, 1.6 }, color = WOOD }, {
		{ name = "DoorLeft", size = { 1.16, 4.9, 0.12 }, offset = { -0.63, -0.1, 0.84 }, color = WOOD_LIGHT },
		{ name = "DoorRight", size = { 1.16, 4.9, 0.12 }, offset = { 0.63, -0.1, 0.84 }, color = WOOD_LIGHT },
		{ name = "HandleLeft", size = { 0.12, 0.6, 0.12 }, offset = { -0.14, 0, 0.95 }, color = METAL },
		{ name = "HandleRight", size = { 0.12, 0.6, 0.12 }, offset = { 0.14, 0, 0.95 }, color = METAL },
		{ name = "Cornice", size = { 2.8, 0.25, 1.8 }, offset = { 0, 2.82, 0 }, color = WOOD_LIGHT },
	}).Parent =
		folder

	return folder
end

-- ─── Verificación round-trip (el contrato se valida ANTES de escribir) ─────────

local EXPECTED_IDS = { "box_small", "sofa_medium", "wardrobe_large" }

local function verify(xml: string)
	local roots = roblox.deserializeModel(xml)
	assert(#roots == 1, "el rbxmx debe tener UNA raíz (Folder) — Rojo mapea archivos de modelo de raíz única")
	local folder = roots[1]

	local found: { [string]: boolean } = {}
	for _, child in folder:GetChildren() do
		local id = child:GetAttribute("ObjectId")
		assert(type(id) == "string" and id ~= "", `prefab {child.Name} sin Attribute ObjectId`)
		assert(found[id] == nil, `ObjectId duplicado: {id}`)
		assert(child:IsA("Model"), `prefab {id} no es Model`)
		assert((child :: any).PrimaryPart ~= nil, `prefab {id} sin PrimaryPart`)
		local primary = (child :: any).PrimaryPart
		assert(primary.Anchored == true, `raíz de {id} debe estar anclada`)
		for _, part in child:GetDescendants() do
			if part:IsA("BasePart") and part ~= primary then
				assert(part.Anchored == false, `{id}/{part.Name}: los detalles van SIN anclar`)
				assert(part.CanCollide == false, `{id}/{part.Name}: los detalles van CanCollide=false`)
				local welded = false
				for _, d in part:GetChildren() do
					if d:IsA("WeldConstraint") then
						welded = true
					end
				end
				assert(welded, `{id}/{part.Name}: detalle sin WeldConstraint a la raíz`)
			end
		end
		found[id] = true
	end
	for _, id in EXPECTED_IDS do
		assert(found[id], `falta el prefab del catálogo: {id}`)
	end
end

-- ─── Main ──────────────────────────────────────────────────────────────────────

local folder = buildAll()
local xml = roblox.serializeModel({ folder }, true)
verify(xml)
fs.writeFile(OUTPUT, xml)
print(`✅ {OUTPUT} generado y verificado — {#EXPECTED_IDS} prefabs (round-trip OK)`)
