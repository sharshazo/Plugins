-- LOTRO_Quest_Assistant/Core/QuestLocResolver.lua
import "Turbine"

_G.QuestLocResolver = {}

function QuestLocResolver.GetQuestNameES(ndx_or_nameEN, fallbackEN)
    local ndx = nil
    if type(ndx_or_nameEN) == "number" then
        ndx = ndx_or_nameEN
    elseif type(ndx_or_nameEN) == "string" then
        ndx = QuestNameIndex and QuestNameIndex[string.lower(ndx_or_nameEN)]
    end
    
    if ndx and QuestLocES and QuestLocES[ndx] then
        local entry = QuestLocES[ndx]
        if type(entry) == "table" and entry.nameES then
            return entry.nameES
        elseif type(entry) == "string" then
            return entry
        end
    end
    return fallbackEN
end

-- BUG (encontrado en escaneo 2026-08-18): la version anterior usaba una
-- character class "[ÁÉÍÓÚÑÜ]" para elegir que reemplazar. En UTF-8 cada
-- letra ocupa 2 bytes, y una character class en Lua compara byte a byte,
-- no caracter a caracter -- así que en la práctica esa clase nunca
-- encontraba las secuencias completas y el gsub no reemplazaba nada.
-- Ademas string.lower() de Lua es solo-ASCII y deja intactas las
-- mayusculas acentuadas. Resultado: cualquier texto de chat con una
-- mayuscula acentuada (frecuente al inicio de una oracion en español,
-- p.ej. "Único", "Área") nunca coincidia con las claves en minuscula de
-- QuestNameESIndex/QuestObjectiveESIndex (esas si estan bien minusculizadas,
-- se generaron con Python). Aqui se reemplaza cada secuencia de 2 bytes
-- completa de forma literal, no por clase de caracteres.
-- Movida a nivel de modulo (2026-08-20, antes vivia solo dentro de
-- FindQuestByAnyName) y expuesta como QuestLocResolver.NormalizeES para que
-- el buscador de QuestSyncWindow.lua use la MISMA normalizacion en vez de
-- duplicar esta logica -- justo el patron de "la misma logica repetida en 2
-- lugares" que ya causo el bug de "misi?n" y el de mapID=0 antes.
-- (2026-09-25) Tabla fuera de la funcion y reemplazos solo si el texto
-- tiene alguna letra acentuada (todas empiezan con el byte 195): mismo
-- resultado exacto, pero mucho mas rapido -- ahora se usa tambien para armar
-- el indice de nombres de FindQuestByName (30.000 nombres de una vez).
local accentPairs = {
    {"\195\129", "\195\161"}, -- Á -> á
    {"\195\137", "\195\169"}, -- É -> é
    {"\195\141", "\195\173"}, -- Í -> í
    {"\195\147", "\195\179"}, -- Ó -> ó
    {"\195\154", "\195\186"}, -- Ú -> ú
    {"\195\145", "\195\177"}, -- Ñ -> ñ
    {"\195\156", "\195\188"}, -- Ü -> ü
}
local function toLowerES(s)
    local lower_s = string.lower(s)
    if string.find(lower_s, "\195", 1, true) then
        for _, pair in ipairs(accentPairs) do
            lower_s = string.gsub(lower_s, pair[1], pair[2])
        end
    end
    lower_s = string.gsub(lower_s, "%s+", " ")
    lower_s = string.gsub(lower_s, "^%s*(.-)%s*$", "%1")
    return lower_s
end

function QuestLocResolver.NormalizeES(s)
    if not s or s == "" then return "" end
    return toLowerES(s)
end

-- (2026-09-27) Quita las marcas de color "<rgb=#...>" y "</rgb>". 2.469
-- misiones (casi todo el contenido mas nuevo) traen el verbo del objetivo
-- coloreado ("<rgb=#ff0000>Derrota</rgb> a ..."), y el juego manda ese
-- mismo texto al chat. Sin marcas no cambia nada.
function QuestLocResolver.StripRGB(s)
    if type(s) ~= "string" or not string.find(s, "<", 1, true) then return s end
    s = string.gsub(s, "<[rR][gG][bB]=[^>]*>", "")
    s = string.gsub(s, "</[rR][gG][bB]>", "")
    return s
