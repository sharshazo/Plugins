-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Utils.callbacks"
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_class_color = _G.LUI.Utils.lui_class_color
local lui_get_class_icon = _G.LUI.Utils.get_class_icon
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local Vitals = _G.LUI.Features.Vitals
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local Defaults = _G.LUI.Settings.Defaults
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Vitals.effect_icon"
import "LUI.src.Vitals.buff_area"
import "LUI.src.Vitals.debuff_area"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Utils.color"
import "LUI.src.Utils.token_format"
import "LUI.src.Utils.vitals_labels"
import "LUI.src.Utils.class_colors"
import "LUI.src.Utils.icons"
import "LUI.src.Settings.enums"

local function _effect_is_debuff(effect)
    return (effect.IsDebuff ~= nil and effect:IsDebuff()) == true
end

local function _effect_key(effect)
    if effect == nil then
        return 0
    end
    return effect:GetID()
end

local function _effect_ending(effect, now, fallback_start)
    if effect == nil then
        return nil
    end

    local duration = (effect.GetDuration ~= nil and effect:GetDuration()) or 0
    if type(duration) ~= "number" then duration = tonumber(duration) or 0 end
    if duration <= 0 or duration >= 9999 then
        return nil
    end

    local start = (effect.GetStartTime ~= nil and effect:GetStartTime()) or nil
    if type(start) ~= "number" then start = tonumber(start) end

    local t = now
    if type(t) ~= "number" then t = 0 end

    -- Target effect start times can be invalid (often 0), which makes effects look immediately expired.
    -- If the start time looks suspicious, fall back to the last time we saw the effect in the list.
    if start == nil or start <= 0 or (t > 0 and (start > (t + 5) or start < (t - 7200))) then
        start = fallback_start
        if type(start) ~= "number" then
            start = now
        end
    end

    return start + duration
end

local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _stack_height(section_heights, border_width)
    local total = 0
    local visible_count = 0
    for i = 1, #section_heights do
        local height = section_heights[i]
        if type(height) == "number" and height > 0 then
            total = total + height
            visible_count = visible_count + 1
        end
    end
    if visible_count > 1 then
        total = total - (border_width * (visible_count - 1))
    end
    return total
end

local _dim_color = lui_dim_color
local _gradient_morale_color = lui_gradient_morale_color
local HUD_KEY_BY_VITAL = {
    self = "self_vitals",
    target = "target_vitals",
    companion = "companion_vitals",
    boss = "boss_vitals",
    fellowship = "fellowship_vitals",
    raid = "raid_vitals",
}

-- Class-icon "portrait" (a pedido explicito del usuario, replicando el
-- estilo de RUF-WoTLK: cada barra de vida trae un icono de clase pegado).
-- Solo self/target lo necesitan: son las unicas dos barras VitalsBase donde
-- la entidad casi siempre resuelve una clase real (jugador propio / objetivo
-- actual). Companion/boss casi siempre apuntan a mascotas o mobs sin clase
-- resoluble, y fellowship/raid (GroupMemberVitals) ya traen su propio
-- class_icon independiente desde antes -- este mecanismo no debe tocarlos.
local CLASS_ICON_VITAL_KEYS = {
    self = true,
    target = true,
}

