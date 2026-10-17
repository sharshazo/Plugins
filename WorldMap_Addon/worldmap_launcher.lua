-- WorldMap_Addon/worldmap_launcher.lua
--
-- Boton flotante anclable que abre/cierra el Mapa del Mundo. Calcado 1 a 1
-- del patron real y ya probado sin incidentes de
-- LOTRO_Quest_Assistant/UI/QuestSyncLauncher.lua (mismo usuario, addon ya
-- instalado y funcionando): una Turbine.UI.Window chica sin chrome, con
-- logica propia de arrastre-vs-clic, menu de click derecho para bloquear la
-- posicion, y la posicion guardada/leida con Turbine.PluginData (por
-- personaje, igual que ese addon).
--
-- CORRECCION (reporte real del usuario): el icono se veia mal/chico en
-- pantalla. Se agranda de 35 a 46px y se le agrega un fondo circular oscuro
-- semitransparente detras (mismo Control simple, sin API nueva) para que
-- se distinga sobre cualquier fondo del juego, en vez de mostrar el icono
-- "pelado" contra lo que sea que haya detras.
--
-- CORRECCION v1.9 (reporte real del usuario con captura): el icono propio
-- (mapicon_128.tga, un cuadrado de cuero con marco dorado y un pergamino
-- adentro) se veia CORTADO A LA MITAD en el juego real -- solo la mitad
-- inferior derecha llegaba a dibujarse, el resto quedaba transparente. El
-- archivo en si esta bien (se releyo con PIL y se ve completo), asi que es
-- un problema de renderizado del propio TGA en el motor real, no del
-- contenido -- no vale la pena perseguirlo mas. El usuario pidio
-- directamente reusar la imagen de icono de mapa que ya tiene
-- LOTRO_QUEST_ASSISTANT (magnifying_icon_35.tga, la lupa que ese addon usa
-- para abrir su propia ventana de "Recoleccion" -- la misma arquitectura de
-- viewport+pan que este addon copio para worldmap.lua) y dejarlo al mismo
-- tamaño que usan LOS ICONOS FLOTANTES de ese addon (ICON=35, no 46 --
-- confirmado leyendo QuestSyncLauncher.lua: "book_icon_35.tga/
-- magnifying_icon_35.tga son copias redimensionadas limpias"). Copiado tal
-- cual (mismo archivo, sin reescalar de nuevo) a assets/worldmap/icon/
-- launcher_icon_35.tga -- evita repetir el mismo problema de renderizado
-- con un TGA nuevo generado por nuestro propio pipeline.
--
-- ATAJO DE TECLADO ("/mapa"): pedido explicito del usuario. No existe forma
-- segura de capturar una tecla cualquiera como hotkey global (revisado en
-- CombatAnalysis/Utils/KeyManager.lua y WhereToPlayV1.34/MapWindow.lua --
-- solo hay enums confirmados para teclas especiales como Escape/F12, y
-- capturar letras sueltas requiere un hack de robo de foco documentado como
-- fragil). En cambio se registra un comando de barra real y confirmado
-- (Turbine.ShellCommand + Turbine.Shell.AddCommand, mismo patron que
-- TravelWindowII usa para "/trav" y "/travel"): "/mapa" o "/mapadelmundo"
-- abren/cierran el mapa. El jugador puede asignarle una tecla el mismo
-- creando una macro con ese texto y arrastrandola a una barra (funcion
-- nativa del juego, no requiere nada de este addon).

import "Turbine"
import "Turbine.UI"

_G.WorldMapAddon = _G.WorldMapAddon or {}
WorldMapAddon.UI = WorldMapAddon.UI or {}

WorldMapAddon.UI.Launcher = class(Turbine.UI.Window)

-- v2.0.3: icono redondo de mapa enviado por el usuario (pergamino con
-- rosa de los vientos y Arbol Blanco). En v2.0.2 se probo a 64px y quedo
-- demasiado grande en el juego -- vuelve a 35px, el MISMO tamaño que los
-- iconos flotantes de LOTRO_Quest_Assistant (pedido del usuario). La
-- imagen se genero a 35x35 exactos (SetBackground no reescala).
--
-- v2.3: ICONO PRINCIPAL UNICO (pedido del usuario: "usa este icono
-- principal y todos los otros iconos se desplieguen al clickear este").
-- Clic en el icono redondo = despliega/recoge una fila con los demas
-- iconos al lado: Mapa del Mundo, y si LOTRO_Quest_Assistant esta cargado,
-- su Libro (misiones + rastreador) y su Lupa (recoleccion) -- las MISMAS
-- imagenes y las MISMAS acciones que sus iconos sueltos (MainWindow/HUD via
-- Launcher:ToggleWindows y GatherWindow), que ahora se ocultan para que en
-- pantalla quede un solo icono. Nada de Quest Assistant se modifica: solo
-- se oculta su ventanita de iconos, y se vuelve a mostrar si este addon se
-- descarga. LUI no entra en el grupo: corre en su propio Apartment y su
-- icono es inalcanzable desde aca (ver nota V12 de QuestSyncLauncher.lua).
local ICON = 35
local GAP = 4
local STEP = ICON + GAP
local RES_BASE = "WorldMap_Addon/assets/worldmap/"
local LQA_RES = "LOTRO_Quest_Assistant/Resources/Book/"
local SAVE_KEY = "WorldMapAddon_LauncherPos"
local LOCK_SAVE_KEY = "WorldMapAddon_LauncherLocked"

-- la ventanita de iconos de Quest Assistant (global _G.Launcher, creada
-- en su Main.lua), solo si de verdad es la suya
local function LqaLauncher(self)
    local l = _G.Launcher
    if l ~= nil and l ~= self and type(l.ToggleWindows) == "function" then
        return l
    end
    return nil
end

function WorldMapAddon.UI.Launcher:Constructor()
    Turbine.UI.Window.Constructor(self)

    self.locked = false
    self.expanded = false
    self.expandLeft = false
    self.subButtons = {}

    self:SetSize(ICON, ICON)
    self:SetPosition(Turbine.UI.Display.GetWidth() - 140, 240)
    self:SetZOrder(100)
    self:SetVisible(true)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    -- Fondo oscuro semitransparente (ver nota de correccion arriba). v2.0.2:
    -- el icono es REDONDO con fondo transparente; se deja creado pero oculto.
    self.btnBg = Turbine.UI.Control()
    self.btnBg:SetParent(self)
    self.btnBg:SetPosition(0, 0)
    self.btnBg:SetSize(ICON, ICON)
    self.btnBg:SetBackColor(Turbine.UI.Color(0, 0, 0, 0.4))
    self.btnBg:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.btnBg:SetMouseVisible(false)
    self.btnBg:SetVisible(false)

    -- icono principal (mismo Control 35x35 en (0,0) de siempre)
    self.btnMap = Turbine.UI.Control()
    self.btnMap:SetParent(self)
    self.btnMap:SetPosition(0, 0)
    self.btnMap:SetSize(ICON, ICON)
    self.btnMap:SetBackground(RES_BASE .. "icon/mapa_redondo_35.tga")
    self:_AttachDrag(self.btnMap, function() self:ToggleExpanded() end)

    -- iconos desplegables (ocultos hasta el clic en el principal)
    self:_AddSub("mapa", RES_BASE .. "icon/mapa_icon_35.tga", function()
        self:ToggleMap()
    end)
    self:_AddSub("libro", LQA_RES .. "book_icon_35.tga", function()
        local l = LqaLauncher(self)
        if l ~= nil then
            l:ToggleWindows()
        end
    end)
    self:_AddSub("lupa", LQA_RES .. "magnifying_icon_35.tga", function()
        -- v3.15: la ventana "Recoleccion" de este addon (sin MoorMap); la
        -- de Quest Assistant solo si la nueva no estuviera
        if WorldMapAddon.Gather ~= nil and WorldMapAddon.Gather.Toggle ~= nil then
            WorldMapAddon.Gather.Toggle()
        elseif _G.GatherWindow ~= nil then
            _G.GatherWindow:SetVisible(not _G.GatherWindow:IsVisible())
        end
    end)
    -- v3.16: senales de jefe (opciones, prueba)
    self:_AddSub("senales", RES_BASE .. "icon/senales_icon_35.tga", function()
        if WorldMapAddon.Boss ~= nil and WorldMapAddon.Boss.ToggleOptions ~= nil then
            WorldMapAddon.Boss.ToggleOptions()
        end
    end)

    self.menu = Turbine.UI.ContextMenu()
    local itemToggle = Turbine.UI.MenuItem("Abrir/Cerrar Mapa del Mundo")
    itemToggle.Click = function() self:ToggleMap() end
    self.menu:GetItems():Add(itemToggle)
    -- v3.15: ventana Recoleccion
    local itemGather = Turbine.UI.MenuItem("Abrir/Cerrar Recolecci\195\179n")
    itemGather.Click = function()
        if WorldMapAddon.Gather ~= nil then
            WorldMapAddon.Gather.Toggle()
        end
    end
    self.menu:GetItems():Add(itemGather)
    -- v3.16: senales de jefe
    local itemBoss = Turbine.UI.MenuItem("Mec\195\161nicas de jefe")
    itemBoss.Click = function()
        if WorldMapAddon.Boss ~= nil and WorldMapAddon.Boss.ToggleOptions ~= nil then
            WorldMapAddon.Boss.ToggleOptions()
        end
    end
    self.menu:GetItems():Add(itemBoss)

    self.itemLock = Turbine.UI.MenuItem("Bloquear posicion")
    self.itemLock.Click = function()
        self:SetLocked(not self.locked, true)
    end
    self.menu:GetItems():Add(self.itemLock)

    Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(pos)
        if pos and type(pos) == "table" and pos.left and pos.top then
            self:SetPosition(pos.left, pos.top)
        end
    end)

    Turbine.PluginData.Load(Turbine.DataScope.Character, LOCK_SAVE_KEY, function(data)
        self:SetLocked(type(data) == "table" and data.locked == true, false)
    end)

    -- Quest Assistant puede cargarse antes o despues que este addon: se
    -- vigila (1 vez por segundo, costo minimo) y su ventanita de iconos se
    -- mantiene oculta mientras este icono principal exista.
    self.hideCheckAt = 0
    self:SetWantsUpdates(true)
    self.Update = function()
        local now = Turbine.Engine.GetGameTime()
        if now < self.hideCheckAt then
            return
        end
        self.hideCheckAt = now + 1
        self:_HideLqaLauncher()
    end
    self:_HideLqaLauncher()
end

function WorldMapAddon.UI.Launcher:_AddSub(key, image, action)
    local btn = Turbine.UI.Control()
    btn:SetParent(self)
    btn:SetSize(ICON, ICON)
    btn:SetBackground(image)
    btn:SetVisible(false)
    btn.subKey = key
    self:_AttachDrag(btn, function()
        action()
        self:SetExpanded(false)
    end)
    self.subButtons[#self.subButtons + 1] = btn
end

-- libro y lupa solo si Quest Assistant esta cargado
function WorldMapAddon.UI.Launcher:_AvailableSubs()
    local list = {}
    for _, btn in ipairs(self.subButtons) do
        local ok = true
        if btn.subKey == "libro" then
            ok = LqaLauncher(self) ~= nil
        elseif btn.subKey == "lupa" then
            ok = _G.GatherWindow ~= nil or _G.GatherPointsStore ~= nil
        elseif btn.subKey == "senales" then
            ok = WorldMapAddon.Boss ~= nil
        end
        if ok then
            list[#list + 1] = btn
        end
    end
    return list
end

function WorldMapAddon.UI.Launcher:_HideLqaLauncher()
    local l = LqaLauncher(self)
    if l ~= nil and l:IsVisible() then
        l:SetVisible(false)
    end
end

-- se llama al descargar este addon (Main.lua): Quest Assistant recupera
-- sus iconos sueltos
function WorldMapAddon.UI.Launcher:RestoreLqaLauncher()
    local l = LqaLauncher(self)
    if l ~= nil then
        l:SetVisible(true)
    end
end

function WorldMapAddon.UI.Launcher:ToggleExpanded()
    self:SetExpanded(not self.expanded)
end

-- Despliega la fila a la DERECHA del icono principal; si no entra en
-- pantalla, a la IZQUIERDA (la ventana se corre para que el icono
-- principal quede exactamente donde estaba).
function WorldMapAddon.UI.Launcher:SetExpanded(expanded)
    expanded = expanded == true
    local left, top = self:GetPosition()
    -- posicion en pantalla del icono principal antes del cambio
    local mainX = left + (self.expanded and self.expandLeft and self.rowW or 0)

    for _, btn in ipairs(self.subButtons) do
        btn:SetVisible(false)
    end

    if not expanded then
        self.expanded = false
        self.expandLeft = false
        self.rowW = 0
        self.btnMap:SetPosition(0, 0)
        self:SetSize(ICON, ICON)
        self:SetPosition(mainX, top)
        return
    end

    local subs = self:_AvailableSubs()
    local rowW = #subs * STEP
    local toLeft = mainX + ICON + rowW > Turbine.UI.Display.GetWidth()
    self.expanded = true
    self.expandLeft = toLeft
    self.rowW = rowW
    self:SetSize(ICON + rowW, ICON)
    if toLeft then
        self:SetPosition(mainX - rowW, top)
        self.btnMap:SetPosition(rowW, 0)
        for i, btn in ipairs(subs) do
            btn:SetPosition(rowW - i * STEP, 0)
            btn:SetVisible(true)
        end
    else
        self:SetPosition(mainX, top)
        self.btnMap:SetPosition(0, 0)
        for i, btn in ipairs(subs) do
            btn:SetPosition(i * STEP, 0)
            btn:SetVisible(true)
        end
    end
end

function WorldMapAddon.UI.Launcher:SetLocked(locked, persist)
    self.locked = locked == true
    self.itemLock:SetText(self.locked and "Desbloquear posicion" or "Bloquear posicion")
    if persist ~= false then
        Turbine.PluginData.Save(Turbine.DataScope.Character, LOCK_SAVE_KEY, { locked = self.locked })
    end
end

-- Arrastrar-vs-clic: si el mouse se movio entre MouseDown y MouseUp fue un
-- arrastre (mueve la ventana), si no fue un clic (abre/cierra el mapa).
function WorldMapAddon.UI.Launcher:_AttachDrag(control, onClick)
    control.MouseDown = function(sender, args)
        if args.Button == Turbine.UI.MouseButton.Left then
            sender.dragStartX = args.X
            sender.dragStartY = args.Y
            sender.dragging = true
            sender.dragged = false
        end
    end

    control.MouseMove = function(sender, args)
        if sender.dragging and not self.locked then
            local left, top = self:GetPosition()
            self:SetPosition(left + (args.X - sender.dragStartX), top + (args.Y - sender.dragStartY))
            sender.dragged = true
        end
    end

    control.MouseUp = function(sender, args)
        if args.Button == Turbine.UI.MouseButton.Left then
            if sender.dragging then
                sender.dragging = false
                if sender.dragged then
                    self:SavePosition()
                else
                    onClick()
                end
            end
        elseif args.Button == Turbine.UI.MouseButton.Right then
            self.menu:ShowMenu()
        end
    end
end

function WorldMapAddon.UI.Launcher:SavePosition()
    local left, top = self:GetPosition()
    -- v2.3: siempre se guarda la posicion del ICONO PRINCIPAL (desplegado
    -- hacia la izquierda, la ventana arranca antes que el)
    if self.expanded and self.expandLeft then
        left = left + (self.rowW or 0)
    end
    Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, { left = left, top = top })
end

-- Crea la ventana del mapa la primera vez que hace falta (no en el
-- Constructor del boton, para no pagar el costo de armar las 59 zonas +
-- 87 tiles si el jugador nunca llega a abrirlo en esa sesion).
function WorldMapAddon.UI.Launcher:ToggleMap()
    if not WorldMapAddon.instance then
        WorldMapAddon.instance = WorldMapAddon.UI.WorldMap()
    end
    WorldMapAddon.instance:SetVisible(not WorldMapAddon.instance:IsVisible())
end

-- Comando de barra "/mapa" (o "/mapadelmundo"): sin nada despues, reusa
-- exactamente la misma logica que el clic del boton flotante
-- (WorldMapAddon.launcher:ToggleMap(), creado en Main.lua al iniciar el
-- addon) -- abre/cierra. Punto 20a: "/mapa <texto>" (ej. "/mapa eregion" o
-- "/mapa 50") abre el mapa (lo crea si hace falta, SIN togglear -- si ya
-- estaba abierto se queda abierto) y deja esa busqueda ya hecha. Turbine.
-- ShellCommand:Execute(command, arguments) confirmado real (TravelWindowII/
-- Main.lua): "arguments" es el resto de la linea completo, como un solo
-- string CON espacios (se compara ahi literal contra "debug on"), asi que
-- una busqueda de varias palabras llega intacta.
-- v3.13 (pedido del usuario): Quest Assistant manda sus puntos aca. Abre
-- el mapa, elige el mapa de zona que contiene el punto y lo marca con la
-- misma flecha que la busqueda de lugares (ZoneView:FindAt).
-- ns/ew: numeros con signo (sur y oeste negativos, como MoorMap).
-- mid: mapa sugerido (mismos numeros que MoorMap), puede ser nil o 0.
local function PointNum(v)
    if type(v) == "number" then
        return v
    end
    local s = tostring(v or ""):gsub("%s", "")
    return tonumber(s) or tonumber((s:gsub(",", "."))) or tonumber((s:gsub("%.", ",")))
end

local POINT_TOL = 0.4   -- igual que COVER_TOL de worldmap_zonemap.lua

-- x, y del punto en el mapa mid si el punto cae en su dibujo; si no, nil
local function PointOnMap(mid, ns, ew)
    local ZD = WorldMapAddon.ZoneMapsData
    local CAL = WorldMapAddon.MapCal
    local m = ZD ~= nil and ZD.Maps ~= nil and ZD.Maps[mid] or nil
    local cal = type(CAL) == "table" and CAL[mid] or nil
    if m == nil or type(cal) ~= "table" or cal[8] == nil then
        return nil
    end
    if ns > cal[5] + POINT_TOL or ns < cal[7] - POINT_TOL or ew < cal[6] - POINT_TOL or ew > cal[8] + POINT_TOL then
        return nil
    end
    local x = ew * cal[1] + cal[2]
    local y = ns * cal[3] + cal[4]
    if x < 0 or y < 0 or x > (m.w or 1024) or y > (m.h or 768) then
        return nil
    end
    return x, y
end

-- Las coordenadas de LOTRO se repiten entre regiones (Eriador, Rhovanion,
-- Gondor...): el mismo ns/ew cae en mapas de zonas distintas. Por eso el
-- mapa sugerido manda: primero ese mapa, despues los otros mapas de SU
-- zona. Sin mapa sugerido solo se marca si todos los mapas que contienen
-- el punto son de una misma zona. Devuelve id, x, y (o nil y el motivo).
-- caja de la zona en el mapa del mundo (de su poligono), para saber que
-- zonas son vecinas
local function ZoneBox(name)
    local D = WorldMapAddon.Data
    if D == nil or type(D.Zones) ~= "table" then
        return nil
    end
    for _, z in ipairs(D.Zones) do
        if z.nombre_original == name and type(z.poligono) == "table" and z.poligono[1] ~= nil then
            local x0, y0, x1, y1 = 1e9, 1e9, -1e9, -1e9
            for _, pt in ipairs(z.poligono) do
                x0, y0 = math.min(x0, pt.x), math.min(y0, pt.y)
                x1, y1 = math.max(x1, pt.x), math.max(y1, pt.y)
            end
            return { x0, y0, x1, y1 }
        end
    end
    return nil
end

local NEAR_PX = 12      -- separacion maxima entre cajas de zonas vecinas
local NEAR_COORD = 12   -- distancia maxima (ns/ew) del punto a su zona

-- distancia (en ns/ew) del punto al mapa mas cercano de la zona; asi una
-- coordenada de otra region (mismos numeros, otro lugar) no pasa por vecina
local function CoordDistToZone(zn, ns, ew)
    local ZD = WorldMapAddon.ZoneMapsData
    local best = nil
    for id, c in pairs(WorldMapAddon.MapCal) do
        local m = ZD.Maps[id]
        if m ~= nil and ZD.MapZone[id] == zn and (m.tier == 3 or m.tier == 4) and c[1] ~= 0 and c[5] ~= nil and c[5] < 900 then
            local dn = math.max(0, ns - c[5], c[7] - ns)
            local de = math.max(0, c[6] - ew, ew - c[8])
            local d = math.sqrt(dn * dn + de * de)
            if best == nil or d < best then
                best = d
            end
        end
    end
    return best
end

local function ZonesNear(a, b)
    local ba, bb = ZoneBox(a), ZoneBox(b)
    if ba == nil or bb == nil then
        return false
    end
    return ba[1] - NEAR_PX <= bb[3] and bb[1] - NEAR_PX <= ba[3] and
        ba[2] - NEAR_PX <= bb[4] and bb[2] - NEAR_PX <= ba[4]
end

-- mejor mapa (zona 3 antes que area 4, despues el mas chico) que contiene
-- el punto; accept(zona) decide que zonas valen. Devuelve id, x, y, zonas.
local function SearchPointMap(ns, ew, accept)
    local ZD = WorldMapAddon.ZoneMapsData
    local CAL = WorldMapAddon.MapCal
    local best, bx, by, bkey
    local zones, nz = {}, 0
    for id, cal in pairs(CAL) do
        local m = ZD.Maps[id]
        local zn = ZD.MapZone ~= nil and ZD.MapZone[id] or nil
        -- solo mapas de zona y de area (3 y 4) con calibracion conocida;
        -- los interiores de instancias comparten coordenadas con el exterior
        if m ~= nil and (m.tier == 3 or m.tier == 4) and zn ~= nil and
            (accept == nil or accept(zn)) and cal[1] ~= 0 and cal[5] ~= nil and cal[5] < 900 then
            local x, y = PointOnMap(id, ns, ew)
            if x ~= nil then
                if zones[zn] == nil then
                    zones[zn] = true
                    nz = nz + 1
                end
                local area = math.abs((cal[5] - cal[7]) * (cal[8] - cal[6]))
                local key = { m.tier == 3 and 0 or 1, area, id }
                local better = bkey == nil
                if not better then
                    for i = 1, 3 do
                        if key[i] ~= bkey[i] then
                            better = key[i] < bkey[i]
                            break
                        end
                    end
                end
                if better then
                    best, bx, by, bkey = id, x, y, key
                end
            end
        end
    end
    return best, bx, by, nz
end

-- Las coordenadas de LOTRO se repiten entre regiones (Eriador, Rhovanion,
-- Gondor...): el mismo ns/ew cae en mapas de zonas distintas. Por eso el
-- mapa sugerido manda: primero ese mapa, despues los otros mapas de SU
-- zona, despues los de una zona VECINA (mision que manda a la zona de al
-- lado). Sin mapa sugerido solo se marca si todos los mapas que contienen
-- el punto son de una misma zona.
-- Devuelve id, x, y (o nil y el motivo).
local function PickPointMap(ns, ew, mid)
    local ZD = WorldMapAddon.ZoneMapsData
    local CAL = WorldMapAddon.MapCal
    if ZD == nil or ZD.Maps == nil or type(CAL) ~= "table" then
        return nil
    end
    if mid ~= nil and mid ~= 0 and ZD.Maps[mid] ~= nil then
        local x, y = PointOnMap(mid, ns, ew)
        if x ~= nil then
            return mid, x, y
        end
        local hint = ZD.MapZone ~= nil and ZD.MapZone[mid] or nil
        if hint == nil then
            return nil, "fuera"
        end
        local id, hx, hy = SearchPointMap(ns, ew, function(zn) return zn == hint end)
        if id ~= nil then
            return id, hx, hy
        end
        local near = CoordDistToZone(hint, ns, ew)
        if near == nil or near > NEAR_COORD then
            return nil, "fuera"
        end
        local nz
        id, hx, hy, nz = SearchPointMap(ns, ew, function(zn) return ZonesNear(hint, zn) end)
        if id ~= nil and nz == 1 then
            return id, hx, hy
        end
        return nil, (id ~= nil) and "varios" or "fuera"
    end
    local id, x, y, nz = SearchPointMap(ns, ew, nil)
    if id == nil then
        return nil, "fuera"
    end
    if nz > 1 then
        return nil, "varios"
    end
    return id, x, y
end

function WorldMapAddon.ShowPoint(ns, ew, mid, label)
    ns, ew, mid = PointNum(ns), PointNum(ew), PointNum(mid)
    if ns == nil or ew == nil or (ns == 0 and ew == 0) then
        return false
    end
    if WorldMapAddon.UI == nil or WorldMapAddon.UI.WorldMap == nil then
        return false
    end
    if not WorldMapAddon.instance then
        WorldMapAddon.instance = WorldMapAddon.UI.WorldMap()
    end
    local inst = WorldMapAddon.instance
    inst:SetVisible(true)
    pcall(function() inst:Activate() end)
    local ZD = WorldMapAddon.ZoneMapsData
    local function zoneOf(m)
        local zname = ZD ~= nil and ZD.MapZone ~= nil and m ~= nil and ZD.MapZone[m] or nil
        if zname ~= nil and inst._zoneByOriginal ~= nil then
            local ok, z = pcall(inst._zoneByOriginal, inst, zname)
            if ok and z ~= nil then
                return z
            end
        end
        return false
    end
    local id, x, y = PickPointMap(ns, ew, mid)
    if id == nil then
        -- al menos se abre la zona del mapa sugerido
        local hz = zoneOf(mid)
        if hz ~= false then
            pcall(function() inst:_showZoneView(hz) end)
        end
        local why = x == "varios" and "no se sabe en que zona esta ese lugar" or "ese lugar no esta en el mapa de su zona"
        Turbine.Shell.WriteLine("<rgb=#FFB040>Mapa del Mundo: " .. why .. " (" .. tostring(label or "") ..
            "  " .. string.format("%.1f%s, %.1f%s", math.abs(ns), ns < 0 and "S" or "N", math.abs(ew), ew < 0 and "W" or "E") .. ")</rgb>")
        return false
    end
    local zone = zoneOf(id)
    local ok, done = pcall(function()
        if inst.zoneView == nil or not inst.zoneMode or inst.zoneView.zone ~= zone then
            inst:_showZoneView(zone)
        end
        if inst.zoneView == nil then
            return false
        end
        return inst.zoneView:FindAt(id, x, y)
    end)
    if not ok then
        Turbine.Shell.WriteLine("<rgb=#FF0000>Mapa del Mundo: no se pudo marcar el punto -- " .. tostring(done) .. "</rgb>")
        return false
    end
    if done and inst.qrBox ~= nil then
        pcall(function() inst.qrBox:SetVisible(false) end)
    end
    return done == true
end

WorldMapAddon.MapCommand = Turbine.ShellCommand()
function WorldMapAddon.MapCommand:Execute(command, arguments)
    local query = arguments ~= nil and tostring(arguments):match("^%s*(.-)%s*$") or ""
    if query == "" then
        if WorldMapAddon.launcher then
            WorldMapAddon.launcher:ToggleMap()
        end
        return
    end
    -- v3.11: "/mapa opciones" abre la ventana de opciones
    local low = query:lower()
    -- v3.13: "/mapa punto mapa:ns:ew:nombre" (lo usa Quest Assistant)
    local pm, pns, pew, plabel = query:match("^[Pp][Uu][Nn][Tt][Oo]%s+(%-?%d*):([^:]+):([^:]+):?(.*)$")
    if pns ~= nil and PointNum(pns) ~= nil and PointNum(pew) ~= nil then
        WorldMapAddon.ShowPoint(pns, pew, pm, plabel)
        return
    end
    -- v3.15: "/mapa recoleccion" abre / cierra la ventana Recoleccion
    if (low == "recoleccion" or low == "recolecci\195\179n" or low == "gathering") and WorldMapAddon.Gather ~= nil then
        WorldMapAddon.Gather.Toggle()
        return
    end
    -- v3.16: "/mapa jefe" (opciones), "/mapa jefe prueba", "/mapa jefe <nombre>", "/mapa jefe off"
    local bossArg = query:match("^[Jj][Ee][Ff][Ee]%s*(.*)$") or query:match("^[Bb][Oo][Ss][Ss]%s*(.*)$")
    if bossArg ~= nil and WorldMapAddon.Boss ~= nil and WorldMapAddon.Boss.Command ~= nil then
        local okB, errB = pcall(WorldMapAddon.Boss.Command, bossArg)
        if not okB then
            Turbine.Shell.WriteLine("<rgb=#FF0000>Mapa del Mundo: " .. tostring(errB) .. "</rgb>")
        end
        return
    end
    if (low == "opciones" or low == "options") and WorldMapAddon.Options ~= nil and WorldMapAddon.Options.Show ~= nil then
        WorldMapAddon.Options.Show()
        return
    end

    if not WorldMapAddon.instance then
        WorldMapAddon.instance = WorldMapAddon.UI.WorldMap()
    end
    WorldMapAddon.instance:SetVisible(true)
    WorldMapAddon.instance:_setSearchQuery(query)
end
Turbine.Shell.AddCommand("mapa,mapadelmundo", WorldMapAddon.MapCommand)
