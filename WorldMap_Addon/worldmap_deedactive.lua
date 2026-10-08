-- WorldMap_Addon/worldmap_deedactive.lua
--
-- v3.3 (pedido del usuario): estado de las hazañas en el mapa de zona.
--   * COMPLETADA (gris + X): lo que ya guardan los otros addons del jugador
--       - Deed Tracker: hazañas completadas de este personaje
--         (WorldMapAddon.Deeds.IsDone, mismo guardado que ya usaba el mapa);
--       - Quest Assistant: "encontrado" de LostLore / Cofres
--         (FoundStateManager.IsFound, mismo guardado de Quest Assistant);
--       - y lo que este archivo ve en el chat ("Completed: <hazaña>").
--   * ACTIVA (aura): la hazaña tuvo PROGRESO (eleccion del usuario). LOTRO
--     no avisa a los addons que hazañas estan empezadas, asi que se lee el
--     chat de misiones (el mismo que leen Quest Assistant y Deed Tracker):
--     si un aviso nombra una hazaña o uno de sus objetivos (en ingles o en
--     español), esa hazaña queda activa; si nombra un objetivo (un lugar
--     descubierto), ese icono queda completado.
-- Se guarda por personaje (Turbine.PluginData, "WorldMap_HazanasProgreso").
--
-- El chat se escucha con el MISMO esquema compartido que ya usan Quest
-- Assistant y Deed Tracker (_G.LQA_ChatListeners[nombre] = funcion): no se
-- pisa Turbine.Chat.Received ni a ningun otro addon. Sin Quest Assistant no
-- hay quien reparta el chat: solo se ven las completadas.
-- Todo en pcall: si algo falla, el mapa se ve como siempre.

import "Turbine"

_G.WorldMapAddon = _G.WorldMapAddon or {}

local A = {}
WorldMapAddon.DeedActive = A

local SAVE_KEY = "WorldMap_HazanasProgreso"

A.data = { a = {}, o = {}, d = {}, dt = {}, qf = {} }
-- a: hazañas con progreso, o: objetivos hechos, d: completadas (chat)
-- v3.4: copia guardada de lo que tienen los OTROS addons (se usa si en esta
-- sesion ese addon no esta cargado): dt = completadas de Deed Tracker,
-- qf = "encontrado" de Quest Assistant (cofres / colecciones)
A.version = 0
A.loaded = false

-- misma normalizacion que build_layers.py (nkey): minusculas ASCII, todo lo
-- que no es letra/numero (ASCII) pasa a espacio, letras con acento intactas
function A.Norm(text)
    local s = tostring(text or "")
    s = s:gsub("<[^>]*>", " ")
    s = s:gsub("[A-Z]", function(c) return c:lower() end)
    s = s:gsub("[^a-z0-9\128-\255]", " ")
    s = s:gsub("%s+", " ")
    s = s:gsub("^ ", ""):gsub(" $", "")
    return s
end
local Norm = A.Norm

local function Save()
    pcall(function()
        Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, A.data)
    end)
end

local function Bump()
    A.version = A.version + 1
end

function A.Load()
    if A.loadStarted then
        return
    end
    A.loadStarted = true
    pcall(function()
        Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(data)
            pcall(function()
                if type(data) == "table" then
                    for _, k in ipairs({ "a", "o", "d", "dt", "qf" }) do
                        if type(data[k]) == "table" then
                            for key, v in pairs(data[k]) do
                                if v == true or v == 1 or v == "true" then
                                    A.data[k][tostring(key)] = true
                                end
                            end
                        end
                    end
                end
            end)
            A.loaded = true
            Bump()
        end)
    end)
end

-- zona del mapa donde esta el jugador (la que ya sigue el mapa con Quest
-- Assistant / el canal Regional), o nil
local function PlayerZone()
    local ok, z = pcall(function()
        local Q = WorldMapAddon.Quests
        return Q ~= nil and Q.PlayerZone ~= nil and Q.PlayerZone() or nil
    end)
    if ok then
        return z
    end
    return nil
end

local function IdOf(val)
    return val:match("^[DO]([^:|]+)")
end

