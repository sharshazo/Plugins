-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- (2026-10-16) Disenos y animaciones de los efectos que expiran (beneficios
-- y perjuicios propios y del objetivo). Pedido del jugador.
--
-- Disenos (opcion "style"):
--   "classic" - como siempre (no se toca nada).
--   "bar"     - barra de tiempo integrada: fondo oscuro, barra del color del
--               tipo de efecto con brillo arriba, borde del icono del mismo
--               color, nombre en una linea y tiempo que cambia de color.
--   "icons"   - solo iconos: icono grande con borde de color, tiempo encima
--               y barrido oscuro (el nombre no se muestra).
-- Animaciones (cada una se activa aparte):
--   1 entrada deslizante, 2 brillo que recorre la barra, 3 latido al
--   acabarse (< 3 s), 4 barrido circular del icono, 5 destello de perjuicio
--   nuevo, 6 salida desvanecida.
--
-- No cambia la logica de las entradas: envuelve apply_settings,
-- _apply_bar_colors y update_remaining de las dos clases y agrega controles
-- propios encima. Todo lo que toca la API va protegido: si algo falla, el
-- efecto se ve como el clasico.

import "Turbine.UI"

local ExpiringEffects = _G.LUI.Features.ExpiringEffects
local State = _G.LUI.Settings.State
local Utils = _G.LUI.Utils

local FX = {}
ExpiringEffects.FX = FX

local DIR = "LUI/assets/ui/efectos/"
local SWEEP_SIZES = { 16, 20, 24, 28, 32, 36, 40, 44, 48, 56, 64 }
local SWEEP_FRAMES = 32
local SWEEP_COLS = 8
local SHINE_W = 24
local SPEED_MULT = { [1] = 1.5, [2] = 1.0, [3] = 0.6 }
FX.ICON_SIZES = { 28, 32, 36, 40, 48 }

local WHITE = Turbine.UI.Color(1, 1, 1, 1)
local YELLOW = Turbine.UI.Color(1, 1, 0.84, 0.35)
local RED = Turbine.UI.Color(1, 1, 0.32, 0.27)
local DARK = Turbine.UI.Color(0.88, 0.05, 0.055, 0.07)
local HILITE = Turbine.UI.Color(0.28, 1, 1, 1)
local CLEAR = Turbine.UI.Color(0, 0, 0, 0)

local function _now()
    return Turbine.Engine.GetGameTime()
end

local function _speed(s)
    return SPEED_MULT[tonumber(s.anim_speed) or 2] or 1
end

local function _style(s)
    local v = s.style
    if v == "bar" or v == "icons" then
        return v
    end
    return "classic"
end

local function _on(s, key)
    return s[key] ~= false
end

-- tamano de la hoja de barrido mas grande que entra en el icono
local function _sweep_size(inner)
    local best = nil
    for i = 1, #SWEEP_SIZES do
        if SWEEP_SIZES[i] <= inner then
            best = SWEEP_SIZES[i]
        end
    end
    return best
end

local function _ctl(parent, z)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    if z ~= nil then
        c:SetZOrder(z)
    end
    pcall(c.SetBlendMode, c, Turbine.UI.BlendMode.AlphaBlend)
    pcall(c.SetBackColorBlendMode, c, Turbine.UI.BlendMode.AlphaBlend)
    c:SetVisible(false)
    return c
end

local function _with_alpha(color, a)
    if color == nil then
        return Turbine.UI.Color(a, 1, 1, 1)
    end
    return Turbine.UI.Color(a, color.R, color.G, color.B)
end

---------------------------------------------------------------------
-- Controles propios (se crean una sola vez por entrada)
---------------------------------------------------------------------

local function _ensure(self)
    if self._fx ~= nil then
        return self._fx
    end
    local f = {}
    -- encima del icono (hijos de icon_background, que recorta)
    f.sweep_clip = _ctl(self.icon_background, 20)
    f.sweep = _ctl(f.sweep_clip)
    f.tint = _ctl(self.icon_background, 21)
    f.time = _G.LUI.UI.Widgets.LuiLabel()
    f.time:SetParent(self.icon_background)
    f.time:SetMouseVisible(false)
    f.time:SetZOrder(22)
    pcall(f.time.SetMultiline, f.time, false)
    f.time:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    f.time:SetFontStyle(Turbine.UI.FontStyle.Outline)
    f.time:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
    f.time:SetVisible(false)
    -- sobre la barra (hijos de bar_fill: solo se ven sobre la parte llena)
    f.hilite = _ctl(self.bar_fill, 5)
    f.hilite:SetBackColor(HILITE)
    f.shine = _ctl(self.bar_fill, 6)
    pcall(f.shine.SetBackground, f.shine, DIR .. "brillo.tga")
    -- velo oscuro para la entrada y la salida (la opacidad solo funciona
    -- en ventanas, no en controles)
    f.veil = _ctl(self, 50)
    f.veil:SetBackColor(CLEAR)
    -- estado
    f.opacity = 1
    f.time_color = nil
    f.sweep_frame = -1
    f.tint_a = -1
    f.dx = 0
    f.name_key = nil
    self._fx = f
    return f
