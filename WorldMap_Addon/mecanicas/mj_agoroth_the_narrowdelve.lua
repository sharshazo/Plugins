-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["agoroth_the_narrowdelve"] = {
  { "Rúcrog Hoarpelt", {
    { "Frontal AoE", "CZ", 0, 0, nil, { "die by the claws of the gauredain", "muere por las garras de los gauredain", "show me the strength of your pack", "muéstrame la fuerza de tu manada" }, nil, true, nil, "Área frontal", nil },
    { "Javelin-Puddle", "Z", 0, 0, nil, { "my spear flies", "mi lanza vuela", "feel the sting of my spear", "siente el aguijón de mi lanza" }, nil, true, nil, "Jabalina con charco", nil },
    { "Totem Spawn!", "Q", 0, 0, nil, { "ancestors i call upon you", "ancestros os invoco", "our ancestors fight with me", "nuestros antepasados luchan conmigo" }, nil, true, nil, "¡Aparece un tótem!", nil },
    { "CC Adds!", "I", 0, 0, nil, { "fight as one", "luchad como uno solo" }, nil, true, nil, "¡Controla a los esbirros!", nil },
  } },
  { "Storm of the Witch-king", {
    { "Avoid Wave!", "Z", 0, 0, nil, { "you will not escape", "no escaparás", "your end draws near mortal", "tu fin se acerca mortal" }, nil, true, nil, "¡Esquiva la ola!", nil },
  } },
  { "Aigrith the Ashen", {
    { "Remove Corruption!", "ZYX", 0, 0, nil, { "burn to cinders", "arde hasta las cenizas", "burn to ash" }, nil, true, nil, "¡Quita la corrupción!", nil },
    { "Cleanse in Water!", "Y", 0, 0, nil, { "the flames will burn you", "las llamas te quemarán", "i call to the flames", "llamo a las llamas" }, nil, true, nil, "¡Límpiate en el agua!", nil },
    { "Avoid Frontal", "CZ", 0, 0, nil, { "by the will of angmar", "por la voluntad de angmar", "by the power of the witch king", "por el poder del rey brujo" }, nil, true, nil, "Evita el frontal", nil },
    { "Add", "Q", 0, 0, nil, { "you will observe our pact spirit", "observarás nuestro pacto espíritu", "i bind you to my will spirit", "te ato a mi voluntad espíritu" }, nil, true, nil, "Esbirro", nil },
  } },
}
