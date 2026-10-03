-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.UI.popup_state"

local UI = _G.LUI.UI
local PopupState = UI.PopupState
local MoveMode = UI.MoveMode

local Hidable = UI.Hidable
local HidableMethods = {}
local global_hud_visible = Hidable.global_visible ~= false
local last_hud_toggle_at = Hidable.last_toggle_at or 0

Hidable.register = nil
Hidable.unregister = nil
Hidable.set_visible = nil
Hidable.is_visible = nil
Hidable.global_visible = nil
Hidable.last_toggle_at = nil

setmetatable(Hidable, {
    __mode = "k",
    __index = HidableMethods,
})

local function _is_registered_window(win, registered)
    return registered == true
end

local function _apply_global_visibility(win, visible)
    if win == nil then
        return
    end

    win:global_hide(visible)
end

function HidableMethods.register(win)
    if win == nil then
        return
    end

    Hidable[win] = true
    if global_hud_visible ~= true then
        _apply_global_visibility(win, false)
    end
end

function HidableMethods.unregister(win)
    if win == nil then
        return
    end

    Hidable[win] = nil
end

function HidableMethods.set_visible(visible)
    if visible == nil then
        return
    end

    global_hud_visible = visible == true

    if global_hud_visible ~= true then
        PopupState.close_all()
    end

    MoveMode.set_hud_visible(global_hud_visible)

    for win, registered in pairs(Hidable) do
        if _is_registered_window(win, registered) == true then
            _apply_global_visibility(win, global_hud_visible)
        end
    end
end

function HidableMethods.is_visible()
    return global_hud_visible == true
end

function Hidable.is_lui_hud_visible()
    return Hidable.is_visible()
end

function Hidable.set_lui_hud_visible(visible)
    Hidable.set_visible(visible)
end

function Hidable.toggle_lui_hud_visible()
    local now = Turbine.Engine.GetGameTime()
    if (now - last_hud_toggle_at) < 0.2 then
        return
    end
    last_hud_toggle_at = now
    Hidable.set_lui_hud_visible(not (global_hud_visible == true))
end
