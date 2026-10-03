-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.UI"
import "Turbine.UI.Lotro"

local Settings = _G.LUI.Settings
local e = Settings.Enums

e.abbrev_digits = {
    DIGITS_3 = 3,
    DIGITS_4 = 4,
}

e.abbrev_width = {
    CHARS_3 = 3,
    CHARS_4 = 4,
}

e.abbrev_method = {
    K_M_G = 1,
    K_M_B = 2,
    K_m_M = 3,
    E3_E6_E9 = 4,
}

e.side = {
    LEFT = 1,
    RIGHT = 2,
}

e.text_alignment = {
    LEFT = 1,
    CENTER = 2,
    RIGHT = 3,
}

e.vitals_label_anchor = {
    TOP_LEFT = 1,
    TOP = 2,
    TOP_RIGHT = 3,
    LEFT = 4,
    CENTER = 5,
    RIGHT = 6,
    BOTTOM_LEFT = 7,
    BOTTOM = 8,
    BOTTOM_RIGHT = 9,
}

e.vitals_label_width_mode = {
    AUTO = 1,
    FILL = 2,
}

e.time_format = {
    H24 = 1,
    AMPM = 2,
}

e.cooldown_time_format = {
    AUTO = 1,
    WHOLE_SECONDS = 2,
}

e.cooldown_group_display = {
    STABLE = 1,
    ROTATE = 2,
}

e.upkeep_track = {
    SELF = 1,
    TARGET = 2,
}

e.font_style = {
    NONE = 1,
    OUTLINE = 2,
}

e.font_name = {
    VERDANA = 1,
    BOOK_ANTIQUA = 2,
    BOOK_ANTIQUA_BOLD = 3,
    TRAJAN_PRO = 4,
    TRAJAN_PRO_BOLD = 5,
    ARIAL = 6,
    FIXED_SYS = 7,
    LUCIDA_CONSOLE = 8,
    VERDANA_BOLD = 9,
}

e.font_name_to_string = {
    [e.font_name.VERDANA] = "Verdana",
    [e.font_name.BOOK_ANTIQUA] = "BookAntiqua",
    [e.font_name.BOOK_ANTIQUA_BOLD] = "BookAntiquaBold",
    [e.font_name.TRAJAN_PRO] = "TrajanPro",
    [e.font_name.TRAJAN_PRO_BOLD] = "TrajanProBold",
    [e.font_name.ARIAL] = "Arial",
    [e.font_name.FIXED_SYS] = "FixedSys",
    [e.font_name.LUCIDA_CONSOLE] = "LucidaConsole",
    [e.font_name.VERDANA_BOLD] = "VerdanaBold",
}

e.vitals_effects_position = {
    ABOVE = 1,
    BELOW = 2,
}

e.vitals_effect_slot = {
    TOP_NEAR = 1,
    TOP_FAR = 2,
    BOTTOM_NEAR = 3,
    BOTTOM_FAR = 4,
}

e.vitals_label_link = {
    MORALE = 1,
    POWER = 2,
    INFO = 3,
}

e.raid_layout_mode = {
    TWO_COLUMNS = "two_columns",
    THREE_COLUMNS = "three_columns",
    FOUR_COLUMNS_MODE_1 = "four_columns_mode_1",
    FOUR_COLUMNS_MODE_2 = "four_columns_mode_2",
    SIX_COLUMNS_MODE_1 = "six_columns_mode_1",
    SIX_COLUMNS_MODE_2 = "six_columns_mode_2",
}

e.bar_mode = {
    LOAD = 1,
    UNLOAD = 2,
}

e.orientation = {
    HORIZONTAL = 1,
    VERTICAL = 2,
}

e.list_flow = {
    TOP_TO_BOTTOM = 1,
    BOTTOM_TO_TOP = 2,
}

e.vertical_align = {
    TOP = 1,
    BOTTOM = 2,
}

e.assets_view_mode = {
    ICONS = 1,
    DETAILS = 2,
}

e.side_is_left = {
    [e.side.LEFT] = true,
    [e.side.RIGHT] = false,
}

local to_lotro = Settings.ToLotro

to_lotro.text_alignment = {
    [e.text_alignment.LEFT] = Turbine.UI.ContentAlignment.MiddleLeft,
    [e.text_alignment.CENTER] = Turbine.UI.ContentAlignment.MiddleCenter,
    [e.text_alignment.RIGHT] = Turbine.UI.ContentAlignment.MiddleRight,
}

to_lotro.font_style = {
    [e.font_style.NONE] = Turbine.UI.FontStyle.None,
    [e.font_style.OUTLINE] = Turbine.UI.FontStyle.Outline,
}
