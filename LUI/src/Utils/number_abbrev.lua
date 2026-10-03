-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local Utils = _G.LUI.Utils
import "LUI.src.Settings.enums"

local THOUSAND = 1000
local MILLION = 1000000
local BILLION = 1000000000
local _preview_settings = nil
local DECIMAL_LIMITS = {
    [LUI_ENUMS.abbrev_width.CHARS_3] = 10,
    [LUI_ENUMS.abbrev_width.CHARS_4] = 100,
}

local METHOD_SUFFIXES = {
    [LUI_ENUMS.abbrev_method.K_M_G] = {
        [THOUSAND] = "k",
        [MILLION] = "M",
        [BILLION] = "G",
    },
    [LUI_ENUMS.abbrev_method.K_M_B] = {
        [THOUSAND] = "k",
        [MILLION] = "M",
        [BILLION] = "B",
    },
    [LUI_ENUMS.abbrev_method.K_m_M] = {
        [THOUSAND] = "k",
        [MILLION] = "m",
        [BILLION] = "M",
    },
    [LUI_ENUMS.abbrev_method.E3_E6_E9] = {
        [THOUSAND] = "e3",
        [MILLION] = "e6",
        [BILLION] = "e9",
    },
}

local function _round_string(value)
    local abs_value = math.abs(value)
    local rounded = math.floor(abs_value + 0.5)
    if value < 0 then
        return "-" .. tostring(rounded)
    end
    return tostring(rounded)
end

local function _current_settings()
    if _preview_settings ~= nil then
        return _preview_settings
    end
    return State.settings.global.number_abbrev
end

local function _format_scaled(value, width)
    local whole = math.floor(value)
    if whole < DECIMAL_LIMITS[width] then
        local decimal = math.floor((value - whole) * 10)
        return tostring(whole) .. "." .. tostring(decimal)
    end
    return tostring(whole)
end

local function _pick_unit(abs_value, scale)
    scale = scale or 1

    if abs_value >= (BILLION * scale) then
        return BILLION
    end
    if abs_value >= (MILLION * scale) then
        return MILLION
    end
    if abs_value >= (THOUSAND * scale) then
        return THOUSAND
    end
    return 1
end

local function _abbrev_number(value)
    local n = value
    local settings = _current_settings()
    local method_suffixes = METHOD_SUFFIXES[settings.method]
    local abs_value = math.abs(n)
    local scale = 10 ^ (settings.digits - 3)
    local unit = _pick_unit(abs_value, scale)
    if not settings.enabled or unit == 1 then
        return _round_string(n)
    end

    local text = _format_scaled(abs_value / unit, settings.width) .. method_suffixes[unit]
    if n < 0 then
        return "-" .. text
    end
    return text
end

local function _abbrev_gold(value)
    return _abbrev_number(value)
end

function Utils.lui_abbrev_number(value)
    return _abbrev_number(value)
end

function Utils.lui_set_number_abbrev_preview_settings(settings)
    _preview_settings = settings
end

function Utils.lui_clear_number_abbrev_preview_settings()
    _preview_settings = nil
end

function Utils.lui_abbrev_gold(value)
    return _abbrev_gold(value)
end
