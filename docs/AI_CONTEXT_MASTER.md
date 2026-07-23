# AI_CONTEXT_MASTER — Mudanza Caótica

**Versión:** 5.58 | **Plataforma:** Roblox | **Plazo:** vertical slice completo al **2026-08-11** (reloj reiniciado el 2026-07-11 — DL-024)

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

**Alcance de la infraestructura (DL-039): todo el ciclo de vida, no el MVP.** La infraestructura, la arquitectura y la gobernanza de este documento se diseñan para el **ciclo de vida completo** del juego. El MVP (§3.8) y el vertical slice (§5.7) son el **primer hito** dentro de ese ciclo, no el horizonte de diseño. Consecuencia operativa: la regla de Completitud (§5.5) se aplica a **escala ciclo-de-vida** — al derivar los tickets de un hito se incluyen los de habilitación/infraestructura que el ciclo de vida implica (lobby, autoría y versionado de prefabs, input del cliente, configuración del place), aunque ningún ticket de feature del slice los nombre. Tratar el MVP como horizonte fue la causa raíz de un conjunto de tickets incompleto (auditoría 2026-07-15).

---

## 2. Fundamentos Transversales

### 2.1 Principios Congelados

Estos principios no se debaten. Toda idea que contradiga cualquiera de ellos —sea del nivel que sea— es rechazada sin excepción.

Se organizan por **altitud**. Un nivel superior **genera o restringe** a los inferiores: el orden es de dependencia lógica, no estético. La altitud no cambia la obligatoriedad — cambia la **naturaleza del conflicto** al auditar: chocar con un **axioma** (Nivel 0) es irreducible; chocar con una **elección de diseño** marcada ⚠ es, en principio, revisable por el PO sin tocar el núcleo.

#### Nivel 0 — Axiomas (núcleo irreducible)

Los cuatro principios de los que todo lo demás se deduce. Destilados y verificados por stress-test conceptual (DL-044): independientes por pares, primitivos, irreducibles entre sí.

| Axioma | Definición |
|---|---|
| **Interacción Humana como Contenido** (C1a) | Los jugadores son el contenido principal del juego; los sistemas existen solo para provocar su interacción. |
| **Interdependencia como Valor** (C1b) | El valor reside en la interdependencia entre jugadores, no en su mera coexistencia. Es **locativo** (dice dónde vive el valor, no que la interdependencia se maximice — su magnitud la gobiernan C3 y el juego en solitario como línea base) y **neutral de valencia** (no distingue cooperación de competencia; la valencia cooperativa de Mudanza es una elección de diseño, no parte del axioma). |
| **Ambigüedad Interpretable** (C2′) | La decisión compartida vive entre lo determinado (donde no hay decisión) y lo aleatorio (donde no hay criterio). |
| **Restricción Intrínseca** (C3) | Una restricción intrínseca a la naturaleza de la entidad se vive como oportunidad; impuesta por una regla externa, como cerradura. |

**Estado formal (F8, DL-057):** los cuatro axiomas son claims `R-POST` (§2.7) — **ratificados por el PO (2026-07-19, DL-055)**: único input humano afirmado del sistema.

#### Nivel 1 — Corolarios de diseño

Se deducen de los axiomas; frozen porque su fundamento lo es. ⚠ marca un **composite**: un axioma combinado con una elección de diseño revisable por el PO. La columna **Derivación** es normativa (F8, §2.7): regla citada del catálogo + premisas; lo que sigue a `—` es comentario no normativo.

| Principio | Definición | Derivación |
|---|---|---|
| Fricción Social | La mejor fricción ocurre entre jugadores, no entre jugador y sistema. | R-COMP · C1a + C1b — operador de dirección de la tensión |
| Dependencia Social ⚠ | Las tareas importantes deben beneficiarse significativamente de la cooperación. | R-ELEC · C1b + E1 |
| Entropía Social | Cada partida produce situaciones distintas sin modificar el objetivo principal. | R-COMP · C2′ + [Contexto Variable] |
| Contexto Variable ⚠ | Las condiciones cambian. El objetivo no. | R-ELEC · C2′ + E2 |
| Objetivo Estable ⚠ | Los jugadores siempre saben qué hacer. El objetivo nunca cambia. | R-ELEC · C2′ + E2 — ver Nota de legibilidad |
| Presión Situacional | El reto surge del contexto, no de aprender nuevas mecánicas. | R-COMP · C2′ + [Simplicidad Mecánica] |
| Complejidad Justificada | Toda complejidad debe aumentar la interacción social o las situaciones emergentes. | R-ESP · C1a — gate de complejidad |
| Expresión sobre Ventaja | La monetización futura debe derivar de expresión personal y creación, no de ventaja competitiva. | R-ESP · C1a — teorema anti-poder: la ventaja rutea el resultado por el sistema |
| Jugadores como Fuente de Contenido | El valor a largo plazo proviene de convertir a los jugadores en contenido para otros jugadores, mediante interacción o creación. | R-ESP · C1a — extensión a largo plazo (entidad Content) |

**Nota de legibilidad.** "Objetivo Estable" carga además "los jugadores siempre saben qué hacer". No requiere un 5º axioma: la legibilidad del *objetivo* se deduce de fijar el objetivo (elección) + Simplicidad Mecánica, y la legibilidad del *estado* es la interpretabilidad de C2′ elaborada como contrato de UX en §3.7. Se anota para confirmación del PO, no como gap sin resolver.

#### Nivel 2 — Método y arquitectura

Otro eje: no describen la experiencia del jugador sino **cómo se construye y se estructura el sistema**. Frozen, pero no se deducen de los axiomas de experiencia.

| Principio | Definición | Eje | Derivación |
|---|---|---|---|---|---|---|
| Simplicidad Mecánica | La profundidad surge de sistemas simples interactuando. | Método | R-POST |
| Compresión Social | El espacio debe aumentar la frecuencia con la que los jugadores interfieren entre sí. | Método (táctica espacial al servicio de C1b) | R-POST |
| Entidades Estables | Diseñar alrededor de entidades (Player, Object, Map, Content), no alrededor de nombres, archivos o features concretas. | Arquitectura | R-POST |
| Modelo de Tres Niveles | Toda decisión arquitectónica pertenece a uno de tres niveles: Entidades (qué existe), Sistemas (qué hace cosas), Persistencia (qué sobrevive entre sesiones). | Arquitectura | R-POST |

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
    Demand,       -- cargadores que el objeto exige (≤ 2, DL-047); su exceso
                  -- sobre la capacidad individual es lo que genera pooling (D6)
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

### 2.6 Disciplina de Modelado

Cómo se deriva el diseño desde los Principios Congelados (§2.1). Es transversal — la usan todos los dominios y agentes — y su incumplimiento es un **error de modelado**, auditable como cualquier contrato.

**Altitud.** Toda afirmación pertenece a un nivel: **axioma** (§2.1 Nivel 0) → **corolario** (se deduce) → **instanciación** (diseño concreto) → **feel/implementación** (parámetros). Un principio se representa en su **relación carrier-agnóstica**, nunca nombrando una entidad que lo transporta. Confundir el *carrier* (una entidad, un tamaño, un mapa) con lo *portado* (la relación) es error de nivel.

**Primacía derivada.** Antes de asignar el rol de una entidad, derivar —matriz principio × entidad— cuál la satisface *mejor*. No heredar el encuadre (del chat, de un ticket, de una versión previa).

**Determinismo.** Un modelado correcto es determinista: su conclusión se sigue de los axiomas y no depende del juicio del PO. Toda "duda de diseño" residual es **deuda de modelado** — se cierra derivando, no se delega.

**Roles.** El PO ratifica axiomas, decide parámetros libres genuinos, aporta hechos e intención de dominio, y da forma al método. El PO **no** adjudica conclusiones determinadas ni verifica la corrección del modelado — eso es competencia del agente que modela.

**Enforcement — derivaciones auto-certificantes.** Toda salida de modelado carga su cadena de entailment de modo que su corrección sea manifiesta por construcción. Antes de presentar un paso, el agente corre el gate:

1. **Procedencia** — ¿cada premisa deriva de un axioma, o se heredó?
2. **Nivel** — ¿relación carrier-agnóstica, o colapsada en entidad/instancia/feel?
3. **Entailment** — ¿se muestra que cada paso se sigue de axioma + pasos previos?
4. **Determinación** — ¿determinado (se presenta) o parámetro libre (se aísla)?
5. **Cierre** — ¿queda duda residual? Es deuda: se cierra.

**Criterio de validez:** el modelado es válido si cumple, objetiva y efectivamente, este enforcement.

### 2.7 Catálogo de Reglas de Inferencia (F8, DL-057)

La capa normativa del diseño se **autora directamente en forma** (DL-055): cada claim derivado cita una regla de este catálogo. Las reglas son **sintácticas** — su aplicabilidad se decide desde la estructura del claim (aridad y clase de las premisas), no por juicio. Un paso que no pueda expresarse con una regla del catálogo **se descompone hasta que pueda**. Añadir o cambiar una regla es un acto constitucional (validación del PO) y exige soporte en el validador (tripwire DL-052 + mutation test DL-056).

| Regla | Forma | Condición sintáctica |
|---|---|---|
| R-POST | postulado | 0 premisas. Se ratifica, no se deriva (axiomas N0; método/arquitectura N2). |
| R-ESP | especialización | exactamente 1 premisa (axioma o claim), sin elecciones; restringe su alcance. |
| R-COMP | composición | ≥ 2 premisas (axiomas o claims), sin elecciones. |
| R-ELEC | composición con elección | ≥ 2 premisas: ≥ 1 axioma/claim y ≥ 1 elección (E-n). La conclusión se marca ⚠ composite. |

**Registro de Ejes (Z2, DL-064).** Un eje es un **tipo**: un nombre y el **dominio** de valores que admite. Sin dominio enumerado, "el valor elegido pertenece a su eje" no es comprobable, y "¿es el mejor valor?" no es una pregunta respondible — de ahí que el registro de ejes preceda a cualquier juicio de optimalidad. Un eje con un solo valor no es un eje: es una consecuencia disfrazada de elección (`axis_domain_thin`).

La columna **Cierre** es la parte honesta: `cerrado` = el dominio agota el eje (típicamente ejes binarios o particiones exhaustivas); `abierto` = son los valores **considerados**, y añadir un candidato es siempre legítimo. La distinción decide qué puede afirmarse después: en un dominio cerrado, "no dominado" significa **óptimo**; en uno abierto, significa **óptimo entre lo considerado** — más débil, y decir lo contrario sería rigor inventado.

| ID | Eje | Dominio de valores | Cierre |
|---|---|---|---|
| A1 | Valencia del resultado | `cooperativa` · `competitiva` · `mixta` · `individual` | cerrado |
| A2 | Ancla interpretable | `el objetivo` · `las reglas` · `el rol` · `el espacio` | abierto |
| A3 | Tratamiento de la derrota | `ausente` · `declarada sin castigo` · `castigada` | cerrado |
| A4 | Situación ficcional | `mudanza` · `evacuación de incendio` · `naufragio` · `atraco` · `rescate` | abierto |
| A5 | Forma del objetivo | `maximización acumulativa` · `umbral fijo` · `lista específica` · `supervivencia` | abierto |
| A6 | Escala del grupo | `individual` · `pareja` · `grupo pequeño` · `grupo grande` | abierto |
| A7 | Naturaleza del primer release | `prototipo de validación` · `early access` · `producto shippable` | abierto |
| A8 | Horizonte de diseño | `el MVP` · `el ciclo de vida completo` | cerrado |
| A9 | Origen de la variación | `el sistema` · `los jugadores` · `ambos` | cerrado |
| A10 | Granularidad de la demanda | `binaria` · `graduada` | cerrado |
| A11 | Generador de la decisión compartida | `escasez temporal` · `información oculta` · `complejidad combinatoria` · `interdependencia de roles` | abierto |

**Elecciones constitucionales** — citables como premisas. **Una elección es una valencia**: un eje que los axiomas dejan abierto, y el **valor elegido** en él — *uno* de los valores del dominio de ese eje; elegir otro es revisión de la elección (⚠), no del núcleo. Forma obligatoria: un eje registrado por elección, un valor perteneciente a su dominio, sin ejes duplicados — verificado (`election_malformed`, `election_axis_dup`, `election_axis_unregistered`, `election_value_off_axis`).

**Registrar ≠ ratificar (DL-067).** Registrar el valor vigente de un eje es **describirlo**: deja constancia de que ahí hubo una elección, aunque nadie la haya examinado. Citarlo como premisa es **apoyarse** en él. Solo una elección con `Estado: decidida` — ratificada por el PO — es contenido garantizado y puede fundar un claim; una `sin ratificar` que aparezca como premisa es violación (`election_unratified_cited`). Sin esa separación, registrar una elección la volvería fundante de facto, y el barrido del corpus habría convertido trece hallazgos en trece axiomas de contrabando.

| ID | Eje | Valor elegido | Abierto por | Estado |
|---|---|---|---|---|---|
| E1 | A1 | `cooperativa` | C1b (neutral de valencia: el axioma no la fija) | decidida |
| E2 | A2 | `el objetivo` | C2′ (exige un ancla, no dice cuál) | decidida |
| E3 | A3 | `ausente` | Ningún axioma lo fija; C3 informa el valor (declararla/castigarla = restricción impuesta) | decidida |
| E4 | A4 | `mudanza` | Ningún axioma fija la ficción; debe admitir espacio compartido finito, objetos de demanda variable y escasez temporal | sin ratificar |
| E5 | A5 | `maximización acumulativa` | Ningún axioma fija la forma del objetivo; E2 exige que el objetivo sea el ancla, no dice cuál | sin ratificar |
| E6 | A6 | `grupo pequeño` | C1a exige varios humanos, no dice cuántos (el rango concreto 4–6 es empírico) | sin ratificar |
| E7 | A7 | `producto shippable` | Ningún axioma lo fija; postura de proyecto (DL-024) | sin ratificar |
| E8 | A8 | `el ciclo de vida completo` | Ningún axioma lo fija; postura de arquitectura (DL-039) | sin ratificar |
| E9 | A9 | `ambos` | C2′ exige variación interpretable, no dice de dónde procede | sin ratificar |
| E10 | A10 | `binaria` | C1b admite cualquier granularidad; DL-047 acota la demanda a ≤ 2 | sin ratificar |
| E11 | A11 | `escasez temporal` | C2′ exige ambigüedad interpretable, no dice qué la genera — hallada dentro de D1, no en prosa (DL-068) | sin ratificar |

