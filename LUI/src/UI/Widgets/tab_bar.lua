-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.assets"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local UI = _G.LUI.UI
local Widgets = UI.Widgets
local AssetIds = UI.Assets
local LuiButton = Widgets.LuiButton
local LuiLabel = Widgets.LuiLabel
local Style = Widgets.Style

local POSITION_TOP = "top"
local POSITION_BOTTOM = "bottom"
local POSITION_LEFT = "left"
local POSITION_RIGHT = "right"
local SELECTION_STYLE_CONNECTED = "connected"
local SELECTION_STYLE_BUTTON = "button"

local BASE_WIDGET_W = 320
local BASE_WIDGET_H = 200
local BASE_TAB_HEIGHT = 24
local BASE_SIDE_TAB_WIDTH = 124
local BASE_SIDE_TAB_HEIGHT = 24
local BASE_TAB_GAP = 0
local BASE_BUTTON_TAB_GAP = 4
local BASE_BUTTON_SIDE_MARGIN = 4
local BASE_TAB_PADDING_X = 14
local BASE_LABEL_PADDING_X = 8
local BASE_CONTENT_PADDING = 0
local BASE_MIN_TAB_WIDTH = 56
local BASE_APPROX_CHAR_WIDTH = 7
local BASE_SCROLL_BUTTON_SIZE = 18
local BASE_SCROLL_BUTTON_GAP = 2

local function _round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function _scaled_size(scale, value)
    return (tonumber(scale) or 1) * value
end

local function _scaled_int(scale, value)
    return _round(_scaled_size(scale, value))
end

local function _scaled_font(scale, name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(scale, size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(scale, size)))
    end
    return font
end

local function _normalize_position(position)
    if position == POSITION_BOTTOM or position == POSITION_LEFT or position == POSITION_RIGHT then
        return position
    end
    return POSITION_TOP
end

local function _normalize_selection_style(style)
    if style == SELECTION_STYLE_BUTTON then
        return SELECTION_STYLE_BUTTON
    end
    return SELECTION_STYLE_CONNECTED
end

local function _set_rect(control, x, y, width, height)
    if control == nil then
        return
    end

    local px = _round(x)
    local py = _round(y)
    local w = math.max(0, _round(width))
    local h = math.max(0, _round(height))

    control:SetPosition(px, py)
    control:SetSize(w, h)
end

local function _show_value(value)
    return value ~= false
end

local function _approx_char_width_units(ch)
    if ch == " " then
        return 0.45
    end
    if ch == "." or ch == "," or ch == ":" or ch == ";" or ch == "'" then
        return 0.35
    end
    if ch == "m" then
        return 1.70
    end
    if ch == "w" then
        return 1.58
    end
    if ch == "n" or ch == "h" or ch == "u" then
        return 1.00
    end
    if ch == "a" or ch == "c" or ch == "e" or ch == "o" or ch == "s" then
        return 0.96
    end
    if ch == "d" or ch == "g" or ch == "p" or ch == "q" then
        return 1.02
    end
    if ch == "b" or ch == "k" or ch == "x" or ch == "y" or ch == "z" then
        return 0.94
    end
    if ch == "i" or ch == "l" or ch == "I" or ch == "j" then
        return 0.55
    end
    if ch == "f" or ch == "t" or ch == "r" then
        return 0.70
    end
    if ch == "M" or ch == "W" then
        return 1.82
    end
    if ch == "N" or ch == "H" or ch == "U" then
        return 1.14
    end
    if string.match(ch, "%u") ~= nil then
        return 1.08
    end
    if string.match(ch, "%l") ~= nil then
        return 0.98
    end
    if string.match(ch, "%d") ~= nil then
        return 0.95
    end
    return 1.0
end

local function _approx_text_width(scale, text)
    local value = tostring(text or "")
    local units = 0
    if string.len(value) < 1 then
        units = 1
    else
        for i = 1, string.len(value) do
            units = units + _approx_char_width_units(string.sub(value, i, i))
        end
    end

    return _scaled_int(scale, BASE_TAB_PADDING_X * 2) + _scaled_int(scale, BASE_APPROX_CHAR_WIDTH * units)
end

local function _tab_gap(scale, selection_style)
    if selection_style == SELECTION_STYLE_BUTTON then
        return _scaled_int(scale, BASE_BUTTON_TAB_GAP)
    end

    return _scaled_int(scale, BASE_TAB_GAP)
end

local function _button_side_margin(scale, selection_style, override)
    if type(override) == "number" and override >= 0 then
        return _round(override)
    end

    if selection_style == SELECTION_STYLE_BUTTON then
        return _scaled_int(scale, BASE_BUTTON_SIDE_MARGIN)
    end

    return 0
end

local LuiTabButton = class(Turbine.UI.Control)

function LuiTabButton:Constructor(owner)
    Turbine.UI.Control.Constructor(self)

    self._owner = owner
    self._text = ""
    self._selected = false
    self._enabled = true
    self._hover = false
    self._scale = 1

    self._text_normal = Style.ALTERNATE_FOREGROUND
    self._text_hover = Style.CONTROL_FOREGROUND_HOVER
    self._text_selected = Style.SELECTION_FOREGROUND
    self._text_disabled = Style.CONTROL_FOREGROUND_DISABLED

    self:SetMouseVisible(true)

    self._label = LuiLabel()
    self._label:SetParent(self)
    self._label:SetMouseVisible(false)
    self._label:SetSelectable(false)
    self._label:SetMultiline(false)
    self._label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        if self._enabled ~= true then
            return
        end
        self._hover = true
        self:_update_visual_state()
        if self._owner ~= nil then
            self._owner:_layout()
        end
    end

    self.MouseLeave = function()
        self._hover = false
        self:_update_visual_state()
        if self._owner ~= nil then
            self._owner:_layout()
        end
    end

    self.MouseClick = function(_, args)
        if self._enabled ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if self._owner ~= nil then
            self._owner:_button_clicked(self)
        end
    end
end

function LuiTabButton:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        return
    end

    self._scale = scale
    self:_layout()
end

function LuiTabButton:set_font(font)
    if font == nil then
        return
    end
    self._label:SetFont(font)
end

function LuiTabButton:set_text(text)
    self._text = tostring(text or "")
    self._label:SetText(self._text)
end

function LuiTabButton:is_hovered()
    return self._hover == true
end

function LuiTabButton:is_enabled()
    return self._enabled == true
end

function LuiTabButton:set_enabled(enabled)
    self._enabled = enabled == true
    if self._enabled ~= true then
        self._hover = false
    end
    Turbine.UI.Control.SetEnabled(self, self._enabled)
    self:_update_visual_state()
    if self._owner ~= nil then
        self._owner:_layout()
    end
end

function LuiTabButton:set_selected(selected)
    self._selected = selected == true
    self:_update_visual_state()
end

