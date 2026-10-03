-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local LUI_ENUMS = _G.LUI.Settings.Enums
local Pages = _G.LUI.Settings.Pages

local Builder = Pages.GroupVitalsPageBuilder or {}
Pages.GroupVitalsPageBuilder = Builder
local RAID_LAYOUT_LABELS = {
    "2",
    "3",
    "4 (Mode 1)",
    "4 (Mode 2)",
    "6 (Mode 1)",
    "6 (Mode 2)",
}
local RAID_LAYOUT_VALUES = {
    LUI_ENUMS.raid_layout_mode.TWO_COLUMNS,
    LUI_ENUMS.raid_layout_mode.THREE_COLUMNS,
    LUI_ENUMS.raid_layout_mode.FOUR_COLUMNS_MODE_1,
    LUI_ENUMS.raid_layout_mode.FOUR_COLUMNS_MODE_2,
    LUI_ENUMS.raid_layout_mode.SIX_COLUMNS_MODE_1,
    LUI_ENUMS.raid_layout_mode.SIX_COLUMNS_MODE_2,
}
local RAID_GROUP_COLOR_KEYS = { "a", "b", "c", "d" }
local RAID_GROUP_COLOR_LABELS = {
    TR["Group A Border"],
    TR["Group B Border"],
    TR["Group C Border"],
    TR["Group D Border"],
}

