-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local LUI_ENUMS = _G.LUI.Settings.Enums
local Utils = _G.LUI.Utils
import "LUI.src.Settings.enums"
import "LUI.src.Utils.time_format"

local lui_format_timeout = Utils.lui_format_timeout
local lui_format_timeout_seconds = Utils.lui_format_timeout_seconds

local MIN_SIDE_PADDING = 2
local TEXT_SIDE_PADDING_RATIO = 0.12
local TEXT_GAP_RATIO = 0.35
local FONT_WIDTH_CACHE = {}
local WIDEST_DIGIT_CACHE = {}

-- Must stay in sync with the per-family size lists inside FONT_TO_LOTRO
-- (src/Utils/font.lua): the vertical time-font fit returns sizes from this
-- table that are rendered through FONT_TO_LOTRO. A divergence makes the fit
-- measure at a size the game renders differently, clipping vertical time text.
local AVAILABLE_FONT_SIZES = {
    verdana = { 10, 12, 14, 16, 18, 20, 22, 23 },
    verdanabold = { 16 },
    bookantiqua = { 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36 },
    bookantiquabold = { 12, 14, 18, 19, 22, 24 },
    trajanpro = { 13, 14, 15, 16, 18, 19, 20, 21, 23, 24, 25, 26, 28 },
    trajanprobold = { 16, 22, 24, 25, 30, 36 },
    arial = { 12 },
    fixedsys = { 15 },
    lucidaconsole = { 12 },
}

local FONT_WIDTH_FACTORS = {
    verdana = 1.00,
    verdanabold = 1.06,
    bookantiqua = 1.10,
    bookantiquabold = 1.13,
    trajanpro = 1.18,
    trajanprobold = 1.24,
    arial = 0.98,
    fixedsys = 0.92,
    lucidaconsole = 0.94,
}

local MONOSPACE_FONTS = {
    fixedsys = true,
    lucidaconsole = true,
}

local FONT_CHAR_WIDTH_OVERRIDES = {
    verdana = {
        ["1"] = 0.50,
        [":"] = 0.26,
    },
    verdanabold = {
        ["1"] = 0.52,
        [":"] = 0.27,
    },
}

local DIGIT_WIDTH_UNITS = {
    ["0"] = 0.58,
    ["1"] = 0.38,
    ["2"] = 0.56,
    ["3"] = 0.56,
    ["4"] = 0.58,
    ["5"] = 0.58,
    ["6"] = 0.58,
    ["7"] = 0.54,
    ["8"] = 0.60,
    ["9"] = 0.58,
}

local function _normalize_font_size(font_size)
    local size = tonumber(font_size)
    if size == nil or size <= 0 then
        return 12
    end
    return size
end

local function _normalize_font_name(font_name)
    if type(font_name) == "number" then
        font_name = LUI_ENUMS.font_name_to_string[font_name]
    end
    if type(font_name) ~= "string" then
        return "verdana"
    end
    return (font_name:gsub("[%s%-%_]", ""):lower())
end
local function _choose_font_size(size, available_sizes)
    local numeric_size = tonumber(size) or 0
    local count = #available_sizes
    if count == 0 then
        return 12
    end
    if count == 1 then
        return available_sizes[1]
    end
    if numeric_size <= available_sizes[1] then
        return available_sizes[1]
    end
    if numeric_size >= available_sizes[count] then
        return available_sizes[count]
    end

    for i = 1, count - 1 do
        local lower = available_sizes[i]
        local upper = available_sizes[i + 1]
        local midpoint = (lower + upper) / 2
        if numeric_size < midpoint then
            return lower
        elseif numeric_size == midpoint then
            return upper
        elseif numeric_size < upper then
            return upper
        end
    end

    return available_sizes[count]
end

local function _char_width_units(ch, normalized_font_name)
    local font_overrides = FONT_CHAR_WIDTH_OVERRIDES[normalized_font_name]
    if font_overrides ~= nil then
        local override_width = font_overrides[ch]
        if override_width ~= nil then
            return override_width
        end
    end

    local digit_width = DIGIT_WIDTH_UNITS[ch]
    if digit_width ~= nil then
        return digit_width
    end
    if ch == ":" then
        return 0.22
    end
    if ch == "." then
        return 0.20
    end
    if ch == "s" or ch == "S" then
        return 0.46
    end
    if ch == " " then
        return 0.30
    end
    if string.match(ch, "%l") ~= nil then
        return 0.52
    end
    if string.match(ch, "%u") ~= nil then
        return 0.66
    end
    return 0.60
