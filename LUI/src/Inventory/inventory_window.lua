-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_abbrev_gold = _G.LUI.Utils.lui_abbrev_gold
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local Settings = _G.LUI.Settings
local Defaults = _G.LUI.Settings.Defaults
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Inventory = _G.LUI.Features.Inventory
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Inventory.filter"
import "LUI.src.Inventory.slot"
import "LUI.src.Inventory.operations"
import "LUI.src.Utils.font"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Settings.enums"

local parse_query = Inventory.parse_query
local normalize_groups = Inventory.normalize_groups
local matches_groups = Inventory.matches_groups
local InventoryWindow = class(UI.Widgets.LuiWindow)
Inventory.InventoryWindow = InventoryWindow

local MARGIN_LEFT = 15
local MARGIN_RIGHT = 15
local MARGIN_BOTTOM = 6
local FILTER_H = 21
local BASE_MONEY_H = 24
local MONEY_GAP = 3
local BASE_HINT_GAP = 6
local BASE_HINT_H = 34
local BAR_GAP = 4
local FILTER_GAP = 4
local CLEAR_W = 52
local MIN_WINDOW_W = 193
local MIN_WINDOW_H = 148
local MIN_COLS = 6
local MIN_ROWS = 1
local MAX_COLS = 20
local TITLE_FULL_MIN_W = 360
local TITLE_COMPACT_MIN_W = 310
local TILE_SIZE_SMALL = 32
local TILE_SIZE_MEDIUM = 40
local TILE_SIZE_LARGE = 48
local RESIZE_LEFT = 1
local RESIZE_TOP = 4

local BASE_HINT_FONT_SIZE = 12
local BASE_FILTER_FONT_SIZE = 10

local function _scaled_size(value)
    return value * State.settings.global.scale
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(size)))
    end
    return font
end

local function _has_resize_dir(mask, dir)
    return math.floor((mask or 0) / dir) % 2 == 1
end

local GOLD_ICON = Turbine.UI.Graphic(0x41007e7b)
local SILVER_ICON = Turbine.UI.Graphic(0x41007e7c)
local COPPER_ICON = Turbine.UI.Graphic(0x41007e7d)

local function _get_item_description(item)
    if item == nil then
        return ""
    end

    if item.GetItemInfo ~= nil then
        local ok_info, info = pcall(function()
            return item:GetItemInfo()
        end)
        if ok_info == true and info ~= nil and info.GetDescription ~= nil then
            local ok_desc, desc = pcall(function()
                return info:GetDescription()
            end)
            if ok_desc == true and desc ~= nil then
                desc = tostring(desc)
                if desc ~= "" then
                    return desc
                end
            end
        end
    end

    return ""
end

local function _split_money_copper(total_copper)
    if total_copper == nil then
        return nil
    end

    local gold = math.floor(total_copper / 100000)
    local silver = math.floor(total_copper / 100) - gold * 1000
    local copper = total_copper - gold * 100000 - silver * 100
    return gold, silver, copper
end

