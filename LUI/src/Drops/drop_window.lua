-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Drops = _G.LUI.Features.Drops
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local Lore = _G.LUI.Data.Lore
local UI = _G.LUI.UI
local scaled_int = UI.NativeScaling.scaled_int
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.base_window"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.callbacks"

local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local CHAT_DISPLAY_DELAY = 0.25
local ITEM_MATCH_WINDOW = 1.00
local EXIT_FADE_DURATION = 0.50

local BASE_ROW_PADDING = 4
local BASE_SPACING = 0
local MIN_WIDTH = 140

local function _with_alpha(color, alpha)
    if color == nil then
        return Turbine.UI.Color(alpha, 1, 1, 1)
    end
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

local function _set_alpha_backdrop(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _trim(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end
    return trimmed
end

local function _drops_tr(key, fallback)
    local value = TR[key]
    if value == key then
        return fallback
    end
    return value
end

local function _starts_with(text, prefix)
    if type(text) ~= "string" or type(prefix) ~= "string" then
        return false
    end
    return string.sub(text, 1, string.len(prefix)) == prefix
end

-- Singular/plural fold per word, applied to BOTH sides of every name
-- comparison (chat line vs backpack item vs merge key): the Spanish client
-- prints stacks in plural ("[2 Bloques de mineral de cobre]") while the
-- backpack item is named in singular ("Bloque de mineral de cobre"), so an
-- exact compare never paired them and the row showed without icon. Drop a
-- trailing "s", then a trailing "e": bloques/bloque -> bloqu, pieles/piel
-- -> piel, colmillos/colmillo -> colmillo; English hides/hide -> hid.
-- Only ever compared against itself, never displayed.
local function _fold_plural_word(word)
    if string.len(word) > 3 then
        word = word:gsub("s$", "")
        word = word:gsub("e$", "")
    end
    return word
end

local function _normalize_item_name(name)
    local trimmed = _trim(name)
    if trimmed == nil then
        return nil
    end

    trimmed = trimmed:gsub("[%s]+", " ")
    trimmed = string.lower(trimmed)
    return (trimmed:gsub("[^ ]+", _fold_plural_word))
end

local function _strip_timestamp(message)
    if type(message) ~= "string" then
        return ""
    end
    return message:gsub("^%[%d%d/%d%d .-%]%s*", "")
end

local function _parse_quantity_prefix(text)
    if type(text) ~= "string" then
        return 1
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return 1
    end

    local plain = trimmed:match("^(%d+)$")
    if plain ~= nil then
        return tonumber(plain) or 1
    end

    local x_suffix = trimmed:match("^(%d+)%s*[xX]$")
    if x_suffix ~= nil then
        return tonumber(x_suffix) or 1
    end

    local x_prefix = trimmed:match("^[xX]%s*(%d+)$")
    if x_prefix ~= nil then
        return tonumber(x_prefix) or 1
    end

    return 1
end

-- Loot lines of the Spanish-translated client this player uses (confirmed
-- in-game by LOTRO_Quest_Assistant's GatherEventParser: "Has adquirido:
-- [2 Bloques de mineral de cobre]."). They are checked ALWAYS, whatever
-- language LUI itself is set to: the item library/encyclopedia is kept in
-- English on purpose, and the old Spanish locale strings
-- ("Habeis obtenido:") never matched the real client text, so the Drops
-- window never showed anything. Anchored at the start of the line, so a
-- player typing the same words in /say ("Fulano dice: ...") or another
-- player's loot ("Fulano ha adquirido") can never match.
local SPANISH_ACQUIRED_PREFIXES = {
    "Has adquirido",
    "Has obtenido",
}

local function _spanish_acquired_prefix(message)
    for i = 1, #SPANISH_ACQUIRED_PREFIXES do
        local prefix = SPANISH_ACQUIRED_PREFIXES[i]
        if _starts_with(message, prefix) == true then
            return prefix
        end
    end
    return nil
end

local function _parse_drop_message(message)
    if type(message) ~= "string" then
        return nil, nil
    end

    local bracket_start, bracket_end = string.find(message, "%b[]")
    if bracket_start == nil or bracket_end == nil then
        return nil, nil
    end

    local acquired_prefix = _drops_tr("__drops_chat_acquired_prefix", "You have acquired")
    -- some languages open the pending-delivery variant with a different
    -- sentence than the plain loot line (German "Ihr habt erhalten:" vs
    -- "Erhalten:"); nil when one prefix covers both
    local acquired_prefix_alt = _drops_tr("__drops_chat_acquired_prefix_alt", nil)
    local gathered_prefix = _drops_tr("__drops_chat_gathered_prefix", "Gathered")
    -- languages whose gathering line starts with the item link itself
    -- ("[3 Felle] in Euren Rucksack gelegt.") match on a suffix instead
    local gathered_suffix = _drops_tr("__drops_chat_gathered_suffix", nil)
    local quantity_prefix = nil
    local gathered_message = false
    local spanish_prefix = _spanish_acquired_prefix(message)
    if spanish_prefix ~= nil then
        -- Spanish lines keep the stack count inside the bracket, exactly
        -- like the English "Gathered" lines -- same split below
        gathered_message = true
        quantity_prefix = string.sub(message, string.len(spanish_prefix) + 1, bracket_start - 1)
    elseif _starts_with(message, acquired_prefix) == true then
        quantity_prefix = string.sub(message, string.len(acquired_prefix) + 1, bracket_start - 1)
    elseif acquired_prefix_alt ~= nil and _starts_with(message, acquired_prefix_alt) == true then
        quantity_prefix = string.sub(message, string.len(acquired_prefix_alt) + 1, bracket_start - 1)
    elseif _starts_with(message, gathered_prefix) == true then
        gathered_message = true
        quantity_prefix = string.sub(message, string.len(gathered_prefix) + 1, bracket_start - 1)
    elseif gathered_suffix ~= nil and bracket_start == 1 and
        string.find(message, gathered_suffix, bracket_end + 1, true) ~= nil then
        gathered_message = true
        quantity_prefix = ""
    else
        return nil, nil
    end

    local name = _trim(string.sub(message, bracket_start + 1, bracket_end - 1))
    if name == nil then
        return nil, nil
    end

    quantity_prefix = quantity_prefix:gsub("^%s*[:%-]*%s*", "")
    local quantity = _parse_quantity_prefix(quantity_prefix)
    if gathered_message == true and quantity == 1 then
        local bracket_quantity, bracket_name = name:match("^(%d+)%s+(.+)$")
        if bracket_quantity ~= nil and _trim(bracket_name) ~= nil then
            quantity = tonumber(bracket_quantity) or 1
            name = _trim(bracket_name)
        end
    end
    return name, quantity
end

local function _visible_duration()
    local duration = tonumber(State.settings.drops.visible_duration) or 4
    if duration <= 0 then
        duration = 4
    end
    return duration
end

local function _safe_item_name(item)
    if item == nil then
        return nil
    end

    local name = nil
    if item.GetName ~= nil then
        name = item:GetName()
    end
    if _trim(name) ~= nil then
        return name
    end

    if item.GetItemInfo ~= nil then
        local item_info = item:GetItemInfo()
        if item_info ~= nil and item_info.GetName ~= nil then
            return item_info:GetName()
        end
    end

    return nil
end

local function _find_backpack_item_by_name(backpack, normalized_name)
    if backpack == nil or normalized_name == nil then
        return nil
    end
    if backpack.GetSize == nil or backpack.GetItem == nil then
        return nil
    end

    local size = tonumber(backpack:GetSize()) or 0
    for index = 1, size do
        local item = backpack:GetItem(index)
        if item ~= nil and _normalize_item_name(_safe_item_name(item)) == normalized_name then
            return item
        end
    end

    return nil
end

local function _row_padding()
    return scaled_int(BASE_ROW_PADDING)
end

local function _row_height()
    return State.settings.drops.icon_size + (2 * _row_padding())
end

local function _row_spacing()
    return scaled_int(BASE_SPACING)
end

local function _move_duration()
    local duration_ms = tonumber(State.settings.drops.move_duration)
    if duration_ms == nil or duration_ms <= 0 then
        return 0
    end
    return duration_ms / 1000
end

-- Escalado (2026-10-01, captura del jugador con la escala de interfaz del
-- juego en 1.20): las filas de botin salian 1.2 veces mas anchas que el hueco
-- entre los estandartes del cartel LOOT y sobresalian por la derecha. Las
-- filas, el fondo y el cartel son ventanas SEPARADAS: si el juego escala unas
-- (filas registradas en el escalado nativo) y otras no (el cartel: sus
-- imagenes son de tamano fijo), nunca calzan, y el factor de escala que
-- informa el juego no alcanzo para corregirlo (en la captura no se aplico).
-- Ahora TODAS las ventanas del botin quedan fuera del escalado del juego,
-- siempre, y se dibujan con el tamano de LUI (Opciones > Global > Escala y
-- Opciones > Botin): las filas, el fondo y el cartel salen del mismo calculo
-- y calzan exactos, con o sin "Use native LotRO UI scaling".
local function _never_native_scaling(window)
    if window ~= nil then
        UI.NativeScaling.disable(window)
    end
end

local DropBackgroundWindow = class(UI.Widgets.LuiBaseWindow)

function DropBackgroundWindow:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })

    self:SetVisible(false)
    self:SetMouseVisible(false)
    _set_alpha_backdrop(self)
end

function DropBackgroundWindow:apply_native_scaling(target_window)
    _never_native_scaling(target_window or self)
end

function DropBackgroundWindow:apply_settings()
    local s = State.settings.drops
    self:SetBackColor(_with_alpha(s.hud.background_color, s.hud.background_opacity))
end

function DropBackgroundWindow:destroy()
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

-- Cartel "LOOT" (pedido del jugador, 2026-09-26): ventana aparte, sin
-- mouse, montada sobre las filas de botin mientras hay botin en pantalla
-- (y en el modo "mover interfaz", para ver donde queda). Es solo imagen:
-- no cambia filas, colores, tiempos ni nada de la mecanica.
-- Encaje (pedido del jugador): el riel de abajo del cartel se apoya justo
-- en el borde de arriba de la primera fila y los dos estandartes con
-- puntas cuelgan a los COSTADOS de las filas, pegados a sus bordes. Por eso
-- el cartel es mas ancho que la ventana: el hueco entre estandartes mide
-- lo mismo que las filas. SetBackground no reescala, asi que hay una imagen
-- por ancho de ventana (assets/ui/loot_cartel_<ancho>.tga, anchos de 160 a
-- 480 de 20 en 20) y se usa la mas chica que alcanza, centrada.
-- Aura y brillo: detras, un halo dorado que "respira"
-- (loot_cartel_aura_<ancho>.tga; se apaga suave sobre las filas para no
-- teñirlas); encima de la palabra LOOT, un destello de luz que la cruza
-- cada pocos segundos (8 cuadros, loot_cartel_brillo_<ancho>_<n>.tga,
-- recortes EXACTOS del cartel con la luz ya pintada); y chispas que
-- titilan en los rombos y puntas (loot_cartel_chispa_<ancho>.tga). Con
-- "Animaciones" apagado en Opciones > Botin queda el halo fijo, sin
-- destello ni chispas.
local BANNER_SOURCE_W = 2022
local BANNER_SOURCE_H = 716
local BANNER_MIN_W = 160
local BANNER_MAX_W = 480
local BANNER_STEP = 20
-- por ancho de la ventana de botin: w/h = tamano del cartel, pad = margen
-- del aura, rail = alto hasta el riel donde se apoyan las filas, rx/ry/rw/rh
-- = zona del destello, spark = tamano de la chispa
local BANNER_FX = {
    [160] = { w = 203, h = 72, pad = 10, rail = 47, rx = 69, ry = 22, rw = 67, rh = 20, spark = 15 },
    [180] = { w = 228, h = 81, pad = 11, rail = 52, rx = 78, ry = 24, rw = 74, rh = 23, spark = 17 },
    [200] = { w = 253, h = 90, pad = 13, rail = 58, rx = 86, ry = 27, rw = 83, rh = 26, spark = 19 },
    [220] = { w = 279, h = 99, pad = 14, rail = 64, rx = 95, ry = 30, rw = 91, rh = 28, spark = 21 },
    [240] = { w = 304, h = 108, pad = 15, rail = 70, rx = 104, ry = 32, rw = 99, rh = 31, spark = 21 },
    [260] = { w = 329, h = 117, pad = 16, rail = 75, rx = 112, ry = 35, rw = 108, rh = 33, spark = 23 },
    [280] = { w = 355, h = 126, pad = 18, rail = 81, rx = 121, ry = 38, rw = 116, rh = 36, spark = 25 },
    [300] = { w = 380, h = 135, pad = 19, rail = 87, rx = 130, ry = 40, rw = 124, rh = 39, spark = 27 },
    [320] = { w = 405, h = 143, pad = 20, rail = 93, rx = 138, ry = 43, rw = 132, rh = 41, spark = 29 },
    [340] = { w = 430, h = 152, pad = 22, rail = 99, rx = 147, ry = 46, rw = 140, rh = 43, spark = 31 },
    [360] = { w = 456, h = 161, pad = 23, rail = 105, rx = 156, ry = 48, rw = 148, rh = 47, spark = 33 },
    [380] = { w = 481, h = 170, pad = 24, rail = 110, rx = 164, ry = 51, rw = 157, rh = 49, spark = 35 },
    [400] = { w = 506, h = 179, pad = 25, rail = 116, rx = 173, ry = 54, rw = 165, rh = 51, spark = 35 },
    [420] = { w = 532, h = 188, pad = 27, rail = 122, rx = 182, ry = 57, rw = 173, rh = 54, spark = 37 },
    [440] = { w = 557, h = 197, pad = 28, rail = 128, rx = 190, ry = 59, rw = 182, rh = 57, spark = 39 },
    [460] = { w = 582, h = 206, pad = 29, rail = 134, rx = 199, ry = 62, rw = 190, rh = 59, spark = 41 },
    [480] = { w = 608, h = 215, pad = 30, rail = 140, rx = 207, ry = 65, rw = 199, rh = 61, spark = 43 },
}
-- rombos junto al texto, rombo de abajo, hoja de arriba, puntas de los
-- estandartes (coordenadas de la imagen grande)
local BANNER_SPARKS = {
    { 660, 322 }, { 1370, 322 }, { 999, 450 }, { 999, 62 }, { 138, 675 }, { 1880, 675 },
}
local BANNER_SHINE_FRAMES = 8
local BANNER_SHINE_EVERY = 4.0     -- segundos entre destellos
local BANNER_SHINE_FRAME_TIME = 0.12
local BANNER_AURA_PERIOD = 2.6
local BANNER_SPARK_PERIOD = 1.9
local TWO_PI = 2 * math.pi

-- ancho de ventana -> el ancho de la tabla mas chico que la alcanza
-- (2026-10-01: antes el mas cercano, y con un ancho como 309 tocaba el de
-- 300 y las filas pasaban unos pixeles por debajo de los estandartes)
local function _banner_key_for(width)
    width = tonumber(width) or BANNER_MIN_W
    local key = math.ceil((width - BANNER_MIN_W) / BANNER_STEP) * BANNER_STEP + BANNER_MIN_W
    if key < BANNER_MIN_W then
        key = BANNER_MIN_W
    elseif key > BANNER_MAX_W then
        key = BANNER_MAX_W
    end
    return key
end

local function _banner_layer(parent)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    return c
end

local DropBannerWindow = class(UI.Widgets.LuiBaseWindow)

function DropBannerWindow:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })
    -- el cartel va siempre en pixeles de pantalla (ver _never_native_scaling)
    _never_native_scaling(self)

    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    -- orden = de atras hacia adelante
    self.aura = _banner_layer(self)
    self.image = _banner_layer(self)
    self.shine = _banner_layer(self)
    self.shine:SetVisible(false)
    self.sparks = {}
    for i = 1, #BANNER_SPARKS do
        self.sparks[i] = _banner_layer(self)
        self.sparks[i]:SetVisible(false)
    end

    self.banner_key = 0
    self.fit_width = nil
    self.banner_w = 0
    self.banner_h = 0
    self.pad = 0
    self.rail = 0
    self.offset_x = 0
    self.shine_frame = 0
