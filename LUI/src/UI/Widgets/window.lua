-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.assets"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.menu"
import "LUI.src.UI.Widgets.style"
import "LUI.src.UI.Widgets.base_window"
import "LUI.src.Utils.font"

local UI = _G.LUI.UI
local Widgets = UI.Widgets
local AssetIds = UI.Assets
local LuiBaseWindow = Widgets.LuiBaseWindow
local LuiButton = Widgets.LuiButton
local Image = Widgets.Image
local LuiLabel = Widgets.LuiLabel
local LuiMenu = Widgets.LuiMenu
local LuiMenuBar = Widgets.LuiMenuBar
local Style = Widgets.Style

local BASE_DEFAULT_W = 420
local BASE_DEFAULT_H = 280
local BASE_MIN_W = 160
local BASE_MIN_H = 90
local BASE_TITLE_BAR_H = 20
local BASE_GAP = 4
local BASE_MARGIN = 8
local BASE_ICON = 20
local BASE_TITLE_ACTION_ICON = 10
local BASE_RESIZE_EDGE = 4
local BASE_RESIZE_CORNER = 8
local BASE_RESIZE_HANDLE = 32
local BASE_MAXIMIZE_DRAG_THRESHOLD = 64

local RESIZE_MODE_NONE = 0
local RESIZE_MODE_HORIZONTAL = 1
local RESIZE_MODE_VERTICAL = 2
local RESIZE_MODE_BOTH = RESIZE_MODE_HORIZONTAL + RESIZE_MODE_VERTICAL
local TILE_NONE = "none"
local TILE_MAXIMIZED = "maximized"

local WindowConstants = Widgets.WindowConstants or {}
Widgets.WindowConstants = WindowConstants
WindowConstants.RESIZE_NONE = RESIZE_MODE_NONE
WindowConstants.RESIZE_HORIZONTAL = RESIZE_MODE_HORIZONTAL
WindowConstants.RESIZE_VERTICAL = RESIZE_MODE_VERTICAL
WindowConstants.RESIZE_BOTH = RESIZE_MODE_BOTH

local RESIZE_LEFT = 1
local RESIZE_RIGHT = 2
local RESIZE_TOP = 4
local RESIZE_BOTTOM = 8

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _scaled_font(scale, name, size)
    return FONT_TO_LOTRO(name, size * scale)
end

local function _clamp(value, min_value, max_value)
    if max_value < min_value then
        return min_value
    end
    return math.max(min_value, math.min(max_value, value))
end

local function _has_resize_dir(mask, dir)
    return math.floor((mask or 0) / dir) % 2 == 1
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _attach_drag_handlers(control, owner)
    control.MouseDown = function(_, args)
        owner:_start_drag(args)
    end
    control.MouseMove = function(_, args)
        owner:_drag_to(args)
    end
    control.MouseUp = function()
        owner:_stop_drag()
    end
end

local function _make_drag_region(parent, owner)
    local control = Turbine.UI.Control()
    control:SetParent(parent)
    control:SetMouseVisible(true)
    _set_blend(control)
    _attach_drag_handlers(control, owner)

    return control
end

local function _make_resize_region(parent, owner, mask)
    local control = Turbine.UI.Control()
    control:SetParent(parent)
    control:SetMouseVisible(true)
    control:SetZOrder(50)
    control._resize_mask = mask
    _set_blend(control)

    control.MouseEnter = function(sender, args)
        owner:_show_resize_handle(sender, args)
    end
    control.MouseLeave = function()
        if owner._resizing ~= true then
            owner:_hide_resize_handle()
        end
    end
    control.MouseDown = function(sender, args)
        owner:_start_resize(sender, args)
    end
    control.MouseMove = function(sender, args)
        if owner._resizing == true then
            owner:_resize_to(sender, args)
        else
            owner:_move_resize_handle(sender, args)
        end
    end
    control.MouseUp = function()
        owner:_stop_resize()
    end

    return control
end

local function _make_resize_handle(host)
    local image = Image()
    image:SetParent(host)
    image:SetMouseVisible(false)
    image:SetPosition(0, 0)
    image:SetVisible(false)
    return image
end

---@class LuiWindow : LuiBaseWindow
local LuiWindow = class(LuiBaseWindow)
Widgets.LuiWindow = LuiWindow
LuiWindow.RESIZE_NONE = RESIZE_MODE_NONE
LuiWindow.RESIZE_HORIZONTAL = RESIZE_MODE_HORIZONTAL
LuiWindow.RESIZE_VERTICAL = RESIZE_MODE_VERTICAL
LuiWindow.RESIZE_BOTH = RESIZE_MODE_BOTH
LuiWindow.TILE_NONE = TILE_NONE
LuiWindow.TILE_MAXIMIZED = TILE_MAXIMIZED

