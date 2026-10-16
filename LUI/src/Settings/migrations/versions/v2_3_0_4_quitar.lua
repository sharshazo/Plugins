-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- (2026-10-16) Las ventanas "Viaje" (travel) y "Bienes" (assets) se
-- quitaron de LUI. Este paso borra sus atajos guardados en cada perfil:
-- los botones "travel"/"assets" del menu LUI y las variables %travel% /
-- %assets% de la barra de estado. Es idempotente (si ya no estan, no
-- cambia nada), asi que puede volver a correr sin efectos.

local VERSION = "2.3.0.4"
local Migrations = _G.LUI.Settings.Migrations

local REMOVED_SHORTCUTS = { travel = true, assets = true }
local LAYOUT_ZONES = { "left", "center", "right" }

local function _strip_layout_tokens(text)
    local out, n_travel = string.gsub(text, "%%[Tt][Rr][Aa][Vv][Ee][Ll]%%", "")
    local n_assets
    out, n_assets = string.gsub(out, "%%[Aa][Ss][Ss][Ee][Tt][Ss]%%", "")
    if (n_travel + n_assets) == 0 then
        return text
    end
    out = string.gsub(out, "%s%s+", " ")
    out = string.gsub(out, "^%s+", "")
    out = string.gsub(out, "%s+$", "")
    return out
end

local function migrate_profile(profile_settings)
    if type(profile_settings) ~= "table" then
        return profile_settings
    end

    local launcher = profile_settings.launcher
    if type(launcher) == "table" and type(launcher.buttons) == "table" then
        local kept = {}
        for i = 1, #launcher.buttons do
            local key = launcher.buttons[i]
            if REMOVED_SHORTCUTS[key] ~= true then
                kept[#kept + 1] = key
            end
        end
        if #kept ~= #launcher.buttons then
            launcher.buttons = kept
        end
    end

    local status_bar = profile_settings.status_bar
    if type(status_bar) == "table" and type(status_bar.layout) == "table" then
        local layout = status_bar.layout
        for i = 1, #LAYOUT_ZONES do
            local zone = LAYOUT_ZONES[i]
            if type(layout[zone]) == "string" then
                layout[zone] = _strip_layout_tokens(layout[zone])
            end
        end
    end

    return profile_settings
end

Migrations.register_settings_migration(VERSION, {
    profile = migrate_profile,
})
