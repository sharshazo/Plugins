-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local Image = Widgets.Image
local LuiLabel = Widgets.LuiLabel
local Style = Widgets.Style
local BASE_BUTTON_W = 89
local BASE_BUTTON_H = 21
local ICON_POSITION_LEFT = "left"
local ICON_POSITION_RIGHT = "right"

local function _scaled_size(scale, value)
    return value * scale
end

local function _scaled_int(scale, value)
    return math.floor(_scaled_size(scale, value) + 0.5)
end

local function _scaled_font(scale, name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(scale, size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(scale, size)))
    end
    return font
end

local function _nearest_matching_parity(value, match_value, max_value)
    local target = tonumber(value) or 0
    local candidate = math.floor(target + 0.5)
    local limit = tonumber(max_value)
    local parity = math.abs(math.floor(tonumber(match_value) or 0)) % 2

    if candidate < 0 then
        candidate = 0
    end
    if limit ~= nil then
        limit = math.floor(limit + 0.5)
        if limit < 0 then
            limit = 0
        end
        if candidate > limit then
            candidate = limit
        end
    end

    if candidate % 2 == parity then
        return candidate
    end

    local lower = candidate - 1
    local upper = candidate + 1
    if lower < 0 then
        lower = nil
    end
    if limit ~= nil and upper > limit then
        upper = nil
    end

    if lower == nil then
        return upper or candidate
    end
    if upper == nil then
        return lower
    end

    local lower_dist = math.abs(target - lower)
    local upper_dist = math.abs(upper - target)
    if upper_dist <= lower_dist then
        return upper
    end
    return lower
end

---@class LuiButton : Turbine.UI.Control
local LuiButton = class(Turbine.UI.Control)
Widgets.LuiButton = LuiButton

LuiButton.icon_position = {
    LEFT = ICON_POSITION_LEFT,
    RIGHT = ICON_POSITION_RIGHT,
}

local function _normalize_icon_position(position)
    if position == ICON_POSITION_LEFT or position == LuiButton.icon_position.LEFT then
        return ICON_POSITION_LEFT
    end
    return ICON_POSITION_RIGHT
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function LuiButton:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.Click = nil

    self._scale = 1
    self._uses_default_size = true
    self._uses_default_font = true

    self._enabled = true
    self._active = false
    self._hover = false
    self._pressed = false

    self._border_thickness = tonumber(Style.BORDER_WIDTH) or 1
    self._border_color = Style.CONTROL_BORDER
    self._border_hover_color = Style.CONTROL_BORDER_HOVER
    self._border_active_color = Style.CONTROL_BORDER_ACTIVE
    self._border_disabled_color = Style.CONTROL_BORDER_DISABLED

    self._back_normal = Style.CONTROL_BACKGROUND
    self._back_hover = Style.CONTROL_BACKGROUND_HOVER
    self._back_pressed = Style.CONTROL_BACKGROUND_PRESSED
    self._back_active = Style.CONTROL_BACKGROUND_ACTIVE
    self._back_disabled = Style.CONTROL_BACKGROUND_DISABLED

    self._text_normal = Style.CONTROL_FOREGROUND
    self._text_hover = Style.CONTROL_FOREGROUND_HOVER
    self._text_pressed = Style.CONTROL_FOREGROUND_PRESSED
    self._text_active = Style.CONTROL_FOREGROUND_ACTIVE
    self._text_disabled = Style.CONTROL_FOREGROUND_DISABLED

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_BUTTON_W), _scaled_int(self._scale, BASE_BUTTON_H))
    self:SetMouseVisible(true)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    local initial_border = math.max(0, _scaled_int(self._scale, self._border_thickness))

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self)
    self._inner:SetMouseVisible(false)
    self._inner:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._inner:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._inner:SetPosition(initial_border, initial_border)
    self._inner:SetSize(
        math.max(0, self:GetWidth() - (2 * initial_border)),
        math.max(0, self:GetHeight() - (2 * initial_border))
    )

    self._label = LuiLabel()
    self._label:SetParent(self._inner)
    self._label:SetMouseVisible(false)
    self._label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._label:SetSize(self._inner:GetSize())

    self._right_label = LuiLabel()
    self._right_label:SetParent(self._inner)
    self._right_label:SetMouseVisible(false)
    self._right_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._right_label:SetVisible(false)
    self._right_text = nil
    self._right_width = 0

    self._icon = Image()
    self._icon:SetParent(self._inner)
    self._icon:SetVisible(false)
    self._icon:SetZOrder(6)
    self._icon_normal = nil
    self._icon_hover = nil
    self._icon_active = nil
    self._icon_disabled = nil
    self._icon_width = 0
    self._icon_height = nil
    self._icon_position = ICON_POSITION_RIGHT
    self._icon_render_w = nil
    self._icon_render_h = nil
    self._icon_stretch_mode = nil
    self._padding = 0

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        if self._enabled ~= true then return end
        self._hover = true
        self:_update_visual_state()
    end

    self.MouseLeave = function()
        self._hover = false
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseDown = function(_, args)
        if self._enabled ~= true then return end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then return end
        self._pressed = true
        self:_update_visual_state()
    end

    self.MouseUp = function(_, args)
        if self._enabled ~= true then return end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then return end
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseClick = function(_, args)
        if self._enabled ~= true then return end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then return end
        if type(self.Click) == "function" then
            self:Click()
        end
    end

    self:_apply_default_font()
    self:_update_visual_state()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function LuiButton:set_border_thickness(px)
    if type(px) ~= "number" then
        px = tonumber(px)
    end
    if px == nil then
        return
    end
    if px < 0 then px = 0 end
    self._border_thickness = px
    self:_layout()
