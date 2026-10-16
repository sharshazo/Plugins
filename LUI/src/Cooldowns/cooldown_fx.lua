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
-- (2026-10-16 b) El icono de la habilidad es una imagen ESTIRADA, y el juego
-- dibuja las imagenes estiradas por encima de todos los controles de su
-- ventana (ver Upkeep/upkeep_window.lua). Por eso el numero, el barrido y
-- los destellos van en una ventanita compania transparente que sigue a la
-- ventana de reutilizaciones, igual que hace el Upkeep. Y como la opacidad
-- solo funciona en ventanas, la entrada y la salida se hacen con un velo
-- oscuro en esa misma ventanita.
--
-- Opciones del numero: mostrar siempre / solo los ultimos X segundos /
-- nunca, tamano y posicion (centro, abajo, arriba).
--
-- No cambia la logica de la ventana: envuelve apply_settings y
-- update_remaining de CooldownEntry. Todo va protegido: si algo falla, la
-- entrada se ve como la clasica.

import "Turbine.UI"

local Cooldowns = _G.LUI.Features.Cooldowns
local State = _G.LUI.Settings.State
local Utils = _G.LUI.Utils
local UI = _G.LUI.UI

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

-- (2026-10-16, rendimiento) colores animados creados una sola vez por
-- nivel (pasos de 1/20) y reutilizados: nada de objetos nuevos por cuadro
local _veil_colors = {}
local _tint_colors = {}

local function _veil_color(a)
    local c = _veil_colors[a]
    if c == nil then
        c = Turbine.UI.Color(a, 0.02, 0.02, 0.03)
        _veil_colors[a] = c
    end
    return c
end

local function _tint_color(a)
    local c = _tint_colors[a]
    if c == nil then
        c = Turbine.UI.Color(a, 1, 0.85, 0.35)
        _tint_colors[a] = c
    end
    return c
end

---------------------------------------------------------------------
-- Ventanita compania (una por ventana de reutilizaciones)
---------------------------------------------------------------------

local function _raise(ov)
    if ov:IsVisible() == true then
        pcall(ov.Activate, ov)
    end
end

local function _sync_overlay(ov)
    local win = ov.win
    local show = win:IsVisible() == true
    if show and win.is_move_mode ~= nil and win:is_move_mode() == true then
        show = false
    end
    if show ~= (ov:IsVisible() == true) then
        ov:SetVisible(show)
        if show then
            _raise(ov)
        end
    end
    if not show then
        return
    end
    local x, y = win:GetPosition()
    if x ~= ov.px or y ~= ov.py then
        ov.px, ov.py = x, y
        ov:SetPosition(x, y)
    end
    local w, h = win:GetSize()
    if w ~= ov.pw or h ~= ov.ph then
        ov.pw, ov.ph = w, h
        ov:SetSize(w, h)
    end
    for entry, g in pairs(ov.groups) do
        local ev = entry:IsVisible() == true and entry.skill ~= nil
        if (g.root:IsVisible() == true) ~= ev then
            g.root:SetVisible(ev)
        end
        if ev then
            local ex, ey = entry:GetPosition()
            if ex ~= g.ex or ey ~= g.ey then
                g.ex, g.ey = ex, ey
                g.root:SetPosition(ex, ey)
            end
        end
    end
end

local function _overlay_for(win)
    if type(win) ~= "table" then
        return nil
    end
    if win._cdfx_overlay ~= nil then
        return win._cdfx_overlay
    end
    local ok, ov = pcall(function()
        local o = UI.Widgets.LuiBaseWindow({ hideable = true })
        o:SetVisible(false)
        o:SetMouseVisible(false)
        if UI.NativeScaling ~= nil and UI.NativeScaling.apply_window ~= nil then
            pcall(UI.NativeScaling.apply_window, o)
        end
        return o
    end)
    if ok ~= true or ov == nil then
        return nil
    end
    ov.win = win
    ov.groups = setmetatable({}, { __mode = "k" })
    ov.Update = function()
        local okk, err = pcall(_sync_overlay, ov)
        if okk ~= true then
            FX.report(err)
            ov:SetWantsUpdates(false)
        end
    end
    ov:SetWantsUpdates(true)
    -- como el Upkeep: si se activa la ventana (modo mover), la compania
    -- vuelve a quedar encima
    if Utils.add_callback ~= nil then
        pcall(Utils.add_callback, win, "Activated", function()
            _raise(ov)
        end)
    end
    win._cdfx_overlay = ov
    return ov
end

---------------------------------------------------------------------
-- Controles de cada entrada
---------------------------------------------------------------------

