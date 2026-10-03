-- LOTRO_Quest_Assistant/UI/ChestsWindow.lua
-- Ventana con pestañas, estructura y mapas visuales identicos a WarbandsSlayer
-- 5.9.1 (misma referencia visual que "Points d'Interet", ver full3529.jpg en
-- la carpeta del proyecto). La imagen de referencia trae 5 pestañas (Cartas /
-- Tropas y Amenazas / Puntos de Interes / Puntos de Clase / Granjeo), pero
-- solo quedan las 2 con datos reales y utiles (Puntos de Interes, Tropas y
-- Amenazas) -- Cartas/Puntos de Clase nunca tuvieron datos en la fuente, y
-- Granjeo se saco tambien porque solo 8 de sus 34 entradas traian coordenada
-- (se sentia vacia igual que las otras). Ver TABS mas abajo para agregar
-- alguna de vuelta si en el futuro aparecen datos completos.
-- Sinergia agregada por QuestSync: cada punto tiene sus propios botones
-- "Mapa"/"Ruta" que usan el MoorMapAdapter/WaypointAdapter ya existentes, no
-- un sistema aparte.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.ChestsWindow = class(Turbine.UI.Lotro.Window)

local CONTENT_TOP = 40
local MAP_W, MAP_H = 300, 200
local RES_BASE = "LOTRO_Quest_Assistant/Resources/"

local TABS = {
    { key = "puntos", label = "Puntos de Interes", db = "ChestsDB", icon = RES_BASE .. "chest.jpg" },
    { key = "tropas", label = "Tropas y Amenazas", db = "ThreatsDB", icon = RES_BASE .. "threat.tga" },
}

-- Nombre + icono de cada tipo de recompensa (RewardsEn.lua de WarbandsSlayer).
-- No se copiaron los iconos .jpg propios de cada recompensa (serian muchos
-- assets mas solo para esto) -- se muestra el nombre traducido, sin icono.
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

-- Misma formula que MiniMapViewer:ComputeDynCoords de WarbandsSlayer: cada
-- mapa tiene una caja delimitadora en coordenadas NS/EW (WarbandMapBounds.lua,
-- extraida de su propia tabla MapsData) y la imagen base es siempre 300x200px
-- -- de ahi sale cuantas unidades de coordenada representa cada pixel.
local function ParseWbCoord(c)
    local y, dirY, x, dirX = string.match(c, "([%d%.]+)%s*([NSns]),%s*([%d%.]+)%s*([EWew])")
    if not y then return nil end
    local cy = tonumber(y)
    local cx = tonumber(x)
    if dirY == "N" or dirY == "n" then cy = -cy end
    if dirX ~= "E" and dirX ~= "e" then cx = -cx end
    return cx, cy
end

