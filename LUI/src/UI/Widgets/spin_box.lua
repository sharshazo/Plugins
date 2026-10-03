-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.line_edit"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local LuiButton = Widgets.LuiButton
local LuiLineEdit = Widgets.LuiLineEdit
local Style = Widgets.Style
local BASE_WIDGET_W = 72
local BASE_WIDGET_H = 21
local BASE_BUTTON_W = 18
local BASE_BUTTON_FONT_SIZE = 8
local BASE_TEXTBOX_INSET_X = 2
local BASE_TEXTBOX_INSET_Y = 2
local BASE_BUTTONS_INSET_Y = 0

local RENDER_PLUS_MINUS = "plus_minus"
local RENDER_ARROWS = "arrows"

local function _scaled_size(scale, value)
    return value * scale
end

local function _scaled_int(scale, value)
    return math.floor(_scaled_size(scale, value) + 0.5)
end

local function _scaled_font(scale, name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(scale, size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(scale, size)))
    end
    return font
end

local function _set_alpha_blend(control)
    if control == nil then
        return
    end
    if control.SetBlendMode ~= nil then
        control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
    if control.SetBackColorBlendMode ~= nil then
        control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
end

local function _round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end


local function _trim_submit_suffix(text)
    if type(text) ~= "string" then
        return nil
    end
    if string.sub(text, -1) ~= "\n" then
        return nil
    end
    return string.gsub(text, "[\r\n]+$", "")
end

local function _round_to_decimals(value, decimals)
    local factor = 10 ^ math.max(0, _round(decimals))
    local number = tonumber(value) or 0
    if number >= 0 then
        return math.floor((number * factor) + 0.5) / factor
    end
    return math.ceil((number * factor) - 0.5) / factor
end

local function _decimal_places(value)
    local number = tonumber(value)
    if number == nil then
        return 0
    end

    local text = string.format("%.8f", math.abs(number))
    text = text:gsub("0+$", "")
    text = text:gsub("%.$", "")
    local decimals = text:match("%.(%d+)")
    return decimals ~= nil and string.len(decimals) or 0
end

---@class LuiSpinBox : Turbine.UI.Control
local LuiSpinBox = class(Turbine.UI.Control)
Widgets.LuiSpinBox = LuiSpinBox

LuiSpinBox.render = {
    PLUS_MINUS = RENDER_PLUS_MINUS,
    ARROWS = RENDER_ARROWS,
}

function LuiSpinBox:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.ValueChanged = nil
    self._on_change = nil

    self._scale = 1
    self._uses_default_size = true
    self._uses_default_font = true
    self._enabled = true
    self._render = RENDER_PLUS_MINUS
    self._minimum = nil
    self._maximum = nil
    self._step = 1
    self._decimals = 0
    self._value = 0
    self._updating_text = false

    self:SetMouseVisible(true)
    _set_alpha_blend(self)

    self._frame = Turbine.UI.Control()
    self._frame:SetParent(self)
    self._frame:SetMouseVisible(false)
    _set_alpha_blend(self._frame)
    self._frame:SetBackColor(Style.CONTROL_BORDER)

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self._frame)
    self._inner:SetMouseVisible(false)
    _set_alpha_blend(self._inner)
    self._inner:SetBackColor(Style.TRANSPARENT_BACKGROUND)

    self._field_back = Turbine.UI.Control()
    self._field_back:SetParent(self._inner)
    self._field_back:SetMouseVisible(false)
    _set_alpha_blend(self._field_back)
    self._field_back:SetBackColor(Style.BACKGROUND)

    self._buttons_back = Turbine.UI.Control()
    self._buttons_back:SetParent(self._inner)
    self._buttons_back:SetMouseVisible(false)
    _set_alpha_blend(self._buttons_back)
    self._buttons_back:SetBackColor(Style.ALTERNATE_BACKGROUND)

    self.text_box = LuiLineEdit()
    self.text_box:SetParent(self._field_back)
    self.text_box:set_border_visible(false)
    self.text_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.text_box:SetWantsKeyEvents(true)
    _set_alpha_blend(self.text_box)
    self.text_box.TextChanged = function()
        if self._updating_text == true then
            return
        end

        local trimmed = _trim_submit_suffix(self.text_box:GetText())
        if trimmed ~= nil then
            self._updating_text = true
            self.text_box:SetText(trimmed)
            self._updating_text = false
            self:_commit_text()
        end
    end
    self.text_box.FocusLost = function()
        self:_commit_text()
    end

    self.increment_button = LuiButton()
    self.increment_button:SetParent(self._buttons_back)
    Style.apply_embedded_button(self.increment_button)
    self.increment_button.Click = function()
        self:_adjust(self._step)
    end

    self.decrement_button = LuiButton()
    self.decrement_button:SetParent(self._buttons_back)
    Style.apply_embedded_button(self.decrement_button)
    self.decrement_button.Click = function()
        self:_adjust(-self._step)
    end

    self.SizeChanged = function()
        self:_layout()
    end

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_WIDGET_W), _scaled_int(self._scale, BASE_WIDGET_H))
    self:_apply_default_font()
    self:set_render(RENDER_PLUS_MINUS)
    self:set_value(0, false)
