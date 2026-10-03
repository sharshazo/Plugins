-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local GroupLayout = _G.LUI.Features.Vitals.GroupLayout
local GroupSnapshot = _G.LUI.Features.Vitals.GroupSnapshot
local GroupOrdering = _G.LUI.Features.Vitals.GroupOrdering
local RaidLayout = _G.LUI.Utils.RaidLayout
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
import "LUI.src.Utils.raid_layout"
import "LUI.src.Vitals.group_snapshot"
import "LUI.src.Vitals.group_ordering"
import "LUI.src.Vitals.group_layout"
import "LUI.src.Vitals.group_member_vitals"
import "LUI.src.Vitals.raid_group_vitals"

local function _raid_vitals_enabled()
    return State.loaded_settings.raid.enabled == true
end

local function _raid_split_enabled()
    return State.loaded_settings.raid.split_by_group == true
end

local function _raid_active(snapshot)
    return snapshot.member_count >= 7
end

local function _set_border_visible(border, visible)
    border.top:SetVisible(visible)
    border.bottom:SetVisible(visible)
    border.left:SetVisible(visible)
    border.right:SetVisible(visible)
end

local function _apply_border(border, x, y, width, height, thickness, color)
    if thickness <= 0 or width <= 0 or height <= 0 then
        _set_border_visible(border, false)
        return
    end

    border.top:SetBackColor(color)
    border.bottom:SetBackColor(color)
    border.left:SetBackColor(color)
    border.right:SetBackColor(color)

    border.top:SetPosition(x, y)
    border.top:SetSize(width, thickness)
    border.bottom:SetPosition(x, y + height - thickness)
    border.bottom:SetSize(width, thickness)
    border.left:SetPosition(x, y)
    border.left:SetSize(thickness, height)
    border.right:SetPosition(x + width - thickness, y)
    border.right:SetSize(thickness, height)
    _set_border_visible(border, true)
end

---@class RaidVitals : UI.Widgets.LuiHUD
local RaidVitals = class(UI.Widgets.LuiHUD)
Vitals.RaidVitals = RaidVitals

function RaidVitals:Constructor()
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "raid_vitals",
        title = TR["Raid Vitals"],
    })

    self.lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.group = nil
    self.members = {}
    self.group_borders = {}
    self.group_windows = {
        Vitals.RaidGroupVitalsWindow("a", 1),
        Vitals.RaidGroupVitalsWindow("b", 2),
        Vitals.RaidGroupVitalsWindow("c", 3),
        Vitals.RaidGroupVitalsWindow("d", 4),
    }
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

    for i = 1, RaidLayout.group_count() do
        local border = {
            top = Turbine.UI.Control(),
            bottom = Turbine.UI.Control(),
            left = Turbine.UI.Control(),
            right = Turbine.UI.Control(),
        }
        border.top:SetParent(self)
        border.bottom:SetParent(self)
        border.left:SetParent(self)
        border.right:SetParent(self)
        border.top:SetMouseVisible(false)
        border.bottom:SetMouseVisible(false)
        border.left:SetMouseVisible(false)
        border.right:SetMouseVisible(false)
        border.top:SetZOrder(30)
        border.bottom:SetZOrder(30)
        border.left:SetZOrder(30)
        border.right:SetZOrder(30)
        _set_border_visible(border, false)
        self.group_borders[i] = border
    end

    local vitals_settings = State.settings.raid
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

function RaidVitals:set_move_mode(enabled)
    if enabled == true and _raid_vitals_enabled() == true and _raid_split_enabled() ~= true then
        self:SetVisible(true)
    end

    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    for i = 1, #self.group_windows do
        self.group_windows[i]:set_move_mode(enabled)
    end
    self:update_members()
end

function RaidVitals:get_placeholder_count()
    return 24
end

function RaidVitals:detach_group_events()
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

function RaidVitals:attach_group_events()
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

function RaidVitals:refresh_group()
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

