-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigSectionPage = _G.LUI.Settings.Content.ConfigSectionPage
local ConfigNestedTabs = _G.LUI.Settings.Content.ConfigNestedTabs
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.nested_tabs"
import "LUI.src.Settings.Content.section_page"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int
local Style = UI.Widgets.Style

local STYLE_FONT_NAME_LABELS = {
    "Verdana",
    "BookAntiqua",
    "BookAntiquaBold",
    "TrajanPro",
    "TrajanProBold",
    "Arial",
    "FixedSys",
    "LucidaConsole",
    "VerdanaBold",
}

local STYLE_FONT_NAME_VALUES = {
    "Verdana",
    "BookAntiqua",
    "BookAntiquaBold",
    "TrajanPro",
    "TrajanProBold",
    "Arial",
    "FixedSys",
    "LucidaConsole",
    "VerdanaBold",
}

-- Idioma de la interfaz (ver Utils/i18n.lua): los nombres de idioma NO
-- pasan por TR[] a proposito -- un nombre de idioma se muestra siempre en
-- si mismo ("Español" sigue diciendo "Español" aunque la interfaz este en
-- ingles), mismo criterio que STYLE_FONT_NAME_LABELS de arriba (nombres
-- propios, no texto de UI generico).
local LANGUAGE_LABELS = { TR["Automatic (client language)"], "English", "Español" }
local LANGUAGE_VALUES = { "auto", "en", "es" }

local function _style_settings(settings)
    return settings.global.style
end

local function _style_override_value(style, key)
    local value = style[key]
    if value ~= nil then
        return value
    end

    local fallback = Style.FALLBACKS[key]
    if fallback ~= nil then
        return _style_override_value(style, fallback)
    end

    return nil
end

local function _dev_style_value(key)
    local value = _style_override_value(UI.Style, key)
    if value ~= nil then
        return value
    end

    return Style.DEFAULTS[key]
end

local function _style_value(settings, key)
    local style = _style_settings(settings)
    local value = style[key]
    if value ~= nil then
        return value, true
    end

    local fallback = Style.FALLBACKS[key]
    if fallback ~= nil then
        local inherited = _style_override_value(style, fallback)
        if inherited ~= nil then
            return inherited, false
        end
    end

    return _dev_style_value(key), false
end

local function _style_inherited_value(settings, key)
    local style = _style_settings(settings)
    local fallback = Style.FALLBACKS[key]
    if fallback ~= nil then
        local inherited = _style_override_value(style, fallback)
        if inherited ~= nil then
            return inherited
        end
    end
    return _dev_style_value(key)
end

local function _same_color_hex(page, left, right)
    return page.color_to_hex(left) == page.color_to_hex(right)
end

local function _color_alpha(color)
    local value = tonumber(color.A)
    if value == nil then
        return 1
    end
    return value
end

local function _color_with_alpha(color, alpha)
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

local function _opacity_value(value)
    local number = tonumber(value)
    if number == nil then
        return nil
    end
    if number < 0 then
        number = 0
    elseif number > 1 then
        number = 1
    end
    return math.floor((number * 100) + 0.5) / 100
end

local function _opacity_text(value)
    return string.format("%.2f", _opacity_value(value) or 1)
end

local function _same_style_color(page, left, right)
    return _same_color_hex(page, left, right) == true and _opacity_text(_color_alpha(left)) == _opacity_text(_color_alpha(right))
end

local function _style_control_key(key)
    return "global_ui_style_" .. string.lower(key)
end

local function _add_style_color(page, settings_getter, key, label)
    local entry = page:add_color_picker(_style_control_key(key), label)
    page:bind(entry,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local color = page.hex_to_color(value)
            local current = _style_value(settings_getter(), key)
            color = _color_with_alpha(color, _color_alpha(current))
            local style = _style_settings(settings_getter())
            if _same_style_color(page, color, _style_inherited_value(settings_getter(), key)) == true then
                style[key] = nil
            else
                style[key] = color
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            local hex = page.color_to_hex(value)
            entry._loaded_value = hex
            entry._loaded_direct = direct == true
            entry._style_default_value = page.color_to_hex(Style.DEFAULTS[key])
            return hex
        end)
    return entry
