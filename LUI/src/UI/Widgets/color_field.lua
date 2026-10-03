-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.line_edit"
import "LUI.src.UI.Widgets.style"
import "LUI.src.Utils.color"

local Widgets = _G.LUI.UI.Widgets
local LuiButton = Widgets.LuiButton
local LuiLineEdit = Widgets.LuiLineEdit
local Style = Widgets.Style

---@class LuiColorField : Turbine.UI.Control
local LuiColorField = class(Turbine.UI.Control)
Widgets.LuiColorField = LuiColorField

local HS_TEXTURE_100 = "LUI/assets/ui/color_hs_100.tga"
local HS_TEXTURE_150 = "LUI/assets/ui/color_hs_150.tga"
local HS_TEXTURE_200 = "LUI/assets/ui/color_hs_200.tga"

local VALUE_GRADIENT_TEXTURE_100 = "LUI/assets/ui/value_gradient_100.tga"
local VALUE_GRADIENT_TEXTURE_150 = "LUI/assets/ui/value_gradient_150.tga"
local VALUE_GRADIENT_TEXTURE_200 = "LUI/assets/ui/value_gradient_200.tga"

local BASE_SWATCH_SIZE = 13
local BASE_SWATCH_GAP = 4
local BASE_FIELD_W = 148
local BASE_FIELD_H = 21
local BASE_TEXTBOX_INSET = 3
local BASE_MIN_BORDER_H = 4
local BASE_MIN_TEXTBOX_W = 15
local BASE_PICKER_HS = 140
local BASE_PICKER_VALUE_W = 18
local BASE_PICKER_GAP = 6
local BASE_PICKER_BUTTON_H = 19
local BASE_PICKER_BUTTON_GAP = 6
local BASE_PICKER_PAD = 7
local BASE_PICKER_OFFSET = 4
local BASE_PICKER_CURSOR = 7

local PICKER_DRAG_NONE = 0
local PICKER_DRAG_HS = 1
local PICKER_DRAG_VALUE = 2

local function _scaled_size(scale, value)
    return value * scale
end

local function _scaled_int(scale, value)
    return math.floor(_scaled_size(scale, value) + 0.5)
end

local function _clamp(v, min_v, max_v)
    if v < min_v then return min_v end
    if v > max_v then return max_v end
    return v
end

local function _picker_image_set(scale)
    if scale == nil or scale < 1.25 then
        return {
            hs_texture = HS_TEXTURE_100,
            value_texture = VALUE_GRADIENT_TEXTURE_100,
            hs_size = BASE_PICKER_HS,
            value_w = BASE_PICKER_VALUE_W,
        }
    elseif scale < 1.75 then
        return {
            hs_texture = HS_TEXTURE_150,
            value_texture = VALUE_GRADIENT_TEXTURE_150,
            hs_size = 210,
            value_w = 27,
        }
    end

    return {
        hs_texture = HS_TEXTURE_200,
        value_texture = VALUE_GRADIENT_TEXTURE_200,
        hs_size = 280,
        value_w = 36,
    }
end

local _hex_to_color = lui_hex_to_color
local _color_to_hex = lui_color_to_hex

local function _hsv_to_rgb(h, s, v)
    local hh = (h or 0) % 360
    local ss = _clamp(s or 0, 0, 1)
    local vv = _clamp(v or 0, 0, 1)

    if ss <= 0 then
        return vv, vv, vv
    end

    local c = vv * ss
    local x = c * (1 - math.abs(((hh / 60) % 2) - 1))
    local m = vv - c

    local r1, g1, b1 = 0, 0, 0
    if hh < 60 then
        r1, g1, b1 = c, x, 0
    elseif hh < 120 then
        r1, g1, b1 = x, c, 0
    elseif hh < 180 then
        r1, g1, b1 = 0, c, x
    elseif hh < 240 then
        r1, g1, b1 = 0, x, c
    elseif hh < 300 then
        r1, g1, b1 = x, 0, c
    else
        r1, g1, b1 = c, 0, x
    end

    return r1 + m, g1 + m, b1 + m
end

