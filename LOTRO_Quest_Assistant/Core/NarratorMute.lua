-- LOTRO_Quest_Assistant/Core/NarratorMute.lua
--
-- Interruptor on/off del Narrador_IA (pedido explicito del usuario,
-- 2026-09-05: un boton en el Tracker, verde = activo, un click lo pasa a
-- gris/apagado, click de nuevo lo reactiva). Este addon no puede silenciar
-- nada por si mismo -- Turbine no expone audio ni forma de hablarle a un
-- proceso Windows aparte (misma limitacion ya documentada en la cabecera de
-- NarratorBridge.lua/LOTRO_Chat_Narrator/Main.lua) -- asi que ACA solo se
-- guarda la preferencia en el mismo tipo de archivo Turbine.PluginData que
-- ya usa el resto del puente, y Narrador_IA (app externa) es quien de
-- verdad deja de reproducir/sondear mientras este en off.
import "Turbine"

_G.NarratorMute = {}
local NarratorMute = _G.NarratorMute

-- Cuenta (no personaje): es una preferencia de audio del jugador, no algo
-- ligado a un personaje puntual -- mismo criterio que LOTRO_Narrator_Feed/
-- LOTRO_Narrator_PlayRequest, que tambien son de cuenta.
local MUTE_KEY = "LOTRO_Narrator_Mute"

local muted = false

local function Persist()
	Turbine.PluginData.Save(Turbine.DataScope.Account, MUTE_KEY, { muted = muted })
end

function NarratorMute.IsMuted()
	return muted
end

function NarratorMute.SetMuted(value)
	value = value and true or false
	muted = value
	Persist()
	if _G.LQA and LQA.Core and LQA.Core.EventBus then
		LQA.Core.EventBus:Publish("NARRATOR_MUTE_CHANGED", { muted = muted })
	end
end

function NarratorMute.Toggle()
	NarratorMute.SetMuted(not muted)
end

-- Restaura la preferencia guardada la proxima vez que se abre el juego.
-- Turbine.PluginData.Load es asincronico -- el boton (creado sincronicamente
-- en QuestTrackerHUD.lua) arranca dibujado en "on" por defecto y se corrige
-- solo cuando este callback llega, via el mismo evento NARRATOR_MUTE_CHANGED
-- que usa SetMuted (mismo patron ya probado por QuestStateManager.Initialize/
-- LanguageSettings). No se llama Persist() aca: no hace falta reescribir el
-- archivo con el mismo valor que ya tiene apenas se termina de leer.
Turbine.PluginData.Load(Turbine.DataScope.Account, MUTE_KEY, function(data)
	if data and data.muted ~= nil then
		muted = data.muted and true or false
		if _G.LQA and LQA.Core and LQA.Core.EventBus then
			LQA.Core.EventBus:Publish("NARRATOR_MUTE_CHANGED", { muted = muted })
		end
	end
end)