end

local function _add_style_opacity(page, settings_getter, key, label)
    local entry = page:add_line_edit(_style_control_key(key) .. "_opacity", label)
    page:bind(entry,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local alpha = _opacity_value(value)
            if alpha ~= nil then
                local current = _style_value(settings_getter(), key)
                local color = _color_with_alpha(current, alpha)
                local style = _style_settings(settings_getter())
                if _same_style_color(page, color, _style_inherited_value(settings_getter(), key)) == true then
                    style[key] = nil
                else
                    style[key] = color
                end
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            local text = _opacity_text(_color_alpha(value))
            entry._loaded_value = text
            entry._loaded_direct = direct == true
            entry._style_default_value = _opacity_text(_color_alpha(Style.DEFAULTS[key]))
            return text
        end)
    return entry
end

local function _add_style_number(page, settings_getter, key, label)
    local entry = page:add_line_edit(_style_control_key(key), label)
    page:bind(entry,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local number = tonumber(value)
            if number ~= nil then
                local style = _style_settings(settings_getter())
                if number == tonumber(_style_inherited_value(settings_getter(), key)) then
                    style[key] = nil
                else
                    style[key] = number
                end
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            local text = tostring(value)
            entry._loaded_value = text
            entry._loaded_direct = direct == true
            entry._style_default_value = tostring(Style.DEFAULTS[key])
            return text
        end)
    return entry
end

local function _add_style_checkbox(page, settings_getter, key, label)
    local entry = page:add_checkbox(_style_control_key(key), label)
    page:bind(entry,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local style = _style_settings(settings_getter())
            if (value == true) == (_style_inherited_value(settings_getter(), key) == true) then
                style[key] = nil
            else
                style[key] = value == true
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            entry._loaded_value = value == true
            entry._loaded_direct = direct == true
            entry._style_default_value = Style.DEFAULTS[key] == true
            return value == true
        end)
    return entry
end

local function _add_style_font_name(page, settings_getter, key, label)
    local entry = page:add_dropdown(_style_control_key(key), label, STYLE_FONT_NAME_LABELS, STYLE_FONT_NAME_VALUES)
    page:bind(entry,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local style = _style_settings(settings_getter())
            if value == _style_inherited_value(settings_getter(), key) then
                style[key] = nil
            else
                style[key] = value
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            entry._loaded_value = value
            entry._loaded_direct = direct == true
            entry._style_default_value = Style.DEFAULTS[key]
            return value
        end)
    return entry
end

local function _reset_style_controls(page)
    page:stage_style_reset()
    page.window:update_all_swatches()
    page:layout()
end

local function _add_reset_button(page, content)
    return content:add_button("global_ui_style_reset", TR["Reset shared UI style"], function()
        _reset_style_controls(page)
    end)
end

