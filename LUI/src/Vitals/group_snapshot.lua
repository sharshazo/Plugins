-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.Gameplay"

local Vitals = _G.LUI.Features.Vitals
local GroupSnapshot = Vitals.GroupSnapshot or {}
Vitals.GroupSnapshot = GroupSnapshot

local function _leader_name(leader)
    if leader == nil or leader.GetName == nil then
        return nil
    end

    return leader:GetName()
end

function GroupSnapshot.read(local_player)
    if local_player == nil or local_player.GetParty == nil then
        return {
            group = nil,
            members = {},
            leader = nil,
            leader_name = nil,
            member_count = 0,
        }
    end

    local group = local_player:GetParty()
    if group == nil then
        return {
            group = nil,
            members = {},
            leader = nil,
            leader_name = nil,
            member_count = 0,
        }
    end

    local members = {}
    local total = 0
    if group.GetMemberCount ~= nil then
        total = group:GetMemberCount() or 0
    end

    for i = 1, total do
        local member = group:GetMember(i)
        if member ~= nil then
            table.insert(members, member)
        end
    end

    local leader = nil
    if group.GetLeader ~= nil then
        leader = group:GetLeader()
    end

    return {
        group = group,
        members = members,
        leader = leader,
        leader_name = _leader_name(leader),
        member_count = #members,
    }
end
