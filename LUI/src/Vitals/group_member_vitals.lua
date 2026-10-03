-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Utils.callbacks"
local TR = _G.LUI.Locale.TR
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local get_class_icon = _G.LUI.Utils.get_class_icon
local get_party_leader_icon = _G.LUI.Utils.get_party_leader_icon
local Vitals = _G.LUI.Features.Vitals
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Vitals.vitals_base"
import "LUI.src.Vitals.target_effect_manager"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"
import "LUI.src.Vitals.group_highlight"

local DEAD_STATE_COLOR = Turbine.UI.Color(0.78, 0.20, 0.02, 0.02)
local OFFLINE_STATE_COLOR = Turbine.UI.Color(0.78, 0.03, 0.03, 0.03)
local STATE_TEXT_COLOR = Turbine.UI.Color(1, 1, 1, 1)
local STATE_OUTLINE_COLOR = Turbine.UI.Color(1, 0, 0, 0)
-- seleccion notoria: linea oscura por dentro del borde (contraste sobre
-- cualquier color de barra), borde blanco fino al pasar el mouse y aviso
-- rojo de vida baja (su latido lo anima Vitals.GroupHighlight)
local SELECT_INNER_COLOR = Turbine.UI.Color(0.90, 0, 0, 0)
local HOVER_COLOR = Turbine.UI.Color(0.85, 1, 1, 1)
local LOW_HEALTH_R, LOW_HEALTH_G, LOW_HEALTH_B = 1.00, 0.10, 0.06
local LOW_HEALTH_BORDER = 2
local DEFAULT_SELECT_COLOR = Turbine.UI.Color(1, 1.00, 0.82, 0.25)

local function _highlight()
    return Vitals.GroupHighlight
end

local function _new_border(parent, z_order, alpha_blend)
    local border = {
        top = Turbine.UI.Control(),
        bottom = Turbine.UI.Control(),
        left = Turbine.UI.Control(),
        right = Turbine.UI.Control(),
    }
    for _, piece in pairs(border) do
        piece:SetParent(parent)
        piece:SetMouseVisible(false)
        piece:SetZOrder(z_order)
        if alpha_blend == true then
            piece:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
            piece:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        end
        piece:SetVisible(false)
    end
    return border
end

local function _set_select_border_visible(border, visible)
    border.top:SetVisible(visible)
    border.bottom:SetVisible(visible)
    border.left:SetVisible(visible)
    border.right:SetVisible(visible)
end

local function _set_select_border_color(border, color)
    border.top:SetBackColor(color)
    border.bottom:SetBackColor(color)
    border.left:SetBackColor(color)
    border.right:SetBackColor(color)
end

local function _apply_select_border(border, x, y, width, height, thickness, color)
    if thickness <= 0 or width <= 0 or height <= 0 then
        _set_select_border_visible(border, false)
        return
    end

    _set_select_border_color(border, color)

    border.top:SetPosition(x, y)
    border.top:SetSize(width, thickness)
    border.top:SetVisible(true)

    border.bottom:SetPosition(x, y + height - thickness)
    border.bottom:SetSize(width, thickness)
    border.bottom:SetVisible(true)

    border.left:SetPosition(x, y)
    border.left:SetSize(thickness, height)
    border.left:SetVisible(true)

    border.right:SetPosition(x + width - thickness, y)
    border.right:SetSize(thickness, height)
    border.right:SetVisible(true)
end

---@class GroupMemberVitals : VitalsBase
local GroupMemberVitals = class(Vitals.VitalsBase)
Vitals.GroupMemberVitals = GroupMemberVitals

function GroupMemberVitals:Constructor(settings_root, entity)
    self.settings_root = settings_root
    self.is_leader = false
    self.target_highlighted = false
    self.link_dead_event = nil
    self.em = nil
    self.em_added_event = nil

    Vitals.VitalsBase.Constructor(self, settings_root, entity, "Group Member", {
        hud_key = settings_root .. "_vitals",
        show_effects = false,
        move_ui = false,
        managed_position = true,
    })
end

