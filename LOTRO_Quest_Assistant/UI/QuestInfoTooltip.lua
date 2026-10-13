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
--
-- v2 (2026-10-13, pedido del usuario): misma "tarjeta moderna" que los
-- carteles del Mapa del Mundo: fondo oscuro con esquinas redondeadas, barra
-- de color a la izquierda (dorada; de grupo si es mision de grupo), icono,
-- nombre, "Nivel N · zona", etiquetas (estado, diaria/semanal, apropiada
-- para tu nivel), resumen, objetivo y barra de progreso fina. Mismos datos
-- que antes (nada inventado) y la misma API: GetInstance / ShowFor / Hide.
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
local CARD = RES_BASE .. "Card/"

local WIDTH = 320
local R = 12            -- radio de las esquinas
local PAD = 18          -- margen izquierdo (despues de la barra de color)
local TEXT_X = 54       -- titulo al lado del icono
local BODY_MAX_H = 240
local BG = Turbine.UI.Color(0.96, 16 / 255, 18 / 255, 24 / 255)
local BORDER_C = Turbine.UI.Color(1, 60 / 255, 66 / 255, 80 / 255)
local ACCENT = Turbine.UI.Color(1, 1, 208 / 255, 64 / 255)
local PILL = {
    green = { "green", Turbine.UI.Color(1, 140 / 255, 240 / 255, 170 / 255), Turbine.UI.Color(1, 22 / 255, 70 / 255, 40 / 255) },
    amber = { "amber", Turbine.UI.Color(1, 1, 200 / 255, 90 / 255), Turbine.UI.Color(1, 90 / 255, 60 / 255, 10 / 255) },
    blue = { "blue", Turbine.UI.Color(1, 160 / 255, 200 / 255, 1), Turbine.UI.Color(1, 30 / 255, 45 / 255, 70 / 255) },
}

local function Font(name, fallback)
    local F = Turbine.UI.Lotro.Font
    return F[name] or F[fallback] or F.Verdana12
end

-- ancho aproximado (el juego no deja medir el texto)
local function TextW(text, px)
    local n = 0
    for _ in tostring(text or ""):gmatch("[^\128-\191]") do n = n + 1 end
    return math.floor(n * (px or 6.6) + 0.5)
end

function QuestInfoTooltip:Constructor()
    if QuestInfoTooltip.instance then return end
    Turbine.UI.Window.Constructor(self)
    QuestInfoTooltip.instance = self

    self:SetZOrder(0x7FFFFFFF)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetMouseVisible(false)
    self:SetVisible(false)

    local this = self
    local function box(color)
        local k = Turbine.UI.Control()
        k:SetParent(this)
        k:SetMouseVisible(false)
        if color then k:SetBackColor(color) end
        return k
    end
    local function img(file, w, h)
        local k = Turbine.UI.Control()
        k:SetParent(this)
        k:SetSize(w, h)
        if file then k:SetBackground(file) end
        k:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        k:SetMouseVisible(false)
        return k
    end
    local function label(font, color, align, multi)
        local l = Turbine.UI.Label()
        l:SetParent(this)
        l:SetFont(font)
        l:SetForeColor(color)
        l:SetTextAlignment(align or Turbine.UI.ContentAlignment.TopLeft)
        l:SetMultiline(multi == true)
        l:SetMouseVisible(false)
        return l
    end
    -- marco
    self.tl = img(CARD .. "card_tl.tga", R, R)
    self.tr = img(CARD .. "card_tr.tga", R, R)
    self.bl = img(CARD .. "card_bl.tga", R, R)
    self.br = img(CARD .. "card_br.tga", R, R)
    self.top, self.mid, self.bot = box(BG), box(BG), box(BG)
    self.lineT, self.lineB, self.lineL, self.lineR = box(BORDER_C), box(BORDER_C), box(BORDER_C), box(BORDER_C)
    self.accent = box(ACCENT)
    self.icon = img(CARD .. "quest_32.tga", 32, 32)
    self.icon:SetPosition(14, 12)
    -- textos
    local V12 = Turbine.UI.Lotro.Font.Verdana12
    local V10 = Font("Verdana10", "Verdana12")
    self.lblTitle = label(Font("Verdana16", "Verdana14"), Turbine.UI.Color(1, 245 / 255, 248 / 255, 1))
    self.lblSub = label(V12, Turbine.UI.Color(1, 140 / 255, 170 / 255, 210 / 255))
    self.pills = {}
    for i = 1, 3 do
        self.pills[i] = { l = img(nil, 9, 18), r = img(nil, 9, 18), m = box(), t = label(V10, Turbine.UI.Color.White, Turbine.UI.ContentAlignment.MiddleCenter) }
    end
    self.lblGroup = label(V12, Turbine.UI.Color(1, 200 / 255, 160 / 255, 1), nil, true)
    self.lblBody = label(V12, Turbine.UI.Color(1, 190 / 255, 196 / 255, 210 / 255), nil, true)
    self.lblObjHead = label(V10, Turbine.UI.Color(1, 140 / 255, 150 / 255, 170 / 255))
    self.lblObj = label(V12, Turbine.UI.Color(1, 240 / 255, 220 / 255, 150 / 255), nil, true)
    -- progreso: barra fina + "N / M"
    self.barBack = box(Turbine.UI.Color(1, 38 / 255, 44 / 255, 56 / 255))
    self.barFill = box(ACCENT)
    self.lblProgress = label(V12, Turbine.UI.Color(1, 160 / 255, 200 / 255, 1), Turbine.UI.ContentAlignment.TopRight)
    self.lblProgName = label(V12, Turbine.UI.Color(1, 245 / 255, 248 / 255, 1))
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

