-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["woe_of_the_willow"] = {
  { "Gulmúk Dampmould", {
    { "Big Knockback", "K", 0, 0, nil, { "witness our might" }, nil, true, nil, "Derribo fuerte", nil },
    { "Small Knockback", "K", 0, 0, nil, { "fall before us", "cae ante nosotros" }, nil, true, nil, "Derribo leve", nil },
    { "Puddle", "Z", 0, 0, nil, { "our corruption runs deep", "nuestra corrupción es profunda" }, nil, true, nil, "Charco", nil },
  } },
}
