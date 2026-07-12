# PROJECT_DECISION_LOG — Mudanza Caótica

**Versión:** 1.0
**Referencia:** AI_CONTEXT_MASTER v5.4 §5.4  
**Última actualización:** 2026-07-11

---

## Uso de este archivo

Este archivo registra **conocimiento arquitectónico** — por qué importó una decisión.
No es historial técnico (eso es Git). No es trabajo operativo (eso es TICKETS.md).

**Solo los cambios Clase A generan entrada aquí.**
Los cambios Clase B se registran únicamente en Git con commit descriptivo.

**La unidad atómica** es un cambio de conocimiento arquitectónico que responde exactamente una de estas preguntas:
1. ¿Qué existe ahora que antes no existía? → entidad nueva
2. ¿Qué regla cambió? → principio o contrato
3. ¿Qué comportamiento sistémico es distinto? → API o invariante
4. ¿Qué ownership cambió? → responsabilidad de dominio

Si una idea responde más de una → se divide en entradas separadas.
Si no responde ninguna → es Clase B. Solo commit.

---

## Schema de entrada

```
ID:          DL-[número]
Fecha:       YYYY-MM-DD
Domain:      TECH | DESIGN | BOTH | UNKNOWN
Tipo:        OBSERVATION | QUESTION | HYPOTHESIS | PROPOSAL
Estado:      DISCOVERY | PROPOSAL | DECISION | AUDIT
Contexto:    [situación que generó la entrada]
Contenido:   [idea, observación, pregunta o propuesta]
Hipótesis:   [qué podría ser verdad — vacío en OBSERVATION]
Razón:       [por qué se tomó esta decisión — vacío hasta DECISION]
Impacto:     [qué cambia — vacío hasta DECISION]
Ejecución:   AUTO | CONFIRM | MANUAL — vacío hasta DECISION
Costo:       C1 | C2 | C3 | C4 — vacío hasta DECISION
Pipeline:    P1 | P2/P4 | P3 | P5 | P6 — vacío hasta DECISION
Ticket:      [DOMINIO]-[número] — vacío hasta que exista
Commit:      [hash] — vacío hasta que exista
Referencias: [§N.N del Context Master, otros DL-, T-]
```

---

## Valores válidos por estado

| Estado | Domain UNKNOWN | Hipótesis | Razón | Ejecución/Costo/Pipeline |
|---|---|---|---|---|
| DISCOVERY | Sí | No | No | — |
| PROPOSAL | No | Sí | No | — |
| DECISION | No | Sí | Sí | Requeridos |
| AUDIT | No | Sí | Sí | Heredado de DECISION |

---

## Entradas

> **Nota de bootstrap (2026-07-10):** Las entradas DL-001 a DL-019 documentan
> decisiones fundacionales tomadas antes de que el ciclo P1 (SCRATCHPAD →
> intake → auditoría → decisión del PO) estuviera operativo. Son retroactivas:
> las decididas se registran con Tipo PROPOSAL (§5.4 — DECISION es un Estado,
> no un Tipo) y las que no registraron hipótesis explícita llevan
> "N/A — entrada retroactiva de bootstrap". Sus campos Ticket quedaron vacíos
> porque los 30 tickets iniciales de TICKETS.md se derivaron directamente del
> AI_CONTEXT_MASTER en el mismo bootstrap (por eso tampoco llevan DL-Ref).
> Toda entrada posterior a esta nota debe nacer del ciclo P1 o ser creada
> directamente por un Orchestrator (§5.4 — Origen de entradas).

---

### DL-001

```
ID:          DL-001
Fecha:       2026-06-06
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Fundación del sistema de governance del proyecto. Necesidad de
             separar arquitectura de diseño y arquitectura técnica sin dividir
             el documento principal en múltiples archivos que puedan diverger.
Contenido:   El AI_CONTEXT_MASTER adopta estructura de 6 secciones:
             §1 Filosofía, §2 Fundamentos Transversales, §3 Design Architecture,
             §4 Technical Architecture, §5 Governance, §6 Operational Architecture.
Hipótesis:   Una estructura jerárquica con Fundamentos Transversales como capa
             compartida permite que los auditores filtren por dominio sin
             duplicar contenido crítico.
Razón:       El documento anterior mezclaba principios de diseño, contratos
             técnicos y normas operativas en secciones sin separación clara.
             Los agentes no podían operar en AUDIT_MODE=TECH sin leer
             contenido irrelevante de diseño y viceversa.
Impacto:     Todos los agentes del proyecto referencian secciones del
             AI_CONTEXT_MASTER por número. Un cambio de numeración requiere
             actualizar todos los prompts.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §1, §2, §3, §4, §5, §6
```

---

### DL-002

