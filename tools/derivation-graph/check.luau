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

-- Sello del enunciado (Z4, DL-063). FNV-1a de 32 bits sobre el texto
-- normalizado; 6 hex. Lo que sella es el ENUNCIADO, no la fila: mover un
-- claim no altera su sello, reescribirlo sí. Así el grafo distingue
-- REUBICAR normatividad de CAMBIAR el compromiso — sin esa distinción, una
-- remodelación de diseño es indistinguible de un refactor cosmético.
-- La multiplicación va partida en dos mitades: 32 bits × 16777619 desborda
-- la precisión exacta de un double antes del módulo.
local function mul32(a, b)
	local hi = math.floor(a / 65536)
	local lo = a % 65536
	return ((hi * b % 65536) * 65536 + lo * b) % 4294967296
end

local function sealOf(text)
	local s = text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	local h = 2166136261
	for i = 1, #s do
		h = mul32(bit32.bxor(h, string.byte(s, i)), 16777619)
	end
	return string.format("%08x", h):sub(1, 6)
end

-- ── relaciones (EDB) ────────────────────────────────────────────────────────
local nodes = {}
local derives = {}
local affects = {}
local modifies = {}
local dlDomain = {}
local declaresFree = {}

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
			if line:match("^Libre:%s*%S") then
				declaresFree[cur] = true
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
	-- Exenciones de obligación de ticket (DL-062):
	--  · §4.15 — registro de gluing, gobernado por unglued_claim/glue_dangling.
	--  · §3.1–§3.9 — comentario NO NORMATIVO desde DL-061: prosa que no obliga
	--    no puede generar obligación de implementación (exención DERIVADA).
	--  · §3.0 — normativa. Desde DL-063 el sello hace VISIBLE que un claim
	--    cambió, pero el grafo no guarda historia: no sabe qué sello había
	--    antes, luego no puede derivar obligación del cambio. Exención
	--    ACOTADA por la zona Z4 re-acotada (§2.8) — no es un fallback.
	local sec = m[2]
	local exempt = sec == "§4.15" or sec:match("^§3") ~= nil
	local isImpl = (sec:match("^§3") ~= nil or sec:match("^§4") ~= nil) and not exempt
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

-- undeclared_free (F7): un DL que modifica el master sin declarar `Libre:`.
-- Fuerza el juicio de determinación como acto explícito ("—" es respuesta
-- legítima); no valida su corrección — valida que se haya hecho.
local undeclaredFree, ufSeen = {}, {}
for _, m in ipairs(modifies) do
	if not declaresFree[m[1]] and not ufSeen[m[1]] then
		ufSeen[m[1]] = true
		table.insert(undeclaredFree, m[1])
	end
end
table.sort(undeclaredFree)

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

-- ── F6: código como nodos + gluing §3↔§4 (DL-054) ───────────────────────────
-- Registro declarado (tabla §4.4, tabla §4.13, registro adicional §4.15)
-- contra src/ real, y tabla de gluing §4.15: totalidad + existencia.
local declaredModules = {}
local gluedClaims = {} -- filas de gluing: claims D-n con ≥1 realización (DL-062)
local glueTargets = {} -- claims de módulo en filas de gluing
do
	local region = nil
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region = (h:gsub("%.$", ""))
		end
		if region == "4.4" then
			local name = line:match("^| (%u%w+) |")
			if name and name ~= "Módulo" then
				declaredModules[name] = true
			end
		elseif region == "4.13" then
			local name = line:match("^| `(%u%w+)`")
			if name then
				declaredModules[name] = true
			end
		elseif region == "4.15" then
			if line:match("^%*%*Registro adicional") then
				for name in line:gmatch("`(%u%w+)`") do
					declaredModules[name] = true
				end
			else
				local did = line:match("^| (D%d+) |")
				if did then
					gluedClaims[did] = true
					for name in line:gmatch("`(%u%w+)`") do
						table.insert(glueTargets, { did, name })
					end
				end
			end
		end
	end
