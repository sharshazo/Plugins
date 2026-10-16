-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- (2026-10-16) Disenos y animaciones de las reutilizaciones (cola de
-- habilidades), el mismo sistema que los efectos (ExpiringEffects/effect_fx).
--
-- Disenos: "classic" (como siempre), "bar" (barra integrada) e "icons"
-- (solo iconos con el tiempo encima y barrido).
-- Animaciones: 1 entrada deslizante, 2 brillo en la barra, 3 latido al
-- acabarse (< 3 s), 4 barrido circular del icono, 5 destello al quedar
-- lista, 6 salida desvanecida.
--
-- No cambia la logica de la ventana: envuelve apply_settings y
-- update_remaining de CooldownEntry y agrega controles propios. Todo va
-- protegido: si algo falla, la entrada se ve como la clasica.

import "Turbine.UI"

local Cooldowns = _G.LUI.Features.Cooldowns
local State = _G.LUI.Settings.State
local Utils = _G.LUI.Utils

local FX = {}
Cooldowns.FX = FX

local DIR = "LUI/assets/ui/efectos/"
local SWEEP_SIZES = { 16, 20, 24, 28, 32, 36, 40, 44, 48, 56, 64 }
local SWEEP_FRAMES = 32
local SWEEP_COLS = 8
local SHINE_W = 24
local SPEED_MULT = { [1] = 1.5, [2] = 1.0, [3] = 0.6 }

local GREEN = Turbine.UI.Color(1, 0.45, 1, 0.45)
local WHITE = Turbine.UI.Color(1, 1, 1, 1)
local DARK = Turbine.UI.Color(0.88, 0.05, 0.055, 0.07)
local HILITE = Turbine.UI.Color(0.28, 1, 1, 1)
local CLEAR = Turbine.UI.Color(0, 0, 0, 0)

local function _now()
    return Turbine.Engine.GetGameTime()
end

local function _settings()
    return State.settings.self.cooldowns
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
        return Turbine.UI.Color(a, 0, 0.55, 0.55)
    end
    return Turbine.UI.Color(a, color.R, color.G, color.B)
end

local function _ensure(self)
    if self._fx ~= nil then
        return self._fx
    end
    local f = {}
    -- marco de color del icono (detras del icono)
    f.ring = _ctl(self, 1)
    self.icon_background:SetZOrder(2)
    -- encima del icono
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
    -- sobre la barra
    f.hilite = _ctl(self.bar_fill, 5)
    f.hilite:SetBackColor(HILITE)
    f.shine = _ctl(self.bar_fill, 6)
    pcall(f.shine.SetBackground, f.shine, DIR .. "brillo.tga")
    self._fx = f
    return f
end

local function _set_icon_inner(self, inner)
    self._icon_size = inner
    self.icon:SetPosition(0, 0)
    self.icon:set_size(inner, inner)
    if self.skill ~= nil and self.skill.icon ~= nil then
        self._shown_icon = self.skill.icon
        self.icon:set_icon(self.skill.icon, inner, inner)
    end
end

---------------------------------------------------------------------
-- Despues de apply_settings
---------------------------------------------------------------------

