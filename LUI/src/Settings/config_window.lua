-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Windows = _G.LUI.Runtime.Windows
local Apply = _G.LUI.Runtime.Apply
local MoveMode = _G.LUI.UI.MoveMode
local TR = _G.LUI.Locale.TR
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local LUI_ENUMS = _G.LUI.Settings.Enums
local Persistence = _G.LUI.Settings.Persistence
local Colors = _G.LUI.Settings.Colors
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Hidable = _G.LUI.UI.Hidable
local Settings = _G.LUI.Settings
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.Gameplay"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"
import "LUI.src.Utils.color"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Utils.time_format"
import "LUI.src.Utils.token_format"
import "LUI.src.Settings.enums"

local Style = UI.Widgets.Style
local SETTINGS_ACTION_FONT_SIZE_OFFSET = 1
local CONFIG_TAB_FONT_SIZE_OFFSET = 3
local CONFIG_MIN_WIDTH = 900
local CONFIG_MIN_HEIGHT = 800
local function _scaled_size(value)
    return value * State.settings.global.scale
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(size)))
    end
    return font
end

local _color_to_hex = lui_color_to_hex
local _hex_to_color = lui_hex_to_color

local ConfigWindow = class(UI.Widgets.LuiWindow)
Settings.ConfigWindow = ConfigWindow

