-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Botin: color por rareza + historial de la sesion.
--
--   Drops.Quality  -> rareza de un item (item vivo de la mochila o registro
--                     de la base de items) y el color de su nombre, con la
--                     misma paleta que ya usa la ventana de Bienes (Assets).
--   Drops.History  -> todo lo looteado en la sesion (solo en memoria, no se
--                     guarda nada en PluginData: el esquema de ajustes de LUI
--                     no cambia) + el dinero ganado desde que se entro.
--   /botin          -> abre/cierra la ventana del historial (con resumen por
--                     rareza: cada casilla de color filtra la lista)
--   Aviso de rareza -> cartel grande en pantalla cuando cae un objeto
--                     Incomparable o Legendario (opcion "drops.rare_alert")
--   /botin reiniciar-> vacia el historial y reinicia el contador de dinero
--   (tambien "/lui botin")
--
-- Todo va envuelto en pcall donde toca la API del juego: un fallo aqui
-- nunca debe cortar la ventana de Botin ni el resto de LUI.

local Drops = _G.LUI.Features.Drops
local Lore = _G.LUI.Data.Lore
local UI = _G.LUI.UI
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"

---------------------------------------------------------------------
-- Rareza
---------------------------------------------------------------------

local Quality = {}
Drops.Quality = Quality

local IQ = Turbine.Gameplay.ItemQuality

-- misma paleta que src/Assets/assets_entry.lua (QUALITY_NAME_COLORS);
-- Comun no se colorea: conserva el blanco de siempre
local NAME_COLORS = {
    [IQ.Uncommon] = Turbine.UI.Color(1, 0.43, 0.88, 0.43),
    [IQ.Rare] = Turbine.UI.Color(1, 0.36, 0.88, 0.96),
    [IQ.Incomparable] = Turbine.UI.Color(1, 0.76, 0.47, 1.00),
    [IQ.Legendary] = Turbine.UI.Color(1, 1.00, 0.78, 0.18),
}

-- orden para "mejorar" una rareza conocida (nunca se baja)
local RANK = {
    [IQ.Common] = 1,
    [IQ.Uncommon] = 2,
    [IQ.Rare] = 3,
    [IQ.Incomparable] = 4,
    [IQ.Legendary] = 5,
}

-- nombres del manifiesto de la base de items -> enum del juego
local DB_NAME_TO_QUALITY = {
    COMMON = IQ.Common,
    UNCOMMON = IQ.Uncommon,
    RARE = IQ.Rare,
    INCOMPARABLE = IQ.Incomparable,
    LEGENDARY = IQ.Legendary,
}

function Quality.name_color(quality)
    if quality == nil then
        return nil
    end
    return NAME_COLORS[quality]
end

function Quality.rank(quality)
    if quality == nil then
        return 0
    end
    return RANK[quality] or 0
end

function Quality.from_item(item)
    if item == nil then
        return nil
    end
    local ok, quality = pcall(function()
        local info = item:GetItemInfo()
        if info == nil or info.GetQuality == nil then
            return nil
        end
        return info:GetQuality()
    end)
    if ok ~= true then
        return nil
    end
    return quality
end

function Quality.from_ordinal(ordinal)
    if ordinal == nil or Lore == nil or Lore.Items == nil or Lore.Items.quality_name == nil then
        return nil
    end
    local ok, name = pcall(Lore.Items.quality_name, ordinal)
    if ok ~= true or name == nil then
        return nil
    end
    return DB_NAME_TO_QUALITY[name]
end

-- rareza de una fila de Botin: el item vivo manda; si no, la de la base
function Quality.of_record(record)
    if record == nil then
        return nil
    end
    local quality = Quality.from_item(record.live_item)
    if quality ~= nil and RANK[quality] ~= nil then
        return quality
    end
    return record.db_quality
end