end

-- Filtro de texto de dialogo/exclamacion de PNJ vs. objetivo real, extraido
-- de UI/QuestInfoTooltip.lua (2026-08-28) para que QuestBookWindow.lua use
-- el MISMO filtro en vez de duplicarlo -- ver la nota grande junto a
-- MoorMapAdapter.ResolveMapID sobre por que "la misma logica repetida en 2
-- lugares" ya causo bugs reales en este addon. Logica sin cambios: se
-- descarta cualquier entrada vacia, con placeholder "${...}" sin resolver,
-- igual al nombre de la mision, o que empiece con comilla/exclamacion/
-- interrogacion (marcas de dialogo citado). string.sub() opera por BYTES
-- -- "¡"/"¿" ocupan 2 bytes en UTF-8, por eso se comparan los primeros 2
-- bytes contra esos literales, no 1 caracter.
local function isCleanText(s)
    return s ~= nil and s ~= "" and not string.find(s, "${", 1, true)
end

function QuestLocResolver.IsFlavorText(s, nameEN)
    if not isCleanText(s) then return true end
    if s == nameEN then return true end
    local first1 = string.sub(s, 1, 1)
    local first2 = string.sub(s, 1, 2)
    if first1 == "'" or first1 == '"' then return true end
    if first2 == "¡" or first2 == "¿" then return true end
    return false
end

-- Hasta maxLines entradas LIMPIAS de QuestLocES[ndx].objectivesES (sin
-- dialogo/exclamacion de PNJ, ver IsFlavorText), en el orden en que
-- aparezcan -- nunca inventa texto, solo filtra mejor lo que LOTRO
-- Companion ya extrajo. Devuelve {} (nunca nil) si no hay nada limpio.
function QuestLocResolver.GetCleanObjectiveLines(ndx, quest, maxLines)
    local lines = {}
    local loc = _G.QuestLocES and _G.QuestLocES[ndx]
    local obj = loc and type(loc) == "table" and loc.objectivesES
    if obj and type(obj) == "table" then
        for i = 1, #obj do
            if not QuestLocResolver.IsFlavorText(obj[i], quest and quest.nameEN) then
                table.insert(lines, obj[i])
                if #lines >= (maxLines or 2) then break end
            end
        end
    end
    return lines
end

