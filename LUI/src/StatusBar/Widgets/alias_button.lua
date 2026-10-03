-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"

local S = _G.LUI.Features.StatusBar.Common
local Style = UI.Widgets.Style
local BUTTON_MARGIN = 1
local BUTTON_BORDER = 1

local AliasButtonWidget = class(Turbine.UI.Control)
StatusBarWidgets.AliasButtonWidget = AliasButtonWidget

local function _apply_font(label, font)
    if label == nil or font == nil then
        return
    end
    if font.lotro ~= nil then
        label:SetFont(font.lotro)
    end
    if font.style ~= nil then
        label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
    end
    if font.outline_color ~= nil then
        label:SetOutlineColor(font.outline_color)
    end
    if font.color ~= nil then
        label:SetForeColor(font.color)
    end
end

function AliasButtonWidget:Constructor(spec, widget_w, bar_h, font)
    Turbine.UI.Control.Constructor(self)

    local entry = type(spec) == "table" and spec or {}

    self.command = type(entry.command) == "string" and entry.command or nil
    self.icon_background = nil
    if type(entry.icon_background) == "number" or type(entry.icon_background) == "string" then
        self.icon_background = entry.icon_background
    end
    self.icon_label = type(entry.icon_label) == "string" and entry.icon_label or nil
    self.font = font
    self._hover = false
    self._pressed = false

    self:SetSize(widget_w, bar_h)
    self:SetMouseVisible(true)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)

    self.border_top = Turbine.UI.Control()
    self.border_top:SetParent(self)
    self.border_top:SetMouseVisible(false)
    self.border_top:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_top:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_top:SetBackColor(Style.CONTROL_BORDER)
    self.border_top:SetZOrder(3)

    self.border_bottom = Turbine.UI.Control()
    self.border_bottom:SetParent(self)
    self.border_bottom:SetMouseVisible(false)
    self.border_bottom:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_bottom:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_bottom:SetBackColor(Style.CONTROL_BORDER)
    self.border_bottom:SetZOrder(3)

    self.border_left = Turbine.UI.Control()
    self.border_left:SetParent(self)
    self.border_left:SetMouseVisible(false)
    self.border_left:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_left:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_left:SetBackColor(Style.CONTROL_BORDER)
    self.border_left:SetZOrder(3)

    self.border_right = Turbine.UI.Control()
    self.border_right:SetParent(self)
    self.border_right:SetMouseVisible(false)
    self.border_right:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_right:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_right:SetBackColor(Style.CONTROL_BORDER)
    self.border_right:SetZOrder(3)

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    self.background:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.background:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.background:SetBackColor(Style.CONTROL_BACKGROUND)
    self.background:SetZOrder(1)

    self.icon = UI.Widgets.Image(self.icon_background)
    self.icon:SetParent(self)
    self.icon:SetZOrder(2)
    self.icon:set_alignment(UI.Widgets.Image.CENTER + UI.Widgets.Image.MIDDLE)

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self)
    self.label:SetMouseVisible(false)
    self.label:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.label:SetText(self.icon_label or "")
    self.label:SetZOrder(2)
    _apply_font(self.label, self.font)

    if self.command ~= nil then
        self.shortcut = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, "")
        self.shortcut:SetData(self.command)

        self.slot = Turbine.UI.Lotro.Quickslot()
        self.slot:SetParent(self)
        self.slot:SetAllowDrop(false)
        self.slot:SetUseOnRightClick(false)
        self.slot:SetShortcut(self.shortcut)
        self.slot:SetVisible(true)

        local function _forward(name, args)
            local handler = self[name]
            if type(handler) == "function" then
                handler(self, args)
            end
        end

        self.slot.MouseClick = function(_, args)
            _forward("MouseClick", args)
        end
        self.slot.MouseEnter = function(_, args)
            _forward("MouseEnter", args)
        end
        self.slot.MouseLeave = function(_, args)
            _forward("MouseLeave", args)
        end
        self.slot.MouseDown = function(_, args)
            _forward("MouseDown", args)
        end
        self.slot.MouseMove = function(_, args)
            _forward("MouseMove", args)
        end
        self.slot.MouseUp = function(_, args)
            _forward("MouseUp", args)
        end
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        self._hover = true
        self:_update_visual_state()
    end

    self.MouseLeave = function()
        self._hover = false
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseDown = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._pressed = true
        self:_update_visual_state()
    end

    self.MouseUp = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._pressed = false
        self:_update_visual_state()
    end

    self:_layout()
    self:set_interaction_enabled(true)
    self:_update_visual_state()
end

function AliasButtonWidget:set_interaction_enabled(enabled)
    if self.slot ~= nil and self.slot.SetMouseVisible ~= nil then
        self.slot:SetMouseVisible(enabled == true)
    end
