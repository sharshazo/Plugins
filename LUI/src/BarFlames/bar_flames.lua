-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Aura de la barra (pedido del jugador, 2026-10-07/08): efecto animado en
-- TODO el contorno de la barra de abajo (habilidades, botones, mochilas)
-- -- arriba, izquierda y derecha, donde algunos skins ponen llamas fijas --
-- y, por DENTRO de la barra (encima de los iconos), solo un aura suave que
-- respira con luces que la recorren (nada de llamas sobre los iconos).
-- Funciona tenga o no el jugador un skin: es una capa propia.
-- Contorno: 7 modelos (llamas, infierno, fuego espiritual, brasas, niebla,
-- energia, rayos) o ninguno; 6 colores; aura interior (ninguna / suave /
-- pulso); chispas; opacidad; velocidad.
--
-- Como funciona:
--   * La barra del juego no se puede tocar desde un addon: es una ventana
--     transparente ENCIMA, que no toma el mouse (los clics pasan a los
--     botones). Se coloca una vez con "Colocar sobre la barra" (Opciones >
--     General > Llamas), "/lui llamas colocar" o "/lui move": se arrastra
--     y se ajusta ancho y alto hasta que el marco rodee la barra.
--   * El efecto son cuadros de 128 px puestos uno al lado del otro (arriba)
--     o uno sobre otro (a los costados, imagenes giradas); cada uno recorta
--     su hoja animada (12 cuadros, assets/ui/llamas/) con otra fase. La base
--     es igual en todo el largo y las lenguas se apagan en los bordes del
--     cuadro: no se notan las uniones ("energia" es continua: misma fase).
--   * Sin estirar imagenes (en este cliente no es fiable).
--   * Se esconde con la interfaz (F12), como las demas ventanas de LUI.
-- Todo lo que toca la API va en pcall: si algo fallara, el resto de LUI
-- sigue igual y el efecto simplemente no se ve.

import "Turbine.UI"
import "LUI.src.UI.Widgets.base_window"

local LUI = _G.LUI
LUI.Features.BarFlames = LUI.Features.BarFlames or {}
local BF = LUI.Features.BarFlames

local UI = LUI.UI
local State = LUI.Settings.State
local Runtime = LUI.Runtime
local Windows = Runtime.Windows
local Apply = Runtime.Apply
local class = LUI.Core.class
local TR = LUI.Locale.TR

local ASSET_DIR = "LUI/assets/ui/llamas/"
local SPARK_DIR = "LUI/assets/ui/minimapa/"   -- chispas y luces del aura del minimapa
local TAU = 2 * math.pi
local TILE = 128          -- largo de cada cuadro del contorno
local E = 40              -- alto del efecto del contorno
local IN = 24             -- ancho del brillo interior
local TOP_ROOM = 30       -- lugar extra arriba para las chispas
local FRAMES = 12
local COLS = 3
local FPS = 12
local MIN_W, MAX_W = 160, 6000
local MIN_H, MAX_H = 30, 600
local WHEEL_STEP = 16
local BUTTON_STEP = 32
local Z_NORMAL = 0
local Z_PLACE = 2147482000
local SPARK_SIZE = 14
local SPARK_LIFE = 1.5
local MAX_SPARKS = 60
local LIGHT_SIZE = 16
local LIGHT_TRAIL = 7
local PREFIX = "<rgb=#3399FA>LUI</rgb> llamas: "

BF.DESIGNS = { "llamas", "infierno", "espiritu", "brasas", "niebla", "energia", "rayos", "ninguno" }
BF.COLORS = { "dorado", "azul", "verde", "rojo", "morado", "blanco" }
BF.AURAS = { "ninguna", "suave", "pulso" }
BF.SYNC = { energia = true }   -- modelos continuos: todos los cuadros con la misma fase
BF.MIN_W, BF.MAX_W = MIN_W, MAX_W

