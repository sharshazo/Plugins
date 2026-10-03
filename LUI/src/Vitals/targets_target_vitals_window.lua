-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.color"

local TargetsTargetVitalsWindow = class(UI.Widgets.LuiHUD)
Vitals.TargetsTargetVitalsWindow = TargetsTargetVitalsWindow

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetsTargetVitalsWindow:Constructor(owner)
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "target_target_vitals",
        title = TR["Target's Target"],
    })

    self.owner = owner

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    self.targets_target_border = Turbine.UI.Control()
    self.targets_target_border:SetParent(self)
    self.targets_target_border:SetMouseVisible(false)
    self.targets_target_border:SetZOrder(2)

    self.targets_target_background = Turbine.UI.Control()
    self.targets_target_background:SetParent(self.targets_target_border)
    self.targets_target_background:SetMouseVisible(false)

    self.targets_target_morale = Turbine.UI.Control()
    self.targets_target_morale:SetParent(self.targets_target_background)
    self.targets_target_morale:SetMouseVisible(false)
    self.targets_target_morale:SetZOrder(2)

    self.targets_target_bubble = Turbine.UI.Control()
    self.targets_target_bubble:SetParent(self.targets_target_background)
    self.targets_target_bubble:SetMouseVisible(false)
    self.targets_target_bubble:SetZOrder(3)
    self.targets_target_bubble:SetVisible(false)

    self.targets_target_labels = {}
    for i = 1, 2 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(self.targets_target_border)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(49 + i)
        self.targets_target_labels[i] = label
    end

    self.targets_control = Turbine.UI.Lotro.EntityControl()
    self.targets_control:SetParent(self)
    self.targets_control:SetMouseVisible(true)
    self.targets_control:SetEntity(nil)
    -- z-order LOWER than targets_target_border(2) on purpose: see the
    -- matching comment in Vitals/vitals_base.lua's entity_control -- this is
    -- the same "native EntityControl chrome paints over our custom frame"
    -- bug, just in the target's-target mini-frame instead.
    self.targets_control:SetZOrder(0)

    self:apply_settings()
    self:SetVisible(false)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetsTargetVitalsWindow:set_move_mode(enabled)
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    if State.loaded_settings.target.vitals.targets_target.enabled == true and enabled == true then
        self:SetVisible(true)
    elseif State.loaded_settings.target.vitals.targets_target.enabled ~= true then
        self:SetVisible(false)
    end
end

function TargetsTargetVitalsWindow:apply_settings()
    self:apply_native_scaling()

    local v = State.settings.target.vitals
    local tt = v.targets_target

    local border = tt.border_width
    local frame_w = tt.width
    local h = tt.height

    self:SetSize(frame_w, h)
    self:layout_move_chrome()

    self.targets_target_border:SetSize(frame_w, h)
    self.targets_target_border:SetBackColor(tt.color.border)

    local inner_w = frame_w - (2 * border)
    local inner_h = h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    self.targets_target_background:SetPosition(border, border)
    self.targets_target_background:SetSize(inner_w, inner_h)
    self.targets_target_background:SetBackColor(lui_apply_opacity_to_color(
        tt.color.background,
        tt.background_opacity
    ))

    self.targets_target_morale:SetPosition(0, 0)
    self.targets_target_morale:SetSize(inner_w, inner_h)

    self.targets_target_bubble:SetBackColor(tt.color.bubble)
    self.targets_target_bubble:SetTop(0)
    self.targets_target_bubble:SetHeight(inner_h)

    self.targets_control:SetSize(frame_w, h)
    self.targets_control:SetPosition(0, 0)

    self:apply_hud_position()
end
