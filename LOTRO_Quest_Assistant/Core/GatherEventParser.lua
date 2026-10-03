-- LOTRO_Quest_Assistant/Core/GatherEventParser.lua
-- Detecta en el chat cuando el jugador recolecta un nodo de una profesion de
-- recoleccion (Minero/Leñador/Granjero/Erudito). Mismo esqueleto que
-- Core/QuestEventParser.lua -- ver Arquitectura_GatherSync.md #3.2 para el
-- ejemplo real de chat que confirmo estos 2 patrones.
--
-- Ejemplo real de chat (minando una veta de cobre):
--   Has ganado 24 de experiencia para un total de 855,787 de experiencia.
--   Tomando los contenidos de los Veta de cobre...
--   Has adquirido: [Piedra de afilar rudimentaria].
--   Has adquirido: [2 Bloques de mineral de cobre].
--
-- La linea "Tomando los contenidos de X..." es el disparador PRINCIPAL: nombra
-- el nodo directamente, sin ambiguedad, y es el momento correcto para capturar
-- la coordenada (ver Legacy/LocationAdapter.lua). El articulo antes del
-- nombre del nodo varia segun genero/numero (salio "de los Veta de cobre" en
-- la captura real, con concordancia rara) -- por eso el patron captura texto
-- libre en vez de anclarse a un articulo fijo.
--
-- Las lineas "Has adquirido: [item]" son secundarias: confirman que
-- materiales concretos salieron (utiles para el detalle del punto guardado)
-- pero no hace falta que coincidan para saber que hubo un evento de
-- recoleccion -- eso ya lo dio la linea del nodo.
import "Turbine"

_G.GatherEventParser = {}