**Sintaxis de derivación** (columna Derivación de §2.1): `R-XXX · P1 + P2 [— comentario no normativo]`. Premisas: ID de axioma (`C1a`, `C1b`, `C2′`, `C3`), ID de elección (`E1`, `E2`) o claim entre corchetes (`[Contexto Variable]`). **Nada deriva de prosa.**

### 2.8 Metaframework — Asignación Total (DL-059, DL-060)

El validador gobierna los artefactos; esta sección gobierna **el diseño del sistema mismo** — asignación de roles, orden de construcción, forma de las estructuras. No es una lista de lecciones: es **una ley con su procedimiento**, de la que las demás se derivan (verificadas por las reglas F8 como cualquier claim). Un metaframework enumerado desde fallos históricos cubriría solo lo ya ocurrido; derivado desde una ley, cubre el espacio por construcción.

**El procedimiento de tipado (total).** Para todo elemento X del sistema:

1. ¿X es **contenido de intención** — un postulado sin premisas, o la valencia de un eje abierto? → **PO**.
2. ¿X es **expresable como relación** dentro del sistema definido? → **máquina** (y M1 fija el cuándo: antes del trabajo que gobierna).
3. ¿X es **formalizable pero aún no formalizado**? → **transitorio declarado**: dueño + frontera/plazo, nunca implícito.
4. ¿Ninguna de las anteriores? → X es **empírico** (se mide: playtest) o su clase **se disuelve** (M7).

Si X se resiste a tipar, X no es atómico: **se descompone (M5) y se tipa por partes.** La exhaustividad del case-split más la descomposición a átomos garantizan totalidad: *no existe elemento sin titular*. El fallback humano no es parte del procedimiento — es su **falsación** (M10).

| ID | Ley | Revelada por | Derivación |
|---|---|---|---|---|---|
| MT0 | **Ley de Asignación Total**: todo elemento del sistema (contenido, relación, residuo, cambio) tiene exactamente un titular determinado por su naturaleza; nada queda asignado implícitamente. | DL-060 | R-POST |
| M1 | **El validador precede al trabajo**: el enforcement de una clase de error existe antes del trabajo que la produce; el validador nunca es un paso del programa que valida. | DL-053 | R-ESP · [MT0] — forma temporal: una clase sin enforcement está sin titular durante el gap |
| M2 | **El determinismo vive fuera de los agentes**: ninguna verificación descansa en agente alguno — incluidos el que modela y el AUDITOR: sus pasadas son advisory, nunca titulares de garantía. | DL-055, DL-060 | R-ESP · [MT0] — los agentes no son titulares válidos de verificación |
| M3 | **La superficie del PO es contenido, nunca relación**: solo se le someten axiomas ("¿es este el suelo?") y elecciones ("¿es este el valor que elijo?"). | DL-055, DL-059 | R-ESP · [MT0] — restricción del titular PO al caso 1 |
| M4 | **Lo normativo se autora en forma**: nada deriva de prosa; la única dirección es forma→prosa. | DL-055, DL-057 | R-ESP · [MT0] — la forma es precondición de asignabilidad a máquina |
| M5 | **Atomicidad**: cada unidad formal porta exactamente un argumento — una elección = un eje, un claim = una conclusión, un DL = una decisión (§5.4). | DL-058 | R-ESP · [MT0] — sin atomicidad el tipado no es unívoco |
| M6 | **Conjunto sobre elemento**: un cambio upstream re-deriva el conjunto derivado completo. | DL-047, DL-049 | R-ESP · [MT0] — propagación: lo no re-derivado queda sin titular |
| M7 | **Disolver sobre vigilar**: una relación frágil se elimina como clase antes que policiarse como instancias. | DL-050 | R-ESP · [MT0] — caso 4 del procedimiento |
| M8 | **Exhaustividad declarada**: todo lo formalizable se formaliza; el residuo restante lleva dueño explícito. | DL-055 | R-ESP · [MT0] — caso 3: residuo sin dueño = asignación implícita, prohibida |
| M9 | **Evolución conductual**: cambiar el sistema es acto etiquetado (tripwire) y toda regla nueva demuestra detectar (mutation). | DL-052, DL-056 | R-ESP · [MT0] — los cambios del sistema son elementos y tipan |
| M10 | **Falsación**: un catch del PO no es motor del sistema — es un **defecto del framework**: un elemento mal tipado o el procedimiento mal aplicado. Se trata como bug (¿cuál de las 4 preguntas se respondió mal?), se corrige el tipado y, si la clase es formalizable, baja a regla. Un catch sobre una zona registrada no es falsación — ahí el sistema no garantizaba. **La métrica del metaframework es que esta ley no se dispare fuera de zonas.** | DL-059, DL-060 | R-ESP · [MT0] — el catch revela una violación de asignación, no una ley nueva |

Las derivaciones de esta tabla pasan por las mismas reglas F8 que §2.1 (`claim_*`); su forma por `meta_law_malformed`.

**Perímetro binario de garantía (DL-060).** El sistema garantiza únicamente lo que emana de dos fuentes: **máquina** (reglas con mutación demostrada — auto-cobertura verificada: toda regla del validador tiene su caso de mutación, chequeado por `test.luau`, no por disciplina) y **contenido ratificado** (axiomas, elecciones, leyes — el PO). Los agentes no son titulares de garantía alguna: sus pasadas son advisory (hallazgos D-n como insumo, jamás como muro). La prosa no tiene autoridad (M4): un elemento normativo solo existe dentro de un slot de forma (claim, elección, regla+mutación, zona) y cada slot está verificado — mal-tipar un elemento lo hace fallar su slot o lo deja fuera del perímetro, sin autoridad. La única fuga posible es contenido que **cabe en la forma sin sostenerse semánticamente**; esas fugas no se asignan a nadie: se **registran** como zonas con camino, vencimiento y **ratificación del PO** — zona vencida = violación (`zone_expired`); el vencimiento fuerza la decisión (formalizar, disolver o re-acotar — re-acotar es del PO). La ratificación va en la forma, no en la prosa de un DL: una frontera de garantía que el sistema se concede a sí mismo no es una frontera (`zone_malformed` exige la celda `PO <fecha>`).

**Registro de Zonas No Verificadas** — dependencias sin garantía, explícitas y acotadas. El registro contiene lo *vigente*: una zona cerrada SALE de la tabla y su cierre queda en el DL que lo ejecuta (Z3 cerrada por DL-062 — el gluing ancla en claims D-n, no en prosa; Z2 cerrada por DL-064 — los ejes son tipos con dominio enumerado). Salir del registro exige haber cerrado, no haber caducado: `zone_expired` dispara antes.

| ID | Zona — sin garantía del sistema | Tipo MT0 | Camino de cierre | Vence | Ratificada | Abierta por |
|---|---|---|---|---|---|
| Z1 | Contenido semántico de claims: que la premisa citada sostenga la conclusión (la forma no lo carga) | relación → máquina (deuda) | Descomposición (M5) + catálogo más fino; contradicciones como relación explícita | 2026-08-11 | PO 2026-07-19 | DL-060 |
| Z4 | Obligación tras remodelar: el sello (DL-063) hace VISIBLE que un claim cambió, pero no genera deber de implementación — el grafo no guarda historia, luego no sabe qué sello había antes. §3.0 sigue exenta de obligación de ticket | relación → máquina (deuda) | Procedencia del sello: registrar qué DL cambió cada sello y derivar la obligación del cambio | 2026-08-11 | PO 2026-07-22 | DL-062 |
| Z5 | Realización semántica: el gluing verifica que el claim NOMBRE un módulo existente, no que el módulo HAGA lo que el claim dice. Evidencia: §4.13 declara `carryEfficiency(demand, carriers)`, el núcleo de reglas de carry sigue exponiendo la firma individual anterior, y el validador pasa en verde | relación → máquina (deuda) | Contratos de función de §4.13 verificados contra las firmas reales de `src/` | 2026-08-11 | PO 2026-07-22 | DL-066 |
| Z6 | Exhaustividad de dominio: que un eje marcado `cerrado` (§2.7) realmente agote sus valores es una afirmación semántica que nadie verifica. Un dominio cerrado de más convierte "no dominado" en "óptimo" sin derecho a ello | formalizable pendiente | Derivar el dominio desde el eje como partición demostrada, en vez de enumerarlo por inspección | 2026-08-11 | PO 2026-07-22 | DL-066 |

**Invariante y variante (DL-071).** Todo el aparato descrito hasta aquí verifica **safety**: que cada estado del corpus sea consistente. No dice nada de la **trayectoria** — si las zonas efectivamente cierran, si las clases de escape acaban teniendo regla, si la tasa de defectos por pasada baja. Los vencimientos eran un sustituto tosco: **un reloj no es una propiedad**; "vence el 11 de agosto" no informa si el sistema tiende a algo.

El nombre correcto lo teníamos importado sin usar: en Event-B, safety son **invariantes** y la convergencia es una **variante** — una medida bien fundada que decrece. La variante del corpus es `zonas abiertas + claims bloqueados + clases de escape sin regla`, y el runner la imprime. **Se mide, no se gobierna**: no existe un valor correcto, y descubrir una zona nueva la **sube** legítimamente — eso es progreso en conocimiento y retroceso en la medida, a la vez. Convertirla en umbral sería la lección del registro de escapes otra vez.

Lo que sí es decidible desde un solo estado es la **estructura** de la deuda: un claim bloqueado debe **nombrar a su bloqueador**, y el bloqueador debe existir — elección sin ratificar (`E-n`) o zona registrada (`Z-n`). Una deuda sin acreedor no se cobra (`blocked_claim_dangling`; era el caso real de D18, que decía "exige un postulado" sin ID alguno).

La columna **Tipo MT0** decide cómo se lee la zona. `relación → máquina (deuda)` significa que su terreno son relaciones y por tanto **el validador debería cubrirla**: es deuda, no frontera. `formalizable pendiente` es transitorio declarado. `contenido → PO` no se cierra formalizando: se ratifica. Sin ese tipo, Z1 se leyó como frontera aceptada durante días **siendo deuda** — la fila no decía de qué cubo era (DL-070).

**Registro de Escapes (DL-070)** — clases de error que el validador **no cazó**, con sus instancias. Sirve para que un defecto hallado a mano no se evapore en la prosa de un DL: así "premisa colada" apareció **siete veces** sin que nada sumara esas siete.

**Es una HEURÍSTICA, y por tanto DEUDA.** Agrupar instancias por clase lo hace un agente reconociendo un patrón — no hay nada mecánico en ello. En consecuencia **no gobierna nada**: no bloquea, no cuenta como violación, no es una regla y no tiene mutación. Es **historial**. Su valor entero es recordar; en el momento en que algo dependiera de él, una lista mantenida a mano estaría actuando como garantía, que es exactamente la dependencia de agente que estas páginas existen para eliminar. La deuda real no la salda el registro: la salda **mecanizar el entailment** (Z1).

| ID | Clase de error | Hallado en | Resolución |
|---|---|---|---|
| X1 | Premisa colada: la conclusión introduce un término ausente de toda premisa | D1 escasez · D2 contenido · D3 cooperación · D10 variabilidad · D21 identidad · D11 ámbito (DL-068/069); D4 acoplamiento hallado por `--provenance` (DL-075); D8 → faltaba C1a, corregido; D6 → depende de §2.3 (Object/demanda), localizado (DL-076) | zona: Z1 |
| X2 | Salto modal: conclusión prohibitiva desde premisas descriptivas ("no cuenta" → "está prohibido") | D8 · D13 · D19 (DL-068/069) | zona: Z1 |
| X3 | Contradicción entre claims vigentes | D12 "ningún objeto vale más" vs D6 "demanda que excede la capacidad" (DL-069) | zona: Z1 |
| X4 | Colisión de vocabulario: un término con dos sentidos normativos | `negativo/positivo` (acoplamiento) vs `cooperativa` (valencia) — D5/D6 vs E1 (DL-068). Instancia regresión-probada por `vocab_banned_term` (DL-074); la clase general (colisiones no declaradas) sigue en Z1 | zona: Z1 |
| X5 | Deriva declaración↔código: el módulo no realiza lo que su contrato declara | `carryEfficiency` declarada en §4.13, ausente en el núcleo de carry (DL-066) | zona: Z5 |
| X6 | Objeto registrable citable sin ratificar | E4–E10 habrían fundado claims por el mero acto de registrarlas (DL-067) | regla: election_unratified_cited |
| X7 | Premisa fantasma: cita a un ID que no existe | §3.3 citaba `C4`, que nunca existió (DL-061) | regla: unknown_premise |
| X9 | **Búsqueda incompleta presentada como frontera**: se declara que algo exige ratificación del PO o juicio irreducible sin haber agotado las premisas ya disponibles | D18/P4: se buscó un postulado en §2.1 N2, no se halló, y se enrutó al PO — pero deriva de `[D17] + [MT0]`, y §5.0 ya enunciaba el principio (DL-080); antes, "entailment no binarizable de una vez" era under-definition (DL-076) | zona: Z1 |
| X8 | **Instrumento cuyo resultado limpio es indistinguible de ceguera**: mide su propia resolución y se lee como si midiera el objeto | la variante valía 0 durante 32 versiones por falta de registro, no por salud (DL-072); el detector de procedencia daba 0 viendo el 22% del vocabulario (DL-078) | zona: Z1 |

