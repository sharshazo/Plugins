StatsWindow = class(Turbine.UI.Lotro.Window)

local alphabetical_desc	= { ["enum"] = 0, ["funct"] = function(w1,w2) return w1.Name:GetText() < w2.Name:GetText() end }
local alphabetical_asc	= { ["enum"] = 1, ["funct"] = function(w1,w2) return w1.Name:GetText() > w2.Name:GetText() end }
local frags_desc		= { ["enum"] = 2, ["funct"] = function(w1,w2) return tonumber((w1.Kills:GetText():gsub("%." , ""))) > tonumber((w2.Kills:GetText():gsub("%." , ""))) end }
local frags_asc			= { ["enum"] = 3, ["funct"] = function(w1,w2) return tonumber((w1.Kills:GetText():gsub("%." , ""))) < tonumber((w2.Kills:GetText():gsub("%." , ""))) end }

function StatsWindow:Constructor()
	local width	= 300
	local height = 575

	Turbine.UI.Lotro.Window.Constructor(self)

	self:SetSize(width, height)
	self:SetPosition(data.numbers.statsWin_x, data.numbers.statsWin_y)
	self:SetZOrder(1)
	self:SetText(L.Statistics_Header)
	self:SetWantsKeyEvents(true)

	-- Tabs
	self.tab_stats = Tab(
		self, L.Tab_Statistics, 1, 0, "PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/stats.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/stats_mouseover.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/stats_selected.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/stats_selected_mouseover.tga"
	)
	self.tab_killList = Tab(
		self, L.Tab_Log, 2, 1, "PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/kills.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/kills_mouseover.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/kills_selected.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/kills_selected_mouseover.tga"
	)
	self.tab_barChartPoints = Tab(
		self, L.Tab_Points, 3, 2, "PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_mouseover.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected_mouseover.tga"
	)
	self.tab_barChartComms = Tab(
		self, L.Tab_Commendations, 4, 3, "PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_mouseover.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected_mouseover.tga"
	)
	self.tab_barChartFrags = Tab(
		self, L.Tab_Killing_Blows, 5, 4, "PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_mouseover.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected_mouseover.tga"
	)
	self.tab_barChartDeaths = Tab(
		self, L.Tab_Deaths, 6, 5, "PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_mouseover.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected_mouseover.tga"
	)
	self.tab_barChartTracks = Tab(
		self, L.Tab_Tracks, 7, 6, "PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_mouseover.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected.tga",
		"PvMP_Plus_Revisited/PvMP_Plus/Resources/Tabs/barChart_selected_mouseover.tga"
	)

	self.label_active_tab = Turbine.UI.Label()
	self.label_active_tab:SetParent(self)
	self.label_active_tab:SetSize(self:GetWidth() - 45, 15)
	self.label_active_tab:SetPosition(self:GetWidth() / 2 - self.label_active_tab:GetWidth() / 2, 65)
	self.label_active_tab:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.label_active_tab:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_active_tab:SetTextAlignment(Turbine.UI.ContentAlignment.BottomCenter)

	self.label_tabs = Turbine.UI.Label()
	self.label_tabs:SetParent(self)
	self.label_tabs:SetSize(self:GetWidth() - 45, 15)
	self.label_tabs:SetPosition(self:GetWidth() / 2 - self.label_tabs:GetWidth() / 2, 65)
	self.label_tabs:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.label_tabs:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_tabs:SetTextAlignment(Turbine.UI.ContentAlignment.BottomCenter)

	-- Statistics Panel
	self.stats_panel = Turbine.UI.Control()
	self.stats_panel:SetParent(self)
	self.stats_panel:SetSize(self:GetWidth() - 50, self:GetHeight() - 90)
	self.stats_panel:SetPosition(self:GetWidth() / 2 - self.stats_panel:GetWidth() / 2, 85)


	-- Rank Labels
	self.label_progress = Turbine.UI.Label()
	self.label_progress:SetParent(self.stats_panel)
	self.label_progress:SetSize(self.stats_panel:GetWidth(), 20)
	self.label_progress:SetPosition(0, 0)
	self.label_progress:SetForeColor(Default_Font_Color)
	self.label_progress:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_progress:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_progress:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_progress:SetText(L.Progress_Header)

	self.statslabel_rank = StatsLabelCenter(self.stats_panel, self.label_progress:GetTop() + 16)
	self.statslabel_tier = StatsLabelCenter(self.stats_panel, self.statslabel_rank:GetTop() + 11)

	-- Points Labels
	self.label_points = Turbine.UI.Label()
	self.label_points:SetParent(self.stats_panel)
	self.label_points:SetSize(self.stats_panel:GetWidth(), 20)
	self.label_points:SetPosition(0, self.statslabel_tier:GetTop() + 15)
	self.label_points:SetForeColor(Default_Font_Color)
	self.label_points:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_points:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_points:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_points:SetText(L.InfamyRenown)

	self.statslabel_points_total					= StatsLabelLeft(self.stats_panel, L.Stats_Total, self.label_points:GetTop() + 16)
	self.statslabel_points_total_value				= StatsLabelRight(self.stats_panel, self.label_points:GetTop() + 16)
	self.statslabel_points_to_rankup				= StatsLabelLeft(self.stats_panel, L.Stats_To_RankUp, self.statslabel_points_total:GetTop() + 11)
	self.statslabel_points_to_rankup_value			= StatsLabelRight(self.stats_panel, self.statslabel_points_total:GetTop() + 11)
	self.statslabel_points_last_24h					= StatsLabelLeft(self.stats_panel, L.Stats_Last_24h, self.statslabel_points_to_rankup:GetTop() + 11)
	self.statslabel_points_last_24h_value			= StatsLabelRight(self.stats_panel, self.statslabel_points_to_rankup:GetTop() + 11)
	self.statslabel_points_this_day					= StatsLabelLeft(self.stats_panel, L.Stats_Current_Day, self.statslabel_points_last_24h:GetTop() + 11)
	self.statslabel_points_this_day_value			= StatsLabelRight(self.stats_panel, self.statslabel_points_last_24h:GetTop() + 11)
	self.statslabel_points_last_hour				= StatsLabelLeft(self.stats_panel, L.Stats_Last_Hour, self.statslabel_points_this_day:GetTop() + 11)
	self.statslabel_points_last_hour_value			= StatsLabelRight(self.stats_panel, self.statslabel_points_this_day:GetTop() + 11)
	self.statslabel_points_last_10min				= StatsLabelLeft(self.stats_panel, L.Stats_Last_10min, self.statslabel_points_last_hour:GetTop() + 11)
	self.statslabel_points_last_10min_value			= StatsLabelRight(self.stats_panel, self.statslabel_points_last_hour:GetTop() + 11)
	self.statslabel_points_last_fight				= StatsLabelLeft(self.stats_panel, L.Stats_Last_Fight, self.statslabel_points_last_10min:GetTop() + 11)
	self.statslabel_points_last_fight_value			= StatsLabelRight(self.stats_panel, self.statslabel_points_last_10min:GetTop() + 11)

	-- Commendations Labels
	self.label_commendations = Turbine.UI.Label()
	self.label_commendations:SetParent(self.stats_panel)
	self.label_commendations:SetSize(self.stats_panel:GetWidth(), 20)
	self.label_commendations:SetPosition(0, self.statslabel_points_last_fight:GetTop() + 15)
	self.label_commendations:SetForeColor(Default_Font_Color)
	self.label_commendations:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_commendations:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_commendations:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_commendations:SetText(L.Commendations_Header)

	self.statslabel_commendations_total				= StatsLabelLeft(self.stats_panel, L.Stats_Total, self.label_commendations:GetTop() + 16)
	self.statslabel_commendations_total_value		= StatsLabelRight(self.stats_panel, self.label_commendations:GetTop() + 16)
	self.statslabel_commendations_current			= StatsLabelLeft(self.stats_panel, L.Stats_Current, self.statslabel_commendations_total:GetTop() + 11)
	self.statslabel_commendations_current_value		= StatsLabelRight(self.stats_panel, self.statslabel_commendations_total:GetTop() + 11)
	self.statslabel_commendations_last_24h			= StatsLabelLeft(self.stats_panel, L.Stats_Last_24h, self.statslabel_commendations_current:GetTop() + 11)
	self.statslabel_commendations_last_24h_value	= StatsLabelRight(self.stats_panel, self.statslabel_commendations_current:GetTop() + 11)
	self.statslabel_commendations_this_day			= StatsLabelLeft(self.stats_panel, L.Stats_Current_Day, self.statslabel_commendations_last_24h:GetTop() + 11)
	self.statslabel_commendations_this_day_value	= StatsLabelRight(self.stats_panel, self.statslabel_commendations_last_24h:GetTop() + 11)
	self.statslabel_commendations_last_hour			= StatsLabelLeft(self.stats_panel, L.Stats_Last_Hour, self.statslabel_commendations_this_day:GetTop() + 11)
	self.statslabel_commendations_last_hour_value	= StatsLabelRight(self.stats_panel, self.statslabel_commendations_this_day:GetTop() + 11)
	self.statslabel_commendations_last_10min		= StatsLabelLeft(self.stats_panel, L.Stats_Last_10min, self.statslabel_commendations_last_hour:GetTop() + 11)
	self.statslabel_commendations_last_10min_value	= StatsLabelRight(self.stats_panel, self.statslabel_commendations_last_hour:GetTop() + 11)
	self.statslabel_commendations_last_fight		= StatsLabelLeft(self.stats_panel, L.Stats_Last_Fight, self.statslabel_commendations_last_10min:GetTop() + 11)
	self.statslabel_commendations_last_fight_value	= StatsLabelRight(self.stats_panel, self.statslabel_commendations_last_10min:GetTop() + 11)

	-- Killing Blows Labels
	self.label_killing_blows = Turbine.UI.Label()
	self.label_killing_blows:SetParent(self.stats_panel)
	self.label_killing_blows:SetSize(self.stats_panel:GetWidth(), 20)
	self.label_killing_blows:SetPosition(0, self.statslabel_commendations_last_fight:GetTop() + 15)
	self.label_killing_blows:SetForeColor(Default_Font_Color)
	self.label_killing_blows:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_killing_blows:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_killing_blows:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_killing_blows:SetText(L.KillingBlows_Header)

	self.statslabel_killing_blows_total				= StatsLabelLeft(self.stats_panel, L.Stats_Total, self.label_killing_blows:GetTop() + 16)
	self.statslabel_killing_blows_total_value		= StatsLabelRight(self.stats_panel, self.label_killing_blows:GetTop() + 16)
	self.statslabel_killing_blows_to_tierup			= StatsLabelLeft(self.stats_panel, L.Stats_To_TierUp, self.statslabel_killing_blows_total:GetTop() + 11)
	self.statslabel_killing_blows_to_tierup_value	= StatsLabelRight(self.stats_panel, self.statslabel_killing_blows_total:GetTop() + 11)
	self.statslabel_killing_blows_last_24h			= StatsLabelLeft(self.stats_panel, L.Stats_Last_24h, self.statslabel_killing_blows_to_tierup:GetTop() + 11)
	self.statslabel_killing_blows_last_24h_value	= StatsLabelRight(self.stats_panel, self.statslabel_killing_blows_to_tierup:GetTop() + 11)
	self.statslabel_killing_blows_this_day			= StatsLabelLeft(self.stats_panel, L.Stats_Current_Day, self.statslabel_killing_blows_last_24h:GetTop() + 11)
	self.statslabel_killing_blows_this_day_value	= StatsLabelRight(self.stats_panel, self.statslabel_killing_blows_last_24h:GetTop() + 11)
	self.statslabel_killing_blows_last_hour			= StatsLabelLeft(self.stats_panel, L.Stats_Last_Hour, self.statslabel_killing_blows_this_day:GetTop() + 11)
	self.statslabel_killing_blows_last_hour_value	= StatsLabelRight(self.stats_panel, self.statslabel_killing_blows_this_day:GetTop() + 11)
	self.statslabel_killing_blows_last_10min		= StatsLabelLeft(self.stats_panel, L.Stats_Last_10min, self.statslabel_killing_blows_last_hour:GetTop() + 11)
	self.statslabel_killing_blows_last_10min_value	= StatsLabelRight(self.stats_panel, self.statslabel_killing_blows_last_hour:GetTop() + 11)
	self.statslabel_killing_blows_last_fight		= StatsLabelLeft(self.stats_panel, L.Stats_Last_Fight, self.statslabel_killing_blows_last_10min:GetTop() + 11)
	self.statslabel_killing_blows_last_fight_value	= StatsLabelRight(self.stats_panel, self.statslabel_killing_blows_last_10min:GetTop() + 11)

	-- Deaths Labels
	self.label_deaths = Turbine.UI.Label()
	self.label_deaths:SetParent(self.stats_panel)
	self.label_deaths:SetSize(self.stats_panel:GetWidth(), 20)
	self.label_deaths:SetPosition(0, self.statslabel_killing_blows_last_fight:GetTop() + 15)
	self.label_deaths:SetForeColor(Default_Font_Color)
	self.label_deaths:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_deaths:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_deaths:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_deaths:SetText(L.Deaths_Header)

	self.statslabel_deaths_last_24h					= StatsLabelLeft(self.stats_panel, L.Stats_Last_24h, self.label_deaths:GetTop() + 16)
	self.statslabel_deaths_last_24h_value			= StatsLabelRight(self.stats_panel, self.label_deaths:GetTop() + 16)
	self.statslabel_deaths_this_day					= StatsLabelLeft(self.stats_panel, L.Stats_Current_Day, self.statslabel_deaths_last_24h:GetTop() + 11)
	self.statslabel_deaths_this_day_value			= StatsLabelRight(self.stats_panel, self.statslabel_deaths_last_24h:GetTop() + 11)
	self.statslabel_deaths_last_hour				= StatsLabelLeft(self.stats_panel, L.Stats_Last_Hour, self.statslabel_deaths_this_day:GetTop() + 11)
	self.statslabel_deaths_last_hour_value			= StatsLabelRight(self.stats_panel, self.statslabel_deaths_this_day:GetTop() + 11)
	self.statslabel_deaths_last_10min				= StatsLabelLeft(self.stats_panel, L.Stats_Last_10min, self.statslabel_deaths_last_hour:GetTop() + 11)
	self.statslabel_deaths_last_10min_value			= StatsLabelRight(self.stats_panel, self.statslabel_deaths_last_hour:GetTop() + 11)

	-- Tracks Labels
	self.label_tracks = Turbine.UI.Label()
	self.label_tracks:SetParent(self.stats_panel)
	self.label_tracks:SetSize(self.stats_panel:GetWidth(), 20)
	self.label_tracks:SetPosition(0, self.statslabel_deaths_last_10min:GetTop() + 15)
	self.label_tracks:SetForeColor(Default_Font_Color)
	self.label_tracks:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_tracks:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_tracks:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_tracks:SetText(L.Tracks_Header)

	self.statslabel_tracks_total					= StatsLabelLeft(self.stats_panel, L.Stats_Total, self.label_tracks:GetTop() + 16)
	self.statslabel_tracks_total_value				= StatsLabelRight(self.stats_panel, self.label_tracks:GetTop() + 16)
	self.statslabel_tracks_last_24h					= StatsLabelLeft(self.stats_panel, L.Stats_Last_24h, self.statslabel_tracks_total:GetTop() + 11)
	self.statslabel_tracks_last_24h_value			= StatsLabelRight(self.stats_panel, self.statslabel_tracks_total:GetTop() + 11)
	self.statslabel_tracks_this_day					= StatsLabelLeft(self.stats_panel, L.Stats_Current_Day, self.statslabel_tracks_last_24h:GetTop() + 11)
	self.statslabel_tracks_this_day_value			= StatsLabelRight(self.stats_panel, self.statslabel_tracks_last_24h:GetTop() + 11)
	self.statslabel_tracks_last_hour				= StatsLabelLeft(self.stats_panel, L.Stats_Last_Hour, self.statslabel_tracks_this_day:GetTop() + 11)
	self.statslabel_tracks_last_hour_value			= StatsLabelRight(self.stats_panel, self.statslabel_tracks_this_day:GetTop() + 11)
	self.statslabel_tracks_last_10min				= StatsLabelLeft(self.stats_panel, L.Stats_Last_10min, self.statslabel_tracks_last_hour:GetTop() + 11)
	self.statslabel_tracks_last_10min_value			= StatsLabelRight(self.stats_panel, self.statslabel_tracks_last_hour:GetTop() + 11)


	-- Killing Blows Panel
	self.frag_panel = Turbine.UI.Control()
	self.frag_panel:SetParent(self)
	self.frag_panel:SetSize(self:GetWidth() - 40, self:GetHeight() - 90)
	self.frag_panel:SetPosition(self:GetWidth() / 2 - self.frag_panel:GetWidth() / 2, 85)

	self.label_search_box = Turbine.UI.Label()
	self.label_search_box:SetParent(self.frag_panel)
	self.label_search_box:SetSize(65, 20)
	self.label_search_box:SetPosition(0, 3)
	self.label_search_box:SetForeColor(Default_Font_Color)
	self.label_search_box:SetFont(Turbine.UI.Lotro.Font.TrajanPro18)
	self.label_search_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	self.label_search_box:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_search_box:SetText(L.Log_Search)

	self.button_search_box_clear = LotroButton(self.frag_panel, nil, "X")
	self.button_search_box_clear:SetPosition(self.frag_panel:GetWidth() - self.button_search_box_clear:GetWidth(), 3)
	self.button_search_box_clear.Click = function()
		self.search_box:SetText("")
		self.button_search_box_clear:SetEnabled(false)
		self:UpdateFragList(self.current_sortmode)
	end

	self.search_box = LotroTextBox(self.frag_panel, self.frag_panel:GetWidth() - self.label_search_box:GetWidth() - self.button_search_box_clear:GetWidth() - 5)
	self.search_box:SetPosition(self.label_search_box:GetWidth(), 3)
	self.search_box.TextChanged = function()
		if self.search_box:GetText() ~= "" then
			self.button_search_box_clear:SetEnabled(true)
		else
			self.button_search_box_clear:SetEnabled(false)
		end
		self:UpdateFragList(self.current_sortmode)
	end

	self.frag_list = Turbine.UI.ListBox()
	self.frag_list:SetParent(self.frag_panel)
	self.frag_list:SetSize(self.frag_panel:GetWidth() - 12, self.frag_panel:GetHeight() - 57)
	self.frag_list:SetPosition(0, 45)

	self.scrollbar_frag_list = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_frag_list:SetParent(self.frag_panel)
	self.scrollbar_frag_list:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_frag_list:SetSize(10, self.frag_list:GetHeight())
	self.scrollbar_frag_list:SetPosition(self.frag_list:GetLeft() + self.frag_list:GetWidth() + 2, self.frag_list:GetTop())
	self.frag_list:SetVerticalScrollBar(self.scrollbar_frag_list)

	self.label_name = Turbine.UI.Label()
	self.label_name:SetParent(self.frag_panel)
	self.label_name:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
	self.label_name:SetSize(self.frag_list:GetWidth() * 0.4, 20)
	self.label_name:SetPosition(0, 25)
	self.label_name:SetForeColor(Default_Font_Color)
	self.label_name:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	self.label_name.MouseDown = function()
		if self.current_sortmode == alphabetical_desc then
			self:SortFragList(alphabetical_asc)
		else
			self:SortFragList(alphabetical_desc)
		end
	end

	self.label_frags = Turbine.UI.Label()
	self.label_frags:SetParent(self.frag_panel)
	self.label_frags:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
	self.label_frags:SetSize(self.frag_list:GetWidth() * 0.6, 20)
	self.label_frags:SetPosition(self.label_name:GetWidth(), 25)
	self.label_frags:SetForeColor(Default_Font_Color)
	self.label_frags:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_frags:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
	self.label_frags.MouseDown = function()
		if self.current_sortmode == frags_desc then
			self:SortFragList(frags_asc)
		else
			self:SortFragList(frags_desc)
		end
	end


	-- Points Bar Chart Panel
	self.barchart_points_panel = Turbine.UI.Control()
	self.barchart_points_panel:SetParent(self)
	self.barchart_points_panel:SetSize(self:GetWidth() - 50, self:GetHeight() - 90)
	self.barchart_points_panel:SetPosition(self:GetWidth() / 2 - self.barchart_points_panel:GetWidth() / 2, 85)

	-- Points Diagram - Month
	self.barchart_points_month_header = Turbine.UI.Label()
	self.barchart_points_month_header:SetParent(self.barchart_points_panel)
	self.barchart_points_month_header:SetSize(self.barchart_points_panel:GetWidth(), 25)
	self.barchart_points_month_header:SetForeColor(Default_Font_Color)
	self.barchart_points_month_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_points_month_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_points_month_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_points_month_header:SetText(L.InfamyRenown .. " " .. L.Stats_Last_Month)

	self.barchart_points_month = Turbine.UI.ListBox()
	self.barchart_points_month:SetParent(self.barchart_points_panel)
	self.barchart_points_month:SetSize(self.barchart_points_panel:GetWidth(), 160)
	self.barchart_points_month:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.barchart_points_month:SetTop(self.barchart_points_month_header:GetTop() + self.barchart_points_month_header:GetHeight())

	self.scrollbar_barchart_points_month = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_points_month:SetParent(self.barchart_points_panel)
	self.scrollbar_barchart_points_month:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_points_month:SetSize(self.barchart_points_month:GetWidth(), 10)
	self.scrollbar_barchart_points_month:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_points_month:SetPosition(self.barchart_points_month:GetLeft(), self.barchart_points_month:GetTop() + self.barchart_points_month:GetHeight())
	self.barchart_points_month:SetHorizontalScrollBar(self.scrollbar_barchart_points_month)

	self.topline_barchart_points_month = Turbine.UI.Control()
	self.topline_barchart_points_month:SetParent(self.barchart_points_month)
	self.topline_barchart_points_month:SetSize(self.barchart_points_month:GetWidth(), 1)
	self.topline_barchart_points_month:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_points_month = Turbine.UI.Label()
	self.label_topline_barchart_points_month:SetParent(self.barchart_points_month)
	self.label_topline_barchart_points_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_points_month:SetSize(50, 12)

	self.bottomline_barchart_points_month = Turbine.UI.Control()
	self.bottomline_barchart_points_month:SetParent(self.barchart_points_month)
	self.bottomline_barchart_points_month:SetSize(self.barchart_points_month:GetWidth(), 1)
	self.bottomline_barchart_points_month:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_points_month = Turbine.UI.Label()
	self.label_bottomline_barchart_points_month:SetParent(self.barchart_points_month)
	self.label_bottomline_barchart_points_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_points_month:SetSize(50, 12)

	self.border_barchart_points_month = Turbine.UI.Control()
	self.border_barchart_points_month:SetParent(self.barchart_points_month)
	self.border_barchart_points_month:SetSize(self.barchart_points_month:GetWidth(), 1)
	self.border_barchart_points_month:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_points_month:SetTop(self.barchart_points_month:GetHeight() - 24)

	self.hopping_points_day = Turbine.UI.Label()
	self.hopping_points_day:SetParent(self)
	self.hopping_points_day:SetSize(50, 12)
	self.hopping_points_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_points_day:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_points_day:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_points_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_points_day:SetVisible(false)

	-- Points Diagram - Year
	self.barchart_points_year_header = Turbine.UI.Label()
	self.barchart_points_year_header:SetParent(self.barchart_points_panel)
	self.barchart_points_year_header:SetSize(self.barchart_points_panel:GetWidth(), 15)
	self.barchart_points_year_header:SetPosition(0, self.scrollbar_barchart_points_month:GetTop() + self.scrollbar_barchart_points_month:GetHeight() + 15)
	self.barchart_points_year_header:SetForeColor(Default_Font_Color)
	self.barchart_points_year_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_points_year_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_points_year_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_points_year_header:SetText(L.InfamyRenown .. " " .. L.Stats_Last_Year)

	self.barchart_points_year = Turbine.UI.ListBox()
	self.barchart_points_year:SetParent(self.barchart_points_panel)
	self.barchart_points_year:SetSize(self.barchart_points_panel:GetWidth(), 160)
	self.barchart_points_year:SetTop(self.barchart_points_year_header:GetTop() + self.barchart_points_year_header:GetHeight())
	self.barchart_points_year:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_points_year = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_points_year:SetParent(self.barchart_points_panel)
	self.scrollbar_barchart_points_year:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_points_year:SetSize(self.barchart_points_year:GetWidth(), 10)
	self.scrollbar_barchart_points_year:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_points_year:SetPosition(self.barchart_points_year:GetLeft(), self.barchart_points_year:GetTop() + self.barchart_points_year:GetHeight())
	self.barchart_points_year:SetHorizontalScrollBar(self.scrollbar_barchart_points_year)

	self.topline_barchart_points_year = Turbine.UI.Control()
	self.topline_barchart_points_year:SetParent(self.barchart_points_year)
	self.topline_barchart_points_year:SetSize(self.barchart_points_year:GetWidth(), 1)
	self.topline_barchart_points_year:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_points_year = Turbine.UI.Label()
	self.label_topline_barchart_points_year:SetParent(self.barchart_points_year)
	self.label_topline_barchart_points_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_points_year:SetSize(50, 12)

	self.bottomline_barchart_points_year = Turbine.UI.Control()
	self.bottomline_barchart_points_year:SetParent(self.barchart_points_year)
	self.bottomline_barchart_points_year:SetSize(self.barchart_points_year:GetWidth(), 1)
	self.bottomline_barchart_points_year:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_points_year = Turbine.UI.Label()
	self.label_bottomline_barchart_points_year:SetParent(self.barchart_points_year)
	self.label_bottomline_barchart_points_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_points_year:SetSize(50, 12)

	self.border_barchart_points_year = Turbine.UI.Control()
	self.border_barchart_points_year:SetParent(self.barchart_points_year)
	self.border_barchart_points_year:SetSize(self.barchart_points_year:GetWidth(), 1)
	self.border_barchart_points_year:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_points_year:SetTop(self.barchart_points_year:GetHeight() - 24)

	self.hopping_points_month = Turbine.UI.Label()
	self.hopping_points_month:SetParent(self)
	self.hopping_points_month:SetSize(50, 12)
	self.hopping_points_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_points_month:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_points_month:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_points_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_points_month:SetVisible(false)

	self.hopping_points_daily_avg = Turbine.UI.Label()
	self.hopping_points_daily_avg:SetParent(self)
	self.hopping_points_daily_avg:SetSize(50, 12)
	self.hopping_points_daily_avg:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_points_daily_avg:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_points_daily_avg:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_points_daily_avg:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_points_daily_avg:SetMouseVisible(false)
	self.hopping_points_daily_avg:SetVisible(false)

	-- Points Diagram - Stats
	self.statistics_points_header = Turbine.UI.Label()
	self.statistics_points_header:SetParent(self.barchart_points_panel)
	self.statistics_points_header:SetSize(self.barchart_points_panel:GetWidth(), 20)
	self.statistics_points_header:SetPosition(0, self.scrollbar_barchart_points_year:GetTop() + self.scrollbar_barchart_points_year:GetHeight() + 3)
	self.statistics_points_header:SetForeColor(Default_Font_Color)
	self.statistics_points_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.statistics_points_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.statistics_points_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.statistics_points_header:SetText(L.Statistics_Header)

	self.statistics_points_most_frag = Turbine.UI.Label()
	self.statistics_points_most_frag:SetParent(self.barchart_points_panel)
	self.statistics_points_most_frag:SetSize(self.barchart_points_panel:GetWidth(), 12)
	self.statistics_points_most_frag:SetTop(self.statistics_points_header:GetTop() + 18)
	self.statistics_points_most_frag:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_points_most_frag:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_points_most_day = Turbine.UI.Label()
	self.statistics_points_most_day:SetParent(self.barchart_points_panel)
	self.statistics_points_most_day:SetSize(self.barchart_points_panel:GetWidth(), 12)
	self.statistics_points_most_day:SetTop(self.statistics_points_most_frag:GetTop() + 13)
	self.statistics_points_most_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_points_most_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_points_most_month = Turbine.UI.Label()
	self.statistics_points_most_month:SetParent(self.barchart_points_panel)
	self.statistics_points_most_month:SetSize(self.barchart_points_panel:GetWidth(), 12)
	self.statistics_points_most_month:SetTop(self.statistics_points_most_day:GetTop() + 13)
	self.statistics_points_most_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_points_most_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_points_per_frag = Turbine.UI.Label()
	self.statistics_points_per_frag:SetParent(self.barchart_points_panel)
	self.statistics_points_per_frag:SetSize(self.barchart_points_panel:GetWidth(), 12)
	self.statistics_points_per_frag:SetTop(self.statistics_points_most_month:GetTop() + 18)
	self.statistics_points_per_frag:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_points_per_frag:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.statistics_points_per_frag:SetVisible(false)


	-- Commendations Bar Chart Panel
	self.barchart_comms_panel = Turbine.UI.Control()
	self.barchart_comms_panel:SetParent(self)
	self.barchart_comms_panel:SetSize(self:GetWidth() - 50, self:GetHeight() - 90)
	self.barchart_comms_panel:SetPosition(self:GetWidth() / 2 - self.barchart_comms_panel:GetWidth() / 2, 85)

	-- Commendations Diagram - Month
	self.barchart_comms_month_header = Turbine.UI.Label()
	self.barchart_comms_month_header:SetParent(self.barchart_comms_panel)
	self.barchart_comms_month_header:SetSize(self.barchart_comms_panel:GetWidth(), 25)
	self.barchart_comms_month_header:SetForeColor(Default_Font_Color)
	self.barchart_comms_month_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_comms_month_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_comms_month_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_comms_month_header:SetText(L.Commendations_Header .. " " .. L.Stats_Last_Month)

	self.barchart_comms_month = Turbine.UI.ListBox()
	self.barchart_comms_month:SetParent(self.barchart_comms_panel)
	self.barchart_comms_month:SetSize(self.barchart_comms_panel:GetWidth(), 160)
	self.barchart_comms_month:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.barchart_comms_month:SetTop(self.barchart_comms_month_header:GetTop() + self.barchart_comms_month_header:GetHeight())

	self.scrollbar_barchart_comms_month = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_comms_month:SetParent(self.barchart_comms_panel)
	self.scrollbar_barchart_comms_month:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_comms_month:SetSize(self.barchart_comms_month:GetWidth(), 10)
	self.scrollbar_barchart_comms_month:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_comms_month:SetPosition(self.barchart_comms_month:GetLeft(), self.barchart_comms_month:GetTop() + self.barchart_comms_month:GetHeight())
	self.barchart_comms_month:SetHorizontalScrollBar(self.scrollbar_barchart_comms_month)

	self.topline_barchart_comms_month = Turbine.UI.Control()
	self.topline_barchart_comms_month:SetParent(self.barchart_comms_month)
	self.topline_barchart_comms_month:SetSize(self.barchart_comms_month:GetWidth(), 1)
	self.topline_barchart_comms_month:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_comms_month = Turbine.UI.Label()
	self.label_topline_barchart_comms_month:SetParent(self.barchart_comms_month)
	self.label_topline_barchart_comms_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_comms_month:SetSize(50, 12)

	self.bottomline_barchart_comms_month = Turbine.UI.Control()
	self.bottomline_barchart_comms_month:SetParent(self.barchart_comms_month)
	self.bottomline_barchart_comms_month:SetSize(self.barchart_comms_month:GetWidth(), 1)
	self.bottomline_barchart_comms_month:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_comms_month = Turbine.UI.Label()
	self.label_bottomline_barchart_comms_month:SetParent(self.barchart_comms_month)
	self.label_bottomline_barchart_comms_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_comms_month:SetSize(50, 12)

	self.border_barchart_comms_month = Turbine.UI.Control()
	self.border_barchart_comms_month:SetParent(self.barchart_comms_month)
	self.border_barchart_comms_month:SetSize(self.barchart_comms_month:GetWidth(), 1)
	self.border_barchart_comms_month:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_comms_month:SetTop(self.barchart_comms_month:GetHeight() - 24)

	self.hopping_comms_day = Turbine.UI.Label()
	self.hopping_comms_day:SetParent(self)
	self.hopping_comms_day:SetSize(50, 12)
	self.hopping_comms_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_comms_day:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_comms_day:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_comms_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_comms_day:SetVisible(false)

	-- Commendations Diagram - Year
	self.barchart_comms_year_header = Turbine.UI.Label()
	self.barchart_comms_year_header:SetParent(self.barchart_comms_panel)
	self.barchart_comms_year_header:SetSize(self.barchart_comms_panel:GetWidth(), 15)
	self.barchart_comms_year_header:SetPosition(0, self.scrollbar_barchart_comms_month:GetTop() + self.scrollbar_barchart_comms_month:GetHeight() + 15)
	self.barchart_comms_year_header:SetForeColor(Default_Font_Color)
	self.barchart_comms_year_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_comms_year_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_comms_year_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_comms_year_header:SetText(L.Commendations_Header .. " " .. L.Stats_Last_Year)

	self.barchart_comms_year = Turbine.UI.ListBox()
	self.barchart_comms_year:SetParent(self.barchart_comms_panel)
	self.barchart_comms_year:SetSize(self.barchart_comms_panel:GetWidth(), 160)
	self.barchart_comms_year:SetTop(self.barchart_comms_year_header:GetTop() + self.barchart_comms_year_header:GetHeight())
	self.barchart_comms_year:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_comms_year = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_comms_year:SetParent(self.barchart_comms_panel)
	self.scrollbar_barchart_comms_year:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_comms_year:SetSize(self.barchart_comms_year:GetWidth(), 10)
	self.scrollbar_barchart_comms_year:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_comms_year:SetPosition(self.barchart_comms_year:GetLeft(), self.barchart_comms_year:GetTop() + self.barchart_comms_year:GetHeight())
	self.barchart_comms_year:SetHorizontalScrollBar(self.scrollbar_barchart_comms_year)

	self.topline_barchart_comms_year = Turbine.UI.Control()
	self.topline_barchart_comms_year:SetParent(self.barchart_comms_year)
	self.topline_barchart_comms_year:SetSize(self.barchart_comms_year:GetWidth(), 1)
	self.topline_barchart_comms_year:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_comms_year = Turbine.UI.Label()
	self.label_topline_barchart_comms_year:SetParent(self.barchart_comms_year)
	self.label_topline_barchart_comms_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_comms_year:SetSize(50, 12)

	self.bottomline_barchart_comms_year = Turbine.UI.Control()
	self.bottomline_barchart_comms_year:SetParent(self.barchart_comms_year)
	self.bottomline_barchart_comms_year:SetSize(self.barchart_comms_year:GetWidth(), 1)
	self.bottomline_barchart_comms_year:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_comms_year = Turbine.UI.Label()
	self.label_bottomline_barchart_comms_year:SetParent(self.barchart_comms_year)
	self.label_bottomline_barchart_comms_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_comms_year:SetSize(50, 12)

	self.border_barchart_comms_year = Turbine.UI.Control()
	self.border_barchart_comms_year:SetParent(self.barchart_comms_year)
	self.border_barchart_comms_year:SetSize(self.barchart_comms_year:GetWidth(), 1)
	self.border_barchart_comms_year:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_comms_year:SetTop(self.barchart_comms_year:GetHeight() - 24)

	self.hopping_comms_month = Turbine.UI.Label()
	self.hopping_comms_month:SetParent(self)
	self.hopping_comms_month:SetSize(50, 12)
	self.hopping_comms_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_comms_month:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_comms_month:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_comms_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_comms_month:SetVisible(false)

	self.hopping_comms_daily_avg = Turbine.UI.Label()
	self.hopping_comms_daily_avg:SetParent(self)
	self.hopping_comms_daily_avg:SetSize(50, 12)
	self.hopping_comms_daily_avg:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_comms_daily_avg:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_comms_daily_avg:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_comms_daily_avg:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_comms_daily_avg:SetMouseVisible(false)
	self.hopping_comms_daily_avg:SetVisible(false)

	-- Commendations Diagram - Stats
	self.statistics_comms_header = Turbine.UI.Label()
	self.statistics_comms_header:SetParent(self.barchart_comms_panel)
	self.statistics_comms_header:SetSize(self.barchart_comms_panel:GetWidth(), 20)
	self.statistics_comms_header:SetPosition(0, self.scrollbar_barchart_comms_year:GetTop() + self.scrollbar_barchart_comms_year:GetHeight() + 3)
	self.statistics_comms_header:SetForeColor(Default_Font_Color)
	self.statistics_comms_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.statistics_comms_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.statistics_comms_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.statistics_comms_header:SetText(L.Statistics_Header)

	self.statistics_comms_most_day = Turbine.UI.Label()
	self.statistics_comms_most_day:SetParent(self.barchart_comms_panel)
	self.statistics_comms_most_day:SetSize(self.barchart_comms_panel:GetWidth(), 12)
	self.statistics_comms_most_day:SetTop(self.statistics_comms_header:GetTop() + 18)
	self.statistics_comms_most_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_comms_most_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_comms_most_month = Turbine.UI.Label()
	self.statistics_comms_most_month:SetParent(self.barchart_comms_panel)
	self.statistics_comms_most_month:SetSize(self.barchart_comms_panel:GetWidth(), 12)
	self.statistics_comms_most_month:SetTop(self.statistics_comms_most_day:GetTop() + 13)
	self.statistics_comms_most_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_comms_most_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)


	-- Frags Bar Chart Panel
	self.barchart_frags_panel = Turbine.UI.Control()
	self.barchart_frags_panel:SetParent(self)
	self.barchart_frags_panel:SetSize(self:GetWidth() - 50, self:GetHeight() - 90)
	self.barchart_frags_panel:SetPosition(self:GetWidth() / 2 - self.barchart_frags_panel:GetWidth() / 2, 85)

	-- Frag Diagram - Month
	self.barchart_frags_month_header = Turbine.UI.Label()
	self.barchart_frags_month_header:SetParent(self.barchart_frags_panel)
	self.barchart_frags_month_header:SetSize(self.barchart_frags_panel:GetWidth(), 25)
	self.barchart_frags_month_header:SetForeColor(Default_Font_Color)
	self.barchart_frags_month_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_frags_month_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_frags_month_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_frags_month_header:SetText(L.KillingBlows_Header .. " " .. L.Stats_Last_Month)

	self.barchart_frags_month = Turbine.UI.ListBox()
	self.barchart_frags_month:SetParent(self.barchart_frags_panel)
	self.barchart_frags_month:SetSize(self.barchart_frags_panel:GetWidth(), 160)
	self.barchart_frags_month:SetTop(self.barchart_frags_month_header:GetTop() + self.barchart_frags_month_header:GetHeight())
	self.barchart_frags_month:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_frags_month = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_frags_month:SetParent(self.barchart_frags_panel)
	self.scrollbar_barchart_frags_month:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_frags_month:SetSize(self.barchart_frags_month:GetWidth(), 10)
	self.scrollbar_barchart_frags_month:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_frags_month:SetPosition(self.barchart_frags_month:GetLeft(), self.barchart_frags_month:GetTop() + self.barchart_frags_month:GetHeight())
	self.barchart_frags_month:SetHorizontalScrollBar(self.scrollbar_barchart_frags_month)

	self.topline_barchart_frags_month = Turbine.UI.Control()
	self.topline_barchart_frags_month:SetParent(self.barchart_frags_month)
	self.topline_barchart_frags_month:SetSize(self.barchart_frags_month:GetWidth(), 1)
	self.topline_barchart_frags_month:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_frags_month = Turbine.UI.Label()
	self.label_topline_barchart_frags_month:SetParent(self.barchart_frags_month)
	self.label_topline_barchart_frags_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_frags_month:SetSize(50, 12)

	self.bottomline_barchart_frags_month = Turbine.UI.Control()
	self.bottomline_barchart_frags_month:SetParent(self.barchart_frags_month)
	self.bottomline_barchart_frags_month:SetSize(self.barchart_frags_month:GetWidth(), 1)
	self.bottomline_barchart_frags_month:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_frags_month = Turbine.UI.Label()
	self.label_bottomline_barchart_frags_month:SetParent(self.barchart_frags_month)
	self.label_bottomline_barchart_frags_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_frags_month:SetSize(50, 12)

	self.border_barchart_frags_month = Turbine.UI.Control()
	self.border_barchart_frags_month:SetParent(self.barchart_frags_month)
	self.border_barchart_frags_month:SetSize(self.barchart_frags_month:GetWidth(), 1)
	self.border_barchart_frags_month:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_frags_month:SetTop(self.barchart_frags_month:GetHeight() - 24)

	self.hopping_frags_day = Turbine.UI.Label()
	self.hopping_frags_day:SetParent(self)
	self.hopping_frags_day:SetSize(50, 12)
	self.hopping_frags_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_frags_day:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_frags_day:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_frags_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_frags_day:SetVisible(false)

	-- Frags Diagram - Year
	self.barchart_frags_year_header = Turbine.UI.Label()
	self.barchart_frags_year_header:SetParent(self.barchart_frags_panel)
	self.barchart_frags_year_header:SetSize(self.barchart_frags_panel:GetWidth(), 15)
	self.barchart_frags_year_header:SetPosition(0, self.scrollbar_barchart_frags_month:GetTop() + self.scrollbar_barchart_frags_month:GetHeight() + 15)
	self.barchart_frags_year_header:SetForeColor(Default_Font_Color)
	self.barchart_frags_year_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_frags_year_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_frags_year_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_frags_year_header:SetText(L.KillingBlows_Header .. " " .. L.Stats_Last_Year)

	self.barchart_frags_year = Turbine.UI.ListBox()
	self.barchart_frags_year:SetParent(self.barchart_frags_panel)
	self.barchart_frags_year:SetSize(self.barchart_frags_panel:GetWidth(), 160)
	self.barchart_frags_year:SetTop(self.barchart_frags_year_header:GetTop() + self.barchart_frags_year_header:GetHeight())
	self.barchart_frags_year:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_frags_year = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_frags_year:SetParent(self.barchart_frags_panel)
	self.scrollbar_barchart_frags_year:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_frags_year:SetSize(self.barchart_frags_year:GetWidth(), 10)
	self.scrollbar_barchart_frags_year:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_frags_year:SetPosition(self.barchart_frags_year:GetLeft(), self.barchart_frags_year:GetTop() + self.barchart_frags_year:GetHeight())
	self.barchart_frags_year:SetHorizontalScrollBar(self.scrollbar_barchart_frags_year)

	self.topline_barchart_frags_year = Turbine.UI.Control()
	self.topline_barchart_frags_year:SetParent(self.barchart_frags_year)
	self.topline_barchart_frags_year:SetSize(self.barchart_frags_year:GetWidth(), 1)
	self.topline_barchart_frags_year:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_frags_year = Turbine.UI.Label()
	self.label_topline_barchart_frags_year:SetParent(self.barchart_frags_year)
	self.label_topline_barchart_frags_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_frags_year:SetSize(50, 12)

	self.bottomline_barchart_frags_year = Turbine.UI.Control()
	self.bottomline_barchart_frags_year:SetParent(self.barchart_frags_year)
	self.bottomline_barchart_frags_year:SetSize(self.barchart_frags_year:GetWidth(), 1)
	self.bottomline_barchart_frags_year:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_frags_year = Turbine.UI.Label()
	self.label_bottomline_barchart_frags_year:SetParent(self.barchart_frags_year)
	self.label_bottomline_barchart_frags_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_frags_year:SetSize(50, 12)

	self.border_barchart_frags_year = Turbine.UI.Control()
	self.border_barchart_frags_year:SetParent(self.barchart_frags_year)
	self.border_barchart_frags_year:SetSize(self.barchart_frags_year:GetWidth(), 1)
	self.border_barchart_frags_year:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_frags_year:SetTop(self.barchart_frags_year:GetHeight() - 24)

	self.hopping_frags_month = Turbine.UI.Label()
	self.hopping_frags_month:SetParent(self)
	self.hopping_frags_month:SetSize(50, 12)
	self.hopping_frags_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_frags_month:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_frags_month:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_frags_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_frags_month:SetVisible(false)

	self.hopping_frags_daily_avg = Turbine.UI.Label()
	self.hopping_frags_daily_avg:SetParent(self)
	self.hopping_frags_daily_avg:SetSize(50, 12)
	self.hopping_frags_daily_avg:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_frags_daily_avg:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_frags_daily_avg:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_frags_daily_avg:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_frags_daily_avg:SetMouseVisible(false)
	self.hopping_frags_daily_avg:SetVisible(false)

	-- Frags Diagram - Stats
	self.statistics_frags_header = Turbine.UI.Label()
	self.statistics_frags_header:SetParent(self.barchart_frags_panel)
	self.statistics_frags_header:SetSize(self.barchart_frags_panel:GetWidth(), 20)
	self.statistics_frags_header:SetPosition(0, self.scrollbar_barchart_frags_year:GetTop() + self.scrollbar_barchart_frags_year:GetHeight() + 3)
	self.statistics_frags_header:SetForeColor(Default_Font_Color)
	self.statistics_frags_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.statistics_frags_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.statistics_frags_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.statistics_frags_header:SetText(L.Statistics_Header)

	self.statistics_frags_most_day = Turbine.UI.Label()
	self.statistics_frags_most_day:SetParent(self.barchart_frags_panel)
	self.statistics_frags_most_day:SetSize(self.barchart_frags_panel:GetWidth(), 12)
	self.statistics_frags_most_day:SetTop(self.statistics_frags_header:GetTop() + 18)
	self.statistics_frags_most_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_frags_most_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_frags_most_month = Turbine.UI.Label()
	self.statistics_frags_most_month:SetParent(self.barchart_frags_panel)
	self.statistics_frags_most_month:SetSize(self.barchart_frags_panel:GetWidth(), 12)
	self.statistics_frags_most_month:SetTop(self.statistics_frags_most_day:GetTop() + 13)
	self.statistics_frags_most_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_frags_most_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_frags_per_death = Turbine.UI.Label()
	self.statistics_frags_per_death:SetParent(self.barchart_frags_panel)
	self.statistics_frags_per_death:SetSize(self.barchart_frags_panel:GetWidth(), 12)
	self.statistics_frags_per_death:SetTop(self.statistics_frags_most_month:GetTop() + 18)
	self.statistics_frags_per_death:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_frags_per_death:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.statistics_frags_per_death:SetVisible(false)


	-- Deaths Bar Chart Panel
	self.barchart_deaths_panel = Turbine.UI.Control()
	self.barchart_deaths_panel:SetParent(self)
	self.barchart_deaths_panel:SetSize(self:GetWidth() - 50, self:GetHeight() - 90)
	self.barchart_deaths_panel:SetPosition(self:GetWidth() / 2 - self.barchart_deaths_panel:GetWidth() / 2, 85)

	-- Deaths Diagram - Month
	self.barchart_deaths_month_header = Turbine.UI.Label()
	self.barchart_deaths_month_header:SetParent(self.barchart_deaths_panel)
	self.barchart_deaths_month_header:SetSize(self.barchart_deaths_panel:GetWidth(), 25)
	self.barchart_deaths_month_header:SetForeColor(Default_Font_Color)
	self.barchart_deaths_month_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_deaths_month_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_deaths_month_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_deaths_month_header:SetText(L.Deaths_Header .. " " .. L.Stats_Last_Month)

	self.barchart_deaths_month = Turbine.UI.ListBox()
	self.barchart_deaths_month:SetParent(self.barchart_deaths_panel)
	self.barchart_deaths_month:SetSize(self.barchart_deaths_panel:GetWidth(), 160)
	self.barchart_deaths_month:SetTop(self.barchart_deaths_month_header:GetTop() + self.barchart_deaths_month_header:GetHeight())
	self.barchart_deaths_month:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_deaths_month = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_deaths_month:SetParent(self.barchart_deaths_panel)
	self.scrollbar_barchart_deaths_month:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_deaths_month:SetSize(self.barchart_deaths_month:GetWidth(), 10)
	self.scrollbar_barchart_deaths_month:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_deaths_month:SetPosition(self.barchart_deaths_month:GetLeft(), self.barchart_deaths_month:GetTop() + self.barchart_deaths_month:GetHeight())
	self.barchart_deaths_month:SetHorizontalScrollBar(self.scrollbar_barchart_deaths_month)

	self.topline_barchart_deaths_month = Turbine.UI.Control()
	self.topline_barchart_deaths_month:SetParent(self.barchart_deaths_month)
	self.topline_barchart_deaths_month:SetSize(self.barchart_deaths_month:GetWidth(), 1)
	self.topline_barchart_deaths_month:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_deaths_month = Turbine.UI.Label()
	self.label_topline_barchart_deaths_month:SetParent(self.barchart_deaths_month)
	self.label_topline_barchart_deaths_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_deaths_month:SetSize(50, 12)

	self.bottomline_barchart_deaths_month = Turbine.UI.Control()
	self.bottomline_barchart_deaths_month:SetParent(self.barchart_deaths_month)
	self.bottomline_barchart_deaths_month:SetSize(self.barchart_deaths_month:GetWidth(), 1)
	self.bottomline_barchart_deaths_month:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_deaths_month = Turbine.UI.Label()
	self.label_bottomline_barchart_deaths_month:SetParent(self.barchart_deaths_month)
	self.label_bottomline_barchart_deaths_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_deaths_month:SetSize(50, 12)

	self.border_barchart_deaths_month = Turbine.UI.Control()
	self.border_barchart_deaths_month:SetParent(self.barchart_deaths_month)
	self.border_barchart_deaths_month:SetSize(self.barchart_deaths_month:GetWidth(), 1)
	self.border_barchart_deaths_month:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_deaths_month:SetTop(self.barchart_deaths_month:GetHeight() - 24)

	self.hopping_deaths_day = Turbine.UI.Label()
	self.hopping_deaths_day:SetParent(self)
	self.hopping_deaths_day:SetSize(50, 12)
	self.hopping_deaths_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_deaths_day:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_deaths_day:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_deaths_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_deaths_day:SetVisible(false)

	-- Deaths Diagram - Year
	self.barchart_deaths_year_header = Turbine.UI.Label()
	self.barchart_deaths_year_header:SetParent(self.barchart_deaths_panel)
	self.barchart_deaths_year_header:SetSize(self.barchart_deaths_panel:GetWidth(), 15)
	self.barchart_deaths_year_header:SetPosition(0, self.scrollbar_barchart_deaths_month:GetTop() + self.scrollbar_barchart_deaths_month:GetHeight() + 15)
	self.barchart_deaths_year_header:SetForeColor(Default_Font_Color)
	self.barchart_deaths_year_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_deaths_year_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_deaths_year_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_deaths_year_header:SetText(L.Deaths_Header .. " " .. L.Stats_Last_Year)

	self.barchart_deaths_year = Turbine.UI.ListBox()
	self.barchart_deaths_year:SetParent(self.barchart_deaths_panel)
	self.barchart_deaths_year:SetSize(self.barchart_deaths_panel:GetWidth(), 160)
	self.barchart_deaths_year:SetTop(self.barchart_deaths_year_header:GetTop() + self.barchart_deaths_year_header:GetHeight())
	self.barchart_deaths_year:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_deaths_year = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_deaths_year:SetParent(self.barchart_deaths_panel)
	self.scrollbar_barchart_deaths_year:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_deaths_year:SetSize(self.barchart_deaths_year:GetWidth(), 10)
	self.scrollbar_barchart_deaths_year:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_deaths_year:SetPosition(self.barchart_deaths_year:GetLeft(), self.barchart_deaths_year:GetTop() + self.barchart_deaths_year:GetHeight())
	self.barchart_deaths_year:SetHorizontalScrollBar(self.scrollbar_barchart_deaths_year)

	self.topline_barchart_deaths_year = Turbine.UI.Control()
	self.topline_barchart_deaths_year:SetParent(self.barchart_deaths_year)
	self.topline_barchart_deaths_year:SetSize(self.barchart_deaths_year:GetWidth(), 1)
	self.topline_barchart_deaths_year:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_deaths_year = Turbine.UI.Label()
	self.label_topline_barchart_deaths_year:SetParent(self.barchart_deaths_year)
	self.label_topline_barchart_deaths_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_deaths_year:SetSize(50, 12)

	self.bottomline_barchart_deaths_year = Turbine.UI.Control()
	self.bottomline_barchart_deaths_year:SetParent(self.barchart_deaths_year)
	self.bottomline_barchart_deaths_year:SetSize(self.barchart_deaths_year:GetWidth(), 1)
	self.bottomline_barchart_deaths_year:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_deaths_year = Turbine.UI.Label()
	self.label_bottomline_barchart_deaths_year:SetParent(self.barchart_deaths_year)
	self.label_bottomline_barchart_deaths_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_deaths_year:SetSize(50, 12)

	self.border_barchart_deaths_year = Turbine.UI.Control()
	self.border_barchart_deaths_year:SetParent(self.barchart_deaths_year)
	self.border_barchart_deaths_year:SetSize(self.barchart_deaths_year:GetWidth(), 1)
	self.border_barchart_deaths_year:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_deaths_year:SetTop(self.barchart_deaths_year:GetHeight() - 24)

	self.hopping_deaths_month = Turbine.UI.Label()
	self.hopping_deaths_month:SetParent(self)
	self.hopping_deaths_month:SetSize(50, 12)
	self.hopping_deaths_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_deaths_month:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_deaths_month:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_deaths_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_deaths_month:SetVisible(false)

	self.hopping_deaths_daily_avg = Turbine.UI.Label()
	self.hopping_deaths_daily_avg:SetParent(self)
	self.hopping_deaths_daily_avg:SetSize(50, 12)
	self.hopping_deaths_daily_avg:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_deaths_daily_avg:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_deaths_daily_avg:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_deaths_daily_avg:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_deaths_daily_avg:SetMouseVisible(false)
	self.hopping_deaths_daily_avg:SetVisible(false)

	-- Deaths Diagram - Stats
	self.statistics_deaths_header = Turbine.UI.Label()
	self.statistics_deaths_header:SetParent(self.barchart_deaths_panel)
	self.statistics_deaths_header:SetSize(self.barchart_deaths_panel:GetWidth(), 20)
	self.statistics_deaths_header:SetPosition(0, self.scrollbar_barchart_deaths_year:GetTop() + self.scrollbar_barchart_deaths_year:GetHeight() + 3)
	self.statistics_deaths_header:SetForeColor(Default_Font_Color)
	self.statistics_deaths_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.statistics_deaths_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.statistics_deaths_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.statistics_deaths_header:SetText(L.Statistics_Header)

	self.statistics_deaths_most_day = Turbine.UI.Label()
	self.statistics_deaths_most_day:SetParent(self.barchart_deaths_panel)
	self.statistics_deaths_most_day:SetSize(self.barchart_deaths_panel:GetWidth(), 12)
	self.statistics_deaths_most_day:SetTop(self.statistics_deaths_header:GetTop() + 18)
	self.statistics_deaths_most_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_deaths_most_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_deaths_most_month = Turbine.UI.Label()
	self.statistics_deaths_most_month:SetParent(self.barchart_deaths_panel)
	self.statistics_deaths_most_month:SetSize(self.barchart_deaths_panel:GetWidth(), 12)
	self.statistics_deaths_most_month:SetTop(self.statistics_deaths_most_day:GetTop() + 13)
	self.statistics_deaths_most_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_deaths_most_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)


	-- Tracks Bar Chart Panel
	self.barchart_tracks_panel = Turbine.UI.Control()
	self.barchart_tracks_panel:SetParent(self)
	self.barchart_tracks_panel:SetSize(self:GetWidth() - 50, self:GetHeight() - 90)
	self.barchart_tracks_panel:SetPosition(self:GetWidth() / 2 - self.barchart_tracks_panel:GetWidth() / 2, 85)

	-- Tracks Diagram - Month
	self.barchart_tracks_month_header = Turbine.UI.Label()
	self.barchart_tracks_month_header:SetParent(self.barchart_tracks_panel)
	self.barchart_tracks_month_header:SetSize(self.barchart_tracks_panel:GetWidth(), 25)
	self.barchart_tracks_month_header:SetForeColor(Default_Font_Color)
	self.barchart_tracks_month_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_tracks_month_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_tracks_month_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_tracks_month_header:SetText(L.Tracks_Header .. " " .. L.Stats_Last_Month)

	self.barchart_tracks_month = Turbine.UI.ListBox()
	self.barchart_tracks_month:SetParent(self.barchart_tracks_panel)
	self.barchart_tracks_month:SetSize(self.barchart_tracks_panel:GetWidth(), 160)
	self.barchart_tracks_month:SetTop(self.barchart_tracks_month_header:GetTop() + self.barchart_tracks_month_header:GetHeight())
	self.barchart_tracks_month:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_tracks_month = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_tracks_month:SetParent(self.barchart_tracks_panel)
	self.scrollbar_barchart_tracks_month:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_tracks_month:SetSize(self.barchart_tracks_month:GetWidth(), 10)
	self.scrollbar_barchart_tracks_month:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_tracks_month:SetPosition(self.barchart_tracks_month:GetLeft(), self.barchart_tracks_month:GetTop() + self.barchart_tracks_month:GetHeight())
	self.barchart_tracks_month:SetHorizontalScrollBar(self.scrollbar_barchart_tracks_month)

	self.topline_barchart_tracks_month = Turbine.UI.Control()
	self.topline_barchart_tracks_month:SetParent(self.barchart_tracks_month)
	self.topline_barchart_tracks_month:SetSize(self.barchart_tracks_month:GetWidth(), 1)
	self.topline_barchart_tracks_month:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_tracks_month = Turbine.UI.Label()
	self.label_topline_barchart_tracks_month:SetParent(self.barchart_tracks_month)
	self.label_topline_barchart_tracks_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_tracks_month:SetSize(50, 12)

	self.bottomline_barchart_tracks_month = Turbine.UI.Control()
	self.bottomline_barchart_tracks_month:SetParent(self.barchart_tracks_month)
	self.bottomline_barchart_tracks_month:SetSize(self.barchart_tracks_month:GetWidth(), 1)
	self.bottomline_barchart_tracks_month:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_tracks_month = Turbine.UI.Label()
	self.label_bottomline_barchart_tracks_month:SetParent(self.barchart_tracks_month)
	self.label_bottomline_barchart_tracks_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_tracks_month:SetSize(50, 12)

	self.border_barchart_tracks_month = Turbine.UI.Control()
	self.border_barchart_tracks_month:SetParent(self.barchart_tracks_month)
	self.border_barchart_tracks_month:SetSize(self.barchart_tracks_month:GetWidth(), 1)
	self.border_barchart_tracks_month:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_tracks_month:SetTop(self.barchart_tracks_month:GetHeight() - 24)

	self.hopping_tracks_day = Turbine.UI.Label()
	self.hopping_tracks_day:SetParent(self)
	self.hopping_tracks_day:SetSize(50, 12)
	self.hopping_tracks_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_tracks_day:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_tracks_day:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_tracks_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_tracks_day:SetVisible(false)

	-- Tracks Diagram - Year
	self.barchart_tracks_year_header = Turbine.UI.Label()
	self.barchart_tracks_year_header:SetParent(self.barchart_tracks_panel)
	self.barchart_tracks_year_header:SetSize(self.barchart_tracks_panel:GetWidth(), 15)
	self.barchart_tracks_year_header:SetPosition(0, self.scrollbar_barchart_tracks_month:GetTop() + self.scrollbar_barchart_tracks_month:GetHeight() + 15)
	self.barchart_tracks_year_header:SetForeColor(Default_Font_Color)
	self.barchart_tracks_year_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.barchart_tracks_year_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.barchart_tracks_year_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.barchart_tracks_year_header:SetText(L.Tracks_Header .. " " .. L.Stats_Last_Year)

	self.barchart_tracks_year = Turbine.UI.ListBox()
	self.barchart_tracks_year:SetParent(self.barchart_tracks_panel)
	self.barchart_tracks_year:SetSize(self.barchart_tracks_panel:GetWidth(), 160)
	self.barchart_tracks_year:SetTop(self.barchart_tracks_year_header:GetTop() + self.barchart_tracks_year_header:GetHeight())
	self.barchart_tracks_year:SetOrientation(Turbine.UI.Orientation.Horizontal)

	self.scrollbar_barchart_tracks_year = Turbine.UI.Lotro.ScrollBar()
	self.scrollbar_barchart_tracks_year:SetParent(self.barchart_tracks_panel)
	self.scrollbar_barchart_tracks_year:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.scrollbar_barchart_tracks_year:SetSize(self.barchart_tracks_year:GetWidth(), 10)
	self.scrollbar_barchart_tracks_year:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.scrollbar_barchart_tracks_year:SetPosition(self.barchart_tracks_year:GetLeft(), self.barchart_tracks_year:GetTop() + self.barchart_tracks_year:GetHeight())
	self.barchart_tracks_year:SetHorizontalScrollBar(self.scrollbar_barchart_tracks_year)

	self.topline_barchart_tracks_year = Turbine.UI.Control()
	self.topline_barchart_tracks_year:SetParent(self.barchart_tracks_year)
	self.topline_barchart_tracks_year:SetSize(self.barchart_tracks_year:GetWidth(), 1)
	self.topline_barchart_tracks_year:SetBackColor(Turbine.UI.Color.White)
	self.label_topline_barchart_tracks_year = Turbine.UI.Label()
	self.label_topline_barchart_tracks_year:SetParent(self.barchart_tracks_year)
	self.label_topline_barchart_tracks_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_topline_barchart_tracks_year:SetSize(50, 12)

	self.bottomline_barchart_tracks_year = Turbine.UI.Control()
	self.bottomline_barchart_tracks_year:SetParent(self.barchart_tracks_year)
	self.bottomline_barchart_tracks_year:SetSize(self.barchart_tracks_year:GetWidth(), 1)
	self.bottomline_barchart_tracks_year:SetBackColor(Turbine.UI.Color.White)
	self.label_bottomline_barchart_tracks_year = Turbine.UI.Label()
	self.label_bottomline_barchart_tracks_year:SetParent(self.barchart_tracks_year)
	self.label_bottomline_barchart_tracks_year:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bottomline_barchart_tracks_year:SetSize(50, 12)

	self.border_barchart_tracks_year = Turbine.UI.Control()
	self.border_barchart_tracks_year:SetParent(self.barchart_tracks_year)
	self.border_barchart_tracks_year:SetSize(self.barchart_tracks_year:GetWidth(), 1)
	self.border_barchart_tracks_year:SetBackColor(Turbine.UI.Color.White)
	self.border_barchart_tracks_year:SetTop(self.barchart_tracks_year:GetHeight() - 24)

	self.hopping_tracks_month = Turbine.UI.Label()
	self.hopping_tracks_month:SetParent(self)
	self.hopping_tracks_month:SetSize(50, 12)
	self.hopping_tracks_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_tracks_month:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_tracks_month:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_tracks_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_tracks_month:SetVisible(false)

	self.hopping_tracks_daily_avg = Turbine.UI.Label()
	self.hopping_tracks_daily_avg:SetParent(self)
	self.hopping_tracks_daily_avg:SetSize(50, 12)
	self.hopping_tracks_daily_avg:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.hopping_tracks_daily_avg:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.hopping_tracks_daily_avg:SetOutlineColor(Turbine.UI.Color.Black)
	self.hopping_tracks_daily_avg:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.hopping_tracks_daily_avg:SetMouseVisible(false)
	self.hopping_tracks_daily_avg:SetVisible(false)

	-- Tracks Diagram - Stats
	self.statistics_tracks_header = Turbine.UI.Label()
	self.statistics_tracks_header:SetParent(self.barchart_tracks_panel)
	self.statistics_tracks_header:SetSize(self.barchart_tracks_panel:GetWidth(), 20)
	self.statistics_tracks_header:SetPosition(0, self.scrollbar_barchart_tracks_year:GetTop() + self.scrollbar_barchart_tracks_year:GetHeight() + 3)
	self.statistics_tracks_header:SetForeColor(Default_Font_Color)
	self.statistics_tracks_header:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.statistics_tracks_header:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.statistics_tracks_header:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.statistics_tracks_header:SetText(L.Statistics_Header)

	self.statistics_tracks_most_day = Turbine.UI.Label()
	self.statistics_tracks_most_day:SetParent(self.barchart_tracks_panel)
	self.statistics_tracks_most_day:SetSize(self.barchart_tracks_panel:GetWidth(), 12)
	self.statistics_tracks_most_day:SetTop(self.statistics_tracks_header:GetTop() + 18)
	self.statistics_tracks_most_day:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_tracks_most_day:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

	self.statistics_tracks_most_month = Turbine.UI.Label()
	self.statistics_tracks_most_month:SetParent(self.barchart_tracks_panel)
	self.statistics_tracks_most_month:SetSize(self.barchart_tracks_panel:GetWidth(), 12)
	self.statistics_tracks_most_month:SetTop(self.statistics_tracks_most_day:GetTop() + 13)
	self.statistics_tracks_most_month:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.statistics_tracks_most_month:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)


	self.KeyDown = function(sender,args) 
		if args.Action == Turbine.UI.Lotro.Action.Escape then
			self:SetVisible(false)
		end
	end

	self.PositionChanged = function(sender, args)
		data.numbers.statsWin_x = self:GetLeft()
		data.numbers.statsWin_y = self:GetTop()
	end
