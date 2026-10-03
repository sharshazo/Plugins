-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils
import "Turbine.Gameplay"
import "Turbine.UI"

local LEADER_ICON = Turbine.UI.Graphic(0x4113F18F) -- 64x64
local BEORNING_ICON = Turbine.UI.Graphic(0x41153709) -- 50x50
local BRAWLER_ICON = "LUI/assets/brawler.tga"
local BURGLAR_ICON = Turbine.UI.Graphic(0x410000E4) -- 50x50
local CAPTAIN_ICON = Turbine.UI.Graphic(0x410000E5) -- 50x50
local CHAMPION_ICON = Turbine.UI.Graphic(0x410000E6) -- 50x50
local GUARDIAN_ICON = Turbine.UI.Graphic(0x410000E7) -- 50x50
local HUNTER_ICON = Turbine.UI.Graphic(0x410000E8) -- 50x50
local LORE_MASTER_ICON = Turbine.UI.Graphic(0x410000E9) -- 50x50
local MARINER_ICON = "LUI/assets/mariner.tga"
local MINSTREL_ICON = Turbine.UI.Graphic(0x410000EA) -- 50x50
local RUNE_KEEPER_ICON = Turbine.UI.Graphic(0x410E81CB) -- 48x48
local WARDEN_ICON = Turbine.UI.Graphic(0x410E0DCA) -- 48x48

Utils.PARTY_LEADER_ICON = LEADER_ICON

-- (2026-09-30, actualizacion 49.6) tamanos reales, ver UI/Widgets/image.lua
do
    local sizes = _G.LUI.UI and _G.LUI.UI.ImageSizes
    if sizes ~= nil then
        sizes[LEADER_ICON] = { 64, 64 }
        for _, icon in ipairs({ BEORNING_ICON, BURGLAR_ICON, CAPTAIN_ICON, CHAMPION_ICON,
            GUARDIAN_ICON, HUNTER_ICON, LORE_MASTER_ICON, MINSTREL_ICON }) do
            sizes[icon] = { 50, 50 }
        end
        sizes[RUNE_KEEPER_ICON] = { 48, 48 }
        sizes[WARDEN_ICON] = { 48, 48 }
        sizes[BRAWLER_ICON] = { 50, 50 }
        sizes[MARINER_ICON] = { 50, 50 }
    end
end

Utils.CLASS_ICON_NAMES = {
    [Turbine.Gameplay.Class.Beorning]     = BEORNING_ICON,
    [Turbine.Gameplay.Class.Brawler]      = BRAWLER_ICON,
    [Turbine.Gameplay.Class.Burglar]      = BURGLAR_ICON,
    [Turbine.Gameplay.Class.Captain]      = CAPTAIN_ICON,
    [Turbine.Gameplay.Class.Champion]     = CHAMPION_ICON,
    [Turbine.Gameplay.Class.Guardian]     = GUARDIAN_ICON,
    [Turbine.Gameplay.Class.Hunter]       = HUNTER_ICON,
    [Turbine.Gameplay.Class.LoreMaster]   = LORE_MASTER_ICON,
    [Turbine.Gameplay.Class.Mariner]      = MARINER_ICON,
    [Turbine.Gameplay.Class.Minstrel]     = MINSTREL_ICON,
    [Turbine.Gameplay.Class.RuneKeeper]   = RUNE_KEEPER_ICON,
    [Turbine.Gameplay.Class.Warden]       = WARDEN_ICON,
}

Utils.CLASS_ICON_CLASSES = {
    Turbine.Gameplay.Class.Hunter,
    Turbine.Gameplay.Class.Warden,
    Turbine.Gameplay.Class.Burglar,
    Turbine.Gameplay.Class.Captain,
    Turbine.Gameplay.Class.Champion,
    Turbine.Gameplay.Class.Guardian,
    Turbine.Gameplay.Class.Minstrel,
    Turbine.Gameplay.Class.Beorning,
    Turbine.Gameplay.Class.LoreMaster,
    Turbine.Gameplay.Class.RuneKeeper,
    Turbine.Gameplay.Class.Brawler,
    Turbine.Gameplay.Class.Mariner,
}

function Utils.get_class_icon(class, size)
    local icon = Utils.CLASS_ICON_NAMES[class]
    if icon == nil then
        return nil
    end

    return icon
end

function Utils.get_party_leader_icon()
    return Utils.PARTY_LEADER_ICON
end
