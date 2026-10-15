-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Widgets de la barra traidos de TitanBar 1.24.45 (Habna y colaboradores;
-- ver ATTRIBUTIONS.md): ubicacion, reputacion, infamia/renombre, dia/noche,
-- hora del servidor, baul personal y almacen compartido. Cada uno se pone o
-- se quita de la barra como los demas (%location%, %reputation%, ...).
--
-- Un solo "servicio" compartido escucha el chat y lee/guarda los datos; solo
-- esta activo mientras haya algun widget de estos en la barra.

import "LUI.src.Utils.callbacks"

local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local class = _G.LUI.Core.class
local S = _G.LUI.Features.StatusBar.Common
local WidgetBase = _G.LUI.Features.StatusBar.WidgetBase
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local TR = _G.LUI.Locale.TR

local ICON_DIR = "LUI/assets/ui/titan/"
local ICONS = {
    sun = ICON_DIR .. "sun.tga",
    dusk = ICON_DIR .. "dusk.tga",
    moon = ICON_DIR .. "moon.tga",
    compass = ICON_DIR .. "compass.tga",
    banner = ICON_DIR .. "banner.tga",
    swords = ICON_DIR .. "swords.tga",
    server_clock = ICON_DIR .. "server_clock.tga",
    vault = ICON_DIR .. "vault.tga",
    shared = ICON_DIR .. "shared.tga",
    hero = ICON_DIR .. "hero.tga",
    equip = ICON_DIR .. "equip.tga",
    lp = ICON_DIR .. "lotro_points.tga",
    -- iconos originales del juego (los mismos que usa TitanBar)
    game_sun = 0x4101f898,
    game_moon = 0x4101f89a,
}

-- clases de Monster Play sin icono en LUI (ids de TitanBar)
local CREEP_CLASS_ICONS = {
    [52] = 0x41007dde, [71] = 0x41007ddd, [126] = 0x41007de1, [127] = 0x41007de0, [179] = 0x41007ddf,
}
StatusBarWidgets.TitanIcons = ICONS

local function C(r, g, b)
    return Turbine.UI.Color(r / 255, g / 255, b / 255)
end

local COLORS = {
    day = C(255, 214, 110),
    dusk = C(255, 165, 105),
    night = C(170, 195, 255),
    gain = C(130, 225, 130),
    loss = C(240, 95, 85),
    freep = C(120, 175, 255),
    creep = C(240, 100, 95),
    yellow = C(235, 222, 5),
    orange = C(242, 153, 0),
    red = C(231, 29, 0),
}

---------------------------------------------------------------------
-- Servicio compartido
---------------------------------------------------------------------

local D = {
    users = 0,
    chat = nil,
    next_tick = 0,
    load_at = nil,
    rep_last = nil,
    rep_amount = 0,
    rep_session = {},
    pvp_points = nil,
    pvp_reload_at = nil,
    pvp_next_reload = 0,
    vault_used = nil,
    vault_cap = nil,
    shared_used = nil,
    shared_cap = nil,
    -- cuantos widgets usan cada dato: solo se lee lo que esta en la barra
    pvp_users = 0,
    vault_users = 0,
    shared_users = 0,
    -- puntos LOTRO: total (si lo pusiste en Opciones) y ganados en la sesion
    lp = nil,
    lp_loaded = false,
    lp_pending = 0,
    lp_session = 0,
    -- ventanita de detalles (al pasar el raton o hacer clic)
    tip = nil,
    tip_owner = nil,
}
StatusBarWidgets.TitanData = D

local REP_KEY = "LUI_TitanRep"
local VAULT_KEY = "LUI_TitanVault"
local SHARED_KEY = "LUI_TitanShared"
local LP_KEY = "LUI_TitanLP"

local function _num(text)
    local digits = string.gsub(tostring(text or ""), "[^%d]", "")
    return tonumber(digits)
end

local function _save(scope, key, value)
    pcall(Turbine.PluginData.Save, scope, key, value)
end

-- "Your reputation with X has increased by 1,300." (en / de / fr)
local REP_PATTERNS = {
    { "reputation with (.-) has increased by ([%d,%.]+)", 1 },
    { "reputation with (.-) has decreased by ([%d,%.]+)", -1 },
    { "Euer Ruf bei der Gruppe \"(.-)\" wurde um ([%d,%.]+) erh", 1 },
    { "Euer Ruf bei (.-) hat sich um ([%d,%.]+) verbessert", 1 },
    { "Euer Ruf bei (.-) hat sich um ([%d,%.]+) verschlechtert", -1 },
    { "de la faction (.-) a augment\195\169 de ([%d,%.]+)", 1 },
    { "de la faction (.-) a diminu\195\169 de ([%d,%.]+)", -1 },
}

