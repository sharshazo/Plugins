import "PvMP_Plus_Revisited.PvMP_Plus"

LoadData()
-- v4.3.14: colores del tema elegido (antes de crear las ventanas)
if PvMP_Themes ~= nil then
	local okTheme, errTheme = pcall(PvMP_Themes.ApplyGlobals)
	if not okTheme then
		Turbine.Shell.WriteLine("PvMP+ tema: " .. tostring(errTheme))
	end
end

InitWindowPoints = InitWindowPoints()
InitWindowFrags = InitWindowFrags()
OverviewWindow = OverviewWindow()
SecondaryWindow = SecondaryWindow()
RecentHitsWindow = RecentHitsWindow()
StatsWindow = StatsWindow()
OverviewSettingsPanel = Overview_Settings()
AlertWindow = AlertWindow()
BattleTaskWindow = BattleTaskWindow()
Settings = Settings()
ResetWindow = ResetWindow()
MapWindow = MapWindow()
-- v4.3.3: temporizador de Gaergoth (debajo de la barra)
local okBoss, boss = pcall(BossTimerWindow)
if okBoss then
	BossTimer = boss
else
	Turbine.Shell.WriteLine("PvMP+: " .. tostring(boss))
end
-- v4.3.4: auras estilo LUI en fortalezas y mejoras
if PvMP_Auras ~= nil then
	local okAura, errAura = pcall(PvMP_Auras.AttachOverview, OverviewWindow)
	if not okAura then
		Turbine.Shell.WriteLine("PvMP+ auras: " .. tostring(errAura))
	end
end
-- v4.3.13: estilos animados de la barra de rango
if PvMP_BarFX ~= nil then
	local okBar, errBar = pcall(PvMP_BarFX.Attach, OverviewWindow)
	if not okBar then
		Turbine.Shell.WriteLine("PvMP+ barra: " .. tostring(errBar))
	end
end
-- v4.3.14: ventana de rachas y nemesis
if PvMP_Rivals ~= nil then
	local okRiv, errRiv = pcall(function() PvMP_Rivals.window = RivalsWindow() end)
	if not okRiv then
		Turbine.Shell.WriteLine("PvMP+ rivales: " .. tostring(errRiv))
	end
end
-- v4.3.6: ventana de asedios + llamas en las fortalezas
if PvMP_Siege ~= nil then
	local okSiege, errSiege = pcall(function()
		PvMP_Siege.AttachOverview(OverviewWindow)
		PvMP_Siege.window = SiegeWindow()
	end)
	if not okSiege then
		Turbine.Shell.WriteLine("PvMP+ asedios: " .. tostring(errSiege))
	end
end

if Data_Loaded then
	OverviewWindow.panel:SetVisible(not storage.minimized)
	SecondaryWindow:SetVisible((not storage.minimized) and (not storage.secondaryMinimized))
	RecentHitsWindow:SetVisible((not storage.minimized) and (not storage.show_recent_hits_disabled) and (not storage.show_recent_hits_disabled))
	OverviewWindow:SetVisible(true)
	OverviewSettingsPanel:SetVisible(true)
else
	InitWindowFrags:Open()
	InitWindowPoints:Open()
end

-- Options in Plugin Window
plugin.GetOptionsPanel = function(self)
	local opt_panel = Turbine.UI.Control()
	opt_panel:SetHeight(100)

	local open_settings = Turbine.UI.Lotro.Button()
	open_settings:SetText(L.Options_Open_Settings)
	open_settings:SetPosition(15, 15)
	open_settings:SetWidth(185)
	open_settings:SetParent(opt_panel)
	open_settings.MouseClick = function()
		Settings:Open()
	end

	local open_points = Turbine.UI.Lotro.Button()
	open_points:SetText(L.Options_Update_Points)
	open_points:SetPosition(15, open_settings:GetTop() + 30)
	open_points:SetWidth(185)
	open_points:SetParent(opt_panel)
	open_points.MouseClick = function()
		InitWindowPoints:Open()
	end

	local open_frags = Turbine.UI.Lotro.Button()
	open_frags:SetText(L.Options_Update_Frags)
	open_frags:SetPosition(15, open_points:GetTop() + 30)
	open_frags:SetWidth(185)
	open_frags:SetParent(opt_panel)
	open_frags.MouseClick = function()
		InitWindowFrags:Open()
	end

	return opt_panel
end

-- Register chat commands
PvMP_Plus_Command = Turbine.ShellCommand()
Turbine.Shell.AddCommand("pvmp+", PvMP_Plus_Command)
function PvMP_Plus_Command:GetShortHelp()
	return L.Command_Help
end

function PvMP_Plus_Command:GetHelp()
	return self:GetShortHelp()
end