**Historial de zonas cerradas (DL-072)** — una zona cerrada sale del registro vigente, y sin este historial sus eventos de apertura y cierre sobrevivirían solo en prosa. Con `Abierta por` en el registro y esta tabla, **descubrimiento y cierre se vuelven eventos distinguibles**, que es lo que la variante necesita para significar convergencia en vez de resolución del instrumento. Como el registro de escapes: es **memoria y no gobierna nada**.

| ID | Zona | Abierta por | Cerrada por |
|---|---|---|---|
| Z2 | Relación valor↔eje: que el Valor sea un valor del Eje declarado | DL-060 | DL-064 |
| Z3 | Realización del gluing: que la fila de §4.15 realice su concepto | DL-060 | DL-062 |

**El registro es MEMORIA, no COBERTURA (DL-070).** Un escape ausente significa que **nadie lo notó**, no que no exista: la ausencia de fila no prueba nada. Por su naturaleza, el registro **no puede crear dependencia alguna** — ninguna garantía del sistema se deriva de su estado, ni de que esté completo, ni de que todos sus escapes estén resueltos, y **ninguna regla puede consumirlo como evidencia**. El registro **empuja** (acumula presión sobre una clase que se repite) pero **jamás respalda**. Un mecanismo que dependiera de su completitud heredaría precisamente la dependencia de agente que el registro existe para hacer visible.

El **contenido** de esta sección es constitución: el PO ratifica MT0, el procedimiento, las zonas y los tipos ("¿acepto estas fronteras?") — contenido, no relación (M3 aplicada a sí misma). El **registro de escapes** no es contenido ni garantía: es un hecho observado, y su resolución apunta a lo que sí carga garantía (una regla, una zona) sin cargarla él.

### 2.9 Vocabulario Controlado (DL-074)

Los claims se construyen de **términos**. Un defecto puede vivir no en ningún claim sino en el vocabulario del que están hechos: un término con dos sentidos normativos, o dos términos que parecen del mismo eje sin serlo. Ese fue el escape **X4** — `acoplamiento negativo/positivo` (mecanismo) leía como `cooperativa/competitiva` (valencia), dos ejes independientes. Esta tabla fija el término preferido de cada predicado y **prohíbe las formas que colisionan**.

| Término preferido | Eje | Definición (comentario) | Formas prohibidas | Sinónimos | Definido en |
|---|---|---|---|---|---|
| acoplamiento rival | mecanismo | Contención: los cuerpos compiten por el mismo lugar (§3.3). | `acoplamiento negativo` | `contención` · `interfieren` · `interferencia` | D5 |
| acoplamiento acumulativo | mecanismo | Pooling: los esfuerzos se combinan (§3.3). | `acoplamiento positivo` | `pooling` | D6 |
| valencia | polaridad | Cómo acumula el resultado del acoplamiento — cooperativa/competitiva (eje A1). **Independiente del mecanismo**: un acoplamiento rival no implica valencia competitiva. | — | — | — |
| interacción | predicado | Lo que ocurre entre jugadores; el contenido del juego (C1a). | — | `interacción entre jugadores` | — |
| interdependencia | predicado | Que el resultado de un jugador dependa del de otro (C1b). | — | `acoplamiento` · `resultados acoplados` · `resultados de los jugadores` | — |
| decisión compartida | predicado | Elegir juntos bajo criterio, entre lo determinado y lo aleatorio (C2′). | — | `coordinación decisional` · `decisión conjunta` · `decidir juntos` · `coordinación` | — |
| ambigüedad | predicado | El margen interpretable donde vive la decisión (C2′). | — | `ambigüedad interpretable` · `interpretable` | — |
| restricción intrínseca | predicado | Límite que emana de la naturaleza de una entidad, no de una regla externa (C3). | — | `intrínseco` · `intrínseca` | — |
| contenido | predicado | Lo que el juego ofrece como experiencia; los jugadores lo son (C1a). | — | `contenido principal` | — |
| ventaja | predicado | Ruteo del resultado por el sistema en vez de por la interacción (anti-poder, §2.1). | — | `ventaja competitiva` · `ventaja de gameplay` | D11 |
| demanda | entidad | Cargadores que un objeto exige; propiedad de ObjectDefinition (§2.3). Su exceso sobre la capacidad individual genera pooling. | — | `capacidad de un individuo` · `demand` | — |

La columna **Sinónimos** existe para el detector de procedencia (abajo): las formas de superficie bajo las que un mismo término aparece. La regla `vocab_banned_term` escanea el texto normativo de §3 en busca de formas prohibidas — **mismo patrón que `impl_leak`**, un scan de superficie, sin etiquetar qué claim usa qué término (ese etiquetado sería una dependencia de agente, no una relación verificable).

**Procedencia de términos (`--provenance`, DL-075) — y el límite honesto de la binarización.** El detector responde, por cada claim derivado: ¿qué términos de la conclusión no aparecen en ninguna premisa? Es la **propiedad de subfórmula** — una derivación sana no introduce vocabulario de la nada. Mecaniza la heurística que más deuda ha cazado esta sesión (halló D4: `R-ESP · C3` concluía sobre *acoplamiento* sin citar a D3, corregido a `R-COMP · [D3] + C3`).

**Cobertura, o el detector se lee a sí mismo (DL-078).** El detector solo ve términos **modelados**; fuera de ellos es ciego, y un `0` suyo sería indistinguible de no mirar. Por eso el runner imprime siempre su **cobertura** (hoy 25% del vocabulario real de los claims) y `--provenance` emite la **cola de refinamiento**: los términos sin modelar, ordenados por uso. Esa cola no es ruido — es **qué definir a continuación**, y es el movimiento de **CEGAR** (la brecha entre lo abstraído y lo real dirige el refinamiento) y de **attribute exploration** en FCA (preguntar lo mínimo que completa la teoría). El lazo se probó cerrando su tope: definir `contenido` y `ventaja` expuso a D11 apoyándose en un término que su premisa no aportaba.

Pero es **detector, no reja**, y el porqué es el hallazgo central. Un término flotante es **o** una premisa colada (defecto) **o** una paráfrasis de un término de premisa cuya sinonimia no está modelada (`coordinación decisional` ≈ `decisión compartida` de C2′). Distinguirlos exige la capa de **sinonimia** — que es **contenido/ontología, no relación pura**. Por eso el detector no bloquea: **empuja**, como el registro de escapes.

Esto **no** vuelve el entailment "no binarizable" (corrección de metamodelado, DL-076). Un término flotante no es una frontera irreducible: es un **puntero a una definición faltante**, finito y localizado. Cada uno se **triajea por MT0** — reducible a primitivos presentes → extraer la definición (mecánico); irreducible a los axiomas/elecciones actuales → primitivo faltante, ratificación *específica* (el patrón `escasez → E11`, DL-068); empírico → medir. Ninguna rama es juicio vago; cada residuo es una **pregunta tipada**. Es **convergente** para corpus fijo (resolver un flag solo quita flags) y la terminación la guarda `claim_cycle` (una definición circular no puede fundar). El terminus honesto son los axiomas ratificados y la medición empírica — *definir más el universo*, que es acto del PO, no incapacidad de la máquina. **Re-tipar Z1 a la luz de esto es del PO** (§2.8): la fila queda intacta.

**Límites, declarados.** (1) Es **léxico**, no semántico: caza que dos claims usen palabras que colisionan, no que una premisa *sostenga* su conclusión — eso sigue siendo Z1 y pide una ontología, no un vocabulario. (2) La cobertura es **las formas declaradas**: una colisión no anotada no se caza (falso negativo posible, como toda memoria). Por eso la regla **regresión-prueba** la colisión ya hallada y **siembra** el espacio de términos que X1 necesita; **no cierra** la clase X4. Las formas prohibidas son **frases distintivas** (dos palabras), no palabras comunes, para que el scan no dé falsos positivos.

---

## 3. Design Architecture

### 3.0 Claims de Diseño (F8, DL-061)

**Esta tabla es la capa normativa de §3.** Los claims se autoran en forma (M4): cada uno cita una regla del catálogo §2.7 sobre premisas que resuelven a axiomas (`C1a`…), elecciones (`E1`…) o claims (`[D-n]`, `[Nombre]` de §2.1). Las subsecciones §3.1–§3.9 son **comentario no normativo**: explican y ejemplifican estos claims, no fundan nada. Verificado por las mismas reglas F8 que §2.1 (`claim_*`) más totalidad (`unclaimed_section`: toda subsección de §3 tiene ≥1 claim o marcador legítimo).

**Sello (DL-063).** Cada claim porta el hash de su propio enunciado. Lo sellado es el **enunciado**, no la fila: reubicar un claim no altera su sello, reescribirlo sí (`claim_seal_mismatch`). Re-sellar es el acto que declara una **remodelación** — sin él, cambiar un compromiso de diseño es indistinguible de un refactor cosmético. Al remodelar legítimamente, `lune run tools/derivation-graph/check.luau --seals` emite los sellos nuevos. El sello no dice que el contenido sea correcto (eso es Z1): dice que el cambio se hizo visible.

**Procedencia (DL-073).** Cada claim declara además **qué DL lo selló**, y esa declaración es **auto-consistente sin necesitar historia**: el DL debe existir y debe declarar `§3.0` en su `Modifica:`. Un DL que nunca tocó los claims no pudo sellarlos, luego una procedencia que miente se cae sola (`seal_unprovenanced`, `seal_provenance_inconsistent`). Con esto, remodelar deja de ser solo **visible** y pasa a ser **atribuible**, y el churn de claims por DL —cuánta normatividad movió cada decisión— se computa desde el corpus en vez de reconstruirse contra git.

| ID | Sección | Claim | Derivación | Sello | Sellado por |
|---|---|---|---|---|---|
| D1 | §3.1 | El reto del loop vive en la coordinación decisional, no en la ejecución individual. | R-COMP · C1b + C2′ | d3eabb | DL-068 |
| D2 | §3.2 | Un momento cuenta como contenido cuando acopla los resultados de dos o más jugadores y exige decidir bajo ambigüedad; la sincronía sin decisión no cuenta. | R-COMP · C1a + C1b + C2′ | 05adac | DL-069 |
| D3 | §3.3 | El entorno acopla los resultados de los jugadores; el acoplamiento no es una feature. | R-ESP · C1b | 265bc2 | DL-068 |
| D4 | §3.3 | Un acoplamiento solo cuenta si es intrínseco al elemento compartido. | R-COMP · [D3] + C3 | 677030 | DL-063 |
| D5 | §3.3 | El espacio acopla por contención: rival y pervasivo. | R-COMP · C1b + [Compresión Social] | 18c67b | DL-068 |
| D6 | §3.3 | El objeto acopla por pooling — acumulativo y puntuado — cuando su demanda excede la capacidad de un individuo. | R-COMP · [D3] + [D4] + [Object] | 95178f | DL-068 |
| D7 | §3.3 | La valencia de todo acoplamiento del loop es cooperativa. | R-ELEC · [D3] + E1 | dc5d75 | DL-063 |
| D8 | §3.3 | Una regla que impide iniciar la interacción está prohibida: impone como obligación lo que no emana del elemento. | R-COMP · [D23] + C1a | 93d133 | DL-068 |
| D9 | §3.3 | La escasez convierte la cooperación en decisión compartida: no basta ejecutar en sincronía. | — bloqueado: la escasez es E11, sin ratificar | 0a5ad8 | DL-068 |
| D10 | §3.4 | Cada partida produce situaciones distintas sin modificar el objetivo. | — bloqueado: la variabilidad es E9, sin ratificar | 4a98c3 | DL-069 |
| D11 | §3.5 | Ninguna progresión otorga ventaja de gameplay: la ventaja rutea el resultado por el sistema, no por la interacción. | R-ESP · C1a | dd790a | DL-069 |
| D12 | §3.5 | Ningún objeto otorga más puntuación que otro (Neutralidad de Objetos); pueden diferir en demanda. | R-COMP · C1b + [Object] — el valor reside en la interdependencia, no en la cosa | fea1c9 | DL-068 |
| D13 | §3.5 | Una mecánica que afecta solo al individuo no produce valor y no entra. | R-COMP · C1b + [Simplicidad Mecánica] | 7b1a32 | DL-069 |
| D14 | §3.5 | El juego no castiga el fallo. | R-ELEC · C3 + E3 | c62b2b | DL-063 |
| D15 | §3.5 | Las estadísticas históricas son infraestructura de producto, no progresión: lo prohibido es que otorguen ventaja. | R-ESP · [D11] | d7f44c | DL-063 |
| D16 | §3.6 | La monetización futura emana de identidad y creación, nunca de ventaja en gameplay. | R-ESP · [Expresión sobre Ventaja] | d6ac66 | DL-063 |
| D17 | §3.7 | El estado del juego es legible para el jugador: sin legibilidad la ambigüedad es ruido, no decisión. | R-ESP · C2′ | 85e3a8 | DL-063 |
| D18 | §3.7 | Los contratos de UX son condiciones binarias verificables, no juicios de gusto. | R-COMP · [D17] + [MT0] — un contrato de UX es relación, luego su titular es la máquina: binario o no es criterio | a01d00 | DL-068 |
| D19 | §3.7 | El Summary Screen narra lo ocurrido entre jugadores: su contenido es la interacción, no la puntuación. | R-ESP · C1a | ecff83 | DL-069 |
| D20 | §3.8 | Los criterios de éxito del MVP se miden; no se derivan. | — empírico → playtest | ac7a1f | DL-063 |
| D21 | §3.9 | La evolución del juego fortalece la interacción entre jugadores o la creación de contenido por jugadores. | R-ESP · [Jugadores como Fuente de Contenido] | 5a56fd | DL-069 |
| D22 | §3.2 | La calidad del loop es la frecuencia de momentos que cuentan como contenido; el umbral concreto es empírico. | R-COMP · C1a + [D2] | 8c9248 | DL-065 |
| D23 | §3.3 | Lo que no cuenta como acoplamiento no puede imponerse como obligación de cooperar. | R-ESP · [D4] | 592d28 | DL-068 |

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

