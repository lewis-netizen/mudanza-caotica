# AI_CONTEXT_MASTER — Mudanza Caótica

**Versión:** 5.6 | **Plataforma:** Roblox | **Plazo:** vertical slice completo al **2026-08-11** (reloj reiniciado el 2026-07-11 — DL-024)

Este documento es la **única fuente de verdad** del proyecto. Los agentes deben leerlo completo antes de responder cualquier petición. No existe documento externo que lo complemente o contradiga.

---

## 1. Filosofía del Proyecto

### 1.1 Visión

Mudanza Caótica es un juego cooperativo multijugador en Roblox donde un grupo de jugadores vacía un edificio transportando objetos al camión antes de que termine el tiempo.

**La profundidad no viene de mecánicas complejas. Viene de la interacción humana, la coordinación imperfecta y las situaciones emergentes.**

### 1.2 Parámetros del Juego

| Parámetro | Valor |
|---|---|
| Objetivo de ronda | Salvar el mayor número de objetos antes de que el camión se vaya |
| Duración de ronda | 3 minutos |
| Condición de derrota | No existe. El resultado refleja cuánto logró el equipo |
| Jugadores objetivo | 4–6 |

### 1.3 Definición de MVP

Este MVP es shippable. No es una validación de gameplay — es la base del producto, diseñada para adquisición de jugadores, medición de retención y evolución continua. La persistencia, el versionado de datos y las migraciones son infraestructura fundamental, no features futuras.

**Estándar de calidad (DL-024):** el juego debe ser profesionalmente funcional desde su primera versión pública. "Mínimo" se refiere al alcance (un mapa, las mecánicas core), nunca a la calidad de ejecución. La misma filosofía aplica a la arquitectura: se invierte el esfuerzo de diseño ahora para maximizar mantenibilidad, escalabilidad y comodidad de desarrollo futuro — no se acepta deuda estructural a cambio de velocidad de entrega.

---

## 2. Fundamentos Transversales

### 2.1 Principios Congelados

Estos principios no se debaten. Toda idea que contradiga cualquiera de ellos es rechazada sin excepción.

| Principio | Definición |
|---|---|
| Dependencia Social | Las tareas importantes deben beneficiarse significativamente de la cooperación. |
| Entropía Social | Cada partida produce situaciones distintas sin modificar el objetivo principal. |
| Objetivo Estable | Los jugadores siempre saben qué hacer. El objetivo nunca cambia. |
| Contexto Variable | Las condiciones cambian. El objetivo no. |
| Simplicidad Mecánica | La profundidad surge de sistemas simples interactuando. |
| Presión Situacional | El reto surge del contexto, no de aprender nuevas mecánicas. |
| Interacción Humana como Contenido | Los jugadores son el contenido principal del juego. |
| Complejidad Justificada | Toda complejidad debe aumentar la interacción social o las situaciones emergentes. |
| Fricción Social | La mejor fricción ocurre entre jugadores, no entre jugador y sistema. |
| Compresión Social | El espacio debe aumentar la frecuencia con la que los jugadores interfieren entre sí. |
| Entidades Estables | Diseñar alrededor de entidades (Player, Object, Map, Content), no alrededor de nombres, archivos o features concretas. |
| Expresión sobre Ventaja | La monetización futura debe derivar de expresión personal y creación, no de ventaja competitiva. |
| Jugadores como Fuente de Contenido | El valor a largo plazo proviene de convertir a los jugadores en contenido para otros jugadores, mediante interacción o creación. |
| Modelo de Tres Niveles | Toda decisión arquitectónica pertenece a uno de tres niveles: Entidades (qué existe), Sistemas (qué hace cosas), Persistencia (qué sobrevive entre sesiones). |

### 2.2 Test Oficial de Diseño

Toda idea nueva debe superar los cinco criterios. Si falla uno, no entra al MVP.

1. ¿Aumenta la Dependencia Social?
2. ¿Aumenta la Entropía (espacial o informacional)?
3. ¿Mantiene la Simplicidad Mecánica?
4. ¿Genera interacción entre jugadores más que entre jugador y sistema?
5. ¿Respeta las entidades fundamentales definidas en §2.3?

### 2.3 Entidades Fundamentales

Toda funcionalidad presente o futura debe derivarse de una de estas cuatro entidades.

**Player** — Representa un jugador activo.
```
Player = { PlayerId }
```

**Object** — Identidad y apariencia son separadas.
```
ObjectDefinition = {
    ObjectId,
    Size,         -- small | medium | large
    Properties    -- velocidades, rangos, timeouts
}

ObjectInstance = {
    InstanceId,
    ObjectId,     -- referencia a ObjectDefinition
    State,        -- free | being_carried | delivered
    LeaderId,     -- jugador que inició el carry; nil si State != being_carried
    SupportId     -- soporte activo; nil si el objeto no es large o no tiene soporte
}
```

**Map** — Representa un escenario de juego.
```
Map = {
    MapId,
    Name
}
```
Map existe como entidad estable. El MVP utiliza exactamente una instancia de Map.

**Content** — Creación visible generada por un jugador.
No implementado en MVP. Reservado para escalabilidad futura.
```
Content = {
    ContentId,
    CreatorId,
    ContentType
}
```

### 2.4 Regla de Entidades

Ningún sistema puede acoplarse a un valor concreto de nombre de objeto, mapa o tipo. La lógica opera sobre IDs y propiedades.

```lua
-- Prohibido
if object.Name == "Piano" then

-- Prohibido
SavedPianos += 1

-- Correcto
ObjectsSavedByType[object.ObjectId] += 1
```

### 2.5 PlayerData — Contrato Canónico

PlayerData existe desde el MVP porque este es un producto shippable. Los dominios son contenedores estables; su contenido puede estar vacío pero su estructura no puede cambiar sin migración.

**Criterio de inclusión:** ¿Qué información perdería valor real para el jugador si desapareciera mañana?

```lua
PlayerData = {
    Version = 1,

    Profile = {
        FirstJoinDate,
        LastJoinDate
    },

    Stats = {
        TimePlayed,
        MatchesStarted,
        MatchesCompleted,
        ObjectsSaved,
        ObjectsSavedByType = {}   -- indexado por ObjectId, no por nombre
    },

    Identity = {
        Titles    = {},           -- reservado
        Cosmetics = {},           -- reservado
        Auras     = {}            -- reservado
    },

    Creation = {
        -- reservado para sistemas UGC futuros
    },

    Settings = {
        MusicVolume,
        SFXVolume
    }
}
```

**Regla de dominios reservados:** Los dominios `Identity`, `Creation` y cualquier dominio marcado como reservado no pueden utilizarse hasta que exista una especificación oficial aprobada por el Product Owner.

---

## 3. Design Architecture

### 3.1 Core Loop

Un grupo de jugadores vacía un edificio transportando objetos al camión antes de que termine el tiempo. El objetivo es siempre el mismo. Las condiciones cambian cada ronda.

```
Ronda inicia
↓
Jugadores exploran el edificio
↓
Identifican objetos y coordinan transporte
↓
Transportan objetos al camión (cooperación activa para objetos grandes)
↓
NPC vecino y eventos generan fricción situacional
↓
Timer llega a cero → camión se va
↓
Summary Screen muestra lo que ocurrió
↓
Nueva ronda
```

### 3.2 Densidad de Interacción (DI)

**Pregunta:** ¿Cada cuánto tiempo ocurre algo que provoque comunicación, coordinación, improvisación o reacción entre jugadores?

**Objetivo MVP:** DI media-alta. Un momento significativo cada 10–15 segundos.

Esta métrica es el criterio de avance entre semanas del Roadmap. No se avanza hasta que la DI objetivo esté confirmada en playtest real.

### 3.3 Dependencia Social y Cooperación

Las tareas importantes deben beneficiarse significativamente de la cooperación. El diseño prioriza situaciones donde ayudarse mutuamente produce resultados mejores que actuar solo.

Los objetos grandes (large) son el mecanismo principal de cooperación forzada: requieren un líder que ancla el objeto y un soporte que debe mantenerse en rango. Esto no es opcional — es estructural.

### 3.4 Entropía Social

Cada partida debe producir situaciones distintas sin modificar el objetivo principal. La variabilidad emerge de:
- Distribución de objetos en el edificio
- Selección aleatoria de evento por ronda
- Comportamiento del NPC vecino
- Decisiones y errores de los jugadores

### 3.5 Progresión — Prohibiciones y Distinciones

**Prohibido en el MVP:**
- Progresión que afecte el gameplay: niveles, XP, stats que otorguen ventaja competitiva
- Monedas, economía o tienda de cualquier tipo
- Gacha, coleccionismo o loot boxes
- Ranking competitivo o matchmaking serio
- Achievements con recompensas
- Múltiples mapas
- Objetos con valores de puntos distintos (Regla de Neutralidad de Objetos)
- Mecánicas que solo afectan al jugador individual, no al grupo
- Cualquier forma de castigo por fallar

**Distinción importante:** Las estadísticas históricas (TimePlayed, ObjectsSaved) no son progresión prohibida. Son infraestructura de producto requerida. Lo prohibido es usar esas estadísticas para otorgar ventaja en el gameplay.

**Permitido en el futuro (no en el MVP):**
- Cosméticos y expresión personal
- Contenido creado por jugadores
- Mercados de creadores
- Sistemas basados en la entidad Content

### 3.6 Monetización Ética

Toda monetización futura debe surgir principalmente de Identidad y Creación. Nunca de ventaja en el Gameplay.

### 3.7 Percepción y Feedback

Esta subsección define los contratos de UX del juego. Es la base para el dominio UX Design y para la auditoría objetiva de UI.

**Principios de feedback:**
Los tres principios siguientes deben responderse antes de implementar cualquier elemento de UI:
- ¿El jugador siempre sabe el estado de un objeto que no está viendo?
- ¿La UI debe reflejar el caos o mitigarlo?
- ¿El Summary Screen narra o informa?

**Contrato de estado visible:**
Qué información del estado del juego es legible por el cliente en cada momento. Se construye sobre los RemoteEvents de §4.3, formalizados desde la perspectiva del jugador.

**Contratos de evaluación UX:**
No son heurísticas genéricas. Son contratos observables con condición verificable (sí/no). El mecanismo: el UX Designer convierte un principio de feedback en una condición binaria. El auditor verifica el contrato, no el gusto.

