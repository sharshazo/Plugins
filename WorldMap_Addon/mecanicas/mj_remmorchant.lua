-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["remmorchant"] = {
  { "Captain Zabothak", {
    { "Reflect!", "B", 0, 0, nil, { "show me your strength haha", "muéstrame tu fuerza jaja", "you weaklings cannot defeat me", "vosotros debiluchos no podéis derrotarm" }, nil, true, nil, "¡Reflejo!", nil },
    { "Adds", "Q", 0, 0, nil, { "slaves make yourselves useful", "esclavos haceos útiles", "get out here you worthless goblins" }, nil, true, nil, "Esbirros", nil },
  } },
  { "Bratha Tasakh, Lady of Many Venoms", {
    { "Spider spawn", "Q", 0, 0, nil, { "my chosen embrace them" }, nil, true, nil, "Aparecen arañas", nil },
  } },
  { "Rûkhor the Pale Herald", {
    { "Interrupt Rúkhor!", "I", 0, 0, nil, { "how long can you last without your power", "cuánto tiempo puedes aguantar sin tu po", "your power becomes mine", "tu poder se convierte en el mío", "what are you without your power", "qué eres sin tu poder" }, nil, true, nil, "¡Interrumpe a Rúkhor!", nil },
    { "Blood Surge", "Q", 0, 0, nil, { "your strength shall be your undoing", "tu fuerza será tu perdición", "i will turn your strength against you", "volveré tu fuerza en tu contra" }, nil, true, nil, "Oleada de sangre", nil },
    { "Life drain", "Q", 0, 0, nil, { "your life force sustains me", "tu fuerza vital me sostiene" }, nil, true, nil, "Drenaje de vida", nil },
  } },
}
