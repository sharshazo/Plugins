-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["hold"] = {
  { "Rátinur", {
    { "Rain of Arrows", "IA", 40, 40, nil, { "there is no cover" }, nil, nil, { "Lluvia de flechas" } },
    { "Powerful Shot", "L", 20, 10, nil, nil, nil },
  } },
  { "Gáthtrag Gloomhammer", {
    { "Harsh Call", "IA", 20, 10, nil, { "how unfortunate", "qué desafortunado" }, nil },
    { "Smashed Bones", "W", 20, 15, { 1091657097 }, { "ah a worthy target", "ah un objetivo digno" }, nil, nil, { "Huesos destrozados" } },
  } },
  { "Sorceress Ombátha", {
    { "Fountains of Blood", "A", 45, 15, nil, { "blood shall rise", "la sangre se alzará", "blood come forth", "sangre ven a mí" }, nil, nil, { "Fuentes de sangre" } },
    { "Boil Blood!", "A", 45, 12, nil, nil, nil, nil, { "¡Hervir sangre!" } },
  } },
  { "Râkdakul", {
    { "Defender's Strike", "L", 30, 20, nil, { "a worthy target", "un objetivo digno" }, nil, nil, { "Golpe del defensor" } },
    { "Powerful Shout", "IAW", 20, 5, { 1090539333 }, nil, nil, nil, { "Grito poderoso" } },
    { "Smashed Bones", "W", 30, 25, { 1091657097 }, nil, nil, nil, { "Huesos destrozados" } },
  } },
  { "Ordâkhai Sorcerer", {
    { "Weak Ordâkhai Blessing", "I", 20, 5, { 1092403827 }, nil, nil, nil, { "Bendición Débil de Ordâkhai" } },
    { "Shadow Burst (distributed)", "G", 10, 0, nil, nil, nil },
  } },
  { "Orc Captain", {
    { "Blistering Derision", "I", 20, 10, nil, nil, nil, nil, { "Burla abrasadora" } },
  } },
  { "Orc Berserker", {
    { "Armour Smash", "WT", 30, 5, { 1091570816 }, nil, nil },
    { "Cleaving Strike", "C", 30, 10, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Jagged Cut", "CSW", 15, 0, { 1090553355 }, nil, nil, nil, { "Corte Dentado" } },
  } },
  { "Ordâkhai Warrior", {
    { "Jagged Cut", "C", 10, 5, nil, nil, nil, nil, { "Corte Dentado" } },
    { "Reaching Attack", "L", 10, 5, nil, nil, nil },
  } },
  { "Ordâkhai Look-out", {
    { "Powerful Shot", "L", 20, 10, nil, nil, nil },
    { "Piercing Arrow", "W", 10, 5, { 1090555713 }, nil, nil, nil, { "Flecha perforante" } },
  } },
  { "Orc Archer", {
    { "Poisoned Dart", "ISP", 20, 0, { 1090523646 }, nil, nil, nil, { "Dardo envenenado" } },
  } },
  { "Utûgi Destroyer", {
    { "Cleaving Strike", "C", 5, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
  } },
  { "Ordâkhai Sorceress", {
    { "Boil Blood!", "A", 20, 10, nil, nil, nil, nil, { "¡Hervir sangre!" } },
    { "Weak Ordâkhai Blessing", "I", 20, 5, { 1092403827 }, nil, nil, nil, { "Bendición Débil de Ordâkhai" } },
    { "Shadow Burst (distributed)", "G", 10, 0, nil, nil, nil },
  } },
  { "Utûgi Slaughterer", {
    { "Harsh Call", "IA", 20, 10, nil, nil, nil },
  } },
  { "Wretched Spirit", {
    { "Self Immolation", "A", 60, 60, nil, nil, nil, nil, { "Autoinmolación" } },
  } },
}
