-- RoundConfig.lua
-- Configuración del ciclo de ronda.
-- RoundManager lee estos valores — nunca los hardcodea.
--
-- REGLA: cambios aquí son Clase A si afectan la experiencia del jugador.
-- Clase B si son solo ajustes de timing técnico.

return {
    -- Duración de una ronda en segundos.
    -- Objetivo MVP: 3 minutos.
    ROUND_DURATION = 180,

    -- Tiempo en estado Summary antes de volver a Lobby (segundos).
    SUMMARY_DURATION = 12,

    -- Tiempo en estado Lobby antes de iniciar ronda (segundos).
    -- Permite que los jugadores se unan antes de que empiece.
    LOBBY_DURATION = 10,

    -- Mínimo de jugadores requeridos para iniciar ronda.
    -- MVP: 1 (permite testing en solitario).
    MIN_PLAYERS_TO_START = 1,
}
