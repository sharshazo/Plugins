-- LOTRO_Quest_Assistant/UI/QuestSyncWindow.lua
-- Ventana UNICA del addon. REDISEÑO VISUAL "libro real" (pedido explicito
-- del usuario, con capturas de MEMLotro como referencia).
--
-- V2 (mismo dia, correccion del usuario despues de ver la V1 en el juego):
-- la V1 usaba el libro de 2 paginas questbook.tga (page_left/page_right
-- para pasar de categoria). El usuario pidio en cambio calcar el panel de
-- MEMMain.lua -- ver capturas de "Middle Earth Memoirs" (book_menu.tga,
-- 624x508, columna "Series" izquierda + columna "Memoir" derecha) -- pero
-- repurposado: la columna izquierda (antes "Series") ahora dice "Mapas"
-- (pestaña QuestSync) o "Titulos" (Puntos de Interes/Tropas/Colecciones) y
-- lista la MISMA estructura agrupada que ya tenia esta ventana; la columna
-- derecha (antes "Memoir") ahora dice "Informacion" y muestra el
-- detalle/mapa/puntos con los botones de MoorMap/Waypoint, tal cual pidio:
-- "en Series diga 'Mapas' y abajo tengamos la estructura que tenemos de
-- questsync... y al lado en memoir la informacion, historia, objetivo y
-- los puntos con los botones de moormap. Y asi en cada pestaña."
--
-- Tambien corrige un bug real visto en las capturas de la V1: "Objetivo de
-- la Mision:" se dibujaba DOS veces (una como encabezado fijo, otra como
-- fila suelta dentro de la lista) -- ahora es un encabezado fijo UNICO,
-- igual que ya funcionaba bien para "Puntos:" en Puntos de Interes/Tropas.
--
-- DECISION DELIBERADA (no un descuido, se mantiene de la V1): sigue
-- usando Turbine.UI.Lotro.Window como clase base (chrome nativo) en vez de
-- Turbine.UI.Window puro (lo que usa MEMLotro) -- ver la nota grande en
-- QuestBookWindow.lua sobre los 3 cierres reales del juego que costo
-- aprender esto. El fondo de panel se agrega como un Control HIJO
-- (self.pageBg) con SetBackground(book_menu.tga), nunca reemplazando la
-- ventana en si. Tampoco se usa MEMBookStyle.CreateIconButton/
-- CreateTagButton (nunca probados en el juego en todo este addon, ver la
-- misma nota) -- las flechas de categoria y el interruptor ES/EN siguen
-- siendo Turbine.UI.Lotro.Button nativos.
--
-- Las coordenadas de la columna izquierda (23,98,218,384 + scrollbar en
-- 246) y de los encabezados "Series"/"Memoir" (23,71 / 266,71) estan
-- calcadas literalmente de MEMLotro/MEMCommon/MEMMain.lua sobre este mismo
-- book_menu.tga -- no son numeros adivinados.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"
-- (2026-10-01) anillo en llamas y estrellas en el titulo (ver ese archivo)
import "LOTRO_Quest_Assistant.UI.RingFireFX"

_G.QuestSyncWindow = class(Turbine.UI.Lotro.Window)

local CHROME_TOP = 40
local PAGE_W, PAGE_H = 624, 508
local WIDTH, HEIGHT = PAGE_W, PAGE_H + CHROME_TOP
-- MAP_H bajado de 200 a 150 (2026-09-05): al agrandar titulo/descripcion
-- (Bold18->24, 16->18, pedido explicito del usuario) y necesitar mas
-- margen abajo para que MoorMap/Waypoint no toquen el marco de madera
-- (otro pedido de la misma sesion), el presupuesto vertical real de la
-- pagina nueva (quest_journal_skin.png) ya no alcanza para los 3 al
-- tamaño viejo. Se prioriza texto grande + botones sin recorte por sobre
-- el minimapa a tamaño maximo -- avisar si se prefiere el orden inverso.
local MAP_W, MAP_H = 300, 150
local RES_BASE = "LOTRO_Quest_Assistant/Resources/"
local BOOK_RES = "LOTRO_Quest_Assistant/Resources/Book/"

