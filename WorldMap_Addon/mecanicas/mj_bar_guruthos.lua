-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["bar_guruthos"] = {
  { "Draugrim Mauler", {
    { "Swiping Claws", "CW", 8, 3, { 1090527705 }, nil, nil, nil, { "Garras cortantes", "Garras Cortantes" } },
    { "Raking Claws", "SW", 15, 7, { 1090527705 }, nil, nil, nil, { "Garras desgarradoras" } },
  } },
  { "Gaurhoth Pack-leader", {
    { "Tear Tendons", "SW", 10, 3, { 1091405164, 1091476353 }, nil, nil, nil, { "Desgarro de tendones" } },
    { "Howl of Terror", "IAS", 15, 7, nil, nil, nil, nil, { "Aullido de terror" } },
  } },
  { "TBD Khurz-hai Captain", {
    { "Throw-down", "K", 60, 10, nil, nil, nil, nil, { "Derribo" } },
    { "Venom Rush", "LS", 60, 10, nil, nil, nil },
  } },
  { "Thothrach, Lord of Beasts", {
    { "Jaws of Doom", "CF", 10, 5, { 1092810118, 1090648290 }, nil, nil, nil, { "Mandíbulas de la perdición" } },
    { "Shadow of the Moon", "ASF", 45, 10, { 1092810118 }, { "eternal night eternal anguish" }, nil, nil, { "Sombra de la Luna", "Sombra de la luna" } },
    { "Bite of the Wolf-lord", "CF", 10, 5, { 1090648290, 1092810118 }, nil, nil, nil, { "Mordisco del señor lobo" } },
    { "Shadow Rip", "SF", 30, 5, { 1092810118, 1092979845, 1091476366, 1091476365, 1090648290 }, { "shadows come forth" }, nil, nil, { "Desgarro de sombras" } },
    { "Illusion of the Hunter", "AS", 45, 10, { 1090553956 }, { "the feeble minded are easy prey" }, nil, nil, { "Ilusión del cazador" } },
    { "Mind-rattling Howl", "AS", 30, 15, { 1092810118 }, { "your minds are weak" }, nil },
  } },
  { "Enraged Spirit", {
    { "Enraged Burst", "AS", 1, 30, nil, nil, nil },
    { "Wing Blades", "AW", 30, 7, { 1090527705 }, nil, nil },
  } },
  { "Corrupted Draugrim", {
    { "Corrupted Swipe", "CF", 5, 1, { 1092407345 }, nil, nil },
    { "Pouncing Strike", "IK", 15, 5, nil, nil, nil },
  } },
  { "TBD Howler", {
    { "Lance of Shadow", "LS", 30, 10, nil, nil, nil, nil, { "Lanza de la sombra", "Lanza de sombra", "Lanza de Sombra", "Lanza de la Sombra" } },
    { "Ready to Howl", "X", 59, 0, { 1091476354, 1091476366 }, nil, nil, nil, { "Listo para Howl", "Listo para aullar" } },
    { "Cursed Armaments", "SF", 45, 0, { 1090532173 }, nil, nil },
  } },
  { "Olog-hai Brute", {
    { "Slam", "AK", 10, 3, nil, nil, nil },
    { "Clobber", "CK", 15, 5, nil, nil, nil, nil, { "Apalear" } },
  } },
  { "Draugrim Prowler", {
    { "Raking Claws", "W", 8, 3, { 1090527705 }, nil, nil, nil, { "Garras desgarradoras" } },
    { "Ambush", "K", 10, 0, nil, nil, nil, nil, { "Emboscada" } },
    { "Pack Frenzy", "CS", 5, 3, nil, nil, nil, nil, { "Frenesí de la manada" } },
  } },
  { "Khûrz-hai Berserker", {
    { "Cleaving Strike", "C", 5, 3, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Berserker Rage", "I", 15, 7, { 1090553956 }, nil, nil, nil, { "Furia berserker" } },
    { "Axe Throw", "SW", 10, 5, { 1091940897 }, nil, nil, nil, { "Lanzamiento de hacha", "Lanzamiento de Hacha" } },
    { "Hacking Slash", "C", 15, 7, nil, nil, nil, nil, { "Corte de hacha" } },
  } },
  { "TBD Cultist Captain", {
    { "Instill Fear", "F", 60, 10, { 1092407345 }, { "fear grips your heart", "el miedo se apodera de tu coraz�" }, nil, nil, { "Infundir Miedo" } },
  } },
  { "Gaurhoth Knight", {
    { "Grievous Bite (Distributed)", "CG", 15, 0, { 1091476365, 1092830873 }, nil, nil, nil, { "Mordisco grave (Distribuido)", "Mordisco Grave (Distribuido)" } },
    { "Lone Wolf", "K", 3, 0, { 1090532174 }, nil, nil, nil, { "Lobo solitario", "Lobo Solitario" } },
  } },
  { "Hunting Spirit", {
    { "Hunter's Trap", "SW", 5, 0, { 1091476353, 1091401111 }, nil, nil, nil, { "Trampa del cazador" } },
  } },
  { "Wave of Darkness", {
    { "Wing Blades", "AW", 30, 7, { 1090527705 }, nil, nil },
  } },
  { "Khashkhilar Wolf-cultist", {
    { "Curse of the Pack", "IASF", 10, 5, { 1091437621 }, nil, nil, nil, { "Cursa del paquete", "Maldición de la manada" } },
    { "Curse of the Wolf", "IASF", 15, 5, { 1091437621 }, nil, nil, nil, { "La maldición del lobo", "Maldición del lobo", "Maldición del Lobo" } },
  } },
  { "Gaurhoth Soldier", {
    { "Howl of Rage", "I", 10, 3, { 1090539274 }, nil, nil, nil, { "Aullido de la ira" } },
    { "Vicious Jaws", "CW", 15, 6, { 1090527705 }, nil, nil },
  } },
  { "Khashkhilar Captain", {
    { "Rally Allies", "I", 20, 7, nil, nil, nil, nil, { "Reunir aliados" } },
  } },
  { "Dúrnanc Gloom-grip", {
    { "Venomous Bite", "P", 30, 5, { 1092810118 }, nil, nil, nil, { "Mordedura Venenosa", "Mordedura venenosa" } },
    { "Cursed Bite", "CS", 15, 10, { 1090576545, 1093081106 }, nil, nil, nil, { "Mordisco maldito" } },
    { "Foetid Breath", "ASD", 60, 20, { 1092979848 }, nil, nil, nil, { "Aliento fétido" } },
    { "Writhing Curse", "AS", 90, 40, nil, nil, nil, nil, { "Maldición retorcida" } },
  } },
  { "Elugor the Unadorned", {
    { "Ravage", "G", 30, 15, nil, { "you are nothing" }, nil, nil, { "Devastación" } },
  } },
  { "Khashkhilar Warrior", {
    { "Rend Armour", "C", 10, 2, { 1091476365 }, nil, nil, nil, { "Desgarrar Armadura 3", "Desgarrar Armadura 6", "Desgarrar Armadura 10", "Desgarrar Armadura 5", "Desgarrar Armadura 8", "Desgarrar Armadura 7", "Desgarrar Armadura 2", "Desgarrar Armadura 9", "Desgarrar Armadura 1", "Desgarrar Armadura 4", "Desgarrar armadura" } },
    { "Whirling Blades", "A", 10, 5, nil, nil, nil, nil, { "Cuchillas giratorias" } },
  } },
  { "Corrupted Gaurhoth", {
    { "Corrupted Bite", "F", 15, 3, { 1092407345 }, nil, nil, nil, { "Mordisco corrupto" } },
  } },
  { "Olog-hai Labourer", {
    { "Crush", "K", 10, 5, nil, nil, nil, nil, { "Aplastar" } },
  } },
  { "Turned Khûrz-hai", {
    { "Howl of the Khûrz-hai", "I", 10, 5, { 1090553956 }, nil, nil, nil, { "Aullido de los Khûrz-hai" } },
    { "Unleash Fury", "AS", 2, 0, nil, nil, nil, nil, { "Desatar furia" } },
  } },
  { "TBD Draugrim Captain", {
    { "Slashing Frenzy", "CS", 60, 10, nil, { "carve you up" }, nil },
  } },
  { "Howling Spirit", {
    { "Howling Burst", "ASK", 5, 0, nil, nil, nil },
  } },
  { "Nascent Khûrz-hai", {
    { "Howl of the Khûrz-hai", "I", 10, 5, { 1090553956 }, nil, nil, nil, { "Aullido de los Khûrz-hai" } },
    { "Unleash Fury", "AS", 2, 0, nil, nil, nil, nil, { "Desatar furia" } },
  } },
  { "Draugrim Howler", {
    { "Guttural Howl", "IAS", 15, 3, { 1091474189 }, nil, nil, nil, { "Aullido gutural" } },
    { "Pack Frenzy", "CS", 5, 3, nil, nil, nil, nil, { "Frenesí de la manada" } },
    { "Opportunist Strike", "CS", 5, 2, nil, nil, nil, nil, { "Golpe oportunista" } },
  } },
  { "Khashkhilar Archer", {
    { "Jagged Arrow", "W", 7, 3, { 1090553904 }, nil, nil, nil, { "Flecha dentada" } },
  } },
  { "Khûrz-hai Defiler", {
    { "Spread Rot", "ISD", 15, 5, { 1090535376 }, nil, nil, nil, { "Propagar podredumbre" } },
    { "Spread Venom", "IP", 5, 2, { 1092404193 }, nil, nil, nil, { "Propagar veneno" } },
  } },
  { "Anguished Spirit", {
    { "Lash of Anguish", "LS", 7, 5, nil, nil, nil, nil, { "Latigazo de angustia" } },
  } },
  { "TBD Mauler", {
    { "Bloody Slash", "CS", 30, 15, nil, nil, nil, nil, { "Corte sangriento" } },
    { "Pounce", "K", 60, 0, { 1091404640 }, nil, nil },
    { "Eviscerate", "T", 60, 0, { 1091479304 }, nil, nil, nil, { "Eviscerar" } },
  } },
  { "Mind-addled Cultist", {
    { "Sacrifice", "ASF", 10, 0, { 1090552838 }, nil, nil, nil, { "Sacrificio" } },
  } },
  { "Empowered Fell-beast", {
    { "Breath of Venom", "CSP", 20, 10, { 1092407345 }, nil, nil, nil, { "Respiración de Venom", "Aliento de Veneno" } },
    { "Tail Swipe", "ASK", 20, 7, nil, nil, nil, nil, { "Barrido de cola" } },
    { "Foul Bite", "P", 10, 3, { 1092407345 }, nil, nil },
  } },
  { "Gaurhoth Flesh-shaper", {
    { "Transfusion", "WX", 7, 3, { 1091401111 }, nil, nil, nil, { "Transfusión" } },
    { "Call to Flesh", "SF", 15, 7, { 1090555828, 1092815114 }, nil, nil, nil, { "Llama a Flesh" } },
  } },
  { "Writhing Spirit", {
    { "Writhing Torment", "AS", 5, 5, nil, nil, nil, nil, { "Tormento retorcido" } },
  } },
  { "Pack Spirit", {
    { "Hunter's Trap", "SW", 5, 0, { 1091476353, 1091401111 }, nil, nil, nil, { "Trampa del cazador" } },
  } },
  { "Illusion of the Hunter", {
    { "Swiping Claws", "ASF", 20, 10, { 1092810118 }, nil, nil, nil, { "Garras cortantes", "Garras Cortantes" } },
    { "Echoing Howl", "AS", 30, 0, nil, nil, nil, nil, { "Aullido resonante" } },
  } },
  { "Blade of Shadow", {
    { "Blade of Shadow (Distributed)", "G", 30, 0, { 1090648290 }, nil, nil, nil, { "Hoja de la sombra (Distribuida)" } },
  } },
  { "Cursed Spear", {
    { "Explosive Spear", "AS", 10, 0, nil, nil, nil, nil, { "Lanza explosiva" } },
    { "Cursed Shot", "LS", 10, 0, nil, nil, nil, nil, { "Disparo maldito" } },
  } },
  { "Pit-maggot", {
    { "Caustic Venom", "I", 30, 7, { 1092404193 }, nil, nil, nil, { "Veneno cáustico" } },
  } },
  { "Flesh-louse", {
    { "Melt Armour", "P", 1, 0, { 1091476365 }, nil, nil, nil, { "Derretir armadura" } },
    { "Piercing Shriek", "IA", 30, 7, nil, nil, nil, nil, { "Chillido penetrante" } },
  } },
  { "Corrupted Warg", {
    { "Hideous Cackle", "AF", 15, 3, { 1090522260 }, nil, nil, nil, { "Carcajada Horrible" } },
    { "Corrupted Bite", "F", 10, 5, { 1092407345 }, nil, nil, nil, { "Mordisco corrupto" } },
  } },
  { "Khûrz-hai Labourer", {
    { "Cleaving Strike", "C", 5, 3, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Berserker Rage", "I", 15, 7, { 1090553956 }, nil, nil, nil, { "Furia berserker" } },
  } },
  { "Jiljegish the Corpse-eater", {
    { "Flailing Tusks", "C", 15, 5, nil, nil, nil, nil, { "Colmillos arrolladores" } },
    { "Charging Bash", "LSK", 15, 7, nil, nil, nil, nil, { "Golpe de carga" } },
  } },
  { "Zengshash the Dank-bark", {
    { "Fungal Claw", "C", 10, 5, { 1091429138 }, nil, nil },
    { "Striking Roots", "K", 20, 10, { 1091752909 }, nil, nil },
  } },
  { "Valuntor the Boulder-hide", {
    { "Desperate Shriek", "AF", 15, 5, { 1091404640 }, nil, nil, nil, { "Grito de desesperación" } },
    { "Kick Dust", "AP", 15, 10, { 1091798510 }, nil, nil },
    { "Mauling Tail", "CK", 15, 13, nil, nil, nil },
  } },
  { "Aghash the Tree-breaker", {
    { "Guttural Roar", "CSK", 30, 10, nil, nil, nil },
    { "Heavy Slam", "C", 15, 5, { 1091479189 }, nil, nil, nil, { "Golpe pesado" } },
  } },
  { "Nazaghai the Thunderer", {
    { "Quaking Stomp", "A", 30, 10, nil, nil, nil },
  } },
  { "Draugrim Hunter", {
    { "Detonating Spear", "S", 15, 3, nil, nil, nil },
    { "Cruel Javelin (Distributed)", "LG", 15, 7, nil, nil, nil },
  } },
  { "Hunting Warg", {
    { "Tear Tendons", "W", 20, 5, { 1091405164, 1091476353 }, nil, nil, nil, { "Desgarro de tendones" } },
    { "Vicious Jaws", "CW", 15, 5, { 1090527705 }, nil, nil },
  } },
}