end

function DropBannerWindow:apply_native_scaling(target_window)
    _never_native_scaling(target_window or self)
end

-- width = ancho de las filas en pantalla
function DropBannerWindow:apply_settings(width)
    _never_native_scaling(self)
    self.fit_width = width
    local key = _banner_key_for(width)
    local fx = BANNER_FX[key]
    local w, h = fx.w, fx.h
    if key ~= self.banner_key then
        local base = "LUI/assets/ui/loot_cartel_"
        self.image:SetBackground(base .. tostring(key) .. ".tga")
        self.aura:SetBackground(base .. "aura_" .. tostring(key) .. ".tga")
        for i = 1, #self.sparks do
            self.sparks[i]:SetBackground(base .. "chispa_" .. tostring(key) .. ".tga")
        end
        self.shine_frame = 0
    end
    self.banner_key = key
    self.banner_w = w
    self.banner_h = h
    self.pad = fx.pad
    self.rail = fx.rail
    -- centrado sobre la ventana: los estandartes quedan a los costados
    self.offset_x = math.floor(((tonumber(width) or key) - w) / 2)

    local pad = fx.pad
    self:SetSize(w + (2 * pad), h + (2 * pad))
    self.aura:SetPosition(0, 0)
    self.aura:SetSize(w + (2 * pad), h + (2 * pad))
    self.image:SetPosition(pad, pad)
    self.image:SetSize(w, h)
    self.shine:SetPosition(pad + fx.rx, pad + fx.ry)
    self.shine:SetSize(fx.rw, fx.rh)
    local half = math.floor(fx.spark / 2)
    for i = 1, #self.sparks do
        local sx = math.floor((BANNER_SPARKS[i][1] * w / BANNER_SOURCE_W) + 0.5)
        local sy = math.floor((BANNER_SPARKS[i][2] * w / BANNER_SOURCE_W) + 0.5)
        self.sparks[i]:SetPosition(pad + sx - half, pad + sy - half)
        self.sparks[i]:SetSize(fx.spark, fx.spark)
    end