end

function StatsWindow:UpdateStatsPanel()
	local points_last_24_hours, points_last_hour, points_last_10_minutes	= GetRecentData(data.numbers.recent_points)
	local comms_last_24_hours, comms_last_hour, comms_last_10_minutes		= GetRecentData(data.numbers.recent_comms)
	local frags_last_24_hours, frags_last_hour, frags_last_10_minutes		= GetRecentData(data.numbers.recent_frags)
	local deaths_last_24_hours, deaths_last_hour, deaths_last_10_minutes	= GetRecentData(data.numbers.recent_deaths)
	local tracks_last_24_hours, tracks_last_hour, tracks_last_10_minutes	= GetRecentData(data.numbers.recent_tracks)

	if data.numbers.points_total == Ranks[#Ranks] then
		self.statslabel_rank:SetText(L.Stats_Rank .. #Ranks .. " - " .. Rank_Names[#Rank_Names])
	else
		for i = 0, #Ranks - 1 do
			if (data.numbers.points_total >= Ranks[i] and data.numbers.points_total < Ranks[i + 1]) then
				self.statslabel_rank:SetText(L.Stats_Rank .. i .. " - " .. Rank_Names[i])
				break
			end
		end
	end

	if data.numbers.frags_total >= Tiers[#Tiers] then
		self.statslabel_tier:SetText(L.Stats_Tier .. #Tiers .. " - " .. Tier_Names[#Tier_Names])
	else
		for j = 0, #Tiers - 1 do
			if (data.numbers.frags_total >= Tiers[j] and data.numbers.frags_total < Tiers[j + 1]) then
				self.statslabel_tier:SetText(L.Stats_Tier .. j .. " - " .. Tier_Names[j])
				break
			end
		end
	end

	self.statslabel_points_total_value:SetText(FormatPoints(data.numbers.points_total))
	self.statslabel_points_to_rankup_value:SetText(FormatPoints(GetRemainingPoints()))
	self.statslabel_points_last_24h_value:SetText(points_last_24_hours)
	self.statslabel_points_this_day_value:SetText(FormatPoints(data.numbers.points_current_day))
	self.statslabel_points_last_hour_value:SetText(points_last_hour)
	self.statslabel_points_last_10min_value:SetText(points_last_10_minutes)
	self.statslabel_points_last_fight_value:SetText(FormatPoints(Points_Last_Fight))

	self.statslabel_commendations_total_value:SetText(FormatPoints(data.numbers.comms_all_time))
	self.statslabel_commendations_current_value:SetText(FormatPoints(Current_Commendations))
	self.statslabel_commendations_last_24h_value:SetText(comms_last_24_hours)
	self.statslabel_commendations_this_day_value:SetText(FormatPoints(data.numbers.comms_current_day))
	self.statslabel_commendations_last_hour_value:SetText(comms_last_hour)
	self.statslabel_commendations_last_10min_value:SetText(comms_last_10_minutes)
	self.statslabel_commendations_last_fight_value:SetText(FormatPoints(Comms_Last_Fight))

	self.statslabel_killing_blows_total_value:SetText(FormatPoints(data.numbers.frags_total))
	self.statslabel_killing_blows_to_tierup_value:SetText(FormatPoints(GetRemainingFrags()))
	self.statslabel_killing_blows_last_24h_value:SetText(frags_last_24_hours)
	self.statslabel_killing_blows_this_day_value:SetText(FormatPoints(data.numbers.frags_current_day))
	self.statslabel_killing_blows_last_hour_value:SetText(frags_last_hour)
	self.statslabel_killing_blows_last_10min_value:SetText(frags_last_10_minutes)
	self.statslabel_killing_blows_last_fight_value:SetText(FormatPoints(Frags_Last_Fight))

	self.statslabel_deaths_last_24h_value:SetText(deaths_last_24_hours)
	self.statslabel_deaths_this_day_value:SetText(FormatPoints(data.numbers.deaths_current_day))
	self.statslabel_deaths_last_hour_value:SetText(deaths_last_hour)
	self.statslabel_deaths_last_10min_value:SetText(deaths_last_10_minutes)

	self.statslabel_tracks_total_value:SetText(FormatPoints(data.numbers.tracks_total))
	self.statslabel_tracks_last_24h_value:SetText(tracks_last_24_hours)
	self.statslabel_tracks_this_day_value:SetText(FormatPoints(data.numbers.tracks_current_day))
	self.statslabel_tracks_last_hour_value:SetText(tracks_last_hour)
	self.statslabel_tracks_last_10min_value:SetText(tracks_last_10_minutes)
end

function StatsWindow:UpdateFragList(sortmode)
	local total_victim_amount = 0
	local total_frag_amount = 0
	local search_pattern = string.lower(self.search_box:GetText())
	self.frag_list:ClearItems()

	for name, frags in pairs(data.numbers.frags) do
		if string.match(string.lower(name), search_pattern) then
			total_victim_amount = total_victim_amount + 1
			total_frag_amount = total_frag_amount + frags

			local listItem = Turbine.UI.Control()
			listItem:SetSize(self.frag_list:GetWidth(), 15)

			listItem.Name = Turbine.UI.Label()
			listItem.Name:SetFont(Turbine.UI.Lotro.Font.Verdana14)
			listItem.Name:SetSize(self.frag_list:GetWidth() * 3/4, listItem:GetHeight() - 1)
			listItem.Name:SetParent(listItem)
			listItem.Name:SetText(name)

			listItem.Kills = Turbine.UI.Label()
			listItem.Kills:SetFont(Turbine.UI.Lotro.Font.Verdana14)
			listItem.Kills:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
			listItem.Kills:SetSize(self.frag_list:GetWidth() * 1/4, listItem:GetHeight() - 1)
			listItem.Kills:SetParent(listItem)
			listItem.Kills:SetText(FormatPoints(frags))
			listItem.Kills:SetLeft(listItem.Name:GetWidth())

			listItem.separator = Turbine.UI.Control()
			listItem.separator:SetParent(listItem)
			listItem.separator:SetSize(listItem:GetWidth(), 1)
			listItem.separator:SetTop(14)
			listItem.separator:SetBackColor(Grey_Font_Color)
			self.frag_list:AddItem(listItem)
		end
	end

	self.label_name:SetText(L.Log_Name .. " (" .. FormatPoints(total_victim_amount) .. ")")
	self.label_frags:SetText(L.Log_KillingBlows .. " (" .. FormatPoints(total_frag_amount) .. ")")

	self.frag_list:SetSelectedIndex(1)
	self:SortFragList(sortmode)
end

function StatsWindow:SortFragList(sortmode)
	self.frag_list:Sort(sortmode.funct)
	self.current_sortmode = sortmode
end

function StatsWindow:UpdateBarChartPoints()
	local current_date = Turbine.Engine.GetDate()

	local points_last_month = {}
	local points_last_year = {}
	local frags_last_month = {}
	local frags_last_year = {}

	local max_points_this_month = 0
	local max_points_this_year = 0

	local threshold_month = 500
	local threshold_year = 5000

	self.barchart_points_month:ClearItems()
	self.barchart_points_year:ClearItems()

	for i = 0, Days_To_Display - 1 do
		local day_of_year = current_date.DayOfYear - i
		if day_of_year < 1 then day_of_year = day_of_year + GetDaysPerYear(current_date.Year - 1) end
		local points = data.numbers.history.points[day_of_year]
		local frags = data.numbers.history.frags[day_of_year]
		if day_of_year == data.numbers.current_day then
			points = data.numbers.points_current_day
			frags = data.numbers.frags_current_day
		end
		local day = current_date.Day - i
		local month = current_date.Month
		local year = current_date.Year
		while day < 1 do
			month = month - 1
			if month == 0 then
				month = 12
				year = year - 1
			end
			day = GetDaysPerMonth(month, year) + day
		end

		if (points or 0) >= max_points_this_month then max_points_this_month = (points or 0) end

		points_last_month[Days_To_Display - i] = { day, L.Months[month], points or 0 }
		frags_last_month[Days_To_Display - i] = { day, L.Months[month], frags or 0 }
	end

	if data.numbers.current_day == current_date.DayOfYear then
		points_last_month[Days_To_Display] = { current_date.Day, L.Months[current_date.Month], data.numbers.points_current_day }
		frags_last_month[Days_To_Display] = { current_date.Day, L.Months[current_date.Month], data.numbers.frags_current_day }
	end

	for i = 0, Months_To_Display - 1 do
		local month_of_year = (current_date.Month - i) % Months_To_Display
		if month_of_year == 0 then month_of_year = Months_To_Display end
		local points = data.numbers.history.pointsMonth[month_of_year]
		local frags = data.numbers.history.fragsMonth[month_of_year]
		if month_of_year == data.numbers.current_month then
			points = data.numbers.points_current_month
			frags = data.numbers.frags_current_month
		end
		local month = current_date.Month - i
		local year = current_date.Year

		if month < 1 then
			year = year - 1
			month = month + Months_To_Display
		end

		if (points or 0) >= max_points_this_year then max_points_this_year = (points or 0) end

		points_last_year[Months_To_Display - i] = { L.Months[month], year, points or 0 }
		frags_last_year[Months_To_Display - i] = { L.Months[month], year, frags or 0 }
	end

	if data.numbers.current_month == current_date.Month then
		points_last_year[Months_To_Display] = { L.Months[current_date.Month], current_date.Year, data.numbers.points_current_month }
		frags_last_year[Months_To_Display] = { L.Months[current_date.Month], current_date.Year, data.numbers.frags_current_month }
	end

	if data.numbers.points_current_day >= max_points_this_month then
		max_points_this_month = data.numbers.points_current_day
	end

	if data.numbers.points_current_month >= max_points_this_year then
		max_points_this_year = data.numbers.points_current_month
	end

	-- Points Month
	local height_barchart_points_month = self.barchart_points_month:GetHeight() - 24

	if max_points_this_month < threshold_month then
		max_points_this_month = threshold_month
	elseif max_points_this_month - ThresholdRound(max_points_this_month, threshold_month) >= (threshold_month / 5) then
		max_points_this_month = ThresholdRound(max_points_this_month, threshold_month) + threshold_month
	else
		max_points_this_month = ThresholdRound(max_points_this_month, threshold_month)
	end

	local topline_barchart_points_month_value = max_points_this_month

	if max_points_this_month < ThresholdRound(max_points_this_month, threshold_month) + max_points_this_month * 12 / self.barchart_points_month:GetHeight() then
		max_points_this_month = max_points_this_month + max_points_this_month * 12 / self.barchart_points_month:GetHeight()
	end

	for index, points in pairs(points_last_month) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_points_month:GetWidth() / 12.5 - 2, self.barchart_points_month:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_points_month * (points[3] / max_points_this_month))
		subItem:SetTop(height_barchart_points_month - subItem:GetHeight())
		local points_amount = Turbine.UI.Label()
		points_amount:SetParent(listItem)
		points_amount:SetText(points[3])
		points_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_points_day:SetPosition(
				self.barchart_points_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_points_day:GetWidth() / 2,
				self.barchart_points_panel:GetTop() + self.barchart_points_month:GetTop() + subItem:GetTop() - self.hopping_points_day:GetHeight()
			)
			self.hopping_points_day:SetText(FormatPoints(points_amount:GetText()))
			self.hopping_points_day:SetVisible(true)

			local points_per_frag = 0
			if frags_last_month[index][3] == 0 then
				points_per_frag = points[3] / 1
			else
				points_per_frag = math.floor((points[3] / frags_last_month[index][3]) + 0.5)
			end

			self.statistics_points_per_frag:SetText(L.Stats_Points_Per_KillingBlow .. FormatPoints(points_per_frag))
			self.statistics_points_per_frag:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_points_day:SetVisible(false)

			self.statistics_points_per_frag:SetVisible(false)
		end
		local dateItemDay = Turbine.UI.Label()
		dateItemDay:SetParent(listItem)
		dateItemDay:SetSize(listItem:GetWidth(), 12)
		dateItemDay:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemDay:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemDay:SetText(points[1])
		dateItemDay:SetTop(listItem:GetHeight() - dateItemDay:GetHeight() * 2)

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(points[2])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight())

		self.barchart_points_month:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_points_month:GetHeight())
		self.barchart_points_month:AddItem(separator)
	end
	self.barchart_points_month:RemoveItemAt(self.barchart_points_month:GetItemCount())

	self.topline_barchart_points_month:SetTop(height_barchart_points_month - height_barchart_points_month * topline_barchart_points_month_value / max_points_this_month)
	self.label_topline_barchart_points_month:SetText(FormatPoints(topline_barchart_points_month_value))
	self.label_topline_barchart_points_month:SetTop(self.topline_barchart_points_month:GetTop() - 11)

	local bottomline_barchart_points_month_value = topline_barchart_points_month_value / 2
	self.bottomline_barchart_points_month:SetTop(height_barchart_points_month - height_barchart_points_month * bottomline_barchart_points_month_value / max_points_this_month)
	self.label_bottomline_barchart_points_month:SetText(FormatPoints(bottomline_barchart_points_month_value))
	self.label_bottomline_barchart_points_month:SetTop(self.bottomline_barchart_points_month:GetTop() - 11)

	self.barchart_points_month:SetSelectedIndex(self.barchart_points_month:GetItemCount())

	-- Points Year
	local height_barchart_points_year = self.barchart_points_year:GetHeight() - 24

	if max_points_this_year < threshold_year then
		max_points_this_year = threshold_year
	elseif max_points_this_year - ThresholdRound(max_points_this_year, threshold_year) >= (threshold_year / 5) then
		max_points_this_year = ThresholdRound(max_points_this_year, threshold_year) + threshold_year
	else
		max_points_this_year = ThresholdRound(max_points_this_year, threshold_year)
	end

	local topline_barchart_points_year_value = max_points_this_year

	if max_points_this_year < ThresholdRound(max_points_this_year, threshold_year) + max_points_this_year * 12 / self.barchart_points_year:GetHeight() then
		max_points_this_year = max_points_this_year + max_points_this_year * 12 / self.barchart_points_year:GetHeight()
	end

	for index, points in pairs(points_last_year) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_points_year:GetWidth() / 11.5 - 2, self.barchart_points_year:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_points_year * (points[3] / max_points_this_year))
		subItem:SetTop(height_barchart_points_year - subItem:GetHeight())
		local points_amount = Turbine.UI.Label()
		points_amount:SetParent(listItem)
		points_amount:SetText(points[3])
		points_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_points_month:SetPosition(
				self.barchart_points_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_points_month:GetWidth() / 2,
				self.barchart_points_panel:GetTop() + self.barchart_points_year:GetTop() + subItem:GetTop() - self.hopping_points_month:GetHeight()
			)
			self.hopping_points_month:SetText(FormatPoints(points_amount:GetText()))
			self.hopping_points_month:SetVisible(true)

			self.hopping_points_daily_avg:SetPosition(
				self.barchart_points_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_points_daily_avg:GetWidth() / 2,
				self.barchart_points_panel:GetHeight() - listItem:GetHeight() / 3.2
			)
			if points[1] == L.Months[current_date.Month] then
				self.hopping_points_daily_avg:SetText(FormatPoints(math.floor(points_amount:GetText() / current_date.Day)))
			else
				self.hopping_points_daily_avg:SetText(FormatPoints(math.floor(points_amount:GetText() / GetDaysPerMonth(points[1], points[2]))))
			end
			self.hopping_points_daily_avg:SetVisible(true)

			local points_per_frag = 0
			if frags_last_year[index][3] == 0 then
				points_per_frag = points[3] / 1
			else
				points_per_frag = math.floor((points[3] / frags_last_year[index][3]) + 0.5)
			end

			self.statistics_points_per_frag:SetText(L.Stats_Points_Per_KillingBlow .. FormatPoints(points_per_frag))
			self.statistics_points_per_frag:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_points_month:SetVisible(false)
			self.hopping_points_daily_avg:SetVisible(false)

			self.statistics_points_per_frag:SetVisible(false)
		end

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(points[1])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight() * 2)

		local dateItemYear = Turbine.UI.Label()
		dateItemYear:SetParent(listItem)
		dateItemYear:SetSize(listItem:GetWidth(), 12)
		dateItemYear:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemYear:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemYear:SetText(points[2])
		dateItemYear:SetTop(listItem:GetHeight() - dateItemYear:GetHeight())

		self.barchart_points_year:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_points_year:GetHeight())
		self.barchart_points_year:AddItem(separator)
	end
	self.barchart_points_year:RemoveItemAt(self.barchart_points_year:GetItemCount())

	self.topline_barchart_points_year:SetTop(height_barchart_points_year - height_barchart_points_year * topline_barchart_points_year_value / max_points_this_year)
	self.label_topline_barchart_points_year:SetText(FormatPoints(topline_barchart_points_year_value))
	self.label_topline_barchart_points_year:SetTop(self.topline_barchart_points_year:GetTop() - 11)

	local bottomline_barchart_points_year_value = topline_barchart_points_year_value / 2
	self.bottomline_barchart_points_year:SetTop(height_barchart_points_year - height_barchart_points_year * bottomline_barchart_points_year_value / max_points_this_year)
	self.label_bottomline_barchart_points_year:SetText(FormatPoints(bottomline_barchart_points_year_value))
	self.label_bottomline_barchart_points_year:SetTop(self.bottomline_barchart_points_year:GetTop() - 11)

	self.barchart_points_year:SetSelectedIndex(self.barchart_points_year:GetItemCount())

	-- Points Stats
	self.statistics_points_most_frag:SetText(L.Stats_Maximum_Kill .. FormatPoints(data.numbers.most_points_a_fight[1]) .. " (" ..
	data.numbers.most_points_a_fight[2] .. " " .. L.Months[data.numbers.most_points_a_fight[3]] .. " " .. data.numbers.most_points_a_fight[4] .. ")")

	self.statistics_points_most_day:SetText(L.Stats_Maximum_Day .. FormatPoints(data.numbers.most_points_a_day[1]) .. " (" ..
	data.numbers.most_points_a_day[2] .. " " .. L.Months[data.numbers.most_points_a_day[3]] .. " " .. data.numbers.most_points_a_day[4] .. ")")

	self.statistics_points_most_month:SetText(L.Stats_Maximum_Month .. FormatPoints(data.numbers.most_points_a_month[1]) .. " (" ..
	L.Months[data.numbers.most_points_a_month[2]] .. " " .. data.numbers.most_points_a_month[3] .. ")")
