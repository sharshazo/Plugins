-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.StatusBar.api_command_parser"

local LUI = _G.LUI
local StatusBar = LUI.Features.StatusBar
local Parser = StatusBar.APICommandParser
local APIChat = StatusBar.APIChat
local Windows = LUI.Runtime.Windows
local add_callback = LUI.Utils.add_callback
local remove_callback = LUI.Utils.remove_callback
local PENDING_STATUS_BAR_API_ITEMS = {}
local status_bar_api_chat_callback = nil

local function _log_status_bar_api_chat(message)
    if Turbine ~= nil and Turbine.Shell ~= nil and Turbine.Shell.WriteLine ~= nil then
        Turbine.Shell.WriteLine("<rgb=#33C1FF>LUI StatusBar</rgb>: " .. tostring(message or ""))
    end
end

local function _register_status_bar_api_item(spec)
    return StatusBar.Common.register_status_bar_api_item(spec)
end

local function flush_pending_items()
    if Windows.status_bar == nil then
        return
    end
    if #PENDING_STATUS_BAR_API_ITEMS == 0 then
        return
    end

    while #PENDING_STATUS_BAR_API_ITEMS > 0 do
        local spec = table.remove(PENDING_STATUS_BAR_API_ITEMS, 1)
        local _, err = _register_status_bar_api_item(spec)
        if err ~= nil then
            _log_status_bar_api_chat("Status bar push failed: " .. tostring(err))
        end
    end
end

local function push_item(spec)
    if Windows.status_bar ~= nil then
        local _, err = _register_status_bar_api_item(spec)
        if err ~= nil then
            _log_status_bar_api_chat("Status bar push failed: " .. tostring(err))
        end
        return
    end

    PENDING_STATUS_BAR_API_ITEMS[#PENDING_STATUS_BAR_API_ITEMS + 1] = spec
    flush_pending_items()
end

local function handle_chat_message(args)
    if args.ChatType ~= Turbine.ChatType.Standard then
        return
    end

    local message = Parser.strip_chat_timestamp(args ~= nil and args.Message or nil)
    local command_text = message:match("^/[Ll][Uu][Ii]%s+(.+)$")
    if command_text == nil then
        return
    end

    local list = Parser.tokenize_command_arguments(command_text)
    local start_index = Parser.get_status_bar_api_start_index(list)
    if start_index == nil then
        return
    end

    local spec, err = Parser.parse_status_bar_api_spec(list, start_index)
    if spec == nil then
        _log_status_bar_api_chat("Ignored invalid /lui " .. tostring(command_text) .. ": " .. tostring(err))
        return
    end

    push_item(spec)
end

function APIChat.flush_pending_items()
    flush_pending_items()
end

function APIChat.install_chat_callback()
    if status_bar_api_chat_callback ~= nil then
        return
    end

    status_bar_api_chat_callback = add_callback(Turbine.Chat, "Received", function(_, args)
        handle_chat_message(args)
    end)
end

function APIChat.uninstall_chat_callback()
    if status_bar_api_chat_callback == nil then
        return
    end

    remove_callback(Turbine.Chat, "Received", status_bar_api_chat_callback)
    status_bar_api_chat_callback = nil
end