import "LUI.src.Settings.Window.window_geometry"
import "LUI.src.Settings.Window.window_tabs"
import "LUI.src.Settings.Window.window_layout"
import "LUI.src.Settings.Window.window_previews"
import "LUI.src.Settings.Window.window_profiles"

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function ConfigWindow:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self:set_title(TR["LUI Configuration"])
    self:set_resizable(true)
    self:hide()

    self:_update_ui_scale_metrics()
    local display_width, display_height = Turbine.UI.Display.GetSize()
    local minimum_width = _scaled_int(CONFIG_MIN_WIDTH)
    local minimum_height = _scaled_int(CONFIG_MIN_HEIGHT)
    if minimum_width > display_width then
        minimum_width = display_width
    end
    if minimum_height > display_height then
        minimum_height = display_height
    end
    self:set_minimum_size(minimum_width, minimum_height)

    local content = Turbine.UI.Control()
    content:SetMouseVisible(true)
    self:set_central_widget(content)

    self.main_tab_bar = UI.Widgets.LuiTabBar()
    self.main_tab_bar:SetParent(content)
    self.main_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.left)
    self.main_tab_bar:set_show_content_border(false)
    self.main_tab_bar.on_tab_changed = function(index, page, text)
        if page == nil then
            return
        end
        self:_on_main_tab_changed(index, page, text, self._pending_main_tab_sub_key)
    end

    self.tooltip = UI.Widgets.LuiTooltip()
    self.tooltip:set_scale(State.settings.global.scale)
    self.tooltip:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))

    self.confirm_overlay = Turbine.UI.Control()
    self.confirm_overlay:SetParent(content)
    self.confirm_overlay:SetVisible(false)
    self.confirm_overlay:SetMouseVisible(true)
    self.confirm_overlay:SetZOrder(2000)
    self.confirm_overlay:SetBackColor(Style.MODAL_OVERLAY_BACKGROUND)
    self.confirm_overlay:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.confirm_overlay:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    self.confirm_dialog = Turbine.UI.Control()
    self.confirm_dialog:SetParent(self.confirm_overlay)
    self.confirm_dialog:SetMouseVisible(true)
    self.confirm_dialog:SetBackColor(Style.MODAL_DIALOG_BACKGROUND)
    self.confirm_dialog:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.confirm_dialog:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    self.confirm_dialog_label = UI.Widgets.LuiLabel()
    self.confirm_dialog_label:SetParent(self.confirm_dialog)
    self.confirm_dialog_label:SetMultiline(true)
    self.confirm_dialog_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.confirm_dialog_label:SetForeColor(Style.FOREGROUND)

    self.confirm_cancel_button = UI.Widgets.LuiButton()
    self.confirm_cancel_button:SetParent(self.confirm_dialog)
    self.confirm_cancel_button:set_text(TR["Cancel"])
    self.confirm_cancel_button.Click = function()
        self:hide_confirmation_dialog()
    end

    self.confirm_confirm_button = UI.Widgets.LuiButton()
    self.confirm_confirm_button:SetParent(self.confirm_dialog)
    self.confirm_confirm_button:set_text(TR["Delete"])
    self.confirm_confirm_button.Click = function()
        local action = self.confirm_dialog_action
        self:hide_confirmation_dialog()
        if action ~= nil then
            action()
        end
    end

    self.button_bar = Turbine.UI.Control()
    self.button_bar:SetParent(content)

    self.cancel_button = UI.Widgets.LuiButton()
    self.cancel_button:SetParent(self.button_bar)
    self.cancel_button:set_font(self.settings_font)
    self.cancel_button:set_text(TR["Cancel"])
    self.cancel_button.Click = function()
        self:cancel()
    end

    self.apply_button = UI.Widgets.LuiButton()
    self.apply_button:SetParent(self.button_bar)
    self.apply_button:set_font(self.settings_font)
    self.apply_button:set_text(TR["Apply"])
    self.apply_button.Click = function()
        self:apply_changes(false)
    end

    self.save_button = UI.Widgets.LuiButton()
    self.save_button:SetParent(self.button_bar)
    self.save_button:set_font(self.settings_font)
    self.save_button:set_text(TR["Save"])
    self.save_button.Click = function()
        self:apply_changes(true)
    end

    self:build_controls()
    self:build_tabs()
    self:_rebuild_control_registry()

    self.move_ui_button = UI.Widgets.LuiButton()
    self.move_ui_button:SetParent(self.button_bar)
    self.move_ui_button:set_font(self.settings_font)
    self.move_ui_button:set_text(TR["Move UI"])
    self.move_ui_button.Click = function()
        if Hidable.is_lui_hud_visible() ~= true then
            Hidable.set_lui_hud_visible(true)
        end
        MoveMode.set_mode(true, true)
    end

    self:apply_ui_scale()

    self.SizeChanged = function()
        UI.Widgets.LuiWindow._layout(self)
        self:layout()
        self:_refresh_active_preview()
    end

    self.VisibleChanged = function()
        if self:IsVisible() == false then
            self:update_saved_geometry()
            self:hide_hint()
            self:hide_confirmation_dialog()
            self:close_all_dropdowns()
            self._pending_open_main_key = nil
            self._pending_open_sub_key = nil
            return
        end

        self:layout()
        if type(self._pending_open_main_key) == "string" then
            local main_key = self._pending_open_main_key
            local preferred_sub_key = self._pending_open_sub_key
            self._pending_open_main_key = nil
            self._pending_open_sub_key = nil
            self:select_main_tab(main_key, preferred_sub_key)
        else
            self:_activate_active_page()
        end
    end

    self:apply_saved_geometry()
    self:select_main_tab("global")
    self:layout()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function ConfigWindow:_update_ui_scale_metrics()
    self.settings_font = _scaled_font(Style.CONTROL_FONT_NAME,
        Style.CONTROL_FONT_SIZE + SETTINGS_ACTION_FONT_SIZE_OFFSET)
    self.tab_font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + CONFIG_TAB_FONT_SIZE_OFFSET)

    self.margin_left = _scaled_int(6)
    self.margin_top = _scaled_int(6)
    self.margin_right = _scaled_int(6)
    self.margin_bottom = _scaled_int(6)

    self.button_bar_height = _scaled_int(30)
    self.row_height = _scaled_int(34)
    self.col_gap = _scaled_int(22)
    self.inner_gap = _scaled_int(4)
    self.content_padding = _scaled_int(7)
    self.scroll_bar_gap = _scaled_int(3)

    self.title_font = _scaled_font(Style.FONT_H2_NAME, Style.FONT_H2_SIZE)
    self.field_label_font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE)
    self.input_font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE)
    self.field_label_height = _scaled_int(31)
    self.input_height = _scaled_int(21)
    self.dropdown_y_offset = _scaled_int(1)
