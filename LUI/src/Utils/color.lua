-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils
import "Turbine.UI"

local function _clamp_0_255(value)
    if value < 0 then return 0 end
    if value > 255 then return 255 end
    return value
end

local function lui_clamp_ratio(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end
Utils.lui_clamp_ratio = lui_clamp_ratio

local function lui_dim_color(color, dimming)
    local factor = 1 - lui_clamp_ratio(dimming)
    return Turbine.UI.Color(
        color.A,
        color.R * factor,
        color.G * factor,
        color.B * factor
    )
end
Utils.lui_dim_color = lui_dim_color

local function lui_lerp_number(start_value, end_value, ratio)
    return start_value + ((end_value - start_value) * lui_clamp_ratio(ratio))
end
Utils.lui_lerp_number = lui_lerp_number

local function lui_lerp_color(start_color, end_color, ratio)
    local t = lui_clamp_ratio(ratio)
    return Turbine.UI.Color(
        lui_lerp_number(start_color.A, end_color.A, t),
        lui_lerp_number(start_color.R, end_color.R, t),
        lui_lerp_number(start_color.G, end_color.G, t),
        lui_lerp_number(start_color.B, end_color.B, t)
    )
end
Utils.lui_lerp_color = lui_lerp_color

local function lui_apply_opacity_to_color(color, opacity)
    local alpha = lui_clamp_ratio(color.A * lui_clamp_ratio(opacity))
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end
Utils.lui_apply_opacity_to_color = lui_apply_opacity_to_color

local function lui_gradient_morale_color(percent, full_color, mid_color, low_color)
    local t = lui_clamp_ratio(percent)
    if t <= 0.5 then
        return lui_lerp_color(low_color, mid_color, t * 2)
    end
    return lui_lerp_color(mid_color, full_color, (t - 0.5) * 2)
end
Utils.lui_gradient_morale_color = lui_gradient_morale_color

local function lui_color_to_hex(color)
    local r = _clamp_0_255(math.floor((color.R * 255) + 0.5))
    local g = _clamp_0_255(math.floor((color.G * 255) + 0.5))
    local b = _clamp_0_255(math.floor((color.B * 255) + 0.5))

    return string.format("#%02X%02X%02X", r, g, b)
end
Utils.lui_color_to_hex = lui_color_to_hex

local function lui_hex_to_color(text)
    if type(text) ~= "string" then
        return nil
    end

    local t = text:gsub("%s+", "")
    if t:sub(1, 1) == "#" then
        t = t:sub(2)
    end

    if string.len(t) ~= 6 then
        return nil
    end

    if not t:match("^[0-9a-fA-F]+$") then
        return nil
    end

    local r = tonumber(t:sub(1, 2), 16)
    local g = tonumber(t:sub(3, 4), 16)
    local b = tonumber(t:sub(5, 6), 16)

    if r == nil or g == nil or b == nil then
        return nil
    end

    return Turbine.UI.Color(r / 255, g / 255, b / 255)
end
Utils.lui_hex_to_color = lui_hex_to_color