function GroupMemberVitals:set_is_leader(is_leader)
    self.is_leader = is_leader == true
    self:_update_leader_icon()
end

function GroupMemberVitals:set_entity(entity)
    local entity_changed = self.entity ~= entity
    if entity_changed == true then
        self:_detach_silent_effect_manager()
        self:_detach_link_dead_event()
        self.target_highlighted = false
        self.hovered = false
    end

    Vitals.VitalsBase.set_entity(self, entity)
    self:_attach_link_dead_event()
    self:_update_class_icon()
    self:_update_leader_icon()
    self:_setup_silent_effect_manager()
    self:_update_member_state()
    self:_apply_target_highlight()
end

function GroupMemberVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end
end

function GroupMemberVitals:get_lower_bars_height()
    return self:get_vitals_settings().power.height
end

function GroupMemberVitals:set_target_highlighted(highlighted)
    self.target_highlighted = highlighted == true
    self:_apply_target_highlight()
end

function GroupMemberVitals:set_target_name(target_name)
    if target_name == nil or self.entity == nil or self.entity.GetName == nil then
        self:set_target_highlighted(false)
        return
    end

    self:set_target_highlighted(self.entity:GetName() == target_name)
end

function GroupMemberVitals:self_morale_changed()
    Vitals.VitalsBase.self_morale_changed(self)
    self:_update_member_state()
end

function GroupMemberVitals:_is_local_player(entity)
    local local_player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if entity == nil or local_player == nil then
        return false
    end
    if entity.GetName == nil or local_player.GetName == nil then
        return false
    end

    return entity:GetName() == local_player:GetName()
end

function GroupMemberVitals:_entity_is_link_dead()
    if self.entity == nil or self.entity.IsLinkDead == nil then
        return false
    end

    return self.entity:IsLinkDead() == true
end

function GroupMemberVitals:_entity_is_dead()
    if self.entity == nil or self.entity.GetMorale == nil then
        return false
    end

    local morale = self.entity:GetMorale()
    return type(morale) == "number" and morale <= 0
end

function GroupMemberVitals:_attach_link_dead_event()
    if self.link_dead_event ~= nil then
        return
    end
    if self.entity == nil or self.entity.IsLinkDead == nil then
        return
    end

    self.link_dead_event = add_callback(self.entity, "IsLinkDeadChanged", function()
        self:_update_member_state()
    end)
end

function GroupMemberVitals:_detach_link_dead_event()
    if self.link_dead_event == nil then
        return
    end

    remove_callback(self.entity, "IsLinkDeadChanged", self.link_dead_event)
    self.link_dead_event = nil
end

function GroupMemberVitals:_set_member_state(text, color)
    local x, y = self.entity_control:GetPosition()
    local width, height = self.entity_control:GetSize()

    self.state_overlay:SetPosition(x, y)
    self.state_overlay:SetSize(width, height)
    self.state_overlay:SetBackColor(color)
    self.state_label:SetSize(width, height)
    self.state_label:SetText(text)
    self.state_overlay:SetVisible(true)
    self.state_label:SetVisible(true)
end

function GroupMemberVitals:_clear_member_state()
    self.state_label:SetText("")
    self.state_label:SetVisible(false)
    self.state_overlay:SetVisible(false)
end

function GroupMemberVitals:_select_color()
    local select_settings = self:get_vitals_settings().select
    if select_settings ~= nil and select_settings.border_color ~= nil then
        return select_settings.border_color
    end
    return DEFAULT_SELECT_COLOR
end

