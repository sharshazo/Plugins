-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_timed_row_time_format = _G.LUI.Utils.lui_timed_row_time_format
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_vertical_time_label_rect = _G.LUI.Utils.lui_timed_row_vertical_time_label_rect
local lui_timed_row_resolve_bar_size = _G.LUI.Utils.lui_timed_row_resolve_bar_size
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local ConfigWindow = _G.LUI.Settings.ConfigWindow
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local UI = _G.LUI.UI
import "LUI.src.Utils.timed_row_layout"
import "LUI.src.Utils.color"

local Common = _G.LUI.Settings.Preview.Common
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _preview_bar_background = Common.preview_resource_background
local _sync_preview_holder_height = Common.sync_preview_holder_height

local LABEL_PAD = _G.LUI.Utils.lui_timed_row_label_pad
local EFFECT_TIME_FORMAT = lui_timed_row_time_format.AUTO

local function _truncate_name(name, max_chars)
    local value = tostring(name or "")
    local m = max_chars
    if type(m) ~= "number" then
        m = tonumber(m)
    end
    if m == nil or m <= 0 then
        return value
    end

    m = math.floor(m + 0.5)
    if m < 1 then
        return ""
    end
    if string.len(value) <= m then
        return value
    end
    if m >= 4 then
        return string.sub(value, 1, m - 3) .. "..."
    end
    return string.sub(value, 1, m)
end

local function _create_row(container)
    local row = {}

    row.border = Turbine.UI.Control()
    row.border:SetParent(container)
    row.border:SetMouseVisible(false)

    row.border_top = Turbine.UI.Control()
    row.border_top:SetParent(row.border)
    row.border_top:SetMouseVisible(false)
    row.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.border_bottom = Turbine.UI.Control()
    row.border_bottom:SetParent(row.border)
    row.border_bottom:SetMouseVisible(false)
    row.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.border_left = Turbine.UI.Control()
    row.border_left:SetParent(row.border)
    row.border_left:SetMouseVisible(false)
    row.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.border_right = Turbine.UI.Control()
    row.border_right:SetParent(row.border)
    row.border_right:SetMouseVisible(false)
    row.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.entry = Turbine.UI.Control()
    row.entry:SetParent(row.border)
    row.entry:SetMouseVisible(false)

    row.bar_border = Turbine.UI.Control()
    row.bar_border:SetParent(row.entry)
    row.bar_border:SetMouseVisible(false)

    row.bar_background = Turbine.UI.Control()
    row.bar_background:SetParent(row.bar_border)
    row.bar_background:SetMouseVisible(false)

    row.bar_fill = Turbine.UI.Control()
    row.bar_fill:SetParent(row.bar_background)
    row.bar_fill:SetMouseVisible(false)

    row.name_label = UI.Widgets.LuiLabel()
    row.name_label:SetParent(row.bar_background)
    row.name_label:SetMouseVisible(false)
    row.name_label:SetMultiline(true)
    row.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    row.name_label:SetText("")

    row.time_label = UI.Widgets.LuiLabel()
    row.time_label:SetParent(row.bar_background)
    row.time_label:SetMouseVisible(false)
    row.time_label:SetMultiline(false)
    row.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    row.time_label:SetText("")

    row.icon_border = Turbine.UI.Control()
    row.icon_border:SetParent(row.entry)
    row.icon_border:SetMouseVisible(false)

    row.icon_background = Turbine.UI.Control()
    row.icon_background:SetParent(row.icon_border)
    row.icon_background:SetMouseVisible(false)

    row.icon = Turbine.UI.Control()
    row.icon:SetParent(row.icon_background)
    row.icon:SetMouseVisible(false)
    row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

    return row
end

function ConfigWindow:init_expiring_target_effects_preview()
    local holder = self.controls.expiring_target_effects_preview

    if self.expiring_target_effects_preview ~= nil then
        return
    end

    self.expiring_target_effects_preview = {}
    local p = self.expiring_target_effects_preview
    p.container = holder.control
    p.buff = _create_row(p.container)
    p.debuff_curable = _create_row(p.container)
    p.debuff_noncurable = _create_row(p.container)

    self:update_expiring_target_effects_preview()
end

