-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local TR = _G.LUI.Locale.TR
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local UI = _G.LUI.UI
local Crafting = _G.LUI.Features.Crafting
local Stores = _G.LUI.Runtime.Stores
local Shortcuts = _G.LUI.UI.Shortcuts
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"

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

local S = _G.LUI.Features.StatusBar.Common
local Style = UI.Widgets.Style

local CHIP_GAP = 0
local CHIP_ICON_GAP = 2
local CHIP_PAD_X = 3
local CHIP_ICON_MARGIN = 2
local READY_TEXT = Turbine.UI.Color(1.00, 0.55, 0.92, 0.55)
local MISSING_TEXT = Turbine.UI.Color(1.00, 0.88, 0.35, 0.35)
local LOADING_TRACK_BACK = Turbine.UI.Color(0.35, 0.10, 0.12, 0.16)
local LOADING_FILL_BACK = Turbine.UI.Color(0.65, 0.38, 0.54, 0.78)
local POPUP_ROW_GAP = 2
local POPUP_SECTION_GAP = 4

local function _set_stretch_mode_fit(control)
    if control ~= nil and control.SetStretchMode ~= nil then
        control:SetStretchMode(1)
        _attach_fixed_edges(control)
    end
end

local function _apply_font(label, font, color, alignment)
    if label == nil then
        return
    end
    label:SetMouseVisible(false)
    label:SetTextAlignment(alignment or Turbine.UI.ContentAlignment.MiddleLeft)
    if font ~= nil then
        if font.lotro ~= nil then
            label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.outline_color ~= nil then
            label:SetOutlineColor(font.outline_color)
        end
    end
    label:SetForeColor(color or (font ~= nil and font.color) or Style.ALTERNATE_FOREGROUND)
end

local function _rough_text_width(text, bar_h)
    local count = string.len(tostring(text or ""))
    return math.max(math.floor(bar_h * 1.6), math.floor(count * math.max(6, bar_h * 0.34)))
end

local function _resource_state_signature(state)
    if type(state) ~= "table" then
        return ""
    end

    local parts = {
        tostring(state.saved_entry_count or 0),
        tostring(state.unresolved_count or 0),
        tostring(state.ready == true),
        tostring(state.loading == true),
        tostring(state.loading_loaded or 0),
        tostring(state.loading_total or 0),
    }

    local resources = state.resources or {}
    for i = 1, #resources do
        local entry = resources[i]
        parts[#parts + 1] = table.concat({
            tostring(entry.key or ""),
            tostring(entry.owned or 0),
            tostring(entry.required or 0),
            tostring(entry.missing or 0),
        }, "\31")
    end

    return table.concat(parts, "\30")
end

local CraftPlanItemSlot = class(Turbine.UI.Control)

function CraftPlanItemSlot:Constructor(forward_target)
    Turbine.UI.Control.Constructor(self)

    self._forward_target = forward_target
    self._interaction_enabled = true

    self.background = UI.Widgets.Image()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    self.background:SetZOrder(1)
    if self.background.SetBlendMode ~= nil then
        self.background:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
    _set_stretch_mode_fit(self.background)

    self.foreground = UI.Widgets.Image()
    self.foreground:SetParent(self)
    self.foreground:SetMouseVisible(false)
    self.foreground:SetZOrder(2)
    if self.foreground.SetBlendMode ~= nil then
        self.foreground:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
    _set_stretch_mode_fit(self.foreground)

    self.quickslot = nil
    self._quickslot_active = false
    self._item_id = nil
    -- pre-layout size: a chip's first bind_resource can create the quickslot
    -- before the first set_side (store already loaded when the chip is built)
    self._side = 0

    local function _forward(name, args)
        local target = self._forward_target
        local handler = target ~= nil and target[name] or nil
        if type(handler) == "function" then
            handler(target, args)
        end
    end

    self._forward = _forward
    local function _set_icon_hover(hovering)
        local target = self._forward_target
        local handler = target ~= nil and target._on_icon_hover_changed or nil
        if type(handler) == "function" then
            handler(target, hovering == true)
        end
    end

    self._set_icon_hover = _set_icon_hover
    self.MouseEnter = function()
        _set_icon_hover(true)
    end
    self.MouseLeave = function()
        _set_icon_hover(false)
    end
    self.MouseUp = function(_, args)
        if self.quickslot ~= nil then
            self.quickslot:SetMouseVisible(self._quickslot_active == true)
        end
        _forward("MouseUp", args)
    end
