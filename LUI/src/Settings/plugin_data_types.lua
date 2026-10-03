-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Settings.default_layouts"

local Settings = _G.LUI.Settings
local Defaults = Settings.Defaults
local Types = Settings.PluginDataTypes

local KIND_TABLE = "table"
local KIND_STRING = "string"
local KIND_NUMBER = "number"
local KIND_BOOL = "bool"
local KIND_COLOR = "color"
local KIND_STYLE_VALUE = "style_value"

local STRING = { kind = KIND_STRING }
local NUMBER = { kind = KIND_NUMBER }
local BOOL = { kind = KIND_BOOL }
local COLOR = { kind = KIND_COLOR }
local STYLE_VALUE = { kind = KIND_STYLE_VALUE }

local function _table_schema(fields, options)
    local schema = {
        kind = KIND_TABLE,
        fields = fields or {},
    }

    if options ~= nil then
        schema.key_type = options.key_type
        schema.values = options.values
    end

    return schema
end

local function _array_schema(value_schema)
    return _table_schema({}, { key_type = KIND_NUMBER, values = value_schema })
end

local function _map_schema(value_schema)
    return _table_schema({}, { key_type = KIND_STRING, values = value_schema })
end

local function _is_color_default(value)
    return type(value) == "table" and
        type(value.A) == "number" and
        type(value.R) == "number" and
        type(value.G) == "number" and
        type(value.B) == "number"
end

local function _schema_from_default(value)
    local value_type = type(value)
    if value_type == "number" then
        return NUMBER
    end
    if value_type == "boolean" then
        return BOOL
    end
    if value_type == "string" then
        return STRING
    end
    if _is_color_default(value) == true then
        return COLOR
    end
    if value_type ~= "table" then
        error("Unsupported default setting type: " .. value_type)
    end

    local fields = {}
    for key, child in pairs(value) do
        fields[key] = _schema_from_default(child)
    end

    return _table_schema(fields)
end

local function _strip_minus(text)
    if string.sub(text, 1, 1) == "-" then
        return string.sub(text, 2)
    end

    return text
end

local function _is_unsigned_number_text(text)
    return type(text) == "string" and
        (string.match(text, "^%d+$") ~= nil or string.match(text, "^%d+%.%d+$") ~= nil)
end

local function _is_signed_number_text(text)
    if type(text) ~= "string" then
        return false
    end

    local unsigned = _strip_minus(text)
    if string.len(unsigned) == 0 then
        return false
    end

    return _is_unsigned_number_text(unsigned)
end

local function _number_to_text(value)
    if type(value) ~= "number" then
        error("Expected number for plugin data")
    end

    local text = string.gsub(tostring(value), ",", ".")
    if _is_signed_number_text(text) ~= true then
        error("Invalid plugin data number: " .. text)
    end

    return text
end

local function _non_negative_number_to_text(value)
    local text = _number_to_text(value)
    if _is_unsigned_number_text(text) ~= true then
        error("Invalid negative plugin data color component: " .. text)
    end

    return text
end

local function _text_to_number(text)
    if _is_signed_number_text(text) ~= true then
        error("Invalid encoded plugin data number: " .. tostring(text))
    end

    local load_chunk = loadstring or load
    local chunk = load_chunk("return " .. text)
    if chunk == nil then
        error("Invalid encoded plugin data number: " .. text)
    end

    local value = chunk()
    if type(value) ~= "number" then
        error("Invalid encoded plugin data number: " .. text)
    end

    return value
end

local function _encode_number(value)
    return "number:<" .. _number_to_text(value) .. ">"
end

local function _decode_number(value)
    if type(value) == "number" then
        return value
    end
    if type(value) ~= "string" then
        error("Expected encoded plugin data number")
    end

    local text = string.match(value, "^number:<(.+)>$")
    if text == nil then
        error("Expected encoded plugin data number: " .. value)
    end

    return _text_to_number(text)
end

local function _try_decode_number_key(key)
    if type(key) == "number" then
        return key
    end
    if type(key) ~= "string" then
        return nil
    end

    local text = string.match(key, "^number:<(.+)>$")
    if text == nil then
        return nil
    end

    return _text_to_number(text)
end

local function _encode_bool(value)
    if type(value) ~= "boolean" then
        error("Expected boolean for plugin data")
    end
    if value == true then
        return "bool:<1>"
    end

    return "bool:<0>"
