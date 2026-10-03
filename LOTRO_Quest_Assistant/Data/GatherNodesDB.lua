-- QuestSync Data/GatherNodesDB.lua
-- Generado a partir de LOTRO_recoleccion_tiers.md (ver ese archivo para fuentes y metodologia).
-- Todos los nombres en espanol vienen confirmados por ID compartido con el diccionario maestro
-- (LotRO Companion/app/data/lore/labels/{en,es}/items.xml y crafting.xml) -- ninguno fue
-- traducido a mano. Entradas donde el nombre en espanol no estaba confirmado en el diccionario
-- se dejaron afuera a proposito (mejor no reconocer un nodo/item que reconocerlo mal).
--
-- Estructura: _G.GatherNodesDB.byNode[nombreDelNodoEnChat] y .byItem[nombreDelItemEnChat]
-- apuntan al MISMO objeto "entry" para un nodo dado -- asi el detector puede confirmar el
-- evento por la linea "Tomando los contenidos de X..." (la mas confiable, ver
-- Arquitectura_GatherSync.md #3.2) o por la linea "Has adquirido: [item]" si hace falta.
--
-- confidence: "alta" | "media" | "baja" -- copiado directo de LOTRO_recoleccion_tiers.md,
-- para que la UI pueda mostrar "Tier ~11 (sin confirmar del todo)" en vez de afirmarlo como
-- un hecho cuando la fuente original no estaba segura.

_G.GatherNodesDB = {
    byNode = {},
    byItem = {},
}

local function register(entry, nodeNames, itemNames)
    -- BUG (encontrado en vivo 2026-08-23): ninguna entrada traia el campo
    -- "node" -- GatherPointsStore/GatherEventParser lo leen para mostrar el
    -- nombre (confirmado en el chat real: "punto nuevo guardado -> nil").
    -- Se deriva del primer nombre de nodeNames (el nombre "principal", ej.
    -- "Veta de cobre" antes que su variante "Depósito abundante de cobre").
    --
    -- BUG REAL #2 (encontrado en auditoria 2026-09-07): las entradas SIN
    -- nombre de nodo (nodeNames={}, solo itemNames -- ej. Colmena/miel,
    -- Tallo de ruibarbo, Cofre de artefactos de Ithil sin nodo local
    -- conocido) se quedaban con entry.node=nil, porque el fallback de
    -- arriba solo miraba nodeNames. Con el fix de GatherEventParser.lua que
    -- ahora dispara la captura directo desde el ITEM (mismo dia), estas
    -- entradas SI llegan a mostrarse en el boton/guardarse como punto -- y
    -- con node=nil: (a) el boton flotante mostraba literalmente "nil", y
    -- (b) GatherPointsStore.AddPoint dedupea por "existing.node==entry.node"
    -- -- con nil==nil TRUE, dos entradas sin nombre de nodo distintas (ej.
    -- miel y ruibarbo) se confundian entre si si caian cerca en el mapa.
    -- Fallback en cascada: nodeNames[1] primero, itemNames[1] si no hay.
    if entry.node == nil and nodeNames ~= nil and nodeNames[1] ~= nil then
        entry.node = nodeNames[1]
    end
    if entry.node == nil and itemNames ~= nil and itemNames[1] ~= nil then
        entry.node = itemNames[1]
    end
    for _, n in ipairs(nodeNames or {}) do
        _G.GatherNodesDB.byNode[n] = entry
    end
    for _, i in ipairs(itemNames or {}) do
        _G.GatherNodesDB.byItem[i] = entry
    end
end

---------------------------------------------------------------------
-- MINERO (Prospector)
---------------------------------------------------------------------

register({ profession = "MINERO", tier = 1, zone = "Apprentice", confidence = "alta" },
    { "Veta de cobre", "Depósito abundante de cobre" },
    { "Bloque de mineral de cobre" })

register({ profession = "MINERO", tier = 1, zone = "Apprentice", confidence = "alta" },
    { "Veta de estaño" },
    {}) -- item "Chunk of Tin Ore" sin confirmar en diccionario

register({ profession = "MINERO", tier = 2, zone = "Journeyman", confidence = "alta" },
    { "Veta de hierro tumulario", "Depósito abundante de hierro de los túmulos" },
    { "Trozo de mineral de hierro de los túmulos" })

register({ profession = "MINERO", tier = 2, zone = "Journeyman", confidence = "alta" },
    { "Veta de plata", "Depósito abundante de plata" },
    { "Trozo de mineral de plata" })

register({ profession = "MINERO", tier = 3, zone = "Expert", confidence = "alta" },
    { "Veta de hierro enriquecido", "Depósito abundante de hierro enriquecido" },
    { "Trozo de mineral de hierro enriquecido" })

register({ profession = "MINERO", tier = 3, zone = "Expert", confidence = "alta" },
    { "Veta de oro", "Depósito abundante de oro" },
    { "Trozo de mineral de oro" })

register({ profession = "MINERO", tier = 4, zone = "Artisan", confidence = "alta" },
    { "Veta de hierro enano", "Depósito abundante de hierro enano" },
    { "Trozo de mineral de hierro enano" })

register({ profession = "MINERO", tier = 4, zone = "Artisan", confidence = "alta" },
    { "Veta de platino", "Depósito abundante de platino" },
    { "Trozo de mineral de platino" })

register({ profession = "MINERO", tier = 5, zone = "Master", confidence = "alta" },
    { "Veta de hierro antiguo", "Depósito abundante de hierro antiguo" },
    { "Trozo de mineral de hierro antiguo" })

register({ profession = "MINERO", tier = 5, zone = "Master", confidence = "alta" },
    { "Veta de plata antigua", "Depósito abundante de plata antigua" },
    { "Trozo de mineral de plata antigua" })

register({ profession = "MINERO", tier = 6, zone = "Khazâd-dûm (Moria)", confidence = "alta" },
    { "Veta de skarn de Khazâd", "Depósito rico de skarn de Khazâd" },
    { "Trozo de skarn khazâd" })

register({ profession = "MINERO", tier = 7, zone = "Calenard", confidence = "alta" },
    { "Veta de skarn de Calenard", "Depósito rico de skarn de Calenard" },
    { "Trozo de skarn de Calenard", "Trozo de skarn de alta calidad de Calenard" })

register({ profession = "MINERO", tier = 8, zone = "Eastemnet", confidence = "alta" },
    { "Veta de skarn de la Marca de los Jinetes", "Depósito rico de skarn de la Marca de los Jinetes" },
    { "Trozo de skarn de la Marca de los Jinetes", "Trozo de skarn de alta calidad de la Marca de los Jinetes" })

register({ profession = "MINERO", tier = 9, zone = "Westemnet", confidence = "alta" },
    { "Veta de skarn de los Eorlingas", "Depósito rico de skarn de los Eorlingas" },
    { "Trozo de skarn de los Eorlingas", "Trozo de skarn de alta calidad de los Eorlingas" })

register({ profession = "MINERO", tier = 10, zone = "Anórien", confidence = "alta" },
    { "Veta de skarn de Anórien", "Depósito rico de skarn de Anórien" },
    { "Trozo de skarn de Anórien", "Trozo de skarn de Anórien de alta calidad" })

register({ profession = "MINERO", tier = 11, zone = "Dagorlad", confidence = "media" },
    { "Veta de chatarra de Dagorlad", "Depósito rico de chatarra de Dagorlad" },
    {})

register({ profession = "MINERO", tier = 11, zone = "Doomfold (Valle de la Perdición)", confidence = "baja" },
    {}, -- nombre del nodo no localizado
    { "Trozo de skarn del Valle de la Perdición", "Trozo de skarn de alta calidad del Valle de la Perdición" })

register({ profession = "MINERO", tier = 11, zone = "Gorgoroth", confidence = "media" },
    { "Veta de skarn de Gorgoroth", "Depósito rico de skarn de Gorgoroth" },
    {})

register({ profession = "MINERO", tier = 12, zone = "Erebor", confidence = "media" },
    { "Veta de skarn de Erebor", "Depósito rico de skarn de Erebor" },
    {})

register({ profession = "MINERO", tier = 12, zone = "Ironfold (Valle del Hierro)", confidence = "media" },
    { "Veta de skarn del Valle del Hierro", "Depósito rico de skarn del Valle del Hierro" },
    { "Trozo de skarn del Valle del Hierro", "Trozo de skarn de alta calidad del Valle del Hierro" })

register({ profession = "MINERO", tier = 13, zone = "Vales de Anduin", confidence = "media-alta" },
    { "Veta de skarn de los Valles", "Depósito rico de skarn de los Valles" },
    {})

register({ profession = "MINERO", tier = 13, zone = "Minas Ithil", confidence = "alta" },
    { "Veta de skarn de Ithil", "Depósito rico de skarn de Ithil" },
    { "Trozo de skarn de Minas Ithil", "Trozo de skarn de alta calidad de Minas Ithil" })

register({ profession = "MINERO", tier = 13, zone = "Langflood", confidence = "media" },
    { "Veta de skarn del Langflood", "Depósito rico de skarn del Langflood" },
    { "Trozo de skarn de Langflood", "Trozo de skarn de alta calidad de Langflood" })

register({ profession = "MINERO", tier = 13, zone = "Khazâd-plata (nodo bonus)", confidence = "baja" },
    { "Veta de plata khazâd", "Depósito rico de plata khazâd" },
    {})

register({ profession = "MINERO", tier = 14, zone = "Gundabad", confidence = "alta" },
    { "Veta de skarn brillante", "Depósito rico de skarn brillante" },
    { "Trozo de skarn de Gundabad", "Trozo de skarn de alta calidad de Gundabad" })

register({ profession = "MINERO", tier = 14, zone = "Khazâd (variante de nieve)", confidence = "baja" },
    { "Yacimiento de Skarn Khazâd Cubierto de Nieve", "Yacimiento Rico de Skarn Khazâd Cubierto de Nieve" },
    {})

register({ profession = "MINERO", tier = 15, zone = "Umbar", confidence = "alta" },
    { "Yacimiento de Mineral Iridiscente", "Yacimiento Rico de Mineral Iridiscente" },
    { "Trozo de hierro shagâni", "Trozo de hierro shagâni de alta calidad" })

register({ profession = "MINERO", tier = 16, zone = "Sul Madásh", confidence = "alta" },
    { "Veta de mena argentada", "Depósito rico de mena argentada" },
    {})

register({ profession = "MINERO", tier = 17, zone = "Mûrai", confidence = "media" },
    {}, -- nombre del nodo sin traduccion ES en el diccionario
    { "Trozo de mineral de hierro mûrai", "Trozo de mineral espejado mûrai" })

-- === EXPANSION 2026-09-07: vetas de Minero adicionales (todo tipo de nodo) ===
-- Mismo criterio que la expansion de Granjero de mas abajo, generalizado a
-- las 3 profesiones de recoleccion (pedido explicito del usuario: "que
-- abarque todo tipo de nodo y recoleccion de todo"). Nombres confirmados
-- por ID compartido con el diccionario oficial (LotRO Companion,
-- labels/es/items.xml) pero sin tier/zona confirmado todavia -- probable-
-- mente nodos de eventos/instancias/vivienda, no de zonas abiertas
-- estandar. tier="?" y confidence="sin catalogar" para que la ventana de
-- guardar SI aparezca; el tier real se corrige despues sin romper nada.
register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de arcilla fina" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de hierro rica" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de mineral" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de mineral gris" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de mineral negro" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de mineral rojizo" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de obsidiana" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de piedra de dragón" },
    {})

