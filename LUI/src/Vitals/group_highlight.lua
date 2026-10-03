-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Marcos de party / raid: efectos animados compartidos.
--
--   * Aura del seleccionado: un anillo de brillo que late POR FUERA del
--     marco del companero que tienes seleccionado. Va en una ventana propia
--     (invisible al mouse, no roba clics) porque los marcos de grupo estan
--     pegados entre si y dentro de la ventana del grupo; como hija del marco
--     quedaria recortada. Solo existe UNA a la vez (solo hay un objetivo).
--   * Aviso de vida baja: el relleno rojo de cada marco que esta por debajo
--     del % configurado late suave (los controles son del propio marco;
--     aqui solo se anima su transparencia).
--
-- Un unico control con Update anima todo, y solo pide updates mientras hay
-- algo que animar (sin seleccion y sin nadie con vida baja no gasta nada).
-- Todo lo que toca la API del juego va en pcall: un fallo aqui apaga el
-- efecto, nunca el marco.

import "Turbine.UI"

local Vitals = _G.LUI.Features.Vitals
local Highlight = Vitals.GroupHighlight or {}
Vitals.GroupHighlight = Highlight

local TICK = 0.05             -- 20 cuadros por segundo
local GLOW_RINGS = 5          -- ancho del aura en pixeles (1 px por anillo)
local GLOW_PERIOD = 1.6       -- segundos por latido del aura
local LOW_PERIOD = 1.0        -- segundos por latido del aviso de vida baja
local LOW_ALPHA_MIN = 0.10
local LOW_ALPHA_MAX = 0.40
local LOW_BORDER_ALPHA_MIN = 0.45
local LOW_BORDER_ALPHA_MAX = 1.00

local function _now()
    local ok, t = pcall(Turbine.Engine.GetGameTime)
    if ok == true and type(t) == "number" then
        return t
    end
    return 0
end

local function _pulse(now, period)
    -- 0..1..0 suave
    return 0.5 - 0.5 * math.cos((now % period) / period * 2 * math.pi)
end

---------------------------------------------------------------------
-- Aura (ventana propia)
---------------------------------------------------------------------

local function _new_ring_piece(parent)
    local piece = Turbine.UI.Control()
    piece:SetParent(parent)
    piece:SetMouseVisible(false)
    piece:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    piece:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    return piece
end

local function _create_glow_window()
    local window = Turbine.UI.Window()
    window:SetMouseVisible(false)
    window:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    window.rings = {}
    for i = 1, GLOW_RINGS do
        window.rings[i] = {
            top = _new_ring_piece(window),
            bottom = _new_ring_piece(window),
            left = _new_ring_piece(window),
            right = _new_ring_piece(window),
        }
    end
    window.frame_w = -1
    window.frame_h = -1
    window:SetVisible(false)
    return window
end

-- anillo i: 1 = pegado al marco, GLOW_RINGS = el mas externo
local function _layout_glow(window, frame_w, frame_h)
    if window.frame_w == frame_w and window.frame_h == frame_h then
        return
    end
    window.frame_w = frame_w
    window.frame_h = frame_h
    local pad = GLOW_RINGS
    window:SetSize(frame_w + pad * 2, frame_h + pad * 2)
    for i = 1, GLOW_RINGS do
        local ring = window.rings[i]
        local off = pad - i                -- borde interno del anillo
        local w = frame_w + i * 2
        local h = frame_h + i * 2
        ring.top:SetPosition(off, off)
        ring.top:SetSize(w, 1)
        ring.bottom:SetPosition(off, off + h - 1)
        ring.bottom:SetSize(w, 1)
        ring.left:SetPosition(off, off + 1)
        ring.left:SetSize(1, math.max(0, h - 2))
        ring.right:SetPosition(off + w - 1, off + 1)
        ring.right:SetSize(1, math.max(0, h - 2))
    end
end

local function _paint_glow(window, color, strength)
    local r, g, b = 1, 0.82, 0.25
    if color ~= nil then
        r, g, b = color.R or r, color.G or g, color.B or b
    end
    for i = 1, GLOW_RINGS do
        -- mas fuerte pegado al marco, se desvanece hacia afuera
        local falloff = 1 - (i - 1) / GLOW_RINGS
        local alpha = strength * falloff * falloff
        local c = Turbine.UI.Color(alpha, r, g, b)
        local ring = window.rings[i]
        ring.top:SetBackColor(c)
        ring.bottom:SetBackColor(c)
        ring.left:SetBackColor(c)
        ring.right:SetBackColor(c)
    end
end

-- el marco (y cada ventana que lo contiene) tiene que estar visible
local function _chain_visible(control)
    local node = control
    local depth = 0
    while node ~= nil and depth < 12 do
        if node:IsVisible() ~= true then
            return false
        end
        node = node:GetParent()
        depth = depth + 1
    end
    return true
end

local function _root_of(control)
    local node = control
    local depth = 0
    while node ~= nil and node:GetParent() ~= nil and depth < 12 do
        node = node:GetParent()
        depth = depth + 1
    end
    return node
