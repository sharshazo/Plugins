Settings = class(Turbine.UI.Lotro.Window)

function Settings:Constructor()
	local width = 430
	local height = PvMP_Language_Switchable and 570 or 540

	Turbine.UI.Lotro.Window.Constructor(self)

	self:SetSize(width, height)
	self:SetPosition(data.numbers.settingsWin_x, data.numbers.settingsWin_y)
	self:SetZOrder(1)
	self:SetText(L.Options_Header)
	self:SetWantsKeyEvents(true)

	-- Data Settings
	self.label_data_settings = OptionsPanelDivider(self, L.Options_Data_Settings, 35)

	self.points_update_button = LotroButton(self, width / 2 - 30, L.Options_Update_Points)
	self.points_update_button:SetPosition(20, self.label_data_settings:GetTop() + 35)
	self.points_update_button.Click = function()
		InitWindowPoints:Open()
	end

	self.frags_update_button = LotroButton(self, width / 2 - 30, L.Options_Update_Frags)
	self.frags_update_button:SetPosition(width / 2 + 10, self.label_data_settings:GetTop() + 35)
	self.frags_update_button.Click = function()
		InitWindowFrags:Open()
	end

	-- Display Settings
	self.label_display_settings = OptionsPanelDivider(self, L.Options_Display_Settings, self.points_update_button:GetTop() + 30)

	self.statistics_checkbox = OptionsCheckBox(self, L.Options_Show_Stats, storage.stats_hidden)
	self.statistics_checkbox:SetPosition(30, self.label_display_settings:GetTop() + 35)
	self.statistics_checkbox.CheckedChanged = function()
		storage.stats_hidden = not storage.stats_hidden
		OverviewWindow:SetStatsVisibility(not storage.stats_hidden)
		OverviewWindow:Update()
	end

	self.bonus_checkbox = OptionsCheckBox(self, L.Options_Bonus, storage.show_bonus_disabled)
	self.bonus_checkbox:SetPosition(width / 2, self.label_display_settings:GetTop() + 35)
	self.bonus_checkbox.CheckedChanged = function()
		storage.show_bonus_disabled = not storage.show_bonus_disabled
		OverviewWindow.label_bonus:SetVisible(not storage.show_bonus_disabled)
	end

	self.outpost_checkbox = OptionsCheckBox(self, L.Options_OPs, storage.show_outpost_disabled)
	self.outpost_checkbox:SetPosition(30, self.statistics_checkbox:GetTop() + 25)
	self.outpost_checkbox.CheckedChanged = function()
		storage.show_outpost_disabled = not storage.show_outpost_disabled
		OverviewWindow.outpost_1:SetVisible(not storage.show_outpost_disabled)
		OverviewWindow.outpost_1_text:SetVisible(not storage.show_outpost_disabled)
		OverviewWindow.outpost_2:SetVisible(not storage.show_outpost_disabled)
		OverviewWindow.outpost_2_text:SetVisible(not storage.show_outpost_disabled)
		OverviewWindow.outpost_3:SetVisible(not storage.show_outpost_disabled)
		OverviewWindow.outpost_3_text:SetVisible(not storage.show_outpost_disabled)
		OverviewWindow.outpost_4:SetVisible(not storage.show_outpost_disabled)
		OverviewWindow.outpost_4_text:SetVisible(not storage.show_outpost_disabled)
	end

	self.keep_checkbox = OptionsCheckBox(self, L.Options_Keeps, storage.show_keep_disabled)
	self.keep_checkbox:SetPosition(width / 2, self.bonus_checkbox:GetTop() + 25)
	self.keep_checkbox.CheckedChanged = function()
		storage.show_keep_disabled = not storage.show_keep_disabled
		UpdateKeeps()
	end

	self.dof_checkbox = OptionsCheckBox(self, L.Options_DOF, storage.show_dof_disabled)
	self.dof_checkbox:SetPosition(30, self.outpost_checkbox:GetTop() + 25)
	self.dof_checkbox.CheckedChanged = function()
		storage.show_dof_disabled = not storage.show_dof_disabled
		OverviewWindow:Update()
	end

	self.relic_checkbox = OptionsCheckBox(self, L.Options_Relic, storage.show_relic_disabled)
	self.relic_checkbox:SetPosition(width / 2, self.keep_checkbox:GetTop() + 25)
	self.relic_checkbox.CheckedChanged = function()
		storage.show_relic_disabled = not storage.show_relic_disabled
		OverviewWindow:Update()
	end

	self.on_checkbox = OptionsCheckBox(self, L.Options_ON, storage.show_on_disabled)
	self.on_checkbox:SetPosition(30, self.dof_checkbox:GetTop() + 25)
	self.on_checkbox.CheckedChanged = function()
		storage.show_on_disabled = not storage.show_on_disabled
		OverviewWindow:Update()
	end

	-- Alert Settings
	self.label_alert_settings = OptionsPanelDivider(self, L.Options_Alert_Settings, self.on_checkbox:GetTop() + 27)

	self.track_warning_checkbox = OptionsCheckBox(self, L.Options_Track_Warning, storage.track_warning_disabled)
	self.track_warning_checkbox:SetPosition(30, self.label_alert_settings:GetTop() + 35)
	self.track_warning_checkbox.CheckedChanged = function()
		storage.track_warning_disabled = not storage.track_warning_disabled
	end

	self.stealth_alert_checkbox = OptionsCheckBox(self, L.Options_StealthAlert, storage.stealth_alert_disabled)
	self.stealth_alert_checkbox:SetPosition(width / 2, self.label_alert_settings:GetTop() + 35)
	self.stealth_alert_checkbox.CheckedChanged = function()
		storage.stealth_alert_disabled = not storage.stealth_alert_disabled
	end

	self.yourfrag_alert_checkbox = OptionsCheckBox(self, L.Options_YourFragAlert, storage.yourfrag_alert_disabled)
	self.yourfrag_alert_checkbox:SetPosition(30, self.track_warning_checkbox:GetTop() + 25)
	self.yourfrag_alert_checkbox.CheckedChanged = function()
		storage.yourfrag_alert_disabled = not storage.yourfrag_alert_disabled
	end

	self.lootbox_alert_checkbox = OptionsCheckBox(self, L.Options_LootboxAlert, storage.lootbox_alert_disabled)
	self.lootbox_alert_checkbox:SetPosition(width / 2, self.track_warning_checkbox:GetTop() + 25)
	self.lootbox_alert_checkbox.CheckedChanged = function()
		storage.lootbox_alert_disabled = not storage.lootbox_alert_disabled
	end

	self.battletask_warning_checkbox = OptionsCheckBox(self, L.Options_Battle_Task_Warning, storage.battletask_warning_disabled)
	self.battletask_warning_checkbox:SetPosition(30, self.yourfrag_alert_checkbox:GetTop() + 25)
	self.battletask_warning_checkbox.CheckedChanged = function()
		storage.battletask_warning_disabled = not storage.battletask_warning_disabled
	end

	self.comms_warning_checkbox = OptionsCheckBox(self, L.Options_Commendation_Warning, storage.comms_warning_disabled)
	self.comms_warning_checkbox:SetPosition(width / 2, self.lootbox_alert_checkbox:GetTop() + 25)
	self.comms_warning_checkbox.CheckedChanged = function()
		storage.comms_warning_disabled = not storage.comms_warning_disabled
		if Commendation_Warning and not storage.comms_warning_disabled then
			OverviewWindow.label_commendations:SetForeColor(Turbine.UI.Color.Red)
		elseif not Commendation_Warning or storage.comms_warning_disabled then
			OverviewWindow.label_commendations:SetForeColor(Default_Font_Color)
			OverviewWindow.label_commendations:SetVisible(true)
			OverviewWindow.commendations_icon:SetVisible(true)
		end
	end

	-- Secondary Windows
	self.label_secondary_settings = OptionsPanelDivider(self, L.Options_Other_Windows_Settings, self.comms_warning_checkbox:GetTop() + 27)

	self.recent_kills_checkbox = OptionsCheckBox(self, L.Options_Recent_Kills, storage.show_recent_kills_disabled)
	self.recent_kills_checkbox:SetPosition(30, self.label_secondary_settings:GetTop() + 35)
	self.recent_kills_checkbox.CheckedChanged = function()
		storage.show_recent_kills_disabled = not storage.show_recent_kills_disabled
		SecondaryWindow:ShowRecentKills(not storage.show_recent_kills_disabled)
	end

	self.recent_hits_checkbox = OptionsCheckBox(self, L.Options_Recent_Hits, storage.show_recent_hits_disabled)
	self.recent_hits_checkbox:SetPosition(width / 2, self.label_secondary_settings:GetTop() + 35)
	self.recent_hits_checkbox.CheckedChanged = function()
		storage.show_recent_hits_disabled = not storage.show_recent_hits_disabled
		RecentHitsWindow:ShowRecentHits(not storage.show_recent_hits_disabled)
	end

	-- Other Settings
	self.label_other_settings = OptionsPanelDivider(self, L.Options_Other_Settings, self.recent_kills_checkbox:GetTop() + 27)

	-- Daily Reset Time
	self.label_reset_time = Turbine.UI.Label()
	self.label_reset_time:SetParent(self)
	self.label_reset_time:SetSize(width / 2 - 30, 16)
	self.label_reset_time:SetPosition(30, self.label_other_settings:GetTop() + 35)
	self.label_reset_time:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.label_reset_time:SetForeColor(Default_Font_Color)
	self.label_reset_time:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	self.label_reset_time:SetText(L.Options_Daily_Reset_Time)

	self.reset_time_minus = Turbine.UI.Button()
	self.reset_time_minus:SetParent(self)
	self.reset_time_minus:SetSize(10, 20)
	self.reset_time_minus:SetPosition(width / 2 - 20, self.label_other_settings:GetTop() + 34)
	self.reset_time_minus:SetBackground(0x41130BF6)
	self.reset_time_minus:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.reset_time_minus.MouseDown = function()
		local time_value = tonumber(string.match(self.reset_time_timer:GetText(), "(%d+):00"))
		local new_value = time_value - 1
		if new_value == -1 then
			new_value = 23
		end
		data.numbers.resettime = new_value
		self.reset_time_timer:SetText(new_value .. ":00")
	end

	self.reset_time_timer = Turbine.UI.Label()
	self.reset_time_timer:SetParent(self)
	self.reset_time_timer:SetSize(35, 20)
	self.reset_time_timer:SetPosition(self.reset_time_minus:GetLeft() + 15, self.label_other_settings:GetTop() + 33)
	self.reset_time_timer:SetForeColor(Default_Font_Color)
	self.reset_time_timer:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
	self.reset_time_timer:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.reset_time_timer:SetText(data.numbers.resettime .. ":00")

	self.reset_time_plus = Turbine.UI.Button()
	self.reset_time_plus:SetParent(self)
	self.reset_time_plus:SetSize(10, 20)
	self.reset_time_plus:SetPosition(self.reset_time_timer:GetLeft() + self.reset_time_timer:GetWidth() + 5, self.label_other_settings:GetTop() + 34)
	self.reset_time_plus:SetBackground(0x41130BF5)
	self.reset_time_plus:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.reset_time_plus.MouseDown = function()
		local time_value = tonumber(string.match(self.reset_time_timer:GetText(), "(%d+):00"))
		local new_value = time_value + 1
		if new_value == 24 then
			new_value = 0
		end
		data.numbers.resettime = new_value
		self.reset_time_timer:SetText(new_value .. ":00")
	end

	-- Progress Bar Size
	self.label_slider = Turbine.UI.Label()
	self.label_slider:SetParent(self)
	self.label_slider:SetSize(width / 2 - 30, 16)
	self.label_slider:SetPosition(30, self.label_reset_time:GetTop() + 22)
	self.label_slider:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.label_slider:SetForeColor(Default_Font_Color)
	self.label_slider:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	self.label_slider:SetText(L.Options_Window_Size)

	self.slider_bar_arrow_left = Turbine.UI.Control()
	self.slider_bar_arrow_left:SetParent(self)
	self.slider_bar_arrow_left:SetSize(16, 16)
	self.slider_bar_arrow_left:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.slider_bar_arrow_left:SetBackground(0x41007E0E)
	self.slider_bar_arrow_left:SetPosition(width / 2 - 20, self.label_reset_time:GetTop() + 22)

	self.slider_bar = Turbine.UI.Label()
	self.slider_bar:SetParent(self)
	self.slider_bar:SetSize(143, 15)
	self.slider_bar:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.slider_bar:SetBackground(0x41007E0B)
	self.slider_bar:SetPosition(width / 2 - 4, self.label_reset_time:GetTop() + 22)
	self.slider_bar.MouseDown = function(sender, args)
		local newLeft = args.X + width / 2 + 4 - self.slider:GetWidth() / 2
		if newLeft < width / 2 - 4 then
			newLeft = width / 2 - 4
		end
		if newLeft > width / 2 + 123 then
			newLeft = width / 2 + 123
		end
		self.slider:SetPosition(newLeft, self.slider:GetTop())
		data.numbers.overview_width_ratio = (newLeft + 4 - width / 2) / (sender:GetWidth() - self.slider:GetWidth())
		self.label_slider_bar_percentage:SetText(math.floor(data.numbers.overview_width_ratio * 100) .. "%")
		OverviewWindow:UpdatePosition()
	end

	self.slider_bar_arrow_right = Turbine.UI.Control()
	self.slider_bar_arrow_right:SetParent(self)
	self.slider_bar_arrow_right:SetSize(16, 16)
	self.slider_bar_arrow_right:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.slider_bar_arrow_right:SetBackground(0x41007E11)
	self.slider_bar_arrow_right:SetPosition(self.slider_bar:GetLeft() + self.slider_bar:GetWidth(), self.label_reset_time:GetTop() + 22)

	self.slider = Turbine.UI.Control()
	self.slider:SetParent(self)
	self.slider:SetSize(16, 16)
	self.slider:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.slider:SetBackground(0x41007e0c)
	self.slider:SetPosition(width / 2 - 4 + data.numbers.overview_width_ratio * (self.slider_bar:GetWidth() - self.slider:GetWidth()), self.label_reset_time:GetTop() + 22)

	self.slider.MouseDown = function(sender, args)
		self.MoveX = args.X
		self.MoveY = args.Y
		self.sliding = true
	end

	self.slider.MouseUp = function(sender, args)
		self.sliding = false
	end

	self.slider.MouseMove = function(sender, args)
		if self.sliding then
			local newLeft = sender:GetLeft() - (self.MoveX - args.X)
			if newLeft < width / 2 - 4 then
				newLeft = width / 2 - 4
			end
			if newLeft > width / 2 + 123 then
				newLeft = width / 2 + 123
			end
			sender:SetPosition(newLeft, sender:GetTop())
			data.numbers.overview_width_ratio = (newLeft + 4 - width / 2) / (self.slider_bar:GetWidth() - sender:GetWidth())
			self.label_slider_bar_percentage:SetText(math.floor(data.numbers.overview_width_ratio * 100) .. "%")
			OverviewWindow:UpdatePosition()
		end
	end

	self.label_slider_bar_percentage = Turbine.UI.Label()
	self.label_slider_bar_percentage:SetParent(self)
	self.label_slider_bar_percentage:SetSize(35, 16)
	self.label_slider_bar_percentage:SetPosition(self.slider_bar_arrow_right:GetLeft() + self.slider_bar_arrow_right:GetWidth() + 5, self.label_reset_time:GetTop() + 22)
	self.label_slider_bar_percentage:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
	self.label_slider_bar_percentage:SetForeColor(Default_Font_Color)
	self.label_slider_bar_percentage:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_slider_bar_percentage:SetText(math.floor(data.numbers.overview_width_ratio * 100) .. "%")

	-- Reset
	self.reset_button = LotroButton(self, width - 30, L.Options_Reset)
	self.reset_button:SetPosition(width / 2 - self.reset_button:GetWidth() / 2, self.label_slider:GetTop() + 30)
	self.reset_button.Click = function()
		ResetWindow:Open()
	end

	-- v4.3.2-es: idioma de la interfaz (solo cliente en ingles)
	if PvMP_Language_Switchable then
		local lang_text = L.Options_Language or "Language: English (click: Espa\195\177ol)"
		self.language_button = LotroButton(self, width - 30, lang_text)
		self.language_button:SetPosition(width / 2 - self.language_button:GetWidth() / 2, self.reset_button:GetTop() + 30)
		self.language_button.Click = function()
			local target = (locale == "es") and "en" or "es"
			Turbine.Shell.WriteLine(L.Language_Changed or "PvMP+: language changed. Reloading...")
			PvMP_SetLanguage(target)
		end
	end

	self.KeyDown = function(sender, args)
		if args.Action == Turbine.UI.Lotro.Action.Escape then
			self:SetVisible(false)
		end
	end

	self.PositionChanged = function(sender, args)
		data.numbers.settingsWin_x = self:GetLeft()
		data.numbers.settingsWin_y = self:GetTop()
	end
end

function Settings:Open()
	self:SetVisible(true)
end