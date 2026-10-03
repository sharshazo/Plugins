-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- v2.2.1 -> next: the encyclopedia entry points were saved under the
-- shortcut key "bestiary": launcher button lists ("bestiary") and status
-- bar layout tokens ("%bestiary%"). Both rename to "encyclopedia".

local VERSION = "2.2.1"
local Migrations = _G.LUI.Settings.Migrations

local LAYOUT_ZONES = { "left", "center", "right" }

local function migrate_profile(profile_settings)
    local launcher = profile_settings.launcher
    if type(launcher) == "table" and type(launcher.buttons) == "table" then
        for i = 1, #launcher.buttons do
            if launcher.buttons[i] == "bestiary" then
                launcher.buttons[i] = "encyclopedia"
            end
        end
    end

    local status_bar = profile_settings.status_bar
    if type(status_bar) == "table" and type(status_bar.layout) == "table" then
        local layout = status_bar.layout
        for i = 1, #LAYOUT_ZONES do
            local zone = LAYOUT_ZONES[i]
            if type(layout[zone]) == "string" then
                layout[zone] = string.gsub(layout[zone], "%%bestiary%%", "%%encyclopedia%%")
            end
        end
    end

    return profile_settings
end

Migrations.register_settings_migration(VERSION, {
    profile = migrate_profile,
})
