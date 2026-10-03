-- WorldMap_Addon/worldmap_deeds.lua
--
-- v2.6 (2026-09-26, pedido del jugador): hazañas (deeds) de cada zona en la
-- ventana de la zona del mapa, con casilla para marcarlas y % completado.
--
-- LOTRO no avisa el avance de las hazañas (solo en pantalla), asi que se
-- marcan a mano -- pero SINCRONIZADO con Deed Tracker (eleccion del
-- jugador), un solo registro:
--   * lectura: el guardado de Deed Tracker de este personaje
--     (PluginData de servidor "DeedTracker_CharData_<personaje>", mismo
--     archivo que Deed Tracker escribe y lee).
--   * escritura: Deed Tracker corre en su propio "apartamento" y no se
--     puede tocar desde aca; se le dejan pedidos en
--     "DeedTracker_MapRequests" (personaje) y el los cumple en ~1 s
--     (CubePlugins/DeedTracker/RemoteRequests.lua) y avisa en
--     "DeedTracker_MapAck" cual fue el ultimo. Mientras tanto la casilla
--     muestra lo que el jugador eligio (pendiente de confirmar).
-- Datos de que hazañas van en cada zona: worldmap_deeds_data.lua
-- (generado de la pagina "Por zona" de Deed Tracker).
--
-- Todo con pcall: si Deed Tracker no esta, o falta algun archivo, el mapa
-- funciona igual que antes.

_G.WorldMapAddon = _G.WorldMapAddon or {}
WorldMapAddon.Deeds = WorldMapAddon.Deeds or {}
local D = WorldMapAddon.Deeds

local REQUEST_KEY = "DeedTracker_MapRequests"
local ACK_KEY = "DeedTracker_MapAck"
local PENDING_GRACE = 5         -- s: tras cumplir el pedido, cuanto se espera a verlo guardado
local STATUS_MAX_AGE = 2        -- s: cada cuanto se relee el guardado como mucho

D.SECTION_TITLES = { "Haza\195\177as de la zona", "Instancias de la zona", "Reputaci\195\179n de la zona" }

D.status = nil          -- { [id] = true } completadas segun Deed Tracker
D.statusAt = nil
D.pending = {}          -- [id] = { done = bool, at = tiempo, q = pedido }
D.queue = {}            -- pedidos todavia no confirmados: { n, op, id, done }
D.lastAck = 0           -- ultimo pedido que Deed Tracker confirmo
D.reqMax = 0            -- numero mas alto que ya hay en el archivo de pedidos
D.ready = false         -- ya se leyeron ack + pedidos (se pueden numerar)
D.loading = false
D.loadingAt = nil

-- IMPORTANTE (v2.7.1, error real en el juego): Turbine.PluginData.Load
-- SIN funcion de aviso solo se puede usar mientras el plugin carga; despues
-- el juego tira "The data load event handler must be specified". Por eso
-- TODAS las lecturas de aca son asincronicas (con funcion de aviso): el
-- dato llega un instante despues y se avisa al mapa (D.onChange) para que
-- redibuje. Nunca se escribe nada en el chat.
local LOAD_TIMEOUT = 10         -- s: si el juego nunca avisa, se vuelve a pedir

local function Now()
    return Turbine.Engine.GetGameTime()
end

local function LoadAsync(scope, key, callback)
    local answered = false
    local ok = pcall(Turbine.PluginData.Load, scope, key, function(data)
        if answered then
            return
        end
        answered = true
        pcall(callback, type(data) == "table" and data or nil)
    end)
    if not ok and not answered then
        answered = true
        pcall(callback, nil)
    end
end

local function SaveData(scope, key, data)
    return pcall(Turbine.PluginData.Save, scope, key, data)
end

local function Changed()
    if type(D.onChange) == "function" then
        pcall(D.onChange)
    end
    local map = WorldMapAddon.instance
    if map ~= nil and type(map._onDeedStatus) == "function" then
        pcall(map._onDeedStatus, map)
    end
end

function D.Available()
    return type(WorldMapAddon.DeedsData) == "table"
end

