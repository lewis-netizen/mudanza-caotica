-- tools/derivation-graph/test.luau
-- Mutation tests del validador (DL-056): cada regla debe ENCENDER ante una
-- violación mínima de su clase, inyectada sobre una COPIA del corpus real
-- del proyecto (+ control: el corpus sin mutar pasa). Un validador que nunca
-- ha fallado es indistinguible de uno roto — esto los distingue.
--   lune run tools/derivation-graph/test.luau

local fs = require("@lune/fs")
local process = require("@lune/process")

local SANDBOX = ".dgtest-sandbox"

local LOG = "docs/PROJECT_DECISION_LOG.md"
local MASTER = "docs/AI_CONTEXT_MASTER.md"
local TICKETS = "docs/TICKETS.md"
local DEFER = "tools/derivation-graph/deferrals.txt"

local function rmrf(path)
	if fs.isDir(path) then
		fs.removeDir(path)
	elseif fs.isFile(path) then
		fs.removeFile(path)
	end
end

local function freshSandbox()
	rmrf(SANDBOX)
	fs.writeDir(SANDBOX)
	fs.copy("docs", SANDBOX .. "/docs")
	fs.copy("src", SANDBOX .. "/src")
	fs.writeDir(SANDBOX .. "/tools")
	fs.copy("tools/derivation-graph", SANDBOX .. "/tools/derivation-graph")
end

local function read(rel)
	return fs.readFile(SANDBOX .. "/" .. rel)
end

local function write(rel, content)
	fs.writeFile(SANDBOX .. "/" .. rel, content)
end

local function append(rel, extra)
	write(rel, read(rel) .. extra)
end

