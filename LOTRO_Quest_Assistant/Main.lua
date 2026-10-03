-- LOTRO_Quest_Assistant/Main.lua
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

-- 1. Load Core Event System first (declara LQA.Debug.Enabled, el interruptor
-- global de depuracion que el resto del addon consulta).
import "LOTRO_Quest_Assistant.Core.EventBus"

-- 2. Load Data Indices (Auto-Generated)
import "LOTRO_Quest_Assistant.Data.QuestDatabase"
-- GroupQuestDB.lua (2026-09-22, pedido explicito del usuario: color +
-- logo de grupo + "a que mazmorra/raid hay que ir" en las misiones de
-- grupo). Tabla pura de datos (id real de la mision -> tamaño/tipo/lugar),
-- sin dependencias -- ver la nota grande en ese archivo y en
-- Core/GroupQuest.lua.
import "LOTRO_Quest_Assistant.Data.GroupQuestDB"
-- GroupPlaceES.lua (2026-09-27, pedido del usuario): nombre en español de
-- cada mazmorra/incursion de GroupQuestDB (etiquetas reales en español de
-- lotro-data, ver ese archivo). Si faltara, se muestra solo en ingles.
import "LOTRO_Quest_Assistant.Data.GroupPlaceES"
-- QuestLockDB.lua (2026-09-22): diaria/semanal/quincenal oficial por id
-- real de mision (tabla pura de datos, ver ese archivo y Core/QuestTags.lua).
import "LOTRO_Quest_Assistant.Data.QuestLockDB"
-- DeedQuestCollisions.lua (2026-09-25, generado): textos de hazanas que
-- coinciden con nombres/objetivos de misiones -- ver la nota de ese archivo
-- y IsDeedCollision en Core/QuestEventParser.lua. Si la tabla faltara
-- (nil), el parser funciona igual que antes.
import "LOTRO_Quest_Assistant.Data.DeedQuestCollisions"
import "LOTRO_Quest_Assistant.Data.QuestZoneIndex"
import "LOTRO_Quest_Assistant.Data.QuestNameIndex"
-- QuestLocES.lua (viejo, basado en el TSV) NO se importa: su texto en
-- español tiene corrupcion de codificacion (mojibake, p.ej. "morirГЎ" en vez
-- de "morira") de una extraccion anterior. Sus ~4.218 entradas son un
-- subconjunto de las 14.824 de QuestLocES_Full.lua (que sí esta limpio), asi
-- que no se pierde cobertura al no importarlo -- antes quedaba enmascarado
-- porque se fusionaba y sobreescribia despues, pero eso dependia del orden
-- de fusion mas abajo y era una trampa latente si alguna vez cambiaba.
-- import "LOTRO_Quest_Assistant.Data.QuestNameESIndex"
import "LOTRO_Quest_Assistant.Data.QuestNameESIndex_Full"
import "LOTRO_Quest_Assistant.Data.QuestObjectiveESIndex_Full"
import "LOTRO_Quest_Assistant.Data.QuestLocalization_Full"
-- QuestObjectiveES_Generated.lua (2026-09-06): traduccion automatica (Argos
-- Translate, motor offline/gratuito -- ver ese archivo para la nota completa)
-- SOLO para las 2.959 misiones cuyo objectivesES en QuestLocalization_Full
-- seguia en ingles puro (verificado por deteccion de palabras funcionales
-- reales del espanol, no solo tildes -- muchos nombres propios en ingles
-- como "Nágri" ya llevan acento y daban falso positivo con esa deteccion
-- mas simple). Las otras 11.865 misiones ya tenian objectivesES profesional
-- real, encontrado recien esta sesion (nota vieja de memoria/documentacion
-- decia "solo Lv1-10", desactualizada). No es traduccion oficial -- ver el
-- merge junto a QuestLocES mas abajo.
import "LOTRO_Quest_Assistant.Data.QuestObjectiveES_Generated"
-- QuestNameES_Missing.lua (2026-09-06): nombres profesionales en espanol
-- (misma fuente LotRO Companion labels/es/quests.xml de siempre) para las
-- 150 misiones nuevas de QuestDatabase_011_Missing.lua (ver esa nota
-- grande) -- esas 150 no existen en QuestLocalization_Full.lua en
-- absoluto (nunca estuvieron en Compendium), asi que necesitan su propia
-- entrada nueva en QuestLocES en vez de solo pisar un campo existente.
import "LOTRO_Quest_Assistant.Data.QuestNameES_Missing"
import "LOTRO_Quest_Assistant.Data.QuestLocCoords"
import "LOTRO_Quest_Assistant.Data.QuestStagesCoords"
import "LOTRO_Quest_Assistant.Data.ZoneMapIndex"
import "LOTRO_Quest_Assistant.Data.ChestsDB"
import "LOTRO_Quest_Assistant.Data.ThreatsDB"
import "LOTRO_Quest_Assistant.Data.LostLoreDB"
-- FarmingDB.lua NO se importa: la pestaña "Granjeo" que la usaba se saco de
-- ChestsWindow.lua (solo 8/34 entradas traen coordenada, se sentia vacia
-- igual que "Cartas"/"Puntos de Clase"). Archivo generado se deja en disco
-- sin usar, mismo criterio que QuestLocES.lua.
import "LOTRO_Quest_Assistant.Data.WarbandMapBounds"

