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

local WalletWidget = class(Turbine.UI.Control)
StatusBarWidgets.WalletWidget = WalletWidget

local ITEM_GAP = 6
local MIN_FIELD_W = 20

local function _apply_font(label, font, alignment)
    label:SetMouseVisible(false)
    label:SetVisible(true)
    label:SetTextAlignment(alignment)
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

local function _apply_wallet_icon_background(item, background, from_wallet)
    if item == nil or item.icon == nil or background == nil then
        return false
    end
    if from_wallet == true and item.icon_from_wallet == true then
        return false
    end
    if from_wallet ~= true and item.icon_background == background then
        return false
    end

    item.icon_background = background
    item.icon_from_wallet = from_wallet == true
    item.icon:set_icon(background)
    return true
end

function WalletWidget:Constructor(widget_w, bar_h, font, content_alignment, items)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "wallet"
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.wallet = nil
    self._last_scan_at = 0
    self._scan_every = 1.0
    self._icon_requested = true
    self._render_use_icons = false
    self._content_alignment = content_alignment or Turbine.UI.ContentAlignment.MiddleRight
    self._entries = S.get_wallet_selection_entries(items)
    self._item_controls = {}
    self._last_values = nil

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self:SetSize(widget_w, bar_h)

    self.placeholder = UI.Widgets.LuiLabel()
    self.placeholder:SetParent(self)
    _apply_font(self.placeholder, font, self._content_alignment)

    for i = 1, #self._entries do
        local entry = self._entries[i]
        local item = {
            name = entry,
            icon = nil,
            icon_background = nil,
            icon_from_wallet = false,
            label = UI.Widgets.LuiLabel(),
        }

        item.label:SetParent(self)
        _apply_font(item.label, font, self._content_alignment)

        if self._icon_requested == true then
            item.icon = UI.Widgets.Image(item.icon_background)
            item.icon:SetParent(self)
            if item.icon_background ~= nil then
                _apply_wallet_icon_background(item, item.icon_background, false)
            end
            item.icon:SetVisible(false)
        end

        self._item_controls[#self._item_controls + 1] = item
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self:_layout()
    self:_apply_values(nil)
end

function WalletWidget:update(now)
    if now - self._last_scan_at < self._scan_every then
        return
    end
    self._last_scan_at = now

    self:_ensure_wallet()
    self:_apply_values(self:_scan())
end

function WalletWidget:destroy()
    if self.placeholder ~= nil then
        self.placeholder:SetVisible(false)
        self.placeholder:SetParent(nil)
    end
    self:SetVisible(false)
    for i = 1, #self._item_controls do
        local item = self._item_controls[i]
        if item ~= nil then
            if item.icon ~= nil then
                item.icon:SetVisible(false)
                item.icon:SetParent(nil)
            end
            if item.label ~= nil then
                item.label:SetVisible(false)
                item.label:SetParent(nil)
            end
        end
    end
    self:SetParent(nil)
end

function WalletWidget:_ensure_wallet()
    if self.wallet ~= nil then
        return
    end

    local player = self.player
    if player == nil then
        player = Turbine.Gameplay.LocalPlayer.GetInstance()
        self.player = player
    end

    if player == nil or player.GetWallet == nil then
        return
    end

    self.wallet = player:GetWallet()
end

function WalletWidget:_scan()
    local wallet = self.wallet
    if wallet == nil or wallet.GetSize == nil or wallet.GetItem == nil then
        return nil
    end

    local size = wallet:GetSize() or 0
    if type(size) ~= "number" then
        size = tonumber(size) or 0
    end

    local values = {}
    for i = 1, #self._item_controls do
        values[i] = 0
    end

    local layout_dirty = false

    for i = 1, size do
        local item = wallet:GetItem(i)
        if item ~= nil and item.GetName ~= nil then
            local wallet_name = item:GetName()
            local quantity = item.GetQuantity ~= nil and item:GetQuantity() or 0
            if type(quantity) ~= "number" then
                quantity = tonumber(quantity) or 0
            end

            for j = 1, #self._item_controls do
                if S.wallet_item_matches(self._item_controls[j].name, wallet_name) == true then
                    values[j] = quantity
                    if item.GetImage ~= nil then
                        local image = item:GetImage()
                        if image ~= nil then
                            if _apply_wallet_icon_background(self._item_controls[j], image, true) == true then
                                layout_dirty = true
                            end
                        end
                    end
                    break
                end
            end
        end
    end

    if layout_dirty == true then
        self:_layout()
    end

    return values
end

function WalletWidget:_layout()
    local count = #self._item_controls
    local w, h = self:GetSize()

    self.placeholder:SetPosition(0, 0)
    self.placeholder:SetSize(w, h)
    self.placeholder:SetVisible(false)

    if count == 0 then
        self._render_use_icons = false
        for i = 1, #self._item_controls do
            local item = self._item_controls[i]
            if item.icon ~= nil then item.icon:SetVisible(false) end
            item.label:SetVisible(false)
        end
        self.placeholder:SetVisible(true)
        self.placeholder:SetText(self._last_values == nil and "--" or "")
        return
    end

    local icon_h = S.get_icon_size(h)
    local use_icons = self._icon_requested == true and icon_h > 0
    local icon_total = 0
    local icon_gap_total = 0
    local icon_widths = {}

    if use_icons == true then
        for i = 1, count do
            local item = self._item_controls[i]
            local icon_w = 0
            if item.icon ~= nil and item.icon_background ~= nil then
                icon_w = item.icon:set_height(icon_h)
                if icon_w > 0 then
                    icon_total = icon_total + icon_w
                    icon_gap_total = icon_gap_total + S.ICON_GAP
                end
            end
            icon_widths[i] = icon_w
        end
    end

    local gap_total = ITEM_GAP * math.max(0, count - 1)
    local label_total = w - gap_total - icon_total - icon_gap_total
    if use_icons == true and label_total < (count * MIN_FIELD_W) then
        use_icons = false
        icon_total = 0
        icon_gap_total = 0
        label_total = w - gap_total
    end

    if label_total < 0 then
        label_total = 0
    end

    self._render_use_icons = use_icons

    local slot_total = math.max(0, w - gap_total)
    local slot_w = count > 0 and math.floor(slot_total / count) or 0
    local extra = count > 0 and (slot_total - (slot_w * count)) or 0
    local x = 0
    local icon_y = S.get_centered_icon_y(h, icon_h)
    local label_pad = math.max(8, math.floor(h * 0.40))

    for i = 1, count do
        local item = self._item_controls[i]
        local icon_w = use_icons == true and (icon_widths[i] or 0) or 0

        local text = self._last_values ~= nil and S.format_wallet_quantity(self._last_values[i]) or "--"
        if self._render_use_icons ~= true or item.icon_background == nil then
            text = item.name .. " " .. text
        end
        item.label:SetText(text)

        local current_w = slot_w
        if extra > 0 then
            current_w = current_w + 1
            extra = extra - 1
        end

        local label_w = 0
        if text ~= "" then
            local text_chars = string.len(text)
            local char_w = math.max(6, math.floor(h * 0.55))
            label_w = (text_chars * char_w) + label_pad
            if label_w <= 0 then
                label_w = MIN_FIELD_W
            elseif label_w < MIN_FIELD_W then
                label_w = MIN_FIELD_W
            end
        end

        local icon_gap = icon_w > 0 and label_w > 0 and S.ICON_GAP or 0
        local max_label_w = current_w - icon_w - icon_gap
        if max_label_w < 0 then
            max_label_w = 0
        end
        if label_w > max_label_w then
            label_w = max_label_w
        end

        local group_w = icon_w + icon_gap + label_w
        local slot_x = x
        local group_x = slot_x + math.floor((current_w - group_w) / 2)
        if group_x < slot_x then
            group_x = slot_x
        end

        if item.icon ~= nil then
            if icon_w > 0 then
                item.icon:SetPosition(group_x, icon_y)
                item.icon:SetVisible(true)
            else
                item.icon:SetVisible(false)
            end
        end

        if label_w > 0 then
            local label_x = group_x + icon_w + icon_gap
            local label_slot_w = (slot_x + current_w) - label_x
            if label_slot_w < 0 then
                label_slot_w = 0
            end
            item.label:SetPosition(label_x, 0)
            item.label:SetSize(label_slot_w, h)
            item.label:SetVisible(label_slot_w > 0)
        else
            item.label:SetVisible(false)
        end

        x = slot_x + current_w

        if i < count then
            x = x + ITEM_GAP
        end
    end
end

function WalletWidget:_apply_values(values)
    self._last_values = values
    self:_layout()
end
