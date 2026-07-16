# TICKETS — Mudanza Caótica
**Referencia:** AI_CONTEXT_MASTER v5.7 §5.5

Los tickets están organizados por Dominio Arquitectónico (§5.1), no por responsable.
Un ticket pertenece a un dominio. Una persona puede cubrir múltiples dominios.

---

## Formato de ticket

```
ID:          [DOMINIO]-[número]
Fecha:       YYYY-MM-DD
DL-Ref:      DL-[número]
Deriva de:   DL-[número] | Principio §2.1: [nombre] | §N.N (contrato) | Hito §5.7: Semana [n]
Domain:      TECH | DESIGN | BOTH
Estado:      TODO | IN_PROGRESS | DONE | BLOCKED
Semana:      1 | 2 | 3 | 4
Depende de:  [IDs de tickets requeridos antes]
Descripción: [qué implementar]
Criterios de Aceptación:
  - [ ] [condición — verificable sí/no]
Notas:       [observaciones durante implementación]
```

**Campo `Deriva de` (§5.5, DL-032):** todo ticket declara su origen — una
DECISIÓN del Decision Log, o el Principio/contrato/hito que habilita. Un ticket
sin `Deriva de` es incompleto.

**Prefijos de ticket:** `FND` (fundación Shared/Lib + Config), `NET`, `PER`,
`GAM`, `WLD`, `UI` corresponden a dominios de implementación (§5.1). `GM-xxx`
pertenece al dominio Gameplay — prefijo propio para agrupar los tickets de
GameManager (ciclo de vida). `QA-xxx` **no es un dominio**: son hitos
transversales de integración semanal, playtest formal (P6) y publicación.

**Nota de bootstrap:** Los tickets iniciales se derivaron del AI_CONTEXT_MASTER
durante el bootstrap — por eso no llevan `DL-Ref`. Se les retrofiteó `Deriva de`
(auditoría 2026-07-12, aplicación de DL-032): su origen es el contrato §4.4/§4.5
que definen y su hito de roadmap. Todo ticket **nuevo** debe nacer de una
entrada DECISION del Decision Log e incluir `DL-Ref` (§5.5 paso 5).

---

## Fundación (Shared/Lib + Config)

### FND-001 — Logger: logging estructurado

```
Deriva de:   §4.4 (Logger, prerequisito de todo módulo) + §4.5 Nivel -1
Domain:      TECH
Estado:      DONE
Semana:      1
Depende de:  ninguna
```

**Descripción**
`src/shared/Lib/Logger.lua` — logging estructurado que reemplaza `print`/`warn` directos en todo el proyecto. Niveles DEBUG/INFO/WARN/ERROR; nivel mínimo desde `GlobalConfig.LOG_LEVEL`. Prerequisito absoluto (§4.5 Nivel -1). El ban de `print`/`warn` fuera de este módulo lo impone el contrato grep `contract-logger-usage`.

**Criterios de Aceptación**
- [x] `Logger.new(moduleName)` retorna instancia con `debug`/`info`/`warn`/`error`
- [x] El nivel mínimo se lee de `GlobalConfig.LOG_LEVEL` (WARN por defecto sin DataModel)
- [x] Lune-compatible: `GlobalConfig` se resuelve lazy, no en scope de módulo (§4.6)
- [x] `print`/`warn` directos prohibidos fuera de este módulo (verificado por `contract-logger-usage`)

**Notas**
Ticket de alta retroactiva (auditoría 2026-07-12, completitud §5.5/DL-032). Módulo foundational implementado en bootstrap sin ticket propio — se registra para trazabilidad.

---

### FND-002 — Config: schemas de configuración

```
Deriva de:   §4.6 (INV-004: config no hardcodeada) + §4.5 Nivel -1/0
Domain:      TECH
Estado:      DONE
Semana:      1
Depende de:  ninguna
```

**Descripción**
Módulos de `src/shared/Config/`: `GlobalConfig` (LOG_LEVEL, FEATURE_FLAGS, IS_STUDIO, MAX_INTERACT_RANGE, TIMER_SYNC_INTERVAL), `GameplayConfig` (NPC_SPEED, OBJECT_COUNTS, placeholders), `RoundConfig` (duraciones), `Events` (schema de StoryEvents + pool). Todo valor de balance/timing transversal vive aquí — nunca hardcodeado en módulos (INV-004).

**Criterios de Aceptación**
- [x] Cada módulo de Config expone solo valores/constantes, sin lógica de juego
- [x] Lune-compatible: `game` solo se accede dentro de funciones (§4.6)
- [x] `Events.STORY_EVENT_TYPES` es la fuente canónica de EventTypes (INV-003)
- [x] Ningún valor de configuración transversal está duplicado en módulos de Sistema (INV-004)

**Notas**
Ticket de alta retroactiva (auditoría 2026-07-12). Foundational implementado en bootstrap. Los estados de wire (ObjectState/RoundPhase) viven en `Shared/Constants` (refactor class:b, sin ticket propio).

---

### FND-003 — Versionado de ObjectPrefabs via Rojo

```
DL-Ref:      DL-040
Deriva de:   DL-040 (asset dentro de Rojo)
Domain:      TECH
Estado:      TODO
Semana:      1
Depende de:  ninguna
```

**Descripción**
Traer `ServerStorage/ObjectPrefabs` a Rojo. Añadir en `default.project.json` un mapeo de `ServerStorage/ObjectPrefabs` a un archivo de modelo versionado `assets/ObjectPrefabs.rbxmx`. Elimina el estado "fuera de Rojo" (§4.1): los prefabs pasan a ser versionables y reproducibles con `rojo build`/`serve`. Actualizar §4.1 en consecuencia.

**Criterios de Aceptación**
- [x] `default.project.json` mapea `ServerStorage/ObjectPrefabs` a `assets/ObjectPrefabs.rbxmx`
- [x] `rojo build` incluye ObjectPrefabs en ServerStorage sin pasos manuales de Studio
- [x] `assets/ObjectPrefabs.rbxmx` está versionado en el repo — generado por `lune/build-prefabs.luau` con los 3 modelos del catálogo
- [x] §4.1 deja de declarar ObjectPrefabs "fuera de Rojo"; refleja el mapeo (DL-040)
- [x] PrefabRegistry sigue resolviendo desde `ServerStorage/ObjectPrefabs` sin cambios de código

**Notas**
Habilitador de versionado (DL-040, completitud DL-039). **Superó el plan del ticket** (licencia del PO): en lugar de esperar autoría manual en Studio, los prefabs se generan en código (`lune/build-prefabs.luau`, coste-IA §5.9) con verificación round-trip del contrato §4.4. WLD-008 queda solo para el arte final.

---

### FND-004 — Configuración del place de Roblox

```
DL-Ref:      DL-039
Deriva de:   §4.1 (infraestructura de repo) + DL-039 (completitud) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GM-001
```

