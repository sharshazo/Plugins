-- LOTRO_Quest_Assistant/Core/GroupQuest.lua
--
-- Misiones de GRUPO (mazmorras, incursiones/raids, instancias de grupo,
-- escaramuzas y misiones de grupo en zona abierta) -- pedido explicito del
-- usuario (2026-09-22): "que la mision sea de otro color especifico para
-- todas estas cosas de grupo y que en el mismo enunciado aparezca un logo
-- de grupo y mencione que mazmorra o dungeon o raid hay que ir".
--
-- Punto UNICO de consulta para las 4 ventanas que lo usan (QuestSyncWindow,
-- QuestTrackerHUD, QuestBookWindow, QuestInfoTooltip) -- asi el color, el
-- icono y los textos quedan iguales en todas, y cambiar el color de grupo
-- es tocar UNA sola linea (GroupQuest.Color de mas abajo).
--
-- El dato real vive en Data/GroupQuestDB.lua (generado, ver la nota grande
-- de ese archivo: tamaño oficial de grupo del juego via LotroCompanion,
-- cruzado por el id real de cada mision). Este archivo NO inventa nada: si
-- una mision no esta en GroupQuestDB, simplemente no es de grupo y todo el
-- resto del addon se comporta exactamente como antes.
--
-- Defensivo a proposito: si GroupQuestDB no llegara a cargar por cualquier
-- motivo, Get() devuelve nil y ninguna ventana cambia (nunca un error de
-- Lua por un campo nil).
import "Turbine"
import "Turbine.UI"

_G.GroupQuest = _G.GroupQuest or {}
local GroupQuest = _G.GroupQuest

GroupQuest.ICON_16 = "LOTRO_Quest_Assistant/Resources/Book/group_icon_16.tga"
GroupQuest.ICON_24 = "LOTRO_Quest_Assistant/Resources/Book/group_icon_24.tga"

-- Color de grupo: naranja fuego -- la MISMA familia de color que el
-- Tracker ya usaba para "grupo" (QuestTrackerHUD.lua, ClassifyQuest V6),
-- solo que mas saturado para que se distinga de verdad. Dos variantes:
--   * Dark: texto sobre fondo OSCURO (columna izquierda de QuestSyncWindow,
--     siempre negra -- se usa con contorno negro, ver ApplyReadableStyle).
--   * Ink: texto sobre PERGAMINO claro (Tracker, detalle, libro de mision)
--     -- mas oscuro para tener contraste contra el papel.
GroupQuest.Color = {
    Dark = Turbine.UI.Color(255 / 255, 138 / 255, 40 / 255),
    Ink = Turbine.UI.Color(176 / 255, 72 / 255, 0 / 255),
}

local SIZE_LABEL = {
    ES = { S = "Grupo pequeño (3)", F = "Comunidad (6)", R = "Incursión (12+)" },
    EN = { S = "Small Fellowship (3)", F = "Fellowship (6)", R = "Raid (12+)" },
}

local HEADER = { ES = "MISIÓN DE GRUPO", EN = "GROUP QUEST" }

-- Tipo de lugar. "inst" depende del tamaño: RAID -> Incursion, el resto ->
-- Mazmorra (es lo que el jugador busca en el Buscador de Instancias).
local KIND_LABEL = {
    ES = { raid = "Incursión", inst = "Mazmorra", pe = "Instancia", skirm = "Escaramuza",
           epic = "Batalla épica", open = "Zona abierta" },
    EN = { raid = "Raid", inst = "Dungeon", pe = "Instance", skirm = "Skirmish",
           epic = "Epic Battle", open = "Open world" },
}

-- Texto cuando no hay un nombre de lugar real conocido (solo pasa con
-- escaramuzas de la categoria generica "Skirmish").
local NO_PLACE = { ES = "Buscador de Instancias", EN = "Instance Finder" }

local function Lang()
    if _G.LanguageSettings and LanguageSettings.IsSpanish and LanguageSettings.IsSpanish() then
        return "ES"
    end
    if _G.LanguageSettings and LanguageSettings.IsSpanish then
        return "EN"
    end
    return "ES"
end