function LuiWindow:Constructor(opts)
    if type(opts) ~= "table" then
        opts = {}
    end
    if opts.hideable == nil then
        opts.hideable = true
    end
    LuiBaseWindow.Constructor(self, opts)

    self._scale = 1
    self._icon_asset = nil
    self._icon_size = BASE_ICON
    self._central_widget = nil
    self._margin_left = BASE_MARGIN
    self._margin_top = BASE_MARGIN
    self._margin_right = BASE_MARGIN
    self._margin_bottom = BASE_MARGIN
    self._title_bar_divider_visible = true
    self._close_handler = nil
    self._draggable = true
    self._dragging = false
    self._drag_start_screen_x = 0
    self._drag_start_screen_y = 0
    self._drag_start_window_x = 0
    self._drag_start_window_y = 0
    self._resizable = true
    self._resize_mode = RESIZE_MODE_BOTH
    self._maximize_enabled = true
    self._tile_mode = TILE_NONE
    self._restore_window_x = nil
    self._restore_window_y = nil
    self._restore_window_w = nil
    self._restore_window_h = nil
    self._capturing_normal_for_maximize = false
    self._minimum_width = nil
    self._minimum_height = nil
    self._resizing = false
    self._resize_mask = 0
    self._resize_start_screen_x = 0
    self._resize_start_screen_y = 0
    self._resize_start_window_x = 0
    self._resize_start_window_y = 0
    self._resize_start_window_w = 0
    self._resize_start_window_h = 0
    self._resize_handle_region = nil
    self._active_resize_handle = nil
    self._resize_handle_screen_x = nil
    self._resize_handle_screen_y = nil

    self:SetVisible(false)
    self:SetMouseVisible(true)
    _set_blend(self)

    self._frame = Turbine.UI.Control()
    self._frame:SetParent(self)
    self._frame:SetMouseVisible(false)
    _set_blend(self._frame)

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self._frame)
    self._inner:SetMouseVisible(false)
    _set_blend(self._inner)

    self._title_bar = Turbine.UI.Control()
    self._title_bar:SetParent(self._inner)
    self._title_bar:SetMouseVisible(false)
    _set_blend(self._title_bar)

    self._title_drag_left = _make_drag_region(self._title_bar, self)
    self._title_drag_body = _make_drag_region(self._title_bar, self)

    self._icon = Image()
    self._icon:SetParent(self._title_bar)
    self._icon:SetMouseVisible(false)
    self._icon:SetVisible(false)

    self._menu_bar = LuiMenuBar()
    self._menu_bar:SetParent(self._title_bar)
    self._menu_bar:SetZOrder(10)
    self._menu_bar.on_change = function()
        self:_layout()
    end
    _attach_drag_handlers(self._menu_bar, self)

    self._title_label = LuiLabel()
    self._title_label:SetParent(self._title_bar)
    self._title_label:SetMouseVisible(false)
    self._title_label:SetSelectable(false)
    self._title_label:SetMultiline(false)
    self._title_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._title_label:SetVisible(false)
    self._title_label:SetZOrder(1)

    self._maximize_button = LuiButton()
    self._maximize_button:SetParent(self._title_bar)
    self._maximize_button:SetZOrder(10)
    self._maximize_button:set_text("")
    self._maximize_button.Click = function()
        self:toggle_maximized()
    end

    self._close_button = LuiButton()
    self._close_button:SetParent(self._title_bar)
    self._close_button:SetZOrder(10)
    self._close_button:set_text("")
    self._close_button.Click = function()
        self:request_close()
    end

    self._divider = Turbine.UI.Control()
    self._divider:SetParent(self._inner)
    self._divider:SetMouseVisible(false)
    _set_blend(self._divider)

    self._resize_regions = {
        top = _make_resize_region(self, self, RESIZE_TOP),
        bottom = _make_resize_region(self, self, RESIZE_BOTTOM),
        left = _make_resize_region(self, self, RESIZE_LEFT),
        right = _make_resize_region(self, self, RESIZE_RIGHT),
        top_left = _make_resize_region(
            self,
            self,
            RESIZE_TOP + RESIZE_LEFT
        ),
        bottom_right = _make_resize_region(
            self,
            self,
            RESIZE_BOTTOM + RESIZE_RIGHT
        ),
        bottom_left = _make_resize_region(
            self,
            self,
            RESIZE_BOTTOM + RESIZE_LEFT
        ),
    }

    self._resize_handle_window = Turbine.UI.Window()
    self:apply_native_scaling(self._resize_handle_window)
    self._resize_handle_window:SetMouseVisible(false)
    self._resize_handle_window:SetZOrder(10000)
    self._resize_handle_window:SetVisible(false)
    _set_blend(self._resize_handle_window)
    self._resize_handle_window:SetBackColor(Style.TRANSPARENT_BACKGROUND)

    self._resize_handles = {
        horizontal = _make_resize_handle(self._resize_handle_window),
        vertical = _make_resize_handle(self._resize_handle_window),
        diagonal_tl_br = _make_resize_handle(self._resize_handle_window),
        diagonal_tr_bl = _make_resize_handle(self._resize_handle_window),
    }

    self.SizeChanged = function()
        self:_layout()
    end

    self:SetWantsKeyEvents(true)
    self.KeyDown = function(_, args)
        if args.Action == Turbine.UI.Lotro.Action.Escape
            and _G.LUI.Settings.State.settings.global.close_windows_with_esc == true then
            self:request_close()
        end
    end

    LuiWindow.apply_settings(self)
    self:SetSize(_scaled_int(self._scale, BASE_DEFAULT_W), _scaled_int(self._scale, BASE_DEFAULT_H))
end

function LuiWindow:set_title(text)
    local value = text ~= nil and tostring(text) or ""
    self._title_label:SetText(value)
    self._title_label:SetVisible(string.len(value) > 0)
    self:_layout()
end

function LuiWindow:set_icon(icon, size)
    self._icon_asset = icon
    if size ~= nil then
        self:set_icon_size(size)
        return
    end
    self._icon:SetVisible(icon ~= nil)
    self:_layout()
end

function LuiWindow:set_icon_size(size)
    if type(size) ~= "number" then
        size = tonumber(size)
    end
    if size == nil or size <= 0 then
        size = BASE_ICON
    end
    self._icon_size = size
    self:_layout()
end

function LuiWindow:clear_icon()
    self:set_icon(nil)
end

function LuiWindow:get_menu_bar()
    return self._menu_bar
end

function LuiWindow:set_central_widget(widget)
    if self._central_widget == widget then
        self:_layout()
        return
    end

    if self._central_widget ~= nil and self._central_widget.SetParent ~= nil then
        self._central_widget:SetParent(nil)
    end

    self._central_widget = widget
    if widget ~= nil then
        widget:SetParent(self._inner)
    end
    self:_layout()
end

