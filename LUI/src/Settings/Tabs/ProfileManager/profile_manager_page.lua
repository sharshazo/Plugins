-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local Persistence = _G.LUI.Settings.Persistence
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.Settings.Content.content"
import "LUI.src.UI.Widgets"

local Style = UI.Widgets.Style

local PROFILE_INFO_FONT_SIZE_OFFSET = 3
local INFO_HEIGHT = 59
local ACTION_ROW_HEIGHT = 24
local BLOCK_GAP = 24
local PROFILE_COLUMNS = 4

local function _scaled_profile_info_size(value)
    return value * State.settings.global.scale
end

local function _scaled_profile_info_font()
    local size = Style.CONTENT_SMALL_FONT_SIZE + PROFILE_INFO_FONT_SIZE_OFFSET
    local font = FONT_TO_LOTRO(Style.CONTENT_SMALL_FONT_NAME, _scaled_profile_info_size(size))
    if font == nil then
        error("Missing profile info font: " .. tostring(Style.CONTENT_SMALL_FONT_NAME) .. " " .. tostring(size))
    end
    return font
end

local function _layout_info(entry)
    local width, height = entry.control:GetSize()
    entry.body:SetPosition(0, 0)
    entry.body:SetSize(width, height)
end

local function _layout_button_row(window, entry, buttons)
    local width, height = entry.control:GetSize()
    local grid_gaps = (PROFILE_COLUMNS - 1) * window.col_gap
    local col_width = math.floor((width - grid_gaps) / PROFILE_COLUMNS)
    if col_width < 1 then
        col_width = 1
    end

    if #buttons < 1 then
        return
    end

    for i = 1, #buttons do
        local item = buttons[i]
        local button = item.button
        local col = item.col - 1
        local x = col * (col_width + window.col_gap)
        button:SetPosition(x, 0)
        button:SetSize(col_width, height)
    end
end

local function _apply_info_scale(entry)
    entry.body:SetFont(_scaled_profile_info_font())
    _layout_info(entry)
end

local function _apply_row_scale(window, entry, buttons)
    for i = 1, #buttons do
        buttons[i].button:set_font(window.settings_font)
    end
    _layout_button_row(window, entry, buttons)
end

local function _refresh_profile_manager(page, selected_profile_id)
    if page.window.profile_manager_refreshing == true then
        return
    end

    local profile_dropdown = page.controls.profile_manager_profile

    page.window.profile_manager_refreshing = true

    local labels, values = Persistence.get_configuration_options()
    profile_dropdown.option_labels = labels
    profile_dropdown.option_values = values
    profile_dropdown.button:SetMappedOptions(labels, values)

    local wanted_profile_id = selected_profile_id
    if wanted_profile_id == nil then
        wanted_profile_id = profile_dropdown:get_value()
    end
    if wanted_profile_id == nil then
        wanted_profile_id = State.current_profile_id
    end
    if wanted_profile_id == nil then
        wanted_profile_id = Persistence.get_first_configuration_id()
    end

    page.profile_manager_profile_value = wanted_profile_id
    profile_dropdown:set_value(wanted_profile_id)
    local active_profile_id = profile_dropdown:get_value()
    page.profile_manager_profile_value = active_profile_id
    page.window.profile_manager_selected_profile_id = active_profile_id
    page.profile_manager_name_value = Persistence.get_configuration_name(active_profile_id) or ""
    ConfigContent.load(page)

    local can_delete = active_profile_id ~= nil and Persistence.get_configuration_count() > 1
    page.profile_manager_use_button:set_enabled(active_profile_id ~= nil and active_profile_id ~= State.current_profile_id)
    page.profile_manager_rename_button:set_enabled(active_profile_id ~= nil)
    page.profile_manager_delete_button:set_enabled(can_delete)

    page.window.profile_manager_refreshing = false
end

local ProfileManagerPage = class(ConfigContent)
Pages.ProfileManagerPage = ProfileManagerPage

