-- WorldMap_Addon/worldmap_mecanicas.lua
--
-- v3.17 "Mecanicas de jefe" (reemplaza las senales con contadores de la v3.16).
-- Al pelear con un jefe muestra SOLO sus mecanicas que tocan a tu rol
-- (tanque, DPS o sanador): que esquivar, a quien curar, cuando interrumpir,
-- cuando usar defensas y de que tener cuidado. Iconos pequenos con aura que
-- se mueven y brillan cuando la mecanica llega.
--
-- Datos (generados, carpeta mecanicas/): BossCodex (Arebel) = habilidades de
-- cada jefe con area, objetivo, lanzamiento, efectos curables, iconos y gritos;
-- PrimePlugins RaidTools = avisos hechos a mano por gritos del jefe, efectos en
-- ti o en tu grupo y golpes enemigos.
--
-- Deteccion (solo por eventos; nada de sondeos):
--   * objetivo: el nombre del jefe dice la mazmorra/incursion; se carga solo esa
--   * efectos en ti y en tu comunidad: por icono (sirve con cliente en espanol)
--     y por nombre (avisos de Prime)
--   * chat (si Quest Assistant reparte el chat): gritos del jefe y golpes
--   * combate: el aura avisa antes de que llegue (primer uso y reutilizacion)
--
-- Modelos: 1 Auras (fila de iconos), 2 Lista (icono + accion + nombre),
-- 3 Flotantes (los avisos suben y se desvanecen), 4 Central (aviso grande).
--
-- Rendimiento: controles creados una vez y reutilizados; rutas de imagen y
-- textos calculados al asignar, nunca por cuadro; animacion a 20 cuadros/s
-- solo mientras algo se mueve, si no 4 veces/s; sin jefe no hace nada.

import "Turbine"
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WorldMapAddon = _G.WorldMapAddon or {}

local B = {}
WorldMapAddon.Boss = B

local RES = "WorldMap_Addon/assets/worldmap/icon/"
local SAVE_KEY = "WorldMap_Mecanicas"
local FAST, SLOW = 0.05, 0.25
local MAX_SLOTS = 12
local SIZES = { 16, 24, 32, 40 }
local END_DELAY = 8        -- s fuera de combate para dar por terminado el combate
local ACTIVE_TIME = 3      -- s que una mecanica detectada queda encendida
local BOUNCE_TIME = 1.2
local SOON = 5             -- s antes de su uso: el aura empieza a girar
local FLOAT_TIME = 2.8
local FLOAT_RISE = 80
local ALERT_TIME = 3
local MAX_FLOATS = 5
local REPEAT_WINDOW = 1.5  -- s: el mismo aviso se agrupa (x2, x3...)

local function DB()
    return WorldMapAddon.BossDB
end

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

local function L(es, en)
    if IsES() then
        return es
    end
    return en
end

local function Now()
    return Turbine.Engine.GetGameTime()
end

local function Report(err)
    if B._reported then
        return
    end
    B._reported = true
    pcall(Turbine.Shell.WriteLine, "<rgb=#FF6060>Mapa del Mundo (mec\195\161nicas de jefe): " .. tostring(err) .. "</rgb>")
end

-- eventos compartidos (funcion o tabla de funciones); nunca se pisan
local function AddCallback(obj, ev, fn)
    local cur = obj[ev]
    if cur == nil then
        obj[ev] = fn
    elseif type(cur) == "table" then
        table.insert(cur, fn)
    else
        obj[ev] = { cur, fn }
    end
    return fn
end

local function RemoveCallback(obj, ev, fn)
    if obj == nil or fn == nil then
        return
    end
    local cur = obj[ev]
    if cur == fn then
        obj[ev] = nil
    elseif type(cur) == "table" then
        for i = #cur, 1, -1 do
            if cur[i] == fn then
                table.remove(cur, i)
            end
        end
    end
end

local function EnsureCallback(obj, ev, fn)
    if obj == nil or fn == nil then
        return
    end
    local cur = obj[ev]
    if cur == fn then
        return
    end
    if type(cur) == "table" then
        for i = 1, #cur do
            if cur[i] == fn then
                return
            end
        end
    end
    AddCallback(obj, ev, fn)
end

-- misma normalizacion que el generador
local function Norm(text)
    local s = tostring(text or ""):lower()
    s = s:gsub("<[^>]*>", " ")
    -- puntuacion UTF-8 (\226\128\166 \226\128\153 \194\161 \194\191 ...) = espacio, igual que el generador
    s = s:gsub("\226\128[\128-\191]", " "):gsub("\194[\161\171\187\191]", " ")
    s = s:gsub("[^a-z0-9\128-\255]", " ")
    s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    return s
end

local function EffectKey(name)
    return (Norm(name):gsub(" %d+$", ""))
end

-- ---------------------------------------------------------------------
-- Mecanicas: etiqueta -> icono y categoria (accion)
-- ---------------------------------------------------------------------
local CAT = {
    e = { es = "ESQUIVA", en = "DODGE", rgb = { 1.00, 0.62, 0.20 } },
    s = { es = "SEP\195\129RATE", en = "SPREAD", rgb = { 1.00, 0.86, 0.25 } },
    g = { es = "AGR\195\154PATE", en = "STACK", rgb = { 0.35, 0.90, 0.85 } },
    i = { es = "INTERRUMPE", en = "INTERRUPT", rgb = { 0.80, 0.55, 1.00 } },
    c = { es = "CURA", en = "CURE", rgb = { 0.45, 0.95, 0.50 } },
    d = { es = "DEFENSIVO", en = "DEFENSIVE", rgb = { 1.00, 0.40, 0.35 } },
    a = { es = "CUIDADO", en = "CAREFUL", rgb = { 0.55, 0.75, 1.00 } },
}
for _, c in pairs(CAT) do
    c.color = Turbine.UI.Color(1, c.rgb[1], c.rgb[2], c.rgb[3])
end

-- t = consejo; tt / th = consejo para tanque / sanador cuando cambia
local TAG = {
    I = { g = "interrupt", c = "i", es = "Interrumpe su lanzamiento", en = "Interrupt the cast" },
    C = { g = "cone", c = "e", es = "No te quedes delante del jefe", en = "Don't stand in front of the boss",
        tes = "Gira al jefe lejos del grupo", ten = "Turn the boss away from the group" },
    A = { g = "aoe", c = "e", es = "Al\195\169jate del jefe", en = "Move away from the boss" },
    L = { g = "line", c = "e", es = "Sal de la l\195\173nea", en = "Step out of the line" },
    Z = { g = "puddle", c = "e", es = "Sal de la zona marcada", en = "Move out of the marked area" },
    S = { g = "spread", c = "s", es = "Sep\195\161rate del grupo", en = "Spread out from the group" },
    G = { g = "stack", c = "g", es = "J\195\186ntense para repartir el da\195\177o", en = "Stack to share the damage" },
    K = { g = "stun", c = "a", es = "Aturde, derriba o inmoviliza", en = "Stuns, knocks down or roots" },
    F = { g = "fear", c = "c", es = "Quita el miedo", en = "Remove the fear" },
    W = { g = "wound", c = "c", es = "Quita la herida", en = "Remove the wound" },
    P = { g = "poison", c = "c", es = "Quita el veneno", en = "Remove the poison" },
    D = { g = "disease", c = "c", es = "Quita la enfermedad", en = "Remove the disease" },
    Y = { g = "cure", c = "c", es = "Quita el efecto", en = "Remove the debuff" },
    T = { g = "tank", c = "d", es = "Golpe fuerte al tanque", en = "Big hit on the tank",
        tes = "Golpe fuerte: usa una defensa", ten = "Big hit: use a defensive",
        hes = "Golpe fuerte al tanque: prec\195\186ralo", hen = "Big hit on the tank: pre-heal" },
    R = { g = "threat", c = "d", es = "Borra la amenaza: cuidado con el aggro", en = "Threat wipe: watch your aggro",
        tes = "Borra la amenaza: vuelve a provocar", ten = "Threat wipe: taunt again" },
    E = { g = "enrage", c = "d", es = "Se enfurece: m\195\161s da\195\177o", en = "Enrage: more damage",
        tes = "Se enfurece: usa defensas", ten = "Enrage: use defensives" },
    H = { g = "heal", c = "a", es = "El jefe se cura", en = "The boss heals itself" },
    B = { g = "shield", c = "a", es = "Escudo o reflejo: para o cambia de objetivo", en = "Shield or reflect: stop or switch" },
    X = { g = "corrupt", c = "a", es = "Quita sus corrupciones", en = "Remove its corruptions" },
    Q = { g = "warn", c = "a", es = "Atento a esta mec\195\161nica", en = "Watch this mechanic" },
}

-- lo que ve cada rol, en orden de importancia
local ROLE_TAGS = {
    t = "TREKCALZGSIQB",
    d = "ICALZSGXBHKQER",
    h = "FWPDYTALZSGCKQE",
    a = "ITRFWPDYCALZSGKEHBXQ",
}
local ROLE_NAMES = {
    { es = "Autom\195\161tico", en = "Automatic" },
    { es = "Tanque", en = "Tank" },
    { es = "DPS", en = "DPS" },
    { es = "Sanador", en = "Healer" },
    { es = "Todos", en = "All" },
}
local MODEL_NAMES = {
    { es = "Auras", en = "Auras" },
    { es = "Lista", en = "List" },
    { es = "Flotantes", en = "Floating" },
    { es = "Central", en = "Center" },
}

local function TagTip(tag, role)
    local t = TAG[tag]
    if t == nil then
        return ""
    end
    if role == "t" and t.tes ~= nil then
        return L(t.tes, t.ten)
    end
    if role == "h" and t.hes ~= nil then
        return L(t.hes, t.hen)
    end
    return L(t.es, t.en)
end

local function ClassRole()
    local ok, role = pcall(function()
        local cls = Turbine.Gameplay.LocalPlayer.GetInstance():GetClass()
        local C = Turbine.Gameplay.Class
        if cls == C.Guardian or cls == C.Warden or (C.Brawler ~= nil and cls == C.Brawler) then
            return "t"
        end
        if cls == C.Minstrel or cls == C.RuneKeeper or (C.Beorning ~= nil and cls == C.Beorning) then
            return "h"
        end
        return "d"
    end)
    if ok and role ~= nil then
        return role
    end
    return "d"
end

-- ---------------------------------------------------------------------
-- Opciones (por cuenta)
-- ---------------------------------------------------------------------
local DEFAULTS = {
    enabled = true,
    model = 1,
    size = 24,
    role = 1,
    maxIcons = 8,
    alerts = true,     -- aviso grande al detectar (modelos Auras y Lista)
    soon = true,       -- el aura gira antes de que llegue
    onlyCombat = false,
    locked = false,
    opacity = 100,
    x = -1, y = -1,
    ax = -1, ay = -1,
}
local CHOICES = {
    model = { 1, 2, 3, 4 },
    size = SIZES,
    role = { 1, 2, 3, 4, 5 },
    maxIcons = { 4, 6, 8, 10, 12 },
    opacity = { 100, 85, 70, 55 },
}

