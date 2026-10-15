-- v4.3.14: rachas de bajas y nemesis.
-- Racha = golpes mortales seguidos sin morir. Aviso en pantalla a las 3, 5, 10,
-- 15, 20... y se guarda la mejor racha. Nemesis = quien mas veces te ha
-- incapacitado (se cuenta desde ahora) y a quien mas has matado (del registro
-- de bajas que ya guardaba el addon). Todo por personaje, en storage.rivals
-- (los numeros se guardan como texto, igual que el resto del addon).

_G.PvMP_Rivals = {}
local R = PvMP_Rivals

local function N(v)
	return tonumber(v) or 0
end

local function Color(hex)
	return Turbine.UI.Color(tonumber(hex:sub(2, 3), 16) / 255, tonumber(hex:sub(4, 5), 16) / 255, tonumber(hex:sub(6, 7), 16) / 255)
end

local function T(key, default)
	return (L ~= nil and L[key]) or default
end

function R.Data()
	if storage == nil then
		return nil
	end
	if type(storage.rivals) ~= "table" then
		storage.rivals = {}
	end
	local d = storage.rivals
	if type(d.killers) ~= "table" then
		d.killers = {}
	end
	return d
end

local function Trim(s)
	if type(s) ~= "string" then
		return nil
	end
	s = string.gsub(s, "<[^>]*>", "")
	s = string.match(s, "^%s*(.-)%s*$")
	if s == nil or s == "" then
		return nil
	end
	return s
end

local function IsMilestone(n)
	return n == 3 or n == 5 or (n >= 10 and n % 5 == 0)
end

function R.OnKill(victim)
	local d = R.Data()
	if d == nil then
		return
	end
	local n = N(d.streak) + 1
	d.streak = tostring(n)
	if n > N(d.best) then
		d.best = tostring(n)
	end
	if IsMilestone(n) and AlertWindow ~= nil and AlertWindow.NewAlert ~= nil then
		pcall(AlertWindow.NewAlert, AlertWindow, string.format(T("Rivals_Streak_Alert", "Killing streak x%d!"), n), Color("#FFD24A"), 4)
	end
	R.Refresh()
end

function R.OnDeath(killer)
	local d = R.Data()
	if d == nil then
		return
	end
	local n = N(d.streak)
	if n >= 3 then
		Turbine.Shell.WriteLine(string.format(T("Rivals_Streak_End", "PvMP+: your killing streak ended at %d."), n))
	end
	d.streak = "0"
	killer = Trim(killer)
	if killer ~= nil then
		d.killers[killer] = tostring(N(d.killers[killer]) + 1)
	end
	R.Refresh()
end

-- se llama desde el lector del chat (Parser.lua), protegido con pcall
function _G.PvMP_RivalsCheck(args)
	if args == nil or args.ChatType ~= Turbine.ChatType.Death or type(args.Message) ~= "string" then
		return
	end
	local msg = args.Message
	local ks, ke = L.Chat_KillingBlow_Start, L.Chat_KillingBlow_End
	if ks ~= nil and ke ~= nil and string.find(msg, ks) and string.find(msg, ke) then
		R.OnKill(string.match(msg, ks .. "(.+)" .. ke))
	elseif L.Chat_Defeated ~= nil and string.find(msg, L.Chat_Defeated) then
		R.OnDeath(string.match(msg, "^(.-)" .. L.Chat_Defeated))
	elseif L.Chat_Environment_Death ~= nil and string.find(msg, L.Chat_Environment_Death) then
		R.OnDeath(nil)
	end
end