function LuiWindow:central_widget()
    return self._central_widget
end

function LuiWindow:set_margin(left, top, right, bottom)
    local margin_left = tonumber(left)
    if margin_left == nil then
        margin_left = BASE_MARGIN
    end

    local margin_top = tonumber(top)
    local margin_right = tonumber(right)
    local margin_bottom = tonumber(bottom)

    if margin_top == nil then margin_top = margin_left end
    if margin_right == nil then margin_right = margin_left end
    if margin_bottom == nil then margin_bottom = margin_top end

    self._margin_left = math.max(0, margin_left)
    self._margin_top = math.max(0, margin_top)
    self._margin_right = math.max(0, margin_right)
    self._margin_bottom = math.max(0, margin_bottom)
    self:_layout()
end

function LuiWindow:set_title_bar_divider_visible(visible)
    self._title_bar_divider_visible = visible == true
    self:_layout()
end

function LuiWindow:set_close_handler(handler)
    self._close_handler = handler
end

function LuiWindow:set_draggable(enabled)
    self._draggable = enabled == true
    if self._draggable ~= true then
        self:_stop_drag()
    end
end

function LuiWindow:_normalize_resize_mode(mode)
    if mode == true then
        return RESIZE_MODE_BOTH
    end
    if mode == false or mode == nil then
        return RESIZE_MODE_NONE
    end
    if mode == RESIZE_MODE_HORIZONTAL or mode == "horizontal" then
        return RESIZE_MODE_HORIZONTAL
    end
    if mode == RESIZE_MODE_VERTICAL or mode == "vertical" then
        return RESIZE_MODE_VERTICAL
    end
    if mode == RESIZE_MODE_BOTH or mode == "both" then
        return RESIZE_MODE_BOTH
    end
    if mode == RESIZE_MODE_NONE or mode == "none" then
        return RESIZE_MODE_NONE
    end
    return RESIZE_MODE_NONE
end

function LuiWindow:set_resizable(mode)
    local resize_mode = self:_normalize_resize_mode(mode)
    local changed = resize_mode ~= self._resize_mode

    self._resize_mode = resize_mode
    self._resizable = resize_mode ~= RESIZE_MODE_NONE

    if changed == true or self._resizable ~= true then
        self:_stop_resize()
        self:_hide_resize_handle()
    end
    self:_layout_resize_regions()
end

function LuiWindow:_resize_mode_allows_mask(mask)
    local resize_mode = self._resize_mode or RESIZE_MODE_BOTH
    if resize_mode == RESIZE_MODE_BOTH then
        return true
    end
    if resize_mode == RESIZE_MODE_NONE then
        return false
    end

    local has_horizontal = _has_resize_dir(mask, RESIZE_LEFT) or _has_resize_dir(mask, RESIZE_RIGHT)
    local has_vertical = _has_resize_dir(mask, RESIZE_TOP) or _has_resize_dir(mask, RESIZE_BOTTOM)
    if has_horizontal == true and has_vertical == true then
        return false
    end
    if resize_mode == RESIZE_MODE_HORIZONTAL then
        return has_horizontal == true
    end
    if resize_mode == RESIZE_MODE_VERTICAL then
        return has_vertical == true
    end
    return false
end

function LuiWindow:_resize_region_enabled(region)
    if region == nil then
        return false
    end
    return self:_resize_mode_allows_mask(region._resize_mask or 0)
end

function LuiWindow:_normalize_tile_mode(tile)
    if tile == TILE_MAXIMIZED then
        return TILE_MAXIMIZED
    end
    return TILE_NONE
end

function LuiWindow:_tile_mode_from_geometry(geometry)
    if type(geometry) ~= "table" then
        return TILE_NONE
    end
    return self:_normalize_tile_mode(geometry.tile)
end

function LuiWindow:_set_tile_mode(tile)
    self._tile_mode = self:_normalize_tile_mode(tile)
end

function LuiWindow:get_tile()
    return self:_normalize_tile_mode(self._tile_mode)
end

function LuiWindow:is_tiled()
    return self:get_tile() ~= TILE_NONE
end

function LuiWindow:enable_maximize(enabled)
    self._maximize_enabled = enabled ~= false
    if self._maximize_enabled ~= true and self:is_maximized() == true then
        self:restore()
    end
    self:_sync_maximize_button_icon()
    self:_layout()
end

function LuiWindow:is_maximized()
    return self:get_tile() == TILE_MAXIMIZED
end

function LuiWindow:toggle_maximized()
    if self:is_maximized() == true then
        self:restore()
    else
        self:maximize()
    end
end

function LuiWindow:maximize(skip_capture)
    if self._maximize_enabled ~= true then
        return
    end

    if self:is_maximized() ~= true then
        if skip_capture ~= true then
            self:_capture_current_normal_geometry()
        else
            self:_remember_restore_geometry()
        end
    end

    self:_stop_resize()
    self:_set_tile_mode(TILE_MAXIMIZED)
    self:_sync_maximize_button_icon()
    self:_apply_maximized_bounds()
end

function LuiWindow:restore()
    if self:is_maximized() ~= true then
        return
    end

    self:_set_tile_mode(TILE_NONE)
    self:_sync_maximize_button_icon()
    self:_restore_normal_bounds()
end

function LuiWindow:get_geometry()
    local tile = self:get_tile()
    local geometry = {
        tile = tile,
    }

    if tile ~= TILE_NONE then
        geometry.left = self._restore_window_x or self:GetLeft()
        geometry.top = self._restore_window_y or self:GetTop()
        geometry.width = self._restore_window_w or self:GetWidth()
        geometry.height = self._restore_window_h or self:GetHeight()
        return geometry
    end

    local left, top = self:GetPosition()
    local width, height = self:GetSize()
    geometry.left = left
    geometry.top = top
    geometry.width = width
    geometry.height = height
    return geometry