-- "You've earned 10 LOTRO Points" (en / fr / de; tambien el nombre viejo "Turbine Points")
local LP_PATTERNS = {
    "earned ([%d,%.]+) LOTRO Points",
    "earned ([%d,%.]+) Turbine Points",
    "gagn\195\169 ([%d,%.]+) points LOTRO",
    "gagn\195\169 ([%d,%.]+) points Turbine",
    "habt ([%d,%.]+) LOTRO%-Punkte",
    "habt ([%d,%.]+) Punkte erhalten",
}

local function _save_lp()
    if D.lp ~= nil then
        _save(Turbine.DataScope.Account, LP_KEY, { points = tostring(D.lp) })
    end
end

function D.add_lp(n)
    D.lp_session = D.lp_session + n
    if D.lp_loaded == true then
        if D.lp ~= nil then
            D.lp = D.lp + n
            _save_lp()
        end
    else
        D.lp_pending = D.lp_pending + n
    end
end

-- desde Opciones: el total que muestra el juego (tienda); despues suma solo
function D.set_lp(n)
    n = tonumber(n)
    if n == nil or n < 0 then
        return
    end
    D.lp = math.floor(n)
    D.lp_loaded = true
    D.lp_pending = 0
    _save_lp()
end

local PVP_WORDS = { "infamy points", "renown points", "Verrufenheit", "Ruhm", "infamie", "renomm\195\169e" }

local function _on_chat(_, args)
    if args == nil or type(args.Message) ~= "string" then
        return
    end
    local msg = args.Message
    if string.find(msg, "eputation", 1, true) ~= nil or string.find(msg, "Ruf bei", 1, true) ~= nil or
        string.find(msg, "faction", 1, true) ~= nil then
        for i = 1, #REP_PATTERNS do
            local name, amount = string.match(msg, REP_PATTERNS[i][1])
            if name ~= nil and amount ~= nil then
                local n = _num(amount)
                if n ~= nil then
                    n = n * REP_PATTERNS[i][2]
                    name = string.gsub(name, "<[^>]*>", "")
                    D.rep_last = name
                    D.rep_amount = n
                    D.rep_session[name] = (D.rep_session[name] or 0) + n
                    _save(Turbine.DataScope.Character, REP_KEY, { name = name, amount = tostring(n) })
                end
                break
            end
        end
    end
    if string.find(msg, "oints", 1, true) ~= nil or string.find(msg, "Punkte", 1, true) ~= nil then
        local adv = Turbine.ChatType ~= nil and Turbine.ChatType.Advancement or nil
        if adv == nil or args.ChatType == adv then
            for i = 1, #LP_PATTERNS do
                local amount = string.match(msg, LP_PATTERNS[i])
                if amount ~= nil then
                    local n = _num(amount)
                    if n ~= nil and n > 0 and n < 100000 then
                        D.add_lp(n)
                    end
                    break
                end
            end
        end
    end
    for i = 1, #PVP_WORDS do
        if string.find(msg, PVP_WORDS[i], 1, true) ~= nil then
            -- PvMP+ guarda sus datos al ganar puntos: se relee un poco despues
            D.pvp_reload_at = Turbine.Engine.GetGameTime() + 3
            break
        end
    end
end

local function _load_pvp()
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Character, "PvMP_Plus", function(data)
        if type(data) == "table" and type(data.numbers) == "table" then
            local pts = tonumber(data.numbers.points_total)
            if pts ~= nil then
                D.pvp_points = pts
            end
        end
    end)
end

local function _load_saved()
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Character, REP_KEY, function(data)
        if type(data) == "table" and type(data.name) == "string" and D.rep_last == nil then
            D.rep_last = data.name
            D.rep_amount = tonumber(data.amount) or 0
        end
    end)
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Character, VAULT_KEY, function(data)
        if type(data) == "table" and D.vault_cap == nil then
            D.vault_used, D.vault_cap = tonumber(data.used), tonumber(data.cap)
        end
    end)
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Server, SHARED_KEY, function(data)
        if type(data) == "table" and D.shared_cap == nil then
            D.shared_used, D.shared_cap = tonumber(data.used), tonumber(data.cap)
        end
    end)
    pcall(Turbine.PluginData.Load, Turbine.DataScope.Account, LP_KEY, function(data)
        if D.lp_loaded == true then
            return
        end
        D.lp_loaded = true
        local saved = type(data) == "table" and tonumber(data.points) or nil
        if saved ~= nil then
            D.lp = saved + D.lp_pending
            if D.lp_pending > 0 then
                _save_lp()
            end
        end
        D.lp_pending = 0
    end)
    if D.pvp_users > 0 then
        _load_pvp()
    end