register({ profession = "MINERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Veta de ámbar" },
    {})

---------------------------------------------------------------------
-- LEÑADOR (Forester)
---------------------------------------------------------------------

register({ profession = "LEÑADOR", tier = 1, zone = "Apprentice", confidence = "alta" },
    { "Ramas de serbal", "Ramas pesadas de serbal" },
    { "Tronco de serbal" })

register({ profession = "LEÑADOR", tier = 2, zone = "Journeyman", confidence = "alta" },
    { "Ramas de fresno", "Ramas pesadas de fresno" },
    { "Tronco de fresno" })

register({ profession = "LEÑADOR", tier = 3, zone = "Expert", confidence = "alta" },
    { "Ramas de tejo", "Ramas pesadas de tejo" },
    { "Tronco de madera de tejo" })

register({ profession = "LEÑADOR", tier = 4, zone = "Artisan", confidence = "alta" },
    { "Ramas de lebethron", "Ramas pesadas de lebethron" },
    { "Tronco de madera de Lebethron" })

register({ profession = "LEÑADOR", tier = 5, zone = "Master", confidence = "alta" },
    { "Ramas de fresno negro", "Ramas pesadas de fresno negro", "Ramas de fresno negro cubiertas de escarcha" },
    { "Tronco de fresno negro" })

