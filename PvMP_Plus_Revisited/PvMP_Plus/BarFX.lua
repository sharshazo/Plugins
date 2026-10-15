-- v4.3.13: estilos animados para la barra de rango (Opciones).
-- Estilo, color, velocidad y efectos extra se guardan por personaje (storage.bar_*).
-- Las capas son hijas de la parte llena de la barra, asi quedan recortadas a lo
-- ganado y debajo del marco y del porcentaje. El aura va alrededor del marco.
-- Se anima moviendo capas o cambiando imagenes (sin SetOpacity).

local ROOT = "PvMP_Plus_Revisited/PvMP_Plus/Resources/BarFX/"
local STEP = 0.033
local FLASH_TIME = 0.7

_G.PvMP_BarFX = {}
local B = PvMP_BarFX

B.STYLES = { "classic", "shine", "energy", "aura", "ember", "flames", "runes", "pulse", "neon", "plasma", "glitter", "aurora" }
B.COLORS = { "auto", "blue", "red", "gold", "green", "purple", "cyan", "orange", "silver", "prism" }
B.SPEEDS = { "slow", "normal", "fast" }
B.EXTRAS = { "both", "flash", "rank", "none" }
-- v4.3.14: estilo distinto mientras estas en combate ("off" = el mismo)
B.COMBAT = { "off", "shine", "energy", "aura", "ember", "flames", "runes", "pulse", "neon", "plasma", "glitter", "aurora" }
-- v4.3.15: marcos de barra (pack de imagenes) y auras alrededor de la barra
B.SKINS = { "classic", "crystal", "metal", "obsidian" }
B.AURAS = { "auto", "off", "pulse", "breath", "fire", "frost", "rainbow", "runner" }

-- medidas de cada marco: ancho de los extremos, alto y cuanto sube sobre el riel
local SKIN = {
	-- tl/tr: cuanto entra el relleno por debajo de cada extremo (su hueco transparente + 2)
	crystal = { cl = 44, cr = 44, h = 26, off = 4, tl = 12, tr = 12, color = "cyan" },
	metal = { cl = 21, cr = 20, h = 21, off = 1, tl = 6, tr = 6, color = "blue" },
	obsidian = { cl = 27, cr = 28, h = 25, off = 3, tl = 9, tr = 10, color = "orange" },
}
local RAINBOW = { "red", "orange", "gold", "green", "cyan", "blue", "purple", "silver" }

local LISTS = { style = B.STYLES, color = B.COLORS, speed = B.SPEEDS, extras = B.EXTRAS, combat = B.COMBAT, skin = B.SKINS, aura = B.AURAS }
local KEYS = { style = "bar_style", color = "bar_color", speed = "bar_speed", extras = "bar_extras", combat = "bar_combat", skin = "bar_skin", aura = "bar_aura" }
local DEFAULTS = { style = "classic", color = "auto", speed = "normal", extras = "both", combat = "off", skin = "classic", aura = "auto" }
local SPEED = { slow = 0.6, normal = 1, fast = 1.7 }
local AURA_COLOR = { blue = "blue", red = "red", gold = "gold", green = "green", purple = "purple",
	cyan = "cyan", orange = "orange", silver = "silver", prism = "silver" }

local NAMES_EN = {
	style = { classic = "Classic", shine = "Shine sweep", energy = "Flowing energy", aura = "Pulsing aura",
		ember = "Burning tip", flames = "Flames", runes = "Elven runes", pulse = "Heartbeat", neon = "Neon",
		plasma = "Plasma", glitter = "Glitter", aurora = "Aurora" },
	color = { auto = "Faction colour", blue = "Blue", red = "Red", gold = "Gold", green = "Emerald",
		purple = "Purple", cyan = "Ice", orange = "Fire", silver = "Silver", prism = "Prism (rainbow)" },
	speed = { slow = "Slow", normal = "Normal", fast = "Fast" },
	extras = { both = "Flash + rank-up glow", flash = "Flash on gain only", rank = "Rank-up glow only", none = "None" },
	combat = { off = "No change" },
	skin = { classic = "Classic", crystal = "Elven crystal", metal = "Minimal metal", obsidian = "Fire obsidian" },
	aura = { auto = "By style", off = "No aura", pulse = "Pulse", breath = "Breathing", fire = "Living fire",
		frost = "Frost", rainbow = "Rainbow", runner = "Running spark" },
}
local LABELS_EN = { style = "Bar style: ", color = "Bar colour: ", speed = "Animation speed: ", extras = "Bar effects: ", combat = "In combat: ", skin = "Frame: ", aura = "Aura: " }

