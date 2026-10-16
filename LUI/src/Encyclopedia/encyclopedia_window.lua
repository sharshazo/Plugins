-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Encyclopedia window: a tab bar over the item browser panels
-- (Equipment, Resources, Consumables). Each panel is created inside its
-- own tab host the first time that tab is shown.

local TR = _G.LUI.Locale.TR
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local Defaults = _G.LUI.Settings.Defaults
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Encyclopedia = _G.LUI.Features.Encyclopedia
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.font"

local Style = UI.Widgets.Style

local BASE_MARGIN_LEFT = 8
local BASE_MARGIN_TOP = 8
local BASE_MARGIN_RIGHT = 8
local BASE_MARGIN_BOTTOM = 8

-- shared with the encyclopedia item tabs so all tab content aligns
Encyclopedia.CONTENT_MARGINS = {
    left = BASE_MARGIN_LEFT,
    top = BASE_MARGIN_TOP,
    right = BASE_MARGIN_RIGHT,
    bottom = BASE_MARGIN_BOTTOM,
}
local BASE_MIN_W = 600
local BASE_MIN_H = 240

-- saved geometry bucket (settings ui.windows)
local WINDOW_STATE_KEY = "encyclopedia"

-- tab index -> lore-DB item bucket shown by that tab
local TAB_BUCKETS = { "equipment", "resource", "consumable" }
local TAB_LABELS = { "Equipment", "Resources", "Consumables" }

-- converter bucket codes (1=equipment 2=consumable 3=resource) to
-- encyclopedia tab index; any other bucket has no tab and is not linkable
local BUCKET_TAB_BY_CODE = { [1] = 1, [2] = 3, [3] = 2 }

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * State.settings.global.scale)
end

local function _to_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback or 0
    end
    return value
end

-- Which encyclopedia tab shows this item name; nil when the name is not a
-- browsable item (unknown name or a bucket without tab). Shared probe for
-- every surface that decides whether an item link makes sense.
function Encyclopedia.encyclopedia_tab_for_item(item_name)
    local Lore = _G.LUI.Data.Lore
    -- the items DB is staged in the background (items_prewarm.lua); a link
    -- probe must never pay the full synchronous import. Pre-staging
    -- probes report "no link" and callers re-probe later.
    if Lore.Items.loaded ~= true then
        return nil
    end
    local ordinals = Lore.Items.find_ordinals(item_name)
    if ordinals == nil then
        return nil
    end
    for i = 1, #ordinals do
        local tab_index = BUCKET_TAB_BY_CODE[Lore.Items.bucket(ordinals[i])]
        if tab_index ~= nil then
            return tab_index
        end
    end
    return nil
end

local EncyclopediaWindow = class(UI.Widgets.LuiWindow)

function EncyclopediaWindow:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self:set_title(TR["Encyclopedia"])
    self:set_icon(UI.AssetIds.book_orange_cover)
    self:set_resizable(true)
    self:hide()
    self:SetWantsUpdates(false)

    self._suppress_size_changed = false

    local content_host = Turbine.UI.Control()
    content_host:SetMouseVisible(true)
    self:set_central_widget(content_host)

    -- the tab bar owns the whole central area and hosts one item browser
    -- panel per tab
    self._item_panels = {}
    self._item_tab_hosts = {}
    self._active_encyclopedia_tab = 1

    self.encyclopedia_tabs = UI.Widgets.LuiTabBar()
    self.encyclopedia_tabs:SetParent(content_host)
    for tab = 1, #TAB_BUCKETS do
        local host = Turbine.UI.Control()
        host:SetMouseVisible(true)
        self._item_tab_hosts[tab] = host
        self.encyclopedia_tabs:add_tab(TR[TAB_LABELS[tab]], host)
    end
    self.encyclopedia_tabs.on_tab_changed = function(index)
        self:_set_encyclopedia_tab(index)
    end
    -- same look as the config window tab bars
    self.encyclopedia_tabs:set_content_padding(4)
    self.encyclopedia_tabs:set_show_border_left(false)
    self.encyclopedia_tabs:set_show_border_right(false)
    self.encyclopedia_tabs:set_show_border_bottom(false)
    -- the border setters also drop the tab-button caps; restore them
    self.encyclopedia_tabs:set_show_tab_cap_left(true)
    self.encyclopedia_tabs:set_show_tab_cap_right(true)
    self.encyclopedia_tabs:set_show_tab_cap_bottom(true)
    self.encyclopedia_tabs:set_scale(State.settings.global.scale)
    self.encyclopedia_tabs:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + 3))
    self.encyclopedia_tabs:set_selected_index(1, false)
    self:_ensure_panel(1)

    self.SizeChanged = function()
        UI.Widgets.LuiWindow._layout(self)
        self:handle_user_resize()
    end

    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    self:SetSize(
        _scaled_int(700) + math.max(0, window_w - central_w),
        _scaled_int(520) + math.max(0, window_h - central_h)
    )
    self:apply_settings()
