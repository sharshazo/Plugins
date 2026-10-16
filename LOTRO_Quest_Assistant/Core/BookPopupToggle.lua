-- LOTRO_Quest_Assistant/Core/BookPopupToggle.lua
--
-- (2026-10-16, pedido del usuario) Interruptor para que el libro de mision
-- (QuestBookWindow, "Nueva mision" / "Completado") se abra solo o no al
-- aceptar o terminar una mision. Mismo patron que NarratorMute.lua: un boton
-- en el Tracker (verde = se abre solo, gris con X = no se abre), la
-- preferencia se guarda en la cuenta y se avisa por el EventBus.
-- Solo corta la apertura AUTOMATICA; el resto del addon sigue igual.
import "Turbine"

_G.BookPopup = {}
local BookPopup = _G.BookPopup

local SAVE_KEY = "LQA_BookPopup"

local enabled = true

local function Persist()
	pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, SAVE_KEY, { enabled = enabled })
end

local function Publish()
	if _G.LQA and LQA.Core and LQA.Core.EventBus then
		LQA.Core.EventBus:Publish("BOOK_POPUP_CHANGED", { enabled = enabled })
	end
end

function BookPopup.IsEnabled()
	return enabled
end

function BookPopup.SetEnabled(value)
	enabled = value and true or false
	Persist()
	Publish()
end

function BookPopup.Toggle()
	BookPopup.SetEnabled(not enabled)
end

-- Restaura la preferencia (Load es asincronico: el boton arranca en "on" y
-- se corrige con BOOK_POPUP_CHANGED, igual que el de audio).
pcall(Turbine.PluginData.Load, Turbine.DataScope.Account, SAVE_KEY, function(data)
	if type(data) == "table" and data.enabled ~= nil then
		enabled = data.enabled and true or false
		Publish()
	end
end)
