-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local lui_timed_row_min_name_width = _G.LUI.Utils.lui_timed_row_min_name_width
local Drops = _G.LUI.Features.Drops
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local scaled_int = UI.NativeScaling.scaled_int
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.UI.Widgets.base_window"
import "LUI.src.Utils.timed_row_layout"

-- (2026-09-30, actualizacion 49.6) el juego pide AttachEdges en los
-- controles con modo de estirado; None = tamano fijo. Sin 49.6, no hace nada.
local function _attach_fixed_edges(control)
    local EA = Turbine.UI.EdgeAttachmentType
    if EA ~= nil and control ~= nil and control.AttachEdges ~= nil then
        pcall(control.AttachEdges, control, EA.None, EA.None, EA.None, EA.None)
    end
end

-- (2026-09-30, 49.6) con estirado activo el juego ignora SetSize salvo que
-- el tamano maximo/minimo del control lo acompanen (probado en el juego,
-- ver UI/Widgets/image.lua). Sin la 49.6 es un SetSize normal.
local function _fit_stretched(control, w, h)
    if control ~= nil and control.SetMaximumSize ~= nil then
        pcall(control.SetMinimumSize, control, 1, 1)
        pcall(control.SetMaximumSize, control, math.max(1, math.floor(w + 0.5)), math.max(1, math.floor(h + 0.5)))
    end
    control:SetSize(w, h)
end

local Style = UI.Widgets.Style
local BASE_ROW_PADDING = 4
local BASE_GAP = 6
local MIN_WIDTH = 140
local ITEM_INFO_CONTROL_OFFSET = -3
local ITEM_INFO_CONTROL_EXTRA = 3
-- borde dorado de los objetos valiosos (incomparable / legendario)
local VALUABLE_EDGE = 2
local VALUABLE_COLOR = Turbine.UI.Color(1, 1.00, 0.78, 0.18)

local function _sanitize_image_id(value)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil or value == 0 then
        return nil
    end
    return value
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, size * State.settings.global.scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(size * State.settings.global.scale))
    end
    return font
end

local function _drops_font_size()
    return Style.CONTROL_FONT_SIZE * State.settings.global.scale
end

local function _drops_qty_width()
    return lui_timed_row_estimate_text_width("999", Style.CONTROL_FONT_NAME, _drops_font_size())
end

local function _drops_min_width(icon_size, padding, gap)
    local qty_width = _drops_qty_width()
    local name_width = lui_timed_row_min_name_width(Style.CONTROL_FONT_NAME, _drops_font_size())
    return math.max(MIN_WIDTH, (2 * padding) + icon_size + gap + qty_width + gap + name_width)
end

local function _with_alpha(color, alpha)
    if color == nil then
        return Turbine.UI.Color(alpha, 1, 1, 1)
    end
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