end

local function _text_width_units(text, normalized_font_name)
    local value = tostring(text or "")
    if MONOSPACE_FONTS[normalized_font_name] == true then
        return string.len(value) * 0.60
    end

    local units = 0
    for i = 1, string.len(value) do
        units = units + _char_width_units(string.sub(value, i, i), normalized_font_name)
    end
    return units
end

local function _text_width_safety_padding(normalized_font_name, resolved_size)
    local padding = 1
    if normalized_font_name == "verdana" and resolved_size <= 18 then
        return padding + 1
    end
    return padding
end

local function _normalized_threshold(threshold)
    local value = tonumber(threshold)
    if value == nil or value < 0 then
        return 0
    end
    return value
end

local function _wider_text(current, candidate, normalized_font_name)
    if candidate == nil then
        return current
    end
    if current == nil then
        return candidate
    end
    if _text_width_units(candidate, normalized_font_name) > _text_width_units(current, normalized_font_name) then
        return candidate
    end
    return current
end

local function _widest_digit_in_range(normalized_font_name, min_digit, max_digit)
    local widest
    local widest_units
    for digit = min_digit, max_digit do
        local ch = tostring(digit)
        local units = _char_width_units(ch, normalized_font_name)
        if widest == nil or units > widest_units then
            widest = ch
            widest_units = units
        end
    end
    return widest
end

local function _widest_digit(normalized_font_name)
    local cached = WIDEST_DIGIT_CACHE[normalized_font_name]
    if cached == nil then
        cached = _widest_digit_in_range(normalized_font_name, 0, 9)
        WIDEST_DIGIT_CACHE[normalized_font_name] = cached
    end
    return cached
end

-- Widest possible label text for the threshold, built per display shape from
-- the font's widest digits instead of enumerating every displayable value.
-- The shapes must stay in sync with the timeout formatters in
-- src/Utils/time_format.lua (lui_format_timeout / lui_format_timeout_seconds /
-- _format_m_ss), which emit exactly d.ds / ds / dds / m:ss.
-- The leading position of each shape is capped by the threshold (threshold 5
-- can only lead with 0-5, threshold 90 only allows one minute), the remaining
-- positions use the widest digit outright. Never under-reserves; may
-- over-reserve by a fraction of a pixel where trailing digits are constrained.
local function _max_time_width_sample(limit, normalized_font_name, time_format)
    local d = _widest_digit(normalized_font_name)

    local widest
    if time_format == LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS then
        if limit >= 10 then
            -- "48s": tens capped by the threshold, ones free.
            local tens = _widest_digit_in_range(normalized_font_name, 1,
                math.min(5, math.floor(limit / 10)))
            widest = tens .. d .. "s"
        else
            -- "5s": the single digit is capped by the threshold.
            widest = _widest_digit_in_range(normalized_font_name, 0, math.floor(limit)) .. "s"
        end
    else
        -- "0.8s": the lead is capped by the threshold, the decimal is free.
        local lead = _widest_digit_in_range(normalized_font_name, 0, math.min(9, math.floor(limit)))
        widest = lead .. "." .. d .. "s"
        if limit >= 10 then
            local tens = _widest_digit_in_range(normalized_font_name, 1,
                math.min(5, math.floor(limit / 10)))
            widest = _wider_text(widest, tens .. d .. "s", normalized_font_name)
        end
    end

    if limit >= 60 then
        -- "1:08", "18:08", ...: the leading minute digit is capped by the
        -- threshold, further minute digits are free, seconds are 0-5 then 0-9.
        local max_minutes = math.floor(limit / 60)
        local minutes_text = tostring(max_minutes)
        local minute_lead = _widest_digit_in_range(normalized_font_name, 1,
            tonumber(string.sub(minutes_text, 1, 1)))
        local minute_template = minute_lead .. string.rep(d, string.len(minutes_text) - 1)
        local seconds_tens = _widest_digit_in_range(normalized_font_name, 0, 5)
        widest = _wider_text(widest, minute_template .. ":" .. seconds_tens .. d, normalized_font_name)
    end

    return widest
end

local function _time_width_cache_key(font_name, font_size, threshold, time_format)
    return table.concat({
        tostring(_normalize_font_name(font_name)),
        tostring(_normalize_font_size(font_size)),
        tostring(_normalized_threshold(threshold)),
        tostring(time_format),
    }, "|")
end

