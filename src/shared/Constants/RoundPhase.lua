-- Constants/RoundPhase.lua
-- Fuente única de las fases globales del juego (§4.4).
-- GameManager es el único que TRANSICIONA fases (§4.8); el cliente las deriva
-- de RoundStarted/RoundEnded. Consumidores comparan contra estas constantes,
-- nunca contra literales sueltos.
--
-- Módulo puro — Lune-compatible por construcción (§4.6).

return table.freeze({
    LOBBY = "Lobby",
    ACTIVE = "Active",
    SUMMARY = "Summary",
})