**Descripción**
Documentar y versionar (donde sea posible) la configuración del place/juego de Roblox que el slice requiere y que ningún ticket nombraba: RemoteEvents en `default.project.json` (NET-001), Tags de CollectionService, SpawnLocations (lobby y ronda), y settings del place (StreamingEnabled acorde a §4.12, colisiones). Lo reproducible via Rojo/project.json se versiona; lo que solo vive en Studio se documenta en `docs/ROBLOX_SETUP.md` (nombre distinto de `.github/PROJECT_SETUP.md`, que es del GitHub Project).

**Criterios de Aceptación**
- [x] `default.project.json` refleja el árbol canónico de §4.1 (Remotes, Systems, Shared, Packages) — `ServerStorage/ObjectPrefabs` queda a FND-003 (necesita el `.rbxmx`)
- [x] Los settings del place no versionables via Rojo están documentados en `docs/ROBLOX_SETUP.md`
- [x] StreamingEnabled fijado acorde al sobre de escala (§4.12); sin CollisionGroups propios en el slice
- [x] Un desarrollador nuevo puede levantar el place desde el repo siguiendo `docs/ROBLOX_SETUP.md` sin adivinar configuración

**Notas**
Deriva de la completitud (DL-039): la "correcta configuración de Roblox" era infra implícita sin ticket.

---

## Dominio: Networking

### NET-001 — Networking.lua: Fuente única de RemoteEvents

```
Deriva de:   §4.3 (RemoteEvents y Contratos) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  ninguna
```

**Descripción**
Implementar `src/shared/Lib/Networking.lua` como la única fuente de referencias a RemoteEvents. Los 7 RemoteEvents se **declaran en `default.project.json`** (Rojo) — versionables y reproducibles, sin pasos manuales de Studio (coste-IA, §5.9). Ningún otro módulo referencia RemoteEvents directamente — todos los importan desde este módulo.

**Criterios de Aceptación**
- [ ] `src/shared/Lib/Networking.lua` expone referencias a los 7 RemoteEvents definidos en §4.3
- [ ] Los 7 RemoteEvents se declaran en `default.project.json` bajo `ReplicatedStorage/Remotes`: `InteractObject`, `DeliverObject`, `ObjectStateChanged`, `EventTriggered`, `RoundStarted`, `RoundEnded`, `TimerSync`
- [ ] Ningún módulo referencia `ReplicatedStorage.Remotes.*` directamente — todos usan `Networking.*`
- [ ] La dirección de cada evento (cliente→servidor o servidor→clientes) está comentada en el módulo
- [ ] El módulo no contiene lógica de juego, solo referencias
- [ ] El conteo de RemoteEvents no supera el cap de §4.3 (verificado por `contract-remote-event-count`)

---

## Dominio: Persistence

### PER-001 — ProfileStore: Integración y configuración

```
Deriva de:   §4.7 (Persistencia y Migraciones) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  ninguna
```

**Descripción**
Añadir `lm-loleris/profilestore@1.0.3` a `[server-dependencies]` de `wally.toml`. Crear `src/server/Persistence/ProfileStoreConfig.lua` con la definición del ProfileStore (nombre del store, template de datos por defecto según §2.5). Este ticket NO implementa lógica propia de persistencia — configura el paquete externo que la provee.

**Criterios de Aceptación**
- [ ] `ProfileStore` está declarado en `[server-dependencies]` de `wally.toml`
- [ ] `ProfileStoreConfig.lua` define el store con nombre versionado (ej: `"PlayerData_v1"`)
- [ ] El template por defecto coincide exactamente con el schema canónico de PlayerData (§2.5)
- [ ] `ProfileStoreConfig.lua` nunca se requiere desde `src/client/` (verificable por `contract-layer-separation`)
- [ ] No existe código propio que llame `game:GetService("DataStoreService")` directamente — toda interacción pasa por ProfileStore

---

### PER-002 — MigrationService: Versionado de PlayerData

```
Deriva de:   §4.7 (Persistencia — migraciones de schema) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  PER-001
```

**Descripción**
Implementar `src/server/Persistence/MigrationService.lua`. Detecta la versión del PlayerData cargado por ProfileStore y aplica migraciones secuenciales hasta llegar a la versión canónica actual (`Version = 1`). Todo dato sin campo `Version` se trata como versión 0. ProfileStore gestiona el ciclo de vida del DataStore — MigrationService solo transforma el schema de los datos que ProfileStore ya cargó.

**Criterios de Aceptación**
- [ ] `MigrationService.migrate(data)` retorna el dato migrado a la versión canónica actual
- [ ] Dato sin campo `Version` es tratado como versión 0 y migrado correctamente
- [ ] Las migraciones se aplican en orden secuencial — nunca saltos
- [ ] Si la migración falla, retorna un PlayerData vacío con `Version = 1` — nunca datos corruptos
- [ ] Añadir una migración futura no requiere modificar la lógica central del servicio, solo registrar una función nueva en el pipeline

---

### PER-003 — PlayerDataService: Wrapper sobre ProfileStore

```
Deriva de:   §4.7 (wrapper de dominio) + DL-020 (ciclo de sesión atado al jugador)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  PER-001, PER-002
```

**Descripción**
Implementar `src/server/Persistence/PlayerDataService.lua` como wrapper delgado sobre ProfileStore. Su responsabilidad es exclusivamente de dominio: aplicar `MigrationService.migrate()` al `Profile.Data` cargado por ProfileStore, y exponer una API estable al resto del proyecto. No reimplementa retry, session locking, ni auto-save — eso ya lo provee ProfileStore.

**Criterios de Aceptación**
- [ ] `PlayerDataService.loadPlayer(player)` inicia sesión de ProfileStore (`StartSessionAsync`), aplica `MigrationService.migrate()` al `Profile.Data`
- [ ] `PlayerDataService.savePlayer(player)` solo dispara un flush explícito (`Profile:Save()`) — no implementa lógica propia de guardado y **nunca** cierra la sesión
- [ ] `PlayerDataService.releasePlayer(player)` cierra la sesión (`Profile:EndSession()`) — se llama únicamente en `PlayerRemoving`, nunca en transiciones de ronda (§4.4, §4.7)
- [ ] `PlayerDataService.getData(player)` retorna `Profile.Data` en memoria sin operación de red
- [ ] Si `StartSessionAsync` falla (perfil bloqueado por otro servidor), el jugador recibe PlayerData por defecto y un `Logger:warn()` — nunca bloquea el join
- [ ] Los dominios reservados (`Identity`, `Creation`) se inicializan como tablas vacías en el template de PER-001, nunca nil
- [ ] Ningún código propio implementa rate limiting manual de guardado — ProfileStore ya lo gestiona internamente

---

### PER-004 — QA: Integración de Persistencia

```
Deriva de:   §3.8 (Criterio de Éxito: los datos sobreviven entre sesiones) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      TODO
Semana:      1
Depende de:  PER-003, GM-002
```

**Descripción**
Verificar que el ciclo completo de persistencia funciona end-to-end: jugador nuevo obtiene PlayerData vacío, juega una ronda, sus Stats se actualizan, y al salir el dato persiste correctamente.