local function _format_gold_compact(gold)
    return lui_abbrev_gold(gold)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function InventoryWindow:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self:set_title(TR["Inventory"])
    self:set_icon(UI.AssetIds.backpack_alt)
    self:set_resizable(UI.Widgets.LuiWindow.RESIZE_BOTH)
    self:hide()
    self:SetWantsUpdates(false)

    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate
    self._dirty = true
    self._filter_dirty = true
    self._haystack_dirty = false
    self._display_dirty = true

    self._suppress_size_changed = false

    self.tile_size = 40
    self.cols = 10
    self.rows_visible = 6
    self.margin_left = MARGIN_LEFT
    self.margin_right = MARGIN_RIGHT
    self.margin_bottom = MARGIN_BOTTOM
    self.filter_h = FILTER_H
    self.money_h = BASE_MONEY_H
    self.money_gap = MONEY_GAP
    self.bar_gap = BAR_GAP
    self.filter_gap = FILTER_GAP
    self.clear_w = CLEAR_W
    self.hint_gap = BASE_HINT_GAP
    self.hint_h = BASE_HINT_H
    self.header_h = FILTER_H + BASE_MONEY_H + MONEY_GAP

    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = self.player ~= nil and self.player:GetBackpack() or nil
    self._last_bp_size = nil
    self._inventory_used_slots = nil
    self._inventory_max_slots = nil
    self._inventory_title_text = TR["Inventory"]

    self.filter_groups = {}
    self._slot_bind_offset = nil

    local content = Turbine.UI.Control()
    content:SetMouseVisible(true)
    self:set_central_widget(content)

    self.header = Turbine.UI.Control()
    self.header:SetParent(content)

    self.g_icon = UI.Widgets.Image(GOLD_ICON)
    self.g_icon:SetParent(self.header)

    self.s_icon = UI.Widgets.Image(SILVER_ICON)
    self.s_icon:SetParent(self.header)

    self.c_icon = UI.Widgets.Image(COPPER_ICON)
    self.c_icon:SetParent(self.header)

    local function make_money_label()
        local l = UI.Widgets.LuiLabel()
        l:SetParent(self.header)
        l:SetMouseVisible(false)
        l:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        l:SetText("--")
        return l
    end

    self.g_label = make_money_label()
    self.s_label = make_money_label()
    self.c_label = make_money_label()

    self._last_money = nil

    self.filter_tb = UI.Widgets.LineEdit()
    self.filter_tb:SetParent(self.header)
    self.filter_tb:SetFont(_scaled_font("Verdana", BASE_FILTER_FONT_SIZE))
    self.filter_tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.filter_tb:set_placeholder_text(TR["Search..."])

    self.clear_button = UI.Widgets.LuiButton()
    self.clear_button:SetParent(self.header)
    self.clear_button:set_font(_scaled_font("Verdana", BASE_FILTER_FONT_SIZE))
    self.clear_button:set_text(TR["Clear"])
    self.clear_button.Click = function()
        self.filter_tb:SetText("")
        self:update_filter()
        self.filter_tb:Focus()
    end

    local menu_bar = self:get_menu_bar()
    self.edit_menu = menu_bar:add_menu(TR["Edit"])
    self.sort_menu = self.edit_menu:add_menu(TR["Sort"])
    self.sort_category_action = self.sort_menu:add_action({
        text = TR["Category + A-Z"],
        action = function()
            self:start_inventory_sort(Inventory.Operations.SORT_CATEGORY_AZ)
        end,
    })
    self.sort_az_action = self.sort_menu:add_action({
        text = TR["A-Z"],
        action = function()
            self:start_inventory_sort(Inventory.Operations.SORT_AZ)
        end,
    })
    self.sort_quantity_action = self.sort_menu:add_action({
        text = TR["Quantity"],
        action = function()
            self:start_inventory_sort(Inventory.Operations.SORT_QUANTITY)
        end,
    })

    self.merge_menu = self.edit_menu:add_menu(TR["Merge"])
    self.merge_up_action = self.merge_menu:add_action({
        text = TR["Up"],
        action = function()
            self:start_inventory_merge(Inventory.Operations.MERGE_UP)
        end,
    })
    self.merge_down_action = self.merge_menu:add_action({
        text = TR["Down"],
        action = function()
            self:start_inventory_merge(Inventory.Operations.MERGE_DOWN)
        end,
    })
    self.view_menu = menu_bar:add_menu(TR["View"])
    self.view_small_action = self.view_menu:add_action({
        text = TR["Small"],
        checkable = true,
        checked = State.loaded_settings.inventory.tile_size == TILE_SIZE_SMALL,
        action = function()
            self:set_tile_size(TILE_SIZE_SMALL)
        end,
    })
    self.view_medium_action = self.view_menu:add_action({
        text = TR["Medium"],
        checkable = true,
        checked = State.loaded_settings.inventory.tile_size == TILE_SIZE_MEDIUM,
        action = function()
            self:set_tile_size(TILE_SIZE_MEDIUM)
        end,
    })
    self.view_large_action = self.view_menu:add_action({
        text = TR["Large"],
        checkable = true,
        checked = State.loaded_settings.inventory.tile_size == TILE_SIZE_LARGE,
        action = function()
            self:set_tile_size(TILE_SIZE_LARGE)
        end,
    })

    self.list = Turbine.UI.ListBox()
    self.list:SetParent(content)
    self.list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.hint_label = UI.Widgets.LuiLabel()
    self.hint_label:SetParent(content)
    self.hint_label:SetMouseVisible(false)
    self.hint_label:SetSelectable(false)
    self.hint_label:SetForeColor(Turbine.UI.Color(0.65, 0.65, 0.65))
    self.hint_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.hint_label:SetMultiline(true)
    self.hint_label:SetFont(_scaled_font("Verdana", BASE_HINT_FONT_SIZE))
    self.default_hint_text =
        TR["Hint: to lock/unlock an item you can select it using Alt+Left click and then press Ctrl+T to toggle the lock."]
    self.hint_label:SetText(self.default_hint_text)

    self.rows = {}
    self.slots = {}
    self.inventory_operation = nil
    self.inventory_operation_status_text = ""

    self.filter_tb.TextChanged = function()
        self:update_filter()
    end

    self.SizeChanged = function()
        UI.Widgets.LuiWindow._layout(self)
        if self._suppress_size_changed then
            return
        end
        self:handle_user_resize()
    end

    self.VisibleChanged = function()
        local visible = self:IsVisible() == true
        self:SetWantsUpdates(visible or self.inventory_operation ~= nil)
        if visible then
            self.last_update_at = 0
            self._dirty = true
            self._filter_dirty = true
            self._display_dirty = true
            if self.inventory_operation ~= nil then
                self:_set_inventory_operation_status(self.inventory_operation_status_text)
            else
                self:_set_inventory_operation_status("")
            end
            self:bring_to_front()
        end
    end

    self:hook_backpack_events()
    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function InventoryWindow:bring_to_front()
    if self:IsVisible() == true then
        self:Activate()
    end
end

