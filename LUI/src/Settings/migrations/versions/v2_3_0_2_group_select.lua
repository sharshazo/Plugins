-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Seleccion notoria en los marcos de party / raid (pedido del jugador):
-- el borde del companero seleccionado pasa de rosa 2 px a DORADO 3 px.
--
-- default_schema.lua solo llega a perfiles NUEVOS (defaults_fill completa
-- claves que faltan, no cambia las que ya existen), asi que este paso
-- actualiza los perfiles guardados. Solo toca el color / grosor si siguen
-- con el valor de fabrica anterior: si el jugador ya los habia cambiado a
-- su gusto, se respetan. Corre UNA vez por perfil (marca
-- select.setup_select_v2 en fellowship y en raid).
--
-- Tag "2.3.0.2": el plugin sigue en 2.3.0 y 2.3.0 / 2.3.0.1 ya estan
-- usados (el registro rechaza tags repetidos); la marca lo hace de una vez.
-- Las opciones nuevas (aura, resaltado al pasar el mouse, aviso de vida
-- baja) no necesitan migracion: defaults_fill las agrega con su valor de
-- fabrica.

local VERSION = "2.3.0.2"
local Migrations = _G.LUI.Settings.Migrations

local MARKER = "setup_select_v2"

local OLD_R, OLD_G, OLD_B = 1.0, 0.309804, 0.847059
local NEW_R, NEW_G, NEW_B = 1.0, 0.823529, 0.247059

local function _near(a, b)
    return type(a) == "number" and math.abs(a - b) < 0.002
end

local function _migrate_select(root)
    if type(root) ~= "table" then
        return
    end
    local select = root.select
    if type(select) ~= "table" then
        return
    end
    if select[MARKER] == true then
        return
    end

    local color = select.border_color
    if type(color) == "table" and _near(color.R, OLD_R) and _near(color.G, OLD_G) and _near(color.B, OLD_B) then
        color.R = NEW_R
        color.G = NEW_G
        color.B = NEW_B
    end
    if select.border_width == 2 then
        select.border_width = 3
    end

    select[MARKER] = true
end

local function migrate_profile(profile_settings)
    if type(profile_settings) ~= "table" then
        return profile_settings
    end
    _migrate_select(profile_settings.fellowship)
    _migrate_select(profile_settings.raid)
    return profile_settings
end

Migrations.register_settings_migration(VERSION, {
    profile = migrate_profile,
})