end

-- baul / almacen: solo se pueden leer mientras estan abiertos (disponibles)
local function _read_storage(getter, used_key, cap_key, scope, save_key)
    local ok, used, cap = pcall(function()
        local player = Turbine.Gameplay.LocalPlayer.GetInstance()
        if player == nil or player[getter] == nil then
            return nil, nil
        end
        local store = player[getter](player)
        if store == nil or store.IsAvailable == nil or store:IsAvailable() ~= true then
            return nil, nil
        end
        return store:GetCount(), store:GetCapacity()
    end)
    used, cap = tonumber(used), tonumber(cap)
    if ok ~= true or used == nil or cap == nil or cap <= 0 then
        return
    end
    if used ~= D[used_key] or cap ~= D[cap_key] then
        D[used_key], D[cap_key] = used, cap
        _save(scope, save_key, { used = tostring(used), cap = tostring(cap) })
    end
end

function D.tick(now)
    if now < D.next_tick then
        return
    end
    D.next_tick = now + 1
    if D.load_at ~= nil and now >= D.load_at then
        D.load_at = nil
        _load_saved()
        D.pvp_next_reload = now + 600
    end
    if D.pvp_users > 0 and ((D.pvp_reload_at ~= nil and now >= D.pvp_reload_at) or (D.load_at == nil and now >= D.pvp_next_reload)) then
        D.pvp_reload_at = nil
        D.pvp_next_reload = now + 600   -- respaldo; lo normal es releer al ganar puntos
        _load_pvp()
    end
    if D.vault_users > 0 then
        _read_storage("GetVault", "vault_used", "vault_cap", Turbine.DataScope.Character, VAULT_KEY)
    end
    if D.shared_users > 0 then
        _read_storage("GetSharedStorage", "shared_used", "shared_cap", Turbine.DataScope.Server, SHARED_KEY)
    end
end

function D.acquire()
    D.users = D.users + 1
    if D.chat == nil then
        D.chat = add_callback(Turbine.Chat, "Received", function(sender, args)
            pcall(_on_chat, sender, args)
        end)
    end
    if D.loaded ~= true then
        D.loaded = true
        -- como el cartel de zona: los datos guardados se leen unos segundos despues
        D.load_at = Turbine.Engine.GetGameTime() + 6
    end
end

function D.release()
    D.users = math.max(0, D.users - 1)
    if D.users == 0 and D.chat ~= nil then
        remove_callback(Turbine.Chat, "Received", D.chat)
        D.chat = nil
    end
end

---------------------------------------------------------------------
-- Ayudas comunes
---------------------------------------------------------------------

local function _fmt(n)
    local s = tostring(math.floor(math.abs(n) + 0.5))
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    out = string.gsub(out, "^%.", "")
    return out
end

-- ventanita de detalles: una sola para todos, se crea la primera vez
local function _tip()
    if D.tip == nil then
        local ok, tip = pcall(function()
            local t = _G.LUI.UI.Widgets.LuiTooltip()
            t:SetZOrder(2200)
            return t
        end)
        if ok == true then
            D.tip = tip
        end
    end
    return D.tip
end

local function _show_tip(self)
    if self._tips_on == false or self.tooltip_text == nil then
        return
    end
    local ok, text = pcall(self.tooltip_text, self)
    if ok ~= true or type(text) ~= "string" or text == "" then
        return
    end
    local tip = _tip()
    if tip ~= nil then
        D.tip_owner = self
        pcall(tip.ShowFor, tip, self, text)
    end
end

local function _hide_tip(self)
    if D.tip ~= nil and (self == nil or D.tip_owner == self) then
        D.tip_owner = nil
        pcall(D.tip.Hide, D.tip)
    end
end

local function _init(self, key, widget_w, bar_h, font, content_alignment, icon_path, default_alignment)
    WidgetBase.Constructor(self, key, widget_w, bar_h, font, content_alignment or default_alignment, icon_path)
    self._has_icon = icon_path ~= nil
    self._icon_now = icon_path
    self._base_color = font ~= nil and font.color or nil
    self._color_key = "base"
    self._next = 0
    self._tips_on = true
    -- la barra encadena estos eventos (clic derecho = menu, resaltado)
    self.MouseEnter = function()
        _show_tip(self)
    end
    self.MouseLeave = function()
        _hide_tip(self)
    end
    self.MouseClick = function(_, args)
        if args == nil or args.Button == Turbine.UI.MouseButton.Left then
            _show_tip(self)
        end
    end
    D.acquire()
end

-- modo edicion de la barra: sin ventanita
local function _set_interaction(self, enabled)
    self._tips_on = enabled == true
    if self._tips_on ~= true then
        _hide_tip(self)
    end
end

