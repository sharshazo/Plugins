-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- v2.3.0 -> next: the Self/Target Vitals frames get a RUF-WoTLK-style text
-- hierarchy (small name+level header, large bold health value) instead of
-- two same-size centered lines. default_schema.lua alone never reaches an
-- existing saved profile -- defaults_fill.lua only fills keys that are
-- missing, never overwrites ones a profile already has -- so this migration
-- force-applies the new label layout/height to any profile still on the old
-- shape. Idempotent: probes for the old signature (label 3 disabled, still
-- linked to POWER) before touching anything, so it's a no-op once a profile
-- is already on the new shape (including one fixed via the "Reset this
-- section to defaults" button in Vitals settings).
--
-- Font correction (added after the first version of this migration already
-- shipped and ran): `Turbine.UI.Lotro.Font.VerdanaBold` is a SINGLE fixed
-- enum member (always 16pt -- see LUI/src/Utils/font.lua's FONT_TO_LOTRO,
-- `verdanabold` branch returns `Font.VerdanaBold16` unconditionally,
-- ignoring the requested size). Using font name 9 (VerdanaBold) for labels
-- of 3 different intended sizes silently rendered all 3 at the same 16pt,
-- so the "small header / big value" hierarchy never actually showed up
-- in-game despite the settings data being correct. `BookAntiquaBold` (font
-- name 3) is a real bold family with genuine size steps
-- {12,14,18,19,22,24}, so labels now use that instead. This second fix is
-- intentionally NOT gated behind `_is_old_shape` (that signature is already
-- gone on a profile the first half of this migration already touched) --
-- it independently probes for font name 9 on labels 1/2/3 and corrects it,
-- so it repairs profiles that already went through the old (wrong-font)
-- version of this same migration step.

local VERSION = "2.3.0"
local Migrations = _G.LUI.Settings.Migrations

local function _is_old_shape(labels)
    if type(labels) ~= "table" then
        return false
    end
    local l3 = labels[3]
    return type(l3) == "table" and l3.enabled ~= true and l3.link_to == 2
end

local function _migrate_vitals_labels(vitals)
    if type(vitals) ~= "table" or type(vitals.labels) ~= "table" then
        return
    end

    local labels = vitals.labels

    if _is_old_shape(labels) == true then
        local l1 = labels[1]
        if type(l1) == "table" then
            l1.text = "[%level%] %name%"
            l1.anchor = 1     -- TOP_LEFT
            l1.width_mode = 1 -- AUTO
            l1.text_alignment = 1 -- LEFT
            l1.x_offset = 52
            l1.y_offset = 2
        end

        local l3 = labels[3]
        if type(l3) == "table" then
            l3.enabled = true
            l3.text = "%mc / %mt - %mp"
            l3.link_to = 1 -- MORALE
            l3.anchor = 8  -- BOTTOM
            l3.width_mode = 2 -- FILL
            l3.text_alignment = 2 -- CENTER
            l3.x_offset = 0
            l3.y_offset = -2
        end

        if type(vitals.morale) == "table" and vitals.morale.height == 50 then
            vitals.morale.height = 56
        end
    end

    -- Font-family fix (see file header): independent of the shape probe
    -- above, runs whenever labels 1/2/3 are still on the broken
    -- fixed-16pt VerdanaBold.
    local sizes = { [1] = 12, [2] = 14, [3] = 22 }
    for i = 1, 3 do
        local label = labels[i]
        if type(label) == "table" and type(label.font) == "table" and label.font.name == 9 then
            label.font.name = 3 -- BookAntiquaBold
            label.font.size = sizes[i]
        end
    end

    -- Color/alignment fix (Round 4): the big health value (label 3) was
    -- white and center-anchored; the RUF reference shows it in a warm
    -- gold/amber tone, right-aligned within the bar. Gated on anchor still
    -- being BOTTOM(8) -- once fixed it becomes BOTTOM_RIGHT(9), so this
    -- only ever applies once.
    local l3fix = labels[3]
    if type(l3fix) == "table" and l3fix.anchor == 8 then
        l3fix.anchor = 9 -- BOTTOM_RIGHT
        l3fix.text_alignment = 3 -- RIGHT
        l3fix.x_offset = -4
        if type(l3fix.font) == "table" and type(l3fix.font.color) == "table" then
            l3fix.font.color.R = 1.0
            l3fix.font.color.G = 0.85
            l3fix.font.color.B = 0.1
        end
    end

    -- Round 6: slim the power bar down to a real WoW/RUF-style thin strip
    -- (was as thick as a second health bar), shrink label 2's font to match,
    -- and drop the frame border to 0 so morale+power read as one seamless
    -- block instead of two boxes with a visible divider line. Each check is
    -- gated on the specific old numeric value so it only ever applies once.
    local l2 = labels[2]
    if type(l2) == "table" and type(l2.font) == "table" and l2.font.size == 14 then
        l2.font.size = 12
    end
    if type(vitals.power) == "table" and vitals.power.height == 26 then
        vitals.power.height = 20
    end
    if type(vitals.frame) == "table" and vitals.frame.border_width == 1 then
        vitals.frame.border_width = 0
    end

    -- Round 7: the class icon moved from an overlay on top of the bars to
    -- a dedicated left-side portrait COLUMN (bars shrink and start after
    -- it, matching WoW/RUF unit frames) -- a code change in vitals_base.lua,
    -- no data migration needed for that part. But label 2 (power value) is
    -- horizontally centered via FILL width_mode against the FULL frame
    -- width, which no longer matches the bar's now-narrower visible area;
    -- nudge its x_offset right by half the reserved column width so it
    -- re-centers over the actual bar instead of the whole frame.
    if type(l2) == "table" and l2.x_offset == 0 then
        l2.x_offset = 26
    end
end

local function migrate_profile(profile_settings)
    if type(profile_settings.self) == "table" then
        _migrate_vitals_labels(profile_settings.self.vitals)
    end
    if type(profile_settings.target) == "table" then
        _migrate_vitals_labels(profile_settings.target.vitals)
    end
    return profile_settings
end

Migrations.register_settings_migration(VERSION, {
    profile = migrate_profile,
})
