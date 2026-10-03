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
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local LuiButton = Widgets.LuiButton
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

local function _scaled_size(scale, value)
    return value * scale
end

local function _scaled_int(scale, value)
    return math.floor(_scaled_size(scale, value) + 0.5)
end

---@class LuiDropdown : Turbine.UI.Control
local LuiDropdown = class(Turbine.UI.Control)
Widgets.LuiDropdown = LuiDropdown

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function LuiDropdown:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._uses_default_size = true
    self._enabled = true
    self._index = nil
    self._value = nil
    self._popup_host = nil
    self._popup_overlay = nil

    self._labels = {}
    self._values = {}

    self._popup_border = tonumber(Style.BORDER_WIDTH) or 1
    self._popup_border_color = Style.CONTROL_BORDER
    self._popup_back_color = Style.BACKGROUND

    self._item_height = _scaled_int(self._scale, BASE_ITEM_H)
    self._max_visible = 10
    self._item_font = nil

    self.ValueChanged = nil

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
    self.popup:SetBackColor(self._popup_border_color)
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
    local initial_border = self:_popup_border_size()
    self.popup_inner:SetPosition(initial_border, initial_border)
    self.popup_inner:SetBackColor(self._popup_back_color)

    self.popup_list = Turbine.UI.ListBox()
    self.popup_list:SetParent(self.popup_inner)
    self.popup_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.popup_scroll = Turbine.UI.Lotro.ScrollBar()
    self.popup_scroll:SetParent(self.popup_inner)
    self.popup_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.popup_scroll:SetWidth(BASE_SCROLL_W)
    self.popup_list:SetVerticalScrollBar(self.popup_scroll)

    self._items = {}

    self.SizeChanged = function()
        self.button:SetSize(self:GetSize())
    end

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_DROPDOWN_W), _scaled_int(self._scale, BASE_DROPDOWN_H))
    self.button:SetSize(self:GetSize())
end

function LuiDropdown:_popup_border_size()
    return math.max(1, _scaled_int(self._scale, self._popup_border or tonumber(Style.BORDER_WIDTH) or 1))
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

function LuiDropdown:Close()
    if self._popup_overlay ~= nil then
        self._popup_overlay:SetVisible(false)
        self._popup_overlay = nil
    end

    if self.popup ~= nil then
        self.popup:SetVisible(false)
    end

    if LuiDropdown._active == self then
        LuiDropdown._active = nil
    end
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function LuiDropdown:SetFont(font)
    self._item_font = font
    if self.button ~= nil then
        self.button:set_font(font)
    end
    for i = 1, #self._items do
        local b = self._items[i]
        if b ~= nil then
            b:set_font(font)
        end
    end
end

function LuiDropdown:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
    self._item_height = _scaled_int(self._scale, BASE_ITEM_H)

    if self.button ~= nil then
        self.button:set_scale(self._scale)
        self.button:set_padding(BASE_POPUP_PAD_X)
        -- see Constructor: pixel-perfect native arrow at 1.0 only
        self.button:set_icon_stretch_mode(self._scale == 1 and 0 or nil)
        Style.apply_dropdown_arrow(self.button, BASE_ARROW_W, LuiButton.icon_position.RIGHT)
    end

    for i = 1, #self._items do
        local b = self._items[i]
        if b ~= nil then
            b:set_scale(self._scale)
        end
    end

    if self._uses_default_size == true then
        Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_DROPDOWN_W), _scaled_int(self._scale, BASE_DROPDOWN_H))
    end

    if self.popup ~= nil and self.popup:IsVisible() == true then
        self:Close()
    end
end

function LuiDropdown:SetTextAlignment(alignment)
    if self.button ~= nil then
        self.button:set_text_alignment(alignment)
    end
end

function LuiDropdown:SetPopupHost(host_window)
    self._popup_host = host_window
end

function LuiDropdown:SetEnabled(enabled)
    self._enabled = enabled == true
    self.button:set_enabled(self._enabled)
    if self._enabled ~= true then
        self:Close()
    end
end

function LuiDropdown:GetValue()
    return self._value
end

function LuiDropdown:GetIndex()
    return self._index
end

function LuiDropdown:get_value()
    return self._value
end

function LuiDropdown:get_index()
    return self._index
end

function LuiDropdown:SetValue(value)
    self:set_value(value)
end

function LuiDropdown:set_value(value)
    local found = nil
    for i = 1, #self._values do
        if self._values[i] == value then
            found = i
            break
        end
    end
    self:_set_index(found, true)
