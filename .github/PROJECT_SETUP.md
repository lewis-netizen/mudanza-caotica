# GitHub Project Setup — Mudanza Caótica

Instrucciones de configuración manual del GitHub Project.
Hacer una sola vez antes de activar sync-tickets.yml.

---

## 1. Crear el Project

GitHub → repo → Projects → New project → Board

**Nombre:** Mudanza Caótica
**Tipo:** Board (kanban)

---

## 2. Configurar columnas

Crear exactamente estas columnas en este orden:

| Columna | Estado en TICKETS.md |
|---|---|
| `TODO` | TODO |
| `IN_PROGRESS` | IN_PROGRESS |
| `BLOCKED` | BLOCKED |
| `DONE` | DONE |

Los nombres deben coincidir exactamente — sync-tickets.yml los mapea por nombre.

---

## 3. Milestones

GitHub → repo → Issues → Milestones → New milestone

Crear 4 milestones, uno por semana del roadmap (§5.7):

| Milestone | Due date |
|---|---|
| Semana 1 | [fecha de fin de semana 1] |
| Semana 2 | [fecha de fin de semana 2] |
| Semana 3 | [fecha de fin de semana 3] |
| Semana 4 | [fecha de fin de semana 4] |

Los Milestones dan barra de progreso (X/Y Issues cerrados) y fecha límite automáticamente — sin configuración adicional. GitHub Projects v2 los muestra de forma nativa como campo agrupable/filtrable en las vistas del Project, sin necesidad de un campo custom.

---

## 4. Campos custom

Project → Settings → Fields → Add field:

| Campo | Tipo | Valores |
|---|---|---|
| `Domain` | Single select | `Gameplay` `World` `Networking` `Persistence` `UI` `QA` |
| `DL-Ref` | Text | — |

`Semana` no es un campo custom — se resuelve con Milestones (paso 3). El Project puede agrupar o filtrar por Milestone directamente desde la configuración de la vista, sin añadirlo como campo.

---

## 5. Importar tickets

Para cada ticket en TICKETS.md, crear un Issue y asignarlo al Project.

**Formato obligatorio del título del Issue:**
```
[DOMINIO]-[número] — [Descripción corta]
```

Ejemplo:
```
NET-001 — Módulo Networking.lua: Fuente única de RemoteEvents
GAM-002 — ObjectManager: Spawn y estados
```

**Al crear el Issue, asignar:**
- Labels: `domain:*` + `class:*`
- Milestone: el correspondiente a `Semana` en TICKETS.md
- Project: Mudanza Caótica (automático si `Auto-add to project` está activo)

El ID al inicio del título es lo que `sync-tickets.yml` usa para hacer el match contra TICKETS.md. Sin el ID al inicio, el Issue no se sincroniza.

---

## 6. Activar la sincronización

`sync-tickets.yml` usa la API GraphQL de Projects v2. El `GITHUB_TOKEN` automático de Actions **no puede leer Projects v2** — es una limitación de permisos de GitHub, no un error del workflow. Necesitas dos configuraciones antes de que la sincronización funcione.

### 6.1 Obtener el número del Project

Visible en la URL del Project:
```
https://github.com/users/lewis-netizen/projects/N
                                              ^
                                    este número
```

### 6.2 Crear un PAT clásico con scope read:project

⚠ **Los fine-grained tokens NO sirven aquí:** el permiso de Projects en
fine-grained tokens solo existe para proyectos de **organizaciones**
("Organization permissions → Projects"). Para un Project de **cuenta de
usuario** (este caso) no hay apartado equivalente — solo funciona el PAT
clásico.

```
GitHub → tu avatar → Settings → Developer settings
→ Personal access tokens → Tokens (classic) → Generate new token (classic)

Nombre: mudanza-caotica-projects-sync
Expiration: 90 días (renovar cuando expire)
Scopes:
  read:project    ← lo único que el workflow necesita (solo lee el Project;
                    el push a TICKETS.md lo hace el GITHUB_TOKEN de Actions)
```

Copia el token generado — no se vuelve a mostrar.

Si el Project migra a una organización en el futuro, un fine-grained token
con `Organization permissions → Projects: Read-only` es la opción preferida.

### 6.3 Configurar el repo

```bash
# Número del Project como variable
gh variable set PROJECT_NUMBER --body "N"

# Token como secret
gh secret set PROJECTS_TOKEN
# → pega el token cuando lo pida
```

### 6.4 Test manual

```bash
gh workflow run sync-tickets.yml
gh run watch
```

Verificar que TICKETS.md se actualizó correctamente con los estados del Project. Si falla con error de permisos, revisar que el PAT clásico tiene el scope `read:project` y que `PROJECT_NUMBER` coincide con la URL del Project.

---

## 7. Flujo de trabajo diario

```
Humano mueve un card en el Project (drag & drop)
↓
Disparar sync manualmente o via workflow_dispatch
↓
sync-tickets.yml lee el Project via API
↓
Actualiza el campo Estado en TICKETS.md
↓
Commit automático: chore(governance): sync [ID]: [ANTES] → [DESPUÉS]
↓
Los Subagents leen TICKETS.md con el estado actual
```

**TICKETS.md no se edita manualmente.**
Todo cambio de estado viene del Project. El campo `Semana` de TICKETS.md es informativo para las IAs — no se sincroniza desde GitHub, ya que el Milestone se asigna una sola vez al crear el Issue y no cambia.

---

## Notas

- El campo `Domain` y `DL-Ref` son solo para visualización humana en el Project. No se sincronizan a TICKETS.md — TICKETS.md ya los tiene.
- `Semana` se resuelve con Milestones nativos de GitHub, no con un campo custom — da barra de progreso y fecha límite sin trabajo adicional.
- `wally.lock` sí se commitea — no añadir a .gitignore.
- Los commits de sync tienen prefijo `chore(governance):` — no generan auditoría de Orchestrator (class:b implícito por ser commits del bot).
