-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["ubw1"] = {
  { "Utûgi Destroyer", {
    { "Cleaving Strike", "C", 5, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
  } },
  { "Kulkorth", {
    { "Roar", "A", 30, 15, nil, nil, nil },
    { "Burn!", "A", 30, 10, { 1090623585 }, nil, nil },
    { "Cursed Arrow", "S", 20, 20, { 1091840260, 1093004319 }, { "may this ground you tread be cur" }, nil, nil, { "Flecha maldita" } },
    { "Dreadful Arrow (distributed)", "G", 20, 20, nil, { "may this ground you tread be cur" }, nil, nil, { "Flecha terrible (distribuida)" } },
    { "Cleaving Strike", "C", 15, 15, { 1093004330, 1093004355, 1093004318, 1093004322 }, nil, nil, nil, { "Golpe de hendidura" } },
  } },
  { "Utûgi Slaughterer", {
    { "Cleaving Strike", "C", 5, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Thrash", "A", 12, 12, nil, nil, nil },
    { "Stunning Blow", "K", 25, 16, nil, nil, nil, nil, { "Golpe aturdidor", "Golpe Aturdidor" } },
  } },
  { "Urâshi Archer", {
    { "Poisoned Dart", "ISP", 20, 0, { 1090523646 }, nil, nil, nil, { "Dardo envenenado" } },
  } },
  { "Urâshi Berserker", {
    { "Jagged Cut", "CSW", 15, 0, { 1090553355 }, nil, nil, nil, { "Corte Dentado" } },
  } },
  { "Urâshi Captain", {
    { "Blistering Derision", "I", 10, 10, nil, nil, nil, nil, { "Burla abrasadora" } },
  } },
  { "Wretched Utug-bûr Spirit", {
    { "Release", "AB", 1, 0, nil, nil, nil, nil, { "Liberar" } },
    { "Induction Enter Invulnerability State", "I", -1, 0, nil, nil, nil, nil, { "Inducción para Entrar en Estado de Invulnerabilidad" } },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
    { "Shadow Scream", "IA", 30, 0, nil, nil, nil, nil, { "Grito de Sombra" } },
    { "Shadow Touched", "F", 20, 0, { 1090528810 }, nil, nil, nil, { "Tocado por la Sombra" } },
    { "Shadow Grip", "F", 20, 0, { 1090532173 }, nil, nil },
  } },
  { "Utug-bûr Crypt-guardian", {
    { "Shield of the Dead", "AK", 30, 10, { 1091423618, 1091401422, 1092979838, 1093004317 }, nil, nil, nil, { "Escudo de los Muertos" } },
  } },
  { "Maluchon, the Pale Brother", {
    { "Lingering Fear", "F", -1, 15, { 1093004350, 1090532791, 1092746846, 1092995894 }, nil, nil, nil, { "Miedo persistente", "Miedo Persistente" } },
    { "Breaking Bonds", "E", -1, 0, { 1090553954, 1091401423 }, nil, nil },
    { "Deathly Chill", "A", 22, 0, { 1091429123, 1092995856, 1092995904, 1092995875, 1092995873, 1092995880, 1092995854 }, nil, nil, nil, { "Frío Mortal", "Frío mortal 2", "Frío mortal 5", "Frío mortal 3", "Frío mortal 4", "Frío mortal 1", "Frío mortal" } },
    { "Call to the Dead", "SF", 35, 22, { 1093004351, 1093004353, 1090625091 }, nil, nil, nil, { "Llamada de los Muertos" } },
    { "Cleaving Strike", "C", 5, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Contagious Fear", "SF", 0, 20, { 1090625091 }, nil, nil, nil, { "Miedo contagioso" } },
  } },
  { "Utug-bûr Crypt-sentinel", {
    { "Sentinel's Barbed Arrow", "SW", 1, 0, { 1091734506 }, nil, nil, nil, { "Flecha con púas de centinela" } },
    { "Sentinel's Killing Arrow", "SW", 1, 0, { 1090555710 }, nil, nil, nil, { "Flecha mortal de centinela" } },
  } },
  { "Utug-bûr Crypt-champion", {
    { "Chill Foes", "A", 15, 20, { 1090532174 }, nil, nil },
    { "Mark Foe", "R", 20, 10, { 1090625091 }, nil, nil, nil, { "Marcar Enemigo" } },
    { "Hooked Arrow", "SW", 10, 5, { 1090555713 }, nil, nil },
  } },
  { "Bashâru", {
    { "Stand Ground", "T", 60, 30, { 1093000218 }, nil, nil },
    { "Deafening Roar", "AS", 10, 0, nil, nil, nil, nil, { "Rugido ensordecedor" } },
    { "Rejuvenating Strike", "CS", 5, 0, nil, nil, nil, nil, { "Golpe rejuvenecedor" } },
    { "Swipe", "C", 3, 0, { 1091744625 }, nil, nil, nil, { "Barrido", "Zarpazo" } },
    { "Broad Swipe", "C", 3, 0, { 1091744625 }, nil, nil, nil, { "Barrido amplio", "Barrido Amplio" } },
    { "a weak swipe attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque de golpe débil", "un ataque de barrido débil" } },
    { "a minor swipe attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque de golpe menor", "un ataque de barrido menor" } },
    { "a moderate swipe attack", "W", 2, 0, { 1090523647, 1090523648 }, nil, nil, nil, { "un ataque de golpe moderado", "Un ataque de barrido moderado" } },
    { "a mighty swipe attack", "W", 0, 0, { 1090523647, 1090537950 }, nil, nil, nil, { "un poderoso ataque de golpe", "un poderoso ataque de barrido" } },
  } },
  { "Dreadful Utug-bûr Spirit", {
    { "Tie Sinew", "A", 30, 15, nil, nil, nil, nil, { "Atar tendón" } },
    { "Embrace Death", "F", 10, 120, { 1093004351, 1093004353, 1090625091 }, nil, nil, nil, { "Abrazar la muerte" } },
    { "Death Burst", "S", 0, 1, nil, nil, nil },
    { "Black Thoughts", "SF", 0, 1, { 1093004351, 1093004353, 1090625091 }, nil, nil, nil, { "Pensamientos negros" } },
    { "Induction Enter Invulnerability State", "I", -1, 0, nil, nil, nil, nil, { "Inducción para Entrar en Estado de Invulnerabilidad" } },
    { "Shadow Burst", "A", -1, 0, nil, nil, nil },
    { "Weaken Courage", "F", 10, 0, { 1090528810 }, nil, nil, nil, { "Debilitar el coraje" } },
    { "Open Fissure", "I", -1, 0, { 1090524461 }, nil, nil },
  } },
  { "Tamâkh", {
    { "Savage Bite", "T", 15, 10, nil, nil, nil, nil, { "Mordisco salvaje" } },
    { "Restorative Howl", "I", 10, 0, { 1090553329 }, nil, nil, nil, { "Aullido restaurador" } },
    { "a weak melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque cuerpo a cuerpo débil" } },
    { "a minor melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque menor de melee", "un ataque cuerpo a cuerpo menor" } },
    { "a moderate melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque cuerpo a cuerpo moderado" } },
    { "a mighty melee attack", "W", 0, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "Un poderoso ataque de melee", "un poderoso ataque cuerpo a cuerpo", "Un poderoso ataque cuerpo a cuerpo" } },
  } },
  { "Urâshi Gut-slasher", {
    { "Brutal Strike", "T", 1, 0, nil, nil, nil, nil, { "Golpe Brutal" } },
  } },
  { "Utûgi Demolisher", {
    { "Sweep", "C", 7, 5, nil, nil, nil, nil, { "Barrido" } },
    { "Great Smash", "K", 5, 3, nil, nil, nil },
    { "Thresh the Chaff", "CK", 10, 5, nil, nil, nil, nil, { "Trillar la paja" } },
    { "Furious Smite", "T", 5, 5, nil, nil, nil, nil, { "Golpe Furioso", "Golpe furioso" } },
  } },
  { "Urâshi Assassin", {
    { "Enraged Shot", "E", 3, 5, nil, nil, nil, nil, { "Disparo enfurecido" } },
  } },
  { "Risen Arm", {
    { "Death Grip", "C", 2, 0, nil, nil, nil },
    { "Expire", "AG", 30, 45, nil, nil, nil, nil, { "Expirar" } },
  } },
}