-- Devuelve la entrada cruda de GroupQuestDB ({s,k,p}) o nil. Acepta el
-- quest (tabla de QuestDB) directamente, o un ndx.
function GroupQuest.Get(questOrNdx)
    if not _G.GroupQuestDB then return nil end
    local quest = questOrNdx
    if type(questOrNdx) == "number" then
        quest = _G.QuestDB and QuestDB.quests and QuestDB.quests[questOrNdx]
    end
    if type(quest) ~= "table" or not quest.id then return nil end
    return _G.GroupQuestDB[quest.id]
end

function GroupQuest.IsGroup(questOrNdx)
    return GroupQuest.Get(questOrNdx) ~= nil
end

-- "Comunidad (6)" / "Fellowship (6)"
function GroupQuest.SizeText(entry)
    if not entry then return "" end
    return SIZE_LABEL[Lang()][entry.s] or ""
end

-- "Mazmorra: The Sixteenth Hall" / "Incursión: Helegrod" /
-- "Zona abierta: Redhorn Lodes, Moria"
-- Nombre del lugar en los DOS idiomas (2026-09-27, pedido del usuario:
-- "el nombre de esta mazmorra o dungeon o raid en español y en ingles").
-- Solo para instancias (mazmorra, incursion, instancia privada,
-- escaramuza, batalla epica); en zona abierta el lugar es un area del mapa
-- y queda como antes. Devuelve principal, secundario: con el addon en
-- español, principal = español y secundario = ingles; en ingles, al reves.
-- secundario = nil si no hay nombre en español (Data/GroupPlaceES.lua) o
-- si es igual en los dos idiomas (ej. "Helegrod").
local SECOND_LABEL = { ES = "En inglés: ", EN = "In Spanish: " }

function GroupQuest.PlaceNames(entry)
    if not entry then return nil, nil end
    local en = entry.p
    if not en or en == "" then return nil, nil end
    if entry.k == "open" then return en, nil end
    local es = _G.GroupPlaceES and GroupPlaceES[en] or nil
    if not es or es == "" or es == en then return en, nil end
    if Lang() == "ES" then return es, en end
    return en, es
end

function GroupQuest.PlaceText(entry)
    if not entry then return "" end
    local lang = Lang()
    local kindKey = entry.k
    if kindKey == "inst" and entry.s == "R" then kindKey = "raid" end
    local kind = KIND_LABEL[lang][kindKey] or KIND_LABEL[lang].inst
    local place = GroupQuest.PlaceNames(entry)
    if not place or place == "" then place = NO_PLACE[lang] end
    return kind .. ": " .. place
end

-- Una sola linea con los dos nombres: "Mazmorra: La Decimosexta Sala (The
-- Sixteenth Hall)". Para listas angostas (Mapa del Mundo).
function GroupQuest.PlaceTextBoth(entry)
    if not entry then return "" end
    local text = GroupQuest.PlaceText(entry)
    local _, second = GroupQuest.PlaceNames(entry)
    if second then text = text .. " (" .. second .. ")" end
    return text
end

-- Mision de instancia (mazmorra, incursion, instancia privada, escaramuza,
-- batalla epica) con lugar conocido -- no zona abierta.
-- Cuantas lineas ocupa un texto multilinea en un ancho dado (estimado:
-- charPx = ancho promedio de una letra de la fuente). Lo usan los paneles
-- de alto fijo para no cortar el nombre largo de una mazmorra.
function GroupQuest.EstimateLines(text, widthPx, charPx)
    local perLine = math.max(1, math.floor((widthPx or 1) / (charPx or 7)))
    local lines = 0
    for line in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        local n = 0
        for _ in line:gmatch("[^\128-\191]") do n = n + 1 end
        lines = lines + math.max(1, math.ceil(n / perLine))
    end
    return lines
end

function GroupQuest.IsInstance(entry)
    return type(entry) == "table" and entry.k ~= "open" and entry.p ~= nil and entry.p ~= ""
end

-- Enunciado completo en 2 lineas, para los paneles con lugar de sobra:
--   MISIÓN DE GRUPO · Comunidad (6)
--   Mazmorra: The Sixteenth Hall
function GroupQuest.Statement(entry)
    if not entry then return "" end
    local text = HEADER[Lang()] .. " · " .. GroupQuest.SizeText(entry) .. "\n" .. GroupQuest.PlaceText(entry)
    -- 3a linea (2026-09-27): el nombre en el otro idioma, si es distinto
    local _, second = GroupQuest.PlaceNames(entry)
    if second then text = text .. "\n" .. SECOND_LABEL[Lang()] .. second end
    return text