local function _item_icon(item)
    if item == nil then
        return nil
    end
    local ok, icon = pcall(function()
        local info = item:GetItemInfo()
        if info == nil or info.GetIconImageID == nil then
            return nil
        end
        return info:GetIconImageID()
    end)
    if ok ~= true or type(icon) ~= "number" or icon == 0 then
        return nil
    end
    return icon
end

---------------------------------------------------------------------
-- Historial (datos)
---------------------------------------------------------------------

local History = Drops.History or {}
Drops.History = History

local MAX_ENTRIES = 300

local function _now()
    local ok, t = pcall(Turbine.Engine.GetGameTime)
    if ok == true and type(t) == "number" then
        return t
    end
    return 0
end

local function _current_money()
    local ok, money = pcall(function()
        local player = Turbine.Gameplay.LocalPlayer.GetInstance()
        if player == nil or player.GetAttributes == nil then
            return nil
        end
        local attributes = player:GetAttributes()
        if attributes == nil or attributes.GetMoney == nil then
            return nil
        end
        return attributes:GetMoney()
    end)
    if ok ~= true or type(money) ~= "number" then
        return nil
    end
    return money
end

function History.reset()
    History.entries = {}
    History.total_items = 0
    History.start_money = _current_money()
    History.revision = (History.revision or 0) + 1
end

if History.entries == nil then
    History.reset()
end

-- llamado en cada Update de la ventana de Botin: fija el dinero inicial en
-- cuanto el personaje lo tiene disponible (al cargar LUI puede faltar)
function History.tick(now)
    if History.start_money == nil then
        History.start_money = _current_money()
    end
    -- con la ventana abierta, el dinero se refresca ~1 vez por segundo
    local window = History.window
    if window ~= nil and type(now) == "number"
        and (History._money_refresh_at == nil or now >= History._money_refresh_at) then
        History._money_refresh_at = now + 1
        if window:IsVisible() == true then
            History.refresh_window()
        end
    end
end

function History.money_delta()
    local money = _current_money()
    if money == nil or History.start_money == nil then
        return nil
    end
    return money - History.start_money
end

local function _find(normalized_name)
    for i = 1, #History.entries do
        local entry = History.entries[i]
        if entry.key == normalized_name then
            return entry, i
        end
    end
    return nil, nil
end

function History.add(name, normalized_name, quantity, quality, icon_id)
    if type(name) ~= "string" or normalized_name == nil then
        return
    end
    quantity = tonumber(quantity) or 1
    if quantity < 1 then
        quantity = 1
    end

    local entry, index = _find(normalized_name)
    if entry == nil then
        entry = { key = normalized_name, name = name, quantity = 0, times = 0 }
    else
        table.remove(History.entries, index)
    end
    entry.quantity = entry.quantity + quantity
    entry.times = entry.times + 1
    entry.last_at = _now()
    if Quality.rank(quality) > Quality.rank(entry.quality) then
        entry.quality = quality
    end
    if entry.icon_id == nil and icon_id ~= nil then
        entry.icon_id = icon_id
    end
    History.maybe_alert(entry)
    -- lo mas reciente arriba
    table.insert(History.entries, 1, entry)
    while #History.entries > MAX_ENTRIES do
        table.remove(History.entries)
    end

    History.total_items = (History.total_items or 0) + quantity
    History.revision = (History.revision or 0) + 1
    History.refresh_window()
end

-- completa rareza / icono cuando la fila de Botin los descubre despues
-- (el item vivo de la mochila llega un instante despues del chat)
function History.note(record)
    if record == nil or record.normalized_name == nil then
        return
    end
    local entry = _find(record.normalized_name)
    if entry == nil then
        return
    end
    local changed = false
    local quality = Quality.of_record(record)
    if Quality.rank(quality) > Quality.rank(entry.quality) then
        entry.quality = quality
        changed = true
    end
    if entry.icon_id == nil then
        local icon = _item_icon(record.live_item) or record.db_icon_id
        if icon ~= nil then
            entry.icon_id = icon
            changed = true
        end
    end
    History.maybe_alert(entry)
    if changed then
        History.revision = (History.revision or 0) + 1
        History.refresh_window()
    end