end

-- opacity: desvanecido general (la ultima fila que se va); animate: si hay
-- que animar (Animaciones prendido)
function DropBannerWindow:update_fx(opacity, now, animate)
    self.image:SetOpacity(opacity)

    if animate ~= true then
        self.aura:SetOpacity(opacity * 0.75)
        self.shine:SetVisible(false)
        for i = 1, #self.sparks do
            self.sparks[i]:SetVisible(false)
        end
        return
    end

    local breath = 0.62 + (0.30 * math.sin(TWO_PI * now / BANNER_AURA_PERIOD))
    self.aura:SetOpacity(opacity * breath)

    local phase = now % BANNER_SHINE_EVERY
    local frame = math.floor(phase / BANNER_SHINE_FRAME_TIME) + 1
    if frame >= 1 and frame <= BANNER_SHINE_FRAMES then
        if frame ~= self.shine_frame then
            self.shine:SetBackground("LUI/assets/ui/loot_cartel_brillo_" .. tostring(self.banner_key) .. "_" .. tostring(frame) .. ".tga")
            self.shine_frame = frame
        end
        self.shine:SetOpacity(opacity)
        self.shine:SetVisible(true)
    else
        self.shine:SetVisible(false)
    end

    for i = 1, #self.sparks do
        local v = math.sin(TWO_PI * ((now / BANNER_SPARK_PERIOD) + (i * 0.37)))
        local o = 0
        if v > 0 then
            o = v * v * v * v
        end
        self.sparks[i]:SetOpacity(opacity * o)
        self.sparks[i]:SetVisible(o > 0.02)
    end
