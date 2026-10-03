-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_abbrev_gold = _G.LUI.Utils.lui_abbrev_gold
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Utils.number_abbrev"
import "LUI.src.UI.assets"
import "LUI.src.UI.shortcuts"
import "LUI.src.UI.Widgets.image"
import "LUI.src.Settings.enums"

local LUI = _G.LUI
local UI = LUI.UI
local Settings = LUI.Settings
local LUI_ENUMS = Settings.Enums
local StatusBar = LUI.Features.StatusBar
local Windows = LUI.Runtime.Windows
local Apply = LUI.Runtime.Apply
local S = StatusBar.Common or {}
StatusBar.Common = S
local Shortcuts = UI.Shortcuts
StatusBar.APIItems = StatusBar.APIItems or {
    by_key = {},
    by_token = {},
    order = {},
}
local STATUS_BAR_API_ITEMS = StatusBar.APIItems
STATUS_BAR_API_ITEMS.by_key = STATUS_BAR_API_ITEMS.by_key or {}
STATUS_BAR_API_ITEMS.by_token = STATUS_BAR_API_ITEMS.by_token or {}
STATUS_BAR_API_ITEMS.order = STATUS_BAR_API_ITEMS.order or {}
local MAX_STATUS_BAR_API_TITLE_LEN = 20
local MAX_STATUS_BAR_API_DESCRIPTION_LEN = 40

local function _log_status_bar_api(message)
    if Turbine ~= nil and Turbine.Shell ~= nil and Turbine.Shell.WriteLine ~= nil then
        Turbine.Shell.WriteLine("<rgb=#33C1FF>LUI StatusBar</rgb>: " .. tostring(message or ""))
    end
end

S.ICON_GAP = 4
S.ICON_INSET = 4
S.BACKPACK_ICON_W = 24
S.BACKPACK_ICON_H = 30

S.GOLD_ICON = UI.AssetIds.gold_coin
S.SILVER_ICON = UI.AssetIds.silver_coin
S.COPPER_ICON = UI.AssetIds.copper_coin
S.INVENTORY_SPACE_ICON = UI.AssetIds.backpack
S.DURABILITY_ICON = UI.AssetIds.durability

S.STATUS_BAR_LAYOUT_TOKENS = {
    time = "time_local",
    inventory = "inventory_space",
    durability = "equipment_wear",
    gold = "money",
    wallet = "wallet",
    config = "config",
    craft = "craft",
    ["craft.plan"] = "craft_plan",
    travel = "travel",
    assets = "assets",
    encyclopedia = "encyclopedia",
    raid = "raid",
}
S.STATUS_BAR_WIDGET_LAYOUT_TOKENS = {
    time_local = "%time%",
    inventory_space = "%inventory%",
    equipment_wear = "%durability%",
    money = "%gold%",
    wallet = "%wallet%",
    config = "%config%",
    craft = "%craft%",
    craft_plan = "%craft.plan%",
    travel = "%travel%",
    assets = "%assets%",
    encyclopedia = "%encyclopedia%",
    raid = "%raid%",
}
S.STATUS_BAR_EDITABLE_WIDGET_KEYS = {
    "time_local",
    "inventory_space",
    "equipment_wear",
    "money",
    "wallet",
    "config",
    "craft",
    "craft_plan",
    "travel",
    "assets",
    "encyclopedia",
    "raid",
}

S.ITEM_WEAR_STATE = Turbine.Gameplay.ItemWearState or {}
S.EQUIPMENT_SLOTS = {
    Turbine.Gameplay.Equipment.Head,
    Turbine.Gameplay.Equipment.Chest,
    Turbine.Gameplay.Equipment.Legs,
    Turbine.Gameplay.Equipment.Gloves,
    Turbine.Gameplay.Equipment.Boots,
    Turbine.Gameplay.Equipment.Shoulder,
    Turbine.Gameplay.Equipment.Back,
    Turbine.Gameplay.Equipment.Bracelet1,
    Turbine.Gameplay.Equipment.Bracelet2,
    Turbine.Gameplay.Equipment.Necklace,
    Turbine.Gameplay.Equipment.Ring1,
    Turbine.Gameplay.Equipment.Ring2,
    Turbine.Gameplay.Equipment.Earring1,
    Turbine.Gameplay.Equipment.Earring2,
    Turbine.Gameplay.Equipment.Pocket,
    Turbine.Gameplay.Equipment.PrimaryWeapon,
    Turbine.Gameplay.Equipment.SecondaryWeapon,
    Turbine.Gameplay.Equipment.RangedWeapon,
    Turbine.Gameplay.Equipment.CraftTool,
    Turbine.Gameplay.Equipment.Class,
}
S.WEAR_STATE_TO_PERCENT = {
    [S.ITEM_WEAR_STATE.Pristine or 2] = 100,
    [S.ITEM_WEAR_STATE.Worn or 4] = 80,
    [S.ITEM_WEAR_STATE.Damaged or 1] = 20,
    [S.ITEM_WEAR_STATE.Broken or 3] = 0,
}

local function _trim(text)
    local v = tostring(text or "")
    v = v:gsub("^%s+", "")
    v = v:gsub("%s+$", "")
    return v
