-- LOTRO_Quest_Assistant/UI/QuestInfoTooltip.lua
-- Ventanita flotante de informacion al pasar el mouse por encima de una
-- mision (fila de QuestSyncWindow o de QuestTrackerHUD). Estructura portada
-- de CubePlugins/DeedTracker/DeedTooltipWindow.lua + MainWin.lua:
-- ShowDeedTooltip/HideDeedTooltip: una unica ventana Turbine.UI.Window (sin
-- chrome de Lotro, igual que el original) que cualquier fila puede pedir
-- mostrar/ocultar via MouseHover/MouseLeave, con el mismo truco de "anillo de
-- borde" (el SetBackColor de la VENTANA se ve como marco; un Control interior
-- mas chico, inset por BORDER px, es el relleno oscuro donde vive el texto) --
-- pero con la paleta y fuentes propias de QuestSync (dorado/TrajanPro), no
-- las de DeedTracker (gris/Verdana16), tal como se pidio explicitamente. No
-- se porto el soporte de "despegar" el tooltip (arrastrarlo, dejarlo fijo) --
-- no fue pedido, y agregarlo hubiera significado copiar mucho mas codigo sin
-- necesidad.
--
-- BUG CORREGIDO (2026-08-20, confirmado por captura de pantalla del usuario
-- con el error real de Lua en el chat: "QuestInfoTooltip.lua:61: attempt to
-- call method 'SetWordWrap' (a nil value)"): esa API NO existe en este SDK --
-- fue una suposicion incorrecta de la sesion anterior (un grep con 3 terminos
-- unidos por OR encontro "SetMultiline" en DeedTracker/MainWin.lua, pero se
-- interpreto por error como si tambien confirmara "SetWordWrap"). El
-- mecanismo real de multilinea+ajuste-de-palabra en un Turbine.UI.Label,
-- confirmado leyendo el uso real en
-- CubePlugins/DeedTracker/PluginFunctions.lua:GetDeedInformationControl, es
-- SetMultiline(true) (ajusta el texto solo, dentro del ancho ya fijado por
-- SetSize -- no hace falta medir texto a mano ni una API de word-wrap
-- separada). Se reemplazo SetWordWrap por SetMultiline en el Constructor.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.QuestInfoTooltip = class(Turbine.UI.Window)
QuestInfoTooltip.instance = nil

function QuestInfoTooltip.GetInstance()
    if QuestInfoTooltip.instance then return QuestInfoTooltip.instance end
    return QuestInfoTooltip()
end

local RES_BASE = "LOTRO_Quest_Assistant/Resources/"

local WIDTH = 320
local BORDER = 2
local HEADER_H = 26
local BODY_MIN_H = 20
local BODY_MAX_H = 240
local PROGRESS_H = 18 -- alto real de ProgressBar_Back.tga
local PAD_BOTTOM = 8

function QuestInfoTooltip:Constructor()
    if QuestInfoTooltip.instance then return end
    Turbine.UI.Window.Constructor(self)
    QuestInfoTooltip.instance = self

    self:SetZOrder(0x7FFFFFFF)
    -- El color de la VENTANA es el "marco" visible (mismo rol que el
    -- SetBackColor gris de DeedTooltipWindow) -- acá el dorado-marron que
    -- ya usa QuestSyncWindow.lua para sus divisores/encabezados, no gris.
    self:SetBackColor(Turbine.UI.Color(0.5, 0.42, 0.25))
    self:SetOpacity(0.92)
    self:SetVisible(false)

    -- Relleno interior oscuro, inset BORDER px -- mismo truco estructural
    -- que el "self.border" de DeedTooltipWindow (que en realidad es el
    -- RELLENO, no el marco: el marco es el color de la ventana detras de
    -- el). Nombrado "inner" aca para que el rol quede claro.
    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetPosition(BORDER, BORDER)
    self.inner:SetBackColor(Turbine.UI.Color(0.08, 0.07, 0.05))
    self.inner:SetMouseVisible(false)

    local innerW = WIDTH - BORDER * 2

    self.lblTitle = Turbine.UI.Label()
    self.lblTitle:SetParent(self.inner)
    self.lblTitle:SetPosition(8, 6)
    self.lblTitle:SetSize(innerW - 16, 20)
    self.lblTitle:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold14) -- rediseño "libro" 2026-08-28
    self.lblTitle:SetForeColor(Turbine.UI.Color(1, 0.82, 0.3))
    self.lblTitle:SetMouseVisible(false)

    self.lblBody = Turbine.UI.Label()
    self.lblBody:SetParent(self.inner)
    self.lblBody:SetPosition(8, HEADER_H)
    self.lblBody:SetSize(innerW - 16, BODY_MIN_H)
    self.lblBody:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    self.lblBody:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.85))
    self.lblBody:SetMouseVisible(false)
    self.lblBody:SetMultiline(true)

    -- Barra de porcentaje de progreso, pedido explicito del usuario --
    -- ahora con las imagenes REALES de CubePlugins/DeedTracker/Resources/
    -- (ProgressBar_Back.tga 200x18, ProgressBar.tga 179x9,
    -- ProgressBarComplete.tga 179x9), copiadas a Resources/ con
    -- autorizacion explicita del usuario (dueño/autor de DeedTracker,
    -- igual que ya lo era de WarbandsSlayer). Mismo mecanismo real
    -- confirmado leyendo MainWin.lua:UpdateTabProgress/SetProgressBarCompleted:
    -- un Control con el fondo del track (ProgressBar_Back) y un Control HIJO
    -- mas chico con el fondo del relleno (ProgressBar) cuyo SetWidth se
    -- reescala proporcional a completado/total (179 * pct) -- el relleno se
    -- ve "cortado" en vez de estirado porque SetBackground no escala la
    -- imagen al tamaño del control, la recorta. Solo se muestra si la mision
    -- esta ACTIVA y su progreso guardado tiene forma "N/M" real (nunca se
    -- inventa un porcentaje sin dato detras).
    self.progressBack = Turbine.UI.Control()
    self.progressBack:SetParent(self.inner)
    self.progressBack:SetSize(200, 18)
    self.progressBack:SetBackground(RES_BASE .. "ProgressBar_Back.tga")
    self.progressBack:SetBlendMode(Turbine.UI.BlendMode.Overlay)
    self.progressBack:SetMouseVisible(false)
    self.progressBack:SetVisible(false)

    self.progressFill = Turbine.UI.Control()
    self.progressFill:SetParent(self.progressBack)
    self.progressFill:SetPosition(10, 5)
    self.progressFill:SetSize(0, 9)
    self.progressFill:SetBackground(RES_BASE .. "ProgressBar.tga")
    self.progressFill:SetBlendMode(Turbine.UI.BlendMode.Overlay)
    self.progressFill:SetMouseVisible(false)

    -- Texto "N/M" centrado SOBRE la barra (mismo patron que
    -- lblOverallProgress en MainWin.lua: outline en vez de fondo solido
    -- para que se lea encima de la imagen del track).
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
end

