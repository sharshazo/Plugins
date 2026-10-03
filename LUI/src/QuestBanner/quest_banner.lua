-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Cartel de misiones (pedido del jugador, 2026-09-30): arriba al centro,
-- sobre la barra de estado, un cartel animado que dice el TITULO de la
-- mision al aceptarla y "Completado" al terminarla. El estilo del cartel
-- (los 11 carteles del jugador) sale de la zona de la mision.
--
-- (Antes era un cartel con el nombre de la zona; el juego no avisa en el
-- chat al cambiar de zona, asi que se paso a las misiones.)
--
-- Deteccion: los mismos avisos del chat que usa LOTRO_Quest_Assistant
-- ("Nueva misión: X", "Completado: X", ...; Core/QuestEventParser.lua).
-- Zona de cada mision: indice generado desde la base de datos de Quest
-- Assistant (quest_banner_index.lua), con su misma regla de zona real.
-- "Completado:" tambien lo usa el juego para las HAZANAS: solo se muestra
-- si el nombre es de una mision; si ademas es el nombre de una hazana, solo
-- si se vio aceptar esa mision con este personaje.
--
-- El cartel se alarga por el medio (imagenes pregeneradas de 380 a 1020 px)
-- para que el titulo entre entero con letra legible. La ventana no toma el
-- mouse y no usa el escalado nativo del juego (imagenes a tamano real).

import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets.base_window"
import "LUI.src.Utils.callbacks"

local LUI = _G.LUI
LUI.Features.QuestBanner = LUI.Features.QuestBanner or {}
local QuestBanner = LUI.Features.QuestBanner
import "LUI.src.QuestBanner.quest_banner_data"

local UI = LUI.UI
local State = LUI.Settings.State
local Runtime = LUI.Runtime
local Windows = Runtime.Windows
local Apply = Runtime.Apply
local class = LUI.Core.class
local add_callback = LUI.Utils.add_callback
local remove_callback = LUI.Utils.remove_callback

local ASSET_DIR = "LUI/assets/ui/cartel/"
local DATA_KEY = "LUI_QuestBanner"
local COMPLETED_TEXT = "Completado"
local TOP_Y = 1                 -- borde de arriba del cartel en pantalla
local FRAME_TIME = 1 / 30       -- animaciones a 30 cuadros por segundo
local FADE_IN = 0.35
local FADE_OUT = 0.8
local SHOW_ACCEPTED = 6.0       -- segundos en pantalla (titulo)
local SHOW_COMPLETED = 3.5      -- segundos en pantalla ("Completado")
local MAX_QUEUE = 20            -- avisos en espera (se muestran uno tras otro)
local GAP = 0.35                -- pausa entre un cartel y el siguiente
local DUP_WINDOW = 10           -- s: el mismo aviso repetido no se encola dos veces
local MAX_LOG = 20              -- registro corto en lo guardado (diagnostico)
local MAX_ERRORS_SHOWN = 3
local SHINE_EVERY = 2.6
local SHINE_TIME = 1.0
local SPARK_PERIOD = 2.1
local TWO_PI = 2 * math.pi
local TRAJAN_SIZES = { 28, 26, 25, 24, 23, 21, 20, 19, 18, 16, 15, 14, 13 }
local PREFERRED_FONT = 20
local LOAD_DELAY = 5            -- s despues de entrar: se lee lo guardado
local INDEX_DELAY = 8           -- s despues de entrar: se arma el indice
local MAX_REMEMBERED = 300      -- misiones aceptadas recordadas (hazanas)

local AURA_FX = {
    sombra = { period = 1.7, flicker = 0.10 },
    hielo = { period = 3.4, flicker = 0 },
    elfico = { period = 3.0, flicker = 0 },
    enano = { period = 2.2, flicker = 0.05 },
}
local AURA_DEFAULT = { period = 2.6, flicker = 0 }

-- ---------------------------------------------------------------------
-- Nombres: misma normalizacion que Quest Assistant (toLowerES)
-- ---------------------------------------------------------------------

local ACCENT_PAIRS = {
    { "\195\129", "\195\161" }, { "\195\137", "\195\169" }, { "\195\141", "\195\173" },
    { "\195\147", "\195\179" }, { "\195\154", "\195\186" }, { "\195\145", "\195\177" },
    { "\195\156", "\195\188" },
}

local function _norm(s)
    if type(s) ~= "string" then
        return ""
    end
    local t = string.lower(s)
    if string.find(t, "\195", 1, true) then
        for i = 1, #ACCENT_PAIRS do
            t = t:gsub(ACCENT_PAIRS[i][1], ACCENT_PAIRS[i][2])
        end
    end
    t = t:gsub("%s+", " ")
    t = t:gsub("^%s*(.-)%s*$", "%1")
    return t
