-- WorldMap_Addon/worldmap_gather.lua
--
-- v3.15 (pedido del usuario): ventana propia "Recoleccion", SOLO para los
-- puntos de recoleccion que va guardando Quest Assistant (GatherPointsStore,
-- por personaje). Como la ventana de la version anterior: pestañas por
-- profesion, selector de zona y el mapa de la zona con tus puntos. Sin
-- MoorMap: la imagen y la formula de cada mapa salen de los datos de este
-- addon (worldmap_zonemaps_data + MapCal) y, si un mapa no estuviera aca,
-- de los datos propios de Quest Assistant (MoorMapZones).
--
-- Clic en un punto = el Mapa del Mundo lo marca con la flecha roja.
-- Todo lo que toca la API va en pcall: si algo fallara, no rompe el mapa.

import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WorldMapAddon = _G.WorldMapAddon or {}

local G = {}
WorldMapAddon.Gather = G

local RES = "WorldMap_Addon/assets/worldmap/icon/"
local SAVE_KEY = "WorldMap_Recoleccion"
local W_DEF, H_DEF = 760, 600
local W_MIN, H_MIN = 560, 420
local PAD = 12
local TOP = 40            -- debajo del titulo de la ventana
local TAB_H = 30
local TAB_GAP = 4
local ZONE_H = 26
local ROW_GAP = 6
local STATUS_H = 22
local MARK = 24
local MARK_MAX = 300
local ROW_H = 24
local FLY_ROWS = 8
local POLL = 2            -- s entre repasos de puntos nuevos

local PROFS = {
    { key = "*", icon = "recoleccion", es = "Todas", en = "All" },
    { key = "MINERO", icon = "rec_minero", es = "Minero", en = "Prospector" },
    { key = "LE\195\145ADOR", icon = "rec_lenador", es = "Le\195\177ador", en = "Forester" },
    { key = "ERUDITO", icon = "rec_erudito", es = "Erudito", en = "Scholar" },
    { key = "GRANJERO", icon = "rec_granjero", es = "Granjero", en = "Farmer" },
}
local PROF_BY = {}
for _, p in ipairs(PROFS) do
    PROF_BY[p.key] = p
end

local GOLD = Turbine.UI.Color(1, 0.79, 0.65, 0.42)
local TEXT = Turbine.UI.Color(1, 0.94, 0.90, 0.80)
local TEXT_HI = Turbine.UI.Color(1, 1.0, 0.91, 0.66)
local TEXT_OFF = Turbine.UI.Color(1, 0.62, 0.58, 0.50)
local DARK = Turbine.UI.Color(1, 0.06, 0.05, 0.03)
local TAB_BG = Turbine.UI.Color(1, 0.13, 0.11, 0.08)
local TAB_ON = Turbine.UI.Color(1, 0.33, 0.24, 0.10)
local FLY_BG = Turbine.UI.Color(1, 0.10, 0.09, 0.07)

local function IsES()
    local ok, es = pcall(function()
        local LS = _G.LanguageSettings
        if LS == nil or LS.IsSpanish == nil then
            return true
        end
        return LS.IsSpanish() == true
    end)
    if not ok then
        return true
    end
    return es
end

local function Font(name, fallback)
    local FT = Turbine.UI.Lotro.Font
    return FT[name] or FT[fallback] or FT.Verdana12
end

local function Points()
    local S = _G.GatherPointsStore
    if type(S) == "table" and type(S.Points) == "table" then
        return S.Points
    end
    return nil
end

-- firma barata para saber si cambio algo (punto nuevo o visto otra vez)
local function Sig()
    local pts = Points()
    if pts == nil then
        return "-"
    end
    local n, seen = 0, 0
    for _, zones in pairs(pts) do
        if type(zones) == "table" then
            for _, list in pairs(zones) do
                if type(list) == "table" then
                    for _, pt in pairs(list) do
                        n = n + 1
                        seen = seen + (tonumber(type(pt) == "table" and pt.timesSeen) or 1)
                    end
                end
            end
        end
    end
    return n .. ":" .. seen
end

-- imagen, tamaño y formula (pixel = coord * factor + offset) de un mapa
local function MapInfo(mid)
    local es = IsES()
    local ZD = WorldMapAddon.ZoneMapsData
    local CAL = WorldMapAddon.MapCal
    local m = ZD ~= nil and ZD.Maps ~= nil and ZD.Maps[mid] or nil
    local c = type(CAL) == "table" and CAL[mid] or nil
    if m ~= nil and type(c) == "table" and c[1] ~= nil and c[1] ~= 0 then
        local name = es and (m.es or m.en) or (m.en or m.es)
        return { img = m.img, w = m.w or 1024, h = m.h or 768, hf = c[1], ho = c[2], vf = c[3], vo = c[4], name = name or ("#" .. tostring(mid)) }
    end
    local R = _G.MoorMapZoneResolver
    if R ~= nil and R.GetByIdx ~= nil then
        local ok, z = pcall(R.GetByIdx, mid)
        if ok and type(z) == "table" and z.image ~= nil and z.hFactor ~= nil and z.hFactor ~= 0 then
            local name = z.name
            if R.DisplayName ~= nil then
                local okN, n = pcall(R.DisplayName, z.name)
                if okN and n ~= nil then
                    name = n
                end
            end
            return { img = z.image, w = z.width or 1024, h = z.height or 768, hf = z.hFactor, ho = z.hOffset, vf = z.vFactor, vo = z.vOffset, name = tostring(name or ("#" .. tostring(mid))) }
        end
    end
    return nil