---@class VitalsBase : UI.Widgets.LuiHUD
local VitalsBase = class(UI.Widgets.LuiHUD)
Vitals.VitalsBase = VitalsBase

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function VitalsBase:Constructor(vital_key, entity, title, opts)
    if type(opts) ~= "table" then
        opts = {}
    end

    local hud_key = opts.hud_key or HUD_KEY_BY_VITAL[vital_key]
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = hud_key,
        title = title,
        hideable = opts.managed_position ~= true,
    })

    self.vital_key = vital_key
    self.entity = entity
    self.show_effects = opts.show_effects ~= false
    self.show_move_ui = opts.move_ui ~= false
    self.managed_position = opts.managed_position == true
    self.hud_key = hud_key
    self.frame_border_color_override = nil

    self.events = {
        mmc = nil,
        mc = nil,
        tc = nil,
        mtmc = nil,
        tmc = nil,
        icc = nil,
        wc = nil,
        pc = nil,
        mpc = nil,
        ea = nil,
        er = nil,
        ec = nil,
    }

    self.effects_list = nil
    self.effects_resync_due_at = nil
    self.effects_resync_attempts = 0
    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}

    local v = self:get_vitals_settings()
    local frame = v.frame
    local frame_width = frame.width

    local effects_height = self:get_effects_height()
    local lower_bars_height = self:get_lower_bars_height()
    local info_height = self:get_info_height()

    self.bars_left = self:_class_icon_column_width()
    self.width = frame_width - (2 * frame.border_width) - self.bars_left
    if self.width < 1 then self.width = 1 end
    self.bubble_width = 1000

    local total_h = effects_height + _stack_height({ v.morale.height, lower_bars_height, info_height }, frame.border_width)
    if total_h < 1 then total_h = 1 end
    self:SetSize(frame_width, total_h)
    self:layout_move_chrome()
    self:SetMouseVisible(false)
    if self.managed_position then
        self:SetPosition(0, 0)
    else
        self:apply_hud_position()
    end

    -- self:SetBackColor(Turbine.UI.Color(0.9, 0.3, 0.3))

    ---------------------------------------------------------------------
    -- MORALE
    ---------------------------------------------------------------------
    local morale_top = self.show_effects == true and v.effects.layout.top_reserved_height or 0
    local frame_border_color = self:get_frame_border_color()

    self.morale_frame = Turbine.UI.Control()
    self.morale_frame:SetParent(self)
    self.morale_frame:SetSize(frame_width, v.morale.height)
    self.morale_frame:SetTop(morale_top)
    self.morale_frame:SetMouseVisible(false)
    self.morale_frame:SetZOrder(2)

    local bw = frame.border_width
    local inner_w = frame_width - (2 * bw) - self.bars_left
    local morale_inner_h = v.morale.height - (2 * bw)
    if inner_w < 1 then inner_w = 1 end
    if morale_inner_h < 1 then morale_inner_h = 1 end

    self.morale_border = Turbine.UI.Control()
    self.morale_border:SetParent(self.morale_frame)
    self.morale_border:SetPosition(0, 0)
    self.morale_border:SetSize(frame_width, v.morale.height)
    self.morale_border:SetBackColor(frame_border_color)
    self.morale_border:SetMouseVisible(false)
    self.morale_border:SetZOrder(1)

    self.morale_background = Turbine.UI.Control()
    self.morale_background:SetParent(self.morale_border)
    self.morale_background:SetPosition(bw + self.bars_left, bw)
    self.morale_background:SetSize(inner_w, morale_inner_h)
    self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.background))
    self.morale_background:SetMouseVisible(false)
    self.morale_background:SetZOrder(2)

    self.morale_bar = Turbine.UI.Control()
    self.morale_bar:SetParent(self.morale_background)
    self.morale_bar:SetPosition(0, 0)
    self.morale_bar:SetSize(self.morale_background:GetSize())
    self.morale_bar:SetMouseVisible(false)
    self.morale_bar:SetZOrder(2)

    self.bubble_bar = Turbine.UI.Control()
    self.bubble_bar:SetParent(self.morale_background)
    self.bubble_bar:SetHeight(self.morale_background:GetHeight())
    self.bubble_bar:SetPosition(0, 0)
    self.bubble_bar:SetWidth(0)
    self.bubble_bar:SetBackColor(v.morale.color.bubble)
    self.bubble_bar:SetMouseVisible(false)
    self.bubble_bar:SetZOrder(3)

    ---------------------------------------------------------------------
    -- POWER (WRATH)
    ---------------------------------------------------------------------
    self.power_frame = Turbine.UI.Control()
    self.power_frame:SetParent(self)
    self.power_frame:SetTop(self.morale_frame:GetTop() + self.morale_frame:GetHeight() - frame.border_width)
    self.power_frame:SetSize(frame_width, v.power.height)
    self.power_frame:SetMouseVisible(false)
    self.power_frame:SetZOrder(3)

    local power_inner_h = v.power.height - (2 * bw)
    if power_inner_h < 1 then power_inner_h = 1 end

    self.power_border = Turbine.UI.Control()
    self.power_border:SetParent(self.power_frame)
    self.power_border:SetPosition(0, 0)
    self.power_border:SetSize(frame_width, v.power.height)
    self.power_border:SetBackColor(frame_border_color)
    self.power_border:SetMouseVisible(false)
    self.power_border:SetZOrder(1)

    self.power_background = Turbine.UI.Control()
    self.power_background:SetParent(self.power_border)
    self.power_background:SetPosition(bw + self.bars_left, bw)
    self.power_background:SetSize(inner_w, power_inner_h)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.power))
    self.power_background:SetMouseVisible(false)

    self.power_bar = Turbine.UI.Control()
    self.power_bar:SetParent(self.power_background)
    self.power_bar:SetPosition(0, 0)
    self.power_bar:SetSize(self.power_background:GetSize())
    self.power_bar:SetMouseVisible(false)

    ---------------------------------------------------------------------
    -- INFO
    ---------------------------------------------------------------------
    self.info_frame = Turbine.UI.Control()
    self.info_frame:SetParent(self)
    self.info_frame:SetSize(frame_width, info_height)
    self.info_frame:SetTop(self.power_frame:GetTop() + self.power_frame:GetHeight() - bw)
    self.info_frame:SetMouseVisible(false)
    self.info_frame:SetVisible(info_height > 0)
    self.info_frame:SetZOrder(3)

    self.info_border = Turbine.UI.Control()
    self.info_border:SetParent(self.info_frame)
    self.info_border:SetPosition(0, 0)
    self.info_border:SetSize(frame_width, info_height)
    self.info_border:SetBackColor(frame_border_color)
    self.info_border:SetMouseVisible(false)
    self.info_border:SetZOrder(1)

    self.info_background = Turbine.UI.Control()
    self.info_background:SetParent(self.info_border)
    self.info_background:SetPosition(bw, bw)
    self.info_background:SetSize(inner_w, math.max(1, info_height - (2 * bw)))
    self.info_background:SetBackColor(lui_apply_opacity_to_color(v.info.color.background, v.info.opacity))
    self.info_background:SetMouseVisible(false)
    self.info_background:SetZOrder(2)

    ---------------------------------------------------------------------
    -- LABELS
    ---------------------------------------------------------------------
    local function make_bar_label(parent, z_order)
        local label = UI.Widgets.LuiLabel()
        label:SetParent(parent)
        label:SetSize(parent:GetSize())
        label:SetPosition(0, 0)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(z_order)
        -- BUG real reportado por el usuario ("al formar party con LUI no me
        -- deja seleccionar los miembros"): a diferencia de TODOS los demas
        -- widgets decorativos de este addon (Image, bordes, fondos -- que
        -- SIEMPRE llaman SetMouseVisible(false) para dejar pasar el click
        -- al control interactivo de abajo), LuiLabel (label.lua) NO
        -- desactiva su propio mouse por defecto -- hereda directo de
        -- Turbine.UI.Label, mouse-visible=true nativo. Estas 4 labels
        -- cubren el AREA COMPLETA de morale_frame/power_frame (SetSize al
        -- tama;o del padre) en z-order 50-53, muy por encima del
        -- entity_control nativo (Turbine.UI.Lotro.EntityControl, el unico
        -- widget que de verdad selecciona al hacer click) -- se comian
        -- CUALQUIER click en toda la barra antes de que le llegara a
        -- entity_control, en self/target/companion/boss/group/raid por
        -- igual (esta funcion es compartida por todos).
        label:SetMouseVisible(false)
        return label
    end

    self.labels = {
        make_bar_label(self.morale_frame, 50),
        make_bar_label(self.morale_frame, 51),
        make_bar_label(self.power_frame, 52),
        make_bar_label(self.power_frame, 53),
    }

    ---------------------------------------------------------------------
    -- Entity control (clickable player frame)
    ---------------------------------------------------------------------
    self.entity_control = Turbine.UI.Lotro.EntityControl()
    self.entity_control:SetParent(self)
    self.entity_control:SetSize(
        math.max(self.morale_frame:GetWidth(), self.power_frame:GetWidth()),
        _stack_height({ self.morale_frame:GetHeight(), self.power_frame:GetHeight(), info_height }, bw)
    )
    self.entity_control:SetPosition(self.morale_frame:GetPosition())
    self.entity_control:SetEntity(self.entity)
    -- z-order LOWER than morale_frame(2)/power_frame(3)/info_frame(3) on purpose:
    -- Turbine.UI.Lotro.EntityControl draws its OWN native chrome (portrait,
    -- rank+name, health bar) by default. At z=4 (higher than every custom
    -- bar piece) it painted on top of this whole hand-built frame -- the
    -- native look the user kept seeing in every screenshot despite correct
    -- settings was this control's own skin, not a rendering of our config.
    -- It only exists for click-to-target, so it just needs to sit BEHIND
    -- our fully-opaque frame (morale_border/power_border/info_border cover
    -- the whole area) -- everything drawn over it already has
    -- SetMouseVisible(false), so clicks still fall through to it.
    self.entity_control:SetZOrder(0)

    ---------------------------------------------------------------------
    -- Effect windows
    ---------------------------------------------------------------------
    if self.show_effects then
        local DebuffAreaClass = Vitals.DebuffArea
        local BuffAreaClass = Vitals.BuffArea

        if DebuffAreaClass ~= nil and BuffAreaClass ~= nil then
            self.debuffs = DebuffAreaClass(frame_width, v.effects, frame.effects_height)
            self.debuffs:SetParent(self)

            self.buffs = BuffAreaClass(frame_width, v.effects, frame.effects_height)
            self.buffs:SetParent(self)
            self.buffs.on_height_changed = function()
                self:_layout_effect_windows()
            end
            self:_layout_effect_windows()
        else
            self.debuffs = nil
            self.buffs = nil
        end
    else
        self.debuffs = nil
        self.buffs = nil
    end

    ---------------------------------------------------------------------
    -- Subclass-specific controls
    ---------------------------------------------------------------------
    self:_build_extra_controls()

    if CLASS_ICON_VITAL_KEYS[self.vital_key] == true then
        self:_ensure_class_icon()
        self:_layout_class_icon()
    end

    self.morale_frame:SetVisible(true)
    self.power_frame:SetVisible(true)
    if self.vital_key == "target" and entity == nil then
        self:SetVisible(false)
    else
        self:SetVisible(true)
    end

    self:apply_fonts()
    self:apply_text_alignment()
    self:set_entity(entity)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function VitalsBase:get_vitals_settings()
    local k = self.vital_key
    if k == "self" or k == "target" then
        return State.settings[k].vitals
    end
    return State.settings[k]
end

function VitalsBase:get_loaded_vitals_settings()
    local k = self.vital_key
    if k == "self" or k == "target" then
        return State.loaded_settings[k].vitals
    end
    return State.loaded_settings[k]
end

function VitalsBase:get_hud_settings()
    return State.settings.ui.hud[self.hud_key]
end

function VitalsBase:get_loaded_hud_settings()
    return Defaults.get_ui_hud_state(self.hud_key)
end

-- Color de clase automatico (pedido explicito del usuario, replicando el
-- estilo de RUF-WoTLK/WoW: guerrero de un color, mago de otro, etc.).
-- Prioridad sobre el degrade por % existente -- si la entidad tiene clase
-- resoluble (jugador real, propio o de otro), su barra de vida usa SIEMPRE
-- el color fijo de esa clase, sin importar el %; si no tiene clase
-- resoluble (mobs, companions, NPCs), se respeta el comportamiento
-- original (degrade verde->amarillo->rojo por %).
function VitalsBase:morale_color(percent)
    local class_color = lui_class_color(self.entity)
    if class_color ~= nil then
        return class_color
    end

    local c = self:get_vitals_settings().morale.color
    if c.gradient == true then
        return _gradient_morale_color(percent, c.gradient_full or c.high, c.gradient_mid or c.medium,
            c.gradient_low or c.critical)
    end

    if percent > 0.75 then
        return c.high
    elseif percent > 0.5 then
        return c.medium
    elseif percent > 0.25 then
        return c.low
    else
        return c.critical
    end
end

function VitalsBase:dimmed_color(color, dimming)
    return _dim_color(color, dimming)
end

function VitalsBase:resource_background_color(fill_color, static_color)
    local v = self:get_vitals_settings()
    local color
    if v.background_matches_missing == true then
        color = self:dimmed_color(fill_color, v.background_dimming)
    else
        color = static_color
    end
    return lui_apply_opacity_to_color(color, v.background_opacity)
end

function VitalsBase:morale_background_color(fill_color)
    return self:resource_background_color(fill_color, self:get_vitals_settings().morale.color.background)
end

function VitalsBase:power_background_color(fill_color)
    return self:resource_background_color(fill_color, self:get_vitals_settings().morale.color.background)
end

function VitalsBase:Update()
    local due = self.effects_resync_due_at
    if type(due) ~= "number" then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if now < due then
        return
    end

    self:_sync_effects_from_list(now)

    local attempts = self.effects_resync_attempts
    if type(attempts) ~= "number" then attempts = 0 end
    attempts = attempts - 1
    self.effects_resync_attempts = attempts

    if attempts > 0 then
        self.effects_resync_due_at = now + 0.10
    else
        self.effects_resync_due_at = nil
        self:SetWantsUpdates(false)
    end
end

function VitalsBase:get_effects_height()
    if self.show_effects ~= true then
        return 0
    end
    return self:get_vitals_settings().frame.effects_height
end

function VitalsBase:get_info_height()
    local info = self:get_vitals_settings().info
    if info.enabled ~= true then
        return 0
    end
    return info.height
end

function VitalsBase:effects_are_below()
    return self:get_vitals_settings().frame.effects_position == LUI_ENUMS.vitals_effects_position.BELOW
end

function VitalsBase:get_lower_bars_height()
    local v = self:get_vitals_settings()
    return v.power.height
end

function VitalsBase:get_empty_morale_text()
    return ""
end

function VitalsBase:_frame_for_label_link(link_to)
    if link_to == LUI_ENUMS.vitals_label_link.POWER then
        return self.power_frame
    end
    if link_to == LUI_ENUMS.vitals_label_link.INFO then
        if self:get_info_height() > 0 then
            return self.info_frame
        end
        return nil
    end
    return self.morale_frame
end

function VitalsBase:_apply_configurable_label_fonts()
    local specs = self:get_vitals_settings().labels
    for i = 1, #self.labels do
        local label = self.labels[i]
        local spec = specs[i]
        local font = spec.font
        local style = LUI_TO_LOTRO.font_style[font.style]
        label:SetFont(font.lotro)
        label:SetFontStyle(style)
        if style == Turbine.UI.FontStyle.Outline then
            label:SetOutlineColor(font.outline_color)
        end
        label:SetForeColor(font.color)
    end
end

function VitalsBase:_apply_configurable_label_layout()
    local specs = self:get_vitals_settings().labels
    for i = 1, #self.labels do
        local label = self.labels[i]
        local spec = specs[i]
        local frame = self:_frame_for_label_link(spec.link_to)
        if frame == nil then
            label:SetText("")
            label:SetVisible(false)
        else
            if label:GetParent() ~= frame then
                label:SetParent(frame)
            end
            local width, height = frame:GetSize()
            lui_vitals_layout_label(label, width, height, spec.anchor, spec.width_mode, spec.text_alignment,
                spec.x_offset, spec.y_offset, spec.font.name, spec.font.size, label:GetText())
            label:SetVisible(spec.enabled == true and _label_text_is_blank(spec.text) ~= true)
        end
    end
end

function VitalsBase:_render_configurable_labels(context)
    local specs = self:get_vitals_settings().labels
    for i = 1, #self.labels do
        local label = self.labels[i]
        local spec = specs[i]
        local frame = self:_frame_for_label_link(spec.link_to)
        if frame ~= nil and spec.enabled == true and _label_text_is_blank(spec.text) ~= true then
            if label:GetParent() ~= frame then
                label:SetParent(frame)
            end
            local width, height = frame:GetSize()
            local rendered_text = lui_format_tokenized(spec.tokens, context)
            label:SetText(rendered_text)
            lui_vitals_layout_label(label, width, height, spec.anchor, spec.width_mode, spec.text_alignment,
                spec.x_offset, spec.y_offset, spec.font.name, spec.font.size, rendered_text)
            label:SetVisible(true)
        else
            label:SetText("")
            label:SetVisible(false)
        end
    end
end

function VitalsBase:_build_vitals_label_context()
    local ctx = {
        name = "",
        level = "",
        mc = "-",
        mt = "-",
        mp = "-",
        b = "",
        B = "",
        pc = "-",
        pt = "-",
        pp = "-",
    }

    if self.entity == nil then
        return ctx
    end

    if self.entity.GetName ~= nil then
        ctx.name = tostring(self.entity:GetName() or "")
    end
    if self.entity.GetLevel ~= nil then
        ctx.level = tostring(self.entity:GetLevel() or "")
    end

    if self.entity.GetMaxMorale ~= nil and self.entity.GetMorale ~= nil then
        local maxm = self.entity:GetMaxMorale() or 0
        local m = self.entity:GetMorale() or 0
        if maxm > 0 then
            ctx.mc = lui_abbrev_number(m)
            ctx.mt = lui_abbrev_number(maxm)
            ctx.mp = tostring(math.floor((((m / maxm) * 100)) + 0.5)) .. "%"

            local bubble = 0
            if self.entity.GetTemporaryMorale ~= nil then
                bubble = self.entity:GetTemporaryMorale() or 0
            end
            if bubble > 0 then
                local bubble_fmt = self:get_vitals_settings().morale.bubble_tokens
                ctx.b = lui_abbrev_number(bubble)
                ctx.B = lui_format_tokenized(bubble_fmt, {
                    b = ctx.b,
                })
            end
        end
    end

    local is_wrath = self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning
    if is_wrath == true and self.entity.GetClassAttributes ~= nil and self.entity:GetClassAttributes() ~= nil
        and self.entity:GetClassAttributes().GetWrath ~= nil then
        local maxw = 100
        local w = self.entity:GetClassAttributes():GetWrath() or 0
        ctx.pc = lui_abbrev_number(w)
        ctx.pt = lui_abbrev_number(maxw)
        ctx.pp = tostring(math.floor((((w / maxw) * 100)) + 0.5)) .. "%"
    elseif self.entity.GetMaxPower ~= nil and self.entity.GetPower ~= nil then
        local maxp = self.entity:GetMaxPower() or 0
        local p = self.entity:GetPower() or 0
        if maxp > 0 then
            ctx.pc = lui_abbrev_number(p)
            ctx.pt = lui_abbrev_number(maxp)
            ctx.pp = tostring(math.floor((((p / maxp) * 100)) + 0.5)) .. "%"
        end
    end

    return ctx
end

function VitalsBase:_set_primary_label_fallback(text)
    local specs = self:get_vitals_settings().labels
    for i = 1, 2 do
        local label = self.labels[i]
        local spec = specs[i]
        local frame = self:_frame_for_label_link(spec.link_to)
        if frame ~= nil and i == 1 and _label_text_is_blank(text) ~= true then
            if label:GetParent() ~= frame then
                label:SetParent(frame)
            end
            local width, height = frame:GetSize()
            label:SetText(text)
            lui_vitals_layout_label(label, width, height, spec.anchor, spec.width_mode, spec.text_alignment,
                spec.x_offset, spec.y_offset, spec.font.name, spec.font.size, text)
            label:SetVisible(true)
        else
            label:SetText("")
            label:SetVisible(false)
        end
    end
end

function VitalsBase:_clear_labels(start_index, end_index)
    for i = start_index, end_index do
        local label = self.labels[i]
        label:SetText("")
        label:SetVisible(false)
    end
end

function VitalsBase:apply_fonts()
    self:_apply_configurable_label_fonts()
end

function VitalsBase:apply_text_alignment()
    self:_apply_configurable_label_layout()
end

function VitalsBase:is_move_mode()
    return self.show_move_ui == true and UI.Widgets.LuiHUD.is_move_mode(self)
end

function VitalsBase:set_move_mode(enabled)
    if self.show_move_ui ~= true then
        return
    end
    local changed = (enabled == true) ~= self:is_move_mode()
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    if changed and self.show_effects == true then
        self:_set_effect_areas_visible(enabled ~= true)
    end
end

function VitalsBase:persist_position(x, y)
    if self.managed_position then
        return
    end
    UI.Widgets.LuiHUD.persist_position(self, x, y)
end

function VitalsBase:on_target_changed()
end

function VitalsBase:self_combat_changed()
    local frame = self:get_vitals_settings().frame

    if self.entity ~= nil and self.entity.IsInCombat ~= nil and self.entity:IsInCombat() then
        self:SetOpacity(frame.incombat_opacity)
    else
        self:SetOpacity(frame.outcombat_opacity)
    end
end

function VitalsBase:self_bubble_changed()
    if self.entity == nil or self.entity.GetMaxMorale == nil or self.entity.GetMaxTemporaryMorale == nil then
        return
    end
    if self._no_morale == true then
        self.bubble_bar:SetVisible(false)
        return
    end
    local b = self.entity:GetTemporaryMorale() or 0

    if b <= 0 then
        self.bubble_bar:SetVisible(false)
        self:_render_configurable_labels(self:_build_vitals_label_context())
        return
    end

    local maxm = self.entity:GetMaxMorale() or 0
    if maxm <= 0 then
        self.bubble_bar:SetVisible(false)
        self:_render_configurable_labels(self:_build_vitals_label_context())
        return
    end

    local bubble_w = math.floor(((b / maxm) * self.width) + 0.5)
    if bubble_w <= 0 then
        self.bubble_bar:SetVisible(false)
        self:_render_configurable_labels(self:_build_vitals_label_context())
        return
    end
    if bubble_w > self.width then bubble_w = self.width end

    local morale_w = 0
    if self.morale_bar ~= nil and self.morale_bar.GetWidth ~= nil then
        morale_w = self.morale_bar:GetWidth() or 0
    end
    if morale_w < 0 then morale_w = 0 end
    if morale_w > self.width then morale_w = self.width end
    morale_w = math.floor(morale_w + 0.5)

    local max_left = self.width - bubble_w
    if max_left < 0 then max_left = 0 end

    -- Attach bubble to the right of the current morale fill if it fits,
    -- otherwise keep it right-aligned within the bar (overlapping morale).
    local left_inner = morale_w
    if left_inner > max_left then
        left_inner = max_left
    end

    self.bubble_bar:SetTop(0)
    self.bubble_bar:SetHeight(self.morale_bar:GetHeight())
    self.bubble_bar:SetLeft(left_inner)
    self.bubble_bar:SetWidth(bubble_w)
    self.bubble_bar:SetVisible(true)
    self:_render_configurable_labels(self:_build_vitals_label_context())
end

function VitalsBase:self_morale_changed()
    if self.entity == nil or self.entity.GetMaxMorale == nil or self.entity.GetMorale == nil then
        return
    end

    local v = self:get_vitals_settings()
    local maxm = self.entity:GetMaxMorale()
    local m = self.entity:GetMorale()
    if maxm == nil then maxm = 0 end
    if m == nil then m = 0 end

    if maxm > 0 then
        self._no_morale = false
        local percent = m / maxm
        local ctx = self:_build_vitals_label_context()
        self:_render_configurable_labels(ctx)

        local fill_color = self:morale_color(percent)
        self.morale_bar:SetBackColor(fill_color)
        local fill_w = math.floor((self.width * percent) + 0.5)
        if fill_w < 0 then fill_w = 0 end
        if fill_w > self.width then fill_w = self.width end
        self.morale_bar:SetWidth(fill_w)
        self.morale_background:SetBackColor(self:morale_background_color(fill_color))
        self:self_bubble_changed()
    else
        self._no_morale = true
        local name = ""
        if self.entity.GetName ~= nil then
            name = tostring(self.entity:GetName() or "")
        end
        self:_set_primary_label_fallback(name)
        self.morale_bar:SetWidth(self.width)
        self.morale_bar:SetBackColor(v.morale.color.neutral)
        self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.neutral))
        if self.bubble_bar ~= nil then
            self.bubble_bar:SetVisible(false)
        end
        if self.power_border ~= nil then
            self.power_border:SetVisible(false)
        end
        self:_clear_labels(3, 4)
    end