function PvMP_Plus_Command:Execute(cmd, args)
	-- v4.3.2-es: acepta los comandos en espanol y en ingles
	local a = string.lower(string.match(tostring(args or ""), "^%s*(.-)%s*$") or "")
	local lang = string.match(a, "^idioma%s+(%a+)$") or string.match(a, "^language%s+(%a+)$")
	if lang ~= nil then
		if PvMP_SetLanguage ~= nil and PvMP_SetLanguage(lang) then
			Turbine.Shell.WriteLine(lang == "es" and "PvMP+: idioma Espa\195\177ol." or "PvMP+: language English.")
		else
			Turbine.Shell.WriteLine("PvMP+: /pvmp+ idioma es | /pvmp+ language en")
		end
	elseif (a == "asedios" or a == "asedio" or a == "sieges" or a == "siege") then
		if PvMP_Siege ~= nil and PvMP_Siege.window ~= nil then PvMP_Siege.window:Toggle() end
	elseif (a == "auras on" or a == "auras off") then
		if PvMP_Auras ~= nil then PvMP_Auras.SetEnabled(a == "auras on") end
		Turbine.Shell.WriteLine("PvMP+: " .. a)
	elseif (a == "gaergoth" or a == "gaergoth muerto" or a == "gaergoth off" or a == "gaergoth dead") then
		if BossTimer ~= nil then BossTimer:Start(true) end
	elseif (a == "gaergoth abajo" or a == "gaergoth below" or a == "gaergoth izquierda" or a == "gaergoth left" or a == "gaergoth derecha" or a == "gaergoth right") then
		local p = "below"
		if a == "gaergoth izquierda" or a == "gaergoth left" then p = "left" end
		if a == "gaergoth derecha" or a == "gaergoth right" then p = "right" end
		if BossTimer ~= nil then BossTimer:SetPlacement(p) end
		if Settings ~= nil and Settings.UpdateBossButton ~= nil then Settings:UpdateBossButton() end
	elseif (a == "gaergoth activo" or a == "gaergoth on" or a == "gaergoth active" or a == "gaergoth reset") then
		if BossTimer ~= nil then BossTimer:Stop() end
		Turbine.Shell.WriteLine("PvMP+: Gaergoth ON.")
	elseif (a == "rivales" or a == "racha" or a == "rivals" or a == "streak") then
		if PvMP_Rivals ~= nil then PvMP_Rivals.Toggle() end
	elseif (a == string.lower(L.Command_Settings) or a == "settings" or a == "opciones" or a == "ajustes") then
		Settings:Open()
	elseif (a == string.lower(L.Command_Map) or a == "map" or a == "mapa") then
		MapWindow:SetVisible(not MapWindow:IsVisible())
		if MapWindow:IsVisible() then
			SecondaryWindow.map_button:SetText(L.Map_Hide)
		else
			SecondaryWindow.map_button:SetText(L.Map_Show)
		end
	else
		Turbine.Shell.WriteLine(self:GetShortHelp())
	end
end

Reloader = class(Turbine.UI.Control)
function Reloader:Constructor()
    Turbine.UI.Control.Constructor(self)
    self:SetWantsUpdates(true)
    self.reloaded = false
    self.Update = function()
        if self.reloaded then
            self:SetWantsUpdates(false)
        elseif not(self.reloaded) then
            Turbine.PluginManager.UnloadScriptState("PvMP+Reloader") -- Apartment
			Turbine.PluginManager.RefreshAvailablePlugins()
            self.reloaded = true
            self:SetParent(nil)
        end
    end
end

function ReloadPlugin()
    Turbine.PluginManager.LoadPlugin("PvMP+ Reloader") -- Name
end

local reload = Reloader()

Plugins["PvMP+"].Load = function(sender, args)
	if locale == "en" then
		Turbine.Shell.WriteLine(sender:GetName() .. " v"..sender:GetVersion() .. " by " .. sender:GetAuthor())
	elseif locale == "de" then
		Turbine.Shell.WriteLine(sender:GetName() .. " v"..sender:GetVersion() .. " von " .. sender:GetAuthor() .. " (Deutsche Übersetzung von RenthoMar)")
	elseif locale == "fr" then
		Turbine.Shell.WriteLine(sender:GetName() .. " v"..sender:GetVersion() .. " par " .. sender:GetAuthor())
	elseif locale == "es" then
		Turbine.Shell.WriteLine(sender:GetName() .. " v"..sender:GetVersion() .. " por " .. sender:GetAuthor() .. " (en espa\195\177ol)")
	elseif locale == "ru" then
		Turbine.Shell.WriteLine(sender:GetName() .. " v"..sender:GetVersion() .. " от " .. sender:GetAuthor())
	end
end