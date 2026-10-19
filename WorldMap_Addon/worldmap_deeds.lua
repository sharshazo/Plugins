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
    -- v3.12.1: aviso de zona que esperaba los datos de Deed Tracker
    if D.toastPending ~= nil and D.status ~= nil and D.ShowZoneToast ~= nil then
        local z = D.toastPending
        D.toastPending = nil
        pcall(D.ShowZoneToast, z)
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
    local key = zone.nombre_original
    if key == "Pahar Hatokali" then key = "The Hatokali Fells" end
    return WorldMapAddon.DeedsData[key]
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
    local previous = D.status
    local changed = previous == nil
    if previous ~= nil then
        for id in pairs(status) do if previous[id] ~= true then changed = true; break end end
        if not changed then
            for id in pairs(previous) do if status[id] ~= true then changed = true; break end end
        end
    end
    D.status = status
    return changed
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
    local changed = false
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
            changed = true
        end
    end
    return changed
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
    local statusChanged = false
    local function loadAck()
        LoadAsync(Turbine.DataScope.Character, ACK_KEY, function(ack)
            local previousAck = D.lastAck
            SetAckFrom(ack)
            local pendingChanged = CleanPending()
            D.loading = false
            if statusChanged or previousAck ~= D.lastAck or pendingChanged or D.toastPending ~= nil then
                Changed()
            end
        end)
    end
    local key = CharDataKey()
    if key ~= nil then
        LoadAsync(Turbine.DataScope.Server, key, function(data)
            statusChanged = SetStatusFrom(data)
            loadAck()
        end)
    else
        statusChanged = D.status == nil
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
-- v3.12 (pedido del jugador): recompensas que faltan en la zona (hazañas
-- sin hacer): { vxp = XP de virtud, lp = puntos LOTRO, n = hazañas }.
-- Datos de worldmap_deedinfo_data.lua; sin ese archivo, nil.
function D.Remaining(zone)
    local I = WorldMapAddon.DeedInfo
    local data = D.ZoneData(zone)
    if data == nil or type(I) ~= "table" or type(I.D) ~= "table" then
        return nil
    end
    local res, seen = { vxp = 0, lp = 0, n = 0 }, {}
    for s = 1, 3 do
        for _, row in ipairs(data[s] or {}) do
            local id = row.h == nil and row[1] or nil
            if id ~= nil and not seen[id] then
                seen[id] = true
                if not D.IsDone(id) then
                    local d = I.D[tonumber(id) or id]
                    if d ~= nil then
                        res.vxp = res.vxp + (tonumber(d[5]) or 0)
                        res.lp = res.lp + (tonumber(d[6]) or 0)
                        res.n = res.n + 1
                    end
                end
            end
        end
    end
    return res
end

