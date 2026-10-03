-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_timed_row_time_format = _G.LUI.Utils.lui_timed_row_time_format
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_vertical_time_label_rect = _G.LUI.Utils.lui_timed_row_vertical_time_label_rect
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local ExpiringEffects = _G.LUI.Features.ExpiringEffects
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"
import "LUI.src.Settings.enums"
import "LUI.src.Utils.timed_row_layout"
import "LUI.src.Utils.color"

local LABEL_PAD = _G.LUI.Utils.lui_timed_row_label_pad
local EFFECT_TIME_FORMAT = lui_timed_row_time_format.AUTO

local function _stable_effect_key(effect)
    if effect == nil then
        return 0
    end

    local id = effect:GetID()
    if type(id) ~= "number" then
        id = tonumber(id) or 0
    end
    return id
end

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

local TargetExpiringEffectEntry = class(Turbine.UI.Control)
ExpiringEffects.TargetExpiringEffectEntry = TargetExpiringEffectEntry

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetExpiringEffectEntry:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.effect = nil
    self.effect_key = 0
    self.bar_inner_len = 0
    self.bar_anchor_far = false
    self.vertical = false
    self.show_time = true

    self:SetMouseVisible(false)

    self.bar_border = Turbine.UI.Control()
    self.bar_border:SetParent(self)
    self.bar_border:SetMouseVisible(false)

    self.bar_background = Turbine.UI.Control()
    self.bar_background:SetParent(self.bar_border)
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

    self.icon_border = Turbine.UI.Control()
    self.icon_border:SetParent(self)
    self.icon_border:SetMouseVisible(false)

    self.icon_background = Turbine.UI.Control()
    self.icon_background:SetParent(self.icon_border)
    self.icon_background:SetMouseVisible(false)

    self.icon = Turbine.UI.Lotro.EffectDisplay()
    self.icon:SetParent(self.icon_background)
    self.icon:SetMouseVisible(false)
    self.icon:SetVisible(false)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetExpiringEffectEntry:apply_settings()
    local s = State.settings.target.expiring_effects
    local border = s.border_width
    local border_color = s.color.border
    local back = lui_apply_opacity_to_color(s.color.background, s.background_opacity)
    local vertical = s.orientation == LUI_ENUMS.orientation.VERTICAL

    -- Bar size, effective show_time, and the fitted vertical time font are
    -- resolved once per Settings.rebuild(); see rebuild_settings.lua.
    local resolved = s.resolved
    local show_time = resolved.show_time
    local bar_len = resolved.bar_length
    local thickness = resolved.thickness
    local icon_size = thickness

    -- side LEFT means left when horizontal, top when vertical.
    local icon_near = LUI_ENUMS.side_is_left[s.icon_side] == true

    if vertical then
        self:SetSize(thickness, bar_len + icon_size)

        self.bar_border:SetPosition(0, icon_near and icon_size or 0)
        self.bar_border:SetSize(thickness, bar_len)

        self.icon_border:SetPosition(0, icon_near and 0 or bar_len)
    else
        self:SetSize(bar_len + icon_size, thickness)

        self.bar_border:SetPosition(icon_near and icon_size or 0, 0)
        self.bar_border:SetSize(bar_len, thickness)

        self.icon_border:SetPosition(icon_near and 0 or bar_len, 0)
    end
    self.bar_border:SetBackColor(border_color)
    self.icon_border:SetSize(icon_size, icon_size)
    self.icon_border:SetBackColor(border_color)

    if border < 0 then border = 0 end
    local max_border = math.floor(math.min(bar_len, thickness) / 2)
    if border > max_border then border = max_border end
    local inner_cross = thickness - (2 * border)
    if inner_cross < 1 then inner_cross = 1 end

    -- Avoid a double border between bar and icon:
    -- keep the separator from the icon border, and extend the bar background to cover its adjacent border.
    local bar_inner_len = bar_len - border
    if bar_inner_len < 1 then bar_inner_len = 1 end
    self.bar_inner_len = bar_inner_len
    self.vertical = vertical
    self.show_time = show_time

    if vertical then
        self.bar_background:SetPosition(border, icon_near and 0 or border)
        self.bar_background:SetSize(inner_cross, bar_inner_len)

        self.bar_fill:SetPosition(0, 0)
        self.bar_fill:SetSize(inner_cross, bar_inner_len)
    else
        self.bar_background:SetPosition(icon_near and 0 or border, border)
        self.bar_background:SetSize(bar_inner_len, inner_cross)

        self.bar_fill:SetPosition(0, 0)
        self.bar_fill:SetSize(bar_inner_len, inner_cross)
    end
    self:_apply_bar_colors()

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
                s.font.name, resolved.time_font_size, bar_inner_len, inner_cross, icon_near)

            self.time_label:SetFont(resolved.time_font)
            self.time_label:SetPosition(time_x, time_y)
            self.time_label:SetSize(time_w, time_h)
            self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        end
    else
        local time_width = 0
        local text_gap = 0
        if show_time then
            time_width = lui_timed_row_time_label_width(
                s.font.name,
                s.font.size,
                s.threshold,
                EFFECT_TIME_FORMAT
            )
            text_gap = lui_timed_row_text_gap(s.font.size)
        end
        local title_width = bar_inner_len - (2 * LABEL_PAD) - time_width - text_gap
        if title_width < 1 then title_width = 1 end
        local time_x = LABEL_PAD + title_width + text_gap

        self.name_label:SetPosition(LABEL_PAD, 0)
        self.name_label:SetSize(title_width, inner_cross)
        self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

        if show_time then
            self.time_label:SetPosition(time_x, 0)
            self.time_label:SetSize(time_width, inner_cross)
            self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        end
    end

    local icon_inner = icon_size
    if icon_inner < 1 then icon_inner = 1 end
    self.icon_background:SetPosition(0, 0)
    self.icon_background:SetSize(icon_inner, icon_inner)
    self.icon_background:SetBackColor(back)

    self.icon:SetPosition(0, 0)
    self.icon:SetSize(icon_inner, icon_inner)

    -- side RIGHT means right when horizontal, bottom when vertical.
    local towards_far = s.bar_expire_towards == LUI_ENUMS.side.RIGHT
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        self.bar_anchor_far = towards_far ~= true
    else
        self.bar_anchor_far = towards_far
    end
