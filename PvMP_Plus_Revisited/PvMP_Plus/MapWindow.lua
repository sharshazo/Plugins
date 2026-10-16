MapWindow = class(Turbine.UI.Window)

function MapWindow:Constructor()
	local width = 1024
	local height = (768 + 20)

	self.min_s = 10
	self.max_s = 22
	self.dif_s = self.max_s - self.min_s
	self.min_w = 8.2
	self.max_w = 24.3
	self.dif_w = self.max_w - self.min_w
	self.heading = 0

	Turbine.UI.Window.Constructor(self)

	self:SetSize(width, height)
	self:SetPosition(data.numbers.mapWin_x, data.numbers.mapWin_y)
	self:SetZOrder(1)
	self:SetWantsKeyEvents(true)
	self:SetMouseVisible(false)

	self.DragBar = DragBar(self, L.DragBar_Map)

	self.map = Turbine.UI.Control()
	self.map:SetParent(self)
	self.map:SetSize(1024, 768)
	self.map:SetBackground(0x41008133)
	self.map:SetStretchMode(1)
	self.map:SetSize(self:GetWidth(), self:GetHeight() - 16)
	self.map:SetTop(20)
	self.map:SetMouseVisible(false)

	self.map_position_arrow = Turbine.UI.Window()
	self.map_position_arrow:SetParent(self.map)
	self.map_position_arrow:SetSize(28, 28)
	self.map_position_arrow:SetBackground(0x41007f4c)
	self.map_position_arrow:SetZOrder(1)
	self.map_position_arrow:SetMouseVisible(false)

	self.map_position_container = Turbine.UI.Control()
	self.map_position_container:SetParent(self)
	self.map_position_container:SetStretchMode(3)
	self.map_position_container:SetSize(155, 31)
	self.map_position_container:SetPosition(
		self:GetWidth() - self.map_position_container:GetWidth() - 50,
		self:GetHeight() - self.map_position_container:GetHeight() - 30
	)

	self.show_own_position_quickslot = Turbine.UI.Lotro.Quickslot()
	self.show_own_position_quickslot:SetParent(self.map_position_container)
	self.show_own_position_quickslot:SetSize(self.map_position_container:GetSize())
	self.show_own_position_quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, L.Loc_Command))
	self.show_own_position_quickslot:SetAllowDrop(false)

	self.show_own_position_overlay = Turbine.UI.Label()
	self.show_own_position_overlay:SetParent(self.map_position_container)
	self.show_own_position_overlay:SetSize(self.map_position_container:GetSize())
	self.show_own_position_overlay:SetForeColor(Default_Font_Color)
	self.show_own_position_overlay:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.show_own_position_overlay:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.show_own_position_overlay:SetBackground(0x4110932c)
	self.show_own_position_overlay:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.show_own_position_overlay:SetText(L.Get_Own_Position)
	self.show_own_position_overlay:SetMouseVisible(false)

	self.keep_list = {}
	self.hotspot_list = {}
	self.port_list = {}
	self.enemy_position_list = {}

	local keep_positions = {
		[1] = { ["s"] = 16.6, ["w"] = 17.3 },	-- Tol Ascarnen
		[2] = { ["s"] = 11.7, ["w"] = 15.3 },	-- Isendeep Mine
		[3] = { ["s"] = 17.6, ["w"] = 14.5 },	-- Tirith Rhaw
		[4] = { ["s"] = 15.3, ["w"] = 20.0 },	-- Lugazag
		[5] = { ["s"] = 19.3, ["w"] = 17.5 },	-- Grimwood Lumber Camp
		[6] = { ["s"] = 19.9, ["w"] = 19.3 },	-- Hithlad Outpost
		[7] = { ["s"] = 13.4, ["w"] = 14.6 },	-- Arador's End Outpost
		[8] = { ["s"] = 18.4, ["w"] = 20.1 },	-- River Outpost
		[9] = { ["s"] = 14.5, ["w"] = 16.2 },	-- Isendeep Outpost
		[10] = { ["s"] = 15.9, ["w"] = 15.3 },	-- Forward Camp - Tirith Rhaw
		[11] = { ["s"] = 17.0, ["w"] = 19.8 },	-- Forward Camp - Lugazag
	}

	for index, position in pairs(keep_positions) do
		self.keep_list[index] = Turbine.UI.Control()
		self.keep_list[index]:SetParent(self.map)
		self.keep_list[index]:SetSize(32, 32)
		self.keep_list[index]:SetStretchMode(1)
		self.keep_list[index]:SetPosition(
			(self.map:GetWidth() - self.map:GetWidth() * (position.w - self.min_w) / self.dif_w - self.keep_list[index]:GetWidth() / 2),
			(self.map:GetHeight() * (position.s - self.min_s) / self.dif_s - self.keep_list[index]:GetHeight() / 2)
		)
		self.keep_list[index]:SetMouseVisible(false)
	end

	local hotspot_positions = {
		[1] = { ["s"] = 12.2, ["w"] = 20.9 },	-- Gramsfoot
		[2] = { ["s"] = 20.7, ["w"] = 13.6 },	-- Glân Vraig
		[3] = { ["s"] = 17.0, ["w"] = 22.4 },	-- Dâr-gazag
		[4] = { ["s"] = 17.8, ["w"] = 16.0 },	-- Elf Camp
		[5] = { ["s"] = 19.8, ["w"] = 20.0 },	-- Hoarhallow
		[6] = { ["s"] = 13.0, ["w"] = 12.7 },	-- Grothum
		[7] = { ["s"] = 17.0, ["w"] = 18.6 },	-- Orc Camp
		[8] = { ["s"] = 16.0, ["w"] = 12.2 }	-- Ost Ringdyr
	}

	for index, position in pairs(hotspot_positions) do
		self.hotspot_list[index] = Turbine.UI.Control()
		self.hotspot_list[index]:SetParent(self.map)
		self.hotspot_list[index]:SetSize(30, 30)
		self.hotspot_list[index]:SetStretchMode(1)
		self.hotspot_list[index]:SetPosition(
			(self.map:GetWidth() - self.map:GetWidth() * (position.w - self.min_w) / self.dif_w - self.hotspot_list[index]:GetWidth() / 2),
			(self.map:GetHeight() * (position.s - self.min_s) / self.dif_s - self.hotspot_list[index]:GetHeight() / 2)
		)
		self.hotspot_list[index]:SetMouseVisible(false)
	end

	local creep_port_positions = {
		[1] = { ["skill"] = 0x70028BBC, ["s"] = 12.35, ["w"] = 20.89 },		-- Gramsfoot
		[2] = { ["skill"] = 0x70028BB7, ["s"] = 16.12, ["w"] = 20.93 },		-- Crude Lugazag
		[3] = { ["skill"] = 0x70028BB6, ["s"] = 17.09, ["w"] = 18.63 },		-- Crude Tol Ascarnen
		[4] = { ["skill"] = 0x70028BBE, ["s"] = 14.63, ["w"] = 15.78 },		-- Crude Tirith Rhaw
		[5] = { ["skill"] = 0x70028BB3, ["s"] = 13.39, ["w"] = 12.79 },		-- Crude Isendeep Mine
		[6] = { ["skill"] = 0x70028BBF, ["s"] = 18.34, ["w"] = 18.55 },		-- Crude Grimwood Lumber Camp
		[7] = { ["skill"] = 0x70028BB2, ["s"] = 14.15, ["w"] = 20.96 },		-- Poor Lugazag
		[8] = { ["skill"] = 0x70028BB1, ["s"] = 15.96, ["w"] = 17.04 },		-- Poor Tol Ascarnen
		[9] = { ["skill"] = 0x70028BB4, ["s"] = 15.70, ["w"] = 14.22 },		-- Poor Tirith Rhaw
		[10] = { ["skill"] = 0x70028BAF, ["s"] = 14.69, ["w"] = 14.51 },	-- Poor Isendeep Mine
		[11] = { ["skill"] = 0x70028BB9, ["s"] = 18.85, ["w"] = 17.95 },	-- Poor Grimwood Lumber Camp
		[12] = { ["skill"] = 0x70028BB5, ["s"] = 14.54, ["w"] = 19.07 },	-- Good Lugazag
		[13] = { ["skill"] = 0x70028BC2, ["s"] = 17.93, ["w"] = 18.12 },	-- Good Tol Ascarnen
		[14] = { ["skill"] = 0x70028BB0, ["s"] = 17.85, ["w"] = 15.33 },	-- Good Tirith Rhaw
		[15] = { ["skill"] = 0x70028BC0, ["s"] = 11.52, ["w"] = 19.10 },	-- Good Isendeep Mine
		[16] = { ["skill"] = 0x70028BBD, ["s"] = 20.35, ["w"] = 16.83 }		-- Good Grimwood Lumber Camp
	}

	local troll_port_positions = {
		[1] = { ["skill"] = 0x7002A7B9, ["s"] = 12.35, ["w"] = 20.89 },		-- Gramsfoot
		[2] = { ["skill"] = 0x7002A7B6, ["s"] = 14.54, ["w"] = 19.07 },		-- Good Lugazag
		[3] = { ["skill"] = 0x7002A7B4, ["s"] = 17.93, ["w"] = 18.12 },		-- Good Tol Ascarnen
		[4] = { ["skill"] = 0x7002A7B5, ["s"] = 17.85, ["w"] = 15.33 },		-- Good Tirith Rhaw
		[5] = { ["skill"] = 0x7002A7B7, ["s"] = 11.52, ["w"] = 19.10 },		-- Good Isendeep Mine
		[6] = { ["skill"] = 0x7002A7B3, ["s"] = 20.35, ["w"] = 16.83 }		-- Good Grimwood Lumber Camp
	}

	local freep_port_positions = {
		[1] = { ["skill"] = 0x7005B38E, ["s"] = 20.77, ["w"] = 13.38 }		-- Glân Vraig
	}

	local ranger_port_positions = {
		[1] = { ["skill"] = 0x7002A7B8, ["s"] = 20.77, ["w"] = 13.38 },		-- Glân Vraig
		[2] = { ["skill"] = 0x7002A7B6, ["s"] = 14.54, ["w"] = 19.07 },		-- Good Lugazag
		[3] = { ["skill"] = 0x7002A7B4, ["s"] = 17.93, ["w"] = 18.12 },		-- Good Tol Ascarnen
		[4] = { ["skill"] = 0x7002A7B5, ["s"] = 17.85, ["w"] = 15.33 },		-- Good Tirith Rhaw
		[5] = { ["skill"] = 0x7002A7B7, ["s"] = 11.52, ["w"] = 19.10 },		-- Good Isendeep Mine
		[6] = { ["skill"] = 0x7002A7B3, ["s"] = 20.35, ["w"] = 16.83 }		-- Good Grimwood Lumber Camp
	}

	if (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() == Turbine.Gameplay.Alignment.MonsterPlayer) then
		for index, map in pairs(creep_port_positions) do
			self:AddMapQuickslots(index, map)
		end
	elseif (Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() ~= Turbine.Gameplay.Alignment.MonsterPlayer) then
		if (Turbine.Gameplay.LocalPlayer:GetInstance():GetClass() == 190) then
			for index, map in pairs(troll_port_positions) do
				self:AddMapQuickslots(index, map)
			end
		elseif (Turbine.Gameplay.LocalPlayer:GetInstance():GetClass() == 191) then
			for index, map in pairs(ranger_port_positions) do
				self:AddMapQuickslots(index, map)
			end
		elseif (Turbine.Gameplay.LocalPlayer:GetInstance():GetClass() == 192) then
			return
		else
			for index, map in pairs(freep_port_positions) do
				self:AddMapQuickslots(index, map)
			end
		end
	end

	self.KeyDown = function(sender, args)
		if args.Action == Turbine.UI.Lotro.Action.Escape then
			self:SetVisible(false)
			SecondaryWindow.map_button:SetText(L.Map_Show)
		end
	end

	self.VisibleChanged = function(sender)
		if self:IsVisible() then
			self:ResizeIcons()
		end
	end

	self.PositionChanged = function(sender, args)
		data.numbers.mapWin_x = self:GetLeft()
		data.numbers.mapWin_y = self:GetTop()
	end
