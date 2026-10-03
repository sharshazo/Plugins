-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Example migration file.
-- This file is intentionally not imported. It exists only as a template.
--
-- One migration step per file. VERSION is the last plugin version that
-- wrote the OLD shape: the step runs for every config saved at or below it,
-- and the runner chains all applicable steps oldest-first. Because a step
-- sees saves from any older version, it must be idempotent: probe for the
-- old shape, transform it if present, do nothing otherwise. Never set
-- config.version — the runner stamps it after each step.

local VERSION = "0.6.0"
local Migrations = _G.LUI.Settings.Migrations

local function migrate_account(account_settings)
    account_settings.some_removed_root_field = nil
    return account_settings
end

-- from_version is the originally saved version string. Almost never needed;
-- use it only when old data has the same shape but a different meaning and
-- must be left untouched below some version.
local function migrate_profile(profile_settings, from_version)
    if type(profile_settings.height) == "number" then
        if type(profile_settings.window) ~= "table" then
            profile_settings.window = {}
        end
        profile_settings.window.height = profile_settings.height
        profile_settings.height = nil
    end
    return profile_settings
end

local function migrate_character(character_settings)
    character_settings.legacy_flag = nil
    return character_settings
end

Migrations.register_settings_migration(VERSION, {
    account = migrate_account,
    profile = migrate_profile,
    character = migrate_character,
})