-- x, y = esquina de arriba a la izquierda de la BARRA; width/height = su
-- tamaño; -1 = sin colocar. Todas las claves estan en default_schema.lua
-- (el guardado de LUI falla con claves desconocidas). "size" queda solo
-- por compatibilidad con la version anterior (ya no se usa).
local DEFAULTS = {
    enabled = false, design = "llamas", color = "dorado", size = "m",
    aura = "suave", sparks = true, opacity = 0.9, speed = 1.0,
    x = -1, y = -1, width = -1, height = -1,
}
BF.DEFAULTS = DEFAULTS

local function _in(list, value)
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

local function _clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function _round(v)
    return math.floor(v + 0.5)
end

local function _num(v, fallback)
    v = tonumber(v)
    if v == nil or v ~= v then
        return fallback
    end
    return v
end

function BF.normalize(raw)
    raw = type(raw) == "table" and raw or {}
    local out = {}
    out.enabled = raw.enabled == true
    out.design = _in(BF.DESIGNS, raw.design) and raw.design or DEFAULTS.design
    out.color = _in(BF.COLORS, raw.color) and raw.color or DEFAULTS.color
    out.size = "m"
    out.aura = _in(BF.AURAS, raw.aura) and raw.aura or DEFAULTS.aura
    out.sparks = raw.sparks ~= false
    out.opacity = _clamp(_num(raw.opacity, DEFAULTS.opacity), 0.2, 1)
    out.speed = _clamp(_num(raw.speed, DEFAULTS.speed), 0.25, 3)
    local x, y = _num(raw.x, -1), _num(raw.y, -1)
    if x >= 0 and y >= 0 then
        out.x, out.y = _round(x), _round(y)
    end
    local w = _num(raw.width, -1)
    if w > 0 then
        out.width = _round(_clamp(w, MIN_W, MAX_W))
    end
    local h = _num(raw.height, -1)
    if h > 0 then
        out.height = _round(_clamp(h, MIN_H, MAX_H))
    end
    return out
end

-- side: nil = arriba, "l" = izquierda, "r" = derecha
function BF.sheet_path(design, color, side)
    return ASSET_DIR .. "ll_" .. design .. "_" .. color .. "_m" .. (side or "") .. ".tga"
end

function BF.inner_path(side, color)
    return ASSET_DIR .. "ll_in_" .. side .. "_" .. color .. ".tga"
end

function BF.spark_path(color)
    return SPARK_DIR .. "mm_chispa_" .. color .. ".tga"
end

function BF.light_path(color)
    return SPARK_DIR .. "mm_brillo_" .. color .. ".tga"
end

local function _now()
    return Turbine.Engine.GetGameTime()
end

local function _mouse()
    local ok, x, y = pcall(Turbine.UI.Display.GetMousePosition)
    if ok ~= true or type(x) ~= "number" or type(y) ~= "number" then
        return nil, nil
    end
    return x, y
end

local function _screen()
    local ok, w = pcall(Turbine.UI.Display.GetWidth)
    local ok2, h = pcall(Turbine.UI.Display.GetHeight)
    if ok ~= true or type(w) ~= "number" or w <= 0 then w = 1920 end
    if ok2 ~= true or type(h) ~= "number" or h <= 0 then h = 1080 end
    return w, h
end

-- pseudoazar estable (mismo resultado para el mismo n)
local function _hash(n)
    local v = math.sin(n * 12.9898 + 78.233) * 43758.5453
    return v - math.floor(v)
end

local function _settings()
    local s = State.settings ~= nil and State.settings.barflames or nil
    if type(s) ~= "table" then
        return BF.normalize(nil)
    end
    return s
end

local function _ctl(parent, w, h, image)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    c:SetSize(w, h)
    if image ~= nil then
        c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        local ok = pcall(Turbine.UI.Control.SetBackground, c, image)
        c._ok = ok
    end
    return c
end

-- ---------------------------------------------------------------------
-- Ventana: la barra + un margen de E alrededor (arriba, izq., der.)
-- ---------------------------------------------------------------------

