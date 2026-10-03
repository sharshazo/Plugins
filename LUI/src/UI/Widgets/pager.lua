-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.assets"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.line_edit"

local UI = _G.LUI.UI
local AssetIds = UI.AssetIds
local Widgets = UI.Widgets
local LuiButton = Widgets.LuiButton
local LuiLabel = Widgets.LuiLabel
local LuiLineEdit = Widgets.LuiLineEdit

local BASE_NAV_W = 22
local BASE_SLASH_W = 12

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

-- Shared page navigator: [<]  x / T  [>], where x is a digits-only text
-- edit. The pager owns the paging state: it clamps every transition to
-- [1, max(1, page_count)], keeps the arrows/readonly state in sync, and
-- reports each actual page change through the single optional `changed`
-- callback:
--
--   pager.changed = function(new_page_number) ... end
--
-- `changed` fires for arrow clicks, Enter commits in the edit, and
-- programmatic set_page/set_page_count calls that move the page (e.g. the
-- page count shrinking below the current page). It never fires when the
-- page ends up unchanged.
---@class LuiPager : Turbine.UI.Control
local LuiPager = class(Turbine.UI.Control)
Widgets.LuiPager = LuiPager

function LuiPager:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.changed = nil

    self._page = 1
    self._page_count = 1
    self._scale = 1
    self._nav_w = nil
    self._gap = nil
    self._synced_page = nil
    self._synced_count = nil

    self.prev_button = LuiButton()
    self.prev_button:SetParent(self)
    self.prev_button:set_text("")
    self.prev_button:set_padding(2)
    self.prev_button:set_icon(
        AssetIds.arrow_l_white,
        AssetIds.arrow_l_white,
        AssetIds.arrow_l_white,
        AssetIds.arrow_l_transparent,
        BASE_NAV_W,
        nil,
        LuiButton.icon_position.LEFT
    )
    self.prev_button.Click = function()
        self:_set_page_internal(self._page - 1, true)
    end

    self.next_button = LuiButton()
    self.next_button:SetParent(self)
    self.next_button:set_text("")
    self.next_button:set_padding(2)
    self.next_button:set_icon(
        AssetIds.arrow_r_white,
        AssetIds.arrow_r_white,
        AssetIds.arrow_r_white,
        AssetIds.arrow_r_transparent,
        BASE_NAV_W,
        nil,
        LuiButton.icon_position.RIGHT
    )
    self.next_button.Click = function()
        self:_set_page_internal(self._page + 1, true)
    end

    -- regular line edit; its scale is left at 1 so the border stays 1px
    self.page_edit = LuiLineEdit()
    self.page_edit:SetParent(self)
    self.page_edit:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.page_edit:SetWantsKeyEvents(true)
    self.page_edit:set_digits_only(true)
    self.page_edit.Submitted = function(_, digits)
        self:_commit_edit(digits)
    end
    self.page_edit.FocusLost = function()
        -- clicking away reverts; Enter is the explicit jump
        self:_sync_display(true)
    end

    -- three-part middle: page edit | centered "/" | total pages
    self.slash_label = LuiLabel()
    self.slash_label:SetParent(self)
    self.slash_label:SetMouseVisible(false)
    self.slash_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.slash_label:SetText("/")

    self.total_label = LuiLabel()
    self.total_label:SetParent(self)
    self.total_label:SetMouseVisible(false)
    self.total_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self:_sync_display()
end

function LuiPager:_max_page()
    if self._page_count < 1 then
        return 1
    end
    return self._page_count
end

function LuiPager:_sync_display(force)
    if force ~= true and self._page == self._synced_page and self._page_count == self._synced_count then
        return
    end
    self._synced_page = self._page
    self._synced_count = self._page_count
    self.page_edit:SetText(tostring(self._page))
    self.total_label:SetText(tostring(self:_max_page()))
    self.prev_button:set_enabled(self._page_count > 0 and self._page > 1)
    self.next_button:set_enabled(self._page_count > 0 and self._page < self._page_count)
end

function LuiPager:_set_page_internal(page, fire)
    local max_page = self:_max_page()
    if page < 1 then
        page = 1
    end
    if page > max_page then
        page = max_page
    end

    local moved = page ~= self._page
    self._page = page
    self:_sync_display()

    if moved == true and fire == true and type(self.changed) == "function" then
        self.changed(page)
    end
end

function LuiPager:_commit_edit(digits)
    local page = tonumber(digits)
    if page == nil then
        -- empty submit: keep the current page
        self:_sync_display(true)
        return
    end
    -- the typed text must be replaced even when the commit clamps back to
    -- the same page ("999" on the last page), so invalidate the sync cache
    self._synced_page = nil
    self:_set_page_internal(page, true)
end

function LuiPager:set_page(page)
    self:_set_page_internal(page, true)
end

function LuiPager:set_page_count(count)
    self._page_count = count
    -- re-clamp; fires changed when the shrunken count moves the page
    self:_set_page_internal(self._page, true)
end

function LuiPager:get_page()
    return self._page
end

function LuiPager:get_page_count()
    return self._page_count
end

function LuiPager:set_font(font)
    self.page_edit:SetFont(font)
    self.slash_label:SetFont(font)
    self.total_label:SetFont(font)
    self.prev_button:set_font(font)
    self.next_button:set_font(font)
end

-- scaled pixel widths for the arrow buttons and the button/text gaps.
-- Store-only: callers set metrics (and scale) first, then SetSize runs the
-- one layout pass. Metrics are required before the first SetSize.
function LuiPager:set_metrics(nav_w, gap)
    self._nav_w = nav_w
    self._gap = gap
end

-- total widget width for a given middle (page area) width, so callers
-- never restate the internal spacing formula
function LuiPager:preferred_width(page_w)
    return (2 * (self._nav_w + self._gap)) + page_w
end

function LuiPager:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
end

function LuiPager:SetSize(w, h)
    Turbine.UI.Control.SetSize(self, w, h)
    self:_layout()
end

function LuiPager:_layout()
    local w, h = self:GetSize()
    local nav_w = self._nav_w
    local gap = self._gap

    self.prev_button:SetPosition(0, 0)
    self.prev_button:SetSize(nav_w, h)
    self.next_button:SetPosition(w - nav_w, 0)
    self.next_button:SetSize(nav_w, h)

    -- three-part middle: the "/" sits dead center between the arrows,
    -- the page edit fills the left side (text right-aligned against the
    -- slash) and the total-pages label the right side (left-aligned)
    local area_x = nav_w + gap
    local area_w = math.max(0, w - (2 * (nav_w + gap)))
    local slash_w = math.min(area_w, _scaled_int(self._scale, BASE_SLASH_W))
    local slash_x = area_x + math.max(0, math.floor((area_w - slash_w) / 2))
    local edit_w = math.max(0, slash_x - area_x)
    self.page_edit:SetPosition(area_x, 0)
    self.page_edit:SetSize(edit_w, h)
    self.slash_label:SetPosition(slash_x, 0)
    self.slash_label:SetSize(slash_w, h)
    self.total_label:SetPosition(slash_x + slash_w, 0)
    self.total_label:SetSize(math.max(0, area_x + area_w - slash_x - slash_w), h)
end

function LuiPager:destroy()
    self.prev_button:SetParent(nil)
    self.next_button:SetParent(nil)
    self.page_edit:destroy()
    self.page_edit:SetParent(nil)
    self.slash_label:SetParent(nil)
    self.total_label:SetParent(nil)
    self:SetVisible(false)
end