Ejemplo:
- Principio: "el jugador debe saber el tiempo restante al entrar a la partida"
- Contrato: "el indicador de tiempo es visible y se actualiza dentro de los primeros 2 segundos de spawn"
- Auditoría: ¿Existe el indicador? ¿Es visible? ¿Se actualiza? → Sí/No

**Nota de escalabilidad:** Esta subsección puede promoverse a §4 independiente si UI crece en complejidad post-MVP.

### 3.8 Criterios de Éxito del MVP

- Los jugadores se comunican espontáneamente.
- Los objetos grandes generan coordinación activa.
- El edificio produce interferencias frecuentes entre jugadores.
- Las rondas generan historias y situaciones distintas.
- DI observada: un momento significativo cada 10–15 segundos.
- El juego es entretenido sin progresión, monedas ni recompensas artificiales.
- El Summary Screen prioriza eventos memorables y situaciones emergentes sobre puntuaciones o recompensas.
- Los datos del jugador sobreviven entre sesiones desde el primer día.
- La arquitectura permite añadir nuevas categorías de contenido sin rehacer sistemas existentes.

### 3.9 Visión a Largo Plazo

El MVP valida el gameplay y establece la infraestructura base. Las actualizaciones futuras deben fortalecer al menos uno de estos tres dominios:

1. **Gameplay** — nuevas mecánicas de cooperación, mapas, objetos
2. **Identidad** — cosméticos, expresión personal, títulos
3. **Creación** — herramientas para que los jugadores creen contenido para otros

---

## 4. Technical Architecture

### 4.1 Infraestructura de Repositorio

**Tabla de mapeo Rojo → Runtime Roblox**

Derivada de `default.project.json`. Esta tabla es la fuente de verdad para la estructura del proyecto.

| Rojo (repo) | Roblox (runtime) | Clase Roblox |
|---|---|---|
| `src/server/` | `ServerScriptService/Systems/` | ServerScriptService |
| `src/shared/` | `ReplicatedStorage/Shared/` | ReplicatedStorage |
| `src/shared/Lib/` | `ReplicatedStorage/Shared/Lib/` | ReplicatedStorage |
| `src/client/` | `StarterPlayer/StarterPlayerScripts/` | StarterPlayer |
| `src/gui/` | `StarterGui/` | StarterGui |
| `Packages/` | `ReplicatedStorage/Packages/` | ReplicatedStorage |

**Estructura canónica del repo (`src/`):**

```
src/
├── server/                          → ServerScriptService/Systems/
│   ├── Main.server.lua              (Script — entry point del servidor)
│   ├── GameManager.lua
│   ├── RoundManager.lua
│   ├── ObjectManager.lua
│   ├── CarryManager.lua
│   ├── TruckManager.lua
│   ├── PrefabRegistry.lua            (resuelve ObjectId → asset — DL-031)
│   ├── MapBootstrap.lua              (edificio placeholder — DL-028)
│   ├── NPCManager.lua
│   ├── EventManager.lua
│   └── Persistence/
│       ├── PlayerDataService.lua
│       ├── MigrationService.lua
│       └── ProfileStoreConfig.lua
│
├── shared/                          → ReplicatedStorage/Shared/
│   ├── Lib/
│   │   ├── Logger.lua               (prerequisito de todo — se implementa primero)
│   │   └── Networking.lua           (fuente única de referencias a RemoteEvents)
│   ├── Entities/
│   │   ├── Player/
│   │   │   ├── Player.lua
│   │   │   └── PlayerData.lua
│   │   ├── Object/
│   │   │   └── Object.lua
│   │   ├── Map/
│   │   │   └── Map.lua
│   │   └── Content/
│   │       └── README.lua           -- Reserved. Not implemented in MVP.
│   ├── Definitions/
│   │   ├── Objects/                 -- ObjectDefinition por cada tipo
│   │   ├── Maps/                    -- MapDefinition por cada mapa (MVP: uno)
│   │   └── Content/                 -- Reserved. Not implemented in MVP.
│   ├── Config/
│   │   ├── Events.lua               -- StoryEvent schema + pool de EventDefinitions
│   │   ├── GameplayConfig.lua       -- NPC_SPEED, OBJECT_COUNTS, MIN_SPAWN_DISTANCE
│   │   ├── RoundConfig.lua          -- ROUND_DURATION, SUMMARY_DURATION, LOBBY_DURATION
│   │   └── GlobalConfig.lua         -- LOG_LEVEL, FEATURE_FLAGS, IS_STUDIO,
│   │                                   MAX_INTERACT_RANGE, TIMER_SYNC_INTERVAL
│   ├── Types/
│   ├── Constants/
│   │   ├── ObjectState.lua          -- estados de wire: free/being_carried/delivered
│   │   └── RoundPhase.lua           -- fases globales: Lobby/Active/Summary
│   └── Tests/                       -- specs de TestEZ, convención: [Módulo].spec.lua
│       ├── MigrationService.spec.lua
│       ├── ObjectManager.spec.lua
│       └── PlayerDataService.spec.lua
│
├── client/                          → StarterPlayer/StarterPlayerScripts/
│   ├── Main.client.lua              (LocalScript — entry point del cliente)
│   └── ClientStateManager.lua       (única fuente de estado del juego en cliente)
│
└── gui/                             → StarterGui/
```

**Nota sobre entry points:** `Main.server.lua` y `Main.client.lua` son Scripts y LocalScripts respectivamente — los únicos archivos que Roblox ejecuta automáticamente. Los demás módulos son ModuleScripts que no se ejecutan solos. Main requiere los módulos correspondientes y actúa como punto de arranque.

**Principio de clasificación de archivos:**

| Pregunta | Destino |
|---|---|
| ¿Es infraestructura transversal sin categoría de negocio? | `Lib/` |
| ¿Qué existe en el mundo del juego? | `Entities/` |
| ¿Cómo es esa entidad? (datos concretos) | `Definitions/` |
| ¿Cómo se comporta un sistema? | `Config/` |
| ¿Quién ejecuta el comportamiento? | `src/server/` |
| ¿Cuál es el asset real en el servidor? | `ServerStorage/ObjectPrefabs` (fuera de Rojo) — resuelto por PrefabRegistry (§4.4, DL-031) |

**Distinción Entities vs Definitions:**
- `Entities/` contiene los módulos de lógica y los contratos de tipo de cada entidad.
- `Definitions/` contiene los datos concretos del juego que conforman esos tipos.

### 4.2 Modelo Cliente-Servidor

```
Cliente (LocalScript)        Servidor (Script)
─────────────────────        ─────────────────
Input del jugador      →     Estado del juego
UI / HUD               ←     Lógica de objetos
                             NPC
                             Eventos
                             Persistencia
                             Resultados
```

**Autoridad física:** La autoridad física de los objetos transportables pertenece al servidor.

### 4.3 RemoteEvents y Contratos

| Evento | Grupo | Dirección | Payload |
|---|---|---|---|
| InteractObject | Gameplay | cliente → servidor | `{ instanceId }` |
| DeliverObject | Gameplay | servidor → clientes | `{ instanceId }` |
| ObjectStateChanged | Gameplay | servidor → clientes | `{ instanceId, objectId, state, leaderId, supportId }` |
| EventTriggered | Round | servidor → clientes | `{ eventType }` |
| RoundStarted | Round | servidor → clientes | `{ duration, eventType? }` — eventType nil si no hay evento activo |
| RoundEnded | Round | servidor → clientes | RoundSummary serializado |
| TimerSync | Round | servidor → clientes | `{ timeRemaining }` — baja prioridad |

Solo `InteractObject` viaja de cliente a servidor. Su única conexión
server-side (`OnServerEvent:Connect`) vive en `CarryManager.lua` — ver INV-001.
`DeliverObject` es disparado por el servidor via `Part.Touched` server-side.

**Autoridad de estado:** ObjectManager es el único propietario de `ObjectInstance.State`. Ningún otro módulo modifica el estado directamente — todos solicitan el cambio a ObjectManager.

**Regla de RemoteEvents:** No más de 7 RemoteEvents sin aprobación del Product Owner.

### 4.4 Módulos del Servidor y APIs

| Módulo | Nivel | Responsabilidad |
|---|---|---|
| Logger | Shared | Logging estructurado. Prerequisito de todo módulo. Niveles DEBUG/INFO/WARN/ERROR. Nivel mínimo desde GlobalConfig.LOG_LEVEL. |
| GameManager | Sistema | Punto de entrada del ciclo de vida. Gestiona estados Lobby y Summary. |
| RoundManager | Sistema | Gestiona la ronda activa. Propietario de RoundState y RoundSummary. |
| ObjectManager | Sistema | Spawn, estados y tracking de ObjectInstances. No mueve objetos. Delega la resolución ObjectId → asset en PrefabRegistry. |
| CarryManager | Sistema | Lógica de transporte. Líder ancla objeto; soporte debe mantenerse en rango. |
| TruckManager | Sistema | Zona de entrega, conteo de objetos salvados, datos para resumen. |
| PrefabRegistry | Sistema | Única capa que conoce `ServerStorage/ObjectPrefabs`. Resuelve `ObjectId → prefab` (o placeholder si falta). `validate()` audita el contrato al bootstrap (§4.4, DL-031). |
| NPCManager | Sistema | TweenService sobre nodos predefinidos. Sin PathfindingService. |
| EventManager | Sistema | Selecciona y ejecuta un evento aleatorio por ronda desde un pool. |
| MapBootstrap | Sistema | Genera un edificio placeholder tagueado si el Workspace no contiene layout (flag ENABLE_PLACEHOLDER_MAP). Se retira cuando exista el layout real de WLD-001+. |
| PlayerDataService | Persistencia | Wrapper delgado sobre ProfileStore (externo). Aplica MigrationService al cargar y expone el schema canónico de PlayerData. |
| ClientStateManager | Cliente | Única fuente de estado del juego en el cliente. Conecta todos los RemoteEvents. Los módulos de UI leen de él. |

**API — ObjectManager:**
```lua
ObjectManager.initialize()
ObjectManager.reset()
ObjectManager.getObject(instanceId)      -- retorna ObjectInstance
ObjectManager.getObjectPart(instanceId)  -- retorna Part en Workspace
ObjectManager.setState(instanceId, state, leaderId?, supportId?)
ObjectManager.getFreeObjects()           -- retorna [ instanceId, ... ]
ObjectManager.getAllObjects()            -- retorna ObjectInstance[]
ObjectManager.getDeliveredCount()        -- retorna number
```