**Esencia (D1).** El reto no vive en la ejecución individual sino en la **coordinación decisional**. Que el generador concreto de esa decisión sea la ESCASEZ (tiempo y manos finitos) es una elección de diseño —A11/E11, sin ratificar— no una consecuencia de los axiomas: C2′ exige ambigüedad interpretable pero no dice qué la produce. Hasta que se ratifique, D9 queda bloqueado y la escasez no funda nada (DL-068). El mecanismo por el que el entorno acopla se deriva en §3.3.

### 3.2 Densidad de Interacción (DI)

**Pregunta:** ¿Cada cuánto tiempo ocurre un momento que **cuente como contenido**?

**Qué cuenta (D2).** No todo lo que ocurre entre jugadores cuenta. Un momento se cuenta solo si **acopla los resultados** de dos o más jugadores (C1b) **y exige decidir bajo ambigüedad** (C2′). Saludarse no cuenta: no acopla nada. Ejecutar una acción en sincronía tampoco: no hay nada que decidir — es coordinación motora, no decisión compartida (D9). Antes de DL-065 este predicado vivía en la palabra "significativo", que nadie había definido: la métrica estaba bien contada sobre un criterio indefinido.

**Objetivo MVP:** un momento que cuente cada 10–15 segundos. La banda es **empírica** — se mide, no se deriva (D22).

Esta métrica es el criterio de avance entre semanas del Roadmap. No se avanza hasta que esté confirmada en playtest real.

*Límite conocido:* la frecuencia trata todos los momentos que califican como equivalentes. Si en playtest aparecen momentos que califican pero difieren mucho en peso, el predicado de D2 es demasiado grueso y hay que refinarlo — no compensarlo con un umbral distinto.

### 3.3 Dependencia Social y Cooperación

El **entorno acopla los resultados de los jugadores** (C1b — el valor reside en la interdependencia); el acoplamiento no es una feature. Que ese acoplamiento se resuelva en **cooperación** y no en competencia lo aporta E1, no C1b: el axioma es neutral de valencia y decirlo de otro modo adelantaría la elección (D3/D7, corregido en DL-068). Un acoplamiento cuenta cuando es **intrínseco** (C3): emana de la naturaleza de un elemento compartido, no de una regla externa.

Dos carriers generan el acoplamiento, con valencias distintas:

- **Espacio — contención (acoplamiento RIVAL):** finito y compartido; los cuerpos rivalizan por el mismo lugar. Es **pervasivo** — ocurre en cada movimiento (Compresión Social). Es la fricción de fondo que fuerza coordinar rutas y turnos.
- **Objeto — pooling (acoplamiento ACUMULATIVO):** un objeto cuya demanda excede la capacidad de un individuo obliga a combinar esfuerzo. Es **puntuado** — solo al enganchar ese objeto. El objeto además porta la apuesta (el objetivo es salvar objetos).

El **objetivo colectivo** (§1.2) fija la valencia cooperativa: como el resultado es de equipo, todo acoplamiento suma en vez de competir.

**Cooperación intrínseca, no impuesta (D4, D8).** La cooperación obligatoria es legítima *solo si es intrínseca*. Un objeto grande requiere dos porque su naturaleza lo exige — no porque una regla bloquee la interacción. Representación correcta: el líder **puede** engancharlo y moverlo con dificultad; el soporte lo vuelve normal. Representación prohibida: una regla que **impide iniciar** el carry sin soporte — se siente cerradura, no oportunidad.

**La escasez vuelve la cooperación una decisión (C2′).** Tiempo y manos finitos ⇒ no se puede salvar todo ⇒ el equipo prioriza qué salvar y con quién. La coordinación es **decisional**: no basta ejecutar en sincronía, hay que decidir juntos bajo escasez.

Las magnitudes —cuánto se mueve un large en solitario, cuánta eficiencia añade un segundo cargador en un medium, cuánta compresión impone el layout— son **parámetros libres de playtest**, no se fijan aquí.

### 3.4 Entropía Social

Cada partida debe producir situaciones distintas sin modificar el objetivo principal.

**Estado normativo (DL-069): D10 bloqueado.** Que el objetivo no cambie deriva de E2 (el ancla es el objetivo). Que las situaciones **varíen** no deriva de C2′: la ambigüedad interpretable puede ser idéntica partida tras partida sin dejar de ser ambigua. La variabilidad exige una fuente, y elegirla es E9 (`A9 — origen de la variación`), hoy **sin ratificar**. Hasta entonces la lista siguiente describe la intención, no funda nada.

La variabilidad emerge de:
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

El MVP valida el gameplay y establece la infraestructura base. Las actualizaciones futuras fortalecen la **interacción entre jugadores** o la **creación de contenido por jugadores** (D21).

Los tres dominios con que se venía describiendo la evolución —Gameplay, Identidad, Creación— **no derivan de una sola premisa**: `[Jugadores como Fuente de Contenido]` da interacción y creación; **identidad no se sigue de ahí** (DL-069). La identidad sigue siendo legítima como dominio de *monetización* por D16, que sí la deriva. Que los dominios de evolución sean exactamente esos tres es, si acaso, una **elección sin registrar** — y en DL-067 se excluyó del registro de ejes alegando que D21 la derivaba, lo cual era falso.

1. **Interacción** — nuevas mecánicas de cooperación, mapas, objetos
2. **Creación** — herramientas para que los jugadores creen contenido para otros

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
│   ├── CarrySupport.lua             (vigilancia de soporte large — GAM-006/007)
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
│   ├── Rules/                       -- núcleo funcional: decisión pura, sin efectos (§4.13, DL-037)
│   │   ├── CarryRules.lua           -- decideInteraction, carrySpeed, chooseSupport, evaluateSupport
│   │   ├── RoundRules.lua           -- buildClientComment, countLost
│   │   ├── StatRules.lua            -- computeStatDeltas
│   │   └── NPCRules.lua             -- orderedPatrol, nextStep (WLD-004)
│   └── Tests/                       -- specs de TestEZ: un [Módulo].spec.lua por
│                                       cada módulo con núcleo puro testeable en Lune
│
├── client/                          → StarterPlayer/StarterPlayerScripts/
│   ├── Main.client.lua              (LocalScript — entry point del cliente)
│   ├── ClientStateManager.lua       (única fuente de estado del juego en cliente)
│   ├── InteractionController.lua    (input → InteractObject:FireServer; expone getTarget — GAM-010)
│   ├── PromptController.lua         (prompt contextual "E — Recoger/Soltar" — UI-002, Fusion)
│   ├── HUDManager.lua               (HUD de ronda: timer + entregas — UI-001)
│   └── SummaryManager.lua           (pantalla de resumen de ronda — UI-003)
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
| ¿Cuál es el asset real en el servidor? | `ServerStorage/ObjectPrefabs` — resuelto por PrefabRegistry (§4.4, DL-031). Versionado como `assets/ObjectPrefabs.rbxmx`, mapeado por Rojo y **generado en código** por `lune/build-prefabs.luau` (DL-040, FND-003) |

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
|---|---|---|---|---|---|
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

**Contrato de payload (lección QA-001, §6.7).** La columna *Payload* de la tabla es un **contrato exacto que ambos lados cumplen**: el emisor manda esa forma, el receptor la parsea de esa forma. El payload de `InteractObject` es `{ instanceId }` (una tabla), **no** el string suelto — el receptor extrae `payload.instanceId`, y lo hace **defensivo** (tolera forma inesperada sin crashear). El bug #2 de QA-001 fue exactamente esto: `CarryManager` trataba `{ instanceId }` como si fuera el string → nunca recogía. Los specs no lo atrapan (prueban módulos aislados); lo atrapa la verificación de runtime (§6.7).

**Autoridad de estado:** ObjectManager es el único propietario de `ObjectInstance.State`. Ningún otro módulo modifica el estado directamente — todos solicitan el cambio a ObjectManager.

**Regla de RemoteEvents (DL-033):** el CI impone un gate duro (Nivel 1) contra el **cap actual = 7**. El límite existe por una restricción de *runtime* (superficie cliente-servidor: exploit + replicación), no de esfuerzo humano — por eso es un gate, no una guía. El *número* 7 es la heurística: **elevar el cap es una decisión Clase A** que se registra en el Decision Log y actualiza el valor del gate. No hay bypass ad-hoc "con aprobación del PO" — la aprobación ES la decisión que cambia el cap.

### 4.4 Módulos del Servidor y APIs

| Módulo | Nivel | Responsabilidad |
|---|---|---|
| Logger | Shared | Logging estructurado. Prerequisito de todo módulo. Niveles DEBUG/INFO/WARN/ERROR. Nivel mínimo desde GlobalConfig.LOG_LEVEL. |
| GameManager | Sistema | Punto de entrada del ciclo de vida. Gestiona estados Lobby y Summary. |
| RoundManager | Sistema | Gestiona la ronda activa. Propietario de RoundState y RoundSummary. |
| ObjectManager | Sistema | Spawn, estados y tracking de ObjectInstances. No mueve objetos. Delega la resolución ObjectId → asset en PrefabRegistry. |
| CarryManager | Sistema | Lógica de transporte. Líder ancla objeto; soporte debe mantenerse en rango. Dueño de los carry entries (§4.8). |
| CarrySupport | Sistema | Vigilancia del contrato de soporte large (GAM-006/007): búsqueda de soporte y loop por tick (task.wait, nunca por frame §4.12). Recibe los entries por inyección de CarryManager — no los posee. |
| TruckManager | Sistema | Zona de entrega, conteo de objetos salvados, datos para resumen. |
| PrefabRegistry | Sistema | Única capa que conoce `ServerStorage/ObjectPrefabs`. Resuelve `ObjectId → prefab` (o placeholder si falta). `validate()` audita el contrato al bootstrap (§4.4, DL-031). |
| NPCManager | Sistema | TweenService sobre nodos predefinidos. Sin PathfindingService. |
| EventManager | Sistema | Selecciona y ejecuta un evento aleatorio por ronda desde un pool. |
| MapBootstrap | Sistema | Arbitra el layout activo según `GlobalConfig.MAP_MODE` (DL-036): `"placeholder"` genera el edificio en código y descarta `Workspace/RealMap`; `"real"` usa el layout de Studio. |
| PlayerDataService | Persistencia | Wrapper delgado sobre ProfileStore (externo). Aplica MigrationService al cargar y expone el schema canónico de PlayerData. |
| ClientStateManager | Cliente | Única fuente de estado del juego en el cliente. Conecta todos los RemoteEvents. Los módulos de UI leen de él. |

**Contrato de carry cooperativo (§3.3, DL-047).** La eficiencia de transporte es **función del pooling**, no un penalizador individual: `CarryRules.carryEfficiency(demand, carriers) → factor` sube con los cargadores hasta la `demand` del objeto. Un large (demand 2) se mueve **pobre con el líder solo** y **normal con soporte** — el líder **siempre puede iniciar** (resistencia intrínseca, no una regla que bloquee, C3). Un objeto de demanda 1 va normal con un cargador — **sin penalización de velocidad**. Perder soporte **degrada** la eficiencia, no obliga a soltar. El conjunto de sistemas (ObjectManager, CarryManager, CarrySupport, CarryRules) y el schema `ObjectInstance` (§2.3, demanda ≤ 2) **sobreviven** — cambia su semántica, no su forma. *Parámetro libre (playtest):* si un segundo cargador sobre un objeto de demanda 1 añade eficiencia extra (pooling en medium).

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

**Trigger zones son volúmenes (lección QA-001, §6.7).** `TruckZone` es una zona `Touched`, no una calcomanía de suelo: el objeto cargado se sostiene a la **altura del torso** (~3 studs), así que una losa a ras de suelo **nunca lo toca**. La entrega se resuelve por el **personaje** del jugador que entra a la zona (sus pies sí la tocan) → se entrega lo que ese jugador carga (`CarryManager.getCarriedInstanceId`), y solo si está `being_carried`. Fue el bug #3 de QA-001. Regla: una zona `Touched` se detecta por la entidad que la toca de forma fiable, no asumiendo contacto de un objeto sostenido en alto.

**Contrato Layout → GameManager (GM-004):**
```
Tag "LobbySpawn"  — SpawnLocation del área de lobby, separada de la zona de
                    ronda. Los jugadores esperan aquí en fase Lobby.
Tag "RoundSpawn"  — Part marcador dentro del edificio. GameManager
                    teletransporta a los jugadores aquí en Lobby→Active, y de
                    vuelta a "LobbySpawn" al reiniciar el ciclo (fase Lobby).
```
En modo `"placeholder"` `MapBootstrap` los genera; el mapa real (WLD-001) debe proveerlos. Si faltan, GameManager avisa y no teletransporta (la ronda sigue jugable desde donde estén).

**Arbitración de mapa activo (DL-036):** `GlobalConfig.MAP_MODE` (`"placeholder"` | `"real"`) es la fuente única de qué layout usa el servidor — un solo valor, sin dos flags que puedan contradecirse. El mapa real de Studio vive bajo `Workspace/RealMap`. En modo `"placeholder"`, `MapBootstrap` destruye la copia *runtime* de `Workspace/RealMap` (seguro: el `.rbxlx` guardado no se toca; necesario porque `CollectionService:GetTagged` es agnóstico al parent y parkear no ocultaría los tags) y genera el edificio. En `"real"`, se usa `Workspace/RealMap` tal cual. Sustituye la detección por presencia de `TruckZone` de DL-028 (frágil con el mapa real incompleto).

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

