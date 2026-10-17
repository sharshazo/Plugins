-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["palace"] = {
  { "Góramul Sai", {
    { "Serpent Strike", "CSW", 30, 5, { 1090522394 }, { "i cannot fail the hûl", "no puedo fallarle al hûl" }, nil, nil, { "Golpe de serpiente" } },
    { "Spear Throw", "LS", 30, 10, nil, { "i cannot abandon emax dûl", "no puedo abandonar a emax dûl" }, nil, nil, { "Lanzamiento de lanza" } },
    { "Corrupted Strike", "CSPR", 15, 5, { 1090522396, 1093065194, 1093065189, 1093065188, 1093065193, 1093065191, 1093065192, 1093065190 }, { "strike of the black serpent", "golpe de la serpiente negra", "succumb to my new power", "sucumbe a mi nuevo poder" }, nil, nil, { "Golpe Corrupto", "Golpe corrupto" } },
  } },
  { "Ratúlko the Bloody", {
    { "Poisoned Knives", "SP", 30, 5, { 1090523646 }, { "this new batch is particularly d", "a well tested poison hahaha", "un veneno bien probado jajaja" }, nil, nil, { "Cuchillos Envenenados" } },
    { "Jagged Blade (Distributed)", "AG", 30, 10, { 1093065176, 1093065174, 1093065169, 1093065170, 1093065171, 1093065175, 1093065177, 1093065172, 1093065168, 1093065173, 1092809833 }, { "let me show you why they call me", "déjenme mostrarles por qué me ", "i ll rip you open and bleed the " }, nil, nil, { "Hoja Dentada (Distribuida)" } },
    { "Cauterize", "CSW", 45, 30, { 1093065176, 1093065174, 1093065169, 1093065170, 1093065171, 1093065175, 1093065177, 1093065172, 1093065168, 1093065173 }, { "don t die yet i m not done with ", "no mueras todavía no he termina", "this stops the bleeding but not ", "esto detiene el sangrado pero no" }, nil, nil, { "Cauterizar" } },
    { "Barbed Chain", "AW", 45, 20, { 1092809833, 1093065176, 1093065174, 1093065169, 1093065170, 1093065171, 1093065175, 1093065177, 1093065172, 1093065168, 1093065173 }, { "come come let us know each other", "vengan vengan conozcámonos mejo", "get over here hahaha", "ven aquí jajaja" }, nil, nil, { "Cadena de Púas" } },
    { "Lock Up", "E", 160, 45, { 1090532174 }, { "i think you all need some time i", "creo que todos necesitan un tiem", "send them to solitary confinemen" }, nil, nil, { "Encerrar" } },
    { "Barbed Chain Throw", "A", 5, 1, nil, nil, nil, nil, { "Lanzamiento de cadena de púas" } },
  } },
  { "Dark Priestess Barkhuráni", {
    { "Gaze of the Eye", "A", 20, 10, { 1093065186, 1093065184, 1093065185, 1093065182, 1093065183, 1093065180, 1093065181, 1093065187, 1093065178, 1093065179 }, { "tremble before the gaze of the e", "tiembla ante la mirada de el ojo", "the great eye gazes upon you", "el gran ojo te contempla" }, nil, nil, { "Mirada del Ojo" } },
    { "Vision of Demise", "K", 15, 0, { 1091404060 }, { "witness your own end", "presencia tu propio fin", "your death comes", "la muerte se acerca" }, nil, nil, { "Visión de la Muerte" } },
    { "Vision of Demise (Distributed)", "GK", 1, 0, { 1091404060 }, nil, nil, nil, { "Visión de la muerte (distribuida)" } },
    { "Overwhelming Despair", "SKF", 20, 0, { 1093032360, 1090532173, 1091404060 }, { "your sorrow fuels my power", "tu dolor alimenta mi poder", "you cannot win there is no hope", "no puedes ganar no hay esperanza" }, nil, nil, { "Desesperación Abrumadora" } },
    { "Impending Doom", "K", 30, 0, { 1091404060 }, { "your worst fear is made manifest", "tu peor miedo se hace manifiesto", "doom comes for you", "el fin viene por ti" }, nil },
    { "Welling Dread", "W", 8, 5, { 1093065186, 1093065184, 1093065185, 1093065182, 1093065183, 1093065180, 1093065181, 1093065187, 1093065178, 1093065179, 1092407345, 1091479303 }, nil, nil, nil, { "Pavor creciente" } },
  } },
  { "Royal Guard", {
    { "Finish Them", "K", 60, 0, nil, nil, nil },
  } },
  { "Priest of Shadow", {
    { "Summon Shadow", "I", 60, 5, nil, nil, nil, nil, { "Invocar sombra", "Invocar Sombra" } },
  } },
  { "Enthralled Prisoner", {
    { "Head Crack", "KT", 30, 8, nil, nil, nil },
    { "Feral Swipe", "C", 5, 3, nil, nil, nil },
  } },
  { "Utûgi Enforcer", {
    { "Massive Slam", "A", 20, 5, nil, nil, nil, nil, { "Golpe masivo" } },
  } },
  { "Thothril the Entangler", {
    { "Force of Madness", "LSKR", 15, 6, { 1093065194, 1093065189, 1093065188, 1093065193, 1093065191, 1093065192, 1093065190 }, nil, nil, nil, { "Fuerza de la Locura" } },
    { "Pull of Madness", "A", 45, 30, { 1091479303 }, { "come closer little puppets", "come to me and earn your reward", "vengan a mí y ganen su recompen" }, nil, nil, { "Tiro de la locura", "Atracción de la Locura" } },
  } },
  { "Utûgi Impaler", {
    { "Impaling Throw (Distributed)", "LG", 20, 8, nil, nil, nil, nil, { "Lanzamiento Empalador (Distribuido)" } },
    { "Run Through", "I", 20, 3, nil, nil, nil, nil, { "Atravesar" } },
  } },
  { "Priestess of Command", {
    { "Fear of the Eye", "IA", 30, 8, nil, nil, nil, nil, { "Miedo al Ojo" } },
  } },
  { "Enthralled Servant", {
    { "Scream of Madness", "IA", 15, 5, nil, nil, nil, nil, { "Grito de Locura" } },
    { "Insane Gibbering", "F", 10, 2, { 1090522260 }, nil, nil },
  } },
  { "Bloody Torturer", {
    { "Brand Stab", "LW", 8, 5, { 1090623585 }, nil, nil, nil, { "Puñalada de Marca" } },
    { "Brand Sweep", "C", 5, 3, nil, nil, nil, nil, { "Barrido de Marca" } },
  } },
  { "Animated Armour", {
    { "Armoured Slam", "K", 15, 5, nil, nil, nil, nil, { "Golpe Acorazado" } },
    { "Clattering Armour", "IAR", 30, 30, { 1093065194, 1093065189, 1093065188, 1093065193, 1093065191, 1093065192, 1093065190 }, nil, nil },
  } },
  { "Palace Sentry", {
    { "Take Aim", "I", 20, 5, nil, nil, nil, nil, { "Apuntar" } },
    { "Call Reinforcements", "I", 120, 0, nil, nil, nil, nil, { "Llamar refuerzos" } },
  } },
  { "Shadow Terror", {
    { "Grip of Fear", "IAS", 10, 5, nil, nil, nil },
  } },
  { "Palace Guard", {
    { "Shield Slam", "T", 20, 5, nil, nil, nil, nil, { "Golpe de escudo", "Golpe de Escudo" } },
    { "Gouge Armour", "W", 30, 2, { 1091476365 }, nil, nil, nil, { "Perforar armadura" } },
  } },
  { "Guard Captain", {
    { "Offensive Order", "AF", 30, 10, { 1092973472 }, nil, nil, nil, { "Orden Ofensiva" } },
    { "Call Target", "SF", 60, 15, { 1090553915 }, nil, nil, nil, { "Marcar objetivo" } },
  } },
  { "Shadow Seeker", {
    { "Shadow Pulse", "A", 3, 1, nil, nil, nil, nil, { "Pulso de sombra" } },
  } },
  { "Animated Ooze", {
    { "Acid Splash", "CS", 15, 5, { 1091510188 }, nil, nil, nil, { "Salpicadura de Ácido" } },
    { "Chemical Reaction", "IAS", 1, 0, nil, nil, nil, nil, { "Reacción Química" } },
  } },
  { "Corrupted Spear", {
    { "Animated Spear Throw", "LS", 1, 0, nil, nil, nil, nil, { "Lanzamiento de lanza animado" } },
  } },
}
