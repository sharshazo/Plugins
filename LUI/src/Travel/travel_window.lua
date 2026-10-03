-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local Defaults = _G.LUI.Settings.Defaults
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Travel = _G.LUI.Features.Travel
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

-- (2026-09-30, actualizacion 49.6) el juego pide AttachEdges en los
-- controles con modo de estirado; None = tamano fijo. Sin 49.6, no hace nada.
local function _attach_fixed_edges(control)
    local EA = Turbine.UI.EdgeAttachmentType
    if EA ~= nil and control ~= nil and control.AttachEdges ~= nil then
        pcall(control.AttachEdges, control, EA.None, EA.None, EA.None, EA.None)
    end
end

-- (2026-09-30, 49.6) con estirado activo el juego ignora SetSize salvo que
-- el tamano maximo/minimo del control lo acompanen (probado en el juego,
-- ver UI/Widgets/image.lua). Sin la 49.6 es un SetSize normal.
local function _fit_stretched(control, w, h)
    if control ~= nil and control.SetMaximumSize ~= nil then
        pcall(control.SetMinimumSize, control, 1, 1)
        pcall(control.SetMaximumSize, control, math.max(1, math.floor(w + 0.5)), math.max(1, math.floor(h + 0.5)))
    end
    control:SetSize(w, h)
end

local TravelWindow = class(UI.Widgets.LuiWindow)
Travel.TravelWindow = TravelWindow

local Style = UI.Widgets.Style
local BASE_MARGIN = 6
local BASE_GAP = 6
local BASE_EMPTY_FONT = 12
local BASE_LIST_ICON = 36
local BASE_GRID_ICON = 36
local BASE_LIST_ROW_H = 34
local BASE_SCROLL_W = 10
local BASE_MIN_W = 260
local BASE_MIN_H = 220
local DISPLAY_MODE_LIST = "list"
local DISPLAY_MODE_GRID = "grid"
local REFRESH_INTERVAL = 2
local RESIZE_LEFT = 1

local function _ui_scale()
    return UI.NativeScaling.get_ui_scale()
end

local function _scaled_int(value)
    return UI.NativeScaling.scaled_ui_int(value)
end

local function _scaled_font(size)
    return FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, size * _ui_scale())
end

local function _apply_body_label_style(label, size)
    label:SetFont(_scaled_font(size))
    label:SetOutlineColor(Style.TEXT_OUTLINE)
    label:SetForeColor(Style.ALTERNATE_FOREGROUND)
end

local function _has_resize_dir(mask, dir)
    return math.floor((mask or 0) / dir) % 2 == 1
end

local function _configure_quickslot(slot, shortcut)
    slot:SetAllowDrop(false)
    slot:SetUseOnRightClick(false)
    slot:SetShortcut(shortcut)
end

local function _measure_quickslot_size(slot, fallback_w, fallback_h)
    local old_w, old_h = slot:GetSize()
    slot:SetStretchMode(2)
    local raw_w, raw_h = slot:GetSize()
    slot:SetSize(old_w, old_h)
    slot:SetStretchMode(0)

    local measured_w = tonumber(raw_w)
    local measured_h = tonumber(raw_h)

    local width = math.floor((measured_w or fallback_w or 0) + 0.5)
    local height = math.floor((measured_h or fallback_h or 0) + 0.5)
    if width <= 0 then
        width = fallback_w or 0
    end
    if height <= 0 then
        height = fallback_h or 0
    end

    return width, height
end

local function _release_quickslot(slot)
    if slot == nil then
        return
    end
    slot:SetVisible(false)
    slot:SetShortcut(nil)
    slot:SetParent(nil)
end

local function _clear_list_box(list)
    if list == nil then
        return
    end

    if list.GetItemCount ~= nil and list.GetItem ~= nil then
        for i = 1, list:GetItemCount() do
            local item = list:GetItem(i)
            if item ~= nil and item.prepare_for_list_clear ~= nil then
                item:prepare_for_list_clear()
            elseif item ~= nil and item.SetVisible ~= nil then
                item:SetVisible(false)
            end
        end
    end

    list:ClearItems()
end

