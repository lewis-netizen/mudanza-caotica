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

-- ── entidades como premisas citables (§2.3, DL-077) ─────────────────────────
-- Las entidades fundamentales son PRIMITIVOS: nunca se derivaron (deuda de
-- ontología conocida). Hacerlas citables no las deriva — hace VISIBLE que un
-- claim se apoya en ellas, en vez de que la dependencia entre por debajo.
local entities = {} -- nombre → texto de su bloque en §2.3
do
	local region, cur = nil, nil
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region, cur = (h:gsub("%.$", "")), nil
		end
		if region == "2.3" then
			local name = line:match("^%*%*(%u%w+)%*%*")
			if name then
				cur = name
				entities[cur] = line
			elseif cur then
				entities[cur] = entities[cur] .. " " .. line
			end
		end
	end
end

-- ── plan del programa (§5.11, DL-079) ───────────────────────────────────────
-- El orden dejó de vivir en prosa (la lección de DL-044): las dependencias se
-- declaran y el FRENTE ACCIONABLE se computa. No gobierna — ordena y se lee.
local planSteps = {} -- P-n → { trabajo, deps = {P-n}, estado }
do
	local region = nil
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region = (h:gsub("%.$", ""))
		end
		if region == "5.11" then
			local id = line:match("^| (P%d+) |")
			if id then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				local deps = {}
				for d in (cells[3] or ""):gmatch("(P%d+)") do
					table.insert(deps, d)
				end
				local salda = {}
				for s in (cells[4] or ""):gmatch("([ZXD]%d+)") do
					salda[s] = true
				end
				planSteps[id] = { trabajo = cells[2] or "", deps = deps, salda = salda, estado = cells[5] or "" }
			end
		end
	end
end
local function planClosed(e)
	return e:match("^hecho") ~= nil or e:match("^disuelto") ~= nil or e:match("^pospuesto") ~= nil
end
local planDangling = {}
do
	local ids = {}
	for id in pairs(planSteps) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local s = planSteps[id]
		if s.trabajo == "" or s.estado == "" then
			table.insert(planDangling, id .. " → trabajo o estado vacío")
		end
		for _, d in ipairs(s.deps) do
			if not planSteps[d] then
				table.insert(planDangling, id .. " → depende de " .. d .. ", que no existe")
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

-- vocabulario controlado (§2.9, DL-074): forma prohibida en texto normativo
-- de §3 = colisión léxica. Mismo patrón que impl_leak — scan de superficie,
-- sin etiquetar qué claim usa qué término (eso sería dependencia de agente).
-- Las formas se leen de §2.9, que NO se escanea (vive en §2).
local vocabSurfaces = {} -- todas las formas modeladas (pref + sinónimos)
local bannedForms = {} -- forma prohibida (minúsculas) → término preferido
do
	local region = nil
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region = (h:gsub("%.$", ""))
		end
		if region == "2.9" and line:match("^| ") and not line:match("^| Término") and not line:match("^|%-") then
			local cells = {}
			for cell in line:gmatch("|([^|]*)") do
				table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
			end
			local pref = cells[1] or ""
			for form in (cells[4] or ""):gmatch("`([^`]+)`") do
				bannedForms[form:lower()] = pref
			end
			-- superficies MODELADAS: lo único que el detector de procedencia
			-- puede ver. Fuera de aquí está su ceguera (DL-078).
			if pref ~= "" then
				table.insert(vocabSurfaces, pref:lower())
				for s in (cells[5] or ""):gmatch("`([^`]+)`") do
					table.insert(vocabSurfaces, s:lower())
				end
			end
		end
	end
end

-- ── forma de TODA tabla del master (TCB, DL-095) ────────────────────────────
-- El misparse silencioso es el riesgo dominante de la TCB: una columna
-- corrida hace que un parser lea celdas equivocadas y dé veredictos falsos
-- sin avisar. Ya pasó dos veces en §2.9.
-- En vez de una regla por tabla, el invariante es general y se auto-mantiene:
-- LA CABECERA DECLARA CUÁNTAS COLUMNAS HAY, y toda fila debe coincidir. Con
-- esto la clase entera sale de la TCB, para las tablas que existen y las que
-- se escriban después.
-- Las barras escapadas (`\|`, p. ej. en firmas `"pickup"\|"drop"`) no separan.
local tableShape = {}
do
	local function columnCount(line)
		local n, i = 0, 1
		while i <= #line do
			local c = line:sub(i, i)
			if c == "\\" then
				i += 2
			else
				if c == "|" then
					n += 1
				end
				i += 1
			end
		end
		return n - 1
	end
	local inFence, expected, headerLine = false, nil, 0
	local i = 0
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		i += 1
		if line:match("^```") then
			inFence = not inFence
			expected = nil
		elseif inFence then
			-- dentro de un bloque de código no hay tablas
		elseif line:match("^%s*|[%s%-:|]*$") then
			-- fila separadora (solo barras, guiones, dos puntos): estructura,
			-- no dato — ningún parser lee sus celdas, luego no es misparse.
		elseif line:match("^%s*|") then
			local n = columnCount(line)
			if expected == nil then
				expected, headerLine = n, i
			elseif n ~= expected then
				table.insert(
					tableShape,
					"L" .. i .. " → " .. n .. " columnas; la cabecera (L" .. headerLine .. ") declara " .. expected
				)
			end
		else
			expected = nil
		end
	end
end

-- ── naturaleza del re-sello (Z4 obligación, P13, DL-104) ────────────────────
-- El sello (DL-063) hace VISIBLE que un claim cambió; «Sellado por» (DL-073)
-- lo atribuye a un DL. La OBLIGACIÓN del cambio —¿exige re-implementar?— NO se
-- deriva del delta textual: DL-093 reescribió 5 claims con delta enorme y
-- CERO cambio de compromiso. Esa derivación es ONTOLÓGICA (§2.10).
-- Lo decidible es el ACTO: todo DL que sella un claim de §3.0 declara la
-- NATURALEZA del cambio (`Resello: nuevo | cosmético | normativo`). No valida
-- que el juicio sea correcto —eso es del PO/agente (M11)— valida que se hizo,
-- como undeclared_free. Un resello `normativo` marca que la realización del
-- claim puede necesitar revisión (X17).
local resealUndeclared = {}
do
	local sealers = {}
	do
		local region = nil
		for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
			local h = line:match("^#+%s+(%d[%d%.]*)")
			if h then
				region = (h:gsub("%.$", ""))
			end
			if region == "3.0" then
				local dl = line:match("^| D%d+ | §3.-| (DL%-%d+) |%s*$")
				if dl then
					sealers[dl] = true
				end
			end
		end
	end
	local declared = {}
	do
		local cur = nil
		for _, line in ipairs(readLines("docs/PROJECT_DECISION_LOG.md")) do
			local dl = line:match("^### (DL%-%d+)")
			if dl then
				cur = dl
			end
			local r = line:match("^Resello:%s*(%S+)")
			if r and cur and (r == "nuevo" or r == "cosmético" or r == "normativo") then
				declared[cur] = true
			end
		end
	end
	local ids = {}
	for dl in pairs(sealers) do
		table.insert(ids, dl)
	end
	table.sort(ids)
	for _, dl in ipairs(ids) do
		if not declared[dl] then
			table.insert(resealUndeclared, dl .. " → sella claims de §3.0 sin declarar `Resello:` (nuevo|cosmético|normativo)")
		end
	end
