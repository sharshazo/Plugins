-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.UI"
import "Turbine.UI.Lotro"

local LUI = _G.LUI
local UI = LUI.UI
local Widgets = UI.Widgets

--[[
Widget style sheet:
Define LUI.UI.Style before creating LUI widgets to provide the developer/plugin
style layer. Saved user style overrides live in LUI.UI.UserStyle. If both are nil,
widgets use the complete DEFAULTS table below.

Example:
LUI.UI.Style = {
    CONTROL_BACKGROUND = Turbine.UI.Color(1, 0.15, 0.15, 0.15),
    CONTROL_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_BORDER = Turbine.UI.Color(1, 0.35, 0.40, 0.50),
    BORDER_WIDTH = 1.5,
    BORDER_WIDTH_THIN = 1,
    BORDER_WIDTH_LARGE = 2,
    DROPDOWN_ARROW = 0x41007e1a,
}

Widgets read values as UI.Widgets.Style.CONTROL_BORDER or Style["CONTROL_BORDER"].
Keys are exact uppercase names. Resolution order is:
DEFAULTS < LUI.UI.Style < LUI.UI.UserStyle.

If a layer omits a state-specific value such as CONTROL_BORDER_HOVER, lookup
tries that layer's fallback chain before moving to the next lower layer.
]]
local DEFAULTS = {
    BACKGROUND = Turbine.UI.Color(1, 0.08, 0.08, 0.08),
    FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),
    INFO_FOREGROUND = Turbine.UI.Color(1, 0.80, 0.86, 0.96),
    FOREGROUND_DISABLED = Turbine.UI.Color(0.55, 0.85, 0.85, 0.85),
    TEXT_OUTLINE = Turbine.UI.Color(1, 0, 0, 0),

    ALTERNATE_BACKGROUND = Turbine.UI.Color(1, 0.06, 0.06, 0.06),
    ALTERNATE_FOREGROUND = Turbine.UI.Color(0.88, 0.88, 0.88),
    SUBTLE_FOREGROUND = Turbine.UI.Color(1, 0.28, 0.28, 0.28),
    -- subtle interior lines (table grids, list separators); deliberately
    -- independent from CONTROL_BORDER so frames can pop without the
    -- interior turning flashy
    SEPARATOR = Turbine.UI.Color(1, 0.20, 0.20, 0.20),

    CONTROL_BACKGROUND = Turbine.UI.Color(1, 0.15, 0.15, 0.15),
    CONTROL_BACKGROUND_HOVER = Turbine.UI.Color(1, 0.18, 0.24, 0.34),
    CONTROL_BACKGROUND_PRESSED = Turbine.UI.Color(1, 0.10, 0.14, 0.20),
    CONTROL_BACKGROUND_ACTIVE = Turbine.UI.Color(1, 0.18, 0.30, 0.46),
    CONTROL_BACKGROUND_DISABLED = Turbine.UI.Color(1, 0.10, 0.10, 0.10),
    CONTROL_BACKGROUND_READONLY = Turbine.UI.Color(1, 0.20, 0.20, 0.20),
    CONTROL_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_HOVER = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_PRESSED = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_ACTIVE = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_DISABLED = Turbine.UI.Color(0.55, 0.85, 0.85, 0.85),
    CONTROL_BORDER = Turbine.UI.Color(1, 0.35, 0.40, 0.50),
    CONTROL_BORDER_HOVER = Turbine.UI.Color(1, 0.35, 0.40, 0.50),
    CONTROL_BORDER_ACTIVE = Turbine.UI.Color(1, 0.35, 0.40, 0.50),
    CONTROL_BORDER_DISABLED = Turbine.UI.Color(0.45, 0.62, 0.62, 0.62),
    BORDER_WIDTH = 1.5,
    BORDER_WIDTH_THIN = 1,
    BORDER_WIDTH_LARGE = 2,

    -- LuiTable interior. The frame and header underline follow the shared
    -- BORDER_WIDTH/CONTROL_BORDER like every widget; colors reuse the
    -- generic tokens (SEPARATOR grid, PANEL/ALTERNATE_BACKGROUND rows,
    -- CONTROL_BACKGROUND header). Only the grid widths and the
    -- row-striping toggle are table-specific: horizontal width 0 = no row
    -- lines (alternating rows carry the separation); single-background
    -- fans disable TABLE_ALTERNATE_ROWS and raise the horizontal width.
    TABLE_VERTICAL_BORDER_WIDTH = 2,
    TABLE_HORIZONTAL_BORDER_WIDTH = 0,
    TABLE_ALTERNATE_ROWS = true,

    CONTROL_FONT_NAME = "Verdana",
    CONTROL_FONT_SIZE = 12,
    WINDOW_TITLE_FONT_NAME = "Verdana",
    WINDOW_TITLE_FONT_SIZE = 12,
    FONT_H1_NAME = "BookAntiqua",
    FONT_H1_SIZE = 22,
    FONT_H2_NAME = "BookAntiquaBold",
    FONT_H2_SIZE = 18,
    CONTENT_LARGE_FONT_NAME = "Verdana",
    CONTENT_LARGE_FONT_SIZE = 14,
    CONTENT_MEDIUM_FONT_NAME = "Verdana",
    CONTENT_MEDIUM_FONT_SIZE = 12,
    CONTENT_SMALL_FONT_NAME = "Verdana",
    CONTENT_SMALL_FONT_SIZE = 10,

    ACCENT_BACKGROUND = Turbine.UI.Color(1, 0.68, 0.74, 0.88),
    ACCENT_BACKGROUND_DISABLED = Turbine.UI.Color(0.50, 0.68, 0.68, 0.68),
    ACCENT_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),

    SELECTION_BACKGROUND = Turbine.UI.Color(1, 0.18, 0.30, 0.46),
    SELECTION_BACKGROUND_HOVER = Turbine.UI.Color(1, 0.18, 0.24, 0.34),
    SELECTION_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),
    ALTERNATE_SELECTION_BACKGROUND = Turbine.UI.Color(1, 0.10, 0.14, 0.20),
    ALTERNATE_SELECTION_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),

    PANEL_BACKGROUND = Turbine.UI.Color(0.10, 0.10, 0.10),
    PANEL_INNER_BACKGROUND = Turbine.UI.Color(0.12, 0.12, 0.12),
    PLACEHOLDER_FOREGROUND = Turbine.UI.Color(1, 0.45, 0.45, 0.45),
    INVALID_BACKGROUND = Turbine.UI.Color(0.20, 0.20, 0.20),
    TRANSPARENT_BACKGROUND = Turbine.UI.Color(0, 0, 0, 0),

    MODAL_OVERLAY_BACKGROUND = Turbine.UI.Color(0.45, 0, 0, 0),
    MODAL_DIALOG_BACKGROUND = Turbine.UI.Color(0.95, 0.08, 0.08, 0.08),
    PREVIEW_OVERLAY_BACKGROUND = Turbine.UI.Color(0.14, 0, 0, 0),
    MOVE_OVERLAY_BACKGROUND = Turbine.UI.Color(0.35, 0, 0, 0),
    MOVE_OVERLAY_HEADER_BACKGROUND = Turbine.UI.Color(0.45, 0, 0, 0),
    MOVE_OVERLAY_FOREGROUND = Turbine.UI.Color(1, 1, 1),
    MOVE_GRID_BACKGROUND = Turbine.UI.Color(0.10, 0, 0, 0),
    MOVE_GRID_CENTER_LINE = Turbine.UI.Color(0.30, 1, 1, 1),
    MOVE_GRID_MAJOR_LINE = Turbine.UI.Color(0.16, 1, 1, 1),
    MOVE_GRID_MINOR_LINE = Turbine.UI.Color(0.08, 1, 1, 1),
    DRAG_GHOST_BACKGROUND = Turbine.UI.Color(0.92, 0.09, 0.09, 0.09),
    DRAG_GHOST_BORDER = Turbine.UI.Color(1.00, 0.35, 0.40, 0.50),
    DRAG_GHOST_FOREGROUND = Turbine.UI.Color(1.00, 1.00, 1.00, 1.00),
    DRAG_PREVIEW_FILL = Turbine.UI.Color(0.28, 1.00, 1.00, 1.00),
    DRAG_PREVIEW_EDGE = Turbine.UI.Color(0.95, 1.00, 1.00, 1.00),

    DROPDOWN_ARROW = 0x41007e1a,
    DROPDOWN_ARROW_HOVER = 0x41007e1b,
    DROPDOWN_ARROW_PRESSED = 0x41007e19,
    DROPDOWN_ARROW_DISABLED = 0x41007e1a,

    WINDOW_WORK_AREA = function()
        local display_w, display_h = Turbine.UI.Display.GetSize()
        return 0, 0, tonumber(display_w) or 0, tonumber(display_h) or 0
    end,
}