-- Ventana popup de Mapa/Ruta por punto (2026-09-05, reemplaza la lista
-- embebida con scrollbar -- ver la nota grande junto a self.pointsPopup
-- en el Constructor). Ancho justo para los items de RIGHT_W(300) + su
-- propia scrollbar, sin depender de ningun recorte de pixeles del libro.
-- Alto chico a proposito (pedido explicito del usuario, "puede ser mas
-- pequeña") -- tiene su propio scroll, no necesita mostrar todo de una.
local POPUP_W, POPUP_H = 340, 260

-- Recorte real del anillo dentro de book_menu.tga (624x508, esquina
-- inferior derecha) -- offset medido pixel a pixel comparando
-- ring_normal.png contra el skin nuevo (quest_journal_skin.png), no
-- adivinado: es el que da la menor diferencia de color posible (avg ~27
-- de 765 por canal, resto explicado por reencode PNG/TGA), y ademas
-- calza justo con el borde inferior derecho de la pagina (504+120=624,
-- 383+125=508) -- el anillo esta pegado a esa esquina.
local RING_X, RING_Y, RING_W, RING_H = 504, 383, 120, 125

-- Columna izquierda ("Mapas"/"Titulos") -- coordenadas calcadas de
-- MEMMain.lua: seriesLabel (23,71,236,24) y booksList (23,98,218,384) con
-- su scrollbar en (246,98,10,384).
local LEFT_X, LEFT_W = 23, 218
-- LEFT_HEADER_Y/RIGHT_HEADER_Y CORREGIDOS (2026-09-05, pedido explicito
-- del usuario: "los titulos... estan flotando por ENCIMA del cartel de
-- pergamino decorativo... hay que bajar/centrar ambos"). 71 era valido
-- para el cartel del SKIN VIEJO -- con quest_journal_skin.png (book_menu.
-- tga actual) el cartel real (la cinta con puntas) se midio pixel por
-- pixel: banda legible pareja en TODO su ancho, y=89 a y=102 (Pillow,
-- ambos lados, izquierda y derecha dan el mismo rango). Centro = 95.5;
-- con caja de 24-25px de alto y TextAlignment.MiddleCenter, Y=83 centra
-- el texto justo en esa banda.
local LEFT_HEADER_Y = 83
local LEFT_SCROLL_X = 246

-- Columna derecha ("Informacion"): RIGHT_X/RIGHT_W se corrigieron de
-- (266,334) -- calcado de memoirLabel de MEMMain.lua, adivinado -- a
-- (279,300), las coordenadas REALES del pergamino medidas en
-- book_menu.tga (PNG convertido con Pillow y muestreado pixel por pixel,
-- ver la nota grande junto a RIGHT_BOTTOM_LIMIT). 300 = mismo ancho que
-- MAP_W, con margen parejo a los 2 lados del pergamino real (279 a 595).
local RIGHT_X, RIGHT_W = 279, 300
local RIGHT_HEADER_Y = 83 -- ver nota grande junto a LEFT_HEADER_Y

local TITLE_X, TITLE_Y, TITLE_W = 152, 7, 322
-- ARROW_RIGHT_X 582->548: los botones "tag" de MEM (68px de ancho) no
-- entraban en 582 sin salirse del borde derecho de la ventana (624px).
local ARROW_LEFT_X, ARROW_RIGHT_X, ARROW_Y = 14, 548, 10
local LANG_BTN_X, LANG_BTN_Y = 582, 40

-- SEARCH_Y/SEARCHINFO_Y/LIST_Y bajados +12 (mismo delta que
-- LEFT_HEADER_Y: 83-71) para no quedar tapados por el cartel "Mapas" que
-- ahora ocupa mas abajo (termina en Y+24=107, antes terminaba en 95).
-- LIST_H se achica los mismos 12px para conservar el limite inferior real
-- de la columna (129+353=482, ahora 141+341=482 -- identico).
local SEARCH_Y = 109
local SEARCHINFO_Y = 130
local LIST_Y = 141
local LIST_H = 341 -- termina en 482 (igual que antes)

-- BUG CORREGIDO CON MEDICION REAL (los 2 intentos anteriores adivinaban
-- las zonas de book_menu.tga a ojo desde capturas -- esta vez se convirtio
-- el .tga real a PNG con Pillow y se muestrearon los pixeles directamente,
-- ver sesion de analisis). Resultado real (624x508, coordenadas de
-- pageBg):
--   * Columna IZQUIERDA: NEGRA solida de punta a punta (x=8-258,
--     y=96-496aprox) -- no hay pergamino ahi, nunca lo hubo. El texto
--     tiene que ser CLARO (dorado/tostado), no tinta oscura.
--   * Columna DERECHA: pergamino real SOLO entre y=109-438 y x=279-595;
--     fuera de ese rectangulo (arriba, abajo y en los bordes) es
--     oscuro/madera, igual que la izquierda.
--   * Cinta roja decorativa: x=550-580, y=99-157 (esquina superior
--     derecha DEL PERGAMINO, no un marco grande para una imagen completa
--     como se asumio antes -- es un adorno chico).
-- Con esto: titulo/descripcion se ubican DENTRO del pergamino (109-438) y
-- angostos (hasta x=540) para no pisar la cinta; el mapa/lista de puntos
-- reserva zona aparte segun haya mapa o no (como antes) porque el
-- pergamino real no alcanza para los 3 al mismo tiempo con letra grande.
-- Para lo que si cae fuera del pergamino (la lista de puntos en el caso
-- con mapa, que sobra hacia la franja oscura de abajo) se usa texto CLARO
-- con contorno negro (ver ApplyReadableStyle) en vez de tinta oscura --
-- asi se lee igual sobre pergamino o sobre madera, sin tener que acertar
-- el pixel exacto donde cambia el fondo.
-- RIGHT_BOTTOM_LIMIT CORREGIDO (2026-09-05, pedido explicito del usuario:
-- "MoorMap/Waypoint... casi tocando el marco de madera"). 465 era valido
-- para el skin viejo -- en quest_journal_skin.png (book_menu.tga actual)
-- se re-midio pixel por pixel: el pergamino real (brillo parejo) llega
-- hasta y=468-472 en toda la columna, con un filo de madera iluminado en
-- 476 y la franja oscura del marco recien empieza en 480.
local RIGHT_BOTTOM_LIMIT = 474 -- ultimo pixel util antes del marco (madera empieza en 480)
local PARCHMENT_X0, PARCHMENT_X1 = 279, 595 -- limites reales del pergamino
local PARCHMENT_Y0, PARCHMENT_Y1 = 109, 438
local RIBBON_X0 = 548 -- el titulo/descripcion no cruzan mas alla de aca (esquiva la cinta)

local RIGHT_TITLE_Y = PARCHMENT_Y0 + 4 -- 113
-- BUG CORREGIDO (screenshot del usuario, 2026-09-03: "perdida de texto de
-- los titulos" -- un nombre de 2 lineas, ej. "Libro 5, Capitulo 1: Hacia
-- las Montañas Nubladas", se dibujaba con la 2da linea encima de "Nivel:").
-- lblTitle tiene SetMultiline(true) pero esta caja solo reservaba 26px (1
-- linea) -- mismo tipo de bug ya corregido antes en QuestBookWindow.lua
-- (lblTitle ahi reserva 40px/2 lineas), nunca aplicado aca. Mismo valor
-- (40px/2 lineas, no 3): esta columna es bastante mas ancha (263px vs 148px
-- del Tracker) asi que 2 lineas ya cubren nombres bien largos sin comerse
-- de mas el espacio de abajo.
-- 52 (no 40): pedido explicito del usuario ("aumentar el tamaño de esos
-- textos"), lblTitle paso de BookAntiquaBold18 a BookAntiquaBold24 -- 2
-- lineas a ese tamaño necesitan mas alto real (mismo motivo que el bug de
-- arriba, solo que con la fuente mas grande).
local RIGHT_TITLE_H = 52
local RIGHT_TITLE_W = RIBBON_X0 - PARCHMENT_X0 - 6 -- 263, esquiva la cinta
local RIGHT_DESC_Y = RIGHT_TITLE_Y + RIGHT_TITLE_H + 4
-- 60 (no 56): lblDesc paso de BookAntiqua16 a BookAntiqua18 (mismo pedido
-- de arriba), 3 lineas (Nivel/Progreso/Destino) necesitan un poco mas.
local RIGHT_DESC_H = 60
local RIGHT_DESC_W = RIGHT_TITLE_W

-- Mapa: empieza despues de la descripcion. El detalle de puntos (Punto
-- 1/2/3... + Mapa/Ruta de cada uno) ya NO vive en el panel -- ver
-- self.pointsPopup en el Constructor -- asi que RIGHT_POINTS_Y_MAP solo
-- posiciona el encabezado "Puntos:" + el boton que abre esa ventana.
local RIGHT_CONTENT_Y = RIGHT_DESC_Y + RIGHT_DESC_H + 6 -- 205 (Y del mapa, SOLO se usa para eso)
local RIGHT_POINTS_Y_MAP = RIGHT_CONTENT_Y + MAP_H + 6 -- 411

-- Fila de botones Activar/Completar/Desmarcar (SOLO misiones, pedido
-- explicito del usuario: "los objetivos de las misiones no tiene botones"
-- -- antes eran filas de texto dentro de la lista, ahora son botones
-- reales Turbine.UI.Lotro.Button, igual que Mapa/Ruta). Independiente de
-- RIGHT_CONTENT_Y (que sigue siendo solo la posicion del mapa) para no
-- afectar el layout de Puntos de Interes/Tropas, que nunca muestran estos
-- botones.
local RIGHT_ACTIONS_Y = RIGHT_CONTENT_Y -- 205
-- V15 (2026-09-04, pedido explicito del usuario: "pueden ser un poco mas
-- grande, se pierde la lectura visual" -- ya con el arte nuevo instalado y
-- funcionando bien). 4 botones en 1 sola fila (66x24 cada uno) no tenian
-- margen para crecer: a actionBtnW(72) de paso, los 4 YA llenaban
-- RIGHT_W(300) exacto (4*72 + 3*4 = 300), no quedaba aire. Pasado a grilla
-- 2x2 -- mismo criterio que MAP_W/MAP_H mas arriba, reparte el mismo
-- ancho total en menos columnas para que cada boton sea mas grande. Cada
-- celda mantiene el ratio real del arte (440x160 = 2.75:1, ver
-- MEMBookStyle.lua) para no deformar el texto quemado en la imagen.
-- V19 (2026-09-04, pedido explicito del usuario: "podemos achicar un
-- poquito esos botones, quizas un 30%"). ACTION_COL_W ya no llena la
-- columna entera (148) -- se reduce un 30% (0.7x) desde ese tamaño
-- "lleno". El bloque 2x2 completo se achica con el mismo factor (ver
-- RIGHT_ACTIONS_H mas abajo), asi que la lista de "Objetivo de la Mision"
-- recupera parte del alto que le habia sacado la grilla mas grande de V15.
local ACTION_GAP = 4
local ACTION_COL_W = math.floor(math.floor((RIGHT_W - ACTION_GAP) / 2) * 0.7) -- 103
local ACTION_ROW_H = math.floor(ACTION_COL_W / 2.75) -- 37
local RIGHT_ACTIONS_H = ACTION_ROW_H * 2 + ACTION_GAP -- 78 (bloque completo, para RIGHT_POINTS_Y_NOMAP)
local RIGHT_POINTS_Y_NOMAP = RIGHT_ACTIONS_Y + RIGHT_ACTIONS_H + 6 -- 289
-- RIGHT_BTN_Y CORREGIDO DE NUEVO (2026-09-05, pedido explicito del
-- usuario: "MoorMap/Waypoint... casi tocando el marco de madera... su
-- texto de atajo queda cortado"). 462 era correcto para el skin viejo,
-- pero con quest_journal_skin.png (RIGHT_BOTTOM_LIMIT re-medido a 474, ver
-- nota grande ahi) y los botones ahora mas altos (32, no 26, para dejarle
-- lugar real al "/Moo"/"/Way" que dibuja el Quickslot nativo debajo del
-- boton -- ver la nota grande de MoorMapAdapter.AttachToButton sobre ese
-- sangrado, NUNCA resuelto del todo, solo mitigado con mas espacio real),
-- 462+32=494 se hubiera metido de lleno en el marco. Subido a 427: deja
-- 474-(427+32)=15px libres antes del marco para ese sangrado.
local RIGHT_BTN_Y = 427

local POI_ICON = RES_BASE .. "chest.jpg"
local THREAT_ICON = RES_BASE .. "threat.tga"
local LOSTLORE_BOOK_ICON = RES_BASE .. "lostlore_book.tga"
local LOSTLORE_TREASURE_ICON = RES_BASE .. "lostlore_treasure.tga"

local function LostLoreIconFor(entry)
    if entry.type == "Q" then return LOSTLORE_BOOK_ICON end
    return LOSTLORE_TREASURE_ICON
end

-- Categorias = "paginas" logicas (se pasan con las flechas <>). leftHeader
-- indica que texto va en la columna izquierda para esa categoria (pedido
-- explicito del usuario: "Mapas" para QuestSync, "Titulos" para el resto).
-- leftHeader UNIFICADO a "left_header_maps" en las 4 pestañas (2026-09-05,
-- pedido explicito del usuario: "en las otras ventanas aparece TITULOS,
-- poner MAPAS") -- antes Puntos de Interes/Tropas y Amenazas/Colecciones
-- usaban "left_header_titles" ("Titulos"), decision deliberada de una
-- sesion anterior; el usuario la reemplaza ahora por el mismo texto
-- "Mapas" en las 4.
local TABS = {
    { key = "misiones", label = "QuestSync", labelEN = "QuestSync", leftHeader = "left_header_maps" },
    { key = "puntos", label = "Puntos de Interes", labelEN = "Points of Interest", db = "ChestsDB", icon = POI_ICON, leftHeader = "left_header_maps" },
    { key = "tropas", label = "Tropas y Amenazas", labelEN = "Threats & Troops", db = "ThreatsDB", icon = THREAT_ICON, leftHeader = "left_header_maps" },
    { key = "lostlore", label = "Colecciones", labelEN = "Collections", db = "LostLoreDB", resolveIcon = LostLoreIconFor, leftHeader = "left_header_maps" },
}

-- Paleta "tinta sobre pergamino" (ver MEMMain.lua: seriesLabel/memoirLabel
-- en gris 140/140/140 con contorno negro).
-- Paleta "tinta sobre pergamino" (V3, mas saturada -- pedido explicito del
-- usuario: "los colores no se logran visualizar... cambia colores para
-- que sea visual"). Recompensa se separa del verde de "completada" (antes
-- casi identicos) a un dorado/marron calido, tematicamente mas propio de
-- un tesoro/recompensa.
-- V4 (correccion con MEDICION REAL de book_menu.tga, ver la nota grande
-- junto a RIGHT_BOTTOM_LIMIT): la paleta anterior ("tinta oscura sobre
-- pergamino") solo tenia sentido para el TITULO/DESCRIPCION, que si caen
-- sobre pergamino real. TODO lo demas -- la columna izquierda entera
-- (siempre negra) y buena parte de la lista de puntos de la derecha
-- (puede terminar fuera del pergamino real, en la franja oscura de abajo)
-- -- necesita texto CLARO. Se usa la MISMA tecnica que ya usa MEM en sus
-- propios encabezados (color + SetOutlineColor negro + FontStyle.Outline,
-- ver ApplyHeadingStyle/ApplyReadableStyle): el contorno negro mantiene el
-- texto legible sea cual sea el fondo real detras (negro, pergamino, o la
-- franja de transicion entre los dos), sin tener que acertar el pixel
-- exacto donde cambia.
local INK = LQA.UI.MEMBookStyle.Color.BodyText -- (80,80,80)/255 -- SOLO titulo/descripcion (pergamino real)
local INK_SECONDARY = Turbine.UI.Color(90 / 255, 65 / 255, 35 / 255) -- SOLO descripcion (pergamino real)

-- Texto claro con contorno -- para todo lo que vive en la columna
-- izquierda (negra) o puede caer fuera del pergamino en la derecha.
local ROW_TEXT = Turbine.UI.Color(224 / 255, 196 / 255, 145 / 255) -- dorado tostado, igual familia que TagText de MEM
local ROW_ACTIVE = Turbine.UI.Color(120 / 255, 185 / 255, 255 / 255)
local ROW_COMPLETED = Turbine.UI.Color(140 / 255, 230 / 255, 150 / 255)
local ROW_ACCENT = Turbine.UI.Color(255 / 255, 175 / 255, 70 / 255) -- filas de accion (Activar/Completar/Desmarcar)
local ROW_REWARD = Turbine.UI.Color(255 / 255, 205 / 255, 90 / 255)
-- Pedido explicito del usuario: nombre de mapa/zona y porcentaje
-- completado, cada uno con su propio color -- distintos entre si y de
-- ROW_TEXT (dorado, ya usado para nombres de mision/punto).
local ROW_AREA = Turbine.UI.Color(180 / 255, 205 / 255, 225 / 255) -- celeste-plateado, nombre de mapa/zona
local ROW_PERCENT = Turbine.UI.Color(120 / 255, 230 / 255, 210 / 255) -- turquesa, porcentaje completado

local function ApplyHeadingStyle(lbl)
    lbl:SetForeColor(LQA.UI.MEMBookStyle.Color.HeadingGray)
    lbl:SetOutlineColor(Turbine.UI.Color(10 / 255, 10 / 255, 10 / 255))
    lbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
end

-- Mismo mecanismo que ApplyHeadingStyle pero con el color que se le pase
-- (los ROW_* de arriba) -- para filas de lista, no encabezados.
local function ApplyReadableStyle(lbl, color)
    lbl:SetForeColor(color)
    lbl:SetOutlineColor(Turbine.UI.Color(8 / 255, 8 / 255, 8 / 255))
    lbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
end

local STRINGS = {
    ES = {
        no_active_quest = "Ninguna mision activa",
        go = "Ir", progress_prefix = "Progreso: ", active_state = "Activa", completed_state = "Completada",
        select_item = "Selecciona un elemento de la lista", activate = "Activar", complete = "Completar",
        reset = "Desmarcar", rewards_header = "Recompensas:", mission_objective = "Objetivo de la Mision:",
        points_header = "Puntos:", map_btn = "Mapa", route_btn = "Ruta", level_prefix = "Nivel: ",
        zone_prefix = "Zona: ", type_prefix = "Tipo: ", note_prefix = "Nota: ", destination_prefix = "Destino: ",
        point_fallback = "Punto ", no_zone = "Sin zona", lang_btn = "EN", unknown = "Desconocido",
        left_header_maps = "Mapas", left_header_titles = "Titulos", right_header_info = "Informacion",
        view_points = "Ver puntos", view_map = "Ver mapa",
        -- 2026-09-22: filtro de grupo + boton "Buscar grupo" (ver
        -- btnGroupFilter/btnLff en el Constructor).
        group_filter_off = "Grupo", group_filter_on = "Todas",
        group_filter_info = "Solo misiones de grupo", group_filter_empty = "Sin misiones de grupo aca",
        group_filter_count = " de grupo", lff_btn = "Buscar grupo",
    },
    EN = {
        no_active_quest = "No active quest",
        go = "Go", progress_prefix = "Progress: ", active_state = "Active", completed_state = "Completed",
        select_item = "Select an item from the list", activate = "Activate", complete = "Complete",
        reset = "Reset", rewards_header = "Rewards:", mission_objective = "Mission Objective:",
        points_header = "Points:", map_btn = "Map", route_btn = "Route", level_prefix = "Level: ",
        zone_prefix = "Zone: ", type_prefix = "Type: ", note_prefix = "Note: ", destination_prefix = "Destination: ",
        point_fallback = "Point ", no_zone = "No zone", lang_btn = "ES", unknown = "Unknown",
        left_header_maps = "Maps", left_header_titles = "Titles", right_header_info = "Information",
        view_points = "View points", view_map = "View map",
        group_filter_off = "Group", group_filter_on = "All",
        group_filter_info = "Group quests only", group_filter_empty = "No group quests here",
        group_filter_count = " group", lff_btn = "Find group",
    },
}

local function T(key)
    local lang = LanguageSettings.IsSpanish() and "ES" or "EN"
    return STRINGS[lang][key] or key
end

local function LocalizedText(esText, enText)
    if LanguageSettings.IsSpanish() then return esText or enText end
    return enText
end

local REWARD_NAMES = {
    VERTUES = "Experiencia de Virtud",
    TITLE = "Titulo",
    GRAINS = "Motas de encantamiento",
    BRAISES = "Brasas de encantamiento",
    TURBINE = "Puntos LOTRO",
    AMROTH_TOKEN = "Piezas de Plata de Amroth",
    CGONDOR_TOKEN = "Piezas de Plata de Gondor Central",
    EGONDOR_TOKEN = "Piezas de Plata de Gondor Este",
    FELEGOTH_TOKEN = "Fichas del Lago y los Rios",
    NITHILIEN_TOKEN = "Piezas de Plata de la Hueste del Oeste",
    MARQUE_DONATEUR = "Marcas de Donante",
    RELIQUE_ALLEGEANCE = "Reliquia de la Ultima Alianza",
    ROHAN_RIDER_REPUTATION_ITEM = "Talla de Madera Exquisita",
    ROHAN_RIDER_REPUTATION_ITEM2 = "Amuleto de Marmol Pulido",
}

local REWARD_NAMES_EN = {
    VERTUES = "Virtue Experience",
    TITLE = "Title",
    GRAINS = "Motes of enchantment",
    BRAISES = "Embers of enchantment",
    TURBINE = "Lotro Points",
    AMROTH_TOKEN = "Amroth Silver Pieces",
    CGONDOR_TOKEN = "Central Gondor Silver Pieces",
    EGONDOR_TOKEN = "East Gondor Silver Pieces",
    FELEGOTH_TOKEN = "Tokens of the Lake and Rivers",
    NITHILIEN_TOKEN = "Host of the West Silver Pieces",
    MARQUE_DONATEUR = "Gift-giver's Brands",
    RELIQUE_ALLEGEANCE = "Relique of the Last Alliance",
    ROHAN_RIDER_REPUTATION_ITEM = "Exquisite Wood-carving",
    ROHAN_RIDER_REPUTATION_ITEM2 = "Polished Marble Trinket",
}

local function StateColor(state)
    if state == "ACTIVE" then return Turbine.UI.Color.LightBlue end
    if state == "COMPLETED" then return Turbine.UI.Color(0, 1, 0) end
    return Turbine.UI.Color.Beige
end

-- Color de TEXTO de la fila en la lista (columna izquierda, siempre
-- negra) -- ver ROW_* arriba, se aplican con ApplyReadableStyle (contorno
-- incluido), no con SetForeColor a secas.
local function StateTextColor(state)
    if state == "ACTIVE" then return ROW_ACTIVE end
    if state == "COMPLETED" then return ROW_COMPLETED end
    return ROW_TEXT
end

local function DisplayName(entry)
    return LocalizedText(entry.nameES, entry.name)
end
local function DisplayZone(entry)
    return LocalizedText(entry.zoneES, entry.zone)
end

local function GetQuestDisplayName(ndx, quest)
    if LanguageSettings.IsSpanish() then
        return QuestLocResolver.GetQuestNameES(ndx, quest.nameEN)
    end
    return quest.nameEN
end

local function ParseWbCoord(c)
    local y, dirY, x, dirX = string.match(c, "([%d%.]+)%s*([NSns]),%s*([%d%.]+)%s*([EWew])")
    if not y then return nil end
    local cy = tonumber(y)
    local cx = tonumber(x)
    if dirY == "N" or dirY == "n" then cy = -cy end
    if dirX ~= "E" and dirX ~= "e" then cx = -cx end
    return cx, cy
end

local function CoordToPixel(c, bounds)
    if not bounds then return nil end
    local cx, cy = ParseWbCoord(c)
    if not cx then return nil end
    local pxPerX = math.abs(bounds.w - bounds.e) / MAP_W
    local pxPerY = math.abs(bounds.s - bounds.n) / MAP_H
    if pxPerX == 0 or pxPerY == 0 then return nil end
    local px = math.floor((cx - bounds.w) / pxPerX) - 8
    local py = math.floor((cy - bounds.n) / pxPerY) - 8
    if px < -4 then px = -4 end
    if px > MAP_W - 12 then px = MAP_W - 12 end
    if py < -4 then py = -4 end
    if py > MAP_H - 12 then py = MAP_H - 12 end
    return px, py
end

local function GetGroupsFor(entry)
    if entry.groups then return entry.groups end
    if entry.map then return { { map = entry.map, coords = entry.coords } } end
    return {}
end

function QuestSyncWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetPosition(100, 80)
    self:SetSize(WIDTH, HEIGHT)
    self:SetText("QuestSync")

    self.currentArea = "Archet"
    self.categoryIndex = 1
    self.activeTab = "misiones"
    self.collapsedAreas = {}
    self.collapsedZones = {}

    -- Fondo de panel real (624x508, tamaño nativo del .tga -- calcado de
    -- MEMMain.lua sobre este mismo book_menu.tga). HIJO de la ventana,
    -- nunca la ventana en si.
    self.pageBg = Turbine.UI.Control()
    self.pageBg:SetParent(self)
    self.pageBg:SetPosition(0, CHROME_TOP)
    self.pageBg:SetSize(PAGE_W, PAGE_H)
    self.pageBg:SetBackground(BOOK_RES .. "book_menu.tga")
    self.pageBg:SetMouseVisible(false)

    -- "Iluminacion" del anillo al pasar el mouse por CUALQUIER parte de la
    -- ventana (pedido explicito del usuario, ref. quest_journal_skin.png/
    -- ring_hover.png). NO se duplica el skin completo en 2 versiones: se
    -- superpone una capa aparte, chica (120x125, exactamente el recorte de
    -- RING_X/RING_Y de arriba), invisible por defecto -- el resto del
    -- libro (botones, texto, mecanismo de ventana) no se toca para nada.
    self.ringGlow = Turbine.UI.Control()
    self.ringGlow:SetParent(self.pageBg)
    self.ringGlow:SetPosition(RING_X, RING_Y)
    self.ringGlow:SetSize(RING_W, RING_H)
    self.ringGlow:SetBackground(BOOK_RES .. "ring_hover.tga")
    self.ringGlow:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.ringGlow:SetMouseVisible(false)
    self.ringGlow:SetVisible(false)

    -- Deteccion de hover con POLL de posicion real del mouse (Update),
    -- NO con MouseEnter/Leave de la ventana: los botones/lista/textbox de
    -- adentro tienen su propio SetMouseVisible(true), y en este SDK
    -- (calcado de WinForms, mismo problema documentado con
    -- Panel.MouseEnter) eso corta el Enter/Leave del padre cada vez que
    -- el mouse pasa por encima de un hijo -- el anillo parpadearia en vez
    -- de quedar prendido mientras el mouse siga dentro de la ventana.
    -- GetMousePosition() da la posicion real sin importar que control
    -- este debajo -- mismo metodo que ya usa el drag de self.MouseMove
    -- mas abajo. Mismo patron de "control fantasma con Update" que
    -- self.searchDebounceControl mas abajo.
    self.ringHoverPoll = Turbine.UI.Control()
    self.ringHoverPoll:SetParent(self.pageBg)
    self.ringHoverPoll:SetVisible(false)
    self.ringHoverPoll:SetWantsUpdates(true)
    self.ringHovering = false
    self.ringHoverPoll.Update = function()
        local mx, my = self:GetMousePosition()
        local over = mx >= 0 and mx < PAGE_W and my >= CHROME_TOP and my < HEIGHT
        if over ~= self.ringHovering then
            self.ringHovering = over
            self.ringGlow:SetVisible(over)
        end
    end

    -- Titulo (nombre de la categoria activa) -- mismo lugar/tamaño que el
    -- "Middle Earth Memoirs" de MEMMain.lua.
    self.lblCategory = Turbine.UI.Label()
    self.lblCategory:SetParent(self.pageBg)
    self.lblCategory:SetPosition(TITLE_X, TITLE_Y)
    self.lblCategory:SetSize(TITLE_W, 32)
    self.lblCategory:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold24)
    -- Dorado (no INK/gris, pedido explicito del usuario: "los titulos
    -- como tropas y amenazas... deben ser dorados") -- reusa
    -- MEMBookStyle.Color.TagText, el mismo dorado-tostado que ya usan las
    -- etiquetas de los botones "tag" de este addon, en vez de inventar un
    -- color nuevo. Es 1 solo Label compartido por las 4 pestañas
    -- (QuestSync/Puntos de Interes/Tropas y Amenazas/Colecciones).
    self.lblCategory:SetForeColor(LQA.UI.MEMBookStyle.Color.TagText)
    self.lblCategory:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.lblCategory:SetMouseVisible(false)
    self.lblCategory:SetSelectable(false)

    -- Flechas para pasar de categoria (QuestSync/Puntos de Interes/Tropas
    -- y Amenazas/Colecciones), flanqueando el titulo. Pedido explicito del
    -- usuario: estilo "tag" rojo/azul de MEM (tag_red.tga/tag_blue.tga) en
    -- vez de botones nativos -- PRIMER uso real en todo este addon de
    -- MEMBookStyle.CreateIconButton (definido hace tiempo pero nunca
    -- invocado hasta ahora). A diferencia de Mapa/Ruta/MoorMap/Waypoint,
    -- estas 2 flechas NO llevan Quickslot detras (solo cambian que
    -- categoria se ve, sin abrir mapas externos) -- el usuario confirmo
    -- explicitamente aplicar el estilo nuevo SOLO aca, dejando los botones
    -- con Quickslot real como Turbine.UI.Lotro.Button nativo (el unico
    -- mecanismo ya confirmado sin cierres para esos).
    -- Anterior=rojo (misma logica que "Restart" de MEM, volver atras),
    -- Siguiente=azul (misma logica que "Continue", avanzar). 68x24 en vez
    -- del tamaño nativo del asset (108x38) para que entre junto al titulo
    -- sin invadirlo -- se estira, pierde algo de detalle pero no rompe.
    self.btnPageLeft = LQA.UI.MEMBookStyle.CreateIconButton("tag_red", 68, 24, "<")
    self.btnPageLeft:SetParent(self.pageBg)
    self.btnPageLeft:SetPosition(ARROW_LEFT_X, ARROW_Y)
    self.btnPageLeft.ButtonClicked = function()
        if self.categoryIndex > 1 then
            self:SelectTab(TABS[self.categoryIndex - 1].key)
        end
    end

    self.btnPageRight = LQA.UI.MEMBookStyle.CreateIconButton("tag_blue", 68, 24, ">")
    self.btnPageRight:SetParent(self.pageBg)
    self.btnPageRight:SetPosition(ARROW_RIGHT_X, ARROW_Y)
    self.btnPageRight.ButtonClicked = function()
        if self.categoryIndex < #TABS then
            self:SelectTab(TABS[self.categoryIndex + 1].key)
        end
    end

    self.btnLanguage = Turbine.UI.Lotro.Button()
    self.btnLanguage:SetParent(self.pageBg)
    self.btnLanguage:SetPosition(LANG_BTN_X, LANG_BTN_Y)
    self.btnLanguage:SetSize(28, 22)
    self.btnLanguage:SetText(T("lang_btn"))
    self.btnLanguage.MouseClick = function()
        LanguageSettings.Toggle()
    end

    -- ===== Columna izquierda ("Mapas"/"Titulos") =====
    self.lblLeftHeader = Turbine.UI.Label()
    self.lblLeftHeader:SetParent(self.pageBg)
    self.lblLeftHeader:SetPosition(LEFT_X, LEFT_HEADER_Y)
    self.lblLeftHeader:SetSize(LEFT_W, 24)
    self.lblLeftHeader:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
    ApplyHeadingStyle(self.lblLeftHeader)
    self.lblLeftHeader:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.lblLeftHeader:SetMouseVisible(false)

    -- Buscador (solo visible en la categoria "QuestSync"): busca por
    -- NOMBRE (ES/EN) o por texto de OBJETIVO entre las 14.824 misiones.
    self.searchBox = Turbine.UI.Lotro.TextBox()
    self.searchBox:SetParent(self.pageBg)
    self.searchBox:SetPosition(LEFT_X, SEARCH_Y)
    -- 94 (antes 140): le hace lugar al boton de filtro de grupo de abajo,
    -- sin mover "Ver todas" (sigue en LEFT_X+146) ni nada mas de la fila.
    self.searchBox:SetSize(94, 20)
    self.searchBox:SetMultiline(false)

    -- Filtro "solo misiones de grupo" (2026-09-22, pedido explicito del
    -- usuario -- ver Core/GroupQuest.lua). Boton nativo chico en el hueco
    -- que libero el buscador: LEFT_X+98 .. LEFT_X+144, justo antes de "Ver
    -- todas" (LEFT_X+146). Sin Quickslot (solo cambia que filas se listan),
    -- mismo tipo de control que btnClearSearch/btnLanguage. Apagado por
    -- defecto: con el filtro apagado la lista es EXACTAMENTE la de antes.
    -- El texto dice lo que va a pasar al clickear ("Grupo" = mostrar solo
    -- las de grupo; "Todas" = volver a todas), y lblSearchInfo avisa cuando
    -- el filtro esta prendido.
    self.groupFilterOnly = false
    self.btnGroupFilter = Turbine.UI.Lotro.Button()
    self.btnGroupFilter:SetParent(self.pageBg)
    self.btnGroupFilter:SetPosition(LEFT_X + 98, SEARCH_Y - 1)
    self.btnGroupFilter:SetSize(46, 22)
    self.btnGroupFilter:SetText(T("group_filter_off"))
    self.btnGroupFilter.MouseClick = function()
        self.groupFilterOnly = not self.groupFilterOnly
        self.btnGroupFilter:SetText(T(self.groupFilterOnly and "group_filter_on" or "group_filter_off"))
        if self.searchResults then
            -- Rehace la busqueda: PerformSearch vuelve a poner el texto
            -- normal de resultados y PopulateSearchResults le suma el
            -- recuento "de grupo" si el filtro quedo prendido.
            self:PerformSearch(self.searchBox:GetText())
        else
            if not self.groupFilterOnly then
                self.lblSearchInfo:SetText("")
            end
            self:PopulateList()
        end
    end

    self.btnClearSearch = Turbine.UI.Lotro.Button()
    self.btnClearSearch:SetParent(self.pageBg)
    self.btnClearSearch:SetPosition(LEFT_X + 146, SEARCH_Y - 1)
    self.btnClearSearch:SetSize(72, 22)
    self.btnClearSearch:SetText("Ver todas")
    self.btnClearSearch:SetVisible(false)
    self.btnClearSearch.MouseClick = function()
        self.isolatedNdx = nil
        self.searchResults = nil
        self:ClearSearchBoxSilently()
        self.lblSearchInfo:SetText("")
        self:PopulateList()
        self:UpdateSearchControls()
    end

    self.lblSearchInfo = Turbine.UI.Label()
    self.lblSearchInfo:SetParent(self.pageBg)
    self.lblSearchInfo:SetPosition(LEFT_X, SEARCHINFO_Y)
    self.lblSearchInfo:SetSize(LEFT_W, 12)
    self.lblSearchInfo:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua12)
    ApplyReadableStyle(self.lblSearchInfo, ROW_TEXT)
    self.lblSearchInfo:SetText("")

    self.searchDebounceControl = Turbine.UI.Control()
    self.searchDebounceControl:SetParent(self.pageBg)
    self.searchDebounceControl:SetVisible(false)
    self.searchDebounceUntil = 0
    self.searchDebounceControl.Update = function()
        if Turbine.Engine.GetGameTime() >= self.searchDebounceUntil then
            self.searchDebounceControl:SetWantsUpdates(false)
            self:PerformSearch(self.searchBox:GetText())
        end
    end
    self.searchBox.TextChanged = function()
        if self.suppressSearchEvent then return end
        self.searchDebounceUntil = Turbine.Engine.GetGameTime() + 0.35
        self.searchDebounceControl:SetWantsUpdates(true)
    end

    self.listBox = Turbine.UI.ListBox()
    self.listBox:SetParent(self.pageBg)
    self.listBox:SetPosition(LEFT_X, LIST_Y)
    self.listBox:SetSize(LEFT_W, LIST_H)
    -- BUG CORREGIDO DE VUELTA (la correccion anterior -- alpha 0, "que se
    -- vea el pergamino de atras" -- resulto ser un bug PEOR: con fondo
    -- transparente de verdad, Turbine no revela el .tga del padre sino el
    -- MUNDO 3D detras de toda la ventana). Con book_menu.tga real medido
    -- pixel a pixel (alpha 255 en toda la columna izquierda -- OPACO,
    -- nunca transparente, confirmado con Pillow), lo correcto es un fondo
    -- OPACO que combine con la textura real de esa zona (negro casi puro,
    -- ~20,20,20).
    --
    -- BUG #2 CORREGIDO (visto en captura: la lista de puntos salio
    -- VIOLETA en vez de color pergamino): Turbine.UI.Color NO es
    -- (R,G,B,A) como en casi todos los frameworks -- es (A,R,G,B). Ver
    -- GatherCaptureButton.lua real: Color(0.9,0.13,0.11,0.07) para un
    -- panel de ALERTA ROJA casi transparente solo tiene sentido como
    -- (A=0.9?? no -- A=0.07 seria casi invisible, pero R=0.9 domina) --
    -- en realidad la evidencia mas clara es DropDown.lua real:
    -- Color(0.65,0,0,0) etiquetado "greyBox" y Color(0.9,0,0,0) etiquetado
    -- "ddListBack" -- un gris/negro semitransparente SOLO tiene sentido si
    -- el primer numero (0.65/0.9) es el ALPHA, no el rojo (si fuera rojo,
    -- estas cajas "grises" saldrian rojas). De ahi que TODO este codebase
    -- solo use (0,0,0,0) para transparente -- con A primero, el orden de
    -- R/G/B no importa cuando esta en 0. El primer intento de este boton
    -- (R,G,B,A) invertido puso el alpha real en el canal ROJO -- por eso
    -- salio semi-transparente Y con un tinte azul/violeta inesperado.
    self.listBox:SetBackColor(Turbine.UI.Color(1, 18 / 255, 18 / 255, 18 / 255))

    self.scrollBar = Turbine.UI.Lotro.ScrollBar()
    self.scrollBar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.scrollBar:SetParent(self.pageBg)
    self.scrollBar:SetPosition(LEFT_SCROLL_X, LIST_Y)
    self.scrollBar:SetSize(10, LIST_H)
    self.listBox:SetVerticalScrollBar(self.scrollBar)

    -- ===== Columna derecha ("Informacion") =====
    self.lblRightHeader = Turbine.UI.Label()
    self.lblRightHeader:SetParent(self.pageBg)
    -- X=260 (no RIGHT_X=279, pedido explicito del usuario: "el texto se
    -- debe mover un poco a la izquierda para que calse") -- el cartel
    -- decorativo real de "Informacion" no esta centrado en RIGHT_X/
    -- RIGHT_W (esa caja es del CONTENIDO, pensada para el pergamino
    -- entero) sino mas a la izquierda: medido pixel a pixel, el cartel va
    -- de x=273 a x=548, centro real x=410. Con el mismo ancho (300) que ya
    -- tenia, X=260 centra el texto en x=410 (260+150).
    self.lblRightHeader:SetPosition(260, RIGHT_HEADER_Y)
    self.lblRightHeader:SetSize(RIGHT_W, 25)
    self.lblRightHeader:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
    ApplyHeadingStyle(self.lblRightHeader)
    self.lblRightHeader:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.lblRightHeader:SetMouseVisible(false)
    self.lblRightHeader:SetText(T("right_header_info"))

    self.lblTitle = Turbine.UI.Label()
    self.lblTitle:SetParent(self.pageBg)
    self.lblTitle:SetPosition(RIGHT_X, RIGHT_TITLE_Y)
    self.lblTitle:SetSize(RIGHT_TITLE_W, RIGHT_TITLE_H)
    -- Bold24 (no 18, pedido explicito del usuario: "aumentar el tamaño de
    -- esos textos") -- ver RIGHT_TITLE_H mas arriba, agrandado a juego.
    self.lblTitle:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold24)
    self.lblTitle:SetForeColor(INK)
    self.lblTitle:SetMultiline(true)
    self.lblTitle:SetText(T("select_item"))

    self.lblDesc = Turbine.UI.Label()
    self.lblDesc:SetParent(self.pageBg)
    self.lblDesc:SetPosition(RIGHT_X, RIGHT_DESC_Y)
    self.lblDesc:SetSize(RIGHT_DESC_W, RIGHT_DESC_H)
    -- Antiqua18 (no 16, mismo pedido) -- ver RIGHT_DESC_H mas arriba.
    self.lblDesc:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua18)
    self.lblDesc:SetForeColor(INK_SECONDARY)
    self.lblDesc:SetMultiline(true)
    self.lblDesc:SetText("")

    self.mapImage = Turbine.UI.Label()
    self.mapImage:SetParent(self.pageBg)
    self.mapImage:SetPosition(RIGHT_X, RIGHT_CONTENT_Y)
    self.mapImage:SetSize(MAP_W, MAP_H)
    self.mapImage:SetMouseVisible(false)
    self.mapImage:SetVisible(false)
    self.mapMarkers = {}

    -- Botones Activar/Completar/Desmarcar -- pedido explicito del usuario
    -- ("los objetivos de las misiones no tiene botones"): vuelven a ser
    -- controles reales (como Mapa/Ruta), NO filas de texto dentro de la
    -- lista como habian quedado. Solo se muestran para misiones
    -- (self.selectedNdx), nunca para Puntos de Interes/Tropas.
    -- 4 en vez de 3 (2026-09-01, pedido explicito del usuario: boton
    -- "Narrar" tambien en la ventana principal, no solo en el Tracker) --
    -- se reparte el mismo ancho entre 4 botones en vez de agregar una fila
    -- nueva, para no correr RIGHT_POINTS_Y_NOMAP (constante fija derivada
    -- de RIGHT_ACTIONS_H, asumida en todo el resto del layout de abajo).
    -- V13 (2026-09-04, pedido explicito del usuario: integrar el set de
    -- botones nuevo -- arte a todo color con el texto ya quemado adentro).
    -- SIN Quickslot detras (a diferencia de Mapa/Ruta, ver nota grande de
    -- btnNarrar mas abajo) -- seguro cambiar el TIPO de control aca.
    --
    -- V14 (2026-09-04, confirmado en el juego con captura del usuario: los
    -- 4 botones se veian recortados/rotos -- solo un hilo de texto arriba,
    -- el resto negro). SetBackground en un Turbine.UI.Control NO reescala
    -- la imagen para llenar el control -- la dibuja a su resolucion REAL y
    -- recorta lo que sobra desde la esquina superior izquierda. Cada .tga
    -- se genera YA al tamaño real de uso -- ACTION_COL_W/ACTION_ROW_H
    -- tienen que coincidir EXACTO con el tamaño real del archivo, no son
    -- valores de layout libres para elegir sin regenerar el arte.
    --
    -- V15 (2026-09-04, grilla 2x2 en vez de 1 fila -- ver ACTION_COL_W/
    -- ACTION_ROW_H/ACTION_GAP mas arriba): Activar/Completar arriba,
    -- Desmarcar/Narrar abajo.
    self.btnMarkActive = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("activar", ACTION_COL_W, ACTION_ROW_H)
    self.btnMarkActive:SetParent(self.pageBg)
    self.btnMarkActive:SetPosition(RIGHT_X, RIGHT_ACTIONS_Y)
    self.btnMarkActive:SetVisible(false)
    self.btnMarkActive.MouseClick = function()
        if self.selectedNdx then
            QuestStateManager.SetQuestActive(self.selectedNdx)
            self:SelectQuest(self.selectedNdx)
        end
    end

    self.btnMarkCompleted = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("completar", ACTION_COL_W, ACTION_ROW_H)
    self.btnMarkCompleted:SetParent(self.pageBg)
    self.btnMarkCompleted:SetPosition(RIGHT_X + ACTION_COL_W + ACTION_GAP, RIGHT_ACTIONS_Y)
    self.btnMarkCompleted:SetVisible(false)
    self.btnMarkCompleted.MouseClick = function()
        if self.selectedNdx then
            QuestStateManager.SetQuestCompleted(self.selectedNdx)
            self:SelectQuest(self.selectedNdx)
        end
    end

    self.btnMarkReset = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("desmarcar", ACTION_COL_W, ACTION_ROW_H)
    self.btnMarkReset:SetParent(self.pageBg)
    self.btnMarkReset:SetPosition(RIGHT_X, RIGHT_ACTIONS_Y + ACTION_ROW_H + ACTION_GAP)
    self.btnMarkReset:SetVisible(false)
    self.btnMarkReset.MouseClick = function()
        if self.selectedNdx then
            QuestStateManager.ResetQuest(self.selectedNdx)
            self:SelectQuest(self.selectedNdx)
        end
    end

    -- Boton "Narrar" (2026-09-01, pedido explicito del usuario: el mismo
    -- boton del Tracker pero disponible para CUALQUIER mision del diario
    -- principal, no solo las activas). Mismo mecanismo que
    -- UI/QuestTrackerHUD.lua: NarratorBridge.PlayQuestText escribe el
    -- pedido para que Narrador_IA (app externa) lo narre.
    --
    -- 2026-09-02 (pedido explicito del usuario: "que haga sinergia visual a
    -- nuestro libros, que sea visualmente tematico"): en vez del
    -- Turbine.UI.Lotro.Button generico que comparte con Activar/Completar/
    -- Reiniciar, usa el estilo "tag" de pergamino. Seguro de usar aca
    -- porque este boton NO lleva Quickslot detras (a diferencia de Mapa/
    -- Ruta/MoorMap/Waypoint, que SI deben quedar en Turbine.UI.Lotro.Button
    -- nativo -- ver comentario de CreateIconButtonAlpha en MEMBookStyle.lua).
    --
    -- V13 (2026-09-04): tag_cyan generico + label "Narrar" superpuesto ->
    -- arte propio "narrar" (mismo set nuevo que Activar/Completar/
    -- Desmarcar, ver nota grande ahi arriba) con el texto ya quemado
    -- adentro.
    self.btnNarrar = LQA.UI.MEMBookStyle.CreateIconButtonAlpha("narrar", ACTION_COL_W, ACTION_ROW_H)
    self.btnNarrar:SetParent(self.pageBg)
    self.btnNarrar:SetPosition(RIGHT_X + ACTION_COL_W + ACTION_GAP, RIGHT_ACTIONS_Y + ACTION_ROW_H + ACTION_GAP)
    self.btnNarrar:SetVisible(false)
    self.btnNarrar.ButtonClicked = function()
        if self.selectedNdx then
            local quest = QuestDB.quests[self.selectedNdx]
            if quest then
                NarratorBridge.PlayQuestText(self.selectedNdx, quest, GetQuestDisplayName(self.selectedNdx, quest))
            end
        end
    end

    self.lblStagesHeader = Turbine.UI.Label()
    self.lblStagesHeader:SetParent(self.pageBg)
    self.lblStagesHeader:SetPosition(RIGHT_X, RIGHT_POINTS_Y_NOMAP)
    -- Alto 26/Bold18 (no 20/Bold14, pedido explicito del usuario:
    -- "aumentar el tamaño de esos textos") -- Bold+contorno necesita mas
    -- alto real que el que tenia esta caja con la fuente vieja.
    self.lblStagesHeader:SetSize(RIGHT_W - 92, 26)
    self.lblStagesHeader:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold18)
    ApplyHeadingStyle(self.lblStagesHeader)
    self.lblStagesHeader:SetVisible(false)

    -- Cartel de MISION DE GRUPO (2026-09-22, pedido explicito del usuario:
    -- "que en el mismo enunciado aparezca un logo de grupo y mencione que
    -- mazmorra o dungeon o raid hay que ir"). Vive en el hueco LIBRE que ya
    -- existia en el modo mision (SelectQuest siempre usa
    -- LayoutDetailForMode(false)): debajo del encabezado "Objetivo de la
    -- Mision:"/boton Mapa (RIGHT_POINTS_Y_NOMAP=319, 26-32px de alto ->
    -- terminan en ~348) y arriba de MoorMap/Waypoint (RIGHT_BTN_Y=427) --
    -- sigue dentro del pergamino real (llega a ~468, ver nota grande de
    -- RIGHT_BOTTOM_LIMIT). No mueve NINGUN control existente.
    -- Texto claro con contorno negro (ApplyReadableStyle, mismo mecanismo
    -- que el resto de las filas de este archivo) -- se lee igual sobre
    -- pergamino o madera sin depender del pixel exacto de fondo.
    -- Oculto por defecto; SOLO SelectQuest lo muestra, y solo si la mision
    -- esta en GroupQuestDB. SelectPoi/ClearDetailPanel lo vuelven a ocultar.
    local GROUP_BANNER_Y = RIGHT_POINTS_Y_NOMAP + 33 -- 352
    local GROUP_BANNER_H = RIGHT_BTN_Y - GROUP_BANNER_Y - 5 -- 70
    self.groupBanner = Turbine.UI.Control()
    self.groupBanner:SetParent(self.pageBg)
    self.groupBanner:SetPosition(RIGHT_X, GROUP_BANNER_Y)
    self.groupBanner:SetSize(RIGHT_W, GROUP_BANNER_H)
    self.groupBanner:SetMouseVisible(false)
    self.groupBanner:SetVisible(false)

    self.groupBannerIcon = Turbine.UI.Control()
    self.groupBannerIcon:SetParent(self.groupBanner)
    self.groupBannerIcon:SetPosition(0, 2)
    self.groupBannerIcon:SetSize(24, 24)
    self.groupBannerIcon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    if _G.GroupQuest then
        self.groupBannerIcon:SetBackground(GroupQuest.ICON_24)
    end
    self.groupBannerIcon:SetMouseVisible(false)

    self.lblGroupBanner = Turbine.UI.Label()
    self.lblGroupBanner:SetParent(self.groupBanner)
    self.lblGroupBanner:SetPosition(30, 0)
    self.lblGroupBanner:SetSize(RIGHT_W - 30, GROUP_BANNER_H)
    self.lblGroupBanner:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold14)
    self.lblGroupBanner:SetMultiline(true)
    self.lblGroupBanner:SetMouseVisible(false)
    if _G.GroupQuest then
        ApplyReadableStyle(self.lblGroupBanner, GroupQuest.Color.Dark)
    end

    -- Boton "Mapa" (2026-09-05, reemplaza la lista embebida con scrollbar
    -- -- pedido explicito del usuario: "al hacer scroll, corta/clipea
    -- parte del fondo de pergamino... quiero eliminar ese mecanismo por
    -- completo"). La lista vieja (self.pointsList) vivia DENTRO del
    -- pergamino con un fondo que era un RECORTE de pixeles fijo
    -- (points_bg.tga/points_bg_map.tga, ver historial abajo de
    -- LayoutDetailForMode) -- scrollear el CONTENIDO sin mover ese
    -- recorte dejaba un borde recto feo apenas la lista crecia. Este
    -- boton abre self.pointsPopup en vez de eso: una ventana aparte sin
    -- ningun fondo de pergamino, asi que no hay NADA que un scroll pueda
    -- cortar. Reusa el asset mapa.tga/_over.tga/_down.tga (generado en la
    -- misma tanda que activar/completar/desmarcar/narrar, nunca conectado
    -- hasta ahora) via MEMBookStyle.CreateIconButton -- mismo mecanismo
    -- de 3 estados que ya usan las flechas de categoria.
    -- 88x32 (no 72x26, pedido explicito del usuario: "aumentar el tamaño
    -- de esos textos y del boton Mapa") -- mismo asset reescalado con
    -- alfa premultiplicado (evita el halo oscuro documentado en
    -- CreateIconButtonAlpha) en vez de generar arte nuevo desde cero.
    self.btnShowPoints = LQA.UI.MEMBookStyle.CreateIconButton("mapa", 88, 32)
    self.btnShowPoints:SetParent(self.pageBg)
    self.btnShowPoints:SetVisible(false)
    self.btnShowPoints.ButtonClicked = function()
        self:TogglePointsPopup()
    end

    -- Ventana popup con la lista completa de puntos (Punto 1/2/3... +
    -- Mapa/Ruta de cada uno). Turbine.UI.Lotro.Window (chrome NATIVO), NO
    -- un Turbine.UI.Window a secas: los botones Mapa/Ruta de cada fila
    -- (AddDetailPointRow mas abajo) son Turbine.UI.Lotro.Button REALES
    -- con Quickslot detras -- exactamente la combinacion (boton nativo +
    -- ventana sin skin de Lotro) que ya causo 3 cierres reales del juego
    -- en este addon (ver la nota grande en QuestBookWindow.lua). Con
    -- chrome nativo esa combinacion nunca crasheo -- misma regla aca.
    --
    -- A proposito SIN fondo de pergamino (self.pointsList queda sin
    -- SetBackground/SetBackColor): al no haber ningun recorte de pixeles
    -- de por medio, no existe nada que el scroll pueda cortar/clipear --
    -- pedido explicito del usuario ("no debe recortar ni clipear el
    -- fondo de pergamino en ningun punto").
    --
    -- Se cierra con el boton Mapa de nuevo (toggle) o con la X nativa de
    -- su propio chrome. Cerrar con click AFUERA de la ventana (tambien
    -- pedido) NO esta implementado: la unica forma de detectarlo en este
    -- SDK es un control invisible a pantalla completa capturando clicks
    -- -- una superficie nueva y nunca probada en este addon, de la misma
    -- familia que causo los 3 cierres reales de arriba. Se prefirio no
    -- arriesgar estabilidad por esta interaccion secundaria.
    self.pointsPopup = Turbine.UI.Lotro.Window()
    self.pointsPopup:SetSize(POPUP_W, POPUP_H)
    self.pointsPopup:SetText(T("points_header"))
    self.pointsPopup:SetVisible(false)

    self.pointsList = Turbine.UI.ListBox()
    self.pointsList:SetParent(self.pointsPopup)
    self.pointsList:SetPosition(8, 30)
    self.pointsList:SetSize(POPUP_W - 34, POPUP_H - 38)
    self.pointsRowCount = 0

    self.pointsPopupScroll = Turbine.UI.Lotro.ScrollBar()
    self.pointsPopupScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.pointsPopupScroll:SetParent(self.pointsPopup)
    self.pointsPopupScroll:SetPosition(POPUP_W - 22, 30)
    self.pointsPopupScroll:SetSize(10, POPUP_H - 38)
    self.pointsList:SetVerticalScrollBar(self.pointsPopupScroll)

    -- Botones generales (Mapa/Ruta): apuntan al primer lugar conocido
    -- (mision O punto). Turbine.UI.Lotro.Button nativo con Quickslot real
    -- detras (ver nota grande arriba).
    self.btnMap = Turbine.UI.Lotro.Button()
    self.btnMap:SetParent(self.pageBg)
    self.btnMap:SetPosition(RIGHT_X, RIGHT_BTN_Y)
    -- Alto 32 (no 26, pedido explicito del usuario -- ver la nota grande
    -- junto a RIGHT_BTN_Y): boton nativo, se reescala solo sin regenerar
    -- arte (a diferencia de los iconos custom de MEMBookStyle).
    self.btnMap:SetSize(90, 32)
    self.btnMap:SetText("MoorMap")

    self.btnWay = Turbine.UI.Lotro.Button()
    self.btnWay:SetParent(self.pageBg)
    self.btnWay:SetPosition(RIGHT_X + 96, RIGHT_BTN_Y)
    self.btnWay:SetSize(90, 32)
    self.btnWay:SetText("Waypoint")

    if MoorMapAdapter then
        self.moorMapQuickslot = MoorMapAdapter.CreateQuickslot()
        MoorMapAdapter.AttachToButton(self.moorMapQuickslot, self.btnMap)
    end
    if WaypointAdapter then
        self.waypointQuickslot = WaypointAdapter.CreateQuickslot()
        MoorMapAdapter.AttachToButton(self.waypointQuickslot, self.btnWay)
    end

    -- Boton "Buscar grupo" (2026-09-22, pedido explicito del usuario: "un
    -- boton que no rompa la estructura del juego y la visual... que mande
    -- el mensaje automatico en ingles... en el chat de mundo"). MISMA fila,
    -- MISMO tipo de control y MISMO mecanismo que MoorMap/Waypoint: boton
    -- nativo Turbine.UI.Lotro.Button + Quickslot propio detras (Alias con
    -- el comando de chat, ver GroupQuest.LffCommand) -- nada nuevo sin
    -- probar. En el hueco libre a la derecha de Waypoint: RIGHT_X+192 ..
    -- RIGHT_X+292 (Waypoint termina en RIGHT_X+186), dentro del pergamino.
    -- SOLO visible para misiones de grupo (SelectQuest); el mensaje sale
    -- UNICAMENTE cuando el jugador hace click, nunca solo.
    self.btnLff = Turbine.UI.Lotro.Button()
    self.btnLff:SetParent(self.pageBg)
    self.btnLff:SetPosition(RIGHT_X + 192, RIGHT_BTN_Y)
    self.btnLff:SetSize(100, 32)
    self.btnLff:SetText(T("lff_btn"))
    self.btnLff:SetVisible(false)
    if MoorMapAdapter then
        self.lffQuickslot = MoorMapAdapter.CreateQuickslot()
        MoorMapAdapter.AttachToButton(self.lffQuickslot, self.btnLff)
    end

    self:SelectTab("misiones")
    self:UpdateActiveSummary()

    self.draggingWindow = false
    self.MouseDown = function(sender, args)
        if self:IsAltKeyDown() then
            self.draggingWindow = true
            self.dragX, self.dragY = self:GetMousePosition()
        end
    end
    self.MouseUp = function(sender, args)
        self.draggingWindow = false
    end
    self.MouseMove = function(sender, args)
        if self.draggingWindow then
            local px, py = self:GetPosition()
            local mx, my = self:GetMousePosition()
            self:SetPosition(px + mx - self.dragX, py + my - self.dragY)
        end
    end

    local function OnQuestEvent(data)
        if data and data.ndx and QuestDB.quests[data.ndx] then
            local q = QuestDB.quests[data.ndx]
            local newArea = (q.area and q.area ~= "" and q.area) or q.zone
            if newArea then
                self.currentArea = newArea
            end
        end
        if self:IsVisible() then
            self:PopulateList()
        else
            self.pendingRepopulate = true
        end
        self:UpdateActiveSummary()
    end
    LQA.Core.EventBus:Subscribe("QUEST_STATE_CHANGED", OnQuestEvent)
    LQA.Core.EventBus:Subscribe("QUEST_PROGRESS", OnQuestEvent)
    LQA.Core.EventBus:Subscribe("QUEST_TRACKED", OnQuestEvent)

    -- SFX de "abrir ventana" RETIRADO (pedido explicito del usuario,
    -- 2026-09-03) -- ver la nota grande en NarratorBridge.lua.
    self.VisibleChanged = function()
        if self:IsVisible() and self.pendingRepopulate then
            self.pendingRepopulate = false
            self:PopulateList()
        end
        -- Si se cierra la ventana principal, el popup de puntos no puede
        -- quedar huerfano flotando solo en pantalla.
        if not self:IsVisible() then
            self.pointsPopup:SetVisible(false)
        end
    end

    LQA.Core.EventBus:Subscribe("LANGUAGE_CHANGED", function()
        self:RefreshLanguage()
    end)

    -- (2026-10-01) efectos: el anillo arde como el del Tracker y el titulo
    -- grande tiene estrellas que titilan (solo imagen, sin mouse; ver
    -- UI/RingFireFX.lua). En pcall: si fallara, la ventana sigue igual.
    if LQA.UI.RingFireFX ~= nil then
        pcall(LQA.UI.RingFireFX.AttachRing, self, self.pageBg, {
            prefix = "questsync_fx_", x = 504, y = 353, w = 120, h = 155,
            rim = {
                { 545, 463 }, { 551, 455 }, { 557, 449 }, { 563, 444 }, { 569, 440 }, { 575, 437 }, { 581, 434 },
                { 587, 432 }, { 593, 431 }, { 599, 431 }, { 605, 431 }, { 611, 433 }, { 617, 436 },
            },
        })
        pcall(LQA.UI.RingFireFX.AttachTitleStars, self, self.pageBg, self.lblTitle, function()
            return self.selectedNdx ~= nil or self.selectedPoi ~= nil
        end)
    end
end

function QuestSyncWindow:RefreshLanguage()
    self.btnLanguage:SetText(T("lang_btn"))
    self.btnGroupFilter:SetText(T(self.groupFilterOnly and "group_filter_on" or "group_filter_off"))
    self.btnLff:SetText(T("lff_btn"))
    self:UpdateCategoryChrome()
    self.lblRightHeader:SetText(T("right_header_info"))

    self:PopulateList()
    self:ClearDetailPanel()
    self:UpdateActiveSummary()
end

-- Titulo + encabezado de columna izquierda + estado de las flechas, segun
-- self.categoryIndex.
function QuestSyncWindow:UpdateCategoryChrome()
    local tab = TABS[self.categoryIndex]
    self.lblCategory:SetText(LanguageSettings.IsSpanish() and tab.label or tab.labelEN)
    self.lblLeftHeader:SetText(T(tab.leftHeader))
    self.btnPageLeft:SetVisible(self.categoryIndex > 1)
    self.btnPageRight:SetVisible(self.categoryIndex < #TABS)
end

-- Banda de mision activa/rastreada (nombre+progreso+boton "Ir") ELIMINADA
-- (pedido explicito del usuario, 2026-09-05: "no deberia mostrarse ahi" /
-- "no hace falta ahi") -- flotaba sobre la madera debajo del cartel
-- "QuestSync" y el boton "Ir" se superponia con su propia etiqueta de
-- atajo. Se deja el metodo como no-op en vez de borrarlo y tocar los 4
-- call sites (OnQuestEvent, RefreshLanguage, Constructor, SelectQuest).
function QuestSyncWindow:UpdateActiveSummary()
end

-- Fila de sub-grupo desplegable "+ Etiqueta {N}" -- pedido explicito del
-- usuario ("el nombre de los mapas de otro color que se diferencie de las
-- misiones... el porcentaje completado se puede poner de otro color"):
-- el nombre (ROW_AREA, celeste-plateado -- distinto del dorado que ya usan
-- las misiones/puntos, ROW_TEXT) y el porcentaje (ROW_PERCENT, turquesa)
-- ahora son 2 Labels separados con color propio, no 1 solo string con 1
-- solo color. pctText es OPCIONAL (Puntos de Interes/Tropas agrupan por
-- zona sin porcentaje) -- cuando no viene, hLbl ocupa el ancho completo
-- como antes. El porcentaje se ancla a la DERECHA de la fila (ancho fijo,
-- 50px) en vez de "pegado" despues del nombre -- este SDK no tiene forma
-- confirmada de medir cuanto ancho ocupa el texto ya dibujado de otro
-- Label para saber donde arrancar el segundo, asi que anclarlo a la
-- derecha es la unica posicion que se puede calcular sin adivinar.
-- Icono real de MEM para expandir/contraer -- pedido del usuario al
-- preguntar por TreeView-branch-open/closed (esos son del tema CEF
-- azul/plateado del launcher, no sirven aca -- ver conversacion). En vez
-- de esos, se usa tree_group_open.tga/tree_group_closed.tga: el MISMO
-- asset real que MEMCommon/MEMTreeGroup.lua usa para esto, ya copiado a
-- Resources/Book/, 218x27 -- calza EXACTO con LEFT_W (218). Se usa solo
-- la IMAGEN de fondo (SetBackground), no el widget TreeView/TreeNode de
-- MEM (Turbine.UI.TreeView nunca se probo en este addon, se evita a
-- proposito -- mismo criterio de toda la sesion). Reemplaza el prefijo de
-- texto "+ "/"- " -- el icono ya muestra el estado.
function QuestSyncWindow:AddZoneHeader(key, label, count, collapseMap, pctText)
    collapseMap = collapseMap or self.collapsedZones
    local collapsed = collapseMap[key]
    if collapsed == nil then collapsed = true end

    local header = Turbine.UI.Control()
    header:SetSize(LEFT_W, 27)
    header:SetBlendMode(Turbine.UI.BlendMode.Overlay)
    header:SetBackground(BOOK_RES .. (collapsed and "tree_group_closed.tga" or "tree_group_open.tga"))

    local nameW = pctText and (LEFT_W - 30 - 50) or (LEFT_W - 30)
    local hLbl = Turbine.UI.Label()
    hLbl:SetParent(header)
    hLbl:SetPosition(30, 1)
    hLbl:SetSize(nameW, 25)
    hLbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua16)
    ApplyReadableStyle(hLbl, ROW_AREA)
    hLbl:SetText(label .. "  {" .. count .. "}")

    local hPct
    if pctText then
        hPct = Turbine.UI.Label()
        hPct:SetParent(header)
        hPct:SetPosition(LEFT_W - 50, 1)
        hPct:SetSize(50, 25)
        hPct:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold14)
        hPct:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        ApplyReadableStyle(hPct, ROW_PERCENT)
        hPct:SetText(pctText)
    end

    header.MouseClick = function()
        collapseMap[key] = not collapsed
        self:PopulateList()
    end
    hLbl.MouseClick = header.MouseClick
    if hPct then hPct.MouseClick = header.MouseClick end

    self.listBox:AddItem(header)
    return not collapsed
end

function QuestSyncWindow:AddPoiRow(entry, icon)
    local item = Turbine.UI.Control()
    item:SetSize(LEFT_W, 42)

    local iconLbl = Turbine.UI.Label()
    iconLbl:SetParent(item)
    iconLbl:SetPosition(22, 12)
    iconLbl:SetSize(16, 16)
    if icon then iconLbl:SetBackground(icon) end
    iconLbl:SetMouseVisible(false)

    local lbl = Turbine.UI.Label()
    lbl:SetParent(item)
    lbl:SetPosition(42, 0)
    lbl:SetSize(LEFT_W - 42, 42)
    lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua16)
    lbl:SetMultiline(true)
    ApplyReadableStyle(lbl, ROW_TEXT)
    local levelTag = entry.level and ("[" .. tostring(entry.level) .. "] ") or ""
    lbl:SetText(levelTag .. tostring(DisplayName(entry)))

    item.MouseClick = function()
        self:SelectPoi(entry, icon)
    end
    lbl.MouseClick = item.MouseClick
    iconLbl.MouseClick = item.MouseClick

    self.listBox:AddItem(item)
end

function QuestSyncWindow:AddQuestListRow(ndx, quest, displayNameOverride)
    local state = QuestStateManager.GetQuestState(ndx)
    local esName = displayNameOverride or GetQuestDisplayName(ndx, quest)

    if quest.level then
        esName = esName .. " [" .. tostring(quest.level) .. "]"
    end

    -- Etiqueta Diaria/Semanal/Quincenal (2026-09-22, ver Core/QuestTags.lua
    -- -- dato oficial de Data/QuestLockDB.lua). No se agrega si el nombre
    -- ya lo dice (muchos traen "(Daily)"/"(Diaria)" en el propio nombre).
    local lockText = _G.QuestTags and QuestTags.LockText(quest)
    if lockText and not QuestTags.NameAlreadyTagged(esName) then
        esName = esName .. " · " .. lockText
    end

    local item = Turbine.UI.Control()
    item:SetSize(LEFT_W, 58)

    local badge = Turbine.UI.Control()
    badge:SetParent(item)
    badge:SetPosition(22, 16)
    badge:SetSize(8, 8)
    badge:SetBackColor(StateColor(state))

    -- Franja verde fina a la izquierda = mision apropiada para el nivel
    -- actual del personaje (2026-09-22, ver QuestTags.IsLevelAppropriate).
    -- x=0..2, antes del logo de grupo (x=3) y del badge (x=22): no se pisa
    -- con nada. self.playerLevel se lee una vez por PopulateList; si es nil
    -- (no se pudo leer el nivel) no se dibuja nada, fila igual que antes.
    if _G.QuestTags and QuestTags.IsLevelAppropriate(quest, self.playerLevel) then
        local levelBar = Turbine.UI.Control()
        levelBar:SetParent(item)
        levelBar:SetPosition(0, 4)
        levelBar:SetSize(3, 50)
        levelBar:SetBackColor(QuestTags.LevelColor)
        levelBar:SetMouseVisible(false)
    end

    -- Misiones de GRUPO (2026-09-22, pedido explicito del usuario -- ver
    -- Core/GroupQuest.lua): el TEXTO toma el color de grupo (naranja fuego)
    -- en vez del color de estado, y se agrega el logo de grupo a la
    -- izquierda. El ESTADO (disponible/activa/completada) se sigue viendo
    -- igual que siempre en la insignia chica (badge) -- no se pierde ese
    -- dato, solo cambia quien pinta el texto. Si la mision no es de grupo,
    -- groupEntry es nil y la fila queda EXACTAMENTE como antes.
    local groupEntry = _G.GroupQuest and GroupQuest.Get(quest)

    local lbl = Turbine.UI.Label()
    lbl:SetParent(item)
    lbl:SetPosition(36, 0)
    lbl:SetSize(LEFT_W - 36, 58)
    lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua16)
    lbl:SetMultiline(true)
    lbl:SetText(esName)
    ApplyReadableStyle(lbl, groupEntry and GroupQuest.Color.Dark or StateTextColor(state))

    item.MouseClick = function(sender, args)
        self:SelectQuest(ndx)
    end
    lbl.MouseClick = item.MouseClick
    badge.MouseClick = item.MouseClick

    if groupEntry then
        -- 16x16 = tamaño REAL del archivo (SetBackground no reescala, ver
        -- la nota grande de CreateIconButtonAlpha en MEMBookStyle.lua) +
        -- AlphaBlend para respetar el borde redondo transparente. Centrado
        -- en la misma altura que el badge (y=16..24 -> centro 20).
        local groupIcon = Turbine.UI.Control()
        groupIcon:SetParent(item)
        groupIcon:SetPosition(3, 12)
        groupIcon:SetSize(16, 16)
        groupIcon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        groupIcon:SetBackground(GroupQuest.ICON_16)
        groupIcon.MouseClick = item.MouseClick
    end

    lbl.MouseHover = function()
        QuestInfoTooltip.GetInstance():ShowFor(ndx, quest, esName)
    end
    lbl.MouseLeave = function()
        QuestInfoTooltip.GetInstance():Hide()
    end

    self.listBox:AddItem(item)
end

function QuestSyncWindow:PopulateMisionesTab()
    if self.isolatedNdx then
        self:PopulateIsolatedQuest(self.isolatedNdx)
        return
    end
    if self.searchResults then
        self:PopulateSearchResults(self.searchResults)
        return
    end

    local areaSet = {}
    local areaOrder = {}
    local function noteArea(a)
        if a and a ~= "" and not areaSet[a] then
            areaSet[a] = true
            table.insert(areaOrder, a)
        end
    end
    for ndx, quest in pairs(QuestDB.quests) do
        local state = QuestStateManager.GetQuestState(ndx)
        if state == "ACTIVE" or state == "COMPLETED" then
            noteArea((quest.area and quest.area ~= "" and quest.area) or quest.zone)
        end
    end
    noteArea(self.currentArea)
    table.sort(areaOrder)

    -- Filtro de grupo (ver btnGroupFilter en el Constructor): con el filtro
    -- prendido solo entran las misiones de GroupQuestDB, y las areas que no
    -- tienen ninguna se saltan enteras. Con el filtro apagado,
    -- onlyGroup=false y este bucle es exactamente el de antes.
    local onlyGroup = self.groupFilterOnly and _G.GroupQuest ~= nil
    local anyShown = false

    for _, area in ipairs(areaOrder) do
        local cArea = string.lower(area)
        local entries = {}
        local nameCounts = {}
        local totalInArea, completedInArea = 0, 0
        for ndx, quest in pairs(QuestDB.quests) do
            local qArea = string.lower(quest.area or "")
            if qArea ~= "" and qArea == cArea and (not onlyGroup or GroupQuest.IsGroup(quest)) then
                local esName = GetQuestDisplayName(ndx, quest)
                table.insert(entries, { ndx = ndx, quest = quest, esName = esName })
                nameCounts[esName] = (nameCounts[esName] or 0) + 1
                totalInArea = totalInArea + 1
                if QuestStateManager.GetQuestState(ndx) == "COMPLETED" then completedInArea = completedInArea + 1 end
            end
        end
        table.sort(entries, function(a, b) return a.ndx < b.ndx end)
        local pct = totalInArea > 0 and math.floor((completedInArea / totalInArea) * 100) or 0

        if self.collapsedAreas[area] == nil then
            self.collapsedAreas[area] = (area ~= self.currentArea)
        end

        local areaOpen = false
        if not onlyGroup or totalInArea > 0 then
            anyShown = true
            areaOpen = self:AddZoneHeader(area, area, totalInArea, self.collapsedAreas, pct .. "%")
        end
        if areaOpen then
            local nameSeen = {}
            for _, entry in ipairs(entries) do
                local ndx, quest, esName = entry.ndx, entry.quest, entry.esName

                local displayName = esName
                if nameCounts[esName] > 1 then
                    nameSeen[esName] = (nameSeen[esName] or 0) + 1
                    displayName = esName .. " (" .. nameSeen[esName] .. "/" .. nameCounts[esName] .. ")"
                end

                self:AddQuestListRow(ndx, quest, displayName)
            end
        end
    end

    if onlyGroup then
        self.lblSearchInfo:SetText(T(anyShown and "group_filter_info" or "group_filter_empty"))
    end
end

function QuestSyncWindow:PopulateList()
    self.listBox:ClearItems()
    -- Nivel del personaje UNA vez por repoblado (ver AddQuestListRow,
    -- franja verde de "tu nivel"); nil si no se pudo leer -> no marca nada.
    self.playerLevel = _G.QuestTags and QuestTags.GetPlayerLevel() or nil
    if self.activeTab == "misiones" then
        self:PopulateMisionesTab()
        return
    end
    for _, tab in ipairs(TABS) do
        if tab.key == self.activeTab and tab.db then
            local db = _G[tab.db]
            if db then
                self:PopulatePoiZones(db, tab.icon, tab.resolveIcon)
            end
            return
        end
    end
end

function QuestSyncWindow:PopulatePoiZones(db, icon, resolveIcon)
    local byZone = {}
    local zoneOrder = {}
    for _, e in ipairs(db) do
        local zone = (e.zone and e.zone ~= "") and e.zone or "__NO_ZONE__"
        if not byZone[zone] then
            byZone[zone] = {}
            table.insert(zoneOrder, zone)
        end
        table.insert(byZone[zone], e)
    end
    table.sort(zoneOrder)

    for _, zone in ipairs(zoneOrder) do
        local zoneEntries = byZone[zone]
        table.sort(zoneEntries, function(a, b)
            local la, lb = tonumber(a.level) or 0, tonumber(b.level) or 0
            if la ~= lb then return la < lb end
            return DisplayName(a) < DisplayName(b)
        end)

        local zoneLabel = (zone ~= "__NO_ZONE__" and zoneEntries[1] and DisplayZone(zoneEntries[1])) or nil
        if not zoneLabel or zoneLabel == "" then
            zoneLabel = (zone == "__NO_ZONE__") and T("no_zone") or zone
        end
        local zoneOpen = self:AddZoneHeader(zone, zoneLabel, #zoneEntries)
        if zoneOpen then
            for _, entry in ipairs(zoneEntries) do
                local rowIcon = resolveIcon and resolveIcon(entry) or icon
                self:AddPoiRow(entry, rowIcon)
            end
        end
    end
end

function QuestSyncWindow:ClearMapMarkers()
    for _, marker in ipairs(self.mapMarkers) do
        marker:SetParent(nil)
    end
    self.mapMarkers = {}
end

-- Titulo/descripcion quedan SIEMPRE en la misma posicion fija, dentro del
-- pergamino real (ver la nota grande junto a RIGHT_BOTTOM_LIMIT) -- eso ya
-- no cambia entre mision y punto de interes, asi que aca solo se
-- reposiciona lo que SI cambia: el mapa (misiones no tienen mapa interno
-- de WarbandsSlayer, asi que el encabezado "Objetivo de la Mision"/boton
-- Mapa suben a ocupar ese espacio; puntos de interes/amenazas si lo usan,
-- a tamaño completo 300x200, y el encabezado/boton bajan debajo).
--
-- 2026-09-05 (pedido explicito del usuario, ver la nota grande junto a
-- self.pointsPopup en el Constructor): ya NO hay boton "Ver puntos"/"Ver
-- mapa" ni lista embebida que alternar -- el mapa (si existe) se muestra
-- SIEMPRE, y el detalle completo de puntos vive en self.pointsPopup,
-- abierto con self.btnShowPoints. Su visibilidad real la decide
-- QuestSyncWindow:UpdatePointsButtonVisibility() DESPUES de poblar
-- self.pointsList (SelectQuest/SelectPoi) -- aca solo se arrancan
-- ocultos y se los posiciona, para no mostrar contenido de la seleccion
-- anterior mientras se arma la nueva.
function QuestSyncWindow:LayoutDetailForMode(hasMap)
    self.currentHasMap = hasMap
    self.mapImage:SetVisible(hasMap)
    self.lblStagesHeader:SetVisible(false)
    self.btnShowPoints:SetVisible(false)

    local headerY = hasMap and RIGHT_POINTS_Y_MAP or RIGHT_POINTS_Y_NOMAP
    self.lblStagesHeader:SetPosition(RIGHT_X, headerY)
    self.btnShowPoints:SetPosition(RIGHT_X + RIGHT_W - 88, headerY - 3)
end

-- Boton Mapa/encabezado "Objetivo de la Mision:"/"Puntos:" solo aparecen
-- si de verdad hay algo para mostrar en el popup -- self.pointsRowCount
-- lo incrementan AddDetailPointRow/AddRewardRow/AddDetailSeparatorRow, se
-- resetea a 0 en cada self.pointsList:ClearItems() (SelectQuest/SelectPoi/
-- ClearDetailPanel). Llamar DESPUES de terminar de poblar la seleccion.
function QuestSyncWindow:UpdatePointsButtonVisibility()
    local hasContent = self.pointsRowCount > 0
    self.lblStagesHeader:SetVisible(hasContent)
    self.btnShowPoints:SetVisible(hasContent)
    if not hasContent then
        self.pointsPopup:SetVisible(false)
    end
end

-- Abre/cierra self.pointsPopup (boton "Mapa"). Se reposiciona cada vez
-- que se abre, pegado al costado derecho de la ventana principal --
-- sigue a self por si el usuario la arrastro desde la ultima vez.
function QuestSyncWindow:TogglePointsPopup()
    if self.pointsPopup:IsVisible() then
        self.pointsPopup:SetVisible(false)
        return
    end
    local wx, wy = self:GetPosition()
    self.pointsPopup:SetPosition(wx + WIDTH + 6, wy + CHROME_TOP)
    self.pointsPopup:SetVisible(true)
end

-- Cambia de categoria (ver TABS/self.categoryIndex). Repuebla la lista y
-- limpia el panel de detalle.
function QuestSyncWindow:SelectTab(key)
    -- SFX de "cambio de pestaña" RETIRADO (pedido explicito del usuario,
    -- 2026-09-03) -- ver la nota grande en NarratorBridge.lua.
    for i, tab in ipairs(TABS) do
        if tab.key == key then self.categoryIndex = i end
    end
    self.activeTab = key
    self:UpdateCategoryChrome()
    self:PopulateList()
    self:ClearDetailPanel()
    self:UpdateSearchControls()
end

function QuestSyncWindow:ClearSearchBoxSilently()
    self.suppressSearchEvent = true
    self.searchBox:SetText("")
    self.suppressSearchEvent = false
end

function QuestSyncWindow:UpdateSearchControls()
    local onTab = self.activeTab == "misiones"
    self.searchBox:SetVisible(onTab)
    self.btnGroupFilter:SetVisible(onTab)
    self.lblSearchInfo:SetVisible(onTab)
    local filtered = self.isolatedNdx ~= nil or self.searchResults ~= nil
    self.btnClearSearch:SetVisible(onTab and filtered)
end

function QuestSyncWindow:PerformSearch(queryRaw)
    self.isolatedNdx = nil
    if not queryRaw or queryRaw == "" then
        self.searchResults = nil
        self.lblSearchInfo:SetText("")
        self:PopulateList()
        self:UpdateSearchControls()
        return
    end

    local q = QuestLocResolver.NormalizeES(queryRaw)
    local seen, matched = {}, {}
    for ndx, quest in pairs(QuestDB.quests) do
        local esName = QuestLocResolver.NormalizeES(GetQuestDisplayName(ndx, quest))
        local enName = QuestLocResolver.NormalizeES(quest.nameEN or "")
        if (esName ~= "" and string.find(esName, q, 1, true))
            or (enName ~= "" and string.find(enName, q, 1, true)) then
            if not seen[ndx] then seen[ndx] = true; table.insert(matched, ndx) end
        end
    end

    if _G.QuestObjectiveESIndex then
        for key, ndxs in pairs(_G.QuestObjectiveESIndex) do
            if string.find(key, q, 1, true) then
                local list = type(ndxs) == "table" and ndxs or { ndxs }
                for _, ndx in ipairs(list) do
                    if not seen[ndx] then seen[ndx] = true; table.insert(matched, ndx) end
                end
            end
        end
    end

    table.sort(matched)

    local TRUNCATE_AT = 200
    local totalFound = #matched
    if totalFound > TRUNCATE_AT then
        local trimmed = {}
        for i = 1, TRUNCATE_AT do trimmed[i] = matched[i] end
        matched = trimmed
    end

    self.searchResults = matched
    if totalFound == 0 then
        self.lblSearchInfo:SetText("Sin resultados")
    elseif totalFound > TRUNCATE_AT then
        self.lblSearchInfo:SetText(totalFound .. " (mostrando " .. TRUNCATE_AT .. ")")
    else
        self.lblSearchInfo:SetText(totalFound .. " resultado(s)")
    end

    self:PopulateList()
    self:UpdateSearchControls()
end

function QuestSyncWindow:PopulateSearchResults(list)
    -- Filtro de grupo (ver btnGroupFilter): con el filtro apagado este
    -- bucle es exactamente el de antes.
    local onlyGroup = self.groupFilterOnly and _G.GroupQuest ~= nil
    local shown = 0
    for _, ndx in ipairs(list) do
        local quest = QuestDB.quests[ndx]
        if quest and (not onlyGroup or GroupQuest.IsGroup(quest)) then
            local esName = GetQuestDisplayName(ndx, quest)
            local area = (quest.area and quest.area ~= "" and quest.area) or quest.zone or ""
            local label = (area ~= "") and (esName .. "  [" .. area .. "]") or esName
            self:AddQuestListRow(ndx, quest, label)
            shown = shown + 1
        end
    end
    if onlyGroup then
        self.lblSearchInfo:SetText(tostring(shown) .. T("group_filter_count"))
    end
end

function QuestSyncWindow:PopulateIsolatedQuest(ndx)
    local quest = QuestDB.quests[ndx]
    if not quest then
        self.isolatedNdx = nil
        self:PopulateMisionesTab()
        return
    end
    self:AddQuestListRow(ndx, quest)
end

function QuestSyncWindow:FocusQuest(ndx)
    self.searchResults = nil
    self.isolatedNdx = ndx
    self:ClearSearchBoxSilently()
    self.lblSearchInfo:SetText("")
    self:SelectTab("misiones")
    self:SelectQuest(ndx)
end

function QuestSyncWindow:ClearDetailPanel()
    self.selectedNdx = nil
    self.selectedPoi = nil
    self.lblTitle:SetText(T("select_item"))
    self.lblTitle:SetForeColor(INK)
    self.groupBanner:SetVisible(false)
    self.btnLff:SetVisible(false)
    self.lblDesc:SetText("")
    self:ClearMapMarkers()
    self.pointsList:ClearItems()
    self.pointsRowCount = 0
    self.pointsPopup:SetVisible(false)
    self.lblStagesHeader:SetVisible(false)
    self.btnShowPoints:SetVisible(false)
    self.mapImage:SetVisible(false)
    self.btnMarkActive:SetVisible(false)
    self.btnMarkCompleted:SetVisible(false)
    self.btnMarkReset:SetVisible(false)
    self.btnNarrar:SetVisible(false)
end

-- Fila de separador de solo texto (usada para "Recompensas:" dentro de la
-- misma lista de detalle).
function QuestSyncWindow:AddDetailSeparatorRow(text)
    local item = Turbine.UI.Control()
    item:SetSize(RIGHT_W, 20)

    local lbl = Turbine.UI.Label()
    lbl:SetParent(item)
    lbl:SetPosition(0, 0)
    lbl:SetSize(RIGHT_W, 20)
    lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold14)
    ApplyHeadingStyle(lbl)
    lbl:SetText(text)
    lbl:SetMouseVisible(false)

    self.pointsList:AddItem(item)
    self.pointsRowCount = self.pointsRowCount + 1
end

function QuestSyncWindow:SelectQuest(ndx)
    local quest = QuestDB.quests[ndx]
    if not quest then return end

    -- Sin SFX de click (pedido explicito del usuario, 2026-09-03: "solo
    -- deben ir los sonidos que yo entregue como mp3" -- no hay mp3 real de
    -- click de fila).

    self.selectedNdx = ndx
    self.selectedPoi = nil
    self:LayoutDetailForMode(false)

    QuestStateManager.SetTrackedQuest(ndx)
    self:UpdateActiveSummary()

    local esName = GetQuestDisplayName(ndx, quest)
    self.lblTitle:SetText(esName)

    -- Mision de GRUPO (ver cartel self.groupBanner en el Constructor):
    -- titulo en tinta de grupo + cartel con logo, tamaño de grupo y a que
    -- mazmorra/incursion/zona hay que ir. Si no es de grupo, titulo con la
    -- tinta de siempre (INK) y cartel oculto -- se resetea SIEMPRE aca,
    -- porque SelectQuest se llama de nuevo para otra mision sin pasar por
    -- ClearDetailPanel.
    local groupEntry = _G.GroupQuest and GroupQuest.Get(quest)
    if groupEntry then
        self.lblTitle:SetForeColor(GroupQuest.Color.Ink)
        -- 2026-09-27: el cartel tiene alto fijo (~4 lineas de Bold14); si
        -- el nombre de la mazmorra en los dos idiomas no entra, se usa la
        -- letra de 12 (5 lineas) en vez de cortar el texto.
        local groupText = GroupQuest.Statement(groupEntry)
        local bw, bh = self.lblGroupBanner:GetSize()
        -- (2026-10-01, pedido del usuario con captura: "las letras naranja
        -- de grupo... no se logra leer") primero la letra GRANDE (Bold18,
        -- la de "Objetivo de la Mision:"); si no entra, la de antes (Bold14)
        -- y recien despues la de 12 -- nunca se corta el texto.
        local font = LQA.UI.MEMBookStyle.Font.BookAntiquaBold14
        if GroupQuest.EstimateLines then
            if GroupQuest.EstimateLines(groupText, bw, 8.5) * 21 <= bh then
                font = LQA.UI.MEMBookStyle.Font.BookAntiquaBold18
            elseif GroupQuest.EstimateLines(groupText, bw, 7.5) * 17 > bh then
                font = LQA.UI.MEMBookStyle.Font.BookAntiqua12
            end
        end
        self.lblGroupBanner:SetFont(font)
        self.lblGroupBanner:SetText(groupText)
        self.groupBanner:SetVisible(true)
    else
        self.lblTitle:SetForeColor(INK)
        self.groupBanner:SetVisible(false)
    end

    -- Boton "Buscar grupo": carga el comando de chat de ESTA mision en su
    -- Quickslot y se muestra; si no es de grupo (o no hay Quickslot), se
    -- oculta. El Quickslot queda con el comando anterior mientras esta
    -- oculto -- inofensivo, nadie puede clickear un boton invisible.
    local lffCmd = groupEntry and self.lffQuickslot and GroupQuest.LffCommand(quest)
    if lffCmd then
        self.lffQuickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, lffCmd))
        self.btnLff:SetVisible(true)
    else
        self.btnLff:SetVisible(false)
    end

    local state = QuestStateManager.GetQuestState(ndx)
    local progress = ""
    if state == "ACTIVE" and QuestStateManager.State.active[ndx] then
        progress = T("progress_prefix") .. (QuestStateManager.State.active[ndx].progress or "")
    elseif state == "COMPLETED" then
        progress = T("completed_state")
    end

    local stages = QuestStagesCoords and QuestStagesCoords[ndx]
    local firstLoc = MoorMapAdapter.ResolveQuestLoc(ndx, quest)
    local poiText = quest.poiName or quest.bestower or T("unknown")

    -- Sin linea en blanco cuando no hay progreso todavia (mas compacto,
    -- deja mas lugar libre para la lista de abajo -- ver la nota grande
    -- junto a RIGHT_BOTTOM_LIMIT sobre el presupuesto de alto ajustado).
    local descLines = { T("level_prefix") .. tostring(quest.level) }
    if progress ~= "" then table.insert(descLines, progress) end
    table.insert(descLines, T("destination_prefix") .. poiText)
    self.lblDesc:SetText(table.concat(descLines, "\n"))

    if firstLoc then
        if WaypointAdapter and self.waypointQuickslot then
            WaypointAdapter.SetDestination(self.waypointQuickslot, firstLoc)
        end
        if MoorMapAdapter and self.moorMapQuickslot then
            local ns, ew = MoorMapAdapter.ParseCoord(firstLoc)
            MoorMapAdapter.SetQuestMarker(self.moorMapQuickslot, {
                mapID = MoorMapAdapter.ResolveMapID(quest),
                ns = ns or 0, ew = ew or 0,
                name = string.gsub(esName, ":", "-"), description = "Objetivo"
            })
        end
    end

    self.pointsList:ClearItems()
    self.pointsRowCount = 0

    -- Botones Activar/Completar/Desmarcar reales (pedido explicito del
    -- usuario: "los objetivos de las misiones no tiene botones" -- antes
    -- eran filas de texto dentro de la lista). self.selectedNdx ya quedo
    -- seteado arriba; sus MouseClick (definidos una sola vez en el
    -- Constructor) lo leen directo, no hace falta pasarles ndx aca.
    -- V13 (2026-09-04): ya NO hay SetText aca. Con el arte nuevo (texto
    -- quemado en la imagen, ver Constructor) estos 3 botones son
    -- Turbine.UI.Control (CreateIconButtonAlpha), que no tiene metodo
    -- SetText -- llamarlo tiraria un error de Lua. Efecto secundario
    -- ACEPTADO (pedido explicito del usuario de integrar este arte tal
    -- cual, sin pedirle una version en ingles): Activar/Completar/
    -- Desmarcar/Narrar quedan fijos en español, ya no seguian el cambio de
    -- idioma ES/EN como antes.
    self.btnMarkActive:SetVisible(true)
    self.btnMarkCompleted:SetVisible(true)
    self.btnMarkReset:SetVisible(true)
    self.btnNarrar:SetVisible(true)

    -- BUG CORREGIDO (visto en captura del usuario, sesion anterior): el
    -- encabezado "Objetivo de la Mision:" se dibujaba DOS veces -- una vez
    -- aca como self.lblStagesHeader (fijo, fuera de la lista) y otra vez
    -- como fila suelta dentro de ella. Ahora es UN SOLO lugar (el
    -- encabezado fijo), igual que ya funcionaba bien para "Puntos:" en
    -- Puntos de Interes/Tropas (SelectPoi nunca duplico el suyo).
    local mapID = MoorMapAdapter.ResolveMapID(quest)
    self.lblStagesHeader:SetText(T("mission_objective"))
    if stages then
        for _, stage in ipairs(stages) do
            local stageName = LocalizedText(stage.nameES, stage.name)
            self:AddDetailPointRow("- " .. stageName, stage.loc, esName, mapID)
        end
    end
    self:UpdatePointsButtonVisibility()
end

-- BUG CORREGIDO (visto en captura del usuario: nombres largos como "El
-- Claro de los Trolls de Piedra" se envolvian a 2 lineas y se pisaban con
-- la fila siguiente): antes el nombre compartia renglon con los botones
-- Mapa/Ruta en una sola fila de 30px, dejandole solo 148px de ancho al
-- texto -- muy angosto para 16pt. Ahora el nombre usa el ANCHO COMPLETO en
-- su propia linea (334px, mucho menos probable que envuelva) y los botones
-- van en una segunda linea debajo, dentro de la MISMA fila -- la fila en
-- si crece lo suficiente para que quepan las 2 lineas sin invadir la
-- siguiente.
-- Pedido explicito del usuario ("estos botones pueden estar de manera
-- horizontal y no vertical, ya que esto gasta espacio"): nombre + Mapa +
-- Ruta vuelven a compartir 1 sola linea (no 2, nombre arriba/botones
-- abajo) -- ahora que existe el boton "Ver puntos" (self.pointsExpanded)
-- para cuando falta lugar, ya no hace falta reservar tanto alto por fila
-- para evitar el choque de nombres largos que motivo el diseño anterior.
-- BUG CORREGIDO (visto en captura del usuario: texto cortado a la mitad
-- de palabra, ej. "At the top of Dun Covad by" seguia y no se veia) --
-- algunos puntos de WarbandsSlayer traen una FRASE larga en ingles como
-- etiqueta (no un nombre corto tipo "Punto N"), que no entraba en 1 sola
-- linea angosta. Se agranda la fila y se activa el ajuste de linea
-- (SetMultiline) para que la frase completa se vea en 2-3 lineas en vez
-- de cortarse -- las filas con nombre corto ("Punto N") simplemente
-- quedan con un poco de espacio de sobra, mejor que perder texto real.
function QuestSyncWindow:AddDetailPointRow(desc, loc, ownerName, mapID)
    local item = Turbine.UI.Control()
    item:SetSize(RIGHT_W, 60)

    local lbl = Turbine.UI.Label()
    lbl:SetParent(item)
    lbl:SetPosition(0, 2)
    lbl:SetSize(RIGHT_W - 124, 56)
    lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua16)
    lbl:SetMultiline(true)
    ApplyReadableStyle(lbl, ROW_ACTIVE)
    lbl:SetText(desc or "")

    if MoorMapAdapter and loc then
        local btnMap = Turbine.UI.Lotro.Button()
        btnMap:SetParent(item)
        btnMap:SetPosition(RIGHT_W - 120, 0)
        btnMap:SetSize(58, 24)
        btnMap:SetText(T("map_btn"))

        local qsMap = MoorMapAdapter.CreateQuickslot()
        MoorMapAdapter.AttachToButton(qsMap, btnMap)

        local ns, ew = MoorMapAdapter.ParseCoord(loc)
        MoorMapAdapter.SetQuestMarker(qsMap, {
            mapID = mapID or 0, ns = ns or 0, ew = ew or 0,
            name = string.gsub(ownerName or "", ":", "-"), description = "Objetivo"
        })
    end

    if WaypointAdapter and loc then
        local btnWay = Turbine.UI.Lotro.Button()
        btnWay:SetParent(item)
        btnWay:SetPosition(RIGHT_W - 60, 0)
        btnWay:SetSize(58, 24)
        btnWay:SetText(T("route_btn"))

        local qsWay = WaypointAdapter.CreateQuickslot()
        MoorMapAdapter.AttachToButton(qsWay, btnWay)

        WaypointAdapter.SetDestination(qsWay, loc)
    end

    self.pointsList:AddItem(item)
    self.pointsRowCount = self.pointsRowCount + 1
end

function QuestSyncWindow:AddRewardRow(text)
    local item = Turbine.UI.Control()
    item:SetSize(RIGHT_W, 24)

    local lbl = Turbine.UI.Label()
    lbl:SetParent(item)
    lbl:SetPosition(0, 0)
    lbl:SetSize(RIGHT_W, 24)
    lbl:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua16)
    lbl:SetMultiline(true)
    ApplyReadableStyle(lbl, ROW_REWARD)
    lbl:SetText(text)
    lbl:SetMouseVisible(false)

    self.pointsList:AddItem(item)
    self.pointsRowCount = self.pointsRowCount + 1
end

function QuestSyncWindow:SelectPoi(entry, icon)
    self.selectedNdx = nil
    self.selectedPoi = entry
    -- Puntos de Interes/Tropas/Colecciones nunca tienen estado de
    -- mision -- sin esto, los botones Activar/Completar/Desmarcar de la
    -- ultima mision seleccionada quedarian visibles por encima.
    self.btnMarkActive:SetVisible(false)
    self.btnMarkCompleted:SetVisible(false)
    self.btnMarkReset:SetVisible(false)
    self.btnNarrar:SetVisible(false)
    -- Cartel/tinta/boton de mision de grupo: solo aplican a misiones (SelectQuest).
    self.groupBanner:SetVisible(false)
    self.btnLff:SetVisible(false)
    self.lblTitle:SetForeColor(INK)

    local esName = DisplayName(entry)
    self.lblTitle:SetText(esName)
    local infoLine = entry.level and (T("level_prefix") .. tostring(entry.level)) or ""
    if entry.zone and entry.zone ~= "" then infoLine = infoLine .. "\n" .. T("zone_prefix") .. DisplayZone(entry) end
    if entry.race and entry.race ~= "" then infoLine = infoLine .. "\n" .. T("type_prefix") .. LocalizedText(entry.raceES, entry.race) end
    if entry.note and entry.note ~= "" then infoLine = infoLine .. "\n" .. T("note_prefix") .. LocalizedText(entry.noteES, entry.note) end
    self.lblDesc:SetText(infoLine)

    self:ClearMapMarkers()
    self.pointsList:ClearItems()
    self.pointsRowCount = 0

    local groups = GetGroupsFor(entry)
    local group = groups[1]
    local bounds = group and WarbandMapBounds and WarbandMapBounds[group.map]

    self:LayoutDetailForMode(group ~= nil and group.map ~= nil and group.map ~= "")

    if group and group.map and group.map ~= "" then
        self.mapImage:SetBackground(RES_BASE .. "Maps/" .. group.map)
    end

    self.lblStagesHeader:SetText(T("points_header"))

    local mapID = MoorMapAdapter.ResolveMapID({ area = (bounds and bounds.name) or entry.area or entry.zone })
    if group and group.coords[1] then
        local firstLoc = group.coords[1].c
        if WaypointAdapter and self.waypointQuickslot then
            WaypointAdapter.SetDestination(self.waypointQuickslot, firstLoc)
        end
        if MoorMapAdapter and self.moorMapQuickslot then
            local ns, ew = MoorMapAdapter.ParseCoord(firstLoc)
            MoorMapAdapter.SetQuestMarker(self.moorMapQuickslot, {
                mapID = mapID, ns = ns or 0, ew = ew or 0,
                name = string.gsub(esName, ":", "-"), description = "Punto de interes"
            })
        end
    end

    local pointIndex = 0
    for _, g in ipairs(groups) do
        local gBounds = WarbandMapBounds and g.map and WarbandMapBounds[g.map]
        local gMapID = gBounds and MoorMapAdapter.ResolveMapID({ area = gBounds.name }) or mapID
        for _, pt in ipairs(g.coords) do
            pointIndex = pointIndex + 1
            if g == group and bounds then
                local px, py = CoordToPixel(pt.c, bounds)
                if px then
                    local marker = Turbine.UI.Label()
                    marker:SetParent(self.mapImage)
                    marker:SetSize(16, 16)
                    marker:SetPosition(px, py)
                    marker:SetMouseVisible(false)
                    if icon then marker:SetBackground(icon) end
                    table.insert(self.mapMarkers, marker)
                end
            end
            -- BUG CORREGIDO (visto en captura con zoom del usuario: filas
            -- sin texto antes de Mapa/Ruta, "no se sabe de que punto es"):
            -- algunas entradas de WarbandsSlayer traen una etiqueta que
            -- NO es string vacio pero tampoco dice nada real (un espacio,
            -- un punto suelto ".") -- el chequeo viejo (~= "") las dejaba
            -- pasar como "etiqueta valida" en vez de caer al respaldo
            -- "Punto N". Ahora se exige al menos 1 caracter alfanumerico
            -- real (%w incluye letras/numeros, no espacios ni puntuacion).
            local ptLabel = LocalizedText(pt.lES, pt.l)
            local desc = (ptLabel and ptLabel:match("%w")) and ptLabel or (T("point_fallback") .. pointIndex)
            self:AddDetailPointRow(desc, pt.c, esName, gMapID)
        end
    end

    local rewards = entry.rewards
    if rewards and #rewards > 0 then
        self:AddDetailSeparatorRow(T("rewards_header"))
        for i, r in ipairs(rewards) do
            local rtext
            if type(r) == "table" then
                local isES = LanguageSettings.IsSpanish()
                local rname = (isES and (REWARD_NAMES[r.type] or r.type)) or (REWARD_NAMES_EN[r.type] or r.type)
                local rvalue = isES and (r.valueES or r.value) or r.value
                rtext = "- " .. rname
                if rvalue and rvalue ~= "" and tostring(rvalue) ~= rname then
                    if tonumber(rvalue) then
                        rtext = rtext .. " x" .. rvalue
                    else
                        rtext = rtext .. ": " .. rvalue
                    end
                end
            else
                local rEN = entry.rewardsEN and entry.rewardsEN[i]
                rtext = "- " .. tostring(LocalizedText(r, rEN or r))
            end
            self:AddRewardRow(rtext)
        end
    end
    self:UpdatePointsButtonVisibility()
end
