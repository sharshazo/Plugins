-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local Style = Widgets.Style

-- (2026-09-30, actualizacion 49.6 del juego) Antes el tamano REAL de cada
-- imagen se averiguaba siempre con el truco SetStretchMode(2) + GetSize().
-- La 49.6 cambio el motor de la interfaz de los plugins (escalado de UI,
-- "Edge Attachments"), y con eso los iconos empezaron a dibujarse en su
-- tamano original, desbordando botones y ventanas (el yunque gigante en la
-- Enciclopedia, la X de cerrar, las flechas del paginador, el menu LUI).
-- Ahora el tamano sale, en este orden, de:
--   1) la tabla LUI.UI.ImageSizes (imagenes propias de LUI y las del juego
--      cuyo tamano se conoce, ver UI/assets.lua y Utils/icons.lua),
--   2) la medicion de siempre, guardada en memoria (una sola vez por imagen),
--   3) si la medicion falla: 32x32 para imagenes del juego (el tamano de
--      los iconos de objetos/efectos/habilidades) y, para un archivo .tga
--      que no este en la tabla, la caja pedida
--      SIN estirar (la imagen queda recortada dentro de su lugar, nunca
--      desborda).
-- Ademas, si el juego ofrece AttachEdges (49.6+), cada imagen estirada se
-- fija con EdgeAttachmentType.None (tamano fijo, no depende del padre).
--
-- LO QUE DE VERDAD ACHICA LA IMAGEN EN LA 49.6 (probado en el juego con
-- "/lui imgtest", 2026-09-30): con el modo de estirado 1 activo, el juego
-- IGNORA SetSize (la imagen queda dibujada a su tamano real, 64x64 aunque
-- se pida 24x24). Las unicas secuencias que la dibujaron del tamano pedido
-- fueron las que fijan el tamano MAXIMO (y minimo) del control al tamano
-- pedido antes del SetSize (variantes L y P). Regla que cumplen TODAS las
-- pruebas hechas en el juego: con estirado 1, el tamano del control queda
-- en el de la imagen (SetSize se ignora) y la imagen se dibuja ESCALADA al
-- tamano maximo solo si el control es mas grande que ese maximo; si el
-- control es igual o mas chico, se dibuja a tamano real y recortada.
-- Por eso: primero el control al tamano REAL de la imagen (sin estirado),
-- despues estirado 1, minimo 1x1 y maximo = tamano pedido. Image redefine
-- SetStretchMode/SetSize/SetWidth/SetHeight para hacerlo siempre; al salir
-- del estirado el maximo vuelve a un valor grande (nunca 0). En juegos sin
-- SetMaximumSize (antes de la 49.6) no hace nada extra.
local ImageSizes = _G.LUI.UI.ImageSizes or {}
_G.LUI.UI.ImageSizes = ImageSizes
local _measured = {}
local _diag = { measured_ok = 0, measured_fail = 0, table_hits = 0, fallback = 0, last_fail = nil }
Widgets.ImageDiag = _diag

local function _valid_size(w, h)
    return type(w) == "number" and type(h) == "number" and w > 0 and h > 0 and w <= 4096 and h <= 4096
end

local function _attach_fixed_edges(control)
    local EA = Turbine.UI.EdgeAttachmentType
    if EA == nil or control.AttachEdges == nil then
        return
    end
    pcall(control.AttachEdges, control, EA.None, EA.None, EA.None, EA.None)
end
Widgets.attach_fixed_edges = _attach_fixed_edges

-- Limites de tamano para un control estirado (ver nota de arriba).
local function _set_size_limits(control, w, h)
    if control.SetMaximumSize == nil then
        return
    end
    if w == nil then
        -- Sin limite: un maximo GRANDE. NUNCA 0: fijado a mano, un maximo
        -- 0x0 deja el control en 0x0 y la imagen INVISIBLE (error del
        -- 2026-09-30, iconos vacios). El minimo no se toca.
        pcall(control.SetMaximumSize, control, 4096, 4096)
        return
    end
    w = math.max(1, math.floor((tonumber(w) or 1) + 0.5))
    h = math.max(1, math.floor((tonumber(h) or 1) + 0.5))
    pcall(control.SetMinimumSize, control, 1, 1)
    pcall(control.SetMaximumSize, control, w, h)
