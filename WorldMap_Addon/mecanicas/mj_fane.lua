-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["fane"] = {
  { "Anâkhi Apothecary", {
    { "Invigourating Fumes", "I", 25, 20, nil, nil, nil, nil, { "Vapores vigorizantes" } },
  } },
  { "Anâkhi Poisoner", {
    { "Death-light Venom", "P", 25, 20, { 1090616922 }, nil, nil, nil, { "Veneno de luz mortal" } },
    { "Poisonous Mixture", "P", 1, 0, { 1090522396 }, nil, nil, nil, { "Mezcla venenosa" } },
  } },
  { "Vicious Scorpion", {
    { "Venomous Sting", "P", 30, 20, { 1091657100 }, nil, nil, nil, { "Aguijón venenoso", "Aguijón Venenoso" } },
  } },
  { "Anâkhi Sorcerer", {
    { "Stinger Shock", "IK", 25, 20, nil, nil, nil, nil, { "Choque de aguijón" } },
    { "Poisonous Mixture", "P", 1, 0, { 1090522396 }, nil, nil, nil, { "Mezcla venenosa" } },
  } },
  { "Prowling Scorpion", {
    { "Crippling Sting", "K", 20, 10, { 1090522398 }, nil, nil },
  } },
  { "Anâkhi Brawler", {
    { "Heavy Strike", "W", 20, 10, { 1090539333 }, nil, nil, nil, { "Golpe pesado" } },
  } },
  { "Sharâtu", {
    { "Desolation Bolt", "I", 30, 15, nil, { "i will end you", "acabaré contigo" }, nil, nil, { "Rayo de desolación" } },
    { "Fatal Toxin", "SP", 15, 10, { 1091657100 }, { "suffer the sting", "sufre el aguijón" }, nil, nil, { "Toxina fatal" } },
    { "Toxic Cloud", "P", 15, 5, { 1091400596, 1092745487, 1092745493, 1092745491 }, { "breathe in your death" }, nil, nil, { "Nube tóxica" } },
    { "Death-light Venom", "P", 25, 20, { 1090616922 }, nil, nil, nil, { "Veneno de luz mortal" } },
    { "Poisonous Mixture", "P", 1, 0, { 1090522396 }, nil, nil, nil, { "Mezcla venenosa" } },
  } },
  { "Kizurdâl", {
    { "Blessing of the Usan-kûni", "I", 25, 15, nil, { "nâkhugir hear me", "nâkhugir escúchame" }, nil, nil, { "Bendición de los Usan-kûni" } },
    { "Toxic Defilement", "SP", 10, 5, { 1090535377 }, { "you grow weak", "te debilitas" }, nil, nil, { "Profanación tóxica" } },
    { "Invigourating Fumes", "I", 25, 20, nil, nil, nil, nil, { "Vapores vigorizantes" } },
  } },
  { "Hashûga", {
    { "Serrated Strike", "W", 15, 5, { 1090580244 }, nil, nil, nil, { "Golpe serrado" } },
    { "Battle Cry", "A", 30, 10, nil, { "your strength fades", "tu fuerza se desvanece" }, nil, nil, { "Grito de batalla", "Grito de Batalla" } },
    { "Brutal Swing", "CW", 8, 8, { 1090531521 }, { "break before me" }, nil, nil, { "Golpe Brutal" } },
    { "Heavy Strike", "W", 20, 10, { 1090539333 }, nil, nil, nil, { "Golpe pesado" } },
  } },
  { "Nâkhugir", {
    { "Toxic Puncture", "P", 20, 10, { 1091657100 }, nil, nil, nil, { "Punción tóxica" } },
    { "Vile Excretion", "P", 20, 10, { 1090523091, 1091400596, 1092745487, 1092745493, 1092745491 }, nil, nil, nil, { "Excreción vil" } },
  } },
  { "Eshêgur the Reaper", {
    { "Thunderous Stomp", "K", 15, 10, nil, { "kneel weaklings", "arrodíllense debiluchos" }, nil },
    { "Single Out", "R", 30, 20, { 1091798547, 1090552047 }, nil, nil },
    { "Killing Blow", "T", 20, 40, nil, nil, nil, nil, { "Golpe mortal" } },
    { "Brutal Swing", "CW", 12, 12, { 1090531521 }, { "i ll cleave you in two", "te partiré en dos" }, nil, nil, { "Golpe Brutal" } },
    { "Intimidating Presence", "AS", 20, 5, nil, nil, nil, nil, { "Presencia intimidante" } },
    { "Poisoned Blade", "P", 8, 6, { 1090523646 }, nil, nil, nil, { "Hoja envenenada", "Hoja Envenenada", "Hoja Envenenada II", "Hoja Envenenada IV", "Hoja Envenenada I", "Hoja Envenenada III", "Hoja Envenenada V" } },
    { "Lesser Cleave", "C", 2, 0, nil, nil, nil, nil, { "Corte menor", "Hendidura menor" } },
    { "Primer Cleave", "C", 5, 0, nil, nil, nil },
    { "Major Cleave", "C", 5, 0, nil, nil, nil, nil, { "Hendidura mayor" } },
    { "Radial Cut", "A", 1, 0, nil, nil, nil, nil, { "Corte radial" } },
    { "Distributed Cut", "AG", 1, 0, nil, nil, nil, nil, { "Corte distribuido" } },
  } },
}