function InventoryWindow:capture_geometry()
    local window_state = Defaults.get_ui_window_state("inventory")
    local geometry = self:get_geometry()
    window_state.left = geometry.left
    window_state.top = geometry.top
    window_state.width = geometry.width
    window_state.height = geometry.height
    window_state.tile = geometry.tile
end

function InventoryWindow:persist_geometry()
    self:capture_geometry()
end

function InventoryWindow:get_needed_rows(cols)
    local c = cols
    if type(c) ~= "number" then
        c = tonumber(c)
    end
    if c == nil or c < 1 then
        c = 1
    end
    c = math.floor(c + 0.5)

    local size = 0
    if self.backpack ~= nil and self.backpack.GetSize ~= nil then
        size = self.backpack:GetSize() or 0
    end
    if size < 1 then
        size = 1
    end

    return math.floor((size + c - 1) / c)
end

function InventoryWindow:get_backpack_size()
    local size = 0
    if self.backpack ~= nil and self.backpack.GetSize ~= nil then
        size = self.backpack:GetSize() or 0
    end
    if size < 1 then
        size = 1
    end
    return size
end

function InventoryWindow:hook_backpack_events()
    if self.backpack == nil then
        return
    end
    local function dirty()
        self._filter_dirty = true
        self._haystack_dirty = true
        self._display_dirty = true
    end
    self.backpack.ItemAdded = dirty
    self.backpack.ItemRemoved = dirty
    self.backpack.ItemMoved = dirty
    self.backpack.ItemChanged = dirty
end

function InventoryWindow:update_filter()
    local q = self.filter_tb:GetText() or ""
    local groups = parse_query(q)
    self.filter_groups = normalize_groups(groups)

    self._filter_dirty = true
end

function InventoryWindow:get_item(index)
    if self.backpack == nil then
        return nil
    end
    if self.backpack.GetItem ~= nil then
        return self.backpack:GetItem(index)
    end
    return nil
end

function InventoryWindow:layout()
    local w, h = self:central_widget():GetSize()
    local min_w = _scaled_int(MIN_WINDOW_W)
    local min_h = _scaled_int(MIN_WINDOW_H)
    if w < min_w then w = min_w end
    if h < min_h then h = min_h end

    self.header:SetPosition(self.margin_left, 0)
    self.header:SetSize(w - self.margin_left - self.margin_right, self.header_h)

    local money_h = self.money_h
    local icon_size = money_h
    local gap = self.money_gap
    local field_w = icon_size * 2
    local total_w = (icon_size * 3) + (gap * 4) + (field_w * 3)
    local x = math.floor((self.header:GetWidth() - total_w) / 2)
    if x < 0 then x = 0 end
    local y = 0

    self.g_icon:SetPosition(x, y + 1)
    self.g_icon:set_size(icon_size, icon_size)
    x = x + icon_size + gap
    self.g_label:SetPosition(x, y)
    self.g_label:SetSize(field_w, money_h)
    x = x + field_w + gap

    self.s_icon:SetPosition(x, y + 1)
    self.s_icon:set_size(icon_size, icon_size)
    x = x + icon_size + gap
    self.s_label:SetPosition(x, y)
    self.s_label:SetSize(field_w, money_h)
    x = x + field_w + gap

    self.c_icon:SetPosition(x, y + 1)
    self.c_icon:set_size(icon_size, icon_size)
    x = x + icon_size + gap
    self.c_label:SetPosition(x, y)
    self.c_label:SetSize(field_w, money_h)

    local clear_w = self.clear_w
    local gap = self.filter_gap

    local filter_y = money_h + self.money_gap

    self.clear_button:SetPosition(self.header:GetWidth() - clear_w, filter_y)
    self.clear_button:SetSize(clear_w, self.filter_h)

    local filter_w = self.header:GetWidth() - clear_w - gap
    if filter_w < _scaled_int(59) then
        filter_w = _scaled_int(59)
    end
    self.filter_tb:SetPosition(0, filter_y)
    self.filter_tb:SetSize(filter_w, self.filter_h)

    local list_y = self.header_h + self.bar_gap
    local list_h = h - self.margin_bottom - self.hint_h - self.hint_gap - list_y
    if list_h < _scaled_int(30) then list_h = _scaled_int(30) end

    local list_w = w - self.margin_left - self.margin_right
    if list_w < _scaled_int(30) then list_w = _scaled_int(30) end

    local grid_w = (self.cols or MIN_COLS) * self.tile_size
    local list_x = self.margin_left
    if list_w > grid_w then
        list_x = self.margin_left + math.floor((list_w - grid_w) / 2)
        list_w = grid_w
    end

    self.list:SetPosition(list_x, list_y)
    self.list:SetSize(list_w, list_h)

    self.hint_label:SetPosition(list_x, list_y + list_h + self.hint_gap)
    self.hint_label:SetSize(list_w, self.hint_h)
end

function InventoryWindow:compute_window_size(cols, rows)
    local grid_w = cols * self.tile_size
    local grid_h = rows * self.tile_size

    local content_w = self.margin_left + self.margin_right + grid_w
    local content_h = self.margin_bottom + self.header_h + self.bar_gap + self.hint_gap + self.hint_h + grid_h
    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    return content_w + math.max(0, window_w - central_w),
        content_h + math.max(0, window_h - central_h)
