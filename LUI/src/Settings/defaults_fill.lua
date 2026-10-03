-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local RaidLayout = _G.LUI.Utils.RaidLayout
import "LUI.src.Settings.default_layouts"
import "LUI.src.Utils.raid_layout"

local LUI = _G.LUI
local State = LUI.Settings.State
local Defaults = LUI.Settings.Defaults
local DefaultLayouts = Defaults.DefaultLayouts
local LUI_ENUMS = LUI.Settings.Enums
local Locale = LUI.Locale

local RAID_GROUP_KEYS = { "a", "b", "c", "d" }

local function _ensure_table(t, key)
    if type(t[key]) ~= "table" then
        t[key] = {}
    end
    return t[key]
end

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = _copy_table(child)
    end

    return copy
end

local function _deep_equal(left, right)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end

    for key, value in pairs(left) do
        if _deep_equal(value, right[key]) ~= true then
            return false
        end
    end
    for key, value in pairs(right) do
        if left[key] == nil and value ~= nil then
            return false
        end
    end

    return true
end

local function _sanitize_with_defaults(source, defaults)
    if type(defaults) ~= "table" then
        if source == nil then
            return defaults
        end
        return source
    end

    local sanitized = _copy_table(defaults)
    if type(source) ~= "table" then
        return sanitized
    end

    for key, default_value in pairs(defaults) do
        local source_value = source[key]
        if type(default_value) == "table" then
            sanitized[key] = _sanitize_with_defaults(source_value, default_value)
        elseif source_value ~= nil then
            sanitized[key] = source_value
        end
    end

    for key, source_value in pairs(source) do
        if defaults[key] == nil and source_value ~= nil then
            sanitized[key] = _copy_table(source_value)
        end
    end

    return sanitized
end

local function _optional_table_child(source, key)
    if type(source) ~= "table" then
        return nil
    end

    local child = source[key]
    if type(child) ~= "table" then
        return nil
    end

    return child
end

local function _preserve_user_arrays(loaded, source)
    local source_launcher = _optional_table_child(source, "launcher")
    if source_launcher ~= nil and type(source_launcher.buttons) == "table" then
        _ensure_table(loaded, "launcher").buttons = _copy_table(source_launcher.buttons)
    end

    local source_upkeep = _optional_table_child(_optional_table_child(source, "self"), "upkeep")
    if source_upkeep ~= nil and type(source_upkeep.slots) == "table" then
        _ensure_table(_ensure_table(loaded, "self"), "upkeep").slots = _copy_table(source_upkeep.slots)
    end
end