local function _rgb_to_hsv(r, g, b)
    local rr = _clamp(r or 0, 0, 1)
    local gg = _clamp(g or 0, 0, 1)
    local bb = _clamp(b or 0, 0, 1)

    local cmax = math.max(rr, math.max(gg, bb))
    local cmin = math.min(rr, math.min(gg, bb))
    local delta = cmax - cmin

    local h = 0
    if delta <= 0 then
        h = 0
    elseif cmax == rr then
        h = 60 * (((gg - bb) / delta) % 6)
    elseif cmax == gg then
        h = 60 * (((bb - rr) / delta) + 2)
    else
        h = 60 * (((rr - gg) / delta) + 4)
    end

    local s = (cmax <= 0) and 0 or (delta / cmax)
    local v = cmax
    return h, s, v
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function LuiColorField:Constructor(swatch_size, swatch_gap)
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._uses_default_size = true
    self._base_swatch_size = swatch_size or BASE_SWATCH_SIZE
    self._base_swatch_gap = swatch_gap or BASE_SWATCH_GAP
    self._swatch_size = _scaled_int(self._scale, self._base_swatch_size)
    self._swatch_gap = _scaled_int(self._scale, self._base_swatch_gap)
    self._picker_host = nil

    self._picker_overlay = nil
    self._picker_panel = nil
    self._picker_h = 0
    self._picker_s = 0
    self._picker_v = 1
    self._picker_original = nil
    self.TextChanged = nil

    self.tb = LuiLineEdit()
    self.tb:SetParent(self)
    self.tb:SetZOrder(1)

    self.swatch_border = Turbine.UI.Control()
    self.swatch_border:SetParent(self)
    self.swatch_border:SetMouseVisible(true)
    self.swatch_border:SetBackColor(Style.CONTROL_BORDER)
    self.swatch_border:SetZOrder(2)

    self.swatch = Turbine.UI.Control()
    self.swatch:SetParent(self.swatch_border)
    self.swatch:SetMouseVisible(false)
    self.swatch:SetPosition(1, 1)
    self.swatch:SetBackColor(Turbine.UI.Color.Black)
    self.swatch:SetZOrder(2)

    self.swatch_border.MouseClick = function()
        self:open_picker()
    end

    self.tb.TextChanged = function(sender, args)
        self:update_swatch()
        local c = _hex_to_color(self:GetText())
        if c ~= nil then
            self._picker_h, self._picker_s, self._picker_v = _rgb_to_hsv(c.R, c.G, c.B)
        end
        if self.TextChanged ~= nil then
            self.TextChanged(sender, args)
        end
    end

    local width = _scaled_int(self._scale, BASE_FIELD_W)
    local height = _scaled_int(self._scale, BASE_FIELD_H)
    Turbine.UI.Control.SetSize(self, width, height)
    self:_layout(width, height)
    self:update_swatch()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function LuiColorField:SetPickerHost(host_window)
    self._picker_host = host_window
end

function LuiColorField:SetFont(font)
    if self.tb ~= nil then
        self.tb:SetFont(font)
    end
end

function LuiColorField:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
    self._swatch_size = _scaled_int(self._scale, self._base_swatch_size)
    self._swatch_gap = _scaled_int(self._scale, self._base_swatch_gap)

    if LuiColorField._active == self then
        self:_close_picker(true)
    end

    if self._uses_default_size == true then
        local width = _scaled_int(self._scale, BASE_FIELD_W)
        local height = _scaled_int(self._scale, BASE_FIELD_H)
        Turbine.UI.Control.SetSize(self, width, height)
        self:_layout(width, height)
        return
    end

    self:_layout(self:GetSize())
end

function LuiColorField:SetTextAlignment(align)
    if self.tb ~= nil then
        self.tb:SetTextAlignment(align)
    end
end

function LuiColorField:GetText()
    return self.tb ~= nil and self.tb:GetText() or ""
end

function LuiColorField:SetText(value)
    if self.tb ~= nil then
        self.tb:SetText(value or "")
    end
    self:update_swatch()
    local c = _hex_to_color(self:GetText())
    if c ~= nil then
        self._picker_h, self._picker_s, self._picker_v = _rgb_to_hsv(c.R, c.G, c.B)
    end
    if self.TextChanged ~= nil then
        self.TextChanged(self.tb, nil)
    end
end