function LuiTabButton:set_theme(text_normal, text_hover, text_selected, text_disabled)
    if text_normal ~= nil then
        self._text_normal = text_normal
    end
    if text_hover ~= nil then
        self._text_hover = text_hover
    end
    if text_selected ~= nil then
        self._text_selected = text_selected
    end
    if text_disabled ~= nil then
        self._text_disabled = text_disabled
    end
    self:_update_visual_state()
end

function LuiTabButton:_current_text_color()
    if self._enabled ~= true then
        return self._text_disabled
    end
    if self._selected == true then
        return self._text_selected
    end
    if self._hover == true then
        return self._text_hover
    end
    return self._text_normal
end

function LuiTabButton:_update_visual_state()
    self._label:SetForeColor(self:_current_text_color())
end

function LuiTabButton:_layout()
    local w, h = self:GetSize()
    local label_pad = _scaled_int(self._scale, BASE_LABEL_PADDING_X)

    _set_rect(self._label, label_pad, 0, w - (label_pad * 2), h)

    self:_update_visual_state()
end

---@class LuiTabBar : Turbine.UI.Control
local LuiTabBar = class(Turbine.UI.Control)
Widgets.LuiTabBar = LuiTabBar

LuiTabBar.position = {
    top = POSITION_TOP,
    bottom = POSITION_BOTTOM,
    left = POSITION_LEFT,
    right = POSITION_RIGHT,
}

LuiTabBar.selection_style = {
    connected = SELECTION_STYLE_CONNECTED,
    button = SELECTION_STYLE_BUTTON,
}

function LuiTabBar:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.on_tab_changed = nil
    self.selection_changed = nil

    self._scale = 1
    self._uses_default_font = true
    self._position = POSITION_TOP
    self._fill_tabs = false
    self._side_tab_width_override = nil
    self._button_side_margin_override = nil
    self._button_content_gap_override = nil
    self._selection_style = SELECTION_STYLE_CONNECTED
    self._content_padding = BASE_CONTENT_PADDING
    self._show_border_top = true
    self._show_border_right = true
    self._show_border_bottom = true
    self._show_border_left = true
    self._show_tab_cap_top = true
    self._show_tab_cap_right = true
    self._show_tab_cap_bottom = true
    self._show_tab_cap_left = true
    self._selected_index = nil
    self._tabs = {}
    self._tab_rects = {}
    self._tab_natural_rects = {}
    self._horizontal_first_visible_index = 1
    self._horizontal_last_visible_index = 0
    self._horizontal_first_drawn_index = 1
    self._horizontal_last_fully_visible_index = 0
    self._horizontal_viewport_width = 0
    self._horizontal_viewport_offset_x = 0
    self._horizontal_scrollable = false
    self._horizontal_scroll_button_size = 0
    self._horizontal_scroll_button_gap = 0
    self._horizontal_follow_selected_once = false

    self._border_width = tonumber(Style.BORDER_WIDTH) or 1
    self._border_color = Style.CONTROL_BORDER
    self._content_border_color = self._border_color
    self._strip_back = Style.ALTERNATE_BACKGROUND
    self._content_back = Style.BACKGROUND
    self._hover_back = Style.CONTROL_BACKGROUND_HOVER
    self._selected_back = Style.SELECTION_BACKGROUND
    self._tab_text = Style.ALTERNATE_FOREGROUND
    self._tab_text_hover = Style.CONTROL_FOREGROUND_HOVER
    self._tab_text_selected = Style.SELECTION_FOREGROUND
    self._tab_text_disabled = Style.CONTROL_FOREGROUND_DISABLED

    self._strip_back_control = Turbine.UI.Control()
    self._strip_back_control:SetParent(self)
    self._strip_back_control:SetMouseVisible(false)
    self._strip_back_control:SetBackColor(self._strip_back)

    self._content_frame = Turbine.UI.Control()
    self._content_frame:SetParent(self)
    self._content_frame:SetMouseVisible(false)
    self._content_frame:SetBackColor(self._content_back)

    self._content_border_top = Turbine.UI.Control()
    self._content_border_top:SetParent(self._content_frame)
    self._content_border_top:SetMouseVisible(false)
    self._content_border_top:SetBackColor(self._border_color)

    self._content_border_right = Turbine.UI.Control()
    self._content_border_right:SetParent(self._content_frame)
    self._content_border_right:SetMouseVisible(false)
    self._content_border_right:SetBackColor(self._border_color)

    self._content_border_bottom = Turbine.UI.Control()
    self._content_border_bottom:SetParent(self._content_frame)
    self._content_border_bottom:SetMouseVisible(false)
    self._content_border_bottom:SetBackColor(self._border_color)

    self._content_border_left = Turbine.UI.Control()
    self._content_border_left:SetParent(self._content_frame)
    self._content_border_left:SetMouseVisible(false)
    self._content_border_left:SetBackColor(self._border_color)

    self._content_inner = Turbine.UI.Control()
    self._content_inner:SetParent(self._content_frame)
    self._content_inner:SetBackColor(self._content_back)

    self._tabs_fill_host = Turbine.UI.Control()
    self._tabs_fill_host:SetParent(self)
    self._tabs_fill_host:SetMouseVisible(false)
    self._tabs_fill_host:SetZOrder(4)

    self._tabs_host = Turbine.UI.Control()
    self._tabs_host:SetParent(self)
    self._tabs_host:SetZOrder(5)

    self._tabs_overlay_host = Turbine.UI.Control()
    self._tabs_overlay_host:SetParent(self)
    self._tabs_overlay_host:SetMouseVisible(false)
    self._tabs_overlay_host:SetZOrder(10)

    self._tab_fill_controls = {}
    self._tab_border_controls = {}
    self._divider_controls = {}

    self._adjacent_line_before = Turbine.UI.Control()
    self._adjacent_line_before:SetParent(self)
    self._adjacent_line_before:SetMouseVisible(false)
    self._adjacent_line_before:SetBackColor(self._border_color)
    self._adjacent_line_before:SetZOrder(10)

    self._adjacent_line_after = Turbine.UI.Control()
    self._adjacent_line_after:SetParent(self)
    self._adjacent_line_after:SetMouseVisible(false)
    self._adjacent_line_after:SetBackColor(self._border_color)
    self._adjacent_line_after:SetZOrder(10)

    self._selected_outline_top = Turbine.UI.Control()
    self._selected_outline_top:SetParent(self._tabs_overlay_host)
    self._selected_outline_top:SetMouseVisible(false)
    self._selected_outline_top:SetBackColor(self._border_color)
    self._selected_outline_top:SetZOrder(11)

    self._selected_outline_right = Turbine.UI.Control()
    self._selected_outline_right:SetParent(self._tabs_overlay_host)
    self._selected_outline_right:SetMouseVisible(false)
    self._selected_outline_right:SetBackColor(self._border_color)
    self._selected_outline_right:SetZOrder(11)

    self._selected_outline_bottom = Turbine.UI.Control()
    self._selected_outline_bottom:SetParent(self._tabs_overlay_host)
    self._selected_outline_bottom:SetMouseVisible(false)
    self._selected_outline_bottom:SetBackColor(self._border_color)
    self._selected_outline_bottom:SetZOrder(11)

    self._selected_outline_left = Turbine.UI.Control()
    self._selected_outline_left:SetParent(self._tabs_overlay_host)
    self._selected_outline_left:SetMouseVisible(false)
    self._selected_outline_left:SetBackColor(self._border_color)
    self._selected_outline_left:SetZOrder(11)

    self._scroll_left_button = LuiButton()
    self._scroll_left_button:SetParent(self)
    self._scroll_left_button:SetVisible(false)
    self._scroll_left_button:SetZOrder(12)
    self._scroll_left_button:set_text("")
    self._scroll_left_button:set_padding(2)
    Style.apply_transparent_button(self._scroll_left_button)
    self._scroll_left_button:set_icon(
        AssetIds.arrow_l_yellow_normal,
        AssetIds.arrow_l_yellow_inverted,
        AssetIds.arrow_l_yellow_dark,
        AssetIds.arrow_l_transparent,
        BASE_SCROLL_BUTTON_SIZE,
        nil,
        LuiButton.icon_position.LEFT
    )
    self._scroll_left_button.Click = function()
        self:_scroll_to_previous_hidden_tab()
    end

    self._scroll_right_button = LuiButton()
    self._scroll_right_button:SetParent(self)
    self._scroll_right_button:SetVisible(false)
    self._scroll_right_button:SetZOrder(12)
    self._scroll_right_button:set_text("")
    self._scroll_right_button:set_padding(2)
    Style.apply_transparent_button(self._scroll_right_button)
    self._scroll_right_button:set_icon(
        AssetIds.arrow_r_yellow_normal,
        AssetIds.arrow_r_yellow_inverted,
        AssetIds.arrow_r_yellow_dark,
        AssetIds.arrow_r_transparent,
        BASE_SCROLL_BUTTON_SIZE,
        nil,
        LuiButton.icon_position.RIGHT
    )
    self._scroll_right_button.Click = function()
        self:_scroll_to_next_hidden_tab()
    end

    self.SizeChanged = function()
        self:_layout()
    end

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_WIDGET_W), _scaled_int(self._scale, BASE_WIDGET_H))
    self:_apply_default_font()
    self:_layout()