end

function LuiButton:set_border_color(color)
    if color == nil then return end
    self._border_color = color
    self:_update_visual_state()
end

function LuiButton:set_hover_border_color(color)
    if color == nil then return end
    self._border_hover_color = color
    self:_update_visual_state()
end

function LuiButton:set_active_border_color(color)
    if color == nil then return end
    self._border_active_color = color
    self:_update_visual_state()
end

function LuiButton:set_disabled_border_color(color)
    if color == nil then return end
    self._border_disabled_color = color
    self:_update_visual_state()
end

function LuiButton:set_padding(px)
    if type(px) ~= "number" then
        px = tonumber(px)
    end
    if px == nil then
        return
    end
    if px < 0 then px = 0 end
    self._padding = px
    self:_layout()
end

function LuiButton:set_right_text(text, width)
    if type(width) ~= "number" then
        width = tonumber(width)
    end
    if width == nil then
        width = 0
    end
    if width < 0 then width = 0 end

    self._right_text = text
    self._right_width = math.floor(width + 0.5)
    self._icon_width = 0
    self:_layout()
end

function LuiButton:set_icon(normal, hover, active, disabled, width, height, position)
    if type(width) ~= "number" then
        width = tonumber(width)
    end
    if width == nil then
        width = 0
    end
    if width < 0 then width = 0 end

    self._icon_normal = normal
    self._icon_hover = hover
    self._icon_active = active
    self._icon_disabled = disabled
    self._icon_width = math.floor(width + 0.5)
    if type(height) ~= "number" then
        height = tonumber(height)
    end
    if height ~= nil and height < 0 then
        height = 0
    end
    if height ~= nil then
        self._icon_height = math.floor(height + 0.5)
    else
        self._icon_height = nil
    end
    self._icon_position = _normalize_icon_position(position or self._icon_position)
    self._right_width = 0
    self:_layout()
end

function LuiButton:set_icon_position(position)
    self._icon_position = _normalize_icon_position(position)
    self:_layout()
end

function LuiButton:set_icon_stretch_mode(mode)
    self._icon_stretch_mode = mode
    if self._icon ~= nil and mode ~= nil then
        self._icon:SetStretchMode(mode)
    end
end

function LuiButton:set_active(active)
    self._active = active == true
    self:_update_visual_state()
end

function LuiButton:is_active()
    return self._active == true
end

function LuiButton:set_enabled(enabled)
    self._enabled = enabled == true
    if self._enabled ~= true then
        self._hover = false
        self._pressed = false
    end
    Turbine.UI.Control.SetEnabled(self, self._enabled)
    self:_update_visual_state()
end

function LuiButton:set_text(text)
    if self._label ~= nil then
        self._label:SetText(text or "")
    end
    self:_layout()
end

function LuiButton:GetText()
    if self._label == nil then return "" end
    return self._label:GetText()
end

function LuiButton:set_font(font)
    if font == nil then return end
    self._uses_default_font = false
    if self._label ~= nil then
        self._label:SetFont(font)
    end
    if self._right_label ~= nil then
        self._right_label:SetFont(font)
    end
end

function LuiButton:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale

    if self._uses_default_font == true then
        self:_apply_default_font()
    end

    if self._uses_default_size == true then
        Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_BUTTON_W), _scaled_int(self._scale, BASE_BUTTON_H))
    end

    self:_layout()
