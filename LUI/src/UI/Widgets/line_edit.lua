-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local LuiLabel = Widgets.LuiLabel
local Style = Widgets.Style
local DEFAULT_INSET_X = 4
local PLACEHOLDER_CURSOR_GAP = 2
local SCROLL_BAR_WIDTH = 10

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _set_alpha_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

---@class LuiLineEdit : Turbine.UI.Control
local LuiLineEdit = class(Turbine.UI.Control)
Widgets.LuiLineEdit = LuiLineEdit
Widgets.LineEdit = LuiLineEdit

function LuiLineEdit:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._placeholder_text = ""
    self._placeholder_color = Style.PLACEHOLDER_FOREGROUND
    self._text_alignment = Turbine.UI.ContentAlignment.MiddleLeft
    self._enabled = true
    self._read_only = false
    self._multiline = false
    self._scroll_bar = nil
    self._border_visible = true
    self._back_color = Style.BACKGROUND
    self._back_color_custom = false
    self._text_color = Style.CONTROL_FOREGROUND
    self._digits_only = false
    self._digits_updating = false

    self:SetMouseVisible(true)
    _set_alpha_blend(self)

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self)
    self._inner:SetMouseVisible(false)
    _set_alpha_blend(self._inner)

    self.text_box = Turbine.UI.Lotro.TextBox()
    self.text_box:SetParent(self._inner)
    self.text_box:SetZOrder(1)
    self.text_box:SetTextAlignment(self._text_alignment)

    self.placeholder_label = LuiLabel()
    self.placeholder_label:SetParent(self._inner)
    self.placeholder_label:SetZOrder(2)
    self.placeholder_label:SetMouseVisible(false)
    self.placeholder_label:SetSelectable(false)
    self.placeholder_label:SetTextAlignment(self._text_alignment)
    self.placeholder_label:SetForeColor(self._placeholder_color)
    self.placeholder_label:SetText("")
    self.placeholder_label:SetVisible(false)

    self.text_box.MouseEnter = function(sender, args)
        if type(self.MouseEnter) == "function" then
            self.MouseEnter(self, args)
        end
    end
    self.text_box.MouseLeave = function(sender, args)
        if type(self.MouseLeave) == "function" then
            self.MouseLeave(self, args)
        end
    end
    self.text_box.TextChanged = function(sender, args)
        if self._digits_only == true and self._digits_updating ~= true then
            -- the Lotro TextBox is multiline: Enter inserts a newline, so a
            -- stripped newline doubles as the submit signal (same trick as
            -- LuiSpinBox)
            local text = self.text_box:GetText() or ""
            local submitted = string.find(text, "\n", 1, true) ~= nil
            local digits = string.gsub(text, "%D", "")
            if digits ~= text then
                self._digits_updating = true
                self.text_box:SetText(digits)
                self._digits_updating = false
                if submitted == true and type(self.Submitted) == "function" then
                    self.Submitted(self, digits)
                end
                return
            end
        end
        self:_refresh_placeholder()
        if type(self.TextChanged) == "function" then
            self.TextChanged(self, args)
        end
    end
    self.text_box.FocusGained = function(sender, args)
        if type(self.FocusGained) == "function" then
            self.FocusGained(self, args)
        end
    end
    self.text_box.FocusLost = function(sender, args)
        if type(self.FocusLost) == "function" then
            self.FocusLost(self, args)
        end
    end
    self.text_box.KeyDown = function(sender, args)
        if type(self.KeyDown) == "function" then
            self.KeyDown(self, args)
        end
    end
    self.text_box.KeyUp = function(sender, args)
        if type(self.KeyUp) == "function" then
            self.KeyUp(self, args)
        end
    end

    self:_update_visual_state(true)
end

function LuiLineEdit:_border_width()
    if self._border_visible ~= true then
        return 0
    end
    return math.max(1, _scaled_int(self._scale, Style.BORDER_WIDTH_THIN))
end

