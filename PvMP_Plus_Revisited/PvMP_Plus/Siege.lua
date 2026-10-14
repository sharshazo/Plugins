-- v4.3.6: Asedios.  v4.3.7: boton Help!, mensajes siempre en ingles por /ooc.
-- v4.3.8: fortalezas con castillo, puestos avanzados con diamante pequeno y
--         llamas tambien en los puestos (botones H R A I en la ventana).
-- Ventana pequena con un boton por fortaleza. Al hacer clic se envia al chat
-- (canal elegible) un aviso: "[Asedio TA] Estan tomando Tol Ascarnen!".
-- Todo jugador con PvMP+ que lea ese aviso (tambien quien lo envia) ve
-- arder el icono de esa fortaleza en la barra principal, hasta que el
-- plugin detecta que la fortaleza cambio de bando (o pasan 20 minutos).
-- Clic derecho en un boton: quita las llamas de esa fortaleza (solo para ti).
-- Help!: envia tu posicion (;loc) por /ooc; quien tenga PvMP+ ve un aviso
-- que puede pulsar para abrir el mapa con una marca azul en esa posicion.
-- (LOTRO no permite que un plugin haga clicable el texto del chat.)
-- /pvmp+ asedios : mostrar u ocultar la ventana.

local DIR = "PvMP_Plus_Revisited/PvMP_Plus/Resources/Siege/"
local TAG = "#FF7A1A"                 -- color que marca los avisos de asedio
local HELP_TAG = "#3CB4FF"            -- color que marca los pedidos de ayuda
local HELP_TIME = 90                  -- segundos que dura la marca en el mapa
local FIRE_FRAMES, FPS = 8, 12.5
local TIMEOUT = 1200                  -- 20 minutos sin cambio = se apaga
local W, H = 300, 185
local BTN, GAP, BX, BY = 46, 4, 25, 44
local OBTN, OGAP, OBX, OBY = 34, 4, 25, 104    -- botones de puestos avanzados
local HX, HY, HW, HH = 178, 100, 104, 44
local RES = "PvMP_Plus_Revisited/PvMP_Plus/Resources/"
local OUTPOST_ORDER = { "H", "R", "A", "I" }

_G.PvMP_Siege = { active = {}, overlays = {}, helps = {}, outslots = {} }
local S = PvMP_Siege
local TickHelps
local UpdateOutpostSides

local function Color(hex)
	hex = hex:gsub("#", "")
	return Turbine.UI.Color(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255)
end

local function Now()
	return Turbine.Engine.GetGameTime()
end

local function Alert(text, color)
	if AlertWindow ~= nil and AlertWindow.NewAlert ~= nil then
		pcall(AlertWindow.NewAlert, AlertWindow, text, color, 5)
	end
end

local function NameByAcronym(acr)
	for name, a in pairs(Keep_Acronyms) do
		if a == acr then
			return name
		end
	end
	if Outpost_Acronyms ~= nil then
		for name, a in pairs(Outpost_Acronyms) do
			if a == acr then
				return name
			end
		end
	end
	return nil
end

local function IsOutpost(name)
	return Outpost_Acronyms ~= nil and Outpost_Acronyms[name] ~= nil
end

local function Acronym(name)
	return Keep_Acronyms[name] or (Outpost_Acronyms ~= nil and Outpost_Acronyms[name]) or "?"
end

local function MySide()
	local ok, al = pcall(function() return Turbine.Gameplay.LocalPlayer.GetInstance():GetAlignment() end)
	if ok and al == Turbine.Gameplay.Alignment.MonsterPlayer then
		return "creep"
	end
	return "freep"
end

-- dueno de un puesto avanzado: lo tiene tu bando si tienes su bonificacion
local function OutpostSide(name)
	if Buff_List == nil then
		return nil
	end
	local owned = false
	for i = 1, Buff_List:GetCount() do
		local e = Buff_List:Get(i)
		if e ~= nil and e:GetName() == name then
			owned = true
			break
		end
	end
	local mine = MySide()
	if owned then
		return mine
	end
	return (mine == "freep") and "creep" or "freep"
