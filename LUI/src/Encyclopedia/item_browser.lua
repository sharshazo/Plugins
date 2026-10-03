-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Encyclopedia item browser tab: a paged, searchable, filterable listing
-- over one lore-DB item bucket (equipment / consumable / resource).
-- Search is the packed type-ahead (folded blob, session cache); filters are
-- byte probes over the record tuples; the listing order is the per-language
-- label-sorted permutation baked by the converter.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Style = UI.Widgets.Style
local scaled_int = UI.NativeScaling.scaled_int
local class = _G.LUI.Core.class
local Lore = _G.LUI.Data.Lore
local SearchQuery = _G.LUI.Utils.SearchQuery
local Encyclopedia = _G.LUI.Features.Encyclopedia
local Crafting = _G.LUI.Features.Crafting
local Shortcuts = UI.Shortcuts
import "Turbine.UI"
import "LUI.src.UI.Widgets.item_icon"

-- control metrics match the bestiary filter bar (21px controls, 4px gaps)
local BASE_BAR_H = 21
-- native item art is 32px and must never be scaled (stretch mode 0 tiles)
local BASE_ICON_SIDE = 32
local BASE_GAP = 4
-- page bar matches the bestiary tab exactly (22x21 square nav buttons)
local BASE_NAV_W = 22
local BASE_PAGE_BAR_H = 21
local BASE_PAGE_W = 74
local BASE_LEVEL_W = 44

local FILTER_ALL_CODE = 0
-- grouped Type entry matching every per-tier recipe class (Items.RECIPE_CLASS_SET)
local FILTER_RECIPES_CODE = -1

-- shared browser scaffolding (browser_shared.lua); the dropdown max clamp
-- is this tab's only variation
local BrowserShared = Encyclopedia.BrowserShared
local BASE_DROPDOWN_MAX_W = 190

local function _dropdown_base_w(labels)
    return BrowserShared.dropdown_base_w(labels, BASE_DROPDOWN_MAX_W)
end

local _scaled_font = BrowserShared.scaled_font

-- link action icons: identical treatment to the crafting window's
-- bestiary button on drop resources (16px icon in a 22px square button)
local CRAFT_ACTION_ICON = UI.AssetIds.anvil_silver_glow
local BESTIARY_ACTION_ICON = UI.AssetIds.book_orange_cover
local BASE_LINK_BUTTON_W = 22

local function _apply_link_icon(button, icon)
    local side = math.max(14, scaled_int(16))
    button:set_icon(
        icon,
        icon,
        icon,
        icon,
        side,
        side,
        UI.Widgets.LuiButton.icon_position.LEFT
    )
end

local function _even_int(value)
    local out = math.floor(value + 0.5)
    if out % 2 ~= 0 then
        out = out - 1
    end
    if out < 0 then
        out = 0
    end
    return out
end

local ItemBrowserPanel = class(Turbine.UI.Control)
Encyclopedia.ItemBrowserPanel = ItemBrowserPanel

