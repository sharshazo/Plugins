-- Map-owned catalog. No Quest Assistant dependency, timers, frame scans or new windows.
_G.WorldMapAddon = _G.WorldMapAddon or {}
local C = { loaded = {}, combined = {}, failed = {}, used = {}, cacheLimit = 6, clock = 0 }
WorldMapAddon.Catalog = C
import "WorldMap_Addon.worldmap_catalog_index"

-- These two calibrations already exist in the bundled MoorMapZones data.
for mid, addition in pairs(C.MapAdditions or {}) do
    local ZD = WorldMapAddon.ZoneMapsData
    ZD.Maps[mid] = ZD.Maps[mid] or addition.map
    ZD.MapZone[mid] = ZD.MapZone[mid] or addition.zone
    WorldMapAddon.MapCal[mid] = WorldMapAddon.MapCal[mid] or addition.cal
    local list = ZD.Zones[addition.zone] or {}
    local found = false
    for _, id in ipairs(list) do if id == mid then found = true end end
    if not found then list[#list + 1] = mid end
    ZD.Zones[addition.zone] = list
end

function C.Register(mid, factory)
    if C.Available[mid] and type(factory) == "function" and not C.loaded[mid] then C.loaded[mid] = factory end
end

function C.GetLayers(mid)
    local base = WorldMapAddon.LayersData[mid] or {}
    if not C.Available[mid] or C.failed[mid] then return base end
    C.clock = C.clock + 1
    if C.combined[mid] then C.used[mid] = C.clock; return C.combined[mid] end
    if not C.loaded[mid] then
        local ok = pcall(import, "WorldMap_Addon.worldmap_catalog_" .. tostring(mid))
        if not ok or not C.loaded[mid] then C.failed[mid] = true; return base end
    end
    local patch = C.loaded[mid]()
    local list = {}
    for i, point in ipairs(base) do
        local refs = patch.updates[i]
        if refs then
            local enriched = {}
            for key, value in pairs(point) do enriched[key] = value end
            enriched.catalog = refs
            if patch.kinds and patch.kinds[i] then enriched[1] = patch.kinds[i] end
            list[#list + 1] = enriched
        else list[#list + 1] = point end
    end
    for _, point in ipairs(patch.new) do
        point.catalog = point[9]; point[9] = nil
        list[#list + 1] = point
    end
    WorldMapAddon.LayersHideOld = WorldMapAddon.LayersHideOld or {}
    local hide = WorldMapAddon.LayersHideOld[mid] or {}
    for key in pairs(patch.hide) do hide[key] = true end
    WorldMapAddon.LayersHideOld[mid] = hide
    local count, oldest, oldestTime = 0, nil, math.huge
    for id in pairs(C.combined) do
        count = count + 1
        if C.used[id] < oldestTime then oldest, oldestTime = id, C.used[id] end
    end
    if count >= C.cacheLimit then C.combined[oldest] = nil; C.used[oldest] = nil end
    C.combined[mid] = list
    C.used[mid] = C.clock
    return list
end

function C.SearchRecords()
    if C.SearchRows == nil then
        local ok = pcall(import, "WorldMap_Addon.worldmap_catalog_search")
        if not ok or C.SearchRows == nil then C.SearchRows = {} end
    end
    return C.SearchRows
end

local REWARDS = {
    VERTUES = { "XP de virtud", "virtue XP" }, TITLE = { "Título", "Title" },
    LOTRO_POINTS = { "Puntos LOTRO", "LOTRO points" }, REPUTATION = { "Reputación", "Reputation" },
    TURBINE = { "Puntos LOTRO", "LOTRO points" }, BRAISES = { "Ascuas de encantamiento", "Embers of Enchantment" },
    GRAINS = { "Motas de encantamiento", "Motes of Enchantment" },
    MARQUE_DONATEUR = { "Marcas de Donante", "Gift-giver's Brands" },
    RELIQUE_ALLEGEANCE = { "Reliquia de la Última Alianza", "Relic of the Last Alliance" },
    FELEGOTH_TOKEN = { "Fichas del Lago y los Ríos", "Tokens of the Lake and Rivers" },
    NITHILIEN_TOKEN = { "Piezas de Plata de la Hueste del Oeste", "Host of the West Silver Pieces" },
    EGONDOR_TOKEN = { "Piezas de Plata de Gondor Este", "East Gondor Silver Pieces" },
    CGONDOR_TOKEN = { "Piezas de Plata de Gondor Central", "Central Gondor Silver Pieces" },
    AMROTH_TOKEN = { "Piezas de Plata de Amroth", "Amroth Silver Pieces" },
    ROHAN_RIDER_REPUTATION_ITEM = { "Talla de Madera Exquisita", "Exquisite Wood-carving" },
    ROHAN_RIDER_REPUTATION_ITEM2 = { "Amuleto de Mármol Pulido", "Polished Marble Trinket" },
}
function C.Details(point, es, includeRewards)
    if not point or not point.catalog then return {} end
    if C.Entries == nil then
        local ok = pcall(import, "WorldMap_Addon.worldmap_catalog_entries")
        if not ok or C.Entries == nil then C.Entries = {} end
    end
    local out, seen = {}, {}
    if WorldMapAddon.Options and WorldMapAddon.Options.Get then
        local ok, show = pcall(WorldMapAddon.Options.Get, "rewards")
        if ok and show == false then includeRewards = false end
    end
    local function add(text)
        if text and text ~= "" and not seen[text] then out[#out + 1] = text; seen[text] = true end
    end
    for _, ref in ipairs(point.catalog) do
        local e = C.Entries[ref[1]]
        if e then
            local name = es and (e.nameES or e.name) or e.name
            add((es and "Colección / registro: " or "Collection / entry: ") .. name)
            if ref[5] then add(es and ref[6] or ref[5])
            else add((es and "Coordenadas: " or "Coordinates: ") .. ref[4]) end
            local facts = {}
            if tonumber(e.level) and tonumber(e.level) > 0 then facts[#facts + 1] = (es and "Nivel " or "Level ") .. e.level end
            if e.race and e.race ~= "TBD" then facts[#facts + 1] = es and (e.raceES or e.race) or e.race end
            if #facts > 0 then add(table.concat(facts, " · ")) end
            if e.note and e.note ~= "" then add((es and "Nota del catálogo: " or "Catalog note: ") .. (es and (e.noteES or e.note) or e.note)) end
            if includeRewards ~= false then
                local rewards = {}
                for i, reward in ipairs(e.rewards or {}) do
                    if type(reward) == "table" then
                        local names = REWARDS[reward.type]
                        local label = names and names[es and 1 or 2] or tostring(reward.type or "")
                        local value = es and (reward.valueES or reward.value) or reward.value
                        rewards[#rewards + 1] = label .. (value and (": " .. value) or "")
                    else rewards[#rewards + 1] = es and reward or ((e.rewardsEN and e.rewardsEN[i]) or reward) end
                end
                if #rewards > 0 then add((es and "Recompensas del catálogo: " or "Catalog rewards: ") .. table.concat(rewards, "; ")) end
            end
        end
    end
    return out
end

function C.Open(showOnly)
    if WorldMapAddon.launcher and WorldMapAddon.launcher.ToggleMap then
        local win = WorldMapAddon.instance
        if showOnly and win and win.IsVisible and win:IsVisible() then return true end
        WorldMapAddon.launcher:ToggleMap()
        return true
    end
    return false
end