**Criterios de Aceptación**
- [ ] Un jugador nuevo obtiene PlayerData vacío con `Version = 1` en su primera sesión
- [ ] Un jugador que vuelve obtiene sus Stats de la sesión anterior
- [ ] `Stats.MatchesCompleted` y `Stats.ObjectsSaved` se incrementan al terminar ronda
- [ ] `Profile.FirstJoinDate` se guarda en la primera sesión y no se sobreescribe
- [ ] `Profile.LastJoinDate` se actualiza en cada sesión
- [ ] El dato persiste entre dos sesiones en Studio (Play → Stop → Play)
- [ ] No hay errores en consola durante el ciclo completo de carga y guardado

---

## Dominio: Gameplay

### GAM-009 — PrefabRegistry: Resolución ObjectId → asset

```
DL-Ref:      DL-031
Deriva de:   DL-031
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GAM-001
```

**Descripción**
Implementar `src/server/PrefabRegistry.lua` como única capa que conoce `ServerStorage/ObjectPrefabs`. Resuelve `ObjectId → prefab` por Attribute (nunca `.Name`, §2.4), con placeholder de fallback si falta el prefab, y `validate()` que audita el contrato al bootstrap. Cierra el hueco entre `ObjectDefinition` y el asset real sin acoplar `ObjectManager` a Studio (§4.4, contrato Arte → PrefabRegistry).

**Criterios de Aceptación**
- [ ] `PrefabRegistry.resolve(objectId)` retorna el template o nil; el caller clona — el template nunca sale de ServerStorage
- [ ] `instantiate(def)` retorna `(top, root, isPlaceholder)`: `root` siempre es un BasePart
- [ ] Prefab ausente → placeholder generado desde `GameplayConfig.PLACEHOLDER_OBJECT_*`
- [ ] Identificación por Attribute `ObjectId`, nunca por `.Name`
- [ ] `validate()` reporta faltantes, huérfanos, duplicados e inválidos al bootstrap
- [ ] Núcleo `_audit` puro y testeado en Lune (`PrefabRegistry.spec`)

**Notas**
Implementado en PR #31. Estado real: IN_PROGRESS hasta merge. Ticket de alta retroactiva (DL-032) — primer caso de la Regla de derivación: deriva de la decisión DL-031, no de un problema encontrado en el camino.

---

### GAM-001 — ObjectDefinitions: Datos de objetos small/medium/large

```
Deriva de:   §2.3 (Entidad Object: ObjectDefinition) + §4.1 (Definitions)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  ninguna
```

**Descripción**
Crear al menos un ObjectDefinition concreto por cada Size (`small`, `medium`, `large`) en `src/shared/Definitions/Objects/`. Cada definición incluye `ObjectId`, `Size`, y `Properties` con los valores configurables: velocidad reducida para medium, rango de soporte y timeout de caída para large.

**Criterios de Aceptación**
- [ ] Existe al menos un ObjectDefinition para cada Size: small, medium, large
- [ ] Cada definición tiene `ObjectId` único (string), `Size` y `Properties`
- [ ] `Properties` de medium incluye `carrySpeedMultiplier` (número entre 0 y 1)
- [ ] `Properties` de large incluye `supportRange` (studs) y `supportTimeout` (segundos)
- [ ] Ningún valor de Properties está hardcodeado en módulos de Sistema — todo viene de la definición
- [ ] Los ObjectIds son strings identificadores, nunca nombres de objetos en Studio

---

### GAM-002 — ObjectManager: Spawn y estados

```
Deriva de:   §4.4 (ObjectManager) + §4.8 (único propietario de ObjectInstance.State)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  NET-001, GAM-001, GAM-009
```

**Descripción**
Implementar `src/server/ObjectManager.lua` con spawn de objetos al inicio de ronda en los Parts tagueados `ObjectSpawn` (§4.4), resolviendo la representación física via PrefabRegistry (GAM-009, DL-031), y tracking de estados por ObjectInstance. Exponer la API completa definida en §4.4.

**Criterios de Aceptación**
- [ ] Al iniciar ronda, los objetos spawnean en los Parts con Tag `ObjectSpawn` (posición aleatoria entre ellos)
- [ ] La representación física se obtiene de `PrefabRegistry.instantiate` — ObjectManager no construye placeholders ni conoce ServerStorage
- [ ] `ObjectManager.getObject(instanceId)` retorna una copia de `ObjectInstance` sin nil errors
- [ ] `ObjectManager.setState(instanceId, state, leaderId?, supportId?)` actualiza estado y dispara `ObjectStateChanged` con `{instanceId, objectId, state, leaderId, supportId}` (§4.3, DL-026)
- [ ] `ObjectManager.reset()` elimina todos los objetos del Workspace y limpia el estado interno
- [ ] `ObjectManager.getFreeObjects()` retorna únicamente objetos en estado `free`
- [ ] No pueden existir dos ObjectInstances con el mismo InstanceId
- [ ] ObjectManager es el **único** módulo que modifica `ObjectInstance.State`

---

### GAM-003 — CarryManager: Pickup y drop (objeto small)

```
Deriva de:   Principio §2.1 (Dependencia Social) + §4.4 (CarryManager) + DL-027 (WalkSpeed)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GAM-002, NET-001
```

**Descripción**
Un jugador puede recoger y soltar un objeto small. La interacción se inicia desde el cliente vía `InteractObject`. Toda validación y cambio de estado corre server-side. `CarryManager` es el único punto que conecta `OnServerEvent` (INV-001, DL-029). El objeto sigue al jugador mientras lo carga.

**Criterios de Aceptación**
- [ ] El servidor valida `InteractObject` antes de cambiar estado — tipo, existencia, rango, estado `free`
- [ ] `OnServerEvent:Connect` de `InteractObject` vive **solo** en CarryManager (INV-001, DL-029)
- [ ] El objeto en `being_carried` sigue la posición del jugador server-side (WeldConstraint, no Heartbeat)
- [ ] Dos jugadores no pueden cargar el mismo objeto simultáneamente
- [ ] Al soltar, el objeto queda en posición actual del jugador y vuelve a `free`
- [ ] Un jugador solo puede cargar un objeto a la vez
- [ ] El estado se refleja en todos los clientes via `ObjectStateChanged`

---

### GAM-004 — TruckManager: Zona de entrega y conteo

```
Deriva de:   §4.4 (TruckManager) + §3.1 (core loop: entrega al camión)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GAM-003
```

**Descripción**
Implementar `src/server/TruckManager.lua`. Zona de entrega detectada server-side via `Part.Touched`. Al entregar, el objeto pasa a `delivered`, se dispara `DeliverObject` y se registra un StoryEvent.