end

function LuiWindow:set_geometry(geometry)
    if type(geometry) ~= "table" then
        self:_sync_maximize_button_icon()
        return
    end

    local left, top = self:GetPosition()
    local width, height = self:GetSize()
    local next_left = tonumber(geometry.left) or left
    local next_top = tonumber(geometry.top) or top
    local next_width = tonumber(geometry.width) or width
    local next_height = tonumber(geometry.height) or height
    local tile = self:_tile_mode_from_geometry(geometry)

    next_width, next_height = self:_fit_size_to_screen(next_width, next_height)
    self:_set_tile_mode(TILE_NONE)

    if width ~= next_width or height ~= next_height then
        self:SetSize(next_width, next_height)
    end

    local actual_w, actual_h = self:GetSize()
    next_left, next_top = self:_clamp_position_to_screen(next_left, next_top, actual_w, actual_h)
    local current_left, current_top = self:GetPosition()
    if current_left ~= next_left or current_top ~= next_top then
        self:SetPosition(next_left, next_top)
    end

    self._restore_window_x = next_left
    self._restore_window_y = next_top
    self._restore_window_w = actual_w
    self._restore_window_h = actual_h

    if tile == TILE_MAXIMIZED and self._maximize_enabled == true then
        self:maximize(true)
    else
        self:_sync_maximize_button_icon()
        self:_layout_resize_regions()
    end
end

function LuiWindow:set_minimum_size(width, height)
    self._minimum_width = tonumber(width)
    self._minimum_height = tonumber(height)
    if self:is_maximized() == true then
        self:_apply_maximized_bounds()
    else
        self:_enforce_minimum_size()
    end
end

function LuiWindow:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end

    self._scale = scale
    self:_apply_style()
end

function LuiWindow:apply_settings(scale)
    self:apply_native_scaling()
    if self._resize_handle_window ~= nil then
        self:apply_native_scaling(self._resize_handle_window)
    end
    if scale ~= nil then
        self:set_scale(scale)
        return
    end
    self:_apply_style()
end

function LuiWindow:_style_title_button(button)
    if button == nil then
        return
    end

    button:set_scale(self._scale)
    button:set_border_thickness(0)
    button:set_padding(0)
    button:set_back_color(Style.TRANSPARENT_BACKGROUND)
    button:set_hover_back_color(Style.ACCENT_BACKGROUND_DISABLED)
    button:set_pressed_back_color(Style.TRANSPARENT_BACKGROUND)
    button:set_active_back_color(Style.TRANSPARENT_BACKGROUND)
    button:set_disabled_back_color(Style.TRANSPARENT_BACKGROUND)
    button:set_border_color(Style.CONTROL_BORDER)
    button:set_hover_border_color(Style.CONTROL_BORDER_HOVER)
    button:set_active_border_color(Style.CONTROL_BORDER_ACTIVE)
    button:set_disabled_border_color(Style.CONTROL_BORDER_DISABLED)
end

function LuiWindow:_apply_style()
    self:SetBackColor(Style.CONTROL_BORDER)
    self._frame:SetBackColor(Style.CONTROL_BORDER)
    self._inner:SetBackColor(Style.BACKGROUND)
    self._title_bar:SetBackColor(Style.CONTROL_BACKGROUND)
    self._divider:SetBackColor(Style.CONTROL_BORDER)
    self._menu_bar:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self._title_label:SetForeColor(Style.FOREGROUND)
    self._title_label:SetFont(_scaled_font(self._scale, Style.WINDOW_TITLE_FONT_NAME, Style.WINDOW_TITLE_FONT_SIZE))
    self._menu_bar:set_scale(self._scale)
    self._menu_bar:set_font(_scaled_font(self._scale, Style.WINDOW_TITLE_FONT_NAME, Style.WINDOW_TITLE_FONT_SIZE))
    self:_sync_resize_handle_icons()

    self:_style_title_button(self._maximize_button)
    self:_style_title_button(self._close_button)
    self:_sync_maximize_button_icon()
    self._close_button:set_icon(
        AssetIds.x,
        AssetIds.x_hover,
        AssetIds.x_hover,
        AssetIds.x,
        BASE_TITLE_ACTION_ICON,
        BASE_TITLE_ACTION_ICON,
        LuiButton.icon_position.RIGHT
    )

    self:_layout()
    if self:is_maximized() == true then
        self:_apply_maximized_bounds()
    end
end

function LuiWindow:show()
    self:SetVisible(true)
    if self:is_maximized() == true then
        self:_apply_maximized_bounds()
    else
        self:_bound_to_screen()
    end
    self:bring_to_front()
end

function LuiWindow:request_close()
    if type(self._close_handler) == "function" then
        self._close_handler(self)
        return
    end
    self:hide()
end

function LuiWindow:SetVisible(visible)
    if visible ~= true and LuiMenu._active_root ~= nil then
        LuiMenu._active_root:close()
    end
    LuiBaseWindow.SetVisible(self, visible)
end

function LuiWindow:hide()
    self:_hide_resize_handle()
    self:SetVisible(false)
end

function LuiWindow:toggle()
    if self:IsVisible() == true then
        self:hide()
    else
        self:show()
    end
end

function LuiWindow:bring_to_front()
    if self:IsVisible() == true then
        self:Activate()
    end
end

function LuiWindow:_border()
    return math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH) or 1))
end

function LuiWindow:_divider_h()
    if self._title_bar_divider_visible ~= true then
        return 0
    end
    return 1
end

