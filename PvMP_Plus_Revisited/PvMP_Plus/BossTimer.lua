-- v4.3.5: icono del jefe Gaergoth the Unbound (Ettenmoors).
-- Siempre visible debajo de la barra principal:
--   * ACTIVO (no sabemos cuando muere): icono grande con llamas animadas
--     en todo su contorno.
--   * Cuando el chat del juego dice que lo mataron: el icono se apaga
--     (gris, sin llamas) y cuenta 1 hora. Al terminar vuelve a ACTIVO.
-- Se guarda por servidor (sigue contando aunque salgas del juego).
-- Manual: /pvmp+ gaergoth muerto (u off)  |  /pvmp+ gaergoth activo (u on)

local BOSS_KEY = "PvMP_Plus_Gaergoth"
local RESPAWN = 3600          -- 1 hora
local DUP_GUARD = 120         -- ignora avisos repetidos del mismo combate
local DIR = "PvMP_Plus_Revisited/PvMP_Plus/Resources/Bosses/"
local FIRE_FRAMES = 10
local FPS = 12.5
local ICON = 80
local W, H = 240, 80
local TX = ICON + 2

-- segundos "absolutos" (siempre crecen, tambien al cambiar de anio)
local function Now()
	local d = Turbine.Engine.GetDate()
	return d.Year * 31622400 + (d.DayOfYear - 1) * 86400 + d.Hour * 3600 + d.Minute * 60 + d.Second
end

local function Color(hex)
	hex = hex:gsub("#", "")
	return Turbine.UI.Color(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255)
end

local function Clock(s)
	if s < 0 then s = 0 end
	return string.format("%02d:%02d", math.floor(s / 60), s % 60)
end

local function Text(parent, x, y, w, h, font)
	local l = Turbine.UI.Label()
	l:SetParent(parent)
	l:SetPosition(x, y)
	l:SetSize(w, h)
	l:SetFont(font)
	l:SetFontStyle(Turbine.UI.FontStyle.Outline)
	l:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
	l:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	l:SetMouseVisible(false)
	return l
end

BossTimerWindow = class(Turbine.UI.Window)

function BossTimerWindow:Constructor()
	Turbine.UI.Window.Constructor(self)
	self:SetSize(W, H)
	self:SetMouseVisible(false)
	self:SetVisible(false)

	self.icon = Turbine.UI.Label()
	self.icon:SetParent(self)
	self.icon:SetPosition(0, 0)
	self.icon:SetSize(ICON, ICON)
	self.icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	self.icon:SetMouseVisible(false)

	self.name = Text(self, TX, 20, W - TX, 16, Turbine.UI.Lotro.Font.Verdana14 or Turbine.UI.Lotro.Font.Verdana12)
	self.name:SetForeColor(Color("#E8ECF4"))
	self.name:SetText(L.Boss_Gaergoth_Name or "Gaergoth the Unbound")

	self.time = Text(self, TX, 37, W - TX, 18, Turbine.UI.Lotro.Font.TrajanPro16 or Turbine.UI.Lotro.Font.TrajanPro14)

	self.track = Turbine.UI.Label()
	self.track:SetParent(self)
	self.track:SetPosition(TX, 58)
	self.track:SetSize(W - TX - 8, 3)
	self.track:SetBackColor(Color("#232835"))
	self.track:SetMouseVisible(false)

	self.fill = Turbine.UI.Label()
	self.fill:SetParent(self)
	self.fill:SetPosition(TX, 58)
	self.fill:SetSize(0, 3)
	self.fill:SetBackColor(Color("#9AA3B5"))
	self.fill:SetMouseVisible(false)

	self.ends = nil
	self.lastStart = nil
	self.lastTick = -1
	self.shownIcon = ""
	self:Load()

	self:SetWantsUpdates(true)
	self.Update = function()
		local ok = pcall(self.Tick, self)
		if not ok then
			self:SetWantsUpdates(false)
		end
	end
end

function BossTimerWindow:Load()
	local saved = nil
	pcall(function()
		saved = Turbine.PluginData.Load(Turbine.DataScope.Server, BOSS_KEY)
	end)
	if type(saved) == "table" then
		local ends = tonumber(saved.ends)
		if ends ~= nil and ends > Now() then
			self.ends = ends
			self.lastStart = ends - RESPAWN
		end
	end
end

function BossTimerWindow:Save()
	local value = { ends = self.ends ~= nil and tostring(self.ends) or "" }
	pcall(Turbine.PluginData.Save, Turbine.DataScope.Server, BOSS_KEY, value)
end

function BossTimerWindow:IsActive()
	return self.ends == nil or Now() >= self.ends
end

local function Alert(text, color)
	if AlertWindow ~= nil and AlertWindow.NewAlert ~= nil then
		pcall(AlertWindow.NewAlert, AlertWindow, text, color, 5)
	end
	Turbine.Shell.WriteLine("PvMP+: " .. text)
