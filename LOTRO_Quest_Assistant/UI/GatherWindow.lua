-- LOTRO_Quest_Assistant/UI/GatherWindow.lua
-- Ventana "Recolección": elegís profesión, elegís zona (desplegable) y ves
-- el mapa REAL de esa zona (mismo mapa que usa MoorMap, tomado directo del
-- cliente de LOTRO) con un icono por cada punto guardado de la profesion
-- activa -- pedido explicito del usuario tras varias rondas de iteracion:
-- "estoy pidiendo que copies el sistema de moormap arquitectura y saques
-- los mapa de su fuente de addons junto a los iconos de los nodos de las
-- profesiones y la incorpores en nuestra ventana del addon".
--
-- HISTORIAL DE ARQUITECTURA (2026-08-23), de mas viejo a mas nuevo:
-- 1) Visor propio con imagenes .jpg chicas de Resources/Maps/ + marcadores
--    dibujados a mano (GatherMapView.lua) -- 6 rondas de prueba en vivo sin
--    lograr que el mapa/iconos/zoom se vieran. Eliminado.
-- 2) Lista de puntos + boton "Ir" que pinguea el mapa REAL de MoorMap (abre
--    su propia ventana aparte) -- funcionaba, pero el usuario aclaro que NO
--    queria que se abriera la ventana de MoorMap, sino ver el mapa DENTRO
--    de esta ventana.
-- 3) Mapa real embebido (Data/MoorMapZones.lua, 206 mapas reales extraidos
--    de GaranStuff/MoorMap/Defaults.lua -- imagen = ID de recurso NUMERICO
--    del propio cliente, confirmado con el uso real no comentado
--    "pcall(Turbine.UI.Window.SetBackground,mapWindow.Map,tmpMap)" de
--    MoorMap Main.lua linea 6517) a tamaño NATIVO, con iconos reales de
--    nodo (OreNode.tga/WoodNode.tga/ScholarNode.tga/Cook.tga, copiados a
--    Resources/ de este addon) y tooltip al pasar el mouse.
-- 4) ESTA VERSION: ventana redimensionable (SetResizable, igual que
--    QuestSyncWindow.lua) con el mapa en un VIEWPORT que recorta -- pedido
--    explicito del usuario: la ventana cambia de tamaño pero el mapa NUNCA
--    se achica (nada de SetScale/stretch, sigue a tamaño nativo real), en
--    su lugar se arrastra con el mouse (clic apretado + mover) para
--    centrar la parte que se quiera ver dentro del viewport mas chico.
--    self.mapViewport (tamaño = area visible, cambia con la ventana) recorta
--    a self.mapControl (tamaño = SIEMPRE nativo de la zona, nunca cambia),
--    que se reposiciona con el arrastre (self.panX/self.panY) en vez de
--    escalarse. RIESGO CONOCIDO (no confirmado en vivo todavia): esto
--    depende de que un Turbine.UI.Control recorte a los hijos mas grandes
--    que el -- no hay un ejemplo ya confirmado de esto en este addon
--    (evidencia indirecta: Turbine.UI.ListBox, que SI esta en esta base,
--    recorta filas fuera de su alto visible para poder scrollear -- pero
--    eso podria ser un mecanismo propio de ListBox, no necesariamente de
--    cualquier Control generico). Si el mapa se ve "desbordando" fuera de
--    su recuadro en vez de recortado, este es el supuesto a revisar primero.
--
-- BUG DE ZONA MAL RESUELTA (encontrado en esta misma sesion, ver historial
-- completo en Persistence/GatherPointsStore.lua): las cajas NS/EW de
-- Data/WarbandMapBounds.lua (usadas hasta la version anterior) eran
-- demasiado grandes/imprecisas -- un punto cerca de Bree se guardaba como
-- "Eryn Lasgalen and the Dale-lands". Ahora la zona se resuelve contra los
-- 206 mapas reales de MoorMap (Core/MoorMapZoneResolver.lua, prefiere el de
-- mayor tier/zoom que realmente contiene la coordenada) -- mucho mas preciso.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}