local FlameWindow = class(UI.Widgets.LuiBaseWindow)
BF.FlameWindow = FlameWindow

function FlameWindow:Constructor(cfg)
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })
    UI.NativeScaling.disable(self)
    self.cfg = cfg
    local sw, sh = _screen()
    self.width = cfg.width or sw
    self.height = cfg.height or 90
    if cfg.x ~= nil then
        self.bx, self.by = cfg.x, cfg.y
    else
        self.bx, self.by = 0, sh - self.height
    end
    self.placing = nil
    self.border = {}      -- cuadros del contorno (arriba, izq., der.)
    self.inner = {}       -- brillo interior
    self.sparks = {}
    self.lights = {}
    self.t0 = _now()
    self.last_frame = -1
    self.glow_op = -1
    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetZOrder(Z_NORMAL)
    self:_layout()
    self:SetVisible(true)

    self.ticker = Turbine.UI.Control()
    self.ticker:SetVisible(false)
    local this = self
    self.ticker.Update = function()
        local ok, err = pcall(this.tick, this)
        if ok ~= true then
            this.errors = (this.errors or 0) + 1
            if this.errors <= 2 then
                Turbine.Shell.WriteLine(PREFIX .. tostring(err))
            end
            if this.errors >= 20 then
                this.ticker:SetWantsUpdates(false)
            end
        end
    end
    self.ticker:SetWantsUpdates(true)
end

function FlameWindow:_layout()
    local sw, sh = _screen()
    self.width = _round(_clamp(self.width, MIN_W, MAX_W))
    self.height = _round(_clamp(self.height, MIN_H, MAX_H))
    self.bx = _clamp(_round(self.bx), -self.width + MIN_W, sw - MIN_W)
    self.by = _clamp(_round(self.by), 0, sh - MIN_H)
    self.T = E + TOP_ROOM                       -- y de la barra en la ventana
    self.WW = self.width + 2 * E
    self.WH = self.T + self.height
    self:SetSize(self.WW, self.WH)
    self:SetPosition(self.bx - E, self.by - self.T)
    self:_build()
    if self.chrome ~= nil then
        self:_layout_chrome()
    end
    self.last_frame = -1
end

-- reusa los controles de una lista (crea los que falten, esconde el resto)
local function _pool(list, n, make)
    for i = 1, n do
        if list[i] == nil then
            list[i] = make(i)
        end
    end
    for i = n + 1, #list do
        local it = list[i]
        local c = it.clip or it.ctl or it
        c:SetVisible(false)
        it.on = false
        it.vis = false
    end
end