-- GatherSync: REACTIVADO con reparacion puntual (2026-08-23). Con reinicio
-- completo real, GatherSync desactivado = anda bien, GatherSync activo = se
-- cierra al cargar el personaje -- comparacion limpia, confirma que es este
-- codigo. Descartado que sea GatherCaptureButton.lua (nunca se importa) o el
-- archivo guardado (se leyo, sintaxis Lua valida, sin corrupcion). Sospecha
-- que queda: antes de esto, el addon hacia 2 llamadas a
-- Turbine.PluginData.Load en el mismo instante al cargar el personaje
-- (QuestStateManager + LanguageSettings, estable en toda la historia del
-- addon) -- GatherPointsStore.Initialize() agregaba una 3ra AL MISMO TIEMPO.
-- Reparacion: se demora GatherPointsStore.Initialize() unos segundos (ver
-- mas abajo, junto a QuestStateManager.Initialize()) para que nunca compitan
-- las 3 en el mismo instante -- misma tecnica de espera que ya usa este
-- archivo para el watchdog del chat compartido.
import "LOTRO_Quest_Assistant.Data.GatherNodesDB"
-- MoorMapZones.lua: 206 mapas reales extraidos del propio MoorMap
-- (Defaults.lua), reemplaza a WarbandMapBounds para resolver la zona de un
-- punto de recoleccion -- ver historial completo en
-- Persistence/GatherPointsStore.lua y UI/GatherWindow.lua.
import "LOTRO_Quest_Assistant.Data.MoorMapZones"
-- MoorMapZonesES.lua: traduccion ES de esos nombres de zona, extraida del
-- diccionario maestro real (LotRO Companion), ver Core/MoorMapZoneResolver.lua.
import "LOTRO_Quest_Assistant.Data.MoorMapZonesES"

-- 2b. Map professional ES localization directly to runtime globals
_G.QuestNameESIndex = _G.QuestNameESIndex_Full
_G.QuestObjectiveESIndex = _G.QuestObjectiveESIndex_Full
_G.QuestLocES = _G.QuestLocalization_Full

-- Relleno de QuestObjectiveES_Generated (ver import e nota grande arriba):
-- solo pisa objectivesES para las ndx que ese archivo trae (exactamente las
-- 2.959 que no tenian nada real en espanol) -- nunca toca las que ya
-- resolvian con la fuente profesional de QuestLocalization_Full.
if _G.QuestObjectiveES_Generated then
    for ndx, data in pairs(_G.QuestObjectiveES_Generated) do
        if _G.QuestLocES[ndx] then
            _G.QuestLocES[ndx].objectivesES = data.objectivesES
        end
    end
end

