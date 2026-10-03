-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Upkeep = _G.LUI.Features.Upkeep
local Lore = _G.LUI.Data.Lore
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.Data.lore_db"
import "LUI.src.Upkeep.skill_lookup"
import "LUI.src.Upkeep.upkeep_slot"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.callbacks"
import "LUI.src.Vitals.target_effect_manager"

local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local Vitals = _G.LUI.Features.Vitals

-- The Upkeep bar: a pure tracker for maintenance buffs, one drawn skill
-- icon per slot (never a quickslot; native quickslot rendering neither
-- scales/aligns cleanly nor alpha-blends with decorations). The skills DB
-- (Lore.Skills) resolves each bound skill DID to the localized buff names
-- it applies; effects on the player (or on the target, for Target-mode
-- slots) are matched by those names, cooldowns come live from the trained
-- ActiveSkill.
--
-- Both inputs are polled on this window's own tick, the way the expiring
-- effect bars read GetEffects(), and nothing is subscribed to. The bar
-- therefore stands entirely on its own: it needs no other feature enabled,
-- and it cannot be left dead by an input that was not ready at load time.
--
-- Zoomed (stretched) icons render above every control in their own window
-- but below other windows, so the slot decorations (drain, shade, timer)
-- live in a companion overlay window kept just above the HUD, in true
-- pixels. Order is held with the Activate() pattern, never window ZOrder.
local UpkeepWindow = class(UI.Widgets.LuiHUD)
Upkeep.UpkeepWindow = UpkeepWindow

local SKILL_DISCOVER_EVERY = 30.0

local UpkeepOverlay = class(UI.Widgets.LuiBaseWindow)

function UpkeepOverlay:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })

    self:SetVisible(false)
    self:SetMouseVisible(false)
end

function UpkeepOverlay:destroy()
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function UpkeepWindow:Constructor()
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "upkeep",
        title = TR["Upkeep"],
    })

    self.slots = {}
    self._capacity = 0
    self._bound_count = 0
    -- localized buff name -> array of slot indexes watching it; Self-mode
    -- slots watch the player's effects, Target-mode slots the target's
    self._watch = {}
    self._watch_target = {}
    -- precomputed so nothing target-related runs without a Target-mode slot
    self._watch_target_any = false
    -- shared TargetEffectManager for the current target, held only while a
    -- Target-mode slot exists (see _sync_target_manager)
    self._target_em = nil
    self._target_em_added = nil
    -- auto-order working buffers (slot index per display position)
    self._display_order = {}
    self._order_buf = {}
    self._urgency_buf = {}
    self._rank_buf = {}
    -- urgencies all count down at the same rate, so the sort order can
    -- only change on discrete events (effect added/removed, cooldown
    -- reset time changed); those mark it dirty via invalidate_order()
    self._order_dirty = true
    -- built once so table.sort does not allocate a fresh closure per
    -- re-sort; reads the buffers in place (they are never reassigned)
    local urgency = self._urgency_buf
    local rank = self._rank_buf
    self._order_compare = function(a, b)
        if urgency[a] ~= urgency[b] then
            return urgency[a] < urgency[b]
        end
        return rank[a] < rank[b]
    end
    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate
    self._skill_discover_due_at = 0
    -- bumped once per effect poll; slots stamp what they saw with it
    self._effect_gen = 0

    self:SetWantsUpdates(true)
    self:SetVisible(false)
    self:SetMouseVisible(false)

    self.overlay = UpkeepOverlay()
    add_callback(self, "PositionChanged", function()
        self:_sync_companion_positions()
    end)
    -- keep the companions above the HUD when the HUD gets activated
    -- (move-mode clicks); they are mouse-invisible and can never steal
    -- activation themselves
    add_callback(self, "Activated", function()
        self:_raise_companions()
    end)

    -- retarget signal for Target-mode slots, same pattern as the vitals
    -- windows; the handler is a no-op while no slot watches the target
    self._lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    self._cb_target_changed = add_callback(self._lp, "TargetChanged", function()
        if self._watch_target_any then
            self:_sync_target_manager()
        end
    end)

    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

function UpkeepWindow:destroy()
    remove_callback(self._lp, "TargetChanged", self._cb_target_changed)
    self._cb_target_changed = nil
    self:_release_target_manager()
    for i = 1, #self.slots do
        self.slots[i]:destroy()
    end
    self.overlay:destroy()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self:SetParent(nil)
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function UpkeepWindow:get_settings()
    return State.settings.self.upkeep
end