local function _set_alpha_backdrop(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _set_stretch_mode_fit(control)
    if control ~= nil and control.SetStretchMode ~= nil then
        control:SetStretchMode(1)
        _attach_fixed_edges(control)
    end
end

local DropEntry = class(UI.Widgets.LuiBaseWindow)
Drops.DropEntry = DropEntry

-- (2026-10-01) las filas del botin NUNCA usan el escalado del juego: el
-- cartel LOOT es de tamano fijo y, si el juego agrandaba las filas (escala
-- de interfaz 1.20), sobresalian de los estandartes. Ver
-- Drops/drop_window.lua (_never_native_scaling).
function DropEntry:apply_native_scaling(target_window)
    local target = target_window or self
    if target ~= nil then
        UI.NativeScaling.disable(target)
    end
end

function DropEntry:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })

    self.record = nil
    self._item_bound = nil
    self._opacity = 1
    self._row_height = 0
    self._icon_side = 0
    self._padding = 0
    self._gap = 0
    self._qty_width = 0
    self._width = 0

    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetMouseVisible(false)
    self:SetVisible(false)

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    _set_alpha_backdrop(self.background)

    -- 4 tiras finas (arriba/abajo/izquierda/derecha) sobre el fondo de la
    -- fila; solo se ven en objetos incomparables o legendarios
    self._valuable = false
    self.gold_edges = {}
    for i = 1, 4 do
        local edge = Turbine.UI.Control()
        edge:SetParent(self)
        edge:SetMouseVisible(false)
        edge:SetBackColor(VALUABLE_COLOR)
        edge:SetVisible(false)
        self.gold_edges[i] = edge
    end

    self.icon_host = Turbine.UI.Control()
    self.icon_host:SetParent(self)
    self.icon_host:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_host:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_host:SetMouseVisible(false)

    self.icon_background = UI.Widgets.Image()
    self.icon_background:SetParent(self.icon_host)
    self.icon_background:SetMouseVisible(false)
    self.icon_background:SetZOrder(1)
    if self.icon_background.SetBlendMode ~= nil then
        self.icon_background:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
    _set_stretch_mode_fit(self.icon_background)

    self.icon_foreground = UI.Widgets.Image()
    self.icon_foreground:SetParent(self.icon_host)
    self.icon_foreground:SetMouseVisible(false)
    self.icon_foreground:SetZOrder(2)
    if self.icon_foreground.SetBlendMode ~= nil then
        self.icon_foreground:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
    _set_stretch_mode_fit(self.icon_foreground)

    self.item_info_control = Turbine.UI.Lotro.ItemInfoControl()
    self.item_info_control:SetParent(self.icon_host)
    self.item_info_control:SetVisible(false)
    self.item_info_control:SetMouseVisible(false)
    self.item_info_control:SetZOrder(0)
    self.item_info_control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    _set_stretch_mode_fit(self.item_info_control)

    self.name_label = UI.Widgets.LuiLabel()
    self.name_label:SetParent(self)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetSelectable(false)
    self.name_label:SetMultiline(true)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.qty_label = UI.Widgets.LuiLabel()
    self.qty_label:SetParent(self)
    self.qty_label:SetMouseVisible(false)
    self.qty_label:SetSelectable(false)
    self.qty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self:apply_settings()
end

