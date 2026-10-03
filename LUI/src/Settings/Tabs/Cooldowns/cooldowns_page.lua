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

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _layout_text_area(entry)
    local width, height = entry.control:GetSize()
    local label_h = 20
    local gap = 4

    entry.label:SetPosition(0, 0)
    entry.label:SetSize(width, label_h)

    entry.tb:SetPosition(0, label_h + gap)
    entry.tb:SetSize(width, math.max(10, height - label_h - gap))
end

local function _create_text_area(page, key, label_text, help_text)
    local entry = page:add_custom(key, 89)

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(entry.control)
    entry.label:SetFont(page.window.field_label_font)
    entry.label:SetMultiline(false)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)

    entry.tb = UI.Widgets.LuiLineEdit()
    entry.tb:SetParent(entry.control)
    entry.tb:SetFont(page.window.input_font)
    entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    if entry.tb.SetMultiline ~= nil then
        entry.tb:SetMultiline(true)
    end

    page.window:bind_tooltip(entry.tb, help_text)

    entry.apply_ui_scale = function()
        entry.label:SetFont(page.window.field_label_font)
        entry.tb:SetFont(page.window.input_font)
        _layout_text_area(entry)
    end

    function entry:refresh_text()
        self.tb:SetText(self.tb:GetText())
    end

    function entry:get_value()
        return entry.tb:GetText()
    end

    function entry:set_value(value)
        entry.tb:SetText(value)
    end

    entry.control.SizeChanged = function()
        _layout_text_area(entry)
    end
    _layout_text_area(entry)

    return entry
end

local function _bind_outline_visibility(owner_page, colors_text_page, style_key, outline_key)
    owner_page.controls[outline_key].visible_if = function()
        return _is_outline(owner_page.controls[style_key])
    end

    local prev = owner_page.controls[style_key].on_changed
    owner_page.controls[style_key].on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        colors_text_page:layout()
        owner_page:layout()
    end
end

