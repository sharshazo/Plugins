RecentHitsWindow = class(Turbine.UI.Window)

function RecentHitsWindow:Constructor()
	local width = 120
	local height = 250

	Turbine.UI.Window.Constructor(self)

	self:SetSize(width, height)
	self:SetPosition(data.numbers.hitWin_x, data.numbers.hitWin_y)
	self:SetMouseVisible(false)
	self:SetOpacity(0.9)

	self.DragBar = DragBar(self, L.DragBar_Recent_Hits_Window)

	self.panel = Turbine.UI.Control()
	self.panel:SetParent(self)
	self.panel:SetSize(width, height)
	self.panel:SetBackColor(Panel_Back_Color or Turbine.UI.Color.Black)
	self.panel:SetMouseVisible(false)

	self.label_count = Turbine.UI.Label()
	self.label_count:SetParent(self.panel)
	self.label_count:SetSize(55, 20)
	self.label_count:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	self.label_count:SetPosition(5, 5)
	self.label_count:SetForeColor(Default_Font_Color)
	self.label_count:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.label_count:SetText(L.Recent_Hits_Amount)
	self.label_count:SetMouseVisible(false)

	self.textbox_count = LotroTextBox(self.panel, 25, "0")
	self.textbox_count:SetPosition(self.label_count:GetWidth() - 5, 5)
	self.textbox_count:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.textbox_count:SetReadOnly(true)

	self.hit_button_container = Turbine.UI.Control()
	self.hit_button_container:SetParent(self.panel)
	self.hit_button_container:SetSize(35, 20)
	self.hit_button_container:SetPosition(self:GetWidth() - self.hit_button_container:GetWidth() - 5, 5)

	self.hit_send_quickslot = Turbine.UI.Lotro.Quickslot()
	self.hit_send_quickslot:SetParent(self.hit_button_container)
	self.hit_send_quickslot:SetSize(self.hit_button_container:GetSize())
	self.hit_send_quickslot:SetUseOnRightClick(false)
	self.hit_send_quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, ""))
	self.hit_send_quickslot.MouseDown = function(sender, args)
		if args.Button == Turbine.UI.MouseButton.Right then
			self.chat_context_menu:ShowMenu()
		end
	end

	self.hit_send_button_overlay = Turbine.UI.Control()
	self.hit_send_button_overlay:SetParent(self.hit_button_container)
	self.hit_send_button_overlay:SetSize(self.hit_button_container:GetSize())
	self.hit_send_button_overlay:SetBackColor(Default_Font_Color)
	self.hit_send_button_overlay:SetMouseVisible(false)

	self.hit_send_button = Turbine.UI.Label()
	self.hit_send_button:SetParent(self.hit_button_container)
	self.hit_send_button:SetSize(self.hit_button_container:GetWidth() - 2, self.hit_button_container:GetHeight() - 2)
	self.hit_send_button:SetPosition(1, 1)
	self.hit_send_button:SetFont(Turbine.UI.Lotro.Font.Verdana10)
	self.hit_send_button:SetBackColor(Panel_Back_Color or Turbine.UI.Color.Black)
	self.hit_send_button:SetForeColor(Default_Font_Color)
	self.hit_send_button:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hit_send_button:SetText(L.String_Send)
	self.hit_send_button:SetMouseVisible(false)

	self.chat_context_menu = Turbine.UI.ContextMenu()
	for i = 1, #L.Chat_Channels - 8 do
		self:AddChatChannel(L.Chat_Channels[i][2])
	end

	self.recent_hits_panel = Turbine.UI.Control()
	self.recent_hits_panel:SetParent(self.panel)
	self.recent_hits_panel:SetSize(self.panel:GetWidth() - 10, self.panel:GetHeight() - 60)
	self.recent_hits_panel:SetBackColor(Default_Font_Color)
	self.recent_hits_panel:SetMouseVisible(false)
	self.recent_hits_panel:SetPosition(5, 32)

	self.recent_hits_label = Turbine.UI.Label()
	self.recent_hits_label:SetParent(self.recent_hits_panel)
	self.recent_hits_label:SetSize(self.recent_hits_panel:GetWidth() - 2, 20)
	self.recent_hits_label:SetPosition(1, 1)
	self.recent_hits_label:SetBackColor(Panel_Back_Color or Turbine.UI.Color.Black)
	self.recent_hits_label:SetForeColor(Default_Font_Color)
	self.recent_hits_label:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.recent_hits_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.recent_hits_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.recent_hits_label:SetText(L.Recent_Hits_Header)
	self.recent_hits_label:SetMouseVisible(false)

	self.recent_hits = Turbine.UI.ListBox()
	self.recent_hits:SetParent(self.recent_hits_panel)
	self.recent_hits:SetSize(self.recent_hits_panel:GetWidth() - 2, self.recent_hits_panel:GetHeight() - 22)
	self.recent_hits:SetPosition(1, 21)
	self.recent_hits:SetBackColor(Grey_Font_Color)
	self.recent_hits.maxEntries = 12
	self.recent_hits:SetMouseVisible(false)

	self.link_hits_checkbox = OptionsCheckBox(self.panel, L.Recent_Hits_Link_Count, storage.link_counts_disabled)
	self.link_hits_checkbox:SetSize(width - 10, 16)
	self.link_hits_checkbox:SetPosition((width - self.link_hits_checkbox:GetWidth()) / 2, self.recent_hits_panel:GetTop() + self.recent_hits_panel:GetHeight() + 5)
	self.link_hits_checkbox.CheckedChanged = function()
		storage.link_counts_disabled = not storage.link_counts_disabled
	end

	self.VisibleChanged = function(sender)
		if not sender:IsVisible() then
			self:SetVisible(false)
		end
	end

	self.PositionChanged = function(sender, args)
		data.numbers.hitWin_x = self:GetLeft()
		data.numbers.hitWin_y = self:GetTop()
	end

	self:ShowRecentHits(not storage.show_recent_hits_disabled)
	self:UpdateChatData()
