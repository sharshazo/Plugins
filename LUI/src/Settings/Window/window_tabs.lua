-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local ConfigWindow = _G.LUI.Settings.ConfigWindow
local Pages = _G.LUI.Settings.Pages
import "LUI.src.Settings.Tabs.Global.global_page"
import "LUI.src.Settings.Tabs.Vitals.vitals_page"
import "LUI.src.Settings.Tabs.ExpiringEffects.expiring_effects_page"
import "LUI.src.Settings.Tabs.Cooldowns.cooldowns_page"
import "LUI.src.Settings.Tabs.Upkeep.upkeep_page"
import "LUI.src.Settings.Tabs.Drops.drops_page"
import "LUI.src.Settings.Tabs.Inventory.inventory_page"
import "LUI.src.Settings.Tabs.Crafting.crafting_page"
import "LUI.src.Settings.Tabs.Encyclopedia.encyclopedia_page"
import "LUI.src.Settings.Tabs.Travel.travel_page"
import "LUI.src.Settings.Tabs.Assets.assets_page"
import "LUI.src.Settings.Tabs.Launcher.launcher_page"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_page"
import "LUI.src.Settings.Tabs.ProfileManager.profile_manager_page"
import "LUI.src.Settings.Tabs.Help.help_page"

local GlobalPage = Pages.GlobalPage
local VitalsPage = Pages.VitalsPage
local ExpiringEffectsPage = Pages.ExpiringEffectsPage
local CooldownsFeaturePage = Pages.CooldownsFeaturePage
local UpkeepPage = Pages.UpkeepPage
local DropsPage = Pages.DropsPage
local InventoryPage = Pages.InventoryPage
local CraftingPage = Pages.CraftingPage
local EncyclopediaPage = Pages.EncyclopediaPage
local TravelPage = Pages.TravelPage
local AssetsPage = Pages.AssetsPage
local LauncherPage = Pages.LauncherPage
local StatusBarPage = Pages.StatusBarPage
local ProfileManagerPage = Pages.ProfileManagerPage
local HelpPage = Pages.HelpPage

local function _normalize_main_tab_request(main_key, preferred_sub_key)
    if type(main_key) ~= "string" then
        return "global", preferred_sub_key
    end

    if main_key == "self_vitals" then
        return "vitals", "self"
    end
    if main_key == "expiring_effects" then
        return "expiring_effects", "self"
    end
    if main_key == "cooldowns" then
        return "cooldowns", preferred_sub_key
    end
    if main_key == "target_vitals" then
        return "vitals", "target"
    end
    if main_key == "companion_vitals" then
        return "vitals", "companion"
    end
    if main_key == "target_boss_vitals" then
        return "vitals", "boss"
    end
    if main_key == "target_targets_target" then
        return "vitals", "target_targets_target"
    end
    if main_key == "expiring_target_effects" then
        return "expiring_effects", "target"
    end
    if main_key == "fellowship_vitals" then
        return "vitals", "fellowship"
    end
    if main_key == "raid_vitals" then
        return "vitals", "raid"
    end

    return main_key, preferred_sub_key
end

local function _apply_main_tab_content_border(window, page)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    window.main_tab_bar:set_show_content_border(page ~= nil and page.show_main_content_border == true)
end

local function _find_main_tab(window, main_key)
    if window == nil or window.main_tab_bar == nil then
        return nil, nil
    end

    return window.main_tab_bar:find_index(function(_, page)
        return page ~= nil and page._tab_key == main_key
    end)
end

function ConfigWindow:_on_main_tab_changed(index, page, _, preferred_sub_key)
    if page == nil then
        return
    end

    local main_key = page._tab_key
    self.active_main_tab = main_key
    _apply_main_tab_content_border(self, page)
    self._pending_main_tab_sub_key = nil

    self:hide_hint()
    self:layout()

    if page.on_selected ~= nil then
        page:on_selected(preferred_sub_key)
    elseif page.layout ~= nil then
        page:layout()
    end

    if page.get_active_tab_key ~= nil then
        self.active_tab = page:get_active_tab_key() or main_key
    else
        self.active_tab = main_key
    end
