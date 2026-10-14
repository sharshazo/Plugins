LoadData = function()
	SetGlobals()
	if storage == nil then
		_G.storage = {["numbers"] = {}}
	else
		_G.Data_Loaded = true
		data.numbers = ConvertStringsToNumbers(storage.numbers)
	end
	SetDefaults()
	data.numbers.overview_width_ratio = data.numbers.overview_width_ratio / 1e+14
end

SetGlobals = function()
	if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
		_G.Rank_Icons = {
			[0] = nil,
			[1] = 0x410080b7,
			[2] = 0x410080b8,
			[3] = 0x410080b9,
			[4] = 0x410080ba,
			[5] = 0x410080bb,
			[6] = 0x410080bc,
			[7] = 0x410080bd,
			[8] = 0x410080be,
			[9] = 0x410080b0,
			[10] = 0x410080b1,
			[11] = 0x410080b2,
			[12] = 0x410080b3,
			[13] = 0x410080b4,
			[14] = 0x410080b5,
			[15] = 0x410080b6
		}
		_G.Aligned_Color = Turbine.UI.Color(177 / 255, 22 / 255, 47 / 255)
		_G.Enemy_Color = Turbine.UI.Color(60 / 255, 86 / 255, 216 / 255)
		_G.Aligned_Keep_Icon = 0x4100819c
		_G.Enemy_Keep_Icon = 0x4100819b
		_G.Bar_Builder = {
			[0] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Red/bar_empty.tga",
			[1] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Red/bar_filled.tga",
			[2] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Red/bar_left.tga",
			[3] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Red/bar_right.tga",
			[4] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Red/bar_middle.tga"
		}
	elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
		_G.Rank_Icons = {
			[0] = nil,
			[1] = 0x410080a8,
			[2] = 0x410080a9,
			[3] = 0x410080aa,
			[4] = 0x410080ab,
			[5] = 0x410080ac,
			[6] = 0x410080ad,
			[7] = 0x410080ae,
			[8] = 0x410080af,
			[9] = 0x410080a1,
			[10] = 0x410080a2,
			[11] = 0x410080a3,
			[12] = 0x410080a4,
			[13] = 0x410080a5,
			[14] = 0x410080a6,
			[15] = 0x410080a7
		}
		_G.Aligned_Color = Turbine.UI.Color(60 / 255, 86 / 255, 216 / 255)
		_G.Enemy_Color = Turbine.UI.Color(177 / 255, 22 / 255, 47 / 255)
		_G.Aligned_Keep_Icon = 0x4100819b
		_G.Enemy_Keep_Icon = 0x4100819c
		_G.Bar_Builder = {
			[0] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Blue/bar_empty.tga",
			[1] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Blue/bar_filled.tga",
			[2] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Blue/bar_left.tga",
			[3] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Blue/bar_right.tga",
			[4] = "PvMP_Plus_Revisited/PvMP_Plus/Resources/ProgressBar/Blue/bar_middle.tga"
		}
	end

	_G.Ranks = {
		[0] = 0,
		[1] = 500,
		[2] = 1250,
		[3] = 2750,
		[4] = 5750,
		[5] = 14750,
		[6] = 33500,
		[7] = 71000,
		[8] = 146000,
		[9] = 258500,
		[10] = 408500,
		[11] = 633500,
		[12] = 1008500,
		[13] = 1608500,
		[14] = 2508500,
		[15] = 3708500
	}

	_G.Tiers = {
		[0] = 0,
		[1] = 10,
		[2] = 510,
		[3] = 3010,
		[4] = 8010,
		[5] = 20510,
		[6] = 45510,
		[7] = 95510,
		[8] = 195510
	}

	_G.Buff_List = nil
	_G.Minimal_Width = 240
	_G.New_Fight_1 = false
	_G.New_Fight_2 = false
	_G.New_Fight_3 = false
	_G.Recent_Hits_Counter = 0
	_G.Recent_Hits_Reset = false
	_G.Points_Last_Fight = 0
	_G.Comms_Last_Fight = 0
	_G.Frags_Last_Fight = 0
	_G.Current_Commendations = 0
	_G.Alert_Counter = 0
	_G.Current_Position_Counter = 0
	_G.Enemy_Position_Counter = 60
	_G.Default_Font_Color = Turbine.UI.Color(245 / 255, 222 / 255, 147 / 255)
	_G.Yellow_Font_Color = Turbine.UI.Color(244 / 255, 255 / 255, 51 / 255)
	_G.Grey_Font_Color = Turbine.UI.Color(48 / 255, 48 / 255, 48 / 255)
	_G.Bar_Chart_Color = Turbine.UI.Color(216 / 255, 165 / 255, 31 / 255)
	_G.Days_To_Display = 31
	_G.Months_To_Display = 12
	_G.Enemy_Position_Chat_Color = "#FF4500"
	_G.Recent_Hits_Chat_Color = "#FFD700"
	_G.Enemy_Position_Pattern = "%[.+] (.+): '?<rgb=" .. Enemy_Position_Chat_Color .. ">(%d*) ?.+ @ .+: .+: (%d+%.%d)S, (%d+%.%d)W</rgb>'?"
	_G.Used_User_Channels = { [1] = nil, [2] = nil, [3] = nil, [4] = nil, [5] = nil, [6] = nil, [7] = nil, [8] = nil }
	_G.Last_Commendations = tonumber(Turbine.PluginData.Load(Turbine.DataScope.Server, "PvMP_Plus")) or 0
	_G.Commendation_Limit = 19000
	_G.Commendation_Warning = Last_Commendations >= Commendation_Limit
	_G.Data_Loaded = false
	_G.storage = Turbine.PluginData.Load(Turbine.DataScope.Character, "PvMP_Plus")
	_G.data = {["numbers"] = {}}
	_G.Recent_Hits_List = {}
	_G.Reversed_Recent_Hits_List = {}
