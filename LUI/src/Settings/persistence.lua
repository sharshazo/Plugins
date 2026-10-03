-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ACCOUNT_DATA_SCOPE = Turbine.DataScope.Account
local SERVER_DATA_SCOPE = Turbine.DataScope.Server
local CHARACTER_DATA_SCOPE = Turbine.DataScope.Character

local ACCOUNT_DATA_KEY = "LUI_PROFILES"
local CHARACTER_DATA_KEY = "LUI_CHARACTER"
local SERVER_ASSETS_CACHE_KEY = "LUI_ASSETS_CACHE"
local SERVER_BESTIARY_CACHE_KEY = "LUI_BESTIARY_CACHE"

local FALLBACK_PROFILE_NAME = "Configuration"
local UNKNOWN_CHARACTER_NAME = "__unknown_character__"
local LUI = _G.LUI
local Settings = LUI.Settings
local State = Settings.State
local Persistence = Settings.Persistence
local Migrations = Settings.Migrations
local Defaults = Settings.Defaults
local PluginDataTypes = Settings.PluginDataTypes
local Windows = LUI.Runtime.Windows
local Stores = LUI.Runtime.Stores
local Flags = LUI.Runtime.Flags
local AssetCache = LUI.Runtime.Caches.Assets
local BestiaryCache = LUI.Runtime.Caches.Bestiary

local PLUGIN_DATA_SCHEMAS = {
    [ACCOUNT_DATA_KEY] = PluginDataTypes.ACCOUNT,
    [CHARACTER_DATA_KEY] = PluginDataTypes.CHARACTER,
    [SERVER_ASSETS_CACHE_KEY] = PluginDataTypes.ASSETS_CACHE,
    [SERVER_BESTIARY_CACHE_KEY] = PluginDataTypes.BESTIARY_CACHE,
}

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = _copy_table(v)
    end

    return copy
end

