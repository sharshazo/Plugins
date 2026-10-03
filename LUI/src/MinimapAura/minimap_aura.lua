-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Aura del minimapa (pedido del jugador, 2026-10-03): un aro animado
-- alrededor del minimapa (radar) del juego. 7 disenos, 6 colores, tamano
-- libre, 3 grosores, opacidad, velocidad y suavidad (fluidez).
--
-- Como funciona:
--   * La API de LOTRO no deja dibujar DENTRO del radar ni saber donde
--     esta. Por eso es una ventanita transparente que se pone ENCIMA, una
--     sola vez, con "Colocar sobre el minimapa" (Opciones > General >
--     Minimapa), "/lui minimapa colocar" o "/lui move". La ventana y todo
--     lo que tiene NO toman el mouse (SetMouseVisible(false)): los clics
--     pasan al radar como siempre. El centro queda vacio (no tapa el mapa).
--   * El aro esta hecho de puntitos suaves (assets/ui/minimapa/) puestos
--     en circulo: asi el tamano puede ser cualquiera, al pixel, sin estirar
--     imagenes (en este cliente el estirado no es fiable, ver /lui imgtest).
--   * La animacion mueve luces, estrellas, runas o chispas calculando su
--     lugar en cada cuadro (seno/coseno), y hace "respirar" la ventana con
--     SetOpacity. "Suavidad" = cada cuantos cuadros se recalcula.
--   * Se esconde con la interfaz (F12 / ocultar HUD), como las demas
--     ventanas de LUI.
-- Todo lo que toca la API va en pcall: si algo fallara, el resto de LUI
-- sigue igual y el aura simplemente no se ve.

import "Turbine.UI"
import "LUI.src.UI.Widgets.base_window"

local LUI = _G.LUI
LUI.Features.MinimapAura = LUI.Features.MinimapAura or {}
local MM = LUI.Features.MinimapAura

local UI = LUI.UI
local State = LUI.Settings.State
local Runtime = LUI.Runtime
local Windows = Runtime.Windows
local Apply = Runtime.Apply
local class = LUI.Core.class
local TR = LUI.Locale.TR

local ASSET_DIR = "LUI/assets/ui/minimapa/"
local TAU = 2 * math.pi
local MARGIN = 40           -- espacio alrededor del aro (chispas, runas)
local MIN_D, MAX_D = 80, 480
local WHEEL_STEP = 2
local BUTTON_STEP = 4
local Z_NORMAL = 0
local Z_PLACE = 2147482000
local MAX_DOTS = 360
local PREFIX = "<rgb=#3399FA>LUI</rgb> minimapa: "

MM.DESIGNS = { "sereno", "orbitas", "corriente", "runas", "destellos", "llamas", "doble" }
MM.COLORS = { "dorado", "azul", "verde", "rojo", "morado", "blanco" }
MM.THICKNESS = { "f", "n", "g" }
MM.DOT = { f = 20, n = 28, g = 36 }        -- lado de la imagen del punto (px)
MM.BAND = { f = 2, n = 3, g = 5 }          -- medio grosor visible del aro (px)
MM.SPACING = { f = 2, n = 3, g = 4 }       -- px entre puntos del aro
MM.SMOOTH = { "alta", "media", "baja" }
MM.SMOOTH_DT = { alta = 0, media = 1 / 30, baja = 1 / 15 }
MM.SIZE_LIST = { 120, 140, 160, 180, 200, 220, 240, 260, 280, 300, 320, 340, 360 }
MM.SPRITE = { brillo = 16, estrella = 26, chispa = 14, runa = 22 }
MM.MIN_D, MM.MAX_D = MIN_D, MAX_D

local DEFAULTS = {
    enabled = false, design = "sereno", color = "dorado", diameter = 180,
    thickness = "n", opacity = 0.85, speed = 1.0, smooth = "alta",
}
MM.DEFAULTS = DEFAULTS

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