-- Relleno de QuestNameES_Missing (ver import e nota grande arriba): las 150
-- misiones de QuestDatabase_011_Missing.lua no tienen NINGUNA entrada en
-- QuestLocalization_Full (nunca estuvieron en Compendium), asi que se les
-- crea su propia entrada nueva en QuestLocES en vez de pisar un campo de
-- una que ya existia.
if _G.QuestNameES_Missing then
    for ndx, data in pairs(_G.QuestNameES_Missing) do
        _G.QuestLocES[ndx] = _G.QuestLocES[ndx] or {}
        _G.QuestLocES[ndx].nameES = data.nameES
    end
end

-- 3. Load Core Managers
import "LOTRO_Quest_Assistant.Core.QuestLocResolver"
import "LOTRO_Quest_Assistant.Core.NarratorBridge"
import "LOTRO_Quest_Assistant.Core.NarratorMute"
import "LOTRO_Quest_Assistant.Core.QuestStateManager"
import "LOTRO_Quest_Assistant.Core.QuestDiag"
import "LOTRO_Quest_Assistant.Core.QuestEventParser"
import "LOTRO_Quest_Assistant.Core.LanguageSettings"
-- Helper de misiones de grupo (color/icono/textos compartidos por las 4
-- ventanas) -- necesita GroupQuestDB (cargado arriba) y LanguageSettings
-- (justo arriba); tiene que estar ANTES de la UI (paso 5).
import "LOTRO_Quest_Assistant.Core.GroupQuest"
-- Etiquetas Diaria/Semanal + "apropiada para tu nivel" (necesita
-- QuestLockDB y LanguageSettings, ambos arriba).
import "LOTRO_Quest_Assistant.Core.QuestTags"

import "LOTRO_Quest_Assistant.Core.MoorMapZoneResolver"
import "LOTRO_Quest_Assistant.Persistence.GatherPointsStore"
import "LOTRO_Quest_Assistant.Core.GatherEventParser"

-- 4. Load Adapters
import "LOTRO_Quest_Assistant.Legacy.MoorMapAdapter"
import "LOTRO_Quest_Assistant.Legacy.WaypointAdapter"
import "LOTRO_Quest_Assistant.Legacy.LocationAdapter"
import "LOTRO_Quest_Assistant.Legacy.MoorMapCustomAnnotations"

-- 5. Load UI
-- ChestsWindow.lua ya NO se importa (sesion 35): su contenido (Puntos de
-- Interes, Tropas y Amenazas) se fusiono dentro de QuestSyncWindow.lua como
-- secciones desplegables -- pedido explicito del usuario de tener 1 sola
-- ventana en vez de 2. Archivo queda en disco sin usar (mismo criterio que
-- FarmingDB.lua/QuestLocES.lua).
import "LOTRO_Quest_Assistant.UI.QuestInfoTooltip"
-- QuestBookWindow.lua (2026-08-28, pedido explicito del usuario): ventana
-- tipo "libro" que se abre sola al aceptar/completar CUALQUIER mision de
-- las 14.824, con el texto narrado real de esa mision -- ver el historial
-- completo en ese archivo (por que no replica el arbol de dialogo de
-- MEMLotro, y por que no usa ninguno de sus assets con licencia).
import "LOTRO_Quest_Assistant.UI.MEMBookStyle"
import "LOTRO_Quest_Assistant.UI.QuestBookWindow"
import "LOTRO_Quest_Assistant.UI.QuestTrackerHUD"
import "LOTRO_Quest_Assistant.UI.QuestSyncWindow"
import "LOTRO_Quest_Assistant.UI.QuestSyncLauncher"
-- GatherCaptureButton.lua REACTIVADO (2026-08-23): con la reparacion de
-- GatherPointsStore.Initialize() ya confirmada estable (reinicio completo,
-- sin cierres) y con GatherWindow (otra Turbine.UI.Lotro.Window nueva, con
-- botones/controles) tambien confirmada sin cierres, se retoma esta ventana
-- -- la causa real de los cierres nunca fue una ventana nueva, fue el
-- timing de PluginData.Load, ya resuelto.
-- GatherMapView.lua ELIMINADO (2026-08-23): era el visor de mapa propio de
-- GatherWindow (imagenes .jpg chicas + marcadores dibujados a mano) -- 6
-- rondas de prueba en vivo sin lograr que funcionara. GatherWindow.lua ahora
-- muestra el mapa REAL de la zona (datos copiados de MoorMap, ver
-- Data/MoorMapZones.lua) directo dentro de esta ventana -- pedido explicito
-- del usuario, ver historial completo en UI/GatherWindow.lua.
import "LOTRO_Quest_Assistant.UI.GatherCaptureButton"
import "LOTRO_Quest_Assistant.UI.GatherNodeTooltip"
import "LOTRO_Quest_Assistant.UI.GatherWindow"