end

local function _refresh_status_bar_after_api_change()
    local edit_window_state = nil
    if Windows.status_bar ~= nil then
        edit_window_state = Windows.status_bar:capture_edit_window_state()
    end

    Settings.rebuild()
    if Windows.status_bar ~= nil then
        Windows.status_bar:apply_settings()
    else
        Apply.status_bar_settings()
    end
    if edit_window_state ~= nil and edit_window_state.visible == true and Windows.status_bar ~= nil then
        Windows.status_bar:restore_edit_window_state(edit_window_state)
    end
    Settings.Pages.StatusBar.refresh_layout_help()
end

local WALLET_ITEM_NAMES = {
    TR["Destiny Points"],
    TR["Mithril Coin"],
    TR["Adorned Dragon-helm"],
    TR["Adorned Royal Crown"],
    TR["'Battle of Dagorlad' Tapestry"],
    TR["'Battle of Five Armies' Tapestry"],
    TR["Beryl Pendant"],
    TR["Black-wood Bow"],
    TR["Ceremonial Dwarf-axe"],
    TR["Chronicle of Cirion and Eorl"],
    TR["Dragon-helm"],
    TR["Dúnedain Star"],
    TR["Elaborate Dúnedain Star"],
    TR["Elaborate Royal Circlet"],
    TR["Elderslade Supply Pack"],
    TR["Embroidered 'Battle of Five Armies' Tapestry"],
    TR["Embroidered 'Battle of Dagorlad' Tapestry"],
    TR["Engraved Elf-blade"],
    TR["Engraved Red Arrow"],
    TR["Engraved Statue of Elendil"],
    TR["Feast of Ethuilwereth"],
    TR["Feast of Harvestmath"],
    TR["Feast of Lithe"],
    TR["Flawless Ceremonial Dwarf-axe"],
    TR["Flawless Númenórean Sceptre"],
    TR["Grand Feast of Ethuilwereth"],
    TR["Grand Feast of Lithe"],
    TR["Illuminated Record of the Elf-lords"],
    TR["Illuminated Record of the Race of Man"],
    TR["Iron Garrison Resource Token"],
    TR["Númenórean Sceptre"],
    TR["Record of Durin"],
    TR["Record of the Elf-lords"],
    TR["Record of the Race of Man"],
    TR["Red Arrow"],
    TR["Royal Circlet"],
    TR["Royal Crown"],
    TR["'Siege of Barad-dûr' Tapestry"],
    TR["Silver Basin"],
    TR["Statue of Elendil"],
    TR["Token of Effort"],
    TR["Universal Ingredient Pack"],
    TR["Motes of Enchantment"],
    TR["Embers of Enchantment"],
    TR["Figments of Splendour"],
    TR["Amberjack"],
    TR["Anniversary Token"],
    TR["Bad Fish"],
    TR["Badge of Dishonour"],
    TR["Badge of Taste"],
    TR["Big Fish"],
    TR["Bottle of Ale"],
    TR["Buried Treasure Token"],
    TR["Drum"],
    TR["Easy Fish"],
    TR["Fall Festival Token"],
    TR["Farmers Faire Token"],
    TR["Festival Token"],
    TR["Festivity Token"],
    TR["Fragment of a Shadow Essence"],
    TR["Golden Festival Token"],
    TR["Keg of Cram"],
    TR["Luillim"],
    TR["Marigold (Barter)"],
    TR["Midsummer Token"],
    TR["Possible Fish"],
    TR["Primrose (Barter)"],
    TR["Puny Fish"],
    TR["Scrap of an Essence Reclamation Scroll"],
    TR["Simple Fish"],
    TR["Small Fish"],
    TR["Spring Leaf"],
    TR["Steel Token"],
    TR["Summer Festival Token"],
    TR["Tricky Fish"],
    TR["Unlikely Fish"],
    TR["Violet (Barter)"],
    TR["Yule Festival Token"],
    TR["Ancient Script"],
    TR["Bright Emblem of Nimrodel"],
    TR["Khuzdul Tablets"],
    TR["Rusted Dwarf Tools"],
    TR["Shard"],
    TR["Ancient Ithil-coin"],
    TR["Arnorian Armour Fragment"],
    TR["Mark"],
    TR["Blade of Dúnachar"],
    TR["Breastplate of Gruglok"],
    TR["Broken Signet"],
    TR["Cloven Helm of Lagmas"],
    TR["Coin of Grárik"],
    TR["Dark Emblem of Courage"],
    TR["Dark Emblem of Strength"],
    TR["Dazzling Emerald"],
    TR["Eglain Token"],
    TR["Fiery Quartz"],
    TR["Glinting Amethyst"],
    TR["Glowing Red Ruby"],
    TR["Greater Elf-stone of Courage"],
    TR["Greater Elf-stone of Hand"],
    TR["Greater Elf-stone of Heart"],
    TR["Greater Elf-stone of Resolve"],
    TR["Greater Elf-stone of Spirit"],
    TR["Greater Elf-stone of Strength"],
    TR["Helchgam's Beak"],
    TR["Long-lost Coin"],
    TR["Mark of Aughaire Victory"],
    TR["Mark of Rammas Deluon Victory"],
    TR["Mark of Rhunendin Victory"],
    TR["Mark of Triumph"],
    TR["Mark of Victory"],
    TR["Masterwork Helmet of the Pelennor Fields"],
    TR["Medallion"],
    TR["Medallion of Dol Guldur"],
    TR["Medallion of Lothlórien"],
    TR["Medallion of Moria"],
    TR["Medallion of the North-men"],
    TR["Morgul Crest"],
    TR["Near Perfect Sapphire"],
    TR["Newfound Coin"],
    TR["Obsidian Rock-shard"],
    TR["Officer's Bracelet of the Pelennor Fields"],
    TR["Orthanc Sigil-fragment"],
    TR["Platinum Coin of Spirit"],
    TR["Pristine Bracelet of the Pelennor Fields"],
    TR["Pristine Ring of the Pelennor Fields"],
    TR["Pristine Opal"],
    TR["Rift-iron Coin"],
    TR["Scorched Helm Token"],
    TR["Scorched Shoulder-guard Token"],
    TR["Scrap of Rift-iron Ore"],
    TR["Scrap of Wisdán's Cloak"],
    TR["Seal"],
    TR["Sparkling Diamond"],
    TR["Star of Merit"],
    TR["Tarnished Ring of the Pelennor Fields"],
    TR["Tarnished Sigil of Gondor"],
    TR["Thrâng's Vault Token"],
    TR["Token of Ill Omens"],
    TR["Token of Resolution"],
    TR["Udúnion's Horn"],
    TR["Unhatched Spider Egg"],
    TR["Vile Bronze Coin"],
    TR["Vile Silver Coin"],
    TR["Western Heroes' Steel Boots Medallion"],
    TR["Western Heroes' Steel Breastplate Medallion"],
    TR["Western Heroes' Steel Gauntlets Medallion"],
    TR["Western Heroes' Steel Helmet Medallion"],
    TR["Western Heroes' Steel Leg-guards Medallion"],
    TR["Western Heroes' Steel Shoulder-guards Medallion"],
    TR["Worn Helmet of the Pelennor Fields"],
    TR["Amroth Silver Piece"],
    TR["Bingo Badge"],
    TR["Bree-land Wood-mark"],
    TR["Bronze Arnorian Coin"],
    TR["Central Gondor Silver Piece"],
    TR["Copper Bounder's Coin"],
    TR["Copper Coin of Gundabad"],
    TR["Eagle Bit"],
    TR["East Gondor Silver Piece"],
    TR["Fangorn Leaf"],
    TR["Gabil'akkâ War-mark"],
    TR["Geode - Agate"],
    TR["Geode - Amethyst"],
    TR["Geode - Gypsum"],
    TR["Geode - Jasper"],
    TR["Geode - Quartz"],
    TR["Gift-giver's Brand"],
    TR["Gold Token of Wildermore"],
    TR["Golden Token of the Anduin"],
    TR["Golden Token of the Riddermark"],
    TR["Golden Token of the Wilds"],
    TR["Greyflood Mark"],
    TR["Gundabad Mountain-mark"],
    TR["Gulmark"],
    TR["Host of the West Silver Piece"],
    TR["Ithilien Essence Fragment"],
    TR["Lothlórien Gold Leaf"],
    TR["Lothlórien Silver Branch"],
    TR["Malledhrim Bronze Feather"],
    TR["Malledhrim Gold Star Emblem"],
    TR["Mark of the Angle"],
    TR["Mark of the Longbeards"],
    TR["Mark of the Wilds"],
    TR["Minas Tirith - Builders' Token"],
    TR["Minas Tirith - Burgsmen's Token"],
    TR["Minas Tirith - Smiths' Token"],
    TR["Minas Tirith Silver Piece"],
    TR["Northern Gulmark"],
    TR["Phial of Amber Extract"],
    TR["Phial of Crimson Extract"],
    TR["Phial of Golden Extract"],
    TR["Phial of Sapphire Extract"],
    TR["Phial of Umber Extract"],
    TR["Phial of Verdant Extract"],
    TR["Phial of Violet Extract"],
    TR["Rhosgobel Oak Leaf"],
    TR["Sigil of Imlad Ithil"],
    TR["Silver Arnorian Coin"],
    TR["Silver Coin of Gundabad"],
    TR["Silver Signet of the Thandrim"],
    TR["Silver Token of the Anduin"],
    TR["Silver Token of the Riddermark"],
    TR["Silver Token of the Wilds"],
    TR["Sliver of Black Steel"],
    TR["Token of Further Adventure"],
    TR["Token of Hytbold"],
    TR["Token of the Kharum-ubnâr"],
    TR["Token of the Lake and Rivers"],
    TR["Token of Salutation"],
    TR["Token of Service"],
    TR["Token of the Zhélruka"],
    TR["Vales - Beorning Token"],
    TR["Vales - Elf Token"],
    TR["Vales - Woodmen Token"],
    TR["Warband Token of Wildermore"],
    TR["Westemnet Iron Coin"],
    TR["Wildermore Coin"],
    TR["Zakaf-beshêk"],
    TR["Brilliant Spirit Stone"],
    TR["Commendation"],
    TR["Chieftain's Brooch"],
    TR["Dull Spirit Stone"],
    TR["Glimmering Spirit Stone"],
    TR["Tyrant's Crest"],
    TR["2-pound Salmon"],
    TR["4-pound Salmon"],
    TR["6-pound Salmon"],
    TR["10-pound Salmon"],
    TR["15-pound Salmon"],
    TR["20-pound Salmon"],
    TR["30-pound Salmon"],
    TR["40-pound Salmon"],
    TR["50-pound Salmon"],
    TR["Arm of Lagmas (Barter)"],
    TR["Barbarous Barbel"],
    TR["The Beast's Drum"],
    TR["Big Mouth Bass"],
    TR["Brawny Bullhead"],
    TR["Bright Bitterling"],
    TR["Caerlug's Arm"],
    TR["Colourful Charr"],
    TR["Courageous Carp"],
    TR["Cunning Catfish"],
    TR["Delightful Dace"],
    TR["Fantastic Flounder"],
    TR["Ferndur's Skull (Barter)"],
    TR["Flagit's Head"],
    TR["Fungal Mushroom (Barter)"],
    TR["General Talug's Armour"],
    TR["Giant Goldfish"],
    TR["Gleaming Grayling"],
    TR["Glothrok's Token"],
    TR["Gothghaash's Symbol"],
    TR["Great Golden Mullet"],
    TR["Grimreaver (Barter)"],
    TR["Gurvand's Head"],
    TR["Head of Bogbereth (Barter)"],
    TR["Huge Houting"],
    TR["Igash's Trinket"],
    TR["Ivar's Banner (Barter)"],
    TR["Krankluk's Hammer (Barter)"],
    TR["Magnificent Minnow"],
    TR["The Mirror of Mordirith (Barter)"],
    TR["Morhûn's Gemstone (Barter)"],
    TR["Naruhel's Dress (Barter)"],
    TR["Nasty Nine-spined Stickleback"],
    TR["Nornúan's Head (Barter)"],
    TR["Perfect Perch"],
    TR["Perfect Pike"],
    TR["Remmenaeg's Armour (Barter)"],
    TR["Ruthless Rudd"],
    TR["The Skull of Thorog (Barter)"],
    TR["Small Turtle Shell"],
    TR["Stinger of Brúmbereth (Barter)"],
    TR["Superb Smelt"],
    TR["Tentacle of Helchgam (Barter)"],
    TR["Thaurlach's Blade (Barter)"],
    TR["Tricky Three-spined Stickleback"],
    TR["Udunion's Swords (Barter)"],
    TR["Undamaged Barghest Corpse"],
    TR["Undamaged Brown-bear Corpse"],
    TR["Undamaged Frost-antler Head"],
    TR["Undamaged Sabre-tooth Corpse"],
    TR["Undamaged Tundra Bear Corpse"],
    TR["Undamaged Warg Corpse"],
    TR["Undamaged White-wolf Corpse"],
    TR["Undamaged Winter-worm Corpse"],
    TR["Watcher's Token"],
    TR["Zholuga's Head"],
    TR["Steed Halter"],
}