end

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------

Highlight.glow_owner = nil
Highlight.low_members = Highlight.low_members or {}

local _ticker = nil
local _next_tick = 0

local function _has_low_members()
    return next(Highlight.low_members) ~= nil
end

local function _update_wants_updates()
    if _ticker == nil then
        return
    end
    local busy = Highlight.glow_owner ~= nil or _has_low_members()
    pcall(function()
        _ticker:SetWantsUpdates(busy)
    end)
end

local function _hide_glow()
    if Highlight.glow_window ~= nil then
        pcall(function()
            Highlight.glow_window:SetVisible(false)
        end)
    end
end

local function _update_glow(now)
    local owner = Highlight.glow_owner
    if owner == nil then
        _hide_glow()
        return
    end

    local ok = pcall(function()
        local anchor = owner.entity_control
        if anchor == nil or _chain_visible(owner) ~= true then
            Highlight.glow_window:SetVisible(false)
            return
        end
        local window = Highlight.glow_window
        local frame_w, frame_h = anchor:GetSize()
        if frame_w <= 0 or frame_h <= 0 then
            window:SetVisible(false)
            return
        end
        _layout_glow(window, frame_w, frame_h)
        local sx, sy = anchor:PointToScreen(0, 0)
        sx, sy = sx - GLOW_RINGS, sy - GLOW_RINGS
        if window._sx ~= sx or window._sy ~= sy then
            window._sx, window._sy = sx, sy
            window:SetPosition(sx, sy)
        end

        local root = _root_of(owner)
        if root ~= nil and root ~= window then
            local z = root:GetZOrder() or 0
            if window._z ~= z + 1 then
                window._z = z + 1
                window:SetZOrder(z + 1)
            end
        end

        local strength = 0.35 + 0.55 * _pulse(now, GLOW_PERIOD)
        _paint_glow(window, owner:_select_color(), strength)
        window:SetVisible(true)
    end)
    if ok ~= true then
        _hide_glow()
    end
end

local function _update_low(now)
    local p = _pulse(now, LOW_PERIOD)
    local fill_alpha = LOW_ALPHA_MIN + (LOW_ALPHA_MAX - LOW_ALPHA_MIN) * p
    local border_alpha = LOW_BORDER_ALPHA_MIN + (LOW_BORDER_ALPHA_MAX - LOW_BORDER_ALPHA_MIN) * p
    for member in pairs(Highlight.low_members) do
        local ok = pcall(member._paint_low_health, member, fill_alpha, border_alpha)
        if ok ~= true then
            Highlight.low_members[member] = nil
        end
    end
end

local function _tick()
    local flags = _G.LUI.Runtime ~= nil and _G.LUI.Runtime.Flags or nil
    if flags ~= nil and flags.is_unloading == true then
        Highlight.shutdown()
        return
    end
    local now = _now()
    if now < _next_tick then
        return
    end
    _next_tick = now + TICK
    _update_glow(now)
    _update_low(now)
    _update_wants_updates()
end

local function _ensure()
    if _ticker == nil then
        _ticker = Turbine.UI.Control()
        _ticker:SetVisible(false)
        _ticker.Update = function()
            _tick()
        end
    end
    if Highlight.glow_window == nil then
        Highlight.glow_window = _create_glow_window()
    end
end

---------------------------------------------------------------------
-- API para GroupMemberVitals
---------------------------------------------------------------------

function Highlight.claim_glow(member)
    local ok = pcall(_ensure)
    if ok ~= true then
        return
    end
    if Highlight.glow_owner ~= member and Highlight.glow_window ~= nil then
        Highlight.glow_window._sx = nil
    end
    Highlight.glow_owner = member
    _next_tick = 0
    pcall(_tick)
    _update_wants_updates()
end

function Highlight.release_glow(member)
    if Highlight.glow_owner ~= member then
        return
    end
    Highlight.glow_owner = nil
    _hide_glow()
    _update_wants_updates()
end

function Highlight.set_low(member, active)
    if active == true then
        if Highlight.low_members[member] == true then
            return
        end
        local ok = pcall(_ensure)
        if ok ~= true then
            return
        end
        Highlight.low_members[member] = true
        pcall(_update_low, _now())
    else
        if Highlight.low_members[member] == nil then
            return
        end
        Highlight.low_members[member] = nil
    end
    _update_wants_updates()
end

-- un paso inmediato del animador (lo usan las pruebas; en el juego manda Update)
function Highlight.step()
    _next_tick = 0
    _tick()
end

function Highlight.shutdown()
    Highlight.glow_owner = nil
    Highlight.low_members = {}
    if _ticker ~= nil then
        pcall(function()
            _ticker:SetWantsUpdates(false)
        end)
    end
    if Highlight.glow_window ~= nil then
        pcall(function()
            Highlight.glow_window:SetVisible(false)
        end)
        Highlight.glow_window = nil
    end
end
