-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local State = _G.LUI.Settings.State
local Tabs = _G.LUI.Settings.Tabs
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets"

local SettingsTabbedPage = class(Turbine.UI.Control)
Tabs.SettingsTabbedPage = SettingsTabbedPage

function SettingsTabbedPage:Constructor(window)
    Turbine.UI.Control.Constructor(self)

    self.window = window
    self.controls = {}
    self._color_fields = {}
    self._sub_pages = {}
    self._sub_page_order = {}
    self._sub_page_modules = {}

    self:SetMouseVisible(false)

    self.sub_tab_bar = UI.Widgets.LuiTabBar()
    self.sub_tab_bar:SetParent(self)
    self.sub_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
    self.sub_tab_bar:set_content_padding(4)
    self.sub_tab_bar:set_show_border_left(false)
    self.sub_tab_bar.on_tab_changed = function(index, page, text)
        if page == nil then
            return
        end
        self:_on_sub_tab_changed(index, page, text)
    end

    self.SizeChanged = function()
        self:layout()
    end
end

function SettingsTabbedPage:_merge_page_controls(page)
    if page == nil then
        return
    end

    if page.controls ~= nil then
        for key, entry in pairs(page.controls) do
            self.controls[key] = entry
        end
    end

    if page._color_fields ~= nil then
        for i = 1, #page._color_fields do
            self._color_fields[#self._color_fields + 1] = page._color_fields[i]
        end
    end
end

function SettingsTabbedPage:add_sub_page(text, module)
    if type(module) ~= "table" then
        error("Invalid settings sub-page module")
    end
    if type(module.create_page) ~= "function" then
        error("Settings sub-page module is missing create_page: " .. tostring(module.key))
    end

    local page = module.create_page(self.window)
    if page == nil then
        error("Settings sub-page create_page returned nil: " .. tostring(module.key))
    end

    page._tab_key = module.key
    self._sub_pages[module.key] = page
    self._sub_page_order[#self._sub_page_order + 1] = module.key
    self._sub_page_modules[module.key] = module
    self.sub_tab_bar:add_tab(text, page)

    self:_merge_page_controls(page)

    if self.active_sub_key == nil then
        self.active_sub_key = module.key
    end

    return page
end

function SettingsTabbedPage:get_active_tab_key()
    return self.active_sub_key
end

function SettingsTabbedPage:_on_sub_tab_changed(_, page)
    if page == nil then
        return
    end

    local key = page._tab_key
    self.active_sub_key = key
    if self.window ~= nil then
        self.window.active_tab = key
    end

    if page.on_selected ~= nil then
        page:on_selected()
    elseif page.layout ~= nil then
        page:layout()
    end
end

function SettingsTabbedPage:select_tab(key)
    if type(key) ~= "string" or self._sub_pages[key] == nil then
        key = self.active_sub_key or self._sub_page_order[1]
    end

    local page = key ~= nil and self._sub_pages[key] or nil
    if page == nil then
        return
    end

    local index = nil
    if self.sub_tab_bar ~= nil then
        index = self.sub_tab_bar:find_index(function(_, candidate)
            return candidate == page
        end)
    end
    if index == nil then
        self:_on_sub_tab_changed(nil, page)
        return
    end

    if self.sub_tab_bar:get_selected_index() == index then
        self:_on_sub_tab_changed(index, page)
        return
    end

    self.sub_tab_bar:select_tab(index)
end

function SettingsTabbedPage:on_selected(preferred_key)
    self:layout()
    self:select_tab(preferred_key)
end

function SettingsTabbedPage:apply_ui_scale()
    local scale = State.settings.global.scale
    self.sub_tab_bar:set_scale(scale)
    self.sub_tab_bar:set_font(self.window.tab_font)

    self.sub_tab_bar:each_widget(function(_, page)
        if page ~= nil and page.apply_ui_scale ~= nil then
            page:apply_ui_scale()
        end
    end)

    self:layout()
end

function SettingsTabbedPage:close_all_dropdowns()
    self.sub_tab_bar:each_widget(function(_, page)
        if page ~= nil and page.close_all_dropdowns ~= nil then
            page:close_all_dropdowns()
        end
    end)
end

function SettingsTabbedPage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    self.sub_tab_bar:SetPosition(0, 0)
    self.sub_tab_bar:SetSize(width, height)
    self.sub_tab_bar:refresh_layout()
end
