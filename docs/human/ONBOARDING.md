# ONBOARDING — Mudanza Caótica

Bienvenido al proyecto. Este documento es tu referencia completa para entender el sistema, configurar tu entorno, y empezar a trabajar.

---

## El proyecto

Mudanza Caótica es un juego cooperativo en Roblox donde un grupo de jugadores vacía un edificio transportando objetos al camión antes de que termine el tiempo. La profundidad viene de la interacción humana, no de mecánicas complejas.

**El documento que gobierna todas las decisiones es `docs/AI_CONTEXT_MASTER.md`.** Léelo completo antes de hacer cualquier cosa. Todo lo que no está en ese documento no existe para el proyecto.

---

## Parte 1 — Prerequisitos del sistema

Instala estas tres herramientas antes de tocar el repo. Los comandos difieren por sistema operativo.

### 1.1 Git

**Windows (PowerShell):**
```powershell
winget install --id Git.Git -e --source winget
```

**macOS:**
```bash
brew install git
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt install git
```

Verifica la instalación:
```bash
git --version
```

### 1.2 Rokit (gestor de versiones de las herramientas del proyecto)

**Windows (PowerShell):**
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
```

**macOS / Linux:**
```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | sh
source ~/.zshrc  # o ~/.bashrc según tu shell
```

Verifica la instalación:
```bash
rokit --version
```

### 1.3 GitHub CLI

**Windows (PowerShell):**
```powershell
winget install --id GitHub.cli
```

**macOS:**
```bash
brew install gh
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt install gh
```

Verifica la instalación:
```bash
gh --version
```

---

## Parte 2 — Configurar Git

### 2.1 Identidad

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### 2.2 Autenticación con GitHub

La forma más simple, funciona igual en cualquier sistema operativo:

```bash
gh auth login
```

Selecciona:
```
? What account do you want to log into?          GitHub.com
? What is your preferred protocol for Git?        HTTPS
? Authenticate Git with your GitHub credentials?  Yes
? How would you like to authenticate?             Login with a web browser
```

Esto configura el credential helper automáticamente — no necesitas gestionar llaves SSH manualmente.

### 2.3 Line endings (ya resuelto, no requiere acción)

El repo incluye `.gitattributes` que fuerza LF en todos los archivos de texto, independientemente de tu sistema operativo o configuración local de Git. No necesitas configurar `core.autocrlf` manualmente — el repo lo resuelve por ti.

---

## Parte 3 — Clonar e instalar el proyecto

```bash
git clone https://github.com/lewis-netizen/mudanza-caotica.git
cd mudanza-caotica

# Instala todas las herramientas del proyecto (rokit.toml):
# rojo, wally, wally-package-types, stylua, selene, lune, lefthook
rokit install

# Activa los pre-commit hooks
lefthook install

# Instala las dependencias de Wally
# (TestEZ, Promise, Janitor — shared; ProfileStore — server-only)
wally install

# Genera el sourcemap de Rojo
rojo sourcemap default.project.json --output sourcemap.json

# Genera los tipos de Luau para las dependencias externas
wally-package-types --sourcemap sourcemap.json Packages/
wally-package-types --sourcemap sourcemap.json ServerPackages/
```

---

## Parte 4 — Configurar Roblox Studio

### 4.1 Plugin de Rojo

Rokit ya puso `rojo` en tu PATH. Instala el plugin de Studio directamente desde la terminal:

```bash
rojo plugin install
```

Esto instala el plugin de Rojo en Roblox Studio sin necesidad de buscar manualmente en el Creator Store.

### 4.2 Plugin Luau LSP Companion

Este plugin no tiene instalación por CLI — se instala manualmente:

```
Roblox Studio → Toolbox → pestaña Plugins
→ buscar "Luau Language Server Companion" (autor: JohnnyMorganz)
→ Install
```

Después de instalarlo, en Studio verás un botón del plugin en la barra de herramientas. Este plugin permite que el Luau LSP de VSCode entienda instancias que no vienen de Rojo (por ejemplo, Parts colocadas manualmente en el Workspace), mejorando el autocompletado.

### 4.3 Flujo de trabajo diario con Rojo

Cada vez que trabajes en código que se sincroniza a Studio (la mayoría de `src/server/`, `src/shared/`, `src/client/`, `src/gui/`):

```bash
# Terminal — desde la raíz del proyecto
rojo serve
```

Esto levanta un servidor local. Luego en Roblox Studio:

```
Abrir el plugin de Rojo (icono en la barra de herramientas)
→ Connect
```

A partir de ahí, cualquier cambio que hagas en los archivos locales se sincroniza en vivo dentro de la sesión de Studio abierta. Deja `rojo serve` corriendo mientras trabajas.

---

## Parte 5 — Configurar VSCode

Las extensiones recomendadas están en `.vscode/extensions.json`. VSCode las sugiere automáticamente al abrir el proyecto. Instálalas todas:

```
JohnnyMorganz.luau-lsp      → Luau language support + autocompletado
evaera.vscode-rojo          → Companion plugin para Luau LSP
JohnnyMorganz.stylua        → Formateador de Luau
Kampfkarren.selene-vscode   → Linting inline de Selene
```

El `settings.json` ya configura `formatOnSave` con StyLua — el código se formatea automáticamente al guardar. El sourcemap para el LSP se autogenera usando `default.project.json` — no necesitas ejecutar nada adicional para el autocompletado, solo tener `rojo` en el PATH (ya lo tienes via Rokit).

---

## Parte 6 — Verificar que todo funciona

```bash
# Compatibilidad con Lune (debe dar 7/7 compatible o más, según módulos existentes)
lune run lune/check-compatibility.luau