end

-- native tooltip host from the lore-DB item id: a hidden quickslot beneath
-- the mouse-transparent images (same pattern as UI.Widgets.LuiItemIcon);
-- left-click activation is swallowed on MouseDown
function CraftPlanItemSlot:_ensure_quickslot()
    if self.quickslot ~= nil then
        return
    end

    local quickslot = Turbine.UI.Lotro.Quickslot()
    quickslot:SetParent(self)
    quickslot:SetZOrder(-1)
    quickslot:SetVisible(false)
    quickslot:SetMouseVisible(false)
    if quickslot.SetAllowDrop ~= nil then
        quickslot:SetAllowDrop(false)
    end
    quickslot:SetPosition(0, 0)
    quickslot:SetSize(self._side, self._side)
    quickslot.MouseEnter = function()
        self._set_icon_hover(true)
    end
    quickslot.MouseLeave = function()
        self._set_icon_hover(false)
    end
    quickslot.MouseDown = function(_, args)
        self._forward("MouseDown", args)
        quickslot:SetMouseVisible(false)
    end
    quickslot.MouseUp = function(_, args)
        quickslot:SetMouseVisible(self._quickslot_active == true)
        self._forward("MouseUp", args)
    end
    quickslot.MouseMove = function(_, args)
        self._forward("MouseMove", args)
    end
    quickslot.MouseClick = function(_, args)
        self._forward("MouseClick", args)
    end
    self.quickslot = quickslot
end

function CraftPlanItemSlot:set_interaction_enabled(enabled)
    self._interaction_enabled = enabled == true
    self:_refresh_item_binding()
end

function CraftPlanItemSlot:set_side(side)
    self._side = math.max(0, math.floor((tonumber(side) or 0) + 0.5))
    self:SetSize(self._side, self._side)
    self.background:SetPosition(0, 0)
    self.background:set_size(self._side, self._side)
    self.foreground:SetPosition(0, 0)
    self.foreground:set_size(self._side, self._side)
    if self.quickslot ~= nil then
        self.quickslot:SetPosition(0, 0)
        self.quickslot:SetSize(self._side, self._side)
    end
end

function CraftPlanItemSlot:bind_item(icon_id, background_image_id, item_id)
    self._icon_id = icon_id
    self._background_image_id = background_image_id
    self._item_id = item_id
    self:_refresh_item_binding()
end

function CraftPlanItemSlot:_refresh_item_binding()
    self.background:set_icon(self._background_image_id, self._side)
    self.background:SetVisible(self._background_image_id ~= nil)
    self.foreground:set_icon(self._icon_id, self._side)
    self.foreground:SetVisible(self._icon_id ~= nil)
    _set_stretch_mode_fit(self.background)
    _set_stretch_mode_fit(self.foreground)

    local use_quickslot = self._item_id ~= nil and self._interaction_enabled == true
    self._quickslot_active = use_quickslot
    if use_quickslot == true then
        self:_ensure_quickslot()
        self.quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(
            Turbine.UI.Lotro.ShortcutType.Item,
            string.format("0x0,0x%X", self._item_id)))
    end
    if self.quickslot ~= nil then
        self.quickslot:SetVisible(use_quickslot == true)
        self.quickslot:SetMouseVisible(use_quickslot == true)
    end
end

function CraftPlanItemSlot:destroy()
    self:bind_item(nil, nil, nil)
    self:SetVisible(false)
    self:SetParent(nil)
end

local CraftPlanChip = class(Turbine.UI.Control)

