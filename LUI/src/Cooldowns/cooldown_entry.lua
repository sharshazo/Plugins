-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_format_cooldown_time = _G.LUI.Utils.lui_format_cooldown_time
local lui_cooldown_text_gap = _G.LUI.Utils.lui_cooldown_text_gap
local lui_cooldown_time_label_width = _G.LUI.Utils.lui_cooldown_time_label_width
local lui_timed_row_vertical_time_label_rect = _G.LUI.Utils.lui_timed_row_vertical_time_label_rect
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local Cooldowns = _G.LUI.Features.Cooldowns
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.enums"
import "LUI.src.Cooldowns.time_display"
import "LUI.src.Utils.color"

local CooldownEntry = class(Turbine.UI.Control)
Cooldowns.CooldownEntry = CooldownEntry

local function _truncate_name(name, max_chars)
    if type(name) ~= "string" then
        name = tostring(name or "")
    end

    local m = max_chars
    if m <= 0 then
        return name
    end

    m = math.floor(m + 0.5)
    if m < 1 then
        return ""
    end

    if string.len(name) <= m then
        return name
    end

    if m >= 4 then
        return string.sub(name, 1, m - 3) .. "..."
    end

    return string.sub(name, 1, m)
end

local function _bar_background_color(settings)
    local color
    if settings.bar_background_matches_fill == true then
        color = lui_dim_color(settings.color.bar, settings.bar_background_dimming)
    else
        color = settings.color.background
    end
    return lui_apply_opacity_to_color(color, settings.background_opacity)
end

