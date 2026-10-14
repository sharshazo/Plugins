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

-- ---------------------------------------------------------------------
-- 2026-10-14 (pedido del jugador: "mejorar los numeros y ese cuadrado E"):
-- pastilla redondeada con el NIVEL de la mision, del color de dificultad
-- del juego segun tu nivel: rojo (+4 o mas), naranja (+2/+3), amarillo
-- (tu nivel), azul (-2 a -5), verde (-6 a -10), gris (mas bajas).
-- Las misiones que escalan con tu nivel ("Scaling") muestran "~58" (tu
-- nivel) en amarillo. Devuelve el ancho de la pastilla.
-- ---------------------------------------------------------------------
local PILL_RES = "LOTRO_Quest_Assistant/Resources/Card/"
local PILL_RGB = {
    red = { 235, 70, 70 }, orange = { 245, 140, 45 }, yellow = { 245, 205, 60 },
    blue = { 80, 155, 240 }, green = { 95, 190, 95 }, gray = { 150, 150, 155 },
}

function QuestTags.DifficultyKey(qLevel, playerLevel)
    if type(qLevel) ~= "number" or type(playerLevel) ~= "number" then return "yellow" end
    local d = qLevel - playerLevel
    if d >= 4 then return "red" end
    if d >= 2 then return "orange" end
    if d >= -1 then return "yellow" end
    if d >= -5 then return "blue" end
    if d >= -10 then return "green" end
    return "gray"
end

local function PillText(quest, plvl)
    local qLevel = type(quest) == "table" and tonumber(quest.level) or nil
    if qLevel ~= nil then
        return tostring(qLevel), qLevel
    end
    -- misiones que escalan: tu nivel (es el nivel real de la mision)
    return (plvl and tostring(plvl) or nil), nil
end

-- ancho que tendra la pastilla (para acomodar lo que va al lado)
function QuestTags.LevelPillWidth(quest)
    -- (pedido del jugador: sin "E" ni "~"; las que escalan, con tu nivel)
    if type(quest) ~= "table" then
        return 0
    end
    local text = PillText(quest, QuestTags.GetPlayerLevel())
    if text == nil then
        return 0
    end
    return math.max(12, #text * 8) + 20
end

function QuestTags.MakeLevelPill(parent, x, y, quest, onClick)
    if type(quest) ~= "table" then
        return 0, nil
    end
    local plvl = QuestTags.GetPlayerLevel()
    local text, qLevel = PillText(quest, plvl)
    if text == nil then
        return 0, nil
    end
    local key = QuestTags.DifficultyKey(qLevel or plvl, plvl)
    local rgb = PILL_RGB[key]
    local function C(f, a)
        return Turbine.UI.Color(a or 1, math.min(255, rgb[1] * f) / 255, math.min(255, rgb[2] * f) / 255, math.min(255, rgb[3] * f) / 255)
    end
    local midW = math.max(12, #text * 8)
    local W, H = midW + 20, 20
    local holder = Turbine.UI.Control()
    holder:SetParent(parent)
    holder:SetPosition(x, y)
    holder:SetSize(W, H)
    local function img(file, px)
        local k = Turbine.UI.Control()
        k:SetParent(holder)
        k:SetPosition(px, 0)
        k:SetSize(10, 20)
        k:SetBackground(PILL_RES .. file)
        k:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        k:SetMouseVisible(false)
    end
    local function box(px, py, w, h, color)
        local k = Turbine.UI.Control()
        k:SetParent(holder)
        k:SetPosition(px, py)
        k:SetSize(w, h)
        k:SetBackColor(color)
        k:SetMouseVisible(false)
    end
    img("lvl_" .. key .. "_l.tga", 0)
    box(10, 0, midW, H, C(0.55))          -- borde
    box(10, 1, midW, H - 2, C(1))         -- relleno
    box(10, 2, midW, 7, C(1.12))          -- brillo de arriba
    img("lvl_" .. key .. "_r.tga", 10 + midW)
    local F = Turbine.UI.Lotro.Font
    local lbl = Turbine.UI.Label()
    lbl:SetParent(holder)
    lbl:SetPosition(0, 0)
    lbl:SetSize(W, H)
    lbl:SetFont(F.TrajanProBold16 or F.Verdana14 or F.Verdana12)
    lbl:SetForeColor(Turbine.UI.Color(28 / 255, 20 / 255, 10 / 255))
    lbl:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    lbl:SetText(text)
    lbl:SetMouseVisible(onClick ~= nil)
    if onClick ~= nil then
        lbl.MouseClick = onClick
    end
    return W, holder
end
