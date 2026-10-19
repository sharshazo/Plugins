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
    if QuestStateManager._loadDriver then
        QuestStateManager._loadDriver:SetWantsUpdates(false)
        QuestStateManager._loadDriver = nil
    end
    QuestStateManager._loading = false
    QuestStateManager._readErrorNoticed = false
    QuestStateManager._stopped = false
    local me = Plugins and Plugins["QuestSync"]
    if me ~= nil and not QuestStateManager._unloadHooked then
        QuestStateManager._unloadHooked = true
        local previous = me.Unload
        local manager = QuestStateManager
        me.Unload = function(sender, args)
            manager._stopped = true
            manager._loadAttemptToken = nil
            manager._loadToken = nil
            if manager._loadDriver then
                manager._loadDriver:SetWantsUpdates(false)
                manager._loadDriver = nil
            end
            if type(previous) == "function" then previous(sender, args) end
        end
    end
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
    --
    -- 2026-10-18 (QS-01): mientras la carga esta pendiente, lo que pase en el
    -- juego (aceptar, completar, abandonar, seguir otra mision...) se anota y
    -- NO se guarda todavia (se guardaria un historial a medias). Al llegar
    -- el guardado anterior se mezcla: lo de esta sesion gana para las
    -- misiones tocadas, el resto sale del guardado; y recien ahi se guarda.
    QuestStateManager._loaded = false
    QuestStateManager._touched = {}
    QuestStateManager._trackedTouched = false
    QuestStateManager._saveWanted = false
    local token = {}
    QuestStateManager._loadToken = token
    local function finish(loadedData)
        if QuestStateManager._loadToken ~= token or QuestStateManager._loaded then
            return   -- callback repetido o de una carga anterior
        end
        QuestStateManager._loaded = true
        QuestStateManager._loading = false
        if QuestStateManager._loadDriver then
            QuestStateManager._loadDriver:SetWantsUpdates(false)
            QuestStateManager._loadDriver = nil
        end
        local wanted = QuestStateManager._saveWanted
        QuestStateManager._saveWanted = false
        if loadedData and type(loadedData) == "table" then
            local cur = QuestStateManager.State
            local act = type(loadedData.active) == "table" and loadedData.active or {}
            local comp = type(loadedData.completed) == "table" and loadedData.completed or {}
            for ndx in pairs(QuestStateManager._touched) do
                act[ndx] = cur.active[ndx]
                comp[ndx] = cur.completed[ndx]
            end
            cur.active = act
            cur.completed = comp
            if not QuestStateManager._trackedTouched then
                cur.tracked = loadedData.tracked
            end
            if cur.zone == nil and type(loadedData.zone) == "string" then
                cur.zone = loadedData.zone
            end
            if cur.fxOff == nil and loadedData.fxOff == true then
                cur.fxOff = true
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
        QuestStateManager._touched = {}
        if wanted then
            QuestStateManager.Save()
        end
    end
    QuestStateManager._loadFinish = finish
    QuestStateManager.RetryLoad()
end

-- Retry without resetting the live changes or authorizing a partial save.
function QuestStateManager.RetryLoad()
    local Q = QuestStateManager
    if Q._stopped or Q._loaded or Q._loading or Q._loadFinish == nil then return end
    local token = {}
    Q._loadAttemptToken = token
    Q._loading = true
    Q._loadDeadline = Turbine.Engine.GetGameTime() + 15
    local ok = pcall(Turbine.PluginData.Load, Turbine.DataScope.Character, SAVE_KEY, function(data)
        if Q._loadAttemptToken ~= token or Q._loaded then return end
        Q._loadFinish(data)
    end)
    if not ok and not Q._loaded then
        Q._loading = false
        Q._loadAttemptToken = nil
        Q._retryAt = Turbine.Engine.GetGameTime() + 5
        if not Q._readErrorNoticed then
            Q._readErrorNoticed = true
            Turbine.Shell.WriteLine("QuestSync: saved progress could not be read. Changes stay in memory while loading is retried; the existing file will not be overwritten.")
        end
    end
    if not Q._loaded and Q._loadDriver == nil and Turbine.UI ~= nil then
        local driver = Turbine.UI.Control()
        Q._loadDriver = driver
        driver.Update = function()
            if Q._loaded or Q._stopped then
                driver:SetWantsUpdates(false)
                return
            end
            local now = Turbine.Engine.GetGameTime()
            if Q._loading and now >= Q._loadDeadline then
                Q._loading = false
                Q._loadAttemptToken = nil
                Q._retryAt = now + 5
            elseif not Q._loading and now >= (Q._retryAt or 0) then
                Q.RetryLoad()
            end
        end
        driver:SetWantsUpdates(true)
    end
end

function QuestStateManager.Save()
    if QuestStateManager._loaded == false then
        QuestStateManager._saveWanted = true   -- se guarda al terminar la carga
        return
    end
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
        if QuestStateManager.State.active[ndx].progress == progressText then
            QuestStateManager.State.active[ndx].lastUpdate = Turbine.Engine.GetGameTime()
            return
        end
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
    -- (2026-10-13) la mision elegida se guarda al momento: antes solo se
    -- guardaba si despues cambiaba otra cosa, y al volver a entrar se perdia
    local changed = QuestStateManager.State.tracked ~= ndx
    QuestStateManager.State.tracked = ndx
    if changed then
        pcall(QuestStateManager.Save)
    end
    LQA.Core.EventBus:Publish("QUEST_TRACKED", {ndx=ndx})
end

-- 2026-10-18 (QS-01): cada cambio hecho mientras la carga esta pendiente
-- queda anotado para que la mezcla de Initialize lo respete.
for _, name in ipairs({ "SetQuestActive", "UpdateProgress", "SetQuestCompleted", "SetQuestAbandoned", "ResetQuest" }) do
    local f = QuestStateManager[name]
    QuestStateManager[name] = function(ndx, ...)
        if QuestStateManager._loaded ~= false then
            return f(ndx, ...)
        end
        if ndx ~= nil and QuestStateManager._touched then
            QuestStateManager._touched[ndx] = true
        end
        local before = QuestStateManager.State.tracked
        local r = f(ndx, ...)
        if QuestStateManager.State.tracked ~= before then
            QuestStateManager._trackedTouched = true
        end
        return r
    end
end
do
    local f = QuestStateManager.SetTrackedQuest
    QuestStateManager.SetTrackedQuest = function(ndx, ...)
        if QuestStateManager._loaded == false then
            QuestStateManager._trackedTouched = true
        end
        return f(ndx, ...)
    end
end