local FALLBACKS = {
    CONTROL_BACKGROUND_HOVER = "CONTROL_BACKGROUND",
    CONTROL_BACKGROUND_PRESSED = "CONTROL_BACKGROUND",
    CONTROL_BACKGROUND_ACTIVE = "SELECTION_BACKGROUND",
    CONTROL_BACKGROUND_DISABLED = "CONTROL_BACKGROUND",
    CONTROL_BACKGROUND_READONLY = "CONTROL_BACKGROUND_DISABLED",
    INFO_FOREGROUND = "ALTERNATE_FOREGROUND",
    CONTROL_FOREGROUND = "FOREGROUND",
    CONTROL_FOREGROUND_HOVER = "CONTROL_FOREGROUND",
    CONTROL_FOREGROUND_PRESSED = "CONTROL_FOREGROUND",
    CONTROL_FOREGROUND_ACTIVE = "CONTROL_FOREGROUND",
    CONTROL_FOREGROUND_DISABLED = "FOREGROUND_DISABLED",
    CONTROL_BORDER_HOVER = "CONTROL_BORDER",
    CONTROL_BORDER_ACTIVE = "CONTROL_BORDER",
    CONTROL_BORDER_DISABLED = "CONTROL_BORDER",
    ACCENT_BACKGROUND_DISABLED = "ACCENT_BACKGROUND",
    SELECTION_BACKGROUND_HOVER = "SELECTION_BACKGROUND",
    SELECTION_FOREGROUND = "FOREGROUND",
    ALTERNATE_FOREGROUND = "FOREGROUND",
    ALTERNATE_SELECTION_BACKGROUND = "SELECTION_BACKGROUND",
    ALTERNATE_SELECTION_FOREGROUND = "SELECTION_FOREGROUND",
    PANEL_BACKGROUND = "BACKGROUND",
    PANEL_INNER_BACKGROUND = "BACKGROUND",
    PLACEHOLDER_FOREGROUND = "ALTERNATE_FOREGROUND",
    MODAL_DIALOG_BACKGROUND = "PANEL_BACKGROUND",
    PREVIEW_OVERLAY_BACKGROUND = "MODAL_OVERLAY_BACKGROUND",
    MOVE_OVERLAY_HEADER_BACKGROUND = "MOVE_OVERLAY_BACKGROUND",
    MOVE_OVERLAY_FOREGROUND = "FOREGROUND",
    MOVE_GRID_BACKGROUND = "MOVE_OVERLAY_BACKGROUND",
    MOVE_GRID_CENTER_LINE = "MOVE_OVERLAY_FOREGROUND",
    MOVE_GRID_MAJOR_LINE = "MOVE_GRID_CENTER_LINE",
    MOVE_GRID_MINOR_LINE = "MOVE_GRID_MAJOR_LINE",
    DRAG_GHOST_BORDER = "CONTROL_BORDER",
    DRAG_GHOST_FOREGROUND = "FOREGROUND",
    DRAG_PREVIEW_FILL = "DRAG_GHOST_FOREGROUND",
    DRAG_PREVIEW_EDGE = "DRAG_GHOST_FOREGROUND",
    DROPDOWN_ARROW_HOVER = "DROPDOWN_ARROW",
    DROPDOWN_ARROW_PRESSED = "DROPDOWN_ARROW_HOVER",
    DROPDOWN_ARROW_DISABLED = "DROPDOWN_ARROW",
}

