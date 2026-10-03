-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ConfigWindow = _G.LUI.Settings.ConfigWindow
import "LUI.src.Settings.Preview.group_vitals"

local _fellowship_preview_spec = {
    state_key = "_fellowship_vitals_preview_state",
    holder_key = "fellowship_vitals_preview",
    prefix = "fellowship",
    max_members = 6,
    leader_slot = 1,
    get_preview_count = function(window)
        if window.controls.fellowship_show_self_in_fellowship.cb:IsChecked() == true then
            return 6
        end

        return 5
    end,
    is_self_slot = function(index, preview_count)
        return preview_count == 6 and index == 1
    end,
}

function ConfigWindow:init_fellowship_vitals_preview()
    _G.LUI.Settings.Preview.GroupVitals.init(self, _fellowship_preview_spec)
    self:update_fellowship_vitals_preview()
end

function ConfigWindow:update_fellowship_vitals_preview()
    _G.LUI.Settings.Preview.GroupVitals.update(self, _fellowship_preview_spec)
end
