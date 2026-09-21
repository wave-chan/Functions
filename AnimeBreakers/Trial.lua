local Trial = {}

function Trial:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Data = Manager.Shared.GamemodeData["Time Trial"] or Manager.Shared.GamemodeData.Trial
end

return Trial