end
Widgets.set_size_limits = _set_size_limits

-- Encoge (o agranda) un control estirado de verdad en la 49.6.
function Widgets.fit_stretched(control, w, h)
    _set_size_limits(control, w, h)
    control:SetSize(w, h)
end

---@class Image : Turbine.UI.Control
local Image = class(Turbine.UI.Control)
Widgets.Image = Image

local function _round_size(value)
    if value == nil then
        return nil
    end
    return math.floor(value + 0.5)
end

local function _has_flag(value, flag)
    if value == nil then
        return false
    end
    return math.floor(value / flag) % 2 == 1
end

function Image:SetStretchMode(mode)
    self._lui_stretch = mode
    if mode ~= 1 then
        _set_size_limits(self, nil)
    end
    Turbine.UI.Control.SetStretchMode(self, mode)
end

function Image:SetSize(w, h)
    if self._lui_stretch == 1 then
        _set_size_limits(self, w, h)
    end
    Turbine.UI.Control.SetSize(self, w, h)
end

function Image:SetWidth(w)
    if self._lui_stretch == 1 then
        _set_size_limits(self, w, self._real_h or w)
    end
    Turbine.UI.Control.SetWidth(self, w)
end

function Image:SetHeight(h)
    if self._lui_stretch == 1 then
        _set_size_limits(self, self._real_w or h, h)
    end
    Turbine.UI.Control.SetHeight(self, h)
end

function Image:Constructor(icon, w, h)
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self._scale = 1
    self._requested_w = nil
    self._requested_h = nil
    self._requested_side = nil
    self._align = nil

    self._real_w = nil
    self._real_h = nil

    if icon ~= nil then
        self:set_icon(icon, w, h)
    elseif w ~= nil then
        self:set_size(w, h)
    end
end

function Image:_store_size_request(w, h)
    w = _round_size(w)
    h = _round_size(h)

    if w ~= nil and h == nil then
        self._requested_side = w
        self._requested_w = nil
        self._requested_h = nil
    elseif w ~= nil or h ~= nil then
        self._requested_w = w
        self._requested_h = h
        self._requested_side = nil
    end

    return w, h
end

function Image:set_size(w, h)
    if w == nil then
        return nil
    end
    w, h = self:_store_size_request(w, h)

    if self.original_w == nil or self.original_h == nil then
        return nil
    end

    if w ~= nil and h ~= nil then
        self._real_w = w
        self._real_h = h
        self:SetSize(w, h)
        self:set_alignment(self._align)
        return w, h
    end

    -- If only w is set we assume that we want to size it so it keeps
    -- the aspect ration but the image can fit in a square w x w
    if w < 0 then
        w = 0
    end

    local new_w = 0
    local new_h = 0
    if self.original_w > self.original_h then
        new_w = w
        new_h = w * self.original_h / self.original_w
    else
        new_h = w
        new_w = w * self.original_w / self.original_h
    end

    self:SetSize(new_w, new_h)
    self:set_alignment(self._align)

    self._real_w = new_w
    self._real_h = new_h

    return new_w, new_h
end

function Image:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
end

function Image:set_width(w)
    w = _round_size(w)
    if w == nil then
        return nil
    end

    self._requested_side = nil
    self._requested_w = w
    self._requested_h = nil

    if self.original_w == nil or self.original_h == nil then
        return nil
    end

    if w < 0 then
        w = 0
    end

    local new_h = w * self.original_h / self.original_w

    self._real_w = w
    self._real_h = new_h

    self:SetSize(w, new_h)
    self:set_alignment(self._align)

    return w, new_h
end

function Image:set_height(h)
    h = _round_size(h)
    if h == nil then
        return
    end

    self._requested_side = nil
    self._requested_w = nil
    self._requested_h = h

    if self.original_h == nil or self.original_w == nil then
        return
    end

    if h < 0 then
        h = 0
    end

    local new_w = h * self.original_w / self.original_h

    self._real_w = new_w
    self._real_h = h

    self:SetSize(new_w, h)
    self:set_alignment(self._align)

    return new_w, h
end

