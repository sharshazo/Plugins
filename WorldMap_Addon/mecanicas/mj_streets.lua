-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["streets"] = {
  { "Utho, the Grasper", {
    { "Cleave", "C", 8, 5, nil, nil, nil, nil, { "Hender" } },
    { "Stagger", "SW", 12, 12, { 1091415788 }, nil, nil, nil, { "Tambalear", "Tambaleo" } },
    { "Flame Splitter I", "L", 14, 5, nil, nil, nil, nil, { "Divisor de llamas I" } },
    { "Flame Splitter II", "L", 12, 5, nil, nil, nil, nil, { "Divisor de llamas II" } },
    { "Flame Splitter III", "L", 10, 5, nil, nil, nil, nil, { "Divisor de llamas III" } },
    { "Frenzy", "X", 20, 10, { 1090528807 }, nil, nil, nil, { "Frenesí" } },
  } },
  { "Jephai Trapper", {
    { "Haymaker Uppercut", "K", 45, 0, nil, nil, nil, nil, { "Gancho demoledor" } },
    { "Net I", "K", 30, 15, nil, nil, nil, nil, { "Red I" } },
    { "Net II", "K", 20, 0, nil, nil, nil, nil, { "Red II" } },
    { "Ichor I", "D", 60, 8, { 1090535377 }, nil, nil, nil, { "Icor I" } },
    { "Ichor II", "D", 45, 4, { 1090535377 }, nil, nil, nil, { "Icor II" } },
  } },
  { "Jephai Sniper", {
    { "Sniper Arrow", "IW", 15, 0, { 1090531521, 1090522261, 1091401433 }, nil, nil },
    { "Volley I", "I", 30, 15, { 1090553936 }, nil, nil },
    { "Volley II", "I", 25, 10, { 1090553936 }, nil, nil },
    { "Volley III", "I", 20, 5, { 1090553936 }, nil, nil },
  } },
  { "Khâshap, Ifrinn's Abomination", {
    { "Bone-crusher", "A", 18, 30, { 1091459632 }, nil, nil, nil, { "Rompehuesos" } },
    { "Smash", "L", 8, 5, nil, nil, nil, nil, { "Aplastar" } },
    { "Pound", "A", 12, 5, nil, nil, nil, nil, { "Machacar" } },
    { "Unstable Flame I", "X", 15, 10, { 1091609049 }, nil, nil, nil, { "Llama inestable I" } },
    { "Unstable Flame II", "X", 15, 10, { 1091609051, 1091609050, 1091609049 }, nil, nil, nil, { "Llama inestable II" } },
    { "Unstable Flame III", "X", 15, 10, { 1091609053, 1091609052, 1091609051, 1091609050, 1091609049 }, nil, nil, nil, { "Llama inestable III" } },
    { "Demand", "A", 45, 10, nil, nil, nil, nil, { "Exigir" } },
    { "Ichor I", "AD", 45, 10, { 1090535377 }, nil, nil, nil, { "Icor I" } },
    { "Ichor II", "AD", 25, 10, { 1090535377 }, nil, nil, nil, { "Icor II" } },
  } },
  { "Khâshap", {
    { "Bone-crusher", "A", 18, 30, { 1091459632 }, nil, nil, nil, { "Rompehuesos" } },
    { "Smash", "L", 8, 5, nil, nil, nil, nil, { "Aplastar" } },
    { "Pound", "A", 12, 5, nil, nil, nil, nil, { "Machacar" } },
    { "Unstable Flame I", "X", 15, 10, { 1091609049 }, nil, nil, nil, { "Llama inestable I" } },
    { "Unstable Flame II", "X", 15, 10, { 1091609051, 1091609050, 1091609049 }, nil, nil, nil, { "Llama inestable II" } },
    { "Unstable Flame III", "X", 15, 10, { 1091609053, 1091609052, 1091609051, 1091609050, 1091609049 }, nil, nil, nil, { "Llama inestable III" } },
    { "Demand", "A", 45, 10, nil, nil, nil, nil, { "Exigir" } },
    { "Ichor I", "AD", 45, 10, { 1090535377 }, nil, nil, nil, { "Icor I" } },
    { "Ichor II", "AD", 25, 10, { 1090535377 }, nil, nil, nil, { "Icor II" } },
  } },
  { "Jephai Bruiser", {
    { "Wild Slash", "K", 0, 0, nil, nil, nil, nil, { "Corte salvaje" } },
    { "Frenzied Strike I", "X", 15, 5, { 1090528807 }, nil, nil, nil, { "Golpe frenético I" } },
    { "Frenzied Strike II", "X", 15, 0, { 1090528807 }, nil, nil, nil, { "Golpe frenético II" } },
  } },
  { "Jephai Look-out", {
    { "Haymaker Uppercut", "K", 45, 0, nil, nil, nil, nil, { "Gancho demoledor" } },
    { "Call For Reinforcements I", "I", 6000, 20, nil, nil, nil, nil, { "Llamada de refuerzos I" } },
    { "Call For Reinforcements II", "I", 6000, 15, nil, nil, nil, nil, { "Llamada de refuerzos II" } },
  } },
  { "Jephai Mender", {
    { "Sniper Arrow", "IW", 15, 0, { 1090531521, 1090522261, 1091401433 }, nil, nil },
    { "Mass Heal I", "I", 60, 5, nil, nil, nil, nil, { "Curación en masa I" } },
    { "Mass Heal II", "I", 30, 10, nil, nil, nil, nil, { "Curación en masa II" } },
  } },
}