local function _create_list_row(owner, entry, row_w)
    local row = Turbine.UI.Control()
    row:SetMouseVisible(false)
    row._icon_w = owner._list_icon_w
    row._icon_h = owner._list_icon_h
    row._gap = owner._gap
    row:SetSize(row_w, owner._list_row_h)

    row.slot = Turbine.UI.Lotro.Quickslot()
    row.slot:SetParent(row)
    _configure_quickslot(row.slot, entry.shortcut)
    row._icon_w, row._icon_h = _measure_quickslot_size(row.slot, row._icon_w, row._icon_h)
    row:SetSize(row_w, math.max(owner._list_row_h, row._icon_h))

    row.label = UI.Widgets.LuiLabel()
    row.label:SetParent(row)
    row.label:SetMouseVisible(false)
    row.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    row.label:SetText(tostring(entry.name or ""))
    _apply_body_label_style(row.label, BASE_EMPTY_FONT)

    row.SizeChanged = function()
        local width, height = row:GetSize()
        local icon_w = row._icon_w
        local icon_h = row._icon_h
        local slot_y = math.max(0, math.floor((height - icon_h) / 2))
        row.slot:SetPosition(0, slot_y)
        row.slot:SetSize(icon_w, icon_h)

        local label_x = icon_w + row._gap
        row.label:SetPosition(label_x, 0)
        row.label:SetSize(math.max(0, width - label_x), height)
    end

    function row:prepare_for_list_clear()
        _release_quickslot(self.slot)
        self:SetVisible(false)
    end

    row.SizeChanged()
    return row
end

