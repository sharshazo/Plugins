-- v4.3.14: temas de color para las ventanas del addon y bloqueo de ventanas.
-- El tema cambia los colores globales (texto, bordes, paneles, graficas) y el
-- marco de la barra ANTES de crear las ventanas, por eso al cambiarlo se recarga
-- el plugin (3 s despues del ultimo clic). Se guarda para toda la cuenta.
-- Bloqueo: las barras de arrastre (Ctrl+\) no aparecen y la ventana de
-- asedios no se mueve. Se guarda por personaje (storage.windows_locked).

local SAVE_KEY = "PvMP_Plus_Theme"
local ROOT = "PvMP_Plus_Revisited/PvMP_Plus/Resources/Themes/"
local RELOAD_DELAY = 3

_G.PvMP_Themes = { LIST = { "classic", "modern", "elven", "mordor" }, current = "classic" }
local T = PvMP_Themes

local DEF = {
	modern = { text = { 230, 233, 239 }, panel = { 14, 16, 22 }, inner = { 35, 40, 53 }, chart = { 77, 163, 255 } },
	elven = { text = { 200, 225, 255 }, panel = { 8, 16, 28 }, inner = { 24, 40, 60 }, chart = { 140, 200, 255 } },
	mordor = { text = { 255, 150, 100 }, panel = { 18, 6, 6 }, inner = { 48, 16, 16 }, chart = { 217, 56, 30 } },
}
local NAMES_EN = { classic = "Classic", modern = "Modern dark", elven = "Elven", mordor = "Mordor" }

local function Valid(v)
	for _, x in ipairs(T.LIST) do
		if x == v then return true end
	end
	return false
end

pcall(function()
	local saved = Turbine.PluginData.Load(Turbine.DataScope.Account, SAVE_KEY)
	if type(saved) == "table" and Valid(saved.theme) then
		T.current = saved.theme
	end
end)
T.loaded = T.current

local function C(t)
	return Turbine.UI.Color(t[1] / 255, t[2] / 255, t[3] / 255)
end

-- se llama en Main despues de LoadData() y antes de crear las ventanas
function T.ApplyGlobals()
	local d = DEF[T.loaded]
	if d == nil then
		return
	end
	_G.Default_Font_Color = C(d.text)
	_G.Grey_Font_Color = C(d.inner)
	_G.Bar_Chart_Color = C(d.chart)
	_G.Panel_Back_Color = C(d.panel)
	if Bar_Builder ~= nil and type(Bar_Builder[1]) == "string" then
		local side = string.find(Bar_Builder[1], "/Red/", 1, true) and "Red" or "Blue"
		local dir = ROOT .. T.loaded .. "/" .. side .. "/"
		Bar_Builder[2] = dir .. "bar_left.tga"
		Bar_Builder[3] = dir .. "bar_right.tga"
		Bar_Builder[4] = dir .. "bar_middle.tga"
	end
end

-- fondo de la ventana de asedios segun el tema (nil = el de siempre)
function T.SiegeBg()
	if DEF[T.loaded] == nil then
		return nil
	end
	return ROOT .. T.loaded .. "/siege_bg.tga"
end

function T.Name(v)
	v = v or T.current
	return (L ~= nil and L["Theme_" .. v]) or NAMES_EN[v] or v
end

function T.ButtonText()
	return ((L ~= nil and L.Theme_Label) or "Theme: ") .. T.Name()
end

local driver = Turbine.UI.Control()
driver.Update = function()
	if T.reloadAt ~= nil and Turbine.Engine.GetGameTime() >= T.reloadAt then
		driver:SetWantsUpdates(false)
		T.reloadAt = nil
		if T.current ~= T.loaded and type(ReloadPlugin) == "function" then
			pcall(ReloadPlugin)
		end
	end
end
T.driver = driver

function T.Cycle(dir)
	local i = 1
	for n, x in ipairs(T.LIST) do
		if x == T.current then i = n end
	end
	i = (i - 1 + (dir or 1)) % #T.LIST + 1
	T.current = T.LIST[i]
	pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, SAVE_KEY, { theme = T.current })
	if T.current == T.loaded then
		T.reloadAt = nil
		driver:SetWantsUpdates(false)
		return
	end
	T.reloadAt = Turbine.Engine.GetGameTime() + RELOAD_DELAY
	driver:SetWantsUpdates(true)
	Turbine.Shell.WriteLine(string.format((L ~= nil and L.Theme_Reload) or "PvMP+: theme %s - reloading in %d s...", T.Name(), RELOAD_DELAY))
end

-- bloqueo de ventanas
function _G.PvMP_IsLocked()
	return storage ~= nil and storage.windows_locked == true
end

function T.LockText()
	if PvMP_IsLocked() then
		return (L ~= nil and L.Lock_On) or "Windows: locked"
	end
	return (L ~= nil and L.Lock_Off) or "Windows: unlocked"
end

function T.ToggleLock()
	if storage == nil then
		return
	end
	storage.windows_locked = not PvMP_IsLocked()
	if storage.windows_locked then
		-- esconder las barras de arrastre que esten abiertas
		for _, n in ipairs({ "OverviewWindow", "SecondaryWindow", "RecentHitsWindow", "AlertWindow", "BattleTaskWindow", "MapWindow" }) do
			local w = _G[n]
			if type(w) == "table" and type(w.DragBar) == "table" and w.DragBar.SetVisible ~= nil then
				w.DragBar.moving = false
				pcall(w.DragBar.SetVisible, w.DragBar, false)
			end
		end
	end
end