end

---------------------------------------------------------------------
-- Historial (ventana)
---------------------------------------------------------------------

local WINDOW_W = 360
local WINDOW_H = 480
local PAD = 18
local TOP = 42
local ROW_H = 24
local ICON = 20
local MAX_ROWS_SHOWN = 150
local WHITE = Turbine.UI.Color(1, 0.92, 0.92, 0.92)
local GREY = Turbine.UI.Color(1, 0.70, 0.70, 0.70)
local GAIN = Turbine.UI.Color(1, 0.55, 0.92, 0.55)
local LOSS = Turbine.UI.Color(1, 0.88, 0.35, 0.35)
local CHIP_H = 34
local CHIP_GAP = 2
local CHIP_BG = Turbine.UI.Color(0.55, 0.10, 0.10, 0.10)

-- casillas del resumen: una por rareza (Comun tambien cuenta lo que no se
-- sabe de que rareza es)
local CHIPS = {
    { quality = IQ.Common, name = "Com\195\186n", color = WHITE },
    { quality = IQ.Uncommon, name = "Poco com\195\186n" },
    { quality = IQ.Rare, name = "Raro" },
    { quality = IQ.Incomparable, name = "Incomparable" },
    { quality = IQ.Legendary, name = "Legendario" },
}

local function _chip_quality(quality)
    if quality == nil or RANK[quality] == nil then
        return IQ.Common
    end
    return quality
end

local function _chip_color(chip)
    return chip.color or Quality.name_color(chip.quality) or WHITE
end

