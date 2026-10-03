-- LOTRO_Quest_Assistant/UI/QuestBookWindow.lua
-- Ventana "libro" que se abre SOLA al aceptar o completar cualquier mision
-- (pedido explicito del usuario, inspirado en como el addon de terceros
-- MEMLotro presenta sus 3 aventuras propias como paginas narradas en vez de
-- una simple linea de chat). A diferencia de MEMLotro, esto NO es un arbol
-- de dialogo ramificado con PNJs/eventos -- esa estructura la arma a mano
-- un autor en un editor visual para historias chicas, y no existe (ni se
-- puede inventar sin falsear el contenido real) para las 14.824 misiones
-- oficiales de la base de este addon. Lo que SI se puede automatizar para
-- las 14.824 sin trabajo manual es la PRESENTACION: texto narrado en una
-- pagina en vez de una fila de lista, con el mismo dato que ya usa
-- QuestInfoTooltip.lua (QuestLocResolver.GetCleanObjectiveLines).
--
-- V2 (correccion del usuario despues de ver la V1 en el juego): la V1 usaba
-- book_menu.tga (panel unico, columna izquierda oscura tipo "Series" vacia
-- + columna derecha clara). El usuario pidio en cambio calcar el libro de
-- 2 paginas de pergamino de MEMLotro/MEMCommon/MEMQuestsBook.lua -- ver
-- captura "Mystery At The Pony": pagina izquierda con titulo + info +
-- descripcion, pagina derecha con encabezado "Quests" + lista, cinta roja
-- de nivel en la esquina, ambas paginas del mismo tono de pergamino. Las
-- coordenadas de abajo (levelTag en 304,3 / adventureTitle en 77,43 /
-- adventureDescription en 77,219 / questListTitle en 416,43 / questsList
-- en 378,86 tamaño 334x288) son las MISMAS que usa MEMQuestsBook.lua sobre
-- este mismo questbook.tga (756x471) -- leidas de su codigo real, no
-- adivinadas. No hay arte de portada por mision (14.824 misiones oficiales,
-- no 1 memoir hecho a mano) asi que el hueco de la imagen (77,81,256,128 en
-- MEM) se usa aca para Nivel/Zona en texto; la lista de la derecha ya no es
-- 1 bloque de texto narrado sino 1 fila por linea de objetivo (mismo dato
-- que antes, presentado como checklist en vez de parrafo).
--
-- Se mantiene Turbine.UI.Lotro.Window (chrome nativo) como clase base EN
-- VEZ de Turbine.UI.Window (que es lo que usa MEM) -- decision deliberada,
-- no un descuido: este mismo addon tuvo 3 cierres reales del juego
-- probando ventanas nuevas sin skin de Lotro con botones nativos adentro
-- (ver historial completo en Arquitectura_GatherSync.md #6 y el comentario
-- de GatherCaptureButton.lua). El chrome nativo de Lotro.Window ya esta
-- probado sin cierres en las otras ventanas de este addon -- el fondo de
-- libro se agrega como un Control HIJO con SetBackground(questbook.tga), el
-- mismo mecanismo ya usado sin problemas en GatherWindow.lua
-- (mapControl:SetBackground(zone.image)), no reemplazando la ventana en si.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"
-- (2026-10-01) anillo en llamas (ver ese archivo)
import "LOTRO_Quest_Assistant.UI.RingFireFX"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}

LQA.UI.QuestBookWindow = class(Turbine.UI.Lotro.Window)

-- Mismo offset de "debajo del titulo nativo" que ya usa GatherWindow.lua
-- (CONTENT_TOP=40) para una Turbine.UI.Lotro.Window -- constante ya
-- validada en este addon, no un numero nuevo sin probar.
local CHROME_TOP = 40
local PAGE_W, PAGE_H = 756, 471

-- V18 (2026-09-04, medido con Pillow sobre questbook_nueva_mision_v2.png
-- real, no adivinado -- pedido explicito del usuario tras ver varios bugs
-- de posicion/superposicion en el juego). Umbral de brillo>55 sobre filas
-- limpias (y=90/150/250/350, antes de que el anillo empiece a interferir)
-- da los limites REALES de cada pagina en esta imagen -- distintos de los
-- que uso MEMQuestsBook.lua sobre SU questbook.tga:
--   * Pagina izquierda: x=30..371 (el bloque de texto x=77,ancho=256
--     termina en 333, sigue entrando bien).
--   * Pagina derecha: x=386..728 -- el viejo objectivesList (x=378) SE
--     METIA 8px en el lomo/gutter del libro, por eso "no se ve centrado a
--     la hoja". RIGHT_PAGE_X/RIGHT_PAGE_W de aca abajo lo corrigen.
--   * Zona segura verticalmente: hasta y=~365-380 aprox -- a y=400 la
--     franja ya se corta en pedazos (el anillo dorado nuevo, mucho mas
--     grande que en el questbook.tga viejo, invade esa zona) -- por eso
--     btnGo/progressBack/btnNarrar quedaban tapados/perdidos contra el
--     anillo. BOTTOM_ROW_Y de aca abajo los sube a una fila realmente
--     libre.
local RIGHT_PAGE_X, RIGHT_PAGE_W = 392, 326
local BOTTOM_ROW_Y = 340
local WIDTH = PAGE_W
local HEIGHT = PAGE_H + CHROME_TOP

