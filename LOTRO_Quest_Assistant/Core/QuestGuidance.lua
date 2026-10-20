-- Offline guidance. Loaded only when a quest is inspected, never by a frame timer.
-- Stable quest DID guards every record; ndx and chat/progress indexes stay unchanged.
_G.QuestGuidance = {}
local G = QuestGuidance
local SHARD_SIZE, MAX_NDX, CACHE_LIMIT = 32, 14974, 8
local encoded = { es = {}, en = {} }
local loaded = { es = {}, en = {} }
local failed = { es = {}, en = {} }
local cache, clock = {}, 0
local stats = { shards = 0, encodedBytes = 0, decoded = 0, hits = 0 }

function G.Register(lang, shard, records)
    if not encoded[lang] or type(shard) ~= "number" or type(records) ~= "table" then return end
    if loaded[lang][shard] then return end
    for ndx, value in pairs(records) do
        if type(ndx) == "number" and math.floor((ndx - 1) / SHARD_SIZE) + 1 == shard
            and type(value) == "string" then
            encoded[lang][ndx] = value
            stats.encodedBytes = stats.encodedBytes + #value
        end
    end
    loaded[lang][shard] = true
    failed[lang][shard] = nil
    stats.shards = stats.shards + 1
end

local function language(lang)
    if lang == "en" or lang == "es" then return lang end
    return _G.LanguageSettings and not LanguageSettings.IsSpanish() and "en" or "es"
end

local function did(quest)
    if not quest or type(quest.id) ~= "string" then return nil end
    return string.upper((string.gsub(quest.id, "^0[xX]", "")))
end

