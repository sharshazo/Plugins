-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["isles"] = {
  { "Krizhmûl", {
    { "Septic Bite", "D", 16, 20, { 1091657100, 1091657099, 1091657098, 1091659752 }, nil, nil },
    { "Thrashing Jaws", "CW", 15, 0, { 1091401111 }, nil, nil },
    { "Lashing Tail", "CK", 20, 0, nil, nil, nil, nil, { "Cola Azotadora" } },
    { "Septic Cloud", "D", 35, 0, { 1091657100, 1091657099, 1091657098, 1091659752, 1091400596 }, nil, nil, nil, { "Nube séptica" } },
  } },
  { "Urâbaz the Mighty", {
    { "Backhand Smash", "K", 0, 0, nil, nil, nil, nil, { "Golpe de revés" } },
    { "Hurl Coconut", "K", 0, 30, nil, nil, nil, nil, { "Lanzar coco" } },
    { "Grog Barrel", "SP", 0, 25, { 1090640842 }, nil, nil, nil, { "Barril de grog" } },
  } },
  { "Raghârik", {
    { "Slashing Beak", "C", 0, 0, nil, nil, nil, nil, { "Pico cortante" } },
    { "Lightning Blast", "K", 10, 0, { 1091565008 }, nil, nil, nil, { "Explosión de relámpagos" } },
    { "Updraft", "K", 0, 12, nil, nil, nil, nil, { "Corriente ascendente" } },
    { "Downdraft", "AK", 0, 30, nil, nil, nil, nil, { "Corriente descendente" } },
  } },
  { "Fallen Buccaneer", {
    { "Submerging...", "I", -1, 0, nil, nil, nil },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
    { "Lesser Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil },
    { "Lesser Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad por enfermedad menor" } },
    { "Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante" } },
    { "Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enferma" } },
    { "Festering disease", "K", 0, 0, nil, nil, nil },
  } },
  { "Fallen Privateer", {
    { "Submerging...", "I", -1, 0, nil, nil, nil },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
    { "Lesser Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil },
    { "Lesser Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad por enfermedad menor" } },
    { "Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante" } },
    { "Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enferma" } },
    { "Festering disease", "K", 0, 0, nil, nil, nil },
  } },
  { "Vengeful Mariner", {
    { "Submerging...", "I", -1, 0, nil, nil, nil },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
    { "Lesser Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil },
    { "Lesser Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad por enfermedad menor" } },
    { "Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante" } },
    { "Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enferma" } },
    { "Festering disease", "K", 0, 0, nil, nil, nil },
  } },
  { "Wandering Cyclone", {
    { "Frost Wave", "AS", 15, 0, nil, nil, nil, nil, { "Ola de escarcha", "Ola de Escarcha" } },
    { "Frost Vortex", "K", 5, 0, nil, nil, nil, nil, { "Vórtice de escarcha" } },
    { "Snow Geyser", "SKW", 5, 0, { 1091429125 }, nil, nil, nil, { "Géiser de nieve" } },
    { "Frost Swipe High", "CS", 3, 0, nil, nil, nil },
  } },
  { "Ghostly Captain", {
    { "Submerging...", "I", -1, 0, nil, nil, nil },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
    { "Lesser Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil },
    { "Lesser Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad por enfermedad menor" } },
    { "Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante" } },
    { "Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enferma" } },
    { "Festering disease", "K", 0, 0, nil, nil, nil },
  } },
  { "Accursed Privateer", {
    { "Diseased Roar", "LD", -1, 0, { 1090522616 }, nil, nil, nil, { "Rugido enfermizo" } },
    { "Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante" } },
    { "Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enferma" } },
    { "Greater Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante sup" } },
    { "Greater Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enfermiza sup" } },
    { "Festering disease", "K", 0, 0, nil, nil, nil },
  } },
  { "Accursed Corsair", {
    { "Lesser Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil },
    { "Lesser Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad por enfermedad menor" } },
    { "Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante" } },
    { "Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enferma" } },
    { "Festering disease", "K", 0, 0, nil, nil, nil },
  } },
  { "Errant Winds", {
    { "Errant Winds", "IAK", 12, 4, nil, nil, nil, nil, { "Vientos errantes" } },
  } },
  { "Chaotic Winds", {
    { "Frost Swipe High", "C", 4, 0, nil, nil, nil },
    { "Lightning Bolt", "K", 8, 6, nil, nil, nil, nil, { "Relámpago" } },
    { "Chaotic Lightning", "IA", 16, 8, nil, nil, nil, nil, { "Rayo caótico" } },
  } },
}
