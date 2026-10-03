-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Runtime access layer for the generated lore databases (tools/lore2lua).
-- Domains import their packed-string files on first load_*() call; nothing
-- is imported at plugin load. Decoding is offset arithmetic over the blobs.

local Lore = _G.LUI.Data.Lore

local byte = string.byte
local sub = string.sub
local find = string.find
local floor = math.floor

-- base-93 decode: w chars at 1-based position p
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

function Lore.language()
    if Lore._language == nil then
        -- same client-language detection the rest of LUI uses
        local code = _G.LUI.Locale.language_code()
        -- Spanish only translates LUI's own interface (menus/options). The
        -- data library (items, recipes, bestiary, quests...) stays in
        -- English on purpose -- player's request: "la biblioteca de
        -- busqueda debe ser en ingles; buscamos en español y salen los
        -- nombres en ingles". Items.load keeps the Spanish search pack as a
        -- second probe for exactly that (see the Items.S_EXTRA note below).
        -- Also required for safety: several domains ship no _es files
        -- (Quests: only de/en/fr), so importing them in "es" would fail.
        if code == "es" then
            code = "en"
        end
        Lore._language = code
    end
    return Lore._language
end

local function _bsearch_id(IDS, id_width, count, target)
    local lo, hi = 1, count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local v = u(IDS, (mid - 1) * id_width + 1, id_width)
        if v == target then
            return mid
        elseif v < target then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

-- name -> ordinals over a sorted name/offset index; nil means "not in DB".
-- The index is sorted bytewise, so the probe compares bytes in place: no
-- substring allocation per probe, and Lua 5.1's `<` (locale strcoll) is
-- never trusted for the ordering.
local function _find_in_index(blob, OFF, nw, entry_count, ow, name)
    local name_len = #name
    local lo, hi = 1, entry_count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local p = u(OFF, (mid - 1) * nw + 1, nw)
        local q = find(blob, "\t", p + 1, true)
        local entry_len = q - p - 1

        local cmp = 0
        local limit = entry_len < name_len and entry_len or name_len
        for k = 1, limit do
            local be = byte(blob, p + k)
            local bn = byte(name, k)
            if be ~= bn then
                cmp = be < bn and -1 or 1
                break
            end
        end
        if cmp == 0 and entry_len ~= name_len then
            cmp = entry_len < name_len and -1 or 1
        end

        if cmp == 0 then
            local res, n = {}, 0
            local e = find(blob, "\n", q + 1, true)
            for k = q + 1, e - 1, ow do
                n = n + 1
                res[n] = u(blob, k, ow)
            end
            return res
        elseif cmp < 0 then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

local function _find_ordinals(NM, name)
    return _find_in_index(NM.NAME, NM.NOFF, NM.noff_width, NM.entry_count,
        NM.ord_width, name)
end

-- Ordered package list for everything the crafting domains need. Consumers
-- that must not hitch import these one per frame (Turbine caches imports, so
-- the load_* finalizers below re-import for free afterwards); standalone
-- consumers may skip straight to load_recipes()/load_items().
function Lore.import_plan()
    local lang = Lore.language()
    return {
        "LUI.src.Data.Recipes.manifest",
        "LUI.src.Data.Recipes.records",
        "LUI.src.Data.Recipes.labels_" .. lang,
        "LUI.src.Data.Recipes.names_" .. lang,
        "LUI.src.Data.Recipes.categories",
        "LUI.src.Data.Items.manifest",
        "LUI.src.Data.Items.records",
        "LUI.src.Data.Items.labels_" .. lang,
    }
end

function Lore.import_step(package_name)
    import(package_name)
end

-- the Items files are the heavy ones (records + labels + name index +
-- search + buckets, several MB each); consumers stage exactly these across
-- ticks so the load_items finalizer only wires already-imported files.
-- Empty once the domain is loaded, so every staging driver skips for free.
function Lore.items_import_plan()
    if Lore.Items.loaded == true then
        return {}
    end
    local lang = Lore.language()
    return {
        "LUI.src.Data.Items.manifest",
        "LUI.src.Data.Items.records",
        "LUI.src.Data.Items.labels_" .. lang,
        "LUI.src.Data.Items.names_" .. lang,
        "LUI.src.Data.Items.classes",
        "LUI.src.Data.Items.buckets_" .. lang,
        "LUI.src.Data.Items.search_" .. lang,
    }
end

-- ------------------------------------------------------------- Recipes ----

Lore.Recipes = Lore.Recipes or {}
local Recipes = Lore.Recipes

function Lore.load_recipes()
    if Recipes.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Recipes.manifest")
    import("LUI.src.Data.Recipes.records")
    import("LUI.src.Data.Recipes.labels_" .. lang)
    import("LUI.src.Data.Recipes.names_" .. lang)
    import("LUI.src.Data.Recipes.categories")
    local Data = _G.LoreData
    Recipes.M = Data["Recipes.manifest"]
    Recipes.R = Data["Recipes.records"]
    Recipes.L = Data["Recipes.labels_" .. lang]
    Recipes.NM = Data["Recipes.names_" .. lang]
    Recipes.CATS = Data["Recipes.categories"].CATS[lang]
    Recipes.PROFS = Data["Recipes.categories"].PROFS[lang]
    -- Spanish recipe names, kept aside as an extra Crafting search key
    -- (display stays in `lang`, same reasoning as Items.L_ES above)
    if lang ~= "es" then
        local ok_l = pcall(import, "LUI.src.Data.Recipes.labels_es")
        if ok_l == true then
            Recipes.L_ES = Data["Recipes.labels_es"]
        end
    end
    Recipes.count = Recipes.M.count
    Recipes.profession_codes = {}
    for code = 1, #Recipes.M.enums.profession do
        Recipes.profession_codes[Recipes.M.enums.profession[code]] = code
    end
    Recipes.loaded = true
