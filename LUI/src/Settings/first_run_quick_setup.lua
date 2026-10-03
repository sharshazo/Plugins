-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Windows = _G.LUI.Runtime.Windows
local Apply = _G.LUI.Runtime.Apply
local MoveMode = _G.LUI.UI.MoveMode
local TR = _G.LUI.Locale.TR
local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local DefaultLayouts = _G.LUI.Settings.Defaults.DefaultLayouts
local Defaults = _G.LUI.Settings.Defaults
local Persistence = _G.LUI.Settings.Persistence
local Colors = _G.LUI.Settings.Colors
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Hidable = _G.LUI.UI.Hidable
local Settings = _G.LUI.Settings
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Settings.default_layouts"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.timed_row_layout"

local Style = UI.Widgets.Style
local WINDOW_W = 260
local WINDOW_H = 160
local FRAME_BORDER = 2
local WINDOW_MARGIN = 6
local TITLE_TOP = 4
local TITLE_H = 20
local TITLE_RULE_GAP = 0
local BODY_TOP = 30
local BODY_H = 48
local BODY_INTRO_H = 88
local BODY_FINAL_H = 58
local BODY_LINE_H = 24
local BODY_LINE_PAD = 14
local BODY_CONTROL_GAP = 8
local BODY_LABEL_GAP = 4
local BOTTOM_BUTTON_GAP = 10
local BUTTON_W = 80
local BUTTON_H = 18
local BUTTON_GAP = 5
local SCALE_INPUT_W = 55
local SCALE_INPUT_H = 18
local SCALE_BUTTON_W = 22
local CONFIG_DROPDOWN_W = 180
local CONFIG_DROPDOWN_H = 20
local LAYOUT_BUTTON_W = 100
local LAYOUT_BUTTON_H = 22
local LAYOUT_LABEL_H = 18

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

local function _body_text_width(text)
    return lui_timed_row_estimate_text_width(text, Style.CONTENT_LARGE_FONT_NAME, _scaled_size(Style.CONTENT_LARGE_FONT_SIZE))
end

