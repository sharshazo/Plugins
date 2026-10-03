-- LOTRO_Quest_Assistant/Core/LanguageSettings.lua
-- Interruptor de idioma ES/EN para toda la interfaz, pedido explicito del
-- usuario: "dejar el sistema que tenga una opcion de dejarlo en espanol o
-- ingles". No tenemos un DAT profesional en ingles separado (nuestro
-- diccionario maestro es EN->ES, no un segundo idioma independiente) --
-- pero no hace falta: cada fuente de datos del addon (Compendium, LotRO
-- Companion, WarbandsSlayer, LostLore) YA trae su texto original en ingles
-- guardado (quest.nameEN, entry.name, pt.l, entry.note), ademas de la
-- traduccion a espanol donde existe (nameES/zoneES/lES/noteES). El modo
-- "English" de este interruptor simplemente usa esos textos originales tal
-- cual, sin traducir nada nuevo.
import "Turbine"

_G.LanguageSettings = {}

local SAVE_KEY = "QuestSync_Language"

-- "ES" o "EN". Por defecto español (idioma nativo del addon).
LanguageSettings.Current = "ES"

function LanguageSettings.Initialize()
    Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(saved)
        if saved == "EN" or saved == "ES" then
            LanguageSettings.Current = saved
            if LQA and LQA.Core and LQA.Core.EventBus then
                LQA.Core.EventBus:Publish("LANGUAGE_CHANGED", { lang = LanguageSettings.Current })
            end
        end
    end)
end

function LanguageSettings.IsSpanish()
    return LanguageSettings.Current == "ES"
end

function LanguageSettings.Toggle()
    LanguageSettings.Current = (LanguageSettings.Current == "ES") and "EN" or "ES"
    Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, LanguageSettings.Current)
    LQA.Core.EventBus:Publish("LANGUAGE_CHANGED", { lang = LanguageSettings.Current })
end