local function lui_timed_row_resolved_font_size(font_name, font_size)
    local normalized = _normalize_font_name(font_name)
    local available = AVAILABLE_FONT_SIZES[normalized]
    if available == nil then
        return 12
    end
    return _choose_font_size(_normalize_font_size(font_size), available)
end

local function lui_timed_row_estimate_text_width(text, font_name, font_size)
    local normalized = _normalize_font_name(font_name)
    local resolved_size = lui_timed_row_resolved_font_size(normalized, font_size)
    local family_factor = FONT_WIDTH_FACTORS[normalized] or 1.0
    local units = _text_width_units(text, normalized)

    local side_padding = math.max(MIN_SIDE_PADDING, math.floor((resolved_size * TEXT_SIDE_PADDING_RATIO) + 0.5))
    local width = (units * resolved_size * family_factor) + side_padding + _text_width_safety_padding(normalized, resolved_size)
    return math.max(1, math.floor(width + 0.5))
end

local function lui_timed_row_format_time(seconds, time_format)
    if time_format == LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS then
        return lui_format_timeout_seconds(seconds)
    end
    return lui_format_timeout(seconds)
end

local function lui_timed_row_text_gap(font_size)
    local size = _normalize_font_size(font_size)
    return math.max(4, math.floor((size * TEXT_GAP_RATIO) + 0.5))
end

local function lui_timed_row_time_label_width(font_name, font_size, threshold, time_format)
    local limit = _normalized_threshold(threshold)
    local normalized_font_name = _normalize_font_name(font_name)
    local cache_key = _time_width_cache_key(normalized_font_name, font_size, limit, time_format)
    local cached = FONT_WIDTH_CACHE[cache_key]
    if cached ~= nil then
        return cached
    end

    local sample = _max_time_width_sample(limit, normalized_font_name, time_format)
    local widest = lui_timed_row_estimate_text_width(sample, normalized_font_name, font_size)

    FONT_WIDTH_CACHE[cache_key] = widest
    return widest
end

local function lui_timed_row_min_name_width(font_name, font_size)
    local size = _normalize_font_size(font_size)
    local ellipsis_width = lui_timed_row_estimate_text_width("...", font_name, size)
    local short_name_width = math.floor((lui_timed_row_resolved_font_size(font_name, size) * 2.5) + 0.5)
    if short_name_width > ellipsis_width then
        return short_name_width
    end
    return ellipsis_width
end

local function _normalized_border(border_width)
    local border = tonumber(border_width)
    if border == nil or border < 0 then
        return 0
    end
    border = math.floor(border + 0.5)
    if border < 0 then
        return 0
    end
    return border
end

local function _normalized_pad(text_margin)
    local pad = tonumber(text_margin)
    if pad == nil or pad < 0 then
        return 0
    end
    return math.floor(pad + 0.5)
end

local function lui_timed_row_min_timed_bar_width(border_width, text_margin, font_name, font_size, threshold, time_format, show_time)
    local border = _normalized_border(border_width)
    local pad = _normalized_pad(text_margin)

    local name_width = lui_timed_row_min_name_width(font_name, font_size)
    if show_time ~= true then
        return border + (2 * pad) + name_width
    end

    local time_width = lui_timed_row_time_label_width(font_name, font_size, threshold, time_format)
    local gap = lui_timed_row_text_gap(font_size)

    return border + (2 * pad) + time_width + gap + name_width
end

local function lui_timed_row_min_item_width(item_h, border_width, text_margin, font_name, font_size, threshold, time_format, show_time)
    local height = tonumber(item_h)
    if height == nil or height < 1 then
        height = 1
    end

    local border = _normalized_border(border_width)
    if border * 2 >= height then
        border = math.floor((height - 1) / 2)
    end
    if border < 0 then
        border = 0
    end

    local inner_h = height - (2 * border)
    if inner_h < 1 then
        inner_h = 1
    end

    local pad = _normalized_pad(text_margin)

    local separator_width = border
    local timed_bar_width = lui_timed_row_min_timed_bar_width(
        border,
        pad,
        font_name,
        font_size,
        threshold,
        time_format,
        show_time
    )

    return (2 * border) + inner_h + separator_width + timed_bar_width
end

---------------------------------------------------------------------
-- Vertical orientation helpers
---------------------------------------------------------------------

-- Smallest visible fill strip a vertical bar must keep beside its time label.
local MIN_VERTICAL_FILL_LENGTH = 12