end

-- bando que muestra hoy esa fortaleza en la barra ("freep"/"creep") y su hueco
local function KeepSide(name)
	if IsOutpost(name) then
		return OutpostSide(name)
	end
	local acr = Keep_Acronyms[name]
	local ov = OverviewWindow
	if acr == nil or ov == nil then
		return nil
	end
	for i = 1, 5 do
		for _, side in ipairs({ "freep", "creep" }) do
			local icon = ov[side .. "_keep_" .. i]
			local text = ov[side .. "_keep_" .. i .. "_text"]
			if icon ~= nil and text ~= nil and icon:IsVisible() and text:GetText() == acr then
				return side, i
			end
		end
	end
	return nil
end
S.KeepSide = KeepSide

-- los avisos salen siempre por OOC (igual que las llamadas de enemigos)
local function Channel()
	return "ooc"
end

local function Message(name)
	-- siempre en ingles (lo leen jugadores de cualquier idioma)
	return string.format("[Siege %s] Enemy is taking %s!", Acronym(name), name)
end

function S.Begin(name)
	local now = Now()
	local entry = S.active[name]
	if entry ~= nil then
		entry.since = now
		return
	end
	S.active[name] = { since = now, side = (KeepSide(name)) }
	Alert(string.format(L.Siege_Alert or "%s is under attack!", name), Color("#FF8A3C"))
	if S.window ~= nil then S.window:Refresh() end
end

function S.Cancel(name)
	S.active[name] = nil
	if S.window ~= nil then S.window:Refresh() end
end

-- revisa cada segundo si la fortaleza ya cambio de bando
local lastCheck = -1
local function CheckCaptures()
	local now = Now()
	if now - lastCheck < 1 and now >= lastCheck then
		return
	end
	lastCheck = now
	pcall(TickHelps)
	pcall(UpdateOutpostSides)
	local changed = false
	for name, entry in pairs(S.active) do
		local side = KeepSide(name)
		if entry.side == nil then
			entry.side = side
		elseif side ~= nil and side ~= entry.side then
			S.active[name] = nil
			changed = true
			Alert(string.format(L.Siege_Taken or "%s has been captured!", name), Color("#FFD27A"))
		end
		if S.active[name] ~= nil and now - entry.since > TIMEOUT then
			S.active[name] = nil
			changed = true
		end
	end
	if changed and S.window ~= nil then S.window:Refresh() end
	-- franja de dueno de cada boton al dia
	if S.window ~= nil and S.window:IsVisible() then
		for _, b in ipairs(S.window.buttons) do
			S.window:RefreshButton(b)
		end
	end
end

