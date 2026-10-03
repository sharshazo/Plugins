-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local Lore = _G.LUI.Data.Lore
local Upkeep = _G.LUI.Features.Upkeep
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Style = UI.Widgets.Style
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Data.lore_db"
import "LUI.src.Upkeep.skill_lookup"
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Utils.chat"

local lui_warn = _G.LUI.Utils.lui_warn

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local MAX_SLOTS = 12
-- cells follow the settings grid: same column count as the other tabs'
-- ConfigContent(window, 4), same window.col_gap between columns
local GRID_COLUMNS = 4
local QS_SIZE = 36
local NAME_H = 12
local MARKER_H = 11
-- base of window.input_height: the mode dropdown and Clear button use the
-- standard settings input size (this constant only feeds the unscaled
-- base-height math; the scaled layout reads window.input_height itself)
local CONTROL_H = 21
local ROW_GAP = 8

-- even sides pair with even containers for exact pixel centering
local function _even_scaled(value)
    local out = scaled_int(value)
    if out % 2 ~= 0 then
        out = out - 1
    end
    return out
end

-- Both take the record the caller already decoded: buffs_of() binary-searches
-- and allocates a fresh record per call, so a cell decodes once and the three
-- consumers share it.
--
-- The skills DB holds every player skill, so a missing record means the drop
-- was not a skill the player can own. Refused at drop time; this only labels
-- bindings saved before that check existed.
local function _slot_name_text(record, bound)
    if bound ~= true then
        return ""
    end
    if record == nil then
        return TR["Not a buff skill"]
    end
    return record.name
end

-- Second line under the name: a skill that applies no visible buff still
-- binds and tracks its cooldown, but the slot can never light up, so say so
-- rather than leaving it looking like a buff that never fires. (The watch
-- mode needs no marker: the Self/Target dropdown below already shows it.)
local function _slot_marker_text(record, bound)
    if bound ~= true or record == nil or #record.effects > 0 then
        return ""
    end
    return TR["Cooldown only"]
end

-- localized skill name -> the trained skill to show for it. Built once per
-- refresh instead of once per cell: laying out 12 cells used to walk the whole
-- trained-skill list 12 times, calling GetSkillInfo()/GetName() on every entry.
local function _build_trained_index()
    local index = {}
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetTrainedSkills == nil then
        return index
    end
    local list = player:GetTrainedSkills()
    if list == nil or list.GetCount == nil or list.GetItem == nil then
        return index
    end

    local now = Turbine.Engine.GetGameTime()
    for i = 1, (list:GetCount() or 0) do
        local skill = list:GetItem(i)
        if skill ~= nil and skill.GetSkillInfo ~= nil then
            local info = skill:GetSkillInfo()
            if info ~= nil and info.GetName ~= nil then
                local name = info:GetName()
                -- same pick as the bar, so both show the same variant
                index[name] = Upkeep.prefer_trained_skill(index[name], skill, now)
            end
        end
    end
    return index
end

-- Rank and trait variants are distinct skill ids sharing one name, and the
-- game exposes no id on a trained skill to tell them apart, so with two
-- trained skills of the same name the cooldown shown may be the other one's.
-- Measured to be rare (a character trains one variant), hence a warning
-- rather than a guess -- printed here, once per deliberate drop, never from
-- the bar's periodic rediscovery.
local function _warn_if_ambiguous(name)
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetTrainedSkills == nil then
        return
    end
    local list = player:GetTrainedSkills()
    if list == nil or list.GetCount == nil or list.GetItem == nil then
        return
    end

    local count = 0
    for i = 1, (list:GetCount() or 0) do
        local skill = list:GetItem(i)
        if skill ~= nil and skill.GetSkillInfo ~= nil then
            local info = skill:GetSkillInfo()
            if info ~= nil and info.GetName ~= nil and info:GetName() == name then
                count = count + 1
            end
        end
    end
    if count > 1 then
        -- concatenated, not string.format: the message body is translated,
        -- and a translator dropping or reordering a format specifier would
        -- otherwise raise out of the drop handler and eat the binding
        lui_warn(TR["Upkeep: several trained skills share this name, the cooldown shown may be the wrong one"]
            .. " (" .. name .. " x" .. tostring(count) .. ")")
    end
