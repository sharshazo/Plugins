-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Inventory = _G.LUI.Features.Inventory

local function _push_term(cur_group, term)
    if term ~= nil and term ~= "" then
        cur_group[#cur_group + 1] = term
    end
end

local function _end_group(groups, cur_group)
    if #cur_group > 0 then
        groups[#groups + 1] = cur_group
    end
end

-- Returns: groups = { {term1, term2}, {termA}, ... }
-- All terms are returned as raw strings (caller can lowercase).
function Inventory.parse_query(q)
    if type(q) ~= "string" then
        return {}
    end

    local groups = {}
    local cur_group = {}

    local i = 1
    local n = #q

    while i <= n do
        local c = q:sub(i, i)
        if c == "\"" then
            local j = i + 1
            while j <= n and q:sub(j, j) ~= "\"" do
                j = j + 1
            end
            local phrase = q:sub(i + 1, j - 1)
            _push_term(cur_group, phrase)
            i = (j <= n) and (j + 1) or (n + 1)
        elseif c == "|" then
            _end_group(groups, cur_group)
            cur_group = {}
            i = i + 1
        elseif c:match("%s") then
            i = i + 1
        else
            local j = i
            while j <= n do
                local cj = q:sub(j, j)
                if cj == "|" or cj == "\"" or cj:match("%s") then
                    break
                end
                j = j + 1
            end
            _push_term(cur_group, q:sub(i, j - 1))
            i = j
        end
    end

    _end_group(groups, cur_group)
    return groups
end

function Inventory.normalize_groups(groups)
    if groups == nil or #groups == 0 then
        return {}
    end

    local out = {}
    for gi = 1, #groups do
        local g = groups[gi]
        if g ~= nil and #g > 0 then
            local gg = {}
            for ti = 1, #g do
                local term = g[ti]
                if type(term) == "string" then
                    term = string.lower(term)
                    if term ~= "" then
                        gg[#gg + 1] = term
                    end
                end
            end
            if #gg > 0 then
                out[#out + 1] = gg
            end
        end
    end
    return out
end

function Inventory.matches_groups(groups, haystack_lower)
    if groups == nil or #groups == 0 then
        return true
    end
    if type(haystack_lower) ~= "string" then
        return false
    end
    for gi = 1, #groups do
        local g = groups[gi]
        local ok = true
        for ti = 1, #g do
            local term = g[ti]
            if term ~= "" and string.find(haystack_lower, term, 1, true) == nil then
                ok = false
                break
            end
        end
        if ok then
            return true
        end
    end
    return false
end
