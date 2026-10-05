-- WorldMap_Addon/worldmap_quests.lua
--
-- v2.1: puente de SOLO LECTURA con LOTRO_Quest_Assistant (pedido del
-- usuario: "Mapa + Quest Assistant"). v2.1.1: solo las misiones ACTIVAS
-- (el usuario no quiere ver completadas ni puntos de recoleccion). Al pasar
-- el mouse por una zona, el cartel dice cuantas misiones activas tienes
-- ahi; con un clic (sin arrastrar) se abre la lista de esas activas, y un
-- clic en una mision la abre en la ventana de Quest Assistant.
--
-- Como se conectan los dos addons: ninguno de los dos declara Apartment en
-- su .plugin, asi que comparten el mismo entorno global de Lua. Este
-- archivo solo LEE las tablas globales que Quest Assistant ya publica
-- (QuestDB.quests, QuestStateManager, QuestLocResolver) y llama a MainWindow:FocusQuest,
-- el MISMO punto de entrada que usa su propio rastreador (QuestTrackerHUD).
-- Nunca escribe nada en Quest Assistant ni guarda nada propio. Si Quest
-- Assistant no esta cargado, todo esto queda apagado en silencio y el mapa
-- funciona exactamente igual que antes.
--
-- Las misiones de la base de Quest Assistant traen la zona en INGLES
-- (quest.zone, p.ej. "The Trollshaws", "Croftlands") y a veces un area mas
-- fina (quest.area). Las tablas de abajo las asignan a las 59 zonas del
-- mapa por su nombre_original. Una zona de la base que no esta en la tabla
-- (eventos, festivales, regiones que el mapa no dibuja) simplemente no se
-- cuenta en ninguna zona -- mejor no contar que contar mal.

_G.WorldMapAddon = _G.WorldMapAddon or {}
WorldMapAddon.Quests = WorldMapAddon.Quests or {}
local Q = WorldMapAddon.Quests

-- ---------------------------------------------------------------------
-- Normalizacion de nombres: minusculas, sin tildes (UTF-8), sin "the "
-- inicial y sin espacios sobrantes. Se aplica a AMBOS lados (base de
-- misiones, MoorMap y las claves de estas tablas).
-- ---------------------------------------------------------------------
local ACCENTS = {
    ["\195\161"] = "a", ["\195\160"] = "a", ["\195\162"] = "a", ["\195\164"] = "a",
    ["\195\169"] = "e", ["\195\168"] = "e", ["\195\170"] = "e", ["\195\171"] = "e",
    ["\195\173"] = "i", ["\195\172"] = "i", ["\195\174"] = "i", ["\195\175"] = "i",
    ["\195\179"] = "o", ["\195\178"] = "o", ["\195\180"] = "o", ["\195\182"] = "o",
    ["\195\186"] = "u", ["\195\185"] = "u", ["\195\187"] = "u", ["\195\188"] = "u",
    ["\195\129"] = "a", ["\195\137"] = "e", ["\195\141"] = "i", ["\195\147"] = "o",
    ["\195\154"] = "u", ["\195\155"] = "u", ["\195\130"] = "a", ["\195\177"] = "n",
}

