-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local Upkeep = _G.LUI.Features.Upkeep
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.enums"
import "LUI.src.Utils.timed_row_layout"
import "LUI.src.Utils.color"
import "LUI.src.Utils.callbacks"

-- One Upkeep bar slot: a pure tracker. Our own Image draws the skill icon
-- (from the trained skill's icon image id) in all three states:
--   ready    - plain icon.
--   active   - drain overlay + buff countdown over the icon.
--   cooldown - icon shaded or dimmed + cooldown countdown.
-- Not clickable; the buff is recast from the action bars.
--
-- A zoomed (stretched) icon renders above every control in its own window
-- but below other windows, so the icon lives in its own small window (the
-- UpkeepWindow keeps it between itself and the decoration overlay), and
-- the decorations (drain, shade, timer) live in the overlay window above
-- (overlay_parent), laid out in true pixels at this slot's cell offset.
-- The icon window also carries the transparent cooldown style: opacity
-- only works on windows (SetOpacity is a silent no-op on plain controls).
local UpkeepSlot = class(Turbine.UI.Control)
Upkeep.UpkeepSlot = UpkeepSlot

-- seconds between IsUsable() polls; far below what the eye resolves, far
-- above the render rate
local USABLE_POLL_EVERY = 0.25

-- translucent back colors only render with alpha blending enabled
local function _set_alpha_backdrop(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local UpkeepIconWindow = class(UI.Widgets.LuiBaseWindow)

function UpkeepIconWindow:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })

    self:SetVisible(false)
    self:SetMouseVisible(false)
    -- opacity only takes effect on alpha-blended windows (same setup as
    -- the drop entries, which fade this way)
    _set_alpha_backdrop(self)
end

function UpkeepIconWindow:destroy()
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function UpkeepSlot:Constructor(overlay_parent, window)
    Turbine.UI.Control.Constructor(self)

    -- owning UpkeepWindow, notified when this slot's urgency inputs change
    self.window = window
    -- binding: decoded skills-DB record ({ id, name, effects }) or nil when
    -- the dropped skill applies no packed visible buff (degraded slot).
    self.binding = nil
    self.did_text = nil
    self.skill = nil
    self.reset_time = nil
    -- IsUsable() covers the conditions the plugin cannot see: execute-range,
    -- target state, stance, gambits, positional requirements
    self.usable = true
    self._usable_due_at = 0
    -- effect instance id -> { ending, duration, gen }; ending nil = no
    -- constant duration (toggle/permanent buff, shown active without
    -- countdown). gen is the poll pass that last saw the effect; entries
    -- carrying an older gen are gone from the player and get pruned.
    self.active = {}
    self.active_count = 0

    self._size = 0
    self._x = 0
    self._y = 0
    self._move_mode = false

    self:SetMouseVisible(false)

    self.placeholder = Turbine.UI.Control()
    self.placeholder:SetParent(self)
    self.placeholder:SetMouseVisible(false)
    _set_alpha_backdrop(self.placeholder)
    self.placeholder:SetBackColor(Turbine.UI.Color(0.5, 0.5, 0.5, 0.5))
    self.placeholder:SetVisible(false)

    self.placeholder_inner = Turbine.UI.Control()
    self.placeholder_inner:SetParent(self.placeholder)
    self.placeholder_inner:SetMouseVisible(false)
    self.placeholder_inner:SetBackColor(Turbine.UI.Color(1, 0.08, 0.08, 0.08))

    self._shown = false
    self.icon_window = UpkeepIconWindow()

    self._icon_graphic = nil
    self.icon = UI.Widgets.Image()
    self.icon:SetParent(self.icon_window)
    self.icon:SetVisible(false)

    self.drain = Turbine.UI.Control()
    self.drain:SetParent(overlay_parent)
    self.drain:SetMouseVisible(false)
    _set_alpha_backdrop(self.drain)
    self.drain:SetZOrder(10)
    self.drain:SetVisible(false)

    self.shade = Turbine.UI.Control()
    self.shade:SetParent(overlay_parent)
    self.shade:SetMouseVisible(false)
    _set_alpha_backdrop(self.shade)
    self.shade:SetZOrder(11)
    self.shade:SetVisible(false)

    self.time_label = UI.Widgets.LuiLabel()
    self.time_label:SetParent(overlay_parent)
    self.time_label:SetMouseVisible(false)
    self.time_label:SetSelectable(false)
    self.time_label:SetMultiline(false)
    self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.time_label:SetZOrder(12)
    self.time_label:SetText("")

    self:_reset_write_cache()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