function LuiLineEdit:_current_border_color()
    if self._border_visible ~= true then
        return Style.TRANSPARENT_BACKGROUND
    end
    if self._enabled ~= true then
        return Style.CONTROL_BORDER_DISABLED
    end
    return Style.CONTROL_BORDER
end

function LuiLineEdit:_current_back_color()
    if self._enabled ~= true then
        return Style.CONTROL_BACKGROUND_DISABLED
    end
    if self._read_only == true and self._back_color_custom ~= true then
        return Style.CONTROL_BACKGROUND_READONLY
    end
    return self._back_color
end

function LuiLineEdit:_current_text_color()
    if self._enabled ~= true then
        return Style.CONTROL_FOREGROUND_DISABLED
    end
    return self._text_color
end

function LuiLineEdit:_update_visual_state(sync_text_box)
    local back = self:_current_back_color()
    Turbine.UI.Control.SetBackColor(self, self:_current_border_color())
    self._inner:SetBackColor(back)
    if sync_text_box == true and self.text_box.SetBackColor ~= nil then
        self.text_box:SetBackColor(back)
    end
    if sync_text_box == true and self.text_box.SetForeColor ~= nil then
        self.text_box:SetForeColor(self:_current_text_color())
    end
    if self._enabled == true then
        self.placeholder_label:SetForeColor(self._placeholder_color)
    else
        self.placeholder_label:SetForeColor(Style.CONTROL_FOREGROUND_DISABLED)
    end
end

function LuiLineEdit:_layout()
    local w, h = self:GetSize()
    local border = self:_border_width()
    local inner_w = math.max(0, w - (border * 2))
    local inner_h = math.max(0, h - (border * 2))

    self._inner:SetPosition(border, border)
    self._inner:SetSize(inner_w, inner_h)

    local text_w = inner_w
    if self._scroll_bar ~= nil and self._multiline == true then
        local sb_w = SCROLL_BAR_WIDTH
        if sb_w > inner_w then
            sb_w = inner_w
        end
        self._scroll_bar:SetPosition(inner_w - sb_w, 0)
        self._scroll_bar:SetSize(sb_w, inner_h)
        text_w = math.max(0, inner_w - sb_w)
    end

    self.text_box:SetPosition(0, 0)
    self.text_box:SetSize(text_w, inner_h)

    local inset_x = math.floor(((DEFAULT_INSET_X + PLACEHOLDER_CURSOR_GAP) * self._scale) + 0.5)
    self.placeholder_label:SetPosition(inset_x, 0)
    self.placeholder_label:SetSize(math.max(0, text_w - (inset_x * 2)), inner_h)
end

function LuiLineEdit:_refresh_placeholder()
    local text = self.text_box:GetText() or ""
    self.placeholder_label:SetVisible(self._placeholder_text ~= "" and text == "")
end

function LuiLineEdit:set_placeholder_text(text)
    self._placeholder_text = tostring(text or "")
    self.placeholder_label:SetText(self._placeholder_text)
    self:_refresh_placeholder()
end

function LuiLineEdit:get_placeholder_text()
    return self._placeholder_text
end

function LuiLineEdit:set_placeholder_color(color)
    if color == nil then
        return
    end
    self._placeholder_color = color
    self:_update_visual_state()
end

function LuiLineEdit:SetPlaceholderText(text)
    self:set_placeholder_text(text)
end

function LuiLineEdit:GetPlaceholderText()
    return self:get_placeholder_text()
end

function LuiLineEdit:SetPlaceholderColor(color)
    self:set_placeholder_color(color)
end

function LuiLineEdit:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
    self:_layout()
end

function LuiLineEdit:set_border_visible(visible)
    self._border_visible = visible == true
    self:_layout()
    self:_update_visual_state()
end

function LuiLineEdit:SetBorderVisible(visible)
    self:set_border_visible(visible)
end

function LuiLineEdit:SetSize(w, h)
    Turbine.UI.Control.SetSize(self, w, h)
    self:_layout()
end

function LuiLineEdit:SetFont(font)
    if font == nil then
        return
    end
    self.text_box:SetFont(font)
    self.placeholder_label:SetFont(font)
