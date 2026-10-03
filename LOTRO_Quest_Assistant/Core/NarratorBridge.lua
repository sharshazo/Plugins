-- LOTRO_Quest_Assistant/Core/NarratorBridge.lua
--
-- Puente hacia LOTRO_Chat_Narrator/Narrador_IA (addon externo + app Python,
-- ver LOTRO_Chat_Narrator/Main.lua): al pedir "Narrar" sobre una mision
-- desde el Tracker (o al detectarla/avanzarla sola, ver mas abajo), escribe
-- su texto en un archivo Turbine.PluginData de CUENTA distinto del feed de
-- chat pasivo (LOTRO_Narrator_PlayRequest, no LOTRO_Narrator_Feed) -- asi
-- Narrador_IA lo puede tratar como pedido EXPLICITO del jugador: se lee con
-- prioridad y sin los filtros de canal/duplicado/largo que aplican al chat
-- ambiental.
--
-- Texto usado: QuestLocES[ndx].objectivesES (misma fuente ya usada por
-- QuestLocResolver/QuestInfoTooltip/QuestBookWindow), SIN el filtro
-- IsFlavorText -- para narrar se quiere justo lo que esos otros lugares
-- descartan a proposito (lineas de dialogo/exclamacion de PNJ), ademas de
-- las lineas de objetivo limpias. Nunca se inventa texto nuevo, solo se
-- cambia el filtro sobre el mismo dato ya extraido.
--
-- Tambien se manda quest.bestower (el NPC que da la mision, campo real de
-- QuestDB -- ver Data/QuestDatabase_*.lua) -- pedido explicito del usuario
-- (2026-09-01): que el mismo NPC siempre narre sus propias misiones con la
-- MISMA voz, y que distintos NPCs usen voces distintas. La eleccion de CUAL
-- voz le toca a cada NPC vive del lado de Narrador_IA (src/npc_voice.py,
-- hash estable del nombre, o un override en config.yaml para NPCs
-- principales) -- este addon no decide voces, solo informa quien habla.
import "Turbine"

_G.NarratorBridge = {}

local PLAY_REQUEST_KEY = "LOTRO_Narrator_PlayRequest"
local MAX_ENTRIES = 12
local nextRequestId = 1

-- Ring buffer, no un slot unico (2026-09-02): con narracion automatica dos
-- eventos pueden dispararse casi seguidos (aceptar + primer progreso) y con
-- un solo registro el segundo Save() pisaria al primero antes de que
-- Narrador_IA (que sondea cada ~0.3s) llegue a leerlo. Mismo patron de ring
-- buffer que ya usa LOTRO_Chat_Narrator/Main.lua para el feed de chat.
local entries = {}

