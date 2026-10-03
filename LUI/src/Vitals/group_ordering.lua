-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.Gameplay"

import "LUI.src.Vitals.raid_config"

local Vitals = _G.LUI.Features.Vitals
local GroupOrdering = Vitals.GroupOrdering or {}
Vitals.GroupOrdering = GroupOrdering

local function _local_player_name()
    local local_player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if local_player == nil or local_player.GetName == nil then
        return nil
    end

    return local_player:GetName()
end

local function _is_local_player(entity, local_player_name)
    if entity == nil or entity.GetName == nil or local_player_name == nil then
        return false
    end

    return entity:GetName() == local_player_name
end

function GroupOrdering.fellowship_members(snapshot, show_self)
    local local_player_name = _local_player_name()
    local ordered = {}
    local members = snapshot.members

    for i = 1, #members do
        local member = members[i]
        if show_self == true or _is_local_player(member, local_player_name) ~= true then
            table.insert(ordered, member)
        end
    end

    return ordered
end

-- Raid rendering is slot-based: an array 1..24 of member entities with
-- false = empty cell, resolved through RaidConfig (manual layout when one
-- exists, game-order chunking otherwise).
function GroupOrdering.raid_slots(snapshot)
    return Vitals.RaidConfig.resolve_slots(snapshot)
end