-- valores seguros (lo guardado puede venir de una version vieja o a mano)
function MM.normalize(raw)
    raw = type(raw) == "table" and raw or {}
    local out = {}
    out.enabled = raw.enabled == true
    out.design = _in(MM.DESIGNS, raw.design) and raw.design or DEFAULTS.design
    out.color = _in(MM.COLORS, raw.color) and raw.color or DEFAULTS.color
    local d = tonumber(raw.diameter) or DEFAULTS.diameter
    if d ~= d then d = DEFAULTS.diameter end
    out.diameter = _round(_clamp(d, MIN_D, MAX_D))
    out.thickness = MM.DOT[raw.thickness] ~= nil and raw.thickness or DEFAULTS.thickness
    local op = tonumber(raw.opacity) or DEFAULTS.opacity
    if op ~= op then op = DEFAULTS.opacity end
    out.opacity = _clamp(op, 0.2, 1)
    local sp = tonumber(raw.speed) or DEFAULTS.speed
    if sp ~= sp then sp = DEFAULTS.speed end
    out.speed = _clamp(sp, 0.25, 3)
    out.smooth = MM.SMOOTH_DT[raw.smooth] ~= nil and raw.smooth or DEFAULTS.smooth
    local cx, cy = tonumber(raw.cx), tonumber(raw.cy)
    if cx ~= nil and cy ~= nil and cx == cx and cy == cy then
        out.cx, out.cy = _round(cx), _round(cy)
    end
    return out
end

function MM.image(kind, color, extra)
    if kind == "punto" then
        return ASSET_DIR .. "mm_punto_" .. color .. "_" .. extra .. ".tga"
    elseif kind == "runa" then
        return ASSET_DIR .. "mm_runa" .. tostring(extra) .. "_" .. color .. ".tga"
    end
    return ASSET_DIR .. "mm_" .. kind .. "_" .. color .. ".tga"
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

-- lugar inicial: arriba a la derecha, donde el juego pone el radar
function MM.default_center(diameter)
    local sw = _screen()
    local r = math.floor((diameter or DEFAULTS.diameter) / 2)
    return sw - r - 20, r + 25
end

-- pseudoazar estable (mismo resultado para el mismo n): sin math.random
local function _hash(n)
    local v = math.sin(n * 12.9898 + 78.233) * 43758.5453
    return v - math.floor(v)
end

local function _settings()
    local s = State.settings ~= nil and State.settings.minimap or nil
    if type(s) ~= "table" then
        return MM.normalize(nil)
    end
    return s
end

-- ---------------------------------------------------------------------
-- Sprite: un Control con una imagen chica, sin mouse, que recuerda su
-- ultimo lugar/opacidad para no llamar a la API sin necesidad.
-- ---------------------------------------------------------------------

local function _new_sprite(parent, image, size)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    c:SetSize(size, size)
    local ok = pcall(Turbine.UI.Control.SetBackground, c, image)
    return { ctl = c, size = size, half = size / 2, ok = ok, x = nil, y = nil, op = -1, vis = true }
end

local function _sprite_show(s, visible)
    visible = visible == true and s.ok == true
    if visible ~= s.vis then
        s.vis = visible
        s.ctl:SetVisible(visible)
    end
end

-- centro del sprite en (x, y) de la ventana
local function _sprite_place(s, x, y)
    local px = _round(x - s.half)
    local py = _round(y - s.half)
    if px ~= s.x or py ~= s.y then
        s.x, s.y = px, py
        s.ctl:SetPosition(px, py)
    end
end

local function _sprite_alpha(s, a)
    a = _clamp(a, 0, 1)
    a = math.floor(a * 40 + 0.5) / 40
    if a ~= s.op then
        s.op = a
        s.ctl:SetOpacity(a)
    end
    _sprite_show(s, a > 0)
end

-- ---------------------------------------------------------------------
-- Ventana del aura
-- ---------------------------------------------------------------------

local AuraWindow = class(UI.Widgets.LuiBaseWindow)
MM.AuraWindow = AuraWindow

function AuraWindow:Constructor(cfg)
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })
    UI.NativeScaling.disable(self)
    self.cfg = cfg
    self.diameter = cfg.diameter
    if cfg.cx ~= nil then
        self.cx, self.cy = cfg.cx, cfg.cy
    else
        self.cx, self.cy = MM.default_center(cfg.diameter)
    end
    self.placing = nil          -- nil / "own" / "move"
    self.win_op = -1
    self.dots = {}
    self.parts = {}
    self.t0 = _now()
    self.last_tick = -1
    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetZOrder(Z_NORMAL)
    self:_layout()
    self:SetVisible(true)

    -- el "reloj" del aura: un control invisible con Update (igual que el
    -- efecto del puntero)
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

