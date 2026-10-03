-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Shared-cooldown channels baked from the game data (Skill_RecoveryChannel):
-- { [lowercased localized skill name] = channel id }. Skills on one channel
-- recover together (e.g. the Captain summons and their cosmetic variants),
-- so the window collapses them into one entry.

local Cooldowns = _G.LUI.Features.Cooldowns
local Locale = _G.LUI.Locale

import "LUI.src.Utils.i18n"

local groups = nil

local code = Locale.language_code()
if code ~= "en" then
    -- optional localized data pack; English fallback below
    if pcall(import, "LUI.src.Data.Skills.cooldown_groups_" .. code) == true then
        groups = _G.LoreData["Skills.cooldown_groups_" .. code].GROUPS
    end
end

if groups == nil then
    import "LUI.src.Data.Skills.cooldown_groups_en"
    groups = _G.LoreData["Skills.cooldown_groups_en"].GROUPS
end

Cooldowns.SKILL_GROUPS = groups