end

function LuiTabBar:set_font(font)
    if font == nil then
        return
    end

    self._uses_default_font = false
    self._font = font
    for i = 1, #self._tabs do
        local button = self._tabs[i].button
        if button ~= nil then
            button:set_font(font)
        end
    end
    self:_layout()
end

function LuiTabBar:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        return
    end

    self._scale = scale
    if self._uses_default_font == true then
        self:_apply_default_font()
    end

    for i = 1, #self._tabs do
        local button = self._tabs[i].button
        if button ~= nil then
            button:set_scale(self._scale)
        end
    end

    self:_layout()
end

function LuiTabBar:get_scale()
    return self._scale
end

function LuiTabBar:set_tab_position(position)
    self._position = _normalize_position(position)
    self:_layout()
end

function LuiTabBar:get_tab_position()
    return self._position
end

function LuiTabBar:set_fill_tabs(fill_tabs)
    self._fill_tabs = fill_tabs == true
    self:_layout()
end

function LuiTabBar:get_fill_tabs()
    return self._fill_tabs == true
end

function LuiTabBar:set_selection_style(style)
    self._selection_style = _normalize_selection_style(style)
    self:_layout()
end

function LuiTabBar:set_side_tab_width(width)
    local value = tonumber(width)
    if value ~= nil and value > 0 then
        self._side_tab_width_override = _round(value)
    else
        self._side_tab_width_override = nil
    end
    self:_layout()
end

function LuiTabBar:set_button_side_margin(margin)
    local value = tonumber(margin)
    if value ~= nil and value >= 0 then
        self._button_side_margin_override = _round(value)
    else
        self._button_side_margin_override = nil
    end
    self:_layout()
end

function LuiTabBar:set_button_content_gap(gap)
    local value = tonumber(gap)
    if value ~= nil and value >= 0 then
        self._button_content_gap_override = _round(value)
    else
        self._button_content_gap_override = nil
    end
    self:_layout()
end

function LuiTabBar:set_content_padding(padding)
    if type(padding) ~= "number" then
        padding = tonumber(padding)
    end
    if padding == nil then
        return
    end

    if padding < 0 then
        padding = 0
    end

    self._content_padding = padding
    self:_layout()
end

function LuiTabBar:get_content_padding()
    return self._content_padding
end

function LuiTabBar:set_show_content_border(show_content_border)
    local show = _show_value(show_content_border)
    self._show_border_top = show
    self._show_border_right = show
    self._show_border_bottom = show
    self._show_border_left = show

    if show ~= true then
        if self._position == POSITION_TOP then
            self._show_border_top = true
        elseif self._position == POSITION_BOTTOM then
            self._show_border_bottom = true
        elseif self._position == POSITION_LEFT then
            self._show_border_left = true
        else
            self._show_border_right = true
        end
    end

    self:_layout()
end

function LuiTabBar:get_show_content_border()
    return self._show_border_top == true and self._show_border_right == true and self._show_border_bottom == true and
        self._show_border_left == true
end

function LuiTabBar:set_show_border_top(show)
    local value = _show_value(show)
    self._show_border_top = value
    self._show_tab_cap_top = value
    self:_layout()
end

function LuiTabBar:get_show_border_top()
    return self._show_border_top == true
end

function LuiTabBar:set_show_border_right(show)
    local value = _show_value(show)
    self._show_border_right = value
    self._show_tab_cap_right = value
    self:_layout()
end

function LuiTabBar:get_show_border_right()
    return self._show_border_right == true
end

function LuiTabBar:set_show_border_bottom(show)
    local value = _show_value(show)
    self._show_border_bottom = value
    self._show_tab_cap_bottom = value
    self:_layout()
end

function LuiTabBar:get_show_border_bottom()
    return self._show_border_bottom == true
end

function LuiTabBar:set_show_border_left(show)
    local value = _show_value(show)
    self._show_border_left = value
    self._show_tab_cap_left = value
    self:_layout()
end

function LuiTabBar:get_show_border_left()
    return self._show_border_left == true
end

-- tab-cap visibility independent of the content-frame borders (the border
-- setters above also flip the matching cap for backward compatibility)
function LuiTabBar:set_show_tab_cap_top(show)
    self._show_tab_cap_top = _show_value(show)
    self:_layout()
end

function LuiTabBar:set_show_tab_cap_right(show)
    self._show_tab_cap_right = _show_value(show)
    self:_layout()
end

function LuiTabBar:set_show_tab_cap_bottom(show)
    self._show_tab_cap_bottom = _show_value(show)
    self:_layout()
end