end

-- La barra de poder usa SIEMPRE un color general fijo (el mismo "azul mana"
-- para todas las clases), en vez de colorearla por clase como la barra de
-- vida. Pedido explicito del usuario: como LOTRO no expone (via
-- Turbine.Gameplay) un color por TIPO de recurso como WoW (mana=azul,
-- furia=rojo, energia=amarillo, etc.), la alternativa mas honesta es no
-- inventar esa distincion y dejar un unico color generico para el poder de
-- cualquier clase. Wrath de Beorning sigue usando su propio color
-- (v.power.color.wrath) porque ya es, por definicion, un color de recurso
-- especifico, no una sustitucion del color de clase.
function VitalsBase:_power_fill_color(is_wrath, v)
    return is_wrath and v.power.color.wrath or v.power.color.power
end

function VitalsBase:self_power_changed()
    if self.entity == nil or self.entity.GetMaxPower == nil or self.entity.GetPower == nil then
        return
    end
    if self._no_morale == true then
        if self.power_border ~= nil then
            self.power_border:SetVisible(false)
        end
        self:_clear_labels(3, 4)
        if self.power_bar ~= nil then
            self.power_bar:SetWidth(0)
        end
        return
    end
    local v = self:get_vitals_settings()
    local maxp = self.entity:GetMaxPower()
    local p = self.entity:GetPower()
    if maxp == nil then maxp = 0 end
    if p == nil then p = 0 end
    local is_wrath = false
    if self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning then
        is_wrath = true
    end

    if maxp > 0 then
        if self.power_border ~= nil then
            self.power_border:SetVisible(true)
        end
        local percent = p / maxp
        self:_render_configurable_labels(self:_build_vitals_label_context())
        self.power_bar:SetWidth(self.width * percent)
        local fill_color = self:_power_fill_color(is_wrath, v)
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    else
        if self.power_border ~= nil then
            self.power_border:SetVisible(true)
        end
        self:_render_configurable_labels(self:_build_vitals_label_context())
        self.power_bar:SetWidth(self.width)
        local fill_color = self:_power_fill_color(is_wrath, v)
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    end
end

