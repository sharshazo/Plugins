-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local Utils = _G.LUI.Utils
import "Turbine.UI"
import "LUI.src.Utils.timed_row_layout"

local lui_timed_row_resolved_font_size = Utils.lui_timed_row_resolved_font_size
local lui_timed_row_estimate_text_width = Utils.lui_timed_row_estimate_text_width

local function _text_alignment(value)
    return LUI_TO_LOTRO.text_alignment[value]
end

local function _resolved_font_size(font_name, font_size)
    return lui_timed_row_resolved_font_size(font_name, font_size)
end

local function _normalize_offset(value)
    local n = value
    if type(n) ~= "number" then
        n = tonumber(n)
    end
    if n == nil then
        n = 0
    end
    return math.floor(n + 0.5)
end

local function _line_count(text)
    local value = tostring(text or "")
    local count = 1
    for _ in string.gmatch(value, "\n") do
        count = count + 1
    end
    return count
end

local function _longest_line_width(text, font_name, font_size)
    local value = tostring(text or "")
    local max_width = 1
    local line_start = 1

    for i = 1, string.len(value) do
        if string.sub(value, i, i) == "\n" then
            local line = string.sub(value, line_start, i - 1)
            local width = lui_timed_row_estimate_text_width(line, font_name, font_size)
            if width > max_width then
                max_width = width
            end
            line_start = i + 1
        end
    end

    local tail = string.sub(value, line_start)
    local tail_width = lui_timed_row_estimate_text_width(tail, font_name, font_size)
    if tail_width > max_width then
        max_width = tail_width
    end

    return max_width
end

local function _estimated_label_height(text, font_name, font_size)
    local resolved_size = _resolved_font_size(font_name, font_size)
    local lines = _line_count(text)
    local line_height = math.max(1, math.floor((resolved_size * 1.2) + 0.5))
    local vertical_padding = math.max(1, math.floor((resolved_size * 0.2) + 0.5))
    return math.max(1, (lines * line_height) + vertical_padding)
end

local function _anchor_x(anchor, area_width, rect_width)
    if anchor == LUI_ENUMS.vitals_label_anchor.TOP or anchor == LUI_ENUMS.vitals_label_anchor.CENTER or
        anchor == LUI_ENUMS.vitals_label_anchor.BOTTOM then
        return math.floor((area_width - rect_width) / 2)
    end
    if anchor == LUI_ENUMS.vitals_label_anchor.TOP_RIGHT or anchor == LUI_ENUMS.vitals_label_anchor.RIGHT or
        anchor == LUI_ENUMS.vitals_label_anchor.BOTTOM_RIGHT then
        return area_width - rect_width
    end
    return 0
end

local function _anchor_y(anchor, area_height, rect_height)
    if anchor == LUI_ENUMS.vitals_label_anchor.LEFT or anchor == LUI_ENUMS.vitals_label_anchor.CENTER or
        anchor == LUI_ENUMS.vitals_label_anchor.RIGHT then
        return math.floor((area_height - rect_height) / 2)
    end
    if anchor == LUI_ENUMS.vitals_label_anchor.BOTTOM_LEFT or anchor == LUI_ENUMS.vitals_label_anchor.BOTTOM or
        anchor == LUI_ENUMS.vitals_label_anchor.BOTTOM_RIGHT then
        return area_height - rect_height
    end
    return 0
end

function Utils.lui_vitals_layout_label(label, width, height, anchor, width_mode, text_alignment, x_offset, y_offset,
                                       font_name, font_size, text)
    local rendered_text = tostring(text or "")
    local rect_width = width
    if width_mode == LUI_ENUMS.vitals_label_width_mode.AUTO then
        rect_width = math.min(width, _longest_line_width(rendered_text, font_name, font_size))
    end
    local rect_height = math.min(height, _estimated_label_height(rendered_text, font_name, font_size))
    local left = _anchor_x(anchor, width, rect_width) + _normalize_offset(x_offset)
    local top = _anchor_y(anchor, height, rect_height) + _normalize_offset(y_offset)

    label:SetPosition(left, top)
    label:SetSize(math.max(1, rect_width), math.max(1, rect_height))
    label:SetTextAlignment(_text_alignment(text_alignment))
    label:SetMultiline(true)
end
