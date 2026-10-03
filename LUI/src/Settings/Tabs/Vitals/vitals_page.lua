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
local State = _G.LUI.Settings.State
local Defaults = _G.LUI.Settings.Defaults
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.nested_tabs"
import "LUI.src.Settings.Content.section_page"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Tabs.Vitals.group_vitals_page"
import "LUI.src.Settings.Tabs.Vitals.standard_vitals_pages"
local GroupVitalsPageBuilder = Pages.GroupVitalsPageBuilder
local StandardVitalsPageBuilder = Pages.StandardVitalsPageBuilder
local NESTED_TAB_SCALE = 0.78
local NESTED_TAB_FONT_SIZE = 11
local SECTION_FRAME_PADDING = 8
local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end
local function _set_color(dest, color)
    dest.R, dest.G, dest.B = color.R, color.G, color.B
end
local function _add_number_field(page, key, label, get_value, set_value, help_text, full_width)
    page:add_line_edit(key, label,
        function(value)
            local number = tonumber(value)
            if number ~= nil then
                set_value(number)
            end
        end,
        function()
            return tostring(get_value())
        end,
        help_text, full_width)
end
local function _add_text_field(page, key, label, get_value, set_value, help_text, full_width)
    page:add_line_edit(key, label,
        function(value)
            set_value(value)
        end,
        function()
            return get_value()
        end,
        help_text, full_width)
end
local function _add_checkbox_field(page, key, label, get_value, set_value, full_width)
    page:add_checkbox(key, label,
        function(value)
            set_value(value == true)
        end,
        function()
            return get_value() == true
        end,
        full_width)
end
local function _add_dropdown_field(page, key, label, labels, values, get_value, set_value, help_text, full_width)
    page:add_dropdown(key, label, labels, values,
        function(value)
            set_value(value)
        end,
        function()
            return get_value()
        end,
        help_text, full_width)
end
local function _add_color_field(page, key, label, get_value, set_value, help_text, full_width)
    page:add_color_picker(key, label,
        function(value)
            set_value(page.hex_to_color(value))
        end,
        function()
            return page.color_to_hex(get_value())
        end,
        help_text, full_width)
end
local function _add_font_identity_controls(page, base_key, font, font_label, size_label, style_label)
    _add_dropdown_field(page, base_key .. "_font_name", font_label or TR["Font"], page.font_name_labels,
        page.font_name_values,
        function()
            return font().name
        end,
        function(value)
            font().name = value
        end)
    _add_number_field(page, base_key .. "_font_size", size_label or TR["Font Size"],
        function()
            return font().size
        end,
        function(value)
            font().size = value
        end)
    _add_dropdown_field(page, base_key .. "_font_style", style_label or TR["Font Style"], page.font_style_labels,
        page.font_style_values,
        function()
            return font().style
        end,
        function(value)
            font().style = value
        end)
end
local function _add_font_color_controls(page, base_key, font, color_label, outline_label)
    _add_color_field(page, base_key .. "_font_color", color_label or TR["Font Color"],
        function()
            return font().color
        end,
        function(color)
            _set_color(font().color, color)
        end)
    _add_color_field(page, base_key .. "_font_outline_color", outline_label or TR["Outline Color"],
        function()
            return font().outline_color
        end,
        function(color)
            _set_color(font().outline_color, color)
        end)
end

local function _bind_outline_visibility(owner_page, colors_page, outline_page, style_key, outline_key)
    local outline = outline_page.controls[outline_key]
    local style = owner_page.controls[style_key]
    local previous_on_changed = style.on_changed

    outline.visible_if = function()
        return style:get_value() == LUI_ENUMS.font_style.OUTLINE
    end

    style.on_changed = function(...)
        if type(previous_on_changed) == "function" then
            previous_on_changed(...)
        end
        outline_page:layout()
        colors_page:layout()
        owner_page:layout()
    end
end