function FlameWindow:_build()
    local cfg = self.cfg
    local W, H, T = self.width, self.height, self.T
    local col = cfg.color
    local this = self

    -- contorno: arriba (todo el ancho de la ventana, tapa las esquinas),
    -- izquierda y derecha (a lo alto de la barra)
    local specs = {}
    if cfg.design ~= "ninguno" then
        local nt = math.ceil(self.WW / TILE)
        for i = 1, nt do
            specs[#specs + 1] = { side = nil, x = (i - 1) * TILE, y = T - E, w = TILE, h = E }
        end
        local nv = math.ceil(H / TILE)
        for i = 1, nv do
            specs[#specs + 1] = { side = "l", x = 0, y = T + (i - 1) * TILE, w = E, h = math.min(TILE, H - (i - 1) * TILE) }
            specs[#specs + 1] = { side = "r", x = E + W, y = T + (i - 1) * TILE, w = E, h = math.min(TILE, H - (i - 1) * TILE) }
        end
    end
    -- se rehacen al cambiar el tamaño (cambia cuantos van de cada lado)
    for _, b in ipairs(self.border) do
        b.clip:SetVisible(false)
        b.clip:SetParent(nil)
    end
    self.border = {}
    for i, sp in ipairs(specs) do
        local clip = _ctl(self, sp.w, sp.h, nil)
        clip:SetPosition(sp.x, sp.y)
        local sw_, sh_ = TILE * COLS, E * (FRAMES / COLS)
        if sp.side ~= nil then
            sw_, sh_ = E * COLS, TILE * (FRAMES / COLS)
        end
        local sheet = _ctl(clip, sw_, sh_, BF.sheet_path(cfg.design, col, sp.side))
        local phase = BF.SYNC[cfg.design] and 0 or math.floor(_hash(i * 3.7) * FRAMES)
        clip:SetVisible(sheet._ok == true)
        self.border[i] = { clip = clip, sheet = sheet, side = sp.side, phase = phase, frame = -1, on = true }
    end

    -- aura interior: brillo suave en los 4 bordes de adentro
    for _, g in ipairs(self.inner) do
        g:SetVisible(false)
        g:SetParent(nil)
    end
    self.inner = {}
    if cfg.aura ~= "ninguna" then
        local function add(side, x, y, w, h)
            local g = _ctl(self, w, h, BF.inner_path(side, col))
            g:SetPosition(x, y)
            g:SetVisible(g._ok == true)
            self.inner[#self.inner + 1] = g
        end
        for i = 0, math.ceil(W / TILE) - 1 do
            local w = math.min(TILE, W - i * TILE)
            add("t", E + i * TILE, T, w, IN)
            add("b", E + i * TILE, T + H - IN, w, IN)
        end
        for i = 0, math.ceil(H / TILE) - 1 do
            local h = math.min(TILE, H - i * TILE)
            add("l", E, T + i * TILE, IN, h)
            add("r", E + W - IN, T + i * TILE, IN, h)
        end
    end
    self.glow_op = -1

    -- luces que recorren el borde de adentro (2 cometas)
    local nl = cfg.aura ~= "ninguna" and 2 * (LIGHT_TRAIL + 1) or 0
    local limg = BF.light_path(col)
    _pool(self.lights, nl, function()
        return { ctl = _ctl(this, LIGHT_SIZE, LIGHT_SIZE, limg), op = -1, on = true }
    end)
    for i = 1, nl do
        self.lights[i].on = true
    end
    self.n_lights = nl

    -- chispas: suben desde el borde de arriba
    local want = 0
    if cfg.sparks == true and cfg.design ~= "ninguno" then
        local per = cfg.design == "brasas" and 32 or 48
        want = math.min(MAX_SPARKS, math.floor(self.WW / per))
    end
    local simg = BF.spark_path(col)
    _pool(self.sparks, want, function()
        return { ctl = _ctl(this, SPARK_SIZE, SPARK_SIZE, simg), x = nil, y = nil, op = -1, vis = true }
    end)
    self.n_sparks = want
end

-- punto del borde de adentro a la distancia s (vuelta completa = P)
function FlameWindow:_perimeter(s)
    local x0, y0 = E + 6, self.T + 6
    local w, h = self.width - 12, self.height - 12
    if w < 1 then w = 1 end
    if h < 1 then h = 1 end
    local P = 2 * (w + h)
    s = s % P
    if s < w then return x0 + s, y0 end
    s = s - w
    if s < h then return x0 + w, y0 + s end
    s = s - h
    if s < w then return x0 + w - s, y0 + h end
    s = s - w
    return x0, y0 + h - s
end

local function _set_alpha(it, a, steps)
    a = math.floor(_clamp(a, 0, 1) * steps + 0.5) / steps
    if a ~= it.op then
        it.op = a
        it.ctl:SetOpacity(a)
    end
    local vis = a > 0 and it.ctl._ok == true
    if vis ~= it.vis then
        it.vis = vis
        it.ctl:SetVisible(vis)
    end
end

function FlameWindow:tick()
    if self:IsVisible() ~= true then
        return
    end
    local cfg = self.cfg
    local now = _now()
    local t = (now - self.t0) * cfg.speed

    -- contorno: cada cuadro con su fase
    local f = math.floor(t * FPS)
    if f ~= self.last_frame then
        self.last_frame = f
        for _, b in ipairs(self.border) do
            local k = (f + b.phase) % FRAMES
            if k ~= b.frame then
                b.frame = k
                local cx, cy = k % COLS, math.floor(k / COLS)
                if b.side == nil then
                    b.sheet:SetPosition(-cx * TILE, -cy * E)
                else
                    b.sheet:SetPosition(-cx * E, -cy * TILE)
                end
            end
        end
    end

    -- aura interior que respira + luces que recorren el borde
    if cfg.aura ~= "ninguna" then
        local a
        if cfg.aura == "pulso" then
            local s = math.sin(TAU * t / 1.6)
            if s < 0 then s = 0 end
            a = 0.3 + 0.7 * s * s
        else
            a = 0.55 + 0.35 * math.sin(TAU * t / 3)
        end
        a = math.floor(a * 40 + 0.5) / 40
        if a ~= self.glow_op then
            self.glow_op = a
            for _, g in ipairs(self.inner) do
                g:SetOpacity(a)
            end
        end
        local P = 2 * ((self.width - 12) + (self.height - 12))
        local speed = P / 9                       -- una vuelta cada 9 s
        for c = 0, 1 do
            local head = t * speed + c * P / 2
            for j = 0, LIGHT_TRAIL do
                local it = self.lights[c * (LIGHT_TRAIL + 1) + j + 1]
                local x, y = self:_perimeter(head - j * 7)
                local px, py = _round(x - LIGHT_SIZE / 2), _round(y - LIGHT_SIZE / 2)
                if px ~= it.x or py ~= it.y then
                    it.x, it.y = px, py
                    it.ctl:SetPosition(px, py)
                end
                _set_alpha(it, (1 - j / (LIGHT_TRAIL + 1)) ^ 1.3 * 0.9, 30)
            end
        end
    end

    -- chispas: suben desde el borde de arriba y se apagan
    local n = self.n_sparks
    for i = 1, n do
        local s = self.sparks[i]
        local tt = t + (i - 1) * SPARK_LIFE / n
        local cyc = math.floor(tt / SPARK_LIFE)
        local u = tt / SPARK_LIFE - cyc
        local seed = cyc * 17 + i
        local x = _hash(seed) * (self.WW - SPARK_SIZE)
        x = x + math.sin(TAU * (u + _hash(seed + 0.3))) * 6
        local y = self.T - E * 0.4 - u * (E + TOP_ROOM * 0.8) - SPARK_SIZE / 2
        local px, py = _round(x), _round(y)
        if px ~= s.x or py ~= s.y then
            s.x, s.y = px, py
            s.ctl:SetPosition(px, py)
        end
        local a = (1 - u) ^ 1.4
        if u < 0.12 then a = a * (u / 0.12) end
        _set_alpha(s, a, 30)
    end

    local op = self.placing ~= nil and 1 or cfg.opacity
    if op ~= self.win_op then
        self.win_op = op
        self:SetOpacity(op)
    end
end

-- ---------------------------------------------------------------------
-- Colocar: arrastrar, rueda / botones para el ancho
-- ---------------------------------------------------------------------

local function _label(parent, text, font)
    local l = Turbine.UI.Label()
    l:SetParent(parent)
    pcall(l.SetFont, l, font)
    l:SetForeColor(Turbine.UI.Color(1, 0.94, 0.82, 0.55))
    pcall(l.SetFontStyle, l, Turbine.UI.FontStyle.Outline)
    pcall(l.SetOutlineColor, l, Turbine.UI.Color(1, 0, 0, 0))
    l:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    pcall(l.SetSelectable, l, false)
    l:SetMouseVisible(false)
    l:SetText(text)
    return l
end

local function _button(parent, text, on_click)
    local b = _label(parent, text, Turbine.UI.Lotro.Font.TrajanPro14)
    b:SetBackColor(Turbine.UI.Color(0.85, 0.16, 0.12, 0.06))
    b:SetMouseVisible(true)
    b.MouseEnter = function()
        b:SetBackColor(Turbine.UI.Color(0.95, 0.42, 0.32, 0.12))
    end
    b.MouseLeave = function()
        b:SetBackColor(Turbine.UI.Color(0.85, 0.16, 0.12, 0.06))
    end
    b.MouseClick = function(_, args)
        if args == nil or args.Button == nil or args.Button == Turbine.UI.MouseButton.Left then
            local ok, err = pcall(on_click)
            if ok ~= true then
                Turbine.Shell.WriteLine(PREFIX .. tostring(err))
            end
        end
    end
    return b
end

local function T_(k)
    local v = TR ~= nil and TR[k] or nil
    if type(v) ~= "string" then
        return k
    end
    return v
end

function FlameWindow:_make_chrome()
    local ch = {}
    local this = self
    -- fondo apenas oscuro; recibe el mouse para arrastrar (en LOTRO un
    -- control sin fondo no siempre lo recibe)
    ch.back = Turbine.UI.Control()
    ch.back:SetParent(self)
    ch.back:SetMouseVisible(true)
    ch.back:SetBackColor(Turbine.UI.Color(0.22, 0, 0, 0))
    -- marco del rectangulo de la barra (para alinearlo con la del juego)
    for _, k in ipairs({ "lt", "lb", "ll", "lr" }) do
        local c = Turbine.UI.Control()
        c:SetParent(self)
        c:SetMouseVisible(false)
        c:SetBackColor(Turbine.UI.Color(0.9, 1, 0.85, 0.4))
        ch[k] = c
    end
    ch.text = _label(self, "", Turbine.UI.Lotro.Font.Verdana12)
    ch.minus = _button(self, "-", function() this:resize_by(-BUTTON_STEP) end)
    ch.plus = _button(self, "+", function() this:resize_by(BUTTON_STEP) end)
    ch.hminus = _button(self, "-", function() this:resize_h(-8) end)
    ch.hplus = _button(self, "+", function() this:resize_h(8) end)
    ch.wlabel = _label(self, T_("Width"), Turbine.UI.Lotro.Font.Verdana12)
    ch.hlabel = _label(self, T_("Height"), Turbine.UI.Lotro.Font.Verdana12)
    ch.full = _button(self, T_("Screen width"), function() this:fit_screen() end)
    ch.done = _button(self, "OK", function() BF.finish_placement(true) end)
    ch.back:SetZOrder(-1)
    self.chrome = ch
end

function FlameWindow:_layout_chrome()
    local ch = self.chrome
    local WW, WH, T, W, H = self.WW, self.WH, self.T, self.width, self.height
    ch.back:SetSize(WW, WH)
    ch.back:SetPosition(0, 0)
    ch.lt:SetSize(W, 1); ch.lt:SetPosition(E, T)
    ch.lb:SetSize(W, 1); ch.lb:SetPosition(E, T + H - 1)
    ch.ll:SetSize(1, H); ch.ll:SetPosition(E, T)
    ch.lr:SetSize(1, H); ch.lr:SetPosition(E + W - 1, T)
    local cx = E + math.floor(math.min(W, 1600) / 2)
    local fin = self.placing == "move" and "" or ("  |  " .. T_("Right click or OK: done"))
    ch.text:SetSize(math.min(W, 1600) - 8, 18)
    ch.text:SetPosition(E + 4, T + 4)
    ch.text:SetText(T_("Drag the frame over your bar") .. "  |  " .. T_("Mouse wheel or - / +: width") ..
        " (" .. tostring(W) .. " x " .. tostring(H) .. " px)" .. fin)
    local by = T + 26
    ch.wlabel:SetSize(50, 20); ch.wlabel:SetPosition(cx - 230, by)
    ch.minus:SetSize(26, 20); ch.minus:SetPosition(cx - 178, by)
    ch.plus:SetSize(26, 20); ch.plus:SetPosition(cx - 148, by)
    ch.hlabel:SetSize(50, 20); ch.hlabel:SetPosition(cx - 116, by)
    ch.hminus:SetSize(26, 20); ch.hminus:SetPosition(cx - 64, by)
    ch.hplus:SetSize(26, 20); ch.hplus:SetPosition(cx - 34, by)
    ch.full:SetSize(140, 20); ch.full:SetPosition(cx, by)
    ch.done:SetSize(44, 20); ch.done:SetPosition(cx + 146, by)
    ch.done:SetVisible(self.placing ~= "move")
end

function FlameWindow:_show_chrome(visible)
    if visible and self.chrome == nil then
        self:_make_chrome()
    end
    if self.chrome == nil then
        return
    end
    if visible then
        self:_layout_chrome()
    end
    for _, c in pairs(self.chrome) do
        if c ~= self.chrome.done or visible ~= true or self.placing ~= "move" then
            c:SetVisible(visible == true)
        end
    end
end

function FlameWindow:resize_by(delta)
    local w = _round(_clamp(self.width + delta, MIN_W, MAX_W))
    if w == self.width then
        return
    end
    self.width = w
    self:_layout()
end

function FlameWindow:resize_h(delta)
    local h = _round(_clamp(self.height + delta, MIN_H, MAX_H))
    if h == self.height then
        return
    end
    -- la parte de abajo queda en su lugar (la barra suele ir pegada abajo)
    self.by = self.by + (self.height - h)
    self.height = h
    self:_layout()
end

function FlameWindow:fit_screen()
    local sw = _screen()
    self.width = sw
    self.bx = 0
    self:_layout()
end

function FlameWindow:_clear_drag_handlers()
    local back = self.chrome ~= nil and self.chrome.back or nil
    if back ~= nil then
        back.MouseDown = nil
        back.MouseMove = nil
        back.MouseUp = nil
        back.MouseWheel = nil
    end
end

function FlameWindow:begin_placement(owner)
    if self.placing ~= nil then
        self.placing = owner
        self:_show_chrome(true)
        return
    end
    self.placing = owner
    self.snapshot = { bx = self.bx, by = self.by, width = self.width, height = self.height }
    self:SetZOrder(Z_PLACE)
    self:SetMouseVisible(true)
    self:_show_chrome(true)
    local this = self
    local back = self.chrome.back
    back.MouseDown = function(_, args)
        if args ~= nil and args.Button == Turbine.UI.MouseButton.Right then
            if this.placing == "own" then
                BF.finish_placement(true)
            end
            return
        end
        local mx, my = _mouse()
        if mx ~= nil then
            this.drag = { mx = mx, my = my, bx = this.bx, by = this.by }
        end
    end
    back.MouseMove = function()
        local dr = this.drag
        if dr == nil then
            return
        end
        local mx, my = _mouse()
        if mx == nil then
            return
        end
        local sw, sh = _screen()
        this.bx = _clamp(_round(dr.bx + (mx - dr.mx)), -this.width + MIN_W, sw - MIN_W)
        this.by = _clamp(_round(dr.by + (my - dr.my)), 0, sh - MIN_H)
        this:SetPosition(this.bx - E, this.by - this.T)
    end
    back.MouseUp = function()
        this.drag = nil
    end
    back.MouseWheel = function(_, args)
        local dir = args ~= nil and tonumber(args.Direction) or 0
        if dir ~= nil and dir ~= 0 then
            this:resize_by(dir > 0 and WHEEL_STEP or -WHEEL_STEP)
        end
    end
end

-- termina; devuelve true si se guarda
function FlameWindow:end_placement(keep)
    if self.placing == nil then
        return false
    end
    self.placing = nil
    self.drag = nil
    self:_clear_drag_handlers()
    self:SetMouseVisible(false)
    self:_show_chrome(false)
    self:SetZOrder(Z_NORMAL)
    local snap = self.snapshot
    self.snapshot = nil
    if keep ~= true and snap ~= nil then
        self.bx, self.by, self.width, self.height = snap.bx, snap.by, snap.width, snap.height
        self:_layout()
        return false
    end
    return true
end

function FlameWindow:destroy()
    self.ticker:SetWantsUpdates(false)
    self.ticker.Update = nil
    self.placing = nil
    self:_clear_drag_handlers()
    self:unregister_hideable()
    self:SetVisible(false)
end

-- ---------------------------------------------------------------------
-- Guardar / opciones
-- ---------------------------------------------------------------------

local function _loaded()
    local loaded = State.loaded_settings
    if type(loaded) ~= "table" then
        return nil
    end
    if type(loaded.barflames) ~= "table" then
        loaded.barflames = {}
    end
    return loaded.barflames
end
BF.loaded = _loaded

local function _save_geometry(w)
    local m = _loaded()
    if m == nil then
        return
    end
    m.x, m.y, m.width, m.height = w.bx, w.by, w.width, w.height
    if State.settings ~= nil then
        State.settings.barflames = BF.normalize(m)
        w.cfg = State.settings.barflames
    end
    pcall(LUI.Settings.Persistence.save_settings)
end

function Apply.barflames_settings()
    local old = Windows.bar_flames
    if old ~= nil then
        if old.placing ~= nil then
            old:end_placement(false)
            BF._on_end = nil
        end
        pcall(old.destroy, old)
        Windows.bar_flames = nil
    end
    local cfg = BF.normalize(_settings())
    if cfg.enabled ~= true then
        return
    end
    local ok, w = pcall(FlameWindow, cfg)
    if ok == true then
        Windows.bar_flames = w
    else
        Turbine.Shell.WriteLine(PREFIX .. tostring(w))
    end
end

function BF.start_placement(on_end)
    local w = Windows.bar_flames
    if w == nil then
        Turbine.Shell.WriteLine(PREFIX .. "est\195\161n apagadas (/lui llamas on)")
        if on_end ~= nil then
            pcall(on_end)
        end
        return false
    end
    BF._on_end = on_end
    w:begin_placement("own")
    return true
end

function BF.finish_placement(keep)
    local w = Windows.bar_flames
    local changed = false
    if w ~= nil and w.placing ~= nil then
        changed = w:end_placement(keep)
        if changed == true then
            _save_geometry(w)
            Turbine.Shell.WriteLine(PREFIX .. "guardado (" .. tostring(w.width) .. " x " .. tostring(w.height) .. " px)")
        end
    end
    local cb = BF._on_end
    BF._on_end = nil
    if cb ~= nil then
        pcall(cb)
    end
    return changed
end

function BF.is_placing()
    local w = Windows.bar_flames
    return w ~= nil and w.placing ~= nil
end

-- "/lui move": las llamas se mueven junto con las demas ventanas de LUI
function BF.on_move_mode(enabled, cancel)
    local w = Windows.bar_flames
    if w == nil then
        return
    end
    if enabled == true then
        if w.placing == nil then
            w:begin_placement("move")
        end
        return
    end
    if w.placing == "move" then
        if w:end_placement(cancel ~= true) == true then
            _save_geometry(w)
        end
    end
end

-- boton "Colocar sobre la barra" de Opciones
function BF.place_from_config(after)
    local m = _loaded()
    if m == nil then
        return
    end
    m.enabled = true
    pcall(LUI.Settings.rebuild)
    Apply.barflames_settings()
    pcall(LUI.Settings.Persistence.save_settings)
    local cfgwin = Windows.config
    local reopen = cfgwin ~= nil and cfgwin:IsVisible() == true
    if reopen then
        cfgwin:SetVisible(false)
    end
    BF.start_placement(function()
        if reopen and Windows.config ~= nil then
            Windows.config:SetVisible(true)
            if Windows.config.bring_to_front ~= nil then
                pcall(Windows.config.bring_to_front, Windows.config)
            end
        end
        if after ~= nil then
            pcall(after)
        end
    end)
end

function BF.shutdown()
    local w = Windows.bar_flames
    if w ~= nil then
        if w.placing ~= nil then
            w:end_placement(false)
        end
        BF._on_end = nil
        pcall(w.destroy, w)
        Windows.bar_flames = nil
    end
end