# Formato (no debe haber errores)
stylua --check src/

# Linting
selene generate-roblox-std
selene src/
```

---

## Cómo fluye el trabajo

Todo cambio al proyecto es **Clase A** (arquitectónico) o **Clase B** (local).

**Clase B — cambio local:**
Bug trivial, typo, variable mal nombrada. Solo commit, nada más.

**Clase A — cambio arquitectónico:**
Cualquier cosa que afecte contratos, entidades, mecánicas, APIs o diseño:

```
1. Escribir idea en docs/SCRATCHPAD.md
2. Ejecutar SCRATCHPAD_INTAKE con Claude
3. Entrada aprobada → PROJECT_DECISION_LOG.md
4. Orchestrator audita (automático TECH via Codex, manual DESIGN via Claude)
5. Product Owner decide
6. Crear Issue en GitHub + asignar al Project
7. Implementar en rama con el prompt del rol correspondiente
8. Self-review contra criterios de aceptación del ticket
9. PR con labels domain:* + class:* → CI verifica contratos
10. Merge → Codex recibe Issue de auditoría TECH automáticamente
```

El humano interviene en pasos 1, 5, y 10 (revisión). El resto lo gestiona el sistema.

---

## Archivos que usas día a día

| Archivo | Para qué |
|---|---|
| `docs/SCRATCHPAD.md` | Escribir ideas sin estructura — zona de ingestión |
| `docs/TICKETS.md` | Ver qué hay que implementar (generado automáticamente) |
| `docs/PROJECT_DECISION_LOG.md` | Entender por qué se tomó una decisión |
| `docs/AI_CONTEXT_MASTER.md` | Referencia de todo lo que es el proyecto |

**TICKETS.md no se edita manualmente.** Se actualiza automáticamente desde el GitHub Project via `sync-tickets.yml` (cron cada hora, o `gh workflow run sync-tickets.yml` para forzar sincronización inmediata).

---

## Prompts disponibles

**Para ideas (Ideadores):**
- `SCRATCHPAD_INTAKE` — filtra y formaliza lo que escribiste en el scratchpad
- `GAMEPLAY_DESIGNER` — mecánicas de cooperación y core loop
- `WORLD_DESIGNER` — NPC, eventos y layout
- `UX_DESIGNER` — contratos de percepción y feedback

**Para implementar (Constructores):**
- `GAMEPLAY_ENGINEER` — ObjectManager, CarryManager, TruckManager
- `WORLD_ENGINEER` — NPCManager, EventManager
- `NETWORKING_ENGINEER` — RemoteEvents y validación cliente-servidor
- `PERSISTENCE_ENGINEER` — integración de ProfileStore, MigrationService
- `UI_ENGINEER` — HUD, Summary Screen (usa Janitor para lifecycle)

**Para auditar (Orchestrators — se activan automáticamente):**
- `AUDITOR_TECH` — Codex, se activa post-merge via Issue de GitHub
- `AUDITOR_DESIGN` — Claude, se activa manualmente cada lunes

---

## Dependencias externas del proyecto (Wally)

| Paquete | Uso |
|---|---|
| `ProfileStore` | Persistencia de PlayerData — session locking, retry, auto-save. Solo servidor. |
| `Promise` | Manejo de operaciones asíncronas |
| `Janitor` | Lifecycle de conexiones en módulos de UI (no en ClientStateManager) |
| `TestEZ` | Framework de testing |

No añadas dependencias nuevas sin pasar por el ciclo Clase A — ver DL-015 para el criterio de adopción usado.

---

## Convención de commits

```
tipo(dominio): descripción corta

