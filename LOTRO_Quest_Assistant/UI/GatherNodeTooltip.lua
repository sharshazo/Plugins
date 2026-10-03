-- LOTRO_Quest_Assistant/UI/GatherNodeTooltip.lua
-- Ventanita flotante chica que muestra "Veta de cobre (tier 1)" al pasar el
-- mouse por encima de un icono de nodo en GatherWindow.lua -- pedido
-- explicito del usuario. Version MINIMA de QuestInfoTooltip.lua (que arma
-- titulo+cuerpo+barra de progreso para misiones, mucho mas de lo que hace
-- falta aca) -- mismo patron estructural (singleton Turbine.UI.Window,
-- posicionado en la posicion real del mouse, marco=color de la ventana +
-- relleno=Control interior mas oscuro) pero solo con 1 linea de texto.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.GatherNodeTooltip = class(Turbine.UI.Window)
GatherNodeTooltip.instance = nil

function GatherNodeTooltip.GetInstance()
    if GatherNodeTooltip.instance then return GatherNodeTooltip.instance end
    return GatherNodeTooltip()
end

local BORDER = 2
local PAD = 8

function GatherNodeTooltip:Constructor()
    if GatherNodeTooltip.instance then return end
    Turbine.UI.Window.Constructor(self)
    GatherNodeTooltip.instance = self

    self:SetZOrder(0x7FFFFFFF)
    -- Mismo truco que QuestInfoTooltip.lua: el color de la VENTANA hace de
    -- marco, un Control interior mas chico (inset BORDER px) es el relleno
    -- oscuro donde vive el texto.
    self:SetBackColor(Turbine.UI.Color(0.5, 0.42, 0.25))
    self:SetOpacity(0.92)
    self:SetVisible(false)

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetPosition(BORDER, BORDER)
    self.inner:SetBackColor(Turbine.UI.Color(0.08, 0.07, 0.05))
    self.inner:SetMouseVisible(false)

    self.lblText = Turbine.UI.Label()
    self.lblText:SetParent(self.inner)
    self.lblText:SetPosition(PAD, PAD / 2)
    self.lblText:SetFont(LQA.UI.MEMBookStyle.Font.BookAntiqua14) -- rediseño "libro" 2026-08-28
    self.lblText:SetForeColor(Turbine.UI.Color(1, 0.82, 0.3))
    self.lblText:SetMouseVisible(false)
end

function GatherNodeTooltip:ShowFor(text)
    self.lblText:SetText(text or "")

    -- Ancho segun el largo del texto (sin medicion real de fuente
    -- disponible en este SDK) -- suficiente margen para nombres largos de
    -- nodo con tier, sin quedar exageradamente ancho para textos cortos.
    local w = math.max(120, math.min(360, 16 + string.len(text or "") * 7))
    local h = 24

    self.lblText:SetSize(w, h)
    self.inner:SetSize(w + PAD, h + PAD)
    self:SetSize(w + PAD + BORDER * 2, h + PAD + BORDER * 2)

    -- Posicion real del mouse, desplazado para no quedar tapado por el
    -- propio cursor -- mismo enfoque que QuestInfoTooltip.lua.
    local screenX, screenY = Turbine.UI.Display.GetMousePosition()
    self:SetPosition(screenX + 16, screenY + 16)
    self:SetVisible(true)
end

function GatherNodeTooltip:Hide()
    self:SetVisible(false)
end