-- a = capa 1, b = capa 2. tex+tile+v = textura que se desplaza (px/s, negativo = a la derecha)
-- frames+n+fps = cambia imagenes; tri = va y vuelve en ese periodo
local CFG = {
	classic = {},
	shine = { shine = true },
	energy = { a = { tex = "energy", tile = 16, v = 30 } },
	aura = { aura = 1.8 },
	ember = { tip = true },
	flames = { a = { frames = "flame_", n = 8, fps = 12 } },
	runes = { a = { tex = "runes", tile = 112, v = 18 } },
	pulse = { beat = true },
	neon = { a = { frames = "neon_", n = 6, tri = 1.2 }, aura = 1.2 },
	plasma = { a = { tex = "plasma_a", tile = 64, v = 40 }, b = { tex = "plasma_b", tile = 48, v = -28 } },
	glitter = { a = { frames = "glitter_", n = 8, fps = 8 } },
	aurora = { a = { tex = "aurora_a", tile = 160, v = 14 }, b = { tex = "aurora_b", tile = 112, v = -10 } },
}

local function InList(list, v)
	for i, x in ipairs(list) do
		if x == v then return i end
	end
	return nil
end

function B.Get(kind)
	local v = storage ~= nil and storage[KEYS[kind]] or nil
	if InList(LISTS[kind], v) then return v end
	return DEFAULTS[kind]
end

function B.Set(kind, v)
	if LISTS[kind] == nil or not InList(LISTS[kind], v) then return end
	if storage ~= nil then storage[KEYS[kind]] = v end
	B.Apply()
end

function B.Cycle(kind, dir)
	local list = LISTS[kind]
	if list == nil then return end
	local i = InList(list, B.Get(kind)) or 1
	i = (i - 1 + (dir or 1)) % #list + 1
	B.Set(kind, list[i])
end

function B.Name(kind, v)
	v = v or B.Get(kind)
	if kind == "combat" and v ~= "off" then
		return B.Name("style", v)
	end
	return (L ~= nil and L["BarFX_" .. kind .. "_" .. v]) or NAMES_EN[kind][v] or v
end

function B.ButtonText(kind)
	return ((L ~= nil and L["BarFX_Label_" .. kind]) or LABELS_EN[kind]) .. B.Name(kind)
end

local function Tri(t, period, n)
	local p = (t % period) / period
	local tri = p < 0.5 and p * 2 or (1 - p) * 2
	return 1 + math.floor(tri * (n - 1) + 0.5)
end

local function Bg(lbl, key)
	if lbl.key ~= key then
		lbl:SetBackground(ROOT .. key .. ".tga")
		lbl.key = key
	end
end

local function Show(lbl, on)
	if lbl:IsVisible() ~= on then lbl:SetVisible(on) end
end

local function Place(lbl, x, y, w, h)
	x, y = math.floor(x), math.floor(y)
	if lbl:GetLeft() ~= x or lbl:GetTop() ~= y then lbl:SetPosition(x, y) end
	if w ~= nil and (lbl:GetWidth() ~= w or lbl:GetHeight() ~= h) then lbl:SetSize(w, h) end
end

local function FactionColor()
	if B.origFill ~= nil and string.find(B.origFill, "/Red/", 1, true) then return "red" end
	return "blue"
end

local function RankGlow()
	local e = B.Get("extras")
	return (e == "both" or e == "rank") and B.pct ~= nil and B.pct >= 0.9 and B.pct < 1
end

-- estilo que toca ahora (el de combate si estas peleando)
local function CurrentStyle()
	local c = B.Get("combat")
	if c ~= "off" and B.inCombat then
		return c
	end
	return B.Get("style")
end

local function CheckCombat(now)
	if B.Get("combat") == "off" then
		B.inCombat = false
		return
	end
	if B.nextCombatCheck ~= nil and now < B.nextCombatCheck and now >= B.nextCombatCheck - 1 then
		return
	end
	B.nextCombatCheck = now + 0.25
	local ok, res = pcall(function()
		local p = Turbine.Gameplay.LocalPlayer.GetInstance()
		return p ~= nil and p.IsInCombat ~= nil and p:IsInCombat() == true
	end)
	B.inCombat = ok and res == true
end

local function Needed()
	local a = B.Get("aura")
	return B.Get("style") ~= "classic" or B.Get("combat") ~= "off" or (a ~= "auto" and a ~= "off") or RankGlow() or
		B.flashEnd > Turbine.Engine.GetGameTime()
end

local function HideAll()
	for _, lbl in pairs(B.layers) do Show(lbl, false) end
	for _, lbl in pairs(B.aura) do Show(lbl, false) end
	if B.runner ~= nil then Show(B.runner, false) end
