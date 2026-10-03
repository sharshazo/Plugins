-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local LUI = _G.LUI
if LUI == nil then
    LUI = {}
    _G.LUI = LUI
end

local function ensure(parent, key)
    local value = parent[key]
    if value == nil then
        value = {}
        parent[key] = value
    end
    return value
end

LUI.API = ensure(LUI, "API")
LUI.Core = ensure(LUI, "Core")
LUI.Utils = ensure(LUI, "Utils")
LUI.Utils.SearchQuery = ensure(LUI.Utils, "SearchQuery")
LUI.Utils.Coords = ensure(LUI.Utils, "Coords")
LUI.Utils.RaidLayout = ensure(LUI.Utils, "RaidLayout")
LUI.Utils.Base93 = ensure(LUI.Utils, "Base93")
LUI.Chat = ensure(LUI, "Chat")
LUI.Data = ensure(LUI, "Data")
LUI.Data.Lore = ensure(LUI.Data, "Lore")
LUI.Data.Bestiary = ensure(LUI.Data, "Bestiary")
LUI.Data.Bestiary.DB = ensure(LUI.Data.Bestiary, "DB")
LUI.Locale = ensure(LUI, "Locale")
LUI.Reloader = ensure(LUI, "Reloader")
LUI.src = ensure(LUI, "src")
LUI.src.Languages = ensure(LUI.src, "Languages")

LUI.Settings = ensure(LUI, "Settings")
LUI.Settings.State = ensure(LUI.Settings, "State")
LUI.Settings.Enums = ensure(LUI.Settings, "Enums")
LUI.Settings.ToLotro = ensure(LUI.Settings, "ToLotro")
LUI.Settings.Defaults = ensure(LUI.Settings, "Defaults")
LUI.Settings.Defaults.DefaultLayouts = ensure(LUI.Settings.Defaults, "DefaultLayouts")
LUI.Settings.Colors = ensure(LUI.Settings, "Colors")
LUI.Settings.Persistence = ensure(LUI.Settings, "Persistence")
LUI.Settings.Migrations = ensure(LUI.Settings, "Migrations")
LUI.Settings.PluginDataTypes = ensure(LUI.Settings, "PluginDataTypes")
LUI.Settings.Content = ensure(LUI.Settings, "Content")
LUI.Settings.Controls = ensure(LUI.Settings, "Controls")
LUI.Settings.Tabs = ensure(LUI.Settings, "Tabs")
LUI.Settings.Pages = ensure(LUI.Settings, "Pages")
LUI.Settings.Pages.StatusBar = ensure(LUI.Settings.Pages, "StatusBar")
LUI.Settings.Preview = ensure(LUI.Settings, "Preview")
LUI.Settings.Preview.GroupVitals = ensure(LUI.Settings.Preview, "GroupVitals")
LUI.Settings.Window = ensure(LUI.Settings, "Window")

LUI.UI = ensure(LUI, "UI")
LUI.UI.Style = ensure(LUI.UI, "Style")
LUI.UI.Widgets = ensure(LUI.UI, "Widgets")
LUI.UI.Assets = ensure(LUI.UI, "Assets")
LUI.UI.ImageSizes = ensure(LUI.UI, "ImageSizes")
LUI.UI.AssetIds = LUI.UI.Assets
LUI.UI.Shortcuts = ensure(LUI.UI, "Shortcuts")
LUI.UI.NativeScaling = ensure(LUI.UI, "NativeScaling")
LUI.UI.MoveMode = ensure(LUI.UI, "MoveMode")
LUI.UI.Hidable = ensure(LUI.UI, "Hidable")
LUI.UI.PopupState = ensure(LUI.UI, "PopupState")
LUI.UI.ItemActions = ensure(LUI.UI, "ItemActions")

LUI.Features = ensure(LUI, "Features")
LUI.Features.Assets = ensure(LUI.Features, "Assets")
LUI.Features.Encyclopedia = ensure(LUI.Features, "Encyclopedia")
LUI.Features.Cooldowns = ensure(LUI.Features, "Cooldowns")
LUI.Features.Crafting = ensure(LUI.Features, "Crafting")
LUI.Features.Drops = ensure(LUI.Features, "Drops")
LUI.Features.ExpiringEffects = ensure(LUI.Features, "ExpiringEffects")
LUI.Features.Inventory = ensure(LUI.Features, "Inventory")
LUI.Features.Launcher = ensure(LUI.Features, "Launcher")
LUI.Features.StatusBar = ensure(LUI.Features, "StatusBar")
LUI.Features.StatusBar.Common = ensure(LUI.Features.StatusBar, "Common")
LUI.Features.StatusBar.APIChat = ensure(LUI.Features.StatusBar, "APIChat")
LUI.Features.StatusBar.APICommandParser = ensure(LUI.Features.StatusBar, "APICommandParser")
LUI.Features.StatusBar.APIItems = ensure(LUI.Features.StatusBar, "APIItems")
LUI.Features.StatusBar.Widgets = ensure(LUI.Features.StatusBar, "Widgets")
LUI.Features.Travel = ensure(LUI.Features, "Travel")
LUI.Features.Upkeep = ensure(LUI.Features, "Upkeep")
LUI.Features.Vitals = ensure(LUI.Features, "Vitals")
LUI.Features.Vitals.GroupLayout = ensure(LUI.Features.Vitals, "GroupLayout")
LUI.Features.Vitals.GroupOrdering = ensure(LUI.Features.Vitals, "GroupOrdering")
LUI.Features.Vitals.GroupSnapshot = ensure(LUI.Features.Vitals, "GroupSnapshot")
LUI.Features.Vitals.GroupRosterWatcher = ensure(LUI.Features.Vitals, "GroupRosterWatcher")
LUI.Features.Vitals.RaidConfig = ensure(LUI.Features.Vitals, "RaidConfig")
LUI.Features.Vitals.RaidShareCodec = ensure(LUI.Features.Vitals, "RaidShareCodec")
LUI.Features.Vitals.RaidShareListener = ensure(LUI.Features.Vitals, "RaidShareListener")

LUI.Runtime = ensure(LUI, "Runtime")
LUI.Runtime.Windows = ensure(LUI.Runtime, "Windows")
LUI.Runtime.Stores = ensure(LUI.Runtime, "Stores")
LUI.Runtime.Caches = ensure(LUI.Runtime, "Caches")
LUI.Runtime.Caches.Assets = ensure(LUI.Runtime.Caches, "Assets")
LUI.Runtime.Caches.Bestiary = ensure(LUI.Runtime.Caches, "Bestiary")
LUI.Runtime.Flags = ensure(LUI.Runtime, "Flags")
LUI.Runtime.Commands = ensure(LUI.Runtime, "Commands")
LUI.Runtime.Apply = ensure(LUI.Runtime, "Apply")