end

function LuiButton:set_text_alignment(alignment)
    if self._label ~= nil and alignment ~= nil then
        self._label:SetTextAlignment(alignment)
    end
end

function LuiButton:set_back_color(color)
    if color ~= nil then
        self._back_normal = color; self:_update_visual_state()
    end
end

function LuiButton:set_hover_back_color(color)
    if color ~= nil then
        self._back_hover = color; self:_update_visual_state()
    end
end

function LuiButton:set_pressed_back_color(color)
    if color ~= nil then
        self._back_pressed = color; self:_update_visual_state()
    end
end

function LuiButton:set_active_back_color(color)
    if color ~= nil then
        self._back_active = color; self:_update_visual_state()
    end
end

function LuiButton:set_disabled_back_color(color)
    if color ~= nil then
        self._back_disabled = color; self:_update_visual_state()
    end
end

function LuiButton:set_text_color(color)
    if color ~= nil then
        self._text_normal = color; self:_update_visual_state()
    end
end

function LuiButton:set_hover_text_color(color)
    if color ~= nil then
        self._text_hover = color; self:_update_visual_state()
    end
end

function LuiButton:set_pressed_text_color(color)
    if color ~= nil then
        self._text_pressed = color; self:_update_visual_state()
    end
end

function LuiButton:set_active_text_color(color)
    if color ~= nil then
        self._text_active = color; self:_update_visual_state()
    end
end

function LuiButton:set_disabled_text_color(color)
    if color ~= nil then
        self._text_disabled = color; self:_update_visual_state()
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function LuiButton:_current_back_color()
    if self._enabled ~= true then return self._back_disabled end
    if self._pressed == true then return self._back_pressed end
    if self._active == true then return self._back_active end
    if self._hover == true then return self._back_hover end
    return self._back_normal
end

function LuiButton:_current_border_color()
    if self._enabled ~= true then return self._border_disabled_color end
    if self._pressed == true or self._active == true then return self._border_active_color end
    if self._hover == true then return self._border_hover_color end
    return self._border_color
end

function LuiButton:_current_text_color()
    if self._enabled ~= true then return self._text_disabled end
    if self._pressed == true then return self._text_pressed end
    if self._active == true then return self._text_active end
    if self._hover == true then return self._text_hover end
    return self._text_normal
end

function LuiButton:_current_icon()
    if self._enabled ~= true then
        return self._icon_disabled or self._icon_normal
    end
    if self._pressed == true or self._active == true then
        return self._icon_active or self._icon_hover or self._icon_normal
    end
    if self._hover == true then
        return self._icon_hover or self._icon_normal
    end
    return self._icon_normal
end

function LuiButton:_apply_default_font()
    local font = _scaled_font(self._scale, Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE)
    if self._label ~= nil then
        self._label:SetFont(font)
    end
    if self._right_label ~= nil then
        self._right_label:SetFont(font)
    end
end

function LuiButton:_update_visual_state()
    local border_px = math.max(0, _scaled_int(self._scale, self._border_thickness or tonumber(Style.BORDER_WIDTH) or 1))
    if border_px > 0 then
        self:SetBackColor(self:_current_border_color())
    else
        self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    end
    if self._inner ~= nil then
        self._inner:SetBackColor(self:_current_back_color())
    end
    if self._label ~= nil then
        self._label:SetForeColor(self:_current_text_color())
    end
    if self._right_label ~= nil then
        self._right_label:SetForeColor(self:_current_text_color())
    end
    if self._icon ~= nil and self._icon:IsVisible() then
        self._icon:set_icon(self:_current_icon())
        if self._icon_stretch_mode ~= nil then
            self._icon:SetStretchMode(self._icon_stretch_mode)
        end
        if self._icon_render_w ~= nil then
            self._icon:set_size(self._icon_render_w, self._icon_render_h)
        end
    end
end