function LuiColorField:update_swatch()
    if self.swatch == nil then
        return
    end
    local color = _hex_to_color(self:GetText())
    if color == nil then
        self.swatch:SetBackColor(Style.INVALID_BACKGROUND)
        return
    end
    self.swatch:SetBackColor(color)
end

function LuiColorField:SetSize(w, h)
    self._uses_default_size = false
    Turbine.UI.Control.SetSize(self, w, h)
    self:_layout(w, h)
end

function LuiColorField:_layout(w, h)
    local height = type(h) == "number" and h or 0
    if height < 4 then
        height = 4
    end

    -- Match the TextBox inner area (input height minus its borders).
    -- LotRO textbox borders are effectively ~2px on top/bottom in the default UI.
    local inset = _scaled_int(self._scale, BASE_TEXTBOX_INSET)
    local border_h = height - inset
    if border_h < _scaled_int(self._scale, BASE_MIN_BORDER_H) then
        border_h = height
    end
    local border_w = border_h
    self._swatch_size = border_h - 2

    local total_w = border_w + self._swatch_gap
    local tb_w = w - total_w
    if tb_w < _scaled_int(self._scale, BASE_MIN_TEXTBOX_W) then
        tb_w = _scaled_int(self._scale, BASE_MIN_TEXTBOX_W)
    end

    self.tb:SetPosition(0, 0)
    self.tb:SetSize(tb_w, h)

    local sw_x = tb_w + self._swatch_gap
    local sw_y = math.floor((height - border_h) / 2)
    if sw_y < 0 then sw_y = 0 end
    self.swatch_border:SetPosition(sw_x, sw_y)
    self.swatch_border:SetSize(border_w, border_h)
    self.swatch:SetSize(self._swatch_size, self._swatch_size)
end