local function _add_vitals_label_controls(page, prefix, label_index, label)
    local key = prefix .. "_label" .. tostring(label_index)

    _add_checkbox_field(page, key .. "_enabled", TR["Enabled"],
        function()
            return label().enabled
        end,
        function(value)
            label().enabled = value
        end, true)
    page:add_row_break()
    _add_text_field(page, key .. "_text", TR["Text"],
        function()
            return label().text
        end,
        function(value)
            label().text = value
        end,
        page.vital_format_help, true)
    page:add_row_break()
    _add_dropdown_field(page, key .. "_link_to", TR["Section"], page.vitals_label_link_labels,
        page.vitals_label_link_values,
        function()
            return label().link_to
        end,
        function(value)
            label().link_to = value
        end, nil, true)
    page:add_row_break()
    _add_dropdown_field(page, key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values,
        function()
            return label().anchor
        end,
        function(value)
            label().anchor = value
        end)
    _add_dropdown_field(page, key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values,
        function()
            return label().width_mode
        end,
        function(value)
            label().width_mode = value
        end)
    _add_dropdown_field(page, key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values,
        function()
            return label().text_alignment
        end,
        function(value)
            label().text_alignment = value
        end)
    page:add_row_break()
    _add_number_field(page, key .. "_x_offset", TR["X offset"],
        function()
            return label().x_offset
        end,
        function(value)
            label().x_offset = value
        end)
    _add_number_field(page, key .. "_y_offset", TR["Y offset"],
        function()
            return label().y_offset
        end,
        function(value)
            label().y_offset = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, key,
        function()
            return label().font
        end,
        TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _build_info_form(page, prefix, get)
    _add_checkbox_field(page, prefix .. "_info_enabled", TR["Enabled"],
        function()
            return get().info.enabled
        end,
        function(value)
            get().info.enabled = value
        end, true)
    page:add_row_break()
    _add_number_field(page, prefix .. "_info_height", TR["Height"],
        function()
            return get().info.height
        end,
        function(value)
            get().info.height = value
        end)
end

local function _add_targets_target_label_controls(page, label_index, label)
    local key = "target_targets_target_label" .. tostring(label_index)

    _add_checkbox_field(page, key .. "_enabled", TR["Enabled"],
        function()
            return label().enabled
        end,
        function(value)
            label().enabled = value
        end, true)
    page:add_row_break()
    _add_text_field(page, key .. "_text", TR["Text"],
        function()
            return label().text
        end,
        function(value)
            label().text = value
        end,
        page.vital_format_help, true)
    page:add_row_break()
    _add_dropdown_field(page, key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values,
        function()
            return label().anchor
        end,
        function(value)
            label().anchor = value
        end)
    _add_dropdown_field(page, key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values,
        function()
            return label().width_mode
        end,
        function(value)
            label().width_mode = value
        end)
    _add_dropdown_field(page, key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values,
        function()
            return label().text_alignment
        end,
        function(value)
            label().text_alignment = value
        end)
    page:add_row_break()
    _add_number_field(page, key .. "_x_offset", TR["X offset"],
        function()
            return label().x_offset
        end,
        function(value)
            label().x_offset = value
        end)
    _add_number_field(page, key .. "_y_offset", TR["Y offset"],
        function()
            return label().y_offset
        end,
        function(value)
            label().y_offset = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, key,
        function()
            return label().font
        end,
        TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _build_standard_frame_colors_form(page, prefix, get)
    _add_color_field(page, prefix .. "_morale_background_color", TR["Background Color"],
        function()
            return get().morale.color.background
        end,
        function(color)
            _set_color(get().morale.color.background, color)
        end)
    page:add_row_break()
    _add_checkbox_field(page, prefix .. "_ressource_background_matches_missing", TR["Matching background"],
        function()
            return get().background_matches_missing
        end,
        function(value)
            get().background_matches_missing = value
        end)
    _add_number_field(page, prefix .. "_ressource_background_dimming", TR["Dimming"],
        function()
            return get().background_dimming
        end,
        function(value)
            get().background_dimming = value
        end)
    page:add_row_break()
    _add_number_field(page, prefix .. "_background_opacity", TR["Background opacity"],
        function()
            return get().background_opacity
        end,
        function(value)
            get().background_opacity = value
        end)
    page:add_row_break()
    _add_color_field(page, prefix .. "_border_color", TR["Border Color"],
        function()
            return get().frame.border_color
        end,
        function(color)
            _set_color(get().frame.border_color, color)
        end)
    page:add_row_break()
    _add_color_field(page, prefix .. "_info_background_color", TR["Info Background Color"],
        function()
            return get().info.color.background
        end,
        function(color)
            _set_color(get().info.color.background, color)
        end)
    _add_number_field(page, prefix .. "_info_opacity", TR["Info opacity"],
        function()
            return get().info.opacity
        end,
        function(value)
            get().info.opacity = value
        end)
end

local function _build_standard_morale_form(page, prefix, get)
    _add_number_field(page, prefix .. "_morale_height", TR["Bar Height"],
        function()
            return get().morale.height
        end,
        function(value)
            get().morale.height = value
        end)
    page:add_row_break()
    _add_text_field(page, prefix .. "_morale_bubble_text", TR["Bubble Format (%B)"],
        function()
            return get().morale.bubble_format
        end,
        function(value)
            get().morale.bubble_format = value
        end,
        page.bubble_format_help, true)
end

local function _build_standard_morale_colors_form(page, prefix, get)
    _add_color_field(page, prefix .. "_morale_bubble_color", TR["Bubble Color"],
        function()
            return get().morale.color.bubble
        end,
        function(color)
            _set_color(get().morale.color.bubble, color)
        end)
    _add_color_field(page, prefix .. "_morale_color_neutral", TR["Neutral Color"],
        function()
            return get().morale.color.neutral
        end,
        function(color)
            _set_color(get().morale.color.neutral, color)
        end)
    page:add_row_break()
    page:add_title(TR["Step Colors"])
    _add_color_field(page, prefix .. "_morale_color_high", TR["High Color"],
        function()
            return get().morale.color.high
        end,
        function(color)
            _set_color(get().morale.color.high, color)
        end)
    _add_color_field(page, prefix .. "_morale_color_medium", TR["Medium Color"],
        function()
            return get().morale.color.medium
        end,
        function(color)
            _set_color(get().morale.color.medium, color)
        end)
    _add_color_field(page, prefix .. "_morale_color_low", TR["Low Color"],
        function()
            return get().morale.color.low
        end,
        function(color)
            _set_color(get().morale.color.low, color)
        end)
    page:add_row_break()
    _add_color_field(page, prefix .. "_morale_color_critical", TR["Critical Color"],
        function()
            return get().morale.color.critical
        end,
        function(color)
            _set_color(get().morale.color.critical, color)
        end)
    page:add_break()
    page:add_title(TR["Gradient Colors"])
    _add_checkbox_field(page, prefix .. "_morale_gradient", TR["Enable gradient colors"],
        function()
            return get().morale.color.gradient
        end,
        function(value)
            get().morale.color.gradient = value
        end, true)
    page:add_row_break()
    _add_color_field(page, prefix .. "_morale_gradient_full", TR["Full Color"],
        function()
            return get().morale.color.gradient_full
        end,
        function(color)
            _set_color(get().morale.color.gradient_full, color)
        end)
    _add_color_field(page, prefix .. "_morale_gradient_mid", TR["Mid Color"],
        function()
            return get().morale.color.gradient_mid
        end,
        function(color)
            _set_color(get().morale.color.gradient_mid, color)
        end)
    _add_color_field(page, prefix .. "_morale_gradient_low", TR["Low Color"],
        function()
            return get().morale.color.gradient_low
        end,
        function(color)
            _set_color(get().morale.color.gradient_low, color)
        end)
    page:add_row_break()
    page:add_custom(prefix .. "_morale_gradient_preview", 30)
end

local function _build_standard_power_form(page, prefix, get, include_boss_fields)
    if include_boss_fields == true then
        _add_checkbox_field(page, prefix .. "_power_hide", TR["Hide power / wrath"],
            function()
                return get().power.hide
            end,
            function(value)
                get().power.hide = value
            end, true)
        page:add_row_break()
        _add_number_field(page, prefix .. "_power_width", TR["Width"],
            function()
                return get().power.width
            end,
            function(value)
                get().power.width = value
            end)
        _add_number_field(page, prefix .. "_power_height", TR["Bar Height"],
            function()
                return get().power.height
            end,
            function(value)
                get().power.height = value
            end)
        page:add_row_break()
        _add_dropdown_field(page, prefix .. "_power_side", TR["Side"], page.side_labels, page.side_values,
            function()
                return get().power.side
            end,
            function(value)
                get().power.side = value
            end)
        page:add_row_break()
    else
        _add_number_field(page, prefix .. "_power_height", TR["Bar Height"],
            function()
                return get().power.height
            end,
            function(value)
                get().power.height = value
            end)
    end
end

local function _build_standard_power_colors_form(page, prefix, get)
    _add_color_field(page, prefix .. "_power_color", TR["Power Color"],
        function()
            return get().power.color.power
        end,
        function(color)
            _set_color(get().power.color.power, color)
        end)
    _add_color_field(page, prefix .. "_wrath_color", TR["Wrath Color"],
        function()
            return get().power.color.wrath
        end,
        function(color)
            _set_color(get().power.color.wrath, color)
        end)
end

local function _build_buffs_form(page, prefix, get)
    _add_dropdown_field(page, prefix .. "_buff_slot", TR["Buffs Slot"], page.vitals_effect_slot_labels,
        page.vitals_effect_slot_values,
        function()
            return get().effects.buffs.slot
        end,
        function(value)
            get().effects.buffs.slot = value
        end)
    _add_dropdown_field(page, prefix .. "_buff_alignment", TR["Alignment"], page.side_labels, page.side_values,
        function()
            return get().effects.buffs.alignment
        end,
        function(value)
            get().effects.buffs.alignment = value
        end)
    page:add_row_break()
    _add_number_field(page, prefix .. "_buff_size", TR["Icon Size"],
        function()
            return get().effects.buffs.icon_size
        end,
        function(value)
            get().effects.buffs.icon_size = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, prefix .. "_buff_timer",
        function()
            return get().effects.buffs.timer_font
        end,
        TR["Timer Font"], TR["Timer Font Size"], TR["Timer Font Style"])
end

local function _build_debuffs_form(page, prefix, get)
    _add_dropdown_field(page, prefix .. "_debuff_slot", TR["Debuffs Slot"], page.vitals_effect_slot_labels,
        page.vitals_effect_slot_values,
        function()
            return get().effects.debuffs.slot
        end,
        function(value)
            get().effects.debuffs.slot = value
        end)
    _add_dropdown_field(page, prefix .. "_debuff_alignment", TR["Alignment"], page.side_labels, page.side_values,
        function()
            return get().effects.debuffs.alignment
        end,
        function(value)
            get().effects.debuffs.alignment = value
        end)
    page:add_row_break()
    _add_checkbox_field(page, prefix .. "_debuff_track_curable", TR["Track curable debuffs"],
        function()
            return get().effects.debuffs.track_curable
        end,
        function(value)
            get().effects.debuffs.track_curable = value
        end, false)
    _add_checkbox_field(page, prefix .. "_debuff_track_noncurable", TR["Track non-curable debuffs"],
        function()
            return get().effects.debuffs.track_noncurable
        end,
        function(value)
            get().effects.debuffs.track_noncurable = value
        end, false)
    page:add_row_break()
    _add_number_field(page, prefix .. "_debuff_size", TR["Icon Size"],
        function()
            return get().effects.debuffs.icon_size
        end,
        function(value)
            get().effects.debuffs.icon_size = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, prefix .. "_debuff_timer",
        function()
            return get().effects.debuffs.timer_font
        end,
        TR["Timer Font"], TR["Timer Font Size"], TR["Timer Font Style"])
end

local function _build_standard_text_colors_form(page, prefix, get)
    page:add_title(TR["Text 1"])
    _add_font_color_controls(page, prefix .. "_label1",
        function()
            return get().labels[1].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 2"])
    _add_font_color_controls(page, prefix .. "_label2",
        function()
            return get().labels[2].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 3"])
    _add_font_color_controls(page, prefix .. "_label3",
        function()
            return get().labels[3].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 4"])
    _add_font_color_controls(page, prefix .. "_label4",
        function()
            return get().labels[4].font
        end,
        TR["Font Color"], TR["Outline Color"])
end

local function _build_targets_target_text_colors_form(page, get)
    page:add_title(TR["Text 1"])
    _add_font_color_controls(page, "target_targets_target_label1",
        function()
            return get().labels[1].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 2"])
    _add_font_color_controls(page, "target_targets_target_label2",
        function()
            return get().labels[2].font
        end,
        TR["Font Color"], TR["Outline Color"])
end

local function _build_effects_colors_form(page, prefix, get)
    page:add_title(TR["Buffs"])
    _add_font_color_controls(page, prefix .. "_buff_timer",
        function()
            return get().effects.buffs.timer_font
        end,
        TR["Timer Font Color"], TR["Timer Outline Color"])
    page:add_break()
    page:add_title(TR["Debuffs"])
    _add_font_color_controls(page, prefix .. "_debuff_timer",
        function()
            return get().effects.debuffs.timer_font
        end,
        TR["Timer Font Color"], TR["Timer Outline Color"])
end

local function _new_standard_colors_section(window, refresh_preview_fn, prefix, get, include_effects)
    local frame = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_frame_colors_form(frame, prefix, get)

    local morale = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_morale_colors_form(morale, prefix, get)

    local power = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_power_colors_form(power, prefix, get)

    local text = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_text_colors_form(text, prefix, get)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page._frame_page = frame
    page._morale_page = morale
    page._power_page = power
    page._text_page = text
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Morale"], "morale", morale)
    page:add_tab(TR["Power / Wrath"], "power", power)
    page:add_tab(TR["Text"], "text", text)

    if include_effects == true then
        local effects = ConfigContent(window, 3, refresh_preview_fn)
        _build_effects_colors_form(effects, prefix, get)
        page._effects_page = effects
        page:add_tab(TR["Effects"], "effects", effects)
    end

    return page
end

local function _new_targets_target_colors_section(window, refresh_preview_fn, get)
    local frame = ConfigContent(window, 3, refresh_preview_fn)
    _add_color_field(frame, "target_targets_target_background_color", TR["Background Color"],
        function()
            return get().color.background
        end,
        function(color)
            _set_color(get().color.background, color)
        end)
    frame:add_row_break()
    _add_checkbox_field(frame, "target_targets_target_background_matches_missing", TR["Matching background"],
        function()
            return get().background_matches_missing
        end,
        function(value)
            get().background_matches_missing = value
        end)
    _add_number_field(frame, "target_targets_target_background_dimming", TR["Dimming"],
        function()
            return get().background_dimming
        end,
        function(value)
            get().background_dimming = value
        end)
    frame:add_row_break()
    _add_number_field(frame, "target_targets_target_background_opacity", TR["Background opacity"],
        function()
            return get().background_opacity
        end,
        function(value)
            get().background_opacity = value
        end)
    frame:add_row_break()
    _add_color_field(frame, "target_targets_target_border_color", TR["Border Color"],
        function()
            return get().color.border
        end,
        function(color)
            _set_color(get().color.border, color)
        end)

    local morale = ConfigContent(window, 3, refresh_preview_fn)
    _add_color_field(morale, "target_targets_target_bubble_color", TR["Bubble Color"],
        function()
            return get().color.bubble
        end,
        function(color)
            _set_color(get().color.bubble, color)
        end)
    _add_color_field(morale, "target_targets_target_color_neutral", TR["Neutral Color"],
        function()
            return get().color.neutral
        end,
        function(color)
            _set_color(get().color.neutral, color)
        end)
    morale:add_row_break()
    morale:add_break()
    morale:add_title(TR["Step Colors"])
    _add_color_field(morale, "target_targets_target_color_high", TR["High Color"],
        function()
            return get().color.high
        end,
        function(color)
            _set_color(get().color.high, color)
        end)
    _add_color_field(morale, "target_targets_target_color_medium", TR["Medium Color"],
        function()
            return get().color.medium
        end,
        function(color)
            _set_color(get().color.medium, color)
        end)
    _add_color_field(morale, "target_targets_target_color_low", TR["Low Color"],
        function()
            return get().color.low
        end,
        function(color)
            _set_color(get().color.low, color)
        end)
    morale:add_row_break()
    _add_color_field(morale, "target_targets_target_color_critical", TR["Critical Color"],
        function()
            return get().color.critical
        end,
        function(color)
            _set_color(get().color.critical, color)
        end)
    morale:add_break()
    morale:add_title(TR["Gradient Colors"])
    _add_checkbox_field(morale, "target_targets_target_color_gradient", TR["Enable gradient colors"],
        function()
            return get().color.gradient
        end,
        function(value)
            get().color.gradient = value
        end, true)
    morale:add_row_break()
    _add_color_field(morale, "target_targets_target_color_gradient_full", TR["Full Color"],
        function()
            return get().color.gradient_full
        end,
        function(color)
            _set_color(get().color.gradient_full, color)
        end)
    _add_color_field(morale, "target_targets_target_color_gradient_mid", TR["Mid Color"],
        function()
            return get().color.gradient_mid
        end,
        function(color)
            _set_color(get().color.gradient_mid, color)
        end)
    _add_color_field(morale, "target_targets_target_color_gradient_low", TR["Low Color"],
        function()
            return get().color.gradient_low
        end,
        function(color)
            _set_color(get().color.gradient_low, color)
        end)
    morale:add_row_break()
    morale:add_custom("target_targets_target_color_gradient_preview", 30)

    local text = ConfigContent(window, 3, refresh_preview_fn)
    _build_targets_target_text_colors_form(text, get)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page._frame_page = frame
    page._morale_page = morale
    page._text_page = text
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Morale"], "morale", morale)
    page:add_tab(TR["Text"], "text", text)
    return page
end

local function _bind_standard_outline_visibility(owner_page, colors_page, prefix, include_effects)
    for i = 1, 4 do
        _bind_outline_visibility(owner_page, colors_page, colors_page._text_page,
            prefix .. "_label" .. tostring(i) .. "_font_style",
            prefix .. "_label" .. tostring(i) .. "_font_outline_color")
    end

    if include_effects == true then
        _bind_outline_visibility(owner_page, colors_page, colors_page._effects_page, prefix .. "_buff_timer_font_style",
            prefix .. "_buff_timer_font_outline_color")
        _bind_outline_visibility(owner_page, colors_page, colors_page._effects_page,
            prefix .. "_debuff_timer_font_style", prefix .. "_debuff_timer_font_outline_color")
    end
end

local function _bind_targets_target_outline_visibility(owner_page, colors_page)
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, "target_targets_target_label1_font_style",
        "target_targets_target_label1_font_outline_color")
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, "target_targets_target_label2_font_style",
        "target_targets_target_label2_font_outline_color")
end

local function _new_label_page(window, refresh_preview_fn, columns, prefix, label_index, label)
    local page = ConfigContent(window, columns, refresh_preview_fn)
    _add_vitals_label_controls(page, prefix, label_index, label)
    return page
end

local function _new_targets_target_label_page(window, refresh_preview_fn, columns, label_index, label)
    local page = ConfigContent(window, columns, refresh_preview_fn)
    _add_targets_target_label_controls(page, label_index, label)
    return page
end

local function _new_texts_section(window, refresh_preview_fn, prefix, get)
    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Text 1"], "label1",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 1, function()
            return get().labels[1]
        end))
    page:add_tab(TR["Text 2"], "label2",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 2, function()
            return get().labels[2]
        end))
    page:add_tab(TR["Text 3"], "label3",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 3, function()
            return get().labels[3]
        end))
    page:add_tab(TR["Text 4"], "label4",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 4, function()
            return get().labels[4]
        end))
    return page
