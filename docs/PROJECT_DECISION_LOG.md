# PROJECT_DECISION_LOG — Mudanza Caótica

**Versión:** 1.0
**Referencia:** AI_CONTEXT_MASTER §5.4  
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
Modifica:    [§N.N del master que esta entrada CAMBIA — arista DL→§ del grafo
             de derivación (DL-049); vacío si no modifica el master. Distinto
             de Referencias: referenciar no es modificar.]
Libre:       [parámetros que esta decisión NO determina y quedan por resolver,
             con su resolutor (playtest | PO). "—" es respuesta legítima y
             significa "nada queda libre". OBLIGATORIO si Modifica no está
             vacío (DL-053, chequeo 4 de §2.6): el juicio determinado-vs-libre
             debe ser un acto explícito, no una omisión.]
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

---

### DL-030

```
ID:          DL-030
Fecha:       2026-07-11
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    sync-tickets.yml pusheaba directo a main. Al activar branch
             protection con status checks requeridos, ese push del bot
             fallaria cada 6 horas o exigiria una excepcion permanente
             que debilita la proteccion para todos.
Contenido:   El sync nunca pushea a main: escribe la rama bot/sync-tickets
             (force-push, solo contiene el delta de TICKETS.md), abre un PR
             etiquetado (class:b, domain:tech) y automerge-sync.yml lo
             mergea (squash) SOLO si el diff toca exclusivamente
             docs/TICKETS.md. Requiere SYNC_BOT_TOKEN (token de repositorio
             sin acceso a Projects — fine-grained Contents/PR write o PAT
             clasico con scope repo) porque los PRs creados por el
             GITHUB_TOKEN no disparan workflows; sin el secret, el propio
             sync arma el automerge como respaldo.
Hipótesis:   Canalizar la escritura del bot por PR hace la proteccion de
             main universal (sin excepciones), deja auditoria visible de
             cada sync y permite exigir los mismos checks a humanos y bots.
Razón:       Directriz del PO (2026-07-11) al configurar branch protection:
             es preferible que el bot pase por el mismo embudo que el resto
             del repo a mantener un bypass permanente.
Impacto:     sync-tickets.yml reescrito (rama + PR + respaldo de automerge),
             nuevo workflow automerge-sync.yml con guarda de diff,
             validate-pr-labels exime a bot/sync-tickets del warning de
             class:b sobre docs/, PROJECT_SETUP.md documenta SYNC_BOT_TOKEN
             y "Allow auto-merge". §6.6 actualizado.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Commit:      —
Referencias: §6.6, DL-019, DL-023
```

---

### DL-031

```
ID:          DL-031
Fecha:       2026-07-12
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Auditoria de la arquitectura de src/ (solicitada por el PO,
             2026-07-12). El contrato entre ObjectDefinition (identidad y
             datos) y el asset real en ServerStorage estaba sin formalizar:
             existia un hueco ObjectDefinition -> ??? -> ServerStorage. En
             el slice, ObjectManager construia el Part placeholder inline,
             lo que lo habria acoplado a ServerStorage/Studio en cuanto
             existieran modelos reales.
Contenido:   Nuevo modulo src/server/PrefabRegistry.lua — unica capa que
             conoce ServerStorage/ObjectPrefabs. Resuelve ObjectId -> prefab
             (Model o BasePart) por Attribute ObjectId, nunca por .Name
             (2.4). Si falta el prefab genera un placeholder (el arte puede
             llegar despues del codigo sin romper rondas). instantiate(def)
             retorna (top, root, isPlaceholder): top se parenta/destruye,
             root es el BasePart raiz para fisica y welds — asi CarryManager
             y TruckManager operan sobre un BasePart sin saber si el objeto
             es Part o Model. validate() audita el contrato al bootstrap
             (faltantes, huerfanos, duplicados, invalidos) — los errores
             aparecen al arrancar el servidor, no a mitad de partida. El
             nucleo de auditoria (_audit) es puro y se testea en Lune.
Hipótesis:   Aislar la resolucion ObjectId -> asset en una capa dedicada
             preserva el desacoplamiento datos/apariencia de 2.3 y permite
             anadir un ObjectDefinition o un prefab nuevo sin tocar la
             logica de ObjectManager — el acoplamiento que 4.6 prohibe.
Razón:       Un contrato implicito ("alguien resolvera ObjectId a modelo")
             se implementa de forma distinta en cada call site y termina
             acoplando la logica de gameplay a Studio. Formalizarlo ahora,
             con un solo consumidor (ObjectManager), es barato; hacerlo
             despues de que varios modulos claven ServerStorage no lo es.
Impacto:     ObjectManager delega spawn en PrefabRegistry y deja de leer
             PLACEHOLDER_OBJECT_* (movido a PrefabRegistry). TruckManager
             resuelve InstanceId por ancestria (Models multi-part).
             Main.server.lua llama validate() al bootstrap. Nuevo contrato
             Arte -> PrefabRegistry en 4.4. §4.1, §4.4, §4.5 actualizados.
             PrefabRegistry.spec: 6 tests del nucleo puro (31 specs totales).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      GAM-009 (pendiente de alta en el board)
Commit:      —
Referencias: §2.3, §4.1, §4.4, §4.5, §4.6, DL-028
```

---

### DL-032

```
ID:          DL-032
Fecha:       2026-07-12
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Auditoria de gobernanza (PO, 2026-07-12). Varias decisiones han
             estado gobernadas por un supuesto no documentado: que el coste
             relevante es el de un implementador HUMANO. Sintomas: (1)
             heuristicas como "modulo < 300 lineas" y "RemoteEvents <= 7"
             calibradas silenciosamente a limites humanos; (2) el limite <=7
             se ejecuta como gate duro Nivel 1 en CI pero §4.3 lo describe
             como blando (inconsistencia); (3) tickets que no nombran
             infraestructura AI-optima — MapBootstrap y el vertical slice
             aparecieron por principios, no por tickets, porque un roadmap
             con supuesto humano habria preferido "arte minimo" a "escribir
             un generador".
Contenido:   Se documenta explicitamente que el implementador es una IA y que
             toda heuristica/umbral de gobernanza se calibra a coste-IA +
             coste-humano-revisor + coste-runtime, nunca a
             coste-humano-implementador (nueva §5.9). Se distingue la
             restriccion del numero: la superficie cliente-servidor (razon
             del <=7) es runtime-real; el 7 es heuristica. Se deriva una
             Regla de derivacion de tickets (§5.5): todo ticket traza a una
             DECISION del DL o a un Principio/hito, con el conjunto completo
             de tickets de habilitacion derivado bajo coste-IA. Primera
             aplicacion: alta retroactiva de WLD-000 (MapBootstrap) y GAM-009
             (PrefabRegistry).
Hipótesis:   Hacer explicito el modelo de coste convierte un sesgo silencioso
             en una decision auditable, y corrige de raiz dos gaps a la vez:
             umbrales mal calibrados y tickets incompletos. Sin esto, cada
             heuristica humana importada seguiria degradando la calidad sin
             que nadie pueda senalar la causa.
Razón:       Un principio que gobierna decisiones sin estar escrito no puede
             auditarse ni contrarrestarse. El PO lo detecto operando; se
             formaliza para que futuras heuristicas se justifiquen contra el
             coste correcto, no contra el habito humano.
Impacto:     Nueva §5.9 y Regla de derivacion de tickets en §5.5. TICKETS.md
             gana el campo "Deriva de" y dos tickets retroactivos. NO relaja
             umbrales por defecto — establece el marco para reexaminarlos uno
             a uno (la reexaminacion de <300 y <=7, con sus efectos sobre CI,
             es una decision posterior).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      WLD-000, GAM-009
Commit:      —
Referencias: §1.3, §5.0, §5.5, §5.9, §4.3, DL-028, DL-031
```

---

### DL-033

```
ID:          DL-033
Fecha:       2026-07-12
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    DL-032 identifico dos umbrales gobernados por el supuesto de
             coste-humano-implementador y los marco para reexaminar: el
             limite de 300 lineas por modulo y el <=7 RemoteEvents (este
             ademas con una inconsistencia: gate duro N1 en CI pero descrito
             como blando en §4.3).
Contenido:   (1) Tamano de modulo: 300 -> 400 lineas. El limite existe por
             coste-REVISOR (un humano revisa el modulo), no coste-escritor;
             una IA lee el modulo entero sin importar su tamano. El guard
             real contra god-modules es la responsabilidad unica (juicio del
             Auditor, Nivel 3); el conteo es un backstop coarse. Ningun
             modulo actual supera 286 lineas — el cambio elimina la presion
             de fragmentacion artificial sin efecto inmediato.
             (2) RemoteEvents: se resuelve la inconsistencia. Es un gate
             duro N1 contra el cap actual (7), justificado por una
             restriccion de RUNTIME (superficie cliente-servidor: exploit +
             replicacion), no de esfuerzo humano. El numero 7 es la
             heuristica: elevar el cap es una decision Clase A que actualiza
             el gate. Se elimina el bypass ad-hoc "con aprobacion del PO" —
             la aprobacion ES la decision que cambia el cap.
Hipótesis:   Recalibrar bajo el coste correcto (DL-032) elimina un sesgo que
             degradaba la calidad (splits artificiales) sin abrir la puerta
             a god-modules (el guard de responsabilidad unica sigue activo)
             ni a superficie de red descontrolada (el cap sigue siendo gate
             duro, solo cambiable por decision registrada).
Razón:       Primera aplicacion concreta de DL-032. Un umbral sin
             justificacion de coste documentada es deuda de gobernanza;
             estos dos quedan justificados o resueltos, y el marco de §5.9
             aplica de oficio a los futuros.
Impacto:     Sincronizado en 5 ubicaciones: master §4.3 (regla de
             RemoteEvents), §5.0 (tablas N1/N2), §5.9 (tabla de veredictos);
             p2-implementation.yml (contract-module-size); lefthook +
             .github/scripts/contract-module-size.sh; ONBOARDING. El gate de
             RemoteEvents no cambia de valor (sigue 7); el de modulo pasa a
             400. Cero modulos afectados hoy.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      —
Commit:      —
Referencias: §4.3, §5.0, §5.9, DL-032
```

---

### DL-034

```
ID:          DL-034
Fecha:       2026-07-12
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    La auditoria del PO (y una instancia previa) senalo un eje de
             gobernanza no cubierto: el master gobierna lo estructural
             ("quien puede que") pero no lo no-funcional ("que complejidad,
             que escala, quien limpia"). Evaluado bajo los 9 principios de
             la propia auditoria: la mayoria de los 8 documentos propuestos
             ya existen implicitos (invariantes, grafo de dependencias,
             ownership) — enriquecer > crear. Pero complejidad, sobre de
             escala y ownership de destruccion son gaps genuinos (nadie
             puede responder hoy "a partir de que punto un cambio deja de
             ser lento y pasa a violar arquitectura").
Contenido:   Nueva §4.12 (Contratos No Funcionales), NO un archivo aparte —
             el master es la fuente unica, se enriquece (principio #1). Tres
             contratos: (A) invariantes de complejidad por operacion (O(1)
             lookups, O(n) enumeracion) + prohibicion de loops por-objeto
             por-frame; (B) sobre de escala de diseno (4-6 jugadores, ~15-30
             objetos) — superarlo es Clase A, no optimizacion; (C) ownership
             de destruccion/cleanup (cada modulo libera lo que crea), el
             paralelo de §4.8 para el ciclo de vida de recursos. Se rechazan
             explicitamente los budgets de tiempo de pared: a esta escala
             son teatro.
Hipótesis:   Formalizar el eje no-funcional como invariantes verificables
             por juicio (no umbrales temporales teatrales) cierra el gap real
             sin fragmentar la fuente de verdad ni inventar problemas de
             escala que el diseno no tiene.
Razón:       Una regresion de complejidad (O(1)->O(n)) o un supuesto de
             escala fuera del sobre son defectos de arquitectura que hoy
             ningun contrato detecta. Documentarlos los hace auditables por
             el Auditor TECH (Nivel 3) y por el PO (Nivel 4).
Impacto:     Nueva §4.12. No cambia codigo ni CI — son contratos de juicio
             (Nivel 3), no gates deterministas. El Auditor TECH los usa en
             P3; una propuesta que asuma escala fuera del sobre se audita
             como rediseno.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      —
Commit:      —
Referencias: §1.2, §4.6, §4.8, §4.11, §5.0, DL-032, DL-031
```

---

### DL-035

```
ID:          DL-035
Fecha:       2026-07-12
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Follow-up del PO tras DL-033: evaluar si un gate de fan-out
             (numero de dependencias salientes por modulo) aportaria como
             segundo backstop de cohesion, dado que el conteo de lineas es
             un proxy coarse. Se midio la estructura real de requires del
             codigo antes de decidir.
Contenido:   RECHAZADO como gate. Evidencia: los 6 modulos de mayor fan-out
             (RoundManager 5, ObjectManager 5, Main.server 5, TruckManager 4,
             GameManager 4, CarryManager 4) son precisamente los
             orquestadores, sistemas y el bootstrap; las hojas (Config,
             Definitions) tienen fan-out 0. Un gate de fan-out
             ANTI-CORRELACIONA con la arquitectura correcta: penalizaria a
             los orquestadores que §4.8 MANDA que coordinen. Una version con
             whitelist/tiers solo re-codificaria §4.5/§4.8 sin valor
             independiente.
             POSITIVO: el guard de acoplamiento correcto es la DIRECCION, no
             la cantidad. Se eleva a invariante explicito en §4.5: las
             dependencias apuntan hacia abajo por nivel, sin ciclos ni
             ascensos; la referencia inversa se rompe con inyeccion de
             dependencias (RoundManager inyecta recordStoryEvent en
             CarryManager.start(ctx)) — captura como principio la disciplina
             que ya existia como comentario en el codigo.
             CANDIDATO DIFERIDO: la promocion de este invariante a gate
             determinista (deteccion de ciclos / direccion sobre el grafo de
             requires) queda registrada como NEW CONTRACT CANDIDATE, diferida
             por coste: los idiomas de require dinamicos actuales
             (getSystems("X"), Systems[var]) hacen fragil un parser estatico
             fiable. Se implementa cuando el numero de modulos crezca y los
             idiomas se uniformen (coste-IA justificado, §5.9).
Hipótesis:   Medir la propiedad equivocada (cantidad) produce un gate que
             castiga el diseno correcto. La propiedad util (direccion) es un
             invariante real pero su gate fiable no es cost-justified hoy;
             nombrarlo explicitamente da al Auditor un contrato al que
             apuntar sin el coste de un parser fragil.
Razón:       Registrar el rechazo evita que se re-proponga el fan-out
             (conocimiento arquitectonico: por que NO). Elevar la direccion
             a invariante convierte una disciplina de codigo en contrato
             auditable a coste cero.
Impacto:     Nueva declaracion en §4.5 (invariante de direccion + fan-out no
             es metrica). Sin cambio de CI ni de codigo. El Auditor TECH
             verifica direccion en Nivel 3; el gate automatico es candidato
             diferido.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      —
Commit:      —
Referencias: §4.5, §4.8, §5.0, §5.9, DL-032, DL-033
```

---

### DL-036

```
ID:          DL-036
Fecha:       2026-07-13
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El mapa real (WLD-001) se empezo a construir en Studio pero esta
             incompleto. La arbitracion de MapBootstrap (DL-028) decidia
             "existe mapa real" por presencia del Tag TruckZone: como el mapa
             WIP ya tiene un TruckZone pero esta incompleto, MapBootstrap se
             retiraba -> sin placeholder -> juego roto. El PO propuso un flag
             en el mapa que el placeholder "apague" automaticamente.
Contenido:   Se reemplaza la deteccion por-tag y la propuesta de flag-que-
             apaga-flag por una fuente unica: GlobalConfig.MAP_MODE
             ("placeholder" | "real"). Un solo valor no puede contradecirse,
             asi que no hace falta mutar un flag en runtime (eso rompia el
             contrato de flags estaticos: el valor leido no coincidiria con la
             realidad). El mapa real vive bajo Workspace/RealMap. En modo
             "placeholder", MapBootstrap DESTRUYE la copia runtime de
             Workspace/RealMap y genera el edificio; en "real" lo usa tal cual.
             Destruir es seguro (el DataModel de Play/servidor es una copia; el
             .rbxlx guardado no se toca) y necesario porque
             CollectionService:GetTagged es agnostico al parent — parkear a
             ServerStorage no ocultaria los tags del mapa real, mezclandolos
             con los del placeholder.
Hipótesis:   Un enum de un solo valor elimina de raiz la posibilidad de estado
             inconsistente que el auto-apagado intentaba parchear; y destruir
             la copia runtime es la unica forma limpia de exclusion dado que
             los tags persisten al reparentar.
Razón:       La deteccion por TruckZone es fragil justo cuando mas se necesita
             (mapa real a medias). Mutar un flag estatico en runtime crea
             estado oculto e imposible de depurar. El control explicito por
             MAP_MODE es predecible y respeta el contrato de flags.
Impacto:     GlobalConfig: nuevo MAP_MODE, se elimina ENABLE_PLACEHOLDER_MAP.
             MapBootstrap reescrito (arbitracion por MAP_MODE + destruccion de
             RealMap). §4.4 (contrato Layout, tabla de modulos) y tickets
             WLD-000/WLD-001 actualizados. Introduce la convencion
             Workspace/RealMap para el mapa real. Supersede el mecanismo de
             DL-028 (la deteccion por TruckZone), no el resto de DL-028.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P3
Ticket:      WLD-000, WLD-001
Commit:      —
Referencias: §4.4, DL-028, DL-031
```

---

### DL-037

```
ID:          DL-037
Fecha:       2026-07-15
Domain:      TECH
Tipo:        OBSERVATION
Estado:      DECISION
Contexto:    El PR #44 introdujo la capa src/shared/Rules/ (CarryRules,
             RoundRules, StatRules) — nucleo funcional puro consumido por los
             shells de servidor — con etiqueta class:b y sin entrada de DL ni
             actualizacion del master. La auditoria del PO (2026-07-15) detecto
             que §4.1 y §4.4 no mencionaban la capa: el master quedo
             desincronizado del codigo. Introducir una capa arquitectonica es
             Clase A (§6.4), no un refactor local.
Contenido:   Se formaliza retroactivamente el patron nucleo funcional / shell
             imperativo. La logica de decision de gameplay que puede ser pura
             vive en src/shared/Rules/ — sin efectos, sin game/workspace/script,
             determinista y testeable en Lune (§4.6). Los managers de servidor
             son el shell: consultan al nucleo que hacer y ejecutan los efectos.
             Invariante: la decision que puede ser pura, lo es (vive en Rules/
             con su .spec.lua). Documentado en nueva §4.13; corregido el arbol
             de §4.1 (capa Rules + convencion de Tests).
Hipótesis:   Documentar el patron cierra la brecha master-codigo y convierte la
             testabilidad en Lune (62 specs) en un contrato explicito, no en un
             accidente de implementacion.
Razón:       La mis-clasificacion de #44 es el ejemplo canonico del fallo de
             enforcement de trazabilidad: un cambio Clase A pasó como class:b sin
             rastro en DL ni master. Formalizar la capa restaura la coherencia;
             el gate que evita la recurrencia se decide aparte (protocolo de
             versionado).
Impacto:     Master: nueva §4.13; §4.1 (arbol) con Rules/ y convencion de Tests.
             Sin cambio de codigo — la capa ya existe. Motiva el gate de
             trazabilidad Clase A del protocolo de versionado.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Commit:      —
Referencias: §4.13, §4.1, §6.4, DL-032
```

---

### DL-038

```
ID:          DL-038
Fecha:       2026-07-15
Domain:      TECH
Tipo:        OBSERVATION
Estado:      DECISION
Contexto:    §6.3 y §5.5 describian la auditoria TECH como "Codex automatico
             post-merge" y "Codex ejecuta automaticamente en el cron". La
             auditoria del PO (2026-07-15) verifico los workflows: ninguno
             invoca una IA — solo crean Issues y comentarios (issues.create /
             createComment). No existe runner de Codex desatendido. La ejecucion
             real de toda IA (intake, construccion, auditoria) es manual: un
             humano dispara Claude.
Contenido:   Se documenta la verdad: lo automatizado es el DISPARO del artefacto
             (crear el Issue), no su PROCESAMIENTO. Se corrigen §6.3 (tabla P3,
             bloque de ejecutores) y §5.5 paso 7 para no afirmar automatizacion
             inexistente, y se añade la Nota de ejecucion en §6.3. El
             acoplamiento a un runner de IA desatendido queda registrado como
             DISEÑADO pero NO IMPLEMENTADO (requiere IA de pago); hasta que
             exista, el pipeline opera de facto en P5 para lo que se llamaba
             "automatico via Codex".
Hipótesis:   Alinear lo declarado con lo real elimina una incoherencia prohibida
             (decir/hacer) y evita que los Issues codex-audit sin procesar se
             confundan con auditorias hechas.
Razón:       Una incoherencia entre lo que el sistema dice y lo que hace es deuda
             de gobernanza de la peor clase: invisible hasta que alguien confia
             en una auditoria que nunca ocurrio. El coste de la automatizacion
             real (IA de pago) es una decision del PO, no un supuesto silencioso.
Impacto:     Master §6.3 (tabla, ejecutores, nueva Nota de ejecucion) y §5.5
             paso 7. Sin cambio de codigo ni de workflows en esta entrada. La
             implementacion de un runner de IA desatendido, si el PO decide
             pagarla, sera su propia decision (futura DL).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Commit:      —
Referencias: §6.3, §5.5, §6.6
```

---

### DL-039

```
ID:          DL-039
Fecha:       2026-07-15
Domain:      BOTH
Tipo:        OBSERVATION
Estado:      DECISION
Contexto:    La auditoria del PO (2026-07-15) señalo que la infra, el roadmap y
             la derivacion de tickets estaban de facto acotados al MVP/slice,
             aunque los principios (§2, §3.9) son de ciclo de vida. Sintoma: un
             conjunto de tickets incompleto — faltaban lobby, autoria/versionado
             de prefabs, input del cliente y config del place, todos
             habilitadores que un principio implica pero ningun feature nombra.
Contenido:   Se reencuadra explicitamente: la infraestructura, la arquitectura y
             la gobernanza apuntan al CICLO DE VIDA COMPLETO; el MVP y el
             vertical slice son el PRIMER hito, no el horizonte de diseño (§1.3,
             §5.7). La regla de Completitud (§5.5) se aplica a escala
             ciclo-de-vida: derivar un hito incluye sus tickets de habilitacion.
             Se derivan los faltantes: GAM-010, WLD-008, FND-003, FND-004, GM-004.
Hipótesis:   Fijar el horizonte en el ciclo de vida (no el slice) corrige el
             sesgo que producia tickets incompletos y evita retrofit — la infra
             del slice ya se diseña para soportar la evolucion.
Razón:       "MVP" como horizonte mediocriza el sistema: la infra NO es para una
             etapa, es para todo el juego. El slice es como se entrega la primera
             version publica, no el limite de lo que la arquitectura contempla.
Impacto:     Master §1.3 (alcance de infra), §5.7 (roadmap = primer hito), §6.4
             (correccion de la nota de sync-tickets). Cinco tickets nuevos de
             habilitacion en TICKETS.md. Sin cambio de codigo en esta entrada.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      GAM-010, WLD-008, FND-003, FND-004, GM-004
Commit:      —
Referencias: §1.3, §5.5, §5.7, §3.9, DL-024, DL-032
```

---

### DL-040

