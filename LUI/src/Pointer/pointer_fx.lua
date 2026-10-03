-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Efecto del puntero (pedido del jugador, 2026-10-02): un aura animada
-- pegada al raton para no perderlo en el juego. 7 estilos (anillo, halo,
-- esferas, fuego, runas, mira, estela), 6 colores, 3 tamanos, opacidad,
-- velocidad, "siempre" o "solo al mover", y "agitar para encontrar".
--
-- Como funciona:
--   * No se cambia la flecha del juego: se dibuja una ventanita
--     transparente que sigue a Turbine.UI.Display.GetMousePosition() en
--     cada cuadro. La ventana y todo lo que tiene NO toman el mouse
--     (SetMouseVisible(false)): los clics pasan al juego como siempre.
--   * Animacion: cada estilo es UNA hoja de 4x4 cuadros
--     (assets/ui/puntero/ptr_<estilo>_<color>_<tam>.tga). La ventana
--     recorta un cuadro y la hoja se corre por detras (mismo recorte que
--     el viewport del Mapa del Mundo) -- no se cambia de imagen por cuadro.
--   * Clic derecho (girar la camara): el juego esconde la flecha, pero el
--     efecto NO se apaga: queda en el ultimo lugar del raton, y al soltar la
--     flecha aparece adentro del efecto. En "solo al mover" el efecto
--     espera FADE_DELAY s quieto antes de irse.
--   * Imagenes a tamano real (sin el escalado nativo de LUI) y se esconde
--     con la interfaz (F12 / ocultar HUD), como las demas ventanas de LUI.
-- Todo lo que toca la API va en pcall: si algo fallara, el resto de LUI
-- sigue igual y el efecto simplemente no se ve.

import "Turbine.UI"
import "LUI.src.UI.Widgets.base_window"

local LUI = _G.LUI
LUI.Features.Pointer = LUI.Features.Pointer or {}
local Pointer = LUI.Features.Pointer

local UI = LUI.UI
local State = LUI.Settings.State
local Runtime = LUI.Runtime
local Windows = Runtime.Windows
local Apply = Runtime.Apply
local class = LUI.Core.class

local ASSET_DIR = "LUI/assets/ui/puntero/"
local FRAMES = 16
local GRID = 4
local TRAIL_N = 10              -- particulas de la estela
local TRAIL_DT = 0.02           -- s entre muestras de la estela
local FADE_DELAY = 2.5          -- s quieto antes de desvanecer ("solo al mover")
local FADE_TIME = 0.4
local SHAKE_WINDOW = 0.7        -- s en que se cuentan los vaivenes
local SHAKE_TURNS = 4           -- cambios de direccion para "agitar"
local SHAKE_MIN_PATH = 700      -- px recorridos dentro de SHAKE_WINDOW
local SHAKE_MIN_STEP = 6        -- px minimos de un tramo para contar
local BURST_TIME = 1.3
local BURST_COOLDOWN = 1.6
local TOP_Z = 2147483000

Pointer.STYLES = { "anillo", "halo", "esferas", "fuego", "runas", "mira", "estela" }
Pointer.COLORS = { "dorado", "azul", "verde", "rojo", "morado", "blanco" }
Pointer.SIZE_KEYS = { "s", "m", "l" }
Pointer.SIZES = { s = 48, m = 72, l = 96 }
Pointer.SPEEDS = { 0.6, 1.0, 1.6 }
Pointer.SHOW_MODES = { "siempre", "mover" }
-- segundos por vuelta de animacion (16 cuadros) a velocidad normal
Pointer.PERIOD = { anillo = 1.6, halo = 2.4, esferas = 2.2, fuego = 1.1, runas = 6.0, mira = 4.0, estela = 1.0 }

local DEFAULTS = {
    enabled = false, style = "anillo", color = "dorado", size = "m",
    opacity = 0.9, speed = 1.0, show = "siempre", shake = true,
}
Pointer.DEFAULTS = DEFAULTS

local function _in(list, value)
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

-- valores seguros (lo guardado puede venir de una version vieja o a mano)
function Pointer.normalize(raw)
    raw = type(raw) == "table" and raw or {}
    local out = {}
    out.enabled = raw.enabled == true
    out.style = _in(Pointer.STYLES, raw.style) and raw.style or DEFAULTS.style
    out.color = _in(Pointer.COLORS, raw.color) and raw.color or DEFAULTS.color
    out.size = Pointer.SIZES[raw.size] ~= nil and raw.size or DEFAULTS.size
    local op = tonumber(raw.opacity) or DEFAULTS.opacity
    if op < 0.2 then op = 0.2 end
    if op > 1 then op = 1 end
    out.opacity = op
    local sp = tonumber(raw.speed) or DEFAULTS.speed
    if sp < 0.25 then sp = 0.25 end
    if sp > 3 then sp = 3 end
    out.speed = sp
    out.show = _in(Pointer.SHOW_MODES, raw.show) and raw.show or DEFAULTS.show
    out.shake = raw.shake ~= false
    return out
