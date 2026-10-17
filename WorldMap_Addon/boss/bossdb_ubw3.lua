-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["ubw3"] = {
  { "Gârash, the Emptiness", {
    { "Purge Hope", "F", 30, 28, 5, { 1090532791, 1091404640 }, nil, "0.7m by 30.0m rectangle from Self" },
    { "True Despair", "AF", 10, 5, nil, { 1092995854, 1092995880, 1092995873, 1092995875, 1092995904, 1092995856 }, nil, "30.0m around Self | 1 max targets" },
    { "Consume to Emptiness", "F", 90, 0, 28, { 1092406491, 1092404096, 1092995854, 1092995880, 1092995873, 1092995875, 1092995904, 1092995856, 1093004346, 1093004352, 1093004323, 1093004342, 1093004335, 1093004339, 1093004349, 1093004331, 1093004326, 1093004325, 1092995898, 1092995885, 1092995852, 1092995877, 1092995907, 1092995897 }, nil, "Single Target" },
    { "Weaken Resolve", "A", 35, 27, nil, nil, { "gârash weakens null s will " }, "50.0m around Self | 5 max targets" },
    { "Purge the Hopeless", "A", 45, 60, 3, nil, { "gârash purges your hope" }, "50.0m around Self | 3 max targets" },
    { "Disease the World", "A", 25, 27, nil, nil, { "gârash unleashes disease up" }, "50.0m around Self | 3 max targets" },
    { "Cleave (Distributed)", "C", 2, 25, nil, nil, nil, "90° by 7.0m arc from Self | distributed damage" },
  } },
  { "Sorcerer of Sagush", {
    { "Fashion the Shadow", "I", 25, 2, 3, nil, nil, "Single Target" },
    { "Shadow Consumes You", "F", 6, 5, nil, { 1091570816, 1091609147 }, nil, "Single Target" },
    { "Ancient Fury", "I", 15, 5, 3, { 1091479052 }, nil, "Single Target" },
    { "Corrupted Earth", "I", 25, 10, 10, { 1091611526 }, nil, "Single Target" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
  } },
  { "Warden of Thahar", {
    { "Cleaving Shadows", "C", 15, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Shadow's Grasp", "W", 6, 6, nil, { 1092402514 }, nil, "Single Target" },
    { "Cleave Foes", "C", 1, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Barbed Arrow", "SW", 10, 8, 2, { 1090531521 }, nil, "Single Target" },
    { "Brutal Arrow", "K", 12, 8, 2, nil, nil, "Single Target" },
    { "Shadow Burst", "A", 10, 5, nil, nil, nil, "7.0m around Self" },
  } },
  { "Azagath Sea-shadow", {
    { "Exploit Opportunity", "SWP", 5, 0, nil, { 1091429145, 1090553915, 1091657099 }, nil, "Single Target" },
    { "The Subtle Death", "FPD", 25, 5, nil, { 1092402633, 1091609004, 1091609074 }, nil, "Single Target" },
    { "Frost Swipe (Distributed)", "C", 2, 0, nil, nil, nil, "180° by 4.0m arc from Self | distributed damage | 6 max targets" },
    { "Acid Swipe (Distributed)", "C", 2, 0, nil, nil, nil, "180° by 4.0m arc from Self | distributed damage | 6 max targets" },
    { "Shadow Swipe (Distributed)", "C", 2, 0, nil, nil, nil, "180° by 4.0m arc from Self | distributed damage | 6 max targets" },
    { "Throat Cut", "SW", 34, 12, 2, { 1091478600 }, nil, "Single Target" },
    { "Assassin's Blade", "S", 20, 15, 5, nil, nil, "4.0m around Selection | distributed damage | 8 max targets" },
  } },
  { "Azagath's Malice", {
    { "Stinging Swipe", "C", 1, 0, nil, nil, nil, "90° by 4.5m arc from Self | 6 max targets" },
    { "Bruise to the Bone", "W", 17, 17, nil, { 1091425403 }, { "right to the bone" }, "Single Target" },
    { "Cold Heart", "F", 22, 4, nil, { 1091609074 }, nil, "Single Target" },
  } },
  { "Thahar", {
    { "Plague Sweep", "C", 4, 0, nil, nil, nil, "120° by 4.5m arc from Self | distributed damage" },
    { "Plague Sweep (Back)", "C", 6, 0, nil, nil, nil, "120° by 4.5m arc from Self with 180° offset | distributed damage" },
    { "Infectious Grip", "S", 30, 0, nil, nil, { "disease consumes you" }, "7.0m around Selection | 2 max targets" },
    { "Poison the Earth", "A", 25, 6, nil, { 1090522617 }, { "the ground festers with dise" }, "40.0m around Self | 4 max targets" },
    { "Plague Breath", "P", 25, 0, nil, { 1090555828 }, nil, "Single Target" },
  } },
  { "Sage of Sagush", {
    { "Renew Flesh", "I", 4, 0, 3, { 1091570800 }, nil, "Single Target" },
    { "From Death, Life", "IA", 15, 0, 3, nil, nil, "10.0m around Self | 2 max targets" },
    { "Sloughing Disease", "A", 18, 5, nil, { 1090555828 }, nil, "40.0m around Self | 2 max targets" },
    { "Tangled Shadow", "S", 15, 10, nil, { 1091429124 }, nil, "5.0m around Selection" },
    { "Death Grip", "K", 20, 10, nil, nil, nil, "Single Target" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
  } },
  { "Sagush", {
    { "Shadow Blades", "I", 2, 0, 3, nil, nil, "Single Target" },
    { "Sweeping Umbra", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Sweeping Umbra (Back)", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self with 180° offset" },
    { "Enveloping Shadow", "F", 25, 0, nil, { 1091581393 }, { "be consumed by shadow" }, "Single Target" },
  } },
  { "Azagath's Mettle", {
    { "Swipe", "C", 3, 0, nil, nil, nil, "45° by 4.5m arc from Self | 6 max targets" },
    { "Shadow Strike", "SF", 16, 0, nil, { 1090532173, 1092402986 }, { "fall to shadow" }, "Single Target" },
    { "Concuss", "IK", 18, 10, 3, { 1091429153 }, { "your mind is broken" }, "Single Target" },
  } },
  { "Azagath's Cunning", {
    { "Poison Dagger", "SP", 3, 0, nil, { 1090555828 }, nil, "Single Target" },
    { "Poison Spike", "SP", 14, 0, nil, { 1091657100, 1091657099, 1091657098, 1091659752 }, nil, "Single Target" },
    { "Slicing Throw", "W", 8, 8, nil, { 1091468392 }, { "taste my blade" }, "Single Target" },
    { "Impaling Throw", "I", 18, 0, 4, nil, { "i will gut you" }, "Single Target" },
    { "Slit Throat", "W", 20, 18, nil, { 1090527705 }, { "i ll cut your necks" }, "Single Target" },
  } },
  { "Bow-master of Thahar", {
    { "Poisoned Dagger", "I", 15, 2, 3, nil, nil, "Single Target" },
    { "Debilitating Wound", "I", 8, 4, 4, nil, nil, "Single Target" },
    { "Focused Shot", "I", 15, 8, 10, nil, nil, "Single Target" },
    { "Enraged Shot", "E", 3, 5, 1, { 1091401433, 1090522261 }, nil, "Single Target" },
  } },
  { "Nodule of Madness", {
    { "Detonating Confusion", "SKF", 15, 1, nil, { 1092995854, 1092995880, 1092995873, 1092995875, 1092995904, 1092995856 }, nil, "Single Target" },
  } },
  { "Nodule of Dread", {
    { "Detonating Mortality", "SF", 2, 4, nil, { 1092995854, 1092995880, 1092995873, 1092995875, 1092995904, 1092995856 }, nil, "Single Target" },
  } },
  { "Nodule of Disease", {
    { "Detonating Contagion", "SKF", 15, 1, nil, { 1092995854, 1092995880, 1092995873, 1092995875, 1092995904, 1092995856 }, nil, "Single Target" },
  } },
  { "Plague Vortex", {
    { "Explosive Plague (Distributed)", "A", 2, 1, nil, nil, nil, "5.0m around Self | distributed damage | 6 max targets" },
    { "Void Blast (Distributed)", "SF", 15, 0, 3, { 1090532791, 1091404640 }, nil, "0.7m by 30.0m rectangle from Self | distributed damage" },
    { "Plague Eruption", "A", 10, 20, 5, nil, nil, "7.0m around Self" },
  } },
  { "Shadow Vortex", {
    { "Explosive Umbra (Distributed)", "A", 2, 1, nil, nil, nil, "5.0m around Self | distributed damage | 6 max targets" },
    { "Void Blast (Distributed)", "SF", 15, 0, 3, { 1090532791, 1091404640 }, nil, "0.7m by 30.0m rectangle from Self | distributed damage" },
    { "Shadow Eruption", "A", 10, 20, 5, nil, nil, "7.0m around Self" },
  } },
  { "Azagath's Will", {
    { "Will of the Sea-shadow", "I", 1, 0, 10, nil, { "by my will my body and mind " }, "20.0m around Selection" },
  } },
  { "Plaguestorm", {
    { "Explosive Plague (Distributed)", "A", 2, 1, nil, nil, nil, "5.0m around Self | distributed damage | 6 max targets" },
    { "Void Blast (Distributed)", "SF", 15, 0, 3, { 1090532791, 1091404640 }, nil, "0.7m by 30.0m rectangle from Self | distributed damage" },
    { "Plague Eruption", "A", 10, 20, 5, nil, nil, "7.0m around Self" },
  } },
  { "Umbrastorm", {
    { "Explosive Umbra (Distributed)", "A", 2, 1, nil, nil, nil, "5.0m around Self | distributed damage | 6 max targets" },
    { "Void Blast (Distributed)", "SF", 15, 0, 3, { 1090532791, 1091404640 }, nil, "0.7m by 30.0m rectangle from Self | distributed damage" },
    { "Shadow Eruption", "A", 10, 20, 5, nil, nil, "7.0m around Self" },
  } },
}
