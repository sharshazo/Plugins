-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Persistence = _G.LUI.Settings.Persistence
local AssetCache = _G.LUI.Runtime.Caches.Assets
local Stores = _G.LUI.Runtime.Stores
local State = _G.LUI.Settings.State
local Lore = _G.LUI.Data.Lore
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

local Crafting = _G.LUI.Features.Crafting

local CraftingStore = class(Turbine.UI.Control)
Crafting.CraftingStore = CraftingStore

local SOURCE_BACKPACK = "backpack"
local SOURCE_BANK = "bank"
local SOURCE_VAULT = "vault"
local SOURCE_SHARED = "shared_storage"
local SOURCE_OTHER_CHARACTERS = "other_characters"
local SOURCE_SCOPE_PREFIX = "sources:"

local FILTER_ALL = "__all"
local FILTER_MINE = "__mine"
local BACKGROUND_RECIPE_BATCH_SIZE = 2
local BACKGROUND_UPDATE_EVERY = 0.20
local FOREGROUND_UPDATE_EVERY = 0.20
local FOREGROUND_RECIPE_BATCH_SIZE = 10
local RECIPE_STATUS_CRAFT_LIMIT = 999

local SOURCE_ORDER = {
    SOURCE_BACKPACK,
    SOURCE_BANK,
    SOURCE_VAULT,
    SOURCE_SHARED,
    SOURCE_OTHER_CHARACTERS,
}

local SOURCE_SET = {
    [SOURCE_BACKPACK] = true,
    [SOURCE_BANK] = true,
    [SOURCE_VAULT] = true,
    [SOURCE_SHARED] = true,
    [SOURCE_OTHER_CHARACTERS] = true,
}

local PROFESSION_ORDER = {
    Turbine.Gameplay.Profession.Cook,
    Turbine.Gameplay.Profession.Farmer,
    Turbine.Gameplay.Profession.Forester,
    Turbine.Gameplay.Profession.Jeweller,
    Turbine.Gameplay.Profession.Metalsmith,
    Turbine.Gameplay.Profession.Prospector,
    Turbine.Gameplay.Profession.Scholar,
    Turbine.Gameplay.Profession.Tailor,
    Turbine.Gameplay.Profession.Weaponsmith,
    Turbine.Gameplay.Profession.Woodworker,
}

-- local lore database join keys (profession enum values in the generated DB)
local DB_PROFESSION_KEYS = {
    [Turbine.Gameplay.Profession.Cook] = "COOK",
    [Turbine.Gameplay.Profession.Farmer] = "FARMER",
    [Turbine.Gameplay.Profession.Forester] = "FORESTER",
    [Turbine.Gameplay.Profession.Jeweller] = "JEWELLER",
    [Turbine.Gameplay.Profession.Metalsmith] = "METALSMITH",
    [Turbine.Gameplay.Profession.Prospector] = "PROSPECTOR",
    [Turbine.Gameplay.Profession.Scholar] = "SCHOLAR",
    [Turbine.Gameplay.Profession.Tailor] = "TAILOR",
    [Turbine.Gameplay.Profession.Weaponsmith] = "WEAPONSMITH",
    [Turbine.Gameplay.Profession.Woodworker] = "WOODWORKER",
}

local DB_QUALITY_TO_LOTRO = {
    COMMON = Turbine.Gameplay.ItemQuality.Common,
    UNCOMMON = Turbine.Gameplay.ItemQuality.Uncommon,
    RARE = Turbine.Gameplay.ItemQuality.Rare,
    INCOMPARABLE = Turbine.Gameplay.ItemQuality.Incomparable,
    LEGENDARY = Turbine.Gameplay.ItemQuality.Legendary,
}

-- building records from the local DB is cheap; step many more recipes per
-- tick than the old API content path allowed
local DB_BATCH_MULTIPLIER = 50
-- known-tagging touches the game's recipe book (identity only), keep batches
-- moderate so it stays invisible in the background
local KNOWN_PASS_BATCH_SIZE = 100

local function _safe_string(value, fallback)
    if value == nil then
        return fallback or ""
    end
    return tostring(value)
end