function LuiWindow:_sync_maximize_button_icon()
    if self._maximize_button == nil then
        return
    end

    local visible = self._maximize_enabled == true
    self._maximize_button:SetVisible(visible)
    if visible ~= true then
        return
    end

    local normal = AssetIds.window_maximize
    local hover = AssetIds.window_maximize_hover
    if self:is_maximized() == true then
        normal = AssetIds.window_restore
        hover = AssetIds.window_restore_hover
    end

    self._maximize_button:set_icon(
        normal,
        hover,
        hover,
        normal,
        BASE_TITLE_ACTION_ICON,
        BASE_TITLE_ACTION_ICON,
        LuiButton.icon_position.RIGHT
    )
end

function LuiWindow:_start_drag(args)
    if self._draggable ~= true then
        return
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return
    end

    self._dragging = true
    self._drag_start_screen_x, self._drag_start_screen_y = self._title_bar:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    self._drag_start_window_x, self._drag_start_window_y = self:GetPosition()
    self:bring_to_front()
end

function LuiWindow:_drag_to(args)
    if self._dragging ~= true then
        return
    end

    local screen_x, screen_y = self._title_bar:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    local dx = screen_x - self._drag_start_screen_x
    local dy = screen_y - self._drag_start_screen_y

    if self:is_maximized() == true then
        local threshold = _scaled_int(self._scale, BASE_MAXIMIZE_DRAG_THRESHOLD)
        if math.max(math.abs(dx), math.abs(dy)) < threshold then
            return
        end

        self:_restore_for_drag(screen_x, screen_y)
        return
    end

    local width, height = self:GetSize()
    local x, y = self:_clamp_position_to_screen(
        self._drag_start_window_x + dx,
        self._drag_start_window_y + dy,
        width,
        height
    )
    self:SetPosition(x, y)
end

function LuiWindow:_stop_drag()
    self._dragging = false
end

function LuiWindow:_minimum_size()
    local min_w = self._minimum_width or _scaled_int(self._scale, BASE_MIN_W)
    local min_h = self._minimum_height or _scaled_int(self._scale, BASE_MIN_H)
    return math.max(1, min_w), math.max(1, min_h)
end

function LuiWindow:_enforce_minimum_size()
    local width, height = self:GetSize()
    local min_w, min_h = self:_minimum_size()
    self:SetSize(math.max(width, min_w), math.max(height, min_h))
    self:_bound_to_screen()
end

function LuiWindow:_display_size()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    return tonumber(display_w) or 0, tonumber(display_h) or 0
end

function LuiWindow:_work_area()
    local work_area = Style.WINDOW_WORK_AREA
    if type(work_area) == "function" then
        local x, y, width, height = work_area(self)
        return tonumber(x) or 0,
            tonumber(y) or 0,
            math.max(0, tonumber(width) or 0),
            math.max(0, tonumber(height) or 0)
    end

    local display_w, display_h = self:_display_size()
    return 0, 0, display_w, display_h
end

function LuiWindow:_fit_size_to_screen(width, height)
    local _, _, work_w, work_h = self:_work_area()
    local min_w, min_h = self:_minimum_size()
    width = tonumber(width) or 0
    height = tonumber(height) or 0

    if work_w > 0 then
        width = math.min(width, math.max(min_w, work_w))
    end
    if work_h > 0 then
        height = math.min(height, math.max(min_h, work_h))
    end

    return math.max(min_w, width), math.max(min_h, height)
end

function LuiWindow:_clamp_position_to_screen(x, y, width, height)
    local work_x, work_y, work_w, work_h = self:_work_area()
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    width = tonumber(width) or 0
    height = tonumber(height) or 0

    if work_w > 0 then
        x = _clamp(x, work_x, math.max(work_x, work_x + work_w - width))
    end
    if work_h > 0 then
        y = _clamp(y, work_y, math.max(work_y, work_y + work_h - height))
    end

    return x, y
end

function LuiWindow:_bound_to_screen()
    local width, height = self:GetSize()
    local bounded_w, bounded_h = self:_fit_size_to_screen(width, height)
    if bounded_w ~= width or bounded_h ~= height then
        self:SetSize(bounded_w, bounded_h)
    end

    local x, y = self:GetPosition()
    local bounded_x, bounded_y = self:_clamp_position_to_screen(x, y, bounded_w, bounded_h)
    if bounded_x ~= x or bounded_y ~= y then
        self:SetPosition(bounded_x, bounded_y)
    end
end

function LuiWindow:_remember_restore_geometry()
    if self:is_maximized() == true then
        return
    end

    self._restore_window_x, self._restore_window_y = self:GetPosition()
    self._restore_window_w, self._restore_window_h = self:GetSize()
end

function LuiWindow:_capture_current_normal_geometry()
    self:_remember_restore_geometry()

    if self._capturing_normal_for_maximize == true then
        return
    end
    if type(self.capture_geometry) ~= "function" then
        return
    end

    self._capturing_normal_for_maximize = true
    local ok, err = pcall(function()
        self:capture_geometry()
    end)
    self._capturing_normal_for_maximize = false
    if ok ~= true then
        error(err)
    end
end

function LuiWindow:_apply_maximized_bounds()
    if self._maximize_enabled ~= true or self:is_maximized() ~= true then
        return
    end

    local x, y, width, height = self:_work_area()
    local min_w, min_h = self:_minimum_size()
    width = math.max(min_w, width)
    height = math.max(min_h, height)

    self:SetPosition(x, y)
    self:SetSize(width, height)
    self:_hide_resize_handle()
    self:_layout_resize_regions()
end

function LuiWindow:_restore_normal_bounds()
    local width = self._restore_window_w or self:GetWidth()
    local height = self._restore_window_h or self:GetHeight()
    width, height = self:_fit_size_to_screen(width, height)

    self:SetSize(width, height)

    local actual_w, actual_h = self:GetSize()
    local x = self._restore_window_x or self:GetLeft()
    local y = self._restore_window_y or self:GetTop()
    x, y = self:_clamp_position_to_screen(x, y, actual_w, actual_h)
    self:SetPosition(x, y)
    self:_layout_resize_regions()
