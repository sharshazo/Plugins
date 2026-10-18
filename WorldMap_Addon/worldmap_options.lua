-- v3.11 (pedido del jugador): ventana de opciones del Mapa del Mundo.
-- "/mapa opciones" (o el boton "Opciones" del mapa). Se guarda por cuenta
-- (Turbine.DataScope.Account). Solo numeros enteros y si/no: el guardado
-- del juego no tiene problemas con la coma decimal.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WorldMapAddon = _G.WorldMapAddon or {}
WorldMapAddon.Options = WorldMapAddon.Options or {}
local O = WorldMapAddon.Options

local SAVE_KEY = "WorldMap_Options"
local DEFAULTS = {
    cards = true,       -- tarjetas modernas en los mapas de zona
    width = 300,        -- ancho de las tarjetas
    opacity = 100,      -- % de opacidad de las tarjetas
    lore = true,        -- saber (texto de historia) en las tarjetas
    rewards = true,     -- recompensas (XP de virtud, puntos LOTRO, reputacion)
    deedbars = true,    -- barritas de % de hazañas en el mapa del mundo
    zonetoast = true,   -- v3.12: aviso de hazañas al entrar a una zona
}
local WIDTHS = { 300, 360 }
local OPACITIES = { 100, 90, 80, 70 }

O.values = O.values or {}

function O.Get(key)
    local v = O.values[key]
    if v == nil then
        return DEFAULTS[key]
    end
    return v
end

local function Valid(key, v)
    local d = DEFAULTS[key]
    if d == nil then
        return false
    end
    if type(d) == "boolean" then
        return type(v) == "boolean"
    end
    if key == "width" then
        for _, w in ipairs(WIDTHS) do
            if tonumber(v) == w then return true end
        end
        return false
    end
    if key == "opacity" then
        for _, w in ipairs(OPACITIES) do
            if tonumber(v) == w then return true end
        end
        return false
    end
    return false
end

-- aviso a lo que ya esta en pantalla (barras del mapa del mundo)
local function Applied()
    local map = WorldMapAddon.instance
    if map ~= nil and type(map._refreshDeedBars) == "function" then
        pcall(map._refreshDeedBars, map)
    end
    if map ~= nil and map.zoneView ~= nil and type(map.zoneView._refreshDeedPanel) == "function" then
        pcall(map.zoneView._refreshDeedPanel, map.zoneView)
    end
    if type(O.onChange) == "function" then
        pcall(O.onChange)
    end
end

function O.Set(key, v)
    if not Valid(key, v) then
        return
    end
    if type(DEFAULTS[key]) == "number" then
        v = tonumber(v)
    end
    O.values[key] = v
    if O.loading then
        -- 2026-10-18 (MAP-02): la lectura aun no llego; se recuerda que el
        -- jugador eligio esto (gana sobre lo guardado) y se guarda todo al
        -- terminar la lectura, para no perder las demas opciones
        O.pendingKeys = O.pendingKeys or {}
        O.pendingKeys[key] = true
        Applied()
        return
    end
    O.SaveAll()
    Applied()
end

function O.SaveAll()
    local data = {}
    for k in pairs(DEFAULTS) do
        if O.values[k] ~= nil then
            data[k] = O.values[k]
        end
    end
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, SAVE_KEY, data)
end

-- lectura asincronica (con funcion de aviso, ver worldmap_deeds.lua)
function O.Load()
    local answered = false
    O.loading = true
    local ok = pcall(Turbine.PluginData.Load, Turbine.DataScope.Account, SAVE_KEY, function(data)
        if answered then
            return
        end
        answered = true
        O.loading = false
        local pending = O.pendingKeys or {}
        O.pendingKeys = nil
        if type(data) == "table" then
            for k in pairs(DEFAULTS) do
                local v = data[k]
                if pending[k] then
                    v = nil   -- lo elegido durante la lectura manda
                end
                if type(DEFAULTS[k]) == "number" then
                    v = tonumber(v)
                end
                if v ~= nil and Valid(k, v) then
                    O.values[k] = v
                end
            end
        end
        if next(pending) ~= nil then
            O.SaveAll()
        end
        Applied()
    end)
    if not ok and not answered then
        O.loading = false
        O.pendingKeys = nil
    end
end

