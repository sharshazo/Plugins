Updater = Turbine.UI.Control()
Updater:SetWantsUpdates(true)

_G.Local_Player = Turbine.Gameplay.LocalPlayer.GetInstance()

local timestamp = Turbine.Engine.GetGameTime()
local currentsecond = nil
local oldsecond = nil

local commendations_in_wallet = nil

local currentResolution = Turbine.UI.Display.GetWidth()
local oldResolution = nil

local wallet_loaded = false
local buffs_loaded = false

Updater.Update = function(sender, args)
	currentsecond = Turbine.Engine.GetDate().Second

	if Commendation_Warning and not storage.comms_warning_disabled then
		Updater.CommendationFlashing()
	end

	if oldsecond ~= currentsecond then
		oldsecond = currentsecond

		for player, control in pairs(MapWindow.enemy_position_list) do
			control.Timer = control.Timer - 1
			if control.Timer % 2 == 0 then
				control:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/MapIcons/enemy_position_overlay_empty.tga")
			else
				control:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/MapIcons/enemy_position_overlay.tga")
			end

			if control.Timer == 0 then control:SetVisible(false) end
		end

		if Current_Position_Counter > 0 then
			Current_Position_Counter = Current_Position_Counter - 1
		else
			MapWindow.map_position_arrow:SetVisible(false)
		end

		if Alert_Counter > 0 then
			AlertWindow.label_alert:SetVisible(not AlertWindow.label_alert:IsVisible())
			if not AlertWindow.label_alert:IsVisible() then
				Alert_Counter = Alert_Counter - 1
			end
		end

		if not storage.battletask_warning_disabled then
			local has_battle_task_scroll = false
			local player_bags = Local_Player:GetBackpack()
			local player_bags_size = player_bags:GetSize()
			if player_bags_size == 0 then
				return
			else
				for i = 1, player_bags_size do
					local bagitem = player_bags:GetItem(i)
					if bagitem ~= nil then
						local bagitem_name = player_bags:GetItem(i):GetName()
						if bagitem_name == L.Battle_Task_Quest_Giver then
							has_battle_task_scroll = true
							BattleTaskWindow.label_battle_task:SetVisible(false)
							break
						end
					end
				end
				if not has_battle_task_scroll then
					BattleTaskWindow:NewAlert(L.Battle_Task_Message, Aligned_Color)
					BattleTaskWindow.label_battle_task:SetVisible(true)
				end
			end
		else
			BattleTaskWindow.label_battle_task:SetVisible(false)
		end

		if (wallet_loaded and buffs_loaded) then
			local current_date = Turbine.Engine.GetDate()
			local current_day = current_date.DayOfYear
			local current_month = current_date.Month
			if data.numbers.current_day ~= current_day then
				if not (current_date.Hour < data.numbers.resettime and ((current_day - data.numbers.current_day == 1)
					or (current_day < data.numbers.current_day and current_day == 1 and data.numbers.current_day == GetDaysPerYear(Turbine.Engine.GetDate().Year - 1))))
				 then
					data.numbers.history.points[data.numbers.current_day] = data.numbers.points_current_day
					data.numbers.history.frags[data.numbers.current_day] = data.numbers.frags_current_day
					data.numbers.history.tracks[data.numbers.current_day] = data.numbers.tracks_current_day
					data.numbers.history.comms[data.numbers.current_day] = data.numbers.comms_current_day
					data.numbers.history.deaths[data.numbers.current_day] = data.numbers.deaths_current_day
					data.numbers.current_day = current_day
					data.numbers.points_current_day = 0
					data.numbers.frags_current_day = 0
					data.numbers.tracks_current_day = 0
					data.numbers.comms_current_day = 0
					data.numbers.deaths_current_day = 0
					Plugins["PvMP+"].Unload(nil, nil, true)
				end
			end
			if data.numbers.current_month ~= current_month then
				if not (current_date.Hour < data.numbers.resettime and ((current_month - data.numbers.current_month == 1)
					or (current_month < data.numbers.current_month and current_month == 1 and data.numbers.current_month == 12)))
				 then
					data.numbers.history.pointsMonth[data.numbers.current_month] = data.numbers.points_current_month
					data.numbers.history.fragsMonth[data.numbers.current_month] = data.numbers.frags_current_month
					data.numbers.history.tracksMonth[data.numbers.current_month] = data.numbers.tracks_current_month
					data.numbers.history.commsMonth[data.numbers.current_month] = data.numbers.comms_current_month
					data.numbers.history.deathsMonth[data.numbers.current_month] = data.numbers.deaths_current_month
					data.numbers.current_month = current_month
					data.numbers.points_current_month = 0
					data.numbers.frags_current_month = 0
					data.numbers.tracks_current_month = 0
					data.numbers.comms_current_month = 0
					data.numbers.deaths_current_month = 0
					Plugins["PvMP+"].Unload(nil, nil, true)
				end
			end
			local new_commendations = commendations_in_wallet:GetQuantity()
			local commendations_changed = new_commendations ~= Current_Commendations
			if commendations_changed then
				Current_Commendations = new_commendations
				Commendation_Warning = Current_Commendations >= Commendation_Limit
				if Commendation_Warning and not storage.comms_warning_disabled then
					OverviewWindow.label_commendations:SetForeColor(Turbine.UI.Color.Red)
				elseif not Commendation_Warning then
					OverviewWindow.label_commendations:SetForeColor(Default_Font_Color)
					OverviewWindow.label_commendations:SetVisible(true)
					OverviewWindow.commendations_icon:SetVisible(true)
				end
				Plugins["PvMP+"].Unload(nil, nil, false)
			end
		elseif not buffs_loaded then
			Buff_List = Local_Player:GetEffects()
			if Buff_List == nil then
				return
			else
				buffs_loaded = true
				InitializeBuffListener()
			end
		elseif not wallet_loaded then
			local player_wallet = Local_Player:GetWallet()
			local player_wallet_size = player_wallet:GetSize()
			for i = 1, player_wallet_size do
				local walletitem = player_wallet:GetItem(i)
				if walletitem:GetName() == L.Wallet_Commendations then
					commendations_in_wallet = walletitem
					Current_Commendations = commendations_in_wallet:GetQuantity()
					break
				end
			end
			if commendations_in_wallet == nil then
				return
			end
			if Last_Commendations ~= nil and Last_Commendations ~= Current_Commendations then
				InitWindowPoints:DataOutOfSync()
				InitWindowFrags:DataOutOfSync()
			end
			wallet_loaded = true
		end

		currentResolution = Turbine.UI.Display.GetWidth()
		if oldResolution ~= currentResolution then
			oldResolution = currentResolution
			OverviewWindow:UpdatePosition()
		end
		OverviewWindow:Update()
	end
end

Updater.CommendationFlashing = function()
	local flashes_per_second = 2
	if Turbine.Engine.GetGameTime() - timestamp > 1 / flashes_per_second then
		timestamp = Turbine.Engine.GetGameTime()
		OverviewWindow.label_commendations:SetVisible(not OverviewWindow.label_commendations:IsVisible())
		OverviewWindow.commendations_icon:SetVisible(not OverviewWindow.commendations_icon:IsVisible())
	end
end

Local_Player.InCombatChanged = function(sender, args)
	if Local_Player:IsInCombat() then
		New_Fight_1 = true
		New_Fight_2 = true
		New_Fight_3 = true
		Recent_Hits_Reset = true
	-- Used to reset RecentHitsWindow after dying
	-- if Local_Player:GetMorale() <= 0 then
	-- 		Recent_Hits_List = {}
	-- 		Recent_Hits_Counter = 0
	-- 		RecentHitsWindow:ClearHitList()
	-- 	end
	end
end