-- entrada de datos de la zona del mapa (o nil si Deed Tracker no la separa)
function D.ZoneData(zone)
    if zone == nil or not D.Available() then
        return nil
    end
    return WorldMapAddon.DeedsData[zone.nombre_original]
end

-- ¿Deed Tracker esta cargado ahora?
function D.TrackerLoaded()
    local ok, loaded = pcall(function()
        local list = Turbine.PluginManager.GetLoadedPlugins()
        if type(list) ~= "table" then
            return nil
        end
        for _, p in pairs(list) do
            if type(p) == "table" and p.Name == "Deed Tracker" then
                return true
            end
        end
        return false
    end)
    if ok then
        return loaded
    end
    return nil
end

-- mismo nombre de archivo que usa Deed Tracker (Main.lua GetCharDataFilename)
local function CharDataKey()
    local ok, name = pcall(function()
        return Turbine.Gameplay.LocalPlayer.GetInstance():GetName()
    end)
    if not ok or type(name) ~= "string" or name == "" then
        return nil
    end
    if name:sub(1, 1) == "~" then
        name = name:sub(2)
    end
    name = name:gsub("-", "_")
    return "DeedTracker_CharData_" .. name
end

-- numero de hazaña de una clave guardada por Deed Tracker (VindarPatch
-- guarda los numeros como texto, a veces con "#" adelante)
local function DeedNumber(key)
    local n = tonumber(key)
    if n == nil and type(key) == "string" then
        n = tonumber((key:gsub("^#", "")))
    end
    return n
end

local function SetStatusFrom(data)
    local status = {}
    if data ~= nil and type(data.DEEDS) == "table" then
        for id, entry in pairs(data.DEEDS) do
            local n = DeedNumber(id)
            if n ~= nil and entry ~= nil and entry ~= false then
                status[n] = true
            end
        end
    end
    D.status = status
end

