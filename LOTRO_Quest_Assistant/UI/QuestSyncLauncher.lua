-- LOTRO_Quest_Assistant/UI/QuestSyncLauncher.lua
-- Boton flotante persistente en pantalla (patron confirmado real en
-- Compendium/Launcher/CompendiumShortcut.lua): una Turbine.UI.Window chica
-- sin bordes ni titulo, con logica de arrastre propia que distingue un CLIC
-- (abre/cierra ventanas) de un ARRASTRE (mueve el grupo).
--
--   1) Libro -- abre/cierra QuestSync + el Tracker (ToggleWindows). Control
--      con book_icon.tga superpuesto, sin Quickslot (solo llama una funcion
--      Lua propia).
--   2) Lupa -- abre/cierra GatherWindow (la ventana de "Recoleccion" de
--      este mismo addon -- MISMO global _G.GatherWindow que ya usa el
--      boton "Recoleccion" de QuestTrackerHUD.lua, patron ya probado, sin
--      Quickslot -- es una funcion de nuestro propio addon).
--
-- V12 -- pedido explicito del usuario ("sacar la barra y dejar solo los
-- iconos del libro y la lupa con el click de bloquear"): version final
-- tras un largo historial de intentos (V2-V11, ver backups .bak_* de esta
-- sesion si hace falta el detalle) de armar una barra de madera+metal
-- (estilo quickbar nativa) con un 3er espacio para "estacionar" el icono
-- propio de LUI encima. CONCLUSION IMPORTANTE para el futuro: no existe
-- forma confiable de hacer que un CLIC le llegue a una ventana de OTRO
-- addon (Apartment distinto) posicionada detras/debajo de la nuestra --
-- ni SetMouseVisible(false), ni bajar el Z-order, ni un agujero
-- TRANSPARENTE real en la textura (alpha=0) lo lograron: el motor parece
-- reservar el rectangulo completo de CADA ventana para hit-testing,
-- independiente de que tan transparente sea su contenido visual. Ademas
-- MEM (MEMOpenIcon.lua, el propio patron original en el que se baso esta
-- barra) tampoco arma una barra compartida -- cada boton de MEM es su
-- propia ventana suelta con solo el icono flotando sobre el mundo, sin
-- fondo. Esta version vuelve a ESO: 2 iconos sueltos (book_icon.tga /
-- magnifying_icon.tga, tamaño nativo 64x64, sin bloque de madera detras),
-- misma logica de arrastre-vs-clic y el sistema de bloqueo de posicion ya
-- pedido antes, intactos. El icono de LUI se posiciona por separado, al
-- lado, sin intentar superponerse.
import "Turbine"
import "Turbine.UI"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}

LQA.UI.QuestSyncLauncher = class(Turbine.UI.Window)

-- V13 -- pedido explicito del usuario ("que los iconos del libro y la lupa
-- sean del mismo tamaño que el de lui"): ICON pasa de 64 (tamaño nativo de
-- los archivos originales) a 35 -- el mismo numero al que le pedimos
-- cambiar el icon_size de LUI en V7 (default 32 +10% = 35.2 ~ 35; sigue
-- siendo un ajuste GUARDADO en OTRO addon, no hay forma de leerlo en vivo
-- desde aca -- si el usuario no lo cambio en LUI, el match es aproximado).
-- book_icon_35.tga/magnifying_icon_35.tga son copias redimensionadas
-- limpias (conservan su transparencia real, sin fondo horneado -- a
-- diferencia del intento de la barra V8/V9, aca no hace falta opacidad
-- total porque flotan directo sobre el mundo, igual que el resto de este
-- diseño V12).
local ICON = 35
local GAP = 8
local WIDTH, HEIGHT = ICON * 2 + GAP, ICON
local BOOK_X, LUPA_X = 0, ICON + GAP
local SAVE_KEY = "QuestSync_LauncherPos"
-- Sistema de bloqueo (pedido explicito del usuario, "agregale un sistema
-- de bloqueo para que no se mueva"): SAVE_KEY separado (no mezclado con la
-- posicion) para poder bloquear/desbloquear sin tocar el registro de
-- posicion guardada. Con el grupo bloqueado, el CLIC sigue andando -- solo
-- se ignora el ARRASTRE (ver _AttachDrag mas abajo: MouseMove no
-- reposiciona si self.locked, pero MouseDown/MouseUp siguen detectando
-- clic normal).
local LOCK_SAVE_KEY = "QuestSync_LauncherLocked"