end

function StatsWindow:UpdateBarChartComms()
	local current_date = Turbine.Engine.GetDate()

	local comms_last_month = {}
	local comms_last_year = {}

	local max_comms_this_month = 0
	local max_comms_this_year = 0

	local threshold_month = 500
	local threshold_year = 5000

	self.barchart_comms_month:ClearItems()
	self.barchart_comms_year:ClearItems()

	for i = 0, Days_To_Display - 1 do
		local day_of_year = current_date.DayOfYear - i
		if day_of_year < 1 then day_of_year = day_of_year + GetDaysPerYear(current_date.Year - 1) end
		local comms = data.numbers.history.comms[day_of_year]
		if day_of_year == data.numbers.current_day then
			comms = data.numbers.comms_current_day
		end
		local day = current_date.Day - i
		local month = current_date.Month
		local year = current_date.Year
		while day < 1 do
			month = month - 1
			if month == 0 then
				month = 12
				year = year - 1
			end
			day = GetDaysPerMonth(month, year) + day
		end

		if (comms or 0) >= max_comms_this_month then max_comms_this_month = (comms or 0) end

		comms_last_month[Days_To_Display - i] = { day, L.Months[month], comms or 0 }
	end

	if data.numbers.current_day == current_date.DayOfYear then
		comms_last_month[Days_To_Display] = { current_date.Day, L.Months[current_date.Month], data.numbers.comms_current_day }
	end

	for i = 0, Months_To_Display - 1 do
		local month_of_year = (current_date.Month - i) % Months_To_Display
		if month_of_year == 0 then month_of_year = Months_To_Display end
		local comms = data.numbers.history.commsMonth[month_of_year]
		if month_of_year == data.numbers.current_month then
			comms = data.numbers.comms_current_month
		end
		local month = current_date.Month - i
		local year = current_date.Year

		if month < 1 then
			year = year - 1
			month = month + Months_To_Display
		end

		if (comms or 0) >= max_comms_this_year then max_comms_this_year = (comms or 0) end

		comms_last_year[Months_To_Display - i] = { L.Months[month], year, comms or 0 }
	end

	if data.numbers.current_month == current_date.Month then
		comms_last_year[Months_To_Display] = { L.Months[current_date.Month], current_date.Year, data.numbers.comms_current_month }
	end

	if data.numbers.comms_current_day >= max_comms_this_month then
		max_comms_this_month = data.numbers.comms_current_day
	end

	if data.numbers.comms_current_month >= max_comms_this_year then
		max_comms_this_year = data.numbers.comms_current_month
	end

	-- Comms Month
	local height_barchart_comms_month = self.barchart_comms_month:GetHeight() - 24

	if max_comms_this_month < threshold_month then
		max_comms_this_month = threshold_month
	elseif max_comms_this_month - ThresholdRound(max_comms_this_month, threshold_month) >= (threshold_month / 5) then
		max_comms_this_month = ThresholdRound(max_comms_this_month, threshold_month) + threshold_month
	else
		max_comms_this_month = ThresholdRound(max_comms_this_month, threshold_month)
	end

	local topline_barchart_comms_month_value = max_comms_this_month

	if max_comms_this_month < ThresholdRound(max_comms_this_month, threshold_month) + max_comms_this_month * 12 / self.barchart_comms_month:GetHeight() then
		max_comms_this_month = max_comms_this_month + max_comms_this_month * 12 / self.barchart_comms_month:GetHeight()
	end

	for index, comms in pairs(comms_last_month) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_comms_month:GetWidth() / 12.5 - 2, self.barchart_comms_month:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_comms_month * (comms[3] / max_comms_this_month))
		subItem:SetTop(height_barchart_comms_month - subItem:GetHeight())
		local comms_amount = Turbine.UI.Label()
		comms_amount:SetParent(listItem)
		comms_amount:SetText(comms[3])
		comms_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_comms_day:SetPosition(
				self.barchart_comms_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_comms_day:GetWidth() / 2,
				self.barchart_comms_panel:GetTop() + self.barchart_comms_month:GetTop() + subItem:GetTop() - self.hopping_comms_day:GetHeight()
			)
			self.hopping_comms_day:SetText(FormatPoints(comms_amount:GetText()))
			self.hopping_comms_day:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_comms_day:SetVisible(false)
		end
		local dateItemDay = Turbine.UI.Label()
		dateItemDay:SetParent(listItem)
		dateItemDay:SetSize(listItem:GetWidth(), 12)
		dateItemDay:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemDay:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemDay:SetText(comms[1])
		dateItemDay:SetTop(listItem:GetHeight() - dateItemDay:GetHeight() * 2)

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(comms[2])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight())

		self.barchart_comms_month:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_comms_month:GetHeight())
		self.barchart_comms_month:AddItem(separator)
	end
	self.barchart_comms_month:RemoveItemAt(self.barchart_comms_month:GetItemCount())

	self.topline_barchart_comms_month:SetTop(height_barchart_comms_month - height_barchart_comms_month * topline_barchart_comms_month_value / max_comms_this_month)
	self.label_topline_barchart_comms_month:SetText(FormatPoints(topline_barchart_comms_month_value))
	self.label_topline_barchart_comms_month:SetTop(self.topline_barchart_comms_month:GetTop() - 11)

	local bottomline_barchart_comms_month_value = topline_barchart_comms_month_value / 2
	self.bottomline_barchart_comms_month:SetTop(height_barchart_comms_month - height_barchart_comms_month * bottomline_barchart_comms_month_value / max_comms_this_month)
	self.label_bottomline_barchart_comms_month:SetText(FormatPoints(bottomline_barchart_comms_month_value))
	self.label_bottomline_barchart_comms_month:SetTop(self.bottomline_barchart_comms_month:GetTop() - 11)

	self.barchart_comms_month:SetSelectedIndex(self.barchart_comms_month:GetItemCount())

	-- Comms Year
	local height_barchart_comms_year = self.barchart_comms_year:GetHeight() - 24

	if max_comms_this_year < threshold_year then
		max_comms_this_year = threshold_year
	elseif max_comms_this_year - ThresholdRound(max_comms_this_year, threshold_year) >= (threshold_year / 5) then
		max_comms_this_year = ThresholdRound(max_comms_this_year, threshold_year) + threshold_year
	else
		max_comms_this_year = ThresholdRound(max_comms_this_year, threshold_year)
	end

	local topline_barchart_comms_year_value = max_comms_this_year

	if max_comms_this_year < ThresholdRound(max_comms_this_year, threshold_year) + max_comms_this_year * 12 / self.barchart_comms_year:GetHeight() then
		max_comms_this_year = max_comms_this_year + max_comms_this_year * 12 / self.barchart_comms_year:GetHeight()
	end

	for index, comms in pairs(comms_last_year) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_comms_year:GetWidth() / 11.5 - 2, self.barchart_comms_year:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_comms_year * (comms[3] / max_comms_this_year))
		subItem:SetTop(height_barchart_comms_year - subItem:GetHeight())
		local comms_amount = Turbine.UI.Label()
		comms_amount:SetParent(listItem)
		comms_amount:SetText(comms[3])
		comms_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_comms_month:SetPosition(
				self.barchart_comms_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_comms_month:GetWidth() / 2,
				self.barchart_comms_panel:GetTop() + self.barchart_comms_year:GetTop() + subItem:GetTop() - self.hopping_comms_month:GetHeight()
			)
			self.hopping_comms_month:SetText(FormatPoints(comms_amount:GetText()))
			self.hopping_comms_month:SetVisible(true)

			self.hopping_comms_daily_avg:SetPosition(
				self.barchart_comms_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_comms_daily_avg:GetWidth() / 2,
				self.barchart_comms_panel:GetHeight() - listItem:GetHeight() / 3.2
			)
			if comms[1] == L.Months[current_date.Month] then
				self.hopping_comms_daily_avg:SetText(FormatPoints(math.floor(comms_amount:GetText() / current_date.Day)))
			else
				self.hopping_comms_daily_avg:SetText(FormatPoints(math.floor(comms_amount:GetText() / GetDaysPerMonth(comms[1], comms[2]))))
			end
			self.hopping_comms_daily_avg:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_comms_month:SetVisible(false)
			self.hopping_comms_daily_avg:SetVisible(false)
		end

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(comms[1])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight() * 2)

		local dateItemYear = Turbine.UI.Label()
		dateItemYear:SetParent(listItem)
		dateItemYear:SetSize(listItem:GetWidth(), 12)
		dateItemYear:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemYear:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemYear:SetText(comms[2])
		dateItemYear:SetTop(listItem:GetHeight() - dateItemYear:GetHeight())

		self.barchart_comms_year:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_comms_year:GetHeight())
		self.barchart_comms_year:AddItem(separator)
	end
	self.barchart_comms_year:RemoveItemAt(self.barchart_comms_year:GetItemCount())

	self.topline_barchart_comms_year:SetTop(height_barchart_comms_year - height_barchart_comms_year * topline_barchart_comms_year_value / max_comms_this_year)
	self.label_topline_barchart_comms_year:SetText(FormatPoints(topline_barchart_comms_year_value))
	self.label_topline_barchart_comms_year:SetTop(self.topline_barchart_comms_year:GetTop() - 11)

	local bottomline_barchart_comms_year_value = topline_barchart_comms_year_value / 2
	self.bottomline_barchart_comms_year:SetTop(height_barchart_comms_year - height_barchart_comms_year * bottomline_barchart_comms_year_value / max_comms_this_year)
	self.label_bottomline_barchart_comms_year:SetText(FormatPoints(bottomline_barchart_comms_year_value))
	self.label_bottomline_barchart_comms_year:SetTop(self.bottomline_barchart_comms_year:GetTop() - 11)

	self.barchart_comms_year:SetSelectedIndex(self.barchart_comms_year:GetItemCount())

	-- Comms Stats
	self.statistics_comms_most_day:SetText(L.Stats_Maximum_Day .. FormatPoints(data.numbers.most_comms_a_day[1]) .. " (" ..
	data.numbers.most_comms_a_day[2] .. " " .. L.Months[data.numbers.most_comms_a_day[3]] .. " " .. data.numbers.most_comms_a_day[4] .. ")")

	self.statistics_comms_most_month:SetText(L.Stats_Maximum_Month .. FormatPoints(data.numbers.most_comms_a_month[1]) .. " (" ..
	L.Months[data.numbers.most_comms_a_month[2]] .. " " .. data.numbers.most_comms_a_month[3] .. ")")
