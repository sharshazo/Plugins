-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_format_icon_timeout = _G.LUI.Utils.lui_format_icon_timeout
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local ConfigWindow = _G.LUI.Settings.ConfigWindow
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local UI = _G.LUI.UI
import "LUI.src.Utils.color"

local Common = _G.LUI.Settings.Preview.Common
local _dim_color = Common.dim_color
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _preview_scaled_int = Common.preview_scaled_int
local _preview_scaled_border = Common.preview_scaled_border
local _preview_scaled_number = Common.preview_scaled_number
local _scaled_int = Common.scaled_int
local _apply_preview_border = Common.apply_preview_border
local _preview_number_abbrev_settings = Common.preview_number_abbrev_settings
local _morale_color_preview = Common.morale_color_preview
local _preview_power_max = Common.preview_power_max
local _sync_preview_holder_height = Common.sync_preview_holder_height

import "LUI.src.Utils.vitals_labels"

local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _boss_stack_height(sections, border_width)
    local total = 0
    local visible = 0

    for i = 1, #sections do
        local height = sections[i]
        if type(height) == "number" and height > 0 then
            total = total + height
            visible = visible + 1
        end
    end

    if visible > 1 then
        total = total - ((visible - 1) * border_width)
    end

    if total < 1 then
        total = 1
    end

    return total
end

local function _slot_is_top(slot)
    return slot == LUI_ENUMS.vitals_effect_slot.TOP_NEAR or slot == LUI_ENUMS.vitals_effect_slot.TOP_FAR
end

local function _slot_order(slot)
    if slot == LUI_ENUMS.vitals_effect_slot.TOP_FAR or slot == LUI_ENUMS.vitals_effect_slot.BOTTOM_FAR then
        return 2
    end
    return 1
end

local function _render_preview_boss_label(window, label_index, label, raw_scale, targets, context)
    local controls = window.controls
    local key = "target_boss_label" .. tostring(label_index)
    local enabled = controls[key .. "_enabled"].cb:IsChecked() == true
    local text = controls[key .. "_text"].tb:GetText()

    if enabled ~= true or _label_text_is_blank(text) == true then
        label:SetText("")
        label:SetVisible(false)
        return
    end

    local target = targets[_require_control_enum(controls, key .. "_link_to")]
    if target == nil then
        label:SetText("")
        label:SetVisible(false)
        return
    end

    local text_alignment = _require_control_enum(controls, key .. "_text_alignment")
    local anchor = _require_control_enum(controls, key .. "_anchor")
    local width_mode = _require_control_enum(controls, key .. "_width_mode")
    local font_name = _require_control_enum(controls, key .. "_font_name")
    local raw_font_size = _require_control_number(controls, key .. "_font_size")
    local font_size = raw_font_size * raw_scale
    local font_style_enum = _require_control_enum(controls, key .. "_font_style")
    local rendered_text = lui_format_tokenized(lui_tokenize_format(text), context)

    if label:GetParent() ~= target.parent then
        label:SetParent(target.parent)
    end
    label:SetFont(_require_font(font_name, font_size))
    label:SetFontStyle(LUI_TO_LOTRO.font_style[font_style_enum])
    label:SetForeColor(_require_control_color(controls, key .. "_font_color"))
    label:SetOutlineColor(_require_control_color(controls, key .. "_font_outline_color"))
    lui_vitals_layout_label(
        label,
        target.width,
        target.height,
        anchor,
        width_mode,
        text_alignment,
        math.floor((_require_control_number(controls, key .. "_x_offset") * raw_scale) + 0.5),
        math.floor((_require_control_number(controls, key .. "_y_offset") * raw_scale) + 0.5),
        font_name,
        font_size,
        rendered_text
    )
    label:SetText(rendered_text)
    label:SetVisible(true)
end

local function _render_preview_boss_labels(window, labels, raw_scale, targets, context)
    for i = 1, #labels do
        _render_preview_boss_label(window, i, labels[i], raw_scale, targets, context)
    end
end

