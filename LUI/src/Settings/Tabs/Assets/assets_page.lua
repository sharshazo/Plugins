-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local LUI_ENUMS = _G.LUI.Settings.Enums
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local TILE_SIZE_LABELS = {
    TR["Small (32)"],
    TR["Medium (40)"],
    TR["Large (48)"],
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

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

local VIEW_MODE_LABELS = {
    TR["Icons"],
    TR["Details"],
}

local VIEW_MODE_VALUES = {
    LUI_ENUMS.assets_view_mode.ICONS,
    LUI_ENUMS.assets_view_mode.DETAILS,
}

local AssetsPage = class(ConfigTabs)
Pages.AssetsPage = AssetsPage

function AssetsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_checkbox("assets_enabled", TR["Enabled"],
        function(value)
            self._settings.assets.enabled = value == true
        end,
        function()
            return self._settings.assets.enabled == true
        end)
    general:add_dropdown("assets_view_mode", TR["View"], _tr_list(VIEW_MODE_LABELS), VIEW_MODE_VALUES,
        function(value)
            self._settings.assets.view_mode = value
        end,
        function()
            return self._settings.assets.view_mode
        end)
    self:add_tab(TR["General"], "general", general)

    local tiles = ConfigContent(window, 4)
    tiles:add_dropdown("assets_tile_icons", TR["Icons"], _tr_list(TILE_SIZE_LABELS), TILE_SIZE_VALUES,
        function(value)
            self._settings.assets.tile.icons = value
        end,
        function()
            return self._settings.assets.tile.icons
        end)
    tiles:add_dropdown("assets_tile_details", TR["Details"], _tr_list(TILE_SIZE_LABELS), TILE_SIZE_VALUES,
        function(value)
            self._settings.assets.tile.details = value
        end,
        function()
            return self._settings.assets.tile.details
        end)
    self:add_tab(TR["Tiles"], "tiles", tiles)
end

function AssetsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