end

local function _new_targets_target_texts_section(window, refresh_preview_fn, get)
    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Text 1"], "label1",
        _new_targets_target_label_page(window, refresh_preview_fn, 3, 1, function()
            return get().labels[1]
        end))
    page:add_tab(TR["Text 2"], "label2",
        _new_targets_target_label_page(window, refresh_preview_fn, 3, 2, function()
            return get().labels[2]
        end))
    return page
end

local function _new_effects_section(window, refresh_preview_fn, prefix, get)
    local buffs = ConfigContent(window, 3, refresh_preview_fn)
    _build_buffs_form(buffs, prefix, get)

    local debuffs = ConfigContent(window, 3, refresh_preview_fn)
    _build_debuffs_form(debuffs, prefix, get)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Buffs"], "buffs", buffs)
    page:add_tab(TR["Debuffs"], "debuffs", debuffs)
    return page
end

local BOSS_TARGETS_COLUMN_SPAN = 2

local function _new_boss_targets_section(window, refresh_preview_fn, get)
    local page = ConfigContent(window, 4, refresh_preview_fn)
    page:add_info(
        TR["Enter one boss name per line. When your target's name matches a line exactly, the Boss Vitals frame is shown."],
        48)
    page:add_text_area("target_boss_custom_targets", TR["Custom Bosses"],
        function(value)
            get().custom_targets = value
        end,
        function()
            return get().custom_targets
        end,
        nil, BOSS_TARGETS_COLUMN_SPAN)

    return page