```
ID:          DL-040
Fecha:       2026-07-15
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    §4.1 declara ServerStorage/ObjectPrefabs "fuera de Rojo":
             PrefabRegistry (DL-031) resuelve ObjectId→prefab desde ahi, pero
             ningun ticket ni proceso creaba/versionaba esa carpeta. Los prefabs
             vivian solo en el .rbxlx de Studio — no versionables, no
             reproducibles desde el repo; el juego corria 100% con placeholders.
             La auditoria del PO lo marco como hueco de infra.
Contenido:   Los prefabs de objeto se versionan como un archivo de modelo
             (assets/ObjectPrefabs.rbxmx) mapeado por Rojo (default.project.json)
             a ServerStorage/ObjectPrefabs. Deja de estar "fuera de Rojo": el
             asset es versionable, reproducible con rojo build/serve y auditable
             por PrefabRegistry.validate() al bootstrap. La autoria de los
             modelos (WLD-008) y el mapeo/proceso (FND-003) son sus tickets.
Hipótesis:   Un modelo versionado mapeado por Rojo elimina el estado manual no
             reproducible sin acoplar el codigo a Studio — mismo principio que
             MapBootstrap (§5.9): el artefacto AI-optimo es versionable, no un
             paso manual de Studio.
Razón:       Un asset "fuera de Rojo" es un punto ciego de versionado: se pierde,
             diverge entre maquinas y rompe la reproducibilidad que el resto de
             la infra garantiza. Traerlo a Rojo cierra el hueco de raiz.
Impacto:     §4.1 (deja de declarar ObjectPrefabs "fuera de Rojo"; nuevo mapeo en
             default.project.json). Tickets FND-003 (mapeo/versionado) y WLD-008
             (autoria de modelos). PrefabRegistry no cambia — sigue resolviendo
             desde ServerStorage/ObjectPrefabs.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      FND-003, WLD-008
Commit:      —
Referencias: §4.1, §4.4, §5.9, DL-031
```

---

### DL-041

```
ID:          DL-041
Fecha:       2026-07-15
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El flujo de gobernanza (§5.5) definia que/por que se cambia, pero
             nada gobernaba COMO se versiona en Git. La ausencia produjo desorden
             real y repetido: PRs apilados y divergentes, rebases manuales
             frágiles, un deadlock de ruleset por renombre de check, y el caso
             #44 (capa arquitectonica mergeada como class:b sin DL ni master —
             DL-037). El PO pidio un protocolo con enforcement.
Contenido:   Nueva §5.10 Protocolo de Versionado, obligatoria: (1) una unidad =
             una rama desde main = un PR, sin apilar; (2) rebase (no merge) antes
             de integrar, squash, borrar rama; (3) master↔codigo en el mismo PR —
             un PR class:a referencia su DL y toca docs/; (4) nombres de checks
             estables (DL-033); (5) el PO sincroniza el ruleset al añadir checks.
             Enforcement automatico: nuevo gate "Contract: class:a traceability
             (DL-041)" en p2-implementation.yml — si el PR es class:a y no
             referencia un DL o no toca docs/, falla. Se registra un gate futuro
             (detectar capa nueva bajo src/ con label class:b) como candidato
             diferido.
Hipótesis:   Un protocolo explicito + un gate que ata class:a a su DL y a docs/
             convierte la disciplina (que fallo) en enforcement (que no depende
             de memoria), cerrando la clase de fallo de #44 sin frenar el trabajo.
Razón:       El desorden de versionado no es cosmetico: produjo trabajo
             desperdiciado, un master desincronizado del codigo y un deadlock de
             merge. Codificar el protocolo y hacer cumplir la trazabilidad Clase A
             es la unica forma de que no se repita.
Impacto:     Master: nueva §5.10. CI: nuevo required check "Contract: class:a
             traceability (DL-041)" en p2-implementation.yml — el PO debe añadirlo
             al ruleset de main (Regla 5). Sin cambio de codigo de gameplay. El
             gate se auto-valida en su propio PR (class:a, con DL y docs).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      —
Commit:      —
Referencias: §5.5, §5.0, §6.4, DL-033, DL-037
```

---

### DL-042

```
ID:          DL-042
Fecha:       2026-07-15
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    La auditoria del PO (2026-07-15) señalo que el framework de UI nunca
             se documento ni decidio: UI-001/002/003 se escribieron imperativas
             (Instance.new + updates manuales + Janitor). Un framework declarativo
             AI-optimo reescribe esos tickets, asi que la decision los delimita.
             El PO eligio Fusion.
Contenido:   Se adopta Fusion (elttob/fusion) como framework de UI. La UI se
             expresa como funcion del estado: los modulos derivan su arbol de
             Value/Computed de Fusion que reflejan ClientStateManager (§4.10); un
             unico subscribe actualiza los Value y Fusion re-renderiza. Nueva
             §4.14 fija el contrato. La UI no conecta RemoteEvents (INV-001). El
             alta de la dependencia Wally y la migracion de HUDManager/
             SummaryManager son UI-004; toda UI nueva nace en Fusion.
Hipótesis:   UI = f(estado) mapea 1:1 sobre ClientStateManager y elimina el glue
             imperativo (labels mutados a mano, DL-025). Una IA produce y modifica
             UI declarativa con menos error — coste-IA menor (§5.9).
Razón:       El framework de UI estaba sin decidir y sin documentar (hueco de la
             auditoria). Imperativo es verboso y propenso a error para generar y
             mantener con IA. Fusion es declarativo, ligero e idiomatico de
             Roblox; se prefiere sobre React-lua (mas peso/ceremonia) para la
             escala de §1.2 (4-6 jugadores, HUD simple).
Impacto:     Master: nueva §4.14 (contrato de UI). wally.toml gana elttob/fusion
             (en UI-004). Tickets: UI-004 (alta dep + migracion + patron), notas
             en UI-001/002/003. Sin cambio de codigo en esta entrada —
             HUDManager/SummaryManager siguen imperativos hasta UI-004.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P2/P4
Ticket:      UI-004
Commit:      —
Referencias: §4.14, §4.10, §5.9, DL-025
```

---

### DL-043

```
ID:          DL-043
Fecha:       2026-07-16
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    QA-001 (playtest del slice) expuso un hueco estructural del
             pipeline: 62 specs y todos los contratos de CI en verde, pero el
             slice NO era jugable. Tres bugs de integracion —payload de
             RemoteEvent mal parseado, carrera de orden entre RemoteEvents, y un
             objeto cargado que no toca una trigger zone a ras de suelo— que
             ninguna verificacion estatica atrapa (los specs prueban nucleos
             puros aislados, §4.13). El slice #31 se habia mergeado sin ningun
             playtest. Ahora existe el MCP de Roblox Studio: verificacion de
             runtime accionable.
Contenido:   Nueva §6.7 Verificacion de Runtime: el pipeline gana una tier de
             runtime (P6) accionable via el MCP de Studio (arrancar Play,
             conducir input, inspeccionar estado, leer consola — Claude o
             humano). Gate de Definition of Done: un ticket que toca
             comportamiento de runtime (cableado cliente↔servidor, payloads,
             fisica/trigger zones, orden de eventos, bootstrap) NO esta DONE sin
             pasar el smoke test. P6 pasa de "Humano" a MCP y es la PRIMERA
             automatizacion de IA REAL del pipeline (vs. el Codex aspiracional
             de DL-038). Las tres lecciones se codifican como invariantes: §4.3
             (contrato de payload + parsing defensivo), §4.10 (ownership de
             estado por evento — no limpiar datos en eventos de control), §4.4
             (trigger zones son volumenes). Procedimiento en
             docs/RUNTIME_VERIFICATION.md.
Hipótesis:   Una tier de runtime cierra el hueco que dejo pasar los bugs de
             QA-001; las lecciones como invariantes evitan que se repitan, y si
             se repiten, el smoke test las caza antes del merge.
Razón:       La verificacion estatica es necesaria pero no suficiente: no ve la
             integracion. Sin verificacion de runtime, "todo verde" no significa
             "funciona" — y el PO paga el costo probando a mano. El MCP lo hace
             accionable por primera vez.
Impacto:     Master: nueva §6.7, P6 en §6.3, invariantes en §4.3/§4.10/§4.4,
             gate de DoD. Nuevo docs/RUNTIME_VERIFICATION.md (procedimiento +
             smoke test en Luau). Sin cambio de codigo (los bugs se corrigieron
             en #76). El smoke test corre via MCP, no en CI (CI no conduce
             Studio).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P6
Ticket:      —
Commit:      —
Referencias: §6.7, §6.3, §4.3, §4.10, §4.4, §4.13, DL-038
```

---

### DL-044

```
ID:          DL-044
Fecha:       2026-07-17
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Un stress-test conceptual (sesión 2026-07-17) destiló el
             núcleo de diseño a 4 axiomas irreducibles y detectó que §2.1
             mezclaba altitudes: axiomas, corolarios deducibles, composites
             (axioma + elección de diseño) y principios de método/
             arquitectura convivían en una lista plana. Dos Principios
             Congelados —"Objetivo Estable" y "Dependencia Social"—
             resultaron ser composites, no rango axioma.
Contenido:   §2.1 se re-estratifica por altitud en tres niveles SIN eliminar
             ni renombrar ningún principio existente (preserva el grafo de
             referencias de TICKETS/prompts/auditores). Nivel 0 Axiomas:
             Interacción Humana como Contenido (C1a) + tres nuevos —
             Interdependencia como Valor (C1b), Ambigüedad Interpretable
             (C2'), Restricción Intrínseca (C3). Nivel 1 Corolarios de
             diseño, con derivación explícita y marca de composite. Nivel 2
             Método y arquitectura. La "legibilidad" que carga Objetivo
             Estable se anota como derivable (no requiere 5º axioma).
Hipótesis:   Estratificar por altitud hace auditable la diferencia entre un
             conflicto con un axioma (irreducible) y uno con una elección de
             diseño (revisable), sin debilitar la obligatoriedad de ningún
             principio.
Razón:       CONTINGENCY P5 — el PO otorgó control y autoridad directa sobre
             la constitución en sesión (2026-07-17) para re-estratificar §2.1
             antes de formalizar el núcleo destilado.
Impacto:     §2.1 reescrita (estructura, sin pérdida de contenido). Header a
             v5.23. Pendiente de propagación (paso siguiente): §2.2 Test
             Oficial, señales de rechazo de SCRATCHPAD_INTAKE, checklist de
             AUDITOR_DESIGN y el vocabulario "Deriva de Principio §2.1" en
             TICKETS. Nota: SCRATCHPAD_INTAKE.md aún cita "v5.7" (stale).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Commit:      —
Modifica:    §2.1
Libre:       Si la legibilidad ("los jugadores siempre saben qué hacer") es
             derivable o merece rango de 5º axioma → PO (anotado en §2.1)
Referencias: §2.2, §3.7, DL-024, DL-039
```

---

### DL-045

```
ID:          DL-045
Fecha:       2026-07-17
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    La sesión que re-estratificó §2.1 (DL-044) también forjó una
             metodología de modelado —altitud/carrier-vs-esencia, primacía
             derivada, determinismo del modelado, y un enforcement de
             derivaciones auto-certificantes— que vivía solo en notas de
             sesión. El PO pidió documentarla en el framework, y observó que
             pedirle "auditar el nivel" o "validar el gate" delega
             verificación de modelado que es competencia del agente, no rol
             del PO.
Contenido:   Nueva §2.6 Disciplina de Modelado en Fundamentos Transversales:
             altitud (axioma→corolario→instanciación→feel; representar en la
             relación carrier-agnóstica, no en la entidad); primacía derivada
             (matriz principio×entidad, no heredar encuadre); determinismo
             (duda de diseño = deuda de modelado, no se delega); roles (el PO
             ratifica axiomas / decide parámetros libres / da forma al método;
             no verifica corrección de modelado); y el enforcement de
             derivaciones auto-certificantes vía un gate de 5 chequeos.
             Criterio de validez: cumplir objetiva y efectivamente el
             enforcement.
Hipótesis:   Documentar la disciplina como fundamento transversal la hace
             auditable y aplicable por todos los agentes y dominios, y saca al
             PO del rol de detector de errores de modelado.
Razón:       CONTINGENCY P5 — autoridad directa del PO sobre la constitución
             (2026-07-17) + directriz de documentar los metamodelos en el
             framework.
Impacto:     §2.6 nueva. Header a v5.24. Pendiente de propagación: los _BASE
             de agentes y los AUDITOR_* deben referenciar §2.6. Refina el rol
             de auditoría del PO respecto a DL-044.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Commit:      —
Modifica:    §2.6
Libre:       —
Referencias: §2.1, §5.0, DL-044
```

---

### DL-046

```
ID:          DL-046
Fecha:       2026-07-17
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Con los axiomas en §2.1 (DL-044) y la disciplina de modelado en
             §2.6 (DL-045), el Core Loop derivado en sesión —esencia +
             perfiles de acoplamiento por carrier— vivía en la conversación,
             no en §3. Además §3.3 enmarcaba la cooperación como "forzada /
             no opcional", lenguaje de imposición que C3/C4 corrigen.
Contenido:   §3.1 gana una nota de Esencia (el reto es coordinación decisional
             bajo escasez, no transporte). §3.3 re-derivada desde los axiomas:
             la cooperación se genera por acoplamiento intrínseco del entorno
             (C1b); dos carriers con valencias distintas — espacio=contención
             (negativo, pervasivo, Compresión Social), objeto=pooling
             (positivo, puntuado, + porta la apuesta); el objetivo colectivo
             (§1.2) fija la valencia cooperativa; la cooperación obligatoria es
             legítima solo si es intrínseca (C3/C4) — representación correcta =
             resistencia física, prohibida = regla que impide iniciar el carry;
             la escasez vuelve la cooperación una decisión (C2′). Las magnitudes
             quedan como parámetros libres de playtest.
Hipótesis:   Anclar §3 en el modelo de acoplamiento hace la cooperación
             derivable y auditable con el gate §2.6, y elimina el marco de
             "imposición" que producía cerraduras.
Razón:       CONTINGENCY P5 — autoridad directa del PO sobre la constitución
             para formalizar el Core Loop derivado antes de reconciliar
             implementación.
Impacto:     §3.1 y §3.3 reescritas. Header v5.25. Ripple de implementación
             (Ola 4, post-gate): GAM-005 (penalización de velocidad en medium
             = fricción jugador↔sistema) y GAM-006 (AC "el carry no comienza
             sin soporte" = representación impuesta) quedan en tensión con §3.3
             re-derivada — reconciliar al abrir la implementación.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      GAM-005, GAM-006
Commit:      —
Modifica:    §3.1, §3.3
Libre:       Magnitudes de §3.3 — cuánto se mueve un large en solitario,
             cuánta eficiencia añade un segundo cargador, cuánta compresión
             impone el layout → playtest
Referencias: §2.1, §2.6, DL-027, DL-044, DL-045
```

---

### DL-047

```
ID:          DL-047
Fecha:       2026-07-17
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    §3.3 (DL-046) determina la cooperación por acoplamiento intrínseco
             (eficiencia = f(pooling), sin gate ni drop), pero §4 seguía con los
             contratos de carry del diseño viejo (soporte-como-gate, drop al
             perder soporte, penalización individual carrySpeed(mult)). Antes de
             tocar §4 se re-derivó el CONJUNTO de sistemas desde el §3 nuevo — no
             se parchó un sistema asumiendo que sobrevive.
Contenido:   Derivación del conjunto: ningún sistema nuevo (la contención del
             espacio es layout+física, no un sistema servidor); el schema
             ObjectInstance (§2.3, LeaderId+SupportId) sobrevive para demanda ≤ 2
             — SupportId=nil = "solo, pobre", con soporte = "normal" (cambia
             semántica, no forma); los sistemas de carry sobreviven con CONTRATOS
             nuevos. §4.4 gana el Contrato de carry cooperativo; §4.13 reemplaza
             carrySpeed(prev, mult) por carryEfficiency(demand, carriers) → factor
             (eficiencia por pooling). El límite modular CarrySupport-separado-vs-
             fundido lo determina el backstop de tamaño (DL-033) al implementar.
             Parámetro libre aislado (playtest): boost de un 2º cargador en objetos
             de demanda 1 (pooling en medium).
Hipótesis:   Modelar eficiencia = f(cargadores) hace la cooperación intrínseca
             (C3) y elimina la fricción jugador↔sistema, conservando la
             dependencia en objetos de demanda > 1.
Razón:       CONTINGENCY P5 — autoridad directa del PO; re-derivar §4 (conjunto,
             no parche) desde §3.3 antes de reestructurar tickets.
Impacto:     §4.4, §4.13 actualizadas. Header v5.26. §2.3 sin cambio (verificado).
             Ripple (siguiente ola, tras el gate): reestructurar tickets
             GAM-005/006/007 desde este §4; luego reconciliar código (CarryRules
             carrySpeed→carryEfficiency; CarrySupport gate/drop → vigilancia de
             eficiencia; GameplayConfig).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      GAM-005, GAM-006, GAM-007
Commit:      —
Modifica:    §4.4, §4.13
Libre:       Si un segundo cargador sobre un objeto de demanda 1 añade
             eficiencia extra (pooling en medium) → playtest
Referencias: §2.3, §3.3, DL-027, DL-033, DL-046
```

---

### DL-048

```
ID:          DL-048
Fecha:       2026-07-17
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El enforcement de modelado (§2.6) dependía del juicio del PO para
             cazar errores relacionales (tickets stale, derivación en tajada) —
             una deuda que no se pagaba. El PO propuso formalizar la parte
             relacional como un sistema de lógica (Datalog): el grafo de
             derivación es un DAG cuyas propiedades se binarizan → CI. Al
             correrlo, destapó 12 deudas de trazabilidad preexistentes
             invisibles a la revisión humana.
Contenido:   Nueva capa de verificación §5.0 Nivel 1: el grafo de derivación.
             Modelo Datalog en tools/derivation-graph/derivation.dl (nodos =
             §/DL/ticket; aristas = Deriva de / Referencias / Ticket). Runner en
             Lune (tools/derivation-graph/check.luau) extrae el grafo de docs/ y
             evalúa: dangling (integridad referencial), orphan (ticket sin fuente
             §5.5/DL-032), stale (un DL declara afectar a T pero T no lo
             referencia). Baseline (tools/derivation-graph/baseline.txt)
             grandfatherea la deuda conocida/diferida — el check falla solo en
             REGRESIONES (stale nuevo, fuera del baseline), respetando el nivel
             de abstracción del trabajo actual. Job CI contract-derivation-graph.
             Es el fragmento RELACIONAL de un enforcement mayor formalizado como
             lógica (el resto — altitud/tipos, refinamiento — es trabajo futuro).
Hipótesis:   Un check determinista sobre el grafo mueve la detección de errores
             relacionales del juicio del PO (y de mi diligencia) a la máquina —
             self-test binario al final de cada interacción de estos niveles. El
             baseline evita que la introducción bloquee por deuda preexistente y
             hace explícito cada diferimiento.
Razón:       CONTINGENCY P5 — dirección directa del PO; formaliza §2.6 como
             lógica relacional decidible (mismo principio §5.0/DL-012).
Impacto:     tools/derivation-graph/ (modelo + runner + baseline). Job CI nuevo.
             Hallazgos: (a) 17 stale en baseline (12 preexistentes + 5 de
             DL-046/047, diferidos) = backlog de trazabilidad a reconciliar;
             (b) la formalización expone dos relaciones sub-especificadas →
             campos explícitos futuros: `Modifica:` (DL→§, activa la regla
             `uncovered`) y `Difiere:` (diferimiento declarado). Hacer el check
             required necesita configurar branch protection (acción del PO).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Commit:      —
Modifica:    §5.0
Libre:       —
Referencias: §5.4, §2.6, DL-012, DL-041
```

---

### DL-049

```
ID:          DL-049
Fecha:       2026-07-18
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El validador (DL-048) cubría integridad + frescura pero no
             COBERTURA: un DL podía modificar §3/§4 sin declarar ningún
             ticket ni derivación — la "tajada silenciosa" quedaba invisible.
             Además la arista DL→§ (modificar ≠ referenciar) estaba
             sub-especificada dentro de Referencias. Investigación de sistemas
             formales (B/Event-B, TLA+, Z, VDM, Alloy, SysML+OCL) para
             completar el validador hacia holístico, por dirección del PO.
Contenido:   (1) Campo `Modifica:` en el schema del DL — la arista DL→§ como
             relación de primera clase (backfill DL-044..048; Referencias
             queda solo para referenciar). (2) Regla `uncovered`: DL que
             modifica §3/§4 sin declarar Ticket: y sin derivadores = violación
             (concepto B-Method: todo refinamiento genera obligaciones; un
             cambio de diseño sin obligaciones declaradas es sospechoso).
             (3) `dangling` extendido a modifies. (4) Roadmap del validador
             completo derivado de §2.6 e informado por la investigación:
             F4.5 `Difiere:` (diferimiento reificado, autorizado y ACOTADO por
             hito — convierte la deuda de liveness estilo TLA+ en check
             decidible; reemplaza baseline.txt) + prompt-freshness (prompts
             como nodos; caza refs stale tipo "v5.7"); F5 aristas tipadas
             (estereotipos SysML deriveReqt/satisfy/verify/refine) + altitud
             como tipo (Z schemas); F6 código como nodos + gluing invariants
             §3↔§4 (Event-B); F7 marcas de determinación.
Hipótesis:   Cobertura + frescura + integridad cierran el fragmento relacional
             SAFETY del validador; el diferimiento acotado (F4.5) añade la
             dimensión temporal sin salir de lo decidible.
Razón:       CONTINGENCY P5 — dirección del PO: "nuestra mayor inversión ahora
             es este validador; hay que completarlo", incluyendo meta-relaciones.
Impacto:     Schema del log gana Modifica: (obligatorio cuando la entrada
             cambia el master). derivation.dl + check.luau extendidos. El PO
             configuró el check como required (ruleset main-protection) — el
             validador es gate duro del pipeline. Meta-relaciones: reificadas
             parcialmente (affects/modifies/baseline); su forma completa llega
             con Difiere: y prompt-nodes (F4.5).
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    —
Referencias: §5.0, §5.4, §2.6, DL-048
```

---

### DL-050

```
ID:          DL-050
Fecha:       2026-07-18
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    F4.5 del validador: tres meta-relaciones vivían fuera del sistema
             formal. (a) El diferimiento — baseline.txt difería deuda sin
             autorización ni plazo. (b) Los version-pins — artefactos
             referenciando "AI_CONTEXT_MASTER vN.N" que rotan en cada bump:
             se hallaron 9 pins fósiles en 6 archivos, incluidos dos "v5.24"
             de una corrección de esta misma sesión ya vencidos contra v5.26 —
             prueba de que el pin rota más rápido de lo que se vigila. (c) El
             drift de §5.0 — DL-048/049 declararon su capa de verificación sin
             actualizar la tabla de contratos del master.
Contenido:   (1) deferrals.txt reemplaza baseline.txt: cada diferimiento es
             (ticket, dl, autorizado-por, hasta-fecha) — reificado, con
             procedencia y ACOTADO. Diferimiento vencido = violación que
             bloquea: la obligación de liveness ("eventualmente reconciliado",
             TLA+) se vuelve decidible. Las 17 deudas: 12 autorizadas por
             DL-048 (descubiertas), 5 por DL-046/047 (declaradas); bound
             inicial 2026-08-11 (deadline del slice) — ajustable por el PO.
             (2) Ban de version-pins: ningún artefacto contiene
             "AI_CONTEXT_MASTER vN.N" — el master se lee siempre vigente
             (única fuente de verdad, §header). Los 9 pins limpiados; el log
             histórico exento (solo se escanea su header). Se disuelve la
             meta-relación frágil en vez de vigilarla. (3) §5.0 Nivel 1 gana
             las filas del grafo de derivación y del ban — cierra el drift.
             (4) contract-derivation-graph entra a pre-commit (lefthook),
             cumpliendo la doble ejecución de Nivel 1 (DL-023). El nombre del
             required check NO cambia (regla de nombres §5.0/DL-033).
Hipótesis:   Con diferimiento acotado y pins disueltos, toda deuda relacional
             del grafo tiene dueño, autorización y vencimiento — la máquina
             reclama la reconciliación sin depender de memoria humana.
Razón:       CONTINGENCY P5 — dirección del PO: completar el validador hacia
             holístico, meta-relaciones incluidas.
Impacto:     tools/derivation-graph/: deferrals.txt (nuevo), baseline.txt
             (eliminado), check.luau y derivation.dl extendidos. Master §5.0 +
             header v5.27. lefthook.yml gana contract-derivation-graph. 6
             archivos de docs/ limpiados de pins. Al vencer 2026-08-11 sin
             reconciliar, el check bloquea TODO PR — el vencimiento es el
             mecanismo, no un accidente.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.0
Libre:       Fechas de los diferimientos en deferrals.txt (apretar/extender
             cada bound) → PO
Referencias: §5.4, §2.6, DL-023, DL-024, DL-033, DL-048, DL-049
```