end

function LuiSpinBox:_apply_default_font()
    self.text_box:SetFont(_scaled_font(self._scale, Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE))
    local button_font = _scaled_font(self._scale, "Verdana", BASE_BUTTON_FONT_SIZE)
    self.increment_button:set_font(button_font)
    self.decrement_button:set_font(button_font)
end

function LuiSpinBox:_effective_decimals()
    if self._decimals ~= nil then
        return math.max(0, _round(self._decimals))
    end
    return _decimal_places(self._step)
end

function LuiSpinBox:_format_value(value)
    local decimals = self:_effective_decimals()
    local rounded = _round_to_decimals(value, decimals)
    if decimals <= 0 then
        return tostring(_round(rounded))
    end

    local text = string.format("%." .. tostring(decimals) .. "f", rounded)
    text = text:gsub("0+$", "")
    text = text:gsub("%.$", "")
    if text == "-0" then
        text = "0"
    end
    return text
end

function LuiSpinBox:_normalize_value(value)
    local number = tonumber(value)
    if number == nil then
        return nil
    end

    local decimals = self:_effective_decimals()
    number = _round_to_decimals(number, decimals)

    if self._minimum ~= nil and number < self._minimum then
        number = self._minimum
    end
    if self._maximum ~= nil and number > self._maximum then
        number = self._maximum
    end

    return _round_to_decimals(number, decimals)
end

function LuiSpinBox:_set_text(text)
    self._updating_text = true
    self.text_box:SetText(text or "")
    self._updating_text = false
end

function LuiSpinBox:_update_buttons()
    local enabled = self._enabled == true
    local value = tonumber(self._value) or 0

    local can_increment = enabled
    local can_decrement = enabled
    if self._maximum ~= nil and value >= self._maximum then
        can_increment = false
    end
    if self._minimum ~= nil and value <= self._minimum then
        can_decrement = false
    end

    self.increment_button:set_enabled(can_increment)
    self.decrement_button:set_enabled(can_decrement)
    if self.text_box.SetEnabled ~= nil then
        self.text_box:SetEnabled(enabled)
    end
end

function LuiSpinBox:_emit_changed()
    if type(self._on_change) == "function" then
        self._on_change(self, self._value)
    end
    if type(self.ValueChanged) == "function" then
        self.ValueChanged(self, self._value)
    end
end

function LuiSpinBox:_set_value_internal(value, fire_event)
    local normalized = self:_normalize_value(value)
    if normalized == nil then
        self:_set_text(self:_format_value(self._value))
        self:_update_buttons()
        return false
    end

    local changed = tonumber(self._value) ~= normalized
    self._value = normalized
    self:_set_text(self:_format_value(normalized))
    self:_update_buttons()

    if changed == true and fire_event == true then
        self:_emit_changed()
    end

    return changed
end

function LuiSpinBox:_commit_text()
    self:_set_value_internal(self.text_box:GetText(), true)
end

function LuiSpinBox:_adjust(delta)
    local base = tonumber(self._value) or 0
    self:_set_value_internal(base + (tonumber(delta) or 0), true)
end