function ItemBrowserPanel:Constructor(bucket_name, popup_host)
    Turbine.UI.Control.Constructor(self)

    self._bucket = bucket_name
    self._popup_host = popup_host
    self._filtered = nil
    self._signature = nil
    self._quality_filter = FILTER_ALL_CODE
    self._class_filter = FILTER_ALL_CODE
    self._level_min = nil
    self._level_max = nil
    self._ilvl_min = nil
    self._ilvl_max = nil

    self:SetMouseVisible(true)
    self:SetBackColor(Style.PANEL_BACKGROUND)

    Lore.load_items()

    self.search_box = UI.Widgets.LuiLineEdit()
    self.search_box:SetParent(self)
    self.search_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.search_box:set_placeholder_text(TR["Search..."])
    self.search_box.TextChanged = function()
        self:_on_filters_changed()
    end

    self.type_label = UI.Widgets.LuiLabel()
    self.type_label:SetParent(self)
    self.type_label:SetMouseVisible(false)
    self.type_label:SetSelectable(false)
    self.type_label:SetMultiline(false)
    self.type_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.type_label:SetText(TR["Type"] .. ":")

    self.rarity_label = UI.Widgets.LuiLabel()
    self.rarity_label:SetParent(self)
    self.rarity_label:SetMouseVisible(false)
    self.rarity_label:SetSelectable(false)
    self.rarity_label:SetMultiline(false)
    self.rarity_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.rarity_label:SetText(TR["Rarity"] .. ":")

    self.quality_dropdown = UI.Widgets.LuiDropdown()
    self.quality_dropdown:SetParent(self)
    self.quality_dropdown:SetPopupHost(popup_host)
    self.quality_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    -- official localized quality names from the game data (LEGENDARY
    -- displays as "Epic" in-game, so no hand-written labels here)
    local quality_labels, quality_values = { TR["All"] }, { FILTER_ALL_CODE }
    for code = 1, #Lore.Items.QUALITY_NAMES do
        local name = Lore.Items.QUALITY_NAMES[code]
        quality_labels[#quality_labels + 1] = Lore.Items.QUALITY_LABELS[name]
        quality_values[#quality_values + 1] = code
    end
    self.quality_dropdown:SetMappedOptions(quality_labels, quality_values)
    self._quality_dd_base_w = _dropdown_base_w(quality_labels)
    self.quality_dropdown.ValueChanged = function(_, value)
        self._quality_filter = tonumber(value) or FILTER_ALL_CODE
        self:_on_filters_changed()
    end

    self.class_dropdown = UI.Widgets.LuiDropdown()
    self.class_dropdown:SetParent(self)
    self.class_dropdown:SetPopupHost(popup_host)
    self.class_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    local class_labels, class_values = self:_class_options()
    self.class_dropdown:SetMappedOptions(class_labels, class_values)
    self._class_dd_base_w = _dropdown_base_w(class_labels)
    self.class_dropdown.ValueChanged = function(_, value)
        self._class_filter = tonumber(value) or FILTER_ALL_CODE
        self:_on_filters_changed()
    end

    -- traceries only: player-class filter; the level boxes switch to
    -- LI item-level band semantics in _rebuild_filtered
    self._pclass_filter = nil
    if self._bucket == "tracery" then
        Lore.load_traceries()
        self._pclass_filter = FILTER_ALL_CODE
        self.pclass_label = UI.Widgets.LuiLabel()
        self.pclass_label:SetParent(self)
        self.pclass_label:SetMouseVisible(false)
        self.pclass_label:SetSelectable(false)
        self.pclass_label:SetMultiline(false)
        self.pclass_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        self.pclass_label:SetText(TR["Class"] .. ":")

        self.pclass_dropdown = UI.Widgets.LuiDropdown()
        self.pclass_dropdown:SetParent(self)
        self.pclass_dropdown:SetPopupHost(popup_host)
        self.pclass_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        local pclass_labels, pclass_values = { TR["All"] }, { FILTER_ALL_CODE }
        for idx = 1, #Lore.Traceries.CLASS_LABELS do
            pclass_labels[#pclass_labels + 1] = Lore.Traceries.CLASS_LABELS[idx]
            pclass_values[#pclass_values + 1] = idx
        end
        self.pclass_dropdown:SetMappedOptions(pclass_labels, pclass_values)
        self._pclass_dd_base_w = _dropdown_base_w(pclass_labels)
        self.pclass_dropdown.ValueChanged = function(_, value)
            self._pclass_filter = tonumber(value) or FILTER_ALL_CODE
            self:_on_filters_changed()
        end

        -- a second range next to Level: the Level boxes match the usable
        -- character band, these match the tracery's BASE iLvl
        self.ilvl_label = UI.Widgets.LuiLabel()
        self.ilvl_label:SetParent(self)
        self.ilvl_label:SetMouseVisible(false)
        self.ilvl_label:SetSelectable(false)
        self.ilvl_label:SetMultiline(false)
        self.ilvl_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        self.ilvl_label:SetText("iLvl:")

        self.ilvl_min_box = UI.Widgets.LuiLineEdit()
        self.ilvl_min_box:SetParent(self)
        self.ilvl_min_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        self.ilvl_min_box.TextChanged = function()
            self:_on_filters_changed()
        end

        self.ilvl_dash_label = UI.Widgets.LuiLabel()
        self.ilvl_dash_label:SetParent(self)
        self.ilvl_dash_label:SetMouseVisible(false)
        self.ilvl_dash_label:SetSelectable(false)
        self.ilvl_dash_label:SetMultiline(false)
        self.ilvl_dash_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        self.ilvl_dash_label:SetText("-")

        self.ilvl_max_box = UI.Widgets.LuiLineEdit()
        self.ilvl_max_box:SetParent(self)
        self.ilvl_max_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        self.ilvl_max_box.TextChanged = function()
            self:_on_filters_changed()
        end

    end

    -- every tab lists through a LuiTable (paged mode; this panel's footer
    -- drives the pagination); rows are pooled cell widgets updated in
    -- place per page. Chrome comes entirely from the shared style
    -- (TABLE_* tokens + the generic colors).
    self.table = UI.Widgets.LuiTable()
    self.table:SetParent(self)
    self.table:set_auto_height(true)
    if self._bucket == "tracery" then
        self.table:set_columns({
            { title = "", width = 40 },
            { title = TR["Name"] },
            { title = TR["Type"], width = 140 },
            { title = TR["Class"], width = 110 },
            { title = TR["Level"], width = 76 },
            { title = "iLvl", width = 46 },
            { title = TR["Limit"], width = 46 },
        })
    else
        self.table:set_columns({
            { title = "", width = 40 },
            { title = TR["Name"] },
            { title = TR["Type"], width = 170 },
            { title = TR["Level"], width = 70 },
            { title = "", width = 60 },
        })
    end
    self._table_cells = {}

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

    -- same pager as the bestiary page bar; during _sync_pager the caller
    -- renders right after, so the callback skips its own render
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

function ItemBrowserPanel:_class_options()
    local Items = Lore.Items
    -- label-sorted class codes baked per language by the extractor
    -- (recipe classes excluded there); no runtime sorting
    local order = Items.CLASS_ORDER[self._bucket]
    local labels, values = { TR["All"] }, { FILTER_ALL_CODE }
    for i = 1, #order do
        local code = order[i]
        labels[#labels + 1] = Items.CLASSES[code]
        values[#values + 1] = code
    end
    -- ~100 "Recipe: <profession> Tier n" classes collapse into one
    -- grouped dropdown entry (rows keep their real class as meta); the
    -- baked order cannot know its plugin-locale label, so place the one
    -- entry with a single ordered insertion scan
    local codes = Items.BUCKET_CLASSES[self._bucket]
    for i = 1, #codes do
        if Items.RECIPE_CLASS_SET[codes[i]] == true then
            local recipes_label = TR["Recipes"]
            local needle = string.lower(recipes_label)
            local insert_at = #labels + 1
            for k = 2, #labels do -- position 1 is "All"
                if needle < string.lower(labels[k]) then
                    insert_at = k
                    break
                end
            end
            table.insert(labels, insert_at, recipes_label)
            table.insert(values, insert_at, FILTER_RECIPES_CODE)
            break
        end
    end
    return labels, values
end

function ItemBrowserPanel:apply_fonts()
    local font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 2)
    self.search_box:SetFont(font)
    self.type_label:SetFont(font)
    self.rarity_label:SetFont(font)
    self.quality_dropdown:SetFont(font)
    self.quality_dropdown:set_scale(State.settings.global.scale)
    self.class_dropdown:SetFont(font)
    self.class_dropdown:set_scale(State.settings.global.scale)
    if self.pclass_dropdown ~= nil then
        self.pclass_label:SetFont(font)
        self.pclass_dropdown:SetFont(font)
        self.pclass_dropdown:set_scale(State.settings.global.scale)
        self.ilvl_label:SetFont(font)
        self.ilvl_min_box:SetFont(font)
        self.ilvl_dash_label:SetFont(font)
        self.ilvl_max_box:SetFont(font)
    end
    self.table:set_header_font(font)
    for slot = 1, #self._table_cells do
        local cells = self._table_cells[slot]
        for _, key in ipairs(cells.label_keys) do
            cells[key]:SetFont(font)
        end
        if cells.craft_button ~= nil then
            cells.craft_button:set_scale(1)
            _apply_link_icon(cells.craft_button, CRAFT_ACTION_ICON)
            cells.bestiary_button:set_scale(1)
            _apply_link_icon(cells.bestiary_button, BESTIARY_ACTION_ICON)
        end
    end
    self.level_label:SetFont(font)
    self.level_min_box:SetFont(font)
    self.level_dash_label:SetFont(font)
    self.level_max_box:SetFont(font)
    self.pager:set_font(font)
    self.pager:set_scale(State.settings.global.scale)
    self.results_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
end

function ItemBrowserPanel:_parse_level(text)
    return BrowserShared.parse_level(text)
end

function ItemBrowserPanel:_on_filters_changed()
    self._level_min = self:_parse_level(self.level_min_box:GetText())
    self._level_max = self:_parse_level(self.level_max_box:GetText())
    if self.ilvl_min_box ~= nil then
        self._ilvl_min = self:_parse_level(self.ilvl_min_box:GetText())
        self._ilvl_max = self:_parse_level(self.ilvl_max_box:GetText())
    end
    self:_sync_pager(1)
    self:_refresh_list()
end

-- programmatic pager updates inside a refresh flow: the flow renders once
-- itself, so the pager's changed callback must not render again
function ItemBrowserPanel:_sync_pager(page, page_count)
    self._pager_syncing = true
    if page ~= nil then
        self.pager:set_page(page)
    end
    if page_count ~= nil then
        self.pager:set_page_count(page_count)
    end
    self._pager_syncing = false
end

-- shared query grammar (space = AND, | = OR, quotes = literal phrase),
-- evaluated over the packed per-term search sets: intersect terms inside a
-- group, union the groups. nil means "no search filter".
local function _search_set_for_query(query)
    local state = SearchQuery.parse(query, {})
    return SearchQuery.evaluate_domain(state.normalized_groups, Lore.Items)
end

function ItemBrowserPanel:_rebuild_filtered()
    local Items = Lore.Items
    local query = self.search_box:GetText() or ""
    local filter_sig = table.concat({
        tostring(self._quality_filter),
        tostring(self._class_filter),
        tostring(self._pclass_filter or ""),
        tostring(self._level_min or ""),
        tostring(self._level_max or ""),
        tostring(self._ilvl_min or ""),
        tostring(self._ilvl_max or ""),
    }, "\30")
    local signature = query .. "\30" .. filter_sig
    if signature == self._signature and self._filtered ~= nil then
        return
    end

    -- keystroke fast path: appending to a '|'-free query only narrows the
    -- match set (terms grow, none are removed, no OR group appears), so
    -- the previous result is re-filtered by the new search set instead of
    -- rescanning the whole bucket on every character typed
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
        local search_set = _search_set_for_query(query)
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

    local search_set = _search_set_for_query(query)
    local quality = self._quality_filter
    local class_code = self._class_filter
    local recipe_class_set = class_code == FILTER_RECIPES_CODE and Items.RECIPE_CLASS_SET or nil
    local is_tracery = self._bucket == "tracery"
    local pclass = self._pclass_filter
    local level_min = self._level_min
    local level_max = self._level_max
    local ilvl_min = self._ilvl_min
    local ilvl_max = self._ilvl_max
    local list = Items.bucket_list(self._bucket)
    local filtered, n = {}, 0
    for i = 1, #list do
        local ordinal = list[i]
        if search_set == nil or search_set[ordinal] == true then
            if quality == FILTER_ALL_CODE or Items.quality_code(ordinal) == quality then
                if class_code == FILTER_ALL_CODE
                    or (recipe_class_set ~= nil and recipe_class_set[Items.class_code(ordinal)] == true)
                    or Items.class_code(ordinal) == class_code then
                    local ok = true
                    if is_tracery == true then
                        local min_il, max_il, _, tr_class, char_max = Lore.Traceries.info(ordinal)
                        if pclass ~= FILTER_ALL_CODE and tr_class ~= pclass then
                            ok = false
                        end
                        -- Level range: the usable character band must
                        -- overlap it (a single value means "usable at X")
                        if ok and (level_min ~= nil or level_max ~= nil) then
                            local char_min = Items.min_level(ordinal) or 1
                            local lo = level_min or level_max
                            local hi = level_max or level_min
                            if char_max < lo or char_min > hi then
                                ok = false
                            end
                        end
                        -- iLvl range: the tracery's BASE iLvl within it,
                        -- so 450-499 shows the 450 tier only, never lower
                        -- tiers whose enhancement cap merely covers 450
                        if ok and ((ilvl_min ~= nil and min_il < ilvl_min)
                            or (ilvl_max ~= nil and min_il > ilvl_max)) then
                            ok = false
                        end
                    elseif level_min ~= nil or level_max ~= nil then
                        -- equipable/required character level; items with
                        -- no requirement are usable from level 1
                        local level = Items.min_level(ordinal) or 1
                        if level_min ~= nil and level < level_min then
                            ok = false
                        end
                        if ok and level_max ~= nil and level > level_max then
                            ok = false
                        end
                    end
                    if ok then
                        n = n + 1
                        filtered[n] = ordinal
                    end
                end
            end
        end
    end
    self._filtered = filtered
end

function ItemBrowserPanel:_page_capacity()
    return math.max(1, self.table:visible_capacity())
end

function ItemBrowserPanel:_page_count()
    if self._filtered == nil then
        return 1
    end
    local capacity = self:_page_capacity()
    return math.max(1, math.ceil(#self._filtered / capacity))
end

-- one pooled row of cell widgets for the traceries table; updated in
-- place per page, never recreated
function ItemBrowserPanel:_ensure_table_row(slot)
    if self._table_cells[slot] ~= nil then
        return self._table_cells[slot]
    end

    local cells = {}
    -- the icon keeps its native 32px side inside the cell rect the table
    -- assigns; centering runs explicitly at render time (no SizeChanged:
    -- internal-widget size events fire every frame during window resizes)
    cells.icon_host = Turbine.UI.Control()
    cells.icon_host:SetMouseVisible(false)
    cells.icon = UI.Widgets.LuiItemIcon()
    cells.icon:set_side(BASE_ICON_SIDE)
    cells.icon:SetParent(cells.icon_host)
    cells.center_icon = function()
        local w, h = cells.icon_host:GetSize()
        cells.icon:SetPosition(math.max(0, math.floor((w - BASE_ICON_SIDE) / 2)),
            math.max(0, math.floor((h - BASE_ICON_SIDE) / 2)))
    end
    cells.name = UI.Widgets.LuiLabel()
    cells.name:SetMouseVisible(false)
    cells.name:SetSelectable(false)
    cells.name:SetMultiline(true)
    cells.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    if self._bucket == "tracery" then
        cells.label_keys = { "name", "type", "class", "level", "ilvl", "limit" }
    else
        cells.label_keys = { "name", "type", "level" }
    end
    for _, key in ipairs(cells.label_keys) do
        if key ~= "name" then
            local label = UI.Widgets.LuiLabel()
            label:SetMouseVisible(false)
            label:SetSelectable(false)
            label:SetMultiline(false)
            label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
            cells[key] = label
        end
    end

    local font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 2)
    for _, key in ipairs(cells.label_keys) do
        cells[key]:SetFont(font)
        cells[key]:SetForeColor(Style.FOREGROUND)
    end

    if self._bucket == "tracery" then
        self.table:append_row({ cells.icon_host, cells.name, cells.type, cells.class,
            cells.level, cells.ilvl, cells.limit })
    else
        -- action cell: crafting anvil + bestiary book, the batch-1 links
        cells.actions = Turbine.UI.Control()
        cells.actions:SetMouseVisible(false)
        cells.craft_button = UI.Widgets.LuiButton()
        cells.craft_button:SetParent(cells.actions)
        cells.craft_button:set_scale(1)
        _apply_link_icon(cells.craft_button, CRAFT_ACTION_ICON)
        cells.craft_button:SetVisible(false)
        cells.craft_button.Click = function()
            Shortcuts.open_crafting_item_search(cells._craft_search_name, cells._link_recipe_id)
        end
        cells.bestiary_button = UI.Widgets.LuiButton()
        cells.bestiary_button:SetParent(cells.actions)
        cells.bestiary_button:set_scale(1)
        _apply_link_icon(cells.bestiary_button, BESTIARY_ACTION_ICON)
        cells.bestiary_button:SetVisible(false)
        cells.bestiary_button.Click = function()
            Shortcuts.open_bestiary_item_search(cells._link_name)
        end
        -- explicit layout at render time (no SizeChanged on internal
        -- widgets): the two-slot block is centered in the cell, slots stay
        -- fixed (anvil left, book right) so buttons align across rows
        cells.layout_actions = function()
            local w, h = cells.actions:GetSize()
            local side = math.min(scaled_int(BASE_LINK_BUTTON_W), math.max(0, h - 2))
            local y = math.max(0, math.floor((h - side) / 2))
            local gap = scaled_int(BASE_GAP)
            local block_x = math.max(0, math.floor((w - (2 * side) - gap) / 2))
            cells.craft_button:SetSize(side, side)
            cells.craft_button:SetPosition(block_x, y)
            cells.bestiary_button:SetSize(side, side)
            cells.bestiary_button:SetPosition(block_x + side + gap, y)
        end
        self.table:append_row({ cells.icon_host, cells.name, cells.type,
            cells.level, cells.actions })
    end
    self._table_cells[slot] = cells
    return cells
end

function ItemBrowserPanel:_render_table_page(capacity, first)
    local Items = Lore.Items
    local Tr = Lore.Traceries
    -- the table ends on the last filled row (auto height)
    self.table:set_visible_rows(math.max(0, math.min(capacity, #self._filtered - first)))
    for slot = 1, math.max(capacity, self.table:row_count()) do
        local cells = self:_ensure_table_row(slot)
        local ordinal = self._filtered[first + slot]
        if ordinal ~= nil and slot <= capacity then
            local icon_id, background_id = Items.icon_layers(ordinal)
            cells.icon:bind(icon_id, background_id, Items.id_of(ordinal))
            cells.center_icon()
            local name = Items.label(ordinal)
            cells.name:SetText(name)
            if self._bucket == "tracery" then
                local min_il, max_il, _, tr_class, char_max = Tr.info(ordinal)
                cells.type:SetText(Items.class_name(ordinal))
                -- unrestricted traceries (heraldic/power/craft): no class
                cells.class:SetText(Tr.class_label(tr_class) or "-")
                local char_min = Items.min_level(ordinal)
                cells.level:SetText(char_min ~= nil
                    and (tostring(char_min) .. " - " .. tostring(char_max)) or "-")
                cells.ilvl:SetText(tostring(min_il))
                cells.limit:SetText(tostring(max_il))
            else
                cells.type:SetText(Items.class_name(ordinal) or "")
                -- equipable/required character level, never the item level
                local level = Items.min_level(ordinal)
                cells.level:SetText(level ~= nil and tostring(level) or "")
                -- O(1) name probes decide the crafting link; the store is
                -- nil only while the crafting feature is disabled
                local store = Crafting.get_shared_store()
                local linkable = false
                local craft_search_name = name
                local craft_recipe_id = nil
                if store ~= nil then
                    local producing = store:first_recipe_producing_name(name)
                    linkable = producing ~= nil or store:has_recipes_using_name(name) == true
                    if producing ~= nil then
                        craft_recipe_id = producing.id
                    end
                    if linkable ~= true then
                        -- recipe scrolls: the anvil opens the recipe the
                        -- scroll teaches, searched by its result name
                        local taught = store:recipe_taught_by_item_id(Items.id_of(ordinal))
                        if taught ~= nil then
                            linkable = true
                            craft_recipe_id = taught.id
                            craft_search_name = store:recipe_result_display_name(taught)
                        end
                    end
                end
                cells._link_name = name
                cells._craft_search_name = craft_search_name
                cells._link_recipe_id = craft_recipe_id
                cells.craft_button:SetVisible(linkable == true)
                cells.bestiary_button:SetVisible(Encyclopedia.has_droppable_item(name) == true)
                cells.layout_actions()
            end
            self.table:set_row_data(slot, ordinal)
        else
            cells.icon:bind(nil, nil, nil)
            for _, key in ipairs(cells.label_keys) do
                cells[key]:SetText("")
            end
            if cells.craft_button ~= nil then
                cells.craft_button:SetVisible(false)
                cells.bestiary_button:SetVisible(false)
            end
            self.table:set_row_data(slot, nil)
        end
    end
end

function ItemBrowserPanel:_render_page()
    local capacity = self:_page_capacity()
    local first = (self.pager:get_page() - 1) * capacity

    self:_render_table_page(capacity, first)

    self.results_label:SetText(tostring(#self._filtered) .. " " .. TR["results"])
end

function ItemBrowserPanel:_refresh_list()
    self:_rebuild_filtered()
    self:_sync_pager(nil, self:_page_count())
    self:_render_page()
end

-- Cross-window link entry (card drop chips): exact-name search with every
-- filter reset so the match can never be hidden.
function ItemBrowserPanel:open_item_search(item_name)
    local query = item_name
    if string.find(query, "\"", 1, true) == nil then
        query = "\"" .. query .. "\""
    end

    self._quality_filter = FILTER_ALL_CODE
    self._class_filter = FILTER_ALL_CODE
    self.quality_dropdown:SetValue(FILTER_ALL_CODE)
    self.class_dropdown:SetValue(FILTER_ALL_CODE)
    if self.pclass_dropdown ~= nil then
        self._pclass_filter = FILTER_ALL_CODE
        self.pclass_dropdown:SetValue(FILTER_ALL_CODE)
    end
    self.level_min_box:SetText("")
    self.level_max_box:SetText("")
    if self.ilvl_min_box ~= nil then
        self.ilvl_min_box:SetText("")
        self.ilvl_max_box:SetText("")
    end
    self.search_box:SetText(query)
    self.search_box:refresh_text_async()
    -- programmatic SetText does not fire TextChanged: refresh explicitly
    self:_on_filters_changed()
end

function ItemBrowserPanel:layout()
    local width, height = self:GetSize()
    local gap = scaled_int(BASE_GAP)
    local bar_h = scaled_int(BASE_BAR_H)
    -- shared margins from the encyclopedia window: all tabs align
    local margins = Encyclopedia.CONTENT_MARGINS
    local margin_l = scaled_int(margins.left)
    local margin_t = scaled_int(margins.top)
    local margin_r = scaled_int(margins.right)
    local margin_b = scaled_int(margins.bottom)
    local level_w = scaled_int(BASE_LEVEL_W)
    local quality_w = scaled_int(self._quality_dd_base_w)
    local class_w = scaled_int(self._class_dd_base_w)

    -- row 1: Type / Rarity left, Level block flush right. Traceries swap
    -- the min-max range for two single-value inputs (Level and iLvl)
    local type_label_w = scaled_int(38)
    local rarity_label_w = scaled_int(48)
    local dash_w = scaled_int(10)
    local level_label_w = scaled_int(42)
    local ilvl_label_w = scaled_int(34)
    local range_w = level_w + gap + dash_w + gap + level_w
    local level_block_w = level_label_w + gap + range_w
    if self.ilvl_label ~= nil then
        level_block_w = level_block_w + (2 * gap) + ilvl_label_w + gap + range_w
    end

    local x = margin_l
    self.type_label:SetPosition(x, margin_t)
    self.type_label:SetSize(type_label_w, bar_h)
    x = x + type_label_w + gap
    self.class_dropdown:SetPosition(x, margin_t)
    self.class_dropdown:SetSize(class_w, bar_h)
    x = x + class_w + (2 * gap)
    self.rarity_label:SetPosition(x, margin_t)
    self.rarity_label:SetSize(rarity_label_w, bar_h)
    x = x + rarity_label_w + gap
    self.quality_dropdown:SetPosition(x, margin_t)
    self.quality_dropdown:SetSize(quality_w, bar_h)

    if self.pclass_dropdown ~= nil then
        local pclass_label_w = scaled_int(46)
        local pclass_w = scaled_int(self._pclass_dd_base_w)
        x = x + quality_w + (2 * gap)
        self.pclass_label:SetPosition(x, margin_t)
        self.pclass_label:SetSize(pclass_label_w, bar_h)
        x = x + pclass_label_w + gap
        self.pclass_dropdown:SetPosition(x, margin_t)
        self.pclass_dropdown:SetSize(pclass_w, bar_h)
    end

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
    if self.ilvl_label ~= nil then
        level_x = level_x + level_w + (2 * gap)
        self.ilvl_label:SetPosition(level_x, margin_t)
        self.ilvl_label:SetSize(ilvl_label_w, bar_h)
        level_x = level_x + ilvl_label_w + gap
        self.ilvl_min_box:SetPosition(level_x, margin_t)
        self.ilvl_min_box:SetSize(level_w, bar_h)
        level_x = level_x + level_w + gap
        self.ilvl_dash_label:SetPosition(level_x, margin_t)
        self.ilvl_dash_label:SetSize(dash_w, bar_h)
        level_x = level_x + dash_w + gap
        self.ilvl_max_box:SetPosition(level_x, margin_t)
        self.ilvl_max_box:SetSize(level_w, bar_h)
    end

    -- row 2: search across the full width
    local search_y = margin_t + bar_h + gap
    self.search_box:SetPosition(margin_l, search_y)
    self.search_box:SetSize(math.max(1, width - margin_l - margin_r), bar_h)

    local page_bar_h = scaled_int(BASE_PAGE_BAR_H)
    local page_w = scaled_int(BASE_PAGE_W)
    local footer_y = height - margin_b - page_bar_h
    self.pager:set_metrics(scaled_int(BASE_NAV_W), gap)
    local footer_total = self.pager:preferred_width(page_w)
    local footer_x = math.max(0, math.floor((width - footer_total) / 2))
    self.pager:SetPosition(footer_x, footer_y)
    self.pager:SetSize(footer_total, page_bar_h)

    local results_w = scaled_int(140)
    self.results_label:SetPosition(width - margin_r - results_w, footer_y)
    self.results_label:SetSize(results_w, page_bar_h)

    local list_top = search_y + bar_h + gap
    local list_w = math.max(1, width - margin_l - margin_r)
    local list_h = math.max(1, footer_y - gap - list_top)
    self.table:set_header_height(scaled_int(20))
    self.table:set_row_height(_even_int(scaled_int(38)))
    self.table:set_column_width(1, scaled_int(40))
    if self._bucket == "tracery" then
        self.table:set_column_width(3, scaled_int(140))
        self.table:set_column_width(4, scaled_int(110))
        self.table:set_column_width(5, scaled_int(76))
        self.table:set_column_width(6, scaled_int(46))
        self.table:set_column_width(7, scaled_int(46))
    else
        self.table:set_column_width(3, scaled_int(170))
        self.table:set_column_width(4, scaled_int(70))
        self.table:set_column_width(5, scaled_int(60))
    end
    self.table:SetPosition(margin_l, list_top)
    self.table:SetSize(list_w, list_h)

    -- SizeChanged fires every frame during a drag resize: resize frames
    -- only move controls; rows re-render only when the page capacity
    -- actually changed (filter edits re-render via _on_filters_changed)
    local capacity = self:_page_capacity()
    if capacity ~= self._layout_capacity then
        self._layout_capacity = capacity
        self:_refresh_list()
    end
end