**Invariante de dirección de dependencias (DL-035).** Un módulo solo requiere módulos de un nivel *inferior* al suyo — las dependencias apuntan hacia abajo. **No hay requires circulares ni ascendentes.** Cuando dos módulos necesitarían referenciarse mutuamente (p. ej. RoundManager ↔ CarryManager), la referencia hacia arriba se rompe con **inyección de dependencias** — RoundManager inyecta `recordStoryEvent` en `CarryManager.start(ctx)`, nunca con un `require` inverso.

**El fan-out NO es métrica de gobernanza (DL-035).** El número de dependencias salientes de un módulo *anti-correlaciona* con la arquitectura correcta: los orquestadores (RoundManager, GameManager) y el bootstrap tienen fan-out alto **por mandato de §4.8**. Un gate de fan-out penalizaría el diseño correcto — por eso el guard de acoplamiento es la *dirección* (arriba/abajo), no la *cantidad*. Hoy esta dirección la garantizan la disciplina de DI y el juicio del Auditor (Nivel 3); su promoción a gate determinista está registrada como candidato diferido (ver DL-035).

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

**Invariante — ownership de estado por evento (lección QA-001, §6.7).** Cada campo de `State` lo posee su **evento de datos**, y **solo** ese evento lo limpia. Un evento de *control* **no** limpia estado de *datos*: el orden de entrega entre RemoteEvents distintos **no está garantizado** por Roblox, así que los `ObjectStateChanged` del spawn pueden llegar *antes* que `RoundStarted`. `objects` se limpia en `RoundEnded` (evento terminal del ciclo del dato), **nunca en RoundStarted**. El bug #1 de QA-001 fue exactamente esto: `RoundStarted` borraba `objects` recién poblado → `InteractionController` no encontraba objetivo → la tecla E no hacía nada.

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

### 4.12 Contratos No Funcionales (DL-034)

Las secciones §4.1–§4.11 gobiernan el eje **estructural** ("quién puede qué", "quién es dueño de qué"). Esta sección añade el eje **no-funcional** ("qué complejidad", "qué escala", "quién limpia") — el complemento que faltaba. No duplica ningún contrato existente: opera sobre propiedades que ningún otro contrato expresa.

**Nota de honestidad:** a la escala de este juego (§1.2: 4–6 jugadores, ~15 objetos por ronda spawneados una vez cada 3 minutos), los *budgets de tiempo de pared* ("spawn < 2 ms") serían teatro — no gobiernan nada real. Lo que sí es arquitectónico son tres cosas: complejidad algorítmica, el sobre de escala de diseño, y el ownership de destrucción/cleanup.

**A. Invariantes de complejidad.** Una regresión de complejidad (p. ej. O(1)→O(n)) es un defecto de *estructura*, independiente de la escala actual — por eso es contrato, no optimización.

| Operación | Complejidad | Dónde |
|---|---|---|
| `ObjectManager.getObject` / `getObjectPart` / `setState` | O(1) | lookup por `InstanceId` en tabla hash |
| `ObjectManager.getFreeObjects` / `getAllObjects` | O(n) | enumeración — n = objetos de la ronda |
| `TruckManager` entrega (`Touched`) | O(1) por evento + O(altura) resolución de ancestría (acotada a 5) |
| `PrefabRegistry.resolve` | O(1) | cache `ObjectId → template` |
| `ClientStateManager` notificación | O(listeners) | por cambio de estado |

**Invariante — Sin loops por-objeto por-frame.** Ningún sistema corre un loop `Heartbeat`/`RenderStepped` que itere objetos cada frame (generaliza la prohibición de §4.6 sobre objetos large). El movimiento del objeto cargado usa un `WeldConstraint` (física del motor), no un loop. El único loop temporal es el timer de ronda de `RoundManager` (1 tick/segundo, O(1) por tick).

**B. Sobre de escala de diseño.** El diseño se dimensiona para:

```
Jugadores:  4–6        (§1.2)
Objetos:    ~15–30 por ronda   (GameplayConfig.OBJECT_COUNTS)
RemoteEvents: ≤ cap actual (§4.3)
```

Superar este sobre (p. ej. soportar 50 jugadores, o 500 objetos) **no es una optimización — es un cambio de arquitectura (Clase A)**. Una propuesta que asuma una escala fuera de este sobre se audita como rediseño, no como tweak.

**C. Ownership de destrucción y cleanup.** El §4.8 define quién *muta* estado; esto define quién lo *destruye y libera*:

| Recurso | Quién lo crea | Quién lo destruye/libera |
|---|---|---|
| Parts/Models de objetos (`top`) | `ObjectManager` (via `PrefabRegistry`) | `ObjectManager`: al entregar (setState "delivered") y en `reset()` |
| Contenedor `RoundObjects` | `ObjectManager.initialize` | `ObjectManager.reset` |
| Welds de carry | `CarryManager` (pickup) | `CarryManager`: `releaseEntry` / `forceRelease` / `stop` |
| Conexiones de RemoteEvent (servidor) | `CarryManager.start`, `TruckManager.start` | su propio `stop()` — desconectan lo que conectaron |
| Suscripciones y GUI (cliente) | módulos de UI en `init()` | `Janitor` en su `cleanup()` (§4.11) |
| Mapa placeholder | `MapBootstrap.ensure` | se retira con el layout real de WLD-001 |

**Invariante — Cada módulo libera lo que crea.** Un módulo que conecta una señal o instancia un recurso es responsable de liberarlo en su `stop()`/`reset()`/`cleanup()`. Ningún módulo libera recursos de otro (el paralelo de destrucción a la regla de ownership de estado, §4.8).

### 4.13 Núcleo Funcional / Shell Imperativo (DL-037)

La lógica de **decisión** de gameplay que puede ser pura vive en `src/shared/Rules/` — funciones sin efectos, sin acceso a `game`/`workspace`/`script`, deterministas y testeables en Lune headless (§4.6). Los módulos de servidor son el **shell imperativo**: consultan al núcleo puro *qué* hacer y ejecutan el *cómo* (mutar estado, disparar RemoteEvents, mover Parts).

| Módulo (núcleo puro) | Función pura | Shell que lo consume |
|---|---|---|
| `CarryRules` | `decideInteraction(facts, states) → "pickup"\|"drop"\|"ignore"` (un large es *pickup* por el líder aun sin soporte — §3.3); `carryEfficiency(demand, carriers) → factor` (eficiencia por pooling — reemplaza el `carrySpeed(prev, mult)` individual); `carrySpeed(prev, factor)` aplica el factor; `chooseSupport(candidates, rangeSq) → id?` | `CarryManager` (GAM-003/006) |
| `RoundRules` | `buildClientComment(saved, lost) → string` (3 umbrales, §3.5); `countLost(objects, deliveredState)` | `RoundManager` (UI-003) |
| `StatRules` | `computeStatDeltas(storyEvents) → { [playerId]: PlayerDelta }` | `GameManager` (GAM-004, §2.5) |
| `NPCRules` | `orderedPatrol(nodes) → {keys}`; `nextStep(current, count)` (circular) | `NPCManager` (WLD-004) |

**Invariante — la decisión que puede ser pura, lo es.** Toda lógica de gameplay expresable como función pura de datos (sin I/O ni estado del DataModel) vive en `Rules/` con su `.spec.lua` en `Tests/`. El shell no embebe decisiones de gameplay: delega en el núcleo y solo orquesta efectos. Así la lógica de gameplay se verifica en CI (Lune) sin un runtime de Roblox — hoy 62 specs.

**Nota de trazabilidad (DL-037).** Esta capa entró en el código con el PR #44 etiquetado `class:b`. Fue una **mis-clasificación**: introducir una capa arquitectónica es Clase A (§6.4). DL-037 la formaliza retroactivamente; es el caso que motiva reforzar el enforcement de trazabilidad Clase A (protocolo de versionado).

### 4.14 Renderizado de UI (Fusion, DL-042)

El framework de UI del proyecto es **Fusion** (`elttob/fusion`) — declarativo y reactivo (DL-042). La UI se expresa como función del estado, no como mutación imperativa de Instances.

**Contrato.** Los módulos de UI derivan su árbol de Instances de `Value`s de Fusion que reflejan el estado de `ClientStateManager` (§4.10, fuente única de estado del cliente). Un único `subscribe` a ClientStateManager actualiza esos `Value`s; Fusion re-renderiza solo lo que cambió. El módulo de UI **no** conecta RemoteEvents (INV-001) ni muta labels a mano.

**Lifecycle.** El árbol de UI se gestiona con los *scopes* de Fusion (creación + limpieza declarativas). Janitor sigue siendo válido para recursos no-UI (conexiones, señales — p. ej. `InteractionController`).

**Por qué Fusion (DL-042).** El modelo `UI = f(estado)` mapea 1:1 sobre la arquitectura ya existente (ClientStateManager como estado único) y elimina el glue imperativo que DL-025 (suscripción selectiva) mitigaba a mano. Es AI-óptimo (§5.9): una IA genera y modifica UI declarativa con menos error que `Instance.new` + updates manuales. Es ligero e idiomático de Roblox — se prefirió sobre React-lua (más ceremonia y peso) para la escala de §1.2.

**Estado de migración.** `HUDManager` (UI-001) y `SummaryManager` (UI-003) están **migrados a Fusion** (UI-004): derivan de `Value`s que un único `subscribe` a ClientStateManager actualiza, con la GUI declarativa vía `scope:New`; `SummaryManager` renderiza la lista de StoryEvents con `ForValues`. La dependencia `elttob/fusion@0.3.0` vive en `wally.toml`. Su lifecycle usa `scope:doCleanup()` (Janitor queda para lo no-UI, p. ej. `InteractionController`). Pendiente solo la verificación en Studio (UI-004/QA-001). Toda UI **nueva** nace en Fusion.

---

### 4.15 Gluing §3↔§4 y Registro de Módulos (DL-054)

El **gluing** (Event-B) hace explícita la correspondencia entre el diseño y su realización técnica. Desde DL-062 su ancla izquierda es el **claim** `D-n` de §3.0 — no la prosa de una subsección (cierre de la zona Z3): cada claim normativo declara **cómo se realiza**, con mecanismos de sistema o con un marcador legítimo (`empírico → playtest` para lo que se mide, `normativo` para lo que restringe sin realizarse en código). El validador exige totalidad (`unglued_claim`: todo claim de §3.0 tiene realización) y existencia de lo nombrado (`glue_dangling`). Un claim sin realización es una **obligación pendiente**, no una omisión silenciosa. Los nombres en backticks se verifican contra el registro y `src/`.

| Claim | Enunciado (comentario) | Realización |
|---|---|---|
| D1 | Coordinación decisional bajo escasez | `GameManager` (Lobby/Summary) + `RoundManager` (ronda activa) — §4.4 |
| D2 | Qué cuenta como contenido | — normativo → criterio de conteo del playtest: un momento se cuenta solo si acopla resultados y exige decidir (§3.2, QA-003) |
| D3 | El entorno acopla resultados | `MapBootstrap` + `CarryManager` + `RoundManager` — el acoplamiento emerge de sus interacciones |
| D4 | Acoplamiento intrínseco | `CarryRules` carryEfficiency (resistencia física, no gate — §4.13, DL-047) |
| D5 | Contención espacial (negativa, pervasiva) | layout + física del engine: `MapBootstrap` (placeholder, DL-036) / layout real (WLD-003) |
| D6 | Pooling por objeto (positivo, puntuado) | `CarryRules` carryEfficiency + `CarryManager` / `CarrySupport` |
| D7 | Valencia cooperativa | `TruckManager` (conteo de equipo) + `RoundManager` (RoundSummary único) |
| D8 | Obligación intrínseca, nunca gate | `CarryManager` (el líder siempre puede iniciar — §4.4, DL-047) |
| D23 | Lo no-acoplado no obliga | — normativo → Test de Diseño (§2.2) + auditoría DESIGN |
| D9 | Escasez → decisión compartida | timer de `RoundManager` (1 tick/s, §4.12) + `ObjectManager` (spawn disperso) |
| D10 | Situaciones distintas (bloqueado por E9) | `EventManager` + `NPCManager` + spawn aleatorio de `ObjectManager` |
| D11 | Sin ventaja de gameplay | — normativo → Test de Diseño (§2.2) + auditoría DESIGN |
| D12 | Neutralidad de objetos | `TruckManager` (conteo uniforme) + definiciones de objeto sin campo de valor (§2.3) |
| D13 | Lo solo-individual no entra | — normativo → Test de Diseño (§2.2) + auditoría DESIGN |
| D14 | Sin castigo por fallo | `RoundRules` buildClientComment (3 umbrales sin derrota — §4.13) |
| D15 | Estadísticas sin ventaja | `StatRules` + `PlayerDataService` (Stats es infraestructura, §2.5) |
| D16 | Monetización de identidad/creación | — normativo (futuro, entidad Content §2.3) |
| D17 | Estado legible | `ClientStateManager` (§4.10) + `HUDManager` / `PromptController` |
| D18 | Contratos UX binarios | — normativo → contratos de §3.7 + auditoría UX |
| D19 | Summary narra, no informa | `RoundRules` + `SummaryManager` + StoryEvents (§4.4) |
| D20 | Criterios de éxito | — empírico → playtest (QA-001, P6 §6.7) |
| D21 | Evolución: interacción o creación | — normativo (roadmap §5.7) |
| D22 | Calidad del loop = frecuencia | — empírico → playtest (métrica de avance, §3.2; medida con el criterio de D2) |

