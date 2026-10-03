-- LOTRO_Quest_Assistant/Integration/MoorMapAdapter.lua
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.MoorMapAdapter = {}

-- Encapsulamos la complejidad de Quickslot/Alias para cumplir con la arquitectura.
-- LOTRO prohibe ejecutar comandos chat programaticamente, por lo que el adapter
-- expone Quickslots reales que la UI superior puede emparentar a un boton/icono
-- visible: al clicarlos, LOTRO ejecuta su Shortcut (alias) por nosotros.
--
-- IMPORTANTE: cada boton/icono clicable necesita su PROPIO Quickslot. Antes
-- habia un unico MoorMapAdapter.Quickslot compartido, y dos ventanas
-- (QuestSyncWindow y QuestTrackerHUD) intentaban emparentarlo cada una bajo su
-- propio boton -- un control solo puede tener un padre a la vez, asi que la
-- segunda ventana en construirse le "robaba" el Quickslot a la primera y ese
-- boton se quedaba sin nada real detras con lo que recibir el clic.
function MoorMapAdapter.CreateQuickslot()
    local qs = Turbine.UI.Lotro.Quickslot()
    qs:SetSize(32, 32)
    -- Debe permanecer Visible=true para recibir clics; se oculta con Opacity=0
    -- en su lugar (un control invisible no participa en el hit-test del mouse).
    qs:SetVisible(true)
    qs:SetOpacity(0)
    -- BUG (encontrado 2026-08-20, capturas del usuario mostrando "/MOO"/"/WAY"
    -- sangrando debajo de CADA boton MoorMap/Waypoint, incluso los ya
    -- agrandados a 60-115px de ancho en sesiones 12/19/20 -- esas sesiones
    -- asumieron que el problema era el ANCHO del boton, pero el sangrado
    -- persistia igual). Comparado contra el propio truco de Quickslot-detras-
    -- de-boton de CubePlugins/DeedTracker/PluginFunctions.lua (lineas
    -- ~1045-1048/1094-1097, con autorizacion del usuario como dueño de ese
    -- addon tambien): su Quickslot SI llama SetAllowDrop(false) despues de
    -- SetShortcut, algo que este adapter nunca hizo. Un Quickslot que acepta
    -- drops por defecto aparentemente reserva/dibuja una etiqueta nativa de
    -- LOTRO con el nombre del shortcut asignado, independiente del tamaño del
    -- control -- de ahi que agrandar el boton nunca lo arreglara del todo.
    qs:SetAllowDrop(false)
    return qs
end

-- REVERTIDO (2026-08-20, misma sesion). Se probo un experimento aca mismo
-- (quickslot como HERMANO del boton en vez de hijo, ZOrder invertido +
-- SetMouseVisible(false) en el boton para dejar pasar el clic) para atacar
-- el sangrado "/MOO"/"/WAY". Antes de darlo por bueno, se peino TODO
-- Plugins/ buscando un caso real y comprobado de ese patron exacto (clic
-- atravesando un control HERMANO mouse-invisible hacia otro control debajo,
-- en la misma posicion) -- no se encontro ninguno: todos los usos reales de
-- SetMouseVisible(false) en este entorno (Waypoint.lua, ChestsWindow.lua,
-- QuestSyncWindow.lua) son de un HIJO puramente decorativo dejando que su
-- PADRE/contenedor reciba el clic (burbujeo normal), nunca de un hermano
-- pasando el clic a otro hermano. Sin esa confirmacion, arriesgar que los 5
-- botones de navegacion (MoorMap/Waypoint/Ir, funcionalidad central del
-- addon) dejen de responder al clic por una hipotesis cosmetica no
-- verificada no vale la pena -- pedido explicito del usuario de proteger la
-- estructura funcional por sobre perseguir el bug visual. Vuelto a la
-- version anterior, con click garantizado: quickslot como HIJO del boton,
-- Opacity(0) para esconder el icono, ZOrder(10) para asegurar que reciba el
-- clic. El sangrado de texto sigue sin resolverse -- ver el bloque de
-- comentario de mas arriba (CreateQuickslot) para el historial completo de
-- intentos sobre este mismo bug.
function MoorMapAdapter.AttachToButton(quickslot, button)
    quickslot:SetParent(button)
    local w, h = button:GetSize()
    quickslot:SetPosition(0, 0)
    quickslot:SetSize(w, h)
    quickslot:SetZOrder(10)
