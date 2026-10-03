-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Content = _G.LUI.Settings.Content
local Tabs = _G.LUI.Settings.Tabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.tabbed_page"

local SettingsTabbedPage = Tabs.SettingsTabbedPage

local function _module_for_page(key, page)
    return {
        key = key,
        create_page = function()
            return page
        end,
    }
end

local ConfigTabs = class(SettingsTabbedPage)
Content.ConfigTabs = ConfigTabs

function ConfigTabs:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
end

function ConfigTabs:add_tab(text, key, page)
    if type(key) ~= "string" then
        error("ConfigTabs:add_tab is missing key")
    end
    if page == nil then
        error("ConfigTabs:add_tab is missing page: " .. tostring(key))
    end

    return self:add_sub_page(text, _module_for_page(key, page))
end

function ConfigTabs:load()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page:load()
    end
end

function ConfigTabs:save()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page:save()
    end
end
