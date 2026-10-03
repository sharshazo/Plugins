-- LOTRO_Quest_Assistant/UI/TrackerFireFX.lua
--
-- Efectos de fuego del Tracker (pedido del usuario, 2026-10-01: "el sistema
-- de brillo y destello como lo que hicimos con LUI y los titulos... en la
-- ventana tracker, pero otro tipo de efecto, destellos de fuego"; el anillo
-- y el borde del pergamino distintos, en efecto y en color, y continuos).
--
--   * ANILLO: la inscripcion arde (brasa que late) y llamas que lamen el
--     borde de arriba del anillo (12 cuadros en bucle), con brasas rojo-
--     naranja que suben un poco.
--   * TITULO: cada pocos segundos una lengua de fuego recorre la placa de
--     "Misiones Activas" (12 cuadros) con chispas doradas.
--   * BORDES: fuego elfico AZUL: brillo azul que respira siguiendo el borde
--     rasgado de los costados del pergamino y chispas/llamitas azules que
--     suben por los costados.
--   * Al aceptar o completar una mision: llamarada (mas brasas, mas brillo
--     y un pase de fuego por el titulo) durante unos segundos.
--
-- Solo imagenes y opacidad/posicion: no toca filas, botones, eventos ni la
-- logica del Tracker. Todo va DENTRO del pergamino (hijo de pageBg, que
-- queda debajo de la lista), sin mouse, asi que nunca tapa ni bloquea nada.
-- Las imagenes salen del mismo tracker_parchment.tga (307x425) y calzan pixel
-- a pixel (SetBackground no reescala). "/trackerfuego" lo apaga o lo prende
-- (se guarda por personaje en el estado de misiones).
import "Turbine"
import "Turbine.UI"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}
LQA.UI.TrackerFireFX = LQA.UI.TrackerFireFX or {}
local FX = LQA.UI.TrackerFireFX

local RES = "LOTRO_Quest_Assistant/Resources/Book/tracker_fx_"
local FRAME_TIME = 1 / 30
local TWO_PI = 2 * math.pi

-- anillo (coordenadas del pergamino, igual que pageBg)
local RING_X, RING_Y, RING_W, RING_H = 145, 296, 159, 129
local RING_FRAMES = 12
local RING_FRAME_TIME = 0.075
-- puntos del borde de arriba del anillo (de ahi salen las brasas)
local RING_RIM = {
    { 187, 378 }, { 193, 372 }, { 199, 368 }, { 205, 364 }, { 211, 361 }, { 217, 359 },
    { 223, 357 }, { 229, 355 }, { 235, 353 }, { 241, 353 }, { 247, 354 }, { 253, 359 },
}

-- titulo
local TITLE_X, TITLE_Y, TITLE_W, TITLE_H = 62, 4, 190, 36
local TITLE_FRAMES = 12
local TITLE_FRAME_TIME = 0.07
local TITLE_EVERY = 5.5

-- borde rasgado del papel cada 10 px: { y, x izquierda, x derecha }
local EDGES = {
    { 70, 29, 271 }, { 80, 28, 266 }, { 90, 30, 273 }, { 100, 27, 273 }, { 110, 27, 275 },
    { 120, 28, 272 }, { 130, 29, 274 }, { 140, 30, 273 }, { 150, 34, 273 }, { 160, 28, 271 },
    { 170, 26, 268 }, { 180, 27, 270 }, { 190, 28, 270 }, { 200, 27, 269 }, { 210, 28, 270 },
    { 220, 28, 270 }, { 230, 27, 273 }, { 240, 33, 275 }, { 250, 28, 273 }, { 260, 26, 275 },
    { 270, 25, 276 }, { 280, 26, 277 }, { 290, 26, 277 }, { 300, 27, 280 }, { 310, 26, 281 },
    { 320, 25, 282 }, { 330, 27, 283 }, { 340, 28, 284 },
}