**Criterios de Aceptación**
- [ ] La entrega se detecta server-side via `Part.Touched` sobre el Part tagueado `TruckZone` — nunca por RemoteEvent del cliente
- [ ] El `instanceId` se resuelve subiendo por ancestría desde la parte tocada (soporta Models multi-part, DL-031)
- [ ] `DeliverObject` se dispara con `instanceId` correcto al entregar
- [ ] `TruckManager.getDeliveredCount()` retorna conteo correcto en tiempo real
- [ ] `TruckManager.reset()` limpia el conteo sin residuos
- [ ] El objeto desaparece del Workspace al ser entregado
- [ ] Solo objetos en `being_carried` pueden entregarse — objetos `free` en la zona no cuentan
- [ ] Se registra StoryEvent via `RoundManager.recordStoryEvent("ObjectDelivered", {instanceId, objectId, playerId})` — `playerId` es el líder, para atribución de stats (§2.5)

---

### GAM-005 — CarryManager: Velocidad reducida en objetos medium

```
Deriva de:   §3.3 (fricción de cooperación) + §4.4 (CarryManager) + DL-027 (WalkSpeed)
Domain:      TECH
Estado:      TODO
Semana:      2
Depende de:  GAM-003, GAM-001
```

**Descripción**
Cargar un objeto medium reduce el `WalkSpeed` del jugador según `ObjectDefinition.Properties.carrySpeedMultiplier`. La reducción se aplica server-side al iniciar el carry y se restaura al soltar o entregar.

**Criterios de Aceptación**
- [ ] `WalkSpeed` se reduce al recoger un objeto medium según `carrySpeedMultiplier` de la definición
- [ ] `WalkSpeed` se restaura al valor **previo guardado** al soltar o entregar (DL-027) — nunca a una constante
- [ ] El valor viene de `ObjectDefinition.Properties` — no hardcodeado en CarryManager
- [ ] La reducción no pisa otras modificaciones activas de velocidad (DL-027)
- [ ] Compatible con GAM-003 sin modificar su lógica central

---

### GAM-006 — CarryManager: Sistema líder/soporte para objetos large

```
Deriva de:   Principio §2.1 (Dependencia Social — cooperación forzada) + §3.3
Domain:      TECH
Estado:      TODO
Semana:      2
Depende de:  GAM-003, GAM-001
```

**Descripción**
Un objeto large requiere un jugador líder (inicia el carry) y al menos un jugador soporte en rango. El carry no comienza sin soporte. `ObjectStateChanged` incluye `leaderId` y `supportId`. Sin sincronización física entre clientes, sin Heartbeat.

**Criterios de Aceptación**
- [ ] Solo el jugador que inicia la interacción puede ser líder
- [ ] El carry no comienza si no hay soporte dentro de `ObjectDefinition.Properties.supportRange`
- [ ] `ObjectStateChanged` incluye `leaderId` y `supportId` correctamente
- [ ] El objeto se ancla al líder server-side — sin sincronización física entre clientes
- [ ] El sistema no usa Heartbeat para movimiento del objeto
- [ ] Sustituye el rechazo temporal de large de GAM-003 (el slice rechaza pickup de large con log hasta este ticket)

---

### GAM-007 — CarryManager: Caída por pérdida de soporte

```
Deriva de:   §3.3 (cooperación con consecuencia) + §4.4 (timeout por definición)
Domain:      TECH
Estado:      TODO
Semana:      2
Depende de:  GAM-006
```

**Descripción**
Si el soporte sale del rango por más tiempo que `ObjectDefinition.Properties.supportTimeout`, el objeto vuelve a `free`. El timer de tolerancia es configurable por definición. El loop de verificación debe tener bajo impacto en el servidor.

**Criterios de Aceptación**
- [ ] Timer de tolerancia configurable desde `ObjectDefinition.Properties.supportTimeout`
- [ ] Si el soporte vuelve al rango antes del timeout, el carry continúa sin interrupción
- [ ] Al caer, el objeto vuelve a `free` y se dispara `ObjectStateChanged`
- [ ] El loop de verificación no genera carga innecesaria — usa `task.wait()` apropiado entre checks (§4.12: sin loops por-objeto por-frame)
- [ ] Se registra StoryEvent via `RoundManager.recordStoryEvent("SupportLost", {instanceId})`

---

### GAM-008 — Balance: Ajuste de parámetros post-playtest

```
Deriva de:   §3.2 (DI) + Hito §5.7 Semana 4 (balance post-playtest)
Domain:      TECH
Estado:      TODO
Semana:      4
Depende de:  GAM-002, GAM-003, GAM-004, GAM-005, GAM-006, GAM-007
```

**Descripción**
Ajustar los parámetros de `ObjectDefinition.Properties` y cantidades de spawn basándose en los playtests de Semana 3–4. No se añaden mecánicas nuevas.

**Criterios de Aceptación**
- [ ] Todos los parámetros ajustados están en `ObjectDefinition.Properties` o en Config — no hardcodeados en módulos
- [ ] La cantidad de objetos al spawn produce una ronda completable pero no trivial
- [ ] La velocidad reducida de objetos medium genera fricción visible
- [ ] El rango de soporte obliga cooperación real sin ser imposible de mantener
- [ ] El timeout de pérdida de soporte genera tensión sin ser injusto
- [ ] **Nota de observación (no criterio binario):** los ajustes se basan en DI observada en playtest real

---

### GAM-010 — Client Input: dispara InteractObject

```
DL-Ref:      DL-039
Deriva de:   §4.2/§4.3 (InteractObject cliente→servidor) + §3.1 (core loop) + DL-039 (completitud)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GM-001, NET-001, GAM-003
```

**Descripción**
Módulo de cliente (`src/client/InteractionController.lua` o equivalente) que captura el input del jugador y dispara `InteractObject:FireServer({instanceId})` sobre el objeto interactuable en rango/mira. Cierra el hueco detectado en QA-001: el servidor escucha `InteractObject` (CarryManager, INV-001) pero **ningún cliente lo disparaba** — el slice no era jugable. Lee estado de ClientStateManager (§4.10) para elegir el objeto objetivo; no consulta al servidor para eso.

**Criterios de Aceptación**
- [ ] Una tecla configurable (o ProximityPrompt) dispara `InteractObject:FireServer` con el `instanceId` del objeto objetivo
- [ ] El objeto objetivo se determina client-side por rango (`GlobalConfig.MAX_INTERACT_RANGE`) y/o mira, leyendo estado de ClientStateManager — sin round-trip al servidor
- [ ] El módulo **no** conecta ningún RemoteEvent servidor→cliente (INV-001; esos viven en ClientStateManager)
- [ ] Se inicializa desde `Main.client.lua` (bootstrapping, §4.1)
- [ ] Debounce/anti-spam client-side; el servidor sigue siendo la autoridad y revalida (GAM-003)
- [ ] Lune-compatible: sin acceso a `game`/`workspace` en scope de módulo (§4.6)
- [ ] Un jugador recoge y entrega un objeto small end-to-end en Studio (desbloquea QA-001)

**Notas**
Dueño del bug de QA-001. Deriva de la completitud (DL-039): el camino input→interacción era un habilitador que GAM-003 (server-side) y UI-002 ("no genera llamadas al servidor") asumían pero ninguno implementaba.

---

## Dominio: World

### WLD-000 — MapBootstrap: Harness de layout reproducible

