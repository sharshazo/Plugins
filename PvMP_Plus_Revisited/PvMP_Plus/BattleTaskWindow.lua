BattleTaskWindow = class(Turbine.UI.Window)

function BattleTaskWindow:Constructor()
	Turbine.UI.Window.Constructor(self)
	local width = 550
	local height = 125

	self:SetSize(width, height)
	self:SetPosition(data.numbers.battle_task_x, data.numbers.battle_task_y)

	self:SetMouseVisible(false)
	self:SetVisible(true)

	self.DragBar = DragBar(self, L.DragBar_Battle_Task)

	self.label_battle_task = Turbine.UI.Label()
	self.label_battle_task:SetParent(self)
	self.label_battle_task:SetSize(width, height - 20)
	self.label_battle_task:SetPosition(0, 20)
	self.label_battle_task:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_battle_task:SetFont(Turbine.UI.Lotro.Font.TrajanProBold30)
	self.label_battle_task:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_battle_task:SetMouseVisible(false)
	self.label_battle_task:SetVisible(false)

	self.PositionChanged = function(sender, args)
		data.numbers.battle_task_x = self:GetLeft()
		data.numbers.battle_task_y = self:GetTop()
	end
end

function BattleTaskWindow:NewAlert(message, color)
	self.label_battle_task:SetForeColor(color)
	self.label_battle_task:SetText(message)
end