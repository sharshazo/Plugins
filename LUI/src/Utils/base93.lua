-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Base-93 integer encoding for compact chat-safe strings. The alphabet is
-- the 94 printable ASCII characters ('!'..'~') minus '<', which the LotRO
-- chat client can swallow as markup.

local Utils = _G.LUI.Utils
local Base93 = Utils.Base93 or {}
Utils.Base93 = Base93

local BASE = 93

local _chars = {}
local _values = {}
do
    local value = 0
    for byte = 33, 126 do
        if byte ~= 60 then
            local char = string.char(byte)
            _chars[value] = char
            _values[char] = value
            value = value + 1
        end
    end
end

function Base93.size()
    return BASE
end

function Base93.char_of(value)
    local char = _chars[value]
    if char == nil then
        error("Base93 value out of range: " .. tostring(value))
    end
    return char
end

-- Returns nil for characters outside the alphabet (external chat input).
function Base93.value_of(char)
    return _values[char]
end

function Base93.encode_uint(value, width)
    local out = ""
    local rest = value
    for _ = 1, width do
        out = _chars[rest % BASE] .. out
        rest = math.floor(rest / BASE)
    end
    if rest ~= 0 then
        error("Base93 value too wide: " .. tostring(value))
    end
    return out
end

-- Returns nil when the slice contains a character outside the alphabet.
function Base93.decode_uint(text, start, width)
    local value = 0
    for i = start, start + width - 1 do
        local digit = _values[string.sub(text, i, i)]
        if digit == nil then
            return nil
        end
        value = (value * BASE) + digit
    end
    return value
end
