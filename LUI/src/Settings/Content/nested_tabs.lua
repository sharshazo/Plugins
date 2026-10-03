-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Content = _G.LUI.Settings.Content
local Tabs = _G.LUI.Settings.Tabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"

local FeatureShell = Tabs.SettingsFeatureShell
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local module_for_page = FeatureShell.module_for_page

local ConfigNestedTabs = class(SettingsFeatureNestedPage)
Content.ConfigNestedTabs = ConfigNestedTabs

function ConfigNestedTabs:Constructor(window, tab_position, scale_factor, font_size)
    SettingsFeatureNestedPage.Constructor(self, window, tab_position, scale_factor, font_size)
end

function ConfigNestedTabs:add_tab(text, key, page)
    if type(key) ~= "string" then
        error("ConfigNestedTabs:add_tab is missing key")
    end
    if page == nil then
        error("ConfigNestedTabs:add_tab is missing page: " .. tostring(key))
    end

    return self:add_sub_page(text, module_for_page(key, page))
end

function ConfigNestedTabs:load()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page:load()
    end
end

function ConfigNestedTabs:save()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page:save()
    end
end