-- Recorta un texto largo a maxLen caracteres, cortando en un espacio para no
-- partir una palabra a la mitad.
local function Truncate(text, maxLen)
    if not text or text == "" then return "" end
    if #text <= maxLen then return text end
    local cut = string.sub(text, 1, maxLen)
    local lastSpace = nil
    for i = #cut, 1, -1 do
        if string.sub(cut, i, i) == " " then lastSpace = i break end
    end
    return string.sub(cut, 1, lastSpace and (lastSpace - 1) or maxLen) .. "..."
end

-- BUG CORREGIDO (2026-08-20, visible en la misma captura del usuario):
-- algunas entradas de objectivesES traen placeholders de plantilla del
-- propio LOTRO sin resolver, p.ej. "Reúne Fichas de Heroísmo
-- (${NUMBER}/${TOTAL})" -- el cliente real los reemplaza en tiempo real con
-- el progreso vivo, algo que este addon no calcula para ese texto (no es lo
-- mismo que el contador "(N/M)" que SI capturamos del chat va
-- QuestStateManager). Mostrar el "${...}" crudo se ve roto, asi que esas
-- lineas se descartan enteras en vez de mostrarse a medio resolver.
-- Movido a Core/QuestLocResolver.lua (2026-08-28) como IsFlavorText, para que
-- UI/QuestBookWindow.lua use el mismo filtro sin duplicar la logica -- ver la
-- nota junto a esa funcion.