end

function StatsWindow:UpdateBarChartFrags()
	local current_date = Turbine.Engine.GetDate()

	local frags_last_month = {}
	local frags_last_year = {}
	local deaths_last_month = {}
	local deaths_last_year = {}

	local max_frags_this_month = 0
	local max_frags_this_year = 0

	local threshold_month = 10
	local threshold_year = 50

	self.barchart_frags_month:ClearItems()
	self.barchart_frags_year:ClearItems()

	for i = 0, Days_To_Display - 1 do
		local day_of_year = current_date.DayOfYear - i
		if day_of_year < 1 then day_of_year = day_of_year + GetDaysPerYear(current_date.Year - 1) end
		local frags = data.numbers.history.frags[day_of_year]
		local deaths = data.numbers.history.deaths[day_of_year]
		if day_of_year == data.numbers.current_day then
			frags = data.numbers.frags_current_day
			deaths = data.numbers.deaths_current_day
		end
		local day = current_date.Day - i
		local month = current_date.Month
		local year = current_date.Year
		while day < 1 do
			month = month - 1
			if month == 0 then
				month = 12
				year = year - 1
			end
			day = GetDaysPerMonth(month, year) + day
		end

		if (frags or 0) >= max_frags_this_month then max_frags_this_month = (frags or 0) end

		frags_last_month[Days_To_Display - i] = { day, L.Months[month], frags or 0 }
		deaths_last_month[Days_To_Display - i] = { day, L.Months[month], deaths or 0 }
	end

	if data.numbers.current_day == current_date.DayOfYear then
		frags_last_month[Days_To_Display] = { current_date.Day, L.Months[current_date.Month], data.numbers.frags_current_day }
		deaths_last_month[Days_To_Display] = { current_date.Day, L.Months[current_date.Month], data.numbers.deaths_current_day }
	end

	for i = 0, Months_To_Display - 1 do
		local month_of_year = (current_date.Month - i) % Months_To_Display
		if month_of_year == 0 then month_of_year = Months_To_Display end
		local frags = data.numbers.history.fragsMonth[month_of_year]
		local deaths = data.numbers.history.deathsMonth[month_of_year]
		if month_of_year == data.numbers.current_month then
			frags = data.numbers.frags_current_month
			deaths = data.numbers.deaths_current_month
		end
		local month = current_date.Month - i
		local year = current_date.Year

		if month < 1 then
			year = year - 1
			month = month + Months_To_Display
		end

		if (frags or 0) >= max_frags_this_year then max_frags_this_year = (frags or 0) end

		frags_last_year[Months_To_Display - i] = { L.Months[month], year, frags or 0 }
		deaths_last_year[Months_To_Display - i] = { L.Months[month], year, deaths or 0 }
	end

	if data.numbers.current_month == current_date.Month then
		frags_last_year[Months_To_Display] = { L.Months[current_date.Month], current_date.Year, data.numbers.frags_current_month }
		deaths_last_year[Months_To_Display] = { L.Months[current_date.Month], current_date.Year, data.numbers.deaths_current_month }
	end

	if data.numbers.frags_current_day >= max_frags_this_year then
		max_frags_this_year = data.numbers.frags_current_day
	end

	if data.numbers.frags_current_month >= max_frags_this_year then
		max_frags_this_year = data.numbers.frags_current_month
	end

	-- Frags Month
	local height_barchart_frags_month = self.barchart_frags_month:GetHeight() - 24

	if max_frags_this_month < threshold_month then
		max_frags_this_month = threshold_month
	elseif max_frags_this_month - ThresholdRound(max_frags_this_month, threshold_month) >= (threshold_month / 5) then
		max_frags_this_month = ThresholdRound(max_frags_this_month, threshold_month) + threshold_month
	else
		max_frags_this_month = ThresholdRound(max_frags_this_month, threshold_month)
	end

	local topline_barchart_frags_month_value = max_frags_this_month

	if max_frags_this_month < ThresholdRound(max_frags_this_month, threshold_month) + max_frags_this_month * 12 / self.barchart_frags_month:GetHeight() then
		max_frags_this_month = max_frags_this_month + max_frags_this_month * 12 / self.barchart_frags_month:GetHeight()
	end

	for index, frags in pairs(frags_last_month) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_frags_month:GetWidth() / 12.5 - 2, self.barchart_frags_month:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_frags_month * (frags[3] / max_frags_this_month))
		subItem:SetTop(height_barchart_frags_month - subItem:GetHeight())
		local frags_amount = Turbine.UI.Label()
		frags_amount:SetParent(listItem)
		frags_amount:SetText(frags[3])
		frags_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_frags_day:SetPosition(
				self.barchart_frags_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_frags_day:GetWidth() / 2,
				self.barchart_frags_panel:GetTop() + self.barchart_frags_month:GetTop() + subItem:GetTop() - self.hopping_frags_day:GetHeight()
			)
			self.hopping_frags_day:SetText(frags_amount:GetText())
			self.hopping_frags_day:SetVisible(true)

			local frags_per_death = Round(frags[3] / deaths_last_month[index][3])
			if deaths_last_month[index][3] == 0 then
				frags_per_death = Round(frags[3] / 1)
			end

			self.statistics_frags_per_death:SetText(L.Stats_KillingBlows_Per_Death .. frags_per_death .. " (" .. frags[3] .. " : " .. deaths_last_month[index][3] .. ")")
			self.statistics_frags_per_death:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_frags_day:SetVisible(false)

			self.statistics_frags_per_death:SetVisible(false)
		end
		local dateItemDay = Turbine.UI.Label()
		dateItemDay:SetParent(listItem)
		dateItemDay:SetSize(listItem:GetWidth(), 12)
		dateItemDay:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemDay:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemDay:SetText(frags[1])
		dateItemDay:SetTop(listItem:GetHeight() - dateItemDay:GetHeight() * 2)

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(frags[2])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight())

		self.barchart_frags_month:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_frags_month:GetHeight())
		self.barchart_frags_month:AddItem(separator)
	end
	self.barchart_frags_month:RemoveItemAt(self.barchart_frags_month:GetItemCount())

	self.topline_barchart_frags_month:SetTop(height_barchart_frags_month - height_barchart_frags_month * topline_barchart_frags_month_value / max_frags_this_month)
	self.label_topline_barchart_frags_month:SetText(topline_barchart_frags_month_value)
	self.label_topline_barchart_frags_month:SetTop(self.topline_barchart_frags_month:GetTop() - 11)

	local bottomline_barchart_frags_month_value = topline_barchart_frags_month_value / 2
	self.bottomline_barchart_frags_month:SetTop(height_barchart_frags_month - height_barchart_frags_month * bottomline_barchart_frags_month_value / max_frags_this_month)
	self.label_bottomline_barchart_frags_month:SetText(bottomline_barchart_frags_month_value)
	self.label_bottomline_barchart_frags_month:SetTop(self.bottomline_barchart_frags_month:GetTop() - 11)

	self.barchart_frags_month:SetSelectedIndex(self.barchart_frags_month:GetItemCount())

	-- Frags Year
	local height_barchart_frags_year = self.barchart_frags_year:GetHeight() - 24

	if max_frags_this_year < threshold_year then
		max_frags_this_year = threshold_year
	elseif max_frags_this_year - ThresholdRound(max_frags_this_year, threshold_year) >= (threshold_year / 5) then
		max_frags_this_year = ThresholdRound(max_frags_this_year, threshold_year) + threshold_year
	else
		max_frags_this_year = ThresholdRound(max_frags_this_year, threshold_year)
	end

	local topline_barchart_frags_year_value = max_frags_this_year

	if max_frags_this_year < ThresholdRound(max_frags_this_year, threshold_year) + max_frags_this_year * 12 / self.barchart_frags_year:GetHeight() then
		max_frags_this_year = max_frags_this_year + max_frags_this_year * 12 / self.barchart_frags_year:GetHeight()
	end

	for index, frags in pairs(frags_last_year) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_frags_year:GetWidth() / 11.5 - 2, self.barchart_frags_year:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_frags_year * (frags[3] / max_frags_this_year))
		subItem:SetTop(height_barchart_frags_year - subItem:GetHeight())
		local frags_amount = Turbine.UI.Label()
		frags_amount:SetParent(listItem)
		frags_amount:SetText(frags[3])
		frags_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_frags_month:SetPosition(
				self.barchart_frags_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_frags_month:GetWidth() / 2,
				self.barchart_frags_panel:GetTop() + self.barchart_frags_year:GetTop() + subItem:GetTop() - self.hopping_frags_month:GetHeight()
			)
			self.hopping_frags_month:SetText(FormatPoints(frags_amount:GetText()))
			self.hopping_frags_month:SetVisible(true)

			self.hopping_frags_daily_avg:SetPosition(
				self.barchart_frags_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_frags_daily_avg:GetWidth() / 2,
				self.barchart_frags_panel:GetHeight() - listItem:GetHeight() / 3.2
			)
			if frags[1] == L.Months[current_date.Month] then
				self.hopping_frags_daily_avg:SetText(Round(frags_amount:GetText() / current_date.Day))
			else
				self.hopping_frags_daily_avg:SetText(Round(frags_amount:GetText() / GetDaysPerMonth(frags[1], frags[2])))
			end
			self.hopping_frags_daily_avg:SetVisible(true)

			local frags_per_death = Round(frags[3] / deaths_last_year[index][3])
			if deaths_last_year[index][3] == 0 then
				frags_per_death = Round(frags[3] / 1)
			end

			self.statistics_frags_per_death:SetText(L.Stats_KillingBlows_Per_Death .. frags_per_death .. " (" .. frags[3] .. " : " .. deaths_last_year[index][3] .. ")")
			self.statistics_frags_per_death:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_frags_month:SetVisible(false)
			self.hopping_frags_daily_avg:SetVisible(false)

			self.statistics_frags_per_death:SetVisible(false)
		end

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(frags[1])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight() * 2)

		local dateItemYear = Turbine.UI.Label()
		dateItemYear:SetParent(listItem)
		dateItemYear:SetSize(listItem:GetWidth(), 12)
		dateItemYear:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemYear:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemYear:SetText(frags[2])
		dateItemYear:SetTop(listItem:GetHeight() - dateItemYear:GetHeight())

		self.barchart_frags_year:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_frags_year:GetHeight())
		self.barchart_frags_year:AddItem(separator)
	end
	self.barchart_frags_year:RemoveItemAt(self.barchart_frags_year:GetItemCount())

	self.topline_barchart_frags_year:SetTop(height_barchart_frags_year - height_barchart_frags_year * topline_barchart_frags_year_value / max_frags_this_year)
	self.label_topline_barchart_frags_year:SetText(FormatPoints(topline_barchart_frags_year_value))
	self.label_topline_barchart_frags_year:SetTop(self.topline_barchart_frags_year:GetTop() - 11)

	local bottomline_barchart_frags_year_value = topline_barchart_frags_year_value / 2
	self.bottomline_barchart_frags_year:SetTop(height_barchart_frags_year - height_barchart_frags_year * bottomline_barchart_frags_year_value / max_frags_this_year)
	self.label_bottomline_barchart_frags_year:SetText(FormatPoints(bottomline_barchart_frags_year_value))
	self.label_bottomline_barchart_frags_year:SetTop(self.bottomline_barchart_frags_year:GetTop() - 11)

	self.barchart_frags_year:SetSelectedIndex(self.barchart_frags_year:GetItemCount())

	-- Frags Stats
	self.statistics_frags_most_day:SetText(L.Stats_Maximum_Day .. data.numbers.most_frags_a_day[1] .. " (" ..
	data.numbers.most_frags_a_day[2] .. " " .. L.Months[data.numbers.most_frags_a_day[3]] .. " " .. data.numbers.most_frags_a_day[4] .. ")")

	self.statistics_frags_most_month:SetText(L.Stats_Maximum_Month .. FormatPoints(data.numbers.most_frags_a_month[1]) .. " (" ..
	L.Months[data.numbers.most_frags_a_month[2]] .. " " .. data.numbers.most_frags_a_month[3] .. ")")
