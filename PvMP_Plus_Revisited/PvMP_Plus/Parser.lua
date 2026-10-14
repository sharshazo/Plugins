Turbine.ChatType.EventBroadcast = 33

-- v4.3.2-es: el analisis del chat va protegido con pcall; un mensaje raro
-- (nombre vacio, numero sin formato) ya no rompe el plugin entero.
local function ParseChat(sender,args)
	if args.ChatType == Turbine.ChatType.Error or args.ChatType == Turbine.ChatType.Tell or
		args.ChatType == Turbine.ChatType.Emote or args.ChatType == Turbine.ChatType.Trade or
		args.ChatType == Turbine.ChatType.LFF or args.ChatType == Turbine.ChatType.Roleplay or
		args.ChatType == Turbine.ChatType.PlayerCombat or args.ChatType == Turbine.ChatType.World then
		return
	end

	-- Parse Points
	if args.ChatType == Turbine.ChatType.Advancement and string.find(args.Message, L.Chat_Earned_Points) and string.find(args.Message, L.Chat_Points) then
		local current_date = Turbine.Engine.GetDate()
		local now = GetSecondsOfYear()
		local points_gained = string.match(args.Message, "(%d[%d.,]*)")
		points_gained = tonumber((string.gsub(points_gained, "%D*", "")))

		if New_Fight_1 then
			New_Fight_1 = false
			Points_Last_Fight = 0
		end

		if (Local_Player:IsInCombat() or Local_Player:GetMorale() == nil) then
			Points_Last_Fight = Points_Last_Fight + points_gained
		end

		data.numbers.points_current_day = data.numbers.points_current_day + points_gained
		data.numbers.points_current_month = data.numbers.points_current_month + points_gained
		data.numbers.points_total = data.numbers.points_total + points_gained
		data.numbers.recent_points[now] = (data.numbers.recent_points[now] or 0) + points_gained

		if data.numbers.points_current_day > data.numbers.most_points_a_day[1] then
			data.numbers.most_points_a_day = { data.numbers.points_current_day, current_date.Day, current_date.Month, current_date.Year }
		end

		if data.numbers.points_current_month > data.numbers.most_points_a_month[1] then
			data.numbers.most_points_a_month = { data.numbers.points_current_month, current_date.Month, current_date.Year }
		end

		if points_gained > data.numbers.most_points_a_fight[1] then
			data.numbers.most_points_a_fight = { points_gained, current_date.Day, current_date.Month, current_date.Year }
		end

		OverviewWindow:Update()

		Plugins["PvMP+"].Unload(nil, nil, false)

	-- Parse Commendations
	elseif args.ChatType == Turbine.ChatType.SelfLoot and string.find(args.Message, L.Chat_Earned_Commendations_Start) and string.find(args.Message, L.Chat_Earned_Commendations_End) then
		local current_date = Turbine.Engine.GetDate()
		local now = GetSecondsOfYear()
		local comms_gained = string.match(args.Message, L.Chat_Earned_Commendations_Start .. "(%d[%d.,]*)" .. L.Chat_Earned_Commendations_End)
		comms_gained = tonumber((string.gsub(comms_gained, "%D*", "")))

		if New_Fight_2 then
			New_Fight_2 = false
			Comms_Last_Fight = 0
		end

		if (Local_Player:IsInCombat() or Local_Player:GetMorale() == nil) then
			Comms_Last_Fight = Comms_Last_Fight + comms_gained
		end

		data.numbers.comms_all_time = data.numbers.comms_all_time + comms_gained
		data.numbers.comms_current_day = data.numbers.comms_current_day + comms_gained
		data.numbers.comms_current_month = data.numbers.comms_current_month + comms_gained
		data.numbers.recent_comms[now] = (data.numbers.recent_comms[now] or 0) + comms_gained

		if data.numbers.comms_current_day > data.numbers.most_comms_a_day[1] then
			data.numbers.most_comms_a_day = { data.numbers.comms_current_day, current_date.Day, current_date.Month, current_date.Year }
		end

		if data.numbers.comms_current_month > data.numbers.most_comms_a_month[1] then
			data.numbers.most_comms_a_month = { data.numbers.comms_current_month, current_date.Month, current_date.Year }
		end

		OverviewWindow:Update()

		Plugins["PvMP+"].Unload(nil, nil, false)

	elseif args.ChatType == Turbine.ChatType.Death then
		-- Parse Frags
		if string.find(args.Message, L.Chat_KillingBlow_Start) and string.find(args.Message, L.Chat_KillingBlow_End) then
			local current_date = Turbine.Engine.GetDate()
			local now = GetSecondsOfYear()
			local victim = string.match(args.Message, L.Chat_KillingBlow_Start .. "(.+)" .. L.Chat_KillingBlow_End)
			local taunt_index = math.random(#L.YourFrag_Message_Taunt)

			if not storage.yourfrag_alert_disabled then
				AlertWindow:NewAlert(L.YourFrag_Message_Start .. victim .. L.YourFrag_Message_End .. L.YourFrag_Message_Taunt[taunt_index] .. "!", Turbine.UI.Color.Lime, 3)
			end

			if New_Fight_3 then
				New_Fight_3 = false
				Frags_Last_Fight = 0
			end

			if (Local_Player:IsInCombat() or Local_Player:GetMorale() == nil) then
				Frags_Last_Fight = Frags_Last_Fight + 1
			end

			data.numbers.frags[victim] = (data.numbers.frags[victim] or 0) + 1
			if (not string.find(victim, "%~")) then
				data.numbers.frags_current_day = data.numbers.frags_current_day + 1
				data.numbers.frags_current_month = data.numbers.frags_current_month + 1
				data.numbers.recent_frags[now] = (data.numbers.recent_frags[now] or 0) + 1
				data.numbers.frags_total = data.numbers.frags_total + 1
			end

			if data.numbers.frags_current_day > data.numbers.most_frags_a_day[1] then
				data.numbers.most_frags_a_day = { data.numbers.frags_current_day, current_date.Day, current_date.Month, current_date.Year }
			end

			if data.numbers.frags_current_month > data.numbers.most_frags_a_month[1] then
				data.numbers.most_frags_a_month = { data.numbers.frags_current_month, current_date.Month, current_date.Year }
			end

			OverviewWindow:Update()

			SecondaryWindow:NewRecentKill(victim)

			Plugins["PvMP+"].Unload(nil, nil, false)

		-- Parse Deaths
		elseif string.find(args.Message, L.Chat_Defeated) or string.find(args.Message, L.Chat_Environment_Death) then
			local current_date = Turbine.Engine.GetDate()
			local now = GetSecondsOfYear()

			data.numbers.deaths_current_day = data.numbers.deaths_current_day + 1
			data.numbers.deaths_current_month = data.numbers.deaths_current_month + 1
			data.numbers.recent_deaths[now] = (data.numbers.recent_deaths[now] or 0) + 1

			if data.numbers.deaths_current_day > data.numbers.most_deaths_a_day[1] then
				data.numbers.most_deaths_a_day = { data.numbers.deaths_current_day, current_date.Day, current_date.Month, current_date.Year }
			end

			if data.numbers.deaths_current_month > data.numbers.most_deaths_a_month[1] then
				data.numbers.most_deaths_a_month = { data.numbers.deaths_current_month, current_date.Month, current_date.Year }
			end

			Plugins["PvMP+"].Unload(nil, nil, false)
		end

	-- Parse Lootboxes
	elseif (args.ChatType == Turbine.ChatType.SelfLoot or args.ChatType == Turbine.ChatType.FellowLoot) and (string.find(args.Message, L.Chat_Lootbox) or string.find(args.Message, L.Chat_Key) or string.find(args.Message, L.Chat_Appearance)) and not storage.lootbox_alert_disabled then
		local message = string.gsub(args.Message, "<.+>(%[.+])<.+>", "%1")
		AlertWindow:NewAlert(message, Bar_Chart_Color, 5)

	-- Parse Stealth messages and create Alert
	elseif args.ChatType == Turbine.ChatType.Regional and not storage.stealth_alert_disabled then
		if string.find(args.Message, L.Chat_Stealth_Nearby) then
			AlertWindow:NewAlert(L.Alert_Stealth_Nearby or L.Chat_Stealth_Nearby, Turbine.UI.Color.Cyan, 3)
		elseif string.find(args.Message, L.Chat_Stealth_Spotted) then
			AlertWindow:NewAlert(L.Alert_Stealth_Spotted or L.Chat_Stealth_Spotted, Turbine.UI.Color.Cyan, 3)
		end

	-- Parse Hit List
	elseif args.ChatType == Turbine.ChatType.EnemyCombat and (string.find(args.Message, L.Chat_Damage_Hit) or string.find(args.Message, L.Chat_Damage_Avoid)) then
		local npc = false
		local enemy = nil

		-- Hit by an enemy and retrieve their name
		if string.find(args.Message, L.Chat_Damage_Hit) then
			enemy = string.match(args.Message, "(.+)" .. L.Chat_Damage_Hit)
		elseif string.find(args.Message, L.Chat_Damage_Avoid) then
			enemy = string.match(args.Message, "(.+)" .. L.Chat_Damage_Avoid)
		end

		local npc = IsEnemyNPC(enemy)

		-- Dont track NPC hits
		if not npc then
			if Recent_Hits_Reset then
				Recent_Hits_Reset = false
				Recent_Hits_List = {}
				Recent_Hits_Counter = 0
				RecentHitsWindow:ClearHitList()
			end
			if Recent_Hits_List[enemy] == nil then
				RecentHitsWindow:NewRecentHit(enemy)
			end
		end

	-- Parse Tracks and Map Position
	elseif args.ChatType == Turbine.ChatType.Standard then
		-- Parse Tracks
		if string.find(args.Message, L.Chat_Tracked) then
			local current_date = Turbine.Engine.GetDate()
			local now = GetSecondsOfYear()

			if not storage.track_warning_disabled then
				AlertWindow:NewAlert(L.Alert_Tracked or L.Chat_Tracked, Turbine.UI.Color.Red, 2)
			end

			data.numbers.tracks_current_day = data.numbers.tracks_current_day + 1
			data.numbers.tracks_current_month = data.numbers.tracks_current_month + 1
			data.numbers.recent_tracks[now] = (data.numbers.recent_tracks[now] or 0) + 1
			data.numbers.tracks_total = data.numbers.tracks_total + 1

			if data.numbers.tracks_current_day > data.numbers.most_tracks_a_day[1] then
				data.numbers.most_tracks_a_day = { data.numbers.tracks_current_day, current_date.Day, current_date.Month, current_date.Year }
			end

			if data.numbers.tracks_current_month > data.numbers.most_tracks_a_month[1] then
				data.numbers.most_tracks_a_month = { data.numbers.tracks_current_month, current_date.Month, current_date.Year }
			end

			Plugins["PvMP+"].Unload(nil, nil, false)

		-- Parse Own Map Position
		elseif string.find(args.Message, L.Chat_Location_String) then
			local region, lx, ly, ox, oy, oz, heading, i
			if string.find(args.Message, L.Chat_Heading_String) == nil then
				heading = 0
				region, lx, ly, ox, oy, oz = string.match(args.Message, L.Chat_Pattern_String_1)
				if region == nil then
					region, lx, ly, ox, oy, oz, heading = string.match(args.Message, L.Chat_Pattern_String_2)
					if region == nil then
						region, lx, ly, i, ox, oy, oz, heading = string.match(args.Message, L.Chat_Pattern_String_3)
						if region == nil then
							region, lx, ly, i, ox, oy, oz, heading = string.match(args.Message, L.Chat_Pattern_String_4)
						end
					end
				end
			else
				region, lx, ly, ox, oy, oz, heading = string.match(args.Message, L.Chat_Pattern_String_1 .. " h(%d+%.?%d*)")
				if region == nil then
					region, lx, ly, ox, oy, oz, heading = string.match(args.Message, L.Chat_Pattern_String_2 .. " h(%d+%.?%d*)")
					if region == nil then
						region, lx, ly, i, ox, oy, oz, heading = string.match(args.Message, L.Chat_Pattern_String_3 .. " h(%d+%.?%d*)")
						if region == nil then
							region, lx, ly, i, ox, oy, oz, heading = string.match(args.Message, L.Chat_Pattern_String_4 .. " h(%d+%.?%d*).*")
						end
					end
				end
			end
			if region ~= nil then
				if heading == nil then
					heading = 0
				end
			if tonumber(ox) == nil then
				ox		= tonumber((string.gsub(ox, "%.", ",")))
				oy		= tonumber((string.gsub(oy, "%.", ",")))
				oz		= tonumber((string.gsub(oz, "%.", ",")))
				heading	= tonumber((string.gsub(heading, "%.", ",")))
			end
			local ew, ns = ((math.floor(lx / 8) * 160 + ox) - 29360) / -200, ((math.floor(ly / 8) * 160 + oy) - 24880) / -200
			MapWindow:MoveCurrentPosition(ew, ns, heading)
			SecondaryWindow:DisplayChatData(ew, ns)
			end

		-- Join Room
		elseif string.find(args.Message, L.Chat_Room_Join) then
			local roomName = string.match(args.Message, L.Chat_Room_Join)
			for i = 1, 8 do
				if Used_User_Channels[i] == nil then
					OverviewSettingsPanel:AddChatChannel(roomName, true)
					SecondaryWindow:AddChatChannel(roomName, true)
					RecentHitsWindow:AddChatChannel(roomName, true)
					Used_User_Channels[i] = string.lower(roomName)
					break
				end
			end
		end

	-- Parse Callout Map Position
	elseif string.find(args.Message, Enemy_Position_Pattern) then
		local player, amount, s, w = string.match(args.Message, Enemy_Position_Pattern)
		if amount == "" then amount = "?" end
		if tonumber(w) == nil then
			w = tonumber((string.gsub(w,"%.",",")))
			s = tonumber((string.gsub(s,"%.",",")))
		end
	MapWindow:AddEnemyPosition(w, s, amount, string.sub(player, 32, string.len(player) - 9))

	-- Leave Room
	elseif (args.ChatType == Turbine.ChatType.UserChat1 or args.ChatType == Turbine.ChatType.UserChat2 or
			args.ChatType == Turbine.ChatType.UserChat3 or args.ChatType == Turbine.ChatType.UserChat4 or
			args.ChatType == Turbine.ChatType.UserChat5 or args.ChatType == Turbine.ChatType.UserChat6 or
			args.ChatType == Turbine.ChatType.UserChat7 or args.ChatType == Turbine.ChatType.UserChat8) and
			string.find(args.Message, L.Chat_Room_Leave) then
		local roomName = string.match(args.Message, L.Chat_Room_Leave)
		OverviewSettingsPanel:RemoveChatChannel(roomName)
		SecondaryWindow:RemoveChatChannel(roomName)
		RecentHitsWindow:RemoveChatChannel(roomName)

	elseif args.ChatType == Turbine.ChatType.EventBroadcast then
		-- Track EventBroadcast
	end
end

local parse_error_shown = false
Turbine.Chat.Received = function(sender, args)
	if args == nil or type(args.Message) ~= "string" then
		return
	end
	if PvMP_BossCheck ~= nil then
		pcall(PvMP_BossCheck, args)
	end
	if PvMP_SiegeCheck ~= nil then
		pcall(PvMP_SiegeCheck, args)
	end
	local ok, err = pcall(ParseChat, sender, args)
	if not ok and not parse_error_shown then
		parse_error_shown = true
		Turbine.Shell.WriteLine("PvMP+: " .. tostring(err))
	end
end
function IsEnemyNPC(enemy)
	if Turbine.Engine:GetLanguage() ~= Turbine.Language.German and string.find(enemy, " ") or string.find(enemy, "%a+%u+") or string.find(enemy, "%-%a+") or string.find(enemy, "%'%a+") or string.find(enemy, "[ÀÁÂÄÈÉÊËÌÍÎÏÒÓÔÖÙÚÛÜàáâäèéêëìíîïòóôöùúûü]") or not string.find(enemy, "%u") then
		return true
	elseif Turbine.Engine:GetLanguage() == Turbine.Language.German then
		enemy = string.sub(enemy, 5)
		if string.find(enemy, " ") then
			return true
		end
	else
		for i = 1, #NPC_Names do
			if string.find(enemy, NPC_Names[i]) then
				return true
			end
		end
	end
end