LQA.UI.GatherWindow = class(Turbine.UI.Lotro.Window)

local RES_BASE = "LOTRO_Quest_Assistant/Resources/"
local CONTENT_TOP = 40
local WINDOW_W_MIN = 620
local WINDOW_H_MIN_EXTRA = 150 -- alto minimo del viewport de mapa
-- Achicado de 24 a 16 (2026-09-07, pedido del usuario tras confirmar que el
-- guardado ya funciona bien) -- con el mapa a tamano nativo los iconos de 24
-- tapaban demasiado detalle del mapa real.
local MARKER_SIZE = 16
local ROW_HEIGHT = 30

local PROFESSIONS = {
    { key = "MINERO", label = "Minero", icon = RES_BASE .. "OreNode.tga" },
    { key = "LEÑADOR", label = "Leñador", icon = RES_BASE .. "WoodNode.tga" },
    { key = "GRANJERO", label = "Granjero", icon = RES_BASE .. "Cook.tga" },
    { key = "ERUDITO", label = "Erudito", icon = RES_BASE .. "ScholarNode.tga" },
}
local ICON_BY_PROFESSION = {}
for _, p in ipairs(PROFESSIONS) do ICON_BY_PROFESSION[p.key] = p.icon end

function LQA.UI.GatherWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    local zoneRowTop = CONTENT_TOP + 34
    self.mapTop = zoneRowTop + 34

    self:SetPosition(120, 80)
    self:SetSize(WINDOW_W_MIN, self.mapTop + 220)
    self:SetText("Recolección")
    self:SetVisible(false)

    -- SFX de "abrir ventana" RETIRADO (pedido explicito del usuario,
    -- 2026-09-03): Turbine.PluginData.Save no escribe al instante -- tarda
    -- entre ~2 y ~15s segun un ciclo propio del cliente (confirmado en vivo,
    -- ver la nota grande en NarratorBridge.lua) -- un sonido de "click"
    -- que puede tardar hasta 15s no cumple ningun proposito de feedback
    -- inmediato, asi que se saca en vez de dejarlo sonando fuera de tiempo.
    -- Redimensionable como el resto de las ventanas del addon (mismo
    -- mecanismo real que QuestSyncWindow.lua: SetResizable + SetMinimumSize
    -- + SizeChanged, confirmado en produccion).
    self:SetResizable(true)
    self:SetMinimumSize(WINDOW_W_MIN, self.mapTop + WINDOW_H_MIN_EXTRA)

    self.currentProfession = "MINERO"
    self.currentZoneIdx = nil
    self.zoneW, self.zoneH = nil, nil
    self.panX, self.panY = 0, 0
    self.dragging = false

    -- REDISEÑO VISUAL "libro" (2026-08-28, pedido explicito del usuario,
    -- mismo criterio que QuestBookWindow.lua/QuestTrackerHUD.lua): panel de
    -- fondo tibio SOLO detras de la fila de pestañas/selector de zona --
    -- deliberadamente NO cubre self.mapViewport/self.mapControl, para no
    -- interferir con el mapa real ni con el mecanismo de arrastre (marcado
    -- como riesgo conocido sin confirmar en vivo mas abajo en este mismo
    -- archivo) -- se redimensiona el ANCHO en SizeChanged, el alto es fijo
    -- (termina justo donde empieza el mapa).
    self.pageBg = Turbine.UI.Control()
    self.pageBg:SetParent(self)
    self.pageBg:SetPosition(0, CONTENT_TOP - 10)
    self.pageBg:SetSize(WINDOW_W_MIN, self.mapTop - (CONTENT_TOP - 10))
    self.pageBg:SetBackColor(Turbine.UI.Color(0.10, 0.08, 0.05))
    self.pageBg:SetMouseVisible(false)

    -- Selector de profesion: mismo patron de botones-pestaña que ya usa
    -- QuestSyncWindow.lua (SetEnabled(false) en el activo para que se vea
    -- "presionado").
    self.profButtons = {}
    local tabX = 20
    for _, prof in ipairs(PROFESSIONS) do
        local btn = Turbine.UI.Lotro.Button()
        btn:SetParent(self)
        btn:SetPosition(tabX, CONTENT_TOP)
        btn:SetSize(140, 26)
        btn:SetText(prof.label)
        btn.profKey = prof.key
        btn.MouseClick = function()
            self:SelectProfession(prof.key)
        end
        self.profButtons[prof.key] = btn
        tabX = tabX + 142
    end

    -- Selector de zona: boton que despliega una lista de TODAS las zonas
    -- con puntos guardados para la profesion activa.
    self.btnZone = Turbine.UI.Lotro.Button()
    self.btnZone:SetParent(self)
    self.btnZone:SetPosition(20, zoneRowTop)
    self.btnZone:SetSize(WINDOW_W_MIN - 40, 28)
    self.btnZone:SetText("Elegí una zona...")
    self.btnZone.MouseClick = function() self:ToggleZoneFlyout() end

    -- El flyout es un Control simple, hijo de esta misma ventana -- se
    -- mueve solo junto con la ventana, sin sincronizacion manual.
    self.zoneFlyout = Turbine.UI.Control()
    self.zoneFlyout:SetParent(self)
    self.zoneFlyout:SetPosition(20, zoneRowTop + 30)
    self.zoneFlyout:SetSize(WINDOW_W_MIN - 40, 4)
    self.zoneFlyout:SetBackColor(Turbine.UI.Color(1, 0.12, 0.12, 0.18))
    self.zoneFlyout:SetVisible(false)
    self.zoneFlyout:SetZOrder(50)

    self.zoneFlyoutBorder = Turbine.UI.Control()
    self.zoneFlyoutBorder:SetParent(self.zoneFlyout)
    self.zoneFlyoutBorder:SetPosition(0, 0)
    self.zoneFlyoutBorder:SetSize(WINDOW_W_MIN - 40, 2)
    self.zoneFlyoutBorder:SetBackColor(Turbine.UI.Color(0.80, 0.63, 0.22))

    self.zoneListBox = Turbine.UI.ListBox()
    self.zoneListBox:SetParent(self.zoneFlyout)
    self.zoneListBox:SetPosition(0, 0)
    self.zoneListBox:SetSize(WINDOW_W_MIN - 56, 4)

    self.zoneScrollBar = Turbine.UI.Lotro.ScrollBar()
    self.zoneScrollBar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.zoneScrollBar:SetParent(self.zoneFlyout)
    self.zoneScrollBar:SetPosition(WINDOW_W_MIN - 50, 0)
    self.zoneScrollBar:SetSize(10, 4)
    self.zoneListBox:SetVerticalScrollBar(self.zoneScrollBar)

    -- Viewport: tamaño = area visible del mapa, cambia con la ventana (ver
    -- SizeChanged mas abajo). Es el que RECORTA -- ver riesgo conocido en
    -- el historial arriba.
    self.mapViewport = Turbine.UI.Control()
    self.mapViewport:SetParent(self)
    self.mapViewport:SetPosition(20, self.mapTop)
    self.mapViewport:SetSize(WINDOW_W_MIN - 40, 200)
    -- SIN SetMouseVisible(false) -- mismo motivo que self.mapControl mas
    -- abajo: bloquearia el arrastre de su hijo (mapControl) y el hover de
    -- sus nietos (marcadores), sin un precedente confirmado en este addon
    -- de que un hijo reciba eventos de mouse con el padre inmediato en false.

    -- Mapa real -- SIEMPRE a tamaño NATIVO de la zona (nunca se achica),
    -- hijo del viewport, reposicionado por el arrastre (self.panX/panY) en
    -- vez de escalado. Sin SetMouseVisible(false): recibe el arrastre
    -- (MouseDown/Move/Up mas abajo) y sus marcadores hijos necesitan
    -- MouseHover/MouseLeave para el tooltip.
    self.mapControl = Turbine.UI.Control()
    self.mapControl:SetParent(self.mapViewport)
    self.mapControl:SetPosition(0, 0)
    self.mapControl:SetSize(WINDOW_W_MIN - 40, 200)

    -- Arrastrar para centrar (clic apretado + mover) -- pedido explicito
    -- del usuario. args.X/args.Y son relativos a self.mapControl (mismo
    -- patron confirmado en GaranStuff/MoorMap/Main.lua mapWindow.Map.
    -- MouseMove, que usa args.X/Y como coordenadas de pixel dentro del
    -- control). Se calcula por DELTA contra la posicion del mouse al
    -- iniciar el arrastre, no la posicion absoluta -- evita que el mapa
    -- "salte" al primer movimiento.
    self.mapControl.MouseDown = function(sender, args)
        self.dragging = true
        self.dragStartMouseX = args.X
        self.dragStartMouseY = args.Y
        self.dragStartPanX = self.panX
        self.dragStartPanY = self.panY
    end
    self.mapControl.MouseMove = function(sender, args)
        if self.dragging then
            self.panX = self.dragStartPanX + (args.X - self.dragStartMouseX)
            self.panY = self.dragStartPanY + (args.Y - self.dragStartMouseY)
            self:ClampPan()
            self:ApplyPan()
        end
    end
    self.mapControl.MouseUp = function(sender, args)
        self.dragging = false
    end
    -- Salvaguarda: si el mouse sale del control mientras se arrastra (sin
    -- confirmar si este SDK mantiene la "captura" del mouse fuera de los
    -- limites del control durante un arrastre, ver MoorMap Main.lua
    -- mapWindow.BorderTop.MouseMove/mapWindow.Moving), se corta el
    -- arrastre en vez de arriesgar que quede "pegado" para siempre.
    self.mapControl.MouseLeave = function()
        self.dragging = false
    end

    self.lblEmpty = Turbine.UI.Label()
    self.lblEmpty:SetParent(self.mapViewport)
    self.lblEmpty:SetPosition(0, 0)
    self.lblEmpty:SetSize(WINDOW_W_MIN - 40, 40)
    self.lblEmpty:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiquaBold14)
    self.lblEmpty:SetForeColor(Turbine.UI.Color(0.6, 0.6, 0.6))
    self.lblEmpty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.lblEmpty:SetMultiline(true)
    self.lblEmpty:SetMouseVisible(false)
    self.lblEmpty:SetText("Sin puntos guardados todavía para esta profesión")
    self.lblEmpty:SetVisible(true)

    self.markers = {}

    if LQA and LQA.Core and LQA.Core.EventBus then
        LQA.Core.EventBus:Subscribe("GATHER_POINT_ADDED", function(data)
            if data and data.profession == self.currentProfession then
                self:RefreshZoneList()
            end
        end)
        LQA.Core.EventBus:Subscribe("GATHER_POINT_UPDATED", function(data)
            if data and data.profession == self.currentProfession then
                self:RefreshZoneList()
            end
        end)
        -- Interruptor de idioma (mismo patron que QuestTrackerHUD.lua) --
        -- reconstruye el flyout/etiqueta de zona con el nombre de zona en
        -- el idioma nuevo (ver MoorMapZoneResolver.DisplayName).
        LQA.Core.EventBus:Subscribe("LANGUAGE_CHANGED", function()
            self:RefreshZoneList()
        end)
    end

    -- SizeChanged: mismo patron real de QuestSyncWindow.lua (definir la
    -- funcion y despues llamarla una vez a mano para el layout inicial --
    -- la asignacion sola no dispara el evento).
    self.SizeChanged = function()
        local w, h = self:GetSize()
        if not w or not h then return end
        self.pageBg:SetWidth(w)
        self.btnZone:SetWidth(w - 40)
        local viewportW = w - 40
        local viewportH = h - self.mapTop - 20
        if viewportH < 100 then viewportH = 100 end
        self.mapViewport:SetSize(viewportW, viewportH)
        self.lblEmpty:SetSize(viewportW, 40)
        self.lblEmpty:SetPosition(0, math.floor((viewportH - 40) / 2))
        self:ClampPan()
        self:ApplyPan()
    end
    self.SizeChanged()

    self:SelectProfession(self.currentProfession)