local function _apply_missing_values(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end

    for key, default_value in pairs(defaults) do
        local current_value = target[key]
        if current_value == nil then
            target[key] = _copy_table(default_value)
        elseif type(current_value) == "table" and type(default_value) == "table" then
            _apply_missing_values(current_value, default_value)
        end
    end
end

local function _ensure_label_layout_defaults(label)
    if type(label) ~= "table" then
        return
    end

    if label.anchor == nil then
        label.anchor = LUI_ENUMS.vitals_label_anchor.CENTER
    end
    if label.width_mode == nil then
        label.width_mode = LUI_ENUMS.vitals_label_width_mode.FILL
    end
    if label.text_alignment == nil then
        label.text_alignment = LUI_ENUMS.text_alignment.CENTER
    end
    if label.x_offset == nil then
        label.x_offset = 0
    end
    if label.y_offset == nil then
        label.y_offset = 0
    end
end

local function _ensure_vital_labels_defaults(vital_settings)
    if type(vital_settings) ~= "table" or type(vital_settings.labels) ~= "table" then
        return
    end

    for _, label in pairs(vital_settings.labels) do
        _ensure_label_layout_defaults(label)
    end
end

local function _ensure_targets_target_labels_defaults(target_settings)
    if type(target_settings) ~= "table" or type(target_settings.targets_target) ~= "table" then
        return
    end

    _ensure_vital_labels_defaults(target_settings.targets_target)
end

local function _ensure_preview_label_defaults(loaded)
    _ensure_vital_labels_defaults(loaded.self and loaded.self.vitals)
    _ensure_vital_labels_defaults(loaded.target and loaded.target.vitals)
    _ensure_targets_target_labels_defaults(loaded.target and loaded.target.vitals)
    _ensure_vital_labels_defaults(loaded.target and loaded.target.boss_vitals)
    _ensure_vital_labels_defaults(loaded.companion)
    _ensure_vital_labels_defaults(loaded.fellowship)
    _ensure_vital_labels_defaults(loaded.raid)
end

local function _ensure_raid_layout_defaults(loaded, defaults)
    if type(loaded.raid) ~= "table" then
        return
    end

    local raid_layout = _ensure_table(loaded.raid, "layout")
    local default_layout = defaults.raid.layout
    if raid_layout.mode == nil then
        raid_layout.mode = default_layout.mode
    end
end

local function _hud_position_matches(lhs, rhs)
    if type(lhs) ~= "table" or type(rhs) ~= "table" then
        return false
    end

    return lhs.left == rhs.left and lhs.top == rhs.top
end

local function _raw_group_member_height(vitals_settings)
    local border_width = vitals_settings.frame.border_width
    local member_height = vitals_settings.morale.height + vitals_settings.power.height - border_width
    if vitals_settings.info.enabled == true then
        member_height = member_height + vitals_settings.info.height - border_width
    end
    if member_height < 1 then
        member_height = 1
    end

    return member_height
end

local function _build_raid_group_hud_defaults(raid_hud, raid_settings)
    local out = {}
    local layout = raid_settings.layout
    local member_width = raid_settings.frame.width
    local member_height = _raw_group_member_height(raid_settings)

    for group_index = 1, #RAID_GROUP_KEYS do
        local group_key = RAID_GROUP_KEYS[group_index]
        local cell = RaidLayout.group_origin_cell(layout.mode, group_index)
        out["raid_group_" .. group_key .. "_vitals"] = {
            left = raid_hud.left + (cell.column * (member_width + layout.spacing_x)),
            top = raid_hud.top + (cell.row * (member_height + layout.spacing_y)),
        }
    end

    return out
end

local function _seed_raid_group_hud_positions(hud, raid_settings, defaults, source_hud)
    local default_group_positions = defaults.ui.hud
    local computed_positions = _build_raid_group_hud_defaults(hud.raid_vitals, raid_settings)

    for i = 1, #RAID_GROUP_KEYS do
        local group_key = RAID_GROUP_KEYS[i]
        local hud_key = "raid_group_" .. group_key .. "_vitals"
        local current = hud[hud_key]
        local seeded = computed_positions[hud_key]
        local source_group = _optional_table_child(source_hud, hud_key)

        if source_group == nil
            or _hud_position_matches(current, default_group_positions[hud_key]) == true
            or (i > 1 and _hud_position_matches(current, hud.raid_vitals) == true) then
            current = seeded
        end

        hud[hud_key] = _sanitize_with_defaults(current, seeded)
    end
end

local function _strip_legacy_party_settings(loaded)
    loaded.party = nil

    local ui = loaded.ui
    if type(ui) ~= "table" then
        return
    end

    local hud = ui.hud
    if type(hud) ~= "table" then
        return
    end

    hud.party_vitals = nil
end

local function _seed_group_vitals_settings(loaded, defaults, source)
    local default_fellowship_source = defaults.fellowship
    local source_fellowship = _optional_table_child(source, "fellowship")
    local source_raid = _optional_table_child(source, "raid")

    local fellowship_source = source_fellowship
    if fellowship_source == nil then
        fellowship_source = loaded.fellowship
    end
    loaded.fellowship = _sanitize_with_defaults(fellowship_source, default_fellowship_source)

    local raid_source = source_raid
    if raid_source == nil then
        raid_source = loaded.raid
    end
    loaded.raid = _sanitize_with_defaults(raid_source, defaults.raid)

    local hud = _ensure_table(_ensure_table(loaded, "ui"), "hud")
    local source_ui = _optional_table_child(source, "ui")
    local source_hud = _optional_table_child(source_ui, "hud")
    local default_fellowship_hud_source = defaults.ui.hud.fellowship_vitals
    local default_raid_hud_source = defaults.ui.hud.raid_vitals

    local fellowship_hud_source = _optional_table_child(source_hud, "fellowship_vitals")
    if fellowship_hud_source == nil then
        fellowship_hud_source = hud.fellowship_vitals
    end

    local raid_hud_source = _optional_table_child(source_hud, "raid_vitals")
    if raid_hud_source == nil then
        raid_hud_source = hud.raid_vitals
    end

    hud.fellowship_vitals = _sanitize_with_defaults(fellowship_hud_source, default_fellowship_hud_source)
    hud.raid_vitals = _sanitize_with_defaults(raid_hud_source, default_raid_hud_source)
    _seed_raid_group_hud_positions(hud, loaded.raid, defaults, source_hud)
end

local function _ensure_window_tiles(windows)
    if type(windows) ~= "table" then
        return
    end

    for _, window in pairs(windows) do
        if type(window) == "table" and window.tile ~= "maximized" then
            window.tile = "none"
        end
    end
end

local function _defaults_source()
    local loaded = State.loaded_settings
    local target_scale = DefaultLayouts.get_resolution_scale()
    if type(loaded) == "table" then
        local global = loaded.global
        if type(global) == "table" then
            local scale = tonumber(global.scale)
            if type(scale) == "number" then
                target_scale = scale
            end
        end
    end

    local defaults = DefaultLayouts.build("top", target_scale)

    if type(defaults.fellowship) ~= "table" then
        error("Missing default fellowship settings")
    end

    local default_raid_group_positions = _build_raid_group_hud_defaults(defaults.ui.hud.raid_vitals, defaults.raid)
    for i = 1, #RAID_GROUP_KEYS do
        local group_key = RAID_GROUP_KEYS[i]
        local hud_key = "raid_group_" .. group_key .. "_vitals"
        defaults.ui.hud[hud_key] = default_raid_group_positions[hud_key]
    end

    return defaults
end

function Defaults.get_ui_window_state(key)
    if type(key) ~= "string" then
        return nil
    end
    if type(State.loaded_settings) ~= "table" then
        return nil
    end

    local ui = _ensure_table(State.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    return _ensure_table(windows, key)
end

function Defaults.get_ui_hud_state(key)
    if type(key) ~= "string" then
        return nil
    end
    if type(State.loaded_settings) ~= "table" then
        return nil
    end

    local ui = _ensure_table(State.loaded_settings, "ui")
    local hud = _ensure_table(ui, "hud")
    return _ensure_table(hud, key)
end

function Defaults.ensure_loaded_settings()
    if type(State.loaded_settings) ~= "table" then
        State.loaded_settings = {}
    end

    local original = State.loaded_settings
    local defaults = _defaults_source()
    State.loaded_settings = _sanitize_with_defaults(State.loaded_settings, defaults)
    _preserve_user_arrays(State.loaded_settings, original)
    _seed_group_vitals_settings(State.loaded_settings, defaults, original)
    _strip_legacy_party_settings(State.loaded_settings)
    _ensure_preview_label_defaults(State.loaded_settings)
    _ensure_raid_layout_defaults(State.loaded_settings, defaults)

    local ui = _ensure_table(State.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    _ensure_window_tiles(windows)

    -- legacy carrier: bestiary_capture lived under global up to v2.1.0.
    -- Old saves move their value into the encyclopedia section here; the
    -- legacy key is no longer in the schema, so it is never re-filled and
    -- disappears from disk on the next save.
    local global = _ensure_table(State.loaded_settings, "global")
    local encyclopedia = _ensure_table(State.loaded_settings, "encyclopedia")
    if global.bestiary_capture ~= nil then
        encyclopedia.bestiary_capture = global.bestiary_capture == true
        global.bestiary_capture = nil
    end
    if Locale.is_english_language() ~= true then
        encyclopedia.bestiary_capture = false
    end

    return _deep_equal(original, State.loaded_settings) ~= true
end
