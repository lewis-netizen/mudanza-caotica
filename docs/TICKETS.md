# TICKETS — Mudanza Caótica
**Referencia:** AI_CONTEXT_MASTER v5.4 §5.5

Los tickets están organizados por Dominio Arquitectónico (§5.1), no por responsable.
Un ticket pertenece a un dominio. Una persona puede cubrir múltiples dominios.

---

## Formato de ticket

```
ID:          [DOMINIO]-[número]
Fecha:       YYYY-MM-DD
DL-Ref:      DL-[número]
Domain:      TECH | DESIGN | BOTH
Estado:      TODO | IN_PROGRESS | DONE | BLOCKED
Semana:      1 | 2 | 3 | 4
Depende de:  [IDs de tickets requeridos antes]
Descripción: [qué implementar]
Criterios de Aceptación:
  - [ ] [condición — verificable sí/no]
Notas:       [observaciones durante implementación]
```

**Prefijos de ticket:** `NET`, `PER`, `GAM`, `WLD`, `UI` corresponden a los
dominios de implementación (§5.1). `GM-xxx` pertenece al dominio Gameplay —
es un prefijo propio solo para agrupar los tickets de GameManager (ciclo de
vida). `QA-xxx` **no es un dominio**: son hitos transversales de integración
semanal, playtest formal (P6) y publicación.

**Nota de bootstrap:** Los 30 tickets iniciales se derivaron directamente del
AI_CONTEXT_MASTER durante el bootstrap del proyecto — por eso no llevan
`DL-Ref` (ver nota equivalente en PROJECT_DECISION_LOG.md). Todo ticket nuevo
debe nacer de una entrada DECISION del Decision Log e incluir su `DL-Ref`
(§5.5 paso 5).

---

## Dominio: Networking

### NET-001 — Módulo Networking.lua: Fuente única de RemoteEvents

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  ninguna
Domain:      TECH
```

**Descripción**
Implementar `src/shared/Networking.lua` como la única fuente de referencias a RemoteEvents en el proyecto. Crear los 7 RemoteEvents en la jerarquía de Studio. Ningún otro módulo referencia RemoteEvents directamente — todos los importan desde este módulo.

**Criterios de Aceptación**
- [ ] `src/shared/Networking.lua` expone referencias a los 7 RemoteEvents definidos en §4.3
- [ ] Los 7 RemoteEvents existen en Studio: `InteractObject`, `DeliverObject`, `ObjectStateChanged`, `EventTriggered`, `RoundStarted`, `RoundEnded`, `TimerSync`
- [ ] Ningún módulo referencia `ReplicatedStorage.Remotes.*` directamente — todos usan `Networking.*`
- [ ] La dirección de cada evento (cliente→servidor o servidor→clientes) está comentada en el módulo
- [ ] El módulo no contiene lógica de juego, solo referencias

---

## Dominio: Persistence

### PER-001 — ProfileStore: Integración y configuración

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  ninguna
Domain:      TECH
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
Semana:      1
Estado:      IN_PROGRESS
Depende de:  PER-001
Domain:      TECH
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
Semana:      1
Estado:      IN_PROGRESS
Depende de:  PER-001, PER-002
Domain:      TECH
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
Semana:      1
Estado:      TODO
Depende de:  PER-003, GM-002
Domain:      TECH
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

### GAM-001 — ObjectDefinitions: Datos de objetos small/medium/large

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  ninguna
Domain:      TECH
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
Semana:      1
Estado:      IN_PROGRESS
Depende de:  NET-001, GAM-001
Domain:      TECH
```

**Descripción**
Implementar `src/server/ObjectManager.lua` con spawn aleatorio de objetos al inicio de ronda y tracking de estados por ObjectInstance. Exponer la API completa definida en §4.4.

**Criterios de Aceptación**
- [ ] Al iniciar ronda, los objetos spawnean en posiciones aleatorias dentro del edificio
- [ ] `ObjectManager.getObject(instanceId)` retorna `ObjectInstance` completo sin nil errors
- [ ] `ObjectManager.setState(instanceId, state, leaderId?, supportId?)` actualiza estado y dispara `ObjectStateChanged` con payload correcto
- [ ] `ObjectManager.reset()` elimina todos los objetos del Workspace y limpia el estado interno
- [ ] `ObjectManager.getFreeObjects()` retorna únicamente objetos en estado `free`
- [ ] No pueden existir dos ObjectInstances con el mismo InstanceId
- [ ] ObjectManager es el **único** módulo que modifica `ObjectInstance.State`

---

