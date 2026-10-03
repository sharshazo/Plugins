-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Persistence = _G.LUI.Settings.Persistence
local AssetCache = _G.LUI.Runtime.Caches.Assets
local Stores = _G.LUI.Runtime.Stores
local Flags = _G.LUI.Runtime.Flags
local State = _G.LUI.Settings.State
local Assets = _G.LUI.Features.Assets
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.Utils.callbacks"

local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local AssetsStore = class(Turbine.UI.Control)
Assets.AssetsStore = AssetsStore

local UPDATE_EVERY = 0.50
local SOURCE_BACKPACK = "backpack"
local SOURCE_BANK = "bank"
local SOURCE_VAULT = "vault"
local SOURCE_SHARED = "shared_storage"

local function _lower(text)
    if type(text) ~= "string" then
        return ""
    end

    return string.lower(text)
end

local function _safe_text(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function _safe_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end

    if value == nil then
        return fallback
    end

    return value
end

local function _copy_table_shallow(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end

    for key, value in pairs(source) do
        out[key] = value
    end

    return out
end

local function _inc_count(map, key)
    if key == nil then
        return
    end
    map[key] = (map[key] or 0) + 1
end

local function _get_current_character_name()
    if type(State.current_character_name) == "string" and string.len(State.current_character_name) > 0 then
        return State.current_character_name
    end

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player ~= nil and player.GetName ~= nil then
        local name = player:GetName()
        if type(name) == "string" and string.len(name) > 0 then
            return name
        end
    end

    return "__unknown_character__"
end

local function _ensure_assets_cache()
    if Persistence.ensure_assets_cache ~= nil then
        return Persistence.ensure_assets_cache()
    end

    if type(AssetCache.data) ~= "table" then
        AssetCache.data = {}
    end

    local cache = AssetCache.data
    if type(cache.characters) ~= "table" then
        cache.characters = {}
    end
    if type(cache.shared_storage) ~= "table" then
        cache.shared_storage = { items = {} }
    elseif type(cache.shared_storage.items) ~= "table" then
        cache.shared_storage.items = {}
    end

    return cache
end

local function _ensure_character_cache(cache, character_name)
    if type(cache.characters[character_name]) ~= "table" then
        cache.characters[character_name] = {}
    end

    local character_cache = cache.characters[character_name]
    if type(character_cache.backpack) ~= "table" then
        character_cache.backpack = { items = {} }
    end
    if type(character_cache.bank) ~= "table" then
        character_cache.bank = { items = {} }
    end
    if type(character_cache.vault) ~= "table" then
        character_cache.vault = { items = {} }
    end

    return character_cache
end

local function _make_location(owner, source_key)
    if source_key == SOURCE_BACKPACK then
        return owner, TR["Backpack"]
    end
    if source_key == SOURCE_BANK then
        return owner, TR["Bank"]
    end
    if source_key == SOURCE_VAULT then
        return owner, TR["Vault"]
    end

    return "", TR["Shared Storage"]
end

local function _make_runtime_key(owner, source_key, slot)
    return table.concat({
        _safe_text(source_key),
        _safe_text(owner),
        tostring(slot or 0),
    }, "\30")
end

local function _make_visual_key(name, icon_id, quality)
    return table.concat({
        _lower(name),
        tostring(icon_id or 0),
        tostring(quality or 0),
    }, "\30")
end

local function _make_quality_key(quality)
    return tostring(quality or 0)
end

local function _item_info_background_image_id(item_info)
    if item_info == nil then
        return nil
    end

    local background_image_id = nil
    if item_info.GetBackgroundImageID ~= nil then
        background_image_id = _safe_number(item_info:GetBackgroundImageID(), nil)
        if background_image_id == 0 then
            background_image_id = nil
        end
    end
    if background_image_id == nil and item_info.GetQualityImageID ~= nil then
        background_image_id = _safe_number(item_info:GetQualityImageID(), nil)
        if background_image_id == 0 then
            background_image_id = nil
        end
    end

    return background_image_id
end

local function _item_info_icon_image_id(item_info)
    if item_info == nil or item_info.GetIconImageID == nil then
        return nil
    end

    local icon_id = _safe_number(item_info:GetIconImageID(), nil)
    if icon_id == 0 then
        return nil
    end

    return icon_id
end

local function _collect_visual_record(lookup, record)
    if type(record) ~= "table" then
        return
    end

    local icon_id = record.icon_id
    local background_image_id = record.background_image_id
    local quality = record.quality
    local name = record.name
    if background_image_id == nil or icon_id == nil then
        return
    end

    lookup.by_exact[_make_visual_key(name, icon_id, quality)] = background_image_id
    if lookup.by_icon[tostring(icon_id)] == nil then
        lookup.by_icon[tostring(icon_id)] = background_image_id
    end

    local quality_key = _make_quality_key(quality)
    if type(lookup.quality_counts[quality_key]) ~= "table" then
        lookup.quality_counts[quality_key] = {}
    end
    _inc_count(lookup.quality_counts[quality_key], tostring(background_image_id))
end

local function _resolve_quality_background_image_id(lookup, quality)
    local quality_counts = lookup.quality_counts[_make_quality_key(quality)]
    if type(quality_counts) ~= "table" then
        return nil
    end

    local best_background_image_id = nil
    local best_count = 0
    for background_key, count in pairs(quality_counts) do
        if count > best_count then
            best_count = count
            best_background_image_id = _safe_number(background_key, nil)
        end
    end

    return best_background_image_id
end

local function _apply_visual_fallbacks(record, live, lookup)
    if type(record) ~= "table" then
        return
    end

    local item_info = live ~= nil and live.item_info or nil

    if record.icon_id == nil then
        record.icon_id = _item_info_icon_image_id(item_info)
    end

    if record.background_image_id == nil then
        record.background_image_id = _item_info_background_image_id(item_info)
    end

    if record.background_image_id == nil and record.icon_id ~= nil then
        record.background_image_id = lookup.by_exact[_make_visual_key(record.name, record.icon_id, record.quality)]
    end
    if record.background_image_id == nil and record.icon_id ~= nil then
        record.background_image_id = lookup.by_icon[tostring(record.icon_id)]
    end
    if record.background_image_id == nil then
        record.background_image_id = _resolve_quality_background_image_id(lookup, record.quality)
    end
end

local function _build_item_record(item, owner, source_key, slot)
    if item == nil then
        return nil
    end

    local info = item.GetItemInfo ~= nil and item:GetItemInfo() or nil
    if info == nil then
        return nil
    end

    local name = ""
    if info.GetName ~= nil then
        name = _safe_text(info:GetName())
    elseif item.GetName ~= nil then
        name = _safe_text(item:GetName())
    end

    if string.len(name) == 0 then
        return nil
    end

    local quantity = 1
    if item.GetQuantity ~= nil then
        quantity = _safe_number(item:GetQuantity(), 1)
    end
    if quantity < 1 then
        quantity = 1
    end

    local icon_id = nil
    if info.GetIconImageID ~= nil then
        icon_id = _safe_number(info:GetIconImageID(), nil)
        if icon_id == 0 then
            icon_id = nil
        end
    end

    local background_image_id = nil
    if info.GetBackgroundImageID ~= nil then
        background_image_id = _safe_number(info:GetBackgroundImageID(), nil)
        if background_image_id == 0 then
            background_image_id = nil
        end
    end
    if background_image_id == nil and info.GetQualityImageID ~= nil then
        background_image_id = _safe_number(info:GetQualityImageID(), nil)
        if background_image_id == 0 then
            background_image_id = nil
        end
    end

    local quality = nil
    if info.GetQuality ~= nil then
        quality = info:GetQuality()
    end

    local location_owner, location_source = _make_location(owner, source_key)

    return {
        name = name,
        quantity = quantity,
        icon_id = icon_id,
        background_image_id = background_image_id,
        quality = quality,
        owner = location_owner,
        slot = slot,
        source_key = source_key,
        source_name = location_source,
    }
end

local function _compare_records(left, right)
    local left_name = _lower(left ~= nil and left.name or nil)
    local right_name = _lower(right ~= nil and right.name or nil)
    if left_name ~= right_name then
        return left_name < right_name
    end

    local left_owner = _lower(left ~= nil and left.owner or nil)
    local right_owner = _lower(right ~= nil and right.owner or nil)
    if left_owner ~= right_owner then
        return left_owner < right_owner
    end

    local left_source = _lower(left ~= nil and left.source_name or nil)
    local right_source = _lower(right ~= nil and right.source_name or nil)
    if left_source ~= right_source then
        return left_source < right_source
    end

    local left_quantity = left ~= nil and left.quantity or 0
    local right_quantity = right ~= nil and right.quantity or 0
    if left_quantity ~= right_quantity then
        return left_quantity < right_quantity
    end

    local left_icon = left ~= nil and left.icon_id or 0
    local right_icon = right ~= nil and right.icon_id or 0
    if left_icon ~= right_icon then
        return left_icon < right_icon
    end

    local left_background = left ~= nil and left.background_image_id or 0
    local right_background = right ~= nil and right.background_image_id or 0
    if left_background ~= right_background then
        return left_background < right_background
    end

    local left_quality = left ~= nil and left.quality or 0
    local right_quality = right ~= nil and right.quality or 0
    return left_quality < right_quality
end

local function _records_equal(left, right)
    if left == right then
        return true
    end
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end
    if #left ~= #right then
        return false
    end

    for i = 1, #left do
        local a = left[i]
        local b = right[i]
        if type(a) ~= "table" or type(b) ~= "table" then
            return false
        end
        if a.name ~= b.name or
            a.quantity ~= b.quantity or
            a.icon_id ~= b.icon_id or
            a.background_image_id ~= b.background_image_id or
            a.quality ~= b.quality or
            a.owner ~= b.owner or
            a.slot ~= b.slot or
            a.source_key ~= b.source_key or
            a.source_name ~= b.source_name then
            return false
        end
    end

    return true
end

local function _snapshot_backpack_items(backpack, character_name)
    local items = {}
    if backpack == nil or backpack.GetSize == nil or backpack.GetItem == nil then
        return items
    end

    local size = _safe_number(backpack:GetSize(), 0)
    for index = 1, size do
        local item = backpack:GetItem(index)
        local record = _build_item_record(item, character_name, SOURCE_BACKPACK, index)
        if record ~= nil then
            items[#items + 1] = record
        end
    end

    table.sort(items, _compare_records)
    return items
end

local function _snapshot_bank_items(bank, character_name, source_key)
    local items = {}
    if bank == nil or bank.IsAvailable == nil or bank:IsAvailable() ~= true then
        return nil
    end
    if bank.GetCount == nil or bank.GetItem == nil then
        return items
    end

    local count = _safe_number(bank:GetCount(), 0)
    for index = 1, count do
        local item = bank:GetItem(index)
        local record = _build_item_record(item, character_name, source_key, index)
        if record ~= nil then
            items[#items + 1] = record
        end
    end

    table.sort(items, _compare_records)
    return items
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function AssetsStore:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetVisible(false)
    self:SetWantsUpdates(true)

    self.update_every = UPDATE_EVERY
    self.last_update_at = 0

    self.character_name = _get_current_character_name()

    self.player = nil
    self.backpack = nil
    self.bank = nil
    self.vault = nil
    self.shared_storage = nil

    self._has_backpack_method = false
    self._has_bank_method = false
    self._has_vault_method = false
    self._has_shared_method = false

    self._callbacks = {}

    self._backpack_dirty = true
    self._bank_dirty = true
    self._vault_dirty = true
    self._shared_dirty = true

    self._bank_available = nil
    self._vault_available = nil
    self._shared_available = nil

    self.generation = 1

    self:refresh_bindings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

function AssetsStore:destroy()
    self:_mark_all_dirty()
    self:_refresh_availability_flags()
    local changed = self:_flush_dirty_snapshots()
    if changed == true then
        self.generation = self.generation + 1
        AssetCache.dirty = true
    end

    self:_detach_callbacks()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function AssetsStore:refresh_bindings()
    self:refresh_now(nil, true)
end

function AssetsStore:refresh_now(source_key, force_bindings)
    local bindings_changed = self:_sync_bindings(force_bindings == true)
    if bindings_changed ~= true then
        self:_mark_source_dirty(source_key)
    end

    self:_refresh_availability_flags()

    local changed = self:_flush_dirty_snapshots()
    if changed == true then
        self.generation = self.generation + 1
        AssetCache.dirty = true
    end

    return changed
end

function AssetsStore:get_entries()
    local cache = _ensure_assets_cache()
    local shared_storage_cache = cache.shared_storage
    local live_info = self:_build_live_info_map()
    local visual_lookup = self:_build_visual_lookup(live_info)
    local entries = {}

    local character_names = {}
    for character_name, character_cache in pairs(cache.characters) do
        if type(character_cache) == "table" then
            character_names[#character_names + 1] = character_name
        end
    end

    table.sort(character_names, function(left, right)
        if left == self.character_name then
            return true
        end
        if right == self.character_name then
            return false
        end
        return _lower(left) < _lower(right)
    end)

    for i = 1, #character_names do
        local character_cache = cache.characters[character_names[i]]
        local backpack_items = character_cache ~= nil and character_cache.backpack ~= nil and character_cache.backpack.items or nil
        if type(backpack_items) == "table" then
            for j = 1, #backpack_items do
                local record = _copy_table_shallow(backpack_items[j])
                local live = live_info[_make_runtime_key(record.owner, record.source_key, record.slot)]
                if live ~= nil then
                    record.item = live.item
                    record.item_info = live.item_info
                end
                _apply_visual_fallbacks(record, live, visual_lookup)
                entries[#entries + 1] = record
            end
        end

        local bank_items = character_cache ~= nil and character_cache.bank ~= nil and character_cache.bank.items or nil
        if type(bank_items) == "table" then
            for j = 1, #bank_items do
                local record = _copy_table_shallow(bank_items[j])
                local live = live_info[_make_runtime_key(record.owner, record.source_key, record.slot)]
                if live ~= nil then
                    record.item = live.item
                    record.item_info = live.item_info
                end
                _apply_visual_fallbacks(record, live, visual_lookup)
                entries[#entries + 1] = record
            end
        end

        local vault_items = character_cache ~= nil and character_cache.vault ~= nil and character_cache.vault.items or nil
        if type(vault_items) == "table" then
            for j = 1, #vault_items do
                local record = _copy_table_shallow(vault_items[j])
                local live = live_info[_make_runtime_key(record.owner, record.source_key, record.slot)]
                if live ~= nil then
                    record.item = live.item
                    record.item_info = live.item_info
                end
                _apply_visual_fallbacks(record, live, visual_lookup)
                entries[#entries + 1] = record
            end
        end
    end

    local shared_items = shared_storage_cache ~= nil and shared_storage_cache.items or nil
    if type(shared_items) == "table" then
        for i = 1, #shared_items do
            local record = _copy_table_shallow(shared_items[i])
            local live = live_info[_make_runtime_key(record.owner, record.source_key, record.slot)]
            if live ~= nil then
                record.item = live.item
                record.item_info = live.item_info
            end
            _apply_visual_fallbacks(record, live, visual_lookup)
            entries[#entries + 1] = record
        end
    end

    table.sort(entries, _compare_records)
    return entries
end

function AssetsStore:get_character_count()
    local cache = _ensure_assets_cache()
    local count = 0

    for _, character_cache in pairs(cache.characters) do
        if type(character_cache) == "table" then
            local backpack_items = character_cache.backpack ~= nil and character_cache.backpack.items or nil
            local bank_items = character_cache.bank ~= nil and character_cache.bank.items or nil
            local vault_items = character_cache.vault ~= nil and character_cache.vault.items or nil
            if (type(backpack_items) == "table" and #backpack_items > 0) or
                (type(bank_items) == "table" and #bank_items > 0) or
                (type(vault_items) == "table" and #vault_items > 0) then
                count = count + 1
            end
        end
    end

    return count
end

function AssetsStore:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - (self.last_update_at or 0)) < self.update_every then
        return
    end
    self.last_update_at = now

    self:_sync_bindings(false)
    self:_refresh_availability_flags()

    local changed = self:_flush_dirty_snapshots()

    if changed == true then
        self.generation = self.generation + 1
        AssetCache.dirty = true
    end

    if Flags.is_unloading ~= true then
        local crafting_store = Stores.crafting
        if crafting_store ~= nil and crafting_store.refresh ~= nil then
            crafting_store:refresh(false, 1)
        end
    end
end

function AssetsStore:_mark_source_dirty(source_key)
    if source_key == SOURCE_BACKPACK then
        self._backpack_dirty = true
        return
    end
    if source_key == SOURCE_BANK then
        self._bank_dirty = true
        return
    end
    if source_key == SOURCE_VAULT then
        self._vault_dirty = true
        return
    end
    if source_key == SOURCE_SHARED then
        self._shared_dirty = true
        return
    end

    self:_mark_all_dirty()
end

function AssetsStore:_sync_bindings(force)
    local character_name = _get_current_character_name()
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local has_backpack_method = player ~= nil and player.GetBackpack ~= nil
    local has_bank_method = player ~= nil and player.GetBank ~= nil
    local has_vault_method = player ~= nil and player.GetVault ~= nil
    local has_shared_method = player ~= nil and player.GetSharedStorage ~= nil
    local backpack = has_backpack_method == true and player:GetBackpack() or nil
    local bank = has_bank_method == true and player:GetBank() or nil
    local vault = has_vault_method == true and player:GetVault() or nil
    local shared_storage = has_shared_method == true and player:GetSharedStorage() or nil

    if force ~= true and
        character_name == self.character_name and
        player == self.player and
        has_backpack_method == self._has_backpack_method and
        has_bank_method == self._has_bank_method and
        has_vault_method == self._has_vault_method and
        has_shared_method == self._has_shared_method and
        backpack == self.backpack and
        bank == self.bank and
        vault == self.vault and
        shared_storage == self.shared_storage then
        return false
    end

    self.character_name = character_name
    self.player = player
    self._has_backpack_method = has_backpack_method
    self._has_bank_method = has_bank_method
    self._has_vault_method = has_vault_method
    self._has_shared_method = has_shared_method
    self.backpack = backpack
    self.bank = bank
    self.vault = vault
    self.shared_storage = shared_storage

    self._bank_available = nil
    self._vault_available = nil
    self._shared_available = nil

    self:_detach_callbacks()
    self:_attach_callbacks()
    self:_mark_all_dirty()

    return true
end

function AssetsStore:_flush_dirty_snapshots()
    local changed = false
    local persist_changed = false
    if self._backpack_dirty == true then
        local source_changed = self:_snapshot_backpack()
        changed = source_changed or changed
        persist_changed = source_changed or persist_changed
    end
    if self._bank_dirty == true then
        local source_changed = self:_snapshot_bank()
        changed = source_changed or changed
        persist_changed = source_changed or persist_changed
    end
    if self._vault_dirty == true then
        local source_changed = self:_snapshot_vault()
        changed = source_changed or changed
        persist_changed = source_changed or persist_changed
    end
    if self._shared_dirty == true then
        local source_changed = self:_snapshot_shared_storage()
        changed = source_changed or changed
        persist_changed = source_changed or persist_changed
    end

    return changed, persist_changed
end

function AssetsStore:_build_visual_lookup(live_info)
    local cache = _ensure_assets_cache()
    local lookup = {
        by_exact = {},
        by_icon = {},
        quality_counts = {},
    }

    local function collect_items(items)
        if type(items) ~= "table" then
            return
        end
        for i = 1, #items do
            _collect_visual_record(lookup, items[i])
        end
    end

    for _, character_cache in pairs(cache.characters) do
        if type(character_cache) == "table" then
            collect_items(character_cache.backpack ~= nil and character_cache.backpack.items or nil)
            collect_items(character_cache.bank ~= nil and character_cache.bank.items or nil)
            collect_items(character_cache.vault ~= nil and character_cache.vault.items or nil)
        end
    end

    collect_items(cache.shared_storage ~= nil and cache.shared_storage.items or nil)

    for _, live in pairs(live_info) do
        if type(live) == "table" and live.item_info ~= nil then
            local background_image_id = _item_info_background_image_id(live.item_info)
            local icon_id = _item_info_icon_image_id(live.item_info)
            if background_image_id ~= nil and icon_id ~= nil then
                _collect_visual_record(lookup, {
                    name = live.item_info.GetName ~= nil and _safe_text(live.item_info:GetName()) or "",
                    icon_id = icon_id,
                    background_image_id = background_image_id,
                    quality = live.item_info.GetQuality ~= nil and live.item_info:GetQuality() or nil,
                })
            end
        end
    end

    return lookup
end

function AssetsStore:_capture_live_container(map, container, owner, source_key, size_fn_name, item_fn_name, require_available)
    if container == nil then
        return
    end

    if require_available == true and (container.IsAvailable == nil or container:IsAvailable() ~= true) then
        return
    end

    local size_fn = container[size_fn_name]
    local item_fn = container[item_fn_name]
    if size_fn == nil or item_fn == nil then
        return
    end

    local count = _safe_number(size_fn(container), 0)
    for slot = 1, count do
        local item = item_fn(container, slot)
        if item ~= nil and item.GetItemInfo ~= nil then
            local item_info = item:GetItemInfo()
            if item_info ~= nil then
                map[_make_runtime_key(owner, source_key, slot)] = {
                    item = item,
                    item_info = item_info,
                }
            end
        end
    end
end

function AssetsStore:_build_live_info_map()
    local map = {}

    self:_capture_live_container(map, self.backpack, self.character_name, SOURCE_BACKPACK, "GetSize", "GetItem", false)
    self:_capture_live_container(map, self.bank, self.character_name, SOURCE_BANK, "GetCount", "GetItem", true)
    self:_capture_live_container(map, self.vault, self.character_name, SOURCE_VAULT, "GetCount", "GetItem", true)
    self:_capture_live_container(map, self.shared_storage, "", SOURCE_SHARED, "GetCount", "GetItem", true)

    return map
end

function AssetsStore:_mark_all_dirty()
    self._backpack_dirty = true
    self._bank_dirty = true
    self._vault_dirty = true
    self._shared_dirty = true
end

function AssetsStore:_attach(object, event_name, callback)
    local handle = add_callback(object, event_name, callback)
    if handle ~= nil then
        self._callbacks[#self._callbacks + 1] = {
            object = object,
            event_name = event_name,
            handle = handle,
        }
    end
end

function AssetsStore:_attach_callbacks()
    local function queue_refresh(source_key)
        self:_mark_source_dirty(source_key)
        self.last_update_at = 0
    end

    local function refresh_backpack()
        queue_refresh(SOURCE_BACKPACK)
    end

    local function refresh_bank()
        queue_refresh(SOURCE_BANK)
    end

    local function refresh_vault()
        queue_refresh(SOURCE_VAULT)
    end

    local function refresh_shared()
        queue_refresh(SOURCE_SHARED)
    end

    if self.backpack ~= nil then
        self:_attach(self.backpack, "ItemAdded", refresh_backpack)
        self:_attach(self.backpack, "ItemRemoved", refresh_backpack)
        self:_attach(self.backpack, "ItemMoved", refresh_backpack)
        self:_attach(self.backpack, "ItemChanged", refresh_backpack)
        self:_attach(self.backpack, "SizeChanged", refresh_backpack)
    end

    if self.bank ~= nil then
        self:_attach(self.bank, "ItemAdded", refresh_bank)
        self:_attach(self.bank, "ItemRemoved", refresh_bank)
        self:_attach(self.bank, "ItemMoved", refresh_bank)
        self:_attach(self.bank, "ItemChanged", refresh_bank)
        self:_attach(self.bank, "CountChanged", refresh_bank)
        self:_attach(self.bank, "ItemsRefreshed", refresh_bank)
        self:_attach(self.bank, "IsAvailableChanged", refresh_bank)
    end

    if self.vault ~= nil then
        self:_attach(self.vault, "ItemAdded", refresh_vault)
        self:_attach(self.vault, "ItemRemoved", refresh_vault)
        self:_attach(self.vault, "ItemMoved", refresh_vault)
        self:_attach(self.vault, "ItemChanged", refresh_vault)
        self:_attach(self.vault, "CountChanged", refresh_vault)
        self:_attach(self.vault, "ItemsRefreshed", refresh_vault)
        self:_attach(self.vault, "IsAvailableChanged", refresh_vault)
    end

    if self.shared_storage ~= nil then
        self:_attach(self.shared_storage, "ItemAdded", refresh_shared)
        self:_attach(self.shared_storage, "ItemRemoved", refresh_shared)
        self:_attach(self.shared_storage, "ItemMoved", refresh_shared)
        self:_attach(self.shared_storage, "ItemChanged", refresh_shared)
        self:_attach(self.shared_storage, "CountChanged", refresh_shared)
        self:_attach(self.shared_storage, "ItemsRefreshed", refresh_shared)
        self:_attach(self.shared_storage, "IsAvailableChanged", refresh_shared)
    end
end

function AssetsStore:_detach_callbacks()
    for i = 1, #self._callbacks do
        local callback = self._callbacks[i]
        if callback ~= nil and callback.object ~= nil and callback.event_name ~= nil and callback.handle ~= nil then
            remove_callback(callback.object, callback.event_name, callback.handle)
        end
    end

    self._callbacks = {}
end

function AssetsStore:_refresh_availability_flags()
    if self.bank ~= nil and self.bank.IsAvailable ~= nil then
        local available = self.bank:IsAvailable() == true
        if self._bank_available ~= available then
            self._bank_available = available
            self._bank_dirty = true
        end
    end

    if self.vault ~= nil and self.vault.IsAvailable ~= nil then
        local available = self.vault:IsAvailable() == true
        if self._vault_available ~= available then
            self._vault_available = available
            self._vault_dirty = true
        end
    end

    if self.shared_storage ~= nil and self.shared_storage.IsAvailable ~= nil then
        local available = self.shared_storage:IsAvailable() == true
        if self._shared_available ~= available then
            self._shared_available = available
            self._shared_dirty = true
        end
    end
end

function AssetsStore:_snapshot_backpack()
    self._backpack_dirty = false

    local cache = _ensure_assets_cache()
    local character_cache = _ensure_character_cache(cache, self.character_name)
    local next_items = _snapshot_backpack_items(self.backpack, self.character_name)
    local current_items = character_cache.backpack.items or {}
    if _records_equal(current_items, next_items) == true then
        return false
    end

    character_cache.backpack.items = next_items
    return true
end

function AssetsStore:_snapshot_bank()
    self._bank_dirty = false

    local cache = _ensure_assets_cache()
    local character_cache = _ensure_character_cache(cache, self.character_name)
    local next_items = _snapshot_bank_items(self.bank, self.character_name, SOURCE_BANK)
    if next_items == nil then
        return false
    end

    local current_items = character_cache.bank.items or {}
    if _records_equal(current_items, next_items) == true then
        return false
    end

    character_cache.bank.items = next_items
    return true
end

function AssetsStore:_snapshot_vault()
    self._vault_dirty = false

    local cache = _ensure_assets_cache()
    local character_cache = _ensure_character_cache(cache, self.character_name)
    local next_items = _snapshot_bank_items(self.vault, self.character_name, SOURCE_VAULT)
    if next_items == nil then
        return false
    end

    local current_items = character_cache.vault.items or {}
    if _records_equal(current_items, next_items) == true then
        return false
    end

    character_cache.vault.items = next_items
    return true
end

function AssetsStore:_snapshot_shared_storage()
    self._shared_dirty = false

    local cache = _ensure_assets_cache()
    local shared_storage_cache = cache.shared_storage
    local next_items = _snapshot_bank_items(self.shared_storage, self.character_name, SOURCE_SHARED)
    if next_items == nil then
        return false
    end

    local current_items = shared_storage_cache.items or {}
    if _records_equal(current_items, next_items) == true then
        return false
    end

    shared_storage_cache.items = next_items
    return true
end