function VitalsBase:self_wrath_changed()
    if self.entity == nil or self.entity.GetClassAttributes == nil or self.entity:GetClassAttributes().GetWrath == nil then
        return
    end
    local v = self:get_vitals_settings()
    local maxw = 100
    local w = self.entity:GetClassAttributes():GetWrath()

    local percent = w / maxw
    self:_render_configurable_labels(self:_build_vitals_label_context())
    self.power_bar:SetWidth(self.width * percent)
    self.power_bar:SetBackColor(v.power.color.wrath)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.wrath))
end

function VitalsBase:update()
    self:on_target_changed()
    self:self_morale_changed()
    self:self_bubble_changed()
    self:self_combat_changed()

    if self.entity ~= nil and self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning then
        if self.entity.GetClassAttributes ~= nil and self.entity:GetClassAttributes() ~= nil and self.entity:GetClassAttributes().GetWrath ~= nil then
            self:self_wrath_changed()
        else
            self:self_power_changed()
        end
    else
        self:self_power_changed()
    end
end

function VitalsBase:set_entity(entity)
    -- Avoid redundant churn, but don't skip the initial binding during construction.
    if self.entity == entity and self.events ~= nil and self.events.mmc ~= nil then
        return
    end

    if self.entity ~= nil and self.entity ~= entity then
        remove_callback(self.entity, "MaxMoraleChanged", self.events.mmc)
        self.events.mmc = nil
        remove_callback(self.entity, "MoraleChanged", self.events.mc)
        self.events.mc = nil
        remove_callback(self.entity, "TargetChanged", self.events.tc)
        self.events.tc = nil
        remove_callback(self.entity, "MaxTemporaryMoraleChanged", self.events.mtmc)
        self.events.mtmc = nil
        remove_callback(self.entity, "TemporaryMoraleChanged", self.events.tmc)
        self.events.tmc = nil
        remove_callback(self.entity, "InCombatChanged", self.events.icc)
        self.events.icc = nil

        if self.events.wc ~= nil and self.entity.GetClassAttributes ~= nil and self.entity:GetClassAttributes() ~= nil then
            remove_callback(self.entity:GetClassAttributes(), "WrathChanged", self.events.wc)
            self.events.wc = nil
        end

        remove_callback(self.entity, "MaxPowerChanged", self.events.mpc)
        self.events.mpc = nil
        remove_callback(self.entity, "PowerChanged", self.events.pc)
        self.events.pc = nil
    end

    self:_clear_effect_callbacks()

    self.entity = entity
    self.entity_control:SetEntity(self.entity)

    if CLASS_ICON_VITAL_KEYS[self.vital_key] == true then
        self:_update_class_icon()
    end

    if self.entity == nil then
        local v = self:get_vitals_settings()

        self.power_border:SetVisible(true)
        self.bubble_bar:SetVisible(false)

        self:_set_primary_label_fallback(self:get_empty_morale_text())
        self:_clear_labels(3, 4)

        self.morale_bar:SetWidth(self.width)
        self.morale_bar:SetBackColor(v.morale.color.neutral)
        self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.neutral))

        self.power_bar:SetWidth(self.width)
        self.power_bar:SetBackColor(v.power.color.power)
        self.power_background:SetBackColor(self:power_background_color(v.power.color.power))

        if self.show_effects then
            if self.buffs ~= nil then self.buffs:clear_effects() end
            if self.debuffs ~= nil then self.debuffs:clear_effects() end
            self:_layout_effect_windows()
        end

        self:_reset_effect_state()

        self:on_target_changed()

        return
    end

    if self.entity ~= nil and self.entity.GetMaxMorale == nil then
        self.morale_bar:SetWidth(0)
        self.power_bar:SetWidth(0)
        self.bubble_bar:SetWidth(0)
        self:_set_primary_label_fallback(self.entity:GetName())
        self:_clear_labels(3, 4)
        self.power_border:SetVisible(false)

        if self.show_effects then
            if self.buffs ~= nil then self.buffs:clear_effects() end
            if self.debuffs ~= nil then self.debuffs:clear_effects() end
            self:_layout_effect_windows()
        end

        self:_reset_effect_state()

        self:on_target_changed()
        return
    end

    self.power_border:SetVisible(true)

    self.events.mmc = add_callback(self.entity, "MaxMoraleChanged", function() self:self_morale_changed() end)
    self.events.mc = add_callback(self.entity, "MoraleChanged", function() self:self_morale_changed() end)
    self.events.tc = add_callback(self.entity, "TargetChanged", function() self:on_target_changed() end)
    self.events.mtmc = add_callback(self.entity, "MaxTemporaryMoraleChanged", function() self:self_bubble_changed() end)
    self.events.tmc = add_callback(self.entity, "TemporaryMoraleChanged", function() self:self_bubble_changed() end)
    self.events.icc = add_callback(self.entity, "InCombatChanged", function() self:self_combat_changed() end)

    if self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning and self.entity.GetClassAttributes ~= nil and self.entity:GetClassAttributes() ~= nil and self.entity:GetClassAttributes().GetWrath ~= nil then
        self.events.wc = add_callback(self.entity:GetClassAttributes(), "WrathChanged",
            function() self:self_wrath_changed() end)
    else
        self.events.mpc = add_callback(self.entity, "MaxPowerChanged", function() self:self_power_changed() end)
        self.events.pc = add_callback(self.entity, "PowerChanged", function() self:self_power_changed() end)
    end

    if self.show_effects then
        self:_setup_effect_tracking()
    end

    self:update()