register({ profession = "LEÑADOR", tier = 6, zone = "Eregion", confidence = "alta" },
    { "Ramas de acebo", "Ramas pesadas de acebo",
      "Ramas de acebo nudosas", "Pila de madera de acebo", "Pila pesada de madera de acebo" },
    { "Tronco de madera de acebo" })

register({ profession = "LEÑADOR", tier = 7, zone = "Westfold", confidence = "alta" },
    { "Ramas de abedul", "Ramas gruesas de abedul", "Ramas de albura de abedul" },
    { "Tronco de madera de abedul" })

register({ profession = "LEÑADOR", tier = 8, zone = "Eastemnet", confidence = "alta" },
    { "Ramas de roble", "Ramas de albura de roble", "Ramas de roble pesadas" },
    { "Tronco de madera de roble" })

register({ profession = "LEÑADOR", tier = 9, zone = "Westemnet", confidence = "alta" },
    { "Ramas de nogal", "Ramas pesadas de nogal", "Ramas de albura de nogal" },
    { "Tronco de madera de nogal" })

register({ profession = "LEÑADOR", tier = 10, zone = "Anórien", confidence = "alta" },
    { "Ramas de álamo", "Ramas pesadas de álamo", "Ramas nudosas", "Ramas nudosas pesadas", "Ramas de albura de álamo" },
    {})

register({ profession = "LEÑADOR", tier = 11, zone = "Doomfold (Valle de la Perdición)", confidence = "media" },
    { "Ramas de Gorgoroth", "Ramas pesadas de Gorgoroth", "Madera de Gorgoroth", "Madera pesada de Gorgoroth",
      "Ramas de Lasgalen", "Ramas gruesas de Lasgalen" },
    {})