-- V20 (2026-09-04, pedido explicito del usuario: "el color de las letras
-- no se logra leer bien" -- el contorno negro de V18 no alcanzo). Tinta
-- MUCHO mas oscura que BodyText/TagText compartidos de MEMBookStyle.lua
-- (80,80,80 y 207,178,133 -- este ultimo un dorado CLARO, mala eleccion
-- de entrada contra pergamino claro, mas todavia en la imagen nueva mas
-- texturada/luminosa). Definida LOCAL a este archivo, no se toca el
-- constante compartido -- otras ventanas (QuestSyncWindow/QuestTrackerHUD)
-- ya se ven bien con los tonos viejos sobre SUS propios fondos, no hay
-- necesidad de arriesgar una regresion ahi.
local READABLE_INK = Turbine.UI.Color(40 / 255, 26 / 255, 14 / 255)

-- Hasta 6 lineas limpias de objectivesES (vs. 2 en el tooltip chico) --
-- esta es una ventana para LEER, no un tooltip de paso; con mas lugar
-- disponible tiene sentido mostrar mas narrativa real en vez de cortarla
-- antes de lo necesario.
local MAX_NARRATIVE_LINES = 6

local BANNER_TEXT = {
    ACCEPTED = { ES = "¡Nueva misión!", EN = "New Quest!" },
    COMPLETED = { ES = "¡Misión completada!", EN = "Quest Completed!" },
}
local BANNER_COLOR = {
    ACCEPTED = Turbine.UI.Color(0.4, 0.85, 0.4),
    COMPLETED = Turbine.UI.Color(1, 0.82, 0.3),
}

local function BT(kind)
    local lang = (_G.LanguageSettings and LanguageSettings.IsSpanish()) and "ES" or "EN"
    return BANNER_TEXT[kind][lang]
end

function LQA.UI.QuestBookWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    -- Sin SetResizable(true): en todo este addon esa llamada solo aparece
    -- cuando SE QUIERE que la ventana redimensione -- esta es a tamaño fijo
    -- (tamaño nativo real de questbook.tga), el default ya es fijo.
    self:SetSize(WIDTH, HEIGHT)
    self:SetVisible(false)

    -- Fondo de pagina (libro de 2 paginas de pergamino, 756x471), HIJO de
    -- la ventana (nunca la ventana en si) -- ver la nota grande arriba.
    self.pageBg = Turbine.UI.Control()
    self.pageBg:SetParent(self)
    self.pageBg:SetPosition(0, CHROME_TOP)
    self.pageBg:SetSize(PAGE_W, PAGE_H)
    self.pageBg:SetBackground(LQA.UI.MEMBookStyle.RES_BASE .. "questbook.tga")
    self.pageBg:SetMouseVisible(false)

    -- Anillo con brillo al pasar el mouse por CUALQUIER parte de la
    -- ventana (2026-09-05, pedido explicito del usuario: "el anillo no
    -- cambia como el otro addons" -- mismo mecanismo que QuestSyncWindow.
    -- lua/book_menu.tga). questbook.tga es PIXEL IDENTICO a
    -- questbook_nueva_mision_v2.png (confirmado con Pillow, diff=0), asi
    -- que el offset/tamaño del anillo real (x=306,y=331,144x140) esta
    -- medido sobre esa misma imagen, no adivinado. questbook_ring_hover.
    -- tga es ring2_hover_1.png tal cual lo entrego el usuario (SIN
    -- recorte/mascara propia) -- ya se confirmo que calza sin costura
    -- contra este fondo especifico (avg diff ~7/765 en los pixeles
    -- opacos, el mejor match encontrado de los 2 juegos de anillo
    -- probados esta sesion).
    self.ringGlow = Turbine.UI.Control()
    self.ringGlow:SetParent(self.pageBg)
    self.ringGlow:SetPosition(306, 331)
    self.ringGlow:SetSize(144, 140)
    self.ringGlow:SetBackground(LQA.UI.MEMBookStyle.RES_BASE .. "questbook_ring_hover.tga")
    self.ringGlow:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.ringGlow:SetMouseVisible(false)
    self.ringGlow:SetVisible(false)

    -- Deteccion de hover con POLL de posicion real del mouse (Update), NO
    -- con MouseEnter/Leave de la ventana -- MISMA razon que
    -- QuestSyncWindow.lua: los botones/listas de adentro (btnGo/
    -- btnNarrar/objectivesList/scrollbars) tienen su propio
    -- SetMouseVisible(true) y en este SDK eso corta el Enter/Leave del
    -- padre cada vez que el mouse pasa por encima de un hijo -- el anillo
    -- parpadearia en vez de quedarse prendido. GetMousePosition() da la
    -- posicion real sin importar que control este debajo.
    self.ringHoverPoll = Turbine.UI.Control()
    self.ringHoverPoll:SetParent(self.pageBg)
    self.ringHoverPoll:SetVisible(false)
    self.ringHoverPoll:SetWantsUpdates(true)
    self.ringHovering = false
    self.ringHoverPoll.Update = function()
        local mx, my = self:GetMousePosition()
        local over = mx >= 0 and mx < WIDTH and my >= CHROME_TOP and my < HEIGHT
        if over ~= self.ringHovering then
            self.ringHovering = over
            self.ringGlow:SetVisible(over)
        end
    end

    -- Cinta de nivel (esquina superior de la pagina izquierda) -- MISMA
    -- posicion/blend que self.summaryComponents.levelTag de
    -- MEMQuestsBook.lua sobre este mismo questbook.tga.
    self.levelTag = Turbine.UI.Control()
    self.levelTag:SetParent(self.pageBg)
    self.levelTag:SetPosition(304, 3)
    self.levelTag:SetSize(44, 70)
    self.levelTag:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.levelTag:SetBackground(LQA.UI.MEMBookStyle.RES_BASE .. "level_ribbon.tga")
    self.levelTag:SetMouseVisible(false)

    self.lblLevel = Turbine.UI.Label()
    self.lblLevel:SetParent(self.pageBg)
    self.lblLevel:SetPosition(310, 22)
    self.lblLevel:SetSize(31, 16)
    self.lblLevel:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
    self.lblLevel:SetForeColor(Turbine.UI.Color(219 / 255, 219 / 255, 219 / 255))
    self.lblLevel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.lblLevel:SetMouseVisible(false)

    -- Pagina IZQUIERDA: nombre de la mision + zona + narrativa. Misma
    -- columna (x=77, ancho=256) que adventureTitle/adventureDescription de
    -- MEMQuestsBook.lua.
    --
    -- V18 (2026-09-04, pedido explicito del usuario): questbook.tga nuevo
    -- (questbook_nueva_mision_v2, mismas 756x471) trae "¡Nueva misión!" YA
    -- quemado en (77,43) -- lblBanner (el label que dibujaba ESE mismo
    -- texto por codigo) se ELIMINA por completo, ya no hace falta.
    --
    -- El caso COMPLETED ("¡Misión completada!", que la imagen NO cubre --
    -- solo trae la version "nueva mision") ya no vive en esa posicion
    -- (superponerlo ahi se veia literalmente 2 textos pisados, "se pierde
    -- el texto" reportado por el usuario) -- se fusiona dentro de lblInfo
    -- mas abajo (la linea de zona), que cambia de color/texto segun el
    -- estado en vez de necesitar su propio cartel aparte. La imagen esta
    -- fija en español (sin variante EN) -- mismo trade-off ya aceptado
    -- para Activar/Completar/Desmarcar/Narrar en QuestSyncWindow.lua/
    -- QuestTrackerHUD.lua.

    -- BUG CORREGIDO (visto en captura con zoom del usuario: el nombre de
    -- la mision se superponia con la zona -- "...Elrohir, Capitulo 5" y
    -- "Taur Hith" se leian pisados uno sobre otro): lblTitle solo tenia
    -- 20px de alto para 1 sola linea, pero nombres largos como
    -- "Miniaventura: Las nuevas aventuras de Elladan y Elrohir, Capitulo
    -- 5" necesitan 2 -- la segunda linea se salia de su caja y caia
    -- encima de lblInfo, que empezaba muy cerca (24px mas abajo). Ahora
    -- lblTitle reserva 2 lineas reales (SetMultiline + 40px) y lblInfo se
    -- corre mas abajo para no chocar.
    --
    -- V18: y=71->78 (con lblBanner fuera del medio, el titulo ya no
    -- necesita pegarse tan arriba contra el cartel quemado en la imagen --
    -- un poco mas de aire lo separa visualmente en vez de leerse
    -- "encimado" contra "¡Nueva misión!").
    self.lblTitle = Turbine.UI.Label()
    self.lblTitle:SetParent(self.pageBg)
    self.lblTitle:SetPosition(77, 78)
    self.lblTitle:SetSize(220, 40)
    -- Pedido explicito del usuario: "mejorar el tamaño de la letra, que no
    -- sea demasiado pequeña" -- hay sobra de espacio en blanco en la
    -- pagina (ver captura), 14pt quedaba chico. Bold18 en vez de Bold14.
    self.lblTitle:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
    -- Pedido del usuario: el titulo de la mision tiene que distinguirse de
    -- la historia "como un libro de verdad" -- tinta bordo en vez del
    -- mismo gris que el cuerpo.
    -- V18 (pedido explicito del usuario: "el color se pierde" contra el
    -- pergamino ilustrado nuevo, mas texturado que el original liso):
    -- SetOutlineColor negro + FontStyle.Outline agregados -- a diferencia
    -- del cuerpo (18pt, donde ya se probo y se veia borroso, ver nota V7
    -- mas abajo), este titulo es Bold18 y mucho mas corto (1-2 lineas, no
    -- parrafos), el contorno lo separa del fondo texturado sin emborronar
    -- letras individuales de a una.
    self.lblTitle:SetForeColor(LQA.UI.MEMBookStyle.Color.TitleInk)
    self.lblTitle:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
    self.lblTitle:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.lblTitle:SetMultiline(true)
    self.lblTitle:SetMouseVisible(false)
    self.lblTitle:SetSelectable(false)

    -- Zona (+ estado "completada", ver V18 arriba) -- ocupa el hueco donde
    -- MEM pone la imagen de portada de su memoir (no hay arte de portada
    -- por mision, 14.824 misiones oficiales vs 1 memoir hecho a mano).
    -- BUG CORREGIDO (visto en la misma captura: "Taur Hith" casi
    -- invisible, muy claro sobre el pergamino) -- HeadingGray (140,140,140)
    -- es apenas mas oscuro que el pergamino real (~151,119,80) medido esta
    -- sesion en book_menu.tga -- questbook.tga es el mismo tono de
    -- pergamino, mismo problema de contraste. Se usa BodyText (80,80,80,
    -- el mismo tono oscuro que ya usa lblTitle) en vez de HeadingGray.
    -- V18: y=113->122 (corrido junto con lblTitle), alto 24->30 (ahora
    -- puede llevar "Zona — ¡Misión completada!" en 2 lineas cortas).
    self.lblInfo = Turbine.UI.Label()
    self.lblInfo:SetParent(self.pageBg)
    self.lblInfo:SetPosition(77, 122)
    self.lblInfo:SetSize(256, 30)
    -- Bold18 (no Antiqua18 sin negrita, pedido explicito del usuario: "se
    -- lee borroso los textos") -- QuestTrackerHUD.lua ya documento que
    -- BookAntiqua a este tamaño sin negrita se ve borroso sobre fondo
    -- texturado; con negrita+contorno se lee nitido.
    self.lblInfo:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
    -- V20: TagText (dorado CLARO, pensado para texto sobre fondo OSCURO en
    -- los botones tag_*) -> READABLE_INK -- sobre pergamino claro se leia
    -- "perdido" (bajo contraste real, no solo percibido). ShowFor la
    -- cambia a BANNER_COLOR.COMPLETED (dorado, CON contorno negro atras)
    -- cuando corresponde (ver V18 mas abajo) -- ese caso funciona bien
    -- igual, el contorno oscuro es lo que separa un dorado claro del
    -- pergamino, no el color solo.
    self.lblInfo:SetForeColor(READABLE_INK)
    self.lblInfo:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
    self.lblInfo:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.lblInfo:SetMultiline(true)
    self.lblInfo:SetMouseVisible(false)
    self.lblInfo:SetSelectable(false)

    -- Cuerpo narrado -- MISMA posicion que adventureDescription de
    -- MEMQuestsBook.lua (77,219,256,156).
    --
    -- V18: y=139->152 (sigue a lblInfo, que ahora termina en 152) y alto
    -- 231->188 (termina en 340 = BOTTOM_ROW_Y, en vez de 370 -- dejaba
    -- btnNarrar pegado contra el pie de la pagina/el anillo nuevo, ver
    -- nota grande de RIGHT_PAGE_X/BOTTOM_ROW_Y arriba). Outline agregado,
    -- mismo motivo/riesgo que lblTitle -- si se ve borroso en el juego
    -- (paso ya reportado como bug para BookAntiquaBold18 EN OTRO archivo,
    -- QuestTrackerHUD.lua, con fuente BOLD -- esta es BookAntiqua18 SIN
    -- negrita, contexto distinto, no hay antecedente directo), sacarlo.
    self.bodyScrollBar = Turbine.UI.Lotro.ScrollBar()
    self.bodyScrollBar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.bodyScrollBar:SetParent(self.pageBg)
    self.bodyScrollBar:SetPosition(77 + 256 + 6, 152)
    self.bodyScrollBar:SetSize(10, 188)

    -- V21 (2026-09-05, reporte real del usuario: "el texto no se mueve con
    -- la rueda del raton, hay que dar click y arrastrar... el del lado
    -- derecho si funciona, el izquierdo no"). La V20 (Label +
    -- SetVerticalScrollBar + un MouseWheel escrito a mano, ver el
    -- comentario/precedente que tenia esta seccion) asumia que ese
    -- precedente (CombatAnalysis/FileSelectBox.lua) aplicaba igual a
    -- Turbine.UI.Label -- confirmado en el juego que NO: el arrastre del
    -- thumb del scrollbar si movia el texto (el link de VALOR funciona),
    -- pero la rueda del mouse nunca disparaba el evento sobre un Label. La
    -- pagina DERECHA (objectivesList, un poco mas abajo) es un
    -- Turbine.UI.ListBox real y SI trae rueda de fabrica, sin codigo propio
    -- -- en vez de seguir adivinando por que un Label no la dispara, esta
    -- pagina pasa a usar el MISMO mecanismo ya comprobado: una ListBox con
    -- 1 fila (Label) por parrafo narrado, igual que ya arma objectivesList
    -- mas abajo con la misma fuente de datos (`narrative`).
    self.bodyList = Turbine.UI.ListBox()
    self.bodyList:SetParent(self.pageBg)
    self.bodyList:SetPosition(77, 152)
    self.bodyList:SetSize(256, 188)
    self.bodyList:SetVerticalScrollBar(self.bodyScrollBar)

    -- Pagina DERECHA: checklist.
    --
    -- V18 (2026-09-04, pedido explicito del usuario): self.lblObjectivesHeader
    -- ("Objetivos"/"Objectives", encabezado FIJO, siempre el mismo texto)
    -- eliminado -- questbook.tga nuevo lo trae quemado en (416,43). Mismo
    -- trade-off de idioma que arriba: la imagen solo tiene la version en
    -- español.
    --
    -- V18: x=378->RIGHT_PAGE_X(392), ancho=334->RIGHT_PAGE_W(326) -- medido
    -- con Pillow (ver nota grande arriba): 378 caia 8px DENTRO del
    -- lomo/gutter del libro en la imagen nueva, no en la hoja -- por eso
    -- "los textos en la 2da hoja no estan centrados a la hoja". Alto
    -- 288->300, pero YA NO empieza en y=86 -- ver mas abajo, el resto de
    -- las filas de esta pagina tambien se recalcularon contra
    -- BOTTOM_ROW_Y.
    self.objectivesScroll = Turbine.UI.Lotro.ScrollBar()
    self.objectivesScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.objectivesScroll:SetParent(self.pageBg)
    self.objectivesScroll:SetPosition(RIGHT_PAGE_X + RIGHT_PAGE_W + 8, 86)
    self.objectivesScroll:SetSize(10, BOTTOM_ROW_Y - 86)

    self.objectivesList = Turbine.UI.ListBox()
    self.objectivesList:SetParent(self.pageBg)
    self.objectivesList:SetPosition(RIGHT_PAGE_X, 86)
    self.objectivesList:SetSize(RIGHT_PAGE_W, BOTTOM_ROW_Y - 86)
    self.objectivesList:SetVerticalScrollBar(self.objectivesScroll)

    -- Logo de MISION DE GRUPO junto al titulo (2026-09-22, pedido explicito
    -- del usuario: "que en el mismo enunciado aparezca un logo de grupo").
    -- En el margen IZQUIERDO libre de la pagina (la hoja empieza en x=30, el
    -- titulo en x=77 -- ver nota grande de RIGHT_PAGE_X arriba): 24x24 en
    -- x=49 termina en 73, no toca el titulo ni mueve nada. Tamaño real del
    -- .tga + AlphaBlend (SetBackground no reescala -- ver
    -- CreateIconButtonAlpha en MEMBookStyle.lua). Oculto por defecto, SOLO
    -- ShowFor lo muestra y solo para misiones de GroupQuestDB.
    self.groupTitleIcon = Turbine.UI.Control()
    self.groupTitleIcon:SetParent(self.pageBg)
    self.groupTitleIcon:SetPosition(49, 80)
    self.groupTitleIcon:SetSize(24, 24)
    self.groupTitleIcon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    if _G.GroupQuest then
        self.groupTitleIcon:SetBackground(GroupQuest.ICON_24)
    end
    self.groupTitleIcon:SetMouseVisible(false)
    self.groupTitleIcon:SetVisible(false)

    -- Progreso "(N/M)", solo si la mision esta ACTIVA y tiene dato real
    -- guardado -- mismo assets que QuestInfoTooltip.lua (nunca se inventa
    -- un porcentaje sin dato detras).
    --
    -- V18: y=388->BOTTOM_ROW_Y+6 (medido con Pillow, ver nota grande
    -- arriba -- 388 caia sobre el anillo dorado nuevo, mucho mas grande
    -- que en el questbook.tga viejo, "se pierde" reportado por el
    -- usuario). Al lado de btnGo (misma fila) en vez de arriba, ya que la
    -- franja vertical libre se acorto -- x fijo (400) en vez de centrado
    -- sobre RIGHT_PAGE_W entero, para dejarle lugar a btnGo a la derecha
    -- en la misma fila sin superponerse.
    self.progressBack = Turbine.UI.Control()
    self.progressBack:SetParent(self.pageBg)
    self.progressBack:SetSize(200, 18)
    self.progressBack:SetPosition(400, BOTTOM_ROW_Y + 6)
    self.progressBack:SetBackground("LOTRO_Quest_Assistant/Resources/ProgressBar_Back.tga")
    self.progressBack:SetBlendMode(Turbine.UI.BlendMode.Overlay)
    self.progressBack:SetMouseVisible(false)
    self.progressBack:SetVisible(false)

    self.progressFill = Turbine.UI.Control()
    self.progressFill:SetParent(self.progressBack)
    self.progressFill:SetPosition(10, 5)
    self.progressFill:SetSize(0, 9)
    self.progressFill:SetBackground("LOTRO_Quest_Assistant/Resources/ProgressBar.tga")
    self.progressFill:SetBlendMode(Turbine.UI.BlendMode.Overlay)
    self.progressFill:SetMouseVisible(false)

    self.lblProgress = Turbine.UI.Label()
    self.lblProgress:SetParent(self.progressBack)
    self.lblProgress:SetPosition(0, 0)
    self.lblProgress:SetSize(200, 18)
    self.lblProgress:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    self.lblProgress:SetForeColor(Turbine.UI.Color.Beige)
    self.lblProgress:SetOutlineColor(Turbine.UI.Color(0.1, 0.1, 0.1))
    self.lblProgress:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.lblProgress:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.lblProgress:SetMouseVisible(false)

    -- Boton "Ir": se mantiene Turbine.UI.Lotro.Button (NO el
    -- MEMBookStyle.CreateIconButton nuevo) a proposito -- este boton lleva
    -- un Quickslot real detras (MoorMapAdapter), y Lotro.Button+Quickslot
    -- dentro de una Lotro.Window es la UNICA combinacion de boton+ventana
    -- ya confirmada sin cierres en este addon (QuestTrackerHUD/
    -- QuestSyncWindow). El estilo visual "libro" se limita a lo cosmetico
    -- (fondo, fuentes, colores) -- no se arriesga el mecanismo de clic real
    -- por estetica.
    self.btnGo = Turbine.UI.Lotro.Button()
    self.btnGo:SetParent(self.pageBg)
    -- Pedido del usuario: el boton quedaba sobre el borde de madera del
    -- atril, no sobre la hoja -- medido pixel a pixel en questbook.tga
    -- (VIEJO): el pergamino real se apagaba a madera oscura alrededor de
    -- y=405-420. Subido de y=414 a y=386.
    --
    -- V18: questbook.tga nuevo -> y=386 ahora cae sobre el anillo dorado
    -- (mucho mas grande que la decoracion vieja). Recalculado contra
    -- RIGHT_PAGE_X/RIGHT_PAGE_W/BOTTOM_ROW_Y (medidos con Pillow sobre la
    -- imagen real, ver nota grande arriba) en vez de los 378/334/386
    -- viejos.
    self.btnGo:SetPosition(RIGHT_PAGE_X + RIGHT_PAGE_W - 70, BOTTOM_ROW_Y + 6)
    self.btnGo:SetSize(70, 26)
    self.btnGo:SetVisible(false)

    -- Boton "Narrar" (pedido explicito del usuario, 2026-09-03: al
    -- desactivar la narracion AUTOMATICA al aceptar/completar una mision,
    -- este libro -- que SI se sigue abriendo solo en esos momentos, ver
    -- QUEST_JUST_ACCEPTED/QUEST_JUST_COMPLETED mas abajo -- necesita su
    -- propio boton para narrar a pedido, igual que ya tienen las filas del
    -- Tracker/QuestSync). Mismo estilo "tag" cyan que esos otros botones
    -- (CreateIconButton, sin Quickslot detras -- seguro de usar aca, ver la
    -- nota grande de btnGo arriba sobre por que btnGo si necesita quedarse
    -- como Lotro.Button nativo). Esquina inferior IZQUIERDA de la pagina
    -- izquierda (77 = mismo margen que el resto del texto de esa columna),
    -- misma fila Y que btnGo para quedar los dos alineados.
    --
    -- V13 (2026-09-04): tag_cyan generico + label "Narrar" -> arte propio
    -- "narrar" (mismo set que QuestSyncWindow.lua/QuestTrackerHUD.lua,
    -- CreateIconButtonAlpha -- texto ya quemado en la imagen, sin label
    -- superpuesto).
    --
    -- V14 (2026-09-04, tras confirmar en el juego que los botones se veian
    -- rotos/recortados): SetBackground en un Turbine.UI.Control NO
    -- reescala la imagen al tamaño del control -- la dibuja a su
    -- resolucion real y RECORTA lo que no entra, empezando desde la
    -- esquina. narrar.tga ahora se genera ya al tamaño real de uso
    -- (66x24, ver MEMBookStyle.lua/QuestSyncWindow.lua) -- 70x25 (el
    -- tamaño viejo de ESTE boton en particular, heredado de tag_cyan)
    -- mostraria un recorte del arte nuevo en vez de la placa completa, asi
    -- que este boton se unifica al mismo tamaño 66x24 que los demas usos
    -- de "narrar", 4px mas angosto que antes.
    --
    -- V18: y=386->BOTTOM_ROW_Y+6, misma fila Y que btnGo (idea original,
    -- ver nota grande de btnGo arriba) -- con questbook.tga nuevo, y=386
    -- quedaba pegado contra el pie de la pagina y el cuerpo narrado largo
    -- lo tapaba visualmente ("el boton narrar se pierde" reportado por el
    -- usuario); lblBody ahora termina en 340 (ver mas arriba), asi que
    -- BOTTOM_ROW_Y+6=346 le deja aire de sobra debajo del texto.
    -- V20 (2026-09-04, bug real confirmado por captura del usuario: el
    -- boton se veia "cortado"): QuestSyncWindow.lua regenero narrar.tga a
    -- 103x37 (V19, grilla 2x2 achicada) -- este boton seguia pidiendolo a
    -- 66x24, un archivo compartido no puede tener 2 tamaños reales a la
    -- vez, asi que se recortaba (mismo bug de fondo que V14, esta vez por
    -- un archivo compartido entre 2 ventanas en vez de un tamaño viejo).
    -- Archivo propio "narrar_questbook" (66x24 real) para no competir mas
    -- con el tamaño que necesita QuestSyncWindow.
    self.btnNarrar = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("narrar_questbook", 66, 24)
    self.btnNarrar:SetParent(self.pageBg)
    self.btnNarrar:SetPosition(77, BOTTOM_ROW_Y + 6)
    self.btnNarrar.ButtonClicked = function()
        if not self.currentQuest then return end
        if self.currentKind == "COMPLETED" then
            NarratorBridge.AnnounceCompleted(self.currentNdx)
        else
            NarratorBridge.PlayQuestText(self.currentNdx, self.currentQuest, self.currentEsName)
        end
    end

    self:SetPosition((Turbine.UI.Display.GetWidth() - WIDTH) / 2, 90)

    -- SFX de "abrir pergamino" RETIRADO (pedido explicito del usuario,
    -- 2026-09-03) -- ver la nota grande en NarratorBridge.lua.

    if LQA and LQA.Core and LQA.Core.EventBus then
        -- Ver la nota junto a QUEST_JUST_ACCEPTED/QUEST_JUST_COMPLETED en
        -- QuestStateManager.lua: son eventos APARTE de QUEST_STATE_CHANGED,
        -- garantizados a disparar solo en la transicion real (no en cada
        -- reafirmacion por texto de objetivo/narrativa), asi que esta
        -- ventana nunca se reabre sola por una mision que ya estaba activa.
        LQA.Core.EventBus:Subscribe("QUEST_JUST_ACCEPTED", function(data)
            if data and data.ndx then self:ShowFor(data.ndx, "ACCEPTED") end
        end)
        LQA.Core.EventBus:Subscribe("QUEST_JUST_COMPLETED", function(data)
            if data and data.ndx then self:ShowFor(data.ndx, "COMPLETED") end
        end)
    end

    -- (2026-10-01) el anillo arde como el del Tracker (solo imagen, sin
    -- mouse; ver UI/RingFireFX.lua). En pcall: si fallara, todo sigue igual.
    if LQA.UI.RingFireFX ~= nil then
        pcall(LQA.UI.RingFireFX.AttachRing, self, self.pageBg, {
            prefix = "questbook_fx_", x = 306, y = 301, w = 144, h = 170,
            rim = {
                { 341, 386 }, { 347, 378 }, { 353, 372 }, { 359, 368 }, { 365, 364 }, { 371, 361 }, { 377, 358 },
                { 383, 357 }, { 389, 356 }, { 395, 355 }, { 401, 356 }, { 407, 357 }, { 413, 360 },
            },
        })
    end
end

function LQA.UI.QuestBookWindow:ShowFor(ndx, kind)
    local quest = _G.QuestDB and QuestDB.quests and QuestDB.quests[ndx]
    if not quest then return end

    local esName = QuestLocResolver.GetQuestNameES(ndx, quest.nameEN)

    -- Guardados para que btnNarrar.ButtonClicked (ver Constructor) sepa que
    -- narrar cuando el jugador lo clickee mas tarde -- ShowFor puede volver
    -- a llamarse para otra mision mientras el libro sigue abierto, asi que
    -- esto SIEMPRE tiene que reflejar la mision actualmente mostrada.
    self.currentNdx = ndx
    self.currentQuest = quest
    self.currentEsName = esName
    self.currentKind = kind

    self:SetText(esName) -- titulo nativo de la ventana (chrome de Lotro)
    self.lblTitle:SetText(esName) -- repetido adentro de la pagina, estilo libro

    -- Mision de GRUPO (ver Core/GroupQuest.lua): titulo en color de grupo
    -- (el contorno negro que ya tiene lblTitle lo separa del pergamino) +
    -- logo a la izquierda. Se resetea SIEMPRE -- el libro es una sola
    -- ventana reusada para cada mision que se acepta/completa.
    local groupEntry = _G.GroupQuest and GroupQuest.Get(quest)
    if groupEntry then
        self.lblTitle:SetForeColor(GroupQuest.Color.Dark)
        self.groupTitleIcon:SetVisible(true)
    else
        self.lblTitle:SetForeColor(LQA.UI.MEMBookStyle.Color.TitleInk)
        self.groupTitleIcon:SetVisible(false)
    end

    self.lblLevel:SetText(tostring(quest.level or "?"))
    local area = (quest.area and quest.area ~= "" and quest.area) or quest.zone

    -- V18: lblBanner eliminado (mostraba "¡Nueva misión!"/"¡Misión
    -- completada!" superpuesto a (77,43), pero questbook.tga nuevo YA trae
    -- "¡Nueva misión!" quemado ahi -- se leian los 2 textos pisados, "se
    -- pierde"/duplicado reportado por el usuario). ACCEPTED no necesita
    -- nada mas (la imagen ya lo dice); COMPLETED (que la imagen NO cubre)
    -- se fusiona en esta misma linea de zona en vez de pelear por un
    -- cartel aparte -- cambia texto Y color en vez de solo texto.
    if kind == "COMPLETED" then
        self.lblInfo:SetText(BT(kind) .. (area and ("  —  " .. tostring(area)) or ""))
        self.lblInfo:SetForeColor(BANNER_COLOR.COMPLETED)
    else
        self.lblInfo:SetText(area and tostring(area) or "")
        self.lblInfo:SetForeColor(READABLE_INK)
    end

    local narrative = QuestLocResolver.GetCleanObjectiveLines(ndx, quest, MAX_NARRATIVE_LINES)

    -- V21: bodyList (ver Constructor) en vez de un solo lblBody:SetText --
    -- ClearItems()+AddItem() por parrafo, mismo patron que objectivesList
    -- mas abajo (misma fuente `narrative`, ya probado en este archivo).
    -- Sin scrollBar:SetValue(0) aca tampoco: mismo motivo que antes, esa
    -- API no tiene precedente confirmado en este addon; ClearItems() ya
    -- vacia la lista, es la scrollbar la que puede quedar con el thumb
    -- desplazado al reabrir para otra mision -- el jugador la puede
    -- arrastrar/girar la rueda arriba a mano.
    self.bodyList:ClearItems()
    local bodyLines = narrative
    if #bodyLines == 0 then
        bodyLines = {
            (_G.LanguageSettings and LanguageSettings.IsSpanish())
                and "(sin texto narrativo disponible para esta misión)"
                or "(no narrative text available for this quest)"
        }
    end
    for _, line in ipairs(bodyLines) do
        local row = Turbine.UI.Label()
        row:SetSize(256 - 10, 52)
        row:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
        row:SetForeColor(READABLE_INK)
        row:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
        row:SetFontStyle(Turbine.UI.FontStyle.Outline)
        row:SetMultiline(true)
        row:SetMouseVisible(false)
        row:SetText(line)
        self.bodyList:AddItem(row)
    end

    -- Checklist de la pagina derecha (estilo "Quests" de MEMQuestsBook.lua,
    -- ver captura de referencia): 1 fila por linea de objetivo/narrativa,
    -- mismo dato que arriba pero presentado como lista en vez de parrafo.
    self.objectivesList:ClearItems()

    -- Primera fila del checklist para misiones de GRUPO: logo + "MISION DE
    -- GRUPO · Comunidad (6)" + "Mazmorra: <instancia>" -- lo que el jugador
    -- necesita saber ANTES de leer los objetivos (a donde ir y con cuantos).
    -- Misma fuente/contorno que las filas normales de abajo (60px de alto,
    -- Bold18) para que el ListBox la trate igual; el texto arranca despues
    -- del logo (30px) y usa el color de grupo en vez de READABLE_INK.
    if groupEntry then
        -- 2026-09-27: con el nombre de la mazmorra en español Y en ingles
        -- el texto puede pasar a 3-4 lineas: el alto crece solo (~18px por
        -- linea de Bold14), nunca menos de los 60 de siempre.
        local groupText = GroupQuest.Statement(groupEntry)
        local groupH = 60
        if GroupQuest.EstimateLines then
            groupH = math.max(60, GroupQuest.EstimateLines(groupText, RIGHT_PAGE_W - 10 - 30, 7.5) * 18 + 6)
        end
        local groupRow = Turbine.UI.Control()
        groupRow:SetSize(RIGHT_PAGE_W - 10, groupH)
        groupRow:SetMouseVisible(false)

        local groupRowIcon = Turbine.UI.Control()
        groupRowIcon:SetParent(groupRow)
        groupRowIcon:SetPosition(0, 4)
        groupRowIcon:SetSize(24, 24)
        groupRowIcon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        groupRowIcon:SetBackground(GroupQuest.ICON_24)
        groupRowIcon:SetMouseVisible(false)

        local groupRowLbl = Turbine.UI.Label()
        groupRowLbl:SetParent(groupRow)
        groupRowLbl:SetPosition(30, 0)
        groupRowLbl:SetSize(RIGHT_PAGE_W - 10 - 30, groupH)
        groupRowLbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold14)
        groupRowLbl:SetForeColor(GroupQuest.Color.Dark)
        groupRowLbl:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
        groupRowLbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
        groupRowLbl:SetMultiline(true)
        groupRowLbl:SetMouseVisible(false)
        groupRowLbl:SetText(groupText)

        self.objectivesList:AddItem(groupRow)
    end

    for _, line in ipairs(narrative) do
        local row = Turbine.UI.Label()
        -- Alto 52 (no 40): mismo criterio que el resto de la sesion --
        -- letra mas grande (18pt) necesita mas alto real por linea.
        row:SetSize(RIGHT_PAGE_W - 10, 52)
        -- Bold18 (mismo motivo/pedido que lblInfo/lblBody arriba).
        row:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
        -- V20: mismo cambio de contraste que lblBody -- ver READABLE_INK.
        row:SetForeColor(READABLE_INK)
        row:SetOutlineColor(Turbine.UI.Color(0, 0, 0))
        row:SetFontStyle(Turbine.UI.FontStyle.Outline)
        row:SetMultiline(true)
        row:SetMouseVisible(false)
        row:SetText("- " .. line)
        self.objectivesList:AddItem(row)
    end

    if kind == "ACCEPTED" then
        local cur, total = nil, nil
        local progressText = _G.QuestStateManager and QuestStateManager.GetQuestProgress(ndx)
        if progressText and progressText ~= "" then
            cur, total = string.match(progressText, "(%d+)%s*/%s*(%d+)")
            cur, total = tonumber(cur), tonumber(total)
        end
        if cur and total and total > 0 then
            local pct = math.min(1, cur / total)
            self.progressFill:SetWidth(math.max(2, math.floor(179 * pct)))
            self.lblProgress:SetText(cur .. "/" .. total)
            self.progressBack:SetVisible(true)
        else
            self.progressBack:SetVisible(false)
        end
    else
        self.progressBack:SetVisible(false)
    end

    local loc = _G.MoorMapAdapter and MoorMapAdapter.ResolveQuestLoc(ndx, quest)
    if loc and _G.MoorMapAdapter then
        self.btnGo:SetText((_G.LanguageSettings and LanguageSettings.IsSpanish()) and "Ir" or "Go")
        self.btnGo:SetVisible(true)

        if self.goQuickslot == nil then
            self.goQuickslot = MoorMapAdapter.CreateQuickslot()
            MoorMapAdapter.AttachToButton(self.goQuickslot, self.btnGo)
        end
        local ns, ew = MoorMapAdapter.ParseCoord(loc)
        MoorMapAdapter.SetQuestMarker(self.goQuickslot, {
            mapID = MoorMapAdapter.ResolveMapID(quest),
            ns = ns or 0,
            ew = ew or 0,
            name = string.gsub(esName, ":", "-"),
            description = "Objetivo",
        })
    else
        self.btnGo:SetVisible(false)
    end

    self:SetVisible(true)
end