function G.Get(ndx, quest, lang)
    ndx = tonumber(ndx)
    if not ndx or ndx < 1 or ndx > MAX_NDX or ndx ~= math.floor(ndx) then return nil end
    local id = did(quest)
    if not id then return nil end
    lang = language(lang)
    local key = lang .. ":" .. ndx
    clock = clock + 1
    local found = cache[key]
    if found and found.data.id == id then
        found.used = clock
        stats.hits = stats.hits + 1
        return found.data
    end
    local shard = math.floor((ndx - 1) / SHARD_SIZE) + 1
    if failed[lang][shard] then return nil end
    if not loaded[lang][shard] then
        -- A failed/missing import leaves normal quest details and existing points available.
        local ok = pcall(import, string.format("LOTRO_Quest_Assistant.Data.QuestGuide_%s_%03d", string.upper(lang), shard))
        if not ok or not loaded[lang][shard] then
            failed[lang][shard] = true
            return nil
        end
    end
    local raw = encoded[lang][ndx]
    if not raw or string.match(raw, "^([^\n]+)\n") ~= id then return nil end
    local data = { id = id, lang = lang, steps = {} }
    for index, action, context in string.gmatch(raw, "\n(%d+)\t([^\t\n]*)\t([^\t\n]*)") do
        local actions = {}
        for part in string.gmatch(action .. "\030", "([^\030]*)\030") do
            if part ~= "" then actions[#actions + 1] = part end
        end
        data.steps[#data.steps + 1] = { index = tonumber(index), actions = actions, context = context }
    end
    if #data.steps == 0 then return nil end
    if not cache[key] then
        local count, oldest, oldestTime = 0, nil, math.huge
        for k, entry in pairs(cache) do
            count = count + 1
            if entry.used < oldestTime then oldest, oldestTime = k, entry.used end
        end
        if count >= CACHE_LIMIT then cache[oldest] = nil end
    end
    cache[key] = { data = data, used = clock }
    stats.decoded = stats.decoded + 1
    return data
end

local function objectiveKey(text)
    if type(text) ~= "string" then return "" end
    text = string.gsub(text, "<[^>]*>", "")
    text = string.gsub(text, "%(%s*%d+%s*/%s*%d+%s*%)", "")
    text = string.gsub(text, "%d+%s*/%s*%d+", "")
    text = string.gsub(text, "%(%s*total:%s*%d+%s*%)", "")
    text = string.gsub(text, "%(cantidad: según el diario%)", "")
    text = string.gsub(text, "%(quantity: see journal%)", "")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(string.gsub(text, "^%s+", ""), "%s+$", "")
    if _G.QuestLocResolver and QuestLocResolver.NormalizeES then return QuestLocResolver.NormalizeES(text) end
    return string.lower(text)
end

-- Match a complete action, never a bare N/M or a guessed percentage through the quest.
-- An action reused by different stages is deliberately ambiguous.
function G.FindStage(data, progress)
    if not data then return nil end
    local key = objectiveKey(progress)
    if key == "" then return nil end
    local found
    for order, step in ipairs(data.steps) do
        for _, action in ipairs(step.actions) do
            if objectiveKey(action) == key then
                if found and found ~= order then return nil end
                found = order
            end
        end
    end
    return found
end

function G.GetNote(ndx, quest, lang)
    local note = _G.QuestGuideNotes and QuestGuideNotes[ndx]
    if note and note.id == did(quest) then return note[language(lang)], note.sources end
    return nil
end

-- A single short objective for the existing hover card. No guide window is created.
local function shortText(text, limit)
    text = string.gsub(tostring(text or ""), "<[^>]*>", "")
    text = string.gsub(text, "%(%s*total:%s*(%d+)%s*%)", " (x%1)")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(string.gsub(text, "^%s+", ""), "%s+$", "")
    local chars = {}
    for ch in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = ch end
    if #chars <= limit then return text end
    local stop = limit - 3
    for i = stop, math.max(1, stop - 26), -1 do
        if chars[i] == " " then stop = i - 1; break end
    end
    return table.concat(chars, "", 1, stop) .. "..."
end

local function firstSentence(text)
    return string.match(text or "", "^%s*(.-)[%.!?]%s")
        or string.match(text or "", "^%s*(.-)[%.!?]$") or text or ""
end

local function placeText(context, es)
    local sentence = firstSentence(context)
    local place
    if es then
        place = string.match(sentence, "[Ss]e encuentra[n]? (.+)")
            or string.match(sentence, "[Pp]uede[n]? encontrarse (.+)")
            or string.match(sentence, "[Ee]stá[n]? (en .+)")
            or string.match(sentence, "[Ee]stá[n]? (al .+)")
    else
        place = string.match(sentence, "can be found (.+)")
            or string.match(sentence, "may be found (.+)")
            or string.match(sentence, " is (at .+)") or string.match(sentence, " is (in .+)")
            or string.match(sentence, " are (at .+)") or string.match(sentence, " are (in .+)")
            or string.match(sentence, " lies (.+)")
    end
    return place
end

-- Only exact action matches identify a stage. A bare fraction never selects one.
function G.Summary(ndx, quest, lang, progress)
    local data = G.Get(ndx, quest, lang)
    if not data then return nil end
    local current = G.FindStage(data, progress)
    local es = data.lang == "es"
    local note = _G.QuestGuideNotes and QuestGuideNotes[ndx]
    local text
    if not current and note and note.id == data.id then
        text = note[data.lang]
    end
    if not text then
        local step = data.steps[current or 1]
        local actions = {}
        for i = 1, math.min(2, #step.actions) do
            local action = step.actions[i]
            -- Journal-only stages can contain a narrative paragraph. Prefer its instruction.
            if #action > 180 then
                for sentence in string.gmatch(action .. " ", "([^%.!?]+)[%.!?]%s+") do
                    local s = string.gsub(sentence, "^%s+", "")
                    if string.find(s, "^[Dd]ebes ") or string.find(s, "^[Dd]eberías ")
                        or string.find(s, "^[Yy]ou should ") or string.find(s, "^[Yy]ou must ") then
                        action = s; break
                    end
                end
                action = firstSentence(action)
            end
            actions[#actions + 1] = shortText(action, 128)
        end
        text = table.concat(actions, "; ")
        if #step.actions > 2 then text = text .. (es and "; más objetivos en el diario" or "; more objectives in journal") end
        local place = placeText(step.context, es)
        if place then
            text = shortText(text, 135) .. ". " .. (es and "Lugar: " or "Location: ") .. shortText(place, 66)
        end
        -- If all we know for an active quest is a number, do not claim the first stage is current.
        local active = _G.QuestStateManager and QuestStateManager.GetQuestState
            and QuestStateManager.GetQuestState(ndx) == "ACTIVE"
        if active and not current then text = (es and "Al inicio: " or "Initially: ") .. text end
    end
    return { action = shortText(text, 220), context = nil, matched = current ~= nil, lang = data.lang }
end


function G.Stats()
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    return { shards = stats.shards, encodedBytes = stats.encodedBytes, cacheEntries = count,
        cacheLimit = CACHE_LIMIT, decoded = stats.decoded, hits = stats.hits }
end
