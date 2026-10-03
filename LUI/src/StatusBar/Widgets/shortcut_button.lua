-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "LUI.src.UI.Widgets"
import "LUI.src.UI.shortcuts"

local S = _G.LUI.Features.StatusBar.Common
local Shortcuts = UI.Shortcuts
local Style = UI.Widgets.Style
local BUTTON_MARGIN = 1
local BUTTON_BORDER = 1

local ShortcutButtonWidget = class(Turbine.UI.Control)
StatusBarWidgets.ShortcutButtonWidget = ShortcutButtonWidget

function ShortcutButtonWidget:Constructor(shortcut_key, display_mode, widget_w, bar_h, font)
    Turbine.UI.Control.Constructor(self)

    self.shortcut_key = shortcut_key
    self.display_mode = display_mode
    self.font = font
    self.icon_background = Shortcuts.get_icon(shortcut_key)
    self._available = nil
    self._interaction_enabled = true

    self:SetSize(widget_w, bar_h)
    self:SetMouseVisible(false)

    self.button = UI.Widgets.LuiButton()
    self.button:SetParent(self)
    self._interaction_target = self.button
    self.button:set_border_thickness(BUTTON_BORDER)
    self.button:set_border_color(Style.CONTROL_BORDER)
    self.button:set_hover_border_color(Style.CONTROL_BORDER_HOVER)
    self.button:set_active_border_color(Style.CONTROL_BORDER_ACTIVE)
    self.button:set_disabled_border_color(Style.CONTROL_BORDER_DISABLED)
    self.button:set_back_color(Style.CONTROL_BACKGROUND)
    self.button:set_hover_back_color(Style.CONTROL_BACKGROUND_HOVER)
    self.button:set_pressed_back_color(Style.CONTROL_BACKGROUND_PRESSED)
    self.button:set_active_back_color(Style.CONTROL_BACKGROUND_ACTIVE)
    self.button:set_disabled_back_color(Style.CONTROL_BACKGROUND_DISABLED)
    self.button:set_padding(0)
    self.button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleCenter)

    if font ~= nil then
        if font.lotro ~= nil then
            self.button._label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.button._label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.outline_color ~= nil then
            self.button._label:SetOutlineColor(font.outline_color)
        end
        if font.color ~= nil then
            self.button:set_text_color(font.color)
            self.button:set_hover_text_color(font.color)
            self.button:set_pressed_text_color(font.color)
            self.button:set_active_text_color(font.color)
        end
    end
    self.button:set_disabled_text_color(S.with_alpha(font ~= nil and font.color or nil, 0.45))

    if self.display_mode == "icon" and self.icon_background ~= nil then
        self.button:set_text("")
    else
        self.button:set_icon(nil, nil, nil, nil, 0)
        self.button:set_text(Shortcuts.get_label(shortcut_key))
    end

    self.button.Click = function()
        if self._interaction_enabled ~= true then
            return
        end
        Shortcuts.activate(self.shortcut_key)
        self:_refresh_state()
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self:_layout()
    self:_refresh_state()
end

function ShortcutButtonWidget:update(now)
    self:_refresh_state()
end

function ShortcutButtonWidget:set_interaction_enabled(enabled)
    self._interaction_enabled = enabled == true
    self:_refresh_state()
end

function ShortcutButtonWidget:get_interaction_target()
    return self._interaction_target
end

function ShortcutButtonWidget:destroy()
    self:SetVisible(false)
    if self.button ~= nil then
        self.button:SetVisible(false)
        self.button:SetParent(nil)
    end
    self:SetParent(nil)
end

function ShortcutButtonWidget:_layout()
    local w, h = self:GetSize()
    local margin = BUTTON_MARGIN
    if margin * 2 > w then
        margin = math.floor(w / 2)
    end
    if margin * 2 > h then
        margin = math.floor(h / 2)
    end

    local button_w = math.max(0, w - (margin * 2))
    local button_h = math.max(0, h - (margin * 2))
    self.button:SetPosition(margin, margin)
    self.button:SetSize(button_w, button_h)

    if self.display_mode == "icon" and self.icon_background ~= nil then
        local inner_h = math.max(0, button_h - (BUTTON_BORDER * 2))
        local icon_h = S.get_icon_size(inner_h)
        self.button:set_icon(self.icon_background, nil, nil, nil, icon_h)
    end
end

function ShortcutButtonWidget:_refresh_state()
    local available = Shortcuts.get_state(self.shortcut_key)
    local is_available = available == true
    if is_available == self._available then
        if self.button ~= nil then
            self.button:set_enabled(self._available == true and self._interaction_enabled == true)
        end
        return
    end

    self._available = is_available
    self.button:set_enabled(self._available == true and self._interaction_enabled == true)
end