**API — GameManager → módulos:**

El ciclo de sesión de PlayerData está atado al **jugador** (join/leave), no al
ciclo de ronda. Cerrar la sesión de ProfileStore en transiciones de ronda
invalidaría su session locking y auto-save con el jugador aún conectado (§4.7).

```lua
-- Al unirse el jugador (PlayerAdded) — independiente del ciclo de ronda
PlayerDataService.loadPlayer(player)      -- StartSessionAsync + migración

-- Transición Lobby → Active
RoundManager.start()

-- Transición Active → Summary
RoundManager.stop()
PlayerDataService.savePlayer(player)      -- Profile:Save() — flush explícito.
                                          -- La sesión NO se cierra aquí.

-- Transición Summary → Lobby
RoundManager.reset()

-- Al salir el jugador (PlayerRemoving)
PlayerDataService.releasePlayer(player)   -- Profile:EndSession()
                                          -- ProfileStore guarda al cerrar.
```

**API — RoundManager → módulos de gameplay:**
```lua
-- Al iniciar ronda
ObjectManager.initialize()
CarryManager.start()
TruckManager.start()
NPCManager.start()
EventManager.triggerRandom()

-- Al detener ronda
CarryManager.stop()
NPCManager.stop()

-- Al resetear
ObjectManager.reset()
CarryManager.reset()
TruckManager.reset()
NPCManager.reset()
EventManager.reset()
```

**API — RoundManager pública:**
```lua
RoundManager.start()
RoundManager.stop()
RoundManager.reset()
RoundManager.recordStoryEvent(eventType, data?)
RoundManager.getTimeRemaining()   -- retorna number (segundos restantes)
```

**RoundState — datos temporales de ronda:**
```lua
RoundState = {
    SavedObjects,
    LostObjects,
    ActiveEvent,
    StoryEvents
}
```

**RoundSummary — contrato:**
```lua
RoundSummary = {
    SavedObjects,
    LostObjects,
    ClientComment,
    StoryEvents  -- [ StoryEvent ]
}

-- StoryEvent = { EventType, Data, Timestamp }
-- EventType:  string — identificador registrado en Shared/Config/Events
-- Data:       table opcional — usa instanceId o ObjectId, nunca strings literales
-- Timestamp:  number — segundos transcurridos desde RoundStarted, calculado
--             por RoundManager (fuente única del timer). No usar os.clock():
--             es tiempo de CPU del VM, no apto para timestamps de gameplay.
```

**Contrato Layout → NPCManager:**
```
Tag "NPCNode"     + Attribute "NodeIndex" (number)
Tag "NPCDropZone" — al menos uno por cuarto
```

**Contrato Layout → Gameplay (DL-028):**
```
Tag "ObjectSpawn" — Parts marcadores de posición de spawn de objetos.
                    ObjectManager elige aleatoriamente entre ellos.
Tag "TruckZone"   — Part de la zona de entrega. TruckManager conecta
                    su Touched server-side.
```
Los Parts de objetos spawneados llevan Attributes `InstanceId` y `ObjectId`
(strings) — nunca se identifica un objeto por `.Name` (§2.4).

**Contrato Arte → PrefabRegistry (DL-031):**

Cierra el hueco entre `ObjectDefinition` (identidad y datos) y el asset real:
la resolución `ObjectId → prefab` vive en **una sola capa** (`PrefabRegistry`),
no en `ObjectManager`. `ObjectDefinition` nunca referencia un modelo — el
desacoplamiento entre datos y apariencia (§2.3) se preserva.

```
ServerStorage/ObjectPrefabs/          ← Folder poblado por arte en Studio
  <Model | BasePart>                  ← un prefab por tipo de objeto
    Attribute "ObjectId" (string)     ← igual a ObjectDefinition.ObjectId
```

Reglas:
- Identificación **siempre** por Attribute `ObjectId`, nunca por `.Name` (§2.4).
- Un `Model` debe tener `PrimaryPart` (raíz física del carry) y sus demás
  `BasePart` soldadas a ella, sin anclar. Un prefab `BasePart` suelto es su
  propia raíz.
- **Prefab ausente → placeholder generado** (dimensiones/color por Size desde
  `GameplayConfig.PLACEHOLDER_OBJECT_*`): el arte puede llegar después del
  código sin romper rondas.
- `PrefabRegistry.validate()` corre al bootstrap (`Main.server.lua`) y reporta
  faltantes, huérfanos, duplicados e inválidos — los errores de contrato
  aparecen al arrancar el servidor, nunca a mitad de partida.

API: `resolve(objectId) → template?` · `instantiate(def) → (top, root, isPlaceholder)`
· `validate() → (ok, issues)` · `refresh()`. `top` es la instancia a
parentar/destruir (Part o Model); `root` es el `BasePart` raíz para física y
welds. `ObjectManager` guarda ambos; `getObjectPart` devuelve `root`.

### 4.5 Orden de Construcción por Dependencias

```
Nivel -1 — prerequisito absoluto (antes de todo)
  Logger | GlobalConfig

Nivel 0 — en paralelo
  ObjectDefinitions | PrefabRegistry | Networking | Layout/Edificio | ProfileStore (externo, sin código propio)

Nivel 1 — dependen del nivel 0
  ObjectManager (usa PrefabRegistry + ObjectDefinitions)

Nivel 2 — dependen del nivel 1
  CarryManager | TruckManager | NPCManager | EventManager | PlayerDataService | MigrationService

Nivel 3 — depende del nivel 2
  RoundManager

Nivel 4 — depende de todo
  GameManager
```

### 4.6 Prohibiciones Técnicas

- PathfindingService para el NPC
- Sincronización física entre clientes para objetos grandes
- Primera persona
- Heartbeat para mover objetos grandes entre dos clientes
- Más de 7 RemoteEvents sin aprobación del Product Owner
- Lógica basada en `object.Name` o `map.Name` como strings literales
- Estadísticas hardcodeadas por tipo de objeto
- Sistemas que mezclen identidad con apariencia
- Acoplamiento que impida añadir un nuevo ObjectDefinition sin modificar lógica existente
- Código malicioso, exploits, o vulnerabilidades intencionales
- `Networking.*:Connect()` fuera de sus dos puntos únicos (INV-001):
  `OnClientEvent` solo en `ClientStateManager.lua` (cliente);
  `OnServerEvent` solo en `CarryManager.lua` (servidor — InteractObject es
  el único evento cliente→servidor)
- `sound:Play()` o efectos VFX llamados directamente desde módulos de gameplay (INV-002)
- EventTypes en `recordStoryEvent()` no registrados en `Config/Events.lua` (INV-003)
- Valores de configuración hardcodeados en módulos — deben venir de `Config/` (INV-004)
- Acceso a globals de Roblox (`game`, `workspace`, `Players`, `script.Parent`, etc.)
  en el scope de módulo (nivel de archivo) — deben estar dentro de funciones
  para garantizar compatibilidad con Lune. Esto se llama **inyección de dependencias**
  (Dependency Injection) — las dependencias se pasan como parámetros en lugar de
  accederse globalmente. Verificable con `lune run lune/check-compatibility.luau`.

### 4.7 Persistencia y Migraciones

**ProfileStore** (paquete externo, `lm-loleris/profilestore@1.0.3`) es la única capa que interactúa directamente con DataStores. Maneja session locking, retry con backoff, y auto-save internamente. Ningún código propio del proyecto reimplementa esta lógica — reimplementarla a mano es el tipo de trabajo que produce bugs severos y poco frecuentes (pérdida o rollback de datos del jugador).

**PlayerDataService** es un wrapper delgado sobre ProfileStore. Su responsabilidad es exclusivamente de dominio: aplicar `MigrationService.migrate()` a los datos cargados, y exponer el schema canónico de PlayerData (§2.5) al resto del proyecto. No reimplementa retry ni session locking — eso es responsabilidad de ProfileStore.

**Ciclo de sesión (API mínima de PlayerDataService):**
```
loadPlayer(player)     → StartSessionAsync + migrate. En PlayerAdded.
savePlayer(player)     → Profile:Save() — flush explícito. Al final de ronda.
                         Nunca cierra la sesión.
getData(player)        → Profile.Data en memoria. Sin operación de red.
releasePlayer(player)  → Profile:EndSession(). Solo en PlayerRemoving.
```
La sesión vive mientras el jugador está conectado — nunca se cierra por
transiciones de ronda.

**MigrationService** detecta la versión de PlayerData al cargar y aplica las migraciones necesarias. Esto sigue siendo lógica específica del proyecto — ProfileStore no migra schemas, solo gestiona el ciclo de vida del DataStore.

La versión actual de PlayerData es `Version = 1`. Cualquier cambio al schema requiere incrementar la versión y añadir una migración en MigrationService.

**Invariante:** ProfileStore vive exclusivamente en `[server-dependencies]` de `wally.toml` — nunca se requiere desde el cliente. La persistencia es responsabilidad exclusiva del servidor (§4.2).

### 4.8 Ownership y Autoridad de Estado

**Regla de orquestación:** GameManager es el punto de entrada del ciclo de vida. Llama start/stop/reset únicamente sobre RoundManager y PlayerDataService. RoundManager llama start/stop/reset sobre los módulos de gameplay durante la ronda activa. Ningún otro módulo inicia transiciones de ciclo de vida.

**ObjectManager** es el único propietario de `ObjectInstance.State`. Todos los módulos solicitan cambios de estado a ObjectManager — nunca los modifican directamente.

**Autoridad física** de objetos transportables: servidor únicamente.

### 4.9 Audio Convention

AudioManager no se implementa en el MVP hasta Semana 3. Esta sección define la convención que todos los módulos deben respetar ahora para evitar retrofit cuando exista.

**Invariante:** ningún módulo de gameplay dispara sonidos directamente. Todo audio reacciona a eventos — nunca a lógica de gameplay.

```
PROHIBIDO:
  -- En CarryManager, TruckManager, ObjectManager, etc.
  sound:Play()  -- acoplamiento directo gameplay → audio

CORRECTO:
  -- AudioManager (Semana 3) conectará:
  Networking.DeliverObject.OnClientEvent → sonido de entrega
  Networking.ObjectStateChanged → sonido de pickup/drop
  Networking.EventTriggered → sonido de evento de ronda
```

Cuando AudioManager se implemente, solo necesita conectar los RemoteEvents existentes. Ningún módulo de gameplay necesita modificarse. La misma convención aplica a VFX.

