# Mudanza Caótica

Juego cooperativo multijugador en Roblox: un grupo de jugadores vacía un edificio transportando objetos al camión antes de que termine el tiempo. La profundidad no viene de mecánicas complejas — viene de la interacción humana, la coordinación imperfecta y las situaciones emergentes.

## Documentación

| Documento | Qué es |
|---|---|
| [docs/human/ONBOARDING.md](docs/human/ONBOARDING.md) | Guía de setup y flujo de trabajo para desarrolladores — **empieza aquí** |
| [docs/AI_CONTEXT_MASTER.md](docs/AI_CONTEXT_MASTER.md) | Única fuente de verdad del proyecto: visión, contratos, arquitectura |
| [docs/PROJECT_DECISION_LOG.md](docs/PROJECT_DECISION_LOG.md) | Registro de decisiones (DL-xxx) |
| [docs/TICKETS.md](docs/TICKETS.md) | Tickets de trabajo por dominio |
| [docs/SCRATCHPAD.md](docs/SCRATCHPAD.md) | Ideas sin procesar — se formalizan via SCRATCHPAD_INTAKE |

## Setup rápido

```bash
# 1. Toolchain (rojo, wally, stylua, selene, lune, lefthook — ver rokit.toml)
rokit install

# 2. Hooks de pre-commit
lefthook install

# 3. Dependencias (genera Packages/ y ServerPackages/, gitignored)
wally install

# 4. Sourcemap + tipos para el LSP
rojo sourcemap default.project.json --output sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
wally-package-types --sourcemap sourcemap.json ServerPackages/

# 5. Servir el proyecto a Roblox Studio
rojo serve
```

## Verificación local

```bash
stylua --check src/                        # formato
selene src/                                # linting
lune run lune/check-compatibility.luau     # globals de Roblox no en scope de módulo (§4.6)
lune run lune/run-specs.luau               # specs de TestEZ headless
```

Los mismos chequeos corren como hooks de pre-commit (`lefthook.yml`) y en CI sobre cada PR (`.github/workflows/p2-implementation.yml`).

## Estructura

```
src/server/   → ServerScriptService/Systems/   (lógica de juego, persistencia)
src/shared/   → ReplicatedStorage/Shared/      (Config, Lib, Tests)
src/client/   → StarterPlayerScripts/          (ClientStateManager)
src/gui/      → StarterGui/
lune/         → scripts de verificación y test runner headless
docs/         → gobernanza del proyecto
```

El mapeo completo Rojo → Roblox vive en [default.project.json](default.project.json) y está documentado en AI_CONTEXT_MASTER §4.1.