local function _layout_preview_icons(icons, count, cols, icon_size, left, top, width, height, reverse_fill,
                                     alignment, colors, font, font_style, font_color, font_outline, first_time,
                                     second_time)
    local used_columns = math.min(count, cols)
    local used_width = used_columns * icon_size
    if used_width > width then
        used_width = width
    end

    local area_left = left
    if alignment == LUI_ENUMS.side.RIGHT then
        area_left = left + width - used_width
        if area_left < left then
            area_left = left
        end
    end

    for i = 1, #icons do
        local icon = icons[i]
        if i > count then
            icon.root:SetVisible(false)
        else
            local idx = i - 1
            local col = idx % cols
            local row = math.floor(idx / cols)
            local col_left = area_left + (col * icon_size)
            local row_top = top + (row * icon_size)
            if reverse_fill == true then
                row_top = top + height - ((row + 1) * icon_size)
            end

            icon.root:SetVisible(true)
            if alignment == LUI_ENUMS.side.RIGHT then
                icon.root:SetPosition(area_left + used_width - ((col + 1) * icon_size), row_top)
            else
                icon.root:SetPosition(col_left, row_top)
            end
            icon.root:SetSize(icon_size, icon_size)
            icon.root:SetBackColor(colors[((i - 1) % #colors) + 1])
            icon.label:SetPosition(0, 0)
            icon.label:SetSize(icon_size, icon_size)
            icon.label:SetFont(font)
            icon.label:SetFontStyle(font_style)
            icon.label:SetForeColor(font_color)
            icon.label:SetOutlineColor(font_outline)
            if i == 1 then
                icon.label:SetText(lui_format_icon_timeout(first_time))
            elseif i == 2 then
                icon.label:SetText(lui_format_icon_timeout(second_time))
            else
                icon.label:SetText("")
            end
        end
    end
end

function ConfigWindow:init_target_boss_vitals_preview()
    local holder = self.controls.target_boss_vitals_preview

    if self.target_boss_vitals_preview ~= nil then
        return
    end

    self.target_boss_vitals_preview = {
        root = Turbine.UI.Control(),
        border_top = Turbine.UI.Control(),
        border_bottom = Turbine.UI.Control(),
        border_left = Turbine.UI.Control(),
        border_right = Turbine.UI.Control(),
        morale_border = Turbine.UI.Control(),
        morale_back = Turbine.UI.Control(),
        morale_fill = Turbine.UI.Control(),
        morale_bubble = Turbine.UI.Control(),
        power_border = Turbine.UI.Control(),
        power_back = Turbine.UI.Control(),
        power_fill = Turbine.UI.Control(),
        labels = {},
        info_border = Turbine.UI.Control(),
        info_back = Turbine.UI.Control(),
        buffs = {},
        debuffs = {},
    }

    local p = self.target_boss_vitals_preview
    local all = {
        p.root,
        p.border_top, p.border_bottom, p.border_left, p.border_right,
        p.morale_border, p.morale_back, p.morale_fill, p.morale_bubble,
        p.power_border, p.power_back, p.power_fill,
        p.info_border, p.info_back,
    }

    for i = 1, #all do
        all[i]:SetParent(holder.control)
        all[i]:SetMouseVisible(false)
    end

    p.morale_back:SetParent(p.morale_border)
    p.morale_fill:SetParent(p.morale_back)
    p.morale_bubble:SetParent(p.morale_back)
    p.power_back:SetParent(p.power_border)
    p.power_fill:SetParent(p.power_back)
    p.info_back:SetParent(p.info_border)

    for i = 1, 4 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(i <= 2 and p.morale_border or p.power_border)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(9 + i)
        p.labels[i] = label
    end

    for i = 1, 12 do
        local icon = Turbine.UI.Control()
        icon:SetParent(holder.control)
        icon:SetMouseVisible(false)
        local label = UI.Widgets.LuiLabel()
        label:SetParent(icon)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        p.buffs[i] = { root = icon, label = label }
    end

    for i = 1, 16 do
        local icon = Turbine.UI.Control()
        icon:SetParent(holder.control)
        icon:SetMouseVisible(false)
        local label = UI.Widgets.LuiLabel()
        label:SetParent(icon)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        p.debuffs[i] = { root = icon, label = label }
    end
end

function ConfigWindow:update_target_boss_vitals_preview()
    local p = self.target_boss_vitals_preview
    if p == nil then
        self:init_target_boss_vitals_preview()
        p = self.target_boss_vitals_preview
    end

    local raw_scale = _require_positive_scale(self)

    local function timer_style(style_enum)
        local style = LUI_TO_LOTRO.font_style[style_enum]
        if style == nil then
            error("Missing boss preview timer font style: " .. tostring(style_enum))
        end
        return style
    end

    local raw_frame_w = _require_control_number(self.controls, "target_boss_width")
    local raw_power_w = _require_control_number(self.controls, "target_boss_power_width")
    local frame_w = _preview_scaled_int(raw_scale, raw_frame_w)
    local power_w = _preview_scaled_int(raw_scale, raw_power_w)
    local border = _preview_scaled_border(raw_scale, _require_control_number(self.controls, "target_boss_border_width"))
    local morale_h = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_morale_height"))
    local power_h = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_power_height"))
    local effects_h = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_effects_height"))
    local info_enabled = self.controls.target_boss_info_enabled.cb:IsChecked() == true
    local info_h = info_enabled == true and
        _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_info_height")) or 0
    local power_side = _require_control_enum(self.controls, "target_boss_power_side")
    local power_hidden = self.controls.target_boss_power_hide.cb:IsChecked() == true
    local buff_slot = _require_control_enum(self.controls, "target_boss_buff_slot")
    local debuff_slot = _require_control_enum(self.controls, "target_boss_debuff_slot")
    local buff_alignment = _require_control_enum(self.controls, "target_boss_buff_alignment")
    local debuff_alignment = _require_control_enum(self.controls, "target_boss_debuff_alignment")

    local buff_size = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_buff_size"))
    local debuff_size = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_debuff_size"))
    if buff_size < 1 then buff_size = 1 end
    if debuff_size < 1 then debuff_size = 1 end

    local holder = self.controls.target_boss_vitals_preview
    local holder_w = holder.control:GetWidth()
    local preview_border = 1
    frame_w = math.min(frame_w, math.max(1, holder_w - (2 * preview_border)))
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end
    if power_w > frame_w then
        power_w = frame_w
    end
    if power_w < 0 then
        power_w = 0
    end

    local buff_count = 6
    local debuff_count = 10
    local buff_cols = math.max(1, math.floor(frame_w / buff_size))
    local debuff_cols = math.max(1, math.floor(frame_w / debuff_size))
    local buffs_reserved_h = effects_h / 2
    local debuffs_reserved_h = effects_h / 2
    local buffs_h = math.min(buffs_reserved_h, math.ceil(buff_count / buff_cols) * buff_size)
    local debuffs_h = math.min(debuffs_reserved_h, math.ceil(debuff_count / debuff_cols) * debuff_size)

    local top_entries = {}
    local bottom_entries = {}

    local function add_entry(list, area, slot, reserved_height, height)
        list[#list + 1] = {
            area = area,
            slot = slot,
            reserved_height = reserved_height,
            height = height,
            order = _slot_order(slot),
        }
    end

    if _slot_is_top(buff_slot) then
        add_entry(top_entries, "buffs", buff_slot, buffs_reserved_h, buffs_h)
    else
        add_entry(bottom_entries, "buffs", buff_slot, buffs_reserved_h, buffs_h)
    end
    if _slot_is_top(debuff_slot) then
        add_entry(top_entries, "debuffs", debuff_slot, debuffs_reserved_h, debuffs_h)
    else
        add_entry(bottom_entries, "debuffs", debuff_slot, debuffs_reserved_h, debuffs_h)
    end

    table.sort(top_entries, function(a, b)
        return a.order > b.order
    end)
    table.sort(bottom_entries, function(a, b)
        return a.order < b.order
    end)

    local core_h = _boss_stack_height({
        morale_h,
        power_hidden == true and 0 or power_h,
        info_h,
    }, border)
    local total_h = effects_h + core_h

    local outer_w = frame_w + (2 * preview_border)
    local outer_h = total_h + (2 * preview_border)
    local holder_extra_h = _scaled_int(9)
    _sync_preview_holder_height(self, holder, outer_h + holder_extra_h)

    local off_x = math.max(0, math.floor((holder_w - outer_w) / 2))
    local outer_y = _scaled_int(4)

    p.root:SetPosition(off_x + preview_border, outer_y + preview_border)
    p.root:SetSize(frame_w, total_h)
    _apply_preview_border({
        border_top = p.border_top,
        border_bottom = p.border_bottom,
        border_left = p.border_left,
        border_right = p.border_right,
    }, outer_w, outer_h)

    local border_color = _require_control_color(self.controls, "target_boss_border_color")
    local morale_back = _require_control_color(self.controls, "target_boss_morale_background_color")
    local ressource_back_matches_missing =
        self.controls.target_boss_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_back_dimming = _require_control_number(self.controls, "target_boss_ressource_background_dimming")
    local background_opacity = _require_control_number(self.controls, "target_boss_background_opacity")
    local morale_high = _require_control_color(self.controls, "target_boss_morale_color_high")
    local morale_medium = _require_control_color(self.controls, "target_boss_morale_color_medium")
    local morale_low = _require_control_color(self.controls, "target_boss_morale_color_low")
    local morale_critical = _require_control_color(self.controls, "target_boss_morale_color_critical")
    local morale_gradient = self.controls.target_boss_morale_gradient.cb:IsChecked() == true
    local morale_gradient_full = _require_control_color(self.controls, "target_boss_morale_gradient_full")
    local morale_gradient_mid = _require_control_color(self.controls, "target_boss_morale_gradient_mid")
    local morale_gradient_low = _require_control_color(self.controls, "target_boss_morale_gradient_low")
    Common.update_gradient_preview(self, "target_boss_morale_gradient_preview", morale_gradient_full,
        morale_gradient_mid, morale_gradient_low)
    local bubble_color = _require_control_color(self.controls, "target_boss_morale_bubble_color")
    local power_fill = _require_control_color(self.controls, "target_boss_power_color")
    local info_back_color = _require_control_color(self.controls, "target_boss_info_background_color")
    local info_opacity = _require_control_number(self.controls, "target_boss_info_opacity")
    local buff_colors = {
        Turbine.UI.Color(1, 0.15, 0.55, 0.55),
        Turbine.UI.Color(1, 0.20, 0.45, 0.72),
        Turbine.UI.Color(1, 0.33, 0.62, 0.28),
        Turbine.UI.Color(1, 0.58, 0.42, 0.76),
        Turbine.UI.Color(1, 0.72, 0.54, 0.20),
        Turbine.UI.Color(1, 0.24, 0.64, 0.44),
    }
    local debuff_colors = {
        Turbine.UI.Color(1, 0.70, 0.35, 0.18),
        Turbine.UI.Color(1, 0.76, 0.20, 0.24),
        Turbine.UI.Color(1, 0.52, 0.24, 0.68),
        Turbine.UI.Color(1, 0.78, 0.48, 0.14),
        Turbine.UI.Color(1, 0.60, 0.18, 0.46),
        Turbine.UI.Color(1, 0.84, 0.30, 0.10),
    }
    local morale_percent = 0.72
    local bubble_percent = 0.08
    local power_percent = 0.55

    local function resource_background(fill_color)
        local color
        if ressource_back_matches_missing == true then
            color = _dim_color(fill_color, ressource_back_dimming)
        else
            color = morale_back
        end
        return lui_apply_opacity_to_color(color, background_opacity)
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    p.border_top:SetBackColor(border_color)
    p.border_bottom:SetBackColor(border_color)
    p.border_left:SetBackColor(border_color)
    p.border_right:SetBackColor(border_color)
    p.border_top:SetPosition(off_x, outer_y)
    p.border_bottom:SetPosition(off_x, outer_y + outer_h - preview_border)
    p.border_left:SetPosition(off_x, outer_y)
    p.border_right:SetPosition(off_x + outer_w - preview_border, outer_y)

    local top_reserved_height = 0
    local top_visual_height = 0
    local effect_positions = {
        buffs = nil,
        debuffs = nil,
    }
    for i = 1, #top_entries do
        top_reserved_height = top_reserved_height + top_entries[i].reserved_height
        top_visual_height = top_visual_height + top_entries[i].height
    end

    local top_cursor = top_reserved_height - top_visual_height
    if top_cursor < 0 then
        top_cursor = 0
    end

    for i = 1, #top_entries do
        local entry = top_entries[i]
        effect_positions[entry.area] = {
            top = top_cursor,
            height = entry.height,
            reverse_fill = true,
        }
        top_cursor = top_cursor + entry.height
    end

    local morale_top = top_reserved_height
    local power_top = morale_top + morale_h - border
    local info_top = power_top
    if power_hidden ~= true then
        info_top = power_top + power_h - border
    end
    local bottom_start = info_top
    if info_h > 0 then
        bottom_start = info_top + info_h - border
    end

    local bottom_cursor = bottom_start
    for i = 1, #bottom_entries do
        local entry = bottom_entries[i]
        effect_positions[entry.area] = {
            top = bottom_cursor,
            height = entry.height,
            reverse_fill = false,
        }
        bottom_cursor = bottom_cursor + entry.height
    end

    p.morale_border:SetPosition(off_x + preview_border, outer_y + preview_border + morale_top)
    p.morale_border:SetSize(frame_w, morale_h)
    p.morale_border:SetBackColor(border_color)
    p.morale_back:SetPosition(border, border)
    p.morale_back:SetSize(frame_w - (2 * border), morale_h - (2 * border))
    local morale_fill_color = _morale_color_preview(morale_percent, morale_gradient, morale_gradient_full,
        morale_gradient_mid, morale_gradient_low, morale_high, morale_medium, morale_low, morale_critical)
    p.morale_back:SetBackColor(resource_background(morale_fill_color))
    p.morale_fill:SetPosition(0, 0)
    p.morale_fill:SetSize(math.floor((frame_w - (2 * border)) * morale_percent + 0.5), morale_h - (2 * border))
    p.morale_fill:SetBackColor(morale_fill_color)
    p.morale_bubble:SetPosition(p.morale_fill:GetWidth(), 0)
    p.morale_bubble:SetSize(math.floor((frame_w - (2 * border)) * bubble_percent + 0.5), morale_h - (2 * border))
    p.morale_bubble:SetBackColor(bubble_color)

    local bubble_fmt = self.controls.target_boss_morale_bubble_text.tb:GetText()
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)
    local morale_max = 600000
    local morale_cur = math.floor(morale_max * morale_percent + 0.5)
    local bubble_value = math.floor(morale_max * bubble_percent + 0.5)
    local bubble_text = bubble_value > 0 and lui_abbrev_number(bubble_value) or ""
    local bubble_formatted = ""
    if bubble_value > 0 and string.len(bubble_fmt) > 0 then
        bubble_formatted = lui_format_tokenized(bubble_fmt_tokens, { b = bubble_text })
    end

    p.power_border:SetVisible(power_hidden ~= true)
    p.power_back:SetVisible(power_hidden ~= true)
    p.power_fill:SetVisible(power_hidden ~= true)

    local power_left = 0
    if power_side == LUI_ENUMS.side.RIGHT then
        power_left = frame_w - power_w
    end
    if power_hidden ~= true then
        p.power_border:SetPosition(off_x + preview_border + power_left, outer_y + preview_border + power_top)
        p.power_border:SetSize(power_w, power_h)
        p.power_border:SetBackColor(border_color)
        p.power_back:SetPosition(border, border)
        p.power_back:SetSize(power_w - (2 * border), power_h - (2 * border))
        p.power_back:SetBackColor(resource_background(power_fill))
        p.power_fill:SetPosition(0, 0)
        p.power_fill:SetSize(math.floor((power_w - (2 * border)) * power_percent + 0.5), power_h - (2 * border))
        p.power_fill:SetBackColor(power_fill)
    else
        for i = 3, 4 do
            p.labels[i]:SetText("")
            p.labels[i]:SetVisible(false)
        end
    end

    p.info_border:SetVisible(info_h > 0)
    p.info_back:SetVisible(info_h > 0)
    if info_h > 0 then
        p.info_border:SetPosition(off_x + preview_border, outer_y + preview_border + info_top)
        p.info_border:SetSize(frame_w, info_h)
        p.info_border:SetBackColor(border_color)
        p.info_back:SetPosition(border, border)
        p.info_back:SetSize(frame_w - (2 * border), info_h - (2 * border))
        p.info_back:SetBackColor(lui_apply_opacity_to_color(info_back_color, info_opacity))
    end

    local label_targets = {
        [LUI_ENUMS.vitals_label_link.MORALE] = {
            parent = p.morale_border,
            width = frame_w,
            height = morale_h,
        },
        [LUI_ENUMS.vitals_label_link.POWER] = power_hidden ~= true and {
            parent = p.power_border,
            width = power_w,
            height = power_h,
        } or nil,
        [LUI_ENUMS.vitals_label_link.INFO] = info_h > 0 and {
            parent = p.info_border,
            width = frame_w,
            height = info_h,
        } or nil,
    }

    local label_context = {
        name = "The Watcher in the Water",
        level = "150",
        mc = lui_abbrev_number(morale_cur),
        mt = lui_abbrev_number(morale_max),
        mp = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%",
        b = bubble_text,
        B = bubble_formatted,
        pc = "-",
        pt = "-",
        pp = "-",
    }

    if power_hidden ~= true then
        local power_max = _preview_power_max(morale_max)
        local power_cur = math.floor(power_max * power_percent + 0.5)
        label_context.pc = lui_abbrev_number(power_cur)
        label_context.pt = lui_abbrev_number(power_max)
        label_context.pp = tostring(math.floor(power_percent * 100 + 0.5)) .. "%"
    end

    _render_preview_boss_labels(self, p.labels, raw_scale, label_targets, label_context)
    if power_hidden == true then
        for i = 3, 4 do
            p.labels[i]:SetText("")
            p.labels[i]:SetVisible(false)
        end
    end

    local buff_timer_font_name = _require_control_enum(self.controls, "target_boss_buff_timer_font_name")
    local buff_timer_font_size = _preview_scaled_number(raw_scale,
        _require_control_number(self.controls, "target_boss_buff_timer_font_size"))
    local buff_timer_font = _require_font(buff_timer_font_name, buff_timer_font_size)
    local buff_timer_style = timer_style(_require_control_enum(self.controls, "target_boss_buff_timer_font_style"))
    local buff_timer_color = _require_control_color(self.controls, "target_boss_buff_timer_font_color")
    local buff_timer_outline = _require_control_color(self.controls, "target_boss_buff_timer_font_outline_color")

    local buff_position = effect_positions.buffs
    if buff_position ~= nil then
        _layout_preview_icons(
            p.buffs,
            buff_count,
            buff_cols,
            buff_size,
            off_x + preview_border,
            outer_y + preview_border + buff_position.top,
            frame_w,
            buff_position.height,
            buff_position.reverse_fill,
            buff_alignment,
            buff_colors,
            buff_timer_font,
            buff_timer_style,
            buff_timer_color,
            buff_timer_outline,
            6,
            2.4
        )
    else
        for i = 1, #p.buffs do
            p.buffs[i].root:SetVisible(false)
        end
    end

    local debuff_timer_font_name = _require_control_enum(self.controls, "target_boss_debuff_timer_font_name")
    local debuff_timer_font_size = _preview_scaled_number(raw_scale,
        _require_control_number(self.controls, "target_boss_debuff_timer_font_size"))
    local debuff_timer_font = _require_font(debuff_timer_font_name, debuff_timer_font_size)
    local debuff_timer_style = timer_style(_require_control_enum(self.controls, "target_boss_debuff_timer_font_style"))
    local debuff_timer_color = _require_control_color(self.controls, "target_boss_debuff_timer_font_color")
    local debuff_timer_outline = _require_control_color(self.controls, "target_boss_debuff_timer_font_outline_color")

    local debuff_position = effect_positions.debuffs
    if debuff_position ~= nil then
        _layout_preview_icons(
            p.debuffs,
            debuff_count,
            debuff_cols,
            debuff_size,
            off_x + preview_border,
            outer_y + preview_border + debuff_position.top,
            frame_w,
            debuff_position.height,
            debuff_position.reverse_fill,
            debuff_alignment,
            debuff_colors,
            debuff_timer_font,
            debuff_timer_style,
            debuff_timer_color,
            debuff_timer_outline,
            7,
            2.2
        )
    else
        for i = 1, #p.debuffs do
            p.debuffs[i].root:SetVisible(false)
        end
    end

    lui_clear_number_abbrev_preview_settings()
end
