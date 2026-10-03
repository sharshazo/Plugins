-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Vitals = _G.LUI.Features.Vitals
local LUI_ENUMS = _G.LUI.Settings.Enums
local class = _G.LUI.Core.class
import "Turbine.UI.Lotro"

import "LUI.src.Vitals.effects_area"

local CURABILITY_UNKNOWN = 0
local CURABILITY_CURABLE = 1
local CURABILITY_NONCURABLE = 2

local function _curability_state(effect)
    if effect == nil or effect.IsCurable == nil then
        return CURABILITY_UNKNOWN
    end

    local is_curable = effect:IsCurable()
    if is_curable == true then
        return CURABILITY_CURABLE
    end
    if is_curable == false then
        return CURABILITY_NONCURABLE
    end

    return CURABILITY_UNKNOWN
end

local function _show_unknown_curability(settings)
    if settings == nil or settings.debuffs == nil then
        return false
    end

    -- Treat unknown curability as its own state. Only show it when both known
    -- debuff kinds are enabled, so a transient nil/unknown value does not leak
    -- into curable-only or non-curable-only views.
    return settings.debuffs.track_curable == true
        and settings.debuffs.track_noncurable == true
end

---@class DebuffArea : EffectsArea
local DebuffArea = class(Vitals.EffectsArea)
Vitals.DebuffArea = DebuffArea

function DebuffArea:Constructor(frame_width, effects_settings, effects_height)
    Vitals.EffectsArea.Constructor(self, frame_width, effects_settings, effects_height)
end

function DebuffArea:_settings_group()
    return "debuffs"
end

function DebuffArea:_default_icon_size()
    return 36
end

function DebuffArea:_default_timer_font()
    return {
        name = LUI_ENUMS.font_name.VERDANA,
        size = 25,
        lotro = Turbine.UI.Lotro.Font.Verdana23,
        style = LUI_ENUMS.font_style.OUTLINE,
    }
end

function DebuffArea:_should_track_effect(effect)
    if self.effects_settings == nil or self.effects_settings.debuffs == nil then
        return false
    end

    local curability = _curability_state(effect)
    if curability == CURABILITY_CURABLE then
        return self.effects_settings.debuffs.track_curable == true
    end
    if curability == CURABILITY_NONCURABLE then
        return self.effects_settings.debuffs.track_noncurable == true
    end
    return _show_unknown_curability(self.effects_settings)
end
