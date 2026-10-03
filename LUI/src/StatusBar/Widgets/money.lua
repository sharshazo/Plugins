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
local TR = _G.LUI.Locale.TR

local TIP_PAD_X = 6
local TIP_PAD_Y = 4
local TIP_SECTION_GAP = 2
local TIP_GROUP_GAP = 6
local TIP_ICON_GAP = 3
local TIP_GAIN_TEXT = Turbine.UI.Color(1.00, 0.55, 0.92, 0.55)
local TIP_LOSS_TEXT = Turbine.UI.Color(1.00, 0.88, 0.35, 0.35)

local function _rough_text_width(text, h)
    local count = string.len(tostring(text or ""))
    return math.max(math.floor(h * 1.6), math.floor(count * math.max(6, h * 0.34)))
end

local function _apply_widget_font(label, font)
    if font == nil then
        return
    end
    if font.lotro ~= nil then
        label:SetFont(font.lotro)
    end
    if font.style ~= nil then
        label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
    end
    if font.outline_color ~= nil then
        label:SetOutlineColor(font.outline_color)
    end
end

local MoneyWidget = class(Turbine.UI.Control)
StatusBarWidgets.MoneyWidget = MoneyWidget

function MoneyWidget:Constructor(widget_w, bar_h, font, content_alignment)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "money"
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self._last_total = nil
    self._content_alignment = content_alignment or Turbine.UI.ContentAlignment.MiddleRight

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self:SetSize(widget_w, bar_h)

    self.g_icon = UI.Widgets.Image(S.GOLD_ICON)
    self.g_icon:SetParent(self)
    self.g_icon:SetVisible(false)

    self.s_icon = UI.Widgets.Image(S.SILVER_ICON)
    self.s_icon:SetParent(self)
    self.s_icon:SetVisible(false)

    self.c_icon = UI.Widgets.Image(S.COPPER_ICON)
    self.c_icon:SetParent(self)
    self.c_icon:SetVisible(false)

    self.g_label = UI.Widgets.LuiLabel()
    self.g_label:SetParent(self)
    self.g_label:SetMouseVisible(false)
    self.g_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.g_label:SetVisible(true)
    if font ~= nil then
        if font.lotro ~= nil then
            self.g_label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.g_label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.g_label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.g_label:SetOutlineColor(font.outline_color)
        end
    end

    self.s_label = UI.Widgets.LuiLabel()
    self.s_label:SetParent(self)
    self.s_label:SetMouseVisible(false)
    self.s_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.s_label:SetVisible(true)
    if font ~= nil then
        if font.lotro ~= nil then
            self.s_label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.s_label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.s_label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.s_label:SetOutlineColor(font.outline_color)
        end
    end

    self.c_label = UI.Widgets.LuiLabel()
    self.c_label:SetParent(self)
    self.c_label:SetMouseVisible(false)
    self.c_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.c_label:SetVisible(true)
    if font ~= nil then
        if font.lotro ~= nil then
            self.c_label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.c_label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.c_label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.c_label:SetOutlineColor(font.outline_color)
        end
    end

    self._interaction_enabled = true
    self._tooltip = UI.Widgets.LuiTooltip()
    self._tooltip:SetZOrder(2200)

    self._tip_inner = Turbine.UI.Control()
    self._tip_inner:SetParent(self._tooltip:GetContentHost())
    self._tip_inner:SetMouseVisible(false)

    self._tip_header = UI.Widgets.LuiLabel()
    self._tip_header:SetParent(self._tip_inner)
    self._tip_header:SetMouseVisible(false)
    self._tip_header:SetMultiline(false)
    self._tip_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self._tip_header:SetForeColor(Style.FOREGROUND)
    self._tip_header:SetText(TR["Session earnings"])
    _apply_widget_font(self._tip_header, font)

    self._tip_sign = UI.Widgets.LuiLabel()
    self._tip_sign:SetParent(self._tip_inner)
    self._tip_sign:SetMouseVisible(false)
    self._tip_sign:SetMultiline(false)
    self._tip_sign:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self._tip_sign:SetVisible(false)
    _apply_widget_font(self._tip_sign, font)

    self._tip_coins = {}
    local coin_icons = { S.GOLD_ICON, S.SILVER_ICON, S.COPPER_ICON }
    for i = 1, 3 do
        local icon = UI.Widgets.Image(coin_icons[i])
        icon:SetParent(self._tip_inner)
        icon:SetMouseVisible(false)
        icon:SetVisible(false)

        local label = UI.Widgets.LuiLabel()
        label:SetParent(self._tip_inner)
        label:SetMouseVisible(false)
        label:SetMultiline(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        label:SetForeColor(Style.FOREGROUND)
        label:SetVisible(false)
        _apply_widget_font(label, font)

        self._tip_coins[i] = { icon = icon, label = label }
    end

    self.MouseEnter = function()
        self:_show_session_popup()
    end
    self.MouseLeave = function()
        self._tooltip:Hide()
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self:_layout()
end

function MoneyWidget:set_interaction_enabled(enabled)
    self._interaction_enabled = enabled == true
    if self._interaction_enabled ~= true then
        self._tooltip:Hide()
    end
end

function MoneyWidget:_show_session_popup()
    if self._interaction_enabled ~= true then
        self._tooltip:Hide()
        return
    end

    local delta = S.get_session_money_delta(self:_get_total_money())
    if delta == nil then
        self._tooltip:Hide()
        return
    end

    local row_h = math.max(16, self:GetHeight())
    local icon = S.get_icon_size(row_h)
    local icon_y = S.get_centered_icon_y(row_h, icon)

    local v = delta
    local sign_text = ""
    local amount_color = Style.FOREGROUND
    if v > 0 then
        sign_text = "+"
        amount_color = TIP_GAIN_TEXT
    elseif v < 0 then
        sign_text = "-"
        amount_color = TIP_LOSS_TEXT
        v = -v
    end

    local gold, silver, copper = S.split_money_copper(v)
    local amounts = { tostring(gold), tostring(silver), tostring(copper) }

    local coins_w = 0
    if sign_text ~= "" then
        coins_w = _rough_text_width(sign_text, row_h) + TIP_ICON_GAP
    end
    for i = 1, 3 do
        if i > 1 then
            coins_w = coins_w + TIP_GROUP_GAP
        end
        coins_w = coins_w + icon + TIP_ICON_GAP + _rough_text_width(amounts[i], row_h)
    end

    local header_w = _rough_text_width(self._tip_header:GetText(), row_h)
    local content_w = math.max(coins_w, header_w)
    local inner_w = content_w + (TIP_PAD_X * 2)
    local inner_h = (TIP_PAD_Y * 2) + row_h + TIP_SECTION_GAP + row_h
    local border = math.max(0, math.floor((tonumber(Style.BORDER_WIDTH_THIN) or 1) + 0.5))

    self._tooltip:ShowContentFor(self, inner_w + (border * 2), inner_h + (border * 2))
    self._tip_inner:SetPosition(0, 0)
    self._tip_inner:SetSize(inner_w, inner_h)

    local y = TIP_PAD_Y
    self._tip_header:SetPosition(TIP_PAD_X, y)
    self._tip_header:SetSize(math.max(0, inner_w - (TIP_PAD_X * 2)), row_h)
    y = y + row_h + TIP_SECTION_GAP

    local x = TIP_PAD_X
    if sign_text ~= "" then
        local sign_w = _rough_text_width(sign_text, row_h)
        self._tip_sign:SetText(sign_text)
        self._tip_sign:SetForeColor(amount_color)
        self._tip_sign:SetPosition(x, y)
        self._tip_sign:SetSize(sign_w, row_h)
        self._tip_sign:SetVisible(true)
        x = x + sign_w + TIP_ICON_GAP
    else
        self._tip_sign:SetVisible(false)
    end

    for i = 1, 3 do
        local coin = self._tip_coins[i]
        coin.icon:SetPosition(x, y + icon_y)
        coin.icon:set_size(icon, icon)
        coin.icon:SetVisible(true)
        x = x + icon + TIP_ICON_GAP

        local amount_w = _rough_text_width(amounts[i], row_h)
        coin.label:SetText(amounts[i])
        coin.label:SetForeColor(amount_color)
        coin.label:SetPosition(x, y)
        coin.label:SetSize(amount_w, row_h)
        coin.label:SetVisible(true)
        x = x + amount_w + TIP_GROUP_GAP
    end
end

function MoneyWidget:update(now)
    local total = self:_get_total_money()
    S.note_session_start_money(total)
    if total == self._last_total then
        return
    end
    self._last_total = total

    local gold, silver, copper = S.split_money_copper(total)
    if gold == nil then
        self.g_label:SetText("--")
        self.s_label:SetText("--")
        self.c_label:SetText("--")
        self:_layout()
        return
    end

    self.g_label:SetText(S.format_gold_compact(gold))
    self.s_label:SetText(tostring(silver))
    self.c_label:SetText(tostring(copper))
    self:_layout()
end

function MoneyWidget:destroy()
    self._tooltip:Hide()
    self._tooltip:SetParent(nil)
    self:SetVisible(false)
    if self.g_icon ~= nil then self.g_icon:SetVisible(false) end
    if self.s_icon ~= nil then self.s_icon:SetVisible(false) end
    if self.c_icon ~= nil then self.c_icon:SetVisible(false) end
    if self.g_label ~= nil then self.g_label:SetVisible(false) end
    if self.s_label ~= nil then self.s_label:SetVisible(false) end
    if self.c_label ~= nil then self.c_label:SetVisible(false) end
    if self.g_icon ~= nil then self.g_icon:SetParent(nil) end
    if self.s_icon ~= nil then self.s_icon:SetParent(nil) end
    if self.c_icon ~= nil then self.c_icon:SetParent(nil) end
    if self.g_label ~= nil then self.g_label:SetParent(nil) end
    if self.s_label ~= nil then self.s_label:SetParent(nil) end
    if self.c_label ~= nil then self.c_label:SetParent(nil) end
    self:SetParent(nil)
end

function MoneyWidget:_layout()
    local w, h = self:GetSize()
    local size = S.get_icon_size(h)
    if size <= 0 then
        self.g_icon:SetVisible(false)
        self.s_icon:SetVisible(false)
        self.c_icon:SetVisible(false)
        self.g_label:SetVisible(false)
        self.s_label:SetVisible(false)
        self.c_label:SetVisible(false)
        return
    end

    local gap = 4
    local fixed = (size * 3) + (gap * 5)
    local remaining = w - fixed
    if remaining < 0 then
        remaining = 0
    end
    local field_w = math.floor(remaining / 3)
    local extra = remaining - (field_w * 3)
    local g_w = field_w
    local s_w = field_w
    if extra > 0 then
        g_w = g_w + 1
        extra = extra - 1
    end
    if extra > 0 then
        s_w = s_w + 1
        extra = extra - 1
    end
    local c_w = field_w + extra
    local x = 0
    local y = S.get_centered_icon_y(h, size)

    self.g_icon:SetPosition(x, y)
    self.g_icon:set_size(size, size)
    self.g_icon:SetVisible(true)
    x = x + size + gap

    self.g_label:SetPosition(x, 0)
    self.g_label:SetSize(g_w, h)
    self.g_label:SetVisible(g_w > 0)
    x = x + g_w + gap

    self.s_icon:SetPosition(x, y)
    self.s_icon:set_size(size, size)
    self.s_icon:SetVisible(true)
    x = x + size + gap

    self.s_label:SetPosition(x, 0)
    self.s_label:SetSize(s_w, h)
    self.s_label:SetVisible(s_w > 0)
    x = x + s_w + gap

    self.c_icon:SetPosition(x, y)
    self.c_icon:set_size(size, size)
    self.c_icon:SetVisible(true)
    x = x + size + gap

    self.c_label:SetPosition(x, 0)
    self.c_label:SetSize(c_w, h)
    self.c_label:SetVisible(c_w > 0)
end

function MoneyWidget:_get_total_money()
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