end

function MapWindow:UpdateKeepsOnMap()
	for index, keep in pairs(self.keep_list) do
		keep:SetBackground(Enemy_Keep_Icon)
	end
	for i = 1, Buff_List:GetCount() do
		local element = Buff_List:Get(i):GetName()
		if SetContains(Towers, element) then
			self.keep_list[Towers[element]]:SetBackground(Aligned_Keep_Icon)
		end
	end
	for index, hotspot in pairs(self.hotspot_list) do
		hotspot:SetBackground(0x41005e5e)
	end
end

function MapWindow:ResizeIcons()
	for player, control in pairs(MapWindow.enemy_position_list) do
		control:SetSize(control:GetWidth() + 2, control:GetHeight() + 2)
	end
	for index, keep in pairs(self.keep_list) do
		keep:SetSize(34, 34)
	end
	for index, hotspot in pairs(self.hotspot_list) do
		hotspot:SetSize(32, 32)
	end
	for index, port in pairs(self.port_list) do
		port:SetSize(port:GetWidth() + 2, port:GetHeight() + 3)
	end
	self.map_position_arrow:SetSize(28, 28)
	self.map_position_arrow:SetVisible(true)
	self.map_position_arrow:SetRotation({ x = 0, y = 0, z = 0 - (self.heading - 90) })
	self.map_position_arrow:SetVisible(Current_Position_Counter ~= 0)
