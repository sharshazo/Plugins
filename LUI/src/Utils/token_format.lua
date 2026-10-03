-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils

local function _is_word_byte(b)
    -- 0-9 A-Z a-z _
    return b == 95
        or (b >= 48 and b <= 57)
        or (b >= 65 and b <= 90)
        or (b >= 97 and b <= 122)
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

local function lui_tokenize_format(fmt)
    if type(fmt) ~= "string" then
        fmt = tostring(fmt or "")
    end

    if string.find(fmt, "\\n", 1, true) ~= nil then
        fmt = string.gsub(fmt, "\\n", "\n")
    end

    local parts = {}
    local parts_len = 0

    local n = string.len(fmt)
    local i = 1

    while i <= n do
        local p = string.find(fmt, "%", i, true)
        if p == nil then
            if i <= n then
                parts_len = parts_len + 1
                parts[parts_len] = { text = string.sub(fmt, i) }
            end
            break
        end

        if p > i then
            parts_len = parts_len + 1
            parts[parts_len] = { text = string.sub(fmt, i, p - 1) }
        end

        if p == n then
            parts_len = parts_len + 1
            parts[parts_len] = { text = "%" }
            break
        end

        local j = p + 1
        local bj = string.byte(fmt, j)

        if bj == 37 then
            parts_len = parts_len + 1
            parts[parts_len] = { text = "%" }
            i = j + 1
        elseif bj ~= nil and _is_word_byte(bj) then
            local k = j
            while k <= n do
                local bk = string.byte(fmt, k)
                if bk ~= nil and _is_word_byte(bk) then
                    k = k + 1
                else
                    break
                end
            end

            if k <= n and string.byte(fmt, k) == 37 then
                local token = string.sub(fmt, j, k - 1)
                parts_len = parts_len + 1
                parts[parts_len] = { token = token }
                i = k + 1
            else
                local token = string.sub(fmt, j, k - 1)
                parts_len = parts_len + 1
                parts[parts_len] = { token = token }
                i = k
            end
        else
            parts_len = parts_len + 1
            parts[parts_len] = { text = "%" }
            i = j
        end
    end
    return parts
end
Utils.lui_tokenize_format = lui_tokenize_format

local function lui_format_tokenized(parts, ctx)
    if type(parts) ~= "table" then
        return tostring(parts or "")
    end
    if type(ctx) ~= "table" then
        ctx = {}
    end

    local out = {}
    local out_len = 0

    for i = 1, #parts do
        local part = parts[i]
        local token = part.token
        if token ~= nil then
            out_len = out_len + 1
            out[out_len] = tostring(ctx[token] or "-")
        else
            out_len = out_len + 1
            out[out_len] = part.text or " "
        end
    end

    return table.concat(out)
end
Utils.lui_format_tokenized = lui_format_tokenized
