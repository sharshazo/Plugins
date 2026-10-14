_G.L = {}

if (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Infamy"
	L.Chat_Points = " infamy points."
	L.FreepsCreeps = "Freeps"
	L.FreepCreep = "Freep"
	L.Battle_Task_Quest_Giver = "Slaughter the Free-folk"
	L.Battle_Task_Message = "Get a Battle Task you maggot!"
	_G.Rank_Names = {
		[0] = "Unranked",
		[1] = "Tracker",
		[2] = "Scout",
		[3] = "Skirmisher",
		[4] = "Fighter",
		[5] = "Soldier",
		[6] = "Sentry",
		[7] = "Chief Guard",
		[8] = "Chief Warrior",
		[9] = "Taskmaster",
		[10] = "Lieutenant",
		[11] = "Commander",
		[12] = "Chieftain",
		[13] = "High Chieftain",
		[14] = "Overlord",
		[15] = "Tyrant"
	}
	_G.Tier_Names = {
		[0] = "Unknown",
		[1] = "Tormenter",
		[2] = "Black Dog",
		[3] = "Harvester of Sorrow",
		[4] = "Slayer of Light",
		[5] = "Hand of Doom",
		[6] = "Bane of the West",
		[7] = "Herald of Darkness",
		[8] = "Manifestation of Morgoth"
	}
	L.Chat_Channels = {
		[1] = { "say", "Say" },
		[2] = { "f", "Group" },
		[3] = { "ra", "Raid" },
		[4] = { "tr", "Tribe" },
		[5] = { "ooc", "OOC" },
		[6] = { "1", "User Chat 1" },
		[7] = { "2", "User Chat 2" },
		[8] = { "3", "User Chat 3" },
		[9] = { "4", "User Chat 4" },
		[10] = { "5", "User Chat 5" },
		[11] = { "6", "User Chat 6" },
		[12] = { "7", "User Chat 7" },
		[13] = { "8", "User Chat 8" }
	}
elseif (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Renown"
	L.Chat_Points = " renown points."
	L.FreepsCreeps = "Creeps"
	L.FreepCreep = "Creep"
	L.Battle_Task_Quest_Giver = "Against the Enemy"
	L.Battle_Task_Message = "Claim a Battle Task!"
	_G.Rank_Names = {
		[0] = "Unranked",
		[1] = "Footman",
		[2] = "Esquire",
		[3] = "Guardsman",
		[4] = "Man-at-Arms",
		[5] = "Sergeant of the Guard",
		[6] = "Sergeant-at-Arms",
		[7] = "Master Guardsman",
		[8] = "Master-at-Arms",
		[9] = "High Warden",
		[10] = "Lieutenant",
		[11] = "Commander",
		[12] = "Third Marshall",
		[13] = "Second Marshall",
		[14] = "First Marshall",
		[15] = "Captain-General"
	}
	_G.Tier_Names = {
		[0] = "Unknown",
		[1] = "Neophyte",
		[2] = "Warrior",
		[3] = "Veteran",
		[4] = "Battlemaster",
		[5] = "Warlord",
		[6] = "Hero of the Ettenmoors",
		[7] = "Hero of Legend",
		[8] = "Saviour of Arda"
	}
	L.Chat_Channels = {
		[1] = { "say", "Say" },
		[2] = { "f", "Fellowship" },
		[3] = { "ra", "Raid" },
		[4] = { "k", "Kinship" },
		[5] = { "ooc", "OOC" },
		[6] = { "1", "User Chat 1" },
		[7] = { "2", "User Chat 2" },
		[8] = { "3", "User Chat 3" },
		[9] = { "4", "User Chat 4" },
		[10] = { "5", "User Chat 5" },
		[11] = { "6", "User Chat 6" },
		[12] = { "7", "User Chat 7" },
		[13] = { "8", "User Chat 8" }
	}
end

_G.Bonus_Buffs = {
	-- Outnumbered
	["Lainedhal's Call to Arms"] = 10,
	["Akúlhun's Challenge"] = 10,
	-- Keeps
	["Tol Ascarnen"] = 50,
	["Lugazag"] = 10,
	["Tírith Rhaw"] = 10,
	["Grimwood Lumber Camp"] = 35,
	["Isendeep Mine"] = 35,
	--Outposts
	["Coldfells Outpost"] = 20,
	["River Outpost"] = 20,
	["Arador's End Outpost"] = 20,
	["Isendeep Outpost"] = 20,
	-- DoF
	["Gaergoth"] = 40,
	["Rottenroot"] = 30,
	["Gwaelug"] = 30,
	-- Relics
	["Fragment of Mordirith's Crown"] = 50,
	["Watchful Gaze"] = 3,
	["Gift of the Eye"] = 5,
	["The Gift of Carrock"] = 50,
	["A Quiet Calm"] = 3,
	["Peace and Quiet"] = 5,
	-- Store
	["+100% Infamy/Renown Gain"] = 100,
	["+20% Infamy Gain"] = 20,
	["+20% Renown Gain"] = 20,
	["For the Glory of..."] = 20
}

_G.Relic_Buffs = {
	[1] = "Fragment of Mordirith's Crown",
	[2] = "Watchful Gaze",
	[3] = "Gift of the Eye",
	[4] = "The Gift of Carrock",
	[5] = "A Quiet Calm",
	[6] = "Peace and Quiet"
}

_G.DoF_Buffs = {
	[1] = "Rottenroot",
	[2] = "Gwaelug",
	[3] = "Gaergoth"
}

_G.Outnumbered_Buffs = {
	[1] = "Lainedhal's Call to Arms",
	[2] = "Akúlhun's Challenge"
}

_G.Towers = {
	["Tol Ascarnen"] = 1,
	["Isendeep Mine"] = 2,
	["Tírith Rhaw"] = 3,
	["Lugazag"] = 4,
	["Grimwood Lumber Camp"] = 5,
	["Coldfells Outpost"] = 6,
	["Arador's End Outpost"] = 7,
	["River Outpost"] = 8,
	["Isendeep Outpost"] = 9
}

_G.Keeps = {
	[1] = "Tol Ascarnen",
	[2] = "Isendeep Mine",
	[3] = "Tírith Rhaw",
	[4] = "Lugazag",
	[5] = "Grimwood Lumber Camp"
}

_G.Keep_Acronyms = {
	["Tol Ascarnen"] = "TA",
	["Isendeep Mine"] = "IM",
	["Tírith Rhaw"] = "TR",
	["Lugazag"] = "LG",
	["Grimwood Lumber Camp"] = "LC"
}

_G.Outpost_Acronyms = {
	["Coldfells Outpost"] = "H",
	["River Outpost"] = "R",
	["Arador's End Outpost"] = "A",
	["Isendeep Outpost"] = "I"
}

_G.Map_Positions = {
	[1] = "Tol Ascarnen",
	[2] = "Isendeep Mine",
	[3] = "Tírith Rhaw",
	[4] = "Lugazag",
	[5] = "Grimwood Lumber Camp",
	[6] = "Hithlad Outpost",
	[7] = "Arador's End Outpost",
	[8] = "River Outpost",
	[9] = "Isendeep Outpost",
	[10] = "Gramsfoot",
	[11] = "Dâr-gazag",
	[12] = "Orc Camp",
	[13] = "Grothum",
	[14] = "Mazauk's Den",
	[15] = "Spider Den",
	[16] = "Glân Vraig",
	[17] = "Ost Ringdyr",
	[18] = "Elf Camp",
	[19] = "Hoarhallow",
	[20] = "Golloval",
	[21] = "Goldhead",
	[22] = "STAB",
	[23] = "WTAB",
	[24] = "DoF - Hithlad Outpost",
	[25] = "DoF - Arador's End Outpost",
	[26] = "DoF - River Outpost",
	[27] = "DoF - Isendeep Outpost",
	[28] = "DoF - Dâr-gazag",
	[29] = "DoF - Orc Camp",
	[30] = "DoF - Ost Ringdyr",
	[31] = "DoF - Elf Camp",
	[32] = "Gaergoth",
	[33] = "Rottenroot",
	[34] = "Gwaelug"
}

_G.Cardinal_Directions = {
	[1] = "N",
	[2] = "NE",
	[3] = "E",
	[4] = "SE",
	[5] = "S",
	[6] = "SW",
	[7] = "W",
	[8] = "NW"
}

_G.NPC_Names = {
	-- Quest NPC's
	[1] = "Bok",
	[2] = "Gasham",
	[3] = "Golloval",
	[4] = "Mazauk",
	[5] = "Caragdal",
	[6] = "Gorgoris",
	[7] = "Rockwithers",
	-- DoF NPC's - Check if these still exist
	[8] = "Boldirith", -- Gary Undeads
	[9] = "Gortheblin", -- Orc Camp Shade
	[10] = "Gworvaethor",
	[11] = "Gâth", -- Rottenroot
	[12] = "Gúrhardron",
	[13] = "Húrlug", -- Gary Salamanders
	[14] = "Iachador",
	[15] = "Iarwen", -- AEOP DoF aligned
	[16] = "Malembor",
	[17] = "Nemornion",
	[18] = "Núrlug", -- Gary Salamanders
	[19] = "Raingorth",
	[20] = "Rimgurthil", -- HOP DoF aligned
	[21] = "Thorliw", -- ROP DoF aligned
	[22] = "Uidhelos", -- Elf Camp Shade
	-- DoF Bosses
	[23] = "Rottenroot"
}

L.Months = {
	[1] = "Jan",
	[2] = "Feb",
	[3] = "Mar",
	[4] = "Apr",
	[5] = "May",
	[6] = "Jun",
	[7] = "Jul",
	[8] = "Aug",
	[9] = "Sep",
	[10] = "Oct",
	[11] = "Nov",
	[12] = "Dec"
}

L.Init_Points = "Please enter your total " .. L.InfamyRenown .. ":"
L.Init_Frags = "Please enter your total Killing Blows:"
L.Init_Invalid_Input = "Invalid Input!"

L.Window_Confirm = "OK"
L.Window_Save = "Save"
L.Window_Cancel = "Cancel"

L.Wallet_Commendations = "Commendation"

L.Stats_Bonus = "Bonus: "
L.Stats_Total_Points = "Total " .. L.InfamyRenown .. ": "
L.Stats_Remaining_Points = L.InfamyRenown .. " to Rank-Up: "
L.Stats_Total_Points_Short = L.InfamyRenown .. ": "
L.Stats_Remaining_Points_Short = "Rank-Up: "

L.Menu = { "Total", "Rank-Up", "Month", "Day", "Hour", "10 mins", "Fight" }
L.Stats_Points_Type = "My " .. L.InfamyRenown .. ": "
L.Stats_Total = "Total: "
L.Stats_Current = "Current: "
L.Stats_To_RankUp = "To Rank-Up: "
L.Stats_To_TierUp = "To Tier-Up: "

L.Stats_Last_Year = "Last Year"
L.Stats_Last_Month = "Last Month"
L.Stats_Last_24h = "Last 24 Hours: "
L.Stats_Today = "Today: "

L.Stats_Current_Month = "Current Month: "
L.Stats_Current_Day = "Current Day: "
L.Stats_Last_Hour = "Last Hour: "
L.Stats_Last_10min = "Last 10 Mins: "
L.Stats_Last_Fight = "Last Fight: "
L.Stats_Current_Month_Short = "Month: "
L.Stats_Current_Day_Short = "Day: "
L.Stats_Last_Hour_Short = "Hour: "
L.Stats_Last_10min_Short = "10 Mins: "
L.Stats_Last_Fight_Short = "Fight: "

L.Statistics_Header = "Statistics"
L.Progress_Header = "Progress"
L.Stats_Rank = "Rank "
L.Stats_Tier = "Tier "
L.Commendations_Header = "Commendations"
L.KillingBlows_Header = "Killing Blows"
L.Deaths_Header = "Deaths"
L.Tracks_Header = "Tracks"

L.Tab_Statistics = "Character Statistics"
L.Tab_Log = "Killing Blow Log"
L.Tab_Points = L.InfamyRenown .. " Statistics"
L.Tab_Commendations = "Commendation Statistics"
L.Tab_Killing_Blows = "Killing Blow Statistics"
L.Tab_Deaths = "Death Statistics"
L.Tab_Tracks = "Track Statistics"

L.Log_Search = "Search: "
L.Log_Name = "Name"
L.Log_KillingBlows = "Kills"

L.Stats_Maximum_Kill = "Maximum Kill: "
L.Stats_Maximum_Day = "Maximum Day: "
L.Stats_Maximum_Month = "Maximum Month: "
L.Stats_Points_Per_KillingBlow = L.InfamyRenown .. " per Killing Blow: "
L.Stats_KillingBlows_Per_Death = "Killing Blows per Death: "

L.Recent_Hits_Header = "Recent Hits"
L.Recent_Hits_Link_Count = "Link Count"
L.Recent_Hits_Amount = "Count"

L.Recent_Kills_Header = "Last 5 Kills"
L.String_Loc = "Loc"
L.String_Send = "Send"
L.Map_Show = "Show Map"
L.Map_Hide = "Hide Map"
L.Get_Own_Position = "Show own position"

L.Loc_Command = "/loc"
L.Loc_Chat = ";loc"

L.Chat_Location_String = "You are on %a+ server %d+ at r.*"
L.Chat_Heading_String = "You are on %a+ server %d+ at r.* h.*"
L.Chat_Pattern_String_1 = "You are on %a+ server %d+ at r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_2 = "You are on %a+ server %d+ at r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_3 = "You are on %a+ server %d+ at r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) ox(%d+%.?%d*) oy(%d+%.?%d*) oz(%d+%.?%d*)"
L.Chat_Pattern_String_4 = "You are on %a+ server %d+ at r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"

L.Chat_Room_Join = "You joined room '(.+)' %(UserChat%d%)%. Number of members: %d+%."
L.Chat_Room_Leave = "You left room '(.+)'"

L.Chat_Tracked = "You feel as though you are being followed..."
L.Chat_Stealth_Nearby = "You sense that a creature is nearby but hidden from your sight."
L.Chat_Stealth_Spotted = "You have spotted a creature attempting to move stealthily about."

L.Chat_Earned_Points = "You've earned "
L.Chat_Earned_Commendations_Start = "You have acquired.+%["
L.Chat_Earned_Commendations_End = " Commendations]."
L.Chat_KillingBlow_Start = "Your mighty blow topples "
L.Chat_KillingBlow_End = "%."
L.Chat_Defeated = " incapacitated you."
L.Chat_Environment_Death = "You have been incapacitated by misadventure."
L.Chat_Damage_Hit = " scored a "
L.Chat_Damage_Avoid = " tried to use "

L.Chat_Lootbox = "Lootbox"
L.Chat_Key = "%[Black Steel Key]"
L.Chat_Appearance = "Appearance"

L.Options_Header = "Settings"
L.Options_Data_Settings = "Data Settings"
L.Options_Update_Points = "Set " .. L.InfamyRenown
L.Options_Update_Frags = "Set Killing Blows"
L.Options_Display_Settings = "Display Settings"
L.Options_Show_Stats = "Show Statistics"
L.Options_Bonus = "Show % Multiplier"
L.Options_OPs = "Show Outposts"
L.Options_Keeps = "Show Keeps"
L.Options_DOF = "Show DoF Buffs"
L.Options_Relic = "Show Relics"
L.Options_ON = "Show ON Buff"
L.Options_Alert_Settings = "Alert Settings"
L.Options_Track_Warning = "Track Warning"
L.Options_StealthAlert = "Stealth Warning"
L.Options_YourFragAlert = "Killing Blow Alert"
L.Options_LootboxAlert = "Lootbox Alert"
L.Options_Commendation_Warning = "Commendation Warning"
L.Options_Battle_Task_Warning = "Battle Task Warning"
L.Options_Other_Windows_Settings = "Secondary Windows"
L.Options_Recent_Kills = "Last Kills Window"
L.Options_Recent_Hits = "Recent Hits Window"
L.Options_Other_Settings = "Other Settings"
L.Options_Daily_Reset_Time = "Daily Reset Time"
L.Options_Window_Size = "Progress Bar Size"
L.Options_Reset = "Reset Settings to Default"
L.Options_Reset_Header = "Reset"
L.Options_Reset_Warning = "Warning!"
L.Options_Reset_Warning_Text = "Pressing " .. L.Window_Confirm .. " will reset all Settings back to their defaults!\n\nAre you sure you want to reset your current Settings?"
L.Options_Open_Settings = "Open Settings"
L.Strings_Points_Out_Of_Sync = "Data out of sync:\nPlease re-enter your total " .. L.InfamyRenown
L.Strings_Frags_Out_Of_Sync = "Data out of sync:\nPlease re-enter your total Killing Blows"

L.DragBar_Overview = "PvMP+"
L.DragBar_Alert = "PvMP+ Alerts"
L.DragBar_Battle_Task = "PvMP+ Battle Task"
L.DragBar_Recent_Hits_Window = "PvMP+ Recent Hits"
L.DragBar_Secondary_Window = "PvMP+ Last Kills"
L.DragBar_Map = "PvMP+ Map"

L.Command_Help = "Settings: /pvmp+ settings | Map: /pvmp+ map"
L.Command_Settings = "settings"
L.Command_Map = "map"

L.YourFrag_Message_Start = "Your mighty blow topples "
L.YourFrag_Message_End = "! "
L.YourFrag_Message_Taunt = {
	[1] = "Bazinga",
	[2] = "Sweet",
	[3] = "Score",
	[4] = "Awesome",
	[5] = "Booyah",
	[6] = "Yippie Kai Yay...",
	[7] = "Woot",
	[8] = "Yahoo",
	[9] = "Bingo",
	[10] = "Cowabunga",
	[11] = "Respectfully",
	[12] = "Sit",
	[13] = "Oof",
	[14] = "Eat Shit and Deed",
	[15] = "Get Bent",
	[16] = "Easy",
	[17] = "Noice",
	[18] = "Wack",
	[19] = "Sad",
	[20] = "Cheers",
	[21] = "In Your Face",
	[22] = "Who's Next",
	[23] = "Cope and Seethe",
	[24] = "In The Bin",
	[25] = "Git Gud",
	[26] = "Ez Game"
}