end

-- Una sola linea, para el tooltip.
function GroupQuest.OneLine(entry)
    if not entry then return "" end
    return "[" .. GroupQuest.SizeText(entry) .. "] " .. GroupQuest.PlaceText(entry)
end

-- ---------------------------------------------------------------------
-- Boton "Buscar grupo" (2026-09-22, pedido explicito del usuario: "un
-- boton que no rompa la estructura del juego y la visual, para que mande
-- el mensaje automatico en ingles, un mensaje sencillo, y que al apretar
-- este boton lo dispare en el chat de mundo").
--
-- Un addon de LOTRO NO puede escribir en el chat por codigo. Se usa el
-- MISMO truco ya probado de MoorMap/Waypoint (ver ESTRUCTURA_DEL_CODIGO.md
-- §6.1): un Quickslot invisible detras de un boton nativo, cargado con un
-- Shortcut de tipo Alias con el comando de chat completo. El mensaje sale
-- SOLO cuando el jugador hace click en el boton -- nunca automatico.
--
-- Canal: /world (chat de mundo, lo que pidio el usuario). Existe como canal
-- global oficial desde la Update 19.3 junto con /trade y /lff -- las notas
-- oficiales piden usar /lff para buscar grupo; si se prefiere ese canal,
-- cambiar SOLO esta linea a "/lff".
GroupQuest.LFF_CHANNEL = "/world"

local SIZE_EN = { S = "Small Fellowship, 3", F = "Fellowship, 6", R = "Raid, 12+" }
local KIND_EN = { raid = "Raid", inst = "Dungeon", pe = "Instance", skirm = "Skirmish",
                  epic = "Epic Battle", open = "Open world" }

-- El parser de comandos de barra del cliente NO es UTF-8-seguro (bug real
-- ya documentado en MoorMapAdapter.SetQuestMarker: "Capítulo" llegaba como
-- "Cap?tulo"). Los nombres oficiales en ingles traen letras como û/â/í/ó
-- (Skûmfil, Nûrz Ghâshu, Tham Mírdain) -- se pliegan a ASCII antes de
-- meterlas en el comando. Tabla completa del bloque Latin-1 (UTF-8
-- 0xC3 0x80-0xBF); cualquier otro caracter no-ASCII se descarta.
local LATIN1 = {
    "A","A","A","A","A","A","AE","C","E","E","E","E","I","I","I","I",
    "D","N","O","O","O","O","O","x","O","U","U","U","U","Y","Th","ss",
    "a","a","a","a","a","a","ae","c","e","e","e","e","i","i","i","i",
    "d","n","o","o","o","o","o","","o","u","u","u","u","y","th","y",
}
function GroupQuest.FoldAscii(s)
    s = tostring(s or "")
    s = string.gsub(s, "\195([\128-\191])", function(b)
        return LATIN1[string.byte(b) - 127] or ""
    end)
    s = string.gsub(s, "[\128-\255]", "")
    return s
end

-- Comando de chat completo, en ingles, corto y simple. Ejemplos:
--   /world LFF Skumfil (Fellowship, 6) - Quest: A Fellowship's Heart
--   /world LFF Helegrod (Raid, 12+) - Quest: The Dragon's Hoard
--   /world LFF Gramsfoot, The Ettenmoors (Raid, 12+) - Quest: ...
-- Devuelve nil si la mision no es de grupo.
function GroupQuest.LffCommand(quest)
    local entry = GroupQuest.Get(quest)
    if not entry then return nil end
    local kindKey = entry.k
    if kindKey == "inst" and entry.s == "R" then kindKey = "raid" end
    local place = entry.p
    if not place or place == "" then place = KIND_EN[kindKey] or "group" end
    local msg = "LFF " .. place .. " (" .. (SIZE_EN[entry.s] or "group") .. ")"
    if quest.nameEN and quest.nameEN ~= "" then
        msg = msg .. " - Quest: " .. quest.nameEN
    end
    msg = GroupQuest.FoldAscii(msg)
    -- Tope de largo por las dudas (el chat de LOTRO corta mensajes largos).
    if #msg > 200 then msg = string.sub(msg, 1, 200) end
    return GroupQuest.LFF_CHANNEL .. " " .. msg
end
