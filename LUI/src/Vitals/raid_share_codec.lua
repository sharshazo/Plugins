-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Raid layout share message codec. A layout travels through regular raid
-- chat as one compact line the leader copy-pastes:
--
--   #LUI:RC1:<salt><24 x 2-digit cell><checksum>
--
-- Each cell is a base-93 pair: 0 = empty slot, 1..8648 = salted name hash.
-- Names never travel in the message; receivers resolve hashes against their
-- own roster. The salt is chosen at encode time so the sender's roster has
-- no hash collisions, making resolution unambiguous.

import "LUI.src.Utils.base93"

local Base93 = _G.LUI.Utils.Base93
local Vitals = _G.LUI.Features.Vitals
local RaidShareCodec = Vitals.RaidShareCodec or {}
Vitals.RaidShareCodec = RaidShareCodec

local PREFIX = "#LUI:RC1:"
local SLOT_COUNT = 24
-- 93^2 - 1 values per cell, minus the 0 = empty sentinel
local HASH_SPACE = (93 * 93) - 1
-- salt(1) + cells(48) + checksum(1)
local BODY_LENGTH = 1 + (SLOT_COUNT * 2) + 1

RaidShareCodec.PREFIX = PREFIX
RaidShareCodec.SLOT_COUNT = SLOT_COUNT

function RaidShareCodec.hash_name(name, salt)
    local hash = 5381 + salt
    local lowered = string.lower(name)
    for i = 1, #lowered do
        hash = ((hash * 33) + string.byte(lowered, i)) % 4294967296
    end
    return (hash % HASH_SPACE) + 1
end

-- First salt whose hashes are collision-free for the given names, or nil
-- when none exists (practically impossible for a 24-name roster).
function RaidShareCodec.pick_salt(names)
    for salt = 0, 92 do
        local seen = {}
        local ok = true
        for i = 1, SLOT_COUNT do
            local name = names[i]
            if name ~= nil then
                local hash = RaidShareCodec.hash_name(name, salt)
                if seen[hash] ~= nil then
                    ok = false
                    break
                end
                seen[hash] = true
            end
        end
        if ok == true then
            return salt
        end
    end
    return nil
end

-- names: array indexed 1..24, nil = empty slot. Returns the full chat line,
-- or nil when no collision-free salt exists.
function RaidShareCodec.encode(names)
    local salt = RaidShareCodec.pick_salt(names)
    if salt == nil then
        return nil
    end

    local payload = {}
    local sum = salt
    for i = 1, SLOT_COUNT do
        local value = 0
        if names[i] ~= nil then
            value = RaidShareCodec.hash_name(names[i], salt)
        end
        payload[i] = Base93.encode_uint(value, 2)
        sum = sum + math.floor(value / 93) + (value % 93)
    end

    return PREFIX .. Base93.char_of(salt) .. table.concat(payload) .. Base93.char_of(sum % 93)
end

-- Scans arbitrary chat text for a share message. Returns nil when absent or
-- corrupted, else { salt = n, values = {24 x 0..8648}, position = prefix index }.
function RaidShareCodec.decode(text)
    local position = string.find(text, PREFIX, 1, true)
    if position == nil then
        return nil
    end

    local body_start = position + #PREFIX
    local body = string.sub(text, body_start, body_start + BODY_LENGTH - 1)
    if #body < BODY_LENGTH then
        return nil
    end

    local salt = Base93.value_of(string.sub(body, 1, 1))
    if salt == nil then
        return nil
    end

    local values = {}
    local sum = salt
    for i = 1, SLOT_COUNT do
        local value = Base93.decode_uint(body, 2 + ((i - 1) * 2), 2)
        if value == nil then
            return nil
        end
        values[i] = value
        sum = sum + math.floor(value / 93) + (value % 93)
    end

    local checksum = Base93.value_of(string.sub(body, BODY_LENGTH, BODY_LENGTH))
    if checksum == nil or checksum ~= sum % 93 then
        return nil
    end

    return {
        salt = salt,
        values = values,
        position = position,
    }
end