end

function ConfigWindow:apply_ui_scale()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)
    self:_update_ui_scale_metrics()
    local display_width, display_height = Turbine.UI.Display.GetSize()
    local minimum_width = _scaled_int(CONFIG_MIN_WIDTH)
    local minimum_height = _scaled_int(CONFIG_MIN_HEIGHT)
    if minimum_width > display_width then
        minimum_width = display_width
    end
    if minimum_height > display_height then
        minimum_height = display_height
    end
    self:set_minimum_size(minimum_width, minimum_height)
    local scale = State.settings.global.scale

    if self.tooltip ~= nil then
        self.tooltip:set_scale(scale)
        self.tooltip:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    end

    if self.cancel_button ~= nil then
        self.cancel_button:set_font(self.settings_font)
    end
    if self.apply_button ~= nil then
        self.apply_button:set_font(self.settings_font)
    end
    if self.save_button ~= nil then
        self.save_button:set_font(self.settings_font)
    end
    if self.move_ui_button ~= nil then
        self.move_ui_button:set_font(self.settings_font)
    end
    if self.confirm_dialog_label ~= nil then
        self.confirm_dialog_label:SetFont(self.field_label_font)
    end
    if self.confirm_cancel_button ~= nil then
        self.confirm_cancel_button:set_font(self.settings_font)
    end
    if self.confirm_confirm_button ~= nil then
        self.confirm_confirm_button:set_font(self.settings_font)
    end

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:set_scale(scale)
        self.main_tab_bar:set_font(self.tab_font)
    end

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            if page ~= nil and page.apply_ui_scale ~= nil then
                page:apply_ui_scale()
            end
        end)
    end
end

function ConfigWindow:close_all_dropdowns()
    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            if page ~= nil and page.close_all_dropdowns ~= nil then
                page:close_all_dropdowns()
            end
        end)
    end
end

function ConfigWindow:show_hint_for(control, text)
    if self.tooltip == nil then
        return
    end
    self.tooltip:ShowFor(control, text)
end

function ConfigWindow:hide_hint()
    if self.tooltip ~= nil then
        self.tooltip:Hide()
    end
end

function ConfigWindow:bind_tooltip(control, text_source)
    if self.tooltip ~= nil then
        self.tooltip:Bind(control, text_source)
    end
end

function ConfigWindow:show_confirmation_dialog(text, confirm_text, action)
    if self.confirm_overlay == nil then
        return
    end

    self.confirm_dialog_action = action
    self.confirm_dialog_label:SetText(text or "")
    self.confirm_confirm_button:set_text(confirm_text or TR["Confirm"])
    self.confirm_overlay:SetVisible(true)
    self:layout()
end

function ConfigWindow:hide_confirmation_dialog()
    self.confirm_dialog_action = nil
    if self.confirm_overlay ~= nil then
        self.confirm_overlay:SetVisible(false)
    end
end

function ConfigWindow:cancel()
    self:hide_confirmation_dialog()
    self:hide()
end

function ConfigWindow:open(main_key, preferred_sub_key)
    self:apply_saved_geometry()
    self:load_from_settings()

    if self:IsVisible() == true then
        if type(main_key) == "string" then
            self:select_main_tab(main_key, preferred_sub_key)
        else
            self:_activate_active_page()
        end
        self:show()
        self:layout()
    else
        self._pending_open_main_key = type(main_key) == "string" and main_key or nil
        self._pending_open_sub_key = type(main_key) == "string" and preferred_sub_key or nil
        self:show()
    end
end

function ConfigWindow:bring_to_front()
    if self:IsVisible() == true then
        self:Activate()
    end
end

