-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["caves"] = {
  { "Giríshu, Thief of Blades", {
    { "Flesh Rend", "W", 18, 5, { 1090522395 }, { "i won t miss my mark", "no fallaré mi objetivo" }, nil },
    { "Battering Blades", "CS", 8, 2, nil, { "my blades will find you", "mis espadas te encontrarán", "i am an artist with these blades", "soy un artista con estas espadas" }, nil },
    { "Blade-storm", "IA", 60, 50, nil, nil, nil, nil, { "Tormenta de hojas" } },
    { "a weak melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque cuerpo a cuerpo débil" } },
    { "a minor melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque menor de melee", "un ataque cuerpo a cuerpo menor" } },
    { "a moderate melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque cuerpo a cuerpo moderado" } },
    { "a mighty melee attack", "W", 0, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "Un poderoso ataque de melee", "un poderoso ataque cuerpo a cuerpo", "Un poderoso ataque cuerpo a cuerpo" } },
  } },
  { "Molbása the Untamed", {
    { "Sand Blast", "A", 15, 0, nil, nil, nil, nil, { "Explosión de arena" } },
    { "Spear of the Sands", "L", 18, 20, nil, nil, nil, nil, { "Lanza de las Arenas" } },
  } },
  { "Bârlat the Bold", {
    { "Fissure of Wealth", "LS", 15, 10, nil, { "feel the sting of riches", "siente el aguijón de las riquez" }, nil, nil, { "Fisura de la riqueza" } },
    { "Gold Pile (Distributed)", "G", 25, 3, nil, { "you want my treasure so badly dr", "deseas tanto mi tesoro ahógate " }, nil },
    { "a weak melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque cuerpo a cuerpo débil" } },
    { "a minor melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque menor de melee", "un ataque cuerpo a cuerpo menor" } },
    { "a moderate melee attack", "W", 2, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "un ataque cuerpo a cuerpo moderado" } },
    { "a mighty melee attack", "W", 0, 0, { 1090523647, 1090529420 }, nil, nil, nil, { "Un poderoso ataque de melee", "un poderoso ataque cuerpo a cuerpo", "Un poderoso ataque cuerpo a cuerpo" } },
  } },
  { "Samâshu, Thief of Blight", {
    { "Poisoned Blades", "SP", 16, 4, { 1090522398 }, { "are you feeling unwell", "te sientes mal" }, nil, nil, { "Hojas envenenadas" } },
    { "Pestilent Apocalypse", "I", 60, 30, nil, nil, nil, nil, { "Apocalipsis pestilente" } },
  } },
  { "Bârlat's Rat-master", {
    { "Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante" } },
    { "Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enferma" } },
    { "Greater Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil, nil, { "Enfermedad debilitante sup" } },
    { "Greater Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad enfermiza sup" } },
    { "Festering disease", "K", 0, 0, nil, nil, nil },
    { "Summon Rat", "I", -1, 0, nil, nil, nil, nil, { "Invocar rata" } },
    { "Lesser Wasting Sickness", "D", 0, 0, { 1091401231 }, nil, nil },
    { "Lesser Diseased Frailty", "D", 0, 0, { 1090522616 }, nil, nil, nil, { "Fragilidad por enfermedad menor" } },
  } },
  { "Bârlat's Tough", {
    { "Seeping Wound", "SW", 30, 2, { 1091401111 }, nil, nil, nil, { "Herida supurante" } },
  } },
  { "Bârlat's Overseer", {
    { "Call for Blood", "I", 140, 12, nil, nil, nil, nil, { "Llamada de sangre" } },
    { "Impaling Strike", "CS", 18, 8, nil, nil, nil, nil, { "Golpe empalador" } },
    { "Blade Sweep", "C", 12, 6, nil, nil, nil },
  } },
  { "Gizûshu, Thief of Shadows", {
    { "Instilled Panic", "K", 20, 15, nil, { "a ready companion" }, nil, nil, { "Pánico infundido" } },
    { "Gathering Shadows", "IA", 60, 40, nil, nil, nil },
  } },
  { "Bârlat's Apothecary", {
    { "Dark Graft", "I", 15, 0, nil, nil, nil, nil, { "Injerto oscuro" } },
    { "Nightmare Borne", "IF", 45, 12, { 1090532173 }, nil, nil, nil, { "Nacido de la pesadilla" } },
  } },
  { "Vicious Rats", {
    { "Plague Bite", "D", -1, 0, { 1090575029 }, nil, nil },
  } },
  { "Grasping Shadows", {
    { "Plunging Darkness", "A", 3, 35, nil, nil, nil },
  } },
}
