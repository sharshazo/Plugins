-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- LuiItemIcon: layered item icon (icon + quality background image) with the
-- native game tooltip resurrected from a numeric game item id. A hidden
-- quickslot hosting an Item shortcut ("0x0,0x<id>") sits beneath the
-- mouse-transparent images: hover reaches it (tooltip), while its own
-- rendering (grayed for unowned items, native-size art) stays covered.
-- Left-click activation is swallowed so hovering an owned consumable can
-- never use it.

local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets.image"

local Widgets = _G.LUI.UI.Widgets

local LuiItemIcon = class(Turbine.UI.Control)
Widgets.LuiItemIcon = LuiItemIcon

local DEFAULT_SIDE = 32

-- even sides pair with even containers for exact pixel centering
local function _even_int(value)
    local out = math.floor(value + 0.5)
    if out % 2 ~= 0 then
        out = out - 1
    end
    if out < 0 then
        out = 0
    end
    return out
end

local function _set_stretch_mode_zero(control)
    if control ~= nil and control.SetStretchMode ~= nil then
        control:SetStretchMode(0)
    end
end

function LuiItemIcon:Constructor(on_click, on_hover_change)
    Turbine.UI.Control.Constructor(self)

    self._on_click = on_click
    self._on_hover_change = on_hover_change
    self._side = _even_int(DEFAULT_SIDE)
    self._quickslot_active = false

    self:SetMouseVisible(true)

    self.background = Widgets.Image()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    _set_stretch_mode_zero(self.background)

    self.foreground = Widgets.Image()
    self.foreground:SetParent(self)
    self.foreground:SetMouseVisible(false)
    _set_stretch_mode_zero(self.foreground)

    self.MouseEnter = function()
        if type(self._on_hover_change) == "function" then
            self._on_hover_change(true)
        end
    end
    self.MouseClick = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if type(self._on_click) == "function" then
            self._on_click()
        end
    end
    self.MouseUp = function()
        self:_rearm_quickslot()
    end
    self.MouseLeave = function()
        self:_rearm_quickslot()
        if type(self._on_hover_change) == "function" then
            self._on_hover_change(false)
        end
    end

    self:set_side(self._side)
    self:bind(nil, nil, nil)
end

-- re-enable the tooltip host after a click swallowed it (see MouseDown in
-- _ensure_quickslot); the quickslot is lazily created, nil until first bind
function LuiItemIcon:_rearm_quickslot()
    if self.quickslot ~= nil then
        self.quickslot:SetMouseVisible(self._quickslot_active == true)
    end
end

function LuiItemIcon:_ensure_quickslot()
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
    quickslot.MouseEnter = function()
        if type(self._on_hover_change) == "function" then
            self._on_hover_change(true)
        end
    end
    quickslot.MouseDown = function()
        -- swallow shortcut activation: drop mouse focus before MouseUp can
        -- execute the item shortcut (clicking an owned consumable must not
        -- use it); the parent icon's MouseUp/MouseLeave re-arm the tooltip
        quickslot:SetMouseVisible(false)
    end
    quickslot.MouseUp = function()
        self:_rearm_quickslot()
    end
    quickslot.MouseLeave = function()
        if type(self._on_hover_change) == "function" then
            self._on_hover_change(false)
        end
    end
    quickslot.MouseClick = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if type(self._on_click) == "function" then
            self._on_click()
        end
    end

    quickslot:SetPosition(0, 0)
    quickslot:SetSize(self._side, self._side)
    self.quickslot = quickslot
end

function LuiItemIcon:set_side(side)
    side = _even_int(side or DEFAULT_SIDE)
    self._side = side

    self:SetSize(side, side)
    self.background:SetPosition(0, 0)
    self.background:set_size(side, side)
    self.foreground:SetPosition(0, 0)
    self.foreground:set_size(side, side)
    if self.quickslot ~= nil then
        self.quickslot:SetPosition(0, 0)
        self.quickslot:SetSize(side, side)
    end
end

function LuiItemIcon:bind(icon_id, background_image_id, item_id)
    local has_visual = icon_id ~= nil or background_image_id ~= nil or item_id ~= nil
    local use_quickslot = item_id ~= nil
    self:SetVisible(has_visual)

    self.background:set_icon(background_image_id, self._side)
    self.background:SetVisible(background_image_id ~= nil)
    _set_stretch_mode_zero(self.background)

    self.foreground:set_icon(icon_id, self._side)
    self.foreground:SetVisible(icon_id ~= nil)
    _set_stretch_mode_zero(self.foreground)

    self._quickslot_active = use_quickslot
    if use_quickslot == true then
        self:_ensure_quickslot()
        -- external API: the client rejects ids it does not know locally
        -- (not fully patched / damaged game data), independent of our DB
        -- being correct; the icon then only loses its tooltip host
        local ok = pcall(function()
            self.quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(
                Turbine.UI.Lotro.ShortcutType.Item,
                string.format("0x0,0x%X", item_id)))
        end)
        if ok ~= true then
            self._quickslot_active = false
        end
    end
    if self.quickslot ~= nil then
        self.quickslot:SetVisible(self._quickslot_active == true)
        self.quickslot:SetMouseVisible(self._quickslot_active == true)
    end
end

function LuiItemIcon:destroy()
    self:bind(nil, nil, nil)
    self:SetVisible(false)
end

function LuiItemIcon:prepare_for_list_clear()
    self:bind(nil, nil, nil)
    self:SetVisible(false)
end
