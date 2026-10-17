-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["garden"] = {
  { "Takâltu the Weaponmaster", {
    { "Poisoned Rend", "AK", 15, 10, 2, { 1092979848, 1091423618 }, { "fall to my blade" }, "4.0m around Self" },
    { "Gutting Cleave", "CSK", 20, 0, 2, { 1091401111, 1091423618 }, { "through your heart" }, "45° by 15.0m arc from Self" },
    { "a moderate swipe attack", "CS", 20, 15, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "Wounding Slash", "SK", 15, 5, 2.5, { 1090531635, 1091423618 }, nil, "5.0m by 30.0m rectangle from Self" },
  } },
  { "Kishâsu the Knowing", {
    { "Vile Spew", "CS", 15, 5, nil, { 1092979848 }, nil, "90° by 15.0m arc from Self" },
    { "Shadowy Charge", "B", 30, 30, nil, { 1091476413 }, nil, "Single Target" },
    { "Ritual of the Dead", "A", 2, 0, nil, nil, nil, "5.0m around Self" },
  } },
  { "Ritual Statue", {
    { "Unnerving Gaze", "A", 10, 10, nil, nil, nil, "50.0m around Self | 6 max targets" },
  } },
  { "Second Age Warrior", {
    { "Uncontrolled Rage", "H", 5, 2, nil, { 1091479052, 1091479053, 1091479054, 1091479055, 1091479056 }, nil, "Single Target" },
    { "Rending Cleave", "C", 15, 5, nil, { 1091401111 }, nil, "45° by 5.0m arc from Self" },
  } },
  { "Empowered Second Age Warrior", {
    { "Uncontrolled Rage", "H", 5, 2, nil, { 1091479052, 1091479053, 1091479054, 1091479055, 1091479056 }, nil, "Single Target" },
    { "Rending Cleave", "C", 15, 5, nil, { 1091401111 }, nil, "45° by 5.0m arc from Self" },
  } },
  { "Second Age Archer", {
    { "Silencing Shot", "SKF", 15, 8, 1, { 1090522263 }, nil, "Single Target" },
  } },
  { "Empowered Second Age Archer", {
    { "Silencing Shot", "SKF", 15, 8, 1, { 1090522263 }, nil, "Single Target" },
  } },
  { "Second Age Tender", {
    { "Revitalize", "I", 20, 10, 4, nil, nil, "Single Target" },
  } },
  { "Empowered Second Age Tender", {
    { "Revitalize", "I", 20, 10, 4, nil, nil, "Single Target" },
  } },
  { "Second Age Guardsman", {
    { "Bulwark of the Dead", "AK", 40, 20, 2, { 1092979838, 1093005420, 1091423618 }, nil, "10.0m around Self" },
    { "Heavy Cleave", "CK", 20, 10, 2, { 1091423618 }, nil, "45° by 15.0m arc from Self" },
  } },
  { "Empowered Second Age Guardsman", {
    { "Bulwark of the Dead", "AK", 40, 20, 2, { 1092979838, 1093005420, 1091423618 }, nil, "10.0m around Self" },
    { "Heavy Cleave", "CK", 20, 10, 2, { 1091423618 }, nil, "45° by 15.0m arc from Self" },
  } },
  { "Khardâmu Blood-sworn", {
    { "Consuming Call", "A", 60, 55, 2, { 1091479052, 1091479053, 1091479054, 1091479055, 1091479056 }, nil, "60.0m around Self" },
    { "Harrowing Slash", "T", 25, 15, 2, { 1092407345, 1090539274 }, { "you cannot run from me" }, "Single Target" },
    { "Roar of Battle", "A", 15, 0, nil, nil, nil, "60.0m around Self | 6 max targets" },
    { "Heavy Cleave", "C", 10, 2, nil, nil, { "crumble before me" }, "45° by 15.0m arc from Self" },
  } },
  { "Blood-sworn Guard", {
    { "Grave Rend", "SK", 5, 0, 2.5, { 1091402348, 1091423618 }, nil, "5.0m by 30.0m rectangle from Self" },
    { "Wail of the Fallen", "ASK", 5, 0, 3, { 1091401418, 1091423618 }, nil, "5.0m around Self" },
  } },
  { "Ushkudâsh", {
    { "Tail Swipe", "K", 15, 18, nil, nil, nil, "Single Target" },
    { "Shadow Breath", "C", 35, 15, 2, nil, nil, "90° by 45.0m arc from Self" },
    { "Wing Flap", "AK", 30, 20, nil, nil, nil, "100.0m around Self" },
    { "Rain of Shadows", "A", 45, 40, 2, nil, nil, "5.0m around Self" },
    { "Call to Nuzêru", "A", 180, 60, 3, { 1092401721 }, nil, "120.0m around Self" },
  } },
  { "Shadow of Ushkudâsh", {
    { "Shattering Roar", "A", 1, 0, 4, nil, nil, "80.0m around Self" },
  } },
  { "Spawn of Ushkudâsh", {
    { "Breath of Fire", "IC", 15, 5, 3, nil, nil, "45° by 4.5m arc from Self" },
  } },
  { "Second Age Conjuror", {
    { "Roar of Terror", "CSK", 25, 5, 3, { 1090625091 }, nil, "45° by 25.0m arc from Self" },
    { "Vile Spew", "CS", 10, 10, nil, { 1092979848 }, nil, "90° by 15.0m arc from Self" },
  } },
  { "Vengeful Spirit", {
    { "Roar of Terror", "CSK", 25, 5, 3, { 1090625091 }, nil, "45° by 25.0m arc from Self" },
  } },
  { "Ordâkhai Herbalist", {
    { "Revitalize", "I", 20, 10, 4, nil, nil, "Single Target" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
  } },
  { "Ordâkhai Warrior", {
    { "Uncontrolled Rage", "H", 5, 2, nil, { 1091479052, 1091479053, 1091479054, 1091479055, 1091479056 }, nil, "Single Target" },
    { "Rending Cleave", "C", 15, 5, nil, { 1091401111 }, nil, "45° by 5.0m arc from Self" },
  } },
  { "Ordâkhai Bowman", {
    { "Silencing Shot", "SKF", 15, 8, 1, { 1090522263 }, nil, "Single Target" },
  } },
  { "Ordâkhai Sorcerer", {
    { "Roar of Terror", "CK", 25, 5, 3, { 1090625091 }, nil, "45° by 25.0m arc from Self" },
    { "Deadly Bolt", "I", 10, 1, 3, nil, nil, "Single Target" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
  } },
  { "Second Age Warden", {
    { "Bulwark of the Dead", "AK", 40, 20, 2, { 1092979838, 1093005420, 1091423618 }, nil, "10.0m around Self" },
    { "Heavy Cleave", "CK", 20, 10, 2, { 1091423618 }, nil, "45° by 15.0m arc from Self" },
  } },
  { "Second Age Revenant", {
    { "Uncontrolled Rage", "H", 5, 2, nil, { 1091479052, 1091479053, 1091479054, 1091479055, 1091479056 }, nil, "Single Target" },
    { "Rending Cleave", "C", 15, 5, nil, { 1091401111 }, nil, "45° by 5.0m arc from Self" },
  } },
  { "Second Age Scout", {
    { "Silencing Shot", "SKF", 15, 8, 1, { 1090522263 }, nil, "Single Target" },
  } },
}
