SecondaryWindow = class(Turbine.UI.Window)

function SecondaryWindow:Constructor()
	local width = 150
	local height = 203	-- v4.3.11: +24 boton de Asedios / v4.3.14: +24 boton de Rivales

	Turbine.UI.Window.Constructor(self)

	self:SetSize(width, height)
	self:SetPosition(data.numbers.secondaryWin_x, data.numbers.secondaryWin_y)
	self:SetMouseVisible(false)
	self:SetOpacity(0.9)

	self.DragBar = DragBar(self, L.DragBar_Secondary_Window)

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
	self.textbox_count.TextChanged = function()
		local parsed_text = string.gsub(self.textbox_count:GetText(), "%D*", "")
		if string.find(self.textbox_count:GetText(), "%D+") ~= nil then
			self.textbox_count:SetText(parsed_text)
		elseif tonumber(parsed_text) ~= nil and tonumber(parsed_text) > 99 then
			self.textbox_count:SetText(string.sub(parsed_text, 1, 2))
		end
		self:UpdateChatData()
	end

	self.enemy_button_container = Turbine.UI.Control()
	self.enemy_button_container:SetParent(self.panel)
	self.enemy_button_container:SetSize(35, 20)
	self.enemy_button_container:SetPosition(self:GetWidth() - self.enemy_button_container:GetWidth() - 5, 5)

	self.enemy_send_quickslot = Turbine.UI.Lotro.Quickslot()
	self.enemy_send_quickslot:SetParent(self.enemy_button_container)
	self.enemy_send_quickslot:SetSize(self.enemy_button_container:GetSize())
	self.enemy_send_quickslot:SetUseOnRightClick(false)
	self.enemy_send_quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, ""))
	self.enemy_send_quickslot.MouseDown = function(sender, args)
		if args.Button == Turbine.UI.MouseButton.Right then
			self.chat_context_menu:ShowMenu()
		end
	end

	self.enemy_send_button_overlay = Turbine.UI.Control()
	self.enemy_send_button_overlay:SetParent(self.enemy_button_container)
	self.enemy_send_button_overlay:SetSize(self.enemy_button_container:GetSize())
	self.enemy_send_button_overlay:SetBackColor(Default_Font_Color)
	self.enemy_send_button_overlay:SetMouseVisible(false)

	self.enemy_send_button = Turbine.UI.Label()
	self.enemy_send_button:SetParent(self.enemy_button_container)
	self.enemy_send_button:SetSize(self.enemy_button_container:GetWidth() - 2, self.enemy_button_container:GetHeight() - 2)
	self.enemy_send_button:SetPosition(1, 1)
	self.enemy_send_button:SetFont(Turbine.UI.Lotro.Font.Verdana10)
	self.enemy_send_button:SetBackColor(Panel_Back_Color or Turbine.UI.Color.Black)
	self.enemy_send_button:SetForeColor(Default_Font_Color)
	self.enemy_send_button:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.enemy_send_button:SetText(L.String_Send)
	self.enemy_send_button:SetMouseVisible(false)

	self.loc_button_container = Turbine.UI.Control()
	self.loc_button_container:SetParent(self.panel)
	self.loc_button_container:SetSize(25, 20)
	self.loc_button_container:SetPosition(self:GetWidth() - (self.loc_button_container:GetWidth() * 2) - 20, 5)

	self.loc_send_quickslot = Turbine.UI.Lotro.Quickslot()
	self.loc_send_quickslot:SetParent(self.loc_button_container)
	self.loc_send_quickslot:SetSize(self.loc_button_container:GetSize())
	self.loc_send_quickslot:SetUseOnRightClick(false)
	self.loc_send_quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, L.Loc_Command))
	self.loc_send_quickslot.MouseDown = function(sender, args)
		if args.Button == Turbine.UI.MouseButton.Right then
			self.chat_context_menu:ShowMenu()
		end
	end

	self.loc_send_button_overlay = Turbine.UI.Control()
	self.loc_send_button_overlay:SetParent(self.loc_button_container)
	self.loc_send_button_overlay:SetSize(self.loc_button_container:GetSize())
	self.loc_send_button_overlay:SetBackColor(Default_Font_Color)
	self.loc_send_button_overlay:SetMouseVisible(false)

	self.loc_send_button = Turbine.UI.Label()
	self.loc_send_button:SetParent(self.loc_button_container)
	self.loc_send_button:SetSize(self.loc_button_container:GetWidth() - 2, self.loc_button_container:GetHeight() - 2)
	self.loc_send_button:SetPosition(1, 1)
	self.loc_send_button:SetFont(Turbine.UI.Lotro.Font.Verdana10)
	self.loc_send_button:SetBackColor(Panel_Back_Color or Turbine.UI.Color.Black)
	self.loc_send_button:SetForeColor(Default_Font_Color)
	self.loc_send_button:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.loc_send_button:SetText(L.String_Loc)
	self.loc_send_button:SetMouseVisible(false)

	self.chat_context_menu = Turbine.UI.ContextMenu()
	for i = 2, #L.Chat_Channels - 8 do
		self:AddChatChannel(L.Chat_Channels[i][2])
	end

	self.recent_kills_panel = Turbine.UI.Control()
	self.recent_kills_panel:SetParent(self.panel)
	self.recent_kills_panel:SetSize(self.panel:GetWidth() - 10, 97)
	self.recent_kills_panel:SetBackColor(Default_Font_Color)
	self.recent_kills_panel:SetMouseVisible(false)
	self.recent_kills_panel:SetPosition(5, 32)

	self.recent_kills_label = Turbine.UI.Label()
	self.recent_kills_label:SetParent(self.recent_kills_panel)
	self.recent_kills_label:SetSize(self.recent_kills_panel:GetWidth() - 2, 20)
	self.recent_kills_label:SetPosition(1, 1)
	self.recent_kills_label:SetBackColor(Panel_Back_Color or Turbine.UI.Color.Black)
	self.recent_kills_label:SetForeColor(Default_Font_Color)
	self.recent_kills_label:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.recent_kills_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.recent_kills_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.recent_kills_label:SetText(L.Recent_Kills_Header)
	self.recent_kills_label:SetMouseVisible(false)

	self.recent_kills = Turbine.UI.ListBox()
	self.recent_kills:SetParent(self.recent_kills_panel)
	self.recent_kills:SetSize(self.recent_kills_panel:GetWidth() - 2, self.recent_kills_panel:GetHeight() - 22)
	self.recent_kills:SetPosition(1, 21)
	self.recent_kills:SetBackColor(Grey_Font_Color)
	self.recent_kills.maxEntries = 5
	self.recent_kills:SetMouseVisible(false)

	self.map_button = LotroButton(self.panel, width - 10, L.Map_Show)
	self.map_button:SetPosition(5, 132)
	self.map_button.Click = function()
		MapWindow:SetVisible(not MapWindow:IsVisible())
		if MapWindow:IsVisible() then
			self.map_button:SetText(L.Map_Hide)
		else
			self.map_button:SetText(L.Map_Show)
		end
	end

	-- v4.3.11: boton para mostrar u ocultar la ventana de Asedios
	self.siege_button = LotroButton(self.panel, width - 10, (storage.siege_hidden and (L.Siege_Show or "Show Sieges")) or (L.Siege_Hide or "Hide Sieges"))
	self.siege_button:SetPosition(5, 156)
	self.siege_button.Click = function()
		if PvMP_Siege ~= nil and PvMP_Siege.window ~= nil then
			PvMP_Siege.window:Toggle()
		end
	end

	-- v4.3.14: boton de rachas y nemesis
	self.rivals_button = LotroButton(self.panel, width - 10, L.Rivals_Button or "Streaks & Rivals")
	self.rivals_button:SetPosition(5, 180)
	self.rivals_button.Click = function()
		if PvMP_Rivals ~= nil then
			PvMP_Rivals.Toggle()
		end
	end

	self.VisibleChanged = function(sender)
		if not sender:IsVisible() then
			MapWindow:SetVisible(false)
			self.map_button:SetText(L.Map_Show)
		end
	end

	self.PositionChanged = function(sender, args)
		data.numbers.secondaryWin_x = self:GetLeft()
		data.numbers.secondaryWin_y = self:GetTop()
	end

	self:InitRecentKillsList()
	self:ShowRecentKills(not storage.show_recent_kills_disabled)
	self:UpdateChatData()
