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
		name = "unglued_section",
		expect = "✗ unglued_section",
		apply = function()
			replaceOnce(
				MASTER,
				"| §3.2 | Densidad de Interacción | — empírico → playtest (métrica de avance, §3.2) |",
				""
			)
		end,
	},
	{
		name = "glue_dangling",
		expect = "✗ glue_dangling",
		apply = function()
			replaceOnce(
				MASTER,
				"| §3.1 | Ciclo de ronda (core loop) | `GameManager` (estados Lobby/Summary)",
				"| §3.1 | Ciclo de ronda (core loop) | `ModuloFantasma` (estados Lobby/Summary)"
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
}

-- ── runner ──────────────────────────────────────────────────────────────────
local exec = (process :: any).exec or (process :: any).spawn

local function runCheck()
	local r = exec("lune", { "run", "tools/derivation-graph/check.luau" }, { cwd = SANDBOX })
	return r.code, (r.stdout or "") .. (r.stderr or "")
end

print("Mutation tests del validador — corpus real + 13 violaciones inyectadas\n")

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
rmrf(SANDBOX)

if failures > 0 then
	print(string.format("\n%d regla(s) NO encendieron ante su violación — validador NO confiable.", failures))
	process.exit(1)
else
	print("\n14/14 — todas las reglas encienden ante su clase de violación. Validador verificado contra el corpus real.")
end
