-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local StatusBar = _G.LUI.Features.StatusBar
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

local S = _G.LUI.Features.StatusBar.Common
local Style = UI.Widgets.Style

local WINDOW_W = 300
local WINDOW_H = 338
local WINDOW_MARGIN = 18
local WINDOW_HEADER_H = 20
local PAD_X = 14
local PAD_Y = 8
local TOP_CONTENT_PAD = 6
local BOTTOM_CONTENT_PAD = 2
local HINT_H = 38
local NOTE_H = 28
local ROW_H = 22
local ROW_GAP = 4
local BUTTON_W = 84
local BUTTON_H = 21
local LIST_SCROLL_W = 10
local LIST_SCROLL_GAP = 4

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * State.settings.global.scale)
end

local function _clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local EditBarPaletteEntry = class(Turbine.UI.Control)

function EditBarPaletteEntry:Constructor(palette_entry, on_mouse_down, on_mouse_move, on_mouse_up)
    Turbine.UI.Control.Constructor(self)

    self.palette_entry = palette_entry or {}
    self.widget_key = self.palette_entry.widget_key
    self._available = true
    self._hover = false
    self._on_mouse_down = on_mouse_down
    self._on_mouse_move = on_mouse_move
    self._on_mouse_up = on_mouse_up

    self:SetMouseVisible(true)
    self:SetBackColor(Style.PANEL_INNER_BACKGROUND)

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self)
    self.title:SetMouseVisible(false)
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.title:SetForeColor(Style.FOREGROUND)
    self.title:SetText(self.palette_entry.title or S.get_status_bar_widget_display_name(self.widget_key))

    self.status = UI.Widgets.LuiLabel()
    self.status:SetParent(self)
    self.status:SetMouseVisible(false)
    self.status:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.status:SetForeColor(Style.INFO_FOREGROUND)
    self.status:SetText("")

    self.border_top = Turbine.UI.Control()
    self.border_top:SetParent(self)
    self.border_top:SetMouseVisible(false)
    self.border_top:SetBackColor(Style.CONTROL_BORDER)

    self.border_bottom = Turbine.UI.Control()
    self.border_bottom:SetParent(self)
    self.border_bottom:SetMouseVisible(false)
    self.border_bottom:SetBackColor(Style.CONTROL_BORDER)

    self.border_left = Turbine.UI.Control()
    self.border_left:SetParent(self)
    self.border_left:SetMouseVisible(false)
    self.border_left:SetBackColor(Style.CONTROL_BORDER)

    self.border_right = Turbine.UI.Control()
    self.border_right:SetParent(self)
    self.border_right:SetMouseVisible(false)
    self.border_right:SetBackColor(Style.CONTROL_BORDER)

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        self._hover = true
        self:_update_visual_state()
    end

    self.MouseLeave = function()
        self._hover = false
        self:_update_visual_state()
    end

    self.MouseDown = function(_, args)
        if self._available ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if type(self._on_mouse_down) == "function" then
            self._on_mouse_down(self.palette_entry, self, args)
        end
    end

    self.MouseMove = function(_, args)
        if self._available ~= true then
            return
        end
        if type(self._on_mouse_move) == "function" then
            self._on_mouse_move(self.palette_entry, self, args)
        end
    end

    self.MouseUp = function(_, args)
        if self._available ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if type(self._on_mouse_up) == "function" then
            self._on_mouse_up(self.palette_entry, self, args)
        end
    end

    self:apply_scale()
    self:_layout()
    self:_update_visual_state()
end

function EditBarPaletteEntry:apply_scale()
    self.title:SetFont(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 1))
    self.status:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
end

function EditBarPaletteEntry:set_available(available)
    self._available = available == true
    self.status:SetText(self._available == true and "" or TR["On bar"])
    self:_update_visual_state()
end

function EditBarPaletteEntry:_layout()
    local w, h = self:GetSize()
    local border = math.min(1, h)
    local pad = _scaled_int(8)
    local status_w = _scaled_int(54)

    self.border_top:SetPosition(0, 0)
    self.border_top:SetSize(w, border)
    self.border_bottom:SetPosition(0, math.max(0, h - border))
    self.border_bottom:SetSize(w, border)
    self.border_left:SetPosition(0, 0)
    self.border_left:SetSize(border, h)
    self.border_right:SetPosition(math.max(0, w - border), 0)
    self.border_right:SetSize(border, h)

    self.status:SetPosition(math.max(0, w - pad - status_w), 0)
    self.status:SetSize(status_w, h)
    self.title:SetPosition(pad, 0)
    self.title:SetSize(math.max(0, w - (2 * pad) - status_w), h)
end