register({ profession = "LEÑADOR", tier = 12, zone = "Ironfold (Vales de Anduin)", confidence = "media" },
    { "Ramas de los Valles", "Ramas gruesas de los Valles", "Ramas de Thornholt", "Ramas gruesas de Thornholt" },
    {})

register({ profession = "LEÑADOR", tier = 13, zone = "Langflood", confidence = "alta" },
    -- tier confirmado por MoorMap NodeTier.lua (2026-09-07): "Frost-rimed
    -- Ilex Branches" esta agrupado junto a "Langflood Branches" en tier 13,
    -- NO en tier 6 (Eregion) como se habia registrado antes por error --
    -- corregido.
    { "Ramas de acebo escarchadas", "Ramas de acebo muy escarchadas" },
    {})

register({ profession = "LEÑADOR", tier = 13, zone = "Mordor", confidence = "alta" },
    -- confirmado por MoorMap NodeTier.lua: "Mordor Snag Branches" tier 13.
    { "Ramas retorcidas de Mordor", "Ramas retorcidas gruesas de Mordor" },
    {})

register({ profession = "LEÑADOR", tier = 14, zone = "Gundabad", confidence = "media" },
    { "Ramas de fresno negro barridas por el viento", "Ramas pesadas de fresno negro barridas por el viento",
      "Pila de madera de fresno negro", "Gran pila de madera de fresno negro" },
    {})

register({ profession = "LEÑADOR", tier = 15, zone = "Umbar", confidence = "media" },
    { "Ramas de Fresno Negro Costero", "Ramas Pesadas de Fresno Negro Costero" },
    {})

register({ profession = "LEÑADOR", tier = 15, zone = "Sul Madásh", confidence = "alta" },
    -- confirmado por MoorMap NodeTier.lua: "Abandoned Planks" tier 15.
    { "Tablones Abandonados", "Tablones Abandonados Pesados" },
    {})

register({ profession = "LEÑADOR", tier = 16, zone = "Sul Madásh", confidence = "alta" },
    -- confirmado por MoorMap NodeTier.lua: "Unblemished Log" tier 16.
    { "Tronco impecable", "Tronco impecable pesado" },
    {})

-- === EXPANSION 2026-09-07: ramas de Leñador adicionales (todo tipo de nodo) ===
-- Mismo criterio que MINERO y GRANJERO -- pedido explicito del usuario de
-- cubrir "todo tipo de nodo y recoleccion de todo". Nombres confirmados por
-- ID compartido con el diccionario oficial, sin tier/zona confirmado
-- todavia (probablemente nodos de instancias/eventos/vivienda o especies
-- de zonas aun no catalogadas en LOTRO_recoleccion_tiers.md). Se agrupan
-- bajo un mismo entry las variantes que claramente son el mismo arbol/
-- especie con distinto adjetivo de calidad (mismo patron que "Trozo de
-- skarn" / "Trozo de skarn de alta calidad" en MINERO).
register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de Palma", "Ramas de Palma Pesadas" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de Sarláshi" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de Ucorno", "Ramas de Ucorno de savia blanca", "Ramas de Ucorno de savia roja",
      "Ramas de ucorno embotadas", "Ramas de ucorno entortilladas", "Ramas de ucorno inútiles",
      "Ramas de ucorno nudosas", "Ramas de ucorno poderosas", "Ramas de ucorno rotas",
      "Ramas de ucorno rígidas", "Ramas de ucorno secas", "Ramas de ucorno torcidas" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de abeto" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de cerezo" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de madera de deriva" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de muérdago" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de obstáculo fuertes" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de perejil" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de pimienta" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de sauce" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de teca", "Ramas de teca pesadas" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas de árbol" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas del Langflood", "Ramas pesadas del Langflood" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas del valle" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas desgastadas" },
    {})