```
DL-Ref:      DL-028
Deriva de:   Principio §2.1 (Entidades Estables) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  ninguna
```

**Descripción**
Implementar `src/server/MapBootstrap.lua`: arbitra el layout activo según `GlobalConfig.MAP_MODE` (DL-036). En `"placeholder"` genera un edificio tagueado (`ObjectSpawn`, `TruckZone`, `NPCNode`, `NPCDropZone`) y descarta la copia runtime de `Workspace/RealMap`; en `"real"` usa el layout de Studio. Hace el juego ejecutable desde `rojo serve` sin pasos manuales de Studio.

**Criterios de Aceptación**
- [ ] Genera todos los tags de contrato (§4.4): `ObjectSpawn`, `TruckZone`, `NPCNode`+`NodeIndex`, `NPCDropZone`, `LobbySpawn`, `RoundSpawn` (GM-004)
- [ ] `MAP_MODE="placeholder"` → destruye la copia runtime de `Workspace/RealMap` (si existe) y genera el placeholder
- [ ] `MAP_MODE="real"` → no genera nada; usa `Workspace/RealMap` (avisa con warning si falta)
- [ ] El edificio es navegable (2 niveles, rampa, chokepoint central) y tiene SpawnLocation
- [ ] `Main.server.lua` lo llama una vez al bootstrap

**Notas**
Implementado en PR #31. Estado real: IN_PROGRESS hasta merge. Ticket de alta retroactiva (DL-032). **Caso canónico de la Regla de derivación bajo coste-IA (§5.9):** un roadmap con supuesto humano habría dicho "haz arte mínimo en Studio"; bajo coste-IA, generar el mapa en código es más barato y mejor (versionable, reproducible, sin pasos manuales). WLD-001/WLD-002 lo reemplazan con el layout real cuando exista.

---

### WLD-001 — Edificio placeholder: Estructura navegable (Studio)

```
Deriva de:   Principio §2.1 (Compresión Social) + §3.3 + Hito §5.7 Semana 1
Domain:      TECH
Estado:      TODO
Semana:      1
Depende de:  ninguna
```

**Descripción**
Construir el edificio **real** en Studio bajo un contenedor `Workspace/RealMap` (Folder o Model) — el layout de arte que **reemplaza** el placeholder generado por WLD-000/MapBootstrap. No necesita assets finales, pero es trabajo de Studio (geometría/navegación pulida), no de código. Se activa poniendo `GlobalConfig.MAP_MODE = "real"` (DL-036) cuando esté completo. Mientras tanto se desarrolla con `"placeholder"`. Debe ser navegable, producir fricción espacial básica y tener salida clara hacia la zona del camión. Escala para 4–6 jugadores.

**Criterios de Aceptación**
- [ ] El edificio tiene al menos 2 niveles con escaleras o rampas accesibles
- [ ] Hay al menos un pasillo que produce fricción natural entre jugadores cargando objetos
- [ ] Hay una salida y zona de camión claramente identificable, con Tag `TruckZone`
- [ ] La escala funciona para 4 jugadores sin sentirse solos ni atrapados
- [ ] No hay huecos que permitan caer fuera del mapa
- [ ] Un jugador puede completar una ronda básica sin quedarse atascado
- [ ] Al cargar el place, MapBootstrap detecta el `TruckZone` real y no genera el placeholder

---

### WLD-002 — Layout: NPCNodes y NPCDropZones (Studio)

```
Deriva de:   §4.4 (contrato Layout → NPCManager) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      TODO
Semana:      1
Depende de:  WLD-001
```

**Descripción**
Colocar los nodos de tránsito de NPCs en el layout **real** de Studio (WLD-001), siguiendo el contrato de §4.4. Reemplazan los nodos que MapBootstrap genera en el placeholder. Los nodos son el contrato entre el dominio World y NPCManager. Deben existir aunque no haya NPC implementado todavía.

**Criterios de Aceptación**
- [ ] Todos los nodos tienen Tag `NPCNode` exacto
- [ ] Todos los nodos tienen Attribute `NodeIndex` con valor numérico único y consecutivo
- [ ] Hay al menos 6 nodos distribuidos por el edificio formando un recorrido lógico
- [ ] Hay al menos un Part con Tag `NPCDropZone` por cuarto principal
- [ ] NPCManager puede iterar los nodos ordenados por NodeIndex sin nil errors
- [ ] Los nodos están dentro de los límites del edificio

---

### WLD-003 — Layout final: Compresión Social

```
Deriva de:   Principio §2.1 (Compresión Social) + §3.4 (Entropía Social)
Domain:      BOTH
Estado:      TODO
Semana:      2
Depende de:  WLD-001
```

**Descripción**
Revisar y ajustar el layout para maximizar Compresión Social antes de los playtests multijugador. Evaluar cada cambio con el Test Oficial de Diseño (§2.2).

**Criterios de Aceptación**
- [ ] El layout tiene al menos 2 chokepoints donde jugadores cargando objetos se interfieren — por diseño, no por bug
- [ ] Los pasillos principales tienen ancho que obliga coordinación para pasar con un objeto large
- [ ] La ruta desde objetos hasta el camión genera tráfico cruzado
- [ ] Los NPCNodes de WLD-002 siguen siendo válidos después de los cambios (o se actualizan)
- [ ] Cada cambio supera los 5 criterios del Test Oficial de Diseño (§2.2)
- [ ] **Nota de observación:** la DI sin eventos activos se verifica en playtest de Semana 2

---

### WLD-004 — NPCManager: Movimiento con TweenService

```
Deriva de:   §4.4 (NPCManager) + §3.4 (Entropía: NPC vecino)
Domain:      TECH
Estado:      TODO
Semana:      3
Depende de:  WLD-002, GM-002
```

**Descripción**
Implementar `src/server/NPCManager.lua`. El NPC patrulla los NPCNodes en orden de NodeIndex usando exclusivamente TweenService. El NPC tiene colisión activa con jugadores. Sin PathfindingService en ningún punto del módulo.

**Criterios de Aceptación**
- [ ] El NPC se mueve entre NPCNodes en orden de `NodeIndex` usando solo TweenService
- [ ] PathfindingService no se usa en ningún punto del módulo
- [ ] `NPCManager.start()` inicia el ciclo de patrulla correctamente
- [ ] `NPCManager.stop()` detiene el movimiento sin errores — incluso si se llama durante un Tween
- [ ] `NPCManager.reset()` devuelve el NPC a posición inicial limpiamente
- [ ] El NPC bloquea el paso físicamente (colisión activa con jugadores)
- [ ] RoundManager es el único punto que llama start/stop/reset sobre NPCManager
- [ ] Al implementarse, se activa `FEATURE_FLAGS.ENABLE_NPC` (hoy `false` hasta que el módulo exista)

---

### WLD-005 — EventManager: Entropía Espacial

```
Deriva de:   §3.4 (Entropía Espacial) + §4.4 (EventManager)
Domain:      BOTH
Estado:      IN_PROGRESS
Semana:      3
Depende de:  WLD-001, GM-002
```

