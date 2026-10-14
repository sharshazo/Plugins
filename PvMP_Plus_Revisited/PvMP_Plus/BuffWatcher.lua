function InitializeBuffListener()
	Buff_List.EffectAdded = function(sender, args)
		if SetContains(Bonus_Buffs, Buff_List:Get(args.Index):GetName()) then
			UpdateBonus()
			UpdateKeeps()
			UpdateOutposts()
		end
	end

	Buff_List.EffectRemoved = function(sender, args)
		if SetContains(Bonus_Buffs, args.Effect:GetName()) then
			UpdateBonus()
			UpdateKeeps()
			UpdateOutposts()
		end
	end

	UpdateBonus()
	UpdateKeeps()
	UpdateOutposts()
end

function UpdateBonus()
	local bonus = 0

	local tree_owned = false
	local drake_owned = false
	local gary_owned = false

	local crown_owned = false
	local carrock_owned = false
	local map_control = false

	local outnumbered = false

	for i = 1, Buff_List:GetCount() do
		local element = Buff_List:Get(i):GetName()
		if SetContains(Bonus_Buffs, element) then
			if map_control or not (element == Relic_Buffs[5] or element == Relic_Buffs[6]) then
				bonus = bonus + Bonus_Buffs[element]
			end
			if not map_control and (element == Relic_Buffs[5] or element == Relic_Buffs[6]) then
				map_control = true
			end

			-- DoF buffs
			if element == DoF_Buffs[1] then
				if OverviewWindow:IsTreeOwned() == false then
					OverviewWindow:ResetTreeTimer()
				end
				OverviewWindow:SetTreeOwner(true)
				tree_owned = true
			elseif element == DoF_Buffs[2] then
				if OverviewWindow:IsDrakeOwned() == false then
					OverviewWindow:ResetDrakeTimer()
				end
				OverviewWindow:SetDrakeOwner(true)
				drake_owned = true
			elseif element == DoF_Buffs[3] then
				if OverviewWindow:IsGaryOwned() == false then
					OverviewWindow:ResetGaryTimer()
				end
				OverviewWindow:SetGaryOwner(true)
				gary_owned = true
			end

			-- Relic buffs
			if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
				if element == Relic_Buffs[1] then
					if OverviewWindow:IsCrownOwned() == false then
						OverviewWindow:ResetCrownTimer()
					end
					OverviewWindow:SetCrownOwner(true)
					crown_owned = true
				end
				if (element == Relic_Buffs[2] or element == Relic_Buffs[3]) then
					if OverviewWindow:IsCarrockOwned() == false then
						OverviewWindow:ResetCarrockTimer()
					end
					OverviewWindow:SetCarrockOwner(true)
					carrock_owned = true
				end
			elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
				if element == Relic_Buffs[4] then
					if OverviewWindow:IsCarrockOwned() == false then
						OverviewWindow:ResetCarrockTimer()
					end
					OverviewWindow:SetCarrockOwner(true)
					carrock_owned = true
				end
				if (element == Relic_Buffs[5] or element == Relic_Buffs[6]) then
					if OverviewWindow:IsCrownOwned() == false then
						OverviewWindow:ResetCrownTimer()
					end
					OverviewWindow:SetCrownOwner(true)
					crown_owned = true
				end
			end

			-- Outnumbered buffs
			if (element == Outnumbered_Buffs[1] or element == Outnumbered_Buffs[2]) then
				if OverviewWindow:IsOutnumberedOwned() == false then
					OverviewWindow:ResetOutnumberedTimer()
				end
				OverviewWindow:SetOutnumberedOwner(true)
				outnumbered = true
			end
		end
	end

	-- Reset DoF buff owners
	if tree_owned == false then
		if OverviewWindow:IsTreeOwned() == true then
			OverviewWindow:ResetTreeTimer()
		end
		OverviewWindow:SetTreeOwner(false)
	end

	if drake_owned == false then
		if OverviewWindow:IsDrakeOwned() == true then
			OverviewWindow:ResetDrakeTimer()
		end
		OverviewWindow:SetDrakeOwner(false)
	end

	if gary_owned == false then
		if OverviewWindow:IsGaryOwned() == true then
			OverviewWindow:ResetGaryTimer()
		end
		OverviewWindow:SetGaryOwner(false)
	end

	-- Reset Relic buff owners
	if crown_owned == false then
		if OverviewWindow:IsCrownOwned() == true then
			OverviewWindow:ResetCrownTimer()
		end
		OverviewWindow:SetCrownOwner(false)
	end

	if carrock_owned == false then
		if OverviewWindow:IsCarrockOwned() == true then
			OverviewWindow:ResetCarrockTimer()
		end
		OverviewWindow:SetCarrockOwner(false)
	end

	-- Reset Outnumbered buff owners
	if outnumbered == false then
		if OverviewWindow:IsOutnumberedOwned() == true then
			OverviewWindow:ResetOutnumberedTimer()
		end
		OverviewWindow:SetOutnumberedOwner(false)
	end

	OverviewWindow.label_bonus:SetText(L.Stats_Bonus .. bonus .. "%")
	MapWindow:UpdateKeepsOnMap()
