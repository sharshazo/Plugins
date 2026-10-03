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
        if _G.GatherWindow ~= nil then
            _G.GatherWindow:SetVisible(not _G.GatherWindow:IsVisible())
        end
    end)

    self.menu = Turbine.UI.ContextMenu()
    local itemToggle = Turbine.UI.MenuItem("Abrir/Cerrar Mapa del Mundo")
    itemToggle.Click = function() self:ToggleMap() end
    self.menu:GetItems():Add(itemToggle)

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
            ok = _G.GatherWindow ~= nil
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
WorldMapAddon.MapCommand = Turbine.ShellCommand()
function WorldMapAddon.MapCommand:Execute(command, arguments)
    local query = arguments ~= nil and tostring(arguments):match("^%s*(.-)%s*$") or ""
    if query == "" then
        if WorldMapAddon.launcher then
            WorldMapAddon.launcher:ToggleMap()
        end
        return
    end

    if not WorldMapAddon.instance then
        WorldMapAddon.instance = WorldMapAddon.UI.WorldMap()
    end
    WorldMapAddon.instance:SetVisible(true)
    WorldMapAddon.instance:_setSearchQuery(query)
end
Turbine.Shell.AddCommand("mapa,mapadelmundo", WorldMapAddon.MapCommand)
