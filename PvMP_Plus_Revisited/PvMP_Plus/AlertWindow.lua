AlertWindow = class(Turbine.UI.Window)

function AlertWindow:Constructor()
	Turbine.UI.Window.Constructor(self)
	local width = 550
	local height = 125

	self:SetSize(width, height)
	self:SetPosition(data.numbers.alert_x, data.numbers.alert_y)

	self:SetMouseVisible(false)
	self:SetVisible(true)

	self.DragBar = DragBar(self, L.DragBar_Alert)

	self.label_alert = Turbine.UI.Label()
	self.label_alert:SetParent(self)
	self.label_alert:SetSize(width, height - 20)
	self.label_alert:SetPosition(0, 20)
	self.label_alert:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_alert:SetFont(Turbine.UI.Lotro.Font.TrajanProBold30)
	self.label_alert:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_alert:SetMouseVisible(false)
	self.label_alert:SetVisible(false)

	self.PositionChanged = function(sender, args)
		data.numbers.alert_x = self:GetLeft()
		data.numbers.alert_y = self:GetTop()
	end
end

function AlertWindow:NewAlert(message, color, duration)
	self.label_alert:SetForeColor(color)
	self.label_alert:SetText(message)
	Alert_Counter = duration
end