function UpkeepSlot:destroy()
    self:set_skill(nil)
    self.icon_window:destroy()
    self.drain:SetParent(nil)
    self.shade:SetParent(nil)
    self.time_label:SetParent(nil)
    self:SetParent(nil)
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function UpkeepSlot:apply_settings()
    local s = State.settings.self.upkeep
    local size = s.icon_size
    self._size = size

    self:SetSize(size, size)
    self.icon_window:SetSize(size, size)

    self.icon:SetPosition(0, 0)
    if self._icon_graphic ~= nil then
        -- set_icon turns the image visible; update() decides what shows
        self.icon:set_icon(self._icon_graphic, size, size)
        self.icon:SetVisible(false)
    end

    self.placeholder:SetPosition(0, 0)
    self.placeholder:SetSize(size, size)
    local inner = size - 2
    if inner < 1 then inner = 1 end
    self.placeholder_inner:SetPosition(1, 1)
    self.placeholder_inner:SetSize(inner, inner)

    self.drain:SetBackColor(lui_apply_opacity_to_color(s.drain_color, s.drain_opacity))
    self.shade:SetSize(size, size)
    self.shade:SetBackColor(lui_apply_opacity_to_color(s.cd_shade_color, s.cd_shade_opacity))

    self.time_label:SetSize(size, size)
    self.time_label:SetFont(s.font.lotro)
    self.time_label:SetFontStyle(LUI_TO_LOTRO.font_style[s.font.style] or Turbine.UI.FontStyle.None)
    self.time_label:SetOutlineColor(s.font.outline_color)

    self:_reset_write_cache()
end

-- same cell offset inside the HUD and inside the overlay window above it
function UpkeepSlot:place(x, y)
    self._x = x
    self._y = y
    self:SetPosition(x, y)
    self.shade:SetPosition(x, y)
    self.time_label:SetPosition(x, y)
    -- the drain position depends on its current height; carry it along
    -- (update() only rewrites it when the height changes)
    local drain_h = self._last_drain_h
    if drain_h ~= nil and drain_h > 0 then
        self.drain:SetPosition(x, y + self._size - drain_h)
    end
end

function UpkeepSlot:set_binding(did_text, record)
    self.did_text = did_text
    self.binding = record
    self:clear_active()
    self.reset_time = nil

    -- the decorations live in the overlay window: the slot's own
    -- visibility does not cover them, reset them explicitly
    self.drain:SetVisible(false)
    self.shade:SetVisible(false)
    self.time_label:SetText("")
    self:_reset_write_cache()
    self:refresh_visibility()
    self:sync_shown(self._shown)
end

-- the icon window follows the bar's effective visibility (passed down by
-- the UpkeepWindow) and shows only for bound slots
function UpkeepSlot:sync_shown(shown)
    self._shown = shown == true
    self.icon_window:SetVisible(self._shown and self.did_text ~= nil)
end

function UpkeepSlot:set_skill(skill)
    if skill == self.skill then
        self:refresh_cooldown()
        return
    end

    self.skill = skill

    local icon_id = nil
    if skill ~= nil and skill.GetSkillInfo ~= nil then
        local info = skill:GetSkillInfo()
        if info ~= nil and info.GetIconImageID ~= nil then
            icon_id = info:GetIconImageID()
        end
    end
    if icon_id ~= nil then
        self._icon_graphic = Turbine.UI.Graphic(icon_id)
        self.icon:set_icon(self._icon_graphic, self._size, self._size)
    else
        self._icon_graphic = nil
        self.icon:set_icon(nil)
    end
    self.icon:SetVisible(false)
    self:_reset_write_cache()

    self:refresh_cooldown()
end

-- Polled from update() rather than driven by ResetTimeChanged: the bar
-- watches at most a handful of skills, and reading them itself keeps it
-- working no matter which other features are enabled.
function UpkeepSlot:refresh_cooldown()
    local previous = self.reset_time
    local skill = self.skill
    if skill == nil or skill.GetResetTime == nil then
        self.reset_time = nil
    else
        self.reset_time = skill:GetResetTime()
    end
    if self.reset_time ~= previous then
        self.window:invalidate_order()
    end
end