end

function VitalsBase:resize()
    self:apply_native_scaling()

    local v = self:get_vitals_settings()
    local frame = v.frame
    local frame_width = frame.width
    local effects_height = self:get_effects_height()
    local lower_bars_height = self:get_lower_bars_height()
    local info_height = self:get_info_height()
    local bw = frame.border_width

    self.bars_left = self:_class_icon_column_width()
    self.width = frame_width - (2 * bw) - self.bars_left
    if self.width < 1 then self.width = 1 end

    local core_height = _stack_height({ v.morale.height, lower_bars_height, info_height }, bw)
    local total_h = effects_height + core_height
    if total_h < 1 then total_h = 1 end
    self:SetSize(frame_width, total_h)
    self:layout_move_chrome()
    if not self.managed_position then
        self:apply_hud_position()
    end

    self.morale_frame:SetSize(frame_width, v.morale.height)
    local inner_w = frame_width - (2 * bw) - self.bars_left
    local morale_inner_h = v.morale.height - (2 * bw)
    local power_inner_h = v.power.height - (2 * bw)
    local info_inner_h = info_height - (2 * bw)
    if inner_w < 1 then inner_w = 1 end
    if morale_inner_h < 1 then morale_inner_h = 1 end
    if power_inner_h < 1 then power_inner_h = 1 end
    if info_inner_h < 1 then info_inner_h = 1 end

    self.morale_frame:SetTop(0)

    self.morale_border:SetSize(frame_width, v.morale.height)
    self:_apply_frame_border_color()

    self.morale_background:SetPosition(bw + self.bars_left, bw)
    self.morale_background:SetSize(inner_w, morale_inner_h)
    self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.background))

    self.morale_bar:SetPosition(0, 0)
    self.morale_bar:SetSize(inner_w, morale_inner_h)

    self.bubble_bar:SetHeight(morale_inner_h)
    self.bubble_bar:SetPosition(0, 0)
    self.bubble_bar:SetBackColor(v.morale.color.bubble)
    self.bubble_bar:SetZOrder(3)

    self.power_frame:SetTop(self.morale_frame:GetTop() + self.morale_frame:GetHeight() - frame.border_width)
    self.power_frame:SetSize(frame_width, v.power.height)

    self.power_border:SetSize(frame_width, v.power.height)
    self.power_background:SetPosition(bw + self.bars_left, bw)
    self.power_background:SetSize(inner_w, power_inner_h)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.power))
    self.power_bar:SetPosition(0, 0)
    self.power_bar:SetSize(inner_w, power_inner_h)

    self.info_frame:SetSize(frame_width, info_height)
    self.info_frame:SetVisible(info_height > 0)
    self.info_border:SetSize(frame_width, info_height)
    self.info_background:SetPosition(bw, bw)
    self.info_background:SetSize(inner_w, info_inner_h)
    self.info_background:SetBackColor(lui_apply_opacity_to_color(v.info.color.background, v.info.opacity))

    self:_apply_configurable_label_layout()
    self:apply_fonts()
    self:apply_text_alignment()

    if self.show_effects and self.debuffs ~= nil then
        self.debuffs:apply_settings(frame_width, v.effects, frame.effects_height)
    end
    if self.show_effects and self.buffs ~= nil then
        self.buffs:apply_settings(frame_width, v.effects, frame.effects_height)
    end

    local top_height = self:_layout_effect_windows() or 0
    local morale_top = top_height
    local power_top = morale_top + v.morale.height - bw
    local info_top = power_top + v.power.height - bw
    local bottom_start = power_top + v.power.height

    self.morale_frame:SetTop(morale_top)
    self.power_frame:SetTop(power_top)
    self.info_frame:SetTop(info_top)

    if info_height > 0 then
        bottom_start = info_top + info_height - bw
    end

    self.entity_control:SetSize(
        math.max(self.morale_frame:GetWidth(), self.power_frame:GetWidth()),
        core_height
    )
    self.entity_control:SetPosition(0, morale_top)

    self:_layout_effect_windows(bottom_start)

    self:_resize_extra_controls()

    if CLASS_ICON_VITAL_KEYS[self.vital_key] == true then
        self:_layout_class_icon()
    end

    self:update()