register({ profession = "LEÑADOR", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Ramas destrozadas" },
    {})

---------------------------------------------------------------------
-- GRANJERO (Farmer)
---------------------------------------------------------------------

register({ profession = "GRANJERO", tier = 1, zone = "Apprentice", confidence = "alta" },
    { "Campo de hoja Valle Largo" },
    {})

register({ profession = "GRANJERO", tier = 1, zone = "Apprentice", confidence = "alta" },
    { "Campo de Cebollas Amarillas" },
    { "Cebolla Amarilla" })

register({ profession = "GRANJERO", tier = 2, zone = "Journeyman", confidence = "alta" },
    { "Campo de Southern Star" },
    {})

register({ profession = "GRANJERO", tier = 2, zone = "Journeyman", confidence = "alta" },
    { "Campo de Repollos" },
    { "Repollo" })

register({ profession = "GRANJERO", tier = 3, zone = "Expert", confidence = "alta" },
    { "Campo de Galenas dulce" },
    {})

register({ profession = "GRANJERO", tier = 3, zone = "Expert", confidence = "alta" },
    { "Campo de Cebollas Verdes" },
    { "Cebolla verde" })

register({ profession = "GRANJERO", tier = 4, zone = "Artisan", confidence = "alta" },
    { "Campo de Fresas" },
    { "Racimo de fresas" })

register({ profession = "GRANJERO", tier = 4, zone = "Artisan", confidence = "alta" },
    { "Manzano de la Comarca" },
    { "Manzana de la Comarca" })

register({ profession = "GRANJERO", tier = 5, zone = "Master", confidence = "alta" },
    { "Campo de Zarzamoras" },
    { "Racimo de moras" })

register({ profession = "GRANJERO", tier = 5, zone = "Master", confidence = "alta" },
    { "Campo de patatas doradas de la Comarca" },
    { "Patata dorada de la Comarca" })

register({ profession = "GRANJERO", tier = 6, zone = "Supreme", confidence = "alta" },
    { "Campo de guisantes verdes" },
    { "Guisantes verdes" })

register({ profession = "GRANJERO", tier = 6, zone = "Supreme", confidence = "alta" },
    { "Campo de patata real" },
    { "Patata real" })

register({ profession = "GRANJERO", tier = 7, zone = "Westfold", confidence = "alta" },
    { "Campo de cebada negra" },
    {})

register({ profession = "GRANJERO", tier = 7, zone = "Westfold", confidence = "alta" },
    { "Campo de puerros" },
    { "Puerros" })

register({ profession = "GRANJERO", tier = 7, zone = "Westfold", confidence = "alta" },
    -- item confirmado en vivo por el usuario (2026-09-07): chat real mostro
    -- "Has adquirido: [Racimo de arándanos]" al recolectar este campo.
    { "Campo de arándanos" },
    { "Racimo de arándanos", "Racimos de arándanos" })

register({ profession = "GRANJERO", tier = 10, zone = "Anórien", confidence = "media" },
    {}, -- nombre del campo no localizado, solo el cultivo procesado
    { "Patata de Anórien" })

-- === EXPANSION 2026-09-07: campos de Granjero adicionales ===
-- Motivada por reporte real del usuario: "Racimo de frambuesas" (recolectado
-- en vivo) no disparaba la ventana de guardar porque "Campo de frambuesas"
-- no estaba registrado -- y no era el unico: de 86 campos de Granjero
-- confirmados por nombre en el diccionario oficial (LotRO Companion,
-- labels/es/items.xml), solo 14 estaban en este archivo. Los 72 de abajo
-- completan el resto. Mismo metodo de siempre (nombre ES confirmado por ID
-- compartido con el diccionario maestro) pero SIN tier/nivel de oficio
-- confirmado todavia (de ahi confidence="sin catalogar" y tier="?") -- el
-- objetivo es que la ventana de guardar SI aparezca para todos estos campos;
-- el tier real se puede corregir despues sin romper nada, editando solo ese
-- campo de la entrada correspondiente.
register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Anórien", "Campo de Anórien bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Ascuas" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Avena", "Campo de Avena bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Campotieso selecto", "Campo de Campotieso selecto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Cebada de Primavera" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Corneta", "Campo de Corneta bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Gundabad", "Campo de Gundabad bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Hoja dulce de la Comarca", "Campo de Hoja dulce de la Comarca bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Hojas de Siempreviva" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Iris", "Campo de Iris bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Ithilien", "Campo de Ithilien bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Lengalenas" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Lirio de los Valles" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Lobelia Dulce", "Campo de Lobelia Dulce bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Lúpulo Dorado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Lúpulo de las Quebradas del Norte" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Mecha de junco", "Campo de Mecha de junco bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Minas Ithil", "Campo de Minas Ithil bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Southlinch" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de Umbar", "Campo de Umbar bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de acianos", "Campo de acianos bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de amapolas" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de amarantos", "Campo de amarantos bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de azafrán", "Campo de azafrán bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de bulbos resistentes" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de café", "Campo de café bien cuidado", "Campo de café robusto", "Campo de café robusto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de café de Estemnet", "Campo de café de Estemnet bien cuidado", "Campo de café de Estemnet robusto", "Campo de café de Estemnet robusto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de café de Oestemnet", "Campo de café de Oestemnet bien cuidado", "Campo de café de Oestemnet resistente", "Campo de café de Oestemnet robusto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de cebada de invierno", "Campo de cebada de invierno bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de centeno", "Campo de centeno bien cuidado", "Campo de centeno robusto", "Campo de centeno robusto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de champiñones de las Tierras del Rey", "Campo de champiñones de las Tierras del Rey bien cuidado", "Campo de champiñones de las Tierras del Rey robusto", "Campo de champiñones de las Tierras del Rey robusto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de coliflor", "Campo de coliflor bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de flores silvestres", "Campo de flores silvestres bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    -- item confirmado en vivo por el usuario (2026-09-07): chat real mostro
    -- "Has adquirido: [Racimo de frambuesas]" al recolectar este campo.
    { "Campo de frambuesas", "Campo de frambuesas bien cuidado" },
    { "Racimo de frambuesas" })

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de frijoles", "Campo de frijoles bien cuidado", "Campo de frijoles resistente" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de frijoles robustos bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de grano" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa Aliento del Dragón", "Campo de hierba para pipa Aliento del Dragón bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa Fuego del Mago" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa Nudo del Cordel" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa Nudo del Cordelero bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa Pies Barrosos", "Campo de hierba para pipa Pies Barrosos bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa Trenza Gamwich" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa Viejo Toby", "Campo de hierba para pipa Viejo Toby bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa cosechado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa de Alas de Águila Vieja", "Campo de hierba para pipa de Alas de Águila Vieja bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa de Bayaoso", "Campo de hierba para pipa de Bayaoso bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa de Fuego Dorado", "Campo de hierba para pipa de Fuego Dorado bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa de Hoja Vellosa de Fungo", "Campo de hierba para pipa de Hoja Vellosa de Fungo bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa de hoja de Lyndelby", "Campo de hierba para pipa de hoja de Lyndelby bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa del Nido del Águila" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa mayormente cosechado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa parcialmente cosechado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba para pipa salvaje", "Campo de hierba para pipa salvaje bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hierba verde de verano", "Campo de hierba verde de verano bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de hongos", "Campo de hongos bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de jacintos", "Campo de jacintos bien cuidado", "Campo de jacintos robusto", "Campo de jacintos robusto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de lúpulo Orgullo del bosque de Chet", "Campo de lúpulo Orgullo del bosque de Chet bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de lúpulo de las Colinas Verdes", "Campo de lúpulo de las Colinas Verdes bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de lúpulo de umbela", "Campo de lúpulo de umbela bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de menta", "Campo de menta bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de nabos", "Campo de nabos bien cuidado", "Campo de nabos robusto", "Campo de nabos robusto bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de papas", "Campo de papas bien cuidado" },
    { "Patata" })

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de puerros robustos bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de sanguisorba", "Campo de sanguisorba bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de saúco", "Campo de saúco bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de trigo" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de tulipanes" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de té", "Campo de té bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo de zanahorias", "Campo de zanahorias bien cuidado" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Campo del Valle del Hierro", "Campo del Valle del Hierro bien cuidado" },
    {})

