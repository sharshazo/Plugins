-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_format_cooldown_time = _G.LUI.Utils.lui_format_cooldown_time
local lui_cooldown_text_gap = _G.LUI.Utils.lui_cooldown_text_gap
local lui_cooldown_time_label_width = _G.LUI.Utils.lui_cooldown_time_label_width
local lui_timed_row_vertical_time_label_rect = _G.LUI.Utils.lui_timed_row_vertical_time_label_rect
local lui_timed_row_resolve_item_footprint = _G.LUI.Utils.lui_timed_row_resolve_item_footprint
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local ConfigWindow = _G.LUI.Settings.ConfigWindow
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local UI = _G.LUI.UI
import "LUI.src.Cooldowns.time_display"
import "LUI.src.Utils.color"

local Common = _G.LUI.Settings.Preview.Common
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _preview_bar_background = Common.preview_resource_background

local function _truncate_name(name, max_chars)
    if type(name) ~= "string" then
        name = tostring(name or "")
    end

    local m = tonumber(max_chars)
    if m == nil or m <= 0 then
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

function ConfigWindow:init_cooldowns_preview()
    local holder = self.controls.cooldowns_preview

    if self.cooldowns_preview ~= nil then
        return
    end

    self.cooldowns_preview = {}
    local p = self.cooldowns_preview
    p.container = holder.control
    p.preview_border_thickness = 1

    p.container.SizeChanged = function()
        self:update_cooldowns_preview()
    end

    local function create_row()
        local row = {}

        row.preview = Turbine.UI.Control()
        row.preview:SetParent(p.container)
        row.preview:SetMouseVisible(false)

        row.preview_top = Turbine.UI.Control()
        row.preview_top:SetParent(row.preview)
        row.preview_top:SetMouseVisible(false)
        row.preview_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_bottom = Turbine.UI.Control()
        row.preview_bottom:SetParent(row.preview)
        row.preview_bottom:SetMouseVisible(false)
        row.preview_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_left = Turbine.UI.Control()
        row.preview_left:SetParent(row.preview)
        row.preview_left:SetMouseVisible(false)
        row.preview_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_right = Turbine.UI.Control()
        row.preview_right:SetParent(row.preview)
        row.preview_right:SetMouseVisible(false)
        row.preview_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border = Turbine.UI.Control()
        row.border:SetParent(row.preview)
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

        row.separator = Turbine.UI.Control()
        row.separator:SetParent(row.entry)
        row.separator:SetMouseVisible(false)

        row.bar_background = Turbine.UI.Control()
        row.bar_background:SetParent(row.entry)
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

        row.icon_background = Turbine.UI.Control()
        row.icon_background:SetParent(row.entry)
        row.icon_background:SetMouseVisible(false)

        row.icon = Turbine.UI.Control()
        row.icon:SetParent(row.icon_background)
        row.icon:SetMouseVisible(false)
        row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

        return row
    end

    p.row = create_row()
    self:update_cooldowns_preview()
end

