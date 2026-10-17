-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["folly"] = {
  { "Commander Mornang", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Piercing Shriek", "A", 30, 15, 2, { 1092812644 }, nil, "50.0m around Self" },
    { "Weapon Snatch", "AK", 60, 30, 4, { 1092830944, 1090553266 }, { "your pathetic weapons cannot", "you are nothing without your" }, "50.0m around Self" },
    { "Claw Swipe", "ASW", 2, 0, 2, { 1091479304 }, nil, "7.0m around Self" },
  } },
  { "Blood Orb", {
    { "Blood Gather", "A", 1, 0, 60, nil, nil, "50.0m around Self" },
  } },
  { "Seregost Black Uruk", {
    { "Interrupting Shout", "IA", 30, 10, 2, nil, nil, "60.0m around Self" },
  } },
  { "Troll Demolisher", {
    { "Ground Slam", "AK", 30, 10, 3, nil, nil, "20.0m around Self" },
    { "Brutal Swing", "CK", 10, 5, nil, nil, nil, "90° by 5.0m arc from Self" },
  } },
  { "Armoured Morvul", {
    { "Flying Charge", "K", 30, 10, 3, { 1091404060, 1092806781, 1090527705, 1092835520 }, nil, "Single Target" },
    { "Claw Slash", "W", 10, 5, nil, { 1091479304 }, nil, "Single Target" },
  } },
  { "Blood Sorceress Agaris", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Beckon", "S", 50, 20, 4, { 1090623612 }, { "you cannot resist me", "come to me little morsels" }, "5.0m around Selection | 5 max targets" },
    { "Bleed for Me", "A", 100, 10, 5, { 1091401111, 1090539325 }, { "ahhh what a feast", "keep bleeding for me little " }, "50.0m around Self" },
    { "Bleed for Me - Empowered", "A", 100, 10, 5, { 1091401111, 1090539325 }, { "ahhh what a feast", "keep bleeding for me little " }, "50.0m around Self" },
    { "Bleed for Me - Empowered II", "A", 100, 10, 5, { 1091401111, 1090539325 }, { "ahhh what a feast", "keep bleeding for me little " }, "50.0m around Self" },
    { "Blood Storm", "ASK", 120, 60, 4, nil, { "dance with me little ones" }, "50.0m around Self" },
  } },
  { "Animated Blood", {
    { "Heated Blood", "AS", 1, 5, 5, nil, nil, "10.0m around Self" },
  } },
  { "Morroval Blade-thrower", {
    { "Wing Blades", "AW", 30, 7, 3, { 1090527705 }, nil, "7.0m around Self" },
  } },
  { "Morvul Darkwing", {
    { "Flying Charge", "K", 60, 15, 3, { 1091404060, 1092806781, 1090527705, 1092835520 }, nil, "Single Target" },
    { "Claw Slash", "SW", 20, 5, nil, { 1091479304 }, nil, "Single Target" },
  } },
  { "Morroval Stalker", {
    { "Ambush", "K", 5, 0, nil, nil, nil, "Single Target" },
    { "Wing Blades", "ASW", 10, 5, 3, { 1090527705 }, nil, "7.0m around Self" },
  } },
  { "Cristhir the Night-shadow", {
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
    { "Fan of Knives", "AP", 30, 10, 2, { 1090523646 }, { "poisoned blades find your ma", "none of you are safe from my" }, "50.0m around Self" },
    { "Fan of Knives - Empowered", "AP", 30, 10, 1, { 1090523646 }, { "poisoned blades find your ma", "none of you are safe from my" }, "50.0m around Self" },
    { "Fan of Knives - Empowered II", "AP", 30, 10, 1, { 1090523646 }, { "poisoned blades find your ma", "none of you are safe from my" }, "50.0m around Self" },
  } },
  { "Zamâktar the Putrescent", {
    { "Putrid Expulsion", "C", 16, 20, nil, { 1092979848, 1092943405 }, nil, "80° by 10.0m arc from Self" },
    { "Great Roar", "A", 30, 0, nil, nil, nil, "60.0m around Self" },
    { "Eruption", "A", 30, 0, nil, nil, nil, "5.0m around Self" },
    { "Devastating Eruption", "A", 30, 0, nil, nil, nil, "60.0m around Self" },
    { "Creeping Blight Infestation", "SWD", 20, 20, nil, { 1090575029 }, nil, "Single Target" },
    { "Virulent Spores", "C", -1, 0, nil, { 1091535828 }, nil, "120° by 20.0m arc from Self" },
    { "Crushing Fall", "A", 15, 0, 5, nil, nil, "60.0m around Self" },
    { "Crushing Blow", "S", 10, 720, nil, nil, nil, "3.0m by 50.0m rectangle from Self" },
    { "Roar", "A", 24, 0, nil, nil, nil, "60.0m around Self" },
    { "Choking Spores", "A", 24, 5, nil, { 1092943405 }, nil, "60.0m around Self" },
    { "Earth Shaker", "A", 24, 5, nil, nil, nil, "15.0m around Self" },
    { "Terrible Roar", "A", 24, 5, nil, { 1092943405 }, nil, "60.0m around Self" },
  } },
  { "Webmother's Brood", {
    { "Savage Blows", "ICS", 9, 3, 3, nil, nil, "120° by 6.0m arc from Self | 12 max targets" },
    { "Flurry of Barbs", "C", 12, 6, nil, nil, nil, "120° by 6.0m arc from Self | 12 max targets" },
  } },
  { "Badharál the Gorger", {
    { "Savage Pincers", "CS", 6, 0, nil, nil, { "you will feel my fury" }, "120° by 6.0m arc from Self | 12 max targets" },
    { "Poison Spit", "S", 0, 0, nil, nil, nil, "5.0m around Selection" },
    { "Horrid Venom", "ICS", 30, 0, 3, nil, nil, "60° by 30.0m arc from Self | 12 max targets" },
  } },
  { "Badharál's Spitter", {
    { "Entangling Web", "K", 12, 6, nil, { 1090529649 }, nil, "Single Target" },
    { "Virulent Spit", "ISP", 9, 0, 3, { 1090522396 }, nil, "Single Target" },
  } },
  { "Badharál's Weaver", {
    { "Wasting Venom", "P", 15, 15, nil, { 1090623612 }, nil, "10.0m around Selection | 12 max targets" },
  } },
  { "Badharál's Webmother", {
    { "Shake the Web", "I", 0, 15, 2, nil, nil, "Single Target" },
    { "Silken Mend", "ASD", 15, 25, nil, { 1090541083 }, nil, "10.0m around Self | 30 max targets" },
    { "Virulent Spit", "ISP", 10, 0, 3, { 1090522396 }, nil, "Single Target" },
  } },
  { "Badharál's Skulker", {
    { "Calculated Pounce", "I", 8, 3, 3, nil, nil, "Single Target" },
    { "Onslaught of Barbs", "CS", 15, 0, nil, nil, nil, "120° by 6.0m arc from Self | 12 max targets" },
  } },
  { "Badharál's Hunter", {
    { "Infected Wound", "SD", 10, 6, nil, { 1090575029 }, nil, "Single Target" },
  } },
  { "Badharál's Young", {
    { "Savage Blows", "ICS", 9, 3, 3, nil, nil, "120° by 6.0m arc from Self | 12 max targets" },
    { "Flurry of Barbs", "C", 12, 6, nil, nil, nil, "120° by 6.0m arc from Self | 12 max targets" },
  } },
  { "Maukhorn", {
    { "Upheaval", "K", 25, 12, nil, { 1091840569 }, nil, "Single Target" },
    { "Stomp", "A", 30, 18, nil, nil, { "smash and crush" }, "40.0m around Self" },
    { "Enraged Spores", "E", 60, 87, nil, { 1093081106, 1091941763 }, nil, "Single Target" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a strong swipe attack", "C", 7, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a mighty swipe attack", "C", 7, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "Strike of the Undeceived", "TR", 4, 4, nil, { 1093004344, 1092754584, 1090586730 }, nil, "Single Target" },
  } },
  { "Giant Erupting Growth", {
    { "Great Eruption", "A", 5, 0, 3, nil, nil, "20.0m around Self" },
  } },
  { "Blight-spreading Bat", {
    { "Blight Bomb", "AS", 15, 2, 5, { 1091400592, 1092979848 }, nil, "7.0m around Self" },
  } },
  { "Troll Crusher", {
    { "Upheaval", "K", 20, 12, nil, { 1091840569 }, nil, "Single Target" },
    { "Stomp", "A", 20, 20, nil, nil, nil, "40.0m around Self" },
  } },
  { "Blighted Bloom", {
    { "Blighted Bloom", "AS", 12, 2, 10, nil, nil, "60.0m around Self" },
  } },
  { "Cascading Bloom", {
    { "Cascading Bloom", "IAS", 10, 2, 8, nil, nil, "60.0m around Self" },
  } },
}