B.values = {}

function B.Get(key)
    local v = B.values[key]
    if v == nil then
        return DEFAULTS[key]
    end
    return v
end

local function ValidValue(key, v)
    local d = DEFAULTS[key]
    if d == nil then
        return false
    end
    if type(d) == "boolean" then
        return type(v) == "boolean"
    end
    v = tonumber(v)
    if v == nil then
        return false
    end
    local list = CHOICES[key]
    if list == nil then
        return true
    end
    for _, c in ipairs(list) do
        if c == v then
            return true
        end
    end
    return false
end

local function SaveValues()
    local data = {}
    for k in pairs(DEFAULTS) do
        if B.values[k] ~= nil then
            data[k] = B.values[k]
        end
    end
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, SAVE_KEY, data)
end

function B.Set(key, v, noSave)
    if not ValidValue(key, v) then
        return
    end
    if type(DEFAULTS[key]) == "number" then
        v = math.floor(tonumber(v))
    end
    B.values[key] = v
    if noSave ~= true then
        SaveValues()
    end
    B.Refresh()
end

local function LoadValues()
    local answered = false
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Account, SAVE_KEY, function(data)
        if answered then
            return
        end
        answered = true
        if type(data) == "table" then
            for k in pairs(DEFAULTS) do
                local v = data[k]
                if v ~= nil and ValidValue(k, v) then
                    if type(DEFAULTS[k]) == "number" then
                        v = math.floor(tonumber(v))
                    end
                    B.values[k] = v
                end
            end
        end
        pcall(B.Refresh)
    end)
end

local function Role()
    local r = B.Get("role")
    if r == 2 then return "t" end
    if r == 3 then return "d" end
    if r == 4 then return "h" end
    if r == 5 then return "a" end
    return ClassRole()
end

-- primera etiqueta de la mecanica que le importa al rol
local CURE_TAGS = { "F", "W", "P", "D", "Y" }
local function CureTag(tags)
    for _, t in ipairs(CURE_TAGS) do
        if string.find(tags, t, 1, true) ~= nil then
            return t
        end
    end
    return nil
end

local function Primary(tags, role)
    local order = ROLE_TAGS[role] or ROLE_TAGS.a
    for i = 1, #order do
        local t = string.sub(order, i, i)
        if string.find(tags, t, 1, true) ~= nil then
            return t
        end
    end
    return nil
end

-- ---------------------------------------------------------------------
-- Imagenes (rutas armadas una sola vez)
-- ---------------------------------------------------------------------
local GLYPH_IMG = {}
local function GlyphImg(g, sz)
    local bySize = GLYPH_IMG[g]
    if bySize == nil then
        bySize = {}
        GLYPH_IMG[g] = bySize
    end
    local p = bySize[sz]
    if p == nil then
        p = RES .. "mj_" .. g .. "_" .. sz .. ".tga"
        bySize[sz] = p
    end
    return p
end

local AURA_IMG = {}
local function AuraFrames(c, sz)
    local byCat = AURA_IMG[c]
    if byCat == nil then
        byCat = {}
        AURA_IMG[c] = byCat
    end
    local f = byCat[sz]
    if f == nil then
        f = {}
        for k = 1, 4 do
            f[k] = RES .. "mj_aura_" .. c .. "_" .. sz .. "_" .. k .. ".tga"
        end
        byCat[sz] = f
    end
    return f
end

local function AuraPad(sz)
    return math.max(3, math.floor(sz * 0.25 + 0.5))
end

-- ---------------------------------------------------------------------
-- Datos
-- ---------------------------------------------------------------------
local function LoadInstance(key)
    local db = DB()
    if db == nil or db.inst == nil then
        return nil
    end
    if db.inst[key] == nil then
        pcall(import, "WorldMap_Addon.mecanicas.mj_" .. key)
    end
    return db.inst[key]
end

local function InstanceInfo(key)
    local db = DB()
    if db == nil or db.instances == nil then
        return nil
    end
    for _, it in ipairs(db.instances) do
        if it.k == key then
            return it
        end
    end
    return nil
end

local function FindBoss(name)
    local db = DB()
    if db == nil or db.names == nil then
        return nil
    end
    local nk = Norm(name)
    if nk == "" then
        return nil
    end
    local hit = db.names[nk]
    if hit ~= nil then
        return hit[1], hit[2]
    end
    if #nk < 5 then
        return nil
    end
    -- nombre con titulo traducido ("Comandante Mornang"): palabra propia
    -- que solo tiene un jefe
    if db.tok ~= nil then
        for w in string.gmatch(nk, "%S+") do
            local t = db.tok[w]
            if t ~= nil then
                return t[1], t[2]
            end
        end
    end
    -- nombre del jefe dentro del objetivo ("... (Elite)"); nunca al reves,
    -- asi "Spider" no activa "Spider Queen"
    local best, bestLen = nil, 0
    for key, v in pairs(db.names) do
        local len = #key
        if len >= 8 and len > bestLen and string.find(nk, key, 1, true) ~= nil then
            best, bestLen = v, len
        end
    end
    if best ~= nil then
        return best[1], best[2]
    end
    return nil
end

-- ---------------------------------------------------------------------
-- Jefe activo
-- ---------------------------------------------------------------------
-- B.cur = { key, idx, name, inst, m = {mecanicas}, names, yells, icons,
--           fxi = {[clave efecto] = i}, prim = {[i] = etiqueta}, rel = {i...},
--           ready = {[i] = momento}, act = {[i] = momento}, pulled }
B.cur = nil
B.inCombat = false
B.endAt = nil

