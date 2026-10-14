-- v4.3.4: auras estilo LUI para los iconos de PvMP+.
-- Un borde brillante alrededor del icono:
--   * fortalezas y mejoras (arbol, Gary, draco, Carrock, corona, inferioridad):
--     azul = Pueblos Libres, rojo = Monstruos. Cuando aparece un icono nuevo
--     (fortaleza tomada, mejora ganada) late 8 segundos y luego queda suave.
--   * Gaergoth: rojo mientras cuenta, ambar latiendo los ultimos 5 minutos,
--     verde latiendo cuando ya esta disponible.
-- Se anima cambiando entre 6 imagenes (sin SetOpacity, que da problemas).
-- Apagar/encender: /pvmp+ auras off | /pvmp+ auras on (se guarda por cuenta)

local ROOT = "PvMP_Plus_Revisited/PvMP_Plus/Resources/Auras/"
local FRAMES = 6
local STATIC_FRAME = 3
local PROC_TIME = 8
local PERIOD = 1.2
local STEP = 0.08
local SIZES = { [15] = true, [24] = true, [32] = true }
local SAVE_KEY = "PvMP_Plus_Auras"

_G.PvMP_Auras = { list = {}, enabled = true }
local A = PvMP_Auras

pcall(function()
	local saved = Turbine.PluginData.Load(Turbine.DataScope.Account, SAVE_KEY)
	if type(saved) == "table" and saved.enabled == false then
		A.enabled = false
	end
end)

function A.SetEnabled(on)
	A.enabled = (on == true)
	pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, SAVE_KEY, { enabled = A.enabled })
end

-- target: el icono (Label); color: blue | red | gold | green | amber
-- opts.auto = false: no late solo al aparecer (lo controla quien lo crea)
function A.Attach(target, color, opts)
	if target == nil or target.GetParent == nil then
		return nil
	end
	local parent = target:GetParent()
	if parent == nil then
		return nil
	end
	local lbl = Turbine.UI.Label()
	lbl:SetParent(parent)
	lbl:SetMouseVisible(false)
	lbl:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
	lbl:SetVisible(false)
	local aura = {
		label = lbl, target = target, color = color,
		auto = not (opts ~= nil and opts.auto == false),
		mode = (opts ~= nil and opts.mode) or "static",
		wasVisible = nil, procUntil = 0, shown = "", size = -1,
	}
	A.list[#A.list + 1] = aura
	return aura
end

-- mode: "static" | "pulse" | "off"
function A.Set(aura, color, mode)
	if aura == nil then
		return
	end
	if color ~= nil then aura.color = color end
	if mode ~= nil then aura.mode = mode end
end

local last = -1
local function Tick()
	local now = Turbine.Engine.GetGameTime()
	if now - last < STEP and now >= last then
		return
	end
	last = now
	local phase = (now % PERIOD) / PERIOD
	local tri = phase < 0.5 and phase * 2 or (1 - phase) * 2
	local pulseFrame = 1 + math.floor(tri * (FRAMES - 1) + 0.5)
	for _, aura in ipairs(A.list) do
		local t = aura.target
		local lbl = aura.label
		local raw = t:IsVisible()
		if aura.wasVisible == false and raw and aura.auto then
			aura.procUntil = now + PROC_TIME
		end
		aura.wasVisible = raw
		local w, h = t:GetWidth(), t:GetHeight()
		local show = A.enabled and raw and aura.mode ~= "off" and w == h and SIZES[w] == true
		if not show then
			if lbl:IsVisible() then
				lbl:SetVisible(false)
			end
		else
			if aura.size ~= w then
				lbl:SetSize(w, h)
				aura.size = w
				aura.shown = ""
			end
			local x, y = t:GetLeft(), t:GetTop()
			if lbl:GetLeft() ~= x or lbl:GetTop() ~= y then
				lbl:SetPosition(x, y)
			end
			local f = STATIC_FRAME
			if aura.mode == "pulse" or now < aura.procUntil then
				f = pulseFrame
			end
			local key = aura.color .. "_" .. w .. "_" .. f
			if key ~= aura.shown then
				lbl:SetBackground(ROOT .. key .. ".tga")
				aura.shown = key
			end
			if not lbl:IsVisible() then
				lbl:SetVisible(true)
			end
		end
	end
end

local driver = Turbine.UI.Control()
driver:SetWantsUpdates(true)
driver.Update = function()
	local ok, err = pcall(Tick)
	if not ok then
		driver:SetWantsUpdates(false)
		Turbine.Shell.WriteLine("PvMP+ auras: " .. tostring(err))
	end
end
A.driver = driver

-- auras para los iconos del panel principal
function A.AttachOverview(ov)
	if ov == nil then
		return
	end
	for i = 1, 5 do
		A.Attach(ov["freep_keep_" .. i], "blue")
		A.Attach(ov["creep_keep_" .. i], "red")
	end
	for _, n in ipairs({ "tree", "gary", "drake", "carrock", "crown", "outnumbered" }) do
		A.Attach(ov["freep_" .. n .. "_icon"], "blue")
		A.Attach(ov["creep_" .. n .. "_icon"], "red")
	end
end