function CraftPlanChip:Constructor(owner, font)
    Turbine.UI.Control.Constructor(self)

    self._owner = owner
    self._font = font
    self._resource = nil
    self._hover = false
    self._interaction_enabled = true
    self._show_popup = false
    self._display_text = ""
    self._icon_hover = false

    self:SetMouseVisible(true)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(true)
    self.background:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.background:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.background:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self.background:SetVisible(true)

    self.slot = CraftPlanItemSlot(self)
    self.slot:SetParent(self)

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self)
    _apply_font(self.label, font, Style.ALTERNATE_FOREGROUND, Turbine.UI.ContentAlignment.MiddleLeft)
    self.label:SetMouseVisible(true)

    local function _owner_mouse(name, args)
        local owner = self._owner
        local handler = owner ~= nil and owner[name] or nil
        if type(handler) == "function" then
            handler(owner, args)
        end
    end

    local function _enter_non_icon()
        self._hover = true
        self:_refresh_visual()
        if self._owner ~= nil and self._owner._set_hovered ~= nil then
            self._owner:_set_hovered(true)
        end
        if self._owner ~= nil and self._owner._show_popup_if_needed ~= nil then
            self._owner:_show_popup_if_needed()
        elseif self._show_popup == true and self._owner ~= nil and self._owner._show_popup ~= nil then
            self._owner:_show_popup()
        end
    end

    local function _leave_non_icon()
        self._hover = false
        self:_refresh_visual()
    end

    self.background.MouseEnter = function()
        _enter_non_icon()
    end
    self.background.MouseLeave = function()
        _leave_non_icon()
    end
    self.background.MouseClick = function(_, args)
        _owner_mouse("MouseClick", args)
    end
    self.background.MouseDown = function(_, args)
        _owner_mouse("MouseDown", args)
    end
    self.background.MouseMove = function(_, args)
        _owner_mouse("MouseMove", args)
    end
    self.background.MouseUp = function(_, args)
        _owner_mouse("MouseUp", args)
    end

    self.label.MouseEnter = function()
        _enter_non_icon()
    end
    self.label.MouseLeave = function()
        _leave_non_icon()
    end
    self.label.MouseClick = function(_, args)
        _owner_mouse("MouseClick", args)
    end
    self.label.MouseDown = function(_, args)
        _owner_mouse("MouseDown", args)
    end
    self.label.MouseMove = function(_, args)
        _owner_mouse("MouseMove", args)
    end
    self.label.MouseUp = function(_, args)
        _owner_mouse("MouseUp", args)
    end

    self.MouseEnter = function()
        self._hover = true
        self:_refresh_visual()
        if self._owner ~= nil and self._owner._set_hovered ~= nil then
            self._owner:_set_hovered(true)
        end
    end
    self.MouseLeave = function()
        self._hover = false
        self:_refresh_visual()
    end
    self.MouseClick = function(_, args)
        local owner = self._owner
        local handler = owner ~= nil and owner.MouseClick or nil
        if type(handler) == "function" then
            handler(owner, args)
        end
    end
    self.MouseDown = function(_, args)
        local owner = self._owner
        local handler = owner ~= nil and owner.MouseDown or nil
        if type(handler) == "function" then
            handler(owner, args)
        end
    end
    self.MouseMove = function(_, args)
        local owner = self._owner
        local handler = owner ~= nil and owner.MouseMove or nil
        if type(handler) == "function" then
            handler(owner, args)
        end
    end
    self.MouseUp = function(_, args)
        local owner = self._owner
        local handler = owner ~= nil and owner.MouseUp or nil
        if type(handler) == "function" then
            handler(owner, args)
        end
    end
end

function CraftPlanChip:_on_icon_hover_changed(hovering)
    self._icon_hover = hovering == true
    if self._owner ~= nil and self._owner._set_icon_hovered ~= nil then
        self._owner:_set_icon_hovered(self._icon_hover)
    end
end

function CraftPlanChip:set_font(font)
    self._font = font
    _apply_font(self.label, font, self.label:GetForeColor(), Turbine.UI.ContentAlignment.MiddleLeft)