### GAM-003 — CarryManager: Pickup y drop (objeto small)

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  GAM-002, NET-001
Domain:      TECH
```

**Descripción**
Un jugador puede recoger y soltar un objeto small. La interacción se inicia desde el cliente vía `InteractObject`. Toda validación y cambio de estado corre server-side. El objeto sigue al jugador mientras lo carga.

**Criterios de Aceptación**
- [ ] El servidor valida `InteractObject` antes de cambiar estado — tipo, existencia, rango, estado `free`
- [ ] El objeto en `being_carried` sigue la posición del jugador server-side
- [ ] Dos jugadores no pueden cargar el mismo objeto simultáneamente
- [ ] Al soltar, el objeto queda en posición actual del jugador y vuelve a `free`
- [ ] Un jugador solo puede cargar un objeto a la vez
- [ ] El estado se refleja en todos los clientes via `ObjectStateChanged`

---

### GAM-004 — TruckManager: Zona de entrega y conteo

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  GAM-003
Domain:      TECH
```

**Descripción**
Implementar `src/server/TruckManager.lua`. Zona de entrega detectada server-side via `Part.Touched`. Al entregar, el objeto pasa a `delivered`, se dispara `DeliverObject` y se registra un StoryEvent.

**Criterios de Aceptación**
- [ ] La entrega se detecta server-side via `Part.Touched` — nunca por RemoteEvent del cliente
- [ ] `DeliverObject` se dispara con `instanceId` correcto al entregar
- [ ] `TruckManager.getDeliveredCount()` retorna conteo correcto en tiempo real
- [ ] `TruckManager.reset()` limpia el conteo sin residuos
- [ ] El objeto desaparece del Workspace al ser entregado
- [ ] Solo objetos en `being_carried` pueden entregarse — objetos `free` en la zona no cuentan
- [ ] Se registra StoryEvent via `RoundManager.recordStoryEvent("ObjectDelivered", {instanceId, objectId})`

---

### GAM-005 — CarryManager: Velocidad reducida en objetos medium

```
Semana:      2
Estado:      TODO
Depende de:  GAM-003, GAM-001
Domain:      TECH
```

**Descripción**
Cargar un objeto medium reduce el `WalkSpeed` del jugador según `ObjectDefinition.Properties.carrySpeedMultiplier`. La reducción se aplica server-side al iniciar el carry y se restaura al soltar o entregar.

**Criterios de Aceptación**
- [ ] `WalkSpeed` se reduce al recoger un objeto medium según `carrySpeedMultiplier` de la definición
- [ ] `WalkSpeed` se restaura al valor original al soltar o entregar
- [ ] El valor viene de `ObjectDefinition.Properties` — no hardcodeado en CarryManager
- [ ] La reducción no interfiere con otras modificaciones activas de velocidad
- [ ] Compatible con GAM-003 sin modificar su lógica central

---

### GAM-006 — CarryManager: Sistema líder/soporte para objetos large

```
Semana:      2
Estado:      TODO
Depende de:  GAM-003, GAM-001
Domain:      TECH
```

**Descripción**
Un objeto large requiere un jugador líder (inicia el carry) y al menos un jugador soporte en rango. El carry no comienza sin soporte. `ObjectStateChanged` incluye `leaderId` y `supportId`. Sin sincronización física entre clientes, sin Heartbeat.

**Criterios de Aceptación**
- [ ] Solo el jugador que inicia la interacción puede ser líder
- [ ] El carry no comienza si no hay soporte dentro de `ObjectDefinition.Properties.supportRange`
- [ ] `ObjectStateChanged` incluye `leaderId` y `supportId` correctamente
- [ ] El objeto se ancla al líder server-side — sin sincronización física entre clientes
- [ ] El sistema no usa Heartbeat para movimiento del objeto

---

### GAM-007 — CarryManager: Caída por pérdida de soporte

```
Semana:      2
Estado:      TODO
Depende de:  GAM-006
Domain:      TECH
```

**Descripción**
Si el soporte sale del rango por más tiempo que `ObjectDefinition.Properties.supportTimeout`, el objeto vuelve a `free`. El timer de tolerancia es configurable por definición. El loop de verificación debe tener bajo impacto en el servidor.

**Criterios de Aceptación**
- [ ] Timer de tolerancia configurable desde `ObjectDefinition.Properties.supportTimeout`
- [ ] Si el soporte vuelve al rango antes del timeout, el carry continúa sin interrupción
- [ ] Al caer, el objeto vuelve a `free` y se dispara `ObjectStateChanged`
- [ ] El loop de verificación no genera carga innecesaria — usa `task.wait()` apropiado entre checks
- [ ] Se registra StoryEvent via `RoundManager.recordStoryEvent("SupportLost", {instanceId})`

---

### GAM-008 — Balance: Ajuste de parámetros post-playtest

