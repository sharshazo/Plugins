Overview_Settings = class(Turbine.UI.Window)

function Overview_Settings:Constructor()
	Turbine.UI.Window.Constructor(self)
	self:SetSize(80, 16)
	self:SetPosition(OverviewWindow:GetLeft() + OverviewWindow:GetWidth() - self:GetWidth(), OverviewWindow:GetTop())

	self.chat_button_container = Turbine.UI.Control()
	self.chat_button_container:SetParent(self)
	self.chat_button_container:SetSize(16, 16)

	self.chat_send_quickslot = Turbine.UI.Lotro.Quickslot()
	self.chat_send_quickslot:SetParent(self.chat_button_container)
	self.chat_send_quickslot:SetSize(self.chat_button_container:GetSize())
	self.chat_send_quickslot:SetUseOnRightClick(false)
	self.chat_send_quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, ""))

	self.chat_send_quickslot.MouseDown = function(sender, args)
		if args.Button == Turbine.UI.MouseButton.Right then
			self.chat_context_menu.x, self.chat_context_menu.y = Turbine.UI.Display.GetMousePosition()
			self.chat_context_menu:ShowMenu()
		end
	end

	self.chat_send_button = Turbine.UI.Control()
	self.chat_send_button:SetParent(self.chat_button_container)
	self.chat_send_button:SetSize(self.chat_button_container:GetSize())
	self.chat_send_button:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/OverviewButtons/chat_button.tga")
	self.chat_send_button:SetMouseVisible(false)

	self.chat_context_menu = Turbine.UI.ContextMenu()
	self.chat_context_menu.menu_items = self.chat_context_menu:GetItems()

	if storage.chat_total == nil then storage.chat_total = false end
	self.chat_context_menu.total = Turbine.UI.MenuItem(L.Menu[1], true, storage.chat_total)
	self.chat_context_menu.total.Click = function()
		self.chat_context_menu.total:SetChecked(not self.chat_context_menu.total:IsChecked())
		storage.chat_total = self.chat_context_menu.total:IsChecked()
		self.chat_context_menu:ShowMenuAt(self.chat_context_menu.x, self.chat_context_menu.y)
		self:UpdateChatData()
	end

	if storage.chat_rankup == nil then storage.chat_rankup = false end
	self.chat_context_menu.rankup = Turbine.UI.MenuItem(L.Menu[2], true, storage.chat_rankup)
	self.chat_context_menu.rankup.Click = function()
		self.chat_context_menu.rankup:SetChecked(not self.chat_context_menu.rankup:IsChecked())
		storage.chat_rankup = self.chat_context_menu.rankup:IsChecked()
		self.chat_context_menu:ShowMenuAt(self.chat_context_menu.x, self.chat_context_menu.y)
		self:UpdateChatData()
	end

	if storage.chat_month == nil then storage.chat_month = true end
	self.chat_context_menu.month = Turbine.UI.MenuItem(L.Menu[3], true, storage.chat_month)
	self.chat_context_menu.month.Click = function()
		self.chat_context_menu.month:SetChecked(not self.chat_context_menu.month:IsChecked())
		storage.chat_month = self.chat_context_menu.month:IsChecked()
		self.chat_context_menu:ShowMenuAt(self.chat_context_menu.x, self.chat_context_menu.y)
		self:UpdateChatData()
	end

	if storage.chat_day == nil then storage.chat_day = true end
	self.chat_context_menu.day = Turbine.UI.MenuItem(L.Menu[4], true, storage.chat_day)
	self.chat_context_menu.day.Click = function()
		self.chat_context_menu.day:SetChecked(not self.chat_context_menu.day:IsChecked())
		storage.chat_day = self.chat_context_menu.day:IsChecked()
		self.chat_context_menu:ShowMenuAt(self.chat_context_menu.x, self.chat_context_menu.y)
		self:UpdateChatData()
	end

	if storage.chat_hour == nil then storage.chat_hour = true end
	self.chat_context_menu.hour = Turbine.UI.MenuItem(L.Menu[5], true, storage.chat_hour)
	self.chat_context_menu.hour.Click = function()
		self.chat_context_menu.hour:SetChecked(not self.chat_context_menu.hour:IsChecked())
		storage.chat_hour = self.chat_context_menu.hour:IsChecked()
		self.chat_context_menu:ShowMenuAt(self.chat_context_menu.x, self.chat_context_menu.y)
		self:UpdateChatData()
	end

	if storage.chat_tenmin == nil then storage.chat_tenmin = true end
	self.chat_context_menu.tenmin = Turbine.UI.MenuItem(L.Menu[6], true, storage.chat_tenmin)
	self.chat_context_menu.tenmin.Click = function()
		self.chat_context_menu.tenmin:SetChecked(not self.chat_context_menu.tenmin:IsChecked())
		storage.chat_tenmin = self.chat_context_menu.tenmin:IsChecked()
		self.chat_context_menu:ShowMenuAt(self.chat_context_menu.x, self.chat_context_menu.y)
		self:UpdateChatData()
	end

	if storage.chat_fight == nil then storage.chat_fight = false end
	self.chat_context_menu.fight = Turbine.UI.MenuItem(L.Menu[7], true, storage.chat_fight)
	self.chat_context_menu.fight.Click = function()
		self.chat_context_menu.fight:SetChecked(not self.chat_context_menu.fight:IsChecked())
		storage.chat_fight = self.chat_context_menu.fight:IsChecked()
		self.chat_context_menu:ShowMenuAt(self.chat_context_menu.x, self.chat_context_menu.y)
		self:UpdateChatData()
	end

	self.chat_context_menu:GetItems():Add(Turbine.UI.MenuItem("——————", false))
	self.chat_context_menu:GetItems():Add(self.chat_context_menu.total)
	self.chat_context_menu:GetItems():Add(self.chat_context_menu.rankup)
	self.chat_context_menu:GetItems():Add(self.chat_context_menu.month)
	self.chat_context_menu:GetItems():Add(self.chat_context_menu.day)
	self.chat_context_menu:GetItems():Add(self.chat_context_menu.hour)
	self.chat_context_menu:GetItems():Add(self.chat_context_menu.tenmin)
	self.chat_context_menu:GetItems():Add(self.chat_context_menu.fight)

	for i = 1, #L.Chat_Channels - 8 do
		self:AddChatChannel(L.Chat_Channels[i][2])
	end

	self.plus_minus_button = Turbine.UI.Control()
	self.plus_minus_button:SetParent(self)
	self.plus_minus_button:SetSize(16, 16)
	self.plus_minus_button:SetPosition(64, 0)
	if storage.minimized then
		self.plus_minus_button:SetBackground(0x41007f88) -- plus icon
	else
		self.plus_minus_button:SetBackground(0x41007f87) -- minus icon
	end
	self.plus_minus_button.MouseDown = function(sender, args)
		storage.minimized = OverviewWindow.panel:IsVisible()
		OverviewWindow.panel:SetVisible(not storage.minimized)
		SecondaryWindow:SetVisible((not storage.minimized) and (not storage.secondaryMinimized))
		RecentHitsWindow:SetVisible((not storage.minimized) and (not storage.hitWindowMinimized))
		BattleTaskWindow:SetVisible(not BattleTaskWindow:IsVisible())
		if storage.minimized then
			self.plus_minus_button:SetBackground(0x41007f88) -- plus icon
		else
			self.plus_minus_button:SetBackground(0x41007f87) -- minus icon
		end
	end

	self.statistics_button = Turbine.UI.Control()
	self.statistics_button:SetParent(self)
	self.statistics_button:SetSize(16, 16)
	self.statistics_button:SetPosition(16, 0)
	self.statistics_button:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/OverviewButtons/statistics_button.tga")
	self.statistics_button.MouseDown = function(sender, args)
		StatsWindow:SetVisible(not StatsWindow:IsVisible())
		if StatsWindow:IsVisible() then
			StatsWindow.tab_stats:Click()
			StatsWindow.tab_stats:MouseLeave()
		end
	end

	self.secondary_windows_button = Turbine.UI.Control()
	self.secondary_windows_button:SetParent(self)
	self.secondary_windows_button:SetSize(16, 16)
	self.secondary_windows_button:SetPosition(32, 0)
	self.secondary_windows_button:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/OverviewButtons/secondary_windows_button.tga")
	self.secondary_windows_button.MouseDown = function(sender, args)
		storage.secondaryMinimized = not storage.secondaryMinimized
		SecondaryWindow:SetVisible((not storage.minimized) and (not storage.secondaryMinimized))
		storage.hitWindowMinimized = not storage.hitWindowMinimized
		RecentHitsWindow:SetVisible((not storage.minimized) and (not storage.hitWindowMinimized))
	end

	self.settings_button = Turbine.UI.Control()
	self.settings_button:SetParent(self)
	self.settings_button:SetSize(16, 16)
	self.settings_button:SetPosition(48, 0)
	self.settings_button:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/OverviewButtons/settings_button.tga")
	self.settings_button.MouseDown = function(sender, args)
		Settings:SetVisible(not Settings:IsVisible())
	end