-- "Faltan: 12.000 XP virtud · 45 LOTRO" (o "" si no falta nada)
function D.RemainingText(zone)
    local ok, r = pcall(D.Remaining, zone)
    if not ok or r == nil or (r.vxp <= 0 and r.lp <= 0) then
        return ""
    end
    local function th(n)
        local t = tostring(math.floor(n))
        local out = t:reverse():gsub("(%d%d%d)", "%1."):reverse()
        return (out:gsub("^%.", ""))
    end
    local parts = {}
    if r.vxp > 0 then parts[#parts + 1] = th(r.vxp) .. " XP virtud" end
    if r.lp > 0 then parts[#parts + 1] = th(r.lp) .. " LOTRO" end
    return "Faltan: " .. table.concat(parts, " \194\183 ")
end

function D.SummaryText(zone)
    local ok, c = pcall(D.Counts, zone)
    if not ok or c == nil or c.total == 0 then
        return ""
    end
    return "Haza\195\177as " .. c.done .. "/" .. c.total
end

-- ---------------------------------------------------------------------
-- v3.12 (pedido del jugador): aviso al ENTRAR a una zona (canal Regional)
-- con las hazañas que faltan ahi, las de exploracion y las recompensas.
-- Tarjeta oscura arriba al centro, 8 s, sin mouse. Opcion "zonetoast".
-- ---------------------------------------------------------------------
local TOAST_RES = "WorldMap_Addon/assets/worldmap/icon/"
local TOAST_W, TOAST_R, TOAST_SECS = 360, 12, 8
local function TColor(r, g, b, a) return Turbine.UI.Color(a or 1, r / 255, g / 255, b / 255) end

local function BuildToast()
    local t = {}
    local win = Turbine.UI.Window()
    win:SetSize(TOAST_W, 96)
    win:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    win:SetZOrder(0x7FFFFFF0)
    win:SetMouseVisible(false)
    win:SetVisible(false)
    t.win = win
    local function box(color)
        local k = Turbine.UI.Control()
        k:SetParent(win)
        k:SetMouseVisible(false)
        k:SetBackColor(color)
        return k
    end
    local function img(file, w, h)
        local k = Turbine.UI.Control()
        k:SetParent(win)
        k:SetSize(w, h)
        k:SetBackground(TOAST_RES .. file)
        k:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        k:SetMouseVisible(false)
        return k
    end
    local function label(font, color)
        local l = Turbine.UI.Label()
        l:SetParent(win)
        l:SetFont(font)
        l:SetForeColor(color)
        l:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        l:SetMouseVisible(false)
        return l
    end
    local bg, border = TColor(16, 18, 24, 0.96), TColor(60, 66, 80)
    t.tl, t.tr = img("card_tl.tga", TOAST_R, TOAST_R), img("card_tr.tga", TOAST_R, TOAST_R)
    t.bl, t.br = img("card_bl.tga", TOAST_R, TOAST_R), img("card_br.tga", TOAST_R, TOAST_R)
    t.top, t.mid, t.bot = box(bg), box(bg), box(bg)
    t.lineT, t.lineB, t.lineL, t.lineR = box(border), box(border), box(border), box(border)
    t.accent = box(TColor(80, 170, 255))
    t.icon = img("fl_exploracion_32.tga", 32, 32)
    local F = Turbine.UI.Lotro.Font
    t.title = label(F.Verdana16 or F.Verdana14, TColor(245, 248, 255))
    t.l1 = label(F.Verdana12, TColor(140, 170, 210))
    t.l2 = label(F.Verdana12, TColor(124, 224, 124))
    t.l3 = label(F.Verdana12, TColor(240, 208, 96))
    -- se esconde sola a los TOAST_SECS segundos
    t.timer = Turbine.UI.Control()
    t.timer.Update = function()
        local okT, now = pcall(Turbine.Engine.GetGameTime)
        if not okT or t.hideAt == nil or now >= t.hideAt then
            t.hideAt = nil
            pcall(function() win:SetVisible(false) end)
            t.timer:SetWantsUpdates(false)
        end
    end
    return t
end

local function LayoutToast(t, lines)
    local W, R = TOAST_W, TOAST_R
    local H = 16 + 22 + (#lines * 17) + 12
    t.win:SetSize(W, H)
    t.tl:SetPosition(0, 0); t.tr:SetPosition(W - R, 0)
    t.bl:SetPosition(0, H - R); t.br:SetPosition(W - R, H - R)
    t.top:SetPosition(R, 0); t.top:SetSize(W - 2 * R, R)
    t.mid:SetPosition(0, R); t.mid:SetSize(W, H - 2 * R)
    t.bot:SetPosition(R, H - R); t.bot:SetSize(W - 2 * R, R)
    t.lineT:SetPosition(R, 0); t.lineT:SetSize(W - 2 * R, 1)
    t.lineB:SetPosition(R, H - 1); t.lineB:SetSize(W - 2 * R, 1)
    t.lineL:SetPosition(0, R); t.lineL:SetSize(1, H - 2 * R)
    t.lineR:SetPosition(W - 1, R); t.lineR:SetSize(1, H - 2 * R)
    t.accent:SetPosition(1, R); t.accent:SetSize(4, H - 2 * R)
    t.icon:SetPosition(14, 14)
    t.title:SetPosition(56, 12); t.title:SetSize(W - 70, 22)
    local labels = { t.l1, t.l2, t.l3 }
    for i, l in ipairs(labels) do
        if lines[i] ~= nil then
            l:SetPosition(56, 36 + (i - 1) * 17)
            l:SetSize(W - 70, 16)
            l:SetText(lines[i])
            l:SetVisible(true)
        else
            l:SetVisible(false)
        end
    end
    local dw = Turbine.UI.Display.GetWidth()
    t.win:SetPosition(math.floor((dw - W) / 2), 110)
end

-- textos del aviso para una zona del mapa (o nil si no hay nada que avisar)
function D.ToastLines(zone)
    local c = D.Counts(zone)
    if c == nil or c.total <= 0 or c.done >= c.total then
        return nil
    end
    local lines = { "Te faltan " .. (c.total - c.done) .. " haza\195\177as (" .. D.Percent(c.done, c.total) .. "% hechas)" }
    local I = WorldMapAddon.DeedInfo
    local data = D.ZoneData(zone)
    if type(I) == "table" and type(I.D) == "table" and data ~= nil then
        local n, seen = 0, {}
        for s = 1, 3 do
            for _, row in ipairs(data[s] or {}) do
                local id = row.h == nil and row[1] or nil
                if id ~= nil and not seen[id] then
                    seen[id] = true
                    local d = I.D[tonumber(id) or id]
                    if d ~= nil and tonumber(d[3]) == 103 and not D.IsDone(id) then
                        n = n + 1
                    end
                end
            end
        end
        if n > 0 then
            lines[#lines + 1] = "Exploraci\195\179n sin hacer: " .. n
        end
    end
    local rt = D.RemainingText(zone)
    if rt ~= "" then
        lines[#lines + 1] = rt
    end
    return lines
end

function D.ShowZoneToast(zone)
    local O = WorldMapAddon.Options
    if O ~= nil and O.Get ~= nil and O.Get("zonetoast") == false then
        return false
    end
    if zone == nil or zone == D.toastZone then
        return false
    end
    -- v3.12.1: hasta que llegue el guardado de Deed Tracker los conteos
    -- saldrian en 0% (al entrar al juego): se espera y se muestra despues
    if D.status == nil or D.loading == true then
        D.toastPending = zone
        pcall(D.RefreshStatus, false)
        return false
    end
    local lines = D.ToastLines(zone)
    if lines == nil then
        return false
    end
    D.toastZone = zone
    if D.toast == nil then
        D.toast = BuildToast()
    end
    local t = D.toast
    t.title:SetText(zone.nombre or zone.nombre_original or "")
    LayoutToast(t, lines)
    t.hideAt = Turbine.Engine.GetGameTime() + TOAST_SECS
    t.win:SetVisible(true)
    t.timer:SetWantsUpdates(true)
    return true
end

-- lo llama worldmap_quests.lua cuando el canal Regional dice que se entro a
-- otra zona (nombre_original del mapa)
function D.OnEnterZone(zoneName)
    pcall(function()
        local Z = WorldMapAddon.Data and WorldMapAddon.Data.Zones or nil
        if type(Z) ~= "table" or zoneName == nil then
            return
        end
        for _, z in ipairs(Z) do
            if z.nombre_original == zoneName then
                D.ShowZoneToast(z)
                return
            end
        end
    end)
end

-- al cargar el plugin: primera lectura (asincronica) de todo
D.Init()
pcall(D.RefreshStatus, true)