end

---------------------------------------------------------------------
-- Despues de apply_settings: arma el diseno elegido
---------------------------------------------------------------------

local function _after_apply(self, s)
    local style = _style(s)
    local f = _ensure(self)
    f.style = style
    f.dx = 0
    f.opacity = 1
    f.time_color = nil
    f.sweep_frame = -1
    f.tint_a = -1
    f.name_key = nil

    -- posiciones base (para la entrada deslizante)
    f.bar_x, f.bar_y = self.bar_border:GetPosition()
    f.icon_x, f.icon_y = self.icon_border:GetPosition()
    self.bar_border:SetVisible(true)

    local icon_w = self.icon_border:GetWidth()

    if style == "icons" then
        local sz = tonumber(s.icon_size) or 36
        self:SetSize(sz, sz)
        self.bar_border:SetVisible(false)
        self.icon_border:SetPosition(0, 0)
        self.icon_border:SetSize(sz, sz)
        f.icon_x, f.icon_y = 0, 0
        icon_w = sz
    end

    local inner = icon_w
    if style ~= "classic" then
        -- borde de color alrededor del icono
        local b = (icon_w >= 24) and 2 or 1
        inner = icon_w - (2 * b)
        if inner < 1 then inner = 1 end
        self.icon_background:SetPosition(b, b)
        self.icon_background:SetSize(inner, inner)
        self.icon:SetPosition(0, 0)
        self.icon:SetSize(inner, inner)
    end
    f.inner = inner

    -- barrido
    local ss = _sweep_size(inner)
    f.sweep_size = ss
    if ss ~= nil then
        local off = math.floor((inner - ss) / 2)
        f.sweep_clip:SetPosition(off, off)
        f.sweep_clip:SetSize(ss, ss)
        f.sweep:SetSize(ss * SWEEP_COLS, ss * (SWEEP_FRAMES / SWEEP_COLS))
        f.sweep:SetPosition(0, 0)
        pcall(f.sweep.SetBackground, f.sweep, DIR .. "barrido_" .. ss .. ".tga")
        f.sweep:SetVisible(true)
    end
    f.sweep_clip:SetVisible(false)

    f.tint:SetPosition(0, 0)
    f.tint:SetSize(inner, inner)
    f.tint:SetBackColor(CLEAR)
    f.tint:SetVisible(false)

    -- tiempo encima del icono (solo iconos)
    if style == "icons" then
        local size = inner >= 40 and 16 or (inner >= 30 and 14 or 12)
        local font = nil
        if Utils.FONT_TO_LOTRO ~= nil then
            local ok, fnt = pcall(Utils.FONT_TO_LOTRO, s.font.name, size)
            if ok then font = fnt end
        end
        if font ~= nil then
            f.time:SetFont(font)
        end
        f.time:SetFontStyle(Turbine.UI.FontStyle.Outline)
        f.time:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
        f.time:SetPosition(0, 0)
        f.time:SetSize(inner, inner)
        f.time:SetVisible(true)
        self.time_label:SetVisible(false)
        self.name_label:SetVisible(false)
    else
        f.time:SetVisible(false)
    end

    -- barra integrada
    local fw, fh = self.bar_fill:GetSize()
    if style == "bar" and self.vertical ~= true then
        pcall(self.name_label.SetMultiline, self.name_label, false)
        f.hilite:SetPosition(0, 0)
        f.hilite:SetSize(math.max(fw, self.bar_inner_len or fw), (fh >= 14) and 2 or 1)
        f.hilite:SetVisible(true)
    else
        f.hilite:SetVisible(false)
    end
    if style == "classic" then
        pcall(self.name_label.SetMultiline, self.name_label, true)
    end

    -- brillo (barras horizontales de clasico y barra integrada)
    f.shine:SetVisible(false)
    if style ~= "icons" and self.vertical ~= true then
        f.shine:SetSize(SHINE_W, math.max(1, fh))
        f.shine:SetPosition(-SHINE_W, 0)
    end

    local ew, eh = self:GetSize()
    f.veil:SetPosition(0, 0)
    f.veil:SetSize(ew, eh)
    f.veil:SetBackColor(CLEAR)
    f.veil:SetVisible(false)
end

---------------------------------------------------------------------
-- Despues de _apply_bar_colors: colores del diseno
---------------------------------------------------------------------