end

function MapWindow:AddMapQuickslots(index, map)
	self.port_list[index] = Turbine.UI.Control()
	self.port_list[index]:SetParent(self.map)

	local port_quickslot = Turbine.UI.Lotro.Quickslot()
	port_quickslot:SetParent(self.port_list[index])
	port_quickslot:SetSize(self.port_list[index]:GetSize())
	port_quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Skill, string.format("0x%x", map.skill)))
	port_quickslot:SetAllowDrop(false)

		self.port_list[index]:SetSize(35, 35)
		self.port_list[index]:SetStretchMode(1)
		self.port_list[index]:SetPosition(
			(self.map:GetWidth() - self.map:GetWidth() * (map.w - self.min_w) / self.dif_w - self.port_list[index]:GetWidth() / 2),
			(self.map:GetHeight() * (map.s - self.min_s) / self.dif_s - self.port_list[index]:GetHeight() / 2)
		)

	port_quickslot.MouseUp = function(sender, args)
		if args.Button == Turbine.UI.MouseButton.Left or args.Button == Turbine.UI.MouseButton.Right then
			self:SetVisible(false)
			SecondaryWindow.map_button:SetText(L.Map_Show)
		end
	end
end

function MapWindow:MoveCurrentPosition(west, south, heading)
	self.heading = heading
	if self:IsVisible() then
		self.map_position_arrow:SetVisible(true)
		self.map_position_arrow:SetRotation({ x = 0, y = 0, z = 0 - (self.heading - 90) })
	end
	self.map_position_arrow:SetPosition(
		self.map:GetWidth() - self.map:GetWidth() * (west - self.min_w) / self.dif_w - self.map_position_arrow:GetWidth() / 2,
		self.map:GetHeight() * (south - self.min_s) / self.dif_s - self.map_position_arrow:GetHeight() / 2
	)
	Current_Position_Counter = 20 -- In seconds how long icon is shown