-- Initialize state manager
QuestStateManager.Initialize()
LanguageSettings.Initialize()

-- (2026-09-27) Registro de diagnostico (Core/QuestDiag.lua): su carga se
-- demora 6 s por la misma razon que GatherPointsStore (abajo, 3 s): nunca
-- dos Turbine.PluginData.Load en el mismo instante al entrar.
local diagInitTimer = Turbine.UI.Control()
diagInitTimer.fireAt = Turbine.Engine.GetGameTime() + 6
diagInitTimer.Update = function()
    if Turbine.Engine.GetGameTime() >= diagInitTimer.fireAt then
        diagInitTimer:SetWantsUpdates(false)
        QuestDiag.Initialize()
    end
end
diagInitTimer:SetWantsUpdates(true)

-- GatherSync: GatherPointsStore.Initialize() (su unica llamada real a
-- Turbine.PluginData.Load) se demora a proposito en vez de dispararse en el
-- mismo instante que las 2 de arriba -- ver nota grande al principio del
-- archivo para el porque. Mismo patron de espera que ya usa este archivo
-- mas abajo (LQA_ChatHookWatcher): Turbine.UI.Control + SetWantsUpdates +
-- Turbine.Engine.GetGameTime().
local gatherInitTimer = Turbine.UI.Control()
gatherInitTimer.fireAt = Turbine.Engine.GetGameTime() + 3
gatherInitTimer.Update = function()
    if Turbine.Engine.GetGameTime() >= gatherInitTimer.fireAt then
        gatherInitTimer:SetWantsUpdates(false)
        GatherPointsStore.Initialize()
    end
end
gatherInitTimer:SetWantsUpdates(true)

-- GatherSync: cuando GatherEventParser reconoce la linea "Tomando los
-- contenidos de X..." y despues llega la respuesta real de /loc (escrita a
-- mano por el jugador), consumimos el nodo pendiente y guardamos el punto.
-- Ver Arquitectura_GatherSync.md #3 para el diagrama completo de este flujo.
LocationAdapter.OnLocationResolved = function(region, ns, ew, lx, ly)
    local entry = GatherEventParser.ConsumePendingGather()
    if entry ~= nil then
        GatherPointsStore.AddPoint(entry, ns, ew, region)
    end
end

-- GatherSync: cuando se guarda un punto NUEVO (no una actualizacion de uno
-- ya visto -- GATHER_POINT_UPDATED es un evento aparte, ver
-- GatherPointsStore.AddPoint), se registra ademas como anotacion PERSISTENTE
-- real en MoorMap (pedido explicito del usuario, ver historial completo en
-- Legacy/MoorMapCustomAnnotations.lua). MINERO=43(Ore), LEÑADOR=44(Wood),
-- ERUDITO=45(Scholar); GRANJERO=46(Cook Ingredient) -- MoorMap no tiene un
-- tipo dedicado de nodo de Granjero, ver nota completa en ese mismo archivo.
local GATHER_TO_MOORMAP_TYPE = {
    MINERO = 43,
    ["LEÑADOR"] = 44,
    ERUDITO = 45,
    GRANJERO = 46,
}
LQA.Core.EventBus:Subscribe("GATHER_POINT_ADDED", function(data)
    if not (data and data.point) then return end
    local mmType = GATHER_TO_MOORMAP_TYPE[data.profession]
    if mmType == nil or data.point.region == nil then return end
    MoorMapCustomAnnotations.RegisterNode(
        data.point.region, data.point.ns, data.point.ew,
        mmType, data.point.tier, data.point.node, data.point.node
    )
end)

