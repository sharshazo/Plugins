-- LOTRO_Quest_Assistant/Integration/WaypointAdapter.lua
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.WaypointAdapter = {}

-- Ver el comentario en MoorMapAdapter.lua: cada boton/icono clicable necesita
-- su PROPIO Quickslot, no se puede compartir uno entre varias ventanas.
function WaypointAdapter.CreateQuickslot()
    local qs = Turbine.UI.Lotro.Quickslot()
    qs:SetSize(32, 32)
    qs:SetVisible(true)
    qs:SetOpacity(0)
    -- Ver el comentario detallado en MoorMapAdapter.CreateQuickslot -- mismo
    -- fix (SetAllowDrop(false)), portado del propio Quickslot-detras-de-boton
    -- de CubePlugins/DeedTracker, contra el sangrado de texto "/WAY" debajo
    -- del boton que agrandar el ancho nunca resolvio del todo.
    qs:SetAllowDrop(false)
    return qs
end

function WaypointAdapter.SetDestination(quickslot, coordinate)
    -- coordinate: "29.5S, 52.0W"
    if not quickslot then return end
    local cmd = "/way target " .. coordinate
    local sc = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, cmd)
    quickslot:SetShortcut(sc)
end

function WaypointAdapter.ClearDestination(quickslot)
    if not quickslot then return end
    local cmd = "/way hide"
    local sc = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, cmd)
    quickslot:SetShortcut(sc)
end
