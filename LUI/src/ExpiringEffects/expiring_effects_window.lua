-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local ExpiringEffects = _G.LUI.Features.ExpiringEffects
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Settings.enums"
import "LUI.src.Utils.timed_row_layout"
import "LUI.src.UI.Widgets.hud"

local CURABILITY_UNKNOWN = 0
local CURABILITY_CURABLE = 1
local CURABILITY_NONCURABLE = 2

local function _is_valid_start(start, now)
    if type(start) ~= "number" then
        return false
    end
    if start <= 0 then
        return false
    end
    if type(now) ~= "number" or now <= 0 then
        return true
    end
    -- Allow small clock skew; reject wildly old/new values.
    if start > (now + 5) then
        return false
    end
    if start < (now - 7200) then
        return false
    end
    return true
end

local ExpiringEffectsWindow = class(UI.Widgets.LuiHUD)
ExpiringEffects.ExpiringEffectsWindow = ExpiringEffectsWindow

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

local function _show_unknown_curability(show_curable, show_noncurable)
    -- Treat unknown curability as its own state. Only show it when both known
    -- debuff kinds are enabled, so a transient nil/unknown value does not leak
    -- into curable-only or non-curable-only views.
    return show_curable == true and show_noncurable == true
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function ExpiringEffectsWindow:Constructor(opts)
    if type(opts) ~= "table" then
        opts = {}
    end

    self._opts = opts
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = self:get_hud_key(),
        title = self:get_move_title(),
    })

    self.slots = {}
    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate
    self._effect_start = {}
    self._effect_seen_at = {}

    self:SetWantsUpdates(true)
    self:SetVisible(false)
    self:SetMouseVisible(false)

    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function ExpiringEffectsWindow:clear_effect_time_cache()
    self._effect_start = {}
    self._effect_seen_at = {}
end

function ExpiringEffectsWindow:get_effect_key(effect)
    if effect == nil then
        return 0
    end
    local id = effect:GetID()
    if type(id) ~= "number" then
        id = tonumber(id) or 0
    end
    return id
end

function ExpiringEffectsWindow:get_settings()
    return nil
end

function ExpiringEffectsWindow:get_hud_key()
    return nil
end

function ExpiringEffectsWindow:get_entry_class()
    return nil
end

function ExpiringEffectsWindow:get_move_title()
    local o = self._opts
    return (type(o.title) == "string" and o.title) or TR["Expiring Effects"]
end

function ExpiringEffectsWindow:set_move_mode(enabled)
    local changed = (enabled == true) ~= self:is_move_mode()
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    if changed and enabled == true then
        self:_hide_slots()
    elseif changed then
        self.last_update_at = -(self.update_every or 0)
        self:Update()
    end
    self:refresh_visibility()
end

function ExpiringEffectsWindow:apply_settings()
    self:apply_native_scaling()

    local s = self:get_settings()
    local cols = s.columns
    local rows = s.rows
    local spacing = s.spacing

    -- Entry footprint resolved once per Settings.rebuild(); see
    -- rebuild_settings.lua.
    local entry_width = s.resolved.entry_width
    local entry_height = s.resolved.entry_height

    local width = (cols * entry_width) + ((cols - 1) * spacing)
    local height = (rows * entry_height) + ((rows - 1) * spacing)
    self:SetSize(width, height)
    self:layout_move_chrome()

    self:apply_hud_position()

    local entry_class = self:get_entry_class()
    if entry_class == nil then
        return
    end

    local capacity = cols * rows
    for i = 1, capacity do
        if self.slots[i] == nil then
            local entry = entry_class()
            entry:SetParent(self)
            entry:SetVisible(false)
            entry:SetZOrder(10)
            entry:apply_settings()
            self.slots[i] = entry
        else
            self.slots[i]:apply_settings()
        end

        local x, y = self:get_slot_position(i, cols, rows, entry_width, entry_height, spacing)
        self.slots[i]:SetPosition(x, y)
    end

    for i = capacity + 1, #self.slots do
        if self.slots[i] ~= nil then
            self.slots[i]:SetVisible(false)
        end
    end

    self:refresh_visibility()
end

