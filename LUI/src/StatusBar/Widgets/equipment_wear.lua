-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Utils.callbacks"
local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local class = _G.LUI.Core.class
local S = _G.LUI.Features.StatusBar.Common
local WidgetBase = _G.LUI.Features.StatusBar.WidgetBase
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local _gradient_morale_color = lui_gradient_morale_color

local EquipmentWearWidget = class(WidgetBase)
StatusBarWidgets.EquipmentWearWidget = EquipmentWearWidget

function EquipmentWearWidget:Constructor(widget_w, bar_h, font, icon_path, wear_color, coloring, content_alignment)
    WidgetBase.Constructor(self, "equipment_wear", widget_w, bar_h, font,
        content_alignment or Turbine.UI.ContentAlignment.MiddleLeft, icon_path)
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.equipment = nil
    self._dirty = true
    self._item_callbacks_dirty = true
    self._last_scan_at = 0
    self._scan_every = 2.0
    self._equipment_callbacks = {}
    self._item_callbacks = {}
    self.wear_color = wear_color or {}
    self.coloring = coloring == true

    self:set_text("--% (--%)", false)
    self:_ensure_equipment()
end

function EquipmentWearWidget:update(now)
    self:_ensure_equipment()

    if self.equipment == nil then
        if now - self._last_scan_at < self._scan_every then
            return
        end
        self._last_scan_at = now
        self:set_text("--% (--%)", false)
        return
    end

    if self._dirty ~= true and now - self._last_scan_at < self._scan_every then
        return
    end

    self:_scan(now)
end

function EquipmentWearWidget:destroy()
    self:_detach_equipment_callbacks()
    self:_detach_item_callbacks()
    WidgetBase.destroy(self)
end

function EquipmentWearWidget:_mark_dirty()
    self._dirty = true
end

function EquipmentWearWidget:_mark_item_callbacks_dirty()
    self._item_callbacks_dirty = true
    self._dirty = true
end

function EquipmentWearWidget:_ensure_equipment()
    if self.equipment ~= nil then
        return
    end

    local player = self.player
    if player == nil then
        player = Turbine.Gameplay.LocalPlayer.GetInstance()
        self.player = player
    end

    if player == nil or player.GetEquipment == nil then
        return
    end

    local equipment = player:GetEquipment()
    if equipment == nil then
        return
    end

    self.equipment = equipment
    self:_attach_equipment_callbacks()
    self._item_callbacks_dirty = true
    self._dirty = true
end

function EquipmentWearWidget:_attach_equipment_callbacks()
    local equipment = self.equipment
    if equipment == nil then
        return
    end

    self:_detach_equipment_callbacks()

    local equipped_cb = add_callback(equipment, "ItemEquipped", function()
        self:_mark_item_callbacks_dirty()
    end)
    local unequipped_cb = add_callback(equipment, "ItemUnequipped", function()
        self:_mark_item_callbacks_dirty()
    end)

    self._equipment_callbacks = {
        { object = equipment, event = "ItemEquipped", callback = equipped_cb },
        { object = equipment, event = "ItemUnequipped", callback = unequipped_cb },
    }
end

function EquipmentWearWidget:_detach_equipment_callbacks()
    for i = 1, #self._equipment_callbacks do
        local cb = self._equipment_callbacks[i]
        if cb ~= nil and cb.object ~= nil and cb.callback ~= nil then
            remove_callback(cb.object, cb.event, cb.callback)
        end
    end
    self._equipment_callbacks = {}
end

function EquipmentWearWidget:_detach_item_callbacks()
    for i = 1, #self._item_callbacks do
        local cb = self._item_callbacks[i]
        if cb ~= nil and cb.object ~= nil and cb.callback ~= nil then
            remove_callback(cb.object, cb.event, cb.callback)
        end
    end
    self._item_callbacks = {}
end

function EquipmentWearWidget:_attach_item_callback(item)
    if item == nil then
        return
    end

    local cb = add_callback(item, "WearStateChanged", function()
        self:_mark_dirty()
    end)
    self._item_callbacks[#self._item_callbacks + 1] = {
        object = item,
        event = "WearStateChanged",
        callback = cb,
    }
end

function EquipmentWearWidget:_scan(now)
    self._dirty = false
    self._last_scan_at = now
    local rebind_item_callbacks = self._item_callbacks_dirty == true
    if rebind_item_callbacks then
        self:_detach_item_callbacks()
        self._item_callbacks_dirty = false
    end

    local equipment = self.equipment
    if equipment == nil or equipment.GetItem == nil then
        self:set_text("--% (--%)", false)
        return
    end

    local count = 0
    local sum = 0
    local weakest = nil

    for i = 1, #S.EQUIPMENT_SLOTS do
        local item = equipment:GetItem(S.EQUIPMENT_SLOTS[i])
        if item ~= nil then
            local percent = S.wear_state_to_percent(item:GetWearState())
            if percent ~= nil then
                count = count + 1
                sum = sum + percent
                if weakest == nil or percent < weakest then
                    weakest = percent
                end
                if rebind_item_callbacks then
                    self:_attach_item_callback(item)
                end
            end
        end
    end

    if count <= 0 or weakest == nil then
        self:set_text("--% (--%)", false)
        return
    end

    local average = S.round_nearest(sum / count)
    if self.coloring == true then
        local average_color = _gradient_morale_color(average / 100, self.wear_color.green, self.wear_color.yellow,
            self.wear_color.red)
        local weakest_color = _gradient_morale_color(weakest / 100, self.wear_color.green, self.wear_color.yellow,
            self.wear_color.red)
        self:set_text(
            S.color_markup(string.format("%d%%", average), average_color) ..
            " (" .. S.color_markup(string.format("%d%%", weakest), weakest_color) .. ")",
            true
        )
        return
    end

    self:set_text(string.format("%d%% (%d%%)", average, weakest), false)
end