end

function TargetExpiringEffectEntry:set_effect(effect)
    if effect == nil then
        if self.effect == nil and (self.effect_key == nil or self.effect_key == 0) then
            return
        end
        self.effect = nil
        self.effect_key = 0
        self:_apply_bar_colors()
        self.icon:SetEffect(nil)
        self.icon:SetVisible(false)
        return
    end

    local next_key = _stable_effect_key(effect)
    if next_key ~= 0 and next_key == self.effect_key then
        -- Same underlying effect (possibly new wrapper) -> avoid EffectDisplay rebinding.
        self.effect = effect
        self:_apply_bar_colors()
        self.icon:SetVisible(true)
        return
    end

    self.effect = effect
    self.effect_key = next_key
    self:_apply_bar_colors()
    self.icon:SetVisible(true)
    self.icon:SetEffect(effect)
end

function TargetExpiringEffectEntry:update_remaining(remaining_seconds, initial_seconds)
    if self.effect == nil then
        self.name_label:SetText("")
        self.time_label:SetText("")
        -- Zero only the fill axis so the cross size from apply_settings survives.
        if self.vertical then
            self.bar_fill:SetHeight(0)
        else
            self.bar_fill:SetWidth(0)
        end
        return
    end

    local s = State.settings.target.expiring_effects
    local inner_len = self.bar_inner_len

    if type(remaining_seconds) ~= "number" then
        self.bar_fill:SetPosition(0, 0)
        if self.vertical then
            self.bar_fill:SetHeight(inner_len)
        else
            local name = _truncate_name(tostring(self.effect:GetName() or ""), s.name_max_chars)
            self.name_label:SetText(name)
            self.bar_fill:SetWidth(inner_len)
        end
        if self.show_time then
            self.time_label:SetText("")
        end
        return
    end

    local base = initial_seconds
    if type(base) ~= "number" or base <= 0 then
        base = remaining_seconds
    end
    if base <= 0 then
        base = 0.0001
    end

    local percent = remaining_seconds / base
    if percent < 0 then percent = 0 end
    if percent > 1 then percent = 1 end
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        percent = 1 - percent
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
        local name = _truncate_name(tostring(self.effect:GetName() or ""), s.name_max_chars)
        self.name_label:SetText(name)
    end
    if self.show_time then
        self.time_label:SetText(lui_timed_row_format_time(remaining_seconds, EFFECT_TIME_FORMAT))
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function TargetExpiringEffectEntry:_apply_bar_colors()
    local s = State.settings.target.expiring_effects
    local bar_color = self:_resolve_bar_color()
    self.bar_background:SetBackColor(self:_resolve_bar_background_color(bar_color))
    self.bar_fill:SetBackColor(lui_apply_opacity_to_color(bar_color, s.bar_opacity))
end

function TargetExpiringEffectEntry:_resolve_bar_background_color(bar_color)
    local s = State.settings.target.expiring_effects
    local color

    if s.bar_background_matches_fill == true then
        color = lui_dim_color(bar_color, s.bar_background_dimming)
    else
        color = s.color.background
    end

    return lui_apply_opacity_to_color(color, s.background_opacity)
end

function TargetExpiringEffectEntry:_resolve_bar_color()
    local s = State.settings.target.expiring_effects

    if self.effect == nil then
        return s.color.bar_debuff_curable
    end

    local is_debuff = self.effect.IsDebuff ~= nil and self.effect:IsDebuff()
    if is_debuff then
        local is_curable = self.effect.IsCurable ~= nil and self.effect:IsCurable()
        if is_curable then
            return s.color.bar_debuff_curable
        end
        return s.color.bar_debuff_noncurable
    end

    return s.color.bar_buff
end