function Builder.new_group_unit_page(window, root, options, deps)
    local get = function()
        return root._settings[options.settings_root]
    end

    local refresh_preview = function(win)
        win[options.preview_method](win)
    end

    local page = deps.ConfigSectionPage(window, options.preview_key, 178, refresh_preview)

    local frame = deps.ConfigContent(window, 4, page.refresh_preview)
    frame.on_scroll_changed = function()
        window[options.preview_method](window)
    end
    local border_width_label = TR["Border Width"]
    if options.raid_layout_dropdown == true then
        border_width_label = TR["In-between Border Width"]
    end
    deps.add_number_field(frame, options.prefix .. "_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    deps.add_number_field(frame, options.prefix .. "_border_width", border_width_label,
        function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    if options.raid_layout_dropdown == true then
        deps.add_number_field(frame, options.prefix .. "_group_border_width", TR["Group Border Width"],
            function() return get().group_border_width end,
            function(value) get().group_border_width = value end)
    end
    frame:add_row_break()
    if options.raid_layout_dropdown == true then
        deps.add_dropdown_field(frame, options.prefix .. "_layout_mode", TR["Columns"], RAID_LAYOUT_LABELS,
            RAID_LAYOUT_VALUES,
            function() return get().layout.mode end,
            function(value) get().layout.mode = value end)
    else
        deps.add_number_field(frame, options.prefix .. "_rows", TR["Rows per Column"],
            function() return get().layout.rows end,
            function(value) get().layout.rows = value end)
    end
    deps.add_number_field(frame, options.prefix .. "_spacing_x", TR["Column Spacing"],
        function() return get().layout.spacing_x end,
        function(value) get().layout.spacing_x = value end)
    deps.add_number_field(frame, options.prefix .. "_spacing_y", TR["Row Spacing"],
        function() return get().layout.spacing_y end,
        function(value) get().layout.spacing_y = value end)
    if options.raid_layout_dropdown == true then
        frame:add_row_break()
        deps.add_checkbox_field(frame, options.prefix .. "_split_by_group", TR["Split by groups"],
            function() return get().split_by_group end,
            function(value) get().split_by_group = value end, true)
    elseif options.include_self_toggle == true then
        frame:add_row_break()
        deps.add_checkbox_field(frame, options.prefix .. "_show_self_in_fellowship", TR["Show self in fellowship"],
            function() return get().show_self_in_fellowship end,
            function(value) get().show_self_in_fellowship = value end, true)
    end
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_incombat_opacity", TR["In-combat opacity"],
        function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    deps.add_number_field(frame, options.prefix .. "_outcombat_opacity", TR["Out-of-combat opacity"],
        function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    frame:add_row_break()
    deps.add_checkbox_field(frame, options.prefix .. "_select_enabled", TR["Select"],
        function() return get().select.enabled end,
        function(value) get().select.enabled = value end)
    deps.add_number_field(frame, options.prefix .. "_select_border_width", TR["Select Border Width"],
        function() return get().select.border_width end,
        function(value) get().select.border_width = value end)
    frame:add_row_break()
    deps.add_checkbox_field(frame, options.prefix .. "_select_glow", TR["Glow around selected"],
        function() return get().select.glow ~= false end,
        function(value) get().select.glow = value == true end)
    deps.add_checkbox_field(frame, options.prefix .. "_select_hover", TR["Highlight on mouse over"],
        function() return get().select.hover ~= false end,
        function(value) get().select.hover = value == true end)
    frame:add_row_break()
    deps.add_checkbox_field(frame, options.prefix .. "_low_health", TR["Low morale warning"],
        function() return get().select.low_health ~= false end,
        function(value) get().select.low_health = value == true end)
    deps.add_number_field(frame, options.prefix .. "_low_health_pct", TR["Low morale %"],
        function() return get().select.low_health_pct or 35 end,
        function(value)
            local pct = tonumber(value)
            if pct ~= nil then
                if pct < 1 then pct = 1 end
                if pct > 99 then pct = 99 end
                get().select.low_health_pct = pct
            end
        end)
    frame:add_row_break()
    deps.add_checkbox_field(frame, options.prefix .. "_background_effect_tracking",
        TR["Background effect tracking"],
        function() return get().background_effect_tracking end,
        function(value) get().background_effect_tracking = value end, true)
    frame:add_info(
        TR["When background effect tracking is enabled, it may add some lag. Whether enabled or not, targeting a group member may not display the correct effects until one of their effects changes."],
        48)
    if options.raid_layout_dropdown == true then
        local general = deps.ConfigContent(window, 4, page.refresh_preview)
        deps.add_checkbox_field(general, options.prefix .. "_share_listen", TR["Apply shared layouts from chat"],
            function() return get().share.listen end,
            function(value) get().share.listen = value end, true)
        general:add_row_break()
        deps.add_checkbox_field(general, options.prefix .. "_share_leader_only", TR["Leader layouts only"],
            function() return get().share.leader_only end,
            function(value) get().share.leader_only = value end, true)
        general:add_row_break()
        general:add_button(options.prefix .. "_open_raid_groups", TR["Open Raid Manager"],
            function()
                _G.LUI.UI.Shortcuts.toggle_raid_groups()
            end,
            TR["Arrange raid members and share the layout with other LUI users. Also available as /lui raid."])
        page:add_tab(TR["General"], "general", general)
    end
    page:add_tab(TR["Frame"], "frame", frame)

    local colors = deps.new_standard_colors_section(window, page.refresh_preview, options.prefix, get, false)
    local colors_frame = colors._frame_page
    if options.raid_group_colors == true then
        colors_frame:add_break()
        for i = 1, #RAID_GROUP_COLOR_KEYS do
            local group_key = RAID_GROUP_COLOR_KEYS[i]
            local control_key = options.prefix .. "_group_" .. group_key .. "_border_color"
            deps.add_color_field(colors_frame, control_key,
                TR[RAID_GROUP_COLOR_LABELS[i]],
                function() return get().group_colors[group_key] end,
                function(value) get().group_colors[group_key] = value end)
            colors.controls[control_key] = colors_frame.controls[control_key]
            page.controls[control_key] = colors_frame.controls[control_key]
            window.controls[control_key] = colors_frame.controls[control_key]
        end
    end
    colors_frame:add_break()
    local select_color_key = options.prefix .. "_select_border_color"
    deps.add_color_field(colors_frame, select_color_key, TR["Select Border Color"],
        function() return get().select.border_color end,
        function(value) get().select.border_color = value end)
    colors.controls[select_color_key] = colors_frame.controls[select_color_key]
    page.controls[select_color_key] = colors_frame.controls[select_color_key]
    window.controls[select_color_key] = colors_frame.controls[select_color_key]
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_morale_form(morale, options.prefix, get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_power_form(power, options.prefix, get, false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_info_form(info, options.prefix, get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", deps.new_texts_section(window, page.refresh_preview, options.prefix, get))

    local icons = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.add_checkbox_field(icons, options.prefix .. "_class_icon_enabled", TR["Show class icon"],
        function() return get().class_icon.enabled end,
        function(value) get().class_icon.enabled = value end, true)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_class_icon_size", TR["Icon Size"],
        function() return get().class_icon.size end,
        function(value) get().class_icon.size = value end)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_class_icon_x", TR["Icon X"], function() return get().class_icon.x end,
        function(value) get().class_icon.x = value end)
    deps.add_number_field(icons, options.prefix .. "_class_icon_y", TR["Icon Y"], function() return get().class_icon.y end,
        function(value) get().class_icon.y = value end)
    icons:add_row_break()
    deps.add_checkbox_field(icons, options.prefix .. "_leader_icon_enabled", TR["Show leader icon"],
        function() return get().leader_icon.enabled end,
        function(value) get().leader_icon.enabled = value end, true)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_leader_icon_size", TR["Leader Icon Size"],
        function() return get().leader_icon.size end,
        function(value) get().leader_icon.size = value end)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_leader_icon_x", TR["Leader Icon X"],
        function() return get().leader_icon.x end,
        function(value) get().leader_icon.x = value end)
    deps.add_number_field(icons, options.prefix .. "_leader_icon_y", TR["Leader Icon Y"],
        function() return get().leader_icon.y end,
        function(value) get().leader_icon.y = value end)
    page:add_tab(TR["Icons"], "icons", icons)

    deps.bind_standard_outline_visibility(page, colors, options.prefix, false)

    return page
end
