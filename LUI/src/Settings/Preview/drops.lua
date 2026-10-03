-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local lui_timed_row_min_name_width = _G.LUI.Utils.lui_timed_row_min_name_width
local ConfigWindow = _G.LUI.Settings.ConfigWindow
local LUI_ENUMS = _G.LUI.Settings.Enums
local UI = _G.LUI.UI
import "LUI.src.Utils.timed_row_layout"

local Common = _G.LUI.Settings.Preview.Common
local _apply_preview_border = Common.apply_preview_border
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _sync_preview_holder_height = Common.sync_preview_holder_height

local BASE_ROW_PADDING = 4
local BASE_GAP = 6
local BASE_FONT_SIZE = 12
local BASE_SPACING = 0
local PREVIEW_MARGIN = 4

local function _drops_qty_width(font_size)
    return lui_timed_row_estimate_text_width("999", "Verdana", font_size)
end

local function _drops_min_width(icon_size, padding, gap, font_size)
    local qty_width = _drops_qty_width(font_size)
    local name_width = lui_timed_row_min_name_width("Verdana", font_size)
    return math.max(140, (2 * padding) + icon_size + gap + qty_width + gap + name_width)
end

local function _with_alpha(color, alpha)
    if color == nil then
        return Turbine.UI.Color(alpha, 1, 1, 1)
    end
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

local function _set_alpha_backdrop(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _create_row(parent)
    local row = {}

    row.root = Turbine.UI.Control()
    row.root:SetParent(parent)
    row.root:SetMouseVisible(false)

    row.background = Turbine.UI.Control()
    row.background:SetParent(row.root)
    row.background:SetMouseVisible(false)
    _set_alpha_backdrop(row.background)

    row.icon = Turbine.UI.Control()
    row.icon:SetParent(row.root)
    row.icon:SetMouseVisible(false)
    _set_alpha_backdrop(row.icon)

    row.name = UI.Widgets.LuiLabel()
    row.name:SetParent(row.root)
    row.name:SetMouseVisible(false)
    row.name:SetMultiline(true)
    row.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    row.qty = UI.Widgets.LuiLabel()
    row.qty:SetParent(row.root)
    row.qty:SetMouseVisible(false)
    row.qty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    return row
end

function ConfigWindow:init_drops_preview()
    local holder = self.controls.drops_preview
    if self.drops_preview ~= nil then
        return
    end

    self.drops_preview = {}
    local p = self.drops_preview
    p.container = holder.control
    p.background = Turbine.UI.Control()
    p.background:SetParent(p.container)
    p.background:SetMouseVisible(false)
    _set_alpha_backdrop(p.background)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.container)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.container)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.container)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.container)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.rows = {
        _create_row(p.container),
        _create_row(p.container),
        _create_row(p.container),
    }

    p.container.SizeChanged = function()
        self:update_drops_preview()
    end

    self:update_drops_preview()
end