end

function LuiDropdown:set_mapped_options(labels, values)
    self._labels = labels or {}
    self._values = values or {}

    if #self._labels ~= #self._values then
        self._labels = {}
        self._values = {}
    end

    self:_rebuild_items()

    if #self._labels == 0 then
        self:_set_index(nil)
        return
    end

    if self._value ~= nil then
        for i = 1, #self._values do
            if self._values[i] == self._value then
                self:_set_index(i)
                return
            end
        end
    end

    self:_set_index(1)
end

function LuiDropdown:SetMappedOptions(labels, values)
    self:set_mapped_options(labels, values)
end

function LuiDropdown:set_dropdown_options(labels, values)
    self:set_mapped_options(labels, values)
end

function LuiDropdown:SetDropdownOptions(labels, values)
    self:set_mapped_options(labels, values)
end

function LuiDropdown:Open()
    if self._enabled ~= true then return end
    if self.popup:IsVisible() then return end

    local item_count = #self._items
    if item_count == 0 then
        return
    end

    if Widgets.LuiCheckDropdown._active ~= nil then
        Widgets.LuiCheckDropdown._active:Close()
    end
    if LuiDropdown._active ~= nil and LuiDropdown._active ~= self then
        LuiDropdown._active:Close()
    end
    LuiDropdown._active = self

    local x, y = self.button:PointToScreen(0, self.button:GetHeight() + _scaled_int(self._scale, BASE_OPEN_GAP))
    local width = self.button:GetWidth()

    local visible_count = item_count
    if visible_count > self._max_visible then
        visible_count = self._max_visible
    end

    local border = self:_popup_border_size()
    local inner_width = math.max(0, width - (2 * border))
    local scroll_w = BASE_SCROLL_W
    local use_scroll = item_count > visible_count
    local list_height = visible_count * self._item_height

    self.popup:SetSize(width, list_height + (2 * border))
    self.popup_inner:SetSize(inner_width, list_height)

    self.popup_list:SetPosition(0, 0)
    self.popup_list:SetSize(math.max(0, inner_width - (use_scroll and scroll_w or 0)), list_height)

    self.popup_scroll:SetPosition(self.popup_list:GetWidth(), 0)
    self.popup_scroll:SetHeight(list_height)
    self.popup_scroll:SetVisible(use_scroll)

    for i = 1, item_count do
        local b = self._items[i]
        if b ~= nil then
            b:SetSize(self.popup_list:GetWidth(), self._item_height)
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
    self.popup_inner:SetPosition(border, border)

    self:_sync_active_items()

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

function LuiDropdown:Toggle()
    if self.popup:IsVisible() then
        self:Close()
    else
        self:Open()
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function LuiDropdown:_set_index(index, fire_event)
    local previous_index = self._index
    local previous_value = self._value

    if type(index) ~= "number" then
        index = nil
    else
        index = math.floor(index)
        if index < 1 or index > #self._labels then
            index = nil
        end
    end

    self._index = index
    self._value = (index ~= nil) and self._values[index] or nil

    local t = (index ~= nil) and tostring(self._labels[index]) or ""
    if string.len(t) == 0 then
        t = TR["Select"]
    end
    self.button:set_text(t)
    self:_sync_active_items()

    if fire_event == true and previous_index == self._index and previous_value == self._value then
        return
    end
    if fire_event == true and type(self.ValueChanged) == "function" then
        self:ValueChanged(self._value)
    end
end

function LuiDropdown:_rebuild_items()
    self.popup_list:ClearItems()
    self._items = {}

    for i = 1, #self._labels do
        local opt = self._labels[i]
        local b = LuiButton()
        b:set_scale(self._scale)
        b:set_border_thickness(0)
        b:set_padding(BASE_POPUP_PAD_X)
        b:set_text_alignment(Turbine.UI.ContentAlignment.MiddleLeft)
        b:set_text(tostring(opt))
        if self._item_font ~= nil then
            b:set_font(self._item_font)
        end
        b.Click = function()
            self:_set_index(i, true)
            self:Close()
        end
        self.popup_list:AddItem(b)
        table.insert(self._items, b)
    end
end

function LuiDropdown:_sync_active_items()
    for i = 1, #self._labels do
        local b = self._items[i]
        if b ~= nil then
            b:set_active(i == self._index)
        end
    end
end

function LuiDropdown:SetSize(w, h)
    self._uses_default_size = false
    Turbine.UI.Control.SetSize(self, w, h)
end
