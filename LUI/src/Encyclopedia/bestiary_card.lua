-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Utils = _G.LUI.Utils
local Settings = _G.LUI.Settings
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Encyclopedia = _G.LUI.Features.Encyclopedia
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

local Style = UI.Widgets.Style

local DATA_ACCESS = Encyclopedia.DataAccess
-- packed builtin bestiary proxy, owned by DataAccess (full iteration must
-- go through count/key_at)
local BUILTIN_BESTIARY = DATA_ACCESS.builtin_source()
local CW = Encyclopedia.CardWidgets

-- shared card style tokens live in card_widgets.lua; card-specific
-- dimensions stay here
local BASE_WIDTH = 550
local BASE_SECTION_GAP = CW.BASE.SECTION_GAP
local BASE_PANEL_HEADER_H = CW.BASE.PANEL_HEADER_H
local BASE_PANEL_BODY_PAD_X = CW.BASE.PANEL_BODY_PAD_X
local BASE_PANEL_BODY_PAD_TOP = CW.BASE.PANEL_BODY_PAD_TOP
local BASE_PANEL_BODY_PAD_BOTTOM = CW.BASE.PANEL_BODY_PAD_BOTTOM
local BASE_STAT_BOX_H = CW.BASE.STAT_BOX_H
local BASE_PROFILE_H = 78
local BASE_TWO_COL_H = 88
local BASE_MITIGATION_H = 104
local BASE_NOTES_MIN_H = 76
local BASE_DROP_MIN_H = 42
local BASE_DROP_MAX_H = 150
local BASE_TITLE_SIZE = CW.BASE.TITLE_SIZE
local BASE_TEXT_SIZE = CW.BASE.TEXT_SIZE
local BASE_OFFSET = CW.BASE.OFFSET
local BASE_CHIP_H = CW.BASE.CHIP_H
local BASE_TEXT_CHAR_W = CW.BASE.TEXT_CHAR_W
local BASE_TEXT_LINE_H = CW.BASE.TEXT_LINE_H
local BASE_SCROLL_W = CW.BASE.SCROLL_W
local BASE_SCROLL_GAP = CW.BASE.SCROLL_GAP
local BASE_VARIANT_TAB_H = 22
local BASE_VARIANT_TAB_PAD_X = 10

local COLOR_VALUE_GREY = Turbine.UI.Color(1, 0.56, 0.59, 0.61)
local COMBAT_SCALE_COLORS = {
    feeble = Turbine.UI.Color(1, 0.26, 0.77, 0.42),
    poor = Turbine.UI.Color(1, 0.49, 0.81, 0.31),
    fair = Turbine.UI.Color(1, 0.79, 0.84, 0.29),
    average = Turbine.UI.Color(1, 0.88, 0.71, 0.30),
    good = Turbine.UI.Color(1, 0.88, 0.54, 0.29),
    superior = Turbine.UI.Color(1, 0.85, 0.35, 0.27),
    remarkable = Turbine.UI.Color(1, 0.79, 0.26, 0.26),
    incredible = Turbine.UI.Color(1, 0.67, 0.20, 0.23),
    extraordinary = Turbine.UI.Color(1, 0.59, 0.16, 0.20),
}

local _scaled_int = CW.scaled_int
local _scaled_font = CW.scaled_font

local function _to_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback or 0
    end
    return value
end

