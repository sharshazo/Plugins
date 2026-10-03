-- LOTRO_Quest_Assistant/Core/QuestManager.lua
import "Turbine"
import "Turbine.Gameplay"

_G.LQA = _G.LQA or {}
LQA.Core = LQA.Core or {}

LQA.Core.QuestManager = {}
LQA.Core.QuestManager.Data = {
    ActiveQuests = {},
    CompletedQuests = {},
    AbandonedQuests = {},
    QuestHistory = {}
}

local playerName = nil
local saveKey = nil

-- Persistencia
function LQA.Core.QuestManager.EnsureLoaded()
    if playerName ~= nil then return end
    
    if Turbine.Gameplay.LocalPlayer and Turbine.Gameplay.LocalPlayer.GetInstance then
        local player = Turbine.Gameplay.LocalPlayer.GetInstance()
        if player then
            playerName = player:GetName()
            saveKey = "LQA_Data_" .. playerName
            
            Turbine.PluginData.Load(Turbine.DataScope.Character, saveKey, function(loadedData)
                if loadedData and type(loadedData) == "table" then
                    if loadedData.ActiveQuests then LQA.Core.QuestManager.Data.ActiveQuests = loadedData.ActiveQuests end
                    if loadedData.CompletedQuests then LQA.Core.QuestManager.Data.CompletedQuests = loadedData.CompletedQuests end
                    if loadedData.AbandonedQuests then LQA.Core.QuestManager.Data.AbandonedQuests = loadedData.AbandonedQuests end
                    if loadedData.QuestHistory then LQA.Core.QuestManager.Data.QuestHistory = loadedData.QuestHistory end
                end
            end)
        end
    end
end

function LQA.Core.QuestManager.SaveData()
    if saveKey then
        Turbine.PluginData.Save(Turbine.DataScope.Character, saveKey, LQA.Core.QuestManager.Data)
    end
end

-- Funciones internas para manejo de estado
local function GetOrCreateQuest(questName)
    if not LQA.Core.QuestManager.Data.ActiveQuests[questName] then
        LQA.Core.QuestManager.Data.ActiveQuests[questName] = {
            name = questName,
            status = "AVAILABLE", -- Asumimos available si an no ha sido activada explcitamente
            objectives = {},
            activeObjectiveIndex = 1,
            startedAt = Turbine.Engine.GetGameTime(),
            completedAt = nil
        }
    end
    return LQA.Core.QuestManager.Data.ActiveQuests[questName]
end

local function GetOrCreateObjective(questData, description)
    -- Buscar si ya existe
    for i, obj in ipairs(questData.objectives) do
        if obj.description == description then
            return obj, i
        end
    end
    
    -- Si no existe, crearlo
    local newObj = {
        description = description,
        progressCurrent = 0,
        progressTotal = 1, -- Por defecto 1 si no hay progresin conocida
        status = "IN_PROGRESS"
    }
    table.insert(questData.objectives, newObj)
    return newObj, #questData.objectives
end