function LuiColorField:open_picker()
    local host = self._picker_host
    if host == nil then
        return
    end

    if LuiColorField._active ~= nil and LuiColorField._active ~= self then
        LuiColorField._active:_close_picker(true)
    end
    LuiColorField._active = self

    local current_text = self:GetText()
    self._picker_original = current_text

    local c = _hex_to_color(current_text) or Turbine.UI.Color(1, 0, 0)
    self._picker_h, self._picker_s, self._picker_v = _rgb_to_hsv(c.R, c.G, c.B)

    local overlay = Turbine.UI.Control()
    overlay:SetParent(host)
    overlay:SetPosition(0, 0)
    overlay:SetSize(host:GetWidth(), host:GetHeight())
    overlay:SetMouseVisible(true)
    overlay:SetZOrder(9999)
    overlay:SetVisible(true)

    local panel = Turbine.UI.Control()
    panel:SetParent(overlay)
    panel:SetMouseVisible(true)
    panel:SetBackColor(Style.PANEL_BACKGROUND)
    panel:SetZOrder(10000)
    panel:SetVisible(true)

    local border = Turbine.UI.Control()
    border:SetParent(panel)
    border:SetMouseVisible(false)
    border:SetBackColor(Style.CONTROL_BORDER)
    border:SetZOrder(1)

    local inner = Turbine.UI.Control()
    inner:SetParent(border)
    inner:SetMouseVisible(false)
    inner:SetBackColor(Style.PANEL_INNER_BACKGROUND)
    inner:SetPosition(1, 1)
    inner:SetZOrder(2)

    local image_set = _picker_image_set(self._scale)
    local hs_size = image_set.hs_size
    local value_w = image_set.value_w
    local gap = _scaled_int(self._scale, BASE_PICKER_GAP)
    local btn_h = _scaled_int(self._scale, BASE_PICKER_BUTTON_H)
    local btn_gap = _scaled_int(self._scale, BASE_PICKER_BUTTON_GAP)
    local pad = _scaled_int(self._scale, BASE_PICKER_PAD)
    local panel_w = (pad * 2) + hs_size + gap + value_w
    local panel_h = (pad * 2) + hs_size + gap + btn_h

    panel:SetSize(panel_w, panel_h)
    border:SetSize(panel_w, panel_h)
    inner:SetSize(panel_w - 2, panel_h - 2)

    local host_sx, host_sy = host:PointToScreen(0, 0)
    local sw_sx, sw_sy = self.swatch_border:PointToScreen(0, 0)
    local rel_x = sw_sx - host_sx
    local rel_y = sw_sy - host_sy

    local px = rel_x + self.swatch_border:GetWidth() + _scaled_int(self._scale, BASE_PICKER_OFFSET)
    local py = rel_y

    if px + panel_w > host:GetWidth() then
        px = rel_x - panel_w - _scaled_int(self._scale, BASE_PICKER_OFFSET)
    end
    if py + panel_h > host:GetHeight() then
        py = host:GetHeight() - panel_h - _scaled_int(self._scale, BASE_PICKER_OFFSET)
    end
    if px < 0 then px = 0 end
    if py < 0 then py = 0 end

    panel:SetPosition(px, py)
    border:SetPosition(0, 0)
    inner:SetPosition(1, 1)

    local picker = {}
    picker.panel = panel
    picker._drag_target = PICKER_DRAG_NONE

    picker.hs = Turbine.UI.Control()
    picker.hs:SetParent(panel)
    picker.hs:SetPosition(pad, pad)
    picker.hs:SetSize(hs_size, hs_size)
    picker.hs:SetMouseVisible(true)
    picker.hs:SetBackground(image_set.hs_texture)
    picker.hs:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    picker.hs:SetZOrder(5)

    picker.hs_dark = Turbine.UI.Control()
    picker.hs_dark:SetParent(picker.hs)
    picker.hs_dark:SetPosition(0, 0)
    picker.hs_dark:SetSize(hs_size, hs_size)
    picker.hs_dark:SetMouseVisible(false)
    picker.hs_dark:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    picker.hs_dark:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    picker.hs_dark:SetZOrder(6)

    picker.value_base = Turbine.UI.Control()
    picker.value_base:SetParent(panel)
    picker.value_base:SetPosition(pad + hs_size + gap, pad)
    picker.value_base:SetSize(value_w, hs_size)
    picker.value_base:SetMouseVisible(true)
    picker.value_base:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    picker.value_base:SetZOrder(5)

    picker.value_grad = Turbine.UI.Control()
    picker.value_grad:SetParent(picker.value_base)
    picker.value_grad:SetPosition(0, 0)
    picker.value_grad:SetSize(value_w, hs_size)
    picker.value_grad:SetMouseVisible(false)
    picker.value_grad:SetBackground(image_set.value_texture)
    picker.value_grad:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    picker.value_grad:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    picker.value_grad:SetZOrder(6)

    picker._cursor_size = _scaled_int(self._scale, BASE_PICKER_CURSOR)
    picker.hs_cursor_v_outer = Turbine.UI.Control()
    picker.hs_cursor_v_outer:SetParent(picker.hs)
    picker.hs_cursor_v_outer:SetMouseVisible(false)
    picker.hs_cursor_v_outer:SetBackColor(Turbine.UI.Color.White)
    picker.hs_cursor_v_outer:SetSize(3, picker._cursor_size)
    picker.hs_cursor_v_outer:SetZOrder(20)

    picker.hs_cursor_h_outer = Turbine.UI.Control()
    picker.hs_cursor_h_outer:SetParent(picker.hs)
    picker.hs_cursor_h_outer:SetMouseVisible(false)
    picker.hs_cursor_h_outer:SetBackColor(Turbine.UI.Color.White)
    picker.hs_cursor_h_outer:SetSize(picker._cursor_size, 3)
    picker.hs_cursor_h_outer:SetZOrder(20)

    picker.hs_cursor_v = Turbine.UI.Control()
    picker.hs_cursor_v:SetParent(picker.hs)
    picker.hs_cursor_v:SetMouseVisible(false)
    picker.hs_cursor_v:SetBackColor(Turbine.UI.Color.Black)
    picker.hs_cursor_v:SetSize(1, picker._cursor_size)
    picker.hs_cursor_v:SetZOrder(21)

    picker.hs_cursor_h = Turbine.UI.Control()
    picker.hs_cursor_h:SetParent(picker.hs)
    picker.hs_cursor_h:SetMouseVisible(false)
    picker.hs_cursor_h:SetBackColor(Turbine.UI.Color.Black)
    picker.hs_cursor_h:SetSize(picker._cursor_size, 1)
    picker.hs_cursor_h:SetZOrder(21)

    picker.value_cursor_outer = Turbine.UI.Control()
    picker.value_cursor_outer:SetParent(picker.value_base)
    picker.value_cursor_outer:SetMouseVisible(false)
    picker.value_cursor_outer:SetBackColor(Turbine.UI.Color.White)
    picker.value_cursor_outer:SetPosition(0, 0)
    picker.value_cursor_outer:SetSize(value_w, 3)
    picker.value_cursor_outer:SetZOrder(20)

    picker.value_cursor = Turbine.UI.Control()
    picker.value_cursor:SetParent(picker.value_base)
    picker.value_cursor:SetMouseVisible(false)
    picker.value_cursor:SetBackColor(Turbine.UI.Color.Black)
    picker.value_cursor:SetPosition(0, 0)
    picker.value_cursor:SetSize(value_w, 1)
    picker.value_cursor:SetZOrder(21)

    picker.apply = LuiButton()
    picker.apply:SetParent(panel)
    picker.apply:set_scale(self._scale)
    picker.apply:set_text(TR["Apply"])
    picker.apply:SetZOrder(6)

    picker.cancel = LuiButton()
    picker.cancel:SetParent(panel)
    picker.cancel:set_scale(self._scale)
    picker.cancel:set_text(TR["Cancel"])
    picker.cancel:SetZOrder(6)

    local btn_w = math.floor((panel_w - (pad * 2) - btn_gap) / 2)
    local btn_y = pad + hs_size + gap
    picker.apply:SetPosition(panel_w - pad - (2 * btn_w) - btn_gap, btn_y)
    picker.apply:SetSize(btn_w, btn_h)
    picker.cancel:SetPosition(panel_w - pad - btn_w, btn_y)
    picker.cancel:SetSize(btn_w, btn_h)

    picker.apply.Click = function()
        local r, g, b = _hsv_to_rgb(self._picker_h, self._picker_s, self._picker_v)
        self:SetText(_color_to_hex(Turbine.UI.Color(r, g, b)))
        self:_close_picker(false)
    end
    picker.cancel.Click = function()
        self:_close_picker(true)
    end

    local function _picker_mouse_to_local(args, source, control)
        if args == nil or source == nil or control == nil then
            return nil
        end

        local sx, sy = source:PointToScreen(args.X or 0, args.Y or 0)
        local cx, cy = control:PointToScreen(0, 0)
        return {
            X = sx - cx,
            Y = sy - cy,
        }
    end

    local function _update_hs(args, source)
        self:_picker_set_hs_from_mouse(_picker_mouse_to_local(args, source, picker.hs), picker.hs)
        self:_picker_sync_ui(picker)
    end

    local function _update_v(args, source)
        self:_picker_set_v_from_mouse(_picker_mouse_to_local(args, source, picker.value_base), picker.value_base)
        self:_picker_sync_ui(picker)
    end

    picker.hs.MouseDown = function(sender, args)
        picker._drag_target = PICKER_DRAG_HS
        _update_hs(args, sender)
    end

    picker.hs.MouseMove = function(sender, args)
        if picker._drag_target == PICKER_DRAG_HS then
            _update_hs(args, sender)
        end
    end

    picker.hs.MouseUp = function(sender, args)
        _update_hs(args, sender)
        picker._drag_target = PICKER_DRAG_NONE
    end

    picker.value_base.MouseDown = function(sender, args)
        picker._drag_target = PICKER_DRAG_VALUE
        _update_v(args, sender)
    end

    picker.value_base.MouseMove = function(sender, args)
        if picker._drag_target == PICKER_DRAG_VALUE then
            _update_v(args, sender)
        end
    end

    picker.value_base.MouseUp = function(sender, args)
        _update_v(args, sender)
        picker._drag_target = PICKER_DRAG_NONE
    end

    overlay.MouseMove = function(sender, args)
        if picker._drag_target == PICKER_DRAG_HS then
            _update_hs(args, sender)
        elseif picker._drag_target == PICKER_DRAG_VALUE then
            _update_v(args, sender)
        end
    end

    overlay.MouseUp = function()
        picker._drag_target = PICKER_DRAG_NONE
    end

    overlay.MouseDown = function(sender, args)
        local x = args ~= nil and args.X or nil
        local y = args ~= nil and args.Y or nil
        if type(x) == "number" and type(y) == "number" and panel ~= nil then
            local px, py = panel:GetPosition()
            local pw, ph = panel:GetSize()
            if x >= px and x <= (px + pw) and y >= py and y <= (py + ph) then
                return
            end
        end
        self:_close_picker(true)
    end

    panel.MouseDown = function(sender, args)
        -- Swallow mouse so overlay doesn't cancel when clicking inside the picker.
    end

    self._picker_overlay = overlay
    self._picker_panel = panel
    self:_picker_sync_ui(picker)
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function LuiColorField:_close_picker(cancelled)
    if cancelled == true then
        self:update_swatch()
    end

    if self._picker_panel ~= nil then
        self._picker_panel:SetVisible(false)
        self._picker_panel = nil
    end
    if self._picker_overlay ~= nil then
        self._picker_overlay:SetVisible(false)
        self._picker_overlay = nil
    end
    self._picker_original = nil

    if LuiColorField._active == self then
        LuiColorField._active = nil
    end