function ConfigWindow:_rebuild_control_registry()
    self.controls = {}
    self._color_fields = {}

    if self.main_tab_bar == nil then
        return
    end

    self.main_tab_bar:each_widget(function(_, page)
        if page ~= nil and page.controls ~= nil then
            for control_key, entry in pairs(page.controls) do
                self.controls[control_key] = entry
            end
        end
        if page ~= nil and page._color_fields ~= nil then
            for i = 1, #page._color_fields do
                self._color_fields[#self._color_fields + 1] = page._color_fields[i]
            end
        end
    end)
end

function ConfigWindow:build_controls()
    local font_name_labels = {
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
    local font_name_values = {
        LUI_ENUMS.font_name.VERDANA,
        LUI_ENUMS.font_name.BOOK_ANTIQUA,
        LUI_ENUMS.font_name.BOOK_ANTIQUA_BOLD,
        LUI_ENUMS.font_name.TRAJAN_PRO,
        LUI_ENUMS.font_name.TRAJAN_PRO_BOLD,
        LUI_ENUMS.font_name.ARIAL,
        LUI_ENUMS.font_name.FIXED_SYS,
        LUI_ENUMS.font_name.LUCIDA_CONSOLE,
        LUI_ENUMS.font_name.VERDANA_BOLD,
    }

    local font_style_labels = { TR["None"], TR["Outline"] }
    local font_style_values = { LUI_ENUMS.font_style.NONE, LUI_ENUMS.font_style.OUTLINE }

    local side_labels = { TR["Left"], TR["Right"] }
    local side_values = { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT }

    local text_alignment_labels = { TR["Left"], TR["Center"], TR["Right"] }
    local text_alignment_values = {
        LUI_ENUMS.text_alignment.LEFT,
        LUI_ENUMS.text_alignment.CENTER,
        LUI_ENUMS.text_alignment.RIGHT,
    }

    local vitals_label_anchor_labels = {
        TR["Top Left"],
        TR["Top"],
        TR["Top Right"],
        TR["Left"],
        TR["Center"],
        TR["Right"],
        TR["Bottom Left"],
        TR["Bottom"],
        TR["Bottom Right"],
    }
    local vitals_label_anchor_values = {
        LUI_ENUMS.vitals_label_anchor.TOP_LEFT,
        LUI_ENUMS.vitals_label_anchor.TOP,
        LUI_ENUMS.vitals_label_anchor.TOP_RIGHT,
        LUI_ENUMS.vitals_label_anchor.LEFT,
        LUI_ENUMS.vitals_label_anchor.CENTER,
        LUI_ENUMS.vitals_label_anchor.RIGHT,
        LUI_ENUMS.vitals_label_anchor.BOTTOM_LEFT,
        LUI_ENUMS.vitals_label_anchor.BOTTOM,
        LUI_ENUMS.vitals_label_anchor.BOTTOM_RIGHT,
    }

    local vitals_label_width_mode_labels = { TR["Auto"], TR["Fill"] }
    local vitals_label_width_mode_values = {
        LUI_ENUMS.vitals_label_width_mode.AUTO,
        LUI_ENUMS.vitals_label_width_mode.FILL,
    }

    local abbrev_digits_labels = { "3", "4" }
    local abbrev_digits_values = { LUI_ENUMS.abbrev_digits.DIGITS_3, LUI_ENUMS.abbrev_digits.DIGITS_4 }
    local abbrev_width_labels = { "3", "4" }
    local abbrev_width_values = {
        LUI_ENUMS.abbrev_width.CHARS_3,
        LUI_ENUMS.abbrev_width.CHARS_4,
    }
    local abbrev_method_labels = {
        "k / M / G",
        "k / M / B",
        "k / m / M",
        "e3 / e6 / e9",
    }
    local abbrev_method_values = {
        LUI_ENUMS.abbrev_method.K_M_G,
        LUI_ENUMS.abbrev_method.K_M_B,
        LUI_ENUMS.abbrev_method.K_m_M,
        LUI_ENUMS.abbrev_method.E3_E6_E9,
    }

    local vitals_effects_position_labels = { TR["Above Morale"], TR["Below Power"] }
    local vitals_effects_position_values = {
        LUI_ENUMS.vitals_effects_position.ABOVE,
        LUI_ENUMS.vitals_effects_position.BELOW,
    }

    local vitals_effect_slot_labels = {
        TR["Top - Near Vitals"],
        TR["Top - Far from Vitals"],
        TR["Bottom - Near Vitals"],
        TR["Bottom - Far from Vitals"],
    }
    local vitals_effect_slot_values = {
        LUI_ENUMS.vitals_effect_slot.TOP_NEAR,
        LUI_ENUMS.vitals_effect_slot.TOP_FAR,
        LUI_ENUMS.vitals_effect_slot.BOTTOM_NEAR,
        LUI_ENUMS.vitals_effect_slot.BOTTOM_FAR,
    }

    local vitals_label_link_labels = {
        TR["Morale"],
        TR["Power / Wrath"],
        TR["Info"],
    }
    local vitals_label_link_values = {
        LUI_ENUMS.vitals_label_link.MORALE,
        LUI_ENUMS.vitals_label_link.POWER,
        LUI_ENUMS.vitals_label_link.INFO,
    }

    local vital_format_help = table.concat({
        TR["Text template tokens:"],
        TR["  %mc = current morale"],
        TR["  %mt = maximum morale"],
        TR["  %mp = morale percent (e.g. 73%)"],
        TR["  %b = bubble value (temporary morale)"],
        TR["  %B = bubble format output (only when bubble > 0)"],
        TR["  %pc = current power / wrath"],
        TR["  %pt = maximum power / wrath"],
        TR["  %pp = power / wrath percent (e.g. 73%)"],
        TR["  %name% = entity name"],
        TR["  %level% = entity level"],
        "",
        TR["Set the text to empty to hide the label."],
        TR["You can use \\n for a new line."],
        TR["Example: [%level%] %name%\n%mc / %mt - %mp"],
    }, "\n")

    local bubble_format_help = table.concat({
        TR["Bubble format (used by %B; only when bubble > 0)."],
        TR["Use %b for the bubble value."],
        TR["Example:  - %b"],
    }, "\n")

    self.controls = {}
    self._color_fields = {}
    self._ui = {
        font_name_labels = font_name_labels,
        font_name_values = font_name_values,
        font_style_labels = font_style_labels,
        font_style_values = font_style_values,
        side_labels = side_labels,
        side_values = side_values,
        text_alignment_labels = text_alignment_labels,
        text_alignment_values = text_alignment_values,
        vitals_label_anchor_labels = vitals_label_anchor_labels,
        vitals_label_anchor_values = vitals_label_anchor_values,
        vitals_label_width_mode_labels = vitals_label_width_mode_labels,
        vitals_label_width_mode_values = vitals_label_width_mode_values,
        abbrev_digits_labels = abbrev_digits_labels,
        abbrev_digits_values = abbrev_digits_values,
        abbrev_width_labels = abbrev_width_labels,
        abbrev_width_values = abbrev_width_values,
        abbrev_method_labels = abbrev_method_labels,
        abbrev_method_values = abbrev_method_values,
        vitals_effects_position_labels = vitals_effects_position_labels,
        vitals_effects_position_values = vitals_effects_position_values,
        vitals_effect_slot_labels = vitals_effect_slot_labels,
        vitals_effect_slot_values = vitals_effect_slot_values,
        vitals_label_link_labels = vitals_label_link_labels,
        vitals_label_link_values = vitals_label_link_values,
        vital_format_help = vital_format_help,
        bubble_format_help = bubble_format_help,
        color_to_hex = _color_to_hex,
        hex_to_color = _hex_to_color,
    }

end
function ConfigWindow:update_swatch(entry)
    if entry == nil or entry.is_color ~= true or entry.tb == nil then
        return
    end

    if entry.tb.update_swatch ~= nil then
        entry.tb:update_swatch()
    end
end

function ConfigWindow:update_all_swatches()
    if self._color_fields == nil then
        return
    end
    for i = 1, #self._color_fields do
        self:update_swatch(self._color_fields[i])
    end
end

function ConfigWindow:load_from_settings()
    if State.loaded_settings == nil then
        return
    end

    self.loading = true

    local s = State.loaded_settings

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            page._settings = s
            page:load()
        end)
    end

    self:update_all_swatches()

    self.loading = false
    self:_refresh_active_preview()
end

function ConfigWindow:refresh_runtime_settings()
    Colors.fix_colors()
    Settings.rebuild()
    -- (2026-10-02) recordar el idioma elegido para el proximo arranque
    if _G.LUI.Locale ~= nil and _G.LUI.Locale.persist_language ~= nil
        and State ~= nil and State.settings ~= nil and State.settings.global ~= nil then
        pcall(_G.LUI.Locale.persist_language, State.settings.global.language)
    end
    -- (2026-10-02) efecto del puntero primero: no depende de las demas
    -- ventanas (si alguna fallara, el puntero igual se actualiza)
    if Apply.pointer_settings ~= nil then
        pcall(Apply.pointer_settings)
    end
    Apply.inventory_settings()
    Apply.assets_settings()
    Apply.status_bar_settings()
    Apply.cooldowns_settings()
    Apply.upkeep_settings()
    Apply.drops_settings()
    Apply.crafting_settings()
    Apply.travel_settings()
    Apply.launcher_settings()
    Apply.lotro_vitals_handoff()

    self:apply_ui_scale()
    self:layout()

    if Windows.player_vital ~= nil then
        Windows.player_vital:resize()
        Windows.player_vital:apply_enabled_state()
    end
    if Windows.target_vital ~= nil then
        Windows.target_vital:resize()
    end
    if Windows.companion_vital ~= nil then
        Windows.companion_vital:resize()
        Windows.companion_vital:update_pet()
    end
    if Windows.boss_vital ~= nil then
        Windows.boss_vital:resize()
    end
    if Windows.fellowship_vitals ~= nil then
        Windows.fellowship_vitals:apply_settings()
    end
    if Windows.raid_vitals ~= nil then
        Windows.raid_vitals:apply_settings()
    end
    if Windows.raid_config ~= nil then
        Windows.raid_config:apply_settings()
    end
    if Windows.expiring_self_effects ~= nil then
        Windows.expiring_self_effects:apply_settings()
    end
    if Windows.expiring_target_effects ~= nil then
        Windows.expiring_target_effects:apply_settings()
    end
    if Windows.inventory ~= nil then
        Windows.inventory:apply_settings()
    end
    if Windows.assets ~= nil then
        Windows.assets:apply_settings()
    end
    if Windows.cooldowns ~= nil then
        Windows.cooldowns:apply_settings()
    end
    if Windows.upkeep ~= nil then
        Windows.upkeep:apply_settings()
    end
    if Windows.drops ~= nil then
        Windows.drops:apply_settings()
    end
    if Windows.encyclopedia ~= nil then
        Windows.encyclopedia:apply_settings()
    end
    if Windows.bestiary_card ~= nil then
        Windows.bestiary_card:apply_settings()
    end
    if Windows.resource_card ~= nil then
        Windows.resource_card:apply_settings()
    end
    if Windows.quest_card ~= nil then
        Windows.quest_card:apply_settings()
    end
    if Windows.crafting ~= nil then
        Windows.crafting:apply_settings()
    end
    if Windows.bestiary_tracker ~= nil then
        Windows.bestiary_tracker:apply_settings()
    end
    if Windows.player_vital ~= nil then
        Windows.player_vital:on_target_changed()
    end

    self:_refresh_active_preview()
end

function ConfigWindow:apply_changes(close_after)
    if State.loaded_settings == nil then
        return
    end

    local s = State.loaded_settings

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            page._settings = s
            page:save()
        end)
    end

    Persistence.capture_runtime_geometry()

    self:refresh_runtime_settings()

    self:update_saved_geometry()
    Persistence.save_settings()

    if close_after then
        self:hide()
    end
end