-- an urgency input changed (effect set, cooldown reset time); auto order
-- re-sorts on the next tick
function UpkeepWindow:invalidate_order()
    self._order_dirty = true
end

function UpkeepWindow:set_move_mode(enabled)
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    for i = 1, self._capacity do
        self.slots[i]:set_move_mode(enabled == true)
    end
    self:refresh_visibility()
end

function UpkeepWindow:apply_settings()
    self:apply_native_scaling()

    local s = self:get_settings()
    self.update_every = 1.0 / State.settings.global.refresh_rate

    self:apply_hud_position()

    local count = s.count
    local size = s.icon_size
    local spacing = s.spacing
    local vertical = s.orientation == LUI_ENUMS.orientation.VERTICAL

    local main = (count * size) + ((count - 1) * spacing)
    if vertical then
        self:SetSize(size, main)
        self.overlay:SetSize(size, main)
    else
        self:SetSize(main, size)
        self.overlay:SetSize(main, size)
    end
    self:layout_move_chrome()

    for i = 1, count do
        if self.slots[i] == nil then
            local slot = Upkeep.UpkeepSlot(self.overlay, self)
            slot:SetParent(self)
            slot:SetVisible(false)
            self.slots[i] = slot
        end
    end
    -- surplus slots from a lowered count: unbind fully and hide
    for i = count + 1, #self.slots do
        self.slots[i]:set_skill(nil)
        self.slots[i]:set_binding(nil, nil)
        self.slots[i]:set_move_mode(false)
        self.slots[i]:SetVisible(false)
    end
    self._capacity = count

    self._watch = {}
    self._watch_target = {}
    self._bound_count = 0
    local move_mode = self:is_move_mode()
    for i = 1, count do
        local slot = self.slots[i]
        slot:apply_settings()
        self:_place_slot(slot, i)
        -- invalidate the cached order so auto order re-places (with its
        -- anchor applied) on the next tick
        self._display_order[i] = 0

        local did_text = s.slots[i]
        local record = nil
        if type(did_text) ~= "string" or tonumber(did_text) == nil then
            did_text = nil
        else
            record = Lore.Skills.buffs_of(tonumber(did_text))
        end
        slot:set_binding(did_text, record)
        slot:set_move_mode(move_mode)

        if did_text ~= nil then
            self._bound_count = self._bound_count + 1
            if record ~= nil then
                local watch = self._watch
                if s.slot_modes[i] == LUI_ENUMS.upkeep_track.TARGET then
                    watch = self._watch_target
                end
                local effects = record.effects
                for k = 1, #effects do
                    local name = effects[k].name
                    local bucket = watch[name]
                    if bucket == nil then
                        bucket = {}
                        watch[name] = bucket
                    end
                    bucket[#bucket + 1] = i
                end
            end
        end
    end
    self._watch_target_any = next(self._watch_target) ~= nil
    self:_sync_target_manager()

    self:_sync_companion_positions()
    self:_discover_skills(true)
    -- _poll_effects invalidates the auto order, no separate call needed
    self:_poll_effects(Turbine.Engine.GetGameTime())
    self:refresh_visibility()
end

function UpkeepWindow:refresh_visibility()
    local s = self:get_settings()
    local move_mode = self:is_move_mode()
    local show = s.enabled == true and (self._bound_count > 0 or move_mode)
    self:SetVisible(show)
    -- in move mode the companions would draw over the move chrome; the
    -- placeholders in the HUD show the footprint while dragging
    local companions_show = show and move_mode ~= true
    local was_visible = self.overlay:IsVisible() == true
    self.overlay:SetVisible(companions_show)
    for i = 1, self._capacity do
        self.slots[i]:sync_shown(companions_show)
    end
    if companions_show and was_visible ~= true then
        self:_raise_companions()
    end
end

function UpkeepWindow:Update()
    local s = self:get_settings()
    if s.enabled ~= true then
        self:refresh_visibility()
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    if now >= (self._skill_discover_due_at or 0) then
        self:_discover_skills(false)
    end

    if self:is_move_mode() == true then
        return
    end

    self:_poll_effects(now)

    for i = 1, self._capacity do
        self.slots[i]:update(now)
    end

    if s.auto_order == true and self._order_dirty == true then
        self:_apply_auto_order(now)
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

-- cell geometry for one display position (1-based, from the start of the bar)
function UpkeepWindow:_place_slot(slot, position)
    local s = self:get_settings()
    local offset = (position - 1) * (s.icon_size + s.spacing)
    if s.orientation == LUI_ENUMS.orientation.VERTICAL then
        slot:place(0, offset)
    else
        slot:place(offset, 0)
    end
end

-- auto order: sort the slots by urgency (next skill to reactivate first)
-- and re-place them when the order changes; the anchor picks which end of
-- the bar holds the most urgent slot. Runs only on ticks where an urgency
-- input changed (see invalidate_order), never on quiet ticks.
function UpkeepWindow:_apply_auto_order(now)
    self._order_dirty = false
    local count = self._capacity
    local order = self._order_buf
    local urgency = self._urgency_buf
    local rank = self._rank_buf
    for i = 1, count do
        order[i] = i
        urgency[i] = self.slots[i]:urgency(now)
        rank[i] = i
    end
    for i = count + 1, #order do
        order[i] = nil
        urgency[i] = nil
        rank[i] = nil
    end
    -- ties keep their current on-screen position instead of snapping to
    -- binding order, so ready slots (urgency 0) don't reshuffle as each
    -- cooldown ends; right after apply_settings the cached order is
    -- invalidated (all 0) and the rank falls back to the slot index
    for k = 1, count do
        local slot_index = self._display_order[k]
        if slot_index ~= 0 then
            rank[slot_index] = k
        end
    end
    table.sort(order, self._order_compare)

    local changed = false
    for k = 1, count do
        if self._display_order[k] ~= order[k] then
            changed = true
            break
        end
    end
    if changed ~= true then
        return
    end

    local reverse = self:get_settings().auto_order_anchor == LUI_ENUMS.side.RIGHT
    for k = 1, count do
        self._display_order[k] = order[k]
        local position = reverse and (count - k + 1) or k
        self:_place_slot(self.slots[order[k]], position)
    end
    self:_sync_companion_positions()
end

-- the icon windows sit at the HUD position plus their cell offset; the
-- decoration overlay covers the whole bar
function UpkeepWindow:_sync_companion_positions()
    local x, y = self:GetPosition()
    self.overlay:SetPosition(x, y)
    for i = 1, self._capacity do
        local slot = self.slots[i]
        slot.icon_window:SetPosition(x + slot._x, y + slot._y)
    end
end

-- layering bottom-up: HUD, then the icon windows, then the decoration
-- overlay; held with the Activate() pattern (never window ZOrder)
function UpkeepWindow:_raise_companions()
    for i = 1, self._capacity do
        local slot = self.slots[i]
        if slot.icon_window:IsVisible() == true then
            slot.icon_window:Activate()
        end
    end
    if self.overlay:IsVisible() == true then
        self.overlay:Activate()
    end
end

-- One pass over the player's effects -- and the target's when a slot watches
-- the target -- matching watched buff names to the slots that want them.
--
-- The player's own list is read fresh every tick like the expiring effect
-- bars do: that works for the LOCAL PLAYER ONLY, and the list does not exist
-- yet at plugin load, so a subscription taken once in the constructor would
-- stay dead for the whole session. Target effects instead come from the
-- shared TargetEffectManager (see _sync_target_manager): its reconciled map
-- replaces the raw list, and the same gen/prune pass runs over it.
--
-- Only the name is read for effects nobody watches; duration and start time
-- are read for matches only.
function UpkeepWindow:_poll_effects(now)
    local gen = self._effect_gen + 1
    self._effect_gen = gen
    local changed = false

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player ~= nil and player.GetEffects ~= nil then
        if self:_sweep_effects(player:GetEffects(), self._watch, now, gen) then
            changed = true
        end
    end

    local em = self._target_em
    if em ~= nil then
        -- drives the manager's ghost sweep and its refetch-after-remove
        em:poll()
        if self:_sweep_manager_effects(em.effects, self._watch_target, now, gen) then
            changed = true
        end
    end

    for i = 1, self._capacity do
        if self.slots[i]:prune_active(gen) then
            changed = true
        end
    end

    if changed then
        self:invalidate_order()
    end
end

function UpkeepWindow:_sweep_effects(list, watch, now, gen)
    if list == nil or list.GetCount == nil then
        return false
    end

    local changed = false
    local slots = self.slots
    for i = 1, (list:GetCount() or 0) do
        local effect = list:Get(i)
        if effect ~= nil and effect.GetName ~= nil then
            local targets = watch[effect:GetName()]
            if targets ~= nil then
                for k = 1, #targets do
                    if slots[targets[k]]:mark_active(effect, now, gen) then
                        changed = true
                    end
                end
            end
        end
    end
    return changed
end

-- the manager-map twin of _sweep_effects: entries are id -> { effect }
function UpkeepWindow:_sweep_manager_effects(effects, watch, now, gen)
    local changed = false
    local slots = self.slots
    for _, entry in pairs(effects) do
        local effect = entry.effect
        if effect ~= nil and effect.GetName ~= nil then
            local targets = watch[effect:GetName()]
            if targets ~= nil then
                for k = 1, #targets do
                    if slots[targets[k]]:mark_active(effect, now, gen) then
                        changed = true
                    end
                end
            end
        end
    end
    return changed
end

function UpkeepWindow:_release_target_manager()
    if self._target_em == nil then
        return
    end
    self._target_em:unregister_added_event(self._target_em_added)
    self._target_em_added = nil
    -- acquiring flipped a shared background manager (group member, pet) to
    -- live player:GetTarget() mode; hand it back to its background entity
    -- before dropping the reference, or it keeps following the player's
    -- target for its remaining holders (same order as target vitals)
    self._target_em:restore_background_source_target()
    self._target_em:delete()
    self._target_em = nil
end

-- Target effects go through the shared TargetEffectManager, NEVER through a
-- raw GetEffects() read on the target: non-player effect lists only behave
-- through the manager's single held instance (removals ghost, the instance
-- dies on every remove/clear -- see target_effect_manager.lua), and any
-- GetEffects() call from outside while a manager runs on that entity can
-- break it. This function therefore only checks that the METHOD exists
-- (capability probe, no call) and hands the entity to acquire(); the manager
-- is the sole reader of the list. Re-synced on TargetChanged and on settings
-- apply; released whenever no Target-mode slot needs it.
function UpkeepWindow:_sync_target_manager()
    self:_release_target_manager()
    -- held only while the bar actually consumes it: a disabled bar (or one
    -- with no Target-mode slot) must not keep re-acquiring on retargets
    if self:get_settings().enabled ~= true or self._watch_target_any ~= true then
        return
    end

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetTarget == nil then
        return
    end
    local target = player:GetTarget()
    if target == nil or target.GetEffects == nil then
        return
    end
    -- targeting yourself: the manager exists for OTHER entities only (same
    -- name check as target vitals), so Target-mode slots see no effects and
    -- read as ready -- you cannot reapply a debuff to yourself anyway
    if target.GetName ~= nil and player.GetName ~= nil and
        target:GetName() == player:GetName() then
        return
    end

    self._target_em = Vitals.TargetEffectManager.acquire(player, target)
    -- registering the added event snapshots the target's current effects
    -- into the manager's map; the per-tick sweep reads the map directly, so
    -- the callback itself has nothing left to do. Kept in a local because
    -- register_added_event returns nothing when the manager's effect list
    -- is not up yet -- unregistering by our own reference always works.
    local added = function() end
    self._target_em:register_added_event(added)
    self._target_em_added = added
