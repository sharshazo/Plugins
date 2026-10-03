-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Persistence = _G.LUI.Settings.Persistence
local Flags = _G.LUI.Runtime.Flags
local Stores = _G.LUI.Runtime.Stores
local State = _G.LUI.Settings.State
local Crafting = _G.LUI.Features.Crafting

import "LUI.src.Data.__init__"
import "LUI.src.Crafting.crafting_store"
import "LUI.src.Crafting.crafting_window"

local _shared_store = nil
local _tracked_plan_cache = nil
local _tracked_plan_autoload_after = nil

local function _is_enabled()
    return type(State.settings) == "table" and type(State.settings.crafting) == "table" and State.settings.crafting.enabled == true
end

local function _copy_tracked_plan_entries(entries)
    local out = {}
    if type(entries) ~= "table" then
        return out
    end

    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" then
            local count = math.floor((tonumber(entry.q) or 0) + 0.5)
            if entry.i ~= nil and count > 0 then
                out[#out + 1] = {
                    i = entry.i,
                    p = entry.p,
                    r = entry.r,
                    n = entry.n,
                    c = entry.c,
                    q = count,
                }
            end
        end
    end

    return out
end

local function _copy_favorite_entries(entries)
    local out = {}
    if type(entries) ~= "table" then
        return out
    end

    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" and entry.p ~= nil and entry.r ~= nil then
            out[#out + 1] = {
                i = entry.i,
                p = entry.p,
                r = entry.r,
                n = entry.n,
                c = entry.c,
            }
        end
    end

    return out
end

local function _current_character_settings()
    Persistence.ensure_character_settings()
    return State.character_settings
end

local function _character_crafting_settings()
    local character_settings = _current_character_settings()

    if type(character_settings.crafting) ~= "table" then
        character_settings.crafting = {}
    end
    return character_settings.crafting
end

local function _character_section_settings(section_key)
    local crafting = _character_crafting_settings()

    if type(crafting[section_key]) ~= "table" then
        crafting[section_key] = {}
    end
    local section = crafting[section_key]
    if type(section.entries) ~= "table" then
        section.entries = {}
    end

    return section
end

local function _tracked_plan_settings()
    return _character_section_settings("tracked_plan")
end

local function _favorite_settings()
    return _character_section_settings("favorites")
end

local function _tracked_plan_signature(entries)
    local parts = {}
    if type(entries) ~= "table" then
        return ""
    end
    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" then
            parts[#parts + 1] = table.concat({
                tostring(entry.i or ""),
                tostring(entry.p or ""),
                tostring(entry.r or ""),
                tostring(entry.n or ""),
                tostring(entry.c or ""),
                tostring(entry.q or ""),
            }, "\31")
        end
    end
    return table.concat(parts, "\30")
end

function Crafting.invalidate_tracked_plan_cache()
    _tracked_plan_cache = nil
end

function Crafting.is_enabled()
    return _is_enabled()
end

function Crafting.get_shared_store()
    if Flags.is_unloading == true or _is_enabled() ~= true then
        return nil
    end
    if _shared_store == nil then
        _shared_store = Crafting.CraftingStore()
        Stores.crafting = _shared_store
    end
    return _shared_store
end

function Crafting.destroy_shared_store()
    if _shared_store ~= nil then
        _shared_store:destroy()
    end
    _shared_store = nil
    Stores.crafting = nil
    _tracked_plan_autoload_after = nil
    Crafting.invalidate_tracked_plan_cache()
end

function Crafting.get_tracked_plan_entries()
    local tracked_plan = _tracked_plan_settings()
    return _copy_tracked_plan_entries(tracked_plan.entries)
end

function Crafting.set_tracked_plan_entries(entries, save_now)
    local tracked_plan = _tracked_plan_settings()

    tracked_plan.entries = _copy_tracked_plan_entries(entries)
    Crafting.invalidate_tracked_plan_cache()
    _tracked_plan_autoload_after = nil

    if save_now == true then
        Persistence.save_settings()
    end
end

function Crafting.get_favorite_recipe_entries()
    local favorites = _favorite_settings()
    return _copy_favorite_entries(favorites.entries)
