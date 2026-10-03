-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Encyclopedia Quests tab: nested sub-tabs (Quests / Deeds), each a paged,
-- searchable, filterable listing over the packed quests domain. Search is
-- the shared type-ahead grammar; filters are cheap fixed-offset byte
-- probes (kind / level / category); the listing order is the record order
-- baked by the extractor: level ascending, then folded en name.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Style = UI.Widgets.Style
local scaled_int = UI.NativeScaling.scaled_int
local class = _G.LUI.Core.class
local Lore = _G.LUI.Data.Lore
local SearchQuery = _G.LUI.Utils.SearchQuery
local Encyclopedia = _G.LUI.Features.Encyclopedia
import "Turbine.UI"

-- control metrics match the item browser tabs (21px controls, 4px gaps)
local BASE_BAR_H = 21
local BASE_GAP = 4
local BASE_NAV_W = 22
local BASE_PAGE_BAR_H = 21
local BASE_PAGE_W = 74
local BASE_LEVEL_W = 44

local FILTER_ALL_CODE = 0

-- shared browser scaffolding (browser_shared.lua); the dropdown max clamp
-- is this tab's only variation (quest categories run longer)
local BrowserShared = Encyclopedia.BrowserShared
local BASE_DROPDOWN_MAX_W = 220

local function _dropdown_base_w(labels)
    return BrowserShared.dropdown_base_w(labels, BASE_DROPDOWN_MAX_W)
end

local _scaled_font = BrowserShared.scaled_font

local QuestBrowserPanel = class(Turbine.UI.Control)
Encyclopedia.QuestBrowserPanel = QuestBrowserPanel

function QuestBrowserPanel:Constructor(kind, popup_host)
    Turbine.UI.Control.Constructor(self)

    self._kind = kind
    self._popup_host = popup_host
    self._filtered = nil
    self._signature = nil
    self._category_filter = FILTER_ALL_CODE
    self._level_min = nil
    self._level_max = nil

    self:SetMouseVisible(true)
    self:SetBackColor(Style.PANEL_BACKGROUND)

    Lore.load_quests()

    self.search_box = UI.Widgets.LuiLineEdit()
    self.search_box:SetParent(self)
    self.search_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.search_box:set_placeholder_text(TR["Search..."])
    self.search_box.TextChanged = function()
        self:_on_filters_changed()
    end

    self.category_label = UI.Widgets.LuiLabel()
    self.category_label:SetParent(self)
    self.category_label:SetMouseVisible(false)
    self.category_label:SetSelectable(false)
    self.category_label:SetMultiline(false)
    self.category_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.category_label:SetText(TR["Category"] .. ":")

    self.category_dropdown = UI.Widgets.LuiDropdown()
    self.category_dropdown:SetParent(self)
    self.category_dropdown:SetPopupHost(popup_host)
    self.category_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    local category_labels, category_values = self:_category_options()
    self.category_dropdown:SetMappedOptions(category_labels, category_values)
    self._category_dd_base_w = _dropdown_base_w(category_labels)
    self.category_dropdown.ValueChanged = function(_, value)
        self._category_filter = tonumber(value) or FILTER_ALL_CODE
        self:_on_filters_changed()
    end

    self.level_label = UI.Widgets.LuiLabel()
    self.level_label:SetParent(self)
    self.level_label:SetMouseVisible(false)
    self.level_label:SetSelectable(false)
    self.level_label:SetMultiline(false)
    self.level_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.level_label:SetText(TR["Level"] .. ":")

    self.level_min_box = UI.Widgets.LuiLineEdit()
    self.level_min_box:SetParent(self)
    self.level_min_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_min_box.TextChanged = function()
        self:_on_filters_changed()
    end

    self.level_dash_label = UI.Widgets.LuiLabel()
    self.level_dash_label:SetParent(self)
    self.level_dash_label:SetMouseVisible(false)
    self.level_dash_label:SetSelectable(false)
    self.level_dash_label:SetMultiline(false)
    self.level_dash_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_dash_label:SetText("-")

    self.level_max_box = UI.Widgets.LuiLineEdit()
    self.level_max_box:SetParent(self)
    self.level_max_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_max_box.TextChanged = function()
        self:_on_filters_changed()
    end

    self.table = UI.Widgets.LuiTable()
    self.table:SetParent(self)
    self.table:set_auto_height(true)
    self.table:set_columns({
        { title = TR["Name"] },
        { title = TR["Category"], width = 190 },
        { title = TR["Level"], width = 60 },
    })
    self._table_cells = {}
    self.table.on_row_clicked = function(index)
        local ordinal = self.table:row_data(index)
        if ordinal ~= nil and type(self.on_quest_open) == "function" then
            self.on_quest_open(ordinal)
        end
    end

    -- during _sync_pager the caller renders right after, so the callback
    -- skips its own render
    self.pager = UI.Widgets.LuiPager()
    self.pager:SetParent(self)
    self.pager.changed = function()
        if self._pager_syncing ~= true then
            self:_render_page()
        end
    end

    self.results_label = UI.Widgets.LuiLabel()
    self.results_label:SetParent(self)
    self.results_label:SetMouseVisible(false)
    self.results_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.results_label:SetForeColor(Style.ALTERNATE_FOREGROUND)

    self:apply_fonts()
