-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local Vitals = _G.LUI.Features.Vitals
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "Turbine.Gameplay"

import "LUI.src.Vitals.vitals_base"
import "LUI.src.Vitals.target_effect_manager"
import "LUI.src.Settings.enums"

local function _boss_stack_height(sections, border_width)
    local total = 0
    local visible = 0

    for i = 1, #sections do
        local height = sections[i]
        if type(height) == "number" and height > 0 then
            total = total + height
            visible = visible + 1
        end
    end

    if visible > 1 then
        total = total - ((visible - 1) * border_width)
    end

    if total < 1 then
        total = 1
    end

    return total
end

---@class BossVitals : VitalsBase
local BossVitals = class(Vitals.VitalsBase)
Vitals.BossVitals = BossVitals

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function BossVitals:Constructor(entity)
    self.em = nil
    self.em_added_event = nil
    self.em_removed_event = nil
    self._layout_busy = false
    self._power_fill_width = 0

    Vitals.VitalsBase.Constructor(self, "boss", entity, TR["Boss Vitals"])

    if self.buffs ~= nil then
        self.buffs.on_height_changed = function()
            self:_layout_effect_windows()
        end
    end
    if self.debuffs ~= nil then
        self.debuffs:set_dynamic_height(true)
        self.debuffs.on_height_changed = function()
            self:_layout_effect_windows()
        end
    end

    self:resize()
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function BossVitals:get_vitals_settings()
    return State.settings.target.boss_vitals
end

function BossVitals:get_loaded_vitals_settings()
    return State.loaded_settings.target.boss_vitals
end

function BossVitals:set_entity(entity)
    if self.em ~= nil and self.entity ~= entity then
        self:_detach_effect_manager()
    end

    Vitals.VitalsBase.set_entity(self, entity)

    if entity == nil and self.em ~= nil then
        self:_detach_effect_manager()
    end

    if entity == nil then
        self.power_bar:SetWidth(self._power_fill_width or 0)
    end
end

function BossVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end

    if self.show_effects == true and self.effects_ending_at ~= nil and self.effects_objects ~= nil then
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

function BossVitals:get_lower_bars_height()
    local v = self:get_vitals_settings()
    if v.power.hide == true then
        return 0
    end
    return v.power.height
end

function BossVitals:effects_are_below()
    return true
end

function BossVitals:get_empty_morale_text()
    return "No Target"
end

function BossVitals:use_stacked_effects_layout()
    local raw = self:get_loaded_vitals_settings()
    if raw == nil or raw.power.hide == true then
        return false
    end

    local raw_frame_width = raw.frame.width or 0
    local raw_power_width = raw.power.width or 0
    return raw_frame_width < 400 or raw_power_width > (raw_frame_width / 2)
end

function BossVitals:apply_text_alignment()
    Vitals.VitalsBase.apply_text_alignment(self)
    if self:get_vitals_settings().power.hide == true then
        self:_clear_labels(3, 4)
    end
end

function BossVitals:set_move_mode(enabled)
    Vitals.VitalsBase.set_move_mode(self, enabled)
    self:_layout_effect_windows()
    if State.loaded_settings.target.vitals.enabled ~= true then
        self:SetVisible(false)
    elseif self:get_loaded_vitals_settings().enabled ~= true then
        self:SetVisible(false)
    elseif enabled == true then
        self:SetVisible(true)
    elseif self.entity == nil then
        self:SetVisible(false)
    end
end

function BossVitals:self_power_changed()
    local v = self:get_vitals_settings()
    if v.power.hide == true then
        self.power_frame:SetVisible(false)
        self.power_border:SetVisible(false)
        self:_clear_labels(3, 4)
        self.power_bar:SetWidth(0)
        return
    end
    if self.entity == nil or self.entity.GetMaxPower == nil or self.entity.GetPower == nil then
        return
    end
    if self._no_morale == true then
        if self.power_border ~= nil then
            self.power_border:SetVisible(false)
        end
        self:_clear_labels(3, 4)
        if self.power_bar ~= nil then
            self.power_bar:SetWidth(0)
        end
        return
    end
    local maxp = self.entity:GetMaxPower() or 0
    local p = self.entity:GetPower() or 0
    local is_wrath = self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning
    local fill_width = self._power_fill_width or 0

    if maxp > 0 then
        self.power_border:SetVisible(true)
        local percent = p / maxp
        self:_render_configurable_labels(self:_build_vitals_label_context())

        self.power_bar:SetWidth(math.floor((fill_width * percent) + 0.5))
        local fill_color = is_wrath and v.power.color.wrath or v.power.color.power
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    else
        self.power_border:SetVisible(true)
        self:_render_configurable_labels(self:_build_vitals_label_context())
        self.power_bar:SetWidth(fill_width)
        local fill_color = is_wrath and v.power.color.wrath or v.power.color.power
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    end
end

