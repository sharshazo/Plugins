-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local SearchQuery = _G.LUI.Utils.SearchQuery
local Coords = _G.LUI.Utils.Coords
local Lore = _G.LUI.Data.Lore
local BestiaryCache = _G.LUI.Runtime.Caches.Bestiary
local Persistence = _G.LUI.Settings.Persistence
local State = _G.LUI.Settings.State
local Locale = _G.LUI.Locale
local Encyclopedia = _G.LUI.Features.Encyclopedia
local Windows = _G.LUI.Runtime.Windows
local class = _G.LUI.Core.class

import "LUI.src.Utils.callbacks"
import "LUI.src.Utils.coords"
import "LUI.src.Utils.search_query"

local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
Encyclopedia.Collector = class()
Encyclopedia.current_location = Encyclopedia.current_location or nil

local DATA_ACCESS = Encyclopedia.DataAccess
-- Loot messages often arrive after the kill line and XP line, so keep a short
-- post-kill attribution window here. Adjust if the client/chat timing shifts.
local LOOT_POST_KILL_WINDOW_SECONDS = 0.10

local function _is_english_client()
    return Locale.is_english_language() == true
end

local function _trim(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function _is_bestiary_open()
    local window = Windows.encyclopedia
    return window ~= nil and window:IsVisible() == true
end

local function _build_location_filter_query(location)
    local parts = {}

    if type(location.region) == "string" and location.region ~= "" then
        parts[#parts + 1] = location.region
    end
    if type(location.area) == "string" and location.area ~= "" and location.area ~= location.region then
        parts[#parts + 1] = location.area
    end

    local query = SearchQuery.format_path(parts)
    if query == nil then
        error("Invalid bestiary location query path")
    end

    return query
end

function Encyclopedia.get_current_location()
    return Encyclopedia.current_location
end

function Encyclopedia.set_current_location(location)
    if type(location) ~= "table" then
        return
    end

    local region = _trim(location.region)
    if region == nil then
        return
    end

    local area = _trim(location.area)
    if area == region then
        area = nil
    end

    local current_location = {
        region = region,
        area = area,
        player_coords = location.player_coords,
        region_id = location.region_id,
    }
    local query = _build_location_filter_query(current_location)

    Encyclopedia.current_location = current_location
    BestiaryCache.area_filter_query = query

    local window = Windows.encyclopedia
    if window ~= nil then
        window:on_location_resolved()
    end
end

local function _apply_location_filter(location)
    Encyclopedia.set_current_location(location)
end

local function _to_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback or 0
    end

    return value
end

local function _normalize_bestiary_name(name)
    return DATA_ACCESS.normalize_name(name)
end

local function _ensure_bestiary_cache()
    return DATA_ACCESS.ensure_cache()
end

local function _touch_generation(name)
    BestiaryCache.generation = (BestiaryCache.generation or 0) + 1
    BestiaryCache.dirty = true
    -- names whose cache entry changed since consumers last rebuilt; the
    -- encyclopedia patches just these records instead of re-decoding the
    -- whole packed bestiary on every committed kill
    local dirty = BestiaryCache.dirty_names
    if dirty == nil then
        dirty = {}
        BestiaryCache.dirty_names = dirty
    end
    dirty[name] = true
end

local function _ensure_entry(name)
    name = _normalize_bestiary_name(name) or name
    name = DATA_ACCESS.resolve_builtin_name(name) or name
    local cache = _ensure_bestiary_cache()
    if type(cache[name]) ~= "table" then
        cache[name] = {
            levels = {},
            k = 0,
            d = {},
        }
    end

    local entry = cache[name]
    if type(entry.levels) ~= "table" then
        entry.levels = {}
    end
    if type(entry.d) ~= "table" then
        entry.d = {}
    end
    entry.k = _to_number(entry.k, 0)
    entry.lmin = nil
    entry.lmax = nil

    return entry, name
end

local function _strip_timestamp(message)
    if type(message) ~= "string" then
        return ""
    end

    return message:gsub("^%[%d%d/%d%d .-%]%s*", "")
end

local function _normalize_kill_name(name)
    return _normalize_bestiary_name(name)
end

local function _parse_kill_name(message)
    if type(message) ~= "string" or string.find(message, " defeated ", 1, true) == nil then
        return nil
    end

    local victim = message:match("^.- defeated the (.+)%.?$")
    if victim == nil then
        victim = message:match("^.- defeated (.+)%.?$")
    end

    return _normalize_kill_name(victim)
end

local function _parse_drop_name(message)
    local bracketed = nil
    local prefix_quantity = 1
    if string.find(message, "You have acquired:", 1, true) == 1 then
        bracketed = message:match("%b[]")
    elseif string.find(message, "Gathered ", 1, true) == 1
        and string.find(message, " into the ", 1, true) ~= nil then
        -- gathered lines carry the stack count outside the bracket
        -- ("Gathered 5 [Hides] into the ...")
        prefix_quantity = tonumber(message:match("^Gathered%s+(%d+)%s")) or 1
        bracketed = message:match("%b[]")
    end

    if bracketed == nil then
        return nil
    end

    local name = _trim(string.sub(bracketed, 2, -2))
    if name == nil then
        return nil
    end

    -- stacked drops print a plural display name with the count inside the
    -- bracket ("[5 Hides]") or, on gathered lines, in front of it; the
    -- shared resolver rewrites only what the DB confirms, so an item named
    -- with a leading number ("100 Virtue XP" is one item, not a stack) is
    -- never split, and the key matches what the drops window displays.
    -- This is the bestiary statistics DB only - the drops window shows
    -- every drop regardless. Before the Items DB is staged a stacked-
    -- looking name cannot be confirmed either way, so it is not recorded
    -- rather than persisting a junk key per stack size ("5 Hides").
    if Lore.Items.loaded ~= true then
        if prefix_quantity > 1 or name:match("^%d+%s") ~= nil then
            return nil
        end
        return name
    end

    return (Lore.Items.canonicalize_drop(name, prefix_quantity))
end

-- Chat-based kill/drop capture only: the target's morale/power cannot be
-- read reliably at selection time (entity data streams in late), so live
-- stat observation was dropped entirely - the packed wiki bestiary
-- already carries the morale/power ranges the cards display.
function Encyclopedia.Collector:Constructor()
    self.enabled = false
    self._cb_chat = nil
    self._pending_kills = {}
end

function Encyclopedia.Collector:is_enabled()
    local settings = State.settings
    if type(settings) ~= "table" or type(settings.encyclopedia) ~= "table" then
        return false
    end

    return settings.encyclopedia.bestiary_capture == true and _is_english_client() == true
end

function Encyclopedia.Collector:apply_settings()
    local should_enable = self:is_enabled()
    self.enabled = should_enable

    self:_bind()

    if should_enable ~= true then
        self:_flush_pending_kills(true)
    end
end

function Encyclopedia.Collector:save()
    self:_flush_pending_kills(true)
    Persistence.save_bestiary_cache()
end

function Encyclopedia.Collector:flush_expired()
    self:_flush_pending_kills(false)
end

function Encyclopedia.Collector:flush_pending()
    self:_flush_pending_kills(true)
end

function Encyclopedia.Collector:destroy()
    self:_flush_pending_kills(true)
    self:_unbind()
end

function Encyclopedia.Collector:_bind()
    if self._cb_chat == nil then
        self._cb_chat = add_callback(Turbine.Chat, "Received", function(_, args)
            self:_on_chat_received(args)
        end)
    end
end

function Encyclopedia.Collector:_unbind()
    if self._cb_chat ~= nil then
        remove_callback(Turbine.Chat, "Received", self._cb_chat)
        self._cb_chat = nil
    end
end

function Encyclopedia.Collector:_commit_kill(record)
    if type(record) ~= "table" then
        return
    end

    local name = _normalize_bestiary_name(record.name)
    if name == nil then
        return
    end

    local entry, entry_name = _ensure_entry(name)
    entry.k = _to_number(entry.k, 0) + 1

    for item_name, count in pairs(record.drops or {}) do
        if type(item_name) == "string" then
            entry.d[item_name] = _to_number(entry.d[item_name], 0) + _to_number(count, 0)
        end
    end

    _touch_generation(entry_name)
end

function Encyclopedia.Collector:_flush_pending_kills(flush_all)
    local now = Turbine.Engine.GetGameTime()
    while #self._pending_kills > 0 do
        local record = self._pending_kills[1]
        if flush_all ~= true and record ~= nil and (now - _to_number(record.at, now)) < LOOT_POST_KILL_WINDOW_SECONDS then
            break
        end

        table.remove(self._pending_kills, 1)
        self:_commit_kill(record)
    end
end

function Encyclopedia.Collector:_on_chat_received(args)
    if args.ChatType ~= Turbine.ChatType.Standard and
        args.ChatType ~= Turbine.ChatType.Death and
        args.ChatType ~= Turbine.ChatType.SelfLoot then
        return
    end

    local message = _strip_timestamp(args.Message)
    if message == "" then
        return
    end

    if args.ChatType == Turbine.ChatType.Standard then
        if _is_bestiary_open() == true then
            local location = Coords.resolve_location_from_chat(message)
            if location ~= nil then
                _apply_location_filter(location)
            end
        end
    end

    if self.enabled ~= true then
        return
    end

    if args.ChatType == Turbine.ChatType.Death then
        self:_flush_pending_kills(false)
        local kill_name = _parse_kill_name(message)
        if kill_name ~= nil then
            self._pending_kills[#self._pending_kills + 1] = {
                at = Turbine.Engine.GetGameTime(),
                name = kill_name,
                drops = {},
            }
            return
        end
    end

    if args.ChatType == Turbine.ChatType.SelfLoot then
        local item_name = _parse_drop_name(message)
        if item_name ~= nil and #self._pending_kills > 0 then
            self:_flush_pending_kills(false)
            local record = self._pending_kills[#self._pending_kills]
            if type(record) == "table" then
                record.drops[item_name] = _to_number(record.drops[item_name], 0) + 1
            end
        end
    end
end