```
ID:          DL-002
Fecha:       2026-06-06
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Necesidad de establecer la estructura canónica del repositorio
             basada en Rojo antes de implementar cualquier código, para que
             los agentes y los humanos usen la misma referencia de paths.
Contenido:   La estructura de carpetas del proyecto se basa en Rojo
             (default.project.json), no en la estructura de Roblox Studio.
             La tabla de mapeo Rojo → Runtime es la fuente de verdad.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Usar Studio como referencia crearía divergencia entre el repo
             y la documentación desde el día uno. Rojo es la única fuente
             de verdad del código fuente.
Impacto:     Toda referencia a paths en el proyecto usa la estructura src/.
             Los agentes que generan código deben respetar esta estructura.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.1, §6.2
```

---

### DL-003

```
ID:          DL-003
Fecha:       2026-06-06
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Necesidad de definir cómo fluye una idea desde su concepción
             hasta su implementación, con trazabilidad completa y sin
             pérdida de contexto entre pasos.
Contenido:   El ciclo de vida de un cambio Clase A sigue el flujo:
             SCRATCHPAD → INTAKE → DISCOVERY → PROPOSAL → DECISION
             → TICKET → IMPLEMENTACIÓN → AUDIT.
             Los cambios Clase B solo generan commit descriptivo.
Hipótesis:   Separar cambios arquitectónicos de cambios locales reduce
             el ruido documental sin sacrificar trazabilidad crítica.
Razón:       Sin esta separación, el Decision Log se convierte en un
             segundo Git — registra todo en lugar de registrar lo que importa.
             La unidad atómica es el cambio de conocimiento, no la tarea.
Impacto:     Todo el sistema de governance depende de esta clasificación.
             Un cambio mal clasificado como Clase B omite auditoría y
             puede introducir deuda arquitectónica invisible.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §5.4, §5.5, §6.4
```

---

### DL-004

```
ID:          DL-004
Fecha:       2026-06-06
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Necesidad de formalizar la distinción entre Orchestrators y
             Subagents para que los prompts de agentes tengan contratos
             claros de qué pueden y no pueden hacer.
Contenido:   Los Orchestrators (Auditor TECH, Auditor DESIGN) tienen visión
             global y producen solo hallazgos. Los Subagents (Constructores,
             Ideadores, Intake) tienen scope acotado y producen artefactos
             específicos. Un agente no puede ocupar dos tipos en el mismo ticket.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Sin esta distinción, los agentes mezclan auditoría e
             implementación en el mismo ciclo, lo cual hace los hallazgos
             no verificables y el output no predecible.
Impacto:     Todos los prompts del proyecto heredan de esta taxonomía.
             Un agente que cruza tipos invalida la auditoría del ciclo completo.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §5.6, §6.5
```

---

### DL-005

```
ID:          DL-005
Fecha:       2026-06-06
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Necesidad de integrar automatización al ciclo de governance
             sin introducir actores que escriban en archivos críticos
             sin autorización.
Contenido:   GitHub Actions gestiona triggers y gates. Los prompts
             transforman artefactos. Actions nunca escribe en archivos
             Tipo B+D. Codex (con acceso al repo) ejecuta auditorías
             TECH automáticamente post-merge y en P3. Claude se activa
             manualmente para auditorías DESIGN y el intake de P1.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Sin esta separación de responsabilidades, la automatización
             puede modificar el Context Master o el Decision Log sin
             autorización del PO, violando §6.4 (C3 requiere CONFIRM).
Impacto:     El nivel de automatización disponible en el proyecto está
             acotado por esta decisión. Expandir la autonomía de Codex
             requiere una nueva entrada Clase A.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §6.3, §6.4, §6.6
```

---

### DL-006

```
ID:          DL-006
Fecha:       2026-06-06
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Necesidad de un mecanismo de ingestión de ideas que filtre
             contenido humano sin estructura antes de que entre al ciclo
             formal del proyecto.
Contenido:   El SCRATCHPAD.md es la zona de ingestión del desarrollador.
             El Subagent SCRATCHPAD_INTAKE filtra y formaliza las entradas
             antes de que lleguen al Decision Log. Las entradas rechazadas
             se mueven a ## Rechazadas — no se eliminan hasta revisión del PO.
             El mecanismo de apelación (WF-010) permite bypass via P5.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Sin este filtro, ideas no formalizadas o contradictorias con
             los Principios Congelados pueden entrar directamente al log
             y contaminar el ciclo de auditoría.
Impacto:     El SCRATCHPAD es el único punto de entrada para ideas humanas
             al ciclo formal. Todo lo que no pase por aquí es P5 con nota
             de contingencia.
Ejecución:   AUTO
Costo:       C1
Pipeline:    P1
Ticket:      —
Commit:      —
Referencias: §5.8, §6.3
```

---

### DL-007

```
ID:          DL-007
Fecha:       2026-06-13
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Tickets UI-001/002/003 dependían de un patrón de consumo de
             RemoteEvents no definido. Sin convención, cada módulo UI
             implementaría su propio sistema de listeners produciendo
             duplicación, memory leaks y limpieza inconsistente.
Contenido:   ClientStateManager es el único módulo del cliente que conecta
             RemoteEvents. Los módulos de UI se suscriben a él via subscribe().
             Ningún otro módulo llama Networking.*:Connect().
Hipótesis:   Centralizar el consumo de estado elimina duplicación y garantiza
             limpieza coherente entre rondas.
Razón:       Patrón proveedor/consumidor: ClientStateManager es proveedor,
             UI es consumidor. Los proveedores se diseñan antes que los consumidores.
Impacto:     Tickets UI-001, UI-002, UI-003 bloqueados hasta que
             ClientStateManager.lua exista. Cualquier futuro módulo de UI
             hereda el patrón sin decisiones adicionales.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.10, §4.6
```