end

function CraftPlanChip:set_interaction_enabled(enabled)
    self._interaction_enabled = enabled == true
    self.slot:set_interaction_enabled(self._interaction_enabled)
end

function CraftPlanChip:bind_resource(resource)
    self._resource = resource
    self._show_popup = false
    self._display_text = type(resource) == "table" and (tostring(resource.owned or 0) .. "/" .. tostring(resource.required or 0)) or ""
    self.label:SetText(self._display_text)
    self.label:SetForeColor(type(resource) == "table" and resource.complete == true and READY_TEXT or MISSING_TEXT)
    self.slot:bind_item(
        resource ~= nil and resource.icon_id or nil,
        resource ~= nil and resource.background_image_id or nil,
        resource ~= nil and resource.item_id or nil
    )
    self:_layout()
    self:_refresh_visual()
end

function CraftPlanChip:bind_text(text, color, show_popup)
    self._resource = nil
    self._show_popup = show_popup == true
    self._display_text = tostring(text or "")
    self.label:SetText(self._display_text)
    self.label:SetForeColor(color or Style.ALTERNATE_FOREGROUND)
    self.slot:bind_item(nil, nil, nil)
    self:_layout()
    self:_refresh_visual()
end

function CraftPlanChip:get_preferred_width(bar_h)
    local has_icon = self._resource ~= nil
    local icon_w = has_icon == true and S.get_icon_size(bar_h) or 0
    return (has_icon == true and (CHIP_ICON_MARGIN + icon_w + CHIP_ICON_GAP) or 0) + _rough_text_width(self._display_text, bar_h) + (CHIP_PAD_X * 2)
end

function CraftPlanChip:set_bounds(width, height)
    self:SetSize(width, height)
    self:_layout()
end

function CraftPlanChip:_refresh_visual()
    self.background:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self.background:SetVisible(false)
end

function CraftPlanChip:_layout()
    local w, h = self:GetSize()
    self.background:SetPosition(0, 0)
    self.background:SetSize(w, h)

    local icon_side = S.get_icon_size(h)
    local icon_y = S.get_centered_icon_y(h, icon_side)
    local has_icon = self._resource ~= nil
    if has_icon == true then
        self.slot:SetVisible(true)
        self.slot:set_side(icon_side)
        self.slot:SetPosition(CHIP_ICON_MARGIN, icon_y)
        self.label:SetPosition(CHIP_ICON_MARGIN + icon_side + CHIP_ICON_GAP, 0)
        self.label:SetSize(math.max(0, w - CHIP_ICON_MARGIN - icon_side - CHIP_ICON_GAP - CHIP_PAD_X), h)
    else
        self.slot:SetVisible(false)
        self.label:SetPosition(CHIP_PAD_X, 0)
        self.label:SetSize(math.max(0, w - (CHIP_PAD_X * 2)), h)
    end
end

function CraftPlanChip:destroy()
    if self.slot ~= nil then
        self.slot:destroy()
    end
    if self.label ~= nil then
        self.label:SetVisible(false)
        self.label:SetParent(nil)
    end
    if self.background ~= nil then
        self.background:SetVisible(false)
        self.background:SetParent(nil)
    end
    self:SetVisible(false)
    self:SetParent(nil)
end

local CraftPlanPopupRow = class(Turbine.UI.Control)

function CraftPlanPopupRow:Constructor(font)
    Turbine.UI.Control.Constructor(self)

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    self.background:SetBackColor(Style.ALTERNATE_BACKGROUND)

    self.slot = CraftPlanItemSlot(self)
    self.slot:SetParent(self)
    self.slot:set_interaction_enabled(true)

    self.name = UI.Widgets.LuiLabel()
    self.name:SetParent(self)
    _apply_font(self.name, font, Style.ALTERNATE_FOREGROUND, Turbine.UI.ContentAlignment.MiddleLeft)

    self.amount = UI.Widgets.LuiLabel()
    self.amount:SetParent(self)
    _apply_font(self.amount, font, Style.ALTERNATE_FOREGROUND, Turbine.UI.ContentAlignment.MiddleRight)
