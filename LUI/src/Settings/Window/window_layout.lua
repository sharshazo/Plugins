-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ConfigWindow = _G.LUI.Settings.ConfigWindow
local State = _G.LUI.Settings.State
local CONFIRM_DIALOG_W = 296
local CONFIRM_DIALOG_H = 126
local CONFIRM_DIALOG_PADDING = 12
local CONFIRM_DIALOG_BUTTON_GAP = 7

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

function ConfigWindow:layout()
    local central = self:central_widget()
    if central == nil then
        return
    end
    local window_width, window_height = central:GetSize()
    local button_gap = _scaled_int(7)
    local min_content_h = _scaled_int(59)
    local content_gap = _scaled_int(7)

    local button_bar_width = window_width - self.margin_left - self.margin_right
    self.button_bar:SetPosition(self.margin_left, window_height - self.margin_bottom - self.button_bar_height)
    self.button_bar:SetSize(button_bar_width, self.button_bar_height)

    local button_width = _scaled_int(81)
    local button_height = self.button_bar_height

    self.cancel_button:SetSize(button_width, button_height)
    self.apply_button:SetSize(button_width, button_height)
    self.save_button:SetSize(button_width, button_height)
    self.move_ui_button:SetSize(button_width, button_height)

    self.save_button:SetPosition(button_bar_width - button_width, 0)
    self.apply_button:SetPosition(button_bar_width - (2 * button_width) - button_gap, 0)
    self.cancel_button:SetPosition(0, 0)
    self.move_ui_button:SetPosition(button_width + button_gap, 0)

    local content_height = window_height - self.margin_top - self.margin_bottom - self.button_bar_height - content_gap
    if content_height < min_content_h then
        content_height = min_content_h
    end

    self.main_tab_bar:SetPosition(self.margin_left, self.margin_top)
    self.main_tab_bar:SetSize(button_bar_width, content_height)
    self.main_tab_bar:refresh_layout()

    if self.confirm_overlay ~= nil then
        self.confirm_overlay:SetPosition(0, 0)
        self.confirm_overlay:SetSize(window_width, window_height)

        local dialog_width = _scaled_int(CONFIRM_DIALOG_W)
        local dialog_height = _scaled_int(CONFIRM_DIALOG_H)
        if dialog_width > window_width - (2 * self.margin_left) then
            dialog_width = window_width - (2 * self.margin_left)
        end
        if dialog_height > window_height - (2 * self.margin_top) then
            dialog_height = window_height - (2 * self.margin_top)
        end
        if dialog_width < _scaled_int(148) then
            dialog_width = _scaled_int(148)
        end
        if dialog_height < _scaled_int(89) then
            dialog_height = _scaled_int(89)
        end

        self.confirm_dialog:SetSize(dialog_width, dialog_height)
        self.confirm_dialog:SetPosition(
            math.floor((window_width - dialog_width) / 2),
            math.floor((window_height - dialog_height) / 2)
        )

        local padding = _scaled_int(CONFIRM_DIALOG_PADDING)
        local confirm_button_gap = _scaled_int(CONFIRM_DIALOG_BUTTON_GAP)
        local confirm_button_width = _scaled_int(81)
        local confirm_button_height = _scaled_int(22)
        local label_height = dialog_height - (padding * 2) - confirm_button_height - confirm_button_gap
        if label_height < _scaled_int(30) then
            label_height = _scaled_int(30)
        end

        self.confirm_dialog_label:SetPosition(padding, padding)
        self.confirm_dialog_label:SetSize(dialog_width - (padding * 2), label_height)

        self.confirm_cancel_button:SetSize(confirm_button_width, confirm_button_height)
        self.confirm_confirm_button:SetSize(confirm_button_width, confirm_button_height)
        self.confirm_confirm_button:SetPosition(dialog_width - padding - confirm_button_width,
            dialog_height - padding - confirm_button_height)
        self.confirm_cancel_button:SetPosition(
            self.confirm_confirm_button:GetLeft() - confirm_button_gap - confirm_button_width,
            self.confirm_confirm_button:GetTop()
        )
    end
end
