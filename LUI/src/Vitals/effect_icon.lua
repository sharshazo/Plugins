-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_format_icon_timeout = _G.LUI.Utils.lui_format_icon_timeout
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.time_format"

local EffectIcon = class(UI.Widgets.LuiBaseWindow)
Vitals.EffectIcon = EffectIcon

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function EffectIcon:Constructor(effect, size, font, font_style, font_color, outline_color)
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = false })

    self.effect = nil
    self.ending = 0

    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate

    self:SetSize(size, size)

    self.icon = Turbine.UI.Lotro.EffectDisplay()
    self.icon:SetParent(self)
    self.icon:SetSize(size, size)
    self.icon:SetZOrder(1)

    self.label_back = Turbine.UI.Window()
    self:apply_native_scaling(self.label_back)
    self.label_back:SetParent(self)
    self.label_back:SetSize(size, size)
    self.label_back:SetVisible(true)
    self.label_back:SetMouseVisible(false)
    self.label_back:SetZOrder(5)

    self.timer = UI.Widgets.LuiLabel()
    self.timer:SetParent(self.label_back)
    self.timer:SetSize(size, size)
    self.timer:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
    self.timer:SetFont(font)
    if font_style ~= nil then
        self.timer:SetFontStyle(font_style)
    else
        self.timer:SetFontStyle(Turbine.UI.FontStyle.Outline)
    end
    if outline_color ~= nil then
        self.timer:SetOutlineColor(outline_color)
    end
    if font_color ~= nil then
        self.timer:SetForeColor(font_color)
    end
    self.timer:SetMouseVisible(false)
    self.timer:SetZOrder(5)

    self:SetVisible(true)

    self:set_effect(effect)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

function EffectIcon:destroy()
    self.icon:SetEffect(nil)
    self.effect = nil
    self.ending = 0
    self:SetWantsUpdates(false)
    self.timer:SetText("")
    self.label_back:SetVisible(false)
    self:SetVisible(false)
end

function EffectIcon:get_effect_id()
    if self.effect == nil then
        return 0
    end
    return self.effect:GetID()
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function EffectIcon:set_effect(effect)
    self.effect = effect
    self.last_update_at = -(self.update_every or 0)

    if effect == nil then
        self.icon:SetEffect(nil)
        self.timer:SetText("")
        self:SetWantsUpdates(false)
        self.ending = 0
        return
    end

    self.icon:SetEffect(effect)
    self.label_back:SetVisible(true)
    self:SetVisible(true)

    local duration = (effect.GetDuration ~= nil and effect:GetDuration()) or 0
    if duration > 0 and duration < 9999 and effect.GetStartTime ~= nil then
        self.ending = effect:GetStartTime() + duration
    else
        self.ending = 0
    end

    self:SetWantsUpdates(true)
    self:Update()
end

function EffectIcon:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    if self.effect == nil then
        self.timer:SetText("")
        self:SetWantsUpdates(false)
        return
    end

    local duration = (self.effect.GetDuration ~= nil and self.effect:GetDuration()) or 0
    if duration <= 0 or duration >= 9999 or self.effect.GetStartTime == nil then
        self.ending = 0
        self.timer:SetText("")
        self:SetWantsUpdates(false)
        return
    end

    local start = self.effect:GetStartTime()
    self.ending = start + duration
    local time_left = self.ending - Turbine.Engine.GetGameTime()
    if time_left < 0 then
        self.timer:SetText("")
    elseif time_left < 10 then
        self.timer:SetText(lui_format_icon_timeout(time_left))
    else
        self.timer:SetText("")
    end
end
