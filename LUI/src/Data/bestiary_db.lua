-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Runtime access layer for the packed wiki bestiary (tools/lore2lua,
-- --db bestiary, source .data/lore/bestiary.json). Decoded entries reproduce
-- the raw source entry shape exactly
-- (n/bn/tl/v/g/s/sp/r/a/i/t/l/m/p/ce/rs/mi/ab/qi/di/w/cw), so the existing
-- data_access/window/card/tracker code consumes them unchanged. qi and di
-- are lists of quest/deed game ids (quests-domain id space); the other
-- lists are pool strings.
-- _G.LUI.Data.Bestiary.DB.en.bestiary becomes an __index proxy over this
-- module: point lookups by entry key work as before; full-table iteration
-- is served by count/key_at instead.

local Lore = _G.LUI.Data.Lore
import "Turbine.UI"

local byte = string.byte
local sub = string.sub
local find = string.find
local floor = math.floor

local function u(s, p, w)
    local v = 0
    for k = p, p + w - 1 do
        local b = byte(s, k)
        if b > 93 then
            v = v * 93 + (b - 34)
        else
            v = v * 93 + (b - 33)
        end
    end
    return v
end

Lore.Bestiary = Lore.Bestiary or {}
local Bestiary = Lore.Bestiary

local SCALARS = { "n", "bn", "tl", "v", "g", "s", "sp", "r", "a", "i", "t" }
local CE = { "f", "fm", "sm", "rt" }
local RS = { "cr", "so", "ta", "ph" }
local MI = { "co", "ad", "fi", "be", "li", "we", "sh", "fr", "lt" }
local LISTS = { "ab", "qi", "di", "w", "cw" }
local LIST_QI = 2 -- LISTS[2] = "qi": quest game ids, not pool refs
local LIST_DI = 3 -- LISTS[3] = "di": deed game ids, not pool refs

-- localized string pool: pool_<lang> mirrors pool.lua entry-for-entry with
-- translated strings where the packer had a game-data label (names stay
-- English by design). Optional localized pack, English fallback.
local function _import_pool()
    if Bestiary._pool_key ~= nil then
        return
    end
    local lang = Lore.language()
    if lang ~= "en" and pcall(import, "LUI.src.Data.Bestiary.pool_" .. lang) == true then
        Bestiary._pool_key = "Bestiary.pool_" .. lang
        return
    end
    import("LUI.src.Data.Bestiary.pool")
    Bestiary._pool_key = "Bestiary.pool"
end

function Lore.load_bestiary()
    if Bestiary.loaded == true then
        return
    end
    import("LUI.src.Data.Bestiary.manifest")
    _import_pool()
    import("LUI.src.Data.Bestiary.records")
    import("LUI.src.Data.Bestiary.index")
    import("LUI.src.Data.Bestiary.order_" .. Lore.language())
    local Data = _G.LoreData
    Bestiary.M = Data["Bestiary.manifest"]
    Bestiary.P = Data[Bestiary._pool_key]
    Bestiary.R = Data["Bestiary.records"]
    Bestiary.I = Data["Bestiary.index"]
    Bestiary.ORD = Data["Bestiary.order_" .. Lore.language()]
    Bestiary.count = Bestiary.M.count
    -- strong caches by design: query/open speed outranks memory here, and
    -- decoded entries are the bestiary window's working set
    Bestiary._entry_cache = {}
    Bestiary._group_cache = {}
    Bestiary.loaded = true
end

local function _pool_string(ref)
    local P = Bestiary.P
    local w = P.poff_width
    return sub(P.POOL, u(P.POFF, (ref - 1) * w + 1, w), u(P.POFF, ref * w + 1, w) - 1)
end

function Bestiary.key_at(ordinal)
    local R = Bestiary.R
    local w = Bestiary.M.koff_width
    return sub(R.KEYS, u(R.KOFF, (ordinal - 1) * w + 1, w), u(R.KOFF, ordinal * w + 1, w) - 1)
end

-- baked display-order permutation (order_<lang>, every language including
-- en): position i in the A-Z listing -> record ordinal. The record order
-- itself stays bytewise English key order, which the exact-key binary
-- search depends on, so listings never sort at runtime.
function Bestiary.display_ordinal(i)
    local ORD = Bestiary.ORD
    return u(ORD.ORD, (i - 1) * ORD.ord_width + 1, ORD.ord_width)
end

-- exact-key binary search over the sorted KEYS blob (bytewise, in place)
local function _ordinal_of_key(key)
    local R = Bestiary.R
    local kw = Bestiary.M.koff_width
    local key_len = #key
    local lo, hi = 1, Bestiary.count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local p = u(R.KOFF, (mid - 1) * kw + 1, kw)
        local q = u(R.KOFF, mid * kw + 1, kw)
        local entry_len = q - p

        local cmp = 0
        local limit = entry_len < key_len and entry_len or key_len
        for k = 1, limit do
            local be = byte(R.KEYS, p + k - 1)
            local bn = byte(key, k)
            if be ~= bn then
                cmp = be < bn and -1 or 1
                break
            end
        end
        if cmp == 0 and entry_len ~= key_len then
            cmp = entry_len < key_len and -1 or 1
        end

        if cmp == 0 then
            return mid
        elseif cmp < 0 then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