---------------------------------------------------------------------
-- ERUDITO (Scholar)
---------------------------------------------------------------------

register({ profession = "ERUDITO", tier = 1, zone = "Apprentice", confidence = "alta" },
    { "Jarra rota" },
    { "Trozo de Texto Antiguo" })

register({ profession = "ERUDITO", tier = 2, zone = "Journeyman", confidence = "alta" },
    { "Urna rota" },
    { "Fragmento de Tableta Desgastada" })

register({ profession = "ERUDITO", tier = 3, zone = "Expert", confidence = "alta" },
    { "Jarrón antiguo" }, -- ojo: mismo nombre ES que tier 5 (item ingles distinto, ver nota Tier 5)
    { "Tallado Enano Agrietado" })

register({ profession = "ERUDITO", tier = 4, zone = "Artisan", confidence = "alta" },
    { "Texto olvidado" },
    { "Fragmento de Escritura Dúnedain" })

register({ profession = "ERUDITO", tier = 5, zone = "Master", confidence = "alta" },
    {}, -- "Jarrón antiguo" ya registrado como nodo del tier 3 (mismo nombre ES, ambiguo -- no
        -- se puede distinguir tier 3 vs 5 solo por el nombre del nodo en chat)
    { "Tallado de elfo desgastado" })

register({ profession = "ERUDITO", tier = 6, zone = "Supreme", confidence = "alta" },
    { "Casillero del sabio", "Cofre del sabio", "Caja de seguridad del sabio" },
    { "Tableta tallada con runas" })

register({ profession = "ERUDITO", tier = 7, zone = "Westfold", confidence = "alta" },
    { "Cofre con bandas", "Cofre con bandas pesado" },
    { "Trozo de texto dunlendino desgastado" })

register({ profession = "ERUDITO", tier = 8, zone = "Eastemnet", confidence = "alta" },
    { "Caché ornamentado", "Caché ornamentado pesado" },
    { "Fragmento de texto rohirrim" })

register({ profession = "ERUDITO", tier = 9, zone = "Westemnet", confidence = "alta" },
    { "Cofre ornamentado", "Cofre ornamentado pesado" },
    { "Pergamino rohirrim raído" })

register({ profession = "ERUDITO", tier = 10, zone = "Anórien", confidence = "alta" },
    { "Cofre opulento", "Cofre opulento pesado" },
    { "Pergamino andrajoso de Anórien" })

register({ profession = "ERUDITO", tier = 11, zone = "Dagorlad", confidence = "media" },
    -- mismo zona/tier que el nodo de Minero "Veta de chatarra de Dagorlad"
    -- (ver seccion MINERO arriba) -- nombres confirmados por diccionario,
    -- tier asumido por analogia de zona, no confirmado en vivo.
    { "Cofre opulento de Dagorlad", "Cofre opulento pesado de Dagorlad" },
    {})

