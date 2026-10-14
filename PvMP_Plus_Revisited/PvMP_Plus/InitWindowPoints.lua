InitWindowPoints = class(Turbine.UI.Lotro.Window)

function InitWindowPoints:Constructor()
	local width = 260
	local height = 140
	local x = Turbine.UI.Display:GetWidth() / 2 - width / 2
	local y = Turbine.UI.Display:GetHeight() / 2 - height / 2

	Turbine.UI.Lotro.Window.Constructor(self)

	self:SetSize(width, height)
	self:SetPosition(x, y)
	self:SetZOrder(2)
	self:SetText(L.InfamyRenown)
	self:SetWantsKeyEvents(true)

	self.label_points = Turbine.UI.Label()
	self.label_points:SetParent(self)
	self.label_points:SetSize(width - 60, 30)
	self.label_points:SetForeColor(Default_Font_Color)
	self.label_points:SetPosition(width / 2 - self.label_points:GetWidth() / 2, 35)
	self.label_points:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_points:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_points:SetText(L.Init_Points)

	self.textbox_points = LotroTextBox(self, width - 70, data.numbers.points_total)
	self.textbox_points:SetPosition(width / 2 - self.textbox_points:GetWidth() / 2, self.label_points:GetTop() + 35)
	self.textbox_points.TextChanged = function()
		local parsed_text = string.gsub(self.textbox_points:GetText(), "%D*", "")
		self.textbox_points:SetText(string.sub(parsed_text, 1, 10))
	end

	self.label_error_message = Turbine.UI.Label()
	self.label_error_message:SetParent(self)
	self.label_error_message:SetSize(width - 60, 50)
	self.label_error_message:SetForeColor(Turbine.UI.Color.Red)
	self.label_error_message:SetPosition(width / 2 - self.label_error_message:GetWidth() / 2, self.textbox_points:GetTop() + 25)
	self.label_error_message:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.label_error_message:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_error_message:SetVisible(false)

	self.button_confirm = LotroButton(self, 80, L.Window_Save)
	self.button_confirm:SetPosition(width / 2 - self.button_confirm:GetWidth() - 5, height - 40)
	self.button_confirm.Click = function()
		self:Set()
	end

	self.button_cancel = LotroButton(self, 80, L.Window_Cancel)
	self.button_cancel:SetPosition(width / 2 + 5, height - 40)
	self.button_cancel.Click = function()
		self:Close()
	end

	self.KeyDown = function(sender, args)
		if args.Action == Turbine.UI.Lotro.Action.Escape then
			self:SetVisible(false)
		end
	end
end

function InitWindowPoints:Open()
	self.label_error_message:SetVisible(false)
	self:SetHeight(140)
	self.button_confirm:SetPosition(self:GetWidth() / 2 - self.button_confirm:GetWidth() - 5, self:GetHeight() - 40)
	self.button_cancel:SetPosition(self:GetWidth() / 2 + 5, self:GetHeight() - 40)
	self.textbox_points:SetText(data.numbers.points_total)
	self:SetVisible(true)
end

function InitWindowPoints:Set()
	local parsed_text = self.textbox_points:GetText()
	if tonumber(parsed_text) == nil then
		self:SetHeight(155)
		self.button_confirm:SetPosition(self:GetWidth() / 2 - self.button_confirm:GetWidth() - 5, self:GetHeight() - 40)
		self.button_cancel:SetPosition(self:GetWidth() / 2 + 5, self:GetHeight() - 40)
		self.label_error_message:SetText(L.Init_Invalid_Input)
		self.label_error_message:SetVisible(true)
		self.textbox_points:SetText(parsed_text)
		return
	end

	if (tonumber(parsed_text) > Ranks[#Ranks]) then
		parsed_text = Ranks[#Ranks]
	end

	data.numbers.points_total = tonumber(parsed_text)

	self:SetVisible(false)
	OverviewSettingsPanel:SetVisible(true)
	OverviewWindow.panel:SetVisible(not storage.minimized)
	SecondaryWindow:SetVisible((not storage.minimized) and (not storage.secondaryMinimized))
	RecentHitsWindow:SetVisible((not storage.minimized) and (not storage.hitWindowMinimized))
	OverviewWindow:SetVisible(true)
	OverviewWindow:Update()
	StatsWindow:UpdateStatsPanel()
end

function InitWindowPoints:DataOutOfSync()
	self.label_error_message:SetText(L.Strings_Points_Out_Of_Sync)
	self.label_error_message:SetVisible(true)
	self:SetHeight(185)
	self.button_confirm:SetPosition(self:GetWidth() / 2 - self.button_confirm:GetWidth() - 5, self:GetHeight() - 40)
	self.button_cancel:SetPosition(self:GetWidth() / 2 + 5, self:GetHeight() - 40)
	self:SetVisible(true)
end

function InitWindowPoints:Close()
	self:SetVisible(false)
end