-- Skills gated on something the plugin cannot see -- an execute threshold, a
-- valid target, a stance -- read as ready whenever they are off cooldown;
-- IsUsable() is the only signal the game gives for that. Skills the character
-- has not trained resolve to no skill at all, and count as usable so they
-- render exactly as before.
--
-- Throttled: what it reports changes on a human timescale, so polling it at
-- the render rate would just burn native calls.
function UpkeepSlot:refresh_usable(now)
    if now < self._usable_due_at then
        return
    end
    self._usable_due_at = now + USABLE_POLL_EVERY

    local skill = self.skill
    if skill == nil or skill.IsUsable == nil then
        self.usable = true
        return
    end
    self.usable = skill:IsUsable() ~= false
end

-- Records a watched effect seen in this poll pass. The entry table is reused
-- across passes so a steady buff allocates nothing; returns whether the slot's
-- tracked state actually moved, so the caller only re-sorts when it did.
function UpkeepSlot:mark_active(effect, now, gen)
    local id = effect:GetID()
    local duration = tonumber(effect:GetDuration())
    local ending = nil
    if duration ~= nil and duration > 0 and duration < 9999 then
        local start = tonumber(effect:GetStartTime())
        if start == nil or start <= 0 or start > now then
            start = now
        end
        ending = start + duration
    else
        duration = nil
    end

    local rec = self.active[id]
    local added = false
    if rec == nil then
        rec = {}
        self.active[id] = rec
        self.active_count = self.active_count + 1
        added = true
    elseif rec.gen == gen then
        -- A second instance of the same effect inside one poll pass: a
        -- stackable buff that outlasts its own cooldown, applied again before
        -- the first ran out. The two stacks can share an id, so keep the one
        -- that runs longest rather than whichever the list yielded last --
        -- otherwise the slot counts down the stack that is about to expire.
        -- A stack with no constant duration outlasts any timed one.
        if rec.ending == nil then
            return false
        end
        if ending ~= nil and ending <= rec.ending then
            return false
        end
    end
    -- an entry whose end moved changes this slot's urgency just as much as a
    -- new one does, so both have to reach the caller or the auto order goes
    -- stale until something unrelated dirties it
    local changed = added or rec.ending ~= ending
    rec.ending = ending
    rec.duration = duration
    rec.gen = gen
    return changed
end

-- drops entries the latest poll pass did not see; returns whether anything
-- went away
function UpkeepSlot:prune_active(gen)
    if self.active_count == 0 then
        return false
    end

    local removed = false
    for id, rec in pairs(self.active) do
        if rec.gen ~= gen then
            self.active[id] = nil
            self.active_count = self.active_count - 1
            removed = true
        end
    end
    return removed
end

function UpkeepSlot:clear_active()
    self.active = {}
    self.active_count = 0
end

-- auto-order sort key: seconds until this skill both needs and can be
-- recast. 0 = act now; permanent/toggle buffs and unbound or untracked
-- slots never need attention and sort last.
--
-- CONTRACT: this must stay a plain countdown -- max(deadline - now, 0)
-- or math.huge -- so every slot's key falls at the same rate and the
-- relative order can only change on a discrete event. The event-driven
-- re-sort (_order_dirty in upkeep_window) skips quiet ticks on exactly
-- that basis; any non-linear shaping here (thresholds, tiers, bucketing)
-- would let the order change with no event and go silently stale.
function UpkeepSlot:urgency(now)
    -- unbound, or bound but untracked (skill missing from the skills DB):
    -- nothing to watch, never urgent
    if self.did_text == nil or self.binding == nil then
        return math.huge
    end

    local buff_remaining = 0
    for _, rec in pairs(self.active) do
        if rec.ending == nil then
            return math.huge
        end
        if rec.ending > now then
            local remaining = rec.ending - now
            if remaining > buff_remaining then
                buff_remaining = remaining
            end
        end
    end

    local cd_remaining = 0
    if self.reset_time ~= nil and self.reset_time > now then
        cd_remaining = self.reset_time - now
    end

    if cd_remaining > buff_remaining then
        return cd_remaining
    end
    return buff_remaining
end

function UpkeepSlot:set_move_mode(enabled)
    self._move_mode = enabled == true
    self:refresh_visibility()
end

function UpkeepSlot:refresh_visibility()
    local bound = self.did_text ~= nil
    self.placeholder:SetVisible(bound ~= true and self._move_mode == true)
    self:SetVisible(bound or self._move_mode == true)
end

