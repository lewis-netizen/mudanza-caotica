# RUNTIME_VERIFICATION — Smoke test de runtime (P6, §6.7)

La verificación de runtime cierra el hueco que dejó pasar los bugs de QA-001: los
specs prueban núcleos puros **aislados** (§4.13) — no ven la *integración*
(cableado cliente↔servidor, payloads, física, orden de eventos). Este smoke test
verifica que el **juego corre de verdad**, vía el **MCP de Roblox Studio** (lo
conduce Claude o el humano).

> **Gate de Definition of Done (DL-043):** un ticket que toca comportamiento de
> runtime — cableado cliente↔servidor, payloads de RemoteEvent, física/colisiones/
> trigger zones, orden de eventos, o el bootstrap — **no está DONE** hasta pasar
> este smoke test. Los specs verdes NO bastan.

## 0. Prerrequisitos (higiene de sync)

Un Studio *stale* produce diagnósticos falsos (en QA-001 reportó "ServerScriptService
vacío" cuando no lo estaba). Antes de verificar:

- Studio abierto con el place, **plugin del MCP habilitado** (Assistant Settings).
- **Rojo conectado y sincronizado** — el Studio debe reflejar el repo. Si dudas,
  reconecta rojo y re-sincroniza; confirma leyendo un script vía el MCP
  (`script_read`) y comparándolo con el repo.

## 1. Bootstrap limpio

1. `start_stop_play(is_start=true)`.
2. `get_console_output`. **Debe** aparecer, sin errores ni stack traces (más allá de
   ruido conocido de plataforma como `LoadUnownedAsset`/`PlatformLeaderboard`):
   - `[Main.server] Servidor arrancado`
   - `[MapBootstrap] Mapa placeholder generado`
   - `[GameManager] Fase global → Active` (tras `LOBBY_DURATION`)
   - `[ObjectManager] Spawn completo — N objetos`
   - `[CarryManager] Carry activo`, `[TruckManager] Zona de entrega activa`
   - `[ClientStateManager] Inicializado`, `[InteractionController] Inicializado`

Cualquier stack trace aquí es un fallo — investiga antes de seguir.

## 2. Loop core end-to-end

Con la ronda activa (paso 1), teletransportar el personaje junto a un objeto small,
disparar la interacción, y verificar pickup → entrega. El input simulado
(`user_keyboard_input`) es intermitente; para aserciones deterministas, dispara
`InteractObject` directo desde el cliente (mismo path que InteractionController).

**Server — preparar (esperar ronda + teleport junto a un small):**
```lua
local CS, Players = game:GetService("CollectionService"), game:GetService("Players")
local target
repeat task.wait(0.5)
  for _, p in ipairs(CS:GetTagged("CarryObject")) do
    if tostring(p:GetAttribute("ObjectId")):find("small") then target = p break end
  end
until target
local root = Players:GetPlayers()[1].Character:WaitForChild("HumanoidRootPart")
root.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 3))
return target:GetAttribute("InstanceId")
```

**Client — recoger:**
```lua
require(game.ReplicatedStorage.Shared.Lib.Networking).InteractObject
  :FireServer({ instanceId = "<id del paso anterior>" })
```

**Server — aserción de pickup** (el objeto se desancla y se weldea al jugador):
```lua
local CS = game:GetService("CollectionService")
for _, p in ipairs(CS:GetTagged("CarryObject")) do
  if p:GetAttribute("InstanceId") == "<id>" then
    local welded = false
    for _, d in ipairs(workspace:GetDescendants()) do
      if d:IsA("WeldConstraint") and (d.Part0 == p or d.Part1 == p) then welded = true end
    end
    return ("anchored=%s welded=%s"):format(tostring(p.Anchored), tostring(welded))
    -- ESPERADO: anchored=false welded=true
  end
end
```

**Server — entregar** (caminar cargando dentro de la TruckZone):
```lua
local CS, Players = game:GetService("CollectionService"), game:GetService("Players")
local char = Players:GetPlayers()[1].Character
local zone = CS:GetTagged("TruckZone")[1]
char.HumanoidRootPart.CFrame = CFrame.new(zone.Position + Vector3.new(0, 3, 12))
task.wait(0.4)
char:FindFirstChildOfClass("Humanoid"):MoveTo(zone.Position)
task.wait(3)
local exists = false
for _, p in ipairs(CS:GetTagged("CarryObject")) do
  if p:GetAttribute("InstanceId") == "<id>" then exists = true end
end
return "objStillExists=" .. tostring(exists) -- ESPERADO: false (entregado, destruido)
```

Luego `get_console_output` → **debe** verse `[TruckManager] Entrega #1 — <id> (...)`.

## 3. Aserciones de estado del cliente

`state.objects` debe estar **poblado** en el cliente (bug #1: `RoundStarted` lo
borraba). El `require` en `execute_luau` corre en contexto aislado y NO ve el módulo
vivo — para inspeccionarlo, instrumenta temporalmente `onInteract` (escribe el conteo
a un Attribute de `LocalPlayer`) o confía en que el pickup del paso 2 tuvo éxito
(implica `state.objects` poblado + objetivo resuelto).

## 4. Cierre

`start_stop_play(is_start=false)`. Registra observaciones (bugs, fricción) en
`docs/SCRATCHPAD.md` → alimentan P1.

---

## Notas

- **CI no puede correr esto** (no conduce Studio). Es una verificación **manual/MCP**,
  parte del Definition of Done, no un job de CI. Es la primera etapa del pipeline con
  automatización de IA **real** (§6.7, vs. el Codex aspiracional de DL-038).
- **Contexto aislado del `require`:** `execute_luau` requiere módulos frescos — no ve
  el estado de los módulos en ejecución. Inspecciona el **DataModel** (instancias,
  Attributes, tags, welds), no el estado interno de módulos vía `require`.
- **Lecciones QA-001 codificadas:** §4.3 (payload), §4.10 (ownership de estado), §4.4
  (trigger zones) — el smoke test las re-verifica.
