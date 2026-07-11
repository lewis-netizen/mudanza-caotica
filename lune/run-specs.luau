-- lune/run-specs.luau
-- Corre los specs de TestEZ en Lune (sin Studio).
--
-- Patrón de inyección de dependencias para specs:
--   Cada spec es una función que recibe el módulo que testea como parámetro.
--   Si el módulo no existe aún (ticket pendiente), el spec se salta con SKIP.
--   Esto permite que los specs existan antes de que el módulo esté implementado.
--
-- El runner intenta cargar el módulo correspondiente a cada spec por path
-- relativo. Si el módulo no existe o no es Lune-compatible, lo pasa como nil
-- y el spec se encarga de saltar gracefully.
--
-- Uso (desde la raíz del proyecto):
--   lune run lune/run-specs.luau

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

-- ─── Configuración ────────────────────────────────────────────────────────────

local SPECS_DIR = "src/shared/Tests"

-- Mapeo spec → módulo que testea (path relativo desde la raíz)
-- Si el módulo no existe o no es Lune-compatible, se pasa nil al spec.
--
-- Nota: ProfileStore (paquete externo) no se testea aquí — sus garantías
-- de retry/session-locking son responsabilidad del paquete, no del proyecto.
-- PlayerDataService reemplaza a DataStoreService como módulo crítico
-- de Persistence tras la adopción de ProfileStore (§4.7, §4.11).
local MODULE_MAP = {
	["MigrationService.spec"]  = "src/server/Persistence/MigrationService",
	["ObjectManager.spec"]     = "src/server/ObjectManager",
	["PlayerDataService.spec"] = "src/server/Persistence/PlayerDataService",
}

-- ─── Utilidades ───────────────────────────────────────────────────────────────

local function tryLoadModule(path: string): any?
	local luaPath = path .. ".lua"
	local luauPath = path .. ".luau"
	local filePath = if fs.isFile(luaPath) then luaPath
		else if fs.isFile(luauPath) then luauPath
		else nil

	if not filePath then
		return nil -- módulo no implementado todavía
	end

	local source = fs.readFile(filePath)
	local chunk, err = load(source, "@" .. filePath)
	if not chunk then
		stdio.write("  ⚠ Could not load module " .. path .. ": " .. tostring(err) .. "\n")
		return nil
	end

	local ok, result = pcall(chunk)
	if not ok then
		stdio.write("  ⚠ Module errored on load " .. path .. ": " .. tostring(result) .. "\n")
		return nil
	end

	return result
end

local function collectSpecs(dir: string): { string }
	local specs = {}
	if not fs.isDir(dir) then
		stdio.write("⚠ Specs directory not found: " .. dir .. "\n")
		return specs
	end
	for _, entry in fs.readDir(dir) do
		if entry:match("%.spec%.lua$") or entry:match("%.spec%.luau$") then
			table.insert(specs, dir .. "/" .. entry)
		end
	end
	table.sort(specs)
	return specs
end

-- ─── Runner de TestEZ ─────────────────────────────────────────────────────────

local passed = 0
local failed = 0
local skipped = 0

local function makeTestEnv(): { [string]: any }
	local env = setmetatable({}, { __index = _G })

	function env.describe(name: string, fn: () -> ())
		stdio.write("\n  📦 " .. name .. "\n")
		local ok, err = pcall(fn)
		if not ok then
			stdio.write("    ❌ describe errored: " .. tostring(err) .. "\n")
			failed += 1
		end
	end

	function env.it(name: string, fn: () -> ())
		-- Detectar tests marcados como SKIP
		if name:match("^SKIP") then
			stdio.write("    ⏭ " .. name .. "\n")
			skipped += 1
			return
		end
		local ok, err = pcall(fn)
		if ok then
			stdio.write("    ✅ " .. name .. "\n")
			passed += 1
		else
			stdio.write("    ❌ " .. name .. "\n")
			stdio.write("       " .. tostring(err) .. "\n")
			failed += 1
		end
	end

	function env.beforeEach(_fn: any) end
	function env.afterEach(_fn: any) end
	function env.beforeAll(_fn: any) end
	function env.afterAll(_fn: any) end

	function env.expect(value: any)
		return {
			to = {
				equal = function(_, expected: any)
					if value ~= expected then
						error(string.format(
							"Expected %s but got %s",
							tostring(expected), tostring(value)
						), 2)
					end
				end,
				be = {
					ok = function(_)
						if not value then
							error("Expected truthy, got " .. tostring(value), 2)
						end
					end,
				},
				throw = function(_)
					if type(value) ~= "function" then
						error("expect(fn).to.throw() requires a function", 2)
					end
					local ok = pcall(value)
					if ok then
						error("Expected function to throw, but it did not", 2)
					end
				end,
			},
			never = {
				to = {
					be = {
						ok = function(_)
							if value then
								error("Expected falsy, got " .. tostring(value), 2)
							end
						end,
					},
					equal = function(_, unexpected: any)
						if value == unexpected then
							error("Expected NOT to equal " .. tostring(unexpected), 2)
						end
					end,
					throw = function(_)
						if type(value) ~= "function" then
							error("expect(fn).never.to.throw() requires a function", 2)
						end
						local ok = pcall(value)
						if not ok then
							error("Expected function NOT to throw, but it did", 2)
						end
					end,
				},
			},
		}
	end

	return env
end

-- ─── Ejecución ────────────────────────────────────────────────────────────────

local specs = collectSpecs(SPECS_DIR)
stdio.write("\n🧪 Running " .. #specs .. " spec file(s) in " .. SPECS_DIR .. "\n")

for _, specPath in specs do
	stdio.write("\n📄 " .. specPath .. "\n")

	-- Identificar el módulo correspondiente
	local specName = specPath:match("([^/]+)%.lua$") or specPath:match("([^/]+)%.luau$")
	local modulePath = MODULE_MAP[specName]
	local moduleInstance = if modulePath then tryLoadModule(modulePath) else nil

	if modulePath and not moduleInstance then
		stdio.write("  ℹ Module not yet implemented: " .. modulePath .. "\n")
	end

	-- Cargar y ejecutar el spec
	local source = fs.readFile(specPath)
	local chunk, loadErr = load(source, "@" .. specPath, "t", makeTestEnv())

	if not chunk then
		stdio.write("  ❌ Failed to compile: " .. tostring(loadErr) .. "\n")
		failed += 1
		continue
	end

	local ok, specFn = pcall(chunk)
	if not ok then
		stdio.write("  ❌ Errored on load: " .. tostring(specFn) .. "\n")
		failed += 1
		continue
	end

	if type(specFn) == "function" then
		local runOk, runErr = pcall(specFn, moduleInstance)
		if not runOk then
			stdio.write("  ❌ Errored on run: " .. tostring(runErr) .. "\n")
			failed += 1
		end
	end
end

-- ─── Resumen ──────────────────────────────────────────────────────────────────

stdio.write("\n─────────────────────────────────────────\n")
stdio.write(string.format(
	"Results: %d passed, %d failed, %d skipped\n\n",
	passed, failed, skipped
))

if failed > 0 then
	process.exit(1)
else
	process.exit(0)
end
