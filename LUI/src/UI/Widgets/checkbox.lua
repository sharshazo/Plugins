-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local LuiLabel = Widgets.LuiLabel
local Style = Widgets.Style
local BASE_CHECKBOX_W = 120
local BASE_CHECKBOX_H = 16
local BASE_ICON_SIZE = 16
local BASE_TEXT_GAP = 6
local BASE_FILL_MARGIN = 2

local function _round(value)
    return math.floor(value + 0.5)
end

---@class LuiCheckBox : Turbine.UI.Control
local LuiCheckBox = class(Turbine.UI.Control)
Widgets.LuiCheckBox = LuiCheckBox

function LuiCheckBox:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.CheckedChanged = nil

    self._checked = false
    self._enabled = true
    self._hover = false
    self._pressed = false
    self._text = ""
    self._scale = 1
    self._icon_scale = 1

    self._text_color = Style.CONTROL_FOREGROUND
    self._text_disabled_color = Style.CONTROL_FOREGROUND_DISABLED
    self._border_color = Style.CONTROL_BORDER
    self._border_hover_color = Style.CONTROL_BORDER_HOVER
    self._border_disabled_color = Style.CONTROL_BORDER_DISABLED
    self._fill_color = Style.ACCENT_BACKGROUND
    self._fill_disabled_color = Style.ACCENT_BACKGROUND_DISABLED

    self:SetMouseVisible(true)

    self._icon = Turbine.UI.Control()
    self._icon:SetParent(self)
    self._icon:SetMouseVisible(false)

    self._border_top = Turbine.UI.Control()
    self._border_top:SetParent(self._icon)
    self._border_top:SetMouseVisible(false)

    self._border_bottom = Turbine.UI.Control()
    self._border_bottom:SetParent(self._icon)
    self._border_bottom:SetMouseVisible(false)

    self._border_left = Turbine.UI.Control()
    self._border_left:SetParent(self._icon)
    self._border_left:SetMouseVisible(false)

    self._border_right = Turbine.UI.Control()
    self._border_right:SetParent(self._icon)
    self._border_right:SetMouseVisible(false)

    self._fill = Turbine.UI.Control()
    self._fill:SetParent(self._icon)
    self._fill:SetMouseVisible(false)

    self._label = LuiLabel()
    self._label:SetParent(self)
    self._label:SetMouseVisible(false)
    self._label:SetSelectable(false)
    self._label:SetMultiline(false)
    self._label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        if self._enabled ~= true then
            return
        end
        self._hover = true
        self:_update_visual_state()
    end

    self.MouseLeave = function()
        self._hover = false
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseDown = function(_, args)
        if self._enabled ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._pressed = true
        self:_update_visual_state()
    end

    self.MouseUp = function(_, args)
        if self._enabled ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseClick = function(_, args)
        if self._enabled ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self:SetChecked(self._checked ~= true)
    end

    Turbine.UI.Control.SetSize(self, BASE_CHECKBOX_W, BASE_CHECKBOX_H)
    self:_layout()
    self:_update_visual_state()
end

function LuiCheckBox:SetText(text)
    self._text = tostring(text or "")
    self._label:SetText(self._text)
    self:_layout()
end

function LuiCheckBox:GetText()
    return self._text
end

function LuiCheckBox:SetFont(font)
    self._label:SetFont(font)
    self:_layout()
end

function LuiCheckBox:SetForeColor(color)
    if color == nil then
        return
    end
    self._text_color = color
    self:_update_visual_state()
end

function LuiCheckBox:SetTextAlignment(alignment)
    self._label:SetTextAlignment(alignment)
end

function LuiCheckBox:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        return
    end
    self._scale = scale
    self:_layout()
end

function LuiCheckBox:GetScale()
    return self._scale
end

function LuiCheckBox:SetIconScale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        return
    end
    self._icon_scale = scale
    self:_layout()
end

function LuiCheckBox:GetIconScale()
    return self._icon_scale
end

function LuiCheckBox:SetChecked(value)
    local checked = value == true
    if self._checked == checked then
        return
    end

    self._checked = checked
    self:_update_visual_state()

    if type(self.CheckedChanged) == "function" then
        self:CheckedChanged()
    end
end

function LuiCheckBox:IsChecked()
    return self._checked == true
end

function LuiCheckBox:Toggle()
    self:SetChecked(self._checked ~= true)
end

function LuiCheckBox:SetEnabled(enabled)
    self._enabled = enabled == true
    self._pressed = false
    self:_update_visual_state()
end

function LuiCheckBox:IsEnabled()
    return self._enabled == true
end

function LuiCheckBox:_icon_size()
    local _, h = self:GetSize()
    local visual_scale = self._scale * self._icon_scale
    local icon_size = _round(BASE_ICON_SIZE * visual_scale)
    icon_size = math.max(0, math.min(h, icon_size))
    return icon_size
end

function LuiCheckBox:_layout()
    local w, h = self:GetSize()
    local icon_size = self:_icon_size()
    local icon_y = math.max(0, _round((h - icon_size) / 2))
    local label_x = icon_size
    local visual_scale = self._scale * self._icon_scale
    local border_thickness = math.max(1, _round((tonumber(Style.BORDER_WIDTH) or 1) * visual_scale))
    local fill_margin = math.max(1, _round(BASE_FILL_MARGIN * visual_scale))
    local fill_offset = border_thickness + fill_margin

    if self._text ~= "" then
        label_x = label_x + _round(BASE_TEXT_GAP * self._scale)
    end

    self._icon:SetPosition(0, icon_y)
    self._icon:SetSize(icon_size, icon_size)

    self._border_top:SetPosition(0, 0)
    self._border_top:SetSize(icon_size, border_thickness)

    self._border_bottom:SetPosition(0, math.max(0, icon_size - border_thickness))
    self._border_bottom:SetSize(icon_size, border_thickness)

    self._border_left:SetPosition(0, border_thickness)
    self._border_left:SetSize(border_thickness, math.max(0, icon_size - (2 * border_thickness)))

    self._border_right:SetPosition(math.max(0, icon_size - border_thickness), border_thickness)
    self._border_right:SetSize(border_thickness, math.max(0, icon_size - (2 * border_thickness)))

    local fill_size = math.max(0, icon_size - (2 * fill_offset))
    self._fill:SetPosition(fill_offset, fill_offset)
    self._fill:SetSize(fill_size, fill_size)

    self._label:SetPosition(label_x, 0)
    self._label:SetSize(math.max(0, w - label_x), h)
end

function LuiCheckBox:_update_visual_state()
    local border_color = self._border_color
    local fill_color = self._fill_color
    local text_color = self._text_color

    if self._enabled ~= true then
        border_color = self._border_disabled_color
        fill_color = self._fill_disabled_color
        text_color = self._text_disabled_color
    elseif self._hover == true or self._pressed == true then
        border_color = self._border_hover_color
    end

    self._border_top:SetBackColor(border_color)
    self._border_bottom:SetBackColor(border_color)
    self._border_left:SetBackColor(border_color)
    self._border_right:SetBackColor(border_color)
    self._fill:SetBackColor(fill_color)
    self._fill:SetVisible(self._checked == true)
    self._label:SetForeColor(text_color)
end