local function SetAckFrom(ack)
    local last = ack and DeedNumber(ack.last) or 0
    if last > D.lastAck then
        D.lastAck = last
    end
    if #D.queue > 0 then
        local keep = {}
        for _, q in ipairs(D.queue) do
            if q.n == nil or q.n > D.lastAck then
                keep[#keep + 1] = q
            end
        end
        D.queue = keep
    end
end

-- limpia las marcas pendientes que Deed Tracker ya confirmo
local function CleanPending()
    local status = D.status or {}
    local now = Now()
    for id, p in pairs(D.pending) do
        local n = p.q and p.q.n or nil
        -- confirmado en el guardado, o Deed Tracker ya lo proceso y no lo
        -- aplico (p.ej. no es una hazaña valida). Si Deed Tracker no esta
        -- cargado el pedido sigue en cola y la casilla queda como se marco.
        if (status[id] == true) == p.done
            or (n ~= nil and n <= D.lastAck and (now - p.at) > PENDING_GRACE) then
            D.pending[id] = nil
        end
    end
end

-- relee (asincronico) el guardado de Deed Tracker y su confirmacion, como
-- mucho cada STATUS_MAX_AGE s salvo force. Devuelve lo que ya se sabe; lo
-- nuevo llega despues y avisa al mapa.
function D.RefreshStatus(force)
    local now = Now()
    if D.loading and D.loadingAt ~= nil and (now - D.loadingAt) < LOAD_TIMEOUT then
        return D.status or {}
    end
    if not force and D.statusAt ~= nil and (now - D.statusAt) < STATUS_MAX_AGE then
        return D.status or {}
    end
    D.statusAt = now
    D.loading = true
    D.loadingAt = now
    local function loadAck()
        LoadAsync(Turbine.DataScope.Character, ACK_KEY, function(ack)
            SetAckFrom(ack)
            CleanPending()
            D.loading = false
            Changed()
        end)
    end
    local key = CharDataKey()
    if key ~= nil then
        LoadAsync(Turbine.DataScope.Server, key, function(data)
            SetStatusFrom(data)
            loadAck()
        end)
    else
        D.status = D.status or {}
        loadAck()
    end
    return D.status or {}
end

function D.IsDone(id)
    local p = D.pending[id]
    if p ~= nil then
        return p.done
    end
    local status = D.status
    if status == nil then
        status = D.RefreshStatus(false)
    end
    return status[id] == true
end

function D.IsPending(id)
    return D.pending[id] ~= nil
end

-- conteos { total, done, [1] = {total, done}, [2] = ..., [3] = ... }
function D.Counts(zone)
    local data = D.ZoneData(zone)
    if data == nil then
        return nil
    end
    local res = { total = 0, done = 0 }
    for s = 1, 3 do
        local t, d = 0, 0
        for _, row in ipairs(data[s] or {}) do
            if row.h == nil and row[1] ~= nil then
                t = t + 1
                if D.IsDone(row[1]) then
                    d = d + 1
                end
            end
        end
        res[s] = { total = t, done = d }
        res.total = res.total + t
        res.done = res.done + d
    end
    return res
end

function D.Percent(done, total)
    if total == nil or total <= 0 then
        return 0
    end
    return math.floor((done * 100 / total) + 0.5)
end

-- ---------- pedidos a Deed Tracker ----------
function D.ReadAck()
    return D.lastAck
end

-- numera los pedidos: siempre despues del ultimo confirmado y de los que ya
-- estan en el archivo (Deed Tracker cumple solo los numeros nuevos)
local function Numerate()
    local top = math.max(D.lastAck, D.reqMax)
    for _, q in ipairs(D.queue) do
        if q.n ~= nil and q.n > top then
            top = q.n
        end
    end
    for _, q in ipairs(D.queue) do
        if q.n == nil then
            top = top + 1
            q.n = top
        end
    end
end

local function SaveQueue()
    local ops = {}
    for _, q in ipairs(D.queue) do
        if q.n ~= nil then
            local op = { op = q.op, id = tostring(q.id) }
            if q.done ~= nil then
                op.done = q.done and "1" or "0"
            end
            ops[tostring(q.n)] = op
        end
    end
    return SaveData(Turbine.DataScope.Character, REQUEST_KEY, { ops = ops })
end

-- lectura inicial (asincronica) de la confirmacion y del archivo de
-- pedidos; hasta que llega, los pedidos esperan en la cola sin numero
local initStarted = false
function D.Init()
    if initStarted then
        return
    end
    initStarted = true
    LoadAsync(Turbine.DataScope.Character, ACK_KEY, function(ack)
        SetAckFrom(ack)
        LoadAsync(Turbine.DataScope.Character, REQUEST_KEY, function(req)
            if req ~= nil and type(req.ops) == "table" then
                for k in pairs(req.ops) do
                    local n = DeedNumber(k)
                    if n ~= nil and n > D.reqMax then
                        D.reqMax = n
                    end
                end
            end
            D.ready = true
            if #D.queue > 0 then
                Numerate()
                SaveQueue()
            end
        end)
    end)
end

local function Push(op, id, done)
    -- un solo "set" pendiente por hazaña (el ultimo gana)
    if op == "set" then
        local keep = {}
        for _, q in ipairs(D.queue) do
            if not (q.op == "set" and q.id == id) then
                keep[#keep + 1] = q
            end
        end
        D.queue = keep
    end
    local q = { op = op, id = id, done = done }
    D.queue[#D.queue + 1] = q
    if not D.ready then
        -- todavia no se sabe que numero toca: se guarda al llegar el dato
        D.Init()
        return true, q
    end
    Numerate()
    local ok = SaveQueue()
    return ok, q
end

function D.Set(id, done)
    id = tonumber(id)
    if id == nil then
        return false
    end
    local ok, q = Push("set", id, done == true)
    D.pending[id] = { done = done == true, at = Now(), q = q }
    return ok
end

function D.Open(id)
    id = tonumber(id)
    if id == nil then
        return false
    end
    local ok = Push("open", id, nil)
    return ok
end

-- texto corto para el cartel de la zona ("" si la zona no tiene hazañas)
function D.SummaryText(zone)
    local ok, c = pcall(D.Counts, zone)
    if not ok or c == nil or c.total == 0 then
        return ""
    end
    return "Haza\195\177as " .. c.done .. "/" .. c.total
end

-- al cargar el plugin: primera lectura (asincronica) de todo
D.Init()
pcall(D.RefreshStatus, true)
