-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.UI"
import "LUI.src.Settings.migrations"
import "LUI.src.Settings.default_bottom"
import "LUI.src.Settings.default_schema"

local Settings = _G.LUI.Settings
local Defaults = Settings.Defaults
local DefaultLayouts = Defaults.DefaultLayouts or {}
Defaults.DefaultLayouts = DefaultLayouts
local Migrations = Settings.Migrations

local BASE_DISPLAY_W = 2560
local BASE_DISPLAY_H = 1440
local BASE_SCALE = 1.35

local function _round(n)
    return math.floor(n + 0.5)
end

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = _copy_table(v)
    end

    return copy
end

local function _merge_table(base, override)
    if type(base) ~= "table" or type(override) ~= "table" then
        return
    end

    for key, value in pairs(override) do
        if type(value) == "table" then
            if type(base[key]) ~= "table" then
                base[key] = {}
            end
            _merge_table(base[key], value)
        else
            base[key] = value
        end
    end
end

local function _build_layout_source(layout_key)
    local base = Defaults.Schema
    if type(base) ~= "table" then
        error("Failed to load default schema")
    end

    local layout = _copy_table(base)
    if layout_key == "top" then
        return layout
    end
    if layout_key == "bottom" then
        local override = Defaults.Bottom
        if type(override) ~= "table" then
            error("Failed to load default bottom overrides")
        end
        _merge_table(layout, override)
        return layout
    end

    error("Unknown default layout: " .. tostring(layout_key))
end

local function _scale_left(base_left, display_w)
    return math.max(0, _round((base_left / BASE_DISPLAY_W) * display_w))
end

local function _scale_top(base_top, display_h)
    return math.max(0, _round((base_top / BASE_DISPLAY_H) * display_h))
end

local function _scale_width(base_width, display_w)
    return math.max(1, _round((base_width / BASE_DISPLAY_W) * display_w))
end

local function _scale_height(base_height, display_h)
    return math.max(1, _round((base_height / BASE_DISPLAY_H) * display_h))
end

local function _clip_position(left, top, width, height, display_w, display_h)
    if type(left) == "number" and type(width) == "number" then
        left = math.min(math.max(0, left), math.max(0, display_w - width))
    end
    if type(top) == "number" and type(height) == "number" then
        top = math.min(math.max(0, top), math.max(0, display_h - height))
    end
    return left, top
end

local function _adjust_window_positions(node, display_w, display_h)
    if type(node) ~= "table" then
        return
    end

    for key, value in pairs(node) do
        if type(value) == "table" then
            if key == "windows" then
                for _, window in pairs(value) do
                    if type(window) == "table" then
                        if type(window.left) == "number" then
                            window.left = _scale_left(window.left, display_w)
                        end
                        if type(window.top) == "number" then
                            window.top = _scale_top(window.top, display_h)
                        end
                        if type(window.width) == "number" then
                            window.width = _scale_width(window.width, display_w)
                        end
                        if type(window.height) == "number" then
                            window.height = _scale_height(window.height, display_h)
                        end
                        window.left, window.top = _clip_position(window.left, window.top, window.width, window.height,
                            display_w, display_h)
                    end
                end
            elseif key == "hud" then
                for _, position in pairs(value) do
                    if type(position) == "table" then
                        if type(position.left) == "number" then
                            position.left = _scale_left(position.left, display_w)
                        end
                        if type(position.top) == "number" then
                            position.top = _scale_top(position.top, display_h)
                        end
                    end
                end
            end

            _adjust_window_positions(value, display_w, display_h)
        end
    end
end

function DefaultLayouts.copy_table(value)
    return _copy_table(value)
end

function DefaultLayouts.get_resolution_scale()
    local _, display_h = Turbine.UI.Display.GetSize()
    local scale = display_h / 1080
    return math.floor((scale * 100) + 0.5) / 100
end

function DefaultLayouts.get_base_scale()
    return BASE_SCALE
end

function DefaultLayouts.build(layout_key, target_scale, preserved_config_geometry)
    local layout = _build_layout_source(layout_key)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    _adjust_window_positions(layout, display_w, display_h)
    layout.version = Migrations.get_settings_version()

    if type(layout.global) ~= "table" then
        layout.global = {}
    end
    layout.global.scale = target_scale

    if preserved_config_geometry ~= nil then
        if type(layout.ui) ~= "table" then
            layout.ui = {}
        end
        if type(layout.ui.windows) ~= "table" then
            layout.ui.windows = {}
        end
        layout.ui.windows.config = _copy_table(preserved_config_geometry)
    end

    return layout
end