### 4.10 ClientStateManager — Contrato

`src/client/ClientStateManager.lua` es el único módulo del cliente que conecta RemoteEvents. Los módulos de UI leen estado de él — nunca conectan RemoteEvents directamente.

**Invariante:** `OnClientEvent:Connect` solo aparece en `ClientStateManager.lua`. En el servidor, `OnServerEvent:Connect` solo aparece en `CarryManager.lua` (INV-001).
**Invariante:** `Networking` se importa desde `src/shared/Lib/Networking.lua` — nunca directamente desde `ReplicatedStorage.Remotes.*`.

**API:**
```lua
ClientStateManager.init()
-- Conecta todos los RemoteEvents. Llamado una sola vez desde Main.client.lua.

ClientStateManager.getState(): State
-- Retorna snapshot del estado actual (copia — no la tabla interna).

ClientStateManager.getObject(instanceId): ObjectSnapshot?
-- Retorna snapshot de un objeto específico.

ClientStateManager.subscribe(id, listener, options?): () -> ()
-- Registra listener que recibe el estado completo en cada cambio.
-- options = { timerUpdates: boolean? } — por defecto los ticks de TimerSync
-- (1/segundo) NO notifican; solo los listeners con timerUpdates = true los
-- reciben (evita re-renders por segundo en módulos sin timer — DL-025).
-- Retorna función de cleanup. Llamar en cleanup() de cada módulo de UI.
```

**Estado que expone:**
```lua
State = {
    phase: "Lobby" | "Active" | "Summary",
    timeRemaining: number,
    deliveredCount: number,
    activeEventType: string?,
    objects: { [instanceId]: ObjectSnapshot },
    summary: RoundSummary?,
}
```

**Nota sobre Janitor:** este módulo NO usa Janitor (`howmanysmall/janitor`, §4.11). Su patrón de `subscribe(id, listener)` con cleanup por clave es un observer pattern con múltiples suscriptores — forma distinta al problema que Janitor resuelve (un dueño limpiando sus propios recursos). Los módulos de UI que consumen `ClientStateManager` (HUDManager, SummaryManager) sí usan Janitor para gestionar sus propias conexiones internas.

### 4.11 Package Management (Wally)

`wally.toml` declara las dependencias externas del proyecto. `Packages/` es el output de `wally install` — gitignored, nunca se commitea. `wally.lock` sí se commitea (equivalente a `cargo.lock` o `package-lock.json`): fija las versiones exactas resueltas para que todos los entornos instalen lo mismo.

**Invariante:** ningún módulo importa una dependencia de Wally sin que esté declarada en `wally.toml`.

**Dependencias adoptadas y su justificación:**

| Paquete | Realm | Justificación |
|---|---|---|
| `roblox/testez@0.4.1` | shared | Framework de testing — ya cubierto en §5.0 |
| `evaera/promise@4.0.0` | shared | Manejo de operaciones asíncronas. Estándar de facto del ecosistema Roblox. |
| `howmanysmall/janitor@1.18.3` | shared | Gestión de lifecycle de conexiones. Uso: dominio UI (§4.10 nota), reemplaza el patrón manual de tabla de conexiones en HUDManager/SummaryManager. |
| `lm-loleris/profilestore@1.0.3` | **server** | Persistencia de PlayerData: session locking, retry, auto-save. Ver §4.7. |

**Regla de scope de Janitor:** se usa en módulos de UI que poseen múltiples conexiones con lifecycle propio (HUDManager, SummaryManager, futuros módulos UI). No se usa en `ClientStateManager` — su patrón de `subscribe()`/cleanup por clave es un observer pattern con forma distinta a la que Janitor resuelve, y ya es correcto tal como está.

**Paquetes evaluados y no adoptados:**

| Paquete | Razón de no adopción |
|---|---|
| BridgeNet2 / Net | Resuelven batching de RemoteEvents de alta frecuencia. El proyecto tiene ≤7 RemoteEvents disparados en acciones discretas a escala humana (§4.3) — no tiene el problema que estas librerías resuelven. Adoptarlas sería complejidad sin problema correspondiente. |

**wally-package-types:** los paquetes de Wally distribuyen su código como thunks de Luau que no exportan tipos nativamente. `wally-package-types` post-procesa `Packages/` para generar los archivos de tipos correctos, habilitando autocompletado y chequeo de tipos del Luau LSP sobre dependencias externas.

**Pipeline de instalación (orden obligatorio):**
```
1. wally install
   → genera Packages/ (realm shared) y ServerPackages/ (realm server)
     con el código de las dependencias

2. rojo sourcemap default.project.json --output sourcemap.json
   → wally-package-types necesita el sourcemap para resolver
     la jerarquía real del proyecto

3. wally-package-types --sourcemap sourcemap.json Packages/
   wally-package-types --sourcemap sourcemap.json ServerPackages/
   → genera los archivos de tipos sobre los paquetes ya instalados
```

`wally-package-types` no puede ejecutarse antes del paso 1 — necesita paquetes instalados para tener algo que procesar.

---

## 5. Governance

### 5.0 Principio de Separación CI/IA

**Regla:** Si una regla arquitectónica puede expresarse como condición binaria verificable, se convierte en CI. Si requiere juicio, queda para IA o humano.

La jerarquía tiene 4 niveles. Cada nivel maneja lo que el nivel anterior no puede:

```
Nivel 1 — CI: contratos funcionales y estructurales
  Qué hace el sistema. Cómo está organizado.
  Condiciones binarias verificables automáticamente en cada PR.

Nivel 2 — CI: contratos de mantenibilidad
  Propiedades de diseño objetivables como umbrales numéricos.
  No son funcionales — verifican que el código sea sostenible.

Nivel 3 — IA: patrones sospechosos
  Propiedades que no tienen umbral objetivo pero tienen señales detectables.
  El Auditor TECH (Codex) detecta y propone conversión a Nivel 1 o 2.

Nivel 4 — Humano: evaluación del modelo
  ¿La abstracción es correcta? ¿El sistema modela bien el problema?
  No es auditoría — es arquitectura. Solo el Product Owner decide.
```

**Nivel 1 — Contratos funcionales y estructurales (CI + pre-commit)**

Todos los contratos de Nivel 1 corren en dos momentos:
- **Pre-commit** (local, inmediato) — via Lefthook antes de crear el commit
- **CI** (remoto, en PR) — via p2-implementation.yml antes de mergear

| Contrato | Invariante | Mecanismo |
|---|---|---|
| INV-001 | `OnClientEvent:Connect` solo en `ClientStateManager.lua`; `OnServerEvent:Connect` solo en `CarryManager.lua` | grep |
| INV-002 | `sound:Play()` / VFX no en módulos de gameplay | grep |
| §4.6 | `PathfindingService` no en `src/` | grep |
| §2.4 | `.Name` no como condición lógica | grep |
| §4.3 | RemoteEvents ≤ 7 en `Networking.lua` | conteo |
| §4.6 Lune | Globals Roblox no en scope de módulo | `lune run lune/check-compatibility.luau` ⚠ heurística, no AST |
| — | Specs de comportamiento (Persistence, ObjectManager) | `lune run lune/run-specs.luau` |
| — | `print`/`warn` fuera de `Logger.lua` | grep (`contract-logger-usage`) — Selene no puede prohibir globals específicos |
| — | Formato de código uniforme | StyLua |
| — | Convención de commits | commitlint (Lefthook commit-msg) |

**Nivel 2 — Contratos de mantenibilidad (CI)**

| Contrato | Umbral | Mecanismo |
|---|---|---|
| Tamaño de módulo | Ningún archivo en `src/` > 300 líneas | `wc -l` |
| Separación de capas | `src/server/` no requiere `src/client/` | grep |
| Cobertura mínima | Módulos de Persistence tienen spec | existencia de archivo |

**Nivel 3 — Patrones sospechosos (Auditor TECH en P3)**

```
¿Este módulo tiene responsabilidades que deberían estar separadas?
¿Esta solución es innecesariamente compleja para lo que hace?
¿Hay acoplamiento implícito que ningún contrato prohíbe todavía?
```

Cuando el Auditor TECH detecta un patrón en Nivel 3, propone convertirlo a Nivel 1 o 2 como "NEW CONTRACT CANDIDATE". Ese candidato entra al Decision Log y eventualmente se implementa como job de CI.

**Nivel 4 — Evaluación del modelo (Product Owner)**

```
¿Esta abstracción modela correctamente el problema?
¿El sistema está diseñado alrededor de las entidades correctas?
¿Esta decisión técnica tiene consecuencias de diseño no anticipadas?
```

No es auditoría. Es arquitectura. El PO decide en cada entrada Clase A.

### 5.1 Dominios Arquitectónicos

Define dominios de ownership. **Persona ≠ Dominio.** Los tickets pertenecen a un dominio. Las personas cubren uno o más dominios.

**Dominios de implementación (TECH):**

| Dominio | Ownership (módulos) |
|---|---|
| Gameplay | ObjectManager, CarryManager, TruckManager, GameManager, RoundManager, ObjectDefinitions |
| World | NPCManager, EventManager, Layout, MapDefinitions |
| Networking | RemoteEvents, Payloads, Contratos cliente-servidor, Validación |
| Persistence | PlayerDataService, MigrationService, integración de ProfileStore |
| UI | HUD, Round UI, Summary Screen, Feedback visual |

**Dominios de diseño (DESIGN):**

| Dominio | Produce |
|---|---|
| Gameplay Design | Mecánicas, reglas de interacción, balance de objetos |
| World Design | Comportamiento de NPCs, selección de eventos, diseño de layout |
| UX Design | Principios de feedback, contratos de estado visible, criterios de evaluación (§3.7) |

Un dominio de implementación recibe diseño aprobado por el Product Owner y lo implementa. No redefine el diseño. Un dominio de diseño no toca código.

**Nota sobre prefijos de ticket:** `GM-xxx` agrupa los tickets de GameManager dentro del dominio Gameplay. `QA-xxx` no es un dominio — son hitos transversales de integración, playtest (P6) y publicación; QA es una función de Governance (§5.6), no tiene ownership de módulos.

### 5.2 Knowledge Domains

Los prompts de agentes heredan de estos domains. No se duplica contenido entre prompts.

