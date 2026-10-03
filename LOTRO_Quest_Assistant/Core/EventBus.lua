-- LOTRO_Quest_Assistant/Core/EventBus.lua
_G.LQA = _G.LQA or {}
LQA.Core = LQA.Core or {}
LQA.Data = LQA.Data or {}
LQA.UI = LQA.UI or {}
LQA.Map = LQA.Map or {}
LQA.Nav = LQA.Nav or {}
LQA.Localization = LQA.Localization or {}
LQA.Debug = LQA.Debug or {}
-- Interruptor unico de depuracion para todo el addon (EventBus, parser de
-- chat, resolver, MoorMap). En false por defecto para uso real: docenas de
-- lineas de color por cada mensaje de chat / cambio de estado son utiles
-- para diagnosticar pero son ruido puro en una sesion de juego normal.
-- Cambiar a true solo cuando se este investigando un problema.
--
-- Prendido temporalmente 2026-09-04 para diagnosticar "el libro no se abre
-- al aceptar mision"/"quedan misiones completadas en el Tracker" -- el
-- libro se confirmo funcionando de nuevo, pedido explicito del usuario de
-- sacar el ruido de chat. Vuelto a false.
--
-- Prendido DE NUEVO 2026-09-05: mismo sintoma reportado otra vez. El log
-- confirmo que NO era un bug de codigo -- la mision de prueba ya estaba
-- marcada activa en el estado GUARDADO del addon (residuo de pruebas
-- anteriores de esta misma sesion), asi que SetQuestActive era un no-op
-- legitimo (nunca publica QUEST_JUST_ACCEPTED para una mision que el
-- addon ya cree activa). Confirmado con Desmarcar+Activar manual: el
-- libro se abrio bien. Vuelto a false otra vez.
--
-- Prendido DE NUEVO 2026-09-07: GatherCaptureButton no aparece al recolectar
-- jarrones (Erudito) ni cultivos de granja (Granjero/Farmer) -- solo funciona
-- con Minero. GatherEventParser.PATTERNS.NODE ("Tomando los contenidos de
-- X...") SOLO fue confirmado en vivo con mineria (ver Arquitectura_GatherSync.md
-- #3.2) -- nunca se capturo el chat real de Erudito/Granjero, asi que es muy
-- probable que el patron no coincida con esos mensajes (verbo distinto:
-- "buscar" en un jarron no es lo mismo que "tomar el contenido" de una veta).
-- Con esto en true, cada linea de chat que llega a GatherEventParser se
-- imprime en celeste ("GatherSync CHAT INTERCEPT: ...") -- hace falta que el
-- jugador recoja un jarron y un cultivo y pegue el texto exacto que aparece
-- para poder agregar el patron correcto.
--
-- VUELTO A false (2026-09-07): el flujo de Erudito/Granjero/Minero/Leñador
-- ya se valido extensamente en esta sesion (auditoria completa de nodos,
-- items y tiers contra datos reales de MoorMap) -- el pedido del usuario de
-- "sacar los ruidos del chat" confirma que ya no hace falta el diagnostico
-- linea-por-linea. Los mensajes de confirmacion de GatherSync que estaban
-- "siempre visibles" (no gateados) mientras se validaba el flujo end-to-end
-- ahora tambien quedan detras de este flag, ver GatherEventParser.lua,
-- GatherPointsStore.lua y LocationAdapter.lua.
-- Vuelto a false (2026-09-07, tercera vez el mismo dia): la causa real de
-- "el item no dispara el popup" se encontro con el diagnostico byte-a-byte
-- -- los items adquiridos en LOTRO son links clickeables con metadatos
-- incrustados, no texto plano ("Has adquirido: [X]." visible medía 204
-- bytes reales) -- GatherEventParser.lua ahora busca el nombre del item
-- como substring en vez de asumir un formato exacto. Confirmado funcionando
-- en vivo (captura real: "GatherSync: punto nuevo guardado -> Campo de
-- arándanos"). El bug de mapa equivocado (Mossward/Musgovilla) tambien se
-- encontro y corrigio en MoorMapZoneResolver.lua.
LQA.Debug.Enabled = false

LQA.Core.EventBus = {
    listeners = {}
}

function LQA.Core.EventBus:Subscribe(eventName, callback)
    if not self.listeners[eventName] then
        self.listeners[eventName] = {}
    end
    table.insert(self.listeners[eventName], callback)
end

function LQA.Core.EventBus:Publish(eventName, data)
    if LQA.Debug.Enabled then
        -- BUG (escaneo 2026-08-18): este texto no tenia el prefijo "QuestSync:"
        -- ni las etiquetas <rgb=...> que Main.lua usa para reconocer y
        -- descartar nuestros propios mensajes de depuracion (ver OnChatReceived
        -- en Main.lua). Sin eso, CADA publicacion de evento se reenviaba al
        -- parser de chat como si fuera un mensaje real del juego -- ruido y
        -- trabajo de mas en cada cambio de estado, con cada nuevo evento
        -- generando otro mas (aunque no en bucle infinito, si acumulativo).
        local debugStr = "<rgb=#888888>QuestSync DEBUG: [EventBus] " .. tostring(eventName)
        if type(data) == "table" then
            if data.questName then debugStr = debugStr .. " | Quest: " .. tostring(data.questName) end
            if data.description then debugStr = debugStr .. " | Obj: " .. tostring(data.description) end
            if data.progressCurrent then debugStr = debugStr .. " | Prog: " .. tostring(data.progressCurrent) .. "/" .. tostring(data.progressTotal) end
            if data.status then debugStr = debugStr .. " | Status: " .. tostring(data.status) end
        end
        debugStr = debugStr .. "</rgb>"
        import "Turbine"
        Turbine.Shell.WriteLine(debugStr)
    end

    if self.listeners[eventName] then
        for _, callback in ipairs(self.listeners[eventName]) do
            callback(data)
        end
    end
end
