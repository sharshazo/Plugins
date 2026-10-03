-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Utils.callbacks"
local TR = _G.LUI.Locale.TR
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.Vitals.vitals_base"
import "LUI.src.Vitals.target_effect_manager"

local function _companion_vitals_enabled()
    return State.loaded_settings.companion.enabled == true
end

---@class CompanionVitals : VitalsBase
local CompanionVitals = class(Vitals.VitalsBase)
Vitals.CompanionVitals = CompanionVitals

function CompanionVitals:Constructor(player)
    self.player = player
    self.pet_changed_event = nil
    self.em = nil
    self.em_added_event = nil
    self.em_removed_event = nil

    Vitals.VitalsBase.Constructor(self, "companion", nil, TR["Companion Vitals"])

    self:_attach_pet_changed()
    self:update_pet()
end

function CompanionVitals:destroy()
    self:_detach_pet_changed()
    self:set_entity(nil)
    self:SetVisible(false)
    self.player = nil
end

function CompanionVitals:set_entity(entity)
    if self.em ~= nil and self.entity ~= entity then
        self:_detach_effect_manager()
    end

    Vitals.VitalsBase.set_entity(self, entity)

    if entity == nil and self.em ~= nil then
        self:_detach_effect_manager()
    end

    self:apply_enabled_state()
end

function CompanionVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end

    if self.show_effects == true then
        local now = Turbine.Engine.GetGameTime()
        local expired = nil
        for key, ending in pairs(self.effects_ending_at) do
            if type(ending) == "number" and now >= ending then
                local eff = self.effects_objects[key]
                if eff ~= nil then
                    expired = expired or {}
                    expired[#expired + 1] = eff
                end
            end
        end
        if expired ~= nil then
            for i = 1, #expired do
                self:_remove_effect(expired[i])
            end
        end
    end

    Vitals.VitalsBase.Update(self)
end

function CompanionVitals:get_empty_morale_text()
    return "No Companion"
end

function CompanionVitals:apply_enabled_state()
    self:SetVisible(_companion_vitals_enabled() == true and (self.entity ~= nil or self:is_move_mode()))
end

function CompanionVitals:update_pet()
    if _companion_vitals_enabled() ~= true then
        self:set_entity(nil)
        self:apply_enabled_state()
        return
    end

    self:set_entity(self:_current_pet())
    self:apply_enabled_state()
end

function CompanionVitals:set_move_mode(enabled)
    Vitals.VitalsBase.set_move_mode(self, enabled)
    self:apply_enabled_state()
end

function CompanionVitals:_current_pet()
    if self.player == nil or self.player.GetPet == nil then
        return nil
    end
    return self.player:GetPet()
end

function CompanionVitals:_attach_pet_changed()
    if self.player == nil then
        return
    end

    self.pet_changed_event = add_callback(self.player, "PetChanged", function()
        self:update_pet()
    end)
end

function CompanionVitals:_detach_pet_changed()
    if self.pet_changed_event == nil then
        return
    end

    remove_callback(self.player, "PetChanged", self.pet_changed_event)
    self.pet_changed_event = nil
end

function CompanionVitals:_setup_effect_tracking()
    if self.show_effects ~= true then
        return
    end

    if self.em ~= nil then
        self:_detach_effect_manager()
    end

    self.debuffs:clear_effects()
    self.buffs:clear_effects()

    self.effects_list = nil
    self.effects_resync_due_at = nil
    self.effects_resync_attempts = 0
    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}

    if self.entity == nil or self.entity.GetEffects == nil then
        self:SetWantsUpdates(false)
        return
    end

    -- Silent acquisition keeps the pet as the background source while selected-target vitals can share the cache.
    self.em = Vitals.TargetEffectManager.acquire_silent(Turbine.Gameplay.LocalPlayer.GetInstance(), self.entity)
    self.em_added_event = self.em:register_added_event(function(effect)
        self:_upsert_effect(effect)
    end)
    self.em_removed_event = self.em:register_removed_event(function(effect)
        self:_remove_effect(effect)
        self:_request_effects_resync(0.05, 6)
    end)

    self:SetWantsUpdates(true)
end

function CompanionVitals:_detach_effect_manager()
    if self.em == nil then
        self.em_added_event = nil
        self.em_removed_event = nil
        return
    end

    if self.em_added_event ~= nil then
        self.em:unregister_added_event(self.em_added_event)
        self.em_added_event = nil
    end
    if self.em_removed_event ~= nil then
        self.em:unregister_removed_event(self.em_removed_event)
        self.em_removed_event = nil
    end

    self.em:delete()
    self.em = nil
end