end

function LuiWindow:_restore_for_drag(screen_x, screen_y)
    local old_x, old_y = self:GetPosition()
    local old_w, old_h = self:GetSize()
    local restore_w = self._restore_window_w or old_w
    local restore_h = self._restore_window_h or old_h
    restore_w, restore_h = self:_fit_size_to_screen(restore_w, restore_h)

    local offset_x = self._drag_start_screen_x - old_x
    local offset_y = self._drag_start_screen_y - old_y
    if old_w > 0 then
        offset_x = math.floor((offset_x / old_w) * restore_w)
    end
    offset_y = math.min(offset_y, _scaled_int(self._scale, BASE_TITLE_BAR_H))
    offset_x = _clamp(offset_x, 0, math.max(0, restore_w - 1))
    offset_y = _clamp(offset_y, 0, math.max(0, restore_h - 1))

    self:_set_tile_mode(TILE_NONE)
    self:_sync_maximize_button_icon()
    self:SetSize(restore_w, restore_h)

    local actual_w, actual_h = self:GetSize()
    local x, y = self:_clamp_position_to_screen(screen_x - offset_x, screen_y - offset_y, actual_w, actual_h)
    self:SetPosition(x, y)
    self:_layout_resize_regions()

    self._drag_start_screen_x = screen_x
    self._drag_start_screen_y = screen_y
    self._drag_start_window_x = x
    self._drag_start_window_y = y
end

function LuiWindow:_clamp_resize_to_screen(x, y, width, height)
    local work_x, work_y, work_w, work_h = self:_work_area()
    local min_w, min_h = self:_minimum_size()
    local mask = self._resize_mask or 0

    if work_w > 0 then
        if _has_resize_dir(mask, RESIZE_LEFT) and x < work_x then
            width = width + (x - work_x)
            x = work_x
        elseif _has_resize_dir(mask, RESIZE_RIGHT) and x + width > work_x + work_w then
            width = work_x + work_w - x
        end
    end

    if work_h > 0 then
        if _has_resize_dir(mask, RESIZE_TOP) and y < work_y then
            height = height + (y - work_y)
            y = work_y
        elseif _has_resize_dir(mask, RESIZE_BOTTOM) and y + height > work_y + work_h then
            height = work_y + work_h - y
        end
    end

    if width < min_w then
        if _has_resize_dir(mask, RESIZE_LEFT) then
            x = x + width - min_w
        end
        width = min_w
    end
    if height < min_h then
        if _has_resize_dir(mask, RESIZE_TOP) then
            y = y + height - min_h
        end
        height = min_h
    end

    x, y = self:_clamp_position_to_screen(x, y, width, height)
    return x, y, width, height
end

function LuiWindow:_start_resize(region, args)
    if self._resizable ~= true then
        return
    end
    if self:_resize_region_enabled(region) ~= true then
        return
    end
    if self:is_maximized() == true then
        return
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return
    end

    self:_stop_drag()
    self._resizing = true
    self._resize_mask = region._resize_mask or 0
    self._resize_start_screen_x, self._resize_start_screen_y = region:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    self._resize_start_window_x, self._resize_start_window_y = self:GetPosition()
    self._resize_start_window_w, self._resize_start_window_h = self:GetSize()
    self:_show_resize_handle(region, args)
    self:bring_to_front()
end

function LuiWindow:_calculate_resize_bounds(region, args)
    local screen_x, screen_y = region:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    local dx = screen_x - self._resize_start_screen_x
    local dy = screen_y - self._resize_start_screen_y
    local min_w, min_h = self:_minimum_size()
    local x = self._resize_start_window_x
    local y = self._resize_start_window_y
    local w = self._resize_start_window_w
    local h = self._resize_start_window_h

    if _has_resize_dir(self._resize_mask, RESIZE_LEFT) then
        w = self._resize_start_window_w - dx
        if w < min_w then
            w = min_w
            x = self._resize_start_window_x + self._resize_start_window_w - min_w
        else
            x = self._resize_start_window_x + dx
        end
    elseif _has_resize_dir(self._resize_mask, RESIZE_RIGHT) then
        w = math.max(min_w, self._resize_start_window_w + dx)
    end

    if _has_resize_dir(self._resize_mask, RESIZE_TOP) then
        h = self._resize_start_window_h - dy
        if h < min_h then
            h = min_h
            y = self._resize_start_window_y + self._resize_start_window_h - min_h
        else
            y = self._resize_start_window_y + dy
        end
    elseif _has_resize_dir(self._resize_mask, RESIZE_BOTTOM) then
        h = math.max(min_h, self._resize_start_window_h + dy)
    end

    x, y, w, h = self:_clamp_resize_to_screen(x, y, w, h)
    return x, y, w, h
end

function LuiWindow:_apply_resize_bounds(x, y, width, height, region, args)
    self:SetPosition(x, y)
    self:SetSize(width, height)
end

function LuiWindow:_resize_to(region, args)
    if self._resizing ~= true then
        return
    end

    self:_remember_resize_handle_cursor(region, args)

    local x, y, w, h = self:_calculate_resize_bounds(region, args)
    self:_apply_resize_bounds(x, y, w, h, region, args)
    self:_layout_resize_handle(region)
end

function LuiWindow:_stop_resize()
    self._resizing = false
    self._resize_mask = 0
    self:_hide_resize_handle()
end

function LuiWindow:_show_resize_handle(region, args)
    if self._resizable ~= true or self._resize_handles == nil then
        return
    end
    if self:_resize_region_enabled(region) ~= true then
        self:_hide_resize_handle()
        return
    end

    self._resize_handle_region = region
    self:_remember_resize_handle_cursor(region, args)
    local handle = self:_resize_handle_for_region(region)
    if handle == nil then
        return
    end

    if self._active_resize_handle ~= nil and self._active_resize_handle ~= handle then
        self._active_resize_handle:SetVisible(false)
    end
    self._active_resize_handle = handle
    self:_layout_resize_handle(region)
    handle:SetVisible(true)
    if self._resize_handle_window ~= nil then
        self._resize_handle_window:SetVisible(true)
        self._resize_handle_window:SetZOrder(10000)
    end
