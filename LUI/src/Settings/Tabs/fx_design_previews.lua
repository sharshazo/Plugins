-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- (2026-10-16) Vistas previas compartidas de la pestana "Diseno" (efectos que
-- expiran y reutilizaciones): tarjetas de diseno y animaciones en movimiento.

import "Turbine.UI"
import "Turbine.UI.Lotro"

local TR = _G.LUI.Locale.TR
local UI = _G.LUI.UI
_G.LUI.Settings.Tabs.FxDesignPreviews = _G.LUI.Settings.Tabs.FxDesignPreviews or {}
local Previews = _G.LUI.Settings.Tabs.FxDesignPreviews

-- (2026-10-16) vistas previas del diseno y de las animaciones (en la misma
-- pestana "Diseno"). Imagenes en assets/ui/efectos/vista; las animaciones son
-- hojas de 16 cuadros que se recorren mientras la pestana esta a la vista.
local VISTA = "LUI/assets/ui/efectos/vista/"
local CARD_W, CARD_H = 240, 72
local ANIM_W, ANIM_H, ANIM_FRAMES, ANIM_FPS = 240, 44, 16, 12
local CAPTION_H = 18
local SEL_COLOR = Turbine.UI.Color(1, 1, 0.82, 0.3)
local OFF_COLOR = Turbine.UI.Color(1, 0.22, 0.23, 0.28)

local function _plain(parent)
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    return c
end

local function _caption(parent, text)
    local l = UI.Widgets.LuiLabel()
    l:SetParent(parent)
    l:SetMouseVisible(false)
    pcall(l.SetMultiline, l, false)
    l:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    l:SetFontStyle(Turbine.UI.FontStyle.Outline)
    l:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
    l:SetForeColor(Turbine.UI.Color(1, 0.9, 0.9, 0.9))
    l:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    l:SetText(text)
    return l
end

-- esta el control a la vista? (la ventana y todos sus padres visibles)
local function _displayed(c)
    local p = c
    local guard = 0
    while p ~= nil and guard < 40 do
        if p.IsVisible ~= nil and p:IsVisible() ~= true then
            return false
        end
        p = p.GetParent ~= nil and p:GetParent() or nil
        guard = guard + 1
    end
    return true
end

local function _entry_value(entry)
    if entry == nil or entry.get_value == nil then
        return nil
    end
    local ok, v = pcall(entry.get_value, entry)
    if ok then
        return v
    end
    return nil
end

