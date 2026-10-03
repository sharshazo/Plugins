-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.hidable"
import "LUI.src.UI.native_scaling"

local LUI = _G.LUI
local Widgets = LUI.UI.Widgets
local NativeScaling = LUI.UI.NativeScaling
local Hidable = LUI.UI.Hidable

---@class LuiBaseWindow : Turbine.UI.Window
local LuiBaseWindow = class(Turbine.UI.Window)
Widgets.LuiBaseWindow = LuiBaseWindow

function LuiBaseWindow:Constructor(opts)
    Turbine.UI.Window.Constructor(self)

    if type(opts) ~= "table" then
        opts = {}
    end

    self._hideable = false
    self._global_hide_active = false
    self._global_hide_restore_visible = nil

    self:apply_native_scaling()

    if opts.hideable == true then
        self:set_hideable(true)
    end
end

function LuiBaseWindow:apply_native_scaling(target_window)
    local target = target_window or self
    local native_scaling = NativeScaling

    local use_native = native_scaling.is_enabled() == true and
        native_scaling.has_global_scaling_api(target) == true

    if use_native then
        native_scaling.enable(target)
    else
        native_scaling.disable(target)
    end
end

function LuiBaseWindow:set_hideable(enabled)
    local want = enabled == true
    if self._hideable == want then
        return
    end

    if want ~= true and self._global_hide_active == true then
        self:global_hide(true)
    end

    local registry = Hidable

    if self._hideable == true then
        registry.unregister(self)
    end

    self._hideable = want

    if self._hideable == true then
        registry.register(self)
    end
end

function LuiBaseWindow:is_hideable()
    return self._hideable == true
end

function LuiBaseWindow:unregister_hideable()
    self:set_hideable(false)
end

function LuiBaseWindow:SetVisible(visible)
    visible = visible == true
    if self._global_hide_active == true then
        if visible == true then
            -- Keep the last requested visibility so HUD restore reflects current state, not pre-hide state.
            self._global_hide_restore_visible = true
            return
        end
        self._global_hide_restore_visible = false
    end
    Turbine.UI.Window.SetVisible(self, visible)
end

function LuiBaseWindow:global_hide(visible)
    if visible == true then
        local restore_visible = self._global_hide_active == true and self._global_hide_restore_visible == true
        self._global_hide_active = false
        self._global_hide_restore_visible = nil
        if restore_visible == true then
            if self.show ~= nil then
                self:show()
            else
                Turbine.UI.Window.SetVisible(self, true)
            end
        end
        return
    end

    if self._global_hide_active ~= true then
        if self.IsVisible ~= nil then
            self._global_hide_restore_visible = self:IsVisible() == true
        else
            self._global_hide_restore_visible = false
        end
    end

    if self._global_hide_restore_visible == true then
        if self.hide ~= nil then
            self:hide()
        else
            Turbine.UI.Window.SetVisible(self, false)
        end
    end
    self._global_hide_active = true
end