-- Create UI instances (localization + state are fully loaded by this point)
_G.HUD = LQA.UI.QuestTrackerHUD()
_G.MainWindow = QuestSyncWindow()
_G.MainWindow:SetVisible(false) -- Hide by default

-- Instanciada temprano (oculta por defecto, ver su propio Constructor) para
-- que su suscripcion a QUEST_JUST_ACCEPTED/QUEST_JUST_COMPLETED este activa
-- desde el arranque -- si se creara mas tarde/perezosa (patron GetInstance
-- de QuestInfoTooltip/GatherNodeTooltip) se perderia la primera mision
-- aceptada/completada de la sesion.
_G.QuestBookWindow = LQA.UI.QuestBookWindow()

-- GatherSync: ventana "Recoleccion" (mapa con los puntos guardados), oculta
-- por defecto (ver UI/GatherWindow.lua). Su propio constructor no llama a
-- Turbine.PluginData.Load (solo lee GatherPointsStore.Points, que ya existe
-- vacio de entrada aunque GatherPointsStore.Initialize() todavia no haya
-- terminado de cargar) asi que instanciarla aca no reintroduce el problema
-- de las 3 cargas simultaneas que causaba los cierres.
_G.GatherWindow = LQA.UI.GatherWindow()

-- Icono flotante y arrastrable, siempre en pantalla: un clic abre/cierra
-- las dos ventanas de arriba juntas. MainWindow y HUD ya deben existir
-- (ToggleWindows los usa por su global _G).
_G.Launcher = LQA.UI.QuestSyncLauncher()

-- GatherSync: boton flotante oculto por defecto, solo aparece cuando se
-- detecta un nodo de recoleccion (ver UI/GatherCaptureButton.lua).
-- Reactivado -- ver nota junto al import mas arriba.
_G.GatherCaptureButton = LQA.UI.GatherCaptureButton()


-- Diagnostico de arranque: solo una vez por sesion, no es ruido recurrente,
-- pero el detalle linea-por-linea queda detras del interruptor igual --
-- el jugador solo necesita ver la confirmacion final.
local qCount = "Desconocido"
if _G.QuestDB and _G.QuestDB.quests then
    local c = 0
    for k, v in pairs(_G.QuestDB.quests) do c = c + 1 end
    qCount = tostring(c)
end
if LQA.Debug.Enabled then
    Turbine.Shell.WriteLine("<rgb=#FFFF00>QuestSync DEBUG: _G.QuestDB cargado = " .. tostring(_G.QuestDB ~= nil) .. "</rgb>")
    Turbine.Shell.WriteLine("<rgb=#FFFF00>QuestSync DEBUG: Quest count = " .. qCount .. "</rgb>")
end
Turbine.Shell.WriteLine("<rgb=#00FF00>QuestSync: Addon unificado inicializado con " .. qCount .. " misiones.</rgb>")

QuestSyncCommand = Turbine.ShellCommand()
function QuestSyncCommand:Execute(command, arguments)
    if _G.MainWindow:IsVisible() then
        _G.MainWindow:SetVisible(false)
    else
        _G.MainWindow:SetVisible(true)
    end
end
Turbine.Shell.AddCommand("questsync;qs", QuestSyncCommand)
Turbine.Shell.WriteLine("Usa /questsync para abrir la ventana principal.")

-- /cofres se deja como alias de /questsync (sesion 35): Puntos de Interes
-- ahora es una seccion desplegable DENTRO de la ventana unica, ya no una
-- ventana aparte, pero el comando viejo se mantiene para no romper el habito
-- del usuario.
ChestsCommand = Turbine.ShellCommand()
function ChestsCommand:Execute(command, arguments)
    if _G.MainWindow:IsVisible() then
        _G.MainWindow:SetVisible(false)
    else
        _G.MainWindow:SetVisible(true)
        _G.MainWindow:SelectTab("puntos")
    end
