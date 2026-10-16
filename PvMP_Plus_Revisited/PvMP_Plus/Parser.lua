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
	-- v4.3.9: lee la posicion de cualquier llamada de enemigos (con ;loc o
	-- con el boton Pos) y la marca en el mapa
	elseif ParseEnemyCallout(args.Message) then
		-- marcado en el mapa

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
	-- v4.3.15: en el canal Regional la rama de sigilo tapaba las llamadas
	if args.ChatType == Turbine.ChatType.Regional and ParseEnemyCallout ~= nil then
		pcall(ParseEnemyCallout, args.Message)
	end
	local ok, err = pcall(ParseChat, sender, args)
	if not ok and not parse_error_shown then
		parse_error_shown = true
		Turbine.Shell.WriteLine("PvMP+: " .. tostring(err))
	end
	-- v4.3.14: rachas y nemesis (despues, para que su aviso tape al de la baja)
	if PvMP_RivalsCheck ~= nil then
		pcall(PvMP_RivalsCheck, args)
	end
end
-- v4.3.10: llamadas de enemigos de versiones anteriores de PvMP+ (sin
-- coordenadas): se situan con el lugar y la distancia/direccion del mensaje.
local CALLOUT_POIS = {
	[1] = { 16.6, 17.3 },
	[2] = { 11.7, 15.3 },
	[3] = { 17.6, 14.5 },
	[4] = { 15.3, 20.0 },
	[5] = { 19.3, 17.5 },
	[6] = { 19.9, 19.3 },
	[7] = { 13.4, 14.6 },
	[8] = { 18.4, 20.1 },
	[9] = { 14.5, 16.2 },
	[10] = { 12.2, 20.9 },
	[11] = { 17.0, 22.4 },
	[12] = { 17.0, 18.6 },
	[13] = { 13.0, 12.7 },
	[14] = { 16.1, 21.0 },
	[15] = { 19.0, 18.6 },
	[16] = { 20.7, 13.6 },
	[17] = { 16.0, 12.2 },
	[18] = { 18.0, 16.7 },
	[19] = { 19.8, 20.0 },
	[20] = { 12.51, 16.61 },
	[21] = { 17.14, 13.75 },
	[22] = { 17.40, 16.74 },
	[23] = { 16.49, 18.20 },
}
local CALLOUT_PLACES = {
	["Tol Ascarnen"] = 1,
	["Тол Аскарнен"] = 1,
	["Isenbinge-Mine"] = 2,
	["Isendeep Mine"] = 2,
	["Mine du Gouffre d'Isen"] = 2,
	["Изендипский рудник"] = 2,
	["Tírith Rhaw"] = 3,
	["Тирит Роу"] = 3,
	["Lugazag"] = 4,
	["Лугазаг"] = 4,
	["Camp de bûcherons du Bois Funeste"] = 5,
	["Grimwood Lumber Camp"] = 5,
	["Holzfällerlager im Grimmwald"] = 5,
	["Лесопилка Мрачного леса"] = 5,
	["Avant-poste des Monts Froids"] = 6,
	["Hithlad Outpost"] = 6,
	["Kaltfelsen-Außenposten"] = 6,
	["Застава в Хитладе"] = 6,
	["Arador's End Outpost"] = 7,
	["Außenposten in Aradors Ende"] = 7,
	["Avant-poste de la Muraille d'Arador"] = 7,
	["Застава в Арадорском тупике"] = 7,
	["Außenposten am Fluss"] = 8,
	["Avant-poste de la rivière"] = 8,
	["River Outpost"] = 8,
	["Застава на реке"] = 8,
	["Außenposten der Isenbinge"] = 9,
	["Avant-poste du Gouffre d'Isen"] = 9,
	["Isendeep Outpost"] = 9,
	["Застава в Изендипском руднике"] = 9,
	["Gramfuß"] = 10,
	["Gramsfoot"] = 10,
	["Pied de Gram"] = 10,
	["Подножие Грэм"] = 10,
	["Dâr-gazag"] = 11,
	["Дар-Газаг"] = 11,
	["Camp d'Orques"] = 12,
	["Orc Camp"] = 12,
	["Ork-Lager"] = 12,
	["Орочий лагерь"] = 12,
	["Grothum"] = 13,
	["Гротум"] = 13,
	["Mazauk's Den"] = 14,
	["Mazauk's Versteck"] = 14,
	["Repaire de Mazauk"] = 14,
	["Repaire d'Araignées"] = 15,
	["Spider Den"] = 15,
	["Spinne Versteck"] = 15,
	["Glân Vraig"] = 16,
	["Глан Врайг"] = 16,
	["Feste Ringdyr"] = 17,
	["Ost Ringdyr"] = 17,
	["Ост Рингдир"] = 17,
	["Camp d'Elfes"] = 18,
	["Elben-Lager"] = 18,
	["Elf Camp"] = 18,
	["Эльфийский лагерь"] = 18,
	["Hoarhallow"] = 19,
	["Sacregris"] = 19,
	["Weißsenke"] = 19,
	["Седая котловина"] = 19,
	["Golloval"] = 20,
	["Goldhead"] = 21,
	["Goldschopf"] = 21,
	["Têtedor"] = 21,
	["STAB"] = 22,
	["WTAB"] = 23,
}
local CALLOUT_DIRS = { N = 1, NE = 2, E = 3, SE = 4, S = 5, SW = 6, SO = 6, W = 7, O = 7, NW = 8, NO = 8,
	["С"] = 1, ["СВ"] = 2, ["В"] = 3, ["ЮВ"] = 4, ["Ю"] = 5, ["ЮЗ"] = 6, ["З"] = 7, ["СЗ"] = 8 }