local function _after_colors(self, s)
    local f = self._fx
    if f == nil or f.style == "classic" then
        return
    end
    local ok, color = pcall(self._resolve_bar_color, self)
    if not ok or color == nil then
        return
    end
    f.type_color = color
    self.icon_border:SetBackColor(_with_alpha(color, 1))
    if f.style == "bar" then
        self.bar_background:SetBackColor(DARK)
        self.bar_fill:SetBackColor(_with_alpha(color, 0.85))
    end
end

---------------------------------------------------------------------
-- Cada cuadro: animaciones
---------------------------------------------------------------------

local function _store(self)
    local win = self:GetParent()
    if type(win) ~= "table" then
        return nil
    end
    if win._fx_born == nil then
        win._fx_born = {}
        win._fx_prune_at = 0
        -- lo que ya estaba al cargar no se anima
        win._fx_ready_at = _now() + 1
    end
    return win
end

local function _fit_name(self, s, f)
    local key = self.effect_key
    if f.name_key == key then
        return
    end
    f.name_key = key
    local name = tostring(self.effect:GetName() or "")
    local width = self.name_label:GetWidth()
    local est = Utils.lui_timed_row_estimate_text_width
    if est == nil or width <= 0 then
        f.name_text = name
    else
        local text = name
        local ok, w = pcall(est, text, s.font.name, s.font.size)
        while ok and w > width and string.len(text) > 4 do
            text = string.sub(name, 1, string.len(text) - 2)
            ok, w = pcall(est, text .. "...", s.font.name, s.font.size)
            if ok and w <= width then
                text = text .. "..."
                break
            end
        end
        f.name_text = text
    end
end

local function _set_time_color(f, label, c)
    if f.time_color ~= c then
        f.time_color = c
        label:SetForeColor(c)
    end
end