end

function Pointer.sheet_path(style, color, size)
    return ASSET_DIR .. "ptr_" .. style .. "_" .. color .. "_" .. size .. ".tga"
end

local function _settings()
    local s = State.settings ~= nil and State.settings.pointer or nil
    if type(s) ~= "table" then
        return Pointer.normalize(nil)
    end
    return s
end

local function _mouse()
    local ok, x, y = pcall(Turbine.UI.Display.GetMousePosition)
    if ok ~= true or type(x) ~= "number" or type(y) ~= "number" then
        return nil, nil
    end
    return x, y
end

local function _now()
    return Turbine.Engine.GetGameTime()
end

-- ---------------------------------------------------------------------
-- Sprite: una ventana del tamano de UN cuadro que recorta la hoja 4x4
-- ---------------------------------------------------------------------

local PointerSprite = class(UI.Widgets.LuiBaseWindow)
Pointer.PointerSprite = PointerSprite

function PointerSprite:Constructor(cell, image)
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })
    UI.NativeScaling.disable(self)
    self.cell = cell
    self.frame = -1
    self.opacity = -1
    self.x, self.y = nil, nil
    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetSize(cell, cell)
    self:SetZOrder(TOP_Z)
    self.sheet = Turbine.UI.Control()
    self.sheet:SetParent(self)
    self.sheet:SetMouseVisible(false)
    self.sheet:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.sheet:SetSize(cell * GRID, cell * GRID)
    self.sheet:SetPosition(0, 0)
    self.ok = pcall(Turbine.UI.Control.SetBackground, self.sheet, image)
end

function PointerSprite:set_frame(i)
    i = math.floor(i) % FRAMES
    if i == self.frame then
        return
    end
    self.frame = i
    local cx = i % GRID
    local cy = math.floor(i / GRID)
    self.sheet:SetPosition(-cx * self.cell, -cy * self.cell)
end

-- centro del cuadro en (x, y) de la pantalla
function PointerSprite:place(x, y)
    local px = math.floor(x - self.cell / 2 + 0.5)
    local py = math.floor(y - self.cell / 2 + 0.5)
    if px == self.x and py == self.y then
        return
    end
    self.x, self.y = px, py
    self:SetPosition(px, py)
end

function PointerSprite:set_alpha(a)
    if a < 0 then a = 0 end
    if a > 1 then a = 1 end
    a = math.floor(a * 50 + 0.5) / 50
    if a == self.opacity then
        return
    end
    self.opacity = a
    self:SetOpacity(a)
    local show = a > 0 and self.ok == true
    if show ~= (self:IsVisible() == true) then
        self:SetVisible(show)
    end
end

function PointerSprite:destroy()
    self:SetWantsUpdates(false)
    self:unregister_hideable()
    self:SetVisible(false)
    self.sheet:SetParent(nil)
end

-- ---------------------------------------------------------------------
-- Efecto completo (cabeza + estela + destello de "agitar")
-- ---------------------------------------------------------------------

local PointerFx = class()
Pointer.PointerFx = PointerFx

function PointerFx:Constructor(cfg)
    self.cfg = cfg
    local cell = Pointer.SIZES[cfg.size]
    self.cell = cell
    self.head = PointerSprite(cell, Pointer.sheet_path(cfg.style, cfg.color, cfg.size))
    self.trail = {}
    if cfg.style == "estela" then
        for i = 1, TRAIL_N do
            local sp = PointerSprite(cell, Pointer.sheet_path("estela", cfg.color, cfg.size))
            sp:set_frame(math.min(FRAMES - 1, i + math.floor(i / 2)))
            sp:SetZOrder(TOP_Z - i)
            self.trail[i] = sp
        end
        self.head:set_frame(0)
    end
    self.burst = nil
    if cfg.shake == true then
        self.burst = PointerSprite(Pointer.SIZES.l, Pointer.sheet_path("anillo", cfg.color, "l"))
        self.burst:SetZOrder(TOP_Z - TRAIL_N - 1)
    end
    self.t0 = _now()
    self.mx, self.my = nil, nil
    self.last_move = self.t0
    self.hist = {}
    self.last_sample = 0
    self.shake = { t = {}, x = {}, dir = 0, path = {}, burst_at = -100 }
    -- el "reloj" del efecto: un control invisible con Update
    self.ticker = Turbine.UI.Control()
    self.ticker:SetVisible(false)
    local this = self
    self.ticker.Update = function()
        local ok, err = pcall(this.tick, this)
        if ok ~= true then
            this.errors = (this.errors or 0) + 1
            if this.errors <= 2 then
                Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> puntero: " .. tostring(err))
            end
            if this.errors >= 20 then
                this.ticker:SetWantsUpdates(false)
            end
        end
    end
    self.ticker:SetWantsUpdates(true)
end

