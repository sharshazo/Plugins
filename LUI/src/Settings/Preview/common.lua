-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local State = _G.LUI.Settings.State
local Preview = _G.LUI.Settings.Preview

local Common = Preview.Common or {}
Preview.Common = Common
Common.PREVIEW_WRATH_MAX = 100

function Common.scaled_size(value)
    return value * State.settings.global.scale
end

function Common.scaled_int(value)
    return math.floor(Common.scaled_size(value) + 0.5)
end

function Common.scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, Common.scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(Common.scaled_size(size)))
    end
    return font
end

function Common.require_font(name, size)
    local font = FONT_TO_LOTRO(name, size)
    if font == nil then
        error("Missing font: " .. tostring(name) .. " " .. tostring(size))
    end
    return font
end

function Common.hex_to_color(value)
    return lui_hex_to_color(value)
end

function Common.dim_color(color, amount)
    return lui_dim_color(color, amount)
end

function Common.require_number(raw_value, key)
    local n = raw_value
    if type(n) ~= "number" then
        n = tonumber(n)
    end
    if n == nil then
        error("Invalid preview number for " .. tostring(key) .. ": " .. tostring(raw_value))
    end
    return n
end

function Common.require_control_text(controls, key)
    return controls[key].tb:GetText()
end

function Common.require_control_number(controls, key)
    local text = Common.require_control_text(controls, key)
    if type(text) == "string" and string.len(text:gsub("%s+", "")) == 0 then
        return Common.require_number(controls[key].load_fn(), key)
    end
    return Common.require_number(text, key)
end

function Common.require_control_color(controls, key)
    local text = Common.require_control_text(controls, key)
    local color = Common.hex_to_color(text)
    if color == nil then
        error("Invalid preview color for " .. tostring(key) .. ": " .. tostring(text))
    end
    return color
end

function Common.require_control_enum(controls, key)
    local value = controls[key]:get_value()
    if type(value) ~= "number" then
        error("Invalid preview enum for " .. tostring(key) .. ": " .. tostring(value))
    end
    return value
end

function Common.require_positive_scale(window)
    local value = Common.require_control_number(window.controls, "scale")
    if value <= 0 then
        error("Invalid preview scale: " .. tostring(value))
    end
    return value
end

function Common.preview_scaled_int(raw_scale, raw_value)
    local n = Common.require_number(raw_value, "scaled_int")
    return math.floor((n * raw_scale) + 0.5)
end

function Common.preview_scaled_border(raw_scale, raw_value)
    local n = Common.require_number(raw_value, "scaled_border")
    if n <= 0 then
        return 0
    end
    local out = math.floor(n * raw_scale)
    if out < 1 then
        out = 1
    end
    return out
end

function Common.preview_scaled_number(raw_scale, raw_value)
    local n = Common.require_number(raw_value, "scaled_number")
    return n * raw_scale
end

function Common.preview_resource_background(matches_missing, dimming, background, fill_color)
    if matches_missing == true then
        return Common.dim_color(fill_color, dimming)
    end
    return background
end

function Common.preview_power_max(morale_max)
    local morale = Common.require_number(morale_max, "preview_power_morale_max")
    local power = math.floor((morale * 0.30) + 0.5)
    if power < 1 then
        power = 1
    end
    if morale > 1 and power >= morale then
        power = morale - 1
    end
    return power
end

function Common.morale_color_preview(percent, gradient_enabled, gradient_full_color, gradient_mid_color,
                                     gradient_low_color, high_color, medium_color, low_color, critical_color)
    if gradient_enabled == true then
        return lui_gradient_morale_color(percent, gradient_full_color, gradient_mid_color, gradient_low_color)
    end
    if percent > 0.75 then
        return high_color
    elseif percent > 0.5 then
        return medium_color
    elseif percent > 0.25 then
        return low_color
    end
    return critical_color
end

function Common.preview_number_abbrev_settings(window)
    local controls = window.controls

    return {
        enabled = controls.abbrev_enabled.cb:IsChecked(),
        digits = controls.abbrev_digits:get_value(),
        width = controls.abbrev_width:get_value(),
        method = controls.abbrev_method:get_value(),
    }
end

