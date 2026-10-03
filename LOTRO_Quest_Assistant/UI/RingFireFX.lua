-- LOTRO_Quest_Assistant/UI/RingFireFX.lua
--
-- (2026-10-01, pedido del usuario con captura: "agregarle el mismo aspecto
-- flameante a los anillos de este mismo addon... a los titulos grandes de
-- la ventana izquierda le puedes dar otro efecto")
--
--   * AttachRing: el MISMO fuego del anillo del Tracker (UI/TrackerFireFX.lua)
--     para el anillo de QuestSyncWindow (book_menu.tga) y el del libro de
--     "Nueva mision" (questbook.tga): la inscripcion arde, llamas que lamen
--     el borde de arriba (12 cuadros en bucle) y brasas que suben. Imagenes
--     derivadas de cada fondo (calzan pixel a pixel, SetBackground no
--     reescala). Llamarada al aceptar/completar una mision.
--   * AttachTitleStars: OTRO efecto para el titulo grande de QuestSyncWindow:
--     destellos de estrella dorado-blancos que titilan sobre las letras, y
--     cada pocos segundos una cascada de estrellas de izquierda a derecha.
--
-- Solo imagen/opacidad/posicion: no cambia textos, colores, botones ni
-- eventos de las ventanas. Todo es hijo del fondo (pageBg) y sin mouse: no
-- bloquea ningun clic. "/trackerfuego off" apaga tambien estos efectos
-- (QuestStateManager.State.fxOff). Un error interno apaga el efecto de esa
-- ventana una sola vez, sin repetir el error en cada cuadro.
import "Turbine"
import "Turbine.UI"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}
LQA.UI.RingFireFX = LQA.UI.RingFireFX or {}
local FX = LQA.UI.RingFireFX

local RES = "LOTRO_Quest_Assistant/Resources/Book/"
local FRAME_TIME = 1 / 30
local TWO_PI = 2 * math.pi
local RING_FRAMES = 12
local RING_FRAME_TIME = 0.075
local EMBERS, EMBER_EVERY = 10, 0.24
local BURST_TIME, BURST_RATE = 3.0, 3.5

-- titulo: tamano real de BookAntiquaBold24 medido en una captura del juego
local TITLE_CHAR_W = 8.8
local TITLE_LINE_H = 25
local STARS = 8
local STAR_EVERY = 0.45
local CASCADE_EVERY = 6.5
local STAR_FRAMES = { 9, 13, 17, 13, 9 }

local function rnd(a, b)
    return a + (math.random() * (b - a))
end

local function layer(parent, x, y, w, h, image)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    c:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    c:SetPosition(x, y)
    c:SetSize(w, h)
    if image ~= nil then
        c:SetBackground(image)
    end
    return c
end

local function enabled()
    local st = _G.QuestStateManager ~= nil and QuestStateManager.State or nil
    return not (st ~= nil and st.fxOff == true)
end

-- un solo "reloj" por ventana para todos sus efectos
local function ticker_for(win)
    if win.fxParts ~= nil then
        return win.fxParts
    end
    local parts = {}
    win.fxParts = parts
    win.fxBurstUntil = 0
    local broken = false
    local last = 0
    local t = Turbine.UI.Control()
    t:SetParent(win)
    t:SetVisible(false)
    t:SetWantsUpdates(true)
    t.Update = function()
        if broken then
            return
        end
        local now = Turbine.Engine.GetGameTime()
        if now - last < FRAME_TIME then
            return
        end
        last = now
        local show = enabled() and win:IsVisible()
        local ok, err = pcall(function()
            for i = 1, #parts do
                parts[i]:tick(now, show)
            end
        end)
        if ok ~= true then
            broken = true
            for i = 1, #parts do
                pcall(parts[i].tick, parts[i], now, false)
            end
            Turbine.Shell.WriteLine("<rgb=#FF8800>QuestSync: efectos de la ventana apagados (" .. tostring(err) .. ")</rgb>")
        end
    end
    win.fxTicker = t
    if LQA.Core ~= nil and LQA.Core.EventBus ~= nil then
        local function burst()
            win.fxBurstUntil = Turbine.Engine.GetGameTime() + BURST_TIME
        end
        LQA.Core.EventBus:Subscribe("QUEST_JUST_ACCEPTED", burst)
        LQA.Core.EventBus:Subscribe("QUEST_JUST_COMPLETED", burst)
    end
    return parts
end