end

-- v4.3.15: varias llamadas a la vez. Cada jugador puede tener varias marcas
-- (una por sitio); si vuelve a avisar cerca de una marca suya, esa se mueve.
-- Las marcas apagadas se reutilizan y hay un maximo a la vista.
local ENEMY_MARKS_MAX = 12
local ENEMY_MARK_NEAR = 0.6	-- en unidades del mapa (S/W)

function MapWindow:AddEnemyPosition(w, s, amount, player)
	-- v4.3.10: si no se dijo cuantos enemigos, solo el nombre de quien avisa
	player = player or "?"
	local map_callout = player
	if amount ~= nil and amount ~= "" and amount ~= "?" then
		map_callout = player .. ": " .. amount .. " " .. (amount == "1" and L.FreepCreep or L.FreepsCreeps)
	end

	local list = self.enemy_position_list
	local mark, spare, oldest
	local active = 0
	for key, control in pairs(list) do
		local alive = (control.Timer or 0) > 0 and control:IsVisible()
		if alive then
			active = active + 1
			if oldest == nil or control.Timer < oldest.Timer then
				oldest = control
			end
			if mark == nil and (control.Player or key) == player and control.S ~= nil and
				math.abs(control.S - s) <= ENEMY_MARK_NEAR and math.abs(control.W - w) <= ENEMY_MARK_NEAR then
				mark = control
			end
		elseif spare == nil then
			spare = control
		end
	end
	if mark == nil then
		mark = spare
	end
	if mark == nil and active >= ENEMY_MARKS_MAX then
		mark = oldest
	end
	if mark == nil then
		mark = Turbine.UI.Label()
		mark:SetParent(self.map)
		mark:SetSize(151, 29)
		mark:SetStretchMode(1)
		mark:SetSize(153, 31)
		mark:SetFont(Turbine.UI.Lotro.Font.Arial12)
		mark:SetForeColor(Turbine.UI.Color.Black)
		mark:SetFontStyle(Turbine.UI.FontStyle.Outline)
		mark:SetOutlineColor(Turbine.UI.Color.White)
		mark:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
		mark:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/MapIcons/enemy_position_overlay.tga")
		mark:SetMouseVisible(false)
		local key = player
		local n = 1
		while list[key] ~= nil do
			n = n + 1
			key = player .. "#" .. n
		end
		list[key] = mark
	end

	mark.Player = player
	mark.S, mark.W = s, w
	local x = self.map:GetWidth() - self.map:GetWidth() * (w - self.min_w) / self.dif_w - math.ceil(mark:GetWidth() / 2)
	local y = self.map:GetHeight() * (s - self.min_s) / self.dif_s - (mark:GetHeight() - 9)
	-- si otra marca ya esta en el mismo sitio, esta se pone un poco mas arriba
	for _ = 1, 6 do
		local taken = false
		for _, control in pairs(list) do
			if control ~= mark and (control.Timer or 0) > 0 and control:IsVisible() and
				math.abs(control:GetLeft() - x) < 40 and math.abs(control:GetTop() - y) < 12 then
				taken = true
				break
			end
		end
		if not taken then
			break
		end
		y = y - 14
	end
	mark:SetPosition(x, y)
	mark.Timer = Enemy_Position_Counter
	mark.Callout = map_callout	-- v4.3.14: para la cuenta atras
	mark:SetText(map_callout)
	mark:SetVisible(true)
end