end

-- Ajusta self.panX/panY para que el mapa nunca deje ver espacio en blanco
-- dentro del viewport (a menos que el mapa sea mas chico que el viewport en
-- ese eje, en cuyo caso se centra en vez de dejarlo pegado a un borde).
function LQA.UI.GatherWindow:ClampPan()
    local vw, vh = self.mapViewport:GetSize()
    local mw, mh = self.zoneW or vw, self.zoneH or vh

    if mw <= vw then
        self.panX = math.floor((vw - mw) / 2)
    else
        if self.panX > 0 then self.panX = 0 end
        if self.panX < vw - mw then self.panX = vw - mw end
    end

    if mh <= vh then
        self.panY = math.floor((vh - mh) / 2)
    else
        if self.panY > 0 then self.panY = 0 end
        if self.panY < vh - mh then self.panY = vh - mh end
    end
end

function LQA.UI.GatherWindow:ApplyPan()
    self.mapControl:SetPosition(self.panX, self.panY)
end

-- Centra el pan inicial en el promedio de los marcadores guardados (si hay)
-- -- asi la primera vista al elegir una zona ya muestra los puntos en vez
-- de la esquina superior izquierda del mapa. Sin marcadores, centra el
-- mapa entero.
function LQA.UI.GatherWindow:CenterPanOn(px, py)
    local vw, vh = self.mapViewport:GetSize()
    self.panX = math.floor(vw / 2 - px)
    self.panY = math.floor(vh / 2 - py)
    self:ClampPan()
    self:ApplyPan()
