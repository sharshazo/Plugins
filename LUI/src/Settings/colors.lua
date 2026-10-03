-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.UI"

local Settings = _G.LUI.Settings
local State = Settings.State
local Colors = Settings.Colors or {}
Settings.Colors = Colors

function Colors.fix_colors()
    local s = State.loaded_settings

    local function to_color(value)
        if type(value) == "table" and value["R"] ~= nil then
            local a = value["A"]
            if a == nil then a = 1 end
            return Turbine.UI.Color(a, value["R"], value["G"], value["B"])
        end
        return value
    end

    local self_expiring_effects = s.self ~= nil and s.self.expiring_effects or nil
    local expiring_target_effects = s.target ~= nil and s.target.expiring_effects or nil

    local function fix_vital(v)
        v.frame.border_color = to_color(v.frame.border_color)

        local morale = v.morale
        local power = v.power
        local labels = v.labels
        local effects = v.effects

        morale.color.high = to_color(morale.color.high)
        morale.color.medium = to_color(morale.color.medium)
        morale.color.low = to_color(morale.color.low)
        morale.color.critical = to_color(morale.color.critical)
        morale.color.neutral = to_color(morale.color.neutral)
        morale.color.gradient_full = to_color(morale.color.gradient_full)
        morale.color.gradient_mid = to_color(morale.color.gradient_mid)
        morale.color.gradient_low = to_color(morale.color.gradient_low)

        morale.color.background = to_color(morale.color.background)
        morale.color.bubble = to_color(morale.color.bubble)

        power.color.power = to_color(power.color.power)
        power.color.wrath = to_color(power.color.wrath)
        v.info.color.background = to_color(v.info.color.background)

        for i = 1, #labels do
            local label = labels[i]
            label.font.color = to_color(label.font.color)
            label.font.outline_color = to_color(label.font.outline_color)
        end

        effects.buffs.timer_font.color = to_color(effects.buffs.timer_font.color)
        effects.buffs.timer_font.outline_color = to_color(effects.buffs.timer_font.outline_color)

        effects.debuffs.timer_font.color = to_color(effects.debuffs.timer_font.color)
        effects.debuffs.timer_font.outline_color = to_color(effects.debuffs.timer_font.outline_color)
    end

    fix_vital(s.self.vitals)
    fix_vital(s.target.vitals)
    fix_vital(s.target.boss_vitals)
    fix_vital(s.companion)
    fix_vital(s.fellowship)
    fix_vital(s.raid)

    for key, value in pairs(s.global.style) do
        s.global.style[key] = to_color(value)
    end

    if s.target ~= nil and s.target.vitals ~= nil and s.target.vitals.targets_target ~= nil then
        local tt = s.target.vitals.targets_target

        if tt.labels ~= nil then
            for i = 1, #tt.labels do
                local label = tt.labels[i]
                label.font.color = to_color(label.font.color)
                label.font.outline_color = to_color(label.font.outline_color)
            end
        end

        local c = tt.color
        c.background = to_color(c.background)
        c.border = to_color(c.border)
        c.bubble = to_color(c.bubble)
        c.neutral = to_color(c.neutral)
        c.high = to_color(c.high)
        c.medium = to_color(c.medium)
        c.low = to_color(c.low)
        c.critical = to_color(c.critical)
        c.gradient_full = to_color(c.gradient_full)
        c.gradient_mid = to_color(c.gradient_mid)
        c.gradient_low = to_color(c.gradient_low)
    end

    if self_expiring_effects ~= nil then
        self_expiring_effects.color.bar_buff = to_color(self_expiring_effects.color.bar_buff)
        self_expiring_effects.color.bar_debuff_curable = to_color(self_expiring_effects.color.bar_debuff_curable)
        self_expiring_effects.color.bar_debuff_noncurable = to_color(self_expiring_effects.color.bar_debuff_noncurable)
        self_expiring_effects.color.background = to_color(self_expiring_effects.color.background)
        self_expiring_effects.color.border = to_color(self_expiring_effects.color.border)
        self_expiring_effects.font.color = to_color(self_expiring_effects.font.color)
        self_expiring_effects.font.outline_color = to_color(self_expiring_effects.font.outline_color)
    end

    if expiring_target_effects ~= nil then
        expiring_target_effects.color.bar_buff = to_color(expiring_target_effects.color.bar_buff)
        expiring_target_effects.color.bar_debuff_curable = to_color(expiring_target_effects.color.bar_debuff_curable)
        expiring_target_effects.color.bar_debuff_noncurable = to_color(expiring_target_effects.color
            .bar_debuff_noncurable)
        expiring_target_effects.color.background = to_color(expiring_target_effects.color.background)
        expiring_target_effects.color.border = to_color(expiring_target_effects.color.border)
        expiring_target_effects.font.color = to_color(expiring_target_effects.font.color)
        expiring_target_effects.font.outline_color = to_color(expiring_target_effects.font.outline_color)
    end

    local sb = s.status_bar
    if sb ~= nil then
        if sb.bg ~= nil then
            sb.bg.color = to_color(sb.bg.color)
        end
        if sb.font ~= nil then
            sb.font.color = to_color(sb.font.color)
            sb.font.outline_color = to_color(sb.font.outline_color)
        end
        if sb.widgets ~= nil and sb.widgets.inventory_space ~= nil and sb.widgets.inventory_space.color ~= nil then
            local c = sb.widgets.inventory_space.color
            c.yellow = to_color(c.yellow)
            c.orange = to_color(c.orange)
            c.red = to_color(c.red)
        end
        if sb.widgets ~= nil and sb.widgets.equipment_wear ~= nil and sb.widgets.equipment_wear.color ~= nil then
            local c = sb.widgets.equipment_wear.color
            c.green = to_color(c.green)
            c.yellow = to_color(c.yellow)
            c.red = to_color(c.red)
        end
    end

    local cd = s.self.cooldowns
    if cd ~= nil then
        if cd.color ~= nil then
            cd.color.background = to_color(cd.color.background)
            cd.color.bar = to_color(cd.color.bar)
            cd.color.border = to_color(cd.color.border)
        end
        if cd.font ~= nil then
            cd.font.color = to_color(cd.font.color)
            cd.font.outline_color = to_color(cd.font.outline_color)
        end
    end

    local uk = s.self.upkeep
    if uk ~= nil then
        uk.drain_color = to_color(uk.drain_color)
        uk.cd_shade_color = to_color(uk.cd_shade_color)
        uk.active_text_color = to_color(uk.active_text_color)
        uk.cooldown_text_color = to_color(uk.cooldown_text_color)
        if uk.font ~= nil then
            uk.font.outline_color = to_color(uk.font.outline_color)
        end
    end
end