end

function InventoryWindow:minimum_window_size()
    local min_w, min_h = self:compute_window_size(MIN_COLS, MIN_ROWS)
    return math.max(_scaled_int(MIN_WINDOW_W), min_w),
        math.max(_scaled_int(MIN_WINDOW_H), min_h)
end

function InventoryWindow:get_columns_for_window_width(window_w)
    local current_window_w = self:GetWidth()
    local current_central_w = self:central_widget():GetSize()
    local content_w = math.max(0, window_w - (current_window_w - current_central_w))
    local list_w = content_w - self.margin_left - self.margin_right
    local cols = math.floor(list_w / self.tile_size)
    if cols < MIN_COLS then cols = MIN_COLS end
    if cols > MAX_COLS then cols = MAX_COLS end
    return cols
end

function InventoryWindow:get_visible_rows_for_window_height(window_h, min_rows)
    local current_window_h = self:GetHeight()
    local _, current_central_h = self:central_widget():GetSize()
    local content_h = math.max(0, window_h - (current_window_h - current_central_h))
    local grid_h = content_h - self.margin_bottom - self.header_h - self.bar_gap - self.hint_gap - self.hint_h
    local rows = math.floor(grid_h / self.tile_size)
    if rows < min_rows then rows = min_rows end
    return rows
end

function InventoryWindow:get_columns_for_visible_rows(rows)
    if type(rows) ~= "number" then
        error("Inventory visible rows must be a number")
    end
    if rows < 1 then
        error("Inventory visible rows must be positive")
    end
    local r = math.floor(rows + 0.5)

    local size = self:get_backpack_size()
    local cols = math.floor((size + r - 1) / r)
    if cols < MIN_COLS then cols = MIN_COLS end
    if cols > MAX_COLS then cols = MAX_COLS end
    return cols
end

function InventoryWindow:window_size_has_inventory_capacity(window_w, window_h)
    local cols = self:get_columns_for_window_width(window_w)
    local rows = self:get_visible_rows_for_window_height(window_h, MIN_ROWS)
    return rows >= self:get_needed_rows(cols)
end

function InventoryWindow:fit_window_size_to_inventory_capacity(window_w, window_h)
    local fit_w, fit_h = self:_fit_size_to_screen(window_w, window_h)
    if self:window_size_has_inventory_capacity(fit_w, fit_h) == true then
        return fit_w, fit_h
    end

    local _, _, work_w, work_h = self:_work_area()
    local min_w, min_h = self:minimum_window_size()
    local max_w = math.max(min_w, work_w)
    local max_h = math.max(min_h, work_h)

    local cols = self:get_columns_for_window_width(fit_w)
    local needed_rows = self:get_needed_rows(cols)
    local _, needed_h = self:compute_window_size(cols, needed_rows)
    needed_h = math.min(max_h, math.max(min_h, needed_h))
    if self:window_size_has_inventory_capacity(fit_w, needed_h) == true then
        return fit_w, needed_h
    end

    local rows = self:get_visible_rows_for_window_height(fit_h, MIN_ROWS)
    local needed_cols = self:get_columns_for_visible_rows(rows)
    local needed_w = self:compute_window_size(needed_cols, rows)
    needed_w = math.min(max_w, math.max(min_w, needed_w))
    if self:window_size_has_inventory_capacity(needed_w, fit_h) == true then
        return needed_w, fit_h
    end

    cols = self:get_columns_for_window_width(max_w)
    needed_rows = self:get_needed_rows(cols)
    _, needed_h = self:compute_window_size(cols, needed_rows)
    needed_h = math.min(max_h, math.max(min_h, needed_h))
    if self:window_size_has_inventory_capacity(max_w, needed_h) == true then
        return max_w, needed_h
    end

    rows = self:get_visible_rows_for_window_height(max_h, MIN_ROWS)
    needed_cols = self:get_columns_for_visible_rows(rows)
    needed_w = self:compute_window_size(needed_cols, rows)
    needed_w = math.min(max_w, math.max(min_w, needed_w))
    if self:window_size_has_inventory_capacity(needed_w, max_h) == true then
        return needed_w, max_h
    end

    return max_w, max_h
end

function InventoryWindow:clamp_resize_to_inventory_capacity(window_w, window_h)
    if self:window_size_has_inventory_capacity(window_w, window_h) == true then
        return window_w, window_h
    end

    local current_w, current_h = self:GetSize()
    local clamped_w = window_w
    local clamped_h = window_h

    for _ = 1, self:get_backpack_size() + MAX_COLS do
        local old_w = clamped_w
        local old_h = clamped_h

        if window_w < current_w then
            local rows = self:get_visible_rows_for_window_height(clamped_h, MIN_ROWS)
            local needed_cols = self:get_columns_for_visible_rows(rows)
            local min_w = self:compute_window_size(needed_cols, rows)
            if min_w > current_w then
                min_w = current_w
            end
            clamped_w = math.max(window_w, min_w)
        end

        if window_h < current_h then
            local cols = self:get_columns_for_window_width(clamped_w)
            local needed_rows = self:get_needed_rows(cols)
            local _, min_h = self:compute_window_size(cols, needed_rows)
            if min_h > current_h then
                min_h = current_h
            end
            clamped_h = math.max(window_h, min_h)
        end

        if clamped_w == old_w and clamped_h == old_h then
            break
        end
    end

    return clamped_w, clamped_h
