-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["bar_guruthos"] = {
  { "Draugrim Mauler", {
    { "Swiping Claws", "CW", 8, 3, nil, { 1090527705 }, nil, "90° by 5.0m arc from Self" },
    { "Raking Claws", "SW", 15, 7, nil, { 1090527705 }, nil, "Single Target" },
  } },
  { "Gaurhoth Pack-leader", {
    { "Tear Tendons", "SW", 10, 3, nil, { 1091405164, 1091476353 }, nil, "Single Target" },
    { "Howl of Terror", "IAS", 15, 7, 4, nil, nil, "7.0m around Self" },
  } },
  { "TBD Khurz-hai Captain", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Throw-down", "K", 60, 10, nil, nil, nil, "Single Target" },
    { "Venom Rush", "S", 60, 10, 3, nil, nil, "3.0m by 30.0m rectangle from Self" },
  } },
  { "Thothrach, Lord of Beasts", {
    { "Strike of the Undeceived", "R", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Jaws of Doom", "CF", 10, 5, 2, { 1092810118, 1090648290 }, nil, "90° by 7.0m arc from Self" },
    { "Shadow of the Moon", "ASF", 45, 10, 3, { 1092810118 }, { "eternal night eternal anguis" }, "50.0m around Self" },
    { "Bite of the Wolf-lord", "CF", 10, 5, 2, { 1090648290, 1092810118 }, nil, "45° by 5.0m arc from Self" },
    { "Shadow Rip", "SF", 30, 5, 2, { 1092810118, 1092979845, 1091476366, 1091476365, 1090648290 }, { "shadows come forth" }, "Single Target" },
    { "Illusion of the Hunter", "AS", 45, 10, nil, { 1090553956 }, { "the feeble minded are easy p" }, "50.0m around Self | 2 max targets" },
    { "Mind-rattling Howl", "AS", 30, 15, 3, { 1092810118 }, { "your minds are weak" }, "50.0m around Self" },
  } },
  { "Enraged Spirit", {
    { "Enraged Burst", "AS", 1, 30, 7, nil, nil, "20.0m around Self" },
    { "Wing Blades", "AW", 30, 7, 3, { 1090527705 }, nil, "7.0m around Self" },
  } },
  { "Corrupted Draugrim", {
    { "Corrupted Swipe", "CF", 5, 1, nil, { 1092407345 }, nil, "90° by 4.0m arc from Self" },
    { "Pouncing Strike", "IK", 15, 5, 3, nil, nil, "Single Target" },
  } },
  { "TBD Howler", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Lance of Shadow", "S", 30, 10, 3, { 1090522260 }, { "dnt lance of shadow" }, "3.0m by 50.0m rectangle from Self" },
    { "Ready to Howl", "X", 59, 0, 3, { 1091476354, 1091476366 }, { "dnt shattering howl" }, "Single Target" },
    { "Shattering Howl", "K", 30, 0, 33, { 1092404588, 1091474189 }, nil, "Single Target" },
    { "Cursed Armaments", "SF", 45, 0, 3, { 1090532173 }, { "dnt cursed armaments" }, "Single Target" },
  } },
  { "Draugrim Guard-captain", {
    { "Captain's Howl", "A", 20, 3, 3, { 1090539274 }, nil, "25.0m around Self" },
  } },
  { "Olog-hai Brute", {
    { "Slam", "AK", 10, 3, 3, nil, nil, "7.0m around Self" },
    { "Clobber", "CK", 15, 5, nil, nil, nil, "180° by 5.0m arc from Self" },
  } },
  { "Draugrim Prowler", {
    { "Raking Claws", "W", 8, 3, nil, { 1090527705 }, nil, "Single Target" },
    { "Ambush", "K", 10, 0, nil, nil, nil, "Single Target" },
    { "Pack Frenzy", "CS", 5, 3, nil, nil, nil, "45° by 5.0m arc from Self" },
  } },
  { "Khûrz-hai Berserker", {
    { "Cleaving Strike", "C", 5, 3, nil, nil, nil, "90° by 5.0m arc from Self" },
    { "Berserker Rage", "I", 15, 7, 3, { 1090553956 }, nil, "Single Target" },
    { "Axe Throw", "SW", 10, 5, nil, { 1091940897 }, nil, "Single Target" },
    { "Hacking Slash", "C", 15, 7, nil, nil, nil, "90° by 3.0m arc from Self" },
  } },
  { "TBD Cultist Captain", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Instill Fear", "F", 60, 10, 3, { 1092407345 }, { "fear grips your heart" }, "5.0m around Selection" },
  } },
  { "Gaurhoth Knight", {
    { "Grievous Bite (Distributed)", "CS", 15, 0, nil, { 1091476365, 1092830873 }, nil, "90° by 3.0m arc from Self | distributed damage" },
    { "Lone Wolf", "K", 3, 0, nil, { 1090532174 }, nil, "Single Target" },
  } },
  { "Hunting Spirit", {
    { "Hunter's Trap", "SW", 5, 0, 3, { 1091476353, 1091401111 }, nil, "Single Target" },
  } },
  { "Wave of Darkness", {
    { "Wing Blades", "AW", 30, 7, 3, { 1090527705 }, nil, "7.0m around Self" },
  } },
  { "Khashkhilar Wolf-cultist", {
    { "Curse of the Pack", "IASF", 10, 5, 3, { 1091437621 }, nil, "20.0m around Self" },
    { "Curse of the Wolf", "IASF", 15, 5, 3, { 1091437621 }, nil, "20.0m around Self" },
  } },
  { "Gaurhoth Soldier", {
    { "Howl of Rage", "I", 10, 3, 3, { 1090539274 }, nil, "Single Target" },
    { "Vicious Jaws", "CW", 15, 6, 2, { 1090527705 }, nil, "45° by 5.0m arc from Self" },
  } },
  { "Khashkhilar Captain", {
    { "Rally Allies", "IA", 20, 7, 5, { 1090541083 }, nil, "20.0m around Self" },
  } },
  { "Dúrnanc Gloom-grip", {
    { "Strike of the Undeceived", "R", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Venomous Bite", "P", 30, 5, 2, { 1092810118 }, { "dnt venomous bite" }, "Single Target" },
    { "Cursed Bite", "CS", 15, 10, 2, { 1090576545, 1093081106 }, { "dnt cursed bite" }, "45° by 7.0m arc from Self" },
    { "Foetid Breath", "ASD", 60, 20, 3, { 1092979848 }, { "dnt foetid breath" }, "50.0m around Self" },
    { "Writhing Curse", "AS", 90, 40, 3, nil, { "dnt writhing curse" }, "50.0m around Self" },
  } },
  { "Elugor the Unadorned", {
    { "Strike of the Undeceived", "R", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Rally the Horde", "AS", 60, 10, nil, { 1091941763 }, { "together we are unstoppable", "unadorned fight with me" }, "50.0m around Self" },
  } },
  { "Khashkhilar Warrior", {
    { "Rend Armour", "C", 10, 2, nil, { 1091476365 }, nil, "45° by 3.0m arc from Self" },
    { "Whirling Blades", "A", 10, 5, 2, nil, nil, "5.0m around Self" },
  } },
  { "Corrupted Gaurhoth", {
    { "Corrupted Bite", "F", 15, 3, nil, { 1092407345 }, nil, "Single Target" },
    { "Corrupted Howl", "A", 10, 5, nil, { 1092943527 }, nil, "7.0m around Self" },
  } },
  { "Olog-hai Labourer", {
    { "Crush", "K", 10, 5, nil, nil, nil, "Single Target" },
  } },
  { "Turned Khûrz-hai", {
    { "Howl of the Khûrz-hai", "IAS", 10, 5, 3, { 1090553956 }, nil, "50.0m around Self" },
    { "Unleash Fury", "AS", 2, 0, nil, nil, nil, "5.0m around Self" },
  } },
  { "TBD Draugrim Captain", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Slashing Frenzy", "CS", 60, 10, nil, nil, { "carve you up" }, "45° by 5.0m arc from Self" },
  } },
  { "Howling Spirit", {
    { "Howling Burst", "ASK", 5, 0, 3, nil, nil, "7.0m around Self" },
  } },
  { "Nascent Khûrz-hai", {
    { "Howl of the Khûrz-hai", "IAS", 10, 5, 3, { 1090553956 }, nil, "50.0m around Self" },
    { "Unleash Fury", "AS", 2, 0, nil, nil, nil, "5.0m around Self" },
  } },
  { "Draugrim Howler", {
    { "Guttural Howl", "IAS", 15, 3, 3, { 1091474189 }, nil, "60.0m around Self" },
    { "Pack Frenzy", "CS", 5, 3, nil, nil, nil, "45° by 5.0m arc from Self" },
    { "Opportunist Strike", "CS", 5, 2, nil, nil, nil, "90° by 5.0m arc from Self" },
  } },
  { "Khashkhilar Archer", {
    { "Jagged Arrow", "W", 7, 3, nil, { 1090553904 }, nil, "Single Target" },
  } },
  { "Khûrz-hai Defiler", {
    { "Spread Rot", "ISD", 15, 5, 3, { 1090535376 }, nil, "Single Target" },
    { "Spread Venom", "IP", 5, 2, 3, { 1092404193 }, nil, "Single Target" },
  } },
  { "Anguished Spirit", {
    { "Lash of Anguish", "S", 7, 5, 3, nil, nil, "1.0m by 30.0m rectangle from Self" },
  } },
  { "TBD Mauler", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Bloody Slash", "CS", 30, 15, nil, { 1090522394 }, { "dnt bloody slash" }, "90° by 5.0m arc from Self" },
    { "Pounce", "K", 60, 0, nil, { 1091404640 }, { "dnt eviscerate" }, "Single Target" },
    { "Eviscerate", "T", 60, 0, 15, { 1091479304, 1090527705 }, { "dnt eviscerate" }, "Single Target" },
  } },
  { "Mind-addled Cultist", {
    { "Sacrifice", "ASF", 10, 0, 2, { 1090552838 }, nil, "5.0m around Self" },
  } },
  { "Empowered Fell-beast", {
    { "Breath of Venom", "CSP", 20, 10, 5, { 1092407345 }, nil, "45° by 20.0m arc from Self" },
    { "Tail Swipe", "ASK", 20, 7, nil, nil, nil, "5.0m around Self" },
    { "Foul Bite", "P", 10, 3, nil, { 1092407345 }, nil, "Single Target" },
  } },
  { "Gaurhoth Flesh-shaper", {
    { "Transfusion", "WX", 7, 3, nil, { 1091401111 }, nil, "Single Target" },
    { "Call to Flesh", "SF", 15, 7, 5, { 1090555828, 1092815114 }, nil, "5.0m around Selection" },
  } },
  { "Writhing Spirit", {
    { "Writhing Torment", "AS", 5, 5, nil, nil, nil, "50.0m around Self" },
  } },
  { "Pack Spirit", {
    { "Hunter's Trap", "SW", 5, 0, 3, { 1091476353, 1091401111 }, nil, "Single Target" },
  } },
  { "Illusion of the Hunter", {
    { "Swiping Claws", "ASF", 20, 10, 3, { 1092810118 }, nil, "5.0m around Self" },
    { "Echoing Howl", "AS", 30, 0, 2, nil, nil, "50.0m around Self" },
  } },
  { "Blade of Shadow", {
    { "Blade of Shadow (Distributed)", "S", 30, 0, 8, { 1090648290 }, nil, "5.0m by 5.0m rectangle from Selection | distributed damage" },
  } },
  { "Cursed Spear", {
    { "Explosive Spear", "AS", 10, 0, 5, nil, nil, "7.0m around Self" },
    { "Cursed Shot", "S", 10, 0, 3, nil, nil, "3.0m by 50.0m rectangle from Self" },
  } },
  { "Pit-maggot", {
    { "Caustic Venom", "I", 30, 7, 3, { 1092404193 }, nil, "Single Target" },
  } },
  { "Flesh-louse", {
    { "Melt Armour", "P", 1, 0, nil, { 1091476365 }, nil, "3.0m around Self" },
    { "Piercing Shriek", "IA", 30, 7, 3, nil, nil, "15.0m around Self" },
  } },
  { "Corrupted Warg", {
    { "Hideous Cackle", "AF", 15, 3, nil, { 1090522260 }, nil, "5.0m around Self" },
    { "Corrupted Bite", "F", 10, 5, nil, { 1092407345 }, nil, "Single Target" },
  } },
  { "Khûrz-hai Labourer", {
    { "Cleaving Strike", "C", 5, 3, nil, nil, nil, "90° by 5.0m arc from Self" },
    { "Berserker Rage", "I", 15, 7, 3, { 1090553956 }, nil, "Single Target" },
  } },
  { "Jiljegish the Corpse-eater", {
    { "Flailing Tusks", "C", 15, 5, nil, nil, nil, "45° by 5.0m arc from Self" },
    { "Charging Bash", "SK", 15, 7, nil, nil, nil, "3.0m by 3.0m rectangle from Self" },
  } },
  { "Zengshash the Dank-bark", {
    { "Fungal Claw", "C", 10, 5, nil, { 1091429138 }, nil, "90° by 5.0m arc from Self" },
    { "Striking Roots", "K", 20, 10, 4, { 1091752909 }, nil, "Single Target" },
  } },
  { "Valuntor the Boulder-hide", {
    { "Desperate Shriek", "AF", 15, 5, nil, { 1091404640 }, nil, "15.0m around Self" },
    { "Kick Dust", "AP", 15, 10, nil, { 1091798510 }, nil, "7.0m around Self" },
    { "Mauling Tail", "CK", 15, 13, nil, nil, nil, "90° by 5.0m arc from Self" },
  } },
  { "Aghash the Tree-breaker", {
    { "Guttural Roar", "CSK", 30, 10, 4, nil, nil, "45° by 20.0m arc from Self" },
    { "Heavy Slam", "C", 15, 5, nil, { 1091479189 }, nil, "45° by 5.0m arc from Self" },
  } },
  { "Nazaghai the Thunderer", {
    { "Quaking Stomp", "A", 30, 10, 5, nil, nil, "15.0m around Self" },
  } },
  { "Draugrim Hunter", {
    { "Detonating Spear", "S", 15, 3, 3, nil, nil, "5.0m around Selection" },
    { "Cruel Javelin (Distributed)", "S", 15, 7, 4, nil, nil, "2.0m by 40.0m rectangle from Self | distributed damage" },
  } },
  { "Hunting Warg", {
    { "Tear Tendons", "W", 20, 5, nil, { 1091405164, 1091476353 }, nil, "Single Target" },
    { "Vicious Jaws", "CW", 15, 5, 2, { 1090527705 }, nil, "45° by 5.0m arc from Self" },
  } },
}