end

-- módulos reales de src/ (exenciones: Tests, Definitions, Main, init — §4.15)
local srcModules = {}
local function collectSrc(dir)
	local ok, entries = pcall(fs.readDir, dir)
	if not ok then
		return
	end
	for _, name in ipairs(entries) do
		local p = dir .. "/" .. name
		if fs.isDir(p) then
			if name ~= "Tests" and name ~= "Definitions" then
				collectSrc(p)
			end
		else
			local base = name:match("^(.+)%.luau?$")
			if base and not base:match("%.spec$") then
				base = base:gsub("%.server$", ""):gsub("%.client$", "")
				if base ~= "Main" and base ~= "init" then
					srcModules[base] = true
				end
			end
		end
	end
end
collectSrc("src")

local moduleUndeclared = {}
for name in pairs(srcModules) do
	if not declaredModules[name] then
		table.insert(moduleUndeclared, name)
	end
end
table.sort(moduleUndeclared)

local glueDangling = {}
for _, t in ipairs(glueTargets) do
	if not declaredModules[t[2]] and not srcModules[t[2]] then
		table.insert(glueDangling, t[1] .. " → " .. t[2])
	end
end
table.sort(glueDangling)

-- ── F8: claims tipados — derivación formal en §2.1 (DL-057) ─────────────────
-- La columna Derivación es NORMATIVA: `R-XXX · P1 + P2 [— comentario]`.
-- Premisas: ID de axioma (C1a...), elección (E1...) o claim [Nombre].
-- Nada deriva de prosa; el comentario tras "—" no se procesa.
local f8Axioms = {}
local f8Claims = {} -- nombre → { raw }
local f8Rules = {}
local f8Elections = {}
local f8ElectionRows = {} -- E-n → { eje (A-n), valor, abierto, estado }
local axes = {} -- A-n → { nombre, dominio = {valores}, cierre } (Z2, DL-064)
local metaLaws = {} -- M-n → { ley, fuente }
local zones = {} -- Z-n → { zona, camino, vence } (registro de zonas no verificadas)
local designClaims = {} -- D-n → { sec, deriv } (capa normativa de §3, DL-061)
local claimedSections = {} -- §3.N con ≥1 claim o marcador
do
	local region, nivel = nil, nil
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region = (h:gsub("%.$", ""))
			nivel = nil
		end
		local nv = line:match("^#### Nivel (%d)")
		if nv then
			nivel = tonumber(nv)
		end
		if region == "2.1" and nivel == 0 then
			local id = line:match("^| %*%*.-%*%* %((.-)%)")
			if id then
				f8Axioms[id] = true
			end
		elseif region == "2.1" and (nivel == 1 or nivel == 2) then
			if line:match("^|") and not line:match("^|%-") and not line:match("^| Principio") then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				local name = (cells[1] or ""):gsub("%s*⚠%s*$", "")
				local deriv = nil
				for i = #cells, 1, -1 do
					if cells[i] ~= "" then
						deriv = cells[i]
						break
					end
				end
				if name ~= "" and deriv then
					f8Claims[name] = { raw = deriv }
				end
			end
		elseif region == "3.0" then
			-- claims de diseño: | ID | Sección | Claim | Derivación |
			local did = line:match("^| (D%d+) |")
			if did then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				local sec, deriv = cells[2] or "", cells[4] or ""
				designClaims[did] = {
					sec = sec,
					deriv = deriv,
					enunciado = cells[3] or "",
					sello = cells[5] or "",
				}
				if sec ~= "" then
					claimedSections[sec] = true
				end
				-- marcador legítimo ("— empírico → playtest"): cuenta para
				-- totalidad pero no es claim derivado (no pasa por F8).
				if deriv ~= "" and not deriv:match("^—") then
					f8Claims[did] = { raw = deriv }
				end
			end
		elseif region == "2.7" then
			local r = line:match("^| (R%-%u+) |")
			if r then
				f8Rules[r] = true
			end
			local e = line:match("^| (E%d+) |")
			if e then
				f8Elections[e] = true
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				-- | ID | Eje (A-n) | Valor | Abierto por | Estado |
				f8ElectionRows[e] = {
					eje = cells[2] or "",
					valor = cells[3] or "",
					abierto = cells[4] or "",
					estado = cells[5] or "",
				}
			end
			-- registro de ejes (Z2): | ID | Eje | Dominio | Cierre |
			local a = line:match("^| (A%d+) |")
			if a then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				local dominio = {}
				for v in (cells[3] or ""):gmatch("`([^`]+)`") do
					table.insert(dominio, v)
				end
				axes[a] = { nombre = cells[2] or "", dominio = dominio, cierre = cells[4] or "" }
			end
		elseif region == "2.8" then
			local m = line:match("^| (MT?%d+) |")
			if m then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				-- | ID | Ley | Revelada por | Derivación |
				metaLaws[m] = { ley = cells[2] or "", fuente = cells[3] or "" }
				-- las meta-leyes son claims: sus derivaciones pasan por las
				-- reglas F8 (MT0 = R-POST; M-n = R-ESP · [MT0])
				if cells[4] and cells[4] ~= "" then
					f8Claims[m] = { raw = cells[4] }
				end
			end
			local z = line:match("^| (Z%d+) |")
			if z then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				-- | ID | Zona | Camino de cierre | Vence |
				-- | ID | Zona | Camino de cierre | Vence | Ratificada |
				zones[z] = {
					zona = cells[2] or "",
					camino = cells[3] or "",
					vence = cells[4] or "",
					ratif = cells[5] or "",
				}
			end
		end
	end