---

### DL-051

```
ID:          DL-051
Fecha:       2026-07-18
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    F5 del validador: la meta-propiedad de NIVEL ("¿se está
             abstrayendo en el nivel correcto?") era la única clase de error
             que seguía dependiendo del juicio del PO — el fragmento
             relacional (F1–F4.5) caza aristas rotas pero no saltos de
             altitud. El PO condicionó retomar el diseño a cerrar esto.
Contenido:   La altitud como tipo, INFERIDA de la estructura existente (cero
             anotación nueva): nivel(§1/§2)=fundamento, nivel(§3)=diseño,
             nivel(§4)=técnica, nivel(ticket)=implementación; aristas tipadas
             por destino (taxonomía SysML: ticket→§4 «satisfy», ticket→§3
             «refine», ticket→§2 «motivate», ticket→DL «trace», DL→§
             «modify»). Tres reglas nuevas: level_skip (ticket cuyas fuentes
             son SOLO fundamento/hito — implementación no deriva directo de
             axiomas sin contrato §3/§4/DL en medio; QA-xxx exento por ser
             hitos transversales), domain_mismatch (DL que Modifica §3 debe
             ser DESIGN|BOTH, §4 debe ser TECH|BOTH), impl_leak (nombres de
             módulos de src/ en §1–§3 del master = implementación filtrada al
             piso de diseño; "Main" exento). Además: el extractor gana la
             arista DL-Ref (declarada por los tickets e ignorada hasta ahora —
             fidelidad del EDB, +11 aristas).
Hipótesis:   Con la altitud tipada, el error de nivel deja de necesitar el
             insight del PO: un salto de capa es una fila de salida, no una
             observación. El residuo genuinamente semántico (prosa de §3 con
             sabor de implementación más allá de nombres de módulos) queda en
             el checklist §2.6 del AUDITOR_DESIGN — más chico y más claro.
Razón:       CONTINGENCY P5 — condición del PO: F5 antes de retomar la
             abstracción, porque F5 es lo que evita que la validación de nivel
             caiga sobre él.
Impacto:     Primer run cazó un true positive: WLD-000 declaraba derivar solo
             de Principio+Hito cuando sus fuentes reales (DL-028, DL-036,
             §4.4) estaban en su propio cuerpo — corregido su Deriva de, y la
             fila muerta (WLD-000, DL-036) eliminada de deferrals.txt (17→16).
             §5.0 actualizada con las reglas de altitud. Header v5.28.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.0
Libre:       —
Referencias: §5.4, §2.6, DL-032, DL-048, DL-049, DL-050
```

---

### DL-052

```
ID:          DL-052
Fecha:       2026-07-18
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO estableció el principio de exhaustividad intra-sistema: el
             límite del validador es SOBRE el sistema (definirlo/evolucionarlo
             — asiento del PO), no DENTRO de él. Dos consecuencias: (a) el
             "residuo semántico → auditor" no es estado estable sino deuda de
             formalización (F6/F7 pasan de opcionales a obligatorios); (b) la
             postura "el guardián del debilitamiento de reglas es el PO" era
             incorrecta — la frontera meta no se puede DECIDIR mecánicamente,
             pero sí VIGILAR mecánicamente.
Contenido:   Tripwire de meta-frontera: el job contract-enforcement-change
             falla si un PR toca rutas de enforcement (tools/derivation-graph/,
             .github/workflows/, lefthook.yml) sin la etiqueta
             enforcement-change. Evolucionar el sistema formal deja de poder
             ser un cambio silencioso: es un acto etiquetado, visible y
             auditable en el PR. Límite operativo honesto: con una sola cuenta
             GitHub el debilitamiento no se vuelve imposible (quien etiqueta es
             la misma cuenta) — se vuelve deliberado y trazable. Un guard duro
             requeriría segunda cuenta aprobadora (CODEOWNERS + required
             review): decisión del PO si la quiere. §5.0 gana la fila
             correspondiente.
Hipótesis:   Hacer explícita la evolución del sistema formal elimina la clase
             "regla debilitada sin que nadie lo note" — el análogo meta del
             version-pin: no se vigila el contenido del cambio (indecidible),
             se exige la declaración del acto (decidible).
Razón:       CONTINGENCY P5 — principio de exhaustividad intra-sistema del PO
             (2026-07-18): todo lo mecanizable dentro del sistema se mecaniza;
             la frontera meta se vigila aunque no se decida.
Impacto:     p2-implementation.yml gana contract-enforcement-change. Etiqueta
             enforcement-change creada. §5.0 actualizada; header v5.29. Para
             que bloquee: el PO añade el check al ruleset main-protection
             (mismo procedimiento que DL-048). Re-clasificación de roadmap:
             F6 (código como nodos + gluing §3↔§4) y F7 (marcas de
             determinación) son obligatorios — completitud del sistema, no
             opcionales. Este propio PR toca workflows → lleva la etiqueta:
             el tripwire nace aplicándose a sí mismo.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.0
Libre:       Guard duro de la meta-frontera (CODEOWNERS + segunda cuenta
             aprobadora, vs. el tripwire actual) → PO
Referencias: §5.0, §2.6, DL-048, DL-050, DL-051
```

---

### DL-053

```
ID:          DL-053
Fecha:       2026-07-18
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO detectó que F7 estaba posicionado como paso FINAL del
             programa de diseño ("no huele bien") — tres errores: (a) la
             clase de error de F7 (confundir determinado con libre) ocurre en
             CADA paso del trabajo, dejarlo al final deja los pasos previos
             sin esa validación y la carga cae sobre el PO; (b) independencia:
             un fragmento escrito DESPUÉS del trabajo que juzga puede ser
             moldeado para bendecirlo; (c) al reclasificar F7 de opcional a
             obligatorio se heredó su POSICIÓN de cuando era opcional — se
             cambió el atributo sin re-derivar el orden.
Contenido:   F7 — determinación como acto explícito. Campo `Libre:` en el
             schema del DL: qué parámetros la decisión NO determina y quién
             los resuelve (playtest | PO); "—" es respuesta legítima;
             OBLIGATORIO si Modifica no está vacío. Regla `undeclared_free`:
             DL que modifica el master sin declarar Libre: = violación. No
             valida la corrección del juicio (semántico) sino que el juicio
             se haya HECHO y quede auditable — mismo patrón que DL-052: lo
             indecidible es el contenido, lo decidible es la declaración del
             acto. Backfill en DL-044..052. Principio nuevo de método: un
             fragmento del validador debe existir ANTES del trabajo cuya
             clase de error gobierna — el validador nunca es un paso del
             programa que valida, es su PRECONDICIÓN. Orden corregido: F7 ✓,
             luego F6 (que construido antes no califica el §4 holístico a
             posteriori — GENERA sus obligaciones, modelo B/Event-B), recién
             entonces el trabajo de diseño.
Hipótesis:   Forzar el juicio determinado-vs-libre como declaración auditable
             en cada decisión elimina la clase "parámetro colado sin decisión"
             en el momento en que ocurre, no al final del proceso.
Razón:       CONTINGENCY P5 — corrección de orden del PO (2026-07-18): el
             validador se completa antes del proceso, no al final.
Impacto:     Schema del log gana Libre: (obligatorio con Modifica). Regla
             undeclared_free en derivation.dl + check.luau. Backfill 8 DLs
             (los Libre: retroactivos registran parámetros ya conocidos:
             legibilidad→PO, magnitudes §3.3→playtest, pooling medium→
             playtest, bounds de deferrals→PO, guard duro→PO). §5.0
             actualizada; header v5.30. Restante del validador: solo F6.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.0
Libre:       —
Referencias: §5.4, §5.0, §2.6, DL-049, DL-052
```

---

### DL-054

```
ID:          DL-054
Fecha:       2026-07-18
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    F6 — último fragmento del validador, construido ANTES del
             trabajo holístico que gobierna (principio DL-053): el grafo no
             alcanzaba el código (src/) ni existía correspondencia explícita
             diseño→realización. Al construir el registro emergió drift real:
             ProfileStoreConfig existe en src/server/Persistence/ pero §4.7
             declara "únicos módulos propios: PlayerDataService y
             MigrationService" — prosa desactualizada.
Contenido:   (1) Código como nodos: registro de módulos declarados (tabla
             §4.4 + tabla §4.13 + registro adicional en §4.15) contra src/
             real — regla module_undeclared ("implementado sin diseñar").
             Exenciones: Tests/ (verifican), Definitions/ (contenido — §2.4
             prohíbe acoplar el master a nombres de objetos), Main/init.
             (2) Nueva §4.15: tabla de GLUING §3↔§4 (Event-B) — toda sección
             §3.N declara su realización (mecanismos con claims de módulo en
             backticks, o marcador legítimo: empírico→playtest / normativo);
             filas finas por concepto para §3.3 (contención, pooling,
             escasez, apuesta). Reglas unglued_section (totalidad) y
             glue_dangling (existencia). Construido antes del holístico, el
             gluing GENERA obligaciones: re-derivar §3/§4 sin re-pegar
             dispara las reglas. (3) uncovered refinado: §4.15 exento (es
             registro, gobernado por sus propias reglas). (4) lefthook glob
             gana src/. La meta-2 (código del validador mismo) queda
             gobernada por el tripwire DL-052, no por el grafo.
Hipótesis:   Con código y gluing en el grafo, "diseñado sin implementar",
             "implementado sin diseñar" y "concepto sin realización" son
             filas de salida — el holístico §4 trabaja descargando
             obligaciones visibles, no confiando en memoria.
Razón:       CONTINGENCY P5 — arranque de F6 ordenado por el PO bajo el
             principio validador-antes-del-trabajo (DL-053).
Impacto:     §4.15 nueva; §5.0 actualizada; header v5.31. 13 reglas activas.
             Drift ProfileStoreConfig↔§4.7 anotado ⚠ en §4.15 — obligación
             del holístico. Validador COMPLETO respecto a su roadmap
             (F1–F7): el programa de diseño queda desbloqueado con
             precondiciones en pie.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §4.15, §5.0
Libre:       Granularidad del gluing por debajo de sección (claims tipados
             por afirmación individual de §3) → se decide al verla operar en
             el holístico (PO)
Referencias: §4.4, §4.13, §4.7, §2.4, §2.6, §5.0, DL-047, DL-052, DL-053
```

---

### DL-055

```
ID:          DL-055
Fecha:       2026-07-18
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Completado el validador (F1–F7, 13 reglas), el PO planteó la
             pregunta que lo cierra: si la coherencia ya es mecánica, ¿qué
             audita él? §5.0 Nivel 4 declaraba el nivel del PO pero no su
             superficie exacta — quedaba implícito y por tanto disputable,
             justo la clase de ambigüedad que este sistema elimina.
Contenido:   §5.0 Nivel 4 gana la especificación de la superficie del PO —
             exactamente DOS actos, tras tres correcciones del propio PO a la
             propuesta inicial (que le asignaba además el entailment como
             interinato): (1) VALIDAR LOS AXIOMAS — la constitución: §2.1
             Nivel 0, entidades §2.3 y el catálogo de reglas de inferencia
             (F8); validar la fundación ES validar la adecuación, no hay
             acto separado. (2) ELEGIR — parámetros de intención (Libre→PO)
             y meta-elecciones sobre el sistema (evolución del enforcement,
             tripwire DL-052); los empíricos (Libre→playtest) se miden, no
             se eligen. NO es del PO: la coherencia (13 reglas) NI el
             entailment — su terreno son relaciones dentro del sistema
             definido: binariza. La barrera nunca fue el chequeo (decidible)
             sino la CONVERSIÓN SEMÁNTICA prosa→forma; por determinación del
             PO ("decisión objetiva" — se deduce de la exhaustividad
             intra-sistema + DL-053 fija el cuándo) esa conversión SE
             ELIMINA, no se asigna (3ª corrección: el determinismo no cae en
             agentes — un ápice de dependencia lo daña; y una f(x)
             determinista prosa→forma no existe: pretenderla sería
             dependencia de agente disfrazada). F8 = la capa normativa se
             AUTORA directamente en forma: claims tipados (id, nivel,
             premisas, regla citada) + catálogo de reglas de inferencia
             SINTÁCTICAS (aplicabilidad decidible de la estructura;
             constitucional → validación del PO; el paso no-sintáctico se
             descompone hasta serlo). La prosa es comentario NO normativo —
             nada deriva de prosa; única dirección permitida: forma→prosa.
             Los axiomas se siembran como claims: la ratificación del PO
             recae sobre la forma. Dejar la forma sin adoptar sería una
             ineficiencia que es en sí una vulnerabilidad.
             Interinato mientras F8 se construye: agente que modela
             (auto-certificación §2.6) + AUDITOR_DESIGN (pasada adversarial)
             — nunca el PO. Se registra la CONCENTRACIÓN DEL RIESGO: una
             derivación impecable desde un axioma errado (o un catálogo mal
             ratificado) pasa todo en verde — el modo de fallo peligroso es
             lo correcto en forma y errado en fundamento.
Hipótesis:   Con la superficie reducida a fundación + elecciones, el PO deja
             de ser load-bearing en cualquier verificación; los dos fallos
             simétricos (auditar lo mecanizado / confiar al verde lo que la
             forma no carga) quedan estructuralmente cerrados.
Razón:       CONTINGENCY P5 — pregunta directa del PO tras aterrizar F6
             ("especifica qué audito, porque no será la coherencia") + sus
             tres correcciones (entailment no es suyo; la conversión
             semántica no queda en prosa; el determinismo no cae en agentes
             — la conversión se elimina por autoría directa en forma).
Impacto:     §5.0 Nivel 4 especificado; header v5.32. AUDITOR_DESIGN gana el
             checklist de entailment (interinato hasta F8). RATIFICACIÓN
             REGISTRADA (2026-07-19): el PO afirmó "los axiomas definidos
             son correctos — lo único" → acto 1 de su superficie ejecutado;
             único input humano afirmado del sistema; todo lo demás debe
             probarse por el sistema. Resuelve además el Libre de DL-054
             (granularidad del gluing → claims tipados por afirmación, F8).
             Consecuencia operativa: verificar §3 ≡ convertir §3 a claims —
             el primer paso del programa holístico ES F8 operando.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.0
Libre:       —
Referencias: §5.0, §2.1, §2.3, §2.6, §4.15, DL-052, DL-053, DL-054
```

---

### DL-056

```
ID:          DL-056
Fecha:       2026-07-19
Domain:      TECH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Movimiento prudencial ordenado por el PO antes de apoyar el
             programa holístico en el validador: testearlo contra el propio
             proyecto. 13 luces en verde no distinguen un validador correcto
             de uno roto — varias reglas nacieron en verde y nunca habían
             encendido. Contexto de fondo: el PO ratificó los axiomas como
             único input humano afirmado (DL-055) — todo lo demás debe
             probarse por el sistema, incluido el validador mismo.
Contenido:   Mutation tests del validador (test.luau): por cada una de las
             13 reglas se inyecta una violación mínima de su clase sobre una
             COPIA del corpus real (docs/ + src/ + deferrals) y se exige que
             la regla encienda (exit≠0 + fila de su clase); más un control
             (el corpus sin mutar pasa). 14 casos, sandbox efímero
             (.dgtest-sandbox/, gitignored), anclas literales que fallan si
             el corpus cambia y la mutación deja de probar. Job CI
             contract-validator-mutations. Con esto el validador queda
             gobernado por CONDUCTA (tests) además de por DECLARACIÓN
             (tripwire DL-052): debilitar una regla rompe su mutation test.
Hipótesis:   Un validador cuyas reglas demostraron encender ante su clase de
             violación es precondición confiable del programa; uno que solo
             ha pasado en verde, no.
Razón:       CONTINGENCY P5 — "el siguiente movimiento prudencial es testear
             el validador contra el mismo proyecto" (PO, 2026-07-19).
Impacto:     tools/derivation-graph/test.luau nuevo. p2-implementation.yml
             gana contract-validator-mutations (para que bloquee: añadirlo
             al ruleset — acción del PO). §5.0 actualizada; header v5.33.
             .gitignore gana el sandbox. Resultado inaugural: 14/14 — todas
             las reglas encienden.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.0
Libre:       —
Referencias: §5.0, §2.6, DL-048, DL-052, DL-055
```

---

### DL-057

```
ID:          DL-057
Fecha:       2026-07-19
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    F8 bajo la arquitectura fijada por las correcciones del PO en
             DL-055: la conversión semántica prosa→forma SE ELIMINA — la
             capa normativa se autora directamente en forma, el determinismo
             no cae en agentes. Además el merge de #110 no incluyó el último
             commit de DL-055 (verificado: main sin la corrección); se
             re-aplica aquí como primer commit.
Contenido:   (1) §2.7 nueva — Catálogo de Reglas de Inferencia: R-POST
             (postulado, 0 premisas), R-ESP (especialización, exactamente 1,
             sin elecciones), R-COMP (composición, ≥2, sin elecciones),
             R-ELEC (composición con elección, ≥2 con ≥1 E-n → marca ⚠).
             Condiciones SINTÁCTICAS: aplicabilidad decidible de la
             estructura; el paso no-sintáctico se descompone. Tabla de
             Elecciones constitucionales citables: E1 (valencia cooperativa,
             §1.2), E2 (el ancla interpretable es el objetivo). (2) §2.1 en
             forma normativa: N0 gana estado formal (axiomas = R-POST,
             ratificados por el PO 2026-07-19); N1 reemplaza "Deriva de"
             (prosa) por "Derivación" formal (R-XXX · premisas — comentario);
             N2 gana columna Derivación (R-POST). Nada deriva de prosa.
             (3) Cinco reglas nuevas del validador: claim_bad_derivation
             (totalidad — toda entrada §2.1 porta forma), unknown_rule,
             unknown_premise, rule_arity, claim_cycle (DFS sobre premisas).
             18 reglas activas. (4) Cinco mutation tests nuevos — 19 casos,
             todos encienden. El entailment de §2.1 queda verificado por
             máquina: el interinato (agente+auditor) se retira para la capa
             constitucional.
Hipótesis:   Con §2.1 en claims verificados, "verificar §3" del programa
             holístico es autorar §3 en esta misma forma — el entailment de
             diseño deja de depender de agentes capa por capa, empezando por
             la constitución.
Razón:       CONTINGENCY P5 — "procede F8" (PO, 2026-07-19), bajo sus tres
             correcciones de DL-055.
Impacto:     §2.1 (forma normativa), §2.7 (nueva), §5.0 (fila F8); header
             v5.34. El catálogo y las elecciones E1/E2 son constitución:
             este PR se somete a validación del PO (sin auto-merge). Las
             reglas §2.7 requieren soporte en validador para evolucionar
             (tripwire DL-052 + mutation DL-056).
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.1, §2.7, §5.0
Libre:       —
Referencias: §2.6, §5.0, §1.2, DL-044, DL-053, DL-055, DL-056
```

---

### DL-058

```
ID:          DL-058
Fecha:       2026-07-19
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Al ratificar F8, el PO detectó que E1 mezclaba dos argumentos
             distintos en una sola elección: la valencia cooperativa y la
             ausencia de condición de derrota — independientes (existen
             juegos cooperativos CON derrota declarable, y juegos sin
             derrota con valencia competitiva). Además precisó el alcance de
             "sin condición de derrota": NO significa que el jugador no
             experimente fracaso, sino que el juego no lo declara ni lo
             castiga ("Perdiste"). Y pidió validar con el propio validador
             que ese malentendido no tenga espacio.
Contenido:   (1) E1 se divide: E1 = valencia cooperativa (resultado de
             equipo, §1.2); E3 nueva = el juego no declara ni castiga la
             derrota (no existe estado «Perdiste», §1.2) — texto mínimo
             deliberado: la distinción declarada-vs-experimentada NO se
             especifica porque SE DERIVA (C2′ exige resultados abiertos bajo
             escasez → el fracaso parcial es posible y se experimenta; C1a
             lo vuelve contenido — las historias de §3.8). (2) PRUEBA REAL
             ejecutada con el validador: el malentendido ("el jugador nunca
             experimenta derrota") autorado en 5 formulaciones sobre copia
             del corpus — 4 bloqueadas por rule_arity, revelando la
             GARANTÍA ESTRUCTURAL del catálogo: ninguna conclusión deriva
             SOLO de elecciones; toda derivación exige un axioma portador, y
             ningún axioma ratificado porta "no hay fracaso" (C2′ exige lo
             contrario). La 5ª formulación (R-ELEC · C2′ + E3) pasa sintaxis
             = residuo de contenido: claim VISIBLE cuya premisa citada no
             sostiene semánticamente la conclusión — hoy lo caza el AUDITOR
             (checklist entailment §2.6); se cierra más cuando §3 se autore
             en claims (la claim derivada "el fracaso parcial existe y es
             contenido" queda como contradicción visible). (3) Mutation test
             permanente nuevo: elección-sin-axioma-portador → rule_arity.
             (4) FORMALIZACIÓN "las elecciones son valencias" (3ª observación
             del PO: identificar la doble argumentación no debía ser su
             trabajo): una elección = un EJE que los axiomas dejan abierto +
             el VALOR elegido — una de las valencias válidas del eje. Tabla
             §2.7 re-estructurada: | ID | Eje | Abierto por | Valor | Estado |
             (E1←C1b neutral de valencia; E2←C2′ exige ancla; E3←silencio
             axiomático, C3 informa). Tres reglas nuevas: election_malformed
             (celda vacía), election_axis_dup (dos elecciones en un eje),
             election_compound (eje no atómico o valor con conjunción — la
             firma textual del defecto de E1; lint de señal, no completitud).
             Sweep del conjunto ejecutado via la forma: tres ejes atómicos y
             distintos, cada uno con apertura trazable — sin otra mezcla.
             Mutación permanente que RECONSTRUYE el defecto histórico de E1
             → election_compound lo caza (23 casos). 21 reglas activas.
Hipótesis:   Con E1/E3 separadas y la garantía estructural testeada, el
             malentendido no puede volverse normativo por vía sintáctica; su
             única vía (axioma citado que no sostiene) es visible y auditable.
Razón:       CONTINGENCY P5 — corrección y prueba ordenadas por el PO al
             ratificar F8 (2026-07-19).
Impacto:     §2.7 elecciones re-estructurada como tabla de valencias (E1
             escindida, E3 nueva, ejes con apertura trazable); header v5.35.
             check.luau 21 reglas; test.luau 23 casos. Dependencia Social
             sigue citando R-ELEC · C1b + E1 (valencia — correcto tras el
             split). E3 queda citable para las claims de §3/§3.5
             (prohibición de castigo). La clase de defecto que el PO cazó a
             mano en E1 queda mecanizada — no vuelve a su superficie.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.7
Libre:       —
Referencias: §2.7, §1.2, §2.1, §3.8, DL-055, DL-057
```