end

-- BUG (encontrado 2026-08-18): el Readme.txt de MoorMap dice explicitamente
-- que NSCoord/EWCoord deben ser NUMEROS CON SIGNO -- "north values being
-- positive and south values being negative... East values being positive and
-- West values being negative" -- pero aqui se enviaba el texto crudo con la
-- letra pegada (p.ej. "25.29S"), que tonumber() no puede convertir. MoorMap
-- entonces rechazaba el ping silenciosamente (solo escribe el error al chat
-- estandar, no un popup) y no hacia nada. Esta funcion convierte un texto de
-- coordenada tipo "25.29S, 47.61W" al par de numeros con signo que MoorMap
-- realmente necesita.
function MoorMapAdapter.ParseCoord(questLoc)
    if not questLoc then return nil, nil end
    local nsNum, nsDir = string.match(questLoc, "([%d%.]+)%s*([NSns])")
    local ewNum, ewDir = string.match(questLoc, "([%d%.]+)%s*([EWew])")
    local ns = tonumber(nsNum)
    local ew = tonumber(ewNum)
    if not ns or not ew then return nil, nil end
    if nsDir == "S" or nsDir == "s" then ns = -ns end
    if ewDir == "W" or ewDir == "w" then ew = -ew end
    return ns, ew
end

function MoorMapAdapter.SetQuestMarker(quickslot, mapData)
    -- mapData: { mapID=9, ns=-29.5, ew=52.0, name="Nombre", description="Desc" }
    -- ns/ew deben venir ya como numeros con signo (ver MoorMapAdapter.ParseCoord).
    if not quickslot then return end

    -- Si la base de datos no pudo resolver el mapa o las coordenadas fallaron en parsearse,
    -- MoorMap arrojara errores en el chat ("ID de mapa no valido", "Coordenada no valida").
    -- Limpiamos el shortcut para que el boton no haga nada y evitamos el spam.
    if not mapData.mapID or mapData.mapID == 0 or (mapData.ns == 0 and mapData.ew == 0) then
        quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, ""))
        if LQA.Debug.Enabled then
            Turbine.Shell.WriteLine("<rgb=#FF00FF>QuestSync DEBUG: MoorMap ping abortado (mapID 0 o coord 0) para " .. tostring(mapData.name) .. "</rgb>")
        end
        return
    end

    -- LOTRO Lua locale bug: tostring(1.5) en Windows ES devuelve "1,5", pero
    -- tonumber("1,5") en MoorMap devuelve nil. Forzamos el uso del punto.
    local function formatCoord(n)
        if not n then return "0" end
        return string.gsub(tostring(n), ",", ".")
    end

    -- BUG CORREGIDO (2026-08-20, captura de pantalla del usuario mostrando
    -- el tooltip nativo del Quickslot con el comando completo): el nombre
    -- de la mision viajaba con tildes/ñ crudas dentro del comando de chat
    -- ("/MoorMap ping 4:-9.44:-41.27:Libro 6. Capítulo 2- Contra su
    -- señor:Objetivo") y volvia mostrado como "Cap?tulo"/"se?±or" -- el
    -- parser de comandos de barra (slash command) del cliente de LOTRO no
    -- es UTF-8-seguro de la misma forma que el chat normal (que si maneja
    -- UTF-8 bien, por eso el resto del addon nunca tuvo este problema). Se
    -- pliegan los acentos/ñ/¿/¡ a ASCII antes de meter el texto en el
    -- comando -- MoorMap solo usa esto como etiqueta cosmetica del pin, no
    -- afecta la navegacion real (mapID/ns/ew se mandan aparte, sin tocar).
    -- Mismo truco de reemplazo LITERAL de secuencia UTF-8 completa (no
    -- character class) que QuestLocResolver.toLowerES, por la misma razon
    -- (una character class en Lua compara byte a byte, no caracter a
    -- caracter, y nunca encontraria estas secuencias de 2 bytes).
    local FOLD_PAIRS = {
        {"\195\161", "a"}, {"\195\169", "e"}, {"\195\173", "i"}, {"\195\179", "o"}, {"\195\186", "u"},
        {"\195\129", "A"}, {"\195\137", "E"}, {"\195\141", "I"}, {"\195\147", "O"}, {"\195\154", "U"},
        {"\195\177", "n"}, {"\195\145", "N"}, {"\195\188", "u"}, {"\195\156", "U"},
        {"\194\191", ""}, {"\194\161", ""},
    }
    local function foldAscii(s)
        s = tostring(s or "")
        for _, pair in ipairs(FOLD_PAIRS) do
            s = string.gsub(s, pair[1], pair[2])
        end
        return s
    end

    local cmd = string.format("/MoorMap ping %s:%s:%s:%s:%s",
        tostring(mapData.mapID),
        formatCoord(mapData.ns),
        formatCoord(mapData.ew),
        foldAscii(mapData.name),
        foldAscii(mapData.description))

    if LQA.Debug.Enabled then
        Turbine.Shell.WriteLine("<rgb=#FF00FF>QuestSync DEBUG: MoorMap cmd = " .. cmd .. "</rgb>")
    end

    local sc = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, cmd)
    quickslot:SetShortcut(sc)