function Image:get_width()
    return self._real_w
end

function Image:get_height()
    return self._real_h
end

function Image:get_size()
    return self._real_w, self._real_h
end

function Image:_set_size(w, h)
    if w ~= nil or h ~= nil then
        self:_store_size_request(w, h)
    end

    if self.original_w == nil or self.original_h == nil then
        return nil
    end

    if self._requested_side ~= nil then
        return self:set_size(self._requested_side)
    elseif self._requested_w ~= nil and self._requested_h ~= nil then
        return self:set_size(self._requested_w, self._requested_h)
    elseif self._requested_w ~= nil then
        return self:set_width(self._requested_w)
    elseif self._requested_h ~= nil then
        return self:set_height(self._requested_h)
    end
end

function Image:set_icon(icon, w, h)
    if icon == nil then
        self.original_w = nil
        self.original_h = nil
        self._real_w = nil
        self._real_h = nil
        self:SetBackground(nil)
        if w ~= nil or h ~= nil then
            self:_store_size_request(w, h)
        end
        return
    end

    self:SetVisible(true)
    local nw, nh = self:_native_size(icon)

    if nw == nil then
        -- Tamano desconocido: sin estirar, del tamano pedido (recorta).
        _diag.fallback = _diag.fallback + 1
        _diag.last_fallback = tostring(icon)
        local rw = _round_size(w) or self._requested_side or self._requested_w or 32
        local rh = _round_size(h) or self._requested_h or rw
        self:SetStretchMode(0)
        self:SetBackground(icon)
        self.original_w, self.original_h = rw, rh
        self._real_w, self._real_h = rw, rh
        self:SetSize(rw, rh)
        if self:_set_size(w, h) == nil then
            self:set_alignment(self._align)
        end
        return
    end

    -- Base del estirado = tamano real, fijado JUSTO antes del modo 1; el
    -- tamano final se pone despues (asi escala en el motor viejo y el nuevo).
    self:SetStretchMode(0)
    self:SetBackground(icon)
    self:SetSize(nw, nh)
    self:SetStretchMode(1)
    _attach_fixed_edges(self)
    self.original_w, self.original_h = nw, nh
    self._real_w = nw
    self._real_h = nh

    if self:_set_size(w, h) == nil then
        self:set_alignment(self._align)
    end
end

-- Tamano real de la imagen (ver nota al principio del archivo).
function Image:_native_size(icon)
    local known = ImageSizes[icon] or _measured[icon]
    if known ~= nil then
        if ImageSizes[icon] ~= nil then
            _diag.table_hits = _diag.table_hits + 1
        end
        return known[1], known[2]
    end

    local ok, mw, mh = pcall(function()
        self:SetStretchMode(0)
        self:SetSize(0, 0)
        self:SetBackground(icon)
        self:SetStretchMode(2)
        local a, b = self:GetSize()
        self:SetStretchMode(0)
        return a, b
    end)
    if ok == true and _valid_size(mw, mh) then
        _diag.measured_ok = _diag.measured_ok + 1
        _measured[icon] = { mw, mh }
        return mw, mh
    end

    _diag.measured_fail = _diag.measured_fail + 1
    _diag.last_fail = tostring(icon) .. " -> " .. tostring(mw) .. "x" .. tostring(mh)
    if type(icon) ~= "string" then
        -- iconos del juego (id numerico o Turbine.UI.Graphic: objetos,
        -- efectos, habilidades, monedas...): 32x32
        _measured[icon] = { 32, 32 }
        return 32, 32
    end
    return nil
end

Image.CENTER = 0x01
Image.MIDDLE = 0x02

function Image:set_alignment(align)
    self._align = align
    local parent = self:GetParent()
    if align == nil or parent == nil or self._real_w == nil or self._real_h == nil then
        -- Keep current position
        return
    end

    if _has_flag(align, Image.CENTER) then
        local pw = parent:GetWidth()
        local w = self._real_w
        self:SetLeft(math.floor((pw - w) / 2))
    end

    if _has_flag(align, Image.MIDDLE) then
        local ph = parent:GetHeight()
        local h = self._real_h
        self:SetTop(math.floor((ph - h) / 2))
    end
end