function LuiSpinBox:_layout()
    local width, height = self:GetSize()
    local border = math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH) or 1))
    local button_w = _scaled_int(self._scale, BASE_BUTTON_W)
    local inset_x = _scaled_int(self._scale, BASE_TEXTBOX_INSET_X)
    local inset_y = _scaled_int(self._scale, BASE_TEXTBOX_INSET_Y)
    local buttons_inset_y = _scaled_int(self._scale, BASE_BUTTONS_INSET_Y)

    self._frame:SetPosition(0, 0)
    self._frame:SetSize(width, height)

    local inner_w = math.max(0, width - (border * 2))
    local inner_h = math.max(0, height - (border * 2))
    self._inner:SetPosition(border, border)
    self._inner:SetSize(inner_w, inner_h)

    if button_w > inner_w then
        button_w = inner_w
    end
    local field_w = math.max(0, inner_w - button_w)

    self._field_back:SetPosition(0, 0)
    self._field_back:SetSize(field_w, inner_h)

    local buttons_h = math.max(0, inner_h - (buttons_inset_y * 2))
    self._buttons_back:SetVisible(true)
    self._buttons_back:SetPosition(field_w, buttons_inset_y)
    self._buttons_back:SetSize(button_w, buttons_h)

    self.text_box:SetPosition(inset_x, inset_y)
    self.text_box:SetSize(
        math.max(0, field_w - (inset_x * 2)),
        math.max(0, inner_h - (inset_y * 2))
    )

    local top_h = math.max(0, math.floor(buttons_h / 2))
    local bottom_y = top_h
    local bottom_h = math.max(0, buttons_h - bottom_y)
    self.increment_button:SetPosition(0, 0)
    self.increment_button:SetSize(button_w, top_h)
    self.decrement_button:SetPosition(0, bottom_y)
    self.decrement_button:SetSize(button_w, bottom_h)
end

function LuiSpinBox:set_render(render_mode)
    if render_mode ~= RENDER_ARROWS then
        render_mode = RENDER_PLUS_MINUS
    end
    self._render = render_mode

    if render_mode == RENDER_ARROWS then
        self.increment_button:set_text("^")
        self.decrement_button:set_text("v")
    else
        self.increment_button:set_text("+")
        self.decrement_button:set_text("-")
    end
end

function LuiSpinBox:set_minimum(value)
    self._minimum = value ~= nil and tonumber(value) or nil
    if self._maximum ~= nil and self._minimum ~= nil and self._maximum < self._minimum then
        self._maximum = self._minimum
    end
    self:_set_value_internal(self._value, false)
end

function LuiSpinBox:set_maximum(value)
    self._maximum = value ~= nil and tonumber(value) or nil
    if self._minimum ~= nil and self._maximum ~= nil and self._maximum < self._minimum then
        self._minimum = self._maximum
    end
    self:_set_value_internal(self._value, false)
end

function LuiSpinBox:set_step(value)
    local number = tonumber(value)
    if number == nil or number <= 0 then
        return
    end
    self._step = number
    self:_set_value_internal(self._value, false)
end

function LuiSpinBox:set_decimals(value)
    if value == nil then
        self._decimals = nil
    else
        self._decimals = math.max(0, _round(value))
    end
    self:_set_value_internal(self._value, false)
end

function LuiSpinBox:set_value(value, fire_event)
    self:_set_value_internal(value, fire_event == true)
end

function LuiSpinBox:get_value()
    return self._value
end

function LuiSpinBox:set_on_change(fn)
    self._on_change = type(fn) == "function" and fn or nil
end

function LuiSpinBox:set_enabled(enabled)
    self._enabled = enabled == true
    Turbine.UI.Control.SetEnabled(self, self._enabled)
    self:_update_buttons()
end

function LuiSpinBox:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        return
    end

    self._scale = scale
    self.increment_button:set_scale(scale)
    self.decrement_button:set_scale(scale)

    if self._uses_default_font == true then
        self:_apply_default_font()
    end
    if self._uses_default_size == true then
        Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_WIDGET_W), _scaled_int(self._scale, BASE_WIDGET_H))
    end

    self:_layout()
end

function LuiSpinBox:SetFont(font)
    if font == nil then
        return
    end
    self._uses_default_font = false
    self.text_box:SetFont(font)
end

function LuiSpinBox:SetButtonFont(font)
    if font == nil then
        return
    end
    self.increment_button:set_font(font)
    self.decrement_button:set_font(font)
end

function LuiSpinBox:SetTextAlignment(alignment)
    if alignment ~= nil then
        self.text_box:SetTextAlignment(alignment)
    end
end

function LuiSpinBox:SetValue(value)
    self:set_value(value, false)
end

function LuiSpinBox:GetValue()
    return self:get_value()
end

function LuiSpinBox:SetEnabled(enabled)
    self:set_enabled(enabled)
end

function LuiSpinBox:destroy()
    if self.increment_button ~= nil then
        self.increment_button:SetParent(nil)
    end
    if self.decrement_button ~= nil then
        self.decrement_button:SetParent(nil)
    end
    if self.text_box ~= nil then
        self.text_box:SetParent(nil)
    end
    if self._field_back ~= nil then
        self._field_back:SetParent(nil)
    end
    if self._buttons_back ~= nil then
        self._buttons_back:SetParent(nil)
    end
    if self._inner ~= nil then
        self._inner:SetParent(nil)
    end
    if self._frame ~= nil then
        self._frame:SetParent(nil)
    end
    self:SetVisible(false)
end