end

function Overview_Settings:UpdateChatData()
	local points_last_24_hours, points_last_hour, points_last_10_minutes	= GetRecentData(data.numbers.recent_points)

	local gold_chat_color = "#DAA520"
	local red_chat_color = "#FF3232"
	local beige_chat_color = "#FFFF99"

	local chat_message = self.chat_send_quickslot:GetShortcut()
	chat_message:SetData(
		"/" .. L.Chat_Channels[data.numbers.selectedChannel][1] .. " " .. "<rgb=" .. gold_chat_color .. ">" .. L.Stats_Points_Type .. "</rgb>" ..
		(storage.chat_total		  and "<rgb=" .. red_chat_color .. ">" .. L.Stats_Total					.. "</rgb>" .. "<rgb=" .. beige_chat_color .. ">" .. FormatPoints(data.numbers.points_total)			.. "</rgb> " or "") ..
		(storage.chat_rankup	  and "<rgb=" .. red_chat_color .. ">" .. L.Stats_To_RankUp				.. "</rgb>" .. "<rgb=" .. beige_chat_color .. ">" .. FormatPoints(GetRemainingPoints())					.. "</rgb> " or "") ..
		(storage.chat_month		  and "<rgb=" .. red_chat_color .. ">" .. L.Stats_Current_Month_Short	.. "</rgb>" .. "<rgb=" .. beige_chat_color .. ">" .. FormatPoints(data.numbers.points_current_month)	.. "</rgb> " or "") ..
		(storage.chat_day		  and "<rgb=" .. red_chat_color .. ">" .. L.Stats_Today					.. "</rgb>" .. "<rgb=" .. beige_chat_color .. ">" .. FormatPoints(data.numbers.points_current_day)		.. "</rgb> " or "") ..
		(storage.chat_hour		  and "<rgb=" .. red_chat_color .. ">" .. L.Stats_Last_Hour				.. "</rgb>" .. "<rgb=" .. beige_chat_color .. ">" .. points_last_hour									.. "</rgb> " or "") ..
		(storage.chat_tenmin	  and "<rgb=" .. red_chat_color .. ">" .. L.Stats_Last_10min			.. "</rgb>" .. "<rgb=" .. beige_chat_color .. ">" .. points_last_10_minutes								.. "</rgb> " or "") ..
		(storage.chat_fight		  and "<rgb=" .. red_chat_color .. ">" .. L.Stats_Last_Fight			.. "</rgb>" .. "<rgb=" .. beige_chat_color .. ">" .. FormatPoints(Points_Last_Fight)					.. "</rgb> " or "")
	)
	self.chat_send_quickslot:SetShortcut(chat_message)
	self.chat_send_quickslot:SetAllowDrop(false)