end

function DropBannerWindow:destroy()
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

local DropsWindow = class(UI.Widgets.LuiHUD)
Drops.DropsWindow = DropsWindow

function DropsWindow:Constructor()
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "drops",
        -- the loot window itself is always shown in Spanish (player's
        -- request), even while the rest of LUI stays in English
        title = _drops_tr("Drops", "Bot\195\173n"),
        mouse_visible = false,
    })

    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = nil
    self.player_name = nil
    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate

    self._callbacks = {}
    self._pending_chat_drops = {}
    self._pending_item_events = {}
    self._active_drops = {}
    self._entry_pool = {}
    self._db_icon_cache = {}

    if self.player ~= nil and self.player.GetName ~= nil then
        self.player_name = self.player:GetName()
    end

    self:SetWantsUpdates(true)
    self:SetVisible(false)

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    self.background:SetVisible(false)
    _set_alpha_backdrop(self.background)

    self.content_background = DropBackgroundWindow()
    self.banner = DropBannerWindow()

    self:_bind_events()
    self:apply_settings()
end

function DropsWindow:apply_native_scaling(target_window)
    _never_native_scaling(target_window or self)
end

function DropsWindow:destroy()
    self:_detach_callbacks()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil then
            self:_recycle_entry(record)
        end
    end
    self._active_drops = {}
    self._pending_chat_drops = {}
    self._pending_item_events = {}
    for i = 1, #self._entry_pool do
        local entry = self._entry_pool[i]
        if entry ~= nil then
            entry:destroy()
        end
    end
    self._entry_pool = {}
    self:_destroy_content_background()
    if self.banner ~= nil then
        self.banner:destroy()
        self.banner = nil
    end
    self:_detach_background()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self:SetParent(nil)
end

function DropsWindow:set_move_mode(enabled)
    local changed = (enabled == true) ~= self:is_move_mode()
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    if changed and enabled == true then
        self:_hide_entries()
    elseif changed then
        self.last_update_at = -(self.update_every or 0)
        self:_show_entries()
        self:Update()
    end
    self:_refresh_background(enabled == true)
    self:refresh_visibility()
end

function DropsWindow:apply_settings()
    self:apply_native_scaling()
    self.update_every = 1.0 / State.settings.global.refresh_rate

    local s = State.settings.drops
    local width = s.width
    if width < MIN_WIDTH then
        width = MIN_WIDTH
    end
    local rows = math.max(1, math.floor((tonumber(s.rows) or 1) + 0.5))
    local row_h = _row_height()
    local spacing = _row_spacing()
    local height = (rows * row_h) + ((rows - 1) * spacing)

    self:SetSize(width, height)
    self.background:SetSize(width, height)
    self.background:SetBackColor(_with_alpha(s.hud.background_color, s.hud.background_opacity))
    -- fondo y filas: fuera del escalado del juego, igual que esta ventana
    -- (las que quedaron registradas de antes se sacan aca)
    self.content_background:apply_native_scaling()
    self.content_background:apply_settings()
    self:_sync_entry_scaling()
    if self.banner ~= nil then
        self.banner:apply_settings(self:_screen_width(width))
    end
    self:layout_move_chrome()
    self:apply_hud_position()
    self:_bind_events()

    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil then
            local entry = record.entry
            if entry ~= nil then
                entry:apply_settings()
            end
        end
    end

    self:_layout_active_drops(Turbine.Engine.GetGameTime(), false)
    self:refresh_visibility()
end

-- ancho real de las filas: el de la ventana, o el de una fila si es mas
-- ancha (las filas tienen un minimo propio para icono + nombre + cantidad)
function DropsWindow:_rows_width()
    local width = self:GetSize()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        local entry = record ~= nil and record.entry or nil
        local w = entry ~= nil and tonumber(entry._width) or nil
        if w ~= nil and w > width then
            width = w
        end
    end
    return width
end

-- factor pantalla / unidades de LUI de las filas: siempre 1, porque ninguna
-- ventana del botin usa el escalado del juego (ver _never_native_scaling)
function DropsWindow:_screen_scale()
    return 1
end

-- ancho de las filas tal como se ven en pantalla
function DropsWindow:_screen_width(width)
    local s = self:_screen_scale()
    if s == 1 then
        return width
    end
    return math.floor((width * s) + 0.5)
end

function DropsWindow:_sync_entry_scaling()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.entry ~= nil then
            record.entry:apply_native_scaling()
        end
    end
    for i = 1, #self._entry_pool do
        local entry = self._entry_pool[i]
        if entry ~= nil then
            entry:apply_native_scaling()
        end
    end
end

function DropsWindow:refresh_visibility()
    local any_visible = #self._active_drops > 0
    self:SetVisible(any_visible or self:is_move_mode())
