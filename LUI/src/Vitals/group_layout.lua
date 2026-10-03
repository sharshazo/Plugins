-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Utils.raid_layout"

local Vitals = _G.LUI.Features.Vitals
local RaidLayout = _G.LUI.Utils.RaidLayout
local GroupLayout = Vitals.GroupLayout or {}
Vitals.GroupLayout = GroupLayout

local function _normalize_rows(rows)
    if rows == nil or rows < 1 then
        return 1
    end

    return rows
end

local function _normalize_member_count(member_count)
    if member_count == nil or member_count < 0 then
        return 0
    end

    return member_count
end

local function _grid_size_from_cells(cells, member_count, spacing_x, spacing_y, member_width, member_height)
    local normalized_count = member_count
    if normalized_count < 0 then
        normalized_count = 0
    end

    local max_column = 0
    local max_row = 0
    local used = normalized_count
    if used < 1 then
        used = 1
    end

    for i = 1, used do
        local cell = cells[i]
        if cell.column > max_column then
            max_column = cell.column
        end
        if cell.row > max_row then
            max_row = cell.row
        end
    end

    local total_width = ((max_column + 1) * member_width) + (max_column * spacing_x)
    local total_height = ((max_row + 1) * member_height) + (max_row * spacing_y)
    if total_width < member_width then
        total_width = member_width
    end
    if total_height < member_height then
        total_height = member_height
    end

    return total_width, total_height
end

function GroupLayout.member_height(vitals_settings)
    local border_width = vitals_settings.frame.border_width
    local member_height = vitals_settings.morale.height + vitals_settings.power.height - border_width
    if vitals_settings.info.enabled == true then
        member_height = member_height + vitals_settings.info.height - border_width
    end
    if member_height < 1 then
        member_height = 1
    end

    return member_height
end

function GroupLayout.compute_size(member_count, rows, spacing_x, spacing_y, member_width, member_height)
    local normalized_rows = _normalize_rows(rows)
    local normalized_count = _normalize_member_count(member_count)

    local columns = 1
    if normalized_count > 0 then
        columns = math.ceil(normalized_count / normalized_rows)
        if columns < 1 then
            columns = 1
        end
    end

    local used_rows = normalized_count
    if used_rows > normalized_rows then
        used_rows = normalized_rows
    end
    if used_rows < 1 then
        used_rows = 1
    end

    local total_width = (columns * member_width) + ((columns - 1) * spacing_x)
    local total_height = (used_rows * member_height) + ((used_rows - 1) * spacing_y)
    if total_width < member_width then
        total_width = member_width
    end
    if total_height < member_height then
        total_height = member_height
    end

    return total_width, total_height
end

function GroupLayout.apply_positions(member_windows, member_count, rows, spacing_x, spacing_y, member_width, member_height)
    local normalized_rows = _normalize_rows(rows)

    for i = 1, #member_windows do
        local member_window = member_windows[i]
        if i <= member_count then
            local index = i - 1
            local column = math.floor(index / normalized_rows)
            local row = index - (column * normalized_rows)
            local x = column * (member_width + spacing_x)
            local y = row * (member_height + spacing_y)
            member_window:SetPosition(x, y)
        else
            member_window:SetPosition(0, 0)
        end
    end
end

function GroupLayout.compute_raid_size(member_count, layout_mode, spacing_x, spacing_y, member_width, member_height)
    return _grid_size_from_cells(RaidLayout.layout_cells(layout_mode), member_count, spacing_x, spacing_y, member_width,
        member_height)
end

function GroupLayout.apply_raid_positions(member_windows, member_count, layout_mode, spacing_x, spacing_y, member_width,
                                          member_height)
    local cells = RaidLayout.layout_cells(layout_mode)

    for i = 1, #member_windows do
        local member_window = member_windows[i]
        if i <= member_count then
            local cell = cells[i]
            local x = cell.column * (member_width + spacing_x)
            local y = cell.row * (member_height + spacing_y)
            member_window:SetPosition(x, y)
        else
            member_window:SetPosition(0, 0)
        end
    end
end

function GroupLayout.compute_raid_group_size(member_count, layout_mode, spacing_x, spacing_y, member_width, member_height)
    return _grid_size_from_cells(RaidLayout.group_shape_cells(layout_mode), member_count, spacing_x, spacing_y,
        member_width, member_height)
end

function GroupLayout.compute_raid_outer_size(member_count, layout_mode, spacing_x, spacing_y, member_width, member_height,
                                             outer_border)
    local normalized_count = _normalize_member_count(member_count)
    local group_size = RaidLayout.group_size()
    local full_group_width, full_group_height = GroupLayout.compute_raid_group_size(group_size, layout_mode, spacing_x,
        spacing_y, member_width, member_height)
    local group_slot_width = full_group_width + (2 * outer_border)
    local group_slot_height = full_group_height + (2 * outer_border)
    local occupied_groups = math.ceil(normalized_count / group_size)

    if occupied_groups < 1 then
        occupied_groups = 1
    end

    local max_right = group_slot_width
    local max_bottom = group_slot_height

    for group_index = 1, occupied_groups do
        local group_first_member = ((group_index - 1) * group_size) + 1
        local group_member_count = normalized_count - group_first_member + 1
        if group_member_count > group_size then
            group_member_count = group_size
        end
        if group_member_count < 1 then
            group_member_count = 1
        end

        local group_width, group_height = GroupLayout.compute_raid_group_size(group_member_count, layout_mode, spacing_x,
            spacing_y, member_width, member_height)
        local tile = RaidLayout.group_tile_position(layout_mode, group_index)
        local right = (tile.column * group_slot_width) + group_width + (2 * outer_border)
        local bottom = (tile.row * group_slot_height) + group_height + (2 * outer_border)

        if right > max_right then
            max_right = right
        end
        if bottom > max_bottom then
            max_bottom = bottom
        end
    end

    return max_right, max_bottom
end

function GroupLayout.apply_raid_group_positions(member_windows, member_count, layout_mode, spacing_x, spacing_y,
                                                member_width, member_height)
    local cells = RaidLayout.group_shape_cells(layout_mode)

    for i = 1, #member_windows do
        local member_window = member_windows[i]
        if i <= member_count then
            local cell = cells[i]
            local x = cell.column * (member_width + spacing_x)
            local y = cell.row * (member_height + spacing_y)
            member_window:SetPosition(x, y)
        else
            member_window:SetPosition(0, 0)
        end
    end
end
