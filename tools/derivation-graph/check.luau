-- tools/derivation-graph/check.luau
-- Extrae el grafo de derivación de docs/ y evalúa el modelo (derivation.dl).
-- Falla (exit 1) en: dangling, orphan, stale nuevo (sin diferimiento),
-- diferimiento VENCIDO (liveness acotada, DL-050) y version-pins.
-- La deuda diferida vigente vive en deferrals.txt — visible, no bloqueante.
-- Correr desde la raíz del repo:  lune run tools/derivation-graph/check.luau

local fs = require("@lune/fs")
local process = require("@lune/process")
local datetime = require("@lune/datetime")

-- ── util ──────────────────────────────────────────────────────────────────
local function readLines(path)
	local content = fs.readFile(path)
	local lines = {}
	for line in (content .. "\n"):gmatch("(.-)\n") do
		table.insert(lines, line)
	end
	return lines
end

local function norm(sec)
	return "§" .. (sec:gsub("%.$", ""))
end

-- ── relaciones (EDB) ────────────────────────────────────────────────────────
local nodes = {}
local derives = {}
local affects = {}
local modifies = {}
local dlDomain = {}

local function eachRef(text, fn)
	for num in text:gmatch("§([%d%.]+)") do
		fn(norm(num))
	end
	for num in text:gmatch("DL%-(%d+)") do
		fn("DL-" .. num)
	end
end

local function eachTicketId(text, fn)
	for id in text:gmatch("(%u+%-%d+)") do
		if not id:match("^DL%-") then
			fn(id)
		end
	end
end

-- ── extracción ──────────────────────────────────────────────────────────────
for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
	local num = line:match("^#+%s+(%d[%d%.]*)")
	if num then
		nodes[norm(num)] = "section"
	end
end

do
	local cur = nil
	for _, line in ipairs(readLines("docs/PROJECT_DECISION_LOG.md")) do
		local dl = line:match("^### DL%-(%d+)")
		if dl then
			cur = "DL-" .. dl
			nodes[cur] = "dl"
		elseif cur then
			local refs = line:match("^Referencias:%s*(.+)")
			if refs then
				eachRef(refs, function(p)
					table.insert(derives, { cur, p })
				end)
			end
			local tks = line:match("^Ticket:%s*(.+)")
			if tks then
				eachTicketId(tks, function(t)
					table.insert(affects, { cur, t })
				end)
			end
			local mods = line:match("^Modifica:%s*(.+)")
			if mods then
				for num in mods:gmatch("§([%d%.]+)") do
					table.insert(modifies, { cur, norm(num) })
				end
			end
			local dom = line:match("^Domain:%s*(%S+)")
			if dom then
				dlDomain[cur] = dom
			end
		end
	end
end

do
	local cur = nil
	for _, line in ipairs(readLines("docs/TICKETS.md")) do
		local t = line:match("^### (%u+%-%d+)")
		if t and not t:match("^DL%-") then
			cur = t
			nodes[cur] = "ticket"
		elseif cur then
			local dv = line:match("^Deriva de:%s*(.+)")
			if dv then
				eachRef(dv, function(p)
					table.insert(derives, { cur, p })
				end)
			end
			-- DL-Ref también es una arista de derivación declarada por el artefacto
			local dlref = line:match("^DL%-Ref:%s*(.+)")
			if dlref then
				eachRef(dlref, function(p)
					table.insert(derives, { cur, p })
				end)
			end
		end
	end
end

-- ── diferimientos autorizados y acotados (DL-050) ───────────────────────────
local deferrals = {} -- "ticket\0dl" → fecha límite YYYY-MM-DD
do
	local ok, content = pcall(fs.readFile, "tools/derivation-graph/deferrals.txt")
	if ok then
		for line in (content .. "\n"):gmatch("(.-)\n") do
			local t, d, _auth, untilDate = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
			if t and untilDate and not t:match("^#") then
				deferrals[t .. "\0" .. d] = untilDate
			end
		end
	end
end

local today = datetime.now():toIsoDate():sub(1, 10)

-- ── evaluación (IDB) ────────────────────────────────────────────────────────
local derivesSet = {}
for _, e in ipairs(derives) do
	derivesSet[e[1] .. "\0" .. e[2]] = true
