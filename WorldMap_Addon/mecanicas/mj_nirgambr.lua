-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["nirgambr"] = {
  { "Sakhârshag", {
    { "Sweeping Strike", "C", 3, 0, nil, nil, nil, nil, { "Golpe de barrido" } },
    { "Great Slam", "CG", 8, 10, nil, nil, nil },
    { "Caustic Bile", "CS", 15, 10, { 1090555828 }, { "my gift to you", "mi regalo para ti" }, nil, nil, { "Bilis Cáustica" } },
    { "Curse of Pain", "SW", 16, 8, { 1092979847 }, { "spread my gift", "difunde mi regalo" }, nil },
    { "Deep Inhale", "A", 40, 20, nil, { "my gifts for all", "mis regalos para todos", "breathe deep", "respira profundo" }, nil, nil, { "Inhalación profunda" } },
    { "Cavernous Shout", "IA", 40, 20, { 1092997788 }, { "my gifts for all", "mis regalos para todos", "breathe deep", "respira profundo" }, nil, nil, { "Grito Cavernoso" } },
  } },
  { "Imanak-tûr", {
    { "Sweeping Sands", "C", 2, 0, nil, nil, nil, nil, { "Arenas Barridas" } },
    { "Scouring Sands", "W", 16, 8, { 1090522394 }, nil, nil },
    { "Stinging Sands", "A", 28, 8, { 1092401721 }, nil, nil, nil, { "Arenas Punzantes" } },
  } },
  { "Aratûg", {
    { "Death Burst", "A", 20, 20, nil, { "my little gift", "mi pequeño regalo" }, nil },
    { "Explosive Strike", "K", 20, 15, nil, { "make them fly", "hazlos volar", "send them below", "envíalos abajo" }, nil, nil, { "Golpe Explosivo" } },
    { "Sweeping Strike", "C", 5, 0, nil, nil, nil, nil, { "Golpe de barrido" } },
  } },
  { "Nirgambâr Crypt-horror", {
    { "Diseased Roar", "LD", -1, 0, { 1090522616 }, nil, nil, nil, { "Rugido enfermizo" } },
  } },
  { "Vengeful Nirgambâr Spirit", {
    { "Submerging...", "I", -1, 0, nil, nil, nil },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
  } },
  { "Cursed Nirgambâr Spirit", {
    { "Sacrifice", "AK", 1, 1, nil, nil, nil, nil, { "Sacrificio" } },
  } },
  { "Wretched Nirgambâr Spirit", {
    { "Submerging...", "I", -1, 0, nil, nil, nil },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
  } },
  { "Dreadful Nirgambâr Spirit", {
    { "Submerging...", "I", -1, 0, nil, nil, nil },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
  } },
}