function ExpiringEffectsWindow:get_slot_position(slot_index, cols, rows, entry_width, entry_height, spacing)
    local zero = slot_index - 1
    local row_from_bottom = math.floor(zero / cols)
    local col_from_right = zero % cols

    local row = rows - row_from_bottom
    local col = cols - col_from_right

    local x = (col - 1) * (entry_width + spacing)
    local y = (row - 1) * (entry_height + spacing)

    return x, y
end

function ExpiringEffectsWindow:refresh_visibility()
    local s = self:get_settings()
    if s.enabled ~= true then
        self:SetVisible(false)
        return
    end

    local cols = s.columns
    local rows = s.rows
    local capacity = cols * rows

    local any_visible = false
    for i = 1, capacity do
        local e = self.slots[i]
        if e ~= nil and e:IsVisible() then
            any_visible = true
            break
        end
    end

    self:SetVisible(any_visible or self:is_move_mode())
end

function ExpiringEffectsWindow:get_effect_objects()
    return {}
end

function ExpiringEffectsWindow:_hide_slots()
    for i = 1, #self.slots do
        local e = self.slots[i]
        if e ~= nil then
            e:SetVisible(false)
        end
    end
end

function ExpiringEffectsWindow:Update()
    local s = self:get_settings()
    if s.enabled ~= true then
        self:SetVisible(false)
        return
    end

    if self:is_move_mode() == true then
        self:_hide_slots()
        self:refresh_visibility()
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    local threshold = s.threshold

    local show_buffs = s.show_buffs == true
    local show_curable = s.show_curable_debuffs ~= false
    local show_noncurable = s.show_noncurable_debuffs ~= false
    local show_debuffs = (show_curable == true) or (show_noncurable == true)
    local show_unknown = _show_unknown_curability(show_curable, show_noncurable)

    if show_buffs ~= true and show_debuffs ~= true then
        self:_hide_slots()
        self:refresh_visibility()
        return
    end

    local cols = s.columns
    local rows = s.rows

    local capacity = cols * rows

    local candidates = {}
    local effects = self:get_effect_objects()
    for i = 1, #effects do
        local effect = effects[i]
        if effect ~= nil and effect.IsDebuff ~= nil then
            local key = self:get_effect_key(effect)
            self._effect_seen_at[key] = now

            local is_debuff = effect:IsDebuff()
            local curability = _curability_state(effect)

            local ok = true
            if is_debuff then
                if curability == CURABILITY_CURABLE then
                    ok = show_curable == true
                elseif curability == CURABILITY_NONCURABLE then
                    ok = show_noncurable == true
                else
                    ok = show_unknown
                end
            else
                ok = show_buffs == true
            end

            if ok then
                local duration = effect:GetDuration()
                if type(duration) ~= "number" then
                    duration = tonumber(duration)
                end
                if type(duration) == "number" and duration > 0 and duration < 9999 then
                    local start = effect:GetStartTime()
                    if type(start) ~= "number" then
                        start = tonumber(start)
                    end

                    local cached_start = self._effect_start[key]
                    if _is_valid_start(start, now) then
                        cached_start = start
                        self._effect_start[key] = start
                    elseif type(cached_start) ~= "number" then
                        cached_start = now
                        self._effect_start[key] = cached_start
                    end

                    local ending = cached_start + duration
                    local remaining = ending - now
                    if remaining > 0 and remaining <= threshold then
                        table.insert(candidates, {
                            effect = effect,
                            ending = ending,
                            remaining = remaining,
                            base = (duration < threshold) and duration or threshold,
                        })
                    end
                end
            end
        end
    end

    -- Prune cache (avoid unbounded growth).
    local ttl = 120
    for k, seen_at in pairs(self._effect_seen_at) do
        if type(seen_at) ~= "number" or (now - seen_at) > ttl then
            self._effect_seen_at[k] = nil
            self._effect_start[k] = nil
        end
    end

    table.sort(candidates, function(a, b) return a.ending < b.ending end)

    for slot = 1, capacity do
        local entry = self.slots[slot]
        local item = candidates[slot]
        if item ~= nil and entry ~= nil then
            entry:set_effect(item.effect)
            entry:update_remaining(item.remaining, item.base)
            entry:SetVisible(true)
        elseif entry ~= nil then
            entry:set_effect(nil)
            entry:SetVisible(false)
        end
    end

    self:refresh_visibility()
end