-- tamano y lugar de la ventana + puntos del aro + piezas del diseno
function AuraWindow:_layout()
    local d = self.diameter
    self.R = d / 2
    self.W = d + 2 * MARGIN
    self.C = self.W / 2
    local sw, sh = _screen()
    self.cx = _clamp(_round(self.cx), 0, sw)
    self.cy = _clamp(_round(self.cy), 0, sh)
    self:SetSize(self.W, self.W)
    self:SetPosition(_round(self.cx - self.C), _round(self.cy - self.C))
    self:_build_ring()
    self:_build_parts()
    if self.chrome ~= nil then
        self:_layout_chrome()
    end
    self.last_tick = -1
end

function AuraWindow:_build_ring()
    local cfg = self.cfg
    local size = MM.DOT[cfg.thickness]
    local spacing = MM.SPACING[cfg.thickness]
    local n = math.floor(TAU * self.R / spacing)
    n = _clamp(n, 24, MAX_DOTS)
    local img = MM.image("punto", cfg.color, cfg.thickness)
    for i = 1, n do
        local s = self.dots[i]
        if s == nil then
            s = _new_sprite(self, img, size)
            self.dots[i] = s
        end
        local th = (i - 1) * TAU / n
        _sprite_place(s, self.C + self.R * math.cos(th), self.C + self.R * math.sin(th))
        _sprite_show(s, true)
    end
    for i = n + 1, #self.dots do
        _sprite_show(self.dots[i], false)
    end
    self.dot_count = n
end

-- piezas que se mueven; se crean una vez por diseno (el aro doble cambia
-- de cantidad con el tamano)
function AuraWindow:_build_parts()
    local cfg = self.cfg
    local design = cfg.design
    local col = cfg.color
    local P = self.parts
    local function need(key, count, image_fn, size)
        P[key] = P[key] or {}
        local list = P[key]
        for i = 1, count do
            if list[i] == nil then
                list[i] = _new_sprite(self, image_fn(i), size)
            end
            _sprite_show(list[i], false)
        end
        for i = count + 1, #list do
            _sprite_show(list[i], false)
        end
        list.n = count
        return list
    end
    local function brillo() return MM.image("brillo", col) end
    local function estrella() return MM.image("estrella", col) end
    local function chispa() return MM.image("chispa", col) end
    if design == "orbitas" then
        need("trail", 3 * 6, brillo, MM.SPRITE.brillo)
        need("stars", 3, estrella, MM.SPRITE.estrella)
    elseif design == "corriente" then
        need("trail", 2 * 12, brillo, MM.SPRITE.brillo)
        need("stars", 2, estrella, MM.SPRITE.estrella)
    elseif design == "runas" then
        need("runes", 8, function(i) return MM.image("runa", col, ((i - 1) % 6) + 1) end, MM.SPRITE.runa)
    elseif design == "destellos" then
        need("stars", 7, estrella, MM.SPRITE.estrella)
    elseif design == "llamas" then
        need("sparks", 24, chispa, MM.SPRITE.chispa)
    elseif design == "doble" then
        local r2 = self.R + MM.BAND[cfg.thickness] + 10
        local n2 = _clamp(math.floor(TAU * r2 / 22), 12, 64)
        need("outer", n2, brillo, MM.SPRITE.brillo)
    end
end

function AuraWindow:_set_window_alpha(a)
    a = _clamp(a, 0, 1)
    a = math.floor(a * 100 + 0.5) / 100
    if a ~= self.win_op then
        self.win_op = a
        self:SetOpacity(a)
    end
end

-- un punto del aro (radio r, angulo th) en coordenadas de la ventana
function AuraWindow:_at(r, th)
    return self.C + r * math.cos(th), self.C + r * math.sin(th)
end