reason: por qué se hizo
refs: DL-[número], [DOMINIO]-[número]   ← solo en Clase A
```

**Tipos válidos:** `feat` `fix` `refactor` `docs` `chore`
**Dominios válidos:** `gameplay` `world` `networking` `persistence` `ui` `ux` `governance`

Lefthook valida el formato automáticamente antes de crear el commit.

---

## Flujo de rama y PR

```bash
# 1. Crear rama desde main actualizado
git checkout main && git pull
git checkout -b feat/NET-001

# 2. Implementar con el prompt del rol correspondiente

# 3. Commitear — Lefthook corre automáticamente
git add .
git commit -m "feat(networking): implementar Networking.lua

reason: fuente unica de referencias a RemoteEvents del proyecto
refs: DL-005, NET-001"

# 4. Push y abrir PR
git push origin feat/NET-001
gh pr create --title "feat(networking): NET-001" --body "" \
  --label "domain:tech" --label "class:a"

# 5. CI verifica contratos automáticamente

# 6. Merge (squash) → Codex recibe Issue de auditoría
```

---

## Pre-commit hooks — qué verifican

Corren automáticamente en cada `git commit`. Si algo falla, el commit se bloquea con un mensaje claro.

| Hook | Qué verifica |
|---|---|
| `stylua` | Formato de código |
| `selene` | Linting |
| `contract-logger-usage` | print()/warn() directos prohibidos — usa Lib/Logger.lua |
| `contract-networking-isolation` | Networking.*:Connect() solo en ClientStateManager |
| `contract-audio-isolation` | sound:Play() no en módulos de gameplay |
| `contract-pathfinding-banned` | PathfindingService no en src/ |
| `contract-name-as-condition` | .Name no como condición lógica |
| `contract-module-size` | Ningún módulo > 400 líneas (DL-033) |
| `contract-layer-separation` | src/server/ no requiere src/client/ |
| `contract-test-coverage-persistence` | MigrationService y PlayerDataService tienen spec |
| `contract-lune-compatibility` | Globals de Roblox no en scope de módulo |
| `commitlint` | Convención de commits |

Saltar un hook en emergencias (documenta por qué si lo haces):
```bash
git commit --no-verify -m "..."
```

---

## GitHub Project — cómo usarlo

El Project es tu fuente de verdad operativa como humano. TICKETS.md es la fuente de verdad para las IAs.

**Crear un Issue (por cada ticket de TICKETS.md):**
```
Título: [DOMINIO]-[número] — descripción corta
Ejemplo: NET-001 — Networking.lua fuente única de RemoteEvents
Labels: domain:tech + class:a (o class:b)
```

El Issue aparece automáticamente en el Project (columna TODO) con `Auto-add to project` activado.

**Rellenar campos custom:** clickea el card en el Project → Domain, Semana, DL-Ref en el panel lateral.

**Mover cards:** arrastra a la columna correcta cuando cambies el estado. `sync-tickets.yml` actualiza TICKETS.md automáticamente.

---

## Lune — comandos útiles

```bash
# Verificar compatibilidad de módulos con Lune (antes de implementar)
lune run lune/check-compatibility.luau

# Correr specs de TestEZ sin Studio
lune run lune/run-specs.luau
```

Specs de módulos no implementados todavía se saltan con SKIP — no fallan.

---

## Comandos útiles de GitHub CLI

```bash
# Ver estado de los workflows en el último push
gh run list

# Abrir el PR actual en el browser
gh pr view --web

# Ver Issues abiertos
gh issue list

# Correr sync de tickets manualmente
gh workflow run sync-tickets.yml

# Ver el log de un workflow específico
gh run view [run-id] --log

# Crear un label desde terminal
gh label create "domain:tech" --color "0075ca"
```

---

## Si lefthook deja de funcionar

Si `lefthook.yml` cambió y tus hooks no reflejan los cambios:

```bash
git pull
lefthook install
```

---

## Si algo no está claro

Primero busca en `docs/AI_CONTEXT_MASTER.md`. Si no está ahí, escríbelo en `docs/SCRATCHPAD.md` como QUESTION y pasa por el intake con Claude. El sistema está diseñado para capturar exactamente eso.
