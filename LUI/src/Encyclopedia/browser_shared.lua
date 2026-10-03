-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Shared scaffolding helpers for the Encyclopedia browser panels (item
-- and quest tabs): sizing and parsing math that must behave identically
-- in every tab lives here; panel-specific layout stays in each file.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local State = _G.LUI.Settings.State
local Encyclopedia = _G.LUI.Features.Encyclopedia

local BrowserShared = {}
Encyclopedia.BrowserShared = BrowserShared

-- filter dropdowns size to their longest option (estimate, same approach
-- as the card chips): byte length x char width + arrow/padding, clamped.
-- The max clamp is per-tab (quest categories run longer than item types).
local BASE_FILTER_CHAR_W = 6.2
local BASE_DROPDOWN_PAD = 26
local BASE_DROPDOWN_MIN_W = 70

function BrowserShared.dropdown_base_w(labels, base_max_w)
    local longest = 0
    for i = 1, #labels do
        local n = string.len(labels[i] or "")
        if n > longest then
            longest = n
        end
    end
    local w = (longest * BASE_FILTER_CHAR_W) + BASE_DROPDOWN_PAD
    return math.min(base_max_w, math.max(BASE_DROPDOWN_MIN_W, w))
end

function BrowserShared.scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * State.settings.global.scale)
end

-- level/iLvl range boxes accept positive integers; anything else means
-- "no bound"
function BrowserShared.parse_level(text)
    local value = tonumber(text)
    if value == nil then
        return nil
    end
    value = math.floor(value)
    if value <= 0 then
        return nil
    end
    return value
end
