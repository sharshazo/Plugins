-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["hold"] = {
  { "Rátinur", {
    { "Rain of Arrows", "IA", 40, 40, 4, nil, { "there is no cover" }, "40.0m around Self" },
  } },
  { "Gáthtrag Gloomhammer", {
    { "Harsh Call", "IA", 20, 10, 5, nil, { "how unfortunate" }, "5.0m around Self" },
    { "Smashed Bones", "W", 20, 15, nil, { 1091657097 }, { "ah a worthy target" }, "Single Target" },
    { "a weak swipe attack", "C", 3, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a moderate swipe attack", "C", 3, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a strong swipe attack", "C", 6, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Sorceress Ombátha", {
    { "Fountains of Blood", "A", 45, 15, 15, nil, { "blood shall rise", "blood come forth" }, "40.0m around Self" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "Boil Blood!", "A", 45, 12, 2, { 1090539333 }, nil, "40.0m around Self" },
  } },
  { "Râkdakul", {
    { "Powerful Shout", "IAW", 20, 5, 3, { 1090539333 }, nil, "40.0m around Self" },
    { "Smashed Bones", "W", 30, 25, nil, { 1091657097 }, nil, "Single Target" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a strong swipe attack", "C", 6, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a weak swipe attack", "C", 1, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Ordâkhai Sorcerer", {
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "Weak Ordâkhai Blessing", "I", 20, 5, 3, { 1092403827 }, nil, "Single Target" },
  } },
  { "Orc Captain", {
    { "Blistering Derision", "I", 20, 10, 3, nil, nil, "Single Target" },
  } },
  { "Orc Berserker", {
    { "a weak swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a minor swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a mighty swipe attack", "C", 0, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "Armour Smash", "WT", 30, 5, nil, { 1091570816 }, nil, "Single Target" },
    { "Cleaving Strike", "C", 30, 10, nil, nil, nil, "90° by 5.0m arc from Self" },
    { "Jagged Cut", "CSW", 15, 0, nil, { 1090553355 }, nil, "120° by 4.5m arc from Self" },
  } },
  { "Ordâkhai Warrior", {
    { "Jagged Cut", "C", 10, 5, nil, nil, nil, "120° by 4.5m arc from Self" },
  } },
  { "Orc Archer", {
    { "Poisoned Dart", "ISP", 20, 0, 3, { 1090523646 }, nil, "Single Target" },
  } },
  { "Utûgi Destroyer", {
    { "Cleaving Strike", "C", 5, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
  } },
  { "Ordâkhai Sorceress", {
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "Boil Blood!", "A", 20, 10, 2, { 1090539333 }, nil, "60.0m around Self" },
    { "Weak Ordâkhai Blessing", "I", 20, 5, 3, { 1092403827 }, nil, "Single Target" },
  } },
  { "Utûgi Slaughterer", {
    { "Harsh Call", "IA", 20, 10, 5, nil, nil, "10.0m around Self" },
    { "a moderate swipe attack", "C", 5, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a strong swipe attack", "C", 7, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Ordâkhai Look-out", {
    { "Piercing Arrow", "W", 10, 5, nil, { 1090555713 }, nil, "Single Target" },
  } },
  { "Wretched Spirit", {
    { "Self Immolation", "A", 60, 60, 3, nil, nil, "40.0m around Self" },
  } },
}