-- BUG CORREGIDO (2026-08-20, captura de pantalla del usuario: el tooltip de
-- "Libro 3, Capitulo 4, Parte III de III: Los Enanos Vendran" [ndx 2077]
-- mostraba "Objetivo: '¡Mi mano ansía tomar mi hacha y partir a los orcos en
-- dos!'" -- una frase de dialogo/grito de batalla de un PNJ, no una
-- instruccion real). La suposicion "objectivesES[1]=resumen,
-- objectivesES[2]=objetivo corto" (sesion ~38) era una generalizacion
-- incorrecta: para ndx 2077, QuestLocalization_Full.lua trae objectivesES =
-- {"Halbarad se encuentra en Esteldín...Hannar te pidio que informaras...",
-- "'¡Mi mano ansía...!'", "Libro 3...(nombre repetido)", "'¡Malditos
-- Duramano...!'", ...} -- el INDICE [1] SI es el objetivo real (coincide
-- palabra por palabra con el campo "o" = "Obj 1: ..." de
-- CompendiumQuestsDB.lua para esa mision), pero [2] en adelante son
-- exclamaciones de PNJ que aparecen en el diario de mision al completar cada
-- etapa, no instrucciones. Medido contra las 14.824 misiones: el PRIMER
-- elemento del array tambien es una frase de dialogo (empieza con comilla/
-- exclamacion/interrogacion) en 3.459 casos (23.5%) -- osea, ni siquiera el
-- indice [1] es confiable el 100% de las veces. Se reemplazo la seleccion
-- por indice fijo por un filtro de contenido: se descarta cualquier entrada
-- que empiece con ' " ¡ ¿ (marcas tipicas de dialogo citado en la
-- traduccion profesional) y se usan los primeros 2 elementos LIMPIOS del
-- array, en el orden en que aparezcan -- nunca se inventa texto nuevo, solo
-- se filtra mejor lo que LOTRO Companion ya extrajo.
-- BUG CORREGIDO (encontrado en auditoria propia, mismo dia): string.sub()
-- en Lua opera por BYTES, no por caracteres -- "¡"/"¿" ocupan 2 bytes en
-- UTF-8 (0xC2 0xA1 / 0xC2 0xBF), asi que comparar string.sub(s,1,1) (1 solo
-- byte) contra el literal "¡" (2 bytes) nunca podia dar verdadero. Misma
-- clase de bug ya vista en QuestLocResolver.toLowerES (sesion 6, "misi?n").
-- Se compara el primer byte solo contra las comillas (ASCII, 1 byte) y los
-- primeros 2 bytes contra ¡/¿ (ambos comparten el byte inicial 0xC2, asi
-- que el prefijo de 2 bytes es la comparacion correcta).
-- Arma el cuerpo del tooltip con lo que YA existe en el addon: nivel + area
-- (siempre disponibles) y, si el DAT profesional trajo texto de objetivo
-- para esta mision (QuestLocES[ndx].objectivesES, ver Main.lua 2b), hasta 2
-- lineas limpias (QuestLocResolver.GetCleanObjectiveLines, ver la nota junto
-- a esa funcion): la primera sin etiqueta (texto general/resumen), la
-- segunda como "Objetivo:" si es distinta de la primera.
local function BuildQuestBody(ndx, quest)
    local lines = {}
    local infoLine = "Nivel " .. tostring(quest.level or "?")
    local area = (quest.area and quest.area ~= "" and quest.area) or quest.zone
    if area then infoLine = infoLine .. "  -  " .. tostring(area) end
    table.insert(lines, infoLine)

    -- Mision de GRUPO (2026-09-22, ver Core/GroupQuest.lua): tamaño de
    -- grupo + a que mazmorra/incursion/zona hay que ir, justo debajo de
    -- la linea de nivel. El alto del cuerpo ya se mide solo
    -- (AutoFitLabelHeight), 2 lineas mas no desbordan nada.
    local groupEntry = _G.GroupQuest and GroupQuest.Get(quest)
    if groupEntry then
        table.insert(lines, GroupQuest.Statement(groupEntry))
    end

    -- Diaria/Semanal y "apropiada para tu nivel" (2026-09-22, ver
    -- Core/QuestTags.lua). Cada linea solo aparece si aplica.
    if _G.QuestTags then
        local lockText = QuestTags.LockText(quest)
        if lockText then
            table.insert(lines, lockText)
        end
        local playerLevel = QuestTags.GetPlayerLevel()
        if QuestTags.IsLevelAppropriate(quest, playerLevel) then
            table.insert(lines, QuestTags.LevelText(playerLevel))
        end
    end

    local clean = QuestLocResolver.GetCleanObjectiveLines(ndx, quest, 2)
    if clean[1] then
        table.insert(lines, "")
        table.insert(lines, Truncate(clean[1], 220))
    end
    if clean[2] and clean[2] ~= clean[1] then
        table.insert(lines, "")
        table.insert(lines, "Objetivo: " .. Truncate(clean[2], 160))
    end
    return table.concat(lines, "\n")
end

