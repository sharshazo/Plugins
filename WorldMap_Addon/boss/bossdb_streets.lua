-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["streets"] = {
  { "Utho, the Grasper", {
    { "Cleave", "C", 8, 5, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Stagger", "SW", 12, 12, nil, { 1091415788 }, nil, "Single Target" },
    { "Frenzy", "X", 20, 10, nil, { 1090528807 }, nil, "Single Target" },
  } },
  { "Jephai Trapper", {
    { "Haymaker Uppercut", "K", 45, 0, nil, nil, nil, "Single Target" },
    { "Net I", "K", 30, 15, nil, nil, nil, "Single Target" },
    { "Net II", "K", 20, 0, nil, nil, nil, "Single Target" },
    { "Ichor I", "D", 60, 8, 1, { 1090535377 }, nil, "1.5m around Selection" },
    { "Ichor II", "D", 45, 4, 1, { 1090535377 }, nil, "1.5m around Selection" },
  } },
  { "Jephai Sniper", {
    { "Sniper Arrow", "IW", 15, 0, 3, { 1090531521 }, nil, "Single Target" },
    { "Volley I", "I", 30, 15, 3, { 1090553936 }, nil, "Single Target" },
    { "Volley II", "I", 25, 10, 3, { 1090553936 }, nil, "Single Target" },
    { "Volley III", "I", 20, 5, 3, { 1090553936 }, nil, "Single Target" },
  } },
  { "Khâshap, Ifrinn's Abomination", {
    { "Bone-crusher", "A", 18, 30, nil, { 1091459632 }, nil, "10.0m around Self" },
    { "Pound", "A", 12, 5, nil, nil, nil, "5.5m around Self" },
    { "Unstable Flame I", "X", 15, 10, nil, { 1091609049 }, nil, "Single Target" },
    { "Unstable Flame II", "X", 15, 10, nil, { 1091609051, 1091609050, 1091609049 }, nil, "Single Target" },
    { "Unstable Flame III", "X", 15, 10, nil, { 1091609053, 1091609052, 1091609051, 1091609050, 1091609049 }, nil, "Single Target" },
    { "Demand", "A", 45, 10, nil, nil, nil, "20.0m around Self" },
    { "Ichor I", "AD", 45, 10, nil, { 1090535377 }, nil, "5.5m around Self" },
    { "Ichor II", "AD", 25, 10, nil, { 1090535377 }, nil, "5.5m around Self" },
  } },
  { "Khâshap", {
    { "Bone-crusher", "A", 18, 30, nil, { 1091459632 }, nil, "10.0m around Self" },
    { "Pound", "A", 12, 5, nil, nil, nil, "5.5m around Self" },
    { "Unstable Flame I", "X", 15, 10, nil, { 1091609049 }, nil, "Single Target" },
    { "Unstable Flame II", "X", 15, 10, nil, { 1091609051, 1091609050, 1091609049 }, nil, "Single Target" },
    { "Unstable Flame III", "X", 15, 10, nil, { 1091609053, 1091609052, 1091609051, 1091609050, 1091609049 }, nil, "Single Target" },
    { "Demand", "A", 45, 10, nil, nil, nil, "20.0m around Self" },
    { "Ichor I", "AD", 45, 10, nil, { 1090535377 }, nil, "5.5m around Self" },
    { "Ichor II", "AD", 25, 10, nil, { 1090535377 }, nil, "5.5m around Self" },
  } },
  { "Jephai Bruiser", {
    { "Wild Slash", "K", 0, 0, nil, nil, nil, "Single Target" },
    { "a sweeping melee attack", "C", 15, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Frenzied Strike I", "X", 15, 5, nil, { 1090528807 }, nil, "Single Target" },
    { "Frenzied Strike II", "X", 15, 0, nil, { 1090528807 }, nil, "Single Target" },
  } },
  { "Jephai Look-out", {
    { "Haymaker Uppercut", "K", 45, 0, nil, nil, nil, "Single Target" },
    { "Call For Reinforcements I", "I", 6000, 20, 3, nil, nil, "Single Target" },
    { "Call For Reinforcements II", "I", 6000, 15, 3, nil, nil, "Single Target" },
  } },
  { "Jephai Mender", {
    { "Sniper Arrow", "IW", 15, 0, 3, { 1090531521 }, nil, "Single Target" },
    { "Mass Heal I", "I", 60, 5, 4, nil, nil, "Single Target" },
    { "Mass Heal II", "I", 30, 10, 3, nil, nil, "Single Target" },
  } },
}
