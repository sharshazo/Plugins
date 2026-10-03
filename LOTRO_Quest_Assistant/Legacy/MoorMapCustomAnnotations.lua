-- LOTRO_Quest_Assistant/Legacy/MoorMapCustomAnnotations.lua
-- Registra un punto de recoleccion como anotacion PERSISTENTE en el mapa
-- REAL de MoorMap (visible siempre que se abra MoorMap en esa zona, con su
-- propio icono de "Ore Node"/"Wood Node"/etc. y tier) -- pedido explicito
-- del usuario: ver el mapa real de MoorMap (como su ventana nativa) con
-- solo los iconos de nodos de recoleccion de NUESTRO sistema encima,
-- filtrados por profesion, sin depender de un visor propio (GatherMapView.lua
-- se elimino, ver historial en GatherWindow.lua).
--
-- MECANISMO (encontrado leyendo el codigo fuente REAL de MoorMap, no
-- adivinado): MoorMap trae su PROPIO archivo de ejemplo/prueba,
-- GaranStuff/MoorMap/CustAnnotTest.lua, que muestra como agregar una
-- anotacion PERSISTENTE (no el "ping" temporal que ya usa MoorMapAdapter.lua)
-- desde CODIGO, sin ningun clic de por medio:
--   1. Registrar un ShellCommand cuyo NOMBRE completo es el payload:
--      "0MMCD_SM_<region>_<ns>_<ew>_<tipo>|<tier>_<allegiance>_<nombre>_<desc>"
--      ("SM" = Save, solo en el mapa de MoorMap -- ver GaranStuff/MoorMap/
--      MMCust.lua lineas 257-273 para las 6 variantes S/SM/ST/D/DM/DT).
--   2. Turbine.PluginManager.LoadPlugin("MMCust") -- el plugin interno de
--      MoorMap que lee TODOS los comandos "0MMCD_*" pendientes, los guarda
--      en el PluginData "MM_CustomAnnotations_<mapID>" (confirmado que
--      Main.lua de MoorMap CARGA y DIBUJA ese mismo archivo en cada mapa
--      abierto, GaranStuff/MoorMap/Main.lua linea ~1959-2018 -- no es
--      codigo muerto), y al terminar registra el comando "0MMCC" como señal
--      de "listo".
--   3. Esperar a que exista el comando "0MMCC", despues
--      Turbine.PluginManager.UnloadScriptState("MMCust") +
--      Turbine.Shell.RemoveCommand() del comando propio -- mismo orden
--      exacto que CustAnnotTest.lua.
--
-- Tipos de nodo reales que MoorMap ya reconoce (GaranStuff/MoorMap/
-- AnnotationsWindow.lua lineas 210-216, confirmado con las cadenas de texto
-- reales en Strings.lua): 43=Ore Node, 44=Wood Node, 45=Scholar Node,
-- 46=Cook Ingredient. NO existe un tipo dedicado "Farmer/Crop Node" en
-- MoorMap -- Granjero usa 46 (Cook Ingredient) por ser el mas cercano
-- semanticamente disponible; limitacion real de MoorMap, no de este addon.
--
-- SERIALIZADO A PROPOSITO (una anotacion a la vez, nunca 2 en simultaneo):
-- esta sesion ya tuvo un crash real por llamadas CONCURRENTES a otra API
-- asincrona (3x Turbine.PluginData.Load a la vez, ver Main.lua/
-- GatherPointsStore.lua) -- Turbine.PluginManager.LoadPlugin("MMCust") es
-- una superficie nueva (nunca usada antes en este addon) que carga el
-- PLUGIN DE OTRO ADDON, asi que se trata con la misma cautela: se encola y
-- se espera la señal "0MMCC" de una solicitud antes de disparar la
-- siguiente, replicando el patron EXACTO (y unico probado) de
-- CustAnnotTest.lua en vez de arriesgar una variante propia.
import "Turbine"
import "Turbine.UI"

_G.MoorMapCustomAnnotations = {}