end
Turbine.Shell.AddCommand("cofres;qcofres", ChestsCommand)
Turbine.Shell.WriteLine("Usa /cofres para abrir la ventana principal en la pestaña Puntos de Interes.")

-- GatherSync: /recoleccion abre/cierra la ventana de mapa de puntos.
GatherWindowCommand = Turbine.ShellCommand()
function GatherWindowCommand:Execute(command, arguments)
    if _G.GatherWindow:IsVisible() then
        _G.GatherWindow:SetVisible(false)
    else
        _G.GatherWindow:SetVisible(true)
    end
end
Turbine.Shell.AddCommand("recoleccion;qrecoleccion", GatherWindowCommand)
Turbine.Shell.WriteLine("Usa /recoleccion para ver el mapa de puntos de recolección.")

-- Chat handler for quest events
local function OnChatReceived(sender, args)
    if not args then return end
    local chatType = args.ChatType
    local message = tostring(args.Message)
    
    -- Ignore our own debug messages to avoid infinite loops
    if string.find(message, "QuestSync:") then return end
    -- (2026-09-27) Las lineas con "<rgb=" se descartaban SIEMPRE, pero el
    -- juego manda asi el progreso de 2.469 misiones (objetivo con el verbo
    -- coloreado). Del canal de Misiones ya no se descartan (nuestros propios
    -- avisos nunca van a ese canal); del resto se siguen descartando.
    if string.find(message, "<rgb=", 1, true) and chatType ~= Turbine.ChatType.Quest then return end

    if chatType == Turbine.ChatType.Quest then
        if LQA.Debug.Enabled then
            Turbine.Shell.WriteLine("<rgb=#00FFFF>QuestSync RAW CHAT (Quest): " .. message .. "</rgb>")
        end
        QuestEventParser.ParseMessage(sender, message, true)
    elseif chatType == Turbine.ChatType.Standard then
        -- Only send Standard to parser if it contains likely quest info (e.g. numbers) to reduce spam
        if string.find(message, "/") or string.find(message, ":") then
            QuestEventParser.ParseMessage(sender, message)
        end
    end
end

-- GatherSync: chat handler separado de OnChatReceived a proposito -- las
-- lineas que nos interesan ("Tomando los contenidos de X...") NO tienen "/"
-- ni ":", asi que el filtro de Standard de arriba las descartaria antes de
-- llegar a ningun parser. Sin filtro de tipo de canal tampoco: se prueban
-- las 2 lineas de interes (nodo + item) y la respuesta de /loc contra
-- CUALQUIER mensaje de chat. Seguro porque los patrones estan anclados con
-- "^" y son muy especificos -- no hay riesgo real de falso positivo.
local function OnGatherChatReceived(sender, args)
    if not args then return end
    local message = tostring(args.Message)
    if string.find(message, "QuestSync:") or string.find(message, "GatherSync:") or string.find(message, "<rgb=") then return end

    if LocationAdapter.ParseLocationMessage(message) then return end
    GatherEventParser.ParseMessage(sender, message)
end