function Common.apply_preview_border(p, w, h, x, y)
    local bw = 1
    local ww = Common.require_number(w, "preview_border_width")
    local hh = Common.require_number(h, "preview_border_height")
    local xx = x == nil and 0 or Common.require_number(x, "preview_border_x")
    local yy = y == nil and 0 or Common.require_number(y, "preview_border_y")
    if ww < 1 then ww = 1 end
    if hh < 1 then hh = 1 end

    p.border_top:SetVisible(true)
    p.border_top:SetZOrder(999)
    p.border_top:SetPosition(xx, yy)
    p.border_top:SetSize(ww, bw)

    p.border_bottom:SetVisible(true)
    p.border_bottom:SetZOrder(999)
    p.border_bottom:SetPosition(xx, yy + hh - bw)
    p.border_bottom:SetSize(ww, bw)

    p.border_left:SetVisible(true)
    p.border_left:SetZOrder(999)
    p.border_left:SetPosition(xx, yy)
    p.border_left:SetSize(bw, hh)

    p.border_right:SetVisible(true)
    p.border_right:SetZOrder(999)
    p.border_right:SetPosition(xx + ww - bw, yy)
    p.border_right:SetSize(bw, hh)
end

function Common.sync_preview_holder_height(window, holder, desired_height)
    local h = Common.require_number(desired_height, "preview_holder_height")
    h = math.floor(h + 0.5)
    if h < 1 then
        h = 1
    end

    if holder.height ~= h then
        holder.height = h
    end

    local w = Common.require_number(holder.control:GetWidth(), "preview_holder_width")
    if w > 0 then
        holder.control:SetSize(w, h)
    end

    return holder
end

function Common.ensure_gradient_preview(window, control_key)
    local holder = window.controls[control_key]
    if holder.gradient_preview ~= nil then
        return holder.gradient_preview
    end

    local p = {}
    p.border = Turbine.UI.Control()
    p.border:SetParent(holder.control)
    p.border:SetMouseVisible(false)

    p.inner = Turbine.UI.Control()
    p.inner:SetParent(p.border)
    p.inner:SetMouseVisible(false)
    p.inner:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))

    p.segments = {}
    for i = 1, 21 do
        local seg = Turbine.UI.Control()
        seg:SetParent(p.inner)
        seg:SetMouseVisible(false)
        p.segments[i] = seg
    end

    holder.gradient_preview = p
    return p
end

function Common.update_gradient_preview(window, control_key, full_color, mid_color, low_color)
    local holder = window.controls[control_key]
    local p = Common.ensure_gradient_preview(window, control_key)

    local w, h = holder.control:GetSize()
    if w == nil or h == nil or w < 1 or h < 1 then
        return
    end

    local strip_w = math.floor((w * 0.5) + 0.5)
    local min_strip_w = Common.scaled_int(111)
    if strip_w < min_strip_w then strip_w = min_strip_w end
    if strip_w > w then strip_w = w end

    local strip_h = window.input_height
    local min_strip_h = Common.scaled_int(11)
    if strip_h < min_strip_h then strip_h = min_strip_h end
    if strip_h > h then strip_h = h end

    local border = 1
    local x = math.floor((w - strip_w) / 2)
    local y = math.floor((h - strip_h) / 2)

    p.border:SetPosition(x, y)
    p.border:SetSize(strip_w, strip_h)
    p.border:SetBackColor(Turbine.UI.Color(1, 0.15, 0.15, 0.15))

    local inner_w = strip_w - (2 * border)
    local inner_h = strip_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    p.inner:SetPosition(border, border)
    p.inner:SetSize(inner_w, inner_h)

    local total_units = 20
    local current_units = 0
    for i = 0, 20 do
        local weight = (i == 0 or i == 20) and 0.5 or 1
        local x0 = math.floor((current_units / total_units) * inner_w)
        current_units = current_units + weight
        local x1 = math.floor((current_units / total_units) * inner_w)

        local seg = p.segments[i + 1]
        local seg_w = x1 - x0
        if seg_w < 1 then seg_w = 1 end

        seg:SetPosition(x0, 0)
        seg:SetSize(seg_w, inner_h)
        seg:SetBackColor(lui_gradient_morale_color(i * 0.05, full_color, mid_color, low_color))
    end
end