local function _create_grid_row(owner, entries, start_index, cols, row_w)
    local row = Turbine.UI.Control()
    row:SetMouseVisible(false)
    row._icon_size = owner._grid_icon_size
    row._row_h = owner._grid_row_h
    row._gap = owner._gap
    row._cols = cols
    row.slots = {}
    row:SetSize(row_w, owner._grid_row_h)

    local last_index = math.min(#entries, start_index + cols - 1)
    for i = start_index, last_index do
        local slot = Turbine.UI.Lotro.Quickslot()
        slot:SetParent(row)
        _configure_quickslot(slot, entries[i].shortcut)
        slot:SetStretchMode(1)
        _attach_fixed_edges(slot)
        row.slots[#row.slots + 1] = slot
    end

    row.SizeChanged = function()
        local icon_size = row._icon_size
        local row_h = row._row_h
        local gap = row._gap
        local y_inset = math.max(0, math.floor((row_h - icon_size) / 2))

        for i = 1, #row.slots do
            local slot = row.slots[i]
            slot:SetPosition((i - 1) * (icon_size + gap), y_inset)
            _fit_stretched(slot, icon_size, icon_size)
        end
    end

    function row:prepare_for_list_clear()
        for i = 1, #self.slots do
            _release_quickslot(self.slots[i])
        end
        self.slots = {}
        self:SetVisible(false)
    end

    row.SizeChanged()
    return row
end

function TravelWindow:Constructor()
    UI.Widgets.LuiWindow.Constructor(self, {
        hideable = true,
    })
    self:enable_maximize(false)
    self:set_resizable(UI.Widgets.LuiWindow.RESIZE_BOTH)
    self:hide()
    self:SetWantsUpdates(false)

    self:set_title(TR["Travel"])
    self:set_icon(UI.AssetIds.compass)
    self:set_margin(_scaled_int(BASE_MARGIN))

    self.content = Turbine.UI.Control()
    self.content:SetMouseVisible(false)
    self:set_central_widget(self.content)

    local menu_bar = self:get_menu_bar()
    self.view_menu = menu_bar:add_menu(TR["View"])
    self.view_list_action = self.view_menu:add_action({
        text = TR["List"],
        checkable = true,
        checked = self:_display_mode() == DISPLAY_MODE_LIST,
        action = function()
            self:set_display_mode(DISPLAY_MODE_LIST, true)
        end,
    })
    self.view_grid_action = self.view_menu:add_action({
        text = TR["Grid"],
        checkable = true,
        checked = self:_display_mode() == DISPLAY_MODE_GRID,
        action = function()
            self:set_display_mode(DISPLAY_MODE_GRID, true)
        end,
    })

    self.list = Turbine.UI.ListBox()
    self.list:SetParent(self.content)
    self.list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.scroll = Turbine.UI.Lotro.ScrollBar()
    self.scroll:SetParent(self.content)
    self.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.list:SetVerticalScrollBar(self.scroll)

    self.empty_label = UI.Widgets.LuiLabel()
    self.empty_label:SetParent(self.content)
    self.empty_label:SetMouseVisible(false)
    self.empty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.empty_label:SetText(TR["No travel skills detected."])

    self.store = nil
    self._geometry_loaded = false
    self._suppress_size_changed = false
    self._last_store_version = nil
    self._last_display_mode = nil
    self._last_grid_cols = nil
    self._last_entry_count = 0
    self._next_refresh_at = 0

    self.content.SizeChanged = function()
        self:_layout_content()
    end

    self.PositionChanged = function()
        if self._geometry_loaded == true then
            self:capture_geometry()
        end
    end

    self.SizeChanged = function()
        if self._suppress_size_changed == true then
            return
        end
        UI.Widgets.LuiWindow._layout(self)
        self:_layout_content()
        if self._geometry_loaded == true then
            self:capture_geometry()
        end
    end

    self.VisibleChanged = function()
        local visible = self:IsVisible() == true
        self:SetWantsUpdates(visible)
        if visible == true then
            self._next_refresh_at = 0
            self:bring_to_front()
            self:refresh(true)
        end
    end

    self.Update = function()
        local now = Turbine.Engine.GetGameTime()
        if now >= self._next_refresh_at then
            self._next_refresh_at = now + REFRESH_INTERVAL
            self:refresh(false)
        end
    end

    self:apply_settings()
end

function TravelWindow:open()
    self:show()
    self:refresh(true)
end

function TravelWindow:capture_geometry()
    local window = Defaults.get_ui_window_state("travel")
    local geometry = self:get_geometry()
    window.left = geometry.left
    window.top = geometry.top
    window.width = geometry.width
    window.height = geometry.height
    window.tile = geometry.tile
end

function TravelWindow:persist_geometry()
    self:capture_geometry()
end

function TravelWindow:_load_geometry()
    local window = Defaults.get_ui_window_state("travel")
    self:set_geometry(window)
end

function TravelWindow:_display_mode()
    local mode = State.settings.travel.display_mode
    if mode == DISPLAY_MODE_GRID then
        return DISPLAY_MODE_GRID
    end
    return DISPLAY_MODE_LIST
end

function TravelWindow:_sync_menu_actions()
    local display_mode = self:_display_mode()
    self.view_list_action:set_checked(display_mode == DISPLAY_MODE_LIST)
    self.view_grid_action:set_checked(display_mode == DISPLAY_MODE_GRID)
end

function TravelWindow:set_display_mode(mode, persist)
    if mode ~= DISPLAY_MODE_GRID then
        mode = DISPLAY_MODE_LIST
    end
    if mode == self:_display_mode() then
        self:_sync_menu_actions()
        return
    end

    State.settings.travel.display_mode = mode
    if persist == true then
        State.loaded_settings.travel.display_mode = mode
    end

    self:_apply_resize_mode()
    local min_w, min_h = self:minimum_window_size()
    self:set_minimum_size(min_w, min_h)
    self:_sync_menu_actions()
    self:_layout_content(true)
    self:refresh(true)
end

function TravelWindow:_grid_columns(width_override)
    local width = width_override or self.list:GetWidth()
    local icon_size = self._grid_icon_size
    local gap = self._gap
    if width <= 0 or icon_size <= 0 then
        return 1
    end
    return math.max(1, math.floor((width + gap) / (icon_size + gap)))
end

function TravelWindow:_grid_width(cols)
    return (cols * self._grid_icon_size) + math.max(0, (cols - 1) * self._gap)
end

function TravelWindow:_window_frame_size()
    local window_w, window_h = self:GetSize()
    local content_w, content_h = self.content:GetSize()
    return math.max(0, window_w - content_w), math.max(0, window_h - content_h)
end

function TravelWindow:_entry_count()
    if self.store ~= nil then
        return #self.store:get_entries()
    end
    return self._last_entry_count or 0
end

function TravelWindow:_grid_columns_for_window_width(window_w)
    local frame_w = self:_window_frame_size()
    local content_w = math.max(0, (tonumber(window_w) or 0) - frame_w)
    local cols = self:_grid_columns(content_w)
    local entry_count = self:_entry_count()
    if entry_count > 0 then
        cols = math.min(cols, entry_count)
    end
    return math.max(1, cols)
end

function TravelWindow:_grid_rows(cols)
    local entry_count = self:_entry_count()
    if entry_count <= 0 then
        return 1
    end
    cols = math.max(1, cols or 1)
    return math.max(1, math.floor((entry_count + cols - 1) / cols))
end

function TravelWindow:compute_grid_window_size(cols)
    local frame_w, frame_h = self:_window_frame_size()
    local rows = self:_grid_rows(cols)
    local grid_w = self:_grid_width(cols)
    local grid_h = rows * self._grid_row_h
    return grid_w + frame_w, grid_h + frame_h
end

function TravelWindow:minimum_window_size()
    local min_w = _scaled_int(BASE_MIN_W)
    if self:_display_mode() ~= DISPLAY_MODE_GRID then
        return min_w, _scaled_int(BASE_MIN_H)
    end

    local _, frame_h = self:_window_frame_size()
    local min_h = frame_h + self._grid_row_h
    return min_w, min_h
end

function TravelWindow:_apply_resize_mode()
    if self:_display_mode() == DISPLAY_MODE_GRID then
        self:set_resizable(UI.Widgets.LuiWindow.RESIZE_HORIZONTAL)
        return
    end
    self:set_resizable(UI.Widgets.LuiWindow.RESIZE_BOTH)
end

function TravelWindow:_fit_grid_height(window_w)
    if self:_display_mode() ~= DISPLAY_MODE_GRID then
        return
    end

    local width = tonumber(window_w) or self:GetWidth()
    local cols = self:_grid_columns_for_window_width(width)
    local _, frame_h = self:_window_frame_size()
    local row_count = self:_grid_rows(cols)
    if self.list.GetItemCount ~= nil then
        row_count = math.max(1, self.list:GetItemCount())
    end
    local desired_h = frame_h + (row_count * self._grid_row_h)
    local min_w, min_h = self:minimum_window_size()
    if width < min_w then
        width = min_w
    end
    if desired_h < min_h then
        desired_h = min_h
    end

    local x, y = self:GetPosition()
    width, desired_h = self:_fit_size_to_screen(width, desired_h)
    x, y = self:_clamp_position_to_screen(x, y, width, desired_h)
    if x == self:GetLeft() and y == self:GetTop() and width == self:GetWidth() and desired_h == self:GetHeight() then
        return
    end

    self._suppress_size_changed = true
    self:SetPosition(x, y)
    self:SetSize(width, desired_h)
    self._suppress_size_changed = false

    UI.Widgets.LuiWindow._layout(self)
    self:_layout_content(true)
end

function TravelWindow:_layout_content(skip_refresh)
    local width, height = self.content:GetSize()
    local scroll_w = self._scroll_w or _scaled_int(BASE_SCROLL_W)
    local list_x = 0
    local list_w = math.max(0, width)
    local grid_cols = nil
    local display_mode = self:_display_mode()
    local show_scroll = display_mode ~= DISPLAY_MODE_GRID

    if display_mode == DISPLAY_MODE_GRID then
        local entry_count = self:_entry_count()
        if entry_count > 0 then
            local cols = math.min(self:_grid_columns(list_w), entry_count)
            local grid_w = self:_grid_width(cols)
            if list_w > grid_w then
                list_x = math.max(0, math.floor((list_w - grid_w) / 2))
                list_w = grid_w
            end
            grid_cols = cols
        end
    end

    self._layout_list_width = list_w
    self._layout_grid_cols = grid_cols

    self.list:SetPosition(list_x, 0)
    self.list:SetSize(list_w, height)
    self.scroll:SetVisible(show_scroll)
    if show_scroll == true then
        self.scroll:SetPosition(math.max(0, width - scroll_w), 0)
        self.scroll:SetSize(scroll_w, height)
    end
    self.empty_label:SetPosition(0, 0)
    self.empty_label:SetSize(width, height)

    if skip_refresh ~= true and self:IsVisible() == true then
        self:refresh(false)
    end
end

function TravelWindow:_populate_rows()
    _clear_list_box(self.list)

    local entries = self.store:get_entries()
    self._last_entry_count = #entries
    if #entries <= 0 then
        self.list:SetVisible(false)
        self.empty_label:SetVisible(true)
        return
    end

    self.list:SetVisible(true)
    self.empty_label:SetVisible(false)

    local row_w = math.max(0, self._layout_list_width or self.list:GetWidth())
    local display_mode = self:_display_mode()
    if display_mode == DISPLAY_MODE_GRID then
        local cols = self._layout_grid_cols or math.min(self:_grid_columns(row_w), #entries)
        self._grid_cols = cols
        self._last_grid_cols = cols
        for i = 1, #entries, cols do
            self.list:AddItem(_create_grid_row(self, entries, i, cols, row_w))
        end
        return
    end

    self._last_grid_cols = nil
    for i = 1, #entries do
        self.list:AddItem(_create_list_row(self, entries[i], row_w))
    end
end

function TravelWindow:refresh(force)
    self.store = Travel.get_shared_store()
    self.store:refresh(force == true)
    self._last_entry_count = #self.store:get_entries()
    self:_layout_content(true)

    local display_mode = self:_display_mode()
    local grid_cols = display_mode == DISPLAY_MODE_GRID and self._layout_grid_cols or nil
    local store_version = self.store.version
    if force == true or store_version ~= self._last_store_version or display_mode ~= self._last_display_mode or
        grid_cols ~= self._last_grid_cols then
        self._last_store_version = store_version
        self._last_display_mode = display_mode
        self._last_grid_cols = grid_cols
        self:_populate_rows()
    end

    if display_mode == DISPLAY_MODE_GRID then
        self:_fit_grid_height(self:GetWidth())
    end
end

function TravelWindow:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, _ui_scale())

    self._gap = _scaled_int(BASE_GAP)
    self._scroll_w = BASE_SCROLL_W
    self._list_icon_w = BASE_LIST_ICON
    self._list_icon_h = BASE_LIST_ICON
    self._grid_icon_size = _scaled_int(BASE_GRID_ICON)
    self._grid_row_h = self._grid_icon_size + self._gap
    self._list_row_h = math.max(_scaled_int(BASE_LIST_ROW_H), _scaled_int(BASE_EMPTY_FONT + 10))

    self:set_margin(_scaled_int(BASE_MARGIN))
    _apply_body_label_style(self.empty_label, BASE_EMPTY_FONT)

    if self._geometry_loaded ~= true then
        self:_load_geometry()
        self._geometry_loaded = true
    end

    self:_apply_resize_mode()
    local min_w, min_h = self:minimum_window_size()
    self:set_minimum_size(min_w, min_h)
    self:_sync_menu_actions()
    self:_layout_content()
    self:refresh(true)
end

function TravelWindow:_apply_resize_bounds(x, y, width, height, region, args)
    if self:_display_mode() ~= DISPLAY_MODE_GRID then
        UI.Widgets.LuiWindow._apply_resize_bounds(self, x, y, width, height, region, args)
        return
    end

    local min_w, min_h = self:minimum_window_size()
    if width < min_w then
        if _has_resize_dir(self._resize_mask, RESIZE_LEFT) then
            x = x + width - min_w
        end
        width = min_w
    end

    local cols = self:_grid_columns_for_window_width(width)
    local _, desired_h = self:compute_grid_window_size(cols)
    if desired_h < min_h then
        desired_h = min_h
    end

    width, desired_h = self:_fit_size_to_screen(width, desired_h)
    x, y = self:_clamp_position_to_screen(x, y, width, desired_h)

    self._suppress_size_changed = true
    self:SetPosition(x, y)
    self:SetSize(width, desired_h)
    self._suppress_size_changed = false

    UI.Widgets.LuiWindow._layout(self)
    self:_layout_content(true)
    self:capture_geometry()
end