local function _set_color(self, key, color)
    if self._color_key == key then
        return
    end
    self._color_key = key
    local c = color or self._base_color
    if c ~= nil then
        self.label:SetForeColor(c)
    end
end

local function _set_icon(self, icon)
    if self._has_icon ~= true or icon == nil or icon == self._icon_now then
        return
    end
    self._icon_now = icon
    local h = self:GetHeight()
    local icon_h = S.get_icon_size(h)
    local icon_w = S.get_widget_icon_w(self.widget_key, icon_h)
    pcall(self.icon.set_icon, self.icon, icon, icon_w, icon_h)
end

local function _throttle(self, now, every)
    D.tick(now)
    if now < self._next then
        return false
    end
    self._next = now + (every or 1)
    if D.tip_owner == self then
        _show_tip(self)   -- la ventanita abierta se actualiza sola
    end
    return true
end

local function _destroy(self)
    _hide_tip(self)
    D.release()
    WidgetBase.destroy(self)
end

---------------------------------------------------------------------
-- Ubicacion (zona del canal Regional, la misma que usa el cartel de zona)
---------------------------------------------------------------------

local LocationWidget = class(WidgetBase)
StatusBarWidgets.TitanLocationWidget = LocationWidget

function LocationWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "location", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleLeft)
    self:set_text("--")
end

function LocationWidget:update(now)
    if not _throttle(self, now, 1) then
        return
    end
    local zb = _G.LUI.Features ~= nil and _G.LUI.Features.ZoneBanner or nil
    local zone = zb ~= nil and zb.current_zone or nil
    if type(zone) ~= "string" or zone == "" then
        self:set_text("--")
        _set_color(self, "base", nil)
        return
    end
    self:set_text(zone)
    if zone ~= self._zone then
        self._zone = zone
        local color = nil
        local ok, style = pcall(zb.style_for, zone)
        local def = ok and zb.STYLES ~= nil and zb.STYLES[style] or nil
        if def ~= nil and type(def.text) == "table" then
            color = C(def.text[1], def.text[2], def.text[3])
        end
        self._color_key = nil
        _set_color(self, "zone:" .. tostring(style), color)
    end
end

LocationWidget.destroy = _destroy

---------------------------------------------------------------------
-- Reputacion (ultima faccion que cambio + total de la sesion)
---------------------------------------------------------------------

local ReputationWidget = class(WidgetBase)
StatusBarWidgets.TitanReputationWidget = ReputationWidget

function ReputationWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "reputation", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleLeft)
    self:set_text("--")
end

function ReputationWidget:update(now)
    if not _throttle(self, now, 1) then
        return
    end
    local name = D.rep_last
    if name == nil then
        self:set_text(TR["No reputation yet"])
        _set_color(self, "base", nil)
        return
    end
    local n = D.rep_amount or 0
    local text = name .. " " .. (n < 0 and "-" or "+") .. _fmt(n)
    local session = D.rep_session[name]
    if session ~= nil and session ~= n then
        text = text .. "  (" .. (session < 0 and "-" or "+") .. _fmt(session) .. ")"
    end
    self:set_text(text)
    if n < 0 then
        _set_color(self, "loss", COLORS.loss)
    else
        _set_color(self, "gain", COLORS.gain)
    end
end

ReputationWidget.destroy = _destroy

---------------------------------------------------------------------
-- Infamia / Renombre (lee los datos que guarda PvMP+)
---------------------------------------------------------------------

local RANKS = { [0] = 0, 500, 1250, 2750, 5750, 14750, 33500, 71000, 146000, 258500, 408500, 633500,
    1008500, 1608500, 2508500, 3708500 }
local FREEP_ICONS = { 0x410080a8, 0x410080a9, 0x410080aa, 0x410080ab, 0x410080ac, 0x410080ad, 0x410080ae,
    0x410080af, 0x410080a1, 0x410080a2, 0x410080a3, 0x410080a4, 0x410080a5, 0x410080a6, 0x410080a7 }
local CREEP_ICONS = { 0x410080b7, 0x410080b8, 0x410080b9, 0x410080ba, 0x410080bb, 0x410080bc, 0x410080bd,
    0x410080be, 0x410080b0, 0x410080b1, 0x410080b2, 0x410080b3, 0x410080b4, 0x410080b5, 0x410080b6 }

local function _rank_of(points)
    local top = #RANKS
    if points >= RANKS[top] then
        return top, 1
    end
    for r = 0, top - 1 do
        if points >= RANKS[r] and points < RANKS[r + 1] then
            return r, (points - RANKS[r]) / (RANKS[r + 1] - RANKS[r])
        end
    end
    return 0, 0
end
StatusBarWidgets.TitanRankOf = _rank_of

