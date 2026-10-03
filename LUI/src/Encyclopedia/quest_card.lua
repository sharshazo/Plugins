-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- QuestCard: the quest/deed sibling of the bestiary card. Opens from a
-- quest browser row click; shows level/category, the bestower NPC, the
-- reward items as the same clickable chips the bestiary card uses for
-- drops, and the description/objective/dialog texts (lazy texts import -
-- the first open pays the one-time blob load).

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Encyclopedia = _G.LUI.Features.Encyclopedia
local Lore = _G.LUI.Data.Lore
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

local Style = UI.Widgets.Style
local CW = Encyclopedia.CardWidgets

local BASE_WIDTH = 480
local BASE_STAT_BOX_H = 42
local BASE_TEXTS_H = 240

local _scaled_int = CW.scaled_int

local QuestCard = class(UI.Widgets.LuiWindow)
Encyclopedia.QuestCard = QuestCard

-- scrollable text area, monster-card style: a multiline label with an
-- external Lotro scroll bar. The Lotro TextBox always jumps to the bottom
-- on SetText with no way back; a label + detach/SetText/reattach opens at
-- the top (same fix as the bestiary card's notes/drops panels).
function QuestCard._create_text_area(parent)
    parent:SetMouseVisible(true)
    local area = { lines = 0 }

    area.label = UI.Widgets.LuiLabel()
    area.label:SetParent(parent)
    area.label:SetMouseVisible(true)
    area.label:SetSelectable(true)
    area.label:SetMultiline(true)
    area.label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)

    area.scroll = Turbine.UI.Lotro.ScrollBar()
    area.scroll:SetParent(parent)
    area.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    -- scroll bars are a fixed 10px, never scaled
    area.scroll:SetWidth(CW.BASE.SCROLL_W)
    area.scroll:SetHeight(1)
    area.scroll:SetMouseVisible(true)
    area.label:SetVerticalScrollBar(area.scroll)
    area.scroll:SetVisible(false)

    return area
end

function QuestCard._bind_text_area(area, text)
    area.label:SetVerticalScrollBar(nil)
    area.label:SetText(text)
    area.label:SetVerticalScrollBar(area.scroll)
end

-- lay the label out inside a panel body: full height, scroll bar flush
-- to the body's right edge and only visible when the text overflows
function QuestCard._layout_text_area(area, body, body_pad_x, uses_scroll)
    local body_w = body:GetWidth()
    local body_h = math.max(1, body:GetHeight())
    -- fixed 10px scroll bar (never scaled); only the gap scales
    local scroll_w = CW.BASE.SCROLL_W
    local scroll_gap = _scaled_int(CW.BASE.SCROLL_GAP)
    local reserved = uses_scroll == true and (scroll_w + scroll_gap) or 0
    area.label:SetPosition(body_pad_x, 0)
    area.label:SetSize(math.max(1, body_w - body_pad_x - reserved), body_h)
    area.scroll:SetPosition(body_w - scroll_w, 0)
    area.scroll:SetSize(scroll_w, body_h)
    area.scroll:SetVisible(uses_scroll == true)
end