function RaidVitals:ensure_member_windows(count)
    for i = #self.members + 1, count do
        local member_window = Vitals.GroupMemberVitals("raid", nil)
        member_window:SetParent(self)
        member_window:SetZOrder(10)
        member_window.entity_control:SetMouseVisible(not self:is_move_mode())
        member_window:SetVisible(false)
        table.insert(self.members, member_window)
    end
end

function RaidVitals:layout_members(count)
    local vitals_settings = State.settings.raid
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)
    local layout = vitals_settings.layout
    local outer_border = vitals_settings.group_border_width
    local shape_cells = RaidLayout.group_shape_cells(layout.mode)
    local full_group_width, full_group_height = GroupLayout.compute_raid_group_size(RaidLayout.group_size(), layout.mode,
        layout.spacing_x, layout.spacing_y, member_width, member_height)
    local group_slot_width = full_group_width + (2 * outer_border)
    local group_slot_height = full_group_height + (2 * outer_border)

    for i = 1, count do
        local member_window = self.members[i]
        local member_index_in_group = ((i - 1) % RaidLayout.group_size()) + 1
        local group_index = RaidLayout.member_group_index(i)
        local tile = RaidLayout.group_tile_position(layout.mode, group_index)
        local cell = shape_cells[member_index_in_group]
        local x = (tile.column * group_slot_width) + outer_border + (cell.column * (member_width + layout.spacing_x))
        local y = (tile.row * group_slot_height) + outer_border + (cell.row * (member_height + layout.spacing_y))
        member_window:SetPosition(x, y)
    end
    for i = count + 1, #self.members do
        self.members[i]:SetPosition(0, 0)
    end

    local total_width, total_height = GroupLayout.compute_raid_outer_size(count, layout.mode, layout.spacing_x,
        layout.spacing_y, member_width, member_height, outer_border)
    self:SetSize(total_width, total_height)

    if self:is_move_mode() then
        self:layout_move_chrome()
        self:sync_move_inputs_from_position()
    end
end

-- Borders wrap each group's occupied extent: the cells up to the last
-- occupied slot in the group, so manual layouts keep gaps inside the frame.
function RaidVitals:update_group_borders(slots)
    if self:is_move_mode() == true or _raid_split_enabled() == true then
        for i = 1, #self.group_borders do
            _set_border_visible(self.group_borders[i], false)
        end
        return
    end

    local vitals_settings = State.settings.raid
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)
    local layout = vitals_settings.layout
    local border_width = vitals_settings.group_border_width
    local group_size = RaidLayout.group_size()
    local full_group_width, full_group_height = GroupLayout.compute_raid_group_size(group_size, layout.mode,
        layout.spacing_x, layout.spacing_y, member_width, member_height)
    local group_slot_width = full_group_width + (2 * border_width)
    local group_slot_height = full_group_height + (2 * border_width)

    for group_index = 1, #self.group_borders do
        local group_first_member = ((group_index - 1) * group_size) + 1
        local group_member_count = 0
        for offset = 0, group_size - 1 do
            local entity = slots[group_first_member + offset]
            if entity ~= nil and entity ~= false then
                group_member_count = offset + 1
            end
        end

        if group_member_count <= 0 then
            _set_border_visible(self.group_borders[group_index], false)
        else
            local group_tile = RaidLayout.group_tile_position(layout.mode, group_index)
            local group_x = group_tile.column * group_slot_width
            local group_y = group_tile.row * group_slot_height
            local group_width, group_height = GroupLayout.compute_raid_group_size(group_member_count, layout.mode,
                layout.spacing_x, layout.spacing_y, member_width, member_height)
            _apply_border(self.group_borders[group_index], group_x, group_y,
                group_width + (2 * border_width), group_height + (2 * border_width), border_width,
                self.group_windows[group_index]:get_border_color())
        end
    end
end

function RaidVitals:update_visibility(active, visible_members)
    if _raid_vitals_enabled() ~= true or _raid_split_enabled() == true then
        self:SetVisible(false)
        return
    end
    if self:is_move_mode() then
        self:SetVisible(true)
        return
    end

    self:SetVisible(active == true and visible_members > 0)
