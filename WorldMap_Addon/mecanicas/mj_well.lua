-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["well"] = {
  { "Ambarûli Crocodile Hatchling", {
    { "Bite", "C", 3, 0, nil, nil, nil },
  } },
  { "Mûkh Bahora, the Mouth of Forgetting", {
    { "Venomous Bite", "P", 10, 8, { 1090522396 }, nil, nil, nil, { "Mordedura Venenosa", "Mordedura venenosa" } },
    { "Cocoon", "SW", 35, 20, { 1090529649 }, nil, nil, nil, { "Capullo" } },
    { "Cleaving Strike", "C", 0, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Thrash", "A", 14, 0, nil, nil, nil },
    { "Stunning Blow", "K", 18, 0, nil, nil, nil, nil, { "Golpe aturdidor", "Golpe Aturdidor" } },
    { "War Horn", "AF", 30, 0, { 1091831486 }, nil, nil, nil, { "Cuerno de guerra" } },
    { "Bite", "C", 0, 0, nil, nil, nil },
    { "Savage Bite", "C", 10, 0, { 1090555733 }, nil, nil, nil, { "Mordisco salvaje" } },
  } },
  { "Utûgi Shade", {
    { "Shadow Smite", "T", 20, 5, nil, nil, nil, nil, { "Golpe de Sombra", "Golpe de sombra" } },
  } },
  { "Ordâkhai Champion", {
    { "Reaching Attack", "L", 10, 5, nil, nil, nil },
    { "Sweeping Attack", "L", 10, 5, nil, nil, nil, nil, { "un ataque de barrido", "Ataque Barrido" } },
  } },
  { "Bahádring the Unmindful", {
    { "Memory of Pain", "C", 1, 0, nil, nil, nil, nil, { "Recuerdo de dolor" } },
    { "Lash of Anger", "C", 4, 0, nil, nil, nil, nil, { "Latigazo de ira" } },
    { "Curse of Regret", "A", 60, 5, nil, { "feel the weight of your regret", "siente el peso de tu arrepentimi", "you are cursed by your regret", "estás maldito por tu arrepentim" }, nil, nil, { "Maldición del arrepentimiento" } },
    { "Abolition of Self", "R", 65, 30, { 1090553954 }, nil, nil, nil, { "Abolición del yo" } },
  } },
  { "Gorthorog Berserker", {
    { "Crushing Blow", "A", 10, 10, nil, nil, nil, nil, { "Golpe Aplastante", "Golpe aplastante" } },
    { "Weapon Breaker", "C", 10, 12, { 1091455326 }, nil, nil, nil, { "Rompearmas" } },
    { "Crushing Sweep", "CK", 10, 3, nil, nil, nil, nil, { "Barrido aplastante" } },
    { "Corrupting Sweep", "C", 12, 6, { 1092995736 }, nil, nil, nil, { "Barrido corruptor" } },
  } },
  { "Ordâkhai Warrior", {
    { "Jagged Cut", "C", 10, 5, nil, nil, nil, nil, { "Corte Dentado" } },
    { "Reaching Attack", "L", 10, 5, nil, nil, nil },
  } },
  { "Ordâkhai Dôlo", {
    { "Ordâkhai Blessing", "I", 25, 5, { 1092403846 }, nil, nil, nil, { "Bendición de Ordâkhai" } },
    { "Call Allies", "I", 99999, 15, nil, nil, nil, nil, { "Llamar a los Aliados" } },
    { "Restore Morale", "IA", 35, 10, nil, nil, nil, nil, { "Restaurar Moral" } },
  } },
  { "Ambarûli Crocodile Shade", {
    { "Shadow Smite", "T", 20, 5, nil, nil, nil, nil, { "Golpe de Sombra", "Golpe de sombra" } },
  } },
  { "Gorthorog Crusher", {
    { "Armour Crusher", "C", 10, 10, nil, nil, nil },
    { "Guard Breaker", "C", 10, 15, { 1090532210 }, nil, nil },
    { "Crushing Blow", "CW", 15, 6, { 1090531521 }, nil, nil, nil, { "Golpe Aplastante", "Golpe aplastante" } },
    { "Corrupting Sweep", "C", 18, 12, { 1092995736 }, nil, nil, nil, { "Barrido corruptor" } },
  } },
  { "Ambarûli Crocodile", {
    { "Bite", "C", 5, 0, nil, nil, nil },
  } },
  { "Gorthorog Devastator", {
    { "Quick Slam", "C", 1, 0, nil, nil, nil, nil, { "Golpe rápido", "Golpe Rápido" } },
    { "Slam", "C", 2, 0, nil, nil, nil },
    { "Heavy Slam", "C", 8, 0, { 1090523949 }, nil, nil, nil, { "Golpe pesado" } },
    { "Corrupting Sweep", "C", 20, 12, { 1092995736 }, nil, nil, nil, { "Barrido corruptor" } },
    { "Execute", "T", 15, 15, nil, nil, nil, nil, { "Ejecutar" } },
    { "Endure", "I", 25, 10, nil, nil, nil },
    { "Chain Breaker", "AK", 45, 30, { 1092404616 }, nil, nil },
    { "Crushing Blow", "A", 10, 10, nil, nil, nil, nil, { "Golpe Aplastante", "Golpe aplastante" } },
    { "Weapon Breaker", "C", 10, 12, { 1091455326 }, nil, nil, nil, { "Rompearmas" } },
    { "Crushing Sweep", "CK", 10, 3, nil, nil, nil, nil, { "Barrido aplastante" } },
    { "Armour Crusher", "C", 10, 10, nil, nil, nil },
    { "Guard Breaker", "C", 10, 15, { 1090532210 }, nil, nil },
  } },
  { "Utûgi Slaughterer", {
    { "Cleaving Strike", "C", 5, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Thrash", "A", 12, 12, nil, nil, nil },
    { "Stunning Blow", "K", 25, 16, nil, nil, nil, nil, { "Golpe aturdidor", "Golpe Aturdidor" } },
  } },
  { "Bauko, Left Hand of Forgetting", {
    { "Brother's Bellow", "AB", 50, 20, { 1092995715, 1092995733 }, { "and you brother take my blessing", "y tú hermano recibe mi bendici�", "be heartened brother", "anímate hermano" }, nil, nil, { "Bramido de hermano" } },
    { "Mournful Bellow", "A", 30, 20, nil, { "brother you will be avenged", "hermano serás vengado" }, nil, nil, { "Bramido lastimero" } },
    { "Sludge Pot", "S", 20, 15, nil, nil, nil },
    { "The Water's Kiss", "I", 20, 20, { 1091686947, 1092926705 }, nil, nil, nil, { "El beso del agua" } },
    { "Field Survey", "A", 18, 15, nil, { "engage me in battle", "come back and face me" }, nil },
    { "Find Enemy", "A", 18, 15, { 1092830866 }, { "engage me in battle", "come back and face me" }, nil, nil, { "Encontrar enemigo" } },
    { "The Arrow's Kiss", "F", 25, 10, { 1092995724 }, nil, nil, nil, { "El beso de la flecha" } },
    { "Piercing Arrow", "W", 10, 5, { 1090555713 }, nil, nil, nil, { "Flecha perforante" } },
  } },
  { "Utûgi Destroyer", {
    { "Cleaving Strike", "C", 5, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
  } },
  { "Ordâkhai Skulker", {
    { "Jagged Cut", "C", 2, 5, nil, nil, nil, nil, { "Corte Dentado" } },
  } },
  { "Imhûlari Trapper", {
    { "Venomous Bite", "P", 12, 10, { 1090522396 }, nil, nil, nil, { "Mordedura Venenosa", "Mordedura venenosa" } },
  } },
  { "Imhûlari Spider Shade", {
    { "Shadow Smite", "T", 20, 5, nil, nil, nil, nil, { "Golpe de Sombra", "Golpe de sombra" } },
  } },
  { "Khûdi Shadow-spreader", {
    { "Shadow Smite", "T", 20, 5, nil, nil, nil, nil, { "Golpe de Sombra", "Golpe de sombra" } },
  } },
  { "Ordâkhai Bowman", {
    { "Piercing Arrow", "W", 10, 5, { 1090555713 }, nil, nil, nil, { "Flecha perforante" } },
  } },
  { "Ordâkhai Sorcerer", {
    { "Weak Ordâkhai Blessing", "I", 20, 5, { 1092403827 }, nil, nil, nil, { "Bendición Débil de Ordâkhai" } },
    { "Shadow Burst (distributed)", "G", 10, 0, nil, nil, nil },
  } },
  { "Daiko, Right Hand of Forgetting", {
    { "Brother's Bellow", "AB", 50, 20, { 1092995715, 1092995733 }, { "brother take my blessing", "hermano recibe mi bendición", "do not fall my brother", "no caigas hermano mío" }, nil, nil, { "Bramido de hermano" } },
    { "Mournful Bellow", "A", 30, 20, nil, { "brother you will be avenged", "hermano serás vengado" }, nil, nil, { "Bramido lastimero" } },
    { "Sludge Pot", "S", 20, 15, nil, nil, nil },
    { "The Water's Kiss", "I", 20, 20, { 1091686947, 1092926705 }, nil, nil, nil, { "El beso del agua" } },
    { "Field Survey", "A", 18, 15, nil, { "face me or die", "enfréntame o muere", "you shall not run from me", "no huirás de mí" }, nil },
    { "Find Enemy", "A", 18, 15, { 1090541218 }, { "face me or die", "enfréntame o muere", "you shall not run from me", "no huirás de mí" }, nil, nil, { "Encontrar enemigo" } },
    { "The Spear's Kiss", "F", 25, 10, { 1092995723 }, nil, nil, nil, { "El beso de la lanza" } },
    { "Reaching Spear", "L", 5, 5, nil, { "my blade shall cut you", "mi espada te cortará", "my blade is as the wind", "mi espada es como el viento" }, nil, nil, { "Lanza de alcance" } },
    { "Sweeping Spear", "L", 7, 5, nil, { "defend the flank", "defiende el flanco" }, nil },
    { "Spear of Deadly Shadow", "LS", 10, 15, nil, nil, nil, nil, { "Lanza de sombra mortal" } },
  } },
  { "Giant Ambarûli Crocodile", {
    { "Bite", "C", 5, 0, nil, nil, nil },
    { "Savage Bite", "C", 10, 2, { 1090555733 }, nil, nil, nil, { "Mordisco salvaje" } },
  } },
  { "Ordâkhai Cat-keeper", {
    { "Piercing Arrow", "W", 10, 5, { 1090555713 }, nil, nil, nil, { "Flecha perforante" } },
  } },
}