function AuraWindow:tick()
    if self:IsVisible() ~= true then
        return
    end
    local now = _now()
    local cfg = self.cfg
    local step = MM.SMOOTH_DT[cfg.smooth] or 0
    -- (margen de 2 ms: con 60 cuadros por segundo, 4 cuadros = 1/15 s)
    if step > 0 and self.last_tick >= 0 and now - self.last_tick < step - 0.002 then
        return
    end
    self.last_tick = now
    local t = (now - self.t0) * cfg.speed
    local R = self.R
    local P = self.parts
    local design = cfg.design
    local breath = 1

    if design == "sereno" then
        breath = 0.62 + 0.38 * (0.5 + 0.5 * math.sin(TAU * t / 3.2))
    elseif design == "orbitas" then
        breath = 0.88 + 0.12 * math.sin(TAU * t / 4)
        local dth = 7 / R
        for k = 0, 2 do
            local a = TAU * t / 7 + k * TAU / 3
            local star = P.stars[k + 1]
            _sprite_place(star, self:_at(R, a))
            _sprite_alpha(star, 1)
            for j = 1, 6 do
                local s = P.trail[k * 6 + j]
                _sprite_place(s, self:_at(R, a - j * dth))
                _sprite_alpha(s, 0.85 * (1 - j / 7))
            end
        end
    elseif design == "corriente" then
        breath = 0.8
        local dth = 5 / R
        for k = 0, 1 do
            local a = TAU * t / 3.5 + k * math.pi
            local head = P.stars[k + 1]
            _sprite_place(head, self:_at(R, a))
            _sprite_alpha(head, 1)
            for j = 1, 12 do
                local s = P.trail[k * 12 + j]
                _sprite_place(s, self:_at(R, a - j * dth))
                _sprite_alpha(s, (1 - j / 13) ^ 1.5)
            end
        end
    elseif design == "runas" then
        breath = 0.85 + 0.15 * math.sin(TAU * t / 5)
        local rr = R + MM.BAND[cfg.thickness] + 13
        local wave = TAU * t / 5
        for k = 1, 8 do
            local a = -TAU * t / 40 + (k - 1) * TAU / 8
            local s = P.runes[k]
            _sprite_place(s, self:_at(rr, a))
            local c = math.cos(a - wave)
            if c < 0 then c = 0 end
            _sprite_alpha(s, 0.45 + 0.55 * c * c)
        end
    elseif design == "destellos" then
        breath = 0.85
        local life = 1.6
        for k = 1, 7 do
            local s = P.stars[k]
            local tt = t + (k - 1) * life / 7
            local cyc = math.floor(tt / life)
            local u = tt / life - cyc
            local a = _hash(cyc * 7 + k) * TAU
            _sprite_place(s, self:_at(R, a))
            local v = math.sin(math.pi * u)
            _sprite_alpha(s, v * v)
        end
    elseif design == "llamas" then
        breath = 0.78 + 0.12 * math.sin(TAU * t * 1.7) + 0.1 * math.sin(TAU * t * 4.3 + 1)
        local life = 1.2
        local n = P.sparks.n
        for k = 1, n do
            local s = P.sparks[k]
            local tt = t + (k - 1) * life / n
            local cyc = math.floor(tt / life)
            local u = tt / life - cyc
            local seed = cyc * 31 + k
            local a = _hash(seed) * TAU + (_hash(seed + 0.5) - 0.5) * 0.3 * u
            local r = R + 2 + u * 26
            _sprite_place(s, self:_at(r, a))
            local fade = (1 - u) ^ 1.3
            if u < 0.1 then fade = fade * (u / 0.1) end
            _sprite_alpha(s, fade)
        end
    elseif design == "doble" then
        breath = 0.8 + 0.2 * math.sin(TAU * t / 3)
        local r2 = R + MM.BAND[cfg.thickness] + 10
        local n2 = P.outer.n
        local base = -TAU * t / 14
        for k = 1, n2 do
            local s = P.outer[k]
            _sprite_place(s, self:_at(r2, base + (k - 1) * TAU / n2))
            _sprite_alpha(s, 0.85)
        end
    end

    if self.placing ~= nil then
        breath = 1
    end
    self:_set_window_alpha(cfg.opacity * breath)
end

-- ---------------------------------------------------------------------
-- Colocar: arrastrar, rueda / botones para el tamano
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
    local b = _label(parent, text, Turbine.UI.Lotro.Font.TrajanPro16)
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

