-- One-time compact loot layout requested by the user. Later edits are retained.
local Migrations = _G.LUI.Settings.Migrations
Migrations.register_settings_migration("2.3.0.5", {
    profile = function(profile)
        if type(profile) ~= "table" then return profile end
        if type(profile.drops) ~= "table" then profile.drops = {} end
        local drops = profile.drops
        if drops.setup_compact_loot_v2 == true then return profile end
        drops.width = math.max(140, math.min(tonumber(drops.width) or 260, 260))
        drops.rows = math.max(1, math.min(tonumber(drops.rows) or 4, 4))
        drops.icon_size = math.max(1, math.min(tonumber(drops.icon_size) or 24, 24))
        drops.setup_compact_loot_v2 = true
        return profile
    end,
})