local function _after_apply(self, s)
    local style = _style(s)
    local f = _ensure(self)
    f.style = style
    f.dx = 0
    f.base_x = nil
    f.opacity = 1
    f.time_color = nil
    f.sweep_frame = -1
    f.tint_a = -1
    f.name_key = nil
    f.name_text = nil
    f.ring:SetVisible(false)
    self.bar_background:SetVisible(true)

    local color = s.color ~= nil and s.color.bar or nil
    local bx, by = self.icon_background:GetPosition()
    local iw = self.icon_background:GetWidth()
    local inner = iw

    if style == "icons" then
        local sz = tonumber(s.icon_size) or 36
        local b = 2
        self:SetSize(sz, sz)
        self.bar_background:SetVisible(false)
        self.separator:SetVisible(false)
        local bc = _with_alpha(color, 1)
        self.border_top:SetPosition(0, 0)
        self.border_top:SetSize(sz, b)
        self.border_bottom:SetPosition(0, sz - b)
        self.border_bottom:SetSize(sz, b)
        self.border_left:SetPosition(0, 0)
        self.border_left:SetSize(b, sz)
        self.border_right:SetPosition(sz - b, 0)
        self.border_right:SetSize(b, sz)
        self.border_top:SetBackColor(bc)
        self.border_bottom:SetBackColor(bc)
        self.border_left:SetBackColor(bc)
        self.border_right:SetBackColor(bc)
        inner = sz - 2 * b
        self.icon_background:SetPosition(b, b)
        self.icon_background:SetSize(inner, inner)
        _set_icon_inner(self, inner)
    elseif style == "bar" then
        -- marco de color alrededor del icono
        local b = (iw >= 24) and 2 or 1
        inner = iw - 2 * b
        if inner < 1 then inner = 1 end
        f.ring:SetPosition(bx, by)
        f.ring:SetSize(iw, iw)
        f.ring:SetBackColor(_with_alpha(color, 1))
        f.ring:SetVisible(true)
        self.icon_background:SetPosition(bx + b, by + b)
        self.icon_background:SetSize(inner, inner)
        _set_icon_inner(self, inner)
        self.bar_background:SetBackColor(DARK)
        self.bar_fill:SetBackColor(_with_alpha(color, 0.85))
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

    if style == "icons" then
        local size = inner >= 40 and 16 or (inner >= 30 and 14 or 12)
        if Utils.FONT_TO_LOTRO ~= nil then
            local ok, fnt = pcall(Utils.FONT_TO_LOTRO, s.font.name, size)
            if ok and fnt ~= nil then
                f.time:SetFont(fnt)
            end
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

    f.shine:SetVisible(false)
    if style ~= "icons" and self.vertical ~= true then
        f.shine:SetSize(SHINE_W, math.max(1, fh))
        f.shine:SetPosition(-SHINE_W, 0)
    end

    self:SetOpacity(1)
end

---------------------------------------------------------------------
-- Cada cuadro
---------------------------------------------------------------------

local function _fit_name(self, s, f)
    local rec = self.skill
    local name = tostring(rec.name or "")
    if f.name_key == rec and f.name_src == name then
        return
    end
    f.name_key = rec
    f.name_src = name
    local width = self.name_label:GetWidth()
    local est = Utils.lui_timed_row_estimate_text_width
    if est == nil or width <= 0 then
        f.name_text = name
        return
    end
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

local function _set_time_color(f, label, c)
    if f.time_color ~= c then
        f.time_color = c
        label:SetForeColor(c)
    end
end

local function _born(self, now)
    local win = self:GetParent()
    local rec = self.skill
    if type(win) ~= "table" or rec == nil then
        return -100
    end
    if win._cdfx_seen == nil then
        win._cdfx_seen = setmetatable({}, { __mode = "k" })
        win._cdfx_born = setmetatable({}, { __mode = "k" })
        win._cdfx_ready_at = now + 1.5   -- lo que ya estaba al cargar no se anima
    end
    local seen = win._cdfx_seen[rec]
    if seen == nil or now - seen > 0.3 then
        win._cdfx_born[rec] = (now >= win._cdfx_ready_at) and now or -100
    end
    win._cdfx_seen[rec] = now
    return win._cdfx_born[rec] or -100
end

