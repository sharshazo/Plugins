-- WorldMap_Addon/worldmap_boss.lua
--
-- v3.16 (pedido del usuario): "Senales de jefe". Con los datos de BossCodex
-- (Arebel) y el estudio de BossCodex + PrimePlugins, detecta el jefe con el
-- que peleas y muestra iconos pequenos de sus mecanicas peligrosas, segun
-- tu rol (tanque / DPS / sanador), con cuenta regresiva hasta su proximo uso.
--
-- Deteccion (todo barato y sin sondeos continuos):
--   * Objetivo: al cambiar de objetivo se busca su nombre en el indice de
--     jefes (boss/bossdb_index.lua); con eso se sabe la incursion o
--     mazmorra y se cargan SOLO los datos de esa instancia.
--   * Combate: al entrar en combate con un jefe activo empiezan los
--     contadores con el "primer uso" de cada habilidad (como BossCodex).
--   * Efectos en ti: cada efecto que te aplica el jefe trae su icono; el
--     icono no depende del idioma del cliente, asi que funciona en ingles y
--     con la traduccion al espanol (igual que Prime, por icono / categoria).
--   * Chat (si Quest Assistant reparte el chat, _G.LQA_ChatListeners): las
--     lineas de combate que nombran una habilidad ("... with Claw Swipe on
--     ...") y los gritos del jefe. Solo se mira mientras hay un jefe activo.
-- Cada deteccion reinicia el contador de esa habilidad con su reutilizacion.
--
-- Modelos: Fila, Columna (con nombre y barra), Mini (solo iconos) y Solo
-- alertas. Ademas una alerta central opcional. Tamano 16-48, opacidad,
-- maximo de iconos, rol automatico por clase o elegido.
--
-- Rendimiento: los controles se crean una vez y se reutilizan; el reloj
-- (10 por segundo) solo corre con un jefe activo; los textos y colores solo
-- se tocan cuando cambian; sin tablas ni textos nuevos por cuadro. Todo lo
-- que toca la API va protegido: si algo falla se avisa una vez y el mapa
-- sigue igual.

import "Turbine"
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WorldMapAddon = _G.WorldMapAddon or {}

local B = {}
WorldMapAddon.Boss = B

local RES = "WorldMap_Addon/assets/worldmap/icon/"
local SAVE_KEY = "WorldMap_Senales"
local TICK = 0.1
local MAX_SLOTS = 12
local SIZES = { 16, 20, 24, 28, 32, 40, 48 }
local END_DELAY = 8          -- s fuera de combate antes de dar el combate por terminado
local FLASH_TIME = 3         -- s de destello tras detectar una habilidad
local ALERT_TIME = 3
local SOON = 5               -- s: "ya viene" (marco encendido)

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
    pcall(Turbine.Shell.WriteLine, "<rgb=#FF6060>Mapa del Mundo (se\195\177ales de jefe): " .. tostring(err) .. "</rgb>")
end

-- mismo esquema de eventos compartidos que Quest Assistant / MoorMap: el
-- evento puede ser una funcion o una tabla de funciones; nunca se pisa
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

-- si otro addon del mismo espacio pisa el evento con "obj[ev] = function",
-- nuestro manejador se vuelve a enganchar (sin duplicarlo)
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

-- misma normalizacion que el generador del indice
local function Norm(text)
    local s = tostring(text or ""):lower()
    s = s:gsub("<[^>]*>", " ")
    s = s:gsub("[^a-z0-9\128-\255]", " ")
    s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    return s
end

-- ---------------------------------------------------------------------
-- Mecanicas (etiquetas del generador) y roles
-- ---------------------------------------------------------------------
local TAGS = {
    I = { g = "interrupt", es = "Interrumpir", en = "Interrupt", tes = "Lanzamiento interrumpible: c\195\179rtalo.", ten = "Interruptible cast: interrupt it." },
    C = { g = "cone", es = "Cono frontal", en = "Frontal cone", tes = "Golpea delante del jefe: no te quedes enfrente.", ten = "Hits in front of the boss: don't stand there." },
    A = { g = "aoe", es = "\195\129rea", en = "Area", tes = "Da\195\177o en \195\161rea alrededor del jefe: al\195\169jate o prep\195\161rate.", ten = "Area damage around the boss: move out or brace." },
    S = { g = "spread", es = "Dispersarse", en = "Spread", tes = "Elige jugadores al azar: sep\195\161rense.", ten = "Picks random players: spread out." },
    K = { g = "stun", es = "Control", en = "Crowd control", tes = "Aturde, derriba o inmoviliza.", ten = "Stuns, knocks down or roots." },
    F = { g = "fear", es = "Miedo", en = "Fear", tes = "Miedo curable: qu\195\173talo.", ten = "Curable fear: remove it." },
    W = { g = "wound", es = "Herida", en = "Wound", tes = "Herida curable: qu\195\173tala.", ten = "Curable wound: remove it." },
    P = { g = "poison", es = "Veneno", en = "Poison", tes = "Veneno curable: qu\195\173talo.", ten = "Curable poison: remove it." },
    D = { g = "disease", es = "Enfermedad", en = "Disease", tes = "Enfermedad curable: qu\195\173tala.", ten = "Curable disease: remove it." },
    T = { g = "tank", es = "Golpe al tanque", en = "Tank buster", tes = "Golpe muy fuerte al tanque: usa defensas.", ten = "Very hard hit on the tank: use defensives." },
    R = { g = "threat", es = "Borra amenaza", en = "Threat wipe", tes = "Borra la amenaza: el tanque vuelve a provocar.", ten = "Wipes threat: the tank must re-taunt." },
    E = { g = "enrage", es = "Furia", en = "Enrage", tes = "El jefe se enfurece: m\195\161s da\195\177o.", ten = "The boss enrages: more damage." },
    H = { g = "heal", es = "Se cura", en = "Self heal", tes = "El jefe se cura: interrumpe o sube el da\195\177o.", ten = "The boss heals: interrupt or burst." },
    B = { g = "shield", es = "Escudo", en = "Shield", tes = "Escudo o inmunidad: cambia de objetivo o espera.", ten = "Shield or immunity: switch or wait." },
    X = { g = "corrupt", es = "Corrupci\195\179n", en = "Corruption", tes = "Gana corrupciones: qu\195\173taselas.", ten = "Gains corruptions: remove them." },
}

-- rol: 1 auto, 2 tanque, 3 DPS, 4 sanador, 5 todos
local ROLE_TAGS = {
    t = "TRCEKA",
    d = "IXBHCASKE",
    h = "FWPDSAK",
    a = "ITRCFWPDASKEHBX",
}
local ROLE_NAMES = {
    { es = "Autom\195\161tico", en = "Automatic" },
    { es = "Tanque", en = "Tank" },
    { es = "DPS", en = "DPS" },
    { es = "Sanador", en = "Healer" },
    { es = "Todos", en = "All" },
}
local MODEL_NAMES = {
    { es = "Fila", en = "Row" },
    { es = "Columna", en = "Column" },
    { es = "Mini", en = "Mini" },
    { es = "Solo alertas", en = "Alerts only" },
}

local function ClassRole()
    local ok, role = pcall(function()
        local p = Turbine.Gameplay.LocalPlayer.GetInstance()
        local cls = p:GetClass()
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
-- Opciones (por cuenta; solo numeros y si/no)
-- ---------------------------------------------------------------------
local DEFAULTS = {
    enabled = true,
    model = 1,       -- 1 fila, 2 columna, 3 mini, 4 solo alertas
    size = 28,
    role = 1,
    maxIcons = 8,
    alerts = true,   -- alerta central
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
        return true   -- posiciones
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

-- ---------------------------------------------------------------------
-- Datos: indice y carga por instancia
-- ---------------------------------------------------------------------
local function LoadInstance(key)
    local db = DB()
    if db == nil or db.inst == nil then
        return nil
    end
    if db.inst[key] == nil then
        pcall(import, "WorldMap_Addon.boss.bossdb_" .. key)
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

-- nombre (normalizado) -> instancia, indice; exacto o el nombre mas largo
-- contenido en el otro (solo al cambiar de objetivo)
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
    local best, bestLen = nil, 0
    for key, v in pairs(db.names) do
        local len = #key
        if len >= 6 and len > bestLen
            and (string.find(nk, key, 1, true) ~= nil or string.find(key, nk, 1, true) ~= nil) then
            best, bestLen = v, len
        end
    end
    if best ~= nil then
        return best[1], best[2]
    end
    return nil
end

-- ---------------------------------------------------------------------
-- Estado del jefe activo
-- ---------------------------------------------------------------------
-- B.cur = { key, idx, name, inst, skills = {datos}, rel = {indices},
--           names = {minusculas}, yells = { {texto, i} }, icons = { [icono] = i },
--           ready = { [i] = momento }, flash = { [i] = hasta }, pulled = bool }
B.cur = nil
B.inCombat = false
B.endAt = nil

local function Primary(skill, role)
    local tags = skill[2]
    local order = ROLE_TAGS[role] or ROLE_TAGS.a
    for i = 1, #order do
        local t = string.sub(order, i, i)
        if string.find(tags, t, 1, true) ~= nil then
            return t
        end
    end
    return nil
end

local function BuildRelevant(cur)
    local role = Role()
    cur.role = role
    cur.rel = {}
    cur.prim = {}
    for i, s in ipairs(cur.skills) do
        local p = Primary(s, role)
        if p ~= nil then
            cur.rel[#cur.rel + 1] = i
            cur.prim[i] = p
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
        key = instKey, idx = idx, name = rec[1], skills = rec[2],
        inst = InstanceInfo(instKey),
        names = {}, yells = {}, icons = {}, ready = {}, flash = {},
        pulled = false,
    }
    for i, s in ipairs(cur.skills) do
        -- nombres muy cortos ("Bite") darian falsos avisos en el chat: esos
        -- se detectan solo por el icono del efecto
        local nm = string.lower(s[1])
        cur.names[i] = (#nm >= 5) and nm or false
        if type(s[6]) == "table" then
            for _, ic in ipairs(s[6]) do
                if cur.icons[ic] == nil then
                    cur.icons[ic] = i
                end
            end
        end
        if type(s[7]) == "table" then
            for _, y in ipairs(s[7]) do
                cur.yells[#cur.yells + 1] = { y, i }
            end
        end
    end
    BuildRelevant(cur)
    B.cur = cur
    B.endAt = nil
    if B.inCombat then
        B.StartPull()
    end
    B.Refresh()
    return true
end

function B.Clear()
    B.cur = nil
    B.endAt = nil
    B.lastTargetName = nil
    if B.alert ~= nil then
        B.alert.untilT = nil
        pcall(B.alert.win.SetVisible, B.alert.win, false)
    end
    B.HideTip()
    B.Refresh()
end

-- comienzo del combate: contadores con el primer uso de cada habilidad
function B.StartPull()
    local cur = B.cur
    if cur == nil or cur.pulled then
        return
    end
    cur.pulled = true
    local now = Now()
    for i, s in ipairs(cur.skills) do
        local icd = tonumber(s[4]) or 0
        if icd > 0 then
            cur.ready[i] = now + icd
        else
            cur.ready[i] = nil
        end
        cur.flash[i] = nil
    end
end

-- se detecto una habilidad (chat, grito o efecto)
function B.Trigger(i)
    local cur = B.cur
    if cur == nil or cur.skills[i] == nil then
        return
    end
    local now = Now()
    if cur.flash[i] ~= nil and now < cur.flash[i] - FLASH_TIME + 1 then
        return   -- la misma habilidad ya se marco hace menos de 1 s
    end
    local cd = tonumber(cur.skills[i][3]) or 0
    cur.ready[i] = cd > 0 and (now + cd) or nil
    cur.flash[i] = now + FLASH_TIME
    if not cur.pulled then
        cur.pulled = true
    end
    if B.Get("alerts") and cur.prim[i] ~= nil then
        B.ShowAlert(i)
    end
    B.dirty = true
end

-- ---------------------------------------------------------------------
-- Ventana de senales
-- ---------------------------------------------------------------------
local GOLD = Turbine.UI.Color(1, 0.79, 0.65, 0.42)
local TEXT = Turbine.UI.Color(1, 0.94, 0.90, 0.80)
local TEXT_SOON = Turbine.UI.Color(1, 1.0, 0.82, 0.30)
local TEXT_NOW = Turbine.UI.Color(1, 1.0, 0.35, 0.25)
local HEAD_BG = Turbine.UI.Color(0.75, 0.06, 0.05, 0.03)
local BAR_BG = Turbine.UI.Color(0.8, 0.10, 0.09, 0.07)
local BAR_FG = Turbine.UI.Color(0.95, 0.79, 0.55, 0.20)
local RING_SOON = Turbine.UI.Color(1, 1.0, 0.75, 0.20)
local RING_NOW = Turbine.UI.Color(1, 1.0, 0.30, 0.20)
local CLEAR = Turbine.UI.Color(0, 0, 0, 0)
local TIP_BG = Turbine.UI.Color(0.94, 0.07, 0.06, 0.04)

local function Font(size)
    local FT = Turbine.UI.Lotro.Font
    if size >= 40 then
        return FT.Verdana16 or FT.Verdana14
    elseif size >= 28 then
        return FT.Verdana14 or FT.Verdana12
    elseif size >= 20 then
        return FT.Verdana12 or FT.Verdana10
    end
    return FT.Verdana10 or FT.Verdana12
end

local function NewCtl(parent)
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
    l:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
    l:SetTextAlignment(align or Turbine.UI.ContentAlignment.MiddleCenter)
    return l
end

-- marco de 4 piezas (no hay controles con borde en la API)
local function NewRing(parent)
    local r = {}
    for _, k in ipairs({ "t", "b", "l", "r" }) do
        r[k] = NewCtl(parent)
        r[k]:SetVisible(false)
    end
    return r
end

local function PlaceRing(r, x, y, w, h, t)
    r.t:SetPosition(x, y); r.t:SetSize(w, t)
    r.b:SetPosition(x, y + h - t); r.b:SetSize(w, t)
    r.l:SetPosition(x, y); r.l:SetSize(t, h)
    r.r:SetPosition(x + w - t, y); r.r:SetSize(t, h)
end

local function ShowRing(r, color)
    if r.color ~= color then
        r.color = color
        if color ~= nil then
            r.t:SetBackColor(color); r.b:SetBackColor(color)
            r.l:SetBackColor(color); r.r:SetBackColor(color)
        end
    end
    local vis = color ~= nil
    if r.vis ~= vis then
        r.vis = vis
        r.t:SetVisible(vis); r.b:SetVisible(vis)
        r.l:SetVisible(vis); r.r:SetVisible(vis)
    end
end

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

    -- cabecera: nombre del jefe; tambien es el asa para mover la ventana
    self.head = Turbine.UI.Control()
    self.head:SetParent(w)
    self.head:SetBackColor(HEAD_BG)
    self.head:SetMouseVisible(true)
    self.title = NewLabel(self.head, Turbine.UI.Lotro.Font.Verdana10 or Turbine.UI.Lotro.Font.Verdana12, Turbine.UI.ContentAlignment.MiddleLeft)
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
        s.icon = Turbine.UI.Control()
        s.icon:SetParent(w)
        s.icon:SetMouseVisible(true)
        pcall(s.icon.SetBlendMode, s.icon, Turbine.UI.BlendMode.AlphaBlend)
        s.ring = NewRing(w)
        s.num = NewLabel(w, Font(28))
        s.name = NewLabel(w, Turbine.UI.Lotro.Font.Verdana12 or Turbine.UI.Lotro.Font.Verdana10, Turbine.UI.ContentAlignment.MiddleLeft)
        s.barBg = NewCtl(w)
        s.barBg:SetBackColor(BAR_BG)
        s.bar = NewCtl(w)
        s.bar:SetBackColor(BAR_FG)
        s.icon.MouseEnter = function()
            B.ShowTip(this, s)
        end
        s.icon.MouseLeave = function()
            B.HideTip()
        end
        s.hidden = true
        s.icon:SetVisible(false)
        s.num:SetVisible(false)
        s.name:SetVisible(false)
        s.barBg:SetVisible(false)
        s.bar:SetVisible(false)
        self.slots[i] = s
    end

    -- reloj: solo corre con un jefe activo y la ventana a la vista
    self.nextTick = 0
    self.errors = 0
    w.Update = function()
        local now = Now()
        if now < this.nextTick then
            return
        end
        this.nextTick = now + TICK
        local ok, err = pcall(B.Tick, now)
        if not ok then
            this.errors = this.errors + 1
            Report(err)
            if this.errors >= 5 then
                w:SetWantsUpdates(false)
            end
        end
    end
    return self
end

-- posiciones y tamanos de cada modelo (solo al cambiar opciones o jefe)
function Panel:Layout(count)
    local model = B.Get("model")
    local size = B.Get("size")
    local w = self.win
    local headH = 14
    local gap = math.max(2, math.floor(size / 8))
    local numH = math.max(12, math.floor(size * 0.55))
    local nameW = math.max(110, size * 5)
    local W, H
    self.model, self.size = model, size
    self.head:SetPosition(0, 0)
    if model == 2 then
        W = size + gap + nameW + 40
        H = headH + gap + count * (size + gap)
    elseif model == 3 then
        W = math.max(60, count * (size + gap) + gap)
        H = headH + gap + size + gap
    else
        W = math.max(90, count * (size + gap) + gap)
        H = headH + gap + size + numH + gap
    end
    self.head:SetSize(W, headH)
    self.title:SetPosition(4, 0)
    self.title:SetSize(W - 8, headH)
    w:SetSize(W, H)
    for i = 1, MAX_SLOTS do
        local s = self.slots[i]
        local x, y
        if model == 2 then
            x, y = gap, headH + gap + (i - 1) * (size + gap)
            s.name:SetPosition(x + size + gap, y)
            s.name:SetSize(nameW, math.floor(size * 0.6))
            s.barBg:SetPosition(x + size + gap, y + math.floor(size * 0.65))
            s.barBg:SetSize(nameW, math.max(3, math.floor(size * 0.2)))
            s.num:SetPosition(x + size + gap + nameW, y)
            s.num:SetSize(36, size)
            s.num:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        else
            x, y = gap + (i - 1) * (size + gap), headH + gap
            s.num:SetPosition(x - 4, y + size)
            s.num:SetSize(size + 8, numH)
            s.num:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        end
        s.x, s.y = x, y
        s.icon:SetPosition(x, y)
        s.icon:SetSize(size, size)
        local t = size >= 32 and 2 or 1
        PlaceRing(s.ring, x - t, y - t, size + 2 * t, size + 2 * t, t)
        s.num:SetFont(Font(size))
        s.img = nil
        s.text = nil
        s.barW = -1
        s.skill = nil
    end
    self.count = count
end

local function SetSlotVisible(s, vis, model)
    if s.hidden == (not vis) and s.model == model then
        return
    end
    s.hidden = not vis
    s.model = model
    s.icon:SetVisible(vis)
    s.num:SetVisible(vis and model ~= 3)
    local list = vis and model == 2
    s.name:SetVisible(list)
    s.barBg:SetVisible(list)
    s.bar:SetVisible(list)
    if not vis then
        ShowRing(s.ring, nil)
    end
end

-- orden: primero lo que viene antes (contador mas corto)
local sortReady = nil
local function SortOrder(a, b)
    local ra = sortReady[a]
    local rb = sortReady[b]
    if ra == nil and rb == nil then
        return a < b
    end
    if ra == nil then
        return false
    end
    if rb == nil then
        return true
    end
    if ra == rb then
        return a < b
    end
    return ra < rb
end

function B.Tick(now)
    local cur = B.cur
    local p = B.panel
    -- fin de combate (jefe muerto, reinicio o huida)
    if B.endAt ~= nil and now >= B.endAt and not B.inCombat then
        B.endAt = nil
        if cur ~= nil then
            cur.pulled = false
            for i in pairs(cur.ready) do cur.ready[i] = nil end
            for i in pairs(cur.flash) do cur.flash[i] = nil end
        end
        B.Refresh()
        return
    end
    if B.alert ~= nil and B.alert.untilT ~= nil and now >= B.alert.untilT then
        B.alert.untilT = nil
        B.alert.win:SetVisible(false)
    end
    if cur == nil or p == nil or not p.win:IsVisible() then
        return
    end
    local model = p.model
    local order = p.order
    sortReady = cur.ready
    table.sort(order, SortOrder)
    local n = math.min(#order, p.count)
    for k = 1, MAX_SLOTS do
        local s = p.slots[k]
        if k <= n then
            local i = order[k]
            local skill = cur.skills[i]
            if s.skill ~= i then
                s.skill = i
                local img = RES .. "sj_" .. TAGS[cur.prim[i]].g .. "_" .. p.size .. ".tga"
                if s.img ~= img then
                    s.img = img
                    s.icon:SetBackground(img)
                end
                if model == 2 then
                    s.name:SetText(skill[1])
                end
                s.text = nil
                s.barW = -1
            end
            SetSlotVisible(s, true, model)
            local ready = cur.ready[i]
            local left = ready ~= nil and (ready - now) or nil
            local flash = cur.flash[i] ~= nil and now < cur.flash[i]
            -- numero (solo cuando cambia el segundo)
            local text = ""
            if left ~= nil and left > 0 then
                local secs = math.floor(left + 0.999)
                if secs ~= s.secs then
                    s.secs = secs
                    if secs >= 60 then
                        s.secsText = string.format("%d:%02d", math.floor(secs / 60), secs % 60)
                    else
                        s.secsText = tostring(secs)
                    end
                end
                text = s.secsText
            else
                s.secs = nil
            end
            if text ~= s.text then
                s.text = text
                s.num:SetText(text)
            end
            local col = TEXT
            local ring = nil
            if flash then
                ring = (math.floor(now * 4) % 2 == 0) and RING_NOW or nil
                col = TEXT_NOW
            elseif left ~= nil and left <= SOON then
                ring = RING_SOON
                col = TEXT_SOON
            end
            if s.col ~= col then
                s.col = col
                s.num:SetForeColor(col)
            end
            ShowRing(s.ring, ring)
            if model == 2 then
                local cd = tonumber(skill[3]) or 0
                local frac = 0
                if left ~= nil and left > 0 and cd > 0 then
                    frac = 1 - math.min(1, left / cd)
                elseif left == nil or left <= 0 then
                    frac = 1
                end
                local bw = math.floor(s.barBg:GetWidth() * frac + 0.5)
                if bw ~= s.barW then
                    s.barW = bw
                    s.bar:SetPosition(s.barBg:GetLeft(), s.barBg:GetTop())
                    s.bar:SetSize(math.max(0, bw), s.barBg:GetHeight())
                end
            end
        else
            if not s.hidden then
                SetSlotVisible(s, false, model)
                s.skill = nil
            end
        end
    end
end

-- aplica opciones / jefe nuevo: visibilidad, tamano, iconos
function B.Refresh()
    if B._inited ~= true then
        return
    end
    local ok, err = pcall(function()
        local cur = B.cur
        local enabled = B.Get("enabled")
        if cur ~= nil then
            BuildRelevant(cur)
        end
        local p = B.panel
        local model = B.Get("model")
        local show = enabled and cur ~= nil and model ~= 4 and #cur.rel > 0
        if show and B.Get("onlyCombat") and not B.inCombat and not B.demo then
            show = false
        end
        if p == nil then
            if not show and cur == nil then
                return
            end
            p = Panel.New()
            B.panel = p
        end
        if cur ~= nil then
            p.order = {}
            for k, i in ipairs(cur.rel) do
                p.order[k] = i
            end
            local count = math.min(#cur.rel, B.Get("maxIcons"), MAX_SLOTS)
            p:Layout(math.max(1, count))
            local inst = cur.inst ~= nil and cur.inst.s or ""
            p.title:SetText(cur.name .. (inst ~= "" and ("  \194\183  " .. inst) or ""))
        end
        local x, y = B.Get("x"), B.Get("y")
        if x < 0 or y < 0 then
            x = math.floor(Turbine.UI.Display.GetWidth() / 2) - 120
            y = math.floor(Turbine.UI.Display.GetHeight() * 0.18)
        end
        p.win:SetPosition(x, y)
        pcall(p.win.SetOpacity, p.win, B.Get("opacity") / 100)
        p.win:SetVisible(show)
        p.win:SetWantsUpdates(cur ~= nil)
        p.nextTick = 0
    end)
    if not ok then
        Report(err)
    end
end

-- ---------------------------------------------------------------------
-- Alerta central (icono grande + texto) y descripcion al pasar el raton
-- ---------------------------------------------------------------------
local function Desc(skill, prim)
    local out = {}
    local tags = skill[2]
    for i = 1, #tags do
        local t = TAGS[string.sub(tags, i, i)]
        if t ~= nil then
            out[#out + 1] = "\226\128\162 " .. L(t.es, t.en) .. ": " .. L(t.tes, t.ten)
        end
    end
    local cd = tonumber(skill[3]) or 0
    local icd = tonumber(skill[4]) or 0
    out[#out + 1] = L("Reutilizaci\195\179n: ", "Cooldown: ") .. cd .. " s   " .. L("Primer uso: ", "First use: ") .. icd .. " s"
    if tonumber(skill[5]) ~= nil then
        out[#out + 1] = L("Lanzamiento: ", "Cast: ") .. skill[5] .. " s"
    end
    if type(skill[8]) == "string" and skill[8] ~= "" then
        out[#out + 1] = L("Alcance: ", "Area: ") .. skill[8]
    end
    return table.concat(out, "\n")
end

function B.ShowAlert(i)
    local cur = B.cur
    if cur == nil then
        return
    end
    local ok, err = pcall(function()
        local a = B.alert
        if a == nil then
            a = {}
            local w = Turbine.UI.Window()
            w:SetSize(360, 56)
            w:SetMouseVisible(false)
            w:SetBackColor(Turbine.UI.Color(0.70, 0.05, 0.04, 0.03))
            pcall(w.SetZOrder, w, 60)
            a.win = w
            a.icon = Turbine.UI.Control()
            a.icon:SetParent(w)
            a.icon:SetPosition(4, 4)
            a.icon:SetSize(48, 48)
            pcall(a.icon.SetBlendMode, a.icon, Turbine.UI.BlendMode.AlphaBlend)
            a.icon:SetMouseVisible(false)
            a.title = NewLabel(w, Turbine.UI.Lotro.Font.Verdana18 or Turbine.UI.Lotro.Font.Verdana16, Turbine.UI.ContentAlignment.MiddleLeft)
            a.title:SetPosition(60, 2)
            a.title:SetSize(296, 28)
            a.title:SetForeColor(TEXT_SOON)
            a.sub = NewLabel(w, Turbine.UI.Lotro.Font.Verdana12 or Turbine.UI.Lotro.Font.Verdana10, Turbine.UI.ContentAlignment.MiddleLeft)
            a.sub:SetPosition(60, 30)
            a.sub:SetSize(296, 22)
            a.ring = NewRing(w)
            PlaceRing(a.ring, 0, 0, 360, 56, 2)
            B.alert = a
        end
        local skill = cur.skills[i]
        local t = TAGS[cur.prim[i]]
        a.icon:SetBackground(RES .. "sj_" .. t.g .. "_48.tga")
        a.title:SetText(skill[1])
        a.sub:SetText(L(t.tes, t.ten))
        ShowRing(a.ring, RING_NOW)
        local x, y = B.Get("ax"), B.Get("ay")
        if x < 0 or y < 0 then
            x = math.floor((Turbine.UI.Display.GetWidth() - 360) / 2)
            y = math.floor(Turbine.UI.Display.GetHeight() * 0.30)
        end
        a.win:SetPosition(x, y)
        a.win:SetVisible(true)
        a.untilT = Now() + ALERT_TIME
        -- la alerta se apaga desde el reloj del panel; si el panel no se ve
        -- (modelo "Solo alertas"), el reloj sigue igual porque hay jefe activo
        if B.panel ~= nil then
            B.panel.win:SetWantsUpdates(true)
        end
    end)
    if not ok then
        Report(err)
    end
end

function B.ShowTip(panel, s)
    local cur = B.cur
    if cur == nil or s.skill == nil then
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
            tip.title = NewLabel(w, Turbine.UI.Lotro.Font.Verdana14 or Turbine.UI.Lotro.Font.Verdana12, Turbine.UI.ContentAlignment.TopLeft)
            tip.title:SetForeColor(GOLD)
            tip.title:SetPosition(8, 6)
            tip.title:SetSize(304, 20)
            tip.body = NewLabel(w, Turbine.UI.Lotro.Font.Verdana12 or Turbine.UI.Lotro.Font.Verdana10, Turbine.UI.ContentAlignment.TopLeft)
            tip.body:SetPosition(8, 28)
            tip.body:SetSize(304, 150)
            pcall(tip.body.SetMultiline, tip.body, true)
            B.tip = tip
        end
        local skill = cur.skills[s.skill]
        local body = Desc(skill, cur.prim[s.skill])
        local lines = 1
        for _ in string.gmatch(body, "\n") do
            lines = lines + 1
        end
        local h = 34 + lines * 16
        tip.win:SetSize(320, h + 6)
        tip.body:SetSize(304, h - 28)
        tip.title:SetText(skill[1])
        tip.body:SetText(body)
        local px, py = panel.win:GetPosition()
        local x = px + s.x
        local y = py + s.y + (panel.size or 28) + 18
        if y + h > Turbine.UI.Display.GetHeight() then
            y = py - h - 10
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
-- Deteccion
-- ---------------------------------------------------------------------
local CHAT_TYPES = {}
pcall(function()
    local CT = Turbine.ChatType
    for _, k in ipairs({ "EnemyCombat", "Say", "Emote", "Standard", "Death" }) do
        if CT[k] ~= nil then
            CHAT_TYPES[CT[k]] = true
        end
    end
end)

function B.OnChat(sender, args)
    local cur = B.cur
    if cur == nil or args == nil or B.Get("enabled") ~= true then
        return
    end
    if args.ChatType ~= nil and CHAT_TYPES[args.ChatType] ~= true then
        return
    end
    local msg = args.Message
    if type(msg) ~= "string" or #msg < 6 then
        return
    end
    local low = string.lower(msg)
    local names = cur.names
    for i = 1, #names do
        local nm = names[i]
        if nm and string.find(low, nm, 1, true) ~= nil then
            B.Trigger(i)
            return
        end
    end
    local yells = cur.yells
    if #yells > 0 then
        local nk = Norm(msg)
        for k = 1, #yells do
            local y = yells[k]
            if string.find(nk, y[1], 1, true) ~= nil then
                B.Trigger(y[2])
                return
            end
        end
    end
end

local function OnEffectAdded(sender, args)
    local cur = B.cur
    if cur == nil or sender == nil or args == nil then
        return
    end
    local ok, icon = pcall(function()
        local e = sender:Get(args.Index)
        return e ~= nil and e:GetIcon() or nil
    end)
    if ok and icon ~= nil then
        local i = cur.icons[icon]
        if i ~= nil then
            B.Trigger(i)
        end
    end
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
        if B.cur ~= nil then
            B.StartPull()
        end
    else
        B.endAt = Now() + END_DELAY
        if B.panel ~= nil and B.cur ~= nil then
            B.panel.win:SetWantsUpdates(true)
        end
    end
    if B.Get("onlyCombat") then
        B.Refresh()
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

function B.Init()
    if B._inited then
        return
    end
    B._inited = true
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    B.player = player
    B.hTarget = AddCallback(player, "TargetChanged", Safe(OnTargetChanged))
    B.hCombat = AddCallback(player, "InCombatChanged", Safe(OnCombatChanged))
    local okE, effects = pcall(function() return player:GetEffects() end)
    if okE and effects ~= nil then
        B.effects = effects
        B.hEffect = AddCallback(effects, "EffectAdded", Safe(OnEffectAdded))
    end
    if type(_G.LQA_ChatListeners) ~= "table" then
        _G.LQA_ChatListeners = {}
    end
    B.hChat = Safe(B.OnChat)
    _G.LQA_ChatListeners["WorldMapBoss"] = B.hChat
    pcall(function() B.inCombat = player:IsInCombat() == true end)
    LoadValues()

    -- vigilante: cada 5 s comprueba que los eventos sigan enganchados
    -- (costo minimo: unas comparaciones)
    local watch = Turbine.UI.Control()
    watch:SetVisible(false)
    local nextCheck = 0
    watch.Update = function()
        local now = Now()
        if now < nextCheck then
            return
        end
        nextCheck = now + 5
        pcall(function()
            EnsureCallback(B.player, "TargetChanged", B.hTarget)
            EnsureCallback(B.player, "InCombatChanged", B.hCombat)
            EnsureCallback(B.effects, "EffectAdded", B.hEffect)
            if type(_G.LQA_ChatListeners) == "table" and _G.LQA_ChatListeners["WorldMapBoss"] == nil then
                _G.LQA_ChatListeners["WorldMapBoss"] = B.hChat
            end
        end)
    end
    watch:SetWantsUpdates(true)
    B.watch = watch
end

function B.Shutdown()
    pcall(function()
        RemoveCallback(B.player, "TargetChanged", B.hTarget)
        RemoveCallback(B.player, "InCombatChanged", B.hCombat)
        RemoveCallback(B.effects, "EffectAdded", B.hEffect)
        if type(_G.LQA_ChatListeners) == "table" then
            _G.LQA_ChatListeners["WorldMapBoss"] = nil
        end
        if B.watch ~= nil then
            B.watch:SetWantsUpdates(false)
        end
        if B.panel ~= nil then
            B.panel.win:SetWantsUpdates(false)
            B.panel.win:SetVisible(false)
        end
        if B.alert ~= nil then
            B.alert.win:SetVisible(false)
        end
        B.HideTip()
        if B.opt ~= nil then
            B.opt.win:SetVisible(false)
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
        B.cur.pulled = false
        B.StartPull()
        local first = B.cur.rel[1]
        if first ~= nil then
            B.Trigger(first)
        end
        B.Refresh()
    end
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
    if low == "off" or low == "quitar" or low == "clear" then
        B.demo = false
        B.Clear()
        return
    end
    local key, idx = FindBoss(arg)
    if key ~= nil and B.Activate(key, idx) then
        Turbine.Shell.WriteLine("<rgb=#C9A66B>" .. L("Se\195\177ales de jefe: ", "Boss signals: ") .. B.cur.name .. "</rgb>")
    else
        Turbine.Shell.WriteLine("<rgb=#C9A66B>" .. L("Se\195\177ales de jefe: no encontr\195\169 ese jefe.", "Boss signals: boss not found.") .. "</rgb>")
    end
end

-- ---------------------------------------------------------------------
-- Ventana de opciones
-- ---------------------------------------------------------------------
local OPT_ROWS = {
    { key = "enabled", es = "Se\195\177ales activadas", en = "Signals enabled" },
    { key = "model", es = "Modelo", en = "Style", names = MODEL_NAMES },
    { key = "size", es = "Tama\195\177o de los iconos", en = "Icon size" },
    { key = "role", es = "Rol", en = "Role", names = ROLE_NAMES },
    { key = "maxIcons", es = "M\195\161ximo de iconos", en = "Max icons" },
    { key = "alerts", es = "Alerta central", en = "Center alert" },
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

local function BuildOptions()
    local o = {}
    local W, ROW = 380, 28
    local H = 52 + #OPT_ROWS * ROW + 46
    local w = Turbine.UI.Lotro.Window()
    o.win = w
    w:SetSize(W, H)
    w:SetPosition(math.floor((Turbine.UI.Display.GetWidth() - W) / 2), math.floor((Turbine.UI.Display.GetHeight() - H) / 2))
    w:SetVisible(false)
    o.rows = {}
    for i, row in ipairs(OPT_ROWS) do
        local y = 40 + (i - 1) * ROW
        local lb = NewLabel(w, Turbine.UI.Lotro.Font.Verdana14 or Turbine.UI.Lotro.Font.Verdana12, Turbine.UI.ContentAlignment.MiddleLeft)
        lb:SetPosition(20, y)
        lb:SetSize(200, ROW - 2)
        local bt = Turbine.UI.Lotro.Button()
        bt:SetParent(w)
        bt:SetPosition(220, y + 2)
        bt:SetSize(140, 22)
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
            B.demo = false
            B.Clear()
        else
            B.Demo()
        end
        B.RefreshOptions()
    end
    o.state = NewLabel(w, Turbine.UI.Lotro.Font.Verdana12 or Turbine.UI.Lotro.Font.Verdana10, Turbine.UI.ContentAlignment.MiddleLeft)
    o.state:SetPosition(190, y)
    o.state:SetSize(180, 24)
    B.opt = o
    return o
end

function B.RefreshOptions()
    local o = B.opt
    if o == nil then
        return
    end
    o.win:SetText(L("Se\195\177ales de jefe", "Boss signals"))
    for _, r in ipairs(o.rows) do
        r.label:SetText(L(r.row.es, r.row.en))
        r.button:SetText(ValueText(r.row))
    end
    o.demo:SetText(B.demo and L("Quitar prueba", "Stop test") or L("Probar", "Test"))
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