local PvpRankWidget = class(WidgetBase)
StatusBarWidgets.TitanPvpRankWidget = PvpRankWidget

function PvpRankWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "pvp_rank", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleLeft)
    local ok, creep = pcall(function()
        return Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer
    end)
    self._creep = ok and creep == true
    D.pvp_users = D.pvp_users + 1
    if D.pvp_points == nil and D.load_at == nil then
        D.pvp_reload_at = Turbine.Engine.GetGameTime()   -- puesto despues de entrar: leer ya
    end
    self:set_text("--")
end

function PvpRankWidget:update(now)
    if not _throttle(self, now, 1) then
        return
    end
    local pts = D.pvp_points
    if pts == nil then
        self:set_text(TR["Rank"] .. " --")
        _set_color(self, "base", nil)
        _set_icon(self, ICONS.swords)
        return
    end
    local rank, pct = _rank_of(pts)
    if rank >= #RANKS then
        self:set_text(TR["Rank"] .. " " .. rank .. " \194\183 MAX")
    else
        self:set_text(string.format("%s %d \194\183 %.1f%%", TR["Rank"], rank, pct * 100))
    end
    _set_color(self, self._creep and "creep" or "freep", self._creep and COLORS.creep or COLORS.freep)
    local icons = self._creep and CREEP_ICONS or FREEP_ICONS
    _set_icon(self, rank >= 1 and icons[rank] or ICONS.swords)
end

function PvpRankWidget:destroy()
    D.pvp_users = math.max(0, D.pvp_users - 1)
    _destroy(self)
end

---------------------------------------------------------------------
-- Dia y noche de la Tierra Media (formula de TitanBar / PredictInGameTime)
---------------------------------------------------------------------

local DAY_CYCLE = 11160
local PHASES = {
    { "Dawn", 572, "dusk" }, { "Morning", 2294, "day" }, { "Noon", 3361, "day" },
    { "Afternoon", 5039, "day" }, { "Dusk", 6140, "dusk" }, { "Gloaming", 6710, "dusk" },
    { "Evening", 8389, "night" }, { "Midnight", 8928, "night" }, { "Late Watches", 10069, "night" },
    { "Foredawn", 11160, "night" },
}

local function _phase(seed)
    local t = (Turbine.Engine.GetGameTime() - (seed or 10350)) % DAY_CYCLE
    for i = 1, #PHASES do
        if t <= PHASES[i][2] then
            local nxt = PHASES[i % #PHASES + 1]
            return PHASES[i][1], PHASES[i][3], math.floor(PHASES[i][2] - t), nxt[1]
        end
    end
    return PHASES[1][1], PHASES[1][3], 0, PHASES[2][1]
end
StatusBarWidgets.TitanDayPhase = _phase

local DayNightWidget = class(WidgetBase)
StatusBarWidgets.TitanDayNightWidget = DayNightWidget

function DayNightWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "daynight", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleLeft)
    self._seed = cfg ~= nil and tonumber(cfg.seed) or 10350
    self._show_next = not (cfg ~= nil and cfg.show_next == false)
end

function DayNightWidget:update(now)
    if not _throttle(self, now, 1) then
        return
    end
    local name, kind, left = _phase(self._seed)
    local text = TR[name]
    if self._show_next then
        if left >= 60 then
            text = text .. " \194\183 " .. math.floor(left / 60) .. " min"
        else
            text = text .. " \194\183 " .. left .. " s"
        end
    end
    self:set_text(text)
    _set_color(self, kind, COLORS[kind == "day" and "day" or (kind == "dusk" and "dusk" or "night")])
    _set_icon(self, (kind == "day" or name == "Dawn") and ICONS.game_sun or ICONS.game_moon)
end

DayNightWidget.destroy = _destroy

---------------------------------------------------------------------
-- Hora del servidor (hora local + diferencia en horas que elijas)
---------------------------------------------------------------------

local ServerTimeWidget = class(WidgetBase)
StatusBarWidgets.TitanServerTimeWidget = ServerTimeWidget

function ServerTimeWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "time_server", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleCenter)
    self._offset = cfg ~= nil and tonumber(cfg.offset) or 0
    self._format = cfg ~= nil and cfg.time_format or nil
end

function ServerTimeWidget:update(now)
    if not _throttle(self, now, 1) then
        return
    end
    local d = Turbine.Engine.GetDate()
    local total = (d.Hour or 0) * 60 + (d.Minute or 0) + math.floor(self._offset * 60 + 0.5)
    total = total % 1440
    self:set_text(S.format_hhmm({ Hour = math.floor(total / 60), Minute = total % 60 }, self._format))
end

ServerTimeWidget.destroy = _destroy

