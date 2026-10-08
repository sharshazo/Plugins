-- WorldMap_Addon/worldmap_filters.lua
--
-- v3.2 (pedido del usuario): ventana "Filtros del Mapa" (diseno horizontal
-- del usuario, 4 columnas x 5 filas). Cada cuadro = casilla + icono +
-- nombre; clic en el cuadro = mostrar / ocultar esa clase de iconos en los
-- mapas de zona. Se guarda por cuenta (Turbine.PluginData, igual que el
-- filtro de expansiones) y sale en espanol o ingles segun el boton ES/EN de
-- Quest Assistant (sin Quest Assistant: espanol).
--
-- Fondo = el marco del diseno del usuario con las celdas vacias (los
-- textos los pone el addon para poder cambiar de idioma). Sin escalar
-- imagenes (en LOTRO estirar una imagen no es confiable): todo va a su
-- tamano real. Todo lo que toca la API va en pcall: si algo fallara, el
-- mapa sigue funcionando y los iconos se ven como siempre.

import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WorldMapAddon = _G.WorldMapAddon or {}

local F = {}
WorldMapAddon.Filters = F

local RES = "WorldMap_Addon/assets/worldmap/icon/"
local SAVE_KEY = "WorldMap_Filtros"
local PANEL_W, PANEL_H = 960, 320

-- orden = el del diseno (fila por fila). on = como viene la primera vez:
-- lo que ya mostraba el mapa queda encendido; lo nuevo y muy denso
-- (NPC, mineria, fauna, historia) empieza apagado.
F.Defs = {
    { key = "raid", icon = "raid", es = "Raids", en = "Raids", on = true },
    { key = "mob", icon = "mobs", es = "Matar monstruos", en = "Slayer areas", on = false },
    { key = "exp", icon = "exploracion", es = "Exploraci\195\179n", en = "Exploration", on = true },
    { key = "cof", icon = "cofre", es = "Cofres y tesoros", en = "Chests & treasure", on = true },
    { key = "jef", icon = "jefe", es = "Jefes", en = "Bosses", on = true },
    { key = "esb", icon = "establo_blanco", es = "Establos blancos", en = "Stables", on = true },
    { key = "esa", icon = "establo_azul", es = "Establos azules", en = "Far-ranging stables", on = true },
    { key = "mis", icon = "mision", es = "Misiones", en = "Quests", on = true },
    { key = "haz", icon = "hazana", es = "Haza\195\177as", en = "Deeds", on = true },
    { key = "his", icon = "historia", es = "Historia y saber", en = "Lore & landmarks", on = false },
    { key = "maz", icon = "mazmorra", es = "Mazmorras", en = "Dungeons", on = true },
    { key = "npc", icon = "npc", es = "NPC", en = "NPCs", on = false },
    { key = "min", icon = "mineria", es = "Miner\195\173a", en = "Mining", on = false },
    { key = "pes", icon = "pesca", es = "Pesca", en = "Fishing", on = true },
    { key = "fau", icon = "fauna", es = "Fauna", en = "Wildlife", on = false },
    { key = "cam", icon = "campamento", es = "Campamentos", en = "Campsites", on = true },
    { key = "via", icon = "viaje", es = "Puntos de viaje", en = "Travel points", on = true },
    -- v3.4: opcion (no es una capa): hazañas / exploracion / cofres ya
    -- completados. Apagado = no se ven en el mapa; encendido = gris con X.
    { key = "done", icon = "completadas", es = "Ver completadas", en = "Show completed", on = false, option = true },
}
F.ByKey = {}
for _, d in ipairs(F.Defs) do
    F.ByKey[d.key] = d
end

-- textos de los carteles: titulo de cada capa
F.Title = {
    exp = { es = "Exploraci\195\179n", en = "Exploration" },
    haz = { es = "Haza\195\177a (saber)", en = "Deed (lore)" },
    mob = { es = "Matar monstruos", en = "Slayer area" },
    cof = { es = "Cofre / tesoro", en = "Chest / treasure" },
    jef = { es = "Jefe", en = "Boss" },
    esb = { es = "Establo", en = "Stable-master" },
    esa = { es = "Establo de largo alcance", en = "Far-ranging Stable-master" },
    cam = { es = "Campamento", en = "Campsite" },
    via = { es = "Punto de viaje", en = "Travel point" },
    mis = { es = "Misi\195\179n activa", en = "Active quest" },
    npc = { es = "NPC de servicio", en = "Service NPCs" },
    min = { es = "Miner\195\173a (vetas)", en = "Mining (deposits)" },
    pes = { es = "Pesca", en = "Fishing" },
    fau = { es = "Fauna", en = "Wildlife" },
    his = { es = "Historia y saber", en = "Lore & landmarks" },
}

-- icono de cada capa en el mapa (caja 24x24, la punta abajo = el lugar)
F.LayerIcon = {
    exp = "exploracion", haz = "hazana", mob = "mobs", cof = "cofre", jef = "jefe", esb = "establo_blanco",
    esa = "establo_azul", cam = "campamento", via = "viaje", mis = "mision", npc = "npc", min = "mineria",
    pes = "pesca", fau = "fauna", his = "historia",
}

F.state = {}
for _, d in ipairs(F.Defs) do
    F.state[d.key] = d.on
end
F.listeners = {}
F.loaded = false

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
F.IsES = IsES

function F.IsOn(key)
    local v = F.state[key]
    if v == nil then
        return true
    end
    return v == true
end

function F.OnChange(fn)
    F.listeners[#F.listeners + 1] = fn
end

local function notify()
    for _, fn in ipairs(F.listeners) do
        pcall(fn)
    end
end

function F.Save()
    pcall(function()
        local on = {}
        for _, d in ipairs(F.Defs) do
            on[d.key] = F.state[d.key] == true
        end
        local data = { v = 1, on = on }
        if F.panelX ~= nil and F.panelY ~= nil then
            data.x = math.floor(F.panelX)
            data.y = math.floor(F.panelY)
        end
        Turbine.PluginData.Save(Turbine.DataScope.Account, SAVE_KEY, data)
    end)
end

function F.Load()
    if F.loadStarted then
        return
    end
    F.loadStarted = true
    pcall(function()
        Turbine.PluginData.Load(Turbine.DataScope.Account, SAVE_KEY, function(data)
            pcall(function()
                if type(data) == "table" and type(data.on) == "table" then
                    for _, d in ipairs(F.Defs) do
                        local v = data.on[d.key]
                        if v ~= nil then
                            F.state[d.key] = (v == true or v == 1 or v == "true")
                        end
                    end
                end
                if type(data) == "table" then
                    F.panelX = tonumber(data.x)
                    F.panelY = tonumber(data.y)
                end
            end)
            F.loaded = true
            if F.panel ~= nil then
                pcall(function() F.panel:Refresh() end)
            end
            notify()
        end)
    end)
end

function F.Set(key, on)
    if F.ByKey[key] == nil then
        return
    end
    F.state[key] = on and true or false
    F.Save()
    notify()
end

function F.SetAll(on)
    for _, d in ipairs(F.Defs) do
        if not d.option then
            F.state[d.key] = on and true or false
        end
    end
    F.Save()
    notify()
end

-- ---------------------------------------------------------------------
-- Ventana
-- ---------------------------------------------------------------------
-- cuadros del fondo (pixeles del panel; medidos sobre el diseno del usuario)
local CELLS = {
    { 15, 54, 228, 44 }, { 246, 54, 232, 44 }, { 482, 54, 232, 44 }, { 717, 54, 228, 44 },
    { 15, 101, 228, 46 }, { 246, 101, 232, 46 }, { 482, 101, 232, 46 }, { 717, 101, 228, 46 },
    { 15, 149, 228, 47 }, { 246, 149, 232, 47 }, { 482, 149, 232, 47 }, { 717, 149, 228, 47 },
    { 15, 199, 228, 47 }, { 246, 199, 232, 47 }, { 482, 199, 232, 47 }, { 717, 199, 228, 47 },
    { 15, 248, 228, 49 }, { 246, 248, 232, 49 }, { 482, 248, 232, 49 }, { 717, 248, 228, 49 },
}
local TITLE = { 95, 10, 770, 30 }
local GOLD = Turbine.UI.Color(1, 0.79, 0.65, 0.42)
local TEXT = Turbine.UI.Color(1, 0.94, 0.90, 0.80)
local TEXT_HI = Turbine.UI.Color(1, 1.0, 0.91, 0.66)
local TEXT_OFF = Turbine.UI.Color(1, 0.62, 0.58, 0.50)

local Panel = {}
Panel.__index = Panel

-- fuente con respaldo (si el cliente no tuviera esa, una que si existe)
local function Font(name, fallback)
    local FT = Turbine.UI.Lotro.Font
    return FT[name] or FT[fallback] or FT.Verdana12
end

local function frameLines(parent, w, h)
    local lines = {}
    for i, r in ipairs({ { 1, 1, w - 2, 1 }, { 1, h - 2, w - 2, 1 }, { 1, 1, 1, h - 2 }, { w - 2, 1, 1, h - 2 } }) do
        local e = Turbine.UI.Control()
        e:SetParent(parent)
        e:SetPosition(r[1], r[2])
        e:SetSize(r[3], r[4])
        e:SetBackColor(GOLD)
        e:SetMouseVisible(false)
        e:SetVisible(false)
        lines[i] = e
    end
    return lines
end

function Panel.New()
    local self = setmetatable({}, Panel)
    local w = Turbine.UI.Window()
    self.win = w
    w:SetSize(PANEL_W, PANEL_H)
    w:SetBackground(RES .. "fl_panel_bg.tga")
    w:SetZOrder(10)
    w:SetMouseVisible(true)
    w:SetVisible(false)
    local this = self

    -- titulo (arrastrar desde aca mueve la ventana)
    self.title = Turbine.UI.Label()
    self.title:SetParent(w)
    self.title:SetPosition(TITLE[1], TITLE[2])
    self.title:SetSize(TITLE[3], TITLE[4])
    self.title:SetFont(Font("TrajanProBold24", "TrajanPro16"))
    self.title:SetForeColor(Turbine.UI.Color(1, 0.96, 0.87, 0.64))
    self.title:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.title:SetOutlineColor(Turbine.UI.Color(1, 0.05, 0.04, 0.02))
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.title:SetMouseVisible(true)
    self.title.MouseDown = function(sender, args)
        this.drag = true
        this.dragX, this.dragY = args.X, args.Y
    end
    self.title.MouseMove = function(sender, args)
        if this.drag then
            local x, y = w:GetPosition()
            w:SetPosition(x + args.X - this.dragX, y + args.Y - this.dragY)
        end
    end
    self.title.MouseUp = function()
        if this.drag then
            this.drag = false
            local x, y = w:GetPosition()
            F.panelX, F.panelY = x, y
            F.Save()
        end
    end

    -- X para cerrar (arriba a la derecha, dentro de la franja)
    self.close = Turbine.UI.Label()
    self.close:SetParent(w)
    self.close:SetPosition(PANEL_W - 92, 12)
    self.close:SetSize(24, 24)
    self.close:SetFont(Font("Verdana16", "Verdana14"))
    self.close:SetForeColor(GOLD)
    self.close:SetText("X")
    self.close:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.close:SetMouseVisible(true)
    self.close.MouseEnter = function() this.close:SetForeColor(TEXT_HI) end
    self.close.MouseLeave = function() this.close:SetForeColor(GOLD) end
    self.close.MouseClick = function() this:Hide() end

    self.cells = {}
    for i, r in ipairs(CELLS) do
        local def = F.Defs[i]
        local cell = { def = def }
        local c = Turbine.UI.Control()
        c:SetParent(w)
        c:SetPosition(r[1], r[2])
        c:SetSize(r[3], r[4])
        c:SetMouseVisible(true)
        cell.ctl = c
        cell.frame = frameLines(c, r[3], r[4])
        local label = Turbine.UI.Label()
        label:SetParent(c)
        label:SetFont(Font("BookAntiquaBold18", "Verdana14"))
        label:SetFontStyle(Turbine.UI.FontStyle.Outline)
        label:SetOutlineColor(Turbine.UI.Color(1, 0.03, 0.02, 0.01))
        label:SetMouseVisible(false)
        label:SetSelectable(false)
        cell.label = label
        if def ~= nil then
            local box = Turbine.UI.Control()
            box:SetParent(c)
            box:SetPosition(12, math.floor((r[4] - 22) / 2))
            box:SetSize(22, 22)
            box:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
            box:SetMouseVisible(false)
            cell.box = box
            local icon = Turbine.UI.Control()
            icon:SetParent(c)
            icon:SetPosition(44, math.floor((r[4] - 32) / 2))
            icon:SetSize(32, 32)
            icon:SetBackground(RES .. "fl_" .. def.icon .. "_32.tga")
            icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
            icon:SetMouseVisible(false)
            cell.icon = icon
            label:SetPosition(84, 0)
            label:SetSize(r[3] - 88, r[4])
            label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
            c.MouseClick = function()
                F.Set(def.key, not F.IsOn(def.key))
                this:Refresh()
            end
        else
            -- fila de abajo: botones (mostrar todo / ocultar todo / cerrar)
            -- (v3.4: con 18 filtros quedan 2: mostrar todo / ocultar todo;
            -- se cierra con la X de arriba)
            local action = i - #F.Defs   -- 1, 2, 3
            cell.action = action
            label:SetPosition(0, 0)
            label:SetSize(r[3], r[4])
            label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            c.MouseClick = function()
                if action == 1 then
                    F.SetAll(true)
                elseif action == 2 then
                    F.SetAll(false)
                else
                    this:Hide()
                    return
                end
                this:Refresh()
            end
        end
        c.MouseEnter = function()
            for _, e in ipairs(cell.frame) do e:SetVisible(true) end
            label:SetForeColor(TEXT_HI)
        end
        c.MouseLeave = function()
            for _, e in ipairs(cell.frame) do e:SetVisible(false) end
            this:_paintCell(cell)
        end
        self.cells[i] = cell
    end
    self:Refresh()
    return self
end

function Panel:_paintCell(cell)
    local es = self.lang
    if cell.def ~= nil then
        local on = F.IsOn(cell.def.key)
        cell.label:SetText(es and cell.def.es or cell.def.en)
        cell.label:SetForeColor(on and TEXT or TEXT_OFF)
        cell.box:SetBackground(RES .. (on and "fl_check_on.tga" or "fl_check_off.tga"))
        cell.icon:SetOpacity(on and 1 or 0.45)
    else
        local t
        if cell.action == 1 then
            t = es and "Mostrar todo" or "Show all"
        elseif cell.action == 2 then
            t = es and "Ocultar todo" or "Hide all"
        else
            t = es and "Cerrar" or "Close"
        end
        cell.label:SetText(t)
        cell.label:SetForeColor(TEXT)
    end
end

function Panel:Refresh()
    self.lang = IsES()
    self.title:SetText(self.lang and "Filtros del Mapa" or "Map Filters")
    for _, cell in ipairs(self.cells) do
        self:_paintCell(cell)
    end
end

function Panel:Place(anchor)
    local sw, sh = Turbine.UI.Display.GetWidth(), Turbine.UI.Display.GetHeight()
    local x, y = F.panelX, F.panelY
    if x == nil or y == nil then
        x = math.floor((sw - PANEL_W) / 2)
        y = sh - PANEL_H - 120
        -- debajo de la ventana del mapa si hay lugar
        pcall(function()
            if anchor ~= nil then
                local ax, ay = anchor:GetPosition()
                local aw, ah = anchor:GetSize()
                x = math.floor(ax + (aw - PANEL_W) / 2)
                if ay + ah + PANEL_H <= sh then
                    y = ay + ah
                end
            end
        end)
    end
    -- siempre entera dentro de la pantalla
    if x > sw - PANEL_W then x = sw - PANEL_W end
    if y > sh - PANEL_H then y = sh - PANEL_H end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    self.win:SetPosition(x, y)
end

function Panel:Show(anchor)
    self:Refresh()
    self:Place(anchor)
    self.win:SetVisible(true)
end

function Panel:Hide()
    self.drag = false
    self.win:SetVisible(false)
end

function Panel:IsVisible()
    return self.win:IsVisible()
end

function F.TogglePanel(anchor)
    local ok = pcall(function()
        if F.panel == nil then
            F.panel = Panel.New()
        end
        if F.panel:IsVisible() then
            F.panel:Hide()
        else
            F.panel:Show(anchor)
        end
    end)
    return ok
end

function F.HidePanel()
    if F.panel ~= nil then
        pcall(function() F.panel:Hide() end)
    end
end

-- cambio de idioma (lo llama el mapa de zona cuando nota el cambio)
function F.RefreshLanguage()
    if F.panel ~= nil and F.panel:IsVisible() then
        pcall(function() F.panel:Refresh() end)
    end
    for _, st in ipairs(F.strips or {}) do
        pcall(function() st:Refresh() end)
    end
end

-- ---------------------------------------------------------------------
-- v3.3 (pedido del usuario): FILA de filtros dentro de la ventana del
-- mapa, en la fila de los botones Hombre / Mujer, mientras se ve una zona.
-- 17 iconos pequeños (mismo orden que el panel): clic = mostrar / ocultar
-- (apagado = gris). Al pasar el mouse sale su nombre. Al final, "Panel"
-- abre la ventana grande "Filtros del Mapa".
-- ---------------------------------------------------------------------
local STRIP_ICON = 24
local STRIP_STEP_MAX = 32
local STRIP_PANEL_W = 64

local Strip = {}
Strip.__index = Strip

function F.NewStrip(owner)
    local self = setmetatable({}, Strip)
    self.owner = owner
    self.root = Turbine.UI.Control()
    self.root:SetParent(owner)
    self.root:SetMouseVisible(false)
    self.root:SetVisible(false)
    local this = self
    self.cells = {}
    for i, def in ipairs(F.Defs) do
        local c = Turbine.UI.Control()
        c:SetParent(self.root)
        c:SetSize(STRIP_ICON, STRIP_ICON)
        c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        c:SetMouseVisible(true)
        local cell = { def = def, ctl = c }
        c.MouseClick = function()
            F.Set(def.key, not F.IsOn(def.key))
            this:Refresh()
            if F.panel ~= nil and F.panel:IsVisible() then
                pcall(function() F.panel:Refresh() end)
            end
        end
        c.MouseEnter = function()
            this:_tip(cell)
        end
        c.MouseLeave = function()
            this:_hideTip()
        end
        self.cells[i] = cell
    end
    local b = Turbine.UI.Label()
    b:SetParent(self.root)
    b:SetFont(Font("Verdana12", "Verdana12"))
    b:SetForeColor(GOLD)
    b:SetBackColor(Turbine.UI.Color(1, 0.165, 0.141, 0.094))
    b:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    b:SetMouseVisible(true)
    b:SetSelectable(false)
    b.MouseEnter = function() b:SetForeColor(TEXT_HI) end
    b.MouseLeave = function() b:SetForeColor(GOLD) end
    b.MouseClick = function()
        F.TogglePanel(this.owner)
    end
    self.panelBtn = b
    -- cartel con el nombre (ventana chica, sin mouse)
    local tw = Turbine.UI.Window()
    tw:SetSize(180, 22)
    tw:SetBackColor(GOLD)
    tw:SetZOrder(0x7FFFFFFF)
    tw:SetMouseVisible(false)
    tw:SetVisible(false)
    local inner = Turbine.UI.Label()
    inner:SetParent(tw)
    inner:SetPosition(1, 1)
    inner:SetSize(178, 20)
    inner:SetBackColor(Turbine.UI.Color(1, 0.06, 0.05, 0.03))
    inner:SetForeColor(TEXT)
    inner:SetFont(Font("Verdana12", "Verdana12"))
    inner:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    inner:SetMouseVisible(false)
    self.tipWin, self.tipLabel = tw, inner
    F.strips = F.strips or {}
    F.strips[#F.strips + 1] = self
    self:Refresh()
    return self
end

function Strip:_tip(cell)
    pcall(function()
        local es = IsES()
        local on = F.IsOn(cell.def.key)
        local name = es and cell.def.es or cell.def.en
        local state = on and (es and "visible" or "shown") or (es and "oculto" or "hidden")
        self.tipLabel:SetText(name .. "  (" .. state .. ")")
        local sx, sy = cell.ctl:PointToScreen(0, 0)
        local x = sx + STRIP_ICON / 2 - 90
        local y = sy + STRIP_ICON + 4
        local sw = Turbine.UI.Display.GetWidth()
        if x > sw - 180 then x = sw - 180 end
        if x < 0 then x = 0 end
        self.tipWin:SetPosition(x, y)
        self.tipWin:SetVisible(true)
    end)
end

function Strip:_hideTip()
    pcall(function() self.tipWin:SetVisible(false) end)
end

function Strip:Refresh()
    local es = IsES()
    for _, cell in ipairs(self.cells) do
        local on = F.IsOn(cell.def.key)
        local file = RES .. "fl_" .. cell.def.icon .. (on and "_24.tga" or "_24_off.tga")
        if cell.file ~= file then
            cell.file = file
            cell.ctl:SetBackground(file)
        end
    end
    self.panelBtn:SetText(es and "Panel" or "Panel")
end

-- coloca la fila en (x, y) con ancho w y alto h (centrada en vertical)
function Strip:Layout(x, y, w, h)
    local n = #self.cells
    local avail = w - STRIP_PANEL_W - 8
    local step = math.floor(avail / n)
    if step > STRIP_STEP_MAX then step = STRIP_STEP_MAX end
    if step < STRIP_ICON then step = STRIP_ICON end
    self.root:SetPosition(x, y)
    self.root:SetSize(w, h)
    local iy = math.floor((h - STRIP_ICON) / 2)
    for i, cell in ipairs(self.cells) do
        cell.ctl:SetPosition((i - 1) * step, iy)
    end
    -- "Panel" despues del ultimo icono; si la ventana es angosta, mas
    -- chico y mas pegado (nunca encima de un icono)
    local bx = n * step + 6
    local bw = STRIP_PANEL_W
    if bx + bw > w then
        bx = n * step + 2
        bw = math.max(36, w - bx)
        if bx + bw > w then
            bx = w - bw
        end
    end
    self.panelBtn:SetPosition(bx, 0)
    self.panelBtn:SetSize(bw, h)
end

function Strip:SetVisible(v)
    self.root:SetVisible(v and true or false)
    if not v then
        self:_hideTip()
    else
        self:Refresh()
    end
end

-- cambios hechos desde el panel grande: la fila se repinta
F.OnChange(function()
    for _, st in ipairs(F.strips or {}) do
        pcall(function() st:Refresh() end)
    end
end)

F.Load()