end

function StatsWindow:UpdateBarChartDeaths()
	local current_date = Turbine.Engine.GetDate()

	local deaths_last_month = {}
	local deaths_last_year = {}

	local max_deaths_this_month = 0
	local max_deaths_this_year = 0

	local threshold_month = 10
	local threshold_year = 50

	self.barchart_deaths_month:ClearItems()
	self.barchart_deaths_year:ClearItems()

	for i = 0, Days_To_Display - 1 do
		local day_of_year = current_date.DayOfYear - i
		if day_of_year < 1 then day_of_year = day_of_year + GetDaysPerYear(current_date.Year - 1) end
		local deaths = data.numbers.history.deaths[day_of_year]
		if day_of_year == data.numbers.current_day then
			deaths = data.numbers.deaths_current_day
		end
		local day = current_date.Day - i
		local month = current_date.Month
		local year = current_date.Year
		while day < 1 do
			month = month - 1
			if month == 0 then
				month = 12
				year = year - 1
			end
			day = GetDaysPerMonth(month, year) + day
		end

		if (deaths or 0) >= max_deaths_this_month then max_deaths_this_month = (deaths or 0) end

		deaths_last_month[Days_To_Display - i] = { day, L.Months[month], deaths or 0 }
	end

	if data.numbers.current_day == current_date.DayOfYear then
		deaths_last_month[Days_To_Display] = { current_date.Day, L.Months[current_date.Month], data.numbers.deaths_current_day }
	end

	for i = 0, Months_To_Display - 1 do
		local month_of_year = (current_date.Month - i) % Months_To_Display
		if month_of_year == 0 then month_of_year = Months_To_Display end
		local deaths = data.numbers.history.deathsMonth[month_of_year]
		if month_of_year == data.numbers.current_month then
			deaths = data.numbers.deaths_current_month
		end
		local month = current_date.Month - i
		local year = current_date.Year

		if month < 1 then
			year = year - 1
			month = month + Months_To_Display
		end

		if (deaths or 0) >= max_deaths_this_year then max_deaths_this_year = (deaths or 0) end

		deaths_last_year[Months_To_Display - i] = { L.Months[month], year, deaths or 0 }
	end

	if data.numbers.current_month == current_date.Month then
		deaths_last_year[Months_To_Display] = { L.Months[current_date.Month], current_date.Year, data.numbers.deaths_current_month }
	end

	if data.numbers.deaths_current_day >= max_deaths_this_year then
		max_deaths_this_year = data.numbers.deaths_current_day
	end

	if data.numbers.deaths_current_month >= max_deaths_this_year then
		max_deaths_this_year = data.numbers.deaths_current_month
	end

	-- Deaths Month
	local height_barchart_deaths_month = self.barchart_deaths_month:GetHeight() - 24

	if max_deaths_this_month < threshold_month then
		max_deaths_this_month = threshold_month
	elseif max_deaths_this_month - ThresholdRound(max_deaths_this_month, threshold_month) >= (threshold_month / 5) then
		max_deaths_this_month = ThresholdRound(max_deaths_this_month, threshold_month) + threshold_month
	else
		max_deaths_this_month = ThresholdRound(max_deaths_this_month, threshold_month)
	end

	local topline_barchart_deaths_month_value = max_deaths_this_month

	if max_deaths_this_month < ThresholdRound(max_deaths_this_month, threshold_month) + max_deaths_this_month * 12 / self.barchart_deaths_month:GetHeight() then
		max_deaths_this_month = max_deaths_this_month + max_deaths_this_month * 12 / self.barchart_deaths_month:GetHeight()
	end

	for index, deaths in pairs(deaths_last_month) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_deaths_month:GetWidth() / 12.5 - 2, self.barchart_deaths_month:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_deaths_month * (deaths[3] / max_deaths_this_month))
		subItem:SetTop(height_barchart_deaths_month - subItem:GetHeight())
		local deaths_amount = Turbine.UI.Label()
		deaths_amount:SetParent(listItem)
		deaths_amount:SetText(deaths[3])
		deaths_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_deaths_day:SetPosition(
				self.barchart_deaths_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_deaths_day:GetWidth() / 2,
				self.barchart_deaths_panel:GetTop() + self.barchart_deaths_month:GetTop() + subItem:GetTop() - self.hopping_deaths_day:GetHeight()
			)
			self.hopping_deaths_day:SetText(deaths_amount:GetText())
			self.hopping_deaths_day:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_deaths_day:SetVisible(false)
		end
		local dateItemDay = Turbine.UI.Label()
		dateItemDay:SetParent(listItem)
		dateItemDay:SetSize(listItem:GetWidth(), 12)
		dateItemDay:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemDay:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemDay:SetText(deaths[1])
		dateItemDay:SetTop(listItem:GetHeight() - dateItemDay:GetHeight() * 2)

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(deaths[2])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight())

		self.barchart_deaths_month:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_deaths_month:GetHeight())
		self.barchart_deaths_month:AddItem(separator)
	end
	self.barchart_deaths_month:RemoveItemAt(self.barchart_deaths_month:GetItemCount())

	self.topline_barchart_deaths_month:SetTop(height_barchart_deaths_month - height_barchart_deaths_month * topline_barchart_deaths_month_value / max_deaths_this_month)
	self.label_topline_barchart_deaths_month:SetText(topline_barchart_deaths_month_value)
	self.label_topline_barchart_deaths_month:SetTop(self.topline_barchart_deaths_month:GetTop() - 11)

	local bottomline_barchart_deaths_month_value = topline_barchart_deaths_month_value / 2
	self.bottomline_barchart_deaths_month:SetTop(height_barchart_deaths_month - height_barchart_deaths_month * bottomline_barchart_deaths_month_value / max_deaths_this_month)
	self.label_bottomline_barchart_deaths_month:SetText(bottomline_barchart_deaths_month_value)
	self.label_bottomline_barchart_deaths_month:SetTop(self.bottomline_barchart_deaths_month:GetTop() - 11)

	self.barchart_deaths_month:SetSelectedIndex(self.barchart_deaths_month:GetItemCount())

	-- Deaths Year
	local height_barchart_deaths_year = self.barchart_deaths_year:GetHeight() - 24

	if max_deaths_this_year < threshold_year then
		max_deaths_this_year = threshold_year
	elseif max_deaths_this_year - ThresholdRound(max_deaths_this_year, threshold_year) >= (threshold_year / 5) then
		max_deaths_this_year = ThresholdRound(max_deaths_this_year, threshold_year) + threshold_year
	else
		max_deaths_this_year = ThresholdRound(max_deaths_this_year, threshold_year)
	end

	local topline_barchart_deaths_year_value = max_deaths_this_year

	if max_deaths_this_year < ThresholdRound(max_deaths_this_year, threshold_year) + max_deaths_this_year * 12 / self.barchart_deaths_year:GetHeight() then
		max_deaths_this_year = max_deaths_this_year + max_deaths_this_year * 12 / self.barchart_deaths_year:GetHeight()
	end

	for index, deaths in pairs(deaths_last_year) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_deaths_year:GetWidth() / 11.5 - 2, self.barchart_deaths_year:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_deaths_year * (deaths[3] / max_deaths_this_year))
		subItem:SetTop(height_barchart_deaths_year - subItem:GetHeight())
		local deaths_amount = Turbine.UI.Label()
		deaths_amount:SetParent(listItem)
		deaths_amount:SetText(deaths[3])
		deaths_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_deaths_month:SetPosition(
				self.barchart_deaths_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_deaths_month:GetWidth() / 2,
				self.barchart_deaths_panel:GetTop() + self.barchart_deaths_year:GetTop() + subItem:GetTop() - self.hopping_deaths_month:GetHeight()
			)
			self.hopping_deaths_month:SetText(FormatPoints(deaths_amount:GetText()))
			self.hopping_deaths_month:SetVisible(true)

			self.hopping_deaths_daily_avg:SetPosition(
				self.barchart_deaths_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_deaths_daily_avg:GetWidth() / 2,
				self.barchart_deaths_panel:GetHeight() - listItem:GetHeight() / 3.2
			)
			if deaths[1] == L.Months[current_date.Month] then
				self.hopping_deaths_daily_avg:SetText(Round(deaths_amount:GetText() / current_date.Day))
			else
				self.hopping_deaths_daily_avg:SetText(Round(deaths_amount:GetText() / GetDaysPerMonth(deaths[1], deaths[2])))
			end
			self.hopping_deaths_daily_avg:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_deaths_month:SetVisible(false)
			self.hopping_deaths_daily_avg:SetVisible(false)
		end

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(deaths[1])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight() * 2)

		local dateItemYear = Turbine.UI.Label()
		dateItemYear:SetParent(listItem)
		dateItemYear:SetSize(listItem:GetWidth(), 12)
		dateItemYear:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemYear:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemYear:SetText(deaths[2])
		dateItemYear:SetTop(listItem:GetHeight() - dateItemYear:GetHeight())

		self.barchart_deaths_year:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_deaths_year:GetHeight())
		self.barchart_deaths_year:AddItem(separator)
	end
	self.barchart_deaths_year:RemoveItemAt(self.barchart_deaths_year:GetItemCount())

	self.topline_barchart_deaths_year:SetTop(height_barchart_deaths_year - height_barchart_deaths_year * topline_barchart_deaths_year_value / max_deaths_this_year)
	self.label_topline_barchart_deaths_year:SetText(FormatPoints(topline_barchart_deaths_year_value))
	self.label_topline_barchart_deaths_year:SetTop(self.topline_barchart_deaths_year:GetTop() - 11)

	local bottomline_barchart_deaths_year_value = topline_barchart_deaths_year_value / 2
	self.bottomline_barchart_deaths_year:SetTop(height_barchart_deaths_year - height_barchart_deaths_year * bottomline_barchart_deaths_year_value / max_deaths_this_year)
	self.label_bottomline_barchart_deaths_year:SetText(FormatPoints(bottomline_barchart_deaths_year_value))
	self.label_bottomline_barchart_deaths_year:SetTop(self.bottomline_barchart_deaths_year:GetTop() - 11)

	self.barchart_deaths_year:SetSelectedIndex(self.barchart_deaths_year:GetItemCount())

	-- Deaths Stats
	self.statistics_deaths_most_day:SetText(L.Stats_Maximum_Day .. data.numbers.most_deaths_a_day[1] .. " (" ..
	data.numbers.most_deaths_a_day[2] .. " " .. L.Months[data.numbers.most_deaths_a_day[3]] .. " " .. data.numbers.most_deaths_a_day[4] .. ")")

	self.statistics_deaths_most_month:SetText(L.Stats_Maximum_Month .. FormatPoints(data.numbers.most_deaths_a_month[1]) .. " (" ..
	L.Months[data.numbers.most_deaths_a_month[2]] .. " " .. data.numbers.most_deaths_a_month[3] .. ")")