local function BuildRelevant(cur)
    local role = Role()
    cur.role = role
    cur.rel = {}
    cur.prim = {}
    local order = ROLE_TAGS[role] or ROLE_TAGS.a
    -- por importancia de la etiqueta principal (orden estable: no salta)
    for k = 1, #order do
        local t = string.sub(order, k, k)
        for i, m in ipairs(cur.m) do
            if cur.prim[i] == nil and Primary(m[2], role) == t then
                cur.prim[i] = t
                cur.rel[#cur.rel + 1] = i
            end
        end
    end
end

function B.Activate(instKey, idx)
    local data = LoadInstance(instKey)
    if data == nil or data[idx] == nil then
        return false
    end
    if B.cur ~= nil and B.cur.key == instKey and B.cur.idx == idx then
        return true
    end
    local rec = data[idx]
    local cur = {
        key = instKey, idx = idx, name = rec[1], inst = InstanceInfo(instKey),
        m = {}, names = {}, yells = {}, icons = {}, fxi = {}, ready = {}, act = {},
        ann = {}, pulled = false,
    }
    for i, s in ipairs(rec[2]) do
        cur.m[i] = s
    end
    -- avisos por efecto de esta misma instancia (Prime) entran en la lista
    local db = DB()
    if db ~= nil and type(db.fx) == "table" then
        for k, fx in pairs(db.fx) do
            if fx[5] == instKey then
                local n = #cur.m + 1
                cur.m[n] = { fx[4], fx[2], 0, 0, fx[6] ~= nil and { fx[6] } or nil, nil, fx[3], nil, nil, nil, fx[7], fx = fx }
                cur.fxi[k] = n
            end
        end
    end
    for i, s in ipairs(cur.m) do
        -- nombres cortos ("Bite") darian falsos avisos: solo por icono
        -- (los avisos de Prime y de efectos no se buscan por nombre en el chat)
        -- (tal cual las escribe el juego: asi el chat de combate no se copia
        -- en minusculas en cada linea)
        if s.fx == nil and s[8] ~= true then
            local nm = s[1]
            if #nm >= 5 then
                cur.names[#cur.names + 1] = { nm, i }
            end
            -- nombre que muestra el parche de traduccion al espanol
            if type(s[9]) == "table" then
                for _, es in ipairs(s[9]) do
                    if #es >= 5 then
                        cur.names[#cur.names + 1] = { es, i }
                    end
                end
            end
        end
        if type(s[5]) == "table" then
            for _, ic in ipairs(s[5]) do
                if cur.icons[ic] == nil then
                    cur.icons[ic] = i
                end
            end
        end
        if type(s[6]) == "table" then
            for _, y in ipairs(s[6]) do
                cur.yells[#cur.yells + 1] = { y, i }
            end
        end
    end
    -- el nombre mas largo primero ("Claw Swipe" antes que "Claw")
    table.sort(cur.names, function(a, b) return #a[1] > #b[1] end)
    BuildRelevant(cur)
    B.cur = cur
    B.endAt = nil
    B.idleAt = nil
    if B.inCombat then
        B.StartPull()
    end
    B.HookParty()
    B.Refresh()
    return true
end

function B.Clear()
    B.cur = nil
    B.endAt = nil
    B.idleAt = nil
    B.lastTargetName = nil
    B.UnhookParty()
    B.HideTip()
    B.Refresh()
end

function B.StartPull()
    local cur = B.cur
    if cur == nil or cur.pulled then
        return
    end
    cur.pulled = true
    local now = Now()
    for i, s in ipairs(cur.m) do
        local icd = tonumber(s[4]) or 0
        cur.ready[i] = icd > 0 and (now + icd) or nil
        cur.act[i] = nil
    end
    B.HookParty()
end

-- ---------------------------------------------------------------------
-- Avisos: flotantes y aviso grande
-- ---------------------------------------------------------------------
local TEXT = Turbine.UI.Color(1, 0.95, 0.91, 0.82)
local GOLD = Turbine.UI.Color(1, 0.79, 0.65, 0.42)
local SUBTLE = Turbine.UI.Color(1, 0.80, 0.78, 0.72)
local HEAD_BG = Turbine.UI.Color(0.70, 0.06, 0.05, 0.03)
local ROW_BG = Turbine.UI.Color(0.55, 0.05, 0.04, 0.03)
local CLEAR = Turbine.UI.Color(0, 0, 0, 0)
local TIP_BG = Turbine.UI.Color(0.94, 0.07, 0.06, 0.04)
local BLACK = Turbine.UI.Color(1, 0, 0, 0)

local function F(...)
    local FT = Turbine.UI.Lotro.Font
    for _, n in ipairs({ ... }) do
        if FT[n] ~= nil then
            return FT[n]
        end
    end
    return FT.Verdana12
end

local function FontFor(size)
    if size >= 32 then
        return F("Verdana16", "Verdana14")
    elseif size >= 24 then
        return F("Verdana14", "Verdana12")
    end
    return F("Verdana12", "Verdana10")
end

local function NewImg(parent)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    pcall(c.SetBlendMode, c, Turbine.UI.BlendMode.AlphaBlend)
    pcall(c.SetBackColorBlendMode, c, Turbine.UI.BlendMode.AlphaBlend)
    return c
end

local function NewLabel(parent, font, align)
    local l = Turbine.UI.Label()
    l:SetParent(parent)
    l:SetMouseVisible(false)
    pcall(l.SetSelectable, l, false)
    l:SetFont(font)
    l:SetForeColor(TEXT)
    l:SetFontStyle(Turbine.UI.FontStyle.Outline)
    l:SetOutlineColor(BLACK)
    l:SetTextAlignment(align or Turbine.UI.ContentAlignment.MiddleLeft)
    return l
end

-- quita el "on:" / "de:" / "en:" final de los avisos de Prime ("Cure Poison on:")
local function Clean(t)
    t = tostring(t or ""):gsub("%s+[Oo]n!?:?%s*$", "")
    local base = string.match(t, "^(.-)%s*:%s*$")
    if base ~= nil then
        t = base:gsub("%s+[Oo]n!?$", ""):gsub("%s+en$", ""):gsub("%s+de$", ""):gsub("%s+a$", "")
    end
    return t
end

-- nombre y aviso de una mecanica en el idioma del addon (los avisos de Prime
-- traen su traduccion; los nombres de habilidad quedan como los muestra el juego)
local function MechName(m)
    if IsES() then
        if m[10] ~= nil then
            return m[10]
        end
        -- nombre que usa el juego en espanol (primera variante)
        local es = m[9]
        if type(es) == "table" and type(es[1]) == "string" and es[1] ~= "" then
            return es[1]
        end
    end
    return m[1]
end

local function MechTip(m)
    if m[11] ~= nil and IsES() then
        return m[11]
    end
    return m[7]
end

local function FxTitle(fx)
    if fx[7] ~= nil and IsES() then
        return fx[7]
    end
    return fx[3]
end

-- texto de un aviso: accion, nombre (+ a quien), consejo
local function Describe(tag, name, tip, who)
    local t = TAG[tag] or TAG.Q
    local c = CAT[t.c]
    local word = L(c.es, c.en)
    local line = Clean(name)
    if who ~= nil and who ~= "" then
        line = line .. "  \226\134\146 " .. who
    end
    return word, c.color, line, tip
end

local function AnchorXY(w, h)
    local x, y = B.Get("ax"), B.Get("ay")
    if x < 0 or y < 0 then
        x = math.floor((Turbine.UI.Display.GetWidth() - w) / 2)
        y = math.floor(Turbine.UI.Display.GetHeight() * 0.28)
    end
    return x, y
end

-- flotantes: suben y se desvanecen
B.floats = {}

local function NewFloat()
    local f = {}
    local w = Turbine.UI.Window()
    w:SetMouseVisible(false)
    w:SetBackColor(CLEAR)
    pcall(w.SetZOrder, w, 55)
    w:SetVisible(false)
    f.win = w
    f.aura = NewImg(w)
    f.icon = NewImg(w)
    f.word = NewLabel(w, F("TrajanProBold16", "Verdana16", "Verdana14"))
    f.line = NewLabel(w, F("Verdana12", "Verdana10"))
    return f
end

local function PlaceFloat(f, sz)
    if f.sz == sz then
        return
    end
    f.sz = sz
    local p = AuraPad(sz)
    local full = sz + 2 * p
    f.full = full
    f.win:SetSize(full + 260, full)
    f.aura:SetPosition(0, 0)
    f.aura:SetSize(full, full)
    f.icon:SetPosition(p, p)
    f.icon:SetSize(sz, sz)
    local half = math.floor(full / 2)
    f.word:SetPosition(full + 4, half - 18)
    f.word:SetSize(256, 18)
    f.line:SetPosition(full + 4, half)
    f.line:SetSize(256, 16)
end

function B.ShowFloat(key, tag, name, tip, who)
    local now = Now()
    local sz = math.max(24, B.Get("size"))
    -- el mismo aviso seguido se agrupa
    for _, f in ipairs(B.floats) do
        if f.t0 ~= nil and f.key == key and now - f.t0 < REPEAT_WINDOW then
            f.count = f.count + 1
            f.line:SetText(f.text .. "  (x" .. f.count .. ")")
            f.t0 = now
            return
        end
    end
    local slot, oldest = nil, nil
    for _, f in ipairs(B.floats) do
        if f.t0 == nil then
            slot = f
            break
        end
        if oldest == nil or f.t0 < oldest.t0 then
            oldest = f
        end
    end
    if slot == nil then
        if #B.floats < MAX_FLOATS then
            slot = NewFloat()
            B.floats[#B.floats + 1] = slot
        else
            slot = oldest
        end
    end
    local t = TAG[tag] or TAG.Q
    local word, color, line = Describe(tag, name, tip, who)
    PlaceFloat(slot, sz)
    slot.frames = AuraFrames(t.c, sz)
    slot.frame = nil
    slot.icon:SetBackground(GlyphImg(t.g, sz))
    slot.word:SetText(word)
    slot.word:SetForeColor(color)
    slot.text = line
    slot.line:SetText(line)
    slot.key = key
    slot.count = 1
    -- se apilan hacia abajo si salen varios a la vez
    local busy = 0
    for _, f in ipairs(B.floats) do
        if f ~= slot and f.t0 ~= nil and now - f.t0 < 0.9 then
            busy = busy + 1
        end
    end
    local ax, ay = AnchorXY(slot.full + 260, slot.full)
    slot.x0 = ax
    slot.y0 = ay + busy * (slot.full + 4)
    slot.t0 = now
    slot.op = nil
    slot.win:SetPosition(slot.x0, slot.y0)
    pcall(slot.win.SetOpacity, slot.win, 0)
    slot.win:SetVisible(true)
end

-- aviso grande (un solo cartel; uno nuevo reemplaza al anterior)
local function BuildAlert()
    local a = {}
    local w = Turbine.UI.Window()
    w:SetSize(420, 72)
    w:SetMouseVisible(false)
    w:SetBackColor(Turbine.UI.Color(0.62, 0.04, 0.03, 0.02))
    pcall(w.SetZOrder, w, 60)
    w:SetVisible(false)
    a.win = w
    local p = AuraPad(48)
    a.aura = NewImg(w)
    a.aura:SetPosition(0, 0)
    a.aura:SetSize(48 + 2 * p, 48 + 2 * p)
    a.icon = NewImg(w)
    a.icon:SetPosition(p, p)
    a.icon:SetSize(48, 48)
    local x = 48 + 2 * p + 6
    a.word = NewLabel(w, F("TrajanProBold22", "TrajanProBold16", "Verdana18", "Verdana16"))
    a.word:SetPosition(x, 4)
    a.word:SetSize(420 - x - 6, 26)
    a.line = NewLabel(w, F("Verdana14", "Verdana12"))
    a.line:SetPosition(x, 30)
    a.line:SetSize(420 - x - 6, 18)
    a.tip = NewLabel(w, F("Verdana12", "Verdana10"))
    a.tip:SetPosition(x, 49)
    a.tip:SetSize(420 - x - 6, 16)
    a.tip:SetForeColor(SUBTLE)
    B.alert = a
    return a
end

function B.ShowAlert(key, tag, name, tip, who)
    local a = B.alert or BuildAlert()
    local now = Now()
    if a.t0 ~= nil and a.key == key and now - a.t0 < REPEAT_WINDOW then
        a.count = a.count + 1
        a.line:SetText(a.text .. "  (x" .. a.count .. ")")
        a.t0 = now
        return
    end
    local t = TAG[tag] or TAG.Q
    local word, color, line = Describe(tag, name, tip, who)
    a.frames = AuraFrames(t.c, 48)
    a.frame = nil
    a.icon:SetBackground(GlyphImg(t.g, 48))
    a.word:SetText(word)
    a.word:SetForeColor(color)
    a.text = line
    a.line:SetText(line)
    a.tip:SetText(tip or "")
    a.key = key
    a.count = 1
    local x, y = AnchorXY(420, 72)
    a.x0, a.y0 = x, y
    a.t0 = now
    a.op = nil
    a.win:SetPosition(x, y)
    pcall(a.win.SetOpacity, a.win, 0)
    a.win:SetVisible(true)
end

-- lanza el aviso segun el modelo
local ANN_GAP = 6        -- s: el mismo aviso no se repite antes (el icono si se enciende)
local ANN_GAP_GROUP = 2.5 -- s: avisos sobre companeros (curar a otro)
B.annFree = {}
local function Announce(key, tag, name, tip, who, gap, force)
    local cur = B.cur
    local ann = cur ~= nil and cur.ann or B.annFree
    if ann ~= nil then
        local now = Now()
        local last = ann[key]
        -- dentro de la ventana corta se agrupa (x2); despues, pausa
        if last ~= nil and now - last >= REPEAT_WINDOW and now - last < (gap or ANN_GAP) then
            return
        end
        if last == nil or now - last >= REPEAT_WINDOW then
            ann[key] = now
        end
    end
    local model = B.Get("model")
    if model == 3 then
        B.ShowFloat(key, tag, name, tip, who)
    elseif model == 4 or force or B.Get("alerts") then
        B.ShowAlert(key, tag, name, tip, who)
    end
end

-- ---------------------------------------------------------------------
-- Disparadores
-- ---------------------------------------------------------------------
-- se detecto la mecanica i; who = nil (lo lanza el jefe), "self" o un nombre
function B.Trigger(i, who)
    local cur = B.cur
    if cur == nil or cur.m[i] == nil then
        return
    end
    local now = Now()
    local m = cur.m[i]
    local last = cur.act[i]
    local cd = tonumber(m[3]) or 0
    cur.ready[i] = cd > 0 and (now + cd) or nil
    cur.pulled = true
    local tag
    if who == nil then
        -- lo lanza el jefe: solo si es de tu rol
        tag = cur.prim[i]
        if tag == nil then
            return
        end
    elseif who == "self" then
        -- te cayo a ti: curable -> CURA; aviso de Prime -> su accion;
        -- otra cosa ya te golpeo: solo se enciende su icono
        tag = CureTag(m[2])
        if tag == nil and m.fx ~= nil then
            tag = cur.prim[i] or Primary(m[2], "a")
        end
        if tag == nil then
            cur.act[i] = now
            return
        end
    else
        -- le cayo a un companero: aviso de grupo de Prime o algo que curar
        if m.fx ~= nil then
            if m.fx[1] ~= "g" then
                return
            end
            tag = cur.prim[i]
        else
            tag = CureTag(m[2])
        end
        if tag == nil then
            return
        end
        if TAG[tag].c == "c" and cur.role ~= "h" and cur.role ~= "a" then
            return
        end
    end
    cur.act[i] = now
    if last ~= nil and now - last < 1 and who == nil then
        return   -- la misma mecanica ya se aviso hace menos de 1 s
    end
    local whoTxt = nil
    if who == "self" then
        whoTxt = L("t\195\186", "you")
    elseif who ~= nil then
        whoTxt = who
    end
    local tip = TagTip(tag, cur.role)
    local mt = MechTip(m)
    if type(mt) == "string" and mt ~= "" then
        tip = tip .. " \194\183 " .. Clean(mt)
    end
    -- sobre un companero: clave aparte (-i) y pausa corta
    if who ~= nil and who ~= "self" then
        Announce(-i, tag, MechName(m), tip, whoTxt, ANN_GAP_GROUP)
    else
        Announce(i, tag, MechName(m), tip, whoTxt)
    end
end

-- aviso de Prime sin mecanica en la lista (efecto o golpe generico)
local function FireFx(fxKey, fx, who)
    local cur = B.cur
    if cur == nil then
        return
    end
    local i = cur.fxi[fxKey]
    if i ~= nil then
        B.Trigger(i, who)
        return
    end
    local tag = Primary(fx[2], cur.role)
    if tag == nil then
        if who ~= "self" then
            return
        end
        tag = Primary(fx[2], "a") or "Q"
    end
    if who ~= nil and who ~= "self" and (fx[1] ~= "g" or (TAG[tag].c == "c" and cur.role ~= "h" and cur.role ~= "a")) then
        return
    end
    local whoTxt = nil
    if who == "self" then
        whoTxt = L("t\195\186", "you")
    elseif who ~= nil then
        whoTxt = who
    end
    if who ~= nil and who ~= "self" then
        Announce(fx, tag, fx[4], TagTip(tag, cur.role) .. " \194\183 " .. Clean(FxTitle(fx)), whoTxt, ANN_GAP_GROUP)
    else
        Announce(fxKey, tag, fx[4], TagTip(tag, cur.role) .. " \194\183 " .. Clean(FxTitle(fx)), whoTxt)
    end
end

-- un efecto aparecio en ti (who = "self") o en un companero (who = nombre)
-- nombre del efecto -> clave de aviso (o false): asi un mismo efecto (los
-- beneficios de la comunidad se repiten mucho) no se normaliza cada vez
local fxNameCache, fxNameCount = {}, 0
local function FxKeyFor(name)
    if type(name) ~= "string" then
        return false
    end
    local k = fxNameCache[name]
    if k == nil then
        local db = DB()
        local key = EffectKey(name)
        k = (db ~= nil and db.fx ~= nil and db.fx[key] ~= nil) and key or false
        if fxNameCount >= 400 then
            fxNameCache, fxNameCount = {}, 0
        end
        fxNameCache[name] = k
        fxNameCount = fxNameCount + 1
    end
    return k
end

local function OnEffect(effect, who)
    local cur = B.cur
    if cur == nil or effect == nil then
        return
    end
    local icon = effect:GetIcon()
    local i = icon ~= nil and cur.icons[icon] or nil
    if i ~= nil then
        B.Trigger(i, who)
        return
    end
    local key = FxKeyFor(effect:GetName())
    if not key then
        return
    end
    local fx = DB().fx[key]
    if fx == nil or fx[1] == "h" then
        return
    end
    -- efectos "de grupo" de Prime tambien valen si te caen a ti
    if fx[1] == "s" and who ~= "self" then
        return
    end
    FireFx(key, fx, who)
end

-- ---------------------------------------------------------------------
-- Panel (modelos Auras y Lista)
-- ---------------------------------------------------------------------
local Panel = {}
Panel.__index = Panel

function Panel.New()
    local self = setmetatable({}, Panel)
    local this = self
    local w = Turbine.UI.Window()
    self.win = w
    w:SetVisible(false)
    w:SetMouseVisible(false)
    w:SetBackColor(CLEAR)
    pcall(w.SetZOrder, w, 50)

    self.head = Turbine.UI.Control()
    self.head:SetParent(w)
    self.head:SetBackColor(HEAD_BG)
    self.head:SetMouseVisible(true)
    self.title = NewLabel(self.head, F("Verdana10", "Verdana12"))
    self.title:SetForeColor(GOLD)
    self.head.MouseDown = function(_, args)
        if B.Get("locked") then
            return
        end
        this.drag = true
        this.dx, this.dy = args.X, args.Y
    end
    self.head.MouseMove = function(_, args)
        if this.drag then
            local x, y = w:GetPosition()
            w:SetPosition(x + args.X - this.dx, y + args.Y - this.dy)
        end
    end
    self.head.MouseUp = function()
        if this.drag then
            this.drag = false
            local x, y = w:GetPosition()
            B.values.x, B.values.y = x, y
            SaveValues()
        end
    end

    self.slots = {}
    for i = 1, MAX_SLOTS do
        local s = {}
        s.bg = NewImg(w)
        s.bg:SetBackColor(ROW_BG)
        s.aura = NewImg(w)
        s.icon = Turbine.UI.Control()
        s.icon:SetParent(w)
        s.icon:SetMouseVisible(true)
        pcall(s.icon.SetBlendMode, s.icon, Turbine.UI.BlendMode.AlphaBlend)
        s.word = NewLabel(w, F("Verdana12", "Verdana10"))
        s.name = NewLabel(w, F("Verdana12", "Verdana10"))
        s.icon.MouseEnter = function()
            B.ShowTip(this, s)
        end
        s.icon.MouseLeave = function()
            B.HideTip()
        end
        s.bg:SetVisible(false)
        s.aura:SetVisible(false)
        s.icon:SetVisible(false)
        s.word:SetVisible(false)
        s.name:SetVisible(false)
        s.shown = false
        self.slots[i] = s
    end
    return self
end

function Panel:Layout(count)
    local model = B.Get("model")
    local size = B.Get("size")
    local p = AuraPad(size)
    local full = size + 2 * p
    local headH = 14
    local textW = math.max(150, size * 7)
    local W, H
    self.model, self.size, self.pad = model, size, p
    if model == 2 then
        W = full + 4 + textW
        H = headH + 2 + count * full
    else
        W = math.max(110, count * full)
        H = headH + 2 + full
    end
    self.head:SetPosition(0, 0)
    self.head:SetSize(W, headH)
    self.title:SetPosition(4, 0)
    self.title:SetSize(W - 8, headH)
    self.win:SetSize(W, H)
    local font = FontFor(size)
    for i = 1, MAX_SLOTS do
        local s = self.slots[i]
        local x, y
        if model == 2 then
            x, y = 0, headH + 2 + (i - 1) * full
            s.bg:SetPosition(0, y + 1)
            s.bg:SetSize(W, full - 2)
            local wordH = math.floor(full / 2)
            s.word:SetFont(font)
            s.word:SetPosition(full + 4, y)
            s.word:SetSize(textW, wordH)
            s.name:SetPosition(full + 4, y + wordH)
            s.name:SetSize(textW, full - wordH)
        else
            x, y = (i - 1) * full, headH + 2
        end
        s.x, s.y = x, y
        s.ox, s.oy = 0, 0
        s.aura:SetPosition(x, y)
        s.aura:SetSize(full, full)
        s.icon:SetPosition(x + p, y + p)
        s.icon:SetSize(size, size)
        s.mech = nil
        s.img = nil
        s.frames = nil
        s.frame = nil
        s.auraOn = false
        s.aura:SetVisible(false)
    end
    self.count = count
end

local function ShowSlot(s, vis, model)
    if s.shown == vis and s.model == model then
        return
    end
    s.shown = vis
    s.model = model
    s.icon:SetVisible(vis)
    local list = vis and model == 2
    s.bg:SetVisible(list)
    s.word:SetVisible(list)
    s.name:SetVisible(list)
    if not vis then
        s.aura:SetVisible(false)
        s.auraOn = false
    end
end

-- ---------------------------------------------------------------------
-- Reloj (animaciones). Devuelve true si algo se mueve.
-- ---------------------------------------------------------------------
local abs, floor, sin, pi = math.abs, math.floor, math.sin, math.pi

local function AnimPanel(now)
    local cur = B.cur
    local p = B.panel
    if cur == nil or p == nil or not p.shown then
        return false
    end
    local moving = false
    local soonOn = B.Get("soon")
    local model = p.model
    local amp = math.max(3, floor(p.size / 4))
    for k = 1, p.count do
        local s = p.slots[k]
        local i = s.mech
        if i ~= nil then
            local act = cur.act[i]
            local state = 0   -- 0 quieto, 1 ya viene, 2 activo
            if act ~= nil and now - act < ACTIVE_TIME then
                state = 2
            elseif soonOn and cur.pulled then
                local r = cur.ready[i]
                if r ~= nil and r - now <= SOON and r - now > -1 then
                    state = 1
                end
            end
            if state == 0 then
                if s.auraOn then
                    s.auraOn = false
                    s.aura:SetVisible(false)
                end
            else
                moving = true
                local fr
                if state == 2 then
                    fr = floor(now * 12) % 4 + 1
                else
                    fr = floor(now * 5) % 4 + 1
                end
                if fr ~= s.frame then
                    s.frame = fr
                    s.aura:SetBackground(s.frames[fr])
                end
                if not s.auraOn then
                    s.auraOn = true
                    s.aura:SetVisible(true)
                end
            end
            -- rebote al detectarse
            local ox, oy = 0, 0
            if state == 2 and now - act < BOUNCE_TIME then
                local d = floor(amp * abs(sin((now - act) * pi * 3)) + 0.5)
                if model == 2 then
                    ox = d
                else
                    oy = -d
                end
            end
            if ox ~= s.ox or oy ~= s.oy then
                s.ox, s.oy = ox, oy
                s.aura:SetPosition(s.x + ox, s.y + oy)
                s.icon:SetPosition(s.x + p.pad + ox, s.y + p.pad + oy)
            end
        end
    end
    return moving
end

local function AnimFloats(now)
    local any = false
    local userOp = B.Get("opacity") / 100
    for _, f in ipairs(B.floats) do
        if f.t0 ~= nil then
            local age = now - f.t0
            if age >= FLOAT_TIME then
                f.t0 = nil
                f.win:SetVisible(false)
            else
                any = true
                local y = f.y0 - floor(age / FLOAT_TIME * FLOAT_RISE)
                if y ~= f.y then
                    f.y = y
                    f.win:SetPosition(f.x0, y)
                end
                local op = 1
                if age < 0.15 then
                    op = age / 0.15
                elseif age > FLOAT_TIME - 0.8 then
                    op = (FLOAT_TIME - age) / 0.8
                end
                op = floor(op * userOp * 20 + 0.5) / 20
                if op ~= f.op then
                    f.op = op
                    pcall(f.win.SetOpacity, f.win, op)
                end
                local fr = floor(now * 12) % 4 + 1
                if fr ~= f.frame then
                    f.frame = fr
                    f.aura:SetBackground(f.frames[fr])
                end
            end
        end
    end
    return any
end

local function AnimAlert(now)
    local a = B.alert
    if a == nil or a.t0 == nil then
        return false
    end
    local age = now - a.t0
    if age >= ALERT_TIME then
        a.t0 = nil
        a.win:SetVisible(false)
        return false
    end
    local op = 1
    if age < 0.12 then
        op = age / 0.12
    elseif age > ALERT_TIME - 0.5 then
        op = (ALERT_TIME - age) / 0.5
    end
    op = floor(op * B.Get("opacity") / 100 * 20 + 0.5) / 20
    if op ~= a.op then
        a.op = op
        pcall(a.win.SetOpacity, a.win, op)
    end
    -- sacudida corta al aparecer
    local dx = 0
    if age < 0.5 then
        dx = floor(4 * sin(age * pi * 10) + 0.5)
    end
    if dx ~= a.dx then
        a.dx = dx
        a.win:SetPosition(a.x0 + dx, a.y0)
    end
    local fr = floor(now * 12) % 4 + 1
    if fr ~= a.frame then
        a.frame = fr
        a.aura:SetBackground(a.frames[fr])
    end
    return true
end

function B.Tick(now)
    -- fin de combate (jefe muerto, reinicio o huida)
    if B.endAt ~= nil and now >= B.endAt and not B.inCombat then
        B.endAt = nil
        B.idleAt = now + 120
        local cur = B.cur
        if cur ~= nil then
            cur.pulled = false
            for i in pairs(cur.ready) do cur.ready[i] = nil end
            for i in pairs(cur.act) do cur.act[i] = nil end
        end
        if B.Get("onlyCombat") then
            B.Refresh()
        end
    end
    -- 2 min sin combate y sin apuntar a ese jefe: se quitan sus mecanicas
    -- (al salir de la mazmorra no quedan en pantalla)
    if B.idleAt ~= nil and now >= B.idleAt then
        B.idleAt = nil
        if not B.inCombat and not B.demo and B.cur ~= nil then
            local ok, tname = pcall(function()
                local t = B.player:GetTarget()
                return t ~= nil and t.GetName ~= nil and t:GetName() or nil
            end)
            if not ok or tname == nil or Norm(tname) ~= Norm(B.cur.name) then
                B.Clear()
                return false
            end
        end
    end
    if B.demo then
        B.DemoStep(now)
    end
    local m1 = AnimPanel(now)
    local m2 = AnimFloats(now)
    local m3 = AnimAlert(now)
    return m1 or m2 or m3
end

-- aplica opciones / jefe nuevo
function B.Refresh()
    if B._inited ~= true then
        return
    end
    local ok, err = pcall(function()
        local cur = B.cur
        if cur ~= nil then
            BuildRelevant(cur)
        end
        local model = B.Get("model")
        local show = B.Get("enabled") and cur ~= nil and model <= 2 and #cur.rel > 0
        if show and B.Get("onlyCombat") and not B.inCombat and not B.demo then
            show = false
        end
        local p = B.panel
        if p == nil then
            if not show then
                return
            end
            p = Panel.New()
            B.panel = p
        end
        if show then
            local count = math.min(#cur.rel, B.Get("maxIcons"), MAX_SLOTS)
            p:Layout(math.max(1, count))
            local inst = cur.inst ~= nil and cur.inst.s or ""
            p.title:SetText(cur.name .. (inst ~= "" and ("  \194\183  " .. inst) or ""))
            for k = 1, MAX_SLOTS do
                local s = p.slots[k]
                local i = cur.rel[k]
                if k <= count and i ~= nil then
                    local tag = cur.prim[i]
                    local t = TAG[tag]
                    s.mech = i
                    s.icon:SetBackground(GlyphImg(t.g, p.size))
                    s.frames = AuraFrames(t.c, p.size)
                    if model == 2 then
                        local c = CAT[t.c]
                        s.word:SetText(L(c.es, c.en))
                        s.word:SetForeColor(c.color)
                        s.name:SetText(MechName(cur.m[i]))
                    end
                    ShowSlot(s, true, model)
                else
                    s.mech = nil
                    ShowSlot(s, false, model)
                end
            end
            local x, y = B.Get("x"), B.Get("y")
            if x < 0 or y < 0 then
                x = math.floor(Turbine.UI.Display.GetWidth() / 2) - 150
                y = math.floor(Turbine.UI.Display.GetHeight() * 0.16)
            end
            p.win:SetPosition(x, y)
            pcall(p.win.SetOpacity, p.win, B.Get("opacity") / 100)
        end
        p.shown = show
        p.win:SetVisible(show)
        if not show then
            B.HideTip()
        end
    end)
    if not ok then
        Report(err)
    end
end

-- ---------------------------------------------------------------------
-- Descripcion al pasar el raton por un icono
-- ---------------------------------------------------------------------
function B.ShowTip(panel, s)
    local cur = B.cur
    if cur == nil or s.mech == nil then
        return
    end
    pcall(function()
        local tip = B.tip
        if tip == nil then
            tip = {}
            local w = Turbine.UI.Window()
            w:SetMouseVisible(false)
            w:SetBackColor(TIP_BG)
            pcall(w.SetZOrder, w, 70)
            tip.win = w
            tip.word = NewLabel(w, F("Verdana14", "Verdana12"), Turbine.UI.ContentAlignment.TopLeft)
            tip.word:SetPosition(8, 6)
            tip.word:SetSize(304, 18)
            tip.title = NewLabel(w, F("Verdana12", "Verdana10"), Turbine.UI.ContentAlignment.TopLeft)
            tip.title:SetForeColor(GOLD)
            tip.title:SetPosition(8, 26)
            tip.title:SetSize(304, 16)
            tip.body = NewLabel(w, F("Verdana12", "Verdana10"), Turbine.UI.ContentAlignment.TopLeft)
            tip.body:SetPosition(8, 44)
            tip.body:SetSize(304, 34)
            pcall(tip.body.SetMultiline, tip.body, true)
            w:SetSize(320, 82)
            B.tip = tip
        end
        local i = s.mech
        local m = cur.m[i]
        local tag = cur.prim[i]
        local c = CAT[TAG[tag].c]
        tip.word:SetText(L(c.es, c.en))
        tip.word:SetForeColor(c.color)
        tip.title:SetText(MechName(m))
        local body = TagTip(tag, cur.role)
        local mt = MechTip(m)
        if type(mt) == "string" and mt ~= "" then
            body = body .. "\n" .. Clean(mt)
        end
        tip.body:SetText(body)
        local px, py = panel.win:GetPosition()
        local x = px + s.x
        local y = py + s.y + panel.size + 2 * panel.pad + 4
        if y + 82 > Turbine.UI.Display.GetHeight() then
            y = py - 86
        end
        tip.win:SetPosition(x, y)
        tip.win:SetVisible(true)
    end)
end

function B.HideTip()
    if B.tip ~= nil then
        pcall(B.tip.win.SetVisible, B.tip.win, false)
    end
end

-- ---------------------------------------------------------------------
-- Comunidad / incursion: efectos en los companeros (solo con jefe activo)
-- ---------------------------------------------------------------------
B.partyHooks = {}

function B.UnhookParty()
    for k = #B.partyHooks, 1, -1 do
        local h = B.partyHooks[k]
        pcall(RemoveCallback, h.list, "EffectAdded", h.fn)
        B.partyHooks[k] = nil
    end
end

function B.HookParty()
    B.UnhookParty()
    if B.cur == nil or B.player == nil then
        return
    end
    pcall(function()
        local party = B.player:GetParty()
        if party == nil then
            return
        end
        local me = B.player:GetName()
        local n = party:GetMemberCount()
        for k = 1, n do
            local mbr = party:GetMember(k)
            if mbr ~= nil then
                local name = mbr:GetName()
                if name ~= me then
                    local list = mbr:GetEffects()
                    if list ~= nil then
                        local fn = function(sender, args)
                            local ok, err = pcall(function()
                                OnEffect(sender:Get(args.Index), name)
                            end)
                            if not ok then
                                Report(err)
                            end
                        end
                        AddCallback(list, "EffectAdded", fn)
                        B.partyHooks[#B.partyHooks + 1] = { list = list, fn = fn }
                    end
                end
            end
        end
    end)
end

-- ---------------------------------------------------------------------
-- Eventos del jugador y del chat
-- ---------------------------------------------------------------------
-- dialogo de PNJ: cualquier canal salvo combate y canales de jugadores (el
-- juego no usa siempre el mismo para los gritos de jefe)
local CHAT_YELL, CHAT_HIT, CHAT_CORE = {}, {}, {}
pcall(function()
    local CT = Turbine.ChatType
    local skip = {}
    for _, k in ipairs({ "EnemyCombat", "PlayerCombat", "Death", "Tell", "Fellowship", "Raid", "Kinship",
        "Officer", "World", "Regional", "Trade", "LFF", "Advice", "OOC", "Roleplay", "UserChat1",
        "UserChat2", "UserChat3", "UserChat4", "Quest", "Selling", "Loot" }) do
        if CT[k] ~= nil then
            skip[CT[k]] = true
        end
    end
    for _, v in pairs(CT) do
        if type(v) == "number" and not skip[v] then
            CHAT_YELL[v] = true
        end
    end
    if CT.EnemyCombat ~= nil then
        CHAT_HIT[CT.EnemyCombat] = true
    end
end)
-- seguro: los canales de dialogo conocidos siempre cuentan
pcall(function()
    local CT = Turbine.ChatType
    for _, k in ipairs({ "Say", "Emote", "Standard", "Yell", "Narration", "Unfiltered" }) do
        if CT[k] ~= nil then
            CHAT_YELL[CT[k]] = true
        end
    end
    -- canales donde el jefe tambien "actua" sin comillas ("Umshura tiembla de ira.")
    -- (Standard no: ahi llegan botin y experiencia)
    for _, k in ipairs({ "Say", "Emote", "Yell" }) do
        if CT[k] ~= nil then
            CHAT_CORE[CT[k]] = true
        end
    end
end)

-- texto citado de una linea de dialogo ("Khalnayak dice: '¡El fuego...!'")
local function Quoted(msg)
    local q = string.match(msg, "'(.+)'") or string.match(msg, '"(.+)"')
        or string.match(msg, "\226\128\156(.+)\226\128\157") or string.match(msg, "\194\171(.+)\194\187")
    return q
end

local function HasQuote(msg)
    return string.find(msg, "'", 1, true) ~= nil or string.find(msg, '"', 1, true) ~= nil
        or string.find(msg, "\194\171", 1, true) ~= nil or string.find(msg, "\226\128\156", 1, true) ~= nil
end

-- ---------------------------------------------------------------------
-- Frases oidas y alertas propias.
-- Una frase que no esta en los datos (p.ej. un grito traducido al espanol)
-- NUNCA genera un aviso sola: se anota en "frases oidas" y el jugador decide
-- en la ventana "Alertas propias" cuales avisar y con que accion.
-- ---------------------------------------------------------------------
local HEARD_KEY = "WorldMap_FrasesOidas"
local CUSTOM_KEY = "WorldMap_AlertasPropias"
local MAX_HEARD, MAX_CUSTOM = 80, 100
B.heard = {}    -- { { t = texto, w = quien, k = clave }, ... } (la mas nueva primero)
B.custom = {}   -- { { k = clave, t = texto, c = etiqueta, n = aviso }, ... }
B.heardDirty = false

local function PhraseKey(text)
    return string.sub(Norm(text), 1, 60)
end
B.PhraseKey = PhraseKey

local function NoteHeard(text, who)
    local k = PhraseKey(text)
    if #k < 4 then
        return
    end
    for i = 1, #B.heard do
        local h = B.heard[i]
        if h.k == k then
            if i > 1 then
                table.remove(B.heard, i)
                table.insert(B.heard, 1, h)
            end
            return
        end
    end
    table.insert(B.heard, 1, { t = text, w = who or "", k = k })
    while #B.heard > MAX_HEARD do
        B.heard[#B.heard] = nil
    end
    B.heardDirty = true
end

local function Speaker(args, msg)
    if type(args.Sender) == "string" and args.Sender ~= "" then
        return string.sub(args.Sender, 1, 40)
    end
    local w = string.match(msg, "^([^'\"]-)%s*['\"]")
    if w ~= nil then
        w = w:gsub("<[^>]*>", ""):gsub("%s*[%a\128-\255]*:%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        return string.sub(w, 1, 40)
    end
    return ""
end

local function ShowCustom(a, key)
    local word = a.n ~= nil and a.n ~= "" and a.n or ("\194\171" .. a.t .. "\194\187")
    local tip = a.n ~= nil and a.n ~= "" and ("\194\171" .. a.t .. "\194\187") or L("Alerta propia", "Your alert")
    Announce(key or a, a.c, word, tip, nil, nil, true)
end

-- frase de una alerta propia dentro del mensaje (ya normalizado)
local function CheckCustom(nk)
    local list = B.custom
    for i = 1, #list do
        local a = list[i]
        if string.find(nk, a.k, 1, true) ~= nil then
            ShowCustom(a)
            return true
        end
    end
    return false
end

function B.OnChat(sender, args)
    if args == nil or B.Get("enabled") ~= true then
        return
    end
    local msg = args.Message
    if type(msg) ~= "string" or #msg < 6 then
        return
    end
    local ct = args.ChatType
    local cur = B.cur
    -- golpes del jefe (linea de combate enemigo): solo en combate y con jefe
    if ct == nil or CHAT_HIT[ct] == true then
        if cur ~= nil and B.inCombat then
            local low = msg
            local names = cur.names
            for k = 1, #names do
                local e = names[k]
                if string.find(low, e[1], 1, true) ~= nil then
                    B.Trigger(e[2])
                    return
                end
            end
            -- golpes con aviso de Prime
            local db = DB()
            if db ~= nil and db.fxHit ~= nil then
                for k = 1, #db.fxHit do
                    local h = db.fxHit[k]
                    if string.find(low, h[1], 1, true) ~= nil then
                        FireFx(h[2], db.fx[h[2]], nil)
                        return
                    end
                end
            end
        end
        if ct ~= nil then
            return
        end
    end
    if ct ~= nil and CHAT_YELL[ct] ~= true then
        return
    end
    -- solo dialogo: botin, experiencia y demas lineas del sistema salen aca
    -- sin trabajo (las sin comillas solo importan para los gritos conocidos)
    -- (los gritos llegan entre comillas: "X dice: '...'"; los gestos del
    -- jefe sin comillas solo se miran con jefe activo y en Say/Emote/Yell)
    local quoted = HasQuote(msg)
    if not quoted and not (cur ~= nil and #cur.yells > 0 and CHAT_CORE[ct] == true) then
        return
    end
    local nk = Norm(msg)
    -- 1) gritos conocidos del jefe (BossCodex / Prime)
    if cur ~= nil then
        local yells = cur.yells
        for k = 1, #yells do
            local y = yells[k]
            if string.find(nk, y[1], 1, true) ~= nil then
                B.Trigger(y[2])
                return
            end
        end
    end
    if not quoted then
        return
    end
    -- 2) alertas propias del jugador
    if #B.custom > 0 and CheckCustom(nk) then
        return
    end
    -- 3) frase desconocida: se anota sin avisar (solo en combate o con jefe)
    if B.inCombat or cur ~= nil then
        local q = Quoted(msg)
        if q ~= nil then
            q = q:gsub("<[^>]*>", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if #q >= 4 and #q <= 200 then
                NoteHeard(q, Speaker(args, msg))
            end
        end
    end
end

-- guardar / cargar (por cuenta)
function B.SaveHeard()
    if not B.heardDirty then
        return
    end
    B.heardDirty = false
    local data = {}
    for i = 1, #B.heard do
        data[i] = { t = B.heard[i].t, w = B.heard[i].w }
    end
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, HEARD_KEY, data)
end

local function SaveCustom()
    local data = {}
    for i = 1, #B.custom do
        local a = B.custom[i]
        data[i] = { t = a.t, c = a.c, n = a.n }
    end
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, CUSTOM_KEY, data)
end

local function ValidTag(c)
    return type(c) == "string" and TAG[c] ~= nil
end

function B.LoadPhrases()
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Account, HEARD_KEY, function(data)
        if type(data) ~= "table" then
            return
        end
        local list = {}
        for _, e in ipairs(data) do
            if type(e) == "table" and type(e.t) == "string" and #list < MAX_HEARD then
                local k = PhraseKey(e.t)
                if #k >= 4 then
                    list[#list + 1] = { t = e.t, w = type(e.w) == "string" and e.w or "", k = k }
                end
            end
        end
        -- lo oido en esta sesion antes de cargar queda primero
        for _, h in ipairs(list) do
            local dup = false
            for _, x in ipairs(B.heard) do
                if x.k == h.k then
                    dup = true
                    break
                end
            end
            if not dup and #B.heard < MAX_HEARD then
                B.heard[#B.heard + 1] = h
            end
        end
    end)
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Account, CUSTOM_KEY, function(data)
        if type(data) ~= "table" then
            return
        end
        local list = {}
        for _, e in ipairs(data) do
            if type(e) == "table" and type(e.t) == "string" and ValidTag(e.c) and #list < MAX_CUSTOM then
                local k = PhraseKey(e.t)
                if #k >= 6 then
                    list[#list + 1] = { k = k, t = e.t, c = e.c, n = type(e.n) == "string" and e.n or "" }
                end
            end
        end
        B.custom = list
        if B.RefreshCustom ~= nil then
            pcall(B.RefreshCustom)
        end
    end)
end

-- agregar / cambiar / quitar (desde la ventana)
function B.AddCustom(text, tag, note)
    text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local k = PhraseKey(text)
    if #k < 6 then
        return false, L("Escribe al menos 6 letras de la frase.", "Type at least 6 letters of the phrase.")
    end
    if not ValidTag(tag) then
        return false, "?"
    end
    note = tostring(note or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #note > 60 then
        note = string.sub(note, 1, 60)
    end
    for _, a in ipairs(B.custom) do
        if a.k == k then
            a.t, a.c, a.n = text, tag, note
            SaveCustom()
            return true, L("Alerta actualizada.", "Alert updated.")
        end
    end
    if #B.custom >= MAX_CUSTOM then
        return false, L("Llegaste al m\195\161ximo de alertas (100).", "Alert limit reached (100).")
    end
    B.custom[#B.custom + 1] = { k = k, t = text, c = tag, n = note }
    SaveCustom()
    return true, L("Alerta guardada.", "Alert saved.")
end

function B.RemoveCustom(a)
    for i = #B.custom, 1, -1 do
        if B.custom[i] == a then
            table.remove(B.custom, i)
        end
    end
    SaveCustom()
end

function B.TestCustom(text, tag, note)
    local a = { k = "", t = tostring(text or ""), c = ValidTag(tag) and tag or "Q", n = note }
    if B.annFree ~= nil then
        B.annFree.test = nil
    end
    ShowCustom(a, "test")
end

-- busqueda para autocompletar: frases oidas (y alertas ya guardadas)
function B.SearchPhrases(query, max)
    local out = {}
    local q = Norm(query or "")
    if #q < 2 then
        return out
    end
    for _, h in ipairs(B.heard) do
        if string.find(h.k, q, 1, true) ~= nil then
            out[#out + 1] = h
            if #out >= max then
                return out
            end
        end
    end
    for _, a in ipairs(B.custom) do
        if string.find(a.k, q, 1, true) ~= nil then
            local dup = false
            for _, o in ipairs(out) do
                if o.k == a.k then
                    dup = true
                    break
                end
            end
            if not dup then
                out[#out + 1] = { t = a.t, w = "", k = a.k }
                if #out >= max then
                    return out
                end
            end
        end
    end
    return out
end

local function OnSelfEffect(sender, args)
    if B.cur == nil or sender == nil or args == nil then
        return
    end
    OnEffect(sender:Get(args.Index), "self")
end

local function OnTargetChanged()
    if B.Get("enabled") ~= true then
        return
    end
    local ok, name = pcall(function()
        local t = B.player:GetTarget()
        if t == nil or t.GetName == nil then
            return nil
        end
        return t:GetName()
    end)
    if not ok or name == nil or name == "" then
        B.lastTargetName = nil
        return
    end
    if name == B.lastTargetName then
        return
    end
    B.lastTargetName = name
    local key, idx = FindBoss(name)
    if key ~= nil then
        B.demo = false
        B.Activate(key, idx)
    end
end

local function OnCombatChanged()
    local ok, inCombat = pcall(function()
        return B.player:IsInCombat() == true
    end)
    if not ok then
        return
    end
    B.inCombat = inCombat
    if inCombat then
        B.endAt = nil
        B.idleAt = nil
        if B.cur ~= nil then
            B.StartPull()
        end
    else
        B.endAt = Now() + END_DELAY
        pcall(B.SaveHeard)
    end
    if B.Get("onlyCombat") then
        B.Refresh()
    end
end

local function OnPartyChanged()
    if B.cur ~= nil then
        B.HookParty()
    end
end

local function Safe(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            Report(err)
        end
    end
end

-- golpes de Prime (lineas de combate): lista corta armada una vez
local function BuildHitList()
    local db = DB()
    if db == nil or type(db.fx) ~= "table" or db.fxHit ~= nil then
        return
    end
    local list = {}
    for k, fx in pairs(db.fx) do
        if fx[1] == "h" and #k >= 5 then
            list[#list + 1] = { fx[4], k }
        end
    end
    db.fxHit = list
end

function B.Init()
    if B._inited then
        return
    end
    B._inited = true
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    B.player = player
    BuildHitList()
    B.hTarget = AddCallback(player, "TargetChanged", Safe(OnTargetChanged))
    B.hCombat = AddCallback(player, "InCombatChanged", Safe(OnCombatChanged))
    B.hParty = AddCallback(player, "PartyChanged", Safe(OnPartyChanged))
    local okE, effects = pcall(function() return player:GetEffects() end)
    if okE and effects ~= nil then
        B.effects = effects
        B.hEffect = AddCallback(effects, "EffectAdded", Safe(OnSelfEffect))
    end
    if type(_G.LQA_ChatListeners) ~= "table" then
        _G.LQA_ChatListeners = {}
    end
    B.hChat = Safe(B.OnChat)
    _G.LQA_ChatListeners["WorldMapBoss"] = B.hChat
    pcall(function() B.inCombat = player:IsInCombat() == true end)
    LoadValues()
    pcall(B.LoadPhrases)

    -- un solo reloj: animaciones (20/s mientras algo se mueve, si no 4/s)
    -- y cada 5 s comprueba que los eventos sigan enganchados
    local drv = Turbine.UI.Control()
    drv:SetVisible(false)
    local nextTick, nextCheck, errors = 0, 0, 0
    drv.Update = function()
        local now = Now()
        if now < nextTick then
            return
        end
        local floating = false
        for k = 1, #B.floats do
            if B.floats[k].t0 ~= nil then
                floating = true
                break
            end
        end
        if B.cur == nil and not B.demo and (B.alert == nil or B.alert.t0 == nil) and not floating then
            nextTick = now + SLOW
        else
            local ok, moving = pcall(B.Tick, now)
            if not ok then
                errors = errors + 1
                Report(moving)
                moving = false
                if errors >= 5 then
                    drv:SetWantsUpdates(false)
                end
            end
            nextTick = now + (moving and FAST or SLOW)
        end
        if now >= nextCheck then
            nextCheck = now + 5
            pcall(function()
                EnsureCallback(B.player, "TargetChanged", B.hTarget)
                EnsureCallback(B.player, "InCombatChanged", B.hCombat)
                EnsureCallback(B.player, "PartyChanged", B.hParty)
                EnsureCallback(B.effects, "EffectAdded", B.hEffect)
                if type(_G.LQA_ChatListeners) == "table" and _G.LQA_ChatListeners["WorldMapBoss"] == nil then
                    _G.LQA_ChatListeners["WorldMapBoss"] = B.hChat
                end
            end)
        end
    end
    drv:SetWantsUpdates(true)
    B.driver = drv
end

function B.Shutdown()
    pcall(B.SaveHeard)
    pcall(function()
        RemoveCallback(B.player, "TargetChanged", B.hTarget)
        RemoveCallback(B.player, "InCombatChanged", B.hCombat)
        RemoveCallback(B.player, "PartyChanged", B.hParty)
        RemoveCallback(B.effects, "EffectAdded", B.hEffect)
        B.UnhookParty()
        if type(_G.LQA_ChatListeners) == "table" then
            _G.LQA_ChatListeners["WorldMapBoss"] = nil
        end
        if B.driver ~= nil then
            B.driver:SetWantsUpdates(false)
        end
        if B.panel ~= nil then
            B.panel.win:SetVisible(false)
        end
        if B.alert ~= nil then
            B.alert.win:SetVisible(false)
        end
        for _, f in ipairs(B.floats) do
            f.win:SetVisible(false)
        end
        B.HideTip()
        if B.opt ~= nil then
            B.opt.win:SetVisible(false)
        end
        if B.cw ~= nil then
            B.cw.win:SetVisible(false)
        end
        if B.anchor ~= nil then
            B.anchor:SetVisible(false)
        end
    end)
end

-- ---------------------------------------------------------------------
-- Prueba y busqueda manual
-- ---------------------------------------------------------------------
function B.Demo()
    local key, idx = FindBoss("Commander Mornang")
    if key == nil then
        local db = DB()
        if db ~= nil and db.instances ~= nil and db.instances[1] ~= nil then
            key, idx = db.instances[1].k, 1
        end
    end
    if key == nil then
        return
    end
    B.demo = true
    B.cur = nil
    if B.Activate(key, idx) then
        B.cur.pulled = true
        B.demoNext = 0
        B.demoK = 0
        B.Refresh()
    end
end

-- en la prueba se dispara una mecanica distinta cada 2,5 s
function B.DemoStep(now)
    local cur = B.cur
    if cur == nil or #cur.rel == 0 then
        return
    end
    if now < (B.demoNext or 0) then
        return
    end
    B.demoNext = now + 2.5
    B.demoK = (B.demoK or 0) % math.min(#cur.rel, 6) + 1
    local i = cur.rel[B.demoK]
    -- la siguiente "ya viene" (aura girando antes de llegar)
    local j = cur.rel[B.demoK % math.min(#cur.rel, 6) + 1]
    if j ~= nil and j ~= i then
        cur.ready[j] = now + 2.5
    end
    cur.act[i] = nil
    B.Trigger(i)
end

function B.StopDemo()
    B.demo = false
    B.Clear()
end

function B.Command(arg)
    local low = Norm(arg)
    if low == "" then
        B.ToggleOptions()
        return
    end
    if low == "prueba" or low == "test" or low == "demo" then
        B.Demo()
        return
    end
    if low == "alertas" or low == "alerts" or low == "frases" then
        B.ToggleCustom()
        return
    end
    if low == "off" or low == "quitar" or low == "clear" then
        B.StopDemo()
        return
    end
    local key, idx = FindBoss(arg)
    if key ~= nil and B.Activate(key, idx) then
        Turbine.Shell.WriteLine("<rgb=#C9A66B>" .. L("Mec\195\161nicas de jefe: ", "Boss mechanics: ") .. B.cur.name .. "</rgb>")
    else
        Turbine.Shell.WriteLine("<rgb=#C9A66B>" .. L("Mec\195\161nicas de jefe: no encontr\195\169 ese jefe.", "Boss mechanics: boss not found.") .. "</rgb>")
    end
end

-- ---------------------------------------------------------------------
-- Ventana de opciones + asa para mover los avisos
-- ---------------------------------------------------------------------
local OPT_ROWS = {
    { key = "enabled", es = "Activado", en = "Enabled" },
    { key = "model", es = "Modelo", en = "Style", names = MODEL_NAMES },
    { key = "size", es = "Tama\195\177o de los iconos", en = "Icon size" },
    { key = "role", es = "Rol", en = "Role", names = ROLE_NAMES },
    { key = "maxIcons", es = "M\195\161ximo de iconos", en = "Max icons" },
    { key = "alerts", es = "Aviso grande al detectar", en = "Big alert on detect" },
    { key = "soon", es = "Aura antes de que llegue", en = "Aura before it comes" },
    { key = "onlyCombat", es = "Solo en combate", en = "Only in combat" },
    { key = "locked", es = "Bloquear posici\195\179n", en = "Lock position" },
    { key = "opacity", es = "Opacidad", en = "Opacity" },
}

local function ValueText(row)
    local v = B.Get(row.key)
    if type(v) == "boolean" then
        return v and L("S\195\173", "Yes") or L("No", "No")
    end
    if row.names ~= nil and row.names[v] ~= nil then
        local n = row.names[v]
        local txt = L(n.es, n.en)
        if row.key == "role" and v == 1 then
            local r = ClassRole()
            local rn = r == "t" and ROLE_NAMES[2] or (r == "h" and ROLE_NAMES[4] or ROLE_NAMES[3])
            txt = txt .. " (" .. L(rn.es, rn.en) .. ")"
        end
        return txt
    end
    if row.key == "opacity" then
        return tostring(v) .. " %"
    end
    if row.key == "size" then
        return tostring(v) .. " px"
    end
    return tostring(v)
end

local function NextValue(row)
    local v = B.Get(row.key)
    if type(v) == "boolean" then
        B.Set(row.key, not v)
        return
    end
    local list = CHOICES[row.key]
    if list == nil then
        return
    end
    local nxt = list[1]
    for i, c in ipairs(list) do
        if c == v then
            nxt = list[i % #list + 1]
            break
        end
    end
    B.Set(row.key, nxt)
end

-- asa (solo con las opciones abiertas): arrastrarla mueve los avisos
local function BuildAnchor()
    local w = Turbine.UI.Window()
    w:SetSize(180, 22)
    w:SetBackColor(Turbine.UI.Color(0.85, 0.30, 0.20, 0.05))
    pcall(w.SetZOrder, w, 65)
    w:SetMouseVisible(true)
    w:SetVisible(false)
    local lb = NewLabel(w, F("Verdana12", "Verdana10"), Turbine.UI.ContentAlignment.MiddleCenter)
    lb:SetPosition(0, 0)
    lb:SetSize(180, 22)
    w.label = lb
    local drag, dx, dy = false, 0, 0
    w.MouseDown = function(_, args)
        drag, dx, dy = true, args.X, args.Y
    end
    w.MouseMove = function(_, args)
        if drag then
            local x, y = w:GetPosition()
            w:SetPosition(x + args.X - dx, y + args.Y - dy)
        end
    end
    w.MouseUp = function()
        if drag then
            drag = false
            local x, y = w:GetPosition()
            B.values.ax, B.values.ay = x, y
            SaveValues()
        end
    end
    B.anchor = w
    return w
end

local function ShowAnchor(vis)
    local w = B.anchor or BuildAnchor()
    if vis then
        w.label:SetText(L("Avisos aqu\195\173 (arr\195\161strame)", "Alerts here (drag me)"))
        local x, y = AnchorXY(180, 22)
        w:SetPosition(x, y)
    end
    w:SetVisible(vis)
end

local function BuildOptions()
    local o = {}
    local W, ROW = 400, 28
    local H = 52 + #OPT_ROWS * ROW + 78
    local w = Turbine.UI.Lotro.Window()
    o.win = w
    w:SetSize(W, H)
    w:SetPosition(math.floor((Turbine.UI.Display.GetWidth() - W) / 2), math.floor((Turbine.UI.Display.GetHeight() - H) / 2))
    w:SetVisible(false)
    o.rows = {}
    for i, row in ipairs(OPT_ROWS) do
        local y = 40 + (i - 1) * ROW
        local lb = NewLabel(w, F("Verdana14", "Verdana12"))
        lb:SetPosition(20, y)
        lb:SetSize(210, ROW - 2)
        local bt = Turbine.UI.Lotro.Button()
        bt:SetParent(w)
        bt:SetPosition(236, y + 2)
        bt:SetSize(144, 22)
        bt.Click = function()
            NextValue(row)
            B.RefreshOptions()
        end
        o.rows[i] = { row = row, label = lb, button = bt }
    end
    local y = 44 + #OPT_ROWS * ROW
    o.demo = Turbine.UI.Lotro.Button()
    o.demo:SetParent(w)
    o.demo:SetPosition(20, y)
    o.demo:SetSize(160, 24)
    o.demo.Click = function()
        if B.demo then
            B.StopDemo()
        else
            B.Demo()
        end
        B.RefreshOptions()
    end
    o.state = NewLabel(w, F("Verdana12", "Verdana10"))
    o.state:SetPosition(190, y)
    o.state:SetSize(200, 24)
    -- frases que el addon no conoce: el jugador decide cuales avisan
    o.custom = Turbine.UI.Lotro.Button()
    o.custom:SetParent(w)
    o.custom:SetPosition(20, y + 30)
    o.custom:SetSize(200, 24)
    o.custom.Click = function()
        B.ToggleCustom()
    end
    w.VisibleChanged = function()
        pcall(ShowAnchor, w:IsVisible())
    end
    B.opt = o
    return o
end

function B.RefreshOptions()
    local o = B.opt
    if o == nil then
        return
    end
    o.win:SetText(L("Mec\195\161nicas de jefe", "Boss mechanics"))
    for _, r in ipairs(o.rows) do
        r.label:SetText(L(r.row.es, r.row.en))
        r.button:SetText(ValueText(r.row))
    end
    o.demo:SetText(B.demo and L("Quitar prueba", "Stop test") or L("Probar", "Test"))
    o.custom:SetText(L("Alertas propias...", "Custom alerts..."))
    if B.cur ~= nil then
        o.state:SetText(B.cur.name)
    else
        o.state:SetText(L("Sin jefe (apunta a uno)", "No boss (target one)"))
    end
end

function B.ToggleOptions()
    local ok, err = pcall(function()
        local o = B.opt or BuildOptions()
        if o.win:IsVisible() then
            o.win:SetVisible(false)
        else
            B.RefreshOptions()
            o.win:SetVisible(true)
            pcall(o.win.Activate, o.win)
        end
        pcall(ShowAnchor, o.win:IsVisible())
    end)
    if not ok then
        Report(err)
    end
end

-- ---------------------------------------------------------------------
-- Ventana "Alertas propias": escribe parte de una frase (se completa con las
-- frases oidas en combate), elige la accion y guarda la alerta.
-- Se arma solo la primera vez que se abre.
-- ---------------------------------------------------------------------
local CUSTOM_TAGS = { "Z", "S", "G", "I", "Y", "T", "Q" }   -- esquiva, separate, agrupate, interrumpe, cura, defensivo, cuidado
local SUGGEST_ROWS = 6

local function TagWord(tag)
    local t = TAG[tag] or TAG.Q
    local c = CAT[t.c]
    return L(c.es, c.en), c.color
end

local function BuildCustomWindow()
    local cw = { tag = "Z" }
    local W, H = 470, 500
    local w = Turbine.UI.Lotro.Window()
    cw.win = w
    w:SetSize(W, H)
    w:SetPosition(math.floor((Turbine.UI.Display.GetWidth() - W) / 2) + 40, math.floor((Turbine.UI.Display.GetHeight() - H) / 2))
    w:SetVisible(false)

    local font12 = F("Verdana12", "Verdana10")
    local font14 = F("Verdana14", "Verdana12")

    cw.help = NewLabel(w, font12, Turbine.UI.ContentAlignment.TopLeft)
    cw.help:SetPosition(20, 38)
    cw.help:SetSize(W - 40, 32)
    pcall(cw.help.SetMultiline, cw.help, true)
    cw.help:SetForeColor(SUBTLE)

    cw.box = Turbine.UI.Lotro.TextBox()
    cw.box:SetParent(w)
    cw.box:SetPosition(20, 74)
    cw.box:SetSize(W - 40, 22)
    cw.box:SetFont(font12)
    pcall(cw.box.SetMultiline, cw.box, false)

    -- sugerencias (frases oidas que contienen lo escrito)
    cw.sug = {}
    for i = 1, SUGGEST_ROWS do
        local lb = NewLabel(w, font12)
        lb:SetPosition(26, 98 + (i - 1) * 19)
        lb:SetSize(W - 52, 18)
        lb:SetMouseVisible(true)
        lb:SetVisible(false)
        lb.MouseEnter = function()
            lb:SetForeColor(GOLD)
        end
        lb.MouseLeave = function()
            lb:SetForeColor(TEXT)
        end
        lb.MouseClick = function()
            if lb.phrase ~= nil then
                cw.skip = true
                cw.box:SetText(lb.phrase)
                cw.skip = false
                B.RefreshSuggest()
            end
        end
        cw.sug[i] = lb
    end

    local y = 98 + SUGGEST_ROWS * 19 + 8
    cw.lblAct = NewLabel(w, font14)
    cw.lblAct:SetPosition(20, y)
    cw.lblAct:SetSize(150, 24)
    cw.btnAct = Turbine.UI.Lotro.Button()
    cw.btnAct:SetParent(w)
    cw.btnAct:SetPosition(170, y + 1)
    cw.btnAct:SetSize(180, 22)
    cw.btnAct.Click = function()
        local nxt = CUSTOM_TAGS[1]
        for i, t in ipairs(CUSTOM_TAGS) do
            if t == cw.tag then
                nxt = CUSTOM_TAGS[i % #CUSTOM_TAGS + 1]
                break
            end
        end
        cw.tag = nxt
        B.RefreshCustom()
    end
    cw.icon = NewImg(w)
    cw.icon:SetPosition(360, y - 1)
    cw.icon:SetSize(24, 24)

    y = y + 30
    cw.lblNote = NewLabel(w, font14)
    cw.lblNote:SetPosition(20, y)
    cw.lblNote:SetSize(150, 24)
    cw.note = Turbine.UI.Lotro.TextBox()
    cw.note:SetParent(w)
    cw.note:SetPosition(170, y + 1)
    cw.note:SetSize(W - 190, 22)
    cw.note:SetFont(font12)
    pcall(cw.note.SetMultiline, cw.note, false)

    y = y + 32
    cw.btnSave = Turbine.UI.Lotro.Button()
    cw.btnSave:SetParent(w)
    cw.btnSave:SetPosition(20, y)
    cw.btnSave:SetSize(150, 24)
    cw.btnSave.Click = function()
        local ok, msg = B.AddCustom(cw.box:GetText(), cw.tag, cw.note:GetText())
        cw.status:SetText(msg or "")
        cw.status:SetForeColor(ok and GOLD or Turbine.UI.Color(1, 1, 0.45, 0.4))
        if ok then
            B.RefreshCustom()
        end
    end
    cw.btnTest = Turbine.UI.Lotro.Button()
    cw.btnTest:SetParent(w)
    cw.btnTest:SetPosition(180, y)
    cw.btnTest:SetSize(110, 24)
    cw.btnTest.Click = function()
        local t = cw.box:GetText()
        if t == nil or t == "" then
            t = L("Frase de prueba", "Test phrase")
        end
        B.TestCustom(t, cw.tag, cw.note:GetText())
    end
    cw.status = NewLabel(w, font12)
    cw.status:SetPosition(300, y)
    cw.status:SetSize(W - 320, 24)

    y = y + 34
    cw.lblList = NewLabel(w, font14)
    cw.lblList:SetPosition(20, y)
    cw.lblList:SetSize(W - 40, 20)
    cw.lblList:SetForeColor(GOLD)

    y = y + 22
    cw.list = Turbine.UI.ListBox()
    cw.list:SetParent(w)
    cw.list:SetPosition(20, y)
    cw.list:SetSize(W - 52, H - y - 20)
    cw.scroll = Turbine.UI.Lotro.ScrollBar()
    cw.scroll:SetParent(w)
    pcall(cw.scroll.SetOrientation, cw.scroll, Turbine.UI.Orientation.Vertical)
    cw.scroll:SetPosition(W - 30, y)
    cw.scroll:SetSize(10, H - y - 20)
    pcall(cw.list.SetVerticalScrollBar, cw.list, cw.scroll)

    cw.box.TextChanged = function()
        if not cw.skip then
            B.RefreshSuggest()
        end
    end
    B.cw = cw
    return cw
end

function B.RefreshSuggest()
    local cw = B.cw
    if cw == nil then
        return
    end
    local found = B.SearchPhrases(cw.box:GetText(), SUGGEST_ROWS)
    for i = 1, SUGGEST_ROWS do
        local lb = cw.sug[i]
        local h = found[i]
        if h ~= nil then
            local txt = "\194\171" .. h.t .. "\194\187"
            if h.w ~= nil and h.w ~= "" then
                txt = txt .. "  \226\128\148 " .. h.w
            end
            lb.phrase = h.t
            lb:SetText(txt)
            lb:SetForeColor(TEXT)
            lb:SetVisible(true)
        else
            lb.phrase = nil
            lb:SetVisible(false)
        end
    end
end

local function CustomRow(cw, a)
    local W = cw.list:GetWidth()
    local row = Turbine.UI.Control()
    row:SetSize(W, 22)
    local icon = NewImg(row)
    local t = TAG[a.c] or TAG.Q
    icon:SetBackground(GlyphImg(t.g, 16))
    icon:SetPosition(2, 3)
    icon:SetSize(16, 16)
    local word, color = TagWord(a.c)
    local lw = NewLabel(row, F("Verdana12", "Verdana10"))
    lw:SetPosition(22, 0)
    lw:SetSize(96, 22)
    lw:SetText(word)
    lw:SetForeColor(color)
    local lt = NewLabel(row, F("Verdana12", "Verdana10"))
    lt:SetPosition(120, 0)
    lt:SetSize(W - 120 - 30, 22)
    local txt = "\194\171" .. a.t .. "\194\187"
    if a.n ~= nil and a.n ~= "" then
        txt = txt .. "  \226\134\146 " .. a.n
    end
    lt:SetText(txt)
    lt:SetMouseVisible(true)
    lt.MouseClick = function()
        -- cargar para editar
        cw.skip = true
        cw.box:SetText(a.t)
        cw.note:SetText(a.n or "")
        cw.skip = false
        cw.tag = a.c
        B.RefreshCustom()
    end
    local del = Turbine.UI.Lotro.Button()
    del:SetParent(row)
    del:SetPosition(W - 26, 1)
    del:SetSize(24, 20)
    del:SetText("X")
    del.Click = function()
        B.RemoveCustom(a)
        B.RefreshCustom()
    end
    return row
end

function B.RefreshCustom()
    local cw = B.cw
    if cw == nil then
        return
    end
    cw.win:SetText(L("Alertas propias", "Custom alerts"))
    cw.help:SetText(L("Escribe parte de una frase del jefe: se completa con las frases o\195\173das en combate. Elige la acci\195\179n y guarda. Solo avisan las frases que t\195\186 guardes.",
        "Type part of a boss phrase: it completes with phrases heard in combat. Pick the action and save. Only phrases you save will alert."))
    cw.lblAct:SetText(L("Acci\195\179n:", "Action:"))
    local word, color = TagWord(cw.tag)
    cw.btnAct:SetText(word)
    cw.icon:SetBackground(GlyphImg((TAG[cw.tag] or TAG.Q).g, 24))
    cw.lblNote:SetText(L("Aviso (opcional):", "Note (optional):"))
    cw.btnSave:SetText(L("Guardar alerta", "Save alert"))
    cw.btnTest:SetText(L("Probar", "Test"))
    cw.lblList:SetText(L("Tus alertas", "Your alerts") .. " (" .. #B.custom .. ")")
    cw.list:ClearItems()
    for _, a in ipairs(B.custom) do
        cw.list:AddItem(CustomRow(cw, a))
    end
end

function B.ToggleCustom()
    local ok, err = pcall(function()
        local cw = B.cw or BuildCustomWindow()
        if cw.win:IsVisible() then
            cw.win:SetVisible(false)
        else
            cw.status:SetText("")
            B.RefreshCustom()
            B.RefreshSuggest()
            cw.win:SetVisible(true)
            pcall(cw.win.Activate, cw.win)
        end
    end)
    if not ok then
        Report(err)
    end
end

-- ---------------------------------------------------------------------
-- Arranque
-- ---------------------------------------------------------------------
local okInit, errInit = pcall(B.Init)
if not okInit then
    Report(errInit)
end