-- ---------------------------------------------------------------------
-- Anillo en llamas
-- cfg = { prefix, x, y, w, h, rim = { {x,y}, ... } } (coordenadas de pageBg)
-- ---------------------------------------------------------------------
function FX.AttachRing(win, page, cfg)
    if win == nil or page == nil or cfg == nil or win.fxRing ~= nil then
        return
    end
    local parts = ticker_for(win)
    local r = {
        shown = true,
        frame = 0,
        frame_at = 0,
        spawn_at = 0,
        embers = {},
    }
    win.fxRing = r
    r.glow = layer(page, cfg.x, cfg.y, cfg.w, cfg.h, RES .. cfg.prefix .. "anillo_brasa.tga")
    r.flame = layer(page, cfg.x, cfg.y, cfg.w, cfg.h, RES .. cfg.prefix .. "anillo_llama_1.tga")
    local sizes = { 6, 8, 11 }
    for i = 1, EMBERS do
        local s = sizes[((i - 1) % #sizes) + 1]
        local c = layer(page, 0, 0, s, s, RES .. "tracker_fx_brasa_" .. tostring(s) .. ".tga")
        c:SetVisible(false)
        r.embers[i] = { ctl = c, size = s, alive = false }
    end

    function r:set_shown(shown)
        if self.shown == shown then
            return
        end
        self.shown = shown
        self.glow:SetVisible(shown)
        self.flame:SetVisible(shown)
        for i = 1, #self.embers do
            self.embers[i].alive = false
            self.embers[i].ctl:SetVisible(false)
        end
    end

    function r:tick(now, show)
        self:set_shown(show)
        if show ~= true then
            return
        end
        local burst = now < (win.fxBurstUntil or 0)
        local boost = burst and 1 or 0
        local ember = 0.62 + (0.18 * math.sin(now * 7.3)) + (0.10 * math.sin(now * 17.9 + 1.3))
        self.glow:SetOpacity(math.min(1, ember + (0.3 * boost)))
        if now >= self.frame_at then
            self.frame_at = now + RING_FRAME_TIME
            self.frame = (self.frame % RING_FRAMES) + 1
            self.flame:SetBackground(RES .. cfg.prefix .. "anillo_llama_" .. tostring(self.frame) .. ".tga")
        end
        self.flame:SetOpacity(math.min(1, 0.72 + (0.12 * math.sin(now * 9.1)) + (0.25 * boost)))

        if now >= self.spawn_at then
            self.spawn_at = now + (EMBER_EVERY / (burst and BURST_RATE or 1)) * rnd(0.6, 1.4)
            for i = 1, #self.embers do
                local p = self.embers[i]
                if p.alive ~= true then
                    local pt = cfg.rim[math.random(1, #cfg.rim)]
                    p.alive = true
                    p.born = now
                    p.x0, p.y0 = pt[1] + rnd(-3, 3), pt[2] - rnd(0, 4)
                    p.rise = rnd(18, 34) + (12 * boost)
                    p.life = rnd(0.9, 1.5)
                    p.sway, p.drift = rnd(1.5, 3.5), rnd(-4, 4)
                    p.freq, p.phase = rnd(2, 4), rnd(0, TWO_PI)
                    p.ctl:SetOpacity(0)
                    p.ctl:SetVisible(true)
                    break
                end
            end
        end
        for i = 1, #self.embers do
            local p = self.embers[i]
            if p.alive == true then
                local age = now - p.born
                if age >= p.life then
                    p.alive = false
                    p.ctl:SetVisible(false)
                else
                    local t = age / p.life
                    local ease = 1 - ((1 - t) * (1 - t))
                    local x = p.x0 + (p.drift * t) + (p.sway * math.sin((age * p.freq) + p.phase))
                    local y = p.y0 - (p.rise * ease)
                    local o = 1
                    if t < 0.15 then
                        o = t / 0.15
                    elseif t > 0.6 then
                        o = (1 - t) / 0.4
                    end
                    o = o * (0.75 + (0.25 * math.sin((age * 19) + p.phase)))
                    if o < 0 then o = 0 elseif o > 1 then o = 1 end
                    local half = math.floor(p.size / 2)
                    p.ctl:SetPosition(math.floor(x + 0.5) - half, math.floor(y + 0.5) - half)
                    p.ctl:SetOpacity(o)
                end
            end
        end
    end

    parts[#parts + 1] = r
end

-- ---------------------------------------------------------------------
-- Estrellas sobre el titulo (otro efecto, no fuego)
-- label: el Label del titulo (hijo de page); active(): true si hay algo
-- elegido (con "Selecciona un elemento..." no se muestran)
-- ---------------------------------------------------------------------
local function char_count(text)
    return #(string.gsub(text, "[\128-\191]", ""))
end

-- renglones aproximados del titulo: { {ancho en px}, ... }
local function title_lines(text, width)
    local per_line = math.max(1, math.floor(width / TITLE_CHAR_W))
    local lines = {}
    local current = 0
    for word in string.gmatch(text, "%S+") do
        local n = char_count(word)
        if current == 0 then
            current = n
        elseif current + 1 + n <= per_line then
            current = current + 1 + n
        else
            lines[#lines + 1] = current
            current = n
        end
    end
    if current > 0 then
        lines[#lines + 1] = current
    end
    local out = {}
    for i = 1, #lines do
        out[i] = math.min(width, math.floor(lines[i] * TITLE_CHAR_W))
    end
    return out
end

function FX.AttachTitleStars(win, page, label, active)
    if win == nil or page == nil or label == nil or win.fxTitle ~= nil then
        return
    end
    local parts = ticker_for(win)
    local s = {
        shown = true,
        text = nil,
        lines = {},
        spawn_at = 0,
        cascade_at = 0,
        cascade = nil,
        stars = {},
    }
    win.fxTitle = s
    for i = 1, STARS do
        local c = layer(page, 0, 0, 17, 17, RES .. "questsync_fx_estrella_9.tga")
        c:SetVisible(false)
        s.stars[i] = { ctl = c, alive = false, frame = 0 }
    end

    function s:set_shown(shown)
        if self.shown == shown then
            return
        end
        self.shown = shown
        for i = 1, #self.stars do
            self.stars[i].alive = false
            self.stars[i].ctl:SetVisible(false)
        end
        self.cascade = nil
    end

    function s:spawn(now, lx, ly)
        for i = 1, #self.stars do
            local p = self.stars[i]
            if p.alive ~= true then
                p.alive = true
                p.born = now
                p.life = rnd(0.55, 0.85)
                p.cx, p.cy = lx, ly
                p.frame = 0
                p.ctl:SetOpacity(0)
                p.ctl:SetVisible(true)
                return
            end
        end
    end

    -- punto al azar sobre las letras (coordenadas de pageBg)
    function s:random_point(line)
        local lx, ly = label:GetPosition()
        local n = #self.lines
        if n == 0 then
            return nil
        end
        local i = line or math.random(1, n)
        local w = self.lines[i]
        return lx + rnd(2, math.max(3, w - 2)), ly + ((i - 1) * TITLE_LINE_H) + rnd(5, TITLE_LINE_H - 5)
    end

    function s:tick(now, show)
        local on = show and (active == nil or active() == true) and label:IsVisible()
        self:set_shown(on)
        if on ~= true then
            return
        end
        local text = label:GetText() or ""
        if text ~= self.text then
            self.text = text
            local w = label:GetSize()
            self.lines = title_lines(text, w)
            self.cascade_at = now + 0.3   -- titulo nuevo: cascada enseguida
        end
        local burst = now < (win.fxBurstUntil or 0)

        if now >= self.spawn_at then
            self.spawn_at = now + (STAR_EVERY / (burst and 2.5 or 1)) * rnd(0.6, 1.4)
            local x, y = self:random_point()
            if x ~= nil then
                self:spawn(now, x, y)
            end
        end
        -- cascada: una estrella por letra-bloque, de izquierda a derecha
        if self.cascade == nil and now >= self.cascade_at and #self.lines > 0 then
            self.cascade = { line = 1, x = 0, next_at = now }
            self.cascade_at = now + CASCADE_EVERY
        end
        local c = self.cascade
        if c ~= nil and now >= c.next_at then
            local lx, ly = label:GetPosition()
            local w = self.lines[c.line]
            if w == nil then
                self.cascade = nil
            else
                self:spawn(now, lx + c.x + rnd(-2, 2), ly + ((c.line - 1) * TITLE_LINE_H) + rnd(6, TITLE_LINE_H - 6))
                c.x = c.x + 34
                c.next_at = now + 0.09
                if c.x > w then
                    c.line = c.line + 1
                    c.x = 0
                end
            end
        end

        for i = 1, #self.stars do
            local p = self.stars[i]
            if p.alive == true then
                local t = (now - p.born) / p.life
                if t >= 1 then
                    p.alive = false
                    p.ctl:SetVisible(false)
                else
                    local f = math.min(#STAR_FRAMES, math.floor(t * #STAR_FRAMES) + 1)
                    local size = STAR_FRAMES[f]
                    if f ~= p.frame then
                        p.frame = f
                        p.ctl:SetBackground(RES .. "questsync_fx_estrella_" .. tostring(size) .. ".tga")
                        p.ctl:SetSize(size, size)
                    end
                    local half = math.floor(size / 2)
                    p.ctl:SetPosition(math.floor(p.cx + 0.5) - half, math.floor(p.cy + 0.5) - half)
                    p.ctl:SetOpacity(math.sin(math.pi * t))
                end
            end
        end
    end

    parts[#parts + 1] = s
end
