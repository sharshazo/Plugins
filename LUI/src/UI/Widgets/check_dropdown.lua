-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.native_scaling"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.checkbox"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local LuiButton = Widgets.LuiButton
local LuiCheckBox = Widgets.LuiCheckBox
local Style = Widgets.Style
local BASE_ITEM_H = 18
local BASE_ARROW_W = 13
local BASE_DROPDOWN_W = 119
local BASE_DROPDOWN_H = 21
local BASE_OPEN_GAP = 1
local BASE_EDGE_PAD = 4
local BASE_FLIP_GAP = 4
local BASE_SCROLL_W = 10
local BASE_POPUP_PAD_X = 2
local BASE_VISIBLE_PAD = 2
local BASE_VISIBLE_ITEM_GAP = 2
local BASE_RIGHT_EXTRA_PAD = 2
local BASE_CHECKBOX_ICON_SIZE = 16

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _copy_array(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    for i = 1, #source do
        out[#out + 1] = source[i]
    end
    return out
end

---@class LuiCheckDropdown : Turbine.UI.Control
local LuiCheckDropdown = class(Turbine.UI.Control)
Widgets.LuiCheckDropdown = LuiCheckDropdown

function LuiCheckDropdown:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._uses_default_size = true
    self._enabled = true
    self._popup_host = nil
    self._popup_overlay = nil
    self._labels = {}
    self._values = {}
    self._selected = {}
    self._items = {}
    self._rows = {}
    self._item_font = nil
    self._item_height = _scaled_int(self._scale, BASE_ITEM_H)
    self._max_visible = 10
    self._summary_formatter = nil
    self._suppress_item_changed = false

    self.SelectedValuesChanged = nil

    self.button = LuiButton()
    self.button:SetParent(self)
    self.button:set_scale(self._scale)
    self.button:set_padding(BASE_POPUP_PAD_X)
    self.button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleLeft)
    -- native-size arrow (stretch mode 0) only at scale 1.0, where it is
    -- pixel-perfect; mode 0 ignores the layout size, so at any other scale
    -- the arrow must stretch to the scaled slot or it stays tiny on 4K
    self.button:set_icon_stretch_mode(self._scale == 1 and 0 or nil)
    Style.apply_dropdown_arrow(self.button, BASE_ARROW_W, LuiButton.icon_position.RIGHT)
    self.button.Click = function()
        self:Toggle()
    end

    self.popup = Turbine.UI.Window()
    UI.NativeScaling.apply_window(self.popup)
    self.popup:SetVisible(false)
    self.popup:SetZOrder(3000)
    self.popup:SetMouseVisible(true)
    self.popup:SetBackColor(Style.CONTROL_BORDER)
    self.popup:SetWantsKeyEvents(true)
    self.popup.KeyDown = function(_, args)
        if args ~= nil and args.Action ~= nil and args.Action == Turbine.UI.Lotro.Action.Escape then
            self:Close()
        end
    end
    self.popup.FocusLost = function()
        if self._popup_host == nil then
            self:Close()
        end
    end

    self.popup_inner = Turbine.UI.Control()
    self.popup_inner:SetParent(self.popup)
    self.popup_inner:SetBackColor(Style.BACKGROUND)

    self.popup_list = Turbine.UI.ListBox()
    self.popup_list:SetParent(self.popup_inner)
    self.popup_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.popup_scroll = Turbine.UI.Lotro.ScrollBar()
    self.popup_scroll:SetParent(self.popup_inner)
    self.popup_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.popup_scroll:SetWidth(BASE_SCROLL_W)
    self.popup_list:SetVerticalScrollBar(self.popup_scroll)

    self.SizeChanged = function()
        self.button:SetSize(self:GetSize())
    end

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_DROPDOWN_W), _scaled_int(self._scale, BASE_DROPDOWN_H))
    self.button:SetSize(self:GetSize())
    self:_refresh_summary()
end

function LuiCheckDropdown:_popup_border_size()
    return math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH) or 1))
end

function LuiCheckDropdown:Close()
    if self._popup_overlay ~= nil then
        self._popup_overlay:SetVisible(false)
        self._popup_overlay = nil
    end

    if self.popup ~= nil then
        self.popup:SetVisible(false)
    end

    if LuiCheckDropdown._active == self then
        LuiCheckDropdown._active = nil
    end
end

function LuiCheckDropdown:SetFont(font)
    self._item_font = font
    if self.button ~= nil then
        self.button:set_font(font)
    end
    for i = 1, #self._items do
        if self._items[i] ~= nil then
            self._items[i]:SetFont(font)
        end
    end
end