end
local function hasDerives(a, b)
	return derivesSet[a .. "\0" .. b] == true
end

local dangling = {}
for _, e in ipairs(derives) do
	if not nodes[e[2]] then
		table.insert(dangling, e)
	end
end
for _, m in ipairs(modifies) do
	if not nodes[m[2]] then
		table.insert(dangling, { m[1], m[2] })
	end
end

local hasSource = {}
for _, e in ipairs(derives) do
	hasSource[e[1]] = true
end
local orphan = {}
for id, kind in pairs(nodes) do
	if kind == "ticket" and not hasSource[id] then
		table.insert(orphan, id)
	end
end

-- stale con tres destinos: nuevo (regresión) | diferido vigente | vencido
local newStale, deferred, expired = {}, {}, {}
for _, a in ipairs(affects) do
	if not hasDerives(a[2], a[1]) then
		local untilDate = deferrals[a[2] .. "\0" .. a[1]]
		if untilDate == nil then
			table.insert(newStale, { a[2], a[1] })
		elseif today > untilDate then
			table.insert(expired, { a[2], a[1], untilDate })
		else
			table.insert(deferred, { a[2], a[1] })
		end
	end
end

-- uncovered: DL que modifica §3/§4 sin declarar Ticket: y sin derivadores
local coveredSet = {}
for _, e in ipairs(derives) do
	coveredSet[e[2]] = true
end
for _, a in ipairs(affects) do
	coveredSet[a[1]] = true
end
local uncovered, uncoveredSeen = {}, {}
for _, m in ipairs(modifies) do
	local isImpl = m[2]:match("^§3") ~= nil or m[2]:match("^§4") ~= nil
	if isImpl and not coveredSet[m[1]] and not uncoveredSeen[m[1]] then
		uncoveredSeen[m[1]] = true
		table.insert(uncovered, m[1])
	end
end

-- ── F5: altitud como tipo (DL-051) ──────────────────────────────────────────

-- level_skip: ticket cuyas fuentes son SOLO fundamento (§1/§2) o hito (§5+) —
-- la implementación exige ≥1 fuente de diseño (§3), técnica (§4) o DL.
-- QA-xxx exento: hitos transversales (TICKETS.md — "QA no es un dominio").
local ticketHasDT = {}
for _, e in ipairs(derives) do
	if nodes[e[1]] == "ticket" then
		local pk = nodes[e[2]]
		if pk == "dl" then
			ticketHasDT[e[1]] = true
		elseif pk == "section" then
			local m = tonumber(e[2]:match("^§(%d+)") or "")
			if m == 3 or m == 4 then
				ticketHasDT[e[1]] = true
			end
		end
	end
end
local levelSkip = {}
for id, kind in pairs(nodes) do
	if kind == "ticket" and hasSource[id] and not ticketHasDT[id] and not id:match("^QA%-") then
		table.insert(levelSkip, id)
	end
end
table.sort(levelSkip)

-- domain_mismatch: Domain del DL incoherente con el nivel de lo que Modifica.
local domainMismatch, dmSeen = {}, {}
for _, m in ipairs(modifies) do
	local major = tonumber(m[2]:match("^§(%d+)") or "")
	local d = dlDomain[m[1]] or "?"
	local bad = (major == 3 and d ~= "DESIGN" and d ~= "BOTH")
		or (major == 4 and d ~= "TECH" and d ~= "BOTH")
	local key = m[1] .. "\0" .. tostring(major)
	if bad and not dmSeen[key] then
		dmSeen[key] = true
		table.insert(domainMismatch, { m[1], m[2], d })
	end
end
table.sort(domainMismatch, function(a, b)
	return a[1] < b[1]
end)

-- impl_leak: nombres de módulos de src/ en §1–§3 del master (implementación
-- filtrada al piso de diseño). "Main" exento (entry point, palabra común).
local moduleNames = {}
local function collectModules(dir)
	local ok, entries = pcall(fs.readDir, dir)
	if not ok then
		return
	end
	for _, name in ipairs(entries) do
		local p = dir .. "/" .. name
		if fs.isDir(p) then
			collectModules(p)
		else
			local base = name:match("^(.+)%.luau?$")
			if base then
				base = base:gsub("%.server$", ""):gsub("%.client$", ""):gsub("%.spec$", "")
				moduleNames[base] = true
			end
		end
	end