end

local f8BadDeriv, f8UnknownRule, f8UnknownPremise, f8Arity = {}, {}, {}, {}
local f8Edges = {} -- nombre → { claims premisa } para detección de ciclos
for name, c in pairs(f8Claims) do
	local formal = c.raw
	local dash = formal:find(" — ", 1, true)
	if dash then
		formal = formal:sub(1, dash - 1)
	end
	formal = formal:gsub("%s+$", "")
	local rule, premStr = formal:match("^(R%-%u+)%s*·%s*(.+)$")
	if not rule then
		rule = formal:match("^(R%-%u+)$")
	end
	if not rule then
		table.insert(f8BadDeriv, name .. " → \"" .. c.raw .. "\"")
	else
		if not f8Rules[rule] then
			table.insert(f8UnknownRule, name .. " → " .. rule)
		end
		local prems = {}
		if premStr then
			for tok in premStr:gmatch("[^+]+") do
				tok = tok:gsub("^%s+", ""):gsub("%s+$", "")
				if tok ~= "" then
					table.insert(prems, tok)
				end
			end
		end
		f8Edges[name] = {}
		local elecN, otherN = 0, 0
		for _, tok in ipairs(prems) do
			local claimRef = tok:match("^%[(.+)%]$")
			if claimRef then
				if f8Claims[claimRef] then
					otherN += 1
					table.insert(f8Edges[name], claimRef)
				else
					table.insert(f8UnknownPremise, name .. " → [" .. claimRef .. "]")
				end
			elseif f8Elections[tok] then
				elecN += 1
			elseif f8Axioms[tok] then
				otherN += 1
			else
				table.insert(f8UnknownPremise, name .. " → " .. tok)
			end
		end
		local n = #prems
		local bad = false
		if rule == "R-POST" then
			bad = n ~= 0
		elseif rule == "R-ESP" then
			bad = n ~= 1 or elecN ~= 0
		elseif rule == "R-COMP" then
			bad = n < 2 or elecN ~= 0
		elseif rule == "R-ELEC" then
			bad = n < 2 or elecN < 1 or otherN < 1
		end
		if bad and f8Rules[rule] then
			table.insert(f8Arity, name .. " → " .. rule .. " con " .. n .. " premisa(s), " .. elecN .. " elección(es)")
		end
	end