**Registro adicional de módulos** — declarados en prosa (§4.1, §4.3, §4.7, §4.10, §4.14) y no en las tablas §4.4/§4.13: `Networking`, `MigrationService`, `ProfileStoreConfig`, `GlobalConfig`, `RoundConfig`, `GameplayConfig`, `Events`, `ObjectState`, `RoundPhase`, `HUDManager`, `SummaryManager`, `InteractionController`, `PromptController`. (⚠ `ProfileStoreConfig` existe en `src/server/Persistence/` pero §4.7 declara solo PlayerDataService y MigrationService como módulos propios — prosa desactualizada; armonizar en la re-derivación holística de §4.)

**Exenciones del registro:** `src/shared/Tests/` (specs — verifican, no son sistemas), `src/shared/Definitions/` (contenido de entidades — §2.4 prohíbe que el master se acople a nombres concretos de objetos), `Main.*` e `init` (infraestructura de arranque).

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
| §4.3 | RemoteEvents ≤ cap actual (7) en `Networking.lua` — elevar el cap es Clase A (DL-033) | conteo |
| §4.6 Lune | Globals Roblox no en scope de módulo | `lune run lune/check-compatibility.luau` ⚠ heurística, no AST |
| — | Specs de comportamiento (Persistence, ObjectManager) | `lune run lune/run-specs.luau` |
| — | `print`/`warn` fuera de `Logger.lua` | grep (`contract-logger-usage`) — Selene no puede prohibir globals específicos |
| — | Formato de código uniforme | StyLua |
| — | Convención de commits | commitlint (Lefthook commit-msg) |
| §5.10 | PR `class:a` referencia un `DL-xxx` y toca `docs/` (trazabilidad, DL-041) | github-script en CI (labels + cuerpo/commits + archivos del PR) — solo CI, requiere contexto de PR |
| §5.4/§5.5 | Grafo de derivación: integridad (`dangling`), procedencia (`orphan`, DL-032), frescura (`stale` — con diferimientos autorizados y acotados por fecha en `deferrals.txt`; vencido = violación), cobertura (`uncovered`: DL que modifica §3/§4 sin declarar derivación) altitud (`level_skip`: implementación sin fuente §3/§4/DL; `domain_mismatch`: Domain del DL incoherente con lo que Modifica; `impl_leak`: módulos de `src/` nombrados en §1–§3) determinación (`undeclared_free`: DL que modifica el master sin declarar `Libre:` — el juicio determinado-vs-libre es un acto explícito), código (`module_undeclared`: módulo en `src/` no declarado en §4) y gluing claim→§4 (`unglued_claim`: claim de §3.0 sin realización en §4.15; `glue_dangling`: claim de módulo inexistente) — DL-048/049/050/051/053/054/062. `uncovered` exime §3: §3.1–§3.9 no son normativas (derivado de DL-061) y §3.0 queda acotada por la zona Z4 — DL-062 | `lune run tools/derivation-graph/check.luau` (modelo: `tools/derivation-graph/derivation.dl`) |
| — | Ningún artefacto pinnea versión del master (`AI_CONTEXT_MASTER vN.N` prohibido — se lee siempre vigente; entradas históricas del log exentas) — DL-050 | mismo runner (escaneo de `docs/`) |
| — | Meta-frontera: un PR que toca rutas de enforcement (`tools/derivation-graph/`, `.github/workflows/`, `lefthook.yml`) lleva la etiqueta `enforcement-change` — evolucionar el sistema formal es explícito, nunca silencioso (DL-052) | github-script en CI — solo CI, requiere contexto de PR |
| — | El validador demuestra su detección: cada regla enciende ante una violación mínima de su clase inyectada sobre copia del corpus real, más control en verde (DL-056) | `lune run tools/derivation-graph/test.luau` |
| §2.1/§2.7 | Claims tipados (F8): toda entrada de §2.1 porta derivación formal — regla citada del catálogo §2.7 con condición sintáctica válida (`claim_bad_derivation`, `unknown_rule`, `unknown_premise`, `rule_arity`, `claim_cycle`) — DL-057. Elecciones como valencias: un eje atómico + un valor, sin duplicados (`election_malformed`, `election_axis_dup`, `election_compound`) — DL-058. Ejes como tipos con dominio enumerado (A1–A10): eje bien formado con Cierre cerrado|abierto, dominio ≥ 2 valores, elección sobre eje registrado y valor perteneciente a su dominio (`axis_malformed`, `axis_domain_thin`, `election_axis_unregistered`, `election_value_off_axis`) — precondición del juicio de optimalidad, DL-064. Registrar ≠ ratificar: una elección `sin ratificar` no puede fundar un claim (`election_unratified_cited`) — DL-067. Claims de diseño §3.0: toda subsección de §3 porta claim normativo o marcador (`unclaimed_section`) — DL-061. Sello del enunciado: cada claim porta el hash de su propio enunciado; reescribirlo sin re-sellar = violación (`claim_seal_mismatch`) — remodelar deja de ser indistinguible de reubicar; `--seals` recalcula al remodelar legítimamente — DL-063 | mismo runner (`check.luau`) |
| §2.8 | Metaframework: forma de las leyes M-n verificada (`meta_law_malformed`) y sus derivaciones por las reglas F8 — DL-059/060. Zonas no verificadas explícitas, acotadas, **tipadas** y **ratificadas** (`zone_malformed` exige descripción, Tipo MT0, camino, vencimiento y celda `PO <fecha>` — DL-062/070; `zone_expired`: zona vencida = violación). El registro de escapes (§2.8) **no aparece aquí**: es heurística e historial, no contrato — no bloquea ni cuenta como violación (DL-070). Auto-cobertura M9: toda regla del validador tiene su mutación (verificado por `test.luau` contra el reporte real) — DL-060 | mismo runner + `test.luau` |

**Nivel 2 — Contratos de mantenibilidad (CI)**

| Contrato | Umbral | Mecanismo |
|---|---|---|
| Tamaño de módulo | Ningún archivo en `src/` > 400 líneas (DL-033) | `wc -l` |
| Separación de capas | `src/server/` no requiere `src/client/` | grep |
| Cobertura mínima | Módulos de Persistence tienen spec | existencia de archivo |

**Nombres de los required checks (DL-033).** El nombre de un status check *requerido* embebe su umbral **si y solo si** cambiar ese umbral es una decisión Clase A. Los *caps* de Nivel 1 (p. ej. `Contract: RemoteEvents ≤ 7 (§4.3)`) conservan el número: elevarlos es Clase A, y el renombre + re-sync manual del ruleset que ello exige es un freno deliberado, no fricción. Los *backstops* de Nivel 2 (p. ej. `Contract: Module size backstop (DL-033)`) usan nombres **sin umbral** y guardan el número solo en el script: su recalibración es Clase B y no debe romper el ruleset. Razón: renombrar un required check obliga a editar el ruleset a mano (dos sitios que no se actualizan atómicamente → bloqueo transitorio del merge); esta regla confina esas ediciones a los cambios que de verdad lo ameritan.

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

**Superficie exacta del PO (DL-055).** Con el grafo de derivación completo (Nivel 1), la **forma** de toda derivación es mecánica. La superficie del PO son exactamente **dos actos**:

1. **Validar los axiomas** — la constitución del sistema: §2.1 Nivel 0, las entidades (§2.3) y el catálogo de reglas de inferencia (F8). Validar la fundación **es** validar la adecuación — no existe un acto separado de "¿modela bien el problema?": la fundación es el modelo.
2. **Elegir** — los parámetros de intención (`Libre:` → PO) y las meta-elecciones sobre el sistema (evolucionar el enforcement — visible por el tripwire DL-052, decidido por el PO). Los parámetros empíricos (`Libre:` → playtest) no se eligen ni se auditan: se miden.

*Lo que NO es del PO:*
- **La coherencia** — trece reglas deterministas (Nivel 1). Un error de esa clase es una fila de salida, no un hallazgo humano.
- **El entailment** (¿la conclusión *se sigue*?) — su terreno son relaciones dentro del sistema definido: **binariza**. La barrera nunca fue el chequeo (decidible) sino la **conversión semántica** prosa→forma — y esa conversión **no se asigna a nadie: se elimina** (corrección del PO: el determinismo no puede caer en agentes; un ápice de dependencia lo daña — y una f(x) determinista prosa→forma no existe; cualquier cosa que lo pretenda es dependencia de agente disfrazada). La capa normativa se **autora directamente en la forma** (F8): claims tipados — id, nivel, premisas, regla de inferencia citada del catálogo. La prosa es comentario **no normativo** — nada deriva de prosa; la única dirección permitida es forma→prosa (mecánica, generable); prosa→forma no existe en la cadena normativa. Las reglas del catálogo son **sintácticas** (aplicabilidad decidible desde la estructura del claim); el paso que no pueda expresarse sintácticamente se descompone hasta que pueda. El agente autora claims como un programador autora código: visible en el artefacto y verificado íntegramente por el validador — la verificación no descansa en ningún agente. Adoptar la forma no es una elección: se deduce de la exhaustividad intra-sistema (lo formalizable se formaliza) y DL-053 fija el cuándo (antes del trabajo que gobierna). Mientras F8 se construye, el interinato es del agente que modela (auto-certificación §2.6, cadena exhibida) + la pasada adversarial del AUDITOR — transicional, acotado a la existencia de F8, y **nunca del PO**; su catch es red de seguridad voluntaria, no mecanismo.

**Concentración del riesgo.** El validador no redujo la responsabilidad del PO — la **concentró en la fundación**. Una derivación impecable desde un axioma equivocado — o un catálogo de inferencia mal ratificado — pasa todas las reglas en verde: el sistema propaga el error con consistencia perfecta y sin señal. El modo de fallo peligroso no es la incoherencia — es lo **correcto en forma y errado en fundamento**.

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
|---|---|---|---|---|---|
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
     Domain BOTH   → TECH primero (Issue automático; auditoría MANUAL — §6.3).
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
|---|---|---|---|---|---|
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

**Este roadmap de 4 semanas es el PRIMER hito (el vertical slice), no el plan completo del juego (DL-039).** Más allá del slice, el ciclo de vida incluye —como horizonte, sin fechas aún— lobby y matchmaking reales, pipeline de contenido (más mapas/objetos/eventos), progresión no-competitiva (§3.5) y live-ops. La infraestructura del slice ya debe soportar esa evolución (§1.3). Los tickets de **habilitación** que el slice necesita pero ningún feature nombraba se derivan explícitamente: `GAM-010` (input del cliente), `WLD-008` (autoría de prefabs), `FND-003` (versionado de prefabs via Rojo), `FND-004` (config del place), `GM-004` (flujo de lobby).

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
| `módulo < 300 → 400 líneas` | Proxy de "responsabilidad única" calibrado al humano que *hojea*. Una IA lee el módulo completo. | **Recalibrado a 400 (DL-033):** límite de coste-revisor, no de coste-escritor. El guard real contra god-modules es la responsabilidad única (juicio del Auditor, Nivel 3); el conteo de líneas es un backstop coarse. |
| `RemoteEvents ≤ 7` | La *restricción* (minimizar superficie cliente-servidor) es de **runtime** — superficie de exploit + coste de replicación, independiente de quién codea. El *número 7* es la heurística. | **Resuelto (DL-033):** gate duro contra el cap actual (7); elevar el cap es Clase A. Sin bypass ad-hoc. |

**Estado de la reexaminación.** Los dos umbrales nombrados arriba quedaron resueltos en **DL-033**. Todo umbral futuro se justifica contra el coste correcto (coste-IA + revisor + runtime) en el momento de introducirse — el marco de esta sección aplica de oficio, sin necesidad de una reexaminación aparte.

**Alcance.** Esta sección NO autoriza relajar umbrales de forma genérica — obliga a *justificar* cada uno contra el coste correcto. Un umbral sin justificación de coste documentada es deuda de gobernanza.

### 5.10 Protocolo de Versionado (DL-041)

El flujo de gobernanza (§5.5) dice *qué* se cambia y *por qué*; este protocolo dice *cómo* se versiona en Git. Su ausencia produjo desorden real (PRs apilados, rebases manuales, deadlocks de ruleset). Es de cumplimiento obligatorio.

**Regla 1 — Una unidad, una rama, un PR.** Un cambio coherente = una rama desde `main` **actualizado** = un PR. **No se apilan PRs** (una rama sobre otra rama no mergeada). Si un cambio B depende de A no mergeado: o esperas a que A entre a `main` y ramificas B desde ahí, o incluyes A y B en el mismo PR si son una sola unidad coherente.

**Regla 2 — Rebase, no merge, antes de integrar.** Antes de pedir merge, la rama se **rebasa** sobre `main` (nunca `git merge main` dentro de la rama). Historia lineal (el ruleset la exige). Merge = **squash**; se borra la rama tras mergear.

**Regla 3 — master↔código en el mismo PR (trazabilidad).** Un PR **Clase A** formaliza una decisión: en el mismo PR referencia su `DL-xxx` (cuerpo o commit) y actualiza la documentación (`docs/`: §4/DL/tickets). Nunca se mergea código Clase A dejando el master desincronizado — ese fue el fallo de #44 (capa nueva como `class:b` sin DL ni §4; ver DL-037). Enforcement: gate `Contract: class:a traceability (DL-041)`.

**Regla 4 — Nombres de checks estables.** Al añadir un required check, su nombre no embebe umbrales (§5.0, DL-033): identidad estable ante recalibraciones, para no romper el ruleset.

**Regla 5 — Sincronía del ruleset.** Añadir/renombrar un required check exige actualizar el ruleset de `main` (acción del PO — es un ajuste de protección de rama). El PR que introduce el check documenta el nombre exacto a añadir.

**Gate automático (Nivel 1).** `Contract: class:a traceability (DL-041)`: si el PR es `class:a`, debe (a) referenciar un `DL-xxx` y (b) tocar `docs/`; si no, falla. Si el cambio no es arquitectónico, se reclasifica a `class:b`.