end

function SecondaryWindow:InitRecentKillsList()
	for i = 1, self.recent_kills.maxEntries do
		local item = self:GetRecentKillsListItem(storage.last5kills[tostring(i)])
		self.recent_kills:InsertItem(1, item)
	end
end

function SecondaryWindow:NewRecentKill(name)
	for i = 1, self.recent_kills.maxEntries - 1 do
		storage.last5kills[tostring(i)] = storage.last5kills[tostring(i + 1)]
	end
	storage.last5kills[tostring(self.recent_kills.maxEntries)] = name

	if self.recent_kills:GetItemCount() == self.recent_kills.maxEntries then
		self.recent_kills:RemoveItemAt(self.recent_kills:GetItemCount())
	end

	local item = self:GetRecentKillsListItem(name)
	self.recent_kills:InsertItem(1, item)
end

function SecondaryWindow:GetRecentKillsListItem(name)
	local item = Turbine.UI.Label()
	item:SetFont(Turbine.UI.Lotro.Font.Verdana14)
	item:SetSize(self.recent_kills:GetWidth(), self.recent_kills:GetHeight() / self.recent_kills.maxEntries)
	item:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	item:SetMouseVisible(false)
	item:SetText(name)
	return item
end

function SecondaryWindow:UpdateChatData()
	local chat_message = self.enemy_send_quickslot:GetShortcut()
	local enemy_count = self.textbox_count:GetText()

	if tonumber(enemy_count) == nil or tonumber(enemy_count) == 0 then
		enemy_count = L.FreepsCreeps
	elseif tonumber(enemy_count) == 1 then
		enemy_count = "1 " .. L.FreepCreep
	else
		enemy_count = enemy_count .. " " .. L.FreepsCreeps
	end

	local text = "/" .. L.Chat_Channels[data.numbers.selectedChannel2][1] .. " <rgb=" .. Enemy_Position_Chat_Color .. ">" .. enemy_count .. " @ " .. L.Loc_Chat .. "</rgb>"

	chat_message:SetData(text)
	self.enemy_send_quickslot:SetShortcut(chat_message)
	self.enemy_send_quickslot:SetAllowDrop(false)