local function _trim(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = string.gsub(text, "^%s+", "")
    trimmed = string.gsub(trimmed, "%s+$", "")
    if string.len(trimmed) == 0 then
        return nil
    end

    return trimmed
end

local function _plugin_data_schema(key)
    local schema = PLUGIN_DATA_SCHEMAS[key]
    if schema == nil then
        error("Missing plugin data type schema: " .. tostring(key))
    end

    return schema
end

local function _save_plugin_data(scope, key, data)
    Turbine.PluginData.Save(scope, key, PluginDataTypes.encode(data, _plugin_data_schema(key)))
end

local function _write_plugin_data_load_error(key, err)
    if Turbine.Shell ~= nil and type(Turbine.Shell.WriteLine) == "function" then
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: Corrupted PluginData file for " .. tostring(key) .. ". Replacing it with a clean file. " .. tostring(err))
    end
end

local function _wipe_corrupted_plugin_data(scope, key, err)
    _write_plugin_data_load_error(key, err)
    _save_plugin_data(scope, key, {})
end

local function _load_plugin_data_raw(scope, key, callback)
    local ok, loaded = pcall(function()
        if callback ~= nil then
            return Turbine.PluginData.Load(scope, key, callback)
        end

        return Turbine.PluginData.Load(scope, key)
    end)

    if ok ~= true then
        _wipe_corrupted_plugin_data(scope, key, loaded)
        return nil
    end

    return loaded
end

local function _load_plugin_data(scope, key, callback)
    local schema = _plugin_data_schema(key)
    if callback ~= nil then
        local loaded = _load_plugin_data_raw(scope, key, function(data)
            callback(PluginDataTypes.decode(data, schema))
        end)
        return PluginDataTypes.decode(loaded, schema)
    end

    return PluginDataTypes.decode(_load_plugin_data_raw(scope, key), schema)
end

local function _compute_next_profile_id(profiles)
    local next_profile_id = 1
    if type(profiles) ~= "table" then
        return next_profile_id
    end

    for profile_id, profile in pairs(profiles) do
        if type(profile) == "table" then
            local numeric_profile_id = tonumber(profile_id)
            if numeric_profile_id ~= nil then
                local candidate = math.floor(numeric_profile_id + 1)
                if candidate > next_profile_id then
                    next_profile_id = candidate
                end
            end
        end
    end

    return next_profile_id
end

local function _get_current_character_name()
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetName == nil then
        return UNKNOWN_CHARACTER_NAME
    end

    local name = player:GetName()
    if type(name) ~= "string" or string.len(name) == 0 then
        return UNKNOWN_CHARACTER_NAME
    end

    return name
end

local function _profile_label(profile_id, profile)
    local name = profile.name
    if type(name) == "string" and string.len(name) > 0 then
        return name
    end

    return FALLBACK_PROFILE_NAME .. " " .. tostring(profile_id)
end

local function _stamp_profile_settings_version(settings)
    if type(settings) ~= "table" then
        return
    end

    settings.version = Migrations.get_settings_version()
end

local function _stamp_account_settings_version(account_settings)
    if type(account_settings) ~= "table" then
        return
    end

    account_settings.version = Migrations.get_settings_version()

    local profiles = account_settings.profiles
    if type(profiles) ~= "table" then
        return
    end

    for _, profile in pairs(profiles) do
        if type(profile) == "table" and type(profile.settings) == "table" then
            _stamp_profile_settings_version(profile.settings)
        end
    end
end

local function _stamp_character_settings_version(character_settings)
    if type(character_settings) ~= "table" then
        return
    end

    character_settings.version = Migrations.get_settings_version()
end

local function _save_settings_files_raw()
    _save_plugin_data(ACCOUNT_DATA_SCOPE, ACCOUNT_DATA_KEY, State.account_settings)
    _save_plugin_data(CHARACTER_DATA_SCOPE, CHARACTER_DATA_KEY, State.character_settings)
end

local function _migrate_account_profiles(account_settings)
    local profiles = account_settings.profiles
    if type(profiles) ~= "table" then
        return false
    end

    local changed = false
    for profile_id, profile in pairs(profiles) do
        if type(profile) ~= "table" or type(profile.settings) ~= "table" then
            profiles[profile_id] = nil
            changed = true
        else
            local migrated_settings, settings_changed = Migrations.migrate_profile_settings(profile.settings)
            if type(migrated_settings) ~= "table" then
                profiles[profile_id] = nil
                changed = true
            else
                profile.settings = migrated_settings
                if settings_changed == true then
                    changed = true
                end
            end
        end
    end

    return changed
end

local function _sync_current_profile_settings()
    Persistence.ensure_account_settings()

    if State.current_profile_id == nil then
        local profile_id = Persistence.create_configuration(State.current_character_name, State.loaded_settings)
        Persistence.assign_character_profile(profile_id)
        return
    end

    local profile = State.account_settings.profiles[State.current_profile_id]
    if type(profile) ~= "table" then
        local profile_id = Persistence.create_configuration(State.current_character_name, State.loaded_settings)
        Persistence.assign_character_profile(profile_id)
        return
    end

    if type(profile.name) ~= "string" or string.len(profile.name) == 0 then
        profile.name = State.current_character_name
    end

    profile.settings = State.loaded_settings
end

function Persistence.ensure_account_settings()
    if type(State.account_settings) ~= "table" then
        State.account_settings = {}
    end

    local s = State.account_settings
    if type(s.profiles) ~= "table" then
        s.profiles = {}
    end
    local min_next_profile_id = _compute_next_profile_id(s.profiles)
    local next_profile_id = tonumber(s.next_profile_id)
    if next_profile_id == nil then
        next_profile_id = min_next_profile_id
    else
        next_profile_id = math.floor(next_profile_id + 0.5)
        if next_profile_id < min_next_profile_id then
            next_profile_id = min_next_profile_id
        end
    end
    s.next_profile_id = next_profile_id
end

function Persistence.ensure_character_settings()
    if type(State.character_settings) ~= "table" then
        State.character_settings = {}
    end

    local s = State.character_settings
    if type(s.crafting) ~= "table" then
        s.crafting = {}
    end
end

local function _merge_assets_cache(loaded)
    if type(loaded) ~= "table" then
        return
    end

    if type(AssetCache.data) ~= "table" or next(AssetCache.data) == nil then
        AssetCache.data = loaded
        return
    end

    local current = AssetCache.data
    if type(current.characters) ~= "table" then
        current.characters = {}
    end
    if type(loaded.characters) == "table" then
        for character_name, loaded_character_cache in pairs(loaded.characters) do
            if type(current.characters[character_name]) ~= "table" then
                current.characters[character_name] = loaded_character_cache
            elseif type(loaded_character_cache) == "table" then
                local current_character_cache = current.characters[character_name]
                local source_names = { "backpack", "bank", "vault" }
                for i = 1, #source_names do
                    local source_name = source_names[i]
                    local current_source = current_character_cache[source_name]
                    local loaded_source = loaded_character_cache[source_name]
                    if type(current_source) ~= "table" or type(current_source.items) ~= "table" or #current_source.items <= 0 then
                        current_character_cache[source_name] = loaded_source
                    end
                end
            end
        end
    end

    if type(current.shared_storage) ~= "table" or type(current.shared_storage.items) ~= "table" or #current.shared_storage.items <= 0 then
        current.shared_storage = loaded.shared_storage
    end
end

local function _merge_count_map(target, source)
    if type(source) ~= "table" then
        return
    end
    if type(target) ~= "table" then
        return
    end

    for key, value in pairs(source) do
        target[key] = (tonumber(target[key]) or 0) + (tonumber(value) or 0)
    end
end

local function _merge_bestiary_level_map(target, source)
    if type(source) ~= "table" then
        return
    end

    for level, info in pairs(source) do
        local target_info = target[level]
        local morale = tonumber(info.m) or 0
        local power = tonumber(info.p) or 0
        if type(target_info) ~= "table" then
            target[level] = {
                m = morale,
                p = power,
            }
        else
            if morale > (tonumber(target_info.m) or 0) then
                target_info.m = morale
            end
            if power > (tonumber(target_info.p) or 0) then
                target_info.p = power
            end
        end
    end
end

local function _merge_bestiary_cache(loaded)
    if type(loaded) ~= "table" then
        return
    end

    if type(BestiaryCache.data) ~= "table" or next(BestiaryCache.data) == nil then
        BestiaryCache.data = loaded
        return
    end

    local current = BestiaryCache.data
    for name, loaded_entry in pairs(loaded) do
        if type(current[name]) ~= "table" then
            current[name] = loaded_entry
        elseif type(loaded_entry) == "table" then
            local current_entry = current[name]
            current_entry.k = (tonumber(current_entry.k) or 0) + (tonumber(loaded_entry.k) or 0)
            if type(current_entry.levels) ~= "table" then
                current_entry.levels = {}
            end
            if type(current_entry.d) ~= "table" then
                current_entry.d = {}
            end
            _merge_bestiary_level_map(current_entry.levels, loaded_entry.levels)
            _merge_count_map(current_entry.d, loaded_entry.d)
        end
    end
end

function Persistence.ensure_assets_cache()
    if AssetCache.loaded ~= true and AssetCache.loading ~= true then
        AssetCache.loading = true
        local loaded = _load_plugin_data(SERVER_DATA_SCOPE, SERVER_ASSETS_CACHE_KEY, function(data)
            if Flags.is_unloading == true then
                return
            end
            _merge_assets_cache(data)
            AssetCache.loaded = true
            AssetCache.loading = false
            if AssetCache.dirty ~= true then
                AssetCache.dirty = false
            end
            if Stores.assets ~= nil then
                Stores.assets.generation = (tonumber(Stores.assets.generation) or 0) + 1
            end
        end)
        if loaded ~= nil then
            _merge_assets_cache(loaded)
            AssetCache.loaded = true
            AssetCache.loading = false
            if AssetCache.dirty ~= true then
                AssetCache.dirty = false
            end
        end
    end

    if type(AssetCache.data) ~= "table" then
        AssetCache.data = {}
    end

    local cache = AssetCache.data
    if type(cache.characters) ~= "table" then
        cache.characters = {}
    end
    if type(cache.shared_storage) ~= "table" then
        cache.shared_storage = { items = {} }
    elseif type(cache.shared_storage.items) ~= "table" then
        cache.shared_storage.items = {}
    end

    return cache
end

function Persistence.ensure_bestiary_cache()
    if BestiaryCache.loaded ~= true and BestiaryCache.loading ~= true then
        BestiaryCache.loading = true
        local loaded = _load_plugin_data(SERVER_DATA_SCOPE, SERVER_BESTIARY_CACHE_KEY, function(data)
            if Flags.is_unloading == true then
                return
            end
            _merge_bestiary_cache(data)
            BestiaryCache.loaded = true
            BestiaryCache.loading = false
            if BestiaryCache.dirty ~= true then
                BestiaryCache.dirty = false
            end
            -- a whole-cache merge invalidates every record, not a named
            -- few; consumers must rebuild instead of patching dirty names
            BestiaryCache.dirty_all = true
            BestiaryCache.generation = (BestiaryCache.generation or 0) + 1
        end)
        if loaded ~= nil then
            _merge_bestiary_cache(loaded)
            BestiaryCache.loaded = true
            BestiaryCache.loading = false
            if BestiaryCache.dirty ~= true then
                BestiaryCache.dirty = false
            end
        end
    end

    if type(BestiaryCache.data) ~= "table" then
        BestiaryCache.data = {}
    end
    if type(BestiaryCache.generation) ~= "number" then
        BestiaryCache.generation = 1
    end

    return BestiaryCache.data
end

function Persistence.create_configuration(name, settings)
    Persistence.ensure_account_settings()

    local s = State.account_settings
    _stamp_account_settings_version(s)
    local profile_id = tostring(s.next_profile_id)
    s.next_profile_id = s.next_profile_id + 1
    _stamp_profile_settings_version(settings)

    s.profiles[profile_id] = {
        name = name,
        settings = settings,
    }

    return profile_id
end

function Persistence.assign_character_profile(profile_id)
    Persistence.ensure_account_settings()
    Persistence.ensure_character_settings()

    local profile = State.account_settings.profiles[profile_id]
    if type(profile) ~= "table" or type(profile.settings) ~= "table" then
        return false
    end

    local character_name = State.current_character_name or _get_current_character_name()
    State.character_settings.profile_id = profile_id

    State.current_character_name = character_name
    State.current_profile_id = profile_id
    State.loaded_settings = profile.settings
    return true
end

function Persistence.get_configuration_options()
    Persistence.ensure_account_settings()

    local entries = {}
    for profile_id, profile in pairs(State.account_settings.profiles) do
        if type(profile) == "table" and type(profile.settings) == "table" then
            entries[#entries + 1] = {
                label = _profile_label(profile_id, profile),
                value = profile_id,
            }
        end
    end

    table.sort(entries, function(a, b)
        local left = string.lower(a.label)
        local right = string.lower(b.label)
        if left == right then
            return tostring(a.value) < tostring(b.value)
        end
        return left < right
    end)

    local labels = {}
    local values = {}
    for i = 1, #entries do
        labels[i] = entries[i].label
        values[i] = entries[i].value
    end

    return labels, values
end

function Persistence.get_configuration(profile_id)
    Persistence.ensure_account_settings()
    return State.account_settings.profiles[profile_id]
end

function Persistence.get_configuration_name(profile_id)
    local profile = Persistence.get_configuration(profile_id)
    if type(profile) ~= "table" then
        return nil
    end

    return _profile_label(profile_id, profile)
end

function Persistence.get_configuration_count()
    Persistence.ensure_account_settings()

    local count = 0
    for _, profile in pairs(State.account_settings.profiles) do
        if type(profile) == "table" and type(profile.settings) == "table" then
            count = count + 1
        end
    end

    return count
end

function Persistence.get_first_configuration_id()
    local _, values = Persistence.get_configuration_options()
    return values[1]
end

function Persistence.rename_configuration(profile_id, name)
    Persistence.ensure_account_settings()

    local profile = State.account_settings.profiles[profile_id]
    local trimmed_name = _trim(name)
    if type(profile) ~= "table" or trimmed_name == nil then
        return false
    end

    profile.name = trimmed_name
    return true
end

function Persistence.duplicate_configuration(profile_id)
    Persistence.ensure_account_settings()

    local profile = State.account_settings.profiles[profile_id]
    if type(profile) ~= "table" or type(profile.settings) ~= "table" then
        return nil
    end

    local duplicate_name = _profile_label(profile_id, profile) .. " (copy)"
    local duplicate_settings = _copy_table(profile.settings)
    return Persistence.create_configuration(duplicate_name, duplicate_settings)
end

function Persistence.delete_configuration(profile_id)
    Persistence.ensure_account_settings()
    Persistence.ensure_character_settings()

    if Persistence.get_configuration_count() <= 1 then
        return false
    end

    local profile = State.account_settings.profiles[profile_id]
    if type(profile) ~= "table" then
        return false
    end

    State.account_settings.profiles[profile_id] = nil

    if State.character_settings.profile_id == profile_id then
        State.character_settings.profile_id = nil
    end

    if State.current_profile_id == profile_id then
        State.current_profile_id = nil
    end

    return true
end

function Persistence.save_settings()
    if Windows.first_run_quick_setup ~= nil and Windows.first_run_quick_setup.closing ~= true then
        return
    end

    Persistence.ensure_account_settings()
    Persistence.ensure_character_settings()

    Persistence.capture_runtime_geometry()

    _sync_current_profile_settings()
    _stamp_account_settings_version(State.account_settings)
    _stamp_character_settings_version(State.character_settings)

    _save_settings_files_raw()
end

function Persistence.capture_runtime_geometry()
    if Windows.config ~= nil then
        Windows.config:update_saved_geometry()
    end

    if Windows.inventory ~= nil then
        Windows.inventory:capture_geometry()
    end

    if Windows.assets ~= nil then
        Windows.assets:capture_geometry()
    end

    if Windows.encyclopedia ~= nil then
        Windows.encyclopedia:capture_geometry()
    end

    if Flags.is_unloading ~= true and Windows.crafting ~= nil then
        Windows.crafting:capture_geometry()
    end

    if Flags.is_unloading ~= true and Windows.travel ~= nil then
        Windows.travel:capture_geometry()
    end
end

function Persistence.save_assets_cache()
    if AssetCache.dirty ~= true then
        return
    end
    if type(AssetCache.data) ~= "table" then
        AssetCache.data = {}
    end
    _save_plugin_data(SERVER_DATA_SCOPE, SERVER_ASSETS_CACHE_KEY, AssetCache.data)
    AssetCache.dirty = false
end

function Persistence.save_bestiary_cache()
    if BestiaryCache.dirty ~= true then
        return
    end
    if type(BestiaryCache.data) ~= "table" then
        BestiaryCache.data = {}
    end
    _save_plugin_data(SERVER_DATA_SCOPE, SERVER_BESTIARY_CACHE_KEY, BestiaryCache.data)
    BestiaryCache.dirty = false
end

function Persistence.load_settings()
    State.account_settings = _load_plugin_data(ACCOUNT_DATA_SCOPE, ACCOUNT_DATA_KEY)
    State.character_settings = _load_plugin_data(CHARACTER_DATA_SCOPE, CHARACTER_DATA_KEY)
    AssetCache.data = nil
    AssetCache.loaded = false
    AssetCache.loading = false
    AssetCache.dirty = false
    BestiaryCache.data = nil
    BestiaryCache.loaded = false
    BestiaryCache.loading = false
    BestiaryCache.dirty = false

    local migrated_any = false

    if type(State.account_settings) == "table" then
        local migrated_account_settings, account_changed = Migrations.migrate_account_settings(State.account_settings)
        if type(migrated_account_settings) == "table" then
            State.account_settings = migrated_account_settings
            if account_changed == true then
                migrated_any = true
            end
            if _migrate_account_profiles(State.account_settings) == true then
                migrated_any = true
            end
        else
            State.account_settings = nil
            migrated_any = true
        end
    else
        State.account_settings = nil
    end

    if type(State.character_settings) == "table" then
        local migrated_character_settings, character_changed = Migrations.migrate_character_settings(State.character_settings)
        if type(migrated_character_settings) == "table" then
            State.character_settings = migrated_character_settings
            if character_changed == true then
                migrated_any = true
            end
        else
            State.character_settings = nil
            migrated_any = true
        end
    else
        State.character_settings = nil
    end

    Persistence.ensure_account_settings()
    Persistence.ensure_character_settings()

    State.current_character_name = _get_current_character_name()
    State.current_profile_id = nil

    local profile_id = State.character_settings.profile_id

    local profile = nil
    if profile_id ~= nil then
        profile = State.account_settings.profiles[profile_id]
        if type(profile) ~= "table" or type(profile.settings) ~= "table" then
            State.character_settings.profile_id = nil
            profile_id = nil
            migrated_any = true
        end
    end

    if profile_id == nil then
        profile_id = Persistence.get_first_configuration_id()
        if profile_id ~= nil then
            profile = State.account_settings.profiles[profile_id]
            State.character_settings.profile_id = profile_id
            migrated_any = true
        end
    end

    if migrated_any == true and type(profile) == "table" and type(profile.settings) == "table" then
        _stamp_account_settings_version(State.account_settings)
        _stamp_character_settings_version(State.character_settings)
        _save_settings_files_raw()
    end

    State.loaded_settings_was_new = true
    if type(profile) == "table" and type(profile.settings) == "table" then
        State.current_profile_id = profile_id
        State.loaded_settings = profile.settings
        State.loaded_settings_was_new = false
    else
        State.loaded_settings = {}
    end

    local defaults_filled = Defaults.ensure_loaded_settings()
    if defaults_filled == true and type(profile) == "table" and type(profile.settings) == "table" then
        profile.settings = State.loaded_settings
        _stamp_account_settings_version(State.account_settings)
        _stamp_character_settings_version(State.character_settings)
        _save_settings_files_raw()
    end
    Settings.Colors.fix_colors()
    Settings.rebuild()
end
