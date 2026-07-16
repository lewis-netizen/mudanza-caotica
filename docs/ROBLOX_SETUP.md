# ROBLOX_SETUP — Setup del place (FND-004)

Cómo levantar Mudanza Caótica desde el repo. Cubre lo que **Rojo versiona** y lo
que **solo vive en Studio** (y por tanto se documenta aquí, no se puede reproducir
automáticamente). Deriva de la Completitud de tickets (§5.5, DL-039): la "correcta
configuración de Roblox" es infraestructura que ningún ticket de feature nombra.

> No confundir con `.github/PROJECT_SETUP.md`, que configura el **GitHub Project**
> (board de tickets). Este archivo configura el **place de Roblox**.

## 1. Prerrequisitos

- **Rokit** (gestor de toolchain). Instala las herramientas pinneadas en `rokit.toml`:
  ```
  rokit install
  ```
  Provee `rojo`, `wally`, `stylua`, `selene`, `lune`, `lefthook`.
- **Wally** (paquetes). Instala las dependencias en `Packages/` (gitignoreado):
  ```
  wally install
  ```
- **Roblox Studio** con el **plugin de Rojo** instalado.

## 2. Levantar el juego

```
rojo serve                 # sirve el árbol de default.project.json
# En Studio: plugin Rojo → Connect → Play
```

En Play, `Main.server.lua` arranca `MapBootstrap`, `PrefabRegistry.validate` y
`GameManager`. Con `GlobalConfig.MAP_MODE = "placeholder"` (default), MapBootstrap
genera el edificio, el área de lobby y todos los tags de contrato — **no requiere
ningún paso manual de Studio** para tener una ronda jugable.

Para tipos/autocompletado (opcional):
```
rojo sourcemap default.project.json -o sourcemap.json
```

Tests headless (sin Studio):
```
lune run lune/run-specs.luau
```

## 3. Qué versiona Rojo (reproducible desde el repo)

Definido en `default.project.json`:

| Runtime | Origen |
|---|---|
| `ServerScriptService/Systems` | `src/server` |
| `ServerScriptService/ServerPackages` | `ServerPackages` (wally) |
| `ReplicatedStorage/Shared` | `src/shared` |
| `ReplicatedStorage/Packages` | `Packages` (wally) |
| `ReplicatedStorage/Remotes` (7 RemoteEvents) | declarados inline (§4.3) |
| `StarterPlayer/StarterPlayerScripts` | `src/client` |
| `StarterGui` | `src/gui` |
| `ServerStorage/ObjectPrefabs` | `assets/ObjectPrefabs.rbxmx` (generado — ver abajo) |
| `Workspace.StreamingEnabled = false` | `$properties` (ver §5) |

Los prefabs de objeto se **generan en código** (FND-003/WLD-008, DL-040): tras
cambiar un modelo en `lune/build-prefabs.luau`, regenerar con
```
lune run lune/build-prefabs.luau
```
El script valida el contrato Arte→PrefabRegistry (§4.4) por round-trip antes de
escribir. El `.rbxmx` generado se commitea.

## 4. Qué NO versiona Rojo (solo Studio — se documenta aquí)

- **Mapa real** (`Workspace/RealMap`): se construye en Studio (WLD-001) y se activa
  con `GlobalConfig.MAP_MODE = "real"` (DL-036). Mientras esté incompleto, se
  desarrolla con `"placeholder"`.
- ~~`ServerStorage/ObjectPrefabs`~~: **ya versionado via Rojo** (`assets/ObjectPrefabs.rbxmx`,
  FND-003/DL-040). Los modelos funcionales los genera `lune/build-prefabs.luau`; el
  **arte final** (mallas/texturas de calidad) sigue siendo trabajo de Studio (WLD-008).
- **Publicación** (game ID, permisos de acceso, productos): **QA-004**.

## 5. Settings del place (sobre de escala §4.12)

- **StreamingEnabled = false.** El sobre es 4–6 jugadores y un mapa pequeño (§1.2,
  §4.12) — el streaming no aporta y añade complejidad. Fijado y versionado en
  `default.project.json` (`Workspace.$properties`).
- **Colisiones:** sin CollisionGroups propios en el slice — el comportamiento por
  defecto basta. (Si se añaden, documentar aquí y en §4.12.)
- **Spawns:** los gestiona `MapBootstrap` (placeholder) vía `SpawnLocation` tagueada
  `LobbySpawn`; no hay que colocar spawns a mano. En modo `"real"` el mapa de Studio
  debe proveer los tags (§4.4).

## 6. Contrato de tags de CollectionService (§4.4)

El layout (placeholder o real) debe proveer estos tags; en placeholder MapBootstrap
los genera:

| Tag | Consumidor | Attribute |
|---|---|---|
| `ObjectSpawn` | ObjectManager | — |
| `TruckZone` | TruckManager | — |
| `NPCNode` | NPCManager | `NodeIndex` (number) |
| `NPCDropZone` | EventManager | — |
| `LobbySpawn` | GameManager (lobby) | — |
| `RoundSpawn` | GameManager (teleport a ronda) | — |
| `CarryObject` | (runtime) ObjectManager lo pone en cada objeto spawneado | `InstanceId`, `ObjectId` |
