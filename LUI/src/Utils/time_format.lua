-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils

-- The output shapes of these timeout formatters (d.ds / ds / dds / m:ss) are
-- mirrored by the width template in _max_time_width_sample
-- (src/Utils/timed_row_layout.lua). Changing any format here — decimals,
-- units, padding, an hours form — requires updating that template, or timer
-- bars will silently under-reserve their time-label width.
local function _format_m_ss(total_seconds)
    local total = math.floor(total_seconds)
    local minutes = math.floor(total / 60)
    local seconds = total - (minutes * 60)
    return string.format("%d:%02d", minutes, seconds)
end

local function lui_format_timeout(seconds)
    if seconds <= 0 then
        return "0.0s"
    end
    if seconds >= 60 then
        return _format_m_ss(seconds)
    end
    if seconds < 10 then
        -- Truncate instead of rounding: the countdown reads 10s -> 9.9s -> ...
        -- and never shows a "10.0s" frame.
        return string.format("%.1fs", math.floor(seconds * 10) / 10)
    end
    return string.format("%ds", math.floor(seconds))
end
Utils.lui_format_timeout = lui_format_timeout

-- Unitless variant for effect-icon overlays: on a small square the trailing
-- "s" wastes a character and the countdown is self-explanatory in context.
local function lui_format_icon_timeout(seconds)
    if seconds <= 0 then
        return "0"
    end
    if seconds >= 60 then
        return _format_m_ss(seconds)
    end
    if seconds < 10 then
        -- Truncate instead of rounding: 10 -> 9.9 -> ... with no "10.0" frame.
        return string.format("%.1f", math.floor(seconds * 10) / 10)
    end
    return string.format("%d", math.floor(seconds))
end
Utils.lui_format_icon_timeout = lui_format_icon_timeout

local function lui_format_timeout_seconds(seconds)
    if seconds <= 0 then
        return "0s"
    end

    local total = math.floor(seconds)
    if total >= 60 then
        return _format_m_ss(total)
    end
    return tostring(total) .. "s"
end
Utils.lui_format_timeout_seconds = lui_format_timeout_seconds