-- varios candidatos ("D1|D2", mismo texto en varias zonas): solo los de UNA
-- hazaña, la de la zona donde esta el jugador; si no se sabe la zona o
-- quedan varias hazañas, ninguno (nunca se adivina). Devuelve una lista.
local function Choose(val)
    local parts = {}
    for part in val:gmatch("[^|]+") do
        parts[#parts + 1] = part
    end
    local first = IdOf(parts[1] or "")
    local same = true
    for _, part in ipairs(parts) do
        if IdOf(part) ~= first then
            same = false
        end
    end
    if same then
        return parts
    end
    local zone = PlayerZone()
    local DZ = WorldMapAddon.DeedZone
    if zone == nil or type(DZ) ~= "table" then
        return {}
    end
    local pick, id0 = {}, nil
    for _, part in ipairs(parts) do
        local id = IdOf(part)
        local zones = id and DZ[id] or nil
        if zones ~= nil and ("|" .. zones .. "|"):find("|" .. zone .. "|", 1, true) ~= nil then
            if id0 ~= nil and id0 ~= id then
                return {}
            end
            id0 = id
            pick[#pick + 1] = part
        end
    end
    return pick
end
A.Choose = Choose

-- aplica una coincidencia del indice ("D<id>" / "O<id>:<objetivo>")
local function ApplyOne(val, completed)
    local changed = false
    local kind = val:sub(1, 1)
    if kind == "D" then
        local id = val:sub(2)
        if completed then
            if not A.data.d[id] then A.data.d[id] = true; changed = true end
        elseif not A.data.a[id] then
            A.data.a[id] = true; changed = true
        end
    elseif kind == "O" then
        local id, obj = val:match("^O([^:]+):(.*)$")
        if id ~= nil then
            local key = id .. ":" .. obj
            if not A.data.o[key] then A.data.o[key] = true; changed = true end
            if not A.data.a[id] then A.data.a[id] = true; changed = true end
        end
    end
    return changed
end

-- activeOnly: el aviso solo MENCIONA el lugar (no es exactamente su
-- nombre): la hazaña queda activa pero ningun icono se da por completado
local function Apply(val, completed, activeOnly)
    local changed = false
    for _, part in ipairs(Choose(val)) do
        if completed and part:sub(1, 1) ~= "D" then
            -- "Completed:" solo completa hazañas enteras, no objetivos
        else
            if activeOnly and part:sub(1, 1) == "O" then
                part = "D" .. (IdOf(part) or "")
            end
            if ApplyOne(part, completed) then
                changed = true
            end
        end
    end
    return changed
end

-- un aviso del chat de misiones
function A.Handle(message)
    local DM = WorldMapAddon.DeedMatch
    if type(DM) ~= "table" or message == nil then
        return false
    end
    local text = tostring(message):gsub("<[^>]*>", "")
    -- avisos de MISIONES (los lee Quest Assistant): no son hazañas
    if text:find("^%s*New Quest:") ~= nil or text:find("^%s*Nueva misi") ~= nil then
        return false
    end
    local completed = text:find("^%s*Completed:") ~= nil or text:find("^%s*Completad[oa]:") ~= nil
    -- "Completed:" con el nombre de una MISION que se llama igual que una
    -- hazaña (lista de Quest Assistant, DeedQuestCollisions): no se toca
    -- (Deed Tracker sabe si fue la hazaña)
    if completed then
        local ok, coll = pcall(function()
            local set = _G.DeedQuestCollisions
            local R = _G.QuestLocResolver
            if type(set) ~= "table" or R == nil or R.NormalizeES == nil then
                return false
            end
            local name = text:match("^[^:\n]*:%s*(.-)%s*$") or ""
            return set[R.NormalizeES(name)] == true
        end)
        if ok and coll == true then
            return false
        end
    end
    -- sin el contador "(3/10)"
    text = text:gsub("%(%s*%d+%s*/%s*%d+%s*%)", " ")
    local cands = { text }
    local after = text:match("^[^:\n]*:%s*(.*)$")
    if after ~= nil then
        cands[#cands + 1] = after
    end
    for line in (text .. "\n"):gmatch("(.-)\n") do
        cands[#cands + 1] = line
    end
    local changed = false
    local hit = false
    for _, c in ipairs(cands) do
        local v = DM[Norm(c)]
        if v ~= nil then
            hit = true
            if Apply(v, completed) then changed = true end
        end
    end
    -- objetivo nombrado dentro del aviso (p.ej. "Discovered Hillshire Ruins")
    if not hit then
        local full = " " .. Norm(text) .. " "
        if #full >= 12 then
            if A.objKeys == nil then
                -- (una sola vez: solo los nombres de lugares / objetos largos)
                local list = {}
                for k, v in pairs(DM) do
                    if #k >= 10 and v:sub(1, 1) == "O" then
                        list[#list + 1] = k
                    end
                end
                A.objKeys = list
            end
            for _, k in ipairs(A.objKeys) do
                if full:find(" " .. k .. " ", 1, true) ~= nil then
                    if Apply(DM[k], false, true) then changed = true end
                end
            end
        end
    end
    if changed then
        Bump()
        Save()
    end
    return changed
end

function A.OnChat(sender, args)
    if args == nil then
        return
    end
    local ok = pcall(function()
        local quest = Turbine.ChatType ~= nil and Turbine.ChatType.Quest or nil
        if quest ~= nil and args.ChatType ~= quest then
            return
        end
        A.Handle(args.Message)
    end)
    return ok
end

-- "id:entradaQuestAssistant" -> id, entrada
local function SplitKey(key)
    local id, lqa = tostring(key or ""):match("^([^:]*):?(.*)$")
    return id or "", lqa or ""
end

local function DeedDone(id)
    if id == "" then
        return false
    end
    if A.data.d[id] then
        return true
    end
    local ok, done = pcall(function()
        local D = WorldMapAddon.Deeds
        return D ~= nil and D.IsDone ~= nil and D.IsDone(tonumber(id)) == true
    end)
    if ok and done == true then
        return true
    end
    -- (Deed Tracker no cargado: lo ultimo que se le copio)
    return A.data.dt[id] == true and not A.dtLive
end

local function FoundInQA(lqa)
    if lqa == "" then
        return false
    end
    local ok, found = pcall(function()
        local FSM = _G.FoundStateManager
        if FSM == nil or FSM.IsFound == nil then
            return false
        end
        return FSM.IsFound(tonumber(lqa)) == true or FSM.IsFound(lqa) == true
    end)
    if ok and found == true then
        return true
    end
    return A.data.qf[lqa] == true and not A.qfLive
end

-- v3.4: copia (guardada por personaje) de lo que tienen Deed Tracker y Quest
-- Assistant, para que el mapa lo siga sabiendo aunque esos addons no esten
-- cargados. Se reemplaza entera cuando el addon esta (asi lo que se
-- desmarca alla tambien se desmarca aca). No se escribe nada en los otros.
local function SameSet(a, b)
    for k in pairs(a) do if not b[k] then return false end end
    for k in pairs(b) do if not a[k] then return false end end
    return true
end
function A.Sync()
    local changed = false
    pcall(function()
        local D = WorldMapAddon.Deeds
        -- (el guardado de Deed Tracker se lee aunque Deed Tracker no este
        -- cargado; vacio solo cuenta si Deed Tracker esta cargado)
        local live = D ~= nil and type(D.status) == "table"
            and (next(D.status) ~= nil or (D.TrackerLoaded ~= nil and D.TrackerLoaded() == true))
        A.dtLive = live
        if live then
            local set = {}
            for id, v in pairs(D.status) do
                if v == true then set[tostring(id)] = true end
            end
            if not SameSet(set, A.data.dt) then
                A.data.dt = set
                changed = true
            end
        end
    end)
    pcall(function()
        local FSM = _G.FoundStateManager
        local live = FSM ~= nil and type(FSM.Found) == "table"
        A.qfLive = live
        if live then
            local set = {}
            for id, v in pairs(FSM.Found) do
                if v == true then set[tostring(id)] = true end
            end
            if not SameSet(set, A.data.qf) then
                A.data.qf = set
                changed = true
            end
        end
    end)
    if changed then
        Bump()
        Save()
    end
    return changed
end

-- v3.4: progreso de una hazaña: hechos, total (nil si no se sabe)
function A.Progress(id)
    id = tostring(id or "")
    local TOT = WorldMapAddon.DeedTotal
    local total = type(TOT) == "table" and TOT[id] or nil
    if total == nil then
        return nil
    end
    if DeedDone(id) then
        return total, total
    end
    local n = 0
    local prefix = id .. ":"
    for k in pairs(A.data.o) do
        if k:sub(1, #prefix) == prefix then
            n = n + 1
        end
    end
    if n > total then n = total end
    return n, total
end

-- firma del estado (si cambia, el mapa vuelve a dibujar los iconos)
function A.Signature()
    local n = A.version
    pcall(function()
        local D = WorldMapAddon.Deeds
        if D ~= nil and type(D.status) == "table" then
            for _ in pairs(D.status) do n = n + 1 end
        end
        if D ~= nil and type(D.pending) == "table" then
            for _ in pairs(D.pending) do n = n + 7 end
        end
        local FSM = _G.FoundStateManager
        if FSM ~= nil and type(FSM.Found) == "table" then
            for _ in pairs(FSM.Found) do n = n + 3 end
        end
    end)
    return n
end

-- estado de un icono (un renglon): "done", "active" o nil
-- key = "hazaña:entradaQuestAssistant", obj = nombre (ingles) del objetivo
function A.Status(key, obj)
    if key == nil or key == "" then
        return nil
    end
    local id, lqa = SplitKey(key)
    if DeedDone(id) or FoundInQA(lqa) then
        return "done"
    end
    if id ~= "" and obj ~= nil and obj ~= "" and A.data.o[id .. ":" .. Norm(obj)] then
        return "done"
    end
    if id ~= "" and A.data.a[id] then
        return "active"
    end
    return nil
end

-- registro en el chat compartido (Quest Assistant / Deed Tracker)
pcall(function()
    if type(_G.LQA_ChatListeners) ~= "table" then
        _G.LQA_ChatListeners = {}
    end
    _G.LQA_ChatListeners["WorldMapDeeds"] = A.OnChat
end)

A.Load()
