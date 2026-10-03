-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Assets = _G.LUI.Features.Assets
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.font"
import "LUI.src.Utils.number_abbrev"

-- (2026-09-30, actualizacion 49.6) el juego pide AttachEdges en los
-- controles con modo de estirado; None = tamano fijo. Sin 49.6, no hace nada.
local function _attach_fixed_edges(control)
    local EA = Turbine.UI.EdgeAttachmentType
    if EA ~= nil and control ~= nil and control.AttachEdges ~= nil then
        pcall(control.AttachEdges, control, EA.None, EA.None, EA.None, EA.None)
    end
end

-- (2026-09-30, 49.6) con estirado activo el juego ignora SetSize salvo que
-- el tamano maximo/minimo del control lo acompanen (probado en el juego,
-- ver UI/Widgets/image.lua). Sin la 49.6 es un SetSize normal.
local function _fit_stretched(control, w, h)
    if control ~= nil and control.SetMaximumSize ~= nil then
        pcall(control.SetMinimumSize, control, 1, 1)
        pcall(control.SetMaximumSize, control, math.max(1, math.floor(w + 0.5)), math.max(1, math.floor(h + 0.5)))
    end
    control:SetSize(w, h)
end

local AssetsEntry = class(Turbine.UI.Control)
Assets.AssetsEntry = AssetsEntry

local Style = UI.Widgets.Style
local BORDER = 2
local BASE_ICON_SIZE = 32
local BASE_QTY_PADDING = 1
local ITEM_INFO_CONTROL_EXTRA = 3
local ITEM_CONTROL_OFFSET = -3
local ITEM_CONTROL_EXTRA = 4
local MULTIPLE_META_TEXT = TR["Various"]

local QUALITY_NAME_COLORS = {
    [Turbine.Gameplay.ItemQuality.Common] = Turbine.UI.Color(1, 0.92, 0.92, 0.92),
    [Turbine.Gameplay.ItemQuality.Incomparable] = Turbine.UI.Color(1, 0.76, 0.47, 1.00),
    [Turbine.Gameplay.ItemQuality.Legendary] = Turbine.UI.Color(1, 1.00, 0.78, 0.18),
    [Turbine.Gameplay.ItemQuality.Rare] = Turbine.UI.Color(1, 0.36, 0.88, 0.96),
    [Turbine.Gameplay.ItemQuality.Uncommon] = Turbine.UI.Color(1, 0.43, 0.88, 0.43),
    [Turbine.Gameplay.ItemQuality.Undefined] = Turbine.UI.Color(1, 0.92, 0.92, 0.92),
}

local QUALITY_BORDER_COLORS = {
    [Turbine.Gameplay.ItemQuality.Common] = Turbine.UI.Color(1, 0.24, 0.24, 0.24),
    [Turbine.Gameplay.ItemQuality.Incomparable] = Turbine.UI.Color(1, 0.38, 0.20, 0.55),
    [Turbine.Gameplay.ItemQuality.Legendary] = Turbine.UI.Color(1, 0.52, 0.36, 0.08),
    [Turbine.Gameplay.ItemQuality.Rare] = Turbine.UI.Color(1, 0.12, 0.42, 0.48),
    [Turbine.Gameplay.ItemQuality.Uncommon] = Turbine.UI.Color(1, 0.16, 0.38, 0.16),
    [Turbine.Gameplay.ItemQuality.Undefined] = Turbine.UI.Color(1, 0.24, 0.24, 0.24),
}

local SOURCE_META_COLORS = {
    backpack = Turbine.UI.Color(1, 0.43, 0.88, 0.43),
    bank = Turbine.UI.Color(1, 0.94, 0.78, 0.28),
    vault = Turbine.UI.Color(1, 0.42, 0.78, 0.96),
    shared_storage = Turbine.UI.Color(1, 0.98, 0.62, 0.32),
}

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * State.settings.global.scale)
end

local function _quality_name_color(quality)
    return QUALITY_NAME_COLORS[quality] or QUALITY_NAME_COLORS[Turbine.Gameplay.ItemQuality.Common]
end