-- Desambiguacion comun (2026-09-25): extraida SIN CAMBIOS de
-- FindQuestByAnyName para que FindQuestByName (mas abajo) use exactamente
-- la misma logica en vez de duplicarla.
local function Disambiguate(candidates, resType)
    if #candidates == 1 then
        if LQA.Debug.Enabled then
            Turbine.Shell.WriteLine("<rgb=#FFFF00>QuestSync DEBUG: Runtime QuestID = " .. tostring(candidates[1]) .. "</rgb>")
        end
        return "SUCCESS", candidates[1], resType
    end

    -- BUG (escaneo 2026-08-18, fiabilidad de activacion en tiempo real):
    -- 552 nombres y 69 textos de objetivo de la base los comparten 2+
    -- misiones (verificado con un script Python contra los indices
    -- reales). La desambiguacion por cadena "prev" de abajo solo puede
    -- resolver un grupo si AL MENOS una candidata tiene datos de prev -- 218
    -- de los 552 grupos de nombre y 48 de los 69 de objetivo no tienen
    -- ningun candidato con prev, asi que nunca se resolvian por chat en
    -- absoluto (quedaban en AMBIGUA para siempre, sin importar el progreso
    -- del jugador) -- el sintoma exacto de "esta mision nunca se activa
    -- sola" que reporto el usuario. Se agrega una señal MEJOR y disponible
    -- antes que la cadena de prev: si el jugador YA tiene exactamente una
    -- de las candidatas marcada ACTIVA en nuestro propio registro (p.ej. un
    -- contador de progreso "(N/M)" que coincide con el objetivo compartido
    -- de una mision que ya esta activa), esa es casi con certeza la
    -- correcta -- es mas confiable que inferir por cadena, porque no es una
    -- suposicion: es el estado real que el jugador ya confirmo al aceptarla.
    --
    -- IMPORTANTE: solo para resType=="OBJECTIVE" (coincidencia por texto de
    -- objetivo/progreso, lo que usan PROGRESS y el fallback narrativo), NO
    -- para "NAME" (lo que usa ACCEPTED). Si se aplicara tambien a NAME,
    -- aceptar una mision NUEVA que comparte nombre con una YA activa (p.ej.
    -- la 2da de 3 "Ithildín Coin" mientras la 1ra sigue activa) resolveria
    -- mal hacia la vieja -- SetQuestActive(vieja) es un no-op porque ya
    -- esta activa, y la nueva nunca se activa. Para PROGRESS ese riesgo no
    -- existe: el contador "(N/M)" siempre pertenece a una mision que el
    -- jugador ya tiene activa, nunca a una recien aceptada.
    if QuestStateManager and resType == "OBJECTIVE" then
        local activeMatch, activeCount = nil, 0
        for _, cndx in ipairs(candidates) do
            if QuestStateManager.State.active[cndx] then
                activeMatch = cndx
                activeCount = activeCount + 1
            end
        end
        if activeCount == 1 then
            if LQA.Debug.Enabled then
                Turbine.Shell.WriteLine("<rgb=#00FFFF>QuestSync DEBUG: AMBIGUA -> desambiguada por mision ya activa = " .. tostring(activeMatch) .. "</rgb>")
            end
            return "SUCCESS", activeMatch, resType .. "_ACTIVE"
        end
    end

    -- Varias quests comparten el mismo nombre/texto (p.ej. ramas paralelas de
    -- una introduccion, una para cada bestower). Regla #10 y #42 del
    -- documento maestro: nunca elegir al azar, pero SI se puede desambiguar
    -- por continuidad de cadena -- si el jugador ya completo o tiene activa
    -- alguna de las quests "prev" de exactamente una candidata, esa es la
    -- correcta.
    local best, bestScore, tie = nil, 0, false
    for _, cndx in ipairs(candidates) do
        local q = QuestDB and QuestDB.quests and QuestDB.quests[cndx]
        if q and q.prev then
            local score = 0
            for _, pndx in ipairs(q.prev) do
                local pstate = QuestStateManager and QuestStateManager.GetQuestState(pndx)
                if pstate == "COMPLETED" or pstate == "ACTIVE" then
                    score = score + 1
                end
            end
            if score > bestScore then
                best, bestScore, tie = cndx, score, false
            elseif score > 0 and score == bestScore then
                tie = true
            end
        end
    end

    if best and bestScore > 0 and not tie then
        if LQA.Debug.Enabled then
            Turbine.Shell.WriteLine("<rgb=#00FFFF>QuestSync DEBUG: AMBIGUA -> desambiguada por cadena previa = " .. tostring(best) .. "</rgb>")
        end
        return "SUCCESS", best, resType .. "_CHAIN"
    end

    return "AMBIGUA", candidates, resType
end