function DropEntry:apply_settings()
    local s = State.settings.drops
    self._padding = scaled_int(BASE_ROW_PADDING)
    self._row_height = s.icon_size + (2 * self._padding)
    self._icon_side = s.icon_size
    self._gap = scaled_int(BASE_GAP)
    self._qty_width = _drops_qty_width()
    self._width = s.width
    local min_width = _drops_min_width(self._icon_side, self._padding, self._gap)
    if self._width < min_width then
        self._width = min_width
    end

    self:SetSize(self._width, self._row_height)
    self.background:SetPosition(0, 0)
    self.background:SetSize(self._width, self._row_height)
    self.background:SetBackColor(_with_alpha(s.item.background_color, s.item.background_opacity))

    local edge = math.max(1, scaled_int(VALUABLE_EDGE))
    local e = self.gold_edges
    e[1]:SetPosition(0, 0)
    e[1]:SetSize(self._width, edge)
    e[2]:SetPosition(0, self._row_height - edge)
    e[2]:SetSize(self._width, edge)
    e[3]:SetPosition(0, 0)
    e[3]:SetSize(edge, self._row_height)
    e[4]:SetPosition(self._width - edge, 0)
    e[4]:SetSize(edge, self._row_height)

    self.icon_host:SetPosition(self._padding, self._padding)
    self.icon_host:SetSize(self._icon_side, self._icon_side)

    self.icon_background:SetPosition(0, 0)
    self.icon_background:set_size(self._icon_side, self._icon_side)
    self.icon_foreground:SetPosition(0, 0)
    self.icon_foreground:set_size(self._icon_side, self._icon_side)
    self.item_info_control:SetPosition(ITEM_INFO_CONTROL_OFFSET, ITEM_INFO_CONTROL_OFFSET)
    _fit_stretched(self.item_info_control, self._icon_side + ITEM_INFO_CONTROL_EXTRA, self._icon_side + ITEM_INFO_CONTROL_EXTRA)

    local font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE)
    self.name_label:SetFont(font)
    self.name_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.name_label:SetForeColor(Style.FOREGROUND)
    self.name_label:SetOutlineColor(Style.TEXT_OUTLINE)

    self.qty_label:SetFont(font)
    self.qty_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.qty_label:SetForeColor(Style.FOREGROUND)
    self.qty_label:SetOutlineColor(Style.TEXT_OUTLINE)

    local content_h = self._row_height - (2 * self._padding)
    if s.icon_side == LUI_ENUMS.side.RIGHT then
        local icon_x = self._width - self._padding - self._icon_side
        self.icon_host:SetPosition(icon_x, self._padding)

        self.qty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        self.qty_label:SetPosition(self._padding, self._padding)
        self.qty_label:SetSize(self._qty_width, content_h)

        local text_x = self._padding + self._qty_width + self._gap
        local text_w = icon_x - text_x - self._gap
        if text_w < 1 then
            text_w = 1
        end
        self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        self.name_label:SetPosition(text_x, self._padding)
        self.name_label:SetSize(text_w, content_h)
    else
        self.icon_host:SetPosition(self._padding, self._padding)

        local qty_x = self._width - self._padding - self._qty_width
        self.qty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        self.qty_label:SetPosition(qty_x, self._padding)
        self.qty_label:SetSize(self._qty_width, content_h)

        local text_x = self._padding + self._icon_side + self._gap
        local text_w = qty_x - text_x - self._gap
        if text_w < 1 then
            text_w = 1
        end
        self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        self.name_label:SetPosition(text_x, self._padding)
        self.name_label:SetSize(text_w, content_h)
    end

    self:_apply_record()
end

function DropEntry:set_record(record)
    self.record = record
    self:_apply_record()
end

function DropEntry:set_live_item(item)
    if self.record == nil then
        return
    end
    self.record.live_item = item
    self:_apply_item()
end

function DropEntry:set_opacity(opacity)
    self._opacity = opacity

    self:SetOpacity(opacity)
    for i = 1, #self.gold_edges do
        self.gold_edges[i]:SetOpacity(opacity)
    end
    self.icon_host:SetOpacity(opacity)
    self.icon_background:SetOpacity(opacity)
    self.icon_foreground:SetOpacity(opacity)
    self.item_info_control:SetOpacity(opacity)
end

function DropEntry:destroy()
    self:set_record(nil)
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

function DropEntry:_apply_record()
    local record = self.record
    if record == nil then
        self.name_label:SetText("")
        self.qty_label:SetText("")
        self:_bind_item(nil)
        self:_set_valuable(false)
        self:SetVisible(false)
        return
    end

    self:SetVisible(true)
    self.name_label:SetText(record.name)
    -- counts only matter from 2 up: "[Hide]" for singles, "[Hide  5]"
    -- for stacks (merged rows re-enter here via set_record)
    if record.quantity >= 2 then
        self.qty_label:SetText(tostring(record.quantity))
    else
        self.qty_label:SetText("")
    end
    self:set_opacity(self._opacity)
    self:_apply_item()
end

function DropEntry:_apply_item()
    local record = self.record
    if record == nil then
        self:_bind_item(nil)
        return
    end
    self:_bind_item(record.live_item, record.db_icon_id, record.db_background_id)
    self:_apply_quality_color()
end