-- nameES/raceES: traduccion profesional al espanol via el mismo puente
-- id-a-id de LotRO Companion (labels/es/*) usado en toda la base de datos
-- de QuestSync -- no toda cacceria/jefe tiene traduccion disponible (nombre
-- propio sin entrada exacta en las 44 categorias de etiquetas), por eso el
-- respaldo al nombre en ingles, mismo patron que QuestLocResolver.
local function DisplayName(entry)
    return entry.nameES or entry.name
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

function ChestsWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetPosition(140, 100)
    self:SetSize(700, 680)
    self:SetText("QuestSync - Puntos de Interes")

    -- SFX de "abrir ventana" RETIRADO (pedido explicito del usuario,
    -- 2026-09-03) -- ver la nota grande en NarratorBridge.lua.

    -- ===== Barra de pestañas (misma estructura que la imagen de referencia) =====
    self.tabButtons = {}
    local tabX = 20
    for _, tab in ipairs(TABS) do
        local btn = Turbine.UI.Lotro.Button()
        btn:SetParent(self)
        btn:SetPosition(tabX, CONTENT_TOP)
        btn:SetSize(150, 26)
        btn:SetText(tab.label)
        btn.tabKey = tab.key
        btn.MouseClick = function()
            self:SelectTab(tab.key)
        end
        self.tabButtons[tab.key] = btn
        tabX = tabX + 154
    end

    local listTop = CONTENT_TOP + 40

    self.lblPlaceholder = Turbine.UI.Label()
    self.lblPlaceholder:SetParent(self)
    self.lblPlaceholder:SetPosition(20, listTop + 40)
    self.lblPlaceholder:SetSize(640, 40)
    self.lblPlaceholder:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
    self.lblPlaceholder:SetForeColor(Turbine.UI.Color(0.7, 0.7, 0.7))
    self.lblPlaceholder:SetText("Esta pestaña todavía no está lista.")
    self.lblPlaceholder:SetVisible(false)

    -- ===== Columna izquierda: lista de la pestaña activa, agrupada por zona =====
    self.listContainer = Turbine.UI.Control()
    self.listContainer:SetParent(self)
    self.listContainer:SetPosition(20, listTop)
    self.listContainer:SetSize(270, 680 - listTop - 20)

    self.listBox = Turbine.UI.ListBox()
    self.listBox:SetParent(self.listContainer)
    self.listBox:SetPosition(0, 0)
    self.listBox:SetSize(250, 680 - listTop - 20)

    self.scrollBar = Turbine.UI.Lotro.ScrollBar()
    self.scrollBar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.scrollBar:SetParent(self.listContainer)
    self.scrollBar:SetPosition(255, 0)
    self.scrollBar:SetSize(10, 680 - listTop - 20)
    self.listBox:SetVerticalScrollBar(self.scrollBar)

    -- ===== Columna derecha: detalle + mapa + puntos + recompensas =====
    self.detailBox = Turbine.UI.Control()
    self.detailBox:SetParent(self)
    self.detailBox:SetPosition(310, listTop)
    self.detailBox:SetSize(360, 680 - listTop - 20)

    self.lblTitle = Turbine.UI.Label()
    self.lblTitle:SetParent(self.detailBox)
    self.lblTitle:SetPosition(0, 0)
    self.lblTitle:SetSize(360, 22)
    self.lblTitle:SetFont(Turbine.UI.Lotro.Font.TrajanPro16)
    self.lblTitle:SetText("Selecciona un elemento de la lista")

    self.lblLevel = Turbine.UI.Label()
    self.lblLevel:SetParent(self.detailBox)
    self.lblLevel:SetPosition(0, 24)
    self.lblLevel:SetSize(360, 16)
    self.lblLevel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    self.lblLevel:SetForeColor(Turbine.UI.Color(0.8, 0.8, 0.8))
    self.lblLevel:SetText("")

    -- Mapa interno, identico visualmente a WarbandsSlayer: la misma imagen
    -- de fondo (resources/maps/*.jpg, copiada a Resources/Maps/) con los
    -- marcadores superpuestos en su posicion exacta.
    --
    -- BUG (reportado 2026-08-18): se usaba Turbine.UI.Control para el mapa y
    -- los marcadores -- SetBackground con una ruta de archivo (imagen) solo
    -- funciona de forma confiable sobre Turbine.UI.Label en este SDK
    -- (confirmado revisando WarbandsSlayer/MoorMap: CADA uso de
    -- SetBackground("ruta/archivo.jpg") en su codigo esta sobre una Label,
    -- nunca sobre un Control -- un Control con imagen de fondo se ve negro,
    -- que es exactamente lo que se reporto). Cambiado a Label en los 2 sitios.
    self.mapImage = Turbine.UI.Label()
    self.mapImage:SetParent(self.detailBox)
    self.mapImage:SetPosition(30, 44)
    self.mapImage:SetSize(MAP_W, MAP_H)
    self.mapImage:SetMouseVisible(false)
    self.mapMarkers = {}

    self.lblPointsHeader = Turbine.UI.Label()
    self.lblPointsHeader:SetParent(self.detailBox)
    self.lblPointsHeader:SetPosition(0, 44 + MAP_H + 10)
    self.lblPointsHeader:SetSize(360, 16)
    self.lblPointsHeader:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
    self.lblPointsHeader:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.6))
    self.lblPointsHeader:SetText("Puntos:")
    self.lblPointsHeader:SetVisible(false)

    local pointsTop = 44 + MAP_H + 30
    local pointsHeight = 130
    self.pointsContainer = Turbine.UI.Control()
    self.pointsContainer:SetParent(self.detailBox)
    self.pointsContainer:SetPosition(0, pointsTop)
    self.pointsContainer:SetSize(360, pointsHeight)

    self.pointsList = Turbine.UI.ListBox()
    self.pointsList:SetParent(self.pointsContainer)
    self.pointsList:SetPosition(0, 0)
    self.pointsList:SetSize(340, pointsHeight)

    self.pointsScroll = Turbine.UI.Lotro.ScrollBar()
    self.pointsScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.pointsScroll:SetParent(self.pointsContainer)
    self.pointsScroll:SetPosition(345, 0)
    self.pointsScroll:SetSize(10, pointsHeight)
    self.pointsList:SetVerticalScrollBar(self.pointsScroll)

    -- Recompensas: la imagen de referencia trae una seccion desplegable
    -- "Recompensas" debajo del mapa/puntos -- se muestran en texto (no se
    -- copiaron los iconos .jpg propios de cada tipo de recompensa, serian
    -- ~15 assets mas solo para esto).
    local rewardsTop = pointsTop + pointsHeight + 10
    self.lblRewardsHeader = Turbine.UI.Label()
    self.lblRewardsHeader:SetParent(self.detailBox)
    self.lblRewardsHeader:SetPosition(0, rewardsTop)
    self.lblRewardsHeader:SetSize(360, 16)
    self.lblRewardsHeader:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
    self.lblRewardsHeader:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.6))
    self.lblRewardsHeader:SetText("Recompensas:")
    self.lblRewardsHeader:SetVisible(false)

    self.rewardsContainer = Turbine.UI.Control()
    self.rewardsContainer:SetParent(self.detailBox)
    self.rewardsContainer:SetPosition(0, rewardsTop + 18)
    self.rewardsContainer:SetSize(360, (680 - listTop - 20) - (rewardsTop + 18))
    self.rewardLabels = {}

    self:SelectTab("puntos")
end

function ChestsWindow:SelectTab(key)
    -- SFX de "cambio de pestaña" RETIRADO (pedido explicito del usuario,
    -- 2026-09-03) -- ver la nota grande en NarratorBridge.lua.
    self.activeTab = key
    for k, btn in pairs(self.tabButtons) do
        btn:SetEnabled(k ~= key)
    end

    local tabDef = nil
    for _, t in ipairs(TABS) do
        if t.key == key then tabDef = t end
    end
    self.activeIcon = tabDef and tabDef.icon

    local db = tabDef and tabDef.db and _G[tabDef.db]
    local isReady = db ~= nil

    self.listContainer:SetVisible(isReady)
    self.detailBox:SetVisible(isReady)
    self.lblPlaceholder:SetVisible(not isReady)

    self.collapsedZones = self.collapsedZones or {}

    if isReady then
        self:PopulateList(db)
        self:ClearDetail()
    end
end

function ChestsWindow:ClearDetail()
    self.lblTitle:SetText("Selecciona un elemento de la lista")
    self.lblLevel:SetText("")
    self:ClearMapMarkers()
    self.pointsList:ClearItems()
    self.lblPointsHeader:SetVisible(false)
    self.mapImage:SetVisible(false)
    self:ClearRewards()
    self.lblRewardsHeader:SetVisible(false)
end

function ChestsWindow:ClearRewards()
    for _, lbl in ipairs(self.rewardLabels) do
        lbl:SetParent(nil)
    end
    self.rewardLabels = {}
end

-- Normaliza los formatos de datos (cofres con groups={{map,coords}},
-- amenazas con map+coords directo) a una lista comun de {map, coords}.
local function GetGroupsFor(entry)
    if entry.groups then return entry.groups end
    if entry.map then return { { map = entry.map, coords = entry.coords } } end
    return {}
end

-- Lista agrupada por zona con filas desplegables, igual que "Les
-- profondeurs de Gundabad {11}" en la imagen de referencia: un encabezado
-- por zona con la cantidad entre llaves, clickeable para mostrar/ocultar
-- sus elementos (colapsada por defecto -- 45 zonas con todo expandido de
-- una seria demasiada lista para desplazarse).
function ChestsWindow:PopulateList(db)
    self.listBox:ClearItems()

    local byZone = {}
    local zoneOrder = {}
    for _, e in ipairs(db) do
        local zone = (e.zone and e.zone ~= "") and e.zone or "Sin zona"
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

        local collapsed = self.collapsedZones[zone]
        if collapsed == nil then collapsed = true end

        local header = Turbine.UI.Control()
        header:SetSize(250, 24)

        local hLbl = Turbine.UI.Label()
        hLbl:SetParent(header)
        hLbl:SetPosition(0, 0)
        hLbl:SetSize(250, 24)
        hLbl:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
        hLbl:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.6))
        hLbl:SetText((collapsed and "+ " or "- ") .. zone .. "  {" .. #zoneEntries .. "}")

        header.MouseClick = function()
            self.collapsedZones[zone] = not collapsed
            self:PopulateList(db)
        end
        hLbl.MouseClick = header.MouseClick

        self.listBox:AddItem(header)

        if not collapsed then
            for _, entry in ipairs(zoneEntries) do
                local item = Turbine.UI.Control()
                item:SetSize(250, 30)

                local icon = Turbine.UI.Label()
                icon:SetParent(item)
                icon:SetPosition(14, 3)
                icon:SetSize(16, 16)
                if self.activeIcon then icon:SetBackground(self.activeIcon) end
                icon:SetMouseVisible(false)

                local lbl = Turbine.UI.Label()
                lbl:SetParent(item)
                lbl:SetPosition(34, 0)
                lbl:SetSize(216, 30)
                lbl:SetForeColor(Turbine.UI.Color(0.8, 0.7, 0.4))
                local levelTag = entry.level and ("[" .. tostring(entry.level) .. "] ") or ""
                lbl:SetText(levelTag .. tostring(DisplayName(entry)))

                item.MouseClick = function()
                    self:SelectEntry(entry)
                end
                lbl.MouseClick = item.MouseClick
                icon.MouseClick = item.MouseClick

                self.listBox:AddItem(item)
            end
        end
    end
end

function ChestsWindow:ClearMapMarkers()
    for _, marker in ipairs(self.mapMarkers) do
        marker:SetParent(nil)
    end
    self.mapMarkers = {}
end

function ChestsWindow:SelectEntry(entry)
    local esName = DisplayName(entry)
    self.lblTitle:SetText(esName)
    local levelLine = entry.level and ("Nivel: " .. tostring(entry.level)) or ""
    if entry.zone and entry.zone ~= "" then levelLine = levelLine .. "  |  " .. entry.zone end
    if entry.race and entry.race ~= "" then levelLine = levelLine .. "  |  " .. (entry.raceES or entry.race) end
    self.lblLevel:SetText(levelLine)

    self:ClearMapMarkers()
    self.pointsList:ClearItems()
    self:ClearRewards()

    local groups = GetGroupsFor(entry)
    local group = groups[1]
    local bounds = group and WarbandMapBounds and WarbandMapBounds[group.map]

    if group and group.map then
        self.mapImage:SetBackground(RES_BASE .. "Maps/" .. group.map)
        self.mapImage:SetVisible(true)
    else
        self.mapImage:SetVisible(false)
    end

    self.lblPointsHeader:SetVisible(true)

    if group then
        for i, pt in ipairs(group.coords) do
            -- Marcador visual sobre el mapa, mismo icono que la lista.
            if bounds then
                local px, py = CoordToPixel(pt.c, bounds)
                if px then
                    local marker = Turbine.UI.Label()
                    marker:SetParent(self.mapImage)
                    marker:SetSize(16, 16)
                    marker:SetPosition(px, py)
                    marker:SetMouseVisible(false)
                    if self.activeIcon then marker:SetBackground(self.activeIcon) end
                    table.insert(self.mapMarkers, marker)
                end
            end

            -- Fila de la lista de puntos: nombre corto + Mapa/Ruta, usando
            -- nuestros adapters ya existentes -- la sinergia que agrega
            -- QuestSync sobre la estructura original de WarbandsSlayer.
            local item = Turbine.UI.Control()
            item:SetSize(320, 30)

            local lbl = Turbine.UI.Label()
            lbl:SetParent(item)
            lbl:SetPosition(0, 2)
            lbl:SetSize(170, 26)
            lbl:SetForeColor(Turbine.UI.Color(0.6, 0.85, 1))
            local desc = (pt.l and pt.l ~= "") and pt.l or ("Punto " .. i)
            lbl:SetText(desc)

            if MoorMapAdapter then
                local btnMap = Turbine.UI.Lotro.Button()
                btnMap:SetParent(item)
                btnMap:SetPosition(176, 2)
                btnMap:SetSize(60, 26)
                btnMap:SetText("Mapa")

                local qsMap = MoorMapAdapter.CreateQuickslot()
                qsMap:SetParent(btnMap)
                qsMap:SetPosition(0, 0)
                qsMap:SetSize(60, 26)
                qsMap:SetZOrder(10)

                local mapID = MoorMapAdapter.ResolveMapID({ area = bounds and bounds.name })
                local ns, ew = MoorMapAdapter.ParseCoord(pt.c)
                MoorMapAdapter.SetQuestMarker(qsMap, {
                    mapID = mapID, ns = ns or 0, ew = ew or 0,
                    name = string.gsub(esName, ":", "-"), description = "Punto de interes"
                })
            end

            if WaypointAdapter then
                local btnWay = Turbine.UI.Lotro.Button()
                btnWay:SetParent(item)
                btnWay:SetPosition(244, 2)
                btnWay:SetSize(60, 26)
                btnWay:SetText("Ruta")

                local qsWay = WaypointAdapter.CreateQuickslot()
                qsWay:SetParent(btnWay)
                qsWay:SetPosition(0, 0)
                qsWay:SetSize(60, 26)
                qsWay:SetZOrder(10)

                WaypointAdapter.SetDestination(qsWay, pt.c)
            end

            self.pointsList:AddItem(item)
        end
    end

    -- Recompensas
    local rewards = entry.rewards
    self.lblRewardsHeader:SetVisible(rewards ~= nil and #rewards > 0)
    if rewards then
        local ry = 0
        for _, r in ipairs(rewards) do
            local rLbl = Turbine.UI.Label()
            rLbl:SetParent(self.rewardsContainer)
            rLbl:SetPosition(0, ry)
            rLbl:SetSize(360, 18)
            rLbl:SetFont(Turbine.UI.Lotro.Font.Verdana12)
            rLbl:SetForeColor(Turbine.UI.Color(0.7, 0.9, 0.7))
            local rname = REWARD_NAMES[r.type] or r.type
            local rtext = "- " .. rname
            if r.value and r.value ~= "" and tostring(r.value) ~= rname then
                if tonumber(r.value) then
                    rtext = rtext .. " x" .. r.value
                else
                    rtext = rtext .. ": " .. r.value
                end
            end
            rLbl:SetText(rtext)
            table.insert(self.rewardLabels, rLbl)
            ry = ry + 18
        end
    end
end