end

function UpdateOutposts()
	local aligned_outposts_count = 0
	local enemy_outposts_count = 0
	local aligned_outposts_list = {}
	local enemy_outposts_list = {}

	for key, value in pairs(Outpost_Acronyms) do
		enemy_outposts_count = enemy_outposts_count + 1
		enemy_outposts_list[enemy_outposts_count] = value
	end

	for i = 1, Buff_List:GetCount() do
		local element = Buff_List:Get(i):GetName()
		if SetContains(Outpost_Acronyms, element) then
			aligned_outposts_list[aligned_outposts_count] = Outpost_Acronyms[element]
			table.remove(enemy_outposts_list, FindIndex(enemy_outposts_list, Outpost_Acronyms[element]))
			aligned_outposts_count = aligned_outposts_count + 1
		end
	end

	-- Set all outposts bar colors to Enemy_Color
	OverviewWindow.outpost_1:SetBackColor(Enemy_Color)
	OverviewWindow.outpost_2:SetBackColor(Enemy_Color)
	OverviewWindow.outpost_3:SetBackColor(Enemy_Color)
	OverviewWindow.outpost_4:SetBackColor(Enemy_Color)

	if aligned_outposts_count == 0 then
		OverviewWindow.outpost_1_text:SetText(enemy_outposts_list[1])
		OverviewWindow.outpost_2_text:SetText(enemy_outposts_list[2])
		OverviewWindow.outpost_3_text:SetText(enemy_outposts_list[3])
		OverviewWindow.outpost_4_text:SetText(enemy_outposts_list[4])
	end
	if aligned_outposts_count >= 1 then
		OverviewWindow.outpost_1:SetBackColor(Aligned_Color)
		OverviewWindow.outpost_1_text:SetText(aligned_outposts_list[0])

		OverviewWindow.outpost_2_text:SetText(enemy_outposts_list[1])
		OverviewWindow.outpost_3_text:SetText(enemy_outposts_list[2])
		OverviewWindow.outpost_4_text:SetText(enemy_outposts_list[3])
	end
	if aligned_outposts_count >= 2 then
		OverviewWindow.outpost_2:SetBackColor(Aligned_Color)
		OverviewWindow.outpost_2_text:SetText(aligned_outposts_list[1])

		OverviewWindow.outpost_3_text:SetText(enemy_outposts_list[1])
		OverviewWindow.outpost_4_text:SetText(enemy_outposts_list[2])
	end
	if aligned_outposts_count >= 3 then
		OverviewWindow.outpost_3:SetBackColor(Aligned_Color)
		OverviewWindow.outpost_3_text:SetText(aligned_outposts_list[2])

		OverviewWindow.outpost_4_text:SetText(enemy_outposts_list[1])
	end
	if aligned_outposts_count == 4 then
		OverviewWindow.outpost_4:SetBackColor(Aligned_Color)
		OverviewWindow.outpost_4_text:SetText(aligned_outposts_list[3])
	end
	MapWindow:UpdateKeepsOnMap()
end