function LQA.UI.QuestSyncLauncher:Constructor()
    Turbine.UI.Window.Constructor(self)

    self.locked = false

    self:SetSize(WIDTH, HEIGHT)
    self:SetPosition(Turbine.UI.Display.GetWidth() - 100 - WIDTH, 200)
    self:SetZOrder(100) -- mismo valor que usa MEMOpenIcon.lua para su propio icono flotante
    self:SetVisible(true)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0)) -- transparente, los iconos de adentro son lo que se ve

    local RES = LQA.UI.MEMBookStyle.RES_BASE

    -- ===== 1) Libro: abre/cierra QuestSync + Tracker. =====
    self.btnBook = Turbine.UI.Control()
    self.btnBook:SetParent(self)
    self.btnBook:SetPosition(BOOK_X, 0)
    self.btnBook:SetSize(ICON, ICON)
    self.btnBook:SetBackground(RES .. "book_icon_35.tga")
    self:_AttachDrag(self.btnBook, function() self:ToggleWindows() end)

    -- ===== 2) Lupa: abre/cierra GatherWindow (Recoleccion). =====
    self.btnGather = Turbine.UI.Control()
    self.btnGather:SetParent(self)
    self.btnGather:SetPosition(LUPA_X, 0)
    self.btnGather:SetSize(ICON, ICON)
    self.btnGather:SetBackground(RES .. "magnifying_icon_35.tga")
    self:_AttachDrag(self.btnGather, function()
        if _G.GatherWindow then
            _G.GatherWindow:SetVisible(not _G.GatherWindow:IsVisible())
        end
    end)

    -- Menu de clic derecho (Turbine.UI.ContextMenu, misma API que usa el
    -- QuickLauncher de WarbandsSlayer).
    self.menu = Turbine.UI.ContextMenu()
    local itemQuests = Turbine.UI.MenuItem("Abrir/Cerrar QuestSync")
    itemQuests.Click = function()
        self:ToggleWindows()
    end
    self.menu:GetItems():Add(itemQuests)

    -- Bloqueo de posicion. Turbine.UI.MenuItem no tiene un SetChecked/
    -- casilla propia probada en este addon -- se usa el texto mismo del
    -- item para reflejar el estado (patron simple, sin depender de una
    -- API sin precedente).
    self.itemLock = Turbine.UI.MenuItem("Bloquear posicion")
    self.itemLock.Click = function()
        self:SetLocked(not self.locked, true)
    end
    self.menu:GetItems():Add(self.itemLock)

    -- Se restaura la posicion guardada (async, igual patron que
    -- QuestStateManager.Initialize): si nunca se guardo nada se queda en la
    -- posicion por defecto de arriba.
    Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(pos)
        if pos and type(pos) == "table" and pos.left and pos.top then
            self:SetPosition(pos.left, pos.top)
        end
    end)

    Turbine.PluginData.Load(Turbine.DataScope.Character, LOCK_SAVE_KEY, function(data)
        self:SetLocked(type(data) == "table" and data.locked == true, false)
    end)
end

-- Actualiza self.locked y el texto del item de menu. `persist` (default
-- true si se omite) controla si ademas se guarda -- en false para la carga
-- inicial desde PluginData.Load, evitar re-guardar el mismo valor que se
-- acaba de leer. Envuelto en una tabla ({locked=...}) para seguir el MISMO
-- patron que usa el resto del addon con Turbine.PluginData.Save (State/
-- Data/Found/Points/posicion -- todos tablas, nunca un booleano suelto sin
-- probar).
function LQA.UI.QuestSyncLauncher:SetLocked(locked, persist)
    self.locked = locked == true
    self.itemLock:SetText(self.locked and "Desbloquear posicion" or "Bloquear posicion")
    if persist ~= false then
        Turbine.PluginData.Save(Turbine.DataScope.Character, LOCK_SAVE_KEY, { locked = self.locked })
    end
end

-- Arrastrar-vs-clic compartido por el libro y la lupa. Si el mouse se movio
-- entre MouseDown y MouseUp fue un arrastre (mueve TODO el grupo,
-- self:SetPosition); si no, fue un clic (dispara onClick).
function LQA.UI.QuestSyncLauncher:_AttachDrag(control, onClick)
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

function LQA.UI.QuestSyncLauncher:SavePosition()
    local left, top = self:GetPosition()
    Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, { left = left, top = top })
end

-- Un solo boton abre/cierra LAS DOS ventanas juntas -- pedido explicito del
-- usuario. Tambien sirve para volver a mostrar el HUD si el jugador lo cerro
-- con el boton nativo de su barra de titulo.
function LQA.UI.QuestSyncLauncher:ToggleWindows()
    local bothVisible = _G.MainWindow:IsVisible() and _G.HUD:IsVisible()
    local show = not bothVisible
    _G.MainWindow:SetVisible(show)
    _G.HUD:SetVisible(show)
end
