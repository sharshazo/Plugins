-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local is_boss_target = _G.LUI.Utils.is_boss_target
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.Vitals.vitals_base"

local function _self_vitals_enabled()
    return State.loaded_settings.self.vitals.enabled == true
end

---@class SelfVitals : VitalsBase
local SelfVitals = class(Vitals.VitalsBase)
Vitals.SelfVitals = SelfVitals

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function SelfVitals:Constructor(entity)
    self.target_vitals = nil
    self.boss_vitals = nil
    Vitals.VitalsBase.Constructor(self, "self", entity, TR["Self Vitals"])
    self:apply_enabled_state()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function SelfVitals:set_target_vitals(target_vitals, boss_vitals)
    self.target_vitals = target_vitals
    self.boss_vitals = boss_vitals
    -- Sync initial target state (plugin can load while a target is already selected).
    self:on_target_changed()
end

function SelfVitals:apply_enabled_state()
    self:SetVisible(_self_vitals_enabled())
end

function SelfVitals:on_target_changed()
    if self.target_vitals == nil and self.boss_vitals == nil then
        return
    end

    local target_vitals_enabled = State.loaded_settings.target.vitals.enabled == true
    local boss_vitals_enabled = target_vitals_enabled == true and State.loaded_settings.target.boss_vitals.enabled == true

    if self.entity == nil or self.entity.GetTarget == nil then
        if self.target_vitals ~= nil then
            self.target_vitals:set_entity(nil)
            self.target_vitals:SetVisible(target_vitals_enabled == true and self.target_vitals:is_move_mode())
        end
        if self.boss_vitals ~= nil then
            self.boss_vitals:set_entity(nil)
            self.boss_vitals:SetVisible(boss_vitals_enabled == true and self.boss_vitals:is_move_mode())
        end
        return
    end

    local t = self.entity:GetTarget()
    local is_boss = boss_vitals_enabled == true and
        t ~= nil and
        is_boss_target ~= nil and
        is_boss_target(t, self.entity) == true

    if self.target_vitals ~= nil then
        self.target_vitals:set_entity(t)
        if target_vitals_enabled ~= true then
            self.target_vitals:SetVisible(false)
        elseif t ~= nil and is_boss ~= true then
            self.target_vitals:SetVisible(true)
        else
            self.target_vitals:SetVisible(self.target_vitals:is_move_mode())
        end
    end

    if self.boss_vitals ~= nil then
        self.boss_vitals:set_entity(is_boss == true and t or nil)
        if is_boss == true then
            self.boss_vitals:SetVisible(true)
        else
            self.boss_vitals:SetVisible(boss_vitals_enabled == true and self.boss_vitals:is_move_mode())
        end
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function SelfVitals:_setup_effect_tracking()
    self:_setup_effect_tracking_default()
end