function BossVitals:self_wrath_changed()
    local v = self:get_vitals_settings()
    if v.power.hide == true then
        self.power_frame:SetVisible(false)
        self.power_border:SetVisible(false)
        self:_clear_labels(3, 4)
        self.power_bar:SetWidth(0)
        return
    end
    if self.entity == nil or self.entity.GetClassAttributes == nil or self.entity:GetClassAttributes().GetWrath == nil then
        return
    end

    local maxw = 100
    local w = self.entity:GetClassAttributes():GetWrath()
    local percent = w / maxw
    self:_render_configurable_labels(self:_build_vitals_label_context())

    self.power_bar:SetWidth(math.floor((self._power_fill_width * percent) + 0.5))
    self.power_bar:SetBackColor(v.power.color.wrath)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.wrath))
end

function BossVitals:resize()
    self:apply_native_scaling()

    local v = self:get_vitals_settings()
    local frame = v.frame
    local frame_width = frame.width
    local border = frame.border_width
    local morale_h = v.morale.height
    local power_hidden = v.power.hide == true
    local power_h = power_hidden == true and 0 or v.power.height
    local info_height = self:get_info_height()
    local effects_h = self.show_effects == true and frame.effects_height or 0

    self.width = frame_width - (2 * border)
    if self.width < 1 then self.width = 1 end

    local core_height = _boss_stack_height({ morale_h, power_h, info_height }, border)
    local total_h = effects_h + core_height
    if total_h < 1 then total_h = 1 end

    self:SetSize(frame_width, total_h)
    self:layout_move_chrome()
    if not self.managed_position then
        self:apply_hud_position()
    end

    self.morale_frame:SetPosition(0, 0)
    self.morale_frame:SetSize(frame_width, morale_h)
    self.morale_border:SetSize(frame_width, morale_h)
    self.morale_border:SetBackColor(frame.border_color)

    local morale_inner_h = morale_h - (2 * border)
    if morale_inner_h < 1 then morale_inner_h = 1 end
    self.morale_background:SetPosition(border, border)
    self.morale_background:SetSize(self.width, morale_inner_h)
    self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.neutral))
    self.morale_bar:SetPosition(0, 0)
    self.morale_bar:SetHeight(morale_inner_h)
    self.bubble_bar:SetPosition(0, 0)
    self.bubble_bar:SetHeight(morale_inner_h)
    self.bubble_bar:SetBackColor(v.morale.color.bubble)

    local power_width = power_hidden == true and 0 or v.power.width
    if power_width < 0 then power_width = 0 end
    if power_width > frame_width then
        power_width = frame_width
    end

    self._power_frame_width = power_width
    self._effects_height = effects_h

    self.power_frame:SetSize(power_width, v.power.height)
    self.power_frame:SetVisible(power_hidden ~= true)
    self.power_border:SetVisible(power_hidden ~= true)
    self.power_border:SetSize(power_width, v.power.height)
    self.power_border:SetBackColor(frame.border_color)

    local power_inner_w = power_width - (2 * border)
    local power_inner_h = v.power.height - (2 * border)
    if power_inner_w < 1 then power_inner_w = 1 end
    if power_inner_h < 1 then power_inner_h = 1 end
    self._power_fill_width = power_inner_w

    self.power_background:SetPosition(border, border)
    self.power_background:SetSize(power_inner_w, power_inner_h)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.power))
    self.power_bar:SetPosition(0, 0)
    self.power_bar:SetHeight(power_inner_h)

    self.info_frame:SetSize(frame_width, info_height)
    self.info_frame:SetVisible(info_height > 0)
    self.info_border:SetSize(frame_width, info_height)
    self.info_border:SetBackColor(frame.border_color)

    local info_inner_h = info_height - (2 * border)
    if info_inner_h < 1 then info_inner_h = 1 end
    self.info_background:SetPosition(border, border)
    self.info_background:SetSize(self.width, info_inner_h)
    self.info_background:SetBackColor(lui_apply_opacity_to_color(v.info.color.background, v.info.opacity))

    local top_height = self:_layout_effect_windows() or 0

    local morale_top = top_height
    self.morale_frame:SetTop(morale_top)

    local next_top = morale_top + morale_h - border
    if power_hidden == true then
        self.power_frame:SetVisible(false)
        self.power_border:SetVisible(false)
        self:_clear_labels(3, 4)
        self.power_bar:SetWidth(0)
    else
        local power_left = 0
        if v.power.side == LUI_ENUMS.side.RIGHT then
            power_left = frame_width - power_width
        end

        self.power_frame:SetVisible(true)
        self.power_frame:SetPosition(power_left, next_top)
        self.power_frame:SetSize(power_width, v.power.height)
        self.power_border:SetVisible(true)
        self.power_border:SetSize(power_width, v.power.height)
        next_top = next_top + v.power.height - border
    end

    self.info_frame:SetTop(next_top)
    local bottom_start = next_top
    if info_height > 0 then
        bottom_start = next_top + info_height - border
    end

    self.entity_control:SetPosition(0, morale_top)
    self.entity_control:SetSize(frame_width, core_height)

    self:_apply_configurable_label_layout()
    self:_layout_effect_windows(bottom_start)
    self:_resize_extra_controls()
    self:apply_fonts()
    self:apply_text_alignment()
    self:update()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function BossVitals:_build_extra_controls()
    self.effects_top_border = Turbine.UI.Control()
    self.effects_top_border:SetParent(self)
    self.effects_top_border:SetMouseVisible(false)
    self.effects_top_border:SetVisible(false)
    self.effects_top_border:SetZOrder(3)