local function _trim(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function _lower_text(text)
    if type(text) ~= "string" then
        return ""
    end
    return string.lower(text)
end

local function _is_numeric_text(text)
    return type(text) == "string" and string.match(text, "^%d+$") ~= nil
end

local function _rating_key(value)
    local text = _trim(value)
    if text == nil then
        return nil
    end
    return string.lower(text)
end

local function _resolve_scale_color(scale, value)
    local key = _rating_key(value)
    if key == nil then
        return nil
    end
    if key == "unknown" or key == "false" or _is_numeric_text(key) == true then
        return COLOR_VALUE_GREY
    end
    return scale[key] or COLOR_VALUE_GREY
end

local function _combat_value_color(row_key, value)
    local key = _rating_key(value)
    if key == nil then
        return nil
    end

    if row_key == "fm" or row_key == "sm" or row_key == "rt" then
        if key == "false" or key == "no" then
            return COMBAT_SCALE_COLORS.feeble
        end
        if key == "true" or key == "yes" then
            return COMBAT_SCALE_COLORS.incredible
        end
        return COLOR_VALUE_GREY
    end

    return _resolve_scale_color(COMBAT_SCALE_COLORS, value)
end

local function _resistance_value_color(_, value)
    return _resolve_scale_color(COMBAT_SCALE_COLORS, value)
end

local function _mitigation_value_color(_, value)
    return _resolve_scale_color(COMBAT_SCALE_COLORS, value)
end

local function _normalize_bestiary_name(name)
    return DATA_ACCESS.normalize_name(name)
end

local function _merged_entry_for_name(name)
    -- localized clients: bridge the target name to the English canonical
    name = DATA_ACCESS.to_canonical(name)
    local normalized = _normalize_bestiary_name(name)
    if normalized == nil then
        return nil
    end

    local merged = DATA_ACCESS.new_merged_entry(normalized)

    local resolved_name = normalized
    local builtin_name, builtin = DATA_ACCESS.resolve_entry(BUILTIN_BESTIARY, DATA_ACCESS.get_builtin_index(), normalized)
    if type(builtin) ~= "table" then
        return nil
    end

    resolved_name = builtin_name or resolved_name
    DATA_ACCESS.merge_entry(merged, builtin, resolved_name)

    local cache = DATA_ACCESS.ensure_cache()
    if type(cache) == "table" then
        local cached_name, cached = DATA_ACCESS.resolve_entry(cache, DATA_ACCESS.get_cache_index(), normalized)
        if type(cached) == "table" then
            resolved_name = cached_name or resolved_name
            DATA_ACCESS.merge_entry(merged, cached, resolved_name)
        end
    end

    return resolved_name, merged
end

local function _format_number(value)
    return CW.format_number(_to_number(value, 0))
end

local function _format_range(min_value, max_value)
    if min_value <= 0 and max_value <= 0 then
        return "-"
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end
    if min_value == max_value then
        return tostring(min_value)
    end
    return tostring(min_value) .. " - " .. tostring(max_value)
end

local function _format_number_range(min_value, max_value)
    if min_value <= 0 and max_value <= 0 then
        return "-"
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end
    if min_value == max_value then
        return _format_number(min_value)
    end
    return _format_number(min_value) .. " - " .. _format_number(max_value)
end

local function _build_record_from_entry(resolved_name, entry, exact_level, exact_morale, exact_power)
    if type(resolved_name) ~= "string" or type(entry) ~= "table" then
        return nil
    end

    local morale_min = 0
    local morale_max = 0
    local power_min = 0
    local power_max = 0
    local level_min = 0
    local level_max = 0

    if type(entry.static_levels) == "table" then
        level_min = _to_number(entry.static_levels[1], 0)
        level_max = _to_number(entry.static_levels[2], level_min)
    end
    if type(entry.static_morale) == "table" then
        morale_min = _to_number(entry.static_morale[1], 0)
        morale_max = _to_number(entry.static_morale[2], morale_min)
    end
    if type(entry.static_power) == "table" then
        power_min = _to_number(entry.static_power[1], 0)
        power_max = _to_number(entry.static_power[2], power_min)
    end

    if type(entry.levels) == "table" then
        for level, info in pairs(entry.levels) do
            local level_n = _to_number(level, 0)
            if level_n > 0 then
                if level_min <= 0 or level_n < level_min then level_min = level_n end
                if level_n > level_max then level_max = level_n end
            end

            if type(info) == "table" then
                local morale = _to_number(info.m, 0)
                local power = _to_number(info.p, 0)
                if morale > 0 and (morale_min <= 0 or morale < morale_min) then morale_min = morale end
                if morale > morale_max then morale_max = morale end
                if power >= 0 and (power_min <= 0 or power < power_min) then power_min = power end
                if power > power_max then power_max = power end
            end
        end
    end

    return {
        key = resolved_name,
        name = type(entry.display_name) == "string" and entry.display_name or resolved_name,
        base_name = type(entry.base_name) == "string" and entry.base_name ~= "" and entry.base_name or
            (type(entry.display_name) == "string" and entry.display_name or resolved_name),
        variant_tab_label = type(entry.variant_tab_label) == "string" and entry.variant_tab_label or nil,
        variant_label = type(entry.variant_label) == "string" and entry.variant_label or nil,
        genus = entry.genus,
        subcategory = entry.subcategory,
        species = entry.species,
        region = entry.region,
        area = entry.area,
        instance = entry.instance,
        type = entry.monster_type,
        level_min = level_min,
        level_max = level_max,
        morale_min = morale_min,
        morale_max = morale_max,
        power_min = power_min,
        power_max = power_max,
        current_level = _to_number(exact_level, 0),
        current_morale = _to_number(exact_morale, 0),
        current_power = _to_number(exact_power, 0),
        combat_effectiveness = entry.combat_effectiveness,
        resistances = entry.resistances,
        mitigation = entry.mitigation,
        abilities = entry.abilities,
        quest_involvement = entry.quest_involvement,
        deed_involvement = entry.deed_involvement,
        drops = DATA_ACCESS.build_drop_records(entry),
    }
end

local function _build_record_for_target(target)
    if target == nil or target.GetName == nil then
        return nil
    end

    local normalized_name, entry = _merged_entry_for_name(target:GetName())
    if normalized_name == nil or type(entry) ~= "table" then
        return nil
    end

    local exact_level = target.GetLevel ~= nil and target:GetLevel() or 0
    local exact_morale = target.GetMaxMorale ~= nil and target:GetMaxMorale() or 0
    local exact_power = target.GetMaxPower ~= nil and target:GetMaxPower() or 0

    local record = _build_record_from_entry(normalized_name, entry, exact_level, exact_morale, exact_power)
    -- The boss matcher compares the raw in-game name, so keep the exact
    -- target:GetName() value used to open this card for the boss-target action.
    record.live_target_name = target:GetName()
    return record
end

local function _build_record_for_name(name)
    local normalized_name, entry = _merged_entry_for_name(name)
    if normalized_name == nil or type(entry) ~= "table" then
        return nil
    end

    return _build_record_from_entry(normalized_name, entry, 0, 0, 0)
end

local function _record_base_name(record)
    if type(record) ~= "table" then
        return nil
    end
    if type(record.base_name) == "string" and record.base_name ~= "" then
        return record.base_name
    end
    if type(record.name) == "string" and record.name ~= "" then
        return record.name
    end
    if type(record.key) == "string" and record.key ~= "" then
        return record.key
    end
    return nil
end

local function _record_primary_variant_label(record)
    if type(record) ~= "table" then
        return TR["Variant"]
    end
    if type(record.variant_tab_label) == "string" and record.variant_tab_label ~= "" then
        return record.variant_tab_label
    end
    if type(record.variant_label) == "string" and record.variant_label ~= "" then
        return record.variant_label
    end
    if type(record.instance) == "string" and record.instance ~= "" then
        return record.instance
    end
    if type(record.area) == "string" and record.area ~= "" then
        return record.area
    end
    if type(record.region) == "string" and record.region ~= "" then
        return record.region
    end
    if type(record.name) == "string" and record.name ~= "" then
        return record.name
    end
    return type(record.key) == "string" and record.key or TR["Variant"]
end

local function _record_fallback_variant_label(record)
    local primary = _record_primary_variant_label(record)
    local primary_lower = _lower_text(primary)

    if type(record) ~= "table" then
        return primary
    end
    if type(record.variant_label) == "string" and record.variant_label ~= "" and _lower_text(record.variant_label) ~= primary_lower then
        return record.variant_label
    end
    if type(record.instance) == "string" and record.instance ~= "" and _lower_text(record.instance) ~= primary_lower then
        return record.instance
    end
    if type(record.area) == "string" and record.area ~= "" and _lower_text(record.area) ~= primary_lower then
        return record.area
    end
    if type(record.region) == "string" and record.region ~= "" and _lower_text(record.region) ~= primary_lower then
        return record.region
    end
    return primary
end

local function _record_disambiguated_variant_label(record)
    local primary = _record_primary_variant_label(record)
    local suffix = _record_fallback_variant_label(record)
    if _lower_text(suffix) == _lower_text(primary) then
        local variant = type(record) == "table" and record.variant_label or nil
        if type(variant) == "string" and variant ~= "" and _lower_text(variant) ~= _lower_text(primary) then
            suffix = variant
        end
    end
    if _lower_text(suffix) == _lower_text(primary) then
        return primary
    end

    return primary .. " · " .. suffix
end

local function _assign_variant_tab_labels(records)
    local counts = {}

    for i = 1, #records do
        local label = _record_primary_variant_label(records[i])
        records[i].tab_label = label
        local key = _lower_text(label)
        counts[key] = _to_number(counts[key], 0) + 1
    end

    for _, count in pairs(counts) do
        if count > 1 then
            local disambiguated_counts = {}
            for i = 1, #records do
                local primary = _record_primary_variant_label(records[i])
                local primary_key = _lower_text(primary)
                if _to_number(counts[primary_key], 0) > 1 then
                    records[i].tab_label = _record_disambiguated_variant_label(records[i])
                end
                local key = _lower_text(records[i].tab_label)
                disambiguated_counts[key] = _to_number(disambiguated_counts[key], 0) + 1
            end
            counts = disambiguated_counts
            break
        end
    end

    for _, count in pairs(counts) do
        if count > 1 then
            for i = 1, #records do
                records[i].tab_label = records[i].name or records[i].key or TR["Variant"]
            end

            local keyed_counts = {}
            for i = 1, #records do
                local key = _lower_text(records[i].tab_label)
                keyed_counts[key] = _to_number(keyed_counts[key], 0) + 1
            end

            for i = 1, #records do
                local key = _lower_text(records[i].tab_label)
                if _to_number(keyed_counts[key], 0) > 1 then
                    records[i].tab_label = records[i].tab_label .. " #" .. tostring(i)
                end
            end
            return
        end
    end
end

local function _compare_variant_records(left, right)
    local left_label = _lower_text(left ~= nil and (left.tab_label or _record_primary_variant_label(left)) or nil)
    local right_label = _lower_text(right ~= nil and (right.tab_label or _record_primary_variant_label(right)) or nil)
    if left_label ~= right_label then
        return left_label < right_label
    end

    local left_name = _lower_text(left ~= nil and (left.name or left.key) or nil)
    local right_name = _lower_text(right ~= nil and (right.name or right.key) or nil)
    if left_name ~= right_name then
        return left_name < right_name
    end

    return _lower_text(left ~= nil and left.key or nil) < _lower_text(right ~= nil and right.key or nil)
end

local function _find_record_index(records, key)
    if type(records) ~= "table" or type(key) ~= "string" then
        return nil
    end

    local wanted = _lower_text(key)
    for i = 1, #records do
        local record = records[i]
        if type(record) == "table" and _lower_text(record.key) == wanted then
            return i
        end
    end

    return nil
end

local function _collect_variant_group(selected_record)
    if type(selected_record) ~= "table" then
        return nil
    end

    local base_name = _record_base_name(selected_record)
    if type(base_name) ~= "string" or base_name == "" then
        return {
            base_name = selected_record.name or selected_record.key or TR["Bestiary"],
            records = { selected_record },
        }
    end

    local records = {}
    local seen = {}
    local wanted = _lower_text(base_name)

    local function append_record(record)
        if type(record) ~= "table" or type(record.key) ~= "string" then
            return
        end

        local key = _lower_text(record.key)
        if seen[key] == true then
            return
        end

        seen[key] = true
        records[#records + 1] = record
    end

    append_record(selected_record)

    local function collect_from_source(source, index_getter)
        if type(source) ~= "table" then
            return
        end

        local index = index_getter()
        local group_keys = DATA_ACCESS.get_group_keys(source, index, base_name)
        if type(group_keys) == "table" then
            for i = 1, #group_keys do
                append_record(_build_record_for_name(group_keys[i]))
            end
            return
        end

        for entry_name, entry in pairs(source) do
            if type(entry_name) == "string" and type(entry) == "table" then
                local entry_base_name = type(entry.bn) == "string" and entry.bn ~= "" and entry.bn or entry_name
                if _lower_text(entry_base_name) == wanted then
                    append_record(_build_record_for_name(entry_name))
                end
            end
        end
    end

    collect_from_source(BUILTIN_BESTIARY, DATA_ACCESS.get_builtin_index)
    local cache = DATA_ACCESS.ensure_cache()
    collect_from_source(cache, DATA_ACCESS.get_cache_index)

    table.sort(records, _compare_variant_records)
    _assign_variant_tab_labels(records)

    return {
        base_name = base_name,
        records = records,
    }
end




local function _display_text(value)
    if type(value) ~= "string" or value == "" then
        return "-"
    end
    return value
end

local function _format_percent(percent)
    return CW.format_percent(_to_number(percent, 0))
end

local function _has_visible_range(min_value, max_value)
    min_value = _to_number(min_value, 0)
    max_value = _to_number(max_value, 0)
    if min_value <= 0 and max_value <= 0 then
        return false
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end
    return min_value ~= max_value
end

local function _format_level_text(record)
    if _has_visible_range(record.level_min, record.level_max) == true then
        return _format_range(record.level_min, record.level_max)
    end
    if _to_number(record.current_level, 0) > 0 then
        return tostring(record.current_level)
    end
    return _format_range(record.level_min, record.level_max)
end

local function _format_morale_text(record)
    if _has_visible_range(record.morale_min, record.morale_max) == true then
        return _format_number_range(record.morale_min, record.morale_max)
    end
    if _to_number(record.current_morale, 0) > 0 then
        return _format_number(record.current_morale)
    end
    return _format_number_range(record.morale_min, record.morale_max)
end

local function _format_power_text(record)
    if _has_visible_range(record.power_min, record.power_max) == true then
        return _format_number_range(record.power_min, record.power_max)
    end
    if _to_number(record.current_power, 0) > 0 then
        return _format_number(record.current_power)
    end
    return _format_number_range(record.power_min, record.power_max)
end

local LOCATION_FIELDS = {
    { key = "region", label = TR["Region"] },
    { key = "area", label = TR["Area"] },
    { key = "instance", label = TR["Instance"] },
}

local CREATURE_FIELDS = {
    { key = "type", label = TR["Type"] },
    { key = "genus", label = TR["Genus"] },
    { key = "species", label = TR["Species"] },
}

local COMBAT_FIELDS = {
    { key = "f", label = TR["Finesse"] },
    { key = "fm", label = TR["F.M. Immune"] },
    { key = "sm", label = TR["Stun/Mez Imm."] },
    { key = "rt", label = TR["Root Immune"] },
}

local RESISTANCE_FIELDS = {
    { key = "cr", label = TR["Cry"] },
    { key = "so", label = TR["Song"] },
    { key = "ta", label = TR["Tactical"] },
    { key = "ph", label = TR["Physical"] },
}

local MITIGATION_LEFT_FIELDS = {
    { key = "co", label = TR["Common"] },
    { key = "fi", label = TR["Fire"] },
    { key = "li", label = TR["Light"] },
    { key = "sh", label = TR["Shadow"] },
    { key = "lt", label = TR["Lightning"] },
}

local MITIGATION_RIGHT_FIELDS = {
    { key = "ad", label = TR["Ancient Dwarf"] },
    { key = "be", label = TR["Beleriand"] },
    { key = "we", label = TR["Westernesse"] },
    { key = "fr", label = TR["Frost"] },
}

local function _build_list_text(values)
    if type(values) ~= "table" or #values == 0 then
        return "-"
    end

    local lines = {}
    for i = 1, #values do
        lines[#lines + 1] = "- " .. values[i]
    end
    return table.concat(lines, "\n")
end

-- quests/deeds panel lines: quest_involvement/deed_involvement carry
-- quest/deed game ids; the display name comes from the packed quests
-- domain (properly localized on FR/DE clients). The quests domain is
-- staged by the background prewarm; until it lands the panels render
-- empty (the Items notify_loaded re-bind below refreshes open cards once
-- staging finishes).
local function _build_quest_lines(quest_ids)
    if type(quest_ids) ~= "table" or #quest_ids == 0 then
        return nil
    end
    local Quests = _G.LUI.Data.Lore.Quests
    if Quests.loaded ~= true then
        return nil
    end
    local lines = {}
    for i = 1, #quest_ids do
        lines[i] = Quests.label(Quests.ordinal_of(quest_ids[i]))
    end
    return lines
end

local function _build_drop_texts(record)
    local texts = {}

    if type(record) == "table" and type(record.drops) == "table" then
        for i = 1, #record.drops do
            local drop = record.drops[i]
            if type(drop) == "table" and type(drop.name) == "string" and drop.name ~= "" then
                local text
                if type(drop.rate) == "number" then
                    text = drop.name .. ": " .. _format_percent(drop.rate)
                else
                    text = drop.name
                end
                texts[#texts + 1] = { text = text, chest = drop.chest == true, name = drop.name }
            end
        end
    end

    if #texts == 0 then
        texts[1] = { text = TR["No drops seen."], chest = false }
    end

    return texts
end

local _estimate_text_width = CW.estimate_text_width

local function _estimate_font_text_width(text, font_size)
    local scaled_char_w = BASE_TEXT_CHAR_W * (font_size / BASE_TEXT_SIZE)
    return _estimate_text_width(text, scaled_char_w)
end

local function _choose_stat_font_size(text, max_width)
    local sizes = { BASE_TITLE_SIZE, 18, 16, 14, 13 }
    local usable_w = math.max(1, max_width)

    for i = 1, #sizes do
        if _estimate_font_text_width(text, sizes[i]) <= usable_w then
            return sizes[i]
        end
    end

    return sizes[#sizes]
end

local function _estimate_wrapped_line_count(text, max_width)
    if type(text) ~= "string" or text == "" then
        return 1
    end

    max_width = math.max(1, max_width)
    local line_count = 0

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        if line == "" then
            line_count = line_count + 1
        else
            local width = _estimate_text_width(line, BASE_TEXT_CHAR_W)
            line_count = line_count + math.max(1, math.ceil(width / max_width))
        end
    end

    return math.max(1, line_count)
end

local _build_chip_layout = CW.build_chip_layout
local _create_text = CW.create_text

local function _apply_scroll_label_style(area)
    if area == nil or area.label == nil then
        return
    end

    if type(area.font_name) ~= "string" or type(area.font_size) ~= "number" or area.color == nil then
        return
    end

    local font_name = area.font_name == "Verdana" and Style.CONTROL_FONT_NAME or area.font_name
    area.label:SetFont(_scaled_font(font_name, area.font_size))
    area.label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    area.label:SetOutlineColor(Style.TEXT_OUTLINE)
    area.label:SetForeColor(area.color)
end

local function _create_scroll_label_area(parent)
    local area = {
        text = "-",
        uses_scroll = false,
        font_name = nil,
        font_size = nil,
        color = nil,
    }

    parent:SetMouseVisible(true)

    area.label = UI.Widgets.LuiLabel()
    area.label:SetParent(parent)
    area.label:SetMouseVisible(true)
    area.label:SetSelectable(false)
    area.label:SetMultiline(true)
    area.label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    area.label:SetSelectable(true)

    area.scroll = Turbine.UI.Lotro.ScrollBar()
    area.scroll:SetParent(parent)
    area.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    area.scroll:SetWidth(BASE_SCROLL_W)
    area.scroll:SetPosition(0, 0)
    area.scroll:SetHeight(1)
    area.scroll:SetMouseVisible(true)
    area.label:SetVerticalScrollBar(area.scroll)
    area.scroll:SetVisible(false)

    area.label.FocusGained = function(s, a)
        parent:Focus()
    end

    _apply_scroll_label_style(area)
    area.label:SetText(area.text or "-")

    return area
end

local function _style_scroll_label_area(area, font_name, font_size, color)
    if area == nil then
        return
    end

    area.font_name = font_name
    area.font_size = font_size
    area.color = color
    _apply_scroll_label_style(area)
end

local function _bind_scroll_label_area(area, values)
    if area == nil or area.label == nil then
        return
    end

    area.label:SetVerticalScrollBar(nil)
    area.text = _build_list_text(values)
    area.label:SetText(area.text)
    area.label:SetVerticalScrollBar(area.scroll)
end

local function _measure_scroll_label_panel(panel_w, text)
    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local header_h = _scaled_int(BASE_PANEL_HEADER_H)
    local min_h = _scaled_int(BASE_NOTES_MIN_H)
    local max_h = _scaled_int(BASE_DROP_MAX_H)
    local scroll_gap = _scaled_int(BASE_SCROLL_GAP)
    local line_h = _scaled_int(BASE_TEXT_LINE_H)

    local function build(use_scroll)
        local reserved_w = use_scroll == true and (BASE_SCROLL_W + scroll_gap) or 0
        local usable_w = math.max(1, panel_w - 2 - (2 * body_pad_x) - reserved_w)
        local line_count = _estimate_wrapped_line_count(text, usable_w)
        local text_h = math.max(line_h, line_count * line_h)
        local frame_h = header_h + 2 + body_pad_t + body_pad_b + text_h
        local panel_h = math.max(min_h, math.min(max_h, frame_h))
        local viewport_h = math.max(1, panel_h - header_h - 2 - body_pad_t - body_pad_b)
        return panel_h, text_h > viewport_h
    end

    local panel_h, uses_scroll = build(false)
    if uses_scroll == true then
        panel_h, uses_scroll = build(true)
    end

    return panel_h, uses_scroll
end

local _style_text = CW.style_text

local function _style_variant_tab_bar(tab_bar)
    if tab_bar == nil then
        return
    end

    tab_bar._border_color = Style.CONTROL_BORDER
    tab_bar._strip_back = Style.CONTROL_BACKGROUND
    tab_bar._content_back = Style.SELECTION_BACKGROUND
    tab_bar._hover_back = Style.CONTROL_BACKGROUND_HOVER
    tab_bar._tab_text = Style.ALTERNATE_FOREGROUND
    tab_bar._tab_text_hover = Style.SELECTION_FOREGROUND
    tab_bar._tab_text_selected = Style.SELECTION_FOREGROUND
    tab_bar._tab_text_disabled = Style.ALTERNATE_FOREGROUND

    if type(tab_bar._tabs) == "table" then
        for i = 1, #tab_bar._tabs do
            local entry = tab_bar._tabs[i]
            entry.button:set_theme(
                tab_bar._tab_text,
                tab_bar._tab_text_hover,
                tab_bar._tab_text_selected,
                tab_bar._tab_text_disabled
            )
        end
    end

    tab_bar:refresh_layout()
end

local _create_panel = CW.create_panel
local _style_panel = CW.style_panel

local function _create_row_set(parent, field_order)
    local rows = {}
    for i = 1, #field_order do
        local row = {
            key = field_order[i].key,
            label = _create_text(parent, false, Turbine.UI.ContentAlignment.MiddleLeft),
            value = _create_text(parent, false, Turbine.UI.ContentAlignment.MiddleRight),
        }
        row.label:SetText(field_order[i].label .. ":")
        rows[#rows + 1] = row
    end
    return rows
end

local function _style_row_set(rows, value_color)
    for i = 1, #rows do
        _style_text(rows[i].label, "Verdana", BASE_TEXT_SIZE, Style.ALTERNATE_FOREGROUND)
        _style_text(rows[i].value, "Verdana", BASE_TEXT_SIZE, value_color or Style.FOREGROUND)
    end
end


local function _layout_parallel_row_sets(left_rows, right_rows, x_left, x_right, y, w_left, w_right, h,
    left_label_ratio, right_label_ratio)
    local left_count = type(left_rows) == "table" and #left_rows or 0
    local right_count = type(right_rows) == "table" and #right_rows or 0
    local row_count = math.max(left_count, right_count)

    if row_count <= 0 then
        return
    end

    local gap = _scaled_int(6)
    local row_h = math.max(_scaled_int(14), math.floor(h / row_count))

    local function layout_rows(rows, x, w, label_ratio)
        if type(rows) ~= "table" or #rows == 0 then
            return
        end

        local label_w = math.max(1, math.floor(w * label_ratio))
        local value_w = math.max(1, w - label_w - gap)

        for i = 1, #rows do
            local ry = y + ((i - 1) * row_h)
            rows[i].label:SetPosition(x, ry)
            rows[i].label:SetSize(label_w, row_h)
            rows[i].value:SetPosition(x + label_w + gap, ry)
            rows[i].value:SetSize(value_w, row_h)
        end
    end

    layout_rows(left_rows, x_left, w_left, left_label_ratio)
    layout_rows(right_rows, x_right, w_right, right_label_ratio)
end

local function _bind_row_set(rows, values, color_resolver, default_value_color)
    default_value_color = default_value_color or Style.FOREGROUND
    for i = 1, #rows do
        local raw_value = nil
        local value = "-"
        if type(values) == "table" then
            raw_value = values[rows[i].key]
            value = _display_text(raw_value)
        end
        rows[i].value:SetText(value)
        if type(color_resolver) == "function" then
            rows[i].value:SetForeColor(color_resolver(rows[i].key, raw_value) or default_value_color)
        else
            rows[i].value:SetForeColor(default_value_color)
        end
    end
end

-- Whether a drop name resolves to a browsable Encyclopedia item; probed at
-- card bind (bounded by drops per card) and cached per name for reopens.
local _drop_link_known = {}

local function _drop_link_name(name)
    if name == nil then
        return nil
    end
    local known = _drop_link_known[name]
    if known == nil then
        known = Encyclopedia.encyclopedia_tab_for_item(name) ~= nil
        -- pre-staging probes always miss; don't memoize them or links
        -- would never appear once the items DB finishes staging
        if _G.LUI.Data.Lore.Items.loaded == true then
            _drop_link_known[name] = known
        end
    end
    return known == true and name or nil
end

-- chips bound while the Items DB was still staging carry no links (the
-- probe reports "no link" pre-staging); re-bind the open card once the
-- domain lands so links appear without closing and reopening the card
_G.LUI.Data.Lore.Items.notify_loaded(function()
    local card = _G.LUI.Runtime.Windows.bestiary_card
    if card ~= nil and card:IsVisible() == true then
        card:apply_settings()
    end
end)

local DropChip = CW.DropChip

local BestiaryVariantTab = class(Turbine.UI.Control)

function BestiaryVariantTab:Constructor(owner)
    Turbine.UI.Control.Constructor(self)

    self.owner = owner
    self.index = 0
    self.selected = false
    self.hovered = false

    self:SetMouseVisible(true)
    self:SetBackColor(Style.CONTROL_BORDER)

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(false)
    self.inner:SetBackColor(Style.CONTROL_BACKGROUND)

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self.inner)
    self.label:SetMouseVisible(false)
    self.label:SetSelectable(false)
    self.label:SetMultiline(false)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.SizeChanged = function()
        self:_layout()
    end
    self.MouseEnter = function()
        self.hovered = true
        self:_apply_style()
    end
    self.MouseLeave = function()
        self.hovered = false
        self:_apply_style()
    end
    self.MouseClick = function()
        self.owner:on_variant_tab_clicked(self.index)
    end

    self:_apply_style()
end

function BestiaryVariantTab:_layout()
    local border_w = 1
    local pad_x = _scaled_int(BASE_VARIANT_TAB_PAD_X)

    self.inner:SetPosition(border_w, border_w)
    self.inner:SetSize(math.max(1, self:GetWidth() - (2 * border_w)), math.max(1, self:GetHeight() - (2 * border_w)))
    self.label:SetPosition(pad_x, 0)
    self.label:SetSize(math.max(1, self.inner:GetWidth() - (2 * pad_x)), self.inner:GetHeight())
end

function BestiaryVariantTab:_apply_style()
    local fill = Style.CONTROL_BACKGROUND
    local text_color = Style.ALTERNATE_FOREGROUND

    if self.selected == true then
        fill = Style.SELECTION_BACKGROUND
        text_color = Style.SELECTION_FOREGROUND
    elseif self.hovered == true then
        fill = Style.CONTROL_BACKGROUND_HOVER
    end

    self.inner:SetBackColor(fill)
    _style_text(self.label, "Verdana", BASE_TEXT_SIZE, text_color)
    self:_layout()
end

function BestiaryVariantTab:bind(text, index, selected)
    self.index = _to_number(index, 0)
    self.label:SetText(text or "")
    self:set_selected(selected)
    self:SetVisible(true)
end

function BestiaryVariantTab:set_selected(selected)
    self.selected = selected == true
    self:_apply_style()
end

local BestiaryCard = class(UI.Widgets.LuiWindow)
Encyclopedia.BestiaryCard = BestiaryCard

local function _card_window_settings(create)
    local root = State.loaded_settings
    if type(root) ~= "table" then
        return nil
    end

    if type(root.bestiary) ~= "table" then
        if create ~= true then
            return nil
        end
        root.bestiary = {}
    end

    if type(root.bestiary.card_window) ~= "table" then
        if create ~= true then
            return nil
        end
        root.bestiary.card_window = {}
    end

    return root.bestiary.card_window
end

function BestiaryCard:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self.current_key = nil
    self.current_record = nil
    self.current_group_name = nil
    self.variant_records = {}
    self.selected_variant_index = nil
    self._variant_bar_updating = false
    self.drop_chips = {}
    self.drop_panel_h = _scaled_int(BASE_DROP_MIN_H)
    self.drop_layout = {}
    self.drop_content_h = _scaled_int(BASE_CHIP_H)
    self.drop_uses_scroll = false
    self.abilities_area = nil
    self.quests_area = nil
    self.deeds_area = nil
    self.sticky_position = false
    self._suppress_position_persist = false

    self:set_title(TR["Bestiary"])
    self:set_icon(UI.AssetIds.book_orange_cover)
    self:set_resizable(false)
    self:enable_maximize(false)
    self:hide()
    self:SetMouseVisible(true)

    local menu_bar = self:get_menu_bar()
    self.edit_menu = menu_bar:add_menu(TR["Edit"])
    self.add_boss_action = self.edit_menu:add_action({
        text = TR["Add to Boss Targets"],
        triggered = function()
            self:_add_current_to_boss_targets()
        end,
    })

    local central = Turbine.UI.Control()
    central:SetMouseVisible(true)
    self:set_central_widget(central)

    self.variant_bar = self:_create_variant_bar()

    self.content = Turbine.UI.Control()
    self.content:SetParent(central)
    self.content:SetMouseVisible(false)

    self.level_panel = _create_panel(self.content, TR["Level"])
    self.level_value = _create_text(self.level_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.morale_panel = _create_panel(self.content, TR["Morale"])
    self.morale_value = _create_text(self.morale_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.power_panel = _create_panel(self.content, TR["Power"])
    self.power_value = _create_text(self.power_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.location_panel = _create_panel(self.content, TR["Location"])
    self.location_rows = _create_row_set(self.location_panel.body, LOCATION_FIELDS)

    self.creature_panel = _create_panel(self.content, TR["Creature"])
    self.creature_rows = _create_row_set(self.creature_panel.body, CREATURE_FIELDS)

    self.drop_panel = _create_panel(self.content, TR["Drops"])
    self.drop_list = Turbine.UI.ListBox()
    self.drop_list:SetParent(self.drop_panel.body)
    self.drop_list:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.drop_scroll = Turbine.UI.Lotro.ScrollBar()
    self.drop_scroll:SetParent(self.drop_panel.body)
    self.drop_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.drop_scroll:SetWidth(BASE_SCROLL_W)
    self.drop_list:SetVerticalScrollBar(self.drop_scroll)
    self.drop_scroll:SetVisible(false)
    self.drop_content = Turbine.UI.Control()
    self.drop_content:SetMouseVisible(false)
    self.drop_list:AddItem(self.drop_content)

    self.combat_panel = _create_panel(self.content, TR["Combat Effectiveness"])
    self.combat_rows = _create_row_set(self.combat_panel.body, COMBAT_FIELDS)

    self.resistances_panel = _create_panel(self.content, TR["Resistances"])
    self.resistance_rows = _create_row_set(self.resistances_panel.body, RESISTANCE_FIELDS)

    self.mitigation_panel = _create_panel(self.content, TR["Mitigation"])
    self.mitigation_left_rows = _create_row_set(self.mitigation_panel.body, MITIGATION_LEFT_FIELDS)
    self.mitigation_right_rows = _create_row_set(self.mitigation_panel.body, MITIGATION_RIGHT_FIELDS)
    self.mitigation_divider = Turbine.UI.Control()
    self.mitigation_divider:SetParent(self.mitigation_panel.body)
    self.mitigation_divider:SetMouseVisible(false)

    self.abilities_panel = _create_panel(self.content, TR["Abilities"])
    self.abilities_area = _create_scroll_label_area(self.abilities_panel.body)

    self.quests_panel = _create_panel(self.content, TR["Quests"])
    self.quests_area = _create_scroll_label_area(self.quests_panel.body)

    self.deeds_panel = _create_panel(self.content, TR["Deeds"])
    self.deeds_area = _create_scroll_label_area(self.deeds_panel.body)

    self.VisibleChanged = function()
        if self:IsVisible() == true then
            self:_clamp_to_display()
            self:_persist_current_position()
        else
            self.current_key = nil
            self.current_record = nil
            self.current_group_name = nil
            self.variant_records = {}
            self.selected_variant_index = nil
        end
    end
    self.PositionChanged = function()
        if self._suppress_position_persist == true or self:IsVisible() ~= true then
            return
        end
        self.sticky_position = true
        self:_persist_current_position()
    end

    self:apply_settings()
end

function BestiaryCard:_variant_tabs_visible()
    return type(self.variant_records) == "table" and #self.variant_records > 1
end

function BestiaryCard:_create_variant_bar()
    local bar = UI.Widgets.LuiTabBar()
    bar:SetParent(self:central_widget())
    bar:SetMouseVisible(true)
    bar:SetVisible(false)
    bar:set_scale(State.settings.global.scale)
    bar:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 1))
    bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
    bar:set_content_padding(0)
    bar:set_show_content_border(false)
    bar.on_tab_changed = function(index)
        if self._variant_bar_updating == true then
            return
        end
        self:_select_variant_index(index, false)
    end
    _style_variant_tab_bar(bar)
    return bar
end

function BestiaryCard:_reset_variant_tabs()
    if self.variant_bar ~= nil then
        self.variant_bar:SetVisible(false)
        self.variant_bar:SetParent(nil)
    end

    self.variant_bar = self:_create_variant_bar()
    if self:_variant_tabs_visible() ~= true then
        return
    end

    for i = 1, #self.variant_records do
        local record = self.variant_records[i]
        local label = type(record) == "table" and (record.tab_label or _record_primary_variant_label(record)) or TR["Variant"]
        local widget = Turbine.UI.Control()
        widget:SetMouseVisible(false)
        self.variant_bar:add_tab(label, widget)
    end

    if self.selected_variant_index ~= nil then
        self._variant_bar_updating = true
        self.variant_bar:set_selected_index(self.selected_variant_index, false)
        self._variant_bar_updating = false
    end
end

function BestiaryCard:_measure_variant_tabs_height()
    if self:_variant_tabs_visible() ~= true then
        return 0
    end

    return _scaled_int(BASE_VARIANT_TAB_H) + _scaled_int(BASE_SECTION_GAP)
end

function BestiaryCard:_layout_variant_tabs(margin_l, margin_t, content_w)
    if self:_variant_tabs_visible() ~= true then
        if self.variant_bar ~= nil then
            self.variant_bar:SetVisible(false)
        end
        return 0
    end

    local bar_h = _scaled_int(BASE_VARIANT_TAB_H)
    self.variant_bar:SetPosition(margin_l, margin_t)
    self.variant_bar:SetSize(content_w, bar_h)
    self.variant_bar:SetVisible(true)
    _style_variant_tab_bar(self.variant_bar)

    return bar_h + _scaled_int(BASE_SECTION_GAP)
end

function BestiaryCard:_apply_selected_variant()
    local record = type(self.variant_records) == "table" and self.variant_records[self.selected_variant_index] or nil
    if type(record) ~= "table" then
        return
    end

    self.current_key = record.key
    self.current_record = record

    if self:_variant_tabs_visible() == true then
        self:set_title(DATA_ACCESS.display_name(self.current_group_name or record.base_name or record.name or record.key) or TR["Bestiary"])
    else
        self:set_title(DATA_ACCESS.display_name(record.name or record.key) or TR["Bestiary"])
    end

    self:_apply_record(record)
    self:_sync_boss_action()
end

-- The boss matcher compares the raw in-game name. For a card opened from a live
-- target that exact name was captured; for a card opened from the Bestiary list
-- the canonical dataset key is the value a live GetName() resolves to.
function BestiaryCard:_boss_target_name()
    local record = self.current_record
    if type(record) ~= "table" then
        return nil
    end
    if type(record.live_target_name) == "string" and record.live_target_name ~= "" then
        return record.live_target_name
    end
    return record.key
end

function BestiaryCard:_sync_boss_action()
    local name = self:_boss_target_name()
    local can_add = type(name) == "string" and name ~= "" and Utils.is_boss_name(name) ~= true
    self.add_boss_action:set_enabled(can_add)
end

function BestiaryCard:_add_current_to_boss_targets()
    local name = self:_boss_target_name()
    if type(name) ~= "string" or name == "" or Utils.is_boss_name(name) == true then
        return
    end

    -- Append the name as a new line to the persisted multiline custom boss list,
    -- mirroring how the Boss vitals settings page stores it.
    local boss_vitals = State.loaded_settings.target.boss_vitals
    local text = boss_vitals.custom_targets
    if text ~= "" and string.sub(text, -1) ~= "\n" then
        text = text .. "\n"
    end
    boss_vitals.custom_targets = text .. name

    -- Rebuild so the runtime boss matcher picks up the new name immediately.
    -- Persistence follows the runtime-menu convention (e.g. Inventory tile size):
    -- the change is saved on unload, not written to disk on every edit.
    Settings.rebuild()
    self:_sync_boss_action()
end

function BestiaryCard:_select_variant_index(index, sync_variant_bar)
    if type(index) ~= "number" then
        index = tonumber(index)
    end
    if index == nil then
        return
    end

    index = math.floor(index + 0.5)
    if index < 1 or index > #self.variant_records then
        return
    end

    self.selected_variant_index = index
    if sync_variant_bar ~= false and self.variant_bar ~= nil and self:_variant_tabs_visible() == true then
        local current_index = self.variant_bar:get_selected_index()
        if current_index ~= index then
            self._variant_bar_updating = true
            self.variant_bar:set_selected_index(index, false)
            self._variant_bar_updating = false
        end
    end

    self:_apply_selected_variant()
end

function BestiaryCard:_show_group(group, selected_key)
    if type(group) ~= "table" or type(group.records) ~= "table" or #group.records == 0 then
        return false
    end

    self.current_group_name = group.base_name
    self.variant_records = group.records
    self.selected_variant_index = _find_record_index(self.variant_records, selected_key) or 1
    self:_reset_variant_tabs()
    self:_select_variant_index(self.selected_variant_index, true)
    return true
end

function BestiaryCard:on_variant_tab_clicked(index)
    self:_select_variant_index(index)
end

function BestiaryCard:_ensure_drop_chip_count(count)
    while #self.drop_chips < count do
        local chip = DropChip()
        chip:SetParent(self.drop_content)
        chip:SetVisible(false)
        self.drop_chips[#self.drop_chips + 1] = chip
    end
end

function BestiaryCard:_layout_panel(panel, x, y, w, h)
    CW.layout_panel(panel, x, y, w, h)
end

function BestiaryCard:_measure_viewport_width()
    local margin_l = _scaled_int(12)
    local margin_r = _scaled_int(12)
    local central_w = self:central_widget():GetSize()

    return math.max(1, central_w - margin_l - margin_r)
end

function BestiaryCard:_measure_bottom_height()
    local content_w = self:_measure_viewport_width()
    local gap = _scaled_int(BASE_SECTION_GAP)
    local col_w = math.max(1, math.floor((content_w - (2 * gap)) / 3))
    local col_x3 = (col_w * 2) + (gap * 2)
    local last_w = math.max(1, content_w - col_x3)

    local abilities_h, abilities_scroll = _measure_scroll_label_panel(
        col_w,
        self.abilities_area ~= nil and self.abilities_area.text or "-"
    )
    local quests_h, quests_scroll = _measure_scroll_label_panel(
        col_w,
        self.quests_area ~= nil and self.quests_area.text or "-"
    )
    local deeds_h, deeds_scroll = _measure_scroll_label_panel(
        last_w,
        self.deeds_area ~= nil and self.deeds_area.text or "-"
    )

    if self.abilities_area ~= nil then
        self.abilities_area.uses_scroll = abilities_scroll == true
    end
    if self.quests_area ~= nil then
        self.quests_area.uses_scroll = quests_scroll == true
    end
    if self.deeds_area ~= nil then
        self.deeds_area.uses_scroll = deeds_scroll == true
    end

    return math.max(_scaled_int(BASE_NOTES_MIN_H), abilities_h, quests_h, deeds_h)
end

function BestiaryCard:_layout_scroll_label_panel(panel, area)
    if panel == nil or area == nil then
        return
    end

    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local scroll_gap = area.uses_scroll == true and _scaled_int(BASE_SCROLL_GAP) or 0
    local scroll_w = area.uses_scroll == true and BASE_SCROLL_W or 0
    local label_w = math.max(1, panel.body:GetWidth() - (2 * body_pad_x) - scroll_gap - scroll_w)
    local label_h = math.max(1, panel.body:GetHeight() - body_pad_t - body_pad_b)

    area.label:SetPosition(body_pad_x, body_pad_t)
    area.label:SetSize(label_w, label_h)

    area.scroll:SetPosition(body_pad_x + label_w + scroll_gap, body_pad_t)
    area.scroll:SetWidth(BASE_SCROLL_W)
    area.scroll:SetHeight(label_h)
    area.scroll:SetVisible(area.uses_scroll == true)
end

function BestiaryCard:_measure_content_height()
    local gap = _scaled_int(BASE_SECTION_GAP)
    local stat_h = _scaled_int(BASE_STAT_BOX_H)
    local profile_h = _scaled_int(BASE_PROFILE_H)
    local pair_h = _scaled_int(BASE_TWO_COL_H)
    local mitigation_h = _scaled_int(BASE_MITIGATION_H)
    local bottom_h = self:_measure_bottom_height()

    return stat_h + gap + profile_h + gap + self.drop_panel_h + gap + pair_h + gap + mitigation_h + gap + bottom_h
end

function BestiaryCard:_measure_minimum_content_height()
    local gap = _scaled_int(BASE_SECTION_GAP)
    return _scaled_int(BASE_STAT_BOX_H) + gap +
        _scaled_int(BASE_PROFILE_H) + gap +
        _scaled_int(BASE_DROP_MIN_H) + gap +
        _scaled_int(BASE_TWO_COL_H) + gap +
        _scaled_int(BASE_MITIGATION_H) + gap +
        _scaled_int(BASE_NOTES_MIN_H)
end

function BestiaryCard:_measure_drop_layout(drop_texts)
    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local header_h = _scaled_int(BASE_PANEL_HEADER_H)
    local min_h = _scaled_int(BASE_DROP_MIN_H)
    local max_h = _scaled_int(BASE_DROP_MAX_H)
    local scroll_gap = _scaled_int(BASE_SCROLL_GAP)
    local scroll_w = BASE_SCROLL_W
    local panel_body_w = math.max(1, self:_measure_viewport_width() - 2 - (2 * body_pad_x))

    local function build(use_scroll)
        local reserved_w = use_scroll == true and (scroll_w + scroll_gap) or 0
        local usable_w = math.max(1, panel_body_w - reserved_w)
        local layout, chip_content_h = _build_chip_layout(drop_texts, usable_w)
        local frame_h = header_h + 2 + body_pad_t + body_pad_b + chip_content_h
        local panel_h = math.max(min_h, math.min(max_h, frame_h))
        local viewport_h = math.max(1, panel_h - header_h - 2 - body_pad_t - body_pad_b)
        return layout, chip_content_h, panel_h, viewport_h
    end

    local layout, chip_content_h, panel_h, viewport_h = build(false)
    local use_scroll = chip_content_h > viewport_h
    if use_scroll == true then
        layout, chip_content_h, panel_h, viewport_h = build(true)
    end

    return layout, chip_content_h, panel_h, viewport_h, use_scroll
end

function BestiaryCard:_clamp_to_display()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local left, top = self:GetPosition()
    local width = self:GetWidth()
    local height = self:GetHeight()

    if width > display_w then
        width = math.max(1, display_w)
    end
    if height > display_h then
        height = math.max(1, display_h)
    end

    if left + width > display_w then
        left = display_w - width
    end
    if top + height > display_h then
        top = display_h - height
    end
    if left < 0 then
        left = 0
    end
    if top < 0 then
        top = 0
    end

    self._suppress_position_persist = true
    self:SetPosition(left, top)
    self._suppress_position_persist = false
end

function BestiaryCard:_persist_current_position()
    local window = _card_window_settings(true)
    if type(window) ~= "table" then
        return
    end

    local left, top = self:GetPosition()
    window.left = left
    window.top = top
end

function BestiaryCard:_restore_saved_position()
    local window = _card_window_settings(false)
    if type(window) ~= "table" then
        return false
    end

    local left = window.left
    local top = window.top
    if type(left) ~= "number" or type(top) ~= "number" then
        return false
    end

    self._suppress_position_persist = true
    self:SetPosition(left, top)
    self._suppress_position_persist = false
    return true
end

function BestiaryCard:_fit_window_height()
    local margin_t = _scaled_int(12)
    local margin_b = _scaled_int(12)
    local offset = _scaled_int(BASE_OFFSET)
    local _, display_h = Turbine.UI.Display.GetSize()
    local min_content_h = margin_t + margin_b + self:_measure_variant_tabs_height() + self:_measure_minimum_content_height()
    local desired_content_h = margin_t + margin_b + self:_measure_variant_tabs_height() + self:_measure_content_height()
    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    local chrome_w = math.max(0, window_w - central_w)
    local chrome_h = math.max(0, window_h - central_h)
    local min_window_h = min_content_h + chrome_h
    local target_w = _scaled_int(BASE_WIDTH) + chrome_w
    local desired_window_h = desired_content_h + chrome_h
    local max_window_h = math.max(min_window_h, display_h - (2 * offset))
    local target_h = math.max(min_window_h, math.min(max_window_h, desired_window_h))

    self:SetSize(target_w, target_h)
    UI.Widgets.LuiWindow._layout(self)
    self:_clamp_to_display()
end

function BestiaryCard:_layout_content()
    local margin_l = _scaled_int(12)
    local margin_t = _scaled_int(12)
    local margin_r = _scaled_int(12)
    local margin_b = _scaled_int(12)
    local gap = _scaled_int(BASE_SECTION_GAP)
    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local stat_h = _scaled_int(BASE_STAT_BOX_H)
    local profile_h = _scaled_int(BASE_PROFILE_H)
    local pair_h = _scaled_int(BASE_TWO_COL_H)
    local mitigation_h = _scaled_int(BASE_MITIGATION_H)
    local bottom_h = self:_measure_bottom_height()

    local host_w, host_h = self:central_widget():GetSize()
    local content_w = math.max(1, host_w - margin_l - margin_r)
    local tab_offset_h = self:_layout_variant_tabs(margin_l, margin_t, content_w)
    local content_y = margin_t + tab_offset_h
    local content_h = math.max(1, host_h - content_y - margin_b)

    self.content:SetPosition(margin_l, content_y)
    self.content:SetSize(content_w, content_h)

    local y = 0
    local stat_total_w = math.max(1, content_w - (2 * gap))
    local level_w = math.max(1, math.floor(stat_total_w * 0.28))
    local morale_w = math.max(1, math.floor(stat_total_w * 0.36))
    local power_w = math.max(1, stat_total_w - level_w - morale_w)
    local morale_x = level_w + gap
    local power_x = morale_x + morale_w + gap

    local bottom_col_w = math.max(1, math.floor((content_w - (2 * gap)) / 3))
    local bottom_x2 = bottom_col_w + gap
    local bottom_x3 = (bottom_col_w * 2) + (gap * 2)
    local bottom_last_w = math.max(1, content_w - bottom_x3)

    self:_layout_panel(self.level_panel, 0, y, level_w, stat_h)
    self:_layout_panel(self.morale_panel, morale_x, y, morale_w, stat_h)
    self:_layout_panel(self.power_panel, power_x, y, power_w, stat_h)

    y = y + stat_h + gap
    local half_w = math.max(1, math.floor((content_w - gap) / 2))
    local right_x = half_w + gap
    local right_w = math.max(1, content_w - right_x)
    self:_layout_panel(self.location_panel, 0, y, half_w, profile_h)
    self:_layout_panel(self.creature_panel, right_x, y, right_w, profile_h)

    y = y + profile_h + gap
    self:_layout_panel(self.drop_panel, 0, y, content_w, self.drop_panel_h)

    local drop_scroll_gap = self.drop_uses_scroll == true and _scaled_int(BASE_SCROLL_GAP) or 0
    local drop_scroll_w = self.drop_uses_scroll == true and BASE_SCROLL_W or 0
    local drop_list_w = math.max(1, self.drop_panel.body:GetWidth() - (2 * body_pad_x) - drop_scroll_gap - drop_scroll_w)
    local drop_list_h = math.max(1, self.drop_panel.body:GetHeight() - body_pad_t - body_pad_b)

    self.drop_list:SetPosition(body_pad_x, body_pad_t)
    self.drop_list:SetSize(drop_list_w, drop_list_h)

    self.drop_scroll:SetPosition(body_pad_x + drop_list_w + drop_scroll_gap, body_pad_t)
    self.drop_scroll:SetWidth(BASE_SCROLL_W)
    self.drop_scroll:SetHeight(drop_list_h)
    self.drop_scroll:SetVisible(self.drop_uses_scroll == true)

    y = y + self.drop_panel_h + gap
    self:_layout_panel(self.combat_panel, 0, y, half_w, pair_h)
    self:_layout_panel(self.resistances_panel, right_x, y, right_w, pair_h)

    y = y + pair_h + gap
    self:_layout_panel(self.mitigation_panel, 0, y, content_w, mitigation_h)

    y = y + mitigation_h + gap
    self:_layout_panel(self.abilities_panel, 0, y, bottom_col_w, bottom_h)
    self:_layout_panel(self.quests_panel, bottom_x2, y, bottom_col_w, bottom_h)
    self:_layout_panel(self.deeds_panel, bottom_x3, y, bottom_last_w, bottom_h)

    self.level_value:SetPosition(_scaled_int(8), _scaled_int(3))
    self.level_value:SetSize(math.max(1, self.level_panel.body:GetWidth() - _scaled_int(16)),
        math.max(1, self.level_panel.body:GetHeight() - _scaled_int(6)))
    self.morale_value:SetPosition(_scaled_int(8), _scaled_int(3))
    self.morale_value:SetSize(math.max(1, self.morale_panel.body:GetWidth() - _scaled_int(16)),
        math.max(1, self.morale_panel.body:GetHeight() - _scaled_int(6)))
    self.power_value:SetPosition(_scaled_int(8), _scaled_int(3))
    self.power_value:SetSize(math.max(1, self.power_panel.body:GetWidth() - _scaled_int(16)),
        math.max(1, self.power_panel.body:GetHeight() - _scaled_int(6)))

    _style_text(
        self.level_value,
        "Verdana",
        _choose_stat_font_size(self.level_value:GetText(), self.level_value:GetWidth()),
        Turbine.UI.Color(1, 0.72, 0.58, 0.20)
    )
    _style_text(
        self.morale_value,
        "Verdana",
        _choose_stat_font_size(self.morale_value:GetText(), self.morale_value:GetWidth()),
        Turbine.UI.Color(1, 0.42, 0.86, 0.44)
    )
    _style_text(
        self.power_value,
        "Verdana",
        _choose_stat_font_size(self.power_value:GetText(), self.power_value:GetWidth()),
        Turbine.UI.Color(1, 0.40, 0.68, 0.96)
    )

    _layout_parallel_row_sets(
        self.location_rows,
        self.creature_rows,
        body_pad_x,
        body_pad_x,
        body_pad_t,
        math.max(1, self.location_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, self.creature_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, math.min(
            self.location_panel.body:GetHeight() - body_pad_t - body_pad_b,
            self.creature_panel.body:GetHeight() - body_pad_t - body_pad_b
        )),
        0.38,
        0.38
    )
    _layout_parallel_row_sets(
        self.combat_rows,
        self.resistance_rows,
        body_pad_x,
        body_pad_x,
        body_pad_t,
        math.max(1, self.combat_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, self.resistances_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, math.min(
            self.combat_panel.body:GetHeight() - body_pad_t - body_pad_b,
            self.resistances_panel.body:GetHeight() - body_pad_t - body_pad_b
        )),
        0.56,
        0.48
    )

    local mitigation_gap = gap + _scaled_int(8)
    local mitigation_body_w = math.max(1, self.mitigation_panel.body:GetWidth() - (2 * body_pad_x))
    local mitigation_col_w = math.max(1, math.floor((mitigation_body_w - mitigation_gap) / 2))
    local mitigation_right_x = body_pad_x + mitigation_col_w + mitigation_gap
    local mitigation_right_w = math.max(1, mitigation_body_w - mitigation_col_w - mitigation_gap)
    local mitigation_body_h = math.max(1, self.mitigation_panel.body:GetHeight() - body_pad_t - body_pad_b)
    local mitigation_divider_w = 1
    local mitigation_divider_x = body_pad_x + mitigation_col_w + math.floor((mitigation_gap - mitigation_divider_w) / 2)
    self.mitigation_divider:SetPosition(mitigation_divider_x, body_pad_t)
    self.mitigation_divider:SetSize(mitigation_divider_w, mitigation_body_h)
    _layout_parallel_row_sets(
        self.mitigation_left_rows,
        self.mitigation_right_rows,
        body_pad_x,
        mitigation_right_x,
        body_pad_t,
        mitigation_col_w,
        mitigation_right_w,
        mitigation_body_h,
        0.52,
        0.56
    )

    self:_layout_scroll_label_panel(self.abilities_panel, self.abilities_area)
    self:_layout_scroll_label_panel(self.quests_panel, self.quests_area)
    self:_layout_scroll_label_panel(self.deeds_panel, self.deeds_area)
end

function BestiaryCard:_apply_drop_layout(drop_texts)
    local layout, chip_content_h, panel_h, _, use_scroll = self:_measure_drop_layout(drop_texts)
    self.drop_panel_h = panel_h
    self.drop_layout = layout
    self.drop_content_h = chip_content_h
    self.drop_uses_scroll = use_scroll == true

    self:_fit_window_height()
    self:_layout_content()
    self:_ensure_drop_chip_count(#layout)

    local chip_h = _scaled_int(BASE_CHIP_H)
    self.drop_content:SetSize(self.drop_list:GetWidth(), math.max(self.drop_list:GetHeight(), chip_content_h))
    self.drop_list:ClearItems()
    self.drop_list:AddItem(self.drop_content)

    for i = 1, #layout do
        local chip_info = layout[i]
        local chip = self.drop_chips[i]
        -- link state first: apply_settings picks the border color from it
        chip:set_link(_drop_link_name(chip_info.name))
        chip:apply_settings(chip_info.chest == true)
        chip:SetPosition(chip_info.x, chip_info.y)
        chip:bind(chip_info.text, chip_info.w, chip_h)
    end
    for i = #layout + 1, #self.drop_chips do
        self.drop_chips[i]:SetVisible(false)
    end
end

function BestiaryCard:_apply_record(record)
    self.current_record = record

    self.level_value:SetText(_format_level_text(record))
    self.morale_value:SetText(_format_morale_text(record))
    self.power_value:SetText(_format_power_text(record))

    _bind_row_set(self.location_rows, record, nil, Style.FOREGROUND)
    _bind_row_set(self.creature_rows, {
        type = record.type,
        genus = record.genus,
        species = record.species or record.subcategory,
    }, nil, Style.FOREGROUND)
    _bind_row_set(self.combat_rows, record.combat_effectiveness, _combat_value_color, Style.FOREGROUND)
    _bind_row_set(self.resistance_rows, record.resistances, _resistance_value_color, Style.FOREGROUND)
    _bind_row_set(self.mitigation_left_rows, record.mitigation, _mitigation_value_color, Style.FOREGROUND)
    _bind_row_set(self.mitigation_right_rows, record.mitigation, _mitigation_value_color, Style.FOREGROUND)

    _bind_scroll_label_area(self.abilities_area, record.abilities)
    _bind_scroll_label_area(self.quests_area, _build_quest_lines(record.quest_involvement))
    _bind_scroll_label_area(self.deeds_area, _build_quest_lines(record.deed_involvement))

    self:_apply_drop_layout(_build_drop_texts(record))
end

function BestiaryCard:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)
    self:set_resizable(false)

    local window_w, window_h = self:GetSize()
    local central_w = self:central_widget():GetSize()
    local w = _scaled_int(BASE_WIDTH) + math.max(0, window_w - central_w)
    self:SetSize(w, window_h)

    _style_panel(self.level_panel)
    _style_panel(self.morale_panel)
    _style_panel(self.power_panel)
    _style_panel(self.location_panel)
    _style_panel(self.creature_panel)
    _style_panel(self.drop_panel)
    _style_panel(self.combat_panel)
    _style_panel(self.resistances_panel)
    _style_panel(self.mitigation_panel)
    self.mitigation_divider:SetBackColor(Style.CONTROL_BORDER)
    _style_panel(self.abilities_panel)
    _style_panel(self.quests_panel)
    _style_panel(self.deeds_panel)

    _style_row_set(self.location_rows, Style.FOREGROUND)
    _style_row_set(self.creature_rows, Style.FOREGROUND)
    _style_row_set(self.combat_rows, Style.FOREGROUND)
    _style_row_set(self.resistance_rows, Style.FOREGROUND)
    _style_row_set(self.mitigation_left_rows, Style.FOREGROUND)
    _style_row_set(self.mitigation_right_rows, Style.FOREGROUND)

    _style_scroll_label_area(self.abilities_area, "Verdana", BASE_TEXT_SIZE, Style.FOREGROUND)
    _style_scroll_label_area(self.quests_area, "Verdana", BASE_TEXT_SIZE, Style.FOREGROUND)
    _style_scroll_label_area(self.deeds_area, "Verdana", BASE_TEXT_SIZE, Style.FOREGROUND)

    _bind_scroll_label_area(self.abilities_area, self.current_record ~= nil and self.current_record.abilities or nil)
    _bind_scroll_label_area(self.quests_area,
        self.current_record ~= nil and _build_quest_lines(self.current_record.quest_involvement) or nil)
    _bind_scroll_label_area(self.deeds_area,
        self.current_record ~= nil and _build_quest_lines(self.current_record.deed_involvement) or nil)

    if self.variant_bar ~= nil then
        self.variant_bar:set_scale(State.settings.global.scale)
        self.variant_bar:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 1))
        _style_variant_tab_bar(self.variant_bar)
    end

    self:_layout_content()

    if self.current_record ~= nil then
        self:_apply_record(self.current_record)
    else
        self:_apply_drop_layout({ TR["No drops seen."] })
    end
end

function BestiaryCard:bring_to_front()
    if self:IsVisible() == true then
        self:Activate()
    end
end

function BestiaryCard:close()
    self.current_key = nil
    self.current_record = nil
    self.current_group_name = nil
    self.variant_records = {}
    self.selected_variant_index = nil
    self:hide()
end

function BestiaryCard:on_target_changed()
end

function BestiaryCard:_position_near_anchor(anchor)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local left = math.floor((display_w - self:GetWidth()) / 2)
    local top = math.floor((display_h - self:GetHeight()) / 2)

    if anchor ~= nil and anchor.GetPosition ~= nil and anchor.GetSize ~= nil then
        local ax, ay = anchor:GetPosition()
        local aw = anchor:GetSize()
        left = ax + aw + _scaled_int(BASE_OFFSET)
        top = ay
    end

    if left + self:GetWidth() > display_w then
        left = display_w - self:GetWidth() - _scaled_int(BASE_OFFSET)
    end
    if top + self:GetHeight() > display_h then
        top = display_h - self:GetHeight() - _scaled_int(BASE_OFFSET)
    end
    if left < _scaled_int(BASE_OFFSET) then
        left = _scaled_int(BASE_OFFSET)
    end
    if top < _scaled_int(BASE_OFFSET) then
        top = _scaled_int(BASE_OFFSET)
    end

    self._suppress_position_persist = true
    self:SetPosition(left, top)
    self._suppress_position_persist = false
end

function BestiaryCard:_prepare_position(anchor)
    if self:_restore_saved_position() ~= true and self.sticky_position ~= true then
        self:_position_near_anchor(anchor)
    end

    self:_clamp_to_display()
    self:_persist_current_position()
    self.sticky_position = true
end

function BestiaryCard:toggle_for_target(target, anchor)
    local record = _build_record_for_target(target)
    if type(record) ~= "table" then
        return false
    end

    local group = _collect_variant_group(record)
    local selected_key = record.key

    if self:IsVisible() == true and self.current_key == selected_key then
        self:close()
        return true
    end

    if self:_show_group(group, selected_key) ~= true then
        return false
    end
    self:_prepare_position(anchor)
    self:show()
    return true
end

function BestiaryCard:show_for_name(name, anchor)
    local record = _build_record_for_name(name)
    if type(record) ~= "table" then
        return false
    end

    local group = _collect_variant_group(record)
    if self:_show_group(group, record.key) ~= true then
        return false
    end
    self:_prepare_position(anchor)
    self:show()
    return true
end