-- Side inset of the centered time text on a vertical bar. Tighter than the
-- horizontal text margins: centered digits need no reading margin.
local VERTICAL_TIME_PAD = 1

local function lui_timed_row_time_label_height(font_name, font_size)
    -- One line of time text plus breathing room for outlines.
    return lui_timed_row_resolved_font_size(font_name, font_size) + 6
end

-- Rect of the centered time text on a vertical bar, in bar-background space.
-- bar_length is the caller's usable main-axis length, inner_cross its usable
-- cross-axis width. Shared by every entry and preview so their label
-- placement can never diverge.
local function lui_timed_row_vertical_time_label_rect(font_name, time_font_size, bar_length, inner_cross, icon_near)
    local time_h = lui_timed_row_time_label_height(font_name, time_font_size)
    if time_h > bar_length then time_h = bar_length end

    local time_w = inner_cross - (2 * VERTICAL_TIME_PAD)
    if time_w < 1 then time_w = 1 end

    local time_y
    if icon_near == true then
        time_y = bar_length - VERTICAL_TIME_PAD - time_h
    else
        time_y = VERTICAL_TIME_PAD
    end
    if time_y < 0 then time_y = 0 end

    return VERTICAL_TIME_PAD, time_y, time_w, time_h
end

-- Largest available size of the same font family, at most the requested
-- size, whose vertical time text fits across the given thickness. The
-- configured thickness is never grown to fit the time; the font shrinks
-- instead, and nil means even the smallest family size does not fit (the
-- resolvers below then drop the time display as a last resort).
local function lui_timed_row_fit_vertical_time_font_size(thickness, border_width, font_name, font_size, threshold,
                                                         time_format)
    local border = _normalized_border(border_width)
    local available = AVAILABLE_FONT_SIZES[_normalize_font_name(font_name)]
    if available == nil then
        available = { 12 }
    end

    -- The resolved size is always a member of the family's size list; start
    -- from it and walk straight down to the smallest.
    local start_size = lui_timed_row_resolved_font_size(font_name, font_size)
    local start_index
    for i = 1, #available do
        if available[i] == start_size then
            start_index = i
            break
        end
    end

    for i = start_index, 1, -1 do
        local size = available[i]
        local time_width = lui_timed_row_time_label_width(font_name, size, threshold, time_format)
        if (2 * border) + (2 * VERTICAL_TIME_PAD) + time_width <= thickness then
            return size
        end
    end

    return nil
end

-- Min main-axis size of the bar region of a vertical item (icon excluded).
local function lui_timed_row_min_vertical_bar_length(border_width, font_name, font_size, show_time)
    local border = _normalized_border(border_width)
    if show_time ~= true then
        return border + MIN_VERTICAL_FILL_LENGTH
    end

    local time_height = lui_timed_row_time_label_height(font_name, font_size)
    local gap = lui_timed_row_text_gap(font_size)

    return border + (2 * VERTICAL_TIME_PAD) + time_height + gap + MIN_VERTICAL_FILL_LENGTH
end

-- Min main-axis size of a whole vertical item: borders + icon + separator + bar region.
local function lui_timed_row_min_vertical_item_length(thickness, border_width, font_name, font_size, show_time)
    local cross = tonumber(thickness)
    if cross == nil or cross < 1 then
        cross = 1
    end

    local border = _normalized_border(border_width)
    if border * 2 >= cross then
        border = math.floor((cross - 1) / 2)
    end
    if border < 0 then
        border = 0
    end

    local inner_cross = cross - (2 * border)
    if inner_cross < 1 then
        inner_cross = 1
    end

    local separator_height = border
    local bar_length = lui_timed_row_min_vertical_bar_length(border, font_name, font_size, show_time)

    return (2 * border) + inner_cross + separator_height + bar_length
end

---------------------------------------------------------------------
-- Footprint resolvers
---------------------------------------------------------------------
-- Single source of truth for the min-size clamps. Windows, entries, and
-- previews must all size items through these so grid cells and entry
-- self-clamps stay in exact agreement.

