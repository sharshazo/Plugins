-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Raid Manager window: the raid layout editor. Four group columns of six
-- cells each; drag a member onto an empty cell to move them, onto an
-- occupied cell to swap. The Share button encodes the layout into a chat
-- line the leader copy-pastes into raid chat; other LUI clients apply it
-- via the share listener.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local Vitals = _G.LUI.Features.Vitals
local UI = _G.LUI.UI
local Windows = _G.LUI.Runtime.Windows
local class = _G.LUI.Core.class
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local get_class_icon = _G.LUI.Utils.get_class_icon
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"
import "LUI.src.Vitals.group_snapshot"
import "LUI.src.Vitals.raid_config"
import "LUI.src.Vitals.raid_share_codec"

local Style = UI.Widgets.Style
local GroupSnapshot = Vitals.GroupSnapshot
local RaidConfig = Vitals.RaidConfig
local RaidShareCodec = Vitals.RaidShareCodec

local GROUP_COUNT = 4
local GROUP_SIZE = 6
local GROUP_KEYS = { "a", "b", "c", "d" }
local GROUP_TITLES = { "A", "B", "C", "D" }

local BASE_MARGIN = 12
local BASE_CELL_W = 140
local BASE_CELL_H = 24
local BASE_CELL_GAP_Y = 3
local BASE_GROUP_GAP_X = 10
local BASE_HEADER_H = 18
local BASE_SECTION_GAP = 10
local BASE_BUTTON_H = 21
local BASE_BUTTON_W = 130
local BASE_EDIT_H = 24
local BASE_INFO_H = 16
local BASE_ICON_SIZE = 16
local BASE_FONT_SIZE = 12
local DRAG_THRESHOLD = 4

---@class RaidConfigWindow : UI.Widgets.LuiWindow
local RaidConfigWindow = class(UI.Widgets.LuiWindow)
Vitals.RaidConfigWindow = RaidConfigWindow

function RaidConfigWindow:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self.lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    self._display = {}
    self._cell_rects = {}
    self._drag = nil
    self._positioned = false

    self:set_title(TR["Raid Manager"])
    self:set_resizable(false)
    self:enable_maximize(false)
    self:hide()
    self:SetMouseVisible(true)

    local central = Turbine.UI.Control()
    central:SetMouseVisible(true)
    self:set_central_widget(central)

    self.content = Turbine.UI.Control()
    self.content:SetParent(central)
    self.content:SetMouseVisible(true)

    self.headers = {}
    for group_index = 1, GROUP_COUNT do
        local header = UI.Widgets.LuiLabel()
        header:SetParent(self.content)
        header:SetMouseVisible(false)
        header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        header:SetText(TR["Raid Group "] .. GROUP_TITLES[group_index])
        self.headers[group_index] = header
    end

    self.cells = {}
    for slot = 1, RaidConfig.SLOT_COUNT do
        self.cells[slot] = self:_build_cell(slot)
    end

    self.ghost = Turbine.UI.Control()
    self.ghost:SetParent(self.content)
    self.ghost:SetMouseVisible(false)
    self.ghost:SetZOrder(100)
    self.ghost:SetBackColor(Style.SELECTION_BACKGROUND)
    self.ghost:SetVisible(false)
    self.ghost_label = UI.Widgets.LuiLabel()
    self.ghost_label:SetParent(self.ghost)
    self.ghost_label:SetMouseVisible(false)
    self.ghost_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.ghost_label:SetForeColor(Style.SELECTION_FOREGROUND)

    self.clear_button = UI.Widgets.LuiButton()
    self.clear_button:SetParent(self.content)
    self.clear_button:set_text(TR["Clear"])
    self.clear_button.Click = function()
        RaidConfig.clear()
        self:_layout_changed()
    end

    self.share_button = UI.Widgets.LuiButton()
    self.share_button:SetParent(self.content)
    self.share_button:set_text(TR["Share"])
    self.share_button.Click = function()
        self:_share()
    end

    self.share_edit = UI.Widgets.LuiLineEdit()
    self.share_edit:SetParent(self.content)
    self.share_edit:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.share_edit:set_placeholder_text(TR["Share produces a chat line here"])

    self.info_label = UI.Widgets.LuiLabel()
    self.info_label:SetParent(self.content)
    self.info_label:SetMouseVisible(false)
    self.info_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.info_label:SetForeColor(Style.INFO_FOREGROUND)
    self.info_label:SetText(TR["Copy the line into raid chat to share this layout."])

    self:apply_settings()
end

function RaidConfigWindow:_build_cell(slot)
    local cell = {}

    cell.control = Turbine.UI.Control()
    cell.control:SetParent(self.content)
    cell.control:SetMouseVisible(true)
    cell.control:SetBackColor(Style.CONTROL_BACKGROUND)

    cell.icon = UI.Widgets.Image()
    cell.icon:SetParent(cell.control)
    cell.icon:SetMouseVisible(false)
    cell.icon:SetVisible(false)

    cell.label = UI.Widgets.LuiLabel()
    cell.label:SetParent(cell.control)
    cell.label:SetMouseVisible(false)
    cell.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    cell.control.MouseDown = function(_, args)
        if args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if self._display[slot] == false then
            return
        end
        self._drag = {
            from = slot,
            start_x = args.X,
            start_y = args.Y,
            moved = false,
        }
    end

    cell.control.MouseMove = function(_, args)
        local drag = self._drag
        if drag == nil or drag.from ~= slot then
            return
        end
        if drag.moved ~= true then
            local dx = args.X - drag.start_x
            local dy = args.Y - drag.start_y
            if math.abs(dx) < DRAG_THRESHOLD and math.abs(dy) < DRAG_THRESHOLD then
                return
            end
            drag.moved = true
            self:_show_ghost(slot)
        end
        local rect = self._cell_rects[slot]
        self:_move_ghost(rect.x + args.X, rect.y + args.Y)
    end

    cell.control.MouseUp = function(_, args)
        local drag = self._drag
        self._drag = nil
        self.ghost:SetVisible(false)
        if drag == nil or drag.from ~= slot or drag.moved ~= true then
            return
        end
        local rect = self._cell_rects[slot]
        local target = self:_slot_at(rect.x + args.X, rect.y + args.Y)
        if target ~= nil and target ~= slot then
            self:_apply_drop(slot, target)
        end
    end

    return cell
end

function RaidConfigWindow:_scaled(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

function RaidConfigWindow:_scaled_font(size)
    local scale = State.settings.global.scale
    local font = FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, size * scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(Style.CONTROL_FONT_NAME) .. " " .. tostring(size * scale))
    end
    return font
end

function RaidConfigWindow:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)
    self:set_resizable(false)

    local margin = self:_scaled(BASE_MARGIN)
    local cell_w = self:_scaled(BASE_CELL_W)
    local cell_h = self:_scaled(BASE_CELL_H)
    local cell_gap_y = self:_scaled(BASE_CELL_GAP_Y)
    local group_gap_x = self:_scaled(BASE_GROUP_GAP_X)
    local header_h = self:_scaled(BASE_HEADER_H)
    local section_gap = self:_scaled(BASE_SECTION_GAP)
    local button_h = self:_scaled(BASE_BUTTON_H)
    local button_w = self:_scaled(BASE_BUTTON_W)
    local edit_h = self:_scaled(BASE_EDIT_H)
    local info_h = self:_scaled(BASE_INFO_H)
    local icon_size = self:_scaled(BASE_ICON_SIZE)
    local font = self:_scaled_font(BASE_FONT_SIZE)
    local scale = State.settings.global.scale

    self._icon_size = icon_size

    local grid_w = (GROUP_COUNT * cell_w) + ((GROUP_COUNT - 1) * group_gap_x)
    local grid_h = header_h + cell_gap_y + (GROUP_SIZE * (cell_h + cell_gap_y)) - cell_gap_y
    local content_w = grid_w
    local content_h = grid_h + section_gap + button_h + section_gap + edit_h + cell_gap_y + info_h

    -- window = content + margins + chrome
    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    local chrome_w = math.max(0, window_w - central_w)
    local chrome_h = math.max(0, window_h - central_h)
    self:SetSize(content_w + (2 * margin) + chrome_w, content_h + (2 * margin) + chrome_h)
    UI.Widgets.LuiWindow._layout(self)

    self.content:SetPosition(margin, margin)
    self.content:SetSize(content_w, content_h)

    local group_colors = State.settings.raid.group_colors
    for group_index = 1, GROUP_COUNT do
        local column_x = (group_index - 1) * (cell_w + group_gap_x)
        local header = self.headers[group_index]
        header:SetFont(font)
        header:SetForeColor(group_colors[GROUP_KEYS[group_index]])
        header:SetPosition(column_x, 0)
        header:SetSize(cell_w, header_h)

        for row = 1, GROUP_SIZE do
            local slot = ((group_index - 1) * GROUP_SIZE) + row
            local cell = self.cells[slot]
            local cell_y = header_h + cell_gap_y + ((row - 1) * (cell_h + cell_gap_y))
            cell.control:SetPosition(column_x, cell_y)
            cell.control:SetSize(cell_w, cell_h)
            cell.label:SetFont(font)
            local icon_y = math.floor((cell_h - icon_size) / 2)
            cell.icon:SetPosition(icon_y, icon_y)
            cell.icon:set_size(icon_size, icon_size)
            local label_x = icon_y + icon_size + self:_scaled(4)
            cell.label:SetPosition(label_x, 0)
            cell.label:SetSize(cell_w - label_x, cell_h)
            self._cell_rects[slot] = {
                x = column_x,
                y = cell_y,
                w = cell_w,
                h = cell_h,
            }
        end
    end

    self.ghost:SetSize(cell_w, cell_h)
    self.ghost_label:SetFont(font)
    self.ghost_label:SetSize(cell_w, cell_h)

    local buttons_y = grid_h + section_gap
    self.clear_button:set_scale(scale)
    self.clear_button:set_font(font)
    self.clear_button:SetPosition(0, buttons_y)
    self.clear_button:SetSize(button_w, button_h)
    self.share_button:set_scale(scale)
    self.share_button:set_font(font)
    self.share_button:SetPosition(content_w - button_w, buttons_y)
    self.share_button:SetSize(button_w, button_h)

    local edit_y = buttons_y + button_h + section_gap
    self.share_edit:set_scale(scale)
    self.share_edit:SetFont(font)
    self.share_edit:SetPosition(0, edit_y)
    self.share_edit:SetSize(content_w, edit_h)

    self.info_label:SetFont(font)
    self.info_label:SetPosition(0, edit_y + edit_h + cell_gap_y)
    self.info_label:SetSize(content_w, info_h)

    if self:IsVisible() == true then
        self:refresh_cells()
    end
end

function RaidConfigWindow:refresh_cells()
    local snapshot = GroupSnapshot.read(self.lp)
    self._display = RaidConfig.display_slots(snapshot)

    for slot = 1, RaidConfig.SLOT_COUNT do
        local cell = self.cells[slot]
        local display = self._display[slot]
        if display == false then
            cell.label:SetText("")
            cell.icon:SetVisible(false)
            cell.control:SetBackColor(Style.ALTERNATE_BACKGROUND)
        else
            cell.label:SetText(display.name)
            cell.control:SetBackColor(Style.CONTROL_BACKGROUND)
            if display.entity ~= nil then
                cell.label:SetForeColor(Style.FOREGROUND)
                self:_update_cell_icon(cell, display.entity)
            else
                -- assigned member currently absent from the roster
                cell.label:SetForeColor(Style.PLACEHOLDER_FOREGROUND)
                cell.icon:SetVisible(false)
            end
        end
    end
end

function RaidConfigWindow:_update_cell_icon(cell, entity)
    if entity.GetClass == nil then
        cell.icon:SetVisible(false)
        return
    end

    local icon = get_class_icon(entity:GetClass(), self._icon_size)
    if icon == nil then
        cell.icon:SetVisible(false)
        return
    end

    cell.icon:set_icon(icon, self._icon_size, self._icon_size)
    cell.icon:SetVisible(true)
end

function RaidConfigWindow:_show_ghost(slot)
    local display = self._display[slot]
    if display == false then
        return
    end
    self.ghost_label:SetText(display.name)
    self.ghost:SetVisible(true)
end

function RaidConfigWindow:_move_ghost(x, y)
    local width, height = self.ghost:GetSize()
    self.ghost:SetPosition(x - math.floor(width / 2), y - math.floor(height / 2))
end

function RaidConfigWindow:_slot_at(x, y)
    for slot = 1, RaidConfig.SLOT_COUNT do
        local rect = self._cell_rects[slot]
        if x >= rect.x and x < rect.x + rect.w and y >= rect.y and y < rect.y + rect.h then
            return slot
        end
    end
    return nil
end

function RaidConfigWindow:_apply_drop(from_slot, to_slot)
    local from_cell = self._display[from_slot]
    if from_cell == false or from_cell.name == nil then
        return
    end

    if RaidConfig.is_manual() ~= true then
        RaidConfig.seed_from_display(self._display)
    end

    local to_cell = self._display[to_slot]
    local to_name = nil
    if to_cell ~= false then
        to_name = to_cell.name
    end

    RaidConfig.apply_move(from_slot, from_cell.name, to_slot, to_name)
    self:_layout_changed()
end

function RaidConfigWindow:_layout_changed()
    self:refresh_cells()
    Windows.raid_vitals:update_members()
end

function RaidConfigWindow:_share()
    local names = {}
    for slot = 1, RaidConfig.SLOT_COUNT do
        local display = self._display[slot]
        if display ~= false then
            names[slot] = display.name
        end
    end

    local message = RaidShareCodec.encode(names)
    if message == nil then
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: " .. TR["Unable to encode the raid layout."])
        return
    end

    self.share_edit:SetText(message)
    self.share_edit:Focus()
end

function RaidConfigWindow:open()
    self:apply_settings()
    self:refresh_cells()

    if self._positioned ~= true then
        self._positioned = true
        local display_w, display_h = Turbine.UI.Display.GetSize()
        local width, height = self:GetSize()
        self:SetPosition(
            math.max(0, math.floor((display_w - width) / 2)),
            math.max(0, math.floor((display_h - height) / 2))
        )
    end

    self:show()
end
