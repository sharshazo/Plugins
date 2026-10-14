_G.L = {}

if (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Infamie"
	L.Init_Points = "Veuillez saisir votre total d'" .. L.InfamyRenown .. ":"
	L.Chat_Points = " points d'infamie."
	L.FreepsCreeps = "Héros"
	L.FreepCreep = "Héro"
	L.Battle_Task_Quest_Giver = "Massacrer les membres des Peuples Libres"
	L.Battle_Task_Message = "Obtenez une Objectif de combat, tu asticot!"
	_G.Rank_Names = {
		[0] = "Sans Grade",
		[1] = "Pisteur", -- Pisteuse
		[2] = "Eclaireur", -- Eclaireuse
		[3] = "Franc-Tireur", -- Franc-Tireuse
		[4] = "Combattant", -- Combattante
		[5] = "Soldat",
		[6] = "Sentinelle",
		[7] = "Garde en Chef",
		[8] = "Guerrier en Chef", -- Guerrière en chef
		[9] = "Maître-Fouet", -- Maîtresse-Fouet
		[10] = "Lieutenant",
		[11] = "Commandant",
		[12] = "Chef",
		[13] = "Grand Chef",
		[14] = "Suzerain", -- Suzeraine
		[15] = "Tyran"
	}
	_G.Tier_Names = {
		[0] = "Inconnue",
		[1] = "Le Tourmenteur",
		[2] = "Chien Noir",
		[3] = "Cueille-Sanglots",
		[4] = "Tueur de Lumière",
		[5] = "l'Instrument du Destin",
		[6] = "Fléau de l'Ouest",
		[7] = "Messager des Ténèbres",
		[8] = "Manifestation de Morgoth"
	}
	L.Chat_Channels = {
		[1] = { "parler", "Parler" },
		[2] = { "f", "Groupe" },
		[3] = { "ra", "Raid" },
		[4] = { "tr", "Tribu" },
		[5] = { "hdp", "HDP" },
		[6] = { "1", "Chat Utilisateur 1" },
		[7] = { "2", "Chat Utilisateur 2" },
		[8] = { "3", "Chat Utilisateur 3" },
		[9] = { "4", "Chat Utilisateur 4" },
		[10] = { "5", "Chat Utilisateur 5" },
		[11] = { "6", "Chat Utilisateur 6" },
		[12] = { "7", "Chat Utilisateur 7" },
		[13] = { "8", "Chat Utilisateur 8" }
	}
elseif (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Renommée"
	L.Init_Points = "Veuillez saisir votre total de " .. L.InfamyRenown .. ":"
	L.Chat_Points = " points de renommée."
	L.FreepsCreeps = "Monstres"
	L.FreepCreep = "Monstre"
	L.Battle_Task_Quest_Giver = "Contre l'ennemi"
	L.Battle_Task_Message = "Réclamer une Objectif de combat!"
	_G.Rank_Names = {
		[0] = "Sans Grade",
		[1] = "Fantassin",
		[2] = "Ecuyer", -- Ecuyère
		[3] = "Garde",
		[4] = "Homme d'Arme", -- Femme d'Arme
		[5] = "Sergent de la Garde",
		[6] = "Sergent d'Armes",
		[7] = "Maître-Garde", -- Maîtresse-Garde
		[8] = "Maître d'Arme", -- Maîtresse d'Arme
		[9] = "Veilleur en Chef", -- Veilleuse en Chef
		[10] = "Lieutenant",
		[11] = "Commandant",
		[12] = "Troisième Maréchal",
		[13] = "Second Maréchal",
		[14] = "Premier Maréchal",
		[15] = "Capitaine-Général"
	}
	_G.Tier_Names = {
		[0] = "Inconnue",
		[1] = "Néophyte",
		[2] = "Guerrier",
		[3] = "Vétéran",
		[4] = "Maître de Guerre",
		[5] = "Prince de Guerre",
		[6] = "Héros des Landes d'Etten",
		[7] = "Héros Légendaire",
		[8] = "Sauveur d'Arda"
	}
	L.Chat_Channels = {
		[1] = { "parler", "Parler" },
		[2] = { "f", "Communauté" },
		[3] = { "ra", "Raid" },
		[4] = { "k", "Confrérie" },
		[5] = { "hdp", "HDP" },
		[6] = { "1", "Chat Utilisateur 1" },
		[7] = { "2", "Chat Utilisateur 2" },
		[8] = { "3", "Chat Utilisateur 3" },
		[9] = { "4", "Chat Utilisateur 4" },
		[10] = { "5", "Chat Utilisateur 5" },
		[11] = { "6", "Chat Utilisateur 6" },
		[12] = { "7", "Chat Utilisateur 7" },
		[13] = { "8", "Chat Utilisateur 8" }
	}
end

_G.Bonus_Buffs = {
	-- Outnumbered
	["Appel aux armes de lainedhal"] = 10,
	["Défi d'Akulhun"] = 10,
	-- Keeps
	["Tol Ascarnen"] = 50,
	["Lugazag"] = 10,
	["Tírith Rhaw"] = 10,
	["Camp de bûcherons du Bois Funeste"] = 35,
	["Mine du Gouffre d'Isen"] = 35,
	--Outposts
	["Avant-poste des Monts Froids"] = 20,
	["Avant-poste de la rivière"] = 20,
	["Avant-poste de la Muraille d'Arador"] = 20,
	["Avant-poste du Gouffre d'Isen"] = 20,
	-- DoF
	["Gaergoth"] = 40,
	["Racinepourrie"] = 30,
	["Gwaelug"] = 30,
	-- Relics
	["Fragment de la couronne de Mordirith"] = 50,
	["Surveillance attentive"] = 3,
	["Don de l'Œil"] = 5,
	["Cadeau du Carrock"] = 50,
	["Un calme silencieux"] = 3,
	["Calme reposant"] = 5,
	-- Store
	["+100% de gains d'infamie/de renommée"] = 100,
	["Infamie +20%"] = 20,
	["Renommée +20%"] = 20,
	["Pour la gloire de..."] = 20
}

_G.Relic_Buffs = {
	[1] = "Fragment de la couronne de Mordirith",
	[2] = "Surveillance attentive",
	[3] = "Don de l'Œil",
	[4] = "Cadeau du Carrock",
	[5] = "Un calme silencieux",
	[6] = "Calme reposant"
}

_G.DoF_Buffs = {
	[1] = "Racinepourrie",
	[2] = "Gwaelug",
	[3] = "Gaergoth"
}

_G.Outnumbered_Buffs = {
	[1] = "Appel aux armes de lainedhal",
	[2] = "Défi d'Akulhun"
}

_G.Towers = {
	["Tol Ascarnen"] = 1,
	["Mine du Gouffre d'Isen"] = 2,
	["Tírith Rhaw"] = 3,
	["Lugazag"] = 4,
	["Camp de bûcherons du Bois Funeste"] = 5,
	["Avant-poste des Monts Froids"] = 6,
	["Avant-poste de la Muraille d'Arador"] = 7,
	["Avant-poste de la rivière"] = 8,
	["Avant-poste du Gouffre d'Isen"] = 9
}

_G.Keeps = {
	[1] = "Tol Ascarnen",
	[2] = "Mine du Gouffre d'Isen",
	[3] = "Tírith Rhaw",
	[4] = "Lugazag",
	[5] = "Camp de bûcherons du Bois Funeste"
}

_G.Keep_Acronyms = {
	["Tol Ascarnen"] = "TO",
	["Mine du Gouffre d'Isen"] = "MI",
	["Tírith Rhaw"] = "TR",
	["Lugazag"] = "LU",
	["Camp de bûcherons du Bois Funeste"] = "BU"
}

_G.Outpost_Acronyms = {
	["Avant-poste des Monts Froids"] = "S",
	["Avant-poste de la rivière"] = "R",
	["Avant-poste de la Muraille d'Arador"] = "A",
	["Avant-poste du Gouffre d'Isen"] = "M"
}

_G.Map_Positions = {
	[1] = "Tol Ascarnen",
	[2] = "Mine du Gouffre d'Isen",
	[3] = "Tírith Rhaw",
	[4] = "Lugazag",
	[5] = "Camp de bûcherons du Bois Funeste",
	[6] = "Avant-poste des Monts Froids",
	[7] = "Avant-poste de la Muraille d'Arador",
	[8] = "Avant-poste de la rivière",
	[9] = "Avant-poste du Gouffre d'Isen",
	[10] = "Pied de Gram",
	[11] = "Dâr-gazag",
	[12] = "Camp d'Orques",
	[13] = "Grothum",
	[14] = "Repaire de Mazauk",
	[15] = "Repaire d'Araignées",
	[16] = "Glân Vraig",
	[17] = "Ost Ringdyr",
	[18] = "Camp d'Elfes",
	[19] = "Sacregris",
	[20] = "Golloval",
	[21] = "Têtedor",
	[22] = "STAB",
	[23] = "WTAB",
	[24] = "CdF - Avant-poste des Monts Froids",
	[25] = "CdF - Avant-poste de la Muraille d'Arador",
	[26] = "CdF - Avant-poste de la rivière",
	[27] = "CdF - Avant-poste du Gouffre d'Isen",
	[28] = "CdF - Dâr-gazag",
	[29] = "CdF - Camp d'Orques",
	[30] = "CdF - Ost Ringdyr",
	[31] = "CdF - Camp d'Elfes",
	[32] = "Gaergoth",
	[33] = "Racinepourrie",
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
	[7] = "Fanepierre",
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
	[23] = "Racinepourrie"
}

L.Months = {
	[1] = "Jan",
	[2] = "Fév",
	[3] = "Mar",
	[4] = "Avr",
	[5] = "Mai",
	[6] = "Jun",
	[7] = "Jui",
	[8] = "Aoû",
	[9] = "Sep",
	[10] = "Oct",
	[11] = "Nov",
	[12] = "Déc"
}

L.Init_Frags = "Veuillez saisir votre total de Coups Mortels:"
L.Init_Invalid_Input = "Mauvaise Saisie!"

L.Window_Confirm = "OK"
L.Window_Save = "Sauve"
L.Window_Cancel = "Annuler"

L.Wallet_Commendations = "Citation"

L.Stats_Bonus = "Bonus: "
L.Stats_Total_Points = "Total " .. L.InfamyRenown .. ": "
L.Stats_Remaining_Points = L.InfamyRenown .. " prochain Grade: "
L.Stats_Total_Points_Short = L.InfamyRenown .. ": "
L.Stats_Remaining_Points_Short = "Prochain Grade: "

L.Menu = { "Total", "Prochain Grade", "Mois", "Aujourd'hui", "Heure", "10 min", "Combat" }
L.Stats_Points_Type = "Mon " .. L.InfamyRenown .. ": "
L.Stats_Total = "Total: "
L.Stats_Current = "Actuelle: "
L.Stats_To_RankUp = "Prochain Grade: "
L.Stats_To_TierUp = "Prochain Niveau: "

L.Stats_Last_Year = "Année Dernière"
L.Stats_Last_Month = "Mois Dernier"
L.Stats_Last_24h = "Dernières 24 Heures: "
L.Stats_Today = "Aujourd'hui: "

L.Stats_Current_Month = "Mois en Cours: "
L.Stats_Current_Day = "Aujourd'hui: "
L.Stats_Last_Hour = "Dernière Heure: "
L.Stats_Last_10min = "10 Dernières Min: "
L.Stats_Last_Fight = "Dernier Combat: "
L.Stats_Current_Month_Short = "Mois: "
L.Stats_Current_Day_Short = "Jour: "
L.Stats_Last_Hour_Short = "Heure: "
L.Stats_Last_10min_Short = "10 Min: "
L.Stats_Last_Fight_Short = "Combat: "

L.Statistics_Header = "Statistiques"
L.Progress_Header = "Progrès"
L.Stats_Rank = "Grade "
L.Stats_Tier = "Niveau "
L.Commendations_Header = "Citations"
L.KillingBlows_Header = "Coups Mortels"
L.Deaths_Header = "Morts"
L.Tracks_Header = "Traques"

L.Tab_Statistics = "Personnage Statistiques"
L.Tab_Log = "Coups Mortels Registre"
L.Tab_Points = L.InfamyRenown .. " Statistiques"
L.Tab_Commendations = "Citation Statistiques"
L.Tab_Killing_Blows = "Coups Mortels Statistiques"
L.Tab_Deaths = "Mort Statistiques"
L.Tab_Tracks = "Traque Statistiques"

L.Log_Search = "Recherche: "
L.Log_Name = "Nom"
L.Log_KillingBlows = "Tués"

L.Stats_Maximum_Kill = "Maximum Coup Mortel: "
L.Stats_Maximum_Day = "Maximum Jour: "
L.Stats_Maximum_Month = "Maximum Mois: "
L.Stats_Points_Per_KillingBlow = L.InfamyRenown .. " par Coup Mortels: "
L.Stats_KillingBlows_Per_Death = "Coups Mortels par Mort: "

L.Recent_Hits_Header = "Hits récents"
L.Recent_Hits_Link_Count = "Nombre de liens"
L.Recent_Hits_Amount = "Alerte"

L.Recent_Kills_Header = "5 Dernières Tués"
L.String_Loc = "Emp"
L.String_Send = "Envoi"
L.Map_Show = "Montrer la carte"
L.Map_Hide = "Masquer la carte"
L.Get_Own_Position = "Montrer ma position"

L.Loc_Command = "/emp"
L.Loc_Chat = ";emp"

L.Chat_Location_String = "Vous vous trouvez sur %a+, serveur %d+, à r.*"
L.Chat_Heading_String = "Vous vous trouvez sur %a+, serveur %d+, à r.* h.*"
L.Chat_Pattern_String_1 = "Vous vous trouvez sur %a+, serveur %d+, à r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_2 = "Vous vous trouvez sur %a+, serveur %d+, à r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_3 = "Vous vous trouvez sur %a+, serveur %d+, à r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) ox(%d+%.?%d*) oy(%d+%.?%d*) oz(%d+%.?%d*)"
L.Chat_Pattern_String_4 = "Vous vous trouvez sur %a+, serveur %d+, à r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"

L.Chat_Room_Join = "Vous avez rejoint le salon '(.+)' %(UserChat%d%)%. Nombre de membres : %d+%."
L.Chat_Room_Leave = "Vous avez quitté le salon (.+)'"

L.Chat_Tracked = "Vous avez l'impression que l'on vous suit..."
L.Chat_Stealth_Nearby = "Vous sentez qu'une créature est proche mais cachée à votre vue."
L.Chat_Stealth_Spotted = "Vous avez repéré une créature qui essayait de se déplacer de manière furtive."

L.Chat_Earned_Points = "Vous avez gagné "
L.Chat_Earned_Commendations_Start = "Vous avez obtenu .+%["
L.Chat_Earned_Commendations_End = " Citations]."
L.Chat_KillingBlow_Start = "Votre coup puissant renverse "
L.Chat_KillingBlow_End = "%."
L.Chat_Defeated = " a réussi à vous mettre hors de combat."
L.Chat_Environment_Death = "Un incident vous a réduit à l'impuissance"
L.Chat_Damage_Hit = " a infligé "
L.Chat_Damage_Avoid = " a essayé d'utiliser "

L.Chat_Lootbox = "Coffre à butin"
L.Chat_Key = "%[Clé en acier noir]"
L.Chat_Appearance = "Apparence"

L.Options_Header = "Options"
L.Options_Data_Settings = "Options Données"
L.Options_Update_Points = "Renseigner " .. L.InfamyRenown
L.Options_Update_Frags = "Renseigner Coups Mortels"
L.Options_Display_Settings = "Paramètres d'Affichage"
L.Options_Show_Stats = "Barre de Statistiques"
L.Options_Bonus = "Montrer Gains"
L.Options_OPs = "Barre de Avant-postes"
L.Options_Keeps = "Barre de Forts"
L.Options_DOF = "Barre de CdF Bonus"
L.Options_Relic = "Barre de Reliques"
L.Options_ON = "Barre de ON Bonus"	-- Translate
L.Options_Alert_Settings = "Paramètres d'Alerte"
L.Options_Track_Warning = "Alerte de Piste"
L.Options_StealthAlert = "Alerte de Proche"
L.Options_YourFragAlert = "Commentaires de Kills"
L.Options_LootboxAlert = "Alerte sur Coffre"
L.Options_Commendation_Warning = "Alerte Max. Citations"
L.Options_Battle_Task_Warning = "Alerte Objectif de Combat"
L.Options_Other_Windows_Settings = "Fenêtres Secondaires"
L.Options_Recent_Kills = "Fenêtre Dernières Tués"
L.Options_Recent_Hits = "Fenêtre des Hits Récents"
L.Options_Other_Settings = "Autres Paramètres"
L.Options_Daily_Reset_Time = "Heure de Remise"
L.Options_Window_Size = "Longueur de la Barre"
L.Options_Reset = "Réinitialiser les Paramètres"
L.Options_Reset_Header = "Réinitialiser"
L.Options_Reset_Warning = "Attention!"
L.Options_Reset_Warning_Text = "Appuyez sur " .. L.Window_Confirm .. " pour réinitialiser tous les paramètres!\n\nEs-tu sur de vouloir continuer?"
L.Options_Open_Settings = "Panneau des options"
L.Strings_Points_Out_Of_Sync = "Données désynchronisées:\nVeuillez réintroduire votre total de " .. L.InfamyRenown
L.Strings_Frags_Out_Of_Sync = "Données désynchronisées:\nVeuillez réintroduire votre total de Coups Mortels"

L.DragBar_Overview = "PvMP+"
L.DragBar_Alert = "PvMP+ Alertes"
L.DragBar_Battle_Task = "PvMP+ Objectif de Combat"
L.DragBar_Recent_Hits_Window = "PvMP+ Hits Récents"
L.DragBar_Secondary_Window = "PvMP+ Dernières Tués"
L.DragBar_Map = "PvMP+ Carte"

L.Command_Help = "Paramètres: /pvmp+ paramètres | Carte: /pvmp+ carte"
L.Command_Settings = "paramètres"
L.Command_Map = "carte"

L.YourFrag_Message_Start = "Votre coup puissant renverse "
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