end

local function _decode_bool(value)
    if type(value) == "boolean" then
        return value
    end
    if value == "bool:<1>" then
        return true
    end
    if value == "bool:<0>" then
        return false
    end

    error("Expected encoded plugin data boolean")
end

local function _encode_color(value)
    local a = value.A
    local r = value.R
    local g = value.G
    local b = value.B

    return "color:<" ..
        _non_negative_number_to_text(a) .. "," ..
        _non_negative_number_to_text(r) .. "," ..
        _non_negative_number_to_text(g) .. "," ..
        _non_negative_number_to_text(b) .. ">"
end

local function _decode_color(value)
    if type(value) == "table" then
        return value
    end
    if type(value) ~= "string" then
        error("Expected encoded plugin data color")
    end
    if string.sub(value, 1, 7) ~= "color:<" or string.sub(value, -1) ~= ">" then
        error("Expected encoded plugin data color: " .. value)
    end

    local body = string.sub(value, 8, -2)
    local parts = {}
    for part in string.gmatch(body, "([^,]+)") do
        if _is_unsigned_number_text(part) ~= true then
            error("Invalid encoded plugin data color: " .. value)
        end
        parts[#parts + 1] = _text_to_number(part)
    end
    if #parts ~= 4 then
        error("Invalid encoded plugin data color: " .. value)
    end

    return {
        A = parts[1],
        R = parts[2],
        G = parts[3],
        B = parts[4],
    }
end

local function _encode_style_value(value)
    local value_type = type(value)
    if value_type == "number" then
        return _encode_number(value)
    end
    if value_type == "boolean" then
        return _encode_bool(value)
    end
    if value_type == "string" then
        return value
    end
    if value_type == "table" or value_type == "userdata" then
        return _encode_color(value)
    end

    error("Unsupported style plugin data value type: " .. value_type)
end

local function _decode_style_value(value)
    if type(value) ~= "string" then
        return value
    end
    if string.match(value, "^number:<.+>$") ~= nil then
        return _decode_number(value)
    end
    if string.match(value, "^bool:<.+>$") ~= nil then
        return _decode_bool(value)
    end
    if string.match(value, "^color:<.+>$") ~= nil then
        return _decode_color(value)
    end

    return value
end

local function _resolve_encode_schema(schema, key)
    if schema.fields[key] ~= nil then
        return schema.fields[key]
    end

    if schema.values ~= nil then
        if schema.key_type == KIND_NUMBER and type(key) ~= "number" then
            error("Expected numeric plugin data key")
        end
        if schema.key_type == KIND_STRING and type(key) ~= "string" then
            error("Expected string plugin data key")
        end

        return schema.values
    end

    error("Missing plugin data type mapping for key: " .. tostring(key))
end

local function _encode_key(key)
    if type(key) == "number" then
        return _encode_number(key)
    end
    if type(key) == "string" then
        return key
    end

    error("Unsupported plugin data key type: " .. type(key))
end

local function _decode_key(schema, key)
    if schema.key_type == KIND_NUMBER then
        local number_key = _try_decode_number_key(key)
        if number_key == nil then
            error("Expected encoded numeric plugin data key: " .. tostring(key))
        end

        return number_key
    end

    local number_key = _try_decode_number_key(key)
    if number_key ~= nil and schema.fields[number_key] ~= nil then
        return number_key
    end

    return key
end

local function _resolve_decode_schema(schema, key)
    if schema.fields[key] ~= nil then
        return schema.fields[key]
    end

    return schema.values
end

function Types.encode(value, schema)
    if value == nil then
        return nil
    end

    if schema.kind == KIND_NUMBER then
        return _encode_number(value)
    end
    if schema.kind == KIND_BOOL then
        return _encode_bool(value)
    end
    if schema.kind == KIND_COLOR then
        return _encode_color(value)
    end
    if schema.kind == KIND_STRING then
        if type(value) ~= "string" then
            error("Expected string for plugin data")
        end
        return value
    end
    if schema.kind == KIND_STYLE_VALUE then
        return _encode_style_value(value)
    end
    if schema.kind ~= KIND_TABLE then
        error("Unsupported plugin data schema kind: " .. tostring(schema.kind))
    end
    if type(value) ~= "table" then
        error("Expected table for plugin data")
    end

    local encoded = {}
    for key, child in pairs(value) do
        local child_schema = _resolve_encode_schema(schema, key)
        encoded[_encode_key(key)] = Types.encode(child, child_schema)
    end

    return encoded
end

function Types.decode(value, schema)
    if value == nil then
        return nil
    end
    if schema == nil then
        return value
    end

    if schema.kind == KIND_NUMBER then
        return _decode_number(value)
    end
    if schema.kind == KIND_BOOL then
        return _decode_bool(value)
    end
    if schema.kind == KIND_COLOR then
        return _decode_color(value)
    end
    if schema.kind == KIND_STRING then
        return value
    end
    if schema.kind == KIND_STYLE_VALUE then
        return _decode_style_value(value)
    end
    if schema.kind ~= KIND_TABLE then
        error("Unsupported plugin data schema kind: " .. tostring(schema.kind))
    end
    if type(value) ~= "table" then
        return nil
    end

    local decoded = {}
    for key, child in pairs(value) do
        local decoded_key = _decode_key(schema, key)
        local child_schema = _resolve_decode_schema(schema, decoded_key)
        if child_schema ~= nil then
            decoded[decoded_key] = Types.decode(child, child_schema)
        end
    end

    return decoded
end

local function _recipe_identity_schema(include_count)
    local fields = {
        i = STRING,
        p = STRING,
        r = STRING,
        n = STRING,
        c = STRING,
    }

    if include_count == true then
        fields.q = NUMBER
        -- alternate-output choice for plan entries (0/absent = main output)
        fields.v = NUMBER
    end

    return _table_schema(fields)
end

local settings_schema = _schema_from_default(Defaults.Schema)
settings_schema.fields.version = STRING
settings_schema.fields.global.fields.style = _map_schema(STYLE_VALUE)
-- legacy carrier: bestiary_capture lived under global up to v2.1.0; kept
-- decodable so defaults_fill can move old saves' value into encyclopedia
settings_schema.fields.global.fields.bestiary_capture = BOOL
settings_schema.fields.launcher.fields.buttons = _array_schema(STRING)
settings_schema.fields.self.fields.upkeep.fields.slots = _array_schema(STRING)
settings_schema.fields.self.fields.upkeep.fields.slot_modes = _array_schema(NUMBER)
settings_schema.fields.status_bar.fields.item_registry = _map_schema(NUMBER)
settings_schema.fields.status_bar.fields.widgets.fields.wallet.fields.items = _array_schema(STRING)

local crafting_settings_schema = _table_schema({
    tracked_plan = _table_schema({
        entries = _array_schema(_recipe_identity_schema(true)),
    }),
    favorites = _table_schema({
        entries = _array_schema(_recipe_identity_schema(false)),
    }),
})

local character_schema = _table_schema({
    version = STRING,
    profile_id = STRING,
    crafting = crafting_settings_schema,
})

local account_schema = _table_schema({
    version = STRING,
    next_profile_id = NUMBER,
    profiles = _map_schema(_table_schema({
        name = STRING,
        settings = settings_schema,
    })),
})

local asset_record_schema = _table_schema({
    name = STRING,
    quantity = NUMBER,
    icon_id = NUMBER,
    background_image_id = NUMBER,
    quality = NUMBER,
    owner = STRING,
    slot = NUMBER,
    source_key = STRING,
    source_name = STRING,
})

local asset_source_schema = _table_schema({
    items = _array_schema(asset_record_schema),
})

local assets_cache_schema = _table_schema({
    characters = _map_schema(_table_schema({
        backpack = asset_source_schema,
        bank = asset_source_schema,
        vault = asset_source_schema,
    })),
    shared_storage = asset_source_schema,
})

local bestiary_level_schema = _table_schema({
    m = NUMBER,
    p = NUMBER,
})

local bestiary_entry_schema = _table_schema({
    k = NUMBER,
    lmin = NUMBER,
    lmax = NUMBER,
    levels = _array_schema(bestiary_level_schema),
    d = _map_schema(NUMBER),
})

Types.ACCOUNT = account_schema
Types.CHARACTER = character_schema
Types.ASSETS_CACHE = assets_cache_schema
Types.BESTIARY_CACHE = _map_schema(bestiary_entry_schema)