-- posicion aproximada a partir de "@ Lugar" o "120m N Lugar"
local function CalloutFromPlace(body)
	local text = string.gsub(body, "</rgb>.*$", "")
	text = string.gsub(text, "['%s]+$", "")
	if string.find(text, " in Delving", 1, true) then
		return nil
	end
	local meters, dir
	local place = string.match(text, " @ (.+)$")
	if place == nil then
		meters, dir, place = string.match(text, " (%d+)m (%S+) (.+)$")
	end
	local idx = place ~= nil and CALLOUT_PLACES[place] or nil
	if idx == nil then
		return nil
	end
	local south, west = CALLOUT_POIS[idx][1], CALLOUT_POIS[idx][2]
	if meters ~= nil then
		local k = CALLOUT_DIRS[dir]
		if k == nil then
			return nil
		end
		local d = tonumber(meters) / 180
		local a = math.rad((k - 1) * 45)
		west = west - d * math.sin(a)
		south = south - d * math.cos(a)
	end
	return south, west
end

local function ToCoord(v)
	return tonumber(v) or tonumber((string.gsub(v, "%.", ","))) or tonumber((string.gsub(v, ",", ".")))
end

-- v4.3.15: tambien se leen las llamadas de otras versiones del addon (otro
-- color en la etiqueta <rgb=...>) y las escritas a mano con "@" y
-- coordenadas ("9 Creeps @ Eriador: Tirith Rhaw: 17.5S, 14.7W"). Solo se
-- marcan coordenadas que caen dentro del mapa de las Landas de Etten.
local CALLOUT_MIN_S, CALLOUT_MAX_S = 10, 22
local CALLOUT_MIN_W, CALLOUT_MAX_W = 8.2, 24.3

local function InsideMap(south, west)
	return south ~= nil and west ~= nil and south >= CALLOUT_MIN_S and south <= CALLOUT_MAX_S and
		west >= CALLOUT_MIN_W and west <= CALLOUT_MAX_W
end

function ParseEnemyCallout(message)
	if type(message) ~= "string" then
		return false
	end
	-- texto despues de "[Canal] Nombre: "
	local raw = string.match(message, "^%[[^%]]*%] (.-): ")
	local body
	local tag = "<rgb=" .. Enemy_Position_Chat_Color .. ">"
	local i = string.find(message, tag, 1, true)
	if i ~= nil then
		body = string.sub(message, i + string.len(tag))
	else
		-- otra version del addon: cualquier color
		local j, k = string.find(message, "<rgb=#%x%x%x%x%x%x>")
		if j ~= nil and raw ~= nil then
			body = string.sub(message, k + 1)
		elseif raw ~= nil and string.find(message, " @ ", 1, true) then
			-- escrita a mano: lo que dijo el jugador
			body = string.match(message, "^%[[^%]]*%] .-: (.*)$")
		end
	end
	if body == nil then
		return false
	end
	body = string.gsub(body, "^['%s]+", "")
	-- v4.3.15: todas las coordenadas del mensaje (pueden venir varias)
	local points = {}
	for cs, cw in string.gmatch(body, "(%d+[%.,]%d+)%s*S,?%s*(%d+[%.,]%d+)%s*W") do
		local south, west = ToCoord(cs), ToCoord(cw)
		if InsideMap(south, west) and #points < 6 then
			points[#points + 1] = { south, west }
		end
	end
	if #points == 0 and (i ~= nil or string.find(message, "<rgb=#%x%x%x%x%x%x>")) and
		string.find(body, "%d+[%.,]%d+%s*S") == nil then
		-- version anterior: sin coordenadas, se calcula desde el lugar
		local south, west = CalloutFromPlace(body)
		if InsideMap(south, west) then
			points[1] = { south, west }
		end
	end
	if #points == 0 then
		return false
	end
	local amount = string.match(body, "^(%d*)") or ""
	if amount == "" then
		amount = "?"
	end
	local player = "?"
	if raw ~= nil then
		player = string.match(raw, ">([^<>]+)<") or (string.gsub(raw, "<[^>]*>", ""))
	end
	for n = 1, #points do
		MapWindow:AddEnemyPosition(points[n][2], points[n][1], amount, player)
	end
	return true
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