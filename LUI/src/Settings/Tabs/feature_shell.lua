-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local State = _G.LUI.Settings.State
local Tabs = _G.LUI.Settings.Tabs
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.Tabs.tabbed_page"

local Style = UI.Widgets.Style
local SettingsTabbedPage = Tabs.SettingsTabbedPage

local SECTION_TAB_SCALE = 0.88
local NESTED_TAB_SCALE = 0.78
local SECTION_TAB_FONT_SIZE = 12
local NESTED_TAB_FONT_SIZE = 11
local STYLE_TAB_BASE_FONT_SIZE = 12
local BASE_TAB_HEIGHT = 24
local PREVIEW_GAP = 10
local SECTION_FRAME_PADDING = 8

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, size * State.settings.global.scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(size * State.settings.global.scale))
    end
    return font
end

local function _scaled_tab_font(size)
    return _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + (size - STYLE_TAB_BASE_FONT_SIZE))
end

local function _refresh_preview_noop()
end

local function _apply_button_tab_bar_theme(tab_bar)
    tab_bar._strip_back = Style.BACKGROUND
    tab_bar._content_back = Style.BACKGROUND
    tab_bar._content_border_color = Style.CONTROL_BORDER
    tab_bar:refresh_layout()
end

local function _module_for_page(key, page)
    return {
        key = key,
        create_page = function()
            return page
        end,
    }
end

local SettingsFeatureNestedPage = class(SettingsTabbedPage)

function SettingsFeatureNestedPage:Constructor(window, tab_position, scale_factor, font_size)
    SettingsTabbedPage.Constructor(self, window)
    self._compact_tab_position = tab_position or UI.Widgets.LuiTabBar.position.left
    self._compact_tab_scale_factor = scale_factor or NESTED_TAB_SCALE
    self._compact_tab_font_size = font_size or NESTED_TAB_FONT_SIZE
    self.show_main_content_border = false

    self.sub_tab_bar:set_tab_position(self._compact_tab_position)
    self.sub_tab_bar:set_selection_style(UI.Widgets.LuiTabBar.selection_style.button)
    self.sub_tab_bar:set_show_content_border(true)
    self.sub_tab_bar:set_button_side_margin(0)
    self.sub_tab_bar:set_button_content_gap(_scaled_int(SECTION_FRAME_PADDING))
    self.sub_tab_bar:set_content_padding(0)
    _apply_button_tab_bar_theme(self.sub_tab_bar)
end

function SettingsFeatureNestedPage:apply_ui_scale()
    self.sub_tab_bar:set_tab_position(self._compact_tab_position)
    self.sub_tab_bar:set_show_content_border(true)
    self.sub_tab_bar:set_button_side_margin(0)
    self.sub_tab_bar:set_button_content_gap(_scaled_int(SECTION_FRAME_PADDING))
    self.sub_tab_bar:set_content_padding(0)
    self.sub_tab_bar:set_scale(State.settings.global.scale * self._compact_tab_scale_factor)
    self.sub_tab_bar:set_font(_scaled_tab_font(self._compact_tab_font_size))
    _apply_button_tab_bar_theme(self.sub_tab_bar)

    self.sub_tab_bar:each_widget(function(_, page)
        page:apply_ui_scale()
    end)

    self:layout()
end

function SettingsFeatureNestedPage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    if self._compact_tab_position == UI.Widgets.LuiTabBar.position.left or
        self._compact_tab_position == UI.Widgets.LuiTabBar.position.right then
        local gap = self.window.col_gap
        local side_col_w = math.floor((width - (2 * gap)) / 4)
        if side_col_w < _scaled_int(74) then
            side_col_w = _scaled_int(74)
        end
        self.sub_tab_bar:set_side_tab_width(side_col_w)
    else
        self.sub_tab_bar:set_side_tab_width(nil)
    end

    self.sub_tab_bar:SetPosition(0, 0)
    self.sub_tab_bar:SetSize(width, height)
    self.sub_tab_bar:refresh_layout()
end

local SettingsFeatureSectionPage = class(Turbine.UI.Control)

