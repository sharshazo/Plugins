-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local Content = _G.LUI.Settings.Content
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

local BASE_SCROLL_W = 10
local Style = UI.Widgets.Style

local function _scaled_size(value)
    return value * State.settings.global.scale
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local scaled_size = _scaled_size(size)
    local font = FONT_TO_LOTRO(name, scaled_size)
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(scaled_size))
    end
    return font
end

local ConfigContent = class(Turbine.UI.Control)
Content.ConfigContent = ConfigContent

function ConfigContent:Constructor(window, columns, refresh_preview_fn)
    Turbine.UI.Control.Constructor(self)

    self.window = window
    self.loading = false
    self.controls = {}
    self.fields = {}
    self._color_fields = {}
    self._bound_entries = {}
    self.grid_columns = 2
    self.compact_fields = true

    local ui = window._ui
    self.font_name_labels = ui.font_name_labels
    self.font_name_values = ui.font_name_values
    self.font_style_labels = ui.font_style_labels
    self.font_style_values = ui.font_style_values
    self.side_labels = ui.side_labels
    self.side_values = ui.side_values
    self.text_alignment_labels = ui.text_alignment_labels
    self.text_alignment_values = ui.text_alignment_values
    self.vitals_label_anchor_labels = ui.vitals_label_anchor_labels
    self.vitals_label_anchor_values = ui.vitals_label_anchor_values
    self.vitals_label_width_mode_labels = ui.vitals_label_width_mode_labels
    self.vitals_label_width_mode_values = ui.vitals_label_width_mode_values
    self.vitals_label_link_labels = ui.vitals_label_link_labels
    self.vitals_label_link_values = ui.vitals_label_link_values
    self.vitals_effect_slot_labels = ui.vitals_effect_slot_labels
    self.vitals_effect_slot_values = ui.vitals_effect_slot_values
    self.abbrev_digits_labels = ui.abbrev_digits_labels
    self.abbrev_digits_values = ui.abbrev_digits_values
    self.abbrev_width_labels = ui.abbrev_width_labels
    self.abbrev_width_values = ui.abbrev_width_values
    self.abbrev_method_labels = ui.abbrev_method_labels
    self.abbrev_method_values = ui.abbrev_method_values
    self.vitals_effects_position_labels = ui.vitals_effects_position_labels
    self.vitals_effects_position_values = ui.vitals_effects_position_values
    self.vital_format_help = ui.vital_format_help
    self.bubble_format_help = ui.bubble_format_help
    self.color_to_hex = ui.color_to_hex
    self.hex_to_color = ui.hex_to_color

    self.scroll = Turbine.UI.ListBox()
    self.scroll:SetParent(self)
    self.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.scroll_bar = Turbine.UI.Lotro.ScrollBar()
    self.scroll_bar:SetParent(self)
    self.scroll_bar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.scroll_bar:SetWidth(BASE_SCROLL_W)
    self.scroll:SetVerticalScrollBar(self.scroll_bar)
    self.scroll_bar.ValueChanged = function()
        if self.on_scroll_changed ~= nil then
            self:on_scroll_changed()
        end
    end

    self.form = Turbine.UI.Control()
    self.scroll:AddItem(self.form)

    -- Settings pages use a four-column visual grid. A left nested tab bar counts
    -- as one column, so its content pages use 3; pages without one use 4.
    if columns ~= nil then
        self:set_grid_columns(columns)
    end
    if refresh_preview_fn ~= nil then
        self.refresh_preview = refresh_preview_fn
    end

    self.SizeChanged = function()
        self:layout()
    end
end

function ConfigContent:_refresh_text_control(control)
    control:SetText(control:GetText())
end

function ConfigContent:set_grid_columns(columns)
    local value = tonumber(columns)
    if value == nil or value < 1 then
        error("Invalid ConfigContent grid column count: " .. tostring(columns))
    end
    self.grid_columns = math.floor(value + 0.5)
end

function ConfigContent:set_compact_fields(enabled)
    self.compact_fields = enabled == true