local function _quality_border_color(quality)
    return QUALITY_BORDER_COLORS[quality] or QUALITY_BORDER_COLORS[Turbine.Gameplay.ItemQuality.Common]
end

local function _sanitize_image_id(value)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil or value == 0 then
        return nil
    end
    return value
end

local function _quantity_font(quantity)
    local text = tostring(quantity or "")
    if string.len(text) > 4 then
        return _scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE - 2)
    end
    return _scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE - 1)
end

local function _source_meta_color(source_key)
    return SOURCE_META_COLORS[source_key] or Style.ALTERNATE_FOREGROUND
end

local function _color_luminance(red, green, blue)
    return (red * 0.2126) + (green * 0.7152) + (blue * 0.0722)
end

local function _color_spread(red, green, blue)
    return math.max(red, green, blue) - math.min(red, green, blue)
end

local function _clamp_unit(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function _owner_hint_color(owner)
    if type(owner) ~= "string" or string.len(owner) == 0 then
        return Style.ALTERNATE_FOREGROUND
    end

    local hash = 0
    for i = 1, string.len(owner) do
        hash = ((hash * 131) + string.byte(owner, i)) % 360
    end

    local hue = hash / 60
    local chroma = 0.42
    local x = chroma * (1 - math.abs((hue % 2) - 1))
    local m = 0.50
    local red = 0
    local green = 0
    local blue = 0

    if hue < 1 then
        red, green, blue = chroma, x, 0
    elseif hue < 2 then
        red, green, blue = x, chroma, 0
    elseif hue < 3 then
        red, green, blue = 0, chroma, x
    elseif hue < 4 then
        red, green, blue = 0, x, chroma
    elseif hue < 5 then
        red, green, blue = x, 0, chroma
    else
        red, green, blue = chroma, 0, x
    end

    red = red + m
    green = green + m
    blue = blue + m

    local luminance = _color_luminance(red, green, blue)
    if luminance < 0.72 then
        local boost = (0.72 - luminance) / 0.72
        red = red + ((1 - red) * boost)
        green = green + ((1 - green) * boost)
        blue = blue + ((1 - blue) * boost)
    end

    local spread = _color_spread(red, green, blue)
    if spread < 0.22 then
        local avg = (red + green + blue) / 3
        local boost = 1 + ((0.22 - spread) / 0.22)
        red = _clamp_unit(avg + ((red - avg) * boost))
        green = _clamp_unit(avg + ((green - avg) * boost))
        blue = _clamp_unit(avg + ((blue - avg) * boost))
    end

    return Turbine.UI.Color(1, red, green, blue)
end

local function _point_in_rect(x, y, left, top, width, height)
    if x == nil or y == nil then
        return false
    end
    return x >= left and y >= top and x < (left + width) and y < (top + height)
end

local function _get_meta_widths(total_w, gap, has_owner, has_source)
    if total_w < 0 then
        return 0, 0
    end
    if has_source ~= true then
        return total_w, 0
    end
    if has_owner ~= true then
        return 0, total_w
    end

    local source_w = math.max(_scaled_int(86), math.floor(total_w * 0.34))
    local owner_w = total_w - source_w - gap
    local min_owner_w = _scaled_int(54)

    if owner_w < min_owner_w then
        owner_w = min_owner_w
        source_w = total_w - owner_w - gap
        if source_w < 0 then
            source_w = 0
            owner_w = total_w
        end
    end

    return owner_w, source_w
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function AssetsEntry:Constructor(on_hover)
    Turbine.UI.Control.Constructor(self)

    self.on_hover = on_hover
    self.mode = nil
    self.tile_size = 40
    self.record = nil
    self._icon_width = nil
    self._icon_height = nil
    self._background_image_id = nil
    self._icon_image_id = nil
    self._has_owner = false
    self._has_source = false

    self:SetMouseVisible(true)
    self:SetBackColor(_quality_border_color(nil))

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(true)
    self.inner:SetBackColor(Style.BACKGROUND)

    self.icon_slot = Turbine.UI.Control()
    self.icon_slot:SetParent(self.inner)
    self.icon_slot:SetMouseVisible(true)
    self.icon_slot:SetZOrder(1)

    self.icon_back = UI.Widgets.Image()
    self.icon_back:SetParent(self.icon_slot)
    self.icon_back:SetMouseVisible(false)
    self.icon_back:SetZOrder(1)

    self.icon_item_info_control = Turbine.UI.Lotro.ItemInfoControl()
    self.icon_item_info_control:SetParent(self.icon_back)
    self.icon_item_info_control:SetMouseVisible(false)
    self.icon_item_info_control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_item_info_control:SetVisible(false)
    self.icon_item_info_control:SetZOrder(0)

    self.icon_fore = UI.Widgets.Image()
    self.icon_fore:SetParent(self.icon_back)
    self.icon_fore:SetMouseVisible(false)
    self.icon_fore:SetZOrder(1)

    self.icon_item_control = Turbine.UI.Lotro.ItemControl()
    self.icon_item_control:SetParent(self.icon_back)
    self.icon_item_control:SetPosition(0, 0)
    _fit_stretched(self.icon_item_control, self.tile_size, self.tile_size)
    self.icon_item_control:SetMouseVisible(false)
    self.icon_item_control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_item_control:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.icon_item_control:SetVisible(false)
    self.icon_item_control:SetZOrder(2)
    if self.icon_item_control.SetStretchMode ~= nil then
        self.icon_item_control:SetStretchMode(1)
        _attach_fixed_edges(self.icon_item_control)
    end

    self.qty_label = UI.Widgets.LuiLabel()
    self.qty_label:SetParent(self.icon_fore)
    self.qty_label:SetMouseVisible(false)
    self.qty_label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
    self.qty_label:SetForeColor(Style.FOREGROUND)
    self.qty_label:SetOutlineColor(Style.TEXT_OUTLINE)
    self.qty_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.qty_label:SetZOrder(3)

    self.name_label = UI.Widgets.LuiLabel()
    self.name_label:SetParent(self.inner)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetSelectable(false)
    self.name_label:SetMultiline(true)
    self.name_label:SetForeColor(_quality_name_color(nil))

    self.owner_label = UI.Widgets.LuiLabel()
    self.owner_label:SetParent(self.inner)
    self.owner_label:SetMouseVisible(false)
    self.owner_label:SetSelectable(false)
    self.owner_label:SetMultiline(false)
    self.owner_label:SetForeColor(Style.ALTERNATE_FOREGROUND)

    self.source_label = UI.Widgets.LuiLabel()
    self.source_label:SetParent(self.inner)
    self.source_label:SetMouseVisible(false)
    self.source_label:SetSelectable(false)
    self.source_label:SetMultiline(false)
    self.source_label:SetForeColor(Style.ALTERNATE_FOREGROUND)

    local function _hover_in(icon_hover)
        if type(self.on_hover) == "function" then
            self.on_hover(self.record, self, icon_hover == true)
        end
    end

    local function _hover_out()
        if type(self.on_hover) == "function" then
            self.on_hover(nil, self, false)
        end
    end

    local function _hover_in_self(_, args)
        local icon_left, icon_top = self.icon_slot:GetPosition()
        local icon_width, icon_height = self.icon_slot:GetSize()
        _hover_in(_point_in_rect(
            args ~= nil and args.X or nil,
            args ~= nil and args.Y or nil,
            BORDER + icon_left,
            BORDER + icon_top,
            icon_width,
            icon_height
        ))
    end

    local function _hover_in_inner(_, args)
        local icon_left, icon_top = self.icon_slot:GetPosition()
        local icon_width, icon_height = self.icon_slot:GetSize()
        _hover_in(_point_in_rect(args ~= nil and args.X or nil, args ~= nil and args.Y or nil, icon_left, icon_top, icon_width, icon_height))
    end

    local function _hover_in_icon()
        _hover_in(true)
    end

    self.MouseEnter = _hover_in_self
    self.MouseLeave = _hover_out
    self.MouseMove = _hover_in_self
    self.inner.MouseEnter = _hover_in_inner
    self.inner.MouseMove = _hover_in_inner
    self.icon_slot.MouseEnter = _hover_in_icon
    self.icon_slot.MouseMove = _hover_in_icon

    self.SizeChanged = function()
        self:_layout()
    end

    self:_apply_fonts()
    self:_layout()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function AssetsEntry:apply_view(mode, tile_size)
    self.mode = mode
    self.tile_size = tile_size
    self:_apply_fonts()
    self:_layout()
end

function AssetsEntry:bind(record)
    self.record = record
    if record == nil then
        self:SetVisible(false)
        return
    end

    self:SetVisible(true)
    self:SetBackColor(_quality_border_color(record.quality))

    local owner_text = record.owner or ""
    local owner_color = _owner_hint_color(owner_text)
    if record.has_multiple_owners == true then
        owner_text = MULTIPLE_META_TEXT
        owner_color = Style.ALTERNATE_FOREGROUND
    end

    local source_text = record.source_name or ""
    local source_color = _source_meta_color(record.source_key)
    if record.has_multiple_sources == true then
        source_text = MULTIPLE_META_TEXT
        source_color = Style.ALTERNATE_FOREGROUND
    end

    self.name_label:SetText(record.name or "")
    self.name_label:SetForeColor(_quality_name_color(record.quality))
    self.owner_label:SetText(owner_text)
    self.source_label:SetText(source_text)
    self.owner_label:SetForeColor(owner_color)
    self.source_label:SetForeColor(source_color)
    self._has_owner = type(owner_text) == "string" and string.len(owner_text) > 0
    self._has_source = type(source_text) == "string" and string.len(source_text) > 0

    local quantity = record.quantity or 1
    local background_image_id = record.background_image_id
    local icon_id = record.icon_id
    if record.item_info ~= nil then
        if background_image_id == nil and record.item_info.GetBackgroundImageID ~= nil then
            background_image_id = _sanitize_image_id(record.item_info:GetBackgroundImageID())
        end
        if background_image_id == nil and record.item_info.GetQualityImageID ~= nil then
            background_image_id = _sanitize_image_id(record.item_info:GetQualityImageID())
        end
        if icon_id == nil and record.item_info.GetIconImageID ~= nil then
            icon_id = _sanitize_image_id(record.item_info:GetIconImageID())
        end
    end

    self._background_image_id = background_image_id
    self._icon_image_id = icon_id
    self.icon_back:set_icon(background_image_id)
    self.icon_fore:set_icon(icon_id)
    self.icon_back:SetVisible(background_image_id ~= nil or icon_id ~= nil or record.item_info ~= nil)

    self.icon_item_control:SetVisible(false)
    self.icon_item_control:SetItem(nil)
    if self.icon_item_control.SetOpacity ~= nil then
        self.icon_item_control:SetOpacity(1)
    end

    if icon_id ~= nil then
        self.icon_fore:SetVisible(true)
    else
        self.icon_fore:SetVisible(false)
    end

    if record.item_info ~= nil then
        self.icon_item_info_control:SetVisible(true)
        self.icon_item_info_control:SetMouseVisible(true)
        self.icon_item_info_control:SetItemInfo(record.item_info)
    else
        self.icon_item_info_control:SetVisible(false)
        self.icon_item_info_control:SetMouseVisible(false)
    end

    if quantity > 1 then
        local quantity_text = lui_abbrev_number(quantity)
        self.qty_label:SetFont(_quantity_font(quantity_text))
        self.qty_label:SetText(quantity_text)
    else
        self.qty_label:SetText("")
    end

    self:_layout()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function AssetsEntry:_apply_fonts()
    self.name_label:SetFont(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE))
    self.owner_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.source_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.qty_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE - 1))