local function _new_ui_colors_section(window, settings_getter)
    local frame = ConfigContent(window, 3)
    _add_style_color(frame, settings_getter, "CONTROL_BORDER", TR["Border color"])
    _add_style_color(frame, settings_getter, "CONTROL_BORDER_HOVER", TR["Hover border color"])
    _add_style_color(frame, settings_getter, "CONTROL_BORDER_ACTIVE", TR["Active border color"])
    frame:add_row_break()
    _add_style_color(frame, settings_getter, "CONTROL_BORDER_DISABLED", TR["Disabled border color"])
    _add_style_color(frame, settings_getter, "SEPARATOR", TR["Separator color"])

    local backgrounds = ConfigContent(window, 3)
    _add_style_color(backgrounds, settings_getter, "BACKGROUND", TR["Window background"])
    _add_style_color(backgrounds, settings_getter, "ALTERNATE_BACKGROUND", TR["Alternate background"])
    backgrounds:add_row_break()
    _add_style_color(backgrounds, settings_getter, "PANEL_BACKGROUND", TR["Panel background"])
    _add_style_color(backgrounds, settings_getter, "PANEL_INNER_BACKGROUND", TR["Panel inner background"])
    backgrounds:add_row_break()
    _add_style_color(backgrounds, settings_getter, "CONTROL_BACKGROUND", TR["Control background"])

    local controls = ConfigContent(window, 3)
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_HOVER", TR["Hover background"])
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_PRESSED", TR["Pressed background"])
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_ACTIVE", TR["Active background"])
    controls:add_row_break()
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_DISABLED", TR["Disabled background"])
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_READONLY", TR["Read-only background"])

    local selection = ConfigContent(window, 3)
    _add_style_color(selection, settings_getter, "SELECTION_BACKGROUND", TR["Selection background"])
    _add_style_color(selection, settings_getter, "SELECTION_BACKGROUND_HOVER", TR["Selection hover background"])
    _add_style_color(selection, settings_getter, "SELECTION_FOREGROUND", TR["Selection text"])
    selection:add_row_break()
    _add_style_color(selection, settings_getter, "ALTERNATE_SELECTION_BACKGROUND", TR["Alternate selection background"])
    _add_style_color(selection, settings_getter, "ALTERNATE_SELECTION_FOREGROUND", TR["Alternate selection text"])

    local text = ConfigContent(window, 3)
    _add_style_color(text, settings_getter, "FOREGROUND", TR["Main text"])
    _add_style_color(text, settings_getter, "ALTERNATE_FOREGROUND", TR["Secondary text"])
    text:add_row_break()
    _add_style_color(text, settings_getter, "INFO_FOREGROUND", TR["Info text"])
    text:add_row_break()
    _add_style_color(text, settings_getter, "FOREGROUND_DISABLED", TR["Disabled text"])
    _add_style_color(text, settings_getter, "PLACEHOLDER_FOREGROUND", TR["Placeholder text"])
    _add_style_color(text, settings_getter, "TEXT_OUTLINE", TR["Text outline"])

    local control_text = ConfigContent(window, 3)
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND", TR["Control text"])
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_HOVER", TR["Control hover text"])
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_PRESSED", TR["Control pressed text"])
    control_text:add_row_break()
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_ACTIVE", TR["Control active text"])
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_DISABLED", TR["Control disabled text"])

    local accents = ConfigContent(window, 3)
    _add_style_color(accents, settings_getter, "ACCENT_BACKGROUND", TR["Accent background"])
    _add_style_color(accents, settings_getter, "ACCENT_FOREGROUND", TR["Accent text"])
    _add_style_color(accents, settings_getter, "SUBTLE_FOREGROUND", TR["Subtle foreground"])
    accents:add_row_break()
    _add_style_color(accents, settings_getter, "ACCENT_BACKGROUND_DISABLED", TR["Disabled accent"])
    _add_style_color(accents, settings_getter, "INVALID_BACKGROUND", TR["Invalid background"])

    local overlays = ConfigContent(window, 3)
    _add_style_color(overlays, settings_getter, "MODAL_OVERLAY_BACKGROUND", TR["Modal overlay background"])
    _add_style_opacity(overlays, settings_getter, "MODAL_OVERLAY_BACKGROUND", TR["Modal overlay opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "MODAL_DIALOG_BACKGROUND", TR["Modal dialog background"])
    _add_style_opacity(overlays, settings_getter, "MODAL_DIALOG_BACKGROUND", TR["Modal dialog opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "PREVIEW_OVERLAY_BACKGROUND", TR["Preview overlay background"])
    _add_style_opacity(overlays, settings_getter, "PREVIEW_OVERLAY_BACKGROUND", TR["Preview overlay opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_GHOST_BACKGROUND", TR["Drag ghost background"])
    _add_style_opacity(overlays, settings_getter, "DRAG_GHOST_BACKGROUND", TR["Drag ghost opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_GHOST_BORDER", TR["Drag ghost border"])
    _add_style_color(overlays, settings_getter, "DRAG_GHOST_FOREGROUND", TR["Drag ghost text"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_PREVIEW_FILL", TR["Drag preview fill"])
    _add_style_opacity(overlays, settings_getter, "DRAG_PREVIEW_FILL", TR["Drag preview fill opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_PREVIEW_EDGE", TR["Drag preview edge"])
    _add_style_opacity(overlays, settings_getter, "DRAG_PREVIEW_EDGE", TR["Drag preview edge opacity"])

    local move_mode = ConfigContent(window, 3)
    _add_style_color(move_mode, settings_getter, "MOVE_OVERLAY_BACKGROUND", TR["Move overlay background"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_OVERLAY_BACKGROUND", TR["Move overlay opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_OVERLAY_HEADER_BACKGROUND", TR["Move header background"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_OVERLAY_HEADER_BACKGROUND", TR["Move header opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_OVERLAY_FOREGROUND", TR["Move text"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_BACKGROUND", TR["Move grid background"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_BACKGROUND", TR["Move grid opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_CENTER_LINE", TR["Move grid center line"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_CENTER_LINE", TR["Move grid center opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_MAJOR_LINE", TR["Move grid major line"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_MAJOR_LINE", TR["Move grid major opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_MINOR_LINE", TR["Move grid minor line"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_MINOR_LINE", TR["Move grid minor opacity"])

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Backgrounds"], "backgrounds", backgrounds)
    page:add_tab(TR["Controls"], "controls", controls)
    page:add_tab(TR["Selection"], "selection", selection)
    page:add_tab(TR["Text"], "text", text)
    page:add_tab(TR["Control Text"], "control_text", control_text)
    page:add_tab(TR["Accents"], "accents", accents)
    page:add_tab(TR["Overlays"], "overlays", overlays)
    page:add_tab(TR["Move Mode"], "move_mode", move_mode)
    return page
end

local function _new_ui_page(window, settings_getter)
    local page = ConfigSectionPage(window, nil, nil, nil)
    local load_page = page.load
    local save_page = page.save
    local function style_settings_getter()
        return page._staged_style_settings or settings_getter()
    end

    function page:stage_style_reset()
        self._staged_style_settings = {
            global = {
                style = {},
            },
        }
        load_page(self)
    end

    function page:load()
        self._staged_style_settings = nil
        load_page(self)
    end

    function page:save()
        local staged = self._staged_style_settings
        if staged ~= nil then
            save_page(self)

            local style = _style_settings(settings_getter())
            for key in pairs(style) do
                style[key] = nil
            end

            local staged_style = _style_settings(staged)
            for key, value in pairs(staged_style) do
                style[key] = value
            end

            self._staged_style_settings = nil
            return
        end

        save_page(self)
    end

    local general = ConfigContent(window, 4)
    general:add_info(TR["Style changes apply after reloading the plugin."], 34)
    _add_reset_button(page, general)
    page:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4)
    _add_style_number(layout, style_settings_getter, "BORDER_WIDTH", TR["Border width"])
    _add_style_number(layout, style_settings_getter, "BORDER_WIDTH_THIN", TR["Thin border width"])
    _add_style_number(layout, style_settings_getter, "BORDER_WIDTH_LARGE", TR["Large border width"])
    layout:add_row_break()
    _add_style_number(layout, style_settings_getter, "TABLE_VERTICAL_BORDER_WIDTH", TR["Table vertical lines width"])
    _add_style_number(layout, style_settings_getter, "TABLE_HORIZONTAL_BORDER_WIDTH", TR["Table horizontal lines width"])
    layout:add_row_break()
    _add_style_checkbox(layout, style_settings_getter, "TABLE_ALTERNATE_ROWS", TR["Alternating table rows"])
    page:add_tab(TR["Layout"], "layout", layout)

    page:add_tab(TR["Colors"], "colors", _new_ui_colors_section(window, style_settings_getter))

    local text = ConfigContent(window, 4)
    _add_style_font_name(text, style_settings_getter, "CONTROL_FONT_NAME", TR["Default control font"])
    _add_style_number(text, style_settings_getter, "CONTROL_FONT_SIZE", TR["Default control font size"])
    text:add_row_break()
    _add_style_font_name(text, style_settings_getter, "WINDOW_TITLE_FONT_NAME", TR["Window title font"])
    _add_style_number(text, style_settings_getter, "WINDOW_TITLE_FONT_SIZE", TR["Window title font size"])
    text:add_row_break()
    _add_style_font_name(text, style_settings_getter, "FONT_H1_NAME", TR["H1 font"])
    _add_style_number(text, style_settings_getter, "FONT_H1_SIZE", TR["H1 font size"])
    text:add_row_break()
    _add_style_font_name(text, style_settings_getter, "FONT_H2_NAME", TR["H2 font"])
    _add_style_number(text, style_settings_getter, "FONT_H2_SIZE", TR["H2 font size"])
    text:add_row_break()
    _add_style_font_name(text, style_settings_getter, "CONTENT_LARGE_FONT_NAME", TR["Large content font"])
    _add_style_number(text, style_settings_getter, "CONTENT_LARGE_FONT_SIZE", TR["Large content font size"])
    text:add_row_break()
    _add_style_font_name(text, style_settings_getter, "CONTENT_MEDIUM_FONT_NAME", TR["Medium content font"])
    _add_style_number(text, style_settings_getter, "CONTENT_MEDIUM_FONT_SIZE", TR["Medium content font size"])
    text:add_row_break()
    _add_style_font_name(text, style_settings_getter, "CONTENT_SMALL_FONT_NAME", TR["Small content font"])
    _add_style_number(text, style_settings_getter, "CONTENT_SMALL_FONT_SIZE", TR["Small content font size"])
    page:add_tab(TR["Text"], "text", text)

    return page
end

local GlobalPage = class(ConfigTabs)
Pages.GlobalPage = GlobalPage

function GlobalPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local digits_help = table.concat({
        TR["How many digits are shown before shortening."],
        TR["3 digits: 999 -> 999, 1000 -> 1.0k, 1000000 -> 1.0M"],
        TR["4 digits: 9999 -> 9999, 10000 -> 10.0k, 1000000 -> 1000k"],
    }, "\n")
    local width_help = table.concat({
        TR["Maximum number of characters used by the shortened numeric part. The decimal point counts. Values are truncated, never rounded up."],
        TR["3 chars: 1000 -> 1.0k, 10000 -> 10k, 100000 -> 100k"],
        TR["4 chars: 1000 -> 1.0k, 10000 -> 10.0k, 1000000 -> 1000k"],
    }, "\n")
    local method_help = table.concat({
        TR["Which style is used for all shortened numbers."],
        TR["k / M / G: 2500000000 -> 2.5G"],
        TR["k / M / B: 2500000000 -> 2.5B"],
        TR["k / m / M: 2500000000 -> 2.5M"],
        TR["e3 / e6 / e9: 2500000000 -> 2.5e9"],
    }, "\n")

    local general = ConfigContent(window, 4)
    -- Pedido explicito del usuario: "que al seleccionar español se
    -- traduzca las opciones y el contenido -- inventario, opciones y
    -- otros se mantienen en ingles". Causa real (ver Utils/i18n.lua):
    -- es.lua nunca se registraba, y el auto-deteccion del idioma del
    -- cliente no tenia ningun caso para español. Se agrega este dropdown
    -- manual en vez de depender solo del auto-deteccion porque el valor
    -- numerico que el cliente en español devuelve no esta confirmado (ni
    -- otros addons de esta carpeta lo saben con certeza).
    general:add_dropdown("language", TR["Language"], LANGUAGE_LABELS, LANGUAGE_VALUES,
        function(value)
            self._settings.global.language = value
        end,
        function()
            return self._settings.global.language or "auto"
        end, TR["Changes apply after reloading the plugin."])
    general:add_row_break()
    general:add_line_edit("scale", TR["UI Scale"],
        function(value)
            local scale = tonumber(value)
            if scale ~= nil and scale > 0 then
                self._settings.global.scale = scale
            end
        end,
        function()
            return tostring(self._settings.global.scale)
        end)
    general:add_checkbox("native_scaling", TR["Use native LotRO UI scaling"],
        function(value)
            self._settings.global.native_scaling = value == true
        end,
        function()
            return self._settings.global.native_scaling == true
        end, true)
    general:add_row_break()
    general:add_line_edit("refresh_rate", TR["Refresh rate of some UI elements (fps)"],
        function(value)
            local refresh_rate = tonumber(value)
            if refresh_rate ~= nil and refresh_rate > 0 then
                self._settings.global.refresh_rate = refresh_rate
            end
        end,
        function()
            return tostring(self._settings.global.refresh_rate)
        end)
    general:add_row_break()
    general:add_checkbox("move_mode_shortcut", TR["Use LotRO move mode shortcut"],
        function(value)
            self._settings.global.move_mode_shortcut = value == true
        end,
        function()
            return self._settings.global.move_mode_shortcut == true
        end, 2)
    general:add_row_break()
    general:add_checkbox("close_windows_with_esc", TR["Close LUI windows with Esc"],
        function(value)
            self._settings.global.close_windows_with_esc = value == true
        end,
        function()
            return self._settings.global.close_windows_with_esc == true
        end, 2)
    general:add_row_break()
    -- (2026-09-30) mostrar/ocultar el icono del menu LUI (misma opcion que
    -- la pestana Menu de LUI, ver Tabs/Launcher/launcher_page.lua)
    local launcher_toggle = general:add_checkbox("launcher_icon_enabled", TR["Show the LUI Menu icon"],
        function(value)
            self._settings.launcher.enabled = value == true
        end,
        function()
            return self._settings.launcher.enabled == true
        end, 2)
    if _G.LUI.Settings.bind_launcher_toggle ~= nil then
        _G.LUI.Settings.bind_launcher_toggle(launcher_toggle)
    end
    self:add_tab(TR["General"], "general", general)

    local numbers = ConfigContent(window, 4)
    numbers:add_checkbox("abbrev_enabled", TR["Shorten large numbers"],
        function(value)
            self._settings.global.number_abbrev.enabled = value == true
        end,
        function()
            return self._settings.global.number_abbrev.enabled == true
        end)
    numbers:add_row_break()
    numbers:add_dropdown("abbrev_digits", TR["Digits Before Shortening"], numbers.abbrev_digits_labels,
        numbers.abbrev_digits_values,
        function(value)
            self._settings.global.number_abbrev.digits = value
        end,
        function()
            return self._settings.global.number_abbrev.digits
        end, digits_help)
    numbers:add_dropdown("abbrev_width", TR["Max Shortened Width"], numbers.abbrev_width_labels,
        numbers.abbrev_width_values,
        function(value)
            self._settings.global.number_abbrev.width = value
        end,
        function()
            return self._settings.global.number_abbrev.width
        end, width_help)
    numbers:add_dropdown("abbrev_method", TR["Shortening Style"], numbers.abbrev_method_labels,
        numbers.abbrev_method_values,
        function(value)
            self._settings.global.number_abbrev.method = value
        end,
        function()
            return self._settings.global.number_abbrev.method
        end, method_help)
    self:add_tab(TR["Numbers"], "numbers", numbers)

    -- (2026-10-02) efecto del puntero (src/Pointer/pointer_fx.lua): aura
    -- animada pegada al raton para no perderlo. Se aplica al guardar.
    local function ptr()
        if type(self._settings.pointer) ~= "table" then
            self._settings.pointer = {}
        end
        return self._settings.pointer
    end
    local Pointer = _G.LUI.Features.Pointer
    local P_DEF = Pointer ~= nil and Pointer.DEFAULTS or {}
    local pointer = ConfigContent(window, 4)
    pointer:add_info(TR["Animated aura under the mouse pointer so it is never lost in the game. Clicks pass through it. It stays visible while you hold the right mouse button to turn the camera, so the pointer reappears inside it."], 64)
    pointer:add_checkbox("pointer_enabled", TR["Show pointer effect"],
        function(value)
            ptr().enabled = value == true
        end,
        function()
            return ptr().enabled == true
        end, 2)
    pointer:add_row_break()
    pointer:add_dropdown("pointer_style", TR["Pointer style"],
        { TR["Ring"], TR["Halo"], TR["Orbiting spheres"], TR["Fire"], TR["Runes"], TR["Crosshair"], TR["Trail"] },
        { "anillo", "halo", "esferas", "fuego", "runas", "mira", "estela" },
        function(value)
            ptr().style = value
        end,
        function()
            return ptr().style or P_DEF.style or "anillo"
        end)
    pointer:add_dropdown("pointer_color", TR["Pointer color"],
        { TR["Gold"], TR["Blue"], TR["Green"], TR["Red"], TR["Purple"], TR["White"] },
        { "dorado", "azul", "verde", "rojo", "morado", "blanco" },
        function(value)
            ptr().color = value
        end,
        function()
            return ptr().color or P_DEF.color or "dorado"
        end)
    pointer:add_row_break()
    pointer:add_dropdown("pointer_size", TR["Pointer effect size"],
        { TR["Small"], TR["Medium"], TR["Large"] }, { "s", "m", "l" },
        function(value)
            ptr().size = value
        end,
        function()
            return ptr().size or P_DEF.size or "m"
        end)
    pointer:add_dropdown("pointer_opacity", TR["Pointer opacity"],
        { "40%", "60%", "75%", "90%", "100%" }, { 0.4, 0.6, 0.75, 0.9, 1 },
        function(value)
            ptr().opacity = value
        end,
        function()
            local v = tonumber(ptr().opacity) or 0.9
            local best, bd = 0.9, 2
            for _, c in ipairs({ 0.4, 0.6, 0.75, 0.9, 1 }) do
                if math.abs(c - v) < bd then
                    best, bd = c, math.abs(c - v)
                end
            end
            return best
        end)
    pointer:add_row_break()
    pointer:add_dropdown("pointer_speed", TR["Animation speed"],
        { TR["Slow"], TR["Normal"], TR["Fast"] }, { 0.6, 1, 1.6 },
        function(value)
            ptr().speed = value
        end,
        function()
            local v = tonumber(ptr().speed) or 1
            if v < 0.8 then return 0.6 end
            if v > 1.3 then return 1.6 end
            return 1
        end)
    pointer:add_dropdown("pointer_show", TR["Show the effect"],
        { TR["Always"], TR["Only while moving"] }, { "siempre", "mover" },
        function(value)
            ptr().show = value
        end,
        function()
            return ptr().show or P_DEF.show or "siempre"
        end, TR["Only while moving: it fades out after 2.5 seconds without moving the mouse."])
    pointer:add_row_break()
    pointer:add_checkbox("pointer_shake", TR["Shake the mouse to find the pointer (big flash)"],
        function(value)
            ptr().shake = value == true
        end,
        function()
            return ptr().shake ~= false
        end, 2)
    self:add_tab(TR["Pointer"], "pointer", pointer)

    -- (2026-10-03) aura del minimapa (src/MinimapAura/minimap_aura.lua):
    -- aro animado alrededor del radar del juego. Se aplica al guardar; el
    -- boton "Colocar" guarda solo esta pestana y deja arrastrar el aro.
    local function mmc()
        if type(self._settings.minimap) ~= "table" then
            self._settings.minimap = {}
        end
        return self._settings.minimap
    end
    local MinimapAura = _G.LUI.Features.MinimapAura
    local M_DEF = MinimapAura ~= nil and MinimapAura.DEFAULTS or {}
    local function nearest(list, v, fallback)
        v = tonumber(v) or fallback
        local best, bd = fallback, math.huge
        for _, c in ipairs(list) do
            if math.abs(c - v) < bd then
                best, bd = c, math.abs(c - v)
            end
        end
        return best
    end
    local minimap = ConfigContent(window, 4)
    minimap:add_info(TR["Animated ring around the game minimap (radar). Clicks pass through it and the centre stays clear. Use Place on the minimap once to put it over your radar: drag it, change the size with the mouse wheel or - / +, then OK or right click."], 64)
    minimap:add_checkbox("minimap_enabled", TR["Show minimap aura"],
        function(value)
            mmc().enabled = value == true
        end,
        function()
            return mmc().enabled == true
        end, 2)
    minimap:add_button("minimap_place", TR["Place on the minimap"], function()
        if MinimapAura == nil or MinimapAura.place_from_config == nil then
            return
        end
        -- por si el perfil se recargo desde que se abrio Opciones
        local St = _G.LUI.Settings.State
        if St ~= nil and type(St.loaded_settings) == "table" then
            self._settings = St.loaded_settings
        end
        minimap:save()
        MinimapAura.place_from_config(function()
            minimap:load()
        end)
    end, TR["Saves this tab, turns the aura on and lets you drag it over the radar."], 2)
    minimap:add_row_break()
    minimap:add_dropdown("minimap_design", TR["Aura design"],
        { TR["Calm aura"], TR["Orbiting stars"], TR["Stream of light"], TR["Runes"], TR["Sparkles"], TR["Flames"], TR["Double ring"] },
        { "sereno", "orbitas", "corriente", "runas", "destellos", "llamas", "doble" },
        function(value)
            mmc().design = value
        end,
        function()
            return mmc().design or M_DEF.design or "sereno"
        end)
    minimap:add_dropdown("minimap_color", TR["Pointer color"],
        { TR["Gold"], TR["Blue"], TR["Green"], TR["Red"], TR["Purple"], TR["White"] },
        { "dorado", "azul", "verde", "rojo", "morado", "blanco" },
        function(value)
            mmc().color = value
        end,
        function()
            return mmc().color or M_DEF.color or "dorado"
        end)
    minimap:add_row_break()
    -- el tamano tambien cambia con la rueda al colocar: solo se escribe si
    -- se eligio otro valor en la lista (si no, se respeta el de la rueda)
    local size_list = MinimapAura ~= nil and MinimapAura.SIZE_LIST or { 180 }
    local size_labels = {}
    for i = 1, #size_list do
        size_labels[i] = tostring(size_list[i]) .. " px"
    end
    local size_loaded = nil
    minimap:add_dropdown("minimap_size", TR["Ring size"], size_labels, size_list,
        function(value)
            if value ~= size_loaded then
                mmc().diameter = value
            end
        end,
        function()
            size_loaded = nearest(size_list, mmc().diameter, M_DEF.diameter or 180)
            return size_loaded
        end, TR["Fine adjustment: mouse wheel or - / + while placing it."])
    minimap:add_dropdown("minimap_thickness", TR["Ring thickness"],
        { TR["Thin"], TR["Normal"], TR["Thick"] }, { "f", "n", "g" },
        function(value)
            mmc().thickness = value
        end,
        function()
            return mmc().thickness or M_DEF.thickness or "n"
        end)
    minimap:add_row_break()
    minimap:add_dropdown("minimap_opacity", TR["Pointer opacity"],
        { "40%", "60%", "75%", "85%", "100%" }, { 0.4, 0.6, 0.75, 0.85, 1 },
        function(value)
            mmc().opacity = value
        end,
        function()
            return nearest({ 0.4, 0.6, 0.75, 0.85, 1 }, mmc().opacity, 0.85)
        end)
    minimap:add_dropdown("minimap_speed", TR["Animation speed"],
        { TR["Slow"], TR["Normal"], TR["Fast"] }, { 0.5, 1, 1.8 },
        function(value)
            mmc().speed = value
        end,
        function()
            return nearest({ 0.5, 1, 1.8 }, mmc().speed, 1)
        end)
    minimap:add_row_break()
    minimap:add_dropdown("minimap_smooth", TR["Smoothness"],
        { TR["High (every frame)"], TR["Medium"], TR["Low (lighter)"] }, { "alta", "media", "baja" },
        function(value)
            mmc().smooth = value
        end,
        function()
            return mmc().smooth or M_DEF.smooth or "alta"
        end, TR["How fluid the movement is. Low redraws less often and uses less of the computer."])
    self:add_tab(TR["Minimap"], "minimap", minimap)

    self:add_tab(TR["UI"], "ui", _new_ui_page(window, function()
        return self._settings
    end))
end

function GlobalPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