end

function LuiWindow:_move_resize_handle(region, args)
    if self._resizable ~= true or self._active_resize_handle == nil then
        return
    end
    if self:_resize_region_enabled(region) ~= true then
        self:_hide_resize_handle()
        return
    end

    self._resize_handle_region = region
    self:_remember_resize_handle_cursor(region, args)
    self:_layout_resize_handle(region)
end

function LuiWindow:_hide_resize_handle()
    self._resize_handle_region = nil
    self._resize_handle_screen_x = nil
    self._resize_handle_screen_y = nil
    if self._active_resize_handle ~= nil then
        self._active_resize_handle:SetVisible(false)
        self._active_resize_handle = nil
    end
    if self._resize_handle_window ~= nil then
        self._resize_handle_window:SetVisible(false)
    end
end

function LuiWindow:_sync_resize_handle_icons()
    if self._resize_handles == nil then
        return
    end

    local handle = _scaled_int(self._scale, BASE_RESIZE_HANDLE)
    self._resize_handles.horizontal:set_icon(AssetIds.resize_horizontal, handle, handle)
    self._resize_handles.vertical:set_icon(AssetIds.resize_vertical, handle, handle)
    self._resize_handles.diagonal_tl_br:set_icon(AssetIds.resize_diagonal_tl_br, handle, handle)
    self._resize_handles.diagonal_tr_bl:set_icon(AssetIds.resize_diagonal_tr_bl, handle, handle)
    for _, resize_handle in pairs(self._resize_handles) do
        resize_handle:SetPosition(0, 0)
        resize_handle:SetVisible(resize_handle == self._active_resize_handle)
    end
    if self._resize_handle_window ~= nil then
        self._resize_handle_window:SetSize(handle, handle)
        self._resize_handle_window:SetVisible(self._active_resize_handle ~= nil)
    end
end

function LuiWindow:_resize_handle_for_region(region)
    if region == nil or self._resize_handles == nil then
        return nil
    end

    if region._resize_mask == RESIZE_BOTTOM + RESIZE_LEFT then
        return self._resize_handles.diagonal_tr_bl
    elseif region._resize_mask == RESIZE_LEFT or region._resize_mask == RESIZE_RIGHT then
        return self._resize_handles.horizontal
    elseif region._resize_mask == RESIZE_TOP or region._resize_mask == RESIZE_BOTTOM then
        return self._resize_handles.vertical
    end
    return self._resize_handles.diagonal_tl_br
end

function LuiWindow:_remember_resize_handle_cursor(region, args)
    if region == nil or args == nil then
        return
    end

    self._resize_handle_screen_x, self._resize_handle_screen_y = region:PointToScreen(
        args.X or 0,
        args.Y or 0
    )
end

function LuiWindow:_layout()
    if self._inner == nil then
        return
    end

    local width, height = self:GetSize()
    local border = self:_border()
    local title_h = _scaled_int(self._scale, BASE_TITLE_BAR_H)
    local gap = _scaled_int(self._scale, BASE_GAP)
    local icon_size = _scaled_int(self._scale, self._icon_size or BASE_ICON)
    local chrome_margin = math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH_THIN) or 1))
    local chrome_square = math.max(0, title_h - (chrome_margin * 2))
    local divider_h = self:_divider_h()

    self._frame:SetPosition(0, 0)
    self._frame:SetSize(width, height)

    local inner_w = math.max(0, width - (border * 2))
    local inner_h = math.max(0, height - (border * 2))
    self._inner:SetPosition(border, border)
    self._inner:SetSize(inner_w, inner_h)

    self._title_bar:SetPosition(0, 0)
    self._title_bar:SetSize(inner_w, math.min(title_h, inner_h))

    local close_x = math.max(0, inner_w - chrome_margin - chrome_square)
    local close_y = chrome_margin
    self._close_button:SetPosition(close_x, close_y)
    self._close_button:SetSize(chrome_square, chrome_square)
    local title_actions_x = close_x
    if self._maximize_button ~= nil then
        local maximize_visible = self._maximize_enabled == true
        local maximize_x = math.max(0, close_x - chrome_margin - chrome_square)
        self._maximize_button:SetPosition(maximize_x, close_y)
        self._maximize_button:SetSize(chrome_square, chrome_square)
        self._maximize_button:SetVisible(maximize_visible)
        if maximize_visible == true then
            title_actions_x = maximize_x
        end
    end

    local left_used = chrome_margin
    if self._icon_asset ~= nil and icon_size > 0 and chrome_square > 0 then
        local title_icon_size = math.min(icon_size, chrome_square)
        self._icon:set_icon(self._icon_asset, title_icon_size)
        local actual_w, actual_h = self._icon:get_size()
        actual_w = actual_w or title_icon_size
        actual_h = actual_h or title_icon_size
        local icon_x = chrome_margin + math.floor((chrome_square - actual_w) / 2)
        local icon_y = chrome_margin + math.floor((chrome_square - actual_h) / 2)
        self._icon:SetPosition(icon_x, icon_y)
        self._icon:SetVisible(true)
        left_used = chrome_margin + chrome_square + gap
    else
        self._icon:SetVisible(false)
    end

    local menu_w = math.min(self._menu_bar:preferred_width(), math.max(0, title_actions_x - gap - left_used))
    local menu_x = left_used
    self._menu_bar:SetPosition(menu_x, 0)
    self._menu_bar:SetSize(menu_w, title_h)
    self._menu_bar:SetZOrder(20)
    self._menu_bar:SetVisible(menu_w > 0)
    if menu_w > 0 then
        left_used = menu_x + menu_w + gap
    end

    self._title_drag_left:SetPosition(0, 0)
    self._title_drag_left:SetSize(math.max(0, menu_x), title_h)

    local drag_body_x = menu_x + menu_w + gap
    local drag_body_w = math.max(0, title_actions_x - gap - drag_body_x)
    self._title_drag_body:SetPosition(drag_body_x, 0)
    self._title_drag_body:SetSize(drag_body_w, title_h)

    self._title_label:SetPosition(0, 0)
    self._title_label:SetSize(inner_w, title_h)

    local divider_y = title_h
    self._divider:SetPosition(0, divider_y)
    self._divider:SetSize(inner_w, divider_h)
    self._divider:SetVisible(divider_h > 0)

    local content_y = title_h + divider_h
    local content_h = math.max(0, inner_h - content_y)
    local central = self._central_widget
    if central ~= nil then
        local margin_l = _scaled_int(self._scale, self._margin_left)
        local margin_t = _scaled_int(self._scale, self._margin_top)
        local margin_r = _scaled_int(self._scale, self._margin_right)
        local margin_b = _scaled_int(self._scale, self._margin_bottom)
        local central_w = math.max(0, inner_w - margin_l - margin_r)
        local central_h = math.max(0, content_h - margin_t - margin_b)
        central:SetPosition(margin_l, content_y + margin_t)
        central:SetSize(central_w, central_h)
    end

    self:_layout_resize_regions()
