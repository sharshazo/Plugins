-- WorldMap_Addon/worldmap_zonemap.lua
--
-- v3.1.1 (pedido del usuario, con capturas reales del juego): el MAPA DE LA
-- ZONA ya no es una ventana aparte. Va DENTRO de la ventana del Mapa del
-- Mundo, en el mismo recuadro del mapa (el viewport):
--   * clic en una zona del mapa del mundo -> se cambia a su mapa de zona
--     (y al lado se abre la lista de misiones, como antes);
--   * clic en el nombre de un mapa vecino ("hacia las Tierras de Bree"...)
--     -> se viaja a ese mapa, igual que en MoorMap (conectores tipo 41/51/52
--     de MoorMap, mismos datos);
--   * clic derecho -> vuelve al mapa anterior y, desde el primero, al mapa
--     del mundo (MoorMap usa el clic derecho para "subir" de mapa).
-- Con esto se arreglan los 3 errores de la v3.1: la ventana de zona dejaba
-- ver el mapa del mundo detras (fila de arriba transparente), se salia del
-- area del mapa del mundo, y el cartel de zona del mapa del mundo aparecia
-- al pasar el mouse por el mapa de la zona (el mapa del mundo seguia
-- "debajo" detectando el mouse; ahora no detecta nada mientras se ve una
-- zona).
--
-- La imagen de cada mapa es la del propio cliente del juego (numero de
-- recurso, igual que MoorMap: pcall(SetBackground, ctl, numero)), sale en el
-- idioma del cliente. Encima van los iconos con su aura que se mueve:
-- ciudad grande, incursion, mazmorra, establo, cofre y elite; al pasar el
-- mouse se resaltan y sale su cartel (cofre: solo resaltado). Ningun icono
-- queda a menos de 16 px del borde del mapa (no sobresale).
--
-- Mismos mecanismos ya probados en worldmap.lua: viewport + contenido a
-- tamaño nativo que se arrastra (pan), sin escalar; auras = cuadros TGA que
-- se cambian; cartel = Window sin chrome + Control solido; hover por poll.
-- Todo lo que toca la API va en pcall: si algo fallara, el mapa del mundo
-- sigue funcionando igual.
--
-- v3.2 (pedido del usuario): boton "Filtros" en la barra de arriba -> panel
-- "Filtros del Mapa" (worldmap_filters.lua). Iconos nuevos del usuario y
-- capas nuevas (worldmap_layers_data.lua): exploracion, hazanas, matar
-- monstruos, campamentos, puntos de viaje, NPC, mineria, pesca, fauna,
-- historia y saber, tablones de tareas. Cada icono nuevo tiene una punta
-- abajo: la punta queda en el lugar exacto.

import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WorldMapAddon = _G.WorldMapAddon or {}
WorldMapAddon.UI = WorldMapAddon.UI or {}

local ZD = WorldMapAddon.ZoneMapsData

local RES = "WorldMap_Addon/assets/worldmap/icon/"
local BORDER_HEX = "#C9A66B"
local VIEW_BG_HEX = "#141005"
local BAR_H = 26 -- barra de arriba: volver, < mapa (1/7) >, ayuda
local FX_FRAMES = 12
local FX_FPS = 8
local TIP_W = 300
local TIP_PAD = 10
local TIP_TITLE_H = 20
local TIP_LINE_H = 15
local LINK_W, LINK_H = 150, 40 -- zona clickeable sobre el nombre del mapa vecino
-- v3.1.2: fondo 100% transparente (igual que MoorMap: MapConnector_blank.tga).
-- En LOTRO un Control sin fondo no siempre recibe el mouse; con una imagen
-- transparente si, sin tapar nada del mapa.
local LINK_BLANK = "WorldMap_Addon/assets/worldmap/icon/zm_link_blank.tga"
local DRAG_SLOP = 4

-- dibujo de cada tipo: icono (w x h, centrado en el punto), aura (cuadros
-- animados) y resaltado (mismo tamaño y lugar que el aura)
-- v3.2 (pedido del usuario): incursion, mazmorra, establo, cofre y elite
-- usan los iconos NUEVOS del usuario (carpeta datos/Iconos), con su aura de
-- siempre detras. Esos iconos tienen una punta abajo: la PUNTA (tx, ty)
-- queda exactamente en el lugar (antes el centro del icono). hlIcon = el
-- resaltado es el mismo icono iluminado (mismo tamano y lugar que el
-- icono). filter = cuadro del panel "Filtros del Mapa" que lo muestra.
local KIND = {
    t = { img = "fl_cofre_24.tga", w = 24, h = 24, tx = 12, ty = 22, aura = "zm_cofre_aura_", aw = 36, ah = 31, ax = -6, ay = -5, hl = "fl_cofre_24_hl.tga", hlIcon = true, filter = "cof" },
    s = { img = "fl_establo_blanco_26.tga", w = 26, h = 26, tx = 13, ty = 25, aura = "zm_establo_aura_", aw = 40, ah = 38, ax = -7, ay = -6, hl = "fl_establo_blanco_26_hl.tga", hlIcon = true, filter = "esb", noAura = true,
          farImg = "fl_establo_azul_26.tga", farHl = "fl_establo_azul_26_hl.tga", farFilter = "esa" },
    e = { img = "fl_jefe_28.tga", w = 28, h = 28, tx = 13, ty = 27, aura = "zm_elite_aura_", aw = 44, ah = 42, ax = -8, ay = -7, hl = "fl_jefe_28_hl.tga", hlIcon = true, filter = "jef" },
    d = { img = "fl_mazmorra_28.tga", w = 28, h = 28, tx = 14, ty = 27, aura = "puerta_aura_", aw = 44, ah = 44, ax = -8, ay = -8, hl = "fl_mazmorra_28_hl.tga", hlIcon = true, filter = "maz", auraIfQuest = true },
    r = { img = "fl_raid_30.tga", w = 30, h = 30, tx = 15, ty = 29, aura = "calavera_fuego_", aw = 46, ah = 52, ax = -8, ay = -18, hl = "fl_raid_30_hl.tga", hlIcon = true, filter = "raid", auraIfQuest = true },
    c = { img = "zm_ciudad.tga", w = 32, h = 30, aura = "zm_ciudad_aura_", aw = 48, ah = 46, ax = -8, ay = -10, hl = "zm_ciudad_hl.tga" },
}
-- orden de dibujo: lo primero queda debajo (las ciudades arriba de todo)
local KIND_ORDER = { "t", "s", "e", "d", "r", "c" }

-- v3.1.3 (pedido del jugador): flecha dorada animada encima de cada
-- mazmorra / incursion donde tiene misiones activas, con el numero. Mismas
-- imagenes que las flechas del mapa del mundo (flecha_mision + su aura).
local QARROW = { img = "flecha_mision.tga", w = 24, h = 30, aura = "flecha_aura_", aw = 40, ah = 46, adx = -8, ady = -14 }
local QARROW_KINDS = { d = true, r = true }
local QARROW_GAP = 6        -- px entre la flecha y el icono
local QARROW_BOB = 4        -- px que sube y baja
local QARROW_PERIOD = 1.2   -- s por subida y bajada
local QARROW_REFRESH = 3    -- s entre recuentos de misiones

-- v3.2: capas del panel "Filtros del Mapa" (worldmap_layers_data.lua):
-- icono 24x24 con la punta abajo; la punta va en el punto (x, y).
local LAYER_W, LAYER_H = 24, 24
local LAYER_TIP = {
    campamento = { 11, 23 }, cofre = { 12, 22 }, establo_azul = { 12, 23 }, establo_blanco = { 12, 22 },
    exploracion = { 12, 23 }, fauna = { 12, 22 }, hazana = { 11, 23 }, historia = { 12, 23 }, jefe = { 12, 23 },
    mazmorra = { 12, 22 }, mineria = { 12, 23 }, mision = { 12, 23 }, mobs = { 12, 23 }, npc = { 12, 23 },
    pesca = { 12, 22 }, raid = { 12, 23 }, viaje = { 12, 23 },
}
local LAYER_MAX_LINES = 8
-- v3.4: capas cuyos iconos son de una hazaña (los muestra tambien "Hazañas")
local DEED_LAYERS = { exp = true, haz = true, mob = true, cof = true }
-- v3.3: aura de "activa" (40x40, centrada en el icono), aura de mision en
-- incursion / mazmorra (60x60), misiones activas (pines) y su estado
local AURA_W, AURA_H, AURA_MAX = 40, 40, 90
local QRING_W, QRING_H = 60, 60
local QPIN_MAX = 40
local STATUS_REFRESH = 3      -- s entre repasos del estado de hazañas / misiones
local COVER_TOL = 0.4         -- tolerancia de los limites del dibujo (como build3)

local function Filters()
    return WorldMapAddon.Filters
end

-- filtro (cuadro del panel) de un icono de los de siempre
local function KindFilter(p)
    local spec = KIND[p[1]]
    if spec == nil then
        return nil
    end
    if spec.farFilter ~= nil and p[6] == "far" then
        return spec.farFilter
    end
    return spec.filter
end

local function FilterOn(key)
    if key == nil then
        return true
    end
    local F = Filters()
    if F == nil or F.IsOn == nil then
        return true
    end
    local ok, on = pcall(F.IsOn, key)
    if not ok then
        return true
    end
    return on
end

local DIFF_ES = {
    ["Elite"] = "\195\137lite", ["Great Elite"] = "Gran \195\169lite", ["Signature"] = "Distintivo",
    ["Nemesis"] = "N\195\169mesis", ["Supreme Nemesis"] = "N\195\169mesis supremo",
}

local function HexToColor(hex, alpha)
    local r = tonumber(hex:sub(2, 3), 16) / 255
    local g = tonumber(hex:sub(4, 5), 16) / 255
    local b = tonumber(hex:sub(6, 7), 16) / 255
    if alpha then
        return Turbine.UI.Color(alpha, r, g, b) -- (a, r, g, b): orden real de la API
    end
    return Turbine.UI.Color(r, g, b)
end

-- idioma: el de Quest Assistant (su boton ES/EN); sin Quest Assistant,
-- español (el idioma de este addon)
local function IsES()
    local ok, es = pcall(function()
        local LS = _G.LanguageSettings
        if LS == nil or LS.IsSpanish == nil then
            return true
        end
        return LS.IsSpanish() == true
    end)
    if not ok then
        return true
    end
    return es
end

