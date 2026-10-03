-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local ConfigWindow = _G.LUI.Settings.ConfigWindow
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local UI = _G.LUI.UI
import "LUI.src.Utils.color"

local Common = _G.LUI.Settings.Preview.Common
local _dim_color = Common.dim_color
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _apply_preview_border = Common.apply_preview_border
local _preview_number_abbrev_settings = Common.preview_number_abbrev_settings
local _morale_color_preview = Common.morale_color_preview
local _sync_preview_holder_height = Common.sync_preview_holder_height

import "LUI.src.Utils.vitals_labels"

local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _render_preview_targets_target_label(window, label_index, label, raw_scale, width, height,
                                                    default_font_size, context)
    local controls = window.controls
    local key = "target_targets_target_label" .. tostring(label_index)
    local enabled = controls[key .. "_enabled"].cb:IsChecked() == true
    local text = controls[key .. "_text"].tb:GetText()

    if enabled ~= true or _label_text_is_blank(text) == true then
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

    label:SetFont(_require_font(font_name, font_size))
    label:SetFontStyle(LUI_TO_LOTRO.font_style[font_style_enum])
    label:SetForeColor(_require_control_color(controls, key .. "_font_color"))
    label:SetOutlineColor(_require_control_color(controls, key .. "_font_outline_color"))
    lui_vitals_layout_label(
        label,
        width,
        height,
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

local function _render_preview_targets_target_labels(window, labels, raw_scale, width, height, default_font_size, context)
    for i = 1, #labels do
        _render_preview_targets_target_label(window, i, labels[i], raw_scale, width, height, default_font_size, context)
    end
end

function ConfigWindow:init_target_targets_target_preview()
    local holder = self.controls.target_targets_target_preview

    if self.target_targets_target_preview ~= nil then
        return
    end

    self.target_targets_target_preview = {
        container = holder.control,
    }

    local p = self.target_targets_target_preview
    p.container:SetMouseVisible(false)

    p.outer = Turbine.UI.Control()
    p.outer:SetParent(p.container)
    p.outer:SetMouseVisible(false)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.outer)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.outer)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.outer)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.outer)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.root = Turbine.UI.Control()
    p.root:SetParent(p.outer)
    p.root:SetMouseVisible(false)

    p.background = Turbine.UI.Control()
    p.background:SetParent(p.root)
    p.background:SetMouseVisible(false)

    p.morale = Turbine.UI.Control()
    p.morale:SetParent(p.background)
    p.morale:SetMouseVisible(false)
    p.morale:SetZOrder(1)

    p.bubble = Turbine.UI.Control()
    p.bubble:SetParent(p.background)
    p.bubble:SetMouseVisible(false)
    p.bubble:SetZOrder(2)
    p.bubble:SetVisible(false)

    p.labels = {}
    for i = 1, 2 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(p.root)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(9 + i)
        p.labels[i] = label
    end
end