---

### DL-008

```
ID:          DL-008
Fecha:       2026-06-13
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Sin convención de audio, los módulos de gameplay implementarían
             sonidos directamente (sound:Play() en CarryManager, TruckManager,
             etc.), produciendo acoplamiento gameplay→audio que requeriría
             retrofit al implementar AudioManager.
Contenido:   Todo audio y VFX reacciona a RemoteEvents — nunca es llamado
             directamente desde módulos de gameplay. AudioManager se implementa
             en Semana 3 conectando los RemoteEvents existentes.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Los RemoteEvents ya existen para comunicar estado. AudioManager
             los consume igual que ClientStateManager. Ningún módulo de gameplay
             necesita modificarse cuando AudioManager se implemente.
Impacto:     Cero retrofit en módulos de gameplay al añadir audio/VFX.
             sound:Play() fuera de AudioManager es prohibición explícita en §4.6.
Ejecución:   AUTO
Costo:       C1
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.9, §4.6
```

---

### DL-009

```
ID:          DL-009
Fecha:       2026-06-13
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    EventManager y Summary Screen (WLD-005, WLD-006, UI-003)
             necesitan un contrato de StoryEvents antes de implementarse.
             Sin schema, cada módulo usaría strings arbitrarios como EventType
             produciendo acoplamiento implícito imposible de auditar.
Contenido:   StoryEvent = { EventType, Data, Timestamp }. Los EventTypes
             canónicos se registran en Config/Events.lua antes de usarse
             en cualquier módulo. recordStoryEvent() solo acepta EventTypes
             registrados.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Unidad atómica: el contrato de StoryEvents es una regla que
             cambia el comportamiento sistémico. Sin él, EventManager y
             Summary Screen no pueden implementarse coherentemente.
Impacto:     WLD-005, WLD-006, UI-003 bloqueados hasta que Config/Events.lua
             tenga el schema y EventTypes canónicos definidos.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.4, §3.7
```

---

### DL-010

```
ID:          DL-010
Fecha:       2026-06-13
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Múltiples módulos necesitaban constantes (MAX_INTERACT_RANGE,
             NPC_SPEED, ROUND_DURATION, LOG_LEVEL) sin un lugar canónico
             para leerlas. Sin schemas de Config, cada módulo hardcodearía
             sus propios valores o los duplicaría.
Contenido:   Cuatro archivos Config con schemas canónicos:
             GlobalConfig (constantes transversales + feature flags),
             RoundConfig (ciclo de ronda), GameplayConfig (mecánicas),
             Events (StoryEvents + pool). Ningún módulo hardcodea valores
             que aparecen en más de un archivo.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       INV-004 es prerequisito de GAM-008 (balance post-playtest).
             Sin schemas definidos, el ajuste de parámetros no tiene
             un lugar canónico donde ocurrir.
Impacto:     GAM-008 bloqueado hasta que los Config schemas estén en uso.
             Todo ajuste de balance post-playtest ocurre en Config/ sin
             modificar lógica de módulos.
Ejecución:   AUTO
Costo:       C2
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.1, §4.6
```

---

### DL-011

```
ID:          DL-011
Fecha:       2026-06-16
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    El proyecto necesitaba toolchain management, formateo y linting
             estandarizados antes del primer commit de código real, para que
             ningún módulo se implementara sin convenciones de calidad.
Contenido:   Rokit gestiona versiones de Rojo, Wally, wally-package-types,
             StyLua y Selene via rokit.toml. StyLua formatea con config en
             .stylua.toml. Selene lintea con std="roblox+testez" via
             selene.toml + testez.yml oficial. Wally gestiona dependencias
             externas via wally.toml, con wally-package-types generando
             tipos sobre Packages/ usando el sourcemap de Rojo.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Sin estas herramientas desde el inicio, el código divergería en
             estilo entre Constructores y no habría detección automática de
             errores comunes de Luau antes de merge.
Impacto:     p2-implementation.yml gana jobs format-check y lint-check que
             bloquean merge. §4.11 documenta el pipeline de Wally. La
             estructura del repo en §6.2 incluye los 5 archivos de config.
Ejecución:   AUTO
Costo:       C1
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.11, §6.2, §6.6
```

---

### DL-012

