-- LOTRO_Quest_Assistant/UI/GatherCaptureButton.lua
-- Boton flotante que aparece SOLO cuando GatherEventParser detecta un nodo
-- de recoleccion, y desaparece apenas el punto queda guardado. Existe porque
-- se confirmo en vivo (2026-08-23, ver Legacy/LocationAdapter.lua) que un
-- Quickslot:MouseClick() programatico NO dispara su alias -- hace falta un
-- clic REAL del jugador. Este boton usa el mismo patron Quickslot-detras-de-
-- boton que los botones "Ir" de MoorMap/Waypoint en QuestSyncWindow.lua
-- (funcionalmente identico, ya probado en produccion), asi que el clic real
-- que recibe SI llega a disparar /loc.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}

LQA.UI.GatherCaptureButton = class(Turbine.UI.Window)

local WIDTH, HEIGHT = 320, 70

function LQA.UI.GatherCaptureButton:Constructor()
    Turbine.UI.Window.Constructor(self)

    self:SetSize(WIDTH, HEIGHT)
    self:SetPosition((Turbine.UI.Display.GetWidth() - WIDTH) / 2, 90)
    self:SetZOrder(150)
    self:SetVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    self.panel = Turbine.UI.Control()
    self.panel:SetParent(self)
    self.panel:SetPosition(0, 0)
    self.panel:SetSize(WIDTH, HEIGHT)
    self.panel:SetBackColor(Turbine.UI.Color(0.9, 0.13, 0.11, 0.07))

    self.border = Turbine.UI.Control()
    self.border:SetParent(self.panel)
    self.border:SetPosition(0, 0)
    self.border:SetSize(WIDTH, 2)
    self.border:SetBackColor(Turbine.UI.Color(0.80, 0.63, 0.22))

    self.label = Turbine.UI.Label()
    self.label:SetParent(self.panel)
    self.label:SetPosition(8, 8)
    self.label:SetSize(WIDTH - 40, 28)
    self.label:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.label:SetForeColor(Turbine.UI.Color(0.95, 0.95, 0.85))
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.label:SetMultiline(true)
    self.label:SetMouseVisible(false)
    self.label:SetText("")

    -- Boton de descarte ("X", mismo patron ya usado en QuestTrackerHUD.lua
    -- para su boton "ocultar") -- pedido explicito del usuario: si no
    -- queremos guardar el nodo, hay que poder cerrar el popup sin capturar
    -- la ubicacion, en vez de dejarlo abierto (se acumulaban ventanas hasta
    -- ~100 activas cuando el jugador dejaba varios nodos sin resolver).
    self.btnClose = Turbine.UI.Lotro.Button()
    self.btnClose:SetParent(self.panel)
    self.btnClose:SetPosition(WIDTH - 26, 4)
    self.btnClose:SetSize(20, 20)
    self.btnClose:SetText("X")
    self.btnClose.MouseClick = function()
        -- BUG REAL (2026-09-07): esto solo escondia la ventana -- el
        -- pendingNode interno de GatherEventParser.lua quedaba pegado hasta
        -- 90s (ver PENDING_TIMEOUT_SECONDS), bloqueando en silencio que
        -- cualquier item NUEVO (de cualquier profesion) volviera a disparar
        -- este mismo boton. Ahora limpia tambien el estado interno.
        if _G.GatherEventParser then
            GatherEventParser.CancelPending()
        end
        self:SetVisible(false)
    end

    self.btnCapture = Turbine.UI.Lotro.Button()
    self.btnCapture:SetParent(self.panel)
    self.btnCapture:SetPosition((WIDTH - 200) / 2, 36)
    self.btnCapture:SetSize(200, 26)
    self.btnCapture:SetText("Guardar ubicación de recolección")

    if LocationAdapter then
        self.quickslot = LocationAdapter.CreateQuickslot()
        LocationAdapter.AttachToButton(self.quickslot, self.btnCapture)
        LocationAdapter.SetLocShortcut(self.quickslot)
    end

    LQA.Core.EventBus:Subscribe("GATHER_NODE_DETECTED", function(data)
        self:ShowForNode(data.entry)
    end)
    LQA.Core.EventBus:Subscribe("GATHER_POINT_ADDED", function(data)
        self:SetVisible(false)
    end)
    LQA.Core.EventBus:Subscribe("GATHER_POINT_UPDATED", function(data)
        self:SetVisible(false)
    end)
end

function LQA.UI.GatherCaptureButton:ShowForNode(entry)
    if entry == nil then return end
    self.label:SetText(tostring(entry.node) .. " (" .. tostring(entry.profession) ..
        " tier " .. tostring(entry.tier) .. ")")
    self:SetVisible(true)
end