local function _money_text(delta)
    if delta == nil then
        return "Dinero de la sesi\195\179n: --", GREY
    end
    local sign, color = "", WHITE
    if delta > 0 then
        sign, color = "+", GAIN
    elseif delta < 0 then
        sign, color = "-", LOSS
        delta = -delta
    end
    local gold = math.floor(delta / 100000)
    local silver = math.floor(delta / 100) - gold * 1000
    local copper = delta - gold * 100000 - silver * 100
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = tostring(gold) .. " oro"
    end
    if gold > 0 or silver > 0 then
        parts[#parts + 1] = tostring(silver) .. " plata"
    end
    parts[#parts + 1] = tostring(copper) .. " cobre"
    return "Dinero de la sesi\195\179n: " .. sign .. table.concat(parts, " "), color
end

local function _new_label(parent, x, y, w, h, font, color, align)
    local label = Turbine.UI.Label()
    label:SetParent(parent)
    label:SetPosition(x, y)
    label:SetSize(w, h)
    label:SetFont(font)
    label:SetForeColor(color)
    label:SetMouseVisible(false)
    if align ~= nil then
        label:SetTextAlignment(align)
    end
    return label
end

local function _build_row(entry, width)
    local row = Turbine.UI.Control()
    row:SetSize(width, ROW_H)
    row:SetMouseVisible(false)

    local x = 2
    if entry.icon_id ~= nil and UI ~= nil and UI.Widgets ~= nil and UI.Widgets.Image ~= nil then
        local ok = pcall(function()
            local icon = UI.Widgets.Image()
            icon:SetParent(row)
            icon:SetPosition(x, math.floor((ROW_H - ICON) / 2))
            icon:SetMouseVisible(false)
            icon:set_icon(entry.icon_id, ICON)
        end)
        if ok ~= true then
            -- sin icono: la fila sigue funcionando igual
        end
    end
    x = x + ICON + 6

    local qty_w = 48
    _new_label(row, width - qty_w - 4, 0, qty_w, ROW_H, Turbine.UI.Lotro.Font.Verdana12,
        WHITE, Turbine.UI.ContentAlignment.MiddleRight):SetText("x" .. tostring(entry.quantity))

    _new_label(row, x, 0, width - x - qty_w - 8, ROW_H, Turbine.UI.Lotro.Font.Verdana12,
        Quality.name_color(entry.quality) or WHITE, Turbine.UI.ContentAlignment.MiddleLeft):SetText(entry.name)

    return row
end

local function _create_window()
    local window = Turbine.UI.Lotro.Window()
    window:SetSize(WINDOW_W, WINDOW_H)
    window:SetText("Historial de bot\195\173n")
    local ok_w, screen_w = pcall(Turbine.UI.Display.GetWidth)
    local ok_h, screen_h = pcall(Turbine.UI.Display.GetHeight)
    if ok_w == true and ok_h == true and type(screen_w) == "number" and type(screen_h) == "number" then
        window:SetPosition(math.floor((screen_w - WINDOW_W) / 2), math.floor((screen_h - WINDOW_H) / 2))
    else
        window:SetPosition(200, 200)
    end

    local inner_w = WINDOW_W - (PAD * 2)

    window.lbl_money = _new_label(window, PAD, TOP, inner_w, 18,
        Turbine.UI.Lotro.Font.Verdana14, WHITE, Turbine.UI.ContentAlignment.MiddleLeft)
    window.lbl_count = _new_label(window, PAD, TOP + 20, inner_w, 16,
        Turbine.UI.Lotro.Font.Verdana12, GREY, Turbine.UI.ContentAlignment.MiddleLeft)

    -- resumen por rareza; clic en una casilla = ver solo esa rareza
    window.chips = {}
    local chip_w = math.floor((inner_w - CHIP_GAP * (#CHIPS - 1)) / #CHIPS)
    for i = 1, #CHIPS do
        local chip = CHIPS[i]
        local box = Turbine.UI.Control()
        box:SetParent(window)
        box:SetPosition(PAD + (i - 1) * (chip_w + CHIP_GAP), TOP + 42)
        box:SetSize(chip_w, CHIP_H)
        box:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        box:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        box:SetBackColor(CHIP_BG)
        box:SetMouseVisible(false)

        box.line = Turbine.UI.Control()
        box.line:SetParent(box)
        box.line:SetPosition(0, CHIP_H - 2)
        box.line:SetSize(chip_w, 2)
        box.line:SetMouseVisible(false)
        box.line:SetBackColor(_chip_color(chip))
        box.line:SetVisible(false)

        box.lbl_name = _new_label(box, 0, 2, chip_w, 13, Turbine.UI.Lotro.Font.Verdana10,
            _chip_color(chip), Turbine.UI.ContentAlignment.MiddleCenter)
        box.lbl_name:SetText(chip.name)
        box.lbl_count = _new_label(box, 0, 14, chip_w, 18, Turbine.UI.Lotro.Font.Verdana14,
            WHITE, Turbine.UI.ContentAlignment.MiddleCenter)
        box.lbl_count:SetText("0")

        -- capa de clic encima de todo
        box.hit = Turbine.UI.Label()
        box.hit:SetParent(box)
        box.hit:SetPosition(0, 0)
        box.hit:SetSize(chip_w, CHIP_H)
        box.hit:SetMouseVisible(true)
        box.hit:SetZOrder(5)
        box.hit.MouseClick = function()
            if History.filter == chip.quality then
                History.filter = nil
            else
                History.filter = chip.quality
            end
            History.refresh_window(true)
        end
        window.chips[i] = box
    end

    window.lbl_filter = _new_label(window, PAD, TOP + 42 + CHIP_H + 3, inner_w, 14,
        Turbine.UI.Lotro.Font.Verdana10, GREY, Turbine.UI.ContentAlignment.MiddleLeft)

    local list_top = TOP + 42 + CHIP_H + 21
    local list_h = WINDOW_H - list_top - 50

    window.list = Turbine.UI.ListBox()
    window.list:SetParent(window)
    window.list:SetPosition(PAD, list_top)
    window.list:SetSize(inner_w - 12, list_h)

    window.scroll = Turbine.UI.Lotro.ScrollBar()
    window.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    window.scroll:SetParent(window)
    window.scroll:SetPosition(PAD + inner_w - 10, list_top)
    window.scroll:SetSize(10, list_h)
    window.list:SetVerticalScrollBar(window.scroll)

    window.lbl_empty = _new_label(window, PAD, list_top + 10, inner_w, 40,
        Turbine.UI.Lotro.Font.Verdana12, GREY, Turbine.UI.ContentAlignment.TopLeft)
    window.lbl_empty:SetMultiline(true)
    window.lbl_empty:SetText("Todav\195\173a no has looteado nada en esta sesi\195\179n.")

    window.btn_reset = Turbine.UI.Lotro.Button()
    window.btn_reset:SetParent(window)
    window.btn_reset:SetSize(110, 20)
    window.btn_reset:SetPosition(math.floor((WINDOW_W - 110) / 2), WINDOW_H - 38)
    window.btn_reset:SetText("Reiniciar")
    window.btn_reset.Click = function()
        History.reset()
        History.refresh_window(true)
    end

    window._built_revision = -1
    window:SetVisible(false)
    return window
end

function History.refresh_window(force)
    local window = History.window
    if window == nil or window:IsVisible() ~= true then
        return
    end
    local ok, err = pcall(function()
        local text, color = _money_text(History.money_delta())
        window.lbl_money:SetText(text)
        window.lbl_money:SetForeColor(color)
        window.lbl_count:SetText("Objetos: " .. tostring(History.total_items or 0)
            .. "   (" .. tostring(#History.entries) .. " distintos)")

        if force ~= true and window._built_revision == History.revision then
            return
        end
        window._built_revision = History.revision

        -- resumen por rareza
        local counts = History.quality_counts()
        local filter_name = nil
        for i = 1, #CHIPS do
            local chip = CHIPS[i]
            local box = window.chips[i]
            box.lbl_count:SetText(tostring(counts[chip.quality] or 0))
            local selected = History.filter == chip.quality
            box.line:SetVisible(selected)
            if selected then
                local c = _chip_color(chip)
                box:SetBackColor(Turbine.UI.Color(0.35, c.R, c.G, c.B))
                filter_name = chip.name
            else
                box:SetBackColor(CHIP_BG)
            end
        end
        if filter_name ~= nil then
            window.lbl_filter:SetText("Mostrando solo: " .. filter_name .. "  (clic de nuevo para ver todo)")
        else
            window.lbl_filter:SetText("Clic en una rareza para ver solo esa.")
        end

        window.list:ClearItems()
        local width = window.list:GetWidth()
        local shown = 0
        for i = 1, #History.entries do
            if shown >= MAX_ROWS_SHOWN then
                break
            end
            local entry = History.entries[i]
            if History.filter == nil or _chip_quality(entry.quality) == History.filter then
                window.list:AddItem(_build_row(entry, width))
                shown = shown + 1
            end
        end
        if #History.entries == 0 then
            window.lbl_empty:SetText("Todav\195\173a no has looteado nada en esta sesi\195\179n.")
        else
            window.lbl_empty:SetText("Nada de esa rareza en esta sesi\195\179n.")
        end
        window.lbl_empty:SetVisible(shown == 0)
    end)
    if ok ~= true then
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: historial de bot\195\173n: " .. tostring(err))
    end
end

function History.toggle_window()
    if History.window == nil then
        History.window = _create_window()
    end
    local window = History.window
    local show = window:IsVisible() ~= true
    window:SetVisible(show)
    if show then
        window:Activate()
        History.refresh_window(true)
    end
end

function History.destroy_window()
    History.destroy_alert()
    if History.window ~= nil then
        pcall(function()
            History.window:SetVisible(false)
            History.window:SetParent(nil)
        end)
        History.window = nil
    end
end

function History.quality_counts()
    local counts = {}
    for i = 1, #History.entries do
        local entry = History.entries[i]
        local q = _chip_quality(entry.quality)
        counts[q] = (counts[q] or 0) + (entry.quantity or 0)
    end
    return counts
end

---------------------------------------------------------------------
-- Aviso de rareza (Incomparable / Legendario)
---------------------------------------------------------------------

local ALERT_W = 460
local ALERT_H = 86
local ALERT_ICON = 36
local ALERT_FADE_IN = 0.25
local ALERT_HOLD = 3.50
local ALERT_FADE_OUT = 0.80
local ALERT_MIN_RANK = 4          -- Incomparable o mejor

local function _alert_enabled()
    local State = _G.LUI.Settings and _G.LUI.Settings.State or nil
    if State == nil or State.settings == nil or State.settings.drops == nil then
        return true
    end
    return State.settings.drops.rare_alert ~= false
end

local function _alert_title(quality)
    if quality == IQ.Legendary then
        return "\194\161LEGENDARIO!"
    end
    return "\194\161INCOMPARABLE!"
end

local function _set_alert_opacity(window, alpha)
    for i = 1, #window.parts do
        window.parts[i]:SetOpacity(alpha)
    end
end

local function _create_alert()
    local window = Turbine.UI.Window()
    window:SetSize(ALERT_W, ALERT_H)
    window:SetMouseVisible(false)
    window:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    window:SetZOrder(100)
    window.parts = {}

    local function part(control)
        control:SetParent(window)
        control:SetMouseVisible(false)
        window.parts[#window.parts + 1] = control
        return control
    end

    window.band = part(Turbine.UI.Control())
    window.band:SetPosition(0, 6)
    window.band:SetSize(ALERT_W, ALERT_H - 12)
    window.band:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    window.band:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    window.band:SetBackColor(Turbine.UI.Color(0.78, 0.03, 0.03, 0.05))

    window.lines = {}
    local line_specs = { { 4, 2, 1.0 }, { ALERT_H - 6, 2, 1.0 }, { 8, 1, 0.35 }, { ALERT_H - 9, 1, 0.35 } }
    for i = 1, #line_specs do
        local spec = line_specs[i]
        local line = part(Turbine.UI.Control())
        line:SetPosition(0, spec[1])
        line:SetSize(ALERT_W, spec[2])
        line:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        line:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        line.alpha = spec[3]
        window.lines[i] = line
    end

    window.icon = nil
    if UI ~= nil and UI.Widgets ~= nil and UI.Widgets.Image ~= nil then
        local ok, icon = pcall(function()
            local image = UI.Widgets.Image()
            image:SetParent(window)
            image:SetMouseVisible(false)
            image:SetPosition(20, math.floor((ALERT_H - ALERT_ICON) / 2))
            image:SetVisible(false)
            return image
        end)
        if ok == true then
            window.icon = icon
            window.parts[#window.parts + 1] = icon
        end
    end

    window.title = part(Turbine.UI.Label())
    window.title:SetPosition(0, 10)
    window.title:SetSize(ALERT_W, 34)
    window.title:SetFont(Turbine.UI.Lotro.Font.TrajanProBold24)
    window.title:SetFontStyle(Turbine.UI.FontStyle.Outline)
    window.title:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
    window.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    window.name = part(Turbine.UI.Label())
    window.name:SetPosition(60, 46)
    window.name:SetSize(ALERT_W - 120, 24)
    window.name:SetFont(Turbine.UI.Lotro.Font.Verdana16)
    window.name:SetFontStyle(Turbine.UI.FontStyle.Outline)
    window.name:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
    window.name:SetForeColor(WHITE)
    window.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    window.Update = function(sender)
        local ok = pcall(function()
            local t = _now() - (window.started_at or 0)
            local alpha
            if t < ALERT_FADE_IN then
                alpha = t / ALERT_FADE_IN
            elseif t < ALERT_FADE_IN + ALERT_HOLD then
                alpha = 1
            elseif t < ALERT_FADE_IN + ALERT_HOLD + ALERT_FADE_OUT then
                alpha = 1 - (t - ALERT_FADE_IN - ALERT_HOLD) / ALERT_FADE_OUT
            else
                alpha = 0
            end
            if alpha <= 0 then
                window:SetWantsUpdates(false)
                window:SetVisible(false)
                return
            end
            _set_alert_opacity(window, alpha)
        end)
        if ok ~= true then
            pcall(function()
                window:SetWantsUpdates(false)
                window:SetVisible(false)
            end)
        end
    end

    window:SetVisible(false)
    return window
end

function History.show_alert(name, quality, icon_id)
    local ok, err = pcall(function()
        if History.alert_window == nil then
            History.alert_window = _create_alert()
        end
        local window = History.alert_window
        local color = Quality.name_color(quality) or WHITE

        window.title:SetText(_alert_title(quality))
        window.title:SetForeColor(color)
        window.name:SetText(tostring(name or ""))
        for i = 1, #window.lines do
            local line = window.lines[i]
            line:SetBackColor(Turbine.UI.Color(line.alpha, color.R, color.G, color.B))
        end
        if window.icon ~= nil then
            if icon_id ~= nil then
                local shown = pcall(function()
                    window.icon:set_icon(icon_id, ALERT_ICON)
                end)
                window.icon:SetVisible(shown == true)
            else
                window.icon:SetVisible(false)
            end
        end

        local ok_w, screen_w = pcall(Turbine.UI.Display.GetWidth)
        local ok_h, screen_h = pcall(Turbine.UI.Display.GetHeight)
        if ok_w ~= true or type(screen_w) ~= "number" then
            screen_w = 1920
        end
        if ok_h ~= true or type(screen_h) ~= "number" then
            screen_h = 1080
        end
        window:SetPosition(math.floor((screen_w - ALERT_W) / 2), math.floor(screen_h * 0.18))

        window.started_at = _now()
        _set_alert_opacity(window, 0)
        window:SetVisible(true)
        window:SetWantsUpdates(true)
    end)
    if ok ~= true then
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: aviso de rareza: " .. tostring(err))
    end
end

-- una vez por cada vez que cae (entry.times cuenta las veces)
function History.maybe_alert(entry)
    if entry == nil or Quality.rank(entry.quality) < ALERT_MIN_RANK then
        return
    end
    if entry.alerted_times == entry.times then
        return
    end
    entry.alerted_times = entry.times
    if _alert_enabled() ~= true then
        return
    end
    History.show_alert(entry.name, entry.quality, entry.icon_id)
end

function History.destroy_alert()
    if History.alert_window ~= nil then
        pcall(function()
            History.alert_window:SetWantsUpdates(false)
            History.alert_window:SetVisible(false)
        end)
        History.alert_window = nil
    end
end

-- /botin [reiniciar]
function History.execute(arguments)
    local arg = ""
    if arguments ~= nil then
        arg = string.lower(tostring(arguments):match("^%s*(.-)%s*$") or "")
    end
    if arg == "reiniciar" or arg == "reset" then
        History.reset()
        History.refresh_window(true)
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: historial de bot\195\173n reiniciado.")
        return
    end
    History.toggle_window()
end

local command = Turbine.ShellCommand()
function command:Execute(_, arguments)
    History.execute(arguments)
end
function command:GetHelp()
    return "/botin abre el historial de botin de la sesion; /botin reiniciar lo vacia."
end
function command:GetShortHelp()
    return "Historial de botin (LUI)"
end
History.command = command

function History.register_command()
    if History._command_registered == true then
        return
    end
    local ok = pcall(Turbine.Shell.AddCommand, "botin", command)
    History._command_registered = ok == true
end

function History.unregister_command()
    if History._command_registered ~= true then
        return
    end
    pcall(Turbine.Shell.RemoveCommand, command)
    History._command_registered = false
end

History.register_command()
