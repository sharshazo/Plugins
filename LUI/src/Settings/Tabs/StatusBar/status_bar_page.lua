-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local StatusBarPageNamespace = Pages.StatusBar
local Windows = _G.LUI.Runtime.Windows
local ConfigNestedTabs = _G.LUI.Settings.Content.ConfigNestedTabs
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local LUI_ENUMS = _G.LUI.Settings.Enums
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.nested_tabs"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_wallet_selector"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_layout_help"

local CreateStatusBarWalletSelector = StatusBarPageNamespace.create_wallet_selector
local BuildStatusBarLayoutHelp = StatusBarPageNamespace.build_layout_help
local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _bind_outline_visibility(owner_page, colors_font_page, style_key, outline_key)
    owner_page.controls[outline_key].visible_if = function()
        return _is_outline(owner_page.controls[style_key])
    end

    local prev = owner_page.controls[style_key].on_changed
    owner_page.controls[style_key].on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        colors_font_page:layout()
        owner_page:layout()
    end
end

local function _new_colors_section(window, settings_getter)
    local ui = window._ui

    local background = ConfigContent(window, 4)
    background:add_color_picker("sb_bg_color", TR["Background color"],
        function(value)
            settings_getter().bg.color = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().bg.color)
        end)

    local font = ConfigContent(window, 4)
    font:add_color_picker("sb_font_color", TR["Font color"],
        function(value)
            settings_getter().font.color = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().font.color)
        end)
    font:add_color_picker("sb_font_outline_color", TR["Outline color"],
        function(value)
            settings_getter().font.outline_color = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().font.outline_color)
        end)

    local inventory = ConfigContent(window, 4)
    inventory:add_color_picker("sb_inv_yellow", TR["Warn color (30%)"],
        function(value)
            settings_getter().widgets.inventory_space.color.yellow = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().widgets.inventory_space.color.yellow)
        end)
    inventory:add_color_picker("sb_inv_orange", TR["Warn color (20%)"],
        function(value)
            settings_getter().widgets.inventory_space.color.orange = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().widgets.inventory_space.color.orange)
        end)
    inventory:add_color_picker("sb_inv_red", TR["Warn color (10%)"],
        function(value)
            settings_getter().widgets.inventory_space.color.red = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().widgets.inventory_space.color.red)
        end)

    local durability = ConfigContent(window, 4)
    durability:add_color_picker("sb_durability_green", TR["Green color"],
        function(value)
            settings_getter().widgets.equipment_wear.color.green = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().widgets.equipment_wear.color.green)
        end)
    durability:add_color_picker("sb_durability_yellow", TR["Yellow color"],
        function(value)
            settings_getter().widgets.equipment_wear.color.yellow = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().widgets.equipment_wear.color.yellow)
        end)
    durability:add_color_picker("sb_durability_red", TR["Red color"],
        function(value)
            settings_getter().widgets.equipment_wear.color.red = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().widgets.equipment_wear.color.red)
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Background"], "background", background)
    page:add_tab(TR["Font"], "font", font)
    page:add_tab(TR["Inventory"], "inventory", inventory)
    page:add_tab(TR["Equipment Wear"], "durability", durability)

    return page, font
end

