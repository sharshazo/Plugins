-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["adkht_zahhar_the_houses_of_rest"] = {
  { "Loknashra", {
    { "DoT", "Q", 0, 0, nil, { "a slight chill", "un ligero escalofrío", "just a taste of the cold", "solo una probada del frío" }, "Chilling DoT", true, nil, "Daño continuo", "Escalofrío continuo" },
    { "AoE", "Z", 0, 0, nil, { "a cold wind blows", "sopla un viento frío", "i will chill you to the bone", "te helaré hasta los huesos" }, nil, true, nil, "Área", nil },
    { "Tank frontal", "CT", 0, 0, nil, { "ice and shadow answer my call", "el hielo y la sombra responden a mi llam", "a frozen whisper", "un susurro helado" }, nil, true, nil, "Frontal al tanque", nil },
    { "Add spawn!", "Q", 0, 0, nil, { "the dead are a useful tool", "los muertos son una herramienta útil", "rise forth and defend me" }, "Add spawn", true, nil, "¡Aparecen esbirros!", "Aparecen esbirros" },
  } },
  { "Andvár Crow-feeder", {
    { "Interrupt Andvár", "IR", 0, 0, nil, { "know pain", "conoce el dolor" }, "Andvár Threat Wipe", true, nil, "Interrumpe a Andvár", "Andvár borra la amenaza" },
  } },
  { "Náli the Thumb-taker", {
    { "Bleed", "Q", 0, 0, nil, { "strike deep", "golpea profundo", "the blade cuts deep", "la hoja corta profundo" }, "Náli Bleed", true, nil, "Sangrado", "Sangrado de Náli" },
  } },
}