local function _ensure(self)
    if self._fx ~= nil then
        return self._fx
    end
    local f = {}
    -- en la ventana principal: marco de color del icono y adornos de la barra
    f.ring = _ctl(self, 1)
    self.icon_background:SetZOrder(2)
    f.hilite = _ctl(self.bar_fill, 5)
    f.hilite:SetBackColor(HILITE)
    f.shine = _ctl(self.bar_fill, 6)
    pcall(f.shine.SetBackground, f.shine, DIR .. "brillo.tga")
    -- en la ventanita compania (encima del icono estirado)
    local ov = _overlay_for(self:GetParent())
    if ov ~= nil then
        local g = {}
        g.root = Turbine.UI.Control()
        g.root:SetParent(ov)
        g.root:SetMouseVisible(false)
        g.root:SetVisible(false)
        g.box = Turbine.UI.Control()
        g.box:SetParent(g.root)
        g.box:SetMouseVisible(false)
        g.sweep_clip = _ctl(g.box, 20)
        g.sweep = _ctl(g.sweep_clip)
        g.tint = _ctl(g.box, 21)
        g.time = UI.Widgets.LuiLabel()
        g.time:SetParent(g.box)
        g.time:SetMouseVisible(false)
        g.time:SetZOrder(22)
        pcall(g.time.SetMultiline, g.time, false)
        g.time:SetFontStyle(Turbine.UI.FontStyle.Outline)
        g.time:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
        g.time:SetVisible(false)
        g.veil = _ctl(g.root, 30)
        g.veil:SetBackColor(CLEAR)
        ov.groups[self] = g
        f.g = g
    end
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

local NUM_ALIGN = {
    center = Turbine.UI.ContentAlignment.MiddleCenter,
    bottom = Turbine.UI.ContentAlignment.BottomCenter,
    top = Turbine.UI.ContentAlignment.TopCenter,
}

---------------------------------------------------------------------
-- Despues de apply_settings
---------------------------------------------------------------------

local function _after_apply(self, s)
    local style = _style(s)
    local f = _ensure(self)
    f.style = style
    f.dx = 0
    f.base_x = nil
    f.veil_a = -1
    f.time_color = nil
    f.time_text = nil
    f.time_key = nil
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
        bx, by = b, b
        self.icon_background:SetPosition(b, b)
        self.icon_background:SetSize(inner, inner)
        _set_icon_inner(self, inner)
    elseif style == "bar" then
        local b = (iw >= 24) and 2 or 1
        inner = iw - 2 * b
        if inner < 1 then inner = 1 end
        f.ring:SetPosition(bx, by)
        f.ring:SetSize(iw, iw)
        f.ring:SetBackColor(_with_alpha(color, 1))
        f.ring:SetVisible(true)
        bx, by = bx + b, by + b
        self.icon_background:SetPosition(bx, by)
        self.icon_background:SetSize(inner, inner)
        _set_icon_inner(self, inner)
        self.bar_background:SetBackColor(DARK)
        self.bar_fill:SetBackColor(_with_alpha(color, 0.85))
    end
    f.inner = inner

    -- compania: caja del icono, barrido, destello, numero y velo
    local g = f.g
    if g ~= nil then
        local ew, eh = self:GetSize()
        g.root:SetSize(ew, eh)
        g.veil:SetPosition(0, 0)
        g.veil:SetSize(ew, eh)
        g.veil:SetBackColor(CLEAR)
        g.veil:SetVisible(false)
        g.box:SetPosition(bx, by)
        g.box:SetSize(inner, inner)

        local ss = _sweep_size(inner)
        f.sweep_size = ss
        if ss ~= nil then
            local off = math.floor((inner - ss) / 2)
            g.sweep_clip:SetPosition(off, off)
            g.sweep_clip:SetSize(ss, ss)
            g.sweep:SetSize(ss * SWEEP_COLS, ss * (SWEEP_FRAMES / SWEEP_COLS))
            g.sweep:SetPosition(0, 0)
            pcall(g.sweep.SetBackground, g.sweep, DIR .. "barrido_" .. ss .. ".tga")
            g.sweep:SetVisible(true)
        end
        g.sweep_clip:SetVisible(false)

        g.tint:SetPosition(0, 0)
        g.tint:SetSize(inner, inner)
        g.tint:SetBackColor(CLEAR)
        g.tint:SetVisible(false)

        if style == "icons" then
            local size = tonumber(s.num_size) or 0
            if size <= 0 then
                size = inner >= 40 and 16 or (inner >= 30 and 14 or 12)
            end
            if Utils.FONT_TO_LOTRO ~= nil then
                local ok, fnt = pcall(Utils.FONT_TO_LOTRO, s.font.name, size)
                if ok and fnt ~= nil then
                    g.time:SetFont(fnt)
                end
            end
            g.time:SetFontStyle(Turbine.UI.FontStyle.Outline)
            g.time:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
            g.time:SetTextAlignment(NUM_ALIGN[s.num_pos] or NUM_ALIGN.center)
            -- un poco mas ancho que el icono: un "1:30" grande no se corta
            g.time:SetPosition(-6, 0)
            g.time:SetSize(inner + 12, inner)
            g.time:SetText("")
            g.time:SetVisible(true)
            self.time_label:SetVisible(false)
            self.name_label:SetVisible(false)
        else
            g.time:SetVisible(false)
        end
    else
        f.sweep_size = nil
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

