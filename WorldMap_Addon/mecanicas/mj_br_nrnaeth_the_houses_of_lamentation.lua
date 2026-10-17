-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["br_nrnaeth_the_houses_of_lamentation"] = {
  { "Manôzagar", {
    { "Aoe distributed", "Z", 0, 0, nil, { "shadow of the" }, nil, true, nil, "Área repartida: júntense", nil },
    { "Frontal", "C", 0, 0, nil, { "none can stand before me" }, nil, true, nil, "Frontal", nil },
  } },
  { "Agath-kali, the Gaunt-woman", {
    { "Spirit", "Q", 0, 0, nil, { "you shall serve" }, nil, true, nil, "Espíritu", nil },
    { "Root bubble", "KB", 0, 0, nil, { "drink morloth drink and be renewed", "bebe morloth bebe y renuévate" }, nil, true, nil, "Burbuja que inmoviliza", nil },
    { "Enraged", "E", 0, 0, nil, { "wither and die", "marchítate y muere" }, nil, true, nil, "Enfurecido", nil },
    { "Spread for fear!", "SF", 0, 0, nil, { "your mind shall break", "tu mente se quebrará" }, nil, true, nil, "¡Sepárense por el miedo!", nil },
  } },
  { "Narkhor the Flensed", {
    { "Frontal!", "C", 0, 0, nil, { "flay you until nothing" }, nil, true, nil, "¡Frontal!", nil },
    { "Add spawn", "Q", 0, 0, nil, { "the blood of the unhoused is mine to com", "la sangre de los desalojados está a mis" }, nil, true, nil, "Aparecen esbirros", nil },
    { "Triple hit!", "Q", 0, 0, nil, { "flesh limits you" }, nil, true, nil, "¡Golpe triple!", nil },
  } },
}
