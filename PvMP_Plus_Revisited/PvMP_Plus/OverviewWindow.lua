OverviewWindow = class(Turbine.UI.Window)

local own_tree_buff				= false
local own_drake_buff			= false
local own_gary_buff				= false
local own_crown_buff			= false
local own_carrock_buff			= false
local own_outnumbered_buff		= false

local tree_buff_timer			= 0
local drake_buff_timer			= 0
local gary_buff_timer			= 0
local crown_buff_timer			= 0
local carrock_buff_timer		= 0
local outnumbered_buff_timer	= 0

function OverviewWindow:Constructor()
	Turbine.UI.Window.Constructor(self)
	local width = math.ceil(Minimal_Width + (Turbine.UI.Display.GetWidth() - Minimal_Width) * data.numbers.overview_width_ratio)
	local height = 105
	self:SetSize(width, height)

	self:SetPosition(data.numbers.overview_x, data.numbers.overview_y)
	self:SetWantsKeyEvents(true)
	self:SetMouseVisible(false)

	self.DragBar = DragBar(self, L.DragBar_Overview)

	self.panel = Turbine.UI.Label()
	self.panel:SetParent(self)
	self.panel:SetSize(width, height)
	self.panel:SetMouseVisible(false)

	self.bar_start	= 50
	self.bar_end	= self:GetWidth() - self.bar_start
	self.bar_length	= self.bar_end - self.bar_start


	-- Percentage Bar Builder for Rank
	self.empty_bar = Turbine.UI.Label()
	self.empty_bar:SetParent(self.panel)
	self.empty_bar:SetSize(self.bar_length, 14)
	self.empty_bar:SetPosition(self.bar_start, 27)
	self.empty_bar:SetBackground(Bar_Builder[0])
	self.empty_bar:SetMouseVisible(false)

	self.filled_bar = Turbine.UI.Label()
	self.filled_bar:SetParent(self.panel)
	self.filled_bar:SetSize(0, 14)
	self.filled_bar:SetPosition(self.bar_start, 27)
	self.filled_bar:SetBackground(Bar_Builder[1])
	self.filled_bar:SetMouseVisible(false)

	self.bar_left_end = Turbine.UI.Label()
	self.bar_left_end:SetParent(self.panel)
	self.bar_left_end:SetSize(6, 18)
	self.bar_left_end:SetPosition(self.bar_start - 3, 25)
	self.bar_left_end:SetBackground(Bar_Builder[2])
	self.bar_left_end:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.bar_left_end:SetMouseVisible(false)

	self.bar_right_end = Turbine.UI.Label()
	self.bar_right_end:SetParent(self.panel)
	self.bar_right_end:SetSize(6, 18)
	self.bar_right_end:SetPosition(self.bar_end - 3, 25)
	self.bar_right_end:SetBackground(Bar_Builder[3])
	self.bar_right_end:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.bar_right_end:SetMouseVisible(false)

	self.bar_middle = Turbine.UI.Label()
	self.bar_middle:SetParent(self.panel)
	self.bar_middle:SetSize(self.bar_length - 6, 18)
	self.bar_middle:SetPosition(self.bar_start + 3, 25)
	self.bar_middle:SetBackground(Bar_Builder[4])
	self.bar_middle:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.bar_middle:SetMouseVisible(false)

	self.bar_percentage = Turbine.UI.Label()
	self.bar_percentage:SetParent(self.panel)
	self.bar_percentage:SetSize(width, 18)
	self.bar_percentage:SetPosition(0, 25)
	self.bar_percentage:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.bar_percentage:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.bar_percentage:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.bar_percentage:SetMouseVisible(false)


	-- Multiplier and Outpost Container
	self.bonus_panel = Turbine.UI.Label()
	self.bonus_panel:SetParent(self.panel)
	self.bonus_panel:SetSize(95, 30)
	self.bonus_panel:SetPosition(width / 2 - self.bonus_panel:GetSize() / 2, 0)
	self.bonus_panel:SetMouseVisible(false)


	-- Multiplier Label
	self.label_bonus = Turbine.UI.Label()
	self.label_bonus:SetParent(self.bonus_panel)
	self.label_bonus:SetSize(self.bonus_panel:GetSize())
	self.label_bonus:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.label_bonus:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.label_bonus:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_bonus:SetMouseVisible(false)
	self.label_bonus:SetVisible(not storage.show_bonus_disabled)


	-- Outpost Labels
	self.outpost_1 = Turbine.UI.Label()
	self.outpost_1:SetParent(self.bonus_panel)
	self.outpost_1:SetSize(20, 3)
	self.outpost_1:SetPosition(0, 18)
	self.outpost_1:SetMouseVisible(false)
	self.outpost_1:SetVisible(not storage.show_outpost_disabled)

	self.outpost_1_text = Turbine.UI.Label()
	self.outpost_1_text:SetParent(self.bonus_panel)
	self.outpost_1_text:SetSize(20, 16)
	self.outpost_1_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.outpost_1_text:SetPosition(0, 11)
	self.outpost_1_text:SetMouseVisible(false)
	self.outpost_1_text:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.outpost_1_text:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.outpost_1_text:SetVisible(not storage.show_outpost_disabled)

	self.outpost_2 = Turbine.UI.Label()
	self.outpost_2:SetParent(self.bonus_panel)
	self.outpost_2:SetSize(20, 3)
	self.outpost_2:SetPosition(25, 18)
	self.outpost_2:SetMouseVisible(false)
	self.outpost_2:SetVisible(not storage.show_outpost_disabled)

	self.outpost_2_text = Turbine.UI.Label()
	self.outpost_2_text:SetParent(self.bonus_panel)
	self.outpost_2_text:SetSize(20, 16)
	self.outpost_2_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.outpost_2_text:SetPosition(25, 11)
	self.outpost_2_text:SetMouseVisible(false)
	self.outpost_2_text:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.outpost_2_text:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.outpost_2_text:SetVisible(not storage.show_outpost_disabled)

	self.outpost_3 = Turbine.UI.Label()
	self.outpost_3:SetParent(self.bonus_panel)
	self.outpost_3:SetSize(20, 3)
	self.outpost_3:SetPosition(50, 18)
	self.outpost_3:SetMouseVisible(false)
	self.outpost_3:SetVisible(not storage.show_outpost_disabled)

	self.outpost_3_text = Turbine.UI.Label()
	self.outpost_3_text:SetParent(self.bonus_panel)
	self.outpost_3_text:SetSize(20, 16)
	self.outpost_3_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.outpost_3_text:SetPosition(50, 11)
	self.outpost_3_text:SetMouseVisible(false)
	self.outpost_3_text:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.outpost_3_text:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.outpost_3_text:SetVisible(not storage.show_outpost_disabled)

	self.outpost_4 = Turbine.UI.Label()
	self.outpost_4:SetParent(self.bonus_panel)
	self.outpost_4:SetSize(20, 3)
	self.outpost_4:SetPosition(75, 18)
	self.outpost_4:SetMouseVisible(false)
	self.outpost_4:SetVisible(not storage.show_outpost_disabled)

	self.outpost_4_text = Turbine.UI.Label()
	self.outpost_4_text:SetParent(self.bonus_panel)
	self.outpost_4_text:SetSize(20, 16)
	self.outpost_4_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.outpost_4_text:SetPosition(75, 11)
	self.outpost_4_text:SetMouseVisible(false)
	self.outpost_4_text:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.outpost_4_text:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.outpost_4_text:SetVisible(not storage.show_outpost_disabled)


	-- Keep Labels
	self.freep_keep_1 = Turbine.UI.Label()
	self.freep_keep_1:SetParent(self.panel)
	self.freep_keep_1:SetSize(24, 24)
	self.freep_keep_1:SetPosition(self.bonus_panel:GetLeft() - 30, 0)
	self.freep_keep_1:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/BlueFire.tga")
	self.freep_keep_1:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_keep_1:SetMouseVisible(false)
	self.freep_keep_1:SetVisible(false)

	self.freep_keep_1_text = Turbine.UI.Label()
	self.freep_keep_1_text:SetParent(self.panel)
	self.freep_keep_1_text:SetSize(24, 24)
	self.freep_keep_1_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.freep_keep_1_text:SetPosition(self.bonus_panel:GetLeft() - 30, 2)
	self.freep_keep_1_text:SetMouseVisible(false)
	self.freep_keep_1_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.freep_keep_1_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.freep_keep_2 = Turbine.UI.Label()
	self.freep_keep_2:SetParent(self.panel)
	self.freep_keep_2:SetSize(24, 24)
	self.freep_keep_2:SetPosition(self.freep_keep_1:GetLeft() - 26, 0)
	self.freep_keep_2:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/BlueFire.tga")
	self.freep_keep_2:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_keep_2:SetMouseVisible(false)
	self.freep_keep_2:SetVisible(false)

	self.freep_keep_2_text = Turbine.UI.Label()
	self.freep_keep_2_text:SetParent(self.panel)
	self.freep_keep_2_text:SetSize(24, 24)
	self.freep_keep_2_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.freep_keep_2_text:SetPosition(self.freep_keep_1_text:GetLeft() - 26, 2)
	self.freep_keep_2_text:SetMouseVisible(false)
	self.freep_keep_2_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.freep_keep_2_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.freep_keep_3 = Turbine.UI.Label()
	self.freep_keep_3:SetParent(self.panel)
	self.freep_keep_3:SetSize(24, 24)
	self.freep_keep_3:SetPosition(self.freep_keep_2:GetLeft() - 26, 0)
	self.freep_keep_3:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/BlueFire.tga")
	self.freep_keep_3:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_keep_3:SetMouseVisible(false)
	self.freep_keep_3:SetVisible(false)

	self.freep_keep_3_text = Turbine.UI.Label()
	self.freep_keep_3_text:SetParent(self.panel)
	self.freep_keep_3_text:SetSize(24, 24)
	self.freep_keep_3_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.freep_keep_3_text:SetPosition(self.freep_keep_2_text:GetLeft() - 26, 2)
	self.freep_keep_3_text:SetMouseVisible(false)
	self.freep_keep_3_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.freep_keep_3_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.freep_keep_4 = Turbine.UI.Label()
	self.freep_keep_4:SetParent(self.panel)
	self.freep_keep_4:SetSize(24, 24)
	self.freep_keep_4:SetPosition(self.freep_keep_3:GetLeft() - 26, 0)
	self.freep_keep_4:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/BlueFire.tga")
	self.freep_keep_4:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_keep_4:SetMouseVisible(false)
	self.freep_keep_4:SetVisible(false)

	self.freep_keep_4_text = Turbine.UI.Label()
	self.freep_keep_4_text:SetParent(self.panel)
	self.freep_keep_4_text:SetSize(24, 24)
	self.freep_keep_4_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.freep_keep_4_text:SetPosition(self.freep_keep_3_text:GetLeft() - 26, 2)
	self.freep_keep_4_text:SetMouseVisible(false)
	self.freep_keep_4_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.freep_keep_4_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.freep_keep_5 = Turbine.UI.Label()
	self.freep_keep_5:SetParent(self.panel)
	self.freep_keep_5:SetSize(24, 24)
	self.freep_keep_5:SetPosition(self.freep_keep_4:GetLeft() - 26, 0)
	self.freep_keep_5:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/BlueFire.tga")
	self.freep_keep_5:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_keep_5:SetMouseVisible(false)
	self.freep_keep_5:SetVisible(false)

	self.freep_keep_5_text = Turbine.UI.Label()
	self.freep_keep_5_text:SetParent(self.panel)
	self.freep_keep_5_text:SetSize(24, 24)
	self.freep_keep_5_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.freep_keep_5_text:SetPosition(self.freep_keep_4_text:GetLeft() - 26, 2)
	self.freep_keep_5_text:SetMouseVisible(false)
	self.freep_keep_5_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.freep_keep_5_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_keep_1 = Turbine.UI.Label()
	self.creep_keep_1:SetParent(self.panel)
	self.creep_keep_1:SetSize(24, 24)
	self.creep_keep_1:SetPosition(self.bonus_panel:GetLeft() + self.bonus_panel:GetSize() + 6, 0)
	self.creep_keep_1:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/RedFire.tga")
	self.creep_keep_1:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_keep_1:SetMouseVisible(false)
	self.creep_keep_1:SetVisible(false)

	self.creep_keep_1_text = Turbine.UI.Label()
	self.creep_keep_1_text:SetParent(self.panel)
	self.creep_keep_1_text:SetSize(24, 24)
	self.creep_keep_1_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.creep_keep_1_text:SetPosition(self.bonus_panel:GetLeft() + self.bonus_panel:GetSize() + 6, 2)
	self.creep_keep_1_text:SetMouseVisible(false)
	self.creep_keep_1_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.creep_keep_1_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_keep_2 = Turbine.UI.Label()
	self.creep_keep_2:SetParent(self.panel)
	self.creep_keep_2:SetSize(24, 24)
	self.creep_keep_2:SetPosition(self.creep_keep_1:GetLeft() + 26, 0)
	self.creep_keep_2:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/RedFire.tga")
	self.creep_keep_2:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_keep_2:SetMouseVisible(false)
	self.creep_keep_2:SetVisible(false)

	self.creep_keep_2_text = Turbine.UI.Label()
	self.creep_keep_2_text:SetParent(self.panel)
	self.creep_keep_2_text:SetSize(24, 24)
	self.creep_keep_2_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.creep_keep_2_text:SetPosition(self.creep_keep_1_text:GetLeft() + 26, 2)
	self.creep_keep_2_text:SetMouseVisible(false)
	self.creep_keep_2_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.creep_keep_2_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_keep_3 = Turbine.UI.Label()
	self.creep_keep_3:SetParent(self.panel)
	self.creep_keep_3:SetSize(24, 24)
	self.creep_keep_3:SetPosition(self.creep_keep_2:GetLeft() + 26, 0)
	self.creep_keep_3:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/RedFire.tga")
	self.creep_keep_3:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_keep_3:SetMouseVisible(false)
	self.creep_keep_3:SetVisible(false)

	self.creep_keep_3_text = Turbine.UI.Label()
	self.creep_keep_3_text:SetParent(self.panel)
	self.creep_keep_3_text:SetSize(24, 24)
	self.creep_keep_3_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.creep_keep_3_text:SetPosition(self.creep_keep_2_text:GetLeft() + 26, 2)
	self.creep_keep_3_text:SetMouseVisible(false)
	self.creep_keep_3_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.creep_keep_3_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_keep_4 = Turbine.UI.Label()
	self.creep_keep_4:SetParent(self.panel)
	self.creep_keep_4:SetSize(24, 24)
	self.creep_keep_4:SetPosition(self.creep_keep_3:GetLeft() + 26, 0)
	self.creep_keep_4:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/RedFire.tga")
	self.creep_keep_4:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_keep_4:SetMouseVisible(false)
	self.creep_keep_4:SetVisible(false)

	self.creep_keep_4_text = Turbine.UI.Label()
	self.creep_keep_4_text:SetParent(self.panel)
	self.creep_keep_4_text:SetSize(24, 24)
	self.creep_keep_4_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.creep_keep_4_text:SetPosition(self.creep_keep_3_text:GetLeft() + 26, 2)
	self.creep_keep_4_text:SetMouseVisible(false)
	self.creep_keep_4_text:SetFont(Turbine.UI.Lotro.Font.Verdana16)
	self.creep_keep_4_text:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_keep_5 = Turbine.UI.Label()
	self.creep_keep_5:SetParent(self.panel)
	self.creep_keep_5:SetSize(24, 24)
	self.creep_keep_5:SetPosition(self.creep_keep_4:GetLeft() + 26, 0)
	self.creep_keep_5:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/KeepIcons/RedFire.tga")
	self.creep_keep_5:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_keep_5:SetMouseVisible(false)
	self.creep_keep_5:SetVisible(false)

	self.creep_keep_5_text = Turbine.UI.Label()
	self.creep_keep_5_text:SetParent(self.panel)
	self.creep_keep_5_text:SetSize(24, 24)
	self.creep_keep_5_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.creep_keep_5_text:SetPosition(self.creep_keep_4_text:GetLeft() + 26, 2)
	self.creep_keep_5_text:SetMouseVisible(false)
	self.creep_keep_5_text:SetFont(Turbine.UI.Lotro.Font.Verdana14)
	self.creep_keep_5_text:SetFontStyle(Turbine.UI.FontStyle.Outline)


	-- Delving Labels
	self.freep_tree_icon = Turbine.UI.Label()
	self.freep_tree_icon:SetParent(self.panel)
	self.freep_tree_icon:SetSize(32, 32)
	self.freep_tree_icon:SetPosition(self.freep_keep_5:GetLeft() - 27, 0)
	self.freep_tree_icon:SetBackground(0x4112D3CD)
	self.freep_tree_icon:SetStretchMode(1)
	self.freep_tree_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.freep_tree_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_tree_icon:SetMouseVisible(false)

	self.freep_tree_timer = Turbine.UI.Label()
	self.freep_tree_timer:SetParent(self.panel)
	self.freep_tree_timer:SetSize(30, 15)
	self.freep_tree_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.freep_tree_timer:SetPosition(self.freep_keep_5:GetLeft() - 35, 13)
	self.freep_tree_timer:SetMouseVisible(false)
	self.freep_tree_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.freep_tree_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.freep_gary_icon = Turbine.UI.Label()
	self.freep_gary_icon:SetParent(self.panel)
	self.freep_gary_icon:SetSize(32, 32)
	self.freep_gary_icon:SetPosition(self.freep_tree_icon:GetLeft() - 28, 0)
	self.freep_gary_icon:SetBackground(0x4112D3CE)
	self.freep_gary_icon:SetStretchMode(1)
	self.freep_gary_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.freep_gary_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_gary_icon:SetMouseVisible(false)

	self.freep_gary_timer = Turbine.UI.Label()
	self.freep_gary_timer:SetParent(self.panel)
	self.freep_gary_timer:SetSize(30, 15)
	self.freep_gary_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.freep_gary_timer:SetPosition(self.freep_tree_timer:GetLeft() - 28, 13)
	self.freep_gary_timer:SetMouseVisible(false)
	self.freep_gary_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.freep_gary_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.freep_drake_icon = Turbine.UI.Label()
	self.freep_drake_icon:SetParent(self.panel)
	self.freep_drake_icon:SetSize(32, 32)
	self.freep_drake_icon:SetPosition(self.freep_gary_icon:GetLeft() - 28, 0)
	self.freep_drake_icon:SetBackground(0x4112D3D0)
	self.freep_drake_icon:SetStretchMode(1)
	self.freep_drake_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.freep_drake_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_drake_icon:SetMouseVisible(false)

	self.freep_drake_timer = Turbine.UI.Label()
	self.freep_drake_timer:SetParent(self.panel)
	self.freep_drake_timer:SetSize(30, 15)
	self.freep_drake_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.freep_drake_timer:SetPosition(self.freep_gary_timer:GetLeft() - 28, 13)
	self.freep_drake_timer:SetMouseVisible(false)
	self.freep_drake_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.freep_drake_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_tree_icon = Turbine.UI.Label()
	self.creep_tree_icon:SetParent(self.panel)
	self.creep_tree_icon:SetSize(32, 32)
	self.creep_tree_icon:SetPosition(self.creep_keep_5:GetLeft() + 36, 0)
	self.creep_tree_icon:SetBackground(0x4112D3CD)
	self.creep_tree_icon:SetStretchMode(1)
	self.creep_tree_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.creep_tree_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_tree_icon:SetMouseVisible(false)

	self.creep_tree_timer = Turbine.UI.Label()
	self.creep_tree_timer:SetParent(self.panel)
	self.creep_tree_timer:SetSize(30, 15)
	self.creep_tree_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.creep_tree_timer:SetPosition(self.creep_keep_5:GetLeft() + 28, 13)
	self.creep_tree_timer:SetMouseVisible(false)
	self.creep_tree_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.creep_tree_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_gary_icon = Turbine.UI.Label()
	self.creep_gary_icon:SetParent(self.panel)
	self.creep_gary_icon:SetSize(32, 32)
	self.creep_gary_icon:SetPosition(self.creep_tree_icon:GetLeft() + 28, 0)
	self.creep_gary_icon:SetBackground(0x4112D3CE)
	self.creep_gary_icon:SetStretchMode(1)
	self.creep_gary_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.creep_gary_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_gary_icon:SetMouseVisible(false)

	self.creep_gary_timer = Turbine.UI.Label()
	self.creep_gary_timer:SetParent(self.panel)
	self.creep_gary_timer:SetSize(30, 15)
	self.creep_gary_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.creep_gary_timer:SetPosition(self.creep_tree_timer:GetLeft() + 28, 13)
	self.creep_gary_timer:SetMouseVisible(false)
	self.creep_gary_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.creep_gary_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_drake_icon = Turbine.UI.Label()
	self.creep_drake_icon:SetParent(self.panel)
	self.creep_drake_icon:SetSize(32, 32)
	self.creep_drake_icon:SetPosition(self.creep_gary_icon:GetLeft() + 28, 0)
	self.creep_drake_icon:SetBackground(0x4112D3D0)
	self.creep_drake_icon:SetStretchMode(1)
	self.creep_drake_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.creep_drake_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_drake_icon:SetMouseVisible(false)

	self.creep_drake_timer = Turbine.UI.Label()
	self.creep_drake_timer:SetParent(self.panel)
	self.creep_drake_timer:SetSize(30, 15)
	self.creep_drake_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.creep_drake_timer:SetPosition(self.creep_gary_timer:GetLeft() + 28, 13)
	self.creep_drake_timer:SetMouseVisible(false)
	self.creep_drake_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.creep_drake_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)


	-- Relic Labels
	self.freep_carrock_icon = Turbine.UI.Label()
	self.freep_carrock_icon:SetParent(self.panel)
	self.freep_carrock_icon:SetSize(32, 32)
	self.freep_carrock_icon:SetPosition(self.freep_drake_icon:GetLeft() - 35, 0)
	self.freep_carrock_icon:SetBackground(0x4112d3c8)
	self.freep_carrock_icon:SetStretchMode(1)
	self.freep_carrock_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.freep_carrock_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_carrock_icon:SetMouseVisible(false)

	self.freep_carrock_timer = Turbine.UI.Label()
	self.freep_carrock_timer:SetParent(self.panel)
	self.freep_carrock_timer:SetSize(30, 15)
	self.freep_carrock_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.freep_carrock_timer:SetPosition(self.freep_drake_timer:GetLeft() - 35, 13)
	self.freep_carrock_timer:SetMouseVisible(false)
	self.freep_carrock_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.freep_carrock_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.freep_crown_icon = Turbine.UI.Label()
	self.freep_crown_icon:SetParent(self.panel)
	self.freep_crown_icon:SetSize(32, 32)
	self.freep_crown_icon:SetPosition(self.freep_carrock_icon:GetLeft() - 28, 0)
	self.freep_crown_icon:SetBackground(0x4112d3c7)
	self.freep_crown_icon:SetStretchMode(1)
	self.freep_crown_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.freep_crown_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_crown_icon:SetMouseVisible(false)

	self.freep_crown_timer = Turbine.UI.Label()
	self.freep_crown_timer:SetParent(self.panel)
	self.freep_crown_timer:SetSize(30, 15)
	self.freep_crown_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.freep_crown_timer:SetPosition(self.freep_carrock_timer:GetLeft() - 28, 13)
	self.freep_crown_timer:SetMouseVisible(false)
	self.freep_crown_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.freep_crown_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_crown_icon = Turbine.UI.Label()
	self.creep_crown_icon:SetParent(self.panel)
	self.creep_crown_icon:SetSize(32, 32)
	self.creep_crown_icon:SetPosition(self.creep_drake_icon:GetLeft() + 35, 0)
	self.creep_crown_icon:SetBackground(0x4112d3c7)
	self.creep_crown_icon:SetStretchMode(1)
	self.creep_crown_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.creep_crown_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_crown_icon:SetMouseVisible(false)

	self.creep_crown_timer = Turbine.UI.Label()
	self.creep_crown_timer:SetParent(self.panel)
	self.creep_crown_timer:SetSize(30, 15)
	self.creep_crown_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.creep_crown_timer:SetPosition(self.creep_drake_timer:GetLeft() + 35, 13)
	self.creep_crown_timer:SetMouseVisible(false)
	self.creep_crown_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.creep_crown_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_carrock_icon = Turbine.UI.Label()
	self.creep_carrock_icon:SetParent(self.panel)
	self.creep_carrock_icon:SetSize(32, 32)
	self.creep_carrock_icon:SetPosition(self.creep_crown_icon:GetLeft() + 28, 0)
	self.creep_carrock_icon:SetBackground(0x4112d3c8)
	self.creep_carrock_icon:SetStretchMode(1)
	self.creep_carrock_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.creep_carrock_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_carrock_icon:SetMouseVisible(false)

	self.creep_carrock_timer = Turbine.UI.Label()
	self.creep_carrock_timer:SetParent(self.panel)
	self.creep_carrock_timer:SetSize(30, 15)
	self.creep_carrock_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.creep_carrock_timer:SetPosition(self.creep_crown_timer:GetLeft() + 28, 13)
	self.creep_carrock_timer:SetMouseVisible(false)
	self.creep_carrock_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.creep_carrock_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)


	-- Outnumbered Labels
	self.freep_outnumbered_icon = Turbine.UI.Label()
	self.freep_outnumbered_icon:SetParent(self.panel)
	self.freep_outnumbered_icon:SetSize(32, 32)
	self.freep_outnumbered_icon:SetPosition(self.freep_crown_icon:GetLeft() - 35, 0)
	self.freep_outnumbered_icon:SetBackground(0x410e6df7)
	self.freep_outnumbered_icon:SetStretchMode(1)
	self.freep_outnumbered_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.freep_outnumbered_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.freep_outnumbered_icon:SetMouseVisible(false)

	self.freep_outnumbered_timer = Turbine.UI.Label()
	self.freep_outnumbered_timer:SetParent(self.panel)
	self.freep_outnumbered_timer:SetSize(30, 15)
	self.freep_outnumbered_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.freep_outnumbered_timer:SetPosition(self.freep_crown_timer:GetLeft() - 35, 13)
	self.freep_outnumbered_timer:SetMouseVisible(false)
	self.freep_outnumbered_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.freep_outnumbered_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

	self.creep_outnumbered_icon = Turbine.UI.Label()
	self.creep_outnumbered_icon:SetParent(self.panel)
	self.creep_outnumbered_icon:SetSize(32, 32)
	self.creep_outnumbered_icon:SetPosition(self.creep_carrock_icon:GetLeft() + 35, 0)
	self.creep_outnumbered_icon:SetBackground(0x410e6d15)
	self.creep_outnumbered_icon:SetStretchMode(1)
	self.creep_outnumbered_icon:AttachEdges(Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same, Turbine.UI.EdgeAttachmentType.Same)
	self.creep_outnumbered_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.creep_outnumbered_icon:SetMouseVisible(false)

	self.creep_outnumbered_timer = Turbine.UI.Label()
	self.creep_outnumbered_timer:SetParent(self.panel)
	self.creep_outnumbered_timer:SetSize(30, 15)
	self.creep_outnumbered_timer:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
	self.creep_outnumbered_timer:SetPosition(self.creep_carrock_timer:GetLeft() + 35, 13)
	self.creep_outnumbered_timer:SetMouseVisible(false)
	self.creep_outnumbered_timer:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.creep_outnumbered_timer:SetFontStyle(Turbine.UI.FontStyle.Outline)


	-- Points Label
	self.label_points = Turbine.UI.Label()
	self.label_points:SetParent(self.panel)
	self.label_points:SetSize(width - 108, 20)
	self.label_points:SetForeColor(Default_Font_Color)
	self.label_points:SetPosition(width / 2 - self.label_points:GetSize() / 2, 45)
	self.label_points:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_points:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_points:SetFontStyle(Turbine.UI.FontStyle.Outline)


	-- Points Footer
	self.points_footer = Turbine.UI.Label()
	self.points_footer:SetParent(self.panel)
	self.points_footer:SetSize(width, 35)
	self.points_footer:SetPosition(0, 70)
	self.points_footer:SetMouseVisible(false)
	self.points_footer:SetVisible(not storage.stats_hidden)

	self.label_month		= OverviewLabel(self.points_footer, width, 0, Default_Font_Color)
	self.label_day			= OverviewLabel(self.points_footer, width, 1, Default_Font_Color)
	self.label_last_hour	= OverviewLabel(self.points_footer, width, 2, Default_Font_Color)
	self.label_10min		= OverviewLabel(self.points_footer, width, 3, Default_Font_Color)
	self.label_last_fight	= OverviewLabel(self.points_footer, width, 4, Default_Font_Color)


	-- Commendations Footer
	self.commendations_footer = Turbine.UI.Label()
	self.commendations_footer:SetParent(self.panel)
	self.commendations_footer:SetSize(width, 35)
	self.commendations_footer:SetPosition(0, 70)
	self.commendations_footer:SetMouseVisible(false)
	self.commendations_footer:SetVisible(false)

	self.label_month_comms		= OverviewLabel(self.commendations_footer, width, 0, Turbine.UI.Color.White)
	self.label_day_comms		= OverviewLabel(self.commendations_footer, width, 1, Turbine.UI.Color.White)
	self.label_last_hour_comms	= OverviewLabel(self.commendations_footer, width, 2, Turbine.UI.Color.White)
	self.label_10min_comms		= OverviewLabel(self.commendations_footer, width, 3, Turbine.UI.Color.White)
	self.label_last_fight_comms	= OverviewLabel(self.commendations_footer, width, 4, Turbine.UI.Color.White)


	-- Frags Footer
	self.frags_footer = Turbine.UI.Label()
	self.frags_footer:SetParent(self.panel)
	self.frags_footer:SetSize(width, 35)
	self.frags_footer:SetPosition(0, 70)
	self.frags_footer:SetMouseVisible(false)
	self.frags_footer:SetVisible(false)

	self.label_month_frags		= OverviewLabel(self.frags_footer, width, 0, Turbine.UI.Color.White)
	self.label_day_frags		= OverviewLabel(self.frags_footer, width, 1, Turbine.UI.Color.White)
	self.label_last_hour_frags	= OverviewLabel(self.frags_footer, width, 2, Turbine.UI.Color.White)
	self.label_10min_frags		= OverviewLabel(self.frags_footer, width, 3, Turbine.UI.Color.White)
	self.label_last_fight_frags	= OverviewLabel(self.frags_footer, width, 4, Turbine.UI.Color.White)


	-- Commendations Label Toggle
	self.commendations_panel = Turbine.UI.Label()
	self.commendations_panel:SetParent(self.panel)
	self.commendations_panel:SetSize(54, 50)
	self.commendations_panel:SetPosition(width - 54, 18)
	self.commendations_panel.MouseEnter = function()
		if not storage.stats_hidden and self.separator:IsVisible() then
			self.commendations_footer:SetVisible(true)
			self.points_footer:SetVisible(false)
			self.frags_footer:SetVisible(false)
			if Commendation_Warning and not storage.comms_warning_disabled then
				self.label_commendations:SetForeColor(Turbine.UI.Color.Red)
			elseif not Commendation_Warning or storage.comms_warning_disabled then
				self.label_commendations:SetForeColor(Turbine.UI.Color.White)
			end
		end
	end

	self.commendations_panel.MouseLeave = function()
		if not storage.stats_hidden and self.separator:IsVisible() then
			self.commendations_footer:SetVisible(false)
			self.points_footer:SetVisible(true)
			self.frags_footer:SetVisible(false)
			if Commendation_Warning and not storage.comms_warning_disabled then
				self.label_commendations:SetForeColor(Turbine.UI.Color.Red)
			elseif not Commendation_Warning or storage.comms_warning_disabled then
				self.label_commendations:SetForeColor(Default_Font_Color)
			end
		end
	end


	-- Commendations Label
	self.label_commendations = Turbine.UI.Label()
	self.label_commendations:SetParent(self.commendations_panel)
	self.label_commendations:SetSize(54, 20)
	self.label_commendations:SetPosition(0, 30)
	self.label_commendations:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_commendations:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_commendations:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_commendations:SetMouseVisible(false)
	if Commendation_Warning and not storage.comms_warning_disabled then
		self.label_commendations:SetForeColor(Turbine.UI.Color.Red)
	elseif not Commendation_Warning or storage.comms_warning_disabled then
		self.label_commendations:SetForeColor(Default_Font_Color)
	end

	self.commendations_icon = Turbine.UI.Control()
	self.commendations_icon:SetParent(self.commendations_panel)
	self.commendations_icon:SetSize(32, 32)
	self.commendations_icon:SetPosition(11, 0)
	self.commendations_icon:SetBackground(0x41123495)
	self.commendations_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.commendations_icon:SetMouseVisible(false)


	-- Rank Label Toggle
	self.rank_panel = Turbine.UI.Label()
	self.rank_panel:SetParent(self.panel)
	self.rank_panel:SetSize(54, 50)
	self.rank_panel:SetPosition(0, 18)
	self.rank_panel.MouseEnter = function()
		if not storage.stats_hidden and self.separator:IsVisible() then
			self.frags_footer:SetVisible(true)
			self.points_footer:SetVisible(false)
			self.commendations_footer:SetVisible(false)
			self.label_rank:SetForeColor(Turbine.UI.Color.White)
		end
	end

	self.rank_panel.MouseLeave = function()
		if not storage.stats_hidden and self.separator:IsVisible() then
			self.frags_footer:SetVisible(false)
			self.points_footer:SetVisible(true)
			self.commendations_footer:SetVisible(false)
			self.label_rank:SetForeColor(Default_Font_Color)
		end
	end


	-- Rank Label
	self.label_rank = Turbine.UI.Label()
	self.label_rank:SetParent(self.rank_panel)
	self.label_rank:SetSize(54, 20)
	self.label_rank:SetForeColor(Default_Font_Color)
	self.label_rank:SetPosition(0, 30)
	self.label_rank:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.label_rank:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
	self.label_rank:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.label_rank:SetMouseVisible(false)

	self.rank_icon = Turbine.UI.Control()
	self.rank_icon:SetParent(self.rank_panel)
	self.rank_icon:SetSize(32, 32)
	self.rank_icon:SetPosition(11, 0)
	self.rank_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.rank_icon:SetMouseVisible(false)


	-- Separator
	self.separator = Turbine.UI.Control()
	self.separator:SetParent(self.panel)
	self.separator:SetSize(width, 1)
	self.separator:SetPosition(0, 70)
	self.separator:SetBackColor(Default_Font_Color)
	self.separator:SetMouseVisible(false)
	self.separator:SetVisible(not storage.stats_hidden)


	-- Repositioning
	self.PositionChanged = function(sender, args)
		data.numbers.overview_x = self:GetLeft()
		data.numbers.overview_y = self:GetTop()
		OverviewSettingsPanel:SetPosition(self:GetLeft() + self:GetWidth() - OverviewSettingsPanel:GetWidth(), self:GetTop())	
	end


	-- Points Toggle
	self.label_points.MouseDown = function()
		storage.show_remaining_points = not storage.show_remaining_points
		self:Update()
	end

	self.KeyDown = function(sender, args) 
		if args.Action == Turbine.UI.Lotro.Action.UI_Toggle then
			self:SetVisible(not self:IsVisible())
			OverviewSettingsPanel:SetVisible(not OverviewSettingsPanel:IsVisible())
			SecondaryWindow:SetVisible(not (SecondaryWindow:IsVisible() or storage.secondaryMinimized or storage.minimized))
			RecentHitsWindow:SetVisible(not (RecentHitsWindow:IsVisible() or storage.HitWindowMinimized or storage.minimized))
			AlertWindow:SetVisible(not AlertWindow:IsVisible())
			BattleTaskWindow:SetVisible(not BattleTaskWindow:IsVisible())
		end
	end