end

function CraftPlanPopupRow:set_font(font)
    _apply_font(self.name, font, self.name:GetForeColor(), Turbine.UI.ContentAlignment.MiddleLeft)
    _apply_font(self.amount, font, self.amount:GetForeColor(), Turbine.UI.ContentAlignment.MiddleRight)
end

function CraftPlanPopupRow:set_data(resource, width, height)
    self:SetSize(width, height)
    self.background:SetPosition(0, 0)
    self.background:SetSize(width, height)
    local icon_w = S.get_icon_size(height)
    local icon_y = S.get_centered_icon_y(height, icon_w)
    self.slot:set_side(icon_w)
    self.slot:SetPosition(CHIP_ICON_MARGIN, icon_y)
    self.slot:bind_item(
        resource ~= nil and resource.icon_id or nil,
        resource ~= nil and resource.background_image_id or nil,
        resource ~= nil and resource.item_id or nil
    )
    self.name:SetText(resource ~= nil and resource.name or "")
    self.amount:SetText(tostring(resource ~= nil and resource.owned or 0) .. "/" .. tostring(resource ~= nil and resource.required or 0))
    self.amount:SetForeColor(resource ~= nil and resource.complete == true and READY_TEXT or MISSING_TEXT)
    self.name:SetPosition(CHIP_ICON_MARGIN + icon_w + CHIP_ICON_GAP + CHIP_PAD_X, 0)
    self.name:SetSize(math.max(0, width - CHIP_ICON_MARGIN - icon_w - _rough_text_width(self.amount:GetText(), height) - _rough_text_width(" ", height) - (CHIP_PAD_X * 4) - CHIP_ICON_GAP), height)
    self.amount:SetPosition(width - _rough_text_width(self.amount:GetText(), height) - CHIP_PAD_X, 0)
    self.amount:SetSize(_rough_text_width(self.amount:GetText(), height), height)
end

function CraftPlanPopupRow:destroy()
    if self.slot ~= nil then
        self.slot:destroy()
    end
    if self.name ~= nil then self.name:SetParent(nil) end
    if self.amount ~= nil then self.amount:SetParent(nil) end
    if self.background ~= nil then self.background:SetParent(nil) end
    self:SetVisible(false)
    self:SetParent(nil)
end

local CraftPlanWidget = class(Turbine.UI.Control)
StatusBarWidgets.CraftPlanWidget = CraftPlanWidget

function CraftPlanWidget:Constructor(widget_w, bar_h, font, max_visible)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "craft_plan"
    self.font = font
    self._max_visible = math.max(1, tonumber(max_visible))
    self._interaction_enabled = true
    self._chips = {}
    self._popup_rows = {}
    self._state_signature = nil
    self._resource_state = nil
    self._hovering = false
    self._icon_hovered = false

    self:SetSize(widget_w, bar_h)
    self:SetMouseVisible(true)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)

    self.loading_track = Turbine.UI.Control()
    self.loading_track:SetParent(self)
    self.loading_track:SetMouseVisible(false)
    self.loading_track:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.loading_track:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.loading_track:SetBackColor(LOADING_TRACK_BACK)
    self.loading_track:SetVisible(false)

    self.loading_fill = Turbine.UI.Control()
    self.loading_fill:SetParent(self)
    self.loading_fill:SetMouseVisible(false)
    self.loading_fill:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.loading_fill:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.loading_fill:SetBackColor(LOADING_FILL_BACK)
    self.loading_fill:SetVisible(false)

    self.popup = UI.Widgets.LuiTooltip()
    self.popup:SetZOrder(2200)

    self.popup_inner = Turbine.UI.Control()
    self.popup_inner:SetParent(self.popup:GetContentHost())
    self.popup_inner:SetMouseVisible(false)

    self.popup_header = UI.Widgets.LuiLabel()
    self.popup_header:SetParent(self.popup_inner)
    _apply_font(self.popup_header, self.font, Style.ALTERNATE_FOREGROUND, Turbine.UI.ContentAlignment.MiddleLeft)
    self.popup_header:SetVisible(false)

    self.popup_note = UI.Widgets.LuiLabel()
    self.popup_note:SetParent(self.popup_inner)
    _apply_font(self.popup_note, self.font, Style.ALTERNATE_FOREGROUND, Turbine.UI.ContentAlignment.MiddleLeft)
    self.popup_note:SetVisible(false)

    self.MouseClick = function(_, args)
        if args ~= nil and args.Button == Turbine.UI.MouseButton.Left and self._interaction_enabled == true then
            Shortcuts.open_crafting_plan()
        end
    end

    self.MouseEnter = function()
        self:_set_hovered(true)
        self:_show_popup_if_needed()
    end

    self.MouseLeave = function()
        self:_set_hovered(false)
        self:_hide_popup()
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self:_layout()
    self:_refresh_from_state(nil)