end

function AliasButtonWidget:update(now)
end

function AliasButtonWidget:destroy()
    self:SetVisible(false)
    if self.border_top ~= nil then self.border_top:SetVisible(false) end
    if self.border_bottom ~= nil then self.border_bottom:SetVisible(false) end
    if self.border_left ~= nil then self.border_left:SetVisible(false) end
    if self.border_right ~= nil then self.border_right:SetVisible(false) end
    if self.slot ~= nil then self.slot:SetVisible(false) end
    if self.background ~= nil then self.background:SetVisible(false) end
    if self.icon ~= nil then self.icon:SetVisible(false) end
    if self.label ~= nil then self.label:SetVisible(false) end
    if self.border_top ~= nil then self.border_top:SetParent(nil) end
    if self.border_bottom ~= nil then self.border_bottom:SetParent(nil) end
    if self.border_left ~= nil then self.border_left:SetParent(nil) end
    if self.border_right ~= nil then self.border_right:SetParent(nil) end
    if self.slot ~= nil then self.slot:SetParent(nil) end
    if self.background ~= nil then self.background:SetParent(nil) end
    if self.icon ~= nil then self.icon:SetParent(nil) end
    if self.label ~= nil then self.label:SetParent(nil) end
    self:SetParent(nil)
end

function AliasButtonWidget:_layout()
    local w, h = self:GetSize()
    local margin = BUTTON_MARGIN
    if margin * 2 > w then
        margin = math.floor(w / 2)
    end
    if margin * 2 > h then
        margin = math.floor(h / 2)
    end

    local button_x = margin
    local button_y = margin
    local button_w = math.max(0, w - (margin * 2))
    local button_h = math.max(0, h - (margin * 2))
    local inner_w = math.max(0, button_w - (BUTTON_BORDER * 2))
    local inner_h = math.max(0, button_h - (BUTTON_BORDER * 2))
    local slot_size = math.min(inner_w, inner_h)

    self.border_top:SetPosition(button_x, button_y)
    self.border_top:SetSize(button_w, math.min(BUTTON_BORDER, button_h))

    self.border_bottom:SetPosition(button_x, button_y + math.max(0, button_h - BUTTON_BORDER))
    self.border_bottom:SetSize(button_w, math.min(BUTTON_BORDER, button_h))

    self.border_left:SetPosition(button_x, button_y)
    self.border_left:SetSize(math.min(BUTTON_BORDER, button_w), button_h)

    self.border_right:SetPosition(button_x + math.max(0, button_w - BUTTON_BORDER), button_y)
    self.border_right:SetSize(math.min(BUTTON_BORDER, button_w), button_h)

    self.background:SetPosition(button_x + BUTTON_BORDER, button_y + BUTTON_BORDER)
    self.background:SetSize(inner_w, inner_h)
    self.background:SetVisible(inner_w > 0 and inner_h > 0)

    if self.slot ~= nil then
        local slot_x = button_x + BUTTON_BORDER + math.floor((inner_w - slot_size) / 2)
        local slot_y = button_y + BUTTON_BORDER + math.floor((inner_h - slot_size) / 2)
        self.slot:SetPosition(slot_x, slot_y)
        self.slot:SetSize(slot_size, slot_size)
    end

    if self.icon_background ~= nil then
        local icon_h = S.get_icon_size(inner_h)
        self.icon:set_height(icon_h)
        self.icon:SetVisible(icon_h > 0)
    else
        self.icon:SetVisible(false)
    end

    self.label:SetPosition(button_x + BUTTON_BORDER, button_y + BUTTON_BORDER)
    self.label:SetSize(inner_w, inner_h)
    self.label:SetVisible(self.icon_label ~= nil and self.icon_label ~= "")
end

function AliasButtonWidget:_set_border_color(color)
    self.border_top:SetBackColor(color)
    self.border_bottom:SetBackColor(color)
    self.border_left:SetBackColor(color)
    self.border_right:SetBackColor(color)
end

function AliasButtonWidget:_update_visual_state()
    local border_color = Style.CONTROL_BORDER
    local fill_color = Style.CONTROL_BACKGROUND

    if self._hover or self._pressed then
        border_color = Style.CONTROL_BORDER_HOVER
        fill_color = self._pressed == true and Style.CONTROL_BACKGROUND_PRESSED or Style.CONTROL_BACKGROUND_HOVER
    end

    self:_set_border_color(border_color)
    if self.background ~= nil then
        self.background:SetBackColor(fill_color)
    end
    if self.label ~= nil and self.font ~= nil and self.font.color ~= nil then
        self.label:SetForeColor(self.font.color)
    end
end