end

function OverviewWindow:Update()
	local text			= ""
	local hours			= 0
	local minutes		= 0
	local minute_mod	= 0

	local points_last_24_hours, points_last_hour, points_last_10_minutes	= GetRecentData(data.numbers.recent_points)
	local comms_last_24_hours, comms_last_hour, comms_last_10_minutes		= GetRecentData(data.numbers.recent_comms)
	local frags_last_24_hours, frags_last_hour, frags_last_10_minutes		= GetRecentData(data.numbers.recent_frags)

	self.label_commendations:SetText(FormatPoints(Current_Commendations))

	if self:GetWidth() < 490 then
		if storage.show_remaining_points then
			self.label_points:SetText(L.Stats_Remaining_Points_Short .. FormatPoints(GetRemainingPoints()))
		else
			self.label_points:SetText(L.Stats_Total_Points_Short .. FormatPoints(data.numbers.points_total))
		end
		self:SetStatsVisibility(false)
	elseif self:GetWidth() < 900 then
		if storage.show_remaining_points then
			self.label_points:SetText(L.Stats_Remaining_Points .. FormatPoints(GetRemainingPoints()))
		else
			self.label_points:SetText(L.Stats_Total_Points .. FormatPoints(data.numbers.points_total))
		end
		if not self.separator:IsVisible() then
			self:SetStatsVisibility(not storage.stats_hidden)
		end
		self.label_month:SetText(L.Stats_Current_Month_Short .. FormatPoints(data.numbers.points_current_month))
		self.label_day:SetText(L.Stats_Current_Day_Short .. FormatPoints(data.numbers.points_current_day))
		self.label_last_hour:SetText(L.Stats_Last_Hour_Short .. points_last_hour)
		self.label_10min:SetText(L.Stats_Last_10min_Short .. points_last_10_minutes)
		self.label_last_fight:SetText(L.Stats_Last_Fight_Short .. FormatPoints(Points_Last_Fight))

		self.label_month_comms:SetText(L.Stats_Current_Month_Short .. FormatPoints(data.numbers.comms_current_month))
		self.label_day_comms:SetText(L.Stats_Current_Day_Short .. FormatPoints(data.numbers.comms_current_day))
		self.label_last_hour_comms:SetText(L.Stats_Last_Hour_Short .. comms_last_hour)
		self.label_10min_comms:SetText(L.Stats_Last_10min_Short .. comms_last_10_minutes)
		self.label_last_fight_comms:SetText(L.Stats_Last_Fight_Short .. FormatPoints(Comms_Last_Fight))

		self.label_month_frags:SetText(L.Stats_Current_Month_Short .. FormatPoints(data.numbers.frags_current_month))
		self.label_day_frags:SetText(L.Stats_Current_Day_Short .. FormatPoints(data.numbers.frags_current_day))
		self.label_last_hour_frags:SetText(L.Stats_Last_Hour_Short .. frags_last_hour)
		self.label_10min_frags:SetText(L.Stats_Last_10min_Short .. frags_last_10_minutes)
		self.label_last_fight_frags:SetText(L.Stats_Last_Fight_Short .. FormatPoints(Frags_Last_Fight))
	else
		if storage.show_remaining_points then
			self.label_points:SetText(L.Stats_Remaining_Points .. FormatPoints(GetRemainingPoints()))
		else
			self.label_points:SetText(L.Stats_Total_Points .. FormatPoints(data.numbers.points_total))
		end
		if not self.separator:IsVisible() then
			self:SetStatsVisibility(not storage.stats_hidden)
		end
		self.label_month:SetText(L.Stats_Current_Month .. FormatPoints(data.numbers.points_current_month))
		self.label_day:SetText(L.Stats_Current_Day .. FormatPoints(data.numbers.points_current_day))
		self.label_last_hour:SetText(L.Stats_Last_Hour .. points_last_hour)
		self.label_10min:SetText(L.Stats_Last_10min .. points_last_10_minutes)
		self.label_last_fight:SetText(L.Stats_Last_Fight .. FormatPoints(Points_Last_Fight))

		self.label_month_comms:SetText(L.Stats_Current_Month .. FormatPoints(data.numbers.comms_current_month))
		self.label_day_comms:SetText(L.Stats_Current_Day .. FormatPoints(data.numbers.comms_current_day))
		self.label_last_hour_comms:SetText(L.Stats_Last_Hour ..comms_last_hour)
		self.label_10min_comms:SetText(L.Stats_Last_10min .. comms_last_10_minutes)
		self.label_last_fight_comms:SetText(L.Stats_Last_Fight .. FormatPoints(Comms_Last_Fight))

		self.label_month_frags:SetText(L.Stats_Current_Month .. FormatPoints(data.numbers.frags_current_month))
		self.label_day_frags:SetText(L.Stats_Current_Day .. FormatPoints(data.numbers.frags_current_day))
		self.label_last_hour_frags:SetText(L.Stats_Last_Hour .. frags_last_hour)
		self.label_10min_frags:SetText(L.Stats_Last_10min .. frags_last_10_minutes)
		self.label_last_fight_frags:SetText(L.Stats_Last_Fight .. FormatPoints(Frags_Last_Fight))
	end
	OverviewSettingsPanel:UpdateChatData()

	-- Resize the icons each iteration
	self.freep_tree_icon:SetSize(15, 15)
	self.freep_gary_icon:SetSize(15, 15)
	self.freep_drake_icon:SetSize(15, 15)
	self.creep_tree_icon:SetSize(15, 15)
	self.creep_gary_icon:SetSize(15, 15)
	self.creep_drake_icon:SetSize(15, 15)
	self.creep_crown_icon:SetSize(15, 15)
	self.creep_carrock_icon:SetSize(15, 15)
	self.freep_crown_icon:SetSize(15, 15)
	self.freep_carrock_icon:SetSize(15, 15)
	self.freep_outnumbered_icon:SetSize(15, 15)
	self.creep_outnumbered_icon:SetSize(15, 15)

	-- Update DOF buff timers
	-- Tree
	tree_buff_timer = tree_buff_timer + 1
	minute_mod = math.fmod(tree_buff_timer, 3600)
	minutes = (minute_mod - math.fmod(minute_mod, 60)) / 60
	hours = (tree_buff_timer - math.fmod(tree_buff_timer, 3600)) / 3600

	if minutes < 10 then
		text = hours .. ":0" .. minutes
	else
		text = hours .. ":" .. minutes
	end

	if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_tree_buff and not storage.show_dof_disabled then
			-- Enable creep side icon and text and set the text timer
			self.creep_tree_icon:SetVisible(true)
			self.creep_tree_timer:SetVisible(true)
			self.creep_tree_timer:SetText(text)

			-- Disable freep side icon and text
			self.freep_tree_icon:SetVisible(false)
			self.freep_tree_timer:SetVisible(false)
		elseif not storage.show_dof_disabled then
			-- Disable creep side icon and text
			self.creep_tree_icon:SetVisible(false)
			self.creep_tree_timer:SetVisible(false)

			-- Enable freep side icon and text and set the text timer
			self.freep_tree_icon:SetVisible(true)
			self.freep_tree_timer:SetVisible(true)
			self.freep_tree_timer:SetText(text)
		else
			-- Disable creep side icon and text
			self.creep_tree_icon:SetVisible(false)
			self.creep_tree_timer:SetVisible(false)

			-- Disable freep side icon and text
			self.freep_tree_icon:SetVisible(false)
			self.freep_tree_timer:SetVisible(false)
		end
	elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_tree_buff and not storage.show_dof_disabled then
			-- Enable freep side icon and text and set the text timer
			self.freep_tree_icon:SetVisible(true)
			self.freep_tree_timer:SetVisible(true)
			self.freep_tree_timer:SetText(text)

			-- Disable creep side icon and text
			self.creep_tree_icon:SetVisible(false)
			self.creep_tree_timer:SetVisible(false)
		elseif not storage.show_dof_disabled then
			-- Disable freep side icon and text
			self.freep_tree_icon:SetVisible(false)
			self.freep_tree_timer:SetVisible(false)

			-- Enable creep side icon and text and set the text timer
			self.creep_tree_icon:SetVisible(true)
			self.creep_tree_timer:SetVisible(true)
			self.creep_tree_timer:SetText(text)
		else
			-- Disable freep side icon and text
			self.freep_tree_icon:SetVisible(false)
			self.freep_tree_timer:SetVisible(false)

			-- Disable creep side icon and text
			self.creep_tree_icon:SetVisible(false)
			self.creep_tree_timer:SetVisible(false)
		end
	end

	-- Update DOF buff timers
	-- Drake
	drake_buff_timer = drake_buff_timer + 1
	minute_mod = math.fmod(drake_buff_timer, 3600)
	minutes = (minute_mod - math.fmod(minute_mod, 60)) / 60
	hours = (drake_buff_timer - math.fmod(drake_buff_timer, 3600)) / 3600

	if minutes < 10 then
		text = hours .. ":0" .. minutes
	else
		text = hours .. ":" .. minutes
	end

	if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_drake_buff and not storage.show_dof_disabled then
			-- Enable creep side icon and text and set the text timer
			self.creep_drake_icon:SetVisible(true)
			self.creep_drake_timer:SetVisible(true)
			self.creep_drake_timer:SetText(text)

			-- Disable freep side icon and text
			self.freep_drake_icon:SetVisible(false)
			self.freep_drake_timer:SetVisible(false)
		elseif not storage.show_dof_disabled then
			-- Disable creep side icon and text
			self.creep_drake_icon:SetVisible(false)
			self.creep_drake_timer:SetVisible(false)

			-- Enable freep side icon and text and set the text timer
			self.freep_drake_icon:SetVisible(true)
			self.freep_drake_timer:SetVisible(true)
			self.freep_drake_timer:SetText(text)
		else
			-- Disable creep side icon and text
			self.creep_drake_icon:SetVisible(false)
			self.creep_drake_timer:SetVisible(false)

			-- Disable freep side icon and text
			self.freep_drake_icon:SetVisible(false)
			self.freep_drake_timer:SetVisible(false)
		end
	elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_drake_buff and not storage.show_dof_disabled then
			-- Enable freep side icon and text and set the text timer
			self.freep_drake_icon:SetVisible(true)
			self.freep_drake_timer:SetVisible(true)
			self.freep_drake_timer:SetText(text)

			-- Disable creep side icon and text
			self.creep_drake_icon:SetVisible(false)
			self.creep_drake_timer:SetVisible(false)
		elseif not storage.show_dof_disabled then
			-- Disable freep side icon and text
			self.freep_drake_icon:SetVisible(false)
			self.freep_drake_timer:SetVisible(false)

			-- Enable creep side icon and text and set the text timer
			self.creep_drake_icon:SetVisible(true)
			self.creep_drake_timer:SetVisible(true)
			self.creep_drake_timer:SetText(text)
		else
			-- Disable freep side icon and text
			self.freep_drake_icon:SetVisible(false)
			self.freep_drake_timer:SetVisible(false)

			-- Disable creep side icon and text
			self.creep_drake_icon:SetVisible(false)
			self.creep_drake_timer:SetVisible(false)
		end
	end

	-- Update DOF buff timers
	-- Gary
	gary_buff_timer = gary_buff_timer + 1
	minute_mod = math.fmod(gary_buff_timer, 3600)
	minutes = (minute_mod - math.fmod(minute_mod, 60)) / 60
	hours = (gary_buff_timer - math.fmod(gary_buff_timer, 3600)) / 3600

	if minutes < 10 then
		text = hours .. ":0" .. minutes
	else
		text = hours .. ":" .. minutes
	end

	if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_gary_buff and not storage.show_dof_disabled then
			-- Enable creep side icon and text and set the text timer
			self.creep_gary_icon:SetVisible(true)
			self.creep_gary_timer:SetVisible(true)
			self.creep_gary_timer:SetText(text)

			-- Disable freep side icon and text
			self.freep_gary_icon:SetVisible(false)
			self.freep_gary_timer:SetVisible(false)
		elseif not storage.show_dof_disabled then
			-- Disable creep side icon and text
			self.creep_gary_icon:SetVisible(false)
			self.creep_gary_timer:SetVisible(false)

			-- Enable freep side icon and text and set the text timer
			self.freep_gary_icon:SetVisible(true)
			self.freep_gary_timer:SetVisible(true)
			self.freep_gary_timer:SetText(text)
		else
			-- Disable creep side icon and text
			self.creep_gary_icon:SetVisible(false)
			self.creep_gary_timer:SetVisible(false)

			-- Disable freep side icon and text
			self.freep_gary_icon:SetVisible(false)
			self.freep_gary_timer:SetVisible(false)
		end
	elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_gary_buff and not storage.show_dof_disabled then
			-- Enable freep side icon and text and set the text timer
			self.freep_gary_icon:SetVisible(true)
			self.freep_gary_timer:SetVisible(true)
			self.freep_gary_timer:SetText(text)

			-- Disable creep side icon and text
			self.creep_gary_icon:SetVisible(false)
			self.creep_gary_timer:SetVisible(false)
		elseif not storage.show_dof_disabled then
			-- Disable freep side icon and text
			self.freep_gary_icon:SetVisible(false)
			self.freep_gary_timer:SetVisible(false)

			-- Enable creep side icon and text and set the text timer
			self.creep_gary_icon:SetVisible(true)
			self.creep_gary_timer:SetVisible(true)
			self.creep_gary_timer:SetText(text)
		else
			-- Disable freep side icon and text
			self.freep_gary_icon:SetVisible(false)
			self.freep_gary_timer:SetVisible(false)

			-- Disable creep side icon and text
			self.creep_gary_icon:SetVisible(false)
			self.creep_gary_timer:SetVisible(false)
		end
	end

	-- Update Relic timers
	-- Crown
	crown_buff_timer = crown_buff_timer + 1
	minute_mod = math.fmod(crown_buff_timer, 3600)
	minutes = (minute_mod - math.fmod(minute_mod, 60)) / 60
	hours = (crown_buff_timer - math.fmod(crown_buff_timer, 3600 )) / 3600

	if minutes < 10 then
		text = hours .. ":0" .. minutes
	else
		text = hours .. ":" .. minutes
	end

	if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_crown_buff and not storage.show_relic_disabled then
			-- Enable creep side icon and text and set the text timer
			self.creep_crown_icon:SetVisible(true)
			self.creep_crown_timer:SetVisible(true)
			self.creep_crown_timer:SetText(text)

			-- Disable freep side icon and text
			self.freep_crown_icon:SetVisible(false)
			self.freep_crown_timer:SetVisible(false)
		elseif not storage.show_relic_disabled then
			-- Disable creep side icon and text
			self.creep_crown_icon:SetVisible(false)
			self.creep_crown_timer:SetVisible(false)

			-- Enable freep side icon and text and set the text timer
			self.freep_crown_icon:SetVisible(true)
			self.freep_crown_timer:SetVisible(true)
			self.freep_crown_timer:SetText(text)
		else
			-- Disable creep side icon and text
			self.creep_crown_icon:SetVisible(false)
			self.creep_crown_timer:SetVisible(false)

			-- Disable freep side icon and text
			self.freep_crown_icon:SetVisible(false)
			self.freep_crown_timer:SetVisible(false)
		end
	elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_crown_buff and not storage.show_relic_disabled then
			-- Enable freep side icon and text and set the text timer
			self.freep_crown_icon:SetVisible(true)
			self.freep_crown_timer:SetVisible(true)
			self.freep_crown_timer:SetText(text)

			-- Disable creep side icon and text
			self.creep_crown_icon:SetVisible(false)
			self.creep_crown_timer:SetVisible(false)
		elseif not storage.show_relic_disabled then
			-- Disable freep side icon and text
			self.freep_crown_icon:SetVisible(false)
			self.freep_crown_timer:SetVisible(false)

			-- Enable creep side icon and text and set the text timer
			self.creep_crown_icon:SetVisible(true)
			self.creep_crown_timer:SetVisible(true)
			self.creep_crown_timer:SetText(text)
		else
			-- Disable freep side icon and text
			self.freep_crown_icon:SetVisible(false)
			self.freep_crown_timer:SetVisible(false)

			-- Disable creep side icon and text
			self.creep_crown_icon:SetVisible(false)
			self.creep_crown_timer:SetVisible(false)
		end
	end

	-- Update Relic timers
	-- Carrock
	carrock_buff_timer = carrock_buff_timer + 1
	minute_mod = math.fmod(carrock_buff_timer, 3600)
	minutes = (minute_mod - math.fmod(minute_mod, 60)) / 60
	hours = (carrock_buff_timer - math.fmod(carrock_buff_timer, 3600)) / 3600

	if minutes < 10 then
		text = hours .. ":0" .. minutes
	else
		text = hours .. ":" .. minutes
	end

	if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_carrock_buff and not storage.show_relic_disabled then
			-- Enable creep side icon and text and set the text timer
			self.creep_carrock_icon:SetVisible(true)
			self.creep_carrock_timer:SetVisible(true)
			self.creep_carrock_timer:SetText(text)

			-- Disable freep side icon and text
			self.freep_carrock_icon:SetVisible(false)
			self.freep_carrock_timer:SetVisible(false)
		elseif not storage.show_relic_disabled then
			-- Disable creep side icon and text
			self.creep_carrock_icon:SetVisible(false)
			self.creep_carrock_timer:SetVisible(false)

			-- Enable freep side icon and text and set the text timer
			self.freep_carrock_icon:SetVisible(true)
			self.freep_carrock_timer:SetVisible(true)
			self.freep_carrock_timer:SetText(text)
		else
			-- Disable creep side icon and text
			self.creep_carrock_icon:SetVisible(false)
			self.creep_carrock_timer:SetVisible(false)

			-- Disable freep side icon and text
			self.freep_carrock_icon:SetVisible(false)
			self.freep_carrock_timer:SetVisible(false)
		end
	elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_carrock_buff and not storage.show_relic_disabled then
			-- Enable freep side icon and text and set the text timer
			self.freep_carrock_icon:SetVisible(true)
			self.freep_carrock_timer:SetVisible(true)
			self.freep_carrock_timer:SetText(text)

			-- Disable creep side icon and text
			self.creep_carrock_icon:SetVisible(false)
			self.creep_carrock_timer:SetVisible(false)
		elseif not storage.show_relic_disabled then
			-- Disable freep side icon and text
			self.freep_carrock_icon:SetVisible(false)
			self.freep_carrock_timer:SetVisible(false)

			-- Enable creep side icon and text and set the text timer
			self.creep_carrock_icon:SetVisible(true)
			self.creep_carrock_timer:SetVisible(true)
			self.creep_carrock_timer:SetText(text)
		else
			-- Disable freep side icon and text
			self.freep_carrock_icon:SetVisible(false)
			self.freep_carrock_timer:SetVisible(false)

			-- Disable creep side icon and text
			self.creep_carrock_icon:SetVisible(false)
			self.creep_carrock_timer:SetVisible(false)
		end
	end

	-- Update Outnumbered timers
	outnumbered_buff_timer = outnumbered_buff_timer + 1
	minute_mod = math.fmod(outnumbered_buff_timer, 3600)
	minutes = (minute_mod - math.fmod(minute_mod, 60)) / 60
	hours = (outnumbered_buff_timer - math.fmod(outnumbered_buff_timer, 3600)) / 3600

	if minutes < 10 then
		text = hours .. ":0" .. minutes
	else
		text = hours .. ":" .. minutes
	end

	if Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_outnumbered_buff and not storage.show_on_disabled then
			-- Enable creep side icon and text and set the text timer
			self.creep_outnumbered_icon:SetVisible(true)
			self.creep_outnumbered_timer:SetVisible(true)
			self.creep_outnumbered_timer:SetText(text)

			-- Disable freep side icon and text
			self.freep_outnumbered_icon:SetVisible(false)
			self.freep_outnumbered_timer:SetVisible(false)
		else
			-- Disable creep side icon and text
			self.creep_outnumbered_icon:SetVisible(false)
			self.creep_outnumbered_timer:SetVisible(false)

			-- Disable freep side icon and text
			self.freep_outnumbered_icon:SetVisible(false)
			self.freep_outnumbered_timer:SetVisible(false)
		end
	elseif Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer then
		if own_outnumbered_buff and not storage.show_on_disabled then
			-- Enable freep side icon and text and set the text timer
			self.freep_outnumbered_icon:SetVisible(true)
			self.freep_outnumbered_timer:SetVisible(true)
			self.freep_outnumbered_timer:SetText(text)

			-- Disable creep side icon and text
			self.creep_outnumbered_icon:SetVisible(false)
			self.creep_outnumbered_timer:SetVisible(false)
		else
			-- Disable freep side icon and text
			self.freep_outnumbered_icon:SetVisible(false)
			self.freep_outnumbered_timer:SetVisible(false)

			-- Disable creep side icon and text
			self.creep_outnumbered_icon:SetVisible(false)
			self.creep_outnumbered_timer:SetVisible(false)
		end
	end

	-- Rank Progress
	if data.numbers.points_total == Ranks[#Ranks] then
		self.rank_icon:SetBackground(Rank_Icons[#Rank_Icons])
		self.label_rank:SetText(L.Stats_Rank .. #Ranks)
		self:UpdateProgressBar(1)
	else
		for i = 0, #Ranks - 1 do
			if (data.numbers.points_total >= Ranks[i] and data.numbers.points_total < Ranks[i + 1]) then
				local rank_difference = Ranks[i + 1] - Ranks[i]
				local points_since_rankup = data.numbers.points_total - Ranks[i]
				local percentage_done = points_since_rankup / rank_difference
				self.rank_icon:SetBackground(Rank_Icons[i])
				self.label_rank:SetText(L.Stats_Rank .. i)
				self:UpdateProgressBar(percentage_done)
				break
			end
		end
	end
end

function OverviewWindow:SetTreeOwner(owner)
	own_tree_buff = owner
end

function OverviewWindow:SetDrakeOwner(owner)
	own_drake_buff = owner
end

function OverviewWindow:SetGaryOwner(owner)
	own_gary_buff = owner
end

function OverviewWindow:SetCrownOwner(owner)
	own_crown_buff = owner
end

function OverviewWindow:SetCarrockOwner(owner)
	own_carrock_buff = owner
end

function OverviewWindow:SetOutnumberedOwner(owner)
	own_outnumbered_buff = owner
end

function OverviewWindow:IsTreeOwned()
	return own_tree_buff
end

function OverviewWindow:IsDrakeOwned()
	return own_drake_buff
end

function OverviewWindow:IsGaryOwned()
	return own_gary_buff
end

function OverviewWindow:IsCrownOwned()
	return own_crown_buff
end

function OverviewWindow:IsCarrockOwned()
	return own_carrock_buff
end

function OverviewWindow:IsOutnumberedOwned()
	return own_outnumbered_buff
end

function OverviewWindow:ResetTreeTimer()
	tree_buff_timer = 0
end

function OverviewWindow:ResetDrakeTimer()
	drake_buff_timer = 0
end

function OverviewWindow:ResetGaryTimer()
	gary_buff_timer = 0
end

function OverviewWindow:ResetCrownTimer()
	crown_buff_timer = 0
end

function OverviewWindow:ResetCarrockTimer()
	carrock_buff_timer = 0
end

function OverviewWindow:ResetOutnumberedTimer()
	outnumbered_buff_timer = 0
end

function OverviewWindow:UpdateProgressBar(percentage_done)
	self.bar_percentage:SetText(math.floor(percentage_done * 10000) / 100 .. "%") -- Sets amount of decimals towards rank
	local filled_pixels = math.floor(self.bar_length * percentage_done)
	self.filled_bar:SetWidth(filled_pixels)
end

function OverviewWindow:UpdatePosition()
	local old_width = self:GetWidth()
	local new_width = math.floor(Minimal_Width + (Turbine.UI.Display.GetWidth() - Minimal_Width) * data.numbers.overview_width_ratio)

	if new_width / 2 ~= math.floor((new_width + 1) / 2) then
		new_width = new_width + 1
	end

	data.numbers.overview_x = data.numbers.overview_x - (new_width - old_width) / 2
	if data.numbers.overview_x < 0 then data.numbers.overview_x = 0 end

	if data.numbers.overview_x + new_width > Turbine.UI.Display.GetWidth() then
		data.numbers.overview_x = Turbine.UI.Display.GetWidth() - new_width
	end

	self:SetWidth(new_width)
	self:SetPosition(data.numbers.overview_x,data.numbers.overview_y)
	self:UpdateBarLength()
	self.panel:SetWidth(new_width)
	self.separator:SetWidth(new_width)
	self.commendations_panel:SetPosition(self:GetWidth() - 54, 18)
	self.points_footer:SetWidth(new_width)
	self.commendations_footer:SetWidth(new_width)
	self.frags_footer:SetWidth(new_width)
	self.label_points:SetSize(new_width - 108, 20)

	self.label_month:SetSize(new_width / 5, 35)
	self.label_day:SetSize(new_width / 5, 35)
	self.label_day:SetPosition(new_width / 5, 3)
	self.label_last_hour:SetSize(new_width / 5, 35)
	self.label_last_hour:SetPosition(2 * new_width / 5, 3)
	self.label_10min:SetSize(new_width / 5, 35)
	self.label_10min:SetPosition(3 * new_width / 5, 3)
	self.label_last_fight:SetSize(new_width / 5, 35)
	self.label_last_fight:SetPosition(4 * new_width / 5, 3)

	self.label_month_comms:SetSize(new_width / 5, 35)
	self.label_day_comms:SetSize(new_width / 5, 35)
	self.label_day_comms:SetPosition(new_width / 5, 3)
	self.label_last_hour_comms:SetSize(new_width / 5, 35)
	self.label_last_hour_comms:SetPosition(2 * new_width / 5, 3)
	self.label_10min_comms:SetSize(new_width / 5, 35)
	self.label_10min_comms:SetPosition(3 * new_width / 5, 3)
	self.label_last_fight_comms:SetSize(new_width / 5, 35)
	self.label_last_fight_comms:SetPosition(4 * new_width / 5, 3)

	self.label_month_frags:SetSize(new_width / 5, 35)
	self.label_day_frags:SetSize(new_width / 5, 35)
	self.label_day_frags:SetPosition(new_width / 5, 3)
	self.label_last_hour_frags:SetSize(new_width / 5, 35)
	self.label_last_hour_frags:SetPosition(2 * new_width / 5, 3)
	self.label_10min_frags:SetSize(new_width / 5, 35)
	self.label_10min_frags:SetPosition(3 * new_width / 5, 3)
	self.label_last_fight_frags:SetSize(new_width / 5, 35)
	self.label_last_fight_frags:SetPosition(4 * new_width / 5, 3)

	self.bonus_panel:SetPosition(new_width / 2 - self.bonus_panel:GetSize() / 2, 0)
	OverviewSettingsPanel:SetPosition(self:GetLeft() + new_width - OverviewSettingsPanel:GetWidth(), self:GetTop())

	-- Update Keep positions
	self.freep_keep_1:SetPosition(self.bonus_panel:GetLeft() - 30, 0)
	self.freep_keep_1_text:SetPosition(self.bonus_panel:GetLeft() - 30, 2)
	self.freep_keep_2:SetPosition(self.freep_keep_1:GetLeft() - 26, 0)
	self.freep_keep_2_text:SetPosition(self.freep_keep_1_text:GetLeft() - 26, 2)
	self.freep_keep_3:SetPosition(self.freep_keep_2:GetLeft() - 26, 0)
	self.freep_keep_3_text:SetPosition(self.freep_keep_2_text:GetLeft() - 26, 2)
	self.freep_keep_4:SetPosition(self.freep_keep_3:GetLeft() - 26, 0)
	self.freep_keep_4_text:SetPosition(self.freep_keep_3_text:GetLeft() - 26, 2)
	self.freep_keep_5:SetPosition(self.freep_keep_4:GetLeft() - 26, 0)
	self.freep_keep_5_text:SetPosition(self.freep_keep_4_text:GetLeft() - 26, 2)

	self.creep_keep_1:SetPosition(self.bonus_panel:GetLeft() + self.bonus_panel:GetSize() + 6, 0)
	self.creep_keep_1_text:SetPosition(self.bonus_panel:GetLeft() + self.bonus_panel:GetSize() + 6, 2)
	self.creep_keep_2:SetPosition(self.creep_keep_1:GetLeft() + 26, 0)
	self.creep_keep_2_text:SetPosition(self.creep_keep_1_text:GetLeft() + 26, 2)
	self.creep_keep_3:SetPosition(self.creep_keep_2:GetLeft() + 26, 0)
	self.creep_keep_3_text:SetPosition(self.creep_keep_2_text:GetLeft() + 26, 2)
	self.creep_keep_4:SetPosition(self.creep_keep_3:GetLeft() + 26, 0)
	self.creep_keep_4_text:SetPosition(self.creep_keep_3_text:GetLeft() + 26, 2)
	self.creep_keep_5:SetPosition(self.creep_keep_4:GetLeft() + 26, 0)
	self.creep_keep_5_text:SetPosition(self.creep_keep_4_text:GetLeft() + 26, 2)

	-- Update DOF positions
	self.freep_tree_icon:SetPosition(self.freep_keep_5:GetLeft() - 27, 0)
	self.freep_tree_timer:SetPosition(self.freep_keep_5:GetLeft() - 35, 13)
	self.freep_gary_icon:SetPosition(self.freep_tree_icon:GetLeft() - 28, 0)
	self.freep_gary_timer:SetPosition(self.freep_tree_timer:GetLeft() - 28, 13)
	self.freep_drake_icon:SetPosition(self.freep_gary_icon:GetLeft() - 28, 0)
	self.freep_drake_timer:SetPosition(self.freep_gary_timer:GetLeft() - 28, 13)

	self.creep_tree_icon:SetPosition(self.creep_keep_5:GetLeft() + 36, 0)
	self.creep_tree_timer:SetPosition(self.creep_keep_5:GetLeft() + 28, 13)
	self.creep_gary_icon:SetPosition(self.creep_tree_icon:GetLeft() + 28, 0)
	self.creep_gary_timer:SetPosition(self.creep_tree_timer:GetLeft() + 28, 13)
	self.creep_drake_icon:SetPosition(self.creep_gary_icon:GetLeft() + 28, 0)
	self.creep_drake_timer:SetPosition(self.creep_gary_timer:GetLeft() + 28, 13)

	--Update Relic positions
	self.freep_carrock_icon:SetPosition(self.freep_drake_icon:GetLeft() - 35, 0)
	self.freep_carrock_timer:SetPosition(self.freep_drake_timer:GetLeft() - 35, 13)
	self.freep_crown_icon:SetPosition(self.freep_carrock_icon:GetLeft() - 28, 0)
	self.freep_crown_timer:SetPosition(self.freep_carrock_timer:GetLeft() - 28, 13)

	self.creep_crown_icon:SetPosition(self.creep_drake_icon:GetLeft() + 35, 0)
	self.creep_crown_timer:SetPosition(self.creep_drake_timer:GetLeft() + 35, 13)
	self.creep_carrock_icon:SetPosition(self.creep_crown_icon:GetLeft() + 28, 0)
	self.creep_carrock_timer:SetPosition(self.creep_crown_timer:GetLeft() + 28, 13)

	--Update Outnumbered positions
	self.freep_outnumbered_icon:SetPosition(self.freep_crown_icon:GetLeft() - 35, 0)
	self.freep_outnumbered_timer:SetPosition(self.freep_crown_timer:GetLeft() - 35, 13)

	self.creep_outnumbered_icon:SetPosition(self.creep_carrock_icon:GetLeft() + 35, 0)
	self.creep_outnumbered_timer:SetPosition(self.creep_carrock_timer:GetLeft() + 35, 13)

	self:Update()
end

function OverviewWindow:UpdateBarLength()
	self.bar_start	= 50
	self.bar_end	= self:GetWidth() - self.bar_start
	self.bar_length	= self.bar_end - self.bar_start

	self.empty_bar:SetWidth(self.bar_length)
	self.bar_middle:SetWidth(self.bar_length - 6)
	self.bar_right_end:SetPosition(self.bar_end - 3, 25)
	self.bar_percentage:SetWidth(self:GetWidth())
end

function OverviewWindow:SetStatsVisibility(bool)
	self.separator:SetVisible(bool)
	self.points_footer:SetVisible(bool)
end