end

function LuiColorField:_picker_set_hs_from_mouse(args, control)
    if args == nil or control == nil then
        return
    end

    local w = control:GetWidth()
    local h = control:GetHeight()
    if w <= 1 or h <= 1 then
        return
    end

    local x = _clamp(args.X or 0, 0, w - 1)
    local y = _clamp(args.Y or 0, 0, h - 1)
    local xn = x / (w - 1)
    local yn = y / (h - 1)

    self._picker_h = xn * 360
    self._picker_s = 1 - yn
end

function LuiColorField:_picker_set_v_from_mouse(args, control)
    if args == nil or control == nil then
        return
    end

    local h = control:GetHeight()
    if h <= 1 then
        return
    end

    local y = _clamp(args.Y or 0, 0, h - 1)
    local yn = y / (h - 1)
    self._picker_v = 1 - yn
end

function LuiColorField:_picker_sync_ui(picker)
    if picker == nil then
        return
    end

    local r1, g1, b1 = _hsv_to_rgb(self._picker_h, self._picker_s, 1)
    if picker.value_base ~= nil then
        picker.value_base:SetBackColor(Turbine.UI.Color(r1, g1, b1))
    end
    if picker.value_grad ~= nil then
        picker.value_grad:SetBackColor(Turbine.UI.Color(r1, g1, b1))
    end
    if picker.hs_dark ~= nil then
        picker.hs_dark:SetBackColor(Turbine.UI.Color(1 - self._picker_v, 0, 0, 0))
    end

    local r, g, b = _hsv_to_rgb(self._picker_h, self._picker_s, self._picker_v)
    if self.swatch ~= nil then
        self.swatch:SetBackColor(Turbine.UI.Color(r, g, b))
    end

    self:_picker_sync_cursors(picker)