function LuiCheckDropdown:set_scale(scale)
    self._scale = tonumber(scale) or 1
    self._item_height = _scaled_int(self._scale, BASE_ITEM_H)

    if self.button ~= nil then
        self.button:set_scale(self._scale)
        self.button:set_padding(BASE_POPUP_PAD_X)
        -- see Constructor: pixel-perfect native arrow at 1.0 only
        self.button:set_icon_stretch_mode(self._scale == 1 and 0 or nil)
        Style.apply_dropdown_arrow(self.button, BASE_ARROW_W, LuiButton.icon_position.RIGHT)
    end
    for i = 1, #self._items do
        if self._items[i] ~= nil then
            self._items[i]:set_scale(self._scale)
        end
    end

    if self._uses_default_size == true then
        Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_DROPDOWN_W), _scaled_int(self._scale, BASE_DROPDOWN_H))
    end

    if self.popup ~= nil and self.popup:IsVisible() == true then
        self:Close()
    end
end

function LuiCheckDropdown:SetTextAlignment(alignment)
    if self.button ~= nil then
        self.button:set_text_alignment(alignment)
    end
end

function LuiCheckDropdown:SetPopupHost(host_window)
    self._popup_host = host_window
end

function LuiCheckDropdown:SetEnabled(enabled)
    self._enabled = enabled == true
    self.button:set_enabled(self._enabled)
    if self._enabled ~= true then
        self:Close()
    end
end

function LuiCheckDropdown:SetSummaryFormatter(formatter)
    self._summary_formatter = type(formatter) == "function" and formatter or nil
    self:_refresh_summary()
end

function LuiCheckDropdown:SetMappedOptions(labels, values)
    self:set_mapped_options(labels, values)
end

function LuiCheckDropdown:set_mapped_options(labels, values)
    self._labels = _copy_array(labels)
    self._values = _copy_array(values)
    if #self._labels ~= #self._values then
        self._labels = {}
        self._values = {}
    end

    local valid = {}
    for i = 1, #self._values do
        valid[self._values[i]] = true
    end
    for value, _ in pairs(self._selected) do
        if valid[value] ~= true then
            self._selected[value] = nil
        end
    end

    self:_rebuild_items()
    self:_sync_items()
    self:_refresh_summary()
end

function LuiCheckDropdown:SetSelectedValues(values, fire_event)
    self:set_selected_values(values, fire_event)
end

function LuiCheckDropdown:set_selected_values(values, fire_event)
    local next_selected = {}
    if type(values) == "table" then
        for i = 1, #values do
            next_selected[values[i]] = true
        end
    end

    local changed = false
    for i = 1, #self._values do
        local value = self._values[i]
        local selected = next_selected[value] == true
        if (self._selected[value] == true) ~= selected then
            changed = true
        end
        self._selected[value] = selected and true or nil
    end

    self:_sync_items()
    self:_refresh_summary()

    if fire_event == true and changed == true and type(self.SelectedValuesChanged) == "function" then
        self:SelectedValuesChanged(self:GetSelectedValues())
    end
end

