-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Upkeep = _G.LUI.Features.Upkeep

-- Rank and trait variants of a skill share one localized name, and the game
-- gives no way to tell them apart: SkillInfo exposes name, icon, description
-- and type only, with no id to match the bound skill DID against. So the
-- trained skill has to be picked by name, and between same-name candidates
-- the only usable signal is which one is recovering -- that is the variant
-- the player actually cast.
--
-- Shared by the bar and the settings page so they cannot disagree: before
-- this they reduced the same candidate list from opposite ends (the bar kept
-- the last match, the page the first) and could show different skills.
function Upkeep.prefer_trained_skill(current, candidate, now)
    if current == nil then
        return candidate
    end
    if candidate == nil then
        return current
    end

    if current.GetResetTime ~= nil then
        local current_reset = current:GetResetTime()
        if current_reset ~= nil and current_reset > now then
            return current
        end
    end

    if candidate.GetResetTime ~= nil then
        local candidate_reset = candidate:GetResetTime()
        if candidate_reset ~= nil and candidate_reset > now then
            return candidate
        end
    end

    -- none of them is recovering: they are interchangeable, keep the first
    -- seen so repeated lookups stay stable
    return current
end
