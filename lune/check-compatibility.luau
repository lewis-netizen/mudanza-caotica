-- lune/check-compatibility.luau
-- Fase 1: verificar qué módulos pueden requerirse sin DataModel de Roblox.
--
-- Invariante:
--   Un módulo es compatible con Lune si puede ser requerido sin DataModel
--   Roblox sin producir errores durante la evaluación de nivel de módulo.
--
-- Uso (desde la raíz del proyecto):
--   lune run lune/check-compatibility.luau

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

-- ─── Configuración ────────────────────────────────────────────────────────────

local TARGETS = {
	"src/shared",
	"src/server",
	"src/client",
}

local EXCLUDE_PATTERNS = {
	"%.spec%.lua$",
	"%.spec%.luau$",
}

-- ─── Utilidades ───────────────────────────────────────────────────────────────

local function shouldExclude(path: string): boolean
	for _, pattern in EXCLUDE_PATTERNS do
		if path:match(pattern) then
			return true
		end
	end
	return false
end

local function collectLuaFiles(dir: string): { string }
	local files = {}
	if not fs.isDir(dir) then
		return files
	end
	for _, entry in fs.readDir(dir) do
		local fullPath = dir .. "/" .. entry
		if fs.isDir(fullPath) then
			for _, nested in collectLuaFiles(fullPath) do
				table.insert(files, nested)
			end
		elseif entry:match("%.lua$") or entry:match("%.luau$") then
			if not shouldExclude(fullPath) then
				table.insert(files, fullPath)
			end
		end
	end
	return files
end

-- ─── Verificación ─────────────────────────────────────────────────────────────
-- En lugar de require(), leemos el contenido del archivo y buscamos
-- accesos a globals de Roblox en el scope de módulo.
--
-- Un módulo es incompatible si tiene en el nivel superior del archivo
-- (fuera de cualquier función) expresiones como:
--   local X = game:GetService(...)
--   local X = workspace
--   local X = Players
--   local X = script.Parent
--
-- Esta verificación es estática (sin ejecutar el código) y por tanto
-- no tiene problemas de paths de require. Es equivalente en resultado
-- a intentar el require() porque el error siempre ocurre en esas líneas.

local ROBLOX_GLOBAL_PATTERNS = {
	-- game:GetService() en scope de módulo
	"^local%s+%w+%s*=%s*game:GetService",
	-- workspace en scope de módulo
	"^local%s+%w+%s*=%s*workspace",
	-- Players en scope de módulo
	"^local%s+%w+%s*=%s*Players",
	-- script.Parent en scope de módulo
	"^local%s+%w+%s*=%s*script%.",
	-- game. directamente en scope de módulo
	"^local%s+%w+%s*=%s*game%.",
}

local passed = {}
local failed = {}

local function checkModule(path: string)
	local content = fs.readFile(path)
	local lineNumber = 0
	local violations = {}
	local blockDepth = 0

	-- Keywords que abren un bloque (incrementan profundidad)
	local OPENERS = { "function", "if", "for", "while", "do" }
	-- "end" cierra cualquiera de los anteriores (decrementa profundidad)
	-- "then" y "do" de control de flujo no cuentan aparte —
	-- ya están cubiertos por if/for/while abriendo el bloque

	for line in content:gmatch("[^\n]+") do
		lineNumber += 1
		local trimmed = line:match("^%s*(.-)%s*$")

		-- Ignorar comentarios de línea completos para el conteo de bloques
		local codepart = trimmed
		local commentStart = trimmed:find("%-%-")
		if commentStart then
			codepart = trimmed:sub(1, commentStart - 1)
		end

		-- Contar aperturas de bloque en esta línea
		local opens = 0
		for _, kw in OPENERS do
			for _ in codepart:gmatch("%f[%w]" .. kw .. "%f[%W]") do
				opens += 1
			end
		end

		-- Restar los "end" inline que cierran tablas, no bloques:
		-- una tabla "{ ... }" no usa "end" — Luau usa "}" para tablas.
		-- Por tanto todo "end" en el código es cierre de bloque real.
		local closes = 0
		for _ in codepart:gmatch("%f[%w]end%f[%W]") do
			closes += 1
		end

		-- Evaluar la línea ANTES de aplicar los cambios de profundidad
		-- de esta misma línea, para que "local function X()" no se cuente
		-- a sí misma como dentro de su propio scope.
		local effectiveDepth = blockDepth

		blockDepth = math.max(0, blockDepth + opens - closes)

		-- Solo verificar líneas en scope de módulo (depth 0 antes de esta línea)
		if effectiveDepth == 0 then
			for _, pattern in ROBLOX_GLOBAL_PATTERNS do
				if codepart:match(pattern) then
					table.insert(violations, {
						line = lineNumber,
						content = trimmed,
					})
				end
			end
		end
	end

	if #violations > 0 then
		table.insert(failed, { path = path, violations = violations })
	else
		table.insert(passed, path)
	end
end

-- ─── Ejecución ────────────────────────────────────────────────────────────────

local allFiles = {}
for _, dir in TARGETS do
	for _, file in collectLuaFiles(dir) do
		table.insert(allFiles, file)
	end
end

table.sort(allFiles)

stdio.write("\n🔍 Checking Lune compatibility for " .. #allFiles .. " module(s)...\n\n")

for _, file in allFiles do
	checkModule(file)
end

-- ─── Reporte ──────────────────────────────────────────────────────────────────

if #failed > 0 then
	stdio.write("❌ INCOMPATIBLE MODULES (" .. #failed .. "):\n")
	stdio.write("   Roblox globals at module scope — not compatible with Lune.\n\n")
	for _, result in failed do
		stdio.write("   ❌ " .. result.path .. "\n")
		for _, v in result.violations do
			stdio.write(
				string.format("      line %d: %s\n", v.line, v.content)
			)
		end
		stdio.write("\n")
	end
end

if #passed > 0 then
	stdio.write("✅ COMPATIBLE MODULES (" .. #passed .. "):\n")
	for _, path in passed do
		stdio.write("   ✅ " .. path .. "\n")
	end
	stdio.write("\n")
end

stdio.write("─────────────────────────────────────────\n")
stdio.write("Total: " .. #allFiles .. " | ")
stdio.write("Compatible: " .. #passed .. " | ")
stdio.write("Incompatible: " .. #failed .. "\n\n")

if #failed > 0 then
	stdio.write("Next step (Fase 2):\n")
	stdio.write("  Move Roblox service access inside functions.\n")
	stdio.write("  (inyección de dependencias — ver AI_CONTEXT_MASTER §4.6)\n\n")
	process.exit(1)
else
	stdio.write("✅ All modules are Lune-compatible.\n\n")
	process.exit(0)
end
