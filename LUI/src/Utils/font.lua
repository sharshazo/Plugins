-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.Settings.enums"

local LUI = _G.LUI
local Utils = LUI.Utils
local LUI_ENUMS = LUI.Settings.Enums

local function _normalize_font_name(name)
    if type(name) == "number" then
        name = LUI_ENUMS.font_name_to_string[name]
    end
    if type(name) ~= "string" then
        name = "Verdana"
    end
    return (name:gsub("[%s%-%_]", ""):lower())
end

local function _choose_font_size(size, available_sizes)
    local numeric_size = size;

    local count = #available_sizes;
    if count == 1 then
        return available_sizes[1];
    end

    if numeric_size <= available_sizes[1] then
        return available_sizes[1];
    end
    if numeric_size >= available_sizes[count] then
        return available_sizes[count];
    end

    for i = 1, count - 1 do
        local lower = available_sizes[i];
        local upper = available_sizes[i + 1];
        local midpoint = (lower + upper) / 2;
        if numeric_size < midpoint then
            return lower;
        elseif numeric_size == midpoint then
            return upper;
        elseif numeric_size < upper then
            return upper;
        end
    end

    return available_sizes[count];
end

local function _lotro_font(base_name, size)
    return Turbine.UI.Lotro.Font[base_name .. tostring(size)];
end

-- The per-family size lists below must stay in sync with AVAILABLE_FONT_SIZES
-- in src/Utils/timed_row_layout.lua: the vertical time-font fit measures text
-- at sizes from that table and renders them through this function.
Utils.FONT_TO_LOTRO = function(name, size)
    local normalized_name = _normalize_font_name(name);

    if normalized_name == "arial" then
        return Turbine.UI.Lotro.Font.Arial12;
    elseif normalized_name == "bookantiqua" then
        local chosen = _choose_font_size(size, { 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36 });
        return _lotro_font("BookAntiqua", chosen);
    elseif normalized_name == "bookantiquabold" then
        local chosen = _choose_font_size(size, { 12, 14, 18, 19, 22, 24 });
        return _lotro_font("BookAntiquaBold", chosen);
    elseif normalized_name == "trajanpro" then
        local chosen = _choose_font_size(size, { 13, 14, 15, 16, 18, 19, 20, 21, 23, 24, 25, 26, 28 });
        return _lotro_font("TrajanPro", chosen);
    elseif normalized_name == "trajanprobold" then
        local chosen = _choose_font_size(size, { 16, 22, 24, 25, 30, 36 });
        return _lotro_font("TrajanProBold", chosen);
    elseif normalized_name == "verdana" then
        local chosen = _choose_font_size(size, { 10, 12, 14, 16, 18, 20, 22, 23 });
        return _lotro_font("Verdana", chosen);
    elseif normalized_name == "verdanabold" then
        return Turbine.UI.Lotro.Font.VerdanaBold16;
    elseif normalized_name == "fixedsys" then
        return Turbine.UI.Lotro.Font.FixedSys15;
    elseif normalized_name == "lucidaconsole" then
        return Turbine.UI.Lotro.Font.LucidaConsole12;
    end
end
