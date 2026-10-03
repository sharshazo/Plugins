-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local LUI_ENUMS = _G.LUI.Settings.Enums
local Utils = _G.LUI.Utils
local RaidLayout = Utils.RaidLayout or {}
Utils.RaidLayout = RaidLayout

local RAID_GROUP_SIZE = 6
local RAID_GROUP_COUNT = 4
local LAYOUT_CELLS = {}
local GROUP_CELLS = {}
local GROUP_SHAPE_CELLS = {}
local GROUP_SHAPE_DIMENSIONS = {}

local function _build_group_cells(start_column, start_row, columns_per_group)
    local cells = {}

    for i = 1, RAID_GROUP_SIZE do
        local index = i - 1
        cells[i] = {
            column = start_column + (index % columns_per_group),
            row = start_row + math.floor(index / columns_per_group),
        }
    end

    return cells
end

local function _copy_cells(cells)
    local out = {}
    for i = 1, #cells do
        local cell = cells[i]
        out[i] = {
            column = cell.column,
            row = cell.row,
        }
    end
    return out
end

local function _append_cells(layout_cells, group_cells)
    for i = 1, #group_cells do
        layout_cells[#layout_cells + 1] = group_cells[i]
    end
end

local function _normalize_group_shape_cells(group_cells)
    local min_column = group_cells[1].column
    local min_row = group_cells[1].row

    for i = 2, #group_cells do
        local cell = group_cells[i]
        if cell.column < min_column then
            min_column = cell.column
        end
        if cell.row < min_row then
            min_row = cell.row
        end
    end

    local normalized = {}
    for i = 1, #group_cells do
        local cell = group_cells[i]
        normalized[i] = {
            column = cell.column - min_column,
            row = cell.row - min_row,
        }
    end

    return normalized
end

local function _cells_dimensions(cells)
    local max_column = 0
    local max_row = 0

    for i = 1, #cells do
        local cell = cells[i]
        if cell.column > max_column then
            max_column = cell.column
        end
        if cell.row > max_row then
            max_row = cell.row
        end
    end

    return {
        columns = max_column + 1,
        rows = max_row + 1,
    }
end

local function _register_layout(layout_mode, group_specs)
    local layout_cells = {}
    local layout_groups = {}

    for i = 1, #group_specs do
        local spec = group_specs[i]
        local group_cells = _build_group_cells(spec.column, spec.row, spec.columns_per_group)
        layout_groups[i] = group_cells
        _append_cells(layout_cells, group_cells)
    end

    LAYOUT_CELLS[layout_mode] = layout_cells
    GROUP_CELLS[layout_mode] = layout_groups
    GROUP_SHAPE_CELLS[layout_mode] = _normalize_group_shape_cells(layout_groups[1])
    GROUP_SHAPE_DIMENSIONS[layout_mode] = _cells_dimensions(GROUP_SHAPE_CELLS[layout_mode])
end

local function _build_layouts()
    local e = LUI_ENUMS.raid_layout_mode

    _register_layout(e.TWO_COLUMNS, {
        { column = 0, row = 0, columns_per_group = 2 },
        { column = 0, row = 3, columns_per_group = 2 },
        { column = 0, row = 6, columns_per_group = 2 },
        { column = 0, row = 9, columns_per_group = 2 },
    })

    _register_layout(e.THREE_COLUMNS, {
        { column = 0, row = 0, columns_per_group = 3 },
        { column = 0, row = 2, columns_per_group = 3 },
        { column = 0, row = 4, columns_per_group = 3 },
        { column = 0, row = 6, columns_per_group = 3 },
    })

    _register_layout(e.FOUR_COLUMNS_MODE_1, {
        { column = 0, row = 0, columns_per_group = 1 },
        { column = 1, row = 0, columns_per_group = 1 },
        { column = 2, row = 0, columns_per_group = 1 },
        { column = 3, row = 0, columns_per_group = 1 },
    })

    _register_layout(e.FOUR_COLUMNS_MODE_2, {
        { column = 0, row = 0, columns_per_group = 2 },
        { column = 2, row = 0, columns_per_group = 2 },
        { column = 0, row = 3, columns_per_group = 2 },
        { column = 2, row = 3, columns_per_group = 2 },
    })

    _register_layout(e.SIX_COLUMNS_MODE_1, {
        { column = 0, row = 0, columns_per_group = 6 },
        { column = 0, row = 1, columns_per_group = 6 },
        { column = 0, row = 2, columns_per_group = 6 },
        { column = 0, row = 3, columns_per_group = 6 },
    })

    _register_layout(e.SIX_COLUMNS_MODE_2, {
        { column = 0, row = 0, columns_per_group = 3 },
        { column = 3, row = 0, columns_per_group = 3 },
        { column = 0, row = 2, columns_per_group = 3 },
        { column = 3, row = 2, columns_per_group = 3 },
    })
end

_build_layouts()

function RaidLayout.group_size()
    return RAID_GROUP_SIZE
end

function RaidLayout.group_count()
    return RAID_GROUP_COUNT
end

function RaidLayout.member_group_index(member_index)
    return math.floor((member_index - 1) / RAID_GROUP_SIZE) + 1
end

function RaidLayout.layout_cells(layout_mode)
    local cells = LAYOUT_CELLS[layout_mode]
    if cells == nil then
        error("Unknown raid layout mode: " .. tostring(layout_mode))
    end

    return cells
end

function RaidLayout.group_cells(layout_mode, group_index)
    local layout_groups = GROUP_CELLS[layout_mode]
    if layout_groups == nil then
        error("Unknown raid layout mode: " .. tostring(layout_mode))
    end

    local group_cells = layout_groups[group_index]
    if group_cells == nil then
        error("Unknown raid group index: " .. tostring(group_index))
    end

    return group_cells
end

function RaidLayout.group_shape_cells(layout_mode)
    local cells = GROUP_SHAPE_CELLS[layout_mode]
    if cells == nil then
        error("Unknown raid layout mode: " .. tostring(layout_mode))
    end

    return cells
end

function RaidLayout.group_origin_cell(layout_mode, group_index)
    local group_cells = RaidLayout.group_cells(layout_mode, group_index)
    return group_cells[1]
end

function RaidLayout.group_shape_dimensions(layout_mode)
    local dimensions = GROUP_SHAPE_DIMENSIONS[layout_mode]
    if dimensions == nil then
        error("Unknown raid layout mode: " .. tostring(layout_mode))
    end

    return dimensions
end

function RaidLayout.group_tile_position(layout_mode, group_index)
    local origin = RaidLayout.group_origin_cell(layout_mode, group_index)
    local dimensions = RaidLayout.group_shape_dimensions(layout_mode)

    return {
        column = math.floor(origin.column / dimensions.columns),
        row = math.floor(origin.row / dimensions.rows),
    }
end

function RaidLayout.copy_cells(cells)
    return _copy_cells(cells)
end