function SettingsFeatureSectionPage:Constructor(window, preview_key, preview_height, preview_refresh_fn, use_button_tabs)
    Turbine.UI.Control.Constructor(self)

    local ui = window._ui

    self.window = window
    self.controls = {}
    self._color_fields = {}
    self._preview_key = preview_key
    self._preview_default_height = preview_height
    self._preview_refresh_fn = preview_refresh_fn or _refresh_preview_noop
    self._section_order = {}
    self._sections = {}
    self._section_tabs = {}
    self._active_section_key = nil
    self._section_use_button_tabs = use_button_tabs ~= false
    self.loading = false
    self.show_main_content_border = false
    self.color_to_hex = ui.color_to_hex
    self.hex_to_color = ui.hex_to_color

    self.section_tab_bar = UI.Widgets.LuiTabBar()
    self.section_tab_bar:SetParent(self)
    self.section_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
    self.section_tab_bar:set_show_border_left(false)
    if self._section_use_button_tabs == true then
        self.section_tab_bar:set_show_content_border(false)
        self.section_tab_bar:set_selection_style(UI.Widgets.LuiTabBar.selection_style.button)
        self.section_tab_bar:set_content_padding(0)
        _apply_button_tab_bar_theme(self.section_tab_bar)
    else
        self.section_tab_bar:set_show_content_border(true)
        self.section_tab_bar:set_selection_style(UI.Widgets.LuiTabBar.selection_style.connected)
        self.section_tab_bar:set_content_padding(_scaled_int(8))
    end
    self.section_tab_bar.on_tab_changed = function(_, page)
        self:_on_section_changed(page)
    end

    self.section_frame = Turbine.UI.Control()
    self.section_frame:SetParent(self)
    self.section_frame:SetBackColor(Style.CONTROL_BORDER)

    self.section_frame_inner = Turbine.UI.Control()
    self.section_frame_inner:SetParent(self.section_frame)
    self.section_frame_inner:SetBackColor(Style.BACKGROUND)

    self.section_frame_body = Turbine.UI.Control()
    self.section_frame_body:SetParent(self.section_frame_inner)
    self.section_frame_body:SetBackColor(Style.BACKGROUND)

    self.refresh_preview = function()
        local preview_height_before = self.preview_holder ~= nil and self.preview_holder.height or nil
        self._preview_refresh_fn(self.window)

        local preview_height_after = self.preview_holder ~= nil and self.preview_holder.height or nil
        if preview_height_before ~= preview_height_after then
            self:layout()
            self._preview_refresh_fn(self.window)
        end
    end

    if preview_key ~= nil and preview_height ~= nil then
        self.preview_holder = {
            kind = "custom",
            key = preview_key,
            height = preview_height,
        }
        self.preview_holder.control = Turbine.UI.Control()
        self.preview_holder.control:SetParent(self)
        self.preview_holder.control:SetMouseVisible(false)
        self.controls[preview_key] = self.preview_holder
    end

    self.SizeChanged = function()
        self:layout()
    end
end