end

function InventoryWindow:apply_resize_candidate(window_x, window_y, window_w, window_h)
    local desired_w = window_w
    local desired_h = window_h
    local min_w, min_h = self:minimum_window_size()
    if desired_w < min_w then desired_w = min_w end
    if desired_h < min_h then desired_h = min_h end

    local mask = self._resize_mask or 0
    if self._resizing == true then
        desired_w, desired_h = self:clamp_resize_to_inventory_capacity(desired_w, desired_h)
    end

    if _has_resize_dir(mask, RESIZE_LEFT) then
        window_x = window_x + window_w - desired_w
    end
    if _has_resize_dir(mask, RESIZE_TOP) then
        window_y = window_y + window_h - desired_h
    end

    window_x, window_y, desired_w, desired_h = self:_clamp_resize_to_screen(window_x, window_y, desired_w, desired_h)
    if self._resizing == true and self:window_size_has_inventory_capacity(desired_w, desired_h) ~= true then
        local screen_w = desired_w
        local screen_h = desired_h
        desired_w, desired_h = self:clamp_resize_to_inventory_capacity(desired_w, desired_h)
        if _has_resize_dir(mask, RESIZE_LEFT) then
            window_x = window_x + screen_w - desired_w
        end
        if _has_resize_dir(mask, RESIZE_TOP) then
            window_y = window_y + screen_h - desired_h
        end
    end

    local cols = self:get_columns_for_window_width(desired_w)
    local rows = self:get_visible_rows_for_window_height(desired_h, MIN_ROWS)
    local changed = cols ~= self.cols or rows ~= self.rows_visible

    self.cols = cols
    self.rows_visible = rows

    if self:is_tiled() == true then
        desired_w = window_w
        desired_h = window_h
    end

    local old_suppress = self._suppress_size_changed
    self._suppress_size_changed = true
    self:SetPosition(window_x, window_y)
    self:SetSize(desired_w, desired_h)
    self._suppress_size_changed = old_suppress

    self:layout()
    if changed == true then
        self:build_grid()
    end
    self:_refresh_inventory_title()
    self._dirty = true
    self._filter_dirty = true
    self._display_dirty = true
end

function InventoryWindow:_inventory_title_for_current_width()
    local base_title = TR["Inventory"]
    if self._inventory_used_slots == nil or self._inventory_max_slots == nil then
        return base_title
    end

    local slot_count = tostring(self._inventory_used_slots) .. "/" .. tostring(self._inventory_max_slots)
    local width = self:GetWidth()
    if width >= _scaled_int(TITLE_FULL_MIN_W) then
        return base_title .. " (" .. slot_count .. ")"
    end
    if width >= _scaled_int(TITLE_COMPACT_MIN_W) then
        return "(" .. slot_count .. ")"
    end
    return ""
end

function InventoryWindow:_refresh_inventory_title()
    local title = self:_inventory_title_for_current_width()
    if self._inventory_title_text == title then
        return
    end

    self._inventory_title_text = title
    self:set_title(title)
end

function InventoryWindow:_set_inventory_title(used_slots, max_slots)
    self._inventory_used_slots = used_slots
    self._inventory_max_slots = max_slots
    self:_refresh_inventory_title()
end

function InventoryWindow:update_money()
    local total = self:_get_total_money()
    if total == self._last_money then
        return
    end
    self._last_money = total
    local gold, silver, copper = _split_money_copper(total)
    if gold == nil then
        self.g_label:SetText("--")
        self.s_label:SetText("--")
        self.c_label:SetText("--")
        return
    end
    self.g_label:SetText(_format_gold_compact(gold))
    self.s_label:SetText(tostring(silver))
    self.c_label:SetText(tostring(copper))
end

function InventoryWindow:_sync_view_menu_actions()
    local tile_size = State.loaded_settings.inventory.tile_size
    self.view_small_action:set_checked(tile_size == TILE_SIZE_SMALL)
    self.view_medium_action:set_checked(tile_size == TILE_SIZE_MEDIUM)
    self.view_large_action:set_checked(tile_size == TILE_SIZE_LARGE)
end

function InventoryWindow:set_tile_size(tile_size)
    if tile_size ~= TILE_SIZE_SMALL and tile_size ~= TILE_SIZE_MEDIUM and tile_size ~= TILE_SIZE_LARGE then
        error("Unsupported inventory tile size: " .. tostring(tile_size))
    end

    if State.loaded_settings.inventory.tile_size == tile_size then
        self:_sync_view_menu_actions()
        return
    end

    local geometry = self:get_geometry()
    local cols = self.cols
    local rows = self.rows_visible

    State.loaded_settings.inventory.tile_size = tile_size
    Settings.rebuild()

    self.tile_size = State.settings.inventory.tile_size
    local width, height = self:compute_window_size(cols, rows)
    local window_state = Defaults.get_ui_window_state("inventory")
    window_state.left = geometry.left
    window_state.top = geometry.top
    window_state.width = width
    window_state.height = height
    window_state.tile = geometry.tile

    self:_sync_view_menu_actions()
    self:apply_settings()