local function _icon_background_color(settings)
    return lui_apply_opacity_to_color(settings.color.background, settings.background_opacity)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function CooldownEntry:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.skill = nil
    self.expired_event = nil
    self._expired_sent = false
    self._shown_icon = nil
    self.bar_inner_len = 0
    self.bar_anchor_far = false
    self.vertical = false
    self.show_time = true
    self._icon_size = nil

    self:SetMouseVisible(false)

    self.border_top = Turbine.UI.Control()
    self.border_top:SetParent(self)
    self.border_top:SetMouseVisible(false)

    self.border_bottom = Turbine.UI.Control()
    self.border_bottom:SetParent(self)
    self.border_bottom:SetMouseVisible(false)

    self.border_left = Turbine.UI.Control()
    self.border_left:SetParent(self)
    self.border_left:SetMouseVisible(false)

    self.border_right = Turbine.UI.Control()
    self.border_right:SetParent(self)
    self.border_right:SetMouseVisible(false)

    self.separator = Turbine.UI.Control()
    self.separator:SetParent(self)
    self.separator:SetMouseVisible(false)

    self.bar_background = Turbine.UI.Control()
    self.bar_background:SetParent(self)
    self.bar_background:SetMouseVisible(false)

    self.bar_fill = Turbine.UI.Control()
    self.bar_fill:SetParent(self.bar_background)
    self.bar_fill:SetMouseVisible(false)

    self.name_label = UI.Widgets.LuiLabel()
    self.name_label:SetParent(self.bar_background)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetSelectable(false)
    self.name_label:SetMultiline(true)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.name_label:SetText("")

    self.time_label = UI.Widgets.LuiLabel()
    self.time_label:SetParent(self.bar_background)
    self.time_label:SetMouseVisible(false)
    self.time_label:SetSelectable(false)
    self.time_label:SetMultiline(false)
    self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.time_label:SetText("")

    self.icon_background = Turbine.UI.Control()
    self.icon_background:SetParent(self)
    self.icon_background:SetMouseVisible(false)

    self.icon = UI.Widgets.Image()
    self.icon:SetParent(self.icon_background)
    self.icon:SetVisible(false)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function CooldownEntry:apply_settings()
    local s = State.settings.self.cooldowns
    local bw = s.border_width
    local vertical = s.orientation == LUI_ENUMS.orientation.VERTICAL

    -- Footprint, effective show_time, and the fitted vertical time font are
    -- resolved once per Settings.rebuild(); see rebuild_settings.lua.
    local resolved = s.resolved
    local show_time = resolved.show_time
    local w = resolved.width
    local h = resolved.height

    self:SetSize(w, h)

    local border = bw
    if type(border) ~= "number" then
        border = 0
    end
    border = math.floor(border + 0.5)
    if border < 0 then border = 0 end
    if border * 2 >= w then border = math.floor((w - 1) / 2) end
    if border * 2 >= h then border = math.floor((h - 1) / 2) end
    if border < 0 then border = 0 end

    local bc = s.color.border
    self.border_top:SetBackColor(bc)
    self.border_bottom:SetBackColor(bc)
    self.border_left:SetBackColor(bc)
    self.border_right:SetBackColor(bc)

    self.border_top:SetPosition(0, 0)
    self.border_top:SetSize(w, border)
    self.border_bottom:SetPosition(0, h - border)
    self.border_bottom:SetSize(w, border)
    self.border_left:SetPosition(0, 0)
    self.border_left:SetSize(border, h)
    self.border_right:SetPosition(w - border, 0)
    self.border_right:SetSize(border, h)

    local inner_w = w - (2 * border)
    local inner_h = h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    local inner_main = vertical and inner_h or inner_w
    local inner_cross = vertical and inner_w or inner_h

    local sep = border
    if sep < 0 then sep = 0 end
    if sep >= inner_main then sep = inner_main - 1 end
    if sep < 0 then sep = 0 end

    local icon_size = inner_cross
    local max_icon = inner_main - sep - 1
    if max_icon < 1 then max_icon = 1 end
    if icon_size > max_icon then
        icon_size = max_icon
    end
    self._icon_size = icon_size

    local bar_len = inner_main - icon_size - sep
    if bar_len < 1 then bar_len = 1 end
    self.bar_inner_len = bar_len
    self.vertical = vertical
    self.show_time = show_time

    -- side LEFT means left when horizontal, top when vertical.
    local icon_near = LUI_ENUMS.side_is_left[s.icon_side] == true

    local back = _icon_background_color(s)
    local bar_back = _bar_background_color(s)
    self.separator:SetBackColor(s.color.border)
    self.separator:SetVisible(sep > 0)

    if vertical then
        if icon_near then
            self.icon_background:SetPosition(border, border)

            self.separator:SetPosition(border, border + icon_size)
            self.separator:SetSize(inner_w, sep)

            self.bar_background:SetPosition(border, border + icon_size + sep)
        else
            self.bar_background:SetPosition(border, border)

            self.separator:SetPosition(border, border + bar_len)
            self.separator:SetSize(inner_w, sep)

            self.icon_background:SetPosition(border, border + bar_len + sep)
        end
        self.bar_background:SetSize(inner_w, bar_len)
    else
        if icon_near then
            self.icon_background:SetPosition(border, border)

            self.separator:SetPosition(border + icon_size, border)
            self.separator:SetSize(sep, inner_h)

            self.bar_background:SetPosition(border + icon_size + sep, border)
        else
            self.bar_background:SetPosition(border, border)

            self.separator:SetPosition(border + bar_len, border)
            self.separator:SetSize(sep, inner_h)

            self.icon_background:SetPosition(border + bar_len + sep, border)
        end
        self.bar_background:SetSize(bar_len, inner_h)
    end

    self.icon_background:SetSize(icon_size, icon_size)
    self.icon_background:SetBackColor(back)
    self.bar_background:SetBackColor(bar_back)

    -- The background should be exactly the content size (no extra inner border).
    self.bar_fill:SetPosition(0, 0)
    if vertical then
        self.bar_fill:SetSize(inner_cross, bar_len)
    else
        self.bar_fill:SetSize(bar_len, inner_cross)
    end
    self.bar_fill:SetBackColor(lui_apply_opacity_to_color(s.color.bar, s.bar_opacity))

    local pad = s.text_margin
    local font_style = LUI_TO_LOTRO.font_style[s.font.style] or Turbine.UI.FontStyle.None

    self.name_label:SetFont(s.font.lotro)
    self.name_label:SetFontStyle(font_style)
    self.name_label:SetOutlineColor(s.font.outline_color)
    self.name_label:SetForeColor(s.font.color)
    self.time_label:SetFont(s.font.lotro)
    self.time_label:SetFontStyle(font_style)
    self.time_label:SetOutlineColor(s.font.outline_color)
    self.time_label:SetForeColor(s.font.color)

    self.name_label:SetVisible(vertical ~= true)
    self.time_label:SetVisible(show_time)

    if vertical then
        if show_time then
            local time_x, time_y, time_w, time_h = lui_timed_row_vertical_time_label_rect(
                s.font.name, resolved.time_font_size, bar_len, inner_cross, icon_near)

            self.time_label:SetFont(resolved.time_font)
            self.time_label:SetPosition(time_x, time_y)
            self.time_label:SetSize(time_w, time_h)
            self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        end
    else
        local time_width = 0
        local text_gap = 0
        if show_time then
            time_width = lui_cooldown_time_label_width(s.font.name, s.font.size, s.threshold, s.time_format)
            text_gap = lui_cooldown_text_gap(s.font.size)
        end
        local title_width = inner_w - icon_size - sep - (2 * pad) - time_width - text_gap
        if title_width < 1 then
            title_width = 1
        end
        local time_x = pad + title_width + text_gap

        self.name_label:SetPosition(pad, 0)
        self.name_label:SetSize(title_width, inner_h)
        self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

        if show_time then
            self.time_label:SetPosition(time_x, 0)
            self.time_label:SetSize(time_width, inner_h)
            self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        end
    end

    self.icon:SetPosition(0, 0)
    self.icon:set_size(icon_size, icon_size)
    if self.skill ~= nil and self.skill.icon ~= nil then
        self._shown_icon = self.skill.icon
        self.icon:set_icon(self.skill.icon, icon_size, icon_size)
    end

    -- side RIGHT means right when horizontal, bottom when vertical.
    local towards_far = s.bar_expire_towards == LUI_ENUMS.side.RIGHT
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        self.bar_anchor_far = towards_far ~= true
    else
        self.bar_anchor_far = towards_far
    end