end

function StatsWindow:UpdateBarChartTracks()
	local current_date = Turbine.Engine.GetDate()

	local tracks_last_month = {}
	local tracks_last_year = {}

	local max_tracks_this_month = 0
	local max_tracks_this_year = 0

	local threshold_month = 10
	local threshold_year = 50

	self.barchart_tracks_month:ClearItems()
	self.barchart_tracks_year:ClearItems()

	for i = 0, Days_To_Display - 1 do
		local day_of_year = current_date.DayOfYear - i
		if day_of_year < 1 then day_of_year = day_of_year + GetDaysPerYear(current_date.Year - 1) end
		local tracks = data.numbers.history.tracks[day_of_year]
		if day_of_year == data.numbers.current_day then
			tracks = data.numbers.tracks_current_day
		end
		local day = current_date.Day - i
		local month = current_date.Month
		local year = current_date.Year
		while day < 1 do
			month = month - 1
			if month == 0 then
				month = 12
				year = year - 1
			end
			day = GetDaysPerMonth(month, year) + day
		end

		if (tracks or 0) >= max_tracks_this_month then max_tracks_this_month = (tracks or 0) end

		tracks_last_month[Days_To_Display - i] = { day, L.Months[month], tracks or 0 }
	end

	if data.numbers.current_day == current_date.DayOfYear then
		tracks_last_month[Days_To_Display] = { current_date.Day, L.Months[current_date.Month], data.numbers.tracks_current_day }
	end

	for i = 0, Months_To_Display - 1 do
		local month_of_year = (current_date.Month - i) % Months_To_Display
		if month_of_year == 0 then month_of_year = Months_To_Display end
		local tracks = data.numbers.history.tracksMonth[month_of_year]
		if month_of_year == data.numbers.current_month then
			tracks = data.numbers.tracks_current_month
		end
		local month = current_date.Month - i
		local year = current_date.Year

		if month < 1 then
			year = year - 1
			month = month + Months_To_Display
		end

		if (tracks or 0) >= max_tracks_this_year then max_tracks_this_year = (tracks or 0) end

		tracks_last_year[Months_To_Display - i] = { L.Months[month], year, tracks or 0 }
	end

	if data.numbers.current_month == current_date.Month then
		tracks_last_year[Months_To_Display] = { L.Months[current_date.Month], current_date.Year, data.numbers.tracks_current_month }
	end

	if data.numbers.tracks_current_day >= max_tracks_this_year then
		max_tracks_this_year = data.numbers.tracks_current_day
	end

	if data.numbers.tracks_current_month >= max_tracks_this_year then
		max_tracks_this_year = data.numbers.tracks_current_month
	end

	-- Tracks Month
	local height_barchart_tracks_month = self.barchart_tracks_month:GetHeight() - 24

	if max_tracks_this_month < threshold_month then
		max_tracks_this_month = threshold_month
	elseif max_tracks_this_month - ThresholdRound(max_tracks_this_month, threshold_month) >= (threshold_month / 5) then
		max_tracks_this_month = ThresholdRound(max_tracks_this_month, threshold_month) + threshold_month
	else
		max_tracks_this_month = ThresholdRound(max_tracks_this_month, threshold_month)
	end

	local topline_barchart_tracks_month_value = max_tracks_this_month

	if max_tracks_this_month < ThresholdRound(max_tracks_this_month, threshold_month) + max_tracks_this_month * 12 / self.barchart_tracks_month:GetHeight() then
		max_tracks_this_month = max_tracks_this_month + max_tracks_this_month * 12 / self.barchart_tracks_month:GetHeight()
	end

	for index, tracks in pairs(tracks_last_month) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_tracks_month:GetWidth() / 12.5 - 2, self.barchart_tracks_month:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_tracks_month * (tracks[3] / max_tracks_this_month))
		subItem:SetTop(height_barchart_tracks_month - subItem:GetHeight())
		local tracks_amount = Turbine.UI.Label()
		tracks_amount:SetParent(listItem)
		tracks_amount:SetText(tracks[3])
		tracks_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_tracks_day:SetPosition(
				self.barchart_tracks_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_tracks_day:GetWidth() / 2,
				self.barchart_tracks_panel:GetTop() + self.barchart_tracks_month:GetTop() + subItem:GetTop() - self.hopping_tracks_day:GetHeight()
			)
			self.hopping_tracks_day:SetText(tracks_amount:GetText())
			self.hopping_tracks_day:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_tracks_day:SetVisible(false)
		end
		local dateItemDay = Turbine.UI.Label()
		dateItemDay:SetParent(listItem)
		dateItemDay:SetSize(listItem:GetWidth(), 12)
		dateItemDay:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemDay:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemDay:SetText(tracks[1])
		dateItemDay:SetTop(listItem:GetHeight() - dateItemDay:GetHeight() * 2)

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(tracks[2])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight())

		self.barchart_tracks_month:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_tracks_month:GetHeight())
		self.barchart_tracks_month:AddItem(separator)
	end
	self.barchart_tracks_month:RemoveItemAt(self.barchart_tracks_month:GetItemCount())

	self.topline_barchart_tracks_month:SetTop(height_barchart_tracks_month - height_barchart_tracks_month * topline_barchart_tracks_month_value / max_tracks_this_month)
	self.label_topline_barchart_tracks_month:SetText(topline_barchart_tracks_month_value)
	self.label_topline_barchart_tracks_month:SetTop(self.topline_barchart_tracks_month:GetTop() - 11)

	local bottomline_barchart_tracks_month_value = topline_barchart_tracks_month_value / 2
	self.bottomline_barchart_tracks_month:SetTop(height_barchart_tracks_month - height_barchart_tracks_month * bottomline_barchart_tracks_month_value / max_tracks_this_month)
	self.label_bottomline_barchart_tracks_month:SetText(bottomline_barchart_tracks_month_value)
	self.label_bottomline_barchart_tracks_month:SetTop(self.bottomline_barchart_tracks_month:GetTop() - 11)

	self.barchart_tracks_month:SetSelectedIndex(self.barchart_tracks_month:GetItemCount())

	-- Tracks Year
	local height_barchart_tracks_year = self.barchart_tracks_year:GetHeight() - 24

	if max_tracks_this_year < threshold_year then
		max_tracks_this_year = threshold_year
	elseif max_tracks_this_year - ThresholdRound(max_tracks_this_year, threshold_year) >= (threshold_year / 5) then
		max_tracks_this_year = ThresholdRound(max_tracks_this_year, threshold_year) + threshold_year
	else
		max_tracks_this_year = ThresholdRound(max_tracks_this_year, threshold_year)
	end

	local topline_barchart_tracks_year_value = max_tracks_this_year

	if max_tracks_this_year < ThresholdRound(max_tracks_this_year, threshold_year) + max_tracks_this_year * 12 / self.barchart_tracks_year:GetHeight() then
		max_tracks_this_year = max_tracks_this_year + max_tracks_this_year * 12 / self.barchart_tracks_year:GetHeight()
	end

	for index, tracks in pairs(tracks_last_year) do
		local listItem = Turbine.UI.Control()
		listItem:SetSize(self.barchart_tracks_year:GetWidth() / 11.5 - 2, self.barchart_tracks_year:GetHeight())
		local subItem = Turbine.UI.Label()
		subItem:SetParent(listItem)
		subItem:SetBackColor(Bar_Chart_Color)
		subItem:SetSize(listItem:GetWidth(), height_barchart_tracks_year * (tracks[3] / max_tracks_this_year))
		subItem:SetTop(height_barchart_tracks_year - subItem:GetHeight())
		local tracks_amount = Turbine.UI.Label()
		tracks_amount:SetParent(listItem)
		tracks_amount:SetText(tracks[3])
		tracks_amount:SetVisible(false)
		subItem.MouseEnter = function()
			subItem:SetBackColor(Aligned_Color)
			self.hopping_tracks_month:SetPosition(
				self.barchart_tracks_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_tracks_month:GetWidth() / 2,
				self.barchart_tracks_panel:GetTop() + self.barchart_tracks_year:GetTop() + subItem:GetTop() - self.hopping_tracks_month:GetHeight()
			)
			self.hopping_tracks_month:SetText(FormatPoints(tracks_amount:GetText()))
			self.hopping_tracks_month:SetVisible(true)

			self.hopping_tracks_daily_avg:SetPosition(
				self.barchart_tracks_panel:GetLeft() + listItem:GetLeft() + listItem:GetWidth() / 2 - self.hopping_tracks_daily_avg:GetWidth() / 2,
				self.barchart_tracks_panel:GetHeight() - listItem:GetHeight() / 3.2
			)
			if tracks[1] == L.Months[current_date.Month] then
				self.hopping_tracks_daily_avg:SetText(Round(tracks_amount:GetText() / current_date.Day))
			else
				self.hopping_tracks_daily_avg:SetText(Round(tracks_amount:GetText() / GetDaysPerMonth(tracks[1], tracks[2])))
			end
			self.hopping_tracks_daily_avg:SetVisible(true)
		end
		subItem.MouseLeave = function()
			subItem:SetBackColor(Bar_Chart_Color)
			self.hopping_tracks_month:SetVisible(false)
			self.hopping_tracks_daily_avg:SetVisible(false)
		end

		local dateItemMonth = Turbine.UI.Label()
		dateItemMonth:SetParent(listItem)
		dateItemMonth:SetSize(listItem:GetWidth(), 12)
		dateItemMonth:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemMonth:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemMonth:SetText(tracks[1])
		dateItemMonth:SetTop(listItem:GetHeight() - dateItemMonth:GetHeight() * 2)

		local dateItemYear = Turbine.UI.Label()
		dateItemYear:SetParent(listItem)
		dateItemYear:SetSize(listItem:GetWidth(), 12)
		dateItemYear:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
		dateItemYear:SetFont(Turbine.UI.Lotro.Font.Arial12)
		dateItemYear:SetText(tracks[2])
		dateItemYear:SetTop(listItem:GetHeight() - dateItemYear:GetHeight())

		self.barchart_tracks_year:AddItem(listItem)

		local separator = Turbine.UI.Control()
		separator:SetSize(2, self.barchart_tracks_year:GetHeight())
		self.barchart_tracks_year:AddItem(separator)
	end
	self.barchart_tracks_year:RemoveItemAt(self.barchart_tracks_year:GetItemCount())

	self.topline_barchart_tracks_year:SetTop(height_barchart_tracks_year - height_barchart_tracks_year * topline_barchart_tracks_year_value / max_tracks_this_year)
	self.label_topline_barchart_tracks_year:SetText(FormatPoints(topline_barchart_tracks_year_value))
	self.label_topline_barchart_tracks_year:SetTop(self.topline_barchart_tracks_year:GetTop() - 11)

	local bottomline_barchart_tracks_year_value = topline_barchart_tracks_year_value / 2
	self.bottomline_barchart_tracks_year:SetTop(height_barchart_tracks_year - height_barchart_tracks_year * bottomline_barchart_tracks_year_value / max_tracks_this_year)
	self.label_bottomline_barchart_tracks_year:SetText(FormatPoints(bottomline_barchart_tracks_year_value))
	self.label_bottomline_barchart_tracks_year:SetTop(self.bottomline_barchart_tracks_year:GetTop() - 11)

	self.barchart_tracks_year:SetSelectedIndex(self.barchart_tracks_year:GetItemCount())

	-- Tracks Stats
	self.statistics_tracks_most_day:SetText(L.Stats_Maximum_Day .. data.numbers.most_tracks_a_day[1] .. " (" ..
	data.numbers.most_tracks_a_day[2] .. " " .. L.Months[data.numbers.most_tracks_a_day[3]] .. " " .. data.numbers.most_tracks_a_day[4] .. ")")

	self.statistics_tracks_most_month:SetText(L.Stats_Maximum_Month .. FormatPoints(data.numbers.most_tracks_a_month[1]) .. " (" ..
	L.Months[data.numbers.most_tracks_a_month[2]] .. " " .. data.numbers.most_tracks_a_month[3] .. ")")
