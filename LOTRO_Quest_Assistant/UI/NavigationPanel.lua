import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}
LQA.UI.NavigationPanel = class(Turbine.UI.Lotro.Window)

function NavigationPanel:Constructor()

    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetPosition(100, 100)
    self:SetSize(220, 140)
    self:SetText("NAVEGACIÓN")

    self.lastLocData = nil
    self.lastUpdateTime = nil

    self.lblLastPos = Turbine.UI.Label()
    self.lblLastPos:SetParent(self)
    self.lblLastPos:SetPosition(15, 45)
    self.lblLastPos:SetSize(190, 20)
    self.lblLastPos:SetText("Última posición: --")
    self.lblLastPos:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)

    self.lblStatus = Turbine.UI.Label()
    self.lblStatus:SetParent(self)
    self.lblStatus:SetPosition(15, 65)
    self.lblStatus:SetSize(190, 20)
    self.lblStatus:SetText("Estado: SIN DATOS")
    self.lblStatus:SetFont(Turbine.UI.Lotro.Font.TrajanPro14)
    self.lblStatus:SetForeColor(Turbine.UI.Color(0.7, 0.7, 0.7))

    self.btnVisual = Turbine.UI.Lotro.Button()
    self.btnVisual:SetParent(self)
    self.btnVisual:SetPosition(35, 95)
    self.btnVisual:SetSize(150, 30)
    self.btnVisual:SetText("ACTUALIZAR")

    self.quickslot = Turbine.UI.Lotro.Quickslot()
    self.quickslot:SetParent(self)
    self.quickslot:SetPosition(35, 95)
    self.quickslot:SetSize(150, 30)
    self.quickslot:SetZOrder(10)
    self.quickslot:SetOpacity(0)
    self.quickslot:SetAllowDrop(false)

    local sc = Turbine.UI.Lotro.Shortcut(
        Turbine.UI.Lotro.ShortcutType.Alias,
        "/loc"
    )

    self.quickslot:SetShortcut(sc)

    self:SetWantsUpdates(true)
    self:SetVisible(true)
end

function NavigationPanel:UpdateLocation(locData)

    if not locData then
        return
    end

    self.lastLocData = locData
    self.lastUpdateTime = Turbine.Engine.GetGameTime()

    self.lblLastPos:SetText("Última posición: 0 s")
    self.lblStatus:SetText("Estado: ACTUALIZADA")
    self.lblStatus:SetForeColor(Turbine.UI.Color(0, 1, 0))
end

function NavigationPanel:Update()

    if not self.lastUpdateTime then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    local diff = math.floor(now - self.lastUpdateTime)

    self.lblLastPos:SetText(
        "Última posición: " .. tostring(diff) .. " s"
    )

    if diff > 10 then

        self.lblStatus:SetText("Estado: DESACTUALIZADA")
        self.lblStatus:SetForeColor(Turbine.UI.Color(1, 0, 0))

    else

        self.lblStatus:SetText("Estado: ACTUALIZADA")
        self.lblStatus:SetForeColor(Turbine.UI.Color(0, 1, 0))

    end
end
