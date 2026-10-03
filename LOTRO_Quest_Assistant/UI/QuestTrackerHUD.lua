-- LOTRO_Quest_Assistant/UI/QuestTrackerHUD.lua
--
-- REDISEÑO VISUAL "libro" (2026-08-28, pedido explicito del usuario, mismo
-- criterio que QuestBookWindow.lua): SOLO lo cosmetico -- toda la logica
-- funcional de este archivo (suscripciones a EventBus, sinergia con
-- DeedTracker, boton "Ir" con su Quickslot real, SizeChanged) queda
-- IDENTICA, pedido explicito del usuario de no tocar la estructura
-- funcional. Los colores de ESTADO (LightBlue para mision activa, violeta
-- para proezas de DeedTracker, Yellow del encabezado ya alineado a
-- proposito con DeedTracker/MainWin.lua) tampoco cambian -- ver la nota
-- original de cada uno mas abajo, siguen siendo la MISMA decision de
-- paleta de antes, no algo nuevo.
--
-- V2 (mismo dia, pedido explicito del usuario: "adaptemos esta imagen...
-- integremos esto en nuestra ventana flotante tracker"): el panel de
-- fondo tibio de un solo color plano se reemplaza por pergamino con marco
-- de madera y adornos de metal (imagen generada con IA, "Gemini_Generated_
-- Image_8od5y08od5y08od5-Photoroom.png" en Documentos/The Lord of the
-- Rings Online/), recortada a su contenido real (450,14,981,750 del PNG
-- original).
--
-- V3 (mismo dia, pedido explicito del usuario: "sigue el bug al agrandar
-- un poco... que la ventana pueda adaptarse, achicarse, y que se adapte la
-- imagen y lo interno"): la v2 usaba UNA sola imagen de 300x416 con
-- SetMaximumSize como tope -- igual se veia el mosaico si el resize se
-- pasaba un poco, y ademas el pedido real era que se adapte de VERDAD, no
-- que se le ponga un techo. Fix: pergamino partido en 3 pedazos, mismo
-- patron "9-slice" que ya se uso para armar el launcher (extremos fijos +
-- tramo del medio que se estira), pero armado EN VIVO con Lua en vez de
-- pre-compuesto con Pillow porque esta ventana si necesita adaptarse en
-- tiempo real:
--   * tracker_parchment_top.tga (300x130) -- borde de madera + cartel +
--     adornos de esquina de ARRIBA. Tamaño fijo, nunca se estira.
--   * tracker_parchment_bottom.tga (300x88) -- adornos de esquina +
--     borde de madera de ABAJO. Tamaño fijo, se reposiciona en
--     SizeChanged para quedar pegado siempre al borde inferior.
--   * tracker_parchment_mid.tga (300x113) -- tira de papel liso sin
--     adornos (recortada de una zona plana confirmada por pixel, sin
--     ningun borde ondulado de la hoja) -- esta SI se redimensiona en
--     SizeChanged para llenar el hueco entre los otros 2. Se probo con un
--     tile mas chico (40px) primero: al repetirse mostraba un patron de
--     "ola" visible en el borde ondulado de la hoja -- 113px (una porcion
--     bastante mas grande, casi sin ondulacion propia) casi no necesita
--     repetirse en el rango normal de uso y la costura es practicamente
--     invisible.
-- Sin SetMaximumSize -- ya no hace falta, la ventana se puede agrandar o
-- achicar libremente y el pergamino se adapta solo.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"
-- (2026-10-01) efectos de fuego del pergamino (ver ese archivo)
import "LOTRO_Quest_Assistant.UI.TrackerFireFX"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}

LQA.UI.QuestTrackerHUD = class(Turbine.UI.Lotro.Window)

-- BUG CORREGIDO (2026-08-20, captura de pantalla del usuario: nombres de
-- mision largos, ej. "Libro 3. Capítulo 7: El Consejo Reunido", se veian
-- cortados/superpuestos con los botones "Ir"/"X" de la misma fila). 34px
-- alcanzaba para 2 lineas de nombre solo cuando NO habia progreso "(N/M)"
-- concatenado -- la misma clase de bug ya corregida en QuestSyncWindow.lua
-- (sesion 16/19/39: "la fila tiene que crecer con el texto, no al reves"),
-- pero esa correccion nunca se aplico a este HUD, que tiene su propia copia
-- de la logica de fila. Subido 34->48 (mismo criterio: 3 lineas visibles
-- antes de que el label empiece a recortar contra la fila de botones).
--
-- V3 -- pedido explicito del usuario ("adapta las letras, que sean mas
-- grande y legible... dejemos visualmente 3 misiones y que tengamos una
-- bajada con la rueda del raton"): 48->64 para acompañar la fuente mas
-- grande (BookAntiqua12->16, ver PopulateActive). Con filas mas altas
-- entran ~3 a la vista antes de necesitar scroll (la ListBox+ScrollBar de
-- mas abajo ya soportan rueda del mouse de forma nativa, sin codigo
-- extra).
local ROW_HEIGHT = 64

-- V12 (2026-09-03, pedido explicito del usuario tras probar preview.png en
-- el juego: "las letras sobresalen la imagen, incluso los botones de
-- narrar no se encuentran dentro del papel"). Medido con Pillow sobre
-- preview.png real (no adivinado): el pergamino CLARO (donde hay que
-- dibujar contenido) ocupa x=41..274 en las filas de arriba, pero se
-- ANGOSTA hacia abajo (arco de la hoja) -- a y=370 (ya cerca del ultimo
-- renglon visible en la captura) el pergamino real es solo x=69..241. El
-- layout viejo (heredado de la imagen anterior, mas ancha de pergamino)
-- arrancaba el contenido en x=10 (item de la lista, ver listContainer mas
-- abajo) -- 31px DENTRO del marco de madera para CUALQUIER fila, no solo
-- las de abajo. Se acota todo el contenido de fila (insignia/texto/
-- botones) a una franja seguro-adentro con margen real, ademas angosta
-- para no repetir el problema en las filas que caen en la zona angosta.
-- V18 (2026-09-05, pedido explicito del usuario: "el contenedor de la
-- ventana sigue teniendo el tamaño/margenes viejos... deja espacio
-- muerto"). El pergamino final (V17) ya usaba ~95% de su propio canvas
-- 300x416 (bbox real medido con Pillow: x=4..295, y=5..409) -- pero
-- PAGE_W/PAGE_H seguian midiendo el CANVAS COMPLETO (300x416), asi que
-- ese ~5% de margen transparente sobrante quedaba incluido en el tamaño
-- del contenedor/ventana, mostrandose como hueco real (el chrome nativo
-- de la ventana es opaco, no transparente, encima de esos pixeles
-- vacios). Fix: tracker_parchment_cropped.png = tracker_parchment_final_2
-- RECORTADO a su bbox real (292x405, cero margen transparente sobrante,
-- confirmado con Pillow tras el recorte). Todas las coordenadas de mas
-- abajo (SAFE_LEFT/RIGHT, GATHER_BTN_Y, PAGE_BOTTOM_H, anillo) se
-- restaron el mismo offset del recorte (dx=4, dy=5) para seguir cayendo
-- en el mismo lugar real. El angosto natural del CUERPO del pergamino
-- (mas angosto que las puntas del rodillo, x=45..241 de 292 en el cuerpo)
-- es la forma real del arte -- un pergamino enrollado nunca va a llenar
-- un rectangulo por completo ahi, no es un margen que se pueda recortar
-- sin cortar el dibujo.
local SCALE = 1.05
local SAFE_LEFT = math.floor(45 * SCALE)   -- x absoluta de ventana/imagen (item arranca en x=10, ver listContainer)
local SAFE_RIGHT = math.floor(241 * SCALE) -- peor caso real del borde rasgado, con margen

-- BUG CORREGIDO (screenshot del usuario, 2026-09-03: "perdida de texto de
-- los titulos... recortado" -- un nombre MUY largo, ej. "Libro 5, Capitulo
-- 1: Hacia las Montañas Nubladas" (49 caracteres), envuelve a 3 lineas a
-- este ancho/fuente, pero ROW_HEIGHT=64 solo tenia margen calculado para 2
-- (ver V10 mas abajo) -- la 3ra linea quedaba tapada por el boton Narrar de
-- esa misma fila. Fila mas alta SOLO para este caso puntual (ver PopulateActive).
local ROW_HEIGHT_TALL = 88

-- Tamaño real de tracker_parchment.tga -- 315x437 = 300x416 nativo x SCALE
-- (ver nota grande de SAFE_LEFT/SAFE_RIGHT arriba), tal cual salio de
-- Pillow (round, no floor -- por eso 437 y no 436). Ya no hay piezas
-- separadas ni SizeChanged: el tamaño de la ventana quedo fijo, esto es
-- solo para el layout inicial.
-- V18: 307x425 = tracker_parchment_cropped.png (292x405 nativo, ver nota
-- grande de SAFE_LEFT/SAFE_RIGHT) x SCALE, tal cual salio de Pillow.
local PAGE_H = 425
local PAGE_W = 307
-- Grosor del marco de madera de ABAJO dentro de esa misma imagen unica
-- (ya no es un archivo aparte, pero la lista sigue necesitando dejarle
-- espacio para no taparlo).
--
-- V18: el papel plano (zona de lista real) llegaba a y=320 en la imagen
-- SIN recortar -- en la recortada (offset dy=5) eso es y=315. Con el
-- nuevo alto nativo (405): 405-315=90, x SCALE.
local PAGE_BOTTOM_H = math.floor(90 * SCALE)

-- BUG CORREGIDO (2026-09-03, mismo dia: "el traker sigue teniendo error
-- visual" incluso despues de volver a la imagen unica) -- el offset de
-- "aire arriba para el chrome nativo" que este archivo venia usando desde
-- la V2/V3 original era 30, heredado sin cuestionar. Comparado contra las
-- OTRAS 2 ventanas de este addon que SI usan Turbine.UI.Lotro.Window con
-- fondo de imagen unica y no tienen bugs reportados de recorte
-- (QuestBookWindow.lua's CHROME_TOP=40, GatherWindow.lua's
-- CONTENT_TOP=40) -- las dos coinciden en 40, no 30. Con 30 le faltaban
-- 10px reales de chrome nativo, asi que el borde inferior del pergamino
-- quedaba recortado contra el borde real de la ventana (se veia el fondo
-- nativo oscuro/transparente ahi) -- la MISMA clase de "corte" que el
-- propio historial de este archivo ya habia sospechado (V9/BUG#10: "si el
-- chrome nativo... reserva algo de alto que este calculo no
-- contemplaba") pero nunca habia llegado a medir contra un valor
-- confirmado en otra ventana. La imagen (tracker_parchment.tga, 300x416)
-- esta bien tal cual esta -- no hacia falta cambiarle el tamaño, hacia
-- falta corregir CUANTO aire se le deja arriba.
local CHROME_TOP = 40

-- V8 -- pedido explicito del usuario ("el boton de recoleccion puede
-- estar mas arriba, hay mucho espacio perdido"): el adorno de esquina de
-- pageTop (dentro de sus 130px) SOLO ocupa el lado DERECHO hasta el
-- fondo -- el lado IZQUIERDO (x=10, donde vive este boton) ya esta libre
-- de decoracion mucho antes, cerca de y=80 relativo a pageTop. Antes se
-- posicionaba a 30+130+8=168 (asumiendo que hacia falta esperar a que
-- terminara TODO pageTop) dejando ~50px de pergamino en blanco sin usar
-- arriba del boton.
-- V17: rodillo termina en y=45 nativo, papel limpio desde y=50-55 -- 75
-- nativo (10px de aire real debajo del rodillo).
-- V18: mismo punto real, offset por el recorte (dy=5): 75-5=70 nativo.
local GATHER_BTN_Y = CHROME_TOP + math.floor(70 * SCALE)

-- Interruptor de idioma (LanguageSettings.lua): mismo patron que
-- QuestSyncWindow.lua, version reducida ya que este HUD solo tiene 3
-- strings fijas.
-- V4 -- pedido explicito del usuario ("la letra de 'misiones activas en
-- el mapa' es demasiado chica para el cuadro... que sea 'Misiones
-- activas' mas grande que ocupe todo el cuadrado"): texto acortado (el
-- cartel del pergamino es angosto, 215px) para poder subir la fuente sin
-- que quede apretado.
local HUD_STRINGS = {
    ES = { header = "Misiones activas", empty = "No hay misiones activas", go = "Ir" },
    EN = { header = "Active quests", empty = "No active quests", go = "Go" },
}
local function HT(key)
    local lang = LanguageSettings.IsSpanish() and "ES" or "EN"
    return HUD_STRINGS[lang][key] or key
end
-- (2026-09-27) Zona real de la mision para el filtro por zona del Tracker.
local function HudQuestZone(ndx, quest)
    if QuestLocResolver and QuestLocResolver.QuestZone then
        return QuestLocResolver.QuestZone(ndx)
    end
    if quest and quest.zone and quest.zone ~= "" then return quest.zone end
    return nil
end

-- (2026-10-01) Zona con la que arranca el Tracker al entrar o relogear.
-- Antes arrancaba SIN zona (currentZone = nil = sin filtro) y mostraba TODAS
-- las misiones activas guardadas de todas las zonas, incluidas las muy
-- viejas; recien al aceptar/completar/avanzar una mision se ponia la zona
-- y la lista se "arreglaba". Ahora: la zona que tenia el Tracker al salir
-- (QuestStateManager.State.zone, se guarda), y si no hay, la zona de la
-- mision activa que se movio por ultima vez (lastUpdate es la hora del
-- juego, sigue corriendo entre sesiones).
local function StartZone()
    local S = QuestStateManager and QuestStateManager.State
    if not S then return nil end
    if type(S.zone) == "string" and S.zone ~= "" then return S.zone end
    local best, bestT = nil, nil
    for ndx, data in pairs(S.active or {}) do
        if type(data) == "table" and not data.hidden then
            local quest = QuestDB.quests[ndx]
            local t = tonumber(data.lastUpdate)
            if quest and t and (bestT == nil or t > bestT) then
                local z = HudQuestZone(ndx, quest)
                if z then best, bestT = z, t end
            end
        end
    end
    return best
end

local function HudQuestName(ndx, quest)
    if LanguageSettings.IsSpanish() then
        return QuestLocResolver.GetQuestNameES(ndx, quest.nameEN)
    end
    return quest.nameEN
end

-- V6 -- pedido explicito del usuario ("las misiones deeds son del mismo
-- color... colores distintos a las que son en grupo, deeds, mision
-- principal, repetibles"): QuestDB.quests[ndx].category es un string real
-- (ej. "Epic - Vol. II, Book 1: The Walls of Moria", "Mûr Ghala
-- Instances", "Raid: The Abyss of Mordath", "Skirmish Assaults") --
-- "Epic" aparece en 999 misiones (historia principal/vol.), "Instance"/
-- "Raid"/"Skirmish" en 135 (contenido de grupo). .repeatable es un
-- booleano real, 4231 misiones lo tienen en true. Ningun campo de
-- "grupo" generico existe aparte de esto -- se usa el category como
-- proxy, es lo unico con dato real disponible (no se inventa nada).
--
-- 2026-09-22 (pedido explicito del usuario: TODAS las misiones de grupo --
-- mazmorras, raids, instancias de grupo -- con un color especifico + logo
-- de grupo): ahora SI existe un dato real de grupo -- Data/GroupQuestDB.lua
-- (tamaño oficial del juego, 1.448 misiones, ver Core/GroupQuest.lua) --
-- que se consulta PRIMERO, antes que "epic": un capitulo epico que es de
-- comunidad/incursion tambien es contenido de grupo y el jugador necesita
-- saberlo. El proxy viejo por category se deja abajo como respaldo por si
-- GroupQuestDB no cargara (nunca rompe nada si falta).
local function ClassifyQuest(quest)
    if _G.GroupQuest and GroupQuest.IsGroup(quest) then
        return "group"
    end
    local cat = quest.category or ""
    if string.find(cat, "Epic", 1, true) then
        return "epic"
    end
    if string.find(cat, "Instance", 1, true) or string.find(cat, "Raid", 1, true) or string.find(cat, "Skirmish", 1, true) then
        return "group"
    end
    if quest.repeatable == true then
        return "repeatable"
    end
    return "normal"
end

local QUEST_TYPE_COLOR -- se arma mas abajo (necesita MEMBookStyle.Color.BodyText ya cargado)
local function InitQuestTypeColors()
    if QUEST_TYPE_COLOR then return end
    QUEST_TYPE_COLOR = {
        epic = Turbine.UI.Color(0.55, 0.12, 0.10),       -- rojo oscuro: mision principal/epica
        -- naranja fuego: grupo (mazmorra, incursion, instancia, escaramuza)
        -- -- mismo color en todo el addon, definido una sola vez en
        -- Core/GroupQuest.lua (antes naranja/oxido 0.62,0.36,0.05 a mano).
        group = (_G.GroupQuest and GroupQuest.Color.Dark) or Turbine.UI.Color(0.62, 0.36, 0.05),
        repeatable = Turbine.UI.Color(0.10, 0.42, 0.32), -- verde azulado: repetible
        normal = LQA.UI.MEMBookStyle.Color.BodyText,     -- gris-cafe de siempre: mision normal, sin cambios
    }
end

function LQA.UI.QuestTrackerHUD:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    -- 320 = PAGE_W(300) + 20 de margen contra el borde de pantalla -- con
    -- PAGE_W ahora en 450 (ver nota grande de SAFE_LEFT/SAFE_RIGHT), esto
    -- se queda igual (PAGE_W+20) o la ventana quedaria de mas a la derecha
    -- fuera de pantalla.
    --
    -- Y subido de 200 a 110 (2026-09-05, pedido explicito del usuario:
    -- "hay espacio y ruido visual arriba, se puede aprovechar mas el
    -- area"). Verificado con captura real (ScreenShot_2026-09-05_045425):
    -- con Y=200 quedaban ~110px de mundo 3D vacio entre el HUD superior
    -- del juego (icono de dificultad/contadores, que termina ~y=58 en
    -- pantalla) y el titulo de esta ventana -- puro espacio perdido. 110
    -- deja un colchon real debajo de ese HUD (no pegado) sin invadirlo.
    self:SetPosition(Turbine.UI.Display.GetWidth() - (PAGE_W + 20), 110)
    -- REVERTIDO A ESTRUCTURA ORIGINAL (pedido explicito del usuario,
    -- 2026-09-03: "vuelve a la estructura original y retoca la version
    -- pasada"). El sistema de pergamino en 3 piezas (V3-V10, historial
    -- grande abajo) siguio generando bugs de costura/transparencia sesion
    -- tras sesion, y el ultimo recorte de tracker_parchment_top/mid/
    -- bottom.tga (intentando arreglar el bug #10) quedo realmente
    -- CORRUPTO: comparado a mano contra tracker_parchment.tga (la imagen
    -- unica original, intacta, sin tocar desde su creacion el 2026-08-28),
    -- la pieza _bottom.tga tenia tajos blancos irregulares cruzando el
    -- marco de madera que NO existen en el original -- eso es exactamente
    -- lo que se vio en el juego (fondo con "error", cortes visibles, marco
    -- con partes transparentes). Se vuelve a la unica imagen original tal
    -- cual estaba en la V2, en vez de seguir parchando el sistema de 3
    -- piezas.
    --
    -- Con una sola imagen (no separable en piezas fijas+elastica sin
    -- volver a romperla) la ventana deja de ser libremente
    -- redimensionable -- se fija al tamaño nativo real del arte (300x416)
    -- + CHROME_TOP (40px, ver nota grande de esa constante mas arriba) de
    -- aire arriba para el chrome nativo + el cartel. Es un paso atras
    -- deliberado en adaptabilidad a cambio de no volver a mostrar el
    -- pergamino roto/costurado/recortado -- pedido explicito del usuario.
    self:SetSize(PAGE_W, CHROME_TOP + PAGE_H)
    -- BUG CORREGIDO (visto en captura con zoom del usuario: el titulo
    -- nativo se cortaba, "QuestSync Tracke" sin la "r" final) -- el chrome
    -- nativo de Lotro.Window trunca el titulo si no entra en el ancho de
    -- la ventana (300px); "QuestSync Tracker" (18 caracteres) no entraba,
    -- "Tracker" si.
    self:SetText("Tracker")
    self:SetOpacity(0.9)
    self:SetVisible(true)
    -- Ya NO redimensionable (ver nota grande arriba) -- la imagen unica no
    -- se puede partir en piezas fijas+elastica sin repetir el bug que se
    -- esta revirtiendo.
    self:SetResizable(false)

    -- SFX de "abrir ventana" RETIRADO (pedido explicito del usuario,
    -- 2026-09-03) -- ver la nota grande en NarratorBridge.lua.

    -- currentZone: cambiamos de area a zone para el HUD. A diferencia de la
    -- ventana principal (que lista TODAS las misiones del juego y necesita
    -- separarlas por area para no abrumar con 1000 misiones de Bree), el
    -- Tracker solo muestra las ACTIVAS. Filtrar por 'area' ocultaba misiones
    -- vecinas (ej. Greenway vs Trestlebridge) provocando que la ventana
    -- saltara entre ellas. Filtrar por 'zone' las mantiene todas juntas.
    self.currentZone = nil

    -- Pergamino: UNA sola imagen (estructura original V2, restaurada -- ver
    -- nota grande en el Constructor sobre por que se abandonan las 3
    -- piezas). Hijo de la ventana, nunca la ventana en si (mismo criterio
    -- que QuestBookWindow.lua).
    --
    -- V11 (2026-09-03, pedido explicito del usuario: reemplazar la imagen
    -- por otra nueva porque "el traker sigue teniendo error visual").
    -- Confirmado el bug real analizando el canal alpha con Pillow: la
    -- tracker_parchment.tga vieja (intacta desde el 2026-08-28) tenia el
    -- BORDE IZQUIERDO irregular/dentado (mascara alpha con muescas, no un
    -- rectangulo redondeado limpio como los otros 3 lados) -- eso es lo que
    -- se veia como "corte"/mundo 3D asomando en filas contra el borde. La
    -- imagen nueva (preview.png, provista por el usuario en Documentos/The
    -- Lord of the Rings Online/, mismas 300x416px) tiene mascara alpha de
    -- rectangulo redondeado limpio en los 4 lados, sin muescas. Vieja
    -- respaldada como tracker_parchment.tga.bak_pre_preview (dev y
    -- deploy). Cartel y esquinas de la nueva imagen miden en pixeles muy
    -- cerca de la vieja (banda oscura del cartel y=26-67 vs y=26-73
    -- original) -- CHROME_TOP/PAGE_BOTTOM_H/posicion de lblHeader se
    -- dejaron sin cambios; revisar en el juego por si hace falta un
    -- retoque fino.
    local BOOK_RES = LQA.UI.MEMBookStyle.RES_BASE
    self.pageBg = Turbine.UI.Control()
    self.pageBg:SetParent(self)
    self.pageBg:SetPosition(0, CHROME_TOP)
    self.pageBg:SetSize(PAGE_W, PAGE_H)
    self.pageBg:SetBackground(BOOK_RES .. "tracker_parchment.tga")
    self.pageBg:SetMouseVisible(false)

    -- lblHeader OCULTO (2026-09-05, pedido explicito del usuario de
    -- reemplazar la imagen por tracker_parchment_v2): el pergamino nuevo
    -- ya trae "Misiones Activas" grabado en el cartel del rollo de arriba
    -- -- mismo patron que "¡Nueva misión!" quemado en questbook.tga
    -- (QuestBookWindow.lua) -- dibujarlo tambien por codigo se veria
    -- duplicado/pisado. Se mantiene el objeto (RefreshLanguage/
    -- LANGUAGE_CHANGED mas abajo le siguen llamando SetText sin problema,
    -- solo que invisible) en vez de borrar todas sus referencias.
    self.lblHeader = Turbine.UI.Label()
    self.lblHeader:SetParent(self)
    self.lblHeader:SetPosition(51, CHROME_TOP + 30)
    self.lblHeader:SetSize(215, 44)
    self.lblHeader:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold24)
    self.lblHeader:SetMultiline(true)
    self.lblHeader:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.lblHeader:SetForeColor(Turbine.UI.Color.Yellow)
    self.lblHeader:SetText(HT("header"))
    self.lblHeader:SetVisible(false)

    -- Anillo con brillo al pasar el mouse por CUALQUIER parte de la
    -- ventana. Offset real (142,315) tamaño (151,94) sobre la imagen SIN
    -- recortar -- V18 le resta el offset del recorte (dx=4,dy=5, ver nota
    -- grande de SAFE_LEFT/SAFE_RIGHT): (138,310). tracker_ring_hover.tga
    -- se regenero derivado de tracker_parchment_cropped.png (mascara por
    -- textura, brillo solo sobre la silueta real del anillo -- sin
    -- costura, mismo metodo que QuestSyncWindow.lua/QuestBookWindow.lua).
    -- Posicion/tamaño x SCALE: (138,310)x1.05, tamaño (151,94)x1.05.
    self.ringGlow = Turbine.UI.Control()
    self.ringGlow:SetParent(self.pageBg)
    self.ringGlow:SetPosition(145, 326)
    self.ringGlow:SetSize(159, 99)
    self.ringGlow:SetBackground(BOOK_RES .. "tracker_ring_hover.tga")
    self.ringGlow:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.ringGlow:SetMouseVisible(false)
    self.ringGlow:SetVisible(false)

    -- Poll de posicion real del mouse (Update), NO MouseEnter/Leave de la
    -- ventana -- misma razon que las otras 2 ventanas: listBox/botones de
    -- adentro tienen su propio SetMouseVisible(true) y cortarian el
    -- Enter/Leave del padre.
    self.ringHoverPoll = Turbine.UI.Control()
    self.ringHoverPoll:SetParent(self.pageBg)
    self.ringHoverPoll:SetVisible(false)
    self.ringHoverPoll:SetWantsUpdates(true)
    self.ringHovering = false
    self.ringHoverPoll.Update = function()
        local mx, my = self:GetMousePosition()
        local over = mx >= 0 and mx < PAGE_W and my >= CHROME_TOP and my < (CHROME_TOP + PAGE_H)
        if over ~= self.ringHovering then
            self.ringHovering = over
            self.ringGlow:SetVisible(over)
        end
    end

    -- Boton a GatherWindow.lua (pedido explicito del usuario) -- ver
    -- GATHER_BTN_Y arriba (subido, ya no espera a que termine TODO
    -- pageTop -- el lado izquierdo, donde vive este boton, esta libre de
    -- decoracion mucho antes que el lado derecho).
    --
    -- V17 (2026-09-04, pedido explicito del usuario: "cambiar el boton que
    -- dice recoleccion por el boton que tenemos en la carpeta"): boton de
    -- texto nativo "Recolección" -> icono "activar_icon" (la hoja verde
    -- del set nuevo, elegida por el usuario -- tematicamente calza mejor
    -- con recoleccion que cualquiera de los otros 5). Sin Quickslot detras
    -- -- seguro cambiar el TIPO de control aca (a diferencia de Mapa/Ruta,
    -- que el usuario pidio explicitamente dejar nativos).
    -- V19 (2026-09-05, pedido explicito del usuario: "esta sobre la imagen
    -- y lo ideal es que quede dentro como el boton de audio on u off"):
    -- x=10 era literalmente el borde izquierdo de la ventana/pergamino
    -- (fuera del area seguro real, ver SAFE_LEFT arriba) -- se veia
    -- montado sobre el marco de madera en vez de "dentro" de la hoja, a
    -- diferencia de btnAudioToggle (mas abajo), que ya usa SAFE_RIGHT como
    -- margen real. SAFE_LEFT lo deja espejado con ese mismo criterio.
    self.btnGather = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("activar_icon", 32, 32)
    self.btnGather:SetParent(self)
    self.btnGather:SetPosition(SAFE_LEFT, GATHER_BTN_Y)
    self.btnGather.MouseClick = function()
        if _G.GatherWindow then
            _G.GatherWindow:SetVisible(not _G.GatherWindow:IsVisible())
        end
    end

    -- Boton de silenciar/activar el Narrador_IA (pedido explicito del
    -- usuario, 2026-09-05: "un boton... si esta en verde esta on y si le
    -- doy click el boton quede cambiado a off"). Espejado con btnGather en
    -- el lado derecho de la misma fila superior -- misma Y, mismo tamaño
    -- 32x32, mismo margen relativo al borde seguro del pergamino
    -- (SAFE_LEFT/SAFE_RIGHT, ver la nota grande de esas constantes).
    -- El icono en si (verde=on / gris con X=off) es la unica señal visual
    -- de estado, no hay texto: mismo criterio que el resto de los botones
    -- de icono de esta ventana (activar/desmarcar/narrar).
    local function AudioIconName()
        return NarratorMute.IsMuted() and "audio_off" or "audio_on"
    end
    self.btnAudioToggle = LQA.UI.MEMBookStyle.CreateIconButtonAlpha(AudioIconName(), 32, 32)
    self.btnAudioToggle:SetParent(self)
    self.btnAudioToggle:SetPosition(SAFE_RIGHT - 32, GATHER_BTN_Y)
    -- Solo escribe la preferencia (Core/NarratorMute.lua) -- Narrador_IA (app
    -- externa, unica pieza que de verdad reproduce audio) es quien deja de
    -- narrar al verla en off; ver la nota grande de ese archivo.
    self.btnAudioToggle.ButtonClicked = function()
        NarratorMute.Toggle()
    end
    -- RefreshAudioIcon reasigna los 3 estados (normal/over/down) del boton ya
    -- creado -- mismos 3 campos que arma CreateIconButtonAlpha, no hay una
    -- API para "recrear" un boton ya parentado sin perder su posicion/
    -- eventos. Se llama al toggle propio Y al restaurar la preferencia
    -- guardada (NarratorMute.lua carga async, puede llegar despues de que
    -- este boton ya se dibujo en su valor por defecto "on").
    local function RefreshAudioIcon()
        local tex = AudioIconName()
        self.btnAudioToggle.normalIcon = LQA.UI.MEMBookStyle.RES_BASE .. tex .. ".tga"
        self.btnAudioToggle.overIcon = LQA.UI.MEMBookStyle.RES_BASE .. tex .. "_over.tga"
        self.btnAudioToggle.clickIcon = LQA.UI.MEMBookStyle.RES_BASE .. tex .. "_down.tga"
        self.btnAudioToggle:SetBackground(
            self.btnAudioToggle.mouseOver and self.btnAudioToggle.overIcon or self.btnAudioToggle.normalIcon
        )
    end
    LQA.Core.EventBus:Subscribe("NARRATOR_MUTE_CHANGED", RefreshAudioIcon)

    -- V17: 22 (alto viejo de btnGather, boton de texto nativo) -> 32 (alto
    -- real del icono nuevo, ver btnGather mas arriba) para no superponerse.
    -- V14: x=10->15 (SCALE), Y sin escalar -- GATHER_BTN_Y ya escalado, el
    -- +32+10 es alto de icono (sin escalar, ver nota grande arriba) + un
    -- margen chico fijo.
    self.listContainer = Turbine.UI.Control()
    self.listContainer:SetParent(self)
    -- x=10 (no 15): SAFE_LEFT-10 mas abajo (badge/lbl dentro de cada fila)
    -- asume que listContainer arranca en 10 -- ver nota grande de
    -- SAFE_LEFT/SAFE_RIGHT arriba.
    self.listContainer:SetPosition(10, GATHER_BTN_Y + 32 + 10)

    -- V14: 265/270/10 -> x1.5, mismo criterio que el resto del layout.
    self.listBox = Turbine.UI.ListBox()
    self.listBox:SetParent(self.listContainer)
    self.listBox:SetPosition(0, 0)
    -- Ancho = SAFE_RIGHT - 10 (listContainer arranca en x=10 -- ver nota
    -- grande de SAFE_LEFT/SAFE_RIGHT): la fila llega justo hasta el margen
    -- real medido contra el borde rasgado, ni un pixel de mas.
    self.listBox:SetWidth(SAFE_RIGHT - 10)

    self.scrollBar = Turbine.UI.Lotro.ScrollBar()
    self.scrollBar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.scrollBar:SetParent(self.listContainer)
    self.scrollBar:SetPosition(SAFE_RIGHT - 10 + 5, 0)
    self.scrollBar:SetWidth(10)
    self.listBox:SetVerticalScrollBar(self.scrollBar)

    -- Alto de la lista: YA NO se recalcula en cada resize (la ventana no
    -- se redimensiona mas, ver nota grande del Constructor) -- se calcula
    -- UNA sola vez con el tamaño fijo real.
    -- V6 (pedido explicito del usuario: "se mira que esta cortado la
    -- imagen y pegada"): listH sale de un resto (altura disponible -
    -- margenes) que casi nunca es multiplo exacto de ROW_HEIGHT -- si no
    -- se redondea, la ListBox muestra la ULTIMA fila MEDIO cortada justo
    -- pegada al borde inferior del pergamino (choca contra el adorno de
    -- madera, se ve "cortado y pegado"). Redondeando para abajo al
    -- multiplo de ROW_HEIGHT mas cercano, la lista SIEMPRE termina en una
    -- fila completa -- el resto (menos de 1 fila) queda como margen de
    -- pergamino en blanco antes del adorno, no como texto a medias.
    --
    -- V12: redondeo cambiado de multiplo de ROW_HEIGHT (64, salto grande)
    -- a multiplo de 8 (bug reportado: "sobra espacio abajo" -- con filas
    -- mezcladas altas/normales (ROW_HEIGHT_TALL=88 vs ROW_HEIGHT=64) el
    -- viejo redondeo a 64 tiraba a la basura hasta 63px reales de
    -- pergamino ya angostado con PAGE_BOTTOM_H mas arriba. 8px de holgura
    -- maxima es imperceptible y ya no reserva de mas.
    local LIST_H_GRANULARITY = 8
    local bottomY = CHROME_TOP + PAGE_H - PAGE_BOTTOM_H
    local listH = bottomY - 10 - self.listContainer:GetTop()
    if listH < ROW_HEIGHT then listH = ROW_HEIGHT end
    listH = math.floor(listH / LIST_H_GRANULARITY) * LIST_H_GRANULARITY
    self.listContainer:SetSize(SAFE_RIGHT - 10 + 20, listH)
    self.listBox:SetHeight(listH)
    self.scrollBar:SetHeight(listH)

    local function OnQuestEvent(data)
        if data and data.ndx and QuestDB.quests[data.ndx] then
            -- (2026-09-27) zona REAL (ver QuestLocResolver.QuestZone): con
            -- la de la base, avanzar una mision mal catalogada escondia
            -- todas las de la zona donde el jugador estaba.
            local z = HudQuestZone(data.ndx, QuestDB.quests[data.ndx])
            if z then
                self.currentZone = z
                -- (2026-10-01) se guarda para arrancar en esta zona al
                -- relogear (ver StartZone); solo cuando cambia
                if QuestStateManager.State.zone ~= z then
                    QuestStateManager.State.zone = z
                    QuestStateManager.Save()
                end
            end
        elseif self.currentZone == nil then
            -- aviso sin mision: se acaba de cargar lo guardado
            self.currentZone = StartZone()
        end
        self:PopulateActive()
    end
    LQA.Core.EventBus:Subscribe("QUEST_STATE_CHANGED", OnQuestEvent)
    LQA.Core.EventBus:Subscribe("QUEST_PROGRESS", OnQuestEvent)
    -- BUG CORREGIDO (pedido explicito del usuario: "al hacer click en la
    -- mision dentro de este tracker desaparece el resto de las misiones
    -- trackeadas"): QUEST_TRACKED se publica desde
    -- QuestStateManager.SetTrackedQuest(ndx), que a su vez se dispara con
    -- CADA click en una fila de este mismo Tracker (via FocusQuest ->
    -- SelectQuest -> SetTrackedQuest en QuestSyncWindow.lua) -- NO es una
    -- señal real de "el jugador esta ahora en la zona de esta mision", es
    -- solo "el jugador clickeo para VER esta mision en la UI". Estar
    -- suscripto a ese evento hacia que self.currentZone se pisara con la
    -- zona de CUALQUIER mision que se clickeara aca mismo, angostando el
    -- filtro de zona del Tracker a esa sola mision y escondiendo al resto.
    -- QUEST_STATE_CHANGED/QUEST_PROGRESS si reflejan progreso real del
    -- jugador (aceptar/completar/avanzar objetivos), esos se dejan.
    LQA.Core.EventBus:Subscribe("LANGUAGE_CHANGED", function()
        self.lblHeader:SetText(HT("header"))
        self:PopulateActive()
    end)

    -- Sinergia con DeedTracker: _G.LQA_InProgressDeeds lo actualiza el OTRO
    -- addon, no publica ningun evento propio en nuestro EventBus -- sin esto
    -- el HUD solo se enteraria de una proeza nueva la proxima vez que una
    -- MISION propia cambiara de estado. Chequeo liviano cada 2s (compara
    -- cuantas entradas tiene la tabla, no repuebla la lista entera salvo que
    -- el numero haya cambiado).
    self.lastDeedCount = 0
    self.deedWatcher = Turbine.UI.Control()
    self.deedWatcher.nextCheck = Turbine.Engine.GetGameTime() + 2
    self.deedWatcher.Update = function()
        if Turbine.Engine.GetGameTime() >= self.deedWatcher.nextCheck then
            self.deedWatcher.nextCheck = Turbine.Engine.GetGameTime() + 2
            local n = 0
            if _G.LQA_InProgressDeeds then
                for _ in pairs(_G.LQA_InProgressDeeds) do n = n + 1 end
            end
            if n ~= self.lastDeedCount then
                self.lastDeedCount = n
                self:PopulateActive()
            end
        end
    end
    self.deedWatcher:SetWantsUpdates(true)

    -- (2026-10-01) efectos de fuego: anillo, titulo y bordes (solo imagen,
    -- dentro del pergamino y debajo de la lista; ver UI/TrackerFireFX.lua)
    if LQA.UI.TrackerFireFX ~= nil and LQA.UI.TrackerFireFX.Attach ~= nil then
        pcall(LQA.UI.TrackerFireFX.Attach, self, self.pageBg)
    end

    -- (2026-10-01) si lo guardado ya se cargo antes de crear el Tracker
    self.currentZone = StartZone()
    self:PopulateActive()
end

function LQA.UI.QuestTrackerHUD:PopulateActive()
    InitQuestTypeColors()
    self.listBox:ClearItems()

    local cZone = self.currentZone and string.lower(self.currentZone) or nil

    local count = 0
    for ndx, data in pairs(QuestStateManager.State.active) do
        if not data.hidden then
            local quest = QuestDB.quests[ndx]
            if quest then
                -- (2026-09-27) una mision de zona desconocida se muestra
                -- siempre (antes quedaban ocultas 1.343 misiones sin zona).
                local qz = HudQuestZone(ndx, quest)
                local qZone = qz and string.lower(qz) or nil
                if not cZone or not qZone or qZone == cZone then
                    count = count + 1

                    local esName = HudQuestName(ndx, quest)

                    -- V2 (pedido explicito del usuario: "mejora la letra,
                    -- tamaño y colores adaptandolos a la nueva imagen") --
                    -- el LightBlue (elegido para contrastar contra el panel
                    -- OSCURO de antes) se lee mal sobre el pergamino CLARO
                    -- nuevo. La insignia (badge, un punto chico) se deja
                    -- igual -- un acento de color se distingue bien sobre
                    -- cualquier fondo -- pero el TEXTO pasa a
                    -- MEMBookStyle.Color.BodyText (80,80,80, el mismo tono
                    -- ya usado en el resto del addon para texto genuinamente
                    -- sobre pergamino).
                    -- V3 (pedido explicito del usuario: "que sean mas
                    -- grande y legible... 3 misiones visibles con scroll"):
                    -- BookAntiqua12 -> BookAntiqua16 (el ROW_HEIGHT ya subio
                    -- de 48 a 64 mas arriba para acompañar, asi que subir la
                    -- fuente aca ya NO reabre el bug viejo de superposicion
                    -- con los botones Ir/X).
                    -- V4 (pedido explicito del usuario: "es mucho el
                    -- espacio entre separacion por mision") -- la insignia
                    -- y los botones estaban CENTRADOS en toda la fila de
                    -- 64px (pensada para 3 lineas de texto largo), pero la
                    -- mayoria de los nombres de mision son 1 sola linea --
                    -- eso dejaba un hueco vacio grande antes de que
                    -- empezara la fila siguiente. Se pegan arriba, junto al
                    -- texto (que ya arranca en y=0), en vez de centrarse en
                    -- toda la altura -- ROW_HEIGHT se queda en 64 igual
                    -- (sigue haciendo falta para nombres largos de 3
                    -- lineas), pero ahora el espacio libre queda SIEMPRE al
                    -- final de la fila (antes de la siguiente), no
                    -- repartido raro en el medio.
                    -- V6 (pedido explicito del usuario: "colores distintos
                    -- para las que son en grupo, deeds, mision principal,
                    -- repetibles" + "el grosor de la letra, se ve muy
                    -- fina"): la insignia y el texto ahora toman el color
                    -- de ClassifyQuest(quest) (ver la funcion grande al
                    -- principio del archivo) en vez de un LightBlue/
                    -- BodyText fijo para TODAS las misiones por igual.
                    -- BookAntiqua16 (fino) -> BookAntiquaBold18 (negrita,
                    -- ademas un toque mas grande -- no existe una variante
                    -- "Bold16" real en MEMCommon/Fonts.lua, Bold18 es la
                    -- mas cercana disponible).
                    local qType = ClassifyQuest(quest)
                    local qColor = QUEST_TYPE_COLOR[qType]

                    local prog = data.progress
                    local displayText = (prog and prog ~= "") and (esName .. "  " .. prog) or esName

                    -- Fila mas alta SOLO para nombres que necesitan 3 lineas
                    -- (ver ROW_HEIGHT_TALL arriba) -- calculado ANTES de
                    -- crear item/lbl para poder dimensionarlos de una, no
                    -- despues.
                    -- V16 (2026-09-04, pedido explicito del usuario: sacar
                    -- el boton "Ir" de esta fila, dejar solo los otros 2
                    -- -- ver mas abajo, btnGo eliminado por completo). Con
                    -- ese espacio libre, lbl vuelve a ensancharse.
                    --
                    -- V17 (2026-09-04, pedido explicito del usuario: "el
                    -- boton X se pierde muy chico, puede ser un poco mas
                    -- grande" -- ver btnHide mas abajo, 24->32). Le saca
                    -- 10px a lbl (160->150) para dejarle sitio de sobra al
                    -- X mas grande sin superponerse. Umbrales de caracteres
                    -- reescalados junto con lbl (~7.4px por caracter a esta
                    -- fuente): 43/22 -> 40/20 -- casualmente los MISMOS
                    -- valores que ya usa QuestSyncWindow.lua a su ancho
                    -- original de 148px (150 es casi identico).
                    --
                    -- V16 (2026-09-05): lbl vuelve a ensancharse a 149 (ver
                    -- nota grande de SAFE_LEFT/SAFE_RIGHT -- tracker_
                    -- parchment_final deja MAS papel liso real que la
                    -- version v2 anterior, casi el mismo ancho que el
                    -- diseño original de 150). Umbral reescalado igual
                    -- (149/150 ~= 1): 40 de nuevo (era 26 con el ancho
                    -- angosto de V15).
                    local rowHeight = (#displayText > 40) and ROW_HEIGHT_TALL or ROW_HEIGHT

                    local item = Turbine.UI.Control()
                    -- Ancho = mismo que self.listBox de mas arriba
                    -- (SAFE_RIGHT-10, ver nota grande de SAFE_LEFT/
                    -- SAFE_RIGHT).
                    item:SetSize(SAFE_RIGHT - 10, rowHeight)

                    local badge = Turbine.UI.Control()
                    badge:SetParent(item)
                    if qType == "group" and _G.GroupQuest and GroupQuest.IsGroup(quest) then
                        -- 2026-09-22: logo de grupo en vez del punto de
                        -- color (pedido explicito del usuario). 16x16 =
                        -- tamaño REAL del .tga (SetBackground no reescala)
                        -- + AlphaBlend para el borde redondo. Centrado en
                        -- el mismo punto que el badge viejo (SAFE_LEFT-5,
                        -- y=11) y termina en SAFE_LEFT+3, antes de que
                        -- arranque el texto (SAFE_LEFT+6) -- no se pisan.
                        badge:SetPosition(SAFE_LEFT - 13, 3)
                        badge:SetSize(16, 16)
                        badge:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
                        badge:SetBackground(GroupQuest.ICON_16)
                    else
                        badge:SetPosition(SAFE_LEFT - 10, 6)
                        badge:SetSize(10, 10)
                        badge:SetBackColor(qColor)
                    end

                    local lbl = Turbine.UI.Label()
                    lbl:SetParent(item)
                    lbl:SetPosition(SAFE_LEFT - 10 + 16, 0)
                    -- 149 (no 96, ver nota grande de SAFE_LEFT/SAFE_RIGHT):
                    -- tracker_parchment_final deja mas papel liso real --
                    -- este ancho llega justo hasta el boton X (btnHide mas
                    -- abajo) sin superponerse.
                    lbl:SetSize(149, rowHeight)
                    lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
                    lbl:SetForeColor(qColor)
                    -- V7 (revertido en su momento) -- se habia probado
                    -- FontStyle.Outline y se saco porque a 18pt se veia
                    -- BORROSO contra el fondo VIEJO (un panel oscuro casi
                    -- plano, donde el color solo ya alcanzaba para leerse).
                    --
                    -- V15 (2026-09-05, vuelto a poner -- pedido explicito
                    -- del usuario: "el texto no se lee bien sobre el nuevo
                    -- fondo... el mapa de fondo tiene mucho detalle y el
                    -- texto se pierde"): el fondo nuevo es un mapa
                    -- ilustrado con muchisimo detalle propio -- ahi el
                    -- color solo YA NO alcanza (se demostro en el juego,
                    -- captura del usuario). El contorno negro separa el
                    -- texto de CUALQUIER textura de fondo en vez de
                    -- depender de que el fondo sea plano -- mismo mecanismo
                    -- ya usado con exito en QuestSyncWindow.lua/
                    -- QuestBookWindow.lua sobre fondos igual de texturados.
                    lbl:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
                    lbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
                    lbl:SetText(displayText)

                    -- V10 -- pedido del usuario: los botones "Ir"/"X"
                    -- quedaban pegados arriba (y=4, ver nota V4 abajo) sin
                    -- importar si el nombre de la mision ocupaba 1 o 2
                    -- lineas -- con nombres largos ("El desafio de
                    -- Crannog", "Depredadores en las estribaciones") el
                    -- texto se ve 2 lineas altas pero los botones quedan
                    -- "flotando" arriba, desalineados. No hay una API de
                    -- medicion de texto real disponible en este addon (se
                    -- reviso, no se usa en ningun lado) -- heuristica de
                    -- cantidad de caracteres: a BookAntiquaBold18 en 148px
                    -- de ancho, ~20 caracteres es el punto donde el texto
                    -- deja de entrar en 1 sola linea (confirmado contra la
                    -- captura del usuario: "Trofeos de guerra" 18 caract.
                    -- entraba en 1 linea, "El desafio de Crannog" 22
                    -- caracteres ya envolvia a 2). Si envuelve, se corren
                    -- los botones mas abajo para centrarse contra el
                    -- bloque de 2 lineas en vez de solo la primera.
                    -- V16 (2026-09-05): lbl vuelve a 149 (ver nota grande
                    -- de rowHeight mas arriba) -- umbrales vueltos a los
                    -- originales 40/20.
                    local buttonY = 4
                    if #displayText > 40 then
                        -- 3 lineas (ver rowHeight arriba) -- X baja mas
                        -- todavia para centrarse contra el bloque de 3
                        -- lineas en vez de solo las 2 primeras.
                        buttonY = 4 + 28
                    elseif #displayText > 20 then
                        buttonY = 4 + 14
                    end

                    -- FocusQuest (no SelectQuest): abre la ventana maestra
                    -- directo en la pestaña QuestSync mostrando SOLO esta
                    -- mision -- antes SelectQuest llenaba el panel de
                    -- detalle bien pero dejaba la lista de la izquierda con
                    -- TODAS las misiones del area, sin forma de distinguir
                    -- cual era la seleccionada (bug reportado por el
                    -- usuario). Ver QuestSyncWindow:FocusQuest.
                    -- Sin SFX de click (pedido explicito del usuario,
                    -- 2026-09-03: "solo deben ir los sonidos que yo entregue
                    -- como mp3" -- no hay mp3 real de click de fila).
                    item.MouseClick = function()
                        if _G.MainWindow then
                            _G.MainWindow:SetVisible(true)
                            _G.MainWindow:FocusQuest(ndx)
                        end
                    end
                    lbl.MouseClick = item.MouseClick
                    badge.MouseClick = item.MouseClick

                    -- Info al pasar el mouse (ver UI/QuestInfoTooltip.lua,
                    -- portado de CubePlugins/DeedTracker) -- pedido
                    -- explicito del usuario, tambien en el Tracker.
                    lbl.MouseHover = function()
                        QuestInfoTooltip.GetInstance():ShowFor(ndx, quest, esName)
                    end
                    lbl.MouseLeave = function()
                        QuestInfoTooltip.GetInstance():Hide()
                    end

                    -- V16 (2026-09-04, pedido explicito del usuario: "se
                    -- puede sacar los botones de Ir, y dejar los otros 2
                    -- que hay"). btnGo (Quickslot de MoorMap, saltaba
                    -- directo al punto) eliminado de esta fila -- sigue
                    -- existiendo el mismo salto vía FocusQuest al clickear
                    -- la fila/nombre (abre QuestSyncWindow con la mision
                    -- enfocada, que ahi si tiene sus botones Mapa/Ruta). Ya
                    -- no hace falta resolver `loc`/Quickslot aca.

                    -- V10 -- pedido del usuario ("estilo generico, no
                    -- combina con el pergamino"): este boton NO lleva
                    -- Quickslot -- solo oculta la mision (data.hidden), es
                    -- seguro cambiarlo de control.
                    --
                    -- V16: close_button.tga (icono redondo generico "libro"
                    -- MEM) -> "desmarcar_icon" del set nuevo (circulo rojo
                    -- con X, del mismo pack que Activar/Completar/
                    -- Desmarcar/Narrar) -- pedido explicito del usuario de
                    -- usar el set de botones que ya integramos tambien
                    -- aca. CreateIconButtonAlpha (no CreateIconButton): es
                    -- arte a todo color nuevo, no una mascara vieja -- ver
                    -- la nota grande de esa funcion en MEMBookStyle.lua
                    -- sobre por que hace falta AlphaBlend + tamaño EXACTO.
                    --
                    -- V17 (2026-09-04, pedido explicito del usuario: "se
                    -- pierde el diseño muy chico"): 24x24 -> 32x32 (el
                    -- archivo desmarcar_icon.tga se regenero a ese tamaño
                    -- real). lbl se angosto 10px (160->150, ver mas arriba)
                    -- para dejarle sitio de sobra al X mas grande.
                    local btnHide = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("desmarcar_icon", 32, 32)
                    btnHide:SetParent(item)
                    -- V15 (2026-09-05): margen recalculado sobre el
                    -- SAFE_RIGHT remedido (ver nota grande de SAFE_LEFT/
                    -- SAFE_RIGHT) -- 48 = 46 nativo x SCALE, mismo margen
                    -- relativo de siempre.
                    btnHide:SetPosition(SAFE_RIGHT - 48, buttonY - 4)
                    btnHide.ButtonClicked = function()
                        data.hidden = true
                        QuestStateManager.Save()
                        self:PopulateActive()
                    end

                    -- Boton "Narrar" (pedido explicito del usuario,
                    -- 2026-09-01): pide a Narrador_IA (app externa, ver
                    -- LOTRO_Chat_Narrator/Main.lua y Core/NarratorBridge.lua)
                    -- que lea en voz alta el nombre + objetivos de esta
                    -- mision. Se ancla en la esquina inferior izquierda de
                    -- la fila -- el espacio que la V4 de arriba dejo siempre
                    -- libre al final (nombres cortos no lo usan, nombres
                    -- largos de 2 lineas casi no lo tocan) -- para no
                    -- competir con el layout ya afinado de Ir/X arriba.
                    --
                    -- 2026-09-02 (pedido explicito del usuario: sinergia
                    -- visual con el tema de libro/pergamino): mismo estilo
                    -- "tag" cyan que en QuestSyncWindow.lua -- ver ese
                    -- archivo para el porque es seguro aca (sin Quickslot).
                    --
                    -- V13 (2026-09-04): tag_cyan+"Narrar" (rotulo ancho,
                    -- 65px) -> icono cuadrado "narrar_icon" del set nuevo
                    -- (arte a todo color, CreateIconButtonAlpha -- ver
                    -- MEMBookStyle.lua). Esta fila es la mas angosta de
                    -- las 3 donde vive el boton Narrar (QuestSyncWindow/
                    -- QuestBookWindow tienen mas lugar para el rotulo con
                    -- la palabra completa) -- aca el icono solo (globo de
                    -- dialogo) evita achicar/deformar un rotulo de texto a
                    -- un espacio que no le entra.
                    local btnNarrar = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("narrar_icon", 24, 24)
                    btnNarrar:SetParent(item)
                    btnNarrar:SetPosition(SAFE_LEFT - 10, rowHeight - 24)
                    btnNarrar.ButtonClicked = function()
                        NarratorBridge.PlayQuestText(ndx, quest, esName)
                    end

                    self.listBox:AddItem(item)
                end
            end
        end
    end

    -- Sinergia con CubePlugins/DeedTracker (mismo dueño/autor, pedido
    -- explicito del usuario): DeedTracker ya expone las proezas en curso en
    -- el global compartido _G.LQA_InProgressDeeds[deedID]=true (ver
    -- ChatLogger.lua) -- se muestran aca con una insignia de color distinta
    -- (violeta) para diferenciarlas de las misiones (azul/verde). Guardado
    -- defensivo con DataFiles and DataFiles._DEED_DATA: si DeedTracker no
    -- esta instalado/activo, este bloque simplemente no agrega nada.
    -- LIMITACION CONOCIDA: _G.LQA_InProgressDeeds nunca se limpia cuando una
    -- proeza se completa (grep confirmado, no hay ninguna asignacion a nil
    -- de esa clave en todo DeedTracker) -- una proeza que ya se completo puede seguir apareciendo
    -- aca como "en curso" hasta que se cierre sesion. No se intento resolver
    -- eso en esta pasada (requeriria exponer el estado real de completado de
    -- DeedTracker via otro global, que hoy no existe).
    if _G.LQA_InProgressDeeds and _G.DataFiles and _G.DataFiles._DEED_DATA then
        for deedID, _ in pairs(_G.LQA_InProgressDeeds) do
            local deed = _G.DataFiles._DEED_DATA[deedID]
            if deed and deed.NAME then
                count = count + 1

                local item = Turbine.UI.Control()
                item:SetSize(SAFE_RIGHT - 10, ROW_HEIGHT)

                -- V4: pegado arriba (y=6), mismo criterio que la fila de
                -- misiones (ver nota grande mas arriba).
                -- V6: badge e texto ahora usan el MISMO violeta oscuro
                -- (antes el badge era un lila claro (0.7,0.45,0.9) que no
                -- coincidia con el texto oscuro -- se ven como si fueran
                -- 2 colores de "deed" distintos). BookAntiqua16 ->
                -- BookAntiquaBold18, mismo criterio de negrita/tamaño que
                -- la fila de misiones.
                local deedColor = Turbine.UI.Color(0.35, 0.20, 0.45)
                local badge = Turbine.UI.Control()
                badge:SetParent(item)
                badge:SetPosition(SAFE_LEFT - 10, 6)
                badge:SetSize(10, 10)
                badge:SetBackColor(deedColor)

                local lbl = Turbine.UI.Label()
                lbl:SetParent(item)
                lbl:SetPosition(SAFE_LEFT - 10 + 16, 0)
                lbl:SetSize(SAFE_RIGHT - SAFE_LEFT - 16, ROW_HEIGHT)
                lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
                lbl:SetForeColor(deedColor)
                -- V15 (2026-09-05, mismo motivo/pedido que la fila de
                -- misiones mas arriba): contorno vuelto a poner, el fondo
                -- nuevo tiene demasiado detalle propio para leer color
                -- solo.
                lbl:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
                lbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
                lbl:SetText(tostring(deed.NAME))

                self.listBox:AddItem(item)
            end
        end
    end

    if count == 0 then
        local empty = Turbine.UI.Control()
        empty:SetSize(SAFE_RIGHT - 10, 26)

        local lbl = Turbine.UI.Label()
        lbl:SetParent(empty)
        lbl:SetPosition(SAFE_LEFT - 10, 0)
        lbl:SetSize(SAFE_RIGHT - SAFE_LEFT, 26)
        lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua12)
        -- V2: gris (0.6,0.6,0.6) tenia buen contraste sobre el panel OSCURO
        -- de antes -- sobre pergamino claro es casi invisible. HeadingGray
        -- de MEMBookStyle (140,140,140) tampoco alcanzaria aca (pensado
        -- para otro fondo); se usa un gris mas oscuro a mano, mismo
        -- criterio que BodyText pero un poco mas claro para que se note
        -- que es un estado "vacio", no una fila real.
        lbl:SetForeColor(Turbine.UI.Color(0.45, 0.42, 0.38))
        -- V15 (2026-09-05, mismo motivo que las filas de arriba).
        lbl:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
        lbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
        lbl:SetText(HT("empty"))

        self.listBox:AddItem(empty)
    end
end