end
table.sort(f8BadDeriv)
table.sort(f8UnknownRule)
table.sort(f8UnknownPremise)
table.sort(f8Arity)

local f8Cycle = {}
do
	local done = {}
	for start in pairs(f8Claims) do
		if not done[start] then
			local visiting = {}
			local found = false
			local function dfs(n)
				if found or done[n] then
					return
				end
				if visiting[n] then
					found = true
					return
				end
				visiting[n] = true
				for _, m in ipairs(f8Edges[n] or {}) do
					dfs(m)
				end
				visiting[n] = nil
				done[n] = true
			end
			dfs(start)
			if found then
				table.insert(f8Cycle, start)
				done[start] = true
			end
		end
	end
end
table.sort(f8Cycle)

-- elecciones como VALENCIAS (DL-058): un eje atómico + un valor, sin duplicados.
-- La conjunción (" — ", " + ", " y " en Eje) es la firma textual del defecto
-- histórico de E1 (dos argumentos en una elección) — lint de señal, no de
-- completitud: la atomicidad plena la fuerza la forma + la pasada del AUDITOR.
-- (M3, DL-059: la relación valor↔eje NO se somete al PO — él solo elige el valor.)
local electionMalformed, electionAxisDup, electionCompound = {}, {}, {}
do
	local axisSeen = {}
	local ids = {}
	for id in pairs(f8ElectionRows) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local row = f8ElectionRows[id]
		if row.eje == "" or row.abierto == "" or row.valor == "" or row.estado == "" then
			table.insert(electionMalformed, id)
		end
		if row.eje ~= "" then
			local norm2 = row.eje:lower()
			if axisSeen[norm2] then
				table.insert(electionAxisDup, id .. " duplica eje de " .. axisSeen[norm2])
			else
				axisSeen[norm2] = id
			end
		end
		-- la atomicidad del eje vive ahora en el registro (un A-n es atómico
		-- por construcción); aquí solo queda el valor sin conjunciones.
		if row.valor:find(" — ", 1, true) or row.valor:find(" + ", 1, true) then
			table.insert(electionCompound, id .. " (valor con conjunción)")
		end
	end
end