-- particulas: cuantas como maximo y cada cuanto nace una (s)
local RING_EMBERS, RING_EVERY = 12, 0.22
local BLUE_EMBERS, BLUE_EVERY = 18, 0.15
local GOLD_SPARKS = 6
local BURST_TIME = 3.0          -- llamarada al aceptar/completar
local BURST_RATE = 3.5          -- nacen 3.5 veces mas seguido durante la llamarada

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

local function make_pool(parent, count, images)
    local pool = {}
    for i = 1, count do
        local img = images[((i - 1) % #images) + 1]
        local c = layer(parent, 0, 0, img.w, img.h, RES .. img.file)
        c:SetVisible(false)
        pool[i] = { ctl = c, w = img.w, h = img.h, alive = false }
    end
    return pool
end

local function free_particle(pool)
    for i = 1, #pool do
        if pool[i].alive ~= true then
            return pool[i]
        end
    end
    return nil
end

-- mueve una particula: sube "rise" px en "life" s, ondula y se desvanece
local function step_particle(p, now)
    local age = now - p.born
    if age >= p.life then
        p.alive = false
        p.ctl:SetVisible(false)
        return
    end
    local t = age / p.life
    local ease = 1 - ((1 - t) * (1 - t))
    local x = p.x0 + (p.drift * t) + (p.sway * math.sin((age * p.freq) + p.phase))
    local y = p.y0 - (p.rise * ease)
    local o
    if t < 0.15 then
        o = t / 0.15
    elseif t > 0.6 then
        o = (1 - t) / 0.4
    else
        o = 1
    end
    o = o * (0.75 + (0.25 * math.sin((age * 19) + p.phase)))
    if o < 0 then o = 0 elseif o > 1 then o = 1 end
    p.ctl:SetPosition(math.floor(x + 0.5) - math.floor(p.w / 2), math.floor(y + 0.5) - math.floor(p.h / 2))
    p.ctl:SetOpacity(o * p.peak)
end

function FX.Attach(hud, page)
    if hud == nil or page == nil or hud.fireFx ~= nil then
        return
    end
    local fx = {
        hud = hud,
        started = Turbine.Engine.GetGameTime(),
        last = 0,
        burst_until = 0,
        ring_frame = 0,
        ring_frame_at = 0,
        title_next = 0,
        title_start = nil,
        title_frame = 0,
        ring_spawn_at = 0,
        blue_spawn_at = 0,
        gold_spawn_at = 0,
        shown = true,
        broken = false,
    }
    hud.fireFx = fx

    -- de atras hacia adelante (todo debajo de la lista: hijos de pageBg)
    fx.edge = layer(page, 0, 0, 307, 425, RES .. "borde_azul.tga")
    fx.blue = make_pool(page, BLUE_EMBERS, {
        { file = "llama_azul_7x11.tga", w = 7, h = 11 }, { file = "llama_azul_9x15.tga", w = 9, h = 15 },
        { file = "llama_azul_12x20.tga", w = 12, h = 20 }, { file = "fuego_azul_18.tga", w = 18, h = 18 },
        { file = "llama_azul_9x15.tga", w = 9, h = 15 },
    })
    fx.ring_glow = layer(page, RING_X, RING_Y, RING_W, RING_H, RES .. "anillo_brasa.tga")
    fx.ring_flame = layer(page, RING_X, RING_Y, RING_W, RING_H, RES .. "anillo_llama_1.tga")
    fx.ring = make_pool(page, RING_EMBERS, {
        { file = "brasa_6.tga", w = 6, h = 6 }, { file = "brasa_8.tga", w = 8, h = 8 }, { file = "brasa_11.tga", w = 11, h = 11 },
    })
    fx.title = layer(page, TITLE_X, TITLE_Y, TITLE_W, TITLE_H, RES .. "titulo_barrido_1.tga")
    fx.title:SetVisible(false)
    fx.gold = make_pool(page, GOLD_SPARKS, { { file = "chispa_oro_8.tga", w = 8, h = 8 } })
    fx.title_next = fx.started + 2.0

    -- llamarada al aceptar o completar (eventos que solo salen cuando la
    -- mision cambia de verdad, ver Core/QuestStateManager.lua)
    local function burst()
        local now = Turbine.Engine.GetGameTime()
        fx.burst_until = now + BURST_TIME
        if fx.title_start == nil then
            fx.title_next = now
        end
    end
    if LQA.Core ~= nil and LQA.Core.EventBus ~= nil then
        LQA.Core.EventBus:Subscribe("QUEST_JUST_ACCEPTED", burst)
        LQA.Core.EventBus:Subscribe("QUEST_JUST_COMPLETED", burst)
    end

    fx.ticker = Turbine.UI.Control()
    fx.ticker:SetParent(hud)
    fx.ticker:SetVisible(false)
    fx.ticker:SetWantsUpdates(true)
    fx.ticker.Update = function()
        if fx.broken == true then
            return
        end
        local ok, err = pcall(FX.Tick, fx)
        if ok ~= true then
            -- un error nunca se repite en cada cuadro: se apaga el efecto
            fx.broken = true
            pcall(FX.SetShown, fx, false)
            Turbine.Shell.WriteLine("<rgb=#FF8800>QuestSync: efectos del Tracker apagados (" .. tostring(err) .. ")</rgb>")
        end
    end
end

function FX.Enabled()
    local st = _G.QuestStateManager ~= nil and QuestStateManager.State or nil
    return not (st ~= nil and st.fxOff == true)
end

function FX.SetShown(fx, shown)
    if fx.shown == shown then
        return
    end
    fx.shown = shown
    fx.edge:SetVisible(shown)
    fx.ring_glow:SetVisible(shown)
    fx.ring_flame:SetVisible(shown)
    fx.title:SetVisible(false)
    fx.title_start = nil
    local pools = { fx.blue, fx.ring, fx.gold }
    for _, pool in ipairs(pools) do
        for i = 1, #pool do
            pool[i].alive = false
            pool[i].ctl:SetVisible(false)
        end
    end
end

local function spawn(pool, now, x, y, rise, life, sway, drift, peak)
    local p = free_particle(pool)
    if p == nil then
        return
    end
    p.alive = true
    p.born = now
    p.x0, p.y0 = x, y
    p.rise, p.life = rise, life
    p.sway, p.drift = sway, drift
    p.freq = rnd(2.0, 4.0)
    p.phase = rnd(0, TWO_PI)
    p.peak = peak
    p.ctl:SetOpacity(0)
    p.ctl:SetVisible(true)
    step_particle(p, now)
end

function FX.Tick(fx)
    local now = Turbine.Engine.GetGameTime()
    if now - fx.last < FRAME_TIME then
        return
    end
    fx.last = now

    local want = FX.Enabled() and fx.hud:IsVisible()
    FX.SetShown(fx, want)
    if want ~= true then
        return
    end

    local burst = now < fx.burst_until
    local boost = burst and 1 or 0
    local rate = burst and BURST_RATE or 1

    -- BORDES: fuego elfico azul que respira (lento) con un titileo leve
    local breath = 0.5 + (0.5 * math.sin(TWO_PI * now / 3.4))
    local flick = 0.06 * math.sin(now * 13.1) * math.sin(now * 4.7)
    fx.edge:SetOpacity(math.min(1, 0.32 + (0.30 * breath) + flick + (0.25 * boost)))

    -- ANILLO: la inscripcion arde y las llamas avanzan de cuadro
    local ember = 0.62 + (0.18 * math.sin(now * 7.3)) + (0.10 * math.sin(now * 17.9 + 1.3))
    fx.ring_glow:SetOpacity(math.min(1, ember + (0.3 * boost)))
    if now >= fx.ring_frame_at then
        fx.ring_frame_at = now + RING_FRAME_TIME
        fx.ring_frame = (fx.ring_frame % RING_FRAMES) + 1
        fx.ring_flame:SetBackground(RES .. "anillo_llama_" .. tostring(fx.ring_frame) .. ".tga")
    end
    fx.ring_flame:SetOpacity(math.min(1, 0.72 + (0.12 * math.sin(now * 9.1)) + (0.25 * boost)))

    -- TITULO: una pasada de fuego cada TITLE_EVERY s (o ya, con llamarada)
    if fx.title_start == nil and now >= fx.title_next then
        fx.title_start = now
        fx.title_frame = 0
        fx.title:SetVisible(true)
    end
    if fx.title_start ~= nil then
        local f = math.floor((now - fx.title_start) / TITLE_FRAME_TIME) + 1
        if f > TITLE_FRAMES then
            fx.title:SetVisible(false)
            fx.title_start = nil
            fx.title_next = now + (burst and 1.2 or TITLE_EVERY)
        else
            if f ~= fx.title_frame then
                fx.title_frame = f
                fx.title:SetBackground(RES .. "titulo_barrido_" .. tostring(f) .. ".tga")
                -- chispas doradas que saltan donde pasa el fuego
                if f % 3 == 0 then
                    local sx = TITLE_X - 24 + ((TITLE_W + 48) * (f - 1) / (TITLE_FRAMES - 1))
                    if sx > TITLE_X + 8 and sx < TITLE_X + TITLE_W - 8 then
                        spawn(fx.gold, now, sx + rnd(-6, 6), TITLE_Y + rnd(18, 26), rnd(8, 14), rnd(0.5, 0.8), rnd(1, 2), rnd(-3, 3), 1)
                    end
                end
            end
            fx.title:SetOpacity(1)
        end
    end

    -- particulas: nacen...
    if now >= fx.ring_spawn_at then
        fx.ring_spawn_at = now + (RING_EVERY / rate) * rnd(0.6, 1.4)
        local pt = RING_RIM[math.random(1, #RING_RIM)]
        spawn(fx.ring, now, pt[1] + rnd(-3, 3), pt[2] - rnd(0, 4), rnd(18, 34) + (12 * boost), rnd(0.9, 1.5),
            rnd(1.5, 3.5), rnd(-4, 4), 1)
    end
    if now >= fx.blue_spawn_at then
        fx.blue_spawn_at = now + (BLUE_EVERY / rate) * rnd(0.6, 1.4)
        local e = EDGES[math.random(1, #EDGES)]
        local left = math.random() < 0.5
        local x = left and (e[2] + rnd(1, 7)) or (e[3] - rnd(1, 7))
        spawn(fx.blue, now, x, e[1] + rnd(-5, 5), rnd(28, 60) + (15 * boost), rnd(1.4, 2.4),
            rnd(1.5, 3.0), left and rnd(-5, 1) or rnd(-1, 5), 1)
    end
    -- ...y se mueven
    local pools = { fx.blue, fx.ring, fx.gold }
    for _, pool in ipairs(pools) do
        for i = 1, #pool do
            local p = pool[i]
            if p.alive == true then
                step_particle(p, now)
            end
        end
    end
end

-- "/trackerfuego": prende o apaga los efectos (se guarda por personaje)
local FireCommand = Turbine.ShellCommand()
function FireCommand:Execute(command, arguments)
    if _G.QuestStateManager == nil or QuestStateManager.State == nil then
        return
    end
    local arg = string.lower(tostring(arguments or ""))
    local off
    if arg == "off" or arg == "apagar" then
        off = true
    elseif arg == "on" or arg == "prender" or arg == "encender" then
        off = false
    else
        off = not (QuestStateManager.State.fxOff == true)
    end
    QuestStateManager.State.fxOff = off or nil
    pcall(QuestStateManager.Save)
    Turbine.Shell.WriteLine("<rgb=#FFAA33>QuestSync: efectos de fuego del Tracker " ..
        (off and "apagados" or "encendidos") .. ".</rgb>")
end
function FireCommand:GetHelp()
    return "/trackerfuego [on|off] - prende o apaga los efectos de fuego del Tracker"
end
function FireCommand:GetShortHelp()
    return "Efectos de fuego del Tracker"
end
pcall(Turbine.Shell.AddCommand, "trackerfuego", FireCommand)
