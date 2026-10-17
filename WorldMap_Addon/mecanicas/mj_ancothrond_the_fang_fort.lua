-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["ancothrond_the_fang_fort"] = {
  { "Eithalam", {
    { "Fury Swipes", "SW", 20, 15, { 1090527705 }, nil, nil },
    { "Bolstering Howl", "X", 30, 30, { 1091475959, 1091475960 }, nil, nil },
    { "Staggering Claws", "W", 25, 20, { 1091476353 }, nil, nil },
  } },
  { "Gorthob the Lothly", {
    { "Infesting Bite", "I", 10, 5, nil, nil, nil },
    { "TBD", "C", 15, 20, nil, nil, nil },
  } },
  { "Gorthob's Tentacle", {
    { "Hulking Slam", "C", 15, 1, nil, nil, nil },
  } },
  { "TBD Skuthuk Elder", {
    { "Dazing Slam", "ISK", 20, 10, nil, nil, nil, nil, { "Golpe aturdidor", "Golpe Aturdidor" } },
    { "Dazing Throw", "IK", 35, 20, nil, nil, nil },
  } },
  { "TBD Hinderling Melee", {
    { "TBD", "I", 30, 15, nil, nil, nil },
  } },
  { "TBD Mire-maggot Melee", {
    { "Poisoned Bite", "ISP", 15, 5, { 1092810118 }, nil, nil },
    { "Hatch", "I", 25, 30, nil, nil, nil, nil, { "Eclosión" } },
  } },
}