end

-- BUG (escaneo 2026-08-18, comparacion masiva Compendium/QuestDB vs
-- ZoneMapIndex): de las 14.824 misiones de la base, 5.298 (36%) no
-- resolvian NINGUN mapID -- ni por area ni por zone -- lo que significa
-- mapID=0 y el error "ID de mapa no valido" de MoorMap. ZoneMapIndex.lua
-- solo tenia 459 entradas mientras Defaults.lua de MoorMap define 703
-- mapas con nombre (ver el propio archivo, regenerado esta sesion), pero
-- ademas de faltar entradas, muchos area/zone de Compendium traen un
-- sufijo que MoorMap no incluye en el nombre del mapa: entre parentesis
-- (p.ej. area="Furtherholm (Zír Aktar)" vs mapa "Furtherholm") o despues de
-- una coma (p.ej. zone="Adagím, the Moulder-wood" vs mapa "Adagím"). Probar
-- esas variantes recupera 704 misiones mas sin tocar ningun dato. Las que
-- siguen sin resolver son mayormente contenido de instancia/mision sin
-- area/zone en absoluto (no tienen coordenada fija que mapear de todas
-- formas, no es un bug de esta funcion).
-- BUG (escaneo 2026-08-18, continuacion): probar solo el sufijo de parentesis
-- y coma dejaba 1.698 misiones (con area/zone real, no vacio) sin resolver
-- todavia. Comparando ZoneMapIndex contra QuestDB se encontro un tercer
-- patron: Compendium suele anteponer "The " a zonas que el nombre de mapa de
-- MoorMap no lleva (zone="The Entwash Vale" vs mapa "Entwash Vale"). Probar
-- tambien esa variante (sola y combinada con las anteriores) recupera 362
-- misiones mas -- verificado con un script Python antes de tocar este
-- archivo, no adivinado.
local function StripParen(s)
    return (string.gsub(s, "%s*%(.-%)%s*$", ""))
end

local function StripComma(s)
    return string.match(s, "^(.-)%s*,") or s
end

local function StripThe(s)
    return (string.gsub(s, "^the%s+", ""))
end