-- los 3 primeros de una tabla nombre -> cantidad
local function Top(tbl)
	local list = {}
	if type(tbl) == "table" then
		for name, v in pairs(tbl) do
			local n = N(v)
			if type(name) == "string" and n > 0 then
				list[#list + 1] = { name = name, n = n }
			end
		end
	end
	table.sort(list, function(a, b)
		if a.n ~= b.n then return a.n > b.n end
		return a.name < b.name
	end)
	return list
end

local function Lines(list)
	if #list == 0 then
		return T("Rivals_None", "  (nobody yet)")
	end
	local out = {}
	for i = 1, math.min(3, #list) do
		out[#out + 1] = i .. ". " .. list[i].name .. "  (" .. list[i].n .. ")"
	end
	return table.concat(out, "\n")
end

-- ventana
local W, H = 300, 290

RivalsWindow = class(Turbine.UI.Lotro.Window)

function RivalsWindow:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self)
	self:SetSize(W, H)
	self:SetText(T("Rivals_Title", "Streaks & Rivals"))
	local d = R.Data() or {}
	local x, y = tonumber(d.x), tonumber(d.y)
	if x == nil or y == nil then
		x, y = math.floor(Turbine.UI.Display.GetWidth() / 2 - W / 2), 200
	end
	x = math.max(0, math.min(x, Turbine.UI.Display.GetWidth() - W))
	y = math.max(0, math.min(y, Turbine.UI.Display.GetHeight() - H))
	self:SetPosition(x, y)
	self:SetWantsKeyEvents(true)
	self:SetVisible(false)

	local function Lbl(top, h, font, color)
		local l = Turbine.UI.Label()
		l:SetParent(self)
		l:SetPosition(20, top)
		l:SetSize(W - 40, h)
		l:SetFont(font)
		l:SetFontStyle(Turbine.UI.FontStyle.Outline)
		l:SetForeColor(color)
		l:SetMouseVisible(false)
		return l
	end
	self.streak = Lbl(40, 22, Turbine.UI.Lotro.Font.TrajanPro16, Color("#FFD24A"))
	self.best = Lbl(64, 18, Turbine.UI.Lotro.Font.Verdana14, Color("#E6E9EF"))
	self.killers_head = Lbl(92, 18, Turbine.UI.Lotro.Font.Verdana14, Color("#FF6B6B"))
	self.killers = Lbl(112, 54, Turbine.UI.Lotro.Font.Verdana12, Color("#E6E9EF"))
	self.victims_head = Lbl(170, 18, Turbine.UI.Lotro.Font.Verdana14, Color("#7CC4FF"))
	self.victims = Lbl(190, 54, Turbine.UI.Lotro.Font.Verdana12, Color("#E6E9EF"))
	self.killers_head:SetText(T("Rivals_Killers", "Killed you the most:"))
	self.victims_head:SetText(T("Rivals_Victims", "You killed the most:"))

	self.reset = LotroButton(self, 120, T("Rivals_Reset", "Reset"))
	self.reset:SetPosition(W / 2 - 60, H - 40)
	self.reset.Click = function()
		local dd = R.Data()
		if dd ~= nil then
			dd.streak, dd.best, dd.killers = "0", "0", {}
		end
		R.Refresh()
	end

	self.KeyDown = function(sender, args)
		if args.Action == Turbine.UI.Lotro.Action.Escape then
			self:SetVisible(false)
		end
	end
	self.PositionChanged = function()
		local dd = R.Data()
		if dd ~= nil then
			dd.x, dd.y = tostring(self:GetLeft()), tostring(self:GetTop())
		end
	end
	self.VisibleChanged = function()
		if self:IsVisible() then
			R.Refresh()
		end
	end
end

function R.Refresh()
	local win = R.window
	if win == nil or not win:IsVisible() then
		return
	end
	local d = R.Data() or {}
	win.streak:SetText(string.format(T("Rivals_Streak", "Current streak: %d"), N(d.streak)))
	win.best:SetText(string.format(T("Rivals_Best", "Best streak: %d"), N(d.best)))
	win.killers:SetText(Lines(Top(d.killers)))
	local frags = (data ~= nil and data.numbers ~= nil) and data.numbers.frags or nil
	win.victims:SetText(Lines(Top(frags)))
end

function R.Toggle()
	if R.window == nil then
		return
	end
	R.window:SetVisible(not R.window:IsVisible())
	R.Refresh()
end
