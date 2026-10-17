-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["shakalush_the_stair_battle"] = {
  { "Groz", {
    { "Interrupt", "I", 0, 0, nil, { "crush them to bits", "aplástalos hasta hacerlos pedazos", "smash smash smash", "this will hurt", "esto dolerá", "smash those little things", "aplasta a esas cositas", "smash all of them to bits", "aplástalos a todos hasta hacerlos pedaz" }, nil, true, nil, "Interrumpe", nil },
  } },
  { "Shatarkha", {
    { "Frontal!", "C", 0, 0, nil, { "chill them to the core" }, nil, true, nil, "¡Frontal!", nil },
    { "Horn", "Q", 0, 0, nil, { "may your blood run cold", "que tu sangre se hiele" }, nil, true, nil, "Cuerno", nil },
  } },
  { "Ulk", {
    { "Interrupt", "I", 0, 0, nil, { "crush them to bits", "aplástalos hasta hacerlos pedazos", "smash smash smash", "this will hurt", "esto dolerá", "smash those little things", "aplasta a esas cositas", "smash all of them to bits", "aplástalos a todos hasta hacerlos pedaz" }, nil, true, nil, "Interrumpe", nil },
  } },
  { "Azbauz", {
    { "Bleed", "Q", 0, 0, nil, { "bleed slowly", "sangra lentamente" }, nil, true, nil, "Sangrado", nil },
    { "Interrupt Azbaus", "I", 0, 0, nil, { "they will fall" }, nil, true, nil, "Interrumpe a Azbaus", nil },
  } },
  { "Maugrush", {
    { "Interrupt Maugrash", "I", 0, 0, nil, { "blood shall cover the field", "la sangre cubrirá el campo" }, nil, true, nil, "Interrumpe a Maugrash", nil },
    { "Bleed", "Q", 0, 0, nil, { "my blade will bathe in blood", "mi espada se bañará en sangre" }, nil, true, nil, "Sangrado", nil },
    { "Frontal!", "C", 0, 0, nil, { "all those before me shall fall" }, nil, true, nil, "¡Frontal!", nil },
  } },
  { "Groz-and-Ulk", {
    { "Interrupt", "I", 0, 0, nil, { "crush them to bits", "aplástalos hasta hacerlos pedazos", "smash smash smash", "this will hurt", "esto dolerá", "smash those little things", "aplasta a esas cositas", "smash all of them to bits", "aplástalos a todos hasta hacerlos pedaz" }, nil, true, nil, "Interrumpe", nil },
  } },
}
