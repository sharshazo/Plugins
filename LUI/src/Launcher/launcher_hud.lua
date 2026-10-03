-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Launcher = _G.LUI.Features.Launcher
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.shortcuts"
import "LUI.src.UI.Widgets.hud"

local Shortcuts = UI.Shortcuts
local Style = UI.Widgets.Style

-- Icono de mano (LOTRO_Quest_Assistant/Resources/Book/hand_icon.tga, mismo
-- archivo que usa nuestro propio addon) en vez del logo original de LUI --
-- pedido explicito del usuario ("estoy hablando del icono flotante que
-- tiene lui"). Este boton NO tiene Quickslot (ver logo_button.Click abajo:
-- solo llama self:toggle_expanded(), una funcion Lua interna de LUI), asi
-- que no sufre el problema de resaltado nativo que afecta al boton "mano"
-- de QuestSyncLauncher.lua. _apply_button_icon() ya reescala cualquier
-- icono a icon_size en cada layout (ver mas abajo), asi que no importa que
-- el archivo original fuera 128x128 y este sea 64x64.
local LOGO_BUTTON_ICON = "LUI/assets/hand_button.tga"
local ORIENTATION_HORIZONTAL = "horizontal"
local ORIENTATION_VERTICAL = "vertical"
local DIRECTION_UP = "up"
local DIRECTION_DOWN = "down"
local DIRECTION_LEFT = "left"
local DIRECTION_RIGHT = "right"
local UPDATE_INTERVAL = 0.20
local BUTTON_BORDER = 1
local BUTTON_PADDING = 2

local function _set_alpha_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _launcher_settings()
    return State.settings.launcher
end

local function _button_footprint(count, icon_size, spacing)
    return (count * icon_size) + ((count - 1) * spacing)
end

local function _button_icon_size(icon_size)
    local inner = icon_size - ((BUTTON_BORDER + BUTTON_PADDING) * 2)
    if inner < 1 then
        inner = 1
    end
    return inner
end

---@class LauncherMenu : UI.Widgets.LuiHUD
local LauncherMenu = class(UI.Widgets.LuiHUD)
Launcher.LauncherMenu = LauncherMenu

function LauncherMenu:Constructor()
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "launcher",
        title = TR["LUI Menu"],
        mouse_visible = true,
    })

    self.expanded = false
    self.shortcut_buttons = {}
    self.last_update_at = 0

    _set_alpha_blend(self)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self:SetMouseVisible(true)
    self:SetWantsUpdates(true)

    self.logo_button = self:_new_button(LOGO_BUTTON_ICON)
    self.logo_button.Click = function()
        self:toggle_expanded()
    end

    self.on_move_end = function()
        self:_layout_buttons()
    end

    self:apply_settings()
    self:SetVisible(true)
end

function LauncherMenu:destroy()
    if self:is_move_mode() == true then
        self:set_move_mode(false)
    end
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self.logo_button:SetParent(nil)
    self:_clear_shortcut_buttons()
    self:unregister_hideable()
    self:SetParent(nil)
end

function LauncherMenu:apply_settings()
    self:apply_native_scaling()
    self:_rebuild_shortcut_buttons()
    self:_resize_window()
    self:apply_hud_position()
    self:_layout_buttons()
    self:_refresh_shortcut_availability()
end

function LauncherMenu:set_move_mode(enabled)
    local want = enabled == true
    if want == self:is_move_mode() then
        return
    end

    self:_resize_window()
    UI.Widgets.LuiHUD.set_move_mode(self, want)

    self:_layout_buttons()
end

function LauncherMenu:toggle_expanded()
    self:set_expanded(self.expanded ~= true)
end

function LauncherMenu:set_expanded(expanded)
    local want = expanded == true
    if self.expanded == want then
        return
    end

    self.expanded = want
    self:_layout_buttons()
end

function LauncherMenu:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < UPDATE_INTERVAL then
        return
    end
    self.last_update_at = now
    self:_refresh_shortcut_availability()
end

function LauncherMenu:_new_button(icon)
    local button = UI.Widgets.LuiButton()
    button:SetParent(self)
    button:set_text("")
    button:set_border_thickness(BUTTON_BORDER)
    button:set_padding(BUTTON_PADDING)
    button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleCenter)
    button:set_back_color(Style.CONTROL_BACKGROUND)
    button:set_hover_back_color(Style.CONTROL_BACKGROUND_HOVER)
    button:set_pressed_back_color(Style.CONTROL_BACKGROUND_PRESSED)
    button:set_border_color(Style.CONTROL_BORDER)
    button:set_hover_border_color(Style.CONTROL_BORDER_HOVER)
    button:set_disabled_border_color(Style.CONTROL_BORDER_DISABLED)
    button:SetZOrder(10)
    button._launcher_icon = icon
    return button
end