end
QuestBanner.norm = _norm

local function _trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function _strip_rgb(s)
    if not string.find(s, "<", 1, true) then
        return s
    end
    s = s:gsub("<[rR][gG][bB]=[^>]*>", "")
    s = s:gsub("</[rR][gG][bB]>", "")
    return s
end

local _index = nil      -- nombre normalizado -> estilo
local _deeds = nil      -- nombres que tambien son de una hazana

local function _build_index()
    if _index ~= nil then
        return
    end
    _index, _deeds = {}, {}
    local ok = pcall(import, "LUI.src.QuestBanner.quest_banner_index")
    if ok ~= true or type(QuestBanner.INDEX) ~= "table" then
        return
    end
    for style, blob in pairs(QuestBanner.INDEX) do
        if QuestBanner.STYLES[style] ~= nil and type(blob) == "string" then
            for name in blob:gmatch("[^\n]+") do
                _index[name] = style
            end
        end
    end
    if type(QuestBanner.DEEDS) == "string" then
        for name in QuestBanner.DEEDS:gmatch("[^\n]+") do
            _deeds[name] = true
        end
    end
    -- los textos ya estan en la tabla: se sueltan los bloques
    QuestBanner.INDEX = nil
    QuestBanner.DEEDS = nil
end

-- variantes del nombre, igual que Quest Assistant: tal cual, sin punto
-- final, sin ningun punto y sin marcas de color
local function _variants(text)
    local out, seen = {}, {}
    local function add(v)
        v = _trim(v)
        if v ~= "" and not seen[v] then
            seen[v] = true
            out[#out + 1] = v
        end
    end
    add(text)
    add((_trim(text):gsub("%.+$", "")))
    add((text:gsub("%.", "")))
    local plain = _strip_rgb(text)
    if plain ~= text then
        add(plain)
        add((_trim(plain):gsub("%.+$", "")))
    end
    return out
end

-- estilo y clave normalizada del nombre (nil si no es una mision conocida)
function QuestBanner.lookup(name)
    _build_index()
    local vs = _variants(name)
    for i = 1, #vs do
        local key = _norm(vs[i])
        local style = _index[key]
        if style ~= nil then
            return style, key
        end
    end
    return nil, nil
end

-- ---------------------------------------------------------------------
-- Avisos del chat
-- ---------------------------------------------------------------------

-- "strict" = la frase ya dice que es una mision; si no, el nombre tiene
-- que estar en la base
local ACCEPT_PATTERNS = {
    { "^Nueva misi\195\179n:%s*(.-)%s*$", true },
    { "^Nueva mision:%s*(.-)%s*$", true },
    { "^New Quest:%s*(.-)%s*$", true },
    { "^Has aceptado la misi\195\179n:%s*(.-)%s*$", true },
    { "^Has aceptado la mision:%s*(.-)%s*$", true },
    { "^Misi\195\179n nueva:%s*(.-)%s*$", true },
    { "^Mision nueva:%s*(.-)%s*$", true },
    { "^Has aceptado%s+(.-)%s*$", false },
}
local COMPLETE_PATTERNS = {
    { "^Misi\195\179n completada:%s*(.-)%s*$", true },
    { "^Mision completada:%s*(.-)%s*$", true },
    { "^Completado:%s*(.-)%s*$", false },
    { "^Completed:%s*(.-)%s*$", false },
    { "^Has completado%s+(.-)%s*$", false },
}

local function _clean_line(message)
    local t = _strip_rgb(message)
    t = t:gsub("^%s*%[%d%d?/%d%d?[^%]]*%]%s*", "")
    t = t:gsub("^%s*%[%d%d?:%d%d[^%]]*%]%s*", "")
    t = t:gsub("^%s+", "")
    return t
end

-- Devuelve "accepted"/"completed", el titulo a mostrar, el estilo y la
-- clave; nil si la linea no es un aviso de mision que haya que mostrar.
function QuestBanner.parse(message)
    if type(message) ~= "string" or message == "" then
        return nil
    end
    local line = _clean_line(message)
    for i = 1, #ACCEPT_PATTERNS do
        local p = ACCEPT_PATTERNS[i]
        local name = line:match(p[1])
        if name ~= nil then
            name = _trim((name:gsub("%s+", " ")))
            if name == "" then
                return nil
            end
            local style, key = QuestBanner.lookup(name)
            if style == nil and p[2] ~= true then
                return nil
            end
            local title = _trim((name:gsub("%.+$", "")))
            return "accepted", title, style or "general", key or _norm(name)
        end
    end
    for i = 1, #COMPLETE_PATTERNS do
        local p = COMPLETE_PATTERNS[i]
        local name = line:match(p[1])
        if name ~= nil then
            name = _trim((name:gsub("%s+", " ")))
            if name == "" then
                return nil
            end
            local style, key = QuestBanner.lookup(name)
            if style == nil then
                if p[2] ~= true then
                    return nil
                end
                style, key = "general", _norm(name)
            end
            return "completed", COMPLETED_TEXT, style, key
        end
    end
    return nil
end

-- ---------------------------------------------------------------------
-- Ventana del cartel
-- ---------------------------------------------------------------------

local function _layer(parent)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    return c
end

local function _settings()
    local sb = State.settings ~= nil and State.settings.status_bar or nil
    return sb or {}
end

-- Ancho del texto en la letra Trajan del juego. Tabla de avances por letra
-- (fraccion del tamano de letra) tomada de Cinzel, una Trajan libre; se
-- comparo con texto Trajan real del juego (captura del jugador, aviso en
-- pantalla) y Cinzel resulta ~2% MAS ANCHA a igual altura de mayusculas,
-- asi que esta medida nunca se queda corta. Letras que no estan en la tabla
-- cuentan como la "M" (la mas ancha).
local TRAJAN_ADV = {
    [" "] = 0.25, ["!"] = 0.23, ["\34"] = 0.315, ["#"] = 0.536, ["$"] = 0.469, ["%"] = 0.684,
    ["&"] = 0.646, ["'"] = 0.17, ["("] = 0.338, [")"] = 0.338, ["*"] = 0.386, ["+"] = 0.481,
    [","] = 0.185, ["-"] = 0.38, ["."] = 0.179, ["/"] = 0.406, ["0"] = 0.596, ["1"] = 0.344,
    ["2"] = 0.553, ["3"] = 0.503, ["4"] = 0.583, ["5"] = 0.498, ["6"] = 0.56, ["7"] = 0.502,
    ["8"] = 0.552, ["9"] = 0.56, [":"] = 0.179, [";"] = 0.185, ["<"] = 0.481, ["="] = 0.481,
    [">"] = 0.481, ["?"] = 0.413, ["@"] = 0.977, ["A"] = 0.712, ["B"] = 0.586, ["C"] = 0.76,
    ["D"] = 0.807, ["E"] = 0.577, ["F"] = 0.541, ["G"] = 0.798, ["H"] = 0.813, ["I"] = 0.338,
    ["J"] = 0.324, ["K"] = 0.657, ["L"] = 0.562, ["M"] = 0.931, ["N"] = 0.841, ["O"] = 0.838,
    ["P"] = 0.577, ["Q"] = 0.837, ["R"] = 0.677, ["S"] = 0.475, ["T"] = 0.618, ["U"] = 0.785,
    ["V"] = 0.74, ["W"] = 0.982, ["X"] = 0.662, ["Y"] = 0.661, ["Z"] = 0.651, ["["] = 0.332,
    ["\92"] = 0.406, ["]"] = 0.332, ["^"] = 0.523, ["_"] = 0.5, ["`"] = 0.439, ["a"] = 0.663,
    ["b"] = 0.57, ["c"] = 0.705, ["d"] = 0.76, ["e"] = 0.546, ["f"] = 0.523, ["g"] = 0.742,
    ["h"] = 0.746, ["i"] = 0.336, ["j"] = 0.309, ["k"] = 0.624, ["l"] = 0.536, ["m"] = 0.878,
    ["n"] = 0.779, ["o"] = 0.774, ["p"] = 0.553, ["q"] = 0.777, ["r"] = 0.627, ["s"] = 0.462,
    ["t"] = 0.578, ["u"] = 0.7, ["v"] = 0.663, ["w"] = 0.899, ["x"] = 0.626, ["y"] = 0.64,
    ["z"] = 0.608, ["{"] = 0.337, ["|"] = 0.245, ["}"] = 0.337, ["~"] = 0.493, ["\195\129"] = 0.712,
    ["\195\137"] = 0.577, ["\195\141"] = 0.338, ["\195\147"] = 0.838, ["\195\154"] = 0.785,
    ["\195\145"] = 0.841, ["\195\156"] = 0.785, ["\195\161"] = 0.663, ["\195\169"] = 0.546,
    ["\195\173"] = 0.306, ["\195\179"] = 0.774, ["\195\186"] = 0.7, ["\195\177"] = 0.779,
    ["\195\188"] = 0.7, ["\195\128"] = 0.712, ["\195\136"] = 0.577, ["\195\140"] = 0.338,
    ["\195\146"] = 0.838, ["\195\153"] = 0.785, ["\195\160"] = 0.663, ["\195\168"] = 0.546,
    ["\195\172"] = 0.306, ["\195\178"] = 0.774, ["\195\185"] = 0.7, ["\195\130"] = 0.712,
    ["\195\138"] = 0.577, ["\195\142"] = 0.338, ["\195\148"] = 0.838, ["\195\155"] = 0.785,
    ["\195\162"] = 0.663, ["\195\170"] = 0.546, ["\195\174"] = 0.306, ["\195\180"] = 0.774,
    ["\195\187"] = 0.7, ["\195\132"] = 0.712, ["\195\139"] = 0.577, ["\195\143"] = 0.338,
    ["\195\150"] = 0.838, ["\195\164"] = 0.663, ["\195\171"] = 0.546, ["\195\175"] = 0.306,
    ["\195\182"] = 0.774, ["\195\135"] = 0.76, ["\195\167"] = 0.705, ["\195\133"] = 0.712,
    ["\195\165"] = 0.663, ["\195\134"] = 0.902, ["\195\166"] = 0.83, ["\195\152"] = 0.828,
    ["\195\184"] = 0.774, ["\195\159"] = 0.924, ["\194\161"] = 0.23, ["\194\191"] = 0.433,
    ["\194\171"] = 0.453, ["\194\187"] = 0.453, ["\194\183"] = 0.17, ["\226\128\153"] = 0.193,
    ["\226\128\152"] = 0.193, ["\226\128\156"] = 0.333, ["\226\128\157"] = 0.333,
    ["\226\128\147"] = 0.5, ["\226\128\148"] = 0.8, ["\226\128\166"] = 0.569,
}
local ADV_DEFAULT = 0.931
local OUTLINE_PX = 2            -- borde negro del texto (1 px por lado)
local FIT = 0.95                -- el texto ocupa como maximo el 95% del recuadro

local function _text_units(text)
    local units, i, n = 0, 1, string.len(text)
    while i <= n do
        local c = string.byte(text, i)
        local len = 1
        if c >= 240 then
            len = 4
        elseif c >= 224 then
            len = 3
        elseif c >= 192 then
            len = 2
        end
        local ch = string.sub(text, i, i + len - 1)
        units = units + (TRAJAN_ADV[ch] or ADV_DEFAULT)
        i = i + len
    end
    return units
end
QuestBanner.text_units = _text_units

local function _estimate_width(text, size)
    return (_text_units(text) * size) + OUTLINE_PX
end
QuestBanner.estimate_width = _estimate_width

-- mayor letra que entra en el recuadro (0 si ni la mas chica entra)
local function _best_font(text, panel_w, panel_h)
    local max_by_height = math.floor(panel_h * 0.95)
    for i = 1, #TRAJAN_SIZES do
        local size = TRAJAN_SIZES[i]
        if size <= max_by_height and _estimate_width(text, size) <= panel_w * FIT then
            return size
        end
    end
    return 0
end

-- el cartel mas corto donde el texto entra con letra comoda; si ninguno,
-- el mas largo con la letra mas grande que entre
function QuestBanner.choose(style, text)
    local def = QuestBanner.STYLES[style] or QuestBanner.STYLES.general
    local widths = QuestBanner.WIDTHS
    local best_w, best_font = widths[#widths], 0
    for i = 1, #widths do
        local L = def.widths[widths[i]]
        local font = _best_font(text, L.panel[3], L.panel[4])
        local wanted = math.min(PREFERRED_FONT, math.floor(L.panel[4] * 0.95))
        if font >= wanted then
            return widths[i], font
        end
        if font > best_font then
            best_w, best_font = widths[i], font
        end
    end
    if best_font == 0 then
        best_font = TRAJAN_SIZES[#TRAJAN_SIZES]
    end
    return best_w, best_font
end

local QuestBannerWindow = class(UI.Widgets.LuiBaseWindow)
QuestBanner.QuestBannerWindow = QuestBannerWindow

function QuestBannerWindow:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })
    UI.NativeScaling.disable(self)

    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    -- de atras hacia adelante
    self.aura = _layer(self)
    self.image = _layer(self)
    self.label = Turbine.UI.Label()
    self.label:SetParent(self)
    self.label:SetMouseVisible(false)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
    pcall(self.label.SetMultiline, self.label, false)
    self.clip = _layer(self)
    self.shine = _layer(self.clip)
    self.shine:SetBackground(ASSET_DIR .. "zb_brillo.tga")
    self.shine:SetSize(QuestBanner.SHINE.w, QuestBanner.SHINE.h)
    self.shine:SetVisible(false)
    self.sparks = {}

    self.style = nil
    self.width = nil
    self.layout = nil
    self.current = nil
    self.last_frame = 0
    self.display_w = nil
    self.display_check_at = 0
    self:SetWantsUpdates(true)
end

function QuestBannerWindow:_ensure_sparks(count)
    for i = #self.sparks + 1, count do
        self.sparks[i] = _layer(self)
        self.sparks[i]:SetVisible(false)
    end
    for i = 1, #self.sparks do
        self.sparks[i]:SetVisible(false)
    end
end

function QuestBannerWindow:_build(style, width)
    local def = QuestBanner.STYLES[style] or QuestBanner.STYLES.general
    local L = def.widths[width] or def.widths[QuestBanner.WIDTHS[1]]
    local base = ASSET_DIR .. "zb_" .. style .. "_"
    UI.NativeScaling.disable(self)

    self.style = style
    self.width = width
    self.layout = L

    local pad = L.pad
    self:SetSize(L.w + (2 * pad), L.h + (2 * pad))
    self.aura:SetBackground(base .. "aura_w" .. tostring(width) .. ".tga")
    self.aura:SetPosition(0, 0)
    self.aura:SetSize(L.w + (2 * pad), L.h + (2 * pad))
    self.image:SetBackground(base .. "w" .. tostring(width) .. ".tga")
    self.image:SetPosition(pad, pad)
    self.image:SetSize(L.w, L.h)

    local px, py, pw, ph = L.panel[1], L.panel[2], L.panel[3], L.panel[4]
    -- el texto se centra en el recuadro; la etiqueta es 8 px mas alta para
    -- que ninguna letra quede recortada arriba o abajo
    self.label:SetPosition(pad + px, pad + py - 4)
    self.label:SetSize(pw, ph + 8)
    self.label:SetForeColor(Turbine.UI.Color(1, def.text[1] / 255, def.text[2] / 255, def.text[3] / 255))

    self.clip:SetPosition(pad + px, pad + py)
    self.clip:SetSize(pw, ph)
    self.shine:SetPosition(-QuestBanner.SHINE.w, math.floor((ph - QuestBanner.SHINE.h) / 2))

    self:_ensure_sparks(#L.sparks)
    local spark = def.spark
    local half = math.floor(spark / 2)
    for i = 1, #L.sparks do
        local s = self.sparks[i]
        s:SetBackground(base .. "chispa.tga")
        s:SetSize(spark, spark)
        s:SetPosition(pad + L.sparks[i][1] - half, pad + L.sparks[i][2] - half)
    end

    self:_place()
end

function QuestBannerWindow:_place()
    local L = self.layout
    if L == nil then
        return
    end
    local display_w = Turbine.UI.Display.GetWidth()
    self.display_w = display_w
    local x = math.floor((display_w - L.w) / 2) - L.pad
    if x < -L.pad then
        x = -L.pad
    end
    self:SetPosition(x, TOP_Y - L.pad)
end

-- muestra un aviso {text, style, duration}; el tiempo corre desde ahora
function QuestBannerWindow:show_item(item, now)
    local width, font_size = QuestBanner.choose(item.style, item.text)
    if item.style ~= self.style or width ~= self.width then
        self:_build(item.style, width)
    end
    local font = LUI.Utils.FONT_TO_LOTRO("TrajanPro", font_size)
    if font ~= nil then
        self.label:SetFont(font)
    end
    self.label:SetText(item.text)
    item.started = now
    self.current = item
    self.last_frame = 0
    self:_animate(now)
    self:SetVisible(true)
end

function QuestBannerWindow:hide_item()
    self.current = nil
    self:SetVisible(false)
end

-- opacidad de aparicion/desaparicion del aviso actual (0..1)
function QuestBannerWindow:_presence(now)
    local item = self.current
    if item == nil then
        return 0
    end
    local t = now - item.started
    if t < 0 then
        return 0
    end
    if t < FADE_IN then
        return t / FADE_IN
    end
    local left = item.duration - t
    if left <= 0 then
        return 0
    end
    if left < FADE_OUT then
        return left / FADE_OUT
    end
    return 1
end

function QuestBannerWindow:_animate(now)
    local appear = self:_presence(now)
    local animate = _settings().zone_animations ~= false

    self.image:SetOpacity(appear)
    self.label:SetOpacity(appear)

    if animate ~= true then
        self.aura:SetOpacity(0.75 * appear)
        self.shine:SetVisible(false)
        for i = 1, #self.sparks do
            self.sparks[i]:SetVisible(false)
        end
        return
    end

    local fx = AURA_FX[self.style] or AURA_DEFAULT
    local breath = 0.60 + (0.30 * math.sin(TWO_PI * now / fx.period))
    if fx.flicker > 0 then
        breath = breath + (fx.flicker * math.sin(TWO_PI * now * 3.7) * math.sin(TWO_PI * now * 1.3))
    end
    if breath < 0 then breath = 0 elseif breath > 1 then breath = 1 end
    self.aura:SetOpacity(breath * appear)

    -- destello que cruza el recuadro del texto (el primero apenas aparece)
    local L = self.layout
    local item = self.current
    local phase = item ~= nil and ((now - item.started - FADE_IN) % SHINE_EVERY) or SHINE_EVERY
    if item ~= nil and now - item.started >= FADE_IN and phase <= SHINE_TIME and L ~= nil then
        local t = phase / SHINE_TIME
        local x = math.floor(-QuestBanner.SHINE.w + ((L.panel[3] + QuestBanner.SHINE.w) * t))
        self.shine:SetPosition(x, math.floor((L.panel[4] - QuestBanner.SHINE.h) / 2))
        self.shine:SetOpacity(appear)
        self.shine:SetVisible(true)
    else
        self.shine:SetVisible(false)
    end

    -- chispas en las gemas
    local count = L ~= nil and #L.sparks or 0
    for i = 1, #self.sparks do
        local s = self.sparks[i]
        if i <= count then
            local v = math.sin(TWO_PI * ((now / SPARK_PERIOD) + (i * 0.29)))
            local o = 0
            if v > 0 then
                o = v * v * v
            end
            s:SetOpacity(o * appear)
            s:SetVisible(o > 0.03)
        else
            s:SetVisible(false)
        end
    end
end

function QuestBannerWindow:Update()
    local now = Turbine.Engine.GetGameTime()
    if now - self.last_frame < FRAME_TIME then
        return
    end
    self.last_frame = now
    if now >= self.display_check_at then
        self.display_check_at = now + 1
        if self.layout ~= nil and Turbine.UI.Display.GetWidth() ~= self.display_w then
            self:_place()
        end
    end
    QuestBanner._tick(now)
    if self.current ~= nil then
        self:_animate(now)
    end
end

function QuestBannerWindow:destroy()
    self:SetWantsUpdates(false)
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

-- ---------------------------------------------------------------------
-- Cola de avisos, chat, guardado y barra de estado
-- ---------------------------------------------------------------------

local _queue = {}
local _chat_handle = nil
local _started_at = nil
local _load_requested = false
local _loaded = false
local _save_due_at = nil
local _state = { style = nil, accepted = {}, order = {} }
local _log = {}                 -- { "hora | que | titulo", ... } (ultimos MAX_LOG)
local _errors_shown = 0

local function _enabled()
    return _settings().zone_banner ~= false
end

local function _tint_enabled()
    return _settings().zone_tint ~= false
end

-- color de la barra de estado: el del ultimo cartel mostrado
local function _apply_tint()
    local bar = Windows.status_bar
    if bar == nil or bar.set_zone_tint == nil then
        return
    end
    local style = _state.style
    if style == nil or QuestBanner.STYLES[style] == nil or _enabled() ~= true or _tint_enabled() ~= true then
        pcall(bar.set_zone_tint, bar, nil)
        return
    end
    local def = QuestBanner.STYLES[style]
    pcall(bar.set_zone_tint, bar, def.bar, def.text)
end

local function _schedule_save(now)
    _save_due_at = (now or Turbine.Engine.GetGameTime()) + 2
end

-- registro corto de lo que paso con los carteles (queda en lo guardado del
-- personaje, LUI_QuestBanner.plugindata), para revisar si alguno no salio
local function _note(what, text, now)
    local t = now or Turbine.Engine.GetGameTime()
    _log[#_log + 1] = string.format("%.1f | %s | %s", t, tostring(what), tostring(text or ""))
    while #_log > MAX_LOG do
        table.remove(_log, 1)
    end
    _schedule_save(t)
end

local function _report_error(err)
    _note("error", tostring(err))
    if _errors_shown < MAX_ERRORS_SHOWN then
        _errors_shown = _errors_shown + 1
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> cartel de misiones: " .. tostring(err))
    end
end

local function _save()
    local accepted = {}
    for i = 1, #_state.order do
        accepted[i] = _state.order[i]
    end
    local log = {}
    for i = 1, #_log do
        log[i] = _log[i]
    end
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Character, DATA_KEY,
        { style = _state.style, accepted = accepted, log = log })
end

local function _remember_accepted(key)
    if type(key) ~= "string" or key == "" or _state.accepted[key] == true then
        return
    end
    _state.accepted[key] = true
    _state.order[#_state.order + 1] = key
    while #_state.order > MAX_REMEMBERED do
        local old = table.remove(_state.order, 1)
        _state.accepted[old] = nil
    end
end

-- false si ese mismo aviso ya esta en la cola o se acaba de mostrar (el
-- juego a veces repite la linea del chat)
local function _enqueue(item, now)
    if item.id ~= nil then
        for i = 1, #_queue do
            if _queue[i].id == item.id then
                return false
            end
        end
        local win = Windows.quest_banner
        local cur = win ~= nil and win.current or nil
        if cur ~= nil and cur.id == item.id and cur.started ~= nil and now - cur.started < DUP_WINDOW then
            return false
        end
    end
    _queue[#_queue + 1] = item
    while #_queue > MAX_QUEUE do
        table.remove(_queue, 1)
    end
    return true
end

-- muestra el siguiente aviso de la cola (empieza "delay" segundos despues;
-- mientras tanto la ventana sigue visible pero transparente). Un aviso que
-- falla se salta y se sigue con el proximo. true si quedo uno en pantalla.
local function _show_next(win, now, delay)
    while #_queue > 0 do
        local nxt = table.remove(_queue, 1)
        local ok, err = pcall(win.show_item, win, nxt, now + (delay or 0))
        if ok == true then
            _note("cartel", nxt.text, now)
            return true
        end
        _report_error(err)
    end
    return false
end

-- si no hay ningun cartel en pantalla, el siguiente sale YA (sin esperar
-- al proximo cuadro)
local function _kick(now)
    local win = Windows.quest_banner
    if win ~= nil and win.current == nil and #_queue > 0 then
        _show_next(win, now or Turbine.Engine.GetGameTime(), 0)
    end
end

-- aviso de mision leido del chat (o de "/lui cartel")
function QuestBanner.notify(kind, text, style, key)
    if kind == "accepted" then
        _remember_accepted(key)
    elseif kind == "completed" then
        -- nombre que tambien es de una hazana: solo si se vio aceptar la mision
        _build_index()
        if key ~= nil and _deeds[key] == true and _state.accepted[key] ~= true then
            return false
        end
    else
        return false
    end
    if QuestBanner.STYLES[style] == nil then
        style = "general"
    end
    local now = Turbine.Engine.GetGameTime()
    _state.style = style
    _schedule_save(now)
    _apply_tint()
    if _enabled() == true and Windows.quest_banner ~= nil then
        local added = _enqueue({
            text = text,
            style = style,
            duration = kind == "completed" and SHOW_COMPLETED or SHOW_ACCEPTED,
            id = key ~= nil and (kind .. "|" .. key) or nil,
        }, now)
        _note(added and (kind == "completed" and "completada" or "aceptada") or "repetida", text, now)
        if added then
            _kick(now)
        end
    end
    return true
end

local function _on_chat(_, args)
    if args == nil or type(args.Message) ~= "string" then
        return
    end
    local ok, kind, text, style, key = pcall(QuestBanner.parse, args.Message)
    if ok == true and kind ~= nil then
        pcall(QuestBanner.notify, kind, text, style, key)
    end
end

local function _install_chat()
    if _chat_handle == nil then
        _chat_handle = add_callback(Turbine.Chat, "Received", _on_chat)
    end
end

local function _uninstall_chat()
    if _chat_handle ~= nil then
        remove_callback(Turbine.Chat, "Received", _chat_handle)
        _chat_handle = nil
    end
end

local function _request_load()
    if _load_requested == true then
        return
    end
    _load_requested = true
    local ok = pcall(Turbine.PluginData.Load, Turbine.DataScope.Character, DATA_KEY, function(data)
        _loaded = true
        if type(data) ~= "table" then
            return
        end
        if type(data.accepted) == "table" then
            for i = 1, #data.accepted do
                if type(data.accepted[i]) == "string" then
                    _remember_accepted(data.accepted[i])
                end
            end
        end
        -- registro de la sesion anterior (lo de esta sesion va despues)
        if type(data.log) == "table" then
            local merged = {}
            for i = 1, #data.log do
                if type(data.log[i]) == "string" then
                    merged[#merged + 1] = data.log[i]
                end
            end
            for i = 1, #_log do
                merged[#merged + 1] = _log[i]
            end
            while #merged > MAX_LOG do
                table.remove(merged, 1)
            end
            _log = merged
        end
        -- un aviso llegado antes que lo guardado gana
        if _state.style == nil and type(data.style) == "string" and QuestBanner.STYLES[data.style] ~= nil then
            _state.style = data.style
            _apply_tint()
        end
    end)
    if ok ~= true then
        _loaded = true -- sin datos guardados que leer: se puede guardar igual
    end
end

-- "/lui cartel demo": los 11 estilos, uno tras otro
local DEMO = {
    { "general", "Una misi\195\179n de la Tierra Media" }, { "comarca", "Hierbas para la Comarca" },
    { "elfico", "Libro 6, Cap\195\173tulo 1: De Golodir y Angmar" }, { "arnor", "Las ruinas de Fornost" },
    { "hielo", "Enanos y mamuts" }, { "sombra", "La sombra de Angmar" }, { "enano", "Pasaje hacia la oscuridad" },
    { "rohan", "Los jinetes de Rohan" }, { "gondor", "La defensa de Minas Tirith" },
    { "salvajes", "Tierras Brunas" }, { "sur", "Los puertos de Umbar" },
}

-- "/lui cartel prueba": los titulos que mas justo entran en su cartel (uno
-- por estilo) y el mas largo de todos, para verlos en el juego
local FIT_TEST = {
    { "enano", "Angmarim in Skarashulg" }, { "comarca", "Lobos en los campos" },
    { "sombra", "Banishing the Shadows" }, { "arnor", "The Hunt Continues" },
    { "sur", "The Sound of Scorpions" }, { "elfico", "Acabando con los Moribundos" },
    { "salvajes", "Charm of the Huntsman" }, { "gondor", "Flames of the South-beacon" },
    { "hielo", "Los lazos que nos unen" }, { "general", "Angmar Legendario: Gran T\195\186mulo - Sambrog" },
    { "rohan", "Eyes Out of the Sky" },
    { "general", "Bosque Negro Legendario: Escaramuza - 'Asalto a la guarida de los Espectros del Anillo'" },
}

function QuestBanner.start_fit_test()
    if Windows.quest_banner == nil then
        return false
    end
    _queue = {}
    for i = 1, #FIT_TEST do
        _queue[#_queue + 1] = { text = FIT_TEST[i][2], style = FIT_TEST[i][1], duration = 4.0 }
    end
    _kick()
    return true
end

function QuestBanner.start_demo()
    if Windows.quest_banner == nil then
        return false
    end
    _queue = {}
    for i = 1, #DEMO do
        _queue[#_queue + 1] = { text = DEMO[i][2], style = DEMO[i][1], duration = 3.0 }
    end
    _queue[#_queue + 1] = { text = COMPLETED_TEXT, style = "rohan", duration = SHOW_COMPLETED }
    _kick()
    return true
end

-- "/lui cartel cola": 3 misiones aceptadas seguidas + una completada, por el
-- mismo camino que los avisos reales del chat (para ver la cola en el juego)
local QUEUE_TEST = {
    { "accepted", "Eliminando el rastro" }, { "accepted", "Thorkell ha ca\195\173do" },
    { "accepted", "Fr\195\173o hasta los huesos" }, { "completed", COMPLETED_TEXT },
}

function QuestBanner.start_queue_test()
    if Windows.quest_banner == nil then
        return false
    end
    for i = 1, #QUEUE_TEST do
        local style = QuestBanner.lookup(QUEUE_TEST[i][2]) or "hielo"
        QuestBanner.notify(QUEUE_TEST[i][1], QUEUE_TEST[i][2], style, nil)
    end
    return true
end

function QuestBanner._tick(now)
    if _started_at == nil then
        _started_at = now
    end
    if _load_requested ~= true and now >= _started_at + LOAD_DELAY then
        _request_load()
    end
    if _index == nil and now >= _started_at + INDEX_DELAY then
        _build_index()
    end
    if _save_due_at ~= nil and now >= _save_due_at and _loaded == true then
        _save_due_at = nil
        _save()
    end

    local win = Windows.quest_banner
    if win == nil then
        return
    end
    local item = win.current
    if item ~= nil and now - item.started >= item.duration then
        -- termino: el siguiente de la cola sale despues de una pausa corta,
        -- SIN ocultar la ventana entre uno y otro; si no hay mas, se oculta
        win.current = nil
        if _show_next(win, now, GAP) ~= true then
            win:hide_item()
        end
        return
    end
    if item == nil and #_queue > 0 then
        _show_next(win, now, 0)
    end
end

-- crea / quita el cartel segun Opciones. Se llama cada vez que se rehace la
-- barra de estado: la ventana se rehace despues, asi queda por encima.
function Apply.quest_banner_settings()
    local pending = nil
    if Windows.quest_banner ~= nil then
        pending = Windows.quest_banner.current
        Windows.quest_banner:destroy()
        Windows.quest_banner = nil
    end
    if _enabled() == true then
        Windows.quest_banner = QuestBannerWindow()
        if pending ~= nil then
            table.insert(_queue, 1, pending)
        end
        _kick()
    else
        _queue = {}
    end
    _install_chat()
    _apply_tint()
end

function QuestBanner.shutdown()
    _uninstall_chat()
    _queue = {}
    if _save_due_at ~= nil and _loaded == true then
        _save_due_at = nil
        _save()
    end
    if Windows.quest_banner ~= nil then
        Windows.quest_banner:destroy()
        Windows.quest_banner = nil
    end
end