end

function SecondaryWindow:DisplayChatData(west, south)
	local chat_message = self.enemy_send_quickslot:GetShortcut()
	local enemy_count = self.textbox_count:GetText()

	local best_index = 0
	local distance = 0.0
	local angle_to_point = 0.0
	local best_distance = 10000.0
	local best_distance_meters = 0.0
	local direction_index = ""
	local degrees_to_meters = 1/180
	local text = ""
	local delving = ""

	local Map_POIs = {
		[1] = { ["s"] = 16.6, ["w"] = 17.3, ["radius"] = 150 },		-- Tol Ascarnen
		[2] = { ["s"] = 11.7, ["w"] = 15.3, ["radius"] = 100 },		-- Isendeep Mine
		[3] = { ["s"] = 17.6, ["w"] = 14.5, ["radius"] = 80 },		-- Tirith Rhaw
		[4] = { ["s"] = 15.3, ["w"] = 20.0, ["radius"] = 80 },		-- Lugazag
		[5] = { ["s"] = 19.3, ["w"] = 17.5, ["radius"] = 80 },		-- Grimwood Lumber Camp
		[6] = { ["s"] = 19.9, ["w"] = 19.3, ["radius"] = 30 },		-- Hithlad Outpost
		[7] = { ["s"] = 13.4, ["w"] = 14.6, ["radius"] = 30 },		-- Arador's End Outpost
		[8] = { ["s"] = 18.4, ["w"] = 20.1, ["radius"] = 30 },		-- River Outpost
		[9] = { ["s"] = 14.5, ["w"] = 16.2, ["radius"] = 30 },		-- Isendeep Outpost
		[10] = { ["s"] = 12.2, ["w"] = 20.9, ["radius"] = 70 },		-- Gramsfoot
		[11] = { ["s"] = 17.0, ["w"] = 22.4, ["radius"] = 80 },		-- Dâr-gazag
		[12] = { ["s"] = 17.0, ["w"] = 18.6, ["radius"] = 40 },		-- Orc Camp
		[13] = { ["s"] = 13.0, ["w"] = 12.7, ["radius"] = 90 },		-- Grothum
		[14] = { ["s"] = 16.1, ["w"] = 21.0, ["radius"] = 30 },		-- Mazauk's Den
		[15] = { ["s"] = 19.0, ["w"] = 18.6, ["radius"] = 30 },		-- Spider Den
		[16] = { ["s"] = 20.7, ["w"] = 13.6, ["radius"] = 70 },		-- Glân Vraig
		[17] = { ["s"] = 16.0, ["w"] = 12.2, ["radius"] = 80 },		-- Ost Ringdyr
		[18] = { ["s"] = 18.0, ["w"] = 16.7, ["radius"] = 40 },		-- Elf Camp
		[19] = { ["s"] = 19.8, ["w"] = 20.0, ["radius"] = 80 },		-- Hoarhallow
		[20] = { ["s"] = 12.51, ["w"] = 16.61, ["radius"] = 30 },	-- Golloval
		[21] = { ["s"] = 17.14, ["w"] = 13.75, ["radius"] = 30 },	-- Goldhead
		[22] = { ["s"] = 17.40, ["w"] = 16.74, ["radius"] = 30 },	-- South Tol Ascarnen Bridge
		[23] = { ["s"] = 16.49, ["w"] = 18.20, ["radius"] = 30 },	-- West Tol Ascarnen Bridge
		[24] = { ["s"] = 67.55, ["w"] = -54.42, ["radius"] = 50 },	-- Delving - Hithlad Outpost
		[25] = { ["s"] = 65.74, ["w"] = -52.15, ["radius"] = 50 },	-- Delving - Arador's End Outpost
		[26] = { ["s"] = 66.87, ["w"] = -52.53, ["radius"] = 50 },	-- Delving - River Outpost
		[27] = { ["s"] = 66.37, ["w"] = -54.00, ["radius"] = 50 },	-- Delving - Isendeep Outpost
		[28] = { ["s"] = 66.50, ["w"] = -52.32, ["radius"] = 50 },	-- Delving - Dâr-gazag
		[29] = { ["s"] = 66.91, ["w"] = -53.98, ["radius"] = 50 },	-- Delving - Orc Camp
		[30] = { ["s"] = 66.79, ["w"] = -54.24, ["radius"] = 50 },	-- Delving - Ost Ringdyr
		[31] = { ["s"] = 66.37, ["w"] = -52.57, ["radius"] = 50 },	-- Delving - Elf Camp
		[32] = { ["s"] = 66.68, ["w"] = -53.33, ["radius"] = 50 },	-- Delving - Gaergoth
		[33] = { ["s"] = 67.41, ["w"] = -53.17, ["radius"] = 40 },	-- Delving - Rottenroot
		[34] = { ["s"] = 65.86, ["w"] = -53.30, ["radius"] = 40 }	-- Delving - Grodris
	}

	-- Search for the closest Map_POI
	for index, map in pairs(Map_POIs) do
		distance = math.sqrt((west - map.w) ^ 2 + (south - map.s) ^ 2)
		if distance < best_distance then
			best_distance = distance
			best_index = index
		end
	end

	-- Calculate distance in meters to the closest Map_POI
	best_distance_meters = math.floor((best_distance / degrees_to_meters) + 0.5)

	-- Calculate angle to the closest Map_POI
	angle_to_point = math.deg(math.atan2((Map_POIs[best_index].w - west), (Map_POIs[best_index].s - south))) % 360

	-- Find Cardinal_Direction based on angle_to_point 
	if (angle_to_point >= 337.5 or angle_to_point <= 22.5) then			-- North
		direction_index = Cardinal_Directions[1]
	elseif (angle_to_point >= 67.5 and angle_to_point <= 112.5) then	-- East
		direction_index = Cardinal_Directions[3]
	elseif (angle_to_point >= 157.5 and angle_to_point <= 202.5) then	-- South
		direction_index = Cardinal_Directions[5]
	elseif (angle_to_point >= 247.5 and angle_to_point <= 292.5) then	-- West
		direction_index = Cardinal_Directions[7]
	elseif (angle_to_point >= 22.5 and angle_to_point <= 67.5) then		-- North East
		direction_index = Cardinal_Directions[2]
	elseif (angle_to_point >= 112.5 and angle_to_point <= 157.5) then	-- South East
		direction_index = Cardinal_Directions[4]
	elseif (angle_to_point >= 202.5 and angle_to_point <= 247.5) then	-- South West
		direction_index = Cardinal_Directions[6]
	elseif (angle_to_point >= 272.5 and angle_to_point <= 337.5) then	-- North West
		direction_index = Cardinal_Directions[8]
	end

	if tonumber(enemy_count) == nil then
		enemy_count = L.FreepsCreeps
	elseif tonumber(enemy_count) == 1 then
		enemy_count = "1 " .. L.FreepCreep
	else
		enemy_count = enemy_count .. " " .. L.FreepsCreeps
	end

	-- Build delving string if applicable
	if west < 0.0 then
		delving = " in Delving "
	end

	-- Build string to display how close we are. Inside Map_POI radius is one message, outside radius is another
	if (best_distance_meters <= Map_POIs[best_index].radius) then
		text = "/" .. L.Chat_Channels[data.numbers.selectedChannel2][1] .. " <rgb=" .. Enemy_Position_Chat_Color .. ">" .. enemy_count .. delving .. " @ " .. Map_Positions[best_index]
	else
		text = "/" .. L.Chat_Channels[data.numbers.selectedChannel2][1] .. " <rgb=" .. Enemy_Position_Chat_Color .. ">" .. enemy_count .. delving .. " " .. best_distance_meters .. "m " .. direction_index .. " " .. Map_Positions[best_index]
	end

	-- v4.3.9/10: el mensaje lleva tambien las coordenadas, con el mismo formato
	-- que da ;loc ("@ Region: lugar: 15.3S, 13.1W"). Asi la marca sale en el
	-- mapa de quien lo lee, tenga esta version o la anterior de PvMP+.
	-- Siempre con punto decimal; en la Delving se deja como antes.
	if west >= 0 and south >= 0 then
		local function Coord(v)
			local t = math.floor(v * 10 + 0.5)
			return math.floor(t / 10) .. "." .. (t % 10)
		end
		local where = Map_Positions[best_index]
		if best_distance_meters > Map_POIs[best_index].radius then
			where = best_distance_meters .. "m " .. direction_index .. " " .. where
		end
		text = "/" .. L.Chat_Channels[data.numbers.selectedChannel2][1] .. " <rgb=" .. Enemy_Position_Chat_Color .. ">" .. enemy_count .. " @ Ettenmoors: " .. where .. ": " .. Coord(south) .. "S, " .. Coord(west) .. "W"
	end
	text = text .. "</rgb>"

	chat_message:SetData(text)
	self.enemy_send_quickslot:SetShortcut(chat_message)
	self.enemy_send_quickslot:SetAllowDrop(false)