```
ID:          DL-012
Fecha:       2026-06-16
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Los Issues de Codex contenían checklists que mezclaban contratos
             verificables por grep/conteo con juicio arquitectónico real.
             Esto subutilizaba CI y sobreutilizaba la IA para trabajo
             que no requería interpretación.
Contenido:   Jerarquía de 4 niveles de verificación implementada en §5.0:
             Nivel 1 (CI: contratos funcionales y estructurales),
             Nivel 2 (CI: contratos de mantenibilidad con umbrales),
             Nivel 3 (IA: patrones sospechosos y candidatos a CI),
             Nivel 4 (Humano: evaluación del modelo).
             p2-implementation.yml gana 4 jobs de Nivel 2:
             module-size (≤300 líneas), layer-separation (server≠client),
             test-coverage-persistence (specs para módulos críticos).
             AUDITOR_TECH reescrito para operar solo en Nivel 3.
             Issues de Codex adelgazados — no repiten lo que CI ya verificó.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Si una regla puede expresarse como condición binaria verificable,
             debe convertirse en CI. La IA queda para lo que genuinamente
             requiere juicio sobre el código como sistema.
Impacto:     El sistema mejora hacia determinismo total en la medida que
             el Auditor TECH identifica candidatos a CI en cada P3.
             La carga del Auditor TECH se reduce con el tiempo.
Ejecución:   AUTO
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §5.0, §6.6
```

---

### DL-013

```
ID:          DL-013
Fecha:       2026-06-16
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    Los specs de TestEZ solo podían correr en Studio, lo que
             impedía verificación automática en pre-commit y CI headless.
             Se necesitaba un mecanismo para correr Luau fuera de Roblox
             y para detectar violaciones de contratos antes de que el
             desarrollador iniciara un PR.
Contenido:   Lune añadido a rokit.toml como runtime de Luau standalone.
             lune/check-compatibility.luau verifica la invariante de
             inyección de dependencias (ningún módulo accede a globals
             de Roblox en scope de módulo).
             lune/run-specs.luau corre specs de TestEZ sin Studio.
             Lefthook añadido a rokit.toml — lefthook.yml define hooks
             de pre-commit que verifican Nivel 1 y Nivel 2 localmente
             antes de crear el commit.
             Las fases 2-4 (refactor de módulos, CI headless, formalización)
             dependen de los resultados de lune/check-compatibility.luau
             en el proyecto real.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       El objetivo es que las reglas sean verificables lo antes
             posible — pre-commit es más inmediato que CI, que es más
             inmediato que la auditoría de IA.
Impacto:     El desarrollador recibe feedback de violaciones de contratos
             en el momento del commit, sin necesidad de PR ni auditoría.
             lune/check-compatibility.luau es el prerequisito de Fase 2
             (refactor con inyección de dependencias).
Ejecución:   AUTO
Costo:       C2
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.6, §5.0, §6.2
```

---

### DL-014

```
ID:          DL-014
Fecha:       2026-06-16
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    lune/check-compatibility.luau ejecutado sobre los 7 módulos
             Nivel -1/0 existentes. 3 fallaron inicialmente: Networking.lua,
             GlobalConfig.lua, Events.lua — todos por game:GetService()
             en scope de módulo. Además, un bug en el tracking de
             profundidad de bloques del propio checker (solo contaba
             function/end, no if/for/while/do) producía falsos positivos
             en módulos que sí tenían inyección de dependencias correcta.
Contenido:   Los 3 módulos refactorizados: Networking.lua usa inicialización
             lazy con setmetatable/__index; GlobalConfig.lua envuelve
             RunService en pcall retornando false en entornos sin DataModel;
             Events.lua mueve CollectionService/TweenService dentro de
             start(). El checker corregido para contar todos los keywords
             de bloque (function/if/for/while/do) contra end, evaluando
             cada línea con la profundidad previa a sus propios cambios.
             7/7 módulos ahora compatibles con Lune.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       El checker es una heurística de patrón de texto, no un parser
             AST real. Es suficiente para el patrón de código que los
             prompts de Constructor enseñan, pero tiene falsos negativos
             documentados (GetService sin paréntesis, con variable, acceso
             indirecto, comentarios multilínea). Esto se documenta
             explícitamente en el script y en §5.0 para que nadie lo
             trate como garantía formal.
Impacto:     Los 7 módulos del Nivel -1/0 son ahora ejecutables en Lune.
             Fase 4 (CI headless + specs en pre-commit) queda desbloqueada.
             Un reemplazo del checker por análisis AST real queda
             registrado como candidato futuro para el Auditor TECH (Nivel 3).
Ejecución:   AUTO
Costo:       C2
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.6, §5.0
```

---

### DL-015

