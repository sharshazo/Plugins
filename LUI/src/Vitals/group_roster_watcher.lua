-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Roster watcher: the live client does not reliably fire party/raid events
-- (fellowship-to-raid conversion in particular can swap the party object
-- without a PartyChanged), so joins and leaves can go unnoticed by the
-- event-driven refresh. This safety net re-reads GetParty() once per second
-- and triggers the normal refresh path when the roster identity changes;
-- refresh_group() also re-binds the group events, healing stale bindings.

import "LUI.src.Vitals.group_snapshot"
import "LUI.src.UI.Widgets.timer"

local Vitals = _G.LUI.Features.Vitals
local GroupRosterWatcher = Vitals.GroupRosterWatcher or {}
Vitals.GroupRosterWatcher = GroupRosterWatcher

local GroupSnapshot = Vitals.GroupSnapshot
local Widgets = _G.LUI.UI.Widgets
local Windows = _G.LUI.Runtime.Windows
import "Turbine.Gameplay"

local POLL_INTERVAL = 1.0

local _timer = nil
local _last_identity = nil

local function _roster_identity()
    local snapshot = GroupSnapshot.read(Turbine.Gameplay.LocalPlayer.GetInstance())
    local members = snapshot.members
    local names = {}
    for i = 1, #members do
        local member = members[i]
        if member.GetName ~= nil then
            names[#names + 1] = member:GetName()
        end
    end
    return snapshot.member_count .. ":" .. table.concat(names, ";")
end

local function _check()
    local identity = _roster_identity()
    if identity == _last_identity then
        return
    end
    _last_identity = identity

    Windows.fellowship_vitals:refresh_group()
    Windows.raid_vitals:refresh_group()

    local config_window = Windows.raid_config
    if config_window ~= nil and config_window:IsVisible() == true then
        config_window:refresh_cells()
    end
end

function GroupRosterWatcher.install()
    _last_identity = _roster_identity()
    _timer = Widgets.LuiTimer(_check)
    _timer:start(POLL_INTERVAL)
end

function GroupRosterWatcher.uninstall()
    if _timer == nil then
        return
    end
    _timer:stop()
    _timer = nil
end