end

function LuiLineEdit:SetTextAlignment(alignment)
    if alignment == nil then
        return
    end
    self._text_alignment = alignment
    self.text_box:SetTextAlignment(alignment)
    self.placeholder_label:SetTextAlignment(alignment)
end

function LuiLineEdit:SetForeColor(color)
    if color ~= nil then
        self._text_color = color
        self:_update_visual_state(true)
    end
end

function LuiLineEdit:SetBackColor(color)
    if color == nil then
        return
    end
    self._back_color = color
    self._back_color_custom = true
    self:_update_visual_state(true)
end

function LuiLineEdit:SetMultiline(multiline)
    self._multiline = multiline == true
    if self.text_box.SetMultiline ~= nil then
        self.text_box:SetMultiline(self._multiline)
    end

    if self._multiline == true and self._scroll_bar == nil and self.text_box.SetVerticalScrollBar ~= nil then
        self._scroll_bar = Turbine.UI.Lotro.ScrollBar()
        self._scroll_bar:SetParent(self._inner)
        self._scroll_bar:SetOrientation(Turbine.UI.Orientation.Vertical)
        self._scroll_bar:SetZOrder(3)
        self.text_box:SetVerticalScrollBar(self._scroll_bar)
    end

    if self._scroll_bar ~= nil then
        self._scroll_bar:SetVisible(self._multiline)
    end

    self:_layout()
end

function LuiLineEdit:SetText(text)
    self.text_box:SetText(text or "")
    self:_refresh_placeholder()
end

-- Re-apply the current text on the next frame. The Lotro TextBox does not
-- paint text that was set while its window was hidden, and re-setting it
-- in the same call stack that shows the window is still too early; the
-- config pages fix the same quirk with SetText(GetText()) once the page
-- is actually on screen.
function LuiLineEdit:refresh_text_async()
    self.Update = function()
        self:SetWantsUpdates(false)
        self.Update = nil
        self.text_box:SetText(self.text_box:GetText())
        self:_refresh_placeholder()
    end
    self:SetWantsUpdates(true)
end

function LuiLineEdit:GetText()
    return self.text_box:GetText()
end

-- Digits-only mode: typed/pasted non-digits are stripped as they arrive,
-- and Enter fires the optional Submitted(self, digits) callback instead of
-- TextChanged.
function LuiLineEdit:set_digits_only(digits_only)
    self._digits_only = digits_only == true
end

function LuiLineEdit:SetWantsKeyEvents(wants_key_events)
    if self.text_box.SetWantsKeyEvents ~= nil then
        self.text_box:SetWantsKeyEvents(wants_key_events)
    end
end

function LuiLineEdit:SetSelectable(selectable)
    if self.text_box.SetSelectable ~= nil then
        self.text_box:SetSelectable(selectable)
    end
end

function LuiLineEdit:SetReadOnly(read_only)
    self._read_only = read_only == true
    if self.text_box.SetReadOnly ~= nil then
        self.text_box:SetReadOnly(read_only)
    end
    self:_update_visual_state(true)
end

function LuiLineEdit:SetEnabled(enabled)
    self._enabled = enabled == true
    Turbine.UI.Control.SetEnabled(self, self._enabled)
    if self.text_box.SetEnabled ~= nil then
        self.text_box:SetEnabled(self._enabled)
    end
    self:_update_visual_state(true)
end

function LuiLineEdit:Focus()
    self.text_box:Focus()
end

function LuiLineEdit:HasFocus()
    if self.text_box.HasFocus == nil then
        return false
    end
    return self.text_box:HasFocus()
end

function LuiLineEdit:destroy()
    if self.placeholder_label ~= nil then
        self.placeholder_label:SetParent(nil)
    end
    if self.text_box ~= nil then
        self.text_box:SetParent(nil)
    end
    if self._scroll_bar ~= nil then
        self._scroll_bar:SetParent(nil)
    end
    self._inner:SetParent(nil)
    self:SetVisible(false)
end