function QuestLocResolver.FindQuestByAnyName(nameRaw)
    if not nameRaw or nameRaw == "" then return "FAIL", nil, "No input" end

    local cleanName = toLowerES(nameRaw)

    -- Priority 1: Exact Match in Spanish / English (QuestNameESIndex mapping)
    local ndxs = QuestNameESIndex and QuestNameESIndex[cleanName]
    local resType = "NAME"

    if not ndxs then
        ndxs = QuestObjectiveESIndex and QuestObjectiveESIndex[cleanName]
        resType = "OBJECTIVE"
    end

    if not ndxs then
        -- Fallback to old english index if needed
        local ndx = QuestNameIndex and QuestNameIndex[cleanName]
        if ndx then ndxs = { ndx } end
    end

    -- (2026-09-27) Objetivo que en la base tiene marcas de color y en el
    -- chat llego sin ellas (o al reves, ya limpiado por el parser).
    if not ndxs then
        local key = toLowerES(QuestLocResolver.StripRGB(cleanName))
        ndxs = QuestLocResolver.RgbFreeObjective(key)
        resType = "OBJECTIVE"
    end

    if not ndxs then
        if LQA.Debug.Enabled then
            Turbine.Shell.WriteLine("<rgb=#FFFF00>QuestSync DEBUG: Candidates = NONE (" .. tostring(cleanName) .. ")</rgb>")
        end
        return "FAIL", nil, "No match"
    end

    -- Parse ndxs list (stored as "123,456" in string if multiple, or just number if single)
    local candidates = {}
    if type(ndxs) == "table" then
        candidates = ndxs
    elseif type(ndxs) == "number" then
        candidates = { ndxs }
    elseif type(ndxs) == "string" then
        for n in string.gmatch(ndxs, "%d+") do
            table.insert(candidates, tonumber(n))
        end
    end

    return Disambiguate(candidates, resType)
end

-- ===================================================================
-- FindQuestByName (2026-09-25, verificacion del sistema de deteccion):
-- resuelve SOLO por NOMBRE de mision (ingles o espanol), nunca por texto
-- de objetivo. Lo usan ACEPTADA/COMPLETADA/ABANDONADA del parser de chat:
-- despues de "New Quest:"/"Completed:" LOTRO siempre pone un NOMBRE, y
-- FindQuestByAnyName tambien busca en el indice de OBJETIVOS -- eso hacia
-- que (1) al completar una HAZANA ("Completed:\n<hazana>") cuyo nombre
-- coincide con el texto de objetivo de alguna mision, esa mision se
-- marcara completada (y se abriera su libro) sin tenerla, y (2) de dos
-- misiones con el MISMO nombre se eligiera una sola "al azar" segun que
-- indice la tuviera, en vez de tratarlas como ambiguas.
-- El indice nombre -> lista de misiones se arma una sola vez (la primera
-- vez que se usa) desde QuestDB y los nombres en espanol, asi todas las
-- homonimas quedan juntas.
-- ===================================================================
local NAME_NDX = nil