function EditBarPaletteEntry:_update_visual_state()
    if self._available ~= true then
        self:SetBackColor(Style.CONTROL_BACKGROUND_DISABLED)
        self.title:SetForeColor(Style.FOREGROUND_DISABLED)
        return
    end

    self.title:SetForeColor(Style.FOREGROUND)
    if self._hover == true then
        self:SetBackColor(Style.CONTROL_BACKGROUND_HOVER)
    else
        self:SetBackColor(Style.PANEL_INNER_BACKGROUND)
    end
end

local StatusBarEditWindow = class(UI.Widgets.LuiBaseWindow)
StatusBar.StatusBarEditWindow = StatusBarEditWindow

function StatusBarEditWindow:Constructor(owner)
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })

    self.owner = owner
    self.entries = {}
    self._destroying = false
    self._dragging = false
    self._drag_start_screen_x = nil
    self._drag_start_screen_y = nil
    self._drag_start_window_x = nil
    self._drag_start_window_y = nil

    self:SetVisible(false)
    self:SetMouseVisible(true)
    self:SetZOrder(3000)
    self:SetBackColor(Style.BACKGROUND)

    self.border_top = Turbine.UI.Control()
    self.border_top:SetParent(self)
    self.border_top:SetMouseVisible(false)
    self.border_top:SetBackColor(Style.CONTROL_BORDER)

    self.border_bottom = Turbine.UI.Control()
    self.border_bottom:SetParent(self)
    self.border_bottom:SetMouseVisible(false)
    self.border_bottom:SetBackColor(Style.CONTROL_BORDER)

    self.border_left = Turbine.UI.Control()
    self.border_left:SetParent(self)
    self.border_left:SetMouseVisible(false)
    self.border_left:SetBackColor(Style.CONTROL_BORDER)

    self.border_right = Turbine.UI.Control()
    self.border_right:SetParent(self)
    self.border_right:SetMouseVisible(false)
    self.border_right:SetBackColor(Style.CONTROL_BORDER)

    self.header = Turbine.UI.Control()
    self.header:SetParent(self)
    self.header:SetMouseVisible(true)
    self.header:SetBackColor(Style.CONTROL_BACKGROUND)

    self.header_divider = Turbine.UI.Control()
    self.header_divider:SetParent(self)
    self.header_divider:SetMouseVisible(false)
    self.header_divider:SetBackColor(Style.CONTROL_BORDER)

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self.header)
    self.title:SetMouseVisible(false)
    self.title:SetMultiline(false)
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.title:SetForeColor(Style.FOREGROUND)
    self.title:SetFont(_scaled_font(Style.WINDOW_TITLE_FONT_NAME, Style.WINDOW_TITLE_FONT_SIZE))
    self.title:SetText(TR["Edit Bar"])

    self.hint = UI.Widgets.LuiLabel()
    self.hint:SetParent(self)
    self.hint:SetSelectable(false)
    self.hint:SetMultiline(true)
    self.hint:SetMouseVisible(false)
    self.hint:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.hint:SetForeColor(Style.FOREGROUND)
    self.hint:SetText(TR["Drag entries onto the status bar. Drag an existing bar item outside the bar to remove it."])

    self.note = UI.Widgets.LuiLabel()
    self.note:SetParent(self)
    self.note:SetSelectable(false)
    self.note:SetMultiline(true)
    self.note:SetMouseVisible(false)
    self.note:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.note:SetForeColor(Style.INFO_FOREGROUND)
    self.note:SetText(TR["Tracked inventory items are still added by dragging them from the inventory window."])

    self.rows_list = Turbine.UI.ListBox()
    self.rows_list:SetParent(self)
    self.rows_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.rows_scroll = Turbine.UI.Lotro.ScrollBar()
    self.rows_scroll:SetParent(self)
    self.rows_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.rows_scroll:SetWidth(LIST_SCROLL_W)
    self.rows_list:SetVerticalScrollBar(self.rows_scroll)

    self.rows_content = Turbine.UI.Control()
    self.rows_content:SetMouseVisible(false)
    self.rows_list:AddItem(self.rows_content)

    self.done_button = UI.Widgets.LuiButton()
    self.done_button:SetParent(self)
    self.done_button:set_text(TR["Done"])
    self.done_button.Click = function()
        self:close_manually()
    end

    self.SizeChanged = function()
        self:layout()
    end

    local function begin_drag(args)
        if args == nil or args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._dragging = true
        self._drag_start_screen_x, self._drag_start_screen_y = self.header:PointToScreen(args.X, args.Y)
        self._drag_start_window_x, self._drag_start_window_y = self:GetPosition()
    end

    local function move_drag(args)
        if self._dragging ~= true or args == nil then
            return
        end
        local sx, sy = self.header:PointToScreen(args.X, args.Y)
        local dx = sx - self._drag_start_screen_x
        local dy = sy - self._drag_start_screen_y
        self:_set_clamped_position(self._drag_start_window_x + dx, self._drag_start_window_y + dy)
    end

    local function end_drag(args)
        if args == nil or args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._dragging = false
    end

    self.header.MouseDown = function(_, args)
        begin_drag(args)
    end
    self.header.MouseMove = function(_, args)
        move_drag(args)
    end
    self.header.MouseUp = function(_, args)
        end_drag(args)
    end
    self.MouseMove = function(_, args)
        move_drag(args)
    end
    self.MouseUp = function(_, args)
        end_drag(args)
    end

    self:_rebuild_entries()
    self:apply_scale()