local function Split(text)
    local out = {}
    for part in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        out[#out + 1] = part
    end
    return out
end

-- renglones aproximados de un texto en Verdana12 (~6.6 px por letra)
local function TipLines(text, w)
    -- v3.8: se simula el corte por palabras (los textos largos de saber
    -- cortaban la ultima linea si solo se contaban letras)
    local perLine = math.max(1, math.floor(w / 6.9))
    local lines, cur = 1, 0
    for word in tostring(text or ""):gmatch("%S+") do
        local n = 0
        for _ in word:gmatch("[^\128-\191]") do
            n = n + 1
        end
        if cur == 0 then
            cur = n
        elseif cur + 1 + n <= perLine then
            cur = cur + 1 + n
        else
            lines = lines + 1
            cur = n
        end
        while cur > perLine do
            lines = lines + 1
            cur = cur - perLine
        end
    end
    return lines
end

-- v3.5: nombre español oficial cuando el dato no lo traia
-- (worldmap_names_es.lua); si no hay traduccion, el mismo nombre
local function NameES(en)
    local T = WorldMapAddon.NameES
    if type(T) == "table" and en ~= nil and T[en] ~= nil then
        return T[en]
    end
    return en
end

-- titulo y renglones del cartel de un icono (nil = sin cartel: cofres)
local function TipFor(p, es)
    local kind = p[1]
    local en, esn, extra = p[4] or "", p[5] or "", p[6] or ""
    if esn == "" then
        esn = en
    end
    local ens, ess = Split(en), Split(esn)
    for i, e in ipairs(ens) do
        if ess[i] == nil or ess[i] == "" or ess[i] == e then
            ess[i] = NameES(e)
        end
    end
    if kind == "t" then
        return nil
    elseif kind == "r" or kind == "d" then
        local title
        if kind == "r" then
            title = es and "Incursi\195\179n (Raid)" or "Raid (Incursi\195\179n)"
        else
            title = es and "Mazmorra (Dungeon)" or "Dungeon (Mazmorra)"
        end
        local lines = {}
        for i, e in ipairs(ens) do
            local s = ess[i] or e
            local first, second = s, e
            if not es then
                first, second = e, s
            end
            if first == second then
                lines[#lines + 1] = first
            else
                lines[#lines + 1] = first .. " (" .. second .. ")"
            end
        end
        return title, lines
    elseif kind == "c" then
        local name = es and ess[1] or ens[1]
        return name, { es and "Ciudad" or "City" }
    elseif kind == "s" then
        local title = es and "Establo" or "Stable-master"
        if extra == "far" then
            title = es and "Establo de largo alcance" or "Far-ranging Stable-master"
        end
        local place = es and ess[1] or ens[1]
        if place == nil or place == "" then
            return title, {}
        end
        return title, { place }
    elseif kind == "e" then
        local infos = Split(extra)
        local lines = {}
        for i, name in ipairs(ens) do
            local diff, lvl = tostring(infos[i] or infos[1] or ""):match("^(.-)|(.*)$")
            local txt = es and (ess[i] or name) or name
            local det = {}
            if diff ~= nil and diff ~= "" then
                det[#det + 1] = es and (DIFF_ES[diff] or diff) or diff
            end
            if lvl ~= nil and lvl ~= "" then
                det[#det + 1] = (es and "nivel " or "level ") .. lvl
            end
            if #det > 0 then
                txt = txt .. " - " .. table.concat(det, ", ")
            end
            lines[#lines + 1] = txt
        end
        return es and "\195\137lite" or "Elite", lines
    end
    return nil
end

-- cartel de un icono de capa: { capa, x, y, nombresEN, nombresES, detalleEN, detalleES }
local function LayerTip(p, es)
    local F = Filters()
    local key = p[1]
    local t = F ~= nil and F.Title ~= nil and F.Title[key] or nil
    local title = t ~= nil and (es and t.es or t.en) or key
    local ens, ess = Split(p[4]), Split(p[5])
    local sens, sess = Split(p[6]), Split(p[7])
    local lines = {}
    for i, en in ipairs(ens) do
        if i > LAYER_MAX_LINES then
            local rest = #ens - LAYER_MAX_LINES
            lines[#lines + 1] = es and ("... y " .. rest .. " m\195\161s") or ("... and " .. rest .. " more")
            break
        end
        local esn = ess[i]
        if esn == nil or esn == "" or esn == en then
            esn = NameES(en)
        end
        local first, second = esn, en
        if not es then
            first, second = en, esn
        end
        local line = first
        if second ~= "" and second ~= first then
            line = first .. " (" .. second .. ")"
        end
        local sen = sens[i] or ""
        local ses = sess[i] or ""
        if ses == "" or ses == sen then
            ses = NameES(sen)
        end
        local sub = es and ses or sen
        if sub ~= "" and sub ~= first then
            line = line .. " - " .. sub
        end
        if line ~= "" then
            lines[#lines + 1] = line
        end
    end
    return title, lines
end

-- v3.8 (pedido del jugador): mas informacion de hazañas y lugares en el
-- cartel, tomada de Deed Tracker (worldmap_deedinfo_data.lua, generado de
-- sus DataFiles): saber del lugar, hazaña, tipo, nivel, recompensas,
-- titulo y objetivo. Sin ese archivo el cartel queda como antes.
local DEED_TYPE = {
    [100] = { "Clase", "Class" }, [101] = { "Raza", "Race" }, [102] = { "Evento", "Event" },
    [103] = { "Explorador", "Explorer" }, [104] = { "Saber", "Lore" },
    [105] = { "Reputaci\195\179n", "Reputation" }, [106] = { "Matanza", "Slayer" },
}
local DINFO_MAX = 2
local DOT = " \194\183 "
-- igual que WorldMapAddon.DeedActive.Norm (las claves del archivo se hicieron asi)
local function InfoNorm(text)
    local s = tostring(text or "")
    s = s:gsub("<[^>]*>", " ")
    s = s:gsub("[A-Z]", function(c) return c:lower() end)
    s = s:gsub("[^a-z0-9\128-\255]", " ")
    s = s:gsub("%s+", " ")
    s = s:gsub("^ ", ""):gsub(" $", "")
    return s
end
local function Thousands(n, es)
    local s = tostring(math.floor(tonumber(n) or 0))
    local sep = es and "." or ","
    local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
    return (out:gsub("^%" .. sep, ""))
end
local function DeedInfoLines(p, es)
    local out = {}
    local I = WorldMapAddon.DeedInfo
    if type(I) ~= "table" or type(I.D) ~= "table" or p == nil then
        return out
    end
    local function pick(a, b)
        if es then
            return (a ~= nil and a ~= "") and a or (b or "")
        end
        return (b ~= nil and b ~= "") and b or (a or "")
    end
    -- el lugar (objetivo de una hazaña) por su nombre
    local placeId, place = nil, nil
    local names = {}
    for _, n in ipairs(Split(p[4])) do names[#names + 1] = n end
    for _, n in ipairs(Split(p[5])) do names[#names + 1] = n end
    for _, n in ipairs(names) do
        local hit = type(I.N) == "table" and I.N[InfoNorm(n)] or nil
        if hit ~= nil then
            local a, b = hit:match("^(%d+):(%d+)$")
            local objs = I.O ~= nil and I.O[tonumber(a)] or nil
            if objs ~= nil and objs[tonumber(b)] ~= nil then
                placeId, place = tonumber(a), objs[tonumber(b)]
                break
            end
        end
    end
    -- hazañas del icono (las del dato; si no trae, la del lugar)
    local ids, seen = {}, {}
    for _, k in ipairs(Split(p[8] or "")) do
        local id = tonumber(k:match("^(%d+)") or "")
        if id ~= nil and I.D[id] ~= nil and not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end
    if #ids == 0 and placeId ~= nil and I.D[placeId] ~= nil then
        ids[1] = placeId
    end
    -- el lugar dentro de las hazañas del propio icono (nombres repetidos)
    if place == nil and I.O ~= nil then
        local want = {}
        for _, n in ipairs(names) do want[InfoNorm(n)] = true end
        for _, id in ipairs(ids) do
            for _, o in ipairs(I.O[id] or {}) do
                if place == nil and (want[InfoNorm(o[1])] or want[InfoNorm(o[2])]) then
                    placeId, place = id, o
                end
            end
        end
    end
    if #ids == 0 then
        return out
    end
    local loreShown = false
    if place ~= nil and (placeId == ids[1] or seen[placeId]) then
        local lore = pick(place[3], place[4])
        if lore ~= "" then
            out[#out + 1] = "\"" .. lore .. "\""
            loreShown = true
        end
    end
    for i, id in ipairs(ids) do
        if i > DINFO_MAX then
            out[#out + 1] = es and ("... y " .. (#ids - DINFO_MAX) .. " haza\195\177as m\195\161s") or ("... and " .. (#ids - DINFO_MAX) .. " more deeds")
            break
        end
        local d = I.D[id]
        local head = (es and "Haza\195\177a: " or "Deed: ") .. pick(d[1], d[2])
        local extra = {}
        local tp = DEED_TYPE[tonumber(d[3]) or 0]
        if tp ~= nil then extra[#extra + 1] = es and tp[1] or tp[2] end
        if (tonumber(d[4]) or 0) > 0 then extra[#extra + 1] = (es and "nivel " or "level ") .. d[4] end
        if #extra > 0 then head = head .. " (" .. table.concat(extra, ", ") .. ")" end
        out[#out + 1] = head
        local rw = {}
        if (tonumber(d[5]) or 0) > 0 then rw[#rw + 1] = Thousands(d[5], es) .. (es and " XP de virtud" or " virtue XP") end
        if (tonumber(d[6]) or 0) > 0 then rw[#rw + 1] = d[6] .. (es and " puntos LOTRO" or " LOTRO points") end
        if (tonumber(d[7]) or 0) > 0 then
            local fac = pick(d[8], d[12])
            rw[#rw + 1] = "+" .. Thousands(d[7], es) .. " " .. ((fac ~= "") and fac or (es and "reputaci\195\179n" or "reputation"))
        end
        if #rw > 0 then out[#out + 1] = (es and "Recompensas: " or "Rewards: ") .. table.concat(rw, DOT) end
        local title = pick(d[9], d[13])
        if title ~= "" then out[#out + 1] = (es and "T\195\173tulo: " or "Title: ") .. title end
        local objs = I.O ~= nil and I.O[id] or nil
        if objs ~= nil and #objs > 0 then
            if tonumber(d[3]) == 106 or #objs == 1 then
                out[#out + 1] = (es and "Objetivo: " or "Objective: ") .. pick(objs[1][1], objs[1][2])
            else
                out[#out + 1] = (es and "Objetivos: " or "Objectives: ") .. #objs
            end
        end
        if i == 1 and not loreShown then
            local lore = pick(d[10], d[11])
            if lore ~= "" then
                out[#out + 1] = "\"" .. lore .. "\""
                loreShown = true
            end
        end
    end
    out[#out + 1] = es and "(informaci\195\179n de Deed Tracker)" or "(info from Deed Tracker)"
    return out
end
WorldMapAddon.DeedInfoLines = DeedInfoLines

-- ---------------------------------------------------------------------
-- Vista de mapa de zona (vive dentro del viewport del Mapa del Mundo)
-- ---------------------------------------------------------------------
local ZV = {}
ZV.__index = ZV
WorldMapAddon.UI.ZoneView = ZV

local function IsRight(args)
    return args ~= nil and args.Button == Turbine.UI.MouseButton.Right
end

local function IsLeft(args)
    return args == nil or args.Button == nil or args.Button == Turbine.UI.MouseButton.Left
end

function ZV.New(owner, viewport)
    local self = setmetatable({}, ZV)
    self.owner = owner
    self.viewport = viewport
    self.active = false
    self.zone = false
    self.mapId = false
    self.history = {}
    self.panX, self.panY = 0, BAR_H
    self.mapW, self.mapH = 1024, 768
    self.lang = IsES()
    self.tipOn = false
    self.tipCtrl = false
    self.hoverItem = false
    self.hoverLink = false
    self.fx = { last = 0, broken = false }
    self.pool = {}
    self.layerPool = {}
    self.linkPool = {}
    self.mapOk = false
    self.dragging = false
    self.dragMoved = false

    local this = self

    -- todo cuelga de "root" (mismo tamaño que el viewport): se muestra u
    -- oculta entero. root no recibe el mouse; sus hijos si (igual que
    -- mapViewport / mapContent en worldmap.lua).
    self.root = Turbine.UI.Control()
    self.root:SetParent(viewport)
    self.root:SetPosition(0, 0)
    self.root:SetMouseVisible(false)
    self.root:SetVisible(false)

    -- fondo solido: nunca se ve el mapa del mundo detras
    self.bg = Turbine.UI.Control()
    self.bg:SetParent(self.root)
    self.bg:SetPosition(0, 0)
    self.bg:SetBackColor(HexToColor(VIEW_BG_HEX))
    self.bg:SetMouseVisible(false)

    self.content = Turbine.UI.Control()
    self.content:SetParent(self.root)
    self.content:SetPosition(0, BAR_H)
    self.content:SetSize(self.mapW, self.mapH)

    self.mapImage = Turbine.UI.Control()
    self.mapImage:SetParent(self.content)
    self.mapImage:SetPosition(0, 0)
    self.mapImage:SetSize(self.mapW, self.mapH)
    self.mapImage:SetMouseVisible(false)

    -- orden de dibujo: conectores debajo, iconos encima
    self:_buildLinks()
    self:_buildPools()

    self.noMap = Turbine.UI.Label()
    self.noMap:SetParent(self.root)
    self.noMap:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
    self.noMap:SetForeColor(HexToColor("#F0D9A0"))
    self.noMap:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.noMap:SetMouseVisible(false)
    self.noMap:SetVisible(false)

    -- barra de arriba (encima del mapa)
    self.bar = Turbine.UI.Control()
    self.bar:SetParent(self.root)
    self.bar:SetPosition(0, 0)
    self.bar:SetBackColor(Turbine.UI.Color(1, 0.07, 0.06, 0.03))
    self.bar:SetMouseVisible(true)
    self.bar.MouseClick = function(sender, args)
        if IsRight(args) then
            this:Back()
        end
    end
    local function barLabel(font, color, align)
        local l = Turbine.UI.Label()
        l:SetParent(self.bar)
        l:SetFont(font)
        l:SetForeColor(HexToColor(color))
        l:SetTextAlignment(align)
        l:SetSelectable(false)
        l:SetMouseVisible(false)
        return l
    end
    local function barButton(text)
        local b = barLabel(Turbine.UI.Lotro.Font.Verdana12, BORDER_HEX, Turbine.UI.ContentAlignment.MiddleCenter)
        b:SetText(text)
        b:SetBackColor(HexToColor("#2A2418"))
        b:SetMouseVisible(true)
        b.MouseEnter = function()
            b:SetForeColor(HexToColor("#FFE9A8"))
        end
        b.MouseLeave = function()
            b:SetForeColor(HexToColor(BORDER_HEX))
            b:SetBackColor(HexToColor("#2A2418"))
        end
        b.MouseDown = function(sender, args)
            if IsLeft(args) then
                b:SetBackColor(HexToColor("#6A5226"))
            end
        end
        b.MouseUp = function()
            b:SetBackColor(HexToColor("#2A2418"))
        end
        return b
    end
    self.backBtn = barButton("")
    self.backBtn.MouseClick = function(sender, args)
        if IsLeft(args) then
            this.owner:_exitZoneMap()
        end
    end
    self.prevBtn = barButton("<")
    self.prevBtn.MouseClick = function(sender, args)
        if IsLeft(args) then
            this:StepMap(-1)
        end
    end
    self.nextBtn = barButton(">")
    self.nextBtn.MouseClick = function(sender, args)
        if IsLeft(args) then
            this:StepMap(1)
        end
    end
    self.mapName = barLabel(Turbine.UI.Lotro.Font.TrajanPro14, "#F0D9A0", Turbine.UI.ContentAlignment.MiddleCenter)
    self.hint = barLabel(Turbine.UI.Lotro.Font.Verdana10, "#A89B7A", Turbine.UI.ContentAlignment.MiddleRight)
    -- v3.3: los filtros van en la fila de Hombre / Mujer de la ventana
    -- (worldmap.lua + worldmap_filters.lua); al cambiar uno se redibuja.
    pcall(function()
        local F = Filters()
        if F ~= nil and F.OnChange ~= nil then
            F.OnChange(function()
                if this.active and this.mapOk then
                    this:_fillIcons()
                end
            end)
        end
    end)

    -- arrastrar (clic izquierdo) y volver (clic derecho), igual que el
    -- mapa del mundo (args.X/Y en coordenadas del contenido)
    self.content.MouseDown = function(sender, args)
        if IsRight(args) then
            this:Back()
            return
        end
        this.dragging = true
        this.dragMoved = false
        this.dragStartX, this.dragStartY = args.X, args.Y
        this.dragPanX, this.dragPanY = this.panX, this.panY
    end
    self.content.MouseMove = function(sender, args)
        if this.dragging then
            if math.abs(args.X - this.dragStartX) > DRAG_SLOP or math.abs(args.Y - this.dragStartY) > DRAG_SLOP then
                this.dragMoved = true
            end
            this.panX = this.dragPanX + (args.X - this.dragStartX)
            this.panY = this.dragPanY + (args.Y - this.dragStartY)
            this:_clampPan()
            this:_applyPan()
        end
    end
    self.content.MouseUp = function()
        this.dragging = false
    end
    -- clic izquierdo (sin arrastrar) sobre el nombre de un mapa vecino
    self.content.MouseClick = function(sender, args)
        if IsRight(args) or this.dragMoved then
            return
        end
        local lk = this:_linkAt(args.X, args.Y)
        if lk ~= nil then
            this:Navigate(lk.target)
        end
    end
    self.content.MouseLeave = function()
        this.dragging = false
    end

    self:Layout()
    return self
end

-- ---------------------------------------------------------------------
-- Tamaño (se llama desde el SizeChanged del mapa del mundo)
-- ---------------------------------------------------------------------
function ZV:Layout()
    local vw, vh = self.viewport:GetSize()
    if not vw or not vh then
        return
    end
    self.root:SetSize(vw, vh)
    self.bg:SetSize(vw, vh)
    self.noMap:SetPosition(0, BAR_H)
    self.noMap:SetSize(vw, math.max(20, vh - BAR_H))
    self.bar:SetSize(vw, BAR_H)
    local backW = 128
    local hintW = vw >= 640 and 190 or 0
    self.backBtn:SetPosition(4, 3)
    self.backBtn:SetSize(backW, BAR_H - 6)
    self.hint:SetVisible(hintW > 0)
    self.hint:SetPosition(vw - hintW - 6, 3)
    self.hint:SetSize(math.max(1, hintW), BAR_H - 6)
    local midX = backW + 12
    local midW = vw - midX - hintW - 12
    if midW < 120 then
        midW = 120
    end
    self.prevBtn:SetPosition(midX, 3)
    self.prevBtn:SetSize(24, BAR_H - 6)
    self.nextBtn:SetPosition(midX + midW - 24, 3)
    self.nextBtn:SetSize(24, BAR_H - 6)
    self.mapName:SetPosition(midX + 28, 2)
    self.mapName:SetSize(math.max(20, midW - 56), BAR_H - 4)
    self:_clampPan()
    self:_applyPan()
end

-- el mapa se ve en el area DEBAJO de la barra (de BAR_H a vh)
function ZV:_clampPan()
    local vw, vh = self.viewport:GetSize()
    if not vw or not vh then
        return
    end
    local mw, mh = self.mapW, self.mapH
    local areaH = vh - BAR_H
    if mw <= vw then
        self.panX = math.floor((vw - mw) / 2)
    else
        if self.panX > 0 then self.panX = 0 end
        if self.panX < vw - mw then self.panX = vw - mw end
    end
    if mh <= areaH then
        self.panY = BAR_H + math.floor((areaH - mh) / 2)
    else
        if self.panY > BAR_H then self.panY = BAR_H end
        if self.panY < vh - mh then self.panY = vh - mh end
    end
end

function ZV:_applyPan()
    self.content:SetPosition(self.panX, self.panY)
end

-- ---------------------------------------------------------------------
-- Iconos (se crean una vez por tipo y en orden de dibujo; se reusan)
-- ---------------------------------------------------------------------
function ZV:_buildPools()
    local need = {}
    for _, k in ipairs(KIND_ORDER) do
        need[k] = 0
    end
    if ZD ~= nil and ZD.Pois ~= nil then
        for _, list in pairs(ZD.Pois) do
            local n = {}
            for _, p in ipairs(list) do
                n[p[1]] = (n[p[1]] or 0) + 1
            end
            for k, v in pairs(n) do
                if need[k] ~= nil and v > need[k] then
                    need[k] = v
                end
            end
        end
    end
    local this = self
    local function layer(w, h, image)
        local c = Turbine.UI.Control()
        c:SetParent(self.content)
        c:SetSize(w, h)
        c:SetBackground(RES .. image)
        c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        c:SetMouseVisible(false)
        c:SetVisible(false)
        return c
    end
    -- v3.2: iconos de las capas del panel "Filtros del Mapa" (van debajo de
    -- los de siempre). Uno por icono del mapa que mas tiene; la imagen se
    -- pone al mostrarlo (cada uno puede ser de otra capa).
    local LD = WorldMapAddon.LayersData
    local needL = 0
    if type(LD) == "table" then
        for _, list in pairs(LD) do
            if #list > needL then
                needL = #list
            end
        end
    end
    -- v3.3: auras "activa" (hazaña con progreso, mision activa): pocas,
    -- se reparten entre los iconos que las necesitan; debajo de todo
    self.auraPool = {}
    for i = 1, AURA_MAX do
        self.auraPool[i] = { ctl = layer(AURA_W, AURA_H, "fl_aura_1.tga"), used = false, frame = 1, phase = (i * 5) % FX_FRAMES, x = 0, y = 0 }
    end
    local function makePin(i)
        local item = { layer = true, kind = "L", poi = false, vis = false, x = 0, y = 0, img = false, phase = (i * 7) % FX_FRAMES }
        local c = Turbine.UI.Control()
        c:SetParent(self.content)
        c:SetSize(LAYER_W, LAYER_H)
        c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        c:SetMouseVisible(true)
        c:SetVisible(false)
        item.icon = c
        c.MouseEnter = function()
            this:_enterItem(item)
        end
        c.MouseLeave = function()
            if this.hoverItem == item then
                this:_leaveItem()
            end
        end
        -- arrastrar el mapa tambien empezando encima de un icono (con
        -- muchas capas encendidas casi todo el mapa tiene iconos)
        local function toContent(args)
            return { X = item.x + (args and args.X or 0), Y = item.y + (args and args.Y or 0), Button = args and args.Button }
        end
        c.MouseDown = function(sender, args)
            if IsLeft(args) and this.content.MouseDown ~= nil then
                this.content.MouseDown(this.content, toContent(args))
            end
        end
        c.MouseMove = function(sender, args)
            if this.dragging and this.content.MouseMove ~= nil then
                this.content.MouseMove(this.content, toContent(args))
            end
        end
        c.MouseUp = function()
            this.dragging = false
        end
        c.MouseClick = function(sender, args)
            if IsRight(args) then
                this:Back()
            elseif item.vis and not this.dragMoved then
                local lk = this:_linkAt(item.x + (args.X or 0), item.y + (args.Y or 0))
                if lk ~= nil then
                    this:Navigate(lk.target)
                end
            end
        end
        return item
    end
    for i = 1, needL do
        self.layerPool[i] = makePin(i)
    end
    -- v3.3: misiones ACTIVAS del jugador (Quest Assistant), encima de las capas
    self.questPool = {}
    for i = 1, QPIN_MAX do
        local item = makePin(i)
        item.quest = true
        self.questPool[i] = item
    end
    for _, k in ipairs(KIND_ORDER) do
        local spec = KIND[k]
        local list = {}
        for i = 1, need[k] do
            local item = { kind = k, frame = 1, phase = (i * 5) % FX_FRAMES, poi = false, vis = false, x = 0, y = 0 }
            if QARROW_KINDS[k] then
                -- v3.3: aura dorada cuando hay misiones activas en ese lugar
                item.qring = layer(QRING_W, QRING_H, "fl_qaura_1.tga")
                item.qringFrame = 1
            end
            item.aura = layer(spec.aw, spec.ah, spec.aura .. "1.tga")
            if spec.hlIcon then
                -- resaltado = el icono iluminado, ENCIMA del icono (no toma el mouse)
                item.icon = layer(spec.w, spec.h, spec.img)
                item.hl = layer(spec.w, spec.h, spec.hl)
                item.img = spec.img
            else
                item.hl = layer(spec.aw, spec.ah, spec.hl)
                item.icon = layer(spec.w, spec.h, spec.img)
            end
            if spec.eyes ~= nil then
                item.eyes = layer(spec.w, spec.h, spec.eyes)
            end
            if QARROW_KINDS[k] then
                item.qaura = layer(QARROW.aw, QARROW.ah, QARROW.aura .. "1.tga")
                item.qarrow = layer(QARROW.w, QARROW.h, QARROW.img)
                local num = Turbine.UI.Label()
                num:SetParent(item.qarrow)
                num:SetPosition(0, 10)
                num:SetSize(QARROW.w, 16)
                num:SetFont(Turbine.UI.Lotro.Font.Verdana12)
                num:SetForeColor(HexToColor("#2A1A04"))
                num:SetFontStyle(Turbine.UI.FontStyle.Outline)
                num:SetOutlineColor(HexToColor("#FFE9A8"))
                num:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
                num:SetMouseVisible(false)
                num:SetSelectable(false)
                item.qnum = num
                item.qcount = 0
                item.qframe = 1
            end
            item.icon:SetMouseVisible(true)
            item.icon.MouseEnter = function()
                this:_enterItem(item)
            end
            item.icon.MouseLeave = function()
                if this.hoverItem == item then
                    this:_leaveItem()
                end
            end
            item.icon.MouseClick = function(sender, args)
                if IsRight(args) then
                    this:Back()
                elseif item.vis then
                    -- v3.5: incursion / mazmorra -> su mapa interior y su ficha
                    if (item.kind == "d" or item.kind == "r") and item.poi ~= false and this:OpenInstance(item.poi) then
                        return
                    end
                    -- icono encima del nombre de un mapa vecino: viaja igual
                    local lk = this:_linkAt(item.x + (args.X or 0), item.y + (args.Y or 0))
                    if lk ~= nil then
                        this:Navigate(lk.target)
                    end
                end
            end
            list[i] = item
        end
        self.pool[k] = list
    end
end

function ZV:_showItem(item, p)
    local spec = KIND[item.kind]
    local x, y
    if spec.tx ~= nil then
        -- la punta del icono en el lugar exacto
        x = math.floor(p[2] - spec.tx + 0.5)
        y = math.floor(p[3] - spec.ty + 0.5)
        if y < 0 then
            -- (muy arriba en el mapa: centrado, para no salirse del borde)
            y = math.floor(p[3] - spec.h / 2)
        end
    else
        x = math.floor(p[2] - spec.w / 2)
        y = math.floor(p[3] - spec.h / 2)
    end
    item.poi = p
    item.x, item.y = x, y
    if spec.farImg ~= nil then
        local img = (p[6] == "far") and spec.farImg or spec.img
        if item.img ~= img then
            item.img = img
            item.icon:SetBackground(RES .. img)
            item.hl:SetBackground(RES .. ((p[6] == "far") and spec.farHl or spec.hl))
        end
    end
    item.icon:SetPosition(x, y)
    item.aura:SetPosition(x + spec.ax, y + spec.ay)
    if spec.hlIcon then
        item.hl:SetPosition(x, y)
    else
        item.hl:SetPosition(x + spec.ax, y + spec.ay)
    end
    if item.eyes ~= nil then
        item.eyes:SetPosition(x, y)
        item.eyes:SetVisible(true)
    end
    -- v3.3.1 (pedido del usuario): establos sin aura; mazmorras e
    -- incursiones con aura SOLO si hay misiones activas ahi (la prende
    -- _refreshQuestArrows)
    item.aura:SetVisible(not spec.noAura and not spec.auraIfQuest)
    item.icon:SetVisible(true)
    item.hl:SetVisible(false)
    item.vis = true
end

-- v3.2: icono de capa (punta abajo en el punto x, y del mapa)
function ZV:_showLayer(item, p)
    local F = Filters()
    local name = F ~= nil and F.LayerIcon ~= nil and F.LayerIcon[p[1]] or nil
    if name == nil then
        return false
    end
    local tip = LAYER_TIP[name] or { 12, 23 }
    local x = math.floor(p[2] - tip[1] + 0.5)
    local y = math.floor(p[3] - tip[2] + 0.5)
    item.poi = p
    item.x, item.y = x, y
    item.img = name
    item.status = nil
    self:_setPinImage(item, false)
    item.icon:SetPosition(x, y)
    item.icon:SetVisible(true)
    item.vis = true
    return true
end

-- imagen del icono de capa segun su estado (completada = gris + X) y si el
-- mouse esta encima (iluminado). Solo cambia la imagen si es otra.
function ZV:_setPinImage(item, hover)
    local name = item.img
    if not name then
        return
    end
    local file
    if item.status == "done" then
        file = "fl_" .. name .. "_pin_done.tga"
    elseif hover then
        file = "fl_" .. name .. "_pin_hl.tga"
    else
        file = "fl_" .. name .. "_pin.tga"
    end
    if item.curImg ~= file then
        item.curImg = file
        item.icon:SetBackground(RES .. file)
    end
end

-- estado de un icono con hazañas (4 columnas + la 8a: "hazaña:entrada" por
-- renglon). Completado solo si TODOS sus renglones lo estan; activa si
-- alguno tiene progreso.
local function PoiStatus(keysText, namesText)
    local DA = WorldMapAddon.DeedActive
    if DA == nil or DA.Status == nil or keysText == nil or keysText == "" then
        return nil
    end
    local keys, names = Split(keysText), Split(namesText)
    local any, allDone, active = false, true, false
    for i = 1, math.max(#keys, #names) do
        local k = keys[i] or ""
        if k == "" then
            allDone = false
        else
            any = true
            local ok, st = pcall(DA.Status, k, names[i])
            st = ok and st or nil
            if st ~= "done" then
                allDone = false
            end
            if st == "active" then
                active = true
            end
        end
    end
    if not any then
        return nil
    end
    if allDone then
        return "done"
    end
    if active then
        return "active"
    end
    return nil
end

-- v3.3: estado de hazañas de todos los iconos visibles + auras de "activa"
function ZV:_refreshStatus()
    self.statusAt = Turbine.Engine.GetGameTime()
    local actives = {}
    for _, item in ipairs(self.layerPool) do
        if item.vis and item.poi ~= false then
            local st = PoiStatus(item.poi[8], item.poi[4])
            if st ~= item.status then
                item.status = st
                self:_setPinImage(item, self.hoverItem == item)
            end
            if st == "active" then
                actives[#actives + 1] = item
            end
        end
    end
    -- cofres de siempre que son de una hazaña
    local OD = WorldMapAddon.LayersOldDeed
    local od = type(OD) == "table" and self.mapId ~= false and OD[self.mapId] or nil
    for _, item in ipairs(self.pool.t or {}) do
        if item.vis and item.poi ~= false then
            local st = nil
            if od ~= nil then
                local key = od["t:" .. tostring(item.poi[2]) .. ":" .. tostring(item.poi[3])]
                if key ~= nil then
                    st = PoiStatus(key, item.poi[4])
                end
            end
            if st ~= item.status then
                item.status = st
                local spec = KIND.t
                local img = (st == "done") and "fl_cofre_24_done.tga" or spec.img
                if item.curImg ~= img then
                    item.curImg = img
                    item.icon:SetBackground(RES .. img)
                end
                item.aura:SetVisible(st ~= "done")
            end
            if st == "active" then
                actives[#actives + 1] = item
            end
        end
    end
    for _, item in ipairs(self.questPool) do
        if item.vis then
            actives[#actives + 1] = item
        end
    end
    -- auras: una por icono activo (las que sobran se apagan)
    local n = 0
    for _, item in ipairs(actives) do
        local a = self.auraPool[n + 1]
        if a == nil then
            break
        end
        n = n + 1
        local w, h = item.icon:GetSize()
        a.x = math.floor(item.x + (w or LAYER_W) / 2 - AURA_W / 2)
        a.y = math.floor(item.y + (h or LAYER_H) / 2 - AURA_H / 2)
        a.ctl:SetPosition(a.x, a.y)
        a.ctl:SetVisible(true)
        a.used = true
    end
    for i = n + 1, #self.auraPool do
        local a = self.auraPool[i]
        if a.used then
            a.used = false
            a.ctl:SetVisible(false)
        end
    end
end

-- v3.3: "12.3S, 45.6W" -> ns, ew (norte y este positivos)
local function ParseLoc(loc)
    local a, ns, b, ew = tostring(loc or ""):match("([%d%.]+)%s*([NnSs])%s*,%s*([%d%.]+)%s*([EeWwOo])")
    if a == nil then
        return nil
    end
    local n = tonumber(a)
    local e = tonumber(b)
    if n == nil or e == nil then
        return nil
    end
    if ns == "S" or ns == "s" then n = -n end
    if ew == "W" or ew == "w" or ew == "O" or ew == "o" then e = -e end
    return n, e
end
ZV.ParseLoc = ParseLoc

-- v3.3: misiones ACTIVAS del jugador en este mapa (pin de mision con aura),
-- en los lugares que da Quest Assistant. Mismas reglas que los demas
-- iconos: dentro del mapa, dentro del dibujo y fuera del cartel del titulo.
function ZV:_questPinData()
    local out = {}
    local Q = WorldMapAddon.Quests
    local CAL = WorldMapAddon.MapCal
    local cal = type(CAL) == "table" and self.mapId ~= false and CAL[self.mapId] or nil
    local zoneName = ZD ~= nil and ZD.MapZone ~= nil and ZD.MapZone[self.mapId] or nil
    if Q == nil or Q.ActiveInZone == nil or cal == nil or zoneName == nil then
        return out, ""
    end
    local ok, list = pcall(Q.ActiveInZone, zoneName)
    if not ok or type(list) ~= "table" then
        return out, ""
    end
    local sig = {}
    for _, e in ipairs(list) do
        sig[#sig + 1] = tostring(e.ndx)
    end
    table.sort(sig)
    local W, H = self.mapW, self.mapH
    for _, e in ipairs(list) do
        local nameEN = (e.quest and e.quest.nameEN) or ("#" .. tostring(e.ndx))
        local nameES = nameEN
        pcall(function() nameES = Q.QuestName(e.ndx, e.quest) end)
        for _, st in ipairs(e.stages or {}) do
            local ns, ew = ParseLoc(st.loc)
            if ns ~= nil then
                local x = ew * cal[1] + cal[2]
                local y = ns * cal[3] + cal[4]
                local inside = x - LAYER_W / 2 >= 3 and x + LAYER_W / 2 <= W - 3 and y - LAYER_H >= 3 and y <= H - 3
                local drawn = ns <= cal[5] + COVER_TOL and ns >= cal[7] - COVER_TOL and ew >= cal[6] - COVER_TOL and ew <= cal[8] + COVER_TOL
                local banner = cal[9] >= 0 and x + LAYER_W / 2 >= cal[9] and x - LAYER_W / 2 <= cal[11] and y >= cal[10] and y - LAYER_H <= cal[12]
                if inside and drawn and not banner then
                    local stEN = st.name or ""
                    local stES = (st.nameES ~= nil and st.nameES ~= "") and st.nameES or stEN
                    local merged = false
                    for _, q in ipairs(out) do
                        if math.abs(q.x - x) <= 10 and math.abs(q.y - y) <= 10 then
                            if #q.en < LAYER_MAX_LINES and not q.seen[tostring(e.ndx)] then
                                q.en[#q.en + 1] = nameEN; q.es[#q.es + 1] = nameES
                                q.sen[#q.sen + 1] = stEN; q.ses[#q.ses + 1] = stES
                                q.seen[tostring(e.ndx)] = true
                            end
                            merged = true
                            break
                        end
                    end
                    if not merged and #out < QPIN_MAX then
                        local seen = {}
                        seen[tostring(e.ndx)] = true
                        out[#out + 1] = { x = x, y = y, en = { nameEN }, es = { nameES }, sen = { stEN }, ses = { stES }, seen = seen }
                    end
                end
            end
        end
    end
    return out, table.concat(sig, ",")
end

function ZV:_fillQuestPins()
    for _, item in ipairs(self.questPool) do
        if item.vis then
            self:_hideItem(item)
        end
    end
    self.questSig = nil
    if not FilterOn("mis") then
        return
    end
    local data, sig = self:_questPinData()
    self.questSig = sig
    for i, q in ipairs(data) do
        local item = self.questPool[i]
        if item == nil then
            break
        end
        local p = { "mis", math.floor(q.x + 0.5), math.floor(q.y + 0.5), table.concat(q.en, "\n"), table.concat(q.es, "\n"),
            table.concat(q.sen, "\n"), table.concat(q.ses, "\n") }
        self:_showLayer(item, p)
    end
end

function ZV:_hideItem(item)
    item.vis = false
    item.poi = false
    if item.layer then
        item.status = nil
        item.icon:SetVisible(false)
        return
    end
    if item.qarrow ~= nil then
        item.qcount = 0
        item.qarrow:SetVisible(false)
        item.qaura:SetVisible(false)
    end
    if item.qring ~= nil then
        item.qring:SetVisible(false)
    end
    if item.status ~= nil or item.curImg ~= nil then
        -- (cofre que estaba completado: vuelve a su imagen de siempre)
        item.status = nil
        if item.curImg ~= nil and item.curImg ~= KIND[item.kind].img then
            item.icon:SetBackground(RES .. KIND[item.kind].img)
        end
        item.curImg = nil
    end
    item.aura:SetVisible(false)
    item.icon:SetVisible(false)
    item.hl:SetVisible(false)
    if item.eyes ~= nil then
        item.eyes:SetVisible(false)
    end
end

function ZV:_clearIcons()
    self:_leaveItem()
    self:_leaveLink()
    for _, k in ipairs(KIND_ORDER) do
        for _, item in ipairs(self.pool[k] or {}) do
            if item.vis then
                self:_hideItem(item)
            end
        end
    end
    for _, item in ipairs(self.layerPool) do
        if item.vis then
            self:_hideItem(item)
        end
    end
    for _, item in ipairs(self.questPool) do
        if item.vis then
            self:_hideItem(item)
        end
    end
    for _, a in ipairs(self.auraPool) do
        if a.used then
            a.used = false
            a.ctl:SetVisible(false)
        end
    end
    for _, lk in ipairs(self.linkPool) do
        if lk.vis then
            lk.vis = false
            lk.target = false
            lk.ctl:SetVisible(false)
        end
    end
end

function ZV:_fillIcons()
    self:_clearIcons()
    if ZD == nil or self.mapId == false then
        return
    end
    local list = ZD.Pois ~= nil and ZD.Pois[self.mapId] or nil
    -- v3.2: los que quedan debajo del cartel del titulo de ESTE mapa
    local HO = WorldMapAddon.LayersHideOld
    local hide = type(HO) == "table" and HO[self.mapId] or nil
    -- v3.4: "Hazañas" muestra TODO lo que es de una hazaña (exploracion,
    -- matar monstruos, cofres de hazaña y saber); las completadas no se
    -- ven salvo con "Ver completadas" (entonces gris con X)
    local hazOn = FilterOn("haz")
    local showDone = FilterOn("done")
    self.sigAt = WorldMapAddon.DeedActive ~= nil and WorldMapAddon.DeedActive.Signature ~= nil
        and WorldMapAddon.DeedActive.Signature() or nil
    local OD = WorldMapAddon.LayersOldDeed
    local od = type(OD) == "table" and OD[self.mapId] or nil
    if list ~= nil then
        local nextIdx = {}
        for _, p in ipairs(list) do
            local k = p[1]
            local pool = self.pool[k]
            local key = tostring(k) .. ":" .. tostring(p[2]) .. ":" .. tostring(p[3])
            local hidden = hide ~= nil and hide[key] == true
            local deedKey = (k == "t" and od ~= nil) and od[key] or nil
            -- v3.2: solo lo que esta marcado en "Filtros del Mapa"
            local on = FilterOn(KindFilter(p)) or (deedKey ~= nil and hazOn)
            if on and deedKey ~= nil and not showDone and PoiStatus(deedKey, p[4]) == "done" then
                on = false
            end
            if pool ~= nil and not hidden and on then
                local i = (nextIdx[k] or 0) + 1
                nextIdx[k] = i
                if pool[i] ~= nil then
                    self:_showItem(pool[i], p)
                end
            end
        end
    end
    -- v3.2: capas (exploracion, hazanas, NPC, ...) marcadas en el panel
    local LD = WorldMapAddon.LayersData
    local llist = type(LD) == "table" and LD[self.mapId] or nil
    if llist ~= nil then
        local i = 0
        for _, p in ipairs(llist) do
            local deed = p[8] ~= nil and p[8] ~= "" and DEED_LAYERS[p[1]] == true
            local on = FilterOn(p[1]) or (deed and hazOn)
            if on and deed and not showDone and PoiStatus(p[8], p[4]) == "done" then
                on = false
            end
            if on then
                local item = self.layerPool[i + 1]
                if item == nil then
                    break
                end
                if self:_showLayer(item, p) then
                    i = i + 1
                end
            end
        end
    end
    local links = ZD.Links ~= nil and ZD.Links[self.mapId] or nil
    if links ~= nil then
        local i = 0
        for _, l in ipairs(links) do
            if ZD.Maps[l[3]] ~= nil then
                i = i + 1
                local lk = self.linkPool[i]
                if lk == nil then
                    break
                end
                local x = math.floor(l[1] - LINK_W / 2)
                local y = math.floor(l[2] - LINK_H / 2)
                if x < 0 then x = 0 end
                if y < 0 then y = 0 end
                if x > self.mapW - LINK_W then x = self.mapW - LINK_W end
                if y > self.mapH - LINK_H then y = self.mapH - LINK_H end
                lk.target = l[3]
                lk.x, lk.y = x, y
                lk.ctl:SetPosition(x, y)
                lk.ctl:SetVisible(true)
                lk.vis = true
            end
        end
    end
    self:_refreshQuestArrows()
    -- v3.6: jefes del mapa interior de una instancia
    pcall(function() self:_fillBosses() end)
    -- v3.3: misiones activas del jugador + estado de hazañas (gris / aura)
    pcall(function() self:_fillQuestPins() end)
    pcall(function() self:_refreshStatus() end)
end

-- cuantas misiones activas tiene cada mazmorra / incursion del mapa; la
-- flecha solo se ve si hay al menos una. Sin Quest Assistant, ninguna.
function ZV:_refreshQuestArrows()
    self.qarrowAt = Turbine.Engine.GetGameTime()
    -- v3.7: la cache de jefes / elites solo se borra si cambian las misiones
    local Qs = WorldMapAddon.Quests
    local okS, sig = pcall(function() return Qs ~= nil and Qs.ActiveSig ~= nil and Qs.ActiveSig() or "" end)
    if not okS or sig ~= self.bossQSig or self.qarrowAt - (self.bossQAt or 0) > 30 then
        self.bossQCache = {}
        self.bossQSig = okS and sig or nil
        self.bossQAt = self.qarrowAt
    end
    pcall(function() self:_refreshBossArrows() end)
    local Q = WorldMapAddon.Quests
    local can = Q ~= nil and Q.InstanceQuests ~= nil and Q.Available ~= nil
    for k in pairs(QARROW_KINDS) do
        for _, item in ipairs(self.pool[k] or {}) do
            if item.qarrow ~= nil then
                local n = 0
                if can and item.vis and item.poi ~= false and FilterOn("mis") then
                    local ok, list = pcall(function()
                        if not Q.Available() then
                            return {}
                        end
                        return Q.InstanceQuests(Split(item.poi[4]), Split(item.poi[5]))
                    end)
                    if ok and type(list) == "table" then
                        n = #list
                    end
                end
                if n ~= item.qcount then
                    item.qcount = n
                    item.qnum:SetText(n > 0 and tostring(n) or "")
                end
                item.qarrow:SetVisible(n > 0)
                item.qaura:SetVisible(n > 0)
                if KIND[k] ~= nil and KIND[k].auraIfQuest then
                    item.aura:SetVisible(n > 0)
                end
                if item.qring ~= nil then
                    if n > 0 then
                        local w, h = item.icon:GetSize()
                        item.qring:SetPosition(math.floor(item.x + (w or 28) / 2 - QRING_W / 2), math.floor(item.y + (h or 28) / 2 - QRING_H / 2))
                    end
                    item.qring:SetVisible(n > 0)
                end
            end
        end
    end
end

-- la flecha sube y baja suave (cada cuadro) y su aura cambia de cuadro
function ZV:_animateQuestArrows(now)
    if self.qarrowBroken == true then
        return
    end
    local ok = pcall(function()
        if self.qarrowAt == nil or now - self.qarrowAt >= QARROW_REFRESH then
            self:_refreshQuestArrows()
        end
        local bob = math.floor(QARROW_BOB * math.sin(2 * math.pi * now / QARROW_PERIOD) + 0.5)
        local tick = math.floor(now * FX_FPS)
        -- v3.6: flecha sobre los jefes que pide una mision activa
        for _, item in ipairs(self.bossPool or {}) do
            if item.vis and item.qcount > 0 then
                local x = math.floor(item.poi[1] - QARROW.w / 2)
                local y = item.y - QARROW.h - QARROW_GAP + bob
                item.qarrow:SetPosition(x, y)
                item.qaura:SetPosition(x + QARROW.adx, y + QARROW.ady)
                local f = ((tick + item.phase) % FX_FRAMES) + 1
                if f ~= item.qframe then
                    item.qframe = f
                    item.qaura:SetBackground(RES .. QARROW.aura .. tostring(f) .. ".tga")
                end
            end
        end
        for k in pairs(QARROW_KINDS) do
            for _, item in ipairs(self.pool[k] or {}) do
                if item.qarrow ~= nil and item.vis and item.qcount > 0 then
                    local x = math.floor(item.poi[2] - QARROW.w / 2)
                    local y = item.y - QARROW.h - QARROW_GAP + bob
                    item.qarrow:SetPosition(x, y)
                    item.qaura:SetPosition(x + QARROW.adx, y + QARROW.ady)
                    local f = ((tick + item.phase) % FX_FRAMES) + 1
                    if f ~= item.qframe then
                        item.qframe = f
                        item.qaura:SetBackground(RES .. QARROW.aura .. tostring(f) .. ".tga")
                        if item.qring ~= nil then
                            item.qring:SetBackground(RES .. "fl_qaura_" .. tostring(f) .. ".tga")
                        end
                    end
                end
            end
        end
    end)
    if not ok then
        self.qarrowBroken = true
    end
end

-- ---------------------------------------------------------------------
-- Conectores: el nombre del mapa vecino se puede cliquear (como MoorMap)
-- ---------------------------------------------------------------------
function ZV:_buildLinks()
    local need = 0
    if ZD ~= nil and ZD.Links ~= nil then
        for _, list in pairs(ZD.Links) do
            if #list > need then
                need = #list
            end
        end
    end
    local this = self
    for i = 1, need do
        local lk = { vis = false, target = false }
        local c = Turbine.UI.Control()
        c:SetParent(self.content)
        c:SetSize(LINK_W, LINK_H)
        -- v3.1.2: SIN color de fondo. En LOTRO un color de fondo con
        -- transparencia (alfa < 1) no se mezcla con el mapa: "perfora" la
        -- ventana y deja ver el juego detras (salia un rectangulo negro u
        -- oscuro tapando el nombre del mapa vecino). Al pasar el mouse se
        -- marca con un marco dorado de 4 lineas opacas (no perforan).
        pcall(function()
            c:SetBackground(LINK_BLANK)
            c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        end)
        c:SetMouseVisible(true)
        c:SetVisible(false)
        lk.frame = {}
        local gold = HexToColor(BORDER_HEX)
        for j, r in ipairs({ { 0, 0, LINK_W, 2 }, { 0, LINK_H - 2, LINK_W, 2 }, { 0, 0, 2, LINK_H }, { LINK_W - 2, 0, 2, LINK_H } }) do
            local e = Turbine.UI.Control()
            e:SetParent(c)
            e:SetPosition(r[1], r[2])
            e:SetSize(r[3], r[4])
            e:SetBackColor(gold)
            e:SetMouseVisible(false)
            e:SetVisible(false)
            lk.frame[j] = e
        end
        c.MouseEnter = function()
            this:_enterLink(lk)
        end
        c.MouseLeave = function()
            if this.hoverLink == lk then
                this:_leaveLink()
            end
        end
        c.MouseClick = function(sender, args)
            if IsRight(args) then
                this:Back()
            elseif lk.vis and lk.target then
                this:Navigate(lk.target)
            end
        end
        lk.ctl = c
        self.linkPool[i] = lk
    end
end

-- conector bajo el punto (x, y) del mapa (pixeles del mapa). Respaldo por
-- coordenadas: el clic y el resaltado funcionan aunque el control del
-- conector no reciba el mouse, o haya un icono encima del nombre.
function ZV:_linkAt(x, y)
    if x == nil or y == nil then
        return nil
    end
    for i = #self.linkPool, 1, -1 do
        local lk = self.linkPool[i]
        if lk.vis and lk.target and lk.x ~= nil
            and x >= lk.x and x < lk.x + LINK_W and y >= lk.y and y < lk.y + LINK_H then
            return lk
        end
    end
    return nil
end

-- conector bajo el mouse (solo dentro del area del mapa, debajo de la barra)
function ZV:_linkUnderMouse()
    local ok, lk = pcall(function()
        local mx, my = Turbine.UI.Display.GetMousePosition()
        local vx, vy = self.viewport:PointToScreen(0, 0)
        local vw, vh = self.viewport:GetSize()
        if not (mx >= vx and mx < vx + vw and my >= vy + BAR_H and my < vy + vh) then
            return nil
        end
        local cx, cy = self.content:PointToScreen(0, 0)
        return self:_linkAt(mx - cx, my - cy)
    end)
    if ok then
        return lk
    end
    return nil
end

function ZV:_mapLabel(mid)
    local m = ZD ~= nil and ZD.Maps[mid] or nil
    if m == nil then
        return ""
    end
    if self.lang then
        return tostring(m.es or m.en or "")
    end
    return tostring(m.en or m.es or "")
end

function ZV:_enterLink(lk)
    if not lk.vis or not lk.target then
        return
    end
    self:_leaveItem()
    if self.hoverLink ~= false and self.hoverLink ~= lk then
        self:_leaveLink()
    end
    self.hoverLink = lk
    pcall(function() for _, e in ipairs(lk.frame) do e:SetVisible(true) end end)
    local title = self.lang and "Ir al mapa" or "Go to map"
    local hint = self.lang and "Clic: abrir este mapa" or "Click: open this map"
    pcall(function() self:_openTip(lk.ctl, title, { self:_mapLabel(lk.target), hint }) end)
end

function ZV:_leaveLink()
    local lk = self.hoverLink
    self.hoverLink = false
    if lk ~= false then
        pcall(function() for _, e in ipairs(lk.frame) do e:SetVisible(false) end end)
        if self.tipCtrl == lk.ctl then
            self:_hideTip()
        end
    end
end

-- ---------------------------------------------------------------------
-- Auras (solo las de los iconos que se ven en el viewport)
-- ---------------------------------------------------------------------
function ZV:_animate()
    local fx = self.fx
    if fx.broken == true then
        return
    end
    local now = Turbine.Engine.GetGameTime()
    if now - fx.last < (1 / FX_FPS) then
        return
    end
    fx.last = now
    local ok = pcall(function()
        local tick = math.floor(now * FX_FPS)
        local vw, vh = self.viewport:GetSize()
        local x0, y0 = -self.panX - 60, -self.panY - 60
        local x1, y1 = x0 + vw + 120, y0 + vh + 120
        for _, k in ipairs(KIND_ORDER) do
            local spec = KIND[k]
            for _, item in ipairs(self.pool[k] or {}) do
                local auraOn = not spec.noAura and (not spec.auraIfQuest or (item.qcount or 0) > 0)
                if auraOn and item.vis and item.x >= x0 and item.x <= x1 and item.y >= y0 and item.y <= y1 then
                    local f = ((tick + item.phase) % FX_FRAMES) + 1
                    if f ~= item.frame then
                        item.frame = f
                        item.aura:SetBackground(RES .. spec.aura .. tostring(f) .. ".tga")
                    end
                    if item.eyes ~= nil then
                        item.eyes:SetOpacity(0.55 + 0.45 * math.sin((2 * math.pi * now / 1.6) + item.phase))
                    end
                end
            end
        end
        -- v3.3: auras de "activa"
        for _, a in ipairs(self.auraPool or {}) do
            if a.used and a.x >= x0 and a.x <= x1 and a.y >= y0 and a.y <= y1 then
                local f = ((tick + a.phase) % FX_FRAMES) + 1
                if f ~= a.frame then
                    a.frame = f
                    a.ctl:SetBackground(RES .. "fl_aura_" .. tostring(f) .. ".tga")
                end
            end
        end
    end)
    if not ok then
        fx.broken = true
    end
end

-- ---------------------------------------------------------------------
-- Resaltado y cartel de los iconos
-- ---------------------------------------------------------------------
function ZV:_enterItem(item)
    if not item.vis or item.poi == false then
        return
    end
    self:_leaveLink()
    if self.hoverItem ~= false and self.hoverItem ~= item then
        self:_leaveItem()
    end
    self.hoverItem = item
    local title, lines
    if item.boss then
        title, lines = self:_bossTip(item)
        pcall(function() self:_openTip(item.icon, title, lines) end)
        return
    end
    if item.layer then
        pcall(function() self:_setPinImage(item, true) end)
        title, lines = LayerTip(item.poi, self.lang)
        -- v3.3: estado de la hazaña / mision
        local es = self.lang
        if item.quest then
            -- (pin de mision: siempre activa)
        elseif item.status == "done" then
            lines[#lines + 1] = es and "[Completada]" or "[Completed]"
        elseif item.status == "active" then
            lines[#lines + 1] = es and "[En progreso]" or "[In progress]"
        end
        -- v3.4: progreso de la hazaña ("Progreso: 3/8")
        if not item.quest and item.poi[8] ~= nil and item.poi[8] ~= "" then
            pcall(function()
                local DA = WorldMapAddon.DeedActive
                local seen = {}
                for _, k in ipairs(Split(item.poi[8])) do
                    local id = k:match("^(%d+)")
                    if id ~= nil and not seen[id] then
                        seen[id] = true
                        local n, tot = DA.Progress(id)
                        if n ~= nil then
                            lines[#lines + 1] = (es and "Progreso: " or "Progress: ") .. n .. "/" .. tot
                        end
                    end
                end
            end)
        end
        -- v3.8: saber del lugar, hazaña, recompensas... (Deed Tracker)
        if not item.quest then
            pcall(function()
                for _, l in ipairs(DeedInfoLines(item.poi, es)) do
                    lines[#lines + 1] = l
                end
            end)
        end
    else
        if item.status ~= "done" then
            pcall(function() item.hl:SetVisible(true) end)
        end
        title, lines = TipFor(item.poi, self.lang)
        -- v3.3: cofre de una hazaña: su estado
        if title == nil and item.status ~= nil and item.kind == "t" then
            title = self.lang and "Cofre / tesoro" or "Chest / treasure"
            local en1 = ((item.poi[4] or ""):gsub("\n.*", ""))
            lines = { self.lang and NameES(en1) or en1 }
        end
        if title ~= nil and item.kind == "t" then
            lines = lines or {}
            if item.status == "done" then
                lines[#lines + 1] = self.lang and "[Completada]" or "[Completed]"
            elseif item.status == "active" then
                lines[#lines + 1] = self.lang and "[En progreso]" or "[In progress]"
            end
        end
    end
    if title ~= nil and (item.kind == "r" or item.kind == "d") then
        lines = lines or {}
        if #self:_instancesOf(item.poi) > 0 then
            lines[#lines + 1] = self.lang and "Clic: ver su mapa e informaci\195\179n" or "Click: open its map and info"
        end
        for _, l in ipairs(self:_questLines(item.poi)) do
            lines[#lines + 1] = l
        end
    end
    if title ~= nil then
        pcall(function() self:_openTip(item.icon, title, lines or {}) end)
    else
        self:_hideTip()
    end
end

function ZV:_leaveItem()
    local item = self.hoverItem
    self.hoverItem = false
    if item ~= false then
        if item.layer then
            pcall(function() self:_setPinImage(item, false) end)
        elseif item.hl ~= nil then
            pcall(function() item.hl:SetVisible(false) end)
        end
        if self.tipCtrl == item.icon then
            self:_hideTip()
        end
    end
end

function ZV:_buildTip()
    local tip = Turbine.UI.Window()
    tip:SetSize(TIP_W, 60)
    tip:SetBackColor(HexToColor(BORDER_HEX))
    tip:SetZOrder(0x7FFFFFFF)
    tip:SetMouseVisible(false)
    tip:SetVisible(false)
    local inner = Turbine.UI.Control()
    inner:SetParent(tip)
    inner:SetPosition(1, 1)
    inner:SetSize(TIP_W - 2, 58)
    inner:SetBackColor(Turbine.UI.Color(1, 0.06, 0.05, 0.03))
    inner:SetMouseVisible(false)
    local title = Turbine.UI.Label()
    title:SetParent(tip)
    title:SetPosition(TIP_PAD, 6)
    title:SetSize(TIP_W - (2 * TIP_PAD), TIP_TITLE_H)
    title:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
    title:SetForeColor(HexToColor("#F0D9A0"))
    title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    title:SetMouseVisible(false)
    local body = Turbine.UI.Label()
    body:SetParent(tip)
    body:SetPosition(TIP_PAD, 6 + TIP_TITLE_H + 2)
    body:SetSize(TIP_W - (2 * TIP_PAD), 20)
    body:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    body:SetForeColor(HexToColor("#E8DDBF"))
    body:SetMultiline(true)
    body:SetMouseVisible(false)
    self.tip = { win = tip, inner = inner, title = title, body = body, h = 60 }
end

function ZV:_placeTip()
    local t = self.tip
    if t == nil then
        return
    end
    local mx, my = Turbine.UI.Display.GetMousePosition()
    local x, y = mx + 18, my + 18
    local maxX = Turbine.UI.Display.GetWidth() - TIP_W
    local maxY = Turbine.UI.Display.GetHeight() - t.h
    if x > maxX then x = mx - TIP_W - 8 end
    if y > maxY then y = maxY end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    t.win:SetPosition(x, y)
end

function ZV:_openTip(ctrl, titleText, lines)
    if self.tip == nil then
        self:_buildTip()
    end
    local t = self.tip
    local bodyW = TIP_W - (2 * TIP_PAD)
    local n = 0
    for _, line in ipairs(lines) do
        n = n + TipLines(line, bodyW)
    end
    local bodyH = (n > 0) and (n * TIP_LINE_H + 2) or 0
    local h = 6 + TIP_TITLE_H + 2 + bodyH + 8
    t.h = h
    t.win:SetSize(TIP_W, h)
    t.inner:SetSize(TIP_W - 2, h - 2)
    t.body:SetSize(bodyW, math.max(1, bodyH))
    t.title:SetText(titleText)
    t.body:SetText(table.concat(lines, "\n"))
    self:_placeTip()
    t.win:SetVisible(true)
    self.tipOn = true
    self.tipCtrl = ctrl
end

function ZV:_hideTip()
    self.tipOn = false
    self.tipCtrl = false
    if self.tip ~= nil then
        pcall(function() self.tip.win:SetVisible(false) end)
    end
end

-- el mouse sigue encima del icono / conector (y dentro del area del mapa)?
function ZV:_mouseOver(ctl)
    local ok, inside = pcall(function()
        local sx, sy = ctl:PointToScreen(0, 0)
        local w, h = ctl:GetSize()
        local mx, my = Turbine.UI.Display.GetMousePosition()
        local vx, vy = self.viewport:PointToScreen(0, 0)
        local vw, vh = self.viewport:GetSize()
        return mx >= sx and mx < sx + w and my >= sy and my < sy + h
            and mx >= vx and mx < vx + vw and my >= vy + BAR_H and my < vy + vh
    end)
    return ok and inside == true
end

function ZV:_checkTip()
    local item = self.hoverItem
    if item ~= false then
        if item.vis and self:_mouseOver(item.icon) then
            if self.tipOn then
                pcall(function() self:_placeTip() end)
            end
        else
            self:_leaveItem()
        end
    end
    local lk = self.hoverLink
    if lk ~= false then
        if lk.vis and self:_mouseOver(lk.ctl) then
            if self.tipOn then
                pcall(function() self:_placeTip() end)
            end
        else
            self:_leaveLink()
        end
    end
end

-- ---------------------------------------------------------------------
-- Mapas: abrir, viajar, volver
-- ---------------------------------------------------------------------
function ZV:_zoneTitle()
    local zone = self.zone
    if zone == false or zone == nil then
        return ""
    end
    if self.lang then
        return tostring(zone.nombre or zone.nombre_original or "")
    end
    return tostring(zone.nombre_original or zone.nombre or "")
end

function ZV:_zoneMaps()
    -- v3.5: dentro de una instancia, < > recorren sus mapas interiores
    if self.instMaps ~= nil and self:_isInstMap(self.mapId) then
        return self.instMaps
    end
    if self.zone == false or self.zone == nil or ZD == nil or ZD.Zones == nil then
        return {}
    end
    return ZD.Zones[self.zone.nombre_original or ""] or {}
end

function ZV:_mapTitle()
    if self.mapId == false then
        return self:_zoneTitle()
    end
    local ids = self:_zoneMaps()
    local idx = nil
    for i, id in ipairs(ids) do
        if id == self.mapId then
            idx = i
            break
        end
    end
    local text
    if idx == 1 and not self:_isInstMap(self.mapId) then
        text = self:_zoneTitle()
    else
        text = self:_mapLabel(self.mapId)
    end
    if idx ~= nil and #ids > 1 then
        text = text .. "  (" .. tostring(idx) .. "/" .. tostring(#ids) .. ")"
    end
    return text
end

function ZV:_refreshTexts()
    self.backBtn:SetText(self.lang and "Volver al mundo" or "Back to world")
    self.hint:SetText(self.lang and "Clic derecho: volver" or "Right-click: back")
    self.noMap:SetText(self.lang and "Mapa no disponible para esta zona" or "No map available for this zone")
    self.mapName:SetText(self:_mapTitle())
    local multi = #self:_zoneMaps() > 1
    self.prevBtn:SetVisible(multi)
    self.nextBtn:SetVisible(multi)
    local title = self:_zoneTitle()
    if title == "" then
        title = self:_mapLabel(self.mapId)
    end
    pcall(function()
        self.owner:SetText((self.lang and "Mapa: " or "Map: ") .. title)
    end)
end

function ZV:_checkLanguage()
    local now = Turbine.Engine.GetGameTime()
    if self.langAt ~= nil and now - self.langAt < 1 then
        return
    end
    self.langAt = now
    local es = IsES()
    if es ~= self.lang then
        self.lang = es
        pcall(function() self:_refreshTexts() end)
        pcall(function() self:_refreshInstInfo() end)
        pcall(function() self:_fillBosses() end)
        pcall(function()
            local F = Filters()
            if F ~= nil and F.RefreshLanguage ~= nil then
                F.RefreshLanguage()
            end
        end)
        local item = self.hoverItem
        if item ~= false then
            self:_leaveItem()
            self:_enterItem(item)
        end
    end
end

function ZV:_loadMap()
    self:_hideTip()
    self.dragging = false
    local m = (self.mapId ~= false and ZD ~= nil) and ZD.Maps[self.mapId] or nil
    local ok = false
    if m ~= nil then
        self.mapW, self.mapH = m.w or 1024, m.h or 768
        self.content:SetSize(self.mapW, self.mapH)
        self.mapImage:SetSize(self.mapW, self.mapH)
        ok = pcall(Turbine.UI.Control.SetBackground, self.mapImage, m.img)
    end
    self.mapOk = ok
    self.content:SetVisible(ok)
    self.noMap:SetVisible(not ok)
    if ok then
        self:_fillIcons()
    else
        self:_clearIcons()
    end
    -- centrado en el area debajo de la barra
    local vw, vh = self.viewport:GetSize()
    self.panX = math.floor(((vw or 0) - self.mapW) / 2)
    self.panY = BAR_H + math.floor((((vh or 0) - BAR_H) - self.mapH) / 2)
    self:_clampPan()
    self:_applyPan()
    self:_refreshTexts()
    pcall(function() self:_refreshInstInfo() end)
end

-- cambia al mapa mid; push = guardar el actual para volver con clic derecho
function ZV:_setMap(mid, push)
    if push and self.mapId ~= false and self.mapId ~= mid then
        self.history[#self.history + 1] = self.mapId
        if #self.history > 40 then
            table.remove(self.history, 1)
        end
    end
    self.mapId = mid
    -- v3.5: mapa interior de una instancia: la zona no cambia
    if self:_isInstMap(mid) then
        self:_loadMap()
        return
    end
    self.instMaps = nil
    self.instInfo = nil
    -- la zona del mapa del mundo a la que pertenece (puede cambiar al viajar)
    local zname = ZD ~= nil and ZD.MapZone ~= nil and ZD.MapZone[mid] or nil
    local newZone = false
    if zname ~= nil and self.owner._zoneByOriginal ~= nil then
        local okZ, z = pcall(self.owner._zoneByOriginal, self.owner, zname)
        if okZ and z ~= nil then
            newZone = z
        end
    end
    local changed = newZone ~= false and newZone ~= self.zone
    if newZone ~= false then
        self.zone = newZone
    elseif zname == nil then
        -- mapa de region (Eriador, Rhovanion...): sin zona
        self.zone = false
    end
    self:_loadMap()
    if changed and self.owner._onZoneViewZone ~= nil then
        pcall(self.owner._onZoneViewZone, self.owner, newZone)
    end
end

-- viajar por un conector (clic en el nombre del mapa vecino)
function ZV:Navigate(mid)
    if ZD == nil or ZD.Maps[mid] == nil then
        return
    end
    self:_leaveLink()
    self:_setMap(mid, true)
end

-- < > : mapas de la misma zona
function ZV:StepMap(delta)
    local ids = self:_zoneMaps()
    local n = #ids
    if n < 2 then
        return
    end
    local idx = 0
    for i, id in ipairs(ids) do
        if id == self.mapId then
            idx = i
            break
        end
    end
    local nextIdx
    if idx == 0 then
        nextIdx = delta > 0 and 1 or n
    else
        nextIdx = ((idx - 1 + delta) % n) + 1
    end
    self:_setMap(ids[nextIdx], true)
end

-- clic derecho: mapa anterior; desde el primero, al mapa del mundo
function ZV:Back()
    self:_leaveItem()
    self:_leaveLink()
    local prev = table.remove(self.history)
    if prev ~= nil then
        self:_setMap(prev, false)
    else
        pcall(function() self.owner:_exitZoneMap() end)
    end
end

-- abre el mapa de una zona del mapa del mundo
function ZV:ShowZone(zone)
    self.lang = IsES()
    self.history = {}
    self.zone = zone or false
    local ids = self:_zoneMaps()
    self.mapId = ids[1] or false
    self.active = true
    self.root:SetVisible(true)
    self:Layout()
    self:_loadMap()
end

function ZV:Deactivate()
    self.active = false
    self.dragging = false
    self.instMaps = nil
    self.instInfo = nil
    pcall(function() self:_refreshInstInfo() end)
    self:_leaveItem()
    self:_leaveLink()
    self:_hideTip()
    pcall(function()
        local F = Filters()
        if F ~= nil and F.HidePanel ~= nil then
            F.HidePanel()
        end
    end)
    pcall(function() self.root:SetVisible(false) end)
end

function ZV:IsActive()
    return self.active == true
end

-- un cuadro (lo llama el poll del mapa del mundo mientras se ve la zona)
function ZV:Tick()
    if not self.active then
        return
    end
    self:_checkTip()
    if self.hoverLink == false and self.hoverItem == false and not self.dragging then
        local lk = self:_linkUnderMouse()
        if lk ~= nil then
            self:_enterLink(lk)
        end
    end
    self:_animate()
    self:_animateQuestArrows(Turbine.Engine.GetGameTime())
    -- v3.3: cada pocos segundos, misiones activas y estado de hazañas
    local now = Turbine.Engine.GetGameTime()
    if self.mapOk and (self.statusAt == nil or now - self.statusAt >= STATUS_REFRESH) then
        pcall(function()
            if FilterOn("mis") then
                local _, sig = self:_questPinData()
                if sig ~= self.questSig then
                    self:_fillQuestPins()
                end
            end
            -- v3.4: copia de Deed Tracker / Quest Assistant y, si cambio
            -- algo (completada nueva, progreso), se vuelve a dibujar
            local DA = WorldMapAddon.DeedActive
            if DA ~= nil and DA.Sync ~= nil then
                DA.Sync()
            end
            local sig = DA ~= nil and DA.Signature ~= nil and DA.Signature() or nil
            if sig ~= nil and sig ~= self.sigAt then
                self:_fillIcons()
            else
                self:_refreshStatus()
            end
            -- completadas de Deed Tracker: se relee su guardado cada 30 s
            -- (lectura asincronica del propio modulo de hazañas)
            if self.deedsAt == nil or now - self.deedsAt >= 30 then
                self.deedsAt = now
                local D = WorldMapAddon.Deeds
                if D ~= nil and D.RefreshStatus ~= nil then
                    D.RefreshStatus(false)
                end
            end
        end)
        self.statusAt = now
    end
    self:_checkLanguage()
end

-- misiones activas en esa mazmorra / incursion (Quest Assistant); sin
-- Quest Assistant no se agrega nada
function ZV:_questLines(p)
    local out = {}
    local Q = WorldMapAddon.Quests
    if Q == nil or Q.InstanceQuests == nil or Q.Available == nil then
        return out
    end
    local ok = pcall(function()
        if not Q.Available() then
            return
        end
        local list = Q.InstanceQuests(Split(p[4]), Split(p[5]))
        local es = self.lang
        if #list == 0 then
            out[1] = es and "Sin misiones activas aqu\195\173." or "No active quests here."
            return
        end
        out[1] = es and "Misiones activas aqu\195\173:" or "Active quests here:"
        local maxShown = 8
        for i, q in ipairs(list) do
            if i > maxShown then
                local rest = #list - maxShown
                out[#out + 1] = es and ("... y " .. rest .. " m\195\161s") or ("... and " .. rest .. " more")
                break
            end
            local first, second = q.es, q.en
            if not es then
                first, second = q.en, q.es
            end
            if second ~= nil and second ~= "" and second ~= first then
                out[#out + 1] = "- " .. first .. " (" .. second .. ")"
            else
                out[#out + 1] = "- " .. first
            end
        end
    end)
    if not ok then
        return {}
    end
    return out
end

-- ---------------------------------------------------------------------
-- v3.5 (pedido del usuario): clic en una incursion / mazmorra -> su mapa
-- interior (imagen del propio cliente, numero de recurso, igual que los
-- mapas de zona) y una ficha con niveles, jugadores, misiones activas y
-- jefes (worldmap_instances_data.lua). < > recorren sus mapas; clic
-- derecho vuelve al mapa de la zona. Sin mapa interior: solo la ficha.
-- Las posiciones de jefes no estan confirmadas: solo se nombra la sala.
-- ---------------------------------------------------------------------
local INFO_W = 330
local INFO_PAD = 8
local INFO_MAX_BOSSES = 10

local function InstData()
    return WorldMapAddon.InstanceData
end

function ZV:_isInstMap(mid)
    local m = ZD ~= nil and mid ~= false and mid ~= nil and ZD.Maps[mid] or nil
    return m ~= nil and m.inst == true
end

-- instancias (indices) de un icono: cada nombre (ingles) del icono
function ZV:_instancesOf(p)
    local D = InstData()
    local out = {}
    if D == nil or p == nil or p == false then
        return out
    end
    local seen = {}
    for _, name in ipairs(Split(p[4])) do
        for _, idx in ipairs(D.ByName[name] or {}) do
            if not seen[idx] and D.Inst[idx] ~= nil then
                seen[idx] = true
                out[#out + 1] = idx
            end
        end
    end
    return out
end

function ZV:OpenInstance(p)
    local D = InstData()
    local idxs = self:_instancesOf(p)
    if D == nil or #idxs == 0 then
        return false
    end
    local maps, seen = {}, {}
    for _, idx in ipairs(idxs) do
        for _, mid in ipairs(D.Inst[idx].maps or {}) do
            local m = D.Maps[mid]
            if m ~= nil and not seen[mid] then
                seen[mid] = true
                if ZD.Maps[mid] == nil then
                    ZD.Maps[mid] = { img = m.img, w = m.w, h = m.h, en = m.en, es = m.es, inst = true }
                end
                maps[#maps + 1] = mid
            end
        end
    end
    self:_leaveItem()
    self:_hideTip()
    self.instInfo = { idxs = idxs, poi = p, open = true }
    if #maps > 0 then
        self.instMaps = maps
        self:_setMap(maps[1], true)
    else
        -- sin mapa interior: la ficha encima del mapa de la zona
        self:_refreshInstInfo()
    end
    return true
end

function ZV:_buildInstInfo()
    local this = self
    local box = Turbine.UI.Control()
    box:SetParent(self.root)
    box:SetBackColor(HexToColor(BORDER_HEX))
    box:SetMouseVisible(true)
    box:SetVisible(false)
    local inner = Turbine.UI.Control()
    inner:SetParent(box)
    inner:SetPosition(1, 1)
    inner:SetBackColor(Turbine.UI.Color(1, 0.06, 0.05, 0.03))
    inner:SetMouseVisible(false)
    local title = Turbine.UI.Label()
    title:SetParent(box)
    title:SetPosition(INFO_PAD, 6)
    title:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
    title:SetForeColor(HexToColor("#F0D9A0"))
    title:SetMultiline(true)
    title:SetMouseVisible(false)
    local body = Turbine.UI.Label()
    body:SetParent(box)
    body:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    body:SetForeColor(HexToColor("#E8DDBF"))
    body:SetMultiline(true)
    body:SetMouseVisible(false)
    -- colores por seccion (si el cliente no acepta marcas: texto sin color)
    self.markupOk = pcall(function() body:SetMarkupEnabled(true) end)
    -- clic: plegar / desplegar (queda solo el titulo)
    box.MouseClick = function(sender, args)
        if IsRight(args) then
            this:Back()
        elseif this.instInfo ~= nil then
            this.instInfo.open = not this.instInfo.open
            this:_refreshInstInfo()
        end
    end
    self.instBox = { box = box, inner = inner, title = title, body = body }
end

function ZV:_instInfoLines()
    local D = InstData()
    local info = self.instInfo
    local es = self.lang
    local title, lines = "", {}
    local function both(a, b)
        if a == nil or a == "" then return b or "" end
        if b == nil or b == "" or b == a then return a end
        return a .. " (" .. b .. ")"
    end
    -- v3.6: colores por seccion (texto con marcas <rgb=...> del juego)
    local function C(hex, text)
        return "<rgb=" .. hex .. ">" .. text .. "</rgb>"
    end
    for n, idx in ipairs(info.idxs) do
        local it = D.Inst[idx]
        local name = es and both(it.es, it.en) or both(it.en, it.es)
        if n == 1 then
            title = name
            if #info.idxs > 1 and info.poi ~= nil then
                -- (varias alas / partes: el nombre del lugar)
                local pen = Split(info.poi[4])[1] or ""
                local pes = Split(info.poi[5])[1] or ""
                if pes == "" or pes == pen then pes = NameES(pen) end
                title = es and both(pes, pen) or both(pen, pes)
            end
            if #info.idxs > 1 then
                lines[#lines + 1] = C("#C9A66B", (es and "Partes: " or "Parts: ") .. #info.idxs)
            end
        end
        if #info.idxs > 1 then
            lines[#lines + 1] = C("#F0D9A0", "- " .. name)
        end
        local lvl = it.lmin or ""
        if it.lmax ~= nil and it.lmax ~= "" and it.lmax ~= it.lmin then
            lvl = lvl .. "-" .. it.lmax
        end
        local row = {}
        if lvl ~= "" then
            row[#row + 1] = (es and "Nivel " or "Level ") .. lvl .. (it.scaling and (es and " (escala)" or " (scaling)") or "")
        end
        local sizes = es and it.sizesES or it.sizesEN
        if sizes ~= nil and sizes ~= "" then
            row[#row + 1] = sizes
        end
        if #row > 0 then
            lines[#lines + 1] = C("#B8C8D8", (#info.idxs > 1 and "   " or "") .. table.concat(row, "  |  "))
        end
    end
    -- misiones activas del jugador en este lugar (Quest Assistant)
    local Q = WorldMapAddon.Quests
    if Q ~= nil and Q.InstanceQuests ~= nil and Q.Available ~= nil and info.poi ~= nil then
        pcall(function()
            if not Q.Available() then return end
            local list = Q.InstanceQuests(Split(info.poi[4]), Split(info.poi[5]))
            if #list > 0 then
                lines[#lines + 1] = C("#7CE07C", (es and "Misiones activas aqu\195\173: " or "Active quests here: ") .. #list)
                for i, q in ipairs(list) do
                    if i > 6 then break end
                    lines[#lines + 1] = C("#F0D060", "- " .. ((es and q.es or q.en) or q.es or q.en or ""))
                end
            end
        end)
    end
    -- jefes (con la sala donde estan, segun la guia; sin posicion exacta)
    local nb = 0
    for _, idx in ipairs(info.idxs) do
        for _, b in ipairs(D.Inst[idx].bosses or {}) do
            if nb == 0 then
                lines[#lines + 1] = C("#FF8A60", es and "Jefes:" or "Bosses:")
            end
            nb = nb + 1
            if nb > INFO_MAX_BOSSES then
                break
            end
            local name = es and both(b[2], b[1]) or b[1]
            local line = C("#F0E6D0", "- " .. name)
            if b[3] ~= nil and b[3] ~= "" then
                line = line .. C("#A89B7A", " - " .. b[3])
            end
            -- jefe que pide una mision activa
            if self:_bossQuests(b[1], b[2]) > 0 then
                line = line .. C("#FFD040", es and "  [misi\195\179n]" or "  [quest]")
            end
            lines[#lines + 1] = line
        end
    end
    if not self:_isInstMap(self.mapId) then
        lines[#lines + 1] = C("#8C8C8C", es and "(sin mapa interior)" or "(no interior map)")
    else
        lines[#lines + 1] = C("#8C8C8C", es and "Clic derecho: volver a la zona" or "Right-click: back to the zone")
    end
    return title, lines
end

function ZV:_refreshInstInfo()
    local info = self.instInfo
    local show = self.active and info ~= nil and InstData() ~= nil
    if not show then
        if self.instBox ~= nil then
            self.instBox.box:SetVisible(false)
        end
        return
    end
    if self.instBox == nil then
        self:_buildInstInfo()
    end
    local t = self.instBox
    local title, lines = self:_instInfoLines()
    local bodyW = INFO_W - 2 * INFO_PAD
    local tl = TipLines(title, bodyW * 0.8)
    local titleH = tl * 18 + 2
    local bodyH = 0
    if info.open then
        for _, l in ipairs(lines) do
            bodyH = bodyH + TipLines((l:gsub("<[^>]*>", "")), bodyW) * TIP_LINE_H
        end
    end
    local vw, vh = self.viewport:GetSize()
    local maxH = math.max(60, (vh or 400) - BAR_H - 16)
    local h = 6 + titleH + (info.open and (bodyH + 6) or 0) + 6
    if h > maxH then
        bodyH = bodyH - (h - maxH)
        h = maxH
    end
    t.box:SetPosition(8, BAR_H + 8)
    t.box:SetSize(INFO_W, h)
    t.inner:SetSize(INFO_W - 2, h - 2)
    t.title:SetSize(bodyW, titleH)
    t.title:SetText(title)
    t.body:SetPosition(INFO_PAD, 6 + titleH + 4)
    t.body:SetSize(bodyW, math.max(1, bodyH))
    local text = info.open and table.concat(lines, "\n") or ""
    if not self.markupOk then
        text = text:gsub("<[^>]*>", "")
    end
    t.body:SetText(text)
    t.body:SetVisible(info.open)
    t.box:SetVisible(true)
end

-- ---------------------------------------------------------------------
-- v3.6 (pedido del usuario): jefes en el mapa interior (icono + nombre).
-- Solo donde el marcador del propio juego cae en ESE mapa (ver
-- worldmap_instances_data.lua). Si una mision activa nombra al jefe, la
-- flecha dorada que sube y baja lo señala (igual que en las mazmorras).
-- Se ven con el filtro "Jefes".
-- ---------------------------------------------------------------------
-- v3.7: jefe = cabeza de orco con corona (34x34); elite = cabeza con casco
-- (28x28), un icono por grupo de monstruos. El pool crece segun el mapa.
local BOSS_MAX = 80
local BOSS_W, BOSS_H, BOSS_TX, BOSS_TY = 34, 34, 16, 33
local ELITE_W, ELITE_H, ELITE_TX, ELITE_TY = 28, 28, 13, 27

function ZV:_buildBossPool(n)
    self.bossPool = self.bossPool or {}
    local this = self
    local function layer(w, h, image)
        local c = Turbine.UI.Control()
        c:SetParent(self.content)
        c:SetSize(w, h)
        c:SetBackground(RES .. image)
        c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        c:SetMouseVisible(false)
        c:SetVisible(false)
        return c
    end
    for i = #self.bossPool + 1, math.min(n or BOSS_MAX, BOSS_MAX) do
        local item = { boss = true, kind = "B", vis = false, poi = false, x = 0, y = 0, qcount = 0, qframe = 1, phase = (i * 3) % FX_FRAMES }
        item.qaura = layer(QARROW.aw, QARROW.ah, QARROW.aura .. "1.tga")
        item.qarrow = layer(QARROW.w, QARROW.h, QARROW.img)
        item.iconB = layer(BOSS_W, BOSS_H, "fl_jefeorco_34.tga")
        item.iconE = layer(ELITE_W, ELITE_H, "fl_elite_28.tga")
        item.icon = item.iconB
        local lbl = Turbine.UI.Label()
        lbl:SetParent(self.content)
        lbl:SetSize(160, 16)
        lbl:SetFont(Turbine.UI.Lotro.Font.Verdana12)
        lbl:SetForeColor(HexToColor("#FFB080"))
        lbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
        lbl:SetOutlineColor(HexToColor("#000000"))
        lbl:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
        lbl:SetMouseVisible(false)
        lbl:SetVisible(false)
        item.lbl = lbl
        for _, ic in ipairs({ item.iconB, item.iconE }) do
            ic:SetMouseVisible(true)
            ic.MouseEnter = function() this:_enterItem(item) end
            ic.MouseLeave = function()
                if this.hoverItem == item then this:_leaveItem() end
            end
            ic.MouseClick = function(sender, args)
                if IsRight(args) then this:Back() end
            end
        end
        self.bossPool[i] = item
    end
end

function ZV:_fillBosses()
    for _, item in ipairs(self.bossPool or {}) do
        if item.vis then
            item.vis = false
            item.poi = false
            item.qcount = 0
            item.iconB:SetVisible(false)
            item.iconE:SetVisible(false)
            item.lbl:SetVisible(false)
            item.qarrow:SetVisible(false)
            item.qaura:SetVisible(false)
        end
    end
    local D = WorldMapAddon.InstanceData
    local list = D ~= nil and D.Boss ~= nil and self:_isInstMap(self.mapId) and D.Boss[self.mapId] or nil
    -- v3.7.1: solo jefes con nombre (los elites / monstruos sin nombre no se
    -- usan). La flecha sale sobre el jefe si una mision activa lo nombra.
    local showB, showE = FilterOn("jef"), false
    if list == nil or (not showB and not showE) then
        return
    end
    if self.bossPool == nil or #self.bossPool < math.min(#list, BOSS_MAX) then
        self:_buildBossPool(#list)
    end
    local i = 0
    for _, b in ipairs(list) do
        local elite = (b[6] == "e")
        if (elite and showE) or (not elite and showB) then
        i = i + 1
        local item = self.bossPool[i]
        if item == nil then break end
        item.elite = elite
        item.icon = elite and item.iconE or item.iconB
        local x = math.floor(b[1] - (elite and ELITE_TX or BOSS_TX) + 0.5)
        local y = math.floor(b[2] - (elite and ELITE_TY or BOSS_TY) + 0.5)
        item.poi = b
        item.x, item.y = x, y
        item.icon:SetPosition(x, y)
        item.icon:SetVisible(not elite)
        if not elite then
            local names = Split(self.lang and b[4] or b[3])
            local txt = names[1] or ""
            if #names > 1 then txt = txt .. " +" .. (#names - 1) end
            item.lbl:SetText(txt)
            item.lbl:SetPosition(math.floor(b[1] - 80), b[2] + 2)
            item.lbl:SetVisible(true)
        end
        item.vis = true
        end
    end
    self:_refreshBossArrows()
end

-- cuantas misiones activas nombran a este jefe (cache por recuento)
function ZV:_bossQuests(en, es)
    self.bossQCache = self.bossQCache or {}
    local key = tostring(en) .. "|" .. tostring(es)
    local c = self.bossQCache[key]
    if c ~= nil then
        return #c, c
    end
    c = {}
    local Q = WorldMapAddon.Quests
    if Q ~= nil and Q.QuestsNaming ~= nil then
        local names = {}
        for _, n in ipairs(Split(en)) do names[#names + 1] = n end
        for _, n in ipairs(Split(es)) do names[#names + 1] = n end
        local ok, list = pcall(Q.QuestsNaming, names)
        if ok and type(list) == "table" then c = list end
    end
    self.bossQCache[key] = c
    return #c, c
end

function ZV:_refreshBossArrows()
    for _, item in ipairs(self.bossPool or {}) do
        local n = 0
        if item.vis and item.poi ~= false and FilterOn("mis") then
            n = self:_bossQuests(item.poi[3], item.poi[4])
        end
        item.qcount = n
        item.qarrow:SetVisible(n > 0)
        item.qaura:SetVisible(n > 0)
    end
end

function ZV:_bossTip(item)
    local b = item.poi
    local es = self.lang
    local lines = {}
    local ens, ess, rooms = Split(b[3]), Split(b[4]), Split(b[5])
    for i, en in ipairs(ens) do
        local e = ess[i] or en
        local line = es and ((e ~= en) and (e .. " (" .. en .. ")") or e) or en
        if item.elite then
            line = tostring(rooms[i] or "1") .. " x " .. line
        elseif rooms[i] ~= nil and rooms[i] ~= "" then
            line = line .. " - " .. rooms[i]
        end
        lines[#lines + 1] = line
    end
    local n, qs = self:_bossQuests(b[3], b[4])
    if n > 0 then
        lines[#lines + 1] = es and "Misi\195\179n activa:" or "Active quest:"
        for i, q in ipairs(qs) do
            if i > 4 then break end
            lines[#lines + 1] = "- " .. ((es and q.es or q.en) or "")
        end
    end
    lines[#lines + 1] = es and "(posici\195\179n del marcador del juego)" or "(game marker position)"
    if item.elite then
        return (es and "Monstruos \195\169lite" or "Elite monsters"), lines
    end
    return (es and "Jefe" or "Boss"), lines
end