end

function CraftPlanWidget:set_interaction_enabled(enabled)
    self._interaction_enabled = enabled == true
    for i = 1, #self._chips do
        self._chips[i]:set_interaction_enabled(self._interaction_enabled)
    end
    if self._interaction_enabled ~= true then
        self:_hide_popup()
    end
end

function CraftPlanWidget:update(_)
    local state = Crafting.get_tracked_plan_resource_state(Stores.crafting)
    local signature = _resource_state_signature(state)
    if signature ~= self._state_signature then
        self._state_signature = signature
        self:_refresh_from_state(state)
    end
end

function CraftPlanWidget:destroy()
    self:_hide_popup()
    if self.popup ~= nil then
        self.popup:Hide()
    end
    if self.popup_inner ~= nil then
        self.popup_inner:SetParent(nil)
    end
    if self.popup_header ~= nil then
        self.popup_header:SetParent(nil)
    end
    if self.popup_note ~= nil then
        self.popup_note:SetParent(nil)
    end
    if self.loading_fill ~= nil then
        self.loading_fill:SetParent(nil)
    end
    if self.loading_track ~= nil then
        self.loading_track:SetParent(nil)
    end
    for i = 1, #self._chips do
        self._chips[i]:destroy()
    end
    for i = 1, #self._popup_rows do
        self._popup_rows[i]:destroy()
    end
    self._chips = {}
    self._popup_rows = {}
    self:SetVisible(false)
    self:SetParent(nil)
end