end
collectModules("src")
moduleNames["Main"] = nil
local implLeak = {}
do
	local inRange = false
	local i = 0
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		i += 1
		if line:match("^## 1%.") then
			inRange = true
		elseif line:match("^## 4%.") then
			inRange = false
		end
		if inRange then
			for name in pairs(moduleNames) do
				if line:match("%f[%w]" .. name .. "%f[%W]") then
					table.insert(implLeak, "AI_CONTEXT_MASTER.md:" .. i .. " → " .. name)
				end
			end
		end
	end
end
table.sort(implLeak)

-- version-pins: ningún artefacto referencia "AI_CONTEXT_MASTER vN.N" (DL-050).
-- El master se lee siempre vigente. Entradas históricas del log exentas
-- (solo se escanea su header). El master mismo está exento.
local pins = {}
local function scanPins(path, headerOnly)
	local i = 0
	for _, line in ipairs(readLines(path)) do
		i += 1
		if headerOnly and i > 10 then
			break
		end
		if line:match("AI_CONTEXT_MASTER v%d") then
			table.insert(pins, path .. ":" .. i)
		end
	end
end
local function walkDocs(dir)
	for _, name in ipairs(fs.readDir(dir)) do
		local p = dir .. "/" .. name
		if fs.isDir(p) then
			walkDocs(p)
		elseif name:match("%.md$") then
			if name == "AI_CONTEXT_MASTER.md" then
				-- exento: es el master
			elseif name == "PROJECT_DECISION_LOG.md" then
				scanPins(p, true)
			else
				scanPins(p, false)
			end
		end
	end
end
walkDocs("docs")

-- ── reporte ─────────────────────────────────────────────────────────────────
local nodeCount = 0
for _ in pairs(nodes) do
	nodeCount += 1
end
print(
	string.format(
		"Grafo: %d nodos, %d 'derives', %d 'affects', %d 'modifies'\n",
		nodeCount,
		#derives,
		#affects,
		#modifies
	)
)

local function reportViolations(name, rows, fmt)
	if #rows == 0 then
		print(string.format("  ✓ %s: 0", name))
	else
		print(string.format("  ✗ %s: %d", name, #rows))
		for _, r in ipairs(rows) do
			print("      " .. fmt(r))
		end
	end
end

reportViolations("dangling", dangling, function(r)
	return r[1] .. " → " .. r[2] .. " (nodo inexistente)"
end)
reportViolations("orphan", orphan, function(r)
	return r
end)
reportViolations("stale NUEVO (regresión)", newStale, function(r)
	return r[1] .. " no referencia " .. r[2]
end)
reportViolations("diferimiento VENCIDO (liveness expirada)", expired, function(r)
	return r[1] .. " ↛ " .. r[2] .. " (venció " .. r[3] .. ")"
end)
reportViolations("uncovered (DL modifica §3/§4 sin derivación declarada)", uncovered, function(r)
	return r
end)
reportViolations("level_skip (implementación sin fuente §3/§4/DL)", levelSkip, function(r)
	return r
end)
reportViolations("domain_mismatch (Domain del DL vs nivel que Modifica)", domainMismatch, function(r)
	return r[1] .. " (Domain " .. r[3] .. ") modifica " .. r[2]
end)
reportViolations("impl_leak (módulo de src/ nombrado en §1–§3)", implLeak, function(r)
	return r
end)
reportViolations("version-pin (referencia a versión del master — prohibido)", pins, function(r)
	return r
end)

if #deferred > 0 then
	print(string.format("\n  · deuda diferida vigente: %d — autorizada y acotada en deferrals.txt", #deferred))
	table.sort(deferred, function(a, b)
		return a[1] .. a[2] < b[1] .. b[2]
	end)
	for _, d in ipairs(deferred) do
		print("      " .. d[1] .. " ↛ " .. d[2])
	end
end

local violations = #dangling + #orphan + #newStale + #expired + #uncovered + #pins
	+ #levelSkip + #domainMismatch + #implLeak
if violations > 0 then
	print(string.format("\n%d violación(es) — el grafo de derivación NO está íntegro.", violations))
	process.exit(1)
else
	print("\nSin violaciones. Grafo consistente al nivel actual.")
end