**Descripción**
Implementar `src/server/EventManager.lua` con al menos un evento de Entropía Espacial en el pool (ejemplo: bloqueo de pasillo, zona que ralentiza). EventManager selecciona aleatoriamente al inicio de cada ronda y notifica via `EventTriggered`. El evento modifica el entorno físico, no las mecánicas core.

**Criterios de Aceptación**
- [ ] Al menos 1 evento espacial existe en el pool en `src/shared/Config/Events.lua`
- [ ] `EventManager.triggerRandom()` selecciona y ejecuta un evento del pool
- [ ] `EventTriggered` se dispara con el `eventType` correcto
- [ ] El evento modifica el entorno de forma visible sin tutorial
- [ ] El evento supera los 5 criterios del Test Oficial de Diseño (§2.2)
- [ ] El evento no viola la Lista Prohibida (§3.5)
- [ ] `EventManager.reset()` devuelve el entorno exactamente al estado anterior — sin residuos
- [ ] Al implementarse, se activa `FEATURE_FLAGS.ENABLE_EVENTS` (hoy `false` hasta que el módulo exista)

---

### WLD-006 — EventManager: Entropía Informacional

```
Deriva de:   §3.4 (Entropía Informacional) + §4.4 (EventManager)
Domain:      BOTH
Estado:      IN_PROGRESS
Semana:      3
Depende de:  WLD-005
```

**Descripción**
Al menos un evento que modifique lo que los jugadores saben o creen, sin alterar mecánicas core. Ejemplos: objeto señuelo, información asimétrica entre jugadores. Debe generar comunicación forzada.

**Criterios de Aceptación**
- [ ] Al menos 1 evento informacional existe en el pool
- [ ] El evento no altera mecánicas core ni añade sistemas nuevos
- [ ] El evento genera al menos una instancia observable de comunicación entre jugadores
- [ ] El evento es resolvible solo comunicándose, sin conocimiento previo
- [ ] El evento supera los 5 criterios del Test Oficial de Diseño (§2.2)
- [ ] `EventManager.reset()` limpia correctamente los efectos del evento

---

### WLD-007 — Ajuste de DI post-playtest

```
Deriva de:   §3.2 (DI) + Hito §5.7 Semana 4
Domain:      BOTH
Estado:      TODO
Semana:      4
Depende de:  WLD-003, WLD-004, WLD-005, WLD-006
```

**Descripción**
Ajustar layout, nodos del NPC y pool de eventos basándose en playtests de Semana 3–4. No se añaden sistemas nuevos.

**Criterios de Aceptación**
- [ ] Cada ajuste al layout o eventos se justifica contra el Test Oficial de Diseño (§2.2)
- [ ] No se añaden sistemas nuevos — solo ajustes a elementos existentes
- [ ] Los ajustes no rompen la compatibilidad con NPCNodes ni contratos de EventManager
- [ ] **Nota de observación:** DI objetivo verificada en playtest real con 4+ jugadores

---

### WLD-008 — Prefabs de objeto: autoría de modelos

```
DL-Ref:      DL-040
Deriva de:   DL-040 (versionado de prefabs) + §4.4 (contrato Arte→PrefabRegistry, DL-031)
Domain:      TECH
Estado:      TODO
Semana:      2
Depende de:  GAM-001, FND-003
```

**Descripción**
Modelar los prefabs de objeto (al menos uno por Size: small/medium/large) como Models con Attribute `ObjectId` (nunca `.Name`, §2.4), ubicados en el archivo de modelo versionado `assets/ObjectPrefabs.rbxmx` (FND-003) que Rojo mapea a `ServerStorage/ObjectPrefabs`. No requiere assets finales de arte, pero reemplaza los placeholders que PrefabRegistry genera hoy.

**Criterios de Aceptación**
- [x] Existe al menos un Model por Size con Attribute `ObjectId` que casa con un ObjectDefinition (GAM-001)
- [x] Cada Model tiene un `root` BasePart bien definido (`PrefabRegistry.instantiate` retorna root BasePart)
- [x] Los prefabs viven en `assets/ObjectPrefabs.rbxmx`, versionado en el repo (FND-003)
- [x] `PrefabRegistry.validate()` no reporta faltantes/huérfanos/duplicados para los ObjectIds del slice
- [x] Identificación por Attribute `ObjectId`, nunca por `.Name` (§2.4)
- [ ] Arte final de calidad (mallas/texturas) — **manos humanas**, ver Notas

**Notas**
Los modelos **funcionales** (caja con cinta, sofá con respaldo/brazos/cojines, ropero con puertas/tiradores) los genera `lune/build-prefabs.luau` — juego reconocible sin bloquear el slice. El **arte final** (MeshParts, texturas, calidad visual de producto) es trabajo humano de Studio: al hacerlo, exportar y reemplazar `assets/ObjectPrefabs.rbxmx` (o migrar el generador a referenciar mallas).

---

## Dominio: UI

> **Framework: Fusion (DL-042, §4.14).** Toda UI **nueva** se construye con Fusion
> (declarativo-reactivo): deriva de `Value`s que reflejan ClientStateManager, sin
> mutar Instances a mano. UI-001 y UI-003 nacieron imperativas y se migran en
> UI-004. UI-002 (pendiente) se implementa directamente en Fusion.

### UI-001 — HUD: Timer e indicadores básicos

```
Deriva de:   §3.7 (Percepción y Feedback: contrato de estado visible) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GM-002, NET-001
```

**Descripción**
HUD con timer de ronda en formato `MM:SS` y conteo de objetos entregados. Lee estado **exclusivamente de ClientStateManager** (§4.10) — nunca conecta RemoteEvents (INV-001). Se suscribe con `timerUpdates = true` para recibir los ticks de `TimerSync` (DL-025). Usa Janitor para el lifecycle de sus recursos (§4.11). El HUD no bloquea la visión del gameplay.

**Criterios de Aceptación**
- [ ] Timer visible en formato `MM:SS` desde cualquier posición del mapa
- [ ] Conteo de objetos entregados se actualiza en tiempo real (estado de ClientStateManager)
- [ ] El HUD no ocupa el centro de pantalla ni interfiere con la visión del juego
- [ ] El timer refleja `TimerSync` sin saltos bruscos (suscripción selectiva `timerUpdates`, DL-025)
- [ ] El HUD se oculta en fase Lobby y se muestra en Active (lee `phase` de ClientStateManager)
- [ ] El módulo **no** conecta RemoteEvents — solo se suscribe a ClientStateManager (INV-001)
- [ ] La suscripción y la GUI se limpian con Janitor en `cleanup()`; la GUI sobrevive respawns (`ResetOnSpawn = false`) sin fugas

---

### UI-002 — HUD: Prompt de interacción contextual

```
Deriva de:   §3.7 (feedback: el jugador sabe qué puede interactuar)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      2
Depende de:  UI-001, GAM-002
```