-- Cooldowns-style item (icon inside the item length).
-- length/thickness follow the item_w/item_h convention: length is the main
-- axis, thickness the cross axis. Returns width and height in screen axes,
-- the effective show_time, and the fitted vertical time font size. On
-- vertical bars the thickness is law: the time font shrinks (same family,
-- smaller sizes) until the text fits, and the time display is dropped when
-- even the smallest size does not.
local function lui_timed_row_resolve_item_footprint(vertical, show_time, length, thickness, border_width, text_margin,
                                                    font_name, font_size, threshold, time_format)
    if length < 1 then length = 1 end
    if thickness < 1 then thickness = 1 end

    if vertical == true then
        local time_font_size
        if show_time == true then
            time_font_size = lui_timed_row_fit_vertical_time_font_size(
                thickness, border_width, font_name, font_size, threshold, time_format)
        end
        local show = time_font_size ~= nil
        local min_length = lui_timed_row_min_vertical_item_length(
            thickness, border_width, font_name, time_font_size or font_size, show)
        if length < min_length then
            length = min_length
        end
        return thickness, length, show, time_font_size
    end

    local min_length = lui_timed_row_min_item_width(
        thickness, border_width, text_margin, font_name, font_size, threshold, time_format, show_time)
    if length < min_length then
        length = min_length
    end
    return length, thickness, show_time == true, nil
end

-- Expiring-effects-style bar (icon square outside the bar length).
-- Returns the clamped bar length, the thickness (never grown), the effective
-- show_time, and the fitted vertical time font size (see above).
local function lui_timed_row_resolve_bar_size(vertical, show_time, bar_length, thickness, border_width, text_margin,
                                              font_name, font_size, threshold, time_format)
    if vertical == true then
        local time_font_size
        if show_time == true then
            time_font_size = lui_timed_row_fit_vertical_time_font_size(
                thickness, border_width, font_name, font_size, threshold, time_format)
        end
        local show = time_font_size ~= nil
        local min_length = lui_timed_row_min_vertical_bar_length(
            border_width, font_name, time_font_size or font_size, show)
        if bar_length < min_length then
            bar_length = min_length
        end
        return bar_length, thickness, show, time_font_size
    end

    local min_length = lui_timed_row_min_timed_bar_width(
        border_width, text_margin, font_name, font_size, threshold, time_format, show_time)
    if bar_length < min_length then
        bar_length = min_length
    end
    return bar_length, thickness, show_time == true, nil
end

Utils.lui_timed_row_resolved_font_size = lui_timed_row_resolved_font_size
Utils.lui_timed_row_estimate_text_width = lui_timed_row_estimate_text_width
Utils.lui_timed_row_format_time = lui_timed_row_format_time
Utils.lui_timed_row_text_gap = lui_timed_row_text_gap
Utils.lui_timed_row_time_label_width = lui_timed_row_time_label_width
Utils.lui_timed_row_min_name_width = lui_timed_row_min_name_width
Utils.lui_timed_row_min_timed_bar_width = lui_timed_row_min_timed_bar_width
Utils.lui_timed_row_min_item_width = lui_timed_row_min_item_width
Utils.lui_timed_row_time_label_height = lui_timed_row_time_label_height
Utils.lui_timed_row_vertical_time_label_rect = lui_timed_row_vertical_time_label_rect
Utils.lui_timed_row_fit_vertical_time_font_size = lui_timed_row_fit_vertical_time_font_size
Utils.lui_timed_row_min_vertical_bar_length = lui_timed_row_min_vertical_bar_length
Utils.lui_timed_row_min_vertical_item_length = lui_timed_row_min_vertical_item_length
Utils.lui_timed_row_resolve_item_footprint = lui_timed_row_resolve_item_footprint
Utils.lui_timed_row_resolve_bar_size = lui_timed_row_resolve_bar_size

-- Text pad inside expiring-effects bars; shared by the windows, entries, and
-- previews so min-size math and label layout can never disagree.
Utils.lui_timed_row_label_pad = 3

-- Side inset of the centered time text on vertical bars.
Utils.lui_timed_row_vertical_time_pad = VERTICAL_TIME_PAD

Utils.lui_timed_row_time_format = {
    AUTO = LUI_ENUMS.cooldown_time_format.AUTO,
    WHOLE_SECONDS = LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS,
}

Utils.lui_cooldown_resolved_font_size = lui_timed_row_resolved_font_size
Utils.lui_cooldown_estimate_text_width = lui_timed_row_estimate_text_width
Utils.lui_format_cooldown_time = lui_timed_row_format_time
Utils.lui_cooldown_text_gap = lui_timed_row_text_gap
Utils.lui_cooldown_time_label_width = lui_timed_row_time_label_width
Utils.lui_cooldown_min_name_width = lui_timed_row_min_name_width
Utils.lui_cooldown_min_timed_bar_width = lui_timed_row_min_timed_bar_width
Utils.lui_cooldown_min_item_width = lui_timed_row_min_item_width
