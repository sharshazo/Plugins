-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.namespace"

local LUI = _G.LUI
local api = LUI.API

LUI.api = api

api.StatusBar = api.StatusBar or {}
local MAX_STATUS_BAR_API_TITLE_LEN = 20
local MAX_STATUS_BAR_API_DESCRIPTION_LEN = 40

local function _trim(text)
    local value = tostring(text or "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function _normalize_key(value)
    local key = _trim(value)
    if key == "" then
        return nil
    end
    if key:find("%s") ~= nil or key:find("%%", 1, true) ~= nil or key:match("^[%w_%-%.]+$") == nil then
        return nil
    end
    return string.lower(key)
end

local function _normalize_title(value)
    local title = _trim(value)
    if title == "" then
        return nil
    end
    if string.len(title) > MAX_STATUS_BAR_API_TITLE_LEN then
        return nil, "StatusBar.add title must be at most " .. tostring(MAX_STATUS_BAR_API_TITLE_LEN) .. " characters."
    end
    return title
end

local function _normalize_description(value)
    if value == nil then
        return nil
    end

    local description = _trim(value)
    if description == "" then
        return nil
    end
    if string.len(description) > MAX_STATUS_BAR_API_DESCRIPTION_LEN then
        return nil, "StatusBar.add description must be at most " .. tostring(MAX_STATUS_BAR_API_DESCRIPTION_LEN) ..
            " characters."
    end
    return description
end

local function _normalize_command(value)
    local command = _trim(value)
    if command == "" then
        return nil
    end
    if command:sub(1, 1) ~= "/" then
        return nil
    end
    return command
end

local function _normalize_image(value)
    if type(value) == "number" then
        return value
    end

    local text = _trim(value)
    if text == "" then
        return nil
    end

    if text:match("^0[xX][%da-fA-F]+$") ~= nil then
        return tonumber(text:sub(3), 16)
    end

    local numeric = tonumber(text)
    if numeric ~= nil then
        return numeric
    end

    if text:lower():match("%.tga$") ~= nil then
        return text
    end

    return nil
end

local function _format_image(value)
    if type(value) == "number" then
        return string.format("0x%X", value)
    end

    local text = _trim(value)
    if text == "" then
        return nil
    end
    return text
end

local function _quote_argument(value)
    local text = tostring(value or "")
    text = text:gsub("\\", "\\\\")
    text = text:gsub("\"", "\\\"")
    text = text:gsub("\r", " ")
    text = text:gsub("\n", " ")
    return "\"" .. text .. "\""
end

local function _ensure_lui_loaded()
    local loaded = false
    local loaded_p = Turbine.PluginManager:GetLoadedPlugins()
    for _, p in pairs(loaded_p) do
        if p.Name == "LUI" then
            loaded = true
        end
    end

    if not loaded then
        local available = false
        local available_p = Turbine.PluginManager:GetAvailablePlugins()
        for _, p in pairs(available_p) do
            if p.Name == "LUI" then
                available = true
            end
        end
        if available then
            Turbine.PluginManager.LoadPlugin("LUI")
        end
    end
end

-- Public helper for other plugins.
--
-- Example:
--   import "LUI.api"
--   local request, err = LUI.api.StatusBar.add({
--       key = "myplugin",
--       title = "My Plugin",
--       description = "Opens my plugin window",
--       image = 0x41000001, -- or "MyPlugin/Resources/icon.tga"
--       command = "/myplugin show",
--   })
function api.StatusBar.add(spec)
    _ensure_lui_loaded()

    if type(spec) ~= "table" then
        return nil, "StatusBar.add expects a table."
    end

    local key = _normalize_key(spec.key)
    if key == nil then
        return nil, "StatusBar.add requires a key using letters, numbers, _, -, or ."
    end

    local title, title_err = _normalize_title(spec.title)
    if title == nil then
        return nil, title_err or "StatusBar.add requires a title."
    end

    local image = _normalize_image(spec.image)
    if image == nil then
        return nil, "StatusBar.add requires an image id or .tga path."
    end

    local command = _normalize_command(spec.command)
    if command == nil then
        return nil, "StatusBar.add requires a slash command."
    end

    if Turbine == nil or Turbine.Shell == nil or Turbine.Shell.WriteLine == nil then
        return nil, "Turbine.Shell.WriteLine is not available."
    end

    local description, description_err = _normalize_description(spec.description)
    if description == nil and description_err ~= nil then
        return nil, description_err
    end
    local message = "/lui api.sb --add" ..
        " -k " .. _quote_argument(key) ..
        " -t " .. _quote_argument(title) ..
        " -i " .. _quote_argument(_format_image(image)) ..
        " -c " .. _quote_argument(command)

    if description ~= nil then
        message = message .. " -d " .. _quote_argument(description)
    end

    Turbine.Shell.WriteLine(message)

    return {
        key = key,
        title = title,
        description = description,
        image = image,
        command = command,
        submitted = true,
    }
end
