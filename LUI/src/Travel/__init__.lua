-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Flags = _G.LUI.Runtime.Flags
local Stores = _G.LUI.Runtime.Stores
local State = _G.LUI.Settings.State
local Travel = _G.LUI.Features.Travel

import "LUI.src.Travel.travel_data"
import "LUI.src.Travel.travel_store"
import "LUI.src.Travel.travel_window"

local _shared_store = nil

local function _is_enabled()
    return State.settings.travel.enabled == true
end

function Travel.is_enabled()
    return _is_enabled()
end

function Travel.get_shared_store()
    if Flags.is_unloading == true then
        return nil
    end
    if _is_enabled() ~= true then
        error("Travel is disabled in settings.")
    end

    if _shared_store == nil then
        _shared_store = Travel.TravelStore()
        Stores.travel = _shared_store
    end

    return _shared_store
end

function Travel.destroy_shared_store()
    if _shared_store ~= nil then
        _shared_store:destroy()
    end
    _shared_store = nil
    Stores.travel = nil
end