end

-- ── ticket anclado en prosa de diseño (P9, DL-099) ──────────────────────────
-- Desde DL-061 §3.1–§3.9 son COMENTARIO no normativo: la norma vive en los
-- claims D-n (§3.0). Un ticket cuyo «Deriva de:» cita una sección §3.x sin
-- citar el claim que esa sección comenta se ancla en prosa — el mismo M4 que
-- §2.2 tenía. La norma la carga el claim, no la subsección. QA exento (hitos
-- transversales, no implementan un claim). El «Deriva de:» conserva la prosa
-- como contexto legible; solo se exige el ancla D-n junto a ella.
local ticketDesignProse = {}
do
	local cur, derivaLine = nil, nil
	for _, line in ipairs(readLines("docs/TICKETS.md")) do
		local t = line:match("^### (%u+%-%d+)")
		if t then
			cur, derivaLine = t, nil
		end
		local dv = line:match("^Deriva de:%s*(.+)")
		if dv and cur then
			derivaLine = dv
			if not cur:match("^QA%-") and dv:match("§3%.%d") and not dv:match("%f[%w]D%d+%f[%W]") then
				table.insert(ticketDesignProse, cur .. " → cita §3.x (comentario) sin el claim D-n que la funda")
			end
		end
	end
end
table.sort(ticketDesignProse)

-- ── sistema sin claim que lo requiera (P8, DL-098) ──────────────────────────
-- La INVERSA del gluing: `unglued_claim` exige que todo claim tenga módulo;
-- esto exige que todo SISTEMA trace a un claim que lo requiera. Es la
-- preocupación del inicio de sesión —¿los sistemas se derivaron o se
-- heredaron del bootstrap?— vuelta regla: un sistema nuevo sin claim que lo
-- pida es herencia no derivada, y ahora rompe el build.
-- Exentos por NATURALEZA (no son sistemas): datos de entidad (Definitions/),
-- configuración (Config/), infraestructura transversal (Lib/, Constants/,
-- Persistence/), núcleos puros (Rules/ — su shell imperativo es el que se
-- gluea), y los entry points Main/init. Lo que queda son los sistemas de
-- server/ y client/, que DEBEN aparecer en el gluing.
local moduleUnderived = {}
do
	local glued = {}
	do
		local region = nil
		for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
			local h = line:match("^#+%s+(%d[%d%.]*)")
			if h then
				region = (h:gsub("%.$", ""))
			end
			if region == "4.15" then
				for name in line:gmatch("`(%u%w+)`") do
					glued[name] = true
				end
			end
		end
	end
	local function scan(dir, exemptDir)
		local ok, entries = pcall(fs.readDir, dir)
		if not ok then
			return
		end
		for _, name in ipairs(entries) do
			local p = dir .. "/" .. name
			if fs.isDir(p) then
				local ex = exemptDir
					or name == "Definitions"
					or name == "Config"
					or name == "Lib"
					or name == "Constants"
					or name == "Persistence"
					or name == "Rules"
					or name == "Tests"
				scan(p, ex)
			else
				local base = name:match("^(.+)%.luau?$")
				if base and not base:match("%.spec$") then
					base = base:gsub("%.server$", ""):gsub("%.client$", "")
					if not exemptDir and base ~= "Main" and base ~= "init" and not glued[base] then
						table.insert(moduleUnderived, base .. " → sistema en src/ que ningún claim de §4.15 requiere")
					end
				end
			end
		end
	end
	scan("src", false)
end
table.sort(moduleUnderived)

-- ── contrato de función vs firma real (Z5, DL-092) ──────────────────────────
-- El gluing verificaba que el claim NOMBRE un módulo existente, no que el
-- módulo HAGA lo que su contrato declara (Z5). §4.13 declara las funciones de
-- cada núcleo puro; aquí se comprueban contra `src/` de verdad. Es el primer
-- chequeo que cruza de los documentos al código.
local contractMissing = {}
do
	local region = nil
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region = (h:gsub("%.$", ""))
		end
		if region == "4.13" then
			local mod = line:match("^| `(%u%w+)` |")
			if mod then
				local body = line:match("^| `%u%w+` |(.*)")
				local src = nil
				for _, dir in ipairs({ "src/shared/Rules/", "src/shared/Lib/", "src/server/", "src/client/" }) do
					local p = dir .. mod .. ".lua"
					if fs.isFile(p) then
						src = fs.readFile(p)
						break
					end
				end
				if src then
					local seen = {}
					for fn in (body or ""):gmatch("`(%a[%w_]*)%(") do
						if not seen[fn] then
							seen[fn] = true
							if not src:find("function " .. mod .. "." .. fn, 1, true) and not src:find("function " .. mod .. ":" .. fn, 1, true) then
								table.insert(contractMissing, mod .. "." .. fn .. " → declarada en §4.13, ausente en src/")
							end
						end
					end
				end
			end
		end
	end
end
table.sort(contractMissing)