**Descripción**
Prompt contextual client-side al acercarse a un objeto interactuable. Distingue visualmente entre objeto `free` y objeto `being_carried`. No genera llamadas al servidor para consultas de estado.

**Criterios de Aceptación**
- [ ] El prompt aparece cuando el jugador está dentro del rango definido en `src/shared/Config/GlobalConfig.lua`
- [ ] El prompt desaparece al alejarse o al cambiar el estado del objeto
- [ ] La representación visual distingue `free` de `being_carried` — o simplemente no aparece para `being_carried`
- [ ] El sistema corre completamente client-side sin disparar RemoteEvents para consultas
- [ ] No hay loop costoso de detección — usa distancia calculada eficientemente
- [ ] Se actualiza correctamente al recibir cambios de estado de ClientStateManager

---

### UI-003 — Summary Screen

```
Deriva de:   §3.7 (¿el Summary narra o informa?) + §3.8 (Summary prioriza eventos memorables)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      3
Depende de:  GM-002, GAM-004
```

**Descripción**
Pantalla de resumen al finalizar ronda. Muestra objetos salvados, objetos perdidos, StoryEvents de la ronda, y comentario narrativo generado por el servidor. No contiene rankings, puntuaciones ni recompensas.

**Criterios de Aceptación**
- [ ] La Summary Screen se muestra en fase Summary (estado de ClientStateManager, derivado de `RoundEnded`)
- [ ] Los datos provienen del `RoundSummary` compilado por RoundManager (payload de `RoundEnded`)
- [ ] Se muestran los StoryEvents de la ronda en lenguaje narrativo, no estadístico
- [ ] El comentario varía según el resultado (al menos 3 umbrales: bajo, medio, alto)
- [ ] La pantalla tiene transición limpia de regreso a Lobby después del tiempo definido
- [ ] Se limpia completamente antes de la siguiente ronda (Janitor)
- [ ] No contiene rankings individuales, puntuaciones por jugador ni recompensas de ningún tipo

---

### UI-004 — Adopción de Fusion: dependencia + migración

```
DL-Ref:      DL-042
Deriva de:   DL-042 (framework de UI) + §4.14 (contrato de renderizado)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      2
Depende de:  UI-001, UI-003
```

**Descripción**
Alta de la dependencia `elttob/fusion` en `wally.toml` (`[dependencies]`, realm shared) y `wally install`. Migrar `HUDManager` (UI-001) y `SummaryManager` (UI-003) del estilo imperativo (`Instance.new` + Janitor) a Fusion declarativo, estableciendo el patrón de §4.14: la UI deriva de `Value`s que un único `subscribe` a ClientStateManager actualiza. Fija el patrón de referencia para toda UI futura (UI-002 y sucesoras).

**Criterios de Aceptación**
- [ ] `elttob/fusion` está en `[dependencies]` de `wally.toml` con versión pineada; `wally install` reproduce `Packages/`
- [ ] `HUDManager` y `SummaryManager` construyen su árbol con Fusion (`New`/`Children`/`Value`/`Computed`) — sin `Instance.new` manual de labels
- [ ] Los módulos derivan de `Value`s alimentados por un único `subscribe` a ClientStateManager (§4.10) — sin mutar labels a mano
- [ ] El lifecycle usa scopes de Fusion; no quedan fugas al salir/entrar de fase (equivalente a `ResetOnSpawn=false`)
- [ ] Ningún módulo de UI conecta RemoteEvents (INV-001) — sigue leyendo solo de ClientStateManager
- [ ] StyLua/Selene/Lune-compat verdes; el HUD se comporta igual que antes (timer MM:SS, entregas, visible solo en Active)

**Notas**
Cierra el hueco de framework de UI sin decidir (DL-042). La suscripción selectiva (DL-025) se preserva: el HUD sigue siendo el único con `timerUpdates=true`.

---

## Dominio: Gameplay (Game Flow)

### GM-001 — Entry points: Main.server.lua y Main.client.lua

```
Deriva de:   §4.1 (entry points — Scripts que Roblox ejecuta) + Hito §5.7 Semana 1
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  ninguna
```

**Descripción**
Crear `src/server/Main.server.lua` y `src/client/Main.client.lua` como entry points de Roblox. Son Scripts/LocalScripts que solo hacen bootstrapping — toda la lógica vive en ModuleScripts. Main.server.lua inicializa MapBootstrap, PrefabRegistry.validate y GameManager. Main.client.lua inicializa los módulos de cliente.

**Criterios de Aceptación**
- [ ] `Main.server.lua` es un Script que hace bootstrapping (MapBootstrap, PrefabRegistry.validate, GameManager.init/start)
- [ ] `Main.client.lua` es un LocalScript que inicializa ClientStateManager y los módulos de UI
- [ ] Ninguno de los dos contiene lógica de juego — solo bootstrapping y require
- [ ] El servidor no tiene ningún Script con lógica de juego fuera de ModuleScripts
- [ ] El cliente no tiene ningún LocalScript con lógica fuera de ModuleScripts

---

### GM-002 — RoundManager: Ciclo de ronda activa

```
Deriva de:   §4.4 (RoundManager) + §4.8 (orquestación de gameplay)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  NET-001, GM-001, GAM-002, GAM-003, GAM-004
```

**Descripción**
Implementar `src/server/RoundManager.lua`. Propietario de RoundState y RoundSummary. Único módulo que llama start/stop/reset sobre módulos de gameplay. Gestiona el timer de 3 minutos. GameManager lo activa y detiene — RoundManager nunca inicia transiciones de estado global.

**Criterios de Aceptación**
- [ ] `RoundManager.start()` inicializa módulos de gameplay en orden de dependencias (§4.5) y arranca el timer
- [ ] `RoundManager.stop()` detiene módulos activos y compila `RoundSummary` desde `RoundState`
- [ ] `RoundManager.reset()` llama `reset()` sobre todos los módulos de gameplay y limpia `RoundState`
- [ ] `RoundManager.recordStoryEvent(eventType, data?)` añade un StoryEvent con `Timestamp` relativo al inicio de ronda (DL-021); descarta EventTypes no registrados en `Config/Events` (INV-003)
- [ ] `RoundState.ActiveEvent` se establece al inicio de ronda con el EventType seleccionado (nil si no hay evento)
- [ ] `RoundEnded` se dispara con `RoundSummary` serializado como payload
- [ ] RoundManager **nunca** cambia el estado global (Lobby/Active/Summary) — eso es GameManager
- [ ] El timer es la fuente única del tiempo; `TimerSync` es baja prioridad (§4.3), 1 tick por `TIMER_SYNC_INTERVAL`

---

### GM-003 — GameManager: Ciclo de vida y transiciones de estado

```
Deriva de:   §4.8 (GameManager, orquestación del ciclo de vida) + DL-020 (ciclo de sesión)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GM-002, PER-003
```

**Descripción**
Implementar `src/server/GameManager.lua`. Punto de entrada del ciclo de vida. Gestiona estados Lobby y Summary. Solo llama start/stop/reset sobre RoundManager y loadPlayer/savePlayer/releasePlayer sobre PlayerDataService (§4.4).