function LuiTabBar:set_show_tab_cap_left(show)
    self._show_tab_cap_left = _show_value(show)
    self:_layout()
end

function LuiTabBar:add_tab(text, widget)
    local entry = {}
    entry.text = tostring(text or "")
    entry.widget = widget or Turbine.UI.Control()

    entry.button = LuiTabButton(self)
    entry.button:SetParent(self._tabs_host)
    entry.button:set_scale(self._scale)
    entry.button:set_text(entry.text)
    entry.button:set_theme(
        self._tab_text,
        self._tab_text_hover,
        self._tab_text_selected,
        self._tab_text_disabled
    )
    entry.button:set_font(self._font)

    if entry.widget.SetParent ~= nil then
        entry.widget:SetParent(self._content_inner)
    end
    if entry.widget.SetVisible ~= nil then
        entry.widget:SetVisible(false)
    end

    self._tabs[#self._tabs + 1] = entry
    self:_layout()

    if self._selected_index == nil then
        self:set_selected_index(1, false)
    else
        self:_layout_selected_widget()
    end

    return #self._tabs
end

function LuiTabBar:widget_at(index)
    if type(index) ~= "number" then
        index = tonumber(index)
    end
    if index == nil then
        return nil
    end

    index = _round(index)
    local entry = self._tabs[index]
    return entry ~= nil and entry.widget or nil
end

function LuiTabBar:text_at(index)
    if type(index) ~= "number" then
        index = tonumber(index)
    end
    if index == nil then
        return nil
    end

    index = _round(index)
    local entry = self._tabs[index]
    return entry ~= nil and entry.text or nil
end

function LuiTabBar:each_widget(fn)
    if type(fn) ~= "function" then
        return
    end

    for i = 1, #self._tabs do
        local entry = self._tabs[i]
        fn(i, entry ~= nil and entry.widget or nil, entry ~= nil and entry.text or nil)
    end
end

function LuiTabBar:find_index(fn)
    if type(fn) ~= "function" then
        return nil
    end

    for i = 1, #self._tabs do
        local entry = self._tabs[i]
        local widget = entry ~= nil and entry.widget or nil
        local text = entry ~= nil and entry.text or nil
        if fn(i, widget, text) == true then
            return i, widget, text
        end
    end

    return nil
end

function LuiTabBar:get_selected_text()
    return self:text_at(self._selected_index)
end

function LuiTabBar:_emit_tab_changed(index)
    local entry = self._tabs[index]
    local widget = entry ~= nil and entry.widget or nil
    local text = entry ~= nil and entry.text or nil

    if type(self.on_tab_changed) == "function" then
        self.on_tab_changed(index, widget, text)
    end

    if type(self.selection_changed) == "function" then
        self:selection_changed(index, text, widget)
    end
end

function LuiTabBar:set_selected_index(index, fire_event)
    if type(index) ~= "number" then
        index = tonumber(index)
    end
    if index == nil then
        return
    end

    index = _round(index)
    if index < 1 or index > #self._tabs then
        return
    end

    if self._selected_index == index then
        self:_layout()
        return
    end

    self._selected_index = index
    self._horizontal_follow_selected_once = true

    for i = 1, #self._tabs do
        local entry = self._tabs[i]
        local selected = i == index
        if entry.button ~= nil then
            entry.button:set_selected(selected)
        end
        if entry.widget ~= nil and entry.widget.SetVisible ~= nil then
            entry.widget:SetVisible(selected)
        end
    end

    self:_layout()

    if fire_event ~= false then
        self:_emit_tab_changed(index)
    end
end

function LuiTabBar:select_tab(index)
    self:set_selected_index(index, true)
end

function LuiTabBar:get_selected_index()
    return self._selected_index
end

function LuiTabBar:get_selected_widget()
    local entry = self._selected_index ~= nil and self._tabs[self._selected_index] or nil
    return entry ~= nil and entry.widget or nil
end

function LuiTabBar:get_tab_count()
    return #self._tabs
end

function LuiTabBar:refresh_layout()
    self:_layout()
end

function LuiTabBar:_apply_default_font()
    self._font = _scaled_font(self._scale, Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE)
    for i = 1, #self._tabs do
        local button = self._tabs[i].button
        if button ~= nil then
            button:set_font(self._font)
        end
    end
end

function LuiTabBar:_ensure_divider_count(count)
    while #self._divider_controls < count do
        local c = Turbine.UI.Control()
        c:SetParent(self._tabs_overlay_host)
        c:SetMouseVisible(false)
        c:SetBackColor(self._border_color)
        c:SetZOrder(10)
        self._divider_controls[#self._divider_controls + 1] = c
    end

    for i = count + 1, #self._divider_controls do
        self._divider_controls[i]:SetVisible(false)
    end
end

function LuiTabBar:_ensure_tab_fill_count(count)
    while #self._tab_fill_controls < count do
        local c = Turbine.UI.Control()
        c:SetParent(self._tabs_fill_host)
        c:SetMouseVisible(false)
        c:SetZOrder(4)
        self._tab_fill_controls[#self._tab_fill_controls + 1] = c
    end

    for i = count + 1, #self._tab_fill_controls do
        self._tab_fill_controls[i]:SetVisible(false)
    end
end

function LuiTabBar:_ensure_tab_border_count(count)
    while #self._tab_border_controls < count do
        local borders = {}

        borders.top = Turbine.UI.Control()
        borders.top:SetParent(self._tabs_overlay_host)
        borders.top:SetMouseVisible(false)
        borders.top:SetZOrder(10)

        borders.right = Turbine.UI.Control()
        borders.right:SetParent(self._tabs_overlay_host)
        borders.right:SetMouseVisible(false)
        borders.right:SetZOrder(10)

        borders.bottom = Turbine.UI.Control()
        borders.bottom:SetParent(self._tabs_overlay_host)
        borders.bottom:SetMouseVisible(false)
        borders.bottom:SetZOrder(10)

        borders.left = Turbine.UI.Control()
        borders.left:SetParent(self._tabs_overlay_host)
        borders.left:SetMouseVisible(false)
        borders.left:SetZOrder(10)

        self._tab_border_controls[#self._tab_border_controls + 1] = borders
    end

    for i = count + 1, #self._tab_border_controls do
        local borders = self._tab_border_controls[i]
        borders.top:SetVisible(false)
        borders.right:SetVisible(false)
        borders.bottom:SetVisible(false)
        borders.left:SetVisible(false)
    end
end

function LuiTabBar:_button_clicked(button)
    for i = 1, #self._tabs do
        if self._tabs[i].button == button then
            self:set_selected_index(i, true)
            return
        end
    end
end

function LuiTabBar:_layout_selected_widget()
    local inner_w = self._content_inner:GetWidth()
    local inner_h = self._content_inner:GetHeight()
    local pad = _scaled_int(self._scale, self._content_padding)
    local x = pad
    local y = pad
    local w = inner_w - (pad * 2)
    local h = inner_h - (pad * 2)

    if w < 0 then w = 0 end
    if h < 0 then h = 0 end

    for i = 1, #self._tabs do
        local entry = self._tabs[i]
        if i == self._selected_index and entry ~= nil and entry.widget ~= nil then
            if entry.widget.SetPosition ~= nil then
                entry.widget:SetPosition(x, y)
            end
            if entry.widget.SetSize ~= nil then
                entry.widget:SetSize(w, h)
            end
        end
    end
end

function LuiTabBar:_compute_horizontal_scroll_button_size(height)
    return math.min(math.max(1, height), _scaled_int(self._scale, BASE_SCROLL_BUTTON_SIZE))
end

function LuiTabBar:_last_visible_horizontal_index(widths, start_index, viewport_width, gap)
    local count = #widths
    if count < 1 then
        return 0
    end

    if type(start_index) ~= "number" then
        start_index = tonumber(start_index) or 1
    end
    if type(viewport_width) ~= "number" then
        viewport_width = tonumber(viewport_width) or 0
    end

    start_index = _round(start_index)
    if start_index < 1 then
        start_index = 1
    elseif start_index > count then
        start_index = count
    end

    local used = 0
    local last_index = start_index

    for i = start_index, count do
        local tab_w = tonumber(widths[i]) or 0
        if tab_w < 1 then
            tab_w = 1
        end

        local extra = tab_w
        if i > start_index then
            extra = extra + gap
        end

        if i == start_index then
            used = tab_w
            last_index = i
        elseif (used + extra) <= viewport_width then
            used = used + extra
            last_index = i
        else
            break
        end

        if used >= viewport_width then
            break
        end
    end

    return last_index
end

function LuiTabBar:_sync_horizontal_visible_range(widths, viewport_width, gap)
    local count = #widths
    if count < 1 then
        self._horizontal_first_visible_index = 1
        self._horizontal_last_visible_index = 0
        self._horizontal_first_drawn_index = 1
        self._horizontal_last_fully_visible_index = 0
        return
    end

    local first_index = tonumber(self._horizontal_first_visible_index) or 1
    first_index = _round(first_index)
    if first_index < 1 then
        first_index = 1
    elseif first_index > count then
        first_index = count
    end

    local last_index = self:_last_visible_horizontal_index(widths, first_index, viewport_width, gap)
    local selected_index = self._selected_index
    local follow_selected = self._horizontal_follow_selected_once == true
    self._horizontal_follow_selected_once = false

    if follow_selected == true and type(selected_index) == "number" then
        selected_index = _round(selected_index)
        if selected_index < first_index then
            first_index = selected_index
            last_index = self:_last_visible_horizontal_index(widths, first_index, viewport_width, gap)
        else
            while selected_index > last_index and first_index < count do
                first_index = first_index + 1
                last_index = self:_last_visible_horizontal_index(widths, first_index, viewport_width, gap)
            end
        end
    end

    while last_index == count and first_index > 1 do
        local candidate_first = first_index - 1
        local candidate_last = self:_last_visible_horizontal_index(widths, candidate_first, viewport_width, gap)
        if candidate_last ~= count then
            break
        end
        first_index = candidate_first
        last_index = candidate_last
    end

    self._horizontal_first_visible_index = first_index
    self._horizontal_last_visible_index = last_index
    self._horizontal_first_drawn_index = first_index
    self._horizontal_last_fully_visible_index = last_index
end

function LuiTabBar:_scroll_to_previous_hidden_tab()
    if self._horizontal_scrollable ~= true then
        return
    end

    local first_index = tonumber(self._horizontal_first_visible_index) or 1
    if first_index <= 1 then
        return
    end

    self._horizontal_first_visible_index = first_index - 1
    self:_layout()
end

function LuiTabBar:_scroll_to_next_hidden_tab()
    if self._horizontal_scrollable ~= true then
        return
    end

    local count = #self._tabs
    local first_index = tonumber(self._horizontal_first_visible_index) or 1
    local last_index = tonumber(self._horizontal_last_fully_visible_index) or 0
    if last_index >= count then
        return
    end

    self._horizontal_first_visible_index = first_index + 1
    self:_layout()
end

function LuiTabBar:_layout_tabs_horizontal(width, height)
    local count = #self._tabs
    self._tab_rects = {}
    self._tab_natural_rects = {}
    if type(self._horizontal_first_visible_index) ~= "number" then
        self._horizontal_first_visible_index = 1
    else
        self._horizontal_first_visible_index = _round(self._horizontal_first_visible_index)
    end
    self._horizontal_last_visible_index = 0
    self._horizontal_first_drawn_index = 1
    self._horizontal_last_fully_visible_index = 0
    self._horizontal_viewport_width = width
    self._horizontal_viewport_offset_x = 0
    self._horizontal_scrollable = false
    self._horizontal_scroll_button_size = 0
    self._horizontal_scroll_button_gap = 0
    if count == 0 then
        return
    end

    local gap = _tab_gap(self._scale, self._selection_style)
    local min_tab_w = _scaled_int(self._scale, BASE_MIN_TAB_WIDTH)
    local widths = {}
    local total = 0

    for i = 1, count do
        local entry = self._tabs[i]
        local desired = math.max(min_tab_w, _approx_text_width(self._scale, entry ~= nil and entry.text or ""))
        widths[i] = desired
        total = total + desired
    end

    total = total + (math.max(0, count - 1) * gap)

    if self._fill_tabs == true then
        local usable = width - (math.max(0, count - 1) * gap)
        local tab_w = count > 0 and math.floor(usable / count) or 0
        if tab_w < 1 then
            tab_w = 1
        end
        for i = 1, count do
            widths[i] = tab_w
        end
    else
        local scrollable = total > width
        local viewport_width = width
        if scrollable == true then
            local button_gap = _scaled_int(self._scale, BASE_SCROLL_BUTTON_GAP)
            local button_size = self:_compute_horizontal_scroll_button_size(height)
            viewport_width = width - (button_size * 2) - (button_gap * 2)
            if viewport_width < 1 then
                viewport_width = 1
            end
            self._horizontal_scrollable = true
            self._horizontal_viewport_offset_x = button_size + button_gap
            self._horizontal_scroll_button_size = button_size
            self._horizontal_scroll_button_gap = button_gap
            self._horizontal_viewport_width = viewport_width
        end
    end

    if self._horizontal_scrollable ~= true then
        self._horizontal_viewport_width = width
    end

    if self._horizontal_scrollable == true then
        self:_sync_horizontal_visible_range(widths, self._horizontal_viewport_width, gap)
    else
        self._horizontal_first_visible_index = 1
        self._horizontal_last_visible_index = count
        self._horizontal_first_drawn_index = 1
        self._horizontal_last_fully_visible_index = count
    end

    local first_visible = self._horizontal_first_visible_index
    local first_drawn = first_visible
    local last_drawn = 0
    local last_fully_visible = 0
    local x = 0

    if self._horizontal_scrollable == true then
        local remaining_total = 0
        for i = first_visible, count do
            if i > first_visible then
                remaining_total = remaining_total + gap
            end
            remaining_total = remaining_total + widths[i]
        end

        if remaining_total < self._horizontal_viewport_width and first_visible > 1 then
            local missing = self._horizontal_viewport_width - remaining_total
            local probe = first_visible - 1

            while probe >= 1 do
                local extra = widths[probe] + gap
                if extra <= missing then
                    first_visible = probe
                    first_drawn = probe
                    missing = missing - extra
                    probe = probe - 1
                else
                    first_drawn = probe
                    x = -(extra - missing)
                    break
                end
            end
        end
    end

    for i = 1, count do
        local button = self._tabs[i].button
        local visible = false
        if i >= first_drawn then
            if x < self._horizontal_viewport_width then
                visible = true
            end
        end
        if visible == true then
            local tab_w = widths[i]
            self._tab_rects[i] = { x = x, y = 0, w = tab_w, h = height }
            if button ~= nil then
                button:SetVisible(true)
                _set_rect(button, x, 0, tab_w, height)
            end
            if x >= 0 and (x + tab_w) <= self._horizontal_viewport_width then
                last_fully_visible = i
            end
            last_drawn = i
            x = x + tab_w + gap
        else
            self._tab_rects[i] = nil
            if button ~= nil then
                button:SetVisible(false)
                _set_rect(button, 0, 0, 0, 0)
            end
        end
    end

    self._horizontal_first_visible_index = first_visible
    self._horizontal_first_drawn_index = first_drawn
    self._horizontal_last_visible_index = last_drawn
    self._horizontal_last_fully_visible_index = last_fully_visible
end

function LuiTabBar:_layout_tabs_vertical(width, height)
    local count = #self._tabs
    self._tab_rects = {}
    if count == 0 then
        return
    end

    local gap = _tab_gap(self._scale, self._selection_style)
    local side_margin = _button_side_margin(self._scale, self._selection_style, self._button_side_margin_override)
    local tab_h = _scaled_int(self._scale, BASE_SIDE_TAB_HEIGHT)
    local total = (count * tab_h) + (math.max(0, count - 1) * gap)
    if total > height then
        local usable = height - (math.max(0, count - 1) * gap)
        tab_h = count > 0 and math.floor(usable / count) or 0
        if tab_h < 1 then
            tab_h = 1
        end
    end

    local y = 0
    for i = 1, count do
        local button = self._tabs[i].button
        self._tab_rects[i] = { x = side_margin, y = y, w = width - (side_margin * 2), h = tab_h }
        if button ~= nil then
            button:SetVisible(true)
            _set_rect(button, side_margin, y, width - (side_margin * 2), tab_h)
        end
        y = y + tab_h + gap
    end
end

function LuiTabBar:_layout_button_borders(border)
    local count = #self._tabs
    self:_ensure_tab_border_count(count)

    if self._selection_style ~= SELECTION_STYLE_BUTTON then
        for i = 1, #self._tab_border_controls do
            local borders = self._tab_border_controls[i]
            borders.top:SetVisible(false)
            borders.right:SetVisible(false)
            borders.bottom:SetVisible(false)
            borders.left:SetVisible(false)
        end
        return
    end

    local rects = self._tab_rects or {}
    for i = 1, count do
        local rect = rects[i]
        local borders = self._tab_border_controls[i]
        if rect ~= nil then
            _set_rect(borders.top, rect.x, rect.y, rect.w, border)
            _set_rect(borders.right, rect.x + rect.w - border, rect.y, border, rect.h)
            _set_rect(borders.bottom, rect.x, rect.y + rect.h - border, rect.w, border)
            _set_rect(borders.left, rect.x, rect.y, border, rect.h)

            borders.top:SetBackColor(self._border_color)
            borders.right:SetBackColor(self._border_color)
            borders.bottom:SetBackColor(self._border_color)
            borders.left:SetBackColor(self._border_color)

            borders.top:SetVisible(true)
            borders.right:SetVisible(true)
            borders.bottom:SetVisible(true)
            borders.left:SetVisible(true)
        else
            borders.top:SetVisible(false)
            borders.right:SetVisible(false)
            borders.bottom:SetVisible(false)
            borders.left:SetVisible(false)
        end
    end
end

function LuiTabBar:_desired_side_strip_width()
    if type(self._side_tab_width_override) == "number" and self._side_tab_width_override > 0 then
        return self._side_tab_width_override
    end

    local width = _scaled_int(self._scale, BASE_SIDE_TAB_WIDTH)
    for i = 1, #self._tabs do
        local entry = self._tabs[i]
        local desired = _approx_text_width(self._scale, entry ~= nil and entry.text or "")
        if desired > width then
            width = desired
        end
    end
    return width
end

function LuiTabBar:_layout_strip_overlays(strip_x, strip_y, strip_w, strip_h, content_x, content_y, content_w, content_h,
                                          border, show_adjacent_border)
    local count = #self._tabs
    local rects = self._tab_rects or {}
    local divider_count = math.max(0, count - 1)
    local selected_index = self._selected_index
    local show_tab_cap_top = self._show_tab_cap_top == true
    local show_tab_cap_right = self._show_tab_cap_right == true
    local show_tab_cap_bottom = self._show_tab_cap_bottom == true
    local show_tab_cap_left = self._show_tab_cap_left == true
    local visible_first_index = self._horizontal_scrollable == true and self._horizontal_first_drawn_index or 1
    local visible_last_index = self._horizontal_scrollable == true and self._horizontal_last_visible_index or count
    self:_ensure_divider_count(divider_count)

    for i = 1, divider_count do
        local divider = self._divider_controls[i]
        local rect = rects[i]
        local show_divider = self._selection_style ~= SELECTION_STYLE_BUTTON and selected_index ~= nil and
            (i == selected_index or i == (selected_index - 1))

        if divider ~= nil and rect ~= nil and show_divider == true then
            if self._position == POSITION_TOP or self._position == POSITION_BOTTOM then
                local boundary = rect.x + rect.w
                _set_rect(divider, boundary - math.floor(border / 2), 0, border, strip_h)
            else
                local boundary = rect.y + rect.h
                _set_rect(divider, 0, boundary - math.floor(border / 2), strip_w, border)
            end
            divider:SetBackColor(self._border_color)
            divider:SetVisible(true)
        elseif divider ~= nil then
            divider:SetVisible(false)
        end
    end

    self._adjacent_line_before:SetVisible(false)
    self._adjacent_line_after:SetVisible(false)
    self._selected_outline_top:SetVisible(false)
    self._selected_outline_right:SetVisible(false)
    self._selected_outline_bottom:SetVisible(false)
    self._selected_outline_left:SetVisible(false)

    local selected_rect = self._selected_index ~= nil and rects[self._selected_index] or nil
    local selected_x = nil
    local selected_y = nil
    local selected_w = nil
    local selected_h = nil
    local selected_abs_x = nil
    local selected_abs_y = nil
    if selected_rect ~= nil then
        selected_x = selected_rect.x
        selected_y = selected_rect.y
        selected_w = selected_rect.w
        selected_h = selected_rect.h
        selected_abs_x = strip_x + selected_x
        selected_abs_y = strip_y + selected_y
    end

    if self._selection_style == SELECTION_STYLE_BUTTON then
        return
    end

    if show_adjacent_border == true then
        if self._position == POSITION_TOP then
            local line_y = content_y
            local before_w = selected_rect ~= nil and math.max(0, selected_abs_x - content_x) or content_w
            local after_x = selected_rect ~= nil and (selected_abs_x + selected_w) or (content_x + content_w)
            local after_w = math.max(0, (content_x + content_w) - after_x)
            _set_rect(self._adjacent_line_before, content_x, line_y, before_w, border)
            _set_rect(self._adjacent_line_after, after_x, line_y, after_w, border)
        elseif self._position == POSITION_BOTTOM then
            local line_y = content_y + content_h - border
            local before_w = selected_rect ~= nil and math.max(0, selected_abs_x - content_x) or content_w
            local after_x = selected_rect ~= nil and (selected_abs_x + selected_w) or (content_x + content_w)
            local after_w = math.max(0, (content_x + content_w) - after_x)
            _set_rect(self._adjacent_line_before, content_x, line_y, before_w, border)
            _set_rect(self._adjacent_line_after, after_x, line_y, after_w, border)
        elseif self._position == POSITION_LEFT then
            local line_x = content_x
            local before_h = selected_rect ~= nil and math.max(0, selected_abs_y - content_y) or content_h
            local after_y = selected_rect ~= nil and (selected_abs_y + selected_h) or (content_y + content_h)
            local after_h = math.max(0, (content_y + content_h) - after_y)
            _set_rect(self._adjacent_line_before, line_x, content_y, border, before_h)
            _set_rect(self._adjacent_line_after, line_x, after_y, border, after_h)
        else
            local line_x = content_x + content_w - border
            local before_h = selected_rect ~= nil and math.max(0, selected_abs_y - content_y) or content_h
            local after_y = selected_rect ~= nil and (selected_abs_y + selected_h) or (content_y + content_h)
            local after_h = math.max(0, (content_y + content_h) - after_y)
            _set_rect(self._adjacent_line_before, line_x, content_y, border, before_h)
            _set_rect(self._adjacent_line_after, line_x, after_y, border, after_h)
        end

        self._adjacent_line_before:SetBackColor(self._border_color)
        self._adjacent_line_after:SetBackColor(self._border_color)
        self._adjacent_line_before:SetVisible(self._adjacent_line_before:GetWidth() > 0 and self._adjacent_line_before:GetHeight() > 0)
        self._adjacent_line_after:SetVisible(self._adjacent_line_after:GetWidth() > 0 and self._adjacent_line_after:GetHeight() > 0)
    end

    if selected_rect == nil then
        return
    end

    if self._position == POSITION_TOP then
        if show_tab_cap_top == true then
            _set_rect(self._selected_outline_top, selected_x, selected_y, selected_w, border)
            self._selected_outline_top:SetVisible(true)
        end
        if selected_index == visible_first_index and show_tab_cap_left == true then
            _set_rect(self._selected_outline_left, selected_x, selected_y, border, selected_h)
            self._selected_outline_left:SetVisible(true)
        end
        if selected_index == visible_last_index and show_tab_cap_right == true then
            _set_rect(self._selected_outline_right, selected_x + selected_w - border, selected_y, border, selected_h)
            self._selected_outline_right:SetVisible(true)
        end
    elseif self._position == POSITION_BOTTOM then
        if show_tab_cap_bottom == true then
            _set_rect(self._selected_outline_bottom, selected_x, selected_y + selected_h - border, selected_w, border)
            self._selected_outline_bottom:SetVisible(true)
        end
        if selected_index == visible_first_index and show_tab_cap_left == true then
            _set_rect(self._selected_outline_left, selected_x, selected_y, border, selected_h)
            self._selected_outline_left:SetVisible(true)
        end
        if selected_index == visible_last_index and show_tab_cap_right == true then
            _set_rect(self._selected_outline_right, selected_x + selected_w - border, selected_y, border, selected_h)
            self._selected_outline_right:SetVisible(true)
        end
    elseif self._position == POSITION_LEFT then
        if show_tab_cap_left == true then
            _set_rect(self._selected_outline_left, selected_x, selected_y, border, selected_h)
            self._selected_outline_left:SetVisible(true)
        end
        if selected_index == visible_first_index and show_tab_cap_top == true then
            _set_rect(self._selected_outline_top, selected_x, selected_y, selected_w, border)
            self._selected_outline_top:SetVisible(true)
        end
        if selected_index == visible_last_index and show_tab_cap_bottom == true then
            _set_rect(self._selected_outline_bottom, selected_x, selected_y + selected_h - border, selected_w, border)
            self._selected_outline_bottom:SetVisible(true)
        end
    else
        if show_tab_cap_right == true then
            _set_rect(self._selected_outline_right, selected_x + selected_w - border, selected_y, border, selected_h)
            self._selected_outline_right:SetVisible(true)
        end
        if selected_index == visible_first_index and show_tab_cap_top == true then
            _set_rect(self._selected_outline_top, selected_x, selected_y, selected_w, border)
            self._selected_outline_top:SetVisible(true)
        end
        if selected_index == visible_last_index and show_tab_cap_bottom == true then
            _set_rect(self._selected_outline_bottom, selected_x, selected_y + selected_h - border, selected_w, border)
            self._selected_outline_bottom:SetVisible(true)
        end
    end

    self._selected_outline_top:SetBackColor(self._border_color)
    self._selected_outline_right:SetBackColor(self._border_color)
    self._selected_outline_bottom:SetBackColor(self._border_color)
    self._selected_outline_left:SetBackColor(self._border_color)
end

function LuiTabBar:_layout_tab_fills(strip_x, strip_y)
    local count = #self._tabs
    local rects = self._tab_rects or {}
    self:_ensure_tab_fill_count(count)

    for i = 1, count do
        local fill = self._tab_fill_controls[i]
        local entry = self._tabs[i]
        local rect = rects[i]
        local button = entry ~= nil and entry.button or nil
        local hovered = button ~= nil and button:is_hovered() == true
        local selected = i == self._selected_index
        local enabled = button == nil or button:is_enabled() == true
        local show_fill = selected == true or (enabled == true and hovered == true)

        if fill ~= nil and rect ~= nil and show_fill == true then
            _set_rect(fill, rect.x, rect.y, rect.w, rect.h)
            if selected == true then
                if self._selection_style == SELECTION_STYLE_BUTTON then
                    fill:SetBackColor(self._selected_back)
                else
                    fill:SetBackColor(self._content_back)
                end
            else
                fill:SetBackColor(self._hover_back)
            end
            fill:SetVisible(true)
        elseif fill ~= nil then
            fill:SetVisible(false)
        end
    end
end

function LuiTabBar:_layout()
    local width, height = self:GetSize()
    local border = math.max(1, _scaled_int(self._scale, self._border_width or tonumber(Style.BORDER_WIDTH) or 1))
    local horizontal_strip = _scaled_int(self._scale, BASE_TAB_HEIGHT)
    local vertical_strip = self:_desired_side_strip_width()
    local show_border_top = self._show_border_top == true
    local show_border_right = self._show_border_right == true
    local show_border_bottom = self._show_border_bottom == true
    local show_border_left = self._show_border_left == true
    local show_adjacent_border = false

    local strip_x = 0
    local strip_y = 0
    local strip_w = width
    local strip_h = horizontal_strip

    local content_x = 0
    local content_y = 0
    local content_w = width
    local content_h = height
    local button_style = self._selection_style == SELECTION_STYLE_BUTTON
    local button_content_gap = 0
    if button_style == true and type(self._button_content_gap_override) == "number" and self._button_content_gap_override > 0 then
        button_content_gap = self._button_content_gap_override
    end

    if self._position == POSITION_TOP then
        strip_h = math.min(height, horizontal_strip)
        if show_border_top == true then
            if button_style == true then
                content_y = strip_h + button_content_gap
            else
                content_y = math.max(0, strip_h - border)
                show_adjacent_border = true
            end
        else
            content_y = strip_h + button_content_gap
        end
        content_h = math.max(0, height - content_y)
    elseif self._position == POSITION_BOTTOM then
        strip_h = math.min(height, horizontal_strip)
        strip_y = math.max(0, height - strip_h)
        if show_border_bottom == true then
            if button_style == true then
                content_h = math.max(0, height - strip_h - button_content_gap)
            else
                content_h = math.max(0, height - strip_h + border)
                show_adjacent_border = true
            end
        else
            content_h = math.max(0, height - strip_h - button_content_gap)
        end
    elseif self._position == POSITION_LEFT then
        strip_w = math.min(width, vertical_strip)
        strip_h = height
        if show_border_left == true then
            if button_style == true then
                content_x = strip_w + button_content_gap
            else
                content_x = math.max(0, strip_w - border)
                show_adjacent_border = true
            end
        else
            content_x = strip_w + button_content_gap
        end
        content_w = math.max(0, width - content_x)
    else
        strip_w = math.min(width, vertical_strip)
        strip_h = height
        strip_x = math.max(0, width - strip_w)
        if show_border_right == true then
            if button_style == true then
                content_w = math.max(0, width - strip_w - button_content_gap)
            else
                content_w = math.max(0, width - strip_w + border)
                show_adjacent_border = true
            end
        else
            content_w = math.max(0, width - strip_w - button_content_gap)
        end
    end

    local tabs_x = strip_x
    local tabs_y = strip_y
    local tabs_w = strip_w
    local tabs_h = strip_h

    local inset_top = show_border_top == true and border or 0
    local inset_right = show_border_right == true and border or 0
    local inset_bottom = show_border_bottom == true and border or 0
    local inset_left = show_border_left == true and border or 0

    _set_rect(self._strip_back_control, strip_x, strip_y, strip_w, strip_h)
    _set_rect(self._content_frame, content_x, content_y, content_w, content_h)
    _set_rect(self._content_border_top, 0, 0, content_w, border)
    _set_rect(self._content_border_right, content_w - border, 0, border, content_h)
    _set_rect(self._content_border_bottom, 0, content_h - border, content_w, border)
    _set_rect(self._content_border_left, 0, 0, border, content_h)
    _set_rect(
        self._content_inner,
        inset_left,
        inset_top,
        content_w - inset_left - inset_right,
        content_h - inset_top - inset_bottom
    )

    self._strip_back_control:SetBackColor(self._strip_back)
    self._content_frame:SetBackColor(self._content_back)
    self._content_border_top:SetBackColor(self._content_border_color)
    self._content_border_right:SetBackColor(self._content_border_color)
    self._content_border_bottom:SetBackColor(self._content_border_color)
    self._content_border_left:SetBackColor(self._content_border_color)
    self._content_border_top:SetVisible(show_border_top and (button_style == true or self._position ~= POSITION_TOP))
    self._content_border_right:SetVisible(show_border_right and (button_style == true or self._position ~= POSITION_RIGHT))
    self._content_border_bottom:SetVisible(show_border_bottom and (button_style == true or self._position ~= POSITION_BOTTOM))
    self._content_border_left:SetVisible(show_border_left and (button_style == true or self._position ~= POSITION_LEFT))
    self._content_inner:SetBackColor(self._content_back)

    if self._position == POSITION_TOP or self._position == POSITION_BOTTOM then
        self:_layout_tabs_horizontal(strip_w, strip_h)
        tabs_x = strip_x + (self._horizontal_viewport_offset_x or 0)
        tabs_w = math.max(0, self._horizontal_viewport_width or strip_w)
    else
        self:_layout_tabs_vertical(strip_w, strip_h)
    end

    _set_rect(self._tabs_fill_host, tabs_x, tabs_y, tabs_w, tabs_h)
    _set_rect(self._tabs_host, tabs_x, tabs_y, tabs_w, tabs_h)
    _set_rect(self._tabs_overlay_host, tabs_x, tabs_y, tabs_w, tabs_h)

    local show_horizontal_scroll = self._position ~= POSITION_LEFT and self._position ~= POSITION_RIGHT and
        self._horizontal_scrollable == true
    if show_horizontal_scroll == true then
        local button_size = self._horizontal_scroll_button_size or 0
        local left_y = strip_y + math.floor((strip_h - button_size) / 2)
        local right_x = strip_x + strip_w - button_size
        _set_rect(self._scroll_left_button, strip_x, left_y, button_size, button_size)
        _set_rect(self._scroll_right_button, right_x, left_y, button_size, button_size)
        self._scroll_left_button:set_enabled((self._horizontal_first_visible_index or 1) > 1)
        self._scroll_right_button:set_enabled((self._horizontal_last_fully_visible_index or 0) < #self._tabs)
        self._scroll_left_button:SetVisible(true)
        self._scroll_right_button:SetVisible(true)
    else
        self._scroll_left_button:set_enabled(false)
        self._scroll_right_button:set_enabled(false)
        self._scroll_left_button:SetVisible(false)
        self._scroll_right_button:SetVisible(false)
    end

    self:_layout_tab_fills(tabs_x, tabs_y)
    self:_layout_button_borders(border)
    self:_layout_strip_overlays(tabs_x, tabs_y, tabs_w, tabs_h, content_x, content_y, content_w, content_h, border,
        show_adjacent_border)
    self:_layout_selected_widget()
end
