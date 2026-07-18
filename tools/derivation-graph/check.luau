-- tools/derivation-graph/check.luau
-- Extrae el grafo de derivación de docs/ y evalúa el modelo (derivation.dl).
-- Falla (exit 1) solo en REGRESIONES: dangling, orphan, o stale nuevo (no en
-- baseline.txt). La deuda conocida/diferida vive en baseline.txt — visible,
-- no bloqueante (respeta el nivel de abstracción del trabajo actual).
-- Correr desde la raíz del repo:  lune run tools/derivation-graph/check.luau

local fs = require("@lune/fs")
local process = require("@lune/process")

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
		end
	end
end

-- ── baseline (deuda conocida/diferida) ──────────────────────────────────────
local baseline = {}
do
	local ok, content = pcall(fs.readFile, "tools/derivation-graph/baseline.txt")
	if ok then
		for line in (content .. "\n"):gmatch("(.-)\n") do
			local t, d = line:match("^(%S+)%s+(%S+)")
			if t and d and not t:match("^#") then
				baseline[t .. "\0" .. d] = true
			end
		end
	end
end

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

local newStale, knownStale = {}, {}
for _, a in ipairs(affects) do
	if not hasDerives(a[2], a[1]) then
		local key = a[2] .. "\0" .. a[1]
		if baseline[key] then
			table.insert(knownStale, { a[2], a[1] })
		else
			table.insert(newStale, { a[2], a[1] })
		end
	end
end

-- ── reporte ─────────────────────────────────────────────────────────────────
local nodeCount = 0
for _ in pairs(nodes) do
	nodeCount += 1
end
print(
	string.format(
		"Grafo: %d nodos, %d aristas 'derives', %d aristas 'affects'\n",
		nodeCount,
		#derives,
		#affects
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

if #knownStale > 0 then
	print(string.format("\n  · deuda conocida (baseline): %d — backlog de trazabilidad, no bloquea", #knownStale))
end

local violations = #dangling + #orphan + #newStale
if violations > 0 then
	print(string.format("\n%d violación(es) NUEVA(s) — el grafo de derivación regresó.", violations))
	process.exit(1)
else
	print("\nSin regresiones. Grafo consistente al nivel actual.")
end