end

function DropsWindow:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    if Drops.History ~= nil then
        pcall(Drops.History.tick, now)
    end

    if self:is_move_mode() == true then
        self:_refresh_background(true)
        self:refresh_visibility()
        return
    end

    self:_expire_pending_item_events(now)
    self:_promote_pending_chat_drops(now)
    self:_expire_active_drops(now)
    self:_update_entry_positions(now)
    self:_refresh_background(false)
    self:refresh_visibility()
end

function DropsWindow:_detach_background()
    if self.background ~= nil then
        self.background:SetVisible(false)
        self.background:SetParent(nil)
        self.background = nil
    end
end

function DropsWindow:_destroy_content_background()
    if self.content_background ~= nil then
        self.content_background:destroy()
        self.content_background = nil
    end
end

function DropsWindow:_bind_events()
    local next_player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local next_backpack = nil
    if next_player ~= nil and next_player.GetBackpack ~= nil then
        next_backpack = next_player:GetBackpack()
    end

    if self.player == next_player and self.backpack == next_backpack and #self._callbacks > 0 then
        return
    end

    self.player = next_player
    self.backpack = next_backpack
    self:_detach_callbacks()

    self:_attach(Turbine.Chat, "Received", function(_, args)
        self:_on_chat_received(args)
    end)

    if self.backpack ~= nil then
        self:_attach(self.backpack, "ItemAdded", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemAdded")
        end)
        self:_attach(self.backpack, "ItemChanged", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemChanged")
        end)
        self:_attach(self.backpack, "ItemMoved", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemMoved")
        end)
        self:_attach(self.backpack, "ItemRemoved", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemRemoved")
        end)
    end
end

function DropsWindow:_attach(object, event_name, callback)
    local handle = add_callback(object, event_name, callback)
    if handle ~= nil then
        self._callbacks[#self._callbacks + 1] = {
            object = object,
            event_name = event_name,
            handle = handle,
        }
    end
end

function DropsWindow:_detach_callbacks()
    for i = 1, #self._callbacks do
        local callback = self._callbacks[i]
        if callback ~= nil then
            remove_callback(callback.object, callback.event_name, callback.handle)
        end
    end
    self._callbacks = {}
end

function DropsWindow:_on_chat_received(args)
    if args == nil then
        return
    end

    local message = _strip_timestamp(args.Message)
    if message == "" then
        return
    end

    -- SelfLoot as always; a Spanish loot line is also accepted from any
    -- channel, because the translated client's channel for it is not
    -- confirmed (LOTRO_Quest_Assistant reads it without a channel filter)
    if args.ChatType ~= Turbine.ChatType.SelfLoot
        and _spanish_acquired_prefix(message) == nil then
        return
    end

    local item_name, quantity = _parse_drop_message(message)
    if item_name == nil then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    self:_queue_chat_drop(item_name, quantity, now)
end

-- fold a new drop into a live row of the same item: quantities add up,
-- fresh loot keeps the row alive, the row never moves. Rows already
-- fading out are left alone - the new drop starts a fresh row.
function DropsWindow:_merge_into_existing(normalized_name, quantity, now)
    for i = 1, #self._pending_chat_drops do
        local record = self._pending_chat_drops[i]
        if record ~= nil and record.normalized_name == normalized_name then
            record.quantity = record.quantity + quantity
            return true
        end
    end

    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.removing ~= true
            and record.normalized_name == normalized_name then
            record.quantity = record.quantity + quantity
            record.expire_at = now + _visible_duration()
            record.entry:set_record(record)
            return true
        end
    end

    return false
end