end

function InventoryWindow:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)

    local s = State.settings.inventory
    self.update_every = 1.0 / State.settings.global.refresh_rate
    self.tile_size = s.tile_size
    self.rows_visible = self:get_needed_rows(self.cols)

    self.margin_left = _scaled_int(MARGIN_LEFT)
    self.margin_right = _scaled_int(MARGIN_RIGHT)
    self.margin_bottom = _scaled_int(MARGIN_BOTTOM)
    self.filter_h = _scaled_int(FILTER_H)
    self.money_gap = _scaled_int(MONEY_GAP)
    self.bar_gap = _scaled_int(BAR_GAP)
    self.filter_gap = _scaled_int(FILTER_GAP)
    self.clear_w = _scaled_int(CLEAR_W)
    local scale = State.settings.global.scale
    self.money_h = math.floor((BASE_MONEY_H * scale) + 0.5)
    self.hint_gap = math.floor((BASE_HINT_GAP * scale) + 0.5)
    self.hint_h = math.floor((BASE_HINT_H * scale) + 0.5)
    self.header_h = self.filter_h + self.money_h + self.money_gap

    local sb_font = State.settings.status_bar.font
    local money_font_size = BASE_MONEY_H * State.settings.global.scale
    local money_font = FONT_TO_LOTRO(sb_font.name, money_font_size)
    local font_style = LUI_TO_LOTRO.font_style[sb_font.style] or Turbine.UI.FontStyle.None

    self.g_label:SetFont(money_font)
    self.s_label:SetFont(money_font)
    self.c_label:SetFont(money_font)
    self.g_label:SetFontStyle(font_style)
    self.s_label:SetFontStyle(font_style)
    self.c_label:SetFontStyle(font_style)
    self.g_label:SetForeColor(sb_font.color)
    self.s_label:SetForeColor(sb_font.color)
    self.c_label:SetForeColor(sb_font.color)
    self.g_label:SetOutlineColor(sb_font.outline_color)
    self.s_label:SetOutlineColor(sb_font.outline_color)
    self.c_label:SetOutlineColor(sb_font.outline_color)

    local filter_font = _scaled_font("Verdana", BASE_FILTER_FONT_SIZE)
    self.filter_tb:SetFont(filter_font)
    self.clear_button:set_font(filter_font)

    local hint_font_size = math.floor((BASE_HINT_FONT_SIZE * scale) + 0.5)
    local hint_font = FONT_TO_LOTRO("Verdana", hint_font_size)
    self.hint_label:SetFont(hint_font)

    local window_state = Defaults.get_ui_window_state("inventory")
    self:SetPosition(window_state.left, window_state.top)

    local w = tonumber(window_state.width)
    local stored_h = tonumber(window_state.height)
    if w ~= nil then
        self.cols = self:get_columns_for_window_width(w)
    end

    if stored_h ~= nil then
        self.rows_visible = self:get_visible_rows_for_window_height(stored_h, MIN_ROWS)
    else
        self.rows_visible = self:get_needed_rows(self.cols)
    end

    local computed_w, computed_h = self:compute_window_size(self.cols, self.rows_visible)
    local h = stored_h
    if w == nil then
        w = computed_w
    end
    if h == nil then
        h = computed_h
    end
    local min_w, min_h = self:minimum_window_size()
    self:set_minimum_size(min_w, min_h)
    self:_sync_view_menu_actions()
    if w < min_w then w = min_w end
    if h < min_h then h = min_h end
    w, h = self:fit_window_size_to_inventory_capacity(w, h)
    self.cols = self:get_columns_for_window_width(w)
    self.rows_visible = self:get_visible_rows_for_window_height(h, MIN_ROWS)
    self._suppress_size_changed = true
    self:SetSize(w, h)
    self._suppress_size_changed = false
    local window_tile = window_state.tile
    self:set_geometry({
        left = window_state.left,
        top = window_state.top,
        width = w,
        height = h,
        tile = window_tile,
    })
    local actual_w, actual_h = self:GetSize()
    self.cols = self:get_columns_for_window_width(actual_w)
    self.rows_visible = self:get_visible_rows_for_window_height(actual_h, MIN_ROWS)

    self:layout()
    self:build_grid()
    self:update_money()
    self._dirty = true
    self._filter_dirty = true
    self._display_dirty = true
end

function InventoryWindow:handle_user_resize()
    local window_w, window_h = self:GetSize()
    local window_x, window_y = self:GetPosition()
    self:apply_resize_candidate(window_x, window_y, window_w, window_h)
end

function InventoryWindow:_apply_resize_bounds(x, y, w, h, region, args)
    self:apply_resize_candidate(x, y, w, h)
end