-- ---------------------------------------------------------------------
-- ventana (mismo estilo oscuro que "Misiones activas")
-- ---------------------------------------------------------------------
local W, ROW_H, TOP = 340, 34, 46
local ROWS = {
    { key = "cards", text = "Tarjetas modernas en los mapas de zona" },
    { key = "width", text = "Tama\195\177o de las tarjetas", values = WIDTHS, names = { [300] = "Normal", [360] = "Grande" } },
    { key = "opacity", text = "Opacidad de las tarjetas", values = OPACITIES },
    { key = "lore", text = "Mostrar el saber (historia)" },
    { key = "rewards", text = "Mostrar recompensas (XP, LOTRO, rep.)" },
    { key = "deedbars", text = "% de haza\195\177as al entrar a una zona" },
    { key = "zonetoast", text = "Aviso de haza\195\177as al entrar a una zona" },
}

local function Hex(hex)
    hex = hex:gsub("#", "")
    return Turbine.UI.Color(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255)
end

local function Font(name, fallback)
    local F = Turbine.UI.Lotro.Font
    return F[name] or F[fallback] or F.Verdana12
end

local function ValueText(row)
    local v = O.Get(row.key)
    if row.values == nil then
        return v and "S\195\173" or "No"
    end
    if row.names ~= nil and row.names[v] ~= nil then
        return row.names[v]
    end
    return tostring(v) .. "%"
end

local function NextValue(row)
    local v = O.Get(row.key)
    if row.values == nil then
        return not v
    end
    for i, x in ipairs(row.values) do
        if x == v then
            return row.values[(i % #row.values) + 1]
        end
    end
    return row.values[1]
end

function O.Refresh()
    local win = O.win
    if win == nil then
        return
    end
    for _, r in ipairs(win.rows) do
        local on = O.Get(r.row.key)
        r.btn:SetText(ValueText(r.row))
        local active = (r.row.values ~= nil) or on == true
        r.btn:SetForeColor(Hex(active and "#8CC8FF" or "#6A7488"))
        r.btn:SetBackColor(Hex(active and "#1E2D46" or "#22262F"))
    end
end

local function Build()
    local H = TOP + #ROWS * ROW_H + 40
    local win
    local P = WorldMapAddon.UI ~= nil and WorldMapAddon.UI.ModernPanel or nil
    local ok = false
    if P ~= nil then
        ok, win = pcall(P, W, H)
    end
    if not ok or win == nil then
        win = Turbine.UI.Lotro.Window()
        win:SetSize(W, H)
    end
    win:SetText("Mapa del Mundo - Opciones")
    win:SetZOrder(20)
    local dw, dh = Turbine.UI.Display.GetWidth(), Turbine.UI.Display.GetHeight()
    win:SetPosition(math.floor((dw - W) / 2), math.floor((dh - H) / 3))
    win.rows = {}
    for i, row in ipairs(ROWS) do
        local y = TOP + (i - 1) * ROW_H
        local stripe = Turbine.UI.Control()
        stripe:SetParent(win)
        stripe:SetPosition(12, y)
        stripe:SetSize(W - 24, ROW_H - 4)
        stripe:SetBackColor(Hex(i % 2 == 1 and "#181B22" or "#1D2029"))
        stripe:SetMouseVisible(false)
        local lbl = Turbine.UI.Label()
        lbl:SetParent(win)
        lbl:SetPosition(22, y)
        lbl:SetSize(W - 130, ROW_H - 4)
        lbl:SetFont(Font("Verdana12", "Verdana12"))
        lbl:SetForeColor(Hex("#E8ECF4"))
        lbl:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        lbl:SetMouseVisible(false)
        lbl:SetText(row.text)
        local btn = Turbine.UI.Label()
        btn:SetParent(win)
        btn:SetPosition(W - 100, y + 4)
        btn:SetSize(76, ROW_H - 12)
        btn:SetFont(Font("Verdana12", "Verdana12"))
        btn:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        btn:SetMouseVisible(true)
        btn.MouseClick = function()
            O.Set(row.key, NextValue(row))
            O.Refresh()
        end
        win.rows[#win.rows + 1] = { row = row, btn = btn }
    end
    local hint = Turbine.UI.Label()
    hint:SetParent(win)
    hint:SetPosition(16, TOP + #ROWS * ROW_H + 6)
    hint:SetSize(W - 32, 24)
    hint:SetFont(Font("Verdana10", "Verdana12"))
    hint:SetForeColor(Hex("#8C96AA"))
    hint:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    hint:SetMouseVisible(false)
    hint:SetText("Clic en el valor para cambiarlo. Se guarda para toda la cuenta.")
    O.win = win
end

function O.Show()
    if O.win == nil then
        Build()
    end
    O.Refresh()
    O.win:SetVisible(true)
    pcall(function() O.win:Activate() end)
end

function O.Toggle()
    if O.win ~= nil and O.win:IsVisible() then
        O.win:SetVisible(false)
    else
        O.Show()
    end
end

pcall(O.Load)