end

function RecentHitsWindow:NewRecentHit(name)
	Recent_Hits_List[name] = Recent_Hits_Counter + 1
	Reversed_Recent_Hits_List[Recent_Hits_Counter + 1] = name
	Recent_Hits_Counter = Recent_Hits_Counter + 1

	self.textbox_count:SetText(Recent_Hits_Counter)

	if not storage.link_counts_disabled then
		SecondaryWindow:UpdateCount(Recent_Hits_Counter)
	end

	if self.recent_hits:GetItemCount() == self.recent_hits.maxEntries then
		self.recent_hits:RemoveItemAt(self.recent_hits:GetItemCount())
	end

	local listItem = self:GetRecentHitListItem(name)
	self.recent_hits:InsertItem(1, listItem)
	self:UpdateChatData()
end

function RecentHitsWindow:GetRecentHitListItem(name)
	local item = Turbine.UI.Label()
	item:SetFont(Turbine.UI.Lotro.Font.Verdana14)
	item:SetSize(self.recent_hits:GetWidth(), self.recent_hits:GetHeight() / self.recent_hits.maxEntries)
	item:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	item:SetMouseVisible(false)
	item:SetText(name)
	return item
end

function RecentHitsWindow:ClearHitList()
	self.textbox_count:SetText("0")
	self.recent_hits:ClearItems()
	if not storage.link_counts_disabled then
		SecondaryWindow:UpdateCount(Recent_Hits_Counter)
	end
end

function RecentHitsWindow:UpdateChatData()
	local chat_message = self.hit_send_quickslot:GetShortcut()
	local enemy_count = ""
	local name_list = ""

	if Recent_Hits_Counter == 1 then
		enemy_count = "1 " .. L.FreepCreep .. ": "
	elseif Recent_Hits_Counter > 1 then
		enemy_count = Recent_Hits_Counter .. " " .. L.FreepsCreeps .. ": "
	end

	for i = 1, Recent_Hits_Counter do
		name_list = name_list .. Reversed_Recent_Hits_List[i]
		if i < Recent_Hits_Counter then
			name_list = name_list .. ", "
		end
	end

	local text = "/" .. L.Chat_Channels[data.numbers.selectedChannel3][1] .. " <rgb=" .. Enemy_Position_Chat_Color .. ">" .. enemy_count .. "</rgb>" .. "<rgb=" .. Recent_Hits_Chat_Color .. ">" .. name_list .. "</rgb>"

	chat_message:SetData(text)
	self.hit_send_quickslot:SetShortcut(chat_message)
	self.hit_send_quickslot:SetAllowDrop(false)
end

function RecentHitsWindow:ShowRecentHits(show)
	if show then
		self:SetVisible(true)
		self.panel:SetVisible(true)
	else
		self.panel:SetVisible(false)
	end
end

function RecentHitsWindow:AddChatChannel(channelname, is_user_channel)
	local index = self.chat_context_menu:GetItems():GetCount() + 1
	if is_user_channel then
		for i = 1, 8 do
			if Used_User_Channels[i] == nil then
				index = 4 + i
				break
			end
		end
	end

	local menu_item = Turbine.UI.MenuItem(channelname, true, data.numbers.selectedChannel3 == index)
	menu_item.Click = function(sender)
		for j = 1, self.chat_context_menu:GetItems():GetCount() do
			self.chat_context_menu:GetItems():Get(j):SetChecked(false)
		end
		sender:SetChecked(true)
		data.numbers.selectedChannel3 = index
		self:UpdateChatData()
	end
	self.chat_context_menu:GetItems():Insert(index, menu_item)
end

function RecentHitsWindow:RemoveChatChannel(channelname)
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