end

SetDefaults = function()
	if storage.last5kills == nil then storage.last5kills = {} end
	if data.numbers.frags == nil then data.numbers.frags = {} end

	if data.numbers.recent_points == nil then data.numbers.recent_points = {} end
	if data.numbers.recent_tracks == nil then data.numbers.recent_tracks = {} end
	if data.numbers.recent_frags == nil then data.numbers.recent_frags = {} end
	if data.numbers.recent_comms == nil then data.numbers.recent_comms = {} end
	if data.numbers.recent_deaths == nil then data.numbers.recent_deaths = {} end

	if data.numbers.history == nil then data.numbers.history = {} end
	if data.numbers.history.points == nil then data.numbers.history.points = {} end
	if data.numbers.history.frags == nil then data.numbers.history.frags = {} end
	if data.numbers.history.comms == nil then data.numbers.history.comms = {} end
	if data.numbers.history.tracks == nil then data.numbers.history.tracks = {} end
	if data.numbers.history.deaths == nil then data.numbers.history.deaths = {} end

	if data.numbers.history.pointsMonth == nil then data.numbers.history.pointsMonth = {} end
	if data.numbers.history.fragsMonth == nil then data.numbers.history.fragsMonth = {} end
	if data.numbers.history.commsMonth == nil then data.numbers.history.commsMonth = {} end
	if data.numbers.history.tracksMonth == nil then data.numbers.history.tracksMonth = {} end
	if data.numbers.history.deathsMonth == nil then data.numbers.history.deathsMonth = {} end

	if data.numbers.current_day == nil then data.numbers.current_day = Turbine.Engine.GetDate().DayOfYear end
	if data.numbers.current_month == nil then data.numbers.current_month = Turbine.Engine.GetDate().Month end

	if data.numbers.comms_all_time == nil then data.numbers.comms_all_time = 0 end

	if data.numbers.most_points_a_fight == nil then data.numbers.most_points_a_fight = {0, 1, 1, 1970} end

	if data.numbers.points_current_day == nil then data.numbers.points_current_day = 0 end
	if data.numbers.frags_current_day == nil then data.numbers.frags_current_day = 0 end
	if data.numbers.tracks_current_day == nil then data.numbers.tracks_current_day = 0 end
	if data.numbers.comms_current_day == nil then data.numbers.comms_current_day = 0 end
	if data.numbers.deaths_current_day == nil then data.numbers.deaths_current_day = 0 end

	if data.numbers.points_current_month == nil then data.numbers.points_current_month = 0 end
	if data.numbers.frags_current_month == nil then data.numbers.frags_current_month = 0 end
	if data.numbers.tracks_current_month == nil then data.numbers.tracks_current_month = 0 end
	if data.numbers.comms_current_month == nil then data.numbers.comms_current_month = 0 end
	if data.numbers.deaths_current_month == nil then data.numbers.deaths_current_month = 0 end

	if data.numbers.most_points_a_day == nil then data.numbers.most_points_a_day = {0, 1, 1, 1970} end
	if data.numbers.most_frags_a_day == nil then data.numbers.most_frags_a_day = {0, 1, 1, 1970} end
	if data.numbers.most_comms_a_day == nil then data.numbers.most_comms_a_day = {0, 1, 1, 1970} end
	if data.numbers.most_tracks_a_day == nil then data.numbers.most_tracks_a_day = {0, 1, 1, 1970} end
	if data.numbers.most_deaths_a_day == nil then data.numbers.most_deaths_a_day = {0, 1, 1, 1970} end

	if data.numbers.most_points_a_month == nil then data.numbers.most_points_a_month = {0, 1, 1970} end
	if data.numbers.most_frags_a_month == nil then data.numbers.most_frags_a_month = {0, 1, 1970} end
	if data.numbers.most_comms_a_month == nil then data.numbers.most_comms_a_month = {0, 1, 1970} end
	if data.numbers.most_tracks_a_month == nil then data.numbers.most_tracks_a_month = {0, 1, 1970} end
	if data.numbers.most_deaths_a_month == nil then data.numbers.most_deaths_a_month = {0, 1, 1970} end

	if data.numbers.points_total == nil then data.numbers.points_total = 0 end
	if data.numbers.frags_total == nil then data.numbers.frags_total = 0 end
	if data.numbers.tracks_total == nil then data.numbers.tracks_total = 0 end

	if data.numbers.selectedChannel == nil then data.numbers.selectedChannel = 5 end
	if data.numbers.selectedChannel2 == nil then data.numbers.selectedChannel2 = 5 end
	if data.numbers.selectedChannel3 == nil then data.numbers.selectedChannel3 = 5 end

	if storage.link_counts_disabled == nil then storage.link_counts_disabled = false end

	if storage.show_dof_disabled == nil then storage.show_dof_disabled = true end
	if storage.lootbox_alert_disabled == nil then storage.lootbox_alert_disabled = true end
	if storage.battletask_warning_disabled == nil then storage.battletask_warning_disabled = true end

	if data.numbers.resettime == nil then data.numbers.resettime = 0 end
	if data.numbers.overview_width_ratio == nil then data.numbers.overview_width_ratio = 30000000000000 end
	local fixed_ratio = data.numbers.overview_width_ratio / 100000000000000

	local display_width = Turbine.UI.Display.GetWidth()
	local display_height = Turbine.UI.Display.GetHeight()

	if data.numbers.overview_x == nil then data.numbers.overview_x = math.floor(display_width / 2 - (Minimal_Width + (display_width - Minimal_Width) * fixed_ratio) / 2) end
	if data.numbers.overview_y == nil then data.numbers.overview_y = 0 end
	if data.numbers.alert_x == nil then data.numbers.alert_x = math.floor(display_width / 2 - 275) end
	if data.numbers.alert_y == nil then data.numbers.alert_y = math.floor(display_height / 4) end
	if data.numbers.battle_task_x == nil then data.numbers.battle_task_x = math.floor(display_width / 2 - 275) end
	if data.numbers.battle_task_y == nil then data.numbers.battle_task_y = math.floor(display_height / 8) end
	if data.numbers.secondaryWin_x == nil then data.numbers.secondaryWin_x = math.floor(display_width - 150) end
	if data.numbers.secondaryWin_y == nil then data.numbers.secondaryWin_y = math.floor(display_height / 2 - 88) end
	if data.numbers.hitWin_x == nil then data.numbers.hitWin_x = math.floor(display_width - 120) end
	if data.numbers.hitWin_y == nil then data.numbers.hitWin_y = math.floor(display_height / 2 - 320) end
	if data.numbers.settingsWin_x == nil then data.numbers.settingsWin_x = math.floor(display_width / 2 - 185) end
	if data.numbers.settingsWin_y == nil then data.numbers.settingsWin_y = math.floor(display_height / 2 - 240) end
	if data.numbers.statsWin_x == nil then data.numbers.statsWin_x = math.floor(display_width / 2 - 150) end
	if data.numbers.statsWin_y == nil then data.numbers.statsWin_y = math.floor(display_height / 2 - 265) end
	if data.numbers.mapWin_x == nil then data.numbers.mapWin_x = math.floor(display_width / 2 - 300) end
	if data.numbers.mapWin_y == nil then data.numbers.mapWin_y = math.floor(display_height / 2 - 230) end
