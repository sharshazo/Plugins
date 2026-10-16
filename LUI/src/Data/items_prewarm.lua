-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Background staging of the lore Items DB after login. The Drops window
-- (icons for carry-all loot) and the Encyclopedia item links read
-- Lore.Items but never import it themselves. A tiny pump waits until the
-- settings/session are up plus a short settle delay, then imports ONE
-- packed file per step (several MB each) so login never freezes on one
-- huge frame; the load_items finalizer then only wires cached imports.
-- The crafting store stages the same plan; imports are cached, so
-- whichever runs first pays each file once.

local Lore = _G.LUI.Data.Lore
import "Turbine.UI"

local START_DELAY = 3.0
local STEP_EVERY = 0.35

local ItemsPrewarm = {}
Lore.ItemsPrewarm = ItemsPrewarm

function ItemsPrewarm.start()
    if ItemsPrewarm._pump ~= nil or ItemsPrewarm._done == true then
        return
    end

    local pump = Turbine.UI.Control()
    pump:SetVisible(false)
    pump:SetWantsUpdates(true)
    local ready_at = nil
    local last_step = 0
    local plan = nil
    local index = 1

    local function finish()
        ItemsPrewarm._done = true
        pump:SetWantsUpdates(false)
        ItemsPrewarm._pump = nil
    end

    pump.Update = function()
        if _G.LUI.Runtime.Flags.is_unloading == true then
            pump:SetWantsUpdates(false)
            ItemsPrewarm._pump = nil
            return
        end
        -- wait for the settings/session to be up before doing any work
        if _G.LUI.Settings.State.settings == nil then
            return
        end
        local now = Turbine.Engine.GetGameTime()
        if ready_at == nil then
            ready_at = now + START_DELAY
        end
        if now < ready_at or (now - last_step) < STEP_EVERY then
            return
        end
        last_step = now

        if Lore.Items.loaded == true then
            finish()
            return
        end
        if plan == nil then
            plan = Lore.items_import_plan()
        end
        if index <= #plan then
            -- one file per step; a failed optional pack never repeats
            pcall(import, plan[index])
            index = index + 1
            return
        end
        -- one attempt only: a failed finalizer must never repeat every
        -- tick (the item tabs/crafting still load the domain on demand)
        pcall(Lore.load_items)
        finish()
    end
    ItemsPrewarm._pump = pump
end

ItemsPrewarm.start()