function UpkeepSlot:update(now)
    if self.did_text == nil then
        return
    end

    self:refresh_cooldown()
    self:refresh_usable(now)

    local s = State.settings.self.upkeep

    local is_active = false
    local has_permanent = false
    local best_remaining = nil
    local best_duration = nil
    if self.active_count > 0 then
        for id, rec in pairs(self.active) do
            if rec.ending == nil then
                is_active = true
                has_permanent = true
            elseif rec.ending <= now then
                -- expired without an EffectRemoved event (server lag): prune
                self.active[id] = nil
                self.active_count = self.active_count - 1
            else
                is_active = true
                local remaining = rec.ending - now
                if best_remaining == nil or remaining > best_remaining then
                    best_remaining = remaining
                    best_duration = rec.duration
                end
            end
        end
    end

    local has_icon = self._icon_graphic ~= nil
    local time_text = ""
    local time_color = nil
    local drain_h = 0
    local shade_h = 0
    local icon_opacity = 1

    if is_active then
        local buff_fill = nil
        if best_remaining ~= nil then
            if s.show_time == true then
                time_text = lui_timed_row_format_time(best_remaining, s.time_format)
                time_color = s.active_text_color
            end
            if best_duration ~= nil then
                local ratio = best_remaining / best_duration
                if ratio > 1 then ratio = 1 end
                buff_fill = math.floor((self._size * ratio) + 0.5)
            end
        elseif has_permanent then
            -- toggle/permanent buff: full fill signals "running"
            buff_fill = self._size
        end

        if s.drain_enabled == true and buff_fill ~= nil then
            drain_h = buff_fill
        end

        -- optional: while the skill still recovers, the consumed part of
        -- the buff (the space above the drain) is shaded; the moment the
        -- cooldown ends the shade vanishes and only the drain remains
        local reset_time = self.reset_time
        if s.cd_shade == true and s.cd_during_active == true and
            buff_fill ~= nil and reset_time ~= nil and reset_time > now then
            shade_h = self._size - buff_fill
        end
    else
        local reset_time = self.reset_time
        if reset_time ~= nil and reset_time > now then
            if s.cd_shade == true then
                shade_h = self._size
            end
            if s.cd_transparent == true then
                -- the setting IS the icon's opacity on cooldown:
                -- 0.2 = heavily faded into the background
                icon_opacity = s.cd_transparent_opacity
                if icon_opacity < 0 then icon_opacity = 0 end
                if icon_opacity > 1 then icon_opacity = 1 end
            end
            if s.cd_show_time == true then
                time_text = lui_timed_row_format_time(reset_time - now, s.time_format)
                time_color = s.cooldown_text_color
            end
        elseif s.dim_unusable == true and self.usable ~= true then
            -- off cooldown but the game says it cannot be cast right now:
            -- faded, and with no countdown since there is nothing to count
            icon_opacity = s.unusable_opacity
            if icon_opacity < 0 then icon_opacity = 0 end
            if icon_opacity > 1 then icon_opacity = 1 end
        end
    end

    if has_icon ~= self._last_icon_visible then
        self._last_icon_visible = has_icon
        self.icon:SetVisible(has_icon)
    end

    if time_text ~= self._last_time_text then
        self._last_time_text = time_text
        self.time_label:SetText(time_text)
    end
    if time_color ~= nil and time_color ~= self._last_time_color then
        self._last_time_color = time_color
        self.time_label:SetForeColor(time_color)
    end
    if drain_h ~= self._last_drain_h then
        self._last_drain_h = drain_h
        if drain_h > 0 then
            self.drain:SetPosition(self._x, self._y + self._size - drain_h)
            self.drain:SetSize(self._size, drain_h)
            self.drain:SetVisible(true)
        else
            self.drain:SetVisible(false)
        end
    end
    if shade_h ~= self._last_shade_h then
        self._last_shade_h = shade_h
        if shade_h > 0 then
            -- anchored top, shrinking upward-to-done (the drain is
            -- anchored bottom, so the two fills stay distinguishable)
            self.shade:SetSize(self._size, shade_h)
            self.shade:SetVisible(true)
        else
            self.shade:SetVisible(false)
        end
    end
    if icon_opacity ~= self._last_icon_opacity then
        self._last_icon_opacity = icon_opacity
        -- window and content together, like DropEntry:set_opacity
        self.icon_window:SetOpacity(icon_opacity)
        self.icon:SetOpacity(icon_opacity)
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function UpkeepSlot:_reset_write_cache()
    self._last_icon_visible = nil
    self._last_time_text = nil
    self._last_time_color = nil
    self._last_drain_h = nil
    self._last_shade_h = nil
    self._last_icon_opacity = nil
end
