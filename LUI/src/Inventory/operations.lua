-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.Gameplay"

local Inventory = _G.LUI.Features.Inventory
Inventory.Operations = Inventory.Operations or {}

local Operations = Inventory.Operations

Operations.SORT_NONE = "none"
Operations.SORT_CATEGORY_AZ = "category_az"
Operations.SORT_AZ = "az"
Operations.SORT_QUANTITY = "quantity"
Operations.MERGE_UP = "up"
Operations.MERGE_DOWN = "down"

local SORT_RESPONSE_TIMEOUT = 2
local MERGE_RESPONSE_TIMEOUT = 2
local MAX_PENDING_SORT_DROPS = 2
local MAX_PENDING_MERGE_DROPS = 2
local MAX_MERGE_ROLLBACK_ATTEMPTS = 2
local PENDING_REMOVE = "remove"
local UNIT_SEPARATOR = "\31"

local MESSAGE_SORT_COMPLETE = "Inventory sort complete."
local MESSAGE_MERGE_COMPLETE = "Inventory merge complete."
local MESSAGE_FAILED = "Inventory action failed."
local MESSAGE_CHANGED = "Inventory changed; action stopped."
local MESSAGE_TIMEOUT = "Inventory action timed out."
local MESSAGE_NEEDS_BUFFER = "Sort needs an empty or different item slot to avoid merging stacks."

local CUSTOM_CATEGORY_NAMES = {
    [89] = "BarterReputation",
    [111] = "GuardianBelt",
    [163] = "MinstrelBook",
    [173] = "Special",
    [177] = "Skirmish",
    [178] = "Barter",
    [179] = "ShieldSpikes",
    [180] = "OutfitFeet",
    [181] = "OutfitShoulder",
    [182] = "OutfitUpperbody",
    [183] = "OutfitHead",
    [184] = "OutfitGloves",
    [185] = "OutfitTrousers",
    [186] = "SkillScrolls",
    [187] = "ChampionHorns",
    [188] = "CraftOptionalIngredient",
    [189] = "Perks",
    [190] = "TomeOf",
    [191] = "TravelAndMaps",
    [194] = "RelicScroll",
    [205] = "FestivalConsumable",
    [207] = "Misc2",
    [218] = "LegendaryBridle",
}

local CATEGORY_NAME_BY_ID = nil

local CATEGORY_GROUP_BY_NAME = {}

local function _add_category_group(order, names)
    for i = 1, #names do
        CATEGORY_GROUP_BY_NAME[names[i]] = order
    end
end

_add_category_group(10, { "Tool" })
_add_category_group(20, { "Device" })
_add_category_group(30, { "Potion", "Healing" })
_add_category_group(40, { "Scroll", "Trap", "Oil", "ShieldSpikes", "Effect", "SkillScrolls", "TomeOf" })
_add_category_group(50, { "Food", "LoremasterFood" })
_add_category_group(60, {
    "LegendaryWeaponExperience",
    "LegendaryWeaponIncreaseMaxLevel",
    "LegendaryWeaponReplaceLegacy",
    "LegendaryWeaponReset",
    "LegendaryWeaponUpgradeLegacy",
    "LegendaryBridle",
    "Relic",
    "RelicScroll",
})
_add_category_group(70, {
    "Axe",
    "Bow",
    "Club",
    "Crossbow",
    "Dagger",
    "Book",
    "Halberd",
    "Hammer",
    "Javelin",
    "Mace",
    "Spear",
    "Shield",
    "Staff",
    "Sword",
    "Thrown",
    "Weapon",
})
_add_category_group(80, { "Instrument", "Minstrel" })
_add_category_group(90, {
    "Armor",
    "GuardianBelt",
    "Back",
    "Chest",
    "Clothing",
    "CosmeticBack",
    "CosmeticHeld",
    "Feet",
    "Hands",
    "Head",
    "Jewelry",
    "Legs",
    "MinstrelBook",
    "Shoulders",
    "OutfitFeet",
    "OutfitUpperbody",
    "OutfitHead",
    "OutfitShoulder",
    "OutfitGloves",
    "OutfitTrousers",
})
_add_category_group(100, {
    "Runekeeper",
    "Burglar",
    "Captain",
    "Guardian",
    "Champion",
    "ChampionHorns",
    "Loremaster",
    "Hunter",
    "Warden",
})
_add_category_group(110, { "Component", "Crafting", "Ingredient", "CraftOptionalIngredient", "Resource", "CraftingTrophy" })
_add_category_group(120, { "Dye" })
_add_category_group(130, { "Fish", "FishingBait", "FishingOther", "FishingPole" })
_add_category_group(140, {
    "CeilingDecoration",
    "Decoration",
    "FloorDecoration",
    "FurnitureDecoration",
    "MusicDecoration",
    "SpecialDecoration",
    "Trophy",
    "TrophyDecoration",
    "YardDecoration",
    "WallDecoration",
    "SurfacePaintDecoration",
})
_add_category_group(150, {
    "BarterReputation",
    "BarterSkirmish",
    "Barter",
    "Skirmish",
    "Perks",
    "TravelAndMaps",
    "Quest",
    "Key",
    "KinshipCharter",
})

local function _safe_call(object, method_name)
    if object ~= nil and object[method_name] ~= nil then
        local ok, value = pcall(function()
            return object[method_name](object)
        end)
        if ok == true then
            return value
        end
    end
    return nil
end

local function _safe_number(value, fallback)
    local number = tonumber(value)
    if number == nil then
        return fallback
    end
    return number
end

local function _trim(text)
    local value = tostring(text or "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function _normalized_name(text)
    local value = _trim(text)
    value = value:gsub("%s+", " ")
    return string.lower(value)
end

local function _category_name_by_id(category_id)
    if CATEGORY_NAME_BY_ID == nil then
        CATEGORY_NAME_BY_ID = {}
        for id, name in pairs(CUSTOM_CATEGORY_NAMES) do
            CATEGORY_NAME_BY_ID[id] = name
        end
        if Turbine.Gameplay.ItemCategory ~= nil then
            for name, id in pairs(Turbine.Gameplay.ItemCategory) do
                if type(id) == "number" then
                    CATEGORY_NAME_BY_ID[id] = name
                end
            end
        end
    end

    return CATEGORY_NAME_BY_ID[category_id] or ""
end

local function _category_group(category_name)
    local exact = CATEGORY_GROUP_BY_NAME[category_name]
    if exact ~= nil then
        return exact
    end

    if string.find(category_name, "Scroll", 1, true) ~= nil then
        return 160
    end
    if string.find(category_name, "Decoration", 1, true) ~= nil then
        return 140
    end
    if string.find(category_name, "Craft", 1, true) ~= nil then
        return 110
    end
    if string.find(category_name, "Fishing", 1, true) ~= nil then
        return 130
    end

    return 999
end

local function _item_info(item)
    return _safe_call(item, "GetItemInfo")
end

local function _item_name(item, item_info)
    local name = _safe_call(item_info, "GetName")
    if name == nil or name == "" then
        name = _safe_call(item, "GetName")
    end
    return _trim(name)
end

local function _item_category(item, item_info)
    local category = _safe_call(item_info, "GetCategory")
    if category == nil then
        category = _safe_call(item, "GetCategory")
    end
    return _safe_number(category, 0)
end

local function _item_quality(item, item_info)
    local quality = _safe_call(item_info, "GetQuality")
    if quality == nil then
        quality = _safe_call(item, "GetQuality")
    end
    return _safe_number(quality, 0)
end

local function _item_quantity(item)
    local quantity = _safe_call(item, "GetQuantity")
    quantity = _safe_number(quantity, 1)
    if quantity < 1 then
        quantity = 1
    end
    return quantity
end

local function _item_max_stack(item, item_info)
    local max_stack = _safe_call(item, "GetMaxStackSize")
    if max_stack == nil then
        max_stack = _safe_call(item_info, "GetMaxStackSize")
    end
    if max_stack == nil then
        max_stack = _safe_call(item_info, "GetMaxQuantity")
    end
    max_stack = _safe_number(max_stack, 1)
    if max_stack < 1 then
        max_stack = 1
    end
    return max_stack
end

local function _item_icon_id(item_info)
    return _safe_number(_safe_call(item_info, "GetIconImageID"), 0)
end

local function _item_background_id(item_info)
    local background = _safe_call(item_info, "GetBackgroundImageID")
    if background == nil or background == 0 then
        background = _safe_call(item_info, "GetQualityImageID")
    end
    return _safe_number(background, 0)
end

local function _merge_key(name_key, category_id, quality, icon_id, background_id)
    return table.concat({
        name_key,
        tostring(category_id),
        tostring(quality),
        tostring(icon_id),
        tostring(background_id),
    }, UNIT_SEPARATOR)
end

local function _entry_for_slot(backpack, slot)
    local item = backpack:GetItem(slot)
    if item == nil then
        return {
            slot = slot,
            original_slot = slot,
            empty = true,
            quantity = 0,
            quality = 0,
            category_id = 0,
            category_group = 9999,
            merge_key = "",
            exact_key = "",
        }
    end

    local info = _item_info(item)
    local name = _item_name(item, info)
    local name_key = _normalized_name(name)
    local category_id = _item_category(item, info)
    local category_name = _category_name_by_id(category_id)
    local category_group = _category_group(category_name)
    local quality = _item_quality(item, info)
    local quantity = _item_quantity(item)
    local max_stack = _item_max_stack(item, info)
    local icon_id = _item_icon_id(info)
    local background_id = _item_background_id(info)
    local merge_key = _merge_key(name_key, category_id, quality, icon_id, background_id)

    return {
        slot = slot,
        original_slot = slot,
        empty = false,
        item = item,
        name = name,
        name_key = name_key,
        category_id = category_id,
        category_name = category_name,
        category_group = category_group,
        quality = quality,
        quantity = quantity,
        max_stack = max_stack,
        icon_id = icon_id,
        background_id = background_id,
        merge_key = merge_key,
        exact_key = merge_key .. UNIT_SEPARATOR .. tostring(quantity),
    }
end

local function _backpack_size(backpack)
    if backpack == nil or backpack.GetSize == nil or backpack.GetItem == nil then
        return nil
    end
    local size = _safe_number(backpack:GetSize(), 0)
    if size < 0 then
        size = 0
    end
    return math.floor(size)
end

local function _snapshot(backpack)
    local size = _backpack_size(backpack)
    if size == nil then
        return nil
    end

    local entries = {}
    for slot = 1, size do
        entries[slot] = _entry_for_slot(backpack, slot)
    end
    return entries
end

local function _entries_match(left, right)
    if left.empty == true or right.empty == true then
        return left.empty == true and right.empty == true
    end
    return left.exact_key == right.exact_key
end

local function _can_merge(left, right)
    return left.empty ~= true and right.empty ~= true and
        left.max_stack > 1 and right.max_stack > 1 and
        left.merge_key == right.merge_key
end

local function _compare_category_az(left, right)
    if left.empty ~= right.empty then
        return left.empty ~= true
    end
    if left.empty == true then
        return left.original_slot < right.original_slot
    end
    if left.category_group ~= right.category_group then
        return left.category_group < right.category_group
    end
    if left.name_key ~= right.name_key then
        return left.name_key < right.name_key
    end
    if left.quality ~= right.quality then
        return left.quality < right.quality
    end
    if left.quantity ~= right.quantity then
        return left.quantity > right.quantity
    end
    return left.original_slot < right.original_slot
end

local function _compare_az(left, right)
    if left.empty ~= right.empty then
        return left.empty ~= true
    end
    if left.empty == true then
        return left.original_slot < right.original_slot
    end
    if left.name_key ~= right.name_key then
        return left.name_key < right.name_key
    end
    if left.quality ~= right.quality then
        return left.quality < right.quality
    end
    if left.quantity ~= right.quantity then
        return left.quantity > right.quantity
    end
    return left.original_slot < right.original_slot
end

local function _compare_quantity(left, right)
    if left.empty ~= right.empty then
        return left.empty ~= true
    end
    if left.empty == true then
        return left.original_slot < right.original_slot
    end
    if left.quantity ~= right.quantity then
        return left.quantity > right.quantity
    end
    if left.category_group ~= right.category_group then
        return left.category_group < right.category_group
    end
    if left.name_key ~= right.name_key then
        return left.name_key < right.name_key
    end
    return left.original_slot < right.original_slot
end

local function _sort_entries(entries, mode)
    local sorted = {}
    for i = 1, #entries do
        sorted[i] = entries[i]
    end

    if mode == Operations.SORT_CATEGORY_AZ then
        table.sort(sorted, _compare_category_az)
    elseif mode == Operations.SORT_AZ then
        table.sort(sorted, _compare_az)
    elseif mode == Operations.SORT_QUANTITY then
        table.sort(sorted, _compare_quantity)
    else
        error("Unknown inventory sort mode: " .. tostring(mode))
    end

    return sorted
end

local function _merge_attempt_key(target_slot, source_slot, merge_key)
    return tostring(target_slot) .. UNIT_SEPARATOR .. tostring(source_slot) .. UNIT_SEPARATOR .. tostring(merge_key)
end

local function _find_merge_source(entries, start_slot, last_slot, step, target, blocked_pairs, locked_slots)
    local slot = start_slot
    while (step > 0 and slot <= last_slot) or (step < 0 and slot >= last_slot) do
        local source = entries[slot]
        if locked_slots[slot] ~= true and source.empty ~= true and source.max_stack > 1 and source.quantity > 0 and
            source.merge_key == target.merge_key then
            local key = _merge_attempt_key(target.slot, slot, target.merge_key)
            if blocked_pairs[key] ~= true then
                return slot
            end
        end
        slot = slot + step
    end
    return nil
end

local function _drop_item(backpack, item, destination_slot)
    if backpack.PerformItemDrop == nil then
        return false
    end

    local ok = pcall(function()
        backpack:PerformItemDrop(item, destination_slot, false)
    end)
    return ok == true
end

local BaseOperation = {}
BaseOperation.__index = BaseOperation

function BaseOperation:_begin(now)
    if self.started_at == nil then
        self.started_at = now
    end
end

function BaseOperation:_running()
    return { done = false, failed = false }
end

function BaseOperation:_done(message_key)
    return {
        done = true,
        failed = false,
        message_key = message_key,
        moves = self.moves,
    }
end

function BaseOperation:_fail(message_key)
    return {
        done = true,
        failed = true,
        message_key = message_key,
        moves = self.moves,
    }
end

function BaseOperation:_timed_out(now)
    return (now - self.started_at) > self.max_seconds or self.moves > self.max_moves
end

local function _pending_entry(entry)
    return {
        empty = entry.empty,
        merge_key = entry.merge_key,
        exact_key = entry.exact_key,
        quantity = entry.quantity,
    }
end

local function _entry_matches_pending(entry, expected)
    if entry.empty == true or expected.empty == true then
        return entry.empty == true and expected.empty == true
    end

    return entry.exact_key == expected.exact_key
end

local SortOperation = setmetatable({}, BaseOperation)
SortOperation.__index = SortOperation

function SortOperation:_locked_slots()
    local locked_slots = {}
    for i = 1, #self.pending do
        local pending = self.pending[i]
        locked_slots[pending.source_slot] = true
        locked_slots[pending.destination_slot] = true
    end

    return locked_slots
end

function SortOperation:_apply_pending_to_plan(pending)
    self.id_at_slot[pending.source_slot] = pending.destination_id
    self.id_at_slot[pending.destination_slot] = pending.source_id
    self.slot_for_id[pending.source_id] = pending.destination_slot
    self.slot_for_id[pending.destination_id] = pending.source_slot
end

function SortOperation:_drop_for_sort(item, destination_slot)
    if _drop_item(self.backpack, item, destination_slot) ~= true then
        return self:_fail(MESSAGE_FAILED)
    end

    self.moves = self.moves + 1
    return nil
end

function SortOperation:_sort_complete(live)
    for slot = 1, #self.desired do
        if _entries_match(live[slot], self.desired[slot]) ~= true then
            return false
        end
    end

    return true
end

function SortOperation:_plan_matches_live(live, locked_slots)
    for slot = 1, #live do
        if locked_slots[slot] ~= true then
            local entry_id = self.id_at_slot[slot]
            local expected = self.entry_by_id[entry_id]
            if expected == nil or _entry_matches_pending(live[slot], expected) ~= true then
                return false
            end
        end
    end

    return true
end

function SortOperation:_pending_matches_wait_state(pending, live)
    return _entry_matches_pending(live[pending.source_slot], pending.source_before) == true and
        _entry_matches_pending(live[pending.destination_slot], pending.destination_before) == true
end

function SortOperation:_pending_matches_expected_state(pending, live)
    return _entry_matches_pending(live[pending.source_slot], pending.source_after) == true and
        _entry_matches_pending(live[pending.destination_slot], pending.destination_after) == true
end

function SortOperation:_resolve_pending(live, now)
    for i = #self.pending, 1, -1 do
        local pending = self.pending[i]
        if self:_pending_matches_expected_state(pending, live) == true then
            self:_apply_pending_to_plan(pending)
            table.remove(self.pending, i)
        elseif self:_pending_matches_wait_state(pending, live) == true then
            if now - pending.started_at >= SORT_RESPONSE_TIMEOUT then
                return self:_fail(MESSAGE_TIMEOUT)
            end
        elseif now - pending.started_at >= SORT_RESPONSE_TIMEOUT then
            return self:_fail(MESSAGE_CHANGED)
        end
    end

    return nil
end

function SortOperation:_attempt_drop(now, live, source_slot, destination_slot)
    local source = live[source_slot]
    local destination = live[destination_slot]
    if destination.empty ~= true and _can_merge(source, destination) == true then
        return self:_fail(MESSAGE_NEEDS_BUFFER)
    end

    local pending = {
        source_slot = source_slot,
        destination_slot = destination_slot,
        source_id = self.id_at_slot[source_slot],
        destination_id = self.id_at_slot[destination_slot],
        source_before = _pending_entry(source),
        destination_before = _pending_entry(destination),
        source_after = _pending_entry(destination),
        destination_after = _pending_entry(source),
        started_at = now,
    }

    local result = self:_drop_for_sort(source.item, destination_slot)
    if result ~= nil then
        return result
    end

    self.pending[#self.pending + 1] = pending
    return nil
end

function SortOperation:_find_empty_slot(live, locked_slots, ignored_slots)
    for slot = 1, #live do
        if locked_slots[slot] ~= true and ignored_slots[slot] ~= true and live[slot].empty == true then
            return slot
        end
    end

    return nil
end

function SortOperation:_find_buffer_slot(live, locked_slots, ignored_slots, displaced, incoming)
    local empty_slot = self:_find_empty_slot(live, locked_slots, ignored_slots)
    if empty_slot ~= nil then
        return empty_slot
    end

    for slot = 1, #live do
        if locked_slots[slot] ~= true and ignored_slots[slot] ~= true then
            local candidate = live[slot]
            if candidate.empty ~= true and _can_merge(displaced, candidate) ~= true and
                _can_merge(incoming, candidate) ~= true then
                return slot
            end
        end
    end

    return nil
end

function SortOperation:_schedule_empty_desired_slot(live, now, slot, locked_slots, allow_fail)
    local current_id = self.id_at_slot[slot]
    local desired_slot = self.desired_slot_for_id[current_id]
    if desired_slot ~= nil and desired_slot ~= slot and locked_slots[desired_slot] ~= true then
        local destination = live[desired_slot]
        if destination.empty == true or _can_merge(live[slot], destination) ~= true then
            local result = self:_attempt_drop(now, live, slot, desired_slot)
            return result == nil, result
        end
    end

    local ignored_slots = { [slot] = true }
    local empty_slot = self:_find_empty_slot(live, locked_slots, ignored_slots)
    if empty_slot ~= nil then
        local result = self:_attempt_drop(now, live, slot, empty_slot)
        return result == nil, result
    end

    if allow_fail == true then
        return false, self:_fail(MESSAGE_CHANGED)
    end
    return false, nil
end

function SortOperation:_schedule_slot(live, now, slot, locked_slots, allow_fail)
    local target = self.desired[slot]
    local current = live[slot]

    if target.empty == true then
        if current.empty == true then
            return false, nil
        end

        return self:_schedule_empty_desired_slot(live, now, slot, locked_slots, allow_fail)
    end

    local desired_id = self.desired_ids[slot]
    local source_slot = self.slot_for_id[desired_id]
    if source_slot == nil then
        if allow_fail == true then
            return false, self:_fail(MESSAGE_CHANGED)
        end
        return false, nil
    end
    if source_slot == slot then
        if allow_fail == true then
            return false, self:_fail(MESSAGE_CHANGED)
        end
        return false, nil
    end
    if locked_slots[source_slot] == true then
        return false, nil
    end

    local source = live[source_slot]
    if source.empty == true then
        if allow_fail == true then
            return false, self:_fail(MESSAGE_CHANGED)
        end
        return false, nil
    end

    if current.empty == true or _can_merge(source, current) ~= true then
        local result = self:_attempt_drop(now, live, source_slot, slot)
        return result == nil, result
    end

    local ignored_slots = { [slot] = true, [source_slot] = true }
    local buffer_slot = self:_find_buffer_slot(live, locked_slots, ignored_slots, current, source)
    if buffer_slot == nil then
        if allow_fail == true then
            return false, self:_fail(MESSAGE_NEEDS_BUFFER)
        end
        return false, nil
    end

    local result = self:_attempt_drop(now, live, slot, buffer_slot)
    return result == nil, result
end

function SortOperation:_schedule_available_moves(live, now, locked_slots)
    local scheduled = 0
    local saw_unresolved = false

    for slot = 1, #self.desired do
        if #self.pending >= self.max_pending_drops then
            return scheduled, nil
        end

        if locked_slots[slot] ~= true and _entries_match(live[slot], self.desired[slot]) ~= true then
            local allow_fail = saw_unresolved ~= true and #self.pending == 0 and scheduled == 0
            saw_unresolved = true

            local did_schedule, result = self:_schedule_slot(live, now, slot, locked_slots, allow_fail)
            if result ~= nil then
                return scheduled, result
            end

            if did_schedule == true then
                local pending = self.pending[#self.pending]
                locked_slots[pending.source_slot] = true
                locked_slots[pending.destination_slot] = true
                scheduled = scheduled + 1
            end
        end
    end

    return scheduled, nil
end

function SortOperation:tick(now)
    self:_begin(now)
    if self:_timed_out(now) == true then
        return self:_fail(MESSAGE_TIMEOUT)
    end

    local live = _snapshot(self.backpack)
    if live == nil or #live ~= #self.desired then
        return self:_fail(MESSAGE_CHANGED)
    end

    local pending_result = self:_resolve_pending(live, now)
    if pending_result ~= nil then
        return pending_result
    end

    if self:_sort_complete(live) == true then
        return self:_done(MESSAGE_SORT_COMPLETE)
    end

    local locked_slots = self:_locked_slots()
    if self:_plan_matches_live(live, locked_slots) ~= true then
        return self:_fail(MESSAGE_CHANGED)
    end

    if self:_timed_out(now) == true then
        return self:_fail(MESSAGE_TIMEOUT)
    end

    local scheduled, schedule_result = self:_schedule_available_moves(live, now, locked_slots)
    if schedule_result ~= nil then
        return schedule_result
    end

    if #self.pending > 0 or scheduled > 0 then
        return self:_running()
    end

    return self:_fail(MESSAGE_CHANGED)
end

local MergeOperation = setmetatable({}, BaseOperation)
MergeOperation.__index = MergeOperation

function MergeOperation:_locked_slots()
    local locked_slots = {}
    for i = 1, #self.pending do
        local pending = self.pending[i]
        locked_slots[pending.target_slot] = true
        locked_slots[pending.source_slot] = true
    end

    return locked_slots
end

function MergeOperation:_block_pair(pending)
    local key = _merge_attempt_key(pending.target_slot, pending.source_slot, pending.merge_key)
    self.blocked_pairs[key] = true
end

function MergeOperation:_drop_for_merge(item, destination_slot)
    if _drop_item(self.backpack, item, destination_slot) ~= true then
        return self:_fail(MESSAGE_FAILED)
    end

    self.moves = self.moves + 1
    return nil
end

function MergeOperation:_slots_match_wait_state(pending, live)
    return _entry_matches_pending(live[pending.target_slot], pending.wait_target) == true and
        _entry_matches_pending(live[pending.source_slot], pending.wait_source) == true
end

function MergeOperation:_slots_restored(pending, live)
    return _entry_matches_pending(live[pending.target_slot], pending.target_before) == true and
        _entry_matches_pending(live[pending.source_slot], pending.source_before) == true
end

function MergeOperation:_slots_swapped(pending, live)
    return _entry_matches_pending(live[pending.target_slot], pending.source_before) == true and
        _entry_matches_pending(live[pending.source_slot], pending.target_before) == true
end

function MergeOperation:_merge_succeeded(pending, live)
    local target = live[pending.target_slot]
    local source = live[pending.source_slot]
    local target_before = pending.target_before
    local source_before = pending.source_before

    if target.empty == true or target.merge_key ~= pending.merge_key then
        return false
    end

    if source.empty == true and target.quantity == target_before.quantity + source_before.quantity then
        return true
    end

    return source.empty ~= true and source.merge_key == pending.merge_key and
        target.quantity > target_before.quantity and source.quantity < source_before.quantity
end

function MergeOperation:_begin_rollback(pending, live, now)
    self:_block_pair(pending)

    local target = live[pending.target_slot]
    pending.action = "rollback"
    pending.rollback_attempts = pending.rollback_attempts + 1
    pending.started_at = now
    pending.wait_target = _pending_entry(target)
    pending.wait_source = _pending_entry(live[pending.source_slot])

    return self:_drop_for_merge(target.item, pending.source_slot)
end

function MergeOperation:_resolve_pending_merge(pending, live, now)
    if self:_slots_match_wait_state(pending, live) == true then
        if now - pending.started_at >= MERGE_RESPONSE_TIMEOUT then
            self:_block_pair(pending)
            return PENDING_REMOVE
        end

        return nil
    end

    if self:_slots_swapped(pending, live) == true then
        local result = self:_begin_rollback(pending, live, now)
        if result ~= nil then
            return result
        end

        return nil
    end

    if self:_merge_succeeded(pending, live) == true then
        return PENDING_REMOVE
    end

    if now - pending.started_at >= MERGE_RESPONSE_TIMEOUT then
        return self:_fail(MESSAGE_CHANGED)
    end

    return nil
end

function MergeOperation:_resolve_pending_rollback(pending, live, now)
    if self:_slots_restored(pending, live) == true then
        return PENDING_REMOVE
    end

    if self:_slots_match_wait_state(pending, live) == true then
        if now - pending.started_at < MERGE_RESPONSE_TIMEOUT then
            return nil
        end

        if pending.rollback_attempts >= MAX_MERGE_ROLLBACK_ATTEMPTS then
            return self:_fail(MESSAGE_TIMEOUT)
        end

        local result = self:_begin_rollback(pending, live, now)
        if result ~= nil then
            return result
        end

        return nil
    end

    if now - pending.started_at < MERGE_RESPONSE_TIMEOUT then
        return nil
    end

    return self:_fail(MESSAGE_CHANGED)
end

function MergeOperation:_resolve_pending(live, now)
    for i = #self.pending, 1, -1 do
        local pending = self.pending[i]
        local result

        if pending.action == "merge" then
            result = self:_resolve_pending_merge(pending, live, now)
        elseif pending.action == "rollback" then
            result = self:_resolve_pending_rollback(pending, live, now)
        else
            error("Unknown inventory merge pending action: " .. tostring(pending.action))
        end

        if result == PENDING_REMOVE then
            table.remove(self.pending, i)
        elseif result ~= nil then
            return result
        end
    end

    return nil
end

function MergeOperation:_attempt_merge(now, target, source)
    local pending = {
        action = "merge",
        target_slot = target.slot,
        source_slot = source.slot,
        merge_key = target.merge_key,
        target_before = _pending_entry(target),
        source_before = _pending_entry(source),
        wait_target = _pending_entry(target),
        wait_source = _pending_entry(source),
        rollback_attempts = 0,
        started_at = now,
    }

    local result = self:_drop_for_merge(source.item, target.slot)
    if result ~= nil then
        return result
    end

    self.pending[#self.pending + 1] = pending
    return nil
end

function MergeOperation:_schedule_available_merges(live, now)
    local locked_slots = self:_locked_slots()
    local scheduled = 0
    local slot = self.first_slot

    while #self.pending < self.max_pending_drops and
        ((self.step > 0 and slot <= self.last_slot) or (self.step < 0 and slot >= self.last_slot)) do
        if locked_slots[slot] ~= true then
            local target = live[slot]
            if target.empty ~= true and target.max_stack > 1 and target.quantity < target.max_stack then
                local source_slot = _find_merge_source(
                    live,
                    slot + self.step,
                    self.last_slot,
                    self.step,
                    target,
                    self.blocked_pairs,
                    locked_slots
                )

                if source_slot ~= nil then
                    local source = live[source_slot]
                    local result = self:_attempt_merge(now, target, source)
                    if result ~= nil then
                        return scheduled, result
                    end

                    locked_slots[slot] = true
                    locked_slots[source_slot] = true
                    scheduled = scheduled + 1
                end
            end
        end

        slot = slot + self.step
    end

    return scheduled, nil
end

function MergeOperation:tick(now)
    self:_begin(now)
    if self:_timed_out(now) == true then
        return self:_fail(MESSAGE_TIMEOUT)
    end

    local live = _snapshot(self.backpack)
    if live == nil or #live ~= self.size then
        return self:_fail(MESSAGE_CHANGED)
    end

    local pending_result = self:_resolve_pending(live, now)
    if pending_result ~= nil then
        return pending_result
    end

    if self:_timed_out(now) == true then
        return self:_fail(MESSAGE_TIMEOUT)
    end

    local scheduled, schedule_result = self:_schedule_available_merges(live, now)
    if schedule_result ~= nil then
        return schedule_result
    end

    if #self.pending > 0 or scheduled > 0 then
        return self:_running()
    end

    return self:_done(MESSAGE_MERGE_COMPLETE)
end

function Operations.create_sort(backpack, mode)
    local live = _snapshot(backpack)
    if live == nil then
        live = {}
    end
    local desired = _sort_entries(live, mode)
    local size = #desired
    local desired_ids = {}
    local desired_slot_for_id = {}
    local id_at_slot = {}
    local slot_for_id = {}
    local entry_by_id = {}

    for slot = 1, size do
        local id = live[slot].original_slot
        id_at_slot[slot] = id
        slot_for_id[id] = slot
        entry_by_id[id] = _pending_entry(live[slot])

        local desired_id = desired[slot].original_slot
        desired_ids[slot] = desired_id
        desired_slot_for_id[desired_id] = slot
    end

    return setmetatable({
        kind = "sort",
        backpack = backpack,
        mode = mode,
        desired = desired,
        desired_ids = desired_ids,
        desired_slot_for_id = desired_slot_for_id,
        id_at_slot = id_at_slot,
        slot_for_id = slot_for_id,
        entry_by_id = entry_by_id,
        moves = 0,
        pending = {},
        max_pending_drops = MAX_PENDING_SORT_DROPS,
        max_moves = (size * 4) + 40,
        max_seconds = math.max(45, size * SORT_RESPONSE_TIMEOUT),
    }, SortOperation)
end

function Operations.create_merge(backpack, direction)
    local size = _backpack_size(backpack) or 0
    local first_slot = 1
    local last_slot = size
    local step = 1

    if direction == Operations.MERGE_DOWN then
        first_slot = size
        last_slot = 1
        step = -1
    elseif direction ~= Operations.MERGE_UP then
        error("Unknown inventory merge direction: " .. tostring(direction))
    end

    return setmetatable({
        kind = "merge",
        backpack = backpack,
        direction = direction,
        size = size,
        first_slot = first_slot,
        last_slot = last_slot,
        step = step,
        moves = 0,
        pending = {},
        blocked_pairs = {},
        max_pending_drops = MAX_PENDING_MERGE_DROPS,
        max_moves = (size * 8) + 40,
        max_seconds = math.max(45, size * MERGE_RESPONSE_TIMEOUT),
    }, MergeOperation)
end