end

function LuiColorField:_picker_sync_cursors(picker)
    if picker == nil then
        return
    end

    local hs = picker.hs
    if hs ~= nil and picker.hs_cursor_h_outer ~= nil then
        local w = hs:GetWidth()
        local h = hs:GetHeight()
        if w > 1 and h > 1 then
            local x = math.floor((_clamp(self._picker_h or 0, 0, 360) / 360) * (w - 1) + 0.5)
            local y = math.floor((1 - _clamp(self._picker_s or 0, 0, 1)) * (h - 1) + 0.5)
            if x < 0 then x = 0 end
            if x > (w - 1) then x = w - 1 end
            if y < 0 then y = 0 end
            if y > (h - 1) then y = h - 1 end

            local size = picker._cursor_size or 9
            local half = math.floor(size / 2)

            picker.hs_cursor_v_outer:SetPosition(x - 1, y - half)
            picker.hs_cursor_h_outer:SetPosition(x - half, y - 1)
            picker.hs_cursor_v:SetPosition(x, y - half)
            picker.hs_cursor_h:SetPosition(x - half, y)
        end
    end

    local vb = picker.value_base
    if vb ~= nil and picker.value_cursor_outer ~= nil then
        local h = vb:GetHeight()
        if h > 1 then
            local y = math.floor((1 - _clamp(self._picker_v or 0, 0, 1)) * (h - 1) + 0.5)
            if y < 0 then y = 0 end
            if y > (h - 1) then y = h - 1 end

            picker.value_cursor_outer:SetTop(y - 1)
            picker.value_cursor:SetTop(y)
        end
    end
end