end

function UpkeepWindow:_discover_skills(force)
    local now = Turbine.Engine.GetGameTime()
    if force ~= true and now < (self._skill_discover_due_at or 0) then
        return
    end
    self._skill_discover_due_at = now + SKILL_DISCOVER_EVERY

    -- localized skill name (from the skills DB) -> slot indexes to resolve
    local wanted = {}
    local wanted_any = false
    for i = 1, self._capacity do
        local record = self.slots[i].binding
        if record ~= nil then
            local bucket = wanted[record.name]
            if bucket == nil then
                bucket = {}
                wanted[record.name] = bucket
                wanted_any = true
            end
            bucket[#bucket + 1] = i
        end
    end

    local found = {}
    if wanted_any then
        local player = Turbine.Gameplay.LocalPlayer.GetInstance()
        if player ~= nil and player.GetTrainedSkills ~= nil then
            local list = player:GetTrainedSkills()
            if list ~= nil and list.GetCount ~= nil and list.GetItem ~= nil then
                for i = 1, (list:GetCount() or 0) do
                    local skill = list:GetItem(i)
                    if skill ~= nil and skill.GetSkillInfo ~= nil and skill.GetResetTime ~= nil then
                        local info = skill:GetSkillInfo()
                        if info ~= nil and info.GetName ~= nil then
                            local bucket = wanted[info:GetName()]
                            if bucket ~= nil then
                                for k = 1, #bucket do
                                    local slot_index = bucket[k]
                                    found[slot_index] = Upkeep.prefer_trained_skill(
                                        found[slot_index], skill, now)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for i = 1, self._capacity do
        self.slots[i]:set_skill(found[i])
    end
end