register({ profession = "ERUDITO", tier = 11, zone = "Gorgoroth", confidence = "media" },
    { "Cofre de artefactos de Gorgoroth", "Cofre pesado de artefactos de Gorgoroth" },
    {})

register({ profession = "ERUDITO", tier = 11, zone = "Doomfold (Valle de la Perdición)", confidence = "baja" },
    {}, -- nombre del nodo no localizado, igual que la entrada equivalente de MINERO
    { "Pergamino andrajoso de Valle de la Perdición" })

register({ profession = "ERUDITO", tier = 12, zone = "Ironfold (Valle del Hierro)", confidence = "media" },
    { "Cofre de artefactos del Valle del Hierro" },
    { "Pergamino andrajoso de Valle del Hierro" })

register({ profession = "ERUDITO", tier = 12, zone = "Vales de Anduin", confidence = "alta" },
    -- tier corregido de 13 a 12 (2026-09-07): confirmado por MoorMap
    -- NodeTier.lua, "Vales Artifact Chest" esta en tier 12, no 13 -- se
    -- habia asumido 13 antes por analogia con la zona de Minero/Erudito
    -- "Minas Ithil"/Langflood que si son tier 13.
    { "Cofre de artefactos de los Valles", "Cofre pesado de artefactos de los Valles" },
    {})

register({ profession = "ERUDITO", tier = 13, zone = "Minas Ithil", confidence = "alta" },
    { "Cofre de artefactos de Ithil", "Cofre pesado de artefactos de Ithil" },
    { "Pergamino raído de Minas Ithil" })

register({ profession = "ERUDITO", tier = 13, zone = "Langflood", confidence = "alta" },
    -- nombre de nodo confirmado por MoorMap NodeTier.lua (2026-09-07):
    -- "Runed Coffer"/"Heavy Runed Coffer" -> "Cofre rúnico"/"Cofre rúnico
    -- pesado", agrupado en tier 13 junto a "Ithil Artifact Chest".
    { "Cofre rúnico", "Cofre rúnico pesado" },
    { "Pergamino raído de Langflood" })

register({ profession = "ERUDITO", tier = 14, zone = "Gundabad", confidence = "alta" },
    -- nombre de nodo confirmado por MoorMap NodeTier.lua (2026-09-07):
    -- "Sage's Coffer"/"Sage's Repository" -> "Cofre de sabio"/"Repositorio
    -- de sabio", tier 14.
    { "Cofre de sabio", "Repositorio de sabio" },
    { "Pergamino andrajoso de Gundabad" })

register({ profession = "ERUDITO", tier = 15, zone = "Umbar", confidence = "media" },
    -- confirmado por MoorMap NodeTier.lua: "Artifact Chest" (generico, sin
    -- prefijo de zona -- "they seemed to drop the Umbar in Harad" segun el
    -- comentario original de MoorMap) tier 15.
    { "Cofre de Artefactos" },
    {})

register({ profession = "ERUDITO", tier = 16, zone = "Sul Madásh", confidence = "media" },
    -- confirmado por MoorMap NodeTier.lua: "Desert Artifact"/"Well-preserved
    -- Desert Artifact" tier 16, misma zona que Minero/Leñador Sul Madásh.
    { "Artefacto del desierto", "Artefacto del desierto bien conservado" },
    {})

-- === EXPANSION 2026-09-07: nodos de Erudito adicionales (candidatos) ===
-- Motivada por reporte real del usuario: los jarrones no disparaban la
-- ventana de guardar. Mismo patron de adjetivos que las entradas YA
-- confirmadas arriba (roto/rota, antiguo, desgastado, agrietado) -- existen
-- en el diccionario oficial (labels/es/items.xml) pero NO se pudo confirmar
-- en vivo su tier exacto. A diferencia de MINERO/LEÑADOR/GRANJERO, para
-- ERUDITO "Cofre"/"Urna"/"Jarrón" TAMBIEN se usan para muchos objetos de
-- recompensa/vivienda no relacionados con recoleccion (cofres de mascotas,
-- jarrones decorativos de festival, etc.) -- se filtraron a mano SOLO los
-- que comparten vocabulario con las entradas ya confirmadas, para minimizar
-- el riesgo de registrar algo que NO es un nodo real de recoleccion.
-- confidence="sin confirmar" a proposito -- revisar en vivo antes de subir
-- a "alta".
register({ profession = "ERUDITO", tier = "?", zone = "sin catalogar", confidence = "sin confirmar" },
    { "Jarra antigua", "Jarra abandonada", "Jarra oxidada" },
    {})

register({ profession = "ERUDITO", tier = "?", zone = "sin catalogar", confidence = "sin confirmar" },
    { "Jarrón antiguo pesado" },
    {})

register({ profession = "ERUDITO", tier = "?", zone = "sin catalogar", confidence = "sin confirmar" },
    { "Jarrón desgastado por el tiempo" },
    {})