end

function CooldownEntry:set_skill(skill)
    if skill == nil then
        self.skill = nil
        self._expired_sent = false
        self._shown_icon = nil
        if self._icon_size ~= nil then
            self.icon:set_icon(nil, self._icon_size, self._icon_size)
        else
            self.icon:set_icon(nil)
        end
        self.icon:SetVisible(false)
        self.name_label:SetText("")
        self.time_label:SetText("")
        -- Zero only the fill axis so the cross size from apply_settings survives.
        if self.vertical then
            self.bar_fill:SetHeight(0)
        else
            self.bar_fill:SetWidth(0)
        end
        self:SetVisible(false)
        return
    end

    -- A group record keeps its identity while its displayed member
    -- rotates, so the icon can change without the record changing.
    if skill == self.skill then
        if skill.icon ~= self._shown_icon then
            self:_apply_icon(skill.icon)
        end
        return
    end

    self.skill = skill
    self._expired_sent = false
    self:SetVisible(true)
    self:_apply_icon(skill.icon)
end

function CooldownEntry:_apply_icon(icon)
    self._shown_icon = icon
    if icon ~= nil then
        if self._icon_size ~= nil then
            self.icon:set_icon(icon, self._icon_size, self._icon_size)
        else
            self.icon:set_icon(icon)
        end
        self.icon:SetVisible(true)
    else
        if self._icon_size ~= nil then
            self.icon:set_icon(nil, self._icon_size, self._icon_size)
        else
            self.icon:set_icon(nil)
        end
        self.icon:SetVisible(false)
    end
end

function CooldownEntry:update_remaining(remaining_seconds, base_seconds)
    local s = State.settings.self.cooldowns

    if self.skill == nil then
        self.name_label:SetText("")
        self.time_label:SetText("")
        if self.vertical then
            self.bar_fill:SetHeight(0)
        else
            self.bar_fill:SetWidth(0)
        end
        return
    end

    if remaining_seconds <= 0 then
        if not self._expired_sent then
            self._expired_sent = true
            if self.expired_event ~= nil then
                self.expired_event()
            end
        end
    else
        self._expired_sent = false
    end

    local inner_len = self.bar_inner_len

    local base = base_seconds
    if base <= 0 then
        base = remaining_seconds
    end

    local ratio = remaining_seconds / base
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end

    local percent = ratio
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        percent = 1 - ratio
    end

    local fill_len = math.floor(inner_len * percent + 0.5)
    if fill_len < 0 then fill_len = 0 end
    if fill_len > inner_len then fill_len = inner_len end

    -- The cross axis is fixed by apply_settings; only touch the fill axis.
    if self.vertical then
        if self.bar_anchor_far then
            self.bar_fill:SetPosition(0, inner_len - fill_len)
        else
            self.bar_fill:SetPosition(0, 0)
        end
        self.bar_fill:SetHeight(fill_len)
    else
        if self.bar_anchor_far then
            self.bar_fill:SetPosition(inner_len - fill_len, 0)
        else
            self.bar_fill:SetPosition(0, 0)
        end
        self.bar_fill:SetWidth(fill_len)
    end

    if self.vertical ~= true then
        local name = _truncate_name(self.skill.name or "", s.name_max_chars)
        self.name_label:SetText(name)
    end
    if self.show_time then
        self.time_label:SetText(lui_format_cooldown_time(remaining_seconds, s.time_format))
    end
end