end

-- puntos de la profesion (o "*" = todas), por mapa: { [mid] = { {prof, pt}, ... } }
local function Collect(prof)
    local out = {}
    local pts = Points()
    if pts == nil then
        return out
    end
    for pk, zones in pairs(pts) do
        if (prof == "*" or pk == prof) and type(zones) == "table" then
            for idx, list in pairs(zones) do
                local mid = tonumber(idx)
                if mid ~= nil and type(list) == "table" then
                    for _, pt in pairs(list) do
                        if type(pt) == "table" and tonumber(pt.ns) ~= nil and tonumber(pt.ew) ~= nil then
                            out[mid] = out[mid] or {}
                            table.insert(out[mid], { prof = pk, pt = pt })
                        end
                    end
                end
            end
        end
    end
    return out
end
G.Collect = Collect
G.MapInfo = MapInfo

local function CountAll(prof)
    local n = 0
    for _, list in pairs(Collect(prof)) do
        n = n + #list
    end
    return n
end

-- ---------------------------------------------------------------------
-- Ventana
-- ---------------------------------------------------------------------
local Win = {}
Win.__index = Win

function Win.New()
    local self = setmetatable({}, Win)
    self.prof = "*"
    self.mid = nil
    self.panX, self.panY = 0, 0
    self.mapW, self.mapH = 0, 0
    self.markers = {}
    self.sig = nil
    self.pollAt = 0
    self.dirty = false
    local this = self

    local w = Turbine.UI.Lotro.Window()
    self.win = w
    w:SetSize(W_DEF, H_DEF)
    w:SetPosition(math.floor((Turbine.UI.Display.GetWidth() - W_DEF) / 2), math.floor((Turbine.UI.Display.GetHeight() - H_DEF) / 2))
    w:SetText("Recolecci\195\179n")
    pcall(function() w:SetResizable(true) end)
    pcall(function() w:SetMinimumSize(W_MIN, H_MIN) end)
    w:SetVisible(false)

    -- pestañas de profesion
    self.tabs = {}
    for i, p in ipairs(PROFS) do
        local t = { def = p }
        local c = Turbine.UI.Control()
        c:SetParent(w)
        c:SetSize(120, TAB_H)
        c:SetBackColor(TAB_BG)
        c:SetMouseVisible(true)
        t.ctl = c
        local ic = Turbine.UI.Control()
        ic:SetParent(c)
        ic:SetPosition(6, math.floor((TAB_H - 24) / 2))
        ic:SetSize(24, 24)
        ic:SetBackground(RES .. "fl_" .. p.icon .. "_pin.tga")
        ic:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        ic:SetMouseVisible(false)
        t.icon = ic
        local lb = Turbine.UI.Label()
        lb:SetParent(c)
        lb:SetPosition(34, 0)
        lb:SetSize(80, TAB_H)
        lb:SetFont(Font("Verdana12", "Verdana12"))
        lb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        lb:SetMouseVisible(false)
        lb:SetSelectable(false)
        t.label = lb
        c.MouseEnter = function() lb:SetForeColor(TEXT_HI) end
        c.MouseLeave = function() this:_paintTabs() end
        c.MouseClick = function()
            this:SetProfession(p.key)
        end
        self.tabs[i] = t
    end

    -- selector de zona
    self.btnZone = Turbine.UI.Lotro.Button()
    self.btnZone:SetParent(w)
    self.btnZone:SetSize(300, ZONE_H)
    self.btnZone.MouseClick = function()
        this:_setFlyout(not this.flyVisible)
    end

    -- mapa (lo de afuera del recuadro no se ve)
    self.view = Turbine.UI.Control()
    self.view:SetParent(w)
    self.view:SetBackColor(DARK)
    self.view:SetMouseVisible(false)
    self.map = Turbine.UI.Control()
    self.map:SetParent(self.view)
    self.map:SetMouseVisible(true)
    self.map.MouseDown = function(sender, args)
        this.dragging = true
        this.dragX, this.dragY = args.X, args.Y
        this.dragPX, this.dragPY = this.panX, this.panY
    end
    self.map.MouseMove = function(sender, args)
        if this.dragging then
            -- args es relativo al mapa, que se mueve: se compensa
            local dx = args.X + this.panX - this.dragPX - this.dragX
            local dy = args.Y + this.panY - this.dragPY - this.dragY
            this.panX = this.dragPX + dx
            this.panY = this.dragPY + dy
            this:_clampPan()
            this:_applyPan()
        end
    end
    self.map.MouseUp = function()
        this.dragging = false
    end
    -- (si el boton se suelta fuera del mapa no llega MouseUp: se corta aca)
    self.map.MouseLeave = function()
        this.dragging = false
    end

    self.empty = Turbine.UI.Label()
    self.empty:SetParent(self.view)
    self.empty:SetFont(Font("BookAntiquaBold16", "Verdana14"))
    self.empty:SetForeColor(TEXT_OFF)
    self.empty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.empty:SetMultiline(true)
    self.empty:SetMouseVisible(false)
    self.empty:SetVisible(false)

    -- lista de zonas (desplegable)
    self.fly = Turbine.UI.Control()
    self.fly:SetParent(w)
    self.fly:SetBackColor(GOLD)
    self.fly:SetVisible(false)
    self.flyInner = Turbine.UI.Control()
    self.flyInner:SetParent(self.fly)
    self.flyInner:SetPosition(1, 1)
    self.flyInner:SetBackColor(FLY_BG)
    self.flyList = Turbine.UI.ListBox()
    self.flyList:SetParent(self.flyInner)
    self.flyList:SetPosition(0, 0)
    self.flyBar = Turbine.UI.Lotro.ScrollBar()
    self.flyBar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.flyBar:SetParent(self.flyInner)
    self.flyList:SetVerticalScrollBar(self.flyBar)
    self.flyVisible = false

    -- linea de abajo
    self.status = Turbine.UI.Label()
    self.status:SetParent(w)
    self.status:SetFont(Font("Verdana12", "Verdana12"))
    self.status:SetForeColor(TEXT_OFF)
    self.status:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.status:SetMouseVisible(false)

    -- cartel del punto (ventana chica, sin mouse, encima de todo)
    local tw = Turbine.UI.Window()
    tw:SetSize(260, 60)
    tw:SetBackColor(GOLD)
    tw:SetZOrder(0x7FFFFFFF)
    tw:SetMouseVisible(false)
    tw:SetVisible(false)
    local inner = Turbine.UI.Label()
    inner:SetParent(tw)
    inner:SetPosition(1, 1)
    inner:SetSize(258, 58)
    inner:SetBackColor(DARK)
    inner:SetForeColor(TEXT)
    inner:SetFont(Font("Verdana12", "Verdana12"))
    inner:SetMultiline(true)
    inner:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    inner:SetMouseVisible(false)
    self.tipWin, self.tipLabel = tw, inner

    w.SizeChanged = function()
        pcall(function() this:_layout() end)
        this.dirty = true
    end
    w.PositionChanged = function()
        this.dirty = true
    end
    w.VisibleChanged = function()
        local v = w:IsVisible()
        w:SetWantsUpdates(v)
        if not v then
            this:_hideTip()
            this:_setFlyout(false)
            this:_save()
        end
    end
    w.Update = function()
        local now = Turbine.Engine.GetGameTime()
        if now < this.pollAt then
            return
        end
        this.pollAt = now + POLL
        pcall(function()
            if Sig() ~= this.sig then
                this:Refresh(true)
            end
        end)
    end

    self:_layout()
    self:Refresh(false)
    self:_load()
    return self
