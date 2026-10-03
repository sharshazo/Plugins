-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"

local Widgets = _G.LUI.UI.Widgets

---@class LuiLabel : Turbine.UI.Label
local LuiLabel = class(Turbine.UI.Label)
Widgets.LuiLabel = LuiLabel

function LuiLabel:Constructor()
    Turbine.UI.Label.Constructor(self)
    self._scale = 1
end

function LuiLabel:SetFont(font)
    Turbine.UI.Label.SetFont(self, font)
    Turbine.UI.Label.SetText(self, self:GetText() or "")
end

function LuiLabel:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
end