end

function VitalsBase:get_frame_border_color()
    if self.frame_border_color_override ~= nil then
        return self.frame_border_color_override
    end

    return self:get_vitals_settings().frame.border_color
end

function VitalsBase:_apply_frame_border_color()
    local color = self:get_frame_border_color()
    self.morale_border:SetBackColor(color)
    self.power_border:SetBackColor(color)
    self.info_border:SetBackColor(color)
end

function VitalsBase:set_frame_border_color_override(color)
    self.frame_border_color_override = color
    self:_apply_frame_border_color()
end

---------------------------------------------------------------------
-- Class icon ("portrait")
---------------------------------------------------------------------

-- Pedido explicito del usuario ("dejar el target del marco de personaje y
-- target con la misma arquitectura visual que el marco de party"): self y
-- target ahora usan el MISMO estilo de icono flotante SUPERPUESTO sobre la
-- barra que ya usaba GroupMemberVitals para fellowship/raid, en vez de
-- reservar una columna aparte que angostaba las barras (el estilo original
-- RUF-WoTLK de un pedido anterior). El icono en si sigue existiendo solo
-- para self/target (ver CLASS_ICON_VITAL_KEYS mas abajo, y
-- _ensure_class_icon/_update_class_icon) -- lo unico que cambia es que ya
-- no le resta ancho a las barras; su posicion se sigue controlando con
-- class_icon.x/class_icon.y (LUI Settings > Vitals > Icon X/Icon Y), igual
-- que el icono de clase de party.
function VitalsBase:_class_icon_column_width()
    return 0
end

function VitalsBase:_ensure_class_icon()
    if self.class_icon ~= nil then
        return
    end

    -- Parented to morale_frame (not self): self's own top edge shifts down
    -- when buffs/debuffs render above the bars (bottom-layout default), but
    -- morale_frame's top-left is always the health bar's own corner.
    self.class_icon = UI.Widgets.Image()
    self.class_icon:SetParent(self.morale_frame)
    self.class_icon:SetMouseVisible(false)
    self.class_icon:SetZOrder(10)
    self.class_icon:SetVisible(false)
end

function VitalsBase:_layout_class_icon()
    if self.class_icon == nil then
        return
    end

    local settings = self:get_vitals_settings().class_icon
    if settings == nil or settings.enabled ~= true or settings.size <= 0 then
        self.class_icon:SetVisible(false)
        return
    end

    self.class_icon:set_size(settings.size, settings.size)
    self.class_icon:SetPosition(settings.x, settings.y)
end

function VitalsBase:_update_class_icon()
    if self.class_icon == nil then
        return
    end

    local settings = self:get_vitals_settings().class_icon
    if settings == nil or settings.enabled ~= true or settings.size <= 0 then
        self.class_icon:SetVisible(false)
        return
    end

    if self.entity == nil or self.entity.GetClass == nil then
        self.class_icon:SetVisible(false)
        return
    end

    local ok, cls = pcall(function() return self.entity:GetClass() end)
    if ok ~= true or cls == nil then
        self.class_icon:SetVisible(false)
        return
    end

    local icon = lui_get_class_icon(cls, settings.size)
    if icon == nil then
        self.class_icon:SetVisible(false)
        return
    end

    self.class_icon:SetPosition(settings.x, settings.y)
    self.class_icon:set_icon(icon, settings.size, settings.size)
    self.class_icon:SetVisible(true)
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function VitalsBase:_effect_area_for_key(area_key)
    if area_key == "buffs" then
        return self.buffs
    end
    if area_key == "debuffs" then
        return self.debuffs
    end
    error("Unknown vitals effect area key: " .. tostring(area_key))
end

function VitalsBase:_effect_entry_visual_height(entry)
    local area = self:_effect_area_for_key(entry.area_key)
    local height = area:GetHeight()
    if height < 0 then
        height = 0
    end
    if height > entry.reserved_height then
        height = entry.reserved_height
    end
    return area, height
end

function VitalsBase:_layout_top_effect_entries(entries, reserved_height)
    local visual_entries = {}
    local visual_total = 0

    for i = 1, #entries do
        local area, height = self:_effect_entry_visual_height(entries[i])
        visual_entries[i] = {
            area = area,
            height = height,
        }
        visual_total = visual_total + height
    end

    local cursor = reserved_height - visual_total
    if cursor < 0 then
        cursor = 0
    end

    for i = 1, #visual_entries do
        local entry = visual_entries[i]
        entry.area:SetTop(cursor)
        cursor = cursor + entry.height
    end
end

function VitalsBase:_layout_bottom_effect_entries(entries, bottom_start)
    local cursor = bottom_start

    for i = 1, #entries do
        local area, height = self:_effect_entry_visual_height(entries[i])
        area:SetTop(cursor)
        cursor = cursor + height
    end
end

function VitalsBase:_layout_effect_windows(bottom_start_override)
    if self.show_effects ~= true then
        return 0
    end
    if self.debuffs == nil or self.buffs == nil then
        return 0
    end

    local v = self:get_vitals_settings()
    local layout = v.effects.layout

    self.buffs:set_max_height(layout.buffs_reserved_height)
    self.debuffs:set_max_height(layout.debuffs_reserved_height)

    self.buffs:set_reverse_fill(layout.buffs_reverse_fill)
    self.buffs:set_horizontal_alignment(v.effects.buffs.alignment)
    self.debuffs:set_reverse_fill(layout.debuffs_reverse_fill)
    self.debuffs:set_horizontal_alignment(v.effects.debuffs.alignment)

    self:_layout_top_effect_entries(layout.top, layout.top_reserved_height)

    local bottom_start = bottom_start_override
    if type(bottom_start) ~= "number" then
        bottom_start = layout.top_reserved_height + _stack_height({
            v.morale.height,
            self:get_lower_bars_height(),
            self:get_info_height(),
        }, v.frame.border_width)
    end

    self:_layout_bottom_effect_entries(layout.bottom, bottom_start)

    return layout.top_reserved_height
end

function VitalsBase:_set_effect_areas_visible(visible)
    if self.show_effects ~= true then
        return
    end

    if self.debuffs ~= nil then self.debuffs:SetVisible(visible == true) end
    if self.buffs ~= nil then self.buffs:SetVisible(visible == true) end
    self:_layout_effect_windows()
end

function VitalsBase:_upsert_effect(effect, now)
    if effect == nil or effect.IsDebuff == nil then
        return
    end
    if self.show_effects ~= true or self.debuffs == nil or self.buffs == nil then
        return
    end

    local t = now
    if type(t) ~= "number" then
        t = Turbine.Engine.GetGameTime()
    end

    local key = _effect_key(effect)
    self.effects_seen_at[key] = t

    local started = self.effects_started_at[key]
    if type(started) ~= "number" then
        started = t
        self.effects_started_at[key] = started
    end

    local ending = _effect_ending(effect, t, started)
    if type(ending) == "number" then
        self.effects_ending_at[key] = ending
    end

    local existing = self.effects_objects[key]
    if existing == nil then
        self.effects_objects[key] = effect
        if effect:IsDebuff() then
            self.debuffs:add_effect(effect)
        else
            self.buffs:add_effect(effect)
        end
        self:_layout_effect_windows()
    elseif existing ~= effect then
        self.effects_objects[key] = effect
        if effect:IsDebuff() then
            self.debuffs:add_effect(effect)
        else
            self.buffs:add_effect(effect)
        end
    end
end

function VitalsBase:_clear_effect_callbacks()
    if self.show_effects and self.effects_list ~= nil then
        remove_callback(self.effects_list, "EffectAdded", self.events.ea)
        self.events.ea = nil
        remove_callback(self.effects_list, "EffectRemoved", self.events.er)
        self.events.er = nil
        remove_callback(self.effects_list, "EffectsCleared", self.events.ec)
        self.events.ec = nil
    end
    self.effects_list = nil
end

function VitalsBase:_reset_effect_state()
    self.effects_resync_due_at = nil
    self.effects_resync_attempts = 0
    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}
    self:SetWantsUpdates(false)