end

local function _resolve_entry_span(value, grid_columns)
    if value == true then
        return grid_columns
    end

    local numeric = tonumber(value)
    if numeric == nil then
        return 1
    end

    local span = math.floor(numeric + 0.5)
    if span < 1 then
        return 1
    end
    if span > grid_columns then
        return grid_columns
    end
    return span
end

function ConfigContent:_refresh_preview()
    if self.loading == true then
        return
    end
    if self.refresh_preview ~= nil then
        self:refresh_preview()
    end
end

function ConfigContent:_bind_hint(target, help_source)
    if target == nil or help_source == nil then
        return
    end
    self.window:bind_tooltip(target, help_source)
end

function ConfigContent:add_title(text)
    local entry = {}
    entry.kind = "title"

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(self.form)
    entry.label:SetFont(self.window.title_font)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(text)

    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_info(text, height)
    local entry = {}
    entry.kind = "info"
    entry.base_height = height or 34
    entry.height = _scaled_int(entry.base_height)

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(self.form)
    entry.label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetMultiline(true)
    entry.label:SetForeColor(Style.ALTERNATE_FOREGROUND)
    entry.label:SetText(text)
    entry.label:SetMouseVisible(false)

    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_hr()
    local entry = {}
    entry.kind = "hr"

    entry.line = Turbine.UI.Control()
    entry.line:SetParent(self.form)
    entry.line:SetMouseVisible(false)
    entry.line:SetBackColor(Style.CONTROL_BORDER)

    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_break(height)
    local entry = {}
    entry.kind = "break"
    entry.base_height = height or 4
    entry.height = _scaled_int(entry.base_height)

    entry.spacer = Turbine.UI.Control()
    entry.spacer:SetParent(self.form)
    entry.spacer:SetMouseVisible(false)

    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_custom(key, height)
    local entry = {}
    entry.kind = "custom"
    entry.key = key
    entry.base_height = height or 44
    entry.height = _scaled_int(entry.base_height)

    entry.control = Turbine.UI.Control()
    entry.control:SetParent(self.form)
    entry.control:SetMouseVisible(false)

    self.controls[key] = entry
    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_button(key, text, click_fn, help_text, span)
    local entry = {}
    entry.kind = "button"
    entry.key = key
    entry.help_text = help_text
    entry.span = span

    entry.button = UI.Widgets.LuiButton()
    entry.button:SetParent(self.form)
    entry.button:set_scale(State.settings.global.scale)
    entry.button:set_font(self.window.input_font)
    entry.button:set_text(text)
    entry.button:SetZOrder(2)
    entry.button.Click = click_fn

    self:_bind_hint(entry.button, function()
        return entry.help_text
    end)

    self.controls[key] = entry
    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_line_edit(key, label_text, save_fn, load_fn, help_text, span)
    local entry = {}
    entry.kind = "text"
    entry.key = key
    entry.label_text = label_text
    entry.is_color = false
    entry.help_text = help_text
    entry.span = span

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(self.form)
    entry.label:SetFont(self.window.field_label_font)
    entry.label:SetMultiline(true)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)
    entry.label:SetZOrder(1)

    entry.tb = UI.Widgets.LuiLineEdit()
    entry.tb:SetParent(self.form)
    entry.tb:SetFont(self.window.input_font)
    entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    entry.tb:SetZOrder(2)

    self:_bind_hint(entry.tb, function()
        return entry.help_text
    end)

    entry.tb.TextChanged = function()
        if self.loading == true then
            return
        end
        if entry.on_changed ~= nil then
            entry.on_changed(entry.tb:GetText())
        end
        self:_refresh_preview()
    end

    function entry:get_value()
        return entry.tb:GetText()
    end

    function entry:set_value(value)
        entry.tb:SetText(value)
    end

    if save_fn ~= nil or load_fn ~= nil then
        if type(save_fn) ~= "function" then
            error("ConfigContent line edit binding is missing save_fn")
        end
        if type(load_fn) ~= "function" then
            error("ConfigContent line edit binding is missing load_fn")
        end
        entry.save_fn = save_fn
        entry.load_fn = load_fn
        self._bound_entries[#self._bound_entries + 1] = entry
    end

    self.controls[key] = entry
    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_text_area(key, label_text, save_fn, load_fn, help_text, span, base_height)
    local entry = {}
    entry.kind = "textarea"
    entry.key = key
    entry.label_text = label_text
    entry.is_color = false
    entry.help_text = help_text
    entry.span = span
    entry.base_height = base_height or 120
    entry.height = _scaled_int(entry.base_height)

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(self.form)
    entry.label:SetFont(self.window.field_label_font)
    entry.label:SetMultiline(true)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)
    entry.label:SetZOrder(1)

    entry.tb = UI.Widgets.LuiLineEdit()
    entry.tb:SetParent(self.form)
    entry.tb:set_scale(State.settings.global.scale)
    entry.tb:SetFont(self.window.input_font)
    entry.tb:SetMultiline(true)
    entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    entry.tb:SetZOrder(2)

    self:_bind_hint(entry.tb, function()
        return entry.help_text
    end)

    entry.tb.TextChanged = function()
        if self.loading == true then
            return
        end
        if entry.on_changed ~= nil then
            entry.on_changed(entry.tb:GetText())
        end
        self:_refresh_preview()
    end

    function entry:get_value()
        return entry.tb:GetText()
    end

    function entry:set_value(value)
        entry.tb:SetText(value)
    end

    if save_fn ~= nil or load_fn ~= nil then
        if type(save_fn) ~= "function" then
            error("ConfigContent text area binding is missing save_fn")
        end
        if type(load_fn) ~= "function" then
            error("ConfigContent text area binding is missing load_fn")
        end
        entry.save_fn = save_fn
        entry.load_fn = load_fn
        self._bound_entries[#self._bound_entries + 1] = entry
    end

    self.controls[key] = entry
    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_color_picker(key, label_text, save_fn, load_fn, help_text, span)
    local entry = {}
    entry.kind = "text"
    entry.key = key
    entry.label_text = label_text
    entry.is_color = true
    entry.help_text = help_text
    entry.span = span

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(self.form)
    entry.label:SetFont(self.window.field_label_font)
    entry.label:SetMultiline(true)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)
    entry.label:SetZOrder(1)

    entry.tb = UI.Widgets.LuiColorField()
    entry.tb:set_scale(State.settings.global.scale)
    entry.tb:SetPickerHost(self.window)
    entry.tb:SetParent(self.form)
    entry.tb:SetFont(self.window.input_font)
    entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    entry.tb:SetZOrder(2)
    self._color_fields[#self._color_fields + 1] = entry

    self:_bind_hint(entry.tb, function()
        return entry.help_text
    end)
    if entry.tb.tb ~= nil then
        self:_bind_hint(entry.tb.tb, function()
            return entry.help_text
        end)
    end
    if entry.tb.swatch_border ~= nil then
        self:_bind_hint(entry.tb.swatch_border, function()
            return entry.help_text
        end)
    end

    entry.tb.TextChanged = function()
        if self.loading == true then
            return
        end
        self:update_swatch(entry)
        if entry.on_changed ~= nil then
            entry.on_changed(entry.tb:GetText())
        end
        self:_refresh_preview()
    end

    function entry:get_value()
        return entry.tb:GetText()
    end

    function entry:set_value(value)
        entry.tb:SetText(value)
    end

    if save_fn ~= nil or load_fn ~= nil then
        if type(save_fn) ~= "function" then
            error("ConfigContent color picker binding is missing save_fn")
        end
        if type(load_fn) ~= "function" then
            error("ConfigContent color picker binding is missing load_fn")
        end
        entry.save_fn = save_fn
        entry.load_fn = load_fn
        self._bound_entries[#self._bound_entries + 1] = entry
    end

    self.controls[key] = entry
    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_dropdown(key, label_text, option_labels, option_values, save_fn, load_fn, help_text,
                                    span)
    local entry = {}
    entry.kind = "dropdown"
    entry.key = key
    entry.label_text = label_text
    entry.option_labels = option_labels
    entry.option_values = option_values
    entry.help_text = help_text
    entry.span = span
    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(self.form)
    entry.label:SetFont(self.window.field_label_font)
    entry.label:SetMultiline(true)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)
    entry.label:SetZOrder(1)

    entry.button = UI.Widgets.LuiDropdown()
    entry.button:SetParent(self.form)
    entry.button:set_scale(State.settings.global.scale)
    entry.button:SetFont(self.window.input_font)
    entry.button:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    entry.button:SetPopupHost(self.window)
    entry.button:SetMappedOptions(entry.option_labels, entry.option_values)
    entry.button:SetZOrder(2)
    entry.button.ValueChanged = function(_, value)
        if self.loading == true then
            return
        end
        if entry.on_changed ~= nil then
            entry.on_changed(value)
        end
        self:_refresh_preview()
    end

    self:_bind_hint(entry.button.button or entry.button, function()
        return entry.help_text
    end)

    function entry:get_value()
        return entry.button:GetValue()
    end

    function entry:set_value(value)
        entry.button:SetValue(value)
    end

    if save_fn ~= nil or load_fn ~= nil then
        if type(save_fn) ~= "function" then
            error("ConfigContent dropdown binding is missing save_fn")
        end
        if type(load_fn) ~= "function" then
            error("ConfigContent dropdown binding is missing load_fn")
        end
        entry.save_fn = save_fn
        entry.load_fn = load_fn
        self._bound_entries[#self._bound_entries + 1] = entry
    end

    self.controls[key] = entry
    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:add_checkbox(key, label_text, save_fn, load_fn, span)
    local entry = {}
    entry.kind = "checkbox"
    entry.key = key
    entry.label_text = label_text
    entry.span = span

    entry.cb = UI.Widgets.LuiCheckBox()
    entry.cb:SetParent(self.form)
    entry.cb:SetFont(self.window.field_label_font)
    entry.cb:SetText(label_text)
    entry.cb:SetZOrder(2)
    entry.cb.CheckedChanged = function()
        if self.loading == true then
            return
        end
        if entry.on_changed ~= nil then
            entry.on_changed(entry.cb:IsChecked())
        end
        self:_refresh_preview()
    end

    function entry:get_value()
        return entry.cb:IsChecked()
    end

    function entry:set_value(value)
        entry.cb:SetChecked(value)
    end

    if save_fn ~= nil or load_fn ~= nil then
        if type(save_fn) ~= "function" then
            error("ConfigContent checkbox binding is missing save_fn")
        end
        if type(load_fn) ~= "function" then
            error("ConfigContent checkbox binding is missing load_fn")
        end
        entry.save_fn = save_fn
        entry.load_fn = load_fn
        self._bound_entries[#self._bound_entries + 1] = entry
    end

    self.controls[key] = entry
    self.fields[#self.fields + 1] = entry
    return entry
end

function ConfigContent:update_swatch(entry)
    if entry == nil or entry.is_color ~= true or entry.tb == nil then
        return
    end

    if entry.tb.update_swatch ~= nil then
        entry.tb:update_swatch()
    end
end

function ConfigContent:update_all_swatches()
    for i = 1, #self._color_fields do
        self:update_swatch(self._color_fields[i])
    end
end

function ConfigContent:apply_ui_scale()
    local scale = State.settings.global.scale

    for i = 1, #self.fields do
        local field = self.fields[i]
        if field ~= nil then
            if field.kind == "title" and field.label ~= nil then
                field.label:SetFont(self.window.title_font)
            elseif field.kind == "info" then
                if field.label ~= nil then
                    field.label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
                end
                if field.base_height ~= nil then
                    field.height = _scaled_int(field.base_height)
                end
            elseif field.kind == "text" or field.kind == "textarea" then
                if field.label ~= nil then
                    field.label:SetFont(self.window.field_label_font)
                end
                if field.tb ~= nil and field.tb.set_scale ~= nil then
                    field.tb:set_scale(scale)
                end
                if field.tb ~= nil and field.tb.SetFont ~= nil then
                    field.tb:SetFont(self.window.input_font)
                end
                if field.kind == "textarea" and field.base_height ~= nil then
                    field.height = _scaled_int(field.base_height)
                end
            elseif field.kind == "dropdown" then
                if field.label ~= nil then
                    field.label:SetFont(self.window.field_label_font)
                end
                if field.button ~= nil and field.button.set_scale ~= nil then
                    field.button:set_scale(scale)
                end
                if field.button ~= nil and field.button.SetFont ~= nil then
                    field.button:SetFont(self.window.input_font)
                end
            elseif (field.kind == "break" or field.kind == "custom") and field.base_height ~= nil then
                field.height = _scaled_int(field.base_height)
                if field.kind == "custom" and field.apply_ui_scale ~= nil then
                    field:apply_ui_scale()
                end
            elseif field.kind == "button" then
                field.button:set_scale(scale)
                field.button:set_font(self.window.input_font)
            elseif field.kind == "checkbox" and field.cb ~= nil then
                if field.cb.set_scale ~= nil then
                    field.cb:set_scale(scale)
                end
                field.cb:SetFont(self.window.field_label_font)
            end
        end
    end

    self:layout()
end

function ConfigContent:close_all_dropdowns()
    for i = 1, #self.fields do
        local field = self.fields[i]
        if field ~= nil and field.kind == "dropdown" and field.button ~= nil then
            field.button:Close()
        end
    end
end

function ConfigContent:refresh_text_inputs()
    for i = 1, #self.fields do
        local field = self.fields[i]
        if field ~= nil then
            if field.kind == "text" or field.kind == "textarea" then
                self:_refresh_text_control(field.tb)
            elseif field.kind == "custom" and field.refresh_text ~= nil then
                field:refresh_text()
            end
        end
    end
end

function ConfigContent:on_selected()
    self:layout()
    local was_loading = self.loading == true
    self.loading = true
    self:refresh_text_inputs()
    self.loading = was_loading
    self:_refresh_preview()
    self:layout()
end

function ConfigContent:layout()
    local page_width, page_height = self:GetSize()
    local scroll_w = BASE_SCROLL_W
    local title_h = _scaled_int(22)
    local title_gap = _scaled_int(24)
    local hr_top = _scaled_int(3)
    local hr_gap = _scaled_int(6)
    local custom_default_h = _scaled_int(44)
    local custom_min_h = _scaled_int(7)
    local custom_gap = _scaled_int(4)
    local form_pad = _scaled_int(4)
    local compact_label_h = _scaled_int(14)
    local compact_field_gap = _scaled_int(2)
    local compact_row_gap = _scaled_int(8)

    if page_width == nil or page_height == nil or page_width < 1 or page_height < 1 then
        return
    end

    if page_height < _scaled_int(30) then
        page_height = _scaled_int(30)
    end

    self.scroll:SetPosition(0, 0)
    self.scroll:SetSize(math.max(0, page_width - scroll_w - self.window.scroll_bar_gap), page_height)

    self.scroll_bar:SetPosition(self.scroll:GetWidth() + self.window.scroll_bar_gap, 0)
    self.scroll_bar:SetHeight(page_height)

    local form_width = self.scroll:GetWidth()
    local inner_width = form_width - (2 * self.window.content_padding)
    if inner_width < _scaled_int(74) then
        inner_width = _scaled_int(74)
    end

    local grid_columns = self.grid_columns or 2
    if grid_columns < 1 then
        grid_columns = 1
    end
    local grid_gaps = (grid_columns - 1) * self.window.col_gap
    local col_width = math.floor((inner_width - grid_gaps) / grid_columns)

    local y = form_pad
    local col = 0

    for i = 1, #self.fields do
        local field = self.fields[i]
        local is_visible = true
        if field.visible_if ~= nil and field.visible_if() == false then
            is_visible = false
        end

        if field.kind == "title" then
            field.label:SetVisible(is_visible)
        elseif field.kind == "info" then
            field.label:SetVisible(is_visible)
        elseif field.kind == "hr" then
            field.line:SetVisible(is_visible)
        elseif field.kind == "break" then
            field.spacer:SetVisible(is_visible)
        elseif field.kind == "custom" then
            field.control:SetVisible(is_visible)
        elseif field.kind == "button" then
            field.button:SetVisible(is_visible)
        elseif field.kind == "text" then
            field.label:SetVisible(is_visible)
            field.tb:SetVisible(is_visible)
        elseif field.kind == "dropdown" then
            field.label:SetVisible(is_visible)
            field.button:SetVisible(is_visible)
        elseif field.kind == "checkbox" then
            field.cb:SetVisible(is_visible)
        elseif field.kind == "textarea" then
            field.label:SetVisible(is_visible)
            field.tb:SetVisible(is_visible)
        end

        if is_visible and field.kind == "title" then
            if self.compact_fields == true and col ~= 0 then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            elseif col == 1 then
                y = y + self.window.row_height
                col = 0
            end

            field.label:SetPosition(self.window.content_padding, y)
            field.label:SetSize(inner_width, title_h)
            y = y + title_gap
            col = 0
        elseif is_visible and field.kind == "info" then
            if self.compact_fields == true and col ~= 0 then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            elseif col == 1 then
                y = y + self.window.row_height
                col = 0
            end

            local h = field.height or self.window.row_height
            field.label:SetPosition(self.window.content_padding, y)
            field.label:SetSize(inner_width, h)
            y = y + h
            col = 0
        elseif is_visible and field.kind == "hr" then
            if self.compact_fields == true and col ~= 0 then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            elseif col == 1 then
                y = y + self.window.row_height
                col = 0
            end

            field.line:SetPosition(self.window.content_padding, y + hr_top)
            field.line:SetSize(inner_width, 1)
            y = y + hr_gap
            col = 0
        elseif is_visible and field.kind == "break" then
            if self.compact_fields == true and col ~= 0 then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            elseif col == 1 then
                y = y + self.window.row_height
                col = 0
            end

            field.spacer:SetPosition(self.window.content_padding, y)
            field.spacer:SetSize(inner_width, field.height)
            y = y + field.height
            col = 0
        elseif is_visible and field.kind == "custom" then
            if self.compact_fields == true and col ~= 0 then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            elseif col == 1 then
                y = y + self.window.row_height
                col = 0
            end

            local h = field.height or custom_default_h
            if type(h) ~= "number" then
                h = custom_default_h
            end
            if h < custom_min_h then
                h = custom_min_h
            end

            field.control:SetPosition(self.window.content_padding, y)
            field.control:SetSize(inner_width, h)
            y = y + h + custom_gap
            col = 0
        elseif is_visible and field.kind == "textarea" then
            if self.compact_fields == true and col ~= 0 then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            elseif col == 1 then
                y = y + self.window.row_height
                col = 0
            end

            local field_span = _resolve_entry_span(field.span, grid_columns)
            local span_w = (col_width * field_span) + ((field_span - 1) * self.window.col_gap)

            field.label:SetPosition(self.window.content_padding, y)
            field.label:SetSize(span_w, compact_label_h)
            local box_y = y + compact_label_h + compact_field_gap
            field.tb:SetPosition(self.window.content_padding, box_y)
            field.tb:SetSize(span_w, field.height)
            y = box_y + field.height + compact_row_gap
            col = 0
        elseif is_visible and self.compact_fields == true then
            local field_span = _resolve_entry_span(field.span, grid_columns)
            if col + field_span > grid_columns then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            end

            local x = self.window.content_padding + (col * (col_width + self.window.col_gap))
            local span_w = (col_width * field_span) + ((field_span - 1) * self.window.col_gap)

            if field.kind == "checkbox" then
                field.cb:SetPosition(x, y + compact_label_h + compact_field_gap)
                field.cb:SetSize(span_w, self.window.input_height)
            elseif field.kind == "button" then
                field.button:SetPosition(x, y + compact_label_h + compact_field_gap)
                field.button:SetSize(span_w, self.window.input_height)
            elseif field.kind == "text" then
                field.label:SetPosition(x, y)
                field.label:SetSize(span_w, compact_label_h)
                field.tb:SetPosition(x, y + compact_label_h + compact_field_gap)
                field.tb:SetSize(span_w, self.window.input_height)
            elseif field.kind == "dropdown" then
                field.label:SetPosition(x, y)
                field.label:SetSize(span_w, compact_label_h)
                field.button:SetPosition(x, y + compact_label_h + compact_field_gap +
                    self.window.dropdown_y_offset)
                field.button:SetSize(span_w, self.window.input_height)
            end

            col = col + field_span
            if col >= grid_columns then
                y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
                col = 0
            end
        elseif is_visible then
            local field_span = _resolve_entry_span(field.span, grid_columns)
            if col + field_span > grid_columns then
                y = y + self.window.row_height
                col = 0
            end

            local x = self.window.content_padding + (col * (col_width + self.window.col_gap))
            local span_w = (col_width * field_span) + ((field_span - 1) * self.window.col_gap)

            if field.kind == "checkbox" then
                field.cb:SetPosition(x, y)
                field.cb:SetSize(span_w, self.window.field_label_height)
            elseif field.kind == "button" then
                field.button:SetPosition(x, y)
                field.button:SetSize(span_w, self.window.input_height)
            else
                local label_width_span = math.floor(span_w * 0.55)
                local input_width_span = span_w - label_width_span - self.window.inner_gap
                if input_width_span < _scaled_int(59) then
                    input_width_span = _scaled_int(59)
                end

                field.label:SetPosition(x, y)
                field.label:SetSize(label_width_span, self.window.field_label_height)

                local input_y = y + math.floor((self.window.field_label_height - self.window.input_height) / 2)
                if field.kind == "text" then
                    field.tb:SetPosition(x + label_width_span + self.window.inner_gap, input_y)
                    field.tb:SetSize(input_width_span, self.window.input_height)
                else
                    field.button:SetPosition(x + label_width_span + self.window.inner_gap,
                        input_y + self.window.dropdown_y_offset)
                    field.button:SetSize(input_width_span, self.window.input_height)
                end
            end

            col = col + field_span
            if col >= grid_columns then
                y = y + self.window.row_height
                col = 0
            end
        end
    end

    if self.compact_fields == true then
        if col ~= 0 then
            y = y + compact_label_h + compact_field_gap + self.window.input_height + compact_row_gap
        end
    elseif col == 1 then
        y = y + self.window.row_height
    end

    self.form:SetSize(form_width, y + form_pad)
end

function ConfigContent:add_row_break()
    return self:add_break(0)
end

function ConfigContent:bind(entry, save_fn, load_fn)
    if type(save_fn) ~= "function" then
        error("ConfigContent binding is missing save_fn")
    end
    if type(load_fn) ~= "function" then
        error("ConfigContent binding is missing load_fn")
    end

    entry.save_fn = save_fn
    entry.load_fn = load_fn
    self._bound_entries[#self._bound_entries + 1] = entry
    return entry
end

function ConfigContent:load()
    self.loading = true

    for i = 1, #self._bound_entries do
        local entry = self._bound_entries[i]
        entry:set_value(entry.load_fn())
    end

    self.loading = false
    self:update_all_swatches()
    self:layout()
end

function ConfigContent:save()
    for i = 1, #self._bound_entries do
        local entry = self._bound_entries[i]
        entry.save_fn(entry:get_value())
    end
end
