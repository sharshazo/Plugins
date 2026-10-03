-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local BestiaryCache = _G.LUI.Runtime.Caches.Bestiary
local Encyclopedia = _G.LUI.Features.Encyclopedia
local Persistence = _G.LUI.Settings.Persistence
Encyclopedia.DataAccess = Encyclopedia.DataAccess or {}

-- packed builtin bestiary: read-only point-lookup proxy registered by
-- src/Data/bestiary_db.lua (full iteration must go through count/key_at)
local BUILTIN_BESTIARY = _G.LUI.Data.Bestiary.DB.en.bestiary

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

local function _lower(text)
    if type(text) ~= "string" then
        return ""
    end

    return string.lower(text)
end

local function _to_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback or 0
    end

    return value
end

local function _normalize_name(name)
    name = _trim(name)
    if name == nil then
        return nil
    end

    local lowered = string.lower(name)
    if string.sub(lowered, 1, 4) == "the " then
        name = _trim(string.sub(name, 5))
    end

    name = name:gsub("%s*%.+$", "")
    name = _trim(name)
    if name == nil or name == "" then
        return nil
    end

    return name
end

local function _normalized_lower(name)
    local normalized = _normalize_name(name)
    if normalized ~= nil then
        return _lower(normalized)
    end

    return _lower(_trim(name))
end

local function _alias_target(entry)
    if type(entry) ~= "table" then
        return nil
    end

    return _trim(entry.alias)
end

local function _is_alias_entry(entry)
    return _alias_target(entry) ~= nil
end

local function _entry_base_name(name, entry)
    if type(entry) == "table" and type(entry.bn) == "string" and entry.bn ~= "" then
        return entry.bn
    end
    if type(entry) == "table" and type(entry.n) == "string" and entry.n ~= "" then
        return entry.n
    end

    return name
end

local function _copy_array(values)
    if type(values) ~= "table" then
        return nil
    end

    local out = {}
    for i = 1, #values do
        out[i] = values[i]
    end

    return out
end

