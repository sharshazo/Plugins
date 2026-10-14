import "Turbine.UI"
if class == nil then
    import "Turbine.Gameplay"
    import "Turbine.UI.Lotro"
    import "PvMP_Plus_Revisited.PvMP_Plus.Utils"
end

PvMP_Plus_Reloader = class(Turbine.UI.Control)
function PvMP_Plus_Reloader:Constructor()
    Turbine.UI.Control.Constructor(self)
    self:SetWantsUpdates(true)
    self.reloaded = false
    self.Update = function()
        if self.reloaded then
            Turbine.PluginManager.LoadPlugin("PvMP+")
            self:SetWantsUpdates(false)
        elseif not(self.reloaded) then
            Turbine.PluginManager.UnloadScriptState("PvMP+")
            self.reloaded = true
        end
    end
end

local reload = PvMP_Plus_Reloader()