-- Controlador de Eventos entrantes
function LQA.Core.QuestManager.ProcessEvent(event)
    LQA.Core.QuestManager.EnsureLoaded()
    table.insert(LQA.Core.QuestManager.Data.QuestHistory, event)
    
    if event.type == "QUEST_ACCEPTED" and event.questName then
        local q = GetOrCreateQuest(event.questName)
        q.status = "ACTIVE"
        
        LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", q)
        LQA.Core.QuestManager.SaveData()
        
    elseif event.type == "QUEST_PROGRESS" and event.questName then
        local q = GetOrCreateQuest(event.questName)
        q.status = "IN_PROGRESS"
        
        if event.description then
            local obj, objIndex = GetOrCreateObjective(q, event.description)
            
            if q.activeObjectiveIndex ~= objIndex then
                -- Cerrar el objetivo anterior
                if q.objectives[q.activeObjectiveIndex] then
                    q.objectives[q.activeObjectiveIndex].status = "COMPLETED"
                end
                q.activeObjectiveIndex = objIndex
                LQA.Core.EventBus:Publish("OBJECTIVE_CHANGED", { quest = q, newObjective = obj })
            end
            
            if event.progressCurrent then
                obj.progressCurrent = event.progressCurrent
                if event.progressTotal then
                    obj.progressTotal = event.progressTotal
                end
                
                if obj.progressCurrent >= obj.progressTotal then
                    obj.status = "COMPLETED"
                    LQA.Core.EventBus:Publish("OBJECTIVE_COMPLETED", { quest = q, objective = obj })
                else
                    LQA.Core.EventBus:Publish("OBJECTIVE_UPDATED", { quest = q, objective = obj })
                end
            else
                LQA.Core.EventBus:Publish("OBJECTIVE_UPDATED", { quest = q, objective = obj })
            end
        end
        
        LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", q)
        LQA.Core.QuestManager.SaveData()
        
    elseif event.type == "QUEST_COMPLETED" and event.questName then
        local q = LQA.Core.QuestManager.Data.ActiveQuests[event.questName]
        if not q then
            q = GetOrCreateQuest(event.questName)
        end
        q.status = "COMPLETED"
        q.completedAt = Turbine.Engine.GetGameTime()
        
        -- Mover a completadas
        LQA.Core.QuestManager.Data.CompletedQuests[event.questName] = q
        LQA.Core.QuestManager.Data.ActiveQuests[event.questName] = nil
        
        LQA.Core.EventBus:Publish("QUEST_COMPLETED", q)
        LQA.Core.EventBus:Publish("QUEST_REMOVED", { name = event.questName })
        LQA.Core.QuestManager.SaveData()
        
    elseif event.type == "QUEST_REWARDED" and event.questName then
        -- Mismo trato que completed si llega rezagado
        local q = LQA.Core.QuestManager.Data.ActiveQuests[event.questName]
        if q then
            q.status = "REWARDED"
            LQA.Core.QuestManager.Data.CompletedQuests[event.questName] = q
            LQA.Core.QuestManager.Data.ActiveQuests[event.questName] = nil
            LQA.Core.EventBus:Publish("QUEST_STATE_CHANGED", q)
            LQA.Core.QuestManager.SaveData()
        end
    end
end

-- API de Consultas
function LQA.Core.QuestManager.GetActiveQuests()
    local list = {}
    for k, v in pairs(LQA.Core.QuestManager.Data.ActiveQuests) do
        table.insert(list, v)
    end
    return list
end

function LQA.Core.QuestManager.GetQuest(questName)
    return LQA.Core.QuestManager.Data.ActiveQuests[questName] or LQA.Core.QuestManager.Data.CompletedQuests[questName] or LQA.Core.QuestManager.Data.AbandonedQuests[questName]
end

function LQA.Core.QuestManager.GetQuestState(questName)
    local q = LQA.Core.QuestManager.GetQuest(questName)
    if q then return q.status end
    return "UNKNOWN"
end

function LQA.Core.QuestManager.GetActiveObjective(questName)
    local q = LQA.Core.QuestManager.Data.ActiveQuests[questName]
    if q and q.activeObjectiveIndex and q.objectives[q.activeObjectiveIndex] then
        return q.objectives[q.activeObjectiveIndex]
    end
    return nil
end

function LQA.Core.QuestManager.GetCompletedQuests()
    local list = {}
    for k, v in pairs(LQA.Core.QuestManager.Data.CompletedQuests) do
        table.insert(list, v)
    end
    return list
end

function LQA.Core.QuestManager.GetObjectiveProgress(questName)
    local obj = LQA.Core.QuestManager.GetActiveObjective(questName)
    if obj then
        return obj.progressCurrent, obj.progressTotal
    end
    return 0, 1
end

-- Suscripcin a eventos al final
LQA.Core.EventBus:Subscribe('QUEST_ACCEPTED', function(event) LQA.Core.QuestManager.ProcessEvent(event) end)
LQA.Core.EventBus:Subscribe('QUEST_COMPLETED', function(event) LQA.Core.QuestManager.ProcessEvent(event) end)
LQA.Core.EventBus:Subscribe('QUEST_PROGRESS', function(event) LQA.Core.QuestManager.ProcessEvent(event) end)
LQA.Core.EventBus:Subscribe('QUEST_REWARDED', function(event) LQA.Core.QuestManager.ProcessEvent(event) end)
