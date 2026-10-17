-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["ancothrond_the_fang_fort"] = {
  { "Eithalam", {
    { "Fury Swipes", "SW", 20, 15, nil, { 1090527705 }, nil, "Single Target" },
    { "Bolstering Howl", "X", 30, 30, nil, { 1091475959, 1091475960 }, nil, "Single Target" },
    { "Staggering Claws", "W", 25, 20, nil, { 1091476353 }, nil, "Single Target" },
  } },
  { "Gorthob the Lothly", {
    { "Infesting Bite", "I", 10, 5, 3, nil, nil, "Single Target" },
    { "TBD", "C", 15, 20, nil, nil, nil, "45° by 4.5m arc from Self" },
  } },
  { "Gorthob's Tentacle", {
    { "Hulking Slam", "C", 15, 1, 4, nil, nil, "30° by 45.0m arc from Self" },
  } },
  { "TBD Skuthuk Elder", {
    { "Dazing Slam", "ISK", 20, 10, 3, nil, nil, "3.0m around Self" },
    { "Dazing Throw", "IK", 35, 20, 3, nil, nil, "Single Target" },
  } },
  { "TBD Hinderling Melee", {
    { "TBD", "I", 30, 15, 3, nil, nil, "Single Target" },
  } },
  { "TBD Mire-maggot Melee", {
    { "Poisoned Bite", "ISP", 15, 5, 3, { 1092810118 }, nil, "Single Target" },
    { "Hatch", "I", 25, 30, 3, nil, nil, "Single Target" },
  } },
}
