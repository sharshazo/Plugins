-- WorldMap_Addon/worldmap_zonemap.lua
--
-- v3.1.1 (pedido del usuario, con capturas reales del juego): el MAPA DE LA
-- ZONA ya no es una ventana aparte. Va DENTRO de la ventana del Mapa del
-- Mundo, en el mismo recuadro del mapa (el viewport):
--   * clic en una zona del mapa del mundo -> se cambia a su mapa de zona
--     (y al lado se abre la lista de misiones, como antes);
--   * clic en el nombre de un mapa vecino ("hacia las Tierras de Bree"...)
--     -> se viaja a ese mapa, igual que en MoorMap (conectores tipo 41/51/52
--     de MoorMap, mismos datos);
--   * clic derecho -> vuelve al mapa anterior y, desde el primero, al mapa
--     del mundo (MoorMap usa el clic derecho para "subir" de mapa).
-- Con esto se arreglan los 3 errores de la v3.1: la ventana de zona dejaba
-- ver el mapa del mundo detras (fila de arriba transparente), se salia del
-- area del mapa del mundo, y el cartel de zona del mapa del mundo aparecia
-- al pasar el mouse por el mapa de la zona (el mapa del mundo seguia
-- "debajo" detectando el mouse; ahora no detecta nada mientras se ve una
-- zona).
--
-- La imagen de cada mapa es la del propio cliente del juego (numero de
-- recurso, igual que MoorMap: pcall(SetBackground, ctl, numero)), sale en el
-- idioma del cliente. Encima van los iconos con su aura que se mueve:
-- ciudad grande, incursion, mazmorra, establo, cofre y elite; al pasar el
-- mouse se resaltan y sale su cartel (cofre: solo resaltado). Ningun icono
-- queda a menos de 16 px del borde del mapa (no sobresale).
--
-- Mismos mecanismos ya probados en worldmap.lua: viewport + contenido a
-- tamaño nativo que se arrastra (pan), sin escalar; auras = cuadros TGA que
-- se cambian; cartel = Window sin chrome + Control solido; hover por poll.
-- Todo lo que toca la API va en pcall: si algo fallara, el mapa del mundo
-- sigue funcionando igual.

import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WorldMapAddon = _G.WorldMapAddon or {}
WorldMapAddon.UI = WorldMapAddon.UI or {}

local ZD = WorldMapAddon.ZoneMapsData

local RES = "WorldMap_Addon/assets/worldmap/icon/"
local BORDER_HEX = "#C9A66B"
local VIEW_BG_HEX = "#141005"
local BAR_H = 26 -- barra de arriba: volver, < mapa (1/7) >, ayuda
local FX_FRAMES = 12
local FX_FPS = 8
local TIP_W = 300
local TIP_PAD = 10
local TIP_TITLE_H = 20
local TIP_LINE_H = 15
local LINK_W, LINK_H = 150, 40 -- zona clickeable sobre el nombre del mapa vecino
-- v3.1.2: fondo 100% transparente (igual que MoorMap: MapConnector_blank.tga).
-- En LOTRO un Control sin fondo no siempre recibe el mouse; con una imagen
-- transparente si, sin tapar nada del mapa.
local LINK_BLANK = "WorldMap_Addon/assets/worldmap/icon/zm_link_blank.tga"
local DRAG_SLOP = 4

-- dibujo de cada tipo: icono (w x h, centrado en el punto), aura (cuadros
-- animados) y resaltado (mismo tamaño y lugar que el aura)
local KIND = {
    t = { img = "zm_cofre.tga", w = 22, h = 17, aura = "zm_cofre_aura_", aw = 36, ah = 31, ax = -7, ay = -9, hl = "zm_cofre_hl.tga" },
    s = { img = "zm_establo.tga", w = 26, h = 24, aura = "zm_establo_aura_", aw = 40, ah = 38, ax = -7, ay = -9, hl = "zm_establo_hl.tga" },
    e = { img = "zm_elite.tga", w = 30, h = 28, aura = "zm_elite_aura_", aw = 44, ah = 42, ax = -7, ay = -9, hl = "zm_elite_hl.tga" },
    d = { img = "puerta_mazmorra_28.tga", w = 28, h = 28, aura = "puerta_aura_", aw = 44, ah = 44, ax = -8, ay = -8, hl = "zm_puerta_hl.tga" },
    r = { img = "calavera_raid_30.tga", w = 30, h = 28, aura = "calavera_fuego_", aw = 46, ah = 52, ax = -8, ay = -18, hl = "zm_calavera_hl.tga", eyes = "calavera_ojos.tga" },
    c = { img = "zm_ciudad.tga", w = 32, h = 30, aura = "zm_ciudad_aura_", aw = 48, ah = 46, ax = -8, ay = -10, hl = "zm_ciudad_hl.tga" },
}
-- orden de dibujo: lo primero queda debajo (las ciudades arriba de todo)
local KIND_ORDER = { "t", "s", "e", "d", "r", "c" }

-- v3.1.3 (pedido del jugador): flecha dorada animada encima de cada
-- mazmorra / incursion donde tiene misiones activas, con el numero. Mismas
-- imagenes que las flechas del mapa del mundo (flecha_mision + su aura).
local QARROW = { img = "flecha_mision.tga", w = 24, h = 30, aura = "flecha_aura_", aw = 40, ah = 46, adx = -8, ady = -14 }
local QARROW_KINDS = { d = true, r = true }
local QARROW_GAP = 6        -- px entre la flecha y el icono
local QARROW_BOB = 4        -- px que sube y baja
local QARROW_PERIOD = 1.2   -- s por subida y bajada
local QARROW_REFRESH = 3    -- s entre recuentos de misiones