end

function SecondaryWindow:ShowRecentKills(show)
	if show then
		self:SetHeight(203)
		self.panel:SetHeight(203)
		self.recent_kills_panel:SetVisible(true)
		self.map_button:SetTop(132)
	else
		self:SetHeight(203 - self.recent_kills_panel:GetHeight() - 5)
		self.panel:SetHeight(203 - self.recent_kills_panel:GetHeight() - 5)
		self.recent_kills_panel:SetVisible(false)
		self.map_button:SetTop(132 - self.recent_kills_panel:GetHeight() - 5)
	end
	if self.siege_button ~= nil then
		self.siege_button:SetTop(self.map_button:GetTop() + 24)
	end
	if self.rivals_button ~= nil then
		self.rivals_button:SetTop(self.map_button:GetTop() + 48)
	end
end

function SecondaryWindow:UpdateCount(count)
	self.textbox_count:SetText(count)
	self:UpdateChatData()
end

function SecondaryWindow:AddChatChannel(channelname, is_user_channel)
	local index = self.chat_context_menu:GetItems():GetCount() + 1
	if is_user_channel then
		for i = 1, 8 do
			if Used_User_Channels[i] == nil then
				index = 4 + i
				break
			end
		end
	end

	local menu_item = Turbine.UI.MenuItem(channelname, true, data.numbers.selectedChannel2 == index + 1)
	menu_item.Click = function(sender)
		for j = 1, self.chat_context_menu:GetItems():GetCount() do
			self.chat_context_menu:GetItems():Get(j):SetChecked(false)
		end
		sender:SetChecked(true)
		data.numbers.selectedChannel2 = index + 1
		self:UpdateChatData()
	end
	self.chat_context_menu:GetItems():Insert(index, menu_item)
end

function SecondaryWindow:RemoveChatChannel(channelname)
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