function GroupMemberVitals:_apply_target_highlight()
    local select_settings = self:get_vitals_settings().select
    local highlight = _highlight()
    if self.target_highlighted ~= true or select_settings.enabled ~= true or self.entity == nil then
        _set_select_border_visible(self.select_border, false)
        if self.select_inner ~= nil then
            _set_select_border_visible(self.select_inner, false)
        end
        if highlight ~= nil then
            highlight.release_glow(self)
        end
        self:_apply_hover()
        return
    end

    local x, y = self.entity_control:GetPosition()
    local width, height = self.entity_control:GetSize()
    local thickness = select_settings.border_width or 0
    _apply_select_border(self.select_border, x, y, width, height, thickness,
        self:_select_color())
    -- linea oscura de 1 px por dentro del borde: separa el borde de la barra
    if self.select_inner ~= nil then
        if thickness > 0 and width > thickness * 2 + 2 and height > thickness * 2 + 2 then
            _apply_select_border(self.select_inner, x + thickness, y + thickness,
                width - thickness * 2, height - thickness * 2, 1, SELECT_INNER_COLOR)
        else
            _set_select_border_visible(self.select_inner, false)
        end
    end
    if highlight ~= nil then
        if select_settings.glow ~= false then
            highlight.claim_glow(self)
        else
            highlight.release_glow(self)
        end
    end
    self:_apply_hover()
end

function GroupMemberVitals:_set_hovered(hovered)
    hovered = hovered == true
    if self.hovered == hovered then
        return
    end
    self.hovered = hovered
    self:_apply_hover()
end

function GroupMemberVitals:_apply_hover()
    if self.hover_border == nil then
        return
    end
    local select_settings = self:get_vitals_settings().select
    local show = self.hovered == true and self.entity ~= nil
        and select_settings.hover ~= false
        and not (self.target_highlighted == true and select_settings.enabled == true)
    if show ~= true then
        _set_select_border_visible(self.hover_border, false)
        return
    end
    local x, y = self.entity_control:GetPosition()
    local width, height = self.entity_control:GetSize()
    _apply_select_border(self.hover_border, x, y, width, height, 1, HOVER_COLOR)
end

-- % de moral por debajo del cual el marco se enciende en rojo (0 = apagado)
function GroupMemberVitals:_low_health_threshold()
    local select_settings = self:get_vitals_settings().select
    if select_settings == nil or select_settings.low_health ~= true then
        return 0
    end
    local pct = tonumber(select_settings.low_health_pct) or 35
    if pct < 1 then
        return 0
    end
    if pct > 99 then
        pct = 99
    end
    return pct
end

function GroupMemberVitals:_is_low_health()
    local threshold = self:_low_health_threshold()
    if threshold <= 0 or self.entity == nil then
        return false
    end
    if self.entity.GetMorale == nil or self.entity.GetMaxMorale == nil then
        return false
    end
    local ok, low = pcall(function()
        if self:_entity_is_link_dead() == true then
            return false
        end
        local morale = self.entity:GetMorale()
        local max_morale = self.entity:GetMaxMorale()
        if type(morale) ~= "number" or type(max_morale) ~= "number" or max_morale <= 0 or morale <= 0 then
            return false
        end
        return (morale / max_morale) * 100 < threshold
    end)
    return ok == true and low == true
end

function GroupMemberVitals:_update_low_health()
    if self.low_overlay == nil then
        return
    end
    local low = self:_is_low_health()
    local highlight = _highlight()
    if low ~= true then
        self.low_active = false
        self.low_overlay:SetVisible(false)
        _set_select_border_visible(self.low_border, false)
        if highlight ~= nil then
            highlight.set_low(self, false)
        end
        return
    end

    local x, y = self.entity_control:GetPosition()
    local width, height = self.entity_control:GetSize()
    self.low_overlay:SetPosition(x, y)
    self.low_overlay:SetSize(width, height)
    _apply_select_border(self.low_border, x, y, width, height, LOW_HEALTH_BORDER,
        Turbine.UI.Color(0.8, LOW_HEALTH_R, LOW_HEALTH_G, LOW_HEALTH_B))
    if self.low_active ~= true then
        self.low_active = true
        self:_paint_low_health(0.25, 0.8)
    end
    self.low_overlay:SetVisible(true)
    if highlight ~= nil then
        highlight.set_low(self, true)
    end
end

-- llamado por Vitals.GroupHighlight en cada cuadro del latido
function GroupMemberVitals:_paint_low_health(fill_alpha, border_alpha)
    if self.low_active ~= true then
        return
    end
    -- solo cambia la transparencia (la posicion la fija _update_low_health)
    self.low_overlay:SetBackColor(Turbine.UI.Color(fill_alpha, LOW_HEALTH_R, LOW_HEALTH_G, LOW_HEALTH_B))
    _set_select_border_color(self.low_border,
        Turbine.UI.Color(border_alpha, LOW_HEALTH_R, LOW_HEALTH_G, LOW_HEALTH_B))
end

function GroupMemberVitals:_update_member_state()
    if self:_entity_is_link_dead() == true then
        self:_set_member_state(TR["OFFLINE"], OFFLINE_STATE_COLOR)
    elseif self:_entity_is_dead() == true then
        self:_set_member_state(TR["DEAD"], DEAD_STATE_COLOR)
    else
        self:_clear_member_state()
    end
    self:_update_low_health()
end

function GroupMemberVitals:_setup_silent_effect_manager()
    -- Per-root toggle (fellowship and raid each have their own). When off, group
    -- members never call GetEffects() or subscribe to effect events, so selecting
    -- a member falls back to the cold path and shows no effects (LotRO does not
    -- expose a fellowship member's effects on the target entity).
    if self:get_vitals_settings().background_effect_tracking ~= true then
        self:_detach_silent_effect_manager()
        return
    end

    if self.em ~= nil then
        self:SetWantsUpdates(true)
        return
    end

    if self.entity == nil or self:_is_local_player(self.entity) == true then
        self:SetWantsUpdates(false)
        return
    end

    if self.entity.GetEffects == nil or self.entity:GetEffects() == nil then
        self:SetWantsUpdates(false)
        return
    end

    self.em = Vitals.TargetEffectManager.acquire_silent(Turbine.Gameplay.LocalPlayer.GetInstance(), self.entity)
    self.em_added_event = self.em:register_added_event(function()
    end)
    self:SetWantsUpdates(true)
end

function GroupMemberVitals:_detach_silent_effect_manager()
    if self.em == nil then
        self.em_added_event = nil
        self:SetWantsUpdates(false)
        return
    end

    if self.em_added_event ~= nil then
        self.em:unregister_added_event(self.em_added_event)
        self.em_added_event = nil
    end

    self.em:delete()
    self.em = nil
    self:SetWantsUpdates(false)
end

function GroupMemberVitals:_update_class_icon()
    local class_icon_settings = self:get_vitals_settings().class_icon
    if class_icon_settings.enabled ~= true then
        self.class_icon:SetVisible(false)
        return
    end

    local size = class_icon_settings.size
    if size <= 0 or self.entity == nil then
        self.class_icon:SetVisible(false)
        return
    end

    local icon = get_class_icon(self.entity:GetClass(), size)
    if icon == nil then
        self.class_icon:SetVisible(false)
        return
    end

    self.class_icon:SetPosition(class_icon_settings.x, class_icon_settings.y)
    self.class_icon:set_icon(icon, size, size)
    self.class_icon:SetVisible(true)
end

function GroupMemberVitals:_update_leader_icon()
    local leader_icon_settings = self:get_vitals_settings().leader_icon
    if leader_icon_settings.enabled ~= true or self.is_leader ~= true then
        self.leader_icon:SetVisible(false)
        return
    end
    if leader_icon_settings.size <= 0 then
        self.leader_icon:SetVisible(false)
        return
    end

    local icon = get_party_leader_icon()
    if icon == nil then
        self.leader_icon:SetVisible(false)
        return
    end

    self.leader_icon:SetPosition(leader_icon_settings.x, leader_icon_settings.y)
    self.leader_icon:set_icon(icon, leader_icon_settings.size, leader_icon_settings.size)
    self.leader_icon:SetVisible(true)
end

function GroupMemberVitals:_build_extra_controls()
    self.select_border = {
        top = Turbine.UI.Control(),
        bottom = Turbine.UI.Control(),
        left = Turbine.UI.Control(),
        right = Turbine.UI.Control(),
    }
    self.select_border.top:SetParent(self)
    self.select_border.top:SetMouseVisible(false)
    self.select_border.top:SetZOrder(75)
    self.select_border.top:SetVisible(false)
    self.select_border.bottom:SetParent(self)
    self.select_border.bottom:SetMouseVisible(false)
    self.select_border.bottom:SetZOrder(75)
    self.select_border.bottom:SetVisible(false)
    self.select_border.left:SetParent(self)
    self.select_border.left:SetMouseVisible(false)
    self.select_border.left:SetZOrder(75)
    self.select_border.left:SetVisible(false)
    self.select_border.right:SetParent(self)
    self.select_border.right:SetMouseVisible(false)
    self.select_border.right:SetZOrder(75)
    self.select_border.right:SetVisible(false)
    self.select_inner = _new_border(self, 75, true)
    self.hover_border = _new_border(self, 74, true)
    self.hovered = false

    -- aviso de vida baja: relleno rojo translucido + borde rojo, por debajo
    -- del cartel MUERTO / DESCONECTADO (z 60)
    self.low_overlay = Turbine.UI.Control()
    self.low_overlay:SetParent(self)
    self.low_overlay:SetMouseVisible(false)
    self.low_overlay:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.low_overlay:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.low_overlay:SetZOrder(58)
    self.low_overlay:SetVisible(false)
    self.low_border = _new_border(self, 59, true)
    self.low_active = false

    -- resaltado al pasar el mouse: solo escucha, el clic sigue siendo del
    -- entity_control nativo (seleccionar no cambia)
    local owner = self
    local entity_control = self.entity_control
    local previous_enter = entity_control.MouseEnter
    local previous_leave = entity_control.MouseLeave
    entity_control.MouseEnter = function(sender, args)
        if type(previous_enter) == "function" then
            pcall(previous_enter, sender, args)
        end
        pcall(owner._set_hovered, owner, true)
    end
    entity_control.MouseLeave = function(sender, args)
        if type(previous_leave) == "function" then
            pcall(previous_leave, sender, args)
        end
        pcall(owner._set_hovered, owner, false)
    end

    self.state_overlay = Turbine.UI.Control()
    self.state_overlay:SetParent(self)
    self.state_overlay:SetMouseVisible(false)
    self.state_overlay:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.state_overlay:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.state_overlay:SetZOrder(60)
    self.state_overlay:SetVisible(false)

    self.state_label = UI.Widgets.LuiLabel()
    self.state_label:SetParent(self.state_overlay)
    self.state_label:SetMouseVisible(false)
    self.state_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.state_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.state_label:SetForeColor(STATE_TEXT_COLOR)
    self.state_label:SetOutlineColor(STATE_OUTLINE_COLOR)
    self.state_label:SetZOrder(1)
    self.state_label:SetVisible(false)

    self.class_icon = UI.Widgets.Image()
    self.class_icon:SetParent(self)
    self.class_icon:SetZOrder(10)
    self.class_icon:SetVisible(false)

    self.leader_icon = UI.Widgets.Image()
    self.leader_icon:SetParent(self)
    self.leader_icon:SetZOrder(11)
    self.leader_icon:SetVisible(false)

    self:_resize_extra_controls()
    self:_update_class_icon()
    self:_update_leader_icon()
end

function GroupMemberVitals:_resize_extra_controls()
    local vitals_settings = self:get_vitals_settings()
    self.state_label:SetFont(vitals_settings.labels[1].font.lotro)
    self:_update_member_state()
    self:_apply_target_highlight()

    local class_icon_settings = vitals_settings.class_icon
    if class_icon_settings.enabled == true and class_icon_settings.size > 0 then
        self.class_icon:set_size(class_icon_settings.size, class_icon_settings.size)
        self.class_icon:SetPosition(class_icon_settings.x, class_icon_settings.y)
    else
        self.class_icon:SetVisible(false)
    end

    local leader_icon_settings = vitals_settings.leader_icon
    if leader_icon_settings.enabled == true and leader_icon_settings.size > 0 then
        self.leader_icon:set_size(leader_icon_settings.size, leader_icon_settings.size)
        self.leader_icon:SetPosition(leader_icon_settings.x, leader_icon_settings.y)
    else
        self.leader_icon:SetVisible(false)
    end

    self:_update_class_icon()
    self:_update_leader_icon()
end