```
Semana:      4
Estado:      TODO
Depende de:  GAM-002, GAM-003, GAM-004, GAM-005, GAM-006, GAM-007
Domain:      TECH
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

## Dominio: World

### WLD-001 — Edificio placeholder: Estructura navegable

```
Semana:      1
Estado:      TODO
Depende de:  ninguna
Domain:      TECH
```

**Descripción**
Construir el edificio placeholder funcional en Studio. No necesita assets finales. Debe ser navegable, producir fricción espacial básica y tener salida clara hacia la zona del camión. Escala para 4–6 jugadores.

**Criterios de Aceptación**
- [ ] El edificio tiene al menos 2 niveles con escaleras o rampas accesibles
- [ ] Hay al menos un pasillo que produce fricción natural entre jugadores cargando objetos
- [ ] Hay una salida y zona de camión claramente identificable
- [ ] La escala funciona para 4 jugadores sin sentirse solos ni atrapados
- [ ] No hay huecos que permitan caer fuera del mapa
- [ ] Un jugador puede completar una ronda básica sin quedarse atascado

---

### WLD-002 — Layout: NPCNodes y NPCDropZones

```
Semana:      1
Estado:      TODO
Depende de:  WLD-001
Domain:      TECH
```

**Descripción**
Colocar los nodos de tránsito de NPCs en Studio siguiendo el contrato de §4.4. Los nodos son el contrato entre el dominio World y NPCManager. Deben existir aunque no haya NPC implementado todavía.

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
Semana:      2
Estado:      TODO
Depende de:  WLD-001
Domain:      BOTH
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
Semana:      3
Estado:      TODO
Depende de:  WLD-002, GM-002
Domain:      TECH
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

---

### WLD-005 — EventManager: Entropía Espacial

```
Semana:      3
Estado:      IN_PROGRESS
Depende de:  WLD-001, GM-002
Domain:      BOTH
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

---

### WLD-006 — EventManager: Entropía Informacional

```
Semana:      3
Estado:      IN_PROGRESS
Depende de:  WLD-005
Domain:      BOTH
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
Semana:      4
Estado:      TODO
Depende de:  WLD-003, WLD-004, WLD-005, WLD-006
Domain:      BOTH
```

**Descripción**
Ajustar layout, nodos del NPC y pool de eventos basándose en playtests de Semana 3–4. No se añaden sistemas nuevos.

**Criterios de Aceptación**
- [ ] Cada ajuste al layout o eventos se justifica contra el Test Oficial de Diseño (§2.2)
- [ ] No se añaden sistemas nuevos — solo ajustes a elementos existentes
- [ ] Los ajustes no rompen la compatibilidad con NPCNodes ni contratos de EventManager
- [ ] **Nota de observación:** DI objetivo verificada en playtest real con 4+ jugadores

---

## Dominio: UI

### UI-001 — HUD: Timer e indicadores básicos

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  GM-002, NET-001
Domain:      TECH
```

**Descripción**
HUD con timer de ronda en formato `MM:SS` y conteo de objetos entregados. El timer se sincroniza con `TimerSync`. El HUD no bloquea la visión del gameplay.

**Criterios de Aceptación**
- [ ] Timer visible en formato `MM:SS` desde cualquier posición del mapa
- [ ] Conteo de objetos entregados se actualiza en tiempo real al recibir `DeliverObject`
- [ ] El HUD no ocupa el centro de pantalla ni interfiere con la visión del juego
- [ ] `TimerSync` corrige la diferencia cliente/servidor sin saltos bruscos
- [ ] El HUD se oculta correctamente al entrar en estado Lobby
- [ ] El HUD se activa correctamente al recibir `RoundStarted`
- [ ] Las conexiones de RemoteEvents se limpian correctamente en respawn (sin memory leaks)

---

### UI-002 — HUD: Prompt de interacción contextual

```
Semana:      2
Estado:      IN_PROGRESS
Depende de:  UI-001, GAM-002
Domain:      TECH
```

**Descripción**
Prompt contextual client-side al acercarse a un objeto interactuable. Distingue visualmente entre objeto `free` y objeto `being_carried`. No genera llamadas al servidor para consultas de estado.

**Criterios de Aceptación**
- [ ] El prompt aparece cuando el jugador está dentro del rango definido en `src/shared/Config/GlobalConfig.lua`
- [ ] El prompt desaparece al alejarse o al cambiar el estado del objeto
- [ ] La representación visual distingue `free` de `being_carried` — o simplemente no aparece para `being_carried`
- [ ] El sistema corre completamente client-side sin disparar RemoteEvents para consultas
- [ ] No hay loop costoso de detección — usa distancia calculada eficientemente
- [ ] Se actualiza correctamente al recibir `ObjectStateChanged` de otro jugador

---

### UI-003 — Summary Screen

```
Semana:      3
Estado:      IN_PROGRESS
Depende de:  GM-002, GAM-004
Domain:      TECH
```

**Descripción**
Pantalla de resumen al finalizar ronda. Muestra objetos salvados, objetos perdidos, StoryEvents de la ronda, y comentario narrativo generado por el servidor. No contiene rankings, puntuaciones ni recompensas.

**Criterios de Aceptación**
- [ ] La Summary Screen se muestra al recibir `RoundEnded`
- [ ] Los datos provienen del payload de `RoundEnded` (RoundSummary compilado por RoundManager)
- [ ] Se muestran los StoryEvents de la ronda en lenguaje narrativo, no estadístico
- [ ] El comentario varía según el resultado (al menos 3 umbrales: bajo, medio, alto)
- [ ] La pantalla tiene transición limpia de regreso a Lobby después del tiempo definido
- [ ] Se limpia completamente antes de la siguiente ronda
- [ ] No contiene rankings individuales, puntuaciones por jugador ni recompensas de ningún tipo

---

## Dominio: Gameplay (Game Flow)

### GM-001 — Entry points: Main.server.lua y Main.client.lua

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  ninguna
Domain:      TECH
```