local function _after_update(self, s, remaining, base)
    local f = self._fx
    if f == nil then
        return
    end
    if self.effect == nil or type(remaining) ~= "number" then
        if f.opacity ~= 1 then
            f.opacity = 1
            f.veil:SetVisible(false)
        end
        f.sweep_clip:SetVisible(false)
        f.tint:SetVisible(false)
        f.shine:SetVisible(false)
        if f.style == "icons" then
            f.time:SetText("")
        end
        return
    end

    local now = _now()
    local sp = _speed(s)
    local style = f.style
    local key = self.effect_key or 0

    -- nacimiento del efecto (por ventana, asi sirve aunque cambie de casilla)
    local win = _store(self)
    local born = -100   -- sin identificador: sin animacion de entrada
    if win ~= nil and key ~= 0 then
        local b = win._fx_born[key]
        if b == nil then
            local is_debuff = self.effect.IsDebuff ~= nil and self.effect:IsDebuff() == true
            b = { t = (now >= win._fx_ready_at) and now or -100, debuff = is_debuff }
            win._fx_born[key] = b
        end
        b.seen = now
        born = b.t
        if now >= win._fx_prune_at then
            win._fx_prune_at = now + 30
            for k, v in pairs(win._fx_born) do
                if now - (v.seen or v.t) > 60 then
                    win._fx_born[k] = nil
                end
            end
        end
    end
    local age = now - born

    -- base del porcentaje (igual que la entrada)
    if type(base) ~= "number" or base <= 0 then
        base = remaining
    end
    local pct = (base > 0) and (remaining / base) or 0
    if pct < 0 then pct = 0 end
    if pct > 1 then pct = 1 end

    -- 1 entrada deslizante + 6 salida desvanecida
    local op = 1
    local dx = 0
    if _on(s, "anim_slide") then
        local d = 0.35 * sp
        if age < d then
            local p = age / d
            local e = 1 - (1 - p) * (1 - p) * (1 - p)
            op = e
            dx = -math.floor((1 - e) * self:GetWidth() * 0.6)
        end
    end
    if _on(s, "anim_fade") then
        local d = 0.5 * sp
        if remaining < d then
            local p = remaining / d
            if p < op then op = p end
            dx = dx + math.floor((1 - p) * 10)
        end
    end
    if op < 0 then op = 0 end
    op = math.floor(op * 20 + 0.5) / 20
    if op ~= f.opacity then
        f.opacity = op
        if op < 1 then
            f.veil:SetBackColor(Turbine.UI.Color(0.85 * (1 - op), 0.02, 0.02, 0.03))
            f.veil:SetVisible(true)
        else
            f.veil:SetVisible(false)
        end
    end
    if dx ~= f.dx then
        f.dx = dx
        if style ~= "icons" then
            self.bar_border:SetPosition(f.bar_x + dx, f.bar_y)
        end
        self.icon_border:SetPosition(f.icon_x + dx, f.icon_y)
    end

    -- tiempo (colores en los disenos nuevos)
    if style == "icons" then
        f.time:SetText(Utils.lui_timed_row_format_time(remaining, Utils.lui_timed_row_time_format.AUTO))
    end
    if style ~= "classic" then
        local label = (style == "icons") and f.time or self.time_label
        if remaining < 3 then
            _set_time_color(f, label, RED)
        elseif remaining < 10 then
            _set_time_color(f, label, YELLOW)
        else
            _set_time_color(f, label, s.font.color or WHITE)
        end
    end
    if style == "bar" and self.vertical ~= true then
        _fit_name(self, s, f)
        if f.name_text ~= nil then
            self.name_label:SetText(f.name_text)
        end
    end

    -- 4 barrido circular
    if f.sweep_size ~= nil and _on(s, "anim_sweep") then
        local frame = math.floor((1 - pct) * (SWEEP_FRAMES - 1) + 0.5)
        if frame ~= f.sweep_frame then
            f.sweep_frame = frame
            local ss = f.sweep_size
            f.sweep:SetPosition(-(frame % SWEEP_COLS) * ss, -math.floor(frame / SWEEP_COLS) * ss)
        end
        if f.sweep_clip:IsVisible() ~= true then
            f.sweep_clip:SetVisible(true)
        end
    elseif f.sweep_clip:IsVisible() == true then
        f.sweep_clip:SetVisible(false)
    end

    -- 3 latido (< 3 s) y 5 destello de perjuicio nuevo -> capa roja
    local tint = 0
    if _on(s, "anim_pulse") and remaining < 3 then
        tint = 0.38 * math.abs(math.sin(now * math.pi * 3 / sp))
    end
    local b = (win ~= nil and key ~= 0) and win._fx_born[key] or nil
    if _on(s, "anim_flash") and b ~= nil and b.debuff == true then
        local d = 0.9 * sp
        if age < d then
            local fl = 0.6 * math.abs(math.sin((age / d) * math.pi * 3))
            if fl > tint then tint = fl end
        end
    end
    tint = math.floor(tint * 20 + 0.5) / 20
    if tint ~= f.tint_a then
        f.tint_a = tint
        if tint > 0 then
            f.tint:SetBackColor(Turbine.UI.Color(tint, 1, 0.15, 0.1))
            f.tint:SetVisible(true)
            if style ~= "classic" then
                self.icon_border:SetBackColor(Turbine.UI.Color(1, 1, 0.25 + 0.5 * (1 - tint), 0.2))
            end
        else
            f.tint:SetVisible(false)
            if style ~= "classic" and f.type_color ~= nil then
                self.icon_border:SetBackColor(_with_alpha(f.type_color, 1))
            end
        end
    end

    -- 2 brillo que recorre la barra (cada 2.5 s)
    if style ~= "icons" and self.vertical ~= true and _on(s, "anim_shine") then
        local period = 2.5 * sp
        local travel = 0.8 * sp
        local t = (now - born) % period
        if t < travel then
            local len = self.bar_fill:GetWidth()
            local x = math.floor(-SHINE_W + (t / travel) * (len + SHINE_W))
            f.shine:SetPosition(x, 0)
            if f.shine:IsVisible() ~= true then
                f.shine:SetVisible(true)
            end
        elseif f.shine:IsVisible() == true then
            f.shine:SetVisible(false)
        end
    elseif f.shine:IsVisible() == true then
        f.shine:SetVisible(false)
    end
end

---------------------------------------------------------------------
-- Instalacion en las dos clases de entradas
---------------------------------------------------------------------

function FX.install(cls, settings_fn)
    if cls == nil or cls._fx_installed == true then
        return
    end
    cls._fx_installed = true

    local orig_apply = cls.apply_settings
    cls.apply_settings = function(self, ...)
        orig_apply(self, ...)
        local ok, err = pcall(_after_apply, self, settings_fn())
        if not ok then
            FX.report(err)
        end
        pcall(cls._apply_bar_colors, self)
    end

    local orig_colors = cls._apply_bar_colors
    cls._apply_bar_colors = function(self, ...)
        orig_colors(self, ...)
        local ok, err = pcall(_after_colors, self, settings_fn())
        if not ok then
            FX.report(err)
        end
    end

    local orig_update = cls.update_remaining
    cls.update_remaining = function(self, remaining, base)
        orig_update(self, remaining, base)
        local ok, err = pcall(_after_update, self, settings_fn(), remaining, base)
        if not ok then
            FX.report(err)
        end
    end
end

-- un error se avisa una sola vez (no se llena el chat)
function FX.report(err)
    if FX._reported == true then
        return
    end
    FX._reported = true
    pcall(Turbine.Shell.WriteLine, "<rgb=#3399FA>LUI</rgb> efectos: " .. tostring(err))
end

FX.install(ExpiringEffects.SelfExpiringEffectEntry, function()
    return State.settings.self.expiring_effects
end)
FX.install(ExpiringEffects.TargetExpiringEffectEntry, function()
    return State.settings.target.expiring_effects
end)
