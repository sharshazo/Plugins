-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- ResourceCard: the harvest-node sibling of the bestiary card. Opens from a
-- target double-click when the target name resolves to a resource node
-- (Lore.Nodes); shows the node's profession/tier and its yields as the same
-- clickable chips the bestiary card uses for drops (guaranteed yields with
-- quantity ranges, bonus yields, rare finds in the gold chest styling).

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Encyclopedia = _G.LUI.Features.Encyclopedia
local Lore = _G.LUI.Data.Lore
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.UI.Widgets.item_icon"

local Style = UI.Widgets.Style
local CW = Encyclopedia.CardWidgets

local BASE_WIDTH = 420
-- taller than the bestiary stat boxes: the body hosts the native 32px
-- profession badge art (20px header + 2px frame + 34px body)
local BASE_STAT_BOX_H = 56
local BADGE_SIDE = 32

local _scaled_int = CW.scaled_int

local function _yield_chip_texts(node)
    local always, chance = {}, {}
    for i = 1, #node.y do
        local y = node.y[i]
        local ordinal = Lore.Items.ordinal_of(y[1])
        local label = Lore.Items.label(ordinal)
        local linked = Encyclopedia.encyclopedia_tab_for_item(label) ~= nil
        if y[4] == 1 then
            local text = label
            if y[3] > 1 then
                if y[2] == y[3] then
                    text = label .. " x" .. y[3]
                else
                    text = label .. " x" .. y[2] .. "-" .. y[3]
                end
            end
            always[#always + 1] = { text = text, chest = false, name = label, linked = linked }
        else
            chance[#chance + 1] = { text = label, chest = y[4] == 3, name = label, linked = linked }
        end
    end
    return always, chance
end

local ResourceCard = class(UI.Widgets.LuiWindow)
Encyclopedia.ResourceCard = ResourceCard

function ResourceCard:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self.current_name = nil
    self.current_node = nil
    self.always_texts = {}
    self.chance_texts = {}
    self.always_chips = {}
    self.chance_chips = {}
    self._link_flags = {}
    self.sticky_position = false
    self._suppress_position_persist = false

    self:set_title(TR["Resource"])
    self:set_icon(UI.AssetIds.anvil_silver_glow)
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

    self.profession_panel = CW.create_panel(self.content, TR["Profession"])
    self.badge = UI.Widgets.LuiItemIcon()
    self.badge:SetParent(self.profession_panel.body)
    self.badge:set_side(BADGE_SIDE)
    self.profession_value = CW.create_text(self.profession_panel.body, false, Turbine.UI.ContentAlignment.MiddleLeft)

    self.tier_panel = CW.create_panel(self.content, TR["Tier"])
    self.tier_value = CW.create_text(self.tier_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.always_panel = CW.create_panel(self.content, TR["Always contains"])
    self.chance_panel = CW.create_panel(self.content, TR["May contain"])

    self.VisibleChanged = function()
        if self:IsVisible() == true then
            self:_clamp_to_display()
            self:_persist_current_position()
        else
            self.current_name = nil
            self.current_node = nil
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
-- shared with the quest card (card_widgets.lua); only the settings key
-- differs

local SETTINGS_KEY = "resource_card_window"

function ResourceCard:_persist_current_position()
    CW.persist_card_position(self, SETTINGS_KEY)
end

function ResourceCard:_restore_saved_position()
    return CW.restore_card_position(self, SETTINGS_KEY)
end

function ResourceCard:_clamp_to_display()
    CW.clamp_card_to_display(self)
end

function ResourceCard:_prepare_position(anchor)
    CW.prepare_card_position(self, SETTINGS_KEY, anchor)
end

-- ---------------------------------------------------------------- layout ----

function ResourceCard:_measure_viewport_width()
    local margin = _scaled_int(12)
    local central_w = self:central_widget():GetSize()
    return math.max(1, central_w - (2 * margin))
end

local _measure_chip_panel = CW.measure_chip_panel

function ResourceCard:_measure_content_height()
    local gap = _scaled_int(CW.BASE.SECTION_GAP)
    local content_w = self:_measure_viewport_width()
    local h = _scaled_int(BASE_STAT_BOX_H)

    local _, _, always_h = _measure_chip_panel(self.always_texts, content_w)
    local _, _, chance_h = _measure_chip_panel(self.chance_texts, content_w)
    if always_h > 0 then
        h = h + gap + always_h
    end
    if chance_h > 0 then
        h = h + gap + chance_h
    end
    return h
end

function ResourceCard:_fit_window_height()
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

function ResourceCard:_layout_chip_panel(panel, texts, chips, y, content_w)
    local layout, _, panel_h = _measure_chip_panel(texts, content_w)
    if layout == nil then
        panel.frame:SetVisible(false)
        return y
    end

    panel.frame:SetVisible(true)
    CW.layout_panel(panel, 0, y, content_w, panel_h)

    local body_pad_x = _scaled_int(CW.BASE.PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(CW.BASE.PANEL_BODY_PAD_TOP)
    for i = 1, #layout do
        layout[i].x = layout[i].x + body_pad_x
        layout[i].y = layout[i].y + body_pad_t
    end
    _bind_chip_row(chips, panel.body, layout, self._link_flags)

    return y + panel_h + _scaled_int(CW.BASE.SECTION_GAP)
end

function ResourceCard:_layout_content()
    local margin = _scaled_int(12)
    local gap = _scaled_int(CW.BASE.SECTION_GAP)
    local stat_h = _scaled_int(BASE_STAT_BOX_H)

    local host_w, host_h = self:central_widget():GetSize()
    local content_w = math.max(1, host_w - (2 * margin))
    self.content:SetPosition(margin, margin)
    self.content:SetSize(content_w, math.max(1, host_h - (2 * margin)))

    local half_w = math.max(1, math.floor((content_w - gap) / 2))
    CW.layout_panel(self.profession_panel, 0, 0, half_w, stat_h)
    CW.layout_panel(self.tier_panel, half_w + gap, 0, math.max(1, content_w - half_w - gap), stat_h)

    local body_pad_x = _scaled_int(CW.BASE.PANEL_BODY_PAD_X)
    local body_h = self.profession_panel.body:GetHeight()
    local badge_y = math.max(0, math.floor((body_h - BADGE_SIDE) / 2))
    self.badge:SetPosition(body_pad_x, badge_y)
    local label_x = body_pad_x + BADGE_SIDE + _scaled_int(6)
    self.profession_value:SetPosition(label_x, 0)
    self.profession_value:SetSize(math.max(1, self.profession_panel.body:GetWidth() - label_x - body_pad_x), body_h)

    self.tier_value:SetPosition(body_pad_x, 0)
    self.tier_value:SetSize(math.max(1, self.tier_panel.body:GetWidth() - (2 * body_pad_x)),
        self.tier_panel.body:GetHeight())

    local y = stat_h + gap
    y = self:_layout_chip_panel(self.always_panel, self.always_texts, self.always_chips, y, content_w)
    self:_layout_chip_panel(self.chance_panel, self.chance_texts, self.chance_chips, y, content_w)
end

-- ---------------------------------------------------------------- record ----

function ResourceCard:_apply_node(name, node)
    self.current_name = name
    self.current_node = node

    self:set_title(name)

    local layers = Lore.Nodes.badge_layers(node.p, node.t)
    self.badge:bind(layers[1], layers[2], nil)
    self.profession_value:SetText(Lore.Nodes.profession_name(node.p))
    self.tier_value:SetText(Lore.Nodes.tier_name(node.t) .. " (" .. node.t .. ")")

    local always, chance = _yield_chip_texts(node)
    self.always_texts = always
    self.chance_texts = chance
    self._link_flags = {}
    for i = 1, #always do
        self._link_flags[always[i].name] = always[i].linked
    end
    for i = 1, #chance do
        self._link_flags[chance[i].name] = chance[i].linked
    end

    self:_fit_window_height()
    self:_layout_content()
end

function ResourceCard:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)
    self:set_resizable(false)

    local window_w, window_h = self:GetSize()
    local central_w = self:central_widget():GetSize()
    self:SetSize(_scaled_int(BASE_WIDTH) + math.max(0, window_w - central_w), window_h)

    CW.style_panel(self.profession_panel)
    CW.style_panel(self.tier_panel)
    CW.style_panel(self.always_panel)
    CW.style_panel(self.chance_panel)
    CW.style_text(self.profession_value, "Verdana", CW.BASE.TEXT_SIZE + 2, Style.FOREGROUND)
    CW.style_text(self.tier_value, "Verdana", CW.BASE.TEXT_SIZE + 2, Style.FOREGROUND)

    if self.current_node ~= nil then
        self:_apply_node(self.current_name, self.current_node)
    else
        self:_fit_window_height()
        self:_layout_content()
    end
end

function ResourceCard:close()
    self.current_name = nil
    self.current_node = nil
    self:hide()
end

-- target double-click entry: false when the target is not a harvest node,
-- so the caller can fall through to the bestiary card
function ResourceCard:toggle_for_target(target, anchor)
    if target == nil or target.GetName == nil then
        return false
    end
    local name = target:GetName()
    if type(name) ~= "string" or name == "" then
        return false
    end

    Lore.load_nodes()
    local node = Lore.Nodes.for_name(name)
    if node == nil then
        return false
    end

    if self:IsVisible() == true and self.current_name == name then
        self:close()
        return true
    end

    -- yields resolve through the items DB (labels + Encyclopedia link
    -- gating); one-time load when the first node card opens
    Lore.load_items()

    self:_apply_node(name, node)
    self:_prepare_position(anchor)
    self:show()
    return true
end