function LuiButton:_layout()
    local w, h = self:GetSize()
    local t = math.max(0, _scaled_int(self._scale, self._border_thickness or tonumber(Style.BORDER_WIDTH) or 1))
    if t < 0 then t = 0 end

    if self._inner ~= nil then
        self._inner:SetPosition(t, t)
        self._inner:SetSize(math.max(0, w - (2 * t)), math.max(0, h - (2 * t)))
    end

    local inner_w = self._inner ~= nil and self._inner:GetWidth() or w
    local inner_h = self._inner ~= nil and self._inner:GetHeight() or h
    local padding = math.max(0, _scaled_int(self._scale, self._padding or 0))
    local content_x = padding
    local content_y = padding
    local content_w = inner_w - (2 * padding)
    local content_h = inner_h - (2 * padding)
    if content_w < 0 then content_w = 0 end
    if content_h < 0 then content_h = 0 end

    local right_text_w = _scaled_int(self._scale, self._right_width or 0)
    if right_text_w < 0 then right_text_w = 0 end
    if right_text_w > content_w then right_text_w = content_w end

    local use_icon = (self._icon_width or 0) > 0 and self._icon_normal ~= nil
    local icon_slot_w = _scaled_int(self._scale, self._icon_width or 0)
    if icon_slot_w < 0 then icon_slot_w = 0 end
    if icon_slot_w > content_w then icon_slot_w = content_w end
    local icon_slot_h = nil
    if self._icon_height ~= nil then
        icon_slot_h = _scaled_int(self._scale, self._icon_height)
        if icon_slot_h < 0 then icon_slot_h = 0 end
        if icon_slot_h > content_h then icon_slot_h = content_h end
    end

    local label_text = self._label ~= nil and tostring(self._label:GetText() or "") or ""
    local has_text = label_text ~= ""

    if self._right_label ~= nil then
        if right_text_w > 0 and use_icon ~= true then
            self._right_label:SetVisible(true)
            self._right_label:SetText(tostring(self._right_text or ""))
            self._right_label:SetPosition(content_x + content_w - right_text_w, content_y)
            self._right_label:SetSize(right_text_w, content_h)
        else
            self._right_label:SetVisible(false)
        end
    end

    if self._icon ~= nil then
        if use_icon == true then
            self._icon:SetVisible(true)
            local current_icon = self:_current_icon()
            local icon_area_x = content_x
            local icon_area_w = content_w
            local icon_area_h = content_h
            local render_w = 0
            local render_h = 0

            if has_text == true then
                icon_area_w = icon_slot_w
                if self._icon_position == ICON_POSITION_RIGHT then
                    icon_area_x = content_x + content_w - icon_slot_w
                end
            end

            if current_icon ~= nil then
                self._icon:set_icon(current_icon)
                if self._icon_stretch_mode ~= nil then
                    self._icon:SetStretchMode(self._icon_stretch_mode)
                end
            end

            if icon_slot_h ~= nil then
                local max_render_w = icon_area_w
                local max_render_h = icon_area_h
                local requested_w = _nearest_matching_parity(
                    _scaled_size(self._scale, self._icon_width or 0),
                    icon_area_w,
                    max_render_w
                )
                local requested_h = _nearest_matching_parity(
                    _scaled_size(self._scale, self._icon_height),
                    icon_area_h,
                    max_render_h
                )
                render_w, render_h = self._icon:set_size(requested_w, requested_h)
            else
                local max_render_side = math.min(icon_area_w, icon_area_h)
                local requested_side = _nearest_matching_parity(
                    _scaled_size(self._scale, self._icon_width or 0),
                    has_text ~= true and max_render_side or icon_area_h,
                    max_render_side
                )
                render_w, render_h = self._icon:set_size(requested_side)
            end
            self._icon_render_w = render_w
            self._icon_render_h = render_h

            local py = content_y + math.floor((icon_area_h - render_h) / 2)
            local px = icon_area_x + math.floor((icon_area_w - render_w) / 2)

            self._icon:SetPosition(px, py)
            self._icon:set_icon(self:_current_icon())
            if self._icon_render_w ~= nil then
                self._icon:set_size(self._icon_render_w, self._icon_render_h)
            end
            if self._icon_stretch_mode ~= nil then
                self._icon:SetStretchMode(self._icon_stretch_mode)
            end
        else
            self._icon_render_w = nil
            self._icon_render_h = nil
            self._icon:SetVisible(false)
        end
    end

    if self._label ~= nil then
        local label_x = content_x
        local label_w = content_w

        if use_icon == true and has_text == true then
            if self._icon_position == ICON_POSITION_LEFT then
                label_x = content_x + icon_slot_w
                label_w = content_w - icon_slot_w
            else
                label_w = content_w - icon_slot_w
            end
        elseif right_text_w > 0 then
            label_w = content_w - right_text_w
        end

        if label_w < 0 then label_w = 0 end
        self._label:SetPosition(label_x, content_y)
        self._label:SetSize(label_w, content_h)
    end

    self:_update_visual_state()
end

function LuiButton:SetSize(w, h)
    self._uses_default_size = false
    Turbine.UI.Control.SetSize(self, w, h)
end