function DropsWindow:_queue_chat_drop(name, quantity, now)
    quantity = tonumber(quantity) or 1
    local ordinals
    name, quantity, ordinals = Lore.Items.canonicalize_drop(name, quantity)

    local normalized_name = _normalize_item_name(name)
    if normalized_name == nil then
        return
    end

    -- historial de la sesion (/botin): cuenta TODO lo looteado, tambien lo
    -- que se funde en una fila ya visible
    local history_quality = nil
    local history_icon = nil
    if ordinals ~= nil and Drops.Quality ~= nil then
        history_quality = Drops.Quality.from_ordinal(ordinals[1])
        local ok_icon, icon_id = pcall(Lore.Items.icon_layers, ordinals[1])
        if ok_icon == true then
            history_icon = icon_id
        end
    end
    if Drops.History ~= nil then
        pcall(Drops.History.add, name, normalized_name, quantity, history_quality, history_icon)
    end

    if State.settings.drops.merge_similar == true
        and self:_merge_into_existing(normalized_name, quantity, now) then
        return
    end

    local record = {
        name = name,
        normalized_name = normalized_name,
        quantity = quantity,
        chat_at = now,
        display_after = now + CHAT_DISPLAY_DELAY,
        upgrade_until = now + ITEM_MATCH_WINDOW,
        shown_at = nil,
        expire_at = nil,
        removing = false,
        fade_end_at = nil,
        opacity = 1,
        current_y = nil,
        target_y = nil,
        pinned_y = nil,
        move_start_at = nil,
        move_end_at = nil,
        move_from_y = nil,
        move_to_y = nil,
        layout_excluded = false,
        entry = nil,
        live_item = nil,
    }

    local pending_item = self:_take_pending_item_event(normalized_name, now)
    if pending_item ~= nil then
        record.live_item = pending_item.item
    elseif self.backpack ~= nil then
        record.live_item = _find_backpack_item_by_name(self.backpack, normalized_name)
    end
    if record.live_item == nil then
        -- carry-all loot: no live item ever appears, resolve from the DB;
        -- canonicalization already found the record, so reuse its ordinals
        if ordinals ~= nil then
            record.db_icon_id, record.db_background_id = Lore.Items.icon_layers(ordinals[1])
            record.db_quality = history_quality
        else
            record.db_icon_id, record.db_background_id, record.db_quality =
                self:_db_icon_for(name, normalized_name, record.quantity)
        end
    end

    self._pending_chat_drops[#self._pending_chat_drops + 1] = record
end

function DropsWindow:_on_backpack_item_event(sender, args, event_name)
    if sender == nil or args == nil then
        return
    end

    local item = nil
    if event_name == "ItemAdded" or event_name == "ItemChanged" then
        local index = args.Index
        if index ~= nil and sender.GetItem ~= nil then
            item = sender:GetItem(index)
        end
    elseif event_name == "ItemMoved" then
        local index = args.NewIndex
        if index ~= nil and sender.GetItem ~= nil then
            item = sender:GetItem(index)
        end
    else
        return
    end

    if item == nil then
        return
    end

    local item_name = _safe_item_name(item)
    local normalized_name = _normalize_item_name(item_name)
    if normalized_name == nil then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    local record = self:_find_oldest_unresolved_drop(normalized_name, now)
    if record ~= nil then
        self:_assign_live_item(record, item)
        return
    end

    self._pending_item_events[#self._pending_item_events + 1] = {
        normalized_name = normalized_name,
        item = item,
        at = now,
        expires_at = now + ITEM_MATCH_WINDOW,
    }
end

function DropsWindow:_find_oldest_unresolved_drop(normalized_name, now)
    local best = nil

    local function consider(record)
        if record == nil then
            return
        end
        if record.normalized_name ~= normalized_name then
            return
        end
        if record.live_item ~= nil then
            return
        end
        if record.removing == true then
            return
        end
        if now > (record.upgrade_until or 0) then
            return
        end
        if best == nil or (record.chat_at or 0) < (best.chat_at or 0) then
            best = record
        end
    end

    for i = 1, #self._pending_chat_drops do
        consider(self._pending_chat_drops[i])
    end
    for i = 1, #self._active_drops do
        consider(self._active_drops[i])
    end

    return best
end

function DropsWindow:_assign_live_item(record, item)
    if record == nil then
        return
    end
    record.live_item = item
    if record.entry ~= nil then
        record.entry:set_live_item(item)
    end
    if Drops.History ~= nil then
        pcall(Drops.History.note, record)
    end
end

function DropsWindow:_take_pending_item_event(normalized_name, now)
    local best_index = nil
    local best_event = nil

    for i = 1, #self._pending_item_events do
        local event = self._pending_item_events[i]
        if event ~= nil then
            if now > (event.expires_at or 0) then
                table.remove(self._pending_item_events, i)
                return self:_take_pending_item_event(normalized_name, now)
            end
            if event.normalized_name == normalized_name then
                if best_event == nil or (event.at or 0) < (best_event.at or 0) then
                    best_index = i
                    best_event = event
                end
            end
        end
    end

    if best_index ~= nil then
        table.remove(self._pending_item_events, best_index)
    end

    return best_event
end

function DropsWindow:_expire_pending_item_events(now)
    for i = #self._pending_item_events, 1, -1 do
        local event = self._pending_item_events[i]
        if event == nil or now > (event.expires_at or 0) then
            table.remove(self._pending_item_events, i)
        end
    end
end

function DropsWindow:_promote_pending_chat_drops(now)
    local duration = _visible_duration()

    local matured = {}
    for i = #self._pending_chat_drops, 1, -1 do
        local record = self._pending_chat_drops[i]
        if record ~= nil and now >= (record.display_after or 0) then
            table.remove(self._pending_chat_drops, i)
            matured[#matured + 1] = record
        end
    end

    for i = #matured, 1, -1 do
        local record = matured[i]
        while self:_layout_record_count() >= self:_rows_capacity() do
            self:_remove_oldest_visible_for_overflow(now)
        end

        record.shown_at = now
        record.expire_at = now + duration
        if record.live_item == nil and self.backpack ~= nil then
            record.live_item = _find_backpack_item_by_name(self.backpack, record.normalized_name)
        end
        if record.live_item == nil and record.db_icon_id == nil then
            record.db_icon_id, record.db_background_id, record.db_quality =
                self:_db_icon_for(record.name, record.normalized_name, record.quantity)
        end
        if Drops.History ~= nil then
            pcall(Drops.History.note, record)
        end
        record.entry = self:_acquire_entry()
        record.entry:apply_settings()
        record.entry:set_record(record)
        record.entry:SetVisible(true)
        self._active_drops[#self._active_drops + 1] = record
        self:_layout_active_drops(now, false)
    end
end

-- The lore Items DB is staged in the background by the bestiary prewarm
-- pump (src/Data/bestiary_db.lua); this window never imports it itself.
-- Until it is staged, carry-all loot shows without an icon and matures
-- one via the pending/_db_icon_for retry once the domain loads.

-- lore-DB icon fallback, cached per item name; false = known miss (item
-- newer than the data drop, or a chat string that is not an item name)
-- Spanish chat name -> items-DB ordinals, used only for the icon of loot
-- that never reaches the backpack (carry-all materials). The library keeps
-- its English names on purpose; the Spanish labels/search pack it already
-- loads next to them (Items.L_ES / Items.S_EXTRA, "buscar en espanol,
-- mostrar en ingles") are only READ here, nothing is swapped or renamed.
-- A substring search narrows the candidates; each one is then confirmed by
-- comparing its Spanish label with the chat name (plural-folded, see
-- _normalize_item_name), so a partial match can never pick a wrong icon.
local SPANISH_MAX_CANDIDATES = 400
local _spanish_ordinals

local function _spanish_candidates(needle)
    local Items = Lore.Items
    if needle == nil or string.len(needle) < 4 then
        return nil
    end
    local ok, set, count = pcall(Items.search, needle)
    if ok ~= true or set == nil or count == nil or count == 0 or count > SPANISH_MAX_CANDIDATES then
        return nil
    end
    return set
end

_spanish_ordinals = function(name, normalized_name)
    local Items = Lore.Items
    if Items == nil or Items.loaded ~= true or Items.L_ES == nil
        or Items.label_es == nil or Items.search == nil then
        return nil
    end
    if type(name) ~= "string" or normalized_name == nil then
        return nil
    end

    local set = _spanish_candidates(string.lower(name))
    if set == nil then
        -- plural chat name vs singular label ("Bloques de mineral de
        -- cobre" / "Bloque de mineral de cobre"): search the text after the
        -- first word, which Spanish leaves unchanged in the plural
        local rest = name:match("^%S+%s+(.+)$")
        if rest ~= nil then
            set = _spanish_candidates(string.lower(rest))
        end
    end
    if set == nil then
        return nil
    end

    for ordinal in pairs(set) do
        local ok, label = pcall(Items.label_es, ordinal)
        if ok == true and label ~= nil and _normalize_item_name(label) == normalized_name then
            return { ordinal }
        end
    end
    return nil
end

function DropsWindow:_db_icon_for(name, normalized_name, quantity)
    if Lore.Items.loaded ~= true then
        return nil, nil
    end

    -- a parsed quantity > 1 means the bracket carried a count, so the
    -- printed name is the plural form (gathered lines: "[5 Bones]" arrives
    -- count-stripped as "Bones"); resolution depends on this bit, so it is
    -- part of the cache key ("\t" cannot appear in item names)
    local plural_likely = quantity ~= nil and quantity > 1
    local cache_key = normalized_name
    if plural_likely then
        cache_key = "#p\t" .. normalized_name
    end

    local cached = self._db_icon_cache[cache_key]
    if cached == false then
        return nil, nil
    end
    if cached ~= nil then
        return cached[1], cached[2], cached[3]
    end

    local _, _, ordinals = Lore.Items.canonicalize_drop(name, quantity)
    if ordinals == nil then
        ordinals = _spanish_ordinals(name, normalized_name)
    end
    if ordinals == nil then
        self._db_icon_cache[cache_key] = false
        return nil, nil
    end
    local icon_id, background_id = Lore.Items.icon_layers(ordinals[1])
    if icon_id == nil then
        self._db_icon_cache[cache_key] = false
        return nil, nil
    end
    local quality = nil
    if Drops.Quality ~= nil then
        quality = Drops.Quality.from_ordinal(ordinals[1])
    end
    self._db_icon_cache[cache_key] = { icon_id, background_id, quality }
    return icon_id, background_id, quality
end

function DropsWindow:_rows_capacity()
    local rows = tonumber(State.settings.drops.rows)
    if rows == nil then
        return 1
    end
    rows = math.floor(rows + 0.5)
    if rows < 1 then
        rows = 1
    end
    return rows
end

-- (2026-10-01, reporte del jugador con capturas: "al reiniciar queda
-- correcto pero despues las siguientes vuelven a sobrepasar el cartel", con
-- y sin escalado) las filas recicladas (ocultas + SetParent(nil) y vueltas a
-- usar) salian mas anchas que el hueco del cartel, las recien creadas no.
-- Ahora cada fila de botin es una ventana NUEVA (como la primera despues de
-- reiniciar) y la que se va se destruye; el botin llega de a pocos, crear
-- una fila cuesta poco. _entry_pool queda siempre vacio.
function DropsWindow:_acquire_entry()
    local entry = Drops.DropEntry()
    entry:apply_native_scaling()
    return entry
end

function DropsWindow:_recycle_entry(record)
    if record == nil or record.entry == nil then
        return
    end

    local entry = record.entry
    record.entry = nil
    pcall(entry.destroy, entry)
end

function DropsWindow:_layout_record_count()
    local count = 0
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.layout_excluded ~= true then
            count = count + 1
        end
    end
    return count
end

function DropsWindow:_layout_block_height(count)
    if count <= 0 then
        return 0
    end

    local row_h = _row_height()
    local spacing = _row_spacing()
    return (count * row_h) + ((count - 1) * spacing)
end

function DropsWindow:_layout_base_y(count)
    local _, height = self:GetSize()
    local base_y = 0
    if State.settings.drops.align == LUI_ENUMS.vertical_align.BOTTOM then
        base_y = height - self:_layout_block_height(count)
        if base_y < 0 then
            base_y = 0
        end
    end
    return base_y
end

function DropsWindow:_ordered_layout_records()
    local ordered = {}
    local flow = State.settings.drops.flow

    if flow == LUI_ENUMS.list_flow.TOP_TO_BOTTOM then
        for i = #self._active_drops, 1, -1 do
            local record = self._active_drops[i]
            if record ~= nil and record.layout_excluded ~= true then
                ordered[#ordered + 1] = record
            end
        end
    else
        for i = 1, #self._active_drops do
            local record = self._active_drops[i]
            if record ~= nil and record.layout_excluded ~= true then
                ordered[#ordered + 1] = record
            end
        end
    end

    return ordered
end

function DropsWindow:_clear_move_state(record)
    record.move_start_at = nil
    record.move_end_at = nil
    record.move_from_y = nil
    record.move_to_y = nil
end

-- y en unidades de LUI; s = factor de pantalla (siempre 1, ver _screen_scale)
function DropsWindow:_set_entry_y(record, anchor_x, anchor_y, y, s)
    record.current_y = y
    if record.entry ~= nil then
        record.entry:SetPosition(anchor_x, anchor_y + math.floor((y * (s or 1)) + 0.5))
    end
end

function DropsWindow:_find_oldest_visible_record_index()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.layout_excluded ~= true then
            return i
        end
    end
    return nil
end

function DropsWindow:_remove_oldest_visible_for_overflow(now)
    local index = self:_find_oldest_visible_record_index()
    if index == nil then
        return
    end

    local record = self._active_drops[index]
    if State.settings.drops.animations_enabled == true then
        record.removing = true
        if record.fade_end_at == nil or now > record.fade_end_at then
            record.fade_end_at = now + EXIT_FADE_DURATION
        end
        record.layout_excluded = true
        record.pinned_y = record.current_y or record.target_y or 0
        record.target_y = record.pinned_y
        self:_clear_move_state(record)
    else
        table.remove(self._active_drops, index)
        self:_recycle_entry(record)
    end
end

function DropsWindow:_expire_active_drops(now)
    local animations_enabled = State.settings.drops.animations_enabled == true
    local removed = false

    for i = #self._active_drops, 1, -1 do
        local record = self._active_drops[i]
        if record ~= nil and record.removing ~= true and now >= (record.expire_at or 0) then
            if animations_enabled == true then
                record.removing = true
                record.fade_end_at = now + EXIT_FADE_DURATION
            else
                table.remove(self._active_drops, i)
                self:_recycle_entry(record)
                removed = true
            end
        end
    end

    if removed == true then
        self:_layout_active_drops(now, false)
    end

    local faded = false
    for i = #self._active_drops, 1, -1 do
        local record = self._active_drops[i]
        if record ~= nil and record.removing == true and now >= (record.fade_end_at or 0) then
            table.remove(self._active_drops, i)
            self:_recycle_entry(record)
            faded = true
        end
    end

    if faded == true then
        self:_layout_active_drops(now, animations_enabled)
    end
end

function DropsWindow:_layout_active_drops(now, animate)
    local anchor_x, anchor_y = self:GetPosition()
    local s = self:_screen_scale()
    local active_count = self:_layout_record_count()
    local row_h = _row_height()
    local spacing = _row_spacing()
    local step = row_h + spacing
    local base_y = self:_layout_base_y(active_count)
    local ordered = self:_ordered_layout_records()
    local move_duration = _move_duration()

    for i = 1, #ordered do
        local record = ordered[i]
        local target_y = base_y + ((i - 1) * step)
        record.target_y = target_y
        record.layout_excluded = false
        record.pinned_y = nil

        if record.entry ~= nil then
            if animate == true and move_duration > 0 and record.current_y ~= nil and math.abs(record.current_y - target_y) > 0.01 then
                record.move_start_at = now
                record.move_end_at = now + move_duration
                record.move_from_y = record.current_y
                record.move_to_y = target_y
            else
                self:_clear_move_state(record)
                self:_set_entry_y(record, anchor_x, anchor_y, target_y, s)
            end
        else
            record.current_y = target_y
        end
    end

    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.layout_excluded == true then
            local pinned_y = record.pinned_y or record.current_y or record.target_y or 0
            record.pinned_y = pinned_y
            record.target_y = pinned_y
            self:_clear_move_state(record)
            self:_set_entry_y(record, anchor_x, anchor_y, pinned_y, s)
        end
    end

    self:_refresh_background(self:is_move_mode())
end

function DropsWindow:_update_entry_positions(now)
    local anchor_x, anchor_y = self:GetPosition()
    local s = self:_screen_scale()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        local entry = record ~= nil and record.entry or nil
        if entry ~= nil then
            local y = record.current_y or record.target_y or 0

            if record.move_end_at ~= nil and record.move_start_at ~= nil and record.move_from_y ~= nil and record.move_to_y ~= nil then
                if now >= record.move_end_at then
                    y = record.move_to_y
                    self:_clear_move_state(record)
                else
                    local duration = record.move_end_at - record.move_start_at
                    local progress = 1
                    if duration > 0 then
                        progress = (now - record.move_start_at) / duration
                    end
                    if progress < 0 then
                        progress = 0
                    elseif progress > 1 then
                        progress = 1
                    end
                    y = record.move_from_y + ((record.move_to_y - record.move_from_y) * progress)
                end
                record.current_y = y
            end

            local opacity = 1
            if record.removing == true and record.fade_end_at ~= nil then
                local remaining = record.fade_end_at - now
                if remaining <= 0 then
                    opacity = 0
                else
                    opacity = remaining / EXIT_FADE_DURATION
                end
            end

            entry:set_opacity(opacity)
            entry:SetPosition(anchor_x, anchor_y + math.floor((y * s) + 0.5))
        end
    end
end

-- Cartel "LOOT" arriba de las filas: visible solo si esta activado, se
-- desvanece junto con la ultima fila que se va.
function DropsWindow:_refresh_banner(move_mode, active_count, base_y)
    local banner = self.banner
    if banner == nil then
        return
    end
    if State.settings.drops.show_banner == false
        or (move_mode ~= true and (active_count or 0) <= 0) then
        banner:SetVisible(false)
        return
    end

    local opacity = 1
    if move_mode ~= true then
        opacity = 0
        local now = Turbine.Engine.GetGameTime()
        for i = 1, #self._active_drops do
            local record = self._active_drops[i]
            if record ~= nil then
                local o = 1
                if record.removing == true and record.fade_end_at ~= nil then
                    o = (record.fade_end_at - now) / EXIT_FADE_DURATION
                    if o < 0 then o = 0 elseif o > 1 then o = 1 end
                end
                if o > opacity then
                    opacity = o
                end
            end
        end
    end

    -- el riel del cartel se apoya en el borde de arriba de la primera fila
    -- (todo en pixeles de pantalla: base_y se pasa con el factor nativo, y
    -- si el escalado del juego cambio, el cartel se rehace para el ancho
    -- que las filas tienen ahora)
    local s = self:_screen_scale()
    local width = self:_rows_width()
    local screen_w = self:_screen_width(width)
    if banner.fit_width ~= screen_w then
        banner:apply_settings(screen_w)
    end
    local anchor_x, anchor_y = self:GetPosition()
    banner:SetPosition(anchor_x + banner.offset_x - banner.pad,
        anchor_y + math.floor(((base_y or 0) * s) + 0.5) - banner.rail - banner.pad)
    banner:update_fx(opacity, Turbine.Engine.GetGameTime(),
        State.settings.drops.animations_enabled == true)
    banner:SetVisible(true)
end

function DropsWindow:_refresh_background(move_mode)
    if self.background == nil or self.content_background == nil then
        return
    end

    local width, height = self:GetSize()
    if move_mode == true then
        self.background:SetVisible(true)
        self.background:SetPosition(0, 0)
        self.background:SetSize(width, height)
        self.content_background:SetVisible(false)
        self:_refresh_banner(true, 0, 0)
        return
    end

    self.background:SetVisible(false)

    local active_count = self:_layout_record_count()
    if active_count <= 0 then
        self.content_background:SetVisible(false)
        self:_refresh_banner(false, 0, 0)
        return
    end

    local block_h = self:_layout_block_height(active_count)
    local base_y = self:_layout_base_y(active_count)
    self:_refresh_banner(false, active_count, base_y)

    local anchor_x, anchor_y = self:GetPosition()
    local s = self:_screen_scale()
    self.content_background:SetVisible(true)
    self.content_background:SetPosition(anchor_x, anchor_y + math.floor((base_y * s) + 0.5))
    self.content_background:SetSize(width, block_h)
end

function DropsWindow:_hide_entries()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.entry ~= nil then
            record.entry:SetVisible(false)
        end
    end
end

function DropsWindow:_show_entries()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.entry ~= nil then
            record.entry:SetVisible(true)
        end
    end
end
