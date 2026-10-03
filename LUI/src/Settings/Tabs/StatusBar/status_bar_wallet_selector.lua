-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local StatusBarPage = _G.LUI.Settings.Pages.StatusBar
local UI = _G.LUI.UI
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.StatusBar.common"

local S = _G.LUI.Features.StatusBar.Common
local Style = UI.Widgets.Style

local WALLET_SELECTOR_HEIGHT = 209
local WALLET_SELECTOR_GAP = 6
local WALLET_SELECTOR_BUTTON_W = 58
local WALLET_SELECTOR_BUTTON_H = 22
local WALLET_SELECTOR_SCROLL_W = 10
local WALLET_SELECTOR_MIN_LIST_W = 90
local WALLET_SELECTOR_BOX_PAD = 1

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local function _copy_list(items)
    local out = {}
    if type(items) ~= "table" then
        return out
    end
    for i = 1, #items do
        out[i] = items[i]
    end
    return out
end

local function _wallet_selector_normalize_items(items)
    return _copy_list(S.parse_wallet_item_list(items))
end

local function _wallet_selector_compare_entries(a, b)
    local an = string.lower(tostring(a or ""))
    local bn = string.lower(tostring(b or ""))
    if an == bn then
        return tostring(a or "") < tostring(b or "")
    end
    return an < bn
end

local function _wallet_selector_normalize_filter(value)
    local v = tostring(value or ""):lower()
    v = v:gsub("[’']", "")
    v = v:gsub("[^%w]+", " ")
    v = v:gsub("%s+", " ")
    v = v:gsub("^%s+", "")
    v = v:gsub("%s+$", "")
    return v
end

local function _wallet_selector_matches_filter(spec, filter_text)
    local filter = _wallet_selector_normalize_filter(filter_text)
    if spec == nil or filter == "" then
        return true
    end

    local function matches(value)
        local candidate = _wallet_selector_normalize_filter(value)
        return candidate ~= "" and string.find(candidate, filter, 1, true) ~= nil
    end

    return matches(spec)
end

local function _wallet_selector_current_token(entry)
    if entry == nil then
        return nil, nil
    end

    if entry.active_list == "available" and type(entry.available_index) == "number" then
        local selected = entry.available_entries[entry.available_index]
        return entry.active_list, selected
    end

    if entry.active_list == "selected" and type(entry.selected_index) == "number" then
        return entry.active_list, entry.selected_items[entry.selected_index]
    end

    return nil, nil
end

local function _wallet_selector_sync_active(entry)
    local available_index = nil
    if entry.active_list == "available" then
        available_index = entry.available_index
    end

    local selected_index = nil
    if entry.active_list == "selected" then
        selected_index = entry.selected_index
    end

    for i = 1, #(entry.available_buttons or {}) do
        local button = entry.available_buttons[i]
        if button ~= nil then
            button:set_active(i == available_index)
        end
    end

    for i = 1, #(entry.selected_buttons or {}) do
        local button = entry.selected_buttons[i]
        if button ~= nil then
            button:set_active(i == selected_index)
        end
    end

    if entry.add_button ~= nil then
        entry.add_button:set_enabled(type(available_index) == "number")
    end
    if entry.remove_button ~= nil then
        entry.remove_button:set_enabled(type(selected_index) == "number")
    end
    if entry.up_button ~= nil then
        entry.up_button:set_enabled(type(selected_index) == "number" and selected_index > 1)
    end
    if entry.down_button ~= nil then
        entry.down_button:set_enabled(type(selected_index) == "number" and selected_index < #entry.selected_items)
    end
end

local function _wallet_selector_select(entry, list_name, index)
    if list_name == "available" then
        entry.active_list = "available"
        entry.available_index = index
        entry.selected_index = nil
    else
        entry.active_list = "selected"
        entry.selected_index = index
        entry.available_index = nil
    end
    _wallet_selector_sync_active(entry)
end

local function _wallet_selector_layout(entry)
    if entry == nil or entry.control == nil then
        return
    end

    local w, h = entry.control:GetSize()
    local gap = _scaled_int(WALLET_SELECTOR_GAP)
    local label_h = entry.window ~= nil and entry.window.field_label_height or _scaled_int(31)
    local filter_h = entry.window ~= nil and entry.window.input_height or _scaled_int(21)
    local button_w = _scaled_int(WALLET_SELECTOR_BUTTON_W)
    local button_h = _scaled_int(WALLET_SELECTOR_BUTTON_H)
    local scroll_w = WALLET_SELECTOR_SCROLL_W
    local item_h = entry.window ~= nil and entry.window.input_height or _scaled_int(21)
    local min_list_w = _scaled_int(WALLET_SELECTOR_MIN_LIST_W)
    local box_pad = _scaled_int(WALLET_SELECTOR_BOX_PAD)

    local action_w = button_w
    local reorder_w = button_w
    local remaining = w - action_w - reorder_w - (gap * 3)
    if remaining < (min_list_w * 2) then
        local shrink = (min_list_w * 2) - remaining
        local reduce_each = math.floor((shrink + 1) / 2)
        action_w = math.max(_scaled_int(34), action_w - reduce_each)
        reorder_w = math.max(_scaled_int(34), reorder_w - reduce_each)
        remaining = w - action_w - reorder_w - (gap * 3)
    end
    if remaining < 2 then
        remaining = 2
    end

    local available_w = math.floor(remaining / 2)
    local selected_w = remaining - available_w
    if available_w < 1 then available_w = 1 end
    if selected_w < 1 then selected_w = 1 end

    local available_x = 0
    local actions_x = available_x + available_w + gap
    local selected_x = actions_x + action_w + gap
    local reorder_x = selected_x + selected_w + gap

    local filter_y = label_h + gap
    local box_top = filter_y + filter_h + gap
    local box_h = h - box_top
    if box_h < item_h + (box_pad * 2) then
        box_h = item_h + (box_pad * 2)
    end
    local list_h = math.max(0, box_h - (box_pad * 2))

    entry.available_label:SetPosition(available_x, 0)
    entry.available_label:SetSize(available_w, label_h)
    entry.selected_label:SetPosition(selected_x, 0)
    entry.selected_label:SetSize(selected_w, label_h)

    entry.available_filter:SetPosition(available_x, filter_y)
    entry.available_filter:SetSize(available_w, filter_h)

    entry.available_box:SetPosition(available_x, box_top)
    entry.available_box:SetSize(available_w, box_h)
    entry.available_fill:SetPosition(box_pad, box_pad)
    entry.available_fill:SetSize(math.max(0, available_w - (box_pad * 2)), list_h)
    entry.available_list:SetPosition(0, 0)
    entry.available_list:SetSize(math.max(0, entry.available_fill:GetWidth() - scroll_w), list_h)
    entry.available_scroll:SetPosition(entry.available_fill:GetWidth() - scroll_w, 0)
    entry.available_scroll:SetSize(scroll_w, list_h)

    entry.selected_box:SetPosition(selected_x, box_top)
    entry.selected_box:SetSize(selected_w, box_h)
    entry.selected_fill:SetPosition(box_pad, box_pad)
    entry.selected_fill:SetSize(math.max(0, selected_w - (box_pad * 2)), list_h)
    entry.selected_list:SetPosition(0, 0)
    entry.selected_list:SetSize(math.max(0, entry.selected_fill:GetWidth() - scroll_w), list_h)
    entry.selected_scroll:SetPosition(entry.selected_fill:GetWidth() - scroll_w, 0)
    entry.selected_scroll:SetSize(scroll_w, list_h)

    local action_block_h = (button_h * 2) + gap
    local action_y = box_top + math.max(0, math.floor((box_h - action_block_h) / 2))
    entry.add_button:SetPosition(actions_x, action_y)
    entry.add_button:SetSize(action_w, button_h)
    entry.remove_button:SetPosition(actions_x, action_y + button_h + gap)
    entry.remove_button:SetSize(action_w, button_h)

    local reorder_block_h = (button_h * 2) + gap
    local reorder_y = box_top + math.max(0, math.floor((box_h - reorder_block_h) / 2))
    entry.up_button:SetPosition(reorder_x, reorder_y)
    entry.up_button:SetSize(reorder_w, button_h)
    entry.down_button:SetPosition(reorder_x, reorder_y + button_h + gap)
    entry.down_button:SetSize(reorder_w, button_h)

    for i = 1, #(entry.available_buttons or {}) do
        local button = entry.available_buttons[i]
        if button ~= nil then
            button:SetSize(entry.available_list:GetWidth(), item_h)
        end
    end

    for i = 1, #(entry.selected_buttons or {}) do
        local button = entry.selected_buttons[i]
        if button ~= nil then
            button:SetSize(entry.selected_list:GetWidth(), item_h)
        end
    end
end

local function _wallet_selector_rebuild_lists(entry)
    local active_list, active_token = _wallet_selector_current_token(entry)
    local selected_known = {}

    entry.selected_entries = {}
    for i = 1, #entry.selected_items do
        local value = entry.selected_items[i]
        local resolved = S.resolve_wallet_item_selection(value)
        if resolved ~= nil then
            entry.selected_entries[#entry.selected_entries + 1] = resolved
            selected_known[resolved] = true
        end
    end

    entry.available_entries = {}
    for i = 1, #S.WALLET_ITEMS do
        local spec = S.WALLET_ITEMS[i]
        if selected_known[spec] ~= true and _wallet_selector_matches_filter(spec, entry.filter_text) == true then
            entry.available_entries[#entry.available_entries + 1] = spec
        end
    end
    table.sort(entry.available_entries, _wallet_selector_compare_entries)

    entry.available_list:ClearItems()
    entry.available_buttons = {}
    for i = 1, #entry.available_entries do
        local spec = entry.available_entries[i]
        local button = UI.Widgets.LuiButton()
        button:set_scale(State.settings.global.scale)
        button:set_font(entry.window.input_font)
        button:set_border_thickness(0)
        button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleLeft)
        button:set_text(spec)
        button.Click = function()
            _wallet_selector_select(entry, "available", i)
        end
        entry.available_buttons[i] = button
        entry.available_list:AddItem(button)
    end

    entry.selected_list:ClearItems()
    entry.selected_buttons = {}
    for i = 1, #entry.selected_entries do
        local resolved = entry.selected_entries[i]
        local button = UI.Widgets.LuiButton()
        button:set_scale(State.settings.global.scale)
        button:set_font(entry.window.input_font)
        button:set_border_thickness(0)
        button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleLeft)
        button:set_text(resolved)
        button.Click = function()
            _wallet_selector_select(entry, "selected", i)
        end
        entry.selected_buttons[i] = button
        entry.selected_list:AddItem(button)
    end

    entry.active_list = nil
    entry.available_index = nil
    entry.selected_index = nil

    if active_list == "available" and active_token ~= nil then
        for i = 1, #entry.available_entries do
            if entry.available_entries[i] == active_token then
                entry.active_list = "available"
                entry.available_index = i
                break
            end
        end
    elseif active_list == "selected" and active_token ~= nil then
        for i = 1, #entry.selected_items do
            if entry.selected_items[i] == active_token then
                entry.active_list = "selected"
                entry.selected_index = i
                break
            end
        end
    end

    _wallet_selector_layout(entry)
    _wallet_selector_sync_active(entry)
end

local function _wallet_selector_add(entry)
    local index = entry.available_index
    if entry.active_list ~= "available" or type(index) ~= "number" then
        return
    end

    local spec = entry.available_entries[index]
    if spec == nil then
        return
    end

    entry.selected_items[#entry.selected_items + 1] = spec
    entry.active_list = "selected"
    entry.selected_index = #entry.selected_items
    entry.available_index = nil
    _wallet_selector_rebuild_lists(entry)
end

local function _wallet_selector_remove(entry)
    local index = entry.selected_index
    if entry.active_list ~= "selected" or type(index) ~= "number" then
        return
    end

    table.remove(entry.selected_items, index)
    if #entry.selected_items == 0 then
        entry.active_list = nil
        entry.selected_index = nil
    else
        entry.active_list = "selected"
        if index > #entry.selected_items then
            index = #entry.selected_items
        end
        entry.selected_index = index
    end
    entry.available_index = nil
    _wallet_selector_rebuild_lists(entry)
end

local function _wallet_selector_move(entry, direction)
    local index = entry.selected_index
    if entry.active_list ~= "selected" or type(index) ~= "number" then
        return
    end

    local target = index + direction
    if target < 1 or target > #entry.selected_items then
        return
    end

    local value = entry.selected_items[index]
    entry.selected_items[index] = entry.selected_items[target]
    entry.selected_items[target] = value
    entry.selected_index = target
    _wallet_selector_rebuild_lists(entry)
end

function StatusBarPage.create_wallet_selector(page, key)
    local entry = page:add_custom(key, WALLET_SELECTOR_HEIGHT)
    entry.window = page.window
    entry.selected_items = {}
    entry.available_entries = {}
    entry.selected_entries = {}
    entry.available_buttons = {}
    entry.selected_buttons = {}
    entry.filter_text = ""
    entry.active_list = nil
    entry.available_index = nil
    entry.selected_index = nil

    entry.available_label = UI.Widgets.LuiLabel()
    entry.available_label:SetParent(entry.control)
    entry.available_label:SetFont(page.window.field_label_font)
    entry.available_label:SetMultiline(true)
    entry.available_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.available_label:SetText(TR["All wallet items"])
    entry.available_label:SetZOrder(1)

    entry.selected_label = UI.Widgets.LuiLabel()
    entry.selected_label:SetParent(entry.control)
    entry.selected_label:SetFont(page.window.field_label_font)
    entry.selected_label:SetMultiline(true)
    entry.selected_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.selected_label:SetText(TR["Shown in %wallet%"])
    entry.selected_label:SetZOrder(1)

    entry.available_filter = UI.Widgets.LineEdit()
    entry.available_filter:SetParent(entry.control)
    entry.available_filter:SetFont(page.window.input_font)
    entry.available_filter:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.available_filter:SetZOrder(2)
    entry.available_filter:set_placeholder_text(TR["Search..."])
    entry.available_filter:SetText("")
    entry.available_filter.TextChanged = function()
        entry.filter_text = entry.available_filter:GetText() or ""
        _wallet_selector_rebuild_lists(entry)
    end

    entry.available_box = Turbine.UI.Control()
    entry.available_box:SetParent(entry.control)
    entry.available_box:SetBackColor(Style.CONTROL_BORDER)
    entry.available_box:SetMouseVisible(false)

    entry.available_fill = Turbine.UI.Control()
    entry.available_fill:SetParent(entry.available_box)
    entry.available_fill:SetBackColor(Style.BACKGROUND)
    entry.available_fill:SetMouseVisible(false)

    entry.available_list = Turbine.UI.ListBox()
    entry.available_list:SetParent(entry.available_fill)
    entry.available_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    entry.available_scroll = Turbine.UI.Lotro.ScrollBar()
    entry.available_scroll:SetParent(entry.available_fill)
    entry.available_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    entry.available_scroll:SetWidth(WALLET_SELECTOR_SCROLL_W)
    entry.available_list:SetVerticalScrollBar(entry.available_scroll)

    entry.selected_box = Turbine.UI.Control()
    entry.selected_box:SetParent(entry.control)
    entry.selected_box:SetBackColor(Style.CONTROL_BORDER)
    entry.selected_box:SetMouseVisible(false)

    entry.selected_fill = Turbine.UI.Control()
    entry.selected_fill:SetParent(entry.selected_box)
    entry.selected_fill:SetBackColor(Style.BACKGROUND)
    entry.selected_fill:SetMouseVisible(false)

    entry.selected_list = Turbine.UI.ListBox()
    entry.selected_list:SetParent(entry.selected_fill)
    entry.selected_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    entry.selected_scroll = Turbine.UI.Lotro.ScrollBar()
    entry.selected_scroll:SetParent(entry.selected_fill)
    entry.selected_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    entry.selected_scroll:SetWidth(WALLET_SELECTOR_SCROLL_W)
    entry.selected_list:SetVerticalScrollBar(entry.selected_scroll)

    entry.add_button = UI.Widgets.LuiButton()
    entry.add_button:SetParent(entry.control)
    entry.add_button:set_text(TR["Add"])
    entry.add_button.Click = function()
        _wallet_selector_add(entry)
    end

    entry.remove_button = UI.Widgets.LuiButton()
    entry.remove_button:SetParent(entry.control)
    entry.remove_button:set_text(TR["Remove"])
    entry.remove_button.Click = function()
        _wallet_selector_remove(entry)
    end

    entry.up_button = UI.Widgets.LuiButton()
    entry.up_button:SetParent(entry.control)
    entry.up_button:set_text(TR["Up"])
    entry.up_button.Click = function()
        _wallet_selector_move(entry, -1)
    end

    entry.down_button = UI.Widgets.LuiButton()
    entry.down_button:SetParent(entry.control)
    entry.down_button:set_text(TR["Down"])
    entry.down_button.Click = function()
        _wallet_selector_move(entry, 1)
    end

    entry.control.SizeChanged = function()
        _wallet_selector_layout(entry)
    end

    function entry:refresh_text()
        entry.available_filter:SetText(entry.available_filter:GetText() or "")
    end

    entry.apply_ui_scale = function()
        entry.available_label:SetFont(page.window.field_label_font)
        entry.selected_label:SetFont(page.window.field_label_font)
        entry.available_filter:SetFont(page.window.input_font)
        entry.add_button:set_scale(State.settings.global.scale)
        entry.add_button:set_font(page.window.settings_font)
        entry.remove_button:set_scale(State.settings.global.scale)
        entry.remove_button:set_font(page.window.settings_font)
        entry.up_button:set_scale(State.settings.global.scale)
        entry.up_button:set_font(page.window.settings_font)
        entry.down_button:set_scale(State.settings.global.scale)
        entry.down_button:set_font(page.window.settings_font)

        for i = 1, #entry.available_buttons do
            local button = entry.available_buttons[i]
            if button ~= nil then
                button:set_scale(State.settings.global.scale)
                button:set_font(page.window.input_font)
            end
        end

        for i = 1, #entry.selected_buttons do
            local button = entry.selected_buttons[i]
            if button ~= nil then
                button:set_scale(State.settings.global.scale)
                button:set_font(page.window.input_font)
            end
        end

        _wallet_selector_layout(entry)
    end

    function entry:set_items(items)
        self.selected_items = _wallet_selector_normalize_items(items)
        self.active_list = nil
        self.available_index = nil
        self.selected_index = nil
        _wallet_selector_rebuild_lists(self)
    end

    function entry:get_items()
        return _copy_list(self.selected_items)
    end

    entry:apply_ui_scale()
    entry:set_items({})
    return entry
end
