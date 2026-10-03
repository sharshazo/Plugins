-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils

function Utils.add_callback(object, event, callback)
    if object == nil or event == nil or type(callback) ~= "function" then
        return nil
    end

    local current = object[event]
    if current == nil then
        object[event] = {}
    elseif type(current) == "function" then
        object[event] = { current }
    elseif type(current) ~= "table" then
        object[event] = {}
    end

    table.insert(object[event], callback)
    return callback
end

function Utils.remove_callback(object, event, callback)
    if object[event] ~= nil and type(object[event]) == "table" then
        local size = #object[event]
        for i = 1, size do
            if object[event][i] == callback then
                table.remove(object[event], i);
                break;
            end
        end
        if #object[event] == 0 then
            object[event] = nil
        end
    elseif object[event] == callback then
        object[event] = nil
    end
end
