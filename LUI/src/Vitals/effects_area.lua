-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Vitals = _G.LUI.Features.Vitals
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Vitals.effect_icon"
import "LUI.src.Settings.enums"

local COMPACT_ICON_MIN_SIZE = 22
local UPSIZE_DELAY_SEC = 30

local function _effect_id(effect)
    if effect == nil then
        return 0
    end
    return effect:GetID()
end

local function _item_effect_id(item)
    if item == nil then
        return 0
    end
    if item.get_effect_id ~= nil then
        return item:get_effect_id()
    end
    if item.effect ~= nil and item.effect.GetID ~= nil then
        return item.effect:GetID()
    end
    return 0
end

local function _item_sort_expiry(item)
    if item == nil then
        return math.huge
    end

    local ending = item.ending
    if type(ending) ~= "number" or ending <= 0 then
        return math.huge
    end
    return ending
end

local function _destroy_item(item)
    if item == nil then
        return
    end
    if item.destroy ~= nil then
        item:destroy()
        return
    end
    if item.SetWantsUpdates ~= nil then
        item:SetWantsUpdates(false)
    end
    if item.SetVisible ~= nil then
        item:SetVisible(false)
    end
    if item.SetParent ~= nil then
        item:SetParent(nil)
    end
end

local function _timer_style(font)
    return LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None
end

local function _as_number(v, default)
    if type(v) == "number" then
        return v
    end
    local n = tonumber(v)
    if type(n) == "number" then
        return n
    end
    return default
end

local function _clamp_int(v, min_v, max_v)
    if v < min_v then
        return min_v
    end
    if max_v ~= nil and v > max_v then
        return max_v
    end
    return v
end

---@class EffectsArea : Turbine.UI.Control
---@field on_height_changed function
local EffectsArea = class(Turbine.UI.Control)
Vitals.EffectsArea = EffectsArea

function EffectsArea:Constructor(frame_width, effects_settings, effects_height)
    Turbine.UI.Control.Constructor(self)

    self.on_height_changed = nil
    self.effects_settings = effects_settings
    self.effects_height = effects_height
    self.frame_width = frame_width
    self.max_height = _as_number(effects_height, 0) / 2
    self.dynamic_height = self:_default_dynamic_height() == true
    self.items_per_row = 1
    self.reverse_fill = true
    self.horizontal_alignment = self:_default_horizontal_alignment()
    self.is_compact = false
    self.compact_icon_size = nil
    self.compact_timer_font_size = nil
    self.upsize_due_at = nil

    self:SetSize(1, self.max_height)
    self:SetMouseVisible(false)

    self.list = Turbine.UI.ListBox()
    self.list:SetParent(self)
    self.list:SetSize(self:GetSize())
    self.list:SetPosition(0, 0)
    self.list:SetOrientation(Turbine.UI.Orientation.Horizontal)
    self.list:SetMaxColumns(self.items_per_row)
    self.list:SetMouseVisible(false)
    self.list:SetReverseFill(true)
    self.list:SetFlippedLayout(false)

    self:apply_settings(frame_width, effects_settings, effects_height)
    self:_apply_dynamic_height()
end

function EffectsArea:Update()
    if self.is_compact ~= true or type(self.upsize_due_at) ~= "number" then
        self:SetWantsUpdates(false)
        self.upsize_due_at = nil
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if now < self.upsize_due_at then
        return
    end

    if self:_can_upsize_now() == true then
        self:_set_compact(false)
    else
        self.upsize_due_at = nil
        self:SetWantsUpdates(false)
    end
end

function EffectsArea:set_reverse_fill(reverse_fill)
    local on = reverse_fill == true
    if self.reverse_fill == on then
        return
    end

    self.reverse_fill = on
    self:_apply_layout_flags()
end

function EffectsArea:set_horizontal_alignment(alignment)
    local next_alignment = self:_normalize_horizontal_alignment(alignment)
    if self.horizontal_alignment == next_alignment then
        return
    end

    self.horizontal_alignment = next_alignment
    self:_apply_layout_flags()
end

function EffectsArea:set_dynamic_height(enabled)
    local on = enabled == true
    if self.dynamic_height == on then
        return
    end
    self.dynamic_height = on
    self:_apply_dynamic_height()
end

function EffectsArea:set_max_height(max_height)
    local h = _as_number(max_height, nil)
    if type(h) ~= "number" then
        return
    end
    if h < 0 then
        h = 0
    end
    if self.max_height == h then
        return
    end

    self.max_height = h

    local width = self:GetWidth()
    if type(width) ~= "number" then
        width = _as_number(self.frame_width, 1)
    end

    self:SetSize(width, h)
    if self.list ~= nil then
        self.list:SetSize(width, h)
    end

    self:_sync_compact_to_count()
    self:_apply_dynamic_height()
    self:_update_upsize_debounce()