function LauncherMenu:_clear_shortcut_buttons()
    for i = 1, #self.shortcut_buttons do
        self.shortcut_buttons[i]:SetVisible(false)
        self.shortcut_buttons[i]:SetParent(nil)
    end
    self.shortcut_buttons = {}
end

function LauncherMenu:_rebuild_shortcut_buttons()
    self:_clear_shortcut_buttons()

    local configured = _launcher_settings().buttons
    for i = 1, #configured do
        local shortcut_key = configured[i]
        if Shortcuts.is_valid(shortcut_key) ~= true then
            error("Unknown launcher shortcut: " .. tostring(shortcut_key))
        end

        local icon = Shortcuts.get_icon(shortcut_key)
        if icon == nil then
            error("Missing launcher shortcut icon: " .. tostring(shortcut_key))
        end

        local button = self:_new_button(icon)
        button.shortcut_key = shortcut_key
        button.Click = function()
            Shortcuts.activate(shortcut_key)
            if _launcher_settings().collapse_after_click == true then
                self:set_expanded(false)
            end
            self:_refresh_shortcut_availability()
        end

        self.shortcut_buttons[#self.shortcut_buttons + 1] = button
    end
end

function LauncherMenu:_menu_footprint()
    local s = _launcher_settings()
    if s.icon_size < 1 then
        error("Invalid launcher icon size: " .. tostring(s.icon_size))
    end
    if s.spacing < 0 then
        error("Invalid launcher spacing: " .. tostring(s.spacing))
    end

    local count = #self.shortcut_buttons + 1
    local length = _button_footprint(count, s.icon_size, s.spacing)

    if s.orientation == ORIENTATION_HORIZONTAL then
        return length, s.icon_size
    end

    if s.orientation == ORIENTATION_VERTICAL then
        return s.icon_size, length
    end

    error("Invalid launcher orientation: " .. tostring(s.orientation))
end

function LauncherMenu:_resize_window()
    local menu_w, menu_h = self:_menu_footprint()

    self:SetSize(menu_w, menu_h)
    self:layout_move_chrome()
end

function LauncherMenu:_resolve_direction()
    local s = _launcher_settings()

    if s.orientation == ORIENTATION_HORIZONTAL then
        if s.direction == DIRECTION_LEFT or s.direction == DIRECTION_RIGHT then
            return s.direction
        end
        return DIRECTION_RIGHT
    end

    if s.orientation == ORIENTATION_VERTICAL then
        if s.direction == DIRECTION_UP or s.direction == DIRECTION_DOWN then
            return s.direction
        end
        return DIRECTION_DOWN
    end

    error("Invalid launcher orientation: " .. tostring(s.orientation))
end

function LauncherMenu:_apply_button_icon(button, size, icon_size)
    button:SetSize(size, size)
    button:set_icon(button._launcher_icon, nil, nil, nil, icon_size, icon_size, UI.Widgets.LuiButton.icon_position.RIGHT)
end

function LauncherMenu:_layout_buttons()
    local s = _launcher_settings()
    local size = s.icon_size
    local spacing = s.spacing
    local icon_size = _button_icon_size(size)
    local direction = self:_resolve_direction()
    local menu_w, menu_h = self:_menu_footprint()

    self:_apply_button_icon(self.logo_button, size, icon_size)

    if s.orientation == ORIENTATION_HORIZONTAL then
        local logo_x = 0
        if direction == DIRECTION_LEFT then
            logo_x = menu_w - size
        elseif direction ~= DIRECTION_RIGHT then
            error("Invalid horizontal launcher direction: " .. tostring(direction))
        end
        self.logo_button:SetPosition(logo_x, 0)

        for i = 1, #self.shortcut_buttons do
            local button = self.shortcut_buttons[i]
            self:_apply_button_icon(button, size, icon_size)
            local step = i * (size + spacing)
            local x = direction == DIRECTION_LEFT and (logo_x - step) or step
            button:SetPosition(x, 0)
            button:SetVisible(self.expanded == true)
        end
        return
    end

    if s.orientation ~= ORIENTATION_VERTICAL then
        error("Invalid launcher orientation: " .. tostring(s.orientation))
    end

    local logo_y = 0
    if direction == DIRECTION_UP then
        logo_y = menu_h - size
    elseif direction ~= DIRECTION_DOWN then
        error("Invalid vertical launcher direction: " .. tostring(direction))
    end
    self.logo_button:SetPosition(0, logo_y)

    for i = 1, #self.shortcut_buttons do
        local button = self.shortcut_buttons[i]
        self:_apply_button_icon(button, size, icon_size)
        local step = i * (size + spacing)
        local y = direction == DIRECTION_UP and (logo_y - step) or step
        button:SetPosition(0, y)
        button:SetVisible(self.expanded == true)
    end
end

function LauncherMenu:_refresh_shortcut_availability()
    for i = 1, #self.shortcut_buttons do
        local button = self.shortcut_buttons[i]
        local available = Shortcuts.get_state(button.shortcut_key)
        button:set_enabled(available == true)
    end
end