-- ── forma de las filas de §2.9 (TCB, DL-090) ────────────────────────────────
-- El fallo más peligroso de un parser es leer celdas CORRIDAS en silencio: el
-- veredicto sale mal sin que nada avise. §3.0 ya está protegida por la forma
-- de sus celdas (sello hex, `Sellado por` = DL-nnn); §2.9 no tenía nada, y sus
-- columnas se movieron dos veces en esta sesión. Validar la forma de cada
-- celda mueve al parser de «confiado» a «comprobado»: TCB más pequeña.
local VOCAB_EJES = { mecanismo = true, polaridad = true, predicado = true, entidad = true, externo = true }
local vocabMalformed = {}
do
	local region = nil
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region = (h:gsub("%.$", ""))
		end
		if region == "2.9" and line:match("^| ") and not line:match("^| Término") and not line:match("^|%-") then
			local cells = {}
			for cell in line:gmatch("|([^|]*)") do
				table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
			end
			local term = cells[1] or "?"
			local eje = (cells[2] or ""):lower()
			local ratif = cells[7] or ""
			-- 7 columnas + el vacío tras la barra final. El conteo es lo que
			-- caza una columna CORRIDA: los valores desplazados pueden caer
			-- en celdas que parecen válidas por casualidad.
			if #cells ~= 8 then
				table.insert(vocabMalformed, term .. " → " .. (#cells - 1) .. " columnas, se esperaban 7")
			else			if not VOCAB_EJES[eje] then
				table.insert(vocabMalformed, term .. " → eje \"" .. eje .. "\" desconocido")
			elseif ratif ~= "—" and not ratif:match("^PO %d%d%d%d%-%d%d%-%d%d$") then
				table.insert(vocabMalformed, term .. " → Ratificada \"" .. ratif .. "\" no es «—» ni «PO <fecha>»")
			end
			end
		end
	end
end
table.sort(vocabMalformed)

-- ── cobertura del vocabulario (DL-078) ──────────────────────────────────────
-- El detector `--provenance` solo ve términos MODELADOS. Un 0 suyo puede
-- significar "limpio" o "ciego", y son indistinguibles sin medir la brecha.
-- Es la segunda instancia de esa clase: la variante (DL-072) valía 0 durante
-- 32 versiones por falta de instrumento, no por salud.
-- El conjunto NO cubierto no es ruido: es la COLA DE TRABAJO — qué definir a
-- continuación, ordenado por frecuencia (más uso = más cobertura ganada).
-- Es el movimiento de CEGAR (la brecha dirige el refinamiento) y de
-- attribute exploration (preguntar lo mínimo que completa la teoría).
local STOP = {}
for w in
	(
		"para pero como cuando donde entre sobre desde hasta segun sino solo "
		.. "cada todo toda todos todas otro otra otros otras mismo misma este esta "
		.. "esto ese esa eso aquel aquella algun alguna ningun ninguna mas menos "
		.. "muy tanto tanta poco poca gran grande mayor menor bien vive vive "
		.. "existe existen tiene tienen puede pueden debe deben hace hacen dice "
		.. "estan esta son ser sido siendo haber habia sera seran cuenta cuentan "
		.. "genera generan produce producen vale valen basta requiere requieren "
		.. "porque aunque mientras ademas tambien nunca siempre nada algo"
	):gmatch("%S+")
do
	STOP[w] = true
end

local function contentWords(txt)
	local out = {}
	for w in txt:lower():gmatch("[^%s%.,;:%(%)%[%]%-—«»\"'?!/]+") do
		if #w >= 6 and not STOP[w] and not w:match("%d") then
			table.insert(out, w)
		end
	end
	return out
end
local vocabBanned = {}
do
	local region, i = nil, 0
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		i += 1
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region = (h:gsub("%.$", ""))
		end
		if region and region:match("^3") then
			local low = line:lower()
			for form, pref in pairs(bannedForms) do
				if low:find(form, 1, true) then
					table.insert(vocabBanned, "§3 L" .. i .. ' → "' .. form .. '" (usar "' .. pref .. '")')
				end
			end
		end
	end
end
table.sort(vocabBanned)

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
local zones = {} -- Z-n → { zona, tipo, camino, vence, ratif }
local escapes = {} -- X-n → { clase, hallado, resol } (registro de escapes, DL-070)
local designClaims = {} -- D-n → { sec, deriv } (capa normativa de §3, DL-061)
local claimedSections = {} -- §3.N con ≥1 claim o marcador
do
	local region, nivel = nil, nil
	local inZoneHistory = false
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
					selladoPor = cells[6] or "",
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
			-- §2.8 tiene DOS tablas de zonas: el registro VIGENTE y el
			-- historial de cerradas. Ambas empiezan por | Z-n |, así que se
			-- distinguen por cabecera — contar celdas enmascararía filas
			-- realmente malformadas, que es lo que zone_malformed debe ver.
			if line:match("^| ID | Zona | Abierta por | Cerrada por |") then
				inZoneHistory = true
			elseif line:match("^| ID | Zona — sin garantía") then
				inZoneHistory = false
			end
			local z = not inZoneHistory and line:match("^| (Z%d+) |") or nil
			if z then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				-- | ID | Zona | Camino de cierre | Vence |
				-- | ID | Zona | Tipo MT0 | Camino de cierre | Vence | Ratificada |
				zones[z] = {
					zona = cells[2] or "",
					tipo = cells[3] or "",
					camino = cells[4] or "",
					vence = cells[5] or "",
					ratif = cells[6] or "",
				}
			end
			-- registro de escapes: | ID | Clase | Hallado en | Resolución |
			local x = line:match("^| (X%d+) |")
			if x then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				escapes[x] = { clase = cells[2] or "", hallado = cells[3] or "", resol = cells[4] or "" }
			end
		end
	end
end

local f8BadDeriv, f8UnknownRule, f8UnknownPremise, f8Arity = {}, {}, {}, {}
local electionUnratifiedCited = {} -- elección no ratificada citada como premisa
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
				elseif entities[claimRef] then
					-- primitivo de §2.3: hoja del grafo, sin arista de ciclo
					otherN += 1
				else
					table.insert(f8UnknownPremise, name .. " → [" .. claimRef .. "]")
				end
			elseif f8Elections[tok] then
				elecN += 1
				-- una elección SIN RATIFICAR no es contenido garantizado
				-- (perímetro binario, DL-060): no puede fundar un claim.
				-- Registrar el valor vigente de un eje es DESCRIBIRLO;
				-- citarlo como premisa es APOYARSE en él.
				local erow = f8ElectionRows[tok]
				if erow and erow.estado ~= "decidida" then
					table.insert(electionUnratifiedCited, name .. " → " .. tok .. " (" .. erow.estado .. ")")
				end
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

-- ── procedencia del sello (Z4, DL-073) ──────────────────────────────────────
-- Cada claim declara QUÉ DL lo selló. La declaración es AUTO-CONSISTENTE sin
-- necesitar historia: el DL debe existir Y debe declarar §3.0 en su
-- `Modifica:`. Una procedencia que miente —un DL que nunca tocó los claims—
-- se detecta desde un solo estado. Con esto, remodelar deja de ser solo
-- visible (el sello, DL-063) y pasa a ser ATRIBUIBLE.
local sealUnprovenanced, sealProvenanceInconsistent = {}, {}
do
	local modifiesClaims = {} -- DL → declara §3.0 en Modifica
	for _, m in ipairs(modifies) do
		if m[2] == "§3.0" then
			modifiesClaims[m[1]] = true
		end
	end
	local ids = {}
	for id in pairs(designClaims) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return tonumber(a:sub(2)) < tonumber(b:sub(2))
	end)
	for _, id in ipairs(ids) do
		local dl = designClaims[id].selladoPor
		if not dl:match("^DL%-%d+$") then
			table.insert(sealUnprovenanced, id .. " → \"" .. dl .. "\" no es un DL")
		elseif not nodes[dl] then
			table.insert(sealUnprovenanced, id .. " → " .. dl .. " no existe")
		elseif not modifiesClaims[dl] then
			table.insert(sealProvenanceInconsistent, id .. " → " .. dl .. " no declara §3.0 en Modifica:")
		end
	end
end

-- ── estructura de la deuda (DL-071) ─────────────────────────────────────────
-- Un claim BLOQUEADO debe nombrar a su bloqueador, y el bloqueador debe
-- existir: una elección sin ratificar (E-n) o una zona registrada (Z-n).
-- Sin esto, "— bloqueado: exige un postulado" es deuda que no apunta a nada
-- — el caso real de D18 antes de DL-071. Una deuda sin acreedor no se cobra.
local blockedClaimDangling = {}
for id, c in pairs(designClaims) do
	if c.deriv:match("^—%s*bloqueado") then
		local ok = false
		for e in c.deriv:gmatch("E(%d+)") do
			if f8ElectionRows["E" .. e] then
				ok = true
			end
		end
		for z in c.deriv:gmatch("Z(%d+)") do
			if zones["Z" .. z] then
				ok = true
			end
		end
		if not ok then
			table.insert(blockedClaimDangling, id .. " → bloqueador inexistente o sin ID: \"" .. c.deriv .. "\"")
		end
	end
end
table.sort(blockedClaimDangling)

-- Validación de objetividad del plan (DL-081): toda deuda DECLARADA —zona
-- abierta, clase de escape sin regla, claim bloqueado— debe estar saldada por
-- algún paso. Es la única completitud que el plan admite probar; frente a
-- deuda NO declarada sigue siendo ciego, y eso es X8, no se cierra con filas.
local planUncoveredDebt = {}
do
	local covered = {}
	for _, s in pairs(planSteps) do
		if not planClosed(s.estado) then
			for d in pairs(s.salda) do
				covered[d] = true
			end
		end
	end
	local debt = {}
	for z in pairs(zones) do
		table.insert(debt, z)
	end
	for id, c in pairs(designClaims) do
		if c.deriv:match("^—%s*bloqueado") then
			table.insert(debt, id)
		end
	end
	for x, e in pairs(escapes) do
		if not e.resol:match("^regla:") and not e.resol:match("^límite:") then
			table.insert(debt, x)
		end
	end
	table.sort(debt)
	for _, id in ipairs(debt) do
		if not covered[id] then
			table.insert(planUncoveredDebt, id .. " → ningún paso del plan lo salda")
		end
	end
end


-- VARIANTE del corpus (Event-B): la deuda abierta como número. Safety son
-- invariantes; la convergencia es una VARIANTE bien fundada que decrece.
-- Nuestras fechas de vencimiento eran un sustituto malo: un reloj no dice si
-- el sistema tiende a algo. Esto se MIDE y se imprime, no se gobierna — no
-- existe un valor correcto, y una zona nueva SUBE la variante legítimamente
-- (descubrir deuda es progreso en conocimiento, retroceso en la medida).
local variantZones, variantBlocked, variantEscapes = 0, 0, 0
for _ in pairs(zones) do
	variantZones += 1
end
for _, c in pairs(designClaims) do
	if c.deriv:match("^—%s*bloqueado") then
		variantBlocked += 1
	end
end
for _, x in pairs(escapes) do
	-- un límite inherente (DL-106) no es deuda: no cuenta en la variante.
	if not x.resol:match("^regla:") and not x.resol:match("^límite:") then
		variantEscapes += 1
	end
end

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
-- `--sensitivity`: ∂downstream/∂premisa sobre el grafo de claims. Responde
-- "si toco esto, ¿qué se mueve?" — el radio de explosión de cada axioma,
-- elección y claim. Es la lectura DISCRETA de la sensibilidad: el corpus no
-- es continuo, así que no hay derivada sino diferencia. Un axioma con radio
-- 0 no sostiene nada; uno con radio alto es donde el diseño se juega.
-- No es una regla: no hay umbral correcto, luego no hay violación que
-- reportar. Es medición, y se lee.
-- Cobertura del detector: qué fracción del vocabulario real de los claims
-- está modelada. Sin esto, un 0 de `--provenance` es indistinguible de
-- ceguera (DL-078).
local vocabCovered, vocabUncovered, vocabFreq = 0, 0, {}
do
	local seen = {}
	for _, c in pairs(designClaims) do
		for _, w in ipairs(contentWords(c.enunciado or "")) do
			local isCovered = false
			for _, s in ipairs(vocabSurfaces) do
				if s:find(w, 1, true) then
					isCovered = true
					break
				end
			end
			if not seen[w] then
				seen[w] = true
				if isCovered then
					vocabCovered += 1
				else
					vocabUncovered += 1
				end
			end
			if not isCovered then
				vocabFreq[w] = (vocabFreq[w] or 0) + 1
			end
		end
	end
end

-- `--provenance` (Z1, DL-075): procedencia de términos. Para cada claim
-- derivado, ¿qué términos de la CONCLUSIÓN no aparecen en ninguna PREMISA?
-- Es la propiedad de subfórmula: una derivación sana no introduce vocabulario
-- de la nada. PERO es DETECTOR, no reja: un término flotante puede ser una
-- premisa colada (defecto) O una paráfrasis de un término de premisa cuya
-- sinonimia no está modelada (falso positivo). Distinguirlos exige la capa de
-- sinonimia — que es CONTENIDO, no relación pura. Por eso no bloquea: empuja.
if table.find(process.args, "--provenance") then
	local termForms = {} -- término preferido → { formas de superficie }
	local termDefinedIn = {} -- término → claim que lo define (extensión conservativa)
	local termRatified = {} -- término → sus sinónimos y marcadores están ratificados
	local termExternal = {} -- eje «externo»: categoría que el diseño EXCLUYE, no deriva
	do
		local region = nil
		for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
			local h = line:match("^#+%s+(%d[%d%.]*)")
			if h then
				region = (h:gsub("%.$", ""))
			end
			if region == "2.9" and line:match("^| ") and not line:match("^| Término") and not line:match("^|%-") then
				local cells = {}
				for cell in line:gmatch("|([^|]*)") do
					table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
				end
				local pref = (cells[1] or ""):lower()
				if pref ~= "" then
					-- El PERÍMETRO BINARIO también rige el vocabulario (DL-086).
					-- Un SINÓNIMO es una afirmación de equivalencia semántica, y
					-- un marcador («Definido en», eje `externo`) silencia un
					-- flotante: ambos CAMBIAN VEREDICTOS. Autorados por un
					-- agente, harían del agente el titular de la garantía —
					-- justo lo que M2 prohíbe. Sin ratificar son INERTES, no
					-- bloqueantes: el claim que dependía de ellos vuelve a
					-- flotar, que es el estado honesto («no sabemos que esté
					-- provenido»). La forma PREFERIDA no necesita ratificación:
					-- nombrar no es afirmar equivalencia.
					local ratified = (cells[7] or ""):match("^PO %d%d%d%d%-%d%d%-%d%d$") ~= nil
					local forms = { pref }
					-- La máquina distingue MORFOLOGÍA de AFIRMACIÓN SEMÁNTICA
					-- (DL-093). `interfieren`/`interferencia` es la misma
					-- palabra flexionada: comprobable por raíz común, no es
					-- una afirmación y no necesita ratificación. `pooling` ≈
					-- `acoplamiento acumulativo` SÍ afirma algo, y sin la
					-- celda `PO <fecha>` queda inerte. Así el PO solo decide
					-- lo que de verdad es una decisión.
					local prefWords = {}
					for w in pref:gmatch("[^%s]+") do
						table.insert(prefWords, w)
					end
					local function sharesStem(a, b)
						local n = math.min(#a, #b)
						if n < 5 then
							return false
						end
						return a:sub(1, math.min(5, n)) == b:sub(1, math.min(5, n))
					end
					local function isMorph(form)
						if form:find(pref, 1, true) then
							return true
						end
						for w in form:gmatch("[^%s]+") do
							if #w >= 5 then
								local ok = false
								for _, pw in ipairs(prefWords) do
									if sharesStem(w, pw) then
										ok = true
									end
								end
								if not ok then
									return false
								end
							end
						end
						return true
					end
					for s in (cells[5] or ""):gmatch("`([^`]+)`") do
						s = s:lower()
						if isMorph(s) or ratified then
							table.insert(forms, s)
						end
					end
					termForms[pref] = forms
					termRatified[pref] = ratified
					-- «Definido en»: el claim que INTRODUCE el término. Un
					-- término no flota en su propia definición — eso es una
					-- extensión conservativa (nombrar una configuración de
					-- términos ya presentes), no una premisa colada.
					if ratified and (cells[2] or ""):lower() == "externo" then
						termExternal[pref] = true
					end
					local def = ratified and (cells[6] or ""):match("^(D%d+)$") or nil
					if def then
						termDefinedIn[pref] = def
					end
				end
			end
		end
	end
	-- texto por nodo: axiomas (§2.1 N0) y claims (§3.0 enunciado)
	local nodeText = {}
	do
		local region, nivel = nil, nil
		for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
			local h = line:match("^#+%s+(%d[%d%.]*)")
			if h then
				region, nivel = (h:gsub("%.$", "")), nil
			end
			local nv = line:match("^#### Nivel (%d)")
			if nv then
				nivel = tonumber(nv)
			end
			if region == "2.1" and nivel == 0 then
				local id = line:match("%((C[%w′]+)%)")
				if id then
					nodeText[id] = line:lower()
				end
			elseif region == "2.1" and (nivel == 1 or nivel == 2) then
				-- claims N1/N2 por nombre: nombre + definición como texto
				if line:match("^|") and not line:match("^|%-") and not line:match("^| Principio") then
					local cells = {}
					for cell in line:gmatch("|([^|]*)") do
						table.insert(cells, (cell:gsub("^%s+", ""):gsub("%s+$", "")))
					end
					local nm = (cells[1] or ""):gsub("%s*⚠%s*$", "")
					if nm ~= "" then
						nodeText[nm] = ((cells[1] or "") .. " " .. (cells[2] or "")):lower()
					end
				end
			end
		end
	end
	for id, c in pairs(designClaims) do
		nodeText[id] = (c.enunciado or ""):lower()
	end
	-- una elección introduce el término de SU EJE (A-n): E1 sobre A1
	-- "valencia del resultado" aporta el término «valencia».
	for n, txt in pairs(entities) do
		nodeText[n] = txt:lower()
	end
	for e, row in pairs(f8ElectionRows) do
		local ax = axes[row.eje]
		if ax then
			-- la elección aporta su EJE y su VALOR: el valor es justamente lo
			-- que elige, y omitirlo dejaba flotando términos que ella funda.
			nodeText[e] = (ax.nombre .. " " .. (row.valor:gsub("`", ""))):lower()
		end
	end
	-- Coincidencia con FRONTERA DE PALABRA. La subcadena a secas daba falsos
	-- positivos reales: `entidad` casaba dentro de `identidad` y marcaba a D16.
	-- Los bytes ≥ 128 son continuación UTF-8, luego cuentan como letra.
	local function isWordByte(ch)
		return ch ~= "" and (ch:match("[%w]") ~= nil or ch:byte() >= 128)
	end
	local function containsWord(txt, form)
		local init = 1
		while true do
			local s, e = txt:find(form, init, true)
			if not s then
				return false
			end
			local before = s > 1 and txt:sub(s - 1, s - 1) or ""
			if not isWordByte(before) and not isWordByte(txt:sub(e + 1, e + 1)) then
				return true
			end
			init = s + 1
		end
	end

	local function termsIn(txt)
		local present = {}
		for term, forms in pairs(termForms) do
			for _, f in ipairs(forms) do
				if txt and containsWord(txt, f) then
					present[term] = true
					break
				end
			end
		end
		return present
	end

	print("Procedencia de términos — conclusión \\ premisas (DETECTOR, no reja)\n")
	local ids = {}
	for id in pairs(designClaims) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return tonumber(a:sub(2)) < tonumber(b:sub(2))
	end)
	local flaggedTotal = 0
	for _, id in ipairs(ids) do
		local deriv = designClaims[id].deriv
		if not deriv:match("^—") then -- salta bloqueados/empíricos
			local premStr = deriv:match("·%s*(.+)$")
			if premStr then
				premStr = (premStr:gsub(" — .*$", ""))
				local premTerms = {}
				for tok in premStr:gmatch("[^+]+") do
					tok = tok:gsub("^%s+", ""):gsub("%s+$", "")
					local ref = tok:match("^%[(.+)%]$") or tok
					local txt = nodeText[ref]
					if txt then
						for t in pairs(termsIn(txt)) do
							premTerms[t] = true
						end
					end
				end
				local concl = termsIn(nodeText[id])
				local floating = {}
				for t in pairs(concl) do
					if not premTerms[t] and termDefinedIn[t] ~= id and not termExternal[t] then
						table.insert(floating, t .. (termRatified[t] and "" or " ⚠"))
					end
				end
				table.sort(floating)
				if #floating > 0 then
					flaggedTotal += 1
					print(string.format("  %-4s %s", id, table.concat(floating, " · ")))
					-- TRIAJE MT0 (P12, DL-103): por cada término flotante, la
					-- máquina no DECIDE el cubo —eso es ontológico— sino que
					-- reúne la EVIDENCIA que lo hace obvio: dónde más vive el
					-- término. Es abducción (hallar la premisa faltante).
					--   · aparece en axiomas/claims → cítalos (extraer / cita)
					--   · en ningún nodo → candidato a PRIMITIVO (ratificación)
					--   · externo/empírico → medir (no se deriva)
					for _, ft in ipairs(floating) do
						local term = ft:gsub("%s*⚠%s*$", "")
						if termExternal[term] then
							print(string.format("         └ %s → EMPÍRICO/EXTERNO: se mide o el diseño lo excluye (no se deriva)", term))
						else
							local where = {}
							for ref, txt in pairs(nodeText) do
								if ref ~= id and (ref:match("^C") or ref:match("^D%d+$")) then
									for _, f in ipairs(termForms[term] or { term }) do
										if txt:find(f, 1, true) then
											table.insert(where, ref)
											break
										end
									end
								end
							end
							table.sort(where)
							if #where > 0 then
								print(string.format("         └ %s → REDUCIBLE: vive en %s — candidato a citar", term, table.concat(where, ", ")))
							else
								print(string.format("         └ %s → PRIMITIVO?: en ningún nodo — candidato a ratificación (como escasez→E11)", term))
							end
						end
					end
				end
			end
		end
	end
	print(string.format("\n  %d claim(s) con términos flotantes — cada uno: premisa colada O sinonimia no modelada.", flaggedTotal))

	-- AUDITORÍA DE BLOQUEOS (X9, DL-102). Un claim marcado «— bloqueado»
	-- afirma que le falta una premisa (una elección, un postulado). Pero un
	-- bloqueo es legítimo solo si NINGUNA combinación de premisas DISPONIBLES
	-- cubre su conclusión. Aquí se computa el pool completo —todos los axiomas,
	-- todos los claims, MT0 y meta-leyes— y se pregunta: ¿sus términos ya
	-- cubren la conclusión del bloqueado? Si sí, la frontera es sospechosa:
	-- las premisas existen y no se buscaron (X9 — el caso de D18). DETECTOR,
	-- no reja: cobertura léxica es necesaria, no suficiente (§2.10 ontológico).
	local poolTerms = {}
	for ref, txt in pairs(nodeText) do
		if ref:match("^C") or ref:match("^D%d+$") or ref == "MT0" or ref:match("^M%d+$") then
			for t in pairs(termsIn(txt)) do
				poolTerms[t] = true
			end
		end
	end
	local blockedAudit = 0
	for _, id in ipairs(ids) do
		if designClaims[id].deriv:match("^—%s*bloqueado") then
			local uncovered = {}
			for t in pairs(termsIn(nodeText[id])) do
				if not poolTerms[t] then
					table.insert(uncovered, t)
				end
			end
			if #uncovered == 0 then
				blockedAudit += 1
				print(string.format("\n  ⚠ X9 %s: BLOQUEADO pero el pool de premisas cubre su conclusión — la frontera puede ser búsqueda incompleta (revisar si D18/DL-080).", id))
			end
		end
	end
	if blockedAudit == 0 then
		print("\n  Auditoría de bloqueos: ningún claim bloqueado con premisas ya disponibles (X9 limpio).")
	end

	-- AUDITORÍA DEÓNTICA (X2, P15, DL-106). El salto ser→deber (Hume): una
	-- conclusión PROHIBITIVA no puede derivar solo de premisas DESCRIPTIVAS.
	-- Un claim cuyo enunciado prohíbe («prohibid…», «no puede», «no entra»,
	-- «nunca…») debe citar una premisa que CARGUE la norma: C3 (restricción),
	-- una elección (E-n), un principio §2.1, u otro claim prohibitivo. Si
	-- todas sus premisas son descriptivas (C1a/C1b/C2′, claims no
	-- prohibitivos), es el salto modal. DETECTOR (léxico, §2.10), no reja.
	local function isProhibitive(txt)
		if not txt then
			return false
		end
		return txt:find("prohibid", 1, true) ~= nil
			or txt:find("no puede", 1, true) ~= nil
			or txt:find("no entra", 1, true) ~= nil
			or txt:find("no castiga", 1, true) ~= nil
			or txt:find("nunca", 1, true) ~= nil
			or txt:find("ninguna", 1, true) ~= nil
			or txt:find("impide", 1, true) ~= nil
	end
	local deonticFlags = 0
	for _, id in ipairs(ids) do
		local c = designClaims[id]
		if isProhibitive((c.enunciado or ""):lower()) and not c.deriv:match("^—") then
			local premStr = c.deriv:match("·%s*(.+)$")
			if premStr then
				premStr = (premStr:gsub(" — .*$", ""))
				local grounded = false
				for tok in premStr:gmatch("[^+]+") do
					tok = tok:gsub("^%s+", ""):gsub("%s+$", "")
					local ref = tok:match("^%[(.+)%]$") or tok
					-- C3 (restricción), elección, principio §2.1 (claim no-D),
					-- u otro claim prohibitivo → carga la norma.
					if ref == "C3" or ref:match("^E%d+$") then
						grounded = true
					elseif ref:match("^D%d+$") then
						if isProhibitive((designClaims[ref] and designClaims[ref].enunciado or ""):lower()) then
							grounded = true
						end
					elseif f8Claims[ref] and not ref:match("^D%d+$") then
						grounded = true -- principio §2.1 (normativo por ratificación)
					end
				end
				if not grounded then
					deonticFlags += 1
					print(string.format("\n  ⚠ X2 %s: conclusión PROHIBITIVA sin premisa que cargue la norma (C3/elección/principio) — posible salto ser→deber.", id))
				end
			end
		end
	end
	if deonticFlags == 0 then
		print("\n  Auditoría deóntica: ninguna prohibición desde solo premisas descriptivas (X2 limpio).")
	end

	-- COLA DE REFINAMIENTO (DL-078). El movimiento de CEGAR: la brecha entre
	-- lo modelado y lo real dirige qué definir después. El orden es por
	-- frecuencia — el término más usado gana más cobertura al definirse, que
	-- es la heurística práctica de "preguntar lo mínimo" (attribute
	-- exploration). No es una lista de defectos: es qué mirar a continuación.
	local queue = {}
	for w, n in pairs(vocabFreq) do
		table.insert(queue, { w, n })
	end
	table.sort(queue, function(a, b)
		if a[2] ~= b[2] then
			return a[2] > b[2]
		end
		return a[1] < b[1]
	end)
	print(string.format("\n  Cola de refinamiento — %d términos sin modelar (top 15 por uso):\n", #queue))
	for i = 1, math.min(15, #queue) do
		print(string.format("    %-28s ×%d", queue[i][1], queue[i][2]))
	end
	process.exit(0)
end

if table.find(process.args, "--sensitivity") then
	-- dependientes directos: premisa → claims que la citan
	local dependents = {}
	local function addDep(prem, claim)
		dependents[prem] = dependents[prem] or {}
		table.insert(dependents[prem], claim)
	end
	for name, c in pairs(f8Claims) do
		local formal = c.raw
		local dash = formal:find(" — ", 1, true)
		if dash then
			formal = formal:sub(1, dash - 1)
		end
		local _, premStr = formal:match("^(R%-%u+)%s*·%s*(.+)$")
		if premStr then
			for tok in premStr:gmatch("[^+]+") do
				tok = tok:gsub("^%s+", ""):gsub("%s+$", "")
				local claimRef = tok:match("^%[(.+)%]$")
				if tok ~= "" then
					addDep(claimRef or tok, name)
				end
			end
		end
	end

	-- cierre transitivo: todo lo que se mueve si se toca la premisa
	local function blastRadius(root)
		local seen, stack = {}, { root }
		while #stack > 0 do
			local cur = table.remove(stack)
			for _, d in ipairs(dependents[cur] or {}) do
				if not seen[d] then
					seen[d] = true
					table.insert(stack, d)
				end
			end
		end
		local n = 0
		for _ in pairs(seen) do
			n += 1
		end
		return n
	end

	local roots = {}
	for a in pairs(f8Axioms) do
		table.insert(roots, { a, "axioma" })
	end
	for e in pairs(f8Elections) do
		table.insert(roots, { e, "elección" })
	end
	for c in pairs(f8Claims) do
		table.insert(roots, { c, "claim" })
	end
	for _, r in ipairs(roots) do
		r[3] = blastRadius(r[1])
	end
	table.sort(roots, function(x, y)
		if x[3] ~= y[3] then
			return x[3] > y[3]
		end
		return x[1] < y[1]
	end)

	print("Sensibilidad — ∂downstream/∂premisa (radio de explosión)\n")
	for _, r in ipairs(roots) do
		if r[3] > 0 or r[2] ~= "claim" then
			print(string.format("  %-28s %-9s %d", r[1], r[2], r[3]))
		end
	end
	process.exit(0)
end

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
		-- Tipo MT0 (DL-070): sin él, una zona cuyo terreno son RELACIONES —
		-- es decir, deuda que la máquina debería cubrir — se lee igual que
		-- una frontera aceptada. Z1 se trató como frontera durante días
		-- siendo deuda: la fila no decía de qué cubo era.
		local tipoOk = z.tipo == "relación → máquina (deuda)"
			or z.tipo == "formalizable pendiente"
			or z.tipo == "contenido → PO"
		if z.zona == "" or z.camino == "" or not tipoOk or not ratified or not z.vence:match("^%d%d%d%d%-%d%d%-%d%d$") then
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

-- Nombres de regla emitidos, para verificar el registro de escapes: una
-- clase de error solo puede declararse resuelta por una regla QUE EXISTA.
local emittedRules = {}

local anyReported = false

local function reportViolations(name, rows, fmt)
	emittedRules[(name:match("^(%S+)"))] = true
	if #rows > 0 then
		anyReported = true
	end
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
reportViolations("table_shape (fila con columnas != cabecera — misparse en potencia)", tableShape, function(r)
	return r
end)
reportViolations("reseal_undeclared (DL sella §3.0 sin declarar Resello:)", resealUndeclared, function(r)
	return r
end)
reportViolations("ticket_design_prose (ticket ancla en §3.x sin claim D-n)", ticketDesignProse, function(r)
	return r
end)
reportViolations("module_underived (sistema en src/ sin claim que lo requiera)", moduleUnderived, function(r)
	return r
end)
reportViolations("contract_missing (función de §4.13 ausente en src/)", contractMissing, function(r)
	return r
end)
reportViolations("vocab_malformed (fila de §2.9 con eje o ratificación fuera de forma)", vocabMalformed, function(r)
	return r
end)
reportViolations("vocab_banned_term (forma léxica prohibida en §3 — §2.9)", vocabBanned, function(r)
	return r
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
reportViolations("seal_unprovenanced (claim sin DL que declare su sellado)", sealUnprovenanced, function(r)
	return r
end)
reportViolations("seal_provenance_inconsistent (el DL sellador no declara §3.0)", sealProvenanceInconsistent, function(r)
	return r
end)
reportViolations("plan_uncovered_debt (deuda declarada que ningún paso del plan salda)", planUncoveredDebt, function(r)
	return r
end)
reportViolations("plan_dangling (paso del plan §5.11 sin estado o con dependencia inexistente)", planDangling, function(r)
	return r
end)
reportViolations("blocked_claim_dangling (claim bloqueado sin bloqueador existente)", blockedClaimDangling, function(r)
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
reportViolations("election_unratified_cited (claim que se apoya en elección sin ratificar)", electionUnratifiedCited, function(r)
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
-- ── registro de escapes (DL-070) ────────────────────────────────────────────
-- M9 verifica que toda REGLA tenga mutación. Nada verificaba lo inverso: que
-- toda CLASE DE ERROR CONOCIDA tenga regla. Por eso "premisa colada" pudo
-- aparecer siete veces sin que nada acumulara esas siete en una señal — cada
-- hallazgo se evaporaba en la prosa de un DL. Un escape es un defecto que el
-- validador NO cazó; queda registrado hasta resolverse en una regla que
-- exista o en una zona registrada. Se evalúa al final: necesita la lista de
-- reglas realmente emitidas.
local escapeMalformed, escapeUnresolved = {}, {}
do
	local ids = {}
	for id in pairs(escapes) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local x = escapes[id]
		if x.clase == "" or x.hallado == "" or x.resol == "" then
			table.insert(escapeMalformed, id .. " → clase/hallazgo/resolución vacíos")
		else
			local regla = x.resol:match("^regla: (%S+)$")
			local zona = x.resol:match("^zona: (Z%d+)$")
			-- «límite:» (DL-106) — una clase de escape que es INHERENTE, no un
			-- defecto pendiente: la ceguera del instrumento (X8), la
			-- completitud indecidible (X12), el defecto auto-consistente de
			-- Thompson (X13). No admite regla por naturaleza, y no es deuda.
			local limite = x.resol:match("^límite: (.+)$")
			if regla then
				if not emittedRules[regla] then
					table.insert(escapeUnresolved, id .. " → regla \"" .. regla .. "\" no existe")
				end
			elseif zona then
				if not zones[zona] then
					table.insert(escapeUnresolved, id .. " → zona " .. zona .. " no registrada")
				end
			elseif not limite then
				table.insert(escapeUnresolved, id .. " → resolución no es `regla: X`, `zona: Z-n` ni `límite: …`")
			end
		end
	end
end
-- NO se reporta como regla ni suma a las violaciones (corrección del PO,
-- DL-070): el registro es una HEURÍSTICA mantenida a mano. Si bloqueara el
-- build, un artefacto que yo agrupo por clase reconociendo un patrón se
-- comportaría como garantía — la deuda disfrazada de mecanismo. Se imprime
-- como historial, junto a la deuda diferida, y no gobierna nada.
reportViolations("version-pin (referencia a versión del master — prohibido)", pins, function(r)
	return r
end)

-- Churn de claims por DL (Z4, DL-073): la serie sale ahora del CORPUS, no
-- de git. Es la diferencia discreta — cuánta normatividad movió cada
-- decisión. Medición, no regla.
do
	local churn, dls = {}, {}
	for _, c in pairs(designClaims) do
		if c.selladoPor ~= "" then
			if not churn[c.selladoPor] then
				churn[c.selladoPor] = 0
				table.insert(dls, c.selladoPor)
			end
			churn[c.selladoPor] += 1
		end
	end
	table.sort(dls)
	local parts = {}
	for _, d in ipairs(dls) do
		table.insert(parts, d .. ":" .. churn[d])
	end
	print("\n  · churn de claims por DL: " .. table.concat(parts, "  "))
end

do
	local total = vocabCovered + vocabUncovered
	local pct = total > 0 and math.floor(vocabCovered / total * 100) or 0
	print(
		string.format(
			"\n  · cobertura del vocabulario: %d%% (%d/%d términos de claims modelados) — %d sin modelar",
			pct,
			vocabCovered,
			total,
			vocabUncovered
		)
	)
	print("      Fuera de esos términos el detector de procedencia es CIEGO: su 0 no prueba nada ahí.")
end

do
	local ids = {}
	for id in pairs(planSteps) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return tonumber(a:sub(2)) < tonumber(b:sub(2))
	end)
	local frente = {}
	for _, id in ipairs(ids) do
		local s = planSteps[id]
		if not planClosed(s.estado) then
			local ready = true
			for _, d in ipairs(s.deps) do
				if planSteps[d] and not planClosed(planSteps[d].estado) then
					ready = false
				end
			end
			if ready then
				table.insert(frente, id .. " (" .. s.estado .. ")")
			end
		end
	end
	if #frente > 0 then
		print("\n  · frente accionable del plan (§5.11): " .. table.concat(frente, "  "))
		print("      Computado de las dependencias declaradas. El plan es memoria, no cobertura: no gobierna.")
	end
end

print(
	string.format(
		"\n  · VARIANTE del corpus: %d  (zonas abiertas %d + claims bloqueados %d + clases sin regla %d)",
		variantZones + variantBlocked + variantEscapes,
		variantZones,
		variantBlocked,
		variantEscapes
	)
)
print("      Event-B: safety son invariantes, convergencia es una variante que decrece.")
print("      Se MIDE, no se gobierna: descubrir deuda la sube, y eso es progreso.")

do
	local n, mal = 0, #escapeMalformed + #escapeUnresolved
	for _ in pairs(escapes) do
		n += 1
	end
	if n > 0 then
		print(string.format("\n  · escapes registrados: %d — HISTORIAL, no cobertura. No gobierna nada.", n))
		if mal > 0 then
			print(string.format("      (%d fila(s) mal formadas — higiene del historial, sin efecto)", mal))
		end
	end
end

if #deferred > 0 then
	print(string.format("\n  · deuda diferida vigente: %d — autorizada y acotada en deferrals.txt", #deferred))
	table.sort(deferred, function(a, b)
		return a[1] .. a[2] < b[1] .. b[2]
	end)
	for _, d in ipairs(deferred) do
		print("      " .. d[1] .. " ↛ " .. d[2])
	end
end

-- ── asimetría de enforcement (§5.12, DL-087) ────────────────────────────────
-- El conjunto declarado y el emitido deben coincidir. Borrar una regla exige
-- borrar su fila del registro: acto normativo en docs/, no diff de código.
-- El agente puede APRETAR (declarar + emitir una regla nueva) pero no AFLOJAR
-- sin que la eliminación quede como cambio constitucional visible.
local ruleMissing, ruleUndeclared = {}, {}
do
	-- Estas dos se registran a mano: se comprueban ANTES de reportarse, luego
	-- se auto-eximirían. Un guardián exento de su propia guardia no guarda.
	emittedRules["rule_missing"] = true
	emittedRules["rule_undeclared"] = true
	local declared = {}
	local region, inBlock = nil, false
	for _, line in ipairs(readLines("docs/AI_CONTEXT_MASTER.md")) do
		local h = line:match("^#+%s+(%d[%d%.]*)")
		if h then
			region, inBlock = (h:gsub("%.$", "")), false
		end
		if region == "5.12" then
			if line:match("^```") then
				inBlock = not inBlock
			elseif inBlock then
				for r in line:gmatch("[^·%s][^·]*") do
					r = r:gsub("^%s+", ""):gsub("%s+$", "")
					if r ~= "" then
						declared[r] = true
					end
				end
			end
		end
	end
	for r in pairs(declared) do
		if not emittedRules[r] and not emittedRules[(r:match("^(%S+)"))] then
			table.insert(ruleMissing, r .. " → declarada en §5.12, no emitida por el runner")
		end
	end
	for r in pairs(emittedRules) do
		local ok = declared[r]
		if not ok then
			for d in pairs(declared) do
				if d:match("^" .. r:gsub("%-", "%%-")) then
					ok = true
				end
			end
		end
		if not ok then
			table.insert(ruleUndeclared, r .. " → emitida, no declarada en §5.12")
		end
	end
	table.sort(ruleMissing)
	table.sort(ruleUndeclared)
end
reportViolations("rule_missing (regla declarada en §5.12 que el runner no emite)", ruleMissing, function(r)
	return r
end)
reportViolations("rule_undeclared (regla emitida sin declarar en §5.12)", ruleUndeclared, function(r)
	return r
end)

local violations = #dangling + #orphan + #newStale + #expired + #uncovered + #pins
	+ #ruleMissing + #ruleUndeclared
	+ #levelSkip + #domainMismatch + #implLeak + #undeclaredFree
	+ #moduleUndeclared + #ungluedClaim + #glueDangling + #unclaimedSection
	+ #f8BadDeriv + #f8UnknownRule + #f8UnknownPremise + #f8Arity + #f8Cycle
	+ #electionMalformed + #electionAxisDup + #electionCompound + #metaLawMalformed
	+ #axisMalformed + #axisDomainThin + #electionAxisUnregistered + #electionValueOffAxis
	+ #electionUnratifiedCited + #blockedClaimDangling
	+ #sealUnprovenanced + #sealProvenanceInconsistent + #vocabBanned + #planDangling + #planUncoveredDebt + #vocabMalformed + #contractMissing + #tableShape + #moduleUnderived + #ticketDesignProse + #resealUndeclared
	+ #zoneMalformed + #zoneExpired + #claimSealMismatch
if violations > 0 then
	print(string.format("\n%d violación(es) — el grafo de derivación NO está íntegro.", violations))
	process.exit(1)
else
	print("\nSin violaciones. Grafo consistente al nivel actual.")
end
