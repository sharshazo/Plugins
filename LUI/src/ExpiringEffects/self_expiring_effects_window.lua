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
import "LUI.src.ExpiringEffects.self_expiring_effect_entry"

local SelfExpiringEffectsWindow = class(ExpiringEffects.ExpiringEffectsWindow)
ExpiringEffects.SelfExpiringEffectsWindow = SelfExpiringEffectsWindow

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function SelfExpiringEffectsWindow:Constructor()
    ExpiringEffects.ExpiringEffectsWindow.Constructor(self, { title = TR["Expiring Effects (Self)"] })
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function SelfExpiringEffectsWindow:get_settings()
    return State.settings.self.expiring_effects
end

function SelfExpiringEffectsWindow:get_hud_key()
    return "self_effects"
end

function SelfExpiringEffectsWindow:get_entry_class()
    return ExpiringEffects.SelfExpiringEffectEntry
end

function SelfExpiringEffectsWindow:get_effect_objects()
    local list = Turbine.Gameplay.LocalPlayer.GetInstance():GetEffects()
    if list == nil or list.GetCount == nil then
        return {}
    end

    local out = {}
    local count = list:GetCount() or 0
    for i = 1, count do
        local effect = list:Get(i)
        if effect ~= nil then
            table.insert(out, effect)
        end
    end

    return out
end
