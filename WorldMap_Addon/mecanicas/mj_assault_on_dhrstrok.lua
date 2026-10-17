-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["assault_on_dhrstrok"] = {
  { "Gâdh-and-Shum", {
    { "Tornado", "Q", 0, 0, nil, { "make books fly", "hacer volar los libros" }, nil, true, nil, "Tornado", nil },
    { "AoE", "Z", 0, 0, nil, { "you shall not have them", "no los tendrás" }, nil, true, nil, "Área", nil },
    { "All abilities active", "Q", 0, 0, nil, { "fine fine together now we talk later", "bien bien juntos ahora hablamos después" }, nil, true, nil, "Todas las habilidades activas", nil },
    { "Goblin spawn", "Q", 0, 0, nil, { "goblin friends", "amigos trasgos" }, nil, true, nil, "Aparecen trasgos", nil },
    { "Throw & AoE Phase", "Z", 0, 0, nil, { "my books", "mis libros" }, nil, true, nil, "Fase de lanzamiento y área", nil },
    { "Shadow throw", "Q", 0, 0, nil, { "shadows take you", "las sombras te lleven" }, nil, true, nil, "Lanzamiento de sombra", nil },
    { "Tornado & Goblin Phase", "Q", 0, 0, nil, { "my turn", "mi turno" }, nil, true, nil, "Fase de tornado y trasgos", nil },
    { "Interrupt", "I", 0, 0, nil, { "let shadows pool", "que las sombras se acumulen" }, nil, true, nil, "Interrumpe", nil },
  } },
  { "Mozrúk", {
    { "Fire Bomb", "Z", 0, 0, nil, { "fry to a crisp" }, "Fire", true, nil, "Bomba de fuego", "Fuego" },
    { "Sticky", "Q", 0, 0, nil, { "stick around won t you", "quédate por aquí quieres" }, nil, true, nil, "Pegajoso", nil },
    { "Airstrike!", "Q", 0, 0, nil, { "death from above", "muerte desde arriba" }, nil, true, nil, "¡Ataque aéreo!", nil },
  } },
}
