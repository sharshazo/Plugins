-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"

local Widgets = _G.LUI.UI.Widgets

local MIN_UPDATE_INTERVAL = 0.05

local timers = {}
local update_driver = nil
local last_update_at = 0

local function _now()
    return Turbine.Engine.GetGameTime()
end

local function _require_callback(callback, context)
    if type(callback) ~= "function" then
        error(context .. " callback must be a function")
    end
    return callback
end

local function _require_interval(interval, context)
    if type(interval) ~= "number" or interval <= 0 then
        error(context .. " interval must be a positive number of seconds")
    end
    return interval
end

local function _set_updates_enabled(enabled)
    update_driver:SetWantsUpdates(enabled == true)
end

local function _remove_timer(timer)
    if timer._active ~= true then
        return false
    end

    for i = 1, #timers do
        if timers[i] == timer then
            table.remove(timers, i)
            timer._active = false
            return true
        end
    end

    error("LuiTimer active timer is not registered")
end

local function _sync_driver()
    _set_updates_enabled(#timers > 0)
end

local function _ensure_driver()
    if update_driver ~= nil then
        return
    end

    update_driver = Turbine.UI.Control()
    update_driver:SetVisible(false)
    update_driver:SetWantsUpdates(false)
    update_driver.Update = function()
        if #timers == 0 then
            _set_updates_enabled(false)
            return
        end

        local now = _now()
        if now - last_update_at < MIN_UPDATE_INTERVAL then
            return
        end
        last_update_at = now

        Widgets.LuiTimer.execute_next_timer(now)
        _sync_driver()
    end
end

---@class LuiTimer
local LuiTimer = class()
Widgets.LuiTimer = LuiTimer

function LuiTimer:Constructor(callback)
    self._callback = _require_callback(callback, "LuiTimer")
    self._interval = nil
    self._due_at = nil
    self._active = false
    self._single_shot = false
end

function LuiTimer:is_due(now)
    return now >= self._due_at
end

function LuiTimer:_reschedule(now)
    local skipped = math.floor((now - self._due_at) / self._interval) + 1
    self._due_at = self._due_at + (skipped * self._interval)
end

function LuiTimer:_delete()
    self._callback = nil
    self._interval = nil
    self._due_at = nil
    self._active = false
    self._single_shot = false
end

function LuiTimer:start(interval)
    self._interval = _require_interval(interval, "LuiTimer:start")
    self._due_at = _now() + self._interval

    if self._active ~= true then
        timers[#timers + 1] = self
        self._active = true
    end

    _ensure_driver()
    _set_updates_enabled(true)
end

function LuiTimer:stop()
    if _remove_timer(self) == true then
        _sync_driver()
    end
end

function LuiTimer.execute_next_timer(now)
    for i = 1, #timers do
        local timer = timers[i]
        if timer:is_due(now) == true then
            local callback = timer._callback

            table.remove(timers, i)
            if timer._single_shot == true then
                timer:_delete()
            else
                timer:_reschedule(now)
                timers[#timers + 1] = timer
            end

            callback()
            return
        end
    end
end

function LuiTimer:single_shot(interval, callback)
    local timer = LuiTimer(callback)
    timer._single_shot = true
    timer:start(interval)
end

Widgets.LuiTimer = LuiTimer