local function Norm(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    local s = string.lower(text)
    s = s:gsub("\195[\128-\191]", function(ch) return ACCENTS[ch] or ch end)
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    s = s:gsub("^the ", "")
    if s == "" then
        return nil
    end
    return s
end
Q.Norm = Norm

-- zona de la base de misiones (quest.zone) -> nombre_original del mapa
local BY_ZONE = {
    ["bree-land"] = "Bree-land",
    ["shire"] = "The Shire",
    ["ered luin"] = "Ered Luin",
    ["evendim"] = "Evendim",
    ["north downs"] = "North Downs",
    ["lone-lands"] = "Lone-lands",
    ["trollshaws"] = "Trollshaws",
    ["misty mountains"] = "Misty Mountains",
    ["angmar"] = "Angmar",
    ["forochel"] = "Forochel",
    ["cardolan"] = "Cardolan",
    ["eregion"] = "Eregion",
    ["moria"] = "Moria",
    ["lothlorien"] = "Lothlorien",
    ["mirkwood"] = "Mirkwood",
    ["enedwaith"] = "Enedwaith",
    ["dunland"] = "Dunland",
    ["swanfleet"] = "Swanfleet",
    ["great river"] = "Great River",
    ["vales of anduin"] = "Vales of Anduin",
    ["wildermore"] = "Wildermore",
    ["wold"] = "East Rohan",
    ["croftlands"] = "East Rohan",
    ["eastfold"] = "East Rohan",
    ["entwash"] = "East Rohan",
    ["rohan - eastemnet"] = "East Rohan",
    ["westfold"] = "West Rohan",
    ["rohan - westemnet"] = "West Rohan",
    ["western gondor"] = "Western Gondor",
    ["belfalas & dor-en-ernil"] = "Western Gondor",
    ["ringlo vale"] = "Western Gondor",
    ["central gondor"] = "Central Gondor",
    ["lebennin"] = "Central Gondor",
    ["lossarnach"] = "Central Gondor",
    ["eastern gondor"] = "Eastern Gondor",
    ["osgiliath"] = "Eastern Gondor",
    ["king's gondor"] = "King's Gondor",
    ["anfalas"] = "Outer Gondor",
    ["pinnath gelin"] = "Outer Gondor",
    ["anorien"] = "Old Anorien",
    ["old anorien"] = "Old Anorien",
    ["anorien (after battle)"] = "Old Anorien",
    ["far anorien"] = "Far Anorien",
    ["ithilien"] = "North Ithilien",
    ["wastes"] = "The Wastes",
    ["mordor"] = "Plateau of Gorgoroth",
    ["lhingris"] = "Plateau of Gorgoroth",
    ["agarnaith"] = "Plateau of Gorgoroth",
    ["imlad morgul"] = "Morgul Vale",
    ["mordor besieged"] = "Mordor Besieged",
    ["strongholds of the north"] = "Eryn Lasgalen and the Dale-lands",
    ["erebor"] = "Eryn Lasgalen and the Dale-lands",
    ["dwarf-holds"] = "Ered Mithrin and Withered Heath",
    ["gundabad"] = "Gundabad",
    ["elderslade"] = "Elderslade",
    ["wells of langflood"] = "Wells of Langflood",
    ["tales of yore: azanulbizar"] = "Azanulbizar",
    ["ettenmoors"] = "Ettenmoors (PvMP)",
    ["shield isles"] = "The Shield Isles",
    ["umbar"] = "Cape of Umbar",
    ["umbar-mokh"] = "Cape of Umbar",
    ["mur ghala: pahar hatokali"] = "Pahar Hatokali",
    ["mur ghala: kighan"] = "M\195\187r Ghala",
    ["kighan, the shornvale"] = "M\195\187r Ghala",
    ["restoring mur ghala"] = "M\195\187r Ghala",
    ["mur ghala instances"] = "M\195\187r Ghala",
    ["mission: mur ghala"] = "M\195\187r Ghala",
    ["sug nidar, the fearwater"] = "Sug Nidar",
}

-- area (quest.area) que manda sobre la zona, SOLO dentro de esa zona de
-- la base (el campo area trae ruido: p.ej. misiones de Bree con area
-- "Eastfold"), para las regiones que el mapa parte en dos
local BY_ZONE_AREA = {
    ["shire"] = { ["yondershire"] = "The Yondershire" },
    ["bree-land"] = { ["wildwood"] = "The Wildwood" },
    ["trollshaws"] = { ["angle of mitheithel"] = "The Angle of Mitheithel" },
    ["entwash"] = { ["broadacres"] = "West Rohan" },
    ["dunland"] = {
        ["nan curunir"] = "Nan Curunir",
        ["isengard"] = "Nan Curunir",
        ["isengard depths"] = "Nan Curunir",
    },
    ["rohan - westemnet"] = {
        ["nan curunir"] = "Nan Curunir",
        ["isengard"] = "Nan Curunir",
        ["isengard depths"] = "Nan Curunir",
    },
    ["wastes"] = { ["dead marshes"] = "Dead Marshes" },
    ["dwarf-holds"] = {
        ["ironfold"] = "Iron Hills",
        ["jarnfast"] = "Iron Hills",
        ["thikil-gundu, the steel keep"] = "Iron Hills",
    },
}

-- ---------------------------------------------------------------------
-- Acceso a Quest Assistant (todo opcional)
-- ---------------------------------------------------------------------

function Q.Available()
    return type(_G.QuestDB) == "table" and type(_G.QuestDB.quests) == "table"
        and type(_G.QuestStateManager) == "table"
end

-- zona del mapa (nombre_original) de una mision, o nil
function Q.ZoneOfQuest(quest)
    if type(quest) ~= "table" then
        return nil
    end
    local zoneKey = Norm(quest.zone)
    if zoneKey == nil then
        return nil
    end
    local areaKey = Norm(quest.area)
    if areaKey ~= nil then
        local king = areaKey:match("%(king's gondor%)$")
        if king ~= nil then
            return "King's Gondor"
        end
        local overrides = BY_ZONE_AREA[zoneKey]
        if overrides ~= nil and overrides[areaKey] ~= nil then
            return overrides[areaKey]
        end
    end
    return BY_ZONE[zoneKey]
end

-- indice nombre_original -> { ndx, ndx, ... } armado UNA vez (la base no
-- cambia durante la partida; ~15.000 misiones, se recorre una sola vez al
-- primer uso, no al cargar el addon)
function Q.BuildIndex()
    if Q.index ~= nil then
        return Q.index
    end
    if not Q.Available() then
        return nil
    end
    local index = {}
    for ndx, quest in pairs(QuestDB.quests) do
        local zoneName = Q.ZoneOfQuest(quest)
        if zoneName ~= nil then
            local list = index[zoneName]
            if list == nil then
                list = {}
                index[zoneName] = list
            end
            list[#list + 1] = ndx
        end
    end
    Q.index = index
    return index
end

local function QuestState(ndx)
    local ok, state = pcall(QuestStateManager.GetQuestState, ndx)
    if ok then
        return state
    end
    return "AVAILABLE"
end

-- v2.1.1: solo interesan las misiones ACTIVAS (pedido del usuario: sin
-- completadas ni puntos de recoleccion). v2.2: se recorren directamente
-- las activas de QuestStateManager (unas pocas) en vez de las ~15.000
-- misiones de la base -- asi el conteo es barato y se puede refrescar
-- seguido para las marcas doradas del mapa.
-- ---------------------------------------------------------------------
-- v2.9 (pedido del usuario: el juego NO avisa en el chat al abandonar una
-- mision desde el diario, asi que Quest Assistant las sigue creyendo
-- activas): boton "Actualizar" del mapa. Una mision activa que Quest
-- Assistant no vio aceptarse, avanzar ni completarse en STALE_DAYS dias
-- queda "antigua": se ve GRIS en la lista de la zona y NO suma en los
-- medallones. No se borra nada: si vuelve a avanzar, vuelve a su color
-- sola; para sacarla de verdad esta la X de la lista.
-- ---------------------------------------------------------------------
Q.STALE_DAYS = 7
Q.staleOn = Q.staleOn or false

local function IsStale(ndx)
    if Q.staleOn ~= true then
        return false
    end
    local st = QuestStateManager.State
    local a = type(st) == "table" and type(st.active) == "table" and st.active[ndx] or nil
    if type(a) ~= "table" then
        return false
    end
    local lu = tonumber(a.lastUpdate)
    if lu == nil then
        return true -- guardado viejo sin fecha: no se movio desde entonces
    end
    local okT, now = pcall(Turbine.Engine.GetGameTime)
    if not okT or type(now) ~= "number" then
        return false
    end
    return (now - lu) > (Q.STALE_DAYS * 86400)
end
Q.IsStale = IsStale

-- includeStale: true = tambien las antiguas (la lista de la zona las
-- muestra en gris); sin el, solo las que cuentan
local function ActiveNdxList(includeStale)
    local st = QuestStateManager.State
    local list = {}
    if type(st) ~= "table" or type(st.active) ~= "table" then
        return list
    end
    for ndx in pairs(st.active) do
        if QuestState(ndx) == "ACTIVE" and (includeStale == true or not IsStale(ndx)) then
            list[#list + 1] = ndx
        end
    end
    return list
end

-- "Actualizar": prende el modo y devuelve cuantas activas quedaron grises
-- y cuantas siguen al dia
function Q.RefreshStale()
    Q.staleOn = true
    if not Q.Available() then
        return 0, 0
    end
    local stale, fresh = 0, 0
    for _, ndx in ipairs(ActiveNdxList(true)) do
        if IsStale(ndx) then
            stale = stale + 1
        else
            fresh = fresh + 1
        end
    end
    return stale, fresh
end

local function QuestByNdx(ndx)
    return QuestDB.quests[ndx] or QuestDB.quests[tonumber(ndx) or -1]
end

-- { [nombre_original] = cantidad de misiones activas }
function Q.ActiveCounts()
    if not Q.Available() then
        return nil
    end
    local counts = {}
    for _, ndx in ipairs(ActiveNdxList()) do
        local zoneName = Q.ZoneOfQuest(QuestByNdx(ndx))
        if zoneName ~= nil then
            counts[zoneName] = (counts[zoneName] or 0) + 1
        end
    end
    return counts
end

-- v2.4: tipo de grupo de una mision segun Quest Assistant (GroupQuestDB,
-- tamaño oficial del juego): "raid" = incursion (12+), "dungeon" =
-- mazmorra o instancia de grupo (3/6). Escaramuzas, batallas epicas y
-- misiones de grupo en zona abierta no cuentan como mazmorra. nil = no es
-- de grupo o Quest Assistant no tiene el dato.
function Q.GroupKind(quest)
    local GQ = _G.GroupQuest
    if quest == nil or type(GQ) ~= "table" or type(GQ.Get) ~= "function" then
        return nil
    end
    local ok, g = pcall(GQ.Get, quest)
    if not ok or type(g) ~= "table" then
        return nil
    end
    if g.s == "R" then
        return "raid"
    end
    if g.k == "inst" or g.k == "pe" then
        return "dungeon"
    end
    return nil
end

-- v2.7 (pedido del usuario): nombre de la mazmorra / incursion / instancia
-- de una mision de grupo, en español y en ingles, en una linea:
-- "Mazmorra: La Decimosexta Sala (The Sixteenth Hall)". Lo arma Quest
-- Assistant (GroupQuest.PlaceTextBoth, con los nombres reales en español
-- de Data/GroupPlaceES.lua). nil si no es de instancia (zona abierta) o si
-- Quest Assistant no tiene el dato / es una version vieja sin esa funcion.
function Q.InstanceText(quest)
    local GQ = _G.GroupQuest
    if quest == nil or type(GQ) ~= "table" or type(GQ.Get) ~= "function"
        or type(GQ.PlaceTextBoth) ~= "function" then
        return nil
    end
    local ok, g = pcall(GQ.Get, quest)
    if not ok or type(g) ~= "table" then
        return nil
    end
    if type(GQ.IsInstance) == "function" then
        local okI, isInst = pcall(GQ.IsInstance, g)
        if not okI or isInst ~= true then
            return nil
        end
    elseif g.k == "open" then
        return nil
    end
    local okT, text = pcall(GQ.PlaceTextBoth, g)
    if okT and type(text) == "string" and text ~= "" then
        return text
    end
    return nil
end

-- { [nombre_original] = { count = n, dungeon = bool, raid = bool } }
function Q.ActiveInfo()
    if not Q.Available() then
        return nil
    end
    local info = {}
    for _, ndx in ipairs(ActiveNdxList()) do
        local quest = QuestByNdx(ndx)
        local zoneName = Q.ZoneOfQuest(quest)
        if zoneName ~= nil then
            local z = info[zoneName]
            if z == nil then
                z = { count = 0, dungeon = false, raid = false }
                info[zoneName] = z
            end
            z.count = z.count + 1
            local kind = Q.GroupKind(quest)
            if kind == "raid" then
                z.raid = true
            elseif kind == "dungeon" then
                z.dungeon = true
            end
        end
    end
    return info
end

function Q.Stats(zone)
    if zone == nil then
        return nil
    end
    local ok, counts = pcall(Q.ActiveCounts)
    if not ok or counts == nil then
        return nil
    end
    return { active = counts[zone.nombre_original] or 0 }
end

-- texto corto para el cartel de la zona ("" si no hay activas)
function Q.SummaryText(zone)
    local ok, stats = pcall(Q.Stats, zone)
    if not ok or stats == nil then
        return ""
    end
    -- v2.9: antiguas (grises) de la zona, aparte
    local old = 0
    if Q.staleOn == true and zone ~= nil and Q.Available() then
        for _, ndx in ipairs(ActiveNdxList(true)) do
            if IsStale(ndx) and Q.ZoneOfQuest(QuestByNdx(ndx)) == zone.nombre_original then
                old = old + 1
            end
        end
    end
    local text = ""
    if stats.active == 1 then
        text = "1 misi\195\179n activa"
    elseif stats.active > 1 then
        text = stats.active .. " misiones activas"
    end
    if old > 0 then
        local oldText = old == 1 and "1 antigua" or (old .. " antiguas")
        text = text ~= "" and (text .. " (+" .. oldText .. ")") or ("Solo " .. oldText)
    end
    return text
end

-- nombre en español cuando Quest Assistant lo tiene
function Q.QuestName(ndx, quest)
    if _G.QuestLocResolver ~= nil and QuestLocResolver.GetQuestNameES ~= nil then
        local ok, name = pcall(QuestLocResolver.GetQuestNameES, tonumber(ndx) or ndx, quest.nameEN)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return quest.nameEN or ("#" .. tostring(ndx))
end

local function LevelNumber(quest)
    local lvl = tonumber(quest.level)
    if lvl == nil then
        lvl = tonumber(quest.minlevel)
    end
    return lvl or 0
end

function Q.LevelText(quest)
    local lvl = tonumber(quest.level)
    if lvl ~= nil then
        return tostring(lvl)
    end
    if tonumber(quest.minlevel) ~= nil then
        return tostring(quest.minlevel) .. "+"
    end
    return "--"
end

-- filas para la lista: solo las misiones ACTIVAS de la zona, por nivel
function Q.Rows(zone)
    if zone == nil or not Q.Available() then
        return {}
    end
    local rows = {}
    for _, ndx in ipairs(ActiveNdxList(true)) do
        local quest = QuestByNdx(ndx)
        if quest ~= nil and Q.ZoneOfQuest(quest) == zone.nombre_original then
            rows[#rows + 1] = { ndx = ndx, quest = quest, state = "ACTIVE", level = LevelNumber(quest),
                stale = IsStale(ndx) }
        end
    end
    table.sort(rows, function(a, b)
        if a.stale ~= b.stale then
            return not a.stale -- las antiguas (grises) al final
        end
        if a.level ~= b.level then
            return a.level < b.level
        end
        return (tonumber(a.ndx) or 0) < (tonumber(b.ndx) or 0)
    end)
    return rows
end

-- abre la mision en la ventana de Quest Assistant (mismo camino que su
-- propio rastreador: MainWindow:SetVisible + FocusQuest)
function Q.OpenQuest(ndx)
    local win = _G.MainWindow
    if win == nil or win.FocusQuest == nil then
        return false
    end
    Q.HideInfo()
    local ok = pcall(function()
        win:SetVisible(true)
        win:FocusQuest(tonumber(ndx) or ndx)
    end)
    -- v2.8: al frente en el acto (si no, podia quedar detras del mapa o de
    -- la ventana de la zona y parecia que el clic no hacia nada). Aparte,
    -- para que un fallo aca nunca anule lo de arriba.
    if ok then
        pcall(function() win:Activate() end)
    end
    return ok
end

-- ---------------------------------------------------------------------
-- v2.8 (pedido del usuario): ventanita flotante con la info de la mision
-- al pasar el mouse. Es la MISMA ventana de Quest Assistant
-- (QuestInfoTooltip: nivel, zona, grupo, objetivo y barra de progreso),
-- la que ya usan su lista y su rastreador -- asi se ve igual en los dos
-- addons y no se duplica nada. Solo se oculta si la mostro el mapa
-- (Q.infoNdx), para no tocar la que muestre Quest Assistant.
-- ---------------------------------------------------------------------
local INFO_GAP = 20

local function InfoTip()
    local T = _G.QuestInfoTooltip
    if T == nil or type(T.GetInstance) ~= "function" then
        return nil
    end
    local ok, inst = pcall(T.GetInstance)
    if ok and inst ~= nil and inst.ShowFor ~= nil and inst.Hide ~= nil then
        return inst
    end
    return nil
end

function Q.CanShowInfo()
    return Q.Available() and _G.QuestInfoTooltip ~= nil
        and type(_G.QuestInfoTooltip.GetInstance) == "function"
end

-- junto al cursor y siempre dentro de la pantalla (si no entra a la
-- derecha/abajo, pasa al otro lado del cursor, nunca debajo de el)
local function PlaceInfo(inst)
    local mx, my = Turbine.UI.Display.GetMousePosition()
    local w, h = inst:GetSize()
    local sw, sh = Turbine.UI.Display.GetWidth(), Turbine.UI.Display.GetHeight()
    local x, y = mx + INFO_GAP, my + INFO_GAP
    if x + w > sw then
        x = mx - INFO_GAP - w
    end
    if y + h > sh then
        y = my - INFO_GAP - h
    end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    inst:SetPosition(x, y)
end

function Q.ShowInfo(ndx, quest)
    if quest == nil or not Q.CanShowInfo() then
        return false
    end
    local inst = InfoTip()
    if inst == nil then
        return false
    end
    local key = tonumber(ndx) or ndx
    local ok = pcall(function()
        inst:ShowFor(key, quest, Q.QuestName(ndx, quest))
        PlaceInfo(inst)
    end)
    if ok then
        Q.infoNdx = key
    else
        Q.infoNdx = nil
        pcall(function() inst:Hide() end)
    end
    return ok
end

function Q.MoveInfo()
    if Q.infoNdx == nil then
        return
    end
    local inst = InfoTip()
    if inst ~= nil and inst.currentNdx == Q.infoNdx then
        pcall(PlaceInfo, inst)
    end
end

function Q.HideInfo()
    if Q.infoNdx == nil then
        return
    end
    local mine = Q.infoNdx
    Q.infoNdx = nil
    local inst = InfoTip()
    if inst ~= nil and inst.currentNdx == mine then
        pcall(function() inst:Hide() end)
    end
end

-- true si la ventanita que mostro el mapa sigue en pantalla
function Q.InfoShown()
    if Q.infoNdx == nil then
        return false
    end
    local inst = InfoTip()
    if inst == nil or inst.currentNdx ~= Q.infoNdx then
        return false
    end
    local ok, vis = pcall(function() return inst:IsVisible() end)
    return ok and vis == true
end

-- ---------------------------------------------------------------------
-- v2.6: quitar una mision mal detectada (boton X de la ventana de la
-- zona). Mismo camino que el boton "Desmarcar" de Quest Assistant:
-- QuestStateManager.ResetQuest -- deja de estar activa en todo el sistema
-- (mapa, rastreador, libro). Devuelve true si se pudo.
-- ---------------------------------------------------------------------
function Q.Unmark(ndx)
    if not Q.Available() or type(QuestStateManager.ResetQuest) ~= "function" then
        return false
    end
    local ok = pcall(QuestStateManager.ResetQuest, tonumber(ndx) or ndx)
    return ok
end

-- ---------------------------------------------------------------------
-- v2.6: buscador de misiones del mapa. Busca en TODAS las misiones de la
-- base (nombre en español y en ingles, sin tildes ni mayusculas); las
-- ACTIVAS van primero, despues por nivel. Devuelve hasta "max" filas
-- { ndx, quest, name, zone (nombre_original del mapa o nil), active }
-- y el total de coincidencias.
-- ---------------------------------------------------------------------
local NAME_INDEX = nil

local function BuildNameIndex()
    NAME_INDEX = {}
    for ndx, quest in pairs(QuestDB.quests) do
        local es = Q.QuestName(ndx, quest)
        NAME_INDEX[#NAME_INDEX + 1] = {
            ndx = ndx,
            es = Norm(es) or "",
            en = Norm(quest.nameEN) or "",
            name = es,
        }
    end
end

function Q.Search(text, max)
    if not Q.Available() then
        return {}, 0
    end
    local needle = Norm(text)
    if needle == nil or #needle < 3 then
        return {}, 0
    end
    if NAME_INDEX == nil then
        BuildNameIndex()
    end
    local st = QuestStateManager.State
    local active = (type(st) == "table" and type(st.active) == "table") and st.active or {}
    local found = {}
    for _, e in ipairs(NAME_INDEX) do
        if string.find(e.es, needle, 1, true) or string.find(e.en, needle, 1, true) then
            local quest = QuestByNdx(e.ndx)
            if quest ~= nil then
                found[#found + 1] = {
                    ndx = e.ndx, quest = quest, name = e.name,
                    zone = Q.ZoneOfQuest(quest),
                    active = active[e.ndx] ~= nil and QuestState(e.ndx) == "ACTIVE" and not IsStale(e.ndx),
                    level = LevelNumber(quest),
                    exact = (e.es == needle or e.en == needle),
                }
            end
        end
    end
    table.sort(found, function(a, b)
        if a.active ~= b.active then return a.active end
        if a.exact ~= b.exact then return a.exact end
        if (a.zone ~= nil) ~= (b.zone ~= nil) then return a.zone ~= nil end
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)
    local total = #found
    local limit = max or 40
    local out = {}
    for i = 1, math.min(total, limit) do
        out[i] = found[i]
    end
    return out, total
end

-- ---------------------------------------------------------------------
-- v3.0 (pedido del usuario): nombres de las mazmorras / incursiones de las
-- misiones ACTIVAS de una zona, para la ventanita que sale al pasar el
-- mouse sobre la puerta (mazmorra) o la calavera (incursion). Cada linea
-- ya viene en español y en ingles (Q.InstanceText, de Quest Assistant).
-- kind = "dungeon" o "raid". Lista sin repetidos (varias misiones de la
-- misma mazmorra = una sola linea).
-- ---------------------------------------------------------------------
function Q.InstanceList(zoneName, kind)
    local out = {}
    if not Q.Available() or zoneName == nil then
        return out
    end
    local seen = {}
    for _, ndx in ipairs(ActiveNdxList()) do
        local quest = QuestByNdx(ndx)
        if quest ~= nil and Q.ZoneOfQuest(quest) == zoneName and Q.GroupKind(quest) == kind then
            local text = Q.InstanceText(quest)
            if text == nil then
                -- de grupo pero sin lugar conocido: el nombre de la mision
                text = Q.QuestName(ndx, quest)
                if quest.nameEN ~= nil and quest.nameEN ~= text then
                    text = text .. " (" .. tostring(quest.nameEN) .. ")"
                end
            end
            if type(text) == "string" and text ~= "" and not seen[text] then
                seen[text] = true
                out[#out + 1] = text
            end
        end
    end
    table.sort(out)
    return out
end

-- ---------------------------------------------------------------------
-- v3.0 (pedido del usuario: "el personaje ... que aparezca en la zona en
-- la que estamos ... se puede detectar a medida que hagamos misiones"):
-- zona del mapa donde esta el jugador. La API de LOTRO no da la posicion,
-- asi que se usa lo que Quest Assistant ya sabe, gana lo MAS RECIENTE:
--   * el canal Regional (al entrar a una region el juego avisa "Entraste
--     en el canal ... - Regional"; Quest Assistant lo guarda en
--     QuestEventParser.GetCurrentZone);
--   * la zona de la mision que se acepta, avanza o completa (avisos
--     QUEST_JUST_ACCEPTED / QUEST_PROGRESS / QUEST_JUST_COMPLETED);
--   * al arrancar: la zona que el Rastreador guardo (State.zone) o la
--     ultima guardada por el mapa.
-- Solo LEE: los avisos solo anotan la zona (nunca pueden fallar ni frenar
-- a Quest Assistant). Si Quest Assistant no esta, Q.PlayerZone() es nil y
-- el mapa no muestra el personaje.
-- ---------------------------------------------------------------------
Q.player = Q.player or { zone = nil, regional = false, hooked = false, tries = 0 }

-- zona de la base (quest.zone, el canal Regional) -> nombre_original
function Q.MapZoneFromDb(dbZone)
    local key = Norm(dbZone)
    if key == nil then
        return nil
    end
    return BY_ZONE[key]
end

local PLAYER_EVENTS = { "QUEST_JUST_ACCEPTED", "QUEST_PROGRESS", "QUEST_JUST_COMPLETED" }

local function NoteQuestZone(data)
    pcall(function()
        if type(data) ~= "table" or data.ndx == nil or not Q.Available() then
            return
        end
        local zn = Q.ZoneOfQuest(QuestByNdx(data.ndx))
        if zn ~= nil then
            Q.player.zone = zn
        end
    end)
end

local function HookPlayerEvents()
    if Q.player.hooked == true then
        return true
    end
    local LQA = _G.LQA
    local bus = LQA ~= nil and LQA.Core ~= nil and LQA.Core.EventBus or nil
    if bus == nil or type(bus.Subscribe) ~= "function" then
        return false
    end
    Q.player.hooked = true
    for _, name in ipairs(PLAYER_EVENTS) do
        pcall(bus.Subscribe, bus, name, NoteQuestZone)
    end
    return true
end

-- canal Regional: solo cuando CAMBIA (asi no pisa a una mision mas nueva)
local function PollRegional()
    local QEP = _G.QuestEventParser
    if type(QEP) ~= "table" or type(QEP.GetCurrentZone) ~= "function" then
        return
    end
    local ok, z = pcall(QEP.GetCurrentZone)
    if not ok or type(z) ~= "string" or z == "" or z == Q.player.regional then
        return
    end
    Q.player.regional = z
    local zn = Q.MapZoneFromDb(z)
    if zn ~= nil then
        Q.player.zone = zn
    end
end

-- primera zona al arrancar (solo si todavia no se sabe ninguna)
local function StartPlayerZone()
    if Q.player.zone ~= nil or not Q.Available() then
        return
    end
    local st = QuestStateManager.State
    if type(st) == "table" and type(st.zone) == "string" then
        Q.player.zone = Q.MapZoneFromDb(st.zone)
    end
end

-- el mapa le pasa la zona que guardo la ultima vez (por personaje)
function Q.SetSavedPlayerZone(zoneName)
    if Q.player.zone == nil and type(zoneName) == "string" and zoneName ~= "" then
        Q.player.zone = zoneName
    end
end

function Q.PlayerZone()
    return Q.player.zone
end

-- vigia liviano: una vez por segundo mira el canal Regional y se engancha
-- a los avisos de Quest Assistant apenas este cargado (no importa cual de
-- los dos addons cargo primero). Un error lo apaga sin repetirse.
function Q.StartPlayerTracking()
    if Q.player.watch ~= nil then
        return
    end
    -- Control sin padre con Update: mismo temporizador que Main.lua de
    -- Quest Assistant (diagInitTimer / gatherInitTimer), ya probado en vivo
    local w = Turbine.UI.Control()
    Q.player.watch = w
    local nextAt = 0
    w.Update = function()
        local okT, now = pcall(Turbine.Engine.GetGameTime)
        if not okT or type(now) ~= "number" or now < nextAt then
            return
        end
        nextAt = now + 1
        local ok = pcall(function()
            if HookPlayerEvents() then
                StartPlayerZone()
            end
            PollRegional()
        end)
        if not ok then
            w:SetWantsUpdates(false)
        end
    end
    w:SetWantsUpdates(true)
end

pcall(Q.StartPlayerTracking)

-- ---------------------------------------------------------------------
-- v3.1 (pedido del usuario): en el MAPA DE LA ZONA, al pasar el mouse por
-- una mazmorra o incursion, las misiones ACTIVAS que tenemos en ESE lugar.
-- El lugar de cada mision es el de Quest Assistant (GroupQuestDB, nombre en
-- ingles, ej. "Helegrod: Giant Wing"); names = nombres en ingles del icono
-- (ej. { "Helegrod" }). Coincide si es el mismo nombre, o si uno es el
-- comienzo del otro hasta una palabra entera ("Helegrod" con "Helegrod:
-- Giant Wing", "Fornost" con "Fornost: Wraith of Shadow"). Igual que las
-- marcas del mapa del mundo, no cuentan las misiones "antiguas" (gris).
-- Devuelve { { es = nombre, en = nombreEN, ndx = ndx }, ... } por nombre.
-- ---------------------------------------------------------------------
local function PlaceKey(text)
    local s = Norm(text)
    if s == nil then
        return nil
    end
    s = s:gsub("[^%w%s]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("^the ", "")
    if s == "" then
        return nil
    end
    return s
end
Q.PlaceKey = PlaceKey

local function PlaceMatches(a, b)
    if a == nil or b == nil then
        return false
    end
    if a == b then
        return true
    end
    if #a > #b then
        a, b = b, a
    end
    if b:sub(1, #a + 1) == (a .. " ") then
        return true
    end
    -- v3.1.2: el nombre corto aparece entero (palabras completas) dentro del
    -- largo: "Dol Guldur" con "Dungeons of Dol Guldur", "Isengard" con "Pits
    -- of Isengard". Minimo 6 letras para no confundir nombres cortos.
    if #a >= 6 then
        local padded = " " .. b .. " "
        return padded:find(" " .. a .. " ", 1, true) ~= nil
    end
    return false
end
Q.PlaceMatches = PlaceMatches

-- v3.1.3 (reporte del jugador, Moria: "Profanadores Sombrios", "Cristales
-- agotados", "Reliquias y monedas" y "Skum y Urauth" se hacen DENTRO del
-- Tesoro Olvidado, pero el icono decia "Sin misiones activas aqui"). Quest
-- Assistant las tiene como misiones de comunidad de ZONA ABIERTA (k="open",
-- lugar "Silvertine Lodes, Moria"), asi que el nombre del lugar nunca
-- coincidia. Ahora una mision de grupo tambien cuenta si el texto de sus
-- objetivos nombra la mazmorra / incursion ("...dentro del Tesoro
-- Olvidado..."). Solo nombres de 6+ letras y palabras enteras, para no
-- confundir lugares cortos.
local ES_ARTICLES = { "el ", "la ", "los ", "las " }
local function TextPlaceKey(text)
    local k = PlaceKey(text)
    if k == nil then
        return nil
    end
    for _, a in ipairs(ES_ARTICLES) do
        if k:sub(1, #a) == a then
            k = k:sub(#a + 1)
            break
        end
    end
    if #k < 6 then
        return nil
    end
    return k
end

local questTextCache = {}
local function QuestTextKey(ndx)
    local c = questTextCache[ndx]
    if c ~= nil then
        return c
    end
    local parts = {}
    local L = _G.QuestLocES
    local loc = type(L) == "table" and (L[ndx] or L[tonumber(ndx) or -1]) or nil
    if type(loc) == "table" and type(loc.objectivesES) == "table" then
        for _, t in ipairs(loc.objectivesES) do
            if type(t) == "string" then
                parts[#parts + 1] = t
            end
        end
    end
    c = " " .. (PlaceKey(table.concat(parts, " ")) or "") .. " "
    questTextCache[ndx] = c
    return c
end

-- names = nombres en ingles del icono; namesES (opcional) = en español
function Q.InstanceQuests(names, namesES)
    local out = {}
    if type(names) ~= "table" or not Q.Available() then
        return out
    end
    local GQ = _G.GroupQuest
    if type(GQ) ~= "table" or type(GQ.Get) ~= "function" then
        return out
    end
    local keys = {}
    local textKeys = {}
    for _, n in ipairs(names) do
        local k = PlaceKey(n)
        if k ~= nil then
            keys[#keys + 1] = k
        end
        local tk = TextPlaceKey(n)
        if tk ~= nil then
            textKeys[#textKeys + 1] = tk
        end
    end
    if type(namesES) == "table" then
        for _, n in ipairs(namesES) do
            local tk = TextPlaceKey(n)
            if tk ~= nil then
                textKeys[#textKeys + 1] = tk
            end
        end
    end
    if #keys == 0 and #textKeys == 0 then
        return out
    end
    for _, ndx in ipairs(ActiveNdxList()) do
        local quest = QuestByNdx(ndx)
        if quest ~= nil then
            local ok, g = pcall(GQ.Get, quest)
            if ok and type(g) == "table" then
                local hit = false
                if g.k ~= "open" and type(g.p) == "string" then
                    local pk = PlaceKey(g.p)
                    for _, k in ipairs(keys) do
                        if PlaceMatches(pk, k) then
                            hit = true
                            break
                        end
                    end
                end
                if not hit and #textKeys > 0 then
                    local okT, text = pcall(QuestTextKey, ndx)
                    if okT and type(text) == "string" then
                        for _, tk in ipairs(textKeys) do
                            if text:find(" " .. tk .. " ", 1, true) ~= nil then
                                hit = true
                                break
                            end
                        end
                    end
                end
                if hit then
                    out[#out + 1] = {
                        es = Q.QuestName(ndx, quest),
                        en = tostring(quest.nameEN or Q.QuestName(ndx, quest)),
                        ndx = ndx,
                    }
                end
            end
        end
    end
    table.sort(out, function(x, y) return x.es < y.es end)
    return out
end
