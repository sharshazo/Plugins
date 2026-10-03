-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Parser = _G.LUI.Features.StatusBar.APICommandParser

function Parser.strip_chat_timestamp(message)
    local text = tostring(message or "")
    local stripped = text:gsub("^%[%d%d/%d%d .-%]%s*", "")
    return stripped
end

function Parser.tokenize_command_arguments(text)
    local source = tostring(text or "")
    local out = {}
    local current = {}
    local quote = nil
    local escaped = false

    local function push_token()
        if #current == 0 then
            return
        end
        out[#out + 1] = table.concat(current)
        current = {}
    end

    for i = 1, string.len(source) do
        local char = string.sub(source, i, i)
        if escaped == true then
            if char == "n" then
                current[#current + 1] = "\n"
            elseif char == "r" then
                current[#current + 1] = "\r"
            elseif char == "t" then
                current[#current + 1] = "\t"
            else
                current[#current + 1] = char
            end
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif quote ~= nil then
            if char == quote then
                quote = nil
            else
                current[#current + 1] = char
            end
        elseif char == "\"" or char == "'" then
            quote = char
        elseif string.find(" \t\r\n", char, 1, true) ~= nil then
            push_token()
        else
            current[#current + 1] = char
        end
    end

    if escaped == true then
        current[#current + 1] = "\\"
    end

    push_token()
    return out
end

function Parser.get_status_bar_api_start_index(list)
    if type(list) ~= "table" or #list == 0 then
        return nil
    end

    local cmd = string.lower(tostring(list[1] or ""))
    if cmd == "api.sb" then
        return 2
    end
    if cmd == "api" and string.lower(tostring(list[2] or "")) == "sb" then
        return 3
    end
    return nil
end

function Parser.parse_status_bar_api_spec(list, index)
    local spec = {}
    local add_requested = false
    local i = index

    while i <= #list do
        local arg = string.lower(tostring(list[i] or ""))
        if arg == "--add" or arg == "-a" then
            add_requested = true
            i = i + 1
        elseif arg == "-k" then
            spec.key = list[i + 1]
            i = i + 2
        elseif arg == "-t" then
            spec.title = list[i + 1]
            i = i + 2
        elseif arg == "-d" then
            spec.description = list[i + 1]
            i = i + 2
        elseif arg == "-i" then
            spec.image = list[i + 1]
            i = i + 2
        elseif arg == "-c" then
            spec.command = list[i + 1]
            i = i + 2
        else
            return nil, "Unknown api.sb argument: " .. tostring(list[i])
        end
    end

    if add_requested ~= true then
        return nil, "Missing --add or -a."
    end
    if spec.key == nil then
        return nil, "Missing -k [key]."
    end
    if spec.title == nil then
        return nil, "Missing -t [title]."
    end
    if spec.image == nil then
        return nil, "Missing -i [image id|path]."
    end
    if spec.command == nil then
        return nil, "Missing -c [command]."
    end

    return spec
end