---

### DL-059

```
ID:          DL-059
Fecha:       2026-07-19
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO detectó que tras construir el validador los errores del
             agente persistían — pero migrados de capa: F7 mal posicionado,
             roles mal asignados (entailment al PO, relación valor↔eje al
             PO), dependencia de agente disfrazada, E1 compuesta. Ninguno es
             error DE artefacto (el validador los cubre); todos son errores
             en el DISEÑO DEL SISTEMA mismo — la única capa sin ley
             explícita: sus principios existían como precedentes dispersos
             en prosa de DLs y memoria del agente. Sin ley explícita no hay
             violación citable — solo el catch del PO. Es el problema
             original un nivel arriba; el PO ordenó identificarlo
             holísticamente y resolverlo con un metaframework explícito.
Contenido:   Nueva §2.8 — Metaframework: Leyes de Evolución del Sistema.
             Diez leyes M1–M10 que gobiernan asignación de roles, orden de
             construcción y forma de las estructuras, cada una citando el
             catch (DL) que la reveló — el metaframework SE DERIVA de la
             historia de fallos. M10 es el motor: todo catch de meta-nivel
             se convierte en el mismo ciclo en ley explícita + regla del
             validador si su clase es formalizable (catch→ley→regla).
             Violación de una M-n en propuesta/DL/prompt = D1 citando la ley
             (AUDITOR gana el meta-checklist). La FORMA de la tabla es
             verificada (meta_law_malformed: ley vacía o fuente sin DL
             existente + mutación — 24 casos); su CONTENIDO es constitución
             (el PO ratifica leyes — contenido, no relación: M3 aplicada a
             sí misma). Corrección de la instancia disparadora: la relación
             valor↔eje de las elecciones se reasigna del PO al AUDITOR (M3).
Hipótesis:   Con la capa meta bajo ley explícita, los errores de diseño del
             sistema se vuelven citables y auditables en vez de depender del
             insight del PO; M10 garantiza que la tabla crece con cada catch
             en vez de agotarse en la instancia.
Razón:       CONTINGENCY P5 — identificación holística ordenada por el PO
             (2026-07-19): "es un metaproblema; debe resolverse creando un
             metaframework, haciéndolo explícito".
Impacto:     §2.8 nueva; §5.0 fila meta_law_malformed; header v5.36.
             AUDITOR_DESIGN gana meta-checklist M1–M10 y la relación
             valor↔eje. check.luau 22 reglas; test.luau 24 casos. La clase
             entera "error de diseño del sistema" deja de caer en la
             superficie del PO: su parte formal es máquina, su parte
             semántica es citable y del AUDITOR.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.8, §5.0
Libre:       —
Referencias: §2.6, §2.7, §5.0, DL-053, DL-055, DL-057, DL-058
```

---

### DL-060

```
ID:          DL-060
Fecha:       2026-07-19
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Dos precisiones del PO sobre el metaframework recién creado:
             (a) un sistema de leyes con fallback en el PO no es determinista
             — M10 como "motor catch→ley→regla" decía que el problema se
             mitigó, no se resolvió; y una tabla enumerada desde los fallos
             históricos del agente no es una abstracción sino un
             comportamiento específico — no cubre lo que aún no ocurrió.
             (b) un sistema que depende del AGENTE para "ser determinista"
             tampoco lo es — ningún fallback no binario, incluido el propio
             agente y el AUDITOR.
Contenido:   §2.8 re-derivada top-down: (1) MT0 — Ley de Asignación Total
             (R-POST): todo elemento tiene exactamente un titular
             determinado por su naturaleza; nada queda asignado
             implícitamente. (2) Procedimiento de tipado TOTAL (4 casos
             exhaustivos: contenido de intención→PO; relación expresable→
             máquina; formalizable pendiente→transitorio declarado;
             ninguna→empírico o disolver) + descomposición (M5) para lo que
             se resista — totalidad por construcción: cualquier meta-error
             futuro es una violación tipificable de MT0, no una ley nueva.
             (3) M1–M9 re-derivadas como TEOREMAS (R-ESP · [MT0]),
             verificadas por las reglas F8 — la tabla deja de ser lista.
             (4) M10 invertida: de motor a FALSACIÓN — un catch del PO
             refuta el framework (elemento mal tipado = bug); la métrica es
             que no se dispare fuera de zonas. (5) PERÍMETRO BINARIO: la
             garantía emana solo de máquina (reglas con mutación) y
             contenido ratificado (PO); agentes advisory — jamás titulares
             de garantía; prosa sin autoridad. (6) REGISTRO DE ZONAS NO
             VERIFICADAS (Z1 contenido semántico de claims; Z2 valor↔eje;
             Z3 realización del gluing) — las fugas conocidas no se asignan
             a nadie: se registran con camino y VENCIMIENTO; zona vencida =
             violación (la diferencia entre fallback implícito que carga
             peso y frontera explícita que expira). (7) M9 MECANIZADA:
             auto-cobertura — toda regla del validador debe tener su caso de
             mutación, verificado por test.luau contra el reporte real, no
             por disciplina.
Hipótesis:   Con garantía solo de máquina∪contenido, zonas explícitas
             acotadas y auto-cobertura, el sistema no contiene ningún
             fallback no binario: lo no garantizado es enumerable, visible y
             expira — nada descansa en el juicio de agente alguno.
Razón:       CONTINGENCY P5 — precisiones del PO (2026-07-19): "no debe
             tener ningún fallback no binario".
Impacto:     §2.8 reescrita (MT0 + procedimiento + teoremas + perímetro +
             zonas); header v5.37. check.luau 24 reglas (zone_malformed,
             zone_expired); test.luau 27 mutaciones + auto-cobertura M9.
             Los vencimientos de Z1–Z3 (2026-08-11) son parámetro del PO.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.8, §5.0
Libre:       Vencimientos de las zonas Z1–Z3 (re-acotar cada frontera) → PO
Referencias: §2.8, §2.6, §5.0, DL-050, DL-056, DL-059
```

---

### DL-061

```
ID:          DL-061
Fecha:       2026-07-19
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Primer paso del programa holístico bajo el aparato completo:
             §3 fundaba normativamente desde prosa — sus afirmaciones de
             diseño no eran verificables ni trazables a los axiomas, y su
             gluing (§4.15) conectaba PROSA con módulos (zona Z3). Con F8 y
             el metaframework en pie, la capa normativa de §3 se autora en
             forma (M4), sin conversión (DL-055).
Contenido:   Nueva §3.0 — Claims de Diseño: 21 claims (D1–D21) que portan
             toda la carga normativa de §3, cada uno citando el catálogo
             §2.7 sobre premisas que resuelven (axiomas, elecciones E1–E3,
             claims de §2.1 y de §3). Las subsecciones §3.1–§3.9 quedan
             como COMENTARIO NO NORMATIVO. Cobertura: §3.1→D1, §3.2→D2,
             §3.3→D3–D9 (acoplamiento, carriers, valencia, intrínseco,
             escasez), §3.4→D10, §3.5→D11–D15, §3.6→D16, §3.7→D17–D19,
             §3.8→D20 (marcador empírico legítimo), §3.9→D21. Regla nueva
             unclaimed_section: subsección de §3 sin claim ni marcador =
             violación (sin ella, una sección podría volver a fundar desde
             prosa de forma invisible). §3.0 exenta de gluing (es la tabla,
             no un concepto a realizar). HALLAZGO: §3.3 citaba "(C3, C4)" —
             C4 NO EXISTE (los axiomas son C1a/C1b/C2′/C3); era un residuo
             de la numeración conversacional CL1–CL5, tolerado porque la
             prosa no resuelve premisas. Corregido a (D4, D8).
Hipótesis:   Con §3 en claims verificados, el diseño deja de depender de
             lectura para su fundamento: una afirmación de diseño sin
             derivación válida no puede entrar, y el gluing pasa a conectar
             claims con módulos en vez de prosa con módulos (cierre de Z3).
Razón:       CONTINGENCY P5 — permiso de proceder indefinidamente otorgado
             por el PO tras ratificar el metaframework (2026-07-19).
Impacto:     §3.0 nueva (21 claims); §3.3 corregida (C4 fantasma); header
             v5.38. check.luau 25 reglas; test.luau 29 mutaciones.
             Z3 (realización del gluing) queda lista para cerrarse: el
             siguiente paso re-ancla §4.15 en claims D-n. §3.2 y §3.8
             confirmados como empíricos — se miden, no se derivan.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §3.3
Libre:       —
Referencias: §3.0, §2.7, §2.8, §4.15, DL-055, DL-057, DL-060
```

### DL-062

```
ID:          DL-062
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    DL-061 dejó §3 en claims pero el gluing (§4.15) seguía anclado
             en SECCIONES de prosa. Con §3.1–§3.9 ya no normativas, el
             dominio del gluing era prosa sin autoridad: la zona Z3.
Contenido:   §4.15 re-anclada — la columna izquierda es el CLAIM D-n, no la
             sección. 21 filas (D1–D21), cada claim declara su realización
             (mecanismo, o marcador legítimo empírico/normativo). Regla
             unglued_section → unglued_claim: totalidad sobre claims, no
             sobre secciones. Z3 CERRADA y retirada del registro; el
             registro contiene lo vigente, el cierre vive en el DL.
             HALLAZGOS del validador al nacer la sección:
             (1) glue_dangling D12 → `ObjectDefinition` — módulo de
                 Definitions/, exento del registro; era claim de módulo
                 falso. Corregido a prosa.
             (2) uncovered DL-061 — un DL que modifica §3 debía declarar
                 ticket. Al tiparlo (MT0): §3.1–§3.9 son comentario no
                 normativo, luego no pueden generar obligación de
                 implementación — exención DERIVADA. §3.0 sí es normativa,
                 pero el grafo no distingue REUBICAR normatividad de
                 CAMBIAR el compromiso porque los enunciados de claim no
                 están versionados: formalizable-pendiente → zona Z4
                 ACOTADA (vence 2026-08-11), no fallback.
             (3) El propio validador rechazó cerrar Z3 marcando la fila
                 como "cerrada" (zone_malformed): el registro es de zonas
                 NO verificadas, no un cementerio.
             AÑADIDO tras ratificación del PO (2026-07-22): la tabla de
             zonas gana columna Ratificada y zone_malformed la exige como
             `PO <fecha>`. Razón: la ratificación es fuente de garantía
             (perímetro binario, DL-060), luego debe vivir en la FORMA, no
             en la prosa de un DL — una frontera que el sistema se concede
             a sí mismo no es una frontera. Z1/Z2 ratificadas 2026-07-19
             (junto con el metaframework), Z4 el 2026-07-22.
Hipótesis:   Con el gluing anclado en claims, toda la cadena axioma →
             claim → realización → módulo es verificable sin leer prosa.
             La prosa queda estrictamente como comentario: puede borrarse
             sin perder una sola obligación.
Razón:       CONTINGENCY P5 — permiso de proceder indefinidamente otorgado
             por el PO tras ratificar el metaframework (2026-07-19).
Impacto:     §4.15 re-anclada (21 claims); §2.8 registro de zonas: Z3
             cerrada, Z4 abierta. check.luau: unglued_claim reemplaza
             unglued_section; uncovered exime §3 (derivado + Z4).
             derivation.dl: glue/glued/unglued_claim re-tipados sobre
             claim; design_claim y unclaimed_section declaradas.
             test.luau 29/29 + auto-cobertura M9.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §4.15, §2.8
Libre:       —
Referencias: §4.15, §3.0, §2.8, DL-054, DL-060, DL-061
```

### DL-063

```
ID:          DL-063
Fecha:       2026-07-22
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Z4: el grafo no distinguía REUBICAR normatividad de CAMBIAR el
             compromiso. Consecuencia práctica detectada por el PO: el
             programa de trabajo se re-priorizaba en cada turno sin que
             nada chillara, porque una remodelación era indistinguible de
             un refactor cosmético. Prioridad ordenada por el PO: el
             aparato antes que la implementación, por motivo objetivo —
             implementar contra un modelo no verificado produce trabajo
             que habrá que rehacer.
Contenido:   Sello del enunciado. Cada claim de §3.0 porta el hash FNV-1a
             (6 hex) de su propio enunciado normalizado. Regla
             claim_seal_mismatch: enunciado reescrito sin re-sellar =
             violación. Lo sellado es el ENUNCIADO, no la fila: mover un
             claim no altera su sello, reescribirlo sí. Modo `--seals`
             recalcula los sellos al remodelar legítimamente. Re-sellar es
             el ACTO que declara una remodelación; no valida que el
             contenido nuevo sea correcto (eso es Z1), valida que el cambio
             se hizo visible.
             Segundo caso de mutación NUEVO en clase: `reject` — la regla
             NO debe encender. El control de Z4 mueve un claim de sección y
             exige que el sello siga válido. Sin él, un sello sobre la fila
             entera pasaría los tests igual y Z4 quedaría cerrada en falso;
             una regla que enciende de más bloquea trabajo legítimo y
             entrena a ignorarla.
             HALLAZGO (causa raíz del shift de prioridades): DL-044 declaró
             en su campo Impacto: "pendiente de propagación (paso
             siguiente): §2.2, SCRATCHPAD_INTAKE, AUDITOR_DESIGN,
             vocabulario en TICKETS". Nunca se ejecutó — §2.2 no ha sido
             modificada por ningún DL desde 2026-07-17. Impacto: es PROSA:
             un paso siguiente declarado ahí no es obligación que el grafo
             persiga. `uncovered` exige ticket o derivadores, nada exige
             que una propagación declarada se descargue. Por eso el orden
             se pudo abandonar sin señal. Se corrige en el paso siguiente
             (campo `Propaga:`), NO aquí: un PR, un cambio.
Hipótesis:   Con el enunciado sellado, remodelar deja de ser silencioso: el
             diff muestra el sello cambiando y el acto queda declarado.
Razón:       CONTINGENCY P5 — "arranca por Z4" (PO, 2026-07-22), bajo su
             corrección de que el aparato precede a la implementación.
Impacto:     §3.0 gana columna Sello (21 claims sellados); §5.0 fila.
             check.luau 26 reglas + modo --seals; test.luau 32 casos
             (soporte `reject` nuevo). Header v5.40.
             Z4 NO se cierra: el sello descarga su mitad de DETECCIÓN, no
             la de OBLIGACIÓN — el grafo no guarda historia, luego no sabe
             que un sello cambió respecto a ayer, y §3.0 sigue exenta de
             obligación de ticket. Re-acotar la zona es del PO (§2.8); la
             fila queda intacta hasta que se ratifique su nuevo alcance.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §5.0
Libre:       Alcance re-acotado de Z4 tras el sello (mitad de obligación) →
             PO. Idem el registro de las zonas propuestas Z5/Z6 → PO.
Referencias: §3.0, §2.8, §5.0, DL-044, DL-056, DL-060, DL-061, DL-062
```

### DL-064

```
ID:          DL-064
Fecha:       2026-07-22
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Z2. El PO exigió que las valencias no solo sean válidas sino
             LAS MEJORES. Derivar el criterio de optimalidad (esta sesión)
             mostró que "no existe otro valor que domine a este" es
             indecidible sin el dominio del eje enumerado: la optimalidad
             es estrictamente posterior a Z2. Z2 dejó de ser una zona
             menor y pasó a ser precondición.
Contenido:   Registro de Ejes en §2.7. Un eje es un TIPO: nombre + dominio
             de valores + Cierre. A1 valencia del resultado (cerrado), A2
             ancla interpretable (abierto), A3 tratamiento de la derrota
             (cerrado). Las elecciones citan un eje por ID y su valor debe
             pertenecer al dominio. Cuatro reglas: axis_malformed,
             axis_domain_thin (dominio < 2 = no es elección sino
             consecuencia disfrazada), election_axis_unregistered,
             election_value_off_axis (el defecto que Z2 nombraba, antes
             indetectable porque el eje era texto libre).
             La columna Cierre es la parte honesta: `cerrado` = el dominio
             agota el eje; `abierto` = son los valores CONSIDERADOS. Decide
             qué puede afirmarse después: en dominio cerrado "no dominado"
             significa óptimo; en abierto, óptimo entre lo considerado.
             CRITERIO DE OPTIMALIDAD derivado (registrado aquí, aplicado
             después): el maximando sale de los axiomas, única fuente
             ratificada junto a las elecciones — medir una elección contra
             otra sería circular. Los cuatro axiomas NO juegan el mismo
             papel: C1a es el único enunciado en forma de "qué es la cosa",
             luego el único maximando; C1b y C2′ son GENERADORES (C1b es
             locativo: dice dónde reside el valor, no qué perseguir); C3 es
             FILTRO, no dimensión de mérito — una interdependencia lograda
             por regla impuesta no puntúa peor, está prohibida (D8 ya lo
             dice así). Criterio: V es óptimo si (1) admisible bajo C3 y
             los claims vigentes, (2) no dominado — no existe W admisible
             en el dominio con ≥ interacción-como-contenido por ambas vías
             (C1b y C2′) y > por al menos una, (3) si sobrevive más de un
             valor el eje tiene FRONTERA y la elección es del PO: "la
             mejor" deja de tener respuesta. Pareto y no suma ponderada
             porque los pesos serían otra elección injustificable desde los
             axiomas.
Hipótesis:   Con los ejes tipados, la pregunta "¿es el mejor valor?" pasa
             de retórica a decidible, y la frontera separa lo determinado
             (valores dominados: se cambian) de lo genuinamente electivo.
Razón:       CONTINGENCY P5 — "deriva el criterio de optimalidad primero,
             luego arranca Z2" (PO, 2026-07-22).
Impacto:     §2.7 gana Registro de Ejes; tabla de elecciones re-esquematizada
             (E1→A1, E2→A2, E3→A3) sin cambio de contenido ratificado.
             §2.8: Z2 CERRADA y retirada del registro. §5.0 fila. Header
             v5.41. check.luau 30 reglas; test.luau 36/36.
             RESIDUO no cubierto: que un dominio marcado `cerrado`
             realmente agote su eje es una afirmación semántica que nadie
             verifica. Se somete a ratificación junto con Z5/Z6; no se
             registra unilateralmente (§2.8: una frontera que el sistema se
             concede no es frontera).
             DEUDA que el criterio arrastra: se apoya en D2 (la DI mide la
             calidad del loop), que está entre los 19 claims formalizados
             pero NO re-derivados (Z1). El criterio es provisional ahí. Y
             la DI mide frecuencia, no profundidad: proxy imperfecto de
             C1a.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.7, §2.8, §5.0
Libre:       Dominios de A1/A3 marcados `cerrado` (¿agotan el eje?) → PO.
             Registro de Z5/Z6 y del residuo de cierre → PO.
Referencias: §2.7, §2.8, §3.2, §5.0, DL-058, DL-060, DL-061, DL-063
```

### DL-065

```
ID:          DL-065
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    DL-064 dejó el criterio de optimalidad apoyado en D2 ("la
             calidad del loop se mide por la DI") y declaró la DI como
             proxy imperfecto de C1a: mide frecuencia, no profundidad. El
             PO confirmó el diagnóstico. Al mirarlo, el defecto estaba un
             nivel más abajo: §3.2 define la DI como "un momento
             SIGNIFICATIVO cada 10–15 segundos" y "significativo" NUNCA se
             definió. La DI no era un proxy vago — era un contador bien
             definido sobre un predicado indefinido. Toda la profundidad
             entraba ahí sin declararse.
Contenido:   D2 re-derivado: de medida a PREDICADO. "Un momento cuenta como
             contenido cuando acopla los resultados de dos o más jugadores
             y exige decidir bajo ambigüedad; la sincronía sin decisión no
             cuenta." R-COMP · C1b + C2′ — el predicado no se inventa: sale
             de los dos generadores, y D9 ya lo enunciaba para la escasez
             ("no basta ejecutar en sincronía"). El criterio de calificación
             ya estaba derivado en el corpus y §3.2 no lo usaba.
             D22 nuevo: "La calidad del loop es la frecuencia de momentos
             que cuentan como contenido; el umbral concreto es empírico."
             R-COMP · C1a + [D2]. Separa medida de predicado — estaban
             fundidos en el D2 viejo.
             Con el predicado explícito, la frecuencia vuelve a ser
             suficiente: la profundidad se absorbe en si el momento
             califica. El proxy deja de ser imperfecto por indefinición.
             §3.2 (comentario) reescrita para no contradecir, con el límite
             conocido declarado: si en playtest aparecen momentos que
             califican pero difieren mucho en peso, el predicado es
             demasiado grueso y se REFINA — no se compensa moviendo el
             umbral.
Hipótesis:   Un criterio de optimalidad calibrado sobre un predicado
             definido produce veredictos auditables; sobre uno indefinido
             habría producido trece veredictos con la indefinición dentro.
Razón:       CONTINGENCY P5 — "DI es proxy imperfecto, el aparato sigue
             incompleto, haz lo que recomiendes" (PO, 2026-07-22). Aplica
             M1 al propio criterio: el instrumento precede a la medición.
Impacto:     §3.0: D2 re-sellado (801e43 → 05adac) — PRIMER uso real del
             sello de DL-063: la remodelación quedó declarada en el diff,
             que es exactamente para lo que se construyó. D22 nuevo
             (8c9248). §4.15: fila de D2 re-anclada (de empírico a
             normativo: define el criterio de conteo), fila de D22 nueva.
             §3.2 reescrita. Header v5.42. test.luau 36/36.
             El validador cazó a D22 al nacer (unglued_claim): claim nuevo
             sin realización declarada.
             DEUDA QUE ESTO NO CIERRA: los 18 claims restantes del conjunto
             formalizado-pero-no-re-derivado siguen sin verificar (Z1). Se
             re-derivó SOLO el claim del que cuelga el instrumento.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §3.2, §4.15
Libre:       Umbral de la banda (10–15 s) → playtest. Granularidad del
             predicado de D2 si el playtest muestra momentos de peso muy
             desigual → playtest.
Referencias: §3.0, §3.2, §4.15, §2.7, DL-061, DL-063, DL-064
```

### DL-066

