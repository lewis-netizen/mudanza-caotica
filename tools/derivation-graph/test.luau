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
local CHECK = "tools/derivation-graph/check.luau"

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
		-- LÍNEA BASE DEL DETECTOR. Fija su veredicto sobre el corpus real: si
		-- un cambio del aparato altera cómo casa términos —como la coincidencia
		-- por subcadena que marcaba a D16 (X10)— el conteo se mueve y esto
		-- falla. Cambiar el veredicto del detector pasa a ser un acto declarado
		-- (se actualiza esta cifra en el diff), no un efecto colateral.
		name = "línea base de --provenance (veredicto pinneado)",
		mode = "--provenance",
		expect = "5 claim(s) con términos flotantes",
		expectPass = true,
		apply = function() end,
	},
	{
		-- MUTACIÓN DEL APARATO, no del corpus. Las dos reglas guardianas se
		-- comprueban antes de reportarse: sin su pre-registro se auto-eximen y
		-- un guardián exento de su propia guardia no guarda (DL-087). Quitarlo
		-- debe encender rule_missing — declaradas en §5.12 y no emitidas.
		name = "guardián auto-eximido (regresión de DL-087)",
		expect = "✗ rule_missing",
		apply = function()
			replaceOnce(CHECK, '\temittedRules["rule_missing"] = true\n', "")
		end,
	},
	{
		-- Línea base de --seals: el sello es la identidad del enunciado. Si el
		-- hash cambiara sin que cambie el texto, todo el mecanismo de DL-063
		-- mentiría en silencio.
		name = "línea base de --seals",
		mode = "--seals",
		expect = "D1   a6ec39",
		expectPass = true,
		apply = function() end,
	},
	{
		-- Línea base de --sensitivity: el radio de explosión de C1b. Mide qué
		-- sostiene el axioma; un cambio silencioso en el cierre transitivo lo
		-- falsearía sin que nada más lo note.
		name = "línea base de --sensitivity",
		mode = "--sensitivity",
		expect = "axioma    14",
		expectPass = true,
		apply = function() end,
	},
	{
		-- El detector RESPONDE: un término en la conclusión que ninguna premisa
		-- aporta debe flotar. Sin este caso, un detector que nunca marca nada
		-- pasaría la línea base por estar roto.
		name = "--provenance responde a un término sin premisa",
		mode = "--provenance",
		expect = "6 claim(s) con términos flotantes",
		expectPass = true,
		apply = function()
			replaceOnce(
				MASTER,
				"El reto del loop vive en la decisión compartida, no en la ejecución individual.",
				"El reto del loop vive en la decisión compartida y en la sincronía, no en la ejecución individual."
			)
		end,
	},
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
			append(LOG, dlBlock("099", "Modifica:    §5.0\nReferencias: §5.0"))
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
			replaceOnce(MASTER, "\n| D22 | Calidad del loop = frecuencia | — empírico → playtest (métrica de avance, §3.2; medida con el criterio de D2) |", "")
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
			replaceOnce(MASTER, "| E2 | A2 | `el objetivo` |", "| E2 | A2 | |")
		end,
	},
	{
		name = "election_axis_dup",
		expect = "✗ election_axis_dup",
		apply = function()
			replaceOnce(MASTER, "| E3 | A3 |", "| E3 | A2 |")
		end,
	},
	{
		name = "election_compound (el defecto histórico de E1)",
		expect = "✗ election_compound",
		apply = function()
			-- Reconstruye exactamente la doble argumentación que el PO cazó a
			-- mano en E1 — ahora la caza la máquina.
			replaceOnce(MASTER, "| E1 | A1 | `cooperativa` |", "| E1 | A1 | `cooperativa` — sin condición de derrota |")
		end,
	},
	{
		name = "axis_malformed",
		expect = "✗ axis_malformed",
		apply = function()
			replaceOnce(MASTER, "| cerrado |\n| A2 |", "| quizás |\n| A2 |")
		end,
	},
	{
		-- Un eje con un solo valor no es una elección: es una consecuencia
		-- disfrazada de elección. Sin esta regla, "elegí X" pasaría aunque X
		-- fuera lo único posible — y el registro mentiría sobre qué es libre.
		name = "axis_domain_thin (eje de un solo valor)",
		expect = "✗ axis_domain_thin",
		apply = function()
			replaceOnce(MASTER, "`ausente` · `declarada sin castigo` · `castigada`", "`ausente`")
		end,
	},
	{
		-- Registrar el valor vigente de un eje es DESCRIBIRLO; citarlo como
		-- premisa es APOYARSE en él. Sin esta regla, registrar una elección
		-- sin ratificar la volvería fundante de facto.
		name = "election_unratified_cited",
		expect = "✗ election_unratified_cited",
		apply = function()
			replaceOnce(MASTER, "| R-ELEC · [D3] + E1 |", "| R-ELEC · [D3] + E4 |")
		end,
	},
	{
		name = "election_axis_unregistered",
		expect = "✗ election_axis_unregistered",
		apply = function()
			replaceOnce(MASTER, "| E1 | A1 |", "| E1 | A99 |")
		end,
	},
	{
		-- El defecto que Z2 nombraba: un valor que no pertenece a su eje.
		-- Antes era indetectable porque el eje era texto libre.
		name = "election_value_off_axis (el defecto que Z2 describía)",
		expect = "✗ election_value_off_axis",
		apply = function()
			replaceOnce(MASTER, "| E1 | A1 | `cooperativa` |", "| E1 | A1 | `el objetivo` |")
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
		-- Sin Tipo MT0 una zona de DEUDA se lee como frontera aceptada:
		-- es lo que pasó con Z1 durante días.
		name = "zone_malformed (zona sin Tipo MT0)",
		expect = "✗ zone_malformed",
		apply = function()
			replaceOnce(MASTER, "| formalizable pendiente |", "| |")
		end,
	},
	{
		name = "zone_malformed",
		expect = "✗ zone_malformed",
		apply = function()
			replaceOnce(MASTER, "| Descomposición (M5) + catálogo más fino; contradicciones como relación explícita |", "| |")
		end,
	},
	{
		name = "zona sin ratificar (frontera auto-concedida)",
		expect = "✗ zone_malformed",
		apply = function()
			replaceOnce(MASTER, "| 2026-08-11 | PO 2026-07-22 |", "| 2026-08-11 | |")
		end,
	},
	{
		name = "zone_expired",
		expect = "✗ zone_expired",
		apply = function()
			replaceOnce(
				MASTER,
				"derivar la obligación del cambio | 2026-08-11 |",
				"derivar la obligación del cambio | 2026-01-01 |"
			)
		end,
	},
	{
		-- Una deuda sin acreedor no se cobra: D18 decía "exige un postulado"
		-- sin nombrar ningún ID, y nada lo detectaba.
		-- Regresión exacta de X4: reintroduce la colisión de vocabulario que
		-- se corrigió a mano en DL-068. Ahora la caza la máquina.
		-- La inversa del gluing: un sistema nuevo en src/server/ que ningún
		-- claim requiere es herencia no derivada. Es la preocupación del
		-- inicio de sesión, ahora imposible de reintroducir en silencio.
		name = "module_underived (sistema sin claim que lo pida)",
		expect = "✗ module_underived",
		apply = function()
			write("src/server/OverlordManager.lua", "return {}\n")
		end,
	},
	{
		-- El misparse silencioso, cazado en forma general: una fila con más
		-- columnas que su cabecera. Así se colaron X10 y las dos derivas de
		-- §2.9. Un | sin escapar dentro de una celda lo dispara.
		name = "table_shape (columna corrida en cualquier tabla)",
		expect = "✗ table_shape",
		apply = function()
			replaceOnce(MASTER, "| Contrato | Invariante | Mecanismo |", "| Contrato | Invariante | Mecanismo | X |")
		end,
	},
	{
		-- El primer chequeo que cruza de documento a código: la deriva
		-- declaración↔implementación (X5) deja de poder reintroducirse.
		name = "contract_missing (función declarada y ausente)",
		expect = "✗ contract_missing",
		apply = function()
			replaceOnce("src/shared/Rules/CarryRules.lua", "function CarryRules.carryEfficiency", "function CarryRules.carryEficiencia")
		end,
	},
	{
		name = "vocab_malformed (celda corrida en §2.9)",
		expect = "✗ vocab_malformed",
		apply = function()
			replaceOnce(MASTER, "| interacción | predicado |", "| interacción | predicado | extra |")
		end,
	},
	{
		name = "vocab_banned_term (regresión de X4)",
		expect = "✗ vocab_banned_term",
		apply = function()
			replaceOnce(MASTER, "El espacio acopla por interferencia: rival y pervasivo.", "El espacio acopla por interferencia: acoplamiento negativo y pervasivo.")
		end,
	},
	{
		name = "seal_unprovenanced",
		expect = "✗ seal_unprovenanced",
		apply = function()
			replaceOnce(MASTER, "| 67816b | DL-093 |", "| 67816b | |")
		end,
	},
	{
		-- La procedencia se verifica SIN historia: el DL nombrado debe
		-- declarar §3.0 en su Modifica. Un DL que nunca tocó los claims no
		-- pudo sellarlos — una procedencia que miente se cae sola.
		name = "seal_provenance_inconsistent (procedencia que miente)",
		expect = "✗ seal_provenance_inconsistent",
		apply = function()
			replaceOnce(MASTER, "| 67816b | DL-093 |", "| 67816b | DL-050 |")
		end,
	},
	{
		-- Un plan cuyo paso depende de algo inexistente no ordena nada: es la
		-- forma en que un plan vuelve a ser prosa sin avisar.
		-- La única completitud que el plan admite probar: que ninguna deuda
		-- YA DECLARADA quede sin paso. Frente a deuda no declarada sigue
		-- ciego — eso es X8 y no se cierra con filas.
		-- La asimetría en acción: borrar una regla del runner sin borrar su
		-- declaración = el aflojamiento silencioso que §5.12 impide.
		-- La otra mitad: emitir una regla sin declararla deja el registro
		-- desincronizado, y un registro que no refleja el runner no guarda nada.
		name = "rule_undeclared",
		expect = "✗ rule_undeclared",
		apply = function()
			replaceOnce(MASTER, "blocked_claim_dangling · vocab_banned_term", "blocked_claim_dangling")
		end,
	},
	{
		name = "rule_missing (aflojar el aparato en silencio)",
		expect = "✗ rule_missing",
		apply = function()
			replaceOnce(MASTER, "blocked_claim_dangling · vocab_banned_term", "blocked_claim_dangling · vocab_banned_term · regla_fantasma")
		end,
	},
	{
		name = "plan_uncovered_debt",
		expect = "✗ plan_uncovered_debt",
		apply = function()
			replaceOnce(MASTER, "el delta del enunciado, no solo su hash y su autor | — | Z4 |", "el delta del enunciado, no solo su hash y su autor | — | — |")
		end,
	},
	{
		name = "plan_dangling",
		expect = "✗ plan_dangling",
		apply = function()
			replaceOnce(MASTER, "| P8 | Derivar el conjunto de sistemas de §4 en una pasada holística | P3 · P5 |", "| P8 | Derivar el conjunto de sistemas de §4 en una pasada holística | P3 · P99 |")
		end,
	},
	{
		name = "blocked_claim_dangling (deuda que no apunta a nada)",
		expect = "✗ blocked_claim_dangling",
		apply = function()
			replaceOnce(MASTER, "| — empírico → playtest | ac7a1f |", "| — bloqueado: pendiente de decidir | ac7a1f |")
		end,
	},
	{
		name = "claim_seal_mismatch (remodelar sin declarar)",
		expect = "✗ claim_seal_mismatch",
		apply = function()
			-- invierte el compromiso de D14 dejando el sello viejo: es la
			-- remodelación silenciosa que Z4 existe para hacer visible.
			replaceOnce(MASTER, "| D14 | §3.5 | El juego no castiga el fallo. |", "| D14 | §3.5 | El juego castiga el fallo. |")
		end,
	},
	{
		-- CONTROL de Z4: reubicar NO es remodelar. Cambiar la sección de un
		-- claim no toca su enunciado, luego el sello sigue válido y el corpus
		-- pasa limpio. Si esto encendiera claim_seal_mismatch, el sello
		-- estaría sellando la FILA en vez del COMPROMISO — el defecto que Z4
		-- describe, invertido. Sin este caso, un sello sobre la fila entera
		-- pasaría los tests igual y Z4 quedaría cerrada en falso.
		name = "control Z4 — reubicar un claim NO enciende el sello",
		expect = nil,
		reject = "✗ claim_seal_mismatch",
		apply = function()
			replaceOnce(MASTER, "| D19 | §3.7 |", "| D19 | §3.2 |")
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

-- Los MODOS (--provenance, --sensitivity, --seals) no tenían ninguna
-- cobertura: M9 solo alcanza las reglas del reporte por defecto. Los tres
-- defectos de aparato de esta sesión vivían ahí, en código que ningún test
-- tocaba, y los halló un agente leyendo salida — la dependencia que el
-- proyecto existe para eliminar (DL-088).
local function runCheck(mode)
	local args = { "run", "tools/derivation-graph/check.luau" }
	if mode then
		table.insert(args, mode)
	end
	local r = exec("lune", args, { cwd = SANDBOX })
	return r.code, (r.stdout or "") .. (r.stderr or "")
end

print(string.format("Mutation tests del validador — corpus real + %d violaciones inyectadas\n", #cases - 1))

local failures = 0
for _, case in ipairs(cases) do
	freshSandbox()
	case.apply()
	local code, out = runCheck(case.mode)
	local ok
	if case.expect == nil then
		ok = (code == 0)
	elseif case.expectPass then
		-- los MODOS salen con 0: se juzga su salida, no su código.
		ok = out:find(case.expect, 1, true) ~= nil
	else
		ok = (code ~= 0) and out:find(case.expect, 1, true) ~= nil
	end
	-- `reject`: la regla NO debe encender. Una regla que enciende de más es
	-- tan inútil como una que no enciende — bloquea trabajo legítimo y
	-- entrena a ignorarla.
	if ok and case.reject then
		ok = out:find(case.reject, 1, true) == nil
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
