local Raid = {}

function Raid:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Data = Manager.Shared.GamemodeData.Raid
end

return Raid