end

-- The bound skill's icon image id: the trained skill's own icon, falling back
-- to the skill's first buff icon from the skills DB when the character has not
-- trained it (and to nothing when it grants no buff either).
local function _skill_icon_id(record, trained)
    if record == nil then
        return nil
    end

    local found = trained[record.name]
    if found ~= nil and found.GetSkillInfo ~= nil then
        local info = found:GetSkillInfo()
        if info ~= nil and info.GetIconImageID ~= nil then
            return info:GetIconImageID()
        end
    end

    local effect = record.effects[1]
    if effect ~= nil then
        return effect.icon
    end
    return nil
end

-- The slot editor: one skill drop area per Upkeep slot, with the bound
-- skill's name and a clear button underneath. Bindings live in the editor
-- until Apply writes them back to settings (same transactional model as
-- every other control on the page).
local function _create_slots_editor(content, window, get_count)
    local entry = content:add_custom("upkeep_slots_editor", 150)
    entry._slots = {}
    entry._modes = {}
    entry._cells = {}

    for i = 1, MAX_SLOTS do
        local cell = {}

        cell.holder = Turbine.UI.Control()
        cell.holder:SetParent(entry.control)
        cell.holder:SetMouseVisible(false)
        cell.holder:SetVisible(false)

        -- a border ring marks the drop target; the bound skill's icon is
        -- drawn by our own image on top
        cell.frame = Turbine.UI.Control()
        cell.frame:SetParent(cell.holder)
        cell.frame:SetMouseVisible(false)
        cell.frame:SetBackColor(Style.CONTROL_BORDER)

        cell.frame_inner = Turbine.UI.Control()
        cell.frame_inner:SetParent(cell.frame)
        cell.frame_inner:SetMouseVisible(false)
        cell.frame_inner:SetBackColor(Style.BACKGROUND)

        -- a plain drop area, never a quickslot: the game hands the dragged
        -- shortcut to any control via DragDrop args, while quickslot
        -- socketing is blocked by client-side quickslot state for some
        -- players
        cell.drop = Turbine.UI.Control()
        cell.drop:SetParent(cell.holder)
        if cell.drop.SetAllowDrop ~= nil then
            cell.drop:SetAllowDrop(true)
        end

        cell.icon = UI.Widgets.Image()
        cell.icon:SetParent(cell.drop)

        cell.name = UI.Widgets.LuiLabel()
        cell.name:SetParent(cell.holder)
        cell.name:SetMouseVisible(false)
        cell.name:SetSelectable(false)
        cell.name:SetMultiline(false)
        cell.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        cell.name:SetFont(window.field_label_font)

        cell.marker = UI.Widgets.LuiLabel()
        cell.marker:SetParent(cell.holder)
        cell.marker:SetMouseVisible(false)
        cell.marker:SetSelectable(false)
        cell.marker:SetMultiline(false)
        cell.marker:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        cell.marker:SetFont(window.field_label_font)
        cell.marker:SetForeColor(Style.INFO_FOREGROUND)

        cell.clear = UI.Widgets.LuiButton()
        cell.clear:SetParent(cell.holder)
        cell.clear:set_scale(State.settings.global.scale)
        cell.clear:set_font(window.input_font)
        cell.clear:set_text(TR["Clear"])

        -- where this slot watches its buffs: standard settings dropdown,
        -- same look and size as every other dropdown in the config window
        cell.mode = UI.Widgets.LuiDropdown()
        cell.mode:SetParent(cell.holder)
        cell.mode:set_scale(State.settings.global.scale)
        cell.mode:SetFont(window.input_font)
        cell.mode:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        cell.mode:SetPopupHost(window)
        cell.mode:SetMappedOptions(
            { TR["Self"], TR["Target"] },
            { LUI_ENUMS.upkeep_track.SELF, LUI_ENUMS.upkeep_track.TARGET })

        cell.drop.DragDrop = function(_, args)
            local info = args ~= nil and args.DragDropInfo or nil
            if info == nil or info.GetShortcut == nil then
                return
            end
            local shortcut = info:GetShortcut()
            local data = nil
            if shortcut ~= nil and shortcut.GetType ~= nil and
                shortcut:GetType() == Turbine.UI.Lotro.ShortcutType.Skill then
                data = shortcut:GetData()
            end
            if type(data) ~= "string" or tonumber(data) == nil then
                -- not a skill: ignore the drop, keep the stored binding
                return
            end

            -- Every player skill is in the skills DB, so no record means this
            -- is not a skill the player can own and nothing could ever be
            -- tracked for it. Refuse it and say why on the marker line -- the
            -- name label keeps showing the stored binding, which is untouched.
            local record = Lore.Skills.buffs_of(tonumber(data))
            if record == nil then
                cell.marker:SetText(TR["Not a buff skill"])
                return
            end

            entry._slots[i] = data
            -- the player may have trained something since the index was built
            entry._trained = nil
            entry:sync_cell(i)
            _warn_if_ambiguous(record.name)
        end

        cell.clear.Click = function()
            entry._slots[i] = ""
            -- an unbound slot has nothing to watch anywhere: back to default
            entry._modes[i] = LUI_ENUMS.upkeep_track.SELF
            entry:sync_cell(i)
        end

        cell.mode.ValueChanged = function(_, value)
            -- sync_cell writes the value back via set_value; the equality
            -- check stops that echo from looping
            if entry._modes[i] == value then
                return
            end
            entry._modes[i] = value
            entry:sync_cell(i)
        end

        entry._cells[i] = cell
    end

    function entry:sync_cell(index)
        local cell = self._cells[index]
        local did_text = self._slots[index]
        local bound = type(did_text) == "string" and tonumber(did_text) ~= nil
        local record = nil
        if bound then
            record = Lore.Skills.buffs_of(tonumber(did_text))
        end
        if self._trained == nil then
            self._trained = _build_trained_index()
        end
        local icon_id = nil
        if bound then
            icon_id = _skill_icon_id(record, self._trained)
        end
        if icon_id ~= nil then
            local qs = _even_scaled(QS_SIZE)
            cell.icon:set_icon(Turbine.UI.Graphic(icon_id), qs, qs)
        else
            cell.icon:set_icon(nil)
            cell.icon:SetVisible(false)
        end
        local mode = self._modes[index]
        if mode ~= LUI_ENUMS.upkeep_track.TARGET then
            mode = LUI_ENUMS.upkeep_track.SELF
        end
        cell.mode:set_value(mode)
        cell.mode:SetVisible(bound)
        cell.name:SetText(_slot_name_text(record, bound))
        cell.marker:SetText(_slot_marker_text(record, bound))
    end

    function entry:get_modes()
        local out = {}
        local last = 0
        for i = 1, MAX_SLOTS do
            local mode = self._modes[i]
            if mode ~= LUI_ENUMS.upkeep_track.TARGET then
                mode = LUI_ENUMS.upkeep_track.SELF
            end
            out[i] = mode
            if mode ~= LUI_ENUMS.upkeep_track.SELF then
                last = i
            end
        end
        for i = MAX_SLOTS, last + 1, -1 do
            out[i] = nil
        end
        return out
    end

    -- absent entries (older saves, trailing trim) are Self, the product
    -- default; runs before the slots bind so sync_cell reads fresh modes
    function entry:set_modes(value)
        for i = 1, MAX_SLOTS do
            local mode = type(value) == "table" and value[i] or nil
            if mode ~= LUI_ENUMS.upkeep_track.TARGET then
                mode = LUI_ENUMS.upkeep_track.SELF
            end
            self._modes[i] = mode
        end
    end

    function entry:get_value()
        local out = {}
        local last = 0
        for i = 1, MAX_SLOTS do
            local did_text = self._slots[i]
            if type(did_text) ~= "string" then
                did_text = ""
            end
            out[i] = did_text
            if did_text ~= "" then
                last = i
            end
        end
        for i = MAX_SLOTS, last + 1, -1 do
            out[i] = nil
        end
        return out
    end

    function entry:set_value(value)
        -- one walk of the trained-skill list for the whole refresh
        self._trained = _build_trained_index()
        for i = 1, MAX_SLOTS do
            local did_text = type(value) == "table" and value[i] or nil
            if type(did_text) ~= "string" then
                did_text = ""
            end
            self._slots[i] = did_text
            self:sync_cell(i)
        end
        self:layout_cells()
    end

    function entry:layout_cells()
        local count = get_count()
        local qs = _even_scaled(QS_SIZE)
        local name_h = scaled_int(NAME_H)
        local marker_h = scaled_int(MARKER_H)
        local control_h = window.input_height
        local col_gap = window.col_gap
        local row_gap = scaled_int(ROW_GAP)
        local pad = scaled_int(2)
        local border = scaled_int(Style.BORDER_WIDTH_THIN)
        local frame_size = qs + (2 * border)
        local cell_h = frame_size + pad + name_h + marker_h + pad + control_h + pad + control_h

        -- the settings grid rule: fixed column count, standard column gap,
        -- cell width identical to a field column on the 4-column tabs
        local width = entry.control:GetWidth()
        local cell_w = math.floor((width - ((GRID_COLUMNS - 1) * col_gap)) / GRID_COLUMNS)

        for i = 1, MAX_SLOTS do
            local cell = self._cells[i]
            if i <= count then
                local row = math.floor((i - 1) / GRID_COLUMNS)
                local col = (i - 1) % GRID_COLUMNS
                cell.holder:SetPosition(col * (cell_w + col_gap), row * (cell_h + row_gap))
                cell.holder:SetSize(cell_w, cell_h)

                local frame_x = math.floor((cell_w - frame_size) / 2)
                cell.frame:SetPosition(frame_x, 0)
                cell.frame:SetSize(frame_size, frame_size)
                cell.frame_inner:SetPosition(border, border)
                cell.frame_inner:SetSize(qs, qs)
                cell.drop:SetPosition(frame_x + border, border)
                cell.drop:SetSize(qs, qs)
                cell.icon:SetPosition(0, 0)
                cell.icon:set_size(qs, qs)
                cell.name:SetPosition(0, frame_size + pad)
                cell.name:SetSize(cell_w, name_h)
                cell.marker:SetPosition(0, frame_size + pad + name_h)
                cell.marker:SetSize(cell_w, marker_h)
                cell.mode:SetPosition(0, frame_size + pad + name_h + marker_h + pad)
                cell.mode:SetSize(cell_w, control_h)
                -- Clear closes the cell at the very bottom
                cell.clear:SetPosition(0, cell_h - control_h)
                cell.clear:SetSize(cell_w, control_h)

                cell.holder:SetVisible(true)
            else
                cell.holder:SetVisible(false)
            end
        end

        local rows = math.ceil(count / GRID_COLUMNS)
        local base_cell_h = QS_SIZE + (2 * Style.BORDER_WIDTH_THIN) + 2 + NAME_H + MARKER_H
            + 2 + CONTROL_H + 2 + CONTROL_H
        local base_height = (rows * base_cell_h) + ((rows - 1) * ROW_GAP) + 4
        if base_height ~= self.base_height then
            self.base_height = base_height
            self.height = scaled_int(base_height)
            content:layout()
        end
    end

    entry.apply_ui_scale = function()
        for i = 1, MAX_SLOTS do
            local cell = entry._cells[i]
            cell.name:SetFont(window.field_label_font)
            cell.marker:SetFont(window.field_label_font)
            cell.marker:SetForeColor(Style.INFO_FOREGROUND)
            cell.clear:set_scale(State.settings.global.scale)
            cell.clear:set_font(window.input_font)
            cell.mode:set_scale(State.settings.global.scale)
            cell.mode:SetFont(window.input_font)
        end
        entry:layout_cells()
    end

    entry.control.SizeChanged = function()
        entry:layout_cells()
    end

    return entry