end

function LQA.UI.GatherWindow:SelectProfession(profKey)
    self.currentProfession = profKey
    self.currentZoneIdx = nil
    for key, btn in pairs(self.profButtons) do
        btn:SetEnabled(key ~= profKey)
    end
    self:SetZoneFlyoutVisible(false)
    self:RefreshZoneList()
end

function LQA.UI.GatherWindow:RefreshZoneList()
    self.zoneList = (_G.GatherPointsStore and GatherPointsStore.GetMapsWithPoints(self.currentProfession)) or {}

    if self.currentZoneIdx == nil or self:FindZoneEntry(self.currentZoneIdx) == nil then
        self.currentZoneIdx = self.zoneList[1] and self.zoneList[1].zoneIdx or nil
    end

    -- RefreshMap() PRIMERO -- BuildZoneFlyout() lee self:GetWidth() para
    -- dimensionarse a si mismo, y aunque ya no dependa del tamaño del mapa
    -- (la ventana no se auto-redimensiona mas), mantiene el mismo orden por
    -- las dudas/consistencia.
    self:RefreshMap()
    self:BuildZoneFlyout()
end

function LQA.UI.GatherWindow:FindZoneEntry(zoneIdx)
    if self.zoneList == nil then return nil end
    for _, entry in ipairs(self.zoneList) do
        if entry.zoneIdx == zoneIdx then return entry end
    end
    return nil