function Bestiary.decode(ordinal)
    local cached = Bestiary._entry_cache[ordinal]
    if cached ~= nil then
        return cached
    end

    local M = Bestiary.M
    local R = Bestiary.R
    local ref_w = M.ref_width
    local p = u(R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    local D = R.DATA

    local function take(w)
        local v = u(D, p, w)
        p = p + w
        return v
    end

    local entry = {}
    for k = 1, #SCALARS do
        local ref = take(ref_w)
        if ref > 0 then
            entry[SCALARS[k]] = _pool_string(ref)
        end
    end
    local widths = { M.l_width, M.m_width, M.p_width }
    local ranges = { "l", "m", "p" }
    for k = 1, 3 do
        local lo = take(widths[k])
        local hi = take(widths[k])
        if lo > 0 or hi > 0 then
            entry[ranges[k]] = { lo - 1, hi - 1 }
        end
    end
    local maps = { { "ce", CE }, { "rs", RS }, { "mi", MI } }
    for k = 1, 3 do
        local field, subs = maps[k][1], maps[k][2]
        local map = nil
        for si = 1, #subs do
            local ref = take(ref_w)
            if ref > 0 then
                if map == nil then
                    map = {}
                    entry[field] = map
                end
                map[subs[si]] = _pool_string(ref)
            end
        end
    end
    for k = 1, #LISTS do
        local n = take(1)
        if n > 0 then
            local list = {}
            if k == LIST_QI or k == LIST_DI then
                local id_base = M.di_base
                local id_w = k == LIST_QI and M.qi_width or M.di_width
                for li = 1, n do
                    list[li] = id_base + take(id_w)
                end
            else
                for li = 1, n do
                    list[li] = _pool_string(take(ref_w))
                end
            end
            entry[LISTS[k]] = list
        end
    end

    Bestiary._entry_cache[ordinal] = entry
    return entry
end

function Bestiary.get(key)
    Lore.load_bestiary()
    local ordinal = _ordinal_of_key(key)
    if ordinal == nil then
        return nil
    end
    return Bestiary.decode(ordinal)
end

-- lookup/group blobs: sorted "\n<lookup>\t<payload>" entries, searched with
-- the same in-place bytewise compare as the other domains
local function _blob_find(BLOB, OFF, off_w, entry_count, needle)
    local needle_len = #needle
    local lo, hi = 1, entry_count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local p = u(OFF, (mid - 1) * off_w + 1, off_w)
        local q = find(BLOB, "\t", p + 1, true)
        local entry_len = q - p - 1

        local cmp = 0
        local limit = entry_len < needle_len and entry_len or needle_len
        for k = 1, limit do
            local be = byte(BLOB, p + k)
            local bn = byte(needle, k)
            if be ~= bn then
                cmp = be < bn and -1 or 1
                break
            end
        end
        if cmp == 0 and entry_len ~= needle_len then
            cmp = entry_len < needle_len and -1 or 1
        end

        if cmp == 0 then
            return q
        elseif cmp < 0 then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

local function _lookup_ordinal(lowered)
    local I = Bestiary.I
    local q = _blob_find(I.LOOKUP, I.LOFF, Bestiary.M.loff_width, I.lookup_count, lowered)
    if q == nil then
        return nil
    end
    return u(I.LOOKUP, q + 1, Bestiary.M.ord_width)
end

local function _group_ordinals(base_lowered)
    local cached = Bestiary._group_cache[base_lowered]
    if cached ~= nil then
        return cached
    end
    local I = Bestiary.I
    local q = _blob_find(I.GROUPS, I.GOFF, Bestiary.M.goff_width, I.group_count, base_lowered)
    if q == nil then
        return nil
    end
    local ow = Bestiary.M.ord_width
    local e = find(I.GROUPS, "\n", q + 1, true)
    local ordinals, n = {}, 0
    for k = q + 1, e - 1, ow do
        n = n + 1
        ordinals[n] = u(I.GROUPS, k, ow)
    end
    Bestiary._group_cache[base_lowered] = ordinals
    return ordinals
end

-- ---- the shapes src/Encyclopedia/data_access.lua consumes -------------------

-- read-only proxy behaving like the old DB.en.bestiary table for point
-- lookups; full iteration must go through count/key_at
local SOURCE_PROXY = setmetatable({}, {
    __index = function(_, key)
        if type(key) ~= "string" then
            return nil
        end
        return Bestiary.get(key)
    end,
    __newindex = function()
        error("bestiary builtin DB is read-only")
    end,
})
Bestiary.source = SOURCE_PROXY

local KEYS_BY_LOWER_PROXY = setmetatable({}, {
    __index = function(_, lowered)
        if type(lowered) ~= "string" then
            return nil
        end
        Lore.load_bestiary()
        local ordinal = _lookup_ordinal(lowered)
        if ordinal == nil then
            return nil
        end
        return Bestiary.key_at(ordinal)
    end,
})

local FIRST_KEY_BY_BASE_PROXY = setmetatable({}, {
    __index = function(_, base_lowered)
        if type(base_lowered) ~= "string" then
            return nil
        end
        Lore.load_bestiary()
        local ordinals = _group_ordinals(base_lowered)
        if ordinals == nil then
            return nil
        end
        return Bestiary.key_at(ordinals[1])
    end,
})

local GROUP_KEYS_BY_BASE_PROXY = setmetatable({}, {
    __index = function(_, base_lowered)
        if type(base_lowered) ~= "string" then
            return nil
        end
        Lore.load_bestiary()
        local ordinals = _group_ordinals(base_lowered)
        if ordinals == nil then
            return nil
        end
        local keys = {}
        for k = 1, #ordinals do
            keys[k] = Bestiary.key_at(ordinals[k])
        end
        return keys
    end,
})

local BUILTIN_INDEX = nil

function Bestiary.builtin_index()
    if BUILTIN_INDEX == nil then
        Lore.load_bestiary()
        BUILTIN_INDEX = {
            source = SOURCE_PROXY,
            keys_by_lower = KEYS_BY_LOWER_PROXY,
            aliases_by_lower = Bestiary.M.aliases,
            first_key_by_base_lower = FIRST_KEY_BY_BASE_PROXY,
            group_keys_by_base_lower = GROUP_KEYS_BY_BASE_PROXY,
        }
    end
    return BUILTIN_INDEX
end

-- ---- background pre-warm -------------------------------------------------
-- Opening the bestiary must never pay the decode of 12k entries: a tiny
-- pump imports the blobs and decodes everything into the strong cache in
-- small batches during idle ticks after login. One import or one batch per
-- tick; self-stops when done or at unload.

local PREWARM_BATCH = 300
local PREWARM_EVERY = 0.2

local IMPORT_PLAN = {
    function() import("LUI.src.Data.Bestiary.manifest") end,
    _import_pool,
    function() import("LUI.src.Data.Bestiary.records") end,
    function() import("LUI.src.Data.Bestiary.index") end,
    function() import("LUI.src.Data.Bestiary.order_" .. Lore.language()) end,
}

-- Packed-file imports are instant (local data, no game calls), so the
-- whole lore stack loads up front on the first tick; only the bestiary
-- record decode is spread across ticks. Slow staged loading is reserved
-- for data sourced from live game API calls (e.g. the crafting store).
function Bestiary.prewarm_step()
    if Bestiary.loaded ~= true then
        for i = 1, #IMPORT_PLAN do
            IMPORT_PLAN[i]()
        end
        Lore.load_bestiary()

        local lang = Lore.language()
        import("LUI.src.Data.Npcs.manifest")
        import("LUI.src.Data.Npcs.records")
        import("LUI.src.Data.Npcs.labels_" .. lang)
        Lore.load_npcs()

        local items_plan = Lore.items_import_plan()
        for i = 1, #items_plan do
            import(items_plan[i])
        end
        Lore.load_items()
        return false
    end

    local next_ordinal = Bestiary._prewarm_next or 1
    if next_ordinal <= Bestiary.count then
        local last = next_ordinal + PREWARM_BATCH - 1
        if last > Bestiary.count then
            last = Bestiary.count
        end
        for ordinal = next_ordinal, last do
            Bestiary.decode(ordinal)
        end
        Bestiary._prewarm_next = last + 1
        return false
    end
    return true
end

function Bestiary.start_prewarm()
    if Bestiary._prewarm_pump ~= nil or Bestiary._prewarm_done == true then
        return
    end

    local pump = Turbine.UI.Control()
    pump:SetVisible(false)
    pump:SetWantsUpdates(true)
    local last_step = 0
    pump.Update = function()
        if _G.LUI.Runtime.Flags.is_unloading == true then
            pump:SetWantsUpdates(false)
            Bestiary._prewarm_pump = nil
            return
        end
        -- wait for the settings/session to be up before doing any work
        if _G.LUI.Settings.State.settings == nil then
            return
        end
        local now = Turbine.Engine.GetGameTime()
        if (now - last_step) < PREWARM_EVERY then
            return
        end
        last_step = now
        if Bestiary.prewarm_step() == true then
            Bestiary._prewarm_done = true
            pump:SetWantsUpdates(false)
            Bestiary._prewarm_pump = nil
        end
    end
    Bestiary._prewarm_pump = pump
end

-- register the proxy where the legacy in-plugin bestiary table used to live
_G.LUI.Data.Bestiary.DB = _G.LUI.Data.Bestiary.DB or {}
local DB = _G.LUI.Data.Bestiary.DB
DB.en = DB.en or {}
DB.en.bestiary = SOURCE_PROXY

Bestiary.start_prewarm()