local function _new_widgets_section(window, settings_getter)
    local time_format_labels = { TR["24-hour"], TR["AM/PM"] }
    local time_format_values = { LUI_ENUMS.time_format.H24, LUI_ENUMS.time_format.AMPM }

    local time = ConfigContent(window, 4)
    time:add_line_edit("sb_time_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.time_local.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.time_local.width)
        end)
    time:add_row_break()
    time:add_dropdown("sb_time_format", TR["Time format"], time_format_labels, time_format_values,
        function(value)
            settings_getter().widgets.time_local.time_format = value
        end,
        function()
            return settings_getter().widgets.time_local.time_format
        end)
    time:add_dropdown("sb_time_text_alignment", TR["Text alignment"], time.text_alignment_labels,
        time.text_alignment_values,
        function(value)
            settings_getter().widgets.time_local.text_alignment = value
        end,
        function()
            return settings_getter().widgets.time_local.text_alignment
        end)

    local inventory = ConfigContent(window, 4)
    inventory:add_line_edit("sb_inv_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.inventory_space.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.inventory_space.width)
        end)
    inventory:add_row_break()
    inventory:add_checkbox("sb_inv_icon", TR["Icon"],
        function(value)
            settings_getter().widgets.inventory_space.icon = value == true
        end,
        function()
            return settings_getter().widgets.inventory_space.icon == true
        end)
    inventory:add_dropdown("sb_inv_text_alignment", TR["Text alignment"], inventory.text_alignment_labels,
        inventory.text_alignment_values,
        function(value)
            settings_getter().widgets.inventory_space.text_alignment = value
        end,
        function()
            return settings_getter().widgets.inventory_space.text_alignment
        end)

    local durability = ConfigContent(window, 4)
    durability:add_line_edit("sb_durability_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.equipment_wear.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.equipment_wear.width)
        end)
    durability:add_row_break()
    durability:add_checkbox("sb_durability_icon", TR["Icon"],
        function(value)
            settings_getter().widgets.equipment_wear.icon = value == true
        end,
        function()
            return settings_getter().widgets.equipment_wear.icon == true
        end)
    durability:add_dropdown("sb_durability_text_alignment", TR["Text alignment"], durability.text_alignment_labels,
        durability.text_alignment_values,
        function(value)
            settings_getter().widgets.equipment_wear.text_alignment = value
        end,
        function()
            return settings_getter().widgets.equipment_wear.text_alignment
        end)
    durability:add_row_break()
    durability:add_checkbox("sb_durability_coloring", TR["Enable rich-text coloring"],
        function(value)
            settings_getter().widgets.equipment_wear.coloring = value == true
        end,
        function()
            return settings_getter().widgets.equipment_wear.coloring == true
        end, true)

    local money = ConfigContent(window, 4)
    money:add_line_edit("sb_money_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.money.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.money.width)
        end)
    money:add_row_break()
    money:add_dropdown("sb_money_text_alignment", TR["Text alignment"], money.text_alignment_labels,
        money.text_alignment_values,
        function(value)
            settings_getter().widgets.money.text_alignment = value
        end,
        function()
            return settings_getter().widgets.money.text_alignment
        end)

    local wallet = ConfigContent(window, 4)
    wallet:add_line_edit("sb_wallet_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.wallet.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.wallet.width)
        end)
    wallet:add_row_break()
    wallet:add_dropdown("sb_wallet_text_alignment", TR["Text alignment"], wallet.text_alignment_labels,
        wallet.text_alignment_values,
        function(value)
            settings_getter().widgets.wallet.text_alignment = value
        end,
        function()
            return settings_getter().widgets.wallet.text_alignment
        end)
    wallet:add_row_break()
    CreateStatusBarWalletSelector(wallet, "sb_wallet_items")
    local wallet_items = wallet.controls.sb_wallet_items
    local wallet_load = wallet.load
    local wallet_save = wallet.save
    function wallet:load()
        wallet_load(self)
        wallet_items:set_items(settings_getter().widgets.wallet.items)
    end
    function wallet:save()
        wallet_save(self)
        settings_getter().widgets.wallet.items = wallet_items:get_items()
    end

    local item = ConfigContent(window, 4)
    item:add_line_edit("sb_item_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.item.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.item.width)
        end)

    local shortcuts = ConfigContent(window, 4)
    shortcuts:add_line_edit("sb_shortcut_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.shortcut.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.shortcut.width)
        end)
    shortcuts:add_line_edit("sb_shortcut_height", TR["Height"],
        function(value)
            local height = tonumber(value)
            if height ~= nil then
                settings_getter().widgets.shortcut.height = height
            end
        end,
        function()
            return tostring(settings_getter().widgets.shortcut.height)
        end)

    local craft_plan = ConfigContent(window, 4)
    craft_plan:add_line_edit("sb_craft_plan_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.craft_plan.width = width
            end
        end,
        function()
            return tostring(settings_getter().widgets.craft_plan.width)
        end)
    craft_plan:add_line_edit("sb_craft_plan_max_visible", TR["Max visible resources"],
        function(value)
            local max_visible = tonumber(value)
            if max_visible ~= nil then
                settings_getter().widgets.craft_plan.max_visible = max_visible
            end
        end,
        function()
            return tostring(settings_getter().widgets.craft_plan.max_visible)
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Time (local)"], "time", time)
    page:add_tab(TR["Inventory"], "inventory", inventory)
    page:add_tab(TR["Equipment Wear"], "durability", durability)
    page:add_tab(TR["Money"], "money", money)
    page:add_tab(TR["Wallet"], "wallet", wallet)
    page:add_tab(TR["Tracked Item"], "item", item)
    page:add_tab(TR["Shortcut Buttons"], "shortcuts", shortcuts)
    page:add_tab(TR["Crafting Plan"], "craft_plan", craft_plan)

    return page
end

local StatusBarPage = class(ConfigTabs)
Pages.StatusBarPage = StatusBarPage

function StatusBarPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local settings_getter = function()
        return self._settings.status_bar
    end

    local general = ConfigContent(window, 4)
    general:add_checkbox("sb_enabled", TR["Enabled"],
        function(value)
            settings_getter().enabled = value == true
        end,
        function()
            return settings_getter().enabled == true
        end, true)
    self:add_tab(TR["General"], "general", general)

    -- cartel de misiones, arriba al centro (src/QuestBanner). Usa las
    -- mismas claves que el cartel de zona que habia antes (zone_*).
    local zone = ConfigContent(window, 4)
    zone:add_checkbox("sb_zone_banner", TR["Show quest banner (new quest title / Completed)"],
        function(value)
            settings_getter().zone_banner = value == true
        end,
        function()
            return settings_getter().zone_banner ~= false
        end, true)
    zone:add_row_break()
    zone:add_checkbox("sb_zone_tint", TR["Tint the bar with the banner color"],
        function(value)
            settings_getter().zone_tint = value == true
        end,
        function()
            return settings_getter().zone_tint ~= false
        end, true)
    zone:add_row_break()
    zone:add_checkbox("sb_zone_animations", TR["Banner animations (aura, shine, sparks)"],
        function(value)
            settings_getter().zone_animations = value == true
        end,
        function()
            return settings_getter().zone_animations ~= false
        end, true)
    self:add_tab(TR["Quest banner"], "zone_banner", zone)

    local background = ConfigContent(window, 4)
    background:add_line_edit("sb_bg_opacity", TR["Background opacity (0..1)"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().bg.opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().bg.opacity)
        end)
    self:add_tab(TR["Background"], "background", background)

    local font = ConfigContent(window, 4)
    font:add_dropdown("sb_font_name", TR["Font"], font.font_name_labels, font.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function()
            return settings_getter().font.name
        end)
    font:add_line_edit("sb_font_size", TR["Font size"],
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function()
            return tostring(settings_getter().font.size)
        end)
    font:add_dropdown("sb_font_style", TR["Font style"], font.font_style_labels, font.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function()
            return settings_getter().font.style
        end)
    self:add_tab(TR["Font"], "font", font)

    local layout_help = BuildStatusBarLayoutHelp()
    local layout = ConfigContent(window, 4)
    layout:add_line_edit("sb_height", TR["Height"],
        function(value)
            local height = tonumber(value)
            if height ~= nil then
                settings_getter().height = height
            end
        end,
        function()
            return tostring(settings_getter().height)
        end)
    layout:add_row_break()
    layout:add_line_edit("sb_layout_left", TR["Left layout"],
        function(value)
            settings_getter().layout.left = value
        end,
        function()
            return settings_getter().layout.left
        end, layout_help, true)
    layout:add_row_break()
    layout:add_line_edit("sb_layout_center", TR["Center layout"],
        function(value)
            settings_getter().layout.center = value
        end,
        function()
            return settings_getter().layout.center
        end, layout_help, true)
    layout:add_row_break()
    layout:add_line_edit("sb_layout_right", TR["Right layout"],
        function(value)
            settings_getter().layout.right = value
        end,
        function()
            return settings_getter().layout.right
        end, layout_help, true)
    self:add_tab(TR["Layout"], "layout", layout)

    local colors, colors_font = _new_colors_section(window, settings_getter)
    self:add_tab(TR["Colors"], "colors", colors)
    self:add_tab(TR["Widgets"], "widgets", _new_widgets_section(window, settings_getter))

    _bind_outline_visibility(self, colors_font, "sb_font_style", "sb_font_outline_color")
    self:refresh_layout_help()
end

function StatusBarPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function StatusBarPage:refresh_layout_help()
    local help_text = BuildStatusBarLayoutHelp()
    local keys = { "sb_layout_left", "sb_layout_center", "sb_layout_right" }
    for i = 1, #keys do
        self.controls[keys[i]].help_text = help_text
    end
end

function StatusBarPage:load()
    self:refresh_layout_help()
    ConfigTabs.load(self)
end

function StatusBarPageNamespace.refresh_layout_help()
    local window = Windows.config
    if window == nil then
        return
    end
    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "status_bar"
    end)
    page:refresh_layout_help()
end