-- ── Z2 (DL-064): el eje es un TIPO con dominio enumerado ────────────────────
-- Sin dominio, "el valor pertenece a su eje" no es comprobable y "¿es el
-- mejor valor?" no es respondible. Estas reglas son la precondición del
-- juicio de optimalidad, no un chequeo de forma más.
local axisMalformed, axisDomainThin = {}, {}
local electionAxisUnregistered, electionValueOffAxis = {}, {}
do
	local ids = {}
	for id in pairs(axes) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local ax = axes[id]
		if ax.nombre == "" or (ax.cierre ~= "cerrado" and ax.cierre ~= "abierto") then
			table.insert(axisMalformed, id .. " → sin nombre o Cierre distinto de cerrado|abierto")
		end
		-- un eje con un solo valor no es una elección: es una consecuencia
		-- disfrazada. El dominio mínimo de un eje real es 2.
		if #ax.dominio < 2 then
			table.insert(axisDomainThin, id .. " → dominio de " .. #ax.dominio .. " valor(es)")
		end
	end

	local eids = {}
	for id in pairs(f8ElectionRows) do
		table.insert(eids, id)
	end
	table.sort(eids)
	for _, id in ipairs(eids) do
		local row = f8ElectionRows[id]
		local ejeId = row.eje:match("^A%d+$")
		if not ejeId or not axes[ejeId] then
			table.insert(electionAxisUnregistered, id .. " → eje \"" .. row.eje .. "\" no está en el registro")
		else
			local valor = row.valor:match("^`(.+)`$") or row.valor
			local pertenece = false
			for _, v in ipairs(axes[ejeId].dominio) do
				if v == valor then
					pertenece = true
					break
				end
			end
			if not pertenece then
				table.insert(electionValueOffAxis, id .. " → \"" .. valor .. "\" no está en el dominio de " .. ejeId)
			end
		end
	end
end

-- metaframework (DL-059): la forma de las leyes M-n es verificada — su
-- contenido es constitución (ratifica el PO; las leyes son contenido, M3).
local metaLawMalformed = {}
do
	local ids = {}
	for id in pairs(metaLaws) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local row = metaLaws[id]
		local hasDl = false
		for dl in row.fuente:gmatch("DL%-(%d+)") do
			if nodes["DL-" .. dl] then
				hasDl = true
			else
				table.insert(metaLawMalformed, id .. " → fuente DL-" .. dl .. " inexistente")
			end
		end
		if row.ley == "" or not hasDl then
			table.insert(metaLawMalformed, id .. (row.ley == "" and " → ley vacía" or " → sin fuente DL"))
		end
	end
end

-- totalidad de la capa normativa de §3 (DL-061): toda subsección tiene ≥1
-- claim derivado o marcador legítimo. Sin esto, una sección podría fundar
-- normativamente desde prosa — violación de M4 invisible.
local unclaimedSection = {}
for id, kind in pairs(nodes) do
	if kind == "section" and id:match("^§3%.%d+$") and id ~= "§3.0" and not claimedSections[id] then
		table.insert(unclaimedSection, id)
	end
end
table.sort(unclaimedSection)

-- sello del enunciado (Z4, DL-063): el claim declara el hash de su propio
-- enunciado. Reescribirlo sin re-sellar = violación; moverlo no toca nada.
-- Re-sellar es el ACTO que hace visible una remodelación: no valida que el
-- contenido nuevo sea correcto (eso es Z1), valida que el cambio se declaró.
local claimSealMismatch = {}
for id, c in pairs(designClaims) do
	local esperado = sealOf(c.enunciado)
	if c.sello == "" then
		table.insert(claimSealMismatch, id .. " → sin sello (esperado " .. esperado .. ")")
	elseif c.sello ~= esperado then
		table.insert(claimSealMismatch, id .. " → sello " .. c.sello .. ", enunciado sella " .. esperado)
	end
end
table.sort(claimSealMismatch)

-- `--seals`: recalcula e imprime los sellos. Se corre al remodelar un claim,
-- para obtener el sello nuevo que hay que escribir en la tabla.
if table.find(process.args, "--seals") then
	local ids = {}
	for id in pairs(designClaims) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return tonumber(a:sub(2)) < tonumber(b:sub(2))
	end)
	print("Sellos de §3.0 (enunciado normalizado → FNV-1a/6):\n")
	for _, id in ipairs(ids) do
		print(string.format("  %-4s %s", id, sealOf(designClaims[id].enunciado)))
	end
	process.exit(0)
end

-- totalidad del gluing (DL-062): todo claim normativo de §3.0 declara CÓMO se
-- realiza. El ancla es el claim, no la prosa (cierre de Z3): un claim sin
-- realización es obligación pendiente, no omisión silenciosa.
local ungluedClaim = {}
for id in pairs(designClaims) do
	if not gluedClaims[id] then
		table.insert(ungluedClaim, id)
	end
end
table.sort(ungluedClaim, function(a, b)
	return tonumber(a:sub(2)) < tonumber(b:sub(2))
end)

