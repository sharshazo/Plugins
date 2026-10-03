-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local Controls = _G.LUI.Settings.Controls
local UI = _G.LUI.UI
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

local Style = UI.Widgets.Style

local SELECTOR_HEIGHT = 176
local GAP = 6
local BUTTON_W = 58
local BUTTON_H = 22
local SCROLL_W = 10
local MIN_LIST_W = 90
local BOX_PAD = 1

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local function _copy_list(items)
    local out = {}
    for i = 1, #items do
        out[i] = items[i]
    end
    return out
end

local function _label_for_key(defs, key)
    for i = 1, #defs do
        if defs[i].key == key then
            return defs[i].label
        end
    end
    error("Unknown launcher button key: " .. tostring(key))
end

local function _normalize_items(defs, items)
    local valid = {}
    for i = 1, #defs do
        valid[defs[i].key] = true
    end

    local out = {}
    local seen = {}
    for i = 1, #items do
        local key = items[i]
        if valid[key] == true and seen[key] ~= true then
            out[#out + 1] = key
            seen[key] = true
        end
    end
    return out
end

local function _current_key(entry)
    if entry.active_list == "available" then
        return entry.active_list, entry.available_items[entry.available_index]
    end
    if entry.active_list == "selected" then
        return entry.active_list, entry.selected_items[entry.selected_index]
    end
    return nil, nil
end

local function _sync_active(entry)
    local available_index = nil
    if entry.active_list == "available" then
        available_index = entry.available_index
    end

    local selected_index = nil
    if entry.active_list == "selected" then
        selected_index = entry.selected_index
    end

    for i = 1, #entry.available_buttons do
        entry.available_buttons[i]:set_active(i == available_index)
    end

    for i = 1, #entry.selected_buttons do
        entry.selected_buttons[i]:set_active(i == selected_index)
    end

    entry.add_button:set_enabled(available_index ~= nil)
    entry.remove_button:set_enabled(selected_index ~= nil)
    entry.up_button:set_enabled(selected_index ~= nil and selected_index > 1)
    entry.down_button:set_enabled(selected_index ~= nil and selected_index < #entry.selected_items)
end

local function _select(entry, list_name, index)
    entry.active_list = list_name
    if list_name == "available" then
        entry.available_index = index
        entry.selected_index = nil
    elseif list_name == "selected" then
        entry.selected_index = index
        entry.available_index = nil
    else
        error("Invalid launcher selector list: " .. tostring(list_name))
    end
    _sync_active(entry)
end

local function _layout(entry)
    local w, h = entry.control:GetSize()
    local gap = _scaled_int(GAP)
    local label_h = entry.window.field_label_height
    local button_w = _scaled_int(BUTTON_W)
    local button_h = _scaled_int(BUTTON_H)
    local item_h = entry.window.input_height
    local min_list_w = _scaled_int(MIN_LIST_W)
    local box_pad = _scaled_int(BOX_PAD)

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

    local box_top = label_h + gap
    local box_h = h - box_top
    if box_h < item_h + (box_pad * 2) then
        box_h = item_h + (box_pad * 2)
    end
    local list_h = box_h - (box_pad * 2)
    local available_fill_w = math.max(0, available_w - (box_pad * 2))
    local selected_fill_w = math.max(0, selected_w - (box_pad * 2))

    entry.available_label:SetPosition(available_x, 0)
    entry.available_label:SetSize(available_w, label_h)
    entry.selected_label:SetPosition(selected_x, 0)
    entry.selected_label:SetSize(selected_w, label_h)

    entry.available_box:SetPosition(available_x, box_top)
    entry.available_box:SetSize(available_w, box_h)
    entry.available_fill:SetPosition(box_pad, box_pad)
    entry.available_fill:SetSize(available_fill_w, list_h)
    entry.available_list:SetPosition(0, 0)
    entry.available_list:SetSize(math.max(0, entry.available_fill:GetWidth() - SCROLL_W), list_h)
    entry.available_scroll:SetPosition(math.max(0, entry.available_fill:GetWidth() - SCROLL_W), 0)
    entry.available_scroll:SetSize(SCROLL_W, list_h)

    entry.selected_box:SetPosition(selected_x, box_top)
    entry.selected_box:SetSize(selected_w, box_h)
    entry.selected_fill:SetPosition(box_pad, box_pad)
    entry.selected_fill:SetSize(selected_fill_w, list_h)
    entry.selected_list:SetPosition(0, 0)
    entry.selected_list:SetSize(math.max(0, entry.selected_fill:GetWidth() - SCROLL_W), list_h)
    entry.selected_scroll:SetPosition(math.max(0, entry.selected_fill:GetWidth() - SCROLL_W), 0)
    entry.selected_scroll:SetSize(SCROLL_W, list_h)

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

    for i = 1, #entry.available_buttons do
        entry.available_buttons[i]:SetSize(entry.available_list:GetWidth(), item_h)
    end

    for i = 1, #entry.selected_buttons do
        entry.selected_buttons[i]:SetSize(entry.selected_list:GetWidth(), item_h)
    end
end

local function _rebuild_lists(entry)
    local active_list, active_key = _current_key(entry)
    local selected = {}
    for i = 1, #entry.selected_items do
        selected[entry.selected_items[i]] = true
    end

    entry.available_items = {}
    for i = 1, #entry.definitions do
        local key = entry.definitions[i].key
        if selected[key] ~= true then
            entry.available_items[#entry.available_items + 1] = key
        end
    end

    entry.available_list:ClearItems()
    entry.available_buttons = {}
    for i = 1, #entry.available_items do
        local key = entry.available_items[i]
        local button = UI.Widgets.LuiButton()
        button:set_scale(State.settings.global.scale)
        button:set_font(entry.window.input_font)
        button:set_border_thickness(0)
        button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleLeft)
        button:set_text(_label_for_key(entry.definitions, key))
        button.Click = function()
            _select(entry, "available", i)
        end
        entry.available_buttons[i] = button
        entry.available_list:AddItem(button)
    end

    entry.selected_list:ClearItems()
    entry.selected_buttons = {}
    for i = 1, #entry.selected_items do
        local key = entry.selected_items[i]
        local button = UI.Widgets.LuiButton()
        button:set_scale(State.settings.global.scale)
        button:set_font(entry.window.input_font)
        button:set_border_thickness(0)
        button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleLeft)
        button:set_text(_label_for_key(entry.definitions, key))
        button.Click = function()
            _select(entry, "selected", i)
        end
        entry.selected_buttons[i] = button
        entry.selected_list:AddItem(button)
    end

    entry.active_list = nil
    entry.available_index = nil
    entry.selected_index = nil

    if active_list == "available" and active_key ~= nil then
        for i = 1, #entry.available_items do
            if entry.available_items[i] == active_key then
                entry.active_list = "available"
                entry.available_index = i
                break
            end
        end
    elseif active_list == "selected" and active_key ~= nil then
        for i = 1, #entry.selected_items do
            if entry.selected_items[i] == active_key then
                entry.active_list = "selected"
                entry.selected_index = i
                break
            end
        end
    end

    _layout(entry)
    _sync_active(entry)
end

local function _add_selected(entry)
    local key = entry.available_items[entry.available_index]
    if entry.active_list ~= "available" or key == nil then
        return
    end

    entry.selected_items[#entry.selected_items + 1] = key
    entry.active_list = "selected"
    entry.selected_index = #entry.selected_items
    entry.available_index = nil
    _rebuild_lists(entry)
end

local function _remove_selected(entry)
    if entry.active_list ~= "selected" or entry.selected_index == nil then
        return
    end

    local index = entry.selected_index
    table.remove(entry.selected_items, index)
    entry.available_index = nil
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
    _rebuild_lists(entry)
end

local function _move_selected(entry, direction)
    if entry.active_list ~= "selected" or entry.selected_index == nil then
        return
    end

    local index = entry.selected_index
    local target = index + direction
    if target < 1 or target > #entry.selected_items then
        return
    end

    local value = entry.selected_items[index]
    entry.selected_items[index] = entry.selected_items[target]
    entry.selected_items[target] = value
    entry.selected_index = target
    _rebuild_lists(entry)
end

function Controls.CreateLauncherButtonSelector(page, key, definitions)
    local entry = page:add_custom(key, SELECTOR_HEIGHT)
    entry.window = page.window
    entry.definitions = definitions
    entry.selected_items = {}
    entry.available_items = {}
    entry.available_buttons = {}
    entry.selected_buttons = {}
    entry.active_list = nil
    entry.available_index = nil
    entry.selected_index = nil

    entry.available_label = UI.Widgets.LuiLabel()
    entry.available_label:SetParent(entry.control)
    entry.available_label:SetFont(page.window.field_label_font)
    entry.available_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.available_label:SetText(TR["Available"])

    entry.selected_label = UI.Widgets.LuiLabel()
    entry.selected_label:SetParent(entry.control)
    entry.selected_label:SetFont(page.window.field_label_font)
    entry.selected_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.selected_label:SetText(TR["Shown in menu"])

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
    entry.available_scroll:SetWidth(SCROLL_W)
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
    entry.selected_scroll:SetWidth(SCROLL_W)
    entry.selected_list:SetVerticalScrollBar(entry.selected_scroll)

    entry.add_button = UI.Widgets.LuiButton()
    entry.add_button:SetParent(entry.control)
    entry.add_button:set_text(TR["Add"])
    entry.add_button.Click = function()
        _add_selected(entry)
    end

    entry.remove_button = UI.Widgets.LuiButton()
    entry.remove_button:SetParent(entry.control)
    entry.remove_button:set_text(TR["Remove"])
    entry.remove_button.Click = function()
        _remove_selected(entry)
    end

    entry.up_button = UI.Widgets.LuiButton()
    entry.up_button:SetParent(entry.control)
    entry.up_button:set_text(TR["Up"])
    entry.up_button.Click = function()
        _move_selected(entry, -1)
    end

    entry.down_button = UI.Widgets.LuiButton()
    entry.down_button:SetParent(entry.control)
    entry.down_button:set_text(TR["Down"])
    entry.down_button.Click = function()
        _move_selected(entry, 1)
    end

    entry.control.SizeChanged = function()
        _layout(entry)
    end

    entry.apply_ui_scale = function()
        entry.available_label:SetFont(page.window.field_label_font)
        entry.selected_label:SetFont(page.window.field_label_font)
        entry.add_button:set_scale(State.settings.global.scale)
        entry.add_button:set_font(page.window.settings_font)
        entry.remove_button:set_scale(State.settings.global.scale)
        entry.remove_button:set_font(page.window.settings_font)
        entry.up_button:set_scale(State.settings.global.scale)
        entry.up_button:set_font(page.window.settings_font)
        entry.down_button:set_scale(State.settings.global.scale)
        entry.down_button:set_font(page.window.settings_font)

        for i = 1, #entry.available_buttons do
            entry.available_buttons[i]:set_scale(State.settings.global.scale)
            entry.available_buttons[i]:set_font(page.window.input_font)
        end

        for i = 1, #entry.selected_buttons do
            entry.selected_buttons[i]:set_scale(State.settings.global.scale)
            entry.selected_buttons[i]:set_font(page.window.input_font)
        end

        _layout(entry)
    end

    function entry:set_items(items)
        self.selected_items = _normalize_items(self.definitions, items)
        self.active_list = nil
        self.available_index = nil
        self.selected_index = nil
        _rebuild_lists(self)
    end

    function entry:get_items()
        return _copy_list(self.selected_items)
    end

    entry:apply_ui_scale()
    entry:set_items({})
    return entry
end