local function _style_override(style, key)
    local value = style[key]
    if value ~= nil then
        return value
    end

    local fallback = FALLBACKS[key]
    if fallback ~= nil then
        return _style_override(style, fallback)
    end

    return nil
end

local Style = setmetatable({}, {
    __index = function(_, key)
        if UI.UserStyle ~= nil then
            local value = _style_override(UI.UserStyle, key)
            if value ~= nil then
                return value
            end
        end

        if UI.Style ~= nil then
            local value = _style_override(UI.Style, key)
            if value ~= nil then
                return value
            end
        end

        return DEFAULTS[key]
    end,
})

Style.DEFAULTS = DEFAULTS
Style.FALLBACKS = FALLBACKS

function Style.apply_transparent_button(button)
    if button == nil then
        return
    end

    local transparent = Style.TRANSPARENT_BACKGROUND
    button:set_border_thickness(0)
    button:set_back_color(transparent)
    button:set_hover_back_color(transparent)
    button:set_pressed_back_color(transparent)
    button:set_active_back_color(transparent)
    button:set_disabled_back_color(transparent)
    button:set_border_color(transparent)
    button:set_hover_border_color(transparent)
    button:set_active_border_color(transparent)
    button:set_disabled_border_color(transparent)
end

function Style.apply_embedded_button(button)
    if button == nil then
        return
    end

    local transparent = Style.TRANSPARENT_BACKGROUND
    button:set_border_thickness(0)
    button:set_padding(0)
    button:set_back_color(transparent)
    button:set_hover_back_color(Style.CONTROL_BACKGROUND_HOVER)
    button:set_pressed_back_color(Style.CONTROL_BACKGROUND_PRESSED)
    button:set_active_back_color(Style.CONTROL_BACKGROUND_PRESSED)
    button:set_disabled_back_color(transparent)
    button:set_text_color(Style.CONTROL_FOREGROUND)
    button:set_hover_text_color(Style.CONTROL_FOREGROUND_HOVER)
    button:set_pressed_text_color(Style.CONTROL_FOREGROUND_PRESSED)
    button:set_active_text_color(Style.CONTROL_FOREGROUND_ACTIVE)
    button:set_disabled_text_color(Style.CONTROL_FOREGROUND_DISABLED)
end

function Style.apply_dropdown_arrow(button, width, position)
    if button == nil then
        return
    end

    button:set_icon(
        Style.DROPDOWN_ARROW,
        Style.DROPDOWN_ARROW_HOVER,
        Style.DROPDOWN_ARROW_PRESSED,
        Style.DROPDOWN_ARROW_DISABLED,
        width,
        nil,
        position
    )
end

Widgets.Style = Style
