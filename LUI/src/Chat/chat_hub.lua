-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Global chat hub: the single place features subscribe to game chat.
-- Listeners register per Turbine.ChatType; the hub holds at most one
-- Turbine.Chat "Received" callback (installed with the first listener,
-- removed with the last), and dispatch is one table lookup per chat line
-- plus a plain loop over that type's listeners.

local Chat = _G.LUI.Chat

import "LUI.src.Utils.callbacks"

local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback

local _listeners = {}
local _chat_callback = nil

local function _on_received(_, args)
    local list = _listeners[args.ChatType]
    if list == nil then
        return
    end
    for i = 1, #list do
        list[i](args)
    end
end

-- Register a listener for one chat type; returns the listener as the
-- unregister handle. Listeners receive the raw Turbine args table.
function Chat.register(chat_type, listener)
    local list = _listeners[chat_type]
    if list == nil then
        list = {}
        _listeners[chat_type] = list
    end
    list[#list + 1] = listener

    if _chat_callback == nil then
        _chat_callback = add_callback(Turbine.Chat, "Received", _on_received)
    end
    return listener
end

function Chat.unregister(chat_type, listener)
    local list = _listeners[chat_type]
    for i = 1, #list do
        if list[i] == listener then
            table.remove(list, i)
            break
        end
    end
    if #list == 0 then
        _listeners[chat_type] = nil
    end

    if next(_listeners) == nil and _chat_callback ~= nil then
        remove_callback(Turbine.Chat, "Received", _chat_callback)
        _chat_callback = nil
    end
end