end

-- Default implementation: track effects directly from entity:GetEffects() callbacks.
-- IMPORTANT: ONLY WORKS FOR LOCAL PLAYER, use TargetEventManager alternative
-- for targets.
function VitalsBase:_setup_effect_tracking_default()
    if self.show_effects ~= true then
        return
    end
    if self.debuffs ~= nil then self.debuffs:clear_effects() end
    if self.buffs ~= nil then self.buffs:clear_effects() end
    self:_layout_effect_windows()

    if self.entity == nil or self.entity.GetEffects == nil or self.debuffs == nil or self.buffs == nil then
        return
    end

    self.effects_list = self.entity:GetEffects()
    local bound_effects = self.effects_list
    if bound_effects == nil then
        return
    end

    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}
    self:_request_effects_resync(0.05, 4)

    self.events.ea = add_callback(bound_effects, "EffectAdded", function(sender, args)
        if self.effects_list ~= bound_effects then
            return
        end
        local idx = args ~= nil and args.Index or nil
        local eff = nil
        if idx ~= nil and sender ~= nil and sender.Get ~= nil then
            eff = sender:Get(idx)
        end
        self:_upsert_effect(eff)
        self:_request_effects_resync(0.05, 6)
    end)

    self.events.er = add_callback(bound_effects, "EffectRemoved", function(sender, args)
        if self.effects_list ~= bound_effects then
            return
        end
        local eff = args ~= nil and args.Effect or nil
        if eff ~= nil then
            self:_remove_effect(eff)
        end
        self:_request_effects_resync(0.05, 6)
    end)

    self.events.ec = add_callback(bound_effects, "EffectsCleared", function()
        if self.effects_list ~= bound_effects then
            return
        end
        self:_request_effects_resync(0.10, 8)
    end)