function CraftPlanWidget:_ensure_chip_count(count)
    while #self._chips < count do
        local chip = CraftPlanChip(self, self.font)
        chip:SetParent(self)
        chip:set_interaction_enabled(self._interaction_enabled)
        self._chips[#self._chips + 1] = chip
    end
    for i = 1, #self._chips do
        self._chips[i]:SetVisible(i <= count)
    end
end

function CraftPlanWidget:_ensure_popup_row_count(count)
    while #self._popup_rows < count do
        local row = CraftPlanPopupRow(self.font)
        row:SetParent(self.popup_inner)
        self._popup_rows[#self._popup_rows + 1] = row
    end
    for i = 1, #self._popup_rows do
        self._popup_rows[i]:SetVisible(i <= count)
    end
end

function CraftPlanWidget:_refresh_from_state(state)
    self._resource_state = state
    self:_hide_popup()

    local visible_specs = {}
    local incomplete = type(state) == "table" and state.incomplete_resources or {}
    local resources = type(state) == "table" and state.resources or {}

    if type(state) ~= "table" or (state.saved_entry_count or 0) <= 0 then
        -- No tracked plan: keep the widget blank instead of showing placeholder text.
    elseif state.ready == true then
        visible_specs[1] = { text = TR["Ready"], color = READY_TEXT, popup = true }
    else
        local visible_count = math.min(#incomplete, self._max_visible)
        for i = 1, visible_count do
            visible_specs[#visible_specs + 1] = { resource = incomplete[i] }
        end
        local has_hidden_details = (#resources > self._max_visible) or (state.unresolved_count or 0) > 0 or state.loading == true
        if #visible_specs == 0 and state.loading == true then
            visible_specs[1] = { text = TR["Loading"] .. "...", color = Style.ALTERNATE_FOREGROUND, popup = true }
        elseif has_hidden_details == true then
            visible_specs[#visible_specs + 1] = { text = "[...]", color = Style.ALTERNATE_FOREGROUND, popup = true }
        end
        if #visible_specs == 0 then
            visible_specs[1] = { text = "[...]", color = Style.ALTERNATE_FOREGROUND, popup = true }
        end
    end

    self:_ensure_chip_count(#visible_specs)
    for i = 1, #visible_specs do
        local chip = self._chips[i]
        local spec = visible_specs[i]
        if spec.resource ~= nil then
            chip:bind_resource(spec.resource)
        else
            chip:bind_text(spec.text, spec.color, spec.popup == true)
        end
    end

    self:_layout()
    if self._hovering == true then
        self:_show_popup_if_needed()
    end
end

function CraftPlanWidget:_set_hovered(hovering)
    self._hovering = hovering == true
end

function CraftPlanWidget:_set_icon_hovered(hovering)
    self._icon_hovered = hovering == true
    if self._icon_hovered == true then
        self:_hide_popup()
    elseif self._hovering == true then
        self:_show_popup_if_needed()
    end
end

function CraftPlanWidget:_should_show_popup()
    local state = self._resource_state
    if type(state) ~= "table" or (state.saved_entry_count or 0) <= 0 then
        return false
    end

    local resources = state.resources or {}
    if state.ready == true then
        return #resources > 0
    end

    if state.loading == true or (state.unresolved_count or 0) > 0 then
        return true
    end

    if #resources > self._max_visible then
        return true
    end

    return false
end

function CraftPlanWidget:_show_popup_if_needed()
    if self._icon_hovered == true then
        return
    end
    if self:_should_show_popup() == true then
        self:_show_popup()
    end
end

function CraftPlanWidget:_refresh_loading_background()
    local w, h = self:GetSize()
    local state = self._resource_state
    local loading = type(state) == "table" and state.loading == true

    self.loading_track:SetPosition(0, 0)
    self.loading_track:SetSize(w, h)
    self.loading_track:SetVisible(loading == true and w > 0 and h > 0)

    local fill_w = 0
    if loading == true and w > 0 and h > 0 then
        local loaded = tonumber(state.loading_loaded) or 0
        local total = tonumber(state.loading_total) or 0
        if total > 0 then
            fill_w = math.floor((w * loaded) / total)
            if fill_w < 0 then
                fill_w = 0
            elseif fill_w > w then
                fill_w = w
            end
        end
    end

    self.loading_fill:SetPosition(0, 0)
    self.loading_fill:SetSize(fill_w, h)
    self.loading_fill:SetVisible(loading == true and fill_w > 0 and h > 0)
end

function CraftPlanWidget:_layout()
    local w, h = self:GetSize()
    local visible = {}

    self:_refresh_loading_background()

    for i = 1, #self._chips do
        local chip = self._chips[i]
        if chip:IsVisible() == true then
            visible[#visible + 1] = {
                chip = chip,
                preferred_w = chip:get_preferred_width(h),
            }
        end
    end

    local function total_width()
        local total = 0
        for i = 1, #visible do
            total = total + visible[i].preferred_w
            if i > 1 then
                total = total + CHIP_GAP
            end
        end
        return total
    end

    if #visible > 1 then
        local last = visible[#visible]
        if last ~= nil and last.chip ~= nil and last.chip._show_popup == true then
            local remove_index = #visible - 1
            while remove_index >= 1 and total_width() > w do
                visible[remove_index].chip:SetVisible(false)
                table.remove(visible, remove_index)
                remove_index = remove_index - 1
            end
        end
    end

    for i = 1, #self._chips do
        self._chips[i]:SetVisible(false)
    end

    local x = 0
    for i = 1, #visible do
        local chip = visible[i].chip
        if i > 1 then
            x = x + CHIP_GAP
        end
        local chip_w = math.max(0, math.min(visible[i].preferred_w, w - x))
        chip:SetVisible(chip_w > 0)
        chip:SetPosition(x, 0)
        chip:set_bounds(chip_w, h)
        x = x + chip_w
    end
end

function CraftPlanWidget:_show_popup()
    if self._interaction_enabled ~= true or self.popup == nil or self.popup_inner == nil then
        return
    end

    local state = self._resource_state
    local resources = type(state) == "table" and state.resources or nil
    local has_resources = type(resources) == "table" and #resources > 0
    local header_text = nil
    local note_text = nil

    if type(state) == "table" and state.loading == true then
        header_text = TR["Loading recipes"] .. " " .. tostring(state.loading_loaded or 0) .. " / " .. tostring(state.loading_total or 0)
    end

    if type(state) == "table" and (state.unresolved_count or 0) > 0 then
        local unresolved = tonumber(state.unresolved_count) or 0
        local total = tonumber(state.total_entry_count) or tonumber(state.saved_entry_count) or unresolved
        if state.loading == true then
            note_text = tostring(unresolved) .. "/" .. tostring(total) .. " " .. TR["planned recipes still unresolved"]
        else
            note_text = tostring(unresolved) .. "/" .. tostring(total) .. " " .. TR["planned recipes unresolved"]
        end
    end

    if has_resources ~= true and header_text == nil and note_text == nil then
        return
    end

    local width = math.max(220, math.min(420, self:GetWidth() + 140))
    local row_h = math.max(20, self:GetHeight())
    local border = math.max(0, math.floor((tonumber(Style.BORDER_WIDTH_THIN) or 1) + 0.5))
    local inner_w = width - (border * 2)
    local header_h = header_text ~= nil and row_h or 0
    local note_h = note_text ~= nil and row_h or 0
    local rows_h = has_resources == true and ((#resources * row_h) + math.max(0, (#resources - 1) * POPUP_ROW_GAP)) or 0
    local inner_h = header_h + note_h + rows_h
    if header_h > 0 and (note_h > 0 or rows_h > 0) then
        inner_h = inner_h + POPUP_SECTION_GAP
    end
    if note_h > 0 and rows_h > 0 then
        inner_h = inner_h + POPUP_SECTION_GAP
    end

    self.popup:ShowContentFor(self, width, inner_h + (border * 2))
    self.popup_inner:SetPosition(0, 0)
    self.popup_inner:SetSize(inner_w, inner_h)

    local y = 0
    self.popup_header:SetVisible(header_h > 0)
    if header_h > 0 then
        self.popup_header:SetText(header_text)
        self.popup_header:SetPosition(CHIP_PAD_X, y)
        self.popup_header:SetSize(math.max(0, inner_w - (CHIP_PAD_X * 2)), row_h)
        y = y + row_h
        if note_h > 0 or rows_h > 0 then
            y = y + POPUP_SECTION_GAP
        end
    end

    self.popup_note:SetVisible(note_h > 0)
    if note_h > 0 then
        self.popup_note:SetText(note_text)
        self.popup_note:SetPosition(CHIP_PAD_X, y)
        self.popup_note:SetSize(math.max(0, inner_w - (CHIP_PAD_X * 2)), row_h)
        y = y + row_h
        if rows_h > 0 then
            y = y + POPUP_SECTION_GAP
        end
    end

    self:_ensure_popup_row_count(has_resources == true and #resources or 0)
    if has_resources == true then
        for i = 1, #resources do
            local row = self._popup_rows[i]
            row:SetPosition(0, y)
            row:set_data(resources[i], inner_w, row_h)
            y = y + row_h + POPUP_ROW_GAP
        end
    end
end

function CraftPlanWidget:_hide_popup()
    if self.popup ~= nil then
        self.popup:Hide()
    end
    if self.popup_header ~= nil then
        self.popup_header:SetVisible(false)
    end
    if self.popup_note ~= nil then
        self.popup_note:SetVisible(false)
    end
end