end

function Overview_Settings:AddChatChannel(channelname, is_user_channel)
	local index = self.chat_context_menu:GetItems():GetCount() - 7
	if is_user_channel then
		for i = 1, 8 do
			if Used_User_Channels[i] == nil then
				index = 5 + i
				break
			end
		end
	end

	local menu_item = Turbine.UI.MenuItem(channelname, true, data.numbers.selectedChannel == index)
	menu_item.Click = function(sender)
		for j = 1, self.chat_context_menu:GetItems():GetCount() - 8 do
			self.chat_context_menu:GetItems():Get(j):SetChecked(false)
		end
		sender:SetChecked(true)
		data.numbers.selectedChannel = index
		self:UpdateChatData()
	end
	self.chat_context_menu:GetItems():Insert(index, menu_item)
end

function Overview_Settings:RemoveChatChannel(channelname)
	local context_menu_item_list = self.chat_context_menu:GetItems()
	for j = 1, context_menu_item_list:GetCount() do
		if string.lower(context_menu_item_list:Get(j):GetText()) == string.lower(channelname) then
			for i = 1, 8 do
				if Used_User_Channels[i] == string.lower(channelname) then
					Used_User_Channels[i] = nil
					break
				end
			end
			context_menu_item_list:RemoveAt(j)
			return
		end
	end
end