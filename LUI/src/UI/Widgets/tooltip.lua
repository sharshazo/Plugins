-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets.base_window"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local LuiBaseWindow = Widgets.LuiBaseWindow
local LuiLabel = Widgets.LuiLabel
local Style = Widgets.Style
local BASE_PADDING_X = 6
local BASE_PADDING_Y = 4
local BASE_MAX_WIDTH = 311
local BASE_MIN_HEIGHT = 44
local BASE_MAX_HEIGHT = 178
local BASE_LINE_HEIGHT = 12
local BASE_OFFSET = 1
local BASE_SCREEN_MARGIN = 4
local BASE_Z_ORDER = 2000

local function _scaled_size(scale, value)
    return value * scale
end

local function _scaled_int(scale, value)
    return math.floor(_scaled_size(scale, value) + 0.5)
end

local function _line_count(text)
    local count = 1
    for _ in tostring(text or ""):gmatch("\n") do
        count = count + 1
    end
    return count
end

---@class LuiTooltip : LuiBaseWindow
local LuiTooltip = class(LuiBaseWindow)
Widgets.LuiTooltip = LuiTooltip

function LuiTooltip:Constructor()
    LuiBaseWindow.Constructor(self, { hideable = false })

    self._scale = 1
    self._anchor = nil
    self._text = nil

    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetZOrder(BASE_Z_ORDER)
    self:SetBackColor(Style.CONTROL_BORDER)

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self)
    self._inner:SetMouseVisible(false)
    self._inner:SetBackColor(Style.PANEL_BACKGROUND)

    self._label = LuiLabel()
    self._label:SetParent(self._inner)
    self._label:SetMouseVisible(false)
    self._label:SetSelectable(false)
    self._label:SetMultiline(true)
    self._label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self._label:SetForeColor(Style.FOREGROUND)
end

function LuiTooltip:_border()
    return math.max(0, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH_THIN) or 1))
end

function LuiTooltip:_padding_x()
    return math.max(0, _scaled_int(self._scale, BASE_PADDING_X))
end

function LuiTooltip:_padding_y()
    return math.max(0, _scaled_int(self._scale, BASE_PADDING_Y))
end

function LuiTooltip:_layout(width, height)
    local border = self:_border()
    local pad_x = self:_padding_x()
    local pad_y = self:_padding_y()
    local inner_w = math.max(0, width - (border * 2))
    local inner_h = math.max(0, height - (border * 2))

    self._inner:SetPosition(border, border)
    self._inner:SetSize(inner_w, inner_h)
    self._label:SetPosition(pad_x, pad_y)
    self._label:SetSize(math.max(0, inner_w - (pad_x * 2)), math.max(0, inner_h - (pad_y * 2)))
end

function LuiTooltip:_sync_style()
    self:SetBackColor(Style.CONTROL_BORDER)
    self._inner:SetBackColor(Style.PANEL_BACKGROUND)
    self._label:SetForeColor(Style.FOREGROUND)
end

function LuiTooltip:_position_for(control, width, height)
    local offset = _scaled_int(self._scale, BASE_OFFSET)
    local margin = _scaled_int(self._scale, BASE_SCREEN_MARGIN)
    local x, y = control:PointToScreen(0, control:GetHeight() + offset)
    local display_width, display_height = Turbine.UI.Display.GetSize()

    if x + width > display_width then
        x = display_width - width - margin
    end
    if y + height > display_height then
        y = y - height - control:GetHeight() - margin
    end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    self:SetPosition(x, y)
end

function LuiTooltip:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end

    self._scale = scale
    if self._anchor ~= nil and self._text ~= nil and self:IsVisible() == true then
        self:ShowFor(self._anchor, self._text)
    end
end

function LuiTooltip:SetFont(font)
    if font == nil then
        return
    end
    self._label:SetFont(font)
end

function LuiTooltip:GetContentHost()
    return self._inner
end

function LuiTooltip:ShowFor(control, text)
    if control == nil or type(text) ~= "string" or string.len(text) == 0 then
        self:Hide()
        return
    end

    self._anchor = control
    self._text = text

    local max_width = math.max(1, _scaled_int(self._scale, BASE_MAX_WIDTH))
    local min_height = math.max(1, _scaled_int(self._scale, BASE_MIN_HEIGHT))
    local max_height = math.max(min_height, _scaled_int(self._scale, BASE_MAX_HEIGHT))
    local line_height = math.max(1, _scaled_int(self._scale, BASE_LINE_HEIGHT))
    local pad_y = self:_padding_y()
    local border = self:_border()
    local height_extra = _scaled_int(self._scale, 7)
    local desired_height = math.min(
        max_height,
        math.max(min_height, (_line_count(text) * line_height) + (pad_y * 2) + (border * 2) + height_extra)
    )

    self:_sync_style()
    self._label:SetText(text)
    self._label:SetVisible(true)
    self:SetSize(max_width, desired_height)
    self:_layout(max_width, desired_height)
    self:_position_for(control, max_width, desired_height)
    self:SetVisible(true)
end

function LuiTooltip:ShowContentFor(control, width, height)
    if control == nil then
        self:Hide()
        return
    end

    width = tonumber(width)
    height = tonumber(height)
    if width == nil or height == nil or width <= 0 or height <= 0 then
        self:Hide()
        return
    end

    width = math.floor(width + 0.5)
    height = math.floor(height + 0.5)
    self._anchor = control
    self._text = nil
    self:_sync_style()
    self._label:SetVisible(false)
    self:SetSize(width, height)
    self:_layout(width, height)
    self:_position_for(control, width, height)
    self:SetVisible(true)
end

function LuiTooltip:Hide()
    self._anchor = nil
    self._text = nil
    self._label:SetVisible(false)
    self:SetVisible(false)
end

function LuiTooltip:Bind(control, text_source)
    if control == nil or text_source == nil then
        return
    end

    local function resolve_text()
        local text = text_source
        if type(text_source) == "function" then
            text = text_source()
        end
        if type(text) ~= "string" or string.len(text) == 0 then
            return nil
        end
        return text
    end

    local prev_enter = control.MouseEnter
    control.MouseEnter = function(sender, args)
        if prev_enter ~= nil then
            prev_enter(sender, args)
        end

        local text = resolve_text()
        if text ~= nil then
            self:ShowFor(control, text)
        end
    end

    local prev_leave = control.MouseLeave
    control.MouseLeave = function(sender, args)
        if prev_leave ~= nil then
            prev_leave(sender, args)
        end
        self:Hide()
    end
end

UI.Widgets.LuiTooltip = LuiTooltip
