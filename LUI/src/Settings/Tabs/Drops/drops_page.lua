-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigNestedTabs = _G.LUI.Settings.Content.ConfigNestedTabs
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local LUI_ENUMS = _G.LUI.Settings.Enums
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Content.nested_tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int
local PREVIEW_GAP = 10
local PREVIEW_MIN_TOP_HEIGHT = 120
local PREVIEW_MIN_HEIGHT = 100

local function _apply_color(ui, dest, hex)
    local color = ui.hex_to_color(hex)
    dest.R, dest.G, dest.B = color.R, color.G, color.B
end

local function _new_colors_section(window, refresh_preview, settings_getter)
    local ui = window._ui

    local hud = ConfigContent(window, 4, refresh_preview)
    hud:add_line_edit("drops_hud_background_opacity", TR["Background opacity (0..1)"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().hud.background_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().hud.background_opacity)
        end)
    hud:add_color_picker("drops_hud_background_color", TR["Background color"],
        function(value)
            _apply_color(ui, settings_getter().hud.background_color, value)
        end,
        function()
            return ui.color_to_hex(settings_getter().hud.background_color)
        end)

    local item = ConfigContent(window, 4, refresh_preview)
    item:add_line_edit("drops_item_background_opacity", TR["Background opacity (0..1)"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().item.background_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().item.background_opacity)
        end)
    item:add_color_picker("drops_item_background_color", TR["Background color"],
        function(value)
            _apply_color(ui, settings_getter().item.background_color, value)
        end,
        function()
            return ui.color_to_hex(settings_getter().item.background_color)
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["HUD"], "hud", hud)
    page:add_tab(TR["Item"], "item", item)

    return page
end

local DropsPage = class(ConfigTabs)
Pages.DropsPage = DropsPage

function DropsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self._preview_default_height = 136
    self.controls = self.controls or {}

    local flow_labels = { TR["Latest at top"], TR["Latest at bottom"] }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }
    local align_labels = { TR["Top"], TR["Bottom"] }
    local align_values = { LUI_ENUMS.vertical_align.TOP, LUI_ENUMS.vertical_align.BOTTOM }
    local side_labels = { TR["Left"], TR["Right"] }
    local side_values = { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT }
    local refresh_preview = function()
        window:update_drops_preview()
    end
    local settings_getter = function()
        return self._settings.drops
    end

    local general = ConfigContent(window, 4, refresh_preview)
    general:add_checkbox("drops_enabled", TR["Enabled"],
        function(value)
            settings_getter().enabled = value == true
        end,
        function()
            return settings_getter().enabled == true
        end, true)
    general:add_row_break()
    general:add_line_edit("drops_visible_duration", TR["Visible duration (s)"],
        function(value)
            local visible_duration = tonumber(value)
            if visible_duration ~= nil then
                settings_getter().visible_duration = visible_duration
            end
        end,
        function()
            return tostring(settings_getter().visible_duration)
        end)
    general:add_row_break()
    general:add_checkbox("drops_merge_similar", TR["Merge similar drops"],
        function(value)
            settings_getter().merge_similar = value == true
        end,
        function()
            return settings_getter().merge_similar == true
        end, true)
    general:add_row_break()
    general:add_checkbox("drops_show_banner", TR["Show LOOT banner"],
        function(value)
            settings_getter().show_banner = value == true
        end,
        function()
            return settings_getter().show_banner ~= false
        end, true)
    general:add_row_break()
    general:add_checkbox("drops_rare_alert", TR["Alert for Incomparable / Legendary loot"],
        function(value)
            settings_getter().rare_alert = value == true
        end,
        function()
            return settings_getter().rare_alert ~= false
        end, true)
    general:add_info(
        TR["Carry-alls may bypass inventory item events. Those drops can appear without icon or hover and will be shown as text only."],
        42)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4, refresh_preview)
    layout:add_line_edit("drops_width", TR["Width"],
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().width = width
            end
        end,
        function()
            return tostring(settings_getter().width)
        end)
    layout:add_line_edit("drops_rows", TR["Rows"],
        function(value)
            local rows = tonumber(value)
            if rows ~= nil then
                settings_getter().rows = rows
            end
        end,
        function()
            return tostring(settings_getter().rows)
        end)
    layout:add_line_edit("drops_icon_size", TR["Icon Size"],
        function(value)
            local icon_size = tonumber(value)
            if icon_size ~= nil then
                settings_getter().icon_size = icon_size
            end
        end,
        function()
            return tostring(settings_getter().icon_size)
        end)
    layout:add_row_break()
    layout:add_dropdown("drops_flow", TR["Order"], flow_labels, flow_values,
        function(value)
            settings_getter().flow = value
        end,
        function()
            return settings_getter().flow
        end)
    layout:add_dropdown("drops_align", TR["Align"], align_labels, align_values,
        function(value)
            settings_getter().align = value
        end,
        function()
            return settings_getter().align
        end)
    layout:add_dropdown("drops_icon_side", TR["Icon position"], side_labels, side_values,
        function(value)
            settings_getter().icon_side = value
        end,
        function()
            return settings_getter().icon_side
        end)
    self:add_tab(TR["Layout"], "layout", layout)

    self:add_tab(TR["Colors"], "colors", _new_colors_section(window, refresh_preview, settings_getter))

    local motion = ConfigContent(window, 4, refresh_preview)
    motion:add_checkbox("drops_animations_enabled", TR["Animations"],
        function(value)
            settings_getter().animations_enabled = value == true
        end,
        function()
            return settings_getter().animations_enabled == true
        end, true)
    motion:add_row_break()
    motion:add_line_edit("drops_move_duration", TR["Move duration (ms)"],
        function(value)
            local move_duration = tonumber(value)
            if move_duration ~= nil then
                settings_getter().move_duration = move_duration
            end
        end,
        function()
            return tostring(settings_getter().move_duration)
        end)
    self:add_tab(TR["Motion"], "motion", motion)

    self.preview_holder = {
        kind = "custom",
        key = "drops_preview",
        height = self._preview_default_height,
    }
    self.preview_holder.control = Turbine.UI.Control()
    self.preview_holder.control:SetParent(self)
    self.preview_holder.control:SetMouseVisible(false)
    self.controls.drops_preview = self.preview_holder
end

function DropsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function DropsPage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    local preview_h = self.preview_holder.height or self._preview_default_height
    local preview_gap = scaled_int(PREVIEW_GAP)
    local min_top_h = scaled_int(PREVIEW_MIN_TOP_HEIGHT)
    local top_h = height - preview_h - preview_gap
    if top_h < min_top_h then
        top_h = min_top_h
        preview_h = height - top_h - preview_gap
    end
    if preview_h < scaled_int(PREVIEW_MIN_HEIGHT) then
        preview_h = scaled_int(PREVIEW_MIN_HEIGHT)
        top_h = height - preview_h - preview_gap
    end
    if top_h < 1 then
        top_h = 1
    end

    self.sub_tab_bar:SetPosition(0, 0)
    self.sub_tab_bar:SetSize(width, top_h)
    self.sub_tab_bar:refresh_layout()

    self.preview_holder.control:SetPosition(0, top_h + preview_gap)
    self.preview_holder.control:SetSize(width, preview_h)
end
