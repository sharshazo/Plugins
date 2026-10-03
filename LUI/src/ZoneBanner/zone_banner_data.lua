-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Cartel de zona (2026-09-30): medidas de las imagenes pregeneradas
-- (assets/ui/zona/). GENERADO a partir de los 11 carteles del jugador;
-- no editar a mano: cada numero corresponde a un pixel de su TGA.
--   w,h   = tamano del cartel (zb_<estilo>_<ancho>.tga)
--   pad   = margen del aura (zb_<estilo>_aura_<ancho>.tga mide w+2pad x h+2pad)
--   panel = x, y, ancho, alto del recuadro liso donde va el nombre
--   spark = lado de la chispa; sparks = centros de las gemas/emblemas
--   text / bar = color del nombre y de la barra de estado (0..255)

local ZoneBanner = _G.LUI.Features.ZoneBanner

ZoneBanner.SIZES = { 300, 380, 460 }
ZoneBanner.SHINE = {
    [300] = { w = 48, h = 30 },
    [380] = { w = 61, h = 38 },
    [460] = { w = 74, h = 46 },
}
ZoneBanner.STYLE_ORDER = { "general", "comarca", "elfico", "arnor", "hielo", "sombra", "enano", "rohan", "gondor", "salvajes", "sur" }
ZoneBanner.STYLES = {
    general = {
        text = { 245, 222, 160 },
        bar = { 6, 26, 56 },
        sizes = {
            [300] = { w = 300, h = 63, pad = 15, panel = { 41, 26, 217, 18 }, spark = 23, sparks = { { 27, 36 }, { 272, 36 }, { 150, 8 } } },
            [380] = { w = 380, h = 80, pad = 19, panel = { 52, 33, 275, 23 }, spark = 29, sparks = { { 34, 45 }, { 345, 45 }, { 190, 10 } } },
            [460] = { w = 460, h = 97, pad = 23, panel = { 63, 40, 333, 28 }, spark = 35, sparks = { { 41, 55 }, { 418, 55 }, { 229, 12 } } },
        },
    },
    comarca = {
        text = { 250, 236, 190 },
        bar = { 30, 54, 14 },
        sizes = {
            [300] = { w = 300, h = 60, pad = 15, panel = { 39, 24, 222, 22 }, spark = 23, sparks = { { 18, 34 }, { 282, 34 }, { 149, 11 } } },
            [380] = { w = 380, h = 76, pad = 19, panel = { 50, 30, 281, 28 }, spark = 29, sparks = { { 23, 43 }, { 357, 43 }, { 189, 13 } } },
            [460] = { w = 460, h = 92, pad = 23, panel = { 60, 37, 340, 34 }, spark = 35, sparks = { { 28, 52 }, { 432, 52 }, { 229, 16 } } },
        },
    },
    elfico = {
        text = { 225, 246, 255 },
        bar = { 4, 44, 48 },
        sizes = {
            [300] = { w = 300, h = 65, pad = 15, panel = { 38, 28, 223, 19 }, spark = 23, sparks = { { 21, 39 }, { 278, 39 }, { 150, 6 } } },
            [380] = { w = 380, h = 83, pad = 19, panel = { 48, 35, 283, 25 }, spark = 29, sparks = { { 27, 49 }, { 352, 49 }, { 190, 8 } } },
            [460] = { w = 460, h = 100, pad = 23, panel = { 58, 43, 342, 30 }, spark = 35, sparks = { { 32, 59 }, { 426, 59 }, { 230, 10 } } },
        },
    },
    arnor = {
        text = { 228, 234, 246 },
        bar = { 34, 42, 48 },
        sizes = {
            [300] = { w = 300, h = 66, pad = 15, panel = { 39, 28, 221, 21 }, spark = 23, sparks = { { 20, 38 }, { 279, 38 }, { 150, 14 }, { 150, 53 } } },
            [380] = { w = 380, h = 84, pad = 19, panel = { 50, 36, 280, 26 }, spark = 29, sparks = { { 25, 48 }, { 354, 48 }, { 190, 17 }, { 190, 67 } } },
            [460] = { w = 460, h = 101, pad = 23, panel = { 60, 44, 339, 32 }, spark = 35, sparks = { { 31, 58 }, { 428, 58 }, { 230, 21 }, { 230, 81 } } },
        },
    },
    hielo = {
        text = { 228, 246, 255 },
        bar = { 8, 56, 100 },
        sizes = {
            [300] = { w = 300, h = 74, pad = 15, panel = { 44, 30, 213, 22 }, spark = 23, sparks = { { 21, 40 }, { 278, 40 }, { 150, 8 } } },
            [380] = { w = 380, h = 94, pad = 19, panel = { 55, 38, 270, 28 }, spark = 29, sparks = { { 27, 50 }, { 353, 50 }, { 190, 11 } } },
            [460] = { w = 460, h = 114, pad = 23, panel = { 67, 46, 327, 34 }, spark = 35, sparks = { { 32, 61 }, { 427, 61 }, { 230, 13 } } },
        },
    },
    sombra = {
        text = { 255, 196, 160 },
        bar = { 58, 12, 6 },
        sizes = {
            [300] = { w = 300, h = 73, pad = 15, panel = { 45, 34, 210, 22 }, spark = 23, sparks = { { 22, 44 }, { 277, 44 }, { 150, 24 }, { 150, 58 } } },
            [380] = { w = 380, h = 92, pad = 19, panel = { 57, 43, 266, 28 }, spark = 29, sparks = { { 28, 56 }, { 351, 56 }, { 190, 30 }, { 190, 73 } } },
            [460] = { w = 460, h = 112, pad = 23, panel = { 70, 52, 322, 33 }, spark = 35, sparks = { { 34, 68 }, { 425, 68 }, { 230, 37 }, { 230, 89 } } },
        },
    },
    enano = {
        text = { 250, 216, 150 },
        bar = { 56, 38, 20 },
        sizes = {
            [300] = { w = 300, h = 72, pad = 15, panel = { 37, 30, 225, 20 }, spark = 23, sparks = { { 22, 39 }, { 279, 39 }, { 150, 56 } } },
            [380] = { w = 380, h = 91, pad = 19, panel = { 47, 38, 285, 26 }, spark = 29, sparks = { { 28, 50 }, { 353, 50 }, { 190, 71 } } },
            [460] = { w = 460, h = 110, pad = 23, panel = { 57, 46, 345, 31 }, spark = 35, sparks = { { 34, 61 }, { 428, 61 }, { 230, 85 } } },
        },
    },
    rohan = {
        text = { 250, 226, 166 },
        bar = { 70, 18, 8 },
        sizes = {
            [300] = { w = 300, h = 71, pad = 15, panel = { 42, 31, 216, 21 }, spark = 23, sparks = { { 34, 45 }, { 266, 45 }, { 150, 16 }, { 150, 58 } } },
            [380] = { w = 380, h = 90, pad = 19, panel = { 53, 40, 273, 27 }, spark = 29, sparks = { { 43, 57 }, { 337, 57 }, { 190, 20 }, { 190, 73 } } },
            [460] = { w = 460, h = 109, pad = 23, panel = { 64, 48, 331, 32 }, spark = 35, sparks = { { 52, 69 }, { 408, 69 }, { 230, 24 }, { 230, 89 } } },
        },
    },
    gondor = {
        text = { 236, 241, 255 },
        bar = { 4, 32, 84 },
        sizes = {
            [300] = { w = 300, h = 80, pad = 15, panel = { 35, 40, 230, 20 }, spark = 23, sparks = { { 10, 47 }, { 278, 47 }, { 149, 3 }, { 149, 67 } } },
            [380] = { w = 380, h = 102, pad = 19, panel = { 44, 51, 291, 25 }, spark = 29, sparks = { { 13, 60 }, { 352, 60 }, { 189, 4 }, { 189, 85 } } },
            [460] = { w = 460, h = 123, pad = 23, panel = { 54, 61, 353, 30 }, spark = 35, sparks = { { 16, 73 }, { 426, 73 }, { 229, 5 }, { 229, 102 } } },
        },
    },
    salvajes = {
        text = { 232, 222, 182 },
        bar = { 48, 30, 22 },
        sizes = {
            [300] = { w = 300, h = 80, pad = 15, panel = { 39, 41, 222, 17 }, spark = 23, sparks = { { 21, 47 }, { 277, 47 }, { 150, 23 } } },
            [380] = { w = 380, h = 101, pad = 19, panel = { 49, 52, 281, 22 }, spark = 29, sparks = { { 27, 60 }, { 351, 60 }, { 190, 29 } } },
            [460] = { w = 460, h = 122, pad = 23, panel = { 60, 63, 340, 27 }, spark = 35, sparks = { { 32, 72 }, { 425, 72 }, { 229, 35 } } },
        },
    },
    sur = {
        text = { 250, 226, 160 },
        bar = { 4, 42, 82 },
        sizes = {
            [300] = { w = 300, h = 79, pad = 15, panel = { 36, 35, 227, 18 }, spark = 23, sparks = { { 23, 43 }, { 276, 43 }, { 150, 17 }, { 150, 61 } } },
            [380] = { w = 380, h = 100, pad = 19, panel = { 46, 44, 288, 23 }, spark = 29, sparks = { { 29, 55 }, { 350, 55 }, { 190, 22 }, { 190, 77 } } },
            [460] = { w = 460, h = 121, pad = 23, panel = { 56, 54, 348, 28 }, spark = 35, sparks = { { 35, 66 }, { 424, 66 }, { 230, 26 }, { 230, 94 } } },
        },
    },
}
