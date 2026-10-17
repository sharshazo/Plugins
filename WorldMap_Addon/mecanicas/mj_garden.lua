-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["garden"] = {
  { "Takâltu the Weaponmaster", {
    { "Poisoned Rend", "AK", 15, 10, { 1092979848, 1091423618 }, { "fall to my blade", "cae ante mi espada" }, nil, nil, { "Desgarro Envenenado" } },
    { "Gutting Cleave", "CSK", 20, 0, { 1091423618 }, { "through your heart", "a través de tu corazón" }, nil },
    { "Wounding Slash", "LSK", 15, 5, { 1090531635, 1091423618 }, nil, nil },
  } },
  { "Kishâsu the Knowing", {
    { "Vile Spew", "CS", 15, 5, { 1092979848 }, nil, nil, nil, { "Vómito vil" } },
    { "Shadowy Charge", "B", 30, 30, { 1091476413 }, nil, nil, nil, { "Carga sombría" } },
    { "Ritual of the Dead", "A", 2, 0, nil, nil, nil, nil, { "Ritual de los Muertos" } },
  } },
  { "Ritual Statue", {
    { "Unnerving Gaze", "A", 10, 10, nil, nil, nil, nil, { "Mirada Inquietante" } },
  } },
  { "Second Age Warrior", {
    { "Uncontrolled Rage", "H", 5, 2, nil, nil, nil, nil, { "Furia Incontrolada" } },
    { "Rending Cleave", "C", 15, 5, nil, nil, nil, nil, { "Hendidura Desgarradora" } },
  } },
  { "Empowered Second Age Warrior", {
    { "Uncontrolled Rage", "H", 5, 2, nil, nil, nil, nil, { "Furia Incontrolada" } },
    { "Rending Cleave", "C", 15, 5, nil, nil, nil, nil, { "Hendidura Desgarradora" } },
  } },
  { "Second Age Archer", {
    { "Silencing Shot", "SKF", 15, 8, { 1090522263 }, nil, nil },
  } },
  { "Empowered Second Age Archer", {
    { "Silencing Shot", "SKF", 15, 8, { 1090522263 }, nil, nil },
  } },
  { "Second Age Tender", {
    { "Revitalize", "I", 20, 10, nil, nil, nil, nil, { "Revitalizar" } },
  } },
  { "Empowered Second Age Tender", {
    { "Revitalize", "I", 20, 10, nil, nil, nil, nil, { "Revitalizar" } },
  } },
  { "Second Age Guardsman", {
    { "Bulwark of the Dead", "AK", 40, 20, { 1092979838, 1093005420, 1091423618 }, nil, nil, nil, { "Baluarte de los Muertos" } },
    { "Heavy Cleave", "CK", 20, 10, { 1091423618 }, nil, nil },
  } },
  { "Empowered Second Age Guardsman", {
    { "Bulwark of the Dead", "AK", 40, 20, { 1092979838, 1093005420, 1091423618 }, nil, nil, nil, { "Baluarte de los Muertos" } },
    { "Heavy Cleave", "CK", 20, 10, { 1091423618 }, nil, nil },
  } },
  { "Khardâmu Blood-sworn", {
    { "Harrowing Slash", "T", 25, 15, { 1092407345, 1090539274 }, { "you cannot run from me", "no puedes huir de mí" }, nil, nil, { "Corte desgarrador", "Corte Desgarrador" } },
    { "Roar of Battle", "A", 15, 0, nil, nil, nil, nil, { "Grito de batalla", "Grito de Batalla" } },
    { "Heavy Cleave", "C", 10, 2, nil, { "crumble before me", "desmorónate ante mí" }, nil },
  } },
  { "Blood-sworn Guard", {
    { "Grave Rend", "LSK", 5, 0, { 1091402348, 1091423618 }, nil, nil, nil, { "Desgarro Sepulcral", "Desgarramiento Sepulcral" } },
    { "Wail of the Fallen", "ASK", 5, 0, { 1091401418, 1091423618 }, nil, nil, nil, { "Lamento de los caídos", "Lamento de los Caídos" } },
  } },
  { "Ushkudâsh", {
    { "Tail Swipe", "K", 15, 18, nil, nil, nil, nil, { "Barrido de cola" } },
    { "Shadow Breath", "C", 35, 15, nil, nil, nil, nil, { "Aliento de sombra" } },
    { "Wing Flap", "AK", 30, 20, nil, nil, nil, nil, { "Aleteo" } },
    { "Rain of Shadows", "A", 45, 40, nil, nil, nil, nil, { "Lluvia de sombras" } },
    { "Call to Nuzêru", "A", 180, 60, { 1092401721, 1091475959 }, nil, nil, nil, { "Llame a Nuzêru" } },
  } },
  { "Shadow of Ushkudâsh", {
    { "Shattering Roar", "A", 1, 0, nil, nil, nil },
  } },
  { "Shadow of Bârshud II", {
    { "Break Power", "L", 10, 3, nil, nil, nil, nil, { "Romper Poder" } },
  } },
  { "Spawn of Ushkudâsh", {
    { "Breath of Fire", "IC", 15, 5, nil, nil, nil, nil, { "Aliento de fuego" } },
  } },
  { "Second Age Conjuror", {
    { "Roar of Terror", "CSK", 25, 5, { 1090625091 }, nil, nil, nil, { "Rugido de Terror", "Rugido del Terror" } },
    { "Vile Spew", "CS", 10, 10, { 1092979848 }, nil, nil, nil, { "Vómito vil" } },
  } },
  { "Vengeful Spirit", {
    { "Roar of Terror", "CSK", 25, 5, { 1090625091 }, nil, nil, nil, { "Rugido de Terror", "Rugido del Terror" } },
  } },
  { "Ordâkhai Herbalist", {
    { "Revitalize", "I", 20, 10, nil, nil, nil, nil, { "Revitalizar" } },
  } },
  { "Ordâkhai Warrior", {
    { "Uncontrolled Rage", "H", 5, 2, nil, nil, nil, nil, { "Furia Incontrolada" } },
    { "Rending Cleave", "C", 15, 5, nil, nil, nil, nil, { "Hendidura Desgarradora" } },
  } },
  { "Ordâkhai Bowman", {
    { "Silencing Shot", "SKF", 15, 8, { 1090522263 }, nil, nil },
  } },
  { "Ordâkhai Sorcerer", {
    { "Roar of Terror", "CK", 25, 5, { 1090625091 }, nil, nil, nil, { "Rugido de Terror", "Rugido del Terror" } },
    { "Deadly Bolt", "I", 10, 1, nil, nil, nil, nil, { "Rayo mortal" } },
  } },
  { "Second Age Warden", {
    { "Bulwark of the Dead", "AK", 40, 20, { 1092979838, 1093005420, 1091423618 }, nil, nil, nil, { "Baluarte de los Muertos" } },
    { "Heavy Cleave", "CK", 20, 10, { 1091423618 }, nil, nil },
  } },
  { "Second Age Revenant", {
    { "Uncontrolled Rage", "H", 5, 2, nil, nil, nil, nil, { "Furia Incontrolada" } },
    { "Rending Cleave", "C", 15, 5, nil, nil, nil, nil, { "Hendidura Desgarradora" } },
  } },
  { "Second Age Scout", {
    { "Silencing Shot", "SKF", 15, 8, { 1090522263 }, nil, nil },
  } },
}