-- NODE ya no ancla el sufijo "..." en el patron -- se probo en vivo
-- (2026-08-23) y el mensaje real es "Tomando los contenidos de los Veta de
-- cobre..." donde el "..." final puede ser 3 puntos literales O el caracter
-- unicode de puntos suspensivos (U+2026, "\226\128\166" en UTF-8) segun como
-- lo mande el cliente -- adivinar cual de los 2 rompia el patron en silencio
-- (nodeNameRaw quedaba nil, ni el caso exito ni el de error se disparaban).
-- Ahora se captura TODO lo que sigue y se limpia en CleanNodeName().
--
-- El patron YA NO exige la palabra "de" -- se confirmo en vivo (2026-09-07,
-- Erudito con "Jarron antiguo") que la plantilla de genero del cliente
-- ("Tomando los contenidos #1:{del[m]|de la[f]|de los[mp]|de las[fp]|de[n]}
-- #1:") a veces resuelve el articulo a VACIO segun el genero del objeto,
-- dando "Tomando los contenidos Jarron antiguo..." sin ningun "de/del/de
-- la" -- con el patron anterior (que exigia "de%s+") nodeNameRaw quedaba nil
-- y TODO el bloque de deteccion se saltaba en silencio (ni exito ni error).
-- Se reproduce igual con distintas versiones del .dat, asi que no es
-- corrupcion de traduccion -- es una variante real del cliente que hay que
-- tolerar aca.
--
-- Generalizado (2026-09-07): en vez de cubrir SOLO "con de" y "sin de" como
-- 2 casos puntuales, la limpieza de prefijos abarca CUALQUIER combinacion de
-- genero/numero de la plantilla del cliente (con o sin "de" delante, en
-- cualquier orden) y queda preparada para variantes nuevas que aparezcan mas
-- adelante -- ver PrefixStrip() mas abajo.
local PATTERNS = {
    NODE = "^Tomando los contenidos%s*(.+)$",
    -- ": " y "." al final se vuelven opcionales/flexibles (espacios extra,
    -- sin punto final, etc.) -- mismo principio que NODE: no asumir que el
    -- cliente siempre manda el formato exacto observado hasta hoy.
    ITEM = "^Has adquirido:%s*%[(.-)%]%.?%s*$",
}

-- Mismo motivo que arriba: el mensaje real trae un articulo de mas antes del
-- nombre del nodo ("...de los Veta de cobre...", con "los" fijo sin importar
-- genero/numero real -- probablemente una plantilla generica del cliente) --
-- o directamente NINGUN articulo ("...Jarron antiguo...", ver nota arriba).
-- GatherNodesDB.byNode esta indexado SIN articulo, asi que hay que sacarlo
-- antes de buscar. Loop en vez de patron con alternancia porque Lua no
-- soporta "(a|b|c)" en sus patrones.
--
-- DE_PREFIXES cubre las 5 formas de la plantilla de genero del cliente
-- (#1:{del[m]|de la[f]|de los[mp]|de las[fp]|de[n]} #1:, ver .dat token
-- 0x0C5D7105 en tabla 0x250001B2) -- "de[n]" es la forma neutra/vacia, por
-- eso "de " (sin nada detras) tambien esta en la lista. ARTICLES cubre
-- definidos e indefinidos, singular y plural, por si el nombre del nodo
-- trae su propio articulo suelto sin "de" delante. Los mas largos van
-- primero en cada lista para no cortar "de la"/"de los"/"de las" a mitad
-- como si fueran solo "de ".
local DE_PREFIXES = { "de la ", "de los ", "de las ", "del ", "de " }
local ARTICLES = { "los ", "las ", "una ", "unos ", "unas ", "el ", "la ", "un " }
local ELLIPSIS_UTF8 = "\226\128\166" -- U+2026 "…" en UTF-8

-- Aplica DE_PREFIXES y ARTICLES en bucle (no solo una pasada de cada uno)
-- hasta que ninguno matchee mas -- asi cubre combinaciones encadenadas que
-- puedan aparecer a futuro (p.ej. un prefijo de genero seguido de un
-- articulo suelto) sin tener que anticipar cada caso a mano.
local function PrefixStrip(name)
    local changed = true
    while changed do
        changed = false
        for _, prefix in ipairs(DE_PREFIXES) do
            if string.sub(name, 1, #prefix) == prefix then
                name = string.sub(name, #prefix + 1)
                changed = true
                break
            end
        end
        for _, article in ipairs(ARTICLES) do
            if string.sub(name, 1, #article) == article then
                name = string.sub(name, #article + 1)
                changed = true
                break
            end
        end
    end
    return name
end

local function CleanNodeName(raw)
    local name = string.gsub(raw, "^%s*(.-)%s*$", "%1")
    name = string.gsub(name, "%.+$", "")
    name = string.gsub(name, ELLIPSIS_UTF8 .. "+$", "")
    name = string.gsub(name, "^%s*(.-)%s*$", "%1")
    name = PrefixStrip(name)
    return name
end

-- Separa una cantidad al frente ("2 Bloques de mineral de cobre" -> "Bloques
-- de mineral de cobre") -- GatherNodesDB.byItem esta indexado por el nombre
-- SIN cantidad. Ya no se usa para detectar el item (ver FindItemMatch), pero
-- se deja por si algun llamador externo la necesita.
local function StripQuantity(text)
    local rest = string.match(text, "^%d+%s+(.+)$")
    return rest or text
end

-- BUG REAL encontrado en vivo (2026-09-07, con diagnostico byte-a-byte):
-- PATTERNS.ITEM asumia que "Has adquirido: [X]." era el mensaje CRUDO
-- completo -- pero el mensaje real que le llega a Lua NO es texto plano: un
-- item adquirido en LOTRO es un link clickeable con metadatos incrustados
-- (confirmado con el diagnostico: un mensaje que se ve como "Has adquirido:
-- [Racimo de arándanos]." (38 caracteres visibles) media en realidad 204
-- bytes, terminando en "...ItemInstance>.\n" -- el corchete "[...]" que se
-- VE en el chat es solo como el cliente RENDERIZA ese link, no lo que hay
-- en el string real). Por eso el patron anclado a "%]%.?%s*$" nunca
-- coincidia con NINGUN item, sin importar cual. En vez de asumir un formato
-- exacto que resulto ser incorrecto, se busca directamente si alguno de los
-- nombres YA REGISTRADOS en GatherNodesDB.byItem aparece como substring en
-- cualquier parte del mensaje (string.find plano, sin patron, para no
-- pelear con caracteres especiales en los nombres) -- funciona sin importar
-- que metadatos rodeen al nombre. Se prefiere el nombre MAS LARGO que
-- matchee (ej. "Gota de miel fina de trébol" sobre "Gota de miel") para no
-- confundir un item mas especifico con uno generico que es substring suyo.
local function FindItemMatch(message)
    local bestName, bestEntry, bestLen = nil, nil, 0
    for name, entry in pairs(_G.GatherNodesDB.byItem) do
        if #name > bestLen and string.find(message, name, 1, true) ~= nil then
            bestName, bestEntry, bestLen = name, entry, #name
        end
    end
    return bestName, bestEntry
end

-- Ultimo nodo detectado por la linea "Tomando los contenidos de X..." --
-- las lineas "Has adquirido" que le siguen en el mismo evento de recoleccion
-- se acumulan aca hasta que EventBus dispara la captura de coordenada.
local pendingNode = nil
local pendingItems = nil
local pendingNodeTime = nil

-- El flujo soportado hoy (ver Arquitectura_GatherSync.md #6, Plan B) es
-- MANUAL: el jugador recolecta y despues escribe /loc el mismo a mano.
-- LocationAdapter.ParseLocationMessage procesa CUALQUIER respuesta de /loc,
-- sin importar por que se disparo -- si el jugador recolecta un nodo, se
-- distrae, camina a otro lado y recien ahi escribe /loc (por curiosidad, o
-- por otro addon que lo dispare), pendingNode seguia ahi indefinidamente y
-- ese /loc tardio le pegaba la coordenada NUEVA (equivocada) al nodo VIEJO.
-- 90s alcanza de sobra para el uso real (leer el loot + escribir /loc a
-- mano toma segundos, no minutos) sin ser tan corto como para descartar un
-- /loc levemente demorado.
local PENDING_TIMEOUT_SECONDS = 90

function GatherEventParser.ParseMessage(sender, message)
    if not message then return false end
    if LQA.Debug.Enabled then
        Turbine.Shell.WriteLine("<rgb=#00AAFF>GatherSync CHAT INTERCEPT: </rgb>" .. tostring(message))
    end

    local nodeNameRaw = string.match(message, PATTERNS.NODE)
    if nodeNameRaw ~= nil then
        local nodeName = CleanNodeName(nodeNameRaw)
        local entry = _G.GatherNodesDB.byNode[nodeName]
        if entry == nil then
            -- Ya no es "siempre visible" (2026-09-07, pedido del usuario:
            -- "sacar los ruidos del chat") -- el flujo se valido a fondo
            -- esta sesion, ver nota igual en GatherPointsStore.lua. Detras
            -- de LQA.Debug.Enabled para quien necesite reportar un nodo
            -- faltante.
            if LQA.Debug.Enabled then
                Turbine.Shell.WriteLine("<rgb=#FF0000>GatherSync: nodo detectado en el chat pero NO esta en GatherNodesDB -> \"" ..
                    tostring(nodeName) .. "\"</rgb>")
            end
            pendingNode = nil
            pendingItems = nil
            pendingNodeTime = nil
            return false
        end

        pendingNode = entry
        pendingItems = {}
        pendingNodeTime = Turbine.Engine.GetGameTime()
        if LQA.Debug.Enabled then
            Turbine.Shell.WriteLine("<rgb=#00FF00>GatherSync: nodo reconocido -> " ..
                tostring(nodeName) .. " | " .. tostring(entry.profession) ..
                " tier " .. tostring(entry.tier) .. " (confianza=" .. tostring(entry.confidence) .. ")</rgb>")
        end

        -- Dispara la captura de coordenada YA -- no esperamos a las lineas de
        -- "Has adquirido" porque no todas llegan en el mismo tick de chat.
        LQA.Core.EventBus:Publish("GATHER_NODE_DETECTED", { entry = entry, nodeName = nodeName })
        return true
    end

    if string.sub(message, 1, 14) == "Has adquirido:" then
        local itemName, entry = FindItemMatch(message)
        if entry ~= nil then
            -- BUG REAL encontrado en vivo (2026-09-07, reportado por el
            -- usuario probando varios items seguidos -- miel funciono/no se
            -- confirmo, y DESPUES frambuesas y patata dejaron de disparar
            -- por completo): un pendingNode disparado por un item (ver mas
            -- abajo) que el jugador nunca termina de confirmar con /loc (por
            -- ejemplo cierra el popup con la "X", que solo lo esconde, no
            -- limpia el estado -- ver GatherCaptureButton.lua) se quedaba
            -- PEGADO indefinidamente -- cualquier item nuevo, de CUALQUIER
            -- profesion, solo se acumulaba en silencio al pendiente viejo
            -- en vez de disparar un aviso nuevo, porque la condicion de
            -- abajo solo miraba "pendingNode ~= nil", nunca su antiguedad.
            -- Se agrega el mismo criterio de PENDING_TIMEOUT_SECONDS que ya
            -- usa ConsumePendingGather: un pendiente mas viejo que eso se
            -- trata como si no existiera, y el item actual dispara fresco.
            local pendingIsStale = pendingNodeTime ~= nil and
                (Turbine.Engine.GetGameTime() - pendingNodeTime) > PENDING_TIMEOUT_SECONDS
            if pendingNode ~= nil and pendingItems ~= nil and not pendingIsStale then
                table.insert(pendingItems, itemName)
            else
                -- BUG REAL encontrado en vivo (2026-09-07): apicultura
                -- (Colmena) y probablemente otras mecanicas de recoleccion
                -- "directas" NO mandan una linea "Tomando los contenidos de
                -- X..." antes del item -- el jugador reporto "Gota de miel
                -- fina de trebol" y "Racimo de arandanos" llegando SOLOS,
                -- sin nodo previo detectado, y la ventana de guardar nunca
                -- aparecia porque el flujo entero dependia de esa linea de
                -- nodo. Si el item se reconoce y no hay un nodo pendiente
                -- activo (o el que habia ya expiro, ver arriba), el item
                -- MISMO dispara la captura (mismo patron que el nodo:
                -- pendingNode/pendingItems/pendingNodeTime +
                -- GATHER_NODE_DETECTED) usando el nombre de nodo que ya trae
                -- la propia entrada (entry.node, ver register()) -- asi
                -- cualquier tipo de recoleccion que no siga el patron
                -- "nodo primero" tambien puede guardar su ubicacion.
                --
                -- BUG REAL #2 encontrado en vivo (2026-09-07, reportado por
                -- el usuario): esta misma via disparaba tambien con items que
                -- NO son de recoleccion directa -- ej. "Tallado de elfo
                -- desgastado" (Erudito tier 5) esta registrado SOLO como
                -- item en GatherNodesDB (sin nodeNames) no porque se recoja
                -- por interaccion directa, sino porque su nodo real
                -- ("Jarron antiguo") ya esta registrado en el tier 3 con el
                -- mismo nombre ES (ver comentario junto al registro) -- es
                -- decir, el hueco en nodeNames es un artefacto de la
                -- ambiguedad de nombres, no una senal de que el item no tenga
                -- nodo. Al no distinguir esto, matar un mob que suelta ese
                -- mismo item disparaba la ventana de guardar igual, con la
                -- ubicacion de la muerte del mob (no de ningun nodo real).
                -- Fix: solo disparar esta via "item sin nodo previo" para
                -- entradas marcadas explicitamente entry.directPickup=true
                -- en GatherNodesDB.lua (Colmena/miel, Tallo de ruibarbo,
                -- plantas de tinte de Erudito -- las unicas confirmadas por
                -- MoorMap NodeTier.lua como recoleccion sin linea de nodo).
                -- Cualquier otro item reconocido sin nodo pendiente activo se
                -- ignora en silencio, igual que loot normal de mob/mision.
                if not entry.directPickup then
                    if LQA.Debug.Enabled then
                        Turbine.Shell.WriteLine("<rgb=#FFAA00>GatherSync: item de recoleccion (" ..
                            tostring(itemName) .. ") reconocido SIN nodo pendiente y sin directPickup -- " ..
                            "descartado (probable loot de mob/mision, no un nodo real).</rgb>")
                    end
                    return false
                end
                pendingNode = entry
                pendingItems = { itemName }
                pendingNodeTime = Turbine.Engine.GetGameTime()
                if LQA.Debug.Enabled then
                    Turbine.Shell.WriteLine("<rgb=#00FF00>GatherSync: item reconocido sin nodo previo -> " ..
                        tostring(itemName) .. " | " .. tostring(entry.profession) ..
                        " tier " .. tostring(entry.tier) .. " (confianza=" .. tostring(entry.confidence) .. ")</rgb>")
                end
                LQA.Core.EventBus:Publish("GATHER_NODE_DETECTED", { entry = entry, nodeName = entry.node })
                return true
            end
            if LQA.Debug.Enabled then
                Turbine.Shell.WriteLine("<rgb=#00FF00>GatherSync DEBUG: item reconocido = " ..
                    tostring(itemName) .. " | profesion=" .. tostring(entry.profession) ..
                    " | tier=" .. tostring(entry.tier) .. "</rgb>")
            end
            LQA.Core.EventBus:Publish("GATHER_ITEM_RECEIVED", { entry = entry, itemName = itemName })
            return true
        end
        -- No es un material de recoleccion conocido (loot normal de mob,
        -- misiones, etc.) -- se ignora en silencio, no es un error.
        return false
    end

    return false
end

-- Devuelve el ultimo nodo detectado y los items acumulados desde entonces
-- (usado por LocationAdapter.lua al confirmar la coordenada, ver
-- Arquitectura_GatherSync.md #3.3/#3.4) y limpia el estado pendiente.
--
-- BUG REAL encontrado en revision (2026-08-27): GatherNodesDB.byNode es un
-- diccionario plano por nombre ES -- cuando 2 tiers distintos comparten el
-- MISMO nombre de nodo en español (pasa con Erudito T3 "Antique Vase" vs T5
-- "Ancient Vase", ambos "Jarrón antiguo" en el diccionario oficial, ver
-- LOTRO_recoleccion_tiers.md linea 162 y el comentario en
-- Data/GatherNodesDB.lua junto al registro de T5), la linea del NODO siempre
-- resuelve al tier que se registro primero (T3) -- el T5 quedaba SIEMPRE mal
-- guardado como T3, sin ningun aviso, y esa etiqueta erronea se propagaba
-- ademas a la anotacion de MoorMap (Main.lua GATHER_POINT_ADDED). Los nombres
-- de ITEM si son unicos entre tiers (confirmado por ID en el diccionario), asi
-- que si alguno de los items recibidos en este mismo evento resuelve a una
-- entrada mas especifica (mismo profession, pero objeto de tier distinto),
-- se prefiere esa sobre la resuelta por nombre de nodo.
local function _ResolveMoreSpecificEntry(nodeEntry, items)
    if nodeEntry == nil or items == nil then
        return nodeEntry
    end
    for _, itemName in ipairs(items) do
        local itemEntry = _G.GatherNodesDB.byItem[itemName]
        if itemEntry ~= nil and itemEntry.profession == nodeEntry.profession and itemEntry ~= nodeEntry then
            return itemEntry
        end
    end
    return nodeEntry
end

function GatherEventParser.ConsumePendingGather()
    local node, items, nodeTime = pendingNode, pendingItems, pendingNodeTime
    pendingNode = nil
    pendingItems = nil
    pendingNodeTime = nil

    if node == nil then
        return nil, nil
    end

    -- Ver nota de PENDING_TIMEOUT_SECONDS arriba: un /loc que llega mucho
    -- despues del nodo detectado probablemente no le corresponde (el
    -- jugador ya se movio) -- se descarta en vez de guardar una coordenada
    -- equivocada. Aviso siempre visible (mismo criterio que el resto de
    -- este archivo) para que el jugador entienda por que no se guardo nada.
    local elapsed = nodeTime ~= nil and (Turbine.Engine.GetGameTime() - nodeTime) or nil
    if elapsed ~= nil and elapsed > PENDING_TIMEOUT_SECONDS then
        Turbine.Shell.WriteLine("<rgb=#FF0000>GatherSync: /loc llego " ..
            string.format("%.0f", elapsed) .. "s despues del nodo detectado (\"" ..
            tostring(node.node) .. "\") -- descartado por posible desactualizacion, punto NO guardado.</rgb>")
        return nil, nil
    end

    return _ResolveMoreSpecificEntry(node, items), items
end

-- Escape hatch inmediato (2026-09-07, ver nota grande junto al bloque de
-- ITEM mas arriba): permite limpiar el pendiente sin esperar los 90s del
-- timeout -- se llama desde el boton "X" de GatherCaptureButton.lua, que
-- antes solo escondia la ventana y dejaba el estado interno pegado.
function GatherEventParser.CancelPending()
    pendingNode = nil
    pendingItems = nil
    pendingNodeTime = nil
end