-- vaivenes rapidos de izquierda a derecha -> destello grande
function PointerFx:_track_shake(now, x, dx)
    local s = self.shake
    if math.abs(dx) >= SHAKE_MIN_STEP then
        local dir = dx > 0 and 1 or -1
        if s.dir ~= 0 and dir ~= s.dir then
            s.t[#s.t + 1] = now
        end
        s.dir = dir
        s.path[#s.path + 1] = { now, math.abs(dx) }
    end
    while #s.t > 0 and now - s.t[1] > SHAKE_WINDOW do
        table.remove(s.t, 1)
    end
    while #s.path > 0 and now - s.path[1][1] > SHAKE_WINDOW do
        table.remove(s.path, 1)
    end
    if #s.t >= SHAKE_TURNS and now - s.burst_at > BURST_COOLDOWN then
        local total = 0
        for i = 1, #s.path do
            total = total + s.path[i][2]
        end
        if total >= SHAKE_MIN_PATH then
            s.burst_at = now
            s.t = {}
            return true
        end
    end
    return false
end

function PointerFx:tick()
    local cfg = self.cfg
    local now = _now()
    local x, y = _mouse()
    if x ~= nil then
        if self.mx == nil then
            self.mx, self.my = x, y
            self.last_move = now
        elseif x ~= self.mx or y ~= self.my then
            if cfg.shake == true then
                self:_track_shake(now, x, x - self.mx)
            end
            self.mx, self.my = x, y
            self.last_move = now
        end
    end
    if self.mx == nil then
        return
    end

    -- visibilidad ("solo al mover": se va despacio tras FADE_DELAY quieto)
    local alpha = cfg.opacity
    local burst_age = now - self.shake.burst_at
    if cfg.show == "mover" then
        local idle = now - self.last_move
        if idle > FADE_DELAY then
            alpha = alpha * math.max(0, 1 - (idle - FADE_DELAY) / FADE_TIME)
        end
        if burst_age < BURST_TIME then
            alpha = cfg.opacity
        end
    end

    -- cabeza
    local head = self.head
    head:place(self.mx, self.my)
    if cfg.style ~= "estela" then
        local period = (Pointer.PERIOD[cfg.style] or 2) / cfg.speed
        head:set_frame(((now - self.t0) / period) * FRAMES)
    end
    head:set_alpha(alpha)

    -- estela: posiciones de hace un momento
    if #self.trail > 0 then
        if now - self.last_sample >= TRAIL_DT then
            self.last_sample = now
            table.insert(self.hist, 1, { self.mx, self.my })
            while #self.hist > TRAIL_N * 2 + 1 do
                table.remove(self.hist)
            end
        end
        for i = 1, #self.trail do
            local sp = self.trail[i]
            local p = self.hist[i * 2]
            if p == nil or (math.abs(p[1] - self.mx) < 3 and math.abs(p[2] - self.my) < 3) then
                sp:set_alpha(0)
            else
                sp:place(p[1], p[2])
                sp:set_alpha(alpha)
            end
        end
    end

    -- destello de "agitar para encontrar"
    local burst = self.burst
    if burst ~= nil then
        if burst_age < BURST_TIME then
            burst:place(self.mx, self.my)
            burst:set_frame((burst_age / 0.6) * FRAMES)
            burst:set_alpha(math.max(0, 1 - burst_age / BURST_TIME))
        elseif burst.opacity ~= 0 then
            burst:set_alpha(0)
        end
    end
end

-- para "/lui puntero prueba": como si se hubiera agitado el raton
function PointerFx:flash()
    self.shake.burst_at = _now()
end

function PointerFx:destroy()
    self.ticker:SetWantsUpdates(false)
    self.ticker.Update = nil
    self.head:destroy()
    for i = 1, #self.trail do
        self.trail[i]:destroy()
    end
    self.trail = {}
    if self.burst ~= nil then
        self.burst:destroy()
        self.burst = nil
    end
end

-- ---------------------------------------------------------------------
-- Opciones
-- ---------------------------------------------------------------------

-- crea / quita / rehace el efecto segun Opciones (se llama al cargar LUI y
-- al guardar la configuracion)
function Apply.pointer_settings()
    if Windows.pointer_fx ~= nil then
        pcall(Windows.pointer_fx.destroy, Windows.pointer_fx)
        Windows.pointer_fx = nil
    end
    local cfg = Pointer.normalize(_settings())
    if cfg.enabled ~= true then
        return
    end
    local ok, fx = pcall(PointerFx, cfg)
    if ok == true then
        Windows.pointer_fx = fx
    else
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> puntero: " .. tostring(fx))
    end
end

function Pointer.flash()
    if Windows.pointer_fx ~= nil then
        Windows.pointer_fx:flash()
        return true
    end
    return false
end

function Pointer.shutdown()
    if Windows.pointer_fx ~= nil then
        pcall(Windows.pointer_fx.destroy, Windows.pointer_fx)
        Windows.pointer_fx = nil
    end
end
