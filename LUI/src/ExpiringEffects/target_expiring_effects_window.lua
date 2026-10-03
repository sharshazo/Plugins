-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local ExpiringEffects = _G.LUI.Features.ExpiringEffects
local State = _G.LUI.Settings.State
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.ExpiringEffects.expiring_effects_window"
import "LUI.src.ExpiringEffects.target_expiring_effect_entry"

local TargetExpiringEffectsWindow = class(ExpiringEffects.ExpiringEffectsWindow)
ExpiringEffects.TargetExpiringEffectsWindow = TargetExpiringEffectsWindow

local function _target_is_local_player()
    if _G.LUI.Runtime.Windows.target_vital == nil or _G.LUI.Runtime.Windows.target_vital.entity == nil then
        return false
    end

    local entity = _G.LUI.Runtime.Windows.target_vital.entity
    local lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    if lp == nil or entity.GetName == nil or lp.GetName == nil then
        return false
    end

    return entity:GetName() == lp:GetName()
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:Constructor()
    ExpiringEffects.ExpiringEffectsWindow.Constructor(self, { title = TR["Expiring Effects (Target)"] })
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:get_settings()
    return State.settings.target.expiring_effects
end

function TargetExpiringEffectsWindow:get_hud_key()
    return "target_effects"
end

function TargetExpiringEffectsWindow:get_entry_class()
    return ExpiringEffects.TargetExpiringEffectEntry
end

function TargetExpiringEffectsWindow:get_effect_objects()
    if _G.LUI.Runtime.Windows.target_vital == nil then
        return {}
    end

    local out = {}
    if _target_is_local_player() == true then
        local list = Turbine.Gameplay.LocalPlayer.GetInstance():GetEffects()
        if list == nil or list.GetCount == nil then
            return {}
        end

        local count = list:GetCount() or 0
        for i = 1, count do
            local effect = list:Get(i)
            if effect ~= nil then
                table.insert(out, effect)
            end
        end
    else
        local em = _G.LUI.Runtime.Windows.target_vital.em
        if em == nil then
            return {}
        end

        for _, o in pairs(em.effects) do
            if o ~= nil then
                table.insert(out, o.effect)
            end
        end
    end
    return out
end