end

function EncyclopediaWindow:bring_to_front()
    if self:IsVisible() == true then
        self:Activate()
    end
end

function EncyclopediaWindow:open()
    self:show()
end

function EncyclopediaWindow:toggle()
    if self:IsVisible() == true then
        self:hide()
    else
        self:show()
    end
end

function EncyclopediaWindow:capture_geometry()
    local window = Defaults.get_ui_window_state(WINDOW_STATE_KEY)
    if type(window) ~= "table" then
        return
    end

    local geometry = self:get_geometry()
    window.left = geometry.left
    window.top = geometry.top
    window.width = geometry.width
    window.height = geometry.height
    window.tile = geometry.tile
end

function EncyclopediaWindow:persist_geometry()
    self:capture_geometry()
end

function EncyclopediaWindow:_minimum_window_size()
    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    return _scaled_int(BASE_MIN_W) + math.max(0, window_w - central_w),
        _scaled_int(BASE_MIN_H) + math.max(0, window_h - central_h)
end

function EncyclopediaWindow:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)
    local min_w, min_h = self:_minimum_window_size()
    self:set_minimum_size(min_w, min_h)

    self.encyclopedia_tabs:set_scale(State.settings.global.scale)
    self.encyclopedia_tabs:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + 3))
    for _, panel in pairs(self._item_panels) do
        panel:apply_fonts()
    end

    local window = Defaults.get_ui_window_state(WINDOW_STATE_KEY)
    if type(window) == "table" then
        local left = _to_number(window.left, self:GetLeft())
        local top = _to_number(window.top, self:GetTop())
        local width = _to_number(window.width, self:GetWidth())
        local height = _to_number(window.height, self:GetHeight())

        self._suppress_size_changed = true
        self:SetPosition(left, top)
        self:SetSize(math.max(min_w, width), math.max(min_h, height))
        self._suppress_size_changed = false
        self:set_geometry(window)
    end

    self:layout()
end

function EncyclopediaWindow:handle_user_resize()
    local min_w, min_h = self:_minimum_window_size()
    self:set_minimum_size(min_w, min_h)
    local cur_w, cur_h = self:GetSize()
    local next_w = cur_w
    local next_h = cur_h
    if cur_w < min_w then next_w = min_w end
    if cur_h < min_h then next_h = min_h end

    if (next_w ~= cur_w or next_h ~= cur_h) and self._suppress_size_changed ~= true then
        self._suppress_size_changed = true
        self:SetSize(next_w, next_h)
        self._suppress_size_changed = false
        return
    end

    self:layout()
end

-- Cross-window link (card drop chips, item actions menu): open the
-- Encyclopedia on the item tab that shows this item, with an exact-name
-- search. Returns false when the name is not a browsable item.
function EncyclopediaWindow:open_encyclopedia_item_search(item_name)
    local tab_index = Encyclopedia.encyclopedia_tab_for_item(item_name)
    if tab_index == nil then
        return false
    end

    self.encyclopedia_tabs:set_selected_index(tab_index)
    self:_set_encyclopedia_tab(tab_index)
    -- window first, text after: the Lotro TextBox does not repaint text
    -- set while its window is hidden until it is interacted with
    self:open()
    self:bring_to_front()
    self._item_panels[tab_index]:open_item_search(item_name)
    return true
end

function EncyclopediaWindow:layout()
    -- the tab bar owns the whole central area; sizing it lays out the
    -- selected tab's content host synchronously
    local central_w, central_h = self:central_widget():GetSize()
    self.encyclopedia_tabs:SetPosition(0, 0)
    self.encyclopedia_tabs:SetSize(central_w, central_h)

    local active_panel = self._item_panels[self._active_encyclopedia_tab]
    if active_panel ~= nil then
        local host = self._item_tab_hosts[self._active_encyclopedia_tab]
        active_panel:SetPosition(0, 0)
        active_panel:SetSize(host:GetSize())
        active_panel:layout()
    end
end

-- panels are only created lazily inside their host on first activation
function EncyclopediaWindow:_ensure_panel(index)
    if self._item_panels[index] == nil and TAB_BUCKETS[index] ~= nil then
        local panel = Encyclopedia.ItemBrowserPanel(TAB_BUCKETS[index], self)
        panel:SetParent(self._item_tab_hosts[index])
        self._item_panels[index] = panel
    end
    return self._item_panels[index]
end

function EncyclopediaWindow:_set_encyclopedia_tab(index)
    if TAB_BUCKETS[index] == nil then
        return
    end
    self._active_encyclopedia_tab = index
    -- the tab bar shows/hides the tab hosts itself
    self:_ensure_panel(index)
    self:layout()
end

Encyclopedia.EncyclopediaWindow = EncyclopediaWindow