end

function Recipes.find_ordinals(name)
    return _find_ordinals(Recipes.NM, name)
end

function Recipes.id_of(ordinal)
    local M = Recipes.M
    return u(Recipes.R.IDS, (ordinal - 1) * M.id_width + 1, M.id_width) + M.base_id
end

-- header probes: read one field without decoding the record
function Recipes.profession_code(ordinal)
    local M = Recipes.M
    local p = u(Recipes.R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    return u(Recipes.R.DATA, p, M.widths.profession)
end

function Recipes.tier_of(ordinal)
    local M = Recipes.M
    local p = u(Recipes.R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    return u(Recipes.R.DATA, p + M.widths.profession, M.widths.tier)
end

function Recipes.label(ordinal)
    local L = Recipes.L
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

-- Spanish recipe name, or nil when the Spanish pack isn't loaded - extra
-- search key only, never used for display (see Recipes.label).
function Recipes.label_es(ordinal)
    local L = Recipes.L_ES
    if L == nil then
        return nil
    end
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

function Recipes.category_name(code)
    local name = Recipes.CATS[code]
    if name == nil then
        return ""
    end
    return name
end

function Recipes.profession_name(key)
    return Recipes.PROFS[key]
end

function Recipes.decode(ordinal)
    local M = Recipes.M
    local R = Recipes.R
    local W = M.widths
    local D = R.DATA
    local IB = M.item_base
    local p = u(R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    local function take(w)
        local v = u(D, p, w)
        p = p + w
        return v
    end
    local rec = {}
    rec.id = u(R.IDS, (ordinal - 1) * M.id_width + 1, M.id_width) + M.base_id
    rec.profession = M.enums.profession[take(W.profession)]
    rec.tier = take(W.tier)
    rec.category = take(W.category)
    rec.xp = take(W.xp)
    rec.cooldown = take(W.cooldown)
    local flags = take(W.flags)
    rec.guild = flags % 2 == 1
    rec.single_use = flags % 4 >= 2
    rec.conversion = flags >= 4
    local scroll = take(W.item)
    if scroll > 0 then
        rec.scroll = scroll + IB
    end
    local pack = take(W.item)
    if pack > 0 then
        rec.pack = pack + IB
    end
    rec.pack_count = take(W.pack_count)
    rec.versions = {}
    for vi = 1, take(W.n) do
        local version = {
            crit = take(W.crit),
            ingredients = {},
            optionals = {},
            results = {},
            crit_results = {},
        }
        local ni, no, nr, nc = take(W.n), take(W.n), take(W.n), take(W.n)
        for k = 1, ni do
            version.ingredients[k] = { take(W.item) + IB, take(W.qty) }
        end
        for k = 1, no do
            version.optionals[k] = { take(W.item) + IB, take(W.qty), take(W.bonus) }
        end
        for k = 1, nr do
            version.results[k] = { take(W.item) + IB, take(W.qty) }
        end
        for k = 1, nc do
            version.crit_results[k] = { take(W.item) + IB, take(W.qty) }
        end
        rec.versions[vi] = version
    end
    return rec
end

-- --------------------------------------------------------------- Items ----

Lore.Items = Lore.Items or {}
local Items = Lore.Items

-- one-shot listeners fired when the Items domain finishes loading (an
-- already-loaded registration fires immediately); UI surfaces use this to
-- refresh probes that reported "not yet" while the domain was staging
Items._on_loaded = {}

function Items.notify_loaded(callback)
    if Items.loaded == true then
        callback()
        return
    end
    Items._on_loaded[#Items._on_loaded + 1] = callback
end

function Lore.load_items()
    if Items.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Items.manifest")
    import("LUI.src.Data.Items.records")
    import("LUI.src.Data.Items.labels_" .. lang)
    import("LUI.src.Data.Items.names_" .. lang)
    import("LUI.src.Data.Items.classes")
    import("LUI.src.Data.Items.buckets_" .. lang)
    import("LUI.src.Data.Items.search_" .. lang)
    local Data = _G.LoreData
    Items.M = Data["Items.manifest"]
    Items.R = Data["Items.records"]
    Items.L = Data["Items.labels_" .. lang]
    Items.NM = Data["Items.names_" .. lang]
    Items.CLASSES = Data["Items.classes"].CLASSES[lang]
    Items.BUCKET_CLASSES = Data["Items.classes"].BUCKET_CLASSES
    -- Type-dropdown class codes per bucket, label-sorted for this
    -- language at pack time (no runtime sorting)
    Items.CLASS_ORDER = Data["Items.classes"].CLASS_ORDER[lang]
    -- per-tier recipe scroll classes, grouped into one Type filter entry
    Items.RECIPE_CLASS_SET = {}
    local recipe_classes = Data["Items.classes"].RECIPE_CLASSES
    for k = 1, #recipe_classes do
        Items.RECIPE_CLASS_SET[recipe_classes[k]] = true
    end
    Items.FOLD = Data["Items.classes"].FOLD
    Items.QUALITY_LABELS = Data["Items.classes"].QUALITIES[lang]
    Items.BK = Data["Items.buckets_" .. lang]
    Items.S = Data["Items.search_" .. lang]
    -- baked ultra-common 2-char needles: a cold seed scan for these would
    -- match >5% of the domain (tens of ms) while filtering out nearly
    -- nothing, so the query layer treats them as "still typing"
    Items.STOP2 = {}
    for needle in pairs(Items.S.STOP2) do
        Items.STOP2[needle] = true
    end

    -- Spanish is never the client/UI language (LOTRO has no Spanish client),
    -- so lang above is always de/en/fr. We still keep the Spanish search
    -- index loaded as a second probe blob so a player can type the Spanish
    -- item name and land on the item under whatever language is active
    -- (results always render through Items.L, i.e. in the active language,
    -- never in Spanish) - see the "buscar en espanol, mostrar en ingles"
    -- request.
    if lang ~= "es" then
        local ok = pcall(import, "LUI.src.Data.Items.search_es")
        if ok == true then
            local es_pack = Data["Items.search_es"]
            if type(es_pack) == "table" then
                Items.S_EXTRA = { es_pack }
                for needle in pairs(es_pack.STOP2 or {}) do
                    Items.STOP2[needle] = true
                end
            end
        end
        -- Spanish display labels, kept aside (never swapped into Items.L):
        -- used only so other domains (e.g. Crafting) can offer the Spanish
        -- item name as an extra search key while still rendering English.
        local ok_l = pcall(import, "LUI.src.Data.Items.labels_es")
        if ok_l == true then
            Items.L_ES = Data["Items.labels_es"]
        end
    end
    Items._bucket_lists = {}
    Items._search_cache = {}
    Items.QUALITY_NAMES = Items.M.enums.quality
    Items.QUALITY_CODES = {}
    for code = 1, #Items.QUALITY_NAMES do
        Items.QUALITY_CODES[Items.QUALITY_NAMES[code]] = code
    end
    Items.count = Items.M.count
    local M = Items.M
    -- field byte offsets within a record tuple
    local at = 0
    Items._field_at = {}
    for k = 1, #M.widths do
        Items._field_at[M.fields[k]] = at
        at = at + M.widths[k]
    end
    Items._field_w = {}
    for k = 1, #M.widths do
        Items._field_w[M.fields[k]] = M.widths[k]
    end
    Items.loaded = true

    local listeners = Items._on_loaded
    Items._on_loaded = {}
    for k = 1, #listeners do
        listeners[k]()
    end
end

function Items.find_ordinals(name)
    return _find_ordinals(Items.NM, name)
end

-- plural display name -> ordinals (stacked loot prints the plural form:
-- "[3 Hides]"). Only plurals that differ from the display name are packed,
-- so a miss here means "retry the same text with find_ordinals" — that
-- covers invariant plurals and items authored with a plural display name.
function Items.find_plural_ordinals(name)
    local NM = Items.NM
    return _find_in_index(NM.PNAM, NM.PNOFF, NM.pnoff_width, NM.plural_count,
        NM.ord_width, name)
end

function Items.ordinal_of(id)
    local M = Items.M
    local target = id - M.base_id
    if target < 0 then
        return nil
    end
    return _bsearch_id(Items.R.IDS, M.id_width, M.count, target)
end

function Items.id_of(ordinal)
    local M = Items.M
    return u(Items.R.IDS, (ordinal - 1) * M.id_width + 1, M.id_width) + M.base_id
end

function Items.label(ordinal)
    local L = Items.L
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

-- Spanish name for the same ordinal, or nil when the Spanish pack isn't
-- loaded (see Lore.load_items) - display-only consumers must keep using
-- Items.label(); this exists purely as an extra search key.
function Items.label_es(ordinal)
    local L = Items.L_ES
    if L == nil then
        return nil
    end
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

-- resolve a printed loot name against the DB: stacked drops print the
-- plural display name, singles the exact name; quantity > 1 means the
-- count was parsed outside the bracket (gathered lines). Returns the
-- canonical display name, quantity, and ordinals. Only what the DB
-- confirms is rewritten - on DB-not-loaded or a full miss the inputs pass
-- through unchanged (ordinals nil), so a not-yet-in-DB item named with a
-- leading count ("100 Virtue XP" is one item, not a stack) is never
-- split. The single shared policy: the bestiary tracker persists these
-- names as cache keys and the drops window displays them, so both must
-- resolve identically.
function Items.canonicalize_drop(name, quantity)
    if Items.loaded ~= true then
        return name, quantity, nil
    end

    local ordinals
    if quantity ~= nil and quantity > 1 then
        -- the printed name is a plural form, and the plural index outranks
        -- a literal name collision ("Bones" the plural vs "Bones" the item)
        ordinals = Items.find_plural_ordinals(name)
        if ordinals ~= nil then
            return Items.label(ordinals[1]), quantity, ordinals
        end
        ordinals = Items.find_ordinals(name)
    else
        -- exact display name first (also covers names with a leading
        -- count), plural forms authored as-is second
        ordinals = Items.find_ordinals(name)
        if ordinals == nil and name:match("^%d") == nil then
            ordinals = Items.find_plural_ordinals(name)
        end
    end
    if ordinals ~= nil then
        return name, quantity, ordinals
    end

    -- acquired stacks keep the count in the bracket ("[5 Hides]"): split,
    -- resolve the remainder plural-first, singular for names authored in
    -- plural form ("200 Figments of Splendour"); a full miss keeps the
    -- printed name unchanged
    local count, rest = name:match("^(%d+)%s+(.+)$")
    if count ~= nil then
        ordinals = Items.find_plural_ordinals(rest)
        if ordinals ~= nil then
            return Items.label(ordinals[1]), tonumber(count), ordinals
        end
        ordinals = Items.find_ordinals(rest)
        if ordinals ~= nil then
            return rest, tonumber(count), ordinals
        end
    end
    return name, quantity, nil
end

local function _item_field(ordinal, field)
    local M = Items.M
    local p = (ordinal - 1) * M.stride + 1 + Items._field_at[field]
    return u(Items.R.REC, p, Items._field_w[field])
end

function Items.min_level(ordinal)
    local v = _item_field(ordinal, "min_level")
    if v == 0 then
        return nil
    end
    return v
end

function Items.quality_name(ordinal)
    local code = _item_field(ordinal, "quality")
    if code == 0 then
        return nil
    end
    return Items.M.enums.quality[code]
end

function Items.bucket(ordinal)
    return _item_field(ordinal, "bucket")
end

function Items.class_code(ordinal)
    return _item_field(ordinal, "class")
end

function Items.class_name(ordinal)
    return Items.CLASSES[_item_field(ordinal, "class")]
end

function Items.quality_code(ordinal)
    return _item_field(ordinal, "quality")
end

function Items.level(ordinal)
    return _item_field(ordinal, "level")
end

-- per-bucket ordinal list, sorted by display label at build time
function Items.bucket_list(bucket_name)
    local cached = Items._bucket_lists[bucket_name]
    if cached ~= nil then
        return cached
    end
    local blob = Items.BK["B_" .. string.upper(bucket_name)]
    local w = Items.BK.ord_width
    local list = {}
    for k = 1, #blob / w do
        list[k] = u(blob, (k - 1) * w + 1, w)
    end
    Items._bucket_lists[bucket_name] = list
    return list
end

-- fold a typed needle exactly like the build-time search blobs: ASCII
-- lowering plus the generated accent map
local function _fold_needle(fold, text)
    local folded = string.lower(text)
    for from, to in pairs(fold) do
        folded = folded:gsub(from, to)
    end
    return folded
end

-- one blob's entries in ordinal order; ordinal numbering is shared across
-- every language blob of the same domain (built from the same item list),
-- so sets from different blobs merge directly with no id translation.
local function _blob_entry(S, ordinal)
    local sw = S.soff_width
    local from = u(S.SOFF, (ordinal - 1) * sw + 1, sw)
    local to = u(S.SOFF, ordinal * sw + 1, sw) - 2
    return sub(S.SRCH, from, to)
end

local function _blob_list(domain)
    if domain.S_EXTRA == nil then
        return { domain.S }
    end
    local list = { domain.S }
    for k = 1, #domain.S_EXTRA do
        list[#list + 1] = domain.S_EXTRA[k]
    end
    return list
end

local function _ordinal_matches_any(blobs, ordinal, needle)
    for k = 1, #blobs do
        -- probe the extracted entry: find() with only a start position
        -- would scan the whole blob to the next occurrence on a miss
        if find(_blob_entry(blobs[k], ordinal), needle, 1, true) ~= nil then
            return true
        end
    end
    return false
end

local function _scan_blob(S, domain_count, needle)
    local sw = S.soff_width
    local function soff(k)
        return u(S.SOFF, (k - 1) * sw + 1, sw)
    end
    local function entry_at(pos)
        local lo, hi = 1, domain_count
        while lo < hi do
            local mid = floor((lo + hi + 1) / 2)
            if soff(mid) <= pos then
                lo = mid
            else
                hi = mid - 1
            end
        end
        return lo
    end

    local set = {}
    local pos = 1
    while true do
        local s = find(S.SRCH, needle, pos, true)
        if s == nil then
            break
        end
        local ordinal = entry_at(s)
        set[ordinal] = true
        pos = soff(ordinal + 1)
    end
    return set
end

-- type-ahead search over a domain's folded name blob(s) (domain carries
-- FOLD, S, an optional S_EXTRA list of secondary-language blobs, count and
-- _search_cache; shared by Items and Quests): one C-speed scan per novel
-- query per blob, refinement for extensions, session cache for
-- repeats/backspace. Returns a set { ordinal = true } plus its size; nil
-- means "no filter" (empty query).
local function _domain_search(domain, query)
    local needle = _fold_needle(domain.FOLD, query)
    if needle == "" then
        return nil, 0
    end
    local cached = domain._search_cache[needle]
    if cached ~= nil then
        return cached.set, cached.count
    end

    local blobs = _blob_list(domain)

    -- refine from the longest cached prefix if one exists
    local parent = nil
    for k = #needle - 1, 1, -1 do
        local candidate = domain._search_cache[string.sub(needle, 1, k)]
        if candidate ~= nil then
            parent = candidate
            break
        end
    end

    local set, count = {}, 0
    if parent ~= nil then
        for ordinal in pairs(parent.set) do
            if _ordinal_matches_any(blobs, ordinal, needle) then
                set[ordinal] = true
                count = count + 1
            end
        end
    else
        for k = 1, #blobs do
            local hits = _scan_blob(blobs[k], domain.count, needle)
            for ordinal in pairs(hits) do
                if set[ordinal] == nil then
                    set[ordinal] = true
                    count = count + 1
                end
            end
        end
    end

    domain._search_cache[needle] = { set = set, count = count }
    return set, count
end

-- evaluate a needle over an explicit candidate set only: one bounded probe
-- per candidate instead of a global blob scan. Used for the second and
-- later terms of AND queries, where the running result is already small;
-- results are query-conditional so nothing enters the session cache.
local function _domain_search_within(domain, query, candidates)
    local needle = _fold_needle(domain.FOLD, query)
    local set, count = {}, 0
    local cached = domain._search_cache[needle]
    if cached ~= nil then
        for ordinal in pairs(candidates) do
            if cached.set[ordinal] == true then
                set[ordinal] = true
                count = count + 1
            end
        end
        return set, count
    end
    local blobs = _blob_list(domain)
    for ordinal in pairs(candidates) do
        if _ordinal_matches_any(blobs, ordinal, needle) then
            set[ordinal] = true
            count = count + 1
        end
    end
    return set, count
end

function Items.fold_needle(text)
    return _fold_needle(Items.FOLD, text)
end

function Items.search(query)
    return _domain_search(Items, query)
end

function Items.search_within(query, candidates)
    return _domain_search_within(Items, query, candidates)
end

-- composite icon "main-background-shadow-underlay": up to 4 numeric layers
function Items.icon_layers(ordinal)
    local ref = _item_field(ordinal, "icon")
    if ref == 0 then
        return nil
    end
    local R = Items.R
    local w = Items.M.poff_width
    local composite = sub(R.POOL, u(R.POFF, (ref - 1) * w + 1, w), u(R.POFF, ref * w + 1, w) - 1)
    local layers = {}
    local start = 1
    while true do
        local dash = find(composite, "-", start, true)
        if dash == nil then
            layers[#layers + 1] = tonumber(sub(composite, start))
            break
        end
        layers[#layers + 1] = tonumber(sub(composite, start, dash - 1))
        start = dash + 1
    end
    return layers[1], layers[2], layers[3], layers[4]
end

-- ----------------------------------------------------------- Traceries ----
-- LI tracery metadata keyed by items-DB ordinal: the LI item-level band a
-- tracery sockets into, its uniqueness channel and the player class it is
-- restricted to (0 = none). Sorted-ordinal blob, bsearch per probe.

Lore.Traceries = Lore.Traceries or {}
local Traceries = Lore.Traceries

function Lore.load_traceries()
    if Traceries.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Items.traceries")
    local D = _G.LoreData["Items.traceries"]
    Traceries.D = D
    Traceries.CLASS_LABELS = D.CLASSES[lang]
    Traceries.stride = (3 * D.il_width) + D.ch_width + 1
    Traceries.loaded = true
end

-- base iLvl, enhancement-cap iLvl, uniqueness channel, class index, max
-- usable character level (the min is the records' min_level field).
-- nil when the ordinal is not a tracery.
function Traceries.info(ordinal)
    local D = Traceries.D
    local slot = _bsearch_id(D.T_ORD, D.ord_width, D.count, ordinal)
    if slot == nil then
        return nil
    end
    local p = (slot - 1) * Traceries.stride + 1
    local R = D.T_REC
    local ilw = D.il_width
    local min_il = u(R, p, ilw)
    local max_il = u(R, p + ilw, ilw)
    local channel = u(R, p + (2 * ilw), D.ch_width)
    local class_idx = u(R, p + (2 * ilw) + D.ch_width, 1)
    local char_max = u(R, p + (2 * ilw) + D.ch_width + 1, ilw)
    return min_il, max_il, channel, class_idx, char_max
end

-- localized player class name for a class index; nil for 0 (unrestricted)
function Traceries.class_label(class_idx)
    if class_idx == 0 then
        return nil
    end
    return Traceries.CLASS_LABELS[class_idx]
end

-- --------------------------------------------------------------- Nodes ----
-- Harvest/resource nodes (deposits, branches, crop fields, artifacts):
-- localized node-name lookup plus per-node yields with quantity ranges.
-- One small plain-table file; safe to load eagerly on a target double-click.

Lore.Nodes = Lore.Nodes or {}
local Nodes = Lore.Nodes

function Lore.load_nodes()
    if Nodes.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Nodes.nodes")
    local D = _G.LoreData["Nodes.nodes"]
    Nodes.NAMES = D.NAMES[lang]
    Nodes.NODES = D.NODES
    Nodes.PROFS = D.PROFS[lang]
    Nodes.TIERS = D.TIERS[lang]
    Nodes.ICONS = D.ICONS
    Nodes.loaded = true
end

-- localized in-game object name -> node record + item id; nil when the
-- name is not a harvest node. Record: { p = profession key, t = tier,
-- y = { { item id, min, max, band 1|2|3 }, ... } } (1 = guaranteed,
-- 2 = bonus, 3 = rare; yields sorted band first, largest haul first).
function Nodes.for_name(name)
    local id = Nodes.NAMES[name]
    if id == nil then
        return nil
    end
    return Nodes.NODES[id], id
end

function Nodes.profession_name(key)
    return Nodes.PROFS[key]
end

function Nodes.tier_name(tier)
    return Nodes.TIERS[tier]
end

-- 3-layer badge icon (game asset ids) for a profession tier
function Nodes.badge_layers(key, tier)
    return Nodes.ICONS[key][tier]
end

-- -------------------------------------------------------------- Quests ----
-- Quests + deeds extracted straight from the game client (data-extractor
-- --db quests): packed numeric records (levels, category, reward items,
-- chains, flags), per-language label/name/search blobs and localized
-- category tables. The heavy description/objective/dialog texts live in
-- texts_<lang>.lua (tens of MB) and are only imported on demand.

Lore.Quests = Lore.Quests or {}
local Quests = Lore.Quests

function Lore.load_quests()
    if Quests.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Quests.manifest")
    import("LUI.src.Data.Quests.records")
    import("LUI.src.Data.Quests.labels_" .. lang)
    import("LUI.src.Data.Quests.names_" .. lang)
    import("LUI.src.Data.Quests.search_" .. lang)
    import("LUI.src.Data.Quests.categories")
    -- non-en display order: record order is (level, folded en name);
    -- other languages carry a baked ordinal permutation with their own
    -- name tie-break
    if lang ~= "en" then
        import("LUI.src.Data.Quests.order_" .. lang)
    end
    -- the accent fold map is shared with the items domain
    import("LUI.src.Data.Items.classes")
    local Data = _G.LoreData
    Quests.M = Data["Quests.manifest"]
    Quests.R = Data["Quests.records"]
    Quests.L = Data["Quests.labels_" .. lang]
    Quests.NM = Data["Quests.names_" .. lang]
    Quests.S = Data["Quests.search_" .. lang]
    -- ultra-common 2-char needles, same contract as Items.STOP2
    Quests.STOP2 = Quests.S.STOP2
    Quests.ORD = lang ~= "en" and Data["Quests.order_" .. lang] or nil
    Quests.QUEST_CATS = Data["Quests.categories"].QUEST_CATS[lang]
    Quests.DEED_CATS = Data["Quests.categories"].DEED_CATS[lang]
    -- category dropdown code order, label-sorted for this language at
    -- pack time (no runtime sorting)
    Quests.QUEST_CATS_ORDER = Data["Quests.categories"].QUEST_CATS_ORDER[lang]
    Quests.DEED_CATS_ORDER = Data["Quests.categories"].DEED_CATS_ORDER[lang]
    Quests.FOLD = Data["Items.classes"].FOLD
    Quests.count = Quests.M.count
    Quests._search_cache = {}
    Quests._record_cache = {}
    Quests.loaded = true
end

-- staged import list for hitch-free loading (one import per tick)
function Lore.quests_import_plan()
    local lang = Lore.language()
    local plan = {
        "LUI.src.Data.Quests.manifest",
        "LUI.src.Data.Quests.records",
        "LUI.src.Data.Quests.labels_" .. lang,
        "LUI.src.Data.Quests.names_" .. lang,
        "LUI.src.Data.Quests.search_" .. lang,
        "LUI.src.Data.Quests.categories",
        "LUI.src.Data.Items.classes",
    }
    if lang ~= "en" then
        plan[#plan + 1] = "LUI.src.Data.Quests.order_" .. lang
    end
    return plan
end

function Quests.find_ordinals(name)
    return _find_ordinals(Quests.NM, name)
end

function Quests.id_of(ordinal)
    local M = Quests.M
    return M.base_id + u(Quests.R.IDS, (ordinal - 1) * M.id_width + 1, M.id_width)
end

-- exact-id binary search over the id-sorted index (IDX ascending ids,
-- IDO the matching ordinal): records themselves are in display order
-- (level, then folded en name), so IDS is not searchable directly
function Quests.ordinal_of(id)
    local M = Quests.M
    local target = id - M.base_id
    local R = Quests.R
    local w = M.id_width
    local lo, hi = 1, Quests.count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local v = u(R.IDX, (mid - 1) * w + 1, w)
        if v == target then
            return u(R.IDO, (mid - 1) * M.ord_width + 1, M.ord_width)
        elseif v < target then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

function Quests.label(ordinal)
    local L = Quests.L
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

-- full record decode, cached (the browser touches rows repeatedly)
function Quests.decode(ordinal)
    local cached = Quests._record_cache[ordinal]
    if cached ~= nil then
        return cached
    end
    local M = Quests.M
    local R = Quests.R
    local W = M.widths
    local p = u(R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    local DATA = R.DATA

    local function take(w)
        local v = u(DATA, p, w)
        p = p + w
        return v
    end
    local function ref()
        local v = take(W.ref)
        if v == 0 then
            return nil
        end
        return M.ref_base + v
    end

    local r = {}
    r.is_deed = take(W.deed) == 1
    r.level = take(W.level)
    r.min_level = take(W.level)
    r.category = take(W.category)
    r.exp_tier = take(W.tier)
    r.gold_tier = take(W.tier)
    r.virtue_xp_tier = take(W.tier)
    r.flags = take(W.flags)
    -- 0 = not repeatable, 1 = unlimited, n+1 = n times
    r.max_times = take(W.times)
    r.lock_type = take(W.lock)
    r.next_quest = ref()
    local n_prereqs = take(W.n)
    local n_rewards = take(W.n)
    local n_dialogs = take(W.n)
    r.prereqs = {}
    for k = 1, n_prereqs do
        r.prereqs[k] = ref()
    end
    r.rewards = {}
    for k = 1, n_rewards do
        local item = ref()
        r.rewards[k] = { item = item, quantity = take(W.qty) }
    end
    r.dialog_npcs = {}
    for k = 1, n_dialogs do
        r.dialog_npcs[k] = { objective = take(W.n), action = take(W.n), npc = ref() }
    end
    r.objectives = {}
    for k = 1, take(W.n) do
        local conds = {}
        for c = 1, take(W.n) do
            conds[c] = { event = take(W.event), count = take(W.count) }
        end
        r.objectives[k] = conds
    end

    Quests._record_cache[ordinal] = r
    return r
end

-- cheap fixed-offset reads of the leading record fields (kind, level,
-- min level, category): filtering 20k records must not pay full decodes
function Quests.brief(ordinal)
    local M = Quests.M
    local W = M.widths
    local R = Quests.R
    local p = u(R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    local is_deed = u(R.DATA, p, W.deed) == 1
    p = p + W.deed
    local level = u(R.DATA, p, W.level)
    p = p + W.level
    local min_level = u(R.DATA, p, W.level)
    p = p + W.level
    local category = u(R.DATA, p, W.category)
    return is_deed, level, min_level, category
end

-- ordinals of one kind ("quest" or "deed"), in display order: level
-- ascending, then folded name. For en that is the record (= ordinal)
-- order; other languages iterate their baked ORD permutation, which
-- keeps the level order but tie-breaks on the local name. Both lists are
-- built in one pass over the kind byte of every record, once per session
function Quests.kind_list(kind)
    local lists = Quests._kind_lists
    if lists == nil then
        local M = Quests.M
        local R = Quests.R
        local ORD = Quests.ORD
        local ow = ORD ~= nil and ORD.ord_width or 0
        local w = M.widths.deed
        local quests_list, nq = {}, 0
        local deeds_list, nd = {}, 0
        for k = 1, Quests.count do
            local ordinal = k
            if ORD ~= nil then
                ordinal = u(ORD.ORD, (k - 1) * ow + 1, ow)
            end
            local p = u(R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
            if u(R.DATA, p, w) == 1 then
                nd = nd + 1
                deeds_list[nd] = ordinal
            else
                nq = nq + 1
                quests_list[nq] = ordinal
            end
        end
        lists = { quest = quests_list, deed = deeds_list }
        Quests._kind_lists = lists
    end
    return lists[kind]
end

-- quest flag bits (tools/data-extractor QUEST_FLAGS)
Quests.FLAG_INSTANCE = 1
Quests.FLAG_SHAREABLE = 2
Quests.FLAG_FELLOWSHIP = 4
Quests.FLAG_SMALL_FELLOWSHIP = 8
Quests.FLAG_MONSTER_PLAY = 16
Quests.FLAG_SESSION = 32
Quests.FLAG_RAID = 64

-- dialog entry actions: 6 at objective 0 = quest giver (bestower),
-- 5 = end/turn-in dialog, others attach to their objective
Quests.ACTION_TURN_IN = 5
Quests.ACTION_BESTOW = 6

function Quests.bestower_npc(record)
    local dialogs = record.dialog_npcs
    for k = 1, #dialogs do
        local entry = dialogs[k]
        if entry.action == Quests.ACTION_BESTOW and entry.objective == 0 then
            return entry.npc
        end
    end
    return nil
end

-- the NPC the quest ends at: the role on the highest objective index.
-- The explicit action-5 end dialog always names the bestower in the game
-- data, so the last objective's NPC is the real turn-in target (delivery
-- quests end at a different NPC than they start from).
function Quests.turn_in_npc(record)
    local dialogs = record.dialog_npcs
    local best, best_obj = nil, -1
    for k = 1, #dialogs do
        local entry = dialogs[k]
        -- strict >: on a tied objective the first listed role is the
        -- actual talk target, later ones are follow-up dialogs
        if entry.npc ~= nil
            and not (entry.action == Quests.ACTION_BESTOW and entry.objective == 0)
            and entry.objective > best_obj then
            best, best_obj = entry.npc, entry.objective
        end
    end
    return best
end

function Quests.category_name(record)
    local cats = record.is_deed and Quests.DEED_CATS or Quests.QUEST_CATS
    return cats[record.category]
end

function Quests.fold_needle(text)
    return _fold_needle(Quests.FOLD, text)
end

function Quests.search(query)
    return _domain_search(Quests, query)
end

function Quests.search_within(query, candidates)
    return _domain_search_within(Quests, query, candidates)
end

-- ---- texts (lazy) ----
-- per-record content: description / objectives / bestower dialogs.
-- Sections separated by manifest.section_sep, texts within a section by
-- text_sep, objective description vs its per-condition texts by sub_sep.

local function _split(text, sep)
    local parts, start = {}, 1
    while true do
        local at = find(text, sep, start, true)
        if at == nil then
            parts[#parts + 1] = sub(text, start)
            return parts
        end
        parts[#parts + 1] = sub(text, start, at - 1)
        start = at + 1
    end
end

function Quests.load_texts()
    if Quests.T ~= nil then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Quests.texts_" .. lang)
    Quests.T = _G.LoreData["Quests.texts_" .. lang]
end

function Quests.texts(ordinal)
    Quests.load_texts()
    local T = Quests.T
    local w = T.toff_width
    local entry = sub(T.TXT, u(T.TOFF, (ordinal - 1) * w + 1, w), u(T.TOFF, ordinal * w + 1, w) - 1)
    local M = Quests.M
    local sections = _split(entry, M.section_sep)
    local objectives = {}
    if sections[2] ~= "" then
        local objective_entries = _split(sections[2], M.text_sep)
        for k = 1, #objective_entries do
            local parts = _split(objective_entries[k], M.sub_sep)
            local conds = {}
            for c = 2, #parts do
                conds[c - 1] = parts[c]
            end
            objectives[k] = { text = parts[1], conds = conds }
        end
    end
    local dialogs = {}
    if sections[3] ~= "" then
        dialogs = _split(sections[3], M.text_sep)
    end
    return { description = sections[1], objectives = objectives, dialogs = dialogs }
end

-- ---------------------------------------------------------------- Npcs ----
-- Localized names + titles for the NPCs referenced by quest dialogs
-- (small: only quest NPCs). Labels are "name \31 title" per record,
-- aligned with the sorted IDS blob.

Lore.Npcs = Lore.Npcs or {}
local Npcs = Lore.Npcs

function Lore.load_npcs()
    if Npcs.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Npcs.manifest")
    import("LUI.src.Data.Npcs.records")
    import("LUI.src.Data.Npcs.labels_" .. lang)
    local Data = _G.LoreData
    Npcs.M = Data["Npcs.manifest"]
    Npcs.R = Data["Npcs.records"]
    Npcs.L = Data["Npcs.labels_" .. lang]
    Npcs.count = Npcs.M.count
    Npcs.loaded = true
end

-- exact-id binary search over the sorted IDS blob
function Npcs.ordinal_of(id)
    local M = Npcs.M
    local target = id - M.base_id
    local IDS, w = Npcs.R.IDS, M.id_width
    local lo, hi = 1, Npcs.count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local v = u(IDS, (mid - 1) * w + 1, w)
        if v == target then
            return mid
        elseif v < target then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

-- name, title for an NPC id; nil when the id is not a quest NPC
function Npcs.name(id)
    Lore.load_npcs()
    local ordinal = Npcs.ordinal_of(id)
    if ordinal == nil then
        return nil, nil
    end
    local L = Npcs.L
    local w = L.loff_width
    local label = sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
    local at = find(label, Npcs.M.text_sep, 1, true)
    if at == nil then
        return label, nil
    end
    local title = sub(label, at + 1)
    if title == "" then
        title = nil
    end
    return sub(label, 1, at - 1), title
end

-- -------------------------------------------------------------- Skills ----
-- Skill -> visible buff table (tools/data-extractor extract_skills): per
-- skill the localized name and the buff effects it applies (localized name,
-- icon id, base duration). Consumed by the Upkeep bar to watch the buffs a
-- quickslotted skill maintains.

Lore.Skills = Lore.Skills or {}
local Skills = Lore.Skills

function Lore.load_skills()
    if Skills.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Skills.manifest")
    import("LUI.src.Data.Skills.records")
    import("LUI.src.Data.Skills.labels_" .. lang)
    local Data = _G.LoreData
    Skills.M = Data["Skills.manifest"]
    Skills.R = Data["Skills.records"]
    Skills.L = Data["Skills.labels_" .. lang]
    Skills.count = Skills.M.count
    Skills.loaded = true
end

function Skills.ordinal_of(id)
    local M = Skills.M
    return _bsearch_id(Skills.R.IDS, M.id_width, Skills.count, id - M.base_id)
end

function Skills.label(ordinal)
    local L = Skills.L
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

function Skills.buff_label(buff_ordinal)
    local L = Skills.L
    local w = L.eloff_width
    return sub(L.ELBL, u(L.ELOFF, (buff_ordinal - 1) * w + 1, w), u(L.ELOFF, buff_ordinal * w + 1, w) - 1)
end

-- decoded record for a skill id: { id, name, effects = { { id, name, icon,
-- duration }, ... } } with duration in seconds (0 = no constant duration,
-- e.g. toggles); effects is empty for cooldown-only skills (no visible
-- buff); nil when the id is not a player skill at all
function Skills.buffs_of(id)
    Lore.load_skills()
    local ordinal = Skills.ordinal_of(id)
    if ordinal == nil then
        return nil
    end

    local M = Skills.M
    local R = Skills.R
    local rec = {
        id = id,
        name = Skills.label(ordinal),
        effects = {},
    }
    local a = u(R.ROFF, (ordinal - 1) * M.roff_width + 1, M.roff_width)
    local b = u(R.ROFF, ordinal * M.roff_width + 1, M.roff_width)
    local n = 0
    for k = a, b - 1, M.eff_ord_width do
        local o = u(R.REF, k, M.eff_ord_width)
        n = n + 1
        rec.effects[n] = {
            id = M.e_base_id + u(R.EIDS, (o - 1) * M.e_id_width + 1, M.e_id_width),
            name = Skills.buff_label(o),
            icon = u(R.EICON, (o - 1) * M.icon_width + 1, M.icon_width),
            duration = u(R.EDUR, (o - 1) * M.dur_width + 1, M.dur_width) / 10,
        }
    end
    return rec
end
