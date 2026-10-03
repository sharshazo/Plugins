-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "LUI.src.UI.Widgets"

local S = _G.LUI.Features.StatusBar.Common
local Style = UI.Widgets.Style

local ItemCountWidget = class(Turbine.UI.Control)
StatusBarWidgets.ItemCountWidget = ItemCountWidget

local ITEM_ICON_GAP = 8
local ITEM_ICON_MARGIN = 2

local function _apply_font(label, font)
    label:SetMouseVisible(false)
    label:SetVisible(true)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    if font ~= nil then
        if font.lotro ~= nil then
            label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            label:SetOutlineColor(font.outline_color)
        end
    end
end

function ItemCountWidget:Constructor(item_name, widget_w, bar_h, font, icon_image_id)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "item"
    self.item_name = S.normalize_status_bar_item_name(item_name) or ""
    self.item_key = S.make_status_bar_item_registry_key(self.item_name)
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = nil
    self._last_scan_at = 0
    self._scan_every = 1.0
    self._last_quantity = nil
    self._icon_image_id = nil
    self._background_image_id = nil

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self:SetSize(widget_w, bar_h)

    self.icon_back = UI.Widgets.Image()
    self.icon_back:SetParent(self)
    self.icon_back:SetPosition(0, ITEM_ICON_MARGIN)
    self.icon_back:SetZOrder(1)
    self.icon_back:SetVisible(false)

    self.icon_fore = UI.Widgets.Image()
    self.icon_fore:SetParent(self)
    self.icon_fore:SetPosition(0, ITEM_ICON_MARGIN)
    self.icon_fore:SetZOrder(2)
    self.icon_fore:SetVisible(false)

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self)
    _apply_font(self.label, font)

    self.SizeChanged = function()
        self:_layout()
    end

    self:_set_icon(icon_image_id)
    self:_layout()
    self:_apply_quantity(0)
end

function ItemCountWidget:update(now)
    if now - self._last_scan_at < self._scan_every then
        return
    end
    self._last_scan_at = now

    self:_ensure_backpack()
    local quantity, icon_image_id, background_image_id = self:_scan()
    if icon_image_id ~= nil then
        self:_set_icon(icon_image_id)
    end
    if background_image_id ~= nil then
        self:_set_background(background_image_id)
    end
    self:_apply_quantity(quantity or 0)
end

function ItemCountWidget:destroy()
    self:SetVisible(false)
    if self.icon_fore ~= nil then self.icon_fore:SetVisible(false) end
    if self.icon_back ~= nil then self.icon_back:SetVisible(false) end
    if self.label ~= nil then self.label:SetVisible(false) end
    if self.icon_fore ~= nil then self.icon_fore:SetParent(nil) end
    if self.icon_back ~= nil then self.icon_back:SetParent(nil) end
    if self.label ~= nil then self.label:SetParent(nil) end
    self:SetParent(nil)
end

function ItemCountWidget:_ensure_backpack()
    if self.backpack ~= nil then
        return
    end

    local player = self.player
    if player == nil then
        player = Turbine.Gameplay.LocalPlayer.GetInstance()
        self.player = player
    end

    if player == nil or player.GetBackpack == nil then
        return
    end

    self.backpack = player:GetBackpack()
end

function ItemCountWidget:_item_matches(item_name)
    if item_name == nil or self.item_key == nil then
        return false
    end
    return S.make_status_bar_item_registry_key(item_name) == self.item_key
end

function ItemCountWidget:_scan()
    local backpack = self.backpack
    if backpack == nil or backpack.GetSize == nil or backpack.GetItem == nil then
        return 0, nil, nil
    end

    local total = 0
    local icon_image_id = nil
    local background_image_id = nil
    local size = backpack:GetSize() or 0

    for i = 1, size do
        local item = backpack:GetItem(i)
        if item ~= nil then
            local name = item.GetName ~= nil and item:GetName() or nil
            local current_item_info = item.GetItemInfo ~= nil and item:GetItemInfo() or nil
            if (name == nil or name == "") and current_item_info ~= nil and current_item_info.GetName ~= nil then
                name = current_item_info:GetName()
            end

            if self:_item_matches(name) == true then
                local quantity = item.GetQuantity ~= nil and item:GetQuantity() or 1
                if type(quantity) ~= "number" then
                    quantity = tonumber(quantity) or 0
                end
                if quantity > 0 then
                    total = total + quantity
                end

                if current_item_info ~= nil then
                    if icon_image_id == nil and current_item_info.GetIconImageID ~= nil then
                        icon_image_id = current_item_info:GetIconImageID()
                    end
                    if background_image_id == nil and current_item_info.GetBackgroundImageID ~= nil then
                        background_image_id = current_item_info:GetBackgroundImageID()
                    end
                    if background_image_id == nil and current_item_info.GetQualityImageID ~= nil then
                        background_image_id = current_item_info:GetQualityImageID()
                    end
                end
            end
        end
    end

    return total, icon_image_id, background_image_id
end

function ItemCountWidget:_set_icon(icon)
    if icon == self._icon_image_id then
        return
    end

    self._icon_image_id = icon
    self.icon_fore:set_icon(icon)
    self:_layout()
end

function ItemCountWidget:_set_background(background)
    if background == self._background_image_id then
        return
    end

    self._background_image_id = background
    self.icon_back:set_icon(background)
    self:_layout()
end

function ItemCountWidget:_apply_quantity(quantity)
    if quantity == self._last_quantity then
        return
    end
    self._last_quantity = quantity
    self.label:SetText(S.format_wallet_quantity(quantity))
end

function ItemCountWidget:_layout()
    local w, h = self:GetSize()
    local icon_size = h - ITEM_ICON_MARGIN * 2
    if icon_size < 0 then
        icon_size = 0
    end

    local show_icon = (self._icon_image_id ~= nil or self._background_image_id ~= nil) and icon_size > 0

    if show_icon == true then
        self.icon_fore:set_size(icon_size, icon_size)
        self.icon_back:set_size(icon_size, icon_size)
        self.icon_fore:SetVisible(self._icon_image_id ~= nil)
        self.icon_back:SetVisible(self._background_image_id ~= nil)
    else
        self.icon_back:SetVisible(false)
        self.icon_fore:SetVisible(false)
    end

    local text_x = 0
    if show_icon == true then
        text_x = icon_size + ITEM_ICON_GAP
    end

    self.label:SetPosition(text_x, 0)
    self.label:SetSize(math.max(0, w - text_x), h)
end