local function _new_colors_section(window, refresh_preview, settings_getter)
    local ui = window._ui

    local frame = ConfigContent(window, 4, refresh_preview)
    frame:add_color_picker("cd_bg_color", TR["Background color"],
        function(value)
            settings_getter().color.background = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().color.background)
        end)
    frame:add_row_break()
    frame:add_checkbox("cd_bar_background_matches_fill", TR["Matching background"],
        function(value)
            settings_getter().bar_background_matches_fill = value == true
        end,
        function()
            return settings_getter().bar_background_matches_fill == true
        end)
    frame:add_line_edit("cd_bar_background_dimming", TR["Dimming"],
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
    frame:add_line_edit("cd_background_opacity", TR["Background opacity"],
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
    frame:add_color_picker("cd_border_color", TR["Border color"],
        function(value)
            settings_getter().color.border = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().color.border)
        end)

    local bar = ConfigContent(window, 4, refresh_preview)
    bar:add_color_picker("cd_bar_color", TR["Bar color"],
        function(value)
            settings_getter().color.bar = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().color.bar)
        end)
    bar:add_line_edit("cd_bar_opacity", TR["Bar opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().bar_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().bar_opacity)
        end)
    local text = ConfigContent(window, 4, refresh_preview)
    text:add_color_picker("cd_font_color", TR["Font color"],
        function(value)
            settings_getter().font.color = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().font.color)
        end)
    text:add_color_picker("cd_font_outline_color", TR["Outline color"],
        function(value)
            settings_getter().font.outline_color = ui.hex_to_color(value)
        end,
        function()
            return ui.color_to_hex(settings_getter().font.outline_color)
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Bars"], "bars", bar)
    page:add_tab(TR["Text"], "text", text)

    return page, text
end

local CooldownsFeaturePage = class(ConfigTabs)
Pages.CooldownsFeaturePage = CooldownsFeaturePage

function CooldownsFeaturePage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self._preview_default_height = 52
    self.controls = self.controls or {}

    local flow_labels = { TR["Top to bottom"], TR["Bottom to top"] }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }
    local bar_mode_labels = { TR["Load"], TR["Unload"] }
    local bar_mode_values = { LUI_ENUMS.bar_mode.LOAD, LUI_ENUMS.bar_mode.UNLOAD }
    local orientation_labels = { TR["Horizontal"], TR["Vertical"] }
    local orientation_values = { LUI_ENUMS.orientation.HORIZONTAL, LUI_ENUMS.orientation.VERTICAL }
    local side_labels = { TR["Left/Top"], TR["Right/Bottom"] }
    local side_values = { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT }
    local time_format_labels = { TR["Auto precision"], TR["Whole seconds"] }
    local time_format_values = {
        LUI_ENUMS.cooldown_time_format.AUTO,
        LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS,
    }
    local group_display_labels = { TR["Fixed skill"], TR["Rotating skills"] }
    local group_display_values = {
        LUI_ENUMS.cooldown_group_display.STABLE,
        LUI_ENUMS.cooldown_group_display.ROTATE,
    }
    local group_display_help =
        TR["Skills sharing one cooldown are shown as a single entry. It can show one fixed skill or rotate through the affected skills."]
    local min_base_help = TR["Skills whose base cooldown is below this value are ignored."]
    local list_help = TR["One skill name per line or comma-separated. Case-insensitive. Exact match or prefix with trailing *."]
    local refresh_preview = function()
        window:update_cooldowns_preview()
    end
    local settings_getter = function()
        return self._settings.self.cooldowns
    end

    local general = ConfigContent(window, 4, refresh_preview)
    general:add_checkbox("cd_enabled", TR["Enabled"],
        function(value)
            settings_getter().enabled = value == true
        end,
        function()
            return settings_getter().enabled == true
        end, true)
    general:add_row_break()
    general:add_line_edit("cd_threshold", TR["Threshold (s)"],
        function(value)
            local threshold = tonumber(value)
            if threshold ~= nil then
                settings_getter().threshold = threshold
            end
        end,
        function()
            return tostring(settings_getter().threshold)
        end)
    general:add_line_edit("cd_min_base_cooldown", TR["Min base cooldown (s)"],
        function(value)
            local min_base_cooldown = tonumber(value)
            if min_base_cooldown ~= nil then
                settings_getter().min_base_cooldown = min_base_cooldown
            end
        end,
        function()
            return tostring(settings_getter().min_base_cooldown)
        end, min_base_help)
    general:add_row_break()
    general:add_dropdown("cd_group_display", TR["Shared cooldowns"],
        group_display_labels, group_display_values,
        function(value)
            settings_getter().group_display = value
        end,
        function()
            return settings_getter().group_display
        end, group_display_help)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4, refresh_preview)
    layout:add_dropdown("cd_orientation", TR["Orientation"], orientation_labels, orientation_values,
        function(value)
            settings_getter().orientation = value
        end,
        function()
            return settings_getter().orientation
        end)
    layout:add_row_break()
    layout:add_line_edit("cd_item_w", TR["Item length"],
        function(value)
            local item_w = tonumber(value)
            if item_w ~= nil then
                settings_getter().item_w = item_w
            end
        end,
        function()
            return tostring(settings_getter().item_w)
        end)
    layout:add_line_edit("cd_item_h", TR["Item thickness"],
        function(value)
            local item_h = tonumber(value)
            if item_h ~= nil then
                settings_getter().item_h = item_h
            end
        end,
        function()
            return tostring(settings_getter().item_h)
        end)
    layout:add_line_edit("cd_spacing", TR["Spacing (px)"],
        function(value)
            local spacing = tonumber(value)
            if spacing ~= nil then
                settings_getter().spacing = spacing
            end
        end,
        function()
            return tostring(settings_getter().spacing)
        end)
    layout:add_line_edit("cd_border_width", TR["Border width (px)"],
        function(value)
            local border_width = tonumber(value)
            if border_width ~= nil then
                settings_getter().border_width = border_width
            end
        end,
        function()
            return tostring(settings_getter().border_width)
        end)
    layout:add_line_edit("cd_columns", TR["Columns"],
        function(value)
            local columns = tonumber(value)
            if columns ~= nil then
                settings_getter().columns = columns
            end
        end,
        function()
            return tostring(settings_getter().columns)
        end)
    layout:add_line_edit("cd_rows", TR["Rows"],
        function(value)
            local rows = tonumber(value)
            if rows ~= nil then
                settings_getter().rows = rows
            end
        end,
        function()
            return tostring(settings_getter().rows)
        end)
    layout:add_row_break()
    layout:add_dropdown("cd_flow", TR["Order"], flow_labels, flow_values,
        function(value)
            settings_getter().flow = value
        end,
        function()
            return settings_getter().flow
        end)
    layout:add_dropdown("cd_icon_side", TR["Icon position"], side_labels, side_values,
        function(value)
            settings_getter().icon_side = value
        end,
        function()
            return settings_getter().icon_side
        end)
    layout:add_row_break()
    layout:add_dropdown("cd_bar_mode", TR["Bar mode"], bar_mode_labels, bar_mode_values,
        function(value)
            settings_getter().bar_mode = value
        end,
        function()
            return settings_getter().bar_mode
        end)
    layout:add_dropdown("cd_bar_expire_towards", TR["Bar movement towards"], side_labels, side_values,
        function(value)
            settings_getter().bar_expire_towards = value
        end,
        function()
            return settings_getter().bar_expire_towards
        end)
    self:add_tab(TR["Frame"], "frame", layout)

    local colors, colors_text = _new_colors_section(window, refresh_preview, settings_getter)
    self:add_tab(TR["Colors"], "colors", colors)

    local text = ConfigContent(window, 4, refresh_preview)
    text:add_checkbox("cd_show_time", TR["Display time"],
        function(value)
            settings_getter().show_time = value == true
        end,
        function()
            return settings_getter().show_time == true
        end)
    text:add_dropdown("cd_time_format", TR["Time format"], time_format_labels, time_format_values,
        function(value)
            settings_getter().time_format = value
        end,
        function()
            return settings_getter().time_format
        end)
    text:add_line_edit("cd_text_margin", TR["Text margin (px)"],
        function(value)
            local text_margin = tonumber(value)
            if text_margin ~= nil then
                settings_getter().text_margin = text_margin
            end
        end,
        function()
            return tostring(settings_getter().text_margin)
        end)
    text:add_line_edit("cd_name_max_chars", TR["Max name chars"],
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
    text:add_dropdown("cd_font_name", TR["Font"], text.font_name_labels, text.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function()
            return settings_getter().font.name
        end)
    text:add_line_edit("cd_font_size", TR["Font size"],
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function()
            return tostring(settings_getter().font.size)
        end)
    text:add_dropdown("cd_font_style", TR["Font style"], text.font_style_labels, text.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function()
            return settings_getter().font.style
        end)
    self:add_tab(TR["Text"], "text", text)

    local filters = ConfigContent(window, 1, refresh_preview)
    local whitelist = _create_text_area(filters, "cd_whitelist", TR["Whitelist"], list_help)
    filters:bind(whitelist,
        function(value)
            settings_getter().whitelist = value
        end,
        function()
            return settings_getter().whitelist
        end)
    filters:add_break()
    local blacklist = _create_text_area(filters, "cd_blacklist", TR["Blacklist"], list_help)
    filters:bind(blacklist,
        function(value)
            settings_getter().blacklist = value
        end,
        function()
            return settings_getter().blacklist
        end)
    self:add_tab(TR["Filters"], "filters", filters)

    self.preview_holder = {
        kind = "custom",
        key = "cooldowns_preview",
        height = self._preview_default_height,
    }
    self.preview_holder.control = Turbine.UI.Control()
    self.preview_holder.control:SetParent(self)
    self.preview_holder.control:SetMouseVisible(false)
    self.preview_holder.on_height_changed = function()
        self:layout()
    end
    self.controls.cooldowns_preview = self.preview_holder

    _bind_outline_visibility(self, colors_text, "cd_font_style", "cd_font_outline_color")
end

function CooldownsFeaturePage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function CooldownsFeaturePage:layout()
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
