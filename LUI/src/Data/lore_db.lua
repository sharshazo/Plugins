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
        -- data library (items, recipes...) stays in
        -- English on purpose -- player's request: "la biblioteca de
        -- busqueda debe ser en ingles; buscamos en español y salen los
        -- nombres en ingles". Items.load keeps the Spanish search pack as a
        -- second probe for exactly that (see the Items.S_EXTRA note below).
        -- Also required for safety: several domains ship no _es files,
        -- so importing them in "es" would fail.
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
    -- protected: the optional Spanish packs may be absent; a missing
    -- required file still errors in the load_items finalizer
    pcall(import, package_name)
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
    local plan = {
        "LUI.src.Data.Items.manifest",
        "LUI.src.Data.Items.records",
        "LUI.src.Data.Items.labels_" .. lang,
        "LUI.src.Data.Items.names_" .. lang,
        "LUI.src.Data.Items.classes",
        "LUI.src.Data.Items.buckets_" .. lang,
        "LUI.src.Data.Items.search_" .. lang,
    }
    -- the Spanish search/label packs load_items adds (~10 MB) are staged
    -- too, so the finalizer never imports them all in one frame
    if lang ~= "es" then
        plan[#plan + 1] = "LUI.src.Data.Items.search_es"
        plan[#plan + 1] = "LUI.src.Data.Items.labels_es"
    end
    return plan
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
-- split. The drops window displays these names.
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
-- _search_cache; used by Items): one C-speed scan per novel
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