```
ID:          DL-015
Fecha:       2026-06-17
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    El proyecto necesitaba decidir explícitamente qué paquetes de
             Wally adoptar para áreas críticas, aplicando criterio profesional
             en lugar de minimalismo por defecto o adopción indiscriminada.
             MVP significa "primera versión jugable", no "arquitectura floja".
Contenido:   Adoptados: ProfileStore (lm-loleris/profilestore@1.0.3,
             server-dependency) para persistencia — reemplaza a
             DataStoreService.lua como módulo propio. Promise
             (evaera/promise@4.0.0) para manejo asíncrono. Janitor
             (howmanysmall/janitor@1.18.3) para lifecycle de conexiones
             en módulos UI (HUDManager, SummaryManager) — no en
             ClientStateManager, cuyo patrón subscribe()-por-clave resuelve
             un problema de forma distinta.
             Rechazados: BridgeNet2/Net — resuelven batching de alta
             frecuencia; el proyecto tiene ≤7 RemoteEvents a escala humana,
             no ese problema.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Criterios objetivos: (1) severidad del riesgo si se implementa
             a mano, (2) track record en producción, (3) mantenimiento activo,
             (4) compatibilidad con invariantes del proyecto, (5) disciplina
             de scope — no importar complejidad sin problema correspondiente.
             Session locking mal implementado produce pérdida de datos —
             severo, raro, difícil de testear. Ese es el caso donde adoptar
             es la decisión profesional, no la floja.
Impacto:     DataStoreService.lua eliminado del proyecto — su responsabilidad
             la absorbe ProfileStore. PlayerDataService.lua se convierte en
             wrapper delgado. Tickets PER-001/PER-003 reescritos.
             PERSISTENCE_ENGINEER.md y UI_ENGINEER.md reescritos.
             wally.toml actualizado con [server-dependencies].
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.7, §4.10, §4.11
```

---

### DL-016

```
ID:          DL-016
Fecha:       2026-06-17
Domain:      TECH
Tipo:        OBSERVATION
Estado:      AUDIT
Contexto:    Durante la reescritura de UI_ENGINEER.md para adoptar Janitor,
             se detectó que los patrones de HUDManager y SummaryManager
             conectaban Networking.*.OnClientEvent directamente, violando
             INV-001 (Networking.*:Connect() solo debe aparecer en
             ClientStateManager.lua). El bug estaba en el prompt desde su
             creación original — nadie lo había ejecutado todavía porque
             UI-001/002/003 seguían BLOCKED esperando esta corrección.
Contenido:   HUDManager y SummaryManager reescritos para suscribirse a
             ClientStateManager.subscribe() en lugar de conectar
             RemoteEvents directamente. Corrige la violación antes de que
             cualquier Constructor la implemente.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Un prompt con un patrón de código incorrecto es tan peligroso
             como código incorrecto en el repo — el Constructor que lo siga
             al pie de la letra reproduce la violación automáticamente.
Impacto:     UI-001/002/003 ahora referencian un patrón correcto. Ningún
             código de producción llegó a implementar la violación —
             detectado antes de ejecución.
Ejecución:   AUTO
Costo:       C2
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §4.10, §6.6
```

---

### DL-017

```
ID:          DL-017
Fecha:       2026-06-17
Domain:      TECH
Tipo:        OBSERVATION
Estado:      AUDIT
Contexto:    Al escribir instrucciones de Git multiplataforma para el
             ONBOARDING, se detectó que .stylua.toml fuerza
             line_endings = "Unix" pero nada en el repo garantiza que
             Git normalice line endings — un desarrollador en Windows
             con core.autocrlf=true (configuración común) checkearía
             CRLF, causando diffs falsos en cada archivo y conflicto
             directo con StyLua en cada commit.
Contenido:   .gitattributes añadido: `* text=auto eol=lf` normaliza todos
             los archivos de texto a LF en el repositorio y checkout,
             independientemente del OS o configuración local del
             desarrollador. Elimina la dependencia de que cada persona
             configure su Git correctamente — la regla es determinista
             a nivel de repo, no de configuración individual.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Consistente con el principio del proyecto de convertir
             reglas dependientes de disciplina individual en mecanismos
             deterministas (§5.0). Line-ending handling es exactamente
             ese tipo de regla.
Impacto:     Ningún desarrollador necesita configurar core.autocrlf
             manualmente. Previene una clase de bug que solo se
             manifestaría al incorporar un colaborador en Windows.
Ejecución:   AUTO
Costo:       C1
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §5.0, §6.2
```

---

### DL-018

```
ID:          DL-018
Fecha:       2026-06-17
Domain:      TECH
Tipo:        PROPOSAL
Estado:      AUDIT
Contexto:    El campo "Semana" del GitHub Project era un campo custom
             Single-select que había que rellenar manualmente por Issue.
             GitHub tiene una feature nativa (Milestones) para agrupación
             temporal con barra de progreso y fecha límite gratis, que no
             había sido evaluada — no por rechazo deliberado, sino por
             no haberla considerado en el diseño original del Project.
Contenido:   Milestones nativos de GitHub reemplazan el campo custom
             "Semana". Se crean 4 Milestones (Semana 1-4) con fecha límite.
             Cada Issue se asigna a su Milestone al crearse. Los campos
             custom del Project se reducen a Domain y DL-Ref — Semana ya
             no requiere campo custom porque GitHub Projects v2 puede
             agrupar/filtrar por Milestone nativamente.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Los Milestones dan barra de progreso y fecha límite sin
             configuración adicional — algo que el campo custom no ofrecía.
             Con el repo público, la señal de progreso por semana es útil
             sin necesidad de abrir el board.
Impacto:     PROJECT_SETUP.md reescrito: nueva sección de Milestones,
             tabla de campos custom reducida. TICKETS.md no cambia — su
             campo Semana es informativo para IAs y no depende de GitHub.
Ejecución:   CONFIRM
Costo:       C1
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §6.6
```