local function _after_update(self, s, remaining, base)
    local f = self._fx
    if f == nil then
        return
    end
    if self.skill == nil or type(remaining) ~= "number" then
        if f.opacity ~= 1 then
            f.opacity = 1
            self:SetOpacity(1)
        end
        if f.dx ~= 0 and f.base_x ~= nil then
            f.dx = 0
            self:SetPosition(f.base_x, f.base_y)
        end
        f.sweep_clip:SetVisible(false)
        f.tint:SetVisible(false)
        f.shine:SetVisible(false)
        return
    end

    local now = _now()
    local sp = _speed(s)
    local style = f.style
    local born = _born(self, now)
    local age = now - born

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
            dx = -math.floor((1 - e) * math.min(40, self:GetWidth() * 0.3))
        end
    end
    if _on(s, "anim_fade") then
        local d = 0.5 * sp
        if remaining < d then
            local p = remaining / d
            if p < 0 then p = 0 end
            if p < op then op = p end
            dx = dx + math.floor((1 - p) * 8)
        end
    end
    if op < 0 then op = 0 end
    op = math.floor(op * 20 + 0.5) / 20
    if op ~= f.opacity then
        f.opacity = op
        self:SetOpacity(op)
    end
    if f.base_x == nil then
        f.base_x, f.base_y = self:GetPosition()
    end
    if dx ~= f.dx then
        f.dx = dx
        self:SetPosition(f.base_x + dx, f.base_y)
    end

    -- tiempo
    if style == "icons" then
        local fmt = Utils.lui_format_cooldown_time
        if fmt ~= nil then
            f.time:SetText(fmt(math.max(0, remaining), s.time_format))
        end
    end
    if style ~= "classic" then
        local label = (style == "icons") and f.time or self.time_label
        if remaining < 3 then
            _set_time_color(f, label, GREEN)
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

    -- 4 barrido (la parte oscura es el tiempo que falta)
    if f.sweep_size ~= nil and _on(s, "anim_sweep") then
        local frame = math.floor(pct * (SWEEP_FRAMES - 1) + 0.5)
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

    -- 3 latido (< 3 s) y 5 destello al quedar lista -> capa dorada
    local tint = 0
    if _on(s, "anim_pulse") and remaining < 3 then
        tint = 0.35 * math.abs(math.sin(now * math.pi * 3 / sp))
    end
    if _on(s, "anim_flash") then
        local d = 0.6 * sp
        if remaining < d then
            local fl = 0.65 * math.abs(math.sin((1 - remaining / d) * math.pi * 2))
            if fl > tint then tint = fl end
        end
    end
    tint = math.floor(tint * 20 + 0.5) / 20
    if tint ~= f.tint_a then
        f.tint_a = tint
        if tint > 0 then
            f.tint:SetBackColor(Turbine.UI.Color(tint, 1, 0.85, 0.35))
            f.tint:SetVisible(true)
        else
            f.tint:SetVisible(false)
        end
    end

    -- 2 brillo que recorre la barra (cada 2.5 s)
    if style ~= "icons" and self.vertical ~= true and _on(s, "anim_shine") then
        local period = 2.5 * sp
        local travel = 0.8 * sp
        local t = (now - born) % period
        if t < travel then
            local len = self.bar_fill:GetWidth()
            f.shine:SetPosition(math.floor(-SHINE_W + (t / travel) * (len + SHINE_W)), 0)
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
-- Instalacion
---------------------------------------------------------------------

function FX.report(err)
    if FX._reported == true then
        return
    end
    FX._reported = true
    pcall(Turbine.Shell.WriteLine, "<rgb=#3399FA>LUI</rgb> reutilizaciones: " .. tostring(err))
end

local function _install(cls)
    if cls == nil or cls._fx_installed == true then
        return
    end
    cls._fx_installed = true

    local orig_apply = cls.apply_settings
    cls.apply_settings = function(self, ...)
        -- la ventana vuelve a poner la posicion despues: se olvida el desplazamiento
        if self._fx ~= nil then
            self._fx.dx = 0
            self._fx.base_x = nil
        end
        orig_apply(self, ...)
        local ok, err = pcall(_after_apply, self, _settings())
        if not ok then
            FX.report(err)
        end
    end

    local orig_update = cls.update_remaining
    cls.update_remaining = function(self, remaining, base)
        orig_update(self, remaining, base)
        local ok, err = pcall(_after_update, self, _settings(), remaining, base)
        if not ok then
            FX.report(err)
        end
    end
end

_install(Cooldowns.CooldownEntry)
