-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Windows = _G.LUI.Runtime.Windows
local Crafting = _G.LUI.Features.Crafting
import "Turbine.UI"

import "LUI.src.UI.assets"

local Shortcuts = UI.Shortcuts

Shortcuts.CONFIG_ICON = UI.AssetIds.feather
Shortcuts.INVENTORY_ICON = UI.AssetIds.backpack_alt
Shortcuts.CRAFT_ICON = UI.AssetIds.anvil_silver_glow
Shortcuts.TRAVEL_ICON = UI.AssetIds.compass
Shortcuts.ASSETS_ICON = UI.AssetIds.chest
Shortcuts.ENCYCLOPEDIA_ICON = UI.AssetIds.book_orange_cover
Shortcuts.RAID_ICON = UI.AssetIds.party_leader_banner

local VALID_SHORTCUTS = {
    config = true,
    inventory = true,
    assets = true,
    craft = true,
    travel = true,
    encyclopedia = true,
    raid = true,
}

local function _window_is_visible(window)
    return window ~= nil and window.IsVisible ~= nil and window:IsVisible() == true
end

function Shortcuts.is_valid(shortcut_key)
    return VALID_SHORTCUTS[shortcut_key] == true
end

function Shortcuts.get_icon(shortcut_key)
    if shortcut_key == "config" then
        return Shortcuts.CONFIG_ICON
    elseif shortcut_key == "inventory" then
        return Shortcuts.INVENTORY_ICON
    elseif shortcut_key == "craft" then
        return Shortcuts.CRAFT_ICON
    elseif shortcut_key == "travel" then
        return Shortcuts.TRAVEL_ICON
    elseif shortcut_key == "assets" then
        return Shortcuts.ASSETS_ICON
    elseif shortcut_key == "encyclopedia" then
        return Shortcuts.ENCYCLOPEDIA_ICON
    elseif shortcut_key == "raid" then
        return Shortcuts.RAID_ICON
    end
    return nil
end

function Shortcuts.get_label(shortcut_key)
    if shortcut_key == "config" then
        return TR["Config"]
    elseif shortcut_key == "inventory" then
        return TR["Inventory"]
    elseif shortcut_key == "craft" then
        return TR["Craft"]
    elseif shortcut_key == "travel" then
        return TR["Travel"]
    elseif shortcut_key == "assets" then
        return TR["Assets"]
    elseif shortcut_key == "encyclopedia" then
        return TR["Encyclopedia"]
    elseif shortcut_key == "raid" then
        return TR["Raid Manager"]
    end
    return ""
end

function Shortcuts.get_state(shortcut_key)
    if shortcut_key == "config" then
        return Windows.config ~= nil, _window_is_visible(Windows.config)
    elseif shortcut_key == "inventory" then
        return Windows.inventory ~= nil, _window_is_visible(Windows.inventory)
    elseif shortcut_key == "craft" then
        -- the window is created on demand from the imported constructor,
        -- so the toggle can always open it while crafting is enabled
        return Crafting.is_enabled() == true, _window_is_visible(Windows.crafting)
    elseif shortcut_key == "travel" then
        return State.settings.travel.enabled == true, _window_is_visible(Windows.travel)
    elseif shortcut_key == "assets" then
        return Windows.assets ~= nil, _window_is_visible(Windows.assets)
    elseif shortcut_key == "encyclopedia" then
        -- created on demand from the imported constructor; always openable
        return true, _window_is_visible(Windows.encyclopedia)
    elseif shortcut_key == "raid" then
        -- created on demand from the imported constructor; always openable
        return true, _window_is_visible(Windows.raid_config)
    end
    return false, false
end

function Shortcuts.activate(shortcut_key)
    if shortcut_key == "config" then
        Shortcuts.toggle_config()
    elseif shortcut_key == "inventory" then
        Shortcuts.toggle_inventory()
    elseif shortcut_key == "craft" then
        Shortcuts.toggle_crafting()
    elseif shortcut_key == "travel" then
        Shortcuts.toggle_travel()
    elseif shortcut_key == "assets" then
        Shortcuts.toggle_assets()
    elseif shortcut_key == "encyclopedia" then
        Shortcuts.toggle_encyclopedia()
    elseif shortcut_key == "raid" then
        Shortcuts.toggle_raid_groups()
    end
end