function QuestCard:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self.current_ordinal = nil
    self.reward_texts = {}
    self.reward_chips = {}
    self._link_flags = {}
    self.sticky_position = false
    self._suppress_position_persist = false

    self:set_title(TR["Quests"])
    self:set_icon(UI.AssetIds.book_orange_cover)
    self:set_resizable(false)
    self:enable_maximize(false)
    self:hide()
    self:SetMouseVisible(true)

    local central = Turbine.UI.Control()
    central:SetMouseVisible(true)
    self:set_central_widget(central)

    self.content = Turbine.UI.Control()
    self.content:SetParent(central)
    self.content:SetMouseVisible(false)

    self.level_panel = CW.create_panel(self.content, TR["Level"])
    self.level_value = CW.create_text(self.level_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.category_panel = CW.create_panel(self.content, TR["Category"])
    self.category_value = CW.create_text(self.category_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.bestower_panel = CW.create_panel(self.content, TR["Bestower"])
    self.bestower_value = CW.create_text(self.bestower_panel.body, false, Turbine.UI.ContentAlignment.MiddleLeft)

    self.receiver_panel = CW.create_panel(self.content, TR["Receiver"])
    self.receiver_value = CW.create_text(self.receiver_panel.body, false, Turbine.UI.ContentAlignment.MiddleLeft)

    self.objectives_panel = CW.create_panel(self.content, TR["Objectives"])
    self.objectives_area = QuestCard._create_text_area(self.objectives_panel.body)

    self.rewards_panel = CW.create_panel(self.content, TR["Rewards"])

    self.texts_panel = CW.create_panel(self.content, TR["Description"])
    self.texts_area = QuestCard._create_text_area(self.texts_panel.body)

    self.VisibleChanged = function()
        if self:IsVisible() == true then
            self:_clamp_to_display()
            self:_persist_current_position()
        else
            self.current_ordinal = nil
        end
    end
    self.PositionChanged = function()
        if self._suppress_position_persist == true or self:IsVisible() ~= true then
            return
        end
        self.sticky_position = true
        self:_persist_current_position()
    end

    self:apply_settings()
end

-- ------------------------------------------------- position persistence ----
-- shared with the resource card (card_widgets.lua); only the settings key
-- differs

local SETTINGS_KEY = "quest_card_window"

function QuestCard:_persist_current_position()
    CW.persist_card_position(self, SETTINGS_KEY)
end

function QuestCard:_restore_saved_position()
    return CW.restore_card_position(self, SETTINGS_KEY)
end

function QuestCard:_clamp_to_display()
    CW.clamp_card_to_display(self)
end

function QuestCard:_prepare_position(anchor)
    CW.prepare_card_position(self, SETTINGS_KEY, anchor)
end

-- ---------------------------------------------------------------- layout ----

local _measure_chip_panel = CW.measure_chip_panel

function QuestCard:_measure_content_height()
    local gap = _scaled_int(CW.BASE.SECTION_GAP)
    local margin = _scaled_int(12)
    local central_w = self:central_widget():GetSize()
    local content_w = math.max(1, central_w - (2 * margin))

    local h = _scaled_int(BASE_STAT_BOX_H)
    if self._has_bestower == true then
        h = h + gap + _scaled_int(BASE_STAT_BOX_H)
    end
    if self._has_receiver == true then
        h = h + gap + _scaled_int(BASE_STAT_BOX_H)
    end
    if self:_objectives_height() > 0 then
        h = h + gap + self:_objectives_height()
    end
    local _, _, rewards_h = _measure_chip_panel(self.reward_texts, content_w)
    if rewards_h > 0 then
        h = h + gap + rewards_h
    end
    h = h + gap + _scaled_int(BASE_TEXTS_H)
    return h
end

-- objectives panel height from an estimated wrapped line count (the box
-- scrolls when the estimate falls short)
function QuestCard:_objectives_height()
    if self._objectives_lines == nil or self._objectives_lines == 0 then
        return 0
    end
    local header_h = _scaled_int(CW.BASE.PANEL_HEADER_H)
    local line_h = _scaled_int(16)
    local pads = _scaled_int(CW.BASE.PANEL_BODY_PAD_TOP) + _scaled_int(CW.BASE.PANEL_BODY_PAD_BOTTOM)
    local lines = math.min(8, self._objectives_lines)
    return header_h + 2 + pads + (lines * line_h)
end

function QuestCard:_fit_window_height()
    local margin = _scaled_int(12)
    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    local chrome_w = math.max(0, window_w - central_w)
    local chrome_h = math.max(0, window_h - central_h)

    self:SetSize(_scaled_int(BASE_WIDTH) + chrome_w,
        (2 * margin) + self:_measure_content_height() + chrome_h)
    UI.Widgets.LuiWindow._layout(self)
    self:_clamp_to_display()
end

local _bind_chip_row = CW.bind_chip_row

function QuestCard:_layout_content()
    local margin = _scaled_int(12)
    local gap = _scaled_int(CW.BASE.SECTION_GAP)
    local stat_h = _scaled_int(BASE_STAT_BOX_H)
    local body_pad_x = _scaled_int(CW.BASE.PANEL_BODY_PAD_X)

    local host_w, host_h = self:central_widget():GetSize()
    local content_w = math.max(1, host_w - (2 * margin))
    self.content:SetPosition(margin, margin)
    self.content:SetSize(content_w, math.max(1, host_h - (2 * margin)))

    -- row 1: Level | Category
    local level_w = math.max(1, math.floor((content_w - gap) / 3))
    CW.layout_panel(self.level_panel, 0, 0, level_w, stat_h)
    CW.layout_panel(self.category_panel, level_w + gap, 0, math.max(1, content_w - level_w - gap), stat_h)
    self.level_value:SetPosition(body_pad_x, 0)
    self.level_value:SetSize(math.max(1, self.level_panel.body:GetWidth() - (2 * body_pad_x)),
        self.level_panel.body:GetHeight())
    self.category_value:SetPosition(body_pad_x, 0)
    self.category_value:SetSize(math.max(1, self.category_panel.body:GetWidth() - (2 * body_pad_x)),
        self.category_panel.body:GetHeight())

    local y = stat_h + gap

    -- bestower / receiver NPCs: one full-width container each (hidden
    -- when not a named NPC; receiver only when it differs)
    local function _layout_npc_panel(panel, value, shown)
        if shown ~= true then
            panel.frame:SetVisible(false)
            return
        end
        panel.frame:SetVisible(true)
        CW.layout_panel(panel, 0, y, content_w, stat_h)
        value:SetPosition(body_pad_x, 0)
        value:SetSize(math.max(1, panel.body:GetWidth() - (2 * body_pad_x)),
            panel.body:GetHeight())
        y = y + stat_h + gap
    end
    _layout_npc_panel(self.bestower_panel, self.bestower_value, self._has_bestower)
    _layout_npc_panel(self.receiver_panel, self.receiver_value, self._has_receiver)

    -- objectives: own container, scroll bar flush to the panel edge
    local objectives_h = self:_objectives_height()
    if objectives_h > 0 then
        self.objectives_panel.frame:SetVisible(true)
        CW.layout_panel(self.objectives_panel, 0, y, content_w, objectives_h)
        QuestCard._layout_text_area(self.objectives_area, self.objectives_panel.body,
            body_pad_x, (self._objectives_lines or 0) > 8)
        y = y + objectives_h + gap
    else
        self.objectives_panel.frame:SetVisible(false)
    end

    -- rewards chips
    local layout, _, rewards_h = _measure_chip_panel(self.reward_texts, content_w)
    if layout ~= nil then
        self.rewards_panel.frame:SetVisible(true)
        CW.layout_panel(self.rewards_panel, 0, y, content_w, rewards_h)
        local body_pad_t = _scaled_int(CW.BASE.PANEL_BODY_PAD_TOP)
        for i = 1, #layout do
            layout[i].x = layout[i].x + body_pad_x
            layout[i].y = layout[i].y + body_pad_t
        end
        _bind_chip_row(self.reward_chips, self.rewards_panel.body, layout, self._link_flags)
        y = y + rewards_h + gap
    else
        self.rewards_panel.frame:SetVisible(false)
    end

    -- texts: fixed-height scrollable block
    local texts_h = _scaled_int(BASE_TEXTS_H)
    CW.layout_panel(self.texts_panel, 0, y, content_w, texts_h)
    local viewport_lines = math.floor(math.max(1, self.texts_panel.body:GetHeight()) / _scaled_int(16))
    QuestCard._layout_text_area(self.texts_area, self.texts_panel.body,
        body_pad_x, (self._texts_lines or 0) > viewport_lines)
end

-- ---------------------------------------------------------------- record ----

local function _reward_chip_texts(record)
    local texts = {}
    for i = 1, #record.rewards do
        local reward = record.rewards[i]
        local ordinal = reward.item ~= nil and Lore.Items.ordinal_of(reward.item) or nil
        if ordinal ~= nil then
            local label = Lore.Items.label(ordinal)
            local text = label
            if reward.quantity > 1 then
                text = label .. " x" .. reward.quantity
            end
            local linked = Encyclopedia.encyclopedia_tab_for_item(label) ~= nil
            texts[#texts + 1] = { text = text, chest = false, name = label, linked = linked }
        end
    end
    return texts
end

-- objectives (with completion counts) as their own block; the numeric
-- conditions align with the condition texts by index
local function _objectives_block(texts, record)
    local numbered = #texts.objectives > 1
    local parts = {}
    for i = 1, #texts.objectives do
        local objective = texts.objectives[i]
        local conds = record.objectives[i]
        local lines = {}
        if objective.text ~= "" then
            lines[#lines + 1] = objective.text
        end
        for c = 1, #objective.conds do
            local text = objective.conds[c]
            local cond = conds ~= nil and conds[c] or nil
            local count = cond ~= nil and cond.count or 0
            if count > 1 then
                if text ~= "" then
                    text = text .. " (x" .. count .. ")"
                else
                    text = "x" .. count
                end
            end
            if text ~= "" then
                lines[#lines + 1] = text
            end
        end
        if #lines > 0 then
            local block = table.concat(lines, "\n")
            if numbered then
                block = tostring(i) .. ". " .. block
            end
            parts[#parts + 1] = block
        end
    end
    return table.concat(parts, "\n")
end

local function _texts_block(texts)
    local parts = {}
    if texts.description ~= "" then
        parts[#parts + 1] = texts.description
    end
    for i = 1, #texts.dialogs do
        if texts.dialogs[i] ~= "" then
            parts[#parts + 1] = texts.dialogs[i]
        end
    end
    return table.concat(parts, "\n\n")
end

-- wrapped-line estimate for the objectives box height (~66 chars/line at
-- the card's width and text size); the box scrolls when it falls short.
-- Length counts characters, not bytes: accented fr/de text is multi-byte
-- and would otherwise overestimate by up to ~15%
local function _estimate_lines(text)
    if text == "" then
        return 0
    end
    local lines = 0
    for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
        local _, continuation_bytes = string.gsub(line, "[\128-\191]", "")
        lines = lines + math.max(1, math.ceil((#line - continuation_bytes) / 66))
    end
    return lines
end

function QuestCard:_apply_quest(ordinal)
    self.current_ordinal = ordinal
    local Quests = Lore.Quests

    self:set_title(Quests.label(ordinal))

    local record = Quests.decode(ordinal)
    self.level_value:SetText(record.level > 0 and tostring(record.level) or "-")
    self.category_value:SetText(Quests.category_name(record) or "-")

    local function _npc_text(npc)
        if npc == nil then
            return nil
        end
        local name, title = Lore.Npcs.name(npc)
        if name == nil then
            return nil
        end
        return title ~= nil and (name .. ", " .. title) or name
    end

    self._has_bestower = false
    self._has_receiver = false
    local bestower = Quests.bestower_npc(record)
    local receiver = Quests.turn_in_npc(record)
    local bestower_text = _npc_text(bestower)
    if bestower_text ~= nil then
        self._has_bestower = true
        self.bestower_value:SetText(bestower_text)
    end
    -- the receiver is only worth a panel when it is a different NPC
    if receiver ~= nil and receiver ~= bestower then
        local receiver_text = _npc_text(receiver)
        if receiver_text ~= nil then
            self._has_receiver = true
            self.receiver_value:SetText(receiver_text)
        end
    end

    local rewards = _reward_chip_texts(record)
    self.reward_texts = rewards
    self._link_flags = {}
    for i = 1, #rewards do
        self._link_flags[rewards[i].name] = rewards[i].linked
    end

    local texts = Quests.texts(ordinal)
    local objectives_text = _objectives_block(texts, record)
    local description_text = _texts_block(texts)
    self._objectives_lines = _estimate_lines(objectives_text)
    self._texts_lines = _estimate_lines(description_text)
    QuestCard._bind_text_area(self.objectives_area, objectives_text)
    QuestCard._bind_text_area(self.texts_area, description_text)

    self:_fit_window_height()
    self:_layout_content()
end

function QuestCard:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)
    self:set_resizable(false)

    local window_w, window_h = self:GetSize()
    local central_w = self:central_widget():GetSize()
    self:SetSize(_scaled_int(BASE_WIDTH) + math.max(0, window_w - central_w), window_h)

    CW.style_panel(self.level_panel)
    CW.style_panel(self.category_panel)
    CW.style_panel(self.bestower_panel)
    CW.style_panel(self.receiver_panel)
    CW.style_panel(self.objectives_panel)
    CW.style_panel(self.rewards_panel)
    CW.style_panel(self.texts_panel)
    CW.style_text(self.level_value, "Verdana", CW.BASE.TEXT_SIZE + 2, Style.FOREGROUND)
    CW.style_text(self.category_value, "Verdana", CW.BASE.TEXT_SIZE + 2, Style.FOREGROUND)
    CW.style_text(self.bestower_value, "Verdana", CW.BASE.TEXT_SIZE, Style.FOREGROUND)
    CW.style_text(self.receiver_value, "Verdana", CW.BASE.TEXT_SIZE, Style.FOREGROUND)
    CW.style_text(self.objectives_area.label, "Verdana", CW.BASE.TEXT_SIZE, Style.FOREGROUND)
    CW.style_text(self.texts_area.label, "Verdana", CW.BASE.TEXT_SIZE, Style.FOREGROUND)

    if self.current_ordinal ~= nil then
        self:_apply_quest(self.current_ordinal)
    else
        self:_fit_window_height()
        self:_layout_content()
    end
end

function QuestCard:close()
    self.current_ordinal = nil
    self:hide()
end

-- quest browser row click entry
function QuestCard:show_for_ordinal(ordinal, anchor)
    Lore.load_quests()
    Lore.load_items()

    if self:IsVisible() == true and self.current_ordinal == ordinal then
        self:close()
        return
    end

    self:_apply_quest(ordinal)
    self:_prepare_position(anchor)
    self:show()
end