**Candidato diferido.** Un gate que detecte "el PR añade un directorio/capa nuevo bajo `src/` pero está etiquetado `class:b`" cazaría el caso #44 en origen. Es heurístico (falsos positivos en adiciones `class:b` legítimas) — se registra como candidato a gate futuro, no se implementa aún (mismo criterio que DL-035).

### 5.11 Plan del Programa de Modelado (DL-079)

**Por qué existe.** DL-044 declaró su propagación pendiente en el campo `Impacto:` — prosa — y nunca se ejecutó; el orden se perdió sin que nada chillara y el programa derivó turno a turno. Un plan que vive en prosa (o en la cabeza de un agente) no es un plan: es una intención. Aquí el orden es un **artefacto con dependencias declaradas**, y **el frente accionable se computa**, no se recuerda.

| ID | Trabajo | Depende de | Salda | Estado |
|---|---|---|---|---|
| P1 | Recorrer la cola de refinamiento del vocabulario (§2.9) hasta que deje de exponer deuda | — | Z1 · X1 | en curso |
| P2 | Disolver o confirmar E4–E11: aplicar el criterio de optimalidad buscando el predicado discriminante | P1 | DL-064 | pendiente |
| P3 | Desbloquear D9 y D10 (exige ratificar E11/E9, si sobreviven a P2) | P2 | D9 · D10 | pendiente |
| P4 | ~~Desbloquear D18: postulado N2 de verificabilidad~~ — no existía tal bloqueo: D18 deriva de [D17] + [MT0] | — | — | disuelto (DL-080) |
| P5 | Derivar las entidades de §2.3 desde los axiomas (deuda de ontología; hoy son primitivos citables pero no derivados) | P1 | DL-077 | pendiente |
| P6 | Cerrar Z5: contratos de función de §4.13 verificados contra las firmas reales de `src/` | — | Z5 | pendiente |
| P7 | Saldar X5: alinear el núcleo de carry con el contrato `carryEfficiency` | P6 | X5 | pendiente |
| P8 | Derivar el conjunto de sistemas de §4 en una pasada holística | P3 · P5 | DL-053 | pendiente |
| P9 | Re-anclar TICKETS a claims D-n | P8 | DL-061 | pendiente |
| P10 | QA-001: playtest que mide lo empírico (D20, D22) | P7 | D20 | pendiente |
| P11 | Mecanizar la detección de X9: para un claim bloqueado, buscar si alguna combinación de premisas existentes cubriría su conclusión | P1 | X9 | pendiente |
| P12 | Mecanizar el triaje MT0 sobre términos flotantes (extraer definición · primitivo faltante · empírico) — el paso que aún hace el agente a mano en la metaherramienta | P1 | X1 · X2 | pendiente |
| P13 | Cerrar la mitad de obligación de Z4: el delta del enunciado, no solo su hash y su autor | — | Z4 | pendiente |
| P14 | Cerrar Z6: derivar el dominio de cada eje como partición demostrada, no enumerada por inspección | P2 | Z6 | pendiente |
| P15 | Dar regla a las clases de escape que no la tienen | P12 | X3 · X4 · X8 | pendiente |
| P16 | Disolver §2.2 (Test Oficial de Diseño) en claims: hoy sus cinco criterios fundan desde prosa, contra M4 | P1 | DL-061 | pendiente |
| P17 | Reconciliar los 16 diferimientos de `deferrals.txt` — vencen 2026-08-11 y romperán el build en bloque | P9 | DL-050 | pendiente |
| P18 | Ratificar el re-tipado de Z1 (se reveló como dos capas) y si X9 merece zona propia | — | Z1 | pendiente-PO |

La columna **Salda** ancla cada paso a la deuda declarada que resuelve. `plan_uncovered_debt` verifica lo inverso y es la validación de objetividad que el plan sí admite: **toda zona abierta, toda clase de escape sin regla y todo claim bloqueado debe aparecer en algún paso**. Lo que el plan no puede probar sigue siendo su completitud frente a deuda **no declarada** — eso es X8 y no se cierra con más filas.

`plan_dangling` verifica que toda dependencia exista. El runner imprime el **frente accionable** — los pasos cuyas dependencias están todas `hecho`.

**Límite, por disciplina X8.** Este plan es **memoria de trabajo declarado**, no prueba de cobertura: un `plan_dangling: 0` dice que las dependencias resuelven, **no** que el conjunto de trabajo esté completo. Un plan limpio y un plan ciego se ven igual. Por eso no gobierna nada: ordena lo declarado y se lee.

---

## 6. Operational Architecture

### 6.1 File Taxonomy

| Tipo | Descripción | Riesgo principal | Ejemplos |
|---|---|---|---|---|---|
| A — Humano semipuro | Estructura creada por IA. Contenido llenado por humano sin filtro. Subagent solo filtra y formaliza via intake. Orchestrator audita solo estructura. | Contenido sin filtrar ingresa al ciclo sin pasar por intake | SCRATCHPAD.md |
| B — Insumo primario de Orchestrator | Ciclo de vida largo. Se modifica solo con aprobación del PO. | Modificación sin auditoría previa | Prompts de auditores, AI_CONTEXT_MASTER (parcial) |
| C — Comprensión humana | Para lectura humana. IA puede auditarlo y redactarlo. No es crítico. | Desactualización silenciosa | Onboarding, READMEs |
| D — Insumo primario de Subagent | Consumido por Subagents en trabajo cotidiano. **TICKETS.md es generado por sync-tickets.yml** — no editar manualmente. El estado de cada ticket se actualiza moviendo el card en el GitHub Project. | Desincronización con estado real | Prompts de roles, TICKETS.md |
| B+D — Insumo universal | Consumido por Orchestrators y Subagents con propósito distinto. | Modificación que satisface a un consumidor pero rompe el contrato del otro | AI_CONTEXT_MASTER, PROJECT_DECISION_LOG |

**Aprovechabilidad por archivo:**

| Archivo | Tipo | Intervención humana | Orchestrator | Subagent |
|---|---|---|---|---|---|
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
│   ├── ROBLOX_SETUP.md               ← setup del place de Roblox (Tipo C, FND-004)
│   ├── RUNTIME_VERIFICATION.md        ← smoke test de runtime P6 via MCP (Tipo C, DL-043)
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
| P3 | Auditoría de proyecto | **Issue automático; auditoría manual** (TECH y DESIGN via Claude) — ver nota de ejecución | Lunes 9:00 UTC o solicitud PO | Hallazgos en log | p3-periodic-audit.yml | — |
| P5 | Contingencia manual | Humano | Pipeline ideal no disponible | Mismo artefacto del pipeline original | — | P1, P2/P4, P3 |
| P6 | Verificación de runtime y playtest | **MCP de Studio** (Claude o humano) | Ticket de comportamiento runtime antes de DONE; o hito de integración | Smoke test de runtime pasado + observaciones en SCRATCHPAD → P1 | — | — |

**Ejecutores detallados:**

```
P1 — Ideación estándar
  Scratchpad:           Humano
  Intake:               Subagent (SCRATCHPAD_INTAKE) + revisión humana
  Auditoría conceptual: Orchestrator
  Decisión:             Product Owner
  Ticket:               Humano o Subagent

P2/P4 — Implementación (Clase A)
  Implementación:       Constructor (Claude, disparado por humano)
  Self-review:          Constructor (modo auditor)
  Revisión:             Humano
  Auditoría TECH:       Codex — el Action crea el Issue automático post-merge;
                        la auditoría se ejecuta MANUAL (hoy no corre)
  Auditoría DESIGN:     Claude, manual, si domain:design o domain:both

P3 — Auditoría de proyecto
  TECH:   el cron crea el Issue automáticamente; la auditoría se ejecuta MANUAL
  DESIGN: humano activa Claude manualmente
  Contexto actual: TODA la auditoría es manual via Claude chat (ver nota)

P5 — Contingencia manual
  Ejecutor único: Humano
  Documentar en Decision Log con nota CONTINGENCY

P6 — Verificación de runtime y playtest
  Ejecutor: MCP de Studio — Claude conduce y verifica (o humano)
  PRIMERA etapa del pipeline con automatización de IA REAL: a diferencia
  del Codex aspiracional (DL-038), el MCP existe y corre. Verifica lo que
  specs/contratos NO pueden: integración cliente↔servidor, payloads,
  física/espacio, orden de eventos, bootstrap limpio. Contrato en §6.7.
```

**Nota de ejecución — automatización real vs. aspiracional (DL-038).** Ninguna GitHub Action invoca una IA. Los workflows solo **crean Issues y comentarios** (`issues.create`, `createComment`): lo que está automatizado es el *disparo del artefacto*, no su *procesamiento*. "Automático" en este registro se refiere a la creación del Issue, nunca a la ejecución de la auditoría o la construcción. Toda ejecución de IA — intake, construcción, auditoría TECH y DESIGN — es **manual**: un humano dispara Claude en chat. El acoplamiento a un runner de Codex/IA desatendido está **diseñado pero no implementado** (requiere IA de pago); mientras no exista, el pipeline opera de facto en modo P5 (contingencia manual) para todo lo que este registro llamaba "automático via Codex", y los Issues `codex-audit` sin procesar son backlog, no auditorías hechas.

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
              (docs/TICKETS.md es autoría de gobernanza: se derivan y editan
              manualmente vía PR, §5.5. Solo el campo Estado se sincroniza
              desde el GitHub Project por sync-tickets.yml — unidireccional
              Project→TICKETS.md, DL-030. El resto NO lo toca la automatización.)
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
|---|---|---|---|---|---|
| Auditor TECH (Codex) | Auditor | TECH | AUDITOR_TECH.md | §1+§2+§4+§5+§6, Decision Log, código, tickets |
| Auditor DESIGN (Claude) | Auditor | DESIGN | AUDITOR_DESIGN.md | §1+§2+§3+§5+§6, Decision Log, tickets |

**Subagents (Tipo D):**

| Agente | Tipo funcional | Knowledge Domain | Prompt | Archivos que consume |
|---|---|---|---|---|---|
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

### 6.7 Verificación de Runtime (DL-043)

El pipeline verificaba exhaustivamente lo **estático** (specs de núcleos puros, contratos grep/AST, lint, formato) pero **nada** verificaba que el juego *funcionara* en runtime. QA-001 lo expuso: 62 specs y todos los contratos en verde, pero el slice **no era jugable** — tres bugs de integración que ninguna verificación estática atrapa. El MCP de Roblox Studio cierra el hueco: **verificación de runtime accionable** (arrancar Play, conducir input, inspeccionar estado, leer consola), programática, por Claude o por el humano.

**Principio — estático necesario, no suficiente.** Los specs prueban núcleos puros *en aislamiento* (§4.13); no pueden atrapar la *integración*: cableado cliente↔servidor, forma de payloads, física/espacio, orden de eventos, bootstrap. Esos bugs solo se ven **en runtime**.