end

function BossVitals:_setup_effect_tracking()
    if self.show_effects ~= true then
        return
    end

    if self.em ~= nil then
        self:_detach_effect_manager()
    end

    if self.debuffs ~= nil then self.debuffs:clear_effects() end
    if self.buffs ~= nil then self.buffs:clear_effects() end

    self.effects_list = nil
    self.effects_resync_due_at = nil
    self.effects_resync_attempts = 0
    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}

    if self.entity == nil or self.entity.GetEffects == nil or self.entity:GetEffects() == nil then
        self:SetWantsUpdates(false)
        return
    end

    self.em = Vitals.TargetEffectManager.acquire(Turbine.Gameplay.LocalPlayer.GetInstance(), self.entity)
    self.em_added_event = self.em:register_added_event(function(effect)
        self:_upsert_effect(effect)
    end)
    self.em_removed_event = self.em:register_removed_event(function(effect)
        self:_remove_effect(effect)
        self:_request_effects_resync(0.05, 6)
    end)

    self:SetWantsUpdates(true)
end

function BossVitals:_detach_effect_manager()
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

function BossVitals:_layout_effect_windows(bottom_start_override)
    if self._layout_busy == true then
        return
    end
    self._layout_busy = true

    local v = self:get_vitals_settings()
    local layout = v.effects.layout
    local bottom_start = bottom_start_override
    if type(bottom_start) ~= "number" then
        if self.info_frame:IsVisible() == true then
            bottom_start = self.info_frame:GetTop() + self.info_frame:GetHeight() - v.frame.border_width
        elseif self.power_frame:IsVisible() == true then
            bottom_start = self.power_frame:GetTop() + self.power_frame:GetHeight() - v.frame.border_width
        else
            bottom_start = self.morale_frame:GetTop() + self.morale_frame:GetHeight() - v.frame.border_width
        end
    end

    if self.show_effects ~= true or self.buffs == nil or self.debuffs == nil then
        if self.effects_top_border ~= nil then
            self.effects_top_border:SetVisible(false)
        end
        self._layout_busy = false
        return 0
    end

    self.buffs:set_max_height(layout.buffs_reserved_height)
    self.debuffs:set_max_height(layout.debuffs_reserved_height)

    self.buffs:set_reverse_fill(layout.buffs_reverse_fill)
    self.buffs:set_horizontal_alignment(v.effects.buffs.alignment)
    self.debuffs:set_reverse_fill(layout.debuffs_reverse_fill)
    self.debuffs:set_horizontal_alignment(v.effects.debuffs.alignment)

    self:_layout_top_effect_entries(layout.top, layout.top_reserved_height)
    self:_layout_bottom_effect_entries(layout.bottom, bottom_start)

    if self.effects_top_border ~= nil then
        self.effects_top_border:SetVisible(false)
    end

    self._layout_busy = false
    return layout.top_reserved_height
end