end

-- capa: textura que se desplaza o imagenes que cambian, ancho = parte llena
local function Layer(lbl, c, fw, t)
	if c == nil or fw <= 0 then
		Show(lbl, false)
		return
	end
	if c.tex ~= nil then
		Bg(lbl, c.tex)
		local off = (t * math.abs(c.v)) % c.tile
		local x = c.v > 0 and -off or (off - c.tile)
		Place(lbl, x, 0, fw + c.tile, 14)
	else
		local f = c.tri ~= nil and Tri(t, c.tri, c.n) or (math.floor(t * c.fps) % c.n + 1)
		Bg(lbl, c.frames .. f)
		Place(lbl, 0, 0, fw, 14)
	end
	Show(lbl, true)
end

local function AuraFrame(color, f)
	local ov = B.ov
	local s, e = ov.bar_start, ov.bar_end
	Bg(B.aura.l, "aura_" .. color .. "_l_" .. f)
	Bg(B.aura.m, "aura_" .. color .. "_m_" .. f)
	Bg(B.aura.r, "aura_" .. color .. "_r_" .. f)
	Place(B.aura.l, s - 8, 20, 8, 28)
	Place(B.aura.m, s, 20, e - s, 28)
	Place(B.aura.r, e, 20, 8, 28)
	for _, lbl in pairs(B.aura) do Show(lbl, true) end
end

local function Aura(on, color, period, t)
	if not on then
		for _, lbl in pairs(B.aura) do Show(lbl, false) end
		return
	end
	AuraFrame(color, Tri(t, period, 6))
end

-- color base del aura: el elegido, si no el del marco, si no el del bando
local function AuraColor()
	local c = B.Get("color")
	if c == "auto" then
		local sk = SKIN[B.Get("skin")]
		c = sk ~= nil and sk.color or FactionColor()
	end
	return AURA_COLOR[c] or "blue"
end

