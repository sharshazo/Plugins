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
}
StatusBarWidgets.TitanData = D

local REP_KEY = "LUI_TitanRep"
local VAULT_KEY = "LUI_TitanVault"
local SHARED_KEY = "LUI_TitanShared"

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
    _load_pvp()
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
        D.pvp_next_reload = now + 120
    end
    if (D.pvp_reload_at ~= nil and now >= D.pvp_reload_at) or (D.load_at == nil and now >= D.pvp_next_reload) then
        D.pvp_reload_at = nil
        D.pvp_next_reload = now + 120
        _load_pvp()
    end
    _read_storage("GetVault", "vault_used", "vault_cap", Turbine.DataScope.Character, VAULT_KEY)
    _read_storage("GetSharedStorage", "shared_used", "shared_cap", Turbine.DataScope.Server, SHARED_KEY)
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

local function _init(self, key, widget_w, bar_h, font, content_alignment, icon_path, default_alignment)
    WidgetBase.Constructor(self, key, widget_w, bar_h, font, content_alignment or default_alignment, icon_path)
    self._has_icon = icon_path ~= nil
    self._icon_now = icon_path
    self._base_color = font ~= nil and font.color or nil
    self._color_key = "base"
    self._next = 0
    D.acquire()
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
    return true
end

local function _destroy(self)
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

PvpRankWidget.destroy = _destroy

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
    _set_icon(self, kind == "day" and ICONS.sun or (kind == "dusk" and ICONS.dusk or ICONS.moon))
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
    self:set_text("--/--")
end

function VaultWidget:update(now)
    if _throttle(self, now, 1) then
        _storage_update(self, D.vault_used, D.vault_cap)
    end
end

VaultWidget.destroy = _destroy

local SharedStorageWidget = class(WidgetBase)
StatusBarWidgets.TitanSharedStorageWidget = SharedStorageWidget

function SharedStorageWidget:Constructor(widget_w, bar_h, font, icon_path, cfg)
    _init(self, "shared_storage", widget_w, bar_h, font, cfg ~= nil and cfg.content_alignment or nil, icon_path,
        Turbine.UI.ContentAlignment.MiddleRight)
    self:set_text("--/--")
end

function SharedStorageWidget:update(now)
    if _throttle(self, now, 1) then
        _storage_update(self, D.shared_used, D.shared_cap)
    end
end

SharedStorageWidget.destroy = _destroy