end

function EffectsArea:apply_settings(frame_width, effects_settings, effects_height)
    if effects_settings ~= nil then
        self.effects_settings = effects_settings
    end
    if frame_width ~= nil then
        self.frame_width = frame_width
    end
    if effects_height ~= nil then
        self.effects_height = effects_height
    end

    if self:_reset_max_height_on_apply_settings() == true or type(self.max_height) ~= "number" then
        self.max_height = _as_number(self.effects_height, 0) / 2
    end

    if self.is_compact == true then
        local count = self:_current_count()
        if self:_needs_compact_for_count(count) == true then
            local compact_icon, compact_font = self:_compute_compact_profile(count)
            if type(compact_icon) ~= "number" then
                self.is_compact = false
                self.compact_icon_size = nil
                self.compact_timer_font_size = nil
                self.upsize_due_at = nil
            else
                self.compact_icon_size = compact_icon
                self.compact_timer_font_size = compact_font
            end
        end
    end

    local width = _as_number(self.frame_width, 1)
    self.items_per_row = self:_active_items_per_row()
    self.horizontal_alignment = self:_settings_horizontal_alignment()

    self:SetSize(width, self.max_height)
    if self.list ~= nil then
        self.list:SetSize(self:GetSize())
        self.list:SetMaxColumns(self.items_per_row)
    end
    self:_apply_layout_flags()

    if self.list ~= nil and self.list:GetItemCount() > 0 then
        self:_rebuild_icons()
    else
        self:_apply_dynamic_height()
    end

    self:_update_upsize_debounce()
end

function EffectsArea:add_effect(effect)
    if effect == nil or self:_should_track_effect(effect) ~= true then
        return
    end

    local id = _effect_id(effect)
    for i = 1, self.list:GetItemCount(), 1 do
        local item = self.list:GetItem(i)
        if item ~= nil then
            local item_id = _item_effect_id(item)
            if item_id == id then
                if item.set_effect ~= nil then
                    item:set_effect(effect)
                end
                self:sort()
                self:_sync_compact_to_count()
                self:_apply_dynamic_height()
                self:_update_upsize_debounce()
                return
            end
        end
    end

    self.list:AddItem(self:_create_effect_icon(effect))
    self:sort()
    self:_sync_compact_to_count()
    self:_apply_dynamic_height()
    self:_update_upsize_debounce()
end

function EffectsArea:remove_effect(effect, id_override)
    local remove_id = id_override
    if type(remove_id) ~= "number" then
        if effect == nil then
            return
        end
        remove_id = _effect_id(effect)
    end

    for i = self.list:GetItemCount(), 1, -1 do
        local item = self.list:GetItem(i)
        if item ~= nil then
            local item_id = _item_effect_id(item)
            if item.effect == effect or item_id == remove_id then
                _destroy_item(item)
                self.list:RemoveItem(item)
            end
        end
    end

    self:_sync_compact_to_count()
    self:_apply_dynamic_height()
    self:_update_upsize_debounce()
end

function EffectsArea:clear_effects()
    for i = 1, self.list:GetItemCount(), 1 do
        local item = self.list:GetItem(i)
        _destroy_item(item)
    end
    self.list:ClearItems()
    self:_sync_compact_to_count()
    self:_apply_dynamic_height()
    self:_update_upsize_debounce()
end

function EffectsArea:sort()
    self.list:Sort(function(elem1, elem2)
        local expiry1 = _item_sort_expiry(elem1)
        local expiry2 = _item_sort_expiry(elem2)

        if expiry1 ~= expiry2 then
            return expiry1 > expiry2
        end

        local id1 = _item_effect_id(elem1)
        local id2 = _item_effect_id(elem2)
        if id1 ~= id2 then
            return id1 > id2
        end

        return elem1.ending > elem2.ending
    end)
end

function EffectsArea:_settings_group()
    return nil
end

function EffectsArea:_default_icon_size()
    return 32
end

function EffectsArea:_default_timer_font()
    return {
        name = LUI_ENUMS.font_name.VERDANA,
        size = 12,
        lotro = Turbine.UI.Lotro.Font.Verdana12,
        style = LUI_ENUMS.font_style.OUTLINE,
    }
end

function EffectsArea:_default_dynamic_height()
    return false
end