-- zonas no verificadas (DL-060): dependencias sin garantía — explícitas y
-- ACOTADAS. Zona vencida = violación: el vencimiento fuerza la decisión
-- (formalizar, disolver o re-acotar — re-acotar es del PO).
local zoneMalformed, zoneExpired = {}, {}
do
	local ids = {}
	for id in pairs(zones) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local z = zones[id]
		-- La ratificación del PO es fuente de garantía (perímetro binario,
		-- DL-060): una zona SIN ratificar es una frontera que yo me concedí.
		-- Por eso está en la forma, no en la prosa de un DL.
		local ratified = z.ratif:match("^PO %d%d%d%d%-%d%d%-%d%d$") ~= nil
		if z.zona == "" or z.camino == "" or not ratified or not z.vence:match("^%d%d%d%d%-%d%d%-%d%d$") then
			table.insert(zoneMalformed, id)
		elseif today > z.vence then
			table.insert(zoneExpired, id .. " (venció " .. z.vence .. ")")
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
reportViolations("undeclared_free (DL modifica el master sin declarar Libre:)", undeclaredFree, function(r)
	return r
end)
reportViolations("module_undeclared (módulo en src/ no declarado en §4)", moduleUndeclared, function(r)
	return r
end)
reportViolations("unglued_claim (claim de §3.0 sin realización en §4.15)", ungluedClaim, function(r)
	return r
end)
reportViolations("unclaimed_section (sección §3 sin claim normativo en §3.0)", unclaimedSection, function(r)
	return r
end)
reportViolations("claim_seal_mismatch (enunciado reescrito sin re-sellar)", claimSealMismatch, function(r)
	return r
end)
reportViolations("glue_dangling (claim de módulo inexistente en §4.15)", glueDangling, function(r)
	return r
end)
reportViolations("claim_bad_derivation (§2.1 sin derivación formal R-XXX)", f8BadDeriv, function(r)
	return r
end)
reportViolations("unknown_rule (regla no registrada en §2.7)", f8UnknownRule, function(r)
	return r
end)
reportViolations("unknown_premise (premisa no resuelve a axioma/elección/claim)", f8UnknownPremise, function(r)
	return r
end)
reportViolations("rule_arity (condición sintáctica de la regla violada)", f8Arity, function(r)
	return r
end)
reportViolations("claim_cycle (ciclo en premisas de claims)", f8Cycle, function(r)
	return r
end)
reportViolations("election_malformed (elección sin eje/abierto-por/valor/estado)", electionMalformed, function(r)
	return r
end)
reportViolations("election_axis_dup (dos elecciones sobre el mismo eje)", electionAxisDup, function(r)
	return r
end)
reportViolations("axis_malformed (eje sin nombre o sin Cierre cerrado|abierto)", axisMalformed, function(r)
	return r
end)
reportViolations("axis_domain_thin (eje con dominio < 2 valores: no es una elección)", axisDomainThin, function(r)
	return r
end)
reportViolations("election_axis_unregistered (elección sobre eje no registrado)", electionAxisUnregistered, function(r)
	return r
end)
reportViolations("election_value_off_axis (valor fuera del dominio de su eje)", electionValueOffAxis, function(r)
	return r
end)
reportViolations("election_compound (valor con conjunción)", electionCompound, function(r)
	return r
end)
reportViolations("meta_law_malformed (ley M-n vacía o fuente sin DL existente)", metaLawMalformed, function(r)
	return r
end)
reportViolations("zone_malformed (zona sin descripción/camino/fecha/ratificación)", zoneMalformed, function(r)
	return r
end)
reportViolations("zone_expired (zona no verificada VENCIDA)", zoneExpired, function(r)
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
	+ #levelSkip + #domainMismatch + #implLeak + #undeclaredFree
	+ #moduleUndeclared + #ungluedClaim + #glueDangling + #unclaimedSection
	+ #f8BadDeriv + #f8UnknownRule + #f8UnknownPremise + #f8Arity + #f8Cycle
	+ #electionMalformed + #electionAxisDup + #electionCompound + #metaLawMalformed
	+ #axisMalformed + #axisDomainThin + #electionAxisUnregistered + #electionValueOffAxis
	+ #zoneMalformed + #zoneExpired + #claimSealMismatch
if violations > 0 then
	print(string.format("\n%d violación(es) — el grafo de derivación NO está íntegro.", violations))
	process.exit(1)
else
	print("\nSin violaciones. Grafo consistente al nivel actual.")
end