end

function Crafting.set_favorite_recipe_entries(entries, save_now)
    local favorites = _favorite_settings()

    favorites.entries = _copy_favorite_entries(entries)

    if save_now == true then
        Persistence.save_settings()
    end
end

function Crafting.resolve_tracked_plan_entries(store)
    local entries = Crafting.get_tracked_plan_entries()
    if #entries <= 0 then
        return {
            entries = {},
            unresolved_count = 0,
            total_count = 0,
        }
    end

    local crafting_store = store or Stores.crafting
    if crafting_store == nil then
        return {
            entries = {},
            unresolved_count = #entries,
            total_count = #entries,
        }
    end

    local signature = _tracked_plan_signature(entries)
    local store_version = tonumber(crafting_store.version) or 0
    if type(_tracked_plan_cache) == "table" and _tracked_plan_cache.signature == signature and
        _tracked_plan_cache.store_version == store_version and _tracked_plan_cache.resolved ~= nil then
        return _tracked_plan_cache.resolved
    end

    local resolved = crafting_store:resolve_saved_plan_entries(entries)
    _tracked_plan_cache = {
        signature = signature,
        store_version = store_version,
        resolved = resolved,
    }
    return resolved
end

function Crafting.get_tracked_plan_resource_state(store)
    local entries = Crafting.get_tracked_plan_entries()
    local signature = _tracked_plan_signature(entries)
    if _is_enabled() ~= true then
        return {
            resources = {},
            incomplete_resources = {},
            ready = false,
            saved_entry_count = 0,
            unresolved_count = 0,
            total_entry_count = 0,
            loading = false,
            loading_loaded = 0,
            loading_total = 0,
            loading_complete = false,
        }
    end
    if #entries <= 0 then
        return {
            resources = {},
            incomplete_resources = {},
            ready = false,
            saved_entry_count = 0,
            unresolved_count = 0,
            total_entry_count = 0,
            loading = false,
            loading_loaded = 0,
            loading_total = 0,
            loading_complete = false,
        }
    end

    local crafting_store = store or Stores.crafting
    if store == nil and crafting_store == nil and Flags.is_unloading ~= true then
        local now = Turbine.Engine.GetGameTime()
        if _tracked_plan_autoload_after == nil then
            _tracked_plan_autoload_after = now + 1.50
        end
        if now >= _tracked_plan_autoload_after then
            crafting_store = Crafting.get_shared_store()
            _tracked_plan_autoload_after = nil
        end
    end

    if crafting_store == nil then
        return {
            resources = {},
            incomplete_resources = {},
            ready = false,
            saved_entry_count = #entries,
            unresolved_count = #entries,
            total_entry_count = #entries,
            loading = Flags.is_unloading ~= true,
            loading_loaded = 0,
            loading_total = 0,
            loading_complete = false,
        }
    end

    local store_version = tonumber(crafting_store.version) or 0
    if type(_tracked_plan_cache) == "table" and _tracked_plan_cache.signature == signature and
        _tracked_plan_cache.store_version == store_version and _tracked_plan_cache.resource_state ~= nil then
        return _tracked_plan_cache.resource_state
    end

    local resolved = Crafting.resolve_tracked_plan_entries(crafting_store)
    local resource_scope = crafting_store:scope_key_from_sources({ "backpack" })
    local resource_state = crafting_store:evaluate_plan_resources(resolved.entries, resource_scope)
    resource_state.saved_entry_count = #entries
    resource_state.unresolved_count = resolved.unresolved_count or 0
    resource_state.total_entry_count = resolved.total_count or #entries
    local progress = crafting_store:get_loading_progress()
    resource_state.loading = progress.loading == true
    resource_state.loading_loaded = tonumber(progress.loaded) or 0
    resource_state.loading_total = tonumber(progress.total) or 0
    resource_state.loading_complete = progress.complete == true

    _tracked_plan_cache = {
        signature = signature,
        store_version = store_version,
        resolved = resolved,
        resource_state = resource_state,
    }
    return resource_state
end
