-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ConfigWindow = _G.LUI.Settings.ConfigWindow
import "LUI.src.Settings.Preview.common"
import "LUI.src.Settings.Preview.self_expiring_effects"
import "LUI.src.Settings.Preview.cooldowns"
import "LUI.src.Settings.Preview.drops"
import "LUI.src.Settings.Preview.expiring_target_effects"
import "LUI.src.Settings.Preview.target_boss_vitals"
import "LUI.src.Settings.Preview.target_targets_target"
import "LUI.src.Settings.Preview.fellowship_vitals"
import "LUI.src.Settings.Preview.raid_vitals"
import "LUI.src.Settings.Preview.vitals"

local function _selected_leaf_page(page)
    local current = page
    while current ~= nil and current.sub_tab_bar ~= nil do
        local child = current.sub_tab_bar:get_selected_widget()
        if child == nil then
            break
        end
        current = child
    end
    return current
end

function ConfigWindow:_refresh_active_preview()
    if self.main_tab_bar == nil then
        return
    end

    local page = self.main_tab_bar:get_selected_widget()
    if page == nil then
        return
    end

    page = _selected_leaf_page(page)

    if page.refresh_preview ~= nil then
        page:refresh_preview()
    end
    if page.layout ~= nil then
        page:layout()
    end
end
