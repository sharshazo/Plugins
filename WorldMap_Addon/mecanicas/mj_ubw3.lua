-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["ubw3"] = {
  { "Gârash, the Emptiness", {
    { "Purge Hope", "LF", 30, 28, { 1090532791, 1091404640 }, nil, nil, nil, { "Purgar la esperanza" } },
    { "True Despair", "AF", 10, 5, { 1092995854, 1092995880, 1092995873, 1092995875, 1092995904, 1092995856 }, nil, nil, nil, { "Desesperación verdadera" } },
    { "Weaken Resolve", "A", 35, 27, nil, { "gârash weakens null s will to f" }, nil },
    { "Purge the Hopeless", "A", 45, 60, nil, { "gârash purges your hope", "gârash purga tu esperanza" }, nil, nil, { "Purga a los desesperanzados" } },
    { "Disease the World", "A", 25, 27, nil, { "gârash unleashes disease upon n" }, nil, nil, { "Enfermar al mundo" } },
    { "Cleave (Distributed)", "CG", 2, 25, nil, nil, nil },
  } },
  { "Sorcerer of Sagush", {
    { "Fashion the Shadow", "I", 25, 2, nil, nil, nil },
    { "Shadow Consumes You", "F", 6, 5, { 1091570816, 1091609147 }, nil, nil, nil, { "La Sombra te consume" } },
    { "Ancient Fury", "I", 15, 5, nil, nil, nil },
    { "Corrupted Earth", "I", 25, 10, { 1091611526 }, nil, nil, nil, { "Tierra corrupta" } },
  } },
  { "Warden of Thahar", {
    { "Cleaving Shadows", "C", 15, 0, nil, nil, nil },
    { "Shadow's Grasp", "W", 6, 6, { 1092402514 }, nil, nil, nil, { "Agarre de la Sombra" } },
    { "Cleave Foes", "C", 1, 0, nil, nil, nil, nil, { "Hender enemigos" } },
    { "Barbed Arrow", "SW", 10, 8, { 1090531521 }, nil, nil, nil, { "Flecha con púas" } },
    { "Brutal Arrow", "K", 12, 8, nil, nil, nil, nil, { "Flecha brutal" } },
    { "Shadow Burst", "A", 10, 5, nil, nil, nil },
  } },
  { "Azagath Sea-shadow", {
    { "Exploit Opportunity", "SWP", 5, 0, { 1091429145, 1090553915, 1091657099 }, nil, nil },
    { "The Subtle Death", "FPD", 25, 5, { 1092402633, 1091609004, 1091609074 }, nil, nil, nil, { "La muerte sutil" } },
    { "Frost Swipe (Distributed)", "CG", 2, 0, nil, nil, nil },
    { "Acid Swipe (Distributed)", "CG", 2, 0, nil, nil, nil },
    { "Shadow Swipe (Distributed)", "CG", 2, 0, nil, nil, nil, nil, { "Barrido de sombras (Distribuido)" } },
    { "Throat Cut", "SW", 34, 12, { 1091478600 }, nil, nil, nil, { "Corte de garganta" } },
    { "Assassin's Blade", "G", 20, 15, nil, nil, nil, nil, { "Hoja de asesino" } },
  } },
  { "Azagath's Malice", {
    { "Stinging Swipe", "C", 1, 0, nil, nil, nil },
    { "Bruise to the Bone", "W", 17, 17, { 1091425403 }, { "right to the bone", "hasta el hueso" }, nil, nil, { "Moretón hasta el hueso" } },
    { "Cold Heart", "F", 22, 4, { 1091609074 }, nil, nil, nil, { "Corazón frío" } },
  } },
  { "Thahar", {
    { "Plague Vortex", "L", 30, 12, nil, { "the plague spreads", "la plaga se extiende" }, nil, nil, { "Vórtice de plaga" } },
    { "Plague Sweep", "CG", 4, 0, nil, nil, nil, nil, { "Barrido de plaga" } },
    { "Plague Sweep (Back)", "CG", 6, 0, nil, nil, nil },
    { "Infectious Grip", "S", 30, 0, nil, { "disease consumes you", "la enfermedad te consume" }, nil, nil, { "Agarre infeccioso" } },
    { "Poison the Earth", "A", 25, 6, nil, { "the ground festers with disease", "el suelo se infecta de enfermeda" }, nil, nil, { "Envenenar la Tierra" } },
    { "Plague Breath", "P", 25, 0, { 1090555828 }, nil, nil, nil, { "Aliento de plaga" } },
  } },
  { "Sage of Sagush", {
    { "Renew Flesh", "I", 4, 0, { 1091570800 }, nil, nil, nil, { "Renovar carne" } },
    { "From Death, Life", "I", 15, 0, nil, nil, nil, nil, { "De la muerte, la vida" } },
    { "Sloughing Disease", "A", 18, 5, { 1090555828 }, nil, nil },
    { "Tangled Shadow", "S", 15, 10, { 1091429124 }, nil, nil, nil, { "Sombra enredada" } },
    { "Death Grip", "K", 20, 10, nil, nil, nil },
  } },
  { "Sagush", {
    { "Shadow Blades", "I", 2, 0, nil, nil, nil },
    { "Sweeping Umbra", "C", 2, 0, nil, nil, nil },
    { "Sweeping Umbra (Back)", "C", 2, 0, nil, nil, nil },
    { "Enveloping Shadow", "F", 25, 0, { 1091581393 }, { "be consumed by shadow", "sé consumido por la sombra" }, nil, nil, { "Sombra Envolvente" } },
  } },
  { "Azagath's Mettle", {
    { "Swipe", "C", 3, 0, nil, nil, nil, nil, { "Barrido", "Zarpazo" } },
    { "Shadow Strike", "SF", 16, 0, { 1090532173, 1092402986 }, { "fall to shadow", "cae a la sombra" }, nil, nil, { "Golpe de Sombra", "Golpe de sombra" } },
    { "Concuss", "IK", 18, 10, { 1091429153 }, { "your mind is broken", "tu mente está rota" }, nil, nil, { "Conmocionar" } },
  } },
  { "Azagath's Cunning", {
    { "Poison Dagger", "SP", 3, 0, { 1090555828 }, nil, nil },
    { "Poison Spike", "SP", 14, 0, { 1091657100, 1091657099, 1091657098, 1091659752 }, nil, nil, nil, { "Púa venenosa" } },
    { "Slicing Throw", "W", 8, 8, { 1091468392 }, { "taste my blade" }, nil, nil, { "Lanzamiento cortante" } },
    { "Impaling Throw", "I", 18, 0, nil, { "i will gut you", "te destriparé" }, nil, nil, { "Lanzamiento empalador" } },
    { "Slit Throat", "W", 20, 18, { 1090527705 }, { "i ll cut your necks", "les cortaré el cuello" }, nil },
  } },
  { "Bow-master of Thahar", {
    { "Poisoned Dagger", "I", 15, 2, nil, nil, nil, nil, { "Daga envenenada" } },
    { "Debilitating Wound", "I", 8, 4, nil, nil, nil, nil, { "Herida debilitante" } },
    { "Focused Shot", "I", 15, 8, nil, nil, nil, nil, { "Disparo concentrado" } },
    { "Enraged Shot", "E", 3, 5, nil, nil, nil, nil, { "Disparo enfurecido" } },
  } },
  { "Plague Vortex", {
    { "Explosive Plague (Distributed)", "AG", 2, 1, nil, nil, nil, nil, { "Plaga explosiva (distribuida)" } },
    { "Void Blast (Distributed)", "LGF", 15, 0, { 1090532791, 1091404640 }, nil, nil, nil, { "Explosión del Vacío (Distribuida)" } },
    { "Plague Eruption", "A", 10, 20, nil, nil, nil, nil, { "Erupción de plaga" } },
  } },
  { "Shadow Vortex", {
    { "Explosive Umbra (Distributed)", "AG", 2, 1, nil, nil, nil, nil, { "Umbra explosiva (distribuida)" } },
    { "Void Blast (Distributed)", "LGF", 15, 0, { 1090532791, 1091404640 }, nil, nil, nil, { "Explosión del Vacío (Distribuida)" } },
    { "Shadow Eruption", "A", 10, 20, nil, nil, nil, nil, { "Erupción de sombras" } },
  } },
  { "Azagath's Will", {
    { "Will of the Sea-shadow", "I", 1, 0, nil, { "by my will my body and mind shal", "por mi voluntad mi cuerpo y mi m" }, nil, nil, { "Voluntad de la Sombra del Mar" } },
  } },
  { "Plaguestorm", {
    { "Explosive Plague (Distributed)", "AG", 2, 1, nil, nil, nil, nil, { "Plaga explosiva (distribuida)" } },
    { "Void Blast (Distributed)", "LGF", 15, 0, { 1090532791, 1091404640 }, nil, nil, nil, { "Explosión del Vacío (Distribuida)" } },
    { "Plague Eruption", "A", 10, 20, nil, nil, nil, nil, { "Erupción de plaga" } },
  } },
  { "Umbrastorm", {
    { "Explosive Umbra (Distributed)", "AG", 2, 1, nil, nil, nil, nil, { "Umbra explosiva (distribuida)" } },
    { "Void Blast (Distributed)", "LGF", 15, 0, { 1090532791, 1091404640 }, nil, nil, nil, { "Explosión del Vacío (Distribuida)" } },
    { "Shadow Eruption", "A", 10, 20, nil, nil, nil, nil, { "Erupción de sombras" } },
  } },
}
