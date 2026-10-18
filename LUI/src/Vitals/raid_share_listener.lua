-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Applies raid layouts shared through fellowship/raid chat. The Lua API
-- cannot send chat, so the leader copy-pastes the encoded line produced by
-- the Raid Manager window; every LUI client (leader included) sees it via
-- Chat.Received and applies the layout.

import "LUI.src.Chat.chat_hub"
import "LUI.src.Vitals.group_snapshot"
import "LUI.src.Vitals.raid_config"
import "LUI.src.Vitals.raid_share_codec"

local Vitals = _G.LUI.Features.Vitals
local RaidShareListener = Vitals.RaidShareListener or {}
Vitals.RaidShareListener = RaidShareListener

local Chat = _G.LUI.Chat
local GroupSnapshot = Vitals.GroupSnapshot
local RaidConfig = Vitals.RaidConfig
local RaidShareCodec = Vitals.RaidShareCodec
local State = _G.LUI.Settings.State
local Windows = _G.LUI.Runtime.Windows
import "Turbine.Gameplay"

local _fellowship_listener = nil
local _raid_listener = nil

-- The chat line prefixes the payload with the speaker ("[Raid] Name: ...").
-- 2026-10-18 (LUI-02): the speaker must BE the leader; a mention of the
-- leader's name inside the text no longer counts. Order of trust:
--   1. args.Sender, when the client provides it;
--   2. the name inside the first <Select:IID:...>Name<\Select> link;
--   3. the plain "[Channel] Name:" header.
-- Unknown shape -> not accepted (leader-only shares are never applied blind).
local function _is_from_leader(message, share, leader_name, sender)
    if type(leader_name) ~= "string" or leader_name == "" then
        return false
    end
    local function same(name)
        if type(name) ~= "string" then
            return false
        end
        name = string.gsub(name, "<[^>]*>", "")
        name = string.gsub(string.gsub(name, "^%s+", ""), "%s+$", "")
        return name == leader_name
    end
    if type(sender) == "string" and sender ~= "" then
        return same(sender)
    end
    local speaker_part = string.sub(message, 1, share.position - 1)
    local linked = string.match(speaker_part, "<Select:IID:[^>]*>([^<]+)<\\Select>")
    if linked ~= nil then
        return same(linked)
    end
    local header = string.match(speaker_part, "^%[[^%]]*%]%s*([^:%[%]<>]+):")
    if header ~= nil then
        return same(header)
    end
    return false
end

local function _on_chat(args)
    local share_settings = State.loaded_settings.raid.share
    if share_settings.listen ~= true then
        return
    end

    local message = args.Message
    if type(message) ~= "string" then
        return
    end

    local share = RaidShareCodec.decode(message)
    if share == nil then
        return
    end

    local snapshot = GroupSnapshot.read(Turbine.Gameplay.LocalPlayer.GetInstance())
    if share_settings.leader_only == true
        and _is_from_leader(message, share, snapshot.leader_name, args.Sender) ~= true then
        return
    end

    RaidConfig.apply_share(share, snapshot)
    Windows.raid_vitals:update_members(snapshot)

    local config_window = Windows.raid_config
    if config_window ~= nil and config_window:IsVisible() == true then
        config_window:refresh_cells()
    end
end

function RaidShareListener.install()
    _fellowship_listener = Chat.register(Turbine.ChatType.Fellowship, _on_chat)
    _raid_listener = Chat.register(Turbine.ChatType.Raid, _on_chat)
end

function RaidShareListener.uninstall()
    if _fellowship_listener == nil then
        return
    end
    Chat.unregister(Turbine.ChatType.Fellowship, _fellowship_listener)
    Chat.unregister(Turbine.ChatType.Raid, _raid_listener)
    _fellowship_listener = nil
    _raid_listener = nil
end