function AuraWindow:_make_chrome()
    local ch = {}
    local this = self
    -- fondo apenas oscuro (se sigue viendo el radar). Es el que recibe el
    -- mouse para arrastrar: en LOTRO un control sin fondo no siempre lo
    -- recibe (ver WorldMap_Addon, zm_link_blank)
    ch.back = Turbine.UI.Control()
    ch.back:SetParent(self)
    ch.back:SetMouseVisible(true)
    ch.back:SetBackColor(Turbine.UI.Color(0.14, 0, 0, 0))
    ch.hline = Turbine.UI.Control()
    ch.hline:SetParent(self)
    ch.hline:SetMouseVisible(false)
    ch.hline:SetBackColor(Turbine.UI.Color(0.9, 1, 0.85, 0.4))
    ch.vline = Turbine.UI.Control()
    ch.vline:SetParent(self)
    ch.vline:SetMouseVisible(false)
    ch.vline:SetBackColor(Turbine.UI.Color(0.9, 1, 0.85, 0.4))
    ch.text = _label(self, "", Turbine.UI.Lotro.Font.Verdana12)
    ch.minus = _button(self, "-", function() this:resize_by(-BUTTON_STEP) end)
    ch.plus = _button(self, "+", function() this:resize_by(BUTTON_STEP) end)
    ch.done = _button(self, "OK", function() MM.finish_placement(true) end)
    -- el fondo queda detras de todo (se agrega a lo ultimo -> z mas bajo)
    ch.back:SetZOrder(-1)
    self.chrome = ch
end

function AuraWindow:_layout_chrome()
    local ch = self.chrome
    local W, C = self.W, _round(self.C)
    ch.back:SetSize(W, W)
    ch.back:SetPosition(0, 0)
    ch.hline:SetSize(31, 1)
    ch.hline:SetPosition(C - 15, C)
    ch.vline:SetSize(1, 31)
    ch.vline:SetPosition(C, C - 15)
    ch.text:SetSize(W - 8, 48)
    ch.text:SetPosition(4, 2)
    local function T(k)
        local v = TR ~= nil and TR[k] or nil
        if type(v) ~= "string" then
            return k
        end
        return v
    end
    local fin = self.placing == "move" and "" or ("\n" .. T("Right click or OK: done"))
    ch.text:SetText(T("Drag to move the aura") .. "\n" .. T("Mouse wheel or - / +: size") ..
        " (" .. tostring(self.diameter) .. " px)" .. fin)
    local by = self.W - 30
    ch.minus:SetSize(28, 24)
    ch.minus:SetPosition(C - 64, by)
    ch.plus:SetSize(28, 24)
    ch.plus:SetPosition(C - 30, by)
    ch.done:SetSize(44, 24)
    ch.done:SetPosition(C + 6, by)
    ch.done:SetVisible(self.placing ~= "move")
end

function AuraWindow:_show_chrome(visible)
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

function AuraWindow:resize_by(delta)
    local d = _round(_clamp(self.diameter + delta, MIN_D, MAX_D))
    if d == self.diameter then
        return
    end
    self.diameter = d
    self.cfg.diameter = d
    self:_layout()
end

function AuraWindow:begin_placement(owner)
    if self.placing ~= nil then
        self.placing = owner
        self:_show_chrome(true)
        return
    end
    self.placing = owner
    self.snapshot = { cx = self.cx, cy = self.cy, diameter = self.diameter }
    self:SetZOrder(Z_PLACE)
    self:SetMouseVisible(true)
    self:_show_chrome(true)
    local this = self
    local back = self.chrome.back
    back.MouseDown = function(_, args)
        if args ~= nil and args.Button == Turbine.UI.MouseButton.Right then
            if this.placing == "own" then
                MM.finish_placement(true)
            end
            return
        end
        local mx, my = _mouse()
        if mx ~= nil then
            this.drag = { mx = mx, my = my, cx = this.cx, cy = this.cy }
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
        this.cx = dr.cx + (mx - dr.mx)
        this.cy = dr.cy + (my - dr.my)
        local sw, sh = _screen()
        this.cx = _clamp(_round(this.cx), 0, sw)
        this.cy = _clamp(_round(this.cy), 0, sh)
        this:SetPosition(_round(this.cx - this.C), _round(this.cy - this.C))
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