end

function StatsWindow:ShowTab(tab)
	self.stats_panel:SetVisible(false)
	self.frag_panel:SetVisible(false)
	self.barchart_points_panel:SetVisible(false)
	self.barchart_comms_panel:SetVisible(false)
	self.barchart_frags_panel:SetVisible(false)
	self.barchart_deaths_panel:SetVisible(false)
	self.barchart_tracks_panel:SetVisible(false)

	if tab == self.tab_stats.index then
		self:UpdateStatsPanel()
		self.stats_panel:SetVisible(true)
	elseif tab == self.tab_killList.index then
		self.search_box:SetText("")
		self.button_search_box_clear:SetEnabled(false)
		self:UpdateFragList(frags_desc)
		self.frag_panel:SetVisible(true)
	elseif tab == self.tab_barChartPoints.index then
		self:UpdateBarChartPoints()
		self.barchart_points_panel:SetVisible(true)
	elseif tab == self.tab_barChartComms.index then
		self:UpdateBarChartComms()
		self.barchart_comms_panel:SetVisible(true)
	elseif tab == self.tab_barChartFrags.index then
		self:UpdateBarChartFrags()
		self.barchart_frags_panel:SetVisible(true)
	elseif tab == self.tab_barChartDeaths.index then
		self:UpdateBarChartDeaths()
		self.barchart_deaths_panel:SetVisible(true)
	elseif tab == self.tab_barChartTracks.index then
		self:UpdateBarChartTracks()
		self.barchart_tracks_panel:SetVisible(true)
	end
end