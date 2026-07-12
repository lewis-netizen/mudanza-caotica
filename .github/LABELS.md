# GitHub Labels — Mudanza Caótica

Crea estos labels en GitHub → Settings → Labels antes de hacer el primer PR.

## Labels de dominio (requeridos en todo PR)

| Nombre | Color | Descripción |
|---|---|---|
| `domain:tech` | `#0075ca` | Cambio en dominio técnico |
| `domain:design` | `#e4e669` | Cambio en dominio de diseño |
| `domain:both` | `#f9d0c4` | Cambio que cruza dominios |

## Labels de clase (requeridos en todo PR)

| Nombre | Color | Descripción |
|---|---|---|
| `class:a` | `#d93f0b` | Cambio arquitectónico — requiere Decision Log y auditoría |
| `class:b` | `#0e8a16` | Cambio local — solo commit |

## Labels de auditoría (creados por Actions automáticamente)

| Nombre | Color | Descripción |
|---|---|---|
| `codex-audit` | `#6f42c1` | Issue de auditoría TECH para Codex |
| `audit:tech` | `#6f42c1` | Auditoría de dominio técnico |
| `audit:design` | `#e4e669` | Auditoría de dominio de diseño |
| `p3-periodic` | `#bfd4f2` | Issue de auditoría periódica semanal |
| `manual-activation` | `#fef2c0` | Requiere activación manual de Claude |
| `intake-pending` | `#c2e0c6` | Entradas del scratchpad pendientes de intake |
| `audit:blocked` | `#d93f0b` | Veredicto de auditoría: Rechazado — añadido por el Auditor |
| `audit:passed` | `#0e8a16` | Veredicto de auditoría: Aprobado — añadido por el Auditor |