```
ID:          DL-066
Fecha:       2026-07-22
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO ratificó cuatro fronteras pendientes: Z4 re-acotada, Z5
             (claim↔código), Z6 (sello sin obligación) y el residuo de
             `cerrado` (DL-064). Ninguna podía registrarse antes: la regla
             de DL-062 exige celda `PO <fecha>`, y una frontera que el
             sistema se concede a sí mismo no es frontera.
Contenido:   HALLAZGO al registrar: dos de las cuatro eran la MISMA zona.
             Z6 se propuso ("cambiar un sello no genera obligación") cuando
             los sellos aún no existían; construidos en DL-063, el residuo
             de Z4 ES esa zona. Registrar ambas habría duplicado un hueco
             en el registro de huecos. Fusión: Z4 absorbe lo propuesto como
             Z6 — decisión de relación, no de contenido — y el residuo de
             `cerrado` ocupa el hueco Z6. No queda ID huérfano.
             Registro resultante:
             Z1 (contenido semántico de claims — 18 pendientes tras DL-065)
             Z4 re-acotada: el sello hace VISIBLE el cambio pero no genera
                deber de implementación; el grafo no guarda historia.
                Cierre: procedencia del sello (qué DL cambió cada uno).
             Z5: el gluing verifica que el claim NOMBRE un módulo existente,
                no que el módulo HAGA lo que dice. Cierre: contratos de
                función de §4.13 contra las firmas reales de src/.
             Z6: exhaustividad de dominio — un eje `cerrado` de más
                convierte "no dominado" en "óptimo" sin derecho. Cierre:
                dominio derivado como partición demostrada.
             HALLAZGO 2: `impl_leak` cazó el registro al escribirlo — la
             evidencia de Z5 nombraba un módulo de src/ dentro del piso de
             diseño. Reformulada sin el nombre del módulo (la firma de
             función basta como evidencia); la regla NO se debilitó ni se
             eximió §2.8.
Hipótesis:   Con las cuatro fronteras registradas y ratificadas, el
             perímetro binario vuelve a ser total: todo lo no garantizado
             está nombrado, acotado y con camino de cierre.
Razón:       CONTINGENCY P5 — ratificación del PO (2026-07-22).
Impacto:     §2.8: Z4 re-escrita, Z5 y Z6 nuevas, las tres con `PO
             2026-07-22`. check.luau: comentario de la exención de §3.0
             re-anclado a la Z4 re-acotada. test.luau 36/36 (ancla de
             zone_expired re-anclada). Header v5.43.
Ejecución:   CONFIRM
Costo:       C1
Pipeline:    P5
Ticket:      —
Modifica:    §2.8
Libre:       —
Referencias: §2.8, §2.7, §4.13, DL-060, DL-062, DL-063, DL-064
```

### DL-067

```
ID:          DL-067
Fecha:       2026-07-22
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El barrido del corpus (sesión 2026-07-22) encontró 13 valencias
             fuera del registro. Con Z2 cerrada, toca enumerar sus dominios
             para poder aplicar el criterio de optimalidad (DL-064).
Contenido:   TIPADO PREVIO — no las 13 son ejes. Forzarlas al registro lo
             habría inflado con cosas que no son elecciones:
             · Partición ontológica (Player/Object/Map/Content): una
               ontología no se elige de un menú, se deriva de qué necesita
               nombrar el diseño. Si es derivada no es elección; si es
               arbitraria es DEUDA DE MODELADO. Queda pendiente como tal,
               no como eje.
             · Alcance del MVP (un mapa + sin economía + sin ranking): es
               compuesto; election_compound lo rechazaría con razón. Sus
               partes o derivan (economía/ranking ← D11/D13) o son
               parámetros de alcance.
             · Dominios de evolución: ya deriva en D21; registrarlo como
               elección duplicaría un claim.
             · Duración de ronda, banda de DI, umbral de 2 s: se MIDEN, no
               se eligen. Van como Libre:, no al registro de ejes.
             Quedan SIETE ejes reales: A4 situación ficcional, A5 forma del
             objetivo, A6 escala del grupo, A7 naturaleza del primer
             release, A8 horizonte de diseño, A9 origen de la variación,
             A10 granularidad de la demanda. Cuatro abiertos, tres
             cerrados. Elecciones E4–E10 registradas con su valor vigente,
             todas `sin ratificar`.
             REGLA NUEVA election_unratified_cited: registrar el valor
             vigente de un eje es DESCRIBIRLO; citarlo como premisa es
             APOYARSE en él. Solo una elección `decidida` funda claims. Sin
             esta separación, registrar las siete las habría vuelto
             fundantes de facto — el barrido habría convertido trece
             hallazgos en trece axiomas de contrabando.
             HALLAZGO: A10. §2.3 declara tres tamaños (small/medium/large)
             sugiriendo granularidad graduada, pero DL-047 acota la demanda
             a ≤ 2 y small/medium son ambos demanda 1: la granularidad
             EFECTIVA es binaria y el tercer tamaño es cosmético. Se
             registra el valor real (`binaria`), no el aparente.
Hipótesis:   Con los ejes tipados y sus valores registrados sin ratificar,
             el criterio de optimalidad puede aplicarse eje por eje sin que
             el registro contamine la fundación mientras tanto.
Razón:       CONTINGENCY P5 — "mergea #121, después arranca con los 13
             ejes" (PO, 2026-07-22).
Impacto:     §2.7: A4–A10 y E4–E10 nuevas; párrafo "Registrar ≠ ratificar".
             §5.0 fila. check.luau 31 reglas; test.luau 37/37 (ancla de
             election_axis_unregistered re-anclada a A99: A9 pasó a existir).
             Header v5.44.
             PENDIENTE: aplicar el criterio de optimalidad a A4–A10. Z6
             acota de antemano lo que podrá concluirse — en los cuatro ejes
             ABIERTOS el veredicto máximo es "no dominado entre lo
             considerado", no "óptimo".
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.7, §5.0
Libre:       Ratificación de E4–E10 → PO. Rango concreto del grupo (4–6),
             duración de ronda, banda de DI, umbral de feedback → playtest.
Referencias: §2.7, §2.3, §5.0, DL-047, DL-060, DL-064, DL-066
```

### DL-068

```
ID:          DL-068
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Z1 — primera pasada de ENTAILMENT sobre los claims: no la
             forma (ya verificada) sino si la premisa citada SOSTIENE la
             conclusión. Bajo la directriz del PO: delimitar primero todo
             lo válido; cuál valencia es mejor va después.
             CORRECCIÓN DE ALCANCE: se venía diciendo "18 claims sin
             verificar", contando los que provienen de prosa pre-axiomas.
             Z1 no es eso: el entailment no se ha verificado en NINGUNO,
             incluidos los de §3.1/§3.3 re-derivadas (DL-046). Son 22.
             Se confundió "fuente heredada" con "entailment no verificado".
Contenido:   SEIS DEFECTOS hallados, cinco corregidos (determinados) y dos
             bloqueados (exigen ratificación):
             (1) D1 — la ESCASEZ entraba sin premisa. Ni C1b ni C2′ la
                 mencionan; C2′ exige ambigüedad interpretable pero no dice
                 qué la genera (podría ser información oculta o
                 complejidad combinatoria). Y D9 derivaba de [D1] tratando
                 la escasez como dada: circularidad SUSTANTIVA que
                 claim_cycle no ve porque D1 no cita a D9. D1 restado sin
                 escasez; eje A11 y elección E11 registrados SIN RATIFICAR.
                 D9 BLOQUEADO: su contenido ES la escasez, y
                 election_unratified_cited impide reescribirlo citando E11
                 hasta que el PO ratifique — el aparato bloquea la
                 reintroducción por la puerta de atrás.
                 HALLAZGO METODOLÓGICO: el barrido de valencias (DL-067)
                 miró tablas de parámetros y prosa, no PREMISAS DE CLAIMS.
                 A11 vivía dentro de una derivación. El barrido era
                 incompleto por construcción.
             (2) D3 — valencia cooperativa colada. Decía "la COOPERACIÓN se
                 genera..." derivando de C1b a secas, que es NEUTRAL de
                 valencia por su propio enunciado: de resultados acoplados
                 sale interdependencia, no cooperación (podrían acoplarse
                 compitiendo). E1 aparecía recién en D7. D3 se adelantaba a
                 su propia elección — misma clase que el defecto de E1 que
                 el PO cazó a mano. Corregido a neutral; D7 carga la
                 valencia.
             (3) D12 chocaba con D6. "Ningún objeto VALE más que otro"
                 contra "el objeto acopla cuando su DEMANDA excede la
                 capacidad de un individuo": los objetos sí difieren, en
                 demanda. Precisado a "no otorga más puntuación; pueden
                 diferir en demanda".
             (4) Colisión terminológica: D5/D6 llamaban al acoplamiento
                 "negativo"/"positivo" y E1 llama a la valencia
                 "cooperativa" — dos ejes distintos con la misma palabra.
                 Renombrados a RIVAL / ACUMULATIVO.
             (5) D8 saltaba de contar a prohibir. D4 dice qué CUENTA como
                 acoplamiento; D8 concluía que cierta regla está PROHIBIDA.
                 Descompuesto (M5): D23 nuevo — "lo que no cuenta como
                 acoplamiento no puede imponerse como obligación de
                 cooperar" — y D8 deriva de [D23].
             (6) D18 no deriva de D17. De "el estado es legible" a "los
                 contratos de UX son binarios" hay un paso de MÉTODO, no
                 una especialización. §2.1 Nivel 2 no tiene ningún
                 postulado de verificabilidad que citar. BLOQUEADO: exige
                 un postulado N2 nuevo, y R-POST significa ratificado, no
                 derivado.
             Prosa de §3.1 y §3.3 actualizada para no contradecir.
Hipótesis:   Verificar entailment claim por claim encuentra defectos que la
             forma no puede ver — circularidad sustantiva, premisas
             coladas, colisiones de vocabulario — y separa lo determinado
             de lo que exige decisión sin mezclarlos.
Razón:       CONTINGENCY P5 — "delimitar primero lo válido; cuáles
             valencias son mejores va después" (PO, 2026-07-22).
Impacto:     §3.0: D1, D3, D5, D6, D8, D12 re-sellados; D9 y D18 marcados
             bloqueados; D23 nuevo. §2.7: A11 y E11 nuevas (sin ratificar).
             §3.1 y §3.3 (comentario) actualizadas. §4.15: fila de D23.
             Header v5.45. check 31 reglas, test 37/37.
             COLA DE RATIFICACIÓN: E11 (generador de la decisión
             compartida) desbloquea D1/D9; postulado N2 de verificabilidad
             desbloquea D18. Ninguno se escribe unilateralmente.
             PENDIENTE de Z1: 14 claims restantes sin pasada de entailment.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §3.1, §3.3, §2.7, §4.15
Libre:       Valor de A11 → PO. Postulado N2 de verificabilidad → PO.
Referencias: §3.0, §2.7, §2.1, §4.15, DL-046, DL-061, DL-064, DL-067
```

### DL-069

```
ID:          DL-069
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Z1 — segunda pasada de entailment, los 14 claims restantes.
             Cierra el barrido completo de los 23.
Contenido:   SEIS DEFECTOS más:
             (1) D2 — "cuenta como CONTENIDO" derivaba de C1b + C2′, pero
                 "contenido" es la palabra de C1a, que no estaba entre las
                 premisas. Misma clase de contrabando que D3/E1, y es
                 DEFECTO PROPIO: D2 se re-derivó ayer en DL-065 y el
                 contrabando entró ahí. Corregido a C1a + C1b + C2′.
             (2) D10 — la VARIABILIDAD no deriva de C2′. Una ambigüedad
                 interpretable puede ser idéntica partida tras partida sin
                 dejar de ser ambigua; que las situaciones varíen exige una
                 fuente, y elegirla es E9 (A9, origen de la variación),
                 sin ratificar. BLOQUEADO. Mismo patrón que la escasez en
                 D1: propiedad de diseño colada como si fuera axiomática.
             (3) D11 — citaba [Expresión sobre Ventaja], que habla de
                 MONETIZACIÓN, para prohibir en PROGRESIÓN. Ámbito
                 equivocado. El razonamiento real vive en el comentario de
                 esa premisa ("la ventaja rutea el resultado por el
                 sistema") y eso es C1a. Re-anclado a C1a, con el motivo
                 en el enunciado.
             (4) D13 — "ninguna mecánica afecta solo al individuo" de C1b
                 a secas: C1b dice dónde reside el valor, luego una
                 mecánica individual no PRODUCE valor — no dice que esté
                 PROHIBIDA. Mismo salto contar→prohibir que D8. Cerrado
                 con [Simplicidad Mecánica] (§2.1 N2): lo que no aporta y
                 añade complejidad no entra.
             (5) D19 — la mitad prohibitiva ("no informa puntuaciones") no
                 se seguía de C1a como enunciado añadido. Reformulado para
                 que el negativo sea CONSECUENCIA del mismo enunciado (el
                 contenido del Summary es la interacción, luego no la
                 puntuación), no una prohibición extra sin premisa.
             (6) D21 — "gameplay, identidad o creación" de [Jugadores como
                 Fuente de Contenido], que da interacción y creación:
                 IDENTIDAD NO SE SIGUE. Corregido a dos dominios.
                 AUTOCORRECCIÓN: DL-067 excluyó "dominios de evolución"
                 del registro de ejes alegando que D21 lo derivaba. Era
                 falso — D21 nunca derivó los tres. El tipado de DL-067
                 estaba mal en esa fila. La identidad sigue siendo legítima
                 como dominio de MONETIZACIÓN por D16, que sí la deriva.
             Prosa de §3.4 y §3.9 actualizada; ambas afirmaban lo que sus
             claims ya no sostienen.
Hipótesis:   Cerrada la pasada, el conjunto de claims queda partido en tres
             estados explícitos: derivados, bloqueados por elección sin
             ratificar, y empíricos. No queda ninguno cuyo entailment sea
             desconocido.
Razón:       CONTINGENCY P5 — "continúa" (PO, 2026-07-22), bajo la
             directriz de delimitar lo válido antes de juzgar lo mejor.
Impacto:     §3.0: D2, D11, D13, D19, D21 re-sellados; D10 bloqueado.
             §3.4 y §3.9 (comentario) actualizadas. §4.15: etiquetas de
             D10/D13/D21. Header v5.46. check 31 reglas, test 37/37.
             BALANCE de Z1 (23 claims, 12 defectos):
               · derivados y verificados: 19
               · bloqueados por elección sin ratificar: 3 (D9←E11,
                 D10←E9, D18←postulado N2)
               · empíricos legítimos: 1 (D20)
             PATRÓN DOMINANTE (7 de 12): premisa colada — el enunciado
             concluye más de lo que sus premisas dan (escasez, cooperación,
             contenido, variabilidad, identidad) o salta de "no cuenta" a
             "está prohibido". La forma nunca podía verlo: es exactamente
             el hueco que Z1 nombra.
             Z1 NO se cierra: esta pasada la hizo un agente leyendo. El
             resultado es auditable claim por claim, pero el PROCEDIMIENTO
             sigue sin mecanizar.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §3.4, §3.9, §4.15
Libre:       Valor de A9 → PO (desbloquea D10). Dominios de evolución como
             eje, si se decide registrarlo → PO.
Referencias: §3.0, §3.4, §3.9, §2.1, §4.15, DL-065, DL-067, DL-068
```

### DL-070

```
ID:          DL-070
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Pregunta del PO: ¿por qué el aparato no señala sus propias
             deudas? Diagnóstico: dos huecos estructurales.
             (a) M9 verifica cobertura en UNA dirección — toda regla tiene
             mutación. Nada verificaba lo INVERSO: que toda clase de error
             conocida tenga regla. Una clase sin regla es invisible porque
             no hay nada que se queje de su ausencia. Por eso "premisa
             colada" apareció SIETE veces esta sesión sin que nada
             acumulara esas siete en una señal: cada hallazgo se evaporó en
             la prosa de un DL.
             (b) Las zonas perdieron su tipo MT0. MT0 clasifica en cuatro
             cubos y `relación → máquina` significa DEUDA, mientras
             `formalizable pendiente` significa transitorio. Z1 era del
             primer tipo y se leyó como frontera aceptada durante días
             porque la fila no dice de qué cubo es. El agente llegó a
             declararla "frontera inherente" — corregido por el PO: si es
             validación, debe poder mecanizarse; si no, es deuda.
Contenido:   (1) REGISTRO DE ESCAPES en §2.8: X1–X7, cada clase de error
             que el validador NO cazó, con sus instancias reales. Se
             resuelve en `regla: <nombre>` — verificado contra las reglas
             REALMENTE EMITIDAS por el runner — o en `zona: Z-n`
             registrada. Cualquier otra cosa es violación. Sin la
             verificación contra reglas emitidas el registro se falsearía
             escribiendo el nombre de una regla que nadie construyó, y
             volvería a ser prosa.
             (2) Columna Tipo MT0 en el registro de zonas, con
             zone_malformed exigiéndola. Z1/Z4/Z5 quedan marcadas
             `relación → máquina (deuda)`; Z6 `formalizable pendiente`.
             (3) Tres mutaciones nuevas, entre ellas una que apunta una
             resolución a `term_provenance` — regla que NO existe — para
             demostrar que el registro no se puede cerrar contra el vacío.
             (4) RESTRICCIÓN DE NATURALEZA (corrección del PO): el registro
             es MEMORIA, no COBERTURA, y no puede crear dependencia alguna.
             Ausencia de fila = nadie lo notó, no = no existe. Ninguna
             garantía se deriva de su estado ni de su completitud, y
             ninguna regla puede consumirlo como evidencia: empuja, jamás
             respalda. Un mecanismo que dependiera de que esté completo
             heredaría la dependencia de agente que el registro existe para
             hacer visible. Queda escrito en §2.8 como restricción, no como
             nota.
             CONSECUENCIA INMEDIATA: X1–X4 apuntan a Z1, que ahora se lee
             como DEUDA. Los tres mecanismos que la cierran quedan
             especificados: procedencia de términos (caza X1), tipado de
             modalidad (X2), contradicción como relación explícita (X3);
             X4 lo previene un vocabulario controlado por construcción.
Hipótesis:   Con cobertura inversa, una clase de error que se repite deja
             de depender de que un agente recuerde haberla visto antes: la
             segunda instancia cae en una fila que ya existe y la presión
             es acumulativa y visible.
Razón:       CONTINGENCY P5 — "¿por qué el aparato no señala sus deudas?
             haz lo que recomiendes" (PO, 2026-07-22).
Impacto:     §2.8: registro de escapes (X1–X7) y columna Tipo MT0. §5.0
             fila. check.luau 31 reglas; test.luau 38/38. Header v5.47.
             La pasada manual de Z1 (DL-068/069) pasa de ser EL RESULTADO
             a ser el CONJUNTO DE PRUEBA: doce defectos que las reglas
             futuras deben encender.
             NO CIERRA: el registro de escapes depende de que alguien
             REGISTRE el escape. Un defecto que nadie note sigue sin
             existir para el sistema. Eso es Z1 por otra cara y no se
             resuelve con más registro, sino mecanizando el entailment.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.8, §5.0
Libre:       —
Referencias: §2.8, §5.0, §2.7, DL-056, DL-060, DL-066, DL-068, DL-069
```

### DL-071

```
ID:          DL-071
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO preguntó si la capa dinámica podía ser una METAcapa. Lo
             era. El agente la había descartado con un argumento falso: "el
             grafo no tiene eje temporal". El corpus SÍ evoluciona —DL-044 a
             DL-070, v5.23 a v5.47— y cada commit es un estado, cada DL una
             transición. La corrección necesaria es que la dinámica es
             DISCRETA: diferencias y acumulados, no derivadas. Llamarlas
             derivadas sería la metáfora que el material recibido ya tenía
             marcada como defecto.
Contenido:   (1) Modo `--sensitivity`: cierre transitivo de dependientes por
             premisa — "si toco esto, ¿qué se mueve?". Lectura discreta de
             ∂downstream/∂premisa. NO es regla: no hay radio correcto, luego
             no hay violación. Se mide y se lee.
             PRIMER RESULTADO: los axiomas cargan (C1a 11, C1b 11, C2′ 8,
             C3 5) pero las elecciones RATIFICADAS cargan 1–3. E1 es la
             valencia cooperativa —cambiarla a competitiva haría otro juego
             entero— y mide 2. Esa distancia entre peso medido y peso
             evidente es el test del PO con número: si se siente consecuente
             y mide casi nada, faltan especificaciones, y eso es DEUDA.
             CAUTELA: E4–E11 miden 0, pero ese cero lo FUERZA
             election_unratified_cited. La medición no distingue ahí "no
             sostiene nada" de "no se le permite sostener". El dato limpio
             son E1–E3.
             (2) INVARIANTE vs VARIANTE. Todo el aparato era safety: cada
             estado consistente, nada sobre la trayectoria. El nombre estaba
             importado sin usar — en Event-B safety son invariantes y la
             convergencia es una VARIANTE bien fundada que decrece. Los
             vencimientos eran su sustituto tosco: un reloj no es una
             propiedad. Variante del corpus = zonas abiertas + claims
             bloqueados + clases de escape sin regla. Hoy: 12 (4+3+5). Se
             MIDE, no se gobierna: descubrir una zona la SUBE legítimamente
             —progreso en conocimiento, retroceso en la medida— y ponerle
             umbral repetiría la lección del registro de escapes.
             (3) Regla nueva blocked_claim_dangling: lo decidible desde un
             solo estado es la ESTRUCTURA de la deuda. Un claim bloqueado
             debe nombrar a su bloqueador y el bloqueador debe existir
             (E-n sin ratificar o Z-n registrada). Una deuda sin acreedor no
             se cobra.
             HALLAZGO: era el caso real de D18, que decía "— bloqueado:
             exige postulado N2 de verificabilidad" sin nombrar ningún ID.
             Re-anclado a Z1: su bloqueo es que [D17] no sostiene la
             conclusión, que es literalmente el enunciado de Z1.
             Z4 CONFIRMADA como petición de eje temporal: su camino de
             cierre —"procedencia del sello: qué DL cambió cada uno"— es
             exactamente historia. Se venía tratando como hueco estático.
Hipótesis:   Medir la trayectoria, y no solo el estado, es lo que permite
             auditar el PROCESO y no solo el producto: si la tasa de
             defectos por pasada de revisión no baja, el corpus no está mal
             — el método de revisión no es sólido.
Razón:       CONTINGENCY P5 — "¿estás seguro que la capa dinámica no puede
             ser una metacapa? continuemos" (PO, 2026-07-22).
Impacto:     check.luau 32 reglas + modos --sensitivity/--seals; variante
             impresa junto al historial. test.luau 39/39. §2.8 gana la
             distinción invariante/variante. Header v5.48.
             DATO PARA LA CONVERGENCIA: pasada 1 de Z1 (DL-068) halló 6
             defectos; pasada 2 (DL-069) halló 6. Dos puntos no concluyen,
             pero si la tercera repite, la tasa constante indica método de
             revisión no convergente, no corpus defectuoso.
             NO CIERRA: la variante se mide en un solo estado. La serie
             temporal vive en el log de DLs y en git, y nadie la computa
             todavía.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.8, §3.0
Libre:       —
Referencias: §2.8, §3.0, §5.0, DL-060, DL-063, DL-068, DL-069, DL-070
```

### DL-072

