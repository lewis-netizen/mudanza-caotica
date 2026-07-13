-- Constants/ObjectState.lua
-- Fuente única de los estados de ObjectInstance (§2.3, §4.3).
-- Estos strings son FORMATO DE WIRE: viajan en ObjectStateChanged (§4.3) y
-- se comparan en el cliente — cambiar un valor es un cambio de contrato.
--
-- Consumidores: CarryManager, TruckManager, RoundManager, ClientStateManager
-- los requieren (lazy, dentro de funciones — §4.6). ObjectManager es el DUEÑO
-- del estado (§4.8) y mantiene su tabla local VALID_STATES con estos mismos
-- literales: se carga standalone en los specs de Lune, donde no puede requerir
-- siblings. Ambos extremos los fija ObjectState.spec + ObjectManager.spec.
--
-- Módulo puro — Lune-compatible por construcción (§4.6).

return table.freeze({
    FREE = "free",
    BEING_CARRIED = "being_carried",
    DELIVERED = "delivered",
})
