-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigSectionPage = _G.LUI.Settings.Content.ConfigSectionPage
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
import "LUI.src.Settings.Content.section_page"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _apply_color(ui, dest, hex)
    local color = ui.hex_to_color(hex)
    dest.R, dest.G, dest.B = color.R, color.G, color.B
end

local function _bind_outline_visibility(owner_page, nested_text_page, style_key, outline_key)
    owner_page.controls[outline_key].visible_if = function()
        return _is_outline(owner_page.controls[style_key])
    end

    local prev = owner_page.controls[style_key].on_changed
    owner_page.controls[style_key].on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        nested_text_page:layout()
        owner_page:layout()
    end
end

local function _new_colors_section(window, refresh_preview, settings_getter, prefix, bar_specs)
    local ui = window._ui

    local frame = ConfigContent(window, 3, refresh_preview)
    frame:add_color_picker(prefix .. "_background_color", TR["Background Color"],
        function(value)
            _apply_color(ui, settings_getter().color.background, value)
        end,
        function()
            return ui.color_to_hex(settings_getter().color.background)
        end)
    frame:add_row_break()
    frame:add_checkbox(prefix .. "_bar_background_matches_fill", TR["Matching background"],
        function(value)
            settings_getter().bar_background_matches_fill = value == true
        end,
        function()
            return settings_getter().bar_background_matches_fill == true
        end)
    frame:add_line_edit(prefix .. "_bar_background_dimming", TR["Dimming"],
        function(value)
            local dimming = tonumber(value)
            if dimming ~= nil then
                settings_getter().bar_background_dimming = dimming
            end
        end,
        function()
            return tostring(settings_getter().bar_background_dimming)
        end)
    frame:add_row_break()
    frame:add_line_edit(prefix .. "_background_opacity", TR["Background opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().background_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().background_opacity)
        end)
    frame:add_row_break()
    frame:add_color_picker(prefix .. "_border_color", TR["Border Color"],
        function(value)
            _apply_color(ui, settings_getter().color.border, value)
        end,
        function()
            return ui.color_to_hex(settings_getter().color.border)
        end)

    local bars = ConfigContent(window, 3, refresh_preview)
    for i = 1, #bar_specs do
        local spec = bar_specs[i]
        bars:add_color_picker(spec.key, spec.label,
            function(value)
                _apply_color(ui, spec.get_target(settings_getter), value)
            end,
            function()
                return ui.color_to_hex(spec.get_target(settings_getter))
            end)
    end
    bars:add_row_break()
    bars:add_line_edit(prefix .. "_bar_opacity", TR["Bar opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().bar_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().bar_opacity)
        end)
    local text = ConfigContent(window, 3, refresh_preview)
    text:add_color_picker(prefix .. "_font_color", TR["Font Color"],
        function(value)
            _apply_color(ui, settings_getter().font.color, value)
        end,
        function()
            return ui.color_to_hex(settings_getter().font.color)
        end)
    text:add_color_picker(prefix .. "_font_outline_color", TR["Outline Color"],
        function(value)
            _apply_color(ui, settings_getter().font.outline_color, value)
        end,
        function()
            return ui.color_to_hex(settings_getter().font.outline_color)
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Bars"], "bars", bars)
    page:add_tab(TR["Text"], "text", text)

    return page, text
end

local function _new_actor_page(window, preview_key, preview_height, refresh_preview_fn, prefix, settings_getter, bar_specs)
    local page = ConfigSectionPage(window, preview_key, preview_height, refresh_preview_fn)
    local bar_mode_labels = { TR["Load"], TR["Unload"] }
    local bar_mode_values = { LUI_ENUMS.bar_mode.LOAD, LUI_ENUMS.bar_mode.UNLOAD }
    local orientation_labels = { TR["Horizontal"], TR["Vertical"] }
    local orientation_values = { LUI_ENUMS.orientation.HORIZONTAL, LUI_ENUMS.orientation.VERTICAL }
    local side_labels = { TR["Left/Top"], TR["Right/Bottom"] }
    local side_values = { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT }

    local general = ConfigContent(window, 4, page.refresh_preview)
    general:add_checkbox(prefix .. "_enabled", TR["Enabled"],
        function(value)
            settings_getter().enabled = value == true
        end,
        function()
            return settings_getter().enabled == true
        end, true)
    general:add_row_break()
    general:add_checkbox(prefix .. "_show_buffs", TR["Track buffs"],
        function(value)
            settings_getter().show_buffs = value == true
        end,
        function()
            return settings_getter().show_buffs == true
        end, false)
    general:add_checkbox(prefix .. "_show_curable_debuffs", TR["Track curable debuffs"],
        function(value)
            settings_getter().show_curable_debuffs = value == true
        end,
        function()
            return settings_getter().show_curable_debuffs ~= false
        end, false)
    general:add_checkbox(prefix .. "_show_noncurable_debuffs", TR["Track non-curable debuffs"],
        function(value)
            settings_getter().show_noncurable_debuffs = value == true
        end,
        function()
            return settings_getter().show_noncurable_debuffs ~= false
        end, false)
    general:add_row_break()
    general:add_line_edit(prefix .. "_threshold", TR["Show when less than seconds remaining"],
        function(value)
            local threshold = tonumber(value)
            if threshold ~= nil then
                settings_getter().threshold = threshold
            end
        end,
        function()
            return tostring(settings_getter().threshold)
        end)
    page:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4, page.refresh_preview)
    layout:add_dropdown(prefix .. "_orientation", TR["Orientation"], orientation_labels, orientation_values,
        function(value)
            settings_getter().orientation = value
        end,
        function()
            return settings_getter().orientation
        end)
    layout:add_row_break()
    layout:add_line_edit(prefix .. "_bar_width", TR["Bar length"],
        function(value)
            local bar_width = tonumber(value)
            if bar_width ~= nil then
                settings_getter().bar_width = bar_width
            end
        end,
        function()
            return tostring(settings_getter().bar_width)
        end)
    layout:add_line_edit(prefix .. "_bar_height", TR["Bar thickness"],
        function(value)
            local bar_height = tonumber(value)
            if bar_height ~= nil then
                settings_getter().bar_height = bar_height
            end
        end,
        function()
            return tostring(settings_getter().bar_height)
        end)
    layout:add_line_edit(prefix .. "_border_width", TR["Border Width"],
        function(value)
            local border_width = tonumber(value)
            if border_width ~= nil then
                settings_getter().border_width = border_width
            end
        end,
        function()
            return tostring(settings_getter().border_width)
        end)
    layout:add_line_edit(prefix .. "_columns", TR["Columns"],
        function(value)
            local columns = tonumber(value)
            if columns ~= nil then
                settings_getter().columns = columns
            end
        end,
        function()
            return tostring(settings_getter().columns)
        end)
    layout:add_line_edit(prefix .. "_rows", TR["Rows"],
        function(value)
            local rows = tonumber(value)
            if rows ~= nil then
                settings_getter().rows = rows
            end
        end,
        function()
            return tostring(settings_getter().rows)
        end)
    layout:add_line_edit(prefix .. "_spacing", TR["Spacing"],
        function(value)
            local spacing = tonumber(value)
            if spacing ~= nil then
                settings_getter().spacing = spacing
            end
        end,
        function()
            return tostring(settings_getter().spacing)
        end)
    layout:add_row_break()
    layout:add_dropdown(prefix .. "_icon_side", TR["Icon position"], side_labels, side_values,
        function(value)
            settings_getter().icon_side = value
        end,
        function()
            return settings_getter().icon_side
        end)
    layout:add_dropdown(prefix .. "_bar_mode", TR["Bar mode"], bar_mode_labels, bar_mode_values,
        function(value)
            settings_getter().bar_mode = value
        end,
        function()
            return settings_getter().bar_mode
        end)
    layout:add_dropdown(prefix .. "_bar_expire_towards", TR["Bar expires towards"], side_labels,
        side_values,
        function(value)
            settings_getter().bar_expire_towards = value
        end,
        function()
            return settings_getter().bar_expire_towards
        end)
    page:add_tab(TR["Frame"], "frame", layout)

    local colors, colors_text = _new_colors_section(window, page.refresh_preview, settings_getter, prefix, bar_specs)
    page:add_tab(TR["Colors"], "colors", colors)

    local text = ConfigContent(window, 4, page.refresh_preview)
    text:add_checkbox(prefix .. "_show_time", TR["Display time"],
        function(value)
            settings_getter().show_time = value == true
        end,
        function()
            return settings_getter().show_time == true
        end)
    text:add_line_edit(prefix .. "_name_max_chars", TR["Max name characters"],
        function(value)
            local name_max_chars = tonumber(value)
            if name_max_chars ~= nil then
                settings_getter().name_max_chars = name_max_chars
            end
        end,
        function()
            return tostring(settings_getter().name_max_chars)
        end)
    text:add_row_break()
    text:add_dropdown(prefix .. "_font_name", TR["Font"], text.font_name_labels, text.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function()
            return settings_getter().font.name
        end)
    text:add_line_edit(prefix .. "_font_size", TR["Font Size"],
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function()
            return tostring(settings_getter().font.size)
        end)
    text:add_dropdown(prefix .. "_font_style", TR["Font Style"], text.font_style_labels, text.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function()
            return settings_getter().font.style
        end)
    page:add_tab(TR["Text"], "text", text)

    _bind_outline_visibility(page, colors_text, prefix .. "_font_style", prefix .. "_font_outline_color")
    return page
end

local ExpiringEffectsPage = class(ConfigTabs)
Pages.ExpiringEffectsPage = ExpiringEffectsPage

function ExpiringEffectsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local self_bar_specs = {
        {
            key = "expiring_effects_bar_color",
            label = TR["Buff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_buff
            end,
        },
        {
            key = "expiring_effects_debuff_curable_bar_color",
            label = TR["Curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_curable
            end,
        },
        {
            key = "expiring_effects_debuff_noncurable_bar_color",
            label = TR["Non-curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_noncurable
            end,
        },
    }
    local target_bar_specs = {
        {
            key = "expiring_target_effects_buff_bar_color",
            label = TR["Buff Bar Color"],
            get_target = function(settings_getter)
                return settings_getter().color.bar_buff
            end,
        },
        {
            key = "expiring_target_effects_bar_color",
            label = TR["Curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_curable
            end,
        },
        {
            key = "expiring_target_effects_debuff_noncurable_bar_color",
            label = TR["Non-curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_noncurable
            end,
        },
    }

    self:add_tab(TR["Self"], "self", _new_actor_page(window, "expiring_effects_preview", 53,
        function(win)
            win:update_expiring_effects_preview()
        end, "expiring_effects", function()
            return self._settings.self.expiring_effects
        end, self_bar_specs))
    self:add_tab(TR["Target"], "target", _new_actor_page(window, "expiring_target_effects_preview", 71,
        function(win)
            win:update_expiring_target_effects_preview()
        end, "expiring_target_effects", function()
            return self._settings.target.expiring_effects
        end, target_bar_specs))
end

function ExpiringEffectsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