end

-- Override in child classes when effect sync differs.
function VitalsBase:_setup_effect_tracking()
    self:_setup_effect_tracking_default()
end

function VitalsBase:_request_effects_resync(delay_seconds, attempts)
    if self.show_effects ~= true then
        return
    end
    if self.effects_list == nil then
        return
    end

    local delay = delay_seconds
    if type(delay) ~= "number" then
        delay = 0.10
    end
    if delay < 0 then delay = 0 end

    local a = attempts
    if type(a) ~= "number" then
        a = 1
    end
    if a < 1 then a = 1 end
    a = math.floor(a + 0.5)
    if a > 10 then a = 10 end
    if type(self.effects_resync_attempts) ~= "number" or self.effects_resync_attempts < a then
        self.effects_resync_attempts = a
    end

    self.effects_resync_due_at = Turbine.Engine.GetGameTime() + delay
    self:SetWantsUpdates(true)
end

function VitalsBase:_sync_effects_from_list(now)
    if self.show_effects ~= true then
        return
    end
    if self.debuffs == nil or self.buffs == nil then
        return
    end
    if self.effects_list == nil or self.effects_list.GetCount == nil or self.effects_list.Get == nil then
        return
    end

    local t = now
    if type(t) ~= "number" then
        t = Turbine.Engine.GetGameTime()
    end

    local sticky_target = self.vital_key == "target"
    local missing_grace = sticky_target and 999999 or 2.5
    local missing_grace_indef = sticky_target and 30.0 or 10.0

    local seen = {}
    local layout_dirty = false
    local count = self.effects_list:GetCount() or 0
    for i = 1, count do
        local effect = self.effects_list:Get(i)
        if effect ~= nil and effect.IsDebuff ~= nil then
            local key = _effect_key(effect)

            local started = self.effects_started_at[key]
            if type(started) ~= "number" then
                started = t
                self.effects_started_at[key] = started
            end

            local ending = _effect_ending(effect, t, started)
            if type(ending) == "number" then
                self.effects_ending_at[key] = ending
            else
                ending = self.effects_ending_at[key]
            end
            if type(ending) == "number" and t >= ending then
                -- Some effects linger in the effect list after expiration; prune them so they don't stick at 0s.
                local obj = self.effects_objects[key] or effect
                if _effect_is_debuff(obj) then
                    self.debuffs:remove_effect(obj, key)
                else
                    self.buffs:remove_effect(obj, key)
                end
                layout_dirty = true
                self.effects_objects[key] = nil
                self.effects_seen_at[key] = nil
                self.effects_started_at[key] = nil
                self.effects_ending_at[key] = nil
            else
                seen[key] = true
                self.effects_seen_at[key] = t

                local existing = self.effects_objects[key]
                if existing == nil then
                    self.effects_objects[key] = effect
                    if effect:IsDebuff() then
                        self.debuffs:add_effect(effect)
                    else
                        self.buffs:add_effect(effect)
                    end
                    layout_dirty = true
                elseif existing ~= effect then
                    -- Same key but different wrapper (e.g., refreshed effects). Update icon binding/timer.
                    self.effects_objects[key] = effect
                    if effect:IsDebuff() then
                        self.debuffs:add_effect(effect)
                    else
                        self.buffs:add_effect(effect)
                    end
                end
            end
        end
    end

    for key, effect in pairs(self.effects_objects) do
        if seen[key] ~= true then
            local last = self.effects_seen_at[key]
            if type(last) ~= "number" then last = 0 end
            if effect == nil then
                self.effects_objects[key] = nil
                self.effects_seen_at[key] = nil
                self.effects_started_at[key] = nil
                self.effects_ending_at[key] = nil
            else
                local ending = _effect_ending(effect, t, last)
                if type(ending) == "number" then
                    self.effects_ending_at[key] = ending
                else
                    ending = self.effects_ending_at[key]
                end

                if type(ending) == "number" and t >= ending then
                    if _effect_is_debuff(effect) then
                        self.debuffs:remove_effect(effect, key)
                    else
                        self.buffs:remove_effect(effect, key)
                    end
                    layout_dirty = true
                    self.effects_objects[key] = nil
                    self.effects_seen_at[key] = nil
                    self.effects_started_at[key] = nil
                    self.effects_ending_at[key] = nil
                else
                    if sticky_target and type(ending) == "number" then
                        -- For target vitals, the effect list frequently drops active debuffs.
                        -- Keep effects until their own duration ends.
                    else
                        local grace = (type(ending) == "number") and missing_grace or missing_grace_indef
                        if (t - last) > grace then
                            if _effect_is_debuff(effect) then
                                self.debuffs:remove_effect(effect, key)
                            else
                                self.buffs:remove_effect(effect, key)
                            end
                            layout_dirty = true
                            self.effects_objects[key] = nil
                            self.effects_seen_at[key] = nil
                            self.effects_started_at[key] = nil
                            self.effects_ending_at[key] = nil
                        end
                    end
                end
            end
        end
    end

    if layout_dirty then
        self:_layout_effect_windows()
    end
end

function VitalsBase:_remove_effect(effect)
    if effect == nil or self.show_effects ~= true then
        return
    end
    if self.debuffs == nil or self.buffs == nil then
        return
    end

    local key = _effect_key(effect)
    if _effect_is_debuff(effect) then
        self.debuffs:remove_effect(effect, key)
    else
        self.buffs:remove_effect(effect, key)
    end
    self.effects_objects[key] = nil
    self.effects_seen_at[key] = nil
    self.effects_started_at[key] = nil
    self.effects_ending_at[key] = nil

    self:_layout_effect_windows()
end

function VitalsBase:_build_extra_controls()
end

function VitalsBase:_resize_extra_controls()
end