end

function StatusBarEditWindow:_create_palette_entry_row(palette_entry)
    local row = EditBarPaletteEntry(palette_entry,
    function(entry, sender, args)
        if self.owner ~= nil and self.owner.arm_palette_drag ~= nil then
            self.owner:arm_palette_drag(entry, sender, args)
        end
    end,
    function(entry, sender, args)
        if self.owner ~= nil and self.owner.handle_palette_drag_move ~= nil then
            self.owner:handle_palette_drag_move(entry, sender, args)
        end
    end,
    function(entry, sender, args)
        if self.owner ~= nil and self.owner.handle_palette_drag_release ~= nil then
            self.owner:handle_palette_drag_release(entry, sender, args)
        end
    end)
    row:SetParent(self.rows_content)
    return row
end

function StatusBarEditWindow:_rebuild_entries()
    for i = 1, #self.entries do
        local row = self.entries[i]
        if row ~= nil then
            row:SetParent(nil)
        end
    end
    self.entries = {}

    local palette_entries = S.get_status_bar_edit_palette_entries()
    for i = 1, #palette_entries do
        self.entries[#self.entries + 1] = self:_create_palette_entry_row(palette_entries[i])
    end
end

function StatusBarEditWindow:apply_scale()
    self:SetSize(_scaled_int(WINDOW_W), _scaled_int(WINDOW_H))
    self.title:SetFont(_scaled_font(Style.WINDOW_TITLE_FONT_NAME, Style.WINDOW_TITLE_FONT_SIZE))
    self.title:SetText(TR["Edit Bar"])
    self.hint:SetFont(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 1))
    self.note:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.done_button:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE))
    self.done_button:SetSize(_scaled_int(BUTTON_W), _scaled_int(BUTTON_H))

    for i = 1, #self.entries do
        self.entries[i]:apply_scale()
        self.entries[i]:SetHeight(_scaled_int(ROW_H))
    end

    self:layout()
end

function StatusBarEditWindow:layout()
    local w, h = self:GetSize()
    local border = 1
    local header_h = _scaled_int(WINDOW_HEADER_H)
    local pad_x = _scaled_int(PAD_X)
    local pad_y = _scaled_int(PAD_Y)
    local title_pad = _scaled_int(4)
    local hint_h = _scaled_int(HINT_H)
    local note_h = _scaled_int(NOTE_H)
    local row_gap = _scaled_int(ROW_GAP)
    local top_content_pad = _scaled_int(TOP_CONTENT_PAD)
    local bottom_content_pad = _scaled_int(BOTTOM_CONTENT_PAD)
    local scroll_w = LIST_SCROLL_W
    local scroll_gap = _scaled_int(LIST_SCROLL_GAP)
    local button_w = self.done_button:GetWidth()
    local button_h = self.done_button:GetHeight()
    local content_top = header_h + border
    local rows_top = content_top + pad_y + top_content_pad + hint_h + _scaled_int(4) + note_h + _scaled_int(6)
    local rows_w = math.max(0, w - (2 * pad_x))
    local rows_h = math.max(0, h - rows_top - pad_y - bottom_content_pad - button_h - _scaled_int(6))
    local row_h = _scaled_int(ROW_H)
    local content_h = 0
    if #self.entries > 0 then
        content_h = (#self.entries * row_h) + ((#self.entries - 1) * row_gap)
    end
    local use_scroll = content_h > rows_h
    local rows_list_w = rows_w
    if use_scroll == true then
        rows_list_w = math.max(1, rows_w - scroll_gap - scroll_w)
    end

    self.border_top:SetPosition(0, 0)
    self.border_top:SetSize(w, border)
    self.border_bottom:SetPosition(0, math.max(0, h - border))
    self.border_bottom:SetSize(w, border)
    self.border_left:SetPosition(0, 0)
    self.border_left:SetSize(border, h)
    self.border_right:SetPosition(math.max(0, w - border), 0)
    self.border_right:SetSize(border, h)

    self.header:SetPosition(border, border)
    self.header:SetSize(math.max(0, w - (2 * border)), math.max(0, header_h - border))
    self.header_divider:SetPosition(0, header_h)
    self.header_divider:SetSize(w, border)
    self.title:SetPosition(title_pad, 0)
    self.title:SetSize(math.max(0, self.header:GetWidth() - (2 * title_pad)), self.header:GetHeight())

    self.hint:SetPosition(pad_x, content_top + pad_y + top_content_pad)
    self.hint:SetSize(rows_w, hint_h)

    self.note:SetPosition(pad_x, content_top + pad_y + top_content_pad + hint_h + _scaled_int(4))
    self.note:SetSize(rows_w, note_h)

    self.rows_list:SetPosition(pad_x, rows_top)
    self.rows_list:SetSize(rows_list_w, rows_h)
    self.rows_content:SetSize(rows_list_w, math.max(rows_h, content_h))

    self.rows_scroll:SetWidth(scroll_w)
    self.rows_scroll:SetPosition(pad_x + rows_list_w + scroll_gap, rows_top)
    self.rows_scroll:SetHeight(rows_h)
    self.rows_scroll:SetVisible(use_scroll == true)

    local row_y = 0
    for i = 1, #self.entries do
        local row = self.entries[i]
        row:SetPosition(0, row_y)
        row:SetSize(rows_list_w, row_h)
        row_y = row_y + row:GetHeight() + row_gap
    end

    self.done_button:SetPosition(w - pad_x - button_w, h - pad_y - bottom_content_pad - button_h)
end

function StatusBarEditWindow:refresh_state()
    self:_rebuild_entries()
    local owner = self.owner
    for i = 1, #self.entries do
        local row = self.entries[i]
        local available = true
        if owner ~= nil and owner.is_palette_entry_available ~= nil then
            available = owner:is_palette_entry_available(row.palette_entry)
        elseif owner ~= nil and owner.is_palette_widget_available ~= nil then
            available = owner:is_palette_widget_available(row.widget_key)
        end
        row:set_available(available)
    end
    self:apply_scale()
end

function StatusBarEditWindow:open()
    self:refresh_state()
    self:position_near_bar()
    self:SetVisible(true)
    self:Activate()
end

function StatusBarEditWindow:close_manually()
    self:SetVisible(false)
end

function StatusBarEditWindow:set_owner(owner)
    self.owner = owner
    if self:IsVisible() == true and owner ~= nil then
        self:position_near_bar()
    end
end

function StatusBarEditWindow:_set_clamped_position(left, top)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local w, h = self:GetSize()
    local clamped_left = _clamp(left, WINDOW_MARGIN, math.max(WINDOW_MARGIN, display_w - w - WINDOW_MARGIN))
    local clamped_top = _clamp(top, WINDOW_MARGIN, math.max(WINDOW_MARGIN, display_h - h - WINDOW_MARGIN))
    self:SetPosition(clamped_left, clamped_top)
end

function StatusBarEditWindow:position_near_bar()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local w, h = self:GetSize()
    local left = math.floor((display_w - w) / 2)
    local top = _scaled_int(36)

    if self.owner ~= nil and self.owner.GetHeight ~= nil then
        top = self.owner:GetHeight() + _scaled_int(18)
    end

    self:_set_clamped_position(left, top)
end

function StatusBarEditWindow:destroy()
    self._destroying = true
    self._dragging = false
    self:SetVisible(false)
    if self.rows_list ~= nil and self.rows_list.ClearItems ~= nil then
        self.rows_list:ClearItems()
    end
    for i = 1, #self.entries do
        if self.entries[i] ~= nil then
            self.entries[i]:SetParent(nil)
        end
    end
    if self.title ~= nil then self.title:SetParent(nil) end
    if self.header_divider ~= nil then self.header_divider:SetParent(nil) end
    if self.header ~= nil then self.header:SetParent(nil) end
    if self.border_top ~= nil then self.border_top:SetParent(nil) end
    if self.border_bottom ~= nil then self.border_bottom:SetParent(nil) end
    if self.border_left ~= nil then self.border_left:SetParent(nil) end
    if self.border_right ~= nil then self.border_right:SetParent(nil) end
    if self.hint ~= nil then self.hint:SetParent(nil) end
    if self.note ~= nil then self.note:SetParent(nil) end
    if self.rows_content ~= nil and self.rows_content.SetVisible ~= nil then self.rows_content:SetVisible(false) end
    if self.rows_scroll ~= nil then self.rows_scroll:SetParent(nil) end
    if self.rows_list ~= nil then self.rows_list:SetParent(nil) end
    if self.done_button ~= nil then self.done_button:SetParent(nil) end
end
