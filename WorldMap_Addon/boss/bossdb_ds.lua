-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["ds"] = {
  { "Zidunâm, the Spirit-caller", {
    { "Smack", "TR", 4, 4, nil, nil, nil, "Single Target" },
  } },
  { "Ushdâla, Lady of the Pride", {
    { "Snaring Shot", "SW", 45, 5, 3, { 1092995724, 1091476353 }, { "slower prey is easier to cat" }, "Single Target" },
    { "Focused Shot (Distributed)", "S", 60, 30, 8, nil, { "this shot will end you" }, "2.0m by 60.0m rectangle from Self | distributed damage | 6 max targets" },
    { "Sleep Shot", "SP", 45, 60, 5, { 1090523646 }, { "you can t run and you can t " }, "Single Target" },
    { "Smack", "TR", 4, 4, nil, nil, nil, "Single Target" },
  } },
  { "Weaponmaster Mâkhragab", {
    { "Smack", "R", 4, 4, nil, nil, nil, "Single Target" },
    { "Cruel Dagger", "SW", 45, 3, 2, { 1090541258 }, { "cruel dagger find your mark" }, "Single Target" },
    { "Command: Loose", "A", 45, 15, 2, { 1090553936 }, { "archers loose" }, "100.0m around Self | 3 max targets" },
    { "Whirling Death", "K", 120, 60, 5, { 1092806781, 1090553902 }, { "whirling blades will cut you" }, "Single Target" },
    { "Cleaving Strike", "CS", 30, 30, 4, { 1090522394 }, { "my blades will cleave you in" }, "60° by 5.0m arc from Self" },
    { "Dual Strike", "CSK", 45, 10, 3, nil, { "two blades two strikes" }, "30° by 7.0m arc from Self" },
    { "Throw Spear", "S", 30, 10, 5, nil, { "a sharp spear to skewer my e" }, "1.0m by 30.0m rectangle from Self" },
    { "Command: Skewer", "S", 20, 10, 5, nil, { "a sharp spear to skewer my e" }, "1.0m by 30.0m rectangle from Self" },
    { "Reflect Shield", "K", 10, 0, 7, { 1091510186, 1090553915, 1090523247 }, nil, "Single Target" },
  } },
  { "Methân Sai", {
    { "Poison Arrow", "ISP", 30, 10, 3, { 1090520845 }, { "poisoned arrow strike true" }, "Single Target" },
    { "Pinning Shot", "SKW", 59, 0, nil, { 1091459008, 1091476353 }, { "they are pinned strike them " }, "Single Target" },
  } },
  { "Ordâkhai Archer", {
    { "Poison Shot", "ISP", 30, 5, 3, { 1090520845 }, nil, "Single Target" },
    { "Multi-shot", "CS", 20, 10, nil, nil, nil, "90° by 20.0m arc from Self | 3 max targets" },
  } },
  { "Kâlach Hûl", {
    { "Serpent's Bite", "CSP", 30, 5, 3, { 1090522396 }, { "black serpent s bite" }, "90° by 5.0m arc from Self" },
    { "Lashing Strike (Distributed)", "ASK", 45, 10, nil, { 1091401111 }, { "the lash of the tail" }, "5.0m around Self | distributed damage" },
  } },
  { "Ordâkhai War-lion", {
    { "Dire Roar", "IASF", 30, 10, 5, { 1090528810 }, nil, "10.0m around Self" },
    { "Clawed Swipe", "C", 10, 5, nil, { 1091479304 }, nil, "90° by 5.0m arc from Self" },
  } },
  { "Ordâkhai Cat-master", {
    { "Pinning Shot", "SW", 10, 10, 3, { 1091476353 }, nil, "Single Target" },
  } },
  { "Ordâkhai Dôlo", {
    { "Rallying Cry", "AS", 30, 5, nil, { 1090541065 }, nil, "7.0m around Self" },
  } },
  { "Ordâkhai Spearman", {
    { "Throw Spear", "S", 50, 0, 5, nil, nil, "1.0m by 30.0m rectangle from Self" },
    { "Skewer", "W", 30, 5, nil, { 1090522394 }, nil, "Single Target" },
    { "Spear Throw", "S", 20, 10, 5, nil, nil, "1.0m by 30.0m rectangle from Self" },
  } },
  { "Ordâkhai Warrior", {
    { "Armour Smash", "W", 30, 5, nil, { 1091570816 }, nil, "Single Target" },
    { "Cleaving Strike", "CS", 15, 10, nil, nil, nil, "90° by 5.0m arc from Self" },
  } },
  { "Ordâkhai Sorcerer", {
    { "Terrible Presence", "SF", 15, 5, nil, { 1090528810 }, nil, "Single Target" },
    { "Gale of Spirits", "ISF", 30, 10, 5, { 1090532173 }, nil, "5.0m around Selection" },
  } },
  { "Serpent Spawn", {
    { "Snake Bite", "P", 20, 5, nil, { 1090522396 }, nil, "Single Target" },
  } },
  { "Ordâkhai Battle-cat", {
    { "Pounce", "K", 30, 0, nil, nil, nil, "Single Target" },
  } },
  { "Raghtâ Sai", {
    { "Poison Strike", "SP", 30, 5, nil, { 1090522396 }, { "feel the poison of the serpe" }, "Single Target" },
    { "Serpent Strike", "CS", 59, 0, 3, { 1090522394 }, { "strike of the serpent" }, "90° by 5.0m arc from Self" },
  } },
  { "Zidunâm, the Serpent Reborn", {
    { "Coiled Strike", "K", 65, 45, 15, { 1091668185, 1090523247, 1090553915 }, { "my coils cannot be penetrate" }, "Single Target" },
    { "Serpent's Venom", "A", 45, 20, nil, { 1091608997 }, { "venom of the black serpent" }, "100.0m around Self" },
    { "Serpent's Cry", "A", 70, 30, nil, { 1091829819 }, { "serpents come to me" }, "100.0m around Self" },
    { "Jagged Scales", "A", 30, 5, nil, { 1091401111 }, { "my scales will rip you apart" }, "100.0m around Self" },
    { "Smack", "TR", 4, 4, nil, nil, nil, "Single Target" },
  } },
  { "Cobra Spirit", {
    { "Snake Bite", "P", 10, 5, nil, { 1090522396 }, nil, "Single Target" },
  } },
  { "Iti-mêlim", {
    { "Lacerate", "CW", 15, 5, nil, { 1091479304 }, nil, "25° by 3.0m arc from Self" },
    { "Terrifying Roar", "IASF", 30, 30, 5, { 1090528810 }, nil, "60.0m around Self" },
    { "Ambush", "K", 50, 50, nil, nil, nil, "Single Target" },
    { "Ravage", "X", 1, 0, nil, { 1092406968 }, nil, "Single Target" },
  } },
  { "Archer Spirit", {
    { "Blade of the Haradrim", "W", 15, 5, nil, { 1090522394 }, nil, "Single Target" },
  } },
  { "Mizâdi", {
    { "a moderate swipe attack", "C", 15, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "Melee Stun", "K", 30, 0, nil, nil, nil, "Single Target" },
    { "Whirl of Fury", "CR", 15, 0, nil, nil, nil, "160° by 5.0m arc from Self | 3 max targets" },
    { "Blood-seeker", "C", 15, 0, nil, { 1091551730 }, nil, "160° by 5.0m arc from Self | 5 max targets" },
  } },
  { "Théoden King", {
    { "a mighty swipe attack", "CS", 3, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
  } },
  { "Explosive Fire Pot", {
    { "Explode", "AS", 50, 0, 10, { 1092812643 }, nil, "7.0m around Self" },
  } },
}
