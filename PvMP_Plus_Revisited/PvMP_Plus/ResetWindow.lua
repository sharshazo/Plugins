ResetWindow = class(Turbine.UI.Lotro.Window)

function ResetWindow:Constructor()
	local width = 250
	local height = 160
	local x = Turbine.UI.Display:GetWidth() / 2 - width / 2
	local y = Turbine.UI.Display:GetHeight() / 2 - height / 2

	Turbine.UI.Lotro.Window.Constructor(self)

	self:SetSize(width, height)
	self:SetPosition(x, y)
	self:SetZOrder(2)
	self:SetText(L.Options_Reset_Header)
	self:SetWantsKeyEvents(true)

	self.reset_text = Turbine.UI.Label()
	self.reset_text:SetParent(self)
	self.reset_text:SetSize(width - 30, 80)
	self.reset_text:SetForeColor(Default_Font_Color)
	self.reset_text:SetPosition(width / 2 - self.reset_text:GetWidth() / 2, 35)
	self.reset_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.reset_text:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.reset_text:SetText(L.Options_Reset_Warning_Text)

	self.button_confirm = LotroButton(self, 80, L.Window_Confirm)
	self.button_confirm:SetPosition(width / 2 - self.button_confirm:GetWidth() - 5, height - 40)
	self.button_confirm.Click = function()
		self:Reset()
	end

	self.button_cancel = LotroButton(self, 80, L.Window_Cancel)
	self.button_cancel:SetPosition(width / 2 + 5, height - 40)
	self.button_cancel.Click = function()
		self:Close()
	end

	self.KeyDown = function(sender, args)
		if args.Action == Turbine.UI.Lotro.Action.Escape then
			self:SetVisible(false)
		end
	end
end

function ResetWindow:Open()
	self:SetVisible(true)
end

function ResetWindow:Reset()
	local display_width = Turbine.UI.Display.GetWidth()
	local display_height = Turbine.UI.Display.GetHeight()

	data.numbers.overview_width_ratio = 0.3

	data.numbers.overview_x = math.floor(display_width / 2 - OverviewWindow:GetWidth() / 2)
	data.numbers.overview_y = 0

	data.numbers.alert_x = math.floor(display_width / 2 - AlertWindow:GetWidth() / 2)
	data.numbers.alert_y = math.floor(display_height / 4)
	AlertWindow:SetPosition(data.numbers.alert_x, data.numbers.alert_y)

	data.numbers.battle_task_x = math.floor(display_width / 2 - BattleTaskWindow:GetWidth() / 2)
	data.numbers.battle_task_y = math.floor(display_height / 8)
	BattleTaskWindow:SetPosition(data.numbers.battle_task_x, data.numbers.battle_task_y)

	data.numbers.secondaryWin_x = math.floor(display_width - SecondaryWindow:GetWidth())
	data.numbers.secondaryWin_y = math.floor(display_height / 2)
	SecondaryWindow:SetPosition(data.numbers.secondaryWin_x, data.numbers.secondaryWin_y)

	data.numbers.hitWin_x = math.floor(display_width - RecentHitsWindow:GetWidth())
	data.numbers.hitWin_y = math.floor(display_height / 2 - RecentHitsWindow:GetHeight())
	RecentHitsWindow:SetPosition(data.numbers.hitWin_x, data.numbers.hitWin_y)

	data.numbers.settingsWin_x = math.floor(display_width / 2 - Settings:GetWidth() / 2)
	data.numbers.settingsWin_y = math.floor(display_height / 2 - Settings:GetHeight() / 2)
	Settings:SetPosition(data.numbers.settingsWin_x, data.numbers.settingsWin_y)

	data.numbers.statsWin_x = math.floor(display_width / 2 - StatsWindow:GetWidth() / 2)
	data.numbers.statsWin_y = math.floor(display_height / 2 - StatsWindow:GetHeight() / 2)
	StatsWindow:SetPosition(data.numbers.statsWin_x, data.numbers.statsWin_y)

	data.numbers.mapWin_x = math.floor(display_width / 2 - MapWindow:GetWidth() / 2)
	data.numbers.mapWin_y = math.floor(display_height / 2 - MapWindow:GetHeight() / 2)
	MapWindow:SetPosition(data.numbers.mapWin_x, data.numbers.mapWin_y)

	OverviewSettingsPanel.plus_minus_button:SetBackground(0x41007f87)
	OverviewWindow.panel:SetVisible(true)
	storage.minimized = false
	storage.secondaryMinimized = false
	storage.hitWindowMinimized = false
	storage.show_remaining_points = true
	SecondaryWindow:SetVisible(true)
	OverviewWindow:SetVisible(true)
	StatsWindow:SetVisible(false)
	InitWindowPoints:SetVisible(false)
	InitWindowFrags:SetVisible(false)
	MapWindow:SetVisible(false)
	SecondaryWindow.map_button:SetText(L.Map_Show)

	RecentHitsWindow.link_hits_checkbox:SetChecked(true)

	Settings.statistics_checkbox:SetChecked(true)
	Settings.bonus_checkbox:SetChecked(true)
	Settings.outpost_checkbox:SetChecked(true)
	Settings.keep_checkbox:SetChecked(true)
	Settings.dof_checkbox:SetChecked(true)
	Settings.relic_checkbox:SetChecked(true)
	Settings.on_checkbox:SetChecked(true)

	Settings.track_warning_checkbox:SetChecked(true)
	Settings.stealth_alert_checkbox:SetChecked(true)
	Settings.yourfrag_alert_checkbox:SetChecked(true)
	Settings.lootbox_alert_checkbox:SetChecked(false)
	Settings.battletask_warning_checkbox:SetChecked(false)
	Settings.comms_warning_checkbox:SetChecked(true)

	Settings.recent_kills_checkbox:SetChecked(true)
	Settings.recent_hits_checkbox:SetChecked(true)

	data.numbers.resettime = 0

	ReloadPlugin()
end

function ResetWindow:Close()
	self:SetVisible(false)
end