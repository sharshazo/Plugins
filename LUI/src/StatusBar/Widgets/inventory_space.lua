-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local class = _G.LUI.Core.class
local WidgetBase = _G.LUI.Features.StatusBar.WidgetBase
local InventorySpaceWidget = class(WidgetBase)
StatusBarWidgets.InventorySpaceWidget = InventorySpaceWidget

function InventorySpaceWidget:Constructor(widget_w, bar_h, font, icon_path, warn_color, content_alignment)
    WidgetBase.Constructor(self, "inventory_space", widget_w, bar_h, font,
        content_alignment or Turbine.UI.ContentAlignment.MiddleRight, icon_path)
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = self.player ~= nil and self.player.GetBackpack ~= nil and self.player:GetBackpack() or nil
    self._last_scan_at = 0
    self._scan_every = 1.0
    self._base_color = font ~= nil and font.color or nil
    self._last_color_key = nil
    self.warn_color = warn_color
end

function InventorySpaceWidget:update(now)
    if now - self._last_scan_at < self._scan_every then
        return
    end
    self._last_scan_at = now

    local used, total = self:_scan()
    if used == nil or total == nil then
        self:set_text("--/--")
        if self._base_color ~= nil then
            self.label:SetForeColor(self._base_color)
            self._last_color_key = "base"
        end
        return
    end

    self:set_text(string.format("%d/%d", used, total))

    if total <= 0 then
        if self._base_color ~= nil and self._last_color_key ~= "base" then
            self.label:SetForeColor(self._base_color)
            self._last_color_key = "base"
        end
        return
    end

    local free_ratio = (total - used) / total
    local wc = self.warn_color
    local key = "base"
    local c = self._base_color
    if free_ratio <= 0.10 then
        key = "red"
        c = wc.red
    elseif free_ratio <= 0.20 then
        key = "orange"
        c = wc.orange
    elseif free_ratio <= 0.30 then
        key = "yellow"
        c = wc.yellow
    end

    if key ~= self._last_color_key and c ~= nil then
        self.label:SetForeColor(c)
        self._last_color_key = key
    end
end

function InventorySpaceWidget:_scan()
    local bp = self.backpack
    if bp == nil or bp.GetSize == nil or bp.GetItem == nil then
        return nil, nil
    end

    local size = bp:GetSize() or 0
    if type(size) ~= "number" then
        size = tonumber(size) or 0
    end
    if size <= 0 then
        return 0, 0
    end

    local used = 0
    for i = 1, size do
        if bp:GetItem(i) ~= nil then
            used = used + 1
        end
    end

    return used, size
end