local function _merge_cache_entry(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end

    if type(dst.levels) ~= "table" then
        dst.levels = {}
    end
    if type(dst.d) ~= "table" then
        dst.d = {}
    end

    dst.k = _to_number(dst.k, 0) + _to_number(src.k, 0)
    dst.lmin = nil
    dst.lmax = nil

    if type(src.levels) == "table" then
        for level, info in pairs(src.levels) do
            if type(info) == "table" then
                local dst_info = dst.levels[level]
                if type(dst_info) ~= "table" then
                    dst.levels[level] = {
                        m = _to_number(info.m, 0),
                        p = _to_number(info.p, 0),
                    }
                else
                    local morale = _to_number(info.m, 0)
                    local power = _to_number(info.p, 0)
                    if morale > _to_number(dst_info.m, 0) then
                        dst_info.m = morale
                    end
                    if power > _to_number(dst_info.p, 0) then
                        dst_info.p = power
                    end
                end
            end
        end
    end

    if type(src.d) == "table" then
        for item_name, count in pairs(src.d) do
            if type(item_name) == "string" then
                dst.d[item_name] = _to_number(dst.d[item_name], 0) + _to_number(count, 0)
            end
        end
    end
end

local function _clear_legacy_level_bounds(entry)
    if type(entry) ~= "table" then
        return
    end

    entry.lmin = nil
    entry.lmax = nil
end

local function _normalize_cache_table(cache)
    if type(cache) ~= "table" then
        return cache, false
    end

    local renames = {}
    for name, entry in pairs(cache) do
        _clear_legacy_level_bounds(entry)
        if type(name) == "string" and type(entry) == "table" then
            local normalized = _normalize_name(name)
            if normalized ~= nil and normalized ~= name then
                renames[#renames + 1] = { from = name, to = normalized }
            end
        end
    end

    local changed = false
    for i = 1, #renames do
        local rename = renames[i]
        local entry = cache[rename.from]
        if type(entry) == "table" then
            if type(cache[rename.to]) == "table" and cache[rename.to] ~= entry then
                _merge_cache_entry(cache[rename.to], entry)
            else
                cache[rename.to] = entry
            end
            cache[rename.from] = nil
            changed = true
        end
    end

    -- entries with no kills, no drops, and no observed stats are dead
    -- weight: the removed live stat capture created one for every mob
    -- ever targeted. Entries with observed morale/power levels stay:
    -- cards still render them and the data cannot be recaptured
    local dead = {}
    for name, entry in pairs(cache) do
        local alive = type(entry) == "table"
            and (_to_number(entry.k, 0) > 0
                or (type(entry.d) == "table" and next(entry.d) ~= nil)
                or (type(entry.levels) == "table" and next(entry.levels) ~= nil))
        if alive ~= true then
            dead[#dead + 1] = name
        end
    end
    for i = 1, #dead do
        cache[dead[i]] = nil
        changed = true
    end
    if changed == true then
        BestiaryCache.dirty = true
    end

    return cache, changed
end

local function _copy_range(range_values)
    if type(range_values) ~= "table" then
        return nil
    end

    local min_value = _to_number(range_values[1], 0)
    local max_value = _to_number(range_values[2], 0)
    if min_value <= 0 and max_value <= 0 then
        return nil
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end

    return { min_value, max_value }
end

local function _append_unique_name(list, value)
    if type(list) ~= "table" or type(value) ~= "string" or value == "" then
        return
    end

    for i = 1, #list do
        if list[i] == value then
            return
        end
    end

    list[#list + 1] = value
end

-- di entries are deed game ids (numbers), not names
local function _append_unique_id(list, value)
    if type(list) ~= "table" or type(value) ~= "number" then
        return
    end

    for i = 1, #list do
        if list[i] == value then
            return
        end
    end

    list[#list + 1] = value
end

local function _merge_text_values(current, next_value)
    if type(next_value) ~= "string" or next_value == "" then
        return current
    end
    if type(current) ~= "string" or current == "" then
        return next_value
    end
    if _lower(current) == _lower(next_value) then
        return current
    end

    local parts = {}
    local seen = {}

    local function push_parts(source)
        if type(source) ~= "string" then
            return
        end

        for part in string.gmatch(source, "([^/]+)") do
            local candidate = part:gsub("^%s+", ""):gsub("%s+$", "")
            if candidate ~= "" then
                local key = _lower(candidate)
                if seen[key] ~= true then
                    seen[key] = true
                    parts[#parts + 1] = candidate
                end
            end
        end
    end

    push_parts(current)
    push_parts(next_value)
    return table.concat(parts, " / ")
end

local function _merge_string_map(dst, field_name, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end

    if type(dst[field_name]) ~= "table" then
        dst[field_name] = {}
    end

    local dst_map = dst[field_name]
    for key, value in pairs(src) do
        if type(key) == "string" and type(value) == "string" and value ~= "" and dst_map[key] == nil then
            dst_map[key] = value
        end
    end
end

local function _merge_record_range(dst, field_name, src_value)
    local src_range = _copy_range(src_value)
    if src_range == nil then
        return
    end

    local dst_range = dst[field_name]
    if type(dst_range) ~= "table" then
        dst[field_name] = src_range
        return
    end

    if src_range[1] < dst_range[1] then
        dst_range[1] = src_range[1]
    end
    if src_range[2] > dst_range[2] then
        dst_range[2] = src_range[2]
    end
end

local function _new_merged_entry(name)
    return {
        base_name = nil,
        variant_tab_label = nil,
        variant_label = nil,
        display_name = name,
        genus = nil,
        subcategory = nil,
        species = nil,
        region = nil,
        area = nil,
        instance = nil,
        monster_type = nil,
        static_levels = nil,
        static_morale = nil,
        static_power = nil,
        combat_effectiveness = {},
        resistances = {},
        mitigation = {},
        abilities = {},
        quest_involvement = {}, -- quest game ids
        deed_involvement = {}, -- deed game ids
        w = {},
        cw = {},
        levels = {},
        k = 0,
        d = {},
    }
end

local function _merge_entry(dst, src, name)
    if type(dst) ~= "table" or type(src) ~= "table" or type(name) ~= "string" then
        return
    end

    if type(src.bn) == "string" and src.bn ~= "" then
        dst.base_name = src.bn
    elseif type(dst.base_name) ~= "string" or dst.base_name == "" then
        dst.base_name = name
    end
    if type(src.tl) == "string" and src.tl ~= "" then
        dst.variant_tab_label = src.tl
    end
    if type(src.v) == "string" and src.v ~= "" then
        dst.variant_label = src.v
    end

    if type(src.n) == "string" and src.n ~= "" then
        dst.display_name = src.n
    elseif type(dst.display_name) ~= "string" or dst.display_name == "" then
        dst.display_name = name
    end

    if type(dst.genus) ~= "string" and type(src.g) == "string" and src.g ~= "" then
        dst.genus = src.g
    end
    if type(dst.subcategory) ~= "string" and type(src.s) == "string" and src.s ~= "" then
        dst.subcategory = src.s
    end
    if type(src.sp) == "string" and src.sp ~= "" then
        dst.species = _merge_text_values(dst.species, src.sp)
    elseif type(dst.species) ~= "string" and type(src.s) == "string" and src.s ~= "" then
        dst.species = src.s
    end
    if type(dst.region) ~= "string" and type(src.r) == "string" and src.r ~= "" then
        dst.region = src.r
    end
    if type(dst.area) ~= "string" and type(src.a) == "string" and src.a ~= "" then
        dst.area = src.a
    end
    if type(dst.instance) ~= "string" and type(src.i) == "string" and src.i ~= "" then
        dst.instance = src.i
    end
    if type(src.t) == "string" and src.t ~= "" then
        dst.monster_type = _merge_text_values(dst.monster_type, src.t)
    end

    _merge_record_range(dst, "static_levels", src.l)
    _merge_record_range(dst, "static_morale", src.m)
    _merge_record_range(dst, "static_power", src.p)
    _merge_string_map(dst, "combat_effectiveness", src.ce)
    _merge_string_map(dst, "resistances", src.rs)
    _merge_string_map(dst, "mitigation", src.mi)

    if type(src.w) == "table" then
        for i = 1, #src.w do
            _append_unique_name(dst.w, src.w[i])
        end
    end
    if type(src.cw) == "table" then
        for i = 1, #src.cw do
            _append_unique_name(dst.cw, src.cw[i])
        end
    end
    if type(src.ab) == "table" then
        for i = 1, #src.ab do
            _append_unique_name(dst.abilities, src.ab[i])
        end
    end
    if type(src.qi) == "table" then
        for i = 1, #src.qi do
            _append_unique_id(dst.quest_involvement, src.qi[i])
        end
    end
    if type(src.di) == "table" then
        for i = 1, #src.di do
            _append_unique_id(dst.deed_involvement, src.di[i])
        end
    end

    dst.k = _to_number(dst.k, 0) + _to_number(src.k, 0)

    if type(src.levels) == "table" then
        for level, info in pairs(src.levels) do
            if type(info) == "table" then
                if type(dst.levels[level]) ~= "table" then
                    dst.levels[level] = {
                        m = _to_number(info.m, 0),
                        p = _to_number(info.p, 0),
                    }
                else
                    local level_entry = dst.levels[level]
                    local morale = _to_number(info.m, 0)
                    local power = _to_number(info.p, 0)
                    if morale > _to_number(level_entry.m, 0) then
                        level_entry.m = morale
                    end
                    if power > _to_number(level_entry.p, 0) then
                        level_entry.p = power
                    end
                end
            end
        end
    end

    if type(src.d) == "table" then
        for item_name, count in pairs(src.d) do
            if type(item_name) == "string" then
                dst.d[item_name] = _to_number(dst.d[item_name], 0) + _to_number(count, 0)
            end
        end
    end
end

local function _build_drop_records(entry)
    local drops = {}
    local kills = _to_number(entry ~= nil and entry.k, 0)

    local by_name = {}
    local function drop_key(item_name, chest)
        return (chest == true and "c:" or "d:") .. item_name
    end
    if type(entry) == "table" and type(entry.w) == "table" then
        for i = 1, #entry.w do
            local item_name = entry.w[i]
            local key = type(item_name) == "string" and drop_key(item_name, false) or nil
            if key ~= nil and item_name ~= "" and by_name[key] == nil then
                by_name[key] = { name = item_name, count = 0, rate = nil, chest = false }
            end
        end
    end
    if type(entry) == "table" and type(entry.cw) == "table" then
        for i = 1, #entry.cw do
            local item_name = entry.cw[i]
            local key = type(item_name) == "string" and drop_key(item_name, true) or nil
            if key ~= nil and item_name ~= "" and by_name[key] == nil then
                by_name[key] = { name = item_name, count = 0, rate = nil, chest = true }
            end
        end
    end

    if type(entry) == "table" and type(entry.d) == "table" then
        for item_name, count in pairs(entry.d) do
            if type(item_name) == "string" then
                local drop = by_name[drop_key(item_name, false)]
                if type(drop) ~= "table" then
                    drop = { name = item_name, count = 0, rate = nil, chest = false }
                    by_name[drop_key(item_name, false)] = drop
                end

                local n = _to_number(count, 0)
                drop.count = n
                if kills > 0 and n > 0 then
                    drop.rate = (n / kills) * 100
                end
            end
        end
    end

    for _, drop in pairs(by_name) do
        drops[#drops + 1] = drop
    end

    table.sort(drops, function(left, right)
        if (left.chest == true) ~= (right.chest == true) then
            return left.chest ~= true
        end
        local left_has_rate = type(left.rate) == "number"
        local right_has_rate = type(right.rate) == "number"
        if left_has_rate ~= right_has_rate then
            return left_has_rate == true
        end
        if left_has_rate == true and right_has_rate == true and left.rate ~= right.rate then
            return left.rate > right.rate
        end
        return _lower(left.name) < _lower(right.name)
    end)

    return drops
end

local function _build_source_index(source)
    local index = {
        source = source,
        keys_by_lower = {},
        aliases_by_lower = {},
        first_key_by_base_lower = {},
        group_keys_by_base_lower = {},
    }

    if type(source) ~= "table" then
        return index
    end

    for name, entry in pairs(source) do
        if type(name) == "string" and type(entry) == "table" then
            local raw_lower = _lower(name)
            if raw_lower ~= "" then
                index.keys_by_lower[raw_lower] = name
            end

            local normalized_lower = _normalized_lower(name)
            if normalized_lower ~= "" then
                index.keys_by_lower[normalized_lower] = name
            end
        end
    end

    for name, entry in pairs(source) do
        if type(name) == "string" and type(entry) == "table" then
            local alias_target = _alias_target(entry)
            if alias_target ~= nil then
                local raw_lower = _lower(name)
                if raw_lower ~= "" then
                    index.aliases_by_lower[raw_lower] = alias_target
                end

                local normalized_lower = _normalized_lower(name)
                if normalized_lower ~= "" then
                    index.aliases_by_lower[normalized_lower] = alias_target
                end
            else
                local base_name = _entry_base_name(name, entry)
                local base_lower = _normalized_lower(base_name)
                local group_keys = index.group_keys_by_base_lower[base_lower]
                if type(group_keys) ~= "table" then
                    group_keys = {}
                    index.group_keys_by_base_lower[base_lower] = group_keys
                    index.first_key_by_base_lower[base_lower] = name
                end
                group_keys[#group_keys + 1] = name
            end
        end
    end

    return index
end

local CACHE_INDEX = nil
local CACHE_GENERATION = nil

function Encyclopedia.DataAccess.get_builtin_index()
    -- baked at pack time; same shape _build_source_index produces
    return _G.LUI.Data.Lore.Bestiary.builtin_index()
end

-- single owner of the packed builtin source binding; consumers must not
-- bind the deep global themselves
function Encyclopedia.DataAccess.builtin_source()
    return BUILTIN_BESTIARY
end

function Encyclopedia.DataAccess.get_cache_index()
    local source = Encyclopedia.DataAccess.ensure_cache()
    local generation = BestiaryCache.generation or 0
    if CACHE_INDEX == nil or CACHE_INDEX.source ~= source or CACHE_GENERATION ~= generation then
        CACHE_INDEX = _build_source_index(source)
        CACHE_GENERATION = generation
    end

    return CACHE_INDEX
end

local function _resolve_key(source, index, name)
    if type(source) ~= "table" then
        return nil
    end

    local normalized = _normalize_name(name)
    if normalized == nil then
        return nil
    end

    local lowered = _lower(normalized)
    local alias_target = type(index) == "table" and index.aliases_by_lower[lowered] or nil
    if alias_target ~= nil then
        local alias_key = type(index) == "table" and index.keys_by_lower[_lower(alias_target)] or nil
        return alias_key or alias_target
    end

    local direct_key = type(index) == "table" and index.keys_by_lower[lowered] or nil
    if direct_key == nil and type(source[normalized]) == "table" then
        direct_key = normalized
    end
    if type(direct_key) == "string" then
        local direct_entry = source[direct_key]
        local nested_alias = _alias_target(direct_entry)
        if nested_alias ~= nil then
            local nested_key = type(index) == "table" and index.keys_by_lower[_lower(nested_alias)] or nil
            return nested_key or nested_alias
        end

        return direct_key
    end

    return type(index) == "table" and index.first_key_by_base_lower[lowered] or nil
end

-- localized target names translate to the English canonical base name
-- before resolution; unmatched names pass through unchanged (English
-- clients, already-canonical names, and the bridge's 4% misses)
function Encyclopedia.DataAccess.to_canonical(name)
    local bridge = Encyclopedia.NameBridge
    if bridge == nil or type(name) ~= "string" then
        return name
    end
    local normalized = _normalize_name(name)
    if normalized == nil or normalized == "" then
        return name
    end
    return bridge[string.lower(normalized)] or name
end

-- render-time inverse of to_canonical: English base name -> localized
-- display name (translation fallback: names without a localized label
-- stay English). Keys, caches and lookups stay English underneath.
function Encyclopedia.DataAccess.display_name(name)
    local display = Encyclopedia.NameDisplay
    if display == nil or type(name) ~= "string" then
        return name
    end
    return display[name] or name
end

function Encyclopedia.DataAccess.resolve_entry(source, index, name)
    local resolved_key = _resolve_key(source, index, name)
    if type(resolved_key) ~= "string" then
        return nil, nil
    end

    local entry = source[resolved_key]
    if type(entry) ~= "table" or _is_alias_entry(entry) == true then
        return nil, nil
    end

    return resolved_key, entry
end

function Encyclopedia.DataAccess.resolve_builtin_name(name)
    local resolved_key = _resolve_key(BUILTIN_BESTIARY, Encyclopedia.DataAccess.get_builtin_index(), name)
    if type(resolved_key) == "string" then
        return resolved_key
    end

    return _normalize_name(name)
end

function Encyclopedia.DataAccess.get_group_keys(source, index, base_name)
    local normalized = _normalize_name(base_name)
    if normalized == nil or type(index) ~= "table" then
        return nil
    end

    return _copy_array(index.group_keys_by_base_lower[_lower(normalized)])
end

function Encyclopedia.DataAccess.new_merged_entry(name)
    return _new_merged_entry(name)
end

function Encyclopedia.DataAccess.merge_entry(dst, src, name)
    _merge_entry(dst, src, name)
end

function Encyclopedia.DataAccess.build_drop_records(entry)
    return _build_drop_records(entry)
end

function Encyclopedia.DataAccess.is_alias_entry(entry)
    return _is_alias_entry(entry)
end

-- legacy-name normalization is a one-time migration pass, not a per-access
-- cost: runtime writes only insert already-normalized names, so the scan
-- runs once per cache table plus once more after the async disk load
-- merges historical entries in (ensure_cache sits on the combat hot path
-- via the tracker's morale/power callbacks)
local CACHE_NORMALIZED_FOR = nil
local CACHE_NORMALIZED_LOADED = false

function Encyclopedia.DataAccess.ensure_cache()
    local cache = Persistence.ensure_bestiary_cache()

    local loaded = BestiaryCache.loaded == true
    if CACHE_NORMALIZED_FOR ~= cache or (loaded == true and CACHE_NORMALIZED_LOADED ~= true) then
        local changed = false
        cache, changed = _normalize_cache_table(cache)
        if changed == true then
            CACHE_INDEX = nil
            CACHE_GENERATION = nil
        end
        CACHE_NORMALIZED_FOR = cache
        CACHE_NORMALIZED_LOADED = loaded
    end

    return cache
end

function Encyclopedia.DataAccess.normalize_name(name)
    return _normalize_name(name)
end
