-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils
Utils.SearchQuery = Utils.SearchQuery or {}
local SearchQuery = Utils.SearchQuery

local function _trim_text(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function _lower_text(text)
    if type(text) ~= "string" then
        return ""
    end

    return string.lower(text)
end

local function _push_term(group, term)
    if type(term) ~= "string" then
        return
    end

    local trimmed = _trim_text(term)
    if trimmed == "" then
        return
    end

    group[#group + 1] = trimmed
end

local function _end_group(groups, group)
    if #group > 0 then
        groups[#groups + 1] = group
    end
end

local function _read_quoted_value(text, index)
    local end_index = index + 1
    local length = #text
    while end_index <= length and text:sub(end_index, end_index) ~= "\"" do
        end_index = end_index + 1
    end

    return text:sub(index + 1, end_index - 1), (end_index <= length) and (end_index + 1) or (length + 1)
end

local function _read_bare_value(text, index)
    local end_index = index
    local length = #text
    while end_index <= length do
        local next_char = text:sub(end_index, end_index)
        if next_char == "|" or next_char == "\"" or next_char:match("%s") then
            break
        end
        end_index = end_index + 1
    end

    return text:sub(index, end_index - 1), end_index
end

local function _read_token_key(text, index)
    local length = #text
    local end_index = index
    while end_index <= length do
        local next_char = text:sub(end_index, end_index)
        if next_char == ":" then
            break
        end
        if next_char:match("[%a]") == nil then
            return nil, nil
        end
        end_index = end_index + 1
    end

    if end_index > length or text:sub(end_index, end_index) ~= ":" then
        return nil, nil
    end

    return _lower_text(text:sub(index, end_index - 1)), end_index + 1
end

local function _serialize_term(term, token_keys)
    local text = _trim_text(term)
    if text == "" then
        return nil
    end

    local token_key = _read_token_key(text, 1)
    if text:find("[\"|%s]") ~= nil or (type(token_key) == "string" and type(token_keys) == "table" and token_keys[token_key] == true) then
        return "\"" .. text:gsub("\"", "") .. "\""
    end

    return text
end

local function _serialize_token_value(value)
    local text = _trim_text(value)
    if text == "" then
        return nil
    end

    if text:find("[\"|%s]") ~= nil then
        return "\"" .. text:gsub("\"", "") .. "\""
    end

    return text
end

function SearchQuery.normalize_groups(groups)
    if type(groups) ~= "table" then
        error("SearchQuery.normalize_groups requires groups table")
    end
    if #groups == 0 then
        return {}
    end

    local out = {}
    for group_index = 1, #groups do
        local group = groups[group_index]
        if type(group) ~= "table" then
            error("SearchQuery.normalize_groups requires group table")
        end
        if #group > 0 then
            local normalized_group = {}
            for term_index = 1, #group do
                local term = group[term_index]
                if type(term) ~= "string" then
                    error("SearchQuery.normalize_groups requires term string")
                end
                term = _lower_text(term)
                if term ~= "" then
                    normalized_group[#normalized_group + 1] = term
                end
            end
            if #normalized_group > 0 then
                out[#out + 1] = normalized_group
            end
        end
    end

    return out
end

function SearchQuery.group_matches(group, haystack_lower)
    if type(group) ~= "table" then
        error("SearchQuery.group_matches requires group table")
    end
    if type(haystack_lower) ~= "string" then
        error("SearchQuery.group_matches requires haystack string")
    end
    if #group == 0 then
        return false
    end

    for term_index = 1, #group do
        local term = group[term_index]
        if type(term) ~= "string" then
            error("SearchQuery.group_matches requires term string")
        end
        if term ~= "" and string.find(haystack_lower, term, 1, true) == nil then
            return false
        end
    end

    return true
end

function SearchQuery.matches_groups(groups, haystack_lower)
    if type(groups) ~= "table" then
        error("SearchQuery.matches_groups requires groups table")
    end
    if type(haystack_lower) ~= "string" then
        error("SearchQuery.matches_groups requires haystack string")
    end
    if #groups == 0 then
        return true
    end

    for group_index = 1, #groups do
        if SearchQuery.group_matches(groups[group_index], haystack_lower) == true then
            return true
        end
    end

    return false
end

-- Evaluate parsed text groups against a searchable domain (a table with
-- fold_needle / search / search_within / STOP2, e.g. Lore.Items or
-- Lore.Quests): terms inside a group AND together, groups OR together.
-- The longest usable term seeds each group globally (cached, most
-- selective); every other term probes only the surviving candidates.
-- Not usable as a seed: terms under 2 chars and baked stop bigrams
-- (2-char needles matching >5% of the domain - a cold scan for those
-- costs tens of ms and filters out nearly nothing). A group with no
-- usable seed applies no filter yet (still typing). Returns
-- { ordinal = true }, or nil for "no filter".
function SearchQuery.evaluate_domain(groups, domain)
    if groups == nil or #groups == 0 then
        return nil
    end

    local result = {}
    for group_index = 1, #groups do
        local group = groups[group_index]
        local terms = {}
        for term_index = 1, #group do
            terms[term_index] = group[term_index]
        end
        table.sort(terms, function(left, right)
            return #left > #right
        end)

        local seed_index = nil
        for term_index = 1, #terms do
            local needle = domain.fold_needle(terms[term_index])
            if #needle > 2 or (#needle == 2 and domain.STOP2[needle] ~= true) then
                seed_index = term_index
                break
            end
        end
        if seed_index == nil then
            return nil
        end

        local set, count = domain.search(terms[seed_index])
        for term_index = 1, #terms do
            if count == 0 then
                break
            end
            if term_index ~= seed_index then
                set, count = domain.search_within(terms[term_index], set)
            end
        end
        for ordinal in pairs(set) do
            result[ordinal] = true
        end
    end

    return result
end

function SearchQuery.parse(query, token_keys)
    if type(query) ~= "string" then
        error("SearchQuery.parse requires query string")
    end

    local text = query
    local groups = {}
    local current_group = {}
    local tokens = {}
    local token_map = {}
    local index = 1
    local length = #text

    while index <= length do
        local char = text:sub(index, index)
        if char == "\"" then
            local value
            value, index = _read_quoted_value(text, index)
            _push_term(current_group, value)
        elseif char == "|" then
            _end_group(groups, current_group)
            current_group = {}
            index = index + 1
        elseif char:match("%s") then
            index = index + 1
        else
            local token_key, value_index = _read_token_key(text, index)
            if type(token_key) == "string" and type(token_keys) == "table" and token_keys[token_key] == true then
                local value
                if value_index <= length and text:sub(value_index, value_index) == "\"" then
                    value, index = _read_quoted_value(text, value_index)
                else
                    value, index = _read_bare_value(text, value_index)
                end

                value = _trim_text(value)
                tokens[#tokens + 1] = {
                    key = token_key,
                    value = value,
                }
                token_map[token_key] = value
            else
                local value
                value, index = _read_bare_value(text, index)
                _push_term(current_group, value)
            end
        end
    end

    _end_group(groups, current_group)

    return {
        raw = text,
        text_groups = groups,
        normalized_groups = SearchQuery.normalize_groups(groups),
        tokens = tokens,
        token_map = token_map,
    }
end

function SearchQuery.serialize(text_groups, token_entries, token_keys)
    if type(text_groups) ~= "table" then
        error("SearchQuery.serialize requires text_groups table")
    end
    if type(token_entries) ~= "table" then
        error("SearchQuery.serialize requires token_entries table")
    end

    local parts = {}

    local group_parts = {}
    for group_index = 1, #text_groups do
        local group = text_groups[group_index]
        if type(group) ~= "table" then
            error("SearchQuery.serialize requires group table")
        end
        if #group > 0 then
            local term_parts = {}
            for term_index = 1, #group do
                local rendered = _serialize_term(group[term_index], token_keys)
                if rendered == nil then
                    error("SearchQuery.serialize requires non-empty term")
                end
                term_parts[#term_parts + 1] = rendered
            end
            if #term_parts > 0 then
                group_parts[#group_parts + 1] = table.concat(term_parts, " ")
            end
        end
    end
    if #group_parts > 0 then
        parts[#parts + 1] = table.concat(group_parts, "|")
    end

    for index = 1, #token_entries do
        local entry = token_entries[index]
        if type(entry) ~= "table" then
            error("SearchQuery.serialize requires token entry table")
        end
        if type(entry.key) ~= "string" or entry.key == "" then
            error("SearchQuery.serialize requires token entry key string")
        end
        local rendered = _serialize_token_value(entry.value)
        if rendered == nil then
            error("SearchQuery.serialize requires non-empty token entry value")
        end
        parts[#parts + 1] = entry.key .. ":" .. rendered
    end

    return table.concat(parts, " ")
end

function SearchQuery.add_token(token_entries, key, value)
    if type(token_entries) ~= "table" then
        error("SearchQuery.add_token requires token_entries table")
    end
    if type(key) ~= "string" or key == "" then
        error("SearchQuery.add_token requires token key string")
    end
    if type(value) ~= "string" then
        error("SearchQuery.add_token requires token value string")
    end

    local text = _trim_text(value)
    if text == "" then
        error("SearchQuery.add_token requires non-empty token value")
    end

    token_entries[#token_entries + 1] = {
        key = key,
        value = text,
    }
end

function SearchQuery.copy_tokens_except(state, excluded_keys)
    if type(state) ~= "table" then
        error("SearchQuery.copy_tokens_except requires state table")
    end
    if type(state.tokens) ~= "table" then
        error("SearchQuery.copy_tokens_except requires state.tokens table")
    end
    if type(excluded_keys) ~= "table" then
        error("SearchQuery.copy_tokens_except requires excluded_keys table")
    end

    local copied = {}
    local entries = state.tokens

    for index = 1, #entries do
        local entry = entries[index]
        if type(entry) ~= "table" then
            error("SearchQuery.copy_tokens_except requires token entry table")
        end
        if type(entry.key) ~= "string" or entry.key == "" then
            error("SearchQuery.copy_tokens_except requires token entry key string")
        end
        if type(entry.value) ~= "string" then
            error("SearchQuery.copy_tokens_except requires token entry value string")
        end
        if excluded_keys[entry.key] ~= true then
            copied[#copied + 1] = {
                key = entry.key,
                value = entry.value,
            }
        end
    end

    return copied
end

function SearchQuery.parse_path(value)
    local text = _trim_text(value)
    if text == "" then
        return nil
    end

    local parts = {}
    local start_index = 1
    while start_index <= #text do
        local separator_index = string.find(text, ">", start_index, true)
        local segment
        if separator_index == nil then
            segment = text:sub(start_index)
        else
            segment = text:sub(start_index, separator_index - 1)
        end

        local part = _trim_text(segment)
        if part == "" then
            return nil
        end
        parts[#parts + 1] = part

        if separator_index == nil then
            break
        end
        if separator_index == #text then
            return nil
        end
        start_index = separator_index + 1
    end

    if #parts == 0 then
        return nil
    end

    return parts
end

function SearchQuery.format_path(parts)
    if type(parts) ~= "table" or #parts == 0 then
        return nil
    end

    local out = {}
    for index = 1, #parts do
        local part = _trim_text(parts[index])
        if part == "" then
            return nil
        end
        out[#out + 1] = part
    end

    if #out == 0 then
        return nil
    end

    return table.concat(out, " > ")
end

function SearchQuery.read_level_filter(state, key)
    if type(state) ~= "table" then
        error("SearchQuery.read_level_filter requires state table")
    end
    if type(state.tokens) ~= "table" then
        error("SearchQuery.read_level_filter requires state.tokens table")
    end
    if type(key) ~= "string" or key == "" then
        error("SearchQuery.read_level_filter requires token key string")
    end

    local filter = {
        min = nil,
        max = nil,
        exact = nil,
        active = false,
        impossible = false,
    }

    local entries = state.tokens

    for index = 1, #entries do
        local entry = entries[index]
        if type(entry) ~= "table" then
            error("SearchQuery.read_level_filter requires token entry table")
        end
        if type(entry.key) ~= "string" or entry.key == "" then
            error("SearchQuery.read_level_filter requires token entry key string")
        end
        if type(entry.value) ~= "string" then
            error("SearchQuery.read_level_filter requires token entry value string")
        end
        if entry.key == key then
            local raw = _trim_text(entry.value)
            local range_min_text, range_max_text = raw:match("^(%d+)%s*%-%s*(%d+)$")
            if range_min_text ~= nil and range_max_text ~= nil then
                local range_min = math.floor(tonumber(range_min_text))
                local range_max = math.floor(tonumber(range_max_text))
                if range_min >= 1 and range_max >= 1 then
                    if range_min > range_max then
                        range_min, range_max = range_max, range_min
                    end
                    filter.active = true
                    filter.min = filter.min ~= nil and math.max(filter.min, range_min) or range_min
                    filter.max = filter.max ~= nil and math.min(filter.max, range_max) or range_max
                end
            else
                local op = ""
                local number_text = raw

                if raw:sub(1, 2) == ">=" or raw:sub(1, 2) == "<=" then
                    op = raw:sub(1, 2)
                    number_text = raw:sub(3)
                elseif raw:sub(1, 1) == ">" or raw:sub(1, 1) == "<" or raw:sub(1, 1) == "=" then
                    op = raw:sub(1, 1)
                    number_text = raw:sub(2)
                else
                    op = "="
                end

                local value = tonumber(number_text)
                if value ~= nil then
                    value = math.floor(value)
                    if value >= 1 then
                        filter.active = true
                        if op == ">" then
                            value = value + 1
                            filter.min = filter.min ~= nil and math.max(filter.min, value) or value
                        elseif op == ">=" then
                            filter.min = filter.min ~= nil and math.max(filter.min, value) or value
                        elseif op == "<" then
                            value = value - 1
                            filter.max = filter.max ~= nil and math.min(filter.max, value) or value
                        elseif op == "<=" then
                            filter.max = filter.max ~= nil and math.min(filter.max, value) or value
                        else
                            filter.exact = value
                            filter.min = filter.min ~= nil and math.max(filter.min, value) or value
                            filter.max = filter.max ~= nil and math.min(filter.max, value) or value
                        end
                    end
                end
            end
        end
    end

    if filter.min ~= nil and filter.max ~= nil and filter.min > filter.max then
        filter.impossible = true
    end

    return filter
end