-- nombre coloreado por rareza (poco comun verde, raro celeste, incomparable
-- morado, legendario dorado); comun y desconocido quedan en el blanco de
-- siempre. Drops.Quality vive en loot_history.lua.
function DropEntry:_apply_quality_color()
    local color = nil
    local valuable = false
    if self.record ~= nil and Drops.Quality ~= nil then
        local ok, quality = pcall(Drops.Quality.of_record, self.record)
        if ok == true then
            color = Drops.Quality.name_color(quality)
            -- rango 4 = incomparable, 5 = legendario (ver loot_history.lua)
            valuable = Drops.Quality.rank(quality) >= 4
        end
    end
    self.name_label:SetForeColor(color or Style.FOREGROUND)
    self:_set_valuable(valuable)
end

-- borde dorado alrededor de la fila (pedido del usuario: "destacar lo
-- valioso ... el borde dorado")
function DropEntry:_set_valuable(valuable)
    valuable = valuable == true
    if self._valuable == valuable then
        return
    end
    self._valuable = valuable
    for i = 1, #self.gold_edges do
        self.gold_edges[i]:SetVisible(valuable)
    end
end

function DropEntry:_bind_item(item, db_icon_id, db_background_id)
    local bound_key = item
    if bound_key == nil then
        bound_key = db_icon_id
    end
    if self._item_bound == bound_key then
        return
    end

    self._item_bound = bound_key

    if item == nil and db_icon_id ~= nil then
        -- lore-DB fallback: icon + quality background resolved by name
        -- (carry-all loot never surfaces a live backpack item); no native
        -- tooltip in this mode, the toast is transient anyway
        self:SetMouseVisible(false)
        self.icon_host:SetMouseVisible(false)
        self.icon_background:set_icon(db_background_id, self._icon_side)
        self.icon_background:SetVisible(db_background_id ~= nil)
        self.icon_foreground:set_icon(db_icon_id, self._icon_side)
        self.icon_foreground:SetVisible(true)
        self.item_info_control:SetMouseVisible(false)
        self.item_info_control:SetVisible(false)
        self.item_info_control:SetItemInfo(nil)
        _set_stretch_mode_fit(self.icon_background)
        _set_stretch_mode_fit(self.icon_foreground)
        return
    end

    if item == nil then
        self:SetMouseVisible(false)
        self.icon_host:SetMouseVisible(false)
        self.icon_background:set_icon(nil, self._icon_side)
        self.icon_background:SetVisible(false)
        self.icon_foreground:set_icon(nil, self._icon_side)
        self.icon_foreground:SetVisible(false)
        self.item_info_control:SetMouseVisible(false)
        self.item_info_control:SetVisible(false)
        self.item_info_control:SetItemInfo(nil)
        if self.item_info_control.SetQuantity ~= nil then
            self.item_info_control:SetQuantity(1)
        end
        return
    end

    local item_info = item:GetItemInfo()
    local background_image_id = nil
    local icon_id = nil
    if item_info ~= nil then
        if item_info.GetBackgroundImageID ~= nil then
            background_image_id = _sanitize_image_id(item_info:GetBackgroundImageID())
        end
        if background_image_id == nil and item_info.GetQualityImageID ~= nil then
            background_image_id = _sanitize_image_id(item_info:GetQualityImageID())
        end
        if item_info.GetIconImageID ~= nil then
            icon_id = _sanitize_image_id(item_info:GetIconImageID())
        end
    end

    self:SetMouseVisible(true)
    self.icon_host:SetMouseVisible(true)
    self.icon_background:set_icon(background_image_id, self._icon_side)
    self.icon_background:SetVisible(background_image_id ~= nil)
    self.icon_foreground:set_icon(icon_id, self._icon_side)
    self.icon_foreground:SetVisible(icon_id ~= nil)
    self.item_info_control:SetMouseVisible(true)
    self.item_info_control:SetVisible(true)
    self.item_info_control:SetItemInfo(item_info)
    if self.item_info_control.SetQuantity ~= nil then
        self.item_info_control:SetQuantity(1)
    end
    _set_stretch_mode_fit(self.icon_background)
    _set_stretch_mode_fit(self.icon_foreground)
    _set_stretch_mode_fit(self.item_info_control)
end
