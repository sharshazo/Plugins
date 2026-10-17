-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["the_harrowing_of_morgul"] = {
  { "Shaktur", {
    { "Frontal", "CZ", 0, 0, nil, { "don t run", "no corras", "maggots" }, "AoE!", true, nil, "Frontal", "¡Área!" },
  } },
  { "Dargásh", {
    { "BIG AOE", "Z", 0, 0, nil, { "come closer", "acércate" }, nil, true, nil, "Área grande", nil },
    { "Tank is dropping puddles!", "ZT", 0, 0, nil, { "contagion" }, "Puddles", true, nil, "¡El tanque deja charcos!", "Charcos" },
    { "Interrupt Dargash", "I", 0, 0, nil, { "minions" }, "Interrupt", true, nil, "Interrumpe a Dargash", "Interrumpe" },
  } },
}