register({ profession = "ERUDITO", tier = "?", zone = "sin catalogar", confidence = "sin confirmar" },
    { "Jarrón Astillado", "Jarrón roto" },
    {})

register({ profession = "ERUDITO", tier = "?", zone = "sin catalogar", confidence = "sin confirmar" },
    { "Urna con inscripción rúnica", "Urna premonitoria" },
    {})

register({ profession = "ERUDITO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    -- generico, no se pudo atar a una zona especifica (distinto de "Cofre de
    -- artefactos del Valle del Hierro" ya registrado en tier 12)
    { "Cofre de artefactos del Valle", "Cofre pesado de artefactos del Valle" },
    {})

register({ profession = "ERUDITO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    -- probable Khazâd-dûm (Moria) por el idioma "khuzdul", zona/tier sin confirmar
    {},
    { "Pergamino raído de khuzdul" })

-- === EXPANSION 2026-09-07: plantas de tinte (mecanica separada, sin nodo previo) ===
-- Confirmado por MoorMap NodeTier.lua ("scholar items", categoria 48,
-- separada de los cofres/jarrones categoria 45): son plantas que se
-- recolectan por interaccion directa, igual que Colmena en GRANJERO -- NO
-- generan la linea "Tomando los contenidos de X..." antes del item, asi que
-- dependen del fix de GatherEventParser.lua que dispara la captura desde el
-- ITEM cuando no hay nodo pendiente. Nombre de nodo = nombre de item (la
-- planta que se ve/clickea en el mundo es el mismo objeto que se recibe).
register({ profession = "ERUDITO", tier = 1, zone = "Apprentice", confidence = "alta", directPickup = true },
    { "Plantas de milenrama" },
    { "Raíz de milenrama", "Raíces de milenrama" })

register({ profession = "ERUDITO", tier = 2, zone = "Journeyman", confidence = "alta", directPickup = true },
    { "Planta de guede", "Plantas de guede" },
    { "Planta de guede", "Plantas de guede" })

register({ profession = "ERUDITO", tier = 2, zone = "Journeyman", confidence = "media", directPickup = true },
    {}, -- nombre exacto del nodo en el mundo sin confirmar (distinto de "Planta de guede")
    { "Planta de Índigo" })

---------------------------------------------------------------------
-- GRANJERO -- Apicultura (Colmenas)
---------------------------------------------------------------------
-- BUG REAL encontrado en vivo (2026-09-07): "Gota de miel fina de trébol" y
-- "Racimo de arándanos" llegaban en el chat SIN ninguna linea previa de
-- "Tomando los contenidos de X..." -- la apicultura (Colmena) es una
-- mecanica de recoleccion distinta (interaccion directa) que no sigue el
-- patron nodo-primero del resto de las profesiones. Se agrega aca la
-- variante Colmena confirmada por nombre en el diccionario oficial
-- (LotRO Companion, labels/es/items.xml) + Core/GatherEventParser.lua ahora
-- puede disparar la captura directamente desde el ITEM cuando no hay un
-- nodo pendiente activo (ver nota en ese archivo), asi que con solo
-- registrar el item alcanza para que la ventana de guardar aparezca aunque
-- nunca llegue una linea de nodo para este tipo de recoleccion.
register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar", directPickup = true },
    { "Colmena", "Colmena pequeña", "Colmena simple", "Colmena prometedora", "Colmena silvestre" },
    { "Gota de miel", "Gotas de miel", "Miel fresca" })

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Colmena abandonada", "Colmenas abandonadas" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Colmena corrupta" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Colmena de Grodbog" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    { "Colmena de abejas de Dun", "Colmenas de abejas de Dun" },
    {})

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar", directPickup = true },
    -- item confirmado en vivo por el usuario (2026-09-07): chat real mostro
    -- "Has adquirido: [Gota de miel fina de trébol]".
    {},
    { "Gota de miel fina de trébol", "Gotas de miel fina de trébol" })

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar", directPickup = true },
    {},
    { "Gota de miel de flores silvestres", "Gotas de miel de flores silvestres" })

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar", directPickup = true },
    {},
    { "Gotas de miel de los Valles" })

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar", directPickup = true },
    -- confirmado por MoorMap NodeTier.lua ("Stalk of Rhubarb"): recoleccion
    -- directa, sin nombre de campo/nodo localizado -- item-only trigger.
    {},
    { "Tallo de ruibarbo", "Tallos de ruibarbo" })

register({ profession = "GRANJERO", tier = "?", zone = "sin catalogar", confidence = "sin catalogar" },
    -- confirmado por MoorMap NodeTier.lua ("Cap of Evengleam", nodo de
    -- evento/temporada U20) -- sin nombre de campo distinto localizado.
    { "Sombrero de Evengleam", "Sombreros de Evengleam" },
    { "Sombrero de Evengleam", "Sombreros de Evengleam" })
