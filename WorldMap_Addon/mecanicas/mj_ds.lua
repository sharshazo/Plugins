-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["ds"] = {
  { "Ushdâla, Lady of the Pride", {
    { "Snaring Shot", "SW", 45, 5, { 1092995724, 1091476353 }, { "slower prey is easier to catch" }, nil },
    { "Focused Shot (Distributed)", "LG", 60, 30, nil, { "this shot will end you", "este disparo acabará contigo" }, nil, nil, { "Disparo enfocado (distribuido)" } },
    { "Sleep Shot", "SP", 45, 60, { 1090523646 }, { "you can t run and you can t hide", "no puedes correr y no puedes esc" }, nil, nil, { "Disparo de sueño" } },
  } },
  { "Weaponmaster Mâkhragab", {
    { "Cruel Dagger", "SW", 45, 3, { 1090541258 }, { "cruel dagger find your mark", "daga cruel encuentra tu marca" }, nil, nil, { "Daga cruel" } },
    { "Command: Loose", "A", 45, 15, { 1090553936 }, { "archers loose" }, nil },
    { "Cleaving Strike", "CS", 30, 30, nil, { "my blades will cleave you in twa", "mis espadas te partirán en dos" }, nil, nil, { "Golpe de hendidura" } },
    { "Dual Strike", "CSK", 45, 10, nil, { "two blades two strikes", "dos espadas dos golpes" }, nil, nil, { "Golpe doble" } },
    { "Throw Spear", "LS", 30, 10, nil, { "a sharp spear to skewer my enemi", "una lanza afilada para ensartar " }, nil, nil, { "Lanzar lanza" } },
    { "Command: Skewer", "LS", 20, 10, nil, { "a sharp spear to skewer my enemi", "una lanza afilada para ensartar " }, nil },
  } },
  { "Methân Sai", {
    { "Poison Arrow", "ISP", 30, 10, { 1090520845 }, { "poisoned arrow strike true", "flecha envenenada da en el blanc" }, nil, nil, { "Flecha venenosa" } },
    { "Pinning Shot", "SKW", 59, 0, { 1091459008, 1091476353 }, { "they are pinned strike them down", "están inmovilizados derríbalos" }, nil, nil, { "Disparo inmovilizador" } },
  } },
  { "Ordâkhai Archer", {
    { "Poison Shot", "ISP", 30, 5, { 1090520845 }, nil, nil, nil, { "Disparo venenoso" } },
    { "Multi-shot", "CS", 20, 10, nil, nil, nil, nil, { "Disparo múltiple" } },
  } },
  { "Kâlach Hûl", {
    { "Serpent's Bite", "CSP", 30, 5, { 1090522396 }, { "black serpent s bite", "mordedura de la serpiente negra" }, nil, nil, { "Mordedura de serpiente" } },
    { "Lashing Strike (Distributed)", "AGK", 45, 10, nil, { "the lash of the tail", "el latigazo de la cola" }, nil },
  } },
  { "Ordâkhai War-lion", {
    { "Dire Roar", "IASF", 30, 10, { 1090528810 }, nil, nil, nil, { "Rugido funesto" } },
    { "Clawed Swipe", "C", 10, 5, { 1091479304 }, nil, nil },
  } },
  { "Ordâkhai Cat-master", {
    { "Pinning Shot", "SW", 10, 10, { 1091476353 }, nil, nil, nil, { "Disparo inmovilizador" } },
  } },
  { "Ordâkhai Spearman", {
    { "Throw Spear", "LS", 50, 0, nil, nil, nil, nil, { "Lanzar lanza" } },
    { "Skewer", "W", 30, 5, { 1090522394 }, nil, nil, nil, { "Empalar", "Ensartar" } },
    { "Spear Throw", "LS", 20, 10, nil, nil, nil, nil, { "Lanzamiento de lanza" } },
  } },
  { "Ordâkhai Warrior", {
    { "Armour Smash", "W", 30, 5, { 1091570816 }, nil, nil },
    { "Cleaving Strike", "CS", 15, 10, nil, nil, nil, nil, { "Golpe de hendidura" } },
  } },
  { "Ordâkhai Sorcerer", {
    { "Terrible Presence", "SF", 15, 5, { 1090528810 }, nil, nil, nil, { "Presencia terrible" } },
    { "Gale of Spirits", "ISF", 30, 10, { 1090532173 }, nil, nil, nil, { "Vendaval de espíritus" } },
  } },
  { "Serpent Spawn", {
    { "Snake Bite", "P", 20, 5, { 1090522396 }, nil, nil, nil, { "Mordedura de serpiente" } },
  } },
  { "Ordâkhai Battle-cat", {
    { "Pounce", "K", 30, 0, nil, nil, nil },
  } },
  { "Raghtâ Sai", {
    { "Poison Strike", "SP", 30, 5, { 1090522396 }, { "feel the poison of the serpent", "siente el veneno de la serpiente" }, nil, nil, { "Golpe venenoso" } },
    { "Serpent Strike", "CS", 59, 0, nil, { "strike of the serpent", "golpe de la serpiente" }, nil, nil, { "Golpe de serpiente" } },
  } },
  { "Zidunâm, the Serpent Reborn", {
    { "Coiled Strike", "K", 65, 45, { 1090523247, 1090553915 }, { "my coils cannot be penetrated", "mis anillos no pueden ser penetr" }, nil },
    { "Serpent's Venom", "A", 45, 20, { 1091608997 }, { "venom of the black serpent", "veneno de la serpiente negra" }, nil, nil, { "Veneno de serpiente" } },
    { "Jagged Scales", "A", 30, 5, nil, { "my scales will rip you apart", "mis escamas te destrozarán" }, nil, nil, { "Escamas dentadas" } },
  } },
  { "Cobra Spirit", {
    { "Snake Bite", "P", 10, 5, { 1090522396 }, nil, nil, nil, { "Mordedura de serpiente" } },
  } },
  { "Iti-mêlim", {
    { "Lacerate", "CW", 15, 5, { 1091479304 }, nil, nil },
    { "Terrifying Roar", "IASF", 30, 30, { 1090528810 }, nil, nil, nil, { "Rugido aterrador" } },
    { "Ambush", "K", 50, 50, nil, nil, nil, nil, { "Emboscada" } },
    { "Ravage", "X", 1, 0, { 1092406968 }, nil, nil, nil, { "Devastación" } },
  } },
  { "Archer Spirit", {
    { "Blade of the Haradrim", "W", 15, 5, { 1090522394 }, nil, nil, nil, { "Hoja de los Haradrim" } },
  } },
  { "Mizâdi", {
    { "Melee Stun", "K", 30, 0, nil, nil, nil },
    { "Whirl of Fury", "CR", 15, 0, nil, nil, nil, nil, { "Torbellino de furia" } },
    { "Blood-seeker", "C", 15, 0, { 1091551730 }, nil, nil, nil, { "Buscador de sangre" } },
  } },
  { "Explosive Fire Pot", {
    { "Explode", "AS", 50, 0, { 1092812643 }, nil, nil, nil, { "Explotar" } },
  } },
}
