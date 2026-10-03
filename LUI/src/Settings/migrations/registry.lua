-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Settings migration chain. Migrations are ordered checkpoints, one file per
-- step under migrations/versions/. The engine has exactly two rules:
--
-- 1. Selection: a config saved at version S runs every migration whose tag
--    is >= S. A tag is the last plugin version that wrote the old shape, so
--    a save stamped exactly at the tag still needs the step.
-- 2. Order: applicable steps run in ascending tag order. After each step the
--    runner sets config.version to that step's tag, and after the last one
--    stamps the current version. Steps never set config.version themselves.

local Migrations = _G.LUI.Settings.Migrations

local function _current_settings_version()
    return tostring(Plugins["LUI"]:GetVersion())
end

local function _parse_version(text)
    local parts = {}
    for piece in string.gmatch(text, "%d+") do
        parts[#parts + 1] = tonumber(piece)
    end
    return parts
end

-- strict less-than, component-wise, missing components = 0 ("2.2" == "2.2.0")
local function _version_lt(a, b)
    for i = 1, math.max(#a, #b) do
        local av = a[i] or 0
        local bv = b[i] or 0
        if av ~= bv then
            return av < bv
        end
    end
    return false
end

Migrations.Registry = Migrations.Registry or {}
Migrations.Registry.account = Migrations.Registry.account or {}
Migrations.Registry.profile = Migrations.Registry.profile or {}
Migrations.Registry.character = Migrations.Registry.character or {}

function Migrations.get_settings_version()
    return _current_settings_version()
end

local SCOPES = { "account", "profile", "character" }

-- version: the last plugin version that wrote the old shape. step: a table
-- with account/profile/character functions; each receives (config,
-- from_version) where from_version is the originally saved version string,
-- and must transform and return the config.
function Migrations.register_settings_migration(version, step)
    if type(version) ~= "string" then
        error("Settings migration version must be a string")
    end
    local tag = _parse_version(version)
    if #tag == 0 then
        error("Settings migration version is not a version: " .. version)
    end
    if type(step) ~= "table" then
        error("Settings migration step must be a table")
    end

    local registered = false
    for i = 1, #SCOPES do
        local scope = SCOPES[i]
        local fn = step[scope]
        if fn ~= nil then
            if type(fn) ~= "function" then
                error("Settings migration " .. scope .. " step must be a function")
            end
            local registry = Migrations.Registry[scope]
            if registry[version] ~= nil then
                error("Duplicate " .. scope .. " settings migration: " .. version)
            end
            registry[version] = { version = version, tag = tag, fn = fn }
            registered = true
        end
    end

    if registered ~= true then
        error("Settings migration step must define account, profile, or character")
    end
end

local function _run_migrations(config, registry)
    if type(config) ~= "table" then
        return nil, false
    end
    if type(config.version) ~= "string" then
        return nil, false
    end

    local current_version = _current_settings_version()
    local from_version = config.version
    local saved = _parse_version(from_version)
    local steps_run = 0

    -- An unparseable saved version has unknown provenance: run no steps and
    -- restamp. (Returning nil would make persistence drop the config.)
    if #saved > 0 then
        local entries = {}
        for _, entry in pairs(registry) do
            if _version_lt(entry.tag, saved) ~= true then
                entries[#entries + 1] = entry
            end
        end
        table.sort(entries, function(a, b)
            return _version_lt(a.tag, b.tag)
        end)

        for i = 1, #entries do
            config = entries[i].fn(config, from_version)
            if type(config) ~= "table" then
                return nil, true
            end
            config.version = entries[i].version
            steps_run = steps_run + 1
        end
    end

    local changed = steps_run > 0 or from_version ~= current_version
    config.version = current_version
    return config, changed
end

function Migrations.migrate_account_settings(config)
    return _run_migrations(config, Migrations.Registry.account)
end

function Migrations.migrate_profile_settings(config)
    return _run_migrations(config, Migrations.Registry.profile)
end

function Migrations.migrate_character_settings(config)
    return _run_migrations(config, Migrations.Registry.character)
end