end

-- All + the categories used by this kind, in the label order baked per
-- language by the extractor (no runtime sorting)
function QuestBrowserPanel:_category_options()
    local Quests = Lore.Quests
    local cats = self._kind == "deed" and Quests.DEED_CATS or Quests.QUEST_CATS
    local order = self._kind == "deed" and Quests.DEED_CATS_ORDER or Quests.QUEST_CATS_ORDER
    local labels, values = { TR["All"] }, { FILTER_ALL_CODE }
    for i = 1, #order do
        local code = order[i]
        labels[#labels + 1] = cats[code]
        values[#values + 1] = code
    end
    return labels, values
end

function QuestBrowserPanel:apply_fonts()
    local font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 2)
    self.search_box:SetFont(font)
    self.category_label:SetFont(font)
    self.category_dropdown:SetFont(font)
    self.category_dropdown:set_scale(State.settings.global.scale)
    self.table:set_header_font(font)
    for slot = 1, #self._table_cells do
        local cells = self._table_cells[slot]
        cells.name_label:SetFont(font)
        cells.category_label:SetFont(font)
        cells.level_label:SetFont(font)
    end
    self.level_label:SetFont(font)
    self.level_min_box:SetFont(font)
    self.level_dash_label:SetFont(font)
    self.level_max_box:SetFont(font)
    self.pager:set_font(font)
    self.pager:set_scale(State.settings.global.scale)
    self.results_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
end

function QuestBrowserPanel:_parse_level(text)
    return BrowserShared.parse_level(text)
end

function QuestBrowserPanel:_on_filters_changed()
    self._level_min = self:_parse_level(self.level_min_box:GetText())
    self._level_max = self:_parse_level(self.level_max_box:GetText())
    self:_sync_pager(1)
    self:_refresh_list()
end

-- programmatic pager updates inside a refresh flow: the flow renders once
-- itself, so the pager's changed callback must not render again
function QuestBrowserPanel:_sync_pager(page, page_count)
    self._pager_syncing = true
    if page ~= nil then
        self.pager:set_page(page)
    end
    if page_count ~= nil then
        self.pager:set_page_count(page_count)
    end
    self._pager_syncing = false
end

function QuestBrowserPanel:_rebuild_filtered()
    local Quests = Lore.Quests
    local query = self.search_box:GetText() or ""
    local filter_sig = table.concat({
        tostring(self._category_filter),
        tostring(self._level_min or ""),
        tostring(self._level_max or ""),
    }, "\30")
    local signature = query .. "\30" .. filter_sig
    if signature == self._signature and self._filtered ~= nil then
        return
    end

    -- keystroke fast path: appending to a '|'-free query only narrows the
    -- match set (terms grow, none are removed, no OR group appears), so
    -- the previous result is re-filtered by the new search set instead of
    -- rescanning the whole domain on every character typed
    local previous = self._filtered
    local can_refine = previous ~= nil
        and self._filter_sig == filter_sig
        and type(self._query) == "string"
        and #query > #self._query
        and query:sub(1, #self._query) == self._query
        and query:find("|", 1, true) == nil
    self._signature = signature
    self._query = query
    self._filter_sig = filter_sig

    if can_refine == true then
        local state = SearchQuery.parse(query, {})
        local search_set = SearchQuery.evaluate_domain(state.normalized_groups, Quests)
        if search_set ~= nil then
            local filtered, n = {}, 0
            for i = 1, #previous do
                local ordinal = previous[i]
                if search_set[ordinal] == true then
                    n = n + 1
                    filtered[n] = ordinal
                end
            end
            self._filtered = filtered
        end
        -- a nil set means the appended text is still below the seed
        -- threshold ("still typing"): search applies no filter, so the
        -- previous result already is the exact answer
        return
    end

    local state = SearchQuery.parse(query, {})
    local search_set = SearchQuery.evaluate_domain(state.normalized_groups, Quests)
    local category = self._category_filter
    local level_min = self._level_min
    local level_max = self._level_max
    local list = Quests.kind_list(self._kind)
    local need_brief = category ~= FILTER_ALL_CODE or level_min ~= nil or level_max ~= nil
    local filtered, n = {}, 0
    for i = 1, #list do
        local ordinal = list[i]
        if search_set == nil or search_set[ordinal] == true then
            local ok = true
            if need_brief then
                local _, level, _, cat = Quests.brief(ordinal)
                ok = (category == FILTER_ALL_CODE or cat == category)
                    and (level_min == nil or level >= level_min)
                    and (level_max == nil or level <= level_max)
            end
            if ok then
                n = n + 1
                filtered[n] = ordinal
            end
        end
    end
    self._filtered = filtered
end

function QuestBrowserPanel:_page_capacity()
    return math.max(1, self.table:visible_capacity())
end

function QuestBrowserPanel:_page_count()
    local capacity = self:_page_capacity()
    if self._filtered == nil or #self._filtered == 0 then
        return 1
    end
    return math.ceil(#self._filtered / capacity)
end

function QuestBrowserPanel:_ensure_table_row(slot)
    local cells = self._table_cells[slot]
    if cells ~= nil then
        return cells
    end
    local font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 2)

    local function make_label(alignment)
        local label = UI.Widgets.LuiLabel()
        label:SetMouseVisible(false)
        label:SetSelectable(false)
        label:SetMultiline(false)
        label:SetTextAlignment(alignment)
        label:SetFont(font)
        return label
    end

    cells = {
        name_label = make_label(Turbine.UI.ContentAlignment.MiddleLeft),
        category_label = make_label(Turbine.UI.ContentAlignment.MiddleLeft),
        level_label = make_label(Turbine.UI.ContentAlignment.MiddleCenter),
    }
    cells.name_label:SetMultiline(true)

    self.table:append_row({ cells.name_label, cells.category_label, cells.level_label })
    self._table_cells[slot] = cells
    return cells
end

function QuestBrowserPanel:_render_table_page(capacity, first)
    local Quests = Lore.Quests
    local filtered = self._filtered
    local shown = math.min(capacity, #filtered - first)
    if shown < 0 then
        shown = 0
    end

    for slot = 1, shown do
        local ordinal = filtered[first + slot]
        local cells = self:_ensure_table_row(slot)
        local is_deed, level, _, cat_code = Quests.brief(ordinal)
        local cats = is_deed and Quests.DEED_CATS or Quests.QUEST_CATS
        cells.name_label:SetText(Quests.label(ordinal))
        cells.category_label:SetText(cats[cat_code] or "")
        cells.level_label:SetText(level > 0 and tostring(level) or "")
        self.table:set_row_data(slot, ordinal)
    end

    self.table:set_visible_rows(shown)
end

function QuestBrowserPanel:_render_page()
    local capacity = self:_page_capacity()
    local first = (self.pager:get_page() - 1) * capacity

    self:_render_table_page(capacity, first)

    self.results_label:SetText(tostring(#self._filtered) .. " " .. TR["results"])
end

function QuestBrowserPanel:_refresh_list()
    self:_rebuild_filtered()
    self:_sync_pager(nil, self:_page_count())
    self:_render_page()
end

function QuestBrowserPanel:layout()
    local width, height = self:GetSize()
    local gap = scaled_int(BASE_GAP)
    local bar_h = scaled_int(BASE_BAR_H)
    local margins = Encyclopedia.CONTENT_MARGINS
    local margin_l = scaled_int(margins.left)
    local margin_t = scaled_int(margins.top)
    local margin_r = scaled_int(margins.right)
    local margin_b = scaled_int(margins.bottom)
    local inner_w = width - margin_l - margin_r
    local level_w = scaled_int(BASE_LEVEL_W)
    local category_w = scaled_int(self._category_dd_base_w)

    -- row 1: Category left, Level range flush right
    local category_label_w = scaled_int(64)
    local dash_w = scaled_int(10)
    local level_label_w = scaled_int(42)
    local level_block_w = level_label_w + gap + level_w + gap + dash_w + gap + level_w

    local x = margin_l
    self.category_label:SetPosition(x, margin_t)
    self.category_label:SetSize(category_label_w, bar_h)
    x = x + category_label_w + gap
    self.category_dropdown:SetPosition(x, margin_t)
    self.category_dropdown:SetSize(category_w, bar_h)

    local level_x = width - margin_r - level_block_w
    self.level_label:SetPosition(level_x, margin_t)
    self.level_label:SetSize(level_label_w, bar_h)
    level_x = level_x + level_label_w + gap
    self.level_min_box:SetPosition(level_x, margin_t)
    self.level_min_box:SetSize(level_w, bar_h)
    level_x = level_x + level_w + gap
    self.level_dash_label:SetPosition(level_x, margin_t)
    self.level_dash_label:SetSize(dash_w, bar_h)
    level_x = level_x + dash_w + gap
    self.level_max_box:SetPosition(level_x, margin_t)
    self.level_max_box:SetSize(level_w, bar_h)

    -- row 2: search across the full width
    local search_y = margin_t + bar_h + gap
    self.search_box:SetPosition(margin_l, search_y)
    self.search_box:SetSize(inner_w, bar_h)

    -- table fills the middle; footer page bar at the bottom
    local page_bar_h = scaled_int(BASE_PAGE_BAR_H)
    local table_y = search_y + bar_h + gap
    local table_h = height - table_y - margin_b - gap - page_bar_h
    self.table:set_row_height(scaled_int(28))
    self.table:SetPosition(margin_l, table_y)
    self.table:SetSize(inner_w, math.max(1, table_h))

    local page_w = scaled_int(BASE_PAGE_W)
    local footer_y = height - margin_b - page_bar_h
    self.pager:set_metrics(scaled_int(BASE_NAV_W), gap)
    local pager_w = self.pager:preferred_width(page_w)
    local pager_x = margin_l + math.max(0, math.floor((inner_w - pager_w) / 2))
    self.pager:SetPosition(pager_x, footer_y)
    self.pager:SetSize(pager_w, page_bar_h)

    local results_w = scaled_int(140)
    self.results_label:SetPosition(margin_l + inner_w - results_w, footer_y)
    self.results_label:SetSize(results_w, page_bar_h)

    -- SizeChanged fires every frame during a drag resize: resize frames
    -- only move controls; rows re-render only when the page capacity
    -- actually changed (filter edits re-render via _on_filters_changed)
    local capacity = self:_page_capacity()
    if capacity ~= self._layout_capacity then
        self._layout_capacity = capacity
        self:_refresh_list()
    end
end

-- ---- Quests tab host: nested sub-tab bar (Quests / Deeds) ----------------

local QuestsTabPanel = class(Turbine.UI.Control)
Encyclopedia.QuestsTabPanel = QuestsTabPanel

local SUB_TAB_KINDS = { "quest", "deed" }

function QuestsTabPanel:Constructor(popup_host)
    Turbine.UI.Control.Constructor(self)

    self._popup_host = popup_host
    self._panels = {}
    self._active_sub_tab = 1

    self:SetMouseVisible(true)

    self._sub_hosts = {}
    self.sub_tabs = UI.Widgets.LuiTabBar()
    self.sub_tabs:SetParent(self)
    for index = 1, #SUB_TAB_KINDS do
        local host = Turbine.UI.Control()
        host:SetMouseVisible(true)
        self._sub_hosts[index] = host
    end
    self.sub_tabs:add_tab(TR["Quests"], self._sub_hosts[1])
    self.sub_tabs:add_tab(TR["Deeds"], self._sub_hosts[2])
    self.sub_tabs.on_tab_changed = function(index)
        self:_set_sub_tab(index)
    end
    self.sub_tabs:set_content_padding(0)
    self.sub_tabs:set_show_border_left(false)
    self.sub_tabs:set_show_border_right(false)
    self.sub_tabs:set_show_border_bottom(false)
    self.sub_tabs:set_show_tab_cap_left(true)
    self.sub_tabs:set_show_tab_cap_right(true)
    self.sub_tabs:set_show_tab_cap_bottom(true)
    self.sub_tabs:set_scale(State.settings.global.scale)
    self.sub_tabs:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + 1))
    self.sub_tabs:set_selected_index(1, false)
end

-- panels are created lazily from layout(), never at construction time:
-- the first layout pass runs once the window has sized this panel, so
-- the browser is born with real dimensions (a constructor-time layout at
-- 0x0 briefly rendered a collapsed table on first open)
function QuestsTabPanel:_ensure_sub_panel(index)
    if self._panels[index] ~= nil then
        return
    end
    local panel = QuestBrowserPanel(SUB_TAB_KINDS[index], self._popup_host)
    panel:SetParent(self._sub_hosts[index])
    panel.on_quest_open = function(ordinal)
        if type(self.on_quest_open) == "function" then
            self.on_quest_open(ordinal)
        end
    end
    self._panels[index] = panel
end

function QuestsTabPanel:_set_sub_tab(index)
    self._active_sub_tab = index
    self:layout()
end

function QuestsTabPanel:apply_fonts()
    self.sub_tabs:set_scale(State.settings.global.scale)
    self.sub_tabs:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + 1))
    for _, panel in pairs(self._panels) do
        panel:apply_fonts()
    end
end

function QuestsTabPanel:layout()
    local width, height = self:GetSize()
    if width <= 0 or height <= 0 then
        return
    end
    self.sub_tabs:SetPosition(0, 0)
    self.sub_tabs:SetSize(width, height)
    -- Turbine may deliver the SizeChanged of a programmatic SetSize a
    -- frame late; the sub host must be sized NOW because the browser
    -- panel below reads it in this same call stack
    self.sub_tabs:_layout()

    self:_ensure_sub_panel(self._active_sub_tab)
    local panel = self._panels[self._active_sub_tab]
    local host = self._sub_hosts[self._active_sub_tab]
    panel:SetPosition(0, 0)
    panel:SetSize(host:GetSize())
    panel:layout()
end