---------------------------------------------------------------------
-- Baul personal y almacen compartido (usado/total, se guarda)
---------------------------------------------------------------------

local function _storage_update(self, used, cap)
    if used == nil or cap == nil or cap <= 0 then
        self:set_text("--/--")
        _set_color(self, "base", nil)
        return
    end
    self:set_text(string.format("%d/%d", used, cap))
    local free = (cap - used) / cap
    if free <= 0.10 then
        _set_color(self, "red", COLORS.red)
    elseif free <= 0.20 then
        _set_color(self, "orange", COLORS.orange)
    elseif free <= 0.30 then
        _set_color(self, "yellow", COLORS.yellow)
    else
        _set_color(self, "base", nil)
    end
end

local VaultWidget = class(WidgetBase)
StatusBarWidgets.TitanVaultWidget = VaultWidget

function VaultWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "vault", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleRight)
    D.vault_users = D.vault_users + 1
    self:set_text("--/--")
end

function VaultWidget:update(now)
    if _throttle(self, now, 1) then
        _storage_update(self, D.vault_used, D.vault_cap)
    end
end

function VaultWidget:destroy()
    D.vault_users = math.max(0, D.vault_users - 1)
    _destroy(self)
end

local SharedStorageWidget = class(WidgetBase)
StatusBarWidgets.TitanSharedStorageWidget = SharedStorageWidget

function SharedStorageWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "shared_storage", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleRight)
    D.shared_users = D.shared_users + 1
    self:set_text("--/--")
end

function SharedStorageWidget:update(now)
    if _throttle(self, now, 1) then
        _storage_update(self, D.shared_used, D.shared_cap)
    end
end

function SharedStorageWidget:destroy()
    D.shared_users = math.max(0, D.shared_users - 1)
    _destroy(self)
end

---------------------------------------------------------------------
-- (2026-10-15) Info del personaje, puntuacion del equipo y puntos LOTRO
---------------------------------------------------------------------

local NICE_NAMES = {
    LoreMaster = "Lore-master", RuneKeeper = "Rune-keeper", HighElf = "High Elf",
    StoutAxe = "Stout-axe Dwarf", RiverHobbit = "River Hobbit", WarLeader = "Warleader",
    BlackArrow = "Black Arrow", WeaverSpider = "Weaver", StalkerSpider = "Stalker",
}

-- nombre de un valor de un enum del juego (Turbine.Gameplay.Class.Guardian -> "Guardian")
local function _enum_name(enum, value)
    if type(enum) ~= "table" or value == nil then
        return nil
    end
    local found = nil
    pcall(function()
        for k, v in pairs(enum) do
            if v == value and type(k) == "string" then
                found = k
                break
            end
        end
    end)
    if found == nil then
        return nil
    end
    return TR[NICE_NAMES[found] or found]
end

local function _player()
    local ok, player = pcall(Turbine.Gameplay.LocalPlayer.GetInstance)
    if ok == true then
        return player
    end
    return nil
end

local function _call(obj, method)
    if obj == nil or obj[method] == nil then
        return nil
    end
    local ok, v = pcall(obj[method], obj)
    if ok == true then
        return v
    end
    return nil
end

-- Info del personaje: nivel y clase (detalles: nombre, raza)
local CharInfoWidget = class(WidgetBase)
StatusBarWidgets.TitanCharInfoWidget = CharInfoWidget

function CharInfoWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "char_info", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleLeft)
    self:set_text("--")
end

function CharInfoWidget:_read()
    local p = _player()
    local gp = Turbine.Gameplay
    local cls = _call(p, "GetClass")
    return {
        name = _call(p, "GetName"),
        level = tonumber(_call(p, "GetLevel")),
        class = _enum_name(gp.Class, cls),
        class_id = cls,
        race = _enum_name(gp.Race, _call(p, "GetRace")),
    }
end

-- icono original de la clase (el mismo de los marcos de grupo de LUI)
local function _class_icon(cls)
    if cls == nil then
        return nil
    end
    local utils = _G.LUI.Utils
    if utils ~= nil and utils.get_class_icon ~= nil then
        local ok, icon = pcall(utils.get_class_icon, cls)
        if ok == true and icon ~= nil then
            return icon
        end
    end
    return CREEP_CLASS_ICONS[cls]
end

function CharInfoWidget:update(now)
    if not _throttle(self, now, 5) then
        return
    end
    local i = self:_read()
    if i.level == nil then
        self:set_text("--")
        return
    end
    if self._class_icon_for ~= i.class_id then
        self._class_icon_for = i.class_id
        local icon = _class_icon(i.class_id)
        if icon ~= nil then
            _set_icon(self, icon)
        end
    end
    local text = TR["Lv."] .. " " .. i.level
    if i.class ~= nil then
        text = text .. " \194\183 " .. i.class
    end
    self:set_text(text)