S.WALLET_ITEMS = WALLET_ITEM_NAMES

function S.get_wallet_item_spec(value)
    if value == nil then
        return nil
    end

    local name = _trim(value)
    if name == "" then
        return nil
    end

    for i = 1, #S.WALLET_ITEMS do
        if S.WALLET_ITEMS[i] == name then
            return name
        end
    end

    return nil
end

function S.parse_wallet_item_list(value)
    local out = {}
    local seen = {}

    local function add_item(token)
        local name = S.get_wallet_item_spec(token)
        if name == nil then
            return
        end

        if name == "" or seen[name] == true then
            return
        end

        seen[name] = true
        out[#out + 1] = name
    end

    if type(value) == "table" then
        for i = 1, #value do
            add_item(value[i])
        end
    elseif type(value) == "string" then
        for token in value:gmatch("[^,\n\r;]+") do
            add_item(token)
        end
    else
        add_item(value)
    end

    return out
end

function S.resolve_wallet_item_selection(value)
    return S.get_wallet_item_spec(value)
end

function S.get_wallet_selection_entries(values)
    return S.parse_wallet_item_list(values)
end

function S.wallet_item_matches(entry, wallet_name)
    if entry == nil or wallet_name == nil then
        return false
    end
    return entry == wallet_name
end

function S.normalize_status_bar_item_name(value)
    local name = _trim(value)
    if name == "" then
        return nil
    end
    return name
end

function S.make_status_bar_item_registry_key(item_name)
    local name = S.normalize_status_bar_item_name(item_name)
    if name == nil then
        return nil
    end
    return string.lower(name)
end

function S.parse_status_bar_item_name(token)
    local text = _trim(token)
    local inner = text:match("^item:%[(.*)%]$")
    if inner == nil then
        return nil
    end
    return S.normalize_status_bar_item_name(inner)
end

function S.make_status_bar_item_token(item_name)
    local name = S.normalize_status_bar_item_name(item_name)
    if name == nil then
        return nil
    end
    return "%item:[" .. name .. "]%"
end

function S.make_status_bar_layout_token(widget_key)
    if type(widget_key) ~= "string" then
        return nil
    end
    return S.STATUS_BAR_WIDGET_LAYOUT_TOKENS[widget_key]
end

local function _normalize_status_bar_button_image(value)
    if type(value) == "number" then
        return value
    end

    local text = _trim(value)
    if text == "" then
        return nil
    end

    if text:match("^0[xX][%da-fA-F]+$") ~= nil then
        return tonumber(text:sub(3), 16)
    end

    local numeric = tonumber(text)
    if numeric ~= nil then
        return numeric
    end

    if text:lower():match("%.tga$") ~= nil then
        return text
    end

    return nil
end

local function _normalize_status_bar_button_icon(value)
    local image = _normalize_status_bar_button_image(value)
    if image ~= nil then
        return image
    end

    local text = _trim(value)
    if text == "" then
        return nil
    end

    return text
end

local function _format_status_bar_button_icon(value)
    if type(value) == "number" then
        return string.format("0x%X", value)
    end

    local text = _trim(value)
    if text == "" then
        return nil
    end

    return text
end

local function _normalize_status_bar_api_key(value)
    local key = _trim(value)
    if key == "" then
        return nil
    end
    if key:find("%s") ~= nil or key:find("%%", 1, true) ~= nil or key:match("^[%w_%-%.]+$") == nil then
        return nil
    end
    return string.lower(key)
end

local function _normalize_status_bar_api_title(value)
    local title = _trim(value)
    if title == "" then
        return nil
    end
    if string.len(title) > MAX_STATUS_BAR_API_TITLE_LEN then
        return nil
    end
    return title
end

local function _normalize_status_bar_api_description(value)
    if value == nil then
        return nil
    end

    local description = _trim(value)
    if description == "" then
        return nil
    end
    if string.len(description) > MAX_STATUS_BAR_API_DESCRIPTION_LEN then
        return nil
    end
    return description
end

local function _make_status_bar_api_layout_token(value)
    local key = _normalize_status_bar_api_key(value)
    if key == nil then
        return nil
    end
    return "%" .. key .. "%"
end

function S.normalize_status_bar_api_command(value)
    local command = _trim(value)
    if command == "" then
        return nil
    end
    if command:sub(1, 1) ~= "/" then
        return nil
    end
    return command
end

function S.make_status_bar_api_registry_key(command)
    local normalized = S.normalize_status_bar_api_command(command)
    if normalized == nil then
        return nil
    end
    return string.lower(normalized)
end

function S.parse_status_bar_button_token(token)
    local text = _trim(token)
    if text == "" then
        return nil
    end

    local wrapped = text:match("^%%(.*)%%$")
    if wrapped ~= nil then
        text = _trim(wrapped)
    end

    local icon_text, command = text:match("^button:([^:]+):(.*)$")
    if icon_text == nil then
        return nil
    end

    local icon_value = _normalize_status_bar_button_icon(icon_text)
    local alias_command = S.normalize_status_bar_api_command(command)
    if icon_value == nil or alias_command == nil then
        return nil
    end

    local icon_background = nil
    local icon_label = nil
    if _normalize_status_bar_button_image(icon_value) ~= nil then
        icon_background = icon_value
    else
        icon_label = icon_value
    end

    return {
        kind = "button",
        command = alias_command,
        icon_background = icon_background,
        icon_label = icon_label,
        token = "%" .. text .. "%",
    }
end

function S.make_status_bar_button_token(icon_background, command)
    local icon_text = _format_status_bar_button_icon(icon_background)
    local alias_command = S.normalize_status_bar_api_command(command)
    if icon_text == nil or alias_command == nil then
        return nil
    end

    return "%button:" .. icon_text .. ":" .. alias_command .. "%"
end

function S.get_status_bar_api_item(value)
    local text = _trim(value)
    if text == "" then
        return nil
    end

    local button_entry = S.parse_status_bar_button_token(text)
    if button_entry ~= nil then
        local command_key = S.make_status_bar_api_registry_key(button_entry.command)
        if command_key ~= nil then
            return STATUS_BAR_API_ITEMS.by_key[command_key]
        end
        return nil
    end

    local wrapped = text:match("^%%(.*)%%$")
    if wrapped ~= nil then
        text = _trim(wrapped)
    end

    local token_key = _normalize_status_bar_api_key(text)
    if token_key ~= nil then
        local entry = STATUS_BAR_API_ITEMS.by_token[token_key]
        if entry ~= nil then
            return entry
        end
    end
    return nil
end

function S.get_status_bar_api_item_by_command(command)
    local key = S.make_status_bar_api_registry_key(command)
    if key == nil then
        return nil
    end
    return STATUS_BAR_API_ITEMS.by_key[key]
end

function S.register_status_bar_api_item(spec)
    if type(spec) ~= "table" then
        return nil, "StatusBar.add expects a table."
    end

    local key_name = _normalize_status_bar_api_key(spec.key)
    if key_name == nil then
        return nil, "StatusBar.add requires a key using letters, numbers, _, -, or ."
    end

    local title = _normalize_status_bar_api_title(spec.title)
    if title == nil then
        return nil, "StatusBar.add requires a title up to " .. tostring(MAX_STATUS_BAR_API_TITLE_LEN) .. " characters."
    end

    local description = _normalize_status_bar_api_description(spec.description)
    if spec.description ~= nil and description == nil then
        return nil, "StatusBar.add description must be at most " .. tostring(MAX_STATUS_BAR_API_DESCRIPTION_LEN) ..
            " characters."
    end

    local image = _normalize_status_bar_button_image(spec.image)
    if image == nil then
        return nil, "StatusBar.add requires an image id or .tga path."
    end

    local command = S.normalize_status_bar_api_command(spec.command)
    if command == nil then
        return nil, "StatusBar.add requires a slash command."
    end

    local key = S.make_status_bar_api_registry_key(command)
    if key == nil then
        return nil, "Invalid status bar command."
    end

    local existing_token_entry = STATUS_BAR_API_ITEMS.by_token[key_name]
    if existing_token_entry ~= nil then
        _log_status_bar_api("Ignoring duplicate status bar API key=" .. tostring(key_name))
        return existing_token_entry
    end

    local entry = STATUS_BAR_API_ITEMS.by_key[key]

    local is_new = entry == nil
    if entry == nil then
        entry = {}
        STATUS_BAR_API_ITEMS.by_key[key] = entry
    end

    local previous_token_key = entry.token_key

    entry.kind = "api_item"
    entry.key = key_name
    entry.title = title
    entry.description = description
    entry.command = command
    entry.icon_background = image
    entry.icon_label = nil
    entry.token_key = key_name
    entry.token = _make_status_bar_api_layout_token(key_name)

    if entry.token == nil then
        return nil, "Failed to build the status bar button token."
    end

    if is_new == true then
        STATUS_BAR_API_ITEMS.order[#STATUS_BAR_API_ITEMS.order + 1] = key
    end

    if previous_token_key ~= nil and previous_token_key ~= key_name and STATUS_BAR_API_ITEMS.by_token[previous_token_key] == entry then
        STATUS_BAR_API_ITEMS.by_token[previous_token_key] = nil
    end
    STATUS_BAR_API_ITEMS.by_token[key_name] = entry

    _refresh_status_bar_after_api_change()
    return entry
end

function S.is_status_bar_api_entry(entry)
    return type(entry) == "table" and entry.kind == "api_item" and entry.key ~= nil and entry.title ~= nil and
        entry.command ~= nil and
        entry.token ~= nil
end

function S.get_status_bar_api_entries()
    local out = {}
    for i = 1, #STATUS_BAR_API_ITEMS.order do
        local key = STATUS_BAR_API_ITEMS.order[i]
        local entry = STATUS_BAR_API_ITEMS.by_key[key]
        if entry ~= nil then
            out[#out + 1] = entry
        end
    end
    return out
end

function S.get_status_bar_api_hint_lines()
    if #STATUS_BAR_API_ITEMS.order == 0 then
        return {}
    end

    local lines = {}
    for i = 1, #STATUS_BAR_API_ITEMS.order do
        local key = STATUS_BAR_API_ITEMS.order[i]
        local entry = STATUS_BAR_API_ITEMS.by_key[key]
        if entry ~= nil then
            local line = "  " .. tostring(entry.token or "")
            local label = entry.description or entry.title
            if label ~= nil then
                line = line .. " - " .. label
            end
            lines[#lines + 1] = line
        end
    end
    return lines
end

function S.get_status_bar_edit_palette_entries()
    local entries = {}
    for i = 1, #S.STATUS_BAR_EDITABLE_WIDGET_KEYS do
        local widget_key = S.STATUS_BAR_EDITABLE_WIDGET_KEYS[i]
        entries[#entries + 1] = {
            kind = "widget",
            widget_key = widget_key,
            title = S.get_status_bar_widget_display_name(widget_key),
            token = S.make_status_bar_layout_token(widget_key),
        }
    end
    for i = 1, #STATUS_BAR_API_ITEMS.order do
        local key = STATUS_BAR_API_ITEMS.order[i]
        local entry = STATUS_BAR_API_ITEMS.by_key[key]
        if entry ~= nil then
            entries[#entries + 1] = {
                kind = "api_item",
                widget_key = "button",
                title = entry.title or "",
                token = entry.token,
                api_entry = entry,
            }
        end
    end
    return entries
end

function S.get_status_bar_widget_display_name(widget_key)
    if widget_key == "time_local" then
        return TR["Time (local)"]
    elseif widget_key == "inventory_space" then
        return TR["Inventory space"]
    elseif widget_key == "equipment_wear" then
        return TR["Equipment Wear"]
    elseif widget_key == "money" then
        return TR["Money"]
    elseif widget_key == "wallet" then
        return TR["Wallet"]
    elseif widget_key == "config" then
        return Shortcuts.get_label("config")
    elseif widget_key == "craft" then
        return Shortcuts.get_label("craft")
    elseif widget_key == "craft_plan" then
        return TR["Crafting Plan"]
    elseif widget_key == "travel" then
        return Shortcuts.get_label("travel")
    elseif widget_key == "assets" then
        return Shortcuts.get_label("assets")
    elseif widget_key == "encyclopedia" then
        return Shortcuts.get_label("encyclopedia")
    elseif widget_key == "raid" then
        return Shortcuts.get_label("raid")
    end

    return tostring(widget_key or "")
end

function S.get_status_bar_item_registry_icon(registry, item_name)
    if type(registry) ~= "table" then
        return nil
    end

    local key = S.make_status_bar_item_registry_key(item_name)
    if key == nil then
        return nil
    end

    local value = registry[key]
    if type(value) == "table" then
        value = value.icon_image_id or value.icon
    end

    if type(value) ~= "number" then
        value = tonumber(value)
    end
    return value
end

function S.set_status_bar_item_registry_icon(registry, item_name, icon_image_id)
    if type(registry) ~= "table" then
        return
    end

    local key = S.make_status_bar_item_registry_key(item_name)
    if key == nil then
        return
    end

    local icon = icon_image_id
    if type(icon) ~= "number" then
        icon = tonumber(icon)
    end
    if icon == nil then
        return
    end

    registry[key] = icon
end

function S.is_status_bar_item_entry(entry)
    return type(entry) == "table" and entry.kind == "item" and entry.name ~= nil
end

function S.is_status_bar_button_entry(entry)
    return type(entry) == "table" and entry.kind == "button" and entry.command ~= nil
end

function S.parse_status_bar_layout(text, item_registry)
    local list = {}
    local source = tostring(text or "")

    for token in source:gmatch("%%([^%%]+)%%") do
        local button_entry = S.parse_status_bar_button_token(token)
        if button_entry ~= nil then
            list[#list + 1] = button_entry
        else
            local item_name = S.parse_status_bar_item_name(token)
            if item_name ~= nil then
                list[#list + 1] = {
                    kind = "item",
                    name = item_name,
                    token = S.make_status_bar_item_token(item_name),
                    icon_image_id = S.get_status_bar_item_registry_icon(item_registry, item_name),
                }
            else
                local api_entry = S.get_status_bar_api_item(token)
                if api_entry ~= nil then
                    list[#list + 1] = api_entry
                else
                    local widget_key = S.STATUS_BAR_LAYOUT_TOKENS[string.lower(_trim(token))]
                    if widget_key ~= nil then
                        list[#list + 1] = widget_key
                    end
                end
            end
        end
    end

    return list
end

function S.status_bar_layout_has_item(text, item_name)
    local wanted_key = S.make_status_bar_item_registry_key(item_name)
    if wanted_key == nil then
        return false
    end

    local source = tostring(text or "")
    for token in source:gmatch("%%([^%%]+)%%") do
        local name = S.parse_status_bar_item_name(token)
        if name ~= nil and S.make_status_bar_item_registry_key(name) == wanted_key then
            return true
        end
    end

    return false
end

function S.status_bar_layout_has_widget(text, widget_key)
    if type(widget_key) ~= "string" or widget_key == "" then
        return false
    end

    local source = tostring(text or "")
    for token in source:gmatch("%%([^%%]+)%%") do
        local current_widget_key = S.STATUS_BAR_LAYOUT_TOKENS[string.lower(_trim(token))]
        if current_widget_key == widget_key then
            return true
        end
    end

    return false
end

function S.status_bar_layout_has_api_item(text, command)
    local wanted_key = S.make_status_bar_api_registry_key(command)
    if wanted_key == nil then
        return false
    end

    local source = tostring(text or "")
    for token in source:gmatch("%%([^%%]+)%%") do
        local entry = S.get_status_bar_api_item(token)
        if entry ~= nil and S.make_status_bar_api_registry_key(entry.command) == wanted_key then
            return true
        end
    end

    return false
end

function S.append_status_bar_layout_token(text, token)
    local suffix = _trim(token)
    if suffix == "" then
        return tostring(text or "")
    end

    local prefix = _trim(text)
    if prefix == "" then
        return suffix
    end

    return prefix .. " " .. suffix
end

function S.extract_item_details_from_shortcut(shortcut)
    if shortcut == nil then
        return nil
    end

    if shortcut.GetType ~= nil and Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Lotro ~= nil and
        Turbine.UI.Lotro.ShortcutType ~= nil then
        local shortcut_type = shortcut:GetType()
        if shortcut_type ~= nil and shortcut_type ~= Turbine.UI.Lotro.ShortcutType.Item then
            return nil
        end
    end

    local item = shortcut.GetItem ~= nil and shortcut:GetItem() or nil
    if item == nil then
        return nil
    end

    local item_info = item.GetItemInfo ~= nil and item:GetItemInfo() or nil
    local name = item.GetName ~= nil and item:GetName() or nil
    if (name == nil or name == "") and item_info ~= nil and item_info.GetName ~= nil then
        name = item_info:GetName()
    end
    name = S.normalize_status_bar_item_name(name)
    if name == nil then
        return nil
    end

    local icon_image_id = nil
    if item_info ~= nil and item_info.GetIconImageID ~= nil then
        icon_image_id = item_info:GetIconImageID()
    end
    if icon_image_id == nil and item_info ~= nil and item_info.GetBackgroundImageID ~= nil then
        icon_image_id = item_info:GetBackgroundImageID()
    end
    if type(icon_image_id) ~= "number" then
        icon_image_id = tonumber(icon_image_id)
    end

    return {
        name = name,
        item = item,
        item_info = item_info,
        icon_image_id = icon_image_id,
    }
end

function S.extract_item_details_from_drag_drop_info(drag_drop_info)
    if drag_drop_info == nil or drag_drop_info.GetShortcut == nil then
        return nil
    end
    return S.extract_item_details_from_shortcut(drag_drop_info:GetShortcut())
end

function S.format_hhmm(date, time_format)
    if date == nil then
        return "--:--"
    end
    local h = date.Hour or 0
    local m = date.Minute or 0

    if time_format == LUI_ENUMS.time_format.AMPM then
        local suffix = h >= 12 and "PM" or "AM"
        local h12 = h % 12
        if h12 == 0 then
            h12 = 12
        end
        return string.format("%d:%02d %s", h12, m, suffix)
    end

    return string.format("%02d:%02d", h, m)
end

function S.get_centered_icon_y(container_h, icon_h)
    return math.floor((container_h - icon_h) / 2)
end

function S.get_icon_size(bar_h)
    local size = bar_h - S.ICON_INSET
    if size < 0 then
        return 0
    end
    return size
end

function S.get_widget_icon_w(widget_key, icon_h)
    if widget_key == "inventory_space" then
        return math.floor(((icon_h * S.BACKPACK_ICON_W) / S.BACKPACK_ICON_H) + 0.5)
    end
    return icon_h
end

function S.get_widget_icon(widget_key)
    if widget_key == "inventory_space" then
        return S.INVENTORY_SPACE_ICON
    elseif widget_key == "equipment_wear" then
        return S.DURABILITY_ICON
    end
    return nil
end

function S.with_alpha(color, alpha)
    if color == nil then
        return Turbine.UI.Color(alpha, 1, 1, 1)
    end
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

function S.clamp_shortcut_height(widget_h, bar_h)
    local h = widget_h
    if type(h) ~= "number" then
        h = tonumber(h)
    end
    if h == nil then
        h = bar_h
    end
    h = math.floor(h + 0.5)
    if h < 1 then
        h = 1
    end
    if h > bar_h then
        h = bar_h
    end
    return h
end

function S.sum_widget_width(widgets, gap)
    if widgets == nil then
        return 0
    end
    local w = 0
    for i = 1, #widgets do
        local c = widgets[i]
        if c ~= nil and c.GetWidth ~= nil then
            w = w + c:GetWidth()
        end
    end
    if #widgets > 1 then
        w = w + (gap * (#widgets - 1))
    end
    return w
end

function S.split_money_copper(total_copper)
    local v = total_copper
    if type(v) ~= "number" then
        v = tonumber(v)
    end
    if v == nil then
        return nil
    end

    local gold = math.floor(v / 100000)
    local silver = math.floor(v / 100) - gold * 1000
    local copper = v - gold * 100000 - silver * 100
    return gold, silver, copper
end

function S.format_money_copper(total_copper)
    local gold, silver, copper = S.split_money_copper(total_copper)
    if gold == nil then
        return "--"
    end
    return string.format("%dg %ds %dc", gold, silver, copper)
end

function S.format_money_copper_signed(total_copper)
    local v = tonumber(total_copper)
    if v == nil then
        return "--"
    end

    local sign = ""
    if v > 0 then
        sign = "+"
    elseif v < 0 then
        sign = "-"
        v = -v
    end

    local gold, silver, copper = S.split_money_copper(v)
    if gold == nil then
        return "--"
    end

    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = string.format("%dg", gold)
    end
    if silver > 0 then
        parts[#parts + 1] = string.format("%ds", silver)
    end
    if copper > 0 or #parts == 0 then
        parts[#parts + 1] = string.format("%dc", copper)
    end

    return sign .. table.concat(parts, " ")
end

-- Session money tracking. The first valid money reading after the plugin
-- loads becomes the session baseline; the delta is shown in the money
-- widget tooltip. The baseline lives on the shared Common module so it
-- survives status-bar rebuilds (e.g. settings changes) within a session.
S.session_start_money = nil

function S.note_session_start_money(total_copper)
    if type(total_copper) ~= "number" then
        return
    end
    if S.session_start_money == nil then
        S.session_start_money = total_copper
    end
end

function S.get_session_money_delta(total_copper)
    if type(total_copper) ~= "number" or S.session_start_money == nil then
        return nil
    end
    return total_copper - S.session_start_money
end

function S.format_gold_compact(gold)
    return lui_abbrev_gold(gold)
end

function S.format_wallet_quantity(value)
    local n = value
    if type(n) ~= "number" then
        n = tonumber(n)
    end
    if n == nil then
        return "--"
    end
    return lui_abbrev_number(n)
end

function S.round_nearest(value)
    return math.floor((value or 0) + 0.5)
end

function S.wear_state_to_percent(wear_state)
    return S.WEAR_STATE_TO_PERCENT[wear_state]
end

function S.color_markup(text, color)
    if color == nil then
        return tostring(text or "")
    end
    return "<rgb=" .. lui_color_to_hex(color) .. ">" .. tostring(text or "") .. "</rgb>"
end