end

function AssetsEntry:_layout_icon_controls(icon_w, icon_h)
    if icon_w < 0 then
        icon_w = 0
    end
    if icon_h < 0 then
        icon_h = 0
    end

    self._icon_width = icon_w
    self._icon_height = icon_h

    local visual_side = math.min(icon_w, icon_h)
    if visual_side < 0 then
        visual_side = 0
    end

    local visual_x = math.floor((icon_w - visual_side) / 2)
    local visual_y = math.floor((icon_h - visual_side) / 2)

    self.icon_back:SetPosition(visual_x, visual_y)
    self.icon_back:set_size(visual_side, visual_side)

    self.icon_fore:SetPosition(0, 0)
    self.icon_fore:set_size(BASE_ICON_SIZE, BASE_ICON_SIZE)
    self.icon_item_info_control:SetPosition(ITEM_CONTROL_OFFSET, ITEM_CONTROL_OFFSET)
    self.icon_item_info_control:SetSize(BASE_ICON_SIZE + ITEM_INFO_CONTROL_EXTRA, BASE_ICON_SIZE + ITEM_INFO_CONTROL_EXTRA)
    self.icon_item_control:SetPosition(ITEM_CONTROL_OFFSET, ITEM_CONTROL_OFFSET)
    _fit_stretched(self.icon_item_control, BASE_ICON_SIZE + ITEM_CONTROL_EXTRA, BASE_ICON_SIZE + ITEM_CONTROL_EXTRA)
    local qty_padding = _scaled_int(BASE_QTY_PADDING)
    local qty_side = math.max(0, BASE_ICON_SIZE - (2 * qty_padding))
    self.qty_label:SetPosition(qty_padding, qty_padding)
    self.qty_label:SetSize(qty_side, qty_side)