end

function CharInfoWidget:tooltip_text()
    local i = self:_read()
    local lines = { i.name or TR["Character"] }
    if i.level ~= nil then
        lines[#lines + 1] = TR["Level"] .. ": " .. i.level
    end
    if i.race ~= nil then
        lines[#lines + 1] = TR["Race"] .. ": " .. i.race
    end
    if i.class ~= nil then
        lines[#lines + 1] = TR["Class"] .. ": " .. i.class
    end
    return table.concat(lines, "\n")
end

CharInfoWidget.destroy = _destroy

-- Puntuacion del equipo (como TitanBar: calidad + durabilidad de cada pieza)
local QUALITY_POINTS = { Legendary = 250, Incomparable = 200, Rare = 150, Uncommon = 100, Common = 50 }
local QUALITY_ORDER = { "Legendary", "Incomparable", "Rare", "Uncommon", "Common" }
local DURABILITY_POINTS = { Indestructible = 60, Tough = 40, Normal = 30, Substantial = 25, Brittle = 15,
    Flimsy = 10, Weak = 5 }

local function _enum_key(enum, value)
    if type(enum) ~= "table" or value == nil then
        return nil
    end
    local found = nil
    pcall(function()
        for k, v in pairs(enum) do
            if v == value and type(k) == "string" then
                found = k
                break
            end
        end
    end)
    return found
end

local function _equip_score()
    local p = _player()
    local eq = _call(p, "GetEquipment")
    if eq == nil or eq.GetItem == nil then
        return nil
    end
    local gp = Turbine.Gameplay
    local r = { score = 0, items = 0, by_quality = {} }
    for i = 1, #S.EQUIPMENT_SLOTS do
        local ok, item = pcall(eq.GetItem, eq, S.EQUIPMENT_SLOTS[i])
        if ok == true and item ~= nil then
            local info = _call(item, "GetItemInfo")
            local q = _call(info, "GetQuality")
            if q == nil then q = _call(item, "GetQuality") end
            local d = _call(info, "GetDurability")
            if d == nil then d = _call(item, "GetDurability") end
            local qk = _enum_key(gp.ItemQuality, q)
            local dk = _enum_key(gp.ItemDurability, d)
            r.items = r.items + 1
            r.score = r.score + (QUALITY_POINTS[qk] or 0) + (DURABILITY_POINTS[dk] or 0)
            if qk ~= nil then
                r.by_quality[qk] = (r.by_quality[qk] or 0) + 1
            end
        end
    end
    return r
end

local QUALITY_COLORS = {
    Legendary = C(255, 128, 64), Incomparable = C(200, 120, 255), Rare = C(240, 120, 220),
    Uncommon = C(255, 230, 90), Common = nil,
}

local EquipScoreWidget = class(WidgetBase)
StatusBarWidgets.TitanEquipScoreWidget = EquipScoreWidget

function EquipScoreWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "equip_score", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleLeft)
    self:set_text("--")
end

function EquipScoreWidget:update(now)
    if not _throttle(self, now, 10) then
        return
    end
    local r = _equip_score()
    self._last = r
    if r == nil or r.items == 0 then
        self:set_text("--")
        _set_color(self, "base", nil)
        return
    end
    self:set_text(TR["Gear"] .. " " .. _fmt(r.score))
    -- color de la calidad que mas se repite
    local best, best_n = nil, 0
    for _, qk in ipairs(QUALITY_ORDER) do
        local n = r.by_quality[qk] or 0
        if n > best_n then
            best, best_n = qk, n
        end
    end
    _set_color(self, "q:" .. tostring(best), QUALITY_COLORS[best or ""])
end

function EquipScoreWidget:tooltip_text()
    local r = self._last or _equip_score()
    if r == nil then
        return TR["Equipment score"]
    end
    local lines = { TR["Equipment score"] .. ": " .. _fmt(r.score), TR["Equipped items"] .. ": " .. r.items }
    for _, qk in ipairs(QUALITY_ORDER) do
        local n = r.by_quality[qk]
        if n ~= nil and n > 0 then
            lines[#lines + 1] = "  " .. TR[qk] .. ": " .. n
        end
    end
    return table.concat(lines, "\n")
end

EquipScoreWidget.destroy = _destroy

-- Puntos LOTRO (se suman solos con los mensajes del chat)
local LotroPointsWidget = class(WidgetBase)
StatusBarWidgets.TitanLotroPointsWidget = LotroPointsWidget

function LotroPointsWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "lotro_points", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleLeft)
    self:set_text("-- LP")
end

function LotroPointsWidget:update(now)
    if not _throttle(self, now, 1) then
        return
    end
    local text
    if D.lp ~= nil then
        text = _fmt(D.lp) .. " LP"
    else
        text = "? LP"
    end
    if D.lp_session > 0 then
        text = text .. "  (+" .. _fmt(D.lp_session) .. ")"
        _set_color(self, "gain", COLORS.gain)
    else
        _set_color(self, "base", nil)
    end
    self:set_text(text)
end

function LotroPointsWidget:tooltip_text()
    local lines = { TR["LOTRO Points"] .. ": " .. (D.lp ~= nil and _fmt(D.lp) or "?") }
    lines[#lines + 1] = TR["Earned this session"] .. ": +" .. _fmt(D.lp_session)
    if D.lp == nil then
        lines[#lines + 1] = TR["Set your total in Options > Status bar"]
    end
    return table.concat(lines, "\n")
end

LotroPointsWidget.destroy = _destroy

---------------------------------------------------------------------
-- Detalles (ventanita) de los widgets anteriores
---------------------------------------------------------------------

function LocationWidget:tooltip_text()
    local zb = _G.LUI.Features ~= nil and _G.LUI.Features.ZoneBanner or nil
    local zone = zb ~= nil and zb.current_zone or nil
    if type(zone) ~= "string" or zone == "" then
        return TR["Location"] .. ": --"
    end
    return TR["Location"] .. ": " .. zone
end

function ReputationWidget:tooltip_text()
    local list = {}
    for name, n in pairs(D.rep_session) do
        list[#list + 1] = { name, n }
    end
    if #list == 0 and D.rep_last == nil then
        return TR["No reputation yet"]
    end
    table.sort(list, function(a, b) return math.abs(a[2]) > math.abs(b[2]) end)
    local lines = { TR["Reputation"] }
    if D.rep_last ~= nil then
        local n = D.rep_amount or 0
        lines[#lines + 1] = TR["Last"] .. ": " .. D.rep_last .. " " .. (n < 0 and "-" or "+") .. _fmt(n)
    end
    if #list > 0 then
        lines[#lines + 1] = TR["This session"] .. ":"
        for i = 1, math.min(8, #list) do
            local n = list[i][2]
            lines[#lines + 1] = "  " .. list[i][1] .. " " .. (n < 0 and "-" or "+") .. _fmt(n)
        end
    end
    return table.concat(lines, "\n")
end

function PvpRankWidget:tooltip_text()
    local pts = D.pvp_points
    if pts == nil then
        return TR["Infamy / Renown"] .. ": --\n" .. TR["Needs the PvMP+ plugin"]
    end
    local rank, pct = _rank_of(pts)
    local lines = { TR["Infamy / Renown"] .. ": " .. _fmt(pts), TR["Rank"] .. " " .. rank }
    if rank < #RANKS then
        lines[#lines + 1] = string.format("%.1f%%", pct * 100) .. " \194\183 " .. TR["Next rank in"] .. " " ..
            _fmt(RANKS[rank + 1] - pts)
    end
    return table.concat(lines, "\n")
end

function DayNightWidget:tooltip_text()
    local name, _, left, nxt = _phase(self._seed)
    local m, s = math.floor(left / 60), left % 60
    return TR[name] .. "\n" .. TR["Next"] .. ": " .. TR[nxt] .. " (" .. string.format("%d:%02d", m, s) .. ")"
end

function ServerTimeWidget:tooltip_text()
    local d = Turbine.Engine.GetDate()
    local local_text = S.format_hhmm({ Hour = d.Hour or 0, Minute = d.Minute or 0 }, self._format)
    local off = self._offset or 0
    return TR["Server time"] .. "\n" .. TR["Time (local)"] .. ": " .. local_text .. "\n" ..
        TR["Hours from local time"] .. ": " .. (off >= 0 and "+" or "") .. tostring(off)
end

local function _storage_tip(title, used, cap)
    if used == nil or cap == nil or cap <= 0 then
        return title .. ": --\n" .. TR["Open it once to read it"]
    end
    return title .. ": " .. used .. "/" .. cap .. "\n" .. TR["Free"] .. ": " .. (cap - used)
end

function VaultWidget:tooltip_text()
    return _storage_tip(TR["Personal vault"], D.vault_used, D.vault_cap)
end

function SharedStorageWidget:tooltip_text()
    return _storage_tip(TR["Shared storage"], D.shared_used, D.shared_cap)
end

for _, cls in ipairs({ LocationWidget, ReputationWidget, PvpRankWidget, DayNightWidget, ServerTimeWidget,
    VaultWidget, SharedStorageWidget, CharInfoWidget, EquipScoreWidget, LotroPointsWidget }) do
    cls.set_interaction_enabled = _set_interaction
end