end

function ConfigWindow:_activate_active_page()
    local index = self.main_tab_bar ~= nil and self.main_tab_bar:get_selected_index() or nil
    local page = self.main_tab_bar ~= nil and self.main_tab_bar:get_selected_widget() or nil
    if page == nil then
        return
    end

    self:_on_main_tab_changed(index, page, self.main_tab_bar:get_selected_text(), nil)
end

function ConfigWindow:build_tabs()
    local global_page = GlobalPage(self)
    global_page._tab_key = "global"
    self.main_tab_bar:add_tab(TR["Global"], global_page)

    local vitals_page = VitalsPage(self)
    vitals_page._tab_key = "vitals"
    self.main_tab_bar:add_tab(TR["Vitals"], vitals_page)

    local expiring_effects_page = ExpiringEffectsPage(self)
    expiring_effects_page._tab_key = "expiring_effects"
    self.main_tab_bar:add_tab(TR["Expiring Effects"], expiring_effects_page)

    local cooldowns_page = CooldownsFeaturePage(self)
    cooldowns_page._tab_key = "cooldowns"
    self.main_tab_bar:add_tab(TR["Cooldowns"], cooldowns_page)

    local upkeep_page = UpkeepPage(self)
    upkeep_page._tab_key = "upkeep"
    self.main_tab_bar:add_tab(TR["Upkeep"], upkeep_page)

    local drops_page = DropsPage(self)
    drops_page._tab_key = "drops"
    self.main_tab_bar:add_tab(TR["Drops"], drops_page)

    local inventory_page = InventoryPage(self)
    inventory_page._tab_key = "inventory"
    self.main_tab_bar:add_tab(TR["Inventory"], inventory_page)

    local crafting_page = CraftingPage(self)
    crafting_page._tab_key = "crafting"
    self.main_tab_bar:add_tab(TR["Crafting"], crafting_page)

    local encyclopedia_page = EncyclopediaPage(self)
    encyclopedia_page._tab_key = "encyclopedia"
    self.main_tab_bar:add_tab(TR["Encyclopedia"], encyclopedia_page)

    local travel_page = TravelPage(self)
    travel_page._tab_key = "travel"
    self.main_tab_bar:add_tab(TR["Travel"], travel_page)

    local assets_page = AssetsPage(self)
    assets_page._tab_key = "assets"
    self.main_tab_bar:add_tab(TR["Assets"], assets_page)

    local launcher_page = LauncherPage(self)
    launcher_page._tab_key = "launcher"
    self.main_tab_bar:add_tab(TR["LUI Menu"], launcher_page)

    local status_bar_page = StatusBarPage(self)
    status_bar_page._tab_key = "status_bar"
    self.main_tab_bar:add_tab(TR["Status Bar"], status_bar_page)

    local profile_manager_page = ProfileManagerPage(self)
    profile_manager_page._tab_key = "profile_manager"
    self.main_tab_bar:add_tab(TR["Profiles"], profile_manager_page)

    -- Pestaña "Help" (Ayuda) quitada a pedido del usuario. El archivo
    -- Tabs/Help/help_page.lua sigue importado (no se borra nada); si alguien
    -- pide la pestaña "help", select_main_tab ya cae sola en "global".
end

function ConfigWindow:select_main_tab(main_key, preferred_sub_key)
    main_key, preferred_sub_key = _normalize_main_tab_request(main_key, preferred_sub_key)

    local index, page = _find_main_tab(self, main_key)
    if index == nil or page == nil then
        main_key = "global"
        preferred_sub_key = nil
        index, page = _find_main_tab(self, main_key)
    end
    if index == nil or page == nil then
        return
    end

    if self.main_tab_bar ~= nil and self.main_tab_bar:get_selected_index() == index then
        self:_on_main_tab_changed(index, page, self.main_tab_bar:get_selected_text(), preferred_sub_key)
        return
    end

    self._pending_main_tab_sub_key = preferred_sub_key
    self.main_tab_bar:select_tab(index)
end
