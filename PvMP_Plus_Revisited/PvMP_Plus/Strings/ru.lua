_G.L = {}

if (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Дурная слава"
	L.Chat_Points = " оч. дурной славы."
	L.FreepsCreeps = "Фрипов"
	L.FreepCreep = "Фрип"
	L.Battle_Task_Quest_Giver = "Slaughter the Free-folk"	-- Translate
	L.Battle_Task_Message = "Get a Battle Task you maggot!"	-- Translate
	_G.Rank_Names = {
		[0] = "Без рейтинга",
		[1] = "Ищейка",
		[2] = "Лазутчик",
		[3] = "Застрельщик",
		[4] = "Воин",
		[5] = "Боец",
		[6] = "Часовой",
		[7] = "Младший командир",
		[8] = "Командир бойцов",
		[9] = "Надсмотрщик",
		[10] = "Лейтенант",
		[11] = "Командор",
		[12] = "Военный вожак",
		[13] = "Верховный вожак",
		[14] = "Властелин",
		[15] = "Тиран"
	}
	_G.Tier_Names = {
		[0] = "Неизвестно",
		[1] = "Палач",
		[2] = "Гончая Мордирита",
		[3] = "Коса Скорби",
		[4] = "Погибель Света",
		[5] = "Рука Судьбы",
		[6] = "Бич Западных Земель",
		[7] = "Глашатай Тьмы",
		[8] = "Manifestation of Morgoth"	-- Translate
	}
	L.Chat_Channels = {
		[1] = {"say", "Сказать"},	-- Translate?
		[2] = {"f", "Братство"},	-- Translate?
		[3] = {"ra", "Рейд"},		-- Translate?
		[4] = {"tr", "Племя"},		-- Translate?
		[5] = {"ooc", "OOC"},		-- Translate?
		[6] = {"1", "Свой канал 1"},
		[7] = {"2", "Свой канал 2"},
		[8] = {"3", "Свой канал 3"},
		[9] = {"4", "Свой канал 4"},
		[10] = {"5", "Свой канал 5"},
		[11] = {"6", "Свой канал 6"},
		[12] = {"7", "Свой канал 7"},
		[13] = {"8", "Свой канал 8"}
	}
elseif (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer) then
	L.InfamyRenown = "Слава"
	L.Chat_Points = " оч. славы."
	L.FreepsCreeps = "Крипов"
	L.FreepCreep = "Крип"
	L.Battle_Task_Quest_Giver = "Against the Enemy"						-- Translate
	L.Battle_Task_Message = "Claim a Battle Task valliant defender!"	-- Translate
	_G.Rank_Names = {
		[0] = "Без рейтинга",
		[1] = "Footman",				-- Translate
		[2] = "Esquire",				-- Translate
		[3] = "Guardsman",				-- Translate
		[4] = "Man-at-Arms",			-- Translate
		[5] = "Sergeant of the Guard",	-- Translate
		[6] = "Sergeant-at-Arms",		-- Translate
		[7] = "Master Guardsman",		-- Translate
		[8] = "Master-at-Arms",			-- Translate
		[9] = "High Warden",			-- Translate
		[10] = "Lieutenant",			-- Translate
		[11] = "Commander",				-- Translate
		[12] = "Third Marshall",		-- Translate
		[13] = "Second Marshall",		-- Translate
		[14] = "First Marshall",		-- Translate
		[15] = "Captain-General"		-- Translate
	}
	_G.Tier_Names = {
		[0] = "Неизвестно",
		[1] = "Новобранец",
		[2] = "Воин",
		[3] = "Ветеран",
		[4] = "Военачальник",
		[5] = "Полководец",
		[6] = "Герой Эттенских высот", -- Героиня
		[7] = "Легендарный Герой", -- Легендарная Героиня
		[8] = "Saviour of Arda"			-- Translate
	}
	L.Chat_Channels = {
		[1] = {"say", "Сказать"},	-- Translate?
		[2] = {"f", "Братство"},	-- Translate?
		[3] = {"ra", "Рейд"},		-- Translate?
		[4] = {"k", "Содружество"},	-- Translate?
		[5] = {"ooc", "OOC"},		-- Translate?
		[6] = {"1", "Свой канал 1"},
		[7] = {"2", "Свой канал 2"},
		[8] = {"3", "Свой канал 3"},
		[9] = {"4", "Свой канал 4"},
		[10] = {"5", "Свой канал 5"},
		[11] = {"6", "Свой канал 6"},
		[12] = {"7", "Свой канал 7"},
		[13] = {"8", "Свой канал 8"}
	}
end

_G.Bonus_Buffs = {
	-- Outnumbered
	["Вдохновляющий клич Лайнедэла"] = 10,
	["Гнев Акулуна"] = 10,
	-- Keeps
	["Тол Аскарнен"] = 50,
	["Лугазаг"] = 10,
	["Тирит Роу"] = 10,
	["Лесопилка Мрачного леса"] = 35,
	["Изендипский рудник"] = 35,
	--Outposts
	["Застава в Холодных горах"] = 20,
	["Застава на реке"] = 20,
	["Застава в Арадорском тупике"] = 20,
	["Застава в Изендипском руднике"] = 20,
	-- DoF
	["Гаэргот"] = 40,
	["Гнилой Корень"] = 30,
	["Гродрис"] = 30,
	-- Relics
	["Осколок короны Мордирита"] = 50,
	["Пристальный взор"] = 3,
	["Дар Ока"] = 5,
	["Дар Каррока"] = 50,
	["Тишина и покой"] = 3,
	["Мир и тишина"] = 5,
	-- Store
	["+100% к славе и дурной славе"] = 100,
	["+20% к дурной славе"] = 20,
	["+20% к славе"] = 20,
	["Настойки 'Во славу..."] = 20
}

_G.Relic_Buffs = {
	[1] = "Осколок короны Мордирита",
	[2] = "Пристальный взор",
	[3] = "Дар Ока",
	[4] = "Дар Каррока",
	[5] = "Тишина и покой",
	[6] = "Мир и тишина"
}

_G.DoF_Buffs = {
	[1] = "Гнилой Корень",
	[2] = "Гродрис",
	[3] = "Гаэргот"
}

_G.Outnumbered_Buffs = {
	[1] = "Вдохновляющий клич Лайнедэла",
	[2] = "Гнев Акулуна"
}

_G.Towers = {
	["Тол Аскарнен"] = 1,
	["Изендипский рудник"] = 2,
	["Тирит Роу"] = 3,
	["Лугазаг"] = 4,
	["Лесопилка Мрачного леса"] = 5,
	["Застава в Холодных горах"] = 6,
	["Застава в Арадорском тупике"] = 7,
	["Застава на реке"] = 8,
	["Застава в Изендипском руднике"] = 9
}

_G.Keeps = {
	[1] = "Тол Аскарнен",
	[2] = "Изендипский рудник",
	[3] = "Тирит Роу",
	[4] = "Лугазаг",
	[5] = "Лесопилка Мрачного леса"
}

_G.Keep_Acronyms = {
	["Тол Аскарнен"] = "TA",
	["Изендипский рудник"] = "ИР",
	["Тирит Роу"] = "TP",
	["Лугазаг"] = "ЛГ",
	["Лесопилка Мрачного леса"] = "ЛМ"
}

_G.Outpost_Acronyms = {
	["Застава в Холодных горах"] = "X",
	["Застава на реке"] = "P",
	["Застава в Арадорском тупике"] = "A",
	["Застава в Изендипском руднике"] = "И"
}

_G.Map_Positions = {
	[1] = "Тол Аскарнен",
	[2] = "Изендипский рудник",
	[3] = "Тирит Роу",
	[4] = "Лугазаг",
	[5] = "Лесопилка Мрачного леса",
	[6] = "Застава в Хитладе",
	[7] = "Застава в Арадорском тупике",
	[8] = "Застава на реке",
	[9] = "Застава в Изендипском руднике",
	[10] = "Подножие Грэм",
	[11] = "Дар-Газаг",
	[12] = "Орочий лагерь",
	[13] = "Гротум",
	[14] = "Mazauk's Den",							-- Translate
	[15] = "Spider Den",							-- Translate
	[16] = "Глан Врайг",
	[17] = "Ост Рингдир",
	[18] = "Эльфийский лагерь",
	[19] = "Седая котловина",
	[20] = "Golloval",								-- Translate
	[21] = "Goldhead",								-- Translate
	[22] = "STAB",									-- Translate
	[23] = "WTAB",									-- Translate
	[24] = "КФ - Застава в Хитладе",
	[25] = "КФ - Застава в Арадорском тупике",
	[26] = "КФ - Застава на реке",
	[27] = "КФ - Застава в Изендипском руднике",
	[28] = "КФ - Дар-Газаг",
	[29] = "КФ - Орочий лагерь",
	[30] = "КФ - Ост Рингдир",
	[31] = "КФ - Эльфийский лагерь",
	[32] = "Гаэргот",
	[33] = "Гнилой Корень",
	[34] = "Гродрис"
}

_G.Cardinal_Directions = {
	[1] = "С",
	[2] = "СВ",
	[3] = "В",
	[4] = "ЮВ",
	[5] = "Ю",
	[6] = "ЮЗ",
	[7] = "З",
	[8] = "СЗ"
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
	[22] = "Uidhelos"
}

L.Months = {
	[1] = "Янв",
	[2] = "Фев",
	[3] = "Мар",
	[4] = "Апр",
	[5] = "Май",
	[6] = "Июн",
	[7] = "Июл",
	[8] = "Авг",
	[9] = "Сен",
	[10] = "Окт",
	[11] = "Ноя",
	[12] = "Дек"
}

L.Init_Points = "Введите текущее значение " .. L.InfamyRenown .. ":"
L.Init_Frags = "Введите текущее значение Смертельные удары:"
L.Init_Invalid_Input = "Неправильный ввод!"

L.Window_Confirm = "ОК"
L.Window_Save = "Save"	-- Translate
L.Window_Cancel = "Отменить"

L.Wallet_Commendations = "Очки судьбы"

L.Stats_Bonus = "Бонус: "
L.Stats_Total_Points = "Всего " .. L.InfamyRenown .. ": "
L.Stats_Remaining_Points = L.InfamyRenown .. " до следующего Ранга: "
L.Stats_Total_Points_Short = L.InfamyRenown .. ": "
L.Stats_Remaining_Points_Short = "До Ранга: "

L.Menu = { "Всего", "До Ранга", "месяц", "День", "Час", "10 мин", "Бой" }
L.Stats_Points_Type = "Моя " .. L.InfamyRenown .. ": "
L.Stats_Total = "Всего: "
L.Stats_Current = "Текущий: "
L.Stats_To_RankUp = "До следующего Ранга: "
L.Stats_To_TierUp = "До следующего Ярус: "

L.Stats_Last_Year = "За посл. год"
L.Stats_Last_Month = "За посл. месяц"
L.Stats_Last_24h = "За сутки: "
L.Stats_Today = "Сегодня: "

L.Stats_Current_Month = "За текущий месяц: "
L.Stats_Current_Day = "За текущий день: "
L.Stats_Last_Hour = "За посл. час: "
L.Stats_Last_10min = "За посл. 10 мин: "
L.Stats_Last_Fight = "За посл. бой: "
L.Stats_Current_Month_Short = "месяц: "
L.Stats_Current_Day_Short = "День: "
L.Stats_Last_Hour_Short = "Час: "
L.Stats_Last_10min_Short = "10 мин: "
L.Stats_Last_Fight_Short = "Бой: "

L.Statistics_Header = "Статистика"
L.Progress_Header = "Прогресс"
L.Stats_Rank = "Ранг "
L.Stats_Tier = "Ярус "
L.Commendations_Header = "Очки судьбы"
L.KillingBlows_Header = "Смертельные удары"
L.Deaths_Header = "Смертей"
L.Tracks_Header = "Трэки"

L.Tab_Statistics = "Персонаж Статистика"
L.Tab_Log = "Смертельные удары Реестр"
L.Tab_Points = L.InfamyRenown .. " Статистика"
L.Tab_Commendations = "Очки судьбы Статистика"
L.Tab_Killing_Blows = "Смертельные удары Статистика"
L.Tab_Deaths = "Смертей Статистика"
L.Tab_Tracks = "Трэки Статистика"

L.Log_Search = "Поиск: "
L.Log_Name = "Имя"
L.Log_KillingBlows = "Убийства"

L.Stats_Maximum_Kill = "Максимум Смертельные удары: "
L.Stats_Maximum_Day = "Максимум День: "
L.Stats_Maximum_Month = "Максимум месяц: "
L.Stats_Points_Per_KillingBlow = L.InfamyRenown .. " за Смертельные удары: "
L.Stats_KillingBlows_Per_Death = "Смертельные удары за Смертей: "

L.Recent_Hits_Header = "недавние хиты"
L.Recent_Hits_Link_Count = "Количество ссылок"
L.Recent_Hits_Amount = "Кол-во"

L.Recent_Kills_Header = "Послед. 5 жертв"
L.String_Loc = "Loc"	-- Translate
L.String_Send = "Отпр."
L.Map_Show = "Показать карту"
L.Map_Hide = "Скрыть карту"
L.Get_Own_Position = "Показать свою позицию"

L.Loc_Command = "/loc"	-- Translate
L.Loc_Chat = ";loc"		-- Translate

L.Chat_Location_String = "Ваше местонахождение: r.*"
L.Chat_Heading_String = "Ваше местонахождение: r.* h.*"
L.Chat_Pattern_String_1 = "Ваше местонахождение: r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_2 = "Ваше местонахождение: r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
L.Chat_Pattern_String_3 = "Ваше местонахождение: r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) ox(%d+%.?%d*) oy(%d+%.?%d*) oz(%d+%.?%d*)"
L.Chat_Pattern_String_4 = "Ваше местонахождение: r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"

L.Chat_Room_Join = "Вы вошли на канал '(.+)' %(UserChat%d%)%. Количество присутствующих: %d+%."
L.Chat_Room_Leave = "Вы покинули канал '(.+)'"

L.Chat_Tracked = "Вы чувствуете, что за вами кто-то следит..."
L.Chat_Stealth_Nearby = "Вы чувствуете, что поблизости незаметно крадется какое-то создание."
L.Chat_Stealth_Spotted = "You have spotted a creature attempting to move stealthily about."	-- Translate

L.Chat_Earned_Points = "Заработано "
L.Chat_Earned_Commendations_Start = "Получено.+%[Очки судьбы %("
L.Chat_Earned_Commendations_End = "%)]."
L.Chat_KillingBlow_Start = ""
L.Chat_KillingBlow_End = " падает под вашим безжалостным натиском."
L.Chat_Defeated = " incapacitated you."	-- Translate
L.Chat_Environment_Death = "You have been incapacitated by misadventure."	-- Translate
L.Chat_Damage_Hit = " scored a "	-- Translate
L.Chat_Damage_Avoid = " tried to use "	-- Translate

L.Chat_Lootbox = "ларец"
L.Chat_Key = "%[Крепкий стальной ключ]"
L.Chat_Appearance = "Облик"

L.Options_Header = "Настройки"
L.Options_Data_Settings = "Данные Настройки"
L.Options_Update_Points = "Установить " .. L.InfamyRenown
L.Options_Update_Frags = "Установить Смертельные удары"
L.Options_Display_Settings = "Настройки экрана"
L.Options_Show_Stats = "Статистика"
L.Options_Bonus = "Показывать Бонус"
L.Options_OPs = "Показывать Застава"
L.Options_Keeps = "Show Keeps"	-- Translate
L.Options_DOF = "Show DoF"		-- Translate
L.Options_Relic = "Show Relics"	-- Translate
L.Options_ON = "Show ON Buff"	-- Translate
L.Options_Alert_Settings = "Настройки уведомлений"
L.Options_Track_Warning = "Предупредить о треке"
L.Options_StealthAlert = "Скрытые враги"
L.Options_YourFragAlert = "Уведомлять о фрагах"
L.Options_LootboxAlert = "Ларцы/Ключи"
L.Options_Commendation_Warning = "Мигающее Очки судьбы предупреждение"
L.Options_Battle_Task_Warning = "Battle Task Warning"	-- Translate
L.Options_Other_Windows_Settings = "Вторичные окна"
L.Options_Recent_Kills = "Показать Посл. жертвы"
L.Options_Recent_Hits = "Показать Последние хиты"
L.Options_Other_Settings = "Другие настройки"
L.Options_Daily_Reset_Time = "Время обновления"
L.Options_Window_Size = "Размер панели"
L.Options_Reset = "Сброс Настройки"
L.Options_Reset_Header = "Сброс"
L.Options_Reset_Warning = "Внимание!"
L.Options_Reset_Warning_Text = "Нажатие " .. L.Window_Confirm .. " сбросит все настройки!\n\nВы уверены что хотите продолжить?"
L.Options_Open_Settings = "Открыть настройки"
L.Strings_Points_Out_Of_Sync = "Нужна синхронизация:\nВведите текущее значение " .. L.InfamyRenown
L.Strings_Frags_Out_Of_Sync = "Нужна синхронизация:\nВведите текущее значение Смертельные удары"

L.DragBar_Overview = "PvMP+"
L.DragBar_Alert = "PvMP+ Предупреждение"
L.DragBar_Battle_Task = "PvMP+ Battle Task"	-- Translate
L.DragBar_Recent_Hits_Window = "PvMP+ Последние хиты"
L.DragBar_Secondary_Window = "PvMP+ Посл. жертвы"
L.DragBar_Map = "PvMP+ Карта"

L.Command_Help = "Настройки: /pvmp+ settings | Карта: /pvmp+ map"
L.Command_Settings = "settings"	-- Translate?
L.Command_Map = "map"			-- Translate?

L.YourFrag_Message_Start = ""
L.YourFrag_Message_End = " падает под вашим безжалостным натиском! "
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