| Domain | Contenido |
|---|---|
| DESIGN | Principios Congelados, DI, Cooperación, Entropía, Test de Diseño, §3 completa |
| TECH | Contratos, Invariantes, Networking, Persistencia, Escalabilidad, Ownership, §4 completa |
| DESIGN-UX | §3.7 completa. Dominio de diseño independiente. Produce contratos observables. |

**Regla:** Un agente declara su Knowledge Domain explícitamente. Opera únicamente sobre ese dominio.

**Nota de granularidad futura:** Los Knowledge Domains se mantienen mínimos hasta evidencia empírica de subdivisión requerida. No se activan sin decisión del Product Owner.

### 5.3 Protocolo de Auditoría

**Categorías técnicas:**

| Código | Nombre |
|---|---|
| T1 | Bug confirmado |
| T2 | Riesgo técnico |
| T3 | Deuda técnica |
| T4 | Violación de invariante |

**Categorías de diseño:**

| Código | Nombre |
|---|---|
| D1 | Violación de principio |
| D2 | Riesgo de diseño |
| D3 | Oportunidad de mejora |
| D4 | Hipótesis sistémica |

**Categoría de gobernanza:**

| Código | Nombre |
|---|---|
| G5 | Actualización del Context Master pendiente de confirmación del PO — emitido por cualquier Orchestrator cuando una entrada llega a P3 con la nota "⚠ Context Master update" activa (§5.5 paso 8) |

**Regla central:** Un Orchestrator no puede emitir hallazgos fuera de su dominio. Auditor TECH no emite D1–D4. Auditor DESIGN no emite T1–T4. G5 es la única categoría compartida — la puede emitir cualquiera de los dos.

**Modos de auditoría:**
```
AUDIT_MODE=TECH   → lee §1 + §2 + §4 + §5 + §6. Emite solo T1–T4.
AUDIT_MODE=DESIGN → lee §1 + §2 + §3 + §5 + §6. Emite solo D1–D4.
```

**Formato obligatorio de hallazgo:**
```
PROBLEMA [n]: [nombre]
  Dominio: TECH | DESIGN
  Código: T1–T4 | D1–D4
  Sección violada: §N.N
  Evidencia: [qué se observa]
  Impacto: [consecuencia concreta]
  Corrección mínima: [lo estrictamente necesario]
```

**Veredicto:** `Aprobado` / `Aprobado con observaciones` / `Rechazado`

### 5.4 Project Decision Log

Archivo separado: `PROJECT_DECISION_LOG.md`

**Propósito:** Registrar conocimiento arquitectónico. No es historial técnico (Git) ni trabajo operativo (Tickets).

**Solo los cambios Clase A generan entrada en el Decision Log.**

**Costo operacional humano:** El humano interviene en exactamente tres puntos del ciclo Clase A: escritura en SCRATCHPAD, decisión sobre la PROPOSAL (Product Owner), y aprobación del Context Master update. Los pasos intermedios son ejecutados por Subagents, Orchestrators y GitHub Actions.

**Criterio de granularidad — unidad atómica:**

La unidad atómica es un cambio de conocimiento arquitectónico. Una entrada responde exactamente a **una** de estas preguntas:

```
1. ¿Qué existe ahora que antes no existía?     → entidad nueva
2. ¿Qué regla cambió?                          → principio o contrato
3. ¿Qué comportamiento sistémico es distinto?  → API o invariante
4. ¿Qué ownership cambió?                      → responsabilidad de dominio
```

Si una idea requiere responder más de una pregunta → se divide. Si no responde ninguna → es Clase B, solo commit.

**Ciclo de vida:**
```
DISCOVERY → PROPOSAL → DECISION → AUDIT
```

**Estructura de entrada:**
```
ID:          DL-[número]
Fecha:       YYYY-MM-DD
Domain:      TECH | DESIGN | BOTH | UNKNOWN
Tipo:        OBSERVATION | QUESTION | HYPOTHESIS | PROPOSAL
Estado:      DISCOVERY | PROPOSAL | DECISION | AUDIT
Contexto:    [situación que generó la entrada]
Contenido:   [idea, observación, pregunta o propuesta]
Hipótesis:   [qué podría ser verdad si esto es correcto]
Razón:       [por qué se tomó esta decisión — vacío hasta DECISION]
Impacto:     [qué cambia — vacío hasta DECISION]
Ejecución:   AUTO | CONFIRM | MANUAL — vacío hasta DECISION
Costo:       C1 | C2 | C3 | C4 — vacío hasta DECISION
Pipeline:    P1 | P2/P4 | P3 | P5 | P6 — vacío hasta DECISION
Ticket:      [DOMINIO]-[número] — vacío hasta que exista
Commit:      [hash] — vacío hasta que exista
Referencias: [secciones del Context Master, otros DL-]
```

**Valores válidos por estado:**

| Estado | Domain UNKNOWN válido | Hipótesis requerida | Razón requerida | Ejecución/Costo/Pipeline |
|---|---|---|---|---|
| DISCOVERY | Sí | No | No | — |
| PROPOSAL | No | Sí | No | — |
| DECISION | No | Sí | Sí | Requeridos |
| AUDIT | No | Sí | Sí | Heredado de DECISION |

**WF-007 — Domain UNKNOWN Resolution:**
```
Actor:   Product Owner
Trigger: revisión periódica o developer marca entrada como bloqueada
Acción:  PO asigna Domain. Costo: C1.
Si indeterminado: documenta "indeterminado tras revisión [fecha]"
  La entrada permanece en DISCOVERY indefinidamente.
  Se registra como open question en la próxima P3.
```

**P5 en el Decision Log:**
```
Pipeline:   P5
Ejecución:  MANUAL (siempre cuando Pipeline = P5)
Razón:      "CONTINGENCY [pipeline-original] — [motivo]: [texto]"
```

**Origen de entradas:** Las entradas de origen humano en DISCOVERY provienen exclusivamente del Subagent SCRATCHPAD_INTAKE. Las entradas generadas por Orchestrators (ej. D3 elevado a PROPOSAL) pueden crearse directamente en el log.

### 5.5 Normas Operativas

**Workflow Oficial de Cambio:**

```
CLASE B — Cambio local
  1. Implementar
  2. Commit descriptivo (convención §6.4)
  Fin. No genera ticket ni entrada en Decision Log.

CLASE A — Cambio arquitectónico
  1. SCRATCHPAD
     Desarrollador escribe idea con estructura canónica.

  2. INTAKE (Subagent SCRATCHPAD_INTAKE)
     Audita y formaliza. Produce entrada DISCOVERY en log.
     Entradas procesadas se eliminan del scratchpad.

  3. AUDITORÍA CONCEPTUAL (Orchestrator)
     Domain TECH    → AUDIT_MODE=TECH
     Domain DESIGN  → AUDIT_MODE=DESIGN
     Domain BOTH    → ambas; TECH primero. Si TECH rechaza, DESIGN no ejecuta.
     Domain UNKNOWN → bloqueado. WF-007 activa antes de proceder.
     Si pasa: estado → PROPOSAL.

  4. DECISIÓN (Product Owner)
     Si aprueba: estado → DECISION. Declara Ejecución, Costo, Pipeline.
     Si rechaza: documenta razón. Estado no avanza.

  5. TICKET
     Formato obligatorio:
     ID:          [DOMINIO]-[número]  (ej: GAM-001, NET-001, UI-001)
     DL-Ref:      DL-[número]
     Domain:      TECH | DESIGN | BOTH
     Descripción: [qué implementar]
     Criterios de Aceptación:
       - [ ] [condición — verificable sí/no]
       ...
     Regla: cada criterio debe ser binario. Sin criterios binarios,
     no puede recibir self-review válido.

  6. IMPLEMENTACIÓN (Subagent Constructor)
     Implementa según el ticket.
     Self-review: verifica cada criterio de aceptación explícitamente.
     Si todos pasan: commit con refs: DL-[número], [DOMINIO]-[número].
     Si alguno falla: corrige antes de commitear.

  7. AUDITORÍA TÉCNICA (Orchestrator)
     Domain TECH   → AUDIT_MODE=TECH
     Domain DESIGN → AUDIT_MODE=DESIGN
     Domain BOTH   → TECH primero (automático via Codex).
                     Si pasa TECH: humano activa Claude para DESIGN.
                     El segundo Orchestrator (DESIGN) revisa explícitamente
                     fronteras entre dominios: ¿el cambio TECH altera
                     contratos que afectan principios o percepción DESIGN?

     Si falla — recovery path:
       T1 o T2: Constructor corrige → nuevo commit → re-auditoría.
                No genera nueva entrada en log.
       T3 o T4: Nueva entrada DISCOVERY, Tipo=OBSERVATION, Domain=TECH.
                Referencias: DL-[original]. Ciclo Clase A desde paso 3.
                Entrada original permanece en DECISION hasta re-auditoría aprobada.
                Circuit breaker: si DL-original ya tiene 2+ entradas T3/T4
                consecutivas abiertas → escalar a C4/MANUAL. PO evalúa raíz.
                Ciclo no se reanuda sin aprobación explícita del PO.

     Si pasa: estado → AUDIT.

  8. CONTEXT MASTER (si aplica)
     Constructor propone diff. Product Owner revisa y aprueba.
     La entrada avanza a AUDIT independientemente de este paso.
     Mecanismo de detección: al avanzar a AUDIT, el Orchestrator
     verifica si Impacto menciona contratos, principios o entidades.
     Si sí: añade nota "⚠ Context Master update — pendiente confirmación PO".
     El PO elimina la nota al aprobar el diff.
     Si llega a P3 con nota activa: Orchestrator emite G5.
```

**Regla de cortocircuito:** Ningún agente puede saltar pasos de Clase A.

**Regla de desempate — Domain BOTH:**
Un rechazo de cualquier Orchestrator bloquea el avance.
```
Si una auditoría aprueba y la otra rechaza:
  El hallazgo se documenta. Estado no avanza.
  Developer puede solicitar al PO que revise el rechazo.
  PO puede reclasificar el hallazgo como fuera de scope
  → si reclasifica: estado puede avanzar con nota del PO.
```

**Regla de Cambios:** Cualquier modificación a contratos, principios o arquitectura debe notificarse antes de implementarse, ser acordada por todos los responsables afectados, y actualizar este documento con nueva versión. Ningún agente aprueba cambios a este documento. Solo el Product Owner.

**Regla de derivación de tickets (DL-032):**

Un ticket no aparece de forma oportunista durante la implementación — se *deriva*. Todo ticket debe trazar a exactamente una de estas dos fuentes, declarada en su campo `Deriva de`:

```
(a) una DECISIÓN del Decision Log (DL-xxx), o
(b) un Principio Congelado (§2.1) / hito de roadmap (§5.7) que el ticket habilita.
```

Reglas:
- **Completitud.** Antes de arrancar un hito de roadmap, se deriva el conjunto *completo* de tickets que lo realizan — incluyendo los tickets de **habilitación/infraestructura** que un principio *implica* pero que ningún ticket de feature nombra. Si una pieza de infraestructura es necesaria para cumplir un principio y ningún ticket la nombra, recibe su propio ticket explícito **antes** de implementarse.
- **Coste-IA.** El ticket especifica el artefacto **AI-óptimo**, no el humano-mínimo (§5.9). El caso de referencia es `MapBootstrap`: derivado del principio "el slice debe ser ejecutable sin pasos manuales de Studio", no de un problema encontrado en el camino.
- **Trazabilidad.** Un ticket sin `Deriva de` es incompleto y no puede recibir self-review válido. Los 30 tickets de bootstrap están grandfathered (nota de bootstrap en TICKETS.md); todo ticket nuevo cumple esta regla.

### 5.6 Taxonomía de Tipos de Agentes

**Definiciones canónicas:**

```
Orchestrator
  Agente con visión global. Evalúa coherencia sistémica.
  Activa Subagents o emite hallazgos. No produce artefactos de implementación.
  Ejemplos: Auditor TECH (Codex), Auditor DESIGN (Claude)

Subagent
  Agente con scope acotado. Activado por humano u Orchestrator.
  Produce artefactos específicos: código, documentación, diseño, entradas de log.
  Ejemplos: todos los agentes de roles (Constructores, Ideadores, Intake)
```

| Tipo | Función | Puede usar | No puede |
|---|---|---|---|
| **Auditor** | Detectar problemas | Context Master, Decision Log, código, tickets | Proponer arquitectura, expandir scope, aprobar cambios |
| **Constructor** | Implementar diseño aprobado | Context Master, Decision Log, código, tickets | Rediseñar, salir del scope del ticket, emitir hallazgos de auditoría |
| **Ideador** | Explorar y proponer diseño | Context Master, heurísticas, métricas subjetivas (pre-playtest) | Aprobar cambios, emitir hallazgos formales, implementar |

Los Auditores son Orchestrators. Los Constructores e Ideadores son Subagents. QA es una función de Governance ejecutada por cada Constructor en self-review.

**Regla de flujo:** Ideador produce diseño → PO aprueba → Constructor implementa → Auditor verifica. Ningún agente ocupa dos tipos simultáneamente en el mismo ticket.

### 5.7 Roadmap de Desarrollo

**Reloj del roadmap (DL-024):** reiniciado el 2026-07-11. Semana 1: 11–18 jul · Semana 2: 19–25 jul · Semana 3: 26 jul–1 ago · Semana 4: 2–11 ago. Objetivo: vertical slice completo (QA-001 y sucesores) al 2026-08-11.

| Semana | Técnico | Objetivo de diseño |
|---|---|---|
| 1 | Edificio placeholder · spawn · pickup/drop · camión · timer · fin de ronda · persistencia via ProfileStore (sesión + migraciones, §4.7) | Un jugador completa una ronda de inicio a fin. Los datos persisten. |
| 2 | Objetos grandes (líder/soporte) · multijugador · layout final | Comunicación espontánea · bloqueos recurrentes · 1 situación inesperada/min sin eventos. Si falla: revisar layout, no añadir sistemas. |
| 3 | NPC vecino · eventos · summary screen | Las rondas se sienten distintas entre sí. |
| 4 | Bug fixing · optimización · publicación | DI media-alta confirmada en playtest real. |

### 5.8 Scratchpad e Intake

Dos archivos en `/docs/`:

```
docs/
├── SCRATCHPAD.md                              ← zona de ingestión del desarrollador (Tipo A)
└── prompts/
    └── roles/
        └── intake/
            └── SCRATCHPAD_INTAKE.md
```

**SCRATCHPAD.md — Especificación:**

Zona de ingestión exclusiva. Las entradas aprobadas se eliminan del scratchpad después de cada ciclo. Las rechazadas se mueven a `## Rechazadas` y no se eliminan hasta revisión del PO.

**Protocolo de escritura concurrente:**
```
Un developer escribe a la vez.
Anunciar intención de escritura en canal del equipo antes de editar.
Si hay conflicto: segundo developer usa archivo temporal personal.
```

**Estructura interna del SCRATCHPAD.md:**

```markdown
# SCRATCHPAD — Mudanza Caótica
> Material de ingestión exclusivo. No es documentación del proyecto.

## Cómo usar este archivo

| Tipo        | Cuándo usarlo                                                           |
|-------------|-------------------------------------------------------------------------|
| OBSERVATION | Viste algo en el juego. No sabes qué significa todavía.                |
| QUESTION    | Tienes una duda sobre diseño, arquitectura o dirección.                 |
| HYPOTHESIS  | Crees que algo podría ser verdad. Sin evidencia todavía.               |
| PROPOSAL    | Tienes una idea concreta. Sabes aproximadamente qué cambiaría.          |

Antes de escribir:
- ¿Tu idea aumenta la Dependencia Social o la Entropía?
- ¿Mantiene el Objetivo Estable?
- ¿Añade complejidad sin aumentar DI?
- Si no puedes responder: usa QUESTION.

## Entradas

### [TIPO] Título corto

**Contexto:** Qué observaste o qué lo generó.
**Contenido:** La idea en tus propias palabras.
**Domain (opcional):** TECH | DESIGN | BOTH | No sé

---

## Rechazadas

<!-- No borrar hasta revisión del PO -->
```

**SCRATCHPAD_INTAKE — Proceso:**

```
1. COHERENCIA
   ¿Contradice algún Principio Congelado?
   ¿Viola la Lista Prohibida?
   Si sí → RECHAZADA. Mover a ## Rechazadas. No pasa al log.

2. CLASIFICACIÓN
   Confirmar o corregir Tipo declarado.
   Inferir Domain si "No sé":
   - Afecta módulos de código → TECH
   - Afecta principios o diseño → DESIGN
   - Afecta ambos → BOTH
   - Genuinamente indeterminado → UNKNOWN

3. FORMALIZACIÓN
   Producir entrada DISCOVERY para PROJECT_DECISION_LOG.md.
```

**Mecanismo de apelación (WF-010):**
```
Si el developer está en desacuerdo con un rechazo:
  → P5 manual: entrada directa en Decision Log, estado DISCOVERY.
  Razón: "CONTINGENCY P5 — bypass de intake. Desacuerdo: [motivo]"
  Costo: C1. Pipeline: P5.
```

### 5.9 Modelo de Coste del Implementador (DL-032)

**Principio.** El implementador de este proyecto es una IA. Toda heurística o umbral de gobernanza debe calibrarse a la suma de tres costes:

```
coste-IA-implementador  +  coste-humano-revisor  +  coste-runtime
```

y **nunca** a `coste-humano-implementador`. Un umbral que existe solo para reducir la carga de un humano que *escribe* u *hojea* código es un tradeoff importado de otro contexto: puede reducir la calidad cuando el implementador es una IA, y debe reexaminarse.

**Por qué importa.** Muchas convenciones de ingeniería nacieron para gestionar límites humanos (memoria de trabajo, tiempo de escritura, fatiga de lectura). Una IA no comparte esos límites: lee el módulo entero sin importar su tamaño, y generar un artefacto de código es tan barato como describir uno mínimo. Calibrar a coste-humano-implementador introduce sesgos silenciosos que degradan la profesionalidad exigida (§1.3).

**Ejemplo canónico — MapBootstrap.** Un roadmap escrito con supuesto de implementador humano diría "haz arte placeholder mínimo en Studio" (barato para un humano, evita escribir y mantener un generador). Bajo el coste-IA, generar el edificio en código (`MapBootstrap`) es *más barato y mejor*: versionable, reproducible, sin pasos manuales. El artefacto AI-óptimo diverge del humano-mínimo — y el ticket, si se deriva con el supuesto equivocado, ni siquiera lo nombra (ver §5.5, Regla de derivación de tickets).

**Matiz — no toda restricción es antropocéntrica.** Distinguir siempre la *restricción* del *número*:

| Umbral | Qué es realmente | Veredicto |
|---|---|---|
| `módulo < 300 líneas` | Proxy de "responsabilidad única" calibrado al humano que *hojea*. Una IA lee el módulo completo. | Antropocéntrico — recalibrar al alza o sustituir por una medida de cohesión real. |
| `RemoteEvents ≤ 7` | La *restricción* (minimizar superficie cliente-servidor) es de **runtime** — superficie de exploit + coste de replicación, independiente de quién codea. El *número 7* es la heurística. | La restricción se mantiene; el número se justifica o recalibra. |

**Inconsistencia detectada (a resolver).** `RemoteEvents ≤ 7` se ejecuta como gate duro de **Nivel 1** en CI (`contract-remote-event-count`), pero §4.3 lo describe como límite blando "sin aprobación del PO". No puede ser ambas cosas: o es un invariante duro (y §4.3 no debería ofrecer escape), o es un umbral Nivel 2 con escape a PO (y no debería ser un gate de bloqueo). Resolver en la reexaminación de umbrales (pipeline posterior).

**Alcance.** Esta decisión NO relaja umbrales por defecto — establece el marco para reexaminarlos uno a uno bajo el coste correcto. Cada reexaminación de un umbral concreto es su propia entrada de decisión.

---

## 6. Operational Architecture

### 6.1 File Taxonomy

| Tipo | Descripción | Riesgo principal | Ejemplos |
|---|---|---|---|
| A — Humano semipuro | Estructura creada por IA. Contenido llenado por humano sin filtro. Subagent solo filtra y formaliza via intake. Orchestrator audita solo estructura. | Contenido sin filtrar ingresa al ciclo sin pasar por intake | SCRATCHPAD.md |
| B — Insumo primario de Orchestrator | Ciclo de vida largo. Se modifica solo con aprobación del PO. | Modificación sin auditoría previa | Prompts de auditores, AI_CONTEXT_MASTER (parcial) |
| C — Comprensión humana | Para lectura humana. IA puede auditarlo y redactarlo. No es crítico. | Desactualización silenciosa | Onboarding, READMEs |
| D — Insumo primario de Subagent | Consumido por Subagents en trabajo cotidiano. **TICKETS.md es generado por sync-tickets.yml** — no editar manualmente. El estado de cada ticket se actualiza moviendo el card en el GitHub Project. | Desincronización con estado real | Prompts de roles, TICKETS.md |
| B+D — Insumo universal | Consumido por Orchestrators y Subagents con propósito distinto. | Modificación que satisface a un consumidor pero rompe el contrato del otro | AI_CONTEXT_MASTER, PROJECT_DECISION_LOG |

**Aprovechabilidad por archivo:**

| Archivo | Tipo | Intervención humana | Orchestrator | Subagent |
|---|---|---|---|---|
| SCRATCHPAD.md | A | Alta — escribe contenido | Solo estructura | Filtra y formaliza |
| AI_CONTEXT_MASTER | B+D | Solo mejoras aprobadas | Lee como insumo | Lee como insumo |
| PROJECT_DECISION_LOG | B+D | Supervisión y estado | Lee y audita | Lee para contexto |
| TICKETS.md | D | Estado y notas | Audita estructura | Opera activamente |
| Prompts de auditores | B | Solo mejoras aprobadas | Lee como contexto | No consume |
| Prompts de roles | D | Solo mejoras aprobadas | No consume | Lee como contexto |
| Onboarding | C | Redacta y lee | Audita ocasionalmente | Referencia ocasional |

**Regla de acceso exclusivo IA:** Los prompts de auditores son el único archivo que los humanos no usan en trabajo cotidiano.

### 6.2 Repository Structure

**Estructura real del repo:**

```
mudanza-caotica/
├── README.md                         ← Tipo C (punto de entrada del repo)
├── lefthook.yml                      ← Tipo C (pre-commit hooks — commitear)
├── default.project.json
├── rokit.toml                        ← Tipo C (toolchain manager)
├── .stylua.toml                      ← Tipo C
├── selene.toml                       ← Tipo C
├── roblox.yml                        ← generado por selene (caché/CI) — gitignored, no se commitea
├── testez.yml                        ← Tipo C (oficial, no editar)
├── wally.toml                        ← Tipo C
├── .gitignore
├── .gitattributes                    ← Tipo C (normaliza line endings a LF)
│
├── lune/                             ← Tipo C (scripts de automatización Lune)
│   ├── check-compatibility.luau      ← verifica compatibilidad de módulos con Lune
│   └── run-specs.luau                ← corre specs de TestEZ sin Studio
│
├── .vscode/                          ← Tipo C (no commitear datos personales)
│   ├── settings.json                 ← LSP, formatOnSave, StyLua
│   └── extensions.json               ← extensiones recomendadas del proyecto
│
├── .github/
│   ├── workflows/
│   │   ├── p1-intake.yml
│   │   ├── p2-implementation.yml
│   │   ├── p3-periodic-audit.yml
│   │   ├── validate-scratchpad.yml
│   │   ├── validate-decision-log.yml
│   │   ├── sync-tickets.yml          ← Project → TICKETS.md (via PR del bot, DL-030)
│   │   └── automerge-sync.yml        ← automerge de los PRs de bot/sync-tickets
│   ├── commitlintrc.yml              ← fuente única de reglas de commits (CI la consume via --config)
│   ├── dependabot.yml                ← actualizaciones semanales de GitHub Actions
│   ├── LABELS.md                     ← instrucciones de setup de labels
│   └── PROJECT_SETUP.md              ← instrucciones de setup del GitHub Project
│
├── docs/
│   ├── AI_CONTEXT_MASTER.md          ← Tipo B+D
│   ├── PROJECT_DECISION_LOG.md       ← Tipo B+D
│   ├── TICKETS.md                    ← Tipo D
│   ├── SCRATCHPAD.md                 ← Tipo A
│   │
│   ├── prompts/
│   │   ├── auditors/                 ← Tipo B
│   │   │   ├── AUDITOR_TECH.md
│   │   │   └── AUDITOR_DESIGN.md
│   │   │
│   │   └── roles/                    ← Tipo D
│   │       ├── _BASE_IDEADOR.md      ← base compartida de Ideadores
│   │       ├── _BASE_CONSTRUCTOR.md  ← base compartida de Constructores
│   │       ├── intake/
│   │       │   └── SCRATCHPAD_INTAKE.md
│   │       ├── gameplay/
│   │       │   ├── GAMEPLAY_ENGINEER.md
│   │       │   └── GAMEPLAY_DESIGNER.md
│   │       ├── world/
│   │       │   ├── WORLD_ENGINEER.md
│   │       │   └── WORLD_DESIGNER.md
│   │       ├── networking/
│   │       │   └── NETWORKING_ENGINEER.md
│   │       ├── persistence/
│   │       │   └── PERSISTENCE_ENGINEER.md
│   │       └── ui/
│   │           ├── UI_ENGINEER.md
│   │           └── UX_DESIGNER.md
│   │
│   └── human/                        ← Tipo C
│       └── ONBOARDING.md
│
└── src/  — ver §4.1 para estructura detallada

Packages/        — generado por wally install (realm shared), gitignored. Ver §4.11.
ServerPackages/  — generado por wally install (realm server: ProfileStore), gitignored.
                   Mapeado a ServerScriptService/ServerPackages en default.project.json.
                   Wally.lock sí se commitea.
```

**Vista virtual para Orchestrators (organización por dominio):**

Las referencias de sección son al Context Master v5.6.

```
[DOMINIO: Gameplay]
  AI_CONTEXT_MASTER §4.4 (GameManager, RoundManager, ObjectManager, CarryManager, TruckManager)
  TICKETS.md → entradas Domain: Gameplay
  PROJECT_DECISION_LOG → entradas Domain: TECH | BOTH relacionadas a Gameplay

[DOMINIO: World]
  AI_CONTEXT_MASTER §4.4 (NPCManager, EventManager)
  TICKETS.md → entradas Domain: World

[DOMINIO: Networking]
  AI_CONTEXT_MASTER §4.2, §4.3, src/shared/Lib/Networking.lua
  TICKETS.md → entradas Domain: Networking

[DOMINIO: Persistence]
  AI_CONTEXT_MASTER §4.7
  TICKETS.md → entradas Domain: Persistence

[DOMINIO: UI / UX]
  AI_CONTEXT_MASTER §3.7, §4.10, src/client/ClientStateManager.lua
  TICKETS.md → entradas Domain: UI | UX
```

### 6.3 Pipeline Registry

| ID | Pipeline | Ejecutor | Trigger | Artefacto | Actions | Contingencia de |
|---|---|---|---|---|---|---|
| P1 | Ideación estándar | Mixto | Humano tiene idea | Entrada DISCOVERY en log | p1-intake.yml | — |
| P2/P4 | Implementación (docs o código) | Subagent + revisión humana | Ticket en DECISION | Artefacto implementado | p2-implementation.yml | — |
| P3 | Auditoría de proyecto | Codex (TECH, automático) + Claude (DESIGN, manual) | Lunes 9:00 UTC o solicitud PO | Hallazgos en log | p3-periodic-audit.yml | — |
| P5 | Contingencia manual | Humano | Pipeline ideal no disponible | Mismo artefacto del pipeline original | — | P1, P2/P4, P3 |
| P6 | Playtest y observación | Humano | Round completable sin crash + N features MVP (N definido por PO en semana 2) | Entradas en SCRATCHPAD → P1 | — | — |

**Ejecutores detallados:**

```
P1 — Ideación estándar
  Scratchpad:           Humano
  Intake:               Subagent (SCRATCHPAD_INTAKE) + revisión humana
  Auditoría conceptual: Orchestrator
  Decisión:             Product Owner
  Ticket:               Humano o Subagent

P2/P4 — Implementación (Clase A)
  Implementación:       Subagent Constructor del dominio
  Self-review:          Constructor (modo auditor)
  Revisión:             Humano
  Auditoría TECH:       Codex (automático post-merge)
  Auditoría DESIGN:     Claude (manual si domain:design o domain:both)

P3 — Auditoría de proyecto
  TECH:   Codex ejecuta automáticamente en el cron
  DESIGN: Humano activa Claude manualmente
  Contexto actual: manual via Claude chat para DESIGN

P5 — Contingencia manual
  Ejecutor único: Humano
  Documentar en Decision Log con nota CONTINGENCY
```

### 6.4 Execution Authority

**Clases de cambio:**

```
Clase A — Cambio arquitectónico
  Altera contratos, entidades, principios, APIs públicas,
  comportamiento sistémico o diseño.
  Flujo: pipeline completo P1 → P2/P4 → P3.
  Genera entrada en Decision Log.

Clase B — Cambio local
  No altera conocimiento arquitectónico.
  Flujo: commit descriptivo. Solo.
  No genera entrada en Decision Log.
```

**Regla de clasificación:** Si hay duda entre A y B → es A.

**Convención de commits:**

```
tipo(dominio): descripción corta

reason: por qué se hizo este cambio
refs: DL-[número], [DOMINIO]-[número]  ← solo en Clase A
```

Tipos: `feat` | `fix` | `refactor` | `docs` | `chore`
Dominios: `gameplay` | `world` | `networking` | `persistence` | `ui` | `ux` | `governance`

**Separación de responsabilidades:**
```
Decision Log  = conocimiento arquitectónico — por qué importa
Git           = historial técnico — qué cambió
Tickets       = trabajo operativo — qué hay que hacer
              (generado por sync-tickets.yml — no editar manualmente)
```

**Costo de corrección:**

```
C1 — Sin costo
  Error corregible sin intervención humana.
  Ningún archivo consumió el estado incorrecto.
  Ejemplos: añadir entrada al log, actualizar estado de ticket

C2 — Costo bajo
  Error localizado. Requiere intervención humana.
  Ejemplos: modificar sección de /docs

C3 — Costo alto
  Error propagado. Requiere auditoría completa.
  Ejemplos: modificar sección del AI_CONTEXT_MASTER, cambiar contratos

C4 — Costo crítico
  Error afecta principios, entidades o contratos fundamentales.
  Daño puede ser invisible hasta que algo falla en producción.
  Ejemplos: cambios a Principios Congelados, eliminar entradas del log
```

**Tabla de autorización:**
```
C1 → AUTO     Orchestrator o Subagent ejecuta sin confirmación
C2 → CONFIRM  Product Owner aprueba antes de ejecutar
C3 → CONFIRM  Product Owner aprueba antes de ejecutar
C4 → MANUAL   Product Owner ejecuta — fuera del ciclo de agentes
```

**Campos requeridos en Decision Log al estado DECISION (Clase A únicamente):**
```
Ejecución:  AUTO | CONFIRM | MANUAL
Costo:      C1 | C2 | C3 | C4
Pipeline:   P1 | P2/P4 | P3 | P5 | P6
```

### 6.5 Agent Roster

**Orchestrators (Tipo B):**

| Agente | Tipo funcional | Knowledge Domain | Prompt | Archivos que consume |
|---|---|---|---|---|
| Auditor TECH (Codex) | Auditor | TECH | AUDITOR_TECH.md | §1+§2+§4+§5+§6, Decision Log, código, tickets |
| Auditor DESIGN (Claude) | Auditor | DESIGN | AUDITOR_DESIGN.md | §1+§2+§3+§5+§6, Decision Log, tickets |

**Subagents (Tipo D):**

| Agente | Tipo funcional | Knowledge Domain | Prompt | Archivos que consume |
|---|---|---|---|---|
| Scratchpad Intake | Especial | DESIGN + TECH | SCRATCHPAD_INTAKE.md | SCRATCHPAD, AI_CONTEXT_MASTER, Decision Log |
| Gameplay Engineer | Constructor | TECH | GAMEPLAY_ENGINEER.md | §4, tickets Gameplay |
| World Engineer | Constructor | TECH | WORLD_ENGINEER.md | §4, tickets World |
| Networking Engineer | Constructor | TECH | NETWORKING_ENGINEER.md | §4.2+§4.3, tickets Networking |
| Persistence Engineer | Constructor | TECH | PERSISTENCE_ENGINEER.md | §4.7, tickets Persistence |
| UI Engineer | Constructor | TECH | UI_ENGINEER.md | §4, tickets UI |
| Gameplay Designer | Ideador | DESIGN | GAMEPLAY_DESIGNER.md | §2+§3, Decision Log |
| World Designer | Ideador | DESIGN | WORLD_DESIGNER.md | §2+§3, Decision Log |
| UX Designer | Ideador | DESIGN-UX | UX_DESIGNER.md | §3.7, Decision Log |

### 6.6 GitHub Actions

**Principio:** Actions gestiona cuándo. Los prompts transforman artefactos. Son capas ortogonales.

**Regla absoluta:** Actions nunca escribe en archivos Tipo B+D. Dispara y notifica únicamente. Única excepción de escritura: `sync-tickets.yml` actualiza el campo `Estado` de TICKETS.md (Tipo D, generado — §6.1), en dirección única Project → archivo, y **siempre via PR automergeado** (rama `bot/sync-tickets` + `automerge-sync.yml`) — nunca push directo a main (DL-030).

**Fronteras — qué nunca automatiza Actions:**
```
× Decisión del PO sobre una PROPOSAL
× Actualización del AI_CONTEXT_MASTER
× Asignación de Domain UNKNOWN
× Escritura en archivos Tipo B+D
```

**Automatización real disponible hoy (con Codex en el repo):**
```
domain:tech post-merge  → Codex ejecuta AUDIT_MODE=TECH directamente
P3 auditoría TECH       → Codex ejecuta en el cron sin intervención humana
domain:both paso TECH   → Codex ejecuta; si pasa, humano activa Claude para DESIGN

Sigue siendo manual:
  P1 intake        → humano activa Claude (requiere Context Master completo)
  Auditoría DESIGN → humano activa Claude
  Decisiones PO    → siempre humano
```

**Workflows:**

```yaml
# p1-intake.yml — push a docs/SCRATCHPAD.md
# Notifica al developer que hay entradas pendientes de procesar.
# No ejecuta el intake — el developer lo activa manualmente con Claude.

# p2-implementation.yml — PR events
jobs:
  validate-commit-convention:
    # commitlint con .github/commitlintrc.yml
    # Bloquea PR si algún commit no cumple la convención.

  validate-pr-labels:
    # Requiere domain:* y class:* en cada PR.
    # Sin ambos: PR no puede mergearse.
    # Si PR modifica /docs/ (excluyendo /docs/human/) con class:b:
    #   warning "Posible misclasificación — confirmar class:b es intencional."

  notify-self-review:
    # Al pasar de draft a ready_for_review: recuerda ejecutar self-review.

  create-codex-audit-issue:
    # Post-merge con class:a:
    #   domain:tech   → Codex ejecuta AUDIT_MODE=TECH directamente.
    #   domain:design → notifica. Humano activa Claude.
    #   domain:both   → Codex ejecuta TECH. Si pasa: humano activa Claude para DESIGN.

# p3-periodic-audit.yml — cron lunes 9:00 UTC
jobs:
  create-audit-issue:
    # Crea issue "P3 Auditoría pendiente — [fecha]".
    # PO cierra manualmente post-ejecución DESIGN.
    # Issues acumulados = omisiones visibles.

  run-tech-audit:
    # Codex ejecuta AUDIT_MODE=TECH directamente.
    # Lee: Decision Log, código modificado desde última auditoría, tickets.
    # Output: hallazgos T1–T4 como comentario en el issue.
    # Incluye: entradas UNKNOWN, entradas estancadas, notas de CM pendientes.

# validate-scratchpad.yml — push a docs/SCRATCHPAD.md
# Warning (no bloqueo) si la estructura canónica está mal.
# El Intake detecta input malformado y falla gracefully.

# validate-decision-log.yml — push a docs/PROJECT_DECISION_LOG.md
# Warning (no bloqueo) si entradas en DECISION tienen campos vacíos.
# Verifica: Ejecución, Costo, Pipeline en DECISION; Hipótesis en PROPOSAL.

# sync-tickets.yml — cron cada 6 horas + workflow_dispatch
# GitHub Project → campo Estado de TICKETS.md (unidireccional).
# Nunca pushea a main: rama bot/sync-tickets + PR etiquetado (DL-030).
# Requiere PROJECT_NUMBER (variable), PROJECTS_TOKEN (PAT clásico
# read:project) y SYNC_BOT_TOKEN (solo repo — sin Projects).
# Ver .github/PROJECT_SETUP.md secciones 6.2 y 6.5.

# automerge-sync.yml — pull_request (head: bot/sync-tickets)
# Mergea (squash) los PRs del bot de sync — solo si el diff toca
# exclusivamente docs/TICKETS.md. Requiere "Allow auto-merge" activo.
```

**Configuración de commitlint (`.github/commitlintrc.yml`):**
```yaml
extends:
  - '@commitlint/config-conventional'
rules:
  type-enum:
    - 2
    - always
    - [feat, fix, refactor, docs, chore]
  scope-enum:
    - 2
    - always
    - [gameplay, world, networking, persistence, ui, ux, governance]
  body-max-line-length:
    - 0
```

**Labels de PR requeridos:**
```
domain:tech | domain:design | domain:both
class:a | class:b
```

---

## Modo Auditor

Activación: `"actúa como Auditor"`, `"modo Auditor"`, `"audita esto"`.

El Auditor busca exclusivamente desviaciones de este documento. No rediseña sistemas, no propone features, no aprueba cambios.

Formato de output:
```
AUDITORÍA — [material revisado]

PROBLEMA [n]: [nombre]
  Dominio: TECH | DESIGN
  Código: T1–T4 | D1–D4
  Sección violada: §N.N
  Evidencia: [qué se observa]
  Impacto: [consecuencia concreta]
  Corrección mínima: [lo estrictamente necesario]

VEREDICTO: Aprobado / Aprobado con observaciones / Rechazado
```

Si no hay problemas: `"Sin problemas detectados. Aprobado."`

---

## Historial de versiones

| Versión | Fecha | Cambios |
|---|---|---|
| 5.6 | 2026-07-12 | Gobernanza del eje no-funcional y del coste del implementador. Nueva §5.9 (Modelo de Coste del Implementador, DL-032): las heurísticas se calibran a coste-IA + revisor + runtime, nunca a coste-humano-implementador — distingue restricción de número y detecta la inconsistencia N1/N2 del límite ≤7 RemoteEvents. Nueva Regla de derivación de tickets en §5.5: todo ticket traza a una DECISIÓN del DL o a un Principio/hito, con conjunto completo de tickets de habilitación derivados bajo coste-IA (campo `Deriva de`). Alta retroactiva de WLD-000 (MapBootstrap) y GAM-009 (PrefabRegistry) como primera aplicación de la regla. |
| 5.5 | 2026-07-12 | Endurecimiento de arquitectura `src/`: formalizado el contrato `ObjectId → asset` en un módulo dedicado `PrefabRegistry` (§4.4, §4.1, §4.5, DL-031) — cierra el hueco entre `ObjectDefinition` y `ServerStorage/ObjectPrefabs` sin acoplar `ObjectManager` a Studio ni referenciar modelos desde los datos. `validate()` audita el contrato al bootstrap. |
| 5.4 | 2026-07-11 | Directrices del PO + arranque del vertical slice: estándar de calidad profesional desde la primera versión pública y reloj del roadmap reiniciado — slice al 2026-08-11 (§1.3, §5.7, DL-024). Suscripción selectiva de timer en ClientStateManager (§4.10, DL-025). Payloads: objectId en ObjectStateChanged, eventType opcional en RoundStarted (§4.3, DL-026). Contrato de restauración de WalkSpeed (DL-027). Contrato Layout → Gameplay (Tags ObjectSpawn/TruckZone) y módulo MapBootstrap (§4.4, DL-028). INV-001 enmendado: OnServerEvent:Connect solo en CarryManager (§4.3, §4.6, §4.10, §5.0, DL-029). |
| 5.3 | 2026-07-10 | Auditoría arquitectónica: ciclo de sesión de PlayerData atado al jugador, no a la ronda (§4.4, §4.7 — se añade `releasePlayer`; `savePlayer` es flush, nunca EndSession). StoryEvent gana `Timestamp` relativo al inicio de ronda (§4.4). Definición del código G5 (§5.3). Mecanismo real del ban print/warn: grep `contract-logger-usage`, no Selene (§5.0). Roadmap Semana 1: ProfileStore, no "DataStore básico" (§5.7). Correcciones factuales de §4.1, §4.11, §6.2, §6.3 y §6.6 (paths de config, ServerPackages, commitlintrc, sync-tickets, cron UTC). Nota de prefijos GM/QA (§5.1). |
| 5.2 | 2026-06-06 | Versión de bootstrap del proyecto. |
