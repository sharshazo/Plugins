-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local UI = _G.LUI.UI
local Features = _G.LUI.Features
local Vitals = Features.Vitals
local Inventory = Features.Inventory
local Crafting = Features.Crafting
local Assets = Features.Assets
local Travel = Features.Travel
local StatusBar = Features.StatusBar
local Launcher = Features.Launcher
import "LUI.src.UI.native_scaling"
import "LUI.src.UI.shortcuts"
import "LUI.src.UI.hidable"
import "LUI.src.UI.move_ui"
import "LUI.src.Vitals"
import "LUI.src.UI.Widgets"
import "LUI.src.UI.item_actions"
import "LUI.src.Settings"
import "LUI.src.Inventory"
import "LUI.src.Crafting"
import "LUI.src.Assets"
import "LUI.src.Travel"
import "LUI.src.StatusBar"
import "LUI.src.Launcher"

UI.VitalsBase = Vitals.VitalsBase
UI.SelfVitals = Vitals.SelfVitals
UI.TargetVitals = Vitals.TargetVitals
UI.CompanionVitals = Vitals.CompanionVitals
UI.BossVitals = Vitals.BossVitals
UI.FellowshipVitals = Vitals.FellowshipVitals
UI.RaidVitals = Vitals.RaidVitals
UI.InventoryWindow = Inventory.InventoryWindow
UI.CraftingWindow = Crafting.CraftingWindow
UI.AssetsWindow = Assets.AssetsWindow
UI.TravelWindow = Travel.TravelWindow
UI.StatusBarWindow = StatusBar.StatusBarWindow
UI.LauncherMenu = Launcher.LauncherMenu
