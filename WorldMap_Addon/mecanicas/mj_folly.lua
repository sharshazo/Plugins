-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["folly"] = {
  { "Commander Mornang", {
    { "Piercing Shriek", "A", 30, 15, { 1092812644 }, nil, nil, nil, { "Chillido penetrante" } },
    { "Weapon Snatch", "AK", 60, 30, { 1092830944, 1090553266 }, { "your pathetic weapons cannot sav", "sus patéticas armas no pueden s", "you are nothing without your wea", "no son nada sin sus armas mortal" }, nil },
    { "Claw Swipe", "ASW", 2, 0, { 1091479304 }, nil, nil, nil, { "Zarpazo de garra" } },
  } },
  { "Blood Orb", {
    { "Blood Gather", "A", 1, 0, nil, nil, nil },
  } },
  { "Seregost Black Uruk", {
    { "Interrupting Shout", "IA", 30, 10, nil, nil, nil },
  } },
  { "Troll Demolisher", {
    { "Ground Slam", "AK", 30, 10, nil, nil, nil, nil, { "Golpe contra el suelo" } },
    { "Brutal Swing", "CK", 10, 5, nil, nil, nil, nil, { "Golpe Brutal" } },
  } },
  { "Armoured Morvul", {
    { "Flying Charge", "K", 30, 10, { 1091404060, 1092806781, 1092835520 }, nil, nil, nil, { "Carga voladora" } },
    { "Claw Slash", "W", 10, 5, { 1091479304 }, nil, nil },
  } },
  { "Blood Sorceress Agaris", {
    { "Beckon", "S", 50, 20, { 1090623612 }, { "you cannot resist me", "come to me little morsels", "vengan a mí pequeños bocados" }, nil, nil, { "Atraer" } },
    { "Bleed for Me", "A", 100, 10, { 1090539325 }, { "ahhh what a feast", "ahhh qué festín", "keep bleeding for me little ones", "sigan sangrando por mí pequeño" }, nil, nil, { "Sangra por mí" } },
    { "Bleed for Me - Empowered", "A", 100, 10, { 1090539325 }, { "ahhh what a feast", "ahhh qué festín", "keep bleeding for me little ones", "sigan sangrando por mí pequeño" }, nil, nil, { "Sangra por mí - Potenciado", "Sangra por mí - Potenciado II" } },
    { "Bleed for Me - Empowered II", "A", 100, 10, { 1090539325 }, { "ahhh what a feast", "ahhh qué festín", "keep bleeding for me little ones", "sigan sangrando por mí pequeño" }, nil, nil, { "Sangra por mí - Potenciado II" } },
    { "Blood Storm", "ASK", 120, 60, nil, { "dance with me little ones", "bailen conmigo pequeños" }, nil, nil, { "Tormenta de sangre" } },
  } },
  { "Animated Blood", {
    { "Heated Blood", "AS", 1, 5, nil, nil, nil, nil, { "Sangre caliente" } },
  } },
  { "Morroval Blade-thrower", {
    { "Wing Blades", "AW", 30, 7, { 1090527705 }, nil, nil },
  } },
  { "Morvul Darkwing", {
    { "Flying Charge", "K", 60, 15, { 1091404060, 1092806781, 1092835520 }, nil, nil, nil, { "Carga voladora" } },
    { "Claw Slash", "SW", 20, 5, { 1091479304 }, nil, nil },
  } },
  { "Morroval Stalker", {
    { "Ambush", "K", 5, 0, nil, nil, nil, nil, { "Emboscada" } },
    { "Wing Blades", "ASW", 10, 5, { 1090527705 }, nil, nil },
  } },
  { "Cristhir the Night-shadow", {
    { "Fan of Knives", "AP", 30, 10, { 1090523646 }, { "poisoned blades find your marks", "none of you are safe from my bla", "ninguno de ustedes está a salvo" }, nil, nil, { "Abanico de cuchillos" } },
    { "Fan of Knives - Empowered", "AP", 30, 10, { 1090523646 }, { "poisoned blades find your marks", "none of you are safe from my bla", "ninguno de ustedes está a salvo" }, nil, nil, { "Abanico de cuchillos - Potenciado II", "Abanico de cuchillos - Potenciado" } },
    { "Fan of Knives - Empowered II", "AP", 30, 10, { 1090523646 }, { "poisoned blades find your marks", "none of you are safe from my bla", "ninguno de ustedes está a salvo" }, nil, nil, { "Abanico de cuchillos - Potenciado II" } },
  } },
  { "Zamâktar the Putrescent", {
    { "Putrid Expulsion", "C", 16, 20, { 1092979848, 1092943405 }, nil, nil, nil, { "Expulsión pútrida" } },
    { "Blight Cleaver", "L", 60, 15, nil, nil, nil },
    { "Great Roar", "A", 30, 0, nil, nil, nil, nil, { "Gran rugido" } },
    { "Eruption", "A", 30, 0, nil, nil, nil, nil, { "Erupción" } },
    { "Devastating Eruption", "A", 30, 0, nil, nil, nil, nil, { "Erupción devastadora" } },
    { "Creeping Blight Infestation", "SWD", 20, 20, { 1090575029 }, nil, nil, nil, { "Infestación de plaga progresiva" } },
    { "Virulent Spores", "C", -1, 0, { 1091535828 }, nil, nil, nil, { "Esporas virulentas" } },
    { "Crushing Fall", "A", 15, 0, nil, nil, nil, nil, { "Caída aplastante" } },
    { "Crushing Blow", "LS", 10, 720, nil, nil, nil, nil, { "Golpe Aplastante", "Golpe aplastante" } },
    { "Roar", "A", 24, 0, nil, nil, nil },
    { "Death Cleaver", "L", 24, 5, nil, nil, nil },
    { "Choking Spores", "A", 24, 5, { 1092943405 }, nil, nil, nil, { "Esporas asfixiantes" } },
    { "Earth Shaker", "A", 24, 5, nil, nil, nil, nil, { "Sacudidor de tierra" } },
    { "Terrible Roar", "A", 24, 5, { 1092943405 }, nil, nil, nil, { "Rugido terrible" } },
  } },
  { "Webmother's Brood", {
    { "Savage Blows", "ICS", 9, 3, nil, nil, nil, nil, { "Golpes Salvajes" } },
    { "Flurry of Barbs", "C", 12, 6, nil, nil, nil, nil, { "Ráfaga de púas" } },
  } },
  { "Badharál the Gorger", {
    { "Savage Pincers", "CS", 6, 0, nil, { "you will feel my fury", "sentirás mi furia" }, nil, nil, { "Pinzas salvajes" } },
    { "Poison Spit", "S", 0, 0, nil, nil, nil, nil, { "Escupitajo venenoso" } },
    { "Horrid Venom", "ICS", 30, 0, nil, nil, nil, nil, { "Veneno horrible" } },
  } },
  { "Badharál's Spitter", {
    { "Entangling Web", "K", 12, 6, { 1090529649 }, nil, nil, nil, { "Telaraña Enredante" } },
    { "Virulent Spit", "ISP", 9, 0, { 1090522396 }, nil, nil },
  } },
  { "Badharál's Weaver", {
    { "Wasting Venom", "P", 15, 15, { 1090623612 }, nil, nil, nil, { "Veneno debilitante" } },
  } },
  { "Badharál's Webmother", {
    { "Shake the Web", "I", 0, 15, nil, nil, nil, nil, { "Sacudir la telaraña" } },
    { "Virulent Spit", "ISP", 10, 0, { 1090522396 }, nil, nil },
  } },
  { "Badharál's Skulker", {
    { "Calculated Pounce", "I", 8, 3, nil, nil, nil },
    { "Onslaught of Barbs", "CS", 15, 0, nil, nil, nil },
  } },
  { "Badharál's Hunter", {
    { "Infected Wound", "SD", 10, 6, { 1090575029 }, nil, nil, nil, { "Herida infectada" } },
  } },
  { "Badharál's Young", {
    { "Savage Blows", "ICS", 9, 3, nil, nil, nil, nil, { "Golpes Salvajes" } },
    { "Flurry of Barbs", "C", 12, 6, nil, nil, nil, nil, { "Ráfaga de púas" } },
  } },
  { "Maukhorn", {
    { "Upheaval", "K", 25, 12, { 1091840569 }, nil, nil, nil, { "Conmoción" } },
    { "Stomp", "A", 30, 18, nil, { "smash and crush" }, nil, nil, { "Pisotón", "¡Pisotón!" } },
    { "Avalanche", "L", 0, 25, { 1091401418 }, { "stones destroy", "las piedras destruyen" }, nil },
    { "Enraged Spores", "E", 60, 87, { 1093081106, 1091941763 }, nil, nil, nil, { "Esporas enfurecidas" } },
  } },
  { "Giant Erupting Growth", {
    { "Great Eruption", "A", 5, 0, nil, nil, nil, nil, { "Gran erupción" } },
  } },
  { "Blight-spreading Bat", {
    { "Blight Bomb", "AS", 15, 2, { 1091400592, 1092979848 }, nil, nil },
  } },
  { "Troll Crusher", {
    { "Upheaval", "K", 20, 12, { 1091840569 }, nil, nil, nil, { "Conmoción" } },
    { "Stomp", "A", 20, 20, nil, nil, nil, nil, { "Pisotón", "¡Pisotón!" } },
  } },
  { "Fungal Troll Demolisher", {
    { "Avalanche", "L", 15, 15, { 1091401418 }, nil, nil },
  } },
  { "Blighted Bloom", {
    { "Blighted Bloom", "AS", 12, 2, nil, nil, nil },
  } },
  { "Cascading Bloom", {
    { "Cascading Bloom", "IAS", 10, 2, nil, nil, nil, nil, { "Floración en cascada" } },
  } },
}
