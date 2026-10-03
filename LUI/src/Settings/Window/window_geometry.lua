-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ConfigWindow = _G.LUI.Settings.ConfigWindow
local Defaults = _G.LUI.Settings.Defaults
local State = _G.LUI.Settings.State
local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local CONFIG_DEFAULT_WIDTH = 1000
local CONFIG_DEFAULT_HEIGHT = 900
local CONFIG_MIN_WIDTH = 900
local CONFIG_MIN_HEIGHT = 800

function ConfigWindow:get_geometry_state()
    if State.loaded_settings == nil then
        return nil
    end

    return Defaults.get_ui_window_state("config")
end

function ConfigWindow:update_saved_geometry()
    local state = self:get_geometry_state()
    if state == nil then
        return
    end

    local geometry = self:get_geometry()
    state.left = geometry.left
    state.top = geometry.top
    state.width = geometry.width
    state.height = geometry.height
    state.tile = geometry.tile
end

function ConfigWindow:persist_geometry()
    self:update_saved_geometry()
end

function ConfigWindow:apply_saved_geometry()
    local default_width = _scaled_int(CONFIG_DEFAULT_WIDTH)
    local default_height = _scaled_int(CONFIG_DEFAULT_HEIGHT)
    local min_width = _scaled_int(CONFIG_MIN_WIDTH)
    local min_height = _scaled_int(CONFIG_MIN_HEIGHT)

    local display_width, display_height = Turbine.UI.Display.GetSize()
    if min_width > display_width then min_width = display_width end
    if min_height > display_height then min_height = display_height end

    local state = self:get_geometry_state()

    local width = default_width
    local height = default_height
    if state ~= nil and type(state.width) == "number" and type(state.height) == "number" then
        width = state.width
        height = state.height
    end

    if width > display_width then width = display_width end
    if height > display_height then height = display_height end
    if width < min_width then width = min_width end
    if height < min_height then height = min_height end

    self:SetSize(width, height)

    local left = math.floor((display_width - width) / 2)
    local top = math.floor((display_height - height) / 2)
    if state ~= nil and type(state.left) == "number" and type(state.top) == "number" then
        left = state.left
        top = state.top
    end

    if left < 0 then left = 0 end
    if top < 0 then top = 0 end
    if left > (display_width - _scaled_int(37)) then
        left = display_width - _scaled_int(37)
    end
    if top > (display_height - _scaled_int(37)) then
        top = display_height - _scaled_int(37)
    end

    self:SetPosition(left, top)

    self:set_geometry(state)
    self:update_saved_geometry()
end