end

local VitalsPage = class(ConfigTabs)
Pages.VitalsPage = VitalsPage

function VitalsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(_scaled_int(SECTION_FRAME_PADDING))

    self:add_tab(TR["General"], "general", StandardVitalsPageBuilder.new_general_page(window, self, {
        ConfigContent = ConfigContent,
    }))
    self:add_tab(TR["Self"], "self", StandardVitalsPageBuilder.new_standard_unit_page(window, self, {
        get_settings = function(root)
            return root._settings.self.vitals
        end,
        defaults = function()
            return Defaults.Schema.self.vitals
        end,
        prefix = "self",
        preview_key = "self_vitals_preview",
        preview_method = "update_self_vitals_preview",
        preview_height = 207,
        show_outline_settings = true,
        boss_power_mode = false,
    }, {
        ConfigContent = ConfigContent,
        ConfigSectionPage = ConfigSectionPage,
        add_number_field = _add_number_field,
        add_checkbox_field = _add_checkbox_field,
        add_dropdown_field = _add_dropdown_field,
        new_standard_colors_section = _new_standard_colors_section,
        build_standard_morale_form = _build_standard_morale_form,
        build_standard_power_form = _build_standard_power_form,
        build_info_form = _build_info_form,
        new_texts_section = _new_texts_section,
        new_effects_section = _new_effects_section,
        bind_standard_outline_visibility = _bind_standard_outline_visibility,
    }))
    self:add_tab(TR["Target"], "target", StandardVitalsPageBuilder.new_standard_unit_page(window, self, {
        get_settings = function(root)
            return root._settings.target.vitals
        end,
        defaults = function()
            return Defaults.Schema.target.vitals
        end,
        prefix = "target",
        preview_key = "target_vitals_preview",
        preview_method = "update_target_vitals_preview",
        preview_height = 222,
        show_outline_settings = true,
        boss_power_mode = false,
    }, {
        ConfigContent = ConfigContent,
        ConfigSectionPage = ConfigSectionPage,
        add_number_field = _add_number_field,
        add_checkbox_field = _add_checkbox_field,
        new_standard_colors_section = _new_standard_colors_section,
        build_standard_morale_form = _build_standard_morale_form,
        build_standard_power_form = _build_standard_power_form,
        build_info_form = _build_info_form,
        new_texts_section = _new_texts_section,
        new_effects_section = _new_effects_section,
        bind_standard_outline_visibility = _bind_standard_outline_visibility,
    }))
    self:add_tab(TR["Companion"], "companion", StandardVitalsPageBuilder.new_standard_unit_page(window, self, {
        get_settings = function(root)
            return root._settings.companion
        end,
        defaults = function()
            return Defaults.Schema.companion
        end,
        prefix = "companion",
        preview_key = "companion_vitals_preview",
        preview_method = "update_companion_vitals_preview",
        preview_height = 222,
        show_outline_settings = true,
        boss_power_mode = false,
    }, {
        ConfigContent = ConfigContent,
        ConfigSectionPage = ConfigSectionPage,
        add_number_field = _add_number_field,
        add_checkbox_field = _add_checkbox_field,
        new_standard_colors_section = _new_standard_colors_section,
        build_standard_morale_form = _build_standard_morale_form,
        build_standard_power_form = _build_standard_power_form,
        build_info_form = _build_info_form,
        new_texts_section = _new_texts_section,
        new_effects_section = _new_effects_section,
        bind_standard_outline_visibility = _bind_standard_outline_visibility,
    }))
    self:add_tab(TR["Boss"], "boss", StandardVitalsPageBuilder.new_standard_unit_page(window, self, {
        get_settings = function(root)
            return root._settings.target.boss_vitals
        end,
        defaults = function()
            return Defaults.Schema.target.boss_vitals
        end,
        prefix = "target_boss",
        preview_key = "target_boss_vitals_preview",
        preview_method = "update_target_boss_vitals_preview",
        preview_height = 178,
        show_outline_settings = true,
        boss_power_mode = true,
        boss_targets = true,
    }, {
        ConfigContent = ConfigContent,
        ConfigSectionPage = ConfigSectionPage,
        add_number_field = _add_number_field,
        add_checkbox_field = _add_checkbox_field,
        new_standard_colors_section = _new_standard_colors_section,
        build_standard_morale_form = _build_standard_morale_form,
        build_standard_power_form = _build_standard_power_form,
        build_info_form = _build_info_form,
        new_texts_section = _new_texts_section,
        new_effects_section = _new_effects_section,
        bind_standard_outline_visibility = _bind_standard_outline_visibility,
        new_boss_targets_section = _new_boss_targets_section,
    }))
    self:add_tab(TR["Target's Target"], "target_targets_target",
        StandardVitalsPageBuilder.new_targets_target_unit_page(window, self, {
            ConfigContent = ConfigContent,
            ConfigSectionPage = ConfigSectionPage,
            add_number_field = _add_number_field,
            add_checkbox_field = _add_checkbox_field,
            add_text_field = _add_text_field,
            new_targets_target_colors_section = _new_targets_target_colors_section,
            new_targets_target_texts_section = _new_targets_target_texts_section,
            bind_targets_target_outline_visibility = _bind_targets_target_outline_visibility,
        }))
    self:add_tab(TR["Fellowship"], "fellowship", GroupVitalsPageBuilder.new_group_unit_page(window, self, {
        settings_root = "fellowship",
        prefix = "fellowship",
        preview_key = "fellowship_vitals_preview",
        preview_method = "update_fellowship_vitals_preview",
        include_self_toggle = true,
    }, {
        ConfigContent = ConfigContent,
        ConfigSectionPage = ConfigSectionPage,
        add_number_field = _add_number_field,
        add_checkbox_field = _add_checkbox_field,
        add_color_field = _add_color_field,
        new_standard_colors_section = _new_standard_colors_section,
        build_standard_morale_form = _build_standard_morale_form,
        build_standard_power_form = _build_standard_power_form,
        build_info_form = _build_info_form,
        new_texts_section = _new_texts_section,
        bind_standard_outline_visibility = _bind_standard_outline_visibility,
    }))
    self:add_tab(TR["Raid"], "raid", GroupVitalsPageBuilder.new_group_unit_page(window, self, {
        settings_root = "raid",
        prefix = "raid",
        preview_key = "raid_vitals_preview",
        preview_method = "update_raid_vitals_preview",
        include_self_toggle = false,
        raid_layout_dropdown = true,
        raid_group_colors = true,
    }, {
        ConfigContent = ConfigContent,
        ConfigSectionPage = ConfigSectionPage,
        add_number_field = _add_number_field,
        add_checkbox_field = _add_checkbox_field,
        add_dropdown_field = _add_dropdown_field,
        add_color_field = _add_color_field,
        new_standard_colors_section = _new_standard_colors_section,
        build_standard_morale_form = _build_standard_morale_form,
        build_standard_power_form = _build_standard_power_form,
        build_info_form = _build_info_form,
        new_texts_section = _new_texts_section,
        bind_standard_outline_visibility = _bind_standard_outline_visibility,
    }))
end

function VitalsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(_scaled_int(SECTION_FRAME_PADDING))
end