function ProfileManagerPage:Constructor(window)
    ConfigContent.Constructor(self, window, PROFILE_COLUMNS)
    self.show_main_content_border = false
    self.profile_manager_profile_value = nil
    self.profile_manager_name_value = ""

    local info_entry = self:add_custom("profile_manager_info", INFO_HEIGHT)
    info_entry.body = UI.Widgets.LuiLabel()
    info_entry.body:SetParent(info_entry.control)
    info_entry.body:SetMouseVisible(false)
    info_entry.body:SetSelectable(false)
    info_entry.body:SetMultiline(true)
    info_entry.body:SetFont(_scaled_profile_info_font())
    info_entry.body:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    info_entry.body:SetForeColor(Style.FOREGROUND)
    info_entry.body:SetText(table.concat({
        TR["Profile actions here apply immediately."],
        TR["Deleting a profile removes it for all characters using it."],
        TR["Profile Manager changes override unsaved changes in other tabs."],
    }, "\n"))
    info_entry.control.SizeChanged = function()
        _layout_info(info_entry)
    end
    info_entry.apply_ui_scale = function()
        _apply_info_scale(info_entry)
    end
    info_entry:apply_ui_scale()

    self:add_break(BLOCK_GAP)

    local profile_dropdown = self:add_dropdown("profile_manager_profile", TR["Profile"], {}, {},
        function(value)
            self.profile_manager_profile_value = value
        end,
        function()
            return self.profile_manager_profile_value
        end,
        nil, true)
    profile_dropdown.on_changed = function(value)
        _refresh_profile_manager(self, value)
    end

    local profile_actions = self:add_custom("profile_manager_profile_actions", ACTION_ROW_HEIGHT)
    profile_actions.use_button = UI.Widgets.LuiButton()
    profile_actions.use_button:SetParent(profile_actions.control)
    profile_actions.use_button:set_text(TR["Use"])
    profile_actions.use_button.Click = function()
        window:use_selected_profile()
    end

    profile_actions.delete_button = UI.Widgets.LuiButton()
    profile_actions.delete_button:SetParent(profile_actions.control)
    profile_actions.delete_button:set_text(TR["Delete"])
    profile_actions.delete_button.Click = function()
        window:confirm_delete_selected_profile()
    end

    profile_actions.control.SizeChanged = function()
        _layout_button_row(window, profile_actions, {
            { button = profile_actions.use_button, col = 1 },
            { button = profile_actions.delete_button, col = 4 },
        })
    end
    profile_actions.apply_ui_scale = function()
        _apply_row_scale(window, profile_actions, {
            { button = profile_actions.use_button, col = 1 },
            { button = profile_actions.delete_button, col = 4 },
        })
    end
    profile_actions:apply_ui_scale()

    self:add_break(BLOCK_GAP)

    self:add_line_edit("profile_manager_name", TR["Name"],
        function(value)
            self.profile_manager_name_value = value
        end,
        function()
            return self.profile_manager_name_value
        end,
        nil, true)

    local name_actions = self:add_custom("profile_manager_name_actions", ACTION_ROW_HEIGHT)
    name_actions.rename_button = UI.Widgets.LuiButton()
    name_actions.rename_button:SetParent(name_actions.control)
    name_actions.rename_button:set_text(TR["Rename"])
    name_actions.rename_button.Click = function()
        window:rename_selected_profile()
    end

    name_actions.new_from_current_button = UI.Widgets.LuiButton()
    name_actions.new_from_current_button:SetParent(name_actions.control)
    name_actions.new_from_current_button:set_text(TR["New from current"])
    name_actions.new_from_current_button.Click = function()
        window:create_profile_from_current()
    end

    name_actions.new_button = UI.Widgets.LuiButton()
    name_actions.new_button:SetParent(name_actions.control)
    name_actions.new_button:set_text(TR["New"])
    name_actions.new_button.Click = function()
        window:start_new_profile_quick_setup()
    end

    name_actions.control.SizeChanged = function()
        _layout_button_row(window, name_actions, {
            { button = name_actions.rename_button, col = 1 },
            { button = name_actions.new_from_current_button, col = 3 },
            { button = name_actions.new_button, col = 4 },
        })
    end
    name_actions.apply_ui_scale = function()
        _apply_row_scale(window, name_actions, {
            { button = name_actions.rename_button, col = 1 },
            { button = name_actions.new_from_current_button, col = 3 },
            { button = name_actions.new_button, col = 4 },
        })
    end
    name_actions:apply_ui_scale()

    self.profile_manager_use_button = profile_actions.use_button
    self.profile_manager_delete_button = profile_actions.delete_button
    self.profile_manager_rename_button = name_actions.rename_button
end

function ProfileManagerPage:load()
    local selected_profile_id = self.window.profile_manager_selected_profile_id or State.current_profile_id
    _refresh_profile_manager(self, selected_profile_id)
end