function InventoryWindow:build_grid()
    if self.backpack == nil or self.backpack.GetSize == nil then
        return
    end

    local size = self.backpack:GetSize() or 0
    if size < 0 then size = 0 end

    local cols = self.cols
    if cols < 1 then cols = 1 end
    local row_count = math.floor((size + cols - 1) / cols)
    if row_count < 1 then
        row_count = 1
    end

    local grid_w = cols * self.tile_size

    while #self.rows > row_count do
        local row = table.remove(self.rows)
        if row ~= nil then
            self.list:RemoveItem(row)
        end
    end

    while #self.rows < row_count do
        local row = Turbine.UI.Control()
        row:SetSize(grid_w, self.tile_size)
        row:SetMouseVisible(true)
        table.insert(self.rows, row)
        self.list:AddItem(row)
    end

    for r = 1, #self.rows do
        local row = self.rows[r]
        row:SetSize(grid_w, self.tile_size)
    end

    for i = 1, size do
        local slot = self.slots[i]
        if slot == nil then
            slot = Inventory.InventorySlot(i, function(dest_index, drag_drop_info, args)
                self:perform_drop(dest_index, drag_drop_info, args)
            end)
            self.slots[i] = slot
        end

        slot:set_tile(self.tile_size)

        local r = math.floor((i - 1) / cols) + 1
        local c = ((i - 1) % cols) + 1

        local parent = self.rows[r]
        slot:SetParent(parent)
        slot:set_grid_edges(r == 1, c == 1)
        slot:SetPosition((c - 1) * self.tile_size, 0)
    end

    for i = size + 1, #self.slots do
        local slot = self.slots[i]
        if slot ~= nil then
            slot:SetParent(nil)
        end
    end
end

function InventoryWindow:perform_drop(dest_index, drag_drop_info, args)
    if self.inventory_operation ~= nil then
        self:_set_inventory_operation_status(TR["Inventory action already running."])
        return
    end

    if self.backpack == nil or drag_drop_info == nil then
        return
    end
    if drag_drop_info.GetShortcut == nil or self.backpack.PerformShortcutDrop == nil then
        return
    end

    local ok, shortcut = pcall(function()
        return drag_drop_info:GetShortcut()
    end)
    if not ok or shortcut == nil then
        return
    end

    local split = false
    if args ~= nil then
        if args.ShiftKeyDown ~= nil then
            split = args.ShiftKeyDown == true
        elseif args.Shift ~= nil then
            split = args.Shift == true
        end
    end
    if split ~= true and Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Control ~= nil and Turbine.UI.Control.IsShiftKeyDown ~= nil then
        pcall(function()
            split = Turbine.UI.Control.IsShiftKeyDown() == true
        end)
    end

    pcall(function()
        self.backpack:PerformShortcutDrop(shortcut, dest_index, split == true)
    end)

    -- local offset = self._drop_index_offset
    -- if offset == 0 or offset == -1 then
    --     pcall(function()
    --         self.backpack:PerformShortcutDrop(shortcut, dest_index + offset)
    --     end)
    -- else
    --     local ok1 = pcall(function()
    --         self.backpack:PerformShortcutDrop(shortcut, dest_index)
    --     end)
    --     if ok1 == true then
    --         self._drop_index_offset = 0
    --     elseif type(dest_index) == "number" and dest_index > 0 then
    --         local ok0 = pcall(function()
    --             self.backpack:PerformShortcutDrop(shortcut, dest_index - 1)
    --         end)
    --         if ok0 == true then
    --             self._drop_index_offset = -1
    --         end
    --     end
    -- end

    self._filter_dirty = true
    self._haystack_dirty = true
    self._display_dirty = true
end

function InventoryWindow:start_inventory_sort(mode)
    if self.inventory_operation ~= nil then
        self:_set_inventory_operation_status(TR["Inventory action already running."])
        return
    end

    local operation = Inventory.Operations.create_sort(self.backpack, mode)
    self:_begin_inventory_operation(operation, TR["Sorting inventory..."])
end

function InventoryWindow:start_inventory_merge(direction)
    if self.inventory_operation ~= nil then
        self:_set_inventory_operation_status(TR["Inventory action already running."])
        return
    end

    local operation = Inventory.Operations.create_merge(self.backpack, direction)
    self:_begin_inventory_operation(operation, TR["Merging inventory..."])
end