function SettingsFeatureSectionPage:_merge_page_controls(page)
    for key, entry in pairs(page.controls) do
        self.controls[key] = entry
    end

    for i = 1, #page._color_fields do
        self._color_fields[#self._color_fields + 1] = page._color_fields[i]
    end
end

function SettingsFeatureSectionPage:add_section(text, key, page)
    page._tab_key = key

    self._section_order[#self._section_order + 1] = key
    self._sections[key] = page
    if self._section_use_button_tabs == true then
        local tab = Turbine.UI.Control()
        tab._tab_key = key
        page:SetParent(self.section_frame_body)
        page:SetVisible(false)
        self._section_tabs[key] = tab
        self.section_tab_bar:add_tab(text, tab)
    else
        self._section_tabs[key] = page
        self.section_tab_bar:add_tab(text, page)
    end
    self:_merge_page_controls(page)

    if self._active_section_key == nil then
        self._active_section_key = key
    end
end

function SettingsFeatureSectionPage:_sync_active_section_visibility()
    if self._section_use_button_tabs ~= true then
        return
    end
    for i = 1, #self._section_order do
        local key = self._section_order[i]
        local page = self._sections[key]
        page:SetVisible(key == self._active_section_key)
    end
end

function SettingsFeatureSectionPage:_on_section_changed(tab)
    self._active_section_key = tab._tab_key
    self:_sync_active_section_visibility()

    local page = self._sections[self._active_section_key]
    self:layout()
    page:on_selected()
    self:refresh_preview()
end

function SettingsFeatureSectionPage:on_selected(preferred_key)
    self:layout()
    self:select_section(preferred_key)
end

function SettingsFeatureSectionPage:select_section(key)
    if self._sections[key] == nil then
        key = self._active_section_key or self._section_order[1]
    end

    local page = self._section_tabs[key]
    local index = self.section_tab_bar:find_index(function(_, candidate)
        return candidate == page
    end)

    if self.section_tab_bar:get_selected_index() == index then
        self:_on_section_changed(page)
        return
    end

    self.section_tab_bar:select_tab(index)
end

function SettingsFeatureSectionPage:each_child_page(fn)
    for i = 1, #self._section_order do
        fn(self._sections[self._section_order[i]])
    end
end

function SettingsFeatureSectionPage:apply_ui_scale()
    self.section_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
    self.section_tab_bar:set_show_border_left(false)
    if self._section_use_button_tabs == true then
        self.section_tab_bar:set_show_content_border(false)
        self.section_tab_bar:set_selection_style(UI.Widgets.LuiTabBar.selection_style.button)
        self.section_tab_bar:set_content_padding(0)
        self.section_tab_bar:set_scale(State.settings.global.scale * SECTION_TAB_SCALE)
        self.section_tab_bar:set_font(_scaled_tab_font(SECTION_TAB_FONT_SIZE))
        _apply_button_tab_bar_theme(self.section_tab_bar)
    else
        self.section_tab_bar:set_show_content_border(true)
        self.section_tab_bar:set_selection_style(UI.Widgets.LuiTabBar.selection_style.connected)
        self.section_tab_bar:set_content_padding(_scaled_int(8))
        self.section_tab_bar:set_scale(State.settings.global.scale)
        self.section_tab_bar:set_font(self.window.tab_font)
    end

    for i = 1, #self._section_order do
        self._sections[self._section_order[i]]:apply_ui_scale()
    end

    self:layout()
end

function SettingsFeatureSectionPage:close_all_dropdowns()
    for i = 1, #self._section_order do
        self._sections[self._section_order[i]]:close_all_dropdowns()
    end
end

function SettingsFeatureSectionPage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    local section_tab_h = self._section_use_button_tabs == true and _scaled_int(BASE_TAB_HEIGHT * SECTION_TAB_SCALE) or
        _scaled_int(BASE_TAB_HEIGHT)
    local frame_margin = _scaled_int(SECTION_FRAME_PADDING)
    local section_gap = frame_margin
    local preview_h = 0
    local preview_gap = 0
    local min_frame_h = _scaled_int(120)
    local min_top_h = section_tab_h + section_gap + min_frame_h
    local top_h = height

    if self.preview_holder ~= nil then
        preview_h = self.preview_holder.height or self._preview_default_height
        preview_gap = _scaled_int(PREVIEW_GAP)
        top_h = height - preview_h - preview_gap
        if top_h < min_top_h then
            top_h = min_top_h
            preview_h = height - top_h - preview_gap
        end
        if preview_h < _scaled_int(100) then
            preview_h = _scaled_int(100)
            top_h = height - preview_h - preview_gap
        end
    end

    if top_h < 1 then
        top_h = 1
    end

    if self._section_use_button_tabs == true then
        local frame_x = 0
        local frame_y = section_tab_h + section_gap
        local frame_w = width
        local frame_h = top_h - frame_y
        if frame_w < 1 then
            frame_w = 1
        end
        if frame_h < 1 then
            frame_h = 1
        end

        self.section_tab_bar:SetPosition(0, 0)
        self.section_tab_bar:SetSize(width, section_tab_h)
        self.section_tab_bar:refresh_layout()

        local border_value = tonumber(Style.BORDER_WIDTH)
        if border_value == nil then
            error("Invalid Style.BORDER_WIDTH: " .. tostring(Style.BORDER_WIDTH))
        end
        local border = math.max(1, _scaled_int(border_value))
        local body_pad = frame_margin

        self.section_frame:SetVisible(true)
        self.section_frame:SetPosition(frame_x, frame_y)
        self.section_frame:SetSize(frame_w, frame_h)

        self.section_frame_inner:SetPosition(border, border)
        self.section_frame_inner:SetSize(math.max(0, frame_w - (border * 2)), math.max(0, frame_h - (border * 2)))

        local inner_w, inner_h = self.section_frame_inner:GetSize()
        self.section_frame_body:SetPosition(body_pad, body_pad)
        self.section_frame_body:SetSize(math.max(0, inner_w - (body_pad * 2)), math.max(0, inner_h - (body_pad * 2)))

        local body_w, body_h = self.section_frame_body:GetSize()
        for i = 1, #self._section_order do
            local page = self._sections[self._section_order[i]]
            page:SetPosition(0, 0)
            page:SetSize(body_w, body_h)
        end
    else
        self.section_frame:SetVisible(false)
        self.section_tab_bar:SetPosition(0, 0)
        self.section_tab_bar:SetSize(width, top_h)
        self.section_tab_bar:refresh_layout()
    end

    if self.preview_holder ~= nil then
        self.preview_holder.control:SetPosition(0, top_h + preview_gap)
        self.preview_holder.control:SetSize(width, preview_h)
    end
end

local SettingsFeatureShell = {
    scaled_int = _scaled_int,
    module_for_page = _module_for_page,
    nested_page_class = SettingsFeatureNestedPage,
    section_page_class = SettingsFeatureSectionPage,
    nested_tab_scale = NESTED_TAB_SCALE,
    nested_tab_font_size = NESTED_TAB_FONT_SIZE,
}

Tabs.SettingsFeatureShell = SettingsFeatureShell
Tabs.SettingsFeatureNestedPage = SettingsFeatureNestedPage
Tabs.SettingsFeatureSectionPage = SettingsFeatureSectionPage