local function _trim(text)
    local value = _safe_string(text, "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function _lower(text)
    return string.lower(_safe_string(text, ""))
end

local function _normalize_name(name)
    local value = _trim(name)
    if value == "" then
        return ""
    end
    value = value:gsub("%s+", " ")
    return _lower(value)
end

local function _is_obsolete_conversion_category(category_name)
    local key = _normalize_name(category_name)
    if key == "" then
        return false
    end

    if string.find(key, "obsolete", 1, true) ~= nil and string.find(key, "conversion", 1, true) ~= nil then
        return true
    end
    if string.find(key, "obsol", 1, true) ~= nil and string.find(key, "conversion", 1, true) ~= nil then
        return true
    end
    if string.find(key, "veraltet", 1, true) ~= nil then
        return string.find(key, "umwand", 1, true) ~= nil or string.find(key, "konvert", 1, true) ~= nil
    end

    return false
end

local function _copy_counts(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end

    for key, value in pairs(source) do
        out[key] = value
    end

    return out
end

local function _copy_array(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    for i = 1, #source do
        out[#out + 1] = source[i]
    end
    return out
end

local function _add_count(map, key, quantity)
    local amount = tonumber(quantity) or 0
    if type(map) ~= "table" or key == nil or key == "" or amount <= 0 then
        return
    end
    map[key] = (map[key] or 0) + amount
end

local function _normalize_source_keys(source_keys)
    local selected = {}
    if type(source_keys) == "table" then
        for i = 1, #source_keys do
            local key = source_keys[i]
            if SOURCE_SET[key] == true then
                selected[key] = true
            end
        end
    elseif type(source_keys) == "string" and string.sub(source_keys, 1, string.len(SOURCE_SCOPE_PREFIX)) == SOURCE_SCOPE_PREFIX then
        local encoded = source_keys
        encoded = string.sub(encoded, string.len(SOURCE_SCOPE_PREFIX) + 1)
        for key in string.gmatch(encoded, "[^,]+") do
            if SOURCE_SET[key] == true then
                selected[key] = true
            end
        end
    end

    local out = {}
    for i = 1, #SOURCE_ORDER do
        local key = SOURCE_ORDER[i]
        if selected[key] == true then
            out[#out + 1] = key
        end
    end
    return out
end

local function _source_scope_key(source_keys)
    local normalized = _normalize_source_keys(source_keys)
    return SOURCE_SCOPE_PREFIX .. table.concat(normalized, ",")
end

local function _is_source_scope_key(scope_key)
    return type(scope_key) == "table" or
        (type(scope_key) == "string" and string.sub(scope_key, 1, string.len(SOURCE_SCOPE_PREFIX)) == SOURCE_SCOPE_PREFIX)
end

local function _normalized_scope_key(scope_key)
    if _is_source_scope_key(scope_key) == true then
        return _source_scope_key(scope_key)
    end
    return _source_scope_key({})
end

local function _count_map_signature(counts)
    if type(counts) ~= "table" then
        return ""
    end

    local keys = {}
    for key, quantity in pairs(counts) do
        if key ~= nil and key ~= "" and (tonumber(quantity) or 0) > 0 then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)

    local parts = {}
    for i = 1, #keys do
        local key = keys[i]
        parts[#parts + 1] = key .. "\31" .. tostring(tonumber(counts[key]) or 0)
    end

    return table.concat(parts, "\30")
end

local function _sum_missing_map(missing_map)
    local total = 0
    if type(missing_map) ~= "table" then
        return total
    end

    for _, entry in pairs(missing_map) do
        if type(entry) == "table" then
            total = total + (tonumber(entry.quantity) or 0)
        end
    end

    return total
end

local function _sort_missing_list(left, right)
    local left_name = _lower(left ~= nil and left.name or nil)
    local right_name = _lower(right ~= nil and right.name or nil)
    if left_name ~= right_name then
        return left_name < right_name
    end

    return (tonumber(left ~= nil and left.quantity or nil) or 0) > (tonumber(right ~= nil and right.quantity or nil) or 0)
end

local function _missing_map_to_list(missing_map)
    local out = {}
    if type(missing_map) ~= "table" then
        return out
    end

    for _, entry in pairs(missing_map) do
        if type(entry) == "table" and (tonumber(entry.quantity) or 0) > 0 then
            out[#out + 1] = entry
        end
    end

    table.sort(out, _sort_missing_list)
    return out
end

local function _collect_leaf_requirements(node, out)
    if type(node) ~= "table" or type(out) ~= "table" then
        return
    end

    local children = node.children
    if type(children) ~= "table" or #children == 0 then
        local key = node.key
        if key ~= nil and key ~= "" then
            if type(out[key]) ~= "table" then
                out[key] = {
                    key = key,
                    quantity = 0,
                }
            end
            out[key].quantity = (tonumber(out[key].quantity) or 0) + (tonumber(node.required) or 0)
        end
        return
    end

    for i = 1, #children do
        _collect_leaf_requirements(children[i], out)
    end
end

local function _resource_progress_sort_compare(left, right)
    local left_complete = left ~= nil and left.complete == true
    local right_complete = right ~= nil and right.complete == true
    if left_complete ~= right_complete then
        return left_complete ~= true
    end

    local left_missing = tonumber(left ~= nil and left.missing or nil) or 0
    local right_missing = tonumber(right ~= nil and right.missing or nil) or 0
    if left_missing ~= right_missing then
        return left_missing > right_missing
    end

    local left_required = tonumber(left ~= nil and left.required or nil) or 0
    local right_required = tonumber(right ~= nil and right.required or nil) or 0
    if left_required ~= right_required then
        return left_required > right_required
    end

    local left_name = _lower(left ~= nil and left.name or nil)
    local right_name = _lower(right ~= nil and right.name or nil)
    return left_name < right_name
end

local function _saved_plan_entry_matches_recipe(saved_entry, recipe)
    if type(saved_entry) ~= "table" or type(recipe) ~= "table" then
        return false
    end
    if saved_entry.i == nil then
        return false
    end

    if tostring(saved_entry.i) ~= tostring(recipe.id) then
        return false
    end
    if saved_entry.p ~= nil and tostring(saved_entry.p) ~= tostring(recipe.profession_key) then
        return false
    end
    if saved_entry.r ~= nil and tostring(saved_entry.r) ~= tostring(recipe.result_key) then
        return false
    end
    if saved_entry.n ~= nil and tostring(saved_entry.n) ~= tostring(recipe.recipe_name_key or recipe.result_key or "") then
        return false
    end
    if saved_entry.c ~= nil and tostring(saved_entry.c) ~= _normalize_name(recipe.category_name) then
        return false
    end

    return true
end


local function _current_character_name()
    if type(State.current_character_name) == "string" and State.current_character_name ~= "" then
        return State.current_character_name
    end

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local name = player ~= nil and player:GetName() or nil
    name = _trim(name)
    if name ~= "" then
        return name
    end

    return "__unknown_character__"
end

local function _copy_asset_record(record)
    if type(record) ~= "table" then
        return nil
    end

    return {
        name = record.name,
        quantity = record.quantity,
        owner = record.owner,
        source_key = record.source_key,
        source_name = record.source_name,
        icon_id = record.icon_id,
        background_image_id = record.background_image_id,
        quality = record.quality,
    }
end

local function _collect_asset_entries_from_cache()
    local entries = {}
    local cache = Persistence.ensure_assets_cache ~= nil and Persistence.ensure_assets_cache() or AssetCache.data
    if type(cache) ~= "table" then
        return entries
    end

    local characters = type(cache.characters) == "table" and cache.characters or {}
    local character_names = {}
    for character_name, _ in pairs(characters) do
        character_names[#character_names + 1] = character_name
    end
    table.sort(character_names, function(left, right)
        return _lower(left) < _lower(right)
    end)

    local function append_items(items)
        if type(items) ~= "table" then
            return
        end
        for i = 1, #items do
            local copy = _copy_asset_record(items[i])
            if copy ~= nil then
                entries[#entries + 1] = copy
            end
        end
    end

    for i = 1, #character_names do
        local character_cache = characters[character_names[i]]
        if type(character_cache) == "table" then
            append_items(character_cache.backpack ~= nil and character_cache.backpack.items or nil)
            append_items(character_cache.bank ~= nil and character_cache.bank.items or nil)
            append_items(character_cache.vault ~= nil and character_cache.vault.items or nil)
        end
    end

    append_items(cache.shared_storage ~= nil and cache.shared_storage.items or nil)
    return entries
end

local function _source_option_labels()
    return {
        TR["Backpack"],
        TR["Bank"],
        TR["Vault"],
        TR["Shared Storage"],
        TR["Other characters"],
    }
end

local function _source_option_values()
    return _copy_array(SOURCE_ORDER)
end

local function _source_label(source_key)
    if source_key == SOURCE_BACKPACK then
        return TR["Backpack"]
    end
    if source_key == SOURCE_BANK then
        return TR["Bank"]
    end
    if source_key == SOURCE_VAULT then
        return TR["Vault"]
    end
    if source_key == SOURCE_SHARED then
        return TR["Shared Storage"]
    end
    if source_key == SOURCE_OTHER_CHARACTERS then
        return TR["Other characters"]
    end
    return _safe_string(source_key, "")
end

local function _recipe_reenters_path(recipe, visiting)
    if type(recipe) ~= "table" or type(recipe.ingredients) ~= "table" or type(visiting) ~= "table" then
        return false
    end

    for index = 1, #recipe.ingredients do
        local ingredient = recipe.ingredients[index]
        if type(ingredient) == "table" and visiting[ingredient.key] == true then
            return true
        end
    end

    return false
end

local function _add_result_index_entry(index_map, key, record, prepend)
    if type(index_map) ~= "table" or type(record) ~= "table" then
        return
    end

    local normalized_key = _normalize_name(key)
    if normalized_key == "" then
        return
    end

    local list = index_map[normalized_key]
    if type(list) ~= "table" then
        list = {}
        index_map[normalized_key] = list
    end

    for i = 1, #list do
        if list[i] == record then
            return
        end
    end

    if prepend == true then
        table.insert(list, 1, record)
    else
        list[#list + 1] = record
    end
end

function CraftingStore:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetVisible(false)
    self:SetWantsUpdates(true)

    self.current_character_name = _current_character_name()
    self.professions = {}
    self.profession_by_key = {}
    self.owned_profession_keys = {}
    self.items = {}
    self.recipes = {}
    self.recipe_by_id = {}
    self.known_recipes_by_result = {}
    self.recipes_by_ingredient = {}
    self.recipes_by_result = {}
    self.recipes_by_scroll = {}
    self.recipe_tiers = {}
    self.recipe_tiers_version = 0
    self._live_inventory_counts = nil
    self.source_ownership = {
        [SOURCE_BACKPACK] = {},
        [SOURCE_BANK] = {},
        [SOURCE_VAULT] = {},
        [SOURCE_SHARED] = {},
        [SOURCE_OTHER_CHARACTERS] = {},
    }
    self.profession_option_labels = { TR["All professions"] }
    self.profession_option_values = { FILTER_ALL }
    self.source_option_labels = _source_option_labels()
    self.source_option_values = _source_option_values()
    self:_reset_status_caches()
    self._assets_token = nil
    self._recipe_token = nil
    self._recipes_initialized = false
    self._recipe_loading = false
    self._import_queue = nil
    self._import_index = 1
    self._import_total = 0
    self._import_done = 0
    self._profession_by_db_code = nil
    self._recipe_load_next = 1
    self._recipe_load_done = 0
    self._recipe_load_total = 0
    self._foreground_loading = false
    self._pending_loaded_result_keys = {}
    self._live_inventory_token = ""
    self._known_queue = nil
    self._known_loading = false
    self.update_every = BACKGROUND_UPDATE_EVERY
    self.last_update_at = 0
    self.version = 0
end

function CraftingStore:destroy()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
end

function CraftingStore:get_source_options()
    return self.source_option_labels, self.source_option_values
end

function CraftingStore:get_default_source_keys()
    return { SOURCE_BACKPACK, SOURCE_BANK, SOURCE_VAULT, SOURCE_SHARED }
end

function CraftingStore:get_all_source_keys()
    return _copy_array(SOURCE_ORDER)
end

function CraftingStore:normalize_source_keys(source_keys)
    return _normalize_source_keys(source_keys)
end

function CraftingStore:scope_key_from_sources(source_keys)
    return _source_scope_key(source_keys)
end

function CraftingStore:get_source_breakdown(item_key, required, scope_key)
    local key = _normalize_name(item_key)
    local needed = math.max(0, math.floor((tonumber(required) or 0) + 0.5))
    local source_keys = _normalize_source_keys(_normalized_scope_key(scope_key))
    local entries = {}
    local total_owned = 0

    for i = 1, #source_keys do
        local source_key = source_keys[i]
        local source_stock = self.source_ownership[source_key]
        local owned = 0
        if type(source_stock) == "table" then
            owned = math.max(0, math.floor((tonumber(source_stock[key]) or 0) + 0.5))
        end
        total_owned = total_owned + owned
        entries[#entries + 1] = {
            key = source_key,
            label = _source_label(source_key),
            owned = owned,
        }
    end

    local remaining = needed
    local positive_count = 0
    for i = 1, #entries do
        local entry = entries[i]
        entry.used = math.min(entry.owned, remaining)
        remaining = math.max(0, remaining - entry.used)
        if entry.owned > 0 then
            positive_count = positive_count + 1
        end
    end

    return {
        key = key,
        required = needed,
        total_owned = total_owned,
        missing = math.max(0, needed - total_owned),
        complete = total_owned >= needed,
        entries = entries,
        positive_count = positive_count,
    }
end

function CraftingStore:get_profession_options()
    return self.profession_option_labels, self.profession_option_values
end

function CraftingStore:is_loading()
    return self._recipe_loading == true
end

function CraftingStore:is_known_pass_running()
    return self._known_loading == true
end

function CraftingStore:get_loading_progress()
    local total = self._import_total + self._recipe_load_total
    local loaded = self._import_done + self._recipe_load_done
    if total < loaded then
        total = loaded
    end

    return {
        loading = self._recipe_loading == true,
        loaded = loaded,
        total = total,
        complete = self._recipes_initialized == true and self._recipe_loading ~= true,
    }
end

function CraftingStore:consume_loaded_recipe_result_keys()
    local loaded_result_keys = self._pending_loaded_result_keys
    self._pending_loaded_result_keys = {}
    if type(loaded_result_keys) ~= "table" then
        return {}
    end
    return loaded_result_keys
end

function CraftingStore:set_loading_priority(enabled)
    local foreground = enabled == true
    if self._foreground_loading == foreground then
        return
    end

    self._foreground_loading = foreground
    self.update_every = foreground == true and FOREGROUND_UPDATE_EVERY or BACKGROUND_UPDATE_EVERY
    self.last_update_at = 0
end

function CraftingStore:Update()
    self:refresh_if_due()
end

function CraftingStore:refresh_if_due()
    local now = Turbine.Engine.GetGameTime()
    if (now - (self.last_update_at or 0)) < self.update_every then
        return false
    end
    self.last_update_at = now

    local batch_size = self._foreground_loading == true and FOREGROUND_RECIPE_BATCH_SIZE or BACKGROUND_RECIPE_BATCH_SIZE
    batch_size = batch_size * DB_BATCH_MULTIPLIER
    return self:refresh(false, batch_size)
end

function CraftingStore:refresh(force, recipe_batch_size)
    local current_character = _current_character_name()
    local assets_token = Stores.assets ~= nil and (tonumber(Stores.assets.generation) or 0) or 0
    local live_inventory_counts = self:_capture_live_backpack_counts(current_character)
    local live_inventory_token = _count_map_signature(live_inventory_counts)
    local changed = false
    local recipe_refresh_needed = force == true or self._recipes_initialized ~= true or self.current_character_name ~= current_character

    if recipe_refresh_needed == true then
        self:_start_recipe_load(current_character)
        changed = true
    elseif self._import_queue ~= nil then
        self:_step_import()
        changed = true
    elseif self._recipe_loading == true and self:_step_recipe_load(recipe_batch_size or BACKGROUND_RECIPE_BATCH_SIZE) == true then
        changed = true
    elseif self._known_loading == true and self:_step_known_pass() == true then
        changed = true
    end

    local ownership_refresh_needed = force == true or recipe_refresh_needed == true or self._assets_token ~= assets_token or
        self._live_inventory_token ~= live_inventory_token

    if changed ~= true and ownership_refresh_needed ~= true then
        return false
    end

    self.current_character_name = current_character
    if ownership_refresh_needed == true then
        local previous_counts = self._live_inventory_counts
        self.source_ownership = self:_build_source_ownership(current_character, live_inventory_counts)
        if force ~= true and recipe_refresh_needed ~= true and self._assets_token == assets_token and
            previous_counts ~= nil then
            -- only the live backpack changed: drop just the statuses that
            -- can depend on the changed items instead of nuking everything
            self:_invalidate_statuses_for_changes(previous_counts, live_inventory_counts)
        else
            self:_reset_status_caches()
        end
        self._live_inventory_counts = live_inventory_counts
        self._assets_token = assets_token
        self._live_inventory_token = live_inventory_token
    end
    self.version = self.version + 1
    return true
end

function CraftingStore:_reset_status_caches()
    self._status_cache = {}
    self._scope_stock_cache = {}
end

-- selective status invalidation for live-backpack deltas: only recipes whose
-- ingredients intersect the changed items, plus (conservatively) any status
-- whose evaluation expanded a material tree, can change
function CraftingStore:_invalidate_statuses_for_changes(old_counts, new_counts)
    self._scope_stock_cache = {}

    local changed_keys = {}
    for key, count in pairs(new_counts) do
        if old_counts[key] ~= count then
            changed_keys[key] = true
        end
    end
    for key in pairs(old_counts) do
        if new_counts[key] == nil then
            changed_keys[key] = true
        end
    end

    for _, cache in pairs(self._status_cache) do
        for key in pairs(changed_keys) do
            local records = self.recipes_by_ingredient[key]
            if records ~= nil then
                for i = 1, #records do
                    cache[records[i].id] = nil
                end
            end
        end
        for id, summary in pairs(cache) do
            if summary.used_expansion == true then
                cache[id] = nil
            end
        end
    end
end

-- merged stock tables are expensive to build (every item across sources);
-- share one per scope for the lifetime of the status cache
function CraftingStore:_cached_stock_for_scope(scope)
    local stock = self._scope_stock_cache[scope]
    if stock == nil then
        stock = self:_stock_for_scope(scope)
        self._scope_stock_cache[scope] = stock
    end
    return stock
end

function CraftingStore:get_recipe_status(recipe_or_id, scope_key)
    local scope = _normalized_scope_key(scope_key)
    if type(self._status_cache[scope]) ~= "table" then
        self._status_cache[scope] = {}
    end

    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    if type(recipe) ~= "table" then
        return nil
    end

    local cache = self._status_cache[scope]
    if cache[recipe.id] == nil then
        local stock = self:_cached_stock_for_scope(scope)

        -- cheap rejection first: an ingredient with no stock at all and no
        -- known producing recipe can never be satisfied; skip the material
        -- tree evaluation entirely
        local impossible = false
        for i = 1, #recipe.ingredients do
            local key = recipe.ingredients[i].key
            if stock[key] == nil and self.known_recipes_by_result[key] == nil then
                impossible = true
                break
            end
        end

        local summary
        if impossible == true then
            summary = {
                craftable = false,
                craftable_count = 0,
                craftable_count_limited = false,
                used_expansion = false,
                ingredients = {},
            }
            for i = 1, #recipe.ingredients do
                local ingredient = recipe.ingredients[i]
                local available = stock[ingredient.key]
                summary.ingredients[i] = {
                    satisfied = available ~= nil and available >= ingredient.quantity,
                    expanded = false,
                }
            end
        else
            local evaluation = self:_evaluate_recipe_with_stock(recipe, 1, stock)
            -- craftable_count stays nil until a consumer asks for it
            -- (get_recipe_craftable_count): the capped count search costs
            -- ~10 more tree evaluations per recipe and only rendered rows
            -- ever display it
            local craftable_count = nil
            if evaluation.craftable ~= true then
                craftable_count = 0
            end
            summary = {
                craftable = evaluation.craftable == true,
                craftable_count = craftable_count,
                craftable_count_limited = false,
                used_expansion = evaluation.used_expansion == true,
                ingredients = {},
            }
            for i = 1, #evaluation.ingredients do
                local node = evaluation.ingredients[i]
                summary.ingredients[i] = {
                    satisfied = node.satisfied == true,
                    expanded = node.expanded == true,
                }
            end
        end
        cache[recipe.id] = summary
    end
    return cache[recipe.id]
end

function CraftingStore:get_recipe_craftable_count(recipe_or_id, scope_key)
    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    if type(recipe) ~= "table" then
        return 0, false
    end

    local status = self:get_recipe_status(recipe, scope_key)
    if status.craftable ~= true then
        return 0, false
    end

    if status.craftable_count == nil then
        local scope = _normalized_scope_key(scope_key)
        local stock = self:_cached_stock_for_scope(scope)
        local craftable_count = self:_max_craftable_with_stock(recipe, stock, RECIPE_STATUS_CRAFT_LIMIT)
        local limited = false
        if craftable_count >= RECIPE_STATUS_CRAFT_LIMIT then
            local over_limit = self:_evaluate_recipe_with_stock(recipe, RECIPE_STATUS_CRAFT_LIMIT + 1, stock)
            limited = over_limit.craftable == true
        end
        status.craftable_count = craftable_count
        status.craftable_count_limited = limited
    end
    return status.craftable_count, status.craftable_count_limited == true
end

function CraftingStore:get_item(item_key)
    if type(self.items) ~= "table" then
        return nil
    end
    return self.items[item_key]
end

function CraftingStore:get_recipe_result_item(recipe_or_id)
    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    if type(recipe) ~= "table" then
        return nil
    end
    -- resolved by real item id: the name-keyed items map can hold a
    -- same-named crit upgrade instead of the normal result
    return self:item_display_by_id(recipe.result_item_id)
end

function CraftingStore:get_recipe_required_level(recipe_or_id)
    local item = self:get_recipe_result_item(recipe_or_id)
    return item ~= nil and item.required_level or nil
end

function CraftingStore:get_recipe_result_name(recipe_or_id)
    local item = self:get_recipe_result_item(recipe_or_id)
    if item ~= nil and item.name ~= nil and item.name ~= "" then
        return item.name
    end

    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    return type(recipe) == "table" and (recipe.result_key or "") or ""
end

function CraftingStore:recipe_matches_query(recipe, groups)
    if type(recipe) ~= "table" then
        return false
    end
    if type(groups) ~= "table" or #groups == 0 then
        return true
    end

    local haystack = recipe.search_text
    for group_index = 1, #groups do
        local group = groups[group_index]
        local matched = true
        for term_index = 1, #group do
            if string.find(haystack, group[term_index], 1, true) == nil then
                matched = false
                break
            end
        end
        if matched == true then
            return true
        end
    end

    return false
end

-- Display entry straight from the lore DB by item id, bypassing the
-- name-keyed items map: crit outputs can share their name with the base
-- item while being a different item (teal upgrades).
function CraftingStore:item_display_by_id(item_id)
    local ordinal = Lore.Items.ordinal_of(item_id)
    if ordinal == nil then
        return nil
    end
    local icon_id, background_id = Lore.Items.icon_layers(ordinal)
    return {
        name = Lore.Items.label(ordinal),
        item_id = item_id,
        icon_id = icon_id,
        background_image_id = background_id,
        quality = DB_QUALITY_TO_LOTRO[Lore.Items.quality_name(ordinal)],
        required_level = Lore.Items.min_level(ordinal),
    }
end

-- Cross-window link probes (Encyclopedia rows, bestiary card drops): both
-- indexes are keyed by normalized item name, the same normalization used
-- when recipe records are registered.
function CraftingStore:has_recipes_using_name(item_name)
    return self.recipes_by_ingredient[_normalize_name(item_name)] ~= nil
end

-- recipe records consuming this item as an ingredient (nil when none)
function CraftingStore:get_recipes_using_name(item_name)
    return self.recipes_by_ingredient[_normalize_name(item_name)]
end

-- Which output of a recipe an item name refers to: 0 for the main result
-- (or its crit), 1..n for a variant (or its crit).
function CraftingStore:variant_index_for_result_name(recipe, item_name)
    local key = _normalize_name(item_name)
    if key == "" or recipe.result_key == key or recipe.critical_result_key == key then
        return 0
    end
    for i = 1, #recipe.variants do
        local variant = recipe.variants[i]
        if variant.result_key == key or variant.critical_result_key == key then
            return i
        end
    end
    return 0
end

function CraftingStore:first_recipe_producing_name(item_name)
    local records = self.recipes_by_result[_normalize_name(item_name)]
    if records == nil then
        return nil
    end
    return records[1]
end

-- the recipe a scroll/recipe item teaches, by the scroll's game item id
function CraftingStore:recipe_taught_by_item_id(item_id)
    return self.recipes_by_scroll[item_id]
end

function CraftingStore:recipe_result_display_name(recipe)
    return self.items[recipe.result_key].name
end

function CraftingStore:_stock_for_source_keys(source_keys)
    local stock = {}
    local normalized = _normalize_source_keys(source_keys)
    for i = 1, #normalized do
        local source_stock = self.source_ownership[normalized[i]]
        if type(source_stock) == "table" then
            for key, quantity in pairs(source_stock) do
                _add_count(stock, key, quantity)
            end
        end
    end
    return stock
end

function CraftingStore:_stock_for_scope(scope_key)
    local scope = _normalized_scope_key(scope_key)
    return self:_stock_for_source_keys(_normalize_source_keys(scope))
end

function CraftingStore:evaluate_recipe(recipe_or_id, scope_key, craft_count)
    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    if type(recipe) ~= "table" then
        return nil
    end

    local count = tonumber(craft_count) or 1
    if count < 1 then
        count = 1
    end
    count = math.floor(count + 0.5)

    local scope = _normalized_scope_key(scope_key)
    local base_stock = self:_stock_for_scope(scope)
    local evaluation = self:_evaluate_recipe_with_stock(recipe, count, base_stock)
    evaluation.scope_key = scope
    return evaluation
end

function CraftingStore:evaluate_plan(plan_entries, scope_key)
    local base_stock = self:_stock_for_scope(scope_key)
    local working_stock = _copy_counts(base_stock)
    local result = {
        entries = {},
        missing = {},
        missing_list = {},
        missing_total = 0,
        planned_recipe_count = 0,
        craftable_count_total = 0,
    }

    if type(plan_entries) ~= "table" then
        return result
    end

    for i = 1, #plan_entries do
        local entry = plan_entries[i]
        local recipe = entry ~= nil and self.recipe_by_id[entry.recipe_id] or nil
        local count = entry ~= nil and (tonumber(entry.count) or 0) or 0
        count = math.floor(count + 0.5)
        if recipe ~= nil and count > 0 then
            result.planned_recipe_count = result.planned_recipe_count + count
            local craftable_count = self:_count_craftable_with_stock(recipe, count, working_stock)
            result.craftable_count_total = result.craftable_count_total + craftable_count
            local evaluation = self:_evaluate_recipe_with_stock(recipe, count, working_stock)
            working_stock = evaluation.remaining_stock
            result.entries[#result.entries + 1] = {
                recipe = recipe,
                count = count,
                craftable_count = craftable_count,
                evaluation = evaluation,
            }
            self:_merge_missing_maps(result.missing, evaluation.missing)
        end
    end

    result.missing_list = _missing_map_to_list(result.missing)
    result.missing_total = _sum_missing_map(result.missing)
    return result
end

function CraftingStore:serialize_plan_entries(plan_entries)
    local saved_entries = {}
    if type(plan_entries) ~= "table" then
        return saved_entries
    end

    for i = 1, #plan_entries do
        local entry = plan_entries[i]
        local recipe = entry ~= nil and self.recipe_by_id[entry.recipe_id] or nil
        local count = entry ~= nil and (tonumber(entry.count) or 0) or 0
        count = math.floor(count + 0.5)
        if recipe ~= nil and count > 0 then
            local saved_entry = self:serialize_recipe_identity(recipe)
            saved_entry.q = count
            local variant = math.floor((tonumber(entry.variant) or 0) + 0.5)
            if variant > 0 then
                saved_entry.v = variant
            end
            saved_entries[#saved_entries + 1] = saved_entry
        end
    end

    return saved_entries
end

function CraftingStore:serialize_recipe_identity(recipe)
    if type(recipe) ~= "table" then
        return nil
    end

    return {
        i = recipe.id,
        p = recipe.profession_key,
        r = recipe.result_key,
        n = recipe.recipe_name_key,
        c = _normalize_name(recipe.category_name),
    }
end

-- Legacy PluginData repair: match a pre-DB plan entry to a DB record via
-- profession + result (disambiguated by recipe-name key and category when
-- the old entry carried them). Known records win, then the lowest tier.
function CraftingStore:_resolve_legacy_plan_entry(saved_entry)
    local profession_key = saved_entry.p ~= nil and tostring(saved_entry.p) or nil
    local result_key = saved_entry.r ~= nil and tostring(saved_entry.r) or nil
    if profession_key == nil or result_key == nil then
        return nil
    end
    local name_key = saved_entry.n ~= nil and tostring(saved_entry.n) or nil
    local category_key = saved_entry.c ~= nil and tostring(saved_entry.c) or nil

    local best = nil
    for i = 1, #self.recipes do
        local record = self.recipes[i]
        if record.profession_key == profession_key and record.result_key == result_key then
            local name_ok = name_key == nil or
                name_key == tostring(record.recipe_name_key or record.result_key or "")
            local category_ok = category_key == nil or
                category_key == _normalize_name(record.category_name)
            if name_ok and category_ok then
                if best == nil then
                    best = record
                elseif record.known == true and best.known ~= true then
                    best = record
                elseif (record.known == true) == (best.known == true) and record.tier < best.tier then
                    best = record
                end
            end
        end
    end
    return best
end

function CraftingStore:resolve_saved_plan_entries(saved_entries)
    local resolved_entries = {}
    local unresolved_entries = {}
    local unresolved_count = 0

    if type(saved_entries) ~= "table" then
        return {
            entries = resolved_entries,
            unresolved_entries = unresolved_entries,
            unresolved_count = unresolved_count,
            total_count = 0,
        }
    end

    for i = 1, #saved_entries do
        local saved_entry = saved_entries[i]
        local recipe = nil
        local count = saved_entry ~= nil and (tonumber(saved_entry.q) or 0) or 0
        count = math.floor(count + 0.5)

        if count > 0 and type(saved_entry) == "table" then
            recipe = saved_entry.i ~= nil and self.recipe_by_id[saved_entry.i] or nil
            if _saved_plan_entry_matches_recipe(saved_entry, recipe) ~= true then
                recipe = nil
            end
            if recipe == nil and type(saved_entry.i) == "string" and
                string.find(saved_entry.i, "\30", 1, true) ~= nil then
                -- pre-DB id format ("profession\30index\30result\30name"):
                -- resolve by the identity fields the old entry carried and
                -- migrate the persisted id in place (saved on next save)
                recipe = self:_resolve_legacy_plan_entry(saved_entry)
                if recipe ~= nil then
                    saved_entry.i = recipe.id
                end
            end
        end

        if recipe ~= nil and count > 0 then
            -- saved variant index, clamped against the current catalog
            local variant = math.floor((tonumber(saved_entry.v) or 0) + 0.5)
            if variant < 0 or variant > #recipe.variants then
                variant = 0
            end
            resolved_entries[#resolved_entries + 1] = {
                recipe_id = recipe.id,
                count = count,
                variant = variant,
            }
        elseif count > 0 then
            unresolved_entries[#unresolved_entries + 1] = {
                saved_entry = saved_entry,
                count = count,
            }
            unresolved_count = unresolved_count + 1
        end
    end

    return {
        entries = resolved_entries,
        unresolved_entries = unresolved_entries,
        unresolved_count = unresolved_count,
        total_count = #saved_entries,
    }
end

function CraftingStore:evaluate_plan_resources(plan_entries, scope_key)
    local evaluation = self:evaluate_plan(plan_entries, scope_key)
    local leaf_requirements = {}
    local missing_by_key = {}
    local resources = {}
    local incomplete_resources = {}

    for i = 1, #evaluation.entries do
        local ingredients = evaluation.entries[i] ~= nil and evaluation.entries[i].evaluation ~= nil and
            evaluation.entries[i].evaluation.ingredients or nil
        if type(ingredients) == "table" then
            for ingredient_index = 1, #ingredients do
                _collect_leaf_requirements(ingredients[ingredient_index], leaf_requirements)
            end
        end
    end

    for i = 1, #evaluation.missing_list do
        local missing_entry = evaluation.missing_list[i]
        if type(missing_entry) == "table" and missing_entry.key ~= nil then
            missing_by_key[missing_entry.key] = missing_entry
        end
    end

    for key, requirement in pairs(leaf_requirements) do
        local required = tonumber(requirement ~= nil and requirement.quantity or nil) or 0
        if required > 0 then
            local missing_entry = missing_by_key[key]
            local missing = tonumber(missing_entry ~= nil and missing_entry.quantity or nil) or 0
            local owned = math.max(0, required - missing)
            local item = self:get_item(key)
            local resource = {
                key = key,
                name = item ~= nil and item.name or key,
                item_id = item ~= nil and item.item_id or nil,
                icon_id = item ~= nil and item.icon_id or nil,
                background_image_id = item ~= nil and item.background_image_id or nil,
                quality = item ~= nil and item.quality or nil,
                owned = owned,
                required = required,
                missing = missing,
                complete = missing <= 0,
                source_breakdown = self:get_source_breakdown(key, required, scope_key),
            }
            resources[#resources + 1] = resource
            if resource.complete ~= true then
                incomplete_resources[#incomplete_resources + 1] = resource
            end
        end
    end

    table.sort(resources, _resource_progress_sort_compare)
    table.sort(incomplete_resources, _resource_progress_sort_compare)

    return {
        evaluation = evaluation,
        resources = resources,
        incomplete_resources = incomplete_resources,
        ready = #resources > 0 and #incomplete_resources == 0,
    }
end

function CraftingStore:recipe_uses_item_key(recipe, key_set)
    if type(recipe) ~= "table" or type(key_set) ~= "table" then
        return false
    end

    for i = 1, #recipe.ingredients do
        local ingredient = recipe.ingredients[i]
        if ingredient ~= nil and key_set[ingredient.key] == true then
            return true
        end
    end

    return false
end

function CraftingStore:_capture_live_backpack_counts(current_character)
    local counts = {}
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local backpack = player ~= nil and player.GetBackpack ~= nil and player:GetBackpack() or nil
    if backpack == nil or backpack.GetSize == nil or backpack.GetItem == nil then
        return counts
    end

    local size = tonumber(backpack:GetSize()) or 0
    for index = 1, size do
        local item = backpack:GetItem(index)
        if item ~= nil then
            local item_info = item.GetItemInfo ~= nil and item:GetItemInfo() or nil
            local name = item.GetName ~= nil and item:GetName() or nil
            if (name == nil or name == "") and item_info ~= nil and item_info.GetName ~= nil then
                name = item_info:GetName()
            end

            local key = _normalize_name(name)
            if key ~= "" then
                local quantity = item.GetQuantity ~= nil and item:GetQuantity() or 1
                quantity = tonumber(quantity) or 0
                if quantity > 0 then
                    counts[key] = (counts[key] or 0) + quantity
                end
            end
        end
    end

    return counts
end

function CraftingStore:_build_source_ownership(current_character, live_inventory_counts)
    local source_ownership = {
        [SOURCE_BACKPACK] = {},
        [SOURCE_BANK] = {},
        [SOURCE_VAULT] = {},
        [SOURCE_SHARED] = {},
        [SOURCE_OTHER_CHARACTERS] = {},
    }

    local entries
    if Stores.assets ~= nil and Stores.assets.get_entries ~= nil then
        entries = Stores.assets:get_entries()
    else
        entries = _collect_asset_entries_from_cache()
    end

    if type(entries) ~= "table" then
        return source_ownership
    end

    for i = 1, #entries do
        local record = entries[i]
        local key = _normalize_name(record ~= nil and record.name or nil)
        local quantity = tonumber(record ~= nil and record.quantity or nil) or 0
        if key ~= "" and quantity > 0 then
            local is_current_backpack = record.owner == current_character and record.source_key == SOURCE_BACKPACK
            if is_current_backpack ~= true then
                if record.owner == current_character and record.source_key == SOURCE_BANK then
                    _add_count(source_ownership[SOURCE_BANK], key, quantity)
                elseif record.owner == current_character and record.source_key == SOURCE_VAULT then
                    _add_count(source_ownership[SOURCE_VAULT], key, quantity)
                elseif record.owner ~= current_character and
                    (record.source_key == SOURCE_BACKPACK or record.source_key == SOURCE_BANK or record.source_key == SOURCE_VAULT) then
                    _add_count(source_ownership[SOURCE_OTHER_CHARACTERS], key, quantity)
                end

                if record.source_key == SOURCE_SHARED then
                    _add_count(source_ownership[SOURCE_SHARED], key, quantity)
                end
            end
        end
    end

    if type(live_inventory_counts) == "table" then
        for key, quantity in pairs(live_inventory_counts) do
            local amount = tonumber(quantity) or 0
            if key ~= nil and key ~= "" and amount > 0 then
                source_ownership[SOURCE_BACKPACK][key] = amount
            end
        end
    end

    return source_ownership
end

function CraftingStore:_start_recipe_load(current_character)
    -- the recipes domain is small (~1.3 MB) and profession names come from
    -- it; the heavy Items files are staged one per tick via _step_import
    Lore.load_recipes()

    local professions = {}
    local profession_labels = { TR["All professions"], TR["All my professions"] }
    local profession_values = { FILTER_ALL, FILTER_MINE }
    local known_queue = {}
    local profession_by_db_code = {}
    local owned_keys = {}

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local attributes = player ~= nil and player:GetAttributes() or nil

    -- every DB profession is listed; the character's own get live rank data
    -- and a background known-tagging pass (identity only, never content)
    for i = 1, #PROFESSION_ORDER do
        local profession_enum = PROFESSION_ORDER[i]
        local db_key = DB_PROFESSION_KEYS[profession_enum]
        local profession_info = attributes ~= nil and attributes:GetProfessionInfo(profession_enum) or nil
        local owned = profession_info ~= nil

        local profession_name = nil
        if owned then
            profession_name = _trim(profession_info:GetName())
        end
        if profession_name == nil or profession_name == "" then
            profession_name = Lore.Recipes.profession_name(db_key)
        end

        local profession = {
            profession = profession_enum,
            key = tostring(profession_enum),
            name = profession_name,
            owned = owned,
            recipe_count = 0,
            proficiency_level = owned and (profession_info:GetProficiencyLevel() or 0) or 0,
            proficiency_title = owned and _trim(profession_info:GetProficiencyTitle()) or "",
            mastery_level = owned and (profession_info:GetMasteryLevel() or 0) or 0,
            mastery_title = owned and _trim(profession_info:GetMasteryTitle()) or "",
        }
        professions[#professions + 1] = profession
        profession_labels[#profession_labels + 1] = profession_name
        profession_values[#profession_values + 1] = profession.key
        profession_by_db_code[Lore.Recipes.profession_codes[db_key]] = profession

        if owned then
            owned_keys[profession.key] = true
            local known_count = profession_info:GetRecipeCount() or 0
            if known_count > 0 then
                known_queue[#known_queue + 1] = {
                    profession = profession,
                    profession_info = profession_info,
                    recipe_count = known_count,
                    next_recipe_index = 1,
                }
            end
        end
    end

    self.current_character_name = current_character
    self.professions = professions
    self.profession_by_key = {}
    for i = 1, #professions do
        self.profession_by_key[professions[i].key] = professions[i]
    end
    self.owned_profession_keys = owned_keys
    self.items = {}
    self.recipes = {}
    self.recipe_by_id = {}
    self.known_recipes_by_result = {}
    self.recipes_by_ingredient = {}
    self.recipes_by_result = {}
    self.recipes_by_scroll = {}
    self.recipe_tiers = {}
    self.recipe_tiers_version = 0
    self.profession_option_labels = profession_labels
    self.profession_option_values = profession_values
    self:_reset_status_caches()
    self._recipe_token = tostring(current_character or "")
    self._recipes_initialized = true
    -- phase 1: stage the heavy Items imports, one file per tick (the plan
    -- is empty when another feature already loaded the domain)
    self._import_queue = Lore.items_import_plan()
    self._import_index = 1
    self._import_total = #self._import_queue
    self._import_done = 0
    -- phase 2: build records straight from the DB, ordinal cursor, batched
    self._profession_by_db_code = profession_by_db_code
    self._recipe_loading = true
    self._recipe_load_next = 1
    self._recipe_load_done = 0
    self._recipe_load_total = Lore.Recipes.count
    -- phase 3: background known-tagging over the in-game book
    self._known_queue = known_queue
    self._known_loading = false
    self._pending_loaded_result_keys = {}
end

function CraftingStore:_step_import()
    -- check-first: an already-loaded domain yields an empty plan
    if self._import_index <= self._import_total then
        Lore.import_step(self._import_queue[self._import_index])
        self._import_index = self._import_index + 1
        self._import_done = self._import_done + 1
    end
    if self._import_index > self._import_total then
        self._import_queue = nil
        Lore.load_items()
    end
end

function CraftingStore:_register_recipe_record(record)
    if type(record) ~= "table" then
        return
    end

    self.recipes[#self.recipes + 1] = record
    self.recipe_by_id[record.id] = record

    -- ingredient -> recipes: selective status invalidation on stock changes
    for i = 1, #record.ingredients do
        local key = record.ingredients[i].key
        local list = self.recipes_by_ingredient[key]
        if list == nil then
            list = {}
            self.recipes_by_ingredient[key] = list
        end
        list[#list + 1] = record
    end

    -- outputs -> recipes over the full catalog (known or not), covering the
    -- critical result and every alternate-version output: cross-window
    -- "how to craft" links resolve the producing recipe here
    local output_keys = { record.result_key }
    if record.critical_result_key ~= nil then
        output_keys[#output_keys + 1] = record.critical_result_key
    end
    for i = 1, #record.variants do
        local variant = record.variants[i]
        output_keys[#output_keys + 1] = variant.result_key
        if variant.critical_result_key ~= nil then
            output_keys[#output_keys + 1] = variant.critical_result_key
        end
    end
    local seen_outputs = {}
    for i = 1, #output_keys do
        local key = output_keys[i]
        if seen_outputs[key] == nil then
            seen_outputs[key] = true
            local result_list = self.recipes_by_result[key]
            if result_list == nil then
                result_list = {}
                self.recipes_by_result[key] = result_list
            end
            result_list[#result_list + 1] = record
        end
    end

    -- scroll item -> the recipe it teaches: Encyclopedia recipe-scroll
    -- rows resolve their anvil link here
    if record.scroll_item_id ~= nil then
        self.recipes_by_scroll[record.scroll_item_id] = record
    end

    -- distinct tiers, maintained incrementally so the rank dropdown never
    -- rescans the whole catalog
    if self.recipe_tiers[record.tier] == nil then
        self.recipe_tiers[record.tier] = true
        self.recipe_tiers_version = self.recipe_tiers_version + 1
    end
end

function CraftingStore:_remember_loaded_recipe_result(record)
    if type(record) ~= "table" then
        return
    end
    if type(self._pending_loaded_result_keys) ~= "table" then
        self._pending_loaded_result_keys = {}
    end
    if record.result_key ~= nil then
        self._pending_loaded_result_keys[record.result_key] = true
    end
    if record.recipe_name_key ~= nil then
        self._pending_loaded_result_keys[record.recipe_name_key] = true
    end
end

function CraftingStore:_step_recipe_load(batch_size)
    if self._recipe_loading ~= true then
        return false
    end

    local remaining = tonumber(batch_size) or BACKGROUND_RECIPE_BATCH_SIZE
    if remaining < 1 then
        remaining = BACKGROUND_RECIPE_BATCH_SIZE
    end

    local changed = false
    local total = self._recipe_load_total
    while remaining > 0 and self._recipe_load_next <= total do
        local ordinal = self._recipe_load_next
        local profession = self._profession_by_db_code[Lore.Recipes.profession_code(ordinal)]
        local record = self:_build_db_recipe_record(ordinal, profession)
        self:_register_recipe_record(record)
        self:_remember_loaded_recipe_result(record)
        profession.recipe_count = profession.recipe_count + 1

        self._recipe_load_done = self._recipe_load_done + 1
        self._recipe_load_next = self._recipe_load_next + 1
        remaining = remaining - 1
        changed = true
    end

    if self._recipe_load_next > total then
        self._recipe_loading = false
        table.sort(self.recipes, function(left, right)
            return left.sort_key < right.sort_key
        end)
        self._recipe_token = table.concat({
            tostring(self.current_character_name or ""),
            tostring(#self.professions),
            tostring(#self.recipes),
        }, "\30")
        self:_reset_status_caches()
        self._known_loading = #self._known_queue > 0
    end

    return changed
end

-- sorted required-ingredient quantities, e.g. "1,2,4": cheap discriminator
-- for same-name bulk/conversion variants (no ItemInfo access)
local function _api_ingredient_signature(recipe)
    local counts = {}
    local n = tonumber(recipe:GetIngredientCount()) or 0
    for i = 1, n do
        local ingredient = recipe:GetIngredient(i)
        if ingredient ~= nil then
            counts[#counts + 1] = math.max(1, tonumber(ingredient:GetRequiredQuantity()) or 1)
        end
    end
    table.sort(counts)
    return table.concat(counts, ",")
end

function CraftingStore:_mark_recipe_known(record, register_expansion)
    if record.known == true then
        return
    end
    record.known = true
    -- register_expansion is false for loose (level-1 drift) matches: those
    -- stay visible under "Known" but must never satisfy material trees.
    -- Conversions register too (prepended, so _satisfy_item tries them
    -- first); they only ever draw one step from on-hand scraps.
    if register_expansion == true then
        local prepend = record.conversion == true
        _add_result_index_entry(self.known_recipes_by_result, record.result_key, record, prepend)
        if record.recipe_name_key ~= nil then
            _add_result_index_entry(self.known_recipes_by_result, record.recipe_name_key, record, prepend)
        end
    end
end

-- Tag records the character actually knows. Identity only (localized name,
-- tier and category per book entry); runs in the background after the DB
-- list is built and never blocks the recipe list. Several DB records can
-- share one identity (alternate-ingredient variants, conversion siblings) -
-- every record matching the book entry is tagged, category-exact matches
-- preferred.
function CraftingStore:_step_known_pass()
    if self._known_loading ~= true then
        return false
    end

    local remaining = KNOWN_PASS_BATCH_SIZE
    local processed = false
    while remaining > 0 and #self._known_queue > 0 do
        local entry = self._known_queue[1]
        local recipe = entry.profession_info:GetRecipe(entry.next_recipe_index)
        if recipe ~= nil then
            local name = _trim(recipe:GetName())
            local tier = tonumber(recipe:GetTier()) or 0
            local category_name = _trim(recipe:GetCategoryName())
            local ordinals = name ~= "" and Lore.Recipes.find_ordinals(name) or nil
            if ordinals ~= nil then
                local db_code = Lore.Recipes.profession_codes[DB_PROFESSION_KEYS[entry.profession.profession]]
                local candidates, n = {}, 0
                for k = 1, #ordinals do
                    local ordinal = ordinals[k]
                    if Lore.Recipes.profession_code(ordinal) == db_code and Lore.Recipes.tier_of(ordinal) == tier then
                        local record = self.recipe_by_id[tostring(Lore.Recipes.id_of(ordinal))]
                        if record ~= nil then
                            n = n + 1
                            candidates[n] = record
                        end
                    end
                end
                -- tag the most specific identity level the API can express:
                -- 3 = category + result quantity + ingredient quantities
                --     (separates same-name bulk/conversion variants)
                -- 2 = category
                -- 1 = profession + tier (drift fallback; never leave the
                --     book entry untagged)
                local result_quantity = math.max(1, tonumber(recipe:GetResultItemQuantity()) or 1)
                local ingredient_signature = _api_ingredient_signature(recipe)
                local levels, best = {}, 0
                for k = 1, n do
                    local record = candidates[k]
                    local level = 1
                    if record.category_name == category_name then
                        level = 2
                        if record.result_quantity == result_quantity and
                            record.ingredient_signature == ingredient_signature then
                            level = 3
                        end
                    end
                    levels[k] = level
                    if level > best then
                        best = level
                    end
                end
                for k = 1, n do
                    if levels[k] == best then
                        -- loose matches stay out of the expansion index
                        self:_mark_recipe_known(candidates[k], best >= 2)
                    end
                end
            end
        end

        entry.next_recipe_index = entry.next_recipe_index + 1
        if entry.next_recipe_index > entry.recipe_count then
            table.remove(self._known_queue, 1)
        end
        remaining = remaining - 1
        processed = true
    end

    if #self._known_queue == 0 then
        self._known_loading = false
        self._known_queue = nil
        -- craftability can change now that known recipes may expand
        -- material trees; recompute statuses on demand
        self:_reset_status_caches()
        return true
    end
    -- report every batch so the window refreshes progressively while the
    -- default "Known" view fills in
    return processed
end

-- Register an item from the local lore DB into self.items, keyed like the
-- API path (normalized localized name). Returns key, display name; nil when
-- the item is not in the local DB (data drop older than the game).
function CraftingStore:_remember_db_item(item_id)
    local ordinal = Lore.Items.ordinal_of(item_id)
    if ordinal == nil then
        return nil, nil
    end
    local name = Lore.Items.label(ordinal)
    local key = _normalize_name(name)
    if key == "" then
        return nil, nil
    end

    local current = self.items[key]
    if type(current) ~= "table" then
        local icon_id, background_id = Lore.Items.icon_layers(ordinal)
        current = {
            key = key,
            name = name,
            -- Spanish name, search-only: lets a player type the Spanish
            -- item name and still land on this (English-displayed) result
            name_es = Lore.Items.label_es and Lore.Items.label_es(ordinal) or nil,
            item_id = item_id,
            icon_id = icon_id,
            background_image_id = background_id,
            quality = DB_QUALITY_TO_LOTRO[Lore.Items.quality_name(ordinal)],
            required_level = Lore.Items.min_level(ordinal),
        }
        self.items[key] = current
    end
    return key, current.name
end

-- Build a recipe record straight from the local lore DB. Returns nil for
-- records that are not products (obsolete conversion categories) or whose
-- item references are missing from the local items DB.
function CraftingStore:_build_db_recipe_record(ordinal, profession)
    local rec = Lore.Recipes.decode(ordinal)
    local recipe_name = Lore.Recipes.label(ordinal)
    local tier = rec.tier

    local category_name = Lore.Recipes.category_name(rec.category)
    if _is_obsolete_conversion_category(category_name) == true then
        return nil
    end

    local version = rec.versions[1]
    if version == nil or version.results[1] == nil then
        return nil
    end

    local result_key, result_name = self:_remember_db_item(version.results[1][1])
    if result_key == nil then
        return nil
    end

    local critical_result_key = nil
    local critical_result_quantity = 0
    local critical_result_item_id = nil
    if version.crit_results[1] ~= nil then
        local crit_key = self:_remember_db_item(version.crit_results[1][1])
        if crit_key ~= nil then
            critical_result_key = crit_key
            critical_result_quantity = version.crit_results[1][2]
            -- crit outputs can share their display name with the base item
            -- (teal upgrades); the name-keyed items map would then return
            -- the base item, so displays must resolve by this real id
            critical_result_item_id = version.crit_results[1][1]
        end
    end

    local ingredients = {}
    for i = 1, #version.ingredients do
        local entry = version.ingredients[i]
        local key = self:_remember_db_item(entry[1])
        if key == nil then
            return nil
        end
        ingredients[#ingredients + 1] = {
            key = key,
            quantity = entry[2],
        }
    end

    -- alternate outputs: versions past the first are the same craft with a
    -- different output choice at the workbench; costs/status stay
    -- version-1 based, variants exist for display, search and result links
    local variants = {}
    for vi = 2, #rec.versions do
        local alt = rec.versions[vi]
        if alt.results[1] ~= nil then
            local alt_key = self:_remember_db_item(alt.results[1][1])
            if alt_key ~= nil then
                local alt_crit_key = nil
                local alt_crit_quantity = 0
                if alt.crit_results[1] ~= nil then
                    alt_crit_key = self:_remember_db_item(alt.crit_results[1][1])
                    alt_crit_quantity = alt.crit_results[1][2]
                end
                variants[#variants + 1] = {
                    result_key = alt_key,
                    result_quantity = alt.results[1][2],
                    result_item_id = alt.results[1][1],
                    critical_result_key = alt_crit_key,
                    critical_result_quantity = alt_crit_quantity,
                    critical_result_item_id = alt_crit_key ~= nil and alt.crit_results[1][1] or nil,
                    critical_chance = alt.crit,
                }
            end
        end
    end

    local recipe_name_key = _normalize_name(recipe_name)
    local record = {
        id = tostring(rec.id),
        profession = profession.profession,
        profession_key = profession.key,
        profession_name = profession.name,
        category_name = category_name,
        conversion = rec.conversion,
        tier = tier,
        cooldown = rec.cooldown,
        critical_chance = version.crit,
        result_key = result_key,
        critical_result_key = critical_result_key,
        critical_result_quantity = critical_result_quantity,
        recipe_name_key = recipe_name_key ~= "" and recipe_name_key ~= result_key and recipe_name_key or nil,
        recipe_name = recipe_name ~= "" and recipe_name ~= result_name and recipe_name or nil,
        result_quantity = version.results[1][2],
        result_item_id = version.results[1][1],
        critical_result_item_id = critical_result_item_id,
        ingredients = ingredients,
        variants = variants,
        scroll_item_id = rec.scroll,
    }

    -- hot paths read prepared values: search and sort must stay allocation-
    -- free across the full recipe catalog
    local recipe_name_es = Lore.Recipes.label_es and Lore.Recipes.label_es(ordinal) or nil
    local search_parts = {
        _lower(result_name),
        _lower(profession.name),
        _lower(category_name),
        _lower(record.recipe_name),
    }
    if recipe_name_es ~= nil then
        -- Spanish recipe name: search-only, results still render in
        -- whatever language the client is running (see Items.L_ES)
        search_parts[#search_parts + 1] = _lower(recipe_name_es)
    end
    local function _push_item_es(key)
        local es_name = self.items[key].name_es
        if es_name ~= nil then
            search_parts[#search_parts + 1] = _lower(es_name)
        end
    end
    for i = 1, #ingredients do
        search_parts[#search_parts + 1] = _lower(self.items[ingredients[i].key].name)
        _push_item_es(ingredients[i].key)
    end
    if critical_result_key ~= nil then
        search_parts[#search_parts + 1] = _lower(self.items[critical_result_key].name)
        _push_item_es(critical_result_key)
    end
    for i = 1, #variants do
        search_parts[#search_parts + 1] = _lower(self.items[variants[i].result_key].name)
        _push_item_es(variants[i].result_key)
        if variants[i].critical_result_key ~= nil then
            search_parts[#search_parts + 1] = _lower(self.items[variants[i].critical_result_key].name)
            _push_item_es(variants[i].critical_result_key)
        end
    end
    local quantity_counts = {}
    for i = 1, #ingredients do
        quantity_counts[i] = ingredients[i].quantity
    end
    table.sort(quantity_counts)
    record.ingredient_signature = table.concat(quantity_counts, ",")

    record.search_text = table.concat(search_parts, "\n")
    record.sort_key = table.concat({
        _lower(profession.name),
        _lower(result_name),
        _lower(record.recipe_name),
        record.id,
    }, "\30")

    return record
end

function CraftingStore:_merge_missing_maps(destination, source)
    if type(source) ~= "table" then
        return
    end

    for key, entry in pairs(source) do
        if type(entry) == "table" and (tonumber(entry.quantity) or 0) > 0 then
            if type(destination[key]) ~= "table" then
                destination[key] = {
                    key = key,
                    quantity = 0,
                }
            end
            destination[key].quantity = (tonumber(destination[key].quantity) or 0) + (tonumber(entry.quantity) or 0)
        end
    end
end

function CraftingStore:_make_missing_entry(item_key, quantity)
    return {
        key = item_key,
        quantity = quantity,
    }
end

function CraftingStore:_get_recipes_for_item(item_key)
    -- material-tree expansion only walks through recipes the character
    -- knows: expanding through the full catalog of unlearned recipes is both
    -- wrong ("craftable" would assume recipes you cannot craft) and
    -- combinatorially explosive
    local list = self.known_recipes_by_result[item_key]
    if type(list) == "table" and #list > 0 then
        return list
    end

    return nil
end

function CraftingStore:_satisfy_item(stock, item_key, quantity, visiting, stock_only)
    local needed = math.max(0, tonumber(quantity) or 0)
    local node = {
        key = item_key,
        required = needed,
        from_stock = 0,
        produced = 0,
        craft_count = 0,
        satisfied = false,
        expanded = false,
        ambiguous = false,
        missing = 0,
        recipe_id = nil,
        children = nil,
    }

    local next_stock = _copy_counts(stock)
    if needed <= 0 then
        node.satisfied = true
        return true, node, next_stock, {}
    end

    local available = tonumber(next_stock[item_key]) or 0
    if available > 0 then
        local used = math.min(available, needed)
        node.from_stock = used
        next_stock[item_key] = available - used
        needed = needed - used
    end

    if needed <= 0 then
        node.satisfied = true
        return true, node, next_stock, {}
    end

    local recipes = nil
    if stock_only ~= true then
        recipes = self:_get_recipes_for_item(item_key)
    end
    if recipes == nil or visiting[item_key] == true then
        node.missing = needed
        node.satisfied = false
        return false, node, next_stock, {
            [item_key] = self:_make_missing_entry(item_key, needed),
        }
    end

    local best_failed_node = nil
    local best_failed_stock = nil
    local best_failed_missing = nil
    local best_failed_total = nil
    local best_failed_distinct = nil

    -- conversion ("scraps") recipes come first in the index (prepended at
    -- registration) and may only draw their ingredients from on-hand stock
    -- (their children never expand, so conversion pairs cannot loop): own
    -- enough scraps and the tree starts there, otherwise regular recipes
    -- craft from the base resource
    for recipe_index = 1, #recipes do
        local recipe = recipes[recipe_index]
        if _recipe_reenters_path(recipe, visiting) ~= true then
            local branch_stock = _copy_counts(next_stock)
            local per_craft = math.max(1, tonumber(recipe.result_quantity) or 1)
            local crafts_needed = math.floor(((needed + per_craft - 1) / per_craft) + 0.0)
            local combined_missing = {}
            local all_ok = true
            local candidate_node = {
                key = node.key,
                required = node.required,
                from_stock = node.from_stock,
                produced = 0,
                craft_count = crafts_needed,
                satisfied = false,
                expanded = true,
                ambiguous = false,
                missing = 0,
                recipe_id = recipe.id,
                children = {},
            }

            visiting[item_key] = true
            for i = 1, #recipe.ingredients do
                local ingredient = recipe.ingredients[i]
                local child_ok, child_node, child_stock, child_missing = self:_satisfy_item(
                    branch_stock,
                    ingredient.key,
                    ingredient.quantity * crafts_needed,
                    visiting,
                    recipe.conversion == true
                )
                branch_stock = child_stock
                candidate_node.children[#candidate_node.children + 1] = child_node
                self:_merge_missing_maps(combined_missing, child_missing)
                if child_ok ~= true then
                    all_ok = false
                end
            end
            visiting[item_key] = nil

            if all_ok == true then
                local produced = crafts_needed * per_craft
                candidate_node.produced = produced
                candidate_node.satisfied = true
                local leftover = produced - needed
                if leftover > 0 then
                    branch_stock[item_key] = (tonumber(branch_stock[item_key]) or 0) + leftover
                end
                return true, candidate_node, branch_stock, combined_missing
            end

            candidate_node.missing = needed
            candidate_node.satisfied = false
            local missing_total = _sum_missing_map(combined_missing)
            local missing_distinct = 0
            for _ in pairs(combined_missing) do
                missing_distinct = missing_distinct + 1
            end

            if best_failed_node == nil or
                missing_total < best_failed_total or
                (missing_total == best_failed_total and missing_distinct < best_failed_distinct) then
                best_failed_node = candidate_node
                best_failed_stock = branch_stock
                best_failed_missing = combined_missing
                best_failed_total = missing_total
                best_failed_distinct = missing_distinct
            end
        end
    end

    if best_failed_node ~= nil then
        return false, best_failed_node, best_failed_stock, best_failed_missing
    end

    node.missing = needed
    node.satisfied = false
    return false, node, next_stock, {
        [item_key] = self:_make_missing_entry(item_key, needed),
    }
end

function CraftingStore:_node_has_expansion(node)
    if type(node) ~= "table" then
        return false
    end
    if node.expanded == true then
        return true
    end
    if type(node.children) ~= "table" then
        return false
    end
    for i = 1, #node.children do
        if self:_node_has_expansion(node.children[i]) == true then
            return true
        end
    end
    return false
end

function CraftingStore:_evaluate_recipe_with_stock(recipe, craft_count, stock)
    local count = math.max(1, math.floor((tonumber(craft_count) or 1) + 0.5))
    local base_stock = _copy_counts(stock)
    local working_stock = _copy_counts(stock)
    local evaluation = {
        requested_count = count,
        ingredients = {},
        missing = {},
        missing_list = {},
        missing_total = 0,
        craftable = true,
        used_expansion = false,
        remaining_stock = working_stock,
    }

    for i = 1, #recipe.ingredients do
        local ingredient = recipe.ingredients[i]
        local required = ingredient.quantity * count
        local ingredient_ok, node, next_stock, child_missing = self:_satisfy_item(
            working_stock,
            ingredient.key,
            required,
            {},
            recipe.conversion == true
        )

        working_stock = next_stock
        node.required = required
        node.owned_in_scope = tonumber(base_stock[ingredient.key]) or 0
        node.satisfied = ingredient_ok == true
        evaluation.ingredients[#evaluation.ingredients + 1] = node
        self:_merge_missing_maps(evaluation.missing, child_missing)

        if ingredient_ok ~= true then
            evaluation.craftable = false
        end
        if self:_node_has_expansion(node) == true then
            evaluation.used_expansion = true
        end
    end

    evaluation.remaining_stock = working_stock
    evaluation.missing_total = _sum_missing_map(evaluation.missing)
    evaluation.missing_list = _missing_map_to_list(evaluation.missing)
    return evaluation
end

function CraftingStore:_count_craftable_with_stock(recipe, craft_count, stock)
    local requested = math.max(0, math.floor((tonumber(craft_count) or 0) + 0.5))
    if requested <= 0 or type(recipe) ~= "table" then
        return 0
    end

    local working_stock = _copy_counts(stock)
    local craftable_count = 0

    for _ = 1, requested do
        local evaluation = self:_evaluate_recipe_with_stock(recipe, 1, working_stock)
        if evaluation == nil or evaluation.craftable ~= true then
            break
        end
        craftable_count = craftable_count + 1
        working_stock = _copy_counts(evaluation.remaining_stock)
    end

    return craftable_count
end

function CraftingStore:_max_craftable_with_stock(recipe, stock, limit)
    local max_count = math.max(1, math.floor((tonumber(limit) or RECIPE_STATUS_CRAFT_LIMIT) + 0.5))
    local low = 0
    local high = max_count

    while low < high do
        local mid = math.floor((low + high + 1) / 2)
        local evaluation = self:_evaluate_recipe_with_stock(recipe, mid, stock)
        if evaluation ~= nil and evaluation.craftable == true then
            low = mid
        else
            high = mid - 1
        end
    end

    return low
end