function InventoryWindow:update_slots()
    if self.backpack == nil or self.backpack.GetSize == nil then
        self:_set_inventory_title(nil, nil)
        return
    end

    local size = self.backpack:GetSize() or 0
    local used_slots = 0
    local groups = self.filter_groups
    local need_filter = groups ~= nil and #groups > 0
    local force_filter = self._filter_dirty == true
    local force_haystack = self._haystack_dirty == true
    local force_display = self._display_dirty == true
    local any_change = false

    for i = 1, size do
        local item = self:get_item(i)
        local qty = 1
        if item ~= nil and item.GetQuantity ~= nil then
            qty = item:GetQuantity() or 1
        end
        if qty < 1 then
            item = nil
            qty = 0
            -- local is_empty = false
            -- if item == nil or item.GetName == nil then
            --     is_empty = true
            -- else
            --     local ok_name, name = pcall(function() return item:GetName() end)
            --     if ok_name ~= true or name == nil or name == "" then
            --         is_empty = true
            --     end
            -- end
            -- if is_empty then
            --     item = nil
            --     qty = 0
            -- else
            --     qty = 1
            -- end
        end
        if item ~= nil then
            used_slots = used_slots + 1
        end

        local slot = self.slots[i]
        if slot ~= nil then
            local item_changed = item ~= slot.item
            if item_changed then
                slot.item = item
                slot.qty = nil
                slot.haystack_lower = nil
                any_change = true
            end

            if (force_display or item_changed or slot._display_bound ~= true) and slot.item_control ~= nil and slot.item_control.SetItem ~= nil then
                pcall(function()
                    slot.item_control:SetItem(item)
                end)
                slot._display_bound = true
            end

            if qty ~= (slot.qty or 1) then
                slot.qty = qty
                any_change = true
            end

            local matched = true
            if need_filter then
                if item == nil then
                    matched = false
                else
                    local need_rebuild = slot.haystack_lower == nil or item_changed or force_haystack
                    if need_rebuild then
                        local name = (item.GetName ~= nil) and (item:GetName() or "") or ""
                        local desc = _get_item_description(item)
                        slot.haystack_lower = string.lower(name .. "\n" .. desc)
                    end
                    if force_filter or need_rebuild then
                        matched = matches_groups(groups, slot.haystack_lower or "")
                    else
                        matched = slot.matched == true
                    end
                end
            end
            if matched ~= (slot.matched == true) then
                slot.matched = matched
                slot:set_matched(matched)
                any_change = true
            end

            -- Dimming/clearing is done via icon opacity (more reliable than an overlay).
            -- Also prevents stale icon artifacts after SetItem(nil).
            if slot.item_control ~= nil and slot.item_control.SetOpacity ~= nil then
                local target_opacity
                if item == nil then
                    target_opacity = 0.001
                elseif matched ~= true then
                    target_opacity = 0.25
                else
                    target_opacity = 1
                end
                if slot._icon_opacity ~= target_opacity then
                    slot._icon_opacity = target_opacity
                    slot.item_control:SetOpacity(target_opacity)
                end
            end
        end
    end

    self._filter_dirty = false
    self._haystack_dirty = false
    self._display_dirty = false
    self:_set_inventory_title(used_slots, size)
end

function InventoryWindow:Update()
    local now = Turbine.Engine.GetGameTime()

    if self.inventory_operation ~= nil then
        self:_update_inventory_operation(now)
    end

    if (now - (self.last_update_at or 0)) < self.update_every then
        return
    end
    self.last_update_at = now

    if self._dirty then
        self:build_grid()
        self._filter_dirty = true
        self._dirty = false
    end
    self:update_slots()
    self:update_money()
end

function InventoryWindow:open()
    self:show()
end

function InventoryWindow:toggle()
    UI.Widgets.LuiWindow.toggle(self)
    if self:IsVisible() then
        self._dirty = true
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function InventoryWindow:_get_total_money()
    local p = self.player
    if p == nil or p.GetAttributes == nil then
        return nil
    end
    local a = p:GetAttributes()
    if a == nil or a.GetMoney == nil then
        return nil
    end
    return a:GetMoney()
end

function InventoryWindow:_begin_inventory_operation(operation, status_text)
    self.inventory_operation = operation
    self:_set_inventory_actions_enabled(false)
    self:_set_inventory_operation_status(status_text)
    self:SetWantsUpdates(true)
end

function InventoryWindow:_update_inventory_operation(now)
    local result = self.inventory_operation:tick(now)
    if result.done == true then
        self:_finish_inventory_operation(TR[result.message_key])
    end
end

function InventoryWindow:_finish_inventory_operation(status_text)
    self.inventory_operation = nil
    self:_set_inventory_actions_enabled(true)
    self:_set_inventory_operation_status(status_text)
    self._dirty = true
    self._filter_dirty = true
    self._haystack_dirty = true
    self._display_dirty = true
    if self:IsVisible() ~= true then
        self:SetWantsUpdates(false)
    end
end

function InventoryWindow:_set_inventory_actions_enabled(enabled)
    local is_enabled = enabled == true
    if is_enabled ~= true then
        self.edit_menu:close()
        self.sort_menu:close()
        self.merge_menu:close()
    end
    self.edit_menu.button:set_enabled(is_enabled)
    self.sort_category_action:set_enabled(is_enabled)
    self.sort_az_action:set_enabled(is_enabled)
    self.sort_quantity_action:set_enabled(is_enabled)
    self.merge_up_action:set_enabled(is_enabled)
    self.merge_down_action:set_enabled(is_enabled)
end

function InventoryWindow:_set_inventory_operation_status(text)
    local status = tostring(text or "")
    self.inventory_operation_status_text = status
    if status == "" then
        self.hint_label:SetText(self.default_hint_text)
    else
        self.hint_label:SetText(status)
    end
end