function EffectsArea:_default_horizontal_alignment()
    return LUI_ENUMS.side.LEFT
end

function EffectsArea:_reset_max_height_on_apply_settings()
    return false
end

function EffectsArea:_should_track_effect(effect)
    return effect ~= nil
end

function EffectsArea:_area_settings()
    local group = self:_settings_group()
    if type(group) ~= "string" or self.effects_settings == nil then
        return nil
    end
    return self.effects_settings[group]
end

function EffectsArea:_normalize_horizontal_alignment(alignment)
    if alignment == LUI_ENUMS.side.RIGHT then
        return LUI_ENUMS.side.RIGHT
    end
    return LUI_ENUMS.side.LEFT
end

function EffectsArea:_settings_horizontal_alignment()
    local settings = self:_area_settings()
    if settings == nil then
        return self:_default_horizontal_alignment()
    end
    return self:_normalize_horizontal_alignment(settings.alignment)
end

function EffectsArea:_apply_layout_flags()
    local align_right = self.horizontal_alignment == LUI_ENUMS.side.RIGHT
    local flip_rows = self.reverse_fill ~= align_right

    self.list:SetReverseFill(align_right)
    self.list:SetFlippedLayout(flip_rows)
end

function EffectsArea:_normal_icon_size()
    local settings = self:_area_settings()
    if settings == nil then
        return self:_default_icon_size()
    end
    return _as_number(settings.icon_size, self:_default_icon_size())
end

function EffectsArea:_normal_timer_font()
    local settings = self:_area_settings()
    if settings == nil or settings.timer_font == nil then
        return self:_default_timer_font()
    end
    return settings.timer_font
end

function EffectsArea:_active_items_per_row()
    local width = _as_number(self.frame_width, 1)
    local icon_size = self:_active_icon_size()
    local per_row = math.floor(width / icon_size)
    if per_row < 1 then
        per_row = 1
    end
    return per_row
end

function EffectsArea:_current_count()
    if self.list == nil or self.list.GetItemCount == nil then
        return 0
    end
    return _as_number(self.list:GetItemCount(), 0)
end

function EffectsArea:_capacity_for_icon_size(icon_size)
    local width = _as_number(self.frame_width, 1)
    local height = _as_number(self.max_height, 0)
    local s = _as_number(icon_size, 0)
    if s <= 0 then
        return 0
    end

    local cols = math.floor(width / s)
    if cols < 1 then
        cols = 1
    end

    local rows = math.floor(height / s)
    if rows < 1 then
        rows = 1
    end

    return cols * rows
end

function EffectsArea:_best_icon_size_for_count(count, max_icon_size)
    local n = _as_number(count, 0)
    local max_s = _as_number(max_icon_size, self:_default_icon_size())
    max_s = math.floor(max_s)
    if max_s < 1 then
        max_s = 1
    end

    if n <= 0 then
        return max_s
    end

    for s = max_s, COMPACT_ICON_MIN_SIZE, -1 do
        if self:_capacity_for_icon_size(s) >= n then
            return s
        end
    end

    return COMPACT_ICON_MIN_SIZE
end

function EffectsArea:_active_icon_size()
    if self.is_compact == true and type(self.compact_icon_size) == "number" and self.compact_icon_size > 0 then
        return self.compact_icon_size
    end
    return self:_normal_icon_size()
end

function EffectsArea:_active_timer_font()
    local f = self:_normal_timer_font()
    if self.is_compact ~= true or type(self.compact_timer_font_size) ~= "number" then
        return f.lotro, f
    end
    local lotro = FONT_TO_LOTRO(f.name, self.compact_timer_font_size) or f.lotro
    return lotro, f
end

function EffectsArea:_compute_compact_profile(count_override)
    local normal_icon = self:_normal_icon_size()
    if normal_icon <= COMPACT_ICON_MIN_SIZE then
        return nil
    end

    local count = count_override
    if type(count) ~= "number" then
        count = self:_current_count()
    end
    count = _as_number(count, 0)
    if count <= 0 then
        return nil
    end

    local compact_icon = self:_best_icon_size_for_count(count, normal_icon)
    compact_icon = _clamp_int(compact_icon, COMPACT_ICON_MIN_SIZE, normal_icon - 1)
    if compact_icon >= normal_icon then
        return nil
    end

    local f = self:_normal_timer_font()
    local ratio = compact_icon / normal_icon
    local compact_font_size = _as_number(f.size, self:_default_timer_font().size) * ratio
    compact_font_size = math.floor(compact_font_size + 0.5)
    if compact_font_size < 8 then
        compact_font_size = 8
    end
    if compact_font_size > _as_number(f.size, self:_default_timer_font().size) then
        compact_font_size = _as_number(f.size, self:_default_timer_font().size)
    end

    return compact_icon, compact_font_size