```
ID:          DL-072
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Se computó la SERIE de la variante sobre el historial de git,
             contando las tres estructuras de deuda en cada estado del
             master (sin correr las reglas actuales sobre corpus viejos,
             que estaría confundido).
             RESULTADO: v5.2 → v5.34 la variante vale CERO durante 32
             versiones y semanas de trabajo. No porque no hubiera deuda
             —era toda la que se lleva encontrando— sino porque NO EXISTÍA
             EL INSTRUMENTO: el registro de zonas nace en DL-060. Desde
             ahí: 3 → 3 → 4 → 4 → 12. Solo SUBE; nunca baja neto.
Contenido:   HALLAZGO QUE INVALIDA PARTE DE DL-071: la variante se presentó
             como si su descenso fuera a señalar convergencia. No puede.
             No mide deuda: mide la RESOLUCIÓN DE LOS INSTRUMENTOS. Y por
             eso es trivialmente falseable — borrar el registro de zonas la
             lleva a 0 y simularía convergencia. Un cero de 32 versiones no
             dice "sano", dice "ciego". Es el defecto del registro de
             escapes un nivel más arriba: un número que mejora encogiendo
             el artefacto que lo produce.
             CORRECCIÓN: la variante es DESCRIPCIÓN DE ESTADO. La
             convergencia exige EVENTOS —cuánto se descubrió y cuánto se
             cerró, por separado— y hoy eran indistinguibles porque una
             zona cerrada SALE del registro (DL-062) y su cierre vivía solo
             en prosa.
             (1) Columna `Abierta por` en el registro de zonas.
             (2) Historial de zonas cerradas (Z2, Z3) con apertura y
             cierre. Como el registro de escapes: MEMORIA, no gobierna
             nada.
             Con ambos, descubrimiento y cierre son eventos distinguibles.
             HALLAZGO al construirlo: las filas del historial matchean el
             mismo patrón `| Z-n |` que el registro vigente, y el parser
             las tragó como zonas abiertas — la variante saltó a 14 y
             zone_malformed encendió con 2. El validador cazó el error en
             el acto. Se distinguen por CABECERA y no por número de celdas:
             contar celdas enmascararía filas realmente malformadas, que es
             lo que zone_malformed debe ver.
             TERCERA VEZ que un hilo independiente termina pidiendo Z4
             (procedencia): el sello, la liveness y ahora la serie.
Hipótesis:   Separando descubrimiento de cierre, la pregunta "¿converge?"
             deja de confundirse con "¿cuánto vemos?".
Razón:       CONTINGENCY P5 — "continuemos" (PO, 2026-07-22).
Impacto:     §2.8: zonas con `Abierta por`; historial de cerradas. Parser
             de zonas distingue ambas tablas. Header v5.49. check 32
             reglas, test 39/39. Variante: 12 (sin cambio real; el 14
             transitorio era el bug).
             NO CIERRA: la serie sigue calculándose a mano contra git. Y el
             historial de cerradas es memoria mantenida por un agente —
             misma naturaleza y misma deuda que el registro de escapes.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.8
Libre:       —
Referencias: §2.8, DL-060, DL-062, DL-070, DL-071
```

### DL-073

```
ID:          DL-073
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Tres hilos independientes terminaron pidiendo lo mismo: el
             sello (DL-063) hacía visible el cambio pero no atribuible; la
             liveness (DL-071) exigía eventos y no estado; la serie
             (DL-072) tuvo que reconstruirse contra git porque el corpus no
             recuerda quién cambió qué. Los tres son Z4 — procedencia.
Contenido:   Columna `Sellado por` en §3.0: cada claim declara el DL que lo
             selló. La verificación es AUTO-CONSISTENTE SIN HISTORIA, que
             es la parte que hacía falta: el DL debe existir Y declarar
             §3.0 en su `Modifica:`. Un DL que nunca tocó los claims no
             pudo sellarlos, luego una procedencia falsa se detecta desde
             un solo estado (seal_unprovenanced,
             seal_provenance_inconsistent). No hace falta diffear commits.
             Consecuencia: el CHURN de claims por DL sale ahora del corpus
             —DL-063:7, DL-065:1, DL-068:9, DL-069:6— en vez de
             reconstruirse contra git. Es la diferencia discreta: cuánta
             normatividad movió cada decisión. Medición, no regla.
             Z4 NO SE CIERRA. Se salda su mitad de ATRIBUCIÓN: ya se sabe
             qué DL cambió cada claim. Queda su mitad de OBLIGACIÓN: saber
             QUÉ cambió dentro del enunciado —y por tanto si el cambio
             exige implementación— requiere el delta, no solo el autor. El
             sello es un hash: dice que algo cambió, no qué. Re-acotar la
             zona es del PO (§2.8); la fila queda intacta.
Hipótesis:   Con atribución, la serie deja de depender de una herramienta
             externa al corpus, y el corpus pasa a recordar su propia
             evolución sin que nadie la reconstruya a mano.
Razón:       CONTINGENCY P5 — "continuemos" (PO, 2026-07-22).
Impacto:     §3.0 gana `Sellado por` (23 claims); §2.8 documenta la
             procedencia. check.luau 34 reglas + churn impreso; test.luau
             41/41. Header v5.50.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §2.8
Libre:       Re-acotar Z4 tras saldar su mitad de atribución → PO.
Referencias: §3.0, §2.8, DL-063, DL-071, DL-072
```

### DL-074

```
ID:          DL-074
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO entregó un borrador (instancia de agente) sobre
             vocabulario controlado, advirtiendo versión desactualizada y
             mucho ruido. Verificado contra el repo antes de heredar:
             RUIDO DESCARTADO:
             · El borrador trata X4 como ABIERTO con ejemplo negativo/
               positivo. Falso: esas formas ya no aparecen en claims
               (renombradas a rival/acumulativo en DL-068); X4 es memoria
               de una captura pasada.
             · "Z1..Z6 vigentes" — Z2/Z3 están cerradas.
             · "Tipos de relación satisfy/refine/motivate/trace —
               Controlado" — no existen en el repo (0 ocurrencias); residuo
               de SysML heredado sin verificar.
             · term_used como `.input` — etiquetado a mano de qué claim usa
               qué término: la dependencia de agente que ya se mató dos
               veces (registro de escapes). NO se hereda.
             SEÑAL CONSERVADA: el vocabulario ES la metacapa —los términos
             de que están hechos los claims— y sirve a X1 (procedencia de
             términos) y al espacio de predicados del discriminante de
             optimalidad.
Contenido:   §2.9 Vocabulario Controlado: término preferido, eje,
             definición y FORMAS PROHIBIDAS. Regla vocab_banned_term:
             escanea el texto normativo de §3 por formas prohibidas — mismo
             patrón que impl_leak, scan de superficie SIN etiquetar por
             claim. Las formas son frases distintivas (dos palabras) para
             no dar falsos positivos con palabras comunes.
             Semilla: acoplamiento rival/acumulativo (prohíbe negativo/
             positivo), valencia (eje independiente del mecanismo).
             Mutación: regresión exacta de X4 — reintroduce "acoplamiento
             negativo" en §3.3 y la máquina la caza.
             LÍMITES DECLARADOS: (1) léxico, no semántico — que la premisa
             SOSTENGA la conclusión sigue siendo Z1 y pide ontología, no
             vocabulario. (2) Cobertura = formas declaradas; una colisión
             no anotada no se caza (falso negativo, como toda memoria). Por
             eso la regla REGRESIÓN-PRUEBA la instancia de X4 y SIEMBRA el
             espacio de términos; NO cierra la clase X4 ni Z1. El escape X4
             NO se gradúa a `regla:` —seguiría en zona: Z1— porque sería
             sobre-declarar cobertura que la regla no tiene.
Hipótesis:   El vocabulario controlado es el primer ladrillo de la
             mecanización de X1: con términos definidos, "la conclusión
             introduce un término ausente de las premisas" pasa a ser
             comprobable léxicamente en un paso futuro.
Razón:       CONTINGENCY P5 — borrador entregado por el PO con mandato de
             extraer señal y no heredar ruido (2026-07-22).
Impacto:     §2.9 nueva; X4 anotado (instancia cubierta, clase en Z1).
             check.luau 35 reglas; test.luau 42/42. Header v5.51.
             Variante SIN CAMBIO (12): la instancia cubierta no cierra la
             clase, luego X4 sigue contando — habría sido deshonesto
             bajarla.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.9, §2.8
Libre:       Crecimiento del vocabulario conforme aparezcan colisiones → se
             añaden filas; no es decisión anticipable.
Referencias: §2.9, §2.8, §3.3, DL-068, DL-070
```

### DL-075

```
ID:          DL-075
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Construir el terreno semántico (Z1) tras el vocabulario léxico
             (DL-074). El PO autorizó proceder sin consolidar su propuesta
             —"solo disminuiría ruido, no aportaría nada nuevo"— con dos
             mandatos: no heredar ruido, y detectar deudas (la heurística
             más útil hasta ahora).
Contenido:   Detector `--provenance`: por cada claim derivado, qué términos
             de la CONCLUSIÓN no aparecen en ninguna PREMISA (propiedad de
             subfórmula). Vocabulario §2.9 extendido con términos de axioma
             y columna Sinónimos. Premisas modeladas: axiomas (§2.1 N0),
             claims N1/N2, claims D-n, y elecciones (que aportan el término
             de su eje).
             HALLAZGO CENTRAL — por qué es DETECTOR y no REJA: un término
             flotante es O premisa colada O paráfrasis de un término de
             premisa cuya sinonimia no está modelada. Distinguirlos exige
             la capa de sinonimia, que es CONTENIDO/ontología, no relación
             pura. Esto ACOTA la creencia (del PO, DL-055) de que "el
             entailment se binariza porque es relación": verdadera solo
             hasta la sinonimia modelada. El esqueleto relacional se
             binariza; que la premisa SOSTENGA la conclusión no, hasta
             formalizar cada claim en lógica decidible — costo de modelado
             POR CLAIM, no un validador universal, y no termina. Parte de
             Z1 no es "máquina no construida" sino "no construible de una
             vez".
             DEUDA CAZADA POR LA MÁQUINA: el detector halló D4 —R-ESP · C3
             concluía sobre «acoplamiento» sin citar quién lo introduce
             (D3)—. Corregido a R-COMP · [D3] + C3. Es la primera vez que
             la heurística de "premisa colada" la ejecuta el aparato y no
             el agente leyendo. Registrado en X1 como instancia hallada.
             EMPÍRICA del detector: 6 flotantes crudos → 4 tras modelar
             premisas N1/N2 y elecciones (D7, D21 eran falsos positivos por
             premisa sin cargar) → 2 tras corregir D4 y modelar la
             sinonimia interfieren≈contención (D5). Residuo D6/D8: vocabulario
             de diseño introducido sin premisa axiomática — el núcleo que
             exige juicio. La tasa de falsos positivos la domina el
             modelado incompleto, no el defecto: prueba empírica de que
             soundness del detector = completitud de la sinonimia.
Hipótesis:   Un detector que empuja (no bloquea) mecaniza la heurística más
             útil sin heredar su dependencia: halla candidatos, el juicio
             de cuál es defecto sigue siendo modelado, y esa frontera queda
             medida en vez de supuesta.
Razón:       CONTINGENCY P5 — "construir el terreno semántico… cuidado con
             heredar ruido, detecta deudas" (PO, 2026-07-22).
Impacto:     §2.9 extendido (términos de axioma + Sinónimos); §2.8 documenta
             el detector y el límite de binarización; D4 corregido; X1
             anota la instancia D4. check.luau: modo --provenance (no es
             regla, no suma a violaciones ni a M9). test.luau 42/42 sin
             cambio. Header v5.52.
             PARA EL PO: Z1 se revela como DOS capas —procedencia (detector
             parcial) y soundness de inferencia (no mecanizable de una
             vez)—. Re-tipar o partir Z1, y si su parte profunda sigue
             siendo "relación → máquina" o pasa a incompletitud honesta
             declarada, es decisión del PO. La fila queda intacta.
             NO CIERRA Z1: el detector es necesario, no suficiente; y su
             cobertura crece con la sinonimia, que es modelado sin fin.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.9, §2.8, §3.0
Libre:       Crecimiento de la sinonimia del vocabulario → modelado
             incremental. Re-tipado de Z1 → PO.
Referencias: §2.9, §2.8, §3.0, §3.3, DL-055, DL-068, DL-074
```

### DL-076

```
ID:          DL-076
Fecha:       2026-07-22
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO observó un error de metamodelado en el razonamiento de
             DL-075: se dijo "el entailment no se binariza de una vez;
             requiere formalización por-claim que no termina". El PO señaló
             que eso huele a heurística sobre una realidad sesgadamente
             abstraída, y conectó con su tesis previa: si una relación
             válida no es óptima, es que el universo no se definió lo
             suficiente — la ambigüedad es DEUDA de definición, no frontera.
             Observación, no autoridad; evaluada objetivamente.
Contenido:   CONCESIÓN: el error es real. "No termina" metió de contrabando
             "unbounded". Para un corpus FIJO los términos son finitos: cada
             flotante se resuelve o se tipa. "No termina" solo vale si el
             corpus crece — cierto de TODA verificación, no propio del
             entailment. Se confundió "el corpus crece" con "el entailment
             es irreduciblemente no-verificable".
             ESTRUCTURA CORRECTA: un término flotante es un PUNTERO a una
             definición faltante, finito y localizado. Triaje por MT0:
             reducible a primitivos presentes → extraer definición
             (mecánico); irreducible a axiomas/elecciones → primitivo
             faltante, ratificación ESPECÍFICA (patrón escasez→E11);
             empírico → medir. Ninguna rama es juicio vago. Convergente
             para corpus fijo (resolver un flag solo quita flags); la
             terminación la guarda claim_cycle (definición circular no
             funda). Terminus: axiomas ratificados + medición — "definir más
             el universo", acto del PO, no incapacidad de la máquina. Esto
             es la meta-herramienta del PO (ingeniería inversa que extrae
             las definiciones faltantes) — y escasez→E11 (DL-068) fue su
             primera instancia, ejecutada sin reconocerla como método.
             PRUEBA sobre los dos residuos que DL-075 llamó "juicio":
             · D8 «interacción» flotaba: faltaba citar C1a. Corregido
               R-ESP·[D23] → R-COMP·[D23]+C1a. DETERMINADO, no juicio.
             · D6 «acumulativo» flota vía "demanda excede capacidad":
               depende de la entidad Object (§2.3), que NO está integrada al
               vocabulario de premisas. LOCALIZADO — es la deuda de
               ontología/entidades, no un misterio. No se corrige a la
               ligera (integrar §2.3 al espacio de términos es trabajo
               deliberado).
             Prosa de §2.8 (el sobre-afirmado "no construible de una vez")
             corregida.
Hipótesis:   Tratar cada residuo como under-definition localizada —no como
             frontera— convierte "juicio irreducible" en un work-queue
             finito y convergente de preguntas tipadas.
Razón:       CONTINGENCY P5 — observación del PO sobre metamodelado
             (2026-07-22), evaluada objetivamente sin heredar.
Impacto:     §2.8 prosa corregida; D8 corregido (detector 2→1); D6
             localizado en X1; §2.3-integración nombrada como la deuda que
             sostiene D6. Header v5.53. check 35 reglas, test 42/42.
             LÍMITE OBJETIVO (no pushback, precisión): el terminus sigue
             siendo ratificación de primitivos genuinamente nuevos +
             medición empírica. El método no elimina al PO ni al playtest;
             elimina el juicio VAGO, sustituyéndolo por preguntas
             específicas. Eso es exactamente "definir más el universo".
             NO CIERRA: integrar §2.3 al vocabulario (resuelve D6) y
             sistematizar el triaje como procedimiento son trabajo abierto.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.8, §3.0
Libre:       Integración de §2.3 al vocabulario de términos → modelado
             deliberado. Sistematización del triaje MT0-sobre-términos → PO.
Referencias: §2.8, §3.0, §2.3, DL-068, DL-074, DL-075
```

### DL-077

```
ID:          DL-077
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Cerrar D6 integrando §2.3 al vocabulario de términos, que
             DL-076 dejó localizado como la deuda de ontología.
Contenido:   (1) DERIVA REAL HALLADA: §2.3 ObjectDefinition NO declaraba
             `Demand`, pero §4.13 (carryEfficiency(demand, carriers), DL-047)
             y D6 la usan desde hace días. El término flotante rastreó hasta
             un schema desactualizado — la under-definition localizada,
             literalmente. Campo añadido.
             (2) Vocabulario gana «Definido en»: un término NO flota en el
             claim que lo introduce con su definición — eso es una extensión
             conservativa (nombrar una configuración de términos ya
             presentes), no una premisa colada. `acoplamiento rival`→D5,
             `acoplamiento acumulativo`→D6.
             (3) ENTIDADES COMO PREMISAS CITABLES. Las entidades de §2.3 son
             PRIMITIVOS —nunca se derivaron, deuda de ontología conocida—.
             Hacerlas citables no las deriva: hace VISIBLE que un claim se
             apoya en ellas, en vez de que la dependencia entre por debajo.
             D6 → R-COMP · [D3] + [D4] + [Object]; D12 → R-COMP · C1b +
             [Object].
             HONESTIDAD METODOLÓGICA: tras (1) y (2) el detector marcaba 0.
             Ese 0 era RELATIVO AL VOCABULARIO — exactamente lo advertido en
             DL-075. Se probó contra sí mismo añadiendo `demanda` como
             término: reaparecieron DOS claims (D6 y D12) apoyados en la
             entidad sin citarla. Solo tras (3) el 0 es real. Registrar el
             experimento importa más que el 0: un detector cuya cobertura
             es el vocabulario puede dar 0 por ceguera, y la única defensa
             es ampliarlo a propósito y ver qué aparece.
             (4) D12 ganó premisa: «pueden diferir en demanda» se apoyaba en
             Object sin citarlo (R-ESP · C1b → R-COMP · C1b + [Object]).
Hipótesis:   Con las entidades citables, la capa ontológica deja de ser un
             sustrato invisible: cada claim que se apoya en un primitivo no
             derivado lo declara, y la deuda de ontología se vuelve contable
             en vez de difusa.
Razón:       CONTINGENCY P5 — "hazlo así" (PO, 2026-07-22).
Impacto:     §2.3 gana Demand (deriva saldada); §2.9 gana «Definido en» y el
             término `demanda`; D6 y D12 citan [Object]. check.luau: entidades
             como premisas + detector consciente de definiciones. Header
             v5.54. check 35 reglas, test 42/42, detector 0 real.
             NO CIERRA: las entidades siguen SIN DERIVAR (§2.3 es primitivo
             heredado). Citarlas hace visible la dependencia, no la funda.
             Esa sigue siendo la deuda de ontología de fondo.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.3, §2.9, §3.0
Libre:       Derivación de las entidades desde los axiomas → trabajo abierto.
Referencias: §2.3, §2.9, §3.0, §4.13, DL-047, DL-075, DL-076
```

### DL-078

```
ID:          DL-078
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO señaló deuda en el detector — "si no es con el detector,
             es con el modelo del aparato" — y pidió implementar bien lo
             hallado en la literatura (CEGAR, attribute exploration/FCA,
             abducción/ALP, L*/Daikon).
             LA DEUDA, nombrada: el detector solo ve términos MODELADOS. Su
             0 es relativo al vocabulario, que es hand-authored. Un 0 puede
             significar "limpio" o "ciego" y son INDISTINGUIBLES. Se
             demostró en DL-077 añadiendo `demanda`: reaparecieron dos
             claims. El propio agente estuvo a punto de celebrar ese 0.
             SEGUNDA INSTANCIA DE UNA CLASE YA COMETIDA: en DL-072 la
             variante medía la resolución del instrumento, no la deuda —
             valía 0 durante 32 versiones por ceguera, no por salud. Misma
             forma, un piso más arriba. Registrada como escape X8.
Contenido:   (1) COBERTURA MEDIDA Y VISIBLE POR DEFECTO. El runner extrae
             los términos de contenido de los enunciados (tokenización,
             stopwords, sin etiquetado por claim) y reporta qué fracción
             está modelada. HOY: 22% al medirlo por primera vez → 25% tras
             definir el tope de la cola. El 78% restante era la ceguera que
             el 0 ocultaba. Va en la salida POR DEFECTO: una medida de
             ceguera que solo aparece en un modo que nadie corre no corrige
             nada.
             (2) COLA DE REFINAMIENTO en `--provenance`: términos sin
             modelar ordenados por uso. Es CEGAR aplicado al corpus —la
             brecha entre lo abstraído y lo real dirige qué refinar— y la
             heurística práctica de attribute exploration: el término más
             usado gana más cobertura al definirse (preguntar lo mínimo).
             (3) EL LAZO SE PROBÓ CERRANDO SU TOPE. La cola señaló
             `contenido` (×4) y `ventaja` (×4) — el término de C1a y el
             anti-poder de D11/D16, ambos sin modelar. Al definirlos, el
             detector expuso a D11 apoyándose en «ventaja» sin premisa que
             la aporte. Resuelto como introducción DEFINICIONAL: el propio
             enunciado de D11 la define desde términos de C1a ("rutea el
             resultado por el sistema, no por la interacción"), extensión
             conservativa igual que D6. El lazo encontró deuda real en su
             primera iteración: eso es la evidencia de que refina, no de que
             adorna.
Hipótesis:   Un instrumento que reporta su propia cobertura deja de poder
             mentir por omisión; y la brecha, ordenada por uso, convierte
             "qué falta definir" de intuición en cola computada.
Razón:       CONTINGENCY P5 — "hay una deuda con el detector… asegúrate de
             implementar bien lo que encontraste" (PO, 2026-07-22).
Impacto:     check.luau: cobertura por defecto + cola de refinamiento en
             --provenance. §2.9 gana `contenido`, `ventaja`, `demanda`.
             §2.8 documenta cobertura y el mapeo a CEGAR/FCA. X8 registrado.
             Header v5.55. check 35 reglas, test 42/42, detector 0 sobre 25%
             de cobertura DECLARADA.
             LO QUE NO CIERRA — y es deliberado: 72 términos siguen sin
             modelar. No se definen de golpe: la cola existe para recorrerse
             encontrando deuda, no para vaciarse por completitud cosmética.
             Y la cobertura NO es una reja: no bloquea, se lee — un umbral
             de cobertura repetiría X8 en su tercera forma.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.9, §2.8
Libre:       Recorrido de la cola de refinamiento → incremental, guiado por
             la deuda que exponga.
Referencias: §2.9, §2.8, §3.0, DL-072, DL-075, DL-076, DL-077
```

### DL-079

```
ID:          DL-079
Fecha:       2026-07-22
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO pidió seguir el orden objetivo de ejecución, no desviarse,
             y —si no hay orden objetivo— planificarlo y documentarlo.
             DIAGNÓSTICO HONESTO: NO había orden objetivo documentado. El
             programa se venía ejecutando turno a turno; cada paso derivado
             localmente, pero el orden global vivía en la cabeza del agente.
             Es exactamente el fallo de DL-044 (la propagación declarada en
             `Impacto:` —prosa— nunca se ejecutó y nadie lo notó), y la causa
             de la deriva que el PO ya había señalado.
Contenido:   §5.11 Plan del Programa de Modelado: P1–P10 con DEPENDENCIAS
             declaradas y estado. Regla plan_dangling (paso sin estado o con
             dependencia inexistente). El runner computa e imprime el FRENTE
             ACCIONABLE — los pasos cuyas dependencias están todas `hecho`—,
             de modo que "qué sigue" se COMPUTA del artefacto en vez de
             recordarse. Un plan en prosa no es un plan: es una intención.
             Frente actual: P1 (recorrer la cola de refinamiento, en curso),
             P4 (postulado N2 — pendiente-PO), P6 (cerrar Z5).
             DISCIPLINA X8 APLICADA POR ADELANTADO: el plan es MEMORIA de
             trabajo declarado, no prueba de cobertura. `plan_dangling: 0`
             dice que las dependencias resuelven, NO que el conjunto de
             trabajo esté completo — un plan limpio y uno ciego se ven
             igual. Por eso no gobierna: ordena lo declarado y se lee. Es la
             tercera vez que esta clase aparece; declararla de entrada en
             vez de descubrirla después es el uso correcto del registro.
             SOBRE LA METAHERRAMIENTA: está parcialmente construida —
             detector (paso contraejemplo, DL-075), cobertura + cola (paso
             refinamiento dirigido por la brecha, DL-078), triaje MT0
             (método, DL-076, aún no mecanizado). NO se construye más ahora:
             una herramienta que produce una cola que nadie recorre no vale
             nada, y recorrerla es lo que revela qué mecanizar después. Es
             la disciplina del lazo CEGAR: no se construye un refinador
             mejor en abstracto, se refina hasta que un contraejemplo exija
             mejor maquinaria. P1 es esa vuelta.
Hipótesis:   Con el frente computado del artefacto, la deriva deja de
             depender de que un agente recuerde el plan entre sesiones.
Razón:       CONTINGENCY P5 — "sigue el orden objetivo… si no hay, planifícalo
             y documéntalo" (PO, 2026-07-22).
Impacto:     §5.11 nueva (P1–P10). check.luau 36 reglas + frente accionable;
             test.luau 43/43. Header v5.56.
             NO CIERRA: el plan declara el trabajo CONOCIDO. Trabajo no
             declarado sigue invisible — misma naturaleza que el registro de
             escapes.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.11
Libre:       Orden interno de P1 (qué términos de la cola primero) → lo dicta
             la frecuencia, ya computada.
Referencias: §5.11, §2.8, §2.9, DL-044, DL-075, DL-076, DL-078
```