-- llamas sobre los iconos de fortaleza de la barra principal
function S.AttachOverview(ov)
	if ov == nil then
		return
	end
	for i = 1, 5 do
		for _, side in ipairs({ "freep", "creep" }) do
			local icon = ov[side .. "_keep_" .. i]
			if icon ~= nil and icon.GetParent ~= nil and icon:GetParent() ~= nil then
				local fire = Turbine.UI.Label()
				fire:SetParent(icon:GetParent())
				fire:SetSize(34, 30)
				fire:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
				fire:SetMouseVisible(false)
				fire:SetVisible(false)
				S.overlays[#S.overlays + 1] = { fire = fire, icon = icon, text = ov[side .. "_keep_" .. i .. "_text"], shown = "" }
			end
		end
	end
	S.AttachOutposts(ov)
end

-- puestos avanzados: diamante pequeno (azul/rojo) en lugar de la rayita de color
function S.AttachOutposts(ov)
	if ov == nil then
		return
	end
	for i = 1, 4 do
		local bar = ov["outpost_" .. i]
		local txt = ov["outpost_" .. i .. "_text"]
		local parent = txt ~= nil and txt.GetParent ~= nil and txt:GetParent() or nil
		if bar ~= nil and parent ~= nil then
			local gem = Turbine.UI.Label()
			gem:SetParent(parent)
			gem:SetSize(16, 16)
			gem:SetPosition(bar:GetLeft() + 2, 11)
			gem:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
			gem:SetMouseVisible(false)
			gem:SetVisible(false)
			local fire = Turbine.UI.Label()
			fire:SetParent(parent)
			fire:SetSize(24, 30)
			fire:SetPosition(bar:GetLeft() - 2, -1)
			fire:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
			fire:SetMouseVisible(false)
			fire:SetVisible(false)
			-- la letra vuelve a quedar encima del diamante
			txt:SetParent(parent)
			S.outslots[#S.outslots + 1] = { bar = bar, txt = txt, gem = gem, fire = fire, shown = "", gshown = "" }
		end
	end
end

-- dueno de cada puesto (una vez por segundo)
UpdateOutpostSides = function()
	for _, o in ipairs(S.outslots) do
		local letter = o.txt:GetText()
		o.name = (letter ~= nil and letter ~= "") and NameByAcronym(letter) or nil
		o.side = o.name ~= nil and OutpostSide(o.name) or nil
	end
end

local function AnimateOutposts(frame)
	for _, o in ipairs(S.outslots) do
		if o.bar:IsVisible() then
			o.bar:SetVisible(false)
		end
		local show = o.txt:IsVisible() and o.name ~= nil and o.side ~= nil
		if show then
			local g = RES .. "Outposts/outpost_" .. ((o.side == "creep") and "red" or "blue") .. ".tga"
			if g ~= o.gshown then
				o.gem:SetBackground(g)
				o.gshown = g
			end
			if not o.gem:IsVisible() then o.gem:SetVisible(true) end
		elseif o.gem:IsVisible() then
			o.gem:SetVisible(false)
		end
		if show and S.active[o.name] ~= nil then
			local file = "outpostfire_" .. frame .. ".tga"
			if file ~= o.shown then
				o.fire:SetBackground(DIR .. file)
				o.shown = file
			end
			if not o.fire:IsVisible() then o.fire:SetVisible(true) end
		elseif o.fire:IsVisible() then
			o.fire:SetVisible(false)
		end
	end
end

local function Animate()
	local frame = math.floor(Now() * FPS) % FIRE_FRAMES + 1
	AnimateOutposts(frame)
	for _, o in ipairs(S.overlays) do
		local burning = false
		if o.icon:IsVisible() and o.text ~= nil then
			local name = NameByAcronym(o.text:GetText())
			burning = name ~= nil and S.active[name] ~= nil
		end
		if burning then
			local x, y = o.icon:GetLeft() - 5, o.icon:GetTop()
			if o.fire:GetLeft() ~= x or o.fire:GetTop() ~= y then
				o.fire:SetPosition(x, y)
			end
			local file = "keepfire_" .. frame .. ".tga"
			if file ~= o.shown then
				o.fire:SetBackground(DIR .. file)
				o.shown = file
			end
			if not o.fire:IsVisible() then o.fire:SetVisible(true) end
		elseif o.fire:IsVisible() then
			o.fire:SetVisible(false)
		end
	end
end

local driver = Turbine.UI.Control()
driver:SetWantsUpdates(true)
driver.Update = function()
	local ok, err = pcall(function()
		CheckCaptures()
		Animate()
	end)
	if not ok then
		driver:SetWantsUpdates(false)
		Turbine.Shell.WriteLine("PvMP+ asedios: " .. tostring(err))
	end
end
S.driver = driver

-- lee los avisos del chat (de cualquier jugador con PvMP+, en ingles o espanol)
function _G.PvMP_SiegeCheck(args)
	if args == nil or type(args.Message) ~= "string" then
		return
	end
	-- rapido: los avisos de PvMP+ siempre llevan color
	if not string.find(args.Message, "<rgb=", 1, true) then
		return
	end
	if S.HelpCheck(args.Message) then
		return
	end
	local msg = string.lower(args.Message)
	local acr = string.match(msg, "<rgb=" .. string.lower(TAG) .. ">%[[^%]]- (%a%a?)%]")
	if acr == nil then
		return
	end
	local name = NameByAcronym(string.upper(acr))
	if name ~= nil then
		S.Begin(name)
	end
end

-- ---------------------------------------------------------------------
-- Help!: marca azul en el mapa con el nombre de quien pide ayuda
-- ---------------------------------------------------------------------
local function ToNumber(v)
	return tonumber(v) or tonumber((string.gsub(v, "%.", ","))) or tonumber((string.gsub(v, ",", ".")))
end

local function SenderName(raw)
	if raw == nil then
		return "?"
	end
	return string.match(raw, ">([^<>]+)<") or string.gsub(raw, "<[^>]*>", "")
end

function S.ShowHelp(name, w, s)
	local map = MapWindow
	if map == nil or map.map == nil or map.dif_w == nil or map.dif_s == nil then
		return
	end
	local mk = S.helps[name]
	if mk == nil then
		mk = Turbine.UI.Label()
		mk:SetParent(map.map)
		mk:SetSize(151, 29)
		mk:SetStretchMode(1)
		mk:SetSize(153, 31)
		mk:SetFont(Turbine.UI.Lotro.Font.Arial12)
		mk:SetForeColor(Color("#0A1E3C"))
		mk:SetFontStyle(Turbine.UI.FontStyle.Outline)
		mk:SetOutlineColor(Color("#BFE6FF"))
		mk:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
		mk:SetMouseVisible(false)
		S.helps[name] = mk
	end
	mk:SetText(name .. ": HELP!")
	mk:SetBackground(DIR .. "help_marker.tga")
	mk:SetPosition(
		math.floor(map.map:GetWidth() - map.map:GetWidth() * (w - map.min_w) / map.dif_w - mk:GetWidth() / 2),
		math.floor(map.map:GetHeight() * (s - map.min_s) / map.dif_s - (mk:GetHeight() - 9))
	)
	mk.Timer = HELP_TIME
	mk:SetVisible(true)
	Alert(string.format(L.Help_Alert or "%s needs help!", name), Color("#5CC8FF"))
	S.ShowHelpToast(name)
end

-- abre el mapa del plugin
function S.OpenMap()
	if MapWindow == nil then
		return
	end
	MapWindow:SetVisible(true)
	if SecondaryWindow ~= nil and SecondaryWindow.map_button ~= nil then
		pcall(function() SecondaryWindow.map_button:SetText(L.Map_Hide) end)
	end
end

-- aviso pulsable: clic = abre el mapa, clic derecho = cerrar
local TW, TH = 290, 44
function S.ShowHelpToast(name)
	local t = S.toast
	if t == nil then
		t = Turbine.UI.Window()
		t:SetSize(TW, TH)
		t:SetZOrder(5)
		local frame = Turbine.UI.Label()
		frame:SetParent(t)
		frame:SetSize(TW, TH)
		frame:SetBackColor(Color("#2A5C8C"))
		frame:SetMouseVisible(false)
		local back = Turbine.UI.Label()
		back:SetParent(t)
		back:SetPosition(1, 1)
		back:SetSize(TW - 2, TH - 2)
		back:SetBackColor(Color("#101218"))
		back:SetMouseVisible(false)
		local accent = Turbine.UI.Label()
		accent:SetParent(t)
		accent:SetPosition(1, 1)
		accent:SetSize(4, TH - 2)
		accent:SetBackColor(Color("#3CB4FF"))
		accent:SetMouseVisible(false)
		t.text = Turbine.UI.Label()
		t.text:SetParent(t)
		t.text:SetPosition(12, 4)
		t.text:SetSize(TW - 20, 18)
		t.text:SetFont(Turbine.UI.Lotro.Font.Verdana14 or Turbine.UI.Lotro.Font.Verdana12)
		t.text:SetForeColor(Color("#BFE6FF"))
		t.text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
		t.text:SetMouseVisible(false)
		t.sub = Turbine.UI.Label()
		t.sub:SetParent(t)
		t.sub:SetPosition(12, 23)
		t.sub:SetSize(TW - 20, 16)
		t.sub:SetFont(Turbine.UI.Lotro.Font.Verdana12)
		t.sub:SetForeColor(Color("#E8D9B0"))
		t.sub:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
		t.sub:SetMouseVisible(false)
		t.sub:SetText(L.Help_Click or "Click: show on map  |  right-click: close")
		t.hit = Turbine.UI.Label()
		t.hit:SetParent(t)
		t.hit:SetSize(TW, TH)
		t.hit:SetMouseVisible(true)
		t.hit.MouseClick = function(sender, args)
			if args == nil or args.Button ~= Turbine.UI.MouseButton.Right then
				S.OpenMap()
			end
			t:SetVisible(false)
		end
		S.toast = t
	end
	local dw = Turbine.UI.Display.GetWidth()
	local ax = tonumber(data.numbers.alert_x) or math.floor(dw / 2 - 275)
	local ay = tonumber(data.numbers.alert_y) or 150
	t:SetPosition(math.floor(ax + 275 - TW / 2), math.floor(ay + 128))
	t.text:SetText(string.format(L.Help_Alert or "%s needs help!", name))
	t.timer = HELP_TIME
	t:SetVisible(true)
end

-- devuelve true si el mensaje era un pedido de ayuda
function S.HelpCheck(message)
	if not string.find(string.lower(message), "<rgb=" .. string.lower(HELP_TAG) .. ">help!", 1, true) then
		return false
	end
	local south, west = string.match(message, "@.-(%d+[%.,]?%d*)S, (%d+[%.,]?%d*)W")
	local raw = string.match(message, "^%[[^%]]*%] (.-): ")
	local w, s = west and ToNumber(west), south and ToNumber(south)
	if w ~= nil and s ~= nil then
		S.ShowHelp(SenderName(raw), w, s)
	end
	return true
end

-- parpadeo y fin de las marcas de ayuda (una vez por segundo)
TickHelps = function()
	local t = S.toast
	if t ~= nil and t:IsVisible() then
		t.timer = (t.timer or 0) - 1
		if t.timer <= 0 then
			t:SetVisible(false)
		end
	end
	for name, mk in pairs(S.helps) do
		if mk:IsVisible() then
			mk.Timer = (mk.Timer or 0) - 1
			if mk.Timer <= 0 then
				mk:SetVisible(false)
			elseif mk.Timer % 2 == 0 then
				mk:SetBackground(DIR .. "help_marker.tga")
			else
				mk:SetBackground("PvMP_Plus_Revisited/PvMP_Plus/Resources/MapIcons/enemy_position_overlay_empty.tga")
			end
		end
	end
end

-- ---------------------------------------------------------------------
-- ventana
-- ---------------------------------------------------------------------
SiegeWindow = class(Turbine.UI.Window)

function SiegeWindow:Constructor()
	Turbine.UI.Window.Constructor(self)
	self:SetSize(W, H)
	if data.numbers.siegeWin_x == nil then
		data.numbers.siegeWin_x = math.floor(Turbine.UI.Display.GetWidth() / 2 - W / 2)
		data.numbers.siegeWin_y = math.floor(Turbine.UI.Display.GetHeight() / 2 + 120)
	end
	self:SetPosition(data.numbers.siegeWin_x, data.numbers.siegeWin_y)
	self:SetZOrder(1)

	self.back = Turbine.UI.Label()
	self.back:SetParent(self)
	self.back:SetSize(W, H)
	self.back:SetBackground(DIR .. "siege_bg.tga")
	self.back:SetMouseVisible(false)

	-- titulo (arrastrar desde aqui)
	self.title = Turbine.UI.Label()
	self.title:SetParent(self)
	self.title:SetPosition(40, 12)
	self.title:SetSize(W - 80, 20)
	self.title:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
	self.title:SetForeColor(Color("#F0CB78"))
	self.title:SetFontStyle(Turbine.UI.FontStyle.Outline)
	self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.title:SetText(L.Siege_Title or "Sieges")
	self.title.MouseDown = function(sender, args)
		if args.Button == Turbine.UI.MouseButton.Left then
			self.dragging = true
			self.dx, self.dy = args.X, args.Y
		end
	end
	self.title.MouseMove = function(sender, args)
		if self.dragging then
			self:SetPosition(self:GetLeft() + args.X - self.dx, self:GetTop() + args.Y - self.dy)
		end
	end
	self.title.MouseUp = function()
		self.dragging = false
		data.numbers.siegeWin_x = self:GetLeft()
		data.numbers.siegeWin_y = self:GetTop()
	end

	self.close = Turbine.UI.Label()
	self.close:SetParent(self)
	self.close:SetPosition(W - 52, 12)
	self.close:SetSize(18, 20)
	self.close:SetFont(Turbine.UI.Lotro.Font.Verdana14 or Turbine.UI.Lotro.Font.Verdana12)
	self.close:SetForeColor(Color("#C9A45A"))
	self.close:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	self.close:SetText("x")
	self.close.MouseClick = function()
		storage.siege_hidden = true
		self:SetVisible(false)
	end

	self.buttons = {}
	for i = 1, 5 do
		local name = Keeps[i]
		if name ~= nil then
			self:AddButton(i, name)
		end
	end
	for i, acr in ipairs(OUTPOST_ORDER) do
		local name = NameByAcronym(acr)
		if name ~= nil and IsOutpost(name) then
			self:AddButton(i, name, true)
		end
	end

	self:AddHelpButton()

	-- F12 (ocultar interfaz) tambien oculta esta ventana
	self.uiHidden = false
	self:SetWantsKeyEvents(true)
	self.KeyDown = function(sender, args)
		if args ~= nil and args.Action == Turbine.UI.Lotro.Action.UI_Toggle then
			self.uiHidden = not self.uiHidden
			self:SetVisible((not self.uiHidden) and (not storage.siege_hidden))
			if S.toast ~= nil and self.uiHidden then
				S.toast:SetVisible(false)
			end
		end
	end

	self:SetVisible(not storage.siege_hidden)
	self:Refresh()
end

function SiegeWindow:AddButton(i, name, small)
	local b = {}
	local size = small and OBTN or BTN
	b.name = name
	b.small = small
	b.box = Turbine.UI.Control()
	b.box:SetParent(self)
	b.box:SetSize(size, size)
	if small then
		b.box:SetPosition(OBX + (i - 1) * (OBTN + OGAP), OBY)
	else
		b.box:SetPosition(BX + (i - 1) * (BTN + GAP), BY)
	end

	b.slot = Turbine.UI.Lotro.Quickslot()
	b.slot:SetParent(b.box)
	b.slot:SetSize(size, size)
	b.slot:SetUseOnRightClick(false)
	b.slot:SetAllowDrop(false)
	b.slot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, ""))

	b.face = Turbine.UI.Control()
	b.face:SetParent(b.box)
	b.face:SetSize(size, size)
	b.face:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	b.face:SetMouseVisible(false)

	b.label = Turbine.UI.Label()
	b.label:SetParent(b.box)
	b.label:SetSize(size, size - 6)
	if small then
		b.label:SetFont(Turbine.UI.Lotro.Font.TrajanProBold14 or Turbine.UI.Lotro.Font.TrajanPro14)
	else
		b.label:SetFont(Turbine.UI.Lotro.Font.TrajanProBold16 or Turbine.UI.Lotro.Font.TrajanPro16)
	end
	b.label:SetFontStyle(Turbine.UI.FontStyle.Outline)
	b.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
	b.label:SetForeColor(Color("#F0E6CC"))
	b.label:SetMouseVisible(false)
	b.label:SetText(Acronym(name))

	-- franja inferior: azul o rojo segun quien tiene la fortaleza
	b.owner = Turbine.UI.Control()
	b.owner:SetParent(b.box)
	b.owner:SetPosition(5, size - 7)
	b.owner:SetSize(size - 10, 3)
	b.owner:SetMouseVisible(false)

	b.hover = false
	b.slot.MouseEnter = function()
		b.hover = true
		self:RefreshButton(b)
	end
	b.slot.MouseLeave = function()
		b.hover = false
		self:RefreshButton(b)
	end
	b.slot.MouseDown = function(sender, args)
		if args.Button == Turbine.UI.MouseButton.Right then
			S.Cancel(name)
		end
	end
	self.buttons[#self.buttons + 1] = b
end

function SiegeWindow:RefreshButton(b)
	local prefix = b.small and "siege_obtn_" or "siege_btn_"
	local face = prefix .. "normal.tga"
	if S.active[b.name] ~= nil then
		face = prefix .. "active.tga"
	elseif b.hover then
		face = prefix .. "hover.tga"
	end
	if face ~= b.shown then
		b.face:SetBackground(DIR .. face)
		b.shown = face
	end
	local side = KeepSide(b.name)
	if side == "freep" then
		b.owner:SetBackColor(Color("#3C8CFF"))
		b.owner:SetVisible(true)
	elseif side == "creep" then
		b.owner:SetBackColor(Color("#E0383C"))
		b.owner:SetVisible(true)
	else
		b.owner:SetVisible(false)
	end
end

function SiegeWindow:Refresh()
	local ch = Channel()
	for _, b in ipairs(self.buttons) do
		local sc = b.slot:GetShortcut()
		sc:SetData("/" .. ch .. " <rgb=" .. TAG .. ">" .. Message(b.name) .. "</rgb>")
		b.slot:SetShortcut(sc)
		b.slot:SetAllowDrop(false)
		self:RefreshButton(b)
	end
end

-- boton Help!: la alias usa ;loc, el juego lo cambia por tu posicion
function SiegeWindow:AddHelpButton()
	local box = Turbine.UI.Control()
	box:SetParent(self)
	box:SetSize(HW, HH)
	box:SetPosition(HX, HY)
	local slot = Turbine.UI.Lotro.Quickslot()
	slot:SetParent(box)
	slot:SetSize(HW, HH)
	slot:SetUseOnRightClick(false)
	slot:SetAllowDrop(false)
	slot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias,
		"/" .. Channel() .. " <rgb=" .. HELP_TAG .. ">HELP! @ " .. (L.Loc_Chat or ";loc") .. "</rgb>"))
	slot:SetAllowDrop(false)
	local face = Turbine.UI.Control()
	face:SetParent(box)
	face:SetSize(HW, HH)
	face:SetBackground(DIR .. "siege_help.tga")
	face:SetMouseVisible(false)
	slot.MouseEnter = function()
		face:SetBackground(DIR .. "siege_help_hover.tga")
	end
	slot.MouseLeave = function()
		face:SetBackground(DIR .. "siege_help.tga")
	end
	self.help = { box = box, slot = slot, face = face }
end

function SiegeWindow:Toggle()
	local show = not self:IsVisible()
	storage.siege_hidden = not show
	self.uiHidden = false
	self:SetVisible(show)
	if show then self:Refresh() end
end