function LuiCheckDropdown:GetSelectedValues()
    local out = {}
    for i = 1, #self._values do
        local value = self._values[i]
        if self._selected[value] == true then
            out[#out + 1] = value
        end
    end
    return out
end

function LuiCheckDropdown:IsValueSelected(value)
    return self._selected[value] == true
end

function LuiCheckDropdown:Open()
    if self._enabled ~= true then return end
    if self.popup:IsVisible() then return end

    local item_count = #self._items
    if item_count == 0 then
        return
    end

    if Widgets.LuiDropdown._active ~= nil then
        Widgets.LuiDropdown._active:Close()
    end
    if LuiCheckDropdown._active ~= nil and LuiCheckDropdown._active ~= self then
        LuiCheckDropdown._active:Close()
    end
    LuiCheckDropdown._active = self

    local x, y = self.button:PointToScreen(0, self.button:GetHeight() + _scaled_int(self._scale, BASE_OPEN_GAP))
    local width = self.button:GetWidth()
    local visible_count = math.min(item_count, self._max_visible)
    local border = self:_popup_border_size()
    local inner_width = math.max(0, width - (2 * border))
    local use_scroll = item_count > visible_count
    local scroll_w = BASE_SCROLL_W
    local pad_x = _scaled_int(self._scale, BASE_POPUP_PAD_X)
    local visible_pad = _scaled_int(self._scale, BASE_VISIBLE_PAD)
    local visible_gap = _scaled_int(self._scale, BASE_VISIBLE_ITEM_GAP)
    local right_pad = pad_x + _scaled_int(self._scale, BASE_RIGHT_EXTRA_PAD)
    local checkbox_icon_h = math.min(self._item_height, _scaled_int(self._scale, BASE_CHECKBOX_ICON_SIZE))
    local checkbox_inner_y = math.max(0, math.floor(((self._item_height - checkbox_icon_h) / 2) + 0.5))
    local pad_y = math.max(0, visible_pad - checkbox_inner_y)
    local row_gap = math.max(0, visible_gap - (checkbox_inner_y * 2))
    local list_height = (visible_count * self._item_height) + (math.max(0, visible_count - 1) * row_gap)

    self.popup:SetSize(width, list_height + (2 * pad_y) + (2 * border))
    self.popup_inner:SetPosition(border, border)
    self.popup_inner:SetSize(inner_width, list_height + (2 * pad_y))

    self.popup_list:SetPosition(pad_x, pad_y)
    self.popup_list:SetSize(math.max(0, inner_width - pad_x - right_pad - (use_scroll and scroll_w or 0)), list_height)

    self.popup_scroll:SetPosition(pad_x + self.popup_list:GetWidth(), pad_y)
    self.popup_scroll:SetHeight(list_height)
    self.popup_scroll:SetVisible(use_scroll)

    for i = 1, item_count do
        local row = self._rows[i]
        local checkbox = self._items[i]
        if row ~= nil then
            local item_gap = (i < item_count) and row_gap or 0
            row:SetSize(self.popup_list:GetWidth(), self._item_height + item_gap)
        end
        if checkbox ~= nil then
            checkbox:SetPosition(0, 0)
            checkbox:SetSize(self.popup_list:GetWidth(), self._item_height)
        end
    end

    local display_width, display_height = Turbine.UI.Display.GetSize()
    if x + self.popup:GetWidth() > display_width then
        x = display_width - self.popup:GetWidth() - _scaled_int(self._scale, BASE_EDGE_PAD)
    end
    if y + self.popup:GetHeight() > display_height then
        y = y - self.popup:GetHeight() - self.button:GetHeight() - _scaled_int(self._scale, BASE_FLIP_GAP)
    end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    UI.NativeScaling.apply_window(self.popup)
    self.popup:SetPosition(x, y)

    if self._popup_host ~= nil then
        local host = self._popup_host
        local overlay = Turbine.UI.Control()
        overlay:SetParent(host)
        overlay:SetPosition(0, 0)
        overlay:SetSize(host:GetWidth(), host:GetHeight())
        overlay:SetMouseVisible(true)
        overlay:SetZOrder(9999)
        overlay:SetVisible(true)
        overlay.MouseDown = function(_, args)
            local cx = args ~= nil and args.X or nil
            local cy = args ~= nil and args.Y or nil
            if type(cx) == "number" and type(cy) == "number" then
                local host_sx, host_sy = host:PointToScreen(0, 0)
                local popup_x, popup_y = self.popup:GetPosition()
                local rel_x = popup_x - host_sx
                local rel_y = popup_y - host_sy
                local popup_w, popup_h = self.popup:GetSize()
                if cx >= rel_x and cx <= (rel_x + popup_w) and cy >= rel_y and cy <= (rel_y + popup_h) then
                    return
                end
            end
            self:Close()
        end
        self._popup_overlay = overlay
    end

    self.popup:SetVisible(true)
end

function LuiCheckDropdown:Toggle()
    if self.popup:IsVisible() then
        self:Close()
    else
        self:Open()
    end
end

function LuiCheckDropdown:_set_value_selected(value, selected, fire_event)
    local next_selected = selected == true
    if (self._selected[value] == true) == next_selected then
        return
    end

    self._selected[value] = next_selected and true or nil
    self:_refresh_summary()

    if fire_event == true and type(self.SelectedValuesChanged) == "function" then
        self:SelectedValuesChanged(self:GetSelectedValues())
    end
end

function LuiCheckDropdown:_rebuild_items()
    self.popup_list:ClearItems()
    self._items = {}
    self._rows = {}

    for i = 1, #self._labels do
        local row = Turbine.UI.Control()
        row:SetMouseVisible(false)

        local checkbox = LuiCheckBox()
        checkbox:SetParent(row)
        checkbox:set_scale(self._scale)
        checkbox:SetText(tostring(self._labels[i]))
        checkbox:SetForeColor(Style.CONTROL_FOREGROUND)
        if self._item_font ~= nil then
            checkbox:SetFont(self._item_font)
        end
        checkbox.CheckedChanged = function()
            if self._suppress_item_changed == true then
                return
            end
            self:_set_value_selected(self._values[i], checkbox:IsChecked() == true, true)
        end
        self.popup_list:AddItem(row)
        self._rows[#self._rows + 1] = row
        self._items[#self._items + 1] = checkbox
    end
end

function LuiCheckDropdown:_sync_items()
    self._suppress_item_changed = true
    for i = 1, #self._items do
        local checkbox = self._items[i]
        if checkbox ~= nil then
            checkbox:SetChecked(self._selected[self._values[i]] == true)
        end
    end
    self._suppress_item_changed = false
end

function LuiCheckDropdown:_refresh_summary()
    local selected_values = self:GetSelectedValues()
    local text = nil
    if self._summary_formatter ~= nil then
        text = self._summary_formatter(selected_values, self._labels, self._values)
    end

    if text == nil then
        if #selected_values == 0 then
            text = TR["None"]
        elseif #selected_values == #self._values then
            text = TR["All"]
        elseif #selected_values == 1 then
            for i = 1, #self._values do
                if self._values[i] == selected_values[1] then
                    text = tostring(self._labels[i])
                    break
                end
            end
        else
            text = tostring(#selected_values) .. " selected"
        end
    end

    self.button:set_text(text or "")
end

function LuiCheckDropdown:SetSize(w, h)
    self._uses_default_size = false
    Turbine.UI.Control.SetSize(self, w, h)
end

UI.Widgets.LuiCheckDropdown = LuiCheckDropdown