-- Mismo problema de locale ya documentado y corregido en MoorMapAdapter.lua:
-- tostring(1.5) en Windows-ES devuelve "1,5", pero el parser de MMCust.lua
-- usa tonumber() que exige punto.
local function FormatCoord(n)
    if not n then return "0" end
    return string.gsub(tostring(n), ",", ".")
end

-- Mismo problema ya documentado y corregido en MoorMapAdapter.lua: el
-- nombre viaja dentro de un NOMBRE DE COMANDO (no un mensaje de chat), que
-- no es UTF-8-seguro en este cliente -- se pliegan tildes/ñ a ASCII. Ademas
-- ESPECIFICO de este comando: el separador de campos es "_", asi que
-- cualquier "_" propio del nombre rompería el parseo -- se reemplaza por
-- espacio por las dudas (los nombres de nodos de GatherNodesDB no traen
-- "_", pero es una salvaguarda barata).
local FOLD_PAIRS = {
    {"\195\161", "a"}, {"\195\169", "e"}, {"\195\173", "i"}, {"\195\179", "o"}, {"\195\186", "u"},
    {"\195\129", "A"}, {"\195\137", "E"}, {"\195\141", "I"}, {"\195\147", "O"}, {"\195\154", "U"},
    {"\195\177", "n"}, {"\195\145", "N"}, {"\195\188", "u"}, {"\195\156", "U"},
    {"\194\191", ""}, {"\194\161", ""},
}
local function SanitizeField(s)
    s = tostring(s or "")
    for _, pair in ipairs(FOLD_PAIRS) do
        s = string.gsub(s, pair[1], pair[2])
    end
    s = string.gsub(s, "_", " ")
    return s
end

local queue = {}
local processing = false
local pendingCmd = nil

local function FinishCurrent()
    if pendingCmd ~= nil then
        Turbine.Shell.RemoveCommand(pendingCmd)
        pendingCmd = nil
    end
    if Turbine.PluginManager.UnloadScriptState ~= nil then
        Turbine.PluginManager.UnloadScriptState("MMCust")
    end
    processing = false
end

local function StartNext()
    if processing then return end
    local item = table.remove(queue, 1)
    if item == nil then return end
    processing = true

    local cmdStr = "0MMCD_SM_" .. tostring(item.region) .. "_" ..
        FormatCoord(item.ns) .. "_" .. FormatCoord(item.ew) .. "_" ..
        tostring(item.type) .. "|" .. tostring(item.tier) .. "_0_" ..
        SanitizeField(item.name) .. "_" .. SanitizeField(item.desc)

    if LQA and LQA.Debug and LQA.Debug.Enabled then
        Turbine.Shell.WriteLine("<rgb=#FF00FF>GatherSync DEBUG: MMCD cmd = " .. cmdStr .. "</rgb>")
    end

    pendingCmd = Turbine.ShellCommand()
    Turbine.Shell.AddCommand(cmdStr, pendingCmd)
    Turbine.PluginManager.LoadPlugin("MMCust")
end

local watcher = Turbine.UI.Control()
watcher.Update = function()
    if processing then
        if Turbine.Shell.IsCommand("0MMCC") then
            FinishCurrent()
            StartNext()
        end
    else
        StartNext()
    end
end
watcher:SetWantsUpdates(true)

-- region: numero crudo que ya devuelve /loc (ver Legacy/LocationAdapter.lua,
-- MISMO numero que usa el Grid de MoorMap/MMCust.lua -- confirmado porque
-- ambos derivan del mismo campo "r<N>" que imprime el cliente). type: 43
-- (Minero) / 44 (Leñador) / 45 (Erudito) / 46 (Granjero, ver nota arriba).
function MoorMapCustomAnnotations.RegisterNode(region, ns, ew, nodeType, tier, name, desc)
    if region == nil or ns == nil or ew == nil or nodeType == nil then return end
    table.insert(queue, {
        region = region, ns = ns, ew = ew,
        type = nodeType, tier = tier or 1,
        name = name or "", desc = desc or name or "",
    })
end