local function _wrap_line_for_width(line, max_width, out)
    local current = ""
    for word in string.gmatch(line, "%S+") do
        local candidate = current == "" and word or current .. " " .. word
        if current == "" or _body_text_width(candidate) <= max_width then
            current = candidate
        else
            out[#out + 1] = current
            current = word
        end
    end

    if current == "" then
        out[#out + 1] = ""
    else
        out[#out + 1] = current
    end
end

local function _wrap_text_for_width(text, max_width)
    local lines = {}
    local source = tostring(text or "")

    for line in string.gmatch(source .. "\n", "(.-)\n") do
        _wrap_line_for_width(line, max_width, lines)
    end

    return table.concat(lines, "\n"), math.max(1, #lines)
end

local function _body_height_for_lines(line_count, min_height)
    return math.max(min_height, (line_count * BODY_LINE_H) + BODY_LINE_PAD)
end

local function _format_scale(value)
    local text = string.format("%.2f", value)
    text = string.gsub(text, "0+$", "")
    text = string.gsub(text, "%.$", "")
    return text
end

local function _trim_submit_suffix(text)
    if type(text) ~= "string" then
        return nil
    end

    if string.sub(text, -1) ~= "\n" then
        return nil
    end

    return string.gsub(text, "[\r\n]+$", "")
end

local function _clamp_scale(value)
    local n = tonumber(value)
    if n == nil then
        return nil
    end
    if n < 0.50 then
        n = 0.50
    end
    if n > 3.00 then
        n = 3.00
    end
    return math.floor((n * 100) + 0.5) / 100
end

local function _persist_window_position(window, raw_window)
    if window == nil or raw_window == nil or window.GetPosition == nil then
        return
    end

    local left, top = window:GetPosition()
    raw_window.left = left
    raw_window.top = top
end

local function _round(value)
    return math.floor(value + 0.5)
end

local function _get_edge_ratio(pos, size, display_size)
    if type(pos) ~= "number" or type(size) ~= "number" or type(display_size) ~= "number" or size <= 0 then
        return 0
    end

    local available = display_size - size
    if available <= 0 then
        return 0
    end

    local clamped_pos = pos
    if clamped_pos < 0 then
        clamped_pos = 0
    end
    if clamped_pos > available then
        clamped_pos = available
    end

    return clamped_pos / available
end

local function _clamp_window_pos(pos, size, display_size)
    local out = _round(pos)
    local max_pos = display_size - size
    if max_pos < 0 then
        max_pos = 0
    end
    if out < 0 then
        return 0
    end
    if out > max_pos then
        return max_pos
    end
    return out
end

local function _get_preview_window_specs()
    return {
        {
            get_window = function()
                return Windows.player_vital
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("self_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.target_vital
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("target_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.target_vital ~= nil and Windows.target_vital.targets_target_window or nil
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("target_target_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.boss_vital
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("boss_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.fellowship_vitals
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("fellowship_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.raid_vitals
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("raid_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.raid_vitals ~= nil and Windows.raid_vitals.group_windows[1] or nil
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("raid_group_a_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.raid_vitals ~= nil and Windows.raid_vitals.group_windows[2] or nil
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("raid_group_b_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.raid_vitals ~= nil and Windows.raid_vitals.group_windows[3] or nil
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("raid_group_c_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.raid_vitals ~= nil and Windows.raid_vitals.group_windows[4] or nil
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("raid_group_d_vitals")
            end,
        },
        {
            get_window = function()
                return Windows.expiring_self_effects
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("self_effects")
            end,
        },
        {
            get_window = function()
                return Windows.expiring_target_effects
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("target_effects")
            end,
        },
        {
            get_window = function()
                return Windows.cooldowns
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("cooldowns")
            end,
        },
        {
            get_window = function()
                return Windows.launcher
            end,
            get_raw_window = function()
                return Defaults.get_ui_hud_state("launcher")
            end,
        },
        {
            get_window = function()
                return Windows.inventory
            end,
            get_raw_window = function()
                return Defaults.get_ui_window_state("inventory")
            end,
        },
    }
end

local function _apply_runtime_settings()
    Defaults.ensure_loaded_settings()
    Colors.fix_colors()
    Settings.rebuild()
    Apply.inventory_settings()
    Apply.status_bar_settings()
    Apply.cooldowns_settings()
    Apply.launcher_settings()

    if Windows.config ~= nil then
        Windows.config:apply_ui_scale()
        Windows.config:layout()
    end

    if Windows.player_vital ~= nil then
        Windows.player_vital:resize()
    end
    if Windows.target_vital ~= nil then
        Windows.target_vital:resize()
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
    if Windows.expiring_self_effects ~= nil then
        Windows.expiring_self_effects:apply_settings()
    end
    if Windows.expiring_target_effects ~= nil then
        Windows.expiring_target_effects:apply_settings()
    end
    if Windows.cooldowns ~= nil then
        Windows.cooldowns:apply_settings()
    end
    if Windows.player_vital ~= nil then
        Windows.player_vital:on_target_changed()
    end

    if Windows.player_vital ~= nil and Windows.player_vital.is_move_mode ~= nil and Windows.player_vital:is_move_mode() == true then
        if Windows.player_vital.set_move_mode ~= nil then
            Windows.player_vital:set_move_mode(true)
        end
        if Windows.target_vital ~= nil and Windows.target_vital.set_move_mode ~= nil then
            Windows.target_vital:set_move_mode(true)
        end
        if Windows.boss_vital ~= nil and Windows.boss_vital.set_move_mode ~= nil then
            Windows.boss_vital:set_move_mode(true)
        end
        if Windows.fellowship_vitals ~= nil and Windows.fellowship_vitals.set_move_mode ~= nil then
            Windows.fellowship_vitals:set_move_mode(true)
        end
        if Windows.raid_vitals ~= nil and Windows.raid_vitals.set_move_mode ~= nil then
            Windows.raid_vitals:set_move_mode(true)
        end
        if Windows.expiring_self_effects ~= nil and Windows.expiring_self_effects.set_move_mode ~= nil then
            Windows.expiring_self_effects:set_move_mode(true)
        end
        if Windows.expiring_target_effects ~= nil and Windows.expiring_target_effects.set_move_mode ~= nil then
            Windows.expiring_target_effects:set_move_mode(true)
        end
        if Windows.cooldowns ~= nil and Windows.cooldowns.set_move_mode ~= nil then
            Windows.cooldowns:set_move_mode(true)
        end
        if Windows.upkeep ~= nil and Windows.upkeep.set_move_mode ~= nil then
            Windows.upkeep:set_move_mode(true)
        end
        if Windows.launcher ~= nil then
            Windows.launcher:set_move_mode(true)
        end
    end
end

local FirstRunQuickSetup = class(UI.Widgets.LuiBaseWindow)
Settings.FirstRunQuickSetup = FirstRunQuickSetup

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function FirstRunQuickSetup:Constructor(options)
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = false })

    self:SetVisible(false)
    self:SetZOrder(1500)
    self:SetBackColor(Style.CONTROL_BORDER)
    self:SetMouseVisible(true)

    self.step = 1
    self.selected_scale = DefaultLayouts.get_resolution_scale()
    self.selected_layout = nil
    self.selected_launcher_enabled = true
    self.updating_scale_text = false
    self.closing = false
    self._body_raw_text = ""
    self._body_h = BODY_H
    self._body_min_h = BODY_H
    self._window_h = WINDOW_H
    self._layout_mode = nil
    self.create_profile_on_finish = options ~= nil and options.create_profile_on_finish == true
    self.profile_name = options ~= nil and options.profile_name or nil
    self.previous_profile_id = self.create_profile_on_finish == true and State.current_profile_id or nil
    self.created_profile_id = nil
    self.initial_settings = DefaultLayouts.copy_table(State.loaded_settings)
    self.existing_config_labels, self.existing_config_values = Persistence.get_configuration_options()
    self.has_existing_configurations =
        not (options ~= nil and options.skip_existing_configurations == true) and #self.existing_config_values > 0
    State.loaded_settings.launcher.enabled = self.selected_launcher_enabled
    _apply_runtime_settings()

    self.preview_overlay = Turbine.UI.Window()
    self:apply_native_scaling(self.preview_overlay)
    self.preview_overlay:SetVisible(false)
    self.preview_overlay:SetMouseVisible(true)
    self.preview_overlay:SetZOrder(1000)
    self.preview_overlay:SetBackColor(Style.PREVIEW_OVERLAY_BACKGROUND)

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(false)
    self.inner:SetBackColor(Style.CONTROL_BACKGROUND)

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self.inner)
    self.title:SetMouseVisible(false)
    self.title:SetSelectable(false)
    self.title:SetForeColor(Style.FOREGROUND)
    self.title:SetFont(_scaled_font(Style.FONT_H1_NAME, Style.FONT_H1_SIZE))
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.title:SetText(TR["LUI"])

    self.title_rule = Turbine.UI.Control()
    self.title_rule:SetParent(self.inner)
    self.title_rule:SetMouseVisible(false)
    self.title_rule:SetBackColor(Style.CONTROL_BORDER)

    self.body = UI.Widgets.LuiLabel()
    self.body:SetParent(self.inner)
    self.body:SetMouseVisible(false)
    self.body:SetSelectable(false)
    self.body:SetMultiline(true)
    self.body:SetFont(_scaled_font(Style.CONTENT_LARGE_FONT_NAME, Style.CONTENT_LARGE_FONT_SIZE))
    self.body:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    self.body:SetForeColor(Style.FOREGROUND)

    self.scale_minus = UI.Widgets.LuiButton()
    self.scale_minus:SetParent(self.inner)
    self.scale_minus:set_text("-")
    self.scale_minus.Click = function()
        self:adjust_scale(-0.05)
    end

    self.scale_box = UI.Widgets.LuiLineEdit()
    self.scale_box:SetParent(self.inner)
    self.scale_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.scale_box:SetWantsKeyEvents(true)
    self.scale_box.TextChanged = function()
        if self.updating_scale_text == true then
            return
        end

        local trimmed = _trim_submit_suffix(self.scale_box:GetText())
        if trimmed ~= nil then
            self.updating_scale_text = true
            self.scale_box:SetText(trimmed)
            self.updating_scale_text = false
            self:apply_scale_from_input()
        end
    end
    self.scale_box.FocusLost = function()
        self:apply_scale_from_input()
    end

    self.scale_plus = UI.Widgets.LuiButton()
    self.scale_plus:SetParent(self.inner)
    self.scale_plus:set_text("+")
    self.scale_plus.Click = function()
        self:adjust_scale(0.05)
    end

    self.config_dropdown = UI.Widgets.LuiDropdown()
    self.config_dropdown:SetParent(self.inner)
    self.config_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.config_dropdown:SetPopupHost(self)
    self.config_dropdown:SetMappedOptions(self.existing_config_labels, self.existing_config_values)

    self.layout_label = UI.Widgets.LuiLabel()
    self.layout_label:SetParent(self.inner)
    self.layout_label:SetMouseVisible(false)
    self.layout_label:SetSelectable(false)
    self.layout_label:SetMultiline(true)
    self.layout_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    self.layout_label:SetForeColor(Style.FOREGROUND)

    self.layout_bottom = UI.Widgets.LuiButton()
    self.layout_bottom:SetParent(self.inner)
    self.layout_bottom:set_text(TR["Bottom layout"])
    self.layout_bottom.Click = function()
        self:select_layout("bottom")
    end

    self.layout_top = UI.Widgets.LuiButton()
    self.layout_top:SetParent(self.inner)
    self.layout_top:set_text(TR["Top layout"])
    self.layout_top.Click = function()
        self:select_layout("top")
    end

    self.choice_no = UI.Widgets.LuiButton()
    self.choice_no:SetParent(self.inner)
    self.choice_no:set_text(TR["No"])
    self.choice_no.Click = function()
        self:select_binary_choice(false)
    end

    self.choice_yes = UI.Widgets.LuiButton()
    self.choice_yes:SetParent(self.inner)
    self.choice_yes:set_text(TR["Yes"])
    self.choice_yes.Click = function()
        self:select_binary_choice(true)
    end

    self.use_button = UI.Widgets.LuiButton()
    self.use_button:SetParent(self.inner)
    self.use_button:set_text(TR["Use"])
    self.use_button.Click = function()
        self:use_selected_configuration()
    end

    self.new_button = UI.Widgets.LuiButton()
    self.new_button:SetParent(self.inner)
    self.new_button:set_text(TR["New"])
    self.new_button.Click = function()
        self:go_next()
    end

    self.cancel_button = UI.Widgets.LuiButton()
    self.cancel_button:SetParent(self.inner)
    self.cancel_button:set_text(TR["Cancel"])
    self.cancel_button.Click = function()
        self:cancel_setup()
    end

    self.next_button = UI.Widgets.LuiButton()
    self.next_button:SetParent(self.inner)
    self.next_button:set_text(TR["Next"])
    self.next_button.Click = function()
        self:go_next()
    end

    self.done_button = UI.Widgets.LuiButton()
    self.done_button:SetParent(self.inner)
    self.done_button:set_text(TR["Done"])
    self.done_button.Click = function()
        self:finish_done()
    end

    self.move_manually_button = UI.Widgets.LuiButton()
    self.move_manually_button:SetParent(self.inner)
    self.move_manually_button:set_text(TR["Move"])
    self.move_manually_button.Click = function()
        self:finish_move_manually()
    end

    self.settings_button = UI.Widgets.LuiButton()
    self.settings_button:SetParent(self.inner)
    self.settings_button:set_text(TR["Settings"])
    self.settings_button.Click = function()
        self:finish_settings()
    end

    self.SizeChanged = function()
        self:layout()
    end

    self.VisibleChanged = function()
        if self:IsVisible() == true then
            self:bring_to_front()
            self:center()
            return
        end

        self.preview_overlay:SetVisible(false)

        if self.closing == true then
            return
        end

        self:cancel_setup()
    end

    self:set_scale_text(self.selected_scale)
    self:apply_ui_scale()
    self:update_step()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function FirstRunQuickSetup:open()
    self:SetVisible(true)
    self:bring_to_front()
    self:center()
end

function FirstRunQuickSetup:bring_to_front()
    self:SetZOrder(1500)
    if self.preview_overlay ~= nil then
        self.preview_overlay:SetZOrder(1000)
    end
end

function FirstRunQuickSetup:center()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local w, h = self:GetSize()

    self:SetPosition(math.floor((display_w - w) / 2), math.floor((display_h - h) / 2))

    if self.preview_overlay ~= nil then
        self.preview_overlay:SetPosition(0, 0)
        self.preview_overlay:SetSize(display_w, display_h)
    end
end

function FirstRunQuickSetup:_body_text_max_width()
    local width = _scaled_int(WINDOW_W) - (FRAME_BORDER * 2) - (_scaled_int(WINDOW_MARGIN) * 2)
    return math.max(1, width)
end

function FirstRunQuickSetup:_set_body_text(text, min_height)
    self._body_raw_text = text
    self._body_min_h = min_height

    local wrapped_text, line_count = _wrap_text_for_width(text, self:_body_text_max_width())
    self._body_h = _body_height_for_lines(line_count, min_height)
    self.body:SetText(wrapped_text)
end

function FirstRunQuickSetup:_window_height_for_content()
    local body_h = self._body_h
    local content_bottom = BODY_TOP + body_h

    if self._layout_mode == "config" then
        content_bottom = content_bottom + BODY_CONTROL_GAP + CONFIG_DROPDOWN_H
    elseif self._layout_mode == "layout" then
        content_bottom = content_bottom + BODY_LABEL_GAP + LAYOUT_LABEL_H + BODY_LABEL_GAP + LAYOUT_BUTTON_H
    elseif self._layout_mode == "scale" then
        content_bottom = content_bottom + BODY_CONTROL_GAP + BUTTON_H
    elseif self._layout_mode == "choice" then
        content_bottom = content_bottom + BODY_CONTROL_GAP + LAYOUT_BUTTON_H
    end

    local inner_h = content_bottom + BOTTOM_BUTTON_GAP + BUTTON_H + WINDOW_MARGIN
    return math.max(WINDOW_H, inner_h + (FRAME_BORDER * 2))
end

function FirstRunQuickSetup:_fit_window_to_content()
    self._window_h = self:_window_height_for_content()
    self:SetSize(_scaled_int(WINDOW_W), _scaled_int(self._window_h))
    self:layout()
    if self:IsVisible() == true then
        self:center()
    end
end

function FirstRunQuickSetup:apply_ui_scale()
    self:SetSize(_scaled_int(WINDOW_W), _scaled_int(self._window_h or WINDOW_H))

    local title_font = _scaled_font(Style.FONT_H1_NAME, Style.FONT_H1_SIZE)
    local body_font = _scaled_font(Style.CONTENT_LARGE_FONT_NAME, Style.CONTENT_LARGE_FONT_SIZE)
    local hint_font = _scaled_font(Style.CONTENT_MEDIUM_FONT_NAME, Style.CONTENT_MEDIUM_FONT_SIZE)
    local button_font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE)

    self.title:SetFont(title_font)

    self.body:SetFont(body_font)
    self.layout_label:SetFont(hint_font)
    self.scale_box:SetFont(body_font)
    self.config_dropdown:SetFont(body_font)
    self.config_dropdown:set_scale(State.settings.global.scale)

    self.scale_minus:set_font(button_font)
    self.scale_plus:set_font(button_font)
    self.use_button:set_font(button_font)
    self.new_button:set_font(button_font)
    self.cancel_button:set_font(button_font)
    self.next_button:set_font(button_font)
    self.done_button:set_font(button_font)
    self.move_manually_button:set_font(button_font)
    self.settings_button:set_font(button_font)
    self.layout_bottom:set_font(button_font)
    self.layout_top:set_font(button_font)
    self.choice_no:set_font(button_font)
    self.choice_yes:set_font(button_font)

    self:_set_body_text(self._body_raw_text, self._body_min_h)
    self:_fit_window_to_content()
end

function FirstRunQuickSetup:cancel_setup()
    self.closing = true

    self:_cleanup_preview(true)
    self:restore_initial_settings()
    Persistence.save_settings()

    self.preview_overlay:SetVisible(false)
    self:SetVisible(false)
    Windows.first_run_quick_setup = nil
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function FirstRunQuickSetup:layout()
    local w, h = self:GetSize()
    local border = FRAME_BORDER
    self.inner:SetPosition(border, border)
    self.inner:SetSize(w - (border * 2), h - (border * 2))

    local inner_w, inner_h = self.inner:GetSize()
    local margin = _scaled_int(WINDOW_MARGIN)
    local title_top = _scaled_int(TITLE_TOP)
    local title_h = _scaled_int(TITLE_H)
    local title_rule_y = title_top + title_h + _scaled_int(TITLE_RULE_GAP)
    local body_top = _scaled_int(BODY_TOP)
    local body_h = _scaled_int(self._body_h or BODY_H)
    local button_w = _scaled_int(BUTTON_W)
    local button_h = _scaled_int(BUTTON_H)
    local button_gap = _scaled_int(BUTTON_GAP)
    local control_gap = _scaled_int(BODY_CONTROL_GAP)
    local label_gap = _scaled_int(BODY_LABEL_GAP)

    self.title:SetPosition(margin, title_top)
    self.title:SetSize(inner_w - (margin * 2), title_h)

    self.title_rule:SetPosition(margin, title_rule_y)
    self.title_rule:SetSize(inner_w - (margin * 2), 1)

    self.body:SetPosition(margin, body_top)
    self.body:SetSize(inner_w - (margin * 2), body_h)

    local body_bottom = body_top + body_h
    local control_row_y = body_bottom + control_gap
    local scale_button_w = _scaled_int(SCALE_BUTTON_W)
    local scale_input_w = _scaled_int(SCALE_INPUT_W)
    local scale_input_h = _scaled_int(SCALE_INPUT_H)
    local scale_row_w = (scale_button_w * 2) + scale_input_w + (button_gap * 2)
    local scale_row_x = math.floor((inner_w - scale_row_w) / 2)
    local scale_input_y = control_row_y + math.floor((button_h - scale_input_h) / 2)

    self.scale_minus:SetPosition(scale_row_x, control_row_y)
    self.scale_minus:SetSize(scale_button_w, button_h)
    self.scale_box:SetPosition(scale_row_x + scale_button_w + button_gap, scale_input_y)
    self.scale_box:SetSize(scale_input_w, scale_input_h)
    self.scale_plus:SetPosition(scale_row_x + scale_button_w + button_gap + scale_input_w + button_gap, control_row_y)
    self.scale_plus:SetSize(scale_button_w, button_h)

    local config_dropdown_w = _scaled_int(CONFIG_DROPDOWN_W)
    local config_dropdown_h = _scaled_int(CONFIG_DROPDOWN_H)
    local config_dropdown_x = math.floor((inner_w - config_dropdown_w) / 2)
    local config_dropdown_y = control_row_y + math.floor((button_h - config_dropdown_h) / 2)
    self.config_dropdown:SetPosition(config_dropdown_x, config_dropdown_y)
    self.config_dropdown:SetSize(config_dropdown_w, config_dropdown_h)

    local layout_label_y = body_bottom + label_gap
    local layout_label_h = _scaled_int(LAYOUT_LABEL_H)
    self.layout_label:SetPosition(margin, layout_label_y)
    self.layout_label:SetSize(inner_w - (margin * 2), layout_label_h)

    local layout_button_w = _scaled_int(LAYOUT_BUTTON_W)
    local layout_button_h = _scaled_int(LAYOUT_BUTTON_H)
    local layout_row_y = layout_label_y + layout_label_h + label_gap
    local layout_row_w = (layout_button_w * 2) + button_gap
    local layout_row_x = math.floor((inner_w - layout_row_w) / 2)

    self.layout_bottom:SetPosition(layout_row_x, layout_row_y)
    self.layout_bottom:SetSize(layout_button_w, layout_button_h)
    self.layout_top:SetPosition(layout_row_x + layout_button_w + button_gap, layout_row_y)
    self.layout_top:SetSize(layout_button_w, layout_button_h)
    self.choice_no:SetPosition(layout_row_x, control_row_y)
    self.choice_no:SetSize(layout_button_w, layout_button_h)
    self.choice_yes:SetPosition(layout_row_x + layout_button_w + button_gap, control_row_y)
    self.choice_yes:SetSize(layout_button_w, layout_button_h)

    local bottom_y = inner_h - margin - button_h
    self.cancel_button:SetPosition(margin, bottom_y)
    self.cancel_button:SetSize(button_w, button_h)

    self.next_button:SetPosition(inner_w - margin - button_w, bottom_y)
    self.next_button:SetSize(button_w, button_h)

    local import_row_w = (button_w * 2) + button_gap
    local import_row_x = math.floor((inner_w - import_row_w) / 2)
    self.use_button:SetPosition(import_row_x, bottom_y)
    self.use_button:SetSize(button_w, button_h)
    self.new_button:SetPosition(import_row_x + button_w + button_gap, bottom_y)
    self.new_button:SetSize(button_w, button_h)

    self.done_button:SetSize(button_w, button_h)

    local action_gap = button_gap
    local action_row_w = (button_w * 3) + (action_gap * 2)
    if action_row_w > inner_w then
        action_gap = math.floor((inner_w - (button_w * 3)) / 2)
        if action_gap < 0 then
            action_gap = 0
        end
        action_row_w = (button_w * 3) + (action_gap * 2)
    end
    local action_row_x = math.floor((inner_w - action_row_w) / 2)
    if action_row_x < 0 then
        action_row_x = 0
    end

    self.move_manually_button:SetPosition(action_row_x, bottom_y)
    self.move_manually_button:SetSize(button_w, button_h)
    self.settings_button:SetPosition(action_row_x + button_w + action_gap, bottom_y)
    self.settings_button:SetSize(button_w, button_h)
    self.done_button:SetPosition(action_row_x + (button_w * 2) + (action_gap * 2), bottom_y)
end

function FirstRunQuickSetup:capture_preview_window_snapshots()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local specs = _get_preview_window_specs()
    local snapshots = {}

    for i = 1, #specs do
        local spec = specs[i]
        local window = spec.get_window()
        if window ~= nil and window.GetPosition ~= nil and window.GetSize ~= nil then
            local left, top = window:GetPosition()
            local width, height = window:GetSize()
            if type(left) == "number" and type(top) == "number" and
                type(width) == "number" and type(height) == "number" and
                width > 0 and height > 0 then
                snapshots[#snapshots + 1] = {
                    spec = spec,
                    left = left,
                    top = top,
                    width = width,
                    height = height,
                    left_ratio = _get_edge_ratio(left, width, display_w),
                    top_ratio = _get_edge_ratio(top, height, display_h),
                }
            end
        end
    end

    return snapshots
end

function FirstRunQuickSetup:apply_preview_window_snapshots(snapshots)
    if snapshots == nil then
        return
    end

    local display_w, display_h = Turbine.UI.Display.GetSize()
    for i = 1, #snapshots do
        local snapshot = snapshots[i]
        local window = snapshot.spec.get_window()
        local raw_window = snapshot.spec.get_raw_window()
        if window ~= nil and raw_window ~= nil and window.GetPosition ~= nil and window.GetSize ~= nil then
            local width, height = window:GetSize()
            if type(width) == "number" and type(height) == "number" and
                width > 0 and height > 0 then
                local next_left = snapshot.left - ((width - snapshot.width) * snapshot.left_ratio)
                local next_top = snapshot.top - ((height - snapshot.height) * snapshot.top_ratio)
                next_left = _clamp_window_pos(next_left, width, display_w)
                next_top = _clamp_window_pos(next_top, height, display_h)
                window:SetPosition(next_left, next_top)
                raw_window.left = next_left
                raw_window.top = next_top
            end
        end
    end
end

function FirstRunQuickSetup:apply_preview_layout(layout_key, scale)
    local preserved_config_geometry = self:get_preserved_config_geometry()
    local base_scale = 1.35
    if DefaultLayouts ~= nil and DefaultLayouts.get_base_scale ~= nil then
        base_scale = DefaultLayouts.get_base_scale()
    end

    local snapshots = nil
    if scale ~= base_scale then
        State.loaded_settings = DefaultLayouts.build(layout_key, base_scale, preserved_config_geometry)
        State.loaded_settings.launcher.enabled = self.selected_launcher_enabled
        _apply_runtime_settings()
        snapshots = self:capture_preview_window_snapshots()
    end

    State.loaded_settings = DefaultLayouts.build(layout_key, scale, preserved_config_geometry)
    State.loaded_settings.launcher.enabled = self.selected_launcher_enabled
    _apply_runtime_settings()

    if snapshots ~= nil then
        self:apply_preview_window_snapshots(snapshots)
    end
end

function FirstRunQuickSetup:update_step()
    self.body:SetVisible(true)
    self.scale_minus:SetVisible(false)
    self.scale_box:SetVisible(false)
    self.scale_plus:SetVisible(false)
    self.config_dropdown:SetVisible(false)
    self.layout_label:SetVisible(false)
    self.layout_bottom:SetVisible(false)
    self.layout_top:SetVisible(false)
    self.choice_no:SetVisible(false)
    self.choice_yes:SetVisible(false)
    self.use_button:SetVisible(false)
    self.new_button:SetVisible(false)
    self.cancel_button:SetVisible(false)
    self.next_button:SetVisible(false)
    self.done_button:SetVisible(false)
    self.move_manually_button:SetVisible(false)
    self.settings_button:SetVisible(false)

    if self.has_existing_configurations == true and self.step == 1 then
        self._layout_mode = "config"
        self:_set_body_text(TR["Do you want to use an existing configuration?"], BODY_H)
        self.config_dropdown:SetVisible(true)
        self.use_button:SetVisible(true)
        self.new_button:SetVisible(true)
        self:_fit_window_to_content()
        return
    end

    local setup_step = self.step
    if self.has_existing_configurations == true then
        setup_step = setup_step - 1
    end

    if setup_step == 1 then
        self._layout_mode = nil
        self:_set_body_text(table.concat({
            TR["Thank you for using LUI."],
            TR["We will guide you through a few short steps."],
        }, "\n"), BODY_INTRO_H)

        self.cancel_button:SetVisible(true)
        self.next_button:SetVisible(true)
        self:_fit_window_to_content()
        return
    end

    self:ensure_preview_mode()

    if setup_step == 2 then
        if self.selected_layout == nil then
            self:select_layout("bottom")
        end

        self._layout_mode = "layout"
        self:_set_body_text(TR["Which layout do you prefer?"], BODY_H)
        self.layout_label:SetText(TR["Pick the closest layout."])
        self.layout_label:SetVisible(true)
        self.layout_bottom:SetVisible(true)
        self.layout_top:SetVisible(true)
        self.next_button:SetVisible(true)
        self:_fit_window_to_content()
        return
    end

    if self.selected_layout == nil then
        self:select_layout("bottom")
    end

    if setup_step == 4 then
        self._layout_mode = "choice"
        self:_set_body_text(TR["Replace the default inventory bags?"], BODY_H)
        self:update_binary_choice_buttons(State.loaded_settings.inventory.replace == true)
        self.choice_no:SetVisible(true)
        self.choice_yes:SetVisible(true)
        self.next_button:SetVisible(true)
        self:_fit_window_to_content()
        return
    end

    if setup_step == 3 then
        self._layout_mode = "scale"
        self:_set_body_text(TR["Select your scaling."], BODY_H)
        self.scale_minus:SetVisible(true)
        self.scale_box:SetVisible(true)
        self.scale_plus:SetVisible(true)
        self.next_button:SetVisible(true)
        self:_fit_window_to_content()
        return
    end

    if setup_step == 5 then
        self._layout_mode = "choice"
        self:_set_body_text(TR["Enable the status bar?"], BODY_H)
        self:update_binary_choice_buttons(State.loaded_settings.status_bar.enabled == true)
        self.choice_no:SetVisible(true)
        self.choice_yes:SetVisible(true)
        self.next_button:SetVisible(true)
        self:_fit_window_to_content()
        return
    end

    if setup_step == 6 then
        self._layout_mode = "choice"
        self:_set_body_text(TR["Enable the LUI Menu?"], BODY_H)
        self:update_binary_choice_buttons(self.selected_launcher_enabled == true)
        self.choice_no:SetVisible(true)
        self.choice_yes:SetVisible(true)
        self.next_button:SetVisible(true)
        self:_fit_window_to_content()
        return
    end

    self._layout_mode = nil
    self:_set_body_text(TR["Do you want to modify anything else?"], BODY_FINAL_H)
    self.done_button:SetVisible(true)
    self.move_manually_button:SetVisible(true)
    self.settings_button:SetVisible(true)
    self:_fit_window_to_content()
end

function FirstRunQuickSetup:go_next()
    local max_step = self.has_existing_configurations == true and 8 or 7
    if self.step >= max_step then
        return
    end
    self.step = self.step + 1
    self:update_step()
end

function FirstRunQuickSetup:use_selected_configuration()
    local profile_id = self.config_dropdown:GetValue()
    if profile_id == nil then
        return
    end

    if Persistence.assign_character_profile(profile_id) ~= true then
        return
    end

    State.loaded_settings_was_new = false
    _apply_runtime_settings()
    self.closing = true
    Persistence.save_settings()
    self.preview_overlay:SetVisible(false)
    self:SetVisible(false)
    Windows.first_run_quick_setup = nil
end

function FirstRunQuickSetup:set_scale_text(value)
    self.updating_scale_text = true
    self.scale_box:SetText(_format_scale(value))
    self.updating_scale_text = false
end

function FirstRunQuickSetup:apply_scale_from_input()
    local scale = _clamp_scale(self.scale_box:GetText())
    if scale == nil then
        self:set_scale_text(self.selected_scale)
        return
    end

    self:set_selected_scale(scale)
end

function FirstRunQuickSetup:adjust_scale(delta)
    local scale = _clamp_scale((self.selected_scale or 1) + delta)
    if scale == nil then
        return
    end

    self:set_selected_scale(scale)
end

function FirstRunQuickSetup:set_selected_scale(scale)
    if scale == nil then
        return
    end

    self.selected_scale = scale
    self:set_scale_text(scale)
    local layout_key = self.selected_layout or "bottom"
    self:apply_preview_layout(layout_key, scale)
    MoveMode.refresh_snapshot()
    self:apply_ui_scale()
end

function FirstRunQuickSetup:get_preserved_config_geometry()
    if State.loaded_settings == nil then
        return nil
    end

    return DefaultLayouts.copy_table(Defaults.get_ui_window_state("config"))
end

function FirstRunQuickSetup:select_layout(layout_key)
    self:apply_preview_layout(layout_key, self.selected_scale)

    self.selected_layout = layout_key
    self.layout_bottom:set_active(layout_key == "bottom")
    self.layout_top:set_active(layout_key == "top")

    MoveMode.refresh_snapshot()

    self:apply_ui_scale()
end

function FirstRunQuickSetup:update_binary_choice_buttons(enabled)
    self.choice_no:set_active(enabled ~= true)
    self.choice_yes:set_active(enabled == true)
end

function FirstRunQuickSetup:select_binary_choice(enabled)
    local value = enabled == true
    local setup_step = self.step
    if self.has_existing_configurations == true then
        setup_step = setup_step - 1
    end

    if setup_step == 4 then
        State.loaded_settings.inventory.replace = value
    elseif setup_step == 5 then
        State.loaded_settings.status_bar.enabled = value
    elseif setup_step == 6 then
        self.selected_launcher_enabled = value
        State.loaded_settings.launcher.enabled = value
    else
        return
    end

    self:update_binary_choice_buttons(value)
    _apply_runtime_settings()

    MoveMode.refresh_snapshot()

    self:apply_ui_scale()
end

function FirstRunQuickSetup:restore_initial_settings()
    if self.previous_profile_id ~= nil then
        Persistence.assign_character_profile(self.previous_profile_id)
    end

    State.loaded_settings = DefaultLayouts.copy_table(self.initial_settings)
    _apply_runtime_settings()
    self.selected_scale = State.loaded_settings.global.scale
    self.selected_layout = nil
    self.selected_launcher_enabled = true
    self.layout_bottom:set_active(false)
    self.layout_top:set_active(false)
    self:set_scale_text(self.selected_scale)
    self:apply_ui_scale()
end

function FirstRunQuickSetup:ensure_finish_profile()
    if self.create_profile_on_finish ~= true then
        return true
    end

    if self.created_profile_id ~= nil then
        return true
    end

    local profile_name = self.profile_name
    if type(profile_name) ~= "string" or string.len(profile_name) == 0 then
        profile_name = State.current_character_name
    end

    local profile_id = Persistence.create_configuration(profile_name, State.loaded_settings)
    if Persistence.assign_character_profile(profile_id) ~= true then
        return false
    end

    self.created_profile_id = profile_id
    return true
end

function FirstRunQuickSetup:commit_preview_settings()
    State.loaded_settings.global.scale = self.selected_scale
    Defaults.ensure_loaded_settings()

    _persist_window_position(Windows.player_vital, Defaults.get_ui_hud_state("self_vitals"))
    _persist_window_position(Windows.target_vital, Defaults.get_ui_hud_state("target_vitals"))
    _persist_window_position(Windows.boss_vital, Defaults.get_ui_hud_state("boss_vitals"))
    _persist_window_position(Windows.fellowship_vitals, Defaults.get_ui_hud_state("fellowship_vitals"))
    _persist_window_position(Windows.raid_vitals, Defaults.get_ui_hud_state("raid_vitals"))
    if Windows.raid_vitals ~= nil then
        _persist_window_position(Windows.raid_vitals.group_windows[1], Defaults.get_ui_hud_state("raid_group_a_vitals"))
        _persist_window_position(Windows.raid_vitals.group_windows[2], Defaults.get_ui_hud_state("raid_group_b_vitals"))
        _persist_window_position(Windows.raid_vitals.group_windows[3], Defaults.get_ui_hud_state("raid_group_c_vitals"))
        _persist_window_position(Windows.raid_vitals.group_windows[4], Defaults.get_ui_hud_state("raid_group_d_vitals"))
    end
    _persist_window_position(Windows.expiring_self_effects, Defaults.get_ui_hud_state("self_effects"))
    _persist_window_position(Windows.expiring_target_effects, Defaults.get_ui_hud_state("target_effects"))
    _persist_window_position(Windows.cooldowns, Defaults.get_ui_hud_state("cooldowns"))
    _persist_window_position(Windows.launcher, Defaults.get_ui_hud_state("launcher"))

    if Windows.target_vital ~= nil and Windows.target_vital.targets_target_window ~= nil then
        _persist_window_position(Windows.target_vital.targets_target_window, Defaults.get_ui_hud_state("target_target_vitals"))
    end

    if Windows.config ~= nil and Windows.config.GetPosition ~= nil and Windows.config.GetSize ~= nil then
        local left, top = Windows.config:GetPosition()
        local width, height = Windows.config:GetSize()
        local window = Defaults.get_ui_window_state("config")
        window.left = left
        window.top = top
        window.width = width
        window.height = height
    end
end

function FirstRunQuickSetup:ensure_preview_mode()
    if Windows.player_vital == nil or Windows.player_vital.is_move_mode == nil then
        return
    end

    if Hidable.is_lui_hud_visible() ~= true then
        Hidable.set_lui_hud_visible(true)
    end

    if Windows.player_vital:is_move_mode() ~= true then
        MoveMode.set_mode(true)
    end

    if Windows.player_vital:is_move_mode() ~= true then
        return
    end

    MoveMode.set_preview_lock(true)

    self.preview_overlay:SetVisible(true)
    self:bring_to_front()
    self:center()
end

function FirstRunQuickSetup:_cleanup_preview(cancel_changes)
    MoveMode.set_preview_lock(false)

    self.preview_overlay:SetVisible(false)

    if Windows.player_vital ~= nil and Windows.player_vital.is_move_mode ~= nil and Windows.player_vital:is_move_mode() == true then
        if cancel_changes == true then
            MoveMode.cancel()
        elseif cancel_changes ~= true then
            MoveMode.set_mode(false)
        end
    end
end

function FirstRunQuickSetup:finish_done()
    self:commit_preview_settings()
    if self:ensure_finish_profile() ~= true then
        return
    end
    self.closing = true
    self:_cleanup_preview(false)
    Persistence.save_settings()
    self:SetVisible(false)
    Windows.first_run_quick_setup = nil
end

function FirstRunQuickSetup:finish_move_manually()
    self:commit_preview_settings()
    if self:ensure_finish_profile() ~= true then
        return
    end
    self.closing = true

    MoveMode.set_preview_lock(false)
    self.preview_overlay:SetVisible(false)

    MoveMode.refresh_snapshot()
    Persistence.save_settings()

    self:SetVisible(false)
    Windows.first_run_quick_setup = nil
end

function FirstRunQuickSetup:finish_settings()
    self:commit_preview_settings()
    if self:ensure_finish_profile() ~= true then
        return
    end
    self.closing = true
    self:_cleanup_preview(false)
    Persistence.save_settings()
    self:SetVisible(false)
    Windows.first_run_quick_setup = nil

    if Windows.config ~= nil then
        Windows.config:open("global")
    end
end
