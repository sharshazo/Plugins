-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- (2026-09-30) Icono del menu LUI (launcher) de vuelta. Los perfiles
-- creados con "Nuevo" (asistente rapido) lo dejaban APAGADO porque el
-- asistente arrancaba en "No" y el valor de fabrica era false, y el
-- jugador se quedaba sin el icono. El valor de fabrica y el asistente
-- ahora arrancan en "Si"; este paso lo vuelve a encender UNA vez en cada
-- perfil guardado (marca launcher.setup_menu_v1). Si despues el jugador
-- lo apaga a proposito (Configuracion > Menu LUI, o "/lui menu off"), se
-- respeta: la marca ya esta puesta y no vuelve a correr. Los perfiles
-- nuevos ya traen la marca en true (default_schema), asi que este paso
-- solo toca los perfiles guardados antes (sin la marca).

local VERSION = "2.3.0.3"
local Migrations = _G.LUI.Settings.Migrations

local function migrate_profile(profile_settings)
    if type(profile_settings) ~= "table" then
        return profile_settings
    end
    local launcher = profile_settings.launcher
    if type(launcher) ~= "table" then
        return profile_settings
    end
    if launcher.setup_menu_v1 == true then
        return profile_settings
    end
    launcher.enabled = true
    launcher.setup_menu_v1 = true
    return profile_settings
end

Migrations.register_settings_migration(VERSION, {
    profile = migrate_profile,
})