end

Plugins["PvMP+"].Unload = function(self, args, isDailyBackup)
	data.numbers.overview_width_ratio = data.numbers.overview_width_ratio * 1e+14
	-- Only save points from the last 24 hours
	data.numbers.recent_points = DeleteObsoleteData(data.numbers.recent_points)
	data.numbers.recent_tracks = DeleteObsoleteData(data.numbers.recent_tracks)
	data.numbers.recent_frags = DeleteObsoleteData(data.numbers.recent_frags)
	data.numbers.recent_comms = DeleteObsoleteData(data.numbers.recent_comms)
	data.numbers.recent_deaths = DeleteObsoleteData(data.numbers.recent_deaths)
	-- Only save history data from the last 31 days
	data.numbers.history.points = DeleteOldHistoryData(data.numbers.history.points, Days_To_Display)
	data.numbers.history.frags = DeleteOldHistoryData(data.numbers.history.frags, Days_To_Display)
	data.numbers.history.comms = DeleteOldHistoryData(data.numbers.history.comms, Days_To_Display)
	data.numbers.history.tracks = DeleteOldHistoryData(data.numbers.history.tracks, Days_To_Display)
	data.numbers.history.deaths = DeleteOldHistoryData(data.numbers.history.deaths, Days_To_Display)
	-- Convert data into strings
	storage.numbers = ConvertNumbersToStrings(data.numbers)
	if isDailyBackup then
		Turbine.PluginData.Save(Turbine.DataScope.Character, "PvMP_Plus_Daily_Backup", storage)
	else
		Turbine.PluginData.Save(Turbine.DataScope.Server, "PvMP_Plus", tostring(Current_Commendations))
		Turbine.PluginData.Save(Turbine.DataScope.Character, "PvMP_Plus", storage)
		Turbine.PluginData.Save(Turbine.DataScope.Character, "PvMP_Plus_Backup", storage)
	end
	data.numbers.overview_width_ratio = data.numbers.overview_width_ratio / 1e+14
