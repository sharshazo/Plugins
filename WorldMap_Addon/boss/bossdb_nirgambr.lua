-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["nirgambr"] = {
  { "Sakhârshag", {
    { "Sweeping Strike", "C", 3, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Great Slam", "C", 8, 10, 2, nil, nil, "120° by 6.0m arc from Self | distributed damage" },
    { "Caustic Bile", "CS", 15, 10, 3, { 1090555828 }, { "my gift to you" }, "40° by 30.0m arc from Self" },
    { "Curse of Pain", "SW", 16, 8, 1, { 1092979847 }, { "spread my gift" }, "Single Target" },
    { "Deep Inhale", "A", 40, 20, nil, nil, { "my gifts for all", "breathe deep" }, "50.0m around Self" },
    { "Cavernous Shout", "IA", 40, 20, 5, { 1092997788 }, { "my gifts for all", "breathe deep" }, "50.0m around Self" },
  } },
  { "Imanak-tûr", {
    { "Sweeping Sands", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Scouring Sands", "W", 16, 8, 2, { 1090522394 }, nil, "Single Target" },
    { "Stinging Sands", "A", 28, 8, 4, { 1092401721 }, nil, "7.0m around Self" },
  } },
  { "Aratûg", {
    { "Death Burst", "A", 20, 20, 3, nil, { "my little gift" }, "50.0m around Self" },
    { "Explosive Strike", "K", 20, 15, nil, nil, { "make them fly", "send them below" }, "Single Target" },
    { "Sweeping Strike", "C", 5, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
  } },
  { "Nirgambâr Crypt-horror", {
    { "Diseased Roar", "D", -1, 0, nil, { 1090522616 }, nil, "6.0m by 10.0m rectangle from Self" },
  } },
  { "Vengeful Nirgambâr Spirit", {
    { "Submerging...", "I", -1, 0, 3, nil, nil, "Single Target" },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil, "5.0m around Self" },
  } },
  { "Nirgambâr Crypt-guardian", {
    { "a moderate swipe attack", "C", 10, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Cursed Nirgambâr Spirit", {
    { "Sacrifice", "AK", 1, 1, 10, nil, nil, "50.0m around Self" },
  } },
  { "Wretched Nirgambâr Spirit", {
    { "Submerging...", "I", -1, 0, 3, nil, nil, "Single Target" },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil, "5.0m around Self" },
  } },
  { "Nirgambâr Crypt-champion", {
    { "a moderate swipe attack", "C", 10, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Dreadful Nirgambâr Spirit", {
    { "Submerging...", "I", -1, 0, 3, nil, nil, "Single Target" },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil, "5.0m around Self" },
  } },
  { "Nirgambâr Crypt-sentinel", {
    { "a ranged double attack", "I", 10, 0, 3, nil, nil, "Single Target" },
  } },
}
