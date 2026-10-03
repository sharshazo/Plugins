-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
import "LUI.src.StatusBar.common"

local StatusBarPage = _G.LUI.Settings.Pages.StatusBar
local S = _G.LUI.Features.StatusBar.Common

function StatusBarPage.build_layout_help()
    local lines = {
        TR["Tokens:"],
        TR["  %time% - local time (HH:MM)"],
        TR["  %inventory% - backpack used/total"],
        TR["  %durability% - equipped wear average% (weakest%)"],
        TR["  %gold% - money (g/s/c)"],
        TR["  %wallet% - selected wallet items"],
        TR["  %item:[Simple Fish]% - tracked total for one inventory item"],
        TR["  %config% - toggle configuration window"],
        TR["  %craft% - toggle crafting window"],
        TR["  %craft.plan% - tracked crafting plan resources"],
        TR["  %travel% - toggle travel window"],
        TR["  %encyclopedia% - toggle encyclopedia window"],
        TR["  %assets% - toggle assets window"],
        TR["  %raid% - toggle raid manager window"],
    }

    local external_lines = S.get_status_bar_api_hint_lines()
    for i = 1, #external_lines do
        lines[#lines + 1] = external_lines[i]
    end

    return table.concat(lines, "\n")
end
