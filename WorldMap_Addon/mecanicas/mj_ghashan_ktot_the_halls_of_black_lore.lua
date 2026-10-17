-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["ghashan_ktot_the_halls_of_black_lore"] = {
  { "Skorgrím", {
    { "Hammer!", "Q", 0, 0, nil, { "you cannot withstand my full might" }, nil, true, nil, "¡Martillo!", nil },
  } },
  { "Dolguzigir, the Dark Archivist", {
    { "Throw", "Q", 0, 0, nil, { "memories against" }, nil, true, nil, "Lanzamiento", nil },
    { "Spirit spawn", "Q", 0, 0, nil, { "double edged", "fires of rage" }, nil, true, nil, "Aparece un espíritu", nil },
  } },
}