**Descripción**
Crear `src/server/Main.server.lua` y `src/client/Main.client.lua` como entry points de Roblox. Son Scripts/LocalScripts que solo hacen bootstrapping — toda la lógica vive en ModuleScripts. Main.server.lua inicializa GameManager. Main.client.lua inicializa los módulos de cliente.

**Criterios de Aceptación**
- [ ] `Main.server.lua` es un Script que requiere GameManager y llama su inicialización
- [ ] `Main.client.lua` es un LocalScript que requiere los módulos de cliente
- [ ] Ninguno de los dos contiene lógica de juego — solo bootstrapping y require
- [ ] El servidor no tiene ningún Script con lógica de juego fuera de ModuleScripts
- [ ] El cliente no tiene ningún LocalScript con lógica fuera de ModuleScripts

---

### GM-002 — RoundManager: Ciclo de ronda activa

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  NET-001, GM-001, GAM-002, GAM-003, GAM-004
Domain:      TECH
```

**Descripción**
Implementar `src/server/RoundManager.lua`. Propietario de RoundState y RoundSummary. Único módulo que llama start/stop/reset sobre módulos de gameplay. Gestiona el timer de 3 minutos. GameManager lo activa y detiene — RoundManager nunca inicia transiciones de estado global.

**Criterios de Aceptación**
- [ ] `RoundManager.start()` inicializa módulos de gameplay en orden de dependencias (§4.5) y arranca el timer
- [ ] `RoundManager.stop()` detiene módulos activos y compila `RoundSummary` desde `RoundState`
- [ ] `RoundManager.reset()` llama `reset()` sobre todos los módulos de gameplay y limpia `RoundState`
- [ ] `RoundManager.recordStoryEvent(eventType, data?)` añade un StoryEvent a `RoundState.StoryEvents`
- [ ] `RoundState.ActiveEvent` se establece al inicio de ronda con el EventType seleccionado
- [ ] `RoundEnded` se dispara con `RoundSummary` serializado como payload
- [ ] RoundManager **nunca** cambia el estado global (Lobby/Active/Summary) — eso es GameManager
- [ ] GameManager **nunca** llama start/stop/reset sobre módulos de gameplay directamente

---

### GM-003 — GameManager: Ciclo de vida y transiciones de estado

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  GM-002, PER-003
Domain:      TECH
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

---

## QA transversal

> QA no es un dominio de implementación (§5.1) — es una función de Governance
> (§5.6). Estos tickets son los hitos de integración semanal, el playtest
> formal (P6) y la publicación. No tienen ownership de módulos.

### QA-001 — Integración Semana 1: Flujo básico single-player

```
Semana:      1
Estado:      IN_PROGRESS
Depende de:  GM-003, PER-004, GAM-004, UI-001
Domain:      TECH
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
Semana:      2
Estado:      TODO
Depende de:  QA-001, GAM-006, GAM-007
Domain:      TECH
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
Semana:      4
Estado:      TODO
Depende de:  QA-002, WLD-007, GAM-008, UI-003
Domain:      BOTH
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
Semana:      4
Estado:      TODO
Depende de:  QA-003
Domain:      TECH
```

**Descripción**
Corregir errores críticos documentados en QA-003, optimizar rendimiento si es necesario, y publicar en Roblox. Solo correcciones — sin features nuevas.

**Criterios de Aceptación**
- [ ] No hay errores críticos en consola durante ronda completa con 4+ jugadores
- [ ] El servidor no presenta caídas de rendimiento visibles
- [ ] El juego está publicado y accesible desde la página de Roblox del proyecto
- [ ] El flujo completo `Lobby → Active → Summary → Lobby` funciona en el servidor publicado
- [ ] No se añadió funcionalidad nueva en esta semana — solo correcciones y optimizaciones
