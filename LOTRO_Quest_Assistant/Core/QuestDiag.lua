-- LOTRO_Quest_Assistant/Core/QuestDiag.lua
-- (2026-09-27) Registro de diagnostico de la deteccion de misiones.
--
-- Guarda los mensajes del canal de Misiones que el addon NO pudo
-- relacionar con una mision (una "Nueva mision" que no se encontro o que
-- comparten varias misiones, o un contador "(N/M)" sin mision). Asi se ve
-- exactamente que texto manda el juego cuando algo no se detecta.
--
--   /qsdiag          muestra en el chat los ultimos 15
--   /qsdiag borrar   vacia el registro
--
-- Se guarda por personaje en QuestSync_Diag.plugindata (maximo 40, sin
-- repetir: si el mismo texto vuelve a llegar solo suma "veces"). El
-- guardado se agrupa: como mucho una vez cada 5 s. La carga del registro
-- anterior es asincrona (con callback), como exige el juego.
import "Turbine"
import "Turbine.UI"

_G.QuestDiag = _G.QuestDiag or {}
local QuestDiag = _G.QuestDiag

local SAVE_KEY = "QuestSync_Diag"
local MAX_ENTRIES = 40
local SHOW = 15

QuestDiag.entries = QuestDiag.entries or {}

local dirty = false
local timer = nil
-- no se guarda nada hasta leer el registro anterior (si no, se pisaria)
local loaded = false
local cleared = false

local function stamp()
    local ok, d = pcall(Turbine.Engine.GetDate)
    if ok and type(d) == "table" and d.Day then
        return string.format("%02d/%02d %02d:%02d", d.Day or 0, d.Month or 0, d.Hour or 0, d.Minute or 0)
    end
    return ""
end

-- el contador "(N/M)" cambia en cada aviso: la clave lo ignora
local function keyOf(kind, text)
    local t = string.gsub(text, "%(?%d+/%d+%)?%s*$", "")
    return kind .. "|" .. t
end

local function doSave()
    if not loaded then return end
    dirty = false
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Character, SAVE_KEY, { entries = QuestDiag.entries })
end

local function scheduleSave()
    dirty = true
    if not timer then
        timer = Turbine.UI.Control()
        timer.at = 0
        timer.Update = function()
            if Turbine.Engine.GetGameTime() >= timer.at then
                timer:SetWantsUpdates(false)
                if dirty then doSave() end
            end
        end
    end
    timer.at = Turbine.Engine.GetGameTime() + 5
    timer:SetWantsUpdates(true)
end

function QuestDiag.Note(kind, text, status, zone)
    text = tostring(text or "")
    if text == "" then return end
    if #text > 240 then text = string.sub(text, 1, 240) end
    local key = keyOf(kind, text)
    for i, e in ipairs(QuestDiag.entries) do
        if e.key == key then
            e.veces = tostring((tonumber(e.veces) or 1) + 1)
            e.ultimo = text
            e.hora = stamp()
            table.remove(QuestDiag.entries, i)
            table.insert(QuestDiag.entries, e)
            scheduleSave()
            return
        end
    end
    local lvl = ""
    if _G.QuestTags and QuestTags.GetPlayerLevel then
        lvl = tostring(QuestTags.GetPlayerLevel() or "")
    end
    table.insert(QuestDiag.entries, {
        key = key, tipo = kind, ultimo = text, estado = tostring(status or ""),
        zona = tostring(zone or ""), nivel = lvl, hora = stamp(), veces = "1",
    })
    while #QuestDiag.entries > MAX_ENTRIES do table.remove(QuestDiag.entries, 1) end
    scheduleSave()
end

function QuestDiag.Initialize()
    Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(data)
        loaded = true
        if cleared or type(data) ~= "table" or type(data.entries) ~= "table" then
            if dirty then scheduleSave() end
            return
        end
        -- lo de la sesion anterior va primero; lo nuevo (si ya llego algo) despues
        local merged = {}
        for _, e in ipairs(data.entries) do
            if type(e) == "table" and e.key then merged[#merged + 1] = e end
        end
        local seen = {}
        for _, e in ipairs(merged) do seen[e.key] = true end
        for _, e in ipairs(QuestDiag.entries) do
            if not seen[e.key] then merged[#merged + 1] = e end
        end
        while #merged > MAX_ENTRIES do table.remove(merged, 1) end
        QuestDiag.entries = merged
        if dirty then scheduleSave() end
    end)
end

local DiagCommand = Turbine.ShellCommand()
function DiagCommand:Execute(command, arguments)
    local arg = string.lower(tostring(arguments or ""))
    if string.find(arg, "borrar", 1, true) or string.find(arg, "clear", 1, true) then
        QuestDiag.entries = {}
        cleared = true
        dirty = true
        doSave()
        Turbine.Shell.WriteLine("QuestSync: registro de diagnostico vaciado.")
        return
    end
    local zone = QuestEventParser and QuestEventParser.GetCurrentZone and QuestEventParser.GetCurrentZone()
    local lvl = _G.QuestTags and QuestTags.GetPlayerLevel and QuestTags.GetPlayerLevel()
    Turbine.Shell.WriteLine("QuestSync: diagnostico -- zona actual: " .. tostring(zone or "desconocida") ..
        ", nivel: " .. tostring(lvl or "?"))
    local n = #QuestDiag.entries
    if n == 0 then
        Turbine.Shell.WriteLine("QuestSync: nada sin detectar. Todo en orden.")
        return
    end
    for i = math.max(1, n - SHOW + 1), n do
        local e = QuestDiag.entries[i]
        Turbine.Shell.WriteLine("QuestSync: [" .. tostring(e.hora) .. "] " .. tostring(e.tipo) .. " (" ..
            tostring(e.estado) .. ", x" .. tostring(e.veces) .. "): " .. tostring(e.ultimo))
    end
end
Turbine.Shell.AddCommand("qsdiag", DiagCommand)