---

### DL-019

```
ID:          DL-019
Fecha:       2026-06-17
Domain:      TECH
Tipo:        OBSERVATION
Estado:      AUDIT
Contexto:    sync-tickets.yml usaba github.rest.projects.listForRepo /
             listColumns / listCards — API REST de Projects Classic,
             deprecada por GitHub. Los Projects creados hoy son v2, que
             usa exclusivamente GraphQL y no tiene el concepto de
             "card.note" (texto libre) — usa Issues/PRs/DraftIssues como
             items con fieldValues tipados. El workflow habría fallado
             en el primer intento de sincronización real.
             Adicionalmente: el GITHUB_TOKEN automático de Actions no
             tiene permisos para leer Projects v2 bajo ningún scope —
             es una limitación de la plataforma, requiere un PAT
             (Personal Access Token) con scope "project".
Contenido:   sync-tickets.yml reescrito completo con GraphQL contra
             ProjectV2, paginación via items(first, after)/pageInfo,
             lectura de fieldValues tipados (ProjectV2ItemFieldSingleSelectValue),
             y extracción del ticket ID desde content.title del Issue
             (antes: card.note). Requiere dos configuraciones nuevas:
             repo variable PROJECT_NUMBER y repo secret PROJECTS_TOKEN
             (PAT con scope project:read). PROJECT_SETUP.md documenta
             ambos pasos con instrucciones exactas de creación del PAT.
Hipótesis:   N/A — entrada retroactiva de bootstrap: decisión fundacional
             documentada post-hoc, antes de que el ciclo P1 estuviera
             operativo (ver nota al inicio de ## Entradas)
Razón:       Un mecanismo documentado como funcional que en realidad no
             puede ejecutarse es peor que no tener el mecanismo — genera
             falsa confianza. Se corrige antes de que el PO dependa de él.
Impacto:     La sincronización Project → TICKETS.md ahora es técnicamente
             viable. Sin la configuración del PAT (§6.2-6.3 de
             PROJECT_SETUP.md), el workflow falla con mensaje explícito
             señalando la causa — no falla silenciosamente.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §6.6
```

---

### DL-020

```
ID:          DL-020
Fecha:       2026-07-10
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Auditoría arquitectónica (P3, 2026-07-10) detectó una
             contradicción de ciclo de vida en persistencia: §4.4 ordenaba
             savePlayer() en cada transición Summary → Lobby, PER-003
             definía savePlayer como cierre de sesión (Profile:EndSession)
             y GM-003 lo mandaba llamar al final de cada ronda. Combinados,
             cerraban la sesión de ProfileStore con el jugador aún
             conectado cada ~3 minutos.
Contenido:   El ciclo de sesión de PlayerData queda atado al jugador, no a
             la ronda. API de PlayerDataService: loadPlayer(player) en
             PlayerAdded (StartSessionAsync + migrate); savePlayer(player)
             al final de ronda = Profile:Save() — flush explícito, nunca
             cierra sesión; releasePlayer(player) en PlayerRemoving =
             Profile:EndSession(), único punto de cierre. GameManager es
             el único caller (§4.8).
Hipótesis:   Atar la sesión al ciclo join/leave del jugador elimina la
             clase de bugs de session-locking y rollback que motivó la
             adopción de ProfileStore — cerrarla por transición de ronda
             invalidaba sus garantías.
Razón:       Implementar el contrato anterior al pie de la letra producía
             pérdida de datos latente — exactamente el modo de fallo
             severo y poco frecuente que §4.7 existe para evitar.
Impacto:     §4.4 (flujo GameManager) y §4.7 (API mínima de sesión)
             actualizados. PER-003 y GM-003 corregidos con criterios
             nuevos. PlayerDataService gana releasePlayer — compatible
             con PlayerDataService.spec (solo exige que loadPlayer/
             savePlayer/getData existan).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      PER-003, GM-003
Commit:      —
Referencias: §4.4, §4.7, §4.8, DL-015
```

---

### DL-021

```
ID:          DL-021
Fecha:       2026-07-10
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    §4.4 definía StoryEvent = { EventType, Data } sin Timestamp,
             mientras Config/Events.lua lo definía con Timestamp =
             os.clock(). Divergencia de contrato, y además os.clock() es
             tiempo de CPU del VM — sin significado para narrar la ronda
             en el Summary Screen.
Contenido:   Contrato unificado en §4.4 y Config/Events.lua: StoryEvent =
             { EventType, Data, Timestamp } donde Timestamp = segundos
             transcurridos desde RoundStarted, calculado por RoundManager
             (fuente única del timer).
Hipótesis:   Un timestamp relativo al inicio de ronda es lo único que el
             Summary Screen necesita para ordenar y narrar momentos —
             tiempo absoluto de servidor no aporta y complica.
Razón:       Corregir el contrato antes de que RoundManager se implemente
             evita un bug latente y una migración de datos posterior.
Impacto:     RoundManager.recordStoryEvent() debe calcular el Timestamp.
             Ningún código existente lo consumía todavía — costo cero de
             migración.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      —
Commit:      —
Referencias: §4.4, src/shared/Config/Events.lua
```

