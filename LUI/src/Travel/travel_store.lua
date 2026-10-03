-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Travel = _G.LUI.Features.Travel
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI.Lotro"

local TravelStore = class()
Travel.TravelStore = TravelStore

local LANG_KEYS = { "EN", "DE", "FR", "RU" }

local function _build_skill_shortcut(skill_id)
    local shortcut = Turbine.UI.Lotro.Shortcut()
    shortcut:SetType(Turbine.UI.Lotro.ShortcutType.Skill)
    shortcut:SetData(skill_id)
    return shortcut
end

local function _build_lookup()
    local lookup = {}
    local skill_data = Travel.SkillData

    for i = 1, #skill_data do
        local entry = skill_data[i]
        local skill_id = entry.id
        if skill_id ~= "" then
            for j = 1, #LANG_KEYS do
                local lang_key = LANG_KEYS[j]
                local localized = entry[lang_key]
                local skill_name = localized.name
                if skill_name ~= "" then
                    local bucket = lookup[skill_name]
                    if bucket == nil then
                        bucket = {}
                        lookup[skill_name] = bucket
                    end
                    bucket[#bucket + 1] = {
                        id = skill_id,
                        desc = localized.desc,
                    }
                end
            end
        end
    end

    return lookup
end

local function _entry_signature(entries)
    local parts = {}

    for i = 1, #entries do
        local entry = entries[i]
        parts[#parts + 1] = table.concat({
            tostring(entry.id or ""),
            tostring(entry.name or ""),
        }, "\31")
    end

    return table.concat(parts, "\30")
end

local function _sort_entries(entries)
    table.sort(entries, function(left, right)
        local left_name = tostring(left.name or "")
        local right_name = tostring(right.name or "")
        if left_name == right_name then
            return tostring(left.id or "") < tostring(right.id or "")
        end
        return left_name < right_name
    end)
end

function TravelStore:Constructor()
    self._lookup = _build_lookup()
    self.entries = {}
    self.version = 0
    self._signature = ""
end

function TravelStore:_resolve_skill_id(skill_name, skill_description, used_ids)
    if skill_name == nil or skill_name == "" then
        return nil
    end

    local candidates = self._lookup[skill_name]
    if candidates == nil or #candidates <= 0 then
        return nil
    end
    if #candidates == 1 then
        return candidates[1].id
    end

    if skill_description ~= nil and skill_description ~= "" then
        for i = 1, #candidates do
            local candidate = candidates[i]
            local wanted_desc = candidate.desc
            if wanted_desc ~= nil and wanted_desc ~= "" and
                string.find(skill_description, wanted_desc, 1, true) ~= nil and
                used_ids[candidate.id] ~= true then
                return candidate.id
            end
        end
    end

    for i = 1, #candidates do
        local candidate = candidates[i]
        if candidate.id ~= nil and used_ids[candidate.id] ~= true then
            return candidate.id
        end
    end

    return candidates[1].id
end

function TravelStore:_scan_travel_skills()
    local entries = {}
    local seen_ids = {}
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local skills = player:GetTrainedSkills()

    for i = 1, skills:GetCount() do
        local skill = skills:GetItem(i)
        local skill_info = skill:GetSkillInfo()
        local skill_name = skill_info:GetName()
        local skill_desc = skill_info:GetDescription()
        local skill_id = self:_resolve_skill_id(skill_name, skill_desc, seen_ids)
        if skill_id ~= nil and seen_ids[skill_id] ~= true then
            seen_ids[skill_id] = true
            entries[#entries + 1] = {
                id = skill_id,
                name = skill_name,
                description = skill_desc,
                shortcut = _build_skill_shortcut(skill_id),
            }
        end
    end

    _sort_entries(entries)
    return entries
end

function TravelStore:refresh(force)
    local entries = self:_scan_travel_skills()
    local signature = _entry_signature(entries)
    if force ~= true and signature == self._signature then
        return false
    end

    self.entries = entries
    self._signature = signature
    self.version = self.version + 1
    return true
end

function TravelStore:get_entries()
    return self.entries
end

function TravelStore:destroy()
    self.entries = {}
    self._signature = ""
end
