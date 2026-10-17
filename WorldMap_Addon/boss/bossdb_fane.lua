-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["fane"] = {
  { "Anâkhi Apothecary", {
    { "Invigourating Fumes", "I", 25, 20, 10, nil, nil, "Single Target" },
  } },
  { "Anâkhi Poisoner", {
    { "Death-light Venom", "P", 25, 20, nil, { 1090616922 }, nil, "Single Target" },
    { "Poisonous Mixture", "P", 1, 0, nil, { 1090522396 }, nil, "Single Target" },
  } },
  { "Vicious Scorpion", {
    { "Venomous Sting", "P", 30, 20, nil, { 1091657100 }, nil, "Single Target" },
  } },
  { "Anâkhi Sorcerer", {
    { "Stinger Shock", "IK", 25, 20, 10, nil, nil, "Single Target" },
    { "Poisonous Mixture", "P", 1, 0, nil, { 1090522396 }, nil, "Single Target" },
  } },
  { "Anâkhi Scrapper", {
    { "a sweeping melee attack", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
  } },
  { "Prowling Scorpion", {
    { "Crippling Sting", "K", 20, 10, nil, { 1090522398 }, nil, "Single Target" },
  } },
  { "Anâkhi Brawler", {
    { "Heavy Strike", "W", 20, 10, nil, { 1090539333 }, nil, "Single Target" },
    { "a sweeping melee attack", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
  } },
  { "Sharâtu", {
    { "Desolation Bolt", "I", 30, 15, 5, nil, { "i will end you" }, "Single Target" },
    { "Fatal Toxin", "SP", 15, 10, nil, { 1091657100 }, { "suffer the sting" }, "Single Target" },
    { "Toxic Cloud", "P", 15, 5, nil, { 1091400596, 1092745487, 1092745493, 1092745491 }, { "breathe in your death" }, "Single Target" },
    { "Death-light Venom", "P", 25, 20, nil, { 1090616922 }, nil, "Single Target" },
    { "Poisonous Mixture", "P", 1, 0, nil, { 1090522396 }, nil, "Single Target" },
  } },
  { "Kizurdâl", {
    { "Blessing of the Usan-kûni", "I", 25, 15, 3, nil, { "nâkhugir hear me" }, "Single Target" },
    { "Toxic Defilement", "SP", 10, 5, nil, { 1090535377 }, { "you grow weak" }, "Single Target" },
    { "Invigourating Fumes", "I", 25, 20, 10, nil, nil, "Single Target" },
  } },
  { "Hashûga", {
    { "Serrated Strike", "W", 15, 5, 1, { 1090580244 }, nil, "Single Target" },
    { "Battle Cry", "A", 30, 10, nil, { 1092257246 }, { "your strength fades" }, "60.0m around Self" },
    { "Brutal Swing", "CW", 8, 8, 4, { 1090531521 }, { "break before me" }, "120° by 4.5m arc from Self" },
    { "a sweeping melee attack", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Heavy Strike", "W", 20, 10, nil, { 1090539333 }, nil, "Single Target" },
  } },
  { "Nâkhugir", {
    { "Toxic Puncture", "P", 20, 10, nil, { 1091657100 }, nil, "Single Target" },
    { "Vile Excretion", "P", 20, 10, nil, { 1090523091, 1091400596, 1092745487, 1092745493, 1092745491 }, nil, "Single Target" },
  } },
  { "Eshêgur the Reaper", {
    { "Thunderous Stomp", "K", 15, 10, 2, nil, { "kneel weaklings" }, "3.0m around Self" },
    { "Single Out", "R", 30, 20, nil, { 1091798547, 1090552047 }, nil, "Single Target" },
    { "Killing Blow", "T", 20, 40, nil, nil, nil, "Single Target" },
    { "Brutal Swing", "CW", 12, 12, 4, { 1090531521 }, { "i ll cleave you in two" }, "120° by 4.5m arc from Self" },
    { "Intimidating Presence", "AS", 20, 5, nil, nil, nil, "30.0m around Self" },
    { "Poisoned Blade", "P", 8, 6, nil, { 1090523646 }, nil, "Single Target" },
    { "a sweeping melee attack", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Lesser Cleave", "C", 2, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Primer Cleave", "C", 5, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Major Cleave", "C", 5, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Radial Cut", "A", 1, 0, nil, nil, nil, "5.0m around Self" },
    { "Distributed Cut", "A", 1, 0, nil, nil, nil, "5.0m around Self | distributed damage" },
  } },
}