function ConfigWindow:update_drops_preview()
    if self.drops_preview == nil then
        self:init_drops_preview()
    end

    local p = self.drops_preview
    local raw_scale = _require_positive_scale(self)

    local function scaled_int(raw_value)
        return math.floor((raw_value * raw_scale) + 0.5)
    end

    local rows = _require_control_number(self.controls, "drops_rows")
    rows = math.max(1, math.floor(rows + 0.5))
    local icon_size = _require_control_number(self.controls, "drops_icon_size")
    if icon_size < 1 then
        icon_size = 1
    end
    local row_pad = scaled_int(BASE_ROW_PADDING)
    local row_h = scaled_int(icon_size) + (2 * row_pad)
    local icon_pixels = scaled_int(icon_size)
    local gap = scaled_int(BASE_GAP)
    local qty_font_size = BASE_FONT_SIZE * raw_scale
    local qty_w = _drops_qty_width(qty_font_size)
    local width = _require_control_number(self.controls, "drops_width")
    width = scaled_int(width)
    local min_width = _drops_min_width(icon_pixels, row_pad, gap, qty_font_size)
    if width < min_width then
        width = min_width
    end
    local spacing = scaled_int(BASE_SPACING)
    local preview_rows = math.min(3, rows)
    local block_h = (preview_rows * row_h) + ((preview_rows - 1) * spacing)
    local capacity_h = (rows * row_h) + ((rows - 1) * spacing)

    _sync_preview_holder_height(self, self.controls.drops_preview, capacity_h + (2 * PREVIEW_MARGIN))

    local holder_w = p.container:GetWidth()
    if holder_w < width then
        width = holder_w
    end
    if width < 1 then
        width = 1
    end

    local frame_x = math.max(0, math.floor((holder_w - width) / 2))

    local flow = _require_control_enum(self.controls, "drops_flow")
    local align = _require_control_enum(self.controls, "drops_align")
    local icon_position = _require_control_enum(self.controls, "drops_icon_side")
    local hud_color = _require_control_color(self.controls, "drops_hud_background_color")
    local hud_opacity = _require_control_number(self.controls, "drops_hud_background_opacity")
    local item_color = _require_control_color(self.controls, "drops_item_background_color")
    local item_opacity = _require_control_number(self.controls, "drops_item_background_opacity")

    local font = _require_font(LUI_ENUMS.font_name.VERDANA, BASE_FONT_SIZE * raw_scale)
    local frame_y = PREVIEW_MARGIN
    local y0 = PREVIEW_MARGIN
    if align == LUI_ENUMS.vertical_align.BOTTOM then
        y0 = math.max(PREVIEW_MARGIN, frame_y + capacity_h - block_h)
    end

    p.background:SetVisible(true)
    p.background:SetPosition(frame_x, y0)
    p.background:SetSize(width, block_h)
    p.background:SetBackColor(_with_alpha(hud_color, hud_opacity))
    _apply_preview_border(p, width, capacity_h, frame_x, frame_y)

    local samples = {}
    if flow == LUI_ENUMS.list_flow.TOP_TO_BOTTOM then
        for i = preview_rows, 1, -1 do
            samples[#samples + 1] = {
                name = "Drop " .. tostring(i),
                qty = tostring(i),
                icon = (i % 2) == 1,
            }
        end
    else
        for i = 1, preview_rows do
            samples[#samples + 1] = {
                name = "Drop " .. tostring(i),
                qty = tostring(i),
                icon = (i % 2) == 1,
            }
        end
    end

    for i = 1, #p.rows do
        local row = p.rows[i]
        local sample = samples[i]
        if sample == nil or i > preview_rows then
            row.root:SetVisible(false)
        else
            local y = y0 + ((i - 1) * (row_h + spacing))
            row.root:SetVisible(true)
            row.root:SetPosition(frame_x + 1, y)
            row.root:SetSize(math.max(1, width - 2), row_h)
            row.background:SetPosition(0, 0)
            row.background:SetSize(math.max(1, width - 2), row_h)
            row.background:SetBackColor(_with_alpha(item_color, item_opacity))
            row.icon:SetSize(icon_pixels, icon_pixels)
            row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))
            row.icon:SetVisible(sample.icon == true)
            row.name:SetFont(font)
            row.name:SetFontStyle(Turbine.UI.FontStyle.Outline)
            row.name:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
            row.name:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
            row.name:SetText(sample.name)
            local content_width = math.max(1, width - 2)
            row.qty:SetFont(font)
            row.qty:SetFontStyle(Turbine.UI.FontStyle.Outline)
            row.qty:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
            row.qty:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
            row.qty:SetText(sample.qty)
            if icon_position == LUI_ENUMS.side.RIGHT then
                local preview_icon_x = content_width - row_pad - icon_pixels
                row.icon:SetPosition(preview_icon_x, row_pad)
                row.qty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
                row.qty:SetPosition(row_pad, row_pad)
                row.qty:SetSize(qty_w, math.max(1, row_h - (2 * row_pad)))
                local text_x = row_pad + qty_w + gap
                row.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
                row.name:SetPosition(text_x, row_pad)
                row.name:SetSize(math.max(1, preview_icon_x - text_x - gap), math.max(1, row_h - (2 * row_pad)))
            else
                local qty_x = content_width - row_pad - qty_w
                row.icon:SetPosition(row_pad, row_pad)
                row.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
                row.name:SetPosition(row_pad + icon_pixels + gap, row_pad)
                row.name:SetSize(math.max(1, qty_x - (row_pad + icon_pixels + gap) - gap),
                    math.max(1, row_h - (2 * row_pad)))
                row.qty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
                row.qty:SetPosition(qty_x, row_pad)
                row.qty:SetSize(qty_w, math.max(1, row_h - (2 * row_pad)))
            end
        end
    end
end
