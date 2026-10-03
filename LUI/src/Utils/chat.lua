-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils

-- the plugin's own blue, same one the /lui command output uses
local LUI_COLOR = "#3399FA"
-- dark orange, readable against the chat backdrop without shouting
local WARN_COLOR = "#CC7A29"

-- A warning the player needs to see and can act on. Deliberately rare: this
-- is not for data-age or drift notices, only for a binding the plugin cannot
-- resolve correctly.
function Utils.lui_warn(message)
    Turbine.Shell.WriteLine(
        "<rgb=" .. LUI_COLOR .. ">LUI</rgb> " ..
        "<rgb=" .. WARN_COLOR .. ">[WARN] " .. message .. "</rgb>")
end

function Utils.lui_chat_type_names(chat_type)
    if type(Turbine.ChatType) ~= "table" then
        return tostring(chat_type)
    end

    local names = {}
    for name, value in pairs(Turbine.ChatType) do
        if value == chat_type then
            names[#names + 1] = tostring(name)
        end
    end

    if #names == 0 then
        return tostring(chat_type)
    end

    table.sort(names)
    return table.concat(names, ", ")
end