function ConfigWindow:update_cooldowns_preview()
    if self.cooldowns_preview == nil then
        self:init_cooldowns_preview()
    end
    local raw_scale = _require_positive_scale(self)

    local function scaled_int(raw_value)
        local n = tonumber(raw_value)
        if n == nil then
            error("Invalid cooldown preview scaled int: " .. tostring(raw_value))
        end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value)
        local n = tonumber(raw_value)
        if n == nil then
            error("Invalid cooldown preview scaled border: " .. tostring(raw_value))
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value)
        local n = tonumber(raw_value)
        if n == nil then
            error("Invalid cooldown preview scaled number: " .. tostring(raw_value))
        end
        return n * raw_scale
    end

    local raw_item_h = _require_control_number(self.controls, "cd_item_h")
    local item_h = scaled_int(raw_item_h)
    if item_h < 10 then item_h = 10 end

    local bg = _require_control_color(self.controls, "cd_bg_color")
    local bg_opacity = _require_control_number(self.controls, "cd_background_opacity")
    local bar = _require_control_color(self.controls, "cd_bar_color")
    local bar_fill = lui_apply_opacity_to_color(bar, _require_control_number(self.controls, "cd_bar_opacity"))
    local border_color = _require_control_color(self.controls, "cd_border_color")
    local bg_matches_fill = self.controls.cd_bar_background_matches_fill.cb:IsChecked() == true
    local bg_dimming = _require_control_number(self.controls, "cd_bar_background_dimming")
    local icon_bg = lui_apply_opacity_to_color(bg, bg_opacity)
    local bar_bg = lui_apply_opacity_to_color(
        _preview_bar_background(bg_matches_fill, bg_dimming, bg, bar),
        bg_opacity
    )

    local raw_border_w = _require_control_number(self.controls, "cd_border_width")
    local border = scaled_border(raw_border_w)
    if border < 0 then border = 0 end

    local icon_side = _require_control_enum(self.controls, "cd_icon_side")
    local icon_near = LUI_ENUMS.side_is_left[icon_side] == true

    local bar_expire_towards = _require_control_enum(self.controls, "cd_bar_expire_towards")

    local bar_mode = _require_control_enum(self.controls, "cd_bar_mode")

    local time_format = _require_control_enum(self.controls, "cd_time_format")

    local orientation = _require_control_enum(self.controls, "cd_orientation")
    local vertical = orientation == LUI_ENUMS.orientation.VERTICAL
    local show_time = self.controls.cd_show_time.cb:IsChecked() == true

    local raw_text_margin = _require_control_number(self.controls, "cd_text_margin")
    local text_margin = scaled_int(raw_text_margin)
    if text_margin < 0 then text_margin = 0 end

    local name_max_chars = _require_control_number(self.controls, "cd_name_max_chars")

    local font_name = _require_control_enum(self.controls, "cd_font_name")
    local raw_font_size = _require_control_number(self.controls, "cd_font_size")
    local font_size = scaled_number(raw_font_size)
    local font = _require_font(font_name, font_size)

    local font_style = _require_control_enum(self.controls, "cd_font_style")
    local font_style_lotro = LUI_TO_LOTRO.font_style[font_style] or Turbine.UI.FontStyle.None

    local font_color = _require_control_color(self.controls, "cd_font_color")
    local outline_color = _require_control_color(self.controls, "cd_font_outline_color")

    local threshold = _require_control_number(self.controls, "cd_threshold")
    if threshold <= 0 then
        error("Invalid cooldown preview threshold: " .. tostring(threshold))
    end

    -- item_w is the bar length (main axis) and item_h the thickness (cross
    -- axis) in both orientations.
    local raw_item_w = _require_control_number(self.controls, "cd_item_w")
    local item_len = scaled_int(raw_item_w)
    if item_len < 10 then item_len = 10 end

    -- On vertical bars the resolver shrinks the time font to fit the
    -- thickness and downgrades show_time when even the smallest size does
    -- not fit.
    local item_w, time_font_size
    item_w, item_h, show_time, time_font_size = lui_timed_row_resolve_item_footprint(
        vertical, show_time,
        item_len, item_h,
        border, text_margin,
        font_name, font_size,
        threshold, time_format
    )

    local row = self.cooldowns_preview.row
    local p = self.cooldowns_preview

    local outer_bw = p.preview_border_thickness
    if outer_bw < 1 then outer_bw = 1 end

    -- The page layout bounds the holder against its own minimum tab-content
    -- height, so no explicit cap is needed here.
    local holder = self.controls.cooldowns_preview
    local desired_holder_h = 52
    if vertical then
        desired_holder_h = item_h + (2 * outer_bw) + 8
        if desired_holder_h < 52 then desired_holder_h = 52 end
    end
    if holder.height ~= desired_holder_h then
        holder.height = desired_holder_h
        holder.on_height_changed()
    end

    local pw, ph = p.container:GetSize()

    local show_w = item_w
    local show_h = item_h

    local max_show_w = pw - (2 * outer_bw)
    local max_show_h = ph - (2 * outer_bw)
    if max_show_w < 1 then max_show_w = 1 end
    if max_show_h < 1 then max_show_h = 1 end

    if show_w > max_show_w then show_w = max_show_w end
    if show_h > max_show_h then show_h = max_show_h end
    if show_w < 1 then show_w = 1 end
    if show_h < 1 then show_h = 1 end

    local bw_draw = border
    if bw_draw * 2 >= show_w then bw_draw = math.floor((show_w - 1) / 2) end
    if bw_draw * 2 >= show_h then bw_draw = math.floor((show_h - 1) / 2) end
    if bw_draw < 0 then bw_draw = 0 end

    local preview_w = show_w + (2 * outer_bw)
    local preview_h = show_h + (2 * outer_bw)

    local off_x = math.max(0, math.floor((pw - preview_w) / 2))
    local off_y = math.max(0, math.floor((ph - preview_h) / 2))

    row.preview:SetPosition(off_x, off_y)
    row.preview:SetSize(preview_w, preview_h)

    row.preview_top:SetPosition(0, 0)
    row.preview_top:SetSize(preview_w, outer_bw)
    row.preview_bottom:SetPosition(0, preview_h - outer_bw)
    row.preview_bottom:SetSize(preview_w, outer_bw)
    row.preview_left:SetPosition(0, 0)
    row.preview_left:SetSize(outer_bw, preview_h)
    row.preview_right:SetPosition(preview_w - outer_bw, 0)
    row.preview_right:SetSize(outer_bw, preview_h)

    row.border:SetPosition(outer_bw, outer_bw)
    row.border:SetSize(show_w, show_h)

    row.border_top:SetBackColor(border_color)
    row.border_bottom:SetBackColor(border_color)
    row.border_left:SetBackColor(border_color)
    row.border_right:SetBackColor(border_color)

    row.border_top:SetPosition(0, 0)
    row.border_top:SetSize(show_w, bw_draw)
    row.border_bottom:SetPosition(0, show_h - bw_draw)
    row.border_bottom:SetSize(show_w, bw_draw)
    row.border_left:SetPosition(0, 0)
    row.border_left:SetSize(bw_draw, show_h)
    row.border_right:SetPosition(show_w - bw_draw, 0)
    row.border_right:SetSize(bw_draw, show_h)

    local inner_x = bw_draw
    local inner_y = bw_draw
    local inner_w = show_w - (2 * bw_draw)
    local inner_h = show_h - (2 * bw_draw)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    row.entry:SetPosition(inner_x, inner_y)
    row.entry:SetSize(inner_w, inner_h)

    local inner_main = vertical and inner_h or inner_w
    local inner_cross = vertical and inner_w or inner_h

    local sep = bw_draw
    if sep < 0 then sep = 0 end
    if sep >= inner_main then sep = inner_main - 1 end
    if sep < 0 then sep = 0 end

    local icon_size = inner_cross
    local max_icon = inner_main - sep - 1
    if max_icon < 1 then max_icon = 1 end
    if icon_size > max_icon then
        icon_size = max_icon
    end

    local bar_len = inner_main - icon_size - sep
    if bar_len < 1 then bar_len = 1 end

    row.separator:SetBackColor(border_color)
    row.separator:SetVisible(sep > 0)

    if vertical then
        if icon_near then
            row.icon_background:SetPosition(0, 0)

            row.separator:SetPosition(0, icon_size)
            row.separator:SetSize(inner_w, sep)

            row.bar_background:SetPosition(0, icon_size + sep)
        else
            row.bar_background:SetPosition(0, 0)

            row.separator:SetPosition(0, bar_len)
            row.separator:SetSize(inner_w, sep)

            row.icon_background:SetPosition(0, bar_len + sep)
        end
        row.bar_background:SetSize(inner_cross, bar_len)
    else
        if icon_near then
            row.icon_background:SetPosition(0, 0)

            row.separator:SetPosition(icon_size, 0)
            row.separator:SetSize(sep, inner_h)

            row.bar_background:SetPosition(icon_size + sep, 0)
        else
            row.bar_background:SetPosition(0, 0)

            row.separator:SetPosition(bar_len, 0)
            row.separator:SetSize(sep, inner_h)

            row.icon_background:SetPosition(bar_len + sep, 0)
        end
        row.bar_background:SetSize(bar_len, inner_cross)
    end

    row.icon_background:SetSize(icon_size, icon_size)
    row.icon_background:SetBackColor(icon_bg)
    row.bar_background:SetBackColor(bar_bg)

    local total = threshold * 1.4
    if total < 3 then total = 3 end

    local base = total
    if base > threshold then
        base = threshold
    end

    local remaining = base * 0.6
    local ratio = remaining / base
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end

    local percent = ratio
    if bar_mode == LUI_ENUMS.bar_mode.LOAD then
        percent = 1 - ratio
    end

    local fill_len = math.floor(bar_len * percent + 0.5)
    if fill_len < 0 then fill_len = 0 end
    if fill_len > bar_len then fill_len = bar_len end

    -- side RIGHT means right when horizontal, bottom when vertical.
    local towards_far = bar_expire_towards == LUI_ENUMS.side.RIGHT
    local anchor_far = towards_far
    if bar_mode == LUI_ENUMS.bar_mode.LOAD then
        anchor_far = towards_far ~= true
    end

    if vertical then
        if anchor_far then
            row.bar_fill:SetPosition(0, bar_len - fill_len)
        else
            row.bar_fill:SetPosition(0, 0)
        end
        row.bar_fill:SetSize(inner_cross, fill_len)
    else
        if anchor_far then
            row.bar_fill:SetPosition(bar_len - fill_len, 0)
        else
            row.bar_fill:SetPosition(0, 0)
        end
        row.bar_fill:SetSize(fill_len, inner_cross)
    end
    row.bar_fill:SetBackColor(bar_fill)

    row.name_label:SetVisible(vertical ~= true)
    row.time_label:SetVisible(show_time)

    if vertical then
        if show_time then
            local time_x, time_y, time_w, time_h = lui_timed_row_vertical_time_label_rect(
                font_name, time_font_size, bar_len, inner_cross, icon_near)

            row.time_label:SetFont(_require_font(font_name, time_font_size))
            row.time_label:SetFontStyle(font_style_lotro)
            row.time_label:SetForeColor(font_color)
            row.time_label:SetOutlineColor(outline_color)
            row.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            row.time_label:SetPosition(time_x, time_y)
            row.time_label:SetSize(time_w, time_h)
            row.time_label:SetText(lui_format_cooldown_time(remaining, time_format))
        end
    else
        local time_width = 0
        local text_gap = 0
        if show_time then
            time_width = lui_cooldown_time_label_width(font_name, font_size, threshold, time_format)
            text_gap = lui_cooldown_text_gap(font_size)
        end
        local title_width = inner_w - icon_size - sep - (2 * text_margin) - time_width - text_gap
        if title_width < 1 then
            title_width = 1
        end
        local time_x = text_margin + title_width + text_gap

        row.name_label:SetFont(font)
        row.name_label:SetFontStyle(font_style_lotro)
        row.name_label:SetForeColor(font_color)
        row.name_label:SetOutlineColor(outline_color)
        row.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        row.name_label:SetPosition(text_margin, 0)
        row.name_label:SetSize(title_width, inner_h)

        local example_name = table.concat({ TR["Example skill"], TR["Example skill"], TR["Example skill"] }, " ")
        row.name_label:SetText(_truncate_name(example_name, name_max_chars))

        if show_time then
            row.time_label:SetFont(font)
            row.time_label:SetFontStyle(font_style_lotro)
            row.time_label:SetForeColor(font_color)
            row.time_label:SetOutlineColor(outline_color)
            row.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
            row.time_label:SetPosition(time_x, 0)
            row.time_label:SetSize(time_width, inner_h)
            row.time_label:SetText(lui_format_cooldown_time(remaining, time_format))
        end
    end

    row.icon:SetPosition(0, 0)
    row.icon:SetSize(icon_size, icon_size)
end