end

function RaidVitals:apply_settings()
    self:apply_native_scaling()
    self:apply_hud_position()

    for i = 1, #self.members do
        self.members[i]:resize()
    end
    for i = 1, #self.group_windows do
        self.group_windows[i]:apply_settings()
    end

    self:update_members()
    _G.LUI.Runtime.Apply.lotro_vitals_handoff()
end

function RaidVitals:group_border_color(member_index)
    local group_index = RaidLayout.member_group_index(member_index)
    return self.group_windows[group_index]:get_border_color()
end

function RaidVitals:current_target_name()
    if self.lp == nil or self.lp.GetTarget == nil then
        return nil
    end

    local target = self.lp:GetTarget()
    if target == nil or target.GetName == nil then
        return nil
    end

    return target:GetName()
end

function RaidVitals:update_target_highlight()
    local target_name = self:current_target_name()
    for i = 1, #self.members do
        self.members[i]:set_target_name(target_name)
    end
    for i = 1, #self.group_windows do
        self.group_windows[i]:set_target_name(target_name)
    end
end

function RaidVitals:hide_combined_members()
    for i = 1, #self.members do
        local member_window = self.members[i]
        member_window.entity_control:SetMouseVisible(false)
        member_window:set_entity(nil)
        member_window:set_is_leader(false)
        member_window:SetVisible(false)
    end
    for i = 1, #self.group_borders do
        _set_border_visible(self.group_borders[i], false)
    end

    self:SetVisible(false)
end

function RaidVitals:update_combined_members(active, slots, occupied, last_slot, leader_name)
    if _raid_split_enabled() == true then
        self:hide_combined_members()
        return
    end

    local move_mode = self:is_move_mode()
    local desired_count = last_slot
    if move_mode == true and (desired_count == 0 or active ~= true) then
        desired_count = self:get_placeholder_count()
    end

    self:ensure_member_windows(desired_count)

    if move_mode == true then
        for i = 1, #self.members do
            local member_window = self.members[i]
            member_window.entity_control:SetMouseVisible(false)
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:set_frame_border_color_override(nil)
            member_window:SetVisible(false)
        end

        self:layout_members(desired_count)
        self:update_group_borders(slots)
        self:update_target_highlight()
        self:update_visibility(active, occupied)
        return
    end

    for i = 1, #self.members do
        local member_window = self.members[i]
        member_window.entity_control:SetMouseVisible(true)
        member_window:set_frame_border_color_override(nil)

        local entity = nil
        if i <= last_slot and slots[i] ~= false then
            entity = slots[i]
        end
        if entity ~= nil then
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
    self:update_group_borders(slots)
    self:update_target_highlight()
    self:update_visibility(active, occupied)
end

function RaidVitals:update_split_members(active, slots, leader_name)
    local group_size = RaidLayout.group_size()

    for group_index = 1, #self.group_windows do
        local first_member = ((group_index - 1) * group_size) + 1
        local group_slots = {}
        for offset = 0, group_size - 1 do
            local entity = slots[first_member + offset]
            if entity == nil then
                entity = false
            end
            group_slots[offset + 1] = entity
        end

        self.group_windows[group_index]:update_members(group_slots, leader_name, active)
    end
end

function RaidVitals:update_members(snapshot)
    local current_snapshot = snapshot or GroupSnapshot.read(self.lp)
    local active = _raid_active(current_snapshot)
    local slots = {}
    local occupied = 0
    local last_slot = 0
    if active == true then
        slots = GroupOrdering.raid_slots(current_snapshot)
        for i = 1, #slots do
            if slots[i] ~= false then
                occupied = occupied + 1
                last_slot = i
            end
        end
    end

    local leader_name = current_snapshot.leader_name
    self:update_combined_members(active, slots, occupied, last_slot, leader_name)
    self:update_split_members(active, slots, leader_name)
    self:update_target_highlight()
end