-- reemplazo literal (sin patrones); falla si el ancla no existe — un ancla
-- muerta significa que la mutación ya no prueba nada.
local function replaceOnce(rel, from, to)
	local c = read(rel)
	local i = c:find(from, 1, true)
	assert(i, "ancla de mutación no encontrada en " .. rel .. ": " .. from)
	write(rel, c:sub(1, i - 1) .. to .. c:sub(i + #from))
end

local function dlBlock(id, fields)
	return "\n### DL-" .. id .. "\n\n```\nID:          DL-" .. id .. "\n" .. fields .. "\n```\n"
end

-- ── casos: 1 control + 13 mutaciones (una por regla) ────────────────────────
local cases = {
	{ name = "control — el corpus real pasa", expect = nil, apply = function() end },
	{
		name = "dangling",
		expect = "✗ dangling",
		apply = function()
			append(LOG, dlBlock("097", "Referencias: §9.9"))
		end,
	},
	{
		name = "orphan",
		expect = "✗ orphan",
		apply = function()
			append(TICKETS, "\n### ZZZ-001 — Fantasma sin fuente\n\n```\nDomain:      TECH\n```\n")
		end,
	},
	{
		name = "stale NUEVO",
		expect = "✗ stale NUEVO",
		apply = function()
			append(LOG, dlBlock("096", "Ticket:      GAM-001"))
		end,
	},
	{
		name = "diferimiento VENCIDO",
		expect = "✗ diferimiento VENCIDO",
		apply = function()
			replaceOnce(DEFER, "GAM-005 DL-046 DL-046 2026-08-11", "GAM-005 DL-046 DL-046 2026-01-01")
		end,
	},
	{
		name = "uncovered",
		expect = "✗ uncovered",
		apply = function()
			append(LOG, dlBlock("095", "Modifica:    §4.4\nLibre:       —\nReferencias: §4.4"))
		end,
	},
	{
		name = "level_skip",
		expect = "✗ level_skip",
		apply = function()
			append(
				TICKETS,
				"\n### ZZY-001 — Salto de nivel\n\n```\nDeriva de:   Principio §2.1 (Prueba) + Hito §5.7 Semana 1\nDomain:      TECH\n```\n"
			)
		end,
	},
	{
		name = "domain_mismatch",
		expect = "✗ domain_mismatch",
		apply = function()
			append(
				LOG,
				dlBlock("094", "Domain:      TECH\nTicket:      GAM-001\nModifica:    §3.1\nLibre:       —\nReferencias: §3.1")
			)
		end,
	},
	{
		name = "impl_leak",
		expect = "✗ impl_leak",
		apply = function()
			replaceOnce(
				MASTER,
				"### 3.2 Densidad de Interacción (DI)",
				"### 3.2 Densidad de Interacción (DI)\n\nPrueba de fuga: CarryManager mencionado en el piso de diseño."
			)
		end,
	},
	{
		name = "undeclared_free",
		expect = "✗ undeclared_free",
		apply = function()
			append(LOG, dlBlock("093", "Modifica:    §5.0\nReferencias: §5.0"))
		end,
	},
	{
		name = "module_undeclared",
		expect = "✗ module_undeclared",
		apply = function()
			write("src/server/FantasmaManager.lua", "return {}\n")
		end,
	},
	{
		name = "unglued_claim",
		expect = "✗ unglued_claim",
		apply = function()
			-- claim normativo sin realización declarada: obligación pendiente
			-- que quedaría invisible si el gluing no exigiera totalidad.
			replaceOnce(MASTER, "\n| D2 | Densidad de interacción | — empírico → playtest (métrica de avance, §3.2) |", "")
		end,
	},
	{
		name = "glue_dangling",
		expect = "✗ glue_dangling",
		apply = function()
			replaceOnce(
				MASTER,
				"| D1 | Coordinación decisional bajo escasez | `GameManager`",
				"| D1 | Coordinación decisional bajo escasez | `ModuloFantasma`"
			)
		end,
	},
	{
		name = "version-pin",
		expect = "✗ version-pin",
		apply = function()
			append("docs/SCRATCHPAD.md", "\nRef de prueba: AI_CONTEXT_MASTER v9.9\n")
		end,
	},
	{
		name = "claim_bad_derivation",
		expect = "✗ claim_bad_derivation",
		apply = function()
			replaceOnce(
				MASTER,
				"R-COMP · C1a + C1b — operador de dirección de la tensión",
				"C1a + C1b — operador de dirección de la tensión"
			)
		end,
	},
	{
		name = "unknown_rule",
		expect = "✗ unknown_rule",
		apply = function()
			replaceOnce(MASTER, "R-ELEC · C1b + E1", "R-FANTASMA · C1b + E1")
		end,
	},
	{
		name = "unknown_premise",
		expect = "✗ unknown_premise",
		apply = function()
			replaceOnce(MASTER, "R-COMP · C2′ + [Simplicidad Mecánica]", "R-COMP · C2′ + [Claim Inexistente]")
		end,
	},
	{
		name = "rule_arity",
		expect = "✗ rule_arity",
		apply = function()
			replaceOnce(MASTER, "R-ESP · C1a — gate de complejidad", "R-ESP · C1a + C1b — gate de complejidad")
		end,
	},
	{
		name = "claim_cycle",
		expect = "✗ claim_cycle",
		apply = function()
			-- Entropía Social ← [Contexto Variable]; se muta Contexto Variable
			-- para que derive de [Entropía Social] → ciclo.
			replaceOnce(MASTER, "| R-ELEC · C2′ + E2 |", "| R-COMP · C2′ + [Entropía Social] |")
		end,
	},
	{
		name = "elección sin axioma portador (solo E-n)",
		expect = "✗ rule_arity",
		apply = function()
			-- Garantía estructural (DL-058): ninguna conclusión deriva SOLO de
			-- elecciones — toda derivación exige un axioma/claim portador.
			replaceOnce(MASTER, "R-ELEC · C1b + E1", "R-ELEC · E1 + E2")
		end,
	},
	{
		name = "election_malformed",
		expect = "✗ election_malformed",
		apply = function()
			replaceOnce(MASTER, "| E2 | Ancla interpretable |", "| E2 | |")
		end,
	},
	{
		name = "election_axis_dup",
		expect = "✗ election_axis_dup",
		apply = function()
			replaceOnce(MASTER, "| E3 | Tratamiento de la derrota |", "| E3 | Ancla interpretable |")
		end,
	},
	{
		name = "election_compound (el defecto histórico de E1)",
		expect = "✗ election_compound",
		apply = function()
			-- Reconstruye exactamente la doble argumentación que el PO cazó a
			-- mano en E1 — ahora la caza la máquina.
			replaceOnce(
				MASTER,
				"| Cooperativa: el resultado es de equipo (§1.2) |",
				"| Cooperativa: el resultado es de equipo (§1.2) — sin condición de derrota |"
			)
		end,
	},
	{
		name = "meta_law_malformed",
		expect = "✗ meta_law_malformed",
		apply = function()
			replaceOnce(MASTER, "| DL-050 |", "| DL-999 |")
		end,
	},
	{
		name = "meta-ley con premisa inexistente (claims F8 cubren §2.8)",
		expect = "✗ unknown_premise",
		apply = function()
			-- Prueba que las derivaciones de §2.8 pasan por las reglas F8
			-- (no parsing vacuo): M3 citando una premisa que no existe.
			replaceOnce(
				MASTER,
				"R-ESP · [MT0] — restricción del titular PO al caso 1",
				"R-ESP · [MT9] — restricción del titular PO al caso 1"
			)
		end,
	},
	{
		name = "zone_malformed",
		expect = "✗ zone_malformed",
		apply = function()
			replaceOnce(MASTER, "| Ejes como tipos con dominio de valores enumerado |", "| |")
		end,
	},
	{
		name = "zone_expired",
		expect = "✗ zone_expired",
		apply = function()
			replaceOnce(
				MASTER,
				"no su posición— cambia | 2026-08-11 |",
				"no su posición— cambia | 2026-01-01 |"
			)
		end,
	},
	{
		name = "unclaimed_section",
		expect = "✗ unclaimed_section",
		apply = function()
			-- Sección de diseño que funda desde prosa, sin claim normativo.
			replaceOnce(MASTER, "| D10 | §3.4 |", "| D10 | §3.99 |")
		end,
	},
	{
		name = "claim de diseño con premisa inexistente",
		expect = "✗ unknown_premise",
		apply = function()
			replaceOnce(MASTER, "R-COMP · [D3] + [D4]", "R-COMP · [D3] + [D99]")
		end,
	},
}

-- ── runner ──────────────────────────────────────────────────────────────────
local exec = (process :: any).exec or (process :: any).spawn

local function runCheck()
	local r = exec("lune", { "run", "tools/derivation-graph/check.luau" }, { cwd = SANDBOX })
	return r.code, (r.stdout or "") .. (r.stderr or "")
end

print(string.format("Mutation tests del validador — corpus real + %d violaciones inyectadas\n", #cases - 1))

local failures = 0
for _, case in ipairs(cases) do
	freshSandbox()
	case.apply()
	local code, out = runCheck()
	local ok
	if case.expect == nil then
		ok = (code == 0)
	else
		ok = (code ~= 0) and out:find(case.expect, 1, true) ~= nil
	end
	if ok then
		print("  ✓ " .. case.name)
	else
		failures += 1
		print("  ✗ " .. case.name .. " — NO DETECTADO (exit=" .. tostring(code) .. ")")
		print("      " .. (out:gsub("\n", "\n      ")))
	end
end
-- M9 mecanizada (DL-060): AUTO-COBERTURA — toda regla que el validador
-- reporta debe tener un caso de mutación en esta suite. Verificado por
-- máquina, no por disciplina: añadir una regla sin mutación falla aquí.
freshSandbox()
local _, pristineOut = runCheck()
local uncovered = {}
for ruleName in pristineOut:gmatch("\n  ✓ ([^\n:]+):") do
	local key = ruleName:match("^([%w_%-]+)")
	if key then
		local covered = false
		for _, case in ipairs(cases) do
			if case.expect and case.expect:find(key, 1, true) then
				covered = true
				break
			end
		end
		if not covered then
			table.insert(uncovered, ruleName)
		end
	end
end
if #uncovered > 0 then
	failures += #uncovered
	for _, r in ipairs(uncovered) do
		print("  ✗ regla sin mutation test (M9): " .. r)
	end
else
	print("  ✓ auto-cobertura M9: toda regla del validador tiene su mutación")
end
rmrf(SANDBOX)

if failures > 0 then
	print(string.format("\n%d regla(s) NO encendieron ante su violación — validador NO confiable.", failures))
	process.exit(1)
else
	print(
		string.format(
			"\n%d/%d — todas las reglas encienden ante su clase de violación. Validador verificado contra el corpus real.",
			#cases,
			#cases
		)
	)
end
