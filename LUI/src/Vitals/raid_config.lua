-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- RaidConfig: the raid slot assignment store. Slots 1-6 are Group A,
-- 7-12 B, 13-18 C, 19-24 D. Two modes:
--
-- - auto: members render in game order, chunked into groups of 6 (the
--   historical behavior). Active while no manual layout exists.
-- - manual: a user-arranged (or chat-received) name-per-slot layout that
--   supersedes the automatic layout entirely. Roster members without an
--   assigned slot fill empty cells so newcomers appear immediately.
--
-- The manual layout is live-only by design: it resets on plugin reload /
-- relog, and the leader's share line is the way to restore it.

import "LUI.src.Vitals.raid_share_codec"

local Vitals = _G.LUI.Features.Vitals
local RaidConfig = Vitals.RaidConfig or {}
Vitals.RaidConfig = RaidConfig

local RaidShareCodec = Vitals.RaidShareCodec

local SLOT_COUNT = 24

RaidConfig.SLOT_COUNT = SLOT_COUNT

-- Live manual layout: slot index -> member name.
local _manual = false
local _slots = {}

-- Chat-received hash values not yet matched to a roster member.
local _pending = nil

local function _member_name(member)
    if member.GetName == nil then
        return nil
    end
    return member:GetName()
end

function RaidConfig.is_manual()
    return _manual == true
end

function RaidConfig.clear()
    _manual = false
    _slots = {}
    _pending = nil
end

-- display: array 1..24 of { name = ... } or false, as returned by
-- display_slots. Freezes what is currently shown into the manual layout.
function RaidConfig.seed_from_display(display)
    local slots = {}
    for i = 1, SLOT_COUNT do
        local cell = display[i]
        if cell ~= false then
            slots[i] = cell.name
        end
    end
    _slots = slots
    _manual = true
    _pending = nil
end

-- Drop of from_slot onto to_slot: move when the target is empty
-- (to_name == nil), swap otherwise. Caller must be in manual mode.
function RaidConfig.apply_move(from_slot, from_name, to_slot, to_name)
    _slots[to_slot] = from_name
    _slots[from_slot] = to_name
end

function RaidConfig.apply_share(share, snapshot)
    _slots = {}
    _manual = true
    _pending = {
        salt = share.salt,
        values = share.values,
    }
    RaidConfig.resolve_pending(snapshot)
end

-- Matches still-pending share hashes against the current roster and writes
-- resolved names into the layout. Cheap: runs only while a share has
-- unresolved cells, on roster rebuilds.
function RaidConfig.resolve_pending(snapshot)
    if _pending == nil then
        return
    end

    local taken = {}
    for i = 1, SLOT_COUNT do
        local name = _slots[i]
        if name ~= nil then
            taken[name] = true
        end
    end

    local by_hash = {}
    local members = snapshot.members
    for i = 1, #members do
        local name = _member_name(members[i])
        if name ~= nil and taken[name] ~= true then
            by_hash[RaidShareCodec.hash_name(name, _pending.salt)] = name
        end
    end

    local unresolved = 0
    for i = 1, SLOT_COUNT do
        local value = _pending.values[i]
        if value > 0 and _slots[i] == nil then
            local name = by_hash[value]
            if name ~= nil and taken[name] ~= true then
                _slots[i] = name
                taken[name] = true
            else
                unresolved = unresolved + 1
            end
        end
    end

    if unresolved == 0 then
        _pending = nil
    end
end

local function _first_empty_slot(slots, named, allow_named)
    for i = 1, SLOT_COUNT do
        if slots[i] == false and (allow_named == true or named[i] ~= true) then
            return i
        end
    end
    return nil
end

-- Resolves the current mode against a roster snapshot. Returns an array
-- 1..24 of member entities, false = empty cell.
function RaidConfig.resolve_slots(snapshot)
    local members = snapshot.members
    local slots = {}

    if _manual ~= true then
        for i = 1, SLOT_COUNT do
            local member = members[i]
            if member == nil then
                member = false
            end
            slots[i] = member
        end
        return slots
    end

    RaidConfig.resolve_pending(snapshot)

    local by_name = {}
    for i = 1, #members do
        local name = _member_name(members[i])
        if name ~= nil then
            by_name[name] = members[i]
        end
    end

    local used = {}
    local named = {}
    for i = 1, SLOT_COUNT do
        slots[i] = false
        local name = _slots[i]
        named[i] = name ~= nil
        if name ~= nil then
            local entity = by_name[name]
            if entity ~= nil and used[name] ~= true then
                slots[i] = entity
                used[name] = true
            end
        end
    end

    -- Newcomers fill nameless cells first and stick there (recorded in the
    -- layout), so later roster-order changes never reshuffle placed
    -- members. Cells reserved for an absent member are display-filled only
    -- as a last resort and keep their reserved name.
    for i = 1, #members do
        local member = members[i]
        local name = _member_name(member)
        if name ~= nil and used[name] ~= true then
            local target = _first_empty_slot(slots, named, false)
            if target ~= nil then
                _slots[target] = name
                named[target] = true
            else
                target = _first_empty_slot(slots, named, true)
            end
            if target ~= nil then
                slots[target] = member
                used[name] = true
            end
        end
    end

    return slots
end

-- Window/share view: array 1..24 of { name, entity } (entity nil for an
-- assigned-but-absent member), false = empty cell.
function RaidConfig.display_slots(snapshot)
    local entities = RaidConfig.resolve_slots(snapshot)
    local display = {}
    for i = 1, SLOT_COUNT do
        local entity = entities[i]
        if entity ~= false then
            display[i] = {
                name = _member_name(entity),
                entity = entity,
            }
        elseif _manual == true and _slots[i] ~= nil then
            display[i] = {
                name = _slots[i],
                entity = nil,
            }
        else
            display[i] = false
        end
    end
    return display
end
