-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["koh_rts"] = {
  { "Agáthar the Bereft", {
    { "Kick", "K", 18, 3, nil, nil, nil },
    { "Rush", "LK", 30, 3, nil, nil, nil },
    { "Great Smash", "C", 12, 3, { 1093004344 }, nil, nil },
    { "Raging Roar", "CH", 6, 2, nil, nil, nil, nil, { "Rugido furioso" } },
    { "Raging Smash", "AK", 20, 0, { 1090523648 }, nil, nil, nil, { "Golpe Furioso", "Golpe furioso" } },
    { "Cloud of Spores", "H", 40, 15, { 1090535377 }, nil, nil, nil, { "Nube de esporas" } },
    { "Blighted Roar", "H", 30, 5, { 1091609090, 1092806781, 1091478916 }, nil, nil },
    { "Sea of Thorns", "A", 30, 5, { 1091402400 }, nil, nil, nil, { "Mar de espinas" } },
  } },
  { "Bloodtooth", {
    { "Shadow Surge", "SKW", 25, 10, { 1090531521 }, nil, nil, nil, { "Oleada de sombras" } },
    { "Ravage", "SW", 20, 15, { 1090539333 }, nil, nil, nil, { "Devastación" } },
    { "Savage Fangs", "T", 15, 7, { 1091429288 }, nil, nil, nil, { "Colmillos salvajes" } },
    { "Rallying Call", "A", 30, 20, { 1091570801 }, nil, nil, nil, { "Llamada de reunión" } },
    { "Doom Howl", "A", 0, 0, { 1091477785, 1092806781 }, nil, nil },
    { "Dread Howl", "A", 0, 0, nil, nil, nil },
    { "Frenzy", "R", -1, 0, { 1090528807 }, nil, nil, nil, { "Frenesí" } },
    { "Unsettled", "F", 0, 0, { 1090528808 }, nil, nil },
    { "Lesser Dread", "F", 0, 0, { 1090528810 }, nil, nil, nil, { "Pavor menor" } },
    { "Chilled", "F", 0, 0, { 1090528808 }, nil, nil },
    { "Dread", "F", 0, 0, { 1090528810 }, nil, nil, nil, { "Pavor" } },
    { "Suppressed Trauma", "KF", 0, 0, { 1090528811, 1090522263 }, nil, nil, nil, { "Trauma Suprimido" } },
  } },
  { "Imtushâl the Gall-spitter", {
    { "Call Hatchling", "AK", 20, 8, nil, nil, nil, nil, { "Llamar a la cría" } },
    { "Noxious Storm", "AX", 0, 5, { 1092943405, 1091657100, 1090648226 }, nil, nil, nil, { "Tormenta Nociva" } },
    { "Noxious Rain", "APX", 0, 5, { 1092943405, 1091479198, 1090648226 }, nil, nil, nil, { "Lluvia nociva" } },
    { "Wing Buffet", "CK", 30, 3, nil, nil, nil, nil, { "Golpe de ala" } },
    { "Tail Swipe", "CSKW", 10, 3, { 1090522393, 1090580244 }, nil, nil, nil, { "Barrido de cola" } },
    { "Acid Pool", "K", 20, 15, { 1090535377 }, nil, nil, nil, { "Charco de ácido" } },
    { "Terrible Roar", "A", 18, 3, nil, nil, nil, nil, { "Rugido terrible" } },
    { "Restoration", "AK", 45, 3, { 1092979838, 1091609090 }, nil, nil, nil, { "Restauración" } },
  } },
  { "Daithor, Terror of An Shêru", {
    { "Gash", "A", 15, 15, { 1090553355 }, nil, nil },
    { "Wound Splitter", "C", 20, 10, { 1090531635 }, nil, nil },
    { "Axe Pummel", "C", 1, 0, nil, nil, nil, nil, { "Golpe de hacha" } },
    { "Not So Fast", "K", 10, 15, nil, nil, nil, nil, { "¡No tan rápido!", "No tan rápido" } },
  } },
  { "Daithor's Slaughterer", {
    { "Cleaving Strike", "C", 2, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
    { "Forceful Slash", "CK", 30, 0, nil, nil, nil },
    { "Intimidating Roar", "SKF", 45, 0, { 1090522263, 1090528808 }, nil, nil, nil, { "Rugido intimidante" } },
    { "Aura of Command", "I", 60, 0, { 1090555721 }, nil, nil, nil, { "Aura de mando" } },
  } },
  { "Daithor's Devastator", {
    { "Sweep", "C", 8, 5, nil, nil, nil, nil, { "Barrido" } },
    { "Thresh the Chaff", "CK", 12, 5, nil, nil, nil, nil, { "Trillar la paja" } },
    { "Jagged Cut", "CSW", 15, 0, { 1090553355 }, nil, nil, nil, { "Corte Dentado" } },
  } },
  { "Daithor's Obliterator", {
    { "Poisoned Dart", "IP", 20, 0, { 1090523646 }, nil, nil, nil, { "Dardo envenenado" } },
    { "Jagged Arrow", "W", 1, 0, { 1090541187 }, nil, nil, nil, { "Flecha dentada" } },
    { "Split Shot", "IW", 10, 5, { 1090553904 }, nil, nil },
  } },
  { "Summoned Root", {
    { "Sweep", "C", 5, 0, nil, nil, nil, nil, { "Barrido" } },
  } },
  { "Pack Heckler", {
    { "Unsettled", "F", 0, 0, { 1090528808 }, nil, nil },
    { "Lesser Dread", "F", 0, 0, { 1090528810 }, nil, nil, nil, { "Pavor menor" } },
    { "Chilled", "F", 0, 0, { 1090528808 }, nil, nil },
    { "Dread", "F", 0, 0, { 1090528810 }, nil, nil, nil, { "Pavor" } },
    { "Suppressed Trauma", "KF", 0, 0, { 1090528811, 1090522263 }, nil, nil, nil, { "Trauma Suprimido" } },
  } },
  { "Pack Elder", {
    { "Ravage", "W", 22, 15, { 1090539333 }, nil, nil, nil, { "Devastación" } },
    { "Frenzy", "R", -1, 0, { 1090528807 }, nil, nil, nil, { "Frenesí" } },
    { "Unsettled", "F", 0, 0, { 1090528808 }, nil, nil },
    { "Lesser Dread", "F", 0, 0, { 1090528810 }, nil, nil, nil, { "Pavor menor" } },
    { "Chilled", "F", 0, 0, { 1090528808 }, nil, nil },
    { "Dread", "F", 0, 0, { 1090528810 }, nil, nil, nil, { "Pavor" } },
    { "Suppressed Trauma", "KF", 0, 0, { 1090528811, 1090522263 }, nil, nil, nil, { "Trauma Suprimido" } },
  } },
  { "Wild-drake Youngling", {
    { "Breath of Acid", "IC", 15, 0, nil, nil, nil, nil, { "Aliento de ácido" } },
  } },
  { "Wild-drake Brood-tender", {
    { "Noxious Breath", "ICWP", 17, 8, { 1091475964, 1091479196, 1090523648 }, nil, nil, nil, { "Aliento nocivo" } },
    { "Acid Burst", "LP", 12, 5, { 1091475964, 1091479196 }, nil, nil },
    { "Tail Swipe", "CSKW", 20, 10, { 1090522393, 1090580244 }, nil, nil, nil, { "Barrido de cola" } },
  } },
}
