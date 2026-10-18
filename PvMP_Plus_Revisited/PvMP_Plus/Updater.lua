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
local wallet_check_at = 0

local task_bag, task_hooks
local task_dirty, task_check_at = true, 0
local task_present = false
function PvMP_ReleaseBackpackWatch()
	if task_hooks ~= nil then
		task_hooks.alive = false
		for event, hook in pairs(task_hooks.list) do
			if task_bag[event] == hook.handler then task_bag[event] = hook.previous end
		end
	end
	task_bag, task_hooks = nil, nil
	task_dirty = true
end

local function CheckBattleTask(now)
	if storage.battletask_warning_disabled then
		PvMP_ReleaseBackpackWatch()
		BattleTaskWindow.label_battle_task:SetVisible(false)
		return
	end
	local bag = Local_Player:GetBackpack()
	if bag == nil then return end
	if bag ~= task_bag then
		PvMP_ReleaseBackpackWatch()
		task_bag = bag
		local hooks = { alive = true, list = {} }
		for _, event in ipairs({"ItemAdded", "ItemRemoved", "ItemMoved", "ItemChanged"}) do
			local previous = bag[event]
			local handler = function(sender, args)
				if hooks.alive then task_dirty = true end
				if type(previous) == "function" then
					pcall(previous, sender, args)
				elseif type(previous) == "table" then
					for _, callback in ipairs(previous) do
						if type(callback) == "function" then pcall(callback, sender, args) end
					end
				end
			end
			hooks.list[event] = { handler = handler, previous = previous }
			bag[event] = handler
		end
		task_hooks = hooks
	end
	if not task_dirty and now < task_check_at then return end
	local size = bag:GetSize()
	if size == 0 then
		-- Inventory is not ready; do not block the calendar or other windows.
		BattleTaskWindow.label_battle_task:SetVisible(false)
		return
	end
	task_dirty, task_check_at, task_present = false, now + 30, false
	for i = 1, size do
		local item = bag:GetItem(i)
		if item ~= nil and item:GetName() == L.Battle_Task_Quest_Giver then
			task_present = true
			break
		end
	end
	if not task_present then BattleTaskWindow:NewAlert(L.Battle_Task_Message, Aligned_Color) end
	BattleTaskWindow.label_battle_task:SetVisible(not task_present)
end

local function CheckWallet(now)
	if wallet_loaded then return end
	if now < wallet_check_at then return end
	wallet_check_at = now + 5
	local wallet = Local_Player:GetWallet()
	if wallet == nil then return end
	for i = 1, wallet:GetSize() do
		local item = wallet:GetItem(i)
		if item ~= nil and item:GetName() == L.Wallet_Commendations then
			commendations_in_wallet = item
			Current_Commendations = item:GetQuantity()
			wallet_loaded = true
			break
		end
	end
	if wallet_loaded and Last_Commendations ~= nil and Last_Commendations ~= Current_Commendations then
		InitWindowPoints:DataOutOfSync()
		InitWindowFrags:DataOutOfSync()
	end
end

Updater.Update = function(sender, args)
	currentsecond = Turbine.Engine.GetDate().Second

	if Commendation_Warning and not storage.comms_warning_disabled then
		Updater.CommendationFlashing()
	end

	if oldsecond ~= currentsecond then
		oldsecond = currentsecond
		FlushPvMPSave()
		local now = Turbine.Engine.GetGameTime()
		if not buffs_loaded then
			Buff_List = Local_Player:GetEffects()
			if Buff_List ~= nil then
				buffs_loaded = true
				InitializeBuffListener()
			end
		end
		CheckWallet(now)
		CheckBattleTask(now)

		for player, control in pairs(MapWindow.enemy_position_list) do
			control.Timer = control.Timer - 1
			if control.Timer % 2 == 0 then
				control:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/MapIcons/enemy_position_overlay_empty.tga")
			else
				-- v4.3.14: la marca se apaga poco a poco al final
				local fade = (control.Timer <= 10 and "_fade2") or (control.Timer <= 25 and "_fade1") or ""
				control:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/MapIcons/enemy_position_overlay" .. fade .. ".tga")
			end
			-- v4.3.14: nombre y segundos que le quedan
			if control.Timer > 0 and control.Callout ~= nil then
				control:SetText(control.Callout .. " (" .. control.Timer .. "s)")
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

		do  -- Calendar progression does not depend on a wallet currency.
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
			if wallet_loaded then
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
				RequestPvMPSave()
			end
			end
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