local DIFF_ES = {
    ["Elite"] = "\195\137lite", ["Great Elite"] = "Gran \195\169lite", ["Signature"] = "Distintivo",
    ["Nemesis"] = "N\195\169mesis", ["Supreme Nemesis"] = "N\195\169mesis supremo",
}

local function HexToColor(hex, alpha)
    local r = tonumber(hex:sub(2, 3), 16) / 255
    local g = tonumber(hex:sub(4, 5), 16) / 255
    local b = tonumber(hex:sub(6, 7), 16) / 255
    if alpha then
        return Turbine.UI.Color(alpha, r, g, b) -- (a, r, g, b): orden real de la API
    end
    return Turbine.UI.Color(r, g, b)
end

-- idioma: el de Quest Assistant (su boton ES/EN); sin Quest Assistant,
-- español (el idioma de este addon)
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

local function Split(text)
    local out = {}
    for part in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        out[#out + 1] = part
    end
    return out
end

-- renglones aproximados de un texto en Verdana12 (~6.6 px por letra)
local function TipLines(text, w)
    local n = 0
    for _ in tostring(text or ""):gmatch("[^\128-\191]") do
        n = n + 1
    end
    local perLine = math.max(1, math.floor(w / 6.6))
    return math.max(1, math.ceil(n / perLine))
end

-- titulo y renglones del cartel de un icono (nil = sin cartel: cofres)
local function TipFor(p, es)
    local kind = p[1]
    local en, esn, extra = p[4] or "", p[5] or "", p[6] or ""
    if esn == "" then
        esn = en
    end
    local ens, ess = Split(en), Split(esn)
    if kind == "t" then
        return nil
    elseif kind == "r" or kind == "d" then
        local title
        if kind == "r" then
            title = es and "Incursi\195\179n (Raid)" or "Raid (Incursi\195\179n)"
        else
            title = es and "Mazmorra (Dungeon)" or "Dungeon (Mazmorra)"
        end
        local lines = {}
        for i, e in ipairs(ens) do
            local s = ess[i] or e
            local first, second = s, e
            if not es then
                first, second = e, s
            end
            if first == second then
                lines[#lines + 1] = first
            else
                lines[#lines + 1] = first .. " (" .. second .. ")"
            end
        end
        return title, lines
    elseif kind == "c" then
        local name = es and ess[1] or ens[1]
        return name, { es and "Ciudad" or "City" }
    elseif kind == "s" then
        local title = es and "Establo" or "Stable-master"
        if extra == "far" then
            title = es and "Establo de largo alcance" or "Far-ranging Stable-master"
        end
        local place = es and ess[1] or ens[1]
        if place == nil or place == "" then
            return title, {}
        end
        return title, { place }
    elseif kind == "e" then
        local infos = Split(extra)
        local lines = {}
        for i, name in ipairs(ens) do
            local diff, lvl = tostring(infos[i] or infos[1] or ""):match("^(.-)|(.*)$")
            local txt = name
            local det = {}
            if diff ~= nil and diff ~= "" then
                det[#det + 1] = es and (DIFF_ES[diff] or diff) or diff
            end
            if lvl ~= nil and lvl ~= "" then
                det[#det + 1] = (es and "nivel " or "level ") .. lvl
            end
            if #det > 0 then
                txt = txt .. " - " .. table.concat(det, ", ")
            end
            lines[#lines + 1] = txt
        end
        return es and "\195\137lite" or "Elite", lines
    end
    return nil
end

-- ---------------------------------------------------------------------
-- Vista de mapa de zona (vive dentro del viewport del Mapa del Mundo)
-- ---------------------------------------------------------------------
local ZV = {}
ZV.__index = ZV
WorldMapAddon.UI.ZoneView = ZV

local function IsRight(args)
    return args ~= nil and args.Button == Turbine.UI.MouseButton.Right
end

local function IsLeft(args)
    return args == nil or args.Button == nil or args.Button == Turbine.UI.MouseButton.Left
end

function ZV.New(owner, viewport)
    local self = setmetatable({}, ZV)
    self.owner = owner
    self.viewport = viewport
    self.active = false
    self.zone = false
    self.mapId = false
    self.history = {}
    self.panX, self.panY = 0, BAR_H
    self.mapW, self.mapH = 1024, 768
    self.lang = IsES()
    self.tipOn = false
    self.tipCtrl = false
    self.hoverItem = false
    self.hoverLink = false
    self.fx = { last = 0, broken = false }
    self.pool = {}
    self.linkPool = {}
    self.dragging = false
    self.dragMoved = false

    local this = self

    -- todo cuelga de "root" (mismo tamaño que el viewport): se muestra u
    -- oculta entero. root no recibe el mouse; sus hijos si (igual que
    -- mapViewport / mapContent en worldmap.lua).
    self.root = Turbine.UI.Control()
    self.root:SetParent(viewport)
    self.root:SetPosition(0, 0)
    self.root:SetMouseVisible(false)
    self.root:SetVisible(false)

    -- fondo solido: nunca se ve el mapa del mundo detras
    self.bg = Turbine.UI.Control()
    self.bg:SetParent(self.root)
    self.bg:SetPosition(0, 0)
    self.bg:SetBackColor(HexToColor(VIEW_BG_HEX))
    self.bg:SetMouseVisible(false)

    self.content = Turbine.UI.Control()
    self.content:SetParent(self.root)
    self.content:SetPosition(0, BAR_H)
    self.content:SetSize(self.mapW, self.mapH)

    self.mapImage = Turbine.UI.Control()
    self.mapImage:SetParent(self.content)
    self.mapImage:SetPosition(0, 0)
    self.mapImage:SetSize(self.mapW, self.mapH)
    self.mapImage:SetMouseVisible(false)

    -- orden de dibujo: conectores debajo, iconos encima
    self:_buildLinks()
    self:_buildPools()

    self.noMap = Turbine.UI.Label()
    self.noMap:SetParent(self.root)
    self.noMap:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
    self.noMap:SetForeColor(HexToColor("#F0D9A0"))
    self.noMap:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.noMap:SetMouseVisible(false)
    self.noMap:SetVisible(false)

    -- barra de arriba (encima del mapa)
    self.bar = Turbine.UI.Control()
    self.bar:SetParent(self.root)
    self.bar:SetPosition(0, 0)
    self.bar:SetBackColor(Turbine.UI.Color(1, 0.07, 0.06, 0.03))
    self.bar:SetMouseVisible(true)
    self.bar.MouseClick = function(sender, args)
        if IsRight(args) then
            this:Back()
        end
    end
    local function barLabel(font, color, align)
        local l = Turbine.UI.Label()
        l:SetParent(self.bar)
        l:SetFont(font)
        l:SetForeColor(HexToColor(color))
        l:SetTextAlignment(align)
        l:SetSelectable(false)
        l:SetMouseVisible(false)
        return l
    end
    local function barButton(text)
        local b = barLabel(Turbine.UI.Lotro.Font.Verdana12, BORDER_HEX, Turbine.UI.ContentAlignment.MiddleCenter)
        b:SetText(text)
        b:SetBackColor(HexToColor("#2A2418"))
        b:SetMouseVisible(true)
        b.MouseEnter = function()
            b:SetForeColor(HexToColor("#FFE9A8"))
        end
        b.MouseLeave = function()
            b:SetForeColor(HexToColor(BORDER_HEX))
            b:SetBackColor(HexToColor("#2A2418"))
        end
        b.MouseDown = function(sender, args)
            if IsLeft(args) then
                b:SetBackColor(HexToColor("#6A5226"))
            end
        end
        b.MouseUp = function()
            b:SetBackColor(HexToColor("#2A2418"))
        end
        return b
    end
    self.backBtn = barButton("")
    self.backBtn.MouseClick = function(sender, args)
        if IsLeft(args) then
            this.owner:_exitZoneMap()
        end
    end
    self.prevBtn = barButton("<")
    self.prevBtn.MouseClick = function(sender, args)
        if IsLeft(args) then
            this:StepMap(-1)
        end
    end
    self.nextBtn = barButton(">")
    self.nextBtn.MouseClick = function(sender, args)
        if IsLeft(args) then
            this:StepMap(1)
        end
    end
    self.mapName = barLabel(Turbine.UI.Lotro.Font.TrajanPro14, "#F0D9A0", Turbine.UI.ContentAlignment.MiddleCenter)
    self.hint = barLabel(Turbine.UI.Lotro.Font.Verdana10, "#A89B7A", Turbine.UI.ContentAlignment.MiddleRight)

    -- arrastrar (clic izquierdo) y volver (clic derecho), igual que el
    -- mapa del mundo (args.X/Y en coordenadas del contenido)
    self.content.MouseDown = function(sender, args)
        if IsRight(args) then
            this:Back()
            return
        end
        this.dragging = true
        this.dragMoved = false
        this.dragStartX, this.dragStartY = args.X, args.Y
        this.dragPanX, this.dragPanY = this.panX, this.panY
    end
    self.content.MouseMove = function(sender, args)
        if this.dragging then
            if math.abs(args.X - this.dragStartX) > DRAG_SLOP or math.abs(args.Y - this.dragStartY) > DRAG_SLOP then
                this.dragMoved = true
            end
            this.panX = this.dragPanX + (args.X - this.dragStartX)
            this.panY = this.dragPanY + (args.Y - this.dragStartY)
            this:_clampPan()
            this:_applyPan()
        end
    end
    self.content.MouseUp = function()
        this.dragging = false
    end
    -- clic izquierdo (sin arrastrar) sobre el nombre de un mapa vecino
    self.content.MouseClick = function(sender, args)
        if IsRight(args) or this.dragMoved then
            return
        end
        local lk = this:_linkAt(args.X, args.Y)
        if lk ~= nil then
            this:Navigate(lk.target)
        end
    end
    self.content.MouseLeave = function()
        this.dragging = false
    end

    self:Layout()
    return self
end

-- ---------------------------------------------------------------------
-- Tamaño (se llama desde el SizeChanged del mapa del mundo)
-- ---------------------------------------------------------------------
function ZV:Layout()
    local vw, vh = self.viewport:GetSize()
    if not vw or not vh then
        return
    end
    self.root:SetSize(vw, vh)
    self.bg:SetSize(vw, vh)
    self.noMap:SetPosition(0, BAR_H)
    self.noMap:SetSize(vw, math.max(20, vh - BAR_H))
    self.bar:SetSize(vw, BAR_H)
    local backW = 128
    local hintW = vw >= 640 and 190 or 0
    self.backBtn:SetPosition(4, 3)
    self.backBtn:SetSize(backW, BAR_H - 6)
    self.hint:SetVisible(hintW > 0)
    self.hint:SetPosition(vw - hintW - 6, 3)
    self.hint:SetSize(math.max(1, hintW), BAR_H - 6)
    local midX = backW + 12
    local midW = vw - midX - hintW - 12
    if midW < 120 then
        midW = 120
    end
    self.prevBtn:SetPosition(midX, 3)
    self.prevBtn:SetSize(24, BAR_H - 6)
    self.nextBtn:SetPosition(midX + midW - 24, 3)
    self.nextBtn:SetSize(24, BAR_H - 6)
    self.mapName:SetPosition(midX + 28, 2)
    self.mapName:SetSize(math.max(20, midW - 56), BAR_H - 4)
    self:_clampPan()
    self:_applyPan()
end

-- el mapa se ve en el area DEBAJO de la barra (de BAR_H a vh)
function ZV:_clampPan()
    local vw, vh = self.viewport:GetSize()
    if not vw or not vh then
        return
    end
    local mw, mh = self.mapW, self.mapH
    local areaH = vh - BAR_H
    if mw <= vw then
        self.panX = math.floor((vw - mw) / 2)
    else
        if self.panX > 0 then self.panX = 0 end
        if self.panX < vw - mw then self.panX = vw - mw end
    end
    if mh <= areaH then
        self.panY = BAR_H + math.floor((areaH - mh) / 2)
    else
        if self.panY > BAR_H then self.panY = BAR_H end
        if self.panY < vh - mh then self.panY = vh - mh end
    end
end

function ZV:_applyPan()
    self.content:SetPosition(self.panX, self.panY)
end

-- ---------------------------------------------------------------------
-- Iconos (se crean una vez por tipo y en orden de dibujo; se reusan)
-- ---------------------------------------------------------------------
function ZV:_buildPools()
    local need = {}
    for _, k in ipairs(KIND_ORDER) do
        need[k] = 0
    end
    if ZD ~= nil and ZD.Pois ~= nil then
        for _, list in pairs(ZD.Pois) do
            local n = {}
            for _, p in ipairs(list) do
                n[p[1]] = (n[p[1]] or 0) + 1
            end
            for k, v in pairs(n) do
                if need[k] ~= nil and v > need[k] then
                    need[k] = v
                end
            end
        end
    end
    local this = self
    local function layer(w, h, image)
        local c = Turbine.UI.Control()
        c:SetParent(self.content)
        c:SetSize(w, h)
        c:SetBackground(RES .. image)
        c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        c:SetMouseVisible(false)
        c:SetVisible(false)
        return c
    end
    for _, k in ipairs(KIND_ORDER) do
        local spec = KIND[k]
        local list = {}
        for i = 1, need[k] do
            local item = { kind = k, frame = 1, phase = (i * 5) % FX_FRAMES, poi = false, vis = false, x = 0, y = 0 }
            item.aura = layer(spec.aw, spec.ah, spec.aura .. "1.tga")
            item.hl = layer(spec.aw, spec.ah, spec.hl)
            item.icon = layer(spec.w, spec.h, spec.img)
            if spec.eyes ~= nil then
                item.eyes = layer(spec.w, spec.h, spec.eyes)
            end
            if QARROW_KINDS[k] then
                item.qaura = layer(QARROW.aw, QARROW.ah, QARROW.aura .. "1.tga")
                item.qarrow = layer(QARROW.w, QARROW.h, QARROW.img)
                local num = Turbine.UI.Label()
                num:SetParent(item.qarrow)
                num:SetPosition(0, 10)
                num:SetSize(QARROW.w, 16)
                num:SetFont(Turbine.UI.Lotro.Font.Verdana12)
                num:SetForeColor(HexToColor("#2A1A04"))
                num:SetFontStyle(Turbine.UI.FontStyle.Outline)
                num:SetOutlineColor(HexToColor("#FFE9A8"))
                num:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
                num:SetMouseVisible(false)
                num:SetSelectable(false)
                item.qnum = num
                item.qcount = 0
                item.qframe = 1
            end
            item.icon:SetMouseVisible(true)
            item.icon.MouseEnter = function()
                this:_enterItem(item)
            end
            item.icon.MouseLeave = function()
                if this.hoverItem == item then
                    this:_leaveItem()
                end
            end
            item.icon.MouseClick = function(sender, args)
                if IsRight(args) then
                    this:Back()
                elseif item.vis then
                    -- icono encima del nombre de un mapa vecino: viaja igual
                    local lk = this:_linkAt(item.x + (args.X or 0), item.y + (args.Y or 0))
                    if lk ~= nil then
                        this:Navigate(lk.target)
                    end
                end
            end
            list[i] = item
        end
        self.pool[k] = list
    end
end

function ZV:_showItem(item, p)
    local spec = KIND[item.kind]
    local x = math.floor(p[2] - spec.w / 2)
    local y = math.floor(p[3] - spec.h / 2)
    item.poi = p
    item.x, item.y = x, y
    item.icon:SetPosition(x, y)
    item.aura:SetPosition(x + spec.ax, y + spec.ay)
    item.hl:SetPosition(x + spec.ax, y + spec.ay)
    if item.eyes ~= nil then
        item.eyes:SetPosition(x, y)
        item.eyes:SetVisible(true)
    end
    item.aura:SetVisible(true)
    item.icon:SetVisible(true)
    item.hl:SetVisible(false)
    item.vis = true
end

function ZV:_hideItem(item)
    item.vis = false
    item.poi = false
    if item.qarrow ~= nil then
        item.qcount = 0
        item.qarrow:SetVisible(false)
        item.qaura:SetVisible(false)
    end
    item.aura:SetVisible(false)
    item.icon:SetVisible(false)
    item.hl:SetVisible(false)
    if item.eyes ~= nil then
        item.eyes:SetVisible(false)
    end
end

function ZV:_clearIcons()
    self:_leaveItem()
    self:_leaveLink()
    for _, k in ipairs(KIND_ORDER) do
        for _, item in ipairs(self.pool[k] or {}) do
            if item.vis then
                self:_hideItem(item)
            end
        end
    end
    for _, lk in ipairs(self.linkPool) do
        if lk.vis then
            lk.vis = false
            lk.target = false
            lk.ctl:SetVisible(false)
        end
    end
end

function ZV:_fillIcons()
    self:_clearIcons()
    if ZD == nil or self.mapId == false then
        return
    end
    local list = ZD.Pois ~= nil and ZD.Pois[self.mapId] or nil
    if list ~= nil then
        local nextIdx = {}
        for _, p in ipairs(list) do
            local k = p[1]
            local pool = self.pool[k]
            if pool ~= nil then
                local i = (nextIdx[k] or 0) + 1
                nextIdx[k] = i
                if pool[i] ~= nil then
                    self:_showItem(pool[i], p)
                end
            end
        end
    end
    local links = ZD.Links ~= nil and ZD.Links[self.mapId] or nil
    if links ~= nil then
        local i = 0
        for _, l in ipairs(links) do
            if ZD.Maps[l[3]] ~= nil then
                i = i + 1
                local lk = self.linkPool[i]
                if lk == nil then
                    break
                end
                local x = math.floor(l[1] - LINK_W / 2)
                local y = math.floor(l[2] - LINK_H / 2)
                if x < 0 then x = 0 end
                if y < 0 then y = 0 end
                if x > self.mapW - LINK_W then x = self.mapW - LINK_W end
                if y > self.mapH - LINK_H then y = self.mapH - LINK_H end
                lk.target = l[3]
                lk.x, lk.y = x, y
                lk.ctl:SetPosition(x, y)
                lk.ctl:SetVisible(true)
                lk.vis = true
            end
        end
    end
    self:_refreshQuestArrows()
end

-- cuantas misiones activas tiene cada mazmorra / incursion del mapa; la
-- flecha solo se ve si hay al menos una. Sin Quest Assistant, ninguna.
function ZV:_refreshQuestArrows()
    self.qarrowAt = Turbine.Engine.GetGameTime()
    local Q = WorldMapAddon.Quests
    local can = Q ~= nil and Q.InstanceQuests ~= nil and Q.Available ~= nil
    for k in pairs(QARROW_KINDS) do
        for _, item in ipairs(self.pool[k] or {}) do
            if item.qarrow ~= nil then
                local n = 0
                if can and item.vis and item.poi ~= false then
                    local ok, list = pcall(function()
                        if not Q.Available() then
                            return {}
                        end
                        return Q.InstanceQuests(Split(item.poi[4]), Split(item.poi[5]))
                    end)
                    if ok and type(list) == "table" then
                        n = #list
                    end
                end
                if n ~= item.qcount then
                    item.qcount = n
                    item.qnum:SetText(n > 0 and tostring(n) or "")
                end
                item.qarrow:SetVisible(n > 0)
                item.qaura:SetVisible(n > 0)
            end
        end
    end
end

-- la flecha sube y baja suave (cada cuadro) y su aura cambia de cuadro
function ZV:_animateQuestArrows(now)
    if self.qarrowBroken == true then
        return
    end
    local ok = pcall(function()
        if self.qarrowAt == nil or now - self.qarrowAt >= QARROW_REFRESH then
            self:_refreshQuestArrows()
        end
        local bob = math.floor(QARROW_BOB * math.sin(2 * math.pi * now / QARROW_PERIOD) + 0.5)
        local tick = math.floor(now * FX_FPS)
        for k in pairs(QARROW_KINDS) do
            for _, item in ipairs(self.pool[k] or {}) do
                if item.qarrow ~= nil and item.vis and item.qcount > 0 then
                    local x = math.floor(item.poi[2] - QARROW.w / 2)
                    local y = item.y - QARROW.h - QARROW_GAP + bob
                    item.qarrow:SetPosition(x, y)
                    item.qaura:SetPosition(x + QARROW.adx, y + QARROW.ady)
                    local f = ((tick + item.phase) % FX_FRAMES) + 1
                    if f ~= item.qframe then
                        item.qframe = f
                        item.qaura:SetBackground(RES .. QARROW.aura .. tostring(f) .. ".tga")
                    end
                end
            end
        end
    end)
    if not ok then
        self.qarrowBroken = true
    end
end

-- ---------------------------------------------------------------------
-- Conectores: el nombre del mapa vecino se puede cliquear (como MoorMap)
-- ---------------------------------------------------------------------
function ZV:_buildLinks()
    local need = 0
    if ZD ~= nil and ZD.Links ~= nil then
        for _, list in pairs(ZD.Links) do
            if #list > need then
                need = #list
            end
        end
    end
    local this = self
    for i = 1, need do
        local lk = { vis = false, target = false }
        local c = Turbine.UI.Control()
        c:SetParent(self.content)
        c:SetSize(LINK_W, LINK_H)
        -- v3.1.2: SIN color de fondo. En LOTRO un color de fondo con
        -- transparencia (alfa < 1) no se mezcla con el mapa: "perfora" la
        -- ventana y deja ver el juego detras (salia un rectangulo negro u
        -- oscuro tapando el nombre del mapa vecino). Al pasar el mouse se
        -- marca con un marco dorado de 4 lineas opacas (no perforan).
        pcall(function()
            c:SetBackground(LINK_BLANK)
            c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        end)
        c:SetMouseVisible(true)
        c:SetVisible(false)
        lk.frame = {}
        local gold = HexToColor(BORDER_HEX)
        for j, r in ipairs({ { 0, 0, LINK_W, 2 }, { 0, LINK_H - 2, LINK_W, 2 }, { 0, 0, 2, LINK_H }, { LINK_W - 2, 0, 2, LINK_H } }) do
            local e = Turbine.UI.Control()
            e:SetParent(c)
            e:SetPosition(r[1], r[2])
            e:SetSize(r[3], r[4])
            e:SetBackColor(gold)
            e:SetMouseVisible(false)
            e:SetVisible(false)
            lk.frame[j] = e
        end
        c.MouseEnter = function()
            this:_enterLink(lk)
        end
        c.MouseLeave = function()
            if this.hoverLink == lk then
                this:_leaveLink()
            end
        end
        c.MouseClick = function(sender, args)
            if IsRight(args) then
                this:Back()
            elseif lk.vis and lk.target then
                this:Navigate(lk.target)
            end
        end
        lk.ctl = c
        self.linkPool[i] = lk
    end
end

-- conector bajo el punto (x, y) del mapa (pixeles del mapa). Respaldo por
-- coordenadas: el clic y el resaltado funcionan aunque el control del
-- conector no reciba el mouse, o haya un icono encima del nombre.
function ZV:_linkAt(x, y)
    if x == nil or y == nil then
        return nil
    end
    for i = #self.linkPool, 1, -1 do
        local lk = self.linkPool[i]
        if lk.vis and lk.target and lk.x ~= nil
            and x >= lk.x and x < lk.x + LINK_W and y >= lk.y and y < lk.y + LINK_H then
            return lk
        end
    end
    return nil
end

-- conector bajo el mouse (solo dentro del area del mapa, debajo de la barra)
function ZV:_linkUnderMouse()
    local ok, lk = pcall(function()
        local mx, my = Turbine.UI.Display.GetMousePosition()
        local vx, vy = self.viewport:PointToScreen(0, 0)
        local vw, vh = self.viewport:GetSize()
        if not (mx >= vx and mx < vx + vw and my >= vy + BAR_H and my < vy + vh) then
            return nil
        end
        local cx, cy = self.content:PointToScreen(0, 0)
        return self:_linkAt(mx - cx, my - cy)
    end)
    if ok then
        return lk
    end
    return nil
end

function ZV:_mapLabel(mid)
    local m = ZD ~= nil and ZD.Maps[mid] or nil
    if m == nil then
        return ""
    end
    if self.lang then
        return tostring(m.es or m.en or "")
    end
    return tostring(m.en or m.es or "")
end

function ZV:_enterLink(lk)
    if not lk.vis or not lk.target then
        return
    end
    self:_leaveItem()
    if self.hoverLink ~= false and self.hoverLink ~= lk then
        self:_leaveLink()
    end
    self.hoverLink = lk
    pcall(function() for _, e in ipairs(lk.frame) do e:SetVisible(true) end end)
    local title = self.lang and "Ir al mapa" or "Go to map"
    local hint = self.lang and "Clic: abrir este mapa" or "Click: open this map"
    pcall(function() self:_openTip(lk.ctl, title, { self:_mapLabel(lk.target), hint }) end)
end

function ZV:_leaveLink()
    local lk = self.hoverLink
    self.hoverLink = false
    if lk ~= false then
        pcall(function() for _, e in ipairs(lk.frame) do e:SetVisible(false) end end)
        if self.tipCtrl == lk.ctl then
            self:_hideTip()
        end
    end
end

-- ---------------------------------------------------------------------
-- Auras (solo las de los iconos que se ven en el viewport)
-- ---------------------------------------------------------------------
function ZV:_animate()
    local fx = self.fx
    if fx.broken == true then
        return
    end
    local now = Turbine.Engine.GetGameTime()
    if now - fx.last < (1 / FX_FPS) then
        return
    end
    fx.last = now
    local ok = pcall(function()
        local tick = math.floor(now * FX_FPS)
        local vw, vh = self.viewport:GetSize()
        local x0, y0 = -self.panX - 60, -self.panY - 60
        local x1, y1 = x0 + vw + 120, y0 + vh + 120
        for _, k in ipairs(KIND_ORDER) do
            local spec = KIND[k]
            for _, item in ipairs(self.pool[k] or {}) do
                if item.vis and item.x >= x0 and item.x <= x1 and item.y >= y0 and item.y <= y1 then
                    local f = ((tick + item.phase) % FX_FRAMES) + 1
                    if f ~= item.frame then
                        item.frame = f
                        item.aura:SetBackground(RES .. spec.aura .. tostring(f) .. ".tga")
                    end
                    if item.eyes ~= nil then
                        item.eyes:SetOpacity(0.55 + 0.45 * math.sin((2 * math.pi * now / 1.6) + item.phase))
                    end
                end
            end
        end
    end)
    if not ok then
        fx.broken = true
    end
end

-- ---------------------------------------------------------------------
-- Resaltado y cartel de los iconos
-- ---------------------------------------------------------------------
function ZV:_enterItem(item)
    if not item.vis or item.poi == false then
        return
    end
    self:_leaveLink()
    if self.hoverItem ~= false and self.hoverItem ~= item then
        self:_leaveItem()
    end
    self.hoverItem = item
    pcall(function() item.hl:SetVisible(true) end)
    local title, lines = TipFor(item.poi, self.lang)
    if title ~= nil and (item.kind == "r" or item.kind == "d") then
        lines = lines or {}
        for _, l in ipairs(self:_questLines(item.poi)) do
            lines[#lines + 1] = l
        end
    end
    if title ~= nil then
        pcall(function() self:_openTip(item.icon, title, lines or {}) end)
    else
        self:_hideTip()
    end
end

function ZV:_leaveItem()
    local item = self.hoverItem
    self.hoverItem = false
    if item ~= false then
        pcall(function() item.hl:SetVisible(false) end)
        if self.tipCtrl == item.icon then
            self:_hideTip()
        end
    end
end

function ZV:_buildTip()
    local tip = Turbine.UI.Window()
    tip:SetSize(TIP_W, 60)
    tip:SetBackColor(HexToColor(BORDER_HEX))
    tip:SetZOrder(0x7FFFFFFF)
    tip:SetMouseVisible(false)
    tip:SetVisible(false)
    local inner = Turbine.UI.Control()
    inner:SetParent(tip)
    inner:SetPosition(1, 1)
    inner:SetSize(TIP_W - 2, 58)
    inner:SetBackColor(Turbine.UI.Color(1, 0.06, 0.05, 0.03))
    inner:SetMouseVisible(false)
    local title = Turbine.UI.Label()
    title:SetParent(tip)
    title:SetPosition(TIP_PAD, 6)
    title:SetSize(TIP_W - (2 * TIP_PAD), TIP_TITLE_H)
    title:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
    title:SetForeColor(HexToColor("#F0D9A0"))
    title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    title:SetMouseVisible(false)
    local body = Turbine.UI.Label()
    body:SetParent(tip)
    body:SetPosition(TIP_PAD, 6 + TIP_TITLE_H + 2)
    body:SetSize(TIP_W - (2 * TIP_PAD), 20)
    body:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    body:SetForeColor(HexToColor("#E8DDBF"))
    body:SetMultiline(true)
    body:SetMouseVisible(false)
    self.tip = { win = tip, inner = inner, title = title, body = body, h = 60 }
end

function ZV:_placeTip()
    local t = self.tip
    if t == nil then
        return
    end
    local mx, my = Turbine.UI.Display.GetMousePosition()
    local x, y = mx + 18, my + 18
    local maxX = Turbine.UI.Display.GetWidth() - TIP_W
    local maxY = Turbine.UI.Display.GetHeight() - t.h
    if x > maxX then x = mx - TIP_W - 8 end
    if y > maxY then y = maxY end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    t.win:SetPosition(x, y)
end

function ZV:_openTip(ctrl, titleText, lines)
    if self.tip == nil then
        self:_buildTip()
    end
    local t = self.tip
    local bodyW = TIP_W - (2 * TIP_PAD)
    local n = 0
    for _, line in ipairs(lines) do
        n = n + TipLines(line, bodyW)
    end
    local bodyH = (n > 0) and (n * TIP_LINE_H + 2) or 0
    local h = 6 + TIP_TITLE_H + 2 + bodyH + 8
    t.h = h
    t.win:SetSize(TIP_W, h)
    t.inner:SetSize(TIP_W - 2, h - 2)
    t.body:SetSize(bodyW, math.max(1, bodyH))
    t.title:SetText(titleText)
    t.body:SetText(table.concat(lines, "\n"))
    self:_placeTip()
    t.win:SetVisible(true)
    self.tipOn = true
    self.tipCtrl = ctrl
end

function ZV:_hideTip()
    self.tipOn = false
    self.tipCtrl = false
    if self.tip ~= nil then
        pcall(function() self.tip.win:SetVisible(false) end)
    end
end

-- el mouse sigue encima del icono / conector (y dentro del area del mapa)?
function ZV:_mouseOver(ctl)
    local ok, inside = pcall(function()
        local sx, sy = ctl:PointToScreen(0, 0)
        local w, h = ctl:GetSize()
        local mx, my = Turbine.UI.Display.GetMousePosition()
        local vx, vy = self.viewport:PointToScreen(0, 0)
        local vw, vh = self.viewport:GetSize()
        return mx >= sx and mx < sx + w and my >= sy and my < sy + h
            and mx >= vx and mx < vx + vw and my >= vy + BAR_H and my < vy + vh
    end)
    return ok and inside == true
end

function ZV:_checkTip()
    local item = self.hoverItem
    if item ~= false then
        if item.vis and self:_mouseOver(item.icon) then
            if self.tipOn then
                pcall(function() self:_placeTip() end)
            end
        else
            self:_leaveItem()
        end
    end
    local lk = self.hoverLink
    if lk ~= false then
        if lk.vis and self:_mouseOver(lk.ctl) then
            if self.tipOn then
                pcall(function() self:_placeTip() end)
            end
        else
            self:_leaveLink()
        end
    end
end

-- ---------------------------------------------------------------------
-- Mapas: abrir, viajar, volver
-- ---------------------------------------------------------------------
function ZV:_zoneTitle()
    local zone = self.zone
    if zone == false or zone == nil then
        return ""
    end
    if self.lang then
        return tostring(zone.nombre or zone.nombre_original or "")
    end
    return tostring(zone.nombre_original or zone.nombre or "")
end

function ZV:_zoneMaps()
    if self.zone == false or self.zone == nil or ZD == nil or ZD.Zones == nil then
        return {}
    end
    return ZD.Zones[self.zone.nombre_original or ""] or {}
end

function ZV:_mapTitle()
    if self.mapId == false then
        return self:_zoneTitle()
    end
    local ids = self:_zoneMaps()
    local idx = nil
    for i, id in ipairs(ids) do
        if id == self.mapId then
            idx = i
            break
        end
    end
    local text
    if idx == 1 then
        text = self:_zoneTitle()
    else
        text = self:_mapLabel(self.mapId)
    end
    if idx ~= nil and #ids > 1 then
        text = text .. "  (" .. tostring(idx) .. "/" .. tostring(#ids) .. ")"
    end
    return text
end

function ZV:_refreshTexts()
    self.backBtn:SetText(self.lang and "Volver al mundo" or "Back to world")
    self.hint:SetText(self.lang and "Clic derecho: volver" or "Right-click: back")
    self.noMap:SetText(self.lang and "Mapa no disponible para esta zona" or "No map available for this zone")
    self.mapName:SetText(self:_mapTitle())
    local multi = #self:_zoneMaps() > 1
    self.prevBtn:SetVisible(multi)
    self.nextBtn:SetVisible(multi)
    local title = self:_zoneTitle()
    if title == "" then
        title = self:_mapLabel(self.mapId)
    end
    pcall(function()
        self.owner:SetText((self.lang and "Mapa: " or "Map: ") .. title)
    end)
end

function ZV:_checkLanguage()
    local now = Turbine.Engine.GetGameTime()
    if self.langAt ~= nil and now - self.langAt < 1 then
        return
    end
    self.langAt = now
    local es = IsES()
    if es ~= self.lang then
        self.lang = es
        pcall(function() self:_refreshTexts() end)
        local item = self.hoverItem
        if item ~= false then
            self:_leaveItem()
            self:_enterItem(item)
        end
    end
end

function ZV:_loadMap()
    self:_hideTip()
    self.dragging = false
    local m = (self.mapId ~= false and ZD ~= nil) and ZD.Maps[self.mapId] or nil
    local ok = false
    if m ~= nil then
        self.mapW, self.mapH = m.w or 1024, m.h or 768
        self.content:SetSize(self.mapW, self.mapH)
        self.mapImage:SetSize(self.mapW, self.mapH)
        ok = pcall(Turbine.UI.Control.SetBackground, self.mapImage, m.img)
    end
    self.content:SetVisible(ok)
    self.noMap:SetVisible(not ok)
    if ok then
        self:_fillIcons()
    else
        self:_clearIcons()
    end
    -- centrado en el area debajo de la barra
    local vw, vh = self.viewport:GetSize()
    self.panX = math.floor(((vw or 0) - self.mapW) / 2)
    self.panY = BAR_H + math.floor((((vh or 0) - BAR_H) - self.mapH) / 2)
    self:_clampPan()
    self:_applyPan()
    self:_refreshTexts()
end

-- cambia al mapa mid; push = guardar el actual para volver con clic derecho
function ZV:_setMap(mid, push)
    if push and self.mapId ~= false and self.mapId ~= mid then
        self.history[#self.history + 1] = self.mapId
        if #self.history > 40 then
            table.remove(self.history, 1)
        end
    end
    self.mapId = mid
    -- la zona del mapa del mundo a la que pertenece (puede cambiar al viajar)
    local zname = ZD ~= nil and ZD.MapZone ~= nil and ZD.MapZone[mid] or nil
    local newZone = false
    if zname ~= nil and self.owner._zoneByOriginal ~= nil then
        local okZ, z = pcall(self.owner._zoneByOriginal, self.owner, zname)
        if okZ and z ~= nil then
            newZone = z
        end
    end
    local changed = newZone ~= false and newZone ~= self.zone
    if newZone ~= false then
        self.zone = newZone
    elseif zname == nil then
        -- mapa de region (Eriador, Rhovanion...): sin zona
        self.zone = false
    end
    self:_loadMap()
    if changed and self.owner._onZoneViewZone ~= nil then
        pcall(self.owner._onZoneViewZone, self.owner, newZone)
    end
end

-- viajar por un conector (clic en el nombre del mapa vecino)
function ZV:Navigate(mid)
    if ZD == nil or ZD.Maps[mid] == nil then
        return
    end
    self:_leaveLink()
    self:_setMap(mid, true)
end

-- < > : mapas de la misma zona
function ZV:StepMap(delta)
    local ids = self:_zoneMaps()
    local n = #ids
    if n < 2 then
        return
    end
    local idx = 0
    for i, id in ipairs(ids) do
        if id == self.mapId then
            idx = i
            break
        end
    end
    local nextIdx
    if idx == 0 then
        nextIdx = delta > 0 and 1 or n
    else
        nextIdx = ((idx - 1 + delta) % n) + 1
    end
    self:_setMap(ids[nextIdx], true)
end

-- clic derecho: mapa anterior; desde el primero, al mapa del mundo
function ZV:Back()
    self:_leaveItem()
    self:_leaveLink()
    local prev = table.remove(self.history)
    if prev ~= nil then
        self:_setMap(prev, false)
    else
        pcall(function() self.owner:_exitZoneMap() end)
    end
end

-- abre el mapa de una zona del mapa del mundo
function ZV:ShowZone(zone)
    self.lang = IsES()
    self.history = {}
    self.zone = zone or false
    local ids = self:_zoneMaps()
    self.mapId = ids[1] or false
    self.active = true
    self.root:SetVisible(true)
    self:Layout()
    self:_loadMap()
end

function ZV:Deactivate()
    self.active = false
    self.dragging = false
    self:_leaveItem()
    self:_leaveLink()
    self:_hideTip()
    pcall(function() self.root:SetVisible(false) end)
end

function ZV:IsActive()
    return self.active == true
end

-- un cuadro (lo llama el poll del mapa del mundo mientras se ve la zona)
function ZV:Tick()
    if not self.active then
        return
    end
    self:_checkTip()
    if self.hoverLink == false and self.hoverItem == false and not self.dragging then
        local lk = self:_linkUnderMouse()
        if lk ~= nil then
            self:_enterLink(lk)
        end
    end
    self:_animate()
    self:_animateQuestArrows(Turbine.Engine.GetGameTime())
    self:_checkLanguage()
end

-- misiones activas en esa mazmorra / incursion (Quest Assistant); sin
-- Quest Assistant no se agrega nada
function ZV:_questLines(p)
    local out = {}
    local Q = WorldMapAddon.Quests
    if Q == nil or Q.InstanceQuests == nil or Q.Available == nil then
        return out
    end
    local ok = pcall(function()
        if not Q.Available() then
            return
        end
        local list = Q.InstanceQuests(Split(p[4]), Split(p[5]))
        local es = self.lang
        if #list == 0 then
            out[1] = es and "Sin misiones activas aqu\195\173." or "No active quests here."
            return
        end
        out[1] = es and "Misiones activas aqu\195\173:" or "Active quests here:"
        local maxShown = 8
        for i, q in ipairs(list) do
            if i > maxShown then
                local rest = #list - maxShown
                out[#out + 1] = es and ("... y " .. rest .. " m\195\161s") or ("... and " .. rest .. " more")
                break
            end
            local first, second = q.es, q.en
            if not es then
                first, second = q.en, q.es
            end
            if second ~= nil and second ~= "" and second ~= first then
                out[#out + 1] = "- " .. first .. " (" .. second .. ")"
            else
                out[#out + 1] = "- " .. first
            end
        end
    end)
    if not ok then
        return {}
    end
    return out
end
