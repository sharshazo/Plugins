-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["caves"] = {
  { "Giríshu, Thief of Blades", {
    { "Flesh Rend", "W", 18, 5, nil, { 1090522395 }, { "i won t miss my mark" }, "Single Target" },
    { "Battering Blades", "CS", 8, 2, nil, nil, { "my blades will find you", "i am an artist with these bl" }, "90° by 5.0m arc from Self" },
    { "Blade-storm", "IA", 60, 50, 5, nil, nil, "60.0m around Self" },
    { "a weak melee attack", "W", 2, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
    { "a minor melee attack", "W", 2, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
    { "a moderate melee attack", "W", 2, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
    { "a mighty melee attack", "W", 0, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
  } },
  { "Pakhán-gebar, Servant of Stone", {
    { "Whirling Dervish", "K", 45, 0, nil, { 1090541206 }, { "storms to me" }, "Single Target" },
  } },
  { "Molbása the Untamed", {
    { "Sand Blast", "A", 15, 0, 3, nil, nil, "10.0m around Self" },
  } },
  { "Bârlat the Bold", {
    { "Fissure of Wealth", "S", 15, 10, 2.5, nil, { "feel the sting of riches" }, "1.0m by 12.0m rectangle from Self" },
    { "Gold Pile (Distributed)", "S", 25, 3, 3, nil, { "you want my treasure so badl" }, "2.2m around Selection | distributed damage" },
    { "a weak melee attack", "W", 2, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
    { "a minor melee attack", "W", 2, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
    { "a moderate melee attack", "W", 2, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
    { "a mighty melee attack", "W", 0, 0, nil, { 1090523647, 1090529420 }, nil, "Single Target" },
  } },
  { "Samâshu, Thief of Blight", {
    { "Poisoned Blades", "SP", 16, 4, nil, { 1090522398 }, { "are you feeling unwell" }, "Single Target" },
    { "Pestilent Apocalypse", "I", 60, 30, 5, { 1090522396 }, nil, "Single Target" },
  } },
  { "Bârlat's Rat-master", {
    { "Wasting Sickness", "D", 0, 0, nil, { 1091401231 }, nil, "Single Target" },
    { "Diseased Frailty", "D", 0, 0, nil, { 1090522616 }, nil, "Single Target" },
    { "Greater Wasting Sickness", "D", 0, 0, nil, { 1091401231 }, nil, "Single Target" },
    { "Greater Diseased Frailty", "D", 0, 0, nil, { 1090522616 }, nil, "Single Target" },
    { "Festering disease", "K", 0, 0, nil, { 1090522617 }, nil, "Single Target" },
    { "Summon Rat", "I", -1, 0, 1.5, nil, nil, "Single Target" },
    { "Lesser Wasting Sickness", "D", 0, 0, nil, { 1091401231 }, nil, "Single Target" },
    { "Lesser Diseased Frailty", "D", 0, 0, nil, { 1090522616 }, nil, "Single Target" },
  } },
  { "Bârlat's Tough", {
    { "Seeping Wound", "SW", 30, 2, nil, { 1091401111 }, nil, "Single Target" },
  } },
  { "Bârlat's Overseer", {
    { "a weak swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a minor swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a mighty swipe attack", "C", 0, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "Cry of Battle", "A", 60, 14, 3, { 1091941763 }, nil, "31.0m around Self" },
    { "Call for Blood", "I", 140, 12, 3, nil, nil, "Single Target" },
    { "Impaling Strike", "CS", 18, 8, 3, nil, nil, "100° by 6.0m arc from Self" },
    { "Blade Sweep", "C", 12, 6, 2.5, nil, nil, "120° by 7.0m arc from Self" },
  } },
  { "Gizûshu, Thief of Shadows", {
    { "Instilled Panic", "K", 20, 15, nil, { 1090528811 }, { "a ready companion" }, "Single Target" },
    { "Gathering Shadows", "IA", 60, 40, 5, nil, nil, "60.0m around Self" },
  } },
  { "Bârlat's Apothecary", {
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "Dark Graft", "I", 15, 0, 4, nil, nil, "Single Target" },
    { "Nightmare Borne", "IF", 45, 12, 4, { 1090532173 }, nil, "Single Target" },
  } },
  { "Vicious Rats", {
    { "Plague Bite", "D", -1, 0, nil, { 1090575029 }, nil, "Single Target" },
  } },
  { "Grasping Shadows", {
    { "Plunging Darkness", "A", 3, 35, 3, nil, nil, "80.0m around Self" },
  } },
}