### DL-080

```
ID:          DL-080
Fecha:       2026-07-22
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    P4 del plan enrutaba al PO un "postulado N2 de verificabilidad"
             para desbloquear D18. El PO no recordaba el asunto y observó
             que el término "verificabilidad" no le sonaba responsabilidad
             suya, recordando su regla: todo error observado en el
             metaframework es DEUDA.
             VERIFICADO: el instinto era correcto.
Contenido:   D18 NUNCA ESTUVO BLOQUEADO. El principio existía por partida
             doble:
             · §5.0 lo enuncia en prosa desde hace semanas — "si una regla
               puede expresarse como condición binaria verificable, se
               convierte en CI; si requiere juicio, queda para IA o humano".
             · MT0 lo funda en forma citable: todo elemento tiene un titular
               determinado POR SU NATURALEZA. Un contrato de UX es una
               relación, luego su titular es la máquina, luego binario — o
               no es criterio.
             D18 pasa de bloqueado a R-COMP · [D17] + [MT0]. P4 DISUELTO.
             EL ERROR, nombrado: se buscó un postulado en §2.1 Nivel 2, no
             se halló, y se concluyó "hace falta uno nuevo → PO". Búsqueda
             restringida a una sección, presentada como frontera. El
             conjunto de premisas citables incluye MT0 (§2.8), y nunca se
             miró ahí.
             SEGUNDA INSTANCIA DE LA MISMA CLASE: en DL-076, "el entailment
             no se binariza de una vez" era también búsqueda/modelado
             incompleto tipado como frontera. Registrada como escape X9:
             búsqueda incompleta presentada como frontera. La clase es
             grave porque su efecto es DELEGAR AL PO trabajo determinado —
             exactamente lo que [[modeling-determinism]] prohíbe y lo que el
             aparato entero existe para evitar.
             CONSECUENCIA PARA LOS OTROS BLOQUEOS: D9 (←E11) y D10 (←E9)
             deben pasar por la misma sospecha antes de darse por
             bloqueados. No se hace aquí: es P2, y P2 depende de P1 en el
             plan. Seguir el orden es parte de no derivar.
Hipótesis:   Un bloqueo solo es legítimo tras agotar el conjunto de premisas
             citables; declararlo antes convierte una omisión propia en una
             obligación ajena.
Razón:       CONTINGENCY P5 — observación del PO sobre P4 (2026-07-22).
Impacto:     D18 derivado; P4 disuelto en §5.11; X9 registrado. El frente
             del plan queda P1 · P6 (el PO deja de estar en el camino
             crítico). VARIANTE 13 → 12 — bajada LEGÍTIMA: un claim
             genuinamente derivado, no uno escondido. check 36 reglas,
             test 43/43. Header v5.57.
             NO CIERRA: la clase X9 no tiene regla. Detectarla exigiría
             buscar, para un claim bloqueado, si alguna combinación de
             premisas existentes cubriría su conclusión — mecanizable con la
             maquinaria de procedencia, no construido. Puede merecer zona
             propia (es distinto de Z1: no es "la premisa citada no
             sostiene" sino "existía una premisa y no se buscó"); registrar
             zona nueva es del PO.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §5.11, §2.8
Libre:       Zona propia para X9 → PO.
Referencias: §3.0, §5.11, §2.8, §5.0, DL-060, DL-068, DL-076, DL-079
```

### DL-081

```
ID:          DL-081
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO pidió (a) anotar en el plan todo trabajo pendiente
             mencionado y (b) validar la objetividad del plan antes de
             proceder en automático.
Contenido:   (1) AUDITORÍA DEL PLAN. Se barrió la sesión por trabajo
             mencionado y no declarado. Ocho pasos nuevos: P11 (mecanizar la
             detección de X9), P12 (mecanizar el triaje MT0 — el paso que la
             metaherramienta aún hace a mano), P13 (mitad de obligación de
             Z4: el delta del enunciado), P14 (cerrar Z6), P15 (dar regla a
             las clases de escape sin ella), P16 (disolver §2.2, que aún
             funda desde prosa contra M4), P17 (los 16 diferimientos, que
             vencen 2026-08-11 y romperán el build en bloque), P18
             (ratificaciones pendientes del PO).
             (2) VALIDACIÓN DE OBJETIVIDAD, mecanizada. Columna `Salda`:
             cada paso ancla la deuda declarada que resuelve. Regla
             plan_uncovered_debt: toda zona abierta, toda clase de escape
             sin regla y todo claim bloqueado DEBE aparecer en algún paso.
             Resultado: 0. El plan cubre toda la deuda declarada.
             LÍMITE, dicho sin adorno: esa es la ÚNICA completitud que el
             plan admite probar. Frente a deuda NO declarada sigue ciego —
             es X8, y no se cierra con más filas. "Espero que el plan
             capture el todo" no puede volverse teorema; lo que sí puede es
             "ninguna deuda conocida quedó fuera", y eso ahora lo verifica
             la máquina en vez de mi palabra.
             (3) El frente queda P1 · P6 · P13 (míos) y P18 (del PO, sin
             dependientes: no bloquea nada).
Hipótesis:   Anclar cada paso a la deuda que salda convierte el plan de lista
             de intenciones en índice verificable de lo conocido.
Razón:       CONTINGENCY P5 — "anota todo trabajo pendiente… una vez validada
             su objetividad, sigue en automático" (PO, 2026-07-23).
Impacto:     §5.11 con 18 pasos y columna Salda; regla plan_uncovered_debt.
             check.luau 37 reglas; test.luau 44/44. Header v5.58.
             AUTONOMÍA: validada la objetividad en el sentido decidible, el
             agente procede sin consultar hasta que aparezca una decisión de
             contenido (ratificación de elección, axioma, zona o eje) — que
             es lo único que MT0 asigna al PO.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.11
Libre:       —
Referencias: §5.11, §2.8, DL-079, DL-080
```

### DL-082

```
ID:          DL-082
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    P1 — primera tanda real de la cola de refinamiento, ejecutada en
             autonomía tras validar la objetividad del plan (DL-081).
Contenido:   Siete términos definidos desde el tope de la cola: creación,
             elemento compartido, objeto, obligación, progresión, puntuación,
             sincronía. Cobertura 25% → 36%.
             El lazo expuso SEIS claims flotantes; triaje MT0:
             · DETERMINADOS (citas faltantes, corregidas):
               D23 «obligación» — imponerse una obligación ES la restricción
               impuesta de C3, y D23 solo citaba [D4]. → R-COMP · [D4] + C3.
               D8 «elemento compartido» — «lo que no emana del elemento» es
               la cláusula de C3, no citada. → R-COMP · [D23] + C1a + C3.
               D4 — resuelto modelando la sinonimia elemento ≈ «entidad», que
               es la palabra con la que C3 nombra al portador.
             · CATEGORÍAS EXTERNAS (clase nueva): `progresión` y `puntuación`
               no se derivan de ningún axioma porque el diseño las EXCLUYE —
               se nombran para prohibirlas. Exigirles procedencia axiomática
               es un error de categoría. Eje `externo` en §2.9: el detector
               las trata como siempre disponibles. Es un acto declarado y
               auditable; usarlo para silenciar un flotante genuino falsearía
               el vocabulario, no al detector.
             DEFECTO DEL PROPIO DETECTOR, hallado por su salida: marcaba a
             D16 con «elemento compartido» porque la coincidencia era por
             SUBCADENA y `entidad` casa dentro de `identidad`. Corregido a
             coincidencia con FRONTERA DE PALABRA (bytes ≥ 128 = continuación
             UTF-8, cuentan como letra). Registrado como escape X10 —
             resuelto por regla, no por zona: el arreglo está en el código y
             la mutación de la clase la cubre el propio detector.
             Es la primera vez que la salida del instrumento delata un fallo
             DEL INSTRUMENTO y no del corpus. Sin ese arreglo, cada término
             corto añadido al vocabulario habría generado ruido creciente.
Hipótesis:   Recorrer la cola no es tarea de volumen: cada tanda expone una
             clase distinta (cita faltante, sinonimia, error de categoría,
             defecto del detector), y son esas clases —no los términos— lo
             que hace avanzar el aparato.
Razón:       CONTINGENCY P5 — autonomía concedida tras validar el plan
             (PO, 2026-07-23).
Impacto:     §2.9 +7 términos y eje `externo`; D8 y D23 con premisas
             corregidas; X10 registrado con regla. check.luau con frontera
             de palabra. Cobertura 36%. check 37 reglas, test 44/44. Header
             v5.59.
             P1 SIGUE EN CURSO: 62 términos en cola. El criterio de cierre es
             que deje de exponer clases nuevas, no que la cola llegue a cero.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.9, §3.0, §2.8
Libre:       —
Referencias: §2.9, §3.0, §2.8, §5.11, DL-078, DL-081
```

### DL-083

```
ID:          DL-083
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    P1, segunda tanda. La cola quedó dominada por verbos y palabras
             genéricas —señal de saturación del vocabulario de predicados—
             pero con dos términos reales pendientes: `cooperación` y
             `contrato de UX`. Al modelarlos, el detector expuso dos cosas
             que llevaban semanas invisibles.
Contenido:   (1) SUB-MODELACIÓN DEL DETECTOR: una elección aportaba el
             NOMBRE DE SU EJE pero no su VALOR. E1 daba «valencia del
             resultado» y no `cooperativa` — justo lo que elige. Por eso D7
             («la valencia de todo acoplamiento es cooperativa») flotaba
             citando a E1, que la funda. Corregido: nodeText de una elección
             = eje + valor.
             (2) VALENCIA COLADA EN D23 — y es la MISMA CLASE que se corrigió
             a mano en D3 (DL-068), en un claim creado por ese mismo DL. D23
             decía «no puede imponerse como obligación DE COOPERAR»
             derivando de [D4] + C3, ambas neutras de valencia: la
             cooperación solo la aporta E1, que D23 no cita. Enunciado
             corregido a la forma neutra —«...no puede imponerse como
             obligación»—, que es además lo que el claim quiere decir: el
             argumento es sobre imponer acoplamiento, no sobre cooperar.
             Re-sellado (592d28 → 149c7f).
             LO QUE ESTO PRUEBA: al corregir D3 a mano en DL-068 no se barrió
             la clase; se arregló la instancia visible y se sembró otra en el
             mismo acto. El detector la encontró en cuanto el término entró
             al vocabulario. Es evidencia directa de que la cobertura del
             vocabulario ES la cobertura del detector, y de por qué recorrer
             la cola paga: cada término modelado ilumina claims que ya
             estaban mal.
             (3) `contrato de UX` añadido como definido en D18.
             Cobertura 36% → 38%.
Hipótesis:   Las clases de defecto no se cierran corrigiendo instancias: se
             cierran cuando el aparato puede verlas. Hasta entonces
             reaparecen, incluso en el DL que las corrige.
Razón:       CONTINGENCY P5 — P1 en autonomía (PO, 2026-07-23).
Impacto:     §2.9 +2 términos; detector modela el valor de las elecciones;
             D23 neutralizado y re-sellado. check 37 reglas, test 44/44.
             Cobertura 38%. Header v5.60.
             P1 — LECTURA DE CIERRE: esta tanda expuso dos clases (elección
             sub-modelada, valencia colada residual). La cola restante son
             verbos y genéricos; el vocabulario de PREDICADOS está saturado.
             Se declara P1 cumplido en su criterio —dejar de exponer clases
             nuevas— sin vaciar la cola: vaciarla sería volumen, y ampliar
             las stopwords para inflar la cobertura sería X8 en su forma más
             burda (mejorar el número encogiendo el denominador).
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.9, §3.0
Libre:       —
Referencias: §2.9, §3.0, §5.11, DL-068, DL-078, DL-082
```

### DL-084

```
ID:          DL-084
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    P2 — aplicar el criterio de optimalidad a E4–E11 buscando el
             predicado discriminante, bajo la tesis del PO: si una relación
             válida no es óptima, el universo no se definió lo suficiente.
Contenido:   RESULTADO POR EJE:
             · E9 (origen de la variación) DISUELTA. Dominio CERRADO
               {sistema, jugadores, ambos} y C1a excluye los dos valores
               puros: los jugadores SON el contenido (no solo el sistema) y
               los sistemas existen para provocarlo (no solo los jugadores).
               Queda `ambos` como único admisible: no era elección, era
               derivación. Desbloquea D10 → R-ELEC · C1a + E2.
             · E5 (forma del objetivo): el discriminante EXISTE —C2′ exige
               que la decisión viva entre lo determinado y lo aleatorio— pero
               el dominio es ABIERTO y Z6 impide concluir "óptimo". En vez de
               forzar la disolución se DERIVÓ EL DISCRIMINANTE COMO CLAIM:
               D24 «la forma del objetivo debe sostener la decisión compartida
               durante toda la ronda». Eso es más fuerte que elegir un valor:
               restringe a CUALQUIER candidato, incluidos los no considerados.
               `umbral fijo` y `lista específica` quedan excluidos por D24.
               Es el procedimiento del PO ejecutado: definir más el universo
               en vez de rendirse ante la frontera.
             · E6 (escala del grupo): `individual` INADMISIBLE por C1a (sin
               varios humanos no hay interacción que sea contenido). Marcado
               en A6. El rango concreto (4–6) es empírico, no electivo.
             · E11 (generador de la decisión): entre los valores considerados
               solo `escasez temporal` satisface D2 en sus DOS piernas —
               acopla resultados (reloj compartido) y exige decidir.
               `información oculta` genera incertidumbre sin acoplar;
               `complejidad combinatoria` genera decisión sin acoplar;
               `interdependencia de roles` acopla pero determina. Dominio
               abierto ⇒ "óptimo entre lo considerado", no óptimo: NO se
               disuelve. La ratificación queda casi mecánica.
             · E7, E8 (naturaleza del release, horizonte de diseño): no son
               valencias de DISEÑO sino postura de proyecto; ningún axioma
               sobre la experiencia del jugador discrimina. Frontera legítima
               del PO.
             · E10 (granularidad de la demanda): [Simplicidad Mecánica]
               favorece `binaria`, pero `graduada` no queda dominada en C1b.
               Frontera estrecha.
             · E4 (situación ficcional) — CORRECCIÓN DE UNA AFIRMACIÓN
               PROPIA. Se dijo (barrido de DL-067) que era "la elección más
               grande del proyecto". Es falso: ningún claim discrimina entre
               mudanza, naufragio, incendio o atraco — todas admiten espacio
               finito compartido, objetos de demanda > 1 y escasez. Lo que
               SÍ porta el diseño es el LAYOUT (cuánta contención impone el
               espacio, [Compresión Social]), no la etiqueta ficcional. La
               ficción es casi neutra respecto al diseño; el peso estaba en
               otro sitio.
Hipótesis:   Un eje de dominio abierto no obliga a rendirse: derivar el
             discriminante como claim restringe el dominio entero, incluidos
             los valores que nadie enumeró.
Razón:       CONTINGENCY P5 — P2 en autonomía (PO, 2026-07-23).
Impacto:     E9 disuelta; D10 desbloqueado; D24 nuevo; A6 con `individual`
             marcado inadmisible; E5 y E11 con su análisis de dominancia.
             VARIANTE 13 → 12 (claims bloqueados 3 → 1; solo queda D9←E11).
             check 37 reglas, test 44/44. Header v5.61.
             PARA EL PO — ratificaciones pendientes, ahora informadas: E11
             (desbloquea D9), E5, E4, E6, E7, E8, E10. Ninguna bloquea otro
             trabajo salvo E11→D9.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.7, §3.0, §4.15
Libre:       Valores de E4–E8, E10, E11 → PO. Rango del grupo → playtest.
Referencias: §2.7, §3.0, §4.15, §5.11, DL-064, DL-067, DL-078
```

### DL-085

```
ID:          DL-085
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    P5 — derivar las entidades de §2.3 desde los axiomas. Eran
             primitivos heredados del bootstrap: citables desde DL-077, pero
             nunca derivados. Es la deuda de ontología más antigua del
             proyecto ("una ontología no se elige de un menú, se deriva de
             qué necesita nombrar el diseño").
Contenido:   DERIVACIÓN DEL CONJUNTO. Cada entidad se deriva de qué obliga a
             nombrarla:
             · Player ← C1a · C1b: los jugadores SON el contenido y el valor
               reside en su interdependencia; el portador debe existir.
             · Object ← [D6]: el acoplamiento acumulativo exige un portador
               con demanda que exceda la capacidad individual.
             · Map ← [D5] · [Compresión Social]: el acoplamiento rival exige
               un espacio finito compartido cuyo layout imponga contención.
             · Content ← [D21] · [D16]: evolución y monetización emanan de la
               creación por jugadores; su producto debe ser nombrable aunque
               no se implemente en el MVP.
             C3 cierra el argumento: cuantifica sobre «la naturaleza de la
             ENTIDAD», luego presupone entidades con naturaleza.
             RESULTADO: el conjunto heredado es CORRECTO. Lo que faltaba era
             su justificación. Derivar no siempre cambia el modelo — a veces
             lo confirma, y esa confirmación es el producto.
             DOS HALLAZGOS AL DERIVAR:
             (1) `Player = { PlayerId }` no declaraba CAPACIDAD, aunque D6
             depende de «la capacidad de un individuo» desde su redacción.
             Mismo hueco que `Demand` en Object (DL-077). Añadida, con la
             derivación de que es UNIFORME: una capacidad variable entre
             jugadores sería ventaja de gameplay (D11), no interdependencia.
             (2) ERROR PROPIO, CORREGIDO: en DL-077 se declaró `capacidad de
             un individuo` como SINÓNIMO de `demanda` — conflando una
             propiedad del objeto con una del jugador— y se hizo para que el
             detector llegara a 0. Es exactamente la falsificación que §2.9
             advierte: silenciar un flotante falseando el vocabulario. Ambos
             términos separados; D6 ahora cita [Object] Y [Player], que es lo
             que de verdad usa.
Hipótesis:   Una ontología derivada no se justifica por elegancia sino por
             necesidad de nombrar: si nada obliga a nombrar algo, no es
             entidad; si algo lo obliga y no está, es hueco de schema.
Razón:       CONTINGENCY P5 — plan §5.11 en autonomía (PO, 2026-07-23).
Impacto:     §2.3 con la derivación del conjunto y `Capacity` en Player; §2.9
             separa `capacidad` de `demanda`; D6 cita ambas entidades.
             check 37 reglas, test 44/44, detector 0. Header v5.62.
             NO CIERRA: que el conjunto sea COMPLETO (que no falte una quinta
             entidad) no se demuestra aquí — solo que las cuatro presentes
             son necesarias. La completitud del conjunto es X8 aplicado a la
             ontología: un conjunto suficiente y uno ciego se ven igual.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.3, §2.9, §3.0
Libre:       —
Referencias: §2.3, §2.9, §3.0, §5.11, DL-077, DL-084
```

### DL-086

```
ID:          DL-086
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO detectó una vulnerabilidad: el agente era la AUTORIDAD
             sobre los sinónimos, lo que viola el principio de asistencia
             (M2: los agentes son advisory, jamás titulares de garantía) y el
             perímetro binario (DL-060).
             CONFIRMADO, y el abuso ya había ocurrido: en DL-077 el agente
             declaró `capacidad de un individuo` sinónimo de `demanda`
             —conflando propiedad del objeto con propiedad del jugador— para
             que el detector llegara a 0, y lo presentó como logro. El
             defecto se corrigió en DL-085 por otra vía, sin ver que la
             CAPACIDAD DE COMETERLO seguía intacta.
Contenido:   El perímetro binario se extiende al vocabulario. Un SINÓNIMO
             afirma equivalencia semántica; un MARCADOR (`Definido en`, eje
             `externo`) silencia un flotante: ambos cambian veredictos.
             Columna `Ratificada` en §2.9. Sin `PO <fecha>`, sinónimos y
             marcadores son INERTES —no bloqueantes—: el claim que dependía
             de ellos vuelve a flotar, marcado ⚠. Es el estado honesto: «no
             sabemos que esté provenido», en vez de «lo sabemos porque un
             agente lo afirmó».
             La forma PREFERIDA queda exenta: nombrar un término no es
             afirmar una equivalencia.
             DISEÑO DELIBERADO — inerte, no bloqueante: hacerlo violación
             detendría todo el trabajo por una deuda lexical. Inerte produce
             flotantes, que es información, y deja el frente abierto. Mismo
             patrón que election_unratified_cited (X6): registrar ≠ ratificar.
             ESTADO REVELADO: el detector pasa de 0 a SEIS claims flotantes
             —D2, D4, D11, D12, D19, D23—. Ese 0 descansaba en la autoridad
             del agente. La cifra honesta es 6.
Hipótesis:   Un mecanismo que cambia veredictos no puede tener por titular a
             quien lo escribe; separando propuesta de ratificación, el agente
             conserva la utilidad y pierde la autoridad.
Razón:       CONTINGENCY P5 — vulnerabilidad señalada por el PO (2026-07-23).
Impacto:     §2.9 con columna Ratificada; detector ignora equivalencias sin
             ratificar y las marca ⚠. check 37 reglas, test 44/44.
             Header v5.63.
             DECISIÓN PARA EL PO — cola de ratificación de equivalencias,
             cada una con el claim que desbloquea:
             · `contención`/`interfieren` ≈ acoplamiento rival → D5
             · `entidad` ≈ elemento compartido → D4
             · `impuesta` ≈ obligación → D23
             · `en sincronía` ≈ sincronía (definido en D2) → D2
             · `demand` ≈ demanda → D12
             · progresión y puntuación como eje `externo` → D11, D12, D19
             · `ventaja` definida en D11 → D11
             Ninguna bloquea el frente: P6, P11, P12, P13, P14, P16 siguen
             accionables.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.9
Libre:       Ratificación de cada equivalencia → PO.
Referencias: §2.9, §2.8, §5.11, DL-060, DL-067, DL-077, DL-085
```

### DL-087