-- BUG (encontrado 2026-08-19, confirmado en vivo con Debug.Enabled=true: CERO
-- lineas "CHAT INTERCEPT" para mensajes de chat reales, aunque el resto del
-- addon -- EventBus, arranque, PopulateList -- funcionaba perfecto). Dos
-- causas, la segunda mas grave que la primera:
--
-- 1) Otros addons que este proyecto depende de tener activos (confirmado
--    leyendo su codigo REAL instalado, no adivinado): Lunarwater/Waypoint.lua
--    linea 186, Esy/ChatNotif/NotifWindow.lua linea 138, WalmPlugins/
--    WarbandsSlayer/WarbandsDialog.lua linea 420 hacen
--    "Turbine.Chat.Received = function...end" de forma INCONDICIONAL. El
--    orden de carga real del cliente no esta bajo nuestro control, asi que
--    cualquiera de ellos puede pisar nuestro registro sin avisar.
--
-- 2) MAS GRAVE, causa real de que la version anterior de este mismo fix
--    siguiera sin funcionar: GaranStuff/MoorMap/Main.lua:201 (funcion
--    AddCallback, copiada palabra por palabra tambien en Esy/ChatNotif,
--    Souru/VitalSelf, RodneyMitchell/WorldChatFilter, TravelWindowII, pureba
--    y QA_ChatProbe_Test -- 7 addons independientes de acuerdo en el mismo
--    contrato) deja claro que Turbine.Chat.Received puede terminar siendo
--    UNA TABLA de funciones, no solo nil/una-funcion -- MoorMap la usa asi
--    para registrarse sin pisar a nadie.
--
-- 2026-08-20, UNIFICADO con CubePlugins/DeedTracker: ese addon (tambien de
-- este usuario) ya tenia su PROPIO esquema compartido pensado para
-- interoperar con QuestSync (_G.LQA_ChatListeners/_G.LQA_ChatHookInstalled
-- en DeedTracker/ChatLogger.lua, comentario "QUESTSYNC INTEGRATION" en el
-- codigo fuente) -- pero este archivo nunca lo usaba, tenia su propio
-- _G.LQA_ChatHookRef aislado. Resultado real: si QuestSync cargaba primero,
-- DeedTracker nunca instalaba el dispatcher compartido (su listener quedaba
-- registrado pero nadie lo llamaba); si DeedTracker cargaba primero, su
-- propio dispatcher (que tampoco encadenaba sobre un handler previo de un
-- 3er addon) pisaba todo. Ambos archivos ahora usan el MISMO contrato:
-- _G.LQA_ChatListeners[nombre] = funcion, y CUALQUIERA de los 2 que cargue
-- primero instala el dispatcher compartido (encadenando sobre lo que ya
-- hubiera, nil/funcion/tabla) + un watchdog que lo reinstala si un 3er addon
-- mal comportado lo pisa. Ver la misma logica en DeedTracker/ChatLogger.lua.
if not _G.LQA_ChatListeners then
    _G.LQA_ChatListeners = {}
end

local function LQA_InstallSharedDispatcher()
    if _G.LQA_ChatHookRef == Turbine.Chat.Received and _G.LQA_ChatHookRef ~= nil then
        return -- ya somos nosotros (o DeedTracker ya lo instalo), nada que hacer
    end
    local current = Turbine.Chat.Received
    local dispatcher = function(sender, args)
        if type(current) == "function" then
            pcall(current, sender, args)
        elseif type(current) == "table" then
            for _, fn in ipairs(current) do pcall(fn, sender, args) end
        end
        for _, listener in pairs(_G.LQA_ChatListeners) do
            pcall(listener, sender, args)
        end
    end
    Turbine.Chat.Received = dispatcher
    _G.LQA_ChatHookRef = dispatcher
    _G.LQA_ChatHookInstalled = true
end

_G.LQA_ChatListeners["QuestSync"] = OnChatReceived
_G.LQA_ChatListeners["GatherSync"] = OnGatherChatReceived

if not _G.LQA_ChatHookWatcher then
    LQA_InstallSharedDispatcher()

    -- Watchdog: reinstala el dispatcher compartido si un addon mal
    -- comportado (punto 1 de arriba) vuelve a pisar Turbine.Chat.Received
    -- por completo. Intervalo de 1s (bajado de 3s en la sesion anterior).
    _G.LQA_ChatHookWatcher = Turbine.UI.Control()
    _G.LQA_ChatHookWatcher.nextCheck = Turbine.Engine.GetGameTime() + 1
    _G.LQA_ChatHookWatcher.Update = function(sender, args)
        if Turbine.Engine.GetGameTime() >= _G.LQA_ChatHookWatcher.nextCheck then
            LQA_InstallSharedDispatcher()
            _G.LQA_ChatHookWatcher.nextCheck = Turbine.Engine.GetGameTime() + 1
        end
    end
    _G.LQA_ChatHookWatcher:SetWantsUpdates(true)
else
    -- DeedTracker (u otra carga previa de este mismo esquema) ya instalo el
    -- dispatcher y el watchdog -- solo hacia falta registrar nuestro propio
    -- listener arriba, ya hecho.
    LQA_InstallSharedDispatcher()
end
