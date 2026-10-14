DragBar = class(Turbine.UI.Control)

function DragBar:Constructor(parent, text)
	local parent_width = parent:GetWidth()
	local parent_height = parent:GetHeight()

	Turbine.UI.Control.Constructor(self)

	self:SetParent(parent)

	self:SetSize(parent_width, parent_height)
	self:SetWantsKeyEvents(true)
	self:SetMouseVisible(false)
	self:SetZOrder(1)

	self.move_panel = Turbine.UI.Control()
	self.move_panel:SetParent(self)
	self.move_panel:SetSize(2000, 20)
	self.move_panel:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/dragbar.tga")

	self.move_text = Turbine.UI.Label()
	self.move_text:SetParent(self.move_panel)
	self.move_text:SetSize(parent_width, 12)
	self.move_text:SetTop(4)
	self.move_text:SetFont(Turbine.UI.Lotro.Font.Verdana12)
	self.move_text:SetText(text)
	self.move_text:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.move_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.move_text:SetMouseVisible(false)

	self.shadow_box = Turbine.UI.Control()
	self.shadow_box:SetParent(self)
	self.shadow_box:SetTop(20)
	self.shadow_box:SetSize(parent_width, parent_height)
	self.shadow_box:SetMouseVisible(false)
	self.shadow_box:SetVisible(false)

	self.shadow_box.top_left = Turbine.UI.Control()
	self.shadow_box.top_left:SetParent(self.shadow_box)
	self.shadow_box.top_left:SetSize(10, 10)
	self.shadow_box.top_left:SetMouseVisible(false)
	self.shadow_box.top_left:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_topleft.tga")
	self.shadow_box.top_left:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.top_right = Turbine.UI.Control()
	self.shadow_box.top_right:SetParent(self.shadow_box)
	self.shadow_box.top_right:SetSize(10, 10)
	self.shadow_box.top_right:SetMouseVisible(false)
	self.shadow_box.top_right:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_topright.tga")
	self.shadow_box.top_right:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.bottom_left = Turbine.UI.Control()
	self.shadow_box.bottom_left:SetParent(self.shadow_box)
	self.shadow_box.bottom_left:SetSize(10, 10)
	self.shadow_box.bottom_left:SetMouseVisible(false)
	self.shadow_box.bottom_left:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_bottomleft.tga")
	self.shadow_box.bottom_left:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.bottom_right = Turbine.UI.Control()
	self.shadow_box.bottom_right:SetParent(self.shadow_box)
	self.shadow_box.bottom_right:SetSize(10, 10)
	self.shadow_box.bottom_right:SetMouseVisible(false)
	self.shadow_box.bottom_right:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_bottomright.tga")
	self.shadow_box.bottom_right:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.top = Turbine.UI.Control()
	self.shadow_box.top:SetParent(self.shadow_box)
	self.shadow_box.top:SetSize(0, 10)
	self.shadow_box.top:SetMouseVisible(false)
	self.shadow_box.top:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_topmid.tga")
	self.shadow_box.top:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.left = Turbine.UI.Control()
	self.shadow_box.left:SetParent(self.shadow_box)
	self.shadow_box.left:SetSize(10, 0)
	self.shadow_box.left:SetMouseVisible(false)
	self.shadow_box.left:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_midleft.tga")
	self.shadow_box.left:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.right = Turbine.UI.Control()
	self.shadow_box.right:SetParent(self.shadow_box)
	self.shadow_box.right:SetSize(10, 0)
	self.shadow_box.right:SetMouseVisible(false)
	self.shadow_box.right:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_midright.tga")
	self.shadow_box.right:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.bottom = Turbine.UI.Control()
	self.shadow_box.bottom:SetParent(self.shadow_box)
	self.shadow_box.bottom:SetSize(0, 10)
	self.shadow_box.bottom:SetMouseVisible(false)
	self.shadow_box.bottom:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/drag_bottommid.tga")
	self.shadow_box.bottom:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)

	self.shadow_box.SizeChanged = function(sender, args)
		local width, height = sender:GetSize()
		self.shadow_box.top:SetPosition(10, 0)
		self.shadow_box.top_right:SetPosition(width - 10, 0)
		self.shadow_box.bottom_left:SetPosition(0, height - 30)
		self.shadow_box.bottom:SetPosition(10, height - 30)
		self.shadow_box.bottom_right:SetPosition(width - 10, height - 30)
		self.shadow_box.left:SetPosition(0, 10)
		self.shadow_box.right:SetPosition(width - 10, 10)
		self.shadow_box.top:SetWidth(width - 20)
		self.shadow_box.bottom:SetWidth(width - 20)
		self.shadow_box.left:SetHeight(height - 40)
		self.shadow_box.right:SetHeight(height - 40)
	end

	self:SetVisible(false)
	self.moving = false

	self.move_panel.MouseDown = function(sender, args)
		self.MoveX = args.X
		self.MoveY = args.Y
		self.moving = true
		self.move_panel:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/dragbar_clicked.tga")
	end

	self.move_panel.MouseUp = function()
		self.moving = false
		self.move_panel:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/DragBar/dragbar.tga")
	end

	self.move_panel.MouseMove = function(sender, args)
		if self.moving then
			local new_left = parent:GetLeft() - (self.MoveX - args.X)
			local new_top = parent:GetTop() - (self.MoveY - args.Y)
			if new_left < 0 then
				new_left = 0
			end
			if new_top < 0 then
				new_top = 0
			end
			if new_left > (Turbine.UI.Display.GetWidth() - parent:GetWidth()) then
				new_left = Turbine.UI.Display.GetWidth() - parent:GetWidth()
			end
			if new_top > (Turbine.UI.Display.GetHeight() - parent:GetHeight()) then
				new_top = Turbine.UI.Display.GetHeight() - parent:GetHeight()
			end
			parent:SetPosition(new_left, new_top)
		end
	end

	self.move_panel.MouseEnter = function()
		self.shadow_box:SetVisible(true)
	end

	self.move_panel.MouseLeave = function()
		self.shadow_box:SetVisible(false)
	end

	self.KeyDown = function(sender, args)
		if args.Action == Turbine.UI.Lotro.Action.ToggleHiddenDragBoxes then
			self:SetVisible(not self:IsVisible())
		end
	end

	parent.SizeChanged = function(sender, args)
		self:SetSize(sender:GetSize())
		self.shadow_box:SetSize(sender:GetSize())
		self.move_text:SetWidth(sender:GetWidth())
	end

	self.shadow_box:SizeChanged()
end