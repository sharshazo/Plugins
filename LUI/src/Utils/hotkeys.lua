-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Runtime = _G.LUI.Runtime
local Windows = Runtime.Windows
local Commands = Runtime.Commands
local Shortcuts = UI.Shortcuts
local MoveMode = UI.MoveMode
local Hidable = UI.Hidable
import "Turbine.UI"

local BACKPACK_ACTION = 0x10000094
local HUD_TOGGLE = 0x100000B3
local MOVE_MODE_TOGGLE = 0x1000007B

local HUD_ACTION_SINK = Turbine.UI.Control();
Commands.hud_action_sink = HUD_ACTION_SINK
HUD_ACTION_SINK:SetVisible(false)
HUD_ACTION_SINK.KeyDown = function(_, args)
    if args.Action == BACKPACK_ACTION then
        local inv = State.settings ~= nil and State.settings.inventory or nil
        if inv ~= nil and inv.enabled == true and inv.replace == true and Windows.inventory ~= nil then
            Shortcuts.toggle_inventory()
            return
        end
    end
    if args.Action == HUD_TOGGLE then
        Hidable.toggle_lui_hud_visible()
    elseif args.Action == MOVE_MODE_TOGGLE then
        if State.settings.global.move_mode_shortcut == true then
            MoveMode.toggle(false)
        end
    end
end
HUD_ACTION_SINK:SetWantsKeyEvents(true)