---

### DL-022

```
ID:          DL-022
Fecha:       2026-07-10
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    §5.5 paso 8 y AUDITOR_TECH.md ordenaban "emitir G5" para
             notas de Context Master pendientes, pero §5.3 solo definía
             las categorías T1–T4 y D1–D4 — G5 no existía formalmente.
Contenido:   §5.3 define la categoría de gobernanza G5: actualización del
             Context Master pendiente de confirmación del PO, emitida por
             cualquier Orchestrator cuando una entrada llega a P3 con la
             nota "⚠ Context Master update" activa. Única categoría
             compartida entre ambos auditores.
Hipótesis:   Un código usado por los prompts pero sin definición canónica
             produce hallazgos inconsistentes entre auditores.
Razón:       Los Orchestrators no pueden emitir códigos que el protocolo
             de auditoría no define — la regla central de §5.3 lo prohíbe.
Impacto:     §5.3 actualizado. AUDITOR_TECH y AUDITOR_DESIGN pueden emitir
             G5 sin violar la separación de dominios.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      —
Commit:      —
Referencias: §5.3, §5.5
```

---

### DL-023

```
ID:          DL-023
Fecha:       2026-07-10
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    §5.0 atribuía el ban de print/warn a Selene, pero selene no
             tiene un lint para prohibir globals específicos — la sección
             [rules] con print = "deny" en selene.toml no era configuración
             válida y el ban nunca estuvo activo. Además §5.0 declaraba que
             todos los contratos Nivel 1 corren en pre-commit Y CI, pero
             los specs (run-specs.luau) solo corrían en CI.
Contenido:   El ban de print/warn directos (fuera de Lib/Logger.lua) se
             implementa como contrato grep contract-logger-usage en
             lefthook.yml y p2-implementation.yml. Selene queda solo como
             linter. Se añade el job run-specs a pre-commit para cumplir
             la regla de doble ejecución de Nivel 1.
Hipótesis:   Un contrato documentado cuyo mecanismo no existe es peor que
             no tener el contrato — genera falsa confianza en el gate.
Razón:       Alinear §5.0 con mecanismos que realmente se ejecutan; los
             contratos grep son deterministas y verificables localmente.
Impacto:     selene.toml simplificado. lefthook.yml y CI ganan
             contract-logger-usage y run-specs. §5.0, AUDITOR_TECH.md,
             _BASE_CONSTRUCTOR.md y ONBOARDING.md actualizados.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      —
Commit:      —
Referencias: §5.0, §6.6, DL-013
```

---

### DL-024

```
ID:          DL-024
Fecha:       2026-07-11
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El plazo original "MVP: 1 mes" (bootstrap 2026-06-06) venció sin
             código de juego — el mes se invirtió en la infraestructura de
             gobernanza. El PO redefine el objetivo y el estándar.
Contenido:   (1) El reloj del roadmap se reinicia el 2026-07-11: vertical
             slice completo al 2026-08-11. (2) Estándar de calidad: el juego
             debe ser profesionalmente funcional desde su primera versión
             pública — "mínimo" se refiere al alcance, nunca a la calidad.
             La misma filosofía aplica a la arquitectura: se invierte diseño
             ahora para maximizar mantenibilidad y escalabilidad.
Hipótesis:   Un plazo realista anclado a una fecha concreta y un estándar de
             calidad explícito evitan tanto el scope creep como la deuda
             estructural "temporal" que nunca se paga.
Razón:       CONTINGENCY P1 — directriz directa del PO en sesión de
             auditoría (2026-07-11), sin pasar por SCRATCHPAD.
Impacto:     §1.3 y §5.7 actualizados. El plazo del header del Context
             Master ahora es una fecha, no una duración relativa.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Commit:      —
Referencias: §1.3, §5.7
```

---

### DL-025

```
ID:          DL-025
Fecha:       2026-07-11
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    ClientStateManager notificaba a TODOS los listeners en cada tick
             de TimerSync (1/segundo) — re-render de módulos que no muestran
             el timer. Observación de la auditoría arquitectónica, aprobada
             por el PO como parte del estándar de calidad (DL-024).
Contenido:   subscribe(id, listener, options?) acepta options.timerUpdates.
             Por defecto los ticks de TimerSync NO notifican; solo los
             listeners con timerUpdates = true los reciben (HUD).
Hipótesis:   La suscripción selectiva elimina el trabajo por segundo de los
             módulos sin timer sin cambiar el modelo de snapshots.
Razón:       Con UI real en el slice, el coste del re-render global por
             segundo se paga en cada frame de cada módulo suscrito.
Impacto:     §4.10 actualizado. API retrocompatible — el tercer parámetro
             es opcional y el comportamiento por defecto es más eficiente.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      UI-001
Commit:      —
Referencias: §4.10, DL-024
```

---

### DL-026

