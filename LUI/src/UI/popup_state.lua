-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local UI = _G.LUI.UI
local Widgets = UI.Widgets
local PopupState = UI.PopupState

function PopupState.close_dropdowns()
    local LuiDropdown = Widgets.LuiDropdown
    local LuiCheckDropdown = Widgets.LuiCheckDropdown

    if LuiDropdown._active ~= nil then
        LuiDropdown._active:Close()
    end
    if LuiCheckDropdown._active ~= nil then
        LuiCheckDropdown._active:Close()
    end
end

function PopupState.close_menus()
    local LuiMenu = Widgets.LuiMenu
    if LuiMenu._active_root ~= nil then
        LuiMenu._active_root:close()
    end
end

function PopupState.close_all()
    PopupState.close_dropdowns()
    PopupState.close_menus()
end