function AuraWindow:_clear_drag_handlers()
    local back = self.chrome ~= nil and self.chrome.back or nil
    if back ~= nil then
        back.MouseDown = nil
        back.MouseMove = nil
        back.MouseUp = nil
        back.MouseWheel = nil
    end
end

-- termina; devuelve true si cambio algo
function AuraWindow:end_placement(keep)
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
        self.cx, self.cy = snap.cx, snap.cy
        self.diameter = snap.diameter
        self.cfg.diameter = snap.diameter
        self:_layout()
        return false
    end
    self.last_tick = -1
    return true
end

function AuraWindow:destroy()
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
    if type(loaded.minimap) ~= "table" then
        loaded.minimap = {}
    end
    return loaded.minimap
end
MM.loaded = _loaded

local function _save_geometry(w)
    local m = _loaded()
    if m == nil then
        return
    end
    m.cx, m.cy, m.diameter = w.cx, w.cy, w.diameter
    if State.settings ~= nil then
        State.settings.minimap = MM.normalize(m)
        w.cfg = State.settings.minimap
    end
    pcall(LUI.Settings.Persistence.save_settings)
end

-- crea / quita / rehace el aura segun Opciones (se llama al cargar LUI y
-- al guardar la configuracion)
function Apply.minimap_settings()
    local old = Windows.minimap_aura
    if old ~= nil then
        if old.placing ~= nil then
            old:end_placement(false)
            MM._on_end = nil
        end
        pcall(old.destroy, old)
        Windows.minimap_aura = nil
    end
    local cfg = MM.normalize(_settings())
    if cfg.enabled ~= true then
        return
    end
    local ok, w = pcall(AuraWindow, cfg)
    if ok == true then
        Windows.minimap_aura = w
    else
        Turbine.Shell.WriteLine(PREFIX .. tostring(w))
    end
end

-- empieza a colocar; on_end se llama al terminar (por ejemplo para volver
-- a abrir Opciones)
function MM.start_placement(on_end)
    local w = Windows.minimap_aura
    if w == nil then
        Turbine.Shell.WriteLine(PREFIX .. "est\195\161 apagado (/lui minimapa on)")
        if on_end ~= nil then
            pcall(on_end)
        end
        return false
    end
    MM._on_end = on_end
    w:begin_placement("own")
    return true
end

function MM.finish_placement(keep)
    local w = Windows.minimap_aura
    local changed = false
    if w ~= nil and w.placing ~= nil then
        changed = w:end_placement(keep)
        if changed == true then
            _save_geometry(w)
            Turbine.Shell.WriteLine(PREFIX .. "guardado (" .. tostring(w.diameter) .. " px)")
        end
    end
    local cb = MM._on_end
    MM._on_end = nil
    if cb ~= nil then
        pcall(cb)
    end
    return changed
end

function MM.is_placing()
    local w = Windows.minimap_aura
    return w ~= nil and w.placing ~= nil
end

-- "/lui move": el aura se mueve junto con las demas ventanas de LUI
function MM.on_move_mode(enabled, cancel)
    local w = Windows.minimap_aura
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

-- boton "Colocar sobre el minimapa" de Opciones: guarda esta pestana,
-- enciende el aura, esconde Opciones mientras se coloca y la vuelve a abrir
function MM.place_from_config(after)
    local m = _loaded()
    if m == nil then
        return
    end
    m.enabled = true
    pcall(LUI.Settings.rebuild)
    Apply.minimap_settings()
    pcall(LUI.Settings.Persistence.save_settings)
    local cfgwin = Windows.config
    local reopen = cfgwin ~= nil and cfgwin:IsVisible() == true
    if reopen then
        cfgwin:SetVisible(false)
    end
    MM.start_placement(function()
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

function MM.shutdown()
    local w = Windows.minimap_aura
    if w ~= nil then
        if w.placing ~= nil then
            w:end_placement(false)
        end
        MM._on_end = nil
        pcall(w.destroy, w)
        Windows.minimap_aura = nil
    end
end
