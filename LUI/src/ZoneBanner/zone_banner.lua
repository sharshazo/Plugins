-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Cartel de zona (pedido del jugador, 2026-09-30): arriba al centro, sobre
-- la barra de estado, un cartel con el nombre de la zona en la que esta el
-- personaje. Hay 11 estilos (los carteles que hizo el jugador) y el estilo
-- sale del nombre de la zona; una zona que no se conoce usa "general".
--
-- Como se sabe la zona: al entrar a cada region el juego une al personaje
-- al canal "<Zona> - Regional" y lo avisa en el chat ("Entered the
-- Bree-land - Regional channel." / "Entro en ... - Regional"). Solo se
-- usan esos avisos de ENTRADA; los de salida nombran la zona que se deja.
-- La ultima zona se guarda por personaje (LUI_ZoneBanner) para que al
-- entrar al juego el cartel ya muestre algo antes del primer aviso.
--
-- Todo es imagen + un texto: la ventana no toma el mouse, no toca la barra
-- de estado salvo su color de fondo (opcional) y no escucha otra cosa que
-- el chat. Tamanos: 300 / 380 / 460 px de ancho (imagenes pregeneradas,
-- SetBackground no reescala). La ventana NO usa el escalado nativo del
-- juego: las imagenes se dibujan siempre a su tamano real y asi el aura,
-- el cartel, el texto y las chispas quedan siempre encajados.

import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets.base_window"
import "LUI.src.Utils.callbacks"

local LUI = _G.LUI
LUI.Features.ZoneBanner = LUI.Features.ZoneBanner or {}
local ZoneBanner = LUI.Features.ZoneBanner
import "LUI.src.ZoneBanner.zone_banner_data"

local UI = LUI.UI
local State = LUI.Settings.State
local Runtime = LUI.Runtime
local Windows = Runtime.Windows
local Apply = Runtime.Apply
local class = LUI.Core.class
local add_callback = LUI.Utils.add_callback
local remove_callback = LUI.Utils.remove_callback

local ASSET_DIR = "LUI/assets/ui/zona/"
local DATA_KEY = "LUI_ZoneBanner"
local DEFAULT_SIZE = 380
local TOP_Y = 1                 -- borde de arriba del cartel en pantalla
local FRAME_TIME = 1 / 30       -- animaciones a 30 cuadros por segundo
local FADE_IN = 0.6             -- aparicion al cambiar de zona
local SHINE_EVERY = 5.0         -- segundos entre destellos
local SHINE_TIME = 1.1          -- lo que tarda el destello en cruzar
local SPARK_PERIOD = 2.1
local TWO_PI = 2 * math.pi
local TRAJAN_SIZES = { 28, 26, 25, 24, 23, 21, 20, 19, 18, 16, 15, 14, 13 }

-- aura: periodo de "respiracion" y cuanto titila (la sombra parpadea como
-- brasas, el hielo respira lento)
local AURA_FX = {
    sombra = { period = 1.7, flicker = 0.10 },
    hielo = { period = 3.4, flicker = 0 },
    elfico = { period = 3.0, flicker = 0 },
    enano = { period = 2.2, flicker = 0.05 },
}
local AURA_DEFAULT = { period = 2.6, flicker = 0 }

-- ---------------------------------------------------------------------
-- Nombre de zona -> estilo
-- ---------------------------------------------------------------------

-- minusculas y sin acentos (UTF-8), guiones y apostrofes como espacio
local ACCENTS = {
    ["\195\161"] = "a", ["\195\169"] = "e", ["\195\173"] = "i", ["\195\179"] = "o", ["\195\186"] = "u",
    ["\195\162"] = "a", ["\195\170"] = "e", ["\195\174"] = "i", ["\195\180"] = "o", ["\195\187"] = "u",
    ["\195\164"] = "a", ["\195\171"] = "e", ["\195\175"] = "i", ["\195\182"] = "o", ["\195\188"] = "u",
    ["\195\160"] = "a", ["\195\168"] = "e", ["\195\172"] = "i", ["\195\178"] = "o", ["\195\185"] = "u",
    ["\195\177"] = "n", ["\195\167"] = "c",
    ["\195\129"] = "a", ["\195\137"] = "e", ["\195\141"] = "i", ["\195\147"] = "o", ["\195\154"] = "u",
    ["\195\130"] = "a", ["\195\138"] = "e", ["\195\142"] = "i", ["\195\148"] = "o", ["\195\155"] = "u",
    ["\195\132"] = "a", ["\195\139"] = "e", ["\195\143"] = "i", ["\195\150"] = "o", ["\195\156"] = "u",
    ["\195\128"] = "a", ["\195\136"] = "e", ["\195\140"] = "i", ["\195\146"] = "o", ["\195\153"] = "u",
    ["\195\145"] = "n", ["\195\135"] = "c",
}

local function _fold(text)
    if type(text) ~= "string" then
        return ""
    end
    local t = string.lower(text)
    t = t:gsub("\195[\128-\191]", function(ch)
        return ACCENTS[ch] or ch
    end)
    t = t:gsub("[%-'`\226\128\153]", " ")
    t = t:gsub("[^%w ]", " ")
    t = t:gsub("%s+", " ")
    t = t:gsub("^ ", ""):gsub(" $", "")
    return t
end
ZoneBanner.fold = _fold

-- nombres en ingles y en espanol (los del cliente traducido), sin acentos
local KEYWORDS = {
    comarca = {
        "shire", "comarca", "bree", "old forest", "bosque viejo", "buckland", "los gamos", "yondershire",
        "archet", "hobbiton", "michel delving", "staddle", "combe", "chetwood", "bosque del chet",
        "barrow downs", "quebradas de los tumulos", "hobbitania",
    },
    elfico = {
        "lothlorien", "lorien", "caras galadhon", "eregion", "acebeda", "hollin", "trollshaws",
        "bosque de los trolls", "rivendell", "rivendel", "imladris", "ered luin", "falathlorn",
        "eryn lasgalen", "felegoth", "angle of mitheithel", "angulo del mitheithel", "mitheithel",
        "celondim", "duillond", "harlindon", "ost galadh",
    },
    arnor = {
        "evendim", "annuminas", "north downs", "quebradas del norte", "lone lands", "tierras solitarias",
        "cardolan", "weather hills", "colinas de los vientos", "fornost", "esteldin", "mossward", "musgovilla",
        "arnor", "tinnudir", "ost forod", "amon sul", "weathertop", "cima de los vientos",
    },
    hielo = {
        "forochel", "misty mountains", "montanas nubladas", "wildermore", "tierras feroces", "frostbluff",
        "suri kyla", "zigilgund", "helegrod", "ered mithrin", "grey mountains", "montanas grises",
        "risco helado", "tal methedras",
    },
    sombra = {
        "angmar", "carn dum", "ettenmoors", "landas de etten", "mirkwood", "bosque negro", "dol guldur",
        "mordor", "gorgoroth", "udun", "lhingris", "agarnaith", "talath urui", "dor amarth", "nurn",
        "the wastes", "tierras baldias", "morgul", "minas morgul", "torech ungol", "dead marshes",
        "cienaga de los muertos", "orodruin", "nargroth", "sammath naur", "isengard", "nan curunir",
        "paths of the dead", "caminos de los muertos", "barad dur", "cirith ungol", "mordor besieged",
        "mordor asediado", "imlad morgul", "tierras baldas", "wastes",
    },
    enano = {
        "moria", "khazad dum", "durin", "great delving", "gran excavacion", "silvertine", "cuerno de plata",
        "redhorn", "cuerno rojo", "foundations of stone", "fundaciones de piedra", "flaming deeps",
        "profundidades llameantes", "nud melek", "zelem melek", "zirakzigil", "walls of moria",
        "murallas de moria", "erebor", "iron hills", "colinas de hierro", "dwarf holds", "moradas enanas",
        "strongholds of the north", "fortalezas del norte", "gundabad", "elderslade", "valle ancestral",
        "azanulbizar", "thorin", "mansion de thorin", "the anvil", "el yunque", "mattugard", "deepscrave",
        "hendidura profunda", "clovengap", "pasohendido", "gloomingtarn", "lagosombrio", "welkin lofts",
        "dale", "glittering caves", "cavernas centelleantes",
    },
    rohan = {
        "rohan", "eastemnet", "westemnet", "emnet", "east rohan", "west rohan", "rohan oriental",
        "rohan occidental", "the wold", "el paramo", "norcrofts", "sutcrofts", "entwash", "entaguas",
        "eastfold", "folde este", "westfold", "folde oeste", "kingstead", "tierras del rey", "broadacres",
        "campos amplios", "stonedeans", "helm", "abismo de helm", "edoras", "snowbourn", "rio nevado",
        "harwick", "forlaw", "east wall", "muralla del este", "great river", "gran rio", "stangard",
        "gap of rohan", "paso de rohan", "croftlands", "wold", "folde",
    },
    gondor = {
        "gondor", "anorien", "osgiliath", "ithilien", "lebennin", "lossarnach", "belfalas", "anfalas",
        "pinnath gelin", "ringlo", "minas tirith", "pelennor", "pelargir", "dol amroth", "lamedon",
        "blackroot", "raiz negra", "dor en ernil", "talath anor", "beacon hills", "almenaras",
        "taur druadan", "march of the king", "marcha del rey", "havens of belfalas", "puertos de belfalas",
        "cape of belfalas", "cabo de belfalas", "emyn arnen", "cair andros",
    },
    salvajes = {
        "enedwaith", "dunland", "tierras brunas", "swanfleet", "cienaga de los cisnes", "fangorn",
        "entwood", "bosque de los ents", "vales of anduin", "valles del anduin", "anduin",
        "wells of langflood", "manantiales del langflood", "langflood", "wildwood", "bosque salvaje",
        "galtrev", "grimbeorn", "rhovanion", "lindes de fangorn", "eaves of fangorn", "minhiriath",
        "tharbad",
    },
    sur = {
        "umbar", "harad", "haradwaith", "near harad", "far harad", "baharbel", "ikorban", "ambarul",
        "khud zagin", "imhular", "furtherholm", "zir aktar", "mur ghala", "idagal", "emax dul",
        "an sheru", "kighan", "adagim", "hatokali", "cabo de umbar", "cape of umbar",
    },
}

-- lista (palabra, estilo) de la mas larga a la mas corta: "cienaga de los
-- cisnes" gana a "cienaga", "rohan oriental" a "rohan", etc.
local _keys = nil
local function _build_keys()
    _keys = {}
    for style, list in pairs(KEYWORDS) do
        for i = 1, #list do
            _keys[#_keys + 1] = { key = _fold(list[i]), style = style }
        end
    end
    table.sort(_keys, function(a, b)
        if string.len(a.key) ~= string.len(b.key) then
            return string.len(a.key) > string.len(b.key)
        end
        return a.key < b.key
    end)
end

-- palabra completa: "dale" no entra en "vandale", "valle" si en "valle
-- ancestral" pero no en "vallenar"
local function _find_word(text, key)
    local start = 1
    while true do
        local s, e = string.find(text, key, start, true)
        if s == nil then
            return false
        end
        local before = s == 1 or string.sub(text, s - 1, s - 1) == " "
        local after = e == string.len(text) or string.sub(text, e + 1, e + 1) == " "
        if before and after then
            return true
        end
        start = s + 1
    end
end

function ZoneBanner.style_for(zone_name)
    local folded = _fold(zone_name)
    if folded == "" then
        return "general"
    end
    if _keys == nil then
        _build_keys()
    end
    for i = 1, #_keys do
        if _find_word(folded, _keys[i].key) then
            return _keys[i].style
        end
    end
    return "general"
end

-- ---------------------------------------------------------------------
-- Aviso del canal Regional -> nombre de zona
-- ---------------------------------------------------------------------

local function _trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function _strip_markup(text)
    local t = text:gsub("<rgb=[^>]*>", ""):gsub("</rgb>", "")
    t = t:gsub("<[^>]*>", "")
    t = t:gsub("^%s*%[%d%d?[:/%.]%d%d?.-%]%s*", "")
    return t
end

-- palabras de la frase del aviso que van ANTES del nombre
local LEAD_WORDS = {
    ["has"] = true, ["ha"] = true, ["se"] = true, ["te"] = true, ["you"] = true, ["have"] = true,
    ["entered"] = true, ["entro"] = true, ["entrado"] = true, ["entras"] = true, ["joined"] = true,
    ["unido"] = true, ["unio"] = true, ["unes"] = true, ["en"] = true, ["al"] = true, ["a"] = true,
    ["to"] = true, ["into"] = true, ["del"] = true,
}
local CHANNEL_WORDS = { ["canal"] = true, ["channel"] = true }
-- verbos de ENTRADA (exactos; "Left"/"Salio"/"Has salido" no estan)
local ENTER_WORDS = {
    ["entered"] = true, ["joined"] = true, ["entro"] = true, ["entraste"] = true, ["entrado"] = true,
    ["entras"] = true, ["unido"] = true, ["unio"] = true, ["uniste"] = true,
}
local SUBJECT_WORDS = { ["has"] = true, ["te"] = true, ["se"] = true, ["you"] = true, ["ha"] = true }

-- palabra de la frase del aviso (no del nombre de la zona)
local function _is_notice_word(fw)
    return LEAD_WORDS[fw] == true or ENTER_WORDS[fw] == true or SUBJECT_WORDS[fw] == true
        or fw == "the" or fw == "el"
end

-- Devuelve el nombre de la zona si el mensaje es un aviso de ENTRADA al
-- canal Regional; nil para cualquier otro mensaje (incluido el de salida
-- y cualquier cosa escrita por un jugador: esas lineas empiezan con el
-- nombre del jugador o del canal, nunca con "Entered"/"Entro"/"Has").
function ZoneBanner.parse_regional(message)
    if type(message) ~= "string" then
        return nil
    end
    local plain = _strip_markup(message)
    local p = string.find(plain, " - Regional", 1, true)
    if p == nil then
        return nil
    end
    -- despues de " - Regional" solo puede venir nada, un punto o la palabra
    -- canal/channel: una linea de un jugador sigue con comillas u otro texto
    local tail = _fold(string.sub(plain, p + string.len(" - Regional")))
    if tail ~= "" and tail ~= "channel" and tail ~= "canal" then
        return nil
    end
    local head = _trim(string.sub(plain, 1, p - 1))
    local low = _fold(head)
    local first = low:match("^(%S+)")
    if first == nil then
        return nil
    end
    -- la frase empieza con "Entered"/"Entro"/... o "Has entrado"/"Te has
    -- unido"/"You have joined"; un nombre de jugador nunca pasa (palabras
    -- exactas, no prefijos)
    local entering = ENTER_WORDS[first] == true
    if not entering and SUBJECT_WORDS[first] == true then
        local second = low:match("^%S+ (%S+)") or ""
        local third = low:match("^%S+ %S+ (%S+)") or ""
        entering = ENTER_WORDS[second] == true or ENTER_WORDS[third] == true
    end
    if not entering then
        return nil
    end

    -- quita las palabras del aviso (en el texto ORIGINAL, para no perder
    -- acentos ni mayusculas del nombre). Despues de la primera palabra solo
    -- se quitan palabras en minuscula: "Al ...", "En ...", "The Shire"
    -- (nombres de zona) quedan enteros.
    local name = head
    local is_first = true
    local guard = 0
    while guard < 12 do
        guard = guard + 1
        local word, rest = name:match("^(%S+)%s+(.+)$")
        if word == nil then
            -- una sola palabra: si es parte del aviso, no hay nombre
            local fw = _fold(name)
            if _is_notice_word(fw) or CHANNEL_WORDS[fw] then
                name = ""
            end
            break
        end
        local fw = _fold(word)
        local lower = is_first or word == string.lower(word)
        if CHANNEL_WORDS[fw] then
            name = rest
            break
        elseif lower and _is_notice_word(fw) then
            name = rest
        else
            break
        end
        is_first = false
    end
    name = _trim((name:gsub("^[:%-%s'\"]+", "")))
    name = (name:gsub("['\"%.:,;%s]+$", ""))
    if name == "" or string.len(name) > 60 then
        return nil
    end
    -- primera letra en mayuscula (solo ASCII; las acentuadas quedan igual)
    name = (name:gsub("^%l", string.upper))
    return name
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

local function _size_setting()
    local size = tonumber(_settings().zone_banner_size) or DEFAULT_SIZE
    local best = DEFAULT_SIZE
    for i = 1, #ZoneBanner.SIZES do
        if math.abs(ZoneBanner.SIZES[i] - size) < math.abs(best - size) then
            best = ZoneBanner.SIZES[i]
        end
    end
    return best
end

local function _estimate_width(text, size)
    local fn = LUI.Utils.lui_timed_row_estimate_text_width
    if fn ~= nil then
        local ok, w = pcall(fn, text, "TrajanPro", size)
        if ok == true and type(w) == "number" then
            return w
        end
    end
    return string.len(text) * size * 0.75
end

local function _fit_font(text, panel_w, panel_h)
    local max_by_height = math.floor(panel_h * 0.95)
    for i = 1, #TRAJAN_SIZES do
        local size = TRAJAN_SIZES[i]
        if size <= max_by_height and _estimate_width(text, size) <= panel_w * 0.94 then
            return size
        end
    end
    return TRAJAN_SIZES[#TRAJAN_SIZES]
end

local ZoneBannerWindow = class(UI.Widgets.LuiBaseWindow)
ZoneBanner.ZoneBannerWindow = ZoneBannerWindow

function ZoneBannerWindow:Constructor()
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
    self.shine:SetVisible(false)
    self.sparks = {}

    self.style = nil
    self.size = nil
    self.zone = nil
    self.layout = nil
    self.shown_at = 0
    self.last_frame = 0
    self.display_w = nil
    self.display_check_at = 0
    self:SetWantsUpdates(true)
end

function ZoneBannerWindow:_ensure_sparks(count)
    for i = #self.sparks + 1, count do
        self.sparks[i] = _layer(self)
        self.sparks[i]:SetVisible(false)
    end
    for i = 1, #self.sparks do
        self.sparks[i]:SetVisible(false)
    end
end

-- estilo + tamano -> imagenes, medidas y posicion
function ZoneBannerWindow:_build(style, size)
    local def = ZoneBanner.STYLES[style] or ZoneBanner.STYLES.general
    local L = def.sizes[size] or def.sizes[DEFAULT_SIZE]
    local base = ASSET_DIR .. "zb_" .. style .. "_"
    UI.NativeScaling.disable(self)

    self.style = style
    self.size = size
    self.layout = L

    local pad = L.pad
    self:SetSize(L.w + (2 * pad), L.h + (2 * pad))
    self.aura:SetBackground(base .. "aura_" .. tostring(size) .. ".tga")
    self.aura:SetPosition(0, 0)
    self.aura:SetSize(L.w + (2 * pad), L.h + (2 * pad))
    self.image:SetBackground(base .. tostring(size) .. ".tga")
    self.image:SetPosition(pad, pad)
    self.image:SetSize(L.w, L.h)

    local px, py, pw, ph = L.panel[1], L.panel[2], L.panel[3], L.panel[4]
    -- el texto se centra en el recuadro; la etiqueta es 8 px mas alta para
    -- que ninguna letra quede recortada arriba o abajo
    self.label:SetPosition(pad + px, pad + py - 4)
    self.label:SetSize(pw, ph + 8)
    self.label:SetForeColor(Turbine.UI.Color(1, def.text[1] / 255, def.text[2] / 255, def.text[3] / 255))

    local sh = ZoneBanner.SHINE[size]
    self.clip:SetPosition(pad + px, pad + py)
    self.clip:SetSize(pw, ph)
    self.shine:SetBackground(ASSET_DIR .. "zb_brillo_" .. tostring(size) .. ".tga")
    self.shine:SetSize(sh.w, sh.h)
    self.shine:SetPosition(-sh.w, math.floor((ph - sh.h) / 2))
    self.shine_w = sh.w
    self.shine_h = sh.h

    self:_ensure_sparks(#L.sparks)
    local half = math.floor(L.spark / 2)
    for i = 1, #L.sparks do
        local s = self.sparks[i]
        s:SetBackground(base .. "chispa_" .. tostring(size) .. ".tga")
        s:SetSize(L.spark, L.spark)
        s:SetPosition(pad + L.sparks[i][1] - half, pad + L.sparks[i][2] - half)
    end

    self:_place()
end

function ZoneBannerWindow:_place()
    local L = self.layout
    if L == nil then
        return
    end
    local display_w = Turbine.UI.Display.GetWidth()
    self.display_w = display_w
    local x = math.floor((display_w - L.w) / 2) - L.pad
    self:SetPosition(x, TOP_Y - L.pad)
end

function ZoneBannerWindow:_set_text(text)
    local L = self.layout
    if L == nil then
        return
    end
    local size = _fit_font(text, L.panel[3], L.panel[4])
    local font = LUI.Utils.FONT_TO_LOTRO("TrajanPro", size)
    if font ~= nil then
        self.label:SetFont(font)
    end
    self.label:SetText(text)
end

-- zona nueva (o cambio de tamano/estilo): arma y hace aparecer el cartel
function ZoneBannerWindow:show_zone(zone, style, fade)
    local size = _size_setting()
    if style ~= self.style or size ~= self.size then
        self:_build(style, size)
    end
    self.zone = zone
    self:_set_text(zone)
    if fade == true then
        self.shown_at = Turbine.Engine.GetGameTime()
    else
        self.shown_at = -1000
    end
    self.last_frame = 0
    self:_animate(Turbine.Engine.GetGameTime())
    self:SetVisible(true)
end

function ZoneBannerWindow:_animate(now)
    local animate = _settings().zone_animations ~= false
    local appear = 1
    if self.shown_at > 0 then
        appear = (now - self.shown_at) / FADE_IN
        if appear < 0 then appear = 0 elseif appear > 1 then appear = 1 end
    end

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

    -- destello que cruza el recuadro del nombre
    local L = self.layout
    local phase = now % SHINE_EVERY
    if phase <= SHINE_TIME and L ~= nil then
        local t = phase / SHINE_TIME
        local x = math.floor(-self.shine_w + ((L.panel[3] + self.shine_w) * t))
        self.shine:SetPosition(x, math.floor((L.panel[4] - self.shine_h) / 2))
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

function ZoneBannerWindow:Update()
    local now = Turbine.Engine.GetGameTime()
    if now - self.last_frame < FRAME_TIME then
        return
    end
    self.last_frame = now
    if now >= self.display_check_at then
        self.display_check_at = now + 1
        if Turbine.UI.Display.GetWidth() ~= self.display_w then
            self:_place()
        end
    end
    if self:IsVisible() == true then
        self:_animate(now)
    end
    ZoneBanner._tick(now)
end

function ZoneBannerWindow:destroy()
    self:SetWantsUpdates(false)
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

-- ---------------------------------------------------------------------
-- Estado, chat, guardado y barra de estado
-- ---------------------------------------------------------------------

ZoneBanner.current_zone = ZoneBanner.current_zone or nil
local _chat_handle = nil
local _loaded = false
local _load_requested = false
local _load_at = nil
local _demo = nil

local function _enabled()
    return _settings().zone_banner ~= false
end

local function _tint_enabled()
    return _settings().zone_tint ~= false
end

-- color de la barra de estado segun el estilo (nil = el color normal)
local function _apply_tint(style)
    local bar = Windows.status_bar
    if bar == nil or bar.set_zone_tint == nil then
        return
    end
    if style == nil or _enabled() ~= true or _tint_enabled() ~= true then
        pcall(bar.set_zone_tint, bar, nil)
        return
    end
    local def = ZoneBanner.STYLES[style] or ZoneBanner.STYLES.general
    pcall(bar.set_zone_tint, bar, def.bar, def.text)
end

local function _refresh(fade)
    local zone = ZoneBanner.current_zone
    local style = nil
    if _demo ~= nil then
        zone = _demo.zone
        style = _demo.style
    elseif zone ~= nil then
        style = ZoneBanner.style_for(zone)
    end

    local win = Windows.zone_banner
    if win ~= nil then
        if zone ~= nil and _enabled() == true then
            win:show_zone(zone, style, fade)
        else
            win:SetVisible(false)
        end
    end
    _apply_tint(zone ~= nil and style or nil)
end

local function _save()
    local zone = ZoneBanner.current_zone
    if type(zone) ~= "string" then
        return
    end
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Character, DATA_KEY, { zone = zone })
end

function ZoneBanner.set_zone(zone, save)
    if type(zone) ~= "string" or zone == "" then
        return
    end
    local changed = zone ~= ZoneBanner.current_zone
    ZoneBanner.current_zone = zone
    _loaded = true -- una zona real gana a la guardada
    if changed then
        _refresh(true)
        if save ~= false then
            _save()
        end
    end
end

local function _on_chat(_, args)
    if args == nil or type(args.Message) ~= "string" then
        return
    end
    if string.find(args.Message, "Regional", 1, true) == nil then
        return
    end
    local ok, zone = pcall(ZoneBanner.parse_regional, args.Message)
    if ok == true and zone ~= nil then
        ZoneBanner.set_zone(zone, true)
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

-- la zona guardada se lee con callback, unos segundos despues de entrar
-- (nunca junto con las cargas de ajustes de LUI)
local function _request_load()
    if _load_requested == true then
        return
    end
    _load_requested = true
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Character, DATA_KEY, function(data)
        if _loaded == true then
            return
        end
        _loaded = true
        if type(data) == "table" and type(data.zone) == "string" and data.zone ~= "" then
            ZoneBanner.current_zone = data.zone
            _refresh(true)
        end
    end)
end

-- "/lui zona demo": muestra los 11 estilos, 3 s cada uno
local DEMO_NAMES = {
    general = "Tierra Media", comarca = "La Comarca", elfico = "Lothl\195\179rien",
    arnor = "Quebradas del Norte", hielo = "Forochel", sombra = "Angmar", enano = "Moria",
    rohan = "Folde Oeste", gondor = "Gondor Central", salvajes = "Tierras Brunas", sur = "Umbar",
}

function ZoneBanner._tick(now)
    if _load_requested ~= true and _load_at ~= nil and now >= _load_at then
        _request_load()
    end
    if _demo ~= nil and now >= _demo.next_at then
        _demo.index = _demo.index + 1
        local style = ZoneBanner.STYLE_ORDER[_demo.index]
        if style == nil then
            _demo = nil
            _refresh(true)
            return
        end
        _demo.style = style
        _demo.zone = DEMO_NAMES[style] or style
        _demo.next_at = now + 3
        _refresh(true)
    end
end

function ZoneBanner.start_demo()
    if Windows.zone_banner == nil then
        return false
    end
    _demo = { index = 0, next_at = 0 }
    ZoneBanner._tick(Turbine.Engine.GetGameTime())
    return true
end

-- crea / quita / reajusta el cartel segun Opciones (se llama tambien cada
-- vez que se rehace la barra de estado, para volver a tenirla)
-- La ventana se rehace siempre DESPUES de la barra de estado, asi queda
-- por encima de ella (la barra se rehace entera al guardar Opciones).
function Apply.zone_banner_settings()
    if Windows.zone_banner ~= nil then
        Windows.zone_banner:destroy()
        Windows.zone_banner = nil
    end
    if _enabled() == true then
        Windows.zone_banner = ZoneBannerWindow()
        if _load_at == nil then
            _load_at = Turbine.Engine.GetGameTime() + 5
        end
    else
        _demo = nil
    end
    -- el chat escucha aunque el cartel este apagado: al prenderlo ya se
    -- sabe la zona
    _install_chat()
    _refresh(false)
end

function ZoneBanner.shutdown()
    _uninstall_chat()
    _demo = nil
    if Windows.zone_banner ~= nil then
        Windows.zone_banner:destroy()
        Windows.zone_banner = nil
    end
end

function ZoneBanner.describe()
    local zone = ZoneBanner.current_zone
    if zone == nil then
        return nil, nil
    end
    return zone, ZoneBanner.style_for(zone)
end
