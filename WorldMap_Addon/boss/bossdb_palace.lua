-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["palace"] = {
  { "Góramul Sai", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Serpent Strike", "CSW", 30, 5, 3, { 1090522394 }, { "i cannot fail the hûl" }, "90° by 5.0m arc from Self" },
    { "Spear Throw", "S", 30, 10, 5, nil, { "i cannot abandon emax dûl" }, "1.0m by 30.0m rectangle from Self" },
    { "Corrupted Strike", "CSPR", 15, 5, 4, { 1090522396, 1093065194, 1093065189, 1093065188, 1093065193, 1093065191, 1093065192, 1093065190 }, { "strike of the black serpent", "succumb to my new power" }, "45° by 7.0m arc from Self" },
  } },
  { "Ratúlko the Bloody", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Poisoned Knives", "SP", 30, 5, 2, { 1090523646 }, { "this new batch is particular", "a well tested poison hahaha" }, "Single Target" },
    { "Jagged Blade (Distributed)", "A", 30, 10, 0.5, { 1093065176, 1093065174, 1093065169, 1093065170, 1093065171, 1093065175, 1093065177, 1093065172, 1093065168, 1093065173, 1092809833 }, { "let me show you why they cal", "i ll rip you open and bleed " }, "5.0m around Self | distributed damage | 6 max targets" },
    { "Cauterize", "CSW", 45, 30, 5, { 1093065176, 1093065174, 1093065169, 1093065170, 1093065171, 1093065175, 1093065177, 1093065172, 1093065168, 1093065173 }, { "don t die yet i m not done w", "this stops the bleeding but " }, "25° by 5.0m arc from Self | 6 max targets" },
    { "Barbed Chain", "AW", 45, 20, 10, { 1092809833, 1093065176, 1093065174, 1093065169, 1093065170, 1093065171, 1093065175, 1093065177, 1093065172, 1093065168, 1093065173 }, { "come come let us know each o", "get over here hahaha" }, "50.0m around Self" },
    { "Lock Up", "E", 160, 45, nil, { 1091479052, 1091479053, 1091479054, 1091479055, 1091479056, 1090532174 }, { "i think you all need some ti", "send them to solitary confin" }, "Single Target" },
    { "Barbed Chain Throw", "A", 5, 1, nil, nil, nil, "50.0m around Self" },
  } },
  { "Dark Priestess Barkhuráni", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Gaze of the Eye", "A", 20, 10, 2, { 1093065186, 1093065184, 1093065185, 1093065182, 1093065183, 1093065180, 1093065181, 1093065187, 1093065178, 1093065179 }, { "tremble before the gaze of t", "the great eye gazes upon you" }, "50.0m around Self" },
    { "Vision of Demise", "K", 15, 0, nil, { 1090532173, 1091404060 }, { "witness your own end", "your death comes" }, "Single Target" },
    { "Vision of Demise (Distributed)", "SK", 1, 0, 4, { 1090532173, 1091404060 }, nil, "5.0m around Selection | distributed damage | 6 max targets" },
    { "Overwhelming Despair", "SKF", 20, 0, nil, { 1093032360, 1090532173, 1091404060 }, { "your sorrow fuels my power", "you cannot win there is no h" }, "Single Target" },
    { "Impending Doom", "K", 30, 0, nil, { 1090532173, 1091404060 }, { "your worst fear is made mani", "doom comes for you" }, "Single Target" },
    { "Welling Dread", "W", 8, 5, nil, { 1093065186, 1093065184, 1093065185, 1093065182, 1093065183, 1093065180, 1093065181, 1093065187, 1093065178, 1093065179, 1092407345, 1091479303 }, nil, "Single Target" },
  } },
  { "Royal Guard", {
    { "Finish Them", "K", 60, 0, nil, { 1090522394 }, nil, "Single Target" },
  } },
  { "Priest of Shadow", {
    { "Summon Shadow", "I", 60, 5, 5, nil, nil, "Single Target" },
  } },
  { "Enthralled Prisoner", {
    { "Head Crack", "KT", 30, 8, nil, nil, nil, "Single Target" },
    { "Feral Swipe", "C", 5, 3, nil, nil, nil, "45° by 5.0m arc from Self" },
  } },
  { "Utûgi Enforcer", {
    { "Massive Slam", "A", 20, 5, nil, nil, nil, "5.0m around Self" },
  } },
  { "Thothril the Entangler", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Force of Madness", "SKR", 15, 6, 4, { 1093065194, 1093065189, 1093065188, 1093065193, 1093065191, 1093065192, 1093065190 }, nil, "5.0m by 50.0m rectangle from Self" },
    { "Pull of Madness", "A", 45, 30, 6, { 1091479303 }, { "come closer little puppets", "come to me and earn your rew" }, "50.0m around Self" },
    { "a massive swipe attack", "C", 1, 0, nil, nil, nil, "45° by 7.0m arc from Self" },
  } },
  { "Utûgi Impaler", {
    { "Impaling Throw (Distributed)", "S", 20, 8, 8, nil, nil, "2.0m by 30.0m rectangle from Self | distributed damage" },
    { "Run Through", "I", 20, 3, 3, { 1090522394 }, nil, "Single Target" },
  } },
  { "Priestess of Command", {
    { "Fear of the Eye", "IA", 30, 8, 4, nil, nil, "20.0m around Self" },
  } },
  { "Enthralled Servant", {
    { "Scream of Madness", "IA", 15, 5, 4, nil, nil, "20.0m around Self" },
    { "Insane Gibbering", "F", 10, 2, nil, { 1090522260 }, nil, "Single Target" },
  } },
  { "Bloody Torturer", {
    { "Brand Stab", "W", 8, 5, 3, { 1090623585 }, nil, "2.0m by 5.0m rectangle from Self" },
    { "Brand Sweep", "C", 5, 3, nil, nil, nil, "45° by 5.0m arc from Self" },
  } },
  { "Animated Armour", {
    { "Armoured Slam", "K", 15, 5, nil, nil, nil, "Single Target" },
    { "Clattering Armour", "IAR", 30, 30, 3, { 1093065194, 1093065189, 1093065188, 1093065193, 1093065191, 1093065192, 1093065190 }, nil, "50.0m around Self" },
  } },
  { "Animated Weapon", {
    { "a massive melee attack", "T", 1, 0, nil, nil, nil, "Single Target" },
  } },
  { "Palace Sentry", {
    { "Take Aim", "I", 20, 5, 4, nil, nil, "Single Target" },
    { "Call Reinforcements", "I", 120, 0, 5, nil, nil, "Single Target" },
  } },
  { "Shadow Terror", {
    { "Grip of Fear", "IAS", 10, 5, 3, nil, nil, "50.0m around Self" },
  } },
  { "Palace Guard", {
    { "Shield Slam", "T", 20, 5, nil, nil, nil, "Single Target" },
    { "Gouge Armour", "W", 30, 2, nil, { 1091476365 }, nil, "Single Target" },
  } },
  { "Guard Captain", {
    { "Defensive Order", "A", 30, 5, nil, { 1091475960 }, nil, "20.0m around Self" },
    { "Offensive Order", "AF", 30, 10, nil, { 1092973472 }, nil, "20.0m around Self" },
    { "Call Target", "SF", 60, 15, nil, { 1090553915 }, nil, "Single Target" },
  } },
  { "Shadow Seeker", {
    { "Shadow Pulse", "A", 3, 1, nil, nil, nil, "50.0m around Self" },
  } },
  { "Animated Ooze", {
    { "Acid Splash", "CS", 15, 5, nil, { 1091510188 }, nil, "45° by 7.0m arc from Self" },
    { "Chemical Reaction", "IAS", 1, 0, 10, nil, nil, "50.0m around Self" },
  } },
  { "Corrupted Spear", {
    { "Animated Spear Throw", "S", 1, 0, 3, nil, nil, "1.0m by 50.0m rectangle from Self" },
  } },
}
