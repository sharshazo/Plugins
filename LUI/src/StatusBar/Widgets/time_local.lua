-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local LUI_ENUMS = _G.LUI.Settings.Enums
local class = _G.LUI.Core.class
local S = _G.LUI.Features.StatusBar.Common
local WidgetBase = _G.LUI.Features.StatusBar.WidgetBase

local TimeLocalWidget = class(WidgetBase)
StatusBarWidgets.TimeLocalWidget = TimeLocalWidget

function TimeLocalWidget:Constructor(widget_w, bar_h, font, content_alignment, time_format)
    WidgetBase.Constructor(self, "time_local", widget_w, bar_h, font,
        content_alignment or Turbine.UI.ContentAlignment.MiddleCenter, nil)
    self._time_format = time_format or LUI_ENUMS.time_format.H24
end

function TimeLocalWidget:update(now)
    self:set_text(S.format_hhmm(Turbine.Engine.GetDate(), self._time_format))
end