-- BUG (escaneo 2026-08-18, continuacion): la version anterior solo QUITABA
-- "the " de la clave si ya la tenia -- pero Compendium a veces hace lo
-- contrario, omite el "The" que el mapa de MoorMap SI lleva (zone="Great
-- River" vs mapa "The Great River"). Ademas ninguna variante normalizaba
-- acentos: zone="Urash Dâr" (con circunflejo) nunca coincidia con el mapa
-- "Urash Dar" (sin acento) de MoorMap. Verificado con Python antes de tocar
-- este archivo: agregar el "the " en la direccion inversa + plegado de
-- acentos recupera 306 misiones mas. Solo aparecen 12 caracteres acentuados
-- distintos en toda la base (area/zone + ZoneMapIndex), por eso la tabla de
-- abajo es corta y explicita en vez de un rango Unicode generico.
local function AddThe(s)
    if string.sub(s, 1, 4) == "the " then return s end
    return "the " .. s
end

local ACCENT_FOLD = {
    {"á", "a"}, {"â", "a"}, {"ä", "a"},
    {"é", "e"}, {"ê", "e"},
    {"í", "i"}, {"î", "i"},
    {"ó", "o"}, {"ô", "o"},
    {"ú", "u"}, {"û", "u"}, {"Ú", "u"},
}

local function FoldAccents(s)
    for _, pair in ipairs(ACCENT_FOLD) do
        s = string.gsub(s, pair[1], pair[2])
    end
    return s
end

local function TryZoneKey(key)
    if not key or key == "" or not ZoneMapIndex then return nil end

    local bases = { key, StripParen(key) }
    local candidates = {}
    for _, b in ipairs(bases) do
        table.insert(candidates, b)
        table.insert(candidates, StripComma(b))
    end
    -- cada candidato de arriba, tambien con/sin el prefijo "the "
    local withThe = {}
    for _, c in ipairs(candidates) do
        table.insert(withThe, StripThe(c))
        table.insert(withThe, AddThe(c))
    end
    for _, c in ipairs(withThe) do
        table.insert(candidates, c)
    end
    -- y cada candidato de arriba, tambien con acentos plegados
    local folded = {}
    for _, c in ipairs(candidates) do
        table.insert(folded, FoldAccents(c))
    end
    for _, c in ipairs(folded) do
        table.insert(candidates, c)
    end

    for _, c in ipairs(candidates) do
        if ZoneMapIndex[c] then return ZoneMapIndex[c] end
    end
    return nil
end

-- Resuelve el mapID interno de MoorMap para una mision, a partir de su area
-- (mapa individual, p.ej. "Archet") o su zone (region amplia) como respaldo.
-- Compartido entre QuestSyncWindow y QuestTrackerHUD -- vivia duplicado en
-- ambos archivos; la logica identica en dos sitios es exactamente como
-- sobrevivio tanto tiempo el bug de "misi?n" sin que nadie lo notara.
function MoorMapAdapter.ResolveMapID(quest)
    local areaKey = quest.area and string.lower(quest.area) or nil
    local zoneKey = quest.zone and string.lower(quest.zone) or nil
    local mapID = TryZoneKey(areaKey) or TryZoneKey(zoneKey) or 0
    if LQA.Debug.Enabled then
        Turbine.Shell.WriteLine("<rgb=#FF00FF>QuestSync DEBUG: ResolveMapID area=" .. tostring(areaKey) ..
            " zone=" .. tostring(zoneKey) .. " ZoneMapIndex=" .. tostring(ZoneMapIndex ~= nil) ..
            " -> mapID=" .. tostring(mapID) .. "</rgb>")
    end
    return mapID
end

-- Resuelve la coordenada "por defecto" de una mision: quest.loc (nunca
-- presente en la base actual, pero se respeta si algun dia lo esta),
-- despues el primer lugar del desglose completo (QuestStagesCoords), y por
-- ultimo el indice mas viejo de una sola coordenada (QuestLocCoords).
-- Centralizado aqui porque vivia repetido 5 veces entre QuestSyncWindow.lua
-- (4 veces) y QuestTrackerHUD.lua (1 vez, y esa copia se habia quedado sin
-- el respaldo de QuestStagesCoords cuando se agrego en otra sesion) -- el
-- mismo patron de riesgo por el que sobrevivio tanto el bug de "misi?n".
function MoorMapAdapter.ResolveQuestLoc(ndx, quest)
    if quest.loc then return quest.loc end
    local stages = QuestStagesCoords and QuestStagesCoords[ndx]
    if stages and stages[1] and stages[1].loc then return stages[1].loc end
    if QuestLocCoords then return QuestLocCoords[ndx] end
    return nil
end

function MoorMapAdapter.SetObjectiveMarker(quickslot, mapData)
    MoorMapAdapter.SetQuestMarker(quickslot, mapData)
end

function MoorMapAdapter.ClearMarker(id)
    -- MoorMap ping no define un clear explicito, el ping desaparece con el tiempo o al hacer otro
end
