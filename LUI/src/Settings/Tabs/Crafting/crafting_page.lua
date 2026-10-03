-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local DISPLAY_MODE_LABELS = {
    TR["Pages (Recommended)"],
    TR["Scroll view"],
}

local DISPLAY_MODE_VALUES = {
    "pages",
    "scroll",
}

local DISPLAY_MODE_HELP = table.concat({
    TR["Changes take effect only after reloading the plugin."],
    "",
    TR["Scroll view creates many row widgets. On large recipe lists it can increase memory usage and slow load/unload."],
}, "\n")

-- Las listas de etiquetas de arriba se arman al IMPORTAR este archivo,
-- antes de que main.lua cargue el idioma elegido -- quedaban siempre en
-- ingles. _tr_list las vuelve a traducir al construir la pestaña (sus
-- valores en ingles son las mismas claves de traduccion).
local function _tr_list(list)
    local out = {}
    for i = 1, #list do
        out[i] = TR[list[i]]
    end
    return out
end

local function _display_mode_help()
    return table.concat({
        TR["Changes take effect only after reloading the plugin."],
        "",
        TR["Scroll view creates many row widgets. On large recipe lists it can increase memory usage and slow load/unload."],
    }, "\n")
end

local CraftingPage = class(ConfigTabs)
Pages.CraftingPage = CraftingPage

function CraftingPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_checkbox("crafting_enabled", TR["Enabled"],
        function(value)
            self._settings.crafting.enabled = value == true
        end,
        function()
            return self._settings.crafting.enabled == true
        end)
    self:add_tab(TR["General"], "general", general)

    local recipes = ConfigContent(window, 4)
    recipes:add_dropdown("crafting_display_mode", TR["Display"], _tr_list(DISPLAY_MODE_LABELS), DISPLAY_MODE_VALUES,
        function(value)
            self._settings.crafting.display_mode = value
        end,
        function()
            return self._settings.crafting.display_mode
        end, _display_mode_help())
    recipes:add_info(TR["Reload the plugin for display mode changes to take effect."])
    recipes.controls.crafting_display_mode.visible_if = function()
        return self.controls.crafting_enabled.cb:IsChecked() == true
    end
    self:add_tab(TR["Recipes"], "recipes", recipes)
end

function CraftingPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
