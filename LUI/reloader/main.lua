-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine";
import "Turbine.UI";
import "LUI.src.namespace"
import "LUI.src.Utils.class"
import "LUI.api"

local LUI = _G.LUI
local Reloader = LUI.Reloader
local class = LUI.Core.class

local function _log(message)
    if Turbine ~= nil and Turbine.Shell ~= nil and Turbine.Shell.WriteLine ~= nil then
        Turbine.Shell.WriteLine("<rgb=#33C1FF>LUIReloader</rgb>: " .. tostring(message or ""))
    end
end

local function _register_button()
    local _, err = LUI.api.StatusBar.add({
        key = "reloader",
        title = "LUI Reloader button",
        description = "Button to reload the LUI plugin",
        image = "LUI/reloader/reload.tga",
        command = "/luireloader",
    })

    if err ~= nil then
        _log("Failed to register status bar entry: " .. tostring(err))
    end
end

Reloader.reload_command = Turbine.ShellCommand()

local ReloaderWindow = class(Turbine.UI.Window);
Reloader.Window = ReloaderWindow
function ReloaderWindow:Constructor()
	Turbine.UI.Window.Constructor(self);
    self:SetVisible(false)
    self:SetSize(1, 1)
    self:SetZOrder(0)

    -- Async reload
    self.Update=function()
        if self:IsVisible() then
            self:SetWantsUpdates(false);
            Turbine.PluginManager.UnloadScriptState("LUI")
            Turbine.PluginManager.LoadPlugin("LUI")
            _register_button()
        end
    end
end
Reloader.async = ReloaderWindow();

function Reloader.reload_command:Execute(_, arguments)
    Reloader.async:SetVisible(true)
    Reloader.async:SetWantsUpdates(true)
end

Turbine.Shell.AddCommand("LUIReloader", Reloader.reload_command)

_register_button()
