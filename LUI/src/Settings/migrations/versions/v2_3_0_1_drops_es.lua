-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- One-time setup of the Drops ("Botin") loot window, requested by the
-- player: turn it on and give it the classic MMO loot-feed look --
-- each looted item pops up in a queue at the TOP-LEFT of the screen and
-- disappears after 2 seconds at most (1.5 s fully visible + the window's
-- fixed 0.5 s fade-out).
--
-- default_schema.lua alone never reaches an existing saved profile
-- (defaults_fill.lua only fills MISSING keys), so this step applies the new
-- values to profiles that already exist. It runs ONCE per profile: the
-- marker drops.setup_es_loot_v1 is stored in the profile, and after that
-- the step is a no-op -- anything the player changes later in
-- /lui config -> Botin (or moves with /lui move) is never overwritten.
--
-- Tag "2.3.0.1": the plugin is still 2.3.0 and v2_3_0.lua already owns the
-- "2.3.0" slot (duplicate tags are rejected by the registry). A save
-- stamped 2.3.0 is not newer than 2.3.0.1, so this step is always
-- considered -- the marker is what makes it one-shot.

local VERSION = "2.3.0.1"
local Migrations = _G.LUI.Settings.Migrations

local MARKER = "setup_es_loot_v1"

local function _table_child(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    return parent[key]
end

local function migrate_profile(profile_settings)
    if type(profile_settings) ~= "table" then
        return profile_settings
    end

    local drops = _table_child(profile_settings, "drops")
    if drops[MARKER] == true then
        return profile_settings
    end

    drops.enabled = true
    drops.visible_duration = 1.5
    drops.rows = 6
    drops.icon_size = 32
    drops.width = 300
    drops.align = 1            -- vertical_align.TOP (window anchored at the top)
    drops.flow = 2             -- list_flow.BOTTOM_TO_TOP: oldest on top, new loot joins the end of the queue
    drops.icon_side = 1        -- side.LEFT
    drops.merge_similar = true
    drops.animations_enabled = true
    drops.move_duration = 250

    local item = _table_child(drops, "item")
    item.background_opacity = 0.55

    -- top-left of the screen, just under the target frame (default target
    -- vitals sit at 370,40) and clear of the LUI launcher (20,260) and the
    -- fellowship/raid frames (x 0-440, y 420+). Movable with /lui move.
    local ui = _table_child(profile_settings, "ui")
    local hud = _table_child(ui, "hud")
    local pos = _table_child(hud, "drops")
    pos.left = 370
    pos.top = 150

    drops[MARKER] = true
    return profile_settings
end

Migrations.register_settings_migration(VERSION, {
    profile = migrate_profile,
})