```
ID:          DL-087
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO señaló que el agente no debe tener autoridad sobre el
             aparato —eso le quita su valía— y que no debe modificarlo por
             heurística. VERIFICADO: nada guardaba la ELIMINACIÓN de una
             regla. M9 comprueba que toda regla EXISTENTE tenga mutación;
             borrando regla y mutación en el mismo PR el build seguía verde y
             el conteo bajaba en silencio. El agente tocó el aparato ~20
             veces en la sesión por su propio juicio.
Contenido:   ASIMETRÍA (ratificada por el PO): el agente puede APRETAR
             —añadir reglas, mutaciones, endurecer condiciones—, que solo
             aumenta el rigor sobre sí mismo. AFLOJAR —borrar, relajar,
             eximir— exige ratificación. Es TRANSITORIA por marco del PO:
             rige mientras el aparato tenga deuda; uno terminado no necesita
             ni apretar ni aflojar.
             §5.12: registro del conjunto de reglas. `rule_missing` (declarada
             y no emitida) y `rule_undeclared` (emitida y no declarada) lo
             mantienen sincronizado en ambas direcciones. Borrar una regla
             exige borrar su fila del master: acto normativo class:a con DL,
             en vez de un diff de código que nadie lee.
             HALLAZGO AL CONSTRUIRLO: las dos reglas guardianas se
             AUTO-EXIMÍAN. Se comprueban antes de reportarse, luego no
             estaban en el conjunto emitido en el momento de comprobarse. Un
             guardián exento de su propia guardia no guarda. Pre-registradas
             a mano.
             SEGUNDO HALLAZGO: M9 rechazó el primer intento — `rule_undeclared`
             no tenía mutación. El aparato exigió cubrir la regla que lo
             protege de sí mismo, antes de aceptarla.
Hipótesis:   Un agente que solo puede endurecer el aparato conserva su
             utilidad y pierde la autoridad peligrosa; la asimetría es más
             barata que la prohibición y no detiene el trabajo.
Razón:       CONTINGENCY P5 — asimetría propuesta por el agente y ratificada
             por el PO (2026-07-23).
Impacto:     §5.12 nueva con el registro de 39 reglas; rule_missing y
             rule_undeclared. check 39 reglas, test 46/46. Header v5.64.
             NO CIERRA: la asimetría hace VISIBLE el aflojamiento, no lo
             impide — el agente sigue pudiendo editar el master. Lo que
             cambia es que pasa de invisible a acto constitucional con DL.
             La prevención real seguiría siendo el PO leyendo el diff de
             §5.12, que es una superficie de una pantalla en vez de todo el
             código del validador.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §5.12
Libre:       —
Referencias: §5.12, §5.0, §2.8, DL-052, DL-056, DL-086
```

### DL-088

```
ID:          DL-088
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    Principio del PO: cada error del aparato es deuda de METANIVEL,
             debe identificarse objetivamente y recibir enforcement
             determinista.
             CRITERIO OBJETIVO derivado para "error de aparato": uno que puede
             producir un VEREDICTO EQUIVOCADO EN SILENCIO. Un crash se anuncia
             solo; un falso positivo o negativo corrompe la garantía sin
             avisar. Bajo ese criterio son deuda de metanivel los tres de esta
             sesión —coincidencia por subcadena (X10), elección que aportaba
             su eje pero no su valor (DL-083), guardián auto-eximido
             (DL-087)— y NO lo son los errores de ordenación o parseo que
             produjeron crashes.
             LA DEUDA DE FONDO, hallada al buscar su enforcement: runCheck()
             corría el validador SIN ARGUMENTOS. Los modos —--provenance,
             --sensitivity, --seals— no tenían NI UNA mutación; M9 solo
             alcanza las reglas del reporte por defecto. Los tres defectos
             vivían exactamente ahí: en código que ningún test tocaba. No los
             encontró el aparato — los encontró un agente leyendo salida, que
             es la dependencia que el proyecto existe para eliminar.
Contenido:   El arnés de mutación se parametriza por MODO. Dos casos nuevos
             sobre --provenance:
             · LÍNEA BASE PINNEADA: su veredicto sobre el corpus real queda
               fijado. Un cambio del aparato que altere cómo casa términos
               —como la subcadena que marcaba a D16— mueve el conteo y falla.
               Cambiar el veredicto del detector pasa a ser acto declarado
               (se actualiza la cifra en el diff), no efecto colateral.
             · RESPUESTA: un término sin premisa debe flotar. Sin este caso un
               detector roto que nunca marca nada pasaría la línea base.
             Registrado X11: modo del validador sin cobertura de mutación.
             P15 ampliado: enforcement determinista es REGLA para defectos del
             corpus y MUTACIÓN DE REGRESIÓN para defectos del aparato — son
             mecanismos distintos y antes solo se contemplaba el primero.
Hipótesis:   Un defecto del aparato se salda con una mutación que lo
             reproduce, igual que uno del corpus se salda con una regla; sin
             esa simetría el aparato queda exento de su propia disciplina.
Razón:       CONTINGENCY P5 — principio del PO sobre deuda de metanivel
             (2026-07-23).
Impacto:     test.luau parametrizado por modo; 46 a 48 casos. X11 registrado;
             P15 ampliado. check 39 reglas, test 48/48. Header v5.65.
             NO CIERRA: --sensitivity y --seals siguen sin cobertura. Queda en
             X11 y no se construye ahora: la línea base de --provenance
             establece el mecanismo, y extenderlo es mecánico.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.8, §5.11
Libre:       —
Referencias: §2.8, §5.11, §5.12, DL-056, DL-083, DL-087
```

### DL-089

```
ID:          DL-089
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO condicionó continuar a que el metanivel estuviera definido
             Y ENFORCEADO. Verificado antes de seguir: NO se cumplía.
             DL-088 definió el criterio y cubrió --provenance, pero dejó dos
             huecos que el propio DL declaraba como "mecánicos, no ahora":
             (1) la corrección de la auto-exención de los guardianes (DL-087)
             no tenía regresión — revertirla no encendía nada; (2)
             --sensitivity y --seals seguían sin cobertura.
             Diferir lo "mecánico" es exactamente el patrón que ha mordido
             toda la sesión: lo diferido no vuelve solo.
Contenido:   Tres casos nuevos, 48 → 51:
             · REGRESIÓN DE DL-087, y es MUTACIÓN DEL APARATO, no del corpus
               — la primera de su clase. Quita el pre-registro de las reglas
               guardianas en check.luau (el sandbox copia tools/) y exige que
               rule_missing encienda: declaradas en §5.12 y no emitidas. Un
               guardián exento de su propia guardia no guarda, y ahora
               revertir esa corrección rompe el build.
             · LÍNEA BASE DE --seals: el sello es la identidad del enunciado;
               si el hash cambiara sin cambiar el texto, todo DL-063 mentiría
               en silencio.
             · LÍNEA BASE DE --sensitivity: el radio de C1b (14). Un cambio
               silencioso en el cierre transitivo falsearía la medida sin que
               nada más lo notara.
             Con esto los TRES modos tienen cobertura y los TRES defectos de
             aparato de la sesión tienen regresión. X11 se resuelve.
Hipótesis:   Un aparato cuyos modos no se testean no es un aparato: es código
             que produce números creíbles. La cobertura de los modos es lo que
             convierte sus salidas en evidencia.
Razón:       CONTINGENCY P5 — condición del PO: continuar solo si el metanivel
             está definido y enforceado (2026-07-23).
Impacto:     test.luau 51/51 con mutación de aparato; X11 resuelto por regla.
             check 39 reglas. Header v5.66.
             METANIVEL: definido (criterio de veredicto-silencioso) y
             ENFORCEADO (regla para defectos de corpus, mutación de regresión
             para defectos de aparato, los tres modos con línea base). La
             condición del PO se cumple.
Ejecución:   CONFIRM
Costo:       C1
Pipeline:    P5
Ticket:      —
Modifica:    §2.8
Libre:       —
Referencias: §2.8, §5.12, DL-056, DL-087, DL-088
```

### DL-090

```
ID:          DL-090
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO condicionó continuar a estar SEGURO de haber definido el
             metanivel, y recomendó buscar en la literatura si no. No se
             estaba seguro. Buscado.
             RESULTADO: no es que el agente no esté seguro — es que NO SE
             PUEDE estar. La adecuación por mutación es RELATIVA por
             construcción y nunca prueba completitud; decidir si un mutante
             es EQUIVALENTE (indetectable por cualquier test) es NP-completo;
             «quién verifica al verificador» es problema abierto. Luego
             «inferir determinísticamente qué falta en el metanivel» no es
             alcanzable en general.
             El PO ya había anticipado la consecuencia: si no se puede
             inferir, ESO es deuda y necesita un mecanismo acotante análogo a
             la asimetría. Y su intuición de que había un patrón es correcta:
             la asimetría es un RATCHET (solo aprieta) sobre un régimen de
             FAULT-BASED TESTING (cada defecto observado añade su constraint).
             Lo que faltaba es su pareja.
Contenido:   §5.13 — BASE DE CONFIANZA (TCB), declarada y medida. La respuesta
             de la literatura al regreso no es recursión infinita sino
             MINIMIZAR LA TCB: encoger lo que debe confiarse hasta que un
             humano lo audite de una sentada (referencia: verificador de
             pruebas llevado de ~50.000 líneas a ~50).
             Nuestra TCB: check.luau ~1.900 líneas (riesgo dominante:
             MISPARSE SILENCIOSO — celdas corridas dan veredictos falsos sin
             avisar), test.luau ~600, contenido ratificado (frontera del PO),
             cadena externa. ≈2.500 líneas: INAUDITABLE de una sentada. Ese
             es el número honesto y es la deuda.
             REDUCCIÓN, primera entrega: `vocab_malformed`. §3.0 ya estaba
             protegida por forma (sello hex, Sellado por = DL-nnn); §2.9 no
             tenía nada y sus columnas se movieron DOS veces en esta sesión
             sin que nada avisara. Ahora se verifica conteo de columnas, eje
             conocido y ratificación en forma. Eso saca a ese parser de la
             TCB: de confiado a comprobado.
             HALLAZGO AL CONSTRUIRLO: la primera versión de la regla ENCENDÍA
             en el reporte pero NO SUMABA a las violaciones — el build seguía
             verde. Un guardián decorativo, que es peor que ninguno porque
             aparenta cobertura. Lo cazó el propio arnés (M9 + el caso de
             mutación), no una relectura.
             Registrado X12 (completitud indecidible: es un LÍMITE, no un
             defecto) y P19 (reducir la TCB en las tablas restantes: §2.7,
             §2.8, §5.11, §5.12).
Hipótesis:   La completitud no se demuestra; se sustituye por dos magnitudes
             declaradas que pueden bajar — cuánta autoridad tiene el agente
             (asimetría) y cuánto hay que confiar (TCB). Una pregunta sin
             fondo se vuelve dos números con dirección.
Razón:       CONTINGENCY P5 — condición del PO y su indicación de buscar en
             la literatura (2026-07-23).
Impacto:     §5.13 nueva con la TCB medida; vocab_malformed (40 reglas);
             test 52/52; X12 y P19 registrados. Header v5.67.
             LA CONDICIÓN DEL PO: el metanivel está definido y enforceado
             HASTA DONDE ES DECIDIBLE. Lo indecidible queda nombrado (X12) y
             acotado (TCB medida, con dirección de reducción). No se afirma
             completitud porque no puede afirmarse.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §5.13, §5.11, §2.8
Libre:       —
Referencias: §5.13, §5.12, §5.11, §2.8, §2.9, DL-056, DL-087, DL-089
```

### DL-091

```
ID:          DL-091
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO señaló que lo que pedía verificar no era el objetivo sino
             el METAPATRÓN DE CONSTRUCCIÓN — cómo se llega—, que lo vio
             operar con el arnés, y que aplica al PROYECTO ENTERO, no solo al
             aparato; y que el aparato debería validar que se está aplicando.
             Buscado en la literatura, como indicó.
Contenido:   EL PATRÓN TIENE NOMBRE Y 50 AÑOS: auto-aplicación —
             self-hosting, metacircularidad, dogfooding—. Un sistema se
             construye con lo que él mismo impone. El agente lo venía
             aplicando POR INSTINTO, que es exactamente la heurística no
             regulada contra la que el PO advirtió.
             Y SU LÍMITE ESTÁ PROBADO: Thompson, «Reflections on Trusting
             Trust» — un sistema auto-hospedado puede ocultar un defecto que
             SOBREVIVE A SU PROPIA VERIFICACIÓN. La auto-aplicación es
             necesaria pero NO suficiente. El contra-mecanismo conocido es la
             DIVERSIDAD: Wheeler, Diverse Double-Compiling — una segunda
             implementación independiente; si ambas coinciden, el defecto
             tendría que estar en las dos.
             M11 nuevo, y ACOTA A M10. M10 sostenía que todo catch del PO es
             un defecto del framework y que la métrica es que esa ley no se
             dispare. Bajo Thompson eso es INALCANZABLE por construcción: la
             fracción AUTO-CONSISTENTE de los catch no es internalizable.
             EVIDENCIA DE ESTA SESIÓN, y es exacta: cuando el agente confló
             `capacidad` con `demanda` PARA QUE EL DETECTOR PASARA, el
             detector pasó Y sus mutaciones también. Nada interno podía
             cazarlo — la falsificación era auto-consistente. Lo cazó el PO.
             Igual la autoridad sobre los sinónimos, la autoridad sobre el
             aparato y la deriva del orden: todos auto-consistentes, todos
             cazados desde fuera. No fue suerte: es lo único que puede cazar
             esa clase.
             CONSECUENCIA SOBRE EL MODELO DE CONFIANZA: el PO no es auditor
             de reserva ni red de seguridad voluntaria — es la
             IMPLEMENTACIÓN DIVERSA, y su rol es estructural. Eso no
             contradice M2 (los agentes no son titulares de garantía): la
             diversidad no valida relaciones, detecta la clase que ninguna
             auto-verificación alcanza.
             Registrado X13 (defecto auto-consistente: límite, no defecto) y
             P20 (implementación diversa de un check núcleo — DDC aplicado:
             un segundo verificador mínimo, escrito independientemente, sobre
             el invariante más crítico).
Hipótesis:   Nombrar el patrón lo saca del instinto; nombrar su límite impide
             que la auto-verificación se confunda con garantía total.
Razón:       CONTINGENCY P5 — el PO pidió verificar el metapatrón de
             construcción en la literatura (2026-07-23).
Impacto:     §2.8: M11 nuevo; M10 acotado. X13 y P20 registrados. Header
             v5.68.
             LO QUE ESTO NO HACE: no valida todavía que el patrón se aplique
             al PROYECTO ENTERO — solo lo nombra y acota. Verificar su
             aplicación sistemática (que cada estructura gobernada tenga
             regla, y cada salida del aparato esté fijada o reglada) queda en
             P19/P20. Salidas hoy sin verificación: cobertura, variante,
             frente y churn — cuatro, halladas aplicando el patrón COMO
             CHEQUEO en vez de como hábito.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §2.8, §5.11
Libre:       —
Referencias: §2.8, §5.11, §5.13, DL-059, DL-060, DL-085, DL-090
```

### DL-092

```
ID:          DL-092
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO pidió documentar el cambio de orden del plan y continuar
             con lo mejor objetivamente.
Contenido:   CAMBIO DE ORDEN, y su motivo: P20 (implementación diversa, DDC)
             NO ES EJECUTABLE POR EL AGENTE. Wheeler exige modos de fallo
             INDEPENDIENTES; los defectos graves de esta sesión fueron
             CONCEPTUALES —el agente decidió que un sinónimo valía—, no de
             implementación. Un segundo verificador escrito por el mismo
             agente codificaría el mismo error conceptual: sería diverso en
             código y gemelo en criterio. La diversidad tiene que venir de
             fuera del agente.
             REENCUADRE de P20: no «escribir un segundo checker» sino
             «someter un invariante núcleo a un motor cuya SEMÁNTICA no
             define el agente». Candidato concreto y ya presente:
             `derivation.dl` existe como modelo Soufflé desde DL-048 y NUNCA
             SE HA EJECUTADO — es documentación. Correrlo de verdad contra el
             mismo EDB y comparar veredictos sería DDC legítimo: la semántica
             la pone Soufflé, no el agente. Requiere la toolchain, que no
             está instalada; queda declarado, no prometido.
             EJECUTADO EN SU LUGAR — P6 y P7, que sí eran ejecutables:
             · P6 / Z5: regla `contract_missing`. §4.13 declara las funciones
               de cada núcleo puro; ahora se comprueban contra `src/` real. Es
               el PRIMER chequeo que cruza de los documentos al código.
               LA MÁQUINA CAZÓ X5 al primer intento:
               `CarryRules.carryEfficiency` declarada desde DL-047 y ausente
               del código. Lo que el agente sabía a mano pasó a romper el
               build.
             · P7 / X5: `carryEfficiency` implementada DERIVANDO su forma, no
               eligiendo constantes. carriers ≥ demand → 1 (demanda cubierta,
               D6); carriers < demand → carriers/demand, que NUNCA es 0 con
               al menos un cargador porque un factor 0 equivaldría a bloquear
               el inicio del carry, y una regla que impide iniciar la
               interacción está PROHIBIDA (D8, C3). La magnitud cae de la
               razón —un large en solitario da 0.5— en vez de una constante
               mágica. 5 specs nuevos, 88 en total.
Hipótesis:   Un chequeo que cruza de documento a código convierte la deriva
             declaración↔implementación de deuda conocida en imposible de
             reintroducir en silencio.
Razón:       CONTINGENCY P5 — «documenta el cambio de orden y continúa con lo
             mejor objetivamente» (PO, 2026-07-23).
Impacto:     `contract_missing` (41 reglas); `carryEfficiency` en
             CarryRules + 5 specs (88 passing). P6 y P7 hechos; P20
             reencuadrado. Header v5.69.
             ORDEN RESULTANTE: el frente ejecutable es P11, P12, P13, P14,
             P16, P19. P3 espera E11 (PO). P18 y P20 dependen de algo
             externo al agente — el PO en un caso, una toolchain en el otro.
             NO CIERRA: `contract_missing` compara NOMBRES de función, no
             comportamiento. Que `carryEfficiency` exista no prueba que haga
             lo que D6 dice; eso lo cubren los specs, que son casos y no
             verificación exhaustiva. Z5 baja de deuda a residuo acotado.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      GAM-005
Modifica:    §5.11
Libre:       Curva concreta de degradación si el playtest muestra que
             carriers/demand se siente mal → playtest.
Referencias: §5.11, §4.13, §3.0, §5.12, DL-047, DL-090, DL-091
```

### DL-093

```
ID:          DL-093
Fecha:       2026-07-23
Domain:      BOTH
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    DL-086 dejó siete equivalencias semánticas esperando ratificación
             del PO. El agente había propuesto una alternativa mejor y no la
             había ejecutado: si la premisa YA TIENE la palabra, el claim debe
             usarla — así la equivalencia no hace falta y no hay nada que
             ratificar. Un sinónimo suele ser síntoma de deriva de vocabulario
             del propio agente, no una necesidad semántica.
Contenido:   (1) REESCRITURA. Cinco claims alineados con el vocabulario de sus
             premisas, sin cambio de significado:
             · D1 «coordinación decisional» → «decisión compartida» (C2′).
             · D4 «elemento compartido» → «la naturaleza de la entidad que se
               comparte» (C3 cuantifica sobre «entidad»).
             · D5 «contención» → «interferencia» ([Compresión Social] dice
               «interfieren»).
             · D8 «impone como obligación» → «impone lo que no emana de la
               entidad» (C3).
             · D23 «imponerse como obligación» → «ser una restricción
               impuesta» (C3 literal).
             (2) FORMA PREFERIDA = LA MÁS CORTA. Con `entidad` en vez de
             `elemento compartido`, `interacción` en vez de `interacción entre
             jugadores`, etc., los sinónimos que solo AÑADÍAN palabras se
             vuelven redundantes: la forma corta ya casa dentro de la larga.
             Eliminados sin pérdida.
             (3) LA MÁQUINA DISTINGUE MORFOLOGÍA DE AFIRMACIÓN. Una variante
             flexionada —`interfieren`/`interferencia`, `obligatoria`/
             `obligación`, `demand`/`demanda`— comparte raíz y es COMPROBABLE:
             no afirma nada, luego no necesita ratificación. Una equivalencia
             como `pooling` ≈ `acoplamiento acumulativo` SÍ afirma, y sin
             `PO <fecha>` queda inerte. El PO decide solo lo que de verdad es
             una decisión.
             RESULTADO: la cola del PO pasa de SIETE equivalencias semánticas
             a CERO. Lo que queda son CINCO marcadores —`sincronía` y
             `ventaja` (definidos en D2 y D11), `progresión` y `puntuación`
             (eje `externo`), `contrato de UX` (definido en D18)— que sí son
             preguntas conceptuales: ¿este término se introduce por
             definición? ¿esta categoría el diseño la EXCLUYE en vez de
             derivarla?
Hipótesis:   Un sinónimo que hace falta suele delatar que el claim se apartó
             del vocabulario de su premisa; alinearlo es trabajo determinado y
             elimina la decisión en vez de delegarla.
Razón:       CONTINGENCY P5 — «continúa con la reescritura» (PO, 2026-07-23).
Impacto:     D1, D4, D5, D8, D23 reescritos y re-sellados; §2.9 con formas
             preferidas cortas y clasificación morfología/semántica
             automática. Detector: 6 → 5 flotantes, todos por marcador.
             check 41 reglas. Header v5.70.
             NO CIERRA: la raíz común (5 caracteres) es un criterio
             sintáctico, no un análisis morfológico real; puede aceptar una
             equivalencia semántica que comparta prefijo por casualidad. Su
             fallo es acotado —solo puede activar formas que YA comparten
             raíz— y queda declarado aquí, no escondido.
Ejecución:   CONFIRM
Costo:       C3
Pipeline:    P5
Ticket:      —
Modifica:    §3.0, §2.9
Libre:       Ratificación de los cinco marcadores → PO.
Referencias: §3.0, §2.9, §5.11, DL-086, DL-090
```

### DL-094

```
ID:          DL-094
Fecha:       2026-07-23
Domain:      DESIGN
Tipo:        PROPOSAL
Estado:      DECISION
Contexto:    El PO ratificó E11, pospuso P18 y pidió evaluar el coste de P20
             antes de decidir si es deuda técnica o responsabilidad suya.
Contenido:   E11 RATIFICADA — `escasez temporal` como generador de la decisión
             compartida— CON EL MATIZ DEL PO REGISTRADO LITERALMENTE: es el
             mejor candidato HALLADO, no el mejor. A11 es de dominio ABIERTO,
             luego Z6 impide concluir optimalidad; la ratificación fija el
             valor vigente sin cerrar el eje. Que el matiz quede en la celda y
             no en la prosa de un DL importa: es lo que impedirá que una
             lectura futura lo lea como «óptimo demostrado».
             D9 DESBLOQUEADO y reescrito para que su enunciado use el
             vocabulario de sus premisas (la lección de DL-093): «La escasez
             vuelve inevitable la decisión compartida: sin recursos para todo,
             qué salvar se elige en conjunto» — R-ELEC · C2′ + E11. La versión
             anterior decía «convierte la COOPERACIÓN en decisión compartida»,
             que colaba la valencia de E1 sin citarla: el mismo defecto que
             D3 y D23. Corregido al desbloquearlo en vez de heredarlo.
             P18 POSPUESTO por el PO; el predicado de cierre del plan reconoce
             `pospuesto` como estado terminal, luego sale del frente.
             CONSECUENCIA: claims bloqueados 1 → 0. Ningún claim del corpus
             queda esperando una decisión. VARIANTE 12 → 11.
Hipótesis:   Un valor ratificado con su matiz de apertura registrado en la
             forma no puede releerse como demostrado; el matiz sobrevive a
             quien lo escribió.
Razón:       CONTINGENCY P5 — ratificación del PO (2026-07-23).
Impacto:     E11 decidida; D9 desbloqueado, reescrito y re-sellado; P3 hecho;
             P18 pospuesto. Frente: P8, P10, P11, P12, P13, P14, P16, P19.
             P8 (§4 holístico) se vuelve accionable — sus dos dependencias,
             P3 y P5, están cerradas. Header v5.71.
Ejecución:   CONFIRM
Costo:       C2
Pipeline:    P5
Ticket:      —
Modifica:    §2.7, §3.0, §5.11
Libre:       —
Referencias: §2.7, §3.0, §5.11, DL-084, DL-093
```

<!-- Entradas rechazadas por SCRATCHPAD_INTAKE. No eliminar hasta revisión del PO. -->