end

function LuiWindow:_layout_resize_regions()
    if self._resize_regions == nil then
        return
    end

    local width, height = self:GetSize()
    local edge = self:_border() + _scaled_int(self._scale, BASE_RESIZE_EDGE)
    local corner = math.max(edge, _scaled_int(self._scale, BASE_RESIZE_CORNER))
    local title_h = _scaled_int(self._scale, BASE_TITLE_BAR_H)
    local right_edge_top = math.min(height, title_h + edge)
    local edge_visible = self._resizable == true and self:is_maximized() ~= true
    if edge_visible ~= true then
        self:_hide_resize_handle()
    end

    local top_w = math.max(0, width - (corner * 2))
    local side_h = math.max(0, height - right_edge_top - corner)
    local vertical_h = math.max(0, height - (corner * 2))

    self._resize_regions.top:SetPosition(corner, 0)
    self._resize_regions.top:SetSize(top_w, edge)

    self._resize_regions.bottom:SetPosition(corner, math.max(0, height - edge))
    self._resize_regions.bottom:SetSize(top_w, edge)

    self._resize_regions.left:SetPosition(0, corner)
    self._resize_regions.left:SetSize(edge, vertical_h)

    self._resize_regions.right:SetPosition(math.max(0, width - edge), right_edge_top)
    self._resize_regions.right:SetSize(edge, side_h)

    self._resize_regions.top_left:SetPosition(0, 0)
    self._resize_regions.top_left:SetSize(corner, corner)

    self._resize_regions.bottom_right:SetPosition(math.max(0, width - corner), math.max(0, height - corner))
    self._resize_regions.bottom_right:SetSize(corner, corner)

    self._resize_regions.bottom_left:SetPosition(0, math.max(0, height - corner))
    self._resize_regions.bottom_left:SetSize(corner, corner)

    for _, region in pairs(self._resize_regions) do
        region:SetVisible(edge_visible == true and self:_resize_region_enabled(region) == true)
    end

    if self._resize_handle_region ~= nil and self:_resize_region_enabled(self._resize_handle_region) ~= true then
        self:_hide_resize_handle()
    end

    self:_layout_resize_handle(self._resize_handle_region)
end

function LuiWindow:_layout_resize_handle(region)
    local handle_control = self._active_resize_handle
    if handle_control == nil or region == nil or self._resize_handle_window == nil then
        return
    end

    local width, height = self:GetSize()
    local handle = _scaled_int(self._scale, BASE_RESIZE_HANDLE)
    local mask = region._resize_mask or 0
    local has_left = _has_resize_dir(mask, RESIZE_LEFT)
    local has_right = _has_resize_dir(mask, RESIZE_RIGHT)
    local has_top = _has_resize_dir(mask, RESIZE_TOP)
    local has_bottom = _has_resize_dir(mask, RESIZE_BOTTOM)
    local has_horizontal = has_left or has_right
    local has_vertical = has_top or has_bottom
    local x = math.floor((width - handle) / 2)
    local y = math.floor((height - handle) / 2)
    local cursor_x = nil
    local cursor_y = nil

    if self._resize_handle_screen_x ~= nil and self._resize_handle_screen_y ~= nil then
        local window_x, window_y = self:PointToScreen(0, 0)
        cursor_x = self._resize_handle_screen_x - window_x
        cursor_y = self._resize_handle_screen_y - window_y
    end

    if has_left then
        x = 0
    elseif has_right then
        x = width - handle
    elseif cursor_x ~= nil and has_vertical then
        x = math.floor(cursor_x - (handle / 2))
    end

    if has_top then
        y = 0
    elseif has_bottom then
        y = height - handle
    elseif cursor_y ~= nil and has_horizontal then
        y = math.floor(cursor_y - (handle / 2))
    end

    x = math.max(0, math.min(math.max(0, width - handle), x))
    y = math.max(0, math.min(math.max(0, height - handle), y))

    local screen_x, screen_y = self:PointToScreen(math.max(0, x), math.max(0, y))
    self._resize_handle_window:SetPosition(screen_x, screen_y)
    self._resize_handle_window:SetSize(handle, handle)
    handle_control:SetPosition(0, 0)
    handle_control:SetSize(handle, handle)
end

UI.Widgets.LuiWindow = LuiWindow