**Gate de Definition of Done (DL-043).** Un ticket que toca **comportamiento de runtime** — cableado cliente↔servidor, payloads de RemoteEvent, física/colisiones/trigger zones, orden de eventos, o el bootstrap — **no está DONE** hasta que pasa la verificación de runtime (P6). Los specs verdes NO bastan. (El slice #31 se mergeó sin esto → los bugs de QA-001.)

**El smoke test (procedimiento en `docs/RUNTIME_VERIFICATION.md`).**
1. **Bootstrap limpio:** servidor y cliente arrancan; la consola **sin errores ni stack traces** (más allá de ruido conocido de plataforma).
2. **Loop core end-to-end:** lobby → arranca ronda → spawn de objetos → recoger (weld, desanclado) → entregar (conteo sube, `DeliverObject`) → fin de ronda → summary.
3. **Aserciones de estado:** `state.objects` poblado en cliente; objetivo resuelto; objeto entregado destruido y contado.

**Lecciones de QA-001 codificadas como invariantes** (para que no se repitan; si se repiten, están mitigadas):
- **§4.3 — Contrato de payload de RemoteEvent:** ambos lados usan la forma exacta de §4.3; el receptor **parsea defensivo** (extrae del payload). Cazó el bug #2 (`{instanceId}` tratado como string).
- **§4.10 — Ownership de estado vs. eventos de control:** el estado de datos lo poseen sus eventos de datos; un evento de control **no** lo limpia (el orden entre RemoteEvents distintos no está garantizado). Cazó el bug #1 (RoundStarted borraba `state.objects`).
- **§4.4 — Trigger zone = volumen:** una zona `Touched` debe dimensionarse para lo que detecta, o detectar por la entidad que sí la toca. Cazó el bug #3 (objeto cargado a la altura del torso vs. zona a ras de suelo).

**Higiene de sync (lección QA-001).** Antes de verificar, el Studio debe reflejar el repo (rojo conectado y **sincronizado**). Un Studio *stale* produce diagnósticos falsos — en QA-001, un Studio desincronizado hizo reportar "ServerScriptService vacío" cuando no lo estaba, y enmascaró qué código corría.

**Automatización real.** P6-via-MCP es la **primera** etapa del pipeline con automatización de IA que *existe y corre* — a diferencia del runner de Codex aspiracional (DL-038). Claude conduce el MCP directamente.

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
| 5.22 | 2026-07-16 | **Prompt contextual de interacción (UI-002, Fusion).** Nuevo `PromptController`: "E — Recoger" cerca de un objeto free / "E — Soltar" cargando, visible solo en Active. La lógica de targeting vive UNA vez en `InteractionController` (nuevo `getTarget()`); el prompt la consume en un poll de 0.15s (`task.wait`, no per-frame §4.12) y renderiza con Value/Computed (§4.14). Cero llamadas al servidor; sin RemoteEvents (INV-001). Runtime (MCP): Recoger→Soltar→oculto verificado. |
| 5.21 | 2026-07-16 | **Eventos de ronda activos (WLD-005).** Nuevo `EventManager`: `triggerRandom()` del pool de `Config/Events`, `EventTriggered` a clientes, `reset()` con cleanup exacto; degradación explícita (evento fallido ⇒ ronda sin evento, nunca rota). RoundManager lo dispara tras el NPC y antes de `RoundStarted` (payload lleva `eventType`, DL-026); `ENABLE_EVENTS = true`. El evento del pasillo aparca al vecino via Attribute **`EventParked`** (coordinación por DataModel, sin require entre capas — la patrulla espera); MapBootstrap genera la NPCDropZone del chokepoint con `EventTag`. Runtime (MCP): NPC bloqueando `(0,3,21)`, cadena Evento→EventTriggered→RoundStarted verificada. |
| 5.20 | 2026-07-16 | **El vecino patrulla (WLD-004).** Nuevo `NPCManager`: NPC placeholder construido en código (raíz-torso de colisión + cabeza soldada, tag `NPCModel`), patrulla los `NPCNode` en orden de `NodeIndex` **solo con TweenService** (duración = distancia/`NPC_SPEED`), colisión activa (bloquea el paso — Entropía §3.4). Orden y avance puros en `Rules/NPCRules` (`orderedPatrol` con descarte de índices inválidos, `nextStep` circular). RoundManager llama start/stop/reset bajo `ENABLE_NPC = true` (activado). 83 specs. Runtime (MCP): patrulla 6 nodos, 14.2 studs en 2.5s, sin errores. |
| 5.19 | 2026-07-16 | **Caída por pérdida de soporte (GAM-007) + módulo CarrySupport.** `CarryRules.evaluateSupport` puro (keep/reassign/grace/drop con tolerancia `supportTimeout`); si otro jugador entra en rango toma el relevo (reassign, más cooperativo que el soporte fijo del ticket); `SupportLost`/`SupportRestored` como StoryEvents. La vigilancia vive en el nuevo **`CarrySupport`** (loop task.wait 0.25s, §4.12) — extraído de CarryManager (424→355 líneas, backstop DL-033): recibe los entries por inyección, CarryManager sigue siendo su dueño (§4.8). 76 specs. |
| 5.18 | 2026-07-16 | **Líder/soporte para objetos large (GAM-006) + GAM-005 verificado.** `CarryRules` gana `supportAvailable` en los hechos y `chooseSupport` puro (el otro jugador más cercano en `supportRange`, excluyendo líderes activos); `CarryManager` busca el soporte al pickup y lo replica en `ObjectStateChanged.supportId` (§4.3). Sin soporte, el carry de large no comienza (Dependencia Social §2.1). 70 specs. Runtime (solo): large rechazado sin soporte; GAM-005 verificado (WalkSpeed 16→9.6→16). Path con soporte → QA-002 (2+ jugadores, humano). |
| 5.17 | 2026-07-16 | **Prefabs versionados y generados en código (FND-003/WLD-008, DL-040).** `assets/ObjectPrefabs.rbxmx` generado por `lune/build-prefabs.luau` (box_small con cinta, sofa_medium con respaldo/brazos/cojines, wardrobe_large con puertas/tiradores) — Models con PrimaryPart-raíz de colisión anclada y detalles decorativos soldados sin colisión (física idéntica al Part suelto que CarryManager muta). Verificación round-trip del contrato §4.4 antes de escribir. Mapeado en `default.project.json` → `ServerStorage/ObjectPrefabs`; ObjectPrefabs deja de estar "fuera de Rojo" (§4.1). Arte final = humano (WLD-008). |
| 5.16 | 2026-07-16 | **Rediseño del pipeline: Verificación de Runtime (§6.7, DL-043).** QA-001 expuso que 62 specs + todos los contratos en verde no impedían un slice injugable (3 bugs de integración). El MCP de Studio cierra el hueco: nueva **tier de verificación de runtime (P6)** accionable — arrancar Play, conducir input, inspeccionar estado, leer consola (Claude o humano). **Gate de Definition of Done:** tickets de comportamiento runtime no están DONE sin pasar el smoke test. Las 3 lecciones codificadas como invariantes: §4.3 (contrato de payload + parsing defensivo), §4.10 (ownership de estado por evento vs. eventos de control), §4.4 (trigger zones son volúmenes). Nuevo `docs/RUNTIME_VERIFICATION.md`. P6-via-MCP es la primera automatización de IA **real** del pipeline (vs. Codex aspiracional, DL-038). |
| 5.15 | 2026-07-15 | **Configuración del place (FND-004, DL-039).** Nuevo `docs/ROBLOX_SETUP.md`: cómo levantar el juego desde el repo, qué versiona Rojo vs. qué es solo-Studio, y el contrato de tags de CollectionService (§4.4). `Workspace.StreamingEnabled = false` fijado en `default.project.json` (sobre de escala §4.12). §6.2 lista el nuevo doc. La "correcta configuración de Roblox" era infra implícita sin ticket — cerrada por completitud (DL-039). |
| 5.14 | 2026-07-15 | **Flujo de Lobby (GM-004, DL-039).** Área de lobby propia con `SpawnLocation` (`LobbySpawn`), separada de la zona de ronda, generada por MapBootstrap en placeholder. GameManager teletransporta a los jugadores lobby↔edificio en las transiciones de fase (`RoundSpawn` dentro del edificio). Nuevo contrato de tags Layout→GameManager en §4.4. El disparador de ronda (`LOBBY_DURATION` + `MIN_PLAYERS_TO_START`) ya existía (GM-003). El lobby rico (matchmaking) sigue como horizonte (§3.9). Pendiente: verificación en Studio. |
| 5.13 | 2026-07-15 | **Migración de UI a Fusion (UI-004, DL-042).** `HUDManager` y `SummaryManager` reescritos en Fusion 0.3 declarativo: `Value`s alimentados por un único `subscribe` a ClientStateManager, GUI vía `scope:New`, lista de StoryEvents con `ForValues`, lifecycle con `scope:doCleanup()`. Cero `Instance.new`/mutación manual de labels. INV-001 intacto. §4.14 actualizado (ya no "imperativos"). Pendiente: verificación en Studio. |
| 5.12 | 2026-07-15 | **Framework de UI: Fusion (§4.14, DL-042).** Decisión del PO — la UI se adopta declarativa-reactiva (`elttob/fusion`): los módulos derivan de `Value`s que reflejan ClientStateManager (§4.10), sin mutar Instances a mano; `UI = f(estado)` mapea 1:1 sobre el estado único del cliente y es AI-óptimo (§5.9). Se prefirió sobre React-lua (peso/ceremonia). Nueva §4.14 fija el contrato. El alta de la dependencia Wally y la migración de HUDManager/SummaryManager son **UI-004** (hoy siguen imperativos — marcado pendiente para no adelantar la realidad). |
| 5.11 | 2026-07-15 | **Input de interacción del cliente (GAM-010, DL-039).** Nuevo `src/client/InteractionController.lua`: captura el input (`GlobalConfig.INTERACT_KEY`) y dispara `InteractObject:FireServer` — cierra el bug de QA-001 (el servidor escuchaba pero ningún cliente disparaba). No conecta RemoteEvents (INV-001); lee estado de ClientStateManager y localiza objetos por Tag `CarryObject` + Attribute `InstanceId`. Árbol de §4.1 sincronizado con los módulos de cliente reales (InteractionController, HUDManager, SummaryManager). Pendiente: verificación en Studio (QA-001). |
| 5.10 | 2026-07-15 | **Protocolo de Versionado + gate de trazabilidad (§5.10, DL-041).** Nueva §5.10 obligatoria: 1 unidad = 1 rama desde `main` = 1 PR (sin apilar); rebase (no merge) antes de integrar, squash, borrar rama; **master↔código en el mismo PR** (un `class:a` referencia su DL y toca `docs/`); nombres de checks estables; el PO sincroniza el ruleset. **Gate de CI `Contract: class:a traceability (DL-041)`** en p2-implementation.yml: falla si un PR `class:a` no referencia un `DL-xxx` o no toca `docs/` — cierra el fallo de #44 (§5.0 actualizado). Requiere que el PO añada el check al ruleset. |
| 5.9 | 2026-07-15 | **Reencuadre a ciclo de vida + completitud de tickets (auditoría PO, DL-039).** La infra/arquitectura/gobernanza apuntan al **ciclo de vida completo**; el MVP/slice es el **primer hito**, no el horizonte (§1.3, §5.7). La regla de Completitud (§5.5) se aplica a escala ciclo-de-vida — se derivan los habilitadores que faltaban: `GAM-010` (input del cliente, dueño del bug de QA-001), `WLD-008` (autoría de prefabs), `FND-003` (versionado de prefabs via Rojo), `FND-004` (config del place), `GM-004` (flujo de lobby). **Versionado de prefabs (§4.1, DL-040):** `ServerStorage/ObjectPrefabs` deja de estar "fuera de Rojo" — se versiona como `assets/ObjectPrefabs.rbxmx` mapeado por Rojo. **Corrección §6.4:** `TICKETS.md` es autoría de gobernanza; `sync-tickets` solo sincroniza el campo `Estado` (unidireccional Project→TICKETS.md). |
| 5.8 | 2026-07-15 | **Verdad-en-docs — sincronización master↔realidad (auditoría PO).** **Núcleo funcional / shell imperativo (§4.13, DL-037):** se formaliza retroactivamente la capa `src/shared/Rules/` (CarryRules/RoundRules/StatRules) que #44 introdujo como `class:b` sin DL ni update de master — mis-clasificación de un cambio Clase A; §4.1 (árbol) corregido con `Rules/` y la convención de Tests. **Realidad del pipeline de IA (§6.3, §5.5, DL-038):** los workflows solo crean Issues — ninguna Action invoca una IA; toda ejecución (intake, construcción, auditoría) es **manual via Claude**. Se corrigen las afirmaciones de "Codex automático" y se añade la Nota de ejecución: el acoplamiento a un runner de IA desatendido está diseñado pero **no implementado** (requiere IA de pago). |
| 5.7 | 2026-07-13 | Arbitración de mapa activo (§4.4, DL-036): `GlobalConfig.MAP_MODE` (`"placeholder"`\|`"real"`) como fuente única — reemplaza la detección frágil por `TruckZone` (DL-028) y la idea de flag-que-apaga-flag. El mapa real vive bajo `Workspace/RealMap`; en `"placeholder"` MapBootstrap destruye su copia runtime y genera el edificio. Tickets WLD-000/WLD-001 actualizados. |
| 5.6 | 2026-07-12 | Gobernanza completa del eje no-funcional y del coste del implementador (DL-032, DL-033, DL-034). **§5.9 Modelo de Coste del Implementador (DL-032):** las heurísticas se calibran a coste-IA + revisor + runtime, nunca a coste-humano-implementador. **Regla de derivación de tickets (§5.5, DL-032):** todo ticket traza a una DECISIÓN del DL o a un Principio/hito (campo `Deriva de`); alta retroactiva de WLD-000 y GAM-009. **Recalibración de umbrales (DL-033):** módulo 300→400 líneas (coste-revisor); resuelta la inconsistencia del ≤7 RemoteEvents (gate duro contra cap; elevarlo es Clase A). **§4.12 Contratos No Funcionales (DL-034):** invariantes de complejidad, sobre de escala de diseño y ownership de destrucción/cleanup — el eje no-funcional, enriqueciendo el master en vez de fragmentarlo. **Invariante de dirección de dependencias (§4.5, DL-035):** las dependencias apuntan hacia abajo, sin ciclos; se rechaza el fan-out como métrica (anti-correlaciona con los orquestadores de §4.8) y se registra el gate automático como candidato diferido. **Convención de nombres de required checks (§5.0, DL-033):** el umbral vive en el nombre del check solo si cambiarlo es Clase A — los caps N1 (≤7) lo conservan; los backstops N2 (tamaño de módulo) no, para que su recalibración Clase B no rompa el ruleset. |
| 5.5 | 2026-07-12 | Endurecimiento de arquitectura `src/`: formalizado el contrato `ObjectId → asset` en un módulo dedicado `PrefabRegistry` (§4.4, §4.1, §4.5, DL-031) — cierra el hueco entre `ObjectDefinition` y `ServerStorage/ObjectPrefabs` sin acoplar `ObjectManager` a Studio ni referenciar modelos desde los datos. `validate()` audita el contrato al bootstrap. |
| 5.4 | 2026-07-11 | Directrices del PO + arranque del vertical slice: estándar de calidad profesional desde la primera versión pública y reloj del roadmap reiniciado — slice al 2026-08-11 (§1.3, §5.7, DL-024). Suscripción selectiva de timer en ClientStateManager (§4.10, DL-025). Payloads: objectId en ObjectStateChanged, eventType opcional en RoundStarted (§4.3, DL-026). Contrato de restauración de WalkSpeed (DL-027). Contrato Layout → Gameplay (Tags ObjectSpawn/TruckZone) y módulo MapBootstrap (§4.4, DL-028). INV-001 enmendado: OnServerEvent:Connect solo en CarryManager (§4.3, §4.6, §4.10, §5.0, DL-029). |
| 5.3 | 2026-07-10 | Auditoría arquitectónica: ciclo de sesión de PlayerData atado al jugador, no a la ronda (§4.4, §4.7 — se añade `releasePlayer`; `savePlayer` es flush, nunca EndSession). StoryEvent gana `Timestamp` relativo al inicio de ronda (§4.4). Definición del código G5 (§5.3). Mecanismo real del ban print/warn: grep `contract-logger-usage`, no Selene (§5.0). Roadmap Semana 1: ProfileStore, no "DataStore básico" (§5.7). Correcciones factuales de §4.1, §4.11, §6.2, §6.3 y §6.6 (paths de config, ServerPackages, commitlintrc, sync-tickets, cron UTC). Nota de prefijos GM/QA (§5.1). |
| 5.2 | 2026-06-06 | Versión de bootstrap del proyecto. |