-- BUG (encontrado 2026-09-02 al precalentar la cache de audio con misiones
-- reales): QuestLocES/objectivesES trae sin resolver la sintaxis de
-- plantilla de genero del jugador, p.ej. "${PLAYERNAME:campeon[m]|campeona[f]}".
-- El resto de QuestSync nunca la ve porque QuestLocResolver.GetCleanObjectiveLines
-- la descarta via IsFlavorText (isCleanText rechaza cualquier linea con "${") --
-- pero PlayQuestText bypasea ESE filtro a proposito para narrar dialogo/flavor
-- (ver comentario de cabecera), y como efecto secundario no querido tambien
-- dejaba pasar la plantilla sin resolver, que se leeria literal en voz alta.
-- Sin dato real de genero del jugador en QuestDB, se resuelve siempre a la
-- variante [m]; cualquier otro "${...}" que no matchee ese formato se
-- descarta entero (mejor silencio que leer sintaxis de plantilla en voz alta).
--
-- BUG #2 (encontrado 2026-09-02, auditoria completa de las 14824 misiones):
-- el patron de arriba asumia que la variante [m] SIEMPRE viene primero, pero
-- el dato fuente tambien trae el orden invertido (ej.
-- "${PLAYERNAME:hermana[f]|hermano[m]}") -- ademas de la variable
-- "${PLAYER:...}" (sin "NAME") con el mismo problema de orden. Peor aun: el
-- comodin perezoso ".-" original no excluia "}", asi que ante el orden
-- invertido (que no matcheaba) el patron podia "cruzar por encima" del "}"
-- de ESTE template y seguir buscando un "[m]" en el texto siguiente,
-- dejando fragmentos rotos tipo "hermana[f]|hermano[m]}" sueltos (confirmado
-- en vivo: ndx 6552). Fix: 4 patrones especificos (NAME/sin-NAME x orden
-- m-primero/f-primero) con clases de caracteres que EXCLUYEN "{" y "}", asi
-- ningun match puede cruzar el limite de su propio template.
local function ResolveGenderTemplate(text)
	if not text or text == "" then return text end
	text = string.gsub(text, "%$%{PLAYERNAME:([^|{}]-)%[m%]%s*|[^{}]-%[f%]%s*%}", "%1")
	text = string.gsub(text, "%$%{PLAYERNAME:[^|{}]-%[f%]%s*|([^{}]-)%[m%]%s*%}", "%1")
	text = string.gsub(text, "%$%{PLAYER:([^|{}]-)%[m%]%s*|[^{}]-%[f%]%s*%}", "%1")
	text = string.gsub(text, "%$%{PLAYER:[^|{}]-%[f%]%s*|([^{}]-)%[m%]%s*%}", "%1")
	text = string.gsub(text, "%$%{[^}]*%}", "")
	return text
end