local function addName(key, ndx)
    if not key or key == "" or not ndx then return end
    local list = NAME_NDX[key]
    if not list then
        NAME_NDX[key] = { ndx }
        return
    end
    for _, v in ipairs(list) do
        if v == ndx then return end
    end
    list[#list + 1] = ndx
end

local function buildNameIndex()
    NAME_NDX = {}
    if QuestDB and QuestDB.quests then
        for ndx, q in pairs(QuestDB.quests) do
            if q.nameEN then addName(toLowerES(q.nameEN), ndx) end
            local es = QuestLocResolver.GetQuestNameES(ndx, nil)
            if es then addName(toLowerES(es), ndx) end
        end
    end
    if QuestNameESIndex then
        for key, v in pairs(QuestNameESIndex) do
            if type(v) == "table" then
                for _, n in ipairs(v) do addName(key, n) end
            elseif type(v) == "number" then
                addName(key, v)
            elseif type(v) == "string" then
                for n in string.gmatch(v, "%d+") do addName(key, tonumber(n)) end
            end
        end
    end
end

-- Arma el indice ya (lo llama QuestEventParser al cargar el plugin, para
-- no hacerlo en el primer mensaje de mision en pleno juego).
function QuestLocResolver.WarmUpNames()
    if not NAME_NDX then buildNameIndex() end
    QuestLocResolver.RgbFreeObjective("")
    QuestLocResolver.QuestZone(0)
end

-- ===================================================================
-- (2026-09-27) Objetivos con marcas de color, indexados tambien SIN ellas.
-- Solo se agregan claves que no existian ya en el indice de objetivos, asi
-- que nada de lo que ya se detectaba cambia.
-- ===================================================================
local RGB_FREE = nil

local function addCands(list, v)
    local function add(n)
        n = tonumber(n)
        if not n then return end
        for _, x in ipairs(list) do if x == n then return end end
        list[#list + 1] = n
    end
    if type(v) == "table" then
        for _, n in ipairs(v) do add(n) end
    elseif type(v) == "number" then
        add(v)
    elseif type(v) == "string" then
        for n in string.gmatch(v, "%d+") do add(n) end
    end
end

local function buildRgbFree()
    RGB_FREE = {}
    local idx = QuestObjectiveESIndex
    if type(idx) ~= "table" then return end
    for key, v in pairs(idx) do
        if string.find(key, "<rgb", 1, true) then
            local plain = toLowerES(QuestLocResolver.StripRGB(key))
            if plain ~= "" and idx[plain] == nil then
                local list = RGB_FREE[plain]
                if not list then
                    list = {}
                    RGB_FREE[plain] = list
                end
                addCands(list, v)
            end
        end
    end
end

function QuestLocResolver.RgbFreeObjective(key)
    if not RGB_FREE then buildRgbFree() end
    if not key or key == "" then return nil end
    local list = RGB_FREE[key]
    if list and #list > 0 then return list end
    return nil
end

-- ===================================================================
-- (2026-09-27) Zona REAL de cada mision. En la base, ~1.000 misiones
-- traen una zona equivocada (p.ej. "Enanos y mamuts": zona Bree-land,
-- subzona Länsi-mâ, que es Forochel) y 1.343 no traen zona. El Tracker
-- filtra por zona, asi que esas misiones desaparecian de la lista (o
-- hacian desaparecer a todas las demas al avanzar). Se usa, en orden:
--   1) la zona que tiene la mayoria (60% o mas) de las misiones de la
--      misma subzona (area),
--   2) la zona propia de la mision,
--   3) la categoria, si es el nombre de una zona ("Trollshaws").
-- Si no hay ninguna, se devuelve nil (zona desconocida).
-- ===================================================================
local ZONE_OF = nil
local ZONE_NAMES = nil  -- nombre normalizado -> zona tal como esta en la base

local function normZone(z)
    z = toLowerES(z or "")
    z = string.gsub(z, "^the ", "")
    return z
end

-- "Zonas" de la base que no son un lugar (eventos, misiones de sesion):
-- esas misiones cuentan como de zona desconocida (se ven siempre).
local function isNonGeo(nz)
    return nz == "special" or nz == "festival" or nz == "midsummer"
        or nz == "spring festival" or string.find(nz, "^mission") ~= nil
end

local function buildZones()
    ZONE_OF, ZONE_NAMES = {}, {}
    if not (QuestDB and QuestDB.quests) then return end
    local areaCount = {}
    for _, q in pairs(QuestDB.quests) do
        local z = q.zone or ""
        if z ~= "" then
            local nz = normZone(z)
            if not ZONE_NAMES[nz] then ZONE_NAMES[nz] = z end
            local a = q.area or ""
            if a ~= "" then
                local t = areaCount[a]
                if not t then
                    t = {}
                    areaCount[a] = t
                end
                t[z] = (t[z] or 0) + 1
            end
        end
    end
    local areaZone = {}
    for a, t in pairs(areaCount) do
        local best, bn, tot = nil, 0, 0
        for z, n in pairs(t) do
            tot = tot + n
            if n > bn then best, bn = z, n end
        end
        if tot >= 3 and bn >= tot * 0.6 then areaZone[a] = best end
    end
    for ndx, q in pairs(QuestDB.quests) do
        local z = areaZone[q.area or ""]
        if not z and q.zone and q.zone ~= "" then z = q.zone end
        if not z and q.category and q.category ~= "" then z = ZONE_NAMES[normZone(q.category)] end
        if z and isNonGeo(normZone(z)) then z = nil end
        ZONE_OF[ndx] = z or false
    end
end