function ConfigWindow:update_target_targets_target_preview()
    local p = self.target_targets_target_preview
    if p == nil then
        self:init_target_targets_target_preview()
        p = self.target_targets_target_preview
    end

    local raw_scale = _require_positive_scale(self)

    local function scaled_int(raw_value)
        local n = tonumber(raw_value)
        if n == nil then
            error("Invalid target's target preview scaled int: " .. tostring(raw_value))
        end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value)
        local n = tonumber(raw_value)
        if n == nil then
            error("Invalid target's target preview scaled border: " .. tostring(raw_value))
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    local frame_w = scaled_int(_require_control_number(self.controls, "target_targets_target_width"))
    local border = scaled_border(_require_control_number(self.controls, "target_targets_target_border_width"))
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_h = _require_control_number(self.controls, "target_targets_target_height")
    local bar_h = scaled_int(raw_h)
    if bar_h < 10 then bar_h = 10 end

    local preview_border = 1
    local outer_w = frame_w + (2 * preview_border)
    local outer_h = bar_h + (2 * preview_border)
    local desired_h = bar_h + 24 + (2 * preview_border)
    local holder = self.controls.target_targets_target_preview
    _sync_preview_holder_height(self, holder, desired_h)

    local cw, ch = p.container:GetSize()
    local x = math.floor((cw - outer_w) / 2)
    if x < 0 then x = 0 end
    local y = math.floor((ch - outer_h) / 2)
    if y < 0 then y = 0 end

    p.outer:SetPosition(x, y)
    p.outer:SetSize(outer_w, outer_h)
    p.root:SetPosition(preview_border, preview_border)
    p.root:SetSize(frame_w, bar_h)
    _apply_preview_border(p, outer_w, outer_h)

    local morale_bg = _require_control_color(self.controls, "target_targets_target_background_color")
    local ressource_bg_matches_missing =
        self.controls.target_targets_target_background_matches_missing.cb:IsChecked() == true
    local ressource_bg_dimming = _require_control_number(self.controls, "target_targets_target_background_dimming")
    local background_opacity = _require_control_number(self.controls, "target_targets_target_background_opacity")
    local border_color = _require_control_color(self.controls, "target_targets_target_border_color")
    local bubble_color = _require_control_color(self.controls, "target_targets_target_bubble_color")
    local gradient_enabled = self.controls.target_targets_target_color_gradient.cb:IsChecked() == true
    local high = _require_control_color(self.controls, "target_targets_target_color_high")
    local medium = _require_control_color(self.controls, "target_targets_target_color_medium")
    local low = _require_control_color(self.controls, "target_targets_target_color_low")
    local critical = _require_control_color(self.controls, "target_targets_target_color_critical")
    local gradient_full = _require_control_color(self.controls, "target_targets_target_color_gradient_full")
    local gradient_mid = _require_control_color(self.controls, "target_targets_target_color_gradient_mid")
    local gradient_low = _require_control_color(self.controls, "target_targets_target_color_gradient_low")
    Common.update_gradient_preview(self, "target_targets_target_color_gradient_preview", gradient_full, gradient_mid,
        gradient_low)

    local function morale_color(percent)
        return _morale_color_preview(percent, gradient_enabled, gradient_full, gradient_mid, gradient_low, high,
            medium, low, critical)
    end

    local function resource_background(fill_color)
        local color
        if ressource_bg_matches_missing == true then
            color = _dim_color(fill_color, ressource_bg_dimming)
        else
            color = morale_bg
        end
        return lui_apply_opacity_to_color(color, background_opacity)
    end

    p.root:SetBackColor(border_color)

    local inner_w = frame_w - (2 * border)
    local inner_h = bar_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    local percent = 0.72
    local fill_color = morale_color(percent)

    p.background:SetPosition(border, border)
    p.background:SetSize(inner_w, inner_h)
    p.background:SetBackColor(resource_background(fill_color))

    local fill_w = math.floor(inner_w * percent + 0.5)
    if fill_w < 0 then fill_w = 0 end
    if fill_w > inner_w then fill_w = inner_w end

    p.morale:SetPosition(0, 0)
    p.morale:SetSize(fill_w, inner_h)
    p.morale:SetBackColor(fill_color)

    local bubble_percent = 0.20
    local bubble_w = math.floor(inner_w * bubble_percent + 0.5)
    if bubble_w < 0 then bubble_w = 0 end
    if bubble_w > inner_w then bubble_w = inner_w end

    if bubble_w > 0 then
        p.bubble:SetVisible(true)
        p.bubble:SetBackColor(bubble_color)
        p.bubble:SetTop(0)
        p.bubble:SetHeight(inner_h)
        p.bubble:SetWidth(bubble_w)
        local max_left = inner_w - bubble_w
        if max_left < 0 then max_left = 0 end
        local left_inner = fill_w
        if left_inner > max_left then left_inner = max_left end
        p.bubble:SetLeft(left_inner)
    else
        p.bubble:SetVisible(false)
    end

    local tt_bubble_fmt = self.controls.target_targets_target_bubble_text.tb:GetText()
    local tt_bubble_tokens = lui_tokenize_format(tt_bubble_fmt)
    local tt_max = 10000
    local tt_cur = math.floor(tt_max * percent + 0.5)
    local tt_bubble = math.floor(tt_max * bubble_percent + 0.5)
    local tt_pct_text = tostring(math.floor(percent * 100 + 0.5)) .. "%"

    local tt_bubble_text = ""
    if tt_bubble > 0 then
        tt_bubble_text = lui_abbrev_number(tt_bubble)
    end

    local tt_bubble_formatted = ""
    if tt_bubble > 0 and string.len(tt_bubble_fmt) > 0 then
        tt_bubble_formatted = lui_format_tokenized(tt_bubble_tokens, { b = tt_bubble_text })
    end

    _render_preview_targets_target_labels(self, p.labels, raw_scale, frame_w, bar_h, 14, {
        name = TR["Target's Target"],
        level = "150",
        c = lui_abbrev_number(tt_cur),
        t = lui_abbrev_number(tt_max),
        p = tt_pct_text,
        b = tt_bubble_text,
        B = tt_bubble_formatted,
    })

    lui_clear_number_abbrev_preview_settings()
end