**Criterios de Aceptación**
- [ ] El ciclo `Lobby → Active → Summary → Lobby` funciona de inicio a fin sin intervención manual
- [ ] GameManager llama **exclusivamente** sobre RoundManager y PlayerDataService — nunca sobre módulos de gameplay directamente
- [ ] El estado global (Lobby/Active/Summary) está centralizado en GameManager y solo GameManager puede cambiarlo
- [ ] `RoundStarted` y `RoundEnded` se disparan con los payloads correctos definidos en §4.3
- [ ] `PlayerDataService.loadPlayer()` se llama al inicio de sesión del jugador (`PlayerAdded`)
- [ ] `PlayerDataService.savePlayer()` (flush) se llama al final de cada ronda — la sesión no se cierra
- [ ] `PlayerDataService.releasePlayer()` se llama al desconectarse el jugador (`PlayerRemoving`) — único punto donde se cierra la sesión
- [ ] Atribuye `ObjectsSaved`/`ObjectsSavedByType` por ObjectId (§2.4) desde los StoryEvents del summary

---

### GM-004 — Flujo de Lobby

```
DL-Ref:      DL-039
Deriva de:   §4.4 (GameManager gestiona Lobby) + §3.1 (core loop) + DL-039 (completitud)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GM-002, GM-003
```

**Descripción**
Implementar el flujo de la fase Lobby que GM-003 asume pero no detalla: los jugadores aparecen en un área de lobby (SpawnLocation de lobby distinta de la zona de ronda), y la ronda arranca por un disparador definido (timer `RoundConfig.LOBBY_DURATION` y/o mínimo de jugadores). GameManager es el dueño de la transición Lobby→Active (§4.4). El lobby "rico" del ciclo de vida (matchmaking, social, cosmético) es una decisión de diseño futura (§3.9) — este ticket cubre la habilitación mínima jugable.

**Criterios de Aceptación**
- [ ] Los jugadores aparecen en un área de Lobby identificable (SpawnLocation con Tag), separada de la zona de ronda
- [ ] La transición Lobby→Active la dispara GameManager según `RoundConfig.LOBBY_DURATION` y/o umbral de jugadores — nunca otro módulo (§4.4)
- [ ] Tras Summary, el ciclo vuelve a Lobby y puede reiniciar (§4.4, GM-003)
- [ ] El HUD se oculta en Lobby y aparece en Active (coherente con UI-001)
- [ ] Sin PathfindingService ni sistemas nuevos fuera de GameManager/RoundManager

**Notas**
El lobby completo del ciclo de vida (matchmaking real) queda como horizonte de diseño (DL-039, §3.9); este ticket es el habilitador mínimo del slice.

---

## QA transversal

> QA no es un dominio de implementación (§5.1) — es una función de Governance
> (§5.6). Estos tickets son los hitos de integración semanal, el playtest
> formal (P6) y la publicación. No tienen ownership de módulos.

### QA-001 — Integración Semana 1: Flujo básico single-player

```
Deriva de:   §3.8 (Criterios de Éxito del MVP) + Hito §5.7 Semana 1 (Pipeline P6)
Domain:      TECH
Estado:      IN_PROGRESS
Semana:      1
Depende de:  GM-003, PER-004, GAM-004, UI-001
```

**Descripción**
Verificar que un solo jugador puede completar una ronda completa de inicio a fin: spawn en Lobby → ronda activa → cargar objeto small → entregar en camión → Summary → Lobby.

**Criterios de Aceptación**
- [ ] Un jugador completa el flujo completo sin intervención manual ni reinicios
- [ ] No hay errores críticos en consola de Studio durante el flujo
- [ ] El timer finaliza la ronda automáticamente y dispara el flujo hacia Summary
- [ ] `RoundEnded` se dispara con RoundSummary serializado correctamente
- [ ] `ObjectManager.reset()` y `TruckManager.reset()` limpian correctamente al reiniciar
- [ ] PlayerData se carga al inicio y se guarda al finalizar la ronda

---

### QA-002 — Integración Semana 2: Multijugador y objetos large

```
Deriva de:   §3.3 (cooperación) + §3.8 + Hito §5.7 Semana 2 (Pipeline P6)
Domain:      TECH
Estado:      TODO
Semana:      2
Depende de:  QA-001, GAM-006, GAM-007
```

**Descripción**
Verificar que 2–4 jugadores pueden jugar simultáneamente sin conflictos de estado. Foco en objetos large con múltiples jugadores y ausencia de desyncs visibles.

**Criterios de Aceptación**
- [ ] Dos jugadores no pueden cargar el mismo objeto — el segundo intento se rechaza correctamente
- [ ] Objetos large requieren cooperación real: sin soporte en rango, el carry no inicia
- [ ] No hay desyncs visibles entre clientes durante el carry (el objeto aparece en la misma posición en ambas pantallas)
- [ ] El sistema de caída de GAM-007 funciona correctamente con jugadores reales
- [ ] Si un jugador se desconecta mientras carga un objeto, el objeto vuelve a `free` correctamente
- [ ] `ObjectManager.reset()` limpia correctamente el estado para todos los jugadores

---

### QA-003 — Playtest formal: Medición de DI con 4+ jugadores

```
Deriva de:   §3.2 (DI: criterio de avance) + §3.8 + Pipeline P6
Domain:      BOTH
Estado:      TODO
Semana:      4
Depende de:  QA-002, WLD-007, GAM-008, UI-003
```

**Descripción**
Playtest formal con al menos 4 jugadores reales. Verificar los Criterios de Éxito del MVP (§3.8). Documentar problemas encontrados y observaciones de DI.

**Criterios de Aceptación**
- [ ] El playtest se realiza con al menos 4 jugadores reales
- [ ] Los jugadores se comunican espontáneamente sin indicación externa
- [ ] Las rondas producen situaciones distintas entre sí
- [ ] El juego es entretenido sin progresión, monedas ni recompensas
- [ ] Los problemas encontrados están documentados y priorizados
- [ ] **Nota de observación:** DI objetivo (1 momento cada 10–15 segundos) verificada en sesión real

---

### QA-004 — Publicación: Deploy y verificación final

```
Deriva de:   Hito §5.7 Semana 4 (publicación) + §1.3 (shippable)
Domain:      TECH
Estado:      TODO
Semana:      4
Depende de:  QA-003
```

**Descripción**
Corregir errores críticos documentados en QA-003, optimizar rendimiento si es necesario, y publicar en Roblox. Solo correcciones — sin features nuevas.

**Criterios de Aceptación**
- [ ] No hay errores críticos en consola durante ronda completa con 4+ jugadores
- [ ] El servidor no presenta caídas de rendimiento visibles
- [ ] El juego está publicado y accesible desde la página de Roblox del proyecto
- [ ] El flujo completo `Lobby → Active → Summary → Lobby` funciona en el servidor publicado
- [ ] No se añadió funcionalidad nueva en esta semana — solo correcciones y optimizaciones