-- se muestra el numero ahora? (opcion "siempre / ultimos X s / nunca")
local function _show_number(s, remaining)
    local mode = s.num_mode
    if mode == "never" then
        return false
    end
    if mode == "last" then
        local from = tonumber(s.num_from) or 30
        return remaining <= from
    end
    return true
end

local function _format_number(s, remaining)
    if remaining < 0 then
        remaining = 0
    end
    if s.time_format == 2 then   -- segundos enteros
        local total = math.floor(remaining + 0.5)
        if total >= 60 then
            return string.format("%d:%02d", math.floor(total / 60), total % 60)
        end
        return tostring(total)
    end
    if Utils.lui_format_icon_timeout ~= nil then
        return Utils.lui_format_icon_timeout(remaining)
    end
    return tostring(math.floor(remaining))
end

local function _after_update(self, s, remaining, base)
    local f = self._fx
    if f == nil then
        return
    end
    local g = f.g
    if self.skill == nil or type(remaining) ~= "number" then
        if f.dx ~= 0 and f.base_x ~= nil then
            f.dx = 0
            self:SetPosition(f.base_x, f.base_y)
        end
        if g ~= nil then
            g.sweep_clip:SetVisible(false)
            g.tint:SetVisible(false)
            g.veil:SetVisible(false)
            f.veil_a = -1
        end
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

    -- 1 entrada deslizante + 6 salida desvanecida (velo oscuro + movimiento)
    local veil = 0
    local dx = 0
    if _on(s, "anim_slide") then
        local d = 0.35 * sp
        if age < d then
            local p = age / d
            local e = 1 - (1 - p) * (1 - p) * (1 - p)
            veil = 0.85 * (1 - e)
            dx = -math.floor((1 - e) * math.min(40, self:GetWidth() * 0.3))
        end
    end
    if _on(s, "anim_fade") then
        local d = 0.5 * sp
        if remaining < d then
            local p = remaining / d
            if p < 0 then p = 0 end
            local v = 0.85 * (1 - p)
            if v > veil then veil = v end
            dx = dx + math.floor((1 - p) * 8)
        end
    end
    if f.base_x == nil then
        f.base_x, f.base_y = self:GetPosition()
    end
    if dx ~= f.dx then
        f.dx = dx
        self:SetPosition(f.base_x + dx, f.base_y)
    end
    if g ~= nil then
        veil = math.floor(veil * 20 + 0.5) / 20
        if veil ~= f.veil_a then
            f.veil_a = veil
            if veil > 0 then
                g.veil:SetBackColor(_veil_color(veil))
                g.veil:SetVisible(true)
            else
                g.veil:SetVisible(false)
            end
        end
    end

    -- numero (opciones: siempre / ultimos X s / nunca)
    local show_num = _show_number(s, remaining)
    if style == "icons" then
        if g ~= nil then
            -- el texto solo se arma cuando cambia la decima de segundo
            local tkey = show_num and math.floor(remaining * 10) or -1
            if tkey ~= f.time_key then
                f.time_key = tkey
                local text = show_num and _format_number(s, remaining) or ""
                if text ~= f.time_text then
                    f.time_text = text
                    g.time:SetText(text)
                end
            end
            if remaining < 3 then
                _set_time_color(f, g.time, GREEN)
            else
                _set_time_color(f, g.time, s.font.color or WHITE)
            end
        end
    else
        if show_num ~= true and self.show_time then
            self.time_label:SetText("")
        end
        if style == "bar" then
            if remaining < 3 then
                _set_time_color(f, self.time_label, GREEN)
            else
                _set_time_color(f, self.time_label, s.font.color or WHITE)
            end
        end
    end
    if style == "bar" and self.vertical ~= true then
        _fit_name(self, s, f)
        if f.name_text ~= nil then
            self.name_label:SetText(f.name_text)
        end
    end

    if g ~= nil then
        -- 4 barrido (la parte oscura es el tiempo que falta)
        if f.sweep_size ~= nil and _on(s, "anim_sweep") then
            local frame = math.floor(pct * (SWEEP_FRAMES - 1) + 0.5)
            if frame ~= f.sweep_frame then
                f.sweep_frame = frame
                local ss = f.sweep_size
                g.sweep:SetPosition(-(frame % SWEEP_COLS) * ss, -math.floor(frame / SWEEP_COLS) * ss)
            end
            if g.sweep_clip:IsVisible() ~= true then
                g.sweep_clip:SetVisible(true)
            end
        elseif g.sweep_clip:IsVisible() == true then
            g.sweep_clip:SetVisible(false)
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
                g.tint:SetBackColor(_tint_color(tint))
                g.tint:SetVisible(true)
            else
                g.tint:SetVisible(false)
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
