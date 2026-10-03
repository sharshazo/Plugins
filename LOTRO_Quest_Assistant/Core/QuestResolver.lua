-- LOTRO_Quest_Assistant/Core/QuestResolver.lua
import "Turbine"

_G.QuestResolver = {}

function QuestResolver.FindQuest(questName)
    if QuestDatabase and QuestDatabase[questName] then
        return QuestDatabase[questName]
    end
    -- En el futuro se podran aadir heursticas de bsqueda difusa aqu
    return nil
end