-- BUG CORREGIDO (2026-08-20, segunda captura del usuario): un texto de
-- objetivo largo desbordaba por debajo del limite visible de la ventana --
-- BODY_H era un alto FIJO adivinado, no medido, y para objetivos largos
-- (varios parrafos reales, ej. "Libro 2, Capitulo 10...") ni recortando a
-- 220/160 caracteres alcanzaba. Portado el mecanismo REAL de
-- CubePlugins/DeedTracker/GeneralFunctions.lua:AutoFitLabelHeight: le
-- engancha temporalmente una scrollbar vertical (solo se vuelve visible si
-- el texto no entra en el alto actual), crece el label de a poco mientras la
-- scrollbar siga visible, y la saca al terminar -- mide el texto real en vez
-- de adivinar un numero fijo. minH/maxH acotan el resultado (nunca mas chico
-- que una linea, nunca mas alto que maxH aunque el texto sea enorme).
local function AutoFitLabelHeight(label, minH, maxH)
    local increment = 8
    label:SetHeight(minH)

    local scrollBar = Turbine.UI.Lotro.ScrollBar()
    scrollBar:SetParent(label)
    label:SetVerticalScrollBar(scrollBar)

    local text = label:GetText()
    label:SetText(text) -- fuerza un relayout con la scrollbar ya enganchada

    while scrollBar:IsVisible() and label:GetHeight() < maxH do
        label:SetHeight(label:GetHeight() + increment)
        label:SetText(text)
    end

    local finalHeight = label:GetHeight()
    label:SetVerticalScrollBar(nil)
    scrollBar:SetParent(nil)
    if finalHeight < minH then finalHeight = minH end
    return finalHeight
end

-- Extrae "N/M" de un texto de progreso guardado (QuestStateManager.State.
-- active[ndx].progress, el mismo texto que ya muestra el resto de la UI) --
-- nunca fabrica un numero, solo lo parsea si esta presente.
local function ParseProgressFraction(text)
    if not text or text == "" then return nil, nil end
    local cur, total = string.match(text, "(%d+)%s*/%s*(%d+)")
    if cur and total then return tonumber(cur), tonumber(total) end
    return nil, nil
end

function QuestInfoTooltip:ShowFor(ndx, quest, displayName)
    if not quest then return end
    self.currentNdx = ndx
    self.lblTitle:SetText(displayName or quest.nameEN or "")
    -- Titulo en color de grupo si corresponde; si no, el dorado de siempre
    -- (se resetea en cada ShowFor -- la instancia del tooltip es unica y se
    -- reusa entre misiones).
    if _G.GroupQuest and GroupQuest.IsGroup(quest) then
        self.lblTitle:SetForeColor(GroupQuest.Color.Dark)
    else
        self.lblTitle:SetForeColor(Turbine.UI.Color(1, 0.82, 0.3))
    end
    self.lblBody:SetText(BuildQuestBody(ndx, quest))

    local innerW = WIDTH - BORDER * 2
    local bodyH = AutoFitLabelHeight(self.lblBody, BODY_MIN_H, BODY_MAX_H)
    local yAfterBody = HEADER_H + bodyH + 6

    local state = QuestStateManager and QuestStateManager.GetQuestState(ndx)
    local cur, total
    if state == "ACTIVE" then
        cur, total = ParseProgressFraction(QuestStateManager.GetQuestProgress(ndx))
    end

    local totalH
    if cur and total and total > 0 then
        local pct = math.min(1, cur / total)
        self.progressFill:SetBackground(cur >= total and (RES_BASE .. "ProgressBarComplete.tga") or (RES_BASE .. "ProgressBar.tga"))
        self.progressFill:SetWidth(math.max(2, math.floor(179 * pct)))
        self.lblProgress:SetText(cur .. "/" .. total)
        self.progressBack:SetPosition(8, yAfterBody)
        self.progressBack:SetVisible(true)

        totalH = yAfterBody + PROGRESS_H + PAD_BOTTOM
    else
        self.progressBack:SetVisible(false)
        totalH = yAfterBody + PAD_BOTTOM
    end

    self:SetSize(WIDTH, totalH + BORDER * 2)
    self.inner:SetSize(innerW, totalH)

    -- Posicion en pantalla real (no relativa a la fila, que vive anidada
    -- dentro de un ListBox) -- mismo enfoque que DisplayTooltip en
    -- DeedTooltipWindow.lua, desplazado de la punta del mouse para no
    -- quedar tapado por el propio cursor.
    local screenX, screenY = Turbine.UI.Display.GetMousePosition()
    self:SetPosition(screenX + 20, screenY + 20)
    self:SetVisible(true)
end

function QuestInfoTooltip:Hide()
    self:SetVisible(false)
    self.currentNdx = nil
end