end

function Win:_layout()
    local W, H = self.win:GetSize()
    local x = PAD
    local avail = W - 2 * PAD - TAB_GAP * (#self.tabs - 1)
    local tw = math.floor(avail / #self.tabs)
    for i, t in ipairs(self.tabs) do
        t.ctl:SetPosition(PAD + (i - 1) * (tw + TAB_GAP), TOP)
        t.ctl:SetSize(tw, TAB_H)
        t.label:SetSize(math.max(20, tw - 38), TAB_H)
    end
    local zy = TOP + TAB_H + ROW_GAP
    self.btnZone:SetPosition(PAD, zy)
    self.btnZone:SetSize(W - 2 * PAD, ZONE_H)
    local vy = zy + ZONE_H + ROW_GAP
    local vh = H - vy - STATUS_H - 16
    if vh < 80 then
        vh = 80
    end
    self.view:SetPosition(PAD, vy)
    self.view:SetSize(W - 2 * PAD, vh)
    self.empty:SetPosition(10, 0)
    self.empty:SetSize(W - 2 * PAD - 20, vh)
    self.status:SetPosition(PAD, vy + vh + 4)
    self.status:SetSize(W - 2 * PAD, STATUS_H)
    -- desplegable debajo del boton de zona
    local fw = W - 2 * PAD
    self.fly:SetPosition(PAD, zy + ZONE_H + 2)
    self.fly:SetWidth(fw)
    self.flyInner:SetWidth(fw - 2)
    self.flyList:SetWidth(fw - 16)
    self.flyBar:SetPosition(fw - 14, 0)
    self:_sizeFlyout()
    self:_clampPan()
    self:_applyPan()
end

function Win:_sizeFlyout()
    local n = self.flyCount or 1
    if n < 1 then n = 1 end
    if n > FLY_ROWS then n = FLY_ROWS end
    local h = n * ROW_H
    self.fly:SetHeight(h + 2)
    self.flyInner:SetHeight(h)
    self.flyList:SetHeight(h)
    self.flyBar:SetSize(10, h)
end

function Win:_setFlyout(v)
    self.flyVisible = v and true or false
    self.fly:SetVisible(self.flyVisible)
    -- (igual que la ventana anterior: el mapa se esconde mientras se elige)
    self.view:SetVisible(not self.flyVisible)
    if self.flyVisible then
        self:_hideTip()
    end
end

function Win:_paintTabs()
    local es = IsES()
    for _, t in ipairs(self.tabs) do
        local on = t.def.key == self.prof
        local n = CountAll(t.def.key)
        t.label:SetText((es and t.def.es or t.def.en) .. " (" .. n .. ")")
        t.label:SetForeColor(on and TEXT_HI or (n > 0 and TEXT or TEXT_OFF))
        t.ctl:SetBackColor(on and TAB_ON or TAB_BG)
    end
end

function Win:_clampPan()
    local vw, vh = self.view:GetSize()
    local mw, mh = self.mapW, self.mapH
    if mw <= 0 or mh <= 0 then
        self.panX, self.panY = 0, 0
        return
    end
    if mw <= vw then
        self.panX = math.floor((vw - mw) / 2)
    else
        if self.panX > 0 then self.panX = 0 end
        if self.panX < vw - mw then self.panX = vw - mw end
    end
    if mh <= vh then
        self.panY = math.floor((vh - mh) / 2)
    else
        if self.panY > 0 then self.panY = 0 end
        if self.panY < vh - mh then self.panY = vh - mh end
    end
end

function Win:_applyPan()
    self.map:SetPosition(math.floor(self.panX), math.floor(self.panY))
end

function Win:_centerOn(px, py)
    local vw, vh = self.view:GetSize()
    self.panX = math.floor(vw / 2 - px)
    self.panY = math.floor(vh / 2 - py)
    self:_clampPan()
    self:_applyPan()
end

-- zonas con puntos de la profesion elegida, por nombre
function Win:_zones(data)
    local list = {}
    for mid, pts in pairs(data) do
        local info = MapInfo(mid)
        if info ~= nil then
            list[#list + 1] = { mid = mid, name = info.name, count = #pts }
        end
    end
    table.sort(list, function(a, b)
        if a.name ~= b.name then
            return a.name < b.name
        end
        return a.mid < b.mid
    end)
    return list
end

function Win:_buildFlyout(zones)
    self.flyList:ClearItems()
    local fw = self.fly:GetWidth()
    local es = IsES()
    local this = self
    self.flyCount = #zones
    if #zones == 0 then
        local lb = Turbine.UI.Label()
        lb:SetSize(fw - 16, ROW_H)
        lb:SetFont(Font("Verdana12", "Verdana12"))
        lb:SetForeColor(TEXT_OFF)
        lb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        lb:SetText(es and "  Sin puntos guardados" or "  No saved points")
        self.flyList:AddItem(lb)
    end
    for _, z in ipairs(zones) do
        local lb = Turbine.UI.Label()
        lb:SetSize(fw - 16, ROW_H)
        lb:SetFont(Font("Verdana12", "Verdana12"))
        lb:SetForeColor(z.mid == self.mid and TEXT_HI or TEXT)
        lb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        lb:SetText("  " .. z.name .. "  (" .. z.count .. ")")
        lb:SetMouseVisible(true)
        lb.MouseEnter = function() lb:SetBackColor(TAB_BG) end
        lb.MouseLeave = function() lb:SetBackColor(Turbine.UI.Color(0, 0, 0, 0)) end
        lb.MouseClick = function()
            this.mid = z.mid
            this.dirty = true
            this:_setFlyout(false)
            this:Refresh(false)
        end
        self.flyList:AddItem(lb)
    end
    self:_sizeFlyout()
end

function Win:_marker(i)
    local m = self.markers[i]
    if m ~= nil then
        return m
    end
    local this = self
    m = { vis = false }
    local c = Turbine.UI.Control()
    c:SetParent(self.map)
    c:SetSize(MARK, MARK)
    c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    c:SetMouseVisible(true)
    c:SetVisible(false)
    m.ctl = c
    c.MouseEnter = function()
        if m.icon ~= nil then
            c:SetBackground(RES .. "fl_" .. m.icon .. "_pin_hl.tga")
        end
        this:_showTip(m)
    end
    c.MouseLeave = function()
        if m.icon ~= nil then
            c:SetBackground(RES .. "fl_" .. m.icon .. "_pin.tga")
        end
        this:_hideTip()
    end
    c.MouseClick = function()
        -- clic = el Mapa del Mundo lo marca con la flecha roja
        if m.ns ~= nil and WorldMapAddon.ShowPoint ~= nil then
            pcall(WorldMapAddon.ShowPoint, m.ns, m.ew, this.mid, m.node)
        end
    end
    self.markers[i] = m
    return m
end

function Win:_showTip(m)
    local okC, shown = pcall(function() return self:_showCard(m) end)
    if okC and shown == true then
        return
    end
    pcall(function()
        self.tipLabel:SetText(m.text or "")
        local lines = 1
        for _ in string.gmatch(m.text or "", "\n") do
            lines = lines + 1
        end
        local h = lines * 15 + 10
        self.tipWin:SetSize(260, h + 2)
        self.tipLabel:SetSize(258, h)
        local sx, sy = m.ctl:PointToScreen(0, 0)
        local x = sx + MARK + 6
        local y = sy - 4
        local sw, sh = Turbine.UI.Display.GetWidth(), Turbine.UI.Display.GetHeight()
        if x + 260 > sw then x = sx - 266 end
        if y + h > sh then y = sh - h - 2 end
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end
        self.tipWin:SetPosition(x, y)
        self.tipWin:SetVisible(true)
    end)
end

function Win:_hideTip()
    pcall(function() self.tipWin:SetVisible(false) end)
    if self.card ~= nil then
        pcall(function() self.card.win:SetVisible(false) end)
    end
end

local function Coord(ns, ew)
    local a = string.format("%.1f", math.abs(ns)):gsub(",", ".")
    local b = string.format("%.1f", math.abs(ew)):gsub(",", ".")
    return a .. (ns < 0 and "S" or "N") .. ", " .. b .. (ew < 0 and "O" or "E")
end

-- ---------------------------------------------------------------------
-- v3.15.1 (pedido del usuario): tarjeta detallada al pasar el mouse, con
-- el mismo estilo que las del Mapa del Mundo (esquinas redondeadas, barra
-- de color, icono, titulo, subtitulo, pastillas y lineas).
-- ---------------------------------------------------------------------
local CARD_W = 290
local CARD_R = 12
local CARD_PAD = 18
local CARD_LINE_H = 16
local CARD_BG = Turbine.UI.Color(0.96, 16 / 255, 18 / 255, 24 / 255)
local CARD_BORDER = Turbine.UI.Color(1, 60 / 255, 66 / 255, 80 / 255)
local DOT = " \194\183 "
local PROF_ACCENT = {
    MINERO = { 205, 150, 90 }, ["LE\195\145ADOR"] = { 120, 200, 90 },
    ERUDITO = { 150, 175, 255 }, GRANJERO = { 255, 150, 60 },
}
local ACCENT_DEF = { 150, 160, 180 }
local PILL = {
    green = { "green", { 140, 240, 170 }, { 22, 70, 40 } },
    amber = { "amber", { 255, 200, 90 }, { 90, 60, 10 } },
    blue = { "blue", { 160, 200, 255 }, { 30, 45, 70 } },
}
-- rango del nodo (como lo guarda Quest Assistant) en español
local RANK_ES = {
    Apprentice = "Aprendiz", Journeyman = "Oficial", Expert = "Experto", Artisan = "Artesano",
    Master = "Maestro", Supreme = "Supremo", Westfold = "Folde Oeste", Eastemnet = "Estemnet",
    Westemnet = "Oestemnet", Doomfold = "Doomfold", Ironfold = "Pliegue de Hierro",
    Minas = "Minas Ithil", Gundabad = "Gundabad", ["Falathlorn"] = "Falathlorn",
}

local function RGB(t, a)
    return Turbine.UI.Color(a or 1, t[1] / 255, t[2] / 255, t[3] / 255)
end

-- ancho aproximado de un texto (en el juego no se puede medir)
local function TextW(text, px)
    local n = 0
    for _ in tostring(text or ""):gmatch("[^\128-\191]") do
        n = n + 1
    end
    return math.floor(n * (px or 6.6) + 0.5)
end

local function TextLines(text, w, px)
    local per = math.max(1, math.floor(w / (px or 6.9)))
    local n = 0
    for part in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        local len = 0
        for _ in part:gmatch("[^\128-\191]") do
            len = len + 1
        end
        n = n + math.max(1, math.ceil(len / per))
    end
    return math.max(1, n)
end

function Win:_buildCard()
    local c = {}
    local win = Turbine.UI.Window()
    win:SetSize(CARD_W, 100)
    win:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    win:SetZOrder(0x7FFFFFFF)
    win:SetMouseVisible(false)
    win:SetVisible(false)
    c.win = win
    local function box(color)
        local k = Turbine.UI.Control()
        k:SetParent(win)
        k:SetMouseVisible(false)
        if color ~= nil then
            k:SetBackColor(color)
        end
        return k
    end
    local function img(file, w, h)
        local k = Turbine.UI.Control()
        k:SetParent(win)
        k:SetSize(w, h)
        if file ~= nil then
            k:SetBackground(RES .. file)
        end
        k:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        k:SetMouseVisible(false)
        return k
    end
    local function label(font, color, align)
        local l = Turbine.UI.Label()
        l:SetParent(win)
        l:SetFont(font)
        l:SetForeColor(color)
        l:SetTextAlignment(align or Turbine.UI.ContentAlignment.TopLeft)
        l:SetMouseVisible(false)
        return l
    end
    c.tl = img("card_tl.tga", CARD_R, CARD_R)
    c.tr = img("card_tr.tga", CARD_R, CARD_R)
    c.bl = img("card_bl.tga", CARD_R, CARD_R)
    c.br = img("card_br.tga", CARD_R, CARD_R)
    c.top, c.mid, c.bot = box(CARD_BG), box(CARD_BG), box(CARD_BG)
    c.lineT, c.lineB, c.lineL, c.lineR = box(CARD_BORDER), box(CARD_BORDER), box(CARD_BORDER), box(CARD_BORDER)
    c.accent = box(RGB(ACCENT_DEF))
    c.iconBg = box(Turbine.UI.Color(1, 0.12, 0.13, 0.17))
    c.icon = img(nil, 24, 24)
    local V12 = Font("Verdana12", "Verdana12")
    c.title = label(Font("Verdana16", "Verdana14"), Turbine.UI.Color(1, 0.96, 0.97, 1))
    c.title:SetMultiline(true)
    c.sub = label(V12, Turbine.UI.Color(1, 0.55, 0.67, 0.82))
    c.sub:SetMultiline(true)
    c.pills = {}
    for i = 1, 3 do
        c.pills[i] = { l = img("card_blue_l.tga", 9, 18), r = img("card_blue_r.tga", 9, 18), m = box(),
            t = label(Font("Verdana10", "Verdana12"), Turbine.UI.Color(1, 1, 1, 1), Turbine.UI.ContentAlignment.MiddleCenter) }
    end
    c.lines = {}
    for i = 1, 4 do
        c.lines[i] = label(V12, Turbine.UI.Color(1, 0.78, 0.81, 0.85))
        c.lines[i]:SetMultiline(true)
    end
    self.card = c
end

-- datos de la tarjeta de un marcador
local function CardSpec(m, es)
    local d = m.card or {}
    local pt = d.pt or {}
    local p = PROF_BY[d.prof]
    local spec = { pills = {}, lines = {} }
    spec.icon = m.icon
    spec.accent = PROF_ACCENT[d.prof] or ACCENT_DEF
    spec.title = tostring(pt.node or m.node or "?")
    local pname = p ~= nil and (es and p.es or p.en) or tostring(d.prof or "")
    spec.sub = pname .. ((d.mapName ~= nil and d.mapName ~= "") and (DOT .. d.mapName) or "")
    local tier = tonumber(pt.tier)
    if tier ~= nil then
        spec.pills[#spec.pills + 1] = { (es and "Nivel " or "Tier ") .. tier, "blue" }
    else
        spec.pills[#spec.pills + 1] = { es and "Nivel ?" or "Tier ?", "blue" }
    end
    local times = tonumber(pt.timesSeen) or 1
    if times > 1 then
        spec.pills[#spec.pills + 1] = { es and ("Visto " .. times .. " veces") or ("Seen " .. times .. " times"), "green" }
    else
        spec.pills[#spec.pills + 1] = { es and "Visto 1 vez" or "Seen once", "green" }
    end
    if pt.confidence == "media" or pt.confidence == "baja" then
        spec.pills[#spec.pills + 1] = { es and "Sin confirmar" or "Unconfirmed", "amber" }
    end
    local rank = type(pt.zone) == "string" and pt.zone or ""
    if rank ~= "" and rank ~= "sin catalogar" then
        spec.lines[#spec.lines + 1] = { (es and "Rango: " or "Rank: ") .. (es and (RANK_ES[rank] or rank) or rank), { 200, 206, 218 } }
    end
    spec.lines[#spec.lines + 1] = { (es and "Coordenadas: " or "Coordinates: ") .. Coord(m.ns, m.ew), { 200, 206, 218 } }
    spec.lines[#spec.lines + 1] = { es and "Clic: marcar en el Mapa del Mundo" or "Click: mark it on the World Map", { 140, 240, 170 } }
    return spec
end

function Win:_showCard(m)
    if m == nil or m.card == nil then
        return false
    end
    if self.card == nil then
        self:_buildCard()
    end
    local c = self.card
    local es = IsES()
    local spec = CardSpec(m, es)
    local W = CARD_W
    local inner = W - CARD_PAD - 16
    -- icono en su recuadro
    c.iconBg:SetPosition(14, 12)
    c.iconBg:SetSize(34, 34)
    c.icon:SetBackground(RES .. "fl_" .. spec.icon .. "_pin.tga")
    c.icon:SetPosition(19, 17)
    local textX = 56
    local textW = W - textX - 12
    local tl = math.min(3, TextLines(spec.title, textW, 8.4))
    c.title:SetText(spec.title)
    c.title:SetPosition(textX, 12)
    c.title:SetSize(textW, tl * 20)
    local sl = math.min(2, TextLines(spec.sub, textW, 6.9))
    c.sub:SetText(spec.sub)
    c.sub:SetPosition(textX, 14 + tl * 20)
    c.sub:SetSize(textW, sl * 16)
    local y = math.max(56, 14 + tl * 20 + sl * 16 + 8)
    -- pastillas
    local px = CARD_PAD
    local npill = 0
    for i, pl in ipairs(c.pills) do
        local d = spec.pills[i]
        local st = d ~= nil and PILL[d[2]] or nil
        local w = d ~= nil and (TextW(d[1], 6.2) + 8) or 0
        local on = st ~= nil and (px + w + 18 <= CARD_PAD + inner)
        pl.l:SetVisible(on); pl.r:SetVisible(on); pl.m:SetVisible(on); pl.t:SetVisible(on)
        if on then
            npill = npill + 1
            pl.l:SetBackground(RES .. "card_" .. st[1] .. "_l.tga")
            pl.r:SetBackground(RES .. "card_" .. st[1] .. "_r.tga")
            pl.m:SetBackColor(RGB(st[3]))
            pl.l:SetPosition(px, y)
            pl.m:SetPosition(px + 9, y)
            pl.m:SetSize(w, 18)
            pl.r:SetPosition(px + 9 + w, y)
            pl.t:SetText(d[1])
            pl.t:SetForeColor(RGB(st[2]))
            pl.t:SetPosition(px + 9, y)
            pl.t:SetSize(w, 18)
            px = px + w + 18 + 6
        end
    end
    if npill > 0 then
        y = y + 26
    end
    -- lineas
    for i, lbl in ipairs(c.lines) do
        local l = spec.lines[i]
        if l == nil then
            lbl:SetVisible(false)
        else
            if i == #spec.lines then
                y = y + 4
            end
            local h = TextLines(l[1], inner, 6.9) * CARD_LINE_H
            lbl:SetText(l[1])
            lbl:SetForeColor(RGB(l[2]))
            lbl:SetPosition(CARD_PAD, y)
            lbl:SetSize(inner, h)
            lbl:SetVisible(true)
            y = y + h
        end
    end
    local H = math.max(y + 10, 2 * CARD_R + 40)
    c.win:SetSize(W, H)
    c.tl:SetPosition(0, 0)
    c.tr:SetPosition(W - CARD_R, 0)
    c.bl:SetPosition(0, H - CARD_R)
    c.br:SetPosition(W - CARD_R, H - CARD_R)
    c.top:SetPosition(CARD_R, 0); c.top:SetSize(W - 2 * CARD_R, CARD_R)
    c.mid:SetPosition(0, CARD_R); c.mid:SetSize(W, H - 2 * CARD_R)
    c.bot:SetPosition(CARD_R, H - CARD_R); c.bot:SetSize(W - 2 * CARD_R, CARD_R)
    c.lineT:SetPosition(CARD_R, 0); c.lineT:SetSize(W - 2 * CARD_R, 1)
    c.lineB:SetPosition(CARD_R, H - 1); c.lineB:SetSize(W - 2 * CARD_R, 1)
    c.lineL:SetPosition(0, CARD_R); c.lineL:SetSize(1, H - 2 * CARD_R)
    c.lineR:SetPosition(W - 1, CARD_R); c.lineR:SetSize(1, H - 2 * CARD_R)
    c.accent:SetBackColor(RGB(spec.accent))
    c.accent:SetPosition(1, CARD_R)
    c.accent:SetSize(4, H - 2 * CARD_R)
    -- al lado del punto; si no entra, del otro lado / arriba
    local sx, sy = m.ctl:PointToScreen(0, 0)
    local x = sx + MARK + 8
    local yy = sy - 6
    local sw, sh = Turbine.UI.Display.GetWidth(), Turbine.UI.Display.GetHeight()
    if x + W > sw then x = sx - W - 8 end
    if yy + H > sh then yy = sh - H - 2 end
    if x < 0 then x = 0 end
    if yy < 0 then yy = 0 end
    c.win:SetPosition(x, yy)
    pcall(function() self.tipWin:SetVisible(false) end)
    c.win:SetVisible(true)
    return true
end


-- keepPan = true: no mueve la vista (punto nuevo mientras se mira)
function Win:Refresh(keepPan)
    local es = IsES()
    self.sig = Sig()
    if not keepPan then
        self:_hideTip()
    end
    self.win:SetText(es and "Recolecci\195\179n" or "Gathering")
    self:_paintTabs()
    for _, m in ipairs(self.markers) do
        if m.vis then
            m.vis = false
            m.ctl:SetVisible(false)
        end
    end
    local hasQA = Points() ~= nil
    local data = Collect(self.prof)
    local zones = self:_zones(data)
    -- zona elegida: la misma si sigue teniendo puntos, si no la de mas puntos
    local cur = nil
    for _, z in ipairs(zones) do
        if z.mid == self.mid then
            cur = z
        end
    end
    if cur == nil then
        for _, z in ipairs(zones) do
            if cur == nil or z.count > cur.count then
                cur = z
            end
        end
        keepPan = false
    end
    self.mid = cur ~= nil and cur.mid or nil
    self:_buildFlyout(zones)

    if cur == nil then
        self.mapW, self.mapH = 0, 0
        self.map:SetVisible(false)
        self.btnZone:SetText(es and "Zona: (ninguna)" or "Zone: (none)")
        if not hasQA then
            self.empty:SetText(es and "Hace falta Quest Assistant: es el que guarda tus puntos de recolecci\195\179n."
                or "Quest Assistant is needed: it saves your gathering points.")
        else
            self.empty:SetText(es and "Todav\195\173a no hay puntos guardados.\nAl recolectar, Quest Assistant muestra un bot\195\179n para guardar el lugar."
                or "No saved points yet.\nWhen you gather, Quest Assistant shows a button to save the spot.")
        end
        self.empty:SetVisible(true)
        self.status:SetText("")
        return
    end

    local info = MapInfo(cur.mid)
    self.empty:SetVisible(false)
    self.map:SetVisible(true)
    self.btnZone:SetText((es and "Zona: " or "Zone: ") .. cur.name .. "   (" .. cur.count .. (es and (cur.count == 1 and " punto)" or " puntos)") or (cur.count == 1 and " point)" or " points)")))
    self.mapW, self.mapH = info.w, info.h
    self.map:SetSize(info.w, info.h)
    if self.mapImg ~= info.img then
        self.mapImg = info.img
        pcall(function() self.map:SetBackground(info.img) end)
    end

    local n, sx, sy, off = 0, 0, 0, 0
    for _, e in ipairs(data[cur.mid] or {}) do
        local pt = e.pt
        local ns, ew = tonumber(pt.ns), tonumber(pt.ew)
        local x = ew * info.hf + info.ho
        local y = ns * info.vf + info.vo
        if not (x >= 0 and y >= 0 and x <= info.w and y <= info.h) then
            off = off + 1
        elseif n < MARK_MAX then
            n = n + 1
            local m = self:_marker(n)
            local p = PROF_BY[e.prof]
            m.icon = p ~= nil and p.icon or "recoleccion"
            m.ns, m.ew = ns, ew
            m.node = tostring(pt.node or "?")
            local pname = p ~= nil and (es and p.es or p.en) or tostring(e.prof)
            local tier = tonumber(pt.tier)
            local times = tonumber(pt.timesSeen) or 1
            local lines = { m.node, pname .. (tier and ((es and " - nivel " or " - tier ") .. tier) or "") }
            if times > 1 then
                lines[#lines + 1] = es and ("Visto " .. times .. " veces") or ("Seen " .. times .. " times")
            end
            lines[#lines + 1] = Coord(ns, ew)
            lines[#lines + 1] = es and "(clic: marcar en el Mapa del Mundo)" or "(click: mark on the World Map)"
            m.text = table.concat(lines, "\n")
            m.card = { prof = e.prof, pt = pt, mapName = info.name }
            m.ctl:SetBackground(RES .. "fl_" .. m.icon .. "_pin.tga")
            -- el icono entero siempre dentro del mapa (punto pegado al borde)
            local mx = math.floor(x - MARK / 2 + 0.5)
            local my = math.floor(y - MARK / 2 + 0.5)
            mx = math.max(0, math.min(mx, info.w - MARK))
            my = math.max(0, math.min(my, info.h - MARK))
            m.ctl:SetPosition(mx, my)
            m.ctl:SetVisible(true)
            m.vis = true
            sx, sy = sx + x, sy + y
        end
    end
    if not keepPan then
        if n > 0 then
            self:_centerOn(sx / n, sy / n)
        else
            self:_centerOn(info.w / 2, info.h / 2)
        end
    else
        self:_clampPan()
        self:_applyPan()
    end
    local st = es and ("Arrastra para mover el mapa  -  clic en un punto: marcarlo en el Mapa del Mundo  -  " .. n .. " en este mapa")
        or ("Drag to move the map  -  click a point: mark it on the World Map  -  " .. n .. " on this map")
    if off > 0 then
        -- (no deberia pasar: el punto se guardo en un mapa que no lo dibuja)
        st = st .. (es and ("  -  " .. off .. " fuera del dibujo") or ("  -  " .. off .. " off the drawing"))
    end
    self.status:SetText(st)
end

function Win:SetProfession(key)
    if PROF_BY[key] == nil then
        return
    end
    self.prof = key
    self.dirty = true
    self:_setFlyout(false)
    self:Refresh(false)
end

function Win:_save()
    if not self.dirty then
        return
    end
    self.dirty = false
    pcall(function()
        local x, y = self.win:GetPosition()
        local w, h = self.win:GetSize()
        Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, {
            v = 1, x = math.floor(x), y = math.floor(y), w = math.floor(w), h = math.floor(h),
            prof = self.prof, mid = self.mid,
        })
    end)
end

function Win:_load()
    local this = self
    pcall(function()
        Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(d)
            pcall(function()
                if type(d) ~= "table" then
                    return
                end
                local sw, sh = Turbine.UI.Display.GetWidth(), Turbine.UI.Display.GetHeight()
                local w, h = tonumber(d.w), tonumber(d.h)
                if w ~= nil and h ~= nil then
                    w = math.max(W_MIN, math.min(w, sw))
                    h = math.max(H_MIN, math.min(h, sh))
                    this.win:SetSize(w, h)
                end
                local x, y = tonumber(d.x), tonumber(d.y)
                if x ~= nil and y ~= nil then
                    local cw, ch = this.win:GetSize()
                    x = math.max(0, math.min(x, sw - cw))
                    y = math.max(0, math.min(y, sh - ch))
                    this.win:SetPosition(x, y)
                end
                if type(d.prof) == "string" and PROF_BY[d.prof] ~= nil then
                    this.prof = d.prof
                end
                this.mid = tonumber(d.mid)
                this:_layout()
                this:Refresh(false)
                this.dirty = false
            end)
        end)
    end)
end

function Win:Show()
    self:Refresh(false)
    self.win:SetVisible(true)
    pcall(function() self.win:Activate() end)
end

function Win:Hide()
    self.win:SetVisible(false)
end

function Win:IsVisible()
    return self.win:IsVisible()
end

-- ---------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------
function G.Get()
    if G.win == nil then
        G.win = Win.New()
    end
    return G.win
end

function G.Toggle()
    local ok, err = pcall(function()
        local w = G.Get()
        if w:IsVisible() then
            w:Hide()
        else
            w:Show()
        end
    end)
    if not ok then
        Turbine.Shell.WriteLine("<rgb=#FF0000>Mapa del Mundo: no se pudo abrir Recolecci\195\179n -- " .. tostring(err) .. "</rgb>")
    end
    return ok
end

function G.Show()
    return pcall(function() G.Get():Show() end)
end