end

function LQA.UI.GatherWindow:SetZoneFlyoutVisible(visible)
    self.zoneFlyout:SetVisible(visible)
    -- Se oculta el mapa mientras el flyout esta abierto -- estan casi en la
    -- misma posicion Y y el mapa (con fondo propio) podia pintar encima del
    -- flyout sin importar SetZOrder.
    self.mapViewport:SetVisible(not visible)
end

function LQA.UI.GatherWindow:ToggleZoneFlyout()
    self:SetZoneFlyoutVisible(not self.zoneFlyout:IsVisible())
end

function LQA.UI.GatherWindow:BuildZoneFlyout()
    self.zoneListBox:ClearItems()

    local count = (self.zoneList and #self.zoneList) or 0
    local visibleRows = count
    if visibleRows < 1 then visibleRows = 1 end
    if visibleRows > 7 then visibleRows = 7 end
    local flyoutH = visibleRows * ROW_HEIGHT
    local w = self:GetWidth()
    self.zoneFlyout:SetSize(w - 40, flyoutH)
    self.zoneListBox:SetSize(w - 56, flyoutH)
    self.zoneScrollBar:SetSize(10, flyoutH)

    if count == 0 then
        local row = Turbine.UI.Control()
        row:SetSize(w - 56, ROW_HEIGHT)
        local lbl = Turbine.UI.Label()
        lbl:SetParent(row)
        lbl:SetPosition(6, 0)
        lbl:SetSize(w - 68, ROW_HEIGHT)
        lbl:SetFont(Turbine.UI.Lotro.Font.Verdana12)
        lbl:SetForeColor(Turbine.UI.Color(0.6, 0.6, 0.6))
        lbl:SetText("Sin puntos guardados todavía para esta profesión")
        self.zoneListBox:AddItem(row)
        return
    end

    for _, entry in ipairs(self.zoneList) do
        local row = Turbine.UI.Control()
        row:SetSize(w - 56, ROW_HEIGHT)

        local lbl = Turbine.UI.Label()
        lbl:SetParent(row)
        lbl:SetPosition(6, 0)
        lbl:SetSize(w - 68, ROW_HEIGHT)
        lbl:SetFont(Turbine.UI.Lotro.Font.Verdana12)
        lbl:SetForeColor(entry.zoneIdx == self.currentZoneIdx and Turbine.UI.Color.Yellow or Turbine.UI.Color.White)
        local displayName = _G.MoorMapZoneResolver and MoorMapZoneResolver.DisplayName(entry.name) or entry.name
        lbl:SetText(tostring(displayName) .. "  (" .. tostring(entry.count) .. ")")

        local function pick()
            self.currentZoneIdx = entry.zoneIdx
            self:SetZoneFlyoutVisible(false)
            self:RefreshMap()
            self:BuildZoneFlyout()
        end
        row.MouseClick = pick
        lbl.MouseClick = pick

        self.zoneListBox:AddItem(row)
    end
end

function LQA.UI.GatherWindow:ClearMarkers()
    for _, marker in ipairs(self.markers) do
        marker:SetParent(nil)
    end
    self.markers = {}
end

-- Redibuja el mapa real de la zona elegida (imagen nativa de MoorMap, NUNCA
-- escalada) y un icono por cada punto guardado, filtrado por la profesion
-- activa. La ventana/viewport NO cambian de tamaño aca -- eso lo controla
-- el usuario arrastrando el borde de la ventana (ver SizeChanged).
function LQA.UI.GatherWindow:RefreshMap()
    self:ClearMarkers()

    local entry = self:FindZoneEntry(self.currentZoneIdx)
    if entry == nil then
        self.btnZone:SetText("Elegí una zona...")
        self.mapControl:SetBackground(nil)
        self.zoneW, self.zoneH = nil, nil
        self.lblEmpty:SetText("Sin puntos guardados todavía para esta profesión")
        self.lblEmpty:SetVisible(true)
        self:ClampPan()
        self:ApplyPan()
        return
    end

    local zone = _G.MoorMapZoneResolver and MoorMapZoneResolver.GetByIdx(entry.zoneIdx)
    if zone == nil then
        self.lblEmpty:SetText("No se encontró el mapa para esta zona.")
        self.lblEmpty:SetVisible(true)
        return
    end

    local zoneDisplayName = MoorMapZoneResolver.DisplayName(entry.name)
    self.btnZone:SetText(tostring(zoneDisplayName) .. "  (" .. tostring(entry.count) .. " puntos)")
    self.lblEmpty:SetVisible(false)

    -- Tamaño SIEMPRE nativo real de esta zona (la mayoria 1024x768, algunas
    -- 1600x1200) -- sin SetScale/stretch, mismo criterio ya probado en este
    -- addon (mostrar a tamaño nativo evita el mosaico que ya rompio el mapa
    -- una vez con imagenes mas chicas). Lo que cambia con el tamaño de
    -- ventana es el VIEWPORT que lo recorta, no el mapa en si.
    self.zoneW, self.zoneH = zone.width, zone.height
    self.mapControl:SetSize(self.zoneW, self.zoneH)
    -- pcall -- mismo criterio que el propio MoorMap usa para esta llamada
    -- (Main.lua linea 6517/6541, "pcall(Turbine.UI.Window.SetBackground,
    -- mapWindow.Map, tmpMap)") -- ni MoorMap confia en que el ID de recurso
    -- numerico siempre resuelva bien (puede depender de que expansion tenga
    -- el jugador), asi que esto tampoco deberia dejar tirar un error sin
    -- atrapar si llega a fallar.
    pcall(Turbine.UI.Control.SetBackground, self.mapControl, zone.image)

    local icon = ICON_BY_PROFESSION[self.currentProfession]
    local points = GatherPointsStore.GetPoints(self.currentProfession, entry.zoneIdx)
    local sumX, sumY, n = 0, 0, 0
    for _, point in ipairs(points) do
        local px, py = MoorMapZoneResolver.ToPixel(zone, point.ns, point.ew)
        if px ~= nil then
            local marker = Turbine.UI.Label()
            marker:SetParent(self.mapControl)
            marker:SetSize(MARKER_SIZE, MARKER_SIZE)
            marker:SetPosition(px - (MARKER_SIZE / 2), py - (MARKER_SIZE / 2))
            -- BlendMode.Overlay -- MISMO tratamiento que MoorMap le da a
            -- CUALQUIER icono .tga chico dibujado encima de otra cosa
            -- (confirmado en su propio codigo real: Overlays/RT/Script.lua
            -- linea 623 "tmpHotSpot:SetBlendMode(Turbine.UI.BlendMode.
            -- Overlay)" para sus iconos de amenaza sobre el mapa, y varios
            -- mas en Main.lua/AnnotationsWindow.lua) -- sin esto el canal
            -- alpha del .tga no compone bien (bug visual reportado en vivo:
            -- el icono se veia, pero con un recuadro/artefacto alrededor).
            marker:SetBlendMode(Turbine.UI.BlendMode.Overlay)
            marker:SetBackground(icon)

            -- Tooltip al pasar el mouse (pedido explicito del usuario,
            -- ver UI/GatherNodeTooltip.lua) -- por eso el marcador SI
            -- necesita recibir eventos de mouse aca (a diferencia del
            -- resto de los controles de esta ventana, que los tienen
            -- deshabilitados a proposito).
            --
            -- REVERTIDO (2026-09-07): se probaron 2 variantes de "resaltado
            -- al pasar el mouse" (halo con Control separado, y agrandar el
            -- propio icono) -- ambas terminaron rompiendo que se vieran
            -- otros iconos guardados en el mapa. El usuario pidio volver
            -- exactamente al punto en que confirmo que todo funcionaba bien
            -- (icono de MARKER_SIZE fijo, solo tooltip, sin ningun efecto
            -- de hover visual) -- no se reintenta el resaltado por ahora.
            local tooltipText = tostring(point.node) .. " (tier " .. tostring(point.tier) .. ")"
            marker.MouseHover = function()
                GatherNodeTooltip.GetInstance():ShowFor(tooltipText)
            end
            marker.MouseLeave = function()
                GatherNodeTooltip.GetInstance():Hide()
            end

            table.insert(self.markers, marker)
            sumX = sumX + px
            sumY = sumY + py
            n = n + 1
        end
    end

    -- Centra la vista inicial en el promedio de los puntos guardados (si
    -- hay) en vez de dejar la esquina superior izquierda del mapa -- el
    -- usuario despues puede arrastrar a donde quiera.
    if n > 0 then
        self:CenterPanOn(sumX / n, sumY / n)
    else
        self:CenterPanOn(self.zoneW / 2, self.zoneH / 2)
    end
end