function UpdateKeeps()
	local keep_found = false
	local freep_keep_count = 0
	local creep_keep_count = 0

	--Set all freep keeps to invisible and empty text
	OverviewWindow.freep_keep_1:SetVisible(false)
	OverviewWindow.freep_keep_1_text:SetText("")
	OverviewWindow.freep_keep_2:SetVisible(false)
	OverviewWindow.freep_keep_2_text:SetText("")
	OverviewWindow.freep_keep_3:SetVisible(false)
	OverviewWindow.freep_keep_3_text:SetText("")
	OverviewWindow.freep_keep_4:SetVisible(false)
	OverviewWindow.freep_keep_4_text:SetText("")
	OverviewWindow.freep_keep_5:SetVisible(false)
	OverviewWindow.freep_keep_5_text:SetText("")

	--Set all creep keeps to invisible and empty text
	OverviewWindow.creep_keep_1:SetVisible(false)
	OverviewWindow.creep_keep_1_text:SetText("")
	OverviewWindow.creep_keep_2:SetVisible(false)
	OverviewWindow.creep_keep_2_text:SetText("")
	OverviewWindow.creep_keep_3:SetVisible(false)
	OverviewWindow.creep_keep_3_text:SetText("")
	OverviewWindow.creep_keep_4:SetVisible(false)
	OverviewWindow.creep_keep_4_text:SetText("")
	OverviewWindow.creep_keep_5:SetVisible(false)
	OverviewWindow.creep_keep_5_text:SetText("")

	if not storage.show_keep_disabled then
		for i = 1, 5 do
			local element = Keeps[i]
			keep_found = false
			if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
				for j = 1, Buff_List:GetCount() do
					local buff_elem = Buff_List:Get(j):GetName()
					if element == buff_elem then
						if freep_keep_count == 0 then
							OverviewWindow.freep_keep_1:SetVisible(true)
							OverviewWindow.freep_keep_1_text:SetText(Keep_Acronyms[element])
						elseif freep_keep_count == 1 then
							OverviewWindow.freep_keep_2:SetVisible(true)
							OverviewWindow.freep_keep_2_text:SetText(Keep_Acronyms[element])
						elseif freep_keep_count == 2 then
							OverviewWindow.freep_keep_3:SetVisible(true)
							OverviewWindow.freep_keep_3_text:SetText(Keep_Acronyms[element])
						elseif freep_keep_count == 3 then
							OverviewWindow.freep_keep_4:SetVisible(true)
							OverviewWindow.freep_keep_4_text:SetText(Keep_Acronyms[element])
						elseif freep_keep_count == 4 then
							OverviewWindow.freep_keep_5:SetVisible(true)
							OverviewWindow.freep_keep_5_text:SetText(Keep_Acronyms[element])
						end
						freep_keep_count = freep_keep_count + 1
						keep_found = true
						j = Buff_List:GetCount()
					end
				end
				if not keep_found then
					if creep_keep_count == 0 then
						OverviewWindow.creep_keep_1:SetVisible(true)
						OverviewWindow.creep_keep_1_text:SetText(Keep_Acronyms[element])
					elseif creep_keep_count == 1 then
						OverviewWindow.creep_keep_2:SetVisible(true)
						OverviewWindow.creep_keep_2_text:SetText(Keep_Acronyms[element])
					elseif creep_keep_count == 2 then
						OverviewWindow.creep_keep_3:SetVisible(true)
						OverviewWindow.creep_keep_3_text:SetText(Keep_Acronyms[element])
					elseif creep_keep_count == 3 then
						OverviewWindow.creep_keep_4:SetVisible(true)
						OverviewWindow.creep_keep_4_text:SetText(Keep_Acronyms[element])
					elseif creep_keep_count == 4 then
						OverviewWindow.creep_keep_5:SetVisible(true)
						OverviewWindow.creep_keep_5_text:SetText(Keep_Acronyms[element])
					end
					creep_keep_count = creep_keep_count + 1
				end
			elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
				for j = 1, Buff_List:GetCount() do
					local buff_elem = Buff_List:Get(j):GetName()
					if element == buff_elem then
						if creep_keep_count == 0 then
							OverviewWindow.creep_keep_1:SetVisible(true)
							OverviewWindow.creep_keep_1_text:SetText(Keep_Acronyms[element])
						elseif creep_keep_count == 1 then
							OverviewWindow.creep_keep_2:SetVisible(true)
							OverviewWindow.creep_keep_2_text:SetText(Keep_Acronyms[element])
						elseif creep_keep_count == 2 then
							OverviewWindow.creep_keep_3:SetVisible(true)
							OverviewWindow.creep_keep_3_text:SetText(Keep_Acronyms[element])
						elseif creep_keep_count == 3 then
							OverviewWindow.creep_keep_4:SetVisible(true)
							OverviewWindow.creep_keep_4_text:SetText(Keep_Acronyms[element])
						elseif creep_keep_count == 4 then
							OverviewWindow.creep_keep_5:SetVisible(true)
							OverviewWindow.creep_keep_5_text:SetText(Keep_Acronyms[element])
						end
						creep_keep_count = creep_keep_count + 1
						keep_found = true
						j = Buff_List:GetCount()
					end
				end
				if not keep_found then
					if freep_keep_count == 0 then
						OverviewWindow.freep_keep_1:SetVisible(true)
						OverviewWindow.freep_keep_1_text:SetText(Keep_Acronyms[element])
					elseif freep_keep_count == 1 then
						OverviewWindow.freep_keep_2:SetVisible(true)
						OverviewWindow.freep_keep_2_text:SetText(Keep_Acronyms[element])
					elseif freep_keep_count == 2 then
						OverviewWindow.freep_keep_3:SetVisible(true)
						OverviewWindow.freep_keep_3_text:SetText(Keep_Acronyms[element])
					elseif freep_keep_count == 3 then
						OverviewWindow.freep_keep_4:SetVisible(true)
						OverviewWindow.freep_keep_4_text:SetText(Keep_Acronyms[element])
					elseif freep_keep_count == 4 then
						OverviewWindow.freep_keep_5:SetVisible(true)
						OverviewWindow.freep_keep_5_text:SetText(Keep_Acronyms[element])
					end
					freep_keep_count = freep_keep_count + 1
				end
			end
		end
	end
	MapWindow:UpdateKeepsOnMap()
end