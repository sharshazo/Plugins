-- LOTRO_Quest_Assistant/Core/QuestTags.lua
--
-- Etiquetas extra de mision (pedido explicito del usuario, 2026-09-22):
--   * Diaria / Semanal / Quincenal -- dato real de Data/QuestLockDB.lua
--     (lockType oficial del juego, ver la nota de ese archivo).
--   * "Apropiada para tu nivel" -- compara el nivel NUMERICO de la mision
--     con el nivel actual del personaje.
--
-- Mismo criterio defensivo que Core/GroupQuest.lua: si falta el dato o la
-- lectura del nivel falla, las funciones devuelven nil/false y todas las
-- ventanas se ven exactamente como antes. Nunca un error de Lua.
import "Turbine"
import "Turbine.UI"
-- import "Turbine.Gameplay": confirmado real en addons instalados (LUI/src/
-- main.lua) y en el propio Core/QuestManager.lua de este addon.
import "Turbine.Gameplay"

_G.QuestTags = _G.QuestTags or {}
local QuestTags = _G.QuestTags

-- Ventana de nivel "apropiado": desde 4 niveles por debajo hasta 2 por
-- encima del personaje. Mas abajo casi no da experiencia; mas arriba los
-- enemigos empiezan a ser duros para ir solo. Cambiar aca si se prefiere
-- otro rango.
QuestTags.LEVEL_BELOW = 4
QuestTags.LEVEL_ABOVE = 2

-- Verde claro: la franja/texto de "tu nivel". Distinto del naranja de
-- grupo y de los colores de estado.
QuestTags.LevelColor = Turbine.UI.Color(120 / 255, 220 / 255, 90 / 255)

local LOCK_LABEL = {
    ES = { D = "Diaria", W = "Semanal", B = "Quincenal" },
    EN = { D = "Daily", W = "Weekly", B = "Bi-weekly" },
}

local function Lang()
    if _G.LanguageSettings and LanguageSettings.IsSpanish then
        return LanguageSettings.IsSpanish() and "ES" or "EN"
    end
    return "ES"
end

-- "D"/"W"/"B" o nil.
function QuestTags.GetLock(quest)
    if not _G.QuestLockDB or type(quest) ~= "table" or not quest.id then return nil end
    return _G.QuestLockDB[quest.id]
end

-- "Diaria"/"Weekly"/... o nil.
function QuestTags.LockText(quest)
    local lock = QuestTags.GetLock(quest)
    if not lock then return nil end
    return LOCK_LABEL[Lang()][lock]
end

-- true si el nombre YA dice que es diaria/semanal (muchos nombres
-- oficiales traen "(Daily)"/"(Diaria)" adentro) -- para no repetir la
-- etiqueta dos veces en la misma fila.
function QuestTags.NameAlreadyTagged(name)
    local s = string.lower(tostring(name or ""))
    return string.find(s, "diari", 1, true) ~= nil
        or string.find(s, "daily", 1, true) ~= nil
        or string.find(s, "semanal", 1, true) ~= nil
        or string.find(s, "weekly", 1, true) ~= nil
        or string.find(s, "quincenal", 1, true) ~= nil
end

-- Nivel actual del personaje, o nil si no se pudo leer.
-- Turbine.Gameplay.LocalPlayer.GetInstance():GetLevel() -- misma llamada
-- real que ya usa el addon WhereToPlay instalado en esta maquina (y el
-- Mapa del Mundo). Envuelto en pcall por las dudas: si falla, simplemente
-- no se resalta nada.
function QuestTags.GetPlayerLevel()
    local ok, level = pcall(function()
        local player = Turbine.Gameplay.LocalPlayer.GetInstance()
        if not player then return nil end
        return player:GetLevel()
    end)
    if ok and type(level) == "number" and level > 0 then
        return level
    end
    return nil
end

-- true si el nivel NUMERICO de la mision cae en la ventana del personaje.
-- Las misiones "Scaling" (se adaptan al nivel) no se marcan: le servirian a
-- casi cualquiera y llenarian la lista de marcas sin decir nada util.
function QuestTags.IsLevelAppropriate(quest, playerLevel)
    if not playerLevel or type(quest) ~= "table" then return false end
    local qLevel = tonumber(quest.level)
    if not qLevel then return false end
    return qLevel >= playerLevel - QuestTags.LEVEL_BELOW and qLevel <= playerLevel + QuestTags.LEVEL_ABOVE
end

function QuestTags.LevelText(playerLevel)
    if Lang() == "ES" then
        return "Apropiada para tu nivel (" .. tostring(playerLevel) .. ")"
    end
    return "Good for your level (" .. tostring(playerLevel) .. ")"
end
