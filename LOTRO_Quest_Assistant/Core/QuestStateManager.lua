-- LOTRO_Quest_Assistant/Core/QuestStateManager.lua
import "Turbine"

_G.QuestStateManager = {}

-- Turbine.DataScope.Character ya aisla el guardado por personaje/servidor,
-- asi que una clave fija basta (no hace falta incluir el nombre del jugador).
local SAVE_KEY = "QuestSync_QuestState"

QuestStateManager.State = {
    active = {},   -- active[ndx] = { status="ACTIVE", progress="...", currentStage=1, lastChatText="..." }
    completed = {},
    tracked = nil,
    zone = nil,    -- (2026-10-01) zona del Tracker al salir (ver UI/QuestTrackerHUD.lua)
    fxOff = nil    -- (2026-10-01) true = efectos de fuego del Tracker apagados (/trackerfuego)
}

function QuestStateManager.Initialize()
    -- Inicializacion limpia primero...
    QuestStateManager.State.active = {}
    QuestStateManager.State.completed = {}
    QuestStateManager.State.tracked = nil
    QuestStateManager.State.zone = nil
    QuestStateManager.State.fxOff = nil

    -- ...y luego se restaura lo guardado de una sesion anterior. La carga es
    -- asincrona (el callback puede llegar antes o despues de que se cree la
    -- UI), asi que al terminar publicamos QUEST_STATE_CHANGED para forzar un
    -- refresco tanto si la ventana/HUD ya existen como si se crean despues.
    Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(loadedData)
        if loadedData and type(loadedData) == "table" then
            if type(loadedData.active) == "table" then
                QuestStateManager.State.active = loadedData.active
            end
            if type(loadedData.completed) == "table" then
                QuestStateManager.State.completed = loadedData.completed
            end
            QuestStateManager.State.tracked = loadedData.tracked
            if type(loadedData.zone) == "string" then
                QuestStateManager.State.zone = loadedData.zone
            end
            if loadedData.fxOff == true then
                QuestStateManager.State.fxOff = true
            end

            local activeCount = 0
            for k, v in pairs(QuestStateManager.State.active) do activeCount = activeCount + 1 end
            local completedCount = 0
            for k, v in pairs(QuestStateManager.State.completed) do completedCount = completedCount + 1 end
            Turbine.Shell.WriteLine("<rgb=#00FFFF>QuestSync: Progreso restaurado del guardado -> " ..
                tostring(activeCount) .. " activas, " .. tostring(completedCount) .. " completadas.</rgb>")

            if LQA and LQA.Core and LQA.Core.EventBus then
                LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", {})
            end
        end
    end)
end

function QuestStateManager.Save()
    Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, QuestStateManager.State)
end

function QuestStateManager.SetQuestActive(ndx)
    if not ndx then return end
    
    if not QuestStateManager.State.active[ndx] then
        -- Si es una mision repetible que ya se habia completado antes,
        -- limpiar esa marca al volver a aceptarla; si no, GetQuestState
        -- la reportaria como COMPLETED para siempre (esa comprobacion va
        -- antes que ACTIVE).
        QuestStateManager.State.completed[ndx] = nil

        QuestStateManager.State.active[ndx] = {
            status = "ACTIVE",
            progress = "",
            currentStage = 1,
            lastUpdate = Turbine.Engine.GetGameTime()
        }
        QuestStateManager.State.tracked = ndx
        QuestStateManager.Save()
        
        local quest = QuestDB.quests[ndx]
        if quest then
            local esName = QuestLocResolver.GetQuestNameES(ndx, quest.nameEN)
            Turbine.Shell.WriteLine("<rgb=#00FF00>QuestSync: Estado actualizado -> ACTIVA (" .. esName .. ")</rgb>")
        end
        
        LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", {ndx=ndx, status="ACTIVE"})
        -- Evento aparte de QUEST_STATE_CHANGED (2026-08-28, para
        -- UI/QuestBookWindow.lua): este bloque solo corre la PRIMERA vez que
        -- se acepta la mision (esta funcion es un no-op si ya estaba en
        -- active[], ver el "if not ... then" que envuelve todo el cuerpo),
        -- asi que este evento es garantia de "aceptada de verdad ahora", sin
        -- el falso positivo que tendria escuchar QUEST_STATE_CHANGED
        -- directamente (QuestEventParser tambien publica status=ACTIVE al
        -- REAFIRMAR una mision ya activa via el camino de texto de
        -- objetivo/narrativa, ver el fallback al final de ese archivo).
        LQA.Core.EventBus:Publish("QUEST_JUST_ACCEPTED", {ndx=ndx})
    end
end

function QuestStateManager.UpdateProgress(ndx, progressText)
    if QuestStateManager.State.active[ndx] then
        QuestStateManager.State.active[ndx].progress = progressText
        QuestStateManager.State.active[ndx].lastUpdate = Turbine.Engine.GetGameTime()
        QuestStateManager.Save()
        LQA.Core.EventBus:Publish("QUEST_PROGRESS", {ndx=ndx, progress=progressText})
    end
end

function QuestStateManager.SetQuestCompleted(ndx)
    if not ndx then return end

    -- BUG (escaneo 2026-08-18): esta funcion solo actuaba si la mision ya
    -- estaba en active[] -- eso significa que si la deteccion de ACEPTADA
    -- fallo por cualquier motivo (mensaje perdido, mision aceptada antes de
    -- abrir el addon, etc.), el mensaje de COMPLETADA tampoco hacia nada
    -- (mismo punto ciego, no solo el marcado manual de mas abajo). Se quita
    -- la condicion: completar una mision es valido este o no estuviera
    -- marcada activa antes.
    QuestStateManager.State.active[ndx] = nil
    QuestStateManager.State.completed[ndx] = true
    QuestStateManager.Save()

    local quest = QuestDB.quests[ndx]
    if quest then
        local esName = QuestLocResolver.GetQuestNameES(ndx, quest.nameEN)
        Turbine.Shell.WriteLine("<rgb=#00FF00>QuestSync: Estado actualizado -> COMPLETADA (" .. esName .. ")</rgb>")

        -- Siguiente quest logic
        if quest.next_ and #quest.next_ > 0 then
            for _, nextNdx in ipairs(quest.next_) do
                local nextQ = QuestDB.quests[nextNdx]
                if nextQ then
                    local nName = QuestLocResolver.GetQuestNameES(nextNdx, nextQ.nameEN)
                    Turbine.Shell.WriteLine("<rgb=#00FFFF>QuestSync: Siguiente etapa disponible -> " .. nName .. "</rgb>")
                end
            end
        end
    end

    LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", {ndx=ndx, status="COMPLETED"})
    -- Evento aparte para UI/QuestBookWindow.lua, mismo motivo que
    -- QUEST_JUST_ACCEPTED en SetQuestActive arriba.
    LQA.Core.EventBus:Publish("QUEST_JUST_COMPLETED", {ndx=ndx})
end

function QuestStateManager.SetQuestAbandoned(ndx)
    if QuestStateManager.State.active[ndx] then
        QuestStateManager.State.active[ndx] = nil
        if QuestStateManager.State.tracked == ndx then
            QuestStateManager.State.tracked = nil
        end
        QuestStateManager.Save()
        LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", {ndx=ndx, status="ABANDONED"})
        -- (2026-10-01) con el nombre de la mision (el Mapa del Mundo y el
        -- Tracker ya se actualizan solos con el evento de arriba)
        local quest = QuestDB.quests[ndx]
        local name = ""
        if quest then
            local okN, esName = pcall(QuestLocResolver.GetQuestNameES, ndx, quest.nameEN)
            name = " (" .. tostring(okN and esName or quest.nameEN) .. ")"
        end
        Turbine.Shell.WriteLine("<rgb=#FF0000>QuestSync: Misión abandonada" .. name .. "</rgb>")
    end
end

-- Reinicia una mision a DISPONIBLE (gris) sin importar su estado actual --
-- el "deshacer" del marcado manual (Activar/Completar) desde la UI, pedido
-- explicitamente por el usuario como red de seguridad para no quedar
-- atascado si se equivoca de mision en la lista.
function QuestStateManager.ResetQuest(ndx)
    if not ndx then return end

    QuestStateManager.State.active[ndx] = nil
    QuestStateManager.State.completed[ndx] = nil
    if QuestStateManager.State.tracked == ndx then
        QuestStateManager.State.tracked = nil
    end
    QuestStateManager.Save()

    local quest = QuestDB.quests[ndx]
    if quest then
        local esName = QuestLocResolver.GetQuestNameES(ndx, quest.nameEN)
        Turbine.Shell.WriteLine("<rgb=#FFAA00>QuestSync: Estado reiniciado -> DISPONIBLE (" .. esName .. ")</rgb>")
    end

    LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", {ndx=ndx, status="AVAILABLE"})
end

function QuestStateManager.GetQuestState(ndx)
    if QuestStateManager.State.completed[ndx] then return "COMPLETED" end
    if QuestStateManager.State.active[ndx] then return QuestStateManager.State.active[ndx].status end
    return "AVAILABLE"
end

function QuestStateManager.GetQuestProgress(ndx)
    if QuestStateManager.State.active[ndx] then
        return QuestStateManager.State.active[ndx].progress or ""
    end
    return ""
end

function QuestStateManager.GetTrackedQuest()
    return QuestStateManager.State.tracked
end

function QuestStateManager.SetTrackedQuest(ndx)
    QuestStateManager.State.tracked = ndx
    LQA.Core.EventBus:Publish("QUEST_TRACKED", {ndx=ndx})
end
