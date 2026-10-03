-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Class-colored vitals bars, a pedido explicito del usuario para replicar
-- el estilo visual de RUF-WoTLK (WoW): cada clase de LOTRO se mapea a un
-- color fijo, igual que WoW colorea guerrero/mago/brujo/etc. LOTRO no tiene
-- 10 clases como WoW (tiene 12 clases "Pueblos Libres" + 6 de Monster Play
-- en Ettenmoors, 18 en total via Turbine.Gameplay.Class) -- se reusan los
-- 10 colores clasicos de WotLK por tema/rol lo mas parecido posible
-- (tanque->guerrero, sanador->sacerdote, cazador->cazador, etc.) y se
-- repiten donde no alcanzan, tal como se pidio explicitamente ("si faltan
-- colores adaptar con los que hay o repetir").
import "Turbine.Gameplay"
import "Turbine.UI"
import "LUI.src.Utils.color"

local Utils = _G.LUI.Utils
local lui_hex_to_color = Utils.lui_hex_to_color

-- Colores clasicos de clase de WotLK (hex reales del juego, no inventados).
local WOTLK_HEX = {
    WARRIOR   = "C79C6E",
    PALADIN   = "F58CBA",
    HUNTER    = "ABD473",
    ROGUE     = "FFF569",
    PRIEST    = "FFFFFF",
    DEATHKNIGHT = "C41F3B",
    SHAMAN    = "0070DE",
    MAGE      = "69CCF0",
    WARLOCK   = "9482C9",
    DRUID     = "FF7D0A",
}

local _cache = {}
local function _color(hex_key)
    local c = _cache[hex_key]
    if c == nil then
        c = lui_hex_to_color(WOTLK_HEX[hex_key])
        _cache[hex_key] = c
    end
    return c
end

-- Mapeo tematico LOTRO -> color WotLK. Un color por clase LOTRO; se repite
-- el color de WotLK cuando no hay mas disponibles (documentado al lado de
-- cada linea el porque de la eleccion).
local CLASS_TO_HEX_KEY = {
    -- 12 clases de Pueblos Libres
    [Turbine.Gameplay.Class.Guardian]   = "WARRIOR",     -- tanque cuerpo a cuerpo
    [Turbine.Gameplay.Class.Champion]   = "DEATHKNIGHT", -- dps agresivo a dos armas
    [Turbine.Gameplay.Class.Warden]     = "SHAMAN",      -- tactico/elemental (gambitos)
    [Turbine.Gameplay.Class.Hunter]     = "HUNTER",      -- coincidencia directa
    [Turbine.Gameplay.Class.Burglar]    = "ROGUE",       -- sigilo, coincidencia directa
    [Turbine.Gameplay.Class.Captain]    = "PALADIN",     -- liderazgo/buffs
    [Turbine.Gameplay.Class.Minstrel]   = "PRIEST",      -- sanador principal, coincidencia directa
    [Turbine.Gameplay.Class.LoreMaster] = "WARLOCK",     -- pet + control, caster oscuro
    [Turbine.Gameplay.Class.RuneKeeper] = "MAGE",        -- caster puro
    [Turbine.Gameplay.Class.Beorning]   = "DRUID",       -- forma-cambiante, coincidencia directa
    [Turbine.Gameplay.Class.Brawler]    = "WARRIOR",     -- repetido: cuerpo a cuerpo fisico
    [Turbine.Gameplay.Class.Mariner]    = "SHAMAN",      -- repetido: tema naval/elemental (azul)

    -- 6 clases de Monster Play (Ettenmoors) -- repiten del mismo pool de 10
    [Turbine.Gameplay.Class.Weaver]     = "WARLOCK",     -- veneno/dot
    [Turbine.Gameplay.Class.Reaver]     = "DEATHKNIGHT", -- cuerpo a cuerpo agresivo
    [Turbine.Gameplay.Class.Defiler]    = "PRIEST",      -- sanador de monstruos
    [Turbine.Gameplay.Class.Stalker]    = "ROGUE",       -- sigilo
    [Turbine.Gameplay.Class.WarLeader]  = "PALADIN",     -- liderazgo/buffs
    [Turbine.Gameplay.Class.BlackArrow] = "HUNTER",      -- a distancia
}

-- Devuelve el Turbine.UI.Color de la clase de esa entidad, o nil si la
-- entidad no tiene clase resoluble (mobs, companions, etc. -- en esos
-- casos el llamador debe usar su color de respaldo existente, nunca se
-- inventa un color para algo sin clase real).
local function lui_class_color(entity)
    if entity == nil or entity.GetClass == nil then
        return nil
    end
    local ok, cls = pcall(function() return entity:GetClass() end)
    if ok ~= true or cls == nil then
        return nil
    end
    local hex_key = CLASS_TO_HEX_KEY[cls]
    if hex_key == nil then
        return nil
    end
    return _color(hex_key)
end
Utils.lui_class_color = lui_class_color