-- tarjetas de diseno (clic = elegir ese diseno) + animaciones en movimiento
-- cards: { {valor, imagen, texto}, ... } ; anims: { {clave, texto, hoja}, ... }
-- sheet_prefix: "anim_" (efectos) o "anim_cd_" (reutilizaciones)
function Previews.add(design, prefix, anims, cards_spec, sheet_prefix)
    local DESIGN_CARDS = cards_spec
    sheet_prefix = sheet_prefix or "anim_"
    local gap = 10

    -- tarjetas
    local cards_entry = design:add_custom(prefix .. "_design_cards", CARD_H + 4 + CAPTION_H + 4)
    local cards = {}
    for i = 1, #DESIGN_CARDS do
        local spec = DESIGN_CARDS[i]
        local frame = Turbine.UI.Control()
        frame:SetParent(cards_entry.control)
        frame:SetMouseVisible(true)
        frame:SetBackColor(OFF_COLOR)
        local img = _plain(frame)
        img:SetPosition(2, 2)
        img:SetSize(CARD_W, CARD_H)
        pcall(img.SetBackground, img, VISTA .. spec[2])
        local cap = _caption(cards_entry.control, TR[spec[3]])
        frame.MouseClick = function()
            local e = design.controls[prefix .. "_style"]
            if e ~= nil and e.set_value ~= nil then
                pcall(e.set_value, e, spec[1])
            end
        end
        cards[i] = { value = spec[1], frame = frame, img = img, cap = cap }
    end
    cards_entry.control.SizeChanged = function()
        local w = cards_entry.control:GetWidth()
        local cw = math.min(CARD_W + 4, math.floor((w - (#cards - 1) * gap) / #cards))
        if cw < 40 then cw = 40 end
        for i = 1, #cards do
            local x = (i - 1) * (cw + gap)
            cards[i].frame:SetPosition(x, 0)
            cards[i].frame:SetSize(cw, CARD_H + 4)
            cards[i].cap:SetPosition(x, CARD_H + 6)
            cards[i].cap:SetSize(cw, CAPTION_H)
        end
    end

    -- animaciones
    design:add_row_break()
    local rows = math.ceil(#anims / 3)
    local anim_entry = design:add_custom(prefix .. "_anim_previews", rows * (ANIM_H + 4 + CAPTION_H + 8))
    local tiles = {}
    for i = 1, #anims do
        local frame = _plain(anim_entry.control)
        frame:SetBackColor(OFF_COLOR)
        local clip = _plain(frame)
        clip:SetPosition(1, 1)
        clip:SetSize(ANIM_W, ANIM_H)
        local sheet = _plain(clip)
        sheet:SetSize(ANIM_W, ANIM_H * ANIM_FRAMES)
        sheet:SetPosition(0, 0)
        pcall(sheet.SetBackground, sheet, VISTA .. sheet_prefix .. anims[i][3] .. ".tga")
        local cap = _caption(anim_entry.control, TR[anims[i][2]])
        -- velo oscuro para las desactivadas (la opacidad no funciona en controles)
        local veil = _plain(frame)
        veil:SetZOrder(5)
        pcall(veil.SetBackColorBlendMode, veil, Turbine.UI.BlendMode.AlphaBlend)
        veil:SetBackColor(Turbine.UI.Color(0.7, 0.02, 0.02, 0.03))
        veil:SetPosition(1, 1)
        veil:SetSize(ANIM_W, ANIM_H)
        veil:SetVisible(false)
        tiles[i] = { key = anims[i][1], frame = frame, clip = clip, sheet = sheet, cap = cap, veil = veil, on = nil }
    end
    anim_entry.control.SizeChanged = function()
        local w = anim_entry.control:GetWidth()
        local tw = math.min(ANIM_W + 2, math.floor((w - 2 * gap) / 3))
        if tw < 40 then tw = 40 end
        for i = 1, #tiles do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local x = col * (tw + gap)
            local y = row * (ANIM_H + 4 + CAPTION_H + 8)
            tiles[i].frame:SetPosition(x, y)
            tiles[i].frame:SetSize(tw, ANIM_H + 2)
            tiles[i].clip:SetSize(math.max(1, tw - 2), ANIM_H)
            tiles[i].veil:SetSize(math.max(1, tw - 2), ANIM_H)
            tiles[i].cap:SetPosition(x, y + ANIM_H + 4)
            tiles[i].cap:SetSize(tw, CAPTION_H)
        end
    end

    -- motor: anima y sincroniza la tarjeta elegida y las animaciones activas
    local driver = Turbine.UI.Control()
    driver:SetParent(anim_entry.control)
    driver:SetVisible(false)
    local last_frame = -1
    local function sync()
        local style = _entry_value(design.controls[prefix .. "_style"]) or "classic"
        for i = 1, #cards do
            local sel = cards[i].value == style
            if cards[i].sel ~= sel then
                cards[i].sel = sel
                cards[i].frame:SetBackColor(sel and SEL_COLOR or OFF_COLOR)
            end
        end
        for i = 1, #tiles do
            local v = _entry_value(design.controls[prefix .. "_" .. tiles[i].key])
            local on = v ~= false
            if tiles[i].on ~= on then
                tiles[i].on = on
                tiles[i].veil:SetVisible(on ~= true)
                tiles[i].frame:SetBackColor(on and SEL_COLOR or OFF_COLOR)
            end
        end
    end
    local next_check = 0
    driver.Update = function()
        local now = Turbine.Engine.GetGameTime()
        local f = math.floor(now * ANIM_FPS) % ANIM_FRAMES
        if f == last_frame then
            return
        end
        last_frame = f
        if now >= next_check then
            next_check = now + 0.5
            if _displayed(anim_entry.control) ~= true then
                driver:SetWantsUpdates(false)
                return
            end
            pcall(sync)
        end
        for i = 1, #tiles do
            tiles[i].sheet:SetPosition(0, -f * ANIM_H)
        end
    end
    local function start()
        next_check = 0
        last_frame = -1
        pcall(sync)
        driver:SetWantsUpdates(true)
    end
    -- al mostrar la pestana y al pasar el raton por las vistas
    local prior_selected = design.on_selected
    design.on_selected = function(self, ...)
        if prior_selected ~= nil then
            prior_selected(self, ...)
        end
        start()
    end
    for i = 1, #cards do
        local prior_click = cards[i].frame.MouseClick
        cards[i].frame.MouseClick = function(...)
            prior_click(...)
            start()
        end
        cards[i].frame.MouseEnter = function()
            start()
        end
    end
end