end

function AssetsEntry:_layout()
    local width, height = self:GetSize()
    if width < 0 then width = 0 end
    if height < 0 then height = 0 end

    self.inner:SetPosition(BORDER, BORDER)
    self.inner:SetSize(math.max(0, width - (2 * BORDER)), math.max(0, height - (2 * BORDER)))

    local inner_w, inner_h = self.inner:GetSize()
    local pad = _scaled_int(4)
    local gap = _scaled_int(6)

    if self.mode == LUI_ENUMS.assets_view_mode.ICONS then
        self.name_label:SetVisible(false)
        self.owner_label:SetVisible(false)
        self.source_label:SetVisible(false)

        self.icon_slot:SetPosition(pad, pad)
        self.icon_slot:SetSize(math.max(0, inner_w - (2 * pad)), math.max(0, inner_h - (2 * pad)))

        local icon_w, icon_h = self.icon_slot:GetSize()
        self:_layout_icon_controls(icon_w, icon_h)
        return
    end

    local icon_side = self.tile_size
    if icon_side > inner_h - (2 * pad) then
        icon_side = inner_h - (2 * pad)
    end
    if icon_side < _scaled_int(20) then
        icon_side = _scaled_int(20)
    end

    local icon_top = math.floor((inner_h - icon_side) / 2)
    self.icon_slot:SetPosition(pad, icon_top)
    self.icon_slot:SetSize(icon_side, icon_side)
    self:_layout_icon_controls(icon_side, icon_side)

    local text_left = pad + icon_side + gap
    local text_width = inner_w - text_left - pad
    if text_width < 0 then
        text_width = 0
    end

    self.name_label:SetVisible(true)
    self.owner_label:SetVisible(self._has_owner)
    self.source_label:SetVisible(self._has_source)
    self.name_label:SetMultiline(true)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.owner_label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    self.source_label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)

    local meta_h = math.min(_scaled_int(12), math.max(0, inner_h - (2 * pad)))
    local details_gap = _scaled_int(2)
    local name_h = inner_h - (2 * pad) - meta_h
    if name_h > 0 and meta_h > 0 then
        name_h = name_h - details_gap
    else
        details_gap = 0
    end
    if name_h < 0 then
        name_h = 0
    end

    self.name_label:SetPosition(text_left, pad)
    self.name_label:SetSize(text_width, name_h)
    local owner_w, source_w = _get_meta_widths(text_width, gap, self._has_owner, self._has_source)
    self.owner_label:SetPosition(text_left, pad + name_h + details_gap)
    self.owner_label:SetSize(owner_w, meta_h)
    self.source_label:SetPosition(text_left + text_width - source_w, pad + name_h + details_gap)
    self.source_label:SetSize(source_w, meta_h)
end