```
ID:          DL-026
Fecha:       2026-07-11
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    ObjectStateChanged no incluía objectId — ClientStateManager lo
             rellenaba con string vacío y la UI no podía distinguir tipos de
             objeto. RoundStarted declaraba eventType obligatorio pero es nil
             cuando no hay evento activo (ENABLE_EVENTS = false).
Contenido:   Payload de ObjectStateChanged: { instanceId, objectId, state,
             leaderId, supportId }. RoundStarted: { duration, eventType? }
             con eventType explícitamente opcional.
Hipótesis:   Extender el payload ahora (sin consumidores server-side aún)
             cuesta cero migración; hacerlo después exige tocar servidor,
             cliente y contrato a la vez.
Razón:       El slice implementa los emisores server-side — es el último
             momento de corregir el contrato sin refactor.
Impacto:     §4.3 actualizado. ObjectManager emite objectId en cada cambio
             de estado. ClientStateManager ya lo consume.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      GAM-002
Commit:      —
Referencias: §4.3, §4.10
```

---

### DL-027

```
ID:          DL-027
Fecha:       2026-07-11
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    GameplayConfig.BASE_WALK_SPEED estaba documentado como el valor
             al que CarryManager "restaura" la velocidad al soltar objetos —
             restaurar a una constante pisa cualquier otro modificador de
             velocidad activo (eventos futuros, efectos).
Contenido:   Contrato de restauración: CarryManager guarda el WalkSpeed
             vigente al iniciar el carry y restaura ESE valor al soltar o
             entregar. BASE_WALK_SPEED queda solo como fallback si el valor
             guardado no existe o no es válido (> 0).
Hipótesis:   Guardar/restaurar el valor previo compone correctamente con
             cualquier sistema futuro que modifique velocidad — una
             constante de restauración no compone con nada.
Razón:       GAM-005 ya exigía "no interferir con otras modificaciones de
             velocidad" — el contrato lo hace implementable sin ambigüedad.
Impacto:     GameplayConfig documenta el contrato. CarryManager lo implementa
             desde su primera versión.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P3
Ticket:      GAM-003, GAM-005
Commit:      —
Referencias: §4.4
```

---

### DL-028

```
ID:          DL-028
Fecha:       2026-07-11
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    GAM-002 exige spawn "dentro del edificio" y GAM-004 una zona de
             entrega, pero no existía contrato de tags entre el dominio World
             (layout) y los sistemas de Gameplay — solo existía el contrato
             Layout → NPCManager. Además el layout real es un asset de Studio
             (WLD-001) que no existe aún: sin él, QA-001 no es ejecutable.
Contenido:   (1) Contrato Layout → Gameplay en §4.4: Tag "ObjectSpawn" para
             puntos de spawn y Tag "TruckZone" para la zona de entrega; los
             Parts de objetos llevan Attributes InstanceId/ObjectId. (2) Nuevo
             módulo MapBootstrap: genera un edificio placeholder tagueado si
             el Workspace no contiene layout (flag ENABLE_PLACEHOLDER_MAP);
             se retira cuando exista el layout real.
Hipótesis:   Con el contrato de tags, layout real y placeholder son
             intercambiables sin tocar ningún sistema — el dominio World
             solo necesita taguear.
Razón:       El vertical slice necesita una ronda jugable desde el repo, sin
             pasos manuales de Studio como prerequisito.
Impacto:     §4.4 (contrato + tabla de módulos) actualizado. MapBootstrap en
             src/server/. WLD-001/WLD-002 conservan sus criterios — el
             placeholder los satisface temporalmente.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      WLD-001, GAM-002, GAM-004
Commit:      —
Referencias: §4.4, §4.5, DL-024
```

---

### DL-029

```
ID:          DL-029
Fecha:       2026-07-11
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    INV-001 prohibía Networking.*:Connect() fuera de
             ClientStateManager.lua — pero InteractObject (único evento
             cliente→servidor, §4.3) necesita un OnServerEvent:Connect en
             el servidor. El contrato era inimplementable tal como estaba:
             el grep de CI habría bloqueado cualquier implementación del
             lado servidor.
Contenido:   INV-001 enmendado con dos dueños únicos: OnClientEvent:Connect
             solo en ClientStateManager.lua (cliente); OnServerEvent:Connect
             solo en CarryManager.lua (servidor). Los greps de lefthook y CI
             verifican cada dirección por separado.
Hipótesis:   Un dueño único por dirección conserva la intención del
             invariante (un solo punto de conexión auditable por lado) y lo
             hace implementable.
Razón:       Contradicción detectada al implementar GAM-003 — el vertical
             slice la destapó; ningún contrato debe ser inimplementable.
Impacto:     §4.3, §4.6, §4.10 y §5.0 actualizados. lefthook.yml y
             p2-implementation.yml enmendados. AUDITOR_TECH.md actualizado.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      GAM-003
Commit:      —
Referencias: §4.3, §4.6, §4.10, §5.0
```

<!-- Entradas rechazadas por SCRATCHPAD_INTAKE. No eliminar hasta revisión del PO. -->