end

local UpkeepPage = class(ConfigTabs)
Pages.UpkeepPage = UpkeepPage

function UpkeepPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self.controls = self.controls or {}

    local orientation_labels = { TR["Horizontal"], TR["Vertical"] }
    local orientation_values = { LUI_ENUMS.orientation.HORIZONTAL, LUI_ENUMS.orientation.VERTICAL }
    local time_format_labels = { TR["Auto precision"], TR["Whole seconds"] }
    local time_format_values = {
        LUI_ENUMS.cooldown_time_format.AUTO,
        LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS,
    }

    local settings_getter = function()
        return self._settings.self.upkeep
    end

    local general = ConfigContent(window, 4)
    general:add_checkbox("uk_enabled", TR["Enabled"],
        function(value)
            settings_getter().enabled = value == true
        end,
        function()
            return settings_getter().enabled == true
        end, true)
    general:add_row_break()
    general:add_dropdown("uk_orientation", TR["Orientation"], orientation_labels, orientation_values,
        function(value)
            settings_getter().orientation = value
        end,
        function()
            return settings_getter().orientation
        end)
    general:add_line_edit("uk_count", TR["Slots"],
        function(value)
            local count = tonumber(value)
            if count ~= nil then
                settings_getter().count = count
            end
        end,
        function()
            return tostring(settings_getter().count)
        end)
    general:add_line_edit("uk_icon_size", TR["Icon size (px)"],
        function(value)
            local icon_size = tonumber(value)
            if icon_size ~= nil then
                settings_getter().icon_size = icon_size
            end
        end,
        function()
            return tostring(settings_getter().icon_size)
        end)
    general:add_line_edit("uk_spacing", TR["Spacing (px)"],
        function(value)
            local spacing = tonumber(value)
            if spacing ~= nil then
                settings_getter().spacing = spacing
            end
        end,
        function()
            return tostring(settings_getter().spacing)
        end)
    general:add_row_break()
    general:add_checkbox("uk_auto_order", TR["Auto order by next activation"],
        function(value)
            settings_getter().auto_order = value == true
        end,
        function()
            return settings_getter().auto_order == true
        end)
    general:add_dropdown("uk_auto_order_anchor", TR["Next skill at"],
        { TR["Left/Top"], TR["Right/Bottom"] }, { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT },
        function(value)
            settings_getter().auto_order_anchor = value
        end,
        function()
            return settings_getter().auto_order_anchor
        end)
    self:add_tab(TR["General"], "general", general)

    local get_count = function()
        local entry = self.controls.uk_count
        local count = entry ~= nil and tonumber(entry:get_value()) or nil
        if count == nil and self._settings ~= nil then
            count = self._settings.self.upkeep.count
        end
        if count == nil then
            count = 1
        end
        count = math.floor(count + 0.5)
        if count < 1 then count = 1 end
        if count > MAX_SLOTS then count = MAX_SLOTS end
        return count
    end

    local skills = ConfigContent(window, 1)
    skills:add_info(
        TR["Drag and drop a skill icon from the game's Skills panel (or an action bar) into a slot below to bind it. Clear removes the binding."],
        34)
    local editor = _create_slots_editor(skills, window, get_count)
    -- the modes ride a value-only adapter on the same editor, so the
    -- persisted `slots` shape stays a plain array of DID strings; bound
    -- first so set_modes runs before the slots bind syncs the cells
    local modes_adapter = {}
    function modes_adapter:get_value()
        return editor:get_modes()
    end
    function modes_adapter:set_value(value)
        editor:set_modes(value)
    end
    skills:bind(modes_adapter,
        function(value)
            settings_getter().slot_modes = value
        end,
        function()
            return settings_getter().slot_modes
        end)
    skills:bind(editor,
        function(value)
            settings_getter().slots = value
        end,
        function()
            return settings_getter().slots
        end)
    self:add_tab(TR["Skills"], "skills", skills)

    -- slot-count edits reflow the editor live
    local count_entry = self.controls.uk_count
    local prev_count_changed = count_entry.on_changed
    count_entry.on_changed = function(value)
        if prev_count_changed ~= nil then
            prev_count_changed(value)
        end
        editor:layout_cells()
    end

    local active = ConfigContent(window, 4)
    active:add_checkbox("uk_show_time", TR["Display time"],
        function(value)
            settings_getter().show_time = value == true
        end,
        function()
            return settings_getter().show_time == true
        end)
    active:add_color_picker("uk_active_text_color", TR["Text color"],
        function(value)
            settings_getter().active_text_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().active_text_color)
        end)
    active:add_row_break()
    active:add_checkbox("uk_drain_enabled", TR["Drain overlay"],
        function(value)
            settings_getter().drain_enabled = value == true
        end,
        function()
            return settings_getter().drain_enabled == true
        end)
    active:add_color_picker("uk_drain_color", TR["Drain color"],
        function(value)
            settings_getter().drain_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().drain_color)
        end)
    active:add_line_edit("uk_drain_opacity", TR["Drain opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().drain_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().drain_opacity)
        end)
    self:add_tab(TR["Buff active"], "active", active)

    local cooldown = ConfigContent(window, 4)
    cooldown:add_checkbox("uk_cd_show_time", TR["Display time"],
        function(value)
            settings_getter().cd_show_time = value == true
        end,
        function()
            return settings_getter().cd_show_time == true
        end)
    cooldown:add_color_picker("uk_cooldown_text_color", TR["Text color"],
        function(value)
            settings_getter().cooldown_text_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().cooldown_text_color)
        end)
    cooldown:add_row_break()
    cooldown:add_checkbox("uk_cd_shade", TR["Shaded"],
        function(value)
            settings_getter().cd_shade = value == true
        end,
        function()
            return settings_getter().cd_shade == true
        end)
    cooldown:add_color_picker("uk_cd_shade_color", TR["Shade color"],
        function(value)
            settings_getter().cd_shade_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().cd_shade_color)
        end)
    cooldown:add_line_edit("uk_cd_shade_opacity", TR["Shade opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().cd_shade_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().cd_shade_opacity)
        end)
    cooldown:add_row_break()
    cooldown:add_checkbox("uk_cd_during_active", TR["Show cooldown while the buff is active"],
        function(value)
            settings_getter().cd_during_active = value == true
        end,
        function()
            return settings_getter().cd_during_active == true
        end, true)
    cooldown:add_row_break()
    cooldown:add_checkbox("uk_cd_transparent", TR["Transparent"],
        function(value)
            settings_getter().cd_transparent = value == true
        end,
        function()
            return settings_getter().cd_transparent == true
        end)
    cooldown:add_line_edit("uk_cd_transparent_opacity", TR["Icon opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().cd_transparent_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().cd_transparent_opacity)
        end)
    cooldown:add_row_break()
    cooldown:add_checkbox("uk_dim_unusable", TR["Fade when not usable"],
        function(value)
            settings_getter().dim_unusable = value == true
        end,
        function()
            return settings_getter().dim_unusable == true
        end)
    cooldown:add_line_edit("uk_unusable_opacity", TR["Icon opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().unusable_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().unusable_opacity)
        end)
    self:add_tab(TR["On cooldown"], "cooldown", cooldown)

    local text = ConfigContent(window, 4)
    text:add_dropdown("uk_font_name", TR["Font"], text.font_name_labels, text.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function()
            return settings_getter().font.name
        end)
    text:add_line_edit("uk_font_size", TR["Font size"],
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function()
            return tostring(settings_getter().font.size)
        end)
    text:add_dropdown("uk_font_style", TR["Font style"], text.font_style_labels, text.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function()
            return settings_getter().font.style
        end)
    text:add_color_picker("uk_font_outline_color", TR["Outline color"],
        function(value)
            settings_getter().font.outline_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().font.outline_color)
        end)
    text:add_row_break()
    text:add_dropdown("uk_time_format", TR["Time format"], time_format_labels, time_format_values,
        function(value)
            settings_getter().time_format = value
        end,
        function()
            return settings_getter().time_format
        end)
    self:add_tab(TR["Text"], "text", text)

    self.controls.uk_font_outline_color.visible_if = function()
        return self.controls.uk_font_style:get_value() == LUI_ENUMS.font_style.OUTLINE
    end
    local prev_style_changed = self.controls.uk_font_style.on_changed
    self.controls.uk_font_style.on_changed = function(value)
        if prev_style_changed ~= nil then
            prev_style_changed(value)
        end
        text:layout()
    end
end

function UpkeepPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