end

function ConvertStringsToNumbers(data)
	local temp = {}
	for i, j in pairs(data) do
		if type(j) == "table" then
			temp[i] = ConvertStringsToNumbers(j)
		elseif type(j) == "string" then
			local test = tonumber(i)
			if test == nil then
				temp[i] = tonumber(j)
			else
				temp[tonumber(i)] = tonumber(j)
			end
		end
	end
	return temp
end

function ConvertNumbersToStrings(input)
	local temp = {}
	for i, j in pairs(input) do
		if type(j) == "table" then
			temp[i] = ConvertNumbersToStrings(j)
		elseif type(j) == "number" then
			temp[tostring(i)] = tostring(j)
		end
	end
	return temp
end

function DeleteObsoleteData(input)
	local important_data = {}
	local now = GetSecondsOfYear()
	for timestamp, value in pairs(input) do
		if (now - timestamp <= 86400 and now - timestamp >= 0) then
			important_data[timestamp] = value
		end
	end
	return important_data
end

function DeleteOldHistoryData(data, days)
	local important_data = {}
	local current_date = Turbine.Engine.GetDate()
	local current_day = current_date.DayOfYear
	for i = 0, days - 1 do
		local day = current_day - i
		if day < 1 then
			day = GetDaysPerYear(current_date.Year - 1) + day
		end
		if not (data[day] == nil) then
			important_data[day] = data[day]
		end
	end
	return important_data
end