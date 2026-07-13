-- ProfileStoreConfig
-- Configuración declarativa del ProfileStore (§4.7, PER-001).
-- No contiene lógica — solo constantes de configuración del store.
--
-- El template canónico de PlayerData (§2.5) vive en MigrationService
-- (getTemplate()) — fuente única del schema y su versionado.
-- PlayerDataService lo pasa a ProfileStore.New() al crear el store.
--
-- Módulo puro: sin acceso a game/servicios — testeable en Lune (§4.6).
-- Server-only: nunca se requiere desde src/client/ (§4.7).

return {
    -- Nombre versionado del DataStore. Cambiarlo equivale a un wipe lógico —
    -- solo con decisión del PO y entrada en el Decision Log.
    STORE_NAME = "PlayerData_v1",

    -- Prefijo de la clave de sesión por jugador: player_<UserId>
    SESSION_KEY_PREFIX = "player_",
}
