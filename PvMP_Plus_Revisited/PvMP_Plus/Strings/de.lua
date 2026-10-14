_G.L = {}

if (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Verrufenheit"
	L.Stats_Points_Type = "Meine " .. L.InfamyRenown .. ": "
	L.Init_Points = "Bitte gib Deine gesamten " .. L.InfamyRenown .. " ein:"
	L.Chat_Points = " Verrufenheitspunkte erhalten."
	L.FreepsCreeps = "Freie"
	L.FreepCreep = "Freier"
	L.Battle_Task_Quest_Giver = "Tod den Freien Völkern"
	L.Battle_Task_Message = "Besorge Dir eine Schlacht Aufgabe du Made!"
	_G.Rank_Names = {
		[0] = "Ohne Rang",
		[1] = "Fährtensucher",
		[2] = "Kundschafter", -- Kundschafterin
		[3] = "Scharmützler",
		[4] = "Kämpfer", -- Kämpferin
		[5] = "Soldat", -- Soldatin
		[6] = "Wache",
		[7] = "Oberster Wächter", -- Oberste Wächterin
		[8] = "Kriegeranführer", -- Kriegeranführerin
		[9] = "Zuchtmeister", -- Zuchtmeisterin
		[10] = "Leutnant",
		[11] = "Kommandeur",
		[12] = "Häuptling",
		[13] = "Oberster Häuptling",
		[14] = "Hochfürst", -- Hochfürstin
		[15] = "Tyrann" -- Tyrannin
	}
	_G.Tier_Names = {
		[0] = "Unbekannt",
		[1] = "Peiniger",
		[2] = "Schwarzer Hund",
		[3] = "Schnitter des Leids",
		[4] = "Bezwinger des Lichts",
		[5] = "Hand des Schicksals",
		[6] = "Fluch des Westens",
		[7] = "Herold der Dunkelheit",
		[8] = "Manifestation von Morgoth"
	}
	L.Chat_Channels = {
		[1] = { "sagen", "Sagen" },
		[2] = { "g", "Gruppe" },
		[3] = { "szc", "Schlachtzug" },
		[4] = { "st", "Stamm" },
		[5] = { "ooc", "OOC" },
		[6] = { "1", "Benutzer-Chat 1" },
		[7] = { "2", "Benutzer-Chat 2" },
		[8] = { "3", "Benutzer-Chat 3" },
		[9] = { "4", "Benutzer-Chat 4" },
		[10] = { "5", "Benutzer-Chat 5" },
		[11] = { "6", "Benutzer-Chat 6" },
		[12] = { "7", "Benutzer-Chat 7" },
		[13] = { "8", "Benutzer-Chat 8" }
	}
elseif (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Ansehen"
	L.Stats_Points_Type = "Mein " .. L.InfamyRenown .. ": "
	L.Init_Points = "Bitte gib Dein gesamtes " .. L.InfamyRenown .. " ein:"
	L.Chat_Points = " Ansehenspunkte erhalten."
	L.FreepsCreeps = "Monster"
	L.FreepCreep = "Monster"
	L.Battle_Task_Quest_Giver = "Gegen den Feind"
	L.Battle_Task_Message = "Beanspruche eine Schlacht Aufgabe tapferer Verteidiger!"
	_G.Rank_Names = {
		[0] = "Ohne Rang",
		[1] = "Gefolgsmann", -- ???
		[2] = "Knappe",
		[3] = "Wächter", -- Wächterin
		[4] = "Artillerist",
		[5] = "Unteroffizier der Wache",
		[6] = "Zeremonienmeister", -- Zeremonienmeisterin
		[7] = "Meister-Wächter", -- Meister-Wächterin
		[8] = "Hoher Artillerist",
		[9] = "Oberwächter", -- Oberwächterin
		[10] = "Leutnant",
		[11] = "Kommandeur",
		[12] = "Dritter Marschall", -- Dritte Marschallin
		[13] = "Zweiter Marschall", -- Zweite Marschallin
		[14] = "Erster Marschall", -- Erste Marschallin
		[15] = "General-Hauptmann"
	}
	_G.Tier_Names = {
		[0] = "Unbekannt",
		[1] = "Neuling",
		[2] = "Krieger",
		[3] = "Veteran",
		[4] = "Schlachtenmeister",
		[5] = "Kriegsherr",
		[6] = "Held der Ettenöden",
		[7] = "Held der Legenden",
		[8] = "Erlöser von Arda"
	}
	L.Chat_Channels = {
		[1] = { "sagen", "Sagen" },
		[2] = { "g", "Gefährten" },
		[3] = { "szc", "Schlachtzug" },
		[4] = { "sc", "Sippe" },
		[5] = { "ooc", "OOC" },
		[6] = { "1", "Benutzer-Chat 1" },
		[7] = { "2", "Benutzer-Chat 2" },
		[8] = { "3", "Benutzer-Chat 3" },
		[9] = { "4", "Benutzer-Chat 4" },
		[10] = { "5", "Benutzer-Chat 5" },
		[11] = { "6", "Benutzer-Chat 6" },
		[12] = { "7", "Benutzer-Chat 7" },
		[13] = { "8", "Benutzer-Chat 8" }
	}
end

_G.Bonus_Buffs = {
	-- Outnumbered
	["Lainedhels Ruf zu den Waffen"] = 10,
	["Akúlhuns Herausforderung"] = 10,
	-- Keeps
	["Tol Ascarnen"] = 50,
	["Lugazag"] = 10,
	["Tírith Rhaw"] = 10,
	["Holzfällerlager im Grimmwald"] = 35,
	["Isenbinge-Mine"] = 35,
	--Outposts
	["Kaltfelsen-Außenposten"] = 20,
	["Außenposten am Fluss"] = 20,
	["Außenposten in Aradors Ende"] = 20,
	["Außenposten der Isenbinge"] = 20,
	-- DoF
	["Gaergoth"] = 40,
	["Faulwurzel"] = 30,
	["Gwaelug"] = 30,
	-- Relics
	["Fragment von Mordiriths Krone"] = 50,
	["Wachsames Auge"] = 3,
	["Geschenk des Auges"] = 5,
	["Die Gabe der Carrock"] = 50,
	["Eine stille Ruhe"] = 3,
	["Ruhe und Stille"] = 5,
	-- Store
	["+100 % Zugewinn an Verrufenheit/Ansehen"] = 100,
	["+ 20 % Zugewinn an Verrufenheit"] = 20,
	["+ 20 % Zugewinn an Ansehen"] = 20,
	["Zum Ruhme von ..."] = 20
}

_G.Relic_Buffs = {
	[1] = "Fragment von Mordiriths Krone",
	[2] = "Wachsames Auge",
	[3] = "Geschenk des Auges",
	[4] = "Die Gabe der Carrock",
	[5] = "Eine stille Ruhe",
	[6] = "Ruhe und Stille"
}

_G.DoF_Buffs = {
	[1] = "Faulwurzel",
	[2] = "Gwaelug",
	[3] = "Gaergoth"
}

_G.Outnumbered_Buffs = {
	[1] = "Lainedhels Ruf zu den Waffen",
	[2] = "Akúlhuns Herausforderung"
}

_G.Towers = {
	["Tol Ascarnen"] = 1,
	["Isenbinge-Mine"] = 2,
	["Tírith Rhaw"] = 3,
	["Lugazag"] = 4,
	["Holzfällerlager im Grimmwald"] = 5,
	["Kaltfelsen-Außenposten"] = 6,
	["Außenposten in Aradors Ende"] = 7,
	["Außenposten am Fluss"] = 8,
	["Außenposten der Isenbinge"] = 9
}

_G.Keeps = {
	[1] = "Tol Ascarnen",
	[2] = "Isenbinge-Mine",
	[3] = "Tírith Rhaw",
	[4] = "Lugazag",
	[5] = "Holzfällerlager im Grimmwald"
}

_G.Keep_Acronyms = {
	["Tol Ascarnen"] = "TA",
	["Isenbinge-Mine"] = "IM",
	["Tírith Rhaw"] = "TR",
	["Lugazag"] = "LG",
	["Holzfällerlager im Grimmwald"] = "HG"
}

_G.Outpost_Acronyms = {
	["Kaltfelsen-Außenposten"] = "H",
	["Außenposten am Fluss"] = "F",
	["Außenposten in Aradors Ende"] = "A",
	["Außenposten der Isenbinge"] = "I"
}

_G.Map_Positions = {
	[1] = "Tol Ascarnen",
	[2] = "Isenbinge-Mine",
	[3] = "Tírith Rhaw",
	[4] = "Lugazag",
	[5] = "Holzfällerlager im Grimmwald",
	[6] = "Kaltfelsen-Außenposten",
	[7] = "Außenposten in Aradors Ende",
	[8] = "Außenposten am Fluss",
	[9] = "Außenposten der Isenbinge",
	[10] = "Gramfuß",
	[11] = "Dâr-gazag",
	[12] = "Ork-Lager",
	[13] = "Grothum",
	[14] = "Mazauk's Versteck",
	[15] = "Spinne Versteck",
	[16] = "Glân Vraig",
	[17] = "Feste Ringdyr",
	[18] = "Elben-Lager",
	[19] = "Weißsenke",
	[20] = "Golloval",
	[21] = "Goldschopf",
	[22] = "STAB",
	[23] = "WTAB",
	[24] = "BvF - Kaltfelsen-Außenposten",
	[25] = "BvF - Außenposten in Aradors Ende",
	[26] = "BvF - Außenposten am Fluss",
	[27] = "BvF - Außenposten der Isenbinge",
	[28] = "BvF - Dâr-gazag",
	[29] = "BvF - Ork-Lager",
	[30] = "BvF - Feste Ringdyr",
	[31] = "BvF - Elben-Lager",
	[32] = "Gaergoth",
	[33] = "Faulwurzel",
	[34] = "Gwaelug"
}

_G.Cardinal_Directions = {
	[1] = "N",
	[2] = "NE",
	[3] = "E",
	[4] = "SE",
	[5] = "S",
	[6] = "SO",
	[7] = "O",
	[8] = "NO"
}

_G.NPC_Names = {
	-- Quest NPC's
	[1] = "Bok",
	[2] = "Gasham",
	[3] = "Golloval",
	[4] = "Mazauk",
	[5] = "Caragdal",
	[6] = "Gorgoris",
	[7] = "Felsstreiter",
	-- DoF NPC's
	[8] = "Boldirith",
	[9] = "Gortheblin",
	[10] = "Gworvaethor",
	[11] = "Gâth",
	[12] = "Gúrhardron",
	[13] = "Húrlug",
	[14] = "Iachador",
	[15] = "Iarwen",
	[16] = "Malembor",
	[17] = "Nemornion",
	[18] = "Núrlug",
	[19] = "Raingorth",
	[20] = "Rimgurthil",
	[21] = "Thorliw",
	[22] = "Uidhelos",
	-- DoF Bosses
	[23] = "Faulwurzel"
}

L.Months = {
	[1] = "Jan",
	[2] = "Feb",
	[3] = "Mrz",
	[4] = "Apr",
	[5] = "Mai",
	[6] = "Jun",
	[7] = "Jul",
	[8] = "Aug",
	[9] = "Sep",
	[10] = "Okt",
	[11] = "Nov",
	[12] = "Dez"
}

L.Init_Frags = "Bitte gib Deine gesamten tödlichen Schläge ein:"
L.Init_Invalid_Input = "Falsche Eingabe!"

L.Window_Confirm = "OK"
L.Window_Save = "Speichern"
L.Window_Cancel = "Abbrechen"

L.Wallet_Commendations = "Anerkennung"

L.Stats_Bonus = "Bonus: "
L.Stats_Total_Points = "Gesamte " .. L.InfamyRenown .. ": "
L.Stats_Remaining_Points = L.InfamyRenown .. " zum Rang-Up: "
L.Stats_Total_Points_Short = L.InfamyRenown .. ": "
L.Stats_Remaining_Points_Short = "Rang-Up: "

L.Menu = { "Gesamt", "Rang-Up", "Monat", "Tag", "Stunde", "10 min", "Kampf" }
L.Stats_Total = "Gesamt: "
L.Stats_Current = "Aktuell: "
L.Stats_To_RankUp = "Zum Rang-Up: "
L.Stats_To_TierUp = "Zum Aufstieg: "

L.Stats_Last_Year = "Letztes Jahr"
L.Stats_Last_Month = "Letzter Monat"
L.Stats_Last_24h = "Letzte 24 Stunden: "
L.Stats_Today = "Heute: "

L.Stats_Current_Month = "Diesen Monat: "
L.Stats_Current_Day = "Diesen Tag: "
L.Stats_Last_Hour = "Letzte Stunde: "
L.Stats_Last_10min = "Letzte 10 Min: "
L.Stats_Last_Fight = "Letzter Kampf: "
L.Stats_Current_Month_Short = "Monat: "
L.Stats_Current_Day_Short = "Tag: "
L.Stats_Last_Hour_Short = "Stunde: "
L.Stats_Last_10min_Short = "10 Min: "
L.Stats_Last_Fight_Short = "Kampf: "

L.Statistics_Header = "Statistiken"
L.Progress_Header = "Fortschritt"
L.Stats_Rank = "Rang "
L.Stats_Tier = "Stufe "
L.Commendations_Header = "Anerkennungen"
L.KillingBlows_Header = "Tödliche Schläge"
L.Deaths_Header = "Tode"
L.Tracks_Header = "Tracks"

L.Tab_Statistics = "Charakter Statistiken"
L.Tab_Log = "Tödliche Schläge Log"
L.Tab_Points = L.InfamyRenown .. " Statistiken"
L.Tab_Commendations = "Anerkennungen Statistiken"
L.Tab_Killing_Blows = "Tödliche Schläge Statistiken"
L.Tab_Deaths = "Tode Statistiken"
L.Tab_Tracks = "Track Statistiken"

L.Log_Search = "Suche: "
L.Log_Name = "Name"
L.Log_KillingBlows = "Kills"

L.Stats_Maximum_Kill = "Maximal tödliche Schläge: "
L.Stats_Maximum_Day = "Maximal Tag: "
L.Stats_Maximum_Month = "Maximal Monat: "
L.Stats_Points_Per_KillingBlow = L.InfamyRenown .. " pro tödliche Schläge: "
L.Stats_KillingBlows_Per_Death = "Tödliche Schläge pro Tode: "

L.Recent_Hits_Header = "Letzte Treffer"
L.Recent_Hits_Link_Count = "Link Anzahl"
L.Recent_Hits_Amount = "Anzahl"

L.Recent_Kills_Header = "Letzte 5 Kills"
L.String_Loc = "Pos"
L.String_Send = "Senden"
L.Map_Show = "Karte anzeigen"
L.Map_Hide = "Karte ausblenden"
L.Get_Own_Position = "Eigene Position anzeigen"

L.Loc_Command = "/pos"
L.Loc_Chat = ";pos"

L.Chat_Location_String = "Ihr seid auf dem Server .* in r.*"
L.Chat_Heading_String = "Ihr seid auf dem Server .* in r.* h.*"
L.Chat_Pattern_String_1 = "Ihr seid auf dem Server .* in r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_2 = "Ihr seid auf dem Server .* in r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_3 = "Ihr seid auf dem Server .* in r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) ox(%d+%.?%d*) oy(%d+%.?%d*) oz(%d+%.?%d*)"
L.Chat_Pattern_String_4 = "Ihr seid auf dem Server .* in r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"

L.Chat_Room_Join = "Ihr habt den Raum '(.+)' betreten %(UserChat%d%)%. Anzahl der Mitglieder: %d+%."
L.Chat_Room_Leave = "Ihr habt den Raum '(.+)' verlassen"

L.Chat_Tracked = "Ihr habt das Gefühl, als würdet Ihr verfolgt ..."
L.Chat_Stealth_Nearby = "Ihr spürt, dass sich eine Kreatur in der Nähe befindet, könnt sie jedoch nicht sehen."
L.Chat_Stealth_Spotted = "Ihr habt eine herumschleichende Kreatur entdeckt."

L.Chat_Earned_Points = "Ihr habt "
L.Chat_Earned_Commendations_Start = "Erhalten.+%["
L.Chat_Earned_Commendations_End = " Anerkennungen]."
L.Chat_KillingBlow_Start = "Euer mächtiger Hieb lässt "
L.Chat_KillingBlow_End = " stürzen."
L.Chat_Defeated = " hat Euch außer Gefecht gesetzt."
L.Chat_Environment_Death = "Ihr wurdet durch ein Missgeschick ausser Gefecht gesetzt."
L.Chat_Damage_Hit = " gelang ein "
L.Chat_Damage_Avoid = " wollte "

L.Chat_Lootbox = "Schatzkästchen"
L.Chat_Key = "%[Schwarzer Stahlschlüssel]"
L.Chat_Appearance = "Aussehen"

L.Options_Header = "Einstellungen"
L.Options_Data_Settings = "Daten Einstellungen"
L.Options_Update_Points = L.InfamyRenown .. " setzen"
L.Options_Update_Frags = "Tödliche Schläge setzen"
L.Options_Display_Settings = "Anzeige Einstellungen"
L.Options_Show_Stats = "Statistiken Zeigen"
L.Options_Bonus = "% Multiplikator Anzeigen"
L.Options_OPs = "Außenposten Anzeigen"
L.Options_Keeps = "Festungen Anzeigen"
L.Options_DOF = "BvF Bonus Anzeigen"
L.Options_Relic = "Artefakte Anzeigen"
L.Options_ON = "UZ Bonus Anzeigen"
L.Options_Alert_Settings = "Alarm Einstellungen"
L.Options_Track_Warning = "Track Warnung"
L.Options_StealthAlert = "Schleich Warnung"
L.Options_YourFragAlert = "Tödliche Schläge Alarm"
L.Options_LootboxAlert = "Schatzkästchen Alarm"
L.Options_Commendation_Warning = "Anerk. Warnung"
L.Options_Battle_Task_Warning = "Schlacht Aufgabe Warnung"
L.Options_Other_Windows_Settings = "Sekundäre Fenster"
L.Options_Recent_Kills = "Letzte Kills Fenster"
L.Options_Recent_Hits = "Letzte Treffer Fenster"
L.Options_Other_Settings = "Andere Einstellungen"
L.Options_Daily_Reset_Time = "Tägliche Reset Zeit"
L.Options_Window_Size = "Fenstergröße"
L.Options_Reset = "Einstellungen zurücksetzen"
L.Options_Reset_Header = "Zurücksetzen"
L.Options_Reset_Warning = "Achtung!"
L.Options_Reset_Warning_Text = "Mit " .. L.Window_Confirm .. " werden alle Einstellungen zurückgesetzt!\n\nBist Du sicher, dass Du fortfahren möchtest?"
L.Options_Open_Settings = "Einstellungen öffnen"
L.Strings_Points_Out_Of_Sync = "Daten nicht mehr aktuell:\nBitte gib dein gesamtes " .. L.InfamyRenown .. " erneut ein"
L.Strings_Frags_Out_Of_Sync = "Daten nicht mehr aktuell:\nBitte gib deine gesamten tödlichen Schläge erneut ein"

L.DragBar_Overview = "PvMP+"
L.DragBar_Alert = "PvMP+ Warnungen"
L.DragBar_Battle_Task = "PvMP+ Schlacht Aufgabe"
L.DragBar_Recent_Hits_Window = "PvMP+ Letzte Treffer"
L.DragBar_Secondary_Window = "PvMP+ Letzte Kills"
L.DragBar_Map = "PvMP+ Karte"

L.Command_Help = "Einstellungen: /pvmp+ einstellungen | Karte: /pvmp+ karte"
L.Command_Settings = "einstellungen"
L.Command_Map = "karte"

L.YourFrag_Message_Start = "Euer mächtiger Hieb lässt "
L.YourFrag_Message_End = " stürzen! "
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