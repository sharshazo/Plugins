-- QuestSync Data/ThreatsDB.lua
-- Jefes y amenazas itinerantes (enemyType=2), con zona y recompensas.
_G.ThreatsDB = {
  { id = 117, name = "Khanakarg", level = 140, race = "Warg", raceES = "Huargo", note = "Respawn every hour", zone = "Mount Gundabad", map = "50.jpg", rewards = {}, coords = {
    { c = "47.8N, 77.1W", l = "" },
    { c = "49.1N, 75.6W", l = "" },
  } },
  { id = 116, name = "Skerla", level = 136, race = "lathbear", note = "Respawn every hour", zone = "Mount Gundabad", map = "51.jpg", rewards = {}, coords = {
    { c = "48.5N, 68.7W", l = "" },
    { c = "50.4N, 61.6W", l = "" },
  } },
  { id = 118, name = "Kurzkub", level = 139, race = "Grim", note = "Respawn every hour", zone = "Delvings of Gundabad", zoneES = "Excursiones de Gundabad", map = "52.jpg", rewards = {}, coords = {
    { c = "35.8S, 122.5W", l = "" },
    { c = "35.2S, 124.0W", l = "" },
  } },
  { id = 119, name = "Gullush", level = 138, race = "Frog", raceES = "Rana", note = "Respawn every hour", zone = "Delvings of Gundabad", zoneES = "Excursiones de Gundabad", map = "53.jpg", rewards = {}, coords = {
    { c = "47.9S, 120.1W", l = "" },
    { c = "47.2S, 121.8W", l = "" },
  } },
  { id = 120, name = "Skrizug", level = 136, race = "TBD", note = "Respawn every hour", zone = "Delvings of Gundabad", zoneES = "Excursiones de Gundabad", map = "54.jpg", rewards = {}, coords = {
    { c = "42.2S, 113.0W", l = "" },
    { c = "38.3S, 111.9W", l = "" },
  } },
  { id = 122, name = "Gurlazg", level = 134, race = "Insect", note = "Respawn every hour", zone = "Delvings of Gundabad", zoneES = "Excursiones de Gundabad", map = "55.jpg", rewards = {}, coords = {
    { c = "49.5S, 117.7W", l = "" },
    { c = "51.3S, 118.4W", l = "" },
  } },
  { id = 121, name = "Forsting", level = 133, race = "Dragon", raceES = "Dragón", note = "Respawn every hour", zone = "Delvings of Gundabad", zoneES = "Excursiones de Gundabad", map = "56.jpg", rewards = {}, coords = {
    { c = "49.6S, 113.5W", l = "" },
    { c = "47.2S, 112.3W", l = "" },
  } },
  { id = 111, name = "Krùmpug", level = 130, race = "Goblin", raceES = "Trasgo", note = "Respawn every hour", zone = "Azanulbizar", map = "49.jpg", rewards = {}, coords = {
    { c = "70.2N, 137.1W", l = "" },
    { c = "70.2N, 136.6W", l = "" },
    { c = "71.3N, 137.2W", l = "" },
  } },
  { id = 112, name = "Muzbuk", level = 130, race = "Bat", raceES = "Murciélago", note = "Respawn every hour", zone = "Azanulbizar", map = "49.jpg", rewards = {}, coords = {
    { c = "69.0N, 134.6W", l = "" },
    { c = "69.9N, 134.0W", l = "" },
    { c = "69.3N, 134.1W", l = "" },
  } },
  { id = 113, name = "Bagnaz Rot-sting", level = 130, race = "Orc", raceES = "Orco", note = "Respawn every hour", zone = "Azanulbizar", map = "49.jpg", rewards = {}, coords = {
    { c = "65.7N, 135.7W", l = "" },
    { c = "64.8N, 134.7W", l = "" },
    { c = "65.1N, 134.8W", l = "" },
  } },
  { id = 114, name = "Skegghorn", level = 130, race = "Auroch", note = "Respawn every hour", zone = "Azanulbizar", map = "49.jpg", rewards = {}, coords = {
    { c = "66.7N, 132.0W", l = "" },
    { c = "66.4N, 132.4W", l = "" },
    { c = "66.8N, 133.2W", l = "" },
  } },
  { id = 115, name = "Zaugnakh", level = 130, race = "Warg", raceES = "Huargo", note = "Respawn every hour", zone = "Azanulbizar", map = "49.jpg", rewards = {}, coords = {
    { c = "67.3N, 138.4W", l = "" },
    { c = "67.8N, 138.3W", l = "" },
    { c = "68.2N, 138.2W", l = "" },
  } },
  { id = 1120, name = "Urdâr, Scourge of the Dale-lands", level = 115, race = "Hill-man", raceES = "Montañés", note = "", zone = "Eryn Lasgalen and the Dale-lands", map = "32.jpg", rewards = { { type = "FELEGOTH_TOKEN", value = "3" } }, coords = {
    { c = "23.5N, 27.7W", l = "" },
    { c = "20.7N, 24.7W", l = "" },
    { c = "17.5N, 23.5W", l = "" },
    { c = "15.2N, 22.8W", l = "" },
  } },
  { id = 1121, name = "Kalabrazân, Scourge of the Dale-lands", level = 115, race = "Angmarim", note = "", zone = "Eryn Lasgalen and the Dale-lands", map = "32.jpg", rewards = { { type = "FELEGOTH_TOKEN", value = "3" } }, coords = {
    { c = "22.8N, 27.4W", l = "" },
    { c = "20.7N, 24.7W", l = "" },
    { c = "17.5N, 32.5W", l = "" },
    { c = "15.2N, 22.8W", l = "" },
  } },
  { id = 1122, name = "Gloomthorn, Scourge of Eryn-Lasgalen", level = 115, race = "Huorn", raceES = "Ucorno", note = "", zone = "Eryn Lasgalen and the Dale-lands", map = "32.jpg", rewards = { { type = "FELEGOTH_TOKEN", value = "3" } }, coords = {
    { c = "20.9N, 43.2W", l = "" },
    { c = "16.9N, 47.9W", l = "" },
    { c = "15.4N, 43.1W", l = "" },
    { c = "16.0N, 36.2W", l = "" },
  } },
  { id = 1110, name = "Nuzdum, Scourge of Udûn", level = 115, race = "Warg", raceES = "Huargo", note = "", zone = "Udûn", map = "26.jpg", rewards = { { type = "RELIQUE_ALLEGEANCE", value = "1" } }, coords = {
    { c = "39.6S, 6.8E", l = "" },
    { c = "40.9S, 3.9E", l = "" },
    { c = "45.6S, 7.3E", l = "" },
  } },
  { id = 1113, name = "Gristlebite, Scourge of Lhingris", level = 115, race = "Spider", raceES = "Araña", note = "", zone = "Lhingris", map = "27.jpg", rewards = { { type = "RELIQUE_ALLEGEANCE", value = "1" } }, coords = {
    { c = "49.2S, 3.9E", l = "" },
    { c = "51.3S, 4.1E", l = "" },
    { c = "60.6S, 10.9E", l = "" },
  } },
  { id = 1111, name = "Rotwing, Scourge of Dor Amarth", level = 115, race = "Fell Beast", raceES = "Bestia caída", note = "", zone = "Dor Amarth", map = "28.jpg", rewards = { { type = "RELIQUE_ALLEGEANCE", value = "1" } }, coords = {
    { c = "43.9S, 17.3E", l = "" },
    { c = "47.4S, 20.0E", l = "" },
    { c = "50.9S, 8.8E", l = "" },
    { c = "50.9S, 12.6E", l = "" },
  } },
  { id = 1112, name = "Spitpyre, Scourge of Talath Úrui", level = 115, race = "Drake", raceES = "Dragonzuelo", note = "", zone = "Talath Úrui", map = "29.jpg", rewards = { { type = "RELIQUE_ALLEGEANCE", value = "1" } }, coords = {
    { c = "52.9S, 14.4E", l = "" },
    { c = "57.0S, 15.9E", l = "" },
    { c = "62.5S, 25.5E", l = "" },
    { c = "60.8S, 26.3E", l = "" },
    { c = "61.7S, 15.8E", l = "" },
  } },
  { id = 1115, name = "Uiliúr, the Ancient Evil", level = 115, race = "Caerog", note = "the quest will be unlocked only after killing the 5 others Ancient Evil of Gorgoroth", zone = "Talath Úrui", map = "29.jpg", rewards = { { type = "RELIQUE_ALLEGEANCE", value = "1" } }, coords = {
    { c = "58.6S, 20.7E", l = "" },
  } },
  { id = 1114, name = "Bolvág the Cursed, Scourge of Agarnaith", level = 115, race = "Troll", raceES = "Trol", note = "", zone = "Agarnaith", map = "30.jpg", rewards = { { type = "RELIQUE_ALLEGEANCE", value = "1" } }, coords = {
    { c = "47.0S, 33.5E", l = "" },
    { c = "52.5S, 25.5E", l = "" },
    { c = "56.1S, 24.7E", l = "" },
  } },
  { id = 1009, name = "Epilogue: Amardam, the Ancient Evil", level = 100, race = "Nameless", note = "You must have completed all 5 previous RT quests in order to do this Epilogue.", zone = "Angmar", map = "9.jpg", rewards = { { type = "MARQUE_DONATEUR", value = "3" } }, coords = {
    { c = "0.2N, 27.4W", l = "" },
  } },
  { id = 5072, name = "Crugaul", level = 28, race = "Lath-bear", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "37.5S, 52.8W", l = "" },
    { c = "37.7S, 53.4W", l = "" },
  } },
  { id = 5074, name = "Agerbrath", level = 27, race = "Spider", raceES = "Araña", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "41.7S, 54.1W", l = "" },
    { c = "42.4S, 54.6W", l = "" },
  } },
  { id = 5075, name = "Penthul", level = 26, race = "Death", raceES = "Muerte", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "42.0S, 51.0W", l = "" },
    { c = "42.4S, 52.2W", l = "" },
  } },
  { id = 5070, name = "Withergrip", nameES = "Agarremarchito", level = 25, race = "Death", raceES = "Muerte", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "41.4S, 49.3W", l = "" },
    { c = "42.3S, 49.5W", l = "" },
  } },
  { id = 5073, name = "Borhashat", level = 24, race = "Orc", raceES = "Orco", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "48.9S, 34.1W", l = "" },
    { c = "49.3S, 34.0W", l = "" },
  } },
  { id = 5068, name = "Tarangarn", level = 23, race = "Auroch", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "54.2S, 53.0W", l = "" },
    { c = "53.7S, 51.7W", l = "" },
  } },
  { id = 5076, name = "Drugodech", level = 22, race = "Wolf", raceES = "Lobo", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "47.4S, 50.0W", l = "" },
    { c = "46.6S, 50.2W", l = "" },
  } },
  { id = 5071, name = "Skrizug", level = 21, race = "Orc", raceES = "Orco", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "41.6S, 33.3W", l = "" },
    { c = "42.4S, 34.4W", l = "" },
  } },
  { id = 5069, name = "Turch", level = 20, race = "Boar", raceES = "Jabalí", note = "", zone = "Cardolan", map = "70.jpg", rewards = {}, coords = {
    { c = "46.3S, 28.1W", l = "" },
    { c = "46.2S, 28.8W", l = "" },
  } },
  { id = 5077, name = "Drindolf", level = 19, race = "Huorn", raceES = "Ucorno", note = "", zone = "Swanfleet", zoneES = "la Ciénaga de los Cisnes", map = "69.jpg", rewards = {}, coords = {
    { c = "47.7S, 21.4W", l = "" },
    { c = "48.2S, 22.2W", l = "" },
  } },
  { id = 5078, name = "Norlúg", level = 18, race = "Worm", raceES = "Sierpe", note = "", zone = "Swanfleet", zoneES = "la Ciénaga de los Cisnes", map = "69.jpg", rewards = {}, coords = {
    { c = "50.4S, 25.5W", l = "" },
    { c = "49.7S, 25.7W", l = "" },
  } },
  { id = 5079, name = "Stoneback", nameES = "Corazapiedra", level = 16, race = "Turtle", raceES = "Tortuga", note = "", zone = "Swanfleet", zoneES = "la Ciénaga de los Cisnes", map = "69.jpg", rewards = {}, coords = {
    { c = "52.2S, 26.6W", l = "" },
    { c = "51.8S, 25.6W", l = "" },
  } },
  { id = 5080, name = "Thostmoth", nameES = "Mugropolilla", level = 15, race = "Bog-lurker", raceES = "Acechador de pantano", note = "", zone = "Swanfleet", zoneES = "la Ciénaga de los Cisnes", map = "69.jpg", rewards = {}, coords = {
    { c = "52.7S, 32.6W", l = "" },
    { c = "53.4S, 33.7W", l = "" },
  } },
  { id = 5081, name = "Gristbite", nameES = "Muerdearenas", level = 13, race = "Neekerbreeker", raceES = "Niquebrique", note = "", zone = "Swanfleet", zoneES = "la Ciénaga de los Cisnes", map = "69.jpg", rewards = {}, coords = {
    { c = "52.5S, 29.1W", l = "" },
  } },
  { id = 5082, name = "Gnaw", nameES = "Mordisquitos", level = 12, race = "Shrew", raceES = "Musaraña", note = "", zone = "Swanfleet", zoneES = "la Ciénaga de los Cisnes", map = "69.jpg", rewards = {}, coords = {
    { c = "60.0S, 25.6W", l = "" },
    { c = "61.1S, 25.7W", l = "" },
    { c = "61.3S, 26.6W", l = "" },
  } },
}