-- BUG/limite (encontrado 2026-09-02, reporte en vivo del usuario: "no
-- escucho nada"): algunas misiones tipo "libro/capitulo" acumulan TODO el
-- dialogo narrativo de QuestLocES[ndx].objectivesES (cada linea de cada
-- etapa, no solo la actual) -- una mision real midio 3968 caracteres
-- (~625 palabras), varios minutos solo para sintetizar con Piper, mas
-- varios minutos mas de audio. Nadie quiere un monologo de 5+ minutos por
-- aceptar una mision. Se corta en el punto de frase mas cercano al limite
-- (nunca a la mitad de una oracion) en vez de tijeretear a lo bruto.
local MAX_NARRATION_CHARS = 700

local function TruncateAtSentence(text, maxChars)
	if string.len(text) <= maxChars then return text end
	local cut = string.sub(text, 1, maxChars)
	local lastPeriod = nil
	local searchStart = 1
	while true do
		local s = string.find(cut, "%. ", searchStart)
		if not s then break end
		lastPeriod = s
		searchStart = s + 1
	end
	-- Solo usar el corte por oracion si no deja el texto demasiado corto
	-- (mision con una sola frase gigante, sin puntos tempranos) -- si no,
	-- mejor cortar a lo bruto que perder casi todo el contenido.
	if lastPeriod and lastPeriod > maxChars * 0.4 then
		return string.sub(cut, 1, lastPeriod)
	end
	return cut .. "..."
end

-- Efectos de sonido de UI (SignalSfx/SFX_KEY) RETIRADOS POR COMPLETO
-- (pedido explicito del usuario, 2026-09-03: "eliminaremos los sonidos que
-- incorporamos de mp3 de los addons"). Motivo real, confirmado en vivo:
-- Turbine.PluginData.Save (el UNICO mecanismo que Turbine le da a un addon
-- Lua para avisar a un programa externo -- sin io.*, sin os.execute, sin
-- red) no escribe al instante: el cliente de LOTRO junta los guardados
-- pendientes de TODOS los addons y los procesa en un ciclo propio, variable
-- entre ~2 y ~15s, sea cual sea el scope o cuantos datos se guarden -- no
-- hay forma de evitarlo desde este archivo. Un sonido que puede tardar hasta
-- 15s en aparecer no cumple ningun proposito real, asi que se saca la
-- funcion entera en vez de dejarla sin uso.

local function QueueRequest(title, text, npc)
	text = ResolveGenderTemplate(text)
	text = TruncateAtSentence(text, MAX_NARRATION_CHARS)
	nextRequestId = nextRequestId + 1
	table.insert(entries, {
		id = nextRequestId,
		title = title or "",
		text = text or "",
		npc = npc or "",
	})
	while #entries > MAX_ENTRIES do
		table.remove(entries, 1)
	end
	Turbine.PluginData.Save(Turbine.DataScope.Account, PLAY_REQUEST_KEY, { entries = entries })
end

-- BUG (2026-09-05, reporte del usuario: "a veces repite 2 veces el
-- titulo"): esta funcion arranca `parts` con el titulo (esName/nameEN,
-- linea de abajo) y despues vuelca objectivesES/stages CRUDOS, a
-- proposito SIN pasar por QuestLocResolver.IsFlavorText (ver la nota
-- grande de cabecera del archivo: se quiere justo el dialogo/exclamacion
-- de PNJ que ese filtro descarta en otros lugares). Pero IsFlavorText
-- hace 2 trabajos a la vez -- descartar dialogo citado Y descartar
-- lineas iguales al nombre de la mision (`s == nameEN`, ver
-- QuestLocResolver.lua) -- al bypasear TODO el filtro para conservar el
-- primero, tambien se perdio el segundo: si una mision no tiene
-- traduccion real al español (esName cae a nameEN) Y su objectivesES[1]
-- crudo repite el nombre en ingles (patron real confirmado en la base),
-- el resultado narrado quedaba "Titulo. Titulo. resto..." -- el titulo
-- sonaba 2 veces. Fix quirurgico: se sigue sin filtrar dialogo/
-- exclamacion (eso no cambia), pero se descarta puntualmente cualquier
-- linea (de objectivesES O de las etapas) que sea un duplicado EXACTO
-- del titulo ya puesto en parts[1] -- mismo criterio de comparacion que
-- ya usa IsFlavorText, aplicado sin heredar el resto de sus reglas.
-- Compartido por PlayQuestText (mision activa) y AnnounceCompleted (mision
-- completada, ver mas abajo) -- extraido 2026-09-06 tras bug reportado por
-- el usuario ("el boton narrar del questbook solo narra el titulo, el texto
-- de abajo no"): AnnounceCompleted armaba su propio texto de 1 sola linea
-- ("Mision completada: <titulo>") sin pasar nunca por objectivesES/
-- QuestStagesCoords, a diferencia de PlayQuestText -- por eso narrar una
-- mision recien completada desde el libro (QuestBookWindow.lua, que abre
-- automaticamente en QUEST_JUST_COMPLETED) sonaba como "solo el titulo".
-- Se factoriza aca la recoleccion de objetivos/etapas para que ambas rutas
-- narren el mismo contenido real, mismo criterio que ya se aplico antes con
-- MoorMapAdapter.ResolveMapID/ResolveQuestLoc (logica duplicada = bugs).
local function CollectQuestNarrationParts(ndx, quest, title)
	local parts = {}
	local function isDuplicateTitle(s)
		return s == title or s == quest.nameEN
	end

	local loc = _G.QuestLocES and _G.QuestLocES[ndx]
	local obj = loc and type(loc) == "table" and loc.objectivesES
	if obj and type(obj) == "table" then
		for i = 1, #obj do
			if obj[i] and obj[i] ~= "" and not isDuplicateTitle(obj[i]) then
				table.insert(parts, obj[i])
			end
		end
	end

	-- Puntos/objetivos paso a paso -- misma fuente que usa el marcador de
	-- mapa de cada etapa (ver QuestSyncWindow:SelectQuest, QuestStagesCoords
	-- ya viene importado como Data antes que este Core, siempre disponible
	-- en runtime). Pedido explicito del usuario (2026-09-01): "que lea...
	-- la mision y sus puntos y que hacer" -- narracion completa, no solo el
	-- texto narrativo/flavor de arriba.
	local stages = _G.QuestStagesCoords and _G.QuestStagesCoords[ndx]
	if stages and type(stages) == "table" then
		for i = 1, #stages do
			local stage = stages[i]
			local stageText = stage.name
			if _G.LanguageSettings and LanguageSettings.IsSpanish() and stage.nameES and stage.nameES ~= "" then
				stageText = stage.nameES
			end
			if stageText and stageText ~= "" and not isDuplicateTitle(stageText) then
				table.insert(parts, stageText)
			end
		end
	end

	return parts
end

function NarratorBridge.PlayQuestText(ndx, quest, esName)
	if not quest then return end

	local title = esName or quest.nameEN or ""
	local parts = { title }
	for _, p in ipairs(CollectQuestNarrationParts(ndx, quest, title)) do
		table.insert(parts, p)
	end

	QueueRequest(title, table.concat(parts, ". "), quest.bestower)
end

-- Narracion MANUAL UNICAMENTE (2026-09-03, pedido explicito del usuario:
-- "eliminaremos... la narracion automatica cuando aceptamos, completamos o
-- activamos una mision.. sera solo manual al clickear el boton narrar").
-- Antes estas 3 funciones se disparaban solas via EventBus al aceptar/
-- avanzar/completar una mision (ver las suscripciones, mas abajo, ahora
-- comentadas) -- la razon del cambio es la misma que llevo a sacar los SFX
-- de UI (ver la nota grande arriba, donde vivia SignalSfx): Turbine.PluginData.Save
-- tiene un piso de ~2-15s antes de que Narrador_IA vea el pedido (confirmado
-- en vivo), asi que una narracion "automatica" en realidad
-- aparece varios segundos despues del evento real, sintiendose desconectada
-- de lo que la disparo. Las funciones se DEJAN intactas (PlayQuestText/
-- AnnounceProgress/AnnounceCompleted) porque los botones "Narrar" manuales
-- (QuestTrackerHUD.lua, QuestSyncWindow.lua, QuestBookWindow.lua) las siguen
-- llamando a pedido explicito del jugador -- ahi la demora es la misma, pero
-- el jugador SABE que clickeo, asi que no se siente "roto".
NarratorBridge._lastProgress = {}

local function ResolveNameAndQuest(ndx)
	local quest = _G.QuestDB and QuestDB.quests and QuestDB.quests[ndx]
	if not quest then return nil, nil end
	local esName = _G.QuestLocResolver and QuestLocResolver.GetQuestNameES(ndx, quest.nameEN) or quest.nameEN
	return quest, esName
end

function NarratorBridge.AnnounceProgress(ndx, progressText)
	if not progressText or progressText == "" then return end
	-- Dedupe: QUEST_PROGRESS puede republicarse con el mismo texto (p.ej. la
	-- reafirmacion de estado ACTIVA via texto narrativo, ver
	-- QuestEventParser.lua) -- solo se narra cuando el progreso realmente
	-- cambio de valor.
	if NarratorBridge._lastProgress[ndx] == progressText then return end

	-- BUG (encontrado en verificacion, 2026-09-02): antes se marcaba
	-- _lastProgress[ndx] ACA, antes de confirmar que QuestDB/QuestLocResolver
	-- lograron resolver la mision. Si esa resolucion fallaba (ndx invalido,
	-- o QuestDB aun no cargado en ese instante), el progreso quedaba
	-- marcado como "ya narrado" para siempre sin haberse narrado nunca --
	-- una repeticion legitima del mismo evento mas tarde se hubiera
	-- descartado por el dedupe. Fix: solo se marca DESPUES de confirmar que
	-- se pudo resolver (mismo orden que ya usaba AnnounceCompleted).
	local quest, esName = ResolveNameAndQuest(ndx)
	if not quest then return end

	-- Sin SFX de progreso (pedido explicito del usuario, 2026-09-03: "solo
	-- deben ir los sonidos que yo entregue como mp3" -- no hay mp3 real
	-- para este evento).
	NarratorBridge._lastProgress[ndx] = progressText
	QueueRequest(esName, esName .. ": " .. progressText, quest.bestower)
end

function NarratorBridge.AnnounceCompleted(ndx)
	local quest, esName = ResolveNameAndQuest(ndx)
	if not quest then return end
	NarratorBridge._lastProgress[ndx] = nil

	local opening = "Mision completada: " .. esName
	local parts = { opening }
	for _, p in ipairs(CollectQuestNarrationParts(ndx, quest, esName)) do
		table.insert(parts, p)
	end

	QueueRequest(esName, table.concat(parts, ". "), quest.bestower)
end

-- Suscripciones automaticas RETIRADAS (pedido explicito del usuario,
-- 2026-09-03) -- ver la nota grande arriba. Las funciones siguen vivas y se
-- llaman a mano desde los botones "Narrar" (PlayQuestText/AnnounceCompleted)
-- y desde QuestBookWindow.lua (AnnounceCompleted, boton Narrar del libro).
--
-- LQA.Core.EventBus:Subscribe("QUEST_JUST_ACCEPTED", function(data)
-- 	local quest, esName = ResolveNameAndQuest(data.ndx)
-- 	if quest then
-- 		NarratorBridge.PlayQuestText(data.ndx, quest, esName)
-- 	end
-- end)
--
-- LQA.Core.EventBus:Subscribe("QUEST_PROGRESS", function(data)
-- 	NarratorBridge.AnnounceProgress(data.ndx, data.progress)
-- end)
--
-- LQA.Core.EventBus:Subscribe("QUEST_JUST_COMPLETED", function(data)
-- 	NarratorBridge.AnnounceCompleted(data.ndx)
-- end)

-- Cortar narracion al cambiar de mapa/zona o de personaje (2026-09-02,
-- pedido explicito del usuario). Investigado y confirmado: la API de
-- Turbine Lua NO tiene un evento real de cambio de zona ni de cambio de
-- personaje -- ni QuestSync, ni LOTRO_Chat_Narrator, ni DeedTracker (que ya
-- resolvio este mismo problema antes, ver CubePlugins/DeedTracker/
-- ChatLogger.lua) usan uno, porque no existe. El unico mecanismo real y ya
-- probado en este codebase es leer del chat de sistema las notificaciones
-- de canal regional que aparecen al entrar/salir de una zona o instancia:
-- "Entro en X - Regional" / "Salio de X - Regional" (patrones EXACTOS
-- tomados de CubePlugins/DeedTracker/Strings.lua, no adivinados). No es
-- 100% infalible -- el propio DeedTracker anota que a veces esas
-- notificaciones no llegan -- pero es lo unico que existe.
-- BUG (2026-09-05, reporte del usuario: "narracion sigue hablando cuando
-- cambio de personaje"): stopCounter era una variable LOCAL de Lua -- se
-- reinicia a 0 en CADA carga del addon (justo lo que pasa al cambiar de
-- personaje/relog/reloadui, ver la nota grande de abajo). El lado
-- Narrador_IA (src/plugindata.py, StopSignalReader.poll) solo detecta el
-- corte cuando el "count" guardado CAMBIA respecto al ultimo que vio --
-- pero si el jugador cambia de personaje SIN pasar por ningun cambio de
-- zona en el medio (stopCounter nunca sube mas alla de 1 en esa sesion),
-- la 1ra llamada de SignalStop() de la sesion NUEVA vuelve a escribir
-- exactamente el mismo "count=1" que la sesion VIEJA ya habia escrito --
-- Narrador_IA ve el mismo numero de siempre, no detecta cambio, y sigue
-- reproduciendo lo que tenia en cola del personaje anterior. Confirmado
-- que "a veces" no pasaba (cuando SI hubo cambios de zona de por medio,
-- el conteo coincidia con otro valor por casualidad).
--
-- Fix: en vez de un contador que arranca de 0 cada vez, se manda la hora
-- real del motor en milisegundos (Turbine.Engine.GetGameTime(), ya usado
-- en otros lugares de este addon -- QuestStateManager.lua, por ejemplo).
-- Es un numero que SOLO crece durante toda la sesion del cliente de LOTRO
-- (sobrevive cambios de personaje, que no reinician el cliente) -- 2
-- llamadas a SignalStop(), sean del mismo personaje o de personajes
-- distintos, nunca van a coincidir en el mismo milisegundo. El campo
-- sigue llamandose "count" y sigue siendo un entero (math.floor) --
-- StopSignalReader.poll() en Narrador_IA no necesita ningun cambio, solo
-- le importa que el numero sea DISTINTO al anterior, y con esto siempre
-- lo es.
local STOP_KEY = "LOTRO_Narrator_Stop"

local function SignalStop()
	local stamp = math.floor(Turbine.Engine.GetGameTime() * 1000)
	Turbine.PluginData.Save(Turbine.DataScope.Account, STOP_KEY, { count = stamp })
end

-- Cambio de personaje/relog/reloadui: no hay evento para "detectar" esto
-- directamente, pero CUALQUIERA de esos 3 casos recarga el addon entero
-- desde cero -- asi que "al cargar" es el proxy mas cercano disponible.
-- Narrador_IA (proceso aparte de Windows) sigue vivo entre personajes y
-- relogs, y sin esto seguiria reproduciendo narracion del personaje/sesion
-- anterior despues del cambio.
SignalStop()

-- Mismo patron de dispatcher compartido que ya usan Main.lua y
-- LOTRO_Chat_Narrator/Main.lua (ver esos archivos) -- se instala de forma
-- defensiva ACA TAMBIEN porque este archivo se importa antes de que
-- Main.lua llegue a montar el suyo, y LOTRO_Chat_Narrator es un addon
-- aparte que puede no estar activo.
if not _G.LQA_ChatHookWatcher then
	local function LQA_InstallSharedDispatcher()
		if _G.LQA_ChatHookRef == Turbine.Chat.Received and _G.LQA_ChatHookRef ~= nil then
			return
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

	_G.LQA_ChatListeners = _G.LQA_ChatListeners or {}
	LQA_InstallSharedDispatcher()

	_G.LQA_ChatHookWatcher = Turbine.UI.Control()
	_G.LQA_ChatHookWatcher.nextCheck = Turbine.Engine.GetGameTime() + 1
	_G.LQA_ChatHookWatcher.Update = function(sender, args)
		if Turbine.Engine.GetGameTime() >= _G.LQA_ChatHookWatcher.nextCheck then
			LQA_InstallSharedDispatcher()
			_G.LQA_ChatHookWatcher.nextCheck = Turbine.Engine.GetGameTime() + 1
		end
	end
	_G.LQA_ChatHookWatcher:SetWantsUpdates(true)
end

-- BUG encontrado en la verificacion (2026-09-02, mismo tipo de bug que
-- QuestLocResolver.toLowerES ya tuvo antes en este proyecto): la primera
-- version usaba "%a" como comodin para la vocal acentuada ("Entr%a en" en
-- vez de "Entró en"), asumiendo que %a matchea cualquier letra -- pero los
-- patrones de Lua comparan BYTE a byte, y "ó" son 2 bytes UTF-8 (ninguno de
-- los dos es alfabetico en el locale "C"), asi que %a nunca matcheaba la
-- version acentuada real que efectivamente escribe el cliente en español
-- (confirmado probando con el string UTF-8 real: no matcheaba, la deteccion
-- de zona nunca se hubiera disparado). Fix: busqueda LITERAL de subcadena
-- (string.find con plain=true, sin interpretar patron) sobre " - Regional"
-- solo -- aparece igual en el mensaje de entrada y en el de salida, y evita
-- por completo el problema de bytes vs. caracteres UTF-8 al no necesitar
-- matchear la palabra acentuada en absoluto.
_G.LQA_ChatListeners = _G.LQA_ChatListeners or {}
_G.LQA_ChatListeners["NarratorBridge_ZoneWatch"] = function(sender, args)
	if not args or not args.Message then return end
	if args.ChatType ~= Turbine.ChatType.Standard then return end
	local msg = tostring(args.Message)
	if string.find(msg, " - Regional", 1, true) then
		SignalStop()
	end
end
