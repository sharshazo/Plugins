-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.UI"

local LUI = _G.LUI
local State = LUI.Settings.State
local NativeScaling = LUI.UI.NativeScaling

local DEFAULT_SCALE = 1
local DEFAULT_ORIGIN_LEFT = 0
local DEFAULT_ORIGIN_TOP = 0

local function _global_settings(settings)
    if type(settings) == "table" and type(settings.global) == "table" then
        return settings.global
    end
    if type(State.settings) == "table" and type(State.settings.global) == "table" then
        return State.settings.global
    end
    if type(State.loaded_settings) == "table" and type(State.loaded_settings.global) == "table" then
        return State.loaded_settings.global
    end
    return nil
end

local function _safe_window_call(window, method_name, ...)
    if window == nil then
        return false
    end

    local method = window[method_name]
    if type(method) ~= "function" then
        return false
    end

    local ok = pcall(method, window, ...)
    return ok == true
end

local function _to_number(value, fallback)
    local n = value
    if type(n) ~= "number" then
        n = tonumber(n)
    end
    if n == nil then
        return fallback
    end
    return n
end

function NativeScaling.is_enabled(settings)
    local global = _global_settings(settings)
    return global ~= nil and global.native_scaling == true and NativeScaling.has_global_scale_api() == true
end

function NativeScaling.get_configured_scale(settings)
    local global = _global_settings(settings)
    local scale = global ~= nil and global.scale or DEFAULT_SCALE
    local n = _to_number(scale, DEFAULT_SCALE)
    if n <= 0 then
        return DEFAULT_SCALE
    end
    return n
end

function NativeScaling.get_effective_scale(settings)
    if NativeScaling.is_enabled(settings) then
        return DEFAULT_SCALE
    end
    return NativeScaling.get_configured_scale(settings)
end

function NativeScaling.scale_value(value, settings)
    return _to_number(value, 0) * NativeScaling.get_effective_scale(settings)
end

function NativeScaling.scaled_int(value, settings)
    return math.floor(NativeScaling.scale_value(value, settings) + 0.5)
end

function NativeScaling.has_global_scale_api()
    local display = Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Display or nil
    return display ~= nil and type(display.GetGlobalUIScale) == "function"
end

function NativeScaling.get_global_scale()
    local display = Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Display or nil
    local method = display ~= nil and display.GetGlobalUIScale or nil
    if type(method) ~= "function" then
        return DEFAULT_SCALE
    end

    local ok, scale = pcall(method)
    if ok ~= true then
        return DEFAULT_SCALE
    end

    local n = _to_number(scale, DEFAULT_SCALE)
    if n <= 0 then
        return DEFAULT_SCALE
    end
    return n
end

function NativeScaling.has_global_scaling_api(window)
    return window ~= nil and
        type(window.RegisterForGlobalScaling) == "function" and
        type(window.UnregisterForGlobalScaling) == "function"
end

function NativeScaling.apply_window(window, settings)
    if window == nil then
        return
    end

    local use_native = NativeScaling.is_enabled(settings) and NativeScaling.has_global_scaling_api(window) == true
    if use_native then
        return NativeScaling.enable(window)
    end
    return NativeScaling.disable(window)
end

function NativeScaling.set_origin(window, left, top)
    return _safe_window_call(
        window,
        "SetScalingOriginPoint",
        _to_number(left, DEFAULT_ORIGIN_LEFT),
        _to_number(top, DEFAULT_ORIGIN_TOP)
    )
end

function NativeScaling.get_origin(window)
    if window == nil or type(window.GetScalingOriginPoint) ~= "function" then
        return DEFAULT_ORIGIN_LEFT, DEFAULT_ORIGIN_TOP
    end

    local ok, left, top = pcall(window.GetScalingOriginPoint, window)
    if ok ~= true then
        return DEFAULT_ORIGIN_LEFT, DEFAULT_ORIGIN_TOP
    end

    return _to_number(left, DEFAULT_ORIGIN_LEFT), _to_number(top, DEFAULT_ORIGIN_TOP)
end

function NativeScaling.set_scale(window, scale)
    local n = _to_number(scale, DEFAULT_SCALE)
    if n <= 0 then
        n = DEFAULT_SCALE
    end
    return _safe_window_call(window, "SetScale", n)
end

function NativeScaling.register(window)
    return _safe_window_call(window, "RegisterForGlobalScaling")
end

function NativeScaling.unregister(window)
    return _safe_window_call(window, "UnregisterForGlobalScaling")
end

function NativeScaling.apply(window, use_global_scaling, scale, origin_left, origin_top)
    local native_enabled = use_global_scaling == true
    local result = {
        origin = false,
        scale = false,
        registered = false,
        unregistered = false,
    }

    result.origin = NativeScaling.set_origin(window, origin_left, origin_top)

    if native_enabled then
        result.scale = NativeScaling.set_scale(window, scale)
        result.registered = NativeScaling.register(window)
    else
        result.unregistered = NativeScaling.unregister(window)
        result.scale = NativeScaling.set_scale(window, scale)
    end

    return result
end

function NativeScaling.enable(window)
    return NativeScaling.apply(window, true, DEFAULT_SCALE, DEFAULT_ORIGIN_LEFT, DEFAULT_ORIGIN_TOP)
end

function NativeScaling.disable(window)
    return NativeScaling.apply(window, false, DEFAULT_SCALE, DEFAULT_ORIGIN_LEFT, DEFAULT_ORIGIN_TOP)
end

function NativeScaling.get_ui_scale(settings)
    return NativeScaling.get_effective_scale(settings)
end

function NativeScaling.scale_ui_value(value, settings)
    return NativeScaling.scale_value(value, settings)
end

function NativeScaling.scaled_ui_int(value, settings)
    return NativeScaling.scaled_int(value, settings)
end