end

-- lo mataron: icono apagado + 1 hora (manual = true desde el comando)
function BossTimerWindow:Start(manual)
	local now = Now()
	if not manual and self.lastStart ~= nil and now - self.lastStart < DUP_GUARD then
		return
	end
	self.lastStart = now
	self.ends = now + RESPAWN
	self:Save()
	self.lastTick = -1
	Alert(L.Boss_Killed_Alert or "Gaergoth defeated - respawn in 1 hour", Color("#FF6B6B"))
	self:Tick()
end

-- volver a ACTIVO a mano
function BossTimerWindow:Stop()
	self.ends = nil
	self.lastStart = nil
	self:Save()
	self.lastTick = -1
	self:Tick()
end

function BossTimerWindow:SetIcon(file)
	if file ~= self.shownIcon then
		self.icon:SetBackground(DIR .. file)
		self.shownIcon = file
	end
end

function BossTimerWindow:Tick()
	local active = self.ends == nil
	-- llamas animadas (cada frame)
	if not active then
		active = Now() >= self.ends
	end
	if active and self:IsVisible() then
		local f = math.floor(Turbine.Engine.GetGameTime() * FPS) % FIRE_FRAMES + 1
		self:SetIcon("gaergoth_fire_" .. f .. ".tga")
	end

	-- texto, posicion y visibilidad (una vez por segundo)
	local now = Now()
	if now == self.lastTick then
		return
	end
	self.lastTick = now
	if self.ends ~= nil and now >= self.ends then
		-- termino la hora: vuelve a estar activo
		self.ends = nil
		self:Save()
		Alert(L.Boss_Active_Alert or "Gaergoth the Unbound is up!", Color("#FFB347"))
	end
	if self.ends == nil then
		self.time:SetText(L.Boss_Active or "ACTIVE!")
		self.time:SetForeColor(Color("#FFB347"))
		self.track:SetVisible(false)
		self.fill:SetVisible(false)
		if self.shownIcon == "" or self.shownIcon == "gaergoth_off.tga" then
			self:SetIcon("gaergoth_fire_1.tga")
		end
	else
		local left = self.ends - now
		self:SetIcon("gaergoth_off.tga")
		self.time:SetText((L.Boss_Respawn or "Respawn in ") .. Clock(left))
		self.time:SetForeColor(Color(left <= 300 and "#FFB347" or "#9AA3B5"))
		self.track:SetVisible(true)
		self.fill:SetVisible(true)
		self.fill:SetWidth(math.floor((W - TX - 8) * (left / RESPAWN)))
	end
	-- debajo de la barra principal (o de sus estadisticas)
	local ov = OverviewWindow
	local show = ov ~= nil and ov:IsVisible() and ov.panel ~= nil and ov.panel:IsVisible()
	if show then
		local y = ov:GetTop() + ((storage ~= nil and storage.stats_hidden) and 64 or 102)
		local x = ov:GetLeft() + math.floor(ov:GetWidth() / 2 - W / 2)
		if x ~= self:GetLeft() or y ~= self:GetTop() then
			self:SetPosition(x, y)
		end
	end
	if self:IsVisible() ~= show then
		self:SetVisible(show)
	end
end

-- Lee el chat: solo mensajes del juego (no lo que escriben los jugadores)
local PLAYER_CHAT = {}
for _, n in ipairs({ "Say", "Fellowship", "Raid", "Kinship", "Officer", "OOC", "Tell", "Emote", "Trade", "LFF",
		"Roleplay", "World", "Advice", "UserChat1", "UserChat2", "UserChat3", "UserChat4", "UserChat5",
		"UserChat6", "UserChat7", "UserChat8" }) do
	local t = Turbine.ChatType[n]
	if t ~= nil then
		PLAYER_CHAT[t] = true
	end
end

local KILL_WORDS = { "topple", "has been defeated", "have defeated", "has defeated", "was defeated",
	"defeated gaergoth", "slain", "slew", "has been killed", "killed gaergoth", "has fallen",
	"has died", " died", "vanquish", "destroyed gaergoth" }

function _G.PvMP_BossCheck(args)
	if args == nil or type(args.Message) ~= "string" or PLAYER_CHAT[args.ChatType] then
		return
	end
	-- rapido: solo seguimos si el mensaje nombra al jefe
	if not (string.find(args.Message, "aergoth", 1, true) or string.find(args.Message, "AERGOTH", 1, true)) then
		return
	end
	local msg = string.lower(args.Message)
	if not string.find(msg, "gaergoth", 1, true) or string.find(msg, "incapacitat", 1, true) then
		return
	end
	for _, w in ipairs(KILL_WORDS) do
		if string.find(msg, w, 1, true) then
			if BossTimer ~= nil then
				BossTimer:Start(false)
			end
			return
		end
	end
end
