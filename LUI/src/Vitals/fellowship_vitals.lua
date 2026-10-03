-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local GroupLayout = _G.LUI.Features.Vitals.GroupLayout
local GroupSnapshot = _G.LUI.Features.Vitals.GroupSnapshot
local GroupOrdering = _G.LUI.Features.Vitals.GroupOrdering
import "LUI.src.Utils.callbacks"
local TR = _G.LUI.Locale.TR
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.hud"
import "LUI.src.Vitals.group_snapshot"
import "LUI.src.Vitals.group_ordering"
import "LUI.src.Vitals.group_layout"
import "LUI.src.Vitals.group_member_vitals"

local function _fellowship_vitals_enabled()
    return State.loaded_settings.fellowship.enabled == true
end

local function _fellowship_active(snapshot)
    return snapshot.member_count > 0 and snapshot.member_count <= 6
end

---@class FellowshipVitals : UI.Widgets.LuiHUD
local FellowshipVitals = class(UI.Widgets.LuiHUD)
Vitals.FellowshipVitals = FellowshipVitals

function FellowshipVitals:Constructor()
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "fellowship_vitals",
        title = TR["Fellowship Vitals"],
    })

    self.lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.group = nil
    self.members = {}
    self.events = {
        party_changed = nil,
        raid_changed = nil,
        member_added = nil,
        member_removed = nil,
        leader_changed = nil,
        target_changed = nil,
    }

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    local vitals_settings = State.settings.fellowship
    local initial_height = GroupLayout.member_height(vitals_settings)
    self:SetSize(vitals_settings.frame.width, initial_height)
    self:layout_move_chrome()
    self:apply_hud_position()

    self.events.party_changed = add_callback(self.lp, "PartyChanged", function()
        self:refresh_group()
    end)
    if self.lp ~= nil and self.lp.RaidChanged ~= nil then
        self.events.raid_changed = add_callback(self.lp, "RaidChanged", function()
            self:refresh_group()
        end)
    end
    self.events.target_changed = add_callback(self.lp, "TargetChanged", function()
        self:update_target_highlight()
    end)

    self:refresh_group()
end

function FellowshipVitals:set_move_mode(enabled)
    if enabled == true and _fellowship_vitals_enabled() == true then
        self:SetVisible(true)
    end

    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    self:update_members()
end

function FellowshipVitals:get_placeholder_count()
    if State.loaded_settings.fellowship.show_self_in_fellowship == true then
        return 6
    end

    return 5
end

function FellowshipVitals:detach_group_events()
    if self.group == nil then
        return
    end

    remove_callback(self.group, "MemberAdded", self.events.member_added)
    self.events.member_added = nil
    remove_callback(self.group, "MemberRemoved", self.events.member_removed)
    self.events.member_removed = nil
    remove_callback(self.group, "LeaderChanged", self.events.leader_changed)
    self.events.leader_changed = nil
end

function FellowshipVitals:attach_group_events()
    if self.group == nil then
        return
    end

    self.events.member_added = add_callback(self.group, "MemberAdded", function()
        self:update_members()
    end)
    self.events.member_removed = add_callback(self.group, "MemberRemoved", function()
        self:update_members()
    end)
    self.events.leader_changed = add_callback(self.group, "LeaderChanged", function()
        self:update_members()
    end)
end

function FellowshipVitals:refresh_group()
    local snapshot = GroupSnapshot.read(self.lp)
    local new_group = snapshot.group

    if self.group ~= new_group then
        self:detach_group_events()
        self.group = new_group
        self:attach_group_events()
    end

    self:update_members(snapshot)
    _G.LUI.Runtime.Apply.lotro_vitals_handoff()
end

function FellowshipVitals:ensure_member_windows(count)
    for i = #self.members + 1, count do
        local member_window = Vitals.GroupMemberVitals("fellowship", nil)
        member_window:SetParent(self)
        member_window:SetZOrder(10)
        member_window.entity_control:SetMouseVisible(not self:is_move_mode())
        member_window:SetVisible(false)
        table.insert(self.members, member_window)
    end
end

function FellowshipVitals:layout_members(count)
    local vitals_settings = State.settings.fellowship
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)
    local layout = vitals_settings.layout
    local total_width, total_height = GroupLayout.compute_size(count, layout.rows, layout.spacing_x, layout.spacing_y,
        member_width, member_height)

    self:SetSize(total_width, total_height)
    GroupLayout.apply_positions(self.members, count, layout.rows, layout.spacing_x, layout.spacing_y, member_width,
        member_height)

    if self:is_move_mode() then
        self:layout_move_chrome()
        self:sync_move_inputs_from_position()
    end
end

function FellowshipVitals:update_visibility(active, visible_members)
    if _fellowship_vitals_enabled() ~= true then
        self:SetVisible(false)
        return
    end
    if self:is_move_mode() then
        self:SetVisible(true)
        return
    end

    self:SetVisible(active == true and visible_members > 0)
end

function FellowshipVitals:apply_settings()
    self:apply_native_scaling()
    self:apply_hud_position()

    for i = 1, #self.members do
        self.members[i]:resize()
    end

    self:update_members()
    _G.LUI.Runtime.Apply.lotro_vitals_handoff()
end

function FellowshipVitals:current_target_name()
    if self.lp == nil or self.lp.GetTarget == nil then
        return nil
    end

    local target = self.lp:GetTarget()
    if target == nil or target.GetName == nil then
        return nil
    end

    return target:GetName()
end

function FellowshipVitals:update_target_highlight()
    local target_name = self:current_target_name()
    for i = 1, #self.members do
        self.members[i]:set_target_name(target_name)
    end
end

function FellowshipVitals:update_members(snapshot)
    local current_snapshot = snapshot or GroupSnapshot.read(self.lp)
    local active = _fellowship_active(current_snapshot)
    local ordered_members = {}
    if active == true then
        ordered_members = GroupOrdering.fellowship_members(current_snapshot,
            State.loaded_settings.fellowship.show_self_in_fellowship == true)
    end

    local move_mode = self:is_move_mode()
    local desired_count = #ordered_members
    if move_mode == true and desired_count == 0 then
        desired_count = self:get_placeholder_count()
    elseif move_mode == true and active ~= true then
        desired_count = self:get_placeholder_count()
    end

    self:ensure_member_windows(desired_count)

    if move_mode == true then
        for i = 1, #self.members do
            local member_window = self.members[i]
            member_window.entity_control:SetMouseVisible(false)
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:SetVisible(false)
        end

        self:layout_members(desired_count)
        self:update_target_highlight()
        self:update_visibility(active, #ordered_members)
        return
    end

    local leader_name = current_snapshot.leader_name
    for i = 1, #self.members do
        local member_window = self.members[i]
        member_window.entity_control:SetMouseVisible(true)

        if i <= #ordered_members then
            local entity = ordered_members[i]
            member_window:set_entity(entity)
            member_window:set_is_leader(leader_name ~= nil and entity:GetName() == leader_name)
            member_window:SetVisible(true)
        else
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:SetVisible(false)
        end
    end

    self:layout_members(desired_count)
    self:update_target_highlight()
    self:update_visibility(active, #ordered_members)
end