-- auras extra (v4.3.15)
local function FancyAura(mode, t)
	if mode == "pulse" then
		AuraFrame(AuraColor(), Tri(t, 1.6, 6))
	elseif mode == "breath" then
		AuraFrame(AuraColor(), Tri(t, 3.6, 6))
	elseif mode == "fire" then
		-- parpadeo irregular entre naranja y rojo
		local n = (math.sin(t * 23) + math.sin(t * 37 + 1) + 2) / 4
		AuraFrame((math.sin(t * 5) > 0.2) and "red" or "orange", 2 + math.floor(n * 4 + 0.5))
	elseif mode == "frost" then
		AuraFrame((math.floor(t / 1.2) % 2 == 0) and "cyan" or "silver", 2 + math.floor((math.sin(t * 2.6) + 1) * 1.5 + 0.5))
	elseif mode == "rainbow" then
		AuraFrame(RAINBOW[math.floor(t * 1.5) % #RAINBOW + 1], Tri(t, 1.0, 6))
	elseif mode == "runner" then
		AuraFrame(AuraColor(), 2)
	end
	-- destello que recorre el borde de la barra
	local r = B.runner
	if r == nil then
		return
	end
	if mode ~= "runner" then
		Show(r, false)
		return
	end
	local ov = B.ov
	local s, e = ov.bar_start - 3, ov.bar_end + 3
	local w, h = e - s, 18
	local per = 2 * w + 2 * h
	local d = (t * 260) % per
	local x, y
	if d < w then
		x, y = s + d, 25
	elseif d < w + h then
		x, y = e, 25 + (d - w)
	elseif d < 2 * w + h then
		x, y = e - (d - w - h), 43
	else
		x, y = s, 43 - (d - 2 * w - h)
	end
	Bg(r, "runner")
	Place(r, x - 12, y - 6)
	Show(r, true)
end

local last = -1
local function Tick()
	local ov = B.ov
	local now = Turbine.Engine.GetGameTime()
	if now >= last and now - last < STEP then
		return
	end
	local dt = (last < 0 or now < last) and 0 or math.min(now - last, 0.25)
	last = now
	if not Needed() then
		HideAll()
		B.driver:SetWantsUpdates(false)
		return
	end
	if not (ov:IsVisible() and ov.panel:IsVisible()) then
		return
	end
	B.t = B.t + dt * (SPEED[B.Get("speed")] or 1)
	local t = B.t
	CheckCombat(now)
	local cfg = CFG[CurrentStyle()] or CFG.classic
	local fw = ov.filled_bar:GetWidth()
	local Ly = B.layers

	Layer(Ly.a, cfg.a, fw, t)
	Layer(Ly.b, cfg.b, fw, t)

	-- brillo que cruza la barra y luego pausa
	if cfg.shine and fw > 0 then
		local cyc = (fw + 48) / 500 + 1.2
		local x = -48 + (t % cyc) * 500
		Bg(Ly.shine, "shine")
		Place(Ly.shine, x, 0)
		Show(Ly.shine, x < fw)
	else
		Show(Ly.shine, false)
	end

	-- punta ardiente con chispas
	if cfg.tip and fw >= 4 then
		Bg(Ly.tip, "tip_" .. Tri(t, 0.8, 6))
		Place(Ly.tip, fw - 24, 0)
		Bg(Ly.spark, "spark_" .. (math.floor(t * 14) % 8 + 1))
		Place(Ly.spark, fw - 48, 0)
		Show(Ly.tip, true)
		Show(Ly.spark, true)
	else
		Show(Ly.tip, false)
		Show(Ly.spark, false)
	end

	-- latido (doble golpe)
	local level = 0
	if cfg.beat and fw > 0 then
		local p = (t % 1.4) / 1.4
		local b = math.max(math.exp(-((p - 0.07) / 0.045) ^ 2), 0.7 * math.exp(-((p - 0.27) / 0.05) ^ 2))
		level = math.floor(b * 6 + 0.5)
	end
	if level > 0 then
		Bg(Ly.pulse, "white_" .. level)
		Place(Ly.pulse, 0, 0, fw, 14)
	end
	Show(Ly.pulse, level > 0)

	-- destello al ganar puntos (tiempo real, no depende de la velocidad)
	local fl = 0
	if fw > 0 and B.flashEnd > now then
		fl = math.min(8, math.ceil((B.flashEnd - now) / FLASH_TIME * 8))
	end
	if fl > 0 then
		Bg(Ly.flash, "white_" .. fl)
		Place(Ly.flash, 0, 0, fw, 14)
	end
	Show(Ly.flash, fl > 0)

	-- aura: dorada si falta poco para subir de rango, si no la del estilo
	local amode = B.Get("aura")
	if RankGlow() then
		Aura(true, "gold", 1.0, now)
		if B.runner ~= nil then Show(B.runner, false) end
	elseif amode == "off" then
		Aura(false)
		if B.runner ~= nil then Show(B.runner, false) end
	elseif amode ~= "auto" then
		FancyAura(amode, t)
	elseif cfg.aura ~= nil then
		Aura(true, AuraColor(), cfg.aura, t)
	else
		Aura(false)
	end
end

-- relleno y fondo: con un marco van solo por dentro de los extremos (asi no
-- asoman por las puntas de la gema y el progreso se ve desde el 0 %)
function B.FitFill()
	local ov = B.ov
	local sk = SKIN[B.Get("skin")]
	local p = B.pct or 0
	if p < 0 then p = 0 elseif p > 1 then p = 1 end
	local a, len
	if sk == nil then
		a, len = ov.bar_start, ov.bar_length
	else
		a = (ov.bar_start - 4) + sk.cl - sk.tl
		len = math.max(0, ((ov.bar_end + 4 - sk.cr) + sk.tr) - a)
	end
	ov.empty_bar:SetPosition(a, 27)
	ov.empty_bar:SetWidth(len)
	ov.filled_bar:SetPosition(a, 27)
	ov.filled_bar:SetWidth(math.floor(len * p + 1e-9))
end

-- marco de la barra: usa los controles originales (bar_left_end, bar_middle,
-- bar_right_end, empty_bar) para que queden debajo del porcentaje
function B.LayoutSkin()
	local ov = B.ov
	if ov == nil or ov.bar_left_end == nil or ov.bar_middle == nil or ov.bar_right_end == nil then
		return
	end
	local key = B.Get("skin")
	local sk = SKIN[key]
	local s, e = ov.bar_start, ov.bar_end
	if sk == nil then
		if Bar_Builder ~= nil then
			ov.bar_left_end:SetBackground(Bar_Builder[2])
			ov.bar_right_end:SetBackground(Bar_Builder[3])
			ov.bar_middle:SetBackground(Bar_Builder[4])
			ov.empty_bar:SetBackground(Bar_Builder[0])
		end
		ov.bar_left_end:SetSize(6, 18)
		ov.bar_left_end:SetPosition(s - 3, 25)
		ov.bar_right_end:SetSize(6, 18)
		ov.bar_right_end:SetPosition(e - 3, 25)
		ov.bar_middle:SetSize(ov.bar_length - 6, 18)
		ov.bar_middle:SetPosition(s + 3, 25)
		B.skinShown = nil
		if B.fitted then
			B.fitted = false
			B.FitFill()
		end
		return
	end
	local dir = ROOT .. "Skins/" .. key .. "/"
	if B.skinShown ~= key then
		ov.bar_left_end:SetBackground(dir .. "cap_l.tga")
		ov.bar_right_end:SetBackground(dir .. "cap_r.tga")
		ov.bar_middle:SetBackground(dir .. "mid.tga")
		ov.empty_bar:SetBackground(dir .. "empty.tga")
		B.skinShown = key
	end
	local lx = s - 4
	local rx = e + 4 - sk.cr
	ov.bar_left_end:SetSize(sk.cl, sk.h)
	ov.bar_left_end:SetPosition(lx, 25 - sk.off)
	ov.bar_right_end:SetSize(sk.cr, sk.h)
	ov.bar_right_end:SetPosition(rx, 25 - sk.off)
	ov.bar_middle:SetSize(math.max(0, rx - (lx + sk.cl)), 18)
	ov.bar_middle:SetPosition(lx + sk.cl, 25)
	B.fitted = true
	B.FitFill()
end

function B.Apply()
	if B.ov == nil then return end
	local c = B.Get("color")
	local sk = B.Get("skin")
	local fill = (c == "auto") and B.origFill or (ROOT .. "fill_" .. c .. ".tga")
	if c == "auto" and SKIN[sk] ~= nil then
		fill = ROOT .. "Skins/" .. sk .. "/fill.tga"
	end
	pcall(B.LayoutSkin)
	if fill ~= nil and fill ~= B.fill then
		B.ov.filled_bar:SetBackground(fill)
		B.fill = fill
	end
	HideAll()
	last = -1
	B.driver:SetWantsUpdates(Needed())
end

function B.OnProgress(ov, p)
	if type(p) ~= "number" then return end
	local len = ov.bar_length
	local e = B.Get("extras")
	if B.pct ~= nil and p > B.pct and len == B.len and (e == "both" or e == "flash") then
		B.flashEnd = Turbine.Engine.GetGameTime() + FLASH_TIME
	end
	B.pct, B.len = p, len
	if B.fitted then
		B.FitFill()	-- con marco, el relleno va por dentro de los extremos
	end
	if B.driver ~= nil and Needed() then B.driver:SetWantsUpdates(true) end
end

function B.Attach(ov)
	if ov == nil or ov.filled_bar == nil or ov.panel == nil or B.ov ~= nil then
		return
	end
	B.ov = ov
	B.t = 0
	B.flashEnd = 0
	B.origFill = Bar_Builder ~= nil and Bar_Builder[1] or nil
	if (ov.bar_length or 0) > 0 then
		B.pct = ov.filled_bar:GetWidth() / ov.bar_length	-- aprox. hasta el proximo cambio
	end
	B.fill = B.origFill

	local function mk(parent, w, h)
		local l = Turbine.UI.Label()
		l:SetParent(parent)
		l:SetSize(w, h)
		l:SetMouseVisible(false)
		l:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
		l:SetVisible(false)
		return l
	end
	local fb = ov.filled_bar
	B.layers = {
		a = mk(fb, 0, 14), b = mk(fb, 0, 14), tip = mk(fb, 24, 14), spark = mk(fb, 48, 14),
		shine = mk(fb, 48, 14), pulse = mk(fb, 0, 14), flash = mk(fb, 0, 14),
	}
	B.aura = { l = mk(ov.panel, 8, 28), m = mk(ov.panel, 0, 28), r = mk(ov.panel, 8, 28) }
	for _, lbl in pairs(B.aura) do
		pcall(lbl.SetZOrder, lbl, -1)	-- detras de iconos y marco si el juego lo respeta
	end
	B.runner = mk(ov.panel, 24, 12)

	-- al cambiar el ancho de la ventana se vuelve a colocar el marco elegido
	local origLen = ov.UpdateBarLength
	if origLen ~= nil then
		ov.UpdateBarLength = function(self)
			origLen(self)
			if B.Get("skin") ~= "classic" then
				pcall(B.LayoutSkin)
			end
		end
	end

	-- avisar cuando cambia el progreso (para el destello y el aura de rango)
	local orig = ov.UpdateProgressBar
	ov.UpdateProgressBar = function(self, p)
		orig(self, p)
		pcall(B.OnProgress, self, p)
	end

	local driver = Turbine.UI.Control()
	driver.Update = function()
		local ok, err = pcall(Tick)
		if not ok then
			driver:SetWantsUpdates(false)
			Turbine.Shell.WriteLine("PvMP+ barra: " .. tostring(err))
		end
	end
	B.driver = driver
	B.Apply()
end
