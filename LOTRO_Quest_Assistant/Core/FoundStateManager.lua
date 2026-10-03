-- LOTRO_Quest_Assistant/Core/FoundStateManager.lua
-- Memoria de "encontrado" para cofres/amenazas/colecciones, pedido explicito
-- del usuario ("auto guardado y completado en los cofres y monstruos y
-- puntos de interes"). Mismo patron que QuestStateManager.lua: guardado
-- automatico en Turbine.PluginData en cada cambio, restaurado solo al
-- volver a entrar.
--
-- Clave: entry.id (numero). Los 3 catalogos (ChestsDB, ThreatsDB,
-- LostLoreDB) usan rangos de id disjuntos -- verificado sin duplicados
-- (393 ids distintos combinados, escaneo 2026-08-18) -- asi que un solo
-- set global {id -> true} alcanza, no hace falta prefijar por catalogo.
import "Turbine"

_G.FoundStateManager = {}

local SAVE_KEY = "QuestSync_FoundState"

FoundStateManager.Found = {} -- [id] = true

function FoundStateManager.Initialize()
    Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(loadedData)
        if loadedData and type(loadedData) == "table" then
            FoundStateManager.Found = loadedData
            if LQA and LQA.Core and LQA.Core.EventBus then
                LQA.Core.EventBus:Publish("FOUND_STATE_CHANGED", {})
            end
        end
    end)
end

function FoundStateManager.Save()
    Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, FoundStateManager.Found)
end

function FoundStateManager.IsFound(id)
    if not id then return false end
    return FoundStateManager.Found[id] == true
end

function FoundStateManager.SetFound(id, value)
    if not id then return end
    if value then
        FoundStateManager.Found[id] = true
    else
        FoundStateManager.Found[id] = nil
    end
    FoundStateManager.Save()
    LQA.Core.EventBus:Publish("FOUND_STATE_CHANGED", { id = id, found = value })
end

function FoundStateManager.Toggle(id)
    FoundStateManager.SetFound(id, not FoundStateManager.IsFound(id))
end