end

function EffectsArea:_set_compact(enabled, count_override)
    if enabled == true then
        local count = count_override
        if type(count) ~= "number" then
            count = self:_current_count()
        end

        local compact_icon, compact_font = self:_compute_compact_profile(count)
        if type(compact_icon) ~= "number" then
            return
        end

        local changed = (self.is_compact ~= true)
            or (self.compact_icon_size ~= compact_icon)
            or (self.compact_timer_font_size ~= compact_font)

        self.is_compact = true
        self.compact_icon_size = compact_icon
        self.compact_timer_font_size = compact_font
        self.upsize_due_at = nil
        if changed then
            self:apply_settings(self.frame_width, self.effects_settings, self.effects_height)
        end
    else
        if self.is_compact ~= true then
            return
        end
        self.is_compact = false
        self.compact_icon_size = nil
        self.compact_timer_font_size = nil
        self.upsize_due_at = nil
        self:apply_settings(self.frame_width, self.effects_settings, self.effects_height)
    end

    self:_update_upsize_debounce()
end

function EffectsArea:_needs_compact_for_count(count_after)
    local count = _as_number(count_after, 0)
    if count <= 0 then
        return false
    end
    return self:_capacity_for_icon_size(self:_normal_icon_size()) < count
end

function EffectsArea:_can_upsize_now()
    if self.is_compact ~= true then
        return false
    end
    if self.list == nil then
        return true
    end
    local count = self:_current_count()
    return self:_capacity_for_icon_size(self:_normal_icon_size()) >= count
end

function EffectsArea:_update_upsize_debounce()
    if self.is_compact ~= true then
        self:SetWantsUpdates(false)
        self.upsize_due_at = nil
        return
    end

    if self:_can_upsize_now() ~= true then
        self.upsize_due_at = nil
        self:SetWantsUpdates(false)
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if type(self.upsize_due_at) ~= "number" then
        self.upsize_due_at = now + UPSIZE_DELAY_SEC
    end
    self:SetWantsUpdates(true)
end

function EffectsArea:_sync_compact_to_count()
    local count = self:_current_count()
    if count <= 0 then
        if self.is_compact == true then
            self:_set_compact(false)
        end
        return
    end

    if self:_needs_compact_for_count(count) == true then
        self:_set_compact(true, count)
    end
end

function EffectsArea:_create_effect_icon(effect)
    local icon_size = self:_active_icon_size()
    local lotro_font, f = self:_active_timer_font()
    return Vitals.EffectIcon(effect, icon_size, lotro_font, _timer_style(f), f.color, f.outline_color)
end

function EffectsArea:_rebuild_icons()
    if self.list == nil then
        return
    end

    local effects = {}
    for i = 1, self.list:GetItemCount(), 1 do
        local item = self.list:GetItem(i)
        if item ~= nil and item.effect ~= nil and self:_should_track_effect(item.effect) == true then
            table.insert(effects, item.effect)
        end
        _destroy_item(item)
    end

    self.list:ClearItems()

    for i = 1, #effects do
        self.list:AddItem(self:_create_effect_icon(effects[i]))
    end
    self:sort()
    self:_apply_dynamic_height()
end

function EffectsArea:_desired_height()
    local max_height = self.max_height
    if type(max_height) ~= "number" then
        max_height = _as_number(self.effects_height, 0) / 2
        self.max_height = max_height
    end

    if self.dynamic_height ~= true then
        return max_height
    end

    local icon_size = self:_active_icon_size()
    if icon_size <= 0 then
        return max_height
    end

    local count = self:_current_count()
    if count <= 0 then
        return 0
    end

    local per_row = self.items_per_row
    local rows = math.ceil(count / per_row)
    local h = rows * icon_size
    if h > max_height then
        h = max_height
    end
    if h < icon_size then
        h = icon_size
    end
    return h
end

function EffectsArea:_apply_dynamic_height()
    local h = self:_desired_height()
    local prev_h = nil
    if self.GetHeight ~= nil then
        prev_h = self:GetHeight()
    end
    if self.SetHeight ~= nil then
        self:SetHeight(h)
    end
    if self.list ~= nil and self.list.SetHeight ~= nil then
        self.list:SetHeight(h)
    end
    if type(prev_h) == "number" and prev_h ~= h and type(self.on_height_changed) == "function" then
        self.on_height_changed(h)
    end
end