function ConfigWindow:update_expiring_target_effects_preview()
    if self.expiring_target_effects_preview == nil then
        self:init_expiring_target_effects_preview()
    end

    local raw_scale = _require_positive_scale(self)

    local function scaled_int(raw_value)
        local n = raw_value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            error("Invalid target expiring effects preview scaled int: " .. tostring(raw_value))
        end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value)
        local n = tonumber(raw_value)
        if n == nil then
            error("Invalid target expiring effects preview scaled border: " .. tostring(raw_value))
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value)
        local n = raw_value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            error("Invalid target expiring effects preview scaled number: " .. tostring(raw_value))
        end
        return n * raw_scale
    end

    local raw_border = _require_control_number(self.controls, "expiring_target_effects_border_width")
    local border = scaled_border(raw_border)
    if border < 0 then border = 0 end

    local raw_bar_width = _require_control_number(self.controls, "expiring_target_effects_bar_width")
    local raw_bar_height = _require_control_number(self.controls, "expiring_target_effects_bar_height")
    local bar_width = scaled_int(raw_bar_width)
    local bar_height = scaled_int(raw_bar_height)
    if bar_width < 10 then bar_width = 10 end
    if bar_height < 10 then bar_height = 10 end
    local max_border = math.floor(math.min(bar_width, bar_height) / 2)
    if border > max_border then border = max_border end

    local background_color = _require_control_color(self.controls, "expiring_target_effects_background_color")
    local background_opacity = _require_control_number(self.controls, "expiring_target_effects_background_opacity")
    local bar_opacity = _require_control_number(self.controls, "expiring_target_effects_bar_opacity")
    local border_color = _require_control_color(self.controls, "expiring_target_effects_border_color")
    local debuff_curable_bar_color = _require_control_color(self.controls, "expiring_target_effects_bar_color")
    local debuff_noncurable_bar_color =
        _require_control_color(self.controls, "expiring_target_effects_debuff_noncurable_bar_color")
    local buff_bar_color = _require_control_color(self.controls, "expiring_target_effects_buff_bar_color")
    local bar_bg_matches_fill = self.controls.expiring_target_effects_bar_background_matches_fill.cb:IsChecked() == true
    local bar_bg_dimming = _require_control_number(self.controls, "expiring_target_effects_bar_background_dimming")

    local icon_side = _require_control_enum(self.controls, "expiring_target_effects_icon_side")
    local icon_near = LUI_ENUMS.side_is_left[icon_side] == true

    local orientation = _require_control_enum(self.controls, "expiring_target_effects_orientation")
    local vertical = orientation == LUI_ENUMS.orientation.VERTICAL
    local show_time = self.controls.expiring_target_effects_show_time.cb:IsChecked() == true

    -- side RIGHT means right when horizontal, bottom when vertical.
    local bar_expire_towards = _require_control_enum(self.controls, "expiring_target_effects_bar_expire_towards")
    local bar_mode = _require_control_enum(self.controls, "expiring_target_effects_bar_mode")
    local anchor_far = bar_expire_towards == LUI_ENUMS.side.RIGHT
    if bar_mode == LUI_ENUMS.bar_mode.LOAD then
        anchor_far = anchor_far ~= true
    end

    local name_max_chars = _require_control_number(self.controls, "expiring_target_effects_name_max_chars")

    local font_name = _require_control_enum(self.controls, "expiring_target_effects_font_name")
    local raw_font_size = _require_control_number(self.controls, "expiring_target_effects_font_size")
    local font_size = scaled_number(raw_font_size)
    local font = _require_font(font_name, font_size)

    local style_enum = _require_control_enum(self.controls, "expiring_target_effects_font_style")
    local font_style = LUI_TO_LOTRO.font_style[style_enum]
    if font_style == nil then
        error("Missing target expiring effects preview font style: " .. tostring(style_enum))
    end

    local font_color = _require_control_color(self.controls, "expiring_target_effects_font_color")
    local outline_color = _require_control_color(self.controls, "expiring_target_effects_font_outline_color")

    local remaining = 3.6
    local raw_threshold = _require_control_number(self.controls, "expiring_target_effects_threshold")
    if raw_threshold <= 0 then
        error("Invalid target expiring effects preview threshold: " .. tostring(raw_threshold))
    end
    remaining = math.max(0.5, math.min(raw_threshold - 0.4, raw_threshold))

    local threshold = raw_threshold

    -- bar_width is the bar length (main axis) and bar_height the thickness
    -- (cross axis, also the icon size) in both orientations. On vertical bars
    -- the resolver shrinks the time font to fit the thickness and downgrades
    -- show_time when even the smallest size does not fit.
    local time_font_size
    bar_width, bar_height, show_time, time_font_size = lui_timed_row_resolve_bar_size(
        vertical, show_time,
        bar_width, bar_height,
        border, LABEL_PAD,
        font_name, font_size,
        threshold, EFFECT_TIME_FORMAT
    )

    local p = self.expiring_target_effects_preview

    local icon_size = bar_height
    local entry_width
    local entry_height
    if vertical then
        entry_width = bar_height
        entry_height = bar_width + icon_size
    else
        entry_width = bar_width + icon_size
        entry_height = bar_height
    end
    local preview_border = 1
    local bw = entry_width + (2 * preview_border)
    local bh = entry_height + (2 * preview_border)

    local row_spacing = scaled_int(6, 6)

    local time_width = lui_timed_row_time_label_width(font_name, font_size, threshold, EFFECT_TIME_FORMAT)
    local text_gap = lui_timed_row_text_gap(font_size)

    local function apply_row(row, x, y, effect_name, row_bar_color)
        row.border:SetSize(bw, bh)
        row.border:SetPosition(x, y)

        row.entry:SetPosition(preview_border, preview_border)
        row.entry:SetSize(entry_width, entry_height)

        row.border_top:SetPosition(0, 0)
        row.border_top:SetSize(bw, preview_border)
        row.border_bottom:SetPosition(0, bh - preview_border)
        row.border_bottom:SetSize(bw, preview_border)
        row.border_left:SetPosition(0, 0)
        row.border_left:SetSize(preview_border, bh)
        row.border_right:SetPosition(bw - preview_border, 0)
        row.border_right:SetSize(preview_border, bh)

        if vertical then
            row.bar_border:SetPosition(0, icon_near and icon_size or 0)
            row.bar_border:SetSize(bar_height, bar_width)

            row.icon_border:SetPosition(0, icon_near and 0 or bar_width)
        else
            row.bar_border:SetPosition(icon_near and icon_size or 0, 0)
            row.bar_border:SetSize(bar_width, bar_height)

            row.icon_border:SetPosition(icon_near and 0 or bar_width, 0)
        end
        row.bar_border:SetBackColor(border_color)
        row.icon_border:SetSize(icon_size, icon_size)
        row.icon_border:SetBackColor(border_color)

        local inner_len = bar_width - (2 * border)
        local inner_cross = bar_height - (2 * border)
        if inner_len < 1 then inner_len = 1 end
        if inner_cross < 1 then inner_cross = 1 end

        local bar_inner_len = bar_width - border
        if bar_inner_len < 1 then bar_inner_len = 1 end

        local preview_percent = 0.6
        if bar_mode == LUI_ENUMS.bar_mode.LOAD then
            preview_percent = 1 - preview_percent
        end

        local preview_fill_len = math.floor(inner_len * preview_percent + 0.5)
        if preview_fill_len < 0 then preview_fill_len = 0 end
        if preview_fill_len > inner_len then preview_fill_len = inner_len end

        row.bar_background:SetBackColor(lui_apply_opacity_to_color(
            _preview_bar_background(bar_bg_matches_fill, bar_bg_dimming, background_color, row_bar_color),
            background_opacity
        ))
        row.bar_fill:SetBackColor(lui_apply_opacity_to_color(row_bar_color, bar_opacity))

        if vertical then
            row.bar_background:SetPosition(border, icon_near and 0 or border)
            row.bar_background:SetSize(inner_cross, bar_inner_len)

            if anchor_far then
                row.bar_fill:SetPosition(0, bar_inner_len - preview_fill_len)
            else
                row.bar_fill:SetPosition(0, 0)
            end
            row.bar_fill:SetSize(inner_cross, preview_fill_len)
        else
            row.bar_background:SetPosition(icon_near and 0 or border, border)
            row.bar_background:SetSize(bar_inner_len, inner_cross)

            if anchor_far then
                row.bar_fill:SetPosition(bar_inner_len - preview_fill_len, 0)
            else
                row.bar_fill:SetPosition(0, 0)
            end
            row.bar_fill:SetSize(preview_fill_len, inner_cross)
        end

        row.name_label:SetVisible(vertical ~= true)
        row.time_label:SetVisible(show_time)

        if vertical then
            if show_time then
                local time_x, time_y, time_w, time_h = lui_timed_row_vertical_time_label_rect(
                    font_name, time_font_size, bar_inner_len, inner_cross, icon_near)

                row.time_label:SetPosition(time_x, time_y)
                row.time_label:SetSize(time_w, time_h)
                row.time_label:SetFont(_require_font(font_name, time_font_size))
                row.time_label:SetFontStyle(font_style)
                row.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
                row.time_label:SetForeColor(font_color)
                row.time_label:SetOutlineColor(outline_color)
                row.time_label:SetText(lui_timed_row_format_time(remaining, EFFECT_TIME_FORMAT))
            end
        else
            local row_time_width = 0
            local row_text_gap = 0
            if show_time then
                row_time_width = time_width
                row_text_gap = text_gap
            end
            local title_width = bar_inner_len - (2 * LABEL_PAD) - row_time_width - row_text_gap
            if title_width < 1 then title_width = 1 end
            local time_x = LABEL_PAD + title_width + row_text_gap

            row.name_label:SetPosition(LABEL_PAD, 0)
            row.name_label:SetSize(title_width, inner_cross)
            row.name_label:SetFont(font)
            row.name_label:SetFontStyle(font_style)
            row.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
            row.name_label:SetForeColor(font_color)
            row.name_label:SetOutlineColor(outline_color)
            row.name_label:SetText(_truncate_name(effect_name, name_max_chars))

            if show_time then
                row.time_label:SetPosition(time_x, 0)
                row.time_label:SetSize(row_time_width, inner_cross)
                row.time_label:SetFont(font)
                row.time_label:SetFontStyle(font_style)
                row.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
                row.time_label:SetForeColor(font_color)
                row.time_label:SetOutlineColor(outline_color)
                row.time_label:SetText(lui_timed_row_format_time(remaining, EFFECT_TIME_FORMAT))
            end
        end

        local icon_inner = icon_size - (2 * border)
        if icon_inner < 1 then icon_inner = 1 end
        row.icon_background:SetPosition(border, border)
        row.icon_background:SetSize(icon_inner, icon_inner)
        row.icon_background:SetBackColor(lui_apply_opacity_to_color(background_color, background_opacity))

        row.icon:SetPosition(0, 0)
        row.icon:SetSize(icon_inner, icon_inner)
    end

    local holder = self.controls.expiring_target_effects_preview
    local desired_height
    if vertical then
        desired_height = bh + 12
    else
        desired_height = (3 * bh) + (2 * row_spacing) + 12
    end
    if desired_height < 96 then desired_height = 96 end
    _sync_preview_holder_height(self, holder, desired_height)

    local cw, ch = p.container:GetSize()
    if vertical then
        local group_width = (3 * bw) + (2 * row_spacing)
        local x = math.floor((cw - group_width) / 2)
        if x < 0 then x = 0 end
        local y = math.floor((ch - bh) / 2)
        if y < 0 then y = 0 end

        apply_row(p.buff, x, y, "Buff", buff_bar_color)
        apply_row(p.debuff_curable, x + bw + row_spacing, y, "Curable Debuff", debuff_curable_bar_color)
        apply_row(p.debuff_noncurable, x + (2 * (bw + row_spacing)), y, "Non-curable Debuff",
            debuff_noncurable_bar_color)
    else
        local group_height = (3 * bh) + (2 * row_spacing)
        local x = math.floor((cw - bw) / 2)
        if x < 0 then x = 0 end
        local y = math.floor((ch - group_height) / 2)
        if y < 0 then y = 0 end

        apply_row(p.buff, x, y, "Buff", buff_bar_color)
        apply_row(p.debuff_curable, x, y + bh + row_spacing, "Curable Debuff", debuff_curable_bar_color)
        apply_row(p.debuff_noncurable, x, y + (2 * (bh + row_spacing)), "Non-curable Debuff",
            debuff_noncurable_bar_color)
    end
end
