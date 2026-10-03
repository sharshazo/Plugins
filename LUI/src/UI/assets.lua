-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local UI = _G.LUI.UI
local AssetIds = UI.Assets

UI.AssetIds = AssetIds

AssetIds.gold_coin = 0x41007e7b
AssetIds.silver_coin = 0x41007e7c
AssetIds.copper_coin = 0x41007e7d
AssetIds.durability = 0x41003061

AssetIds.arrow_l_white = 0x41108D0C
AssetIds.arrow_r_white = 0x41108D0D

AssetIds.arrow_l_yellow_normal = 0x4110A12F
AssetIds.arrow_l_yellow_inverted = 0x4110A130
AssetIds.arrow_l_yellow_dark = 0x4110A131
AssetIds.arrow_l_transparent = 0x4110A12D

AssetIds.arrow_r_yellow_normal = 0x4110A132
AssetIds.arrow_r_yellow_inverted = 0x4110A133
AssetIds.arrow_r_yellow_dark = 0x4110A134
AssetIds.arrow_r_transparent = 0x4110A12E

AssetIds.x = "LUI/assets/ui/x_64.tga"
AssetIds.x_hover = "LUI/assets/ui/x_hover_64.tga"
AssetIds.window_maximize = "LUI/assets/ui/maximize_64.tga"
AssetIds.window_maximize_hover = "LUI/assets/ui/maximize_hover_64.tga"
AssetIds.window_restore = "LUI/assets/ui/restore_64.tga"
AssetIds.window_restore_hover = "LUI/assets/ui/restore_hover_64.tga"

AssetIds.resize_horizontal = 0x410081BF
AssetIds.resize_vertical = 0x410081C0
AssetIds.resize_diagonal_tl_br = 0x41007E20
AssetIds.resize_diagonal_tr_bl = 0x4101973F

AssetIds.feather = 0x41004D92

AssetIds.party_leader_banner = 0x4113F18F

AssetIds.backpack = 0x41008113
AssetIds.backpack_alt = 0x411AD881

AssetIds.anvil_silver = "LUI/assets/ui/anvil-silver.tga"
AssetIds.anvil_silver_glow = "LUI/assets/ui/anvil-silver-glow.tga"
AssetIds.anvil_gold = "LUI/assets/ui/anvil-gold.tga"
-- Anvil LotRO alternatives: 0x410F2EA5 original, 0x410F2EA2, 0x410F2EAE bright contour.
AssetIds.anvil_lotro_original = 0x410F2EA5
AssetIds.anvil_lotro_alt = 0x410F2EA2
AssetIds.anvil_lotro_bright_contour = 0x410F2EAE

AssetIds.chest = 0x41003830
AssetIds.chest_alt_1 = 0x4111BE35
AssetIds.chest_dark = 0x4111BE44
AssetIds.chest_alt_2 = 0x4111BE3E
AssetIds.chest_alt_3 = 0x411BA042

AssetIds.compass = "LUI/assets/ui/compass_64.tga"
AssetIds.compass_hover = "LUI/assets/ui/compass_hover_64.tga"

AssetIds.book_shortcut = 0x410031FB
AssetIds.book_open = 0x410E0435
AssetIds.parchment = 0x410E9288
AssetIds.book_no_background = 0x41003199
AssetIds.book_background = 0x41002DC3
AssetIds.book_pressed_25 = 0x41005F00
AssetIds.book_normal_25 = 0x41005F07
AssetIds.book_hover_25 = 0x41005F0F
AssetIds.book = 0x4112E6D1
AssetIds.book_red = 0x41133491
AssetIds.book_cyan = 0x41133492
AssetIds.book_green = 0x41133493
AssetIds.book_purple = 0x41133494
AssetIds.book_yellow = 0x41133496
AssetIds.book_light_gray = 0x4113349A
AssetIds.book_orange = 0x4113349C
AssetIds.book_dark_gray = 0x4113349F
AssetIds.book_old = 0x41138432
AssetIds.book_magic = 0x41139D6B
AssetIds.book_orange_cover = 0x4113B263
AssetIds.book_blue_cover = 0x4113BC91

AssetIds.plus_25 = 0x41116576
AssetIds.minus_25 = 0x41116579
-- There are other +/- colors available as 25x25 icons.

-- (2026-09-30, actualizacion 49.6) Tamano REAL de las imagenes, para no
-- depender de medirlas en el juego (ver nota en UI/Widgets/image.lua).
-- Las propias de LUI se leyeron de la cabecera de cada .tga; las del juego
-- solo cuando el tamano esta documentado (el resto se mide en el juego).
local ImageSizes = UI.ImageSizes
local function _size(icon, w, h)
    if icon ~= nil then
        ImageSizes[icon] = { w, h or w }
    end
end

_size(AssetIds.x, 64)
_size(AssetIds.x_hover, 64)
_size(AssetIds.window_maximize, 64)
_size(AssetIds.window_maximize_hover, 64)
_size(AssetIds.window_restore, 64)
_size(AssetIds.window_restore_hover, 64)
_size(AssetIds.anvil_silver, 64)
_size(AssetIds.anvil_silver_glow, 64)
_size(AssetIds.anvil_gold, 64)
_size(AssetIds.compass, 64)
_size(AssetIds.compass_hover, 64)
_size("LUI/assets/hand_button.tga", 64)
_size("LUI/assets/logo_button.tga", 128)
_size("LUI/assets/logo.tga", 32)
_size("LUI/assets/logo2.tga", 32)
_size("LUI/assets/ui/star_24.tga", 24)
_size("LUI/assets/ui/star_hover_24.tga", 24)
_size("LUI/assets/ui/star_gray_24.tga", 24)
_size("LUI/assets/ui/star_32.tga", 32)
_size("LUI/assets/ui/star_hover_32.tga", 32)
_size("LUI/assets/ui/star_gray_32.tga", 32)
_size("LUI/assets/ui/star_48.tga", 48)
_size("LUI/assets/ui/star_hover_48.tga", 48)
_size("LUI/assets/ui/star_gray_48.tga", 48)
_size("LUI/assets/ui/star_64.tga", 64)
_size("LUI/assets/ui/star_hover_64.tga", 64)
_size("LUI/assets/ui/star_gray_64.tga", 64)
for _, class_name in ipairs({ "beorning", "brawler", "burglar", "captain", "champion", "guardian",
    "hunter", "lore-master", "mariner", "minstrel", "rune-keeper", "warden" }) do
    _size("LUI/assets/" .. class_name .. ".tga", 50)
end

_size(AssetIds.party_leader_banner, 64)
_size(AssetIds.book_pressed_25, 25)
_size(AssetIds.book_normal_25, 25)
_size(AssetIds.book_hover_25, 25)
_size(AssetIds.plus_25, 25)
_size(AssetIds.minus_25, 25)
