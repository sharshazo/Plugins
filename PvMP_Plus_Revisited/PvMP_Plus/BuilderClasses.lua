Tab = class(Turbine.UI.Button)
function Tab:Constructor(parent, header, tabIndex, pos, background, mouseover, selected, selected_mouseover)
	Turbine.UI.Button.Constructor(self)

	self.isSelected = false
	self.index = tabIndex
	self.normal = background
	self.mouseover = mouseover
	self.selected = selected
	self.mouseover_selected = selected_mouseover

	self:SetParent(parent)
	self:SetSize((parent:GetWidth() + 35) / 7, 50)
	self:SetPosition(10 + pos * ((parent:GetWidth() - 35) / 7), 25)
	self:SetBackground(self.normal)
	self:SetWantsKeyEvents(true)
	self:SetBlendMode(Turbine.UI.BlendMode.Overlay)

	self.Click = function()
		parent.tab_stats:SetBackground(parent.tab_stats.normal)
		parent.tab_stats.isSelected = false

		parent.tab_killList:SetBackground(parent.tab_killList.normal)
		parent.tab_killList.isSelected = false

		parent.tab_barChartPoints:SetBackground(parent.tab_barChartPoints.normal)
		parent.tab_barChartPoints.isSelected = false

		parent.tab_barChartComms:SetBackground(parent.tab_barChartComms.normal)
		parent.tab_barChartComms.isSelected = false

		parent.tab_barChartFrags:SetBackground(parent.tab_barChartFrags.normal)
		parent.tab_barChartFrags.isSelected = false

		parent.tab_barChartDeaths:SetBackground(parent.tab_barChartDeaths.normal)
		parent.tab_barChartDeaths.isSelected = false

		parent.tab_barChartTracks:SetBackground(parent.tab_barChartTracks.normal)
		parent.tab_barChartTracks.isSelected = false

		self:SetBackground(self.mouseover_selected)
		self.isSelected = true
		parent:ShowTab(self.index)
		parent.label_active_tab:SetText(header)
		parent.label_active_tab:SetForeColor(Turbine.UI.Color.White)
		parent.label_active_tab:SetVisible(true)
		parent.label_tabs:SetVisible(false)
	end

	self.MouseEnter = function()
		if self.isSelected then
			self:SetBackground(self.mouseover_selected)
		else
			self:SetBackground(self.mouseover)
			parent.label_tabs:SetText(header)
			parent.label_tabs:SetForeColor(Bar_Chart_Color)
			parent.label_tabs:SetVisible(true)
			parent.label_active_tab:SetVisible(false)
		end
	end

	self.MouseLeave = function()
		if self.isSelected then
			self:SetBackground(self.selected)
		else
			self:SetBackground(self.normal)
			parent.label_tabs:SetVisible(false)
			parent.label_active_tab:SetVisible(true)
		end
	end
end

OverviewLabel = class(Turbine.UI.Label)
function OverviewLabel:Constructor(parent, width, pos, color)
	Turbine.UI.Label.Constructor(self)

	self:SetParent(parent)
	self:SetSize(width / 5, 35)
	self:SetForeColor(color)
	self:SetPosition(pos * (width / 5), 3)
	self:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self:SetMouseVisible(false)
end

StatsLabelCenter = class(Turbine.UI.Label)
function StatsLabelCenter:Constructor(parent, pos)
	Turbine.UI.Label.Constructor(self)

	self:SetParent(parent)
	self:SetSize(parent:GetWidth(), 15)
	self:SetPosition(0, pos)
	self:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
end

StatsLabelLeft = class(Turbine.UI.Label)
function StatsLabelLeft:Constructor(parent, text, pos)
	Turbine.UI.Label.Constructor(self)

	self:SetParent(parent)
	self:SetSize(parent:GetWidth() / 2, 15)
	self:SetPosition(0, pos)
	self:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
	self:SetText(text)
end

StatsLabelRight = class(Turbine.UI.Label)
function StatsLabelRight:Constructor(parent, pos)
	Turbine.UI.Label.Constructor(self)

	self:SetParent(parent)
	self:SetSize(parent:GetWidth() / 2, 15)
	self:SetPosition(parent:GetWidth() / 2, pos)
	self:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
end

OptionsPanelDivider = class(Turbine.UI.Label)
function OptionsPanelDivider:Constructor(parent, text, pos)
	Turbine.UI.Label.Constructor(self)

	self:SetParent(parent)
	self:SetSize(400, 30)
	self:SetPosition(parent:GetWidth() / 2 - self:GetWidth() / 2, pos)
	self:SetForeColor(Yellow_Font_Color)
	self:SetFont(Turbine.UI.Lotro.Font.TrajanPro18)
	self:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self:SetText(text)
	self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self:SetBackground(0x41005F8A)
end

OptionsCheckBox = class(Turbine.UI.Lotro.CheckBox)
function OptionsCheckBox:Constructor(parent, text, bool)
	Turbine.UI.Lotro.CheckBox.Constructor(self)

	self:SetParent(parent)
	self:SetSize(parent:GetWidth() / 2 - 30, 16)
	self:SetForeColor(Default_Font_Color)
	self:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self:SetText(" " .. text)
	self:SetChecked(not bool)
end

LotroButton = class(Turbine.UI.Lotro.Button)
function LotroButton:Constructor(parent, width, text)
	Turbine.UI.Lotro.Button.Constructor(self)

	self:SetParent(parent)
	self:SetWidth(width)
	self:SetText(text)
end

LotroTextBox = class(Turbine.UI.Lotro.TextBox)
function LotroTextBox:Constructor(parent, width, text)
	Turbine.UI.Lotro.TextBox.Constructor(self)

	self:SetParent(parent)
	self:SetSize(width, 20)
	self:SetForeColor(Default_Font_Color)
	self:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
	self:SetText(text)
	self:SetMultiline(false)
end