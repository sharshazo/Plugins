-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Shared visual building blocks for the bestiary and resource cards: the
-- common style constants, panel/text constructors and the clickable chip.
-- Both cards must stay visually locked together; card-specific dimensions
-- stay in their own files.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Encyclopedia = _G.LUI.Features.Encyclopedia
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets"

local Style = UI.Widgets.Style
local Shortcuts = UI.Shortcuts

local CardWidgets = {}
Encyclopedia.CardWidgets = CardWidgets

CardWidgets.BASE = {
    SECTION_GAP = 6,
    PANEL_HEADER_H = 20,
    PANEL_BODY_PAD_X = 8,
    PANEL_BODY_PAD_TOP = 4,
    PANEL_BODY_PAD_BOTTOM = 10,
    STAT_BOX_H = 52,
    TITLE_SIZE = 20,
    SECTION_TITLE_SIZE = 12,
    TEXT_SIZE = 11,
    OFFSET = 12,
    CHIP_H = 18,
    CHIP_PAD_X = 6,
    CHIP_GAP_X = 4,
    CHIP_GAP_Y = 4,
    CHIP_BORDER = 1,
    CHIP_CHAR_W = 5.8,
    TEXT_CHAR_W = 5.8,
    TEXT_LINE_H = 14,
    SCROLL_W = 10,
    SCROLL_GAP = 3,
}
local BASE = CardWidgets.BASE

local COLOR_DROP_CHIP_BORDER = Turbine.UI.Color(1, 0.28, 0.28, 0.28)
local COLOR_DROP_CHIP_BG = Turbine.UI.Color(1, 0.08, 0.08, 0.08)
local COLOR_DROP_CHIP_TEXT = Turbine.UI.Color(1, 0.76, 0.88, 0.79)
local COLOR_CHEST_CHIP_BORDER = Turbine.UI.Color(1, 0.45, 0.32, 0.12)
local COLOR_CHEST_CHIP_BG = Turbine.UI.Color(1, 0.08, 0.08, 0.08)
local COLOR_CHEST_CHIP_TEXT = Turbine.UI.Color(1, 0.95, 0.83, 0.49)
-- clickable chips (the chip resolves to a browsable item) get a distinct
-- steel-blue border; chest/rare chips keep a brighter gold instead
local COLOR_DROP_CHIP_LINK_BORDER = Turbine.UI.Color(1, 0.30, 0.52, 0.68)
local COLOR_CHEST_CHIP_LINK_BORDER = Turbine.UI.Color(1, 0.70, 0.52, 0.20)

function CardWidgets.scaled_size(value)
    return value * State.settings.global.scale
end

function CardWidgets.scaled_int(value)
    return math.floor(CardWidgets.scaled_size(value) + 0.5)
end

function CardWidgets.scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, CardWidgets.scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(CardWidgets.scaled_size(size)))
    end
    return font
end

function CardWidgets.style_text(text, font_name, font_size, color)
    local resolved_font_name = font_name == "Verdana" and Style.CONTROL_FONT_NAME or font_name
    text:SetFont(CardWidgets.scaled_font(resolved_font_name, font_size))
    text:SetFontStyle(Turbine.UI.FontStyle.Outline)
    text:SetOutlineColor(Style.TEXT_OUTLINE)
    text:SetForeColor(color)
end

function CardWidgets.create_text(parent, multiline, alignment)
    local text = UI.Widgets.LuiLabel()
    text:SetParent(parent)
    text:SetMouseVisible(false)
    text:SetSelectable(false)
    text:SetMultiline(multiline == true)
    text:SetFont(CardWidgets.scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 1))
    text:SetTextAlignment(alignment or Turbine.UI.ContentAlignment.TopLeft)
    return text
end

function CardWidgets.create_panel(parent, title_text)
    local panel = {}
    panel.frame = Turbine.UI.Control()
    panel.frame:SetParent(parent)
    panel.frame:SetMouseVisible(false)
    panel.header = Turbine.UI.Control()
    panel.header:SetParent(panel.frame)
    panel.header:SetMouseVisible(false)
    panel.body = Turbine.UI.Control()
    panel.body:SetParent(panel.frame)
    panel.body:SetMouseVisible(false)
    panel.title = CardWidgets.create_text(panel.header, false, Turbine.UI.ContentAlignment.MiddleLeft)
    panel.title:SetText(title_text or "")
    return panel
end

function CardWidgets.style_panel(panel)
    panel.frame:SetBackColor(Style.CONTROL_BORDER)
    panel.header:SetBackColor(Style.CONTROL_BACKGROUND)
    panel.body:SetBackColor(Style.PANEL_BACKGROUND)
    CardWidgets.style_text(panel.title, "Verdana", BASE.SECTION_TITLE_SIZE, Style.FOREGROUND)
end

function CardWidgets.layout_panel(panel, x, y, w, h)
    local header_h = CardWidgets.scaled_int(BASE.PANEL_HEADER_H)

    panel.frame:SetPosition(x, y)
    panel.frame:SetSize(w, h)
    panel.header:SetPosition(1, 1)
    panel.header:SetSize(math.max(1, w - 2), header_h)
    panel.body:SetPosition(1, header_h + 1)
    panel.body:SetSize(math.max(1, w - 2), math.max(1, h - header_h - 2))
    panel.title:SetPosition(CardWidgets.scaled_int(9), 0)
    panel.title:SetSize(math.max(1, panel.header:GetWidth() - CardWidgets.scaled_int(18)), header_h)
end

function CardWidgets.estimate_text_width(text, base_char_w)
    return math.floor((string.len(text or "") * base_char_w * State.settings.global.scale) + 0.5)
end

-- shared number/percent rendering for bestiary rows, cards and chips
-- (thousands grouped with spaces; percents trimmed to their precision)
function CardWidgets.format_number(value)
    local n = math.floor(value + 0.5)
    local text = tostring(math.abs(n))
    local out = {}
    local count = 0
    for i = #text, 1, -1 do
        count = count + 1
        out[#out + 1] = string.sub(text, i, i)
        if count == 3 and i > 1 then
            out[#out + 1] = " "
            count = 0
        end
    end

    local reversed = {}
    for i = #out, 1, -1 do
        reversed[#reversed + 1] = out[i]
    end

    local joined = table.concat(reversed)
    if n < 0 then
        return "-" .. joined
    end
    return joined
end

function CardWidgets.format_percent(value)
    local text
    if value >= 1 then
        text = string.format("%.1f", value)
    else
        text = string.format("%.2f", value)
    end

    text = text:gsub("(%..-)0+$", "%1")
    text = text:gsub("%.$", "")
    return text .. "%"
end

function CardWidgets.estimate_chip_width(text)
    local pad_x = CardWidgets.scaled_int(BASE.CHIP_PAD_X)
    local border_w = CardWidgets.scaled_int(BASE.CHIP_BORDER)
    return CardWidgets.estimate_text_width(text or "", BASE.CHIP_CHAR_W) + (2 * pad_x) + (2 * border_w)
end

-- rows of chips flowing left to right; entries are strings or
-- { text, chest, name } tables. Returns positioned entries + content height.
function CardWidgets.build_chip_layout(texts, max_width)
    local layout = {}
    local chip_h = CardWidgets.scaled_int(BASE.CHIP_H)
    local gap_x = CardWidgets.scaled_int(BASE.CHIP_GAP_X)
    local gap_y = CardWidgets.scaled_int(BASE.CHIP_GAP_Y)
    local x = 0
    local y = 0

    for i = 1, #texts do
        local item = texts[i]
        local text = type(item) == "table" and item.text or item
        local width = CardWidgets.estimate_chip_width(text)
        if width > max_width then
            width = max_width
        end

        if x > 0 and (x + width) > max_width then
            x = 0
            y = y + chip_h + gap_y
        end

        layout[#layout + 1] = {
            text = text,
            chest = type(item) == "table" and item.chest == true,
            name = type(item) == "table" and item.name or nil,
            x = x,
            y = y,
            w = width,
        }

        x = x + width + gap_x
    end

    if #layout == 0 then
        return layout, chip_h
    end

    return layout, y + chip_h
end

local DropChip = class(Turbine.UI.Control)
CardWidgets.DropChip = DropChip

function DropChip:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._link_name = nil
    self._chest = false

    self:SetMouseVisible(false)
    self:SetBackColor(COLOR_DROP_CHIP_BORDER)

    -- linkable chips: left click opens the Encyclopedia on the matching
    -- item tab, right click opens the item actions menu (Encyclopedia /
    -- recipe); the chip is only mouse-visible when a link target exists
    self.MouseClick = function(_, args)
        if self._link_name == nil or args == nil then
            return
        end
        if args.Button == Turbine.UI.MouseButton.Left then
            Shortcuts.open_encyclopedia_item_search(self._link_name)
        elseif args.Button == Turbine.UI.MouseButton.Right then
            UI.ItemActions.show_menu(self, args.X, args.Y, self._link_name)
        end
    end
    self.MouseEnter = function()
        if self._link_name ~= nil then
            self.label:SetForeColor(Style.FOREGROUND)
        end
    end
    self.MouseLeave = function()
        self:apply_settings(self._chest)
    end

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(false)
    self.inner:SetBackColor(COLOR_DROP_CHIP_BG)

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self.inner)
    self.label:SetMouseVisible(false)
    self.label:SetSelectable(false)
    self.label:SetMultiline(false)
    self.label:SetFont(CardWidgets.scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 1))
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
end

function DropChip:set_link(item_name)
    self._link_name = item_name
    self:SetMouseVisible(item_name ~= nil)
end

function DropChip:apply_settings(chest)
    self._chest = chest == true
    local linked = self._link_name ~= nil
    local border_w = CardWidgets.scaled_int(BASE.CHIP_BORDER)
    self.inner:SetPosition(border_w, border_w)
    if chest == true then
        self:SetBackColor(linked and COLOR_CHEST_CHIP_LINK_BORDER or COLOR_CHEST_CHIP_BORDER)
        self.inner:SetBackColor(COLOR_CHEST_CHIP_BG)
        CardWidgets.style_text(self.label, "Verdana", BASE.TEXT_SIZE, COLOR_CHEST_CHIP_TEXT)
    else
        self:SetBackColor(linked and COLOR_DROP_CHIP_LINK_BORDER or COLOR_DROP_CHIP_BORDER)
        self.inner:SetBackColor(COLOR_DROP_CHIP_BG)
        CardWidgets.style_text(self.label, "Verdana", BASE.TEXT_SIZE, COLOR_DROP_CHIP_TEXT)
    end
end

function DropChip:bind(text, width, height)
    local border_w = CardWidgets.scaled_int(BASE.CHIP_BORDER)
    local pad_x = CardWidgets.scaled_int(BASE.CHIP_PAD_X)

    self:SetSize(width, height)
    self.inner:SetSize(math.max(1, width - (2 * border_w)), math.max(1, height - (2 * border_w)))
    self.label:SetPosition(pad_x, 0)
    self.label:SetSize(math.max(1, self.inner:GetWidth() - (2 * pad_x)), self.inner:GetHeight())
    self.label:SetText(text or "")
    self:SetVisible(true)
end

-- ------------------------------------------------ shared card behaviors ----
-- The quest and resource cards share their chip-panel math, chip binding
-- and window position persistence; both must resolve them identically, so
-- the single implementation lives here (the bestiary card keeps its own
-- variant: it also persists size and clamps flush to the screen edges).

-- panel height wrapping its chip layout; nil layout (hidden) when empty
function CardWidgets.measure_chip_panel(texts, content_w)
    if #texts == 0 then
        return nil, 0, 0
    end

    local body_pad_x = CardWidgets.scaled_int(BASE.PANEL_BODY_PAD_X)
    local body_pad_t = CardWidgets.scaled_int(BASE.PANEL_BODY_PAD_TOP)
    local body_pad_b = CardWidgets.scaled_int(BASE.PANEL_BODY_PAD_BOTTOM)
    local header_h = CardWidgets.scaled_int(BASE.PANEL_HEADER_H)
    local usable_w = math.max(1, content_w - 2 - (2 * body_pad_x))
    local layout, chip_content_h = CardWidgets.build_chip_layout(texts, usable_w)
    return layout, chip_content_h, header_h + 2 + body_pad_t + body_pad_b + chip_content_h
end

function CardWidgets.bind_chip_row(chips, parent, layout, link_flags)
    local chip_h = CardWidgets.scaled_int(BASE.CHIP_H)
    while #chips < #layout do
        local chip = CardWidgets.DropChip()
        chip:SetParent(parent)
        chip:SetVisible(false)
        chips[#chips + 1] = chip
    end
    for i = 1, #layout do
        local chip_info = layout[i]
        local chip = chips[i]
        -- link state first: apply_settings picks the border color from it
        chip:set_link(link_flags[chip_info.name] == true and chip_info.name or nil)
        chip:apply_settings(chip_info.chest == true)
        chip:SetPosition(chip_info.x, chip_info.y)
        chip:bind(chip_info.text, chip_info.w, chip_h)
    end
    for i = #layout + 1, #chips do
        chips[i]:SetVisible(false)
    end
end

-- saved-geometry bucket for a card window, keyed under settings.encyclopedia
function CardWidgets.card_window_settings(key, create)
    local root = State.loaded_settings
    if type(root) ~= "table" then
        return nil
    end

    if type(root.encyclopedia) ~= "table" then
        if create ~= true then
            return nil
        end
        root.encyclopedia = {}
    end

    if type(root.encyclopedia[key]) ~= "table" then
        if create ~= true then
            return nil
        end
        root.encyclopedia[key] = {}
    end

    return root.encyclopedia[key]
end

function CardWidgets.persist_card_position(card, key)
    local window = CardWidgets.card_window_settings(key, true)
    if type(window) ~= "table" then
        return
    end

    local left, top = card:GetPosition()
    window.left = left
    window.top = top
end

function CardWidgets.restore_card_position(card, key)
    local window = CardWidgets.card_window_settings(key, false)
    if type(window) ~= "table" then
        return false
    end

    local left = window.left
    local top = window.top
    if type(left) ~= "number" or type(top) ~= "number" then
        return false
    end

    card._suppress_position_persist = true
    card:SetPosition(left, top)
    card._suppress_position_persist = false
    return true
end

function CardWidgets.clamp_card_to_display(card)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local left, top = card:GetPosition()
    local width, height = card:GetSize()
    local offset = CardWidgets.scaled_int(BASE.OFFSET)

    if left + width > display_w then
        left = display_w - width - offset
    end
    if top + height > display_h then
        top = display_h - height - offset
    end
    if left < 0 then
        left = 0
    end
    if top < 0 then
        top = 0
    end

    card._suppress_position_persist = true
    card:SetPosition(left, top)
    card._suppress_position_persist = false
end

function CardWidgets.position_card_near_anchor(card, anchor)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local left = math.floor((display_w - card:GetWidth()) / 2)
    local top = math.floor((display_h - card:GetHeight()) / 2)
    local offset = CardWidgets.scaled_int(BASE.OFFSET)

    -- anchor is optional by design: nil centers the card on screen
    if anchor ~= nil then
        local ax, ay = anchor:GetPosition()
        local aw = anchor:GetSize()
        left = ax + aw + offset
        top = ay
    end

    card._suppress_position_persist = true
    card:SetPosition(left, top)
    card._suppress_position_persist = false
end

function CardWidgets.prepare_card_position(card, key, anchor)
    if CardWidgets.restore_card_position(card, key) ~= true and card.sticky_position ~= true then
        CardWidgets.position_card_near_anchor(card, anchor)
    end

    CardWidgets.clamp_card_to_display(card)
    CardWidgets.persist_card_position(card, key)
    card.sticky_position = true
end