function QuestLocResolver.QuestZone(ndx)
    if not ZONE_OF then buildZones() end
    return ZONE_OF[ndx] or nil
end

-- Zona de la base que corresponde al texto del canal Regional ("... Forochel
-- - Regional", "... Tierras de Bree - Regional"). Se busca el nombre de zona
-- mas largo (en ingles o en español) con el que TERMINA el texto.
local ZONE_KEYS = nil

local function buildZoneKeys()
    if not ZONE_OF then buildZones() end
    ZONE_KEYS = {}
    local function add(key, zone)
        key = normZone(key)
        if key ~= "" and zone then ZONE_KEYS[#ZONE_KEYS + 1] = { key = key, zone = zone } end
    end
    for nz, z in pairs(ZONE_NAMES) do
        if not isNonGeo(nz) then add(nz, z) end
    end
    if type(_G.MoorMapZonesES) == "table" then
        for en, es in pairs(_G.MoorMapZonesES) do
            local z = ZONE_NAMES[normZone(en)]
            if z and type(es) == "string" then
                add(es, z)
                local sinArticulo = string.gsub(toLowerES(es), "^l[aeo]s? ", "")
                add(sinArticulo, z)
            end
        end
    end
    table.sort(ZONE_KEYS, function(a, b)
        if #a.key ~= #b.key then return #a.key > #b.key end
        return a.key < b.key
    end)
end

function QuestLocResolver.ZoneFromText(text)
    if type(text) ~= "string" or text == "" then return nil end
    if not ZONE_KEYS then buildZoneKeys() end
    local t = toLowerES(QuestLocResolver.StripRGB(text))
    t = string.gsub(t, "[%s%.:,;%-]+$", "")
    for _, e in ipairs(ZONE_KEYS) do
        local k = e.key
        if #t >= #k and string.sub(t, -#k) == k then
            local before = string.sub(t, -#k - 1, -#k - 1)
            if #t == #k or not string.find(before, "[%w\128-\255]") then
                return e.zone
            end
        end
    end
    return nil
end

-- preferActive=true (COMPLETADA/ABANDONADA): si varias misiones comparten
-- el nombre y el jugador tiene EXACTAMENTE una de ellas activa, es esa --
-- se mira ANTES que la cadena "prev", que podria elegir una homonima que
-- ni siquiera tiene. Para ACEPTADA va en false: la mision nueva todavia no
-- esta activa (misma razon que la nota grande de Disambiguate).
function QuestLocResolver.FindQuestByName(nameRaw, preferActive)
    if not nameRaw or nameRaw == "" then return "FAIL", nil, "No input" end
    if not NAME_NDX then buildNameIndex() end
    local list = NAME_NDX[toLowerES(nameRaw)]
    if not list then return "FAIL", nil, "No match" end
    local candidates = {}
    for i = 1, #list do candidates[i] = list[i] end
    if preferActive and #candidates > 1 and QuestStateManager then
        local activeMatch, activeCount = nil, 0
        for _, cndx in ipairs(candidates) do
            if QuestStateManager.State.active[cndx] then
                activeMatch = cndx
                activeCount = activeCount + 1
            end
        end
        if activeCount == 1 then
            return "SUCCESS", activeMatch, "NAME_ACTIVE"
        end
    end
    return Disambiguate(candidates, "NAME")
end

-- ¿El texto es el NOMBRE de esa mision (ingles o espanol)? Lo usa el
-- parser para no activar una mision solo porque su nombre aparecio suelto
-- en el chat (el indice de objetivos tambien trae el nombre de muchas
-- misiones como si fuera un objetivo).
function QuestLocResolver.IsQuestOwnName(ndx, text)
    local q = QuestDB and QuestDB.quests and QuestDB.quests[ndx]
    if not q or not text then return false end
    local t = toLowerES(text)
    if q.nameEN and toLowerES(q.nameEN) == t then return true end
    local es = QuestLocResolver.GetQuestNameES(ndx, nil)
    if es and toLowerES(es) == t then return true end
    return false
end