local function Show(ctl, on)
    ctl:SetVisible(on == true)
end

function QuestInfoTooltip:ShowFor(ndx, quest, displayName)
    if not quest then return end
    self.currentNdx = ndx
    local W = WIDTH
    local inner = W - PAD - 16
    -- color de la barra: grupo o dorado
    local accent = ACCENT
    local isGroup = _G.GroupQuest and GroupQuest.IsGroup(quest)
    if isGroup and GroupQuest.Color and GroupQuest.Color.Dark then
        accent = GroupQuest.Color.Dark
    end
    self.icon:SetBackground(CARD .. (isGroup and "group_32.tga" or "quest_32.tga"))
    -- cabecera
    local title = displayName or quest.nameEN or ""
    local titleW = W - TEXT_X - 12
    -- nombres largos: hasta 2 lineas
    local twoLines = TextW(title, 8.6) > titleW
    self.lblTitle:SetMultiline(twoLines)
    self.lblTitle:SetText(twoLines and Truncate(title, 58) or title)
    self.lblTitle:SetPosition(TEXT_X, twoLines and 6 or 12)
    self.lblTitle:SetSize(titleW, twoLines and 40 or 20)
    local subY = twoLines and 48 or 34
    local area = (quest.area and quest.area ~= "" and quest.area) or quest.zone
    local lvl = quest.level
    local sub = (lvl == "Scaling" or lvl == "scaling") and "Nivel: escala" or ("Nivel " .. tostring(lvl or "?"))
    if area then sub = sub .. "  \194\183  " .. tostring(area) end
    self.lblSub:SetText(Truncate(sub, 44))
    self.lblSub:SetPosition(TEXT_X, subY)
    self.lblSub:SetSize(W - TEXT_X - 12, 16)
    local y = subY + 22
    -- etiquetas: estado, diaria/semanal, apropiada para tu nivel
    local pills = {}
    local state = QuestStateManager and QuestStateManager.GetQuestState and QuestStateManager.GetQuestState(ndx)
    if state == "ACTIVE" then
        pills[#pills + 1] = { "Activa", "amber" }
    elseif state == "COMPLETED" then
        pills[#pills + 1] = { "Completada", "green" }
    end
    local extraLines = {}
    if _G.QuestTags then
        local okL, lockText = pcall(QuestTags.LockText, quest)
        if okL and lockText then pills[#pills + 1] = { lockText, "blue" } end
        local okP, playerLevel = pcall(QuestTags.GetPlayerLevel)
        if okP and QuestTags.IsLevelAppropriate(quest, playerLevel) then
            local lt = QuestTags.LevelText(playerLevel)
            if lt then pills[#pills + 1] = { lt, "green" } end
        end
    end
    local px = PAD
    local npill = 0
    for i, pl in ipairs(self.pills) do
        local d = pills[i]
        local st = d and PILL[d[2]]
        local w = d and (TextW(d[1], 6.2) + 8) or 0
        local on = st ~= nil and (px + w + 18 <= PAD + inner)
        Show(pl.l, on); Show(pl.r, on); Show(pl.m, on); Show(pl.t, on)
        if on then
            npill = npill + 1
            pl.l:SetBackground(CARD .. "card_" .. st[1] .. "_l.tga")
            pl.r:SetBackground(CARD .. "card_" .. st[1] .. "_r.tga")
            pl.m:SetBackColor(st[3])
            pl.l:SetPosition(px, y)
            pl.m:SetPosition(px + 9, y)
            pl.m:SetSize(w, 18)
            pl.r:SetPosition(px + 9 + w, y)
            pl.t:SetText(d[1])
            pl.t:SetForeColor(st[2])
            pl.t:SetPosition(px + 9, y)
            pl.t:SetSize(w, 18)
            px = px + w + 18 + 6
        elseif d then
            extraLines[#extraLines + 1] = d[1]
        end
    end
    if npill > 0 then y = y + 26 end
    -- mision de grupo: tamaño y a donde ir (+ etiquetas que no entraron)
    local groupText = ""
    local groupEntry = _G.GroupQuest and GroupQuest.Get(quest)
    if groupEntry then groupText = GroupQuest.Statement(groupEntry) or "" end
    if #extraLines > 0 then
        groupText = (groupText ~= "" and (groupText .. "\n") or "") .. table.concat(extraLines, "\n")
    end
    if groupText ~= "" then
        self.lblGroup:SetText(groupText)
        self.lblGroup:SetPosition(PAD, y)
        self.lblGroup:SetWidth(inner)
        local h = AutoFitLabelHeight(self.lblGroup, 16, 120)
        self.lblGroup:SetVisible(true)
        y = y + h + 6
    else
        self.lblGroup:SetVisible(false)
    end
    -- resumen y objetivo (lineas limpias del DAT profesional)
    local clean = QuestLocResolver.GetCleanObjectiveLines(ndx, quest, 2)
    if clean[1] then
        self.lblBody:SetText(Truncate(clean[1], 220))
        self.lblBody:SetPosition(PAD, y)
        self.lblBody:SetWidth(inner)
        local h = AutoFitLabelHeight(self.lblBody, 16, BODY_MAX_H)
        self.lblBody:SetVisible(true)
        y = y + h + 8
    else
        self.lblBody:SetVisible(false)
    end
    if clean[2] and clean[2] ~= clean[1] then
        self.lblObjHead:SetText("OBJETIVO")
        self.lblObjHead:SetPosition(PAD, y)
        self.lblObjHead:SetSize(inner, 14)
        self.lblObjHead:SetVisible(true)
        y = y + 16
        self.lblObj:SetText(Truncate(clean[2], 160))
        self.lblObj:SetPosition(PAD, y)
        self.lblObj:SetWidth(inner)
        local h = AutoFitLabelHeight(self.lblObj, 16, 120)
        self.lblObj:SetVisible(true)
        y = y + h + 8
    else
        self.lblObjHead:SetVisible(false)
        self.lblObj:SetVisible(false)
    end
    -- progreso guardado "N/M" (solo si la mision esta activa y lo trae)
    local cur, total
    if state == "ACTIVE" then
        cur, total = ParseProgressFraction(QuestStateManager.GetQuestProgress(ndx))
    end
    if cur and total and total > 0 then
        local pct = math.min(1, cur / total)
        self.lblProgName:SetText("Progreso")
        self.lblProgName:SetPosition(PAD, y)
        self.lblProgName:SetSize(inner - 70, 16)
        self.lblProgress:SetText(cur .. " / " .. total)
        self.lblProgress:SetPosition(W - 16 - 70, y)
        self.lblProgress:SetSize(70, 16)
        y = y + 19
        self.barBack:SetPosition(PAD, y)
        self.barBack:SetSize(inner, 6)
        self.barFill:SetBackColor(cur >= total and Turbine.UI.Color(1, 90 / 255, 210 / 255, 120 / 255) or accent)
        self.barFill:SetPosition(PAD, y)
        self.barFill:SetSize(math.max(4, math.floor(inner * pct)), 6)
        Show(self.lblProgName, true); Show(self.lblProgress, true); Show(self.barBack, true); Show(self.barFill, true)
        y = y + 14
    else
        Show(self.lblProgName, false); Show(self.lblProgress, false); Show(self.barBack, false); Show(self.barFill, false)
    end
    -- marco a la medida
    local H = math.max(y + 6, 2 * R + 40)
    self:SetSize(W, H)
    self.tl:SetPosition(0, 0)
    self.tr:SetPosition(W - R, 0)
    self.bl:SetPosition(0, H - R)
    self.br:SetPosition(W - R, H - R)
    self.top:SetPosition(R, 0); self.top:SetSize(W - 2 * R, R)
    self.mid:SetPosition(0, R); self.mid:SetSize(W, H - 2 * R)
    self.bot:SetPosition(R, H - R); self.bot:SetSize(W - 2 * R, R)
    self.lineT:SetPosition(R, 0); self.lineT:SetSize(W - 2 * R, 1)
    self.lineB:SetPosition(R, H - 1); self.lineB:SetSize(W - 2 * R, 1)
    self.lineL:SetPosition(0, R); self.lineL:SetSize(1, H - 2 * R)
    self.lineR:SetPosition(W - 1, R); self.lineR:SetSize(1, H - 2 * R)
    self.accent:SetBackColor(accent)
    self.accent:SetPosition(1, R)
    self.accent:SetSize(4, H - 2 * R)
    -- al lado del mouse (sin salirse de la pantalla)
    local screenX, screenY = Turbine.UI.Display.GetMousePosition()
    local x, yy = screenX + 20, screenY + 20
    local maxX = Turbine.UI.Display.GetWidth() - W
    local maxY = Turbine.UI.Display.GetHeight() - H
    if x > maxX then x = screenX - W - 10 end
    if yy > maxY then yy = maxY end
    if x < 0 then x = 0 end
    if yy < 0 then yy = 0 end
    self:SetPosition(x, yy)
    self:SetVisible(true)
end

function QuestInfoTooltip:Hide()
    self:SetVisible(false)
    self